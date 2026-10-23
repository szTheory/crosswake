---
phase: 169-diagnostic-legibility
plan: 05
subsystem: ci-diagnostics
tags: [elixir, exunit, github-actions, release-please, maven, trigger-isolation]

requires:
  - phase: 169-03
    provides: "The display-name and trigger non-vacuity proof file reconciled by this gap-closure plan."
  - phase: 175-11
    provides: "The isolated push-only Release Please and dispatch-only Maven fire-drill workflows."
provides:
  - "A two-workflow, exact-key trigger-partition proof: Release Please is push-only and the Maven fire drill is workflow_dispatch-only."
  - "Synthetic re-coupling, empty maps, and invalid trigger inputs that demonstrably make the proof fail."
affects: [169, 175, release-workflows, ci-diagnostics]

actuals:
  tokens: 900
  tasks: 1
  commits: 1
plan_head_before: 8eb289b80c575e76aee53fd959657cfbf5145268

tech-stack:
  added: []
  patterns:
    - "Use an extracted two-input predicate with positive and synthetic-negative cases when an authority contract spans multiple workflow files."

key-files:
  created: []
  modified:
    - test/crosswake/proof/phase169_check_name_uniqueness_test.exs

key-decisions:
  - "Treat the isolated Maven rehearsal as a separate, dispatch-only authority surface; Release Please remains exactly push-only."
  - "Keep D-23 non-vacuity with positive, re-coupling, empty-map, and invalid-input predicate controls."

requirements-completed: [MSG-06]

coverage:
  - id: D1
    description: "The Phase 169 proof reads both live workflow trigger maps and requires the exact push-versus-workflow_dispatch partition without restoring a manual Release Please trigger."
    requirement: MSG-06
    verification:
      - kind: unit
        ref: "MIX_ENV=test mix test test/crosswake/proof/phase169_diagnostic_legibility_test.exs test/crosswake/proof/phase169_check_name_uniqueness_test.exs test/crosswake/proof/phase169_exit_contract_guard_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "The extracted trigger predicate rejects dispatch or pull-request re-coupling on Release Please, push re-coupling on the Maven drill, and empty or non-map input on either side."
    requirement: MSG-06
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase169_check_name_uniqueness_test.exs#Task 3: trigger-partition guard rejects synthetic re-coupling and empty scopes"
        status: pass
    human_judgment: false

duration: 9min
completed: 2026-09-22
status: complete
---

# Phase 169 Plan 05: Isolated Trigger Contract Summary

**Phase 169 now proves that ordinary release authority is push-only while the disposable Maven rehearsal is dispatch-only, with mutation-backed rejection of every cross-wiring path.**

## Performance

- **Duration:** 9min
- **Completed:** 2026-09-22T12:03:52Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Replaced the stale one-workflow trigger check with an exact two-workflow partition predicate.
- Read both checked-in workflow maps through the existing PyYAML/Jason helper, preserving production YAML as read-only test input.
- Kept D-23 non-vacuous with an accepted control plus rejected manual, pull-request, push, empty-map, and invalid-input variants.

## Task Commits

1. **Task 1: Replace the stale co-located trigger invariant with a non-vacuous isolation contract** - `8542502e` (test)

## Evidence

- Command: MIX_ENV=test mix test test/crosswake/proof/phase169_diagnostic_legibility_test.exs test/crosswake/proof/phase169_check_name_uniqueness_test.exs test/crosswake/proof/phase169_exit_contract_guard_test.exs — 53 tests, 0 test errors (run twice; second run was the tracer feedback gate).
- The initial focused test was red exactly as planned: the old assertion required `push` and `workflow_dispatch` in Release Please, while the live isolated workflow exposes only `push`.

## Decisions Made

- Release Please retains D-18's no-`pull_request` authority conclusion and is now explicitly asserted as push-only; Plan 175-11's dedicated Maven fire drill alone owns `workflow_dispatch`.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- `test/crosswake/proof/phase169_check_name_uniqueness_test.exs` exists and is present in task commit `8542502e`.
- The persisted ledger measures one task commit from `8eb289b80c575e76aee53fd959657cfbf5145268` to the task commit.

## Next Phase Readiness

G-169-1 is closed. The repaired diagnostic proof accepts the intentional Phase 175 trigger isolation without changing release behavior.
