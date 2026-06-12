# Phase 104: Logo Refinement & Production Suite - Context

**Gathered:** 2026-06-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Take the LOGO-04 winner — **Mark A (Canonical Wake Mark) + W1 terminal-cut wordmark** (`candidates/A.svg` + `candidates/wordmark-r3.svg`) — through a 3-micro-variant refinement round **rendered in the ratified colorways** (this is where the user first sees the logo in color), get user sign-off, then ship the production asset suite in `brandbook/logo/`. Requirements: LOGO-05, LOGO-06, LOGO-07.

NOT in this phase: HTML brand book (105), collateral/README wiring/favicon PNGs (106).

</domain>

<decisions>
## Implementation Decisions

### Winner (locked by LOGO-04 pick, 2026-06-12)
- **D-01:** Mark A: 3-line 20° wake mark, route (0,43.65)→(64,20.35) on 64-grid, notch break (27.30,33.71)→(36.70,30.29), wake lines (20.59,50.34)→(52.53,38.71) and (25.15,62.87)→(57.10,51.24), stroke 6.667u round caps.
- **D-02:** W1 wordmark: `wordmark-r3.svg` — stock Space Grotesk SemiBold outlines + clipPath 20° shears on exactly two terminals (w final-stroke tip wedge `M237.46 35.28 L245.66 35.28 L245.66 38.265 Z`, k arm tip wedge `M317.02 35.28 L327.89 35.28 L327.89 39.236 Z`).
- **D-03:** Lockup layout (from R3-A-lockup-horizontal): mark scaled 1.125 (→72u), gap 7.5u (one stroke width), wordmark translated +75.76, total viewBox 0 0 442.16 72.

### Hard technique rules (learned rounds 1–2, non-negotiable)
- **D-04:** NO blind path-node surgery on letterforms — clip-path shears on untouched outlines only.
- **D-05:** EVERY visual artifact must be browser-rendered (Playwright) and inspected by the orchestrator/executor BEFORE user presentation or commit. The render-verify loop is mandatory, not optional.

### Micro-variant round (LOGO-05)
- **D-06:** Exactly 3 micro-variants of the winner, differing on ONE axis each (e.g., V1 = as-picked baseline; V2 = notch width 1.25× vs 1.5× stroke; V3 = slightly heavier stroke 7.2u or wordmark shear depth). Variants rendered side-by-side IN COLOR.
- **D-07:** Colorway renders use the ratified audit §8 table: Light primary (Current 950 `#09141A` on Foam 50 `#F7F1E6` and on white), Dark primary (Foam 50 on Current 950), Signal (Brass 500 `#C98A2E` mark + Foam wordmark on Current 950), OSS badge (Wake 700 `#2B756A` mark + Current 950 wordmark on Foam 50). One sign-off page (`brandbook/logo/refinement.html`, small, file://-compatible).
- **D-08:** User sign-off via blocking checkpoint; pick recorded for the suite build.

### Production suite (LOGO-06, LOGO-07)
- **D-09:** Files in `brandbook/logo/`: `crosswake-mark.svg` (currentColor), `crosswake-mark-mono.svg`, `crosswake-lockup-horizontal.svg` (light: literal Current 950), `crosswake-lockup-horizontal-dark.svg` (Foam 50), `crosswake-lockup-stacked.svg`, `crosswake-lockup-subtitle.svg` (ONLY variant carrying the tagline "Declare the crossing." — set as PATHS generated via gen-wordmark.mjs in Atkinson/Space Grotesk, never <text>), `crosswake-typemark.svg` (the W1 wordmark standalone), `favicon.svg` (dedicated 16-grid redraw: max 2 wake strokes, pixel-snapped, NOT a scaled-down mark; include prefers-color-scheme dark swap inside the SVG for browser tabs — GitHub README contexts get separate handling in 106).
- **D-10:** Production lockups use literal hex fills (distribution files must render correctly when downloaded standalone); the mark/typemark keep currentColor variants for embedding. Each file ≤ a few KB; clear provenance header comments.
- **D-11:** LOGO-07 acceptance: gen-wordmark.mjs already committed (103) — 104 confirms regeneration reproducibility (run script, diff base) and documents the regen workflow in brandbook/logo/README note or header comments.
- **D-12:** Size budget pressure: brandbook committed = 780KB of 1MB cap. Production suite must stay lean (~30-60KB total). Do NOT duplicate the wordmark paths more than necessary; consider <use> only where renderer-safe (GitHub strips some references — keep distribution files self-contained, accept duplication, but keep toPathData precision at 2 decimals to trim bytes).

### Claude's Discretion
- Variant axis choices, refinement page layout, exact favicon 16-grid geometry (verified visually at 16px), stacked lockup proportions, subtitle typography size/tracking (brand book §9 rules).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/phases/103-logo-tournament/103-04-SUMMARY.md` — the pick + technique rules provenance
- `brandbook/logo/tournament/candidates/A.svg`, `wordmark-r3.svg`, `R3-A-lockup-horizontal.svg` — the winning source artifacts
- `brandbook/AUDIT.md` §8 — colorway table, clearspace, min sizes, favicon simplification rule
- `brandbook/tokens/crosswake.tokens.json` — exact hex values for colorways
- `.planning/research/STACK.md` — SVG favicon prefers-color-scheme support, PNG fallback facts (PNGs are 106 scope)
- `.planning/research/PITFALLS.md` — GitHub SVG sanitization (no external refs in distribution files)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Render-verify loop: Playwright via `examples/phoenix_host/node_modules` (chromium launch + file:// screenshot) — the proven QA harness from round 3
- `brandbook/tools/check-candidates.mjs` — extend or point at `brandbook/logo/` for production files validation
- `brandbook/tools/gen-wordmark.mjs` — for the subtitle text paths (tagline) if needed

### Established Patterns
- Provenance header comments on every SVG; separate commits for generated-base vs hand-curated edits
- currentColor for embeddable variants; literal hex for standalone distribution files (new rule D-10)

### Integration Points
- Phase 105 brand book consumes `brandbook/logo/*` paths; Phase 106 derives PNGs from `favicon.svg` + social card from lockups

</code_context>

<specifics>
## Specific Ideas

- User explicitly wants to SEE color now — the refinement sign-off page is the color reveal moment; make the colorway grid prominent
- "All killer no filler": 3 variants max, one axis each, no decorative extras

</specifics>

<deferred>
## Deferred Ideas

- favicon-32.png / apple-touch-icon.png / social card → Phase 106
- Misuse examples + clearspace diagrams → Phase 105 (brand book)
- Tournament gallery size trim (index.html is 351KB) → consider in 106 size-budget pass if cap pressure demands

</deferred>

---

*Phase: 104-logo-refinement-production-suite*
*Context gathered: 2026-06-12*
