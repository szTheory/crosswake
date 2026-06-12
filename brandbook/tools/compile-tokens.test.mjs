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
