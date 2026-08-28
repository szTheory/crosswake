---
phase: 162-physical-iphone-adoption-proof
plan: "02"
subsystem: testing
tags: [phoenix, ecto, replay-admission, proof-lane, typescript]
requires:
  - phase: 162-01
    provides: Closed physical-iPhone assertion vocabulary and preflight contract
provides:
  - Host-owned generated Phoenix authority fixture contract with closed observations
  - Example-host replay authority matrix for idempotency, recovery retention, scope fencing, and disablement
  - Local-only typed browser observation callbacks
affects: [162-physical-iphone-adoption-proof, physical proof driver, generated Phoenix hosts]
tech-stack:
  added: []
  patterns: [host-owned authority callbacks, closed backend observations, transaction-backed replay fixtures]
key-files:
  created:
    - examples/phoenix_host/test/crosswake_example/local_first/physical_iphone_authority_test.exs
  modified:
    - priv/templates/crosswake/proof_lane/test/crosswake_proof_lane_test.exs.eex
    - priv/templates/crosswake/proof_lane/e2e/support/proof_lane_host_adapter.ts.eex
    - test/crosswake/proof_lane/template_contract_test.exs
key-decisions:
  - "Generated host tests require closed callback results and fail with PL-PHOENIX-HOST-AUTHORITY when the host adapter is missing, malformed, or raises."
  - "Phoenix authority output is limited to fixed assertion IDs and outcomes; private fixture values stay inside the test process."
patterns-established:
  - "Host fixtures exercise ReplayAdmission, SyncController, Study, and Repo directly; browser/device observations cannot author backend outcomes."
requirements-completed: [DEVICE-02, DEVICE-03, DEVICE-04, DEVICE-05]
coverage:
  - id: D1
    description: Generated host authority fixture requires closed backend callback coverage.
    requirement: DEVICE-02
    verification:
      - kind: unit
        ref: mix test test/crosswake/proof_lane/template_contract_test.exs --max-failures 1
        status: pass
    human_judgment: false
  - id: D2
    description: Example Phoenix host proves exactly-once replay, retained recovery, scope fencing, and feature denial.
    requirement: DEVICE-03
    verification:
      - kind: integration
        ref: examples/phoenix_host/test/crosswake_example/local_first/physical_iphone_authority_test.exs
        status: pass
      - kind: integration
        ref: examples/phoenix_host/test/crosswake_example/local_first/sync_controller_test.exs
        status: pass
      - kind: integration
        ref: examples/phoenix_host/test/crosswake_example/local_first/replay_auth_test.exs
        status: pass
    human_judgment: false
  - id: D3
    description: Browser host adapter is restricted to typed local queue, lifecycle, and recovery observations.
    requirement: DEVICE-05
    verification:
      - kind: other
        ref: npm run typecheck:offline-route-proof
        status: pass
    human_judgment: false
metrics:
  duration: 22min
  completed: 2026-08-04
status: complete
---

# Phase 162 Plan 02: Phoenix Authority Fixture Summary

**Closed generated host callbacks and a transaction-backed Phoenix matrix independently prove replay admission, exactly-once effects, retained recovery, scope fencing, and feature disablement.**

## Performance

- **Duration:** 22 min
- **Completed:** 2026-08-04T21:28:01Z
- **Tasks:** 2/2
- **Files modified:** 4

## Accomplishments

- Added a fail-closed generated ExUnit host-adapter contract covering accepted/duplicate replay, retained rejection/conflict, scope and logout fences, and separate entry/replay disablement.
- Added an executable example-host authority fixture that uses real current admission and Ecto persistence, preserving one effect across a lost-response duplicate.
- Added typed browser callbacks for local queue, lifecycle, and recovery observations without Phoenix outcome setters or payload-bearing methods.

## Task Commits

1. **Task 1: Generate a closed host authority and fixture contract** — `f89a4a10` (test), `ec2d9d2b` (feat)
2. **Task 2: Prove the generated authority matrix against the example Phoenix host** — `aaa598cb` (test), `25900038` (feat)

## Files Created/Modified

- `priv/templates/crosswake/proof_lane/test/crosswake_proof_lane_test.exs.eex` — generated host callback contract and closed assertion report.
- `test/crosswake/proof_lane/template_contract_test.exs` — contract coverage for the generated Phoenix fixture seam.
- `examples/phoenix_host/test/crosswake_example/local_first/physical_iphone_authority_test.exs` — real Phoenix admission and transaction matrix.
- `priv/templates/crosswake/proof_lane/e2e/support/proof_lane_host_adapter.ts.eex` — typed local-only browser observations.

## Decisions Made

- Callback results are strict aggregate maps; missing callbacks, exceptions, and malformed results fail closed rather than skipping a backend assertion.
- The generated browser adapter can observe device-local state only. Phoenix retains all admission and outcome authority.

## Deviations from Plan

None - implementation followed the plan's bounded host-fixture and local-observation scope.

## Issues Encountered

- `bash script/verify_phoenix_host_proof_lane.sh` remains blocked before typechecking because it requires manifest `template_version === 2`, while the already-committed generator emits version 4. The script is outside this plan's declared files and was not changed.
- The plan-specified `(cd examples/phoenix_host && npx tsc --noEmit)` exits 1 because the host has no root `tsconfig.json`; the existing scoped command `npm run typecheck:offline-route-proof` passes. No TypeScript configuration was added outside this plan's declared files.

## Known Stubs

None.

## Next Phase Readiness

- The host authority seam is ready for the physical driver to consume once its existing proof-lane verification script reconciles its stale manifest-version expectation.
- No Android, generic-sync, generic-storage, payload-reporting, or backend authority expansion was introduced.

## Self-Check: PASSED

- Verified the four plan-owned artifacts exist and all four task commits are present in git history.
- Passing checks: template contract (14 tests), authority/replay integration slice (8 tests), and scoped TypeScript proof typecheck.
