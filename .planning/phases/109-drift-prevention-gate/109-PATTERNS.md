# Phase 109: Drift-Prevention Gate — Pattern Map

**Mapped:** 2026-06-14
**Files analyzed:** 3 (2 new, 1 modified)
**Analogs found:** 3 / 3

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `brandbook/tools/check-consumer-drift.mjs` | utility/validator | batch (file scan → exit code) | `brandbook/tools/check-production.mjs` | exact |
| `brandbook/tools/check-consumer-drift.test.mjs` | test | batch (synthetic fixtures → assertions) | `brandbook/tools/compile-tokens.test.mjs` | exact |
| `.github/workflows/brandbook-verify.yml` | config | request-response (CI step addition + path trigger broadening) | existing `brand-structural` steps in same file | exact (same-file edit) |

---

## Pattern Assignments

### `brandbook/tools/check-consumer-drift.mjs` (utility/validator, batch file scan)

**Analog:** `brandbook/tools/check-production.mjs`

**Imports pattern** (`check-production.mjs` lines 25-31):
```javascript
import { readFileSync, readdirSync } from 'node:fs';
import { resolve, dirname, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import { checkSvg } from './check-candidates.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, '../..');
```

For the drift check, replace the `checkSvg` import with a named import of `parseHex` and `PALETTE` from `contrast.mjs`:
```javascript
import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseHex, PALETTE } from './contrast.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, '../..');
```

`parseHex` and `PALETTE` are both named exports on the final export line of `contrast.mjs` (line 181 of research excerpt):
```javascript
export { linearize, luminance, parseHex, contrast, PALETTE };
```

**PALETTE — 17-color brand hex set** (`contrast.mjs` lines 42-60):
```javascript
const PALETTE = {
  'current-950': '#09141A',
  'current-900': '#0F1E26',
  'current-800': '#162B35',
  'harbor-700':  '#254855',
  'wake-700':    '#2B756A',
  'wake-500':    '#4E9A8E',
  'kelp-800':    '#123B36',
  'brass-500':   '#C98A2E',
  'brass-700':   '#946017',
  'foam-50':     '#F7F1E6',
  'foam-100':    '#EFE6D6',
  'mist-200':    '#C9D4CF',
  'stone-500':   '#7C746A',
  'stone-600':   '#756D63',
  'rust-600':    '#9A4D35',
  'plum-700':    '#372D4C',
  'white':       '#FFFFFF',
};
```

`PALETTE` is used only for human-readable violation messages (name-lookup). Detection uses a broader independent regex — `parseHex` validates 6-digit hex only and throws on 3/8-digit; do not use it for scanning.

**Curated manifest pattern** — inline JS array, NOT a glob (D-02). Annotated with `type` for per-file-class rule dispatch:
```javascript
// Curated manifest — D-02: NOT a glob. Add new normalized consumers here.
// Excluded (deferred offenders):
//   examples/phoenix_host/priv/static/offline_study.js — #9A4D35/#fee2e2/#ef4444 (innerHTML)
//   examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_challenge_live.ex
//     — bg-[#F8FAFC] / bg-[#2563EB] (dead Tailwind). NOTE: CONTEXT.md has wrong path;
//     correct path verified: crosswake_example/saas_portal/... (not crosswake_example_web/live/...)
// tokens.css excluded — byte-parity covered by compile-tokens.test.mjs:222 (D-04).
const MANIFEST = [
  { path: 'examples/phoenix_host/priv/static/css/app.css',   type: 'css' },
  { path: 'priv/static/crosswake/offline.css',               type: 'css' },
  { path: 'priv/templates/crosswake/offline_ui/offline_page.html.heex.eex', type: 'heex' },
  { path: 'priv/templates/crosswake/offline_ui/offline_root.html.heex.eex', type: 'heex' },
  { path: 'examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex', type: 'heex' },
];
```

**Hex detection regex** (D-03 Rule 1 — with `#id`-selector false-positive guard):

Use a lookbehind to require the `#` to be preceded by a value-context character (`:`  `(` `,` or whitespace). This naturally excludes CSS ID selectors (which follow a selector context, not a value context) without needing post-match heuristics:
```javascript
// Matches hex color literals in value positions; excludes #id selectors.
// Lookahead ensures valid CSS hex lengths: 3, 6, or 8 digits only.
// Uses lookbehind: # must be preceded by ':', '(', ',', or whitespace.
const HEX_RE = /(?<=[:,(\s])#([0-9a-fA-F]{6}|[0-9a-fA-F]{8}|[0-9a-fA-F]{3})\b/g;
```

