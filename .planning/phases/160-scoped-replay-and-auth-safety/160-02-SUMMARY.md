---
phase: 160-scoped-replay-and-auth-safety
plan: "02"
subsystem: scoped replay admission
tags: [phoenix, ecto, playwright, sigra, idempotency]
requires:
  - phase: 160-01
    provides: exact-scope browser partitions and active scope leases
provides:
  - ordered fail-closed host admission for scoped Study events
  - scope-qualified exactly-once ReviewEvent transaction semantics
  - closed Sigra replay allow/deny projection
affects: [160-03, replay-evidence, first-adopter-proof]
tech-stack:
  added: []
  patterns: [per-event authority resolution, Ecto.Multi idempotency boundary, closed denial classes]
key-files:
  created:
    - examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex
    - examples/phoenix_host/priv/repo/migrations/20260802160000_scope_review_events.exs
    - examples/phoenix_host/test/crosswake_example/local_first/replay_admission_test.exs
  modified:
    - examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex
    - examples/phoenix_host/lib/crosswake_example/local_first/study.ex
    - examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex
    - examples/phoenix_host/e2e/offline_sync.spec.ts
    - examples/phoenix_host/e2e/support/offline_route_proof.ts
    - packages/crosswake_sigra/lib/crosswake/companions/sigra.ex
key-decisions:
  - "Each replay event resolves host session, scope, route, feature, Sigra, and domain authority in order immediately before mutation."
  - "Review-event idempotency is qualified by opaque scope and commits with its domain effect in one transaction."
  - "Sigra projects backend authority to only allow or the safe sigra_denied class."
metrics:
  duration: "31m"
  completed: "2026-08-02"
status: complete
---

# Phase 160 Plan 02: Scoped Replay Admission Summary

One exact-scope browser Study event now passes fresh host authority checks and commits exactly once with a scope-qualified idempotency boundary.

## Completed Tasks

1. Replaced bulk replay insertion with ordered per-event admission and an atomic Ecto.Multi Study effect.
2. Added host integration coverage for denial, authority changes, rollback, and accepted retry behavior.
3. Added Sigra’s narrow replay decision projection with no authority-detail return path.

## Verification

- `npm run proof:offline-island -- --grep "fully authorized scoped Study event"` — passed (1 Playwright test).
- `MIX_ENV=test mix test test/crosswake_example/local_first/replay_admission_test.exs test/crosswake_example/local_first/sync_controller_test.exs test/crosswake_example/local_first/study_test.exs` — passed (8 tests).
- `cd packages/crosswake_sigra && mix test test/crosswake/companions/sigra/contracts_test.exs` — passed (13 tests) after resolving its declared test dependencies.

## Decisions Made

- Host-owned synthetic fixture configuration remains separate from adopter route input and does not create account or credential authority.
- A wholly blocked request returns a typed non-success envelope; a later denial after accepted events returns a successful typed halted batch.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Updated the browser proof reader to use the scoped IndexedDB store.
- **Found during:** Task 1 verification
- **Issue:** The reader still opened the legacy `mutations` store after Plan 01 moved the outbox to `scoped_mutations`.
- **Fix:** Read the scoped store and its exact-scope index.
- **Files modified:** `examples/phoenix_host/e2e/support/offline_route_proof.ts`
- **Commit:** c4a9b8d6

## Known Stubs

None.

## Self-Check: PASSED

- Required host admission, migration, tests, and Sigra projection files exist.
- Task commits `d9f34b50`, `9f2df209`, `c4d26242`, and `c4a9b8d6` exist in git history.
