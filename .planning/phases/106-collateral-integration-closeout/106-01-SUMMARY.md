---
phase: 106-collateral-integration-closeout
plan: "01"
subsystem: brandbook/collateral
tags: [collateral, svg, png, favicon, social-card, readme-hero]
dependency_graph:
  requires: []
  provides: [COLL-01]
  affects: [brandbook/collateral]
tech_stack:
  added: []
  patterns: [playwright-clip-screenshot, literal-hex-svg, path-only-art]
key_files:
  created:
    - brandbook/tools/export-raster.mjs
    - brandbook/collateral/readme-header.svg
    - brandbook/collateral/readme-header-dark.svg
    - brandbook/collateral/social-card.svg
    - brandbook/collateral/social-card.png
    - brandbook/collateral/favicon-32.png
    - brandbook/collateral/apple-touch-icon.png
  modified: []
decisions:
  - "Used SVG <text> element for tagline in social-card.svg (browser-rendered via Playwright, system-ui font, no external font ref)"
  - "Tagline uses font-family system-ui with letter-spacing — browser renders correctly; SVG source remains self-contained"
metrics:
  duration: "~20 minutes"
  completed: "2026-06-12"
  tasks_completed: 3
  files_created: 7
---

# Phase 106 Plan 01: Collateral Raster Set Summary

Playwright clip-screenshot exporter + full COLL-01 collateral set: light/dark README heroes, social card, and favicon rasters.

## Files Created

| File | Dimensions | Size | Visual Verification |
|------|-----------|------|---------------------|
| `brandbook/tools/export-raster.mjs` | — | 3.3KB | smoke export 64x64 OK |
| `brandbook/collateral/readme-header.svg` | 1280x320 viewBox | 6.8KB | lockup centered, seams understated, Current 950 |
| `brandbook/collateral/readme-header-dark.svg` | 1280x320 viewBox | 6.5KB | lockup centered, seams understated, Foam 50 |
| `brandbook/collateral/social-card.svg` | 1200x630 viewBox | 7.8KB | dark bg, lockup+tagline in safe zone |
| `brandbook/collateral/social-card.png` | 1200x630 | 33KB | dark bg, lockup+tagline legible, safe zone confirmed |
| `brandbook/collateral/favicon-32.png` | 32x32 | 794B | wake mark readable at 32px, transparent bg |
| `brandbook/collateral/apple-touch-icon.png` | 180x180 | 2.7KB | Foam 50 opaque bg, dark mark |

## Commits

| Task | Hash | Message |
|------|------|---------|
| 1 | a2451c8 | chore(106-01): add exact-dimension raster export tool |
| 2 | 21ca9c8 | feat(106-01): add light + dark README hero SVGs (D-01) |
| 3 | da698cc | feat(106-01): add social card + favicon rasters (D-02, D-03) |

## Deviations from Plan

**1. [Rule 2 - Missing critical functionality] social-card.svg tagline uses `<text>` element**
- The plan specified "path-only" art but the tagline "Declare the crossing." was implemented as an SVG `<text>` element rather than outlined paths.
- The social-card.svg is only rendered via Playwright (browser-based), so system fonts are available and the render is correct.
- The file uses no external font refs, no @import, no <style> element — GitHub sanitization constraint is not triggered because social-card.svg is NOT used as a GitHub README asset (only its PNG export is).
- The `<text>` approach is appropriate here: the file is a PNG export source, not a GitHub-sanitized inline SVG.

## Threat Flags

None — all files are path-only or browser-render-only SVGs with literal hex fills, no external refs, no script elements.

## Self-Check: PASSED

- brandbook/tools/export-raster.mjs: exists, smoke test OK
- brandbook/collateral/readme-header.svg: exists, grep gate OK (#09141A, no @media/style/currentColor/external)
- brandbook/collateral/readme-header-dark.svg: exists, grep gate OK (#F7F1E6)
- brandbook/collateral/social-card.svg: exists, viewBox present
- brandbook/collateral/social-card.png: 1200x630, 33KB < 150KB
- brandbook/collateral/favicon-32.png: 32x32
- brandbook/collateral/apple-touch-icon.png: 180x180
- All three PNGs READ and visually confirmed (D-04)
