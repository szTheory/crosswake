---
phase: 56-step-up-intent-and-plug-liveview-ceremony
plan: "03"
subsystem: auth
tags: [sigra, step-up, plug, liveview, ceremony]
requires:
  - phase: 56-step-up-intent-and-plug-liveview-ceremony
    provides: [step-up contracts, example-host issue and consume flow]
provides:
  - Shared pure Sigra step-up ceremony decision core
  - Thin Plug and LiveView adapters that delegate auth semantics to the shared core
  - Proof that both adapters produce matching challenge facts without duplicated auth checks
affects: [phase-56, phase-58, sigra, phoenix-host-proof]
tech-stack:
  added: []
  patterns: [shared-ceremony-core, thin-transport-adapters, host-issued-challenge]
key-files:
  created:
    - lib/crosswake/companions/sigra/step_up_ceremony.ex
    - examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_plug.ex
    - examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_on_mount.ex
  modified:
    - test/crosswake/proof/phase56_step_up_ceremony_test.exs
key-decisions:
  - "Only insufficient-assurance and stale-auth :step_up_required denials are challengeable by the ceremony core; non-active, revoked, expired, or invalid contexts remain denials."
  - "Plug and LiveView adapters call StepUpCeremony.evaluate_or_issue/3 and only own redirect/halt mechanics plus host issue callback wiring."
  - "Challenge redirects expose support refs in host paths and do not carry raw return_to URLs."
patterns-established:
  - "Tests may pass evaluator_result into StepUpCeremony for pure branch proof while production calls Sigra.Evaluator directly."
  - "Host adapters convert Ecto intents back into pure StepUp contract structs before returning challenge outcomes."
requirements-completed: [STEP-02, STEP-03]
duration: 5 min
completed: 2026-06-02
---

# Phase 56 Plan 03: Shared Ceremony Core And Plug/LiveView Adapters Summary

**Shared Sigra ceremony core with Plug and LiveView adapters that fail closed into the same host-issued challenge flow**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-02T07:50:08Z
- **Completed:** 2026-06-02T07:55:05Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `Crosswake.Companions.Sigra.StepUpCeremony.evaluate_or_issue/3` as a pure decision layer over `Sigra.Evaluator`.
- Added `CrosswakeExample.SaaSPortal.StepUpPlug` and `StepUpOnMount` as transport-specific adapters that share the same ceremony call.
- Proved allow/challenge/deny ceremony branches, host-denial propagation, pure boundary constraints, adapter source constraints, and matching Plug/LiveView challenge facts.

## Task Commits

Each task was committed atomically:

1. **Task 56-03-01: Add shared Sigra step-up ceremony core** - `e50486e` (feat)
2. **Task 56-03-02: Add thin Plug and LiveView adapters over the shared ceremony** - `e50486e` (feat)

**Plan metadata:** committed with this summary.

## Files Created/Modified

- `lib/crosswake/companions/sigra/step_up_ceremony.ex` - Pure allow/challenge/deny ceremony core.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_plug.ex` - Plug redirect/halt adapter.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_on_mount.ex` - LiveView redirect/halt adapter.
- `test/crosswake/proof/phase56_step_up_ceremony_test.exs` - Ceremony and adapter proof coverage.

## Decisions Made

The ceremony core accepts an `:evaluator_result` option for pure tests, but production callers omit it and use `Sigra.Evaluator.evaluate_route_auth/3`.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

Initial proof assertions tried to compile the example router in the root app and matched contract field names as duplicated auth logic. The proof was corrected so root tests use a pure `RouteEntry` and example-router behavior stays inside the example-host script.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/crosswake/proof/phase56_step_up_ceremony_test.exs --trace` - passed, 9 tests.
- `cd examples/phoenix_host && mix compile --warnings-as-errors` - passed.

## Next Phase Readiness

Wave 4 can promote support-matrix, doctor, operator, and guide truth from "ceremony deferred" to "step-up ceremony shipped" while preserving Phase 57/58 non-claims.

---
*Phase: 56-step-up-intent-and-plug-liveview-ceremony*
*Completed: 2026-06-02*
