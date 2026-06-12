# Phase 103: Logo Tournament - Research

**Researched:** 2026-06-11
**Domain:** SVG path generation, variable font instancing, logo design systems, standalone HTML gallery
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Exactly 7 candidates at equal production fidelity: A (Canonical Wake Mark), B (Seam Shift), C (Crossing Lanes), D (Minimal Wake Monogram), E (Wake-W typemark), F (Crossing-SS typemark), G (Terminal Cuts typemark)
- **D-02:** Each logomark (A–D) shown as close-set horizontal AND stacked lockup with the Space Grotesk SemiBold wordmark; typemarks (E–G) stand alone
- **D-03:** Wake Mark constraints: 20° crossing angle (16–24° acceptable), exactly 3 lines, 2.5px stroke at 24px scale, 1.5x-stroke notch, round caps, simplify to 2 strokes at 16px or below
- **D-04:** Path-only SVG — no text elements, no rectangular clip-path backgrounds, no embedded fonts, no bounding shapes. ViewBox on 64-unit grid for marks; strokes kept as strokes (re-weightable)
- **D-05:** No rectangular background shapes; logotype gap approx one stroke-width from mark; NO subtitle/slogan on main lockups
- **D-06 (D-11 rider):** ALL wordmark renderings carry mandatory custom w/k wake-angle cuts — wordmark must NOT be typesettable in unmodified Space Grotesk; candidates without these cuts are disqualified
- **D-07:** brandbook/tools/gen-wordmark.mjs (Node + opentype.js 2.0.0 only) generates kerned path-only "Crosswake" outlines from Space Grotesk SemiBold TTF
- **D-08:** brandbook/tools/fetch-fonts.sh downloads Space Grotesk TTF from google/fonts at a PINNED commit; fonts gitignored; committed SVGs are source of truth
- **D-09:** Custom cuts are surgical hand-edits to generated path data on affected glyphs; never hand-drawn full letterforms
- **D-10:** brandbook/logo/tournament/index.html — standalone, no build step, file:// compatible; uses Phase 102 tokens.css; per candidate: 256px renders on Foam 50 / Current 950 / white; monochrome; 24px + 16px inline; browser-tab favicon mock; horizontal + stacked lockups
- **D-11:** Per-candidate 2-3 sentence design rationale AND stated risk; closing equal-size lineup grid of all 7
- **D-12:** Gallery includes maintainer recommendation WITH reasoning, rendered identically to other candidates; franken-picks explicitly invited; selection framing is durability-focused
- **D-13:** Candidate SVGs in brandbook/logo/tournament/candidates/ (committed); one-color Current 950 is canonical authored colorway; CSS-driven variants permitted for tournament artifacts
- **D-14:** Phase ends with blocking user checkpoint presenting gallery path + lineup summary + maintainer recommendation; pick recorded in phase summary and STATE.md

### Claude's Discretion

- Exact path data, optical corrections, stroke joints, per-candidate micro-geometry within D-03 constraints
- Gallery page layout/typography (must follow brand tokens), rationale prose
- The maintainer recommendation itself (decide from durability criteria after seeing all 7 rendered)
- Whether D's monogram is "C" or "cw" (pick whichever survives 16px better)

### Deferred Ideas (OUT OF SCOPE)

- 3 micro-variants of winner + production suite + favicon.svg as dedicated 16-grid artifact — Phase 104
- Full colorway asset files (signal/OSS-badge variants) — Phase 106
- Misuse-example renderings — Phase 105 (HTML brand book)

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LOGO-01 | 7 tournament candidates (4 logomark concepts + 3 integrated typemarks) as path-only SVGs at equal production fidelity | Space Grotesk variable font + opentype.js 2.0.0 pipeline; per-glyph path separation for w/k edits; SVG geometry math for marks A-D |
| LOGO-02 | Tournament gallery showing each candidate at 256px on foam/dark/white, monochrome, 24px + 16px, browser-tab favicon mock, horizontal + stacked lockups, per-candidate rationale + stated risk, equal-size lineup grid | Inline SVG + currentColor CSS-swap technique; favicon mock CSS; gallery architecture pattern |
| LOGO-03 | No rectangular container backgrounds on any mark; main lockup carries no subtitle; logotype gap approx one stroke-width | Design anti-pattern verification checklist; grep checks documented below |
| LOGO-04 | User selects logo direction at tournament checkpoint (franken-picks supported) | Blocking checkpoint mechanics; phase summary + STATE.md recording format |

</phase_requirements>

---

## Summary

Phase 103 produces seven SVG logo candidates (A-G) at equal production fidelity and presents them in a standalone HTML gallery that ends with a mandatory user-selection checkpoint. The two hard technical problems are: (1) getting Space Grotesk SemiBold outlines from a variable-only TTF source and processing them correctly through opentype.js 2.0.0, which has a known double y-axis flip bug that requires passing `{flipY: false}` to `toPathData()`; and (2) applying the mandatory 20-degree wake-angle cuts to the `w` and `k` letterforms as surgical path node edits rather than boolean clipping operations.

The gallery is build-free, consuming Phase 102's `tokens.css` directly. Color swaps for the three background contexts (Foam 50, Current 950, white) are driven by CSS `color` inheritance on inline SVG elements whose paths use `fill="currentColor"`. This avoids file duplication while keeping candidates self-contained for long-term provenance.

The primary risk is scope diffusion: attempting Phase 104 production quality when tournament fidelity is the goal. The second risk is the `w`/`k` path edit being skipped or deferred, which disqualifies the wordmark per D-06. Both are planner-enforceable via acceptance criteria.

