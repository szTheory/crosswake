---
phase: 108-consumer-normalization
plan: 04
type: execute
status: complete
requirements: [NORM-01, NORM-02]
human_signoff: approved
---

# 108-04 Summary — D-13 Render-Verify Release Gate

## What was built

The D-13 release gate: the normalized token consumers were **browser-rendered (Playwright + Chromium), visually inspected, and WCAG-measured** in BOTH light and dark mode — not grep-verified. Both dark-mode triggers were exercised (`prefers-color-scheme` on the generated page; `[data-theme="dark"]` on the host pages). Evidence: `108-RENDER-VERIFY.md` + 7 screenshots under `render/`.

Two **real AA failures** were caught by the render and remediated (semantic-tier only, no primitives, no `var()` fallbacks):

1. **Danger button, dark mode — was 3.10:1.** `--cw-status-error` (rust-600) does not flip, but `--cw-text-inverse` does (→ near-black), and rust-600 vs the near-black surface is ~3.1:1 in either role (symmetric — so a status-color-as-text outline fails identically). Fixed by switching **both** status buttons to the **D-06 outlined treatment**: `background: transparent`, `color: var(--cw-text-default)` (~16.6:1 both modes), status carried by `border-color: var(--cw-status-success|error)` (≥3:1 non-text affordance) + the button label. `button { border: 2px solid transparent }` keeps all buttons the same height.
2. **offline.css `.cw-offline-status-label`, light mode — was 4.11:1.** `--cw-text-muted` (stone-600) on `--cw-surface-raised` (foam-100); the D-05 "4.53:1" figure is against `surface-default`, not the darker raised surface. As an `<h2>` heading it took `--cw-text-default` (~15:1), keeping the raised status-card tonal hierarchy.

**Final status-button treatment:** outlined (text-default text + status-color border), both success and danger, for AA-correctness and visual consistency.

## Render-verify result

All six states re-rendered post-fix: **every text element ≥ 4.5:1, every border affordance ≥ 3:1, in both modes.** D-06 success-button dark-mode result: **PASS (5.62:1)**. Branded outline focus ring confirmed (brass-500 light / wake-500 dark, `box-shadow: none`). No layout shift, no hover/focus weirdness. `offline.css` and `index.html.heex` remain semantic-only.

**Human sign-off: approved** (D-13 release gate).

## Files changed

- `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex` — status buttons → outlined treatment.
- `priv/static/crosswake/offline.css` — status label → `--cw-text-default`.
- `.planning/phases/108-consumer-normalization/108-RENDER-VERIFY.md` — evidence log.
- `.planning/phases/108-consumer-normalization/render/*.png` — 7 rendered screenshots.

## Key links

- See `108-RENDER-VERIFY.md` for the full per-state verdicts, measured contrast table, method, and screenshot index.

## Self-Check: PASSED
