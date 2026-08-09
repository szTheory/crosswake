---
phase: 162-physical-iphone-adoption-proof
plan: "08"
subsystem: proof-lane
tags: [ios, phoenix, xctest, playwright, fail-closed]
requires:
  - phase: 162-07
    provides: fail-closed physical report validation and ordered device prerequisites
provides:
  - Executed Phoenix authority bytes for advisory device/backend report joining
  - Explicit non-passing XCUITest admission for missing study-status host composition
  - Phoenix-owned unavailable recovery capability pending TODO-002 route inputs
affects: [physical-iphone-proof, generated-ios-host, offline-study-recovery]
tech-stack:
  added: []
  patterns: [exact producer-byte join, fail-closed XCTest admission, closed recovery capability]
key-files:
  created:
    - test/crosswake/proof_lane/physical_iphone_report_contract_script_test.exs
  modified:
    - script/verify_physical_iphone_report_contract.sh
    - priv/templates/crosswake/proof_lane/test/crosswake_proof_lane_test.exs.eex
    - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex
    - examples/phoenix_host/lib/crosswake_example_web/controllers/offline_controller.ex
    - examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex
    - examples/phoenix_host/priv/static/offline_study.js
    - examples/phoenix_host/e2e/offline_sync.spec.ts
decisions:
  - "Advisory report success requires the exact stdout bytes of an explicit host-owned Phoenix producer; the verifier authors no backend outcomes."
  - "Missing study-status composition is an XCTest failure, and serialization selects one intended contract test only."
  - "The example host exposes no recovery destination until TODO-002 supplies a server-approved saved-answer route."
metrics:
  duration: 8m
  completed: 2026-08-05
status: complete
---

# Phase 162 Plan 08: Fail-Closed Review Gap Repairs Summary

**Advisory iPhone proof now requires real Phoenix producer bytes, explicit study-status adapter admission, and a server-owned recovery capability.**

## Accomplishments

- Removed the script-authored backend success envelope and failure suppression. The verifier now captures an explicit Phoenix producer's stdout without rewriting it, rejects absent/failing/empty output, and parses it only as backend authority.
- Added focused shell-contract regression coverage for producer failure, silence, malformed output, incomplete authority assertions, and the exact-byte positive join.
- Made all three required study-status accessibility tests call a shared admission helper that records `PL-STUDY-STATUS-HOST-ADAPTER` as an XCTest failure when composition is absent or invalid.
- Narrowed the simulator advisory command to `testPhysicalContractModeEmitsOwnerFreeReport`; required accessibility tests cannot be accidentally represented by that serialization run.
- Added a closed `unavailable` recovery-route capability from Phoenix. Same-origin, cross-origin, protocol-relative, malformed, and unrelated paths cannot render a recovery action while rejected work remains queued and visible.

## Task Commits

1. **Task 1: Join exact output from the executed Phoenix authority producer** — `89821fa6` (fix)
2. **Task 2: Make missing study-status accessibility composition non-passing** — `dba3249e` (fix)
3. **Task 3: Require a server-approved recovery-route capability** — `059b63cf` (fix)

## Verification

- `mix test test/crosswake/proof_lane/physical_iphone_preflight_test.exs test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs test/crosswake/proof_lane/evidence_test.exs test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/physical_iphone_report_contract_script_test.exs --max-failures 1` — 57 tests passed.
- `cd examples/phoenix_host && npm test -- --project=chromium e2e/offline_sync.spec.ts --grep "study status retains rejected work"` — 1 Playwright test passed.
- `cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/router_test.exs --max-failures 1` — 7 tests passed.
- `mix test test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/support_matrix/renderer_test.exs --max-failures 1` — 71 tests passed.
- `mix crosswake.proof_lane.physical_iphone --run --promote --json` — correctly remained blocked with `PI-PREFLIGHT-INVENTORY`; no evidence or support claim was created.

## Decisions Made

- An advisory script cannot substitute backend authority for a missing, failed, or silent host producer.
- Host composition is a prerequisite for required study-status accessibility coverage, never a passing early return.
- TODO-002 keeps the example recovery capability closed; a future approved route must be resolved by Phoenix, not inferred from a browser URL.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking verification] Replaced the unavailable support-matrix Mix task with the repository's existing support-matrix contract suite.**
- **Found during:** Final verification
- **Issue:** `mix crosswake.support_matrix.gen --check` is not defined in this repository.
- **Fix:** Ran the canonical support-matrix and renderer tests instead; no support source or claim changed.
- **Files modified:** None

## Known Stubs

None. The recovery capability is intentionally closed rather than a stub: TODO-002 has not established a safe host recovery route, so the learner action remains absent.

## Next Phase Readiness

The code-review findings BL-01, WR-01, and WR-02 are closed. Physical promotion remains externally blocked until TODO-002, an eligible signed host/backend, required adapters, and a physical iPhone are available. Android, generic storage/sync, evidence artifacts, and support truth were not changed.

## Self-Check: PASSED

- All plan-owned files and the three task commits exist.
- No physical evidence artifact or promotion destination was created.
