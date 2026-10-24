---
phase: 193-cleanup-and-new-working-rules
plan: 04
subsystem: infra
tags: [removal-gate, final-check, rules-check, self-test, script-freeze]
requires:
  - phase: 193-cleanup-and-new-working-rules
    provides: paths-193.sh, preflight, the post-189 record and backups (01); land gate and privacy check (02); copy-forward, swap and guard (03)
provides:
  - remove-193.sh (plan [--pre-swap], propose, answer allow|hold, apply, ledger, --self-test)
  - final-check-193.sh (--pre-merge PR, --post-merge, --check N, --self-test)
  - rules-check-193.sh (run, --self-test)
  - selftest-193.sh and the 12-line 193-SCRIPTS.sha256
affects: [193-05, 193-08, 193-09, 193-10]
requirements-completed: []
actuals:
  tokens: 90000
  tasks: 3
  commits: 0
plan_head_before: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
plan_head_after: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
status: complete
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/scripts/remove-193.sh
    - .planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/scripts/final-check-193.sh
    - .planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/scripts/rules-check-193.sh
    - .planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/scripts/selftest-193.sh
    - .planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/193-SCRIPTS.sha256
    - .planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/193-EVIDENCE/remove-plan-preswap-193.txt
    - .planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/193-EVIDENCE/final-check-ci-probe-193.txt
    - .planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/193-EVIDENCE/legacy-selftests-193.txt
  modified: []
key-decisions:
  - "Counts come from the records (304 expected ids today: 259 inventory + 45 post-189), never from the plan's 11 / 18."
completed: 2026-10-24
---

# Phase 193 Plan 04: Removal gate, final check, working-rules check

The three checking tools now exist, are tested on throwaway folders, and the removal gate has already looked at every real item without deleting or changing anything. The whole 193 script set (12 scripts) is frozen by hash.

## What was checked

- **Real removal plan, read-only (`plan --pre-swap`).** 15 items were evaluated; 14 pass and 1 is kept. Nothing was deleted, moved or written outside the evidence file.
  - All 11 present `<tmp>` crosswake entries pass: `crosswake-phase179-hex` (R-TMP-038) and the ten post-189 entries (R-POST-TMP-01..10, in the order the record lists them).
  - The accrue-bridge worktree (R-WT-2) passes, including `bridge_commits patch_unique 14 in_refs_all_bundle 14` and its one dirty file covered by the 189 worktree listing, read through the explicit `--git-dir`/`--work-tree` options.
  - The durable candidate clone (R-POST-LOC-02) passes.
  - The recovery folder (R-POST-LOC-03) reports `gates pass pending:d,f`; the information line `pending recovery dirty_uncovered 30` counts the plain files plans 02-04 wrote after plan 01's dirty backup (plan 08's dirty-refresh closes them).
  - The preflight re-verify of the backup root ran inside the plan and passed (`backup_root verify pass`).
  - The counts line reads `now branches 56 stashes 4 worktrees 3 tmp_entries 11` against `189 branches 56 stashes 4 worktrees 3 tmp_entries 159`.
- **Live CI probe.** `final-check-193.sh --check 2 --post-merge` (reading the clean clone through `FINAL193_TOP`) printed `final: check 2 pass` for today's main tip: the single merged PR that produced it, its head, and a successful `Crosswake CI` check run from the app id read from branch protection. The main-push workflows are listed as information only.
- **Self-tests (every control as expected):** remove-193 26 of 26, final-check-193 30 of 30, rules-check-193 19 of 19. The aggregate `selftest-193.sh` runs all ten 193 self-tests: `scripts 10 of 10 pass`, and no `cw193-st.*` folder is left.
- **Freeze.** `193-SCRIPTS.sha256` has 12 lines (paths, preflight, backup-post189, privacy, land-gate, copyforward, swap, guard-swapped, remove, final-check, rules-check, selftest) and `shasum -a 256 -c` passes.
- **Legacy standalone self-tests:** selftest-scan-191 (33 of 33) and selftest-carry-191 (26 of 26), both rc 0; the `crosswake*` names in `/private/tmp` are identical before and after, and no `crosswake-selftest-*` or `crosswake-scan-191.*` entry remains. The 192 privacy self-test was not run (D-13(e)).
- The three task verify commands exited 0 with their exit codes captured directly; nothing was piped into tail or head. No git write happened in the recovery checkout (HEAD `d0f3e2f1` unchanged); no remote write.

