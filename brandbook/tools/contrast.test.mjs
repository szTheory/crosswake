#!/usr/bin/env node
// brandbook/tools/contrast.test.mjs
// Unit tests for contrast.mjs — run with: node brandbook/tools/contrast.test.mjs
// RED phase: these tests verify behavior before implementation exists.

import { strict as assert } from 'assert';
import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

// Import the module under test
let mod;
try {
  mod = await import('./contrast.mjs');
} catch (e) {
  console.error('FATAL: could not import contrast.mjs:', e.message);
  process.exit(1);
}

const { linearize, luminance, parseHex, contrast } = mod;

// ─── Token resolution (Phase 155 D-33 — read from crosswake.tokens.json at test
// time, never paste hex literals) ────────────────────────────────────────────
const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, '../..');
const TOKENS_JSON = resolve(ROOT, 'brandbook/tokens/crosswake.tokens.json');

const { flattenTokens } = await import('./compile-tokens.js');
const tokensData = JSON.parse(readFileSync(TOKENS_JSON, 'utf8'));
const flatTokens = flattenTokens(tokensData);

// Resolve a dot-path token (e.g. "action.focus-ring") to a real hex string,
// following the `{alias.path}` chain to a primitive, for a given theme.
function resolveTokenHex(path, dark = false) {
  const token = flatTokens[path];
  if (!token) throw new Error(`resolveTokenHex: unknown token path "${path}"`);
  let raw = dark ? (token.$dark || token.$value) : token.$value;
  while (typeof raw === 'string' && raw.startsWith('{') && raw.endsWith('}')) {
    const aliasPath = raw.slice(1, -1);
    const aliasToken = flatTokens[aliasPath];
    if (!aliasToken) throw new Error(`resolveTokenHex: unresolved alias "${aliasPath}"`);
    raw = dark ? (aliasToken.$dark || aliasToken.$value) : aliasToken.$value;
  }
  return raw;
}

let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    fn();
    console.log(`  PASS: ${name}`);
    passed++;
  } catch (e) {
    console.error(`  FAIL: ${name}`);
    console.error(`        ${e.message}`);
    failed++;
  }
}

console.log('contrast.mjs unit tests\n');

// linearize: threshold must be 0.04045 (not 0.03928)
test('linearize(0) returns 0', () => {
  assert.equal(linearize(0), 0);
});

test('linearize(255) returns ~1.0', () => {
  const v = linearize(255);
  assert.ok(Math.abs(v - 1.0) < 0.001, `expected ~1.0 got ${v}`);
});

// The 0.04045 threshold: the exact boundary value
// s = 0.04045 exactly: s <= 0.04045 so result = s / 12.92
// A raw byte value of c where c/255 = 0.04045 → c ≈ 10.31
// So c=10: s = 10/255 ≈ 0.03922 < 0.04045 → linear branch
// c=11: s = 11/255 ≈ 0.04314 > 0.04045 → gamma branch
test('linearize uses 0.04045 threshold (not 0.03928)', () => {
  // c=11: s = 11/255 ≈ 0.04314 > 0.04045 → gamma: ((0.04314+0.055)/1.055)^2.4
  // c=10: s = 10/255 ≈ 0.03922 < 0.04045 → linear: s/12.92 = 0.00304
  const low = linearize(10);  // should use linear branch (< 0.04045)
  const high = linearize(11); // should use gamma branch (> 0.04045)
  // Linear result for c=10: (10/255) / 12.92 ≈ 0.003035
  assert.ok(low < 0.004, `c=10 should use linear branch, got ${low}`);
  // Gamma result for c=11: ((11/255+0.055)/1.055)^2.4
  const expected_high = Math.pow((11 / 255 + 0.055) / 1.055, 2.4);
  assert.ok(Math.abs(high - expected_high) < 1e-10, `c=11 gamma mismatch: ${high} vs ${expected_high}`);
});

// parseHex: valid input
test('parseHex("#09141A") returns [9, 20, 26]', () => {
  const [r, g, b] = parseHex('#09141A');
  assert.equal(r, 9);
  assert.equal(g, 20);
  assert.equal(b, 26);
});

test('parseHex("#FFFFFF") returns [255, 255, 255]', () => {
  const [r, g, b] = parseHex('#FFFFFF');
  assert.equal(r, 255);
  assert.equal(g, 255);
  assert.equal(b, 255);
});

// parseHex: invalid input must throw
test('parseHex("#ZZZ") throws Invalid hex color', () => {
  assert.throws(
    () => parseHex('#ZZZ'),
    (err) => err.message.includes('Invalid hex color'),
    'expected Invalid hex color error'
  );
});

test('parseHex("not-a-color") throws Invalid hex color', () => {
  assert.throws(
    () => parseHex('not-a-color'),
    (err) => err.message.includes('Invalid hex color'),
    'expected Invalid hex color error'
  );
});

// contrast: verified ratios from RESEARCH.md Finding 4
test('contrast(foam-50, current-950) ≈ 16.58 (PASS AA)', () => {
  const ratio = contrast('#F7F1E6', '#09141A');
  assert.ok(Math.abs(ratio - 16.58) < 0.1, `expected ~16.58 got ${ratio.toFixed(2)}`);
});

