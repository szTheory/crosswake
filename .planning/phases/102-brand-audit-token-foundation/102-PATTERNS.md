# Phase 102: Brand Audit & Token Foundation - Pattern Map

**Mapped:** 2026-06-11
**Files analyzed:** 6 (5 new + 1 modified)
**Analogs found:** 5 / 6

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `brandbook/AUDIT.md` | doc (structured audit) | batch/transform | `guides/threadline.md` + `.planning/milestones/v7.0-MILESTONE-AUDIT.md` | role-match |
| `brandbook/tokens/crosswake.tokens.json` | config (design token source) | transform | `priv/templates/crosswake/install_manifest.json.eex` | partial-match (structured JSON) |
| `brandbook/tokens/tokens.css` | config (generated CSS) | transform | `examples/phoenix_host/assets/css/app.css` | exact |
| `brandbook/tools/contrast.mjs` | utility (WCAG script) | batch | `priv/templates/crosswake/offline_ui/offline.js.eex` | partial-match (vanilla JS module style) |
| `brandbook/tools/compile-tokens.js` | utility (codegen script) | transform | `priv/templates/crosswake/offline_ui/offline.js.eex` | partial-match (vanilla JS module style) |
| `.gitignore` | config | — | `.gitignore` (self) | exact |

---

## Pattern Assignments

### `brandbook/AUDIT.md` (doc, batch/transform)

**Analogs:** `guides/threadline.md` (long-form structured guide); `.planning/milestones/v7.0-MILESTONE-AUDIT.md` (scored/annotated audit doc)

**Document structure pattern** (`guides/threadline.md` lines 1–20):
```markdown
# Threadline

## What Threadline Is

...

## What Threadline Is NOT

These are non-goals by design, not deferred features.

- **Not an APM / observability platform.**
- **Not a generic plugin / event bus.**
```

Key guide conventions to copy:
- Top-level `#` title, no frontmatter in prose guides
- `##` section headings; bold-inline term definitions: `**Term** — description`
- "What X Is NOT" / non-goals listed explicitly as bullet points with **bold lead**
- No hedging language; direct declarative sentences

**Audit/scored doc pattern** (`.planning/milestones/v7.0-MILESTONE-AUDIT.md` lines 1–55):
```yaml
---
milestone: v7.0
audited: 2026-06-10
status: tech_debt
scores:
  requirements: 19/19
  phases: 8/8
---
```

AUDIT.md does NOT use YAML frontmatter (it is not a machine-parsed planning artifact — it is a prose brand document). The milestone-audit frontmatter pattern applies to planning files only.

**Verdict format to apply throughout AUDIT.md:**
```markdown
**Verdict: KEEP** — [one-sentence rationale]

**Verdict: TIGHTEN** — [what sharper constraint is needed]

**Verdict: REWORK** — [what is wrong]; **Cost:** [what this forces downstream]

**Verdict: ADD** — [what is missing and why it matters]

**Verdict: REMOVE** — [what to cut and why]
```

The audit brief requires every REWORK to state a cost. Encode it inline as `**Cost:** ...` on the same verdict line.

**Section heading scaffold** (14 sections per `102-AUDIT-BRIEF.md` §"Required output structure"):
```markdown
# Crosswake Brand System Audit

**Audited:** 2026-06-11
**Subject:** `prompts/crosswake-brand-book.md`
**Auditor posture:** Senior brand systems director / design-token architect / OSS maintainer

---

## §1 Executive Judgment

## §2 Brand DNA Extraction

## §3 Pressure-Test Scorecard

## §4 Stress Tests

## §5 Gaps and Risks

## §6 Recommended Brand Book Upgrades

## §7 Design Token Specification

## §8 Logo and Mark System

## §9 Visual Examples and Screenshot Guidance

## §10 Brand Voice and Microcopy

## §11 Landing Page and Docs Blueprint

## §12 Repo-Ready Artifact Plan

## §13 Prioritized Action Plan

## §14 Final Quality Gate

---

## Appendix A: WCAG Contrast Matrix
```

