---
phase: 161-ios-pronunciation-pack-seam
plan: "13"
subsystem: generated-ios-proof
tags: [ios, swift, urlsession, urlprotocol, xctest, verifier, privacy]
requires:
  - phase: 161-11
    provides: generated reference-adapter advisory proof and transcript verifier
provides:
  - operation-bound denied-network pronunciation proof
  - exact schema-v2 advisory evidence verifier
  - marker-free accessibility-only generated UI proof
affects: [phase-162, ios-proof-lane, pronunciation-pack]
tech-stack:
  added: []
  patterns:
    - A URLSession restricted to a deny-only URLProtocol proves local network denial before installed audio is read.
    - XCTest emits exact stable IDs only from the completed adapter operation and shell verification accepts one schema-v2 document.
key-files:
  created: [.planning/phases/161-ios-pronunciation-pack-seam/161-13-SUMMARY.md]
  modified:
    - priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex
    - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex
    - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex
    - script/verify_generated_ios_shell.sh
    - test/crosswake/proof_lane/template_contract_test.exs
    - test/crosswake/proof_lane/ios_verifier_test.exs
key-decisions:
  - "Use an internal deny-only URLProtocol as the sole transport for the generated reference adapter's bounded pronunciation request."
  - "Accept advisory evidence only when the exact schema-v2 document contains ordered operation-derived stable IDs; reference success remains simulator-advisory."
requirements-completed: [PACK-01, PACK-03, PACK-04, PACK-05]
metrics:
  duration: 14m
  tasks_completed: 2
  files_modified: 6
completed: 2026-08-03
status: complete
---

# Phase 161 Plan 13: Honest Denied-Network Advisory Proof Summary

**Generated iOS advisory proof now observes a locally denied URLSession pronunciation request before it re-attests and reads installed audio bytes.**

## Accomplishments

- Added a deny-only internal `URLProtocol` and ephemeral `URLSession` that completes the bounded request with `notConnectedToInternet` without egress.
- Bound schema version 2 evidence to the exercised adapter path; legacy, missing, extra, duplicate, and reordered documents fail closed.
- Added a negative XCTest seam for unexpected transport success and removed the obsolete XCUITest network launch marker while preserving accessibility-only lifecycle checks.

## Task Commits

1. **Task 1: Observe denied network transport before installed-audio advisory proof** — `f1e00db4` (RED), `3e3f4d56` (GREEN)
2. **Task 2: Remove the obsolete UI launch marker and retain accessibility-only process proof** — `286774d0`

## Verification

- Passed: `mix test test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs test/crosswake/proof_lane/config_test.exs`
- Passed: default generated proof exits with its closed `blocked` or `unavailable` outcome.
- Passed: explicit reference-adapter simulator command returns only `{"outcome":"passed","rule_id":"PL-IOS-PACK-AUDIO-ADVISORY","scope":"pack_audio_prerequisite"}`.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None. The repair adds no external endpoint, provider capability, retained native artifact, auth path, or physical-device claim.

## Next Phase Readiness

The reference-adapter result remains simulator-advisory. Phase 162 alone owns physical-iPhone evidence and promotion.

## Self-Check: PASSED

- Confirmed all six declared implementation/test files exist.
- Confirmed task commits `f1e00db4`, `3e3f4d56`, and `286774d0` exist in Git history.
