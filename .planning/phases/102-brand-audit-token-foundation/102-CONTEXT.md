# Phase 102: Brand Audit & Token Foundation - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Pressure-test `prompts/crosswake-brand-book.md` through the 14-section audit specified in `102-AUDIT-BRIEF.md`, producing `brandbook/AUDIT.md` with KEEP/TIGHTEN/REWORK/ADD/REMOVE verdicts; run a scripted WCAG contrast matrix over every palette pairing; emit the design-token foundation (`brandbook/tokens/crosswake.tokens.json` in DTCG 2025.10 + generated, committed `brandbook/tokens/tokens.css`). Phase ends with the user ratifying any audit-driven font/color changes (AUDT-04) so phases 103–106 build on a frozen foundation. Requirements: AUDT-01..04, TOKN-01..03.

NOT in this phase: logo candidates/SVGs (103–104), the HTML brand book (105), collateral/README wiring (106), patching v8.0 generator/example CSS drift (flagged only — NORM-01, future milestone).

</domain>

<decisions>
## Implementation Decisions

### Palette remediation posture (advisor-researched, locked)
- **D-01:** Computed WCAG matrix (not estimates) is the ground truth. Verified results: Stone 500 `#7C746A` on Foam 50 = 4.09:1 is the ONLY true text-pair hex failure. Brass 700 (4.74:1) and Wake 700 (4.85:1) on Foam 50 PASS. All dark-surface pairs pass (5.6–16.6:1). Wake 500 on Foam 50 (2.95:1) and Mist 200 on Foam 50 (1.35:1) are role-definition issues, not hex problems.
- **D-02:** Remediation rule: add **Stone 600 `#756D63`** as a new primitive (4.53:1 on Foam 50 ✓, 5.09:1 on white ✓); semantic `text.muted` maps to Stone 600. Stone 500 stays in the palette, narrowed to `text.subtle` (large text ≥24px, disabled, decorative). No other hex changes.
- **D-03:** Usage restrictions are encoded structurally in DTCG `$description` fields (e.g., Wake 500: "light-surface text forbidden: 2.95:1 on Foam 50"; Mist 200: "border and dark-surface text only") — the Primer fg.muted lesson: constraints live in the token, not in prose.
- **D-04:** Full before/after matrix committed as an AUDIT.md appendix; contrast script is dependency-free Node at `brandbook/tools/contrast.mjs` (WCAG relative-luminance, 0.04045 threshold), output reproducible.

### Token naming & structure (advisor-researched, locked)
- **D-05:** Keep the **`--cw-` prefix**. Two tiers only: **primitive** (internal, emitted as `--cw-primitive-*`, never referenced by component CSS) → **semantic** (public contract, `--cw-{role}-{variant}`). No component tier (anti-feature per research).
- **D-06:** Bounded semantic vocabulary (~23–28 tokens, hard cap ~30): `surface` (default/raised/inset/inverse) · `text` (default/muted/subtle/inverse/code) · `action` (bg/fg/bg-dark/fg-dark/hover/focus-ring) · `border` (default/subtle/strong) · `status` (success/warning/error/info) · `runtime` (liveview/offline/native/sensitive/bridge — the Crosswake-unique tier).
- **D-07:** DTCG 2025.10 JSON (`$value`/`$type`/`$description`, group-level `$type`, `{primitive.x.y}` aliases) is the **source of truth**. `brandbook/tools/compile-tokens.js` (<80 LOC, zero npm deps) generates `tokens.css`, which is **committed** with a `/* GENERATED from crosswake.tokens.json — do not edit */` header. Rule: edit JSON → run script → commit both.
- **D-08:** Theming: single `:root` (light), `@media (prefers-color-scheme: dark) { :root:not([data-theme]) }` for system dark, `[data-theme="dark"]` for explicit toggle — daisyUI-idiomatic for Phoenix 1.8 adopters. Only the semantic tier flips; primitives never change.
- **D-09:** State handling (satisfies TOKN-03 without explosion): hover/focus as semantic tokens (`action.hover`, `action.focus-ring`); active via CSS selectors against semantic tokens; disabled via `opacity: 0.45` + label (never a new color token); success/warning/error/info via `status.*`; subtle/muted via `text.*`/`border.*` variants; selected documented as a pattern (action tokens + border.strong). AUDIT.md §7 documents this mapping explicitly so TOKN-03 is auditable.

### Audit boldness / latitude policy (advisor-researched, locked)
- **D-10:** **Typography verdict: KEEP Space Grotesk** (+ Atkinson Hyperlegible Next body, JetBrains Mono code — all confirmed on Google Fonts with required weights). Honest finding acknowledged in AUDIT.md: Space Grotesk appears in 2026 "LLM-default design" criticism, BUT the Elixir/devtools space has near-zero saturation, and its quirky w/k/g letterforms are the best available raw material for wake-angle cuts. Font question CLOSES at 102 ratification.
- **D-11:** **TIGHTEN rider (mandatory, cascades to Phase 103):** custom `w`/`k` wake-angle cuts on the wordmark are NON-OPTIONAL — the final wordmark must not be typesettable in unmodified Space Grotesk. This converts a generic starting point into a proprietary endpoint.
- **D-12:** Latitude boundaries — **Frozen** (no change even at ratification): display font family, coastal-muted palette character (current/foam/wake/brass/rust families), wake-seam visual concept, diagonal crossing-mark direction. **Audit acts unilaterally:** math-forced hex additions/shifts (D-02), semantic role assignments, approved-pairings table, token naming/structure, type scale numbers, tracking, fallback stacks, gap-fill ADDs. **Requires AUDT-04 ratification:** any verdict touching what the wordmark/logo depends on (typography section, logo direction, approved colorways), any palette REWORK that shifts emotional character rather than fixing math, and the Phase 103 letter-cut brief (D-11) itself.

