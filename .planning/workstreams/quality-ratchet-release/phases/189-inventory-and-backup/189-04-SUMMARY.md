---
phase: 189-inventory-and-backup
plan: 04
subsystem: infra
tags: [git, dirty-paths, backup, tar, restore-check, worktrees, inventory]
status: complete
requires:
  - phase: 189-02
    provides: refs-all.bundle, compare clone, SHA256SUMS.02
provides:
  - content class for all 738 uncommitted paths of the recovery checkout (dirty-paths.tsv, dirty-buckets.txt, rows-04.md)
  - tar and diff HEAD patch backups of the uncommitted work and of both extra worktrees, each restored exactly
  - SHA256SUMS.04 over 13 backup files
affects: [189-09, 189-10, 191, 193]
requirements-completed: [INV-01, INV-02]
actuals:
  size_chars_over_4: 80000
  tasks: 2
  commits: 0
  commits_note: "commit skipped per checkout rule; nothing was staged or committed in the recovery checkout"
plan_head_before: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
plan_head_after: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
key-files:
  created:
    - 189-EVIDENCE/dirty-paths.tsv
    - 189-EVIDENCE/dirty-buckets.txt
    - 189-EVIDENCE/rows-04.md
    - 189-EVIDENCE/restore-04.tsv
---

# Phase 189 Plan 04: Uncommitted work classification and backup Summary

**All 738 uncommitted paths of the recovery checkout were sorted by file content against fresh main and the candidate, then backed up twice (tar plus diff HEAD patch) together with both extra worktrees; all six restore tests passed and the frozen state is unchanged.**

## What was checked and what happened

- The live list of uncommitted paths (every file listed individually, the phase-189 folder and GSD's heartbeat lock file left out) held 738 entries, equal to the before-snapshot's expanded count. The same set seen in default mode is the collapsed count of 121. CONTEXT's 73 non-planning and about 47 planning figures were counted on that collapsed basis, where an untracked folder is one line; listing every file gives 78 non-planning and 660 planning paths. It is the same set counted two ways.
- Every working file was hashed without writing anything and compared with its copy at fresh main (d0dbdf7b), at the candidate (a53fbef7) and, for edited tracked files, at the recovery HEAD.
- Nothing was written to the recovery checkout or either worktree. verify-189 --quick --plan 04 printed `verify-189 quick: ok` after each task.

## Bucket counts (expanded basis)

| Measure | Count |
|---|---|
| total | 738 (58 modified, 680 untracked) |
| env_excluded (untracked environment files, owned by plan 05) | 0 |
| env_tracked_dirty (tracked and edited environment files) | 0 |
| non-planning | 78 (45 modified, 33 untracked) |
| planning | 660 (13 modified, 647 untracked) |
| non-planning identical to both main and candidate | 4 |
| non-planning differing from both | 29 |
| non-planning absent from both | 45 |

Classes: on main 4, to land 645, obsolete 0, unclassified 89. The 4 on-main files are the non-planning files identical to main; no file was empty or superseded by a candidate path, so no obsolete row exists.

- Unclassified non-planning files: 74 (29 differ from main and candidate, 45 absent from both). Nothing in them is judged; they are backed up and the user decides before Phase 193.
- Unclassified planning paths: 15, all outside the Phase 191 carry set (the debug notes, forensics reports, the quick-task folder, the planning scratch folder, and top-level files such as the agent history, estimation calibration and the v25.0 and v26.0 milestone audit files). The debug note whose name contains a flagged word appears only in sanitised form with its 12-hex suffix.
- To-land planning groups (645 paths): the workstream phase folders 176 through 188, workstream history (56), milestones (28), the v24.0-audit and v25.0-start folders, every top-level workstream file (including the handoff files STATE, ROADMAP, REQUIREMENTS, state.json, .continue-here and MILESTONES, captured at tar time), research v25 (20) and v26 (7), seeds (2 edited), and the four edited top-level planning files (PROJECT, RETROSPECTIVE, WINDOWS, config.json). Reason on every row: planning record only in the recovery checkout; lands through the Phase 191 planning-records carry.
- rows-04.md holds 78 R-NP rows, 46 R-PL group rows (Count sum 738), plus R-WT-1 and R-WT-2.

## Backups (all in the backup root under inventory-189, mode 0600, sha256 in SHA256SUMS.04)

| File | Bytes | sha256 (first 16) |
|---|---|---|
| uncommitted-recovery.tar (738 files) | 14015488 | e0b60378eb9cbb54 |
| uncommitted-recovery.files | - | 46308688d54232a0 |
| uncommitted-recovery-diff-HEAD.patch (58 paths) | 1290545 | 94f8c87aa22f5463 |
| uncommitted-recovery-diff-HEAD.expect | - | f2662c9da259a913 |
| worktree-agent-p78.tar (10 files) | 529920 | 97a7354990115540 |
| worktree-agent-p78.patch (10 paths) | 346964 | bbd3a3aa25b2e9c0 |
| worktree-accrue-bridge.tar (1 file) | 2560 | 2faf3b7e416da8e2 |
| worktree-accrue-bridge.patch (1 path) | 542 | f2b423dffd17e3e6 |
| dirty-paths-full.tsv (real paths, local only) | - | b23b942fd8b287d0 |

The .files and .expect files of the two worktrees, and the full 64-character hashes, are in SHA256SUMS.04 (13 lines, 13 OK).

## Restore tests (restore-04.tsv, all under the scratch restore folder, none inside any checkout)

- uncommitted-recovery.tar: pass (738 files equal the tar-time sha256 and mode; no AppleDouble entries, no symlinks)
- uncommitted-recovery-diff-HEAD.patch: pass (58 paths on base d0f3e2f1 from refs-all.bundle)
- worktree-agent-p78.tar and .patch: pass (10 files / 10 paths, base 0c050084)
- worktree-accrue-bridge.tar and .patch: pass (1 file / 1 path, base 789175f2)

Free-space precheck passed (about 1.1 GB needed, about 476 GB free). The capture hashes of all listed files were recomputed after the tar and matched, so nothing changed during capture. The privacy scan over the four evidence files printed `scan: hits 0` (4 files).

## Deviations from Plan

None - plan executed as written. The unsanitised-path file is kept only in the backup root.

## Decisions Made

- Groups in the planning rows are split by class, so a folder never mixes classes.
- Commit steps skipped per checkout rule (the recovery checkout is frozen).

## Known Stubs

None.

## Notes for later plans

- R-WT-1 and R-WT-2 carry Count 10 and 1 (worktree dirty files); they are not part of the 738 recovery-checkout total, so plan 09's reconciliation should sum R-NP and R-PL only for that total.
- The restore folder for the 738-file tar holds an extracted copy of the uncommitted work under the private run folder; plan 10 may wish to delete it after the final check.
- Handoff files edited later by plan 09 will differ from the tar; that is expected and checked against the tar-time manifest only.

## Self-Check: PASSED

Both task verify commands exited 0, SHA256SUMS.04 verifies 13 of 13, and verify-189 quick printed ok.
