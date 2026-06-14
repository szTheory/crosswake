# Roadmap: Crosswake

## Milestones

- ✅ **v8.0 Offline Sync Hardening and UI Polish** — Phases 99-101 (shipped 2026-06-11)
- ✅ **v9.0 Brand System & Visual Identity** — Phases 102-106 (shipped 2026-06-13)
- **v10.0 Brand Normalization** — Phases 107-109 (active)

## Phases

<details>
<summary>✅ v8.0 Offline Sync Hardening and UI Polish (Phases 99-101) — SHIPPED 2026-06-11</summary>

- [x] Phase 99: Real Network-Toggling E2E Tests (2/2 plans) — completed 2026-06-11
- [x] Phase 100: Storage Budget Enforcement (2/2 plans) — completed 2026-06-11
- [x] Phase 101: Offline UI Consolidation & Polish (2/2 plans) — completed 2026-06-11

</details>

<details>
<summary>✅ v9.0 Brand System & Visual Identity (Phases 102-106) — SHIPPED 2026-06-13</summary>

- [x] Phase 102: Brand Audit & Token Foundation (4/4 plans) — completed 2026-06-12
- [x] Phase 103: Logo Tournament (4/4 plans) — completed 2026-06-12
- [x] Phase 104: Logo Refinement & Production Suite (3/3 plans) — completed 2026-06-12
- [x] Phase 105: HTML Brand Book (3/3 plans) — completed 2026-06-12
- [x] Phase 106: Collateral, Integration & Closeout (2/2 plans) — completed 2026-06-13

Full phase detail archived in `.planning/milestones/v9.0-ROADMAP.md`.

</details>

**v10.0 Brand Normalization (Phases 107-109)**

- [x] **Phase 107: Token Source & Distribution** — Extend compile-tokens.js to emit font and dimension tokens; document the one distribution mechanism (completed 2026-06-13)
- [x] **Phase 108: Consumer Normalization** — Rewire app.css and offline_ui templates off duplicated values onto semantic tokens; update generator test contract (completed 2026-06-14)
- [ ] **Phase 109: Drift-Prevention Gate** — Extend brand-structural CI to block on hardcoded hex and missing token references in normalized consumers

## Phase Details

### Phase 107: Token Source & Distribution
**Goal**: `tokens.css` covers everything its consumers need — font families, type scale, spacing, radius — all generated from `crosswake.tokens.json`, and one documented distribution path connects that file to every consumer.
**Depends on**: Nothing (first phase of v10.0)
**Requirements**: TOKN-04, TOKN-05, NORM-03
**Success Criteria** (what must be TRUE):
  1. Running `node brandbook/tools/compile-tokens.js` produces `tokens.css` that contains `--cw-font-display`, `--cw-font-body`, and `--cw-font-mono` properties — no hand-edited font stacks exist anywhere outside this file.
  2. Running `compile-tokens.js` also emits dimension tokens for type scale (`--cw-text-scale-*`), display scale (`--cw-display-scale-*`), radius (`--cw-radius-*`), and any other dimension values the host page and offline UI consume — all derived from `crosswake.tokens.json`.
  3. There is exactly one documented distribution mechanism describing how `tokens.css` reaches the example host and the generated offline UI templates — no other copy or re-declaration of brand values is required.
  4. A developer can verify the token source is current by running one command with no build toolchain beyond Node; the output file is the sole source that downstream consumers wire against.
**Plans**: 3 plans
  - [x] 107-01-PLAN.md — Generator emits font + dimension tokens and writes the packaged priv/static/crosswake/tokens.css mirror
  - [x] 107-02-PLAN.md — Vendor-by-copy + link distribution into the offline_ui generator and the example host
  - [x] 107-03-PLAN.md — Write the single distribution guide (guides/tokens.md) and register it in mix.exs extras

