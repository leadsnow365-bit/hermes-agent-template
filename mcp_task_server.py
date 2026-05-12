#!/usr/bin/env python3
"""
Angel MCP Task Server — exposes execute_task via FastMCP streamable-http.
Each agent runs this alongside the Hermes Railway admin server.
"""
import os
import json
import subprocess
import logging
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse

logging.basicConfig(level=logging.INFO, format="[mcp] %(levelname)s: %(message)s")
logger = logging.getLogger("angel-mcp")


# ── Bearer Token Auth Middleware ──────────────────────────────────────────

class BearerAuthMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        if request.url.path == "/health":
            return await call_next(request)
        expected = f"Bearer {os.getenv('MCP_SHARED_TOKEN', '')}"
        auth = request.headers.get("Authorization", "")
        if auth != expected:
            logger.warning("Unauthorized request from %s", request.client)
            return JSONResponse({"error": "Unauthorized"}, status_code=401)
        return await call_next(request)


# ── FastMCP Server ───────────────────────────────────────────────────────

from mcp.server.fastmcp import FastMCP

AGENT_NAME = os.getenv("AGENT_NAME", "angel")

mcp = FastMCP(
    AGENT_NAME,
    instructions=f"{AGENT_NAME.capitalize()} AI agent task executor. Call execute_task to delegate work.",
)


@mcp.tool()
def execute_task(task: str, context: str = "") -> str:
    """
    Execute a task using this agent's full Hermes toolset.

    Args:
        task: The instruction or question to execute.
        context: Optional background context (who asked, why, constraints).
    """
    full_prompt = task
    if context:
        full_prompt = f"[Context: {context}]\n\n{task}"

    logger.info("Executing task: %s", task[:120])

    try:
        result = subprocess.run(
            ["hermes", "chat", "-q", full_prompt],
            capture_output=True,
            text=True,
            timeout=300,
            env={**os.environ, "PYTHONUNBUFFERED": "1"},
        )
        output = result.stdout.strip()
        if result.returncode != 0 and result.stderr:
            output += f"\n[stderr: {result.stderr.strip()[:500]}]"
        return json.dumps({
            "result": output,
            "agent": AGENT_NAME,
            "returncode": result.returncode,
        }, ensure_ascii=False)
    except subprocess.TimeoutExpired:
        return json.dumps({"error": "Task timed out after 300s", "agent": AGENT_NAME}, ensure_ascii=False)
    except Exception as e:
        return json.dumps({"error": str(e), "agent": AGENT_NAME}, ensure_ascii=False)


# ── Health endpoint ──────────────────────────────────────────────────────

async def health(request):
    return JSONResponse({"status": "ok", "agent": AGENT_NAME})


# ── Run ──────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import uvicorn
    from starlette.applications import Starlette
    from starlette.routing import Route

    mcp_app = mcp.streamable_http_app()
    mcp_app.routes.insert(0, Route("/health", health, methods=["GET"]))
    mcp_app.add_middleware(BearerAuthMiddleware)

    host = os.getenv("MCP_HOST", "0.0.0.0")
    port = int(os.getenv("MCP_PORT", "8081"))
    logger.info(f"Angel MCP server starting on {host}:{port} | agent={AGENT_NAME}")
    uvicorn.run(mcp_app, host=host, port=port, log_level="info")
