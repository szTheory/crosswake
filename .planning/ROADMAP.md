# Roadmap: Crosswake

## Milestones

- ✅ **v8.0 Offline Sync Hardening and UI Polish** — Phases 99-101 (shipped 2026-06-11)
- 🚧 **v9.0 Brand System & Visual Identity** — Phases 102-106 (in progress)

## Phases

<details>
<summary>✅ v8.0 Offline Sync Hardening and UI Polish (Phases 99-101) — SHIPPED 2026-06-11</summary>

- [x] Phase 99: Real Network-Toggling E2E Tests (2/2 plans) — completed 2026-06-11
- [x] Phase 100: Storage Budget Enforcement (2/2 plans) — completed 2026-06-11
- [x] Phase 101: Offline UI Consolidation & Polish (2/2 plans) — completed 2026-06-11

</details>

### 🚧 v9.0 Brand System & Visual Identity (In Progress)

**Milestone Goal:** Pressure-test the existing brand book and ship the fully implemented brand system — audit, design tokens, user-selected logo, standalone HTML brand book, and collateral — self-contained in `brandbook/` (<1 MB committed, SVG/text-first).

- [ ] **Phase 102: Brand Audit & Token Foundation** - Audit the brand book, run WCAG contrast matrix, freeze design tokens with user ratification
- [ ] **Phase 103: Logo Tournament** - Seven-candidate HTML gallery with mandatory user direction-pick checkpoint
- [ ] **Phase 104: Logo Refinement & Production Suite** - Three micro-variants, user sign-off, full path-only production SVG suite
- [ ] **Phase 105: HTML Brand Book** - Standalone long-scroll index.html + BRAND-SPEC.md v1.0
- [ ] **Phase 106: Collateral, Integration & Closeout** - Collateral assets, README/ExDoc wiring, hex exclusion, advisory CI lane

## Phase Details

### Phase 102: Brand Audit & Token Foundation
**Goal**: Audit deliverable locks palette and typography verdicts before any token or logo work begins; design tokens are the audit's enforceable output; user ratifies font/color changes before downstream phases proceed
**Depends on**: Nothing (first phase of v9.0)
**Requirements**: AUDT-01, AUDT-02, AUDT-03, AUDT-04, TOKN-01, TOKN-02, TOKN-03
**Success Criteria** (what must be TRUE):
  1. `brandbook/AUDIT.md` exists with KEEP/TIGHTEN/REWORK/ADD/REMOVE verdicts for all 14 brand book sections, a stated cost on every REWORK, and a scripted WCAG contrast matrix classifying all color pairings against AA text (4.5:1) and non-text UI (3:1) thresholds
  2. The audit explicitly flags the v8.0 generator-template blue/amber Tailwind vs. app.css teal/brass palette drift with an explicit verdict
  3. User has ratified any audit-driven font or color changes (lightweight checkpoint) before Phase 103 begins
  4. `brandbook/tokens/crosswake.tokens.json` exists in W3C DTCG 2025.10 format with three tiers (primitive → semantic → state), including Crosswake runtime-semantic tokens (`runtime.liveview`, `runtime.offline`, `runtime.native`, `runtime.sensitive`, `runtime.bridge`)
  5. `brandbook/tokens/tokens.css` custom properties align with the JSON, contrast-annotated per pairing, and state tokens cover all 12 required states (default/hover/active/focus/disabled/selected/success/warning/error/info/subtle/muted)
**Plans**: TBD

### Phase 103: Logo Tournament
**Goal**: Seven logo candidates are presented at equal production fidelity in an HTML gallery; the phase ends only when the user has made an explicit direction selection (franken-picks allowed) — no refinement begins without this checkpoint
**Depends on**: Phase 102
**Requirements**: LOGO-01, LOGO-02, LOGO-03, LOGO-04
**Success Criteria** (what must be TRUE):
  1. Opening `brandbook/logo/tournament/index.html` from `file://` shows all 7 candidates (4 logomark concepts + 3 integrated typemarks) rendered as path-only SVGs at equal production fidelity
  2. Each candidate is shown on foam/dark/white backgrounds, in monochrome, at 256px + 24px + 16px, with a browser-tab favicon mock, close-set horizontal and stacked lockups, per-candidate rationale + stated risk, and an equal-size lineup grid
  3. No candidate has a rectangular container background; no main lockup carries a subtitle; logotype gap is approximately one stroke-width on all typemark candidates
  4. User has made an explicit direction selection at the tournament checkpoint before Phase 104 begins (BLOCKING CHECKPOINT — Phase 104 does not start without selection confirmation)
