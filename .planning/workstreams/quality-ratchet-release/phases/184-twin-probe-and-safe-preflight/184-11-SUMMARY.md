---
phase: 184-twin-probe-and-safe-preflight
plan: 11
subsystem: proof-lane twin source probe
tags: [gap-closure, check-ignore, pathspec, info-exclude]
status: complete
commits: 0
plan_head_before: b5399e519ab44f7149480f68311189f1ec02a78d
plan_head_after: b5399e519ab44f7149480f68311189f1ec02a78d
requirements: [PROBE-01, PROBE-02, PROBE-03, PROBE-04]
key-files:
  modified:
    - lib/crosswake/proof_lane/twin_producers.ex
    - guides/see_it_run.md
    - test/crosswake/proof_lane/twin_source_probe_test.exs
    - test/mix/tasks/crosswake_proof_lane_twin_preflight_test.exs
---

# Phase 184 Plan 11: Literal check-ignore paths and git-exact info/exclude Summary

The probe now sends every ignored path to `git check-ignore` as `./<entry>` and binds each answer to that exact text, and it no longer trusts `.git/info/exclude` and reads its lines the way git does. A folder named `:deps` beside a committed `/deps/` rule, and an `info/exclude` line such as `  #*`, both now block instead of reading clean.

All edits are uncommitted in `/private/tmp/crosswake-phase180-impl` (HEAD still b5399e51, push URL still `no-push-phase180`). Recovery-checkout commits skipped per checkout rule; `commits: 0` is by design (184-12 makes the single commit).

## Changed candidate paths (uncommitted)

- `lib/crosswake/proof_lane/twin_producers.ex`
- `guides/see_it_run.md` (one sentence; new SHA-256 `33597cd71ee28e4fb4cc12913056d115e50caa65dfd525e2e1d2432b807fbf78`)
- `test/crosswake/proof_lane/twin_source_probe_test.exs`
- `test/mix/tasks/crosswake_proof_lane_twin_preflight_test.exs`

No new file, `test/support/twin_git_fixtures.ex` untouched.

## Final shapes

- Payload: `"./" <> entry <> NUL` per listed entry, written to `check-ignore.in`, then `File.chmod(stdin_path, 0o600)` before git reads it (chmod error is `:error`, so the probe is `:unavailable`).
- Binding: framing check (4 fields per sent entry, trailing NUL) stays separate from the binding check (`recorded == "./" <> entry`, byte for byte).
- Trust: only a `.gitignore` that is an exact fresh-index entry; `exclude_source/4` and the `rev-parse --git-path info/exclude` call used for trust were removed.
- `exclude_line_active?/1` (after one trailing CR is removed, inactive only if empty, first byte `#`, or spaces only; uses `String.trim_trailing`, never `String.trim`). `attributes_line_active?/1` keeps the old trimming, unchanged.
- Comments and docs: `git_invocation` comment names `:pinned`, `:pinned_stdin`, `:bare`; `dirty_counts` and `probe_source` docs; moduledoc names the input file. No "covered by the excludes count" text remains.

## New tests

Task 1 (twin_source_probe_test.exs): "a top-level folder named :deps cannot borrow a committed /deps/ rule", ":(top)deps" variant, "a folder named : holding deps cannot borrow a committed /deps/ rule", "a top-level folder named :!deps is judged as written", "folders whose names hold glob characters are judged as written" (guard). Preflight: "a top-level folder named :deps blocks the preflight and nothing changes".
Task 2: "an info/exclude line that starts with spaces before # is a live rule", "an info/exclude line holding only a tab is a live rule", "a file hidden by an info/exclude rule counts as a change as well as the rule", "only an empty, first-byte # or space-only info/exclude line is inactive" (guard). Preflight: "an info/exclude line that starts with spaces blocks the preflight and nothing changes".
Task 3: "a check-ignore record that does not echo the exact sent text makes the probe unavailable", "check-ignore is sent each listed path as ./ and the entry, in a file only its owner can read".

## Red runs (all on b5399e51 producer code; exit 2 each)

- red-184-11a: 86 tests, 5 failures (the plan's expected set). `:deps`, `:(top)deps`, `: holding deps` got `{:ok, %{modified: 0, flagged: 0, excludes: 0}}`; `:!deps` got `:unavailable`; the `:deps` preflight got status 0 "result: allowed". Glob guard passed. Evidence files: `red-184-11a.out/.exit`.
- red-184-11b: 91 tests, 4 failures. spaces-# and tab got all-zero; hidden `secret.txt` got `{modified: 0, excludes: 1}`; spaces preflight got status 0 "result: allowed". Inactive-line guard passed.
- red-184-11c: 72 tests, 1 failure: input-file test, mode got 420 (0o644) instead of 384 (0o600). umask was 022 (`umask-184-11.out`). The echo-binding test passed already, as the plan predicted.

## Green runs

- t1-184-11: 153 tests, 0 failures. t2-184-11: 158 tests, 0 failures. t3a-184-11: 72 tests, 0 failures.
- guides-184-11: 199 tests, 0 failures (7 excluded). phase-184-11: 168 tests, 0 failures. format-184-11: exit 0.
- No existing pin changed. No `assert/refute Enum.all?/any?` added (`diff-t3-184-11.out`). Candidate porcelain shows only the four modified files, none untracked.

## Deviations from Plan

**1. [Rule 1 - Bug in new test] The first red run of the `:deps` preflight test failed for the wrong reason**
- **Found during:** Task 1 (first green run).
- **Issue:** the test committed `.gitignore` after setup had written the prepared record, so HEAD no longer matched and the preflight returned `identity_mismatch` (status 2) both red and green.
- **Fix:** the test now writes a new prepared record with the new head and tree after the commit and passes it to `args/2`. The five-failure red run was repeated in a throwaway copy (`/private/tmp/crosswake-184-11-red`, lib restored from b5399e51 with `git show`, since removed); the preflight test then failed for the intended reason (status 0, "result: allowed"). The corrected run is `red-184-11a.out`; the first run is kept as `red-184-11a-first.out`. The real candidate was never reverted.

## Known Stubs / Threat Flags

None. Fixtures are synthetic (`:deps`, `evil.ex`, `secret.txt`); no adopter data.

## Self-Check: PASSED

- Candidate HEAD b5399e51, nothing staged, push URL `no-push-phase180`; recovery checkout at d0f3e2f1 with nothing staged.
- All gate exit files are 0 except the red runs, which are non-zero by design. D-37 and D-38 are in 184-CONTEXT.md; the five GAP2 rows say "fixed in 184-11 (commit in 184-12)". STATE.md and ROADMAP.md untouched.
