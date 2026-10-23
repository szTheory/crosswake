---
phase: 187-doctor-and-proof-fidelity
plan: 06
subsystem: proof
tags: [gate, mutation-controls, doctor, proof-lane]
requires:
  - phase: 187-doctor-and-proof-fidelity
    provides: plans 01-05 (uncommitted candidate tree)
provides:
  - gate pass of the uncommitted Phase 187 tree against the Phase 186 baselines
  - 25 recorded mutation controls (0-24), each guard shown to bite
affects: [187-07]
requirements-completed: [DOCTOR-01, DOCTOR-02, DOCTOR-03, DOCTOR-04]
commits: 0
plan_head_before: bd29400722e14bed74c987bf5a9903f486dc6fc2
plan_head_after: bd29400722e14bed74c987bf5a9903f486dc6fc2
actuals:
  tasks: 2
  commits: 0
  note: "no commit by design; the single fix(187) commit belongs to 187-07"
status: complete
completed: 2026-10-16
---

# Phase 187 Plan 06: Gate and mutation proof Summary

**The uncommitted Phase 187 tree passes every gate against the Phase 186 baselines, and all 24 guard-reverting mutations make their named tests fail; nothing was committed and HEAD is still bd294007.**

All evidence is under `/private/tmp/crosswake-phase180-run` (RUNS). The candidate (`/private/tmp/crosswake-phase180-impl`) was only changed by one display-only ledger regeneration. No twin, Simulator or xcodebuild was run.

## Task 1: gates (all exits recorded in RUNS)

| Gate | Result |
|------|--------|
| Absence checker pin | literal 249 untouched; 253 test files; flagless checker exit 0, "scanned 253 test files, pin 249" |
| Ledger `--check` | first run failed (5 rows drifted); regenerated display-only (see below); recheck exit 0, 243 sites |
| Focused ExUnit (quick-187g) | 726 tests, 0 failures, exit 0 (see deviation 1 for the file list) |
| Guides and readers (guides-187g) | 289 tests, 0 failures, exit 0 |
| Docs sync `--check`, compile `--force --warnings-as-errors`, format on 14 changed .ex/.exs paths, `bash -n` harness | all exit 0 |
| Full suite (env -u MIX_BUILD_PATH) | 2622 tests, 1 failure (78 excluded); failure set is only `test/crosswake/proof/phase180_twin_feasibility_test.exs:30`; cmp-equal to `fix-186.failures` |
| Adoption scan | exit 1 (the carried deviation); the five `routing.unclassified_path` findings under examples/phoenix_host/native/ios/crosswake_shell/ are cmp-equal to `adoption-scan-186.findings` |
| Diff boundaries | 16 paths in `diff-187.paths`, all 15 required present plus the ledger; nothing under .github, no Android, no .swift, no generated guide, no `physical_iphone_contract.ex`, `physical_iphone_preflight.ex`, `policy/route.ex`, `mix.exs`/`mix.lock`; only script paths are the harness and the ledger; no added `assert/refute Enum.all?/any?(` line |

Ledger regeneration: the five drifted rows differ only in the `display` line number (four rows) and, for one row, the line number quoted inside its rationale text (295 to 385) because tests moved in `crosswake_doctor_test.exs`. Row keys, row count (243), and every classification are identical to bd294007 (`ledger-pre-187.json` against `ledger-snapshot-187.json`); `ledger-diff-187.exit` is 0. The file is changed in the uncommitted tree for 187-07 to commit.

## Task 2: mutation controls

Harness `mutate-187.sh` (from `mutate-186.sh`, Swift helpers dropped), run in the throwaway copy `/private/tmp/crosswake-187-mutation` with its own build tree; exit 0; `mutation-187.log` has exactly 25 `control ` lines and no HARNESS FAILURE. The copy was removed. The 16-path pre-mutation sha256 manifest verified after the run (all OK), so the candidate is byte-identical.

