# Phase 109: Drift-Prevention Gate — Research

**Researched:** 2026-06-14
**Domain:** Node.js CI tooling — deterministic textual consumer-drift detection
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** New step inside existing `brand-structural` job — same required check name, no new branch-protection entry.
Implement as a Node script in `brandbook/tools/`. No browser, no Playwright, no Elixir toolchain.
Step goes BEFORE the Playwright install steps.

**D-01a:** Broaden `on.paths` (both `pull_request` and `push`) to add:
- `examples/phoenix_host/priv/static/css/app.css`
- `priv/static/crosswake/**`
- `priv/templates/crosswake/offline_ui/**`
- `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/**`

**D-02:** Curated declarative manifest — NOT a glob. Deferred offenders excluded. Per-file-type assertions expressed per entry.

**D-03:** Per-file-class assertions:
- Every file: forbid `#`-hex color literal (regex `#[0-9a-fA-F]{3,8}` with `#id`-selector guard)
- Every file: forbid `var(--cw-primitive-`
- CSS files only: require ≥1 `var(--cw-` reference
- HEEX/template files: forbid retired Tailwind utility classes (no inline `var(--cw-` required)
- Leave `rgba(9,20,26,0.06)` shadow alone — hex regex naturally ignores `rgba()`

**D-04:** Do NOT write a new tokens.css byte-parity check. `compile-tokens.test.mjs` line 222 already covers it; D-01a closes the path-trigger gap.

### Claude's Discretion

- Script form: plain `node brandbook/tools/check-consumer-drift.mjs` (exit 1) OR `node --test …test.mjs`
- Exact manifest representation (inline JS array/object vs. adjacent `.json`/`.mjs`)
- Exact regexes (subject to D-03 guards)
- Exact step name and ordering within the job (subject to "before Playwright install")
- Exact Tailwind blocklist (derive from NORM-04 test contract)
- Wording of failure messages and `::error` GitHub annotations

### Deferred Ideas (OUT OF SCOPE)

- Fixing `offline_study.js` or `step_up_challenge_live.ex`
- Shadow-opacity token (`rgba(9,20,26,0.06)`)
- Glob-based auto-discovery
- Adding new required-status-check name to branch-protection
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROOF-01 | Deterministic structural check, extending `brand-structural` CI gate, fails build when normalized consumer contains hardcoded brand hex or stops referencing the token source | Verified: live tree is zero-hex + `var(--cw-` present across all manifest targets; gate will pass green immediately; step placement and YAML anchors confirmed below |
</phase_requirements>

---

## Summary

Phase 109 adds a single new step to the existing required `brand-structural` CI job that textually scans a curated manifest of normalized consumer files and exits non-zero on any brand-color drift (bare hex, primitive token reference, or lost `var(--cw-` coverage). The work is entirely within `brandbook/tools/` and `.github/workflows/brandbook-verify.yml`; no consumer files change.

**Every manifest target is verified zero-hex and `var(--cw-`-bearing TODAY.** The gate lands green. The research below supplies the exact code snippets, line numbers, YAML anchors, and regex guards the planner needs — including two divergences from CONTEXT claims that must be flagged.

**Primary recommendation:** Implement as a plain Node script (`check-consumer-drift.mjs`, `node` invocation, `process.exit(1)` on violation) following the `check-production.mjs` convention. This gives the cleanest one-command local runner. Add a companion `node --test check-consumer-drift.test.mjs` for the contract/pin test, following the `compile-tokens.test.mjs` convention. Both run before the Playwright install steps in the YAML.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Hex/primitive detection regex | Build tooling (Node script) | — | Textual scan; no runtime component |
| Manifest definition | Build tooling (Node script) | — | Curated, per-file-type; lives in the script |
| CI job integration | CI workflow YAML | — | Extends existing `brand-structural` step list |
| Path-trigger broadening | CI workflow YAML | — | `on.paths` addition; activates gate on consumer edits |
| Contract/pin test | Build tooling (`node --test`) | — | Mirrors NORM-04 generator-test pattern |

---

## Live-Tree Verification

### Gap 1 — CONTEXT line-count figures are close but not exact

CONTEXT claims `offline.css` has 38 `var(--cw-` references. Live count: **39**. Minor drift (one extra occurrence added since context-gathering). The ≥1 rule the gate asserts is what matters; this is not a correctness issue.

CONTEXT claims `app.css` has 47 `var(--cw-` references. Live count: **47 occurrences across 43 lines** (some lines have multiple). Both figures are consistent; 47 occurrences confirmed.

