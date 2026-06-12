# Requirements: Crosswake v9.0 Brand System & Visual Identity

**Defined:** 2026-06-11
**Core Value:** Pressure-test the existing brand book and ship the fully implemented brand system — audit, design tokens, user-selected logo, standalone HTML brand book, and collateral — self-contained in `brandbook/` (<1 MB committed, SVG/text-first).

## v1 Requirements

Requirements for this milestone. Each maps to roadmap phases.

### Brand Audit (AUDT)

- [x] **AUDT-01**: Maintainer can read a full 14-section pressure-test audit of `prompts/crosswake-brand-book.md` in `brandbook/AUDIT.md`, with KEEP/TIGHTEN/REWORK/ADD/REMOVE verdicts and a stated cost on every REWORK
- [x] **AUDT-02**: A scripted WCAG contrast matrix classifies every brand color pairing against AA text (4.5:1) and non-text UI (3:1) thresholds; palette values adjusted only where the math demands
- [x] **AUDT-03**: Audit explicitly flags the v8.0 surface drift (generator-template blue/amber Tailwind scale vs app.css teal/brass palette) with a verdict — code normalization deferred to a future milestone
- [x] **AUDT-04**: User ratifies any audit-driven font/color changes before downstream phases consume them

### Design Tokens (TOKN)

- [x] **TOKN-01**: `brandbook/tokens/crosswake.tokens.json` exists in W3C DTCG 2025.10 format with three tiers (primitive → semantic → state), including Crosswake runtime-semantic tokens (liveview / offline island / native / sensitive / bridge)
- [x] **TOKN-02**: `brandbook/tokens/tokens.css` custom properties align with the JSON, contrast-annotated per pairing
- [x] **TOKN-03**: State tokens cover default/hover/active/focus/disabled/selected/success/warning/error/info/subtle/muted

### Logo System (LOGO)

- [x] **LOGO-01**: 7 tournament candidates (4 logomark concepts + 3 integrated typemarks) exist as path-only SVGs at equal production fidelity
- [x] **LOGO-02**: Tournament gallery (`brandbook/logo/tournament/index.html`) shows each candidate at 256px on foam/dark/white, monochrome, 24px + 16px, a browser-tab favicon mock, close-set horizontal + stacked lockups, per-candidate rationale + stated risk, and an equal-size lineup grid
- [x] **LOGO-03**: No rectangular container backgrounds on any mark; main lockup carries no subtitle; logotype gap ≈ one stroke-width
- [x] **LOGO-04**: User selects the logo direction at the tournament checkpoint (franken-picks supported)
- [ ] **LOGO-05**: Winner goes through a 3-micro-variant refinement round with user sign-off
- [x] **LOGO-06**: Production suite ships: mark, mono, horizontal lockup (light/dark), stacked, subtitle variant, typemark, and a dedicated 16-grid `favicon.svg` — all path-only, no `<text>`, correct fill rules
- [x] **LOGO-07**: Wordmark generated from Space Grotesk outlines via opentype.js (correct Y-baseline, evenodd counters) with the provenance script committed in `brandbook/tools/`; fonts + node_modules gitignored

### HTML Brand Book (BOOK)

- [ ] **BOOK-01**: Standalone `brandbook/index.html` — long-scroll, zero build step, works from `file://`, Google Fonts CDN with full system fallbacks
- [ ] **BOOK-02**: Sections include: cover hero, brand essence, logo system with misuse examples, color with live contrast badges + copy-hex, typography specimens + scale, tokens, motifs rendered live, voice/microcopy do-don't tables, UI specimens built from `tokens.css`, asset index
- [ ] **BOOK-03**: `brandbook/BRAND-SPEC.md` v1.0 — the audited successor to the prompts/ draft (which stays as the historical seed)

### Collateral & Integration (COLL)

- [ ] **COLL-01**: Collateral ships: `readme-header.svg`, `social-card.svg` + `social-card.png` (1200×630, <300 KB), `favicon-32.png`, `apple-touch-icon.png` (180px)
- [ ] **COLL-02**: README header wired via absolute raw.githubusercontent URL with GitHub `<picture>` dark-mode handling (works on both GitHub and hexdocs)
- [ ] **COLL-03**: ExDoc `logo:` configured in `mix.exs`; hex tarball verified to exclude `brandbook/` (+ `:exclude_patterns` belt-and-suspenders)
- [ ] **COLL-04**: `brandbook/` committed size verified < 1 MB; `.gitignore` additions in place; advisory CI lane checks size budget, SVG validity, and token JSON validity

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Brand Normalization

- **NORM-01**: Generator templates (`priv/templates/crosswake/offline_ui/*.eex`) and `examples/phoenix_host` CSS normalize onto `brandbook/tokens/tokens.css` as the single source of truth

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| PDF brand book | HTML chosen deliberately — diffs cleanly, checks into git, no binary bloat |
| Embedded font binaries | License-safe CDN + system fallbacks; gitignored TTFs only for one-time path generation |
| Landing page / marketing site build | Brand book provides the blueprint; building the site is a separate milestone |
| Mascot or illustration library | No strong reason per the seed brand book; violates "all killer no filler" |
| Patching v8.0 generator/example palette drift | Flagged in audit (AUDT-03), normalization deferred to NORM-01 in a future milestone |
| Animated logo / motion assets | Static SVG system first; motion only if a future surface demands it |
| Multi-library suite brand architecture rollout | Audit may note suite implications, but only Crosswake's brand ships this milestone |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUDT-01 | Phase 102 | Complete |
| AUDT-02 | Phase 102 | Complete |
| AUDT-03 | Phase 102 | Complete |
| AUDT-04 | Phase 102 | Complete |
| TOKN-01 | Phase 102 | Complete |
| TOKN-02 | Phase 102 | Complete |
| TOKN-03 | Phase 102 | Complete |
| LOGO-01 | Phase 103 | Complete |
| LOGO-02 | Phase 103 | Complete |
| LOGO-03 | Phase 103 | Complete |
| LOGO-04 | Phase 103 | Complete |
| LOGO-05 | Phase 104 | Pending |
| LOGO-06 | Phase 104 | Complete |
| LOGO-07 | Phase 104 | Complete |
| BOOK-01 | Phase 105 | Pending |
| BOOK-02 | Phase 105 | Pending |
| BOOK-03 | Phase 105 | Pending |
| COLL-01 | Phase 106 | Pending |
| COLL-02 | Phase 106 | Pending |
| COLL-03 | Phase 106 | Pending |
| COLL-04 | Phase 106 | Pending |

**Coverage:**
- v1 requirements: 20 total
- Mapped to phases: 20
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-11*
*Last updated: 2026-06-11 — traceability written after roadmap creation*
