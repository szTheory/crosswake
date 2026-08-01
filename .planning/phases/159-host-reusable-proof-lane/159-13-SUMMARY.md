---
phase: 159-host-reusable-proof-lane
plan: "13"
subsystem: generator filesystem lifecycle
tags: [elixir, c, filesystem, cleanup, collision-safety, proof-lane]
requires:
  - phase: 159-12
    provides: fresh final-tree gap assessment for the proof lane
provides:
  - Post-create exclusive-write cleanup for read, write, and fsync failures
  - Collision-safe manifest staging cleanup that fails closed on cleanup failure
  - Deterministic regressions for reruns, winner preservation, and retained staging absence
affects: [proof-lane, host-reusable-generation, PROOF-01, 159-14]
tech-stack:
  added: []
  patterns: [descriptor-relative unlink-before-return cleanup, no-replace collision cleanup]
key-files:
  created: []
  modified:
    - priv/native/crosswake_proof_lane_fs.c
    - lib/crosswake/proof_lane/generator_fs.ex
    - test/mix/tasks/crosswake_gen_proof_lane_test.exs
key-decisions:
  - "A failed exclusive write removes only the newly created destination while its parent descriptor remains pinned."
  - "Manifest reuse is valid only after the helper-owned staging source is removed; cleanup failure is non-passing."
metrics:
  duration: 12m
  completed: 2026-08-01
  tasks_completed: 2
  files_changed: 3
status: complete
---

# Phase 159 Plan 13: Proof-Lane Filesystem Cleanup Summary

The native proof-lane helper now removes helper-created debris on failed writes and manifest publication collisions without touching pre-existing host-owned winners.

## Completed Work

- Added closed test-only post-create fault selectors for the real compiled helper and three named regressions covering read, write, and fsync failures after exclusive creation.
- Routed every post-create copy and fsync failure through one descriptor-pinned cleanup path that closes descriptors, unlinks the new leaf, and returns the original write failure classification.
- Made `EEXIST` manifest publication unlink helper staging before returning reuse; injected cleanup failure returns `PL-GENERATE-WRITE` instead.
- Extended interruption and two-generator regressions to prove successful/reused outcomes leave no `.staging-*` debris.

## Task Commits

1. Task 1 RED — `8aff91ff` test(159-13): add failing post-create cleanup regressions
2. Task 1 GREEN — `f81e1a15` fix(159-13): clean failed exclusive proof writes
3. Task 2 RED — `30d5ca09` test(159-13): add failing manifest collision cleanup regressions
4. Task 2 GREEN — `cf262b6f` fix(159-13): clean manifest staging on collisions

## Verification

- `mix test test/mix/tasks/crosswake_gen_proof_lane_test.exs --only post_create_fault:read` — passed.
- `mix test test/mix/tasks/crosswake_gen_proof_lane_test.exs --only post_create_fault:write` — passed.
- `mix test test/mix/tasks/crosswake_gen_proof_lane_test.exs --only post_create_fault:fsync` — passed.
- `mix test test/mix/tasks/crosswake_gen_proof_lane_test.exs` — passed (14 tests).
- `mix format --check-formatted test/mix/tasks/crosswake_gen_proof_lane_test.exs lib/crosswake/proof_lane/generator_fs.ex` — passed.
- `cc -std=c11 -O2 -Wall -Wextra -Werror -o /tmp/crosswake-proof-lane-fs-plan-159-13 priv/native/crosswake_proof_lane_fs.c` — passed.

## Decisions Made

- Preserve the native helper’s public result contract: only the cleanup guarantees changed.
- Keep fault selection closed to the three named post-create branches and the deterministic collision-cleanup failure control.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Added a closed test-only fault bridge in `GeneratorFS.write/4`.**
- **Found during:** Task 1
- **Issue:** The real helper had no way to deterministically select its post-create read, write, and fsync failure branches.
- **Fix:** Added a closed `:read | :write | :fsync` option that passes only the matching test selector to the helper.
- **Files modified:** `lib/crosswake/proof_lane/generator_fs.ex`
- **Commit:** `f81e1a15`

## Known Stubs

None.

## Self-Check: PASSED

- Modified native helper and regression suite exist.
- All four TDD gate commits exist in git history.
- Focused tests, formatter, native `-Werror` compile, and diff whitespace check passed.
