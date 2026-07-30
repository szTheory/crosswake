/**
 * Tests for compile-tokens.js (TDD RED phase)
 * Run: node --test brandbook/tools/compile-tokens.test.mjs
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execSync } from 'node:child_process';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, '../..');
const TOKENS_JSON = resolve(ROOT, 'brandbook/tokens/crosswake.tokens.json');
const TOKENS_CSS = resolve(ROOT, 'brandbook/tokens/tokens.css');
const COMPILE_SCRIPT = resolve(ROOT, 'brandbook/tools/compile-tokens.js');

// ─── flattenTokens / resolveAlias unit tests ────────────────────────────────

// Import internal helpers by requiring the module
// compile-tokens.js must export { flattenTokens, resolveAlias } for testing
let flattenTokens, resolveAlias;
try {
  const mod = await import('./compile-tokens.js');
  flattenTokens = mod.flattenTokens;
  resolveAlias = mod.resolveAlias;
} catch {
  // Will fail in RED phase — that's expected
  flattenTokens = null;
  resolveAlias = null;
}

test('compile-tokens.js exports flattenTokens', () => {
  assert.ok(flattenTokens !== null, 'flattenTokens must be exported from compile-tokens.js');
  assert.strictEqual(typeof flattenTokens, 'function');
});

test('compile-tokens.js exports resolveAlias', () => {
  assert.ok(resolveAlias !== null, 'resolveAlias must be exported from compile-tokens.js');
  assert.strictEqual(typeof resolveAlias, 'function');
});

test('flattenTokens extracts leaf nodes into dot-path map', () => {
  const input = {
    primitive: {
      $type: 'color',
      current: {
        '950': { $value: '#09141A', $description: 'Primary dark' }
      }
    }
  };
  const result = flattenTokens(input);
  assert.ok('primitive.current.950' in result, 'must flatten primitive.current.950');
  assert.strictEqual(result['primitive.current.950'].$value, '#09141A');
});

test('flattenTokens skips $-prefixed keys (group-level metadata)', () => {
  const input = {
    primitive: {
      $type: 'color',
      wake: {
        '700': { $value: '#2B756A' }
      }
    }
  };
  const result = flattenTokens(input);
  // $type should NOT appear as a leaf key
  const keys = Object.keys(result);
  assert.ok(!keys.some(k => k.includes('$type')), 'must not flatten $-prefixed metadata');
  assert.ok('primitive.wake.700' in result, 'must include primitive.wake.700');
});

test('flattenTokens handles a leaf at depth 2 (primitive.white)', () => {
  const input = {
    primitive: {
      $type: 'color',
      white: { $value: '#FFFFFF', $description: 'White' }
    }
  };
  const result = flattenTokens(input);
  assert.ok('primitive.white' in result, 'must flatten primitive.white (depth-2 leaf)');
  assert.strictEqual(result['primitive.white'].$value, '#FFFFFF');
});

test('resolveAlias converts {primitive.foam.50} to var(--cw-primitive-foam-50)', () => {
  const alias = '{primitive.foam.50}';
  const result = resolveAlias(alias);
  assert.strictEqual(result, 'var(--cw-primitive-foam-50)');
});

test('resolveAlias converts {primitive.current.950} correctly', () => {
  const result = resolveAlias('{primitive.current.950}');
  assert.strictEqual(result, 'var(--cw-primitive-current-950)');
});

test('resolveAlias converts {primitive.white} (no stop number) correctly', () => {
  const result = resolveAlias('{primitive.white}');
  assert.strictEqual(result, 'var(--cw-primitive-white)');
});

test('resolveAlias returns non-alias values unchanged', () => {
  const hex = '#FFFFFF';
  const result = resolveAlias(hex);
  assert.strictEqual(result, '#FFFFFF');
});

// ─── Generated tokens.css structural tests ───────────────────────────────────

test('tokens.css exists after script execution', () => {
  // Script must have been run before this test; we just check if it exists
  // In RED phase this will fail if tokens.css doesn't exist yet
  assert.ok(existsSync(TOKENS_CSS), 'brandbook/tokens/tokens.css must exist');
});

test('tokens.css first line contains GENERATED header', () => {
  const content = readFileSync(TOKENS_CSS, 'utf8');
  const firstLine = content.split('\n')[0];
  assert.ok(firstLine.includes('GENERATED from crosswake.tokens.json'),
    'first line must contain GENERATED header');
});

test('tokens.css contains >= 20 var(--cw-primitive-) references', () => {
  const content = readFileSync(TOKENS_CSS, 'utf8');
  const matches = content.match(/var\(--cw-primitive-/g) || [];
  assert.ok(matches.length >= 20,
    `semantic tier must reference primitive vars >=20 times; got ${matches.length}`);
});

test('tokens.css semantic tier contains no inline hex (#RRGGBB) outside primitive block', () => {
  const content = readFileSync(TOKENS_CSS, 'utf8');
  // Split into sections; semantic section starts after second :root block (after primitive)
  // Simple check: find lines with --cw-[group]- (not --cw-primitive-) that contain hex
  const lines = content.split('\n');
  const semanticHexLines = lines.filter(line => {
    const isSemanticVar = /--cw-(?!primitive-)/.test(line);
    const hasHex = /#[0-9a-fA-F]{6}/.test(line);
    return isSemanticVar && hasHex;
  });
  assert.strictEqual(semanticHexLines.length, 0,
    `semantic tier must not inline hex; offending lines: ${semanticHexLines.join('; ')}`);
});

test('tokens.css contains prefers-color-scheme: dark block', () => {
  const content = readFileSync(TOKENS_CSS, 'utf8');
  assert.ok(content.includes('prefers-color-scheme: dark'),
    'must contain @media prefers-color-scheme: dark');
});

test('tokens.css contains [data-theme="dark"] block', () => {
  const content = readFileSync(TOKENS_CSS, 'utf8');
  assert.ok(content.includes('[data-theme="dark"]'),
    'must contain [data-theme="dark"] explicit toggle block');
});

test('running compile-tokens.js twice produces byte-identical output (deterministic)', () => {
  // Run once (already run above in earlier test or by setup)
  execSync(`node ${COMPILE_SCRIPT}`, { cwd: ROOT });
  const first = readFileSync(TOKENS_CSS, 'utf8');
  // Run again
  execSync(`node ${COMPILE_SCRIPT}`, { cwd: ROOT });
  const second = readFileSync(TOKENS_CSS, 'utf8');
  assert.strictEqual(first, second, 'tokens.css must be byte-identical on re-run');
});

test('compile-tokens.js has no require() calls for npm packages', () => {
  const source = readFileSync(COMPILE_SCRIPT, 'utf8');
  const requireCalls = source.match(/require\(['"]([^'"]+)['"]\)/g) || [];
  const allowedModules = new Set(['fs', 'path']);
  const forbidden = requireCalls.filter(call => {
    const match = call.match(/require\(['"]([^'"]+)['"]\)/);
    return match && !allowedModules.has(match[1]);
  });
  assert.strictEqual(forbidden.length, 0,
    `compile-tokens.js must use only fs/path; found: ${forbidden.join(', ')}`);
});

// ─── Font & dimension token tests ────────────────────────────────────────────

const PRIV_TOKENS_CSS = resolve(ROOT, 'priv/static/crosswake/tokens.css');

test('tokens.css contains --cw-font-display with quoted font stack', () => {
  const content = readFileSync(TOKENS_CSS, 'utf8');
  assert.ok(content.includes('--cw-font-display: "Space Grotesk"'),
    '--cw-font-display must start with quoted "Space Grotesk"');
});

test('tokens.css contains --cw-font-body with quoted font stack', () => {
  const content = readFileSync(TOKENS_CSS, 'utf8');
  assert.ok(content.includes('--cw-font-body: "Atkinson Hyperlegible Next"'),
    '--cw-font-body must start with quoted "Atkinson Hyperlegible Next"');
});

test('tokens.css contains --cw-font-mono with quoted font stack', () => {
  const content = readFileSync(TOKENS_CSS, 'utf8');
  assert.ok(content.includes('--cw-font-mono: "JetBrains Mono"'),
    '--cw-font-mono must start with quoted "JetBrains Mono"');
});

test('tokens.css contains --cw-text-scale-md: 16px', () => {
  const content = readFileSync(TOKENS_CSS, 'utf8');
  assert.ok(content.includes('--cw-text-scale-md: 16px'),
    '--cw-text-scale-md must be 16px');
});

test('tokens.css contains --cw-radius-lg: 14px', () => {
  const content = readFileSync(TOKENS_CSS, 'utf8');
  assert.ok(content.includes('--cw-radius-lg: 14px'),
    '--cw-radius-lg must be 14px');
});

test('tokens.css contains --cw-display-scale-sm: 28px', () => {
  const content = readFileSync(TOKENS_CSS, 'utf8');
  assert.ok(content.includes('--cw-display-scale-sm: 28px'),
    '--cw-display-scale-sm must be 28px');
});

test('priv/static/crosswake/tokens.css exists after script execution', () => {
  execSync(`node ${COMPILE_SCRIPT}`, { cwd: ROOT });
  assert.ok(existsSync(PRIV_TOKENS_CSS), 'priv/static/crosswake/tokens.css must exist');
});

test('priv/static/crosswake/tokens.css is byte-identical to brandbook/tokens/tokens.css', () => {
  execSync(`node ${COMPILE_SCRIPT}`, { cwd: ROOT });
  const brand = readFileSync(TOKENS_CSS, 'utf8');
  const priv  = readFileSync(PRIV_TOKENS_CSS, 'utf8');
  assert.strictEqual(brand, priv, 'both outputs must be byte-identical');
});

// ─── Phase 155 D-27 / T-155-11: semantic-token count cap ────────────────────
// AUDIT.md:392 documents a hard cap of 30 semantic tokens. No mechanical test
// existed before this phase — this pins the count so uncapped growth turns the
// gate red instead of silently exhausting the documented budget.

function semanticTierBlock(css) {
  const start = css.indexOf('/* ─── Semantic tier (public contract) ─── */');
  const end = css.indexOf('/* ─── Dark mode ─── */');
  assert.ok(start !== -1 && end !== -1 && end > start,
    'tokens.css must contain a delimited Semantic tier block between the ' +
    '"Semantic tier" and "Dark mode" comment markers');
  return css.slice(start, end);
}

