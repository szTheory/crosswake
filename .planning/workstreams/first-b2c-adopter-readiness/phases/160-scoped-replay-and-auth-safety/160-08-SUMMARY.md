---
phase: 160-scoped-replay-and-auth-safety
plan: "08"
subsystem: scoped replay privacy and validation
tags: [elixir, telemetry, doctor, safe-observation, privacy, replay]
requires:
  - phase: 160-04
    provides: legacy quarantine and exact-scope recovery
  - phase: 160-05
    provides: fenced replay lifecycle and halted-batch handling
  - phase: 160-06
    provides: typed Sigra authority admission
  - phase: 160-07
    provides: global replay idempotency protection
provides:
  - Revalidated SafeObservation projection boundary
  - Success-only telemetry, Logger, callback, and Doctor egress
  - Fresh same-tree Phase 160 validation evidence
affects: [scoped-replay, security-audit, first-adopter-proof]
tech-stack:
  added: []
  patterns: [constructor-round-trip validation, typed projection result, zero-egress invalid observation]
key-files:
  created:
    - .planning/phases/160-scoped-replay-and-auth-safety/160-08-SUMMARY.md
  modified:
    - lib/crosswake/offline/safe_observation.ex
    - lib/crosswake/offline/telemetry.ex
    - lib/crosswake/telemetry.ex
    - lib/crosswake/doctor/doctor.ex
    - .planning/phases/160-scoped-replay-and-auth-safety/160-VALIDATION.md
key-decisions:
  - "Every SafeObservation public projection reconstructs declared fields through the canonical constructor validation path."
  - "Operational egress pattern-matches typed successful projections; invalid observations return closed rule/path errors without emitting output."
  - "The final Phase 160 gate is current-tree evidence only; generated iOS remains non-passing and security requires an independent audit."
metrics:
  duration: 26m
  completed_date: 2026-08-02
  tasks_completed: 3
  files_modified: 10
status: complete
---

# Phase 160 Plan 08: Scoped Replay Egress Closure Summary

SafeObservation projections now reject forged public structs before operational output, and the full Phase 160 gate has fresh same-tree evidence without promoting iOS/device or security status.

## Tasks Completed

1. **Revalidate every SafeObservation projection at its public boundary**
   - Added `validate/1`, which rebuilds the declared struct map through `new/1`.
   - Changed telemetry, Logger, and Doctor projections to return typed `{:ok, projection}` or closed errors.
   - Added forged route, enum, readiness, measurement, nested-value, and extra-field coverage.

2. **Guard every production telemetry, Logger, and Doctor egress**
   - Offline callbacks run only after a successful telemetry projection.
   - Root telemetry skips `:telemetry.execute/3` and default Logger output for invalid observations.
   - Doctor returns no readiness map for forged input.

3. **Run the complete post-gap Phase 160 gate and reconcile validation**
   - Ran the complete fresh same-tree chain and updated `160-VALIDATION.md` from observed results.
   - Recorded all gap plans 160-04 through 160-08, SCOPE-01 through SCOPE-05, and T-160-01 through T-160-06.
   - Preserved TODO-002 and real adopter/device inputs as `unknown_blocking`.

## Verification

- Focused projection suite: 7 tests passed.
- Focused all-egress suite: 71 tests passed.
- Fresh final chain: 118 core tests, 15 Sigra contracts, 14 Phoenix local-first tests, 16 browser proofs, one generated-host proof, 36 planning/adoption tests, and formatting check passed.
- Generated iOS proof returned an asserted blocked/unavailable JSON prerequisite outcome; it remains non-passing.

## Commits

- `a5ac702e` — `test(160-08): add forged observation projection regressions`
- `909cff51` — `feat(160-08): revalidate safe observation projections`
- `180b3ef0` — `test(160-08): pin zero egress for forged observations`
- `df3a2a91` — `feat(160-08): guard production observation egress`
- `b303b326` — `style(160-08): format phase gate test files`
- `1b4a8222` — `docs(160-08): record fresh phase validation gate`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Formatted files named by the final gate**
- **Found during:** Task 3
- **Issue:** The final scoped formatter check found two new forged-observation tests and the existing Plan 160-07 idempotency test unformatted.
- **Fix:** Applied the project formatter, then reran the full chain from the beginning.
- **Files modified:** `test/crosswake/offline/safe_observation_test.exs`, `test/crosswake/telemetry_test.exs`, `examples/phoenix_host/test/crosswake_example/local_first/study_test.exs`
- **Commit:** `b303b326`

## Known Stubs

None. Existing doctor placeholder-detection code is not a stub and was not introduced or changed by this plan.

## Security and External Boundaries

- `160-SECURITY.md` was not edited or self-approved. An independent `$gsd-secure-phase 160` audit remains required.
- TODO-002 and real adopter scope, route, flag, session, adapter, and physical-iPhone evidence remain `unknown_blocking`.
- The generated iOS prerequisite remains explicitly non-passing.

## Self-Check: PASSED

- Verified all five runtime files and `160-VALIDATION.md` exist.
- Verified the six task commits listed above exist in git history.
- No new stubs, skipped tests, or unrun planned verification remain.
