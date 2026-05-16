#!/bin/bash
set -e

# Mirror dashboard-ref-only's startup: create every directory hermes expects
# and seed a default config.yaml if the volume is empty.
mkdir -p /data/.hermes/cron /data/.hermes/sessions /data/.hermes/logs \
         /data/.hermes/memories /data/.hermes/skills /data/.hermes/pairing \
         /data/.hermes/hooks /data/.hermes/image_cache /data/.hermes/audio_cache \
         /data/.hermes/workspace

# Seed default config only if completely missing
if [ ! -f /data/.hermes/config.yaml ] && [ -f /opt/hermes-agent/cli-config.yaml.example ]; then
  cp /opt/hermes-agent/cli-config.yaml.example /data/.hermes/config.yaml
fi

# SAFELY patch ONLY the vision section into existing config (never overwrites other settings)
python3 << 'PYEOF'
import yaml, os, sys
config_path = '/data/.hermes/config.yaml'
if not os.path.exists(config_path):
    sys.exit(0)

with open(config_path) as f:
    config = yaml.safe_load(f) or {}

config.setdefault('auxiliary', {})
config['auxiliary']['vision'] = {
    'provider': 'custom',
    'model': 'gpt-4o-mini',
    'base_url': 'https://api.openai.com/v1',
    'api_key': '${OPENAI_API_KEY}',
    'timeout': 120,
    'extra_body': {},
    'download_timeout': 30
}

with open(config_path, 'w') as f:
    yaml.dump(config, f, default_flow_style=False, sort_keys=False)
PYEOF

[ ! -f /data/.hermes/.env ] && touch /data/.hermes/.env

# Start Angel MCP task server in background (port 8081) only if configured
if [ -n "$AGENT_NAME" ]; then
    python /app/mcp_task_server.py &
fi

exec python /app/server.py