## Kept cause from the real pre-swap plan (fix before PR 1 / Gate B)

**R-POST-LOC-01 (integration clone): `kept:ref_tip_unprotected`.** The clone holds six remote-tracking refs whose tips are neither in any backup bundle, nor equal to a live GitHub value, nor on `main`: five Dependabot branches (`checkout`, `download-artifact`, `setup-node`, `upload-artifact`, `setup-beam`) and `release-please--branches--main`. GitHub has since moved those branches, so the clone's copies are stale. Everything else in that clone (the five trial branches, local `main`, `origin/main` and the remaining remote-tracking refs) is covered. Left alone, the clone simply stays and is not deleted. Two ways to close it before Gate B: add a small extra bundle of those six tips to the backup root through plan 01's backup tool (preferred, keeps the gate strict), or decide the stale Dependabot/release-please copies are obsolete and record that as the reason the clone is kept or the ref class is accepted. No tool change is needed either way.

## Deviations from Plan

**1. [Rule 1 - Fact drift] Derived counts.** The plan says 11 post-189 temporary rows and 18 published refs; the record has R-POST-TMP-01..10 and R-POST-PUB-01..20. The expected id set is computed from the records (304 today: 259 inventory rows + 45 post-189 rows) and never hardcoded; the final check computes it with the same rule.

**2. [Rule 1 - Fact drift] The integration bundle lives in the backup root itself**, not in `inventory-189/` (its sums line is `../integration-191-trials.bundle`). The gate looks there first and falls back to the inventory folder.

**3. [Rule 2 - Missing handling] Beyond the plan text:**
- An unmapped `<tmp>/crosswake*` entry becomes an item with no row and is kept `no_row`; a symlink is `symlink_refused`; a path whose real path differs is `path_not_real`.
- `plan` prints the list and also writes it to its evidence file (a caller redirecting stdout to the same file gets identical content).
- Preflight is run with its own output name (`remove-preflight-193.txt`) so it never overwrites `preflight-193.txt`.
- Final-check check 3 in post-merge mode allows a table row for the merged PR that produced the main tip (so PR 2's own row does not fail the comparison); any other row for a closed PR fails. Pre-merge mode allows the PR under test as the one extra open number.
- Final-check check 1 runs `git fetch origin main` inside the checkout under test (only the new main checkout; it refuses the recovery branch with exit 2). `FINAL193_TOP` is refused for checks other than 2 and 3.
- rules-check forbids, in STATE's active sections, the phrases `frozen recovery checkout`, `in this recovery checkout`, `stays frozen` and the /private/tmp candidate forms; history lines are never read. Gate words checked: allow, hold, one-use, displayed.

**4. [Rule 1 - Bug, mine] Two early self-test fixtures failed** because the swapped fixture had no copy-forward evidence file, so the `copy_forward pending` line tripped my "no pending" assertion. The fixture now writes that file.

**5. TDD note.** The checkout rule forbids a RED commit. The self-tests were written with the scripts; the fail-closed controls (one per refusal) and the first-run fixture failures above are the RED evidence. Mutation proof was not repeated for these scripts.

**6. Environment note.** The safety check once denied a diagnostic `bash -c` containing a cleanup `rm`; I re-ran it without the cleanup. The leftover scratch folder is under the session scratchpad, not the project.

## Known Stubs

None.

## Threat Flags

None. All outputs use placeholders and fixed labels; no home path appears in any evidence file (checked).

## Self-Check: PASSED

The four scripts, the sums file and the seven evidence files exist; `shasum -a 256 -c 193-SCRIPTS.sha256` passes (12 lines); the three task verify commands returned 0; the recovery HEAD is unchanged (`d0f3e2f1`). No commits were made (D-03). STATE.md and ROADMAP.md were not touched.
