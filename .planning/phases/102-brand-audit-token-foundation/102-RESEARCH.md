# Phase 102: Brand Audit & Token Foundation - Research

**Researched:** 2026-06-11
**Domain:** Brand system audit, WCAG contrast scripting, W3C DTCG design tokens
**Confidence:** HIGH — all key facts verified against CONTEXT.md locked decisions and prior milestone research; no re-research of already-verified stack items

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Palette remediation (D-01..D-04)**
- D-01: Computed WCAG matrix is ground truth. Stone 500 `#7C746A` on Foam 50 = 4.09:1 is the ONLY true text-pair hex failure. Brass 700 (4.74:1) and Wake 700 (4.85:1) on Foam 50 PASS. All dark-surface pairs pass (5.6–16.6:1). Wake 500 on Foam 50 (2.95:1) and Mist 200 on Foam 50 (1.35:1) are role-definition issues, not hex problems.
- D-02: Add Stone 600 `#756D63` as a new primitive (4.53:1 on Foam 50, 5.09:1 on white). `text.muted` maps to Stone 600. Stone 500 narrowed to `text.subtle` (large text ≥24px, disabled, decorative). No other hex changes.
- D-03: Usage restrictions encoded in DTCG `$description` fields (e.g., Wake 500: "light-surface text forbidden: 2.95:1 on Foam 50"; Mist 200: "border and dark-surface text only").
- D-04: Full before/after matrix committed as AUDIT.md appendix; contrast script at `brandbook/tools/contrast.mjs`, dependency-free Node, WCAG relative-luminance, 0.04045 threshold.

**Token naming & structure (D-05..D-09)**
- D-05: Keep `--cw-` prefix. Two tiers only: primitive (`--cw-primitive-*`, internal) → semantic (`--cw-{role}-{variant}`, public contract). No component tier.
- D-06: ~23–28 semantic tokens (hard cap ~30): `surface` (default/raised/inset/inverse) · `text` (default/muted/subtle/inverse/code) · `action` (bg/fg/bg-dark/fg-dark/hover/focus-ring) · `border` (default/subtle/strong) · `status` (success/warning/error/info) · `runtime` (liveview/offline/native/sensitive/bridge).
- D-07: DTCG 2025.10 JSON is source of truth. `brandbook/tools/compile-tokens.js` (<80 LOC, zero npm deps) generates `tokens.css`, committed with a `/* GENERATED from crosswake.tokens.json — do not edit */` header.
- D-08: Single `:root` (light), `@media (prefers-color-scheme: dark) { :root:not([data-theme]) }` for system dark, `[data-theme="dark"]` for explicit toggle. Only semantic tier flips; primitives never change.
- D-09: State handling: hover/focus as semantic tokens (`action.hover`, `action.focus-ring`); active via CSS selectors; disabled via `opacity: 0.45` + label; success/warning/error/info via `status.*`; subtle/muted via `text.*`/`border.*` variants; selected documented as a pattern.

**Audit boldness / latitude policy (D-10..D-12)**
- D-10: Typography verdict: KEEP Space Grotesk (+ Atkinson Hyperlegible Next body, JetBrains Mono code). Font question CLOSES at 102 ratification.
- D-11: TIGHTEN rider (mandatory, cascades to Phase 103): custom `w`/`k` wake-angle cuts on wordmark are NON-OPTIONAL.
- D-12: Frozen (never change at ratification): display font family, coastal-muted palette character, wake-seam visual concept, diagonal crossing-mark direction. Audit acts unilaterally: math-forced hex additions/shifts, semantic role assignments, approved-pairings table, token naming/structure, type scale numbers, tracking, fallback stacks, gap-fill ADDs. Requires AUDT-04 ratification: typography section, logo direction, palette REWORK that shifts emotional character, Phase 103 letter-cut brief.

### Claude's Discretion
- AUDIT.md prose quality, section-by-section verdict calls within the latitude policy, exact wording of ready-to-use copy blocks (§10 of the brief), contrast script output format, DTCG file organization details, whether Stone 600 placement warrants additional approved-pairing rows.
- Typography/spacing/radius/shadow/focus-ring token values: derive from brand book §9/§13 (type scale, 4px grid, 12–16px card radius); keep bounded.

### Deferred Ideas (OUT OF SCOPE)
- NORM-01: Normalize generator templates + example app CSS onto `brandbook/tokens/tokens.css`. Phase 102 only flags the drift (AUDT-03).
- Multi-library suite brand rollout: audit may note suite implications, no suite assets this milestone.
- Landing page build: blueprint lives in AUDIT.md §11; building is a future milestone.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AUDT-01 | Maintainer can read a full 14-section pressure-test audit of `prompts/crosswake-brand-book.md` in `brandbook/AUDIT.md`, with KEEP/TIGHTEN/REWORK/ADD/REMOVE verdicts and a stated cost on every REWORK | Brand book §1–§25 mapped to audit brief §1–§14 below; all inputs identified |
| AUDT-02 | Scripted WCAG contrast matrix classifies every brand color pairing against AA text (4.5:1) and non-text UI (3:1) thresholds | `contrast.mjs` design confirmed; full pairing list enumerated; verified results from live computation |
| AUDT-03 | Audit explicitly flags the v8.0 surface drift (generator-template blue/amber Tailwind scale vs app.css teal/brass palette) with a verdict | Drift evidence pinned to exact file/line numbers — see Drift Evidence section |
| AUDT-04 | User ratifies any audit-driven font/color changes before downstream phases consume them | Checkpoint structure defined; ratification summary content enumerated |
| TOKN-01 | `brandbook/tokens/crosswake.tokens.json` in W3C DTCG 2025.10 format with primitive → semantic tiers including runtime-semantic tokens | Full token inventory enumerated; 17 primitives + 26–28 semantic + state coverage mapped |
| TOKN-02 | `brandbook/tokens/tokens.css` custom properties align with the JSON, contrast-annotated per pairing | `compile-tokens.js` design confirmed; alias resolution approach documented |
| TOKN-03 | State tokens cover default/hover/active/focus/disabled/selected/success/warning/error/info/subtle/muted (12 states) | All 12 states mapped to D-09 strategy; explicit grep verification command defined |
</phase_requirements>