Scaffold this structure first (Wave 0), then fill sequentially. The `---` horizontal rules between major sections match the guide pattern in `guides/threadline.md`.

---

### `brandbook/tokens/crosswake.tokens.json` (config, transform)

**Analog:** `priv/templates/crosswake/install_manifest.json.eex` (structured JSON config with versioned schema)

**JSON structure conventions from analog** (`install_manifest.json.eex` lines 1–9):
```json
{
  "schema_version": 1,
  "crosswake_version": "...",
  "files": [...],
  "markers": [...]
}
```

Key conventions observed: top-level keys are snake_case; structured objects grouped by domain; no trailing commas; flat where possible.

**DTCG 2025.10 structure to use** (from RESEARCH.md §Architecture Patterns):
```json
{
  "primitive": {
    "$type": "color",
    "current": {
      "950": {
        "$value": "#09141A",
        "$description": "Primary dark — logo ink, hero background"
      }
    },
    "stone": {
      "500": {
        "$value": "#7C746A",
        "$description": "Narrow use only: large text ≥24px, disabled states, decorative. Fails AA normal text on Foam 50 (4.09:1)."
      },
      "600": {
        "$value": "#756D63",
        "$description": "text.muted mapping. Passes AA on Foam 50 (4.53:1) and white (5.09:1)."
      }
    }
  },
  "surface": {
    "$type": "color",
    "default": {
      "$value": "{primitive.foam.50}",
      "$dark": "{primitive.current.950}",
      "$description": "Main light background"
    }
  }
}
```

Key DTCG conventions (locked in D-07):
- `$type` declared at group level, not per-token (reduces repetition)
- `$value` holds the light-mode value; `$dark` holds the dark-mode value (sibling property, consumed by compile-tokens.js)
- `{primitive.x.y}` alias syntax for semantic → primitive references
- `$description` encodes usage restrictions on any restricted primitive (D-03): e.g., `"Wake 500: light-surface text forbidden: 2.95:1 on Foam 50"`
- Top-level keys: `primitive`, `surface`, `text`, `action`, `border`, `status`, `runtime`, `font`, `text-scale`, `display-scale`, `spacing`, `radius`, `focus`

**Primitive token naming** (from `examples/phoenix_host/assets/css/app.css` lines 3–19 — the existing 16 variables are the ground truth):

The JSON primitive names must be compatible with the existing CSS variable names. The mapping is:

| Existing CSS var | JSON dot-path |
|-----------------|---------------|
| `--cw-current-950` | `primitive.current.950` |
| `--cw-wake-700` | `primitive.wake.700` |
| `--cw-brass-500` | `primitive.brass.500` |
| `--cw-foam-50` | `primitive.foam.50` |
| `--cw-stone-500` | `primitive.stone.500` |
| (new) `--cw-stone-600` | `primitive.stone.600` |

All 17 primitives follow this pattern. The compile script will emit `--cw-primitive-{family}-{stop}` (not `--cw-{family}-{stop}`) for the internal tier, preserving backward compatibility only at the semantic level.

---

### `brandbook/tokens/tokens.css` (config, transform — GENERATED)

**Analog:** `examples/phoenix_host/assets/css/app.css` (the only existing `--cw-*` CSS custom properties file)

**CSS custom property conventions** (`examples/phoenix_host/assets/css/app.css` lines 1–24):
```css
/* Crosswake Brand Book CSS */

:root {
  --cw-current-950: #09141A;
  --cw-current-900: #0F1E26;
  --cw-current-800: #162B35;
  --cw-harbor-700: #254855;
  --cw-wake-700: #2B756A;
  --cw-wake-500: #4E9A8E;
  --cw-kelp-800: #123B36;
  --cw-brass-500: #C98A2E;
  --cw-brass-700: #946017;
  --cw-foam-50: #F7F1E6;
  --cw-foam-100: #EFE6D6;
  --cw-mist-200: #C9D4CF;
  --cw-stone-500: #7C746A;
  --cw-rust-600: #9A4D35;
  --cw-plum-700: #372D4C;
  --cw-white: #FFFFFF;

  --cw-font-display: "Space Grotesk", ui-sans-serif, ...;
  --cw-font-body: "Atkinson Hyperlegible Next", ui-sans-serif, ...;
  --cw-font-mono: "JetBrains Mono", "SFMono-Regular", ...;
}
```

