---
phase: 184-twin-probe-and-safe-preflight
plan: 01
subsystem: twin-proof-lane
tags: [git, source-probe, fail-closed, fresh-index]
requires: []
provides:
  - TwinProducers.probe_source/2 (fresh-index probe, flagged-tag count, exclude count)
  - one private git builder (git_invocation/3) and sole spawn site (run_git/4)
affects: [184-02, 184-03]
key-files:
  modified:
    - /private/tmp/crosswake-phase180-impl/lib/crosswake/proof_lane/twin_producers.ex
    - /private/tmp/crosswake-phase180-impl/test/crosswake/proof_lane/twin_producers_test.exs
  created:
    - /private/tmp/crosswake-phase180-impl/test/support/twin_git_fixtures.ex
    - /private/tmp/crosswake-phase180-impl/test/crosswake/proof_lane/twin_source_probe_test.exs
status: complete
commits: 0
plan_head_before: 50fcd5743243c0b20275a7e2bd9338bf25468687
plan_head_after: 50fcd5743243c0b20275a7e2bd9338bf25468687
actuals:
  tasks: 2
  commits: 0
---

# Phase 184 Plan 01: Fresh-index twin source probe Summary

The twin source probe now compares the working tree against a fresh index built from HEAD, counts hidden-flag index entries separately, and spawns git only through one pinned builder; every stat-cache, flag, mode, untracked, unmerged and attribute hiding mechanism in the plan has a real-repo test that blocks.

Nothing is committed: all candidate edits are uncommitted by design (the single candidate commit is 184-06), and no commit, staging or planning-doc commit was made in the recovery checkout.

## Baselines (taken before the first edit)

- Full suite at HEAD 50fcd57 (`mix test --exclude requires_example_host`): 2399 tests, 1 failure, 78 excluded. The one failure is `test/crosswake/proof/phase180_twin_feasibility_test.exs:30`, identical to the 183 baseline. Files: `baseline-184.full.out`, `baseline-184.failures` in `/private/tmp/crosswake-phase180-run`.
- `history-184.before.sha256`: 87 lines, mode 0400, `shasum -a 256 -c` all OK. It covers every path in `history-183.before.sha256` (54), every file under `twin-04` (19) plus the listed twin-04 side files, `history-183.before.sha256` itself, and the 183 `TWIN-RESULT.json` and `IDENTITY.json`. No listed name was missing, so nothing was skipped.
- `COVERAGE.md` written with the single "No external API integration" line.

## What was built

- `twin_producers.ex`: D-05 env and pin lists as module attributes (including `core.attributesFile=/dev/null` per D-23); `git_invocation/3` (modes `:pinned` and `:bare`; only GIT_INDEX_FILE may vary); `run_git/4` is the only `git_cmd` call (NUL refusal, Task timeout via `:git_timeout_ms` default 60 000, `ArgumentError`/`ErlangError` rescued without reading the message); `probe_source/2` (version floor >= 2.41, absolute git dir, real-index `ls-files -v -z` parsed fail-closed, private 0700 temp index created only after a device/inode containment check against candidate, git dir and `:run_root`, `read-tree HEAD`, fresh-index `ls-files` all `H`, `status --porcelain=v1 -z`, guaranteed removal, exclude-rule count); `clean_tree/2` and `dirty_count/2` as views; D-33 disclosures in the docs.
- `twin_git_fixtures.ex` (`Crosswake.ProofLane.TwinGitFixtures`): `repo!/0`, `git!/2`, `raw_git/3`, `git_env/1`, `env_restore/1`, `same_mtime_edit!/3`, `flag!/3`, `set_config!/3`, `unmerged!/1`, `crlf_edit!/2`, `listing/1`, `old_mtime/0`.
- `twin_source_probe_test.exs`: 17 top-level tests, all passing under `--trace` (the 3 tracer tests: untouched clone, assume-unchanged edit through `freeze`, exclude rule; plus the 14 matrix tests with the exact names in the plan).
- `twin_producers_test.exs` (below line 265 only): staged-rename test renamed to "a staged rename blocks and counts as two findings" asserting 2; the fd-level stderr test now delegates to the real git and requires at least 8 logged calls (still all `null`).

## Results

- Probe test file: 17 tests, 0 failures. Producers suite: 43 tests, 0 failures.
- Full suite after the change: 2416 tests, 1 failure (same `phase180_twin_feasibility_test.exs:30`), 78 excluded. That is baseline plus the 17 new tests, with no new failure.
- Inventory ledger check OK (243 sites); compile with warnings-as-errors clean; format check clean; no `assert/refute Enum.all?/any?(` added; `twin_runtime.ex` untouched; exactly one non-comment `git_cmd.(` call site.
- Recovery checkout has no staged paths; candidate HEAD is still 50fcd5743243c0b20275a7e2bd9338bf25468687; `history-184.before.sha256` still verifies; no twin-05 entry exists.

## Deviations from Plan

1. [Verify wording] The plan's trace gate looks for the line `test a staged rename blocks and counts as two findings (`. That test lives inside the existing `describe "source cleanliness"` block (it needs that block's setup), so ExUnit prints it as `test source cleanliness a staged rename blocks and counts as two findings (`. The test ran and passed (line 27 of `quick-184-01-t1.out`); only the plan's literal grep string would not match. Later gates should match without the `test ` prefix.
2. [Rule 1 - fixture precondition] The two attribute fixtures (tracked eol and user-level attributes) first asserted that ordinary raw `git status` is blind. It is not: a CRLF edit changes the file size, and git treats a size change against a stat-carrying index as modified before any content conversion. The attributes only hide the edit when the index has no recorded sizes, which is exactly the fresh-index case. Both fixtures now prove blindness with an unpinned fresh-index git (`fresh_blind?/2`), and the user-level fixture also proves it under the user attributes environment. The probe code did not need changing.
3. [Design detail] A missing `:run_root` path is ignored (a nonexistent directory cannot contain anything); a missing candidate or git dir is fail-closed. The containment walk follows real parents (`..`) by device and inode rather than text parents, so a symlinked component cannot hide containment.

No fix to probe behaviour was needed after the matrix ran; all 14 matrix fixtures passed against the first implementation apart from deviation 2 (test-side).

## Known Stubs

None.

## Threat Flags

None. The probe's only new filesystem write is the private temp index, which is covered by T-184-03 and tested.

## Notes

Planning-doc commits were skipped by instruction (sequential, uncommitted candidate). STATE.md and ROADMAP.md were not touched. The configuration refusals (`:hiding_config`, `:not_toplevel`), the fail-closed version and output-shape tests, and the call-site migration remain for 184-02 and 184-03.

## Self-Check: PASSED

Created files exist (fixtures module, probe test, COVERAGE.md, baseline and history files); candidate HEAD unchanged; recovery index empty.
