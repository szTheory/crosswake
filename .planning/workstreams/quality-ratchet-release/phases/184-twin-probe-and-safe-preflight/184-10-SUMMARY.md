---
phase: 184-twin-probe-and-safe-preflight
plan: 10
status: complete
gap_closure: true
requirements: [PROBE-01, PROBE-02, PROBE-03, PROBE-04]
candidate_commit: b5399e519ab44f7149480f68311189f1ec02a78d
candidate_parent: 3786de95b2b2b8435c3378fd1d194e0fecd84df5
candidate_tree: e880c7ea6aedabfbfc1f3c81d3aa987b983bb786
actuals:
  tasks: 3
  commits: 1
---

# Phase 184 Plan 10: Prove and land the second gap closure Summary

The 184-09 tree passed every gate, all eleven mutation controls failed their named tests, and it is now one local commit (b5399e51) on top of 3786de95 in the throwaway candidate. Nothing was pushed.

## Commit

- SHA `b5399e519ab44f7149480f68311189f1ec02a78d`, tree `e880c7ea6aedabfbfc1f3c81d3aa987b983bb786`, parent `3786de95b2b2b8435c3378fd1d194e0fecd84df5`.
- Subject: `fix(184-10): judge ignore-rule sources exactly (spoofed rule-file folders, quoted names, folder collapsing)`; trailer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Paths (4): `guides/see_it_run.md`, `lib/crosswake/proof_lane/twin_producers.ex`, `test/crosswake/proof_lane/twin_source_probe_test.exs`, `test/mix/tasks/crosswake_proof_lane_twin_preflight_test.exs`. `test/support/twin_git_fixtures.ex` and `script/collection_assertion_ledger.json` were not changed (the ledger check passed without regeneration).
- Guide SHA-256 (for the STATE guide-reconciliation line): `c99db902b479687551a6b6bc98c3e70787ae0206e78ecd8b2832093af9e5da0c`.
- Candidate porcelain empty; push URL still `no-push-phase180`.

## Task 1: gates on the uncommitted tree

| Gate | Result |
|---|---|
| Extractor reproduces feat-184.failures | cmp equal |
| Quick suites (8 files) | 187 tests, 0 failures |
| Full suite `mix test --exclude requires_example_host` | 2489 tests, 1 failure (78 excluded); failure set cmp-equals baseline-184.failures (only `test/crosswake/proof/phase180_twin_feasibility_test.exs:30`) |
| Guides, docs parity, ledger tests | 218 tests, 0 failures |
| Ledger check, docs sync, compile warnings-as-errors, format | all exit 0 |
| Adoption scan routing findings | cmp-equal to adoption-scan-head-184.findings (scan exit 1 is carried debt, not gated) |
| Added `assert/refute Enum.all?/any?` lines | 0 |
| History manifest | verified |

## Task 2: mutation controls (RUNS/mutation-184-09.log, 12 control lines)

- Control 0 (unmutated copy): passed, 155 tests, 0 failures.
- 1 (whole 3786de95 producer file, probe tests): the info/exclude:1:z test, the .gitignore:1:x test and the quoted-name test all failed (61 tests, 7 failures).
- 2 (same old file, preflight test): the preflight info/exclude:1:z test failed (19 tests, 1 failure).
- 3 (old text parse plus old suffix trust): the info/exclude:1:z test failed.
- 4 (old text parse alone): the .gitignore:1:x test failed.
- 5 (d(ii), tracked .gitignore trusted by basename only): the nested-.gitignore test and the info/exclude:1:z test failed.
- 6 (d(i), info/exclude clause trusts every source): the same two tests failed.
- 7 (empty source trusted): the no-deciding-rule test failed.
- 8 (framing check removed): the extra-record test failed.
- 9 (path binding removed): the misaligned-record test failed.
- 10 (directory-collapsing flag restored): the listing test failed.
- 11 (stdin file inside the candidate): the stdin-builder test failed.

