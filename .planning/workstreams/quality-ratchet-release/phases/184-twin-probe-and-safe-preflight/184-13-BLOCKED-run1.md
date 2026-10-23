# Plan 184-13 BLOCKED (not executed to completion)

Status: blocked at the Task 1 green gate. Zero requirements completed. This is not a SUMMARY.
Recovery-checkout commits skipped per checkout rule. Nothing was committed anywhere.

## What was done (uncommitted, in /private/tmp/crosswake-phase180-impl, HEAD still e4344ca5)

- Task 1 Step A (red): RUNS/red-184-13a.out, exit 2, "99 tests, 6 failures". T1a-T1e each fail with
  left `{:ok, %{modified: 0, excludes: 0, flagged: 0}}` (e4344ca5 probes all-zero); T1f's block holds
  "result: allowed". All six fail for the stated reason.
- Task 1 Step B (fix): `@git_script` added and `@stdin_script` replaced with the D-39 stderr-capture
  texts in `lib/crosswake/proof_lane/twin_producers.ex`; non-stdin branch uses `@git_script`; comment
  rewritten. Test copies and `conforming?/1` updated; `TwinGitFixtures.unlistable!/2` added; `mix format` run.
- Task 1 Step C (green): RUNS/t1-184-13.out, exit 2, "174 tests, 1 failure". All six new tests pass.
  Task 2 was NOT started.

## The one failure (privacy-safe cause)

`test/crosswake/proof_lane/twin_producers_test.exs:755`, test "source cleanliness every git invocation
discards stderr at the descriptor level" (Crosswake.ProofLane.TwinProducersTest). It installs a fake `git`
that records whether its fd 2 is `-ef /dev/null` and asserts every line is `null`. Under D-39 git's stderr
is deliberately a pipe into a shell variable (tested only for emptiness), so the stub records `leak`
(`left: ["leak"]`, `right: ["null"]`). This is not a probe regression: clean_tree/dirty_count/freeze all
still return the expected results. The test pins the old D-05/D-23 design that D-39 amends.

This is not the "existing test turned :unavailable because real git wrote stderr" case; no git subcommand
wrote stderr. It is a stale design pin in a file outside this plan's allowed changed paths
(`twin_producers_test.exs` is not in files_modified), so I did not edit it.

## Needed decision

Amend plan 184-13 (or 184-15) to allow editing `test/crosswake/proof_lane/twin_producers_test.exs` and
re-point that test to the D-39 contract, for example: the fake git records that fd 2 is NOT inherited from
the BEAM (not a terminal and not the shared stderr) and that the shell's own stderr stays /dev/null, still
requiring `length(lines) >= 8`; or fold it into the new stderr-stub tests. Then re-run the Task 1 green
gate and proceed to Task 2.

## State left behind

Candidate has four uncommitted modified files (the allowed ones); HEAD e4344ca5; push URL no-push-phase180;
recovery index empty; no twin run, no new directories.
