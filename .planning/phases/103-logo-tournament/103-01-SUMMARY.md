---
phase: 103-logo-tournament
plan: "01"
subsystem: brandbook/tools
tags: [logo, wordmark, opentype, svg, toolchain]
dependency_graph:
  requires: [102-brand-audit-token-foundation]
  provides: [wordmark-toolchain, wordmark-custom.svg]
  affects: [103-02, 103-03, 103-04]
tech_stack:
  added:
    - opentype.js 2.0.0 (npm, isolated under brandbook/tools/)
  patterns:
    - Node ESM zero-dep-first script (gen-wordmark.mjs)
    - node --test built-in test runner (gen-wordmark.test.mjs)
    - Pinned-commit font download with integrity assertion (fetch-fonts.sh)
    - opentype.parse(buffer.buffer) — replaces deprecated opentype.load()
    - flipY:false + variation.set() workarounds for opentype.js 2.0.0 bugs
    - Surgical 2-4 node path replacement for D-06 w/k cuts (no boolean ops)
key_files:
  created:
    - brandbook/tools/package.json
    - brandbook/tools/package-lock.json
    - brandbook/tools/fetch-fonts.sh
    - brandbook/tools/gen-wordmark.mjs
    - brandbook/tools/gen-wordmark.test.mjs
    - brandbook/tools/check-candidates.mjs
    - brandbook/logo/tournament/candidates/wordmark-base.svg
    - brandbook/logo/tournament/candidates/wordmark-custom.svg
    - brandbook/logo/tournament/candidates/.gitkeep
  modified: []
decisions:
  - opentype.parse(buffer.buffer) required — opentype.load() deprecated in 2.0.0 returns undefined
  - Surgical 2-node replacement at w apexes; single-to-2-node replacement at k arm/leg vertex
  - notch_half_x=4 for w (8-unit cut width), notch_half_x=3 for k (6-unit cut width) at 20-deg slope
  - wordmark-base.svg and wordmark-custom.svg committed as two separate provenance commits (D-09)
metrics:
  duration_minutes: 9
  completed_date: "2026-06-12"
  tasks_completed: 3
  files_created: 9
  files_modified: 0
---

# Phase 103 Plan 01: Wordmark Toolchain & Hand-Cut Candidates Summary

Wordmark generation toolchain built and the canonical hand-cut Space Grotesk SemiBold wordmark committed with mandatory 20-degree wake-angle cuts on w and k glyphs.

## What Was Built

### Task 1 — Toolchain scaffold (commit `32a958b`)
- `brandbook/tools/package.json`: isolated `opentype.js` at exact version `2.0.0` (not caret), `"type":"module"`, `"private":true`
- `brandbook/tools/package-lock.json`: committed lockfile for provenance (T-103-SC mitigation)
- `brandbook/tools/fetch-fonts.sh`: downloads `SpaceGrotesk[wght].ttf` from google/fonts pinned commit `877f8918ee661764418e085766dc0b073260a3ef`; asserts exactly 136676 bytes on download (T-103-01 mitigation); idempotent
- `brandbook/logo/tournament/candidates/.gitkeep`: candidates directory tracked in git

### Task 2 — gen-wordmark.mjs + TDD tests (commits `5d205b9`, `91de0c1`, `625c932`)

**TDD RED** (`5d205b9`): 5 failing tests for the 5 behaviors before implementation.

**GREEN** (`91de0c1`): `generateWordmark(ttfPath, options)` implemented with all opentype.js 2.0.0 workarounds applied. All 5 tests pass.

**Provenance commit** (`625c932`): `wordmark-base.svg` committed separately — 9 paths, fill-rule=evenodd, currentColor, before any cuts.

**Glyph topology observed** (Space Grotesk SemiBold, 72px, wght=600):
- `glyph-5-w`: `M214.42 70.85 ... L207.14 65.30 L208.37 65.30 ... L232.42 65.30 L233.64 65.30 ...`
  - Two inner valley apexes at y≈65.30, x≈207-208 and x≈232-234 (narrow 1.2-unit gaps at each apex)
  - Structure: 4 vertical strokes alternating up/down; apexes are the bottom turning points of V-shapes
- `glyph-7-k`: `... L304.20 48.74 L317.02 35.28 L327.89 35.28 L310.68 52.49 L328.46 70.85 ...`
  - Single inner vertex at (310.68, 52.49) where arm (upper diagonal) meets leg (lower diagonal)

### Task 3 — D-06 w/k cuts + check-candidates.mjs (commits `1e77c16`, `27358b1`)

**wordmark-custom.svg** (`1e77c16`): Surgical node replacements applied to glyph-5-w and glyph-7-k:

