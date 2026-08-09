---
phase: 162-physical-iphone-adoption-proof
plan: "07"
subsystem: proof-lane
tags: [ios, swift, xctest, elixir, evidence, fail-closed]
requires:
  - phase: 162-06
    provides: physical-iPhone preflight, host boundary, and retained-evidence contract
provides:
  - Sequential generated iOS proof-driver guards that stop later host operations after a closed failure
  - Total physical-report validation and fail-closed canonical evidence decoding
affects: [physical-iphone-proof, generated-ios-host, evidence-promotion]
tech-stack:
  added: []
  patterns: [ordered closed-outcome guards, exact atom-key report-shape admission]
key-files:
  created: []
  modified:
    - priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex
    - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex
    - lib/crosswake/proof_lane/physical_iphone_contract.ex
    - test/crosswake/proof_lane/physical_iphone_preflight_test.exs
    - test/crosswake/proof_lane/evidence_test.exs
key-decisions:
  - "Every non-passing adapter result immediately closes unrun device observations with its terminal outcome."
  - "Physical report entries must have exactly atom keys id, owner, and outcome before validation reads them."
patterns-established:
  - "Device-proof sequence: guard each awaited host operation before invoking the next."
  - "Untrusted report lists: admit exact entry shape before Map access, ordering, or semantic checks."
requirements-completed: []
coverage:
  - id: D1
    description: Generated iOS proof sequence short-circuits after every blocked or unavailable prerequisite.
    verification:
      - kind: integration
        ref: bash script/verify_physical_iphone_report_contract.sh
        status: pass
      - kind: unit
        ref: test/crosswake/proof_lane/template_contract_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Malformed physical reports fail closed through direct validation and Evidence.build/1.
    verification:
      - kind: unit
        ref: test/crosswake/proof_lane/physical_iphone_preflight_test.exs
        status: pass
      - kind: unit
        ref: test/crosswake/proof_lane/evidence_test.exs
        status: pass
    human_judgment: false
metrics:
  duration: 20m
  completed: 2026-08-05
status: complete
---

# Phase 162 Plan 07: Fail-Closed Physical Proof Repairs Summary

**Generated iOS proof operations now stop at the first closed prerequisite, while malformed physical reports fail safely before evidence handling.**

## Performance

- **Duration:** 20m
- **Completed:** 2026-08-05T01:59:02Z
- **Tasks:** 2/2
- **Files modified:** 6

## Accomplishments

- Added recording-adapter coverage for every one of seven physical host operations failing as `blocked` or `unavailable`, plus the all-passed order.
- Replaced eager Swift awaits with ordered guards that never invoke later host mutation, relaunch, reconnect, or recovery work after failure.
- Made physical report validation total for non-map and wrong-shape entries, and verified public evidence construction translates invalid run-contract bytes to `PL-EVIDENCE-HASH`.

## Task Commits

1. **Task 1: Short-circuit every failed generated-device prerequisite** — `95b63845` (fix)
2. **Task 2: Make malformed physical reports total across validator and evidence** — `f6b7d340` (fix)

## Verification

- `bash script/verify_physical_iphone_report_contract.sh && mix test test/crosswake/proof_lane/template_contract_test.exs --max-failures 1` — passed.
- `mix test test/crosswake/proof_lane/physical_iphone_preflight_test.exs test/crosswake/proof_lane/evidence_test.exs --max-failures 1` — 34 tests passed.
- `mix format --check-formatted lib/crosswake/proof_lane/physical_iphone_contract.ex test/crosswake/proof_lane/physical_iphone_preflight_test.exs test/crosswake/proof_lane/evidence_test.exs` — passed.

## Decisions Made

- Terminal `blocked` or `unavailable` outcomes close every unrun local assertion without inferring a pass or invoking another host operation.
- Shape admission precedes map reads so malformed external report input cannot raise or echo content through the evidence boundary.

## Deviations from Plan

None - plan executed within its declared iOS driver, report-contract, and focused-test scope.

## Issues Encountered

None.

## Next Phase Readiness

The code-only safety gaps are closed. The repository-default physical command remains blocked at `PI-PREFLIGHT-INVENTORY`; no physical artifact, support claim, or requirement completion was recorded. Genuine promotion still needs TODO-002, an eligible signed host/backend, host adapters, and a physical iPhone.

## Self-Check: PASSED

- All six plan-owned implementation/test files exist.
- Task commits `95b63845` and `f6b7d340` exist in git history.