`index.html.heex`: CONTEXT does not give a count. Live count: **17 occurrences** of `var(--cw-` (all inside the inline `<style>` block).

### Gap 2 — DEFERRED OFFENDER PATH HAS MOVED (HIGH PRIORITY)

CONTEXT (`<canonical_refs>`) names the deferred offender as:
```
examples/phoenix_host/lib/crosswake_example_web/live/saas_portal/step_up_challenge_live.ex
```

**This path does not exist.** The actual file is at:
```
examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_challenge_live.ex
```

The file still contains the expected hex/Tailwind violations:
```
bg-[#F8FAFC]
bg-[#2563EB]
```

**Impact on the gate:** The manifest must reference the correct path if it ever documents exclusions. Since D-02 uses a curated INCLUDE list (not an exclude list), the wrong path in CONTEXT is a documentation error only — the gate is unaffected as long as the manifest simply does not include this file. However the planner must use the correct path in the manifest header comment that explains why the file is excluded.

### Gap 3 — `offline_root.html.heex.eex` contains `[scrollbar-gutter:stable]` in a class attribute

The template file contains:
```html
<html lang="en" class="[scrollbar-gutter:stable]">
```

This is a JIT Tailwind arbitrary-value utility (`[scrollbar-gutter:stable]`) in a class attribute. The NORM-04 test (`crosswake.gen.offline_ui_test.exs`) asserts `refute combined =~ "flex"` but does NOT assert against `scrollbar-gutter`. The D-03 retired Tailwind blocklist in 108-CONTEXT covers: `flex`, `bg-white`, `bg-cw-*`, `text-cw-*`, `min-h-screen`, `border-cw-*`, `border-gray-*`, `space-y-*`, `max-w-md`. It does not mention arbitrary-value Tailwind `[…]` syntax.

**Assessment:** This is intentional — `[scrollbar-gutter:stable]` is a layout primitive that has no token equivalent and is not a brand-color drift. The D-03 retired Tailwind blocklist targets COLOR and layout classes that were migrated to tokens. The gate should NOT add `scrollbar-gutter` to the blocklist. Document this as the intended exception in the manifest header comment.

### Gap 4 — `index.html.heex` has `display: flex` as CSS property values (NOT Tailwind classes)

The `grep -oP '(flex)' index.html.heex` hit `display: flex` inside the inline `<style>` block — plain CSS, not a Tailwind utility class. The file's actual class attributes are:
```
class="btn-primary"
class="btn-success"
class="btn-danger"
```

No retired Tailwind utility classes are present. `flex` as a CSS value is irrelevant to the Tailwind blocklist check. The gate regex for retired classes should match only class attribute content, not arbitrary CSS text, OR the blocklist should use word-boundary anchors that rule out CSS property values.

---

## Reusable Code — Exact Signatures

### `contrast.mjs` — `parseHex()` and `PALETTE` (lines 19-29, 42-60)

```javascript
// contrast.mjs lines 19-29
// Validates hex string format before parseInt (ASVS V5 input validation)
function parseHex(hex) {
  const clean = hex.replace('#', '');
  if (!/^[0-9a-fA-F]{6}$/.test(clean)) {
    throw new Error(`Invalid hex color: ${hex}`);
  }
  return [
    parseInt(clean.slice(0, 2), 16),
    parseInt(clean.slice(2, 4), 16),
    parseInt(clean.slice(4, 6), 16),
  ];
}
```

```javascript
// contrast.mjs lines 42-60 — 17-color brand palette
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

export { linearize, luminance, parseHex, contrast, PALETTE };
```

`parseHex` and `PALETTE` are both named exports. `parseHex` validates 6-digit hex only — **note it does NOT handle 3-digit or 8-digit hex.** The drift check regex `#[0-9a-fA-F]{3,8}` is intentionally broader to catch any hex color; `parseHex` can be imported for human-readable violation messages (name lookup in PALETTE) but the detection regex is independent.

### `compile-tokens.test.mjs` — key idioms

**Hex-outside-semantic-tier scan (lines 129-141) — the exact idiom to reuse:**

```javascript
// compile-tokens.test.mjs lines 129-141
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

The idiom uses `/#[0-9a-fA-F]{6}/` (exactly 6 digits). For the consumer drift check the regex should be `/#(?![0-9a-fA-F]{0,7}[^0-9a-fA-F])[0-9a-fA-F]{3,8}/` with a lookahead guard, OR the simpler approach: scan for `#[0-9a-fA-F]{3,8}` then exclude matches where the character after the hex digits is also a hex digit (to avoid partial matches), plus exclude the CSS `#id-selector` pattern (see Detection Regex section below).