**Button / state patterns used in app.css** (lines 108–118):
```css
.btn-primary {
  background: var(--cw-wake-700);
  color: var(--cw-white);
}
.btn-primary:hover {
  background: var(--cw-current-950);
}
.btn-primary:focus {
  outline: 2px solid var(--cw-brass-500);
  outline-offset: 2px;
}
```

These become the **canonical state examples** for the `action.*` semantic tokens. The generated tokens.css must use `var(--cw-primitive-*)` references for semantic values, not hardcoded hex.

**Generated file header + structure to emit** (from RESEARCH.md §Research Finding 4):
```css
/* GENERATED from crosswake.tokens.json — do not edit */
/* Edit crosswake.tokens.json, then run: node brandbook/tools/compile-tokens.js */

/* ─── Primitive tier (internal — do not reference directly in component CSS) ─── */
:root {
  --cw-primitive-current-950: #09141A;
  /* ... all 17 primitives ... */
}

/* ─── Semantic tier (public contract) ─── */
:root {
  --cw-surface-default: var(--cw-primitive-foam-50);
  --cw-text-default: var(--cw-primitive-current-950);
  /* ... all 27 semantic tokens ... */
}

/* ─── Dark mode ─── */
@media (prefers-color-scheme: dark) {
  :root:not([data-theme]) {
    --cw-surface-default: var(--cw-primitive-current-950);
    --cw-text-default: var(--cw-primitive-foam-50);
    /* ... dark values ... */
  }
}

[data-theme="dark"] {
  --cw-surface-default: var(--cw-primitive-current-950);
  /* ... identical to @media block ... */
}

/* ─── Forbidden pairings (DO NOT USE) ─── */
/* stone-500 on foam-50: 4.09:1 — fails AA normal text */
/* wake-500 on foam-50: 2.95:1 — role issue; dark-surface only */
/* mist-200 on foam-50: 1.35:1 — border/dark-surface only */
```

Key conventions from analog:
- `--cw-` prefix on all variables (D-05)
- Section comment headers with `─── ... ───` ASCII borders
- Semantic tokens reference primitive vars, never inline hex values
- Dark mode: `@media (prefers-color-scheme: dark) { :root:not([data-theme]) }` + `[data-theme="dark"]` block (D-08)
- Font stack order matches app.css: quoted name → `ui-sans-serif` → `system-ui` → platform fallbacks → generic

---

### `brandbook/tools/contrast.mjs` (utility, batch)

**Analog:** `priv/templates/crosswake/offline_ui/offline.js.eex` (vanilla JS module with async functions, try/catch error handling, named exports)

**JS module conventions from analog** (`offline.js.eex` lines 1–43):
```javascript
// Comment block describing module purpose

async function checkStorageBudget() {
  if (navigator.storage && navigator.storage.estimate) {
    try {
      const estimate = await navigator.storage.estimate();
      // ...
    } catch (e) {
      console.error("Failed to estimate storage budget", e);
    }
  }
}

// Initialization
document.addEventListener("DOMContentLoaded", () => {
  // ...
});

export { insertRecord, checkStorageBudget };
```

Key JS conventions:
- Leading comment block: single-line `//` comments describing purpose
- `const` for values; `function` declarations for named utilities
- `try/catch` with `console.error` for error paths
- Named exports at bottom of file: `export { fn1, fn2 }`

