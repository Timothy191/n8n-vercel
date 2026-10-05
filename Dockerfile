# Use the official n8n image
FROM n8nio/n8n:latest

USER root

# Install graceful-fs globally to provide resilient file handle queueing under strict microVM ulimits
RUN npm install -g graceful-fs

# Patch abstract-server.js to show a polished, accessible cold-boot experience
# instead of leaving the user stranded on a static text screen
RUN node -e "\
  const fs = require('fs');\
  const file = '/usr/local/lib/node_modules/n8n/dist/abstract-server.js';\
  let content = fs.readFileSync(file, 'utf8');\
  const target = \"res.send('n8n is starting up. Please wait');\";\
  const replacement = \"res.type('html').send('<!DOCTYPE html><html lang=\\\"en\\\"><head><meta charset=\\\"utf-8\\\"><meta name=\\\"viewport\\\" content=\\\"width=device-width,initial-scale=1\\\"><meta http-equiv=\\\"refresh\\\" content=\\\"3\\\"><title>Starting n8n</title><style>:root{color-scheme:dark}*{box-sizing:border-box}body{font-family:Inter,ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,\\\"Segoe UI\\\",sans-serif;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0;padding:24px;background:#0d0d0d;color:#f5f5f5}.shell{width:min(100%,440px)}.card{padding:40px 36px;background:linear-gradient(145deg,#1b1b1b,#141414);border:1px solid #303030;border-radius:16px;box-shadow:0 24px 70px rgba(0,0,0,.38);text-align:center}.brand{display:inline-flex;align-items:center;gap:10px;margin-bottom:32px;color:#f97316;font-size:18px;font-weight:700}.mark{display:grid;place-items:center;width:28px;height:28px;border-radius:8px;background:#f97316;color:#111;font-weight:800}.status{display:flex;align-items:center;justify-content:center;gap:10px;margin-bottom:16px}.spinner{width:18px;height:18px;border:2px solid #454545;border-top-color:#f97316;border-radius:50%;animation:spin .8s linear infinite}@keyframes spin{to{transform:rotate(360deg)}}h1{margin:0;font-size:24px;line-height:1.2;letter-spacing:-.03em}p{margin:12px 0 0;color:#a3a3a3;font-size:14px;line-height:1.6}.progress{height:4px;margin:28px 0 0;overflow:hidden;border-radius:999px;background:#2b2b2b}.progress:after{display:block;width:40%;height:100%;border-radius:inherit;background:#f97316;content:\\\"\\\";animation:progress 1.8s ease-in-out infinite}@keyframes progress{0%{transform:translateX(-100%)}100%{transform:translateX(300%)}}.hint{margin-top:20px;color:#737373;font-size:12px}@media(max-width:480px){.card{padding:32px 24px}}@media(prefers-reduced-motion:reduce){.spinner,.progress:after{animation:none}.progress:after{margin-left:30%}}</style><script>setTimeout(()=>window.location.reload(),3000)</script></head><body><main class=\\\"shell\\\" aria-live=\\\"polite\\\"><section class=\\\"card\\\" aria-label=\\\"n8n startup status\\\"><div class=\\\"brand\\\"><span class=\\\"mark\\\" aria-hidden=\\\"true\\\">n</span><span>n8n</span></div><div class=\\\"status\\\"><span class=\\\"spinner\\\" aria-hidden=\\\"true\\\"></span><h1>Preparing your workspace</h1></div><p>n8n is initializing securely. This page will refresh automatically when your workspace is ready.</p><div class=\\\"progress\\\" role=\\\"progressbar\\\" aria-label=\\\"Workspace initialization in progress\\\"></div><p class=\\\"hint\\\">Usually takes a few seconds</p></section></main></body></html>');\";\
  if (content.includes(target)) {\
    content = content.replace(target, replacement);\
    fs.writeFileSync(file, content);\
    console.log('[build] abstract-server.js startup screen patched successfully');\
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