For line-by-line scanning with `file:line` reporting (mirroring `check-production.mjs` output style):
```javascript
function findHexColors(content) {
  const violations = [];
  const lines = content.split('\n');
  for (let i = 0; i < lines.length; i++) {
    const hexRe = /(?<=[:,(\s])#([0-9a-fA-F]{6}|[0-9a-fA-F]{8}|[0-9a-fA-F]{3})\b/g;
    let m;
    while ((m = hexRe.exec(lines[i])) !== null) {
      const hex6 = m[1].length === 6 ? m[0] : null;
      const paletteName = hex6 ? Object.entries(PALETTE).find(([, v]) => v.toUpperCase() === hex6.toUpperCase())?.[0] : null;
      violations.push({
        line: i + 1,
        text: paletteName ? `${m[0]} (${paletteName})` : m[0],
        rule: 'hex-color-forbidden',
      });
    }
  }
  return violations;
}
```

**Primitive token detection** (D-03 Rule 2):
```javascript
// Simple substring match — no false-positive risk.
const PRIMITIVE_RE = /var\(--cw-primitive-/;
```

**Semantic var presence** (D-03 Rule 3 — CSS files only):
```javascript
const SEMANTIC_VAR_RE = /var\(--cw-/;
const hasSemanticVar = SEMANTIC_VAR_RE.test(content);
```

**Retired Tailwind blocklist** (D-03 Rule 4 — HEEX/template files only). Derived from NORM-04 test contract at `test/mix/tasks/crosswake.gen.offline_ui_test.exs` lines 120-127:
```javascript
const RETIRED_TAILWIND = [
  'flex',          // layout utility — NOTE: must check class attrs only, not CSS text
  'bg-white',      // color utility
  'bg-cw-',        // primitive Tailwind color prefix (matches bg-cw-foam-50 etc.)
  'text-cw-',      // primitive Tailwind color prefix
  'min-h-screen',  // layout utility
  'border-cw-',    // primitive Tailwind border prefix
  'border-gray-',  // Tailwind system gray border
  'space-y-',      // spacing utility
  'max-w-md',      // sizing utility
];
```

**CRITICAL: Tailwind check must be scoped to `class="..."` attribute values only.** `index.html.heex` has `display: flex` in an inline `<style>` block — a naive `content.includes('flex')` false-positives. `[scrollbar-gutter:stable]` in `offline_root.html.heex.eex` is intentional and not in the blocklist; do not add it.
```javascript
function findRetiredTailwindInClassAttrs(content) {
  const violations = [];
  const classRe = /class="([^"]*)"/g;
  const lines = content.split('\n');
  let m;
  while ((m = classRe.exec(content)) !== null) {
    const classes = m[1];
    // Find line number by counting newlines up to match index
    const lineNum = content.slice(0, m.index).split('\n').length;
    for (const retired of RETIRED_TAILWIND) {
      if (classes.includes(retired)) {
        violations.push({ line: lineNum, text: retired, rule: 'retired-tailwind-class-forbidden' });
      }
    }
  }
  return violations;
}
```

**Core scan loop + exit pattern** (copy from `check-production.mjs` lines 73-126):
```javascript
// check-production.mjs lines 73-126 — the per-file loop + exit-1 convention
const allViolations = [];

for (const filePath of files) {
  const filename = relative(ROOT, filePath);
  let content;
  try {
    content = readFileSync(filePath, 'utf8');
  } catch (err) {
    allViolations.push({ file: filename, issues: [`Cannot read file: ${err.message}`] });
    continue;
  }

  const issues = checkSvg(content, filename);   // ← replace with drift check calls

  if (issues.length > 0) {
    allViolations.push({ file: filename, issues });
    console.error(`FAIL: ${filename}`);
    for (const issue of issues) {
      console.error(`  - ${issue}`);
    }
  } else if (verbose) {
    console.log(`  OK: ${filename}`);
  }
}

if (allViolations.length === 0) {
  console.log(`All ${files.length} production SVG(s) passed structural validation.`);
  process.exit(0);
} else {
  console.error(`\n${allViolations.length} file(s) failed production validation. Fix the above issues before proceeding.`);
  process.exit(1);
}
```

