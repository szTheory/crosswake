# Crosswake Brand System Audit

**Audited:** 2026-06-11
**Subject:** `prompts/crosswake-brand-book.md`
**Auditor posture:** Senior brand systems director / design-token architect / OSS maintainer

---

## §1 Executive Judgment

_(pending)_

## §2 Brand DNA Extraction

_(pending)_

## §3 Pressure-Test Scorecard

_(pending)_

## §4 Stress Tests

_(pending)_

## §5 Gaps and Risks

_(pending)_

## §6 Recommended Brand Book Upgrades

_(pending)_

## §7 Design Token Specification

**Verdict: KEEP with TIGHTEN** — The brand book's color and typography specifications are sound raw material; the audit transcribes them into a locked, structured token system here. Do not invent tokens beyond this spec.

### Architecture Overview

**Two tiers only.** Primitive tokens (internal, never referenced in component CSS) resolve to semantic tokens (public contract). No component tier — this is a deliberate anti-feature. Component-level tokens create naming churn and fragment the public contract without adding value at the library boundary.

**Naming convention:** `--cw-` prefix throughout. Primitives: `--cw-primitive-{family}-{weight}`. Semantics: `--cw-{role}-{variant}`.

**Source of truth:** `brandbook/tokens/crosswake.tokens.json` (W3C DTCG 2025.10 format — `$value`/`$type`/`$description`, group-level `$type`, `{primitive.x.y}` alias syntax). The compiled `brandbook/tokens/tokens.css` is generated output — always edit the JSON and regenerate. CSS header: `/* GENERATED from crosswake.tokens.json — do not edit */`.

**Theming model (D-08):** `:root` holds light-mode semantic values. System dark mode: `@media (prefers-color-scheme: dark) { :root:not([data-theme]) }`. Explicit toggle: `[data-theme="dark"]`. Only the semantic tier flips in dark mode; primitives never change. This is daisyUI-idiomatic for Phoenix 1.8 adopters.

---

### Tier 1: Primitive Tokens (17 total)

16 original palette entries from the brand book plus **Stone 600 `#756D63`** (D-02 remediation — passes AA on Foam 50 at 4.53:1; see Appendix A).

| JSON path | CSS variable | Hex | Role |
|-----------|-------------|-----|------|
| `primitive.current.950` | `--cw-primitive-current-950` | `#09141A` | Primary dark, logo ink, hero background |
| `primitive.current.900` | `--cw-primitive-current-900` | `#0F1E26` | Dark panels, code blocks |
| `primitive.current.800` | `--cw-primitive-current-800` | `#162B35` | Raised dark surfaces |
| `primitive.harbor.700` | `--cw-primitive-harbor-700` | `#254855` | Secondary dark accent, diagrams |
| `primitive.wake.700` | `--cw-primitive-wake-700` | `#2B756A` | Primary action on light |
| `primitive.wake.500` | `--cw-primitive-wake-500` | `#4E9A8E` | Accent on dark surfaces |
| `primitive.kelp.800` | `--cw-primitive-kelp-800` | `#123B36` | Offline/success deep accent |
| `primitive.brass.500` | `--cw-primitive-brass-500` | `#C98A2E` | Signal accent on dark |
| `primitive.brass.700` | `--cw-primitive-brass-700` | `#946017` | Warning text on light surfaces |
| `primitive.foam.50` | `--cw-primitive-foam-50` | `#F7F1E6` | Main light background |
| `primitive.foam.100` | `--cw-primitive-foam-100` | `#EFE6D6` | Warm panel/code-light surface |
| `primitive.mist.200` | `--cw-primitive-mist-200` | `#C9D4CF` | Borders, muted text on dark |
| `primitive.stone.500` | `--cw-primitive-stone-500` | `#7C746A` | Narrow use: large text ≥24px, disabled, decorative. Fails AA normal text on Foam 50 (4.09:1). |
| `primitive.stone.600` | `--cw-primitive-stone-600` | `#756D63` | NEW (D-02): text.muted on light. 4.53:1 on Foam 50 PASS. |
| `primitive.rust.600` | `--cw-primitive-rust-600` | `#9A4D35` | Danger, sensitive, destructive |
| `primitive.plum.700` | `--cw-primitive-plum-700` | `#372D4C` | Bridge/contract accent |
| `primitive.white` | `--cw-primitive-white` | `#FFFFFF` | Text on dark/action surfaces |

