---
phase: 189-inventory-and-backup
plan: 08
subsystem: infra
tags: [git, bundle, tar, tmp-clones, backup, restore-test]
status: complete
requires:
  - phase: 189-02
    provides: compare clone and restore tooling
  - phase: 189-06
    provides: tmp-tips, tmp-gitdirs, tmp-unique lists and the temp-folder rows
provides:
  - tmp-commits.bundle (complete history, restores without any temp repo)
  - git-directory tars for the 5 shallow repos, dirty-file tars, folder tars, loose-file tar
  - SHA256SUMS.08 (123 artifacts), restore-08.tsv, rows-06.md with no pending cell
affects: [189-09, 189-10, 193]
requirements-completed: [INV-02]
actuals:
  size_chars_over_4: 22000
  tasks: 2
  commits: 0
  commits_note: "commit skipped per checkout rule; nothing was staged or committed in the recovery checkout"
plan_head_before: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
plan_head_after: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
key-files:
  created:
    - 189-EVIDENCE/restore-08.tsv
  modified:
    - 189-EVIDENCE/rows-06.md
---

# Phase 189 Plan 08: Backup of temp-folder work Summary

**Everything in the temp folder that is unclassified or to land now has a copy in the backup root that restores exactly: one self-contained commit bundle (3 unique commits, 14 tip refs, complete history) plus 59 tars, and all 60 restore tests passed.**

## What was checked and what happened

I built one bundle from the 14 tips of the 15 non-shallow repos inside a scratch mirror of the compare clone (not shallow; no tip belongs to a shallow repo). The bundle has no negative refs, so it records a complete history. Restoring it in an empty scratch clone passed the verify, ref-equality, complete-history and connectivity checks, and all 3 unique commits plan 06 counted as fetched (including 5923a679) are present there (`unique_present 3 of 3`). Its size is about 64 MB.

Then I wrote the file backups from the backup-plan column of the entry list:

| Kind | Count | Notes |
|---|---|---|
| git-directory tars | 5 | all reason shallow: phase179-impl, phase179-source, the candidate checkout (phase180-impl), phase181-impl, phase182-impl; 0 unreadable, 0 zero-ref; about 77 MB total |
| dirty-file tars | 11 | 72 unmatched dirty files across 11 repos |
| folder tars | 42 | includes the 178 toolchain folder (17435 files kept) and the phase180 run folder (46713 files) |
| loose-file tar | 1 | 77 files |
| excluded manifests | 3 | toolchain (2409 npm package files), native-proof repair check (1 Python bytecode file), config-research (27 mix build files); 11.99 MB hashed and listed, not tarred |

Total tar size is about 5.6 GB; the free-space precheck required about 17 GB and 491 GB was available. Every tar restored with exact file count, sha256 and mode, no symlink and no AppleDouble entries. No manifest names an environment file. `.excluded` reasons are exactly the regen_check kinds, and no path is in both a `.files` and its `.excluded`. The candidate's own git-directory tar restored too (`tmp-crosswake-phase180-impl-gitdir.tar`); its row stays C-CAND and it is not cited in rows-06.md.

`SHA256SUMS.08` lists 123 artifacts (every tmp artifact except `tmp-entries-full.tsv`, which stays in SHA256SUMS.06) and all lines verify OK. rows-06.md now has no pending cell; every unclassified or to-land R-TMP row names an existing artifact and restore pass, and R-TMP-COMMITS cites the bundle plus the phase179-impl git-directory tar (the second shallow-only commit lives in the candidate checkout and is covered through C-CAND). verify-189 quick ended `ok`; the scan of rows-06.md and restore-08.tsv reported `files 2` and `hits 0`. The recovery HEAD is unchanged.

## Deviations from Plan

**1. [Rule 1 - Bug] Registry check used a literal space.** The Task 1 verify greps `'^tmp-commits.bundle '` in the restore registry, but the registry is tab-separated, so the literal check counts 0. I ran the equivalent check with the line start and the tab (count 1). Plan 09/10 verifies that grep the registry the same way need the same correction.

**2. [Rule 1 - Bug] Name-collision guard compared stem only.** My first build stopped (name_collision) because a folder's tar and its `.excluded` manifest share a stem. The guard now compares kind plus stem; nothing was written by the failed run. No other effect.

**3. Folder tars hold every kept file, not only the unmatched ones.** Plan 06's reason counts files not found in main, candidate or recovery HEAD, but the tar holds all non-environment, non-regenerable files outside git (a superset), which is simpler to restore and audit.

**4. Empty directories of git directories are in the tars** (listed with no recursion) so a restored git directory keeps its refs and objects folders. The restore test counts files only.

**5. Commit skipped per checkout rule.** Nothing was staged or committed; STATE.md, ROADMAP.md and REQUIREMENTS.md untouched. Nothing under the temp sources was written (plain reads and tar only).

## Auth gates

None.

## Known Stubs

None.

## Threat Flags

None.

## Notes for plans 09-10

- New files in the backup root: `tmp-*` artifacts (123, listed in SHA256SUMS.08), `tmp-commits.bundle` and `.expect`. Registry `RUNS/restore-registry-08.tsv` has 60 lines (tab-separated).
- Restore scratch for plan 08 is under `RUNS/restore` and `RUNS/scratch-08` (about 5.6 GB of extracted tars); plan 10 cleanup may remove it.
- The toolchain, the phase180 run folder and the 178 diagnostic folders are large; the user may judge them obsolete before Phase 193, but they are backed up.

## Self-Check: PASSED

Both verify blocks passed (with the registry grep corrected as noted). 60 of 60 restore tests pass, SHA256SUMS.08 verifies 123 of 123, recovery HEAD unchanged.
