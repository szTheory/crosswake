---
phase: 53-release-continuity-and-closeout-hardening
plan: "02"
subsystem: tooling
tags: [mix-task, ci, closeout, proof-lane]
requires:
  - phase: 53-release-continuity-and-closeout-hardening
    provides: Crosswake.Planning.CloseoutVerifier
provides:
  - mix closeout.verify local command
  - merge-blocking proof workflow closeout step
  - CI parity tests for blocking and advisory lanes
affects: [REL-01, phase52-proof, closeout.verify]
tech-stack:
  added: []
  patterns: [thin Mix wrapper, shared verifier delegation, workflow parity test]
key-files:
  created:
    - lib/mix/tasks/closeout.verify.ex
    - test/mix/tasks/closeout_verify_test.exs
    - test/crosswake/planning/closeout_ci_parity_test.exs
  modified:
    - .github/workflows/phase52-proof.yml
key-decisions:
  - "mix closeout.verify delegates directly to Crosswake.Planning.CloseoutVerifier and raises on :failed status."
  - "The existing Phase 52 proof workflow is extended in place instead of creating a second closeout workflow."
requirements-completed: [REL-01]
duration: 11min
completed: 2026-06-01
---

# Phase 53 Plan 02 Summary

**`mix closeout.verify` now exposes the shared closeout verifier locally and in the merge-blocking proof lane.**

## Accomplishments

- Added `Mix.Tasks.Closeout.Verify` as a small command wrapper over `CloseoutVerifier.run/1` and `render/1`.
- Added Mix task tests for passing output, blocking failure exit behavior, and unsupported option handling.
- Added CI parity tests that require the merge-blocking proof job to run `mix closeout.verify` while keeping the advisory job `continue-on-error: true`.
- Updated `.github/workflows/phase52-proof.yml` in place with a named closeout verification step after compile.

## Verification

- `mix test test/mix/tasks/closeout_verify_test.exs test/crosswake/planning/closeout_ci_parity_test.exs` — 5 tests, 0 failures.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

None.

## Next Phase Readiness

Plan 53-03 can now archive/reset v3.6 planning surfaces and make `mix closeout.verify` pass against the live repository state.

## Self-Check: PASSED

- FOUND: `lib/mix/tasks/closeout.verify.ex`
- FOUND: `.github/workflows/phase52-proof.yml` includes `mix closeout.verify`
- VERIFIED: command/workflow parity tests passed.
