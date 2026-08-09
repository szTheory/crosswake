---
phase: 159-host-reusable-proof-lane
plan: "11"
subsystem: proof-lane evidence promotion
tags: [elixir, evidence, privacy, fail-closed, tdd]
requires:
  - phase: 159-07
    provides: atomic no-replace evidence promotion
provides:
  - Total sanitized lifecycle-hook boundary for evidence promotion
affects: [PROOF-04]
tech-stack:
  added: []
  patterns: [exact-return-allowlist, callback-exception-normalization, staged-artifact-cleanup]
key-files:
  created: []
  modified:
    - lib/crosswake/proof_lane/evidence.ex
    - test/crosswake/proof_lane/evidence_test.exs
decisions:
  - "Evidence lifecycle hooks permit only an absent hook or an installed zero-arity hook returning exactly :ok; every other outcome is one sanitized promotion failure."
metrics:
  duration: 2m
  completed: 2026-08-01
  tasks_completed: 1
  files_modified: 2
status: complete
---

# Phase 159 Plan 11: Evidence Promotion Hook Totality Summary

Evidence promotion now treats every malformed lifecycle-hook result or exception as the same sanitized, cleanup-complete `PL-EVIDENCE-PROMOTE` failure.

## Tasks Completed

1. **Collapse all malformed evidence hooks into one safe non-passing result**
   - Added RED regressions for malformed returns plus raise, throw, and exit canaries.
   - Normalized installed callbacks to an exact `:ok` allowlist, with a boundary-local catch for all callback exception classes.
   - Asserted that failed hooks leave neither a destination nor a sibling staging directory, and never echo callback, candidate, destination, or native-output values.

## Verification

- `mix test test/crosswake/proof_lane/evidence_test.exs` — 15 tests, 0 failures.
- `mix format --check-formatted lib/crosswake/proof_lane/evidence.ex test/crosswake/proof_lane/evidence_test.exs` — passed.
- Confirmed `COVERAGE.md` and the retained evidence schema allowlists are unchanged.
- Re-ran the tracer verification after the GREEN commit; it passed.

## TDD Gate Compliance

- RED: `b3bbc657` — failing adversarial lifecycle-hook regressions.
- GREEN: `b08c9966` — closed hook normalization and cleanup behavior.

## Decisions Made

- An absent hook remains `nil`; any installed zero-arity callback must return exactly `:ok`.
- Callback values, exceptions, throw terms, and exit reasons are intentionally discarded before rendering the stable evidence-promotion error.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- Both modified production and test files exist.
- RED and GREEN commits are present in Git history.
- Focused evidence tests and formatter checks pass on the final tree.