**Primitive reference count (lines 122-127):**

```javascript
// compile-tokens.test.mjs lines 122-127
test('tokens.css contains >= 20 var(--cw-primitive-) references', () => {
  const content = readFileSync(TOKENS_CSS, 'utf8');
  const matches = content.match(/var\(--cw-primitive-/g) || [];
  assert.ok(matches.length >= 20,
    `semantic tier must reference primitive vars >=20 times; got ${matches.length}`);
});
```

**tokens.css byte-parity test (line 222-227):**

```javascript
// compile-tokens.test.mjs lines 222-227
test('priv/static/crosswake/tokens.css is byte-identical to brandbook/tokens/tokens.css', () => {
  execSync(`node ${COMPILE_SCRIPT}`, { cwd: ROOT });
  const brand = readFileSync(TOKENS_CSS, 'utf8');
  const priv  = readFileSync(PRIV_TOKENS_CSS, 'utf8');
  assert.strictEqual(brand, priv, 'both outputs must be byte-identical');
});
```

Live state confirmed: `diff brandbook/tokens/tokens.css priv/static/crosswake/tokens.css` → IDENTICAL. [VERIFIED: live grep]

---

## YAML Anchors — Exact Current State of `brandbook-verify.yml`

### `on.paths` (lines 20-25) — current state:

```yaml
on:
  pull_request:
    paths:
      - "brandbook/**"
  push:
    paths:
      - "brandbook/**"
```

D-01a adds four consumer globs to BOTH `pull_request.paths` and `push.paths`.

### `brand-structural` step list — complete current ordering (lines 33-82):

```yaml
jobs:
  brand-structural:
    name: brand-structural
    runs-on: ubuntu-latest
    timeout-minutes: 12

    steps:
      - name: Checkout                              # line 34
        uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6

      - name: Setup Node                            # line 38
        uses: actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020 # v4
        with:
          node-version: "22.x"

      - name: Install brandbook tool dependencies   # line 42
        working-directory: brandbook/tools
        run: npm ci

      - name: Size budget (committed brandbook <= 1MB)  # line 46
        run: |
          ...

      - name: SVG structural validation - production marks  # line 58
        working-directory: brandbook/tools
        run: node check-production.mjs

      - name: SVG structural validation - candidate marks   # line 63
        working-directory: brandbook/tools
        run: node check-candidates.mjs

      - name: Token JSON round-trip                 # line 66
        working-directory: brandbook/tools
        run: node --test compile-tokens.test.mjs

      - name: WCAG contrast matrix                  # line 70
        working-directory: brandbook/tools
        run: node --test contrast.test.mjs

      # ← NEW STEP GOES HERE (before Playwright install)

      - name: Install brand e2e dependencies        # line 74
        working-directory: brandbook/e2e
        run: npm ci

      - name: Install Playwright Chromium           # line 78
        working-directory: brandbook/e2e
        run: npx playwright install --with-deps chromium

      - name: Structural brand checks (DOM, dimensions, source assertions)  # line 82
        working-directory: brandbook/e2e
        run: npm run test:structural
```

**Insertion point:** After the `WCAG contrast matrix` step (line 70), before `Install brand e2e dependencies` (line 74). This is the correct "before Playwright install" position per D-01.

### `brand-visual` job — advisory structure (lines 84-119):

```yaml
  brand-visual:
    name: brand-visual
    runs-on: ubuntu-latest
    timeout-minutes: 12
    # ADVISORY: failures here never gate a merge.
    continue-on-error: true
```

Do not touch `brand-visual`. The `continue-on-error: true` makes it advisory-only. The header comment (lines 1-15) documents the required-vs-advisory contract and the branch-protection integration point.

### Workflow header comment (lines 1-15) — documents the integration point:

```yaml
# HYBRID GATE (promoted from advisory at v9.0 — see .planning/REQUIREMENTS.md):
#   • brand-structural — REQUIRED merge gate. Deterministic file / DOM / dimension /
#     token assertions with negligible flake risk. Add this job's check context to
#     branch-protection required-status-checks.
#   • brand-visual — ADVISORY (continue-on-error). Headless render + pixel-sample
#     checks; non-deterministic enough (fonts, network) to stay informational only.
#     Must NOT be added to required-status-checks.
```

---

## Detection Regex Architecture

### Hex detection (D-03 Rule 1)

