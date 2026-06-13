// Minimal dependency-free static file server rooted at the brandbook/ directory.
// Playwright's webServer launches this so the brand book is served from a real
// http://localhost origin (not file://) — clipboard permissions, relative asset
// paths, and same-origin canvas sampling all behave like production.
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { extname, join, normalize, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

// import.meta.url = brandbook/e2e/static-server.mjs  →  ../ = brandbook/
const ROOT = fileURLToPath(new URL('../', import.meta.url));
const PORT = Number(process.env.PORT) || 5099;

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.ico': 'image/x-icon',
  '.md': 'text/markdown; charset=utf-8',
};

const server = createServer(async (req, res) => {
  try {
    let urlPath = decodeURIComponent((req.url || '/').split('?')[0]);
    if (urlPath === '/' || urlPath.endsWith('/')) urlPath += 'index.html';
    // Resolve and confine to ROOT (defence against path traversal).
    const filePath = normalize(join(ROOT, urlPath));
    if (filePath !== ROOT.slice(0, -1) && !filePath.startsWith(ROOT)) {
      res.writeHead(403);
      res.end('forbidden');
      return;
    }
    const body = await readFile(filePath);
    res.writeHead(200, { 'content-type': MIME[extname(filePath)] || 'application/octet-stream' });
    res.end(body);
  } catch {
    res.writeHead(404);
    res.end('not found');
  }
});

server.listen(PORT, () => {
  // eslint-disable-next-line no-console
  console.log(`brandbook static server: http://localhost:${PORT} (root: ${ROOT.split(sep).slice(-2).join(sep)})`);
});
