'use strict';
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '../..');
const JSON_PATH = path.join(ROOT, 'brandbook/tokens/crosswake.tokens.json');
const CSS_PATH = path.join(ROOT, 'brandbook/tokens/tokens.css');

// Flatten nested DTCG token tree to dot-path -> token map; skip $-prefixed metadata keys
function flattenTokens(obj, prefix, acc) {
  if (acc === undefined) { prefix = ''; acc = {}; }
  for (const [k, v] of Object.entries(obj)) {
    if (k.startsWith('$')) continue;
    const p = prefix ? prefix + '.' + k : k;
    if (v && typeof v === 'object' && '$value' in v) acc[p] = v;
    else if (v && typeof v === 'object') flattenTokens(v, p, acc);
  }
  return acc;
}

// Resolve "{primitive.foam.50}" -> "var(--cw-primitive-foam-50)"; pass non-aliases through
function resolveAlias(value) {
  if (typeof value === 'string' && value.startsWith('{') && value.endsWith('}'))
    return 'var(--cw-' + value.slice(1, -1).replace(/\./g, '-') + ')';
  return value;
}

function props(flat, paths, dark, isPrim) {
  return paths.map(p => {
    const t = flat[p];
    const raw = dark ? (t.$dark || t.$value) : t.$value;
    return '  --cw-' + p.replace(/\./g, '-') + ': ' + (isPrim ? raw : resolveAlias(raw)) + ';';
  }).join('\n');
}

function main() {
  let tokens;
  try { tokens = JSON.parse(fs.readFileSync(JSON_PATH, 'utf8')); }
  catch (err) { process.stderr.write('compile-tokens.js: ' + err.message + '\n'); process.exit(1); }

  const flat = flattenTokens(tokens);
  const all = Object.keys(flat).sort();
  const prim = all.filter(p => p.startsWith('primitive.'));
  const groups = ['surface', 'text', 'action', 'border', 'status', 'runtime'];
  const sem = all.filter(p => groups.some(g => p.startsWith(g + '.')));
  const darkSem = props(flat, sem, true, false);

  const out = [
    '/* GENERATED from crosswake.tokens.json — do not edit */',
    '/* Edit crosswake.tokens.json, then run: node brandbook/tools/compile-tokens.js */',
    '',
    '/* ─── Primitive tier (internal — do not reference directly in component CSS) ─── */',
    ':root {', props(flat, prim, false, true), '}', '',
    '/* ─── Semantic tier (public contract) ─── */',
    ':root {', props(flat, sem, false, false), '}', '',
    '/* ─── Dark mode ─── */',
    '@media (prefers-color-scheme: dark) {',
    '  :root:not([data-theme]) {',
    darkSem.replace(/^  /gm, '    '),
    '  }', '}', '',
    '[data-theme="dark"] {', darkSem, '}', '',
    '/* ─── Forbidden pairings (DO NOT USE) ─────────────────────────────────────────── */',
    '/* stone-500 on foam-50:  4.09:1 — fails AA normal text                           */',
    '/* wake-500  on foam-50:  2.95:1 — role issue; dark-surface only                  */',
    '/* mist-200  on foam-50:  1.35:1 — border/dark-surface only                       */',
    '',
  ].join('\n');

  fs.writeFileSync(CSS_PATH, out, 'utf8');
  process.stdout.write('brandbook/tokens/tokens.css written\n');
}

if (require.main === module) main();
module.exports = { flattenTokens, resolveAlias };
