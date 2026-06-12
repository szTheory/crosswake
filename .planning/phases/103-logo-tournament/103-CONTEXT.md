# Phase 103: Logo Tournament - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Produce 7 logo candidates (4 logomark concepts + 3 integrated typemarks) as path-only SVGs at equal production fidelity, presented in a standalone HTML gallery (`brandbook/logo/tournament/index.html`) that ends at the MANDATORY blocking user checkpoint: the user picks a direction (franken-picks supported). Requirements: LOGO-01, LOGO-02, LOGO-03, LOGO-04.

NOT in this phase: refinement micro-variants and the production asset suite (104), HTML brand book (105), collateral (106). The tournament gallery is this phase's ONLY deliverable — nothing competes with it on the critical path.

</domain>

<decisions>
## Implementation Decisions

### Candidate roster (locked by approved milestone plan)
- **D-01:** Exactly 7 candidates at equal production fidelity (no straw men):
  - **A — Canonical Wake Mark:** the audit §8 spec executed straight — diagonal route line at 20°, two trailing wake lines (3 lines total), notch/break of 1.5× stroke width at the crossing, round caps.
  - **B — Seam Shift:** route line *offset* (not broken) at a perpendicular seam — the boundary visibly changes the route but the route continues.
  - **C — Crossing Lanes:** two runtime lanes with the route line crossing between them through a gate notch.
  - **D — Minimal Wake Monogram:** a "C" (or "cw") constructed from wake geometry, counter broken by the route line — favicon-first.
  - **E — Wake-W typemark:** "Crosswake" with `w` apexes re-cut to the 20° wake angle + trailing hairline wake.
  - **F — Crossing-SS typemark:** route line passes through the wordmark with the break landing at the "cross|wake" boundary.
  - **G — Terminal Cuts typemark:** quiet 20° terminal cuts on `k`/`w` + one notch detail — deliberate low-risk fallback.
- **D-02:** Each logomark candidate (A–D) is shown as close-set horizontal lockup AND stacked lockup with the Space Grotesk SemiBold wordmark; typemark candidates (E–G) stand alone as integrated treatments.

### Geometry & format (ratified via AUDT-04 — frozen)
- **D-03:** Wake Mark constraints from AUDIT.md §8: 20° canonical crossing angle (16–24° acceptable), exactly 3 lines, 2.5px stroke at 24px scale, 1.5×-stroke notch, round caps, simplify to 2 strokes at ≤16px.
- **D-04:** Path-only SVG — no `<text>`, no rectangular clip-path backgrounds, no embedded fonts, no bounding shapes (circle/square/blob) around any mark. ViewBox on a 64-unit grid for marks; strokes kept as strokes (re-weightable).
- **D-05:** Hard user constraints: NO rectangular background shapes (marks break boundaries, sit directly on page); logotype gap ≈ one stroke-width from the mark; main lockups carry NO subtitle/slogan (a with-subtitle variant is Phase 104 scope).
- **D-06 (D-11 rider, ratified):** ALL wordmark renderings carry the mandatory custom `w`/`k` wake-angle cuts — the wordmark must NOT be typesettable in unmodified Space Grotesk. The `w` cut echoes the 20° crossing angle; the `k` arm/leg intersection carries an angular notch at the same slope. Candidates without these cuts are disqualified.

