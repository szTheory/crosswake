---
gsd_state_version: 1.0
milestone: v3.2
milestone_name: Commerce And Entitlement Seams
status: completed
stopped_at: Phase 20 context gathered
last_updated: "2026-05-27T09:48:02.496Z"
last_activity: 2026-05-27
progress:
  total_phases: 4
  completed_phases: 1
  total_plans: 3
  completed_plans: 3
  percent: 25
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-27)

**Core value:** Make runtime boundaries explicit so Phoenix teams can ship credible mobile apps without hiding the tradeoffs between LiveView, offline, and native ownership.
**Current focus:** Phase 20 — entitlement-lifecycle-semantics

## Current Position

Phase: 20
Plan: Not started
Status: Phase 19 complete (19-01, 19-02, 19-03 complete); ready to begin Phase 20
Last activity: 2026-05-27

Progress: [##########] 100%

## Performance Metrics

**Velocity:**

- Total plans completed: 36
- Average duration: n/a
- Total execution time: n/a

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 19. Commerce Route Corridors | 3 | 18 min | 6 min |
| 20. Entitlement Lifecycle Semantics | 0 | n/a | n/a |
| 21. Reconciliation Example | 0 | n/a | n/a |
| 22. Commerce Support, Review, And Proof | 0 | n/a | n/a |
| 19 | 3 | - | - |

**Recent Trend:**

- Last milestone shipped: v3.1 Native Capabilities and Bridge Expansion on 2026-05-27
- Current milestone: v3.2 Commerce And Entitlement Seams
- Trend: Positive

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Milestone v3.1 shipped with the first low-frequency bounded capability families and closed Phase 18 CI proof.
- Milestone v3.2 treats Phase 13 commerce vocabulary as substrate and focuses on operationalizing route corridors, lifecycle semantics, reconciliation examples, and support truth.
- Entitlement truth remains Phoenix/backend-owned; StoreKit, Play Billing, and provider SDK events are evidence inputs.
- Provider-specific billing adapters remain companion/future work, not core scope.
- Phase 19 Plan 01 established canonical corridor profile declarations and root manifest `commerce_corridors` with route `corridor_ref` linkage.
- Manifest schema stays `1.0.0`; corridor fields are additive and enforced only on routes that declare commerce.
- Phase 19 Plan 02 established canonical `commerce.corridor.*` denial codes under `:commerce_corridor` and fail-closed activation enforcement.
- Corridor denials now carry explicit `return_to_phoenix_guidance` plus corridor declaration recovery actions instead of silent fallback.
- Phase 19 Plan 03 synchronized commerce corridor support truth across support matrix, doctor human/json output, and public guides with canonical taxonomy parity tests.

### Pending Todos

- Start Phase 20 planning/execution for entitlement lifecycle semantics (`ENTL-01`, `ENTL-02`, `ENTL-03`).
- Decide whether future proof lanes should split JVM/unit checks from emulator-backed connected checks across separate workflows.

### Blockers/Concerns

- This local workstation still lacks a Java runtime, so Android JVM evidence should continue to come from CI unless Java is installed locally.
- StoreKit and Play Billing proof should remain advisory until a provider adapter milestone intentionally ships native/provider code.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Integrations | First-party companion integrations remain deferred until the commerce seam is operational and support truth is stable | Deferred | 2026-05-27 |
| Commerce | StoreKit, Play Billing, RevenueCat, Accrue, or other provider adapters remain deferred to companion/future milestones | Deferred | 2026-05-27 |
| Platform | Desktop packaging remains out of the near-term arc | Deferred | 2026-05-19 |
| Human UAT | Phase 15 device checks for share sheet presentation, physical haptics feedback, and app-info runtime fidelity remain human-needed | Deferred | 2026-05-27 |

## Session Continuity

Last session: 2026-05-27T09:48:02.494Z
Stopped at: Phase 20 context gathered
Resume file: .planning/phases/20-entitlement-lifecycle-semantics/20-CONTEXT.md
