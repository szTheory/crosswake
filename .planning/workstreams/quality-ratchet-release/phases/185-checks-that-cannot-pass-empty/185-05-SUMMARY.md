---
phase: 185-checks-that-cannot-pass-empty
plan: 05
subsystem: testing
tags: [gate, mutation-controls, candidate-commit]
requirements-completed: [GUARD-01, GUARD-02, GUARD-03]
status: complete
commits: 1
plan_head_before: b898e1104b0feafdb569d1ae42972cb4e1c46629
plan_head_after: 25614cf685e2ee299646e04b833293c677023c45
actuals:
  tasks: 3
  commits: 1
completed: 2026-10-16
---

# Phase 185 Plan 05: Prove and land Phase 185 Summary

Phase 185 is one commit on the candidate: `25614cf685e2ee299646e04b833293c677023c45` (tree `b2f885e0280fde0bba39da552c96ed35408e3be1`, parent `b898e1104b0feafdb569d1ae42972cb4e1c46629`), subject `fix(185): fail when a check examines nothing`, with the required trailer. The candidate is clean afterwards and its push URL is still `no-push-phase180`. Nothing in the planning checkout was staged or committed.

## What was checked and what happened

Task 1, gates on the uncommitted tree:
- Pin (D-03): independent count of test `.exs` files = 249, pin literal = 249, checker prints "scanned 249 test files, pin 249" (exit 0). No pin edit.
- Ledger: `--check` first failed (4 rows with shifted lines). `--emit-snapshot` writes to stdout, so the output was saved and copied over the ledger; `--check` then exits 0 (243 rows). Drift proof: the header is identical, bucket counts are identical (135/41/4/63), and rows minus `display` and with the digits of "at line N" in the rationale normalised cmp-equal. The plain "rows minus display" comparison is NOT byte-equal, because four rationale texts embed the line number of the guard they cite ("guarded ... at line 594"). That is a display-derived line shift, not a re-bucket (see Deviations). Ledger is part of the commit.
- Final loop scan: 45 files, 96 sites, exit 0 (`185-LOOP-SCAN.after.txt`). No "pending 185-04" marker remained; an after-scan note was appended to `185-LOOP-MEASUREMENT.md`.
- Extractor reproduces `feat-184.failures`.
- Twin quick suite plus the absence test: 256 tests, 0 failures. Guides, parity and ledger tests: 219 tests, 0 failures. Docs sync, compile with warnings as errors, and format: all exit 0.
- Full suite (`--exclude requires_example_host`): 2549 tests, 1 failure (78 excluded). The failure set cmp-equals `baseline-184.failures` (only `test/crosswake/proof/phase180_twin_feasibility_test.exs:30`).
- Adoption scan: exit 1 (recorded, not gated); the 5 routing findings cmp-equal `adoption-scan-head-184.findings`.
- Diff gates: no added `assert/refute Enum.all?/any?(` line; no `.github/` path; the only `script/` paths are the checker and the ledger (D-12).

Task 2, mutation controls in the throwaway copy: see the 20 log lines below. Harness exit 0, copy deleted, the pre-mutation manifest of the 15 changed candidate files verifies, no zero-test run.

Task 3: HEAD-copy probe, commit, post-commit probe, post-commit suites, flagless checker, history manifest and preflight, all as below.

## The 20 mutation log lines (mutation-185.log)

Every line is "failed as expected" unless marked. Test counts are for the target files run.

- 0 unmutated: passed (154 tests, 0 failures).
- 1 whole b898e110 checker: the four root floors plus the empty-tree and dot-directory scope tests fail (23 tests).
- 2 root existence check removed: "root floor: a nonexistent --root exits 2 before scanning".
- 3 assert_full_scope always :ok: dot-directory subset test and empty-tree test.
- 4 pin comparison removed: below-min pin test and the x.exs directory test.
- 5 regular-file filter removed: the x.exs directory test.
- 6 pin raised by one: "all scopes pin floor" and "is clean".
- 7 expected derived by the same wildcard: dot-directory subset test.
- 8 project/2 emits [] for T01: "project/2 returns exactly the pinned closed key set" fails; the output contains `assert [_ | _] = g["sub_observations"]`.
- 9 negative (8 plus both :289 floors removed): the same test PASSES (12 tests, 0 failures). The floors are the only catch.
- 10 ios_entries filter matches nothing: the device-verified formatter test fails; output contains `assert [_ | _] = ios_entries`.
- 11 negative (10 plus the :416 floor removed): the same test PASSES (20 tests, 0 failures).
- 12 identity_joins/0 returns []: the mismatched-identities test.
- 13 tracked_children catch returns {:ok, []}: "stop_children reports registry_gone" (13 tests, 3 failures).
- 14 stop_all returns the error before closing the listener: "stop_all still closes the origin listener ...".
- 15 stop_children result bound to `_` in the journey: the "discards the stop_children result by design" pin.
- 16 whole b898e110 verify_twin task: host-lock-missing, root-lock-missing and unreadable-lockfile freeze tests (run is not uid 0).
- 17 File.stat pre-filter restored: the host-never-had and root-never-had source-gate tests.
- 18 locks restored to the non-nil list: "observation drops dependency_lock and backend_build unless both lockfiles digest".
- 19 emptiness rule restored, pre-filter removed: host-never-had, root-never-had and "an unreadable lockfile blocks the source gate" (this last test is the one 185-04 rewrote to inject an unreadable digest; it still bites on this control).

