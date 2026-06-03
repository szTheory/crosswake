---
phase: 56-step-up-intent-and-plug-liveview-ceremony
plan: "02"
subsystem: auth
tags: [sigra, step-up, ecto, phoenix-session, csrf, route-gate]
requires:
  - phase: 56-step-up-intent-and-plug-liveview-ceremony
    provides: [pure step-up contracts, auth.step_up_intent denial vocabulary]
provides:
  - Example-host Ecto step-up intent and audit tables
  - Server-owned issue, challenge, consume, cancel, revoke, replay, expiry, and projection proof path
  - Host-owned session renewal, CSRF rotation, transient cleanup, and LiveView invalidation instructions
affects: [phase-56, phase-58, sigra, phoenix-host-proof]
tech-stack:
  added: []
  patterns: [ecto-conditional-consume, manifest-route-target-validation, host-owned-session-renewal]
key-files:
  created:
    - examples/phoenix_host/lib/crosswake_example/saas_portal/step_up.ex
    - examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_intent.ex
    - examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_audit_event.ex
    - examples/phoenix_host/priv/repo/migrations/20260602070000_create_sigra_step_up_intents.exs
    - examples/phoenix_host/priv/repo/migrations/20260602070100_create_sigra_step_up_audit_events.exs
  modified:
    - examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex
    - test/crosswake/proof/phase56_step_up_ceremony_test.exs
key-decisions:
  - "The example host rejects raw return_to during step-up issue as auth.step_up_intent.invalid_intent and only stores manifest route IDs."
  - "Step-up consume validates projection and return-route authority before the conditional consume update so projection failures do not grant renewal instructions."
  - "Host session renewal accepts only explicit crosswake_session_ref and crosswake_session_version keys from successful StepUpCompletion instructions."
patterns-established:
  - "Step-up lifecycle transitions are persisted in host Ecto tables and audited as append-only evidence."
  - "Signed step-up locators are Phoenix.Token transport artifacts, not authority-bearing records."
requirements-completed: [STEP-01, STEP-03]
duration: 7 min
completed: 2026-06-02
---

# Phase 56 Plan 02: Example-Host Step-Up Intent Storage, Consume, And Renewal Summary

**Ecto-backed step-up intent issue and one-time consume flow with backend authority projection and host session renewal instructions**

## Performance

- **Duration:** 7 min
- **Started:** 2026-06-02T07:43:04Z
- **Completed:** 2026-06-02T07:50:08Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added `sigra_step_up_intents` and `sigra_step_up_audit_events` schemas/migrations in the Phoenix example host.
- Implemented `StepUp.issue/1`, `challenge/2`, `consume/2`, `cancel/2`, and `revoke/2` with manifest route validation and server-record lifecycle truth.
- Extended `CrosswakeExample.SaaSPortal.Auth` with `apply_step_up_completion/2` for host-owned session renewal, CSRF token deletion, transient cleanup, and explicit session key writes.
- Expanded the Phase 56 proof to cover issue, signed locator payload safety, challenge, one-time consume, replay, expiry, cancel, revoke, binding mismatch, return-route mismatch, projection failure, audit rows, and session renewal.

## Task Commits

Each task was committed atomically:

1. **Task 56-02-01: Add example-host step-up intent and audit persistence** - `ad1ee4f` (feat)
2. **Task 56-02-02: Implement one-time consume, projection, audit, and host renewal instructions** - `ad1ee4f` (feat)

**Plan metadata:** committed with this summary.

## Files Created/Modified

- `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up.ex` - Host step-up issue/challenge/consume/cancel/revoke workflow.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_intent.ex` - Ecto schema for authoritative step-up intent records.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_audit_event.ex` - Ecto schema for append-only step-up lifecycle evidence.
- `examples/phoenix_host/priv/repo/migrations/20260602070000_create_sigra_step_up_intents.exs` - Intent table and indexes.
- `examples/phoenix_host/priv/repo/migrations/20260602070100_create_sigra_step_up_audit_events.exs` - Audit table and indexes.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex` - Step-up completion application helper.
- `test/crosswake/proof/phase56_step_up_ceremony_test.exs` - Hermetic example-host proof script.

## Decisions Made

Projection is built and route-gate-checked before the conditional consume update. This keeps projection failures from consuming an intent or returning renewal instructions, while still recording denied audit evidence.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

The proof caught two implementation issues: `String.to_existing_atom/1` rejected the host challenge kind in a fresh example-host runtime, and projection denials were initially collapsed by the outer `with` fallback. Both were fixed before commit.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/crosswake/proof/phase56_step_up_ceremony_test.exs --trace` - passed, 6 tests.
- `cd examples/phoenix_host && mix compile --warnings-as-errors` - passed.

## Next Phase Readiness

Wave 3 can add the shared ceremony decision core and thin Plug/LiveView adapters on top of the working host issue/consume path.

---
*Phase: 56-step-up-intent-and-plug-liveview-ceremony*
*Completed: 2026-06-02*