### Claude's Discretion
- AUDIT.md prose quality, section-by-section verdict calls within the latitude policy above, exact wording of ready-to-use copy blocks (§10 of the brief), the contrast script's output format, DTCG file organization details, and whether Stone 600 placement warrants any additional approved-pairing rows.
- Typography/spacing/radius/shadow/focus-ring token values: derive from brand book §9/§13 (type scale, 4px grid, 12–16px card radius); keep bounded.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Audit specification (the WHAT of AUDT-01)
- `.planning/phases/102-brand-audit-token-foundation/102-AUDIT-BRIEF.md` — the full 14-section audit output spec, decision framework, lenses, and behavior constraints. AUDIT.md MUST follow this structure.

### Audit subject + vision grounding
- `prompts/crosswake-brand-book.md` — the seed brand book under audit (25 sections; palette table §8, typography §9, logo direction §10, voice §6, microcopy §15)
- `prompts/crosswake-elixir-oss-dna.md` — szTheory house style the brand must serve (install truth, contract honesty, proof lanes)
- `prompts/crosswake-research-synthesis.md` — architecture story/vision the brand expresses
- `prompts/crosswake-integrations-and-companions.md` — suite context for the multi-library lens (§10 of brief)

### Milestone research (verified facts — do not re-research)
- `.planning/research/SUMMARY.md` — synthesis + phase implications
- `.planning/research/STACK.md` — opentype.js 2.0.0, font availability (Atkinson Hyperlegible Next CONFIRMED on Google Fonts), OFL verdict, DTCG 2025.10 syntax, WCAG formula, favicon/OG requirements, rsvg-convert
- `.planning/research/PITFALLS.md` — token naming churn, WCAG thresholds (4.5:1 text / 3:1 non-text UI), GitHub SVG sanitization, hex `:exclude_patterns`
- `.planning/research/ARCHITECTURE.md` — mix.exs `:files` allowlist (brandbook auto-excluded), v8.0 palette drift evidence (generator templates vs app.css), .gitignore additions, build order
- `.planning/research/FEATURES.md` — token/brand-book table stakes vs anti-features

### Existing brand surfaces (evidence for AUDT-03 drift flag)
- `examples/phoenix_host/assets/css/app.css` — the 16 shipped `--cw-*` variables (correct teal/brass palette)
- `priv/templates/crosswake/offline_ui/` — generator templates with divergent blue/amber Tailwind scale (flag, do not fix)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `examples/phoenix_host/assets/css/app.css`: 16 `--cw-*` custom properties matching the brand book palette — primitive names must stay compatible (D-05)
- Brand book §8 already specifies CSS variable names and §13 a type scale — tokens largely transcribe + restructure rather than invent

### Established Patterns
- Hermetic/advisory CI split is the house pattern (relevant to phase 106's advisory brandbook lane, not 102)
- `mix.exs` package `:files` is a strict allowlist — `brandbook/` is auto-excluded; no packaging work needed in 102

### Integration Points
- `brandbook/` is a NEW self-contained directory; 102 creates `brandbook/AUDIT.md`, `brandbook/tokens/`, `brandbook/tools/` (contrast.mjs, compile-tokens.js)
- `.gitignore` needs `/brandbook/tools/node_modules/` and `/brandbook/tools/fonts/` (can land in 102 since tools/ starts here)
- Size budget for ALL of brandbook/ across the milestone: <1 MB committed

</code_context>

<specifics>
## Specific Ideas

- "All killer no filler" — every audit recommendation must be value-tied; REWORKs carry stated costs
- Accessibility as a visible brand feature: contrast ratios printed next to pairings, matrix committed and reproducible
- The audit's §10 should produce READY-TO-USE copy blocks (taglines exist in seed: "Declare the crossing. Keep the boundary honest.")
- User profile: opinionated/minimal_decisive — AUDIT.md should be decisive, not hedge-everything

</specifics>

<deferred>
## Deferred Ideas

- **NORM-01** (v2 requirement, future milestone): normalize generator templates + example app CSS onto `brandbook/tokens/tokens.css` as single source of truth — 102 only flags the drift (AUDT-03)
- Multi-library suite brand rollout (sigra/parapet/threadline…): audit §10 of the brief notes suite implications only; no suite assets this milestone
- Landing page build: blueprint lives in AUDIT.md §11; actual site is a future milestone

</deferred>

---

*Phase: 102-brand-audit-token-foundation*
*Context gathered: 2026-06-11*
