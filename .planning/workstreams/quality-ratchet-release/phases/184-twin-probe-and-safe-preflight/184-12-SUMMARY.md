---
phase: 184-twin-probe-and-safe-preflight
plan: 12
subsystem: proof-lane twin source probe
tags: [gap-closure, mutation-controls, candidate-commit]
status: complete
commits: 1
plan_head_before: b5399e519ab44f7149480f68311189f1ec02a78d
plan_head_after: e4344ca523a56e146d9e8647ec141b9714e8180f
requirements: [PROBE-01, PROBE-02, PROBE-03, PROBE-04]
actuals:
  tasks: 3
  commits: 1
---

# Phase 184 Plan 12: Gate, mutate and land the third gap closure Summary

The uncommitted 184-11 changes passed every gate, all eighteen mutation controls failed their named tests, a full HEAD copy probed clean, and one candidate commit now sits on b5399e51. Both reproduced layouts (a `:deps`-style folder beside a committed rule, an `info/exclude` line starting with spaces or a tab) now block in the probe and the preflight.

Recovery-checkout commits skipped per checkout rule (planning files are plain uncommitted files; STATE.md and ROADMAP.md left to the orchestrator).

## Candidate commit

- SHA `e4344ca523a56e146d9e8647ec141b9714e8180f`, tree `0ceb03de71263ad24f27384ee18994c30ae0e020`, parent `b5399e519ab44f7149480f68311189f1ec02a78d`.
- Subject: `fix(184-12): judge ignore rules exactly as git does (pathspec-magic folder names, info/exclude lines)`; trailer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Paths (4): `guides/see_it_run.md`, `lib/crosswake/proof_lane/twin_producers.ex`, `test/crosswake/proof_lane/twin_source_probe_test.exs`, `test/mix/tasks/crosswake_proof_lane_twin_preflight_test.exs`. `test/support/twin_git_fixtures.ex` and `script/collection_assertion_ledger.json` did not change, so neither is included.
- Candidate porcelain empty, push URL still `no-push-phase180`, no deletions in the commit. Evidence: `fix-184-11.commit`, `.message`, `.paths`.
- `guides/see_it_run.md` SHA-256 for the STATE guide-reconciliation line: `33597cd71ee28e4fb4cc12913056d115e50caa65dfd525e2e1d2432b807fbf78`.

## Task 1 gates (all passed, no fixes needed)

- Extractor reproduces `feat-184.failures` byte for byte.
- Full suite (`env -u MIX_BUILD_PATH`): `2502 tests, 1 failure (78 excluded)`; failure set is only `phase180_twin_feasibility_test.exs:30` and cmp-equals `baseline-184.failures`.
- Quick suites (8 files): 200 tests, 0 failures. Guides/docs-parity/ledger tests, ledger `--check`, docs sync, `compile --force --warnings-as-errors`, and format all exit 0. Ledger did not need regeneration.
- Adoption scan findings cmp-equal `adoption-scan-head-184.findings` (scan exit 1 is carried debt, not gated).
- No added `assert/refute Enum.all?/any?` line. History manifest verified.

## Task 2 mutation controls

Harness `mutate-184-11.sh` (umask 0022), exit 0, `mutation-184-11.log` has exactly 19 `control ` lines, no HARNESS FAILURE. Control 0 (unmutated): 168 tests, 0 failures.

| # | Mutation | Result |
|---|----------|--------|
| 1 | whole 3786de95 producer (probe tests) | failed in info/exclude:1:z, .gitignore:1:x, quoted-name tests |
| 2 | whole 3786de95 producer (preflight) | failed in info/exclude:1:z preflight (21 tests, 3 failures) |
| 3 | parse cut at first colon plus re-added info/exclude suffix trust (re-targeted; D-38 removed the original clause) | failed in info/exclude:1:z (5 failures) |
| 4 | parse cut at first colon alone | failed in .gitignore:1:x (1 failure) |
| 5 | tracked-.gitignore check by basename only | failed in nested-.gitignore and info/exclude:1:z (9) |
| 6 | added trust clause accepting every non-empty source (re-targeted) | failed in same two tests (12) |
| 7 | empty source trusted | failed in no-deciding-rule test |
| 8 | framing check removed | failed in extra-record test |
| 9 | path binding removed | failed in misaligned-record test (2) |
| 10 | `--directory` restored | failed in collapsed-directory test (9) |
| 11 | stdin file inside the candidate | failed in private-file test (19) |
| 12 | whole b5399e51 producer (probe tests) | failed in :deps, :(top)deps, : holding deps, :!deps, spaces-#, tab, counts-as-a-change (9 failures) |
| 13 | whole b5399e51 producer (preflight) | failed in :deps and spaces preflight tests (21 tests, 2 failures) |
| 14 | `./` removed from payload and binding | failed in :deps, :(top)deps, : holding deps, :!deps (6) |
| 15 | binding also accepts echo without `./` | failed in echo-binding test (1) |
| 16 | trust clause for a `.git/info/exclude` source | failed in counts-as-a-change, spaces-#, tab (3) |
| 17 | `exclude_rules` uses trimming attributes predicate | failed in spaces-# and tab (2) |
| 18 | 0600 chmod removed | failed in input-file test (1) |

Controls 3 and 6 were re-targeted as the plan required; no other control needed strengthening. Candidate files byte-identical afterwards (`candidate-184-11.post-mutation.out` all OK); throwaway copy removed.

## Task 3 probes and evidence

- Pre-commit probe of a full HEAD copy (real .git and every ignored file kept, restored to b5399e51, then removed): `{:ok, %{modified: 0, flagged: 0, excludes: 0}}`.
- Post-commit probe of the real candidate: `{:ok, %{modified: 0, flagged: 0, excludes: 0}}`.
- Gitlink count 0 (`gitlinks-184-11.count`), no `.gitmodules`.
- Post-commit five phase files: 168 tests, 0 failures.
- History manifest: 87 `OK` lines; no twin-05; recovery checkout has nothing staged and stays at d0f3e2f1.
- `184-REVIEW-DISPOSITION.md`: five GAP2 rows now say "closed in 184-11/184-12" with commit `e4344ca5` and control numbers, plus a short closure paragraph (plain uncommitted file).

## Deviations from Plan

None. The plan executed as written; every control bit on the first run.

## Notes for the orchestrator

- WR-05 stays open for Phase 188 TWIN-07.
- The D-36 deferrals carry their reopen triggers.
- The D-38 BOM over-count is accepted.
- The candidate is on a detached HEAD at e4344ca5 (as b5399e51 was); nothing pushed.

## Known Stubs / Threat Flags

None.

## Self-Check: PASSED

- Commit e4344ca5 is HEAD of the candidate and its parent is b5399e51; all evidence files listed above exist; recovery index empty.
