# Phase 106: Collateral, Integration & Closeout - Context

**Gathered:** 2026-06-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship derivative collateral (`brandbook/collateral/`), wire the brand into the repo surfaces (README header, ExDoc logo, hex exclusion belt-and-suspenders), add the advisory brandbook CI lane, and verify the milestone-wide size budget. Requirements: COLL-01..04. This is the final v9.0 phase — ends with milestone-closing UAT.

</domain>

<decisions>
## Implementation Decisions

### Collateral (COLL-01)
- **D-01:** `brandbook/collateral/readme-header.svg` — wide hero composition for the README: horizontal lockup centered with subtle wake-seam motif, transparent background, GitHub-safe (no external refs, no <style> media queries — light/dark handled by TWO files: `readme-header.svg` (Current 950 art) + `readme-header-dark.svg` (Foam 50 art) for the `<picture>` pattern).
- **D-02:** `brandbook/collateral/social-card.svg` (source) + `social-card.png` 1200×630 export via `rsvg-convert` if available else Playwright screenshot at exact viewport (deviceScaleFactor 1, clip 1200×630) — dark Current 950 bg, lockup + tagline, key content in 1080×600 safe zone, PNG < 300KB (target <150KB).
- **D-03:** Favicon PNGs from `brandbook/logo/favicon.svg`: `favicon-32.png` (32×32) and `apple-touch-icon.png` (180×180, needs opaque background — Foam 50 — since iOS doesn't composite transparency well). Export via same raster path as D-02.
- **D-04:** All renders verified visually (render-verify loop / READ the PNGs).

### Integration (COLL-02, COLL-03)
- **D-05:** README.md header: `<picture>` block at top — `<source media="(prefers-color-scheme: dark)" srcset="...readme-header-dark.svg">` + `<img src="...readme-header.svg">` using ABSOLUTE raw.githubusercontent.com/szTheory/crosswake/main/... URLs (works on GitHub + hexdocs). Keep the existing README title/content below; don't rewrite the README beyond the header.
- **D-06:** mix.exs: add `logo: "brandbook/logo/crosswake-mark.svg"` to `docs()` (ExDoc ~0.38 supports SVG logos) and add `exclude_patterns: ["brandbook"]`-equivalent belt-and-suspenders... NOTE: hex `:files` is already a strict allowlist (`~w(lib priv mix.exs README.md LICENSE CHANGELOG.md guides)`); verify whether package supports `:exclude_patterns` (it does — hexpm docs) and add it for safety. Verify with `mix hex.build` + tarball listing that brandbook/ is absent.
- **D-07:** `mix docs`/compile must still pass after mix.exs change (don't break the library build).

### CI lane (COLL-04)
- **D-08:** `.github/workflows/brandbook-verify.yml` — ADVISORY (non-merge-blocking, matching the repo's hermetic/advisory house split), triggers on `paths: ['brandbook/**']`: size budget (git ls-files brandbook | sum ≤ 1MB), SVG structural validation (node brandbook/tools/check-candidates.mjs + check-production.mjs), token JSON parse + compile-tokens round-trip diff, node --test brandbook/tools.
- **D-09:** Size budget FINAL verification: committed brandbook ≤ 1MB INCLUDING the new PNGs (current 614KB + ~200KB PNG budget = comfortable).

### Closeout
- **D-10:** After COLL tasks: phase verification, then milestone-level wrap-up is handled by the orchestrator (UAT conversation with the user + complete-milestone flow) — NOT by an executor.

### Claude's Discretion
- readme-header composition details (verified visually), social card layout, CI lane job naming.

</decisions>

<canonical_refs>
## Canonical References

- `.planning/research/ARCHITECTURE.md` — raw.githubusercontent URL pattern, ExDoc logo support, advisory CI precedent
- `.planning/research/PITFALLS.md` — GitHub SVG sanitization (no in-SVG media queries for README), `<picture>` pattern, hex exclude_patterns
- `.planning/research/STACK.md` — OG card requirements (1200×630 PNG <300KB, sRGB), favicon PNG sizes, rsvg-convert vs alternatives
- `brandbook/logo/*.svg` — source assets
- `mix.exs` lines 69-85 — package() allowlist + docs() to modify
- `README.md` — header insertion point
- `.github/workflows/` — existing lane conventions (read one for style)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `brandbook/tools/render-verify.mjs` (with width arg) — for visual checks AND as PNG export fallback (Playwright clip screenshot)
- check-production.mjs / check-candidates.mjs — wired into the CI lane

### Established Patterns
- Advisory vs merge-blocking CI split (house style); kebab-case asset naming with crosswake- prefix

### Integration Points
- `mix.exs` package()/docs(); README.md top; .github/workflows/
- rsvg-convert NOT installed (research notes brew install librsvg); ImageMagick `magick` IS installed but its SVG rendering can't resolve currentColor — collateral SVGs must use LITERAL hex fills so either rasterizer works; Playwright screenshot is the reliable export path

</code_context>

<specifics>
## Specific Ideas

- README header should be understated — the lockup + a whisper of wake seams, not a billboard
- PNG sizes kept lean (D-09); social-card.png target <150KB

</specifics>

<deferred>
## Deferred Ideas

- GitHub repo social-preview upload (manual Settings step — document it, can't be automated from repo)
- Landing page build; NORM-01 generator/example normalization (future milestone)

</deferred>

---

*Phase: 106-collateral-integration-closeout*
*Context gathered: 2026-06-12*