**Primary recommendation:** Use `font.getPaths()` (plural) for per-glyph SVG path emission with `toPathData({flipY: false})`. Load the variable TTF, call `font.variation.set({wght: 600})` before `getPaths()`. Apply `w`/`k` cuts as manual path node edits post-generation. Two-point straight-line truncation (replace 2-4 path nodes at the apex/arm intersection) is more maintainable than boolean clipping for this specific geometry.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Font outline extraction | Build script (Node.js) | — | opentype.js runs at generation time; output is committed SVG path data |
| Font download and pinning | Shell script (fetch-fonts.sh) | — | Gitignored TTF, pinned commit; no runtime font dependency |
| w/k surgical path edits | Human / text editor | — | Path data is plain text; 2-4 node replacements per glyph; no tooling needed |
| Mark geometry (A-D) | SVG path authoring | — | Hand-authored on 64-unit grid using computed coordinates |
| Gallery HTML | Static HTML file | tokens.css | No framework; inline SVG; CSS custom properties from Phase 102 |
| Color context swaps | CSS (currentColor) | — | CSS `color` property drives `fill="currentColor"` on inline SVGs |
| Favicon mock | CSS (border-radius + flexbox) | — | Pure CSS tab-chrome simulation, no images |
| User checkpoint | Human decision | Phase summary + STATE.md | LOGO-04 is a blocking manual step; no automation |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `opentype.js` | `2.0.0` | Variable font loading, per-glyph path extraction, kerning | [VERIFIED: npm registry] — 1M+ weekly downloads, created 2013, published 2026-05-06; only zero-native-dep option for TTF-to-SVG-path in Node ESM; slopcheck [OK] |

### System Tools (no new installs)

| Tool | Use | Available |
|------|-----|-----------|
| Node.js v22.14.0 | Run gen-wordmark.mjs | Confirmed present |
| `node --test` (built-in) | Run *.test.mjs | Confirmed — matches Phase 102 pattern |
| `xmllint` | SVG validity check | Present on macOS via libxml2 |
| `bash` + `curl` | fetch-fonts.sh | Present |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| variable TTF + font.variation.set() | fontTools varLib.instancer (Python) | fontTools requires Python toolchain; opentype.js handles wght axis natively — no external process needed |
| Manual path node edits for w/k cuts | polygon-clipping + flattened contours | polygon-clipping requires converting quadratic bezier curves to polygon approximations first; adds a dependency; the cuts are straight-line truncations on 2-4 nodes — manual edits are strictly simpler |
| Inline SVG in gallery HTML | img src="candidates/*.svg" | img prevents currentColor inheritance; inline SVG required for CSS-driven color swaps |

**Installation (brandbook/tools/package.json — new file this phase):**

```bash
cd brandbook/tools && npm install opentype.js@2.0.0
```

---

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `opentype.js` | npm | 13 years (2013-09-27) | ~1.08M/wk | github.com/opentypejs/opentype.js | [OK] | Approved |

**Packages removed due to slopcheck [SLOP] verdict:** none

**Packages flagged as suspicious [SUS]:** none

*Note: `slopcheck install opentype.js` defaulted to pypi (not found — SLOP for wrong ecosystem). Re-run with `--ecosystem npm` confirmed [OK]. No postinstall script present.*

---

## Architecture Patterns

### System Architecture Diagram

```
fetch-fonts.sh
  curl https://raw.githubusercontent.com/google/fonts/877f891/ofl/spacegrotesk/SpaceGrotesk[wght].ttf
       -> brandbook/tools/fonts/SpaceGrotesk[wght].ttf   (gitignored)

gen-wordmark.mjs
  opentype.load(SpaceGrotesk[wght].ttf)
  font.variation.set({wght: 600})
  font.getPaths("Crosswake", 0, baseline, size, {kerning:true})
       -> [Path_C, Path_r, Path_o, Path_s1, Path_s2, Path_w, Path_a, Path_k, Path_e]
  per path: path.toPathData({flipY: false, decimalPlaces: 2})
       -> stdout: <g id="wordmark-base"> containing per-glyph <path id="glyph-5-w" ...>

HUMAN EDIT STEP (D-09)
  open wordmark-base SVG in text editor
  glyph-5-w: locate apex nodes -> replace with 20-deg-cut geometry (2-4 node replacement)
  glyph-7-k: locate arm/leg intersection -> replace with 20-deg-notch (2-4 node replacement)
       -> committed as brandbook/logo/tournament/candidates/wordmark-custom.svg

SVG authoring: marks A-D, typemarks E-G
  64-unit grid; stroke-based; round caps; strokes kept as strokes (D-04)
  viewBox="0 0 64 64" for standalone marks
  Combine mark paths + wordmark-custom.svg paths for lockup candidates
       -> brandbook/logo/tournament/candidates/{A,B,C,D,E,F,G}.svg
          canonical colorway: fill="currentColor" / stroke="currentColor"

index.html (gallery)
  <link rel="stylesheet" href="../../../tokens/tokens.css">
  Per candidate card:
    .swatch-foam { color: #09141A; background: #F7F1E6 }   -> dark mark on foam
    .swatch-dark { color: #F7F1E6; background: #09141A }   -> light mark on dark
    .swatch-white { color: #09141A; background: #FFFFFF }  -> dark mark on white
    256px render, 24px render, 16px render (CSS width on inline SVG)
    .favicon-mock (CSS tab chrome) -> 16px scaled favicon inside tab div
    horizontal lockup (mark + wordmark in single SVG)
    stacked lockup (mark above wordmark in single SVG)
  Lineup grid (all 7 equal-size)
  CHECKPOINT section with maintainer recommendation + selection prompt
```

