---
phase: 161-ios-pronunciation-pack-seam
plan: "16"
subsystem: ios-proof-validation
tags: [swift, xctest, xcui, accessibility, proof-lane, validation]
requires:
  - phase: 161-ios-pronunciation-pack-seam
    provides: crash-safe pack-publication recovery and deterministic restart tests
provides:
  - real XCUI accessibility coverage for the four UI-SPEC backstops
  - schema-3 aggregate-only crash-recovery final-tree validation
  - run-root-safe generated iOS proof verification
affects: [phase-162-device-proof]
tech-stack:
  added: []
  patterns: [detached Xcode verification, caller-scoped DerivedData, aggregate-only validation]
key-files:
  created: []
  modified:
    - examples/ios_shell_host/CrosswakeShellUITests/RequiredPackViewAccessibilityTests.swift
    - script/verify_generated_ios_shell.sh
    - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex
    - .planning/phases/161-ios-pronunciation-pack-seam/161-VALIDATION.md
key-decisions:
  - "Use the narrow real XCUI target for process-level accessibility probes; preserve unit tests for lifecycle-effect internals."
  - "Keep every generated-verifier discovery and test invocation inside one normalized caller-owned private run root."
requirements-completed: [PACK-01, PACK-02, PACK-03, PACK-04, PACK-05]
coverage:
  - id: D1
    description: Real accessibility-XXXL E1-E4 backstops cover recovery reachability, lifecycle status, action labels, and safe developer context.
    requirement: PACK-01
    verification:
      - kind: automated_ui
        ref: CrosswakeShellUITests/RequiredPackViewAccessibilityTests
        status: pass
    human_judgment: false
  - id: D2
    description: Fresh schema-3 validation seals crash recovery and preservation outcomes while preserving the advisory device boundary.
    requirement: PACK-03
    verification:
      - kind: integration
        ref: 161-16 complete same-tree final gate
        status: pass
    human_judgment: false
status: complete
---

# Phase 161 Plan 16: Crash-Recovery Final Gate Summary

**Real XCUI accessibility backstops and a fresh schema-3 aggregate-only gate close Phase 161’s crash-recovery validation without promoting simulator proof to physical-device evidence.**

## Performance

- **Duration:** 30m
- **Tasks:** 2/2
- **Files modified:** 8
- **Verification:** focused E1/E2/E4, full XCUI target, verifier contracts, and the complete final same-tree gate passed.

## Accomplishments

- Ran all four real UI-SPEC accessibility backstops with a constrained accessibility-XXXL simulator surface; no test-originated crash or fatal output occurred.
- Published the exact schema-3 aggregate payload with six-file subject binding, preservation counts, closed outcomes, payload equality, privacy scan, and cleanup assertions.
- Repaired generated-proof root normalization, discovery arguments, and async XCTest assertions so default proof remains non-passing while the reference adapter remains simulator-advisory.

## Task Commits

1. **Task 1: Make all four UI-SPEC large-Dynamic-Type backstops executable** — `d7d7f6fa`, `01bc435b`, `0841beaa`, `f198e0df`.
2. **Task 2: Execute and retain the fresh crash-recovery final-tree gate** — `db3710ac`, `41a7825b`.

## Decisions Made

- The authorized recovery uses an XCUI target only for rendered-process assertions; it does not change the learner UI contract or widen native scope.
- The full gate appends that real target to the existing private host XCTest transcript so its four required markers contribute to one aggregate result.
- Simulator/reference success remains advisory; Phase 162 solely owns physical-iPhone promotion.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Adapted final-gate UI marker collection to the authorized XCUI target**
- **Found during:** Task 2
- **Issue:** The planned host-only command expected E1-E4 markers after they moved into the authorized real UI target.
- **Fix:** Ran the UI target in the same private host transcript before asserting all markers.
- **Verification:** all four XCUI tests and the complete same-tree gate passed.
- **Committed in:** `f198e0df`

**2. [Rule 3 - Blocking] Normalized private verifier roots and supplied Xcode discovery scheme**
- **Found during:** Task 2
- **Issue:** an ambient trailing separator violated proof-lane root validation, and this Xcode requires `-scheme` with DerivedData-scoped `-list`.
- **Fix:** normalized the owned root logically and supplied the already-known scheme.
- **Verification:** verifier contracts passed; default lane closed non-passing and reference lane passed advisory.
- **Committed in:** `db3710ac`, `41a7825b`

**3. [Rule 1 - Bug] Removed async calls from XCTest assertion autoclosures**
- **Found during:** Task 2
- **Issue:** generated reference XCTest could not compile.
- **Fix:** awaited both operations into local values before asserting.
- **Verification:** template/verifier contracts passed and real reference-adapter proof passed.
- **Committed in:** `41a7825b`

**Total deviations:** 3 auto-fixed. **Impact:** all corrections were limited to executable proof and verification correctness; no product, API, privacy, Android, or device-promotion scope expanded.

## Known Stubs

None.

## Next Phase Readiness

Phase 161 has fresh aggregate-only simulator evidence. TODO-002 and adopter-instance completeness remain `unknown_blocking`; Phase 162 alone owns physical-iPhone promotion.

## Self-Check: PASSED
