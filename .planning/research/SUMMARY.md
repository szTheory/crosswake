# Project Research Summary

**Project:** Crosswake v9.0 Brand System & Visual Identity
**Domain:** OSS devtools brand system — design tokens, logo suite, HTML brand book, collateral
**Researched:** 2026-06-11
**Confidence:** HIGH

## Executive Summary

Crosswake v9.0 converts the existing text-only brand book draft (`prompts/crosswake-brand-book.md`) into a fully implemented, audited, and self-contained `brandbook/` directory. The work pattern is well-established: production-grade OSS brand systems (Tailwind, Astro, Vercel/Geist, Bun) all follow the same structure — path-only SVG logo suite with light/dark/mono variants, W3C DTCG design token file with a three-tier primitive→semantic→state hierarchy, and a standalone HTML brand book that requires no build step. The tooling surface is deliberately minimal: one npm package (`opentype.js` 2.0.0 for glyph-to-path wordmark generation), one Homebrew tool (`rsvg-convert` for PNG rasterisation), and zero new Elixir/mix.exs dependencies. All brand tooling lives under `brandbook/tools/` and is isolated entirely from the Elixir library.

The recommended phase order is dictated by a hard dependency chain: the brand audit must lock palette verdicts before tokens can be finalized, tokens must be settled before logos can reference correct palette values, the selected logo must exist before the HTML brand book can display it, and the brand book must be complete before collateral and wiring can reference canonical assets. Skipping this order — for example, generating tokens before the audit flags contrast failures — produces rework. The audit is not a formality; the existing v8.0 palette surfaces contain a Tailwind color mismatch (blue/amber scale in generator templates vs. the teal/warm nautical palette in `app.css`) that must be diagnosed and locked before anything downstream proceeds.

The critical risks are concentrated in two areas. First, logo generation: programmatic marks without explicit concept constraints produce generic devtools-cliché output (hexagons, node graphs, rectangular containers). The tournament gallery must enforce written anti-requirements and require monochrome and small-size tests for every candidate before user selection. Second, token architecture: primitive-only token files without a semantic layer make theming and dark mode maintenance intractable. Every component in `tokens.css` must reference the semantic tier only — never raw palette primitives. Both risks are preventable if the phase sequencing and per-phase checklists from the pitfalls research are followed.

---

## Key Findings

### Recommended Stack

The tooling stack is minimal by design. `opentype.js` 2.0.0 (May 2026) is the single npm dependency: it converts Space Grotesk glyphs to SVG path data without a headless browser, runs in pure Node.js ESM, and its `getPath()` / `toPathData()` API handles GPOS kerning natively. `rsvg-convert` (via `brew install librsvg`) handles all SVG-to-PNG rasterisation — it is significantly more accurate than macOS `sips` and far lighter than Puppeteer or Inkscape. The W3C DTCG `2025.10` stable spec governs the token file format; all three major tools (Style Dictionary, Tokens Studio, Figma) have adopted it.

All three specified typefaces are confirmed available with the required weights. `Atkinson Hyperlegible Next` (the 2024 "Next" variant with 7 weights) is confirmed on Google Fonts at the correct specimen URL — distinct from the classic 2-weight version. The OFL FAQ explicitly permits using font outlines in logos; committed path-data SVGs are not subject to OFL redistribution requirements.

**Core technologies:**
- `opentype.js` 2.0.0: Glyph-to-SVG-path conversion for path-only wordmarks — actively maintained, zero native deps, ships ESM+CJS
- `rsvg-convert` (librsvg via Homebrew): SVG-to-PNG rasterisation — correct renderer, scriptable, deterministic; avoids `sips` distortion and Puppeteer overhead
- W3C DTCG 2025.10: Design token JSON format — stable spec, tooling-compatible, `$value`/`$type`/`$description` per token
- Google Fonts CDN: Brand book font loading — no binary commits, no build step; Fontsource is the self-hosted fallback for offline use
- WCAG luminance formula: Implemented as a dependency-free Node.js script consuming `crosswake.tokens.json` directly

**Critical version requirements:**
- `opentype.js` must be `^2.0.0` (not 1.3.4) — the 2.0.0 release closes a 5-year gap and ships the correct ESM surface
- OG social card: 1200x630px (universal) or 1280x640px (GitHub-recommended); safe zone 1080x600px inner area