**`glyph-5-w` cut technique:**
- First apex (y≈65.30, center_x≈207.76): replaced `L207.14 65.30 L208.37 65.30` with `L203.75 63.84 L211.75 66.76`
- Second apex (y≈65.30, center_x≈233.03): replaced `L232.42 65.30 L233.64 65.30` with `L229.03 63.84 L237.03 66.76`
- Cut width: 8 units (notch_half_x=4), angle: 20° (dy = 4 × tan20° = 1.46)
- Creates a visible angled truncation at each inner valley bottom — not typesettable in stock Space Grotesk

**`glyph-7-k` cut technique:**
- Single inner vertex (310.68, 52.49): replaced `L310.68 52.49` with `L307.68 51.40 L313.68 53.58`
- Notch width: 6 units (notch_half_x=3), same 20° slope (dy = 3 × tan20° = 1.09)
- Creates an angular notch at the arm/leg intersection

All other paths (C, r, o, s, s, a, e) unchanged. Cut geometry matches 20° wake slope (D-06/D-11).

**check-candidates.mjs** (`27358b1`): Zero-dep ESM structural validator checks all `candidates/*.svg` for:
- (a) Well-formed XML (tag balance heuristic)
- (b) No `<text` elements (D-04)
- (c) No full-bleed `<rect` spanning the viewBox (D-05/LOGO-03)
- (d) `viewBox` declared on root `<svg>`
Self-tested: correctly detects `<text>` + full-bleed-rect violations; both current candidates pass.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `opentype.load()` deprecated in 2.0.0 returns `undefined`**
- **Found during:** Task 2 (GREEN phase — tests fail with `Cannot read properties of undefined (reading 'variation')`)
- **Issue:** `opentype.load(path)` is deprecated in opentype.js 2.0.0 and returns `undefined` instead of a Font object. The research documented `opentype.load()` but this bug was not listed in the pitfalls (only the flipY and wght bugs were).
- **Fix:** Use `opentype.parse(readFileSync(ttfPath).buffer)` — reads the TTF into a Node Buffer and passes the underlying ArrayBuffer to `opentype.parse()`. Documented as workaround #0 in gen-wordmark.mjs header.
- **Files modified:** `brandbook/tools/gen-wordmark.mjs`
- **Commit:** `91de0c1`

**2. [Rule 2 - Missing critical] SVG comment `<!-- ... no <text> ... -->` false-positive in test**
- **Found during:** Task 2 (GREEN phase — Test 5 "no <text elements" fails)
- **Issue:** The SVG header comment included the literal string `<text>` in `<!-- D-04: path-only SVG — no <text>, ... -->`, causing the test's `svg.includes('<text')` check to trigger on the comment text.
- **Fix:** Changed comment to `<!-- D-04: path-only SVG (no text/rect/font elements) -->` to avoid the false positive.
- **Files modified:** `brandbook/tools/gen-wordmark.mjs` (template literal inside)
- **Commit:** `91de0c1`

## Wordmark Not Typesettable Confirmation

The wordmark-custom.svg contains node sequences at the w inner apexes and k arm/leg vertex that have no corresponding glyph in Space Grotesk or any other commercially available version of the typeface. Specifically:
- The `w` apex nodes form a diagonal cut line segment that crosses the V-shape at 20° — this geometry cannot be produced by any weight/variation setting on the stock variable font
- The `k` arm/leg junction is interrupted by a 6-unit angular notch at 20° slope — the stock `k` has a single sharp vertex at this point

Any wordmark render that matches wordmark-custom.svg requires a hand-edited path or a custom font binary. The tournament wordmark is exclusively generated + edited.

## Self-Check

Checking created files exist:
- brandbook/tools/package.json: FOUND
- brandbook/tools/package-lock.json: FOUND
- brandbook/tools/fetch-fonts.sh: FOUND
- brandbook/tools/gen-wordmark.mjs: FOUND
- brandbook/tools/gen-wordmark.test.mjs: FOUND
- brandbook/tools/check-candidates.mjs: FOUND
- brandbook/logo/tournament/candidates/wordmark-base.svg: FOUND
- brandbook/logo/tournament/candidates/wordmark-custom.svg: FOUND

Checking commits exist:
- 32a958b (toolchain scaffold): FOUND
- 5d205b9 (TDD RED): FOUND
- 91de0c1 (GREEN gen-wordmark): FOUND
- 625c932 (wordmark-base.svg provenance): FOUND
- 1e77c16 (wordmark-custom.svg w/k cuts): FOUND
- 27358b1 (check-candidates.mjs): FOUND

## Self-Check: PASSED
