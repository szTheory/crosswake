/**
 * Contract/pin test for check-consumer-drift.mjs
 * Pins manifest completeness, asserts green baseline (gate exits 0 on current tree),
 * and proves every PROOF-01 success criterion with synthetic positive fixtures
 * and every false-positive guard with negative fixtures.
 *
 * Run: node --test brandbook/tools/check-consumer-drift.test.mjs
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execSync } from 'node:child_process';

import {
  findHexColors,
  findPrimitiveRefs,
  checkCssSemanticCoverage,
  findRetiredTailwindInClassAttrs,
  MANIFEST,
} from './check-consumer-drift.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, '../..');

// ─── Manifest completeness ────────────────────────────────────────────────────

test('manifest has exactly 5 entries', () => {
  assert.strictEqual(MANIFEST.length, 5,
    `MANIFEST must have exactly 5 entries; got ${MANIFEST.length}`);
});

test('all manifest files exist on disk', () => {
  for (const entry of MANIFEST) {
    const abs = resolve(ROOT, entry.path);
    assert.ok(existsSync(abs), `manifest file must exist: ${entry.path}`);
  }
});

// ─── PROOF-01 SC #1: Hex injection ───────────────────────────────────────────

test('findHexColors: detects #2B756A hex color in CSS value position (SC #1)', () => {
  const content = 'color: #2B756A;';
  const hits = findHexColors(content);
  assert.strictEqual(hits.length, 1, 'must detect one hex violation');
  assert.ok(hits[0].text.includes('#2B756A'),
    `violation text must include #2B756A; got: ${hits[0].text}`);
  // The palette name wake-700 should appear since #2B756A is a known palette color
  assert.ok(hits[0].text.includes('wake-700'),
    `violation text must include palette name wake-700; got: ${hits[0].text}`);
});

// ─── CR-01: hex detected in non-colon value contexts ─────────────────────────

test('findHexColors: detects #fff after = (CSS custom-property assignment)', () => {
  const hits = findHexColors('--x=#ffffff');
  assert.strictEqual(hits.length, 1, 'must detect hex after "="; got ' + hits.length);
});

test('findHexColors: detects #fff after ; (value separator)', () => {
  const hits = findHexColors('a:1;#ffffff');
  assert.strictEqual(hits.length, 1, 'must detect hex after ";"; got ' + hits.length);
});

test('findHexColors: detects hex inside an attribute (attr="#fff")', () => {
  const hits = findHexColors('stop-color="#ffffff"');
  assert.strictEqual(hits.length, 1, 'must detect hex inside attribute; got ' + hits.length);
});

// ─── WR-02: 4-digit (#RGBA) hex is valid CSS and must be detected ────────────

test('findHexColors: detects 4-digit #RGBA hex (#fff8)', () => {
  const hits = findHexColors('color: #fff8;');
  assert.strictEqual(hits.length, 1, 'must detect 4-digit #RGBA hex; got ' + hits.length);
});

// ─── WR-05: 8-digit #RRGGBBAA hex is detected as one full-length token ────────

test('findHexColors: detects 8-digit #RRGGBBAA hex as one token', () => {
  const hits = findHexColors('color: #2B756AFF;');
  assert.strictEqual(hits.length, 1, 'must detect 8-digit hex; got ' + hits.length);
  assert.ok(hits[0].text.includes('#2B756AFF'),
    `8-digit match must be the full token; got: ${hits[0].text}`);
});

// ─── PROOF-01 SC #2: Lost coverage (checkCssSemanticCoverage) ────────────────

test('checkCssSemanticCoverage: no var(--cw-) returns ok=false (SC #2)', () => {
  const content = 'body { color: red; }';
  const result = checkCssSemanticCoverage(content);
  assert.ok(!result.ok, 'must return ok=false when no var(--cw-) present');
});

test('checkCssSemanticCoverage: at least one var(--cw-) returns ok=true', () => {
  const content = 'a { color: var(--cw-text-default); }';
  const result = checkCssSemanticCoverage(content);
  assert.ok(result.ok, 'must return ok=true when var(--cw-) present');
});

// ─── Primitive injection ──────────────────────────────────────────────────────

test('findPrimitiveRefs: detects var(--cw-primitive-foam-50)', () => {
  const content = 'color: var(--cw-primitive-foam-50);';
  const hits = findPrimitiveRefs(content);
  assert.ok(hits.length >= 1, 'must detect primitive token reference');
});

test('findPrimitiveRefs: does not flag semantic var(--cw-surface-default)', () => {
  const content = 'color: var(--cw-surface-default);';
  const hits = findPrimitiveRefs(content);
  assert.strictEqual(hits.length, 0, 'semantic var must not be flagged as primitive');
});

// ─── Retired Tailwind in class attribute ──────────────────────────────────────

test('findRetiredTailwindInClassAttrs: flex in class attr is flagged', () => {
  const content = '<div class="flex items-center">';
  const hits = findRetiredTailwindInClassAttrs(content);
  assert.ok(hits.some(h => h.text === 'flex'), 'must detect flex in class attr');
});

// ─── WR-01: single-quoted and newline-wrapped class lists are scanned ────────

test("findRetiredTailwindInClassAttrs: single-quoted class='flex' is flagged", () => {
  const hits = findRetiredTailwindInClassAttrs("<div class='flex'>");
  assert.ok(hits.some(h => h.text === 'flex'),
    `single-quoted class attr must be scanned; got: ${JSON.stringify(hits)}`);
});

test('findRetiredTailwindInClassAttrs: newline-wrapped class list is scanned', () => {
  const content = '<div\n class="foo\n flex">';
  const hits = findRetiredTailwindInClassAttrs(content);
  assert.ok(hits.some(h => h.text === 'flex'),
    `newline-wrapped class list must be scanned; got: ${JSON.stringify(hits)}`);
});

// ─── WR-01 documented gap: class={...} dynamic binding is NOT scanned ─────────

test('findRetiredTailwindInClassAttrs: class={...} dynamic binding is a documented gap (not flagged)', () => {
  const hits = findRetiredTailwindInClassAttrs('<div class={@foo}>');
  assert.strictEqual(hits.length, 0,
    'class={...} dynamic bindings are an accepted documented blind spot (WR-01)');
});

// ─── CR-02: per-token matching — substring near-misses are NOT flagged ───────

test('findRetiredTailwindInClassAttrs: inline-flex is NOT flagged (not exact "flex")', () => {
  const hits = findRetiredTailwindInClassAttrs('<div class="inline-flex gap-2">');
  assert.strictEqual(hits.length, 0,
    `inline-flex must not match exact token "flex"; got: ${JSON.stringify(hits)}`);
});

test('findRetiredTailwindInClassAttrs: flex-col is NOT flagged (not exact "flex")', () => {
  const hits = findRetiredTailwindInClassAttrs('<div class="flex-col">');
  assert.strictEqual(hits.length, 0,
    `flex-col must not match exact token "flex"; got: ${JSON.stringify(hits)}`);
});

test('findRetiredTailwindInClassAttrs: reflex is NOT flagged (not exact "flex")', () => {
  const hits = findRetiredTailwindInClassAttrs('<div class="reflex">');
  assert.strictEqual(hits.length, 0,
    `reflex must not match exact token "flex"; got: ${JSON.stringify(hits)}`);
});

// ─── False-positive guard: #id selector ──────────────────────────────────────

test('findHexColors: #id CSS selector is NOT flagged as hex color', () => {
  const content = '#status { color: var(--cw-text-muted); }';
  const hits = findHexColors(content);
  assert.strictEqual(hits.length, 0, '#id selector must not be flagged as hex color');
});

// ─── Scoped design-token layer: hex allowed in --custom-property values ──────

test('findHexColors: hex in a --custom-property declaration is NOT flagged', () => {
  const hits = findHexColors('  --adminpilot-accent: #2f6f73;');
  assert.strictEqual(hits.length, 0,
    'a consumer file may define its own scoped --token: #hex design-token layer');
});

test('findHexColors: hex in a real style value IS still flagged', () => {
  const hits = findHexColors('  color: #ff0000;');
  assert.strictEqual(hits.length, 1, 'hex in a style value (color:) must still be flagged');
});

test('findHexColors: a bad style-value hex after a token def on the same line IS flagged', () => {
  const hits = findHexColors('  --a: #2f6f73; color: #bad123;');
  assert.strictEqual(hits.length, 1, 'only the token-def hex is exempt; the style-value hex is flagged');
  assert.strictEqual(hits[0].text, '#bad123');
});

// ─── False-positive guard: rgba() shadow ─────────────────────────────────────

test('findHexColors: rgba() shadow is NOT flagged', () => {
  const content = 'box-shadow: 0 4px 6px rgba(9,20,26,0.06);';
  const hits = findHexColors(content);
  assert.strictEqual(hits.length, 0, 'rgba() shadow must not be flagged by hex regex');
});

// ─── False-positive guard: display:flex in <style> block ─────────────────────

test('findRetiredTailwindInClassAttrs: display:flex in <style> block is NOT flagged', () => {
  const content = '<style>body { display: flex; }</style><div class="btn-primary">';
  const hits = findRetiredTailwindInClassAttrs(content);
  assert.strictEqual(hits.length, 0,
    'CSS property display:flex in <style> block must not be flagged as retired Tailwind class');
});

// ─── False-positive guard: [scrollbar-gutter:stable] ─────────────────────────

test('findRetiredTailwindInClassAttrs: [scrollbar-gutter:stable] is NOT flagged', () => {
  const content = '<html lang="en" class="[scrollbar-gutter:stable]">';
  const hits = findRetiredTailwindInClassAttrs(content);
  assert.strictEqual(hits.length, 0,
    '[scrollbar-gutter:stable] must not be flagged — intentional layout utility not in retired blocklist');
});

// ─── Blocklist pin: all 9 tokens must be detected ────────────────────────────

test('findRetiredTailwindInClassAttrs: blocklist pin — all 9 retired tokens are flagged in class attrs', () => {
  const tokens = [
    'flex',
    'bg-white',
    'bg-cw-',
    'text-cw-',
    'min-h-screen',
    'border-cw-',
    'border-gray-',
    'space-y-',
    'max-w-md',
  ];
  for (const t of tokens) {
    const content = `<div class="${t}">`;
    const hits = findRetiredTailwindInClassAttrs(content);
    assert.ok(hits.length >= 1,
      `blocklist token "${t}" must be detected in class attr; got 0 hits`);
  }
});

// ─── Green baseline integration: gate exits 0 on the current normalized tree ──

test('check-consumer-drift.mjs exits 0 on current clean tree (green baseline)', () => {
  const scriptPath = resolve(ROOT, 'brandbook/tools/check-consumer-drift.mjs');
  try {
    execSync(`node ${scriptPath}`, { cwd: ROOT, stdio: 'pipe' });
  } catch (err) {
    // Surface the gate's captured stdout/stderr (the ::error violation lines)
    // so a red baseline is diagnosable from the test output alone.
    assert.fail(
      'gate must exit 0 on the current normalized tree, but it exited non-zero:\n' +
      `--- stdout ---\n${err.stdout?.toString() ?? ''}\n` +
      `--- stderr ---\n${err.stderr?.toString() ?? ''}`
    );
  }
});