### Phase 108: Consumer Normalization
**Goal**: Both drifted consumers — the example host CSS and the offline UI generator templates — reference semantic token custom properties exclusively, with no duplicated flat palette, no inline font stacks, and no Tailwind utility classes; the generator test reflects the new contract.
**Depends on**: Phase 107
**Requirements**: NORM-01, NORM-02, NORM-04
**Success Criteria** (what must be TRUE):
  1. `examples/phoenix_host/assets/css/app.css` references semantic tokens (`var(--cw-surface-default)`, `var(--cw-text-default)`, `var(--cw-action-bg)`, `var(--cw-font-body)`, etc.) with zero hand-declared hex values and zero duplicated flat primitive aliases — dark mode works without any extra CSS in `app.css`.
  2. The generated `offline_page.html.heex` and `offline_root.html.heex` contain no Tailwind utility classes and no Tailwind color references; all visual styling is expressed through token-backed inline styles or a host-owned CSS class that references semantic custom properties.
  3. The generated offline UI requires no Tailwind dependency installed in the host project to render correctly.
  4. `test/mix/tasks/crosswake.gen.offline_ui_test.exs` asserts the presence of semantic token references (e.g., `var(--cw-surface-default)`) and the absence of retired Tailwind class names (`flex`, `bg-white`, `text-cw-*`) in the generated output.
**Plans**: 4 plans
- [x] 108-01-PLAN.md — Normalize the example host SERVED app.css + reconcile the unserved duplicate + restyle the example offline page onto semantic tokens (NORM-01) [wave 1]
- [x] 108-02-PLAN.md — Author vendored offline.css + rewrite offline_ui templates off Tailwind + vendor it (no-clobber) and retire the stale theme in the generator (NORM-02) [wave 1]
- [x] 108-03-PLAN.md — Rewrite the generator test to the semantic-token contract (NORM-04) [wave 2]
- [x] 108-04-PLAN.md — D-13 render-verify release gate: browser-render example host + generated offline page in light/dark, remediate any D-06 contrast failure, human sign-off (NORM-01, NORM-02) [wave 3]
**UI hint**: yes

### Phase 109: Drift-Prevention Gate
**Goal**: The v9.0 `brand-structural` CI gate is extended so any future commit that reintroduces a hardcoded brand hex or drops a token reference in a normalized consumer fails the build automatically.
**Depends on**: Phase 108
**Requirements**: PROOF-01
**Success Criteria** (what must be TRUE):
  1. The `brand-structural` CI check fails (non-zero exit) when a normalized consumer file (`app.css`, the offline UI templates) contains a bare hex value matching any brand color.
  2. The `brand-structural` CI check fails when a normalized consumer no longer contains any `var(--cw-` reference, detecting a regression to hard-coded values.
  3. The check runs without a browser or pixel-rendering engine; it is purely textual/structural and deterministic across Linux CI and macOS, consistent with the required-vs-advisory split established in v9.0.
  4. A developer can run the same check locally with one command and get the identical pass/fail result that CI produces.
**Plans**: 3 plans
- [x] 109-01-PLAN.md — Create check-consumer-drift.mjs: curated 5-consumer manifest + detection (hex/primitive/lost-var/retired-Tailwind) with exported check functions; green baseline runner [wave 1]
- [ ] 109-02-PLAN.md — Contract/pin test check-consumer-drift.test.mjs: manifest completeness + per-SC synthetic fixtures + false-positive guards + green-baseline integration assertion [wave 2]
- [ ] 109-03-PLAN.md — Wire the gate into brand-structural (new step before Playwright install) and broaden on.paths with the 4 consumer globs [wave 2]

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 99. Real Network-Toggling E2E Tests | v8.0 | 2/2 | Complete | 2026-06-11 |
| 100. Storage Budget Enforcement | v8.0 | 2/2 | Complete | 2026-06-11 |
| 101. Offline UI Consolidation & Polish | v8.0 | 2/2 | Complete | 2026-06-11 |
| 102. Brand Audit & Token Foundation | v9.0 | 4/4 | Complete | 2026-06-12 |
| 103. Logo Tournament | v9.0 | 4/4 | Complete | 2026-06-12 |
| 104. Logo Refinement & Production Suite | v9.0 | 3/3 | Complete | 2026-06-12 |
| 105. HTML Brand Book | v9.0 | 3/3 | Complete | 2026-06-12 |
| 106. Collateral, Integration & Closeout | v9.0 | 2/2 | Complete | 2026-06-13 |
| 107. Token Source & Distribution | v10.0 | 3/3 | Complete    | 2026-06-13 |
| 108. Consumer Normalization | v10.0 | 4/4 | Complete    | 2026-06-14 |
| 109. Drift-Prevention Gate | v10.0 | 1/3 | In Progress|  |
