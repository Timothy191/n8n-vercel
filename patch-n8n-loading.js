// Patch abstract-server.js to use n8n official design system loading page
const fs = require('fs');
const path = require('path');

// Import the HTML (we'll inline it for the Docker build)
const LOADING_HTML = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="refresh" content="2">
  <title>n8n is starting up...</title>
  <style>
    :root {
      /* n8n Official Design System Variables */
      --color--primary: #ff9b26;
      --color--primary-light: #ffb552;
      --color--secondary: #ff5873;
      --color--background: #0e0918;
      --color--background-light-3: #1a1a1a;
      --color--text: #ffffff;
      --color--text-shade-1: #b6b5b9;
      --color--text-tint-1: #9ca3af;
      --color--foreground: rgba(255, 255, 255, 0.1);
      --color--foreground-tint-2: rgba(255, 142, 93, 0.3);
      
      /* Backward compatibility aliases */
      --color-bg-primary: var(--color--background);
      --color-bg-card: var(--color--background-light-3);
      --color-border: var(--color--foreground);
      --color-border-glow: var(--color--foreground-tint-2);
      --color-text-primary: var(--color--text);
      --color-text-secondary: var(--color--text-shade-1);
      --color-text-tertiary: var(--color--text-tint-1);
      --color-accent: var(--color--primary);
      --color-accent-secondary: var(--color--secondary);
      --font-family: ui-sans-serif, system-ui, sans-serif, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto;
      --letter-spacing: -0.02em;
    }
    
    * { margin: 0; padding: 0; box-sizing: border-box; }
    
    body {
      font-family: var(--font-family);
      background: var(--color--background);
      color: var(--color--text);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      letter-spacing: var(--letter-spacing);
      animation: fadeIn 0.5s ease-out;
    }
    
    @keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
    
    .loading-container { text-align: center; padding: 1rem; max-width: 420px; width: 90%; }
    
    .loading-card {
      background: var(--color--background-light-3);
      border-radius: 1rem;
      padding: 2.5rem;
      border: 1px solid var(--color--foreground);
      box-shadow: 
        0 0 0 1px var(--color--foreground) inset,
        0 1px 0 0 var(--color--foreground-tint-2) inset;
      background-image: 
        radial-gradient(55% 100% at 55% 2%, rgba(168, 92, 92, 0.25), rgba(103, 69, 69, 0.08)),
        linear-gradient(to bottom, transparent, rgba(14, 9, 24, 0.36));
      animation: fadeIn 0.6s ease-out 0.1s both;
      position: relative;
      overflow: hidden;
    }
    
    .loading-card::before {
      content: ''; position: absolute; top: 0; left: 0; right: 0; bottom: 0;
      background: 
        radial-gradient(circle at 30% 0%, rgba(253, 152, 37, 0.1) 0%, transparent 50%),
        radial-gradient(circle at 70% 100%, rgba(251, 151, 51, 0.1) 0%, transparent 50%);
      opacity: 0.5; pointer-events: none;
    }
    
    .n8n-logo {
      width: 48px; height: 48px; margin: 0 auto 1.5rem;
      background: linear-gradient(135deg, var(--color--primary), var(--color--secondary));
      -webkit-background-clip: text; -webkit-text-fill-color: transparent;
      background-clip: text;
      font-size: 2.5rem; font-weight: 700; letter-spacing: -0.05em;
      animation: fadeIn 0.7s ease-out 0.2s both;
    }
    
    .loading-spinner {
      width: 44px; height: 44px;
      border: 3px solid var(--color--foreground);
      border-top: 3px solid var(--color--primary);
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
      margin: 0 auto 1.25rem; position: relative;
    }
    
    .loading-spinner::before {
      content: ''; position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%);
      width: 8px; height: 8px; background: var(--color--primary); border-radius: 50%;
      box-shadow: 0 0 0 2px var(--color--background-light-3);
    }
    
    @keyframes spin {
      0% { transform: rotate(0deg); border-top-color: var(--color--primary); }
      25% { border-top-color: var(--color--secondary); }
      50% { border-top-color: var(--color--primary); }
      75% { border-top-color: var(--color--secondary); }
      100% { transform: rotate(360deg); border-top-color: var(--color--primary); }
    }
    
    .loading-title {
      margin: 0 0 0.5rem; font-size: 1.25rem; color: var(--color--text);
      font-weight: 600; letter-spacing: var(--letter-spacing); animation: fadeIn 0.8s ease-out 0.3s both;
    }
    
    .loading-description {
      margin: 0; color: var(--color--text-shade-1); font-size: 0.875rem; line-height: 1.5;
      animation: fadeIn 0.8s ease-out 0.4s both;
    }
    
    .loading-subtitle {
      color: var(--color--text-tint-1); font-size: 0.75rem; margin-top: 0.5rem;
      animation: fadeIn 0.8s ease-out 0.5s both;
    }
    
    .loading-subtitle::before { content: '⏳ '; animation: pulse 1.5s ease-in-out infinite; }
    @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.6; } }
    
    @media (max-width: 640px) {
      .loading-container { padding: 0.5rem; }
      .loading-card { padding: 1.5rem; }
      .loading-title { font-size: 1.125rem; }
      .n8n-logo { width: 40px; height: 40px; font-size: 2rem; }
    }
  </style>
</head>
<body>
  <div class="loading-container">
    <div class="loading-card">
      <div class="n8n-logo">n8n</div>
      <div class="loading-spinner"></div>
      <h1 class="loading-title">n8n is starting up...</h1>
      <p class="loading-description">Initializing workflow automation engine</p>
      <p class="loading-subtitle">Auto-refreshing every 2 seconds</p>
    </div>
  </div>
</body>
</html>`;

// Target string to find and replace
const TARGET_STRING = "res.send('n8n is starting up. Please wait');";

// Function to patch the file
function patchAbstractServer() {
  const possiblePaths = [
    '/usr/local/lib/node_modules/n8n/dist/abstract-server.js',
    '/usr/local/lib/node_modules/n8n/dist/src/abstract-server.js',
    '/usr/local/lib/node_modules/n8n/lib/abstract-server.js'
  ];
  
  let patched = false;
  
  for (const filePath of possiblePaths) {
    try {
      if (fs.existsSync(filePath)) {
        let content = fs.readFileSync(filePath, 'utf8');
        
        if (content.includes(TARGET_STRING)) {
          // JSON.stringify yields a valid JS string literal (escapes newlines,
          // quotes and backslashes). Raw multi-line HTML inside '...' is a
          // SyntaxError that crashes n8n on boot.
          const replacement = `res.type('html').send(${JSON.stringify(LOADING_HTML)});`;
          
          // Function replacer: prevents `$&`/`$1` patterns in the HTML from
          // being interpreted by String.prototype.replace.
          content = content.replace(TARGET_STRING, () => replacement);
          fs.writeFileSync(filePath, content);
          console.log('[build] abstract-server.js patched successfully with n8n official design');
          patched = true;
          break;
        } else {
          console.warn('[build] Target string not found in abstract-server.js at', filePath);
        }
      }
    } catch (error) {
      // Try next path
      continue;
    }
  }
  
  if (!patched) {
    console.warn('[build] abstract-server.js not found or could not be patched');
  }
}

// Run the patch
try {
  patchAbstractServer();
} catch (error) {
  console.error('[build] Error patching abstract-server.js:', error.message);
  process.exit(0); // Don't fail the build
}