function countSemanticProps(css) {
  const block = semanticTierBlock(css);
  const matches = block.match(/^\s*--cw-[a-z0-9-]+:/gm) || [];
  return matches.length;
}

test('compiled tokens.css semantic tier is at most 30 --cw- custom properties (AUDIT.md:392 hard cap)', () => {
  execSync(`node ${COMPILE_SCRIPT}`, { cwd: ROOT });
  const css = readFileSync(TOKENS_CSS, 'utf8');
  const count = countSemanticProps(css);
  assert.ok(count <= 30,
    `AUDIT.md:392 documents a hard cap of 30 semantic tokens; compiled tokens.css ` +
    `has ${count}. Do not invent tokens beyond the documented spec.`);
});

test('compiled tokens.css semantic tier is exactly 29 --cw- custom properties today (Phase 155 D-27: 1 slot remains)', () => {
  execSync(`node ${COMPILE_SCRIPT}`, { cwd: ROOT });
  const css = readFileSync(TOKENS_CSS, 'utf8');
  const count = countSemanticProps(css);
  assert.strictEqual(count, 29,
    `expected exactly 29 semantic tokens (AUDIT.md:392 cap of 30, 1 slot remaining ` +
    `after Phase 155's --cw-status-error-fg addition), got ${count}. A silent ` +
    `addition must be caught immediately, not only at the ceiling.`);
});