For the drift check, replace the `checkSvg` call block with per-manifest-entry dispatch. Violation message format: `file:line — rule` (success criterion requirement from CONTEXT.md). GitHub annotation format: `console.error('::error file=%s,line=%d::%s', relPath, lineNum, message)` (discretionary per CONTEXT).

**`IS_MAIN` guard** — copy from `check-candidates.mjs` line 110 to allow module import by the test:
```javascript
// check-candidates.mjs line 110-111
const IS_MAIN = process.argv[1] === fileURLToPath(import.meta.url);
if (!IS_MAIN) { /* imported as module — skip main */ }
else {
  // ... main scan loop ...
}
```

Export the per-file check functions so the test file can import and exercise them with synthetic fixtures without running the full scan.

**File header JSDoc** — copy the shebang + JSDoc block style from `check-production.mjs` lines 1-23:
```javascript
#!/usr/bin/env node
/**
 * brandbook/tools/check-consumer-drift.mjs
 * Structural drift gate for normalized consumer CSS and HEEX files.
 *
 * Scans a curated manifest of normalized consumer files and exits non-zero
 * when any file reintroduces a brand-color drift:
 *   1. Hardcoded hex color literal (#RGB / #RRGGBB / #RRGGBBAA)
 *   2. var(--cw-primitive-*) reference (semantic-only boundary rule)
 *   3. CSS file with zero var(--cw-*) references (token coverage lost)
 *   4. HEEX/template with retired Tailwind utility in class="..." attribute
 *
 * Usage:
 *   node brandbook/tools/check-consumer-drift.mjs [--verbose]
 *
 * Zero additional npm installs — uses only Node built-ins + contrast.mjs.
 */
```

---

### `brandbook/tools/check-consumer-drift.test.mjs` (test, batch synthetic-fixture assertions)

**Analog:** `brandbook/tools/compile-tokens.test.mjs`

**Imports pattern** (`compile-tokens.test.mjs` lines 1-16):
```javascript
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execSync } from 'node:child_process';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, '../..');
```

For the drift test, drop `execSync` (not needed) and add imports of the exported check functions:
```javascript
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, '../..');

// Import check functions for synthetic-fixture testing
import { findHexColors, findPrimitiveRefs, findRetiredTailwindInClassAttrs, checkCssSemanticCoverage } from './check-consumer-drift.mjs';
```

**`node:test` test block structure** — copy from `compile-tokens.test.mjs` lines 33-55 (use `test()` top-level, `assert.strictEqual` / `assert.ok`, descriptive string):
```javascript
test('tokens.css semantic tier contains no inline hex (#RRGGBB) outside primitive block', () => {
  const content = readFileSync(TOKENS_CSS, 'utf8');
  const lines = content.split('\n');
  const semanticHexLines = lines.filter(line => {
    const isSemanticVar = /--cw-(?!primitive-)/.test(line);
    const hasHex = /#[0-9a-fA-F]{6}/.test(line);
    return isSemanticVar && hasHex;
  });
  assert.strictEqual(semanticHexLines.length, 0,
    `semantic tier must not inline hex; offending lines: ${semanticHexLines.join('; ')}`);
});
```

**Manifest existence pin test** (modeled on `compile-tokens.test.mjs` lines 109-113):
```javascript
test('all manifest files exist on disk', () => {
  for (const entry of MANIFEST) {
    const abs = resolve(ROOT, entry.path);
    assert.ok(existsSync(abs), `manifest file must exist: ${entry.path}`);
  }
});
```

