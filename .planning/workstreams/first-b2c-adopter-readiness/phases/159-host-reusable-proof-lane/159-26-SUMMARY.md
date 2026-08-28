---
phase: 159-host-reusable-proof-lane
plan: "26"
subsystem: proof-evidence integrity
tags: [elixir, retained-evidence, sha256, toctou, testing]
requires:
  - phase: 159-24
    provides: retained proof-evidence reader and completion-marker contract
provides:
  - Digest-bound evidence snapshots for both public evidence checks
  - Deterministic replacement regressions for source-free and source-verified checks
affects: [159-27, proof-lane verification, PROOF-04]
tech-stack:
  added: []
  patterns:
    - One captured, marker-verified byte binary drives scan, decode, and source verification.
    - Test-only process-local barriers model replacement without timing dependencies.
key-files:
  created: []
  modified:
    - lib/crosswake/proof_lane/evidence.ex
    - test/crosswake/proof_lane/evidence_test.exs
key-decisions:
  - "Evidence acceptance is snapshot-based: the bytes that satisfy .complete are the sole semantic input for that check call."
  - "Replacement races use a private test-environment process barrier, preserving production APIs and retained metadata."
patterns-established:
  - "Retained artifact validation reads a mutable artifact once before binding it to a regular SHA-256 completion marker."
requirements-completed: [PROOF-04]
coverage:
  - id: D1
    description: "Both Evidence.check arities decode and validate only marker-bound captured bytes, then reject a changed path on the following read."
    requirement: PROOF-04
    verification:
      - kind: unit
        ref: test/crosswake/proof_lane/evidence_test.exs#digest-bound replacement regressions
        status: pass
    human_judgment: false
duration: 9min
completed: 2026-08-02
status: complete
---

# Phase 159 Plan 26: Digest-Bound Evidence Snapshot Summary

**Both public evidence checks now validate one completion-digest-bound artifact snapshot through canonical decoding and approved-source verification.**

## Performance

- **Duration:** 9 min
- **Completed:** 2026-08-02T02:36:11Z
- **Tasks:** 1/1
- **Files modified:** 2

## Accomplishments

- Replaced the scan-then-reopen flow with a single verified evidence reader shared by `scan_stage/1`, `check/1`, and `check/2`.
- Kept the exact twelve-field schema, non-echoing errors, source semantics, and public APIs unchanged.
- Added deterministic no-sleep replacement coverage for both public check arities and confirmed a later check fails against the changed artifact.

## Task Commits

1. **Task 1: Consume the exact completion-digest-bound evidence bytes (RED)** — `76628cc3` (test)
2. **Task 1: Consume the exact completion-digest-bound evidence bytes (GREEN)** — `e1433a50` (fix)

## Verification

- `mix test test/crosswake/proof_lane/evidence_test.exs` — passed (19 tests, 0 failures).
- `mix format --check-formatted lib/crosswake/proof_lane/evidence.ex test/crosswake/proof_lane/evidence_test.exs` — passed.
- Static reader inspection confirms the artifact is read only by `read_artifact/1`, before completion-marker verification; no evidence path is reopened for decoding or source validation.

## Decisions Made

- Use the digest-matched binary as the sole input to scan, decode, and source verification for each call.
- Limit the adversarial replacement hook to a module-private branch compiled only in the test environment and scoped to the calling process.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

None.

## Next Phase Readiness

Plan 159-27 can run the fresh same-tree reconciliation knowing retained-evidence readers are bound to verified snapshot bytes. TODO-002 and adopter-instance completeness remain `unknown_blocking`.

## Self-Check: PASSED

- Modified implementation and regression files exist.
- Both TDD commits exist in git history.
- No protected Phase 159 `COVERAGE.md` changes were made; the pre-existing `.planning/config.json` modification remains unstaged.
