---
phase: 161-ios-pronunciation-pack-seam
plan: "05"
subsystem: proof-lane-evidence-validation
tags: [ios, proof-lane, evidence, privacy, validation]
requires:
  - phase: 161-ios-pronunciation-pack-seam
    provides: host-owned PackProvider, recovery UI, and generated advisory pack/audio proof
  - phase: 160-scoped-replay-and-auth-safety
    provides: scoped replay, backend authorization, and privacy preservation gates
provides:
  - Closed pack-audio evidence regression coverage with non-echoing D-21 rejection behavior
  - Fresh aggregate-only Phase 161 final validation and sealed no-external-API declaration
affects: [phase-162-physical-iphone-proof, proof-lane-evidence]
tech-stack:
  added: []
  patterns: [allowlisted-evidence, closed-diagnostics, aggregate-only-final-gate]
key-files:
  created: []
  modified:
    - lib/crosswake/proof_lane/evidence.ex
    - test/crosswake/proof_lane/evidence_test.exs
    - .planning/phases/161-ios-pronunciation-pack-seam/161-VALIDATION.md
decisions:
  - Nested sensitive evidence values fail with the established closed error rather than raising or exposing a candidate.
  - Simulator and reference-adapter results remain advisory; Phase 162 alone owns physical-iPhone and adopter-instance promotion.
metrics:
  duration: 22m
  completed_date: 2026-08-03
  tasks: 1
  files: 3
status: complete
---

# Phase 161 Plan 05: Pack Evidence and Final Gate Summary

Closed the deterministic pack seam with a fresh privacy-safe gate that preserves Phase 160 authority and keeps all native simulator proof advisory.

## Completed Tasks

1. Added `pack_audio_prerequisite` closed-outcome coverage and D-21 private/raw proof rejection regressions, then reconciled the full Phase 161 final-tree validation map from fresh aggregate-only evidence.

## Verification

- Swift core: 21 tests passed.
- Example-host provider and recovery UI: 2 and 4 XCTest cases passed on the installed iPhone 17 simulator with `ONLY_ACTIVE_ARCH=YES`.
- Proof-lane suite: 50 tests passed; scoped replay/privacy/egress preservation: 121 tests passed.
- Sigra contract: 15 tests passed; Phoenix authorization: 33 tests passed; offline-island browser proof: 23 tests passed.
- Generated iOS default remained closed non-passing; explicit reference-pack-adapter output passed only as advisory `pack_audio_prerequisite` evidence.
- `api-coverage.verify-pre` passed for the existing exact no-external-API declaration.

## Decisions Made

- Evidence scanning halts with the established non-echoing `PL-EVIDENCE-SENSITIVE` result when a nested candidate is sensitive.
- No external API, SDK, service, storage, Android, physical-device, or adopter-instance claim was added.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Returned sanitized nested sensitive-value errors instead of raising.
- **Found during:** Task 1 evidence regression verification.
- **Issue:** A nested sensitive candidate produced a function-clause failure after the scanner had already found a private value.
- **Fix:** Halt the recursive map scan on any nested error and return the existing closed error shape.
- **Files modified:** `lib/crosswake/proof_lane/evidence.ex`, `test/crosswake/proof_lane/evidence_test.exs`.
- **Verification:** `mix test test/crosswake/proof_lane/evidence_test.exs` — 24 tests passed.
- **Commit:** `85af5539`.

2. [Rule 3 - Environment] Used the installed iPhone 17 simulator with active-architecture-only builds.
- **Found during:** Task 1 example-host verification.
- **Issue:** The planned iPhone 16 simulator is unavailable, and the local Xcode build required an active-architecture-only simulator build.
- **Fix:** Ran the unchanged tests on iPhone 17 with `ONLY_ACTIVE_ARCH=YES`.
- **Files modified:** None.
- **Verification:** Provider and UI XCTest suites passed.
- **Commit:** N/A.

**Total deviations:** 2 (1 auto-fixed bug, 1 environment-only verification substitution).

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed all modified source, test, validation, and pre-existing coverage-seal artifacts exist.
- Confirmed task commit `85af5539` exists.
