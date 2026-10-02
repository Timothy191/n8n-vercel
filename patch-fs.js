// Global filesystem patch to prevent EMFILE crashes on high-concurrency static chunk requests
const realFs = require('node:fs');

try {
  let gracefulFs;
  try {
    gracefulFs = require('/usr/local/lib/node_modules/graceful-fs');
  } catch {
    try {
      gracefulFs = require('/usr/local/lib/node_modules/n8n/node_modules/.pnpm/node_modules/graceful-fs');
    } catch {
      try {
        gracefulFs = require('graceful-fs');
      } catch {
        gracefulFs = null;
      }
    }
  }

  if (gracefulFs && typeof gracefulFs.gracefulify === 'function') {
    gracefulFs.gracefulify(realFs);
    console.log('[patch-fs] graceful-fs successfully hooked into native fs module');
  } else {
    console.warn('[patch-fs] graceful-fs package not found, proceeding with unpatched fs');
  }
} catch (err) {
  console.warn('[patch-fs] Warning while patching fs:', err?.message || err);
}
