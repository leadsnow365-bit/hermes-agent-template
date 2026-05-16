!/bin/bash
set -e

# Mirror dashboard-ref-only's startup: create every directory hermes expects
# and seed a default config.yaml if the volume is empty. Without these,
# hermes dashboard endpoints that hit logs/, sessions/, cron/, etc. can fail
# with opaque errors even though no auth is actually involved.
mkdir -p /data/.hermes/cron /data/.hermes/sessions /data/.hermes/logs \
         /data/.hermes/memories /data/.hermes/skills /data/.hermes/pairing \
         /data/.hermes/hooks /data/.hermes/image_cache /data/.hermes/audio_cache \
         /data/.hermes/workspace

# ALWAYS copy repo-baked config.yaml (Railway volume may persist stale config)
if [ -f /app/config.yaml ]; then
  cp /app/config.yaml /data/.hermes/config.yaml
elif [ ! -f /data/.hermes/config.yaml ] && [ -f /opt/hermes-agent/cli-config.yaml.example ]; then
  cp /opt/hermes-agent/cli-config.yaml.example /data/.hermes/config.yaml
fi

[ ! -f /data/.hermes/.env ] && touch /data/.hermes/.env

# Start Angel MCP task server in background (port 8081) only if configured
if [ -n "$AGENT_NAME" ]; then
    python /app/mcp_task_server.py &
fi

exec python /app/server.py
