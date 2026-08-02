---
phase: 159-host-reusable-proof-lane
plan: "25"
subsystem: proof-lane-helper-security
tags: [elixir, c, generator, private-temp-directory, provenance, concurrency]
requires:
  - phase: 159-24
    provides: final same-tree proof-lane gate and identified executable-provenance gap
provides:
  - invocation-owned restrictive compilation and execution boundary for proof-lane helpers
  - poisoned former-cache regression across direct and generator action seams
affects: [PROOF-01, PROOF-02, phase-159-final-gate]
tech-stack:
  added: []
  patterns: [process-scoped-private-helper-lifecycle, exclusive-temp-directory, stable-non-echoing-failure]
key-files:
  created: []
  modified:
    - lib/crosswake/proof_lane/generator.ex
    - lib/crosswake/proof_lane/generator_fs.ex
    - test/mix/tasks/crosswake_gen_proof_lane_test.exs
key-decisions:
  - The digest-named shared-temp helper is attacker-controlled legacy input and is never consulted or executed.
  - Generator actions share one freshly compiled helper only within their caller-owned private lifecycle; direct filesystem actions remain independently private.
requirements-completed: [PROOF-01, PROOF-02]
coverage:
  - id: D1
    description: Proof-lane helper compilation and execution use an exclusive restrictive directory rather than a predictable shared-temp executable.
    requirement: PROOF-01
    verification:
      - kind: unit
        ref: test/mix/tasks/crosswake_gen_proof_lane_test.exs#generator actions ignore a poisoned former shared helper cache
        status: pass
    human_judgment: false
  - id: D2
    description: Concurrent, idempotent generator actions preserve host-owned destinations while using private helper lifecycles.
    requirement: PROOF-02
    verification:
      - kind: unit
        ref: test/mix/tasks/crosswake_gen_proof_lane_test.exs#concurrent generators preserve host-owned destinations
        status: pass
    human_judgment: false
  - id: D3
    description: Repository-native helper source remains warning-clean under the existing compiler contract.
    requirement: PROOF-01
    verification:
      - kind: other
        ref: cc -std=c11 -O2 -Wall -Wextra -Werror -o /tmp/crosswake-proof-lane-fs-159-25 priv/native/crosswake_proof_lane_fs.c
        status: pass
    human_judgment: false
metrics:
  duration: 22m
  completed: 2026-08-02
status: complete
---

# Phase 159 Plan 25: Private Helper Provenance Summary

Proof-lane filesystem actions now execute only a freshly compiled helper inside an invocation-owned restrictive temporary directory, with the former shared cache proved inert.

## Accomplishments

- Added a discriminating poisoned-cache regression covering direct `GeneratorFS` calls and generate, check, and diff lifecycle actions.
- Replaced digest-named shared helper reuse with exclusive random directories, regular-type and permission checks, compiler-output discard, and owned cleanup.
- Preserved host-owned collision behavior, read-only checks/diffs, repeated runs, and concurrent generation through a caller-scoped private helper lifecycle.

## Verification

- `mix test test/mix/tasks/crosswake_gen_proof_lane_test.exs --seed 0` — passed (14 tests).
- `cc -std=c11 -O2 -Wall -Wextra -Werror -o /tmp/crosswake-proof-lane-fs-159-25 priv/native/crosswake_proof_lane_fs.c` — passed.
- `mix format --check-formatted lib/crosswake/proof_lane/generator.ex lib/crosswake/proof_lane/generator_fs.ex test/mix/tasks/crosswake_gen_proof_lane_test.exs` — passed.
- `git diff --check` — passed.

## Task Commits

1. **Task 1: Execute only an invocation-owned restrictive helper (RED)** — `8469346e` (`test`)
2. **Task 1: Execute only an invocation-owned restrictive helper (GREEN)** — `0e34535d` (`feat`)

## Files Created/Modified

- `lib/crosswake/proof_lane/generator_fs.ex` — owns private helper creation, validation, execution, and cleanup.
- `lib/crosswake/proof_lane/generator.ex` — scopes generator operations to one private helper lifecycle.
- `test/mix/tasks/crosswake_gen_proof_lane_test.exs` — proves poisoned legacy helper paths stay inert and concurrency remains deterministic.

## Decisions Made

- A helper is reusable only inside the caller-owned private lifecycle, never through a predictable shared temporary pathname.
- Compiler and helper output remain discarded; externally visible failures continue through the established safe result surface.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Scoped one private helper to each generator operation.**
- **Found during:** Task 1
- **Issue:** Fresh compilation for every individual generated file exceeded the existing concurrent-generator test timeout.
- **Fix:** Added an internal caller-scoped lifecycle so generate, check, and diff use one newly compiled private helper per operation while direct `GeneratorFS` calls still receive fresh private lifecycles.
- **Files modified:** `lib/crosswake/proof_lane/generator.ex`, `lib/crosswake/proof_lane/generator_fs.ex`, `test/mix/tasks/crosswake_gen_proof_lane_test.exs`
- **Verification:** Focused suite passes all 14 tests, including concurrent generation and the poisoned-cache regression.
- **Committed in:** `0e34535d`

**Total deviations:** 1 auto-fixed (1 blocking).
**Impact on plan:** Required to preserve deterministic concurrent generation without restoring a shared helper cache or widening configuration or filesystem authority.

## Known Stubs

None.

## Next Phase Readiness

The shared-temp executable provenance gap is closed for proof-lane generator actions. Plan 27 still owns fresh same-tree reconciliation; TODO-002 remains open and adopter-instance completeness remains `unknown_blocking`.

## Self-Check: PASSED

- All three modified production/test files exist.
- Both task commits are present in Git history.