**contrast.mjs structure to follow** (dependency-free Node ESM, per D-04):
```javascript
#!/usr/bin/env node
// brandbook/tools/contrast.mjs
// WCAG 2.2 contrast matrix for the Crosswake palette.
// Usage: node brandbook/tools/contrast.mjs
// Output: markdown table to stdout

// WCAG 2.2 linearization threshold: 0.04045 (corrected May 2021)
function linearize(c) {
  const s = c / 255;
  return s <= 0.04045 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
}

function luminance(r, g, b) {
  return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b);
}

function contrast(hex1, hex2) {
  // ... parse hex, compute luminances, return (L1+0.05)/(L2+0.05) with L1>=L2
}

// Palette constants (hardcoded — no JSON dep needed for Phase 102)
const PALETTE = {
  'current-950': '#09141A',
  'wake-700':    '#2B756A',
  // ...
};

// Approved pairings matrix
const PAIRS = [
  ['foam-50',    'current-950'],
  ['stone-500',  'foam-50'],     // expect FAIL
  ['stone-600',  'foam-50'],     // expect PASS
  // ...
];

// Main: print markdown table
const rows = PAIRS.map(([fg, bg]) => { /* ... */ });
console.log('| Foreground | Background | Ratio | AA | AAA |');
console.log('|-----------|-----------|-------|-----|-----|');
rows.forEach(r => console.log(r));
```

**Input validation (ASVS V5):** Validate hex string format before `parseInt`:
```javascript
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

File is ESM (`.mjs` extension). No `import` statements needed — palette hardcoded for Phase 102. Phase 103 can add JSON import via `fs.readFileSync`.

---

### `brandbook/tools/compile-tokens.js` (utility, transform)

**Analog:** `priv/templates/crosswake/offline_ui/offline.js.eex` (vanilla JS with sync file I/O patterns)

**JS module conventions:** Same as contrast.mjs above. compile-tokens.js is CJS or ESM (<80 LOC per D-07). CJS is simpler for sync `fs` usage:

```javascript
#!/usr/bin/env node
// brandbook/tools/compile-tokens.js
// Compiles brandbook/tokens/crosswake.tokens.json → brandbook/tokens/tokens.css
// Usage: node brandbook/tools/compile-tokens.js
// Zero npm dependencies.

const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const JSON_PATH = path.join(ROOT, 'tokens', 'crosswake.tokens.json');
const CSS_PATH  = path.join(ROOT, 'tokens', 'tokens.css');

const tokens = JSON.parse(fs.readFileSync(JSON_PATH, 'utf8'));
```

**Tree-walk alias resolution pattern** (from RESEARCH.md §Research Finding 4):
```javascript
// Build flat lookup: 'primitive.current.950' → { $value: '#09141A', ... }
function flattenTokens(obj, prefix = '') {
  const map = {};
  for (const [key, val] of Object.entries(obj)) {
    if (key.startsWith('$')) continue;
    const dotPath = prefix ? `${prefix}.${key}` : key;
    if (val.$value !== undefined) {
      map[dotPath] = val;
    } else {
      Object.assign(map, flattenTokens(val, dotPath));
    }
  }
  return map;
}

// Resolve '{primitive.foam.50}' → 'var(--cw-primitive-foam-50)'
function resolveAlias(value, flatMap) {
  return value.replace(/\{([^}]+)\}/g, (_, path) => {
    const cssVar = '--cw-' + path.replace(/\./g, '-');
    return `var(${cssVar})`;
  });
}
```

**Output pattern:**
```javascript
const lines = [];
lines.push('/* GENERATED from crosswake.tokens.json — do not edit */');
lines.push('/* Edit crosswake.tokens.json, then run: node brandbook/tools/compile-tokens.js */');
lines.push('');
// ... emit :root blocks, @media block, [data-theme] block ...
fs.writeFileSync(CSS_PATH, lines.join('\n'), 'utf8');
console.log(`Written: ${CSS_PATH}`);
```

`console.log` for success output; `process.exit(1)` + `console.error` for failures — matching the minimal CLI style of the offline.js template.

---

### `.gitignore` (config — modification)

**Analog:** `.gitignore` (self, lines 1–32)

**Existing pattern** (`.gitignore` lines 28–32):
```gitignore
# Local tooling / harness state (not part of the package)
/.claude/
/.gsd/
/.bg-shell/
```

Key conventions:
- `#` comment lines group related entries
- Absolute paths prefixed with `/` for repo-root-relative entries
- Comment precedes each group; no blank line between comment and first entry in a group
- Two additions required (RESEARCH.md §Finding 5):

