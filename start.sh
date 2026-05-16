#!/bin/bash
set -e

mkdir -p /data/.hermes/cron /data/.hermes/sessions /data/.hermes/logs \
         /data/.hermes/memories /data/.hermes/skills /data/.hermes/pairing \
         /data/.hermes/hooks /data/.hermes/image_cache /data/.hermes/audio_cache \
         /data/.hermes/workspace

# Write config directly — no Python, no YAML parsing, no guessing paths
cat > /data/.hermes/config.yaml << 'EOF'
model:
  default: "kimi-k2.6"
  provider: "kimi-coding"

auxiliary:
  vision:
    provider: "main"
    timeout: 120

data_dir: "/data/.hermes"
EOF

[ ! -f /data/.hermes/.env ] && touch /data/.hermes/.env

# Try to activate venv if it exists — but don't fail if it doesn't
if [ -f /opt/hermes/.venv/bin/activate ]; then
    source /opt/hermes/.venv/bin/activate
elif [ -f /opt/hermes-agent/.venv/bin/activate ]; then
    source /opt/hermes-agent/.venv/bin/activate
elif [ -f /app/.venv/bin/activate ]; then
    source /app/.venv/bin/activate
fi

if [ -n "$AGENT_NAME" ]; then
    python /app/mcp_task_server.py &
fi

exec python /app/server.py
