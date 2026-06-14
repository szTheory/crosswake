# 108 Render-Verify Evidence Log (D-13 Release Gate)

**Phase:** 108-consumer-normalization · **Plan:** 108-04 · **Date:** 2026-06-13

The project's render-verify rule is mandatory for brand-facing surfaces: this log records
**browser-rendered, visually-inspected** results (not grep) for the normalized token consumers
in BOTH light and dark mode, with **measured** WCAG contrast (not estimated).

## Method

- **Tool:** Playwright + Chromium (`examples/phoenix_host/node_modules/playwright`), headless, `deviceScaleFactor: 2`.
- **Surfaces rendered against the REAL stylesheets** (`priv/static/crosswake/tokens.css`, `priv/static/crosswake/offline.css`, `examples/phoenix_host/priv/static/css/app.css`), each with **`tokens.css` linked BEFORE the consuming stylesheet** (verified — otherwise custom properties are undefined and the test is invalid):
  - **Generated offline page** — `offline_root` head wiring (`tokens.css` → `app.css` → `offline.css`) + the generator's `offline_page` markup verbatim (`mix crosswake.gen.offline_ui --dir /tmp/cw_render_gen --app DemoApp`).
  - **Example host offline page** — `index.html.heex` inline `<style>` verbatim (EEx data-attrs stripped; the JS-hidden `Pass`/`Fail` status buttons exposed so their contrast could be measured).
  - **Example host deck surface** — `app.css` (`tokens.css` → `app.css`) with representative deck markup (`page-title`, `card`/`card-title`, `badge`, `text-sm`/`text-mono`, `btn-primary`, `btn-secondary`).
- **Dark mode exercised via BOTH triggers** per D-13: generated offline page via `prefers-color-scheme: dark` emulation (tests `@media … :root:not([data-theme])`); host offline + deck via the explicit `[data-theme="dark"]` attribute (tests `[data-theme="dark"]`). Token maps are identical across both paths.
- **Contrast measured in-page** from rendered `rgb()` via WCAG sRGB relative-luminance, resolving each element's true effective background by walking up to the nearest non-transparent ancestor. Border affordances measured against the surface behind them (non-text threshold 3:1).

## Screenshots

| State | File |
|-------|------|
| Generated offline — light | `render/gen-light.png` |
| Generated offline — dark (prefers-color-scheme) | `render/gen-dark.png` |
| Example host offline — light | `render/host-light.png` |
| Example host offline — dark (`[data-theme="dark"]`) | `render/host-dark.png` |
| Example host deck — light | `render/deck-light.png` |
| Example host deck — dark (`[data-theme="dark"]`) | `render/deck-dark.png` |
| Branded focus ring (deck `btn-primary`, keyboard `:focus-visible`) | `render/deck-focus-ring.png` |

## Per-state verdicts

### Generated offline page (offline.css)
- **Colors:** correct — foam page / white card / raised foam-100 status panel (light); near-black page / dark-navy surfaces (dark). ✓
- **Dark-mode flip:** flips correctly via `prefers-color-scheme`; no white-on-white / black-on-black / unstyled flash. ✓
- **D-07 non-color cue:** the status card's 4px `border-left` (`--cw-border-strong`) is present in both modes (teal in light, mist-200 in dark). ✓
- **AA (measured):** light — heading 18.6:1, status value 15.1:1, **status label 15.1:1**, subtitle 5.1:1; dark — all 9.6–18.7:1. All ≥ 4.5. ✓
- **Layout shift / weirdness:** none. ✓

### Example host offline page (index.html.heex inline styles)
- **Colors / dark flip:** correct in both modes via `[data-theme="dark"]`. ✓
- **Status buttons (AA measured):**
  - light: primary 5.45:1, **Pass (success) 16.58:1 text / 10.96:1 border**, **Fail (danger) 16.58:1 text / 5.36:1 border**, muted `#status` 4.53:1 — all pass.
  - dark: primary 6.35:1, **Pass 16.58:1 text / 5.62:1 border**, **Fail 16.58:1 text / 3.10:1 border**, muted `#status` 12.25:1 — all pass.
- **Focus rings:** browser-default outline (visible, outline-based, `box-shadow: none`) — acceptable; the branded ring lives in `app.css`/`offline.css` per D-07, not in this demo page's inline styles.
- **Layout shift / hover weirdness:** none. ✓

### Example host deck surface (app.css)
- **Colors / dark flip:** correct in both modes. ✓
- **AA (measured):** light — title 18.6:1, badge 15.1:1, text-sm 5.1:1, btn-primary 5.45:1, btn-secondary 18.6:1; dark — 6.35–16.6:1. All pass. ✓
- **Focus ring (D-07):** branded — `outline: 2px solid` `--cw-action-focus-ring` (brass-500 `rgb(201,138,46)` light / wake-500 dark), `outline-offset: 2px`, `box-shadow: none`. Captured at `render/deck-focus-ring.png`. ✓
- **Layout shift:** none. ✓

## D-06 success-button result (explicit)

- **Success button, dark mode: PASS at 5.62:1.** `--cw-status-success` flips to `wake-500` (#4E9A8E); the footgun (white text → ~2.9:1) is avoided because the foreground uses theme-aware `--cw-text-inverse` (→ near-black `current-950` in dark), not hardcoded white. (Note: after remediation below, both status buttons are *outlined*, so the success affordance is now carried by a `wake-500` border at 5.62:1 with `--cw-text-default` text at 16.58:1 — still PASS.)

## D-06 remediation applied (Task 2)

Render-verify caught a **real failure**: the **danger button in dark mode was 3.10:1** (initial treatment: `--cw-status-error` rust-600 fill + theme-flipping `--cw-text-inverse` → near-black text). Unlike success, `--cw-status-error` (rust-600) does **not** flip, while `--cw-text-inverse` does — and rust-600 vs the near-black surface is ~3.1:1 in **either** role (contrast is symmetric, so a status-color-as-text outline on the dark surface fails identically).

**Fix (semantic-tier only, no primitives, no `var()` fallbacks):** both `.btn-success` and `.btn-danger` switched to the **D-06 outlined treatment** in `examples/phoenix_host/.../index.html.heex` — `background: transparent`, `color: var(--cw-text-default)` (≈16.6:1 in both modes), status carried by `border-color: var(--cw-status-success|error)` (a ≥3:1 non-text affordance: success 10.96/5.62, danger 5.36/**3.10** light/dark) plus the button label. `button { border: 2px solid transparent }` keeps all three buttons the same height (no layout shift).

**Second finding (D-05-class), remediated:** `offline.css` `.cw-offline-status-label` used `--cw-text-muted` (stone-600) on `--cw-surface-raised` (foam-100) = **4.11:1, fails AA** — the D-05 "stone-600 passes at 4.53:1" figure is against `surface-default` (foam-50), not the one-step-darker `surface-raised`. Since the element is an `<h2>` heading, it was switched to `--cw-text-default` (→15.1:1), preserving the raised status-card tonal hierarchy. Re-rendered → PASS.

## Re-verification (post-remediation)

All six states re-rendered and re-measured: **every text element ≥ 4.5:1 and every border affordance ≥ 3:1 in both light and dark.** `offline.css` and `index.html.heex` remain semantic-only (0 `--cw-primitive-*`, 0 `var()` fallbacks). Visually inspected — colors correct, dark mode flips cleanly, status buttons legible in both modes, focus ring visible, no layout shift.

**Verdict: D-13 render-verify PASS** (pending human sign-off, Task 3).