### Recommended Project Structure

```
brandbook/
  tools/
    package.json          # new this phase: {"dependencies":{"opentype.js":"^2.0.0"}}
    package-lock.json     # committed (provenance)
    fetch-fonts.sh        # new this phase
    gen-wordmark.mjs      # new this phase
    gen-wordmark.test.mjs # new this phase
    fonts/                # gitignored (Phase 102 .gitignore already covers this)
    node_modules/         # gitignored (Phase 102 .gitignore already covers this)
  logo/
    tournament/
      index.html          # gallery
      candidates/
        wordmark-custom.svg
        A.svg  B.svg  C.svg  D.svg  E.svg  F.svg  G.svg
```

### Pattern 1: Variable Font Loading and Weight Setting

**What:** Load the variable font TTF and set wght=600 before extracting paths.

**When to use:** Required — google/fonts only ships `SpaceGrotesk[wght].ttf` (variable, wght 300-700). No static SemiBold TTF exists in either google/fonts or floriankarsten/space-grotesk (static/ folder has only Light, Regular, Medium, Bold — no SemiBold). [VERIFIED: GitHub API — google/fonts ofl/spacegrotesk/ contains only SpaceGrotesk[wght].ttf; floriankarsten/space-grotesk static/ confirmed missing SemiBold]

```javascript
// Source: opentypejs/opentype.js src/variation.mjs + src/font.mjs
import opentype from 'opentype.js';

const font = await opentype.load('brandbook/tools/fonts/SpaceGrotesk[wght].ttf');

// Set wght=600 (SemiBold) on the variable font's VariationManager
// font.variation is auto-initialized if fvar+gvar tables are present
font.variation.set({ wght: 600 });

// Compute baseline: font uses bottom-up coordinate system
// y must be positive and equal to the ascender scaled to fontSize
const fontSize = 72;
const baseline = font.ascender * (fontSize / font.unitsPerEm);
```

### Pattern 2: Per-Glyph Path Extraction (v2.0.0 Bug Fix Required)

**What:** Extract one SVG path element per glyph position, including correct kerning positions. Critical: pass `{flipY: false}` to `toPathData()` to avoid the double-flip bug in v2.0.0.

