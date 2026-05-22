#!/bin/bash
set -e

echo "Starting Hermes Agent..."

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

# CLEAN OLD BROKEN CONFIGS
rm -f /data/.hermes/.env
rm -f /data/.hermes/config.yaml

# WRITE CLEAN CONFIG
cat > /data/.hermes/config.yaml << EOF
model:
  default: "llama-3.3-70b-versatile"
  provider: groq

providers:
  groq:
    api_key: "${GROQ_API_KEY}"
    base_url: "https://api.groq.com/openai/v1"

  kimi-coding:
    api_key: "${KIMI_API_KEY}"
    base_url: "https://api.moonshot.cn/v1"

  openai:
    api_key: "${OPENAI_API_KEY}"

auxiliary:
  vision:
    provider: "kimi-coding"
    model: "kimi-k2.5"
    timeout: 120

terminal:
  backend: "local"
  timeout: 60
  cwd: "/tmp"

agent:
  max_iterations: 50

data_dir: "/data/.hermes"
EOF

echo "Config written successfully"

source /opt/hermes-agent/.venv/bin/activate 2>/dev/null || true

if [ -n "$AGENT_NAME" ]; then
    echo "Starting MCP task server..."
    python /app/mcp_task_server.py &
fi

echo "Launching Hermes server..."
exec python /app/server.py 
