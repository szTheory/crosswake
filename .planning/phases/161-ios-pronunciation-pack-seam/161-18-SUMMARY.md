---
phase: 161-ios-pronunciation-pack-seam
plan: "18"
subsystem: ios-pronunciation-pack-proof
tags: [ios, xctest, validation, privacy, evidence]
requires: [161-17]
provides: [schema-4-current-run-provenance]
affects: [phase-161-validation]
tech-stack:
  added: []
  patterns: [aggregate-only evidence, current-run provenance, canonical manifest equality]
key-files:
  created: [.planning/phases/161-ios-pronunciation-pack-seam/161-18-SUMMARY.md]
  modified: [.planning/phases/161-ios-pronunciation-pack-seam/161-VALIDATION.md]
decisions:
  - "The final host XCTest gate explicitly selects the existing UI accessibility backstops."
metrics:
  tasks_completed: 1
status: complete
---

# Phase 161 Plan 18: Fresh Current-Run Provenance Final Gate Summary

The post-161-17 tree passed one complete same-tree gate, retaining only schema-4 aggregate evidence that binds reset, foreground install, relaunch, and offline-audio provenance to the repaired generated iOS path.

## Completed Tasks

1. Executed the full Swift, host XCTest, proof-lane, privacy, Sigra, Phoenix, browser, and generated iOS validation chain.
   - `5fc5a3fc` — `docs(161-18): retain fresh pack validation evidence`

## Verification

- Swift core, proof-lane, privacy, Sigra, Phoenix, and browser suite counts are positive.
- The selected host XCTest run observed all four required accessibility backstops; direct selected-host confirmation passed 43 tests with zero failures.
- Default generated iOS remains closed non-passing; the reference adapter remains passed simulator-advisory only.
- Retained and private manifests passed canonical equality and privacy scanning; the repair subject remains five files with an unchanged digest.
- `COVERAGE.md` remained byte-identical, and no raw native artifacts were retained.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 2 - Missing critical validation] Selected existing UI accessibility backstops in the host XCTest invocation.
   - **Found during:** Task 1 final gate
   - **Issue:** The planned host command selected only `CrosswakeShellTests`, but the acceptance criteria require four backstops defined in `CrosswakeShellUITests/RequiredPackViewAccessibilityTests`.
   - **Fix:** Added the existing `-only-testing:CrosswakeShellUITests/RequiredPackViewAccessibilityTests` selector to the one-run validation command; no product code changed.
   - **Files modified:** `161-VALIDATION.md` only (retained evidence)
   - **Commit:** `5fc5a3fc`

## Known Stubs

None.

## Self-Check: PASSED

- Fresh schema-4 validation evidence exists in `161-VALIDATION.md`.
- Task commit `5fc5a3fc` exists.
