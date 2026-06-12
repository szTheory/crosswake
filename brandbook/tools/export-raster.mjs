#!/usr/bin/env node
/**
 * brandbook/tools/export-raster.mjs
 * Exact-dimension Playwright PNG exporter.
 *
 * Usage:
 *   node brandbook/tools/export-raster.mjs <input.svg> <output.png> <width> <height> [bgColor]
 *
 *   bgColor: optional CSS color string (e.g. "#F7F1E6") for opaque background.
 *            If omitted, background is transparent (omitBackground: true).
 *
 * Playwright lives at examples/phoenix_host/node_modules — zero new installs.
 */

import { createRequire } from 'node:module';
import { resolve, dirname, isAbsolute } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { randomBytes } from 'node:crypto';

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

const [, , inputArg, outputArg, widthArg, heightArg, bgColorArg] = process.argv;

if (!inputArg || !outputArg || !widthArg || !heightArg) {
  console.error('Usage: node brandbook/tools/export-raster.mjs <input.svg> <output.png> <width> <height> [bgColor]');
  process.exit(1);
}

const width = parseInt(widthArg, 10);
const height = parseInt(heightArg, 10);
if (isNaN(width) || isNaN(height) || width <= 0 || height <= 0) {
  console.error('ERROR: width and height must be positive integers');
  process.exit(1);
}

const inputAbs = isAbsolute(inputArg) ? inputArg : resolve(process.cwd(), inputArg);
const outputAbs = isAbsolute(outputArg) ? outputArg : resolve(process.cwd(), outputArg);

if (!existsSync(inputAbs)) {
  console.error(`ERROR: Input file not found: ${inputAbs}`);
  process.exit(1);
}

const svgContent = readFileSync(inputAbs, 'utf8');
const bgStyle = bgColorArg
  ? `body { background: ${bgColorArg}; }`
  : `body { background: transparent; }`;

// Build minimal HTML: SVG fills exactly width x height, no scrollbars
const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  html, body { width: ${width}px; height: ${height}px; overflow: hidden; }
  ${bgStyle}
  .wrap { width: ${width}px; height: ${height}px; display: flex; align-items: center; justify-content: center; }
  .wrap svg { width: ${width}px; height: ${height}px; display: block; }
</style>
</head>
<body>
<div class="wrap">
${svgContent}
</div>
</body>
</html>`;

const tmpHtml = resolve(tmpdir(), `export-raster-${randomBytes(6).toString('hex')}.html`);
writeFileSync(tmpHtml, html, 'utf8');

let browser;
try {
  browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width, height }, deviceScaleFactor: 1 });
  await page.goto(pathToFileURL(tmpHtml).href, { waitUntil: 'load' });
  const screenshotOpts = {
    path: outputAbs,
    clip: { x: 0, y: 0, width, height },
  };
  if (!bgColorArg) {
    screenshotOpts.omitBackground = true;
  }
  await page.screenshot(screenshotOpts);
  console.log(`Exported: ${outputAbs} (${width}x${height}${bgColorArg ? ` bg=${bgColorArg}` : ' transparent'})`);
} catch (err) {
  console.error('ERROR during render:', err.message);
  process.exit(1);
} finally {
  if (browser) await browser.close();
  // Clean up temp file
  try { require('fs').unlinkSync(tmpHtml); } catch (_) {}
}