Every control ran at least 61 tests with at least 1 failure and every named test appeared in the failure headers. No control needed strengthening; none was masked. The harness exited 0, the throwaway copy was deleted, and the pre-mutation manifest of the four candidate files verified byte-identical afterwards.

The narrower d(i) weakenings were applied one at a time, outside the numbering, and recorded in `mutation-184-09.notes`: a basename-exclude match (n1) and the old suffix rule with the NUL parse kept (n2) both passed (61 tests, 0 failures). Under the pinned config (`core.excludesFile=/dev/null`, `--exclude-standard`) git reads rules only from per-directory `.gitignore` files and `$GIT_DIR/info/exclude`, so no other source can reach that clause with an exclude-shaped name; these weakenings are unobservable. The d(i) guard is therefore shown load-bearing only by control 6 (clause made trust-all) and by control 3 (combined with the old parse). This is expected, not a harness failure.

## Task 3: probes and evidence

- Pre-commit probe of a full copy of the candidate (all ignored files and the real .git kept) restored to HEAD 3786de95: `{:ok, %{modified: 0, flagged: 0, excludes: 0}}` (real-probe-184-09.pre.out). Copy removed.
- Post-commit probe of the real candidate: `{:ok, %{modified: 0, flagged: 0, excludes: 0}}` (real-probe-184-09.out).
- D-36: gitlink count 0 (gitlinks-184-09.count), no `.gitmodules`.
- Post-commit five phase suites: 155 tests, 0 failures.
- History: `shasum -c history-184.before.sha256` reports 87 OK lines; no twin-05 entry.
- 184-REVIEW-DISPOSITION.md (plain, uncommitted): GAP-CR-01 and GAP-WR-01 now say "closed in 184-09/184-10" with b5399e51 and their control numbers; GAP-IN-01 and GAP-IN-02 rows carry the SHA and the gitlink count.

## Deviations from Plan

**1. [Rule 3 - Blocking] Full suite run on the default build directory, not MIX_BUILD_PATH=$B**
- **Found during:** Task 1.
- **Issue:** Two full-suite runs with `MIX_BUILD_PATH=$B` gave 28 and 88 failures plus invalid tests, all "module ... is not available" or nested-mix errors. The phase135 and phase52 proof tests spawn nested `mix` processes that inherit `MIX_BUILD_PATH` and rebuild the single shared directory while the outer suite is running. A single `MIX_BUILD_PATH` collapses the per-environment `_build` split that avoids this. The two affected test files passed alone.
- **Fix:** Re-ran the full suite with `MIX_BUILD_PATH` unset (candidate's ignored `_build/test`, the same setup 184-08 used): 2489 tests, 1 failure, failure set equal to the baseline. Quick suites, guides, probes and post-commit suites still use `$B` and were unaffected. The failed attempts are kept as `fix-184-09b.full.out` and the first run's failure list was overwritten by the rerun.
- **Files modified:** none (build output only, ignored).
- **Commit:** none.

**2. [Minor] Manifest written twice.** The first pre-mutation manifest was malformed (shell word splitting), was rewritten correctly before the harness touched anything and before any result was read; the harness never writes to the candidate.

## Notes for the orchestrator

- WR-05 (the real run does not compare record and identity digests, D-31) stays open against TWIN-07 for Phase 188's scripted pre-run check.
- D-36 deferrals carry their reopen triggers: orphan git child (reopen when a hung or leftover git is seen in a preflight or twin run); submodule config (reopen on any HEAD with a mode-160000 entry or `.gitmodules`).
- Recovery-checkout commits skipped per checkout rule. STATE.md and ROADMAP.md were not touched. Nothing is staged in the recovery checkout.
- No permanent CI lane was added for the mutation check.

## Known Stubs

None.

## Self-Check: PASSED

- Commit b5399e51 is HEAD in the candidate, parent 3786de95, 4 paths, trailer present.
- Probe outputs, gitlink count 0, history 87 OK, no twin-05, push URL unchanged, porcelain empty, recovery index empty: all checked.
