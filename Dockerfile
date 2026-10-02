# Use the official n8n image
FROM n8nio/n8n:latest

USER root

# Install graceful-fs globally to provide resilient file handle queueing under strict microVM ulimits
RUN npm install -g graceful-fs

# Patch abstract-server.js to auto-refresh the browser during cold boot initialization
# instead of leaving the user stranded on a static text screen
RUN node -e "\
  const fs = require('fs');\
  const file = '/usr/local/lib/node_modules/n8n/dist/abstract-server.js';\
  let content = fs.readFileSync(file, 'utf8');\
  const target = \"res.send('n8n is starting up. Please wait');\";\
  const replacement = \"res.type('html').send('<!DOCTYPE html><html><head><meta http-equiv=\\\\\\\"refresh\\\\\\\" content=\\\\\\\"2\\\\\\\"><title>n8n is starting up...</title><style>body{font-family:system-ui,-apple-system,sans-serif;display:flex;align-items:center;justify-content:center;height:100vh;margin:0;background:#111827;color:#f9fafb}.card{text-align:center;padding:2.5rem;background:#1f2937;border-radius:1rem;border:1px solid #374151;box-shadow:0 10px 25px rgba(0,0,0,0.5)}.spinner{border:3px solid #374151;border-top:3px solid #f97316;border-radius:50%;width:44px;height:44px;animation:spin 0.8s linear infinite;margin:0 auto 1.25rem}@keyframes spin{to{transform:rotate(360deg)}}h2{margin:0 0 0.5rem;font-size:1.25rem}p{margin:0;color:#9ca3af;font-size:0.875rem}</style><script>setTimeout(()=>window.location.reload(),2000)</script></head><body><div class=\\\\\\\"card\\\\\\\"><div class=\\\\\\\"spinner\\\\\\\"></div><h2>n8n is starting up...</h2><p>Initializing workspace database.</p><p style=\\\\\\\"color:#6b7280;margin-top:0.5rem;font-size:0.75rem\\\\\\\">Auto-refreshing every 2 seconds...</p></div></body></html>');\";\
  if (content.includes(target)) {\
    content = content.replace(target, replacement);\
    fs.writeFileSync(file, content);\
    console.log('[build] abstract-server.js auto-refresh patched successfully');\
  } else {\
    console.warn('[build] target string not found in abstract-server.js');\
  }\
"

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
