#!/bin/bash
set -e

mkdir -p /data/.hermes/cron \
         /data/.hermes/sessions \
         /data/.hermes/logs \
         /data/.hermes/memories \
         /data/.hermes/skills \
         /data/.hermes/pairing \
         /data/.hermes/hooks \
         /data/.hermes/image_cache \
         /data/.hermes/audio_cache \
         /data/.hermes/workspace

cat > /data/.hermes/config.yaml << EOF
model:
  default: "${LLM_MODEL:-qwen3:latest}"
  provider: "custom"

providers:
  custom:
    base_url: "${OLLAMA_BASE_URL:-https://ollama.com/api}"
    api_key: "${OLLAMA_API_KEY}"

auxiliary:
  vision:
    provider: "custom"
    model: "${LLM_MODEL:-qwen3:latest}"
    timeout: 120

terminal:
  backend: "local"
  timeout: 60
  cwd: "/tmp"

agent:
  max_iterations: 50

data_dir: "/data/.hermes"
EOF

[ ! -f /data/.hermes/.env ] && touch /data/.hermes/.env

source /opt/hermes-agent/.venv/bin/activate 2>/dev/null || true

if [ -n "$AGENT_NAME" ]; then
    python /app/mcp_task_server.py &
fi

exec python /app/server.py
