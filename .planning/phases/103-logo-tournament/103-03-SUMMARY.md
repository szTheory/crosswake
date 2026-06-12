---
phase: 103-logo-tournament
plan: "03"
subsystem: brandbook/logo/tournament
tags: [logo, svg, brandbook, typemark, tournament]
dependency_graph:
  requires: [103-01]
  provides: [E.svg, F.svg, G.svg]
  affects: [103-04-gallery, 103-05-checkpoint]
tech_stack:
  added: []
  patterns:
    - path-only SVG with currentColor for CSS-driven color swap
    - open/close XML syntax for line elements (check-candidates.mjs heuristic compat)
    - 20-degree wake geometry (slope -tan20=-0.364, dx_per_unit_y=2.747)
key_files:
  created:
    - brandbook/logo/tournament/candidates/E.svg
    - brandbook/logo/tournament/candidates/F.svg
    - brandbook/logo/tournament/candidates/G.svg
  modified:
    - brandbook/logo/tournament/candidates/E.svg (line syntax fix committed with F)
decisions:
  - Use open/close <line></line> syntax instead of self-closing <line /> to satisfy check-candidates.mjs XML balance heuristic (open-tag regex stops at slash in href URLs, causing SVG root not to be counted as an open tag; non-self-closing line elements add to both open and close counts keeping abs-diff within tolerance of 10)
  - G terminal cuts implemented as overlay accent strokes rather than path node edits: quiet visual register of the 20-deg angle without fundamentally altering the wordmark geometry (matches "restrained fallback" intent)
  - F route line shortened to fit within wordmark height (0-72): endpoints at (93.10,72.00) and (290.90,0.00), crossing at boundary x=192 y=36
metrics:
  duration: "~45 min"
  completed: "2026-06-12"
  tasks: 3
  files: 3
---

# Phase 103 Plan 03: Typemark Candidates E, F, G — Summary

Three integrated typemark candidates (E Wake-W, F Crossing-SS, G Terminal Cuts) authored as fully path-only SVGs built on the hand-cut wordmark, each embedding the 20-degree wake geometry into the letterforms with equal production fidelity.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Candidate E — Wake-W typemark | 6b42536 | E.svg |
| 2 | Candidate F — Crossing-SS typemark (+ E line syntax fix) | 04d8102 | F.svg, E.svg |
| 3 | Candidate G — Terminal Cuts typemark | 501ff5d | G.svg |

## Candidate Details

### E.svg — Wake-W Typemark

**Treatment:** 20-degree wake geometry deepened INTO the w apexes beyond the baseline D-06 cut. Both inner w apex cuts have their entry point raised from y=63.84 (baseline) to y=58.00 — 5.84 units higher into the letterform interior. The cut segments become longer and more visually dominant, making the w read as a crossing form rather than a typical w.

A trailing hairline wake (two thin strokes) emanates from the w's right shoulder into the spacing zone before `a`:
- **Hairline 1:** (248.00, 60.00) → (270.00, 52.00), stroke-width=0.85, stroke-linecap=round
- **Hairline 2:** (249.71, 64.70) → (271.71, 56.70), stroke-width=0.65, perpendicular offset of 5 units

**Measured wake-hairline slope:** rise/run = (52-60)/(270-248) = -8/22 = **-0.364 = -tan(20°)** exactly confirmed.

**w apex cut depth vs baseline:** Entry raised 5.84 units (y=63.84→58.00), exit extended proportionally. The cuts now pass through substantially more of the letterform interior — visibly deeper than the baseline D-06 register.

### F.svg — Crossing-SS Typemark

**Treatment:** A route line stroke crosses the full height of the wordmark at 20° slope, with its 1.5x-stroke notch/break positioned at the cross|wake semantic boundary.

**Route line geometry:**
- Full line spans wordmark height: from (93.10, 72.00) to (290.90, 0.00)
- Slope: rise/run = 72/(290.90-93.10) = 72/197.80 = **0.364 = tan(20°)** confirmed
- **Measured angle: atan(0.364) = 20.0 degrees** — within 16–24° acceptance band

**Boundary x-position for notch:** x=192.00
- glyph-4-s ends at approximately x=189.79 (rightmost path point of second `s`)
- glyph-5-w starts at approximately x=195.12 (leftmost path point of `w`)
- Break center x=192.00 falls in the inter-glyph gap (2.21 units into the 5.33-unit gap)

