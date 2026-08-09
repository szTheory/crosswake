---
phase: 158-adoption-reset-and-route-map
plan: "17"
subsystem: planning privacy scanner
tags: [privacy, repository-scanning, mix-task, reset-04]
requires:
  - 158-16
provides:
  - tracked-text scan-by-default classification
  - production Mix-task bypass regressions
affects: [protected-private-term-ci]
tech_stack:
  added: []
  patterns: [Git candidate enumeration, stable rule/path diagnostics]
key_files:
  created: []
  modified:
    - lib/crosswake/planning/first_adopter_context.ex
    - test/crosswake/planning/first_adopter_context_test.exs
    - test/mix/tasks/crosswake_adoption_context_scan_test.exs
decisions:
  - Recognized textual repository candidates scan for private terms regardless of subtree; raw evidence and binary exclusions remain explicit.
  - Generic policy rules stay limited to designated policy artifacts while private-term enforcement covers every classified textual candidate.
metrics:
  duration: 18m
  completed: 2026-07-31
status: complete
---

# Phase 158 Plan 17: Tracked Text Privacy Classification Summary

Tracked action, script, and future planning text now reach private-term enforcement through both the direct scanner and the production Mix task without exposing matched content or supplied terms.

## Tasks Completed

1. Added a direct temporary-repository regression for action, script, and unbounded future-phase candidates, then made recognized text scan by default.
2. Added production Mix-task coverage for those three candidates and retained policy checks for designated artifacts.

## Verification

- `mix test test/crosswake/planning/first_adopter_context_test.exs test/mix/tasks/crosswake_adoption_context_scan_test.exs`
- `mix crosswake.adoption_context.scan`
- `mix format --check-formatted lib/crosswake/planning/first_adopter_context.ex test/crosswake/planning/first_adopter_context_test.exs test/mix/tasks/crosswake_adoption_context_scan_test.exs`

## Commits

- `83173499` — failing direct scanner regression
- `6a6d0d34` — tracked text scan-by-default implementation
- `8c6f1ac9` — production Mix-task regression and policy-scan correction

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Restored designated-artifact generic policy checks
- **Found during:** Task 2
- **Issue:** The new policy-scan flag held a destination atom rather than a boolean, bypassing existing generic rule tests.
- **Fix:** Normalized the flag to a boolean while retaining private-term coverage for all classified text.
- **Files modified:** `lib/crosswake/planning/first_adopter_context.ex`
- **Commit:** `8c6f1ac9`

## Known Stubs

None.

## Self-Check: PASSED

- All three modified scanner/test files exist.
- Commits `83173499`, `6a6d0d34`, and `8c6f1ac9` exist.