**Synthetic fixture injection pattern** — create minimal in-memory strings, do NOT write temp files:
```javascript
test('findHexColors: detects #2B756A hex color in CSS value position', () => {
  const content = 'color: #2B756A;';
  const hits = findHexColors(content);
  assert.strictEqual(hits.length, 1, 'must detect one hex violation');
  assert.ok(hits[0].text.includes('#2B756A'));
});

test('findHexColors: #id CSS selector is NOT flagged as hex color', () => {
  const content = '#status { color: var(--cw-text-muted); }';
  const hits = findHexColors(content);
  assert.strictEqual(hits.length, 0, '#id selector must not be flagged');
});

test('findHexColors: rgba() shadow is NOT flagged', () => {
  const content = 'box-shadow: 0 4px 6px rgba(9,20,26,0.06);';
  const hits = findHexColors(content);
  assert.strictEqual(hits.length, 0, 'rgba() must not be flagged by hex regex');
});

test('findPrimitiveRefs: detects var(--cw-primitive-foam-50) reference', () => {
  const content = 'color: var(--cw-primitive-foam-50);';
  const hits = findPrimitiveRefs(content);
  assert.ok(hits.length >= 1, 'must detect primitive token reference');
});

test('checkCssSemanticCoverage: zero var(--cw-) references fails', () => {
  const content = 'body { color: red; }';
  const result = checkCssSemanticCoverage(content);
  assert.ok(!result.ok, 'must fail when no var(--cw-) present');
});

test('findRetiredTailwindInClassAttrs: flex in class attr is flagged', () => {
  const content = '<div class="flex items-center">';
  const hits = findRetiredTailwindInClassAttrs(content);
  assert.ok(hits.some(h => h.text === 'flex'), 'must detect flex in class attr');
});

test('findRetiredTailwindInClassAttrs: display:flex in <style> block is NOT flagged', () => {
  const content = '<style>body { display: flex; }</style><div class="btn-primary">';
  const hits = findRetiredTailwindInClassAttrs(content);
  assert.strictEqual(hits.length, 0, 'CSS property display:flex must not be flagged');
});

test('findRetiredTailwindInClassAttrs: [scrollbar-gutter:stable] is NOT flagged', () => {
  const content = '<html lang="en" class="[scrollbar-gutter:stable]">';
  const hits = findRetiredTailwindInClassAttrs(content);
  assert.strictEqual(hits.length, 0, '[scrollbar-gutter:stable] must not be flagged — intentional layout utility');
});
```

**Green baseline test** — runs the actual script on the live tree (models `compile-tokens.test.mjs` lines 155-163 determinism test):
```javascript
test('check-consumer-drift.mjs exits 0 on current clean tree (green baseline)', () => {
  // Runs the full scan against real manifest files — must pass today
  const scriptPath = resolve(ROOT, 'brandbook/tools/check-consumer-drift.mjs');
  const { execSync } = await import('node:child_process');
  assert.doesNotThrow(
    () => execSync(`node ${scriptPath}`, { cwd: ROOT, stdio: 'pipe' }),
    'gate must exit 0 on current normalized tree'
  );
});
```

---

### `.github/workflows/brandbook-verify.yml` (config, CI step insertion + path broadening)

**Analog:** existing steps in same file (`brand-structural` job, lines 56-70)

**New step YAML shape** — copy the `check-production.mjs` / `check-candidates.mjs` plain-node step shape (lines 56-62):
```yaml
      - name: SVG structural validation - production marks
        working-directory: brandbook/tools
        run: node check-production.mjs
```

Apply to the drift check. Place after line 70 (`WCAG contrast matrix`) and before line 72 (`Install brand e2e dependencies`):
```yaml
      - name: Consumer drift gate (no hex / no primitives / semantic coverage)
        working-directory: brandbook/tools
        run: node check-consumer-drift.mjs
```

The `working-directory: brandbook/tools` convention means `node check-consumer-drift.mjs` resolves correctly. The script's internal `ROOT = resolve(__dirname, '../..')` handles manifest path resolution back to repo root regardless of cwd (Pitfall 4 guard).

**`on.paths` broadening** — current state (lines 19-25):
```yaml
on:
  pull_request:
    paths:
      - "brandbook/**"
  push:
    paths:
      - "brandbook/**"
```

D-01a replacement (add four consumer globs to BOTH triggers):
```yaml
on:
  pull_request:
    paths:
      - "brandbook/**"
      - "examples/phoenix_host/priv/static/css/app.css"
      - "priv/static/crosswake/**"
      - "priv/templates/crosswake/offline_ui/**"
      - "examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/**"
  push:
    paths:
      - "brandbook/**"
      - "examples/phoenix_host/priv/static/css/app.css"
      - "priv/static/crosswake/**"
      - "priv/templates/crosswake/offline_ui/**"
      - "examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/**"
```

`priv/static/crosswake/**` covers both `offline.css` and `tokens.css` — the latter closes the gap so the existing `compile-tokens.test.mjs:222` byte-parity test also fires on direct `tokens.css` edits (D-04 free win, zero new code).

