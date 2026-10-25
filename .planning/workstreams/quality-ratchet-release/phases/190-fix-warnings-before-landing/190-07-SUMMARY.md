---
phase: 190-fix-warnings-before-landing
plan: 07
subsystem: proof_lane
tags: [FIX-04, twin_runtime, registry_timeout]
requires: [190-06]
provides: [FIX-04]
key-files:
  modified:
    - lib/crosswake/proof_lane/twin_runtime.ex
    - lib/mix/tasks/crosswake.proof_lane.verify_twin.ex
    - test/crosswake/proof_lane/twin_runtime_check_test.exs
    - test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs
status: complete
requirements: [FIX-04]
actuals:
  tasks: 2
  commits: 1
plan_head_before: 01e07a51dadd06518dfaf54448693df4de157dd6
plan_head_after: 8a529f52f1d08adaa63a17d2c4d3d1bb608e562b
---

# Phase 190 Plan 07: FIX-04 registry timeout is reported and a live registry is kept

## What was checked and what happened

On the unchanged runtime, four new tests failed (`190-EVIDENCE/red-FIX-04.txt`): a suspended registry read as `registry_gone` instead of a timeout (with and without children), a timed-out stop_all stopped the registry and lost the child list, and a child that survived TERM and KILL was dropped from the registry. A second RED run showed the three `annotate_stop/2` tests failing because the function did not exist.

Now:
- `tracked_children/1` takes the runtime and reads the registry with a timeout from the new `registry_timeout_ms` field (nil means 5_000 ms). An exit of shape `{:timeout, _}` is `:timeout`; every other exit is `:gone` (assumption A3, fails closed).
- `stop_children/1` returns `{:error, :registry_timeout}` for `:timeout` and terminates no child. Both `spec`s include `:registry_timeout`.
- `stop_all/1` closes the origin listener, then calls `Agent.stop/1` only on `:ok` or `{:error, :registry_gone}`. After a timeout or `{:error, :child_still_alive}` the registry stays alive; `terminate/2` removes a child only once its OS process is gone, so a surviving child stays listed. A later `stop_all/1` after `:sys.resume` returns `:ok` and the child process is gone (tested).
- `VerifyTwin.execute/2` uses try/catch/else: on a raise it stops children and re-raises with the saved stacktrace; otherwise the result goes through public `doc false annotate_stop/2`. Only `{:error, :registry_timeout}` changes the verdict (A1): `first cause: none` becomes `registry_timeout`, and a fixed sentence about leftover child processes is appended to the next-action line. Exit code, result line, report line and the write-once receipt are unchanged. `twin_journey.ex` is untouched.

Quick run: 59 tests, 0 failures. Full suite at the commit: 2637 tests, 6 failures (all baseline names), 78 excluded, `new_failures 0`, `result pass` (`190-EVIDENCE/suite-FIX-04.txt`). Candidate HEAD is now `8a529f52f1d08adaa63a17d2c4d3d1bb608e562b`, a fast-forward from `01e07a51`, touching exactly the four files, clean. Both plan verify blocks pass when run verbatim.

## Deviations from Plan

**1. [Rule 1 - Bug] First suite gate run failed with one new name; fixed, not baselined.** My first commit placed the `annotate_stop/2` tests in the middle of `crosswake_proof_lane_verify_twin_test.exs`, which shifted a pre-existing classified collection-assertion site so the Phase 170 ledger check (`inventory_collection_assertions.exs --check`) reported 1 unclassified and 1 orphan row. Re-run alone it still failed (two names: the clean-run test and the completeness test), so it was real, not flaky. I moved the new tests to the end of that file (no ledger change), `--check` then printed OK with 243 sites, and I recreated the commit (the first commit was never fast-forwarded into the candidate). The final gate passed.

**2. Three annotate_stop tests instead of four.** The "unchanged for :ok, :registry_gone, :child_still_alive" cases are one test iterating the three results; behaviour covered is identical.

**3. Surviving-child seam.** A `sleep 30` started with `sh -c 'sleep 30 & echo $!'` (not a process-group leader) plus a harmless `cat` port, put into the live registry; real processes, killed in on_exit.

The Co-Authored-By trailer is `Claude Opus 5.5`, as the plan's verify requires.

## Checkout rule
No git command touched the recovery checkout. Planning-file commit skipped per checkout rule. No push, PR, release or twin run.

## Self-Check: PASSED
D HEAD = W HEAD, parent = FIX-05 SHA, D clean, exactly four files, trailer once, `heads.txt` has three lines ending in the FIX-04 SHA, suite file has head/`result pass`/`new_failures 0`, RED files record `red_exit` and `red2_exit`.