### Wordmark tooling (pulled forward from 104's LOGO-07 — needed at tournament time)
- **D-07:** `brandbook/tools/gen-wordmark.mjs` (Node + opentype.js 2.0.0, the phase's ONLY npm dependency, isolated in `brandbook/tools/package.json`) generates kerned path-only "Crosswake" outlines from Space Grotesk SemiBold TTF via `font.getPath(text, x, y, size, {kerning:true})` + `toPathData()`. Known bugs to handle: y-origin must be `font.ascender * (fontSize/unitsPerEm)` (NOT 0); TTF outlines need `fill-rule="evenodd"` for counters.
- **D-08:** `brandbook/tools/fetch-fonts.sh` downloads Space Grotesk TTF from the google/fonts GitHub repo at a PINNED commit into `brandbook/tools/fonts/` (gitignored — already covered by Phase 102's .gitignore entries). The committed SVGs are source of truth; scripts are provenance/regeneration tooling, never a build step.
- **D-09:** Custom cuts (D-06) are surgical hand-edits to the generated path data on the affected glyphs — never hand-drawn full letterforms. LOGO-07's formal acceptance stays in Phase 104; Phase 103 builds and uses the tooling.

### Gallery presentation (locked by approved milestone plan + LOGO-02)
- **D-10:** `brandbook/logo/tournament/index.html` — standalone, no build step, works from `file://`. Uses Phase 102's `tokens.css` for page styling. Per candidate: one card showing 256px renders on Foam 50 / Current 950 / white; one-color monochrome; 24px and 16px inline renders; a browser-tab favicon mock; horizontal + stacked lockups (close-set per D-05). Candidates render directly on background swatches — never in container rectangles.
- **D-11:** Each card carries a 2–3 sentence design rationale AND a stated risk (e.g., "reads as a checkmark below 20px"). Closing section: equal-size lineup grid of all 7 for direct comparison.
- **D-12:** Gallery includes a maintainer recommendation WITH reasoning, rendered identically to other candidates (no visual favoritism). Franken-picks explicitly invited ("mark B + type treatment F"). Selection question framing: durability-focused ("which still works at 16px, in one color, in five years"), not "which do you like".
- **D-13:** Candidate SVGs live in `brandbook/logo/tournament/candidates/` (committed — kilobytes of text, selection provenance). One-color (Current 950) is the canonical authored colorway; light/dark/mono variants in the gallery may be CSS-driven (currentColor) since these are tournament artifacts, not production assets.

### Checkpoint mechanics (LOGO-04)
- **D-14:** Phase ends with a blocking user checkpoint presenting the gallery path + lineup summary + maintainer recommendation. User may pick a candidate, a franken-combination, or request adjustments (which re-enter this phase). The pick is recorded in the phase summary and STATE.md for Phase 104 to consume. Notify the user explicitly when the gallery is ready (their standing instruction: "lmk when the logos are there").

### Claude's Discretion
- Exact path data, optical corrections (optical vs geometric centering), stroke joints, per-candidate micro-geometry within the D-03 constraints
- Gallery page layout/typography (must follow brand tokens), rationale prose
- The maintainer recommendation itself (decide from durability criteria after seeing all 7 rendered)
- Whether D's monogram is "C" or "cw" (pick whichever survives 16px better)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Tournament brief (the WHAT — ratified)
- `brandbook/AUDIT.md` §8 — pinned geometry, wordmark spec + D-11 rider, colorways, clearspace, min sizes, do/don't, misuse list
- `brandbook/AUDIT.md` §9 — visual specimen guidance (what's worth producing)

### Design tokens (gallery styling + colorways)
- `brandbook/tokens/tokens.css` — use semantic tokens for gallery page; colorway hexes from primitives
- `brandbook/tokens/crosswake.tokens.json` — token source incl. usage guards

### Phase 102 context chain
- `.planning/phases/102-brand-audit-token-foundation/102-CONTEXT.md` — D-01..D-12 locked decisions (palette, latitude policy)

### Milestone research (verified facts)
- `.planning/research/STACK.md` — opentype.js 2.0.0 API, font sources, OFL verdict
- `.planning/research/PITFALLS.md` — opentype.js y-origin + fill-rule bugs, GitHub SVG sanitization, optical correction pitfalls, 16px legibility
- `.planning/research/FEATURES.md` — logo tournament presentation best practices (in-situ mocks)

### Seed spec (historical grounding)
- `prompts/crosswake-brand-book.md` §10 — original Wake Mark concept and anti-patterns (no boats/anchors/flames/X-without-wake-semantics; must not resemble React atom, Phoenix flame, Hotwire wire, compass rose)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `brandbook/tokens/tokens.css` (Phase 102) — gallery page consumes these custom properties directly
- `brandbook/tools/` conventions established in 102: zero-dep-first Node ESM, const + named functions, tests alongside (`*.test.mjs`, `node --test`)

### Established Patterns
- `.gitignore` already excludes `/brandbook/tools/node_modules/` and `/brandbook/tools/fonts/` (Phase 102)
- Committed-generated-artifact pattern with provenance header comment (tokens.css) — apply to generated wordmark base paths if committed separately

### Integration Points
- New: `brandbook/logo/tournament/{index.html, candidates/*.svg}`, `brandbook/tools/{gen-wordmark.mjs, fetch-fonts.sh, package.json}`
- Milestone size budget: brandbook/ currently 140KB of 1MB cap — tournament SVGs are kilobytes; package-lock.json should be committed (provenance) but node_modules never

</code_context>

<specifics>
## Specific Ideas

- "Not just a shitty icon to the left of basic text" — lockups must feel unified; typemark candidates are fully integrated type treatments
- "Breaking the boundaries" — marks may overshoot baseline/cap-height, cross their own seam lines; never boxed
- Equal production fidelity across all 7 — the user must be able to genuinely choose any of them

</specifics>

<deferred>
## Deferred Ideas

- 3 micro-variants of the winner + production suite + favicon.svg as dedicated 16-grid artifact → Phase 104
- Full colorway asset files (signal/OSS-badge variants) → Phase 106 per AUDIT.md §8
- Misuse-example renderings → Phase 105 (HTML brand book)

</deferred>

---

*Phase: 103-logo-tournament*
*Context gathered: 2026-06-11*
