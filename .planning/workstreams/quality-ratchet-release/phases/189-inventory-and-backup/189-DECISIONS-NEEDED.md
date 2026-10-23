# Phase 189 Decisions Needed

## What was checked and what is backed up

Phase 189 inventoried everything the frozen recovery checkout, its extra worktrees and the temporary clone folders hold, and copied what matters to the backup root outside the temporary area. Every backup was restored again in a fresh scratch folder and compared with what was expected: file counts, content hashes and modes for archives, and ref lists and complete history for commit bundles. The inventory (189-INVENTORY.md) has 259 rows: 36 are already on main, 41 will land with the candidate, 9 are judged obsolete by a stated and checked reason, and 173 are unclassified. The 173 unclassified rows are the subject of this note.

"Unclassified" means the content is safely backed up, but a tool could not prove it is already on main, will land with the candidate, or is junk. Only you can say whether it is worth keeping.

## How to answer

You decide each item (keep, land or remove) before Phase 193 removes anything. For each group below you can answer for the whole group or name individual row IDs. Keep means it stays in the backup root and nothing is removed from its source. Land means it should be carried into main by a later phase. Remove means Phase 193 may delete the source once the backup is confirmed. Nothing was decided or removed in Phase 189. No git write was made in the recovery checkout or any temporary clone.

Per-item detail (what the item is, where it lives, the reason it is unclassified) is in the table in 189-INVENTORY.md under the same row ID.

## Always removable in Phase 193 (listed so nothing surprises you)

The folder of dangling objects that Phase 189 itself created with a read-only integrity check (row R-LOST-FOUND, 248 items) is regenerable and is to be removed in Phase 193. It is classified obsolete, not unclassified, and needs no decision from you unless you want to keep it.

## Git history

### 1. Commits that exist only in reflogs

**What these are:** Commits you once made or checked out that no branch, tag or stash points to any more. They are reachable only through the recovery checkout's reflog history.

**Why they are unclassified:** They are not contained in main or the candidate, and nobody has said whether any of them is wanted.

**Choices:** keep, land or remove, for the whole group or per row.

**Rows (1 rows, 554 items):** R-REFLOG-OTHER

**Backup:** refs-all.bundle