---

## Summary

Phase 102 is a bounded, high-information-density writing-and-scripting phase. It produces three artifacts: `brandbook/AUDIT.md` (14 sections), `brandbook/tools/contrast.mjs` (WCAG script), and `brandbook/tokens/crosswake.tokens.json` + `brandbook/tokens/tokens.css` (generated). All palette decisions are pre-locked by D-01..D-04, so the audit's color math cannot surprise downstream phases. The main execution risk is audit prose quality — the AUDIT-BRIEF demands decisive verdicts, not hedge-everything commentary.

The brand book seed (25 sections) maps cleanly onto the 14 audit output sections. No section of the brand book is orphaned. The token inventory is fully enumerable: 17 primitives (16 original + Stone 600), 26–28 semantic tokens across 6 categories, and 12 state coverage patterns. The compile-tokens.js alias resolution follows a straightforward tree-walk pattern over the DTCG JSON, replacing `{primitive.x.y}` references with CSS variable names.

The drift evidence for AUDT-03 is precise and damning: the generator task (`crosswake.gen.offline_ui.ex` lines 67–90) hard-emits a Tailwind config snippet with a `cw-wake` 9-stop **blue** scale (e.g., `500: '#699cc9'`) and `cw-brass` 9-stop **amber** scale (e.g., `500: '#e1b982'`), while `app.css` defines `--cw-wake-700: #2B756A` (teal) and `--cw-brass-500: #C98A2E` (warm gold). These are entirely different color families used under the same naming prefix. The audit flags this; the fix is NORM-01 in a future milestone.

**Primary recommendation:** Execute in two work units: (1) write `brandbook/AUDIT.md` and `brandbook/tools/contrast.mjs`, (2) write tokens. Gate AUDT-04 ratification between phase end and any Phase 103 work starting.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Audit prose authoring | Manual/AI writing | — | No automated tier; requires domain judgment per verdict |
| WCAG contrast computation | `brandbook/tools/contrast.mjs` (Node script) | — | Pure math; no framework; runs against JSON palette |
| Token source of truth | `brandbook/tokens/crosswake.tokens.json` | — | DTCG format; human-editable |
| CSS generation | `brandbook/tools/compile-tokens.js` (Node script) | — | Reads JSON, writes CSS; committed output |
| Light/dark theming | CSS layer (`tokens.css`) | — | `:root` + `@media prefers-color-scheme` + `[data-theme]` |
| Drift flag (AUDT-03) | AUDIT.md prose | — | No code fix this phase; flag only |
| Ratification gate (AUDT-04) | User checkpoint | — | Human decision; structured summary as input |
| .gitignore additions | Repo config | — | Two lines; lands in this phase's setup task |

---

## Research Finding 1: Brand Book Section → Audit Section Mapping

The brand book has 25 sections. The audit brief specifies 14 output sections. Every brand book section feeds one or more audit sections. This mapping lets the planner break audit writing into bounded tasks.

[VERIFIED: direct read of both files]

### Brand Book §1–§25 → Audit Brief §1–§14 Feed Map