**Goal:** flag `#` followed by 3-8 hex digits as a color literal; do NOT flag CSS `#id` selectors.

A CSS `#id` selector is `#identifier` where the identifier starts at a word-character (`[a-zA-Z_-]` or digit, but by convention never all-hex-letter). The current consumer files have no all-hex-letter IDs (confirmed in CONTEXT). The simplest robust guard:

```javascript
// Matches hex color literals; excludes #id selectors.
// An #id selector is never preceded by whitespace and is followed by
// a non-hex character (space, {, :, ., [, etc.) at the START of a token.
// Strategy: match #[hex]{3,8} then check surrounding context.
const HEX_COLOR_RE = /#([0-9a-fA-F]{3}(?:[0-9a-fA-F]{3}(?:[0-9a-fA-F]{2})?)?)\b/g;
// \b word-boundary after the hex digits prevents partial-match into longer hex strings.
// Disambiguate #id vs #color: if the FULL token before the # is end-of-value context
// (after ':', 'var(', '(', ',', ' ') it is a color; if after a selector combinator it is an ID.
// Simplest conservative approach for these flat files: flag all #hex matches,
// then exclude lines where the match sits inside a CSS selector context:
// i.e., the match is NOT preceded by ':', '(', ',', or whitespace.
```

**Recommended implementation — line-by-line with context check:**

```javascript
function findHexColors(content) {
  const violations = [];
  const lines = content.split('\n');
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const hexRe = /#([0-9a-fA-F]{3,8})\b/g;
    let m;
    while ((m = hexRe.exec(line)) !== null) {
      // Skip if length not 3, 6, or 8 (valid CSS hex lengths)
      const hexLen = m[1].length;
      if (hexLen !== 3 && hexLen !== 6 && hexLen !== 8) continue;
      // Skip CSS #id selectors: the # is preceded by whitespace or start-of-line,
      // and the character after the hex sequence is a space, '{', ':', '.', '[', ',' or ')'
      const before = line.slice(0, m.index);
      const after = line.slice(m.index + m[0].length);
      const isIdSelector = /[\s,>~+]$/.test(before) || before.trim() === '' || before.trimEnd().endsWith(',');
      // If the match is preceded by ':', '(', or ' ' inside a value context it IS a color
      const isValueContext = /:[\s]*$/.test(before) || /[,(][\s]*$/.test(before);
      if (isIdSelector && !isValueContext) continue;
      violations.push({ line: i + 1, match: m[0] });
    }
  }
  return violations;
}
```

**Simpler alternative** (sufficient for these files because current files are zero-hex):

```javascript
// Any #[3/6/8-digit hex] that is preceded by ':', space, '(', or ','.
// This misses only the edge case of a hex at true line-start (never in these files).
const HEX_RE = /(?<=[:,(\s])#([0-9a-fA-F]{6}|[0-9a-fA-F]{3}|[0-9a-fA-F]{8})\b/g;
```

The lookahead-behind approach is cleaner and recommended.

### Primitive token detection (D-03 Rule 2)

```javascript
const PRIMITIVE_RE = /var\(--cw-primitive-/;
```

Simple substring match — no false-positive risk.

### Semantic var presence (D-03 Rule 3 — CSS files only)

```javascript
const SEMANTIC_VAR_RE = /var\(--cw-/;
const hasSemanticVar = SEMANTIC_VAR_RE.test(content);
```

### Retired Tailwind blocklist (D-03 Rule 4 — HEEX/template files)

Derived from the NORM-04 test contract (`crosswake.gen.offline_ui_test.exs`, lines 120-127):

```elixir
refute combined =~ "flex", "Should not contain 'flex' Tailwind class"
refute combined =~ "bg-white", "Should not contain 'bg-white' Tailwind class"
refute combined =~ "bg-cw-foam-50", "Should not contain primitive Tailwind color"
refute combined =~ "text-cw-current-950", "Should not contain primitive Tailwind color"
refute combined =~ "min-h-screen", "Should not contain Tailwind layout class"
refute combined =~ ~r/border-cw-/, "Should not contain Tailwind border-cw- classes"
refute combined =~ "border-gray-", "Should not contain Tailwind system gray borders"
refute combined =~ "--cw-primitive-", "Should not reference primitive tier tokens"
```

The JavaScript equivalent blocklist for the drift gate (these are the class names to search for in class attribute values — NOT in CSS property values):