### Expected Features

Five deliverables are in scope for v9.0. All are required; none can be deferred.

**Must have (table stakes):**
- `brandbook/AUDIT.md` — verdict (KEEP/TIGHTEN/REWORK/ADD/REMOVE) for every section of the brand book draft; WCAG contrast matrix for all 16 palette token pairs; competitor conflict check against the four named projects (React Native, Hotwire, Phoenix/LiveView Native, Capacitor)
- `brandbook/tokens/crosswake.tokens.json` — W3C DTCG format; three-tier hierarchy (primitives → semantic roles → state variants); all 16 palette tokens plus semantic roles and light/dark variants
- `brandbook/tokens/tokens.css` — CSS custom properties derived from the token JSON; tier-separated with comment headers; `@media (prefers-color-scheme)` dark mode; forbidden-pairing comments embedded
- `brandbook/logo/tournament/index.html` — 7-candidate gallery (4 logomark + 3 typemark); each shown on light/dark/monochrome backgrounds and at 16–32px scale; mandatory user-selection checkpoint; no external dependencies
- `brandbook/logo/` production suite — horizontal lockup (light + dark), stacked lockup (light + dark), mark-only (light + dark + monochrome + signal colorway), path-only SVGs, no rectangular containers, no subtitle on main lockup
- `brandbook/index.html` — standalone HTML brand book (no build step): live swatches with clipboard copy, inline WCAG contrast badges, type specimens, voice do/don't table, logo display with download links, asset index, component specimens (route card, badge, button, code block)
- `brandbook/collateral/readme-header.svg` — path-only SVG, light + dark variants, wired into README with absolute `raw.githubusercontent.com` URL
- `brandbook/collateral/social-card.png` — 1280x640px PNG; dark Current-950 background
- `brandbook/collateral/favicons/` — `favicon.ico` + `favicon.svg` (prefers-color-scheme embedded) + `apple-touch-icon.png` (180x180) + `icon-192.png` + `icon-512.png`
- Size budget: entire `brandbook/` committed content under 1 MB
- Hex exclusion: `brandbook/` absent from published hex tarball (verified via `mix hex.build` tarball inspection)

**Should have (v9.0 scope extensions, include if within complexity budget):**
- Runtime-semantic token group (`runtime.liveview`, `runtime.offline`, `runtime.native`, `runtime.sensitive`) in the token file — unique differentiator, low implementation cost
- In-situ context mocks (browser tab, GitHub repo card) in the tournament gallery per candidate
- Competitor diff panel in tournament gallery
- Inline WCAG contrast checker (two-swatch picker) in the HTML brand book

**Defer to post-v9.0:**
- Animated logo variants
- Figma source files
- Print-ready CMYK PDF brand book
- Dark/light mode toggle in HTML brand book (auto via `prefers-color-scheme` is sufficient)
- Token wiring: migrating `examples/phoenix_host/assets/css/app.css` and `priv/templates/` to import from `brandbook/tokens/tokens.css` — this is a v10.0 concern once audit has locked palette verdicts

### Architecture Approach

The `brandbook/` directory is a self-contained artifact that sits alongside the Elixir library without touching it. The hex `package/0` `:files` key in `mix.exs` is an allowlist (`~w(lib priv mix.exs README.md LICENSE CHANGELOG.md guides)`) — `brandbook/` is excluded automatically with no additional configuration required. The only `mix.exs` change this milestone is adding `logo: "brandbook/logo/crosswake-mark.svg"` to `docs/0` in phase 106. `.gitignore` needs two additions: `brandbook/tools/node_modules/` and `brandbook/tools/fonts/`. Everything else in `brandbook/` is committed SVG, HTML, JSON, CSS, and shell scripts — no binaries.

Token consumers (`examples/phoenix_host/assets/css/app.css`, `priv/templates/`) remain decoupled this milestone by design. The audit may change color values; wiring dependents before verdicts are locked produces rework. `tokens.css` becomes the canonical written source in v9.0; wiring is a v10.0 concern.

