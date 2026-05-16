#!/bin/bash
set -e

# Create hermes directory structure
mkdir -p /data/.hermes/cron /data/.hermes/sessions /data/.hermes/logs \
         /data/.hermes/memories /data/.hermes/skills /data/.hermes/pairing \
         /data/.hermes/hooks /data/.hermes/image_cache /data/.hermes/audio_cache \
         /data/.hermes/workspace

# Seed default config only if missing
if [ ! -f /data/.hermes/config.yaml ] && [ -f /opt/hermes-agent/cli-config.yaml.example ]; then
  cp /opt/hermes-agent/cli-config.yaml.example /data/.hermes/config.yaml
fi

# Route vision through main provider (Kimi) — no extra API key needed
python3 << 'PYEOF'
import yaml, os, sys
config_path = '/data/.hermes/config.yaml'
if not os.path.exists(config_path):
    sys.exit(0)

with open(config_path) as f:
    config = yaml.safe_load(f) or {}

config.setdefault('auxiliary', {})
config['auxiliary']['vision'] = {
    'provider': 'main',
    'timeout': 120,
}

with open(config_path, 'w') as f:
    yaml.dump(config, f, default_flow_style=False, sort_keys=False)
PYEOF

[ ! -f /data/.hermes/.env ] && touch /data/.hermes/.env

# Activate hermes virtual environment
source /opt/hermes-agent/.venv/bin/activate

# Start Angel MCP task server in background if configured
if [ -n "$AGENT_NAME" ]; then
    python /app/mcp_task_server.py &
fi

exec python /app/server.py