| Audit §  | Audit Section Title | Brand Book Input Sections |
|----------|---------------------|--------------------------|
| §1 | Executive judgment | §1 (brand summary), §2 (essence), §23 (do/don't), §25 (checklist) |
| §2 | Brand DNA extraction | §2 (essence, pillars), §7 (visual identity overview), §24 (LLM context block) |
| §3 | Pressure-test scorecard | All 25 sections (15 sub-scores; cite specific sections per criterion) |
| §4 | Stress tests | §10 (logo), §13 (layout/UI), §16 (landing page), §19 (UI components), §21 (accessibility) |
| §5 | Gaps and risks | §11 (graphic design elements), §12 (iconography), §17 (imagery), §25 (checklist) — missing items |
| §6 | Recommended brand book upgrades | Sections receiving TIGHTEN/REWORK/ADD verdicts from §3 |
| §7 | Design token specification | §8 (color system + CSS variables), §9 (typography + type scale), §13 (layout/radius/shadows/buttons) |
| §8 | Logo and mark system | §10 (logo direction) |
| §9 | Visual examples and screenshot guidance | §11 (motifs), §13 (components), §19 (UI examples) |
| §10 | Brand voice and microcopy | §5 (taglines/messaging), §6 (voice/tone), §15 (microcopy library) |
| §11 | Landing page and docs blueprint | §14 (documentation brand system), §16 (landing page direction) |
| §12 | Repo-ready artifact plan | §25 (first implementation checklist) — artifact list only |
| §13 | Prioritized action plan | Synthesizes verdicts from §3; Do now / Do next / Defer / Do not do |
| §14 | Final quality gate | §21 (accessibility standards), §23 (do/don't summary), §25 (implementation checklist) |

**Key note on §4 stress tests:** The audit brief lists ~25 surface types (GitHub repo header, README hero, HexDocs page, favicon, dark-mode page, etc.). The brand book addresses only ~10 of these directly. The audit must explicitly state what is missing for each untreated surface — those gaps become the §5 material.

**Key note on §7 (token specification):** This section in the audit is where the locked token spec (D-05..D-09) is documented. The audit does not invent tokens — it transcribes the locked decisions into AUDIT.md §7, which then serves as the written specification that compile-tokens.js implements.

---

## Research Finding 2: AUDT-03 Drift Evidence (Exact File/Line Citations)

[VERIFIED: direct file inspection]

### The Drift

**Surface A — `examples/phoenix_host/assets/css/app.css`** (16 CSS custom properties)
Correct teal/brass palette matching the brand book:
- `--cw-wake-700: #2B756A` — teal green
- `--cw-brass-500: #C98A2E` — warm gold
- All 16 variables match `prompts/crosswake-brand-book.md §8` exactly

**Surface B — `lib/mix/tasks/crosswake.gen.offline_ui.ex`, lines 67–90**
The generator task's instructions to users define a Tailwind config snippet:
```
'cw-wake': {
  500: '#699cc9',   // BLUE — not teal (#4E9A8E in brand book)
  700: '#3c6d99',   // BLUE
  ...
}
'cw-brass': {
  500: '#e1b982',   // AMBER — not warm gold (#C98A2E in brand book)
  700: '#c59a5e',   // AMBER
  ...
}
```

**Surface C — `priv/templates/crosswake/offline_ui/offline_page.html.heex.eex`**
Uses brand-book-aligned Tailwind classes:
- `border-cw-wake-700` — references wake-700 slot (correct name, wrong color if the emitted tailwind.config is used)
- `border-cw-brass-500` / `text-cw-brass-500` — same structural mismatch

**Surface D — `priv/templates/crosswake/offline_ui/offline_root.html.heex.eex`**
Uses `bg-cw-foam-50 text-cw-current-950` — correctly referencing brand-aligned slots

### Audit Verdict for AUDT-03
The audit must include a dedicated finding:
- **What:** Generator emits Tailwind config defining `cw-wake` as a blue family (#699cc9) and `cw-brass` as an amber family (#e1b982). The brand book and `app.css` define `cw-wake` as teal (#2B756A) and `cw-brass` as warm gold (#C98A2E).
- **Impact:** Any host app that runs `mix crosswake.gen.offline_ui` and uses the emitted Tailwind snippet will render the offline UI in blue/amber rather than the canonical teal/brass palette.
- **Verdict:** TIGHTEN (the naming convention is correct; the colors in the generator snippet are wrong). Fix is NORM-01 in a future milestone — do not fix in phase 102.
- **Cited lines:** `crosswake.gen.offline_ui.ex:67-90` (the Tailwind config snippet in the `@impl Mix.Task` `run/1` function's info output).

---

## Research Finding 3: Full Token Inventory for TOKN-01

[VERIFIED: derived from CONTEXT.md D-05..D-09 + brand book §8/§9/§13 + direct file inspection]

### Tier 1: Primitive Tokens (17 total)

All 16 original primitives from `app.css` + Stone 600 added per D-02:

| CSS Var Name (internal) | Hex | Notes |
|------------------------|-----|-------|
| `--cw-primitive-current-950` | `#09141A` | Primary dark |
| `--cw-primitive-current-900` | `#0F1E26` | Dark panels |
| `--cw-primitive-current-800` | `#162B35` | Raised dark surfaces |
| `--cw-primitive-harbor-700` | `#254855` | Secondary dark accent |
| `--cw-primitive-wake-700` | `#2B756A` | Primary action on light |
| `--cw-primitive-wake-500` | `#4E9A8E` | Accent on dark |
| `--cw-primitive-kelp-800` | `#123B36` | Offline/success deep |
| `--cw-primitive-brass-500` | `#C98A2E` | Signal accent |
| `--cw-primitive-brass-700` | `#946017` | Warning text on light |
| `--cw-primitive-foam-50` | `#F7F1E6` | Main light background |
| `--cw-primitive-foam-100` | `#EFE6D6` | Warm panel surface |
| `--cw-primitive-mist-200` | `#C9D4CF` | Borders, dark-surface text |
| `--cw-primitive-stone-500` | `#7C746A` | Narrow use: large text, disabled, decorative |
| `--cw-primitive-stone-600` | `#756D63` | NEW (D-02): text.muted on light |
| `--cw-primitive-rust-600` | `#9A4D35` | Danger/sensitive |
| `--cw-primitive-plum-700` | `#372D4C` | Bridge/contract accent |
| `--cw-primitive-white` | `#FFFFFF` | Text on dark/action |

**Primitive naming in JSON:** `primitive.current.950`, `primitive.wake.700`, etc. (hierarchical DTCG groups with `$type: "color"` at group level). Stone 600 sits in a `primitive.stone` group alongside stone.500.

### Tier 2: Semantic Tokens (26–28 tokens)

Derived from D-06 bounded vocabulary + brand book §8 semantic mapping + §13 button/badge/layout specs:

**surface (4 tokens):**
| Token | Light value | Dark value | Brand book source |
|-------|-------------|------------|-------------------|
| `--cw-surface-default` | foam-50 | current-950 | §8: main light bg / hero bg |
| `--cw-surface-raised` | foam-100 | current-900 | §8: warm panel; §13: code block bg |
| `--cw-surface-inset` | white | current-800 | §13: card inset |
| `--cw-surface-inverse` | current-950 | foam-50 | §8: hero / dark panels |

**text (5 tokens):**
| Token | Light value | Dark value | Brand book source |
|-------|-------------|------------|-------------------|
| `--cw-text-default` | current-950 | foam-50 | §8: body text |
| `--cw-text-muted` | stone-600 | mist-200 | D-02: replaces stone-500 for normal-size text |
| `--cw-text-subtle` | stone-500 | mist-200 | D-02: large text ≥24px, disabled, decorative only |
| `--cw-text-inverse` | foam-50 | current-950 | §8: text on dark |
| `--cw-text-code` | foam-50 | foam-50 | §13: code block text on Current-900 |

**action (6 tokens):**
| Token | Light value | Dark value | Brand book source |
|-------|-------------|------------|-------------------|
| `--cw-action-bg` | wake-700 | brass-500 | §13: primary button bg |
| `--cw-action-fg` | white | current-950 | §13: primary button text |
| `--cw-action-bg-dark` | brass-500 | wake-700 | §8: dark CTA bg |
| `--cw-action-fg-dark` | current-950 | white | §8: dark CTA text |
| `--cw-action-hover` | current-950 | foam-100 | §13: hover state |
| `--cw-action-focus-ring` | brass-500 | wake-500 | §13: 2px outline |

**border (3 tokens):**
| Token | Light value | Dark value | Brand book source |
|-------|-------------|------------|-------------------|
| `--cw-border-default` | mist-200 | harbor-700 | §13: card border |
| `--cw-border-subtle` | foam-100 | current-800 | §13: inset borders |
| `--cw-border-strong` | wake-700 | mist-200 | Selected state pattern |

**status (4 tokens):**
| Token | Value | Dark value | Brand book source |
|-------|-------|------------|-------------------|
| `--cw-status-success` | kelp-800 | wake-500 | §8: offline/success |
| `--cw-status-warning` | brass-700 | brass-500 | §8: warning on light |
| `--cw-status-error` | rust-600 | rust-600 | §8: danger/sensitive |
| `--cw-status-info` | harbor-700 | mist-200 | §7: information state |

**runtime (5 tokens — Crosswake-unique tier):**
| Token | Value | Dark value | Brand book source |
|-------|-------|------------|-------------------|
| `--cw-runtime-liveview` | harbor-700 | mist-200 | §8: LiveView runtime |
| `--cw-runtime-offline` | kelp-800 | wake-500 | §8: Offline island |
| `--cw-runtime-native` | brass-500 | brass-500 | §8: Native screen |
| `--cw-runtime-sensitive` | rust-600 | rust-600 | §8: Sensitive/cache-never |
| `--cw-runtime-bridge` | plum-700 | foam-50 | §8: Bridge/contract |

**Total semantic: 27 tokens.** Within the D-06 hard cap of 30.

### Non-Color Tokens (from §9/§13 — in scope for TOKN-01)

The brand book explicitly specifies these dimension values. They belong in `crosswake.tokens.json` as DTCG `$type: "dimension"` and `$type: "fontFamily"` tokens:

**Font family (3 tokens):**
- `font.display`: `["Space Grotesk", "ui-sans-serif", "system-ui", "-apple-system", "BlinkMacSystemFont", "Segoe UI", "sans-serif"]`
- `font.body`: `["Atkinson Hyperlegible Next", "ui-sans-serif", ...]`
- `font.mono`: `["JetBrains Mono", "SFMono-Regular", "Consolas", "Liberation Mono", "monospace"]`

**Type scale (8 tokens, `$type: "dimension"` for size, paired line-heights):**
| Token | Size | Line height | Use |
|-------|------|-------------|-----|
| `text.xs` | 12px | 16px | badges, metadata |
| `text.sm` | 14px | 20px | nav, labels |
| `text.md` | 16px | 24px | body |
| `text.lg` | 18px | 28px | lead body |
| `text.xl` | 20px | 30px | card headings |
| `display.sm` | 28px | 36px | docs page title |
| `display.md` | 40px | 48px | landing section title |
| `display.lg` | 56px | 64px | hero headline |

**Spacing grid (base unit only, 1 token):**
- `spacing.base`: 4px — brand book §13 specifies 4px base grid

**Radius (4 tokens):**
- `radius.sm`: 6px (inline code, tiny badges)
- `radius.md`: 10px (buttons, inputs)
- `radius.lg`: 14px (cards)
- `radius.xl`: 20px (hero panels, major diagrams)

**Focus ring (1 token, `$type: "dimension"`):**
- `focus.ring-width`: 2px — brand book §13 and §21 specify 2px focus outline

**Tracking (1 token, for display headings):**
- `text.tracking-tight`: -0.02em — brand book §9 "tight but readable tracking"

**Total non-color tokens: ~18.** Grand total token file: ~62 tokens (17 primitive + 27 semantic + 18 non-color). This is within reasonable scope for a v1 token file.

### TOKN-03: 12-State Coverage Mapping

| State | D-09 strategy | Token(s) involved |
|-------|---------------|-------------------|
| default | Semantic token default value | All base semantic tokens |
| hover | `--cw-action-hover` | action group |
| active | CSS selector on semantic tokens | `action.bg`, `action.fg` (no new token) |
| focus | `--cw-action-focus-ring` (2px outline) | action group |
| disabled | `opacity: 0.45` + label; `text.subtle` | text group |
| selected | Pattern: `action.bg` + `border.strong` | action + border groups |
| success | `--cw-status-success` | status group |
| warning | `--cw-status-warning` | status group |
| error | `--cw-status-error` | status group |
| info | `--cw-status-info` | status group |
| subtle | `--cw-text-subtle` | text group |
| muted | `--cw-text-muted` | text group |

All 12 states are covered. AUDIT.md §7 must document this mapping explicitly (per D-09: "AUDIT.md §7 documents this mapping explicitly so TOKN-03 is auditable").

---

## Research Finding 4: contrast.mjs + compile-tokens.js Design

[VERIFIED: CONTEXT.md D-04/D-07 + milestone STACK.md WCAG formula + direct computation verification]

### contrast.mjs (AUDT-02)

**Location:** `brandbook/tools/contrast.mjs`
**Dependencies:** Zero — pure Node.js ESM
**Input:** Reads `brandbook/tokens/crosswake.tokens.json` for palette hex values (or can hardcode palette as a constant for Phase 102 before tokens file exists)
**Output:** Markdown table (or structured JSON) of all pairings with contrast ratios and AA/AAA pass/fail

**Algorithm (WCAG 2.2, verified):**
```javascript
// threshold: 0.04045 (corrected May 2021; use this, not 0.03928)
function linearize(c) {
  const s = c / 255;
  return s <= 0.04045 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
}
function luminance(r, g, b) {
  return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b);
}
function contrast(hex1, hex2) {
  // lighter/darker swap ensures (L1 + 0.05) / (L2 + 0.05) with L1 >= L2
  ...
}
```

**Approved pairings to compute (minimum set for AUDIT.md appendix):**

| Foreground | Background | Computed Contrast | AA text | AA-large/UI |
|------------|------------|------------------|---------|-------------|
| foam-50 | current-950 | 16.58:1 | PASS | PASS |
| current-950 | foam-50 | 16.58:1 | PASS | PASS |
| white | wake-700 | 5.45:1 | PASS | PASS |
| current-950 | brass-500 | 6.35:1 | PASS | PASS |
| wake-500 | current-950 | 5.62:1 | PASS | PASS |
| wake-700 | foam-50 | 4.85:1 | PASS | PASS |
| white | rust-600 | 6.02:1 | PASS | PASS |
| foam-50 | plum-700 | 11.38:1 | PASS | PASS |
| **stone-500** | **foam-50** | **4.09:1** | **FAIL** | PASS |
| stone-600 | foam-50 | 4.53:1 | PASS | PASS |
| stone-600 | white | 5.09:1 | PASS | PASS |
| brass-700 | foam-50 | 4.74:1 | PASS | PASS |
| wake-500 | foam-50 | 2.95:1 | FAIL | FAIL |
| mist-200 | foam-50 | 1.35:1 | FAIL | FAIL |
| foam-50 | current-900 | 15.14:1 | PASS | PASS |
| mist-200 | current-950 | 12.25:1 | PASS | PASS |
| wake-500 | current-900 | 5.14:1 | PASS | PASS |
| brass-500 | current-950 | 6.35:1 | PASS | PASS |
| white | kelp-800 | 12.32:1 | PASS | PASS |
| white | harbor-700 | 9.83:1 | PASS | PASS |

Stone 600 on Current 950 is 3.66:1 — passes AA non-text (3:1) but fails AA normal text (4.5:1). Stone 600 is therefore appropriate for non-text use on dark surfaces (borders, decorative elements) but not for muted text on dark. Muted text on dark maps to `mist-200 on current-950` (12.25:1, PASS).

**Script output format (Claude's discretion):** Emit markdown table with columns: Foreground, Background, Ratio, AA, AAA. Include a summary line: "X pairings tested, Y fail AA normal text, Z fail AA large text / non-text UI."

### compile-tokens.js (TOKN-02)

**Location:** `brandbook/tools/compile-tokens.js`
**Dependencies:** Zero — pure Node.js CJS or ESM (<80 LOC per D-07)
**Input:** `brandbook/tokens/crosswake.tokens.json`
**Output:** `brandbook/tokens/tokens.css`

**DTCG alias resolution:** In the JSON, semantic tokens reference primitive tokens via `{primitive.wake.700}` syntax. The compile script must resolve these at CSS generation time into the actual CSS variable references (`var(--cw-primitive-wake-700)`), not inline the hex values. This keeps the CSS correct: changing a primitive hex only requires regenerating the CSS, not editing semantic token $values.

**Resolution algorithm:**
1. Parse JSON
2. Walk the tree, collecting all tokens with `$value` into a flat lookup map (dot-path → token)
3. For each semantic token: if `$value` is a string matching `{path.to.primitive}`, replace with `var(--cw-primitive-[flattened-path])`
4. Emit CSS sections with tier comment headers

**Generated CSS structure:**
```css
/* GENERATED from crosswake.tokens.json — do not edit */
/* Edit crosswake.tokens.json, then run: node brandbook/tools/compile-tokens.js */

/* ─── Primitive tier (internal — do not reference directly in component CSS) ─── */
:root {
  --cw-primitive-current-950: #09141A;
  /* ... */
}

/* ─── Semantic tier (public contract) ─── */
:root {
  --cw-surface-default: var(--cw-primitive-foam-50);
  --cw-text-default: var(--cw-primitive-current-950);
  /* ... */
}

/* ─── Dark mode ─── */
@media (prefers-color-scheme: dark) {
  :root:not([data-theme]) {
    --cw-surface-default: var(--cw-primitive-current-950);
    --cw-text-default: var(--cw-primitive-foam-50);
    /* ... */
  }
}

[data-theme="dark"] {
  --cw-surface-default: var(--cw-primitive-current-950);
  /* ... */
}

/* ─── Forbidden pairings (DO NOT USE) ─── */
/* stone-500 on foam-50: 4.09:1 — fails AA normal text */
/* wake-500 on foam-50: 2.95:1 — role issue; dark-surface only */
/* mist-200 on foam-50: 1.35:1 — border/dark-surface only */
```

---

## Research Finding 5: Gitignore Additions

[VERIFIED: direct `.gitignore` inspection]

The current `.gitignore` (inspected) contains no `node_modules` entry of any kind. The `/**/_build/` glob does NOT match `node_modules`. Required additions:

```
# brandbook tooling (Node processing — not committed)
/brandbook/tools/node_modules/
/brandbook/tools/fonts/
```

**Timing:** These two lines should be added in the first task of Phase 102 (directory setup), before any `npm install` runs in `brandbook/tools/`. If the directory doesn't exist yet when the gitignore is written, git will simply ignore the pattern until the directory appears — no problem.

**No other gitignore changes needed for Phase 102.** The `brandbook/` directory itself is committed; only `node_modules/` and `fonts/` subdirectories under `tools/` are gitignored.

---

## Research Finding 6: AUDT-04 Checkpoint Mechanics

[VERIFIED: CONTEXT.md D-12 + audit brief behavior constraints]

### What Requires Ratification (D-12)

The ratification checkpoint must present the user with a structured summary of every audit verdict that falls under D-12's "Requires AUDT-04 ratification" category:

1. **Typography verdicts** (font family, weight choices, tracking, fallback stacks)
   - Specifically: KEEP Space Grotesk verdict (§10 of brief)
   - D-11 TIGHTEN rider: custom `w`/`k` wake-angle cuts are mandatory for Phase 103

2. **Logo direction verdict** (AUDIT.md §8)
   - Wake Mark concept evaluation — KEEP/TIGHTEN/REWORK verdict
   - Phase 103 letter-cut brief framing

3. **Any palette REWORK** that shifts emotional character rather than fixing math
   - Per D-01..D-02, no hex changes are needed except adding Stone 600 — this addition is unilateral (math-forced), not a ratification item
   - If the audit produces any REWORK verdict on a color family (e.g., "Plum 700 is too similar to Phoenix's purple"), that verdict must be in the ratification summary

4. **Phase 103 letter-cut brief itself** (D-11 cascade)
   - The brief for custom `w`/`k` cuts must be stated in the ratification checkpoint so the user can approve it before Phase 103 executes it

### Ratification Summary Template

The plan must include a final task that produces (or presents) this summary to the user:

```
## AUDT-04 Ratification Summary

Changes requiring your approval before Phase 103 begins:

**Typography:**
- [verdict on Space Grotesk KEEP/TIGHTEN]
- [weights, tracking, fallback stack confirmation]
- MANDATORY: Custom w/k wake-angle cuts on wordmark (Phase 103 brief)

**Logo direction:**
- [AUDIT.md §8 verdict]
- [Phase 103 tournament brief summary]

**Palette (if any REWORK verdicts):**
- Stone 600 (#756D63) addition — UNILATERAL (math-forced, no approval needed)
- [any other verdicts]

Changes the audit made unilaterally (no approval needed):
- Stone 600 added as primitive
- text.muted → Stone 600; text.subtle → Stone 500 (large/disabled/decorative only)
- All semantic role assignments
- Approved-pairings table (computed, not estimated)
- Token naming and structure

Please confirm: ✓ Approved / ✗ Amend [section]
```

### Checkpoint Task Shape

The final plan task is: **checkpoint:human-verify** — do not auto-proceed. Summarize all ratification items from AUDIT.md. Block Phase 103 until explicit user confirmation is received.

---

## Standard Stack

### Core (Phase 102 tooling)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Node.js (system) | ≥18 | Run contrast.mjs + compile-tokens.js | Zero-dep scripts; no npm packages for Phase 102 tooling |

**Phase 102 requires NO npm packages.** Both `contrast.mjs` and `compile-tokens.js` are dependency-free Node.js scripts. The `brandbook/tools/package.json` with `opentype.js` is a Phase 103 concern (wordmark generation).

### Confirmed Available Environment

| Dependency | Required By | Available | Notes |
|------------|------------|-----------|-------|
| Node.js | contrast.mjs, compile-tokens.js | Presumed (standard macOS dev machine) | Verify with `node --version` in Wave 0 |
| git | Committing brandbook/ | ✓ (repo is git) | — |

---

## Architecture Patterns

### Recommended brandbook/ Structure for Phase 102

```
brandbook/
├── AUDIT.md                          # 14-section audit (AUDT-01)
└── tools/
    ├── contrast.mjs                  # WCAG contrast matrix script (AUDT-02)
    └── compile-tokens.js             # tokens.json → tokens.css compiler (TOKN-02)
tokens/
    ├── crosswake.tokens.json         # DTCG source of truth (TOKN-01)
    └── tokens.css                    # Generated CSS (TOKN-02, TOKN-03)
```

(The `tokens/` directory lives at `brandbook/tokens/` — flattened above for clarity.)

Phase 102 also modifies `.gitignore` (2 lines).

### DTCG JSON Structure Pattern

[VERIFIED: CONTEXT.md D-07 + milestone STACK.md DTCG section]

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
      "$description": "Main light background"
    }
  }
}
```

**Note on dark mode in DTCG:** DTCG does not have a native theming primitive. The `$value` fields hold the light-mode value. The compile-tokens.js script must emit a second set of semantic tokens under `@media (prefers-color-scheme: dark)` by reading a separate `"$dark"` property on semantic tokens (Claude's discretion — one approach) or by maintaining a parallel dark section in the JSON. The simpler approach: add `"$dark": "{primitive.current.950}"` alongside `"$value"` on semantic tokens, and have compile-tokens.js emit both `:root` and dark-mode blocks.

### Anti-Patterns to Avoid

- **Hardcoding hex in tokens.css:** Always resolve primitives to CSS variables, not inline hex. `--cw-surface-default: var(--cw-primitive-foam-50)` not `--cw-surface-default: #F7F1E6`.
- **Component-level tokens:** D-05 forbids a component tier. Stop at semantic.
- **Editing tokens.css directly:** It has a "do not edit" header; enforce via task description.
- **Mixing primitive references in component CSS:** No `var(--cw-primitive-wake-700)` in app code; only `var(--cw-action-bg)`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| WCAG luminance math | Custom approximation | The exact formula from WCAG 2.2 spec with 0.04045 threshold | Off-by-one on threshold produces wrong AA verdicts for near-boundary colors (Stone 500 at 4.09 is precisely one of these) |
| Token alias resolution | Regex string replacement | Tree-walk with dot-path lookup map | Regex breaks on nested group names; tree-walk handles arbitrary depth correctly |
| Dark mode CSS | JavaScript theme toggle | CSS `@media prefers-color-scheme` + `[data-theme]` attribute | Per D-08; matches daisyUI pattern; no JS required for system preference |

---

## Common Pitfalls

### Pitfall 1: Writing AUDIT.md Verdicts as Hedged Prose

**What goes wrong:** Audit reads "This is largely good but could potentially be improved in some areas" — provides no actionable signal. REWORK verdicts without stated cost are spec violations (the audit brief: "Every REWORK requires a stated cost").

**How to avoid:** Each verdict is exactly one of: KEEP / TIGHTEN / REWORK / ADD / REMOVE. For TIGHTEN: state what sharpening is needed. For REWORK: state what it forces downstream. For ADD: state what is missing and why it matters.

**Warning signs:** Audit prose contains "could," "might," "potentially," "seems."

### Pitfall 2: Confusing Role Issues With Hex Issues

**What goes wrong:** Wake 500 on Foam 50 (2.95:1) gets a hex-change recommendation — shifting Wake 500 hex to pass AA. This is wrong: the audit decision (D-01) is that this is a role issue, not a hex problem. Wake 500 is meant for dark surfaces, not light-surface text.

**How to avoid:** Follow D-01 exactly. The only true hex failure is Stone 500 on Foam 50. All other failures are role misuse, documented via D-03 `$description` restrictions.

### Pitfall 3: Stone 600 Dark-Mode Confusion

**What goes wrong:** Stone 600 (`--cw-text-muted`) is placed on `current-950` backgrounds in dark mode because it's "the muted text token." But Stone 600 on Current 950 is only 3.66:1 — passes AA non-text but fails AA normal text.

**How to avoid:** In dark mode, `text.muted` must map to `mist-200` (12.25:1 on current-950 — PASS). Only the light-mode value of `text.muted` is Stone 600. Both the JSON dark value and the generated CSS dark-mode block must use mist-200 for text.muted.

### Pitfall 4: Token File Exceeds Hard Cap Without Warning

**What goes wrong:** Tokens proliferate during implementation — "we need a `text.brand` token" — pushing past the D-06 hard cap of 30 semantic tokens. Once tokens are committed, renaming them cascades through AUDIT.md, tokens.css, brand book specimens, and future phases.

**How to avoid:** During task execution, count semantic tokens before committing. If count approaches 28, stop and evaluate whether any proposed addition fits into an existing slot. The D-06 cap is a hard constraint, not a guideline.

### Pitfall 5: AUDIT.md Sections Mis-numbered or Missing

**What goes wrong:** The audit brief specifies exactly 14 numbered sections. AUDIT.md ships with 12, or sections are reordered. The planner cannot create a verification check against section counts.

**How to avoid:** Wave 0 (or task description) establishes the 14-section scaffold as an empty file before any prose is written. Each section gets its number and title as a heading. Fill sections sequentially.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None — verification is prose/file inspection + script execution |
| Config file | n/a |
| Quick run command | See per-requirement commands below |
| Full suite command | All commands below, run sequentially |

Phase 102 produces text artifacts (AUDIT.md, JSON, CSS) and two Node scripts. Validation is structural inspection plus script execution, not a test suite.

### Phase Requirements → Verification Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| AUDT-01 | AUDIT.md has exactly 14 sections, each with a verdict | structural grep | `grep -c "^## " brandbook/AUDIT.md` (expect ≥14); `grep -E "KEEP\|TIGHTEN\|REWORK\|ADD\|REMOVE" brandbook/AUDIT.md \| wc -l` (expect ≥14 verdicts) | ❌ Wave 0 scaffold |
| AUDT-01 | Every REWORK has a stated cost | prose grep | `grep -A3 "REWORK" brandbook/AUDIT.md \| grep -i "cost\|forces\|requires\|downstream"` — any REWORK block missing "cost" indicator is a gap | ❌ Wave 0 scaffold |
| AUDT-02 | contrast.mjs runs and produces output | script execution | `node brandbook/tools/contrast.mjs \| grep -E "PASS\|FAIL"` — must produce ≥20 rows | ❌ Wave 0 (script creation task) |
| AUDT-02 | Matrix includes all 17 primitives (or approved subset) | output inspection | `node brandbook/tools/contrast.mjs \| wc -l` — expect ≥22 lines (header + 20+ pairs) | ❌ Wave 0 |
| AUDT-02 | Stone 500 on Foam 50 shows as FAIL | output grep | `node brandbook/tools/contrast.mjs \| grep "stone-500.*foam-50\|foam-50.*stone-500"` — expect FAIL | ❌ Wave 0 |
| AUDT-02 | Stone 600 on Foam 50 shows as PASS | output grep | `node brandbook/tools/contrast.mjs \| grep "stone-600.*foam-50\|foam-50.*stone-600"` — expect PASS | ❌ Wave 0 |
| AUDT-03 | Drift flagged in AUDIT.md with cited file/line | prose grep | `grep -n "offline_ui\|gen.offline_ui\|blue.*amber\|tailwind.config\|cw-wake.*blue\|drift\|NORM-01" brandbook/AUDIT.md` — expect ≥3 hits | ❌ Wave 0 |
| AUDT-04 | Checkpoint task exists in plan with ratification summary | plan inspection | Manual — verify final task in plan is checkpoint:human-verify with D-12 items enumerated | n/a |
| TOKN-01 | JSON is valid DTCG format | Node one-liner | `node -e "const t = JSON.parse(require('fs').readFileSync('brandbook/tokens/crosswake.tokens.json','utf8')); console.log('keys:', Object.keys(t).join(', '))"` — must not throw; must print primitive, surface, text, action, border, status, runtime | ❌ Wave 0 |
| TOKN-01 | JSON contains Stone 600 primitive | jq or Node | `node -e "const t=JSON.parse(require('fs').readFileSync('brandbook/tokens/crosswake.tokens.json','utf8')); console.log(JSON.stringify(t.primitive?.stone?.['600']))"` — expect `{"$value":"#756D63",...}` | ❌ Wave 0 |
| TOKN-01 | JSON contains all 5 runtime semantic tokens | Node | `node -e "const t=JSON.parse(require('fs').readFileSync('brandbook/tokens/crosswake.tokens.json','utf8')); const r=t.runtime; console.log(Object.keys(r).filter(k=>!k.startsWith('\$')))"` — expect `['liveview','offline','native','sensitive','bridge']` | ❌ Wave 0 |
| TOKN-02 | tokens.css generated header present | grep | `head -1 brandbook/tokens/tokens.css \| grep "GENERATED"` — expect match | ❌ Wave 0 |
| TOKN-02 | tokens.css semantic tokens reference var(--cw-primitive-*) not hardcoded hex | grep | `grep -E "var\(--cw-primitive-" brandbook/tokens/tokens.css \| wc -l` (expect ≥20); `grep -E ":\s+#[0-9a-fA-F]{6}" brandbook/tokens/tokens.css \| grep -v "cw-primitive"` (expect 0 lines in semantic block) | ❌ Wave 0 |
| TOKN-02 | tokens.css contains dark mode block | grep | `grep -c "prefers-color-scheme: dark" brandbook/tokens/tokens.css` — expect ≥1 | ❌ Wave 0 |
| TOKN-03 | All 12 states addressed (via $description or pattern) | manual + grep | `grep -Ei "hover\|active\|focus\|disabled\|selected\|success\|warning\|error\|info\|subtle\|muted" brandbook/tokens/crosswake.tokens.json \| wc -l` — expect ≥12 distinct hits; cross-check with D-09 state table in AUDIT.md §7 | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** Run the applicable command(s) from the table above for the task's requirement
- **Per wave merge:** Run full suite (all commands above sequentially)
- **Phase gate:** All commands green + AUDT-04 checkpoint explicitly confirmed before Phase 103 begins

### Wave 0 Gaps

The following artifacts must be scaffolded/created in Wave 0 (before any substantive work):

- [ ] `brandbook/` directory created
- [ ] `brandbook/tools/` directory created
- [ ] `.gitignore` amended with 2 lines (`/brandbook/tools/node_modules/` and `/brandbook/tools/fonts/`)
- [ ] `brandbook/AUDIT.md` scaffolded — 14 empty sections with correct headings (from audit brief §1–§14)
- [ ] `brandbook/tools/contrast.mjs` — placeholder file (will be filled in audit tooling task)
- [ ] `brandbook/tools/compile-tokens.js` — placeholder file
- [ ] `brandbook/tokens/` directory created
- [ ] `brandbook/tokens/crosswake.tokens.json` — scaffold with `{}` or minimal structure

---

## Security Domain

`security_enforcement` is not explicitly set to false in `.planning/config.json`. ASVS categories apply minimally to this phase.

### Applicable ASVS Categories

| ASVS Category | Applies | Control |
|---------------|---------|---------|
| V2 Authentication | No | No auth in brand tooling |
| V3 Session Management | No | No sessions |
| V4 Access Control | No | No access control |
| V5 Input Validation | Minimal | contrast.mjs: validate hex string format before parseInt |
| V6 Cryptography | No | No crypto |

### Known Threat Pattern

| Pattern | STRIDE | Mitigation |
|---------|--------|-----------|
| SVG with script injection | Spoofing/Tampering | Path-only SVGs; no `<script>` — enforced by design |
| Font binary OFL violation | — | Gitignore fonts/; committed output is path data, not font software |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Node.js ≥18 is available on the execution machine | Environment | contrast.mjs and compile-tokens.js will fail if Node is absent; recoverable (install Node) |
| A2 | The `brandbook/tools/package.json` with opentype.js is a Phase 103 concern; Phase 102 scripts are zero-dep | Standard Stack | If compile-tokens.js needs a JSON5 parser or similar, a dep would be needed; but pure JSON + standard Node APIs suffice |

**If this table is empty for verified claims:** All non-assumed claims are cited to CONTEXT.md locked decisions (D-01..D-12), direct file inspection, or live computation output.

---

## Open Questions

1. **Stone 600 dark-surface text use**
   - What we know: Stone 600 on Current 950 is 3.66:1 — fails AA normal text, passes AA non-text
   - What's unclear: The `text.muted` dark-mode mapping should use `mist-200` (12.25:1) — but is there any desired use of stone-600 on dark surfaces for non-text elements (borders, decorative lines)?
   - Recommendation: Document Stone 600 as light-mode-only for text; permit as border/decorative on dark surfaces. State this in AUDIT.md §7 $descriptions.

2. **Semantic count at 27: any candidates for consolidation?**
   - What we know: 27 is within D-06's hard cap of 30
   - What's unclear: During implementation, `surface.inset` (white / current-800) may duplicate `surface.raised` semantically in practice
   - Recommendation: Keep both; the distinction (foam-100 vs white on light) is meaningful for code blocks vs regular cards. Revisit only if count approaches cap during Phase 103 brand book construction.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | contrast.mjs, compile-tokens.js | Presumed ✓ | — | — |
| git | Commits | ✓ | — | — |
| `brandbook/` dir | All artifacts | ❌ (create in Wave 0) | — | Create as first task |

**Missing with no fallback:** None.
**Missing with fallback:** None — only directory creation is needed, which is a Wave 0 task.

---

## Sources

### Primary (HIGH confidence)
- `.planning/phases/102-brand-audit-token-foundation/102-CONTEXT.md` — locked decisions D-01..D-12, all palette/token decisions verified
- `.planning/phases/102-brand-audit-token-foundation/102-AUDIT-BRIEF.md` — 14-section audit output spec, verbatim structure
- `.planning/REQUIREMENTS.md` — AUDT-01..04, TOKN-01..03 definitions
- `prompts/crosswake-brand-book.md` — all 25 sections read and mapped
- `examples/phoenix_host/assets/css/app.css` — 16 CSS custom properties confirmed (correct teal/brass palette)
- `lib/mix/tasks/crosswake.gen.offline_ui.ex` — lines 67–90: Tailwind config snippet with blue/amber scale confirmed (AUDT-03 evidence)
- `priv/templates/crosswake/offline_ui/offline_page.html.heex.eex` — `border-cw-wake-700`, `border-cw-brass-500` confirmed
- `priv/templates/crosswake/offline_ui/offline_root.html.heex.eex` — `bg-cw-foam-50 text-cw-current-950` confirmed
- `.gitignore` — no `node_modules` entry confirmed; two additions needed
- `.planning/config.json` — `nyquist_validation` absent → validation architecture enabled
- Live Node.js WCAG computation — all contrast ratios in this document computed fresh, not estimated
- `.planning/research/STACK.md` — WCAG formula, DTCG 2025.10 syntax, font availability (all HIGH confidence from prior milestone research)
- `.planning/research/ARCHITECTURE.md` — gitignore analysis, brandbook/ structure, mix.exs :files confirmed
- `.planning/research/PITFALLS.md` — token naming, raw-color pitfalls

### Secondary (MEDIUM confidence)
- `.planning/research/SUMMARY.md` — phase ordering rationale, audit scope
- `.planning/research/FEATURES.md` — deliverable table stakes, anti-features

---

## Metadata

**Confidence breakdown:**
- Audit section mapping: HIGH — derived from direct reading of both 25-section brand book and 14-section audit brief
- AUDT-03 drift evidence: HIGH — exact file/line citations from direct file reads
- Token inventory: HIGH — fully derived from locked D-05..D-09 decisions + brand book §8/§9/§13
- Contrast ratios: HIGH — computed live with the exact WCAG formula; not estimated
- compile-tokens.js design: HIGH — alias resolution approach is standard DTCG tree-walk; zero-dep confirmed by D-07
- Validation commands: MEDIUM — grep-based structural checks are correct; exact output counts should be verified against final artifacts during execution
- AUDT-04 ratification structure: HIGH — derived directly from D-12 verbatim

**Research date:** 2026-06-11
**Valid until:** This research is grounded in locked decisions from CONTEXT.md and direct code inspection — valid for the duration of Phase 102. Token inventory may need minor adjustment if audit §7 reveals a compelling consolidation (LOW probability given D-06 hard cap).
