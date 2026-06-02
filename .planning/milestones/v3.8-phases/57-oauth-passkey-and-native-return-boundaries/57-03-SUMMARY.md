---
phase: 57-oauth-passkey-and-native-return-boundaries
plan: "03"
subsystem: auth
tags: [sigra, ecto, example-host, audit, session-authority]
requires:
  - phase: 57-oauth-passkey-and-native-return-boundaries
    provides: [AuthReturn pure contracts and denial vocabulary]
provides:
  - Example-host auth-return attempt and audit schemas
  - Example-host migrations for replay, expiry, lifecycle, binding, projection, and audit fields
  - Proof that callback, passkey, native link, and bridge evidence cannot complete without backend authority projection
affects: [phase-57, phase-58, example-host, sigra]
tech-stack:
  added: [Ecto schemas in example host]
  patterns: [host-owned-transaction-shape, replay-source-of-truth, evidence-only-client-return]
key-files:
  created:
    - examples/phoenix_host/lib/crosswake_example/saas_portal/auth_return_attempt.ex
    - examples/phoenix_host/lib/crosswake_example/saas_portal/auth_return_audit_event.ex
    - examples/phoenix_host/priv/repo/migrations/20260602080000_create_sigra_auth_return_attempts.exs
    - examples/phoenix_host/priv/repo/migrations/20260602080100_create_sigra_auth_return_audit_events.exs
  modified:
    - test/crosswake/proof/phase57_auth_return_boundaries_test.exs
key-decisions:
  - "Host-owned attempt records are the replay, expiry, revocation, binding, audit, and promotion source of truth."
  - "Promotion requires a host transaction that consumes the attempt, writes audit evidence, projects SessionAuthorityLane, and returns renewal instructions."
  - "Core Crosswake remains pure; Ecto, Repo transactions, provider verification, and session mutation stay host-owned."
requirements-completed: [RETN-02, RETN-03]
duration: 27 min
completed: 2026-06-02
---

# Phase 57 Plan 03: Host-Owned Attempt, Audit, And Promotion Proof Summary

**Example-host server-record proof for auth-return replay, audit, and backend promotion authority**

## Performance

- **Duration:** 27 min
- **Started:** 2026-06-02T10:21:00Z
- **Completed:** 2026-06-02T10:48:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added example-host `AuthReturnAttempt` schema for host-owned replay, expiry, revocation, binding, validation posture, return params, projection facts, and lifecycle state.
- Added example-host `AuthReturnAuditEvent` schema for append-only promotion/denial audit evidence.
- Added migrations with unique attempt/event indexes and lookup indexes for lifecycle, expiry, route, session, and audit correlation.
- Proved that OAuth callback evidence, passkey assertion evidence, native deep-link evidence, and bridge-event evidence cannot construct completion alone.
- Proved completion requires backend-projected `SessionAuthorityLane` and session renewal instructions.

## Task Commits

1. **Task 57-03-01: Lock example-host attempt and audit persistence shape** - `4b9d19b` (feat)
2. **Task 57-03-02: Prove backend promotion requirements without provider or shell authority** - `4b9d19b` (feat)

## Files Created/Modified

- `examples/phoenix_host/lib/crosswake_example/saas_portal/auth_return_attempt.ex` - Host-owned attempt schema.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/auth_return_audit_event.ex` - Host-owned audit schema.
- `examples/phoenix_host/priv/repo/migrations/20260602080000_create_sigra_auth_return_attempts.exs` - Attempt table and indexes.
- `examples/phoenix_host/priv/repo/migrations/20260602080100_create_sigra_auth_return_audit_events.exs` - Audit table and indexes.
- `test/crosswake/proof/phase57_auth_return_boundaries_test.exs` - Host-owned attempt and completion proof.

## Decisions Made

No new decisions beyond the locked Phase 57 context. Implementation followed D-11, D-14 through D-19, D-39, D-40, and D-42.

## Deviations from Plan

Implementation was committed as one integrated Phase 57 production commit because the proof file spans route policy, contracts, host persistence, and support truth.

---

**Total deviations:** 1 documentation/commit-shaping deviation.
**Impact on plan:** No behavior or scope change.

## Issues Encountered

None.

## User Setup Required

None.

## Verification

- `mix test test/crosswake/proof/phase57_auth_return_boundaries_test.exs --trace` - passed, 8 tests.
- `cd examples/phoenix_host && mix compile --warnings-as-errors` - passed.
- `mix test` - passed, 660 tests, 0 failures, 2 excluded.

## Next Phase Readiness

Ready for Plan 57-04 support, doctor, operator, guide, and proof truth.

