# Use the official n8n image
FROM n8nio/n8n:latest

USER root

# Install graceful-fs globally to provide resilient file handle queueing under strict microVM ulimits
RUN npm install -g graceful-fs

# Disable telemetry and enforce permission tolerance
ENV N8N_DIAGNOSTICS_ENABLED=false
ENV N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=false

# Copy custom entrypoint and fs patch to bridge Vercel container lifecycle and n8n CLI
COPY patch-fs.js /entrypoint-fs-patch.js
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Healthcheck for orchestration
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:${N8N_PORT:-5678}/healthz || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["start"]