test('contrast(stone-500, foam-50) ≈ 4.09 (FAIL AA — must be < 4.5)', () => {
  const ratio = contrast('#7C746A', '#F7F1E6');
  assert.ok(Math.abs(ratio - 4.09) < 0.1, `expected ~4.09 got ${ratio.toFixed(2)}`);
  assert.ok(ratio < 4.5, `stone-500/foam-50 must fail AA (< 4.5), got ${ratio.toFixed(2)}`);
});

test('contrast(stone-600, foam-50) ≈ 4.53 (PASS AA — must be >= 4.5)', () => {
  const ratio = contrast('#756D63', '#F7F1E6');
  assert.ok(Math.abs(ratio - 4.53) < 0.1, `expected ~4.53 got ${ratio.toFixed(2)}`);
  assert.ok(ratio >= 4.5, `stone-600/foam-50 must pass AA (>= 4.5), got ${ratio.toFixed(2)}`);
});

test('contrast(wake-500, foam-50) ≈ 2.95 (FAIL AA)', () => {
  const ratio = contrast('#4E9A8E', '#F7F1E6');
  assert.ok(Math.abs(ratio - 2.95) < 0.1, `expected ~2.95 got ${ratio.toFixed(2)}`);
  assert.ok(ratio < 4.5, `wake-500/foam-50 must fail AA`);
});

test('contrast(mist-200, current-950) ≈ 12.25 (PASS AA)', () => {
  const ratio = contrast('#C9D4CF', '#09141A');
  assert.ok(Math.abs(ratio - 12.25) < 0.2, `expected ~12.25 got ${ratio.toFixed(2)}`);
});

// ─── Non-text UI component contrast (WCAG SC 1.4.11, 3:1) ───────────────────
// Phase 155 D-33: the suite above has only ever tested TEXT pairs (>= 4.5
// threshold). That hole is exactly why a focus ring measuring 2.93:1 shipped
// and stayed green. These assertions resolve their hex from
// crosswake.tokens.json at test time — never a pasted literal — so changing
// the token without re-running this gate turns it red.
console.log('\nnon-text UI component contrast (WCAG SC 1.4.11, must be >= 3.0)\n');

test('WCAG SC 1.4.11: action.focus-ring (light) vs white >= 3.0 (non-text, 3:1 floor)', () => {
  const fg = resolveTokenHex('action.focus-ring', false);
  const ratio = contrast(fg, '#FFFFFF');
  assert.ok(ratio >= 3.0,
    `focus-ring (light, ${fg}) vs white must pass SC 1.4.11's 3:1 non-text floor, got ${ratio.toFixed(2)}`);
});

test('WCAG SC 1.4.11: action.focus-ring (light) vs foam-50 >= 3.0 (non-text, 3:1 floor)', () => {
  const fg = resolveTokenHex('action.focus-ring', false);
  const ratio = contrast(fg, '#F7F1E6');
  assert.ok(ratio >= 3.0,
    `focus-ring (light, ${fg}) vs foam-50 must pass SC 1.4.11's 3:1 non-text floor, got ${ratio.toFixed(2)}`);
});

test('WCAG SC 1.4.11: action.focus-ring (dark) vs the dark inset surface >= 3.0 (non-text, 3:1 floor)', () => {
  const fg = resolveTokenHex('action.focus-ring', true);
  const bg = resolveTokenHex('surface.inset', true);
  const ratio = contrast(fg, bg);
  assert.ok(ratio >= 3.0,
    `focus-ring (dark, ${fg}) vs the dark inset surface (${bg}) must pass SC 1.4.11's 3:1 non-text floor, got ${ratio.toFixed(2)}`);
});

// ─── Destructive-pair contrast (status.error-fg on status.error, D-27/D-32) ──
console.log('\ndestructive-pair contrast (status.error-fg on status.error, must be >= 4.5)\n');

test('contrast(status.error-fg, status.error) (light) >= 4.5 (PASS AA — filled destructive button)', () => {
  const fg = resolveTokenHex('status.error-fg', false);
  const bg = resolveTokenHex('status.error', false);
  const ratio = contrast(fg, bg);
  assert.ok(ratio >= 4.5,
    `status.error-fg (light, ${fg}) on status.error (${bg}) must pass AA (>= 4.5), got ${ratio.toFixed(2)}`);
});

test('contrast(status.error-fg, status.error) (dark) >= 4.5 (PASS AA — filled destructive button)', () => {
  const fg = resolveTokenHex('status.error-fg', true);
  const bg = resolveTokenHex('status.error', true);
  const ratio = contrast(fg, bg);
  assert.ok(ratio >= 4.5,
    `status.error-fg (dark, ${fg}) on status.error (${bg}) must pass AA (>= 4.5), got ${ratio.toFixed(2)}`);
});

console.log(`\nResults: ${passed} passed, ${failed} failed`);

if (failed > 0) {
  process.exit(1);
} else {
  process.exit(0);
}
