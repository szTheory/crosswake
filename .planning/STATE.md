---
gsd_state_version: 1.0
milestone: v3.4
milestone_name: Commerce Archetype Proof
status: planning
last_updated: "2026-05-29T14:33:12.203Z"
last_activity: 2026-05-29 — Roadmap created for v3.4 (Phases 33-37, 14 requirements)
progress:
  total_phases: 5
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-29)

**Core value:** Make runtime boundaries explicit so Phoenix teams can ship credible mobile apps without hiding the tradeoffs between LiveView, offline, and native ownership.
**Current focus:** v3.4 Commerce Archetype Proof — Phase 33 ready to plan

## Current Position

Phase: 33 of 37 (Corridor Routes And CI Infrastructure)
Plan: —
Status: Ready to plan
Last activity: 2026-05-29 — Roadmap created for v3.4 (Phases 33-37, 14 requirements)

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**

- Total plans completed: 51 (v1.0–v3.3)
- Average duration: n/a
- Total execution time: n/a

**By Phase (v3.2):**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 19. Commerce Route Corridors | 3 | 18 min | 6 min |
| 23. Commerce Support And Proof Closure | 4 | n/a | n/a |
| 30. Hex Page Polish | 2 | - | - |

**Recent Trend:** Positive — v3.3 shipped cleanly; v3.4 roadmap ready

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.

- v3.4 phase ordering: routes + CI before MockStorefront; MockStorefront before LiveView; proof after final code; docs last (same phase as docs-contract test)
- v3.4 proof isolation: `async: false`, `Phase34`-prefixed fixture module names, `Code.require_file` at module scope only (mirrors phase21/phase23 discipline)
- v3.4 idempotency: `MockStorefront` must derive `provider_reference` from stable `entry_id`, not transient `correlation_id` (RECN-02 guardrail)
- v3.4 scope: zero new dependencies; reuse Phase 21 `ReconciliationInbox`, `EntitlementProjection`, `ReconciliationKeys` as-is; no ETS, no Ecto migrations in mock lane

### Pending Todos

- v3.4 Phase 33: Confirm whether `CrosswakeExample.PubSub` is already started in `application.ex`; if not, add it before Phase 35 LiveView wiring.
- v3.4 Phase 35: Decide verification simulation shape (inline in LiveView handler vs. separate context function) so proof test and example use the same construction path.
- Deferred from v3.3: Clean up ~150 ExDoc `@moduledoc false` hidden-type warnings (HEX-03 zero-warnings clause). Low priority for v3.4.

### Blockers/Concerns

- Android JVM evidence continues to require CI (no local Java runtime).
- StoreKit/Play Billing proof stays advisory; graduation to merge-blocking deferred to v3.6 (ADPT-01/02/03).

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Commerce | StoreKit, Play Billing, RevenueCat provider adapters | Deferred to v3.6 | 2026-05-27 |
| Docs | ExDoc zero-warnings clause (HEX-03) | Deferred to v3.4+ | 2026-05-29 |
| CI | Retroactive SHA-pinning of pre-v3.3 proof workflows | Deferred to v3.4+ | 2026-05-27 |
| Human UAT | Phase 15 device checks (share, haptics, app-info) | Acknowledged | 2026-05-27 |
| Tooling | `mix crosswake.doctor --check-publish` surface | Deferred to v3.4+ | 2026-05-27 |

## Session Continuity

Last session: 2026-05-29T14:33:12.200Z
Stopped at: Phase 33 context gathered
Resume file: .planning/phases/33-corridor-routes-and-ci-infrastructure/33-CONTEXT.md
