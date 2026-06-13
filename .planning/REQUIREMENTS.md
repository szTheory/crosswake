# Requirements: Crosswake — v10.0 Brand Normalization

**Defined:** 2026-06-13
**Core Value:** Make `brandbook/tokens/tokens.css` the genuine single source of truth for the brand system — consumed by the generator templates and the example host via semantic CSS custom properties — and mechanically forbid drift.

## v1 Requirements

Requirements for milestone v10.0. Each maps to exactly one roadmap phase.

### Token Source

Extends the v9.0 DTCG token system (TOKN-01..03) so `tokens.css` covers everything its consumers need, not just color.

- [ ] **TOKN-04**: `brandbook/tools/compile-tokens.js` emits the `font.*` family tokens (`--cw-font-display`, `--cw-font-body`, `--cw-font-mono`) into `tokens.css` from `crosswake.tokens.json`, so typography is no longer a second hand-maintained source of truth.
- [ ] **TOKN-05**: `compile-tokens.js` emits the `dimension.*` tokens that consumers actually reference (type scale and any spacing/radius used by the host page and offline UI) into `tokens.css`, generated from `crosswake.tokens.json`.

### Consumer Normalization

- [ ] **NORM-01**: `examples/phoenix_host` CSS consumes the semantic token tier from `tokens.css` (`var(--cw-surface-default)`, `var(--cw-text-default)`, `var(--cw-action-bg)`, font tokens…) with no duplicated flat palette and no inline font stacks, and renders correctly in both light and dark mode.
- [ ] **NORM-02**: The `offline_ui` generator produces token-backed markup referencing the semantic tier instead of Tailwind utility classes, requiring no Tailwind dependency in the generated host. This covers both the `priv/templates/crosswake/offline_ui/*.eex` templates **and** the stale hardcoded Tailwind color theme emitted by `lib/mix/tasks/crosswake.gen.offline_ui.ex` (legacy blue `#699cc9` / amber `#e1b982`, ~lines 68-90) — the actual color source backing those templates.
- [ ] **NORM-03**: `tokens.css` reaches both consumers through one explicit, documented distribution mechanism, with no hand-edited duplicate palettes that can silently drift from the source.
- [ ] **NORM-04**: The `crosswake.gen.offline_ui` generator test (`test/mix/tasks/crosswake.gen.offline_ui_test.exs`) asserts the new token-backed contract (semantic token / class references) rather than the retired Tailwind class names.

### Drift Prevention

- [ ] **PROOF-01**: A deterministic structural check, extending the v9.0 `brand-structural` CI gate, fails the build when a normalized consumer contains a hardcoded brand hex value or stops referencing the token source.

## Future Requirements

Deferred to a later milestone. Tracked but not in this roadmap.

### Dashboard & Native

- **DASH-01**: Surface offline adoption and eviction metrics to the deferred `crosswake_dashboard` package.
- **NTV-01**: Extend storage budgets to use native iOS/Android bridge commands to calculate available physical disk space.

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Introducing Tailwind into `examples/phoenix_host` | The host carries no Tailwind dependency; normalization converts off Tailwind utility classes onto token-backed CSS, honoring the lean/zero-build posture. |
| Re-theming the standalone brand book HTML or ExDoc/README collateral | Those already consume the v9.0 token system; v10.0 is confined to the two drifted consumers (generator templates + example host). |
| Changing brand values (new colors, type, logo, or token names) | This is a wiring/normalization milestone, not a brand redesign; the v9.0 brand contract is frozen. |
| Restyling the demo app's product surface beyond token wiring | Scope is token consumption, not a UI redesign of the flashcard demo. |
| Pixel/font-level visual diffing as a merge gate | Stays in the advisory `brand-visual` tier per the v9.0 hermetic-vs-advisory split; only deterministic structural checks block merges. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| TOKN-04 | Phase 107 | Pending |
| TOKN-05 | Phase 107 | Pending |
| NORM-03 | Phase 107 | Pending |
| NORM-01 | Phase 108 | Pending |
| NORM-02 | Phase 108 | Pending |
| NORM-04 | Phase 108 | Pending |
| PROOF-01 | Phase 109 | Pending |