// ─── Phase 155 T-155-10 / RESEARCH Pitfall 2: group exhaustiveness ──────────
// compile-tokens.js:76's `groups` array is a curated filter; a colour-typed
// top-level group added to crosswake.tokens.json without also being added to
// that array compiles valid, green-passing CSS with the token silently
// dropped (D-29's scrim-goes-transparent failure mode). This assertion makes
// that silent drop impossible: every colour-typed top-level group in the JSON
// must produce at least one compiled --cw-<group>-* custom property.

test('every color-typed top-level token group emits at least one compiled --cw-<group>-* custom property', () => {
  execSync(`node ${COMPILE_SCRIPT}`, { cwd: ROOT });
  const tokensJson = JSON.parse(readFileSync(TOKENS_JSON, 'utf8'));
  const css = readFileSync(TOKENS_CSS, 'utf8');
  const block = semanticTierBlock(css);

  const colorGroups = Object.entries(tokensJson)
    .filter(([key, value]) => key !== 'primitive' && value && value['$type'] === 'color')
    .map(([key]) => key);

  assert.ok(colorGroups.length > 0, 'expected at least one non-primitive color-typed group in crosswake.tokens.json');

  for (const group of colorGroups) {
    const pattern = new RegExp(`--cw-${group}-[a-z0-9-]+:`);
    assert.ok(pattern.test(block),
      `color-typed group "${group}" in crosswake.tokens.json must emit at least one ` +
      `--cw-${group}-* custom property in the compiled semantic tier — if this fails, ` +
      `the group is missing from compile-tokens.js's \`groups\` array (RESEARCH Pitfall 2)`);
  }
});