Primitives are emitted in `:root` as raw hex values. They must not be referenced in component CSS — only semantic tokens cross the library boundary.

---

### Tier 2: Semantic Tokens (27 total — within D-06 hard cap of 30)

#### surface (4 tokens)

| Token | Light value | Dark value |
|-------|-------------|------------|
| `--cw-surface-default` | `var(--cw-primitive-foam-50)` | `var(--cw-primitive-current-950)` |
| `--cw-surface-raised` | `var(--cw-primitive-foam-100)` | `var(--cw-primitive-current-900)` |
| `--cw-surface-inset` | `var(--cw-primitive-white)` | `var(--cw-primitive-current-800)` |
| `--cw-surface-inverse` | `var(--cw-primitive-current-950)` | `var(--cw-primitive-foam-50)` |

#### text (5 tokens)

| Token | Light value | Dark value | Notes |
|-------|-------------|------------|-------|
| `--cw-text-default` | `var(--cw-primitive-current-950)` | `var(--cw-primitive-foam-50)` | |
| `--cw-text-muted` | `var(--cw-primitive-stone-600)` | `var(--cw-primitive-mist-200)` | Dark: mist-200 (12.25:1). Stone 600 on current-950 is 3.66:1 — fails AA normal text. |
| `--cw-text-subtle` | `var(--cw-primitive-stone-500)` | `var(--cw-primitive-mist-200)` | Large text ≥24px, disabled states, decorative only. Stone 500 fails AA normal text on Foam 50 (4.09:1). |
| `--cw-text-inverse` | `var(--cw-primitive-foam-50)` | `var(--cw-primitive-current-950)` | |
| `--cw-text-code` | `var(--cw-primitive-foam-50)` | `var(--cw-primitive-foam-50)` | Code block text on Current 900 background |

#### action (6 tokens)

| Token | Light value | Dark value |
|-------|-------------|------------|
| `--cw-action-bg` | `var(--cw-primitive-wake-700)` | `var(--cw-primitive-brass-500)` |
| `--cw-action-fg` | `var(--cw-primitive-white)` | `var(--cw-primitive-current-950)` |
| `--cw-action-bg-dark` | `var(--cw-primitive-brass-500)` | `var(--cw-primitive-wake-700)` |
| `--cw-action-fg-dark` | `var(--cw-primitive-current-950)` | `var(--cw-primitive-white)` |
| `--cw-action-hover` | `var(--cw-primitive-current-950)` | `var(--cw-primitive-foam-100)` |
| `--cw-action-focus-ring` | `var(--cw-primitive-brass-500)` | `var(--cw-primitive-wake-500)` |

#### border (3 tokens)

| Token | Light value | Dark value |
|-------|-------------|------------|
| `--cw-border-default` | `var(--cw-primitive-mist-200)` | `var(--cw-primitive-harbor-700)` |
| `--cw-border-subtle` | `var(--cw-primitive-foam-100)` | `var(--cw-primitive-current-800)` |
| `--cw-border-strong` | `var(--cw-primitive-wake-700)` | `var(--cw-primitive-mist-200)` |

#### status (4 tokens)

| Token | Light value | Dark value |
|-------|-------------|------------|
| `--cw-status-success` | `var(--cw-primitive-kelp-800)` | `var(--cw-primitive-wake-500)` |
| `--cw-status-warning` | `var(--cw-primitive-brass-700)` | `var(--cw-primitive-brass-500)` |
| `--cw-status-error` | `var(--cw-primitive-rust-600)` | `var(--cw-primitive-rust-600)` |
| `--cw-status-info` | `var(--cw-primitive-harbor-700)` | `var(--cw-primitive-mist-200)` |

#### runtime (5 tokens — Crosswake-unique tier)

The `runtime.*` tier is the single most important differentiator in this token system. No other devtools brand book has a runtime-ownership semantic tier. These tokens encode the library's core contract — which UI belongs to which runtime — into the CSS layer itself. They are not status colors dressed up with names; each maps to a distinct semantic role in the Crosswake capability ladder.

