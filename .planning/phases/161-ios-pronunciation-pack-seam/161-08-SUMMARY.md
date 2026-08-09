---
phase: 161-ios-pronunciation-pack-seam
plan: "08"
subsystem: ios-proof-lane
tags: [ios, swift, xctest, fixture-integrity, advisory-proof]
requires:
  - phase: 161-ios-pronunciation-pack-seam
    provides: generated proof-lane and reference pack-adapter seam
provides:
  - Artifact-backed reference fixture installation with exact SHA-256 and relaunch verification.
  - Exact temporary XCTest evidence that gates advisory pack-audio proof.
affects: [phase-162-device-proof, generated-ios-proof]
tech-stack:
  added: []
  patterns: [same-volume-fixture-promotion, artifact-backed-readiness, exact-structured-evidence]
key-files:
  created: []
  modified:
    - priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex
    - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex
    - script/verify_generated_ios_shell.sh
    - test/crosswake/proof_lane/ios_verifier_test.exs
key-decisions:
  - "Reference readiness derives only from a freshly verified Application Support artifact."
  - "The advisory verifier accepts one exact allowlisted temporary JSON document, never console markers."
requirements-completed: [PACK-01, PACK-03, PACK-04, PACK-05]
coverage:
  - id: D1
    description: Reference fixture installation, relaunch readback, and offline installed-byte operation remain artifact-backed.
    requirement: PACK-03
    verification:
      - kind: integration
        ref: mix test test/crosswake/proof_lane/template_contract_test.exs
        status: pass
      - kind: automated_ui
        ref: bash script/verify_generated_ios_shell.sh --proof-lane --reference-pack-adapter
        status: pass
    human_judgment: false
  - id: D2
    description: Pack-audio advisory proof requires exact structured XCTest operation evidence.
    requirement: PACK-05
    verification:
      - kind: integration
        ref: mix test test/crosswake/proof_lane/ios_verifier_test.exs test/crosswake/proof_lane/template_contract_test.exs
        status: pass
    human_judgment: false
duration: 12min
completed: 2026-08-03
status: complete
---

# Phase 161 Plan 08: Fixture-backed iOS Proof Summary

**Generated iOS proof now promotes only exact installed synthetic fixture bytes and exact allowlisted XCTest evidence, while remaining simulator-advisory.**

## Accomplishments

- Replaced the reference adapter's UserDefaults marker with Application Support staging, SHA-256 verification, atomic promotion, and fresh artifact readback.
- Required an explicit networking-disabled condition before the bounded installed pronunciation-byte operation can pass.
- Replaced marker-text verifier authority with a restrictive temporary exact-schema evidence handoff containing only six approved assertion IDs and a closed outcome.

## Task Commits

1. **Task 1: Implement real fixture installation, relaunch readback, and offline pronunciation read** - `2338f025`, `39ac6d76`
2. **Task 2: Gate advisory pack audio on exact structured operation evidence** - `aed814b0`, `653fe5f7`

## Files Created/Modified

- `priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex` - fixture requirement, atomic installation, and artifact-backed reference adapter.
- `priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex` - atomic structured-evidence producer.
- `priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex` - launches the audio proof with networking disabled.
- `script/verify_generated_ios_shell.sh` - restrictive temporary evidence handoff and exact document gate.
- `test/crosswake/proof_lane/ios_verifier_test.exs` - structured-evidence verifier shim coverage.
- `test/crosswake/proof_lane/template_contract_test.exs` - generated-template contract coverage.

## Decisions Made

- Reference fixture metadata remains private in the generated adapter and is checked on every passing read.
- Evidence is process-scoped, exact, and deleted on verifier exit; it is not retained Crosswake evidence.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Verification

- Passed: `mix test test/crosswake/proof_lane/ios_verifier_test.exs test/crosswake/proof_lane/template_contract_test.exs`
- Passed: `env -u CROSSWAKE_IOS_XCODEBUILD_BIN -u CROSSWAKE_IOS_PROJECT_ROOT -u CROSSWAKE_IOS_SHIM_MODE CROSSWAKE_IOS_USE_LOCAL_CORE=1 CROSSWAKE_IOS_LAUNCH_SIMULATOR=1 bash script/verify_generated_ios_shell.sh --proof-lane --reference-pack-adapter`

## Next Phase Readiness

Phase 162 can run the same advisory command on a physical iPhone; this plan does not make any device-support or adopter-instance promotion claim.

## Self-Check: PASSED

- Required generated adapter, XCTest, verifier, and test files exist.
- Task commits `2338f025`, `39ac6d76`, `aed814b0`, and `653fe5f7` exist in Git history.
