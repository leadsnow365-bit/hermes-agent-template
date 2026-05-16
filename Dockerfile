FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

# Node.js is required only at build time to compile the Hermes React dashboard.
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates git && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

# ---- Chrome system dependencies (install early) ----
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libglib2.0-0 libnss3 libfontconfig1 libxss1 \
    libasound2 libxtst6 libgtk-3-0 libgbm-dev \
    libdrm2 libxcomposite1 libxdamage1 libxrandr2 \
    libxkbcommon0 libpango-1.0-0 libcairo2 libatspi2.0-0 \
    fonts-liberation && \
    rm -rf /var/lib/apt/lists/*

# Install hermes-agent (provides the hermes CLI) and pre-build its React
# dashboard so hermes dashboard has nothing to build at runtime.
RUN git clone --depth 1 https://github.com/impacte-tech/hermes-agent /opt/hermes-agent && \
    cd /opt/hermes-agent && \
    uv pip install --system --no-cache -e ".[all]" && \
    cd /opt/hermes-agent/web && \
    npm install --silent && \
    npm run build && \
    rm -rf /opt/hermes-agent/web /opt/hermes-agent/.git /root/.npm

# ---- Install Playwright browsers AFTER Hermes is installed ----
RUN uv pip install --system --no-cache playwright
RUN python -m playwright install chromium && \
    python -m playwright install-deps chromium

COPY requirements.txt /app/requirements.txt
RUN uv pip install --system --no-cache -r /app/requirements.txt

RUN

COPY server.py /app/server.py
COPY templates/ /app/templates/
COPY start.sh /app/start.sh
COPY config.yaml /app/config.yaml
COPY mcp_task_server.py /app/mcp_task_server.py
RUN chmod +x /app/start.sh

ENV HOME=/data
ENV HERMES_HOME=/data/.hermes

CMD ["/app/start.sh"]