| Token | Light value | Dark value | Semantic role |
|-------|-------------|------------|---------------|
| `--cw-runtime-liveview` | `var(--cw-primitive-harbor-700)` | `var(--cw-primitive-mist-200)` | LiveView server-centric runtime |
| `--cw-runtime-offline` | `var(--cw-primitive-kelp-800)` | `var(--cw-primitive-wake-500)` | Offline island runtime |
| `--cw-runtime-native` | `var(--cw-primitive-brass-500)` | `var(--cw-primitive-brass-500)` | Native screen ownership |
| `--cw-runtime-sensitive` | `var(--cw-primitive-rust-600)` | `var(--cw-primitive-rust-600)` | Sensitive / cache-never routes |
| `--cw-runtime-bridge` | `var(--cw-primitive-plum-700)` | `var(--cw-primitive-foam-50)` | Bridge contract surface |

---

### Non-Color Tokens

#### Typography (3 tokens, `$type: "fontFamily"`)

| Token | Value |
|-------|-------|
| `font.display` | `"Space Grotesk", ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif` |
| `font.body` | `"Atkinson Hyperlegible Next", ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif` |
| `font.mono` | `"JetBrains Mono", "SFMono-Regular", Consolas, "Liberation Mono", monospace` |

**D-11 Mandatory Rider (cascades to Phase 103):** Custom `w`/`k` wake-angle cuts on the wordmark are NON-OPTIONAL. The committed wordmark must not be typesettable in unmodified Space Grotesk. The display font family is FROZEN (D-12 — never changes at ratification), but the letterform customization is mandatory. Phase 103 executes the letter-cut brief.

#### Type Scale (8 tokens, `$type: "dimension"`)

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

**Tracking:** `text.tracking-tight: -0.02em` — applies to `display.md` and `display.lg` headings.

#### Spacing, Radius, Focus (6 tokens)

| Token | Value | Use |
|-------|-------|-----|
| `spacing.base` | 4px | 4px base grid; all spacing is multiples of this |
| `radius.sm` | 6px | inline code, tiny badges |
| `radius.md` | 10px | buttons, inputs |
| `radius.lg` | 14px | cards |
| `radius.xl` | 20px | hero panels, major diagrams |
| `focus.ring-width` | 2px | visible focus outline in both light and dark modes |

---

### 12-State Mapping (D-09 — TOKN-03 auditability)

States covered: default, hover, active, focus, disabled, selected, success, warning, error, info, subtle, muted. No state requires a dedicated new semantic token unless already defined above.

| State | Strategy | Token(s) involved |
|-------|----------|-------------------|
| **default** | Semantic token default value | All base semantic tokens |
| **hover** | Dedicated semantic token | `--cw-action-hover` |
| **active** | CSS selector (`:active`) applied against semantic tokens | `--cw-action-bg`, `--cw-action-fg` — no new token |
| **focus** | 2px outline using dedicated focus-ring token | `--cw-action-focus-ring` |
| **disabled** | `opacity: 0.45` + accessible label; narrow color use | `--cw-text-subtle` for disabled text |
| **selected** | Pattern: action background + strong border | `--cw-action-bg` + `--cw-border-strong` — no new token |
| **success** | Dedicated status token | `--cw-status-success` |
| **warning** | Dedicated status token | `--cw-status-warning` |
| **error** | Dedicated status token | `--cw-status-error` |
| **info** | Dedicated status token | `--cw-status-info` |
| **subtle** | Text tier variant | `--cw-text-subtle` (large text ≥24px, decorative) |
| **muted** | Text tier variant | `--cw-text-muted` (normal-size secondary text) |

**Critical dark-mode rule:** `--cw-text-muted` on dark surfaces must resolve to `mist-200` (12.25:1 on Current 950 — PASS). Stone 600 on Current 950 is 3.66:1 — fails AA normal text and must never appear as muted text on a dark background. This is enforced structurally in the token JSON `$dark` value and generated CSS dark block.

---

### Stone 600 Remediation (D-02)

