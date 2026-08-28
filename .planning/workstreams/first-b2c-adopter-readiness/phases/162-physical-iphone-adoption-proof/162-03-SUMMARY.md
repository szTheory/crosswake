---
phase: 162-physical-iphone-adoption-proof
plan: "03"
subsystem: proof-lane
tags: [ios, physical-iphone, xctest, xcuittest, phoenix, privacy]
requires:
  - phase: 162-01
    provides: closed preflight gateway and fixed owner-tagged DEVICE assertion contract
  - phase: 162-02
    provides: independently-owned Phoenix authority fixture callbacks
provides:
  - closed generated device-local physical-sequence observation contract
  - strict preflight-gated, owner-disjoint report join for sanitized candidates
affects: [162-04, 162-05, physical-device-evidence]
tech-stack:
  added: []
  patterns: [host-owned physical observations, uninterrupted lifecycle sequence, exact dual-authority join]
key-files:
  created: []
  modified:
    - priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex
    - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex
    - lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex
    - test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs
key-decisions:
  - "Generated physical device reports contain only schema version, physical device class, fixed assertion IDs, and closed outcomes."
  - "The driver protocol has no reset operation, preventing a reset between offline submission, terminate/relaunch, and reconnect."
  - "Device-local reports cannot satisfy Phoenix-owned assertions; a candidate is returned only for the complete exact passed manifest."
patterns-established:
  - "Absent production host adapters are unavailable rather than simulated as passed."
  - "Physical proof output is constructed from a strict owner-disjoint join and emits only low-cardinality fields."
requirements-completed: [DEVICE-01, DEVICE-02, DEVICE-03, DEVICE-04, DEVICE-05]
coverage:
  - id: D1
    description: "Generated physical sequence exposes only closed device-local observations and stays unavailable without a production adapter."
    requirement: DEVICE-01
    verification:
      - kind: unit
        ref: "mix test test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs --max-failures 1"
        status: pass
      - kind: automated_ui
        ref: "bash script/verify_generated_ios_shell.sh --proof-lane --reference-pack-adapter"
        status: pass
    human_judgment: false
  - id: D2
    description: "Preflight-gated device and Phoenix reports join only when each fixed assertion has its required owner and passed outcome."
    requirement: DEVICE-02
    verification:
      - kind: unit
        ref: "mix test test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs test/crosswake/proof_lane/physical_iphone_preflight_test.exs --max-failures 1"
        status: pass
    human_judgment: false
metrics:
  duration: 25min
  completed: 2026-08-04
status: complete
---

# Phase 162 Plan 03: Physical iPhone Driver and Authority Join Summary

**A host-owned, reset-free device-local sequence plus a fail-closed exact join that keeps Phoenix backend authority independent.**

## Performance

- **Duration:** 25 min
- **Completed:** 2026-08-04T21:35:49Z
- **Tasks:** 2/2
- **Files modified:** 4

## Accomplishments

- Added a generated physical-iPhone observation protocol for verified pack/audio, offline selected and free-form submissions, relaunch/reconnect, and retained recovery state; the nil host adapter produces only unavailable results.
- Added XCTest coverage that confirms the report is a fixed device-local JSON shape with no host values, paths, payloads, logs, or device details.
- Extended the Mix command with an exact `--run --json` join after the existing preflight. Device and Phoenix reports must be owner-disjoint, complete, ordered, and passed before a sanitized candidate is returned.

## Task Commits

1. **Task 1: Extend the generated driver with the uninterrupted physical sequence** — `1327b5b7` (`feat`)
2. **Task 2: Orchestrate signed device execution and join dual-authority reports** — `22d641e0` (`feat`)

## Files Created/Modified

- `priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex` — closed device-local physical observation/report contract with no reset capability.
- `priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex` — nil-adapter and report-shape contract tests.
- `lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex` — `--run --json` preflight gate and strict dual-authority report join.
- `test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs` — exact join and cross-owner rejection coverage.

## Decisions Made

- The generated device report stays limited to the five device-local assertion IDs. Backend authority remains represented solely by the separately supplied Phoenix report.
- A missing host adapter, malformed report, wrong owner, incomplete report, or non-passing assertion returns a stable blocked rule rather than emitting raw output.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed a forbidden unconditional passed return from the generated driver**
- **Found during:** Task 1
- **Issue:** The existing template contract rejects a generic `return .passed` pattern because it could mask a simulated success.
- **Fix:** Used an explicit closed outcome reducer that returns `passed` only when both observations passed.
- **Files modified:** `priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex`
- **Verification:** Generated template contract and advisory iOS verifier pass.
- **Committed in:** `1327b5b7`

**2. [Rule 1 - Bug] Corrected invalid guard access in the Mix task**
- **Found during:** Task 2
- **Issue:** Accessing parsed option data inside a guard does not compile in Elixir.
- **Fix:** Moved the option branch into ordinary control flow before invoking the join.
- **Files modified:** `lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex`
- **Verification:** Focused physical runner and preflight tests pass.
- **Committed in:** `22d641e0`

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs).
**Impact on plan:** Both fixes preserve fail-closed behavior and keep the intended scope intact.

## Issues Encountered

- No actual signed physical-device run was attempted or claimed. The repository has no configured generated host, validated route inventory, selected physical destination, signing, media, or backend fixture controls; the existing preflight blocks this state before the runner.
- The simulator/reference-pack lane remains advisory only and does not promote physical-device evidence.

## Known Stubs

None. The nil physical host adapter is an intentional fail-closed generated seam, not a proof result.

## Next Phase Readiness

- Plans 162-04 and 162-05 can consume only the sanitized candidate shape after an adopter host supplies the required physical callbacks and all Plan 01 preflight prerequisites.
- No simulator result, Android work, generic sync/storage, raw artifacts, or backend authority was introduced.

## Self-Check: PASSED

- All four modified plan artifacts exist.
- Task commits `1327b5b7` and `22d641e0` exist in Git history.

---
*Phase: 162-physical-iphone-adoption-proof*
*Completed: 2026-08-04*
