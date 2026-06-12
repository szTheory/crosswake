---
plan: 104-03
phase: 104
wave: 3
status: complete
requirements: [LOGO-06, LOGO-07]
key-decisions:
  - "Production embeddables use currentColor (mark, typemark); distribution lockups use literal hex (#09141A light / #F7F1E6 dark) — D-10"
  - "Tagline 'Declare the crossing.' lives exclusively in crosswake-lockup-subtitle.svg as opentype.js paths (wght=500, 18px) — D-09"
  - "favicon.svg is a dedicated 16-grid redraw (2 strokes, 20-deg, pixel-snapped) with internal prefers-color-scheme swap — D-09"
  - "LOGO-07 confirmed: gen-wordmark.mjs regenerates diff-clean against committed wordmark-base.svg — D-11"
  - "brandbook/ committed size = 867KB < 1MB cap — D-12"
subsystem: brandbook/logo
tags: [svg, logo, brandbook, production, favicon]
dependency-graph:
  requires: [104-02]
  provides: [brandbook/logo/*, LOGO-06, LOGO-07]
  affects: [phase-105-brand-book, phase-106-favicon-pngs]
tech-stack:
  added: []
  patterns:
    - currentColor embeddables (mark, typemark)
    - literal-hex distribution lockups (D-10)
    - opentype.js path generation for tagline at wght=500
    - SVG prefers-color-scheme media query (favicon dark swap)
key-files:
  created:
    - brandbook/logo/crosswake-mark.svg
    - brandbook/logo/crosswake-mark-mono.svg
    - brandbook/logo/crosswake-typemark.svg
    - brandbook/logo/crosswake-lockup-horizontal.svg
    - brandbook/logo/crosswake-lockup-horizontal-dark.svg
    - brandbook/logo/crosswake-lockup-stacked.svg
    - brandbook/logo/crosswake-lockup-subtitle.svg
    - brandbook/logo/favicon.svg
    - brandbook/logo/README.md
  modified: []
decisions:
  - Tagline paths at 18px Space Grotesk Medium (wght=500) placed 10u below lockup baseline, left-aligned with wordmark
  - Stacked lockup: mark 64px centered over wordmark, 12u gap; wordmark at original paths (not scaled)
  - favicon: 2-line simplification (route + wake) is sufficient for 16px legibility; no notch at 16px
metrics:
  duration: ~45min
  completed: 2026-06-12
  tasks: 3
  files: 9
---

# Phase 104 Plan 03 Summary — Production Logo Suite

8 production SVGs shipped to `brandbook/logo/` from the LOGO-05 V1 baseline, covering embeddable currentColor variants and standalone literal-hex distribution lockups with all files render-verified.

## Task Outcomes

### Task 1: Mark + Typemark Family

| File | Render Outcome |
|------|----------------|
| `crosswake-mark.svg` | 20-deg 3-line wake mark, round caps, notch break visible, currentColor |
| `crosswake-mark-mono.svg` | Identical geometry, literal #09141A stroke |
| `crosswake-typemark.svg` | "Crosswake" SemiBold outlines + w/k terminal cuts visible, currentColor |

### Task 2: Lockup Family

| File | Render Outcome |
|------|----------------|
| `crosswake-lockup-horizontal.svg` | Mark + wordmark side-by-side, #09141A fills, correct proportions |
| `crosswake-lockup-horizontal-dark.svg` | Identical layout, #F7F1E6 fills (Foam 50) |
| `crosswake-lockup-stacked.svg` | Mark centered above wordmark, clean vertical spacing |
| `crosswake-lockup-subtitle.svg` | Lockup + "Declare the crossing." tagline at 18px, paths-only, no text elements |

### Task 3: Favicon + LOGO-07 + README

| Item | Outcome |
|------|---------|
| `favicon.svg` | 2-stroke 16-grid at 20-deg, pixel-snapped, round caps, dark-mode swap present |
| 16px legibility gate | Confirmed: 2 strokes distinct and non-merging at 16px, 32px, 64px |
| LOGO-07 regen | `gen-wordmark.mjs` diff-clean — regeneration is deterministic |
| Size budget | 867KB / 1048KB cap — PASS |
| `README.md` | Asset index + colorway table + LOGO-07 regen instructions |

## Verification Results

- `node brandbook/tools/check-production.mjs`: 11/11 OK (8 production + 3 variants)
- All embeddable files grep `currentColor`
- All distribution files grep literal hex fills
- `crosswake-lockup-subtitle.svg`: only file with "Declare the crossing." — no `<text>` elements
- `favicon.svg`: `viewBox="0 0 16 16"` + `prefers-color-scheme` present
- LOGO-07: `git diff --exit-code wordmark-base.svg` clean after `gen-wordmark.mjs`
- brandbook/ size: 867KB < 1MB (D-12)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Comment contained `<text` pattern matching check-production validator**
- Found during: Task 2 post-validation
- Issue: Comment in subtitle SVG read "never a `<text` element" — validator regex `/<text[\s>/]/i` matched the literal `<text ` in the comment
- Fix: Rewrote comment to avoid the pattern: "no text elements"
- Files modified: `crosswake-lockup-subtitle.svg`
- Commit: 9a69e5e (re-verified, then committed with fixed version)

None others — plan executed per spec.

## Known Stubs

None. All 8 files are complete production assets with correct fills, paths, and verified geometry.

## Threat Flags

None. All distribution files are self-contained (no external refs). favicon uses only inline CSS `@media` query with no script or network access.

## Self-Check: PASSED

- All 8 production SVGs exist in `brandbook/logo/`
- Task commits exist: 1c81005, 9a69e5e, aba73de
- check-production.mjs exits 0
- Size budget: 867KB < 1MB
