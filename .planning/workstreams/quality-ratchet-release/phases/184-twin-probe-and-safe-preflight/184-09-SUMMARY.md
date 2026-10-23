---
phase: 184-twin-probe-and-safe-preflight
plan: 09
subsystem: twin-source-probe
tags: [gap-closure, git, ignore-rules, fail-closed]
status: complete
commits: 0
plan_head_before: none (commits skipped per checkout rule; candidate HEAD stays 3786de95)
plan_head_after: none
requirements-completed: [PROBE-01, PROBE-02, PROBE-03, PROBE-04]
key-files:
  modified:
    - lib/crosswake/proof_lane/twin_producers.ex
    - guides/see_it_run.md
    - test/crosswake/proof_lane/twin_source_probe_test.exs
    - test/mix/tasks/crosswake_proof_lane_twin_preflight_test.exs
decisions: [D-35, D-36]
---

# Phase 184 Plan 09: Exact ignore-rule parsing and trust Summary

The twin source probe now reads git's ignore-rule output by splitting on NUL only and trusts only two rule sources, so a folder named like a rule-source string can no longer hide untracked source.

Commits skipped per checkout rule. All candidate edits in `/private/tmp/crosswake-phase180-impl` are uncommitted; 184-10 makes the single commit.

## Changed paths (candidate, uncommitted)

- lib/crosswake/proof_lane/twin_producers.ex
- guides/see_it_run.md (new SHA-256 `c99db902b479687551a6b6bc98c3e70787ae0206e78ecd8b2832093af9e5da0c`)
- test/crosswake/proof_lane/twin_source_probe_test.exs
- test/mix/tasks/crosswake_proof_lane_twin_preflight_test.exs

test/support/twin_git_fixtures.ex was not needed. Planning edits (plain files): 184-CONTEXT.md D-35 and D-36, four rows in 184-REVIEW-DISPOSITION.md.

## Red-first evidence (Task 1)

`red-184-09.out` / `red-184-09.exit` (exit 2, 75 tests, 4 failures, lib unchanged) on 3786de95:

| Test | Failed assertion and value |
|---|---|
| info/exclude:1:z cannot hide untracked source | probe_source got modified 0, expected 2 |
| .gitignore:1:x beside a committed .gitignore | probe_source got modified 0, expected 2 |
| committed .gitignore in a quoted-name directory | probe_source got modified 1, expected 0 |
| preflight blocks info/exclude:1:z, nothing changes | got status 0 (allowed), expected 2 blocked |

## Tests added

- Task 1: the four above (names exactly as in the plan).
- Task 3: "a listed path with no deciding rule is counted"; "a check-ignore output with an extra record makes the probe unavailable" (framing check, also drops a final field); "a misaligned check-ignore record makes the probe unavailable" (path binding, field count unchanged); "the ignored listing names files, never collapsed directories"; "check-ignore reads its paths from a private file outside the candidate through the shared builder".
- conforming?/1 gained exactly one extra shape (the stdin form: exact script text, absolute stdin path, pins, -C, check-ignore with --stdin and -z); the plain shape is not loosened.

Mutation checks (temporary, reverted): removing the framing check made the extra-record test fail; removing the path-equality check made the misaligned test fail. Each check is load-bearing on its own. No `Enum.all?/any?` assertions added.

## Final git call shapes and observed counts

- Listing: `ls-files --others --ignored --exclude-standard -z` (no `--directory`).
- One call: `check-ignore --verbose --non-matching --stdin -z`, spawned as `sh -c 'in=$1; shift; exec "$@" <"$in" 2>/dev/null' sh <stdin_path> git <pins> -C <path> ...`; stdin file `check-ignore.in` in the private index dir (exclusive create, removed with the dir).
- `rev-parse --git-path info/exclude` fetched once, only when the listing is non-empty.
- Observed: both spoof folders modified 2; quoted-name case modified 0 and clean_tree :ok.
- Updated pinned count: "an untracked directory whose own .gitignore ignores everything blocks" went 3 to 2, because the folder entry itself is no longer listed (only the two files are).

## Results

- t2 (probe, preflight, producers, verify_twin): 142 tests, 0 failures. t3: 128 tests, 0 failures.
- guides + phase69 docs parity: 199 tests, 0 failures (7 excluded). Five phase files: 155 tests, 0 failures. mix format --check-formatted: exit 0.
- Candidate porcelain shows only the four modified files, none untracked; HEAD still 3786de95; recovery index empty.

## Deviations from Plan

None - plan executed as written. Minor note: GAP rows in 184-REVIEW-DISPOSITION.md keep the original note after the new status text, so the row has an extra cell; content is accurate.

## Known Stubs

None.

## Self-Check: PASSED

Candidate files exist and are modified, evidence files present under /private/tmp/crosswake-phase180-run, D-35/D-36 and the four disposition rows present, guide sentence updated, nothing staged or committed.
