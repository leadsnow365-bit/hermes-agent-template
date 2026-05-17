 #!/bin/bash
set -e

mkdir -p /data/.hermes/{cron,sessions,logs,memories,skills,pairing,hooks,image_cache,audio_cache,workspace}

[ ! -f /data/.hermes/.env ] && touch /data/.hermes/.env

source /opt/hermes-agent/.venv/bin/activate 2>/dev/null || true

if [ -n "$AGENT_NAME" ]; then
    python /app/mcp_task_server.py &
fi

# Start server in background
python /app/server.py &
SERVER_PID=$!

# Wait for server.py to finish its setup nonsense
sleep 8

# OVERWRITE whatever broken config server.py wrote
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

# Keep container alive
wait $SERVER_PID
