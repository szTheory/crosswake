---
phase: 191-integration-branch-and-local-suite
plan: 02
status: complete
requirements: [LAND-01]
commits: 0
plan_head_before: not_recorded_frozen_checkout
plan_head_after: not_recorded_frozen_checkout
actuals:
  tasks: 2
  commits: 0
---

# Phase 191 Plan 02: Planning-carry tool Summary

## Result

One-liner: a bash tool that works out which `.planning/` records differ in raw bytes from main, sorts each into a milestone commit (v23.0 to v27.0) by a table that fails on any unmatched path, applies the home, temp and account-name privacy rewrite, and checks the landed result against `git diff --raw` exactly. It is proven by 25 self-test controls (the plan required 23), and a dry run against the real trees passed with nothing unmatched, ignored or symlinked.

- Tool: `carry-191.sh` with `manifest [--sync]`, `apply`, `commit-bucket` and `verify`. It reads the source tree with plain file reads, runs git only through the pinned `g()` helper, and prints only `carry:` labels and counts (no paths, no content).
- Self-test: `selftest-carry: controls 25 of 25 as expected` (S01-S25). The stored output equals a fresh run. Each negative control (dropped file, flipped byte, extra file, mode change, empty manifest, unmatched path, symlink, FIFO, ignored-not-excluded, missing landed hash, changed-source, uncovered inventory row, excluded path present, brace row, unused rule) fails with its own exact label. The A-6 controls pass: a moved file holding a home line is transformed (S21); a same-path raw-identical file holding a home line is not listed, not written and not transformed, and a mode-only same-path file is counted and not listed (S22); a `--sync` re-run against the commit that landed transformed files reports `already landed 2` and `empty delta`, then lists exactly one path after a later raw edit (S23).
- Both automated verifies of Tasks 1 and 2 exit 0 (the Task 2 verify uses `set -- $T`, so run it under sh or bash; zsh does not split it).

## Dry run (real trees, no commit, writes only in the run folder)

Source: the recovery working tree. Base: the durable candidate at its HEAD `2faf15a255f644c869d321508c4d3f3007572138`. Exit 0, `result pass`. Counts against the plan's approximate figures:

| Item | Measured | Plan figure |
|---|---|---|
| Added (A) | 2474 | about 2442 |
| Modified (M) | 13 | about 13 |
| Deleted (D) | 141, all under phases 169-175 | 141 |
| Excluded source files | 46 | about 45 |
| Same-path identical, not listed | 1767 | about 1767 |
| of those holding a pattern, left untouched | 358 | about 358 |
| Moved files, untransformed / transformed | 120 / 4 | about 127 moved, about 4 transformed |
| Transformed in total | 244 | (research: 243 home plus a few temp) |
| mode_only, already_landed | 0, 0 | 0, 0 |
| Buckets v23.0 / v24.0 / v25.0 / v26.0 / v27.0 | 1781 / 189 / 258 / 177 / 223 | all non-zero |

Differences stated plainly: added is 32 higher than the plan's estimate because the estimate subtracted exclusions from the research's raw additions and the tree has since grown (Phase 191 files, the new seed work); moves split 120 plus 4 (124 total, the plan said about 127). Neither affects any gate. Unmatched 0, ignored-not-excluded 0, symlinks 0, unused rules 0. Plan 10 recomputes all of this at the real cut. Manifest digest from the dry run is kept only in the run folder output.

## Deviations from Plan

**1. [Rule 2 - Missing critical] Coverage exemption is by exclusion reason, not only R-PL-24.** The inventory also lists the workstream `state.json` as R-PL-40 "to land", and A-2 excludes it. Verify therefore skips any to-land row whose path is an exclusion entry whose reason contains `A-2`, in addition to R-PL-24. Without this, verify would always report one uncovered row.

**2. [Interpretation] Extra controls and a test hook.** Added S24 (missing landed hash) and S25 (exclusion counted, not listed), using a test-only environment switch `CARRY_TEST_BLANK_LANDED=1`, since the missing-hash path cannot otherwise be reached.

**3. [Interpretation] Verify inputs.** `verify` takes no exclusions or inventory argument, so it reads `carry-exclusions-191.tsv` and the Phase 189 inventory beside the script, overridable with `CARRY_EXCL` and `CARRY_INVENTORY` (used by the fixtures).

**4. [Rule 1 - Bug, found by self-test] Two defects fixed before the proof run.** `commit-bucket` now compares staged names with `--no-renames` (a moved file otherwise shows as a rename and hid the deleted path); the ignore check now feeds NUL-separated paths to `check-ignore -z --stdin`.

**5. Sidecar files.** `manifest` also writes `OUT.src` (the source top, for apply's source-changed check) and `OUT.d/` (landed bytes, named by landed sha256), both in the run folder only.

**6. Performance.** The real-tree manifest takes a few minutes (one transform pass per carried file); it exceeded the interactive tool timeout and ran in the background.

No rule was removed as dead and the table was not widened.

## Known Stubs

None.

## Threat Flags

None. The script, table, exclusions and evidence hold no home path, account name, temp path or file content (the account name was grepped against every file this plan wrote: 0 hits).

Commit: none; the recovery checkout is frozen and this plan makes no commit.

## Self-Check: PASSED

Files exist: `carry-191.sh`, `carry-table-191.tsv`, `carry-exclusions-191.tsv`, `selftest-carry-191.sh`, `191-EVIDENCE/selftest-carry-191.out`, `191-EVIDENCE/carry-dryrun-191.txt`. Verify commands exit 0.
