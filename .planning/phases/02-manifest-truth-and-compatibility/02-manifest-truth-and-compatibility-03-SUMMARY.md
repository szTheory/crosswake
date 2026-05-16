---
phase: 02-manifest-truth-and-compatibility
plan: 03
subsystem: diagnostics
tags: [doctor, mix-task, diagnostics, json]
requires:
  - phase: 02-manifest-truth-and-compatibility
    provides: manifest compile and validation pipeline
provides:
  - structured doctor findings
  - human and JSON doctor output
  - public `mix crosswake.doctor` task
affects: [install, docs, ci, support]
tech-stack:
  added: []
  patterns: [structured findings, host-truth-first checks, render-only formatters]
key-files:
  created:
    - lib/crosswake/doctor/check.ex
    - lib/crosswake/doctor/doctor.ex
    - lib/crosswake/doctor/formatter.ex
    - lib/crosswake/doctor/json_formatter.ex
    - lib/mix/tasks/crosswake.doctor.ex
patterns-established:
  - "Doctor findings are explicit structs with severity, code, message, hint, check, and details."
  - "JSON output is generated from structured findings, never scraped back from terminal text."
requirements-completed: [DX-02, MANI-02]
duration: session
completed: 2026-05-14
---

# Phase 2 Plan 03 Summary

**Host-truth-first doctor diagnostics with stable human and JSON output over install, policy, and manifest truth**

## Performance

- **Duration:** session
- **Started:** 2026-05-14
- **Completed:** 2026-05-14
- **Tasks:** 1
- **Files modified:** 7

## Accomplishments

- Added a structured doctor engine that checks install-manifest presence, router markers, policy module presence, policy compilation, manifest validity, and support-matrix truth.
- Added terminal and JSON renderers with explicit `error`, `warning`, and `advisory` severities.
- Added `mix crosswake.doctor` as the public Phase 2 diagnostic entrypoint.

## Task Commits

Not committed in this execution mode. Changes remain local in the working tree.

## Files Created/Modified

- `lib/crosswake/doctor/check.ex` - typed doctor finding struct
- `lib/crosswake/doctor/doctor.ex` - doctor orchestration
- `lib/crosswake/doctor/formatter.ex` - human-readable output
- `lib/crosswake/doctor/json_formatter.ex` - stable JSON output
- `lib/mix/tasks/crosswake.doctor.ex` - Mix task surface
- `test/crosswake/doctor/doctor_test.exs` - doctor behavior coverage
- `test/mix/tasks/crosswake_doctor_test.exs` - Mix task coverage

## Decisions Made

- Kept native toolchain inspection advisory-only so Phase 2 does not overclaim Phase 3 shell proof.
- Required callers to pass a router module explicitly to keep doctor host truth honest in this early substrate stage.

## Deviations from Plan

None. The doctor surface stayed focused on host and manifest truth rather than broad native-preflight scope.

## Issues Encountered

- An option-plumbing bug passed `support_matrix: nil` into manifest compilation; it was corrected before release tests so doctor now preserves builder defaults.

## User Setup Required

None.

## Next Phase Readiness

Adopters and CI now have one stable diagnostic surface to verify manifest and compatibility truth before Phase 3 shell work begins.

---
*Phase: 02-manifest-truth-and-compatibility*
*Completed: 2026-05-14*
