---
phase: 189-inventory-and-backup
plan: 11
subsystem: infra
tags: [gap-closure, cr01, inventory-correction, restore-test, checksum-fold, recheck]
status: complete
requires:
  - phase: 189-10
    provides: phase-folder backup, 158-line SHA256SUMS, handoffs
provides:
  - inventory row R-TMP-051 (unclassified) with restore-tested cr01 tar
  - decision group 14 naming the 3 commits
  - SHA256SUMS.11 and a regenerated 160-line combined SHA256SUMS
  - tmp-recheck-11.txt (32 folder lines, no other empty or stub folder holds content)
affects: [12, 193]
requirements-completed: [INV-01, INV-02]
duration: about 25 minutes
completed: 2026-10-18
actuals:
  size_chars_over_4: 20000
  tasks: 3
  commits: 0
  commits_note: "commit skipped per checkout rule; nothing was staged or committed in the recovery checkout"
plan_head_before: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
plan_head_after: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
key-files:
  created:
    - 189-EVIDENCE/restore-11.tsv
    - 189-EVIDENCE/cr01-commits-11.tsv
    - 189-EVIDENCE/reconcile-11.txt
    - 189-EVIDENCE/tmp-recheck-11.txt
  modified:
    - 189-EVIDENCE/tmp-entries.tsv
    - 189-EVIDENCE/tmp-entry-map.tsv
    - 189-INVENTORY.md
    - 189-DECISIONS-NEEDED.md
    - 189-REVIEW-DISPOSITION.md
---

# Phase 189 Plan 11: Correct the CR-01 item, recheck empty and stub temp folders, fold checksums Summary

**The broken temp clone that the inventory called "nothing to keep" is now recorded as unclassified (R-TMP-051) with its restore-tested backup, its 3 commits are on the decision list, and a recheck of every other empty or stub temp folder found no regular file and no git object store.**

## What was checked and what happened

- Fresh restore: the cr01 tar was extracted into a new scratch folder. The 96 restored entries equal the backup's file list exactly, no AppleDouble entries exist, and because the source folder still exists, all 96 entries were compared byte for byte (symlinks by target) with 0 mismatches. The 3 commits (3bbce495, e585e053, deb52df4) resolve as full 40-character commit ids in the restored copy. `restore-11.tsv` holds one pass line; `cr01-commits-11.tsv` holds the three commit lines.
- Manifest: `SHA256SUMS.11` was made with the manifest script, verifies 2 of 2, and its lines equal `SHA256SUMS.cr01`.
- Correction: one row was changed in `tmp-entries.tsv` and one line in `tmp-entry-map.tsv` (each diff showed exactly one changed line; both files stay mode 0600). The entry now has class unclassified, row R-TMP-051, backup cr01-tar, size 64512 KB. The entry file keeps 159 rows and the map 159 lines. The inventory gained row R-TMP-051 and the R-TMP-EMPTY count went from 30 to 29: 259 rows (36 on main, 41 to land, 9 obsolete, 173 unclassified). `reconcile-189.sh` printed `reconcile-189: ok` (saved in `reconcile-11.txt`).
- Recheck (`tmp-recheck-11.txt`): 32 folder lines (the 29 empty rows plus R-TMP-021, R-TMP-050 and R-TMP-051; 9 carry broken stubs), 2 note lines and 1 file line. Of the 29 empty rows, 28 are present with 0 regular files (4 hold only build links) and 1 was removed by the temp cleaner with recorded size 0. Summary counts: 0 regular files, 0 git-directory files, 0 recorded size above 0 and 0 unexplained links in the empty rows; 1 stub row has git-directory files (R-TMP-051, 90 files, all 90 in the backup list) and 0 stub rows are unbacked. The superseded loose file is already gone (temp cleaner); its class rests on a content match, as recorded. The plan was not blocked.
- Decision list: group 14 names R-TMP-051, its tar and the 3 commits (short id, date, subject); the header reads 259 rows and 173 unclassified; the total line reads 173; 173 of 173 unclassified inventory ids appear in the list.
- Combined manifest: the `RESTORE-RESULTS.txt` append went in first, then `SHA256SUMS` was regenerated: 160 lines (158 files plus the two candidate bundles), all OK, it lists the cr01 tar, and every line of `SHA256SUMS.02` to `.08`, `.11` and `.cr01` appears in it verbatim.
- Review disposition: CR-01 is now `fixed`; WR-13 and WR-14 stay open with notes; 22 finding rows remain.
- Privacy scan on the 9 changed files: `scan: files 9`, `scan: hits 0`.
- Nothing was staged, committed or deleted in the recovery checkout; HEAD is still `d0f3e2f1`. Commit skipped per checkout rule.

## Deviations from Plan

1. **[Rule 3 - Blocking] Helper adapted in scratch.** The `.files` list holds paths that already start with the folder name, so the first helper run compared the wrong source paths (96 false mismatches). I fixed the path in the helper and reran into a fresh scratch folder. Two earlier restore scratch folders from the failed runs remain in the run folder, untouched (nothing is deleted in Phase 189; Phase 193 owns removal).
2. **[Rule 3 - Blocking] `refs` folder added in the restored scratch copy.** The tar holds only `.git/objects`, so git refused to treat the restored copy as a repository even with a HEAD file. In the restored scratch copy only, the helper also creates an empty `refs/heads` folder next to the plan's `HEAD` line. The source folder and the tar were not touched.
3. **Recheck helper fixes.** The first recheck run looked for the cr01 list under the wrong name (the list drops the `crosswake-` prefix), which left the backup count blank for R-TMP-051; I fixed the name and reran, so the saved file is from the corrected run.
4. R-TMP-021 and R-TMP-050 still hold 56 regular files outside git today against 1200 and 1220 recorded (the temp cleaner removed the rest); their folder tars already hold the recorded content, and their stub git directories have 0 files. Recorded in the note lines.

## Known Stubs

None.

## For plan 12

- `phase-189-folder.tar` from plan 10 was made before this plan and does not contain the corrected evidence, inventory, decision list, disposition or new evidence files. It should be remade and restore-tested if the phase folder is to be backed up in its final state (the combined `SHA256SUMS` would then change again).
- The inventory now has 259 rows; verify-189.sh expectations that hard-code 258 rows, 172 unclassified, or a 158-line `SHA256SUMS` need the new numbers (259, 173, 160 derived).
- `RESTORE-RESULTS.txt` now has the cr01 line appended (restore tab-separated).
- `verify-189.sh --full` was not run in this plan.

## Self-Check: PASSED

Task 1, Task 2 and Task 3 automated verify commands all returned success; the 9-file privacy scan reported 0 hits; HEAD unchanged and index empty.
