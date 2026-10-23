---
phase: 189-inventory-and-backup
plan: 09
subsystem: infra
tags: [inventory, reconciliation, backup, restore-test, decision-list]
status: complete
requires:
  - phase: 189-02..08
    provides: row files, backups, per-plan manifests, restore registries, PR table
provides:
  - 189-INVENTORY.md (final, 258 rows plus 7 PR dispositions)
  - reconcile-189.sh (exact reconciliation) and verify-189.sh --full
  - complete manifest SHA256SUMS (156 lines) and RESTORE-RESULTS.txt (76 lines)
  - 189-DECISIONS-NEEDED.md (172 unclassified rows in 13 groups)
affects: [189-10, 193]
requirements-completed: [INV-01, INV-02, INV-03]
duration: about 90 minutes (about 55 of them restore reruns)
completed: 2026-10-16
actuals:
  size_chars_over_4: 26000
  tasks: 2
  commits: 0
  commits_note: "commit skipped per checkout rule; nothing was staged or committed in the recovery checkout"
plan_head_before: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
plan_head_after: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
key-files:
  created:
    - 189-DECISIONS-NEEDED.md
    - 189-EVIDENCE/reconcile.txt
    - 189-EVIDENCE/verify-full.out
  modified:
    - 189-INVENTORY.md
---

# Phase 189 Plan 09: Final inventory, reconciliation and full restore rerun Summary

**The final inventory has 258 rows (36 on main, 41 to land, 9 obsolete, 172 unclassified) plus 7 pull request dispositions; it reconciles exactly against its sources, all 73 registered restores plus the 3 candidate bundle restores passed again (76 of 76), and one manifest of 156 lines verifies every backup file.**

## What was checked and what happened

I assembled 189-INVENTORY.md from the six row files and the PR table, then wrote `reconcile-189.sh`. It reads its counts from the sources, not from the table: the before-snapshot, ref counts, the reflog list (2897 ids equal to the independent `log -g` count, 571 reflog-only), env counts, dirty buckets, the candidate check (90 ahead of main, 0 behind), the frozen temp listing (159 entries), the temp repo list and the restore records. It ended `reconcile-189: ok` with 28 checks, all ok, including: all seven per-plan manifests present and non-empty, reflog rows 17 + 0 + 554 = 571, 4 stash rows, 56 branch rows, 56 branches plus 118 ref-group items = 174 refs, 78 non-planning rows, dirty rows summing to the snapshot's 738 (no environment file excluded), 2 worktree rows, 3 environment files, 248 lost-and-found items, 90 candidate commits, 159 of 159 temp entries mapped to existing rows, every non-shallow temp repo's captured refs equal to its source refs, the 5 shallow repos (the candidate included) all archived as git-directory tars with no shallow tip in the commit bundle, 7 PR rows, every obsolete row carrying one of the allowed reasons, and every to-land or unclassified row naming an existing backup and a passing restore. The empty-input guard works: each check requires non-empty numeric sources.

`verify-189.sh --full` (new) ran the quick check, then every restore in the five registries (73), then the three candidate bundle restores, then reconciliation, then the quick check again. Result: 76 pass lines, 0 fail lines, `verify-189 full: ok`. The slow ones (ignored-keep.tar with 46066 files, the 178 toolchain and phase 180 run-folder tars) were run to the end, none skipped. The registry total (73) equals the pass total of restore-02/03/04/05/08 (73).

The manifest `SHA256SUMS` has 156 lines (154 files in the backup folder plus the two existing candidate bundles); `shasum -c` reports 156 of 156 OK, and all 155 lines of SHA256SUMS.02..08 appear verbatim in it. The backup folder is about 8.6 GB. The recovery checkout HEAD is unchanged and nothing is staged.

The decision list (189-DECISIONS-NEEDED.md) covers all 172 unclassified rows in 13 groups, in plain language, with backup names. It says the user decides each before Phase 193 and that nothing was decided or removed in Phase 189. The privacy scan over it, the inventory, reconcile.txt and verify-full.out reported 4 files and 0 hits.

| Class | Rows |
|---|---|
| on main | 36 |
| to land | 41 |
| obsolete | 9 |
| unclassified | 172 |

PR dispositions (INV-03): 238, 210, 211, 239, 240 and 241 are redo after landing; 236 (release PR) is hold. No PR was changed.

## Deviations from Plan

**1. [Rule 1 - Bug] Registry greps are tab-aware.** As in plans 05 and 08, no check here greps the registries with a literal space; the reconcile script reads them by line count and the tab-separated pass column.

**2. [Rule 1 - Bug] The "pending marker" check initially matched branch names.** First draft grepped the whole row for `todo`, which flagged a branch named after a todo item. It now inspects only the Kind/Count/Class/Reason/Backup/Restore cells for a cell that starts with pending, tbd or todo. No evidence or row was edited.

**3. [Rule 3 - Blocking] Task 1 verify was run in two parts.** The plan's one-line verify reruns `verify-189.sh --full` (about 55 minutes). I ran `--full` once, kept its output, and ran every other clause of the verify against the saved output, so the full rerun was not repeated a second time.

**4. Commit skipped per checkout rule.** Nothing was staged or committed; STATE.md, ROADMAP.md and REQUIREMENTS.md untouched.

**5. Task 2 decision-list generation.** The file is generated from the final inventory by a script (kept in the session scratch area, not in the repo) so every unclassified row ID appears exactly as in the inventory.

## Auth gates

None.

## Known Stubs

None.

## Threat Flags

None.

## Notes for plan 10

- Restore scratch is large (`<tmp>/crosswake-phase189-run/restore` and `scratch-0N`, roughly 20+ GB after the full rerun). Plan 10 cleanup may remove it.
- `verify-189.sh --full` is rerunnable but takes about 55 minutes; `--quick` is unchanged. `finish-09.sh` in the run folder rebuilds reconcile.txt, verify-full.out, RESTORE-RESULTS.txt and SHA256SUMS from `full.raw`.
- The late phase-folder tar is to be added by plan 10 as `restore-registry-10.tsv`; a future `--full` will pick it up automatically (it loops over every registry file) but the SHA256SUMS lines/count will change by the files plan 10 adds.
- The inventory row count is 258 item rows; a naive `grep -c '^| [A-Z]'` gives 260 because it also matches the two table header lines.
- Recovery HEAD at the end: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377 (unchanged).

## Self-Check: PASSED

Reconcile ok (28 of 28), verify-189 full ok (76 pass, 0 fail), manifest 156 of 156 OK, decisions file lists 172 of 172 unclassified IDs, scan hits 0, nothing staged.
