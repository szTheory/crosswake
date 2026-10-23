---
phase: 184-twin-probe-and-safe-preflight
plan: 13
subsystem: proof-lane twin source probe
status: complete
tags: [probe, git-stderr, attributes, config-spelling, gap-closure]
requirements: [PROBE-01, PROBE-02, PROBE-03, PROBE-04]
key-files:
  modified:
    - lib/crosswake/proof_lane/twin_producers.ex
    - test/crosswake/proof_lane/twin_source_probe_test.exs
    - test/mix/tasks/crosswake_proof_lane_twin_preflight_test.exs
    - test/support/twin_git_fixtures.ex
    - test/crosswake/proof_lane/twin_producers_test.exs
decisions: [D-39, D-40]
commits: 0
actuals:
  tasks: 2
  commits: 0
---

# Phase 184 Plan 13: Unreadable folders, git-format text (D-39, D-40) Summary

Every git call in the twin source probe now keeps git's stderr in a shell variable and fails (exit 125, so probe unavailable, prerequisite_missing) when it is non-empty; info/attributes, info/exclude, git output and config values are now read the way git reads them. All edits are uncommitted by design (plan makes no commit; recovery-checkout commits skipped per checkout rule). HEAD of the candidate is still e4344ca5.

## Run history

The first run was BLOCKED (184-13-BLOCKED-run1.md) at the Task 1 green gate: the stale test "every git invocation discards stderr at the descriptor level" in twin_producers_test.exs pinned the e4344ca5 design that D-39 replaces, and that file was not in files_modified. The orchestrator amended the plan (file added, new Step B2). This second run did Step B2 and finished both tasks.

## Task 1 (D-39)

Red (RUNS/red-184-13a.out, exit 2, "99 tests, 6 failures"), each for the stated reason:
- T1a untracked 0111 folder, T1b tracked 0311 folder, T1c ignored 0111 folder, T1d status stderr stub, T1e check-ignore stderr stub: each failed with left `{:ok, %{modified: 0, excludes: 0, flagged: 0}}`.
- T1f preflight with an unreadable folder: block contains "result: allowed".

Fix: `@git_script` added, `@stdin_script` replaced, the non-stdin branch of git_invocation uses `@git_script`, comment rewritten, test copies and conforming?/1 updated, `TwinGitFixtures.unlistable!/2` added.

Step B2: test renamed "every git invocation captures stderr in a pipe the probe tests for emptiness". The fake git records `pipe` / `null` / `other` for fd 2; the test wraps the three calls in capture_io(:stderr), asserts captured is "", `Enum.uniq(lines) == ["pipe"]` and `length(lines) >= 8`. Under the e4344ca5 discard text fd 2 is /dev/null, so it records `null` and the test fails (to be added to 184-14 control 19; not mutation-run here).

Green (RUNS/t1-184-13.out, exit 0): 174 tests, 0 failures. Task 1 automated check: passed.

## Task 2 (D-40)

Red (RUNS/red-184-13b.out, exit 2, "108 tests, 6 failures"):
- T2a NBSP attributes line: left `{:ok, %{modified: 0, flagged: 0, excludes: 0}}`.
- T2b non-ASCII-blank prefixes: first prefix left `{"\v", {:ok, %{modified: 0, flagged: 0, excludes: 0}}}`.
- T2f core.symlinks=00: left all-zero `{:ok, ...}`. T2g worktreeConfig=2: left all-zero `{:ok, ...}`.
- T2d CR CR LF exclude: left `{:ok, %{modified: 1, flagged: 0, excludes: 0}}`.
- T2i preflight: "result: allowed".
- Guards T2c, T2e, T2h passed (no failure block).

Fix: attributes_line_active? strips only leading space/tab/CR/LF (byte 0 must be `#` to be a comment); read_exclude splits on LF only; git/3, attributes_refusal, absolute_git_dir and exclude_rules strip exactly one trailing LF; config values ASCII-downcased with no trim; git_true?/git_false? replace truthy?/falsy?, with hiding_entry? refusing unless a safe git spelling. No `String.trim(` remains.

Green (RUNS/t2-184-13.out, exit 0): 183 tests, 0 failures.

## Deviations from Plan

**1. [Plan defect, no code change] Task 2 automated check, T2b pattern.** The check greps `left: +\{:ok, %\{` for the T2b block, but T2b's assertion compares a `{prefix, probe}` tuple, so its left line is `{"\v", {:ok, ...}}` and the literal check exits 1 at that step. The failure is for the intended reason (all-zero probe on e4344ca5); I verified it with the pattern `left: +\{"\\v", \{:ok, %\{` and then ran every remaining clause of the check (T2d `excludes: 0`/modified 1, T2i "result: allowed", three guards empty, t2 green, no String.trim(, git_true?/git_false?, no truthy?/falsy?, HEAD, empty recovery index), all passing. The plan's T2b literal check needs the tuple-aware pattern (184-14 should use it).

**2. [Plan amendment] Step B2** edited twin_producers_test.exs (see above).

Auth gates: none. Stubs: none. Threat flags: none.

## Final state

Changed candidate paths (uncommitted): the five files_modified entries only. HEAD e4344ca523a56e146d9e8647ec141b9714e8180f; push URL no-push-phase180; recovery index empty; no twin, Simulator or xcodebuild run; STATE.md and ROADMAP.md not touched.

## Self-Check: PASSED
Files verified present and modified in the candidate; red/green evidence files exist under /private/tmp/crosswake-phase180-run; no commits were expected (commits: 0).
