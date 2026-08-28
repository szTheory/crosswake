---
phase: 160
plan: 14
status: complete
---

# Phase 160 Plan 14: Request-Bound Replay Authority Summary

Authenticated replay routes now use a host-owned Plug boundary and fail closed when current authority is absent.

## Completed Tasks

1. Added the shared `:replay_api` router pipeline, `ReplayAuth` host adapter seam, and end-to-end authorized/anonymous route coverage.
2. Removed production fixture authority defaults and made focused admission tests explicitly inject authority.

## Verification

`MIX_ENV=test mix test test/crosswake_example/local_first/replay_auth_test.exs test/crosswake_example/local_first/replay_admission_test.exs test/crosswake_example/local_first/sync_controller_test.exs test/crosswake_example/local_first/study_test.exs` — 24 tests, 0 failures.

## Deviations from Plan

None - plan executed with the existing host adapter and focused test seams.

## Self-Check: PASSED