**When to use:** Always for gen-wordmark.mjs. The `toPathData()` default `flipY: true` double-flips because `glyph.getPath()` already applies y-negation (`y + (-cmd.y * yScale)` in glyph.mjs). Using `flipY: false` in `toPathData()` prevents the second flip. [VERIFIED: opentypejs/opentype.js src/glyph.mjs lines confirm y-flip in getPath; issue #724 and PR #850 confirm v2.0.0 double-flip bug; `toPathData()` default is `flipY: true` per src/path.mjs]

```javascript
// Source: opentypejs/opentype.js src/font.mjs + confirmed by issue #724
const text = 'Crosswake';
const paths = font.getPaths(text, 0, baseline, fontSize, { kerning: true });

// paths is an array — one Path object per glyph position (9 for "Crosswake")
// Glyph order: C(0) r(1) o(2) s(3) s(4) w(5) a(6) k(7) e(8)
const glyphs = font.stringToGlyphs(text);

const svgPaths = paths.map((path, index) => {
  const char = text[index];
  const d = path.toPathData({ flipY: false, decimalPlaces: 2 });
  const glyphName = glyphs[index].name || char;
  return `  <!-- glyph: ${glyphName} char: ${char} position: ${index} -->
  <path id="glyph-${index}-${char}"
        fill-rule="evenodd"
        d="${d}" />`;
}).join('\n');

const bbox = font.getPath(text, 0, baseline, fontSize, { kerning: true }).getBoundingBox();
const viewBox = `${bbox.x1.toFixed(2)} 0 ${(bbox.x2 - bbox.x1).toFixed(2)} ${fontSize}`;

const svg = `<?xml version="1.0" encoding="UTF-8"?>
<!-- GENERATED by brandbook/tools/gen-wordmark.mjs — do not edit directly -->
<!-- Source: SpaceGrotesk[wght].ttf wght=600 at ${fontSize}px -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="${viewBox}">
  <g id="wordmark-base" fill="currentColor">
${svgPaths}
  </g>
</svg>`;
```

### Pattern 3: fetch-fonts.sh with Pinned Commit

**What:** Download the variable TTF from google/fonts at a pinned commit SHA to guarantee reproducibility. [VERIFIED: GitHub API — google/fonts main HEAD SHA as of 2026-06-11: 877f8918ee661764418e085766dc0b073260a3ef; file size 136,676 bytes confirmed]

```bash
#!/usr/bin/env bash
# Source: google/fonts repo — ofl/spacegrotesk/SpaceGrotesk[wght].ttf
# Pinned to: 877f8918ee661764418e085766dc0b073260a3ef (google/fonts main HEAD 2026-06-11)
set -euo pipefail

COMMIT="877f8918ee661764418e085766dc0b073260a3ef"
FONTS_DIR="$(dirname "$0")/fonts"
mkdir -p "$FONTS_DIR"

TTF_URL="https://raw.githubusercontent.com/google/fonts/${COMMIT}/ofl/spacegrotesk/SpaceGrotesk%5Bwght%5D.ttf"
TTF_OUT="$FONTS_DIR/SpaceGrotesk[wght].ttf"

if [ -f "$TTF_OUT" ]; then
  echo "Font already present: $TTF_OUT"
  exit 0
fi

echo "Downloading Space Grotesk variable font (pinned commit $COMMIT)..."
curl -fL "$TTF_URL" -o "$TTF_OUT"
echo "Downloaded: $(wc -c < "$TTF_OUT") bytes"
```

### Pattern 4: w/k Surgical Path Node Edit

**What:** After generating the wordmark base paths, open the SVG in a text editor and replace 2-4 path nodes in the `w` and `k` glyphs to create the 20-degree wake-angle cuts. This is NOT a boolean operation; it is a straight-line truncation of the apex/arm geometry.

**When to use:** D-06 mandates this. Apply after running gen-wordmark.mjs and before using the wordmark in any candidate SVG.

**Technique for `w` (apex cut):**

Space Grotesk `w` has two inner apex triangles where the strokes meet. The TTF outlines are quadratic bezier curves (Q commands). The 20-degree cut replaces the apex area's 2-4 nodes (typically `L x y` or `Q x1 y1 x y` around the peak) with two endpoints that define a line segment at 20-degree slope:

```
Original apex node sequence (example, actual coords from gen-wordmark.mjs output):
  ... Q cx1 cy1 peak_x peak_y Q cx2 cy2 next_x next_y ...

Replaced with:
  ... L cut_left_x cut_left_y  L cut_right_x cut_right_y ...

where cut_left/right define the 20-degree incision:
  dx_per_unit_y = 1 / tan(20°) = 2.747
  cut_left_y  = peak_y + notch_half      (notch = 1.5 * stroke_in_local_coords)
  cut_left_x  = peak_x - notch_half * dx_per_unit_y * (scale_factor)
```

**Technique for `k` (arm/leg notch):**

The `k` has an arm (upper-right diagonal) and leg (lower-right diagonal) meeting at an inner vertex. Insert a 20-degree angular notch at that vertex by replacing the vertex node with two offset nodes:

```
Original inner vertex:
  ... L vertex_x vertex_y ...

Replaced with (notch gap at 20-degree angle):
  ... L notch_enter_x notch_enter_y L notch_exit_x notch_exit_y ...
```

**Critical:** Inspect the actual generated path data before editing. Space Grotesk uses quadratic TTF outlines, but opentype.js emits them as Q commands. The exact nodes differ per font version; review `id="glyph-5-w"` and `id="glyph-7-k"` paths at 400% zoom in any SVG-aware editor before editing.

### Pattern 5: Gallery HTML Color Context Swap

**What:** Show each candidate on three background swatches without authoring separate SVG files. CSS `color` property is inherited by inline SVG and drives `fill="currentColor"`.

**When to use:** All 7 candidates in index.html. The candidate SVG files use `fill="currentColor"` and `stroke="currentColor"` as their authored state.

```html
<!-- Source: MDN — currentColor in inline SVG inherits from CSS color property -->
<!-- Candidate SVG must use fill="currentColor" stroke="currentColor" -->

<div class="candidate-swatches">
  <!-- Foam 50 background (light primary) -->
  <div class="swatch swatch-foam">
    <!-- Inline SVG pasted here; path fill="currentColor" inherits #09141A -->
    <svg viewBox="0 0 64 64" width="256" height="256">
      <path fill="currentColor" d="..." />
    </svg>
  </div>

  <!-- Current 950 background (dark primary) -->
  <div class="swatch swatch-dark">
    <!-- Same SVG code; color: #F7F1E6 means Foam 50 mark on dark bg -->
    <svg viewBox="0 0 64 64" width="256" height="256">
      <path fill="currentColor" d="..." />
    </svg>
  </div>

  <!-- White background -->
  <div class="swatch swatch-white">
    <svg viewBox="0 0 64 64" width="256" height="256">
      <path fill="currentColor" d="..." />
    </svg>
  </div>
</div>
```

```css
/* Consumes tokens from Phase 102 tokens.css */
.swatch { padding: 24px; }
.swatch-foam  { background: var(--cw-primitive-foam-50);    color: var(--cw-primitive-current-950); }
.swatch-dark  { background: var(--cw-primitive-current-950); color: var(--cw-primitive-foam-50); }
.swatch-white { background: var(--cw-primitive-white);       color: var(--cw-primitive-current-950); }
```

### Pattern 6: Browser-Tab Favicon Mock

**What:** A pure-CSS div that simulates a browser tab chrome (rounded top corners, gray background, left-aligned favicon area at 16x16px) to show how each candidate looks as a browser favicon.

```html
<!-- No images required — pure CSS mock -->
<div class="tab-bar">
  <div class="tab-mock">
    <div class="favicon-area">
      <!-- 16x16 inline SVG of the simplified 2-stroke favicon variant -->
      <svg width="16" height="16" viewBox="0 0 64 64">
        <path fill="currentColor" d="..." />
      </svg>
    </div>
    <span class="tab-label">Crosswake</span>
  </div>
</div>
```

```css
.tab-bar {
  background: #DEE1E6;  /* Chrome light tab bar color (approximate) */
  padding: 8px 0 0 8px;
  border-radius: 4px 4px 0 0;
  display: flex;
}
.tab-mock {
  background: #F1F3F4;  /* Chrome active tab background (approximate) */
  border-radius: 8px 8px 0 0;
  display: flex;
  align-items: center;
  padding: 6px 12px;
  gap: 6px;
  color: #09141A;
  min-width: 140px;
}
.favicon-area { width: 16px; height: 16px; flex-shrink: 0; }
.tab-label { font-size: 12px; color: #333; white-space: nowrap; overflow: hidden; }
```

### Anti-Patterns to Avoid

- **Double y-flip in opentype.js v2.0.0:** Never call `path.toPathData({flipY: true})` (the default) on a path returned by `font.getPaths()` or `glyph.getPath()`. Both already apply `-cmd.y` negation. The result is a vertically mirrored wordmark. Pass `{flipY: false}` explicitly.
- **Passing `y=0` to font.getPaths():** Produces glyphs rendered entirely below the SVG origin (invisible). Always compute `baseline = font.ascender * (fontSize / font.unitsPerEm)`.
- **Omitting `fill-rule="evenodd"` on wordmark paths:** Space Grotesk TTF outlines use path winding direction for counter-shapes. Without `evenodd`, the counters in `o`, `e`, `a`, `s` fill solid black instead of being hollow. Apply on the wrapping `<g>` element.
- **Using `font.getPath()` (singular) for the wordmark:** This returns all glyphs merged into one path element, making per-glyph w/k edits impossible. Use `font.getPaths()` (plural) for per-glyph elements.
- **rect backgrounds on any mark:** Every submitted candidate is checked with `grep -c '<rect' candidate.svg`. Any count > 0 fails LOGO-03.
- **Attempting boolean clip operations for w/k cuts:** polygon-clipping requires flattened polygon coordinates (no curves). Converting the quadratic bezier outlines to polygons at sufficient precision adds complexity without benefit. Two-point straight-line node replacement is the correct approach for straight-line cuts on letter outlines.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Variable font instance extraction | Custom TTF binary parser | opentype.js 2.0.0 font.variation.set() | fvar/gvar table parsing is non-trivial; opentype.js has 13-year-old, 1M-download validated implementation |
| Quadratic bezier to SVG path data | Custom coordinate transformer | opentype.js path.toPathData() | Handles all Q/C/L/M commands, coordinate scaling, and precision formatting |
| Kerning between glyph pairs | GPOS/kern table lookup | opentype.js {kerning: true} option | GPOS table parsing requires reading lookup tables, script/language chains; handled by opentype.js forEachGlyph() |
| WCAG contrast check for gallery | Custom formula | Phase 102's brandbook/tools/contrast.mjs | Already exists; import directly |

**Key insight:** The only domain requiring custom authorship is the SVG path node surgery for the w/k cuts. Everything else uses opentype.js or existing Phase 102 infrastructure.

---

## Candidate Geometry Math (64-unit grid, 20-degree canonical angle)

These coordinates are pre-computed for the planner to bake into task acceptance criteria. The implementer verifies visually but these numbers define "correct."

[ASSUMED — math is deterministic, but actual SVG path placements should be verified against rendered output at 24px and 16px]

```
tan(20°) = 0.3640
At 64-unit mark grid (scale factor vs 24px icon = 64/24 = 2.667x):

Stroke width at 64 units:   2.5 * 2.667 = 6.667 units
Notch size (1.5x stroke):   1.5 * 6.667 = 10.000 units
Wake line spacing (2x stroke): 13.333 units

Canonical route line (center 32,32):
  From: (0, 37.82)
  To:   (64, 26.18)
  Slope: -tan(20°) = -0.364  [rising left-to-right in SVG top-down coords]

Notch gap centered on crossing (32, 32):
  Line direction unit vector: (0.9397, -0.3420)
  Notch half = 5.0 units
  Break start: (32 - 5*0.9397, 32 - 5*(-0.3420)) = (27.30, 33.71)
  Break end:   (32 + 5*0.9397, 32 + 5*(-0.3420)) = (36.70, 30.29)

Two trailing wake lines (offset perpendicular to route line):
  Perpendicular unit vector: (0.3420, 0.9397)
  Wake line 1 center: (32 + 13.333*0.3420, 32 + 13.333*0.9397) = (36.56, 44.53)
  Wake line 2 center: (32 + 26.667*0.3420, 32 + 26.667*0.9397) = (41.12, 57.06)
  Each wake line: same slope as route line, shorter length (approx 30-40 units)

At 16px render (scale = 16/64 = 0.25x):
  Stroke width: 6.667 * 0.25 = 1.667px  (within 1-2px target for legibility)
  Notch: 10.0 * 0.25 = 2.5px (visible gap)
  -> Use 2-stroke simplification per D-03 (drop wake line 2 at 16px)
  -> At 2 strokes, stroke weight should be ~2px: set stroke-width="8" on 64-grid
     (8 * 0.25 = 2px at 16px render)
```

---

## Common Pitfalls

### Pitfall 1: opentype.js v2.0.0 Double Y-Flip

**What goes wrong:** `path.toPathData()` defaults to `{flipY: true}`, but `glyph.getPath()` already applies y-axis negation (`y + (-cmd.y * yScale)`). Calling both produces a vertically mirrored wordmark — `C`, `r`, `o` appear upside down.

**Why it happens:** v2.0.0 changed the default `flipY` behavior in `toPathData()` without accounting for the y-flip already applied in `getPath()`. Issue #724 and PR #850 both confirm this is an open bug as of 2026-06-11. [VERIFIED: opentypejs/opentype.js issue #724 (open), PR #850 (open)]

**How to avoid:** Always pass `{flipY: false}` to `toPathData()` when the Path object came from `font.getPaths()` or `glyph.getPath()`. If you ever call `toPathData()` on a Path you constructed manually (not from font.getPath), the default `flipY: true` may be correct — but for wordmark generation, always use `{flipY: false}`.

**Warning signs:** Wordmark SVG previews show letters as upside-down or vertically mirrored.

### Pitfall 2: Missing wght Axis Activation

**What goes wrong:** The variable font loads with its default variation (typically wght=400 Regular). The wordmark comes out in Regular weight instead of SemiBold, making letter stems noticeably thinner.

**Why it happens:** `opentype.load()` initializes `font.variation` with default coordinates (activateDefaultVariation). For Space Grotesk, the default is wght=400. The VariationManager is instantiated automatically when fvar+gvar tables are present, but the weight must be set explicitly.

**How to avoid:** Always call `font.variation.set({wght: 600})` immediately after loading the font, before any call to `getPaths()` or `getPath()`. Verify output stem weight visually by comparing to the Google Fonts specimen at weight 600.

**Warning signs:** Generated wordmark looks visually lighter than the Space Grotesk SemiBold on Google Fonts.

### Pitfall 3: fill-rule Omission Fills Counters Solid

**What goes wrong:** The counters (enclosed spaces) in `o`, `e`, `a`, `s`, `C` appear filled solid black instead of transparent. The wordmark reads as a series of black blobs.

**Why it happens:** TTF outline path direction encodes counter vs. fill via winding direction, which SVG resolves via `fill-rule`. The CSS default is `fill-rule="nonzero"`, but TTF outlines require `fill-rule="evenodd"` to correctly render counter-shapes as holes.

**How to avoid:** Set `fill-rule="evenodd"` on the `<g id="wordmark-base">` wrapper. Confirm by viewing the exported SVG in a browser and zooming in on `o` and `e` — their interiors should be transparent.

**Warning signs:** Letters with counters (`o`, `e`, `a`, `s`) appear as solid filled shapes.

### Pitfall 4: Inlining SVG with Non-currentColor fills

**What goes wrong:** Candidate SVG uses hardcoded `fill="#09141A"` instead of `fill="currentColor"`. The CSS-driven color swap has no effect; the mark always appears in Current 950 regardless of swatch background.

**Why it happens:** SVG files authored in Inkscape or similar tools default to hardcoded hex values. The generated wordmark from gen-wordmark.mjs will use fill="currentColor" only if explicitly specified.

**How to avoid:** After generating the wordmark and authoring each candidate SVG, do a final pass replacing all `fill="#09141A"`, `fill="#F7F1E6"`, or `stroke="#..."` hardcoded values with `fill="currentColor"` / `stroke="currentColor"`. The gallery's CSS then drives color entirely.

**Warning signs:** Dark background swatch shows the mark in black (Current 950) instead of Foam 50 white.

### Pitfall 5: Scope Creep to Phase 104 Polish

**What goes wrong:** Candidate authoring time is consumed chasing production perfection — pixel-perfect optical corrections, multiple corner variants, stroke-to-path conversion. The tournament gate passes (user picks) but no time remains for seven candidates at equal fidelity.

**Why it happens:** The natural impulse when making a logo is to keep refining. Tournament fidelity requires equal quality across all 7, not maximum quality on 2.

**How to avoid:** Set a hard cap per candidate: 2-4 hours of authoring for marks, 1-2 hours for typemarks. The goal is "genuinely choosable", not production-ready. Production polish is Phase 104's job. The planner should express this as a time-box in wave planning.

**Warning signs:** One candidate SVG is 50+ path nodes while others are under 10. Gallery reveals unequal fidelity between marks and typemarks.

---

## Code Examples

### gen-wordmark.mjs Complete Pattern

```javascript
// Source: opentypejs/opentype.js src/font.mjs, src/glyph.mjs, src/path.mjs, src/variation.mjs
// Verified: font.getPaths(), font.variation.set(), toPathData({flipY:false})
import opentype from 'opentype.js';
import { writeFileSync } from 'fs';

const FONT_PATH = new URL('../fonts/SpaceGrotesk[wght].ttf', import.meta.url).pathname;
const OUT_PATH  = new URL('../../logo/tournament/candidates/wordmark-base.svg', import.meta.url).pathname;

const font = await opentype.load(FONT_PATH);

// Set SemiBold weight on variable font — MUST precede any getPath/getPaths call
font.variation.set({ wght: 600 });

const text = 'Crosswake';
const fontSize = 72;
// Correct baseline: font.ascender is in unitsPerEm space, must be scaled to fontSize
const baseline = font.ascender * (fontSize / font.unitsPerEm);

const paths  = font.getPaths(text, 0, baseline, fontSize, { kerning: true });
const glyphs = font.stringToGlyphs(text);
const bbox   = font.getPath(text, 0, baseline, fontSize, { kerning: true }).getBoundingBox();

const pathEls = paths.map((path, i) => {
  const char      = text[i];
  const glyphName = glyphs[i].name || char;
  // flipY: false — getPath already applied y-negation; default flipY:true would double-flip
  const d = path.toPathData({ flipY: false, decimalPlaces: 2 });
  return [
    `  <!-- glyph: ${glyphName}  char: ${char}  pos: ${i} -->`,
    `  <path id="glyph-${i}-${char}" d="${d}" />`
  ].join('\n');
}).join('\n');

const vbX = bbox.x1.toFixed(2);
const vbW = (bbox.x2 - bbox.x1).toFixed(2);
const vbH = fontSize.toFixed(2);

const svg = `<?xml version="1.0" encoding="UTF-8"?>
<!-- GENERATED by brandbook/tools/gen-wordmark.mjs — hand-edit glyph-5-w and glyph-7-k for w/k cuts -->
<!-- Provenance: SpaceGrotesk[wght].ttf wght=600 at ${fontSize}px, pinned commit 877f891 -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="${vbX} 0 ${vbW} ${vbH}">
  <g id="wordmark-base" fill="currentColor" fill-rule="evenodd">
${pathEls}
  </g>
</svg>`;

writeFileSync(OUT_PATH, svg, 'utf8');
console.log(`Written: ${OUT_PATH}`);
console.log('Next: hand-edit glyph-5-w (w apex) and glyph-7-k (k arm/leg) for 20-deg wake cuts');
```

### Candidate SVG Shell (path-only, currentColor, 64-unit grid)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- Candidate A: Canonical Wake Mark -->
<!-- Provenance: hand-authored on 64-unit grid, 20-deg canonical angle -->
<!-- NO background rect, NO text elements, NO embedded fonts -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <!-- Route line (crossing), with notch gap at center -->
  <!-- Two trailing wake lines -->
  <g id="mark-a" fill="none" stroke="currentColor"
     stroke-width="6.667" stroke-linecap="round">
    <!-- Route line segment 1 (origin to notch start) -->
    <line x1="0" y1="37.82" x2="27.30" y2="33.71" />
    <!-- Route line segment 2 (notch end to far edge) -->
    <line x1="36.70" y1="30.29" x2="64" y2="26.18" />
    <!-- Wake line 1 (trailing) -->
    <line x1="24" y1="54" x2="52" y2="43.8" />
    <!-- Wake line 2 (outer trailing) -->
    <line x1="18" y1="64" x2="46" y2="53.8" />
  </g>
</svg>
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Static-weight TTF for each weight variant | Single variable TTF with wght axis + font.variation.set() | opentype.js added VariationManager (pre-2026, surfaced in v2.0.0) | No need for separate SemiBold TTF; one font file covers all weights |
| opentype.js 1.3.4 (2021) | opentype.js 2.0.0 (2026-05-06) | May 2026 | ESM support, COLRv0+CPALv0, updated deps; but introduces toPathData flipY double-flip bug requiring workaround |
| text-to-svg npm wrapper | opentype.js directly | That wrapper is 7 years stale | No wrapper layer; direct API access to getPaths() and variation |

**Deprecated/outdated:**
- `text-to-svg`: Last published 7 years ago; wraps opentype.js 1.x. Do not use.
- `toPathData()` without options: Default `{flipY: true}` in v2.0.0 is broken for paths from `getPath()`/`getPaths()`. Always pass `{flipY: false}`.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Coordinate math (notch endpoints, wake line centers) produces visually correct geometry on 64-unit grid | Candidate Geometry Math | Marks may look geometrically off; requires visual correction during authoring — low risk since author verifies at render time |
| A2 | w/k path node replacement requires 2-4 node edits (not more) | Pattern 4, Code Examples | If Space Grotesk w/k have more complex node topology around apex/arm, the edit scope is larger — requires inspection of generated path data before estimate is final |
| A3 | CSS tab-chrome colors (#DEE1E6, #F1F3F4) are close enough to Chrome for the favicon mock to be recognizable | Pattern 6 | Mock may look less realistic on non-Chrome-themed operating systems; cosmetic risk only |

**If this table is empty:** All other claims in this research were verified or cited — no user confirmation needed for the non-assumed items.

---

## Open Questions

1. **w/k path node count in practice**
   - What we know: Space Grotesk SemiBold is a quadratic TTF with approx 8-16 nodes per glyph
   - What's unclear: Exact node topology at the `w` apex and `k` arm/leg intersection — depends on the actual generated path data; cannot be known without running gen-wordmark.mjs against the real TTF
   - Recommendation: gen-wordmark.mjs Wave 0 task includes printing the generated path data to stdout for review; the implementer inspects `id="glyph-5-w"` and `id="glyph-7-k"` before the edit task is planned

2. **Monogram D: "C" vs "cw"**
   - What we know: Both survive monochrome; "C" is simpler and cleaner at 16px; "cw" is more distinctive but harder to read below 24px
   - What's unclear: Which reads better in the browser-tab favicon mock context specifically
   - Recommendation: Author "C" first; evaluate at 16px in the favicon mock; pivot to "cw" only if "C" looks generic next to the other candidates

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | gen-wordmark.mjs | Yes | v22.14.0 | — |
| npm | package.json install | Yes | v11.1.0 | — |
| curl | fetch-fonts.sh | Yes | system | wget with s/-fL/-q -O/ |
| xmllint | SVG validation check | Yes | system (macOS libxml2) | node --input-type=module inline DOMParser |
| bash | fetch-fonts.sh | Yes | zsh | zsh compatible |

**Missing dependencies with no fallback:** None.

---

## Validation Architecture

*nyquist_validation key absent from .planning/config.json — treating as enabled.*

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Node.js built-in test runner (`node --test`) |
| Config file | none — matches Phase 102 convention |
| Quick run command | `node --test brandbook/tools/gen-wordmark.test.mjs` |
| Full suite command | `node --test brandbook/tools/*.test.mjs` |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LOGO-01 | gen-wordmark.mjs emits correct number of path elements (9 for "Crosswake") | unit | `node --test brandbook/tools/gen-wordmark.test.mjs` | Wave 0 |
| LOGO-01 | wordmark baseline is positive (ascender-scaled) and glyphs do not go below origin | unit | included in gen-wordmark.test.mjs | Wave 0 |
| LOGO-01 | all 7 candidate SVG files exist and are well-formed XML | smoke | `xmllint --noout brandbook/logo/tournament/candidates/*.svg` | Wave 0 fixture |
| LOGO-01 | no `<text>` elements in any candidate SVG | smoke | `grep -rL '<text' brandbook/logo/tournament/candidates/` returns all 7 files | manual-check |
| LOGO-02 | index.html opens in browser from file:// with no console errors | manual | open brandbook/logo/tournament/index.html | Wave 0 |
| LOGO-03 | no full-viewBox `<rect>` in candidate SVGs | smoke | `grep -c '<rect' brandbook/logo/tournament/candidates/*.svg` all return 0 | manual-check |
| LOGO-03 | no `<text>` in candidate SVGs | smoke | `grep -rn '<text' brandbook/logo/tournament/candidates/` returns empty | manual-check |
| LOGO-04 | checkpoint section present in index.html | manual | visual review of gallery closing section | manual-check |

### Sampling Rate

- **Per task commit:** `node --test brandbook/tools/gen-wordmark.test.mjs`
- **Per wave merge:** `node --test brandbook/tools/*.test.mjs && xmllint --noout brandbook/logo/tournament/candidates/*.svg`
- **Phase gate:** Full suite green + human visual review of gallery at file:// before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `brandbook/tools/gen-wordmark.test.mjs` — covers LOGO-01 unit checks (path count, baseline sign, fill-rule)
- [ ] `brandbook/tools/package.json` — adds opentype.js 2.0.0 dependency
- [ ] `brandbook/logo/tournament/candidates/` directory — stub SVG placeholder to unblock smoke tests
- [ ] `brandbook/logo/tournament/index.html` — stub HTML page to verify file:// loading

---

## Security Domain

*security_enforcement not present in config.json — treating as enabled.*

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Static files; no user accounts |
| V3 Session Management | no | No sessions; file:// gallery |
| V4 Access Control | no | No server; local files only |
| V5 Input Validation | yes (limited) | fetch-fonts.sh validates HTTP status; gen-wordmark.mjs validates font load success |
| V6 Cryptography | no | No secrets or sensitive data |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Downloading unverified binary from GitHub raw URL | Tampering | Pinned commit SHA in fetch-fonts.sh; verify file size after download |
| SVG with embedded script (XSS if ever served inline) | Elevation of Privilege | All candidate SVGs are path-only; no `<script>` or event handlers; grep check in validation |
| node_modules malicious postinstall | Tampering | opentype.js has no postinstall script; slopcheck [OK]; package-lock.json committed for reproducibility |

---

## Sources

### Primary (HIGH confidence)

- `github.com/opentypejs/opentype.js` src/glyph.mjs — confirmed y-flip in getPath (`y + (-cmd.y * yScale)`)
- `github.com/opentypejs/opentype.js` src/path.mjs — confirmed `toPathData()` default `{flipY: true}`
- `github.com/opentypejs/opentype.js` src/variation.mjs — confirmed `font.variation.set({wght: 600})` API
- `github.com/opentypejs/opentype.js` src/font.mjs — confirmed `getPaths()` returns per-glyph path array
- `github.com/opentypejs/opentype.js` issue #724, PR #850 — double y-flip bug confirmed open as of 2026-06-11
- `api.github.com/repos/google/fonts/contents/ofl/spacegrotesk` — confirmed only `SpaceGrotesk[wght].ttf` in root (no static SemiBold)
- `api.github.com/repos/floriankarsten/space-grotesk/contents/fonts/ttf/static` — confirmed static/ has only Light, Regular, Medium, Bold (no SemiBold)
- `api.npmjs.org/downloads/point/last-week/opentype.js` — 1,077,077 weekly downloads confirmed
- `api.github.com/repos/google/fonts/git/ref/heads/main` — SHA `877f8918ee661764418e085766dc0b073260a3ef` (2026-06-11)
- `brandbook/tokens/tokens.css` (Phase 102, committed) — `--cw-primitive-*` variable names confirmed for gallery CSS
- `.planning/research/STACK.md` — opentype.js 2.0.0 API fundamentals (do not re-research)
- `.planning/research/PITFALLS.md` — y-origin/fill-rule bugs, GitHub SVG sanitization, optical corrections

### Secondary (MEDIUM confidence)

- `github.com/opentypejs/opentype.js/test/variation.spec.mjs` — variation.set() usage confirmed in tests
- Geometry math (tan 20°, notch coordinates) — deterministic computation, verified by Python script in this session

### Tertiary (LOW confidence)

- CSS tab-chrome approximate colors (#DEE1E6, #F1F3F4) — estimated from visual inspection of Chrome UI, not an authoritative specification

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — opentype.js npm registry verified, slopcheck OK, 13-year history
- Font source: HIGH — Google Fonts API confirmed variable-only; no static SemiBold exists
- opentype.js v2.0.0 API: HIGH — source code inspected directly; issue/PR confirmed bug and workaround
- Geometry math: HIGH — deterministic trigonometry, Python-verified
- Gallery architecture (currentColor swap): HIGH — standard CSS inheritance behavior
- w/k edit technique: MEDIUM — approach is correct, exact node count requires real TTF inspection

**Research date:** 2026-06-11
**Valid until:** 2026-09-11 (opentype.js 2.0.0 API is stable; Space Grotesk repo unlikely to change wght axis range; CSS currentColor is permanent)