**Plans**: TBD
**UI hint**: yes

### Phase 104: Logo Refinement & Production Suite
**Goal**: The tournament winner goes through three micro-variants with user sign-off, then the full path-only production SVG suite ships including all lockup variants and a 16-grid favicon
**Depends on**: Phase 103 (requires user tournament selection)
**Requirements**: LOGO-05, LOGO-06, LOGO-07
**Success Criteria** (what must be TRUE):
  1. Three micro-variants of the selected tournament direction exist and user has given explicit sign-off before the production suite is built (BLOCKING CHECKPOINT — production suite does not begin without sign-off)
  2. Production suite contains path-only SVGs for: mark (light/dark/mono/signal colorway), horizontal lockup (light/dark), stacked lockup (light/dark), subtitle variant, and typemark — no `<text>` elements, no rectangular container backgrounds, correct fill rules
  3. A dedicated 16-grid `favicon.svg` exists with strokes outlined to filled paths, verified to render legibly at 16px
  4. Wordmark path data was generated via opentype.js 2.0.0 with the correct Y-baseline and `fill-rule="evenodd"` applied; the provenance script is committed in `brandbook/tools/`; font binaries and `node_modules/` are gitignored
**Plans**: TBD

### Phase 105: HTML Brand Book
**Goal**: A standalone long-scroll HTML brand book and the authoritative BRAND-SPEC.md v1.0 ship with all brand elements assembled and no build step required
**Depends on**: Phase 104
**Requirements**: BOOK-01, BOOK-02, BOOK-03
**Success Criteria** (what must be TRUE):
  1. Opening `brandbook/index.html` from `file://` renders the full brand book without errors, loads fonts via Google Fonts CDN (with full system fallbacks), and requires zero build steps
  2. The brand book contains all required sections: cover hero, brand essence, logo system with misuse examples, color with live contrast badges + copy-hex, typography specimens + scale, tokens, motifs rendered live, voice/microcopy do-don't tables, UI specimens built from `tokens.css`, and an asset index
  3. `brandbook/BRAND-SPEC.md` v1.0 exists as the audited successor to the `prompts/` draft, documenting the ratified palette, type scale, token naming convention, and logo usage rules
**Plans**: TBD
**UI hint**: yes

### Phase 106: Collateral, Integration & Closeout
**Goal**: All collateral assets ship, README and ExDoc are wired to the production mark, hex tarball exclusion is verified, and an advisory CI lane enforces size budget and asset validity
**Depends on**: Phase 105
**Requirements**: COLL-01, COLL-02, COLL-03, COLL-04
**Success Criteria** (what must be TRUE):
  1. Collateral set is complete: `readme-header.svg` (light + dark, path-only), `social-card.svg` + `social-card.png` (1200×630, <300 KB), `favicon-32.png`, and `apple-touch-icon.png` (180px) all exist in `brandbook/collateral/`
  2. README header image uses an absolute `raw.githubusercontent.com` URL with GitHub `<picture>` dark-mode handling; ExDoc `logo:` key in `mix.exs` points to the committed production mark
  3. Running `mix hex.build` produces a tarball that does not contain any `brandbook/` files; `:exclude_patterns` belt-and-suspenders is in place in `mix.exs`
  4. `brandbook/` total committed size is verified < 1 MB; `.gitignore` additions cover `brandbook/tools/node_modules/` and `brandbook/tools/fonts/`; advisory CI lane (`brandbook-verify.yml`) passes checks for size budget, SVG validity, and token JSON validity
**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 99. Real Network-Toggling E2E Tests | v8.0 | 2/2 | Complete | 2026-06-11 |
| 100. Storage Budget Enforcement | v8.0 | 2/2 | Complete | 2026-06-11 |
| 101. Offline UI Consolidation & Polish | v8.0 | 2/2 | Complete | 2026-06-11 |
| 102. Brand Audit & Token Foundation | v9.0 | 0/? | Not started | - |
| 103. Logo Tournament | v9.0 | 0/? | Not started | - |
| 104. Logo Refinement & Production Suite | v9.0 | 0/? | Not started | - |
| 105. HTML Brand Book | v9.0 | 0/? | Not started | - |
| 106. Collateral, Integration & Closeout | v9.0 | 0/? | Not started | - |
