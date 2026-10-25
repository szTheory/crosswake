# Phase 189 Decisions — Answers

**Date:** 2026-10-19
**How decided:** The user asked for Claude's recommendation and said "let's follow that". These answers resolve every unclassified row in 189-DECISIONS-NEEDED.md and are input to Phase 193 (CLEAN-01..04).

## Governing rule

**The backup is the keep.** Every unclassified row already has a backup outside `/private/tmp` that passed a fresh restore test. So "remove" below means Phase 193 removes the *source* copy (in the recovery checkout, its worktrees or the temp area) once it re-confirms the backup's manifest. **The backup root itself is not deleted in v27.0.** It is reviewed at the v28 milestone boundary at the earliest. The privacy rules stay in force: no restored item is searched to reidentify the adopter.

Nothing in the recovery checkout lands as code. Main holds the released, CI-checked versions (191 D-05).

## Answers by group

| Group | Rows | Answer | Reason |
|---|---|---|---|
| 1. Reflog-only commits | R-REFLOG-OTHER | Remove source | Preserved as `refs/reflog-backup/*` in refs-all.bundle; the reflog goes away when the checkout is retired. |
| 2. Branches | all 27 R-BR rows | Remove source (local branches only) | Full history is in refs-all.bundle. **Exception:** the planning half of R-BR-047 lands through the Phase 191 carry (191 D-04); its code half is removed like the rest. Remote branches and open PRs are untouched; they follow their PR dispositions. |
| 3. Reference groups | R-REFS-REMOTES, -TAGS, -TMP, -STASH | Remove source | In refs-all.bundle. The new `main` checkout fetches remote refs and published tags fresh. |
| 4. Stashes | R-STASH-0..3 | Remove source | Patches, untracked tars and stash commits are all backed up. |
| 5. Non-planning files | all 74 R-NP rows | Remove source | Older drafts of code that main already has in released form (191 D-05). **Input to CLEAN-04:** read the recovery AGENTS.md (in uncommitted-recovery.tar) for durable working rules worth keeping, and drop the consumed Phase 175 standing authorization. |
| 6. Planning paths outside the carry | R-PL-04, -06, -07, -08, -09, -13, -14, -15, -16 | Remove source | Debug, forensics, quick-task and scratch notes; excluded from the carry on purpose (191 D-04). |
| 7. Worktree files | R-WT-1, R-WT-2 | Remove source (both worktrees) | Dirty files are in the worktree tars and patches; their branch commits are in refs-all.bundle. |
| 8. Ignored files | R-IGN-KEEP (+ review-content-13.tar) | Copy local settings forward, remove the rest | Phase 193 copies only the local editor and agent settings into the new `main` checkout, so the working setup carries over. Logs, test output, xcuserdata and the Gradle-output text files are removed. All of it stays in ignored-keep.tar. |
| 9. Environment files | R-ENV | Copy forward, remove source | If the new `main` checkout needs these local settings, Phase 193 restores them there from env-local.tar (mode 0600), without listing names or contents in any record. They are never landed. The 0600 backup stays. |
| 10. Temporary clones | R-TMP-004, -005, -007..-016, -018, -039 | Remove source | Covered by tmp-commits.bundle and the git-directory and dirty tars. |
| 11. Temporary folders | all 33 rows (+ tmp-symlinks-13.tsv, review-repos-13.tar) | Remove source | Past run output and evidence, all archived. The large toolchain and Phase 180 run folders are regenerable. The macOS temp cleaner would erode them anyway. |
| 12. Loose temporary files | R-TMP-LOOSE-KEEP | Remove source | In tmp-loose-files.tar. |
| 13. Unique temporary commits | R-TMP-COMMITS | Remove source | In tmp-commits.bundle and the Phase 179 git-directory tar. None of it is planned work to land. |
| 14. Broken temporary clone | R-TMP-051 | Remove source | The tar stays. Phase 193 runs one read-only check for whether the three commits are on the public companion repository and records the result. The answer stays the same either way. |
| Always removable | R-LOST-FOUND | Remove | Regenerable output of Phase 189's own integrity check. |

## What Phase 193 must still prove before removing anything

1. The 191 carry and the integration branch are merged to `main` (Phase 192), so every *to land* item is on `main`.
2. The backup manifest still verifies (re-run the 189 verify step against the backup root).
3. Settings that were copied forward work in the new checkout before the old checkout is retired.
4. The final check in CLEAN-03 passes: `git status` is clean, `main` CI is green, every open PR has a disposition, and no `/private/tmp` folder is the only copy of anything.