```
control 0: unmutated: passed (85 tests, 0 failures)
control 1: doctor.ex replaced whole by bd294007: failed as expected (18 tests, 9 failures)
control 2: unmanaged_routes check/6 loses its details argument: failed as expected (18 tests, 3 failures)
control 3: router inspect without the nil guard: failed as expected (8 tests, 1 failure)
control 4: Enum.uniq removed from unmanaged_paths: failed as expected (8 tests, 1 failure)
control 5: incoherent_ids computed from the filtered offline routes: failed as expected (8 tests, 2 failures)
control 6: incoherence predicate widened (D-09): failed as expected in the native_screen/cached_read_only "not flagged" test (8 tests, 1 failure)
control 7: incoherent_routes removed from the finding details: failed as expected (8 tests, 2 failures)
control 8: not_claimed branch removed: failed as expected (18 tests, 3 failures)
control 9: not_claimed severity advisory to error: failed as expected (18 tests, 2 failures)
control 10: evidence.ex replaced whole by bd294007: failed as expected (35 tests, 5 failures)
control 11: all-zero clause removed from git_ref/1: failed as expected (35 tests, 1 failure)
control 12: all-zero check moved after the hex check: failed as expected (35 tests, 1 failure)
control 13: decimal_version sentinel accepts any path: failed as expected (35 tests, 1 failure)
control 14: provenance_known?/1 returns true: failed as expected (35 tests, 3 failures)
control 15: promotion_class drops provenance_known?: failed as expected (35 tests, 1 failure)
control 16: commit_ref trusts rev-parse output: failed as expected (11 tests, 4 failures)
control 17: status check removed from commit_ref/1: failed as expected (11 tests, 1 failure)
control 18: --untracked-files=all: failed as expected (11 tests, 1 failure)
control 19: env: git_env() removed from rev-parse: failed as expected (11 tests, 1 failure)
control 20: template_version/1 ignores the manifest: failed as expected (11 tests, 1 failure)
control 21: manifest range check removed: failed as expected (11 tests, 1 failure)
control 22: verify_navigation_shell.ex replaced whole by bd294007: failed as expected (4 tests, 3 failures)
control 23: requested-and-empty evidence block removed: failed as expected (17 tests, 2 failures)
control 24: --evidence arm restored to shift 2: failed as expected (17 tests, 2 failures)
```

The full log lines name every expected test (each name is checked as a failure header by the harness, per the plan's control table). Pattern corrections: none were needed; notes are in `mutation-187.notes` (including that removing `Enum.sort` is not a control, since `Warning.unmanaged_routes/2` already sorts).

## Deviations from Plan

**1. [Rule 3 - environment, gate scope] Two test files left out of the focused run.** The plan's focused run includes all of `test/mix/tasks` with `MIX_BUILD_PATH` set. `test/mix/tasks/crosswake_gen_shell_host_test.exs` (runs `mix` with `MIX_ENV=prod`) and `test/mix/tasks/crosswake_doctor_router_test.exs` (runs `mix` in a temporary project) start `mix` subprocesses that inherit `MIX_BUILD_PATH`, so they overwrite the shared build tree; every later test using a `test/support` module then fails with "module ... is not available" (first run: 36 failures; a repeat with another seed: 129). A fresh build path did not help, because the corruption happens during the run. I removed the polluted trees, ran the focused list without those two files on a fresh `MIX_ENV=test` build (726 tests, 0 failures), and both files ran in the full suite (build path unset), which passed apart from the baseline failure. Not caused by Phase 187 files; the same plan text will hit 187-07 and later phases unless the list drops those two files. Scratch outputs: `scratch-187-*.out`.

**2. [Gate note] Adoption scan extraction.** The first line of the scan output carries a `** (Mix) ` prefix that the 186 findings file strips; I stripped it the same way before the cmp.

No Rule 1/2 fixes, no churn assertion edits, and no product code was changed in this plan. The 186 WR-03 deviation is folded in through 187-05 (controls 23 and 24).

## Known Stubs

None.

## Next step

187-07 makes the single `fix(187)` commit. Its precondition evidence: `diff-187.paths` (16 paths, the ledger included), `mutate-187.exit` (0), `mutation-187.log`, and HEAD still `bd294007`.

## Self-Check: PASSED

All artifacts exist (`fix-187.failures`, `mutation-187.log`, `candidate-187.pre-mutation.sha256`, `diff-187.paths`); the manifest verifies after mutation; the mutation copy is gone; nothing is staged; HEAD is bd29400722e14bed74c987bf5a9903f486dc6fc2.
