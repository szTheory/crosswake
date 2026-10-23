---
phase: 185-checks-that-cannot-pass-empty
plan: 02
subsystem: proof-lane twin cleanup
tags: [GUARD-03, twin_runtime, stop_children]
requirements: [GUARD-03]
status: complete
commits: 0
plan_head_before: b898e1104b0feafdb569d1ae42972cb4e1c46629
plan_head_after: b898e1104b0feafdb569d1ae42972cb4e1c46629
key-files:
  modified:
    - lib/crosswake/proof_lane/twin_runtime.ex
    - test/crosswake/proof_lane/twin_runtime_check_test.exs
    - test/crosswake/proof_lane/twin_journey_test.exs
    - test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs
actuals:
  tasks: 2
  commits: 0
---

# Phase 185 Plan 02: Twin cleanup reports a gone registry Summary

`TwinRuntime.stop_children/1` and `stop_all/1` now return `{:error, :registry_gone}` when the run registry is already gone, instead of reading an empty list and reporting `:ok`. All changes are uncommitted in the candidate (/private/tmp/crosswake-phase180-impl); plan 185-05 makes the single fix commit, so `commits: 0` here is by design.

## What was checked and what happened

- Preconditions: candidate HEAD b898e110, push URL `no-push-phase180`, pin guard exit 0, porcelain held only 185-01's two files.
- Stop sites were listed before editing (RUNS/stop-sites-185-02.txt): nine asserted sites and three bare calls, as research said. None runs after an earlier stop on the same runtime. Producers at verify_twin_test :427 and :439 stop the registry, so the command's own after-block `stop_all` runs on a stopped registry (its result is discarded).
- Red first: the new twin_runtime_check tests ran against the unchanged code (RUNS/red-185-02.out, exit 2): 13 tests, 3 failures. The failing headers were the registry_gone, origin-listener and tracked-child tests. The zero-children and tolerance tests passed on old code, as they should (they pin behaviour that must not regress).
- Green: twin_runtime_check_test 13 tests, 0 failures (RUNS/t1-185-02.out). twin_journey_test 10 tests, 0 failures. verify_twin_test 25 tests, 0 failures. Twin quick suite (8 files): 225 tests, 0 failures (RUNS/quick-185-02.out). `mix format --check-formatted` clean on the four files. No leftover `sleep 30` processes.

## Code change (twin_runtime.ex)

- New private `tracked_children/1` reads the registry in a function-level try; its catch clause is exactly `:exit, _ -> :gone` (success is `{:ok, children}`). A call timeout is also reported as gone, noted in a comment.
- `stop_children/1`: `{:ok, children}` keeps the `:ok` / `{:error, :child_still_alive}` rule (a live registry with zero children is `:ok`); `:gone` returns `{:error, :registry_gone}`.
- `stop_all/1`: always closes the origin listener, tries `Agent.stop` inside `catch :exit`, then returns the `stop_children` result. No flag, no `start_link`.
- Both `@spec` lines are `:ok | {:error, :child_still_alive | :registry_gone}`; docs updated.
- `first_failure/1`, `record_failure/2`, `mark_exited/2` use `catch :exit` instead of `Process.alive?`; results stay nil and `:ok`. No `Process.alive?(registry)` remains.

## Tests added (named as in the plan)

- twin_runtime_check_test.exs: the five named tests (registry_gone; listener released plus registry_gone; zero children `:ok`; tracked child with gone registry, process group killed in on_exit; first_failure/record_failure tolerance).
- twin_journey_test.exs: the source pin (bare `TwinRuntime.stop_children(runtime)` statement, no binding or case) and the dead-registry run through `TwinJourney.run/3`. Both a dead and a live-control runtime have a database path outside the run root, so the run blocks at `start_backend` (or the tool lookup) with `{:blocked, :prerequisite_missing}`; no backend, Simulator or xcodebuild starts. The dead one then reports `{:error, :registry_gone}`, showing `finish/2` met a gone registry without raising.
- verify_twin test: a producer stops the registry and then returns passing observations; exit code 0, the four-line result, and the receipt file are unchanged.

## D-14 deferred item

`twin_journey.ex` and `verify_twin.ex` still discard the stop result. Letting a stop failure change the run verdict is deferred; reopen on the next twin change that already alters the cause list or receipt (Phase 188 or later), or after any run that leaves a process behind. Registry ownership (the registry is an unlinked Agent) is also deferred.

## Deviations from Plan

None. The plan executed as written. Neither twin_journey.ex nor verify_twin.ex was touched.

## Known Stubs

None.

## Self-Check: PASSED

Files edited exist; RUNS evidence files present (stop-sites, red out/exit, t1, t2 journey and verify, quick); candidate porcelain shows only 185-01's two files plus this plan's four.
