/**
 * Tests for gen-wordmark.mjs
 * Covers LOGO-01 unit checks per 103-RESEARCH.md "Validation Architecture"
 * Run: node --test brandbook/tools/gen-wordmark.test.mjs
 *
 * Tests run gen-wordmark's exported generateWordmark() against the real
 * downloaded TTF and assert on the produced SVG string.
 *
 * RED phase: tests written before implementation; all will fail until
 * gen-wordmark.mjs exports generateWordmark().
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, '../..');
const TTF_PATH = resolve(__dirname, 'fonts/SpaceGrotesk[wght].ttf');
const BASE_SVG_PATH = resolve(ROOT, 'brandbook/logo/tournament/candidates/wordmark-base.svg');

// Import the generator function — will throw during RED if not yet implemented
let generateWordmark;
try {
  const mod = await import('./gen-wordmark.mjs');
  generateWordmark = mod.generateWordmark;
} catch {
  // Will fail in RED phase — expected
  generateWordmark = null;
}

// Test 1: Generated SVG contains exactly 9 <path elements (one per glyph in "Crosswake")
test('generated SVG has exactly 9 path elements', async () => {
  assert.ok(generateWordmark, 'generateWordmark must be exported from gen-wordmark.mjs');
  assert.ok(existsSync(TTF_PATH), `Font file must exist at ${TTF_PATH} — run fetch-fonts.sh first`);

  const svg = await generateWordmark(TTF_PATH);
  const matches = svg.match(/<path\s/g);
  assert.ok(matches, 'SVG must contain path elements');
  assert.equal(matches.length, 9,
    `Expected 9 path elements (one per glyph of "Crosswake"), got ${matches ? matches.length : 0}`);
});

// Test 2: Each glyph path id follows id="glyph-{i}-{char}" with w at index 5 and k at index 7
test('glyph-5-w and glyph-7-k path ids are present', async () => {
  assert.ok(generateWordmark, 'generateWordmark must be exported from gen-wordmark.mjs');
  const svg = await generateWordmark(TTF_PATH);

  assert.ok(svg.includes('id="glyph-5-w"'),
    'SVG must contain id="glyph-5-w" (w is at index 5 in "Crosswake": C=0,r=1,o=2,s=3,s=4,w=5)');
  assert.ok(svg.includes('id="glyph-7-k"'),
    'SVG must contain id="glyph-7-k" (k is at index 7 in "Crosswake": ...w=5,a=6,k=7)');
});

// Test 3: The wrapping group carries fill-rule="evenodd" (counters render hollow)
test('wrapping group has fill-rule="evenodd"', async () => {
  assert.ok(generateWordmark, 'generateWordmark must be exported from gen-wordmark.mjs');
  const svg = await generateWordmark(TTF_PATH);

  assert.ok(svg.includes('fill-rule="evenodd"'),
    'SVG <g> must carry fill-rule="evenodd" so counters in o/e/a/s/C render hollow');
});

// Test 4: Baseline used is positive — regression guard against y=0 / y-flip pitfalls
// The generator must compute baseline = font.ascender * (fontSize/unitsPerEm) and it must be > 0
test('computed baseline is positive (ascender-scaled, not zero)', async () => {
  assert.ok(generateWordmark, 'generateWordmark must be exported from gen-wordmark.mjs');

  // Call with inspectBaseline option to extract the baseline value used
  const result = await generateWordmark(TTF_PATH, { inspectBaseline: true });
  const baseline = typeof result === 'object' ? result.baseline : null;

  assert.ok(baseline !== null, 'generateWordmark must return { svg, baseline } when inspectBaseline: true');
  assert.ok(typeof baseline === 'number' && baseline > 0,
    `Baseline must be a positive number (ascender-scaled); got ${baseline}`);
});

// Test 5: No <text element appears in the output SVG (path-only requirement D-04)
test('output SVG contains no <text elements (path-only)', async () => {
  assert.ok(generateWordmark, 'generateWordmark must be exported from gen-wordmark.mjs');
  const svg = await generateWordmark(TTF_PATH);

  assert.ok(!svg.includes('<text'),
    'Output SVG must not contain <text elements — path-only SVG is required (D-04)');
});
