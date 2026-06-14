---
gsd_state_version: 1.0
milestone: v10.0
milestone_name: Brand Normalization
status: planning
last_updated: "2026-06-14T04:54:53.495Z"
last_activity: 2026-06-14
progress:
  total_phases: 3
  completed_phases: 2
  total_plans: 7
  completed_plans: 7
  percent: 67
---

# Project State: Crosswake

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-13)

**Core value:** Make `brandbook/tokens/tokens.css` the genuine single source of truth for the brand system — consumed by the generator templates and the example host via semantic CSS custom properties — and mechanically forbid drift.
**Current focus:** Phase 109 — drift prevention gate

## Current Position

Phase: 109
Plan: Not started
Status: Ready to plan
Last activity: 2026-06-14

```
v10.0 Progress [░░░░░░░░░░░░░░░░░░░░] 0% (0/3 phases)
Phase 107 ░░░  Phase 108 ░░░  Phase 109 ░░░
```

## Performance Metrics

**Velocity:**

- Total plans completed: 7
- Average duration: —
- Total execution time: —

*Updated after each plan completion*

## Accumulated Context

### Decisions

- v9.0 brand contract is frozen; v10.0 is wiring-only, not a redesign
- compile-tokens.js currently emits only color groups; font.* and dimension.* tokens exist in the JSON but are silently dropped — TOKN-04/05 fix this
- app.css duplicates the entire primitive palette as flat aliases without the `primitive.` namespace prefix (e.g., `--cw-foam-50` not `--cw-primitive-foam-50`) and hand-declares font stacks — these must be removed, not just augmented
- offline_ui templates use Tailwind utility classes and Tailwind color references (`text-cw-current-950`, `bg-cw-foam-50`) — no Tailwind dependency exists in the generated host; NORM-02 converts these to token-backed markup
- Distribution mechanism (NORM-03) is documented as part of Phase 107, not a separate phase — it is the contract the consumer phases wire against
- PROOF-01 is purely textual/structural (grep-style); it stays in the required `brand-structural` gate, not the advisory `brand-visual` tier — consistent with v9.0 hermetic-vs-advisory split
- brandbook/ remains excluded from the Hex package (v9.0 decision, unchanged)
- Zero new build toolchain: Node for compile-tokens.js only; no Tailwind, no bundler introduced in the host

### Pending Todos

None.

### Blockers/Concerns

- Phase 108 (NORM-02) must fix THREE drifted consumers, not two: the worst is `lib/mix/tasks/crosswake.gen.offline_ui.ex` (~lines 68-90), which emits a hardcoded Tailwind theme on a fully stale legacy palette (blue `#699cc9` / amber `#e1b982`) — not canonical teal `#2B756A` / brass `#C98A2E`. This `.ex`-emitted theme is the real color source backing the `.eex` templates' utility classes, so retiring the templates' Tailwind classes without also retiring this emitted theme would leave dead drift behind.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| v8.0 gap | Phase 81 verification gap (human_needed, carried from v5.1) | Acknowledged | v8.0 close |
| v8.0 gap | `tighten-validation-ledger-closeout-gate` quick task | Acknowledged | v8.0 close |
| v8.0 gap | DASH-01: Surfacing offline adoption metrics | Deferred | v8.0 close |
| v8.0 gap | NTV-01: Extend storage budgets to native physical disk space | Deferred | v8.0 close |

## Session Continuity

Last session: 2026-06-14T04:54:53.489Z
Stopped at: Phase 109 context gathered
Resume file: .planning/phases/109-drift-prevention-gate/109-CONTEXT.md

## Operator Next Steps

- Run `/gsd:plan-phase 107` to plan Phase 107: Token Source & Distribution