The backup is the set of refs refs/reflog-backup/* inside refs-all.bundle, which restores with complete history.

### 2. Branches with commits that are not on main

**What these are:** Local branches whose commits are not in main and are not patch-equivalent to main changes.

**Why they are unclassified:** The tools found commits that main does not have, and the changed paths do not all match main, so they could be real unmerged work.

**Choices:** keep, land or remove, for the whole group or per row.

**Rows (27 rows, 27 items):** R-BR-001, R-BR-002, R-BR-003, R-BR-004, R-BR-005, R-BR-006, R-BR-007, R-BR-008, R-BR-009, R-BR-010, R-BR-012, R-BR-013, R-BR-015, R-BR-016, R-BR-020, R-BR-023, R-BR-028, R-BR-034, R-BR-040, R-BR-041, R-BR-042, R-BR-044, R-BR-046, R-BR-047, R-BR-049, R-BR-050, R-BR-056

**Backup:** refs-all.bundle

### 3. Reference groups not fully contained in main

**What these are:** Remote-tracking references, tags, the temporary reference and the stash reference.

**Why they are unclassified:** Not every target of these groups is an ancestor of main, so the group as a whole cannot be called redundant.

**Choices:** keep, land or remove, for the whole group or per row.

**Rows (4 rows, 117 items):** R-REFS-REMOTES, R-REFS-TAGS, R-REFS-TMP, R-REFS-STASH

**Backup:** refs-all.bundle

### 4. Stashes

**What these are:** The four saved stashes of the recovery checkout, each with its tracked changes as a patch and its untracked files as a tar.

**Why they are unclassified:** Some of their paths differ from both main and the candidate, so they might hold unsaved work.

**Choices:** keep, land or remove, for the whole group or per row.

**Rows (4 rows, 4 items):** R-STASH-0, R-STASH-1, R-STASH-2, R-STASH-3

**Backup:** refs-all.bundle, stash-0.patch, stash-0-untracked.tar, stash-1.patch, stash-1-untracked.tar, stash-2.patch, stash-2-untracked.tar, stash-3.patch, stash-3-untracked.tar

## Files in the recovery checkout

### 5. Recovery-only code, script and other non-planning files

**What these are:** Files outside .planning that are changed or new in the recovery checkout, with 29 differing from main and the candidate and 45 absent from both.

**Why they are unclassified:** Their content is not in main or the candidate, so they are either work to land or leftovers, and only you know which.

**Choices:** keep, land or remove, for the whole group or per row.

**Rows (74 rows, 74 items):** R-NP-001, R-NP-002, R-NP-003, R-NP-004, R-NP-005, R-NP-006, R-NP-007, R-NP-008, R-NP-009, R-NP-010, R-NP-011, R-NP-013, R-NP-014, R-NP-015, R-NP-016, R-NP-017, R-NP-018, R-NP-019, R-NP-020, R-NP-021, R-NP-023, R-NP-024, R-NP-025, R-NP-026, R-NP-027, R-NP-028, R-NP-029, R-NP-030, R-NP-031, R-NP-032, R-NP-033, R-NP-034, R-NP-035, R-NP-036, R-NP-037, R-NP-038, R-NP-039, R-NP-040, R-NP-041, R-NP-042, R-NP-043, R-NP-044, R-NP-045, R-NP-046, R-NP-048, R-NP-049, R-NP-050, R-NP-051, R-NP-052, R-NP-053, R-NP-054, R-NP-055, R-NP-056, R-NP-057, R-NP-058, R-NP-059, R-NP-060, R-NP-061, R-NP-062, R-NP-063, R-NP-064, R-NP-065, R-NP-066, R-NP-067, R-NP-068, R-NP-069, R-NP-070, R-NP-071, R-NP-072, R-NP-074, R-NP-075, R-NP-076, R-NP-077, R-NP-078

**Backup:** uncommitted-recovery.tar, uncommitted-recovery-diff-HEAD.patch

### 6. Planning paths outside the planned carry set

**What these are:** Top-level planning files and folders (debug notes, forensics reports, quick tasks, planning scratch, audit files) that exist only in the recovery checkout.

**Why they are unclassified:** They are not part of the set that the later planning-records carry will land, and they are absent from main.

**Choices:** keep, land or remove, for the whole group or per row.

**Rows (9 rows, 15 items):** R-PL-04, R-PL-06, R-PL-07, R-PL-08, R-PL-09, R-PL-13, R-PL-14, R-PL-15, R-PL-16

**Backup:** uncommitted-recovery.tar

### 7. Files in the two extra worktrees

**What these are:** Dirty files in the extra worktree on the agent-p78 branch and the one for the accrue host command bridge branch. Their branches also have commits that main lacks (see the branch rows in group 2).

**Why they are unclassified:** The worktrees were left with uncommitted changes and unique commits; removing either worktree would lose them unless you decide they are unneeded.

**Choices:** keep, land or remove, for the whole group or per row.

**Rows (2 rows, 11 items):** R-WT-1, R-WT-2

**Backup:** worktree-agent-p78.tar, worktree-agent-p78.patch, worktree-accrue-bridge.tar, worktree-accrue-bridge.patch

### 8. Ignored files that are not regenerable

**What these are:** Files that git ignores but that no tool could prove are rebuilt automatically, for example local editor and agent settings, worker logs, a prompts note, doc, xcuserdata, project.xcworkspace and .expert folders, and test output. Folders with a clear regenerable marker (build output, dependencies, bytecode caches) are listed as obsolete instead.

**Why they are unclassified:** They carry no regenerable marker, so they cannot be dismissed as junk.

**Choices:** keep, land or remove, for the whole group or per row.

**Rows (1 rows, 46066 items):** R-IGN-KEEP

**Backup:** ignored-keep.tar

**Added by the plan 13 review check:** a stricter look at the folders called regenerable found 42 text, source or config files inside Gradle build output, now kept in review-content-13.tar (restore tested), for you to keep or remove before Phase 193.

### 9. Local environment files

**What these are:** Local environment files found in the recovery checkout, its worktrees and the temporary folders. Only the count (3) is recorded; names and contents are not.

**Why they are unclassified:** They hold local settings that may include credentials, so they were archived in a restricted file (mode 0600) and never inspected or listed.

**Choices:** keep, land or remove, for the whole group or per row.

**Rows (1 rows, 3 items):** R-ENV

**Backup:** env-local.tar

Keep or remove is the only sensible answer for these; they are never landed.

## Temporary folders (the temp area outside the project)

### 10. Temporary clones with unique refs, stash entries, dirty files or shallow history

**What these are:** Repository clones in the temporary area. Some hold commits no other copy has, some are shallow (their older history is missing, so their git directory was archived whole), some have uncommitted files.

**Why they are unclassified:** Commits or files in them were not found in main, the candidate or the recovery checkout, or could not be compared because history below a shallow boundary is absent.

**Choices:** keep, land or remove, for the whole group or per row.

**Rows (14 rows, 14 items):** R-TMP-004 (tmp-crosswake-177-source-crosswake-dirty.tar + tmp-crosswake-177-source.tar); R-TMP-005 (tmp-commits.bundle + tmp-crosswake-178-diagnostic-clone-dirty.tar); R-TMP-007 (tmp-commits.bundle + tmp-crosswake-178-gates-1bv08549-repo-dirty.tar + tmp-crosswake-178-gates-1bv08549.tar); R-TMP-008 (tmp-commits.bundle + tmp-crosswake-178-gates-2g3dntty-repo-dirty.tar + tmp-crosswake-178-gates-2g3dntty.tar); R-TMP-009 (tmp-commits.bundle + tmp-crosswake-178-gates-2ri1v9ly-repo-dirty.tar + tmp-crosswake-178-gates-2ri1v9ly.tar); R-TMP-010 (tmp-commits.bundle + tmp-crosswake-178-gates-dqd__he2-repo-dirty.tar + tmp-crosswake-178-gates-dqd__he2.tar); R-TMP-011 (tmp-commits.bundle + tmp-crosswake-178-gates-i7t3kjwr-repo-dirty.tar + tmp-crosswake-178-gates-i7t3kjwr.tar); R-TMP-012 (tmp-commits.bundle + tmp-crosswake-178-gates-ky_7v1o0-repo-dirty.tar + tmp-crosswake-178-gates-ky_7v1o0.tar); R-TMP-013 (tmp-commits.bundle + tmp-crosswake-178-handoff.WKuxnb-repair-clone.y0IsfY-dirty.tar + tmp-crosswake-178-handoff.WKuxnb.tar); R-TMP-014 (tmp-commits.bundle); R-TMP-015 (tmp-commits.bundle); R-TMP-016 (tmp-commits.bundle + tmp-crosswake-178-index-diagnosis.tar); R-TMP-018 (tmp-commits.bundle + tmp-crosswake-178-regression-epoch-dpeq5cqv-crosswake-dirty.tar); R-TMP-039 (tmp-crosswake-phase179-impl-gitdir.tar + tmp-crosswake-phase179-impl-dirty.tar)

The commit-level backup is tmp-commits.bundle; shallow clones are covered by their git-directory tars named in the rows.

### 11. Temporary folders holding files that are not in git

**What these are:** Folders in the temporary area (diagnostic runs, fixtures, evidence, handoffs, the toolchain, a run folder) with files not found in main, the candidate or the recovery checkout.

**Why they are unclassified:** Their files are not anywhere else, so they might be evidence you want, or might be disposable run output.

**Choices:** keep, land or remove, for the whole group or per row.

**Rows (33 rows, 33 items):** R-TMP-001 (tmp-crosswake-phase179-packaged-checker.tar); R-TMP-002 (tmp-crosswake-177-handoff.EmloDU.tar); R-TMP-003 (tmp-crosswake-177-hex-home.tar); R-TMP-006 (tmp-crosswake-178-diagnostic-tmp.tar); R-TMP-017 (tmp-crosswake-178-prior-fixtures-x55g58_9.tar); R-TMP-019 (tmp-crosswake-178-toolchain.tar + tmp-crosswake-178-toolchain.excluded); R-TMP-020 (tmp-crosswake-phase175-android-lint-repair.tar); R-TMP-021 (tmp-crosswake-phase175-chimeway011-shallow-proof.tar); R-TMP-022 (tmp-crosswake-phase175-companion-ci-binding-source.tar); R-TMP-023 (tmp-crosswake-phase175-companion-history-repair.tar); R-TMP-024 (tmp-crosswake-phase175-companion115-e2e-failure.tar); R-TMP-025 (tmp-crosswake-phase175-core0211-evidence.tar); R-TMP-026 (tmp-crosswake-phase175-exact-proof-hex.tar); R-TMP-027 (tmp-crosswake-phase175-native-proof-repair-check.tar + tmp-crosswake-phase175-native-proof-repair-check.excluded); R-TMP-028 (tmp-crosswake-phase175-policy-repair-check.tar); R-TMP-029 (tmp-crosswake-phase175-pr227-ci-artifact.tar); R-TMP-030 (tmp-crosswake-phase175-pr227-ci-artifact-v2.tar); R-TMP-031 (tmp-crosswake-phase175-pr228-public-check.tar); R-TMP-032 (tmp-crosswake-phase175-pr228-public-object-view.git.tar); R-TMP-033 (tmp-crosswake-phase175-pr228-v2-evidence.tar); R-TMP-034 (tmp-crosswake-phase175-public-android-host.tar); R-TMP-035 (tmp-crosswake-phase175-public-core-029-unpack-diagnostic-2.tar); R-TMP-036 (tmp-crosswake-phase175-public-ios-host.tar); R-TMP-037 (tmp-crosswake-phase175-published-companion-baselines.tar); R-TMP-038 (tmp-crosswake-phase179-hex.tar); R-TMP-040 (tmp-crosswake-phase179-safe-results.tar); R-TMP-042 (tmp-crosswake-phase180-run.tar); R-TMP-045 (tmp-crosswake-phase182-move-backup-20261015T003402Z.tar); R-TMP-046 (tmp-crosswake-v24-closeout-preview-i97sabw3.tar); R-TMP-047 (tmp-crosswake-v25-config-research-b288pm1d.tar + tmp-crosswake-v25-config-research-b288pm1d.excluded); R-TMP-048 (tmp-crosswake-v25-init-preview-aiacv2pl.tar); R-TMP-049 (tmp-crosswake-v25-start-l5co_6wk.tar); R-TMP-050 (tmp-crosswake176-compare.EhRPvM.tar)

Two of these are large (the toolchain folder and the phase 180 run folder); the user may judge them obsolete.

**Added by the plan 13 review check:** the folder tars did not keep symbolic links, so 244 links that are not build or dependency links are now listed in tmp-symlinks-13.tsv (restore tested), and three empty bare repositories left by a test inside the phase 180, 181 and 182 candidate clones are kept in review-repos-13.tar (restore tested); both are for you to keep or remove before Phase 193.

### 12. Loose files in the temporary area

**What these are:** Individual files directly in the temporary area whose content is not in main, the candidate or the recovery checkout (77 files).

**Why they are unclassified:** No other copy of their content was found.

**Choices:** keep, land or remove, for the whole group or per row.

**Rows (1 rows, 77 items):** R-TMP-LOOSE-KEEP (tmp-loose-files.tar)

### 13. Unique commits found in temporary clones

**What these are:** The distinct commits found across the temporary clones that no main, candidate or recovery ref contains (5 commits). Three are in the commit bundle; two exist only in shallow clones and are covered by those clones' git-directory tars. Three more such commits are in the broken clone in group 14 (R-TMP-051).

**Why they are unclassified:** They are unmerged work with no branch in the recovery checkout.

**Choices:** keep, land or remove, for the whole group or per row.

**Rows (1 rows, 5 items):** R-TMP-COMMITS (tmp-commits.bundle + tmp-crosswake-phase179-impl-gitdir.tar)

### 14. A broken temporary clone holding commits found nowhere else

**What these are:** A temporary-folder clone with no HEAD. The macOS temp cleaner removed its old files on 2026-10-16 and left a 63 MB git object store behind. The git directory is saved in a tar in the backup root, and a fresh restore of that tar passed.

**Why they are unclassified:** Three of its commits are not reachable from main, the candidate or any recovery ref. They look like public companion-repository commits (a dependency bump of erlef/setup-beam, one of actions/checkout and a crosswake_chimeway 0.1.1 release), but that was not checked.

- 3bbce495, 2026-09-27, chore(deps): bump erlef/setup-beam from 1.24.0 to 1.24.1
- e585e053, 2026-09-27, chore(deps): bump actions/checkout from 7.0.0 to 7.0.1
- deb52df4, 2026-09-28, chore(main): release crosswake_chimeway 0.1.1

**Choices:** keep, land or remove.

**Rows (1 rows, 1 items):** R-TMP-051 (tmp-phase175-exact-public-candidate-source-cr01.tar)

## Summary of choices

| Group | Rows | Items |
|---|---|---|
| 1. Reflog-only commits | 1 | 554 |
| 2. Branches | 27 | 27 |
| 3. Reference groups | 4 | 117 |
| 4. Stashes | 4 | 4 |
| 5. Non-planning files | 74 | 74 |
| 6. Planning paths outside the carry set | 9 | 15 |
| 7. Worktree files | 2 | 11 |
| 8. Ignored files | 1 | 46066 |
| 9. Environment files | 1 | 3 |
| 10. Temporary clones | 14 | 14 |
| 11. Temporary folders | 33 | 33 |
| 12. Loose temporary files | 1 | 77 |
| 13. Unique temporary commits | 1 | 5 |
| 14. Broken temporary clone | 1 | 1 |

Total unclassified rows: 173. Every one is listed above by row ID.

This is a handoff note, not a checkpoint: nothing is waiting on a reply to continue Phase 189. Answers are needed before Phase 193 removes anything, and to be clear, nothing was decided or removed in Phase 189.