**Major components:**
1. `brandbook/tools/` — Node scripts (token compilation, WCAG contrast matrix, SVG validation) + PNG export shell script; isolated `package.json`; `node_modules/` and `fonts/` gitignored
2. `brandbook/tokens/` — `crosswake.tokens.json` (W3C DTCG source of truth) + `tokens.css` (compiled CSS custom properties); three-tier hierarchy; light/dark via `prefers-color-scheme`
3. `brandbook/logo/` — path-only SVG production suite (mark, lockup variants, monochrome); `tournament/` subdirectory with 7-candidate gallery HTML
4. `brandbook/index.html` — standalone HTML brand book; no build step; vanilla JS only; fonts from Google Fonts CDN
5. `brandbook/collateral/` — readme-header SVG, social card PNG, favicon set
6. `.github/workflows/brandbook-verify.yml` — advisory CI lane (size budget, SVG validity, token JSON validity); triggered only on `brandbook/**` changes

### Critical Pitfalls

1. **Generic marks / rectangular containers** — Lock the concept brief (shape vocabulary, explicit anti-requirements: no hexagons, no node-graph metaphors, no enclosing rectangle) before any SVG is drawn. The tournament gallery enforces this at the mandatory user-selection checkpoint. Recovery after a generic mark wins the tournament is expensive (re-run tournament).

2. **Stroke collapse at 16px favicon** — Design the mark at a native 24x32 canvas, not at 512px. Evaluate every candidate at three sizes in the tournament gallery: 200px, 32px, 16px. Production SVGs must have strokes outlined to filled paths; live-stroke source files live in `brandbook/src/` only.

3. **Broken kerning and Y-axis flip after opentype.js path conversion** — Pass the correct baseline `y = font.ascender * (fontSize / font.unitsPerEm)` to `font.getPath()`. Set `fill-rule="evenodd"` on the wordmark path group (TTF outline winding requires evenodd for letter counters). After path generation, review every adjacent glyph pair at 400% zoom and hand-adjust optically bad pairs (`rk`, `os`, `aw`, `ke`). The path-converted wordmark is the start of hand-curation, not the finished artifact.

4. **Raw-color-only tokens without semantic layer** — The DTCG three-tier structure is mandatory. Component rules in `tokens.css` must reference only semantic tier tokens (`--cw-color-accent-primary`), never raw primitives (`--cw-color-blue-500`). Document and freeze the naming convention in phase 102 before generating a single CSS variable. Cap v1.0 at ~50 total tokens.

5. **GitHub SVG sanitization and relative image paths** — Production SVGs must be path-only (no `<text>`, no `dominant-baseline`, no `<script>`, no external `href`). README header dark mode must use GitHub's `<picture><source media="(prefers-color-scheme: dark)" srcset="...">` pattern. README image URL must be an absolute `https://raw.githubusercontent.com/szTheory/crosswake/main/brandbook/...` path; relative paths 404 on hexdocs.pm.

---

## Implications for Roadmap

The phase order is fully determined by hard artifact dependencies. Each phase has exactly one critical output that the next phase consumes. There is no parallelism available in the core chain; shortcuts produce rework.

### Phase 102: Brand Audit

**Rationale:** The audit must come first because it determines which palette values survive and which get REWORK verdicts. Tokens built before the audit may need rebuilding if any color values change. The audit also surfaces the existing generator template / app.css palette mismatch (generator emits blue/amber Tailwind classes; app.css uses the teal/nautical palette) — this inconsistency must be diagnosed and logged before any token is written.
**Delivers:** `brandbook/AUDIT.md` with verdicts for all 14 brand book sections; scripted WCAG contrast matrix for all 16 palette pairs; competitor conflict check; `.gitignore` additions (2 lines)
**Addresses:** WCAG contrast failures in muted palettes (pitfall 10); token naming convention decision and freeze (pitfall 9)
**Avoids:** Rebuilding tokens after post-audit palette changes

### Phase 103: Design Tokens

**Rationale:** Palette verdicts from phase 102 are now locked. This is the earliest the token file can be built without risk of rework.
**Delivers:** `brandbook/tokens/crosswake.tokens.json` (W3C DTCG, three-tier hierarchy, 16 primitives + semantic roles + state + light/dark); `brandbook/tokens/tokens.css` (CSS custom properties with tier-separation comments and forbidden-pairing notes); `brandbook/tools/package.json` (opentype.js 2.0.0 as the sole dependency)
**Addresses:** Raw-color-only token pitfall (pitfall 5); token naming churn (pitfall 9)
**Avoids:** Any component referencing primitive tokens directly; token explosion beyond ~50 entries

