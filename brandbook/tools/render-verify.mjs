#!/usr/bin/env node
/**
 * brandbook/tools/render-verify.mjs
 * Playwright-based render-verify helper (D-05 mandatory loop tool).
 *
 * Launches headless Chromium, navigates to a local file:// path (HTML or SVG),
 * takes a fullPage screenshot, and saves it to a given output path.
 * The executor then Reads the output PNG to visually inspect before commit.
 *
 * Usage:
 *   node brandbook/tools/render-verify.mjs <input-file> [output-png]
 *
 *   input-file: absolute or relative path to an .html or .svg file
 *   output-png: screenshot destination (default: /tmp/render-verify.png)
 *
 * Playwright lives at examples/phoenix_host/node_modules — NOT under brandbook/tools.
 * Zero additional npm installs required.
 *
 * D-05: Every visual artifact must be browser-rendered and inspected before commit.
 */

import { createRequire } from 'node:module';
import { resolve, dirname, isAbsolute } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Resolve Playwright from the examples/phoenix_host node_modules tree
const PW_MODULES = resolve(__dirname, '../../examples/phoenix_host/node_modules');
const require = createRequire(import.meta.url);
let chromium;
try {
  ({ chromium } = require(resolve(PW_MODULES, 'playwright')));
} catch (err) {
  console.error('ERROR: Could not load Playwright from', PW_MODULES);
  console.error(err.message);
  process.exit(1);
}

const inputArg = process.argv[2];
const outputArg = process.argv[3] || '/tmp/render-verify.png';
const widthArg = parseInt(process.argv[4], 10) || 1200; // viewport width (e.g. 390 for mobile pass)

if (!inputArg) {
  console.error('Usage: node brandbook/tools/render-verify.mjs <input-file> [output-png] [viewport-width]');
  process.exit(1);
}

// Resolve input to absolute path
const inputAbs = isAbsolute(inputArg) ? inputArg : resolve(process.cwd(), inputArg);

if (!existsSync(inputAbs)) {
  console.error(`ERROR: Input file not found: ${inputAbs}`);
  process.exit(1);
}

const ext = inputAbs.split('.').pop().toLowerCase();
let fileUrl;

if (ext === 'svg') {
  // Wrap SVG in a minimal HTML page so currentColor is visible (dark text on white bg)
  const svgContent = readFileSync(inputAbs, 'utf8');
  const wrapperHtml = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>
  body { margin: 0; background: #f5f5f5; display: flex; align-items: center; justify-content: center; min-height: 100vh; }
  .svg-wrap { color: #09141A; width: 300px; height: 300px; display: flex; align-items: center; justify-content: center; }
  .svg-wrap svg { width: 100%; height: 100%; }
</style>
</head>
<body>
  <div class="svg-wrap">
    ${svgContent}
  </div>
</body>
</html>`;
  // Write to a temp HTML file
  const tmpHtml = outputArg.replace(/\.png$/, '-wrapper.html').replace(/^\/tmp\//, '/tmp/');
  writeFileSync(tmpHtml, wrapperHtml, 'utf8');
  fileUrl = pathToFileURL(tmpHtml).href;
} else {
  fileUrl = pathToFileURL(inputAbs).href;
}

// Launch headless Chromium and screenshot
let browser;
try {
  browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: widthArg, height: 900 } });
  await page.goto(fileUrl, { waitUntil: 'load' });
  await page.screenshot({ path: outputArg, fullPage: true });
  console.log(`Screenshot saved: ${outputArg}`);
} catch (err) {
  console.error('ERROR during render:', err.message);
  process.exit(1);
} finally {
  if (browser) await browser.close();
}