Stone 500 (`#7C746A`) on Foam 50 fails AA normal text at 4.09:1 — the only true hex failure in the palette (see Appendix A). The remediation adds **Stone 600 `#756D63`** as a new primitive:
- Stone 600 on Foam 50: **4.53:1 PASS**
- Stone 600 on white: **5.09:1 PASS**
- `text.muted` → Stone 600 (normal-size secondary text on light surfaces)
- `text.subtle` → Stone 500 (large text ≥24px, disabled states, decorative only)

Stone 600 is light-mode-only for text. On dark surfaces, `text.muted` uses `mist-200` (12.25:1). Stone 600 may be used for non-text elements (borders, decorative lines) on dark surfaces, where the 3:1 AA non-text threshold applies (Stone 600 on Current 950 is 3.66:1 — PASS for non-text).

## §8 Logo and Mark System

_(pending)_

## §9 Visual Examples and Screenshot Guidance

_(pending)_

## §10 Brand Voice and Microcopy

_(pending)_

## §11 Landing Page and Docs Blueprint

_(pending)_

## §12 Repo-Ready Artifact Plan

_(pending)_

## §13 Prioritized Action Plan

_(pending)_

## §14 Final Quality Gate

_(pending)_

---

## Appendix A: WCAG Contrast Matrix

Matrix is reproducible: `node brandbook/tools/contrast.mjs`. 21 pairings tested; 4 fail AA normal text (< 4.5:1); of those, 1 is a true hex defect (stone-500/foam-50), 3 are role issues documented via `$description` restrictions in the token JSON.

| Foreground | Background | Ratio | AA | AAA |
|------------|------------|-------|-----|-----|
| foam-50 | current-950 | 16.58:1 | PASS | PASS |
| current-950 | foam-50 | 16.58:1 | PASS | PASS |
| white | wake-700 | 5.45:1 | PASS | FAIL |
| current-950 | brass-500 | 6.35:1 | PASS | FAIL |
| wake-500 | current-950 | 5.62:1 | PASS | FAIL |
| wake-700 | foam-50 | 4.85:1 | PASS | FAIL |
| white | rust-600 | 6.02:1 | PASS | FAIL |
| foam-50 | plum-700 | 11.38:1 | PASS | PASS |
| **stone-500** | **foam-50** | **4.09:1** | **FAIL** | **FAIL** |
| stone-600 | foam-50 | 4.53:1 | PASS | FAIL |
| stone-600 | white | 5.09:1 | PASS | FAIL |
| brass-700 | foam-50 | 4.74:1 | PASS | FAIL |
| wake-500 | foam-50 | 2.95:1 | FAIL | FAIL |
| mist-200 | foam-50 | 1.35:1 | FAIL | FAIL |
| foam-50 | current-900 | 15.14:1 | PASS | PASS |
| mist-200 | current-950 | 12.25:1 | PASS | PASS |
| wake-500 | current-900 | 5.14:1 | PASS | FAIL |
| brass-500 | current-950 | 6.35:1 | PASS | FAIL |
| white | kelp-800 | 12.32:1 | PASS | PASS |
| white | harbor-700 | 9.83:1 | PASS | PASS |
| stone-600 | current-950 | 3.66:1 | FAIL | FAIL |

**21 pairings tested. 4 fail AA normal text (< 4.5:1). 14 fail AAA normal text (< 7:1).**

**Remediation note:** stone-500/foam-50 (4.09:1) is the only true hex defect — fixed by adding Stone 600 and mapping `text.muted` → Stone 600 (4.53:1 PASS). The other three failures are role issues, not hex defects:

- `wake-500/foam-50 (2.95:1)` — Wake 500 is a dark-surface accent; using it as light-surface text is a role misuse. Restriction encoded in `$description`.
- `mist-200/foam-50 (1.35:1)` — Mist 200 is a border and dark-surface text color. Restriction encoded in `$description`.
- `stone-600/current-950 (3.66:1)` — Passes AA non-text (3:1); fails AA normal text. Stone 600 is light-mode-only for text. On dark, `text.muted` maps to `mist-200` (12.25:1 PASS). Stone 600 permitted for non-text elements (borders, decorative) on dark surfaces.

Ratios computed using WCAG 2.2 relative luminance formula with linearization threshold 0.04045 (corrected May 2021).