### Phase 104: Logo Tournament and Production Logo Suite

**Rationale:** Token palette values are settled. The tournament requires the opentype.js pipeline (established in phase 103 tooling) for typemark candidates. The mandatory user-selection checkpoint is a hard gate — no production suite work begins until selection is confirmed.
**Delivers:** `brandbook/logo/tournament/index.html` (7 candidates, 3-background x 3-scale presentation, in-situ mocks, selection checkpoint); user-selected candidate refined to `brandbook/logo/` production suite (5+ SVG files: horizontal lockup light/dark, stacked light/dark, mark-only light/dark/mono, signal colorway)
**Addresses:** Generic marks (pitfall 1); stroke collapse (pitfall 2); monochrome failure (pitfall 3); broken kerning / Y-axis (pitfall 4); optical centering (pitfall 8); x-height mismatch (pitfall 11)
**Avoids:** Proceeding to brand book without a locked, hand-curated mark

### Phase 105: Standalone HTML Brand Book

**Rationale:** Tokens are settled and the production logo exists. The brand book references both. This is the first phase that assembles all brand elements into a single deliverable.
**Delivers:** `brandbook/index.html` (no build step; live swatches with clipboard copy; inline WCAG contrast badges; type specimens; voice do/don't table; logo display with download links; asset index; component specimens for route card, badge, button, code block)
**Addresses:** Over-specification pitfall (scope to color, type, logo, spacing, voice-with-examples only); devtools brand cliches in component specimens
**Avoids:** External JS frameworks (vanilla JS only); Figma embeds; animation-heavy hero

### Phase 106: Collateral, README Wiring, and ExDoc Logo

**Rationale:** All assets are finalized. Collateral requires the settled mark and settled token palette. README wiring and ExDoc `:logo` key reference the production mark. Size budget CI and hex exclusion verification run here when the complete committed asset set is known.
**Delivers:** `brandbook/collateral/readme-header.svg` (light + dark, path-only); `brandbook/collateral/social-card.png` (1280x640px); `brandbook/collateral/favicons/` (5 files); `BRAND-SPEC.md`; `mix.exs` `:logo` key; `README.md` header image with absolute raw.githubusercontent.com URL; `.github/workflows/brandbook-verify.yml` (advisory CI: size budget, SVG validity, token JSON)
**Addresses:** Hex package brand asset leak (pitfall 7); GitHub SVG sanitization for README (pitfall 6); relative image paths on hexdocs (architecture finding)
**Avoids:** Relative image paths in README.md; `@media prefers-color-scheme` inside `<img>`-referenced SVG; missing `:exclude_patterns` in mix.exs

### Phase Ordering Rationale

- Audit → Tokens → Logos → Book → Collateral is a strict dependency chain enforced by artifact outputs. Any reordering introduces rework: tokens before audit risks palette rebuilding; logos before tokens reference unsettled color values; brand book before logo has a placeholder; collateral before book assembly misses the asset index.
- The tournament user-selection checkpoint is a hard gate. No refinement work begins without an explicit selection.
- Token naming convention must be decided and frozen in phase 102 before any CSS is generated in phase 103. Renaming tokens mid-implementation triggers cascading updates across JSON, CSS, brand book, and component specimens.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 104 (Logo Tournament):** High creative uncertainty — the concept brief needs explicit shape anti-requirements, and the opentype.js Y-axis/fill-rule gotchas require validated generation code before candidate SVGs are authored
- **Phase 105 (HTML Brand Book):** Inline WCAG contrast checker and component specimens (route card, badge) are medium complexity; both require finalized token CSS first; test the contrast badge computation in isolation before wiring into the full page

Phases with standard patterns (research phase likely skippable):
- **Phase 102 (Brand Audit):** Audit structure is well-specified; WCAG formula is implemented in STACK.md; competitor check list is bounded (4 named projects)
- **Phase 103 (Design Tokens):** DTCG 2025.10 spec is stable and thoroughly documented; three-tier hierarchy is established industry pattern
- **Phase 106 (Collateral):** Favicon set requirements, OG card dimensions, and README image URL convention are fully resolved in research

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | opentype.js 2.0.0 release confirmed May 2026; font availability confirmed on Google Fonts and Fontsource; DTCG 2025.10 stable spec verified at W3C; OFL logo-use FAQ confirmed; rsvg-convert recommendation corroborated by multiple sources |
| Features | HIGH | Grounded in public brand pages from Tailwind, Astro, Vercel/Geist, GitHub, Bun; all 5 deliverables and all MVP acceptance criteria are concrete and enumerable |
| Architecture | HIGH | Based on direct inspection of actual `mix.exs`, `.gitignore`, `app.css`, and template files in the repo (2026-06-11); all integration mechanisms confirmed from source |
| Pitfalls | HIGH (technical) / MEDIUM (design) | GitHub SVG sanitization, WCAG thresholds, hex exclusion, and opentype.js coordinate bugs are all confirmed from primary sources; optical correction and logo design pitfalls are MEDIUM confidence (community pattern evidence) |

**Overall confidence:** HIGH

### Gaps to Address

- **Generator template palette mismatch:** The Tailwind color mismatch in `priv/templates/crosswake/offline_ui/` (blue/amber) vs. `app.css` (teal/nautical) needs an explicit audit verdict in phase 102. The fix path (update generator templates) belongs in v10.0 token-wiring work, not v9.0.
- **Logo concept brief specifics:** The shape vocabulary for the 4 logomark concepts and 3 typemark concepts is a creative decision for the phase 104 planning step, not a research output. The research constraint is: the brief must include explicit anti-requirements (shapes to avoid) before any SVG generation begins.
- **Optical correction thresholds:** Nudge amounts for optical centering (2-4% upward for type-heavy lockups) are empirical guidance. Validate visually during phase 104 refinement; no script can verify this.
- **Advisory CI scope for brandbook-verify.yml:** Three checks recommended (size budget, SVG validity via xmllint, token JSON validity via Node one-liner). Deferred checks (WCAG assertions, HTML validation) wait until their respective phases complete.

---

## Sources

### Primary (HIGH confidence)
- `github.com/opentypejs/opentype.js/releases` — v2.0.0 release confirmation (May 2026)
- `fonts.google.com/specimen/Atkinson+Hyperlegible+Next` — weight availability confirmed
- `openfontlicense.org/ofl-faq/` — logo artwork OFL exemption
- `www.designtokens.org/TR/drafts/format/` — DTCG 2025.10 `$value`/`$type`/`$description` syntax
- `www.w3.org/TR/WCAG21/relative-luminance.html` — luminance formula with 0.04045 threshold
- `caniuse.com/link-icon-svg` — SVG favicon browser support matrix
- `docs.github.com/en/repositories/.../customizing-your-repositorys-social-media-preview` — 1280x640 recommended social card size
- `evilmartians.com/chronicles/how-to-favicon-in-2021-six-files-that-fit-most-needs` — minimal favicon set
- `opentypejs/opentype.js#187`, `#724`, `#347` — Y-axis flip, kerning, fill-rule confirmed issues
- `github.com/github/markup#1160` — GitHub SVG `dominant-baseline` sanitization confirmed
- `mix.exs` (actual repo, inspected 2026-06-11) — `:files` allowlist, ExDoc deps, `docs/0` structure
- `examples/phoenix_host/assets/css/app.css` — 16 CSS custom properties confirmed
- `priv/templates/crosswake/offline_ui/` — Tailwind class mismatch confirmed

### Secondary (MEDIUM confidence)
- `tasteprofile.io/blog/w3c-dtcg-design-tokens-practical-guide` — three-tier hierarchy, naming pitfalls
- `medium.com/studio-function/logo-design-guide-4-of-5-notes-on-presenting-e1c130974dd0` — tournament presentation guidelines
- `goodpractices.design/articles/design-tokens` — component-token anti-pattern
- `driesvints.com/blog/investigating-dark-mode-for-svgs-in-github-readmes` — GitHub SVG dark mode limitation
- `webaim.org/articles/contrast/` — mid-tone contrast failure patterns
- `alexadam.medium.com` + `mausic.me/blog/...` — rsvg-convert recommendation

### Tertiary (LOW confidence, validate during implementation)
- Optical correction nudge amounts (2-4% for type-heavy lockups) — empirical design community guidance, no single authoritative source; validate visually during phase 104 refinement

---
*Research completed: 2026-06-11*
*Ready for roadmap: yes*
