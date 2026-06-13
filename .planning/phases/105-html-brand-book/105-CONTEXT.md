# Phase 105: HTML Brand Book - Context

**Gathered:** 2026-06-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship the standalone professional HTML brand book (`brandbook/index.html` + `brandbook/assets/brandbook.css` + `brandbook/assets/brandbook.js`) and `brandbook/BRAND-SPEC.md` (the audited v1.0 successor to the prompts/ draft). Requirements: BOOK-01, BOOK-02, BOOK-03.

NOT in this phase: collateral/README wiring/PNGs/CI lane (106).

</domain>

<decisions>
## Implementation Decisions

### Architecture (locked by approved milestone plan + research)
- **D-01:** One long-scroll `brandbook/index.html` with two small asset files (`assets/brandbook.css`, `assets/brandbook.js`) — NO framework, NO build step, works from `file://` and GitHub Pages. JS ≤ ~60 lines: sticky-nav scroll-spy, copy-hex buttons, live WCAG contrast computation for swatch badges.
- **D-02:** Fonts via Google Fonts CDN `<link>` (Space Grotesk 500/600/700, Atkinson Hyperlegible Next 400/500/600, JetBrains Mono 400/500 — all verified available) with the full system fallback stacks from tokens; page must degrade gracefully offline.
- **D-03:** Page consumes `../tokens/tokens.css`… NO — index.html sits IN brandbook/, so `tokens/tokens.css` relative link. The page is styled FROM the tokens (the tokens proving themselves); brandbook.css layers layout/typography on top of token variables.

### Sections (BOOK-02, in order; dark-hero/light-body rhythm per AUDIT §11)
- **D-04:** (1) Cover hero — dark Current 950, `crosswake-lockup-horizontal-dark.svg` inline, the promise "Declare the crossing. Keep the boundary honest."; (2) Brand essence + pillars (from AUDIT §2 DNA); (3) Logo system — all 8 production files rendered (from `logo/`), clearspace + min sizes (AUDIT §8 numbers), misuse examples RENDERED LIVE (cyan recolor, boxed mark, stretched, subtitle-on-main — each shown crossed out, built in CSS/SVG not screenshots); (4) Color — swatch grid from tokens with hex + copy button + LIVE computed contrast pass/fail badges (JS, WCAG formula from contrast.mjs logic inlined); semantic role table incl. runtime.* tokens; (5) Typography — specimens of all three faces + the type scale table (brand book §9 values); (6) Design tokens — usage guide + links to tokens files; (7) Motifs — wake seams + runtime lanes rendered live as inline SVG (sparse per brand book §11); (8) Voice & microcopy — write-this/not-this tables, runtime/status label glossary, error message examples (from seed brand book §6/§15 + AUDIT §10 ready-to-use copy); (9) UI specimens — route card, runtime badges, buttons, callout, code block — built from tokens.css custom properties only; (10) Asset index — file table for logo/ + tokens/ + collateral (collateral rows marked "ships in v9.0 phase 106").
- **D-05:** BRAND-SPEC.md = the audited brand book v1.0: seed brand book content with every AUDIT verdict applied (KEEPs carried over, TIGHTENs rewritten, ADDs included — Stone 600, dark-mode hierarchy, state-mapping table, logo geometry numbers, ratified colorways). Markdown, kebab-case heading anchors, ~the same section structure as the seed. The prompts/ draft stays untouched (historical seed).

### Quality bar + verification
- **D-06:** MANDATORY render-verify loop (Playwright screenshot of the full page at 1200w + a mobile 390w pass; executing agent READS the screenshots and inspects every section) before commit. The visual loop caught real defects in 103/104 — it is the quality gate.
- **D-07:** Accessibility of the page itself: semantic headings h1→h2→h3, landmarks (nav/main), all logo imgs/svgs carry titles or aria-labels, contrast badges computed not hardcoded, keyboard-reachable copy buttons, prefers-reduced-motion respected (no animations beyond trivial transitions anyway).
- **D-08:** Authoring strategy (learned from the 103-04 crashes): NO giant single Writes. Build index.html via a generator script OR incremental section-by-section Edits, committing per section group. brandbook.css hand-written in bounded chunks.

### Size budget (HARD)
- **D-09:** Committed brandbook/ is 868KB of the 1MB cap. THIS PHASE frees space first: replace `brandbook/logo/tournament/index.html` (351KB round-1/2 gallery) with a ~2KB provenance README pointing at round3.html, the candidates/ SVGs, and git history (`git log --follow brandbook/logo/tournament/index.html`). round3.html (the decision page) stays. Candidates stay (tiny). After trim: ~519KB used; brand book targets ≤ 250KB total (index.html + assets), leaving ≥ 200KB for phase 106 PNGs.
- **D-10:** Brand book embeds the production logo SVGs by inlining ONCE per variant where needed; favor `<img src="logo/crosswake-mark.svg">` references over inlining where currentColor isn't required (file:// img-loading of local SVG works) — inline only where color-swapping demands it.

### Claude's Discretion
- Visual design of the page itself (must follow the brand: foam/current rhythm, wake-seam motifs sparse, Space Grotesk display headings), exact specimen content, BRAND-SPEC.md prose details within audit verdicts.

</decisions>

<canonical_refs>
## Canonical References

- `brandbook/AUDIT.md` — §2 DNA (essence section), §7 token spec + state mapping, §8 logo numbers (clearspace/min sizes/misuse list), §10 voice + ready-to-use copy, §11 landing/docs blueprint (dark-hero rhythm), §14 ratification record
- `prompts/crosswake-brand-book.md` — seed content for BRAND-SPEC.md (§6 voice, §9 typography scale, §15 microcopy library, §13 layout rules)
- `brandbook/tokens/tokens.css` + `crosswake.tokens.json` — the styling source of truth
- `brandbook/logo/*.svg` + `brandbook/logo/README.md` — production assets to showcase
- `.planning/research/FEATURES.md` — brand-book table stakes (live swatches, contrast badges, voice tables)
- `.planning/research/PITFALLS.md` — over-specification rot, GitHub-safe SVG (less relevant here; page isn't sanitized)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `brandbook/tools/render-verify.mjs` — the mandatory visual QA harness
- `brandbook/tools/contrast.mjs` — exports linearize/luminance/contrast; its formula gets inlined (~15 lines) into brandbook.js for live badges
- refinement.html / round3.html — established page aesthetic (foam bg, current text, swatch tiles) to evolve into the full book

### Established Patterns
- Generated-or-incremental authoring with per-section commits (D-08); provenance headers; check-candidates/check-production validators

### Integration Points
- Phase 106 adds: README header wiring, ExDoc logo, favicon PNGs, social card, CI lane — the asset index section should list these as "ships in 106"

</code_context>

<specifics>
## Specific Ideas

- "Very professional, stands on its own" — the page IS the brand's first full expression; the dark hero with the real lockup is the money shot
- Accessibility as visible brand feature: contrast ratios printed beside every pairing
- All killer no filler: no decorative stock imagery, no lorem ipsum — every specimen uses real Crosswake microcopy from the brand book

</specifics>

<deferred>
## Deferred Ideas

- Landing page build (blueprint only, AUDIT §11)
- Collateral + integrations → 106

</deferred>

---

*Phase: 105-html-brand-book*
*Context gathered: 2026-06-12*