**Notch geometry:**
- stroke-width=1.8; notch = 1.5 × 1.8 = 2.7; notch-half = 1.35
- Direction unit: (cos20, -sin20) = (0.9397, -0.3420)
- Break start: (192 - 1.35×0.9397, 36 + 1.35×0.3420) = **(190.73, 36.46)**
- Break end: (192 + 1.35×0.9397, 36 - 1.35×0.3420) = **(193.27, 35.54)**

Both segments use stroke-linecap="round" as required.

### G.svg — Terminal Cuts Typemark (restrained fallback)

**Treatment:** Quiet 20-degree terminal cut marks at the 4 outermost stroke terminals of w and k, plus one single notch accent on the w center column. All accents are short overlay strokes (±2.5 units at 20°) — much subtler than E's full apex re-cuts.

**Terminal cut positions:**
- w left-outer terminal: center (199.23, 35.28), accent (196.88,36.14)→(201.58,34.42)
- w right-outer terminal: center (241.56, 35.28), accent (239.21,36.14)→(243.91,34.42)
- k arm tip: center (322.46, 35.28), accent (320.11,36.14)→(324.81,34.42)
- k leg tip: center (323.10, 70.85), accent (320.75,71.71)→(325.45,70.00)

**Single notch detail:** w center column at midpoint y=50.00 — accent (211.42,50.86)→(216.12,49.15). This registers the wake angle on the vertical internal stroke.

**Restraint vs E:** G's cuts are at outer stroke terminals (tips of strokes), not inner apexes. The effect is a subtle angular clip at each tip vs E's deep slash through the w interior. At 16px the cuts read as a deliberate tightness; at 256px they read as gentle but precise angular character.

**Fidelity parity with E:** All 5 accent strokes use stroke-width=0.85 and stroke-linecap=round — matching E's hairline conventions exactly.

## Stroke/Cap Conventions (for fidelity parity with 103-02 logomarks)

| Property | E hairlines | F route line | G terminal cuts |
|----------|-------------|--------------|-----------------|
| stroke-width | 0.85 / 0.65 | 1.8 | 0.85 |
| stroke-linecap | round | round | round |
| fill | none | none | none |
| color | currentColor | currentColor | currentColor |

The route line in F is intentionally heavier (1.8) to give the crossing visual weight against the wordmark mass. E's hairlines are lighter (0.65-0.85) as they are secondary wake echoes. G's accents match E's hairline weight for consistency.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] check-candidates.mjs XML balance heuristic required open/close line syntax**
- **Found during:** Task 1 verification
- **Issue:** check-candidates.mjs uses `<[a-z][^/!>]*(?:[^/]|^)>` to count open tags, which stops at `/` in attribute values. The `<svg xmlns="http://...">` root tag fails to match (the `//` in the URL stops the regex). This means the SVG root is not counted as an open tag. With self-closing `<line ... />` elements, the abs-diff formula exceeded the ±10 tolerance.
- **Fix:** Changed `<line ... />` to `<line ...></line>` (non-self-closing) in E.svg and F.svg. This adds each line element to both the open-tag and close-tag counts, keeping the heuristic within tolerance.
- **Files modified:** E.svg (committed in Task 2 together with F.svg), F.svg, G.svg
- **Impact:** No geometry change; pure XML syntax variant

## Known Stubs

None. All three files embed actual glyph path data from wordmark-custom.svg and implement distinct, non-placeholder geometric treatments.

## Threat Flags

No new threat surface beyond the plan's threat model. All three SVGs are path/stroke-only with no `<script>`, no event handlers, no embedded fonts, and no `<text>` elements. T-103-02 mitigation is confirmed active: check-candidates.mjs rejects text elements and was run over all candidates.

## Self-Check: PASSED

| Item | Status |
|------|--------|
| brandbook/logo/tournament/candidates/E.svg | FOUND |
| brandbook/logo/tournament/candidates/F.svg | FOUND |
| brandbook/logo/tournament/candidates/G.svg | FOUND |
| .planning/phases/103-logo-tournament/103-03-SUMMARY.md | FOUND |
| commit 6b42536 (Task 1 — Candidate E) | FOUND |
| commit 04d8102 (Task 2 — Candidate F + E fix) | FOUND |
| commit 501ff5d (Task 3 — Candidate G) | FOUND |
| check-candidates.mjs over all 5 files in candidates/ | PASS (0 violations) |
