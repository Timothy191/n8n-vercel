# Use the official n8n image - pinned to specific version for stability
# Note: Using :latest for best compatibility with current n8n versions
FROM n8nio/n8n:latest

# Capture the actual version used for this build
RUN echo "Building with n8n version: $(n8n --version 2>/dev/null || echo 'unknown')" && \
    echo "Built on: $(date)" > /tmp/build-info.txt

USER root

# Install graceful-fs globally to provide resilient file handle queueing under strict microVM ulimits
RUN npm install -g graceful-fs

# Copy and run patch script to apply n8n official design system loading page
COPY patch-n8n-loading.js /tmp/patch-n8n-loading.js
RUN node /tmp/patch-n8n-loading.js && rm /tmp/patch-n8n-loading.js || echo "Warning: n8n loading page patch failed, continuing anyway..."

# Disable telemetry and enforce permission tolerance
ENV N8N_DIAGNOSTICS_ENABLED=false
ENV N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=false

# Copy custom entrypoint and fs patch to bridge Vercel container lifecycle and n8n CLI
COPY patch-fs.js /entrypoint-fs-patch.js
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Healthcheck for orchestration - enhanced with fallback
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=5 \
  CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:${N8N_PORT:-5678}/healthz \
    || wget --no-verbose --tries=1 --spider http://127.0.0.1:${N8N_PORT:-5678}/ \
    || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["start"]