---
phase: 161-ios-pronunciation-pack-seam
plan: "17"
subsystem: ios-proof-validation
tags: [swift, xcuitest, xctest, ios, proof-lane, provenance]
requires:
  - phase: 161-ios-pronunciation-pack-seam
    provides: reference-adapter real-byte install, relaunch, and denied-network audio proof
provides:
  - test-only reset-before-construction seam for generated reference-adapter proof
  - exact Blocked-to-install-to-Passed XCUITest provenance
  - verifier rejection of missing, duplicate, marker-only, and reordered current-run markers
affects: [phase-161-ios-pronunciation-pack-seam, phase-162-physical-iphone-adoption-proof]
tech-stack:
  added: []
  patterns: [exact launch-environment gate, ordered transcript provenance, closed outcome assertions]
key-files:
  created: []
  modified:
    - priv/templates/crosswake/proof_lane/ios/ProofLaneApp.swift.eex
    - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex
    - script/verify_generated_ios_shell.sh
    - test/crosswake/proof_lane/template_contract_test.exs
    - test/crosswake/proof_lane/ios_verifier_test.exs
key-decisions:
  - "Reference persistence resets only under the exact adapter-and-reset test environment before adapter construction."
  - "Passing simulator advisory output requires all four unique current-run markers in transcript order plus existing schema-v2 operation evidence."
metrics:
  duration: 15m
  completed_date: 2026-08-03
  tasks_completed: 1
  files_modified: 5
status: complete
---

# Phase 161 Plan 17: Current-Run Pack Provenance Summary

**Generated iOS reference-adapter proof now demonstrates a fresh foreground pack installation from reset state through relaunch and denied-network audio.**

## Accomplishments

- Added an exact-value, reference-adapter-only reset seam before `ProofLaneHostAdapterFactory.make()`.
- Made XCUITest assert `Blocked: packAudio` before install and exact `Passed: packAudio` only after the foreground action; relaunch removes the reset flag before readback.
- Required the four unique ordered current-run transcript markers in addition to existing XCTest and schema-v2 evidence.
- Added regressions for construction/UI ordering and missing, marker-only, duplicate, and reordered provenance.

## Verification

- `mix test test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs` — passed (19 tests).
- `bash -n script/verify_generated_ios_shell.sh` — passed.
- Plan end-to-end verifier command — passed: default generated lane remained blocked/unavailable; reference-adapter lane emitted advisory passed output with the required pack-audio scope and cleaned its run roots.

## Task Commits

1. **Task 1 RED: Cover current-run pack provenance** — `2bbeb009`.
2. **Task 1 GREEN: Prove current-run pack install** — `23027a5b`.

## Decisions Made

- The reset path requires both environment keys to equal `1`, stays inside the generated app, and has no provider/public-API/evidence surface.
- Transcript marker validation uses exact full lines, accepts each marker exactly once, and fails closed when order is not monotonic.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None. The new launch environment is exact-value gated and only clears test-only reference-adapter persistence before construction.

## Self-Check: PASSED

- All five planned modified files exist.
- Task commits `2bbeb009` and `23027a5b` exist.