No control was rewritten from the plan and none was dropped; the full log with exact test names and counts is `/private/tmp/crosswake-phase180-run/mutation-185.log`.

## D-17 deviation: where the all-zero result comes from

CONTEXT D-17 (amended 2026-10-16 in `185-CONTEXT.md`) says the real-candidate source probe shows all zeros. The all-zero term `{:ok, %{modified: 0, flagged: 0, excludes: 0}}` comes from `TwinProducers.probe_source`, run with the new code on a full HEAD copy before the commit (`real-probe-185.pre.out`) and on the committed candidate after it (`real-probe-185.out`). It does not come from the `twin_preflight` command, whose four-line output has no count field and which stops before its source step when there is no prepared record. The preflight was run read-only on the committed candidate with a never-created record path, identity path and run root. It exited 2 and printed exactly four lines (`preflight-185.out`, exit in `preflight-185.exit`): `result: blocked`, `first cause: prerequisite_missing`, `report: none written; no run root was created or consumed`, and a next-action line. Nothing was raised, nothing was created, HEAD and porcelain are unchanged. Small difference from the plan text: it blocks first because the run root does not exist (the next action says to create a private run root), not specifically for "no prepared record"; both are the same honest answer, since no twin-05 has run.

## Commit contents

15 paths: the 14 required paths plus `script/collection_assertion_ledger.json` (regenerated). Optional `twin_git_fixtures.ex` and `doctor_test.exs` were not changed. No deletions. Pin: 249 = 249, and the checker on the committed tree prints the same numbers. Twin history manifest: 87 OK lines after the commit. No twin-05 directory exists.

## Deviations from Plan

**1. [Process] Ledger drift proof tightened.** The plan's "rows minus display, sorted by key, byte-equal" does not hold literally: four rows carry the cited line in their rationale text and moved with the display line (phase64 :596, verify_twin :269 and :294, receipt :336). I proved instead that the rows are equal once "at line N" is normalised in the rationale, with the header and bucket counts byte-identical; keys, shapes, buckets, enclosing text and expressions are unchanged. The unnormalised comparison is saved as `ledger-rows-{pre,post}-185.json`, the normalised one as `ledger-rowsN-{pre,post}-185.json`. This is display-only in effect but is a stricter-than-plan gap the verifier may want to see.

**2. [Process] `--emit-snapshot` writes to stdout.** The plan assumed it rewrote the ledger; I redirected its output to a RUNS file and copied it into place only after confirming the exit code. The first failing `--check` exit is kept as `ledger-185g.pre.exit`; `ledger-185g.exit` holds the re-check (0).

**3. [Process] Candidate HEAD is detached.** The generic "refuse to commit on a detached HEAD" assertion would block the plan's required commit; the plan and dispatch rules specify committing on b898e110 in the candidate, so I followed them. No branch was created.

No code changes beyond the committed 185-01..185-04 work and the regenerated ledger.

## Notes for the orchestrator

- Deferred items with reopen triggers: a stop failure feeding the run verdict, and registry ownership (reopen on the next twin change that alters the cause list or receipt, or after a run that leaves a process behind); the pin raise at Phase 188; VACG-01; scanner blind spots; `strip_heredocs`; unread SEED-023 sites; the twin_journey residue-scope mismatch.
- D-09's list was extended by twin_receipt :110, gen_shell_origin_mode :99 and :336, and the example-host :47.
- The example-host test file has two pre-existing failures (G2, G6) from the router's `host.study.audio.play`; they were excluded from the full suite by `--exclude requires_example_host` and are unchanged by this commit. 185-03's floor passes.
- Planning-doc commits were skipped (STATE.md and ROADMAP.md left for the orchestrator).
- The unreadable-lockfile tests ran as non-root, so they were part of controls 16 and 19.

## Known Stubs

None.

## Self-Check: PASSED

Commit 25614cf6 is HEAD of the candidate with parent b898e110; porcelain empty; push URL unchanged; all RUNS artifacts exist (fix-185.failures, mutation-185.log with 20 control lines, fix-185.commit, real-probe-185.pre.out, real-probe-185.out, preflight-185.out).
