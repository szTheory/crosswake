# Crosswake Logo — Production Asset Suite

**Phase 104 production suite.** All files are path-only SVGs (no `<text>` elements), self-contained (no external refs), built from the LOGO-05 signed-off V1 baseline geometry.

## Asset Index

| File | Purpose | Color | Usage |
|------|---------|-------|-------|
| `crosswake-mark.svg` | Wake mark icon alone | `currentColor` (embeddable) | HTML/CSS embeds; set stroke color on parent |
| `crosswake-mark-mono.svg` | Wake mark, literal #09141A | `#09141A` (Current 950) | Contexts that strip currentColor |
| `crosswake-typemark.svg` | W1 wordmark standalone | `currentColor` (embeddable) | Typography-only contexts; set fill on parent |
| `crosswake-lockup-horizontal.svg` | Mark + wordmark, horizontal, light | `#09141A` (Current 950) | Light backgrounds, standalone download |
| `crosswake-lockup-horizontal-dark.svg` | Mark + wordmark, horizontal, dark | `#F7F1E6` (Foam 50) | Dark backgrounds, standalone download |
| `crosswake-lockup-stacked.svg` | Mark above wordmark | `#09141A` (Current 950) | Square/compact contexts, light bg |
| `crosswake-lockup-subtitle.svg` | Horizontal lockup + tagline | `#09141A` (Current 950) | Only file carrying "Declare the crossing." |
| `favicon.svg` | 16-grid favicon with dark-mode swap | `#09141A` / `#F7F1E6` | Browser tab `<link rel="icon" href="favicon.svg">` |

## Colorway Reference

| Token | Hex | Name |
|-------|-----|------|
| Current 950 | `#09141A` | Dark (default text/mark on light bg) |
| Foam 50 | `#F7F1E6` | Light (mark on dark bg) |

## Embeddable vs Distribution

- **Embeddable** (mark, typemark): use `currentColor`; parent element controls color via CSS.
- **Distribution** (lockups, mono): literal hex fills; renders correctly when downloaded standalone.

## favicon.svg Notes

- Dedicated 16-grid redraw (`viewBox="0 0 16 16"`), NOT a scaled-down mark.
- 2 wake strokes, pixel-snapped coordinates, round caps, 20° angle preserved.
- Internal `<style>` with `@media (prefers-color-scheme: dark)` swaps `#09141A` → `#F7F1E6`.
- PNG fallbacks and GitHub README handling: Phase 106.

## LOGO-07 Regen Workflow

The W1 wordmark paths are reproducibly generated from Space Grotesk SemiBold:

```bash
node brandbook/tools/gen-wordmark.mjs
git diff --exit-code brandbook/logo/tournament/candidates/wordmark-base.svg
```

If the diff is clean, regeneration is deterministic. Parameters: `SpaceGrotesk[wght].ttf` at `wght=600`, `fontSize=72`, opentype.js 2.0.0. Font file is gitignored; fetch via `bash brandbook/tools/fetch-fonts.sh`.

The `wordmark-base.svg` output is the regeneration baseline. The `wordmark-r3.svg` used in production adds the 20° terminal-cut clip-path shears (D-02) — these are hand-curated on top of the base, committed separately for provenance.

## Source Provenance

- Mark geometry: `brandbook/logo/variants/v1-baseline.svg` (LOGO-05 sign-off, 2026-06-12)
- Wordmark: `brandbook/logo/tournament/candidates/wordmark-r3.svg` (D-02)
- Lockup layout: `brandbook/logo/tournament/candidates/R3-A-lockup-horizontal.svg` (D-03)