```gitignore
# brandbook tooling (Node processing — not committed)
/brandbook/tools/node_modules/
/brandbook/tools/fonts/
```

Place this block at the end of `.gitignore`, after the existing `# Local tooling / harness state` block. Match the existing comment-then-entries style.

---

## Shared Patterns

### CSS Custom Property Naming
**Source:** `examples/phoenix_host/assets/css/app.css` lines 3–23
**Apply to:** `brandbook/tokens/tokens.css`

The existing 16 `--cw-*` variables establish the naming convention. The generated tokens.css extends this with a primitive tier prefix (`--cw-primitive-*`) and a semantic tier (`--cw-{role}-{variant}`). The existing CSS variable names in app.css (e.g., `--cw-wake-700`, `--cw-foam-50`) remain in place as-is; tokens.css adds a parallel structured layer. Downstream phases will migrate app.css to consume semantic tokens (NORM-01), but that is out of scope for Phase 102.

```css
/* Existing primitive-compat pattern (app.css) */
--cw-wake-700: #2B756A;

/* New primitive tier (tokens.css) */
--cw-primitive-wake-700: #2B756A;

/* New semantic tier (tokens.css) */
--cw-action-bg: var(--cw-primitive-wake-700);
```

### Vanilla JS Module Style
**Source:** `priv/templates/crosswake/offline_ui/offline.js.eex` lines 1–43
**Apply to:** `brandbook/tools/contrast.mjs`, `brandbook/tools/compile-tokens.js`

- Leading `//` comment block (no JSDoc unless the function is externally called)
- `const` for immutable values; no `var`
- Named function declarations (not arrow functions for top-level utilities)
- `try/catch` with `console.error` for I/O and computation errors
- Named exports OR no exports (CLI scripts that print to stdout need none)
- No semicolons are NOT used — the analog uses semicolons; follow semicolons style

### Structured Markdown Document Conventions
**Source:** `guides/threadline.md` lines 1–60
**Apply to:** `brandbook/AUDIT.md`

- `#` title, then short prose paragraph before first `##` section
- Sections use `##` headings; subsections use `###`
- Bold-inline term definitions: `**Term** — description prose`
- Code fences with language specifier: ` ```elixir `, ` ```css `, ` ```json `
- No trailing whitespace; blank line between paragraphs
- Horizontal rule (`---`) used to separate major document parts

### .gitignore Group Pattern
**Source:** `.gitignore` lines 28–32
**Apply to:** `.gitignore` (new block at end of file)

```gitignore
# [description of what the group excludes]
/[exact-repo-root-path]/
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `brandbook/tokens/crosswake.tokens.json` | config | transform | No DTCG token file exists anywhere in the repo. The closest structural analog is `install_manifest.json.eex` (flat versioned JSON) but it uses EEx templating, not DTCG hierarchy. DTCG structure must come from RESEARCH.md §Architecture Patterns. |

---

## Metadata

**Analog search scope:** `examples/phoenix_host/assets/css/`, `guides/`, `priv/templates/crosswake/offline_ui/`, `.gitignore`, `.planning/milestones/`, `examples/phoenix_host/package.json`
**Files scanned:** 10 analog candidates; 5 strong matches selected (stopped at threshold)
**Pattern extraction date:** 2026-06-11

**Critical implementation constraints carried from analogs:**
1. `examples/phoenix_host/assets/css/app.css`: The 16 existing `--cw-*` variable names are the backward-compatibility contract. `--cw-primitive-*` names must map from these exactly.
2. `guides/threadline.md`: AUDIT.md prose must be declarative, no hedging. Bold-inline verdict pattern enforced throughout.
3. `.gitignore`: Two lines only, placed at end of file, matching `# comment` + `/path/` style.
4. `offline.js.eex`: JS scripts use `const`, named function declarations, `try/catch`, semicolons — no class syntax, no TypeScript, no bundler assumptions.
5. DTCG JSON has no existing repo analog — use RESEARCH.md §Architecture Patterns verbatim.