**Do NOT touch:**
- `brand-visual` job (lines 84-119) — advisory, `continue-on-error: true`; leave entirely unchanged
- Any existing step order above line 70
- The workflow header comment (lines 1-15) — documents the required-vs-advisory contract; update if a clarifying note about the new step is desired, but not required

---

## Shared Patterns

### ROOT derivation (all new tool files)
**Source:** `brandbook/tools/compile-tokens.test.mjs` lines 12-13 AND `brandbook/tools/check-candidates.mjs` lines 23-24
**Apply to:** `check-consumer-drift.mjs` and `check-consumer-drift.test.mjs`
```javascript
const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, '../..');
```
This resolves from `brandbook/tools/` up two levels to repo root, making all manifest paths (`resolve(ROOT, entry.path)`) repo-root-relative and CI/local-identical.

### Plain-node exit-1 convention
**Source:** `brandbook/tools/check-production.mjs` lines 120-126
**Apply to:** `check-consumer-drift.mjs`
```javascript
if (allViolations.length === 0) {
  console.log(`All N file(s) passed structural validation.`);
  process.exit(0);
} else {
  console.error(`\nN file(s) failed. Fix the above issues before proceeding.`);
  process.exit(1);
}
```

### `IS_MAIN` guard for module/script dual use
**Source:** `brandbook/tools/check-candidates.mjs` line 110
**Apply to:** `check-consumer-drift.mjs` (so the test file can import check functions without triggering the main scan loop)
```javascript
const IS_MAIN = process.argv[1] === fileURLToPath(import.meta.url);
if (IS_MAIN) {
  // main scan loop
}
```

### Error handling on file read
**Source:** `brandbook/tools/check-production.mjs` lines 79-82
**Apply to:** `check-consumer-drift.mjs` per-file loop
```javascript
try {
  content = readFileSync(filePath, 'utf8');
} catch (err) {
  allViolations.push({ file: filename, issues: [`Cannot read file: ${err.message}`] });
  continue;
}
```

### `node --test` test invocation in YAML
**Source:** `.github/workflows/brandbook-verify.yml` lines 64-70
**Apply to:** the companion `check-consumer-drift.test.mjs` step (second new step, also before Playwright install)
```yaml
      - name: Token JSON round-trip
        working-directory: brandbook/tools
        run: node --test compile-tokens.test.mjs

      - name: WCAG contrast matrix
        working-directory: brandbook/tools
        run: node --test contrast.test.mjs
```

The test step follows the same `node --test <file>` pattern with `working-directory: brandbook/tools`.

---

## No Analog Found

All three files have close analogs. No entries in this section.

---

## Critical False-Positive Guards (must be implemented)

These are not optional — the gate will break on a clean tree without them:

| Guard | Risk | Implementation |
|---|---|---|
| `#id`-selector guard | `#status { }` flagged as hex color | Lookbehind: `(?<=[:,(\s])#` requires value-context before `#` |
| `display:flex` in `<style>` block | `index.html.heex` inline `<style>` flagged for `flex` | Scope Tailwind checks to `class="..."` attribute values via `classRe = /class="([^"]*)"/g` |
| `rgba()` shadow | `rgba(9,20,26,0.06)` flagged | Non-issue: `#` hex regex naturally ignores `rgba()` — no extra guard needed |
| `[scrollbar-gutter:stable]` | `offline_root.html.heex.eex` flagged for arbitrary-value Tailwind | Not in RETIRED_TAILWIND list — no action needed; document in manifest comment |
| `parseHex()` 6-digit-only | Throws on 3/8-digit hex in detection | Use `parseHex` only for PALETTE name-lookup (after confirming 6-digit match); use independent detection regex for scanning |
| Manifest paths relative to ROOT | ENOENT when `working-directory: brandbook/tools` is set | `resolve(ROOT, entry.path)` where ROOT derives from `import.meta.url` |
| Deferred offender correct path | Wrong path silently "works" until someone adds file at CONTEXT path | Use `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_challenge_live.ex` (not `crosswake_example_web/live/saas_portal/…`) in manifest header comment |

---

## Metadata

**Analog search scope:** `brandbook/tools/`, `.github/workflows/`
**Files read:** `check-production.mjs`, `check-candidates.mjs`, `compile-tokens.test.mjs`, `contrast.mjs` (lines 1-70), `brandbook-verify.yml`
**Pattern extraction date:** 2026-06-14
