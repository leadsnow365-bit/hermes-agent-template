#!/bin/bash
set -e

mkdir -p /data/.hermes/cron /data/.hermes/sessions /data/.hermes/logs \
         /data/.hermes/memories /data/.hermes/skills /data/.hermes/pairing \
         /data/.hermes/hooks /data/.hermes/image_cache /data/.hermes/audio_cache \
         /data/.hermes/workspace

cat > /data/.hermes/config.yaml << 'EOF'
model:
  default: "kimi-k2.6"
  provider: "kimi-coding"

auxiliary:
  vision:
    provider: "main"
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

[ ! -f /data/.hermes/.env ] && touch /data/.hermes/.env

source /opt/hermes-agent/.venv/bin/activate 2>/dev/null || true

if [ -n "$AGENT_NAME" ]; then
    python /app/mcp_task_server.py &
fi

exec python /app/server.py