```javascript
const RETIRED_TAILWIND = [
  'flex',         // layout utility
  'bg-white',     // color utility
  'bg-cw-',       // primitive Tailwind color prefix (matches bg-cw-foam-50 etc.)
  'text-cw-',     // primitive Tailwind color prefix
  'min-h-screen', // layout utility
  'border-cw-',   // primitive Tailwind border prefix
  'border-gray-', // Tailwind system gray border
  'space-y-',     // spacing utility
  'max-w-md',     // sizing utility
];
```

**CRITICAL — `flex` must be scoped to class attributes, not CSS text.** The `index.html.heex` file contains `display: flex` in an inline `<style>` block. A naive `content.includes('flex')` would false-positive on this valid CSS. The gate must either:
1. Scan only class attribute values: `class="..."` content; OR
2. Exclude matches inside `<style>...</style>` blocks; OR
3. Use a word-boundary regex that targets `flex` as a standalone token preceded by whitespace or `"`: `/(?:^|\s)"[^"]*\bflex\b[^"]*"/`

**Recommended:** Extract class attribute values explicitly:

```javascript
function findRetiredTailwindInClassAttrs(content) {
  const violations = [];
  // Extract all class="..." values
  const classRe = /class="([^"]*)"/g;
  let m;
  while ((m = classRe.exec(content)) !== null) {
    const classes = m[1];
    for (const retired of RETIRED_TAILWIND) {
      if (classes.includes(retired)) {
        violations.push(`class="${classes}" contains retired Tailwind token: "${retired}"`);
      }
    }
  }
  return violations;
}
```

**Known safe class in templates:** `[scrollbar-gutter:stable]` in `offline_root.html.heex.eex` — this is an arbitrary-value Tailwind utility for a layout primitive with no token equivalent. It does NOT appear in the retired blocklist and must NOT be flagged. It will not match any of the RETIRED_TAILWIND entries above.

---

## Manifest — File Classification

```javascript
// Proposed manifest structure for check-consumer-drift.mjs
const MANIFEST = [
  {
    path: 'examples/phoenix_host/priv/static/css/app.css',
    type: 'css',
    // Rules: hex forbidden, primitive forbidden, ≥1 var(--cw-) required
  },
  {
    path: 'priv/static/crosswake/offline.css',
    type: 'css',
    // Rules: hex forbidden, primitive forbidden, ≥1 var(--cw-) required
  },
  {
    path: 'priv/templates/crosswake/offline_ui/offline_page.html.heex.eex',
    type: 'heex',
    // Rules: hex forbidden, primitive forbidden, retired Tailwind class attrs forbidden
    // (no var(--cw-) required — tokens consumed via linked offline.css)
  },
  {
    path: 'priv/templates/crosswake/offline_ui/offline_root.html.heex.eex',
    type: 'heex',
    // Rules: hex forbidden, primitive forbidden, retired Tailwind class attrs forbidden
    // Note: [scrollbar-gutter:stable] is intentional — not in the retired list
  },
  {
    path: 'examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex',
    type: 'heex',
    // Rules: hex forbidden, primitive forbidden, retired Tailwind class attrs forbidden
    // Note: file has display:flex in inline <style> — not a class attr; not flagged
  },
];

// Excluded (deferred offenders — do not add to manifest):
// examples/phoenix_host/priv/static/offline_study.js
//   — contains #9A4D35 / #fee2e2 / #ef4444 (innerHTML hardcoded hex)
// examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_challenge_live.ex
//   — contains bg-[#F8FAFC] and bg-[#2563EB] (dead Tailwind utilities)
//   NOTE: CONTEXT.md has wrong path for this file; correct path verified above.
```

**tokens.css is NOT in the manifest** (D-04: parity already handled by `compile-tokens.test.mjs:222`).

---

## Script Form Recommendation

**Recommended: plain Node script (`check-consumer-drift.mjs`) following the `check-production.mjs` convention.**

Rationale:
- `check-production.mjs` and `check-candidates.mjs` are the established pattern for non-test structural checks in this job
- Plain `node brandbook/tools/check-consumer-drift.mjs` is the one-command local runner (success criterion #4)
- Exit 0 / exit 1 maps cleanly to pass/fail with per-violation `::error` annotations
- The `node --test` form (`compile-tokens.test.mjs` convention) is better for unit-level assertions with describe/test structure — the consumer drift check is a single scan loop, not a test suite

**Invoke from working-directory `brandbook/tools/` or from repo root:**

Current YAML convention for Node tools:
```yaml
- name: SVG structural validation - production marks
  working-directory: brandbook/tools
  run: node check-production.mjs
```

The drift check can follow the same pattern OR be invoked from repo root using `node brandbook/tools/check-consumer-drift.mjs`. The manifest paths must be relative to repo root (the script resolves them against `ROOT = resolve(__dirname, '../..')`), matching the `compile-tokens.test.mjs` ROOT derivation pattern.

**One-command local runner (success criterion #4):**
```bash
node brandbook/tools/check-consumer-drift.mjs
```

Produces identical output on Linux CI (ubuntu-latest, Node 22.x) and macOS because:
- Pure Node.js built-ins only (`fs`, `path`)
- No binary, no native addon, no Playwright
- File paths resolved via `import.meta.url` / `resolve()` — OS-agnostic

---

## Contract/Pin Test

A companion `node --test brandbook/tools/check-consumer-drift.test.mjs` (or inline in `compile-tokens.test.mjs` as additional tests) should assert:

1. **Manifest completeness:** all 5 manifest paths exist on disk
2. **Per-file rules on current clean tree:** running the check exits 0 (green baseline)
3. **Synthetic hex injection:** inject a `#2B756A` line into a copy of `app.css` → exits non-zero
4. **Synthetic primitive injection:** inject `var(--cw-primitive-foam-50)` into a copy → exits non-zero
5. **Synthetic var removal:** create a CSS file with zero `var(--cw-` → exits non-zero
6. **`#id`-selector false-positive guard:** `#status { color: var(--cw-text-muted); }` → exits 0
7. **`rgba()` shadow guard:** `box-shadow: 0 4px 6px rgba(9,20,26,0.06)` → exits 0
8. **`display:flex` in `<style>` block NOT flagged as Tailwind:** → exits 0

The contract test mirrors the NORM-04 generator-test pattern (test file alongside the tool, `node --test` invocation in the YAML).

---

## Common Pitfalls

### Pitfall 1: Scoping `flex` too broadly

**What goes wrong:** `content.includes('flex')` flags `display: flex` in `index.html.heex`'s inline `<style>` block — false positive, gate fails on a clean tree.
**Why it happens:** The NORM-04 test runs on generator OUTPUT (pure HEEX markup, no inline `<style>`), but `index.html.heex` is the example host's page with an inline stylesheet.
**How to avoid:** Scope Tailwind checks to class attribute values only (see regex in Detection Regex section).
**Warning signs:** Gate fails immediately on `index.html.heex`; the violation message names `display: flex` not `class="flex"`.

### Pitfall 2: Wrong path for deferred offender in manifest comment

**What goes wrong:** Using the CONTEXT.md path `crosswake_example_web/live/saas_portal/step_up_challenge_live.ex` — this file does not exist.
**How to avoid:** Use verified correct path: `crosswake_example/saas_portal/step_up_challenge_live.ex`.

### Pitfall 3: `parseHex()` only handles 6-digit hex

**What goes wrong:** Reusing `parseHex()` from `contrast.mjs` for detection — it throws on 3-digit or 8-digit hex (`/^[0-9a-fA-F]{6}$/.test(clean)` fails).
**How to avoid:** Use a separate detection regex for scanning; use `parseHex()` only for PALETTE name-lookup in violation messages (after confirming the match is 6 digits).

### Pitfall 4: Manifest path relative to `brandbook/tools/` cwd

**What goes wrong:** If the step uses `working-directory: brandbook/tools`, manifest paths like `examples/phoenix_host/priv/static/css/app.css` resolve against `brandbook/tools/` and fail with ENOENT.
**How to avoid:** Derive ROOT as `resolve(dirname(fileURLToPath(import.meta.url)), '../..')` — same pattern as `compile-tokens.test.mjs` line 13. Manifest paths are then relative to repo root.

### Pitfall 5: Missing `npm ci` dependency for the new script

**What goes wrong:** The new script imports from `contrast.mjs` which has no npm dependencies, but if the step runs before `Install brandbook tool dependencies`, `node_modules` may be absent.
**How to avoid:** Keep new step after the `npm ci` step (line 42). Current ordering already places all tool steps after `npm ci`. New step goes after `WCAG contrast matrix` (line 70) — `npm ci` is at line 42, so this is safe.

### Pitfall 6: `tokens.css` not in manifest accidentally triggers duplicate parity check

**What goes wrong:** Including `priv/static/crosswake/tokens.css` in the manifest adds a redundant "≥1 `var(--cw-`" check. Not a correctness issue, but creates maintenance confusion.
**How to avoid:** Explicitly exclude `tokens.css` from manifest per D-04. Comment in manifest explains D-04 coverage.

---

## Zero-Hex Baseline — Live Verification Summary

| File | Type | `var(--cw-` refs | Hex literals | Primitive refs | Retired Tailwind class attrs |
|------|------|-----------------|--------------|----------------|------------------------------|
| `examples/phoenix_host/priv/static/css/app.css` | CSS | 47 occurrences | 0 | 0 | N/A |
| `priv/static/crosswake/offline.css` | CSS | 39 occurrences | 0 | 0 | N/A |
| `priv/templates/crosswake/offline_ui/offline_page.html.heex.eex` | HEEX | 0 (expected — tokens via CSS) | 0 | 0 | 0 |
| `priv/templates/crosswake/offline_ui/offline_root.html.heex.eex` | HEEX | 0 (expected) | 0 | 0 | 0 (has `[scrollbar-gutter:stable]` — intentional, not in blocklist) |
| `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex` | HEEX | 17 (in inline `<style>`) | 0 | 0 | 0 (has `display:flex` in `<style>` — NOT a class attr) |
| `priv/static/crosswake/tokens.css` | CSS | covered by D-04 | — | — | — |

**Gate lands green.** All `var(--cw-` rule checks pass on current tree. [VERIFIED: live grep]

---

## Deferred Offenders — Verified Still Contain Violations

| File | Violations | Correct Path |
|------|-----------|--------------|
| `examples/phoenix_host/priv/static/offline_study.js` | `#9A4D35`, `#fee2e2`, `#ef4444` (innerHTML) | (path correct in CONTEXT) |
| `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_challenge_live.ex` | `bg-[#F8FAFC]`, `bg-[#2563EB]` (dead Tailwind) | **PATH DIFFERS FROM CONTEXT** — see Gap 2 above |

Both confirmed still contain violations — excluding them from the manifest is correct and required. [VERIFIED: live grep]

---

## Standard Stack

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|-------------|
| Node.js | 22.x (pinned in workflow) | Runtime for drift check script | Already the workflow runtime |
| `node:fs` | built-in | Read consumer files | Zero-dependency pattern established in all `brandbook/tools/` scripts |
| `node:path` | built-in | Resolve manifest paths from ROOT | Same pattern as `compile-tokens.test.mjs:13` |

### No new npm dependencies

All detection logic uses built-in Node.js APIs and regex. `contrast.mjs` exports (`parseHex`, `PALETTE`) are imported as local ES modules — no npm install required.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `node:test` (built-in, Node 22.x) |
| Config file | None — invoked directly |
| Quick run command | `node brandbook/tools/check-consumer-drift.mjs` |
| Full suite command | `node --test brandbook/tools/check-consumer-drift.test.mjs` (if companion test file added) OR the existing `node --test brandbook/tools/compile-tokens.test.mjs` (if tests are appended there) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROOF-01 (SC #1) | Fails on hardcoded brand hex in consumer | Contract test — synthetic fixture | `node --test brandbook/tools/check-consumer-drift.test.mjs` | No — Wave 0 |
| PROOF-01 (SC #2) | Fails when CSS file loses all `var(--cw-` refs | Contract test — synthetic fixture | `node --test brandbook/tools/check-consumer-drift.test.mjs` | No — Wave 0 |
| PROOF-01 (SC #3) | Browser-free, OS-deterministic | Integration — run on macOS + CI assertion | CI run + local `node brandbook/tools/check-consumer-drift.mjs` | No — Wave 0 |
| PROOF-01 (SC #4) | Local == CI one-command runner | Manual + CI | `node brandbook/tools/check-consumer-drift.mjs` | No — Wave 0 |
| Manifest integrity | All 5 manifest paths exist | Contract test | `node --test brandbook/tools/check-consumer-drift.test.mjs` | No — Wave 0 |
| Green baseline | Gate exits 0 on current clean tree | Contract test | `node --test brandbook/tools/check-consumer-drift.test.mjs` | No — Wave 0 |
| #id-selector guard | `#status` CSS ID not flagged as hex | Contract test | `node --test brandbook/tools/check-consumer-drift.test.mjs` | No — Wave 0 |
| rgba shadow guard | `rgba(9,20,26,0.06)` not flagged | Contract test | `node --test brandbook/tools/check-consumer-drift.test.mjs` | No — Wave 0 |
| `display:flex` guard | CSS property value not flagged as Tailwind | Contract test | `node --test brandbook/tools/check-consumer-drift.test.mjs` | No — Wave 0 |

### Sampling Rate

- **Per task commit:** `node brandbook/tools/check-consumer-drift.mjs` (< 1 second)
- **Per wave merge:** `node --test brandbook/tools/check-consumer-drift.test.mjs`
- **Phase gate:** Full `brand-structural` workflow passes before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `brandbook/tools/check-consumer-drift.mjs` — the main drift check script (Wave 1 deliverable)
- [ ] `brandbook/tools/check-consumer-drift.test.mjs` — contract/pin test with synthetic fixtures (Wave 2 deliverable)
- [ ] YAML edit to `.github/workflows/brandbook-verify.yml` — new step + broadened `on.paths`

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js 22.x | drift check script | CI: pinned in workflow; Local: confirmed | 22.x | — |
| `node:fs`, `node:path`, `node:test` | built-in modules | CI+local: Node 22.x standard | 22.x built-in | — |
| `brandbook/tools/node_modules` | `contrast.mjs` import (if used) | Installed by `npm ci` step | — | — |

No missing dependencies. The script uses only Node built-ins plus sibling ES module imports from `brandbook/tools/`.

---

## Security Domain

> `security_enforcement` not explicitly set in config — treated as enabled.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | Yes | Regex guards on file content; no user-supplied input; `parseHex()` already validates hex format |
| V2 Authentication | No | CI tooling, no auth surface |
| V3 Session Management | No | Stateless script |
| V4 Access Control | No | Read-only file scan |
| V6 Cryptography | No | No crypto used |

No security concerns beyond ensuring the script reads only committed files (no network calls, no external services).

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `[scrollbar-gutter:stable]` in `offline_root.html.heex.eex` is intentional and not a brand-color drift | Gap 3, Manifest | Low — it is not in the 108-CONTEXT retired Tailwind blocklist and has no token equivalent; if it should be flagged, add it to RETIRED_TAILWIND |
| A2 | `index.html.heex` inline `<style>` block is a permanent feature of the file (not to be removed) | Gap 4 | Low — the file was normalized in Phase 108 to use `var(--cw-*)` inside the style block; the style block itself is the correct pattern for this host-page |

---

## Open Questions

1. **Should the companion contract test live as a new `check-consumer-drift.test.mjs` or as additional tests appended to `compile-tokens.test.mjs`?**
   - What we know: `compile-tokens.test.mjs` is already in the `node --test` step; both patterns are established in the project.
   - What's unclear: The CONTEXT allows discretion on exact script form.
   - Recommendation: New `check-consumer-drift.test.mjs` — keeps concerns separated and makes the drift check self-contained. The planner can override.

2. **Should `tokens.css` (the distributed copy) be in the manifest with a hex-only check, even though D-04 says "do not re-implement parity"?**
   - Recommendation: No. D-04 is locked. Adding it would create confusion about ownership.

---

## Sources

### Primary (HIGH confidence)
- Live filesystem grep — all consumer file counts and hex checks performed in this session [VERIFIED: live grep]
- `brandbook/tools/contrast.mjs` — read directly, lines 19-29 (parseHex) and 42-60 (PALETTE)
- `brandbook/tools/compile-tokens.test.mjs` — read directly, lines 122-127 (primitive count), 129-141 (hex scan idiom), 222-227 (byte-parity test)
- `brandbook/tools/check-production.mjs` — read directly (plain-script-exit-1 convention)
- `brandbook/tools/check-candidates.mjs` — read directly (export pattern, IS_MAIN guard)
- `.github/workflows/brandbook-verify.yml` — read in full; all line numbers verified
- `test/mix/tasks/crosswake.gen.offline_ui_test.exs` — read directly; NORM-04 Tailwind blocklist at lines 120-127
- `priv/templates/crosswake/offline_ui/offline_page.html.heex.eex` — read directly
- `priv/templates/crosswake/offline_ui/offline_root.html.heex.eex` — read directly
- `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex` — read directly

### Tertiary (LOW confidence — not needed, deferred offenders only)
- `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_challenge_live.ex` — path verified by find + grep

---

## Metadata

**Confidence breakdown:**
- Zero-hex baseline: HIGH — live grep across all manifest targets
- YAML anchors and step ordering: HIGH — read full workflow file
- Reusable code signatures: HIGH — read source files directly, quoted exact lines
- Deferred offender path correction: HIGH — find + grep confirmed
- Detection regex design: MEDIUM — based on known file contents + CSS/Tailwind idioms; synthetic fixture test in Wave 0 will confirm

**Research date:** 2026-06-14
**Valid until:** 30 days (stable, code not changing)
