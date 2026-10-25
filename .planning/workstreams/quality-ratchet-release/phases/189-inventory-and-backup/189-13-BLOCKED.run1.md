# Phase 189 Plan 13: BLOCKED

**Cause: `review_content_found`** (a second check, IN-05, also missed its expected result: `review_check_failed`). Plan 13 stopped inside Task 1, at the nested-repository check for review finding WR-13. Task 2 (recorded scan, final scan, supplemental checks) and Task 3 (phase-folder backup, final manifest, success handoff) were not run. The recovery checkout is unchanged, nothing was deleted, and no commit was made (commit skipped per checkout rule).

## What was checked and what happened

- Read-only checks were run for every review finding. Passed with a recorded block in `189-EVIDENCE/review-checks-13.txt`: WR-01 to WR-10, WR-14, WR-15, and the record-only items IN-01 to IN-04 and IN-06. WR-11 was not run because it belongs to the scan step.
- WR-12 (files skipped as "regenerable"): the three excluded lists held no flagged file. In the 20 regenerable folders of the recovery checkout, 42 files (23271 listed) are text, source or config files inside Gradle build output. They are now in `review-content-13.tar` in the backup root (mode 0600) and a fresh restore passed (`restore-13.tsv`). A planted control flagged 7 of 7 as expected.
- WR-13 (a) symlinks: in the 42 temp folders that have a folder tar, 79 links are build or dependency links and 244 are something else. The 244 are listed in `tmp-symlinks-13.tsv` in the backup root (mode 0600); recreating them in a scratch folder gave 244 of 244 with every target equal, recorded as pass in `restore-13.tsv`.
- WR-13 (b) repositories: this is the stop. Of 80 present temp folders, 6 contain a directory with both HEAD and objects. Three are the `.git` directories of shallow clones that were already backed up. The other three are bare repositories that a test created inside the scratch area of the phase 180, 181 and 182 candidate clones. Each is empty: 20 files, zero commits, zero references. They were not in `tmp-repos.tsv`, `tmp-gitdirs.tsv` or the cr01 tar, so the plan's rule requires an emergency backup and a stop. The emergency tar is `review-repos-13.tar` (60 files, mode 0600) and its fresh restore passed.
- WR-13 (c): the recovery checkout's ignored keep entries hold 27 symbolic links (mostly mix build links named `priv` and `src`), and `ignored-keep.tar` has no symlink entries, so these 27 are counted but not archived. There are 0 environment-style symlinks in the recovery checkout and its two extra worktrees. The plan only asks for the counts; they are in the evidence file.
- IN-05: the plan expects no configured remote URL under the run folder to equal the recovery checkout path. One does: the origin of `mirror.git`, which git wrote when the read-only mirror clone was made in plan 02. Nothing was pushed or fetched into the checkout (the plan 12 snapshot comparison shows it unchanged), so this is a provenance record, not a write path, but it is not the expected 0.

## Bookkeeping done before the stop

- `189-EVIDENCE/review-checks-13.txt` (21 finding blocks: 17 pass, 1 content_backed_up, 2 fail, 1 not_run) and `189-EVIDENCE/restore-13.tsv` (3 pass lines).
- Backup root: `review-content-13.tar` + `.files`, `tmp-symlinks-13.tsv`, `review-repos-13.tar` + `.files`, and `SHA256SUMS.13` (5 lines). `RESTORE-RESULTS.txt` has the 3 new lines (81 total). `SHA256SUMS` was regenerated and verifies 165 of 165; every line of the per-plan manifests is in it. `restore-registry-13.tsv` lists the two tar restores for the next full check.
- `189-DECISIONS-NEEDED.md`: one sentence added under group 8 (the 42 build files) and one under group 11 (the 244 links and the three empty repositories).
- `189-REVIEW-DISPOSITION.md` was not edited: apart from CR-01 every row still reads `open`, because the plan sets the dispositions only after all of Task 1 passes.

## Deviations noted in the checks

- WR-08: the plan names only the phase 179 clone's git-directory tar, but one unique commit comes from the phase 180 clone. The check used all five shallow-clone git-directory tars plus the restored commits bundle: 5 of 5 ids resolve.
- WR-14: a stash untracked tar (for example `stash-0-untracked.tar`) is restored by the `stash-0` restore line, not by a line with its own name; that mapping was accepted. 213 rows checked, 0 gaps.
- IN-05: compared by exact equality of the URL, not by prefix (the backup root path starts with the checkout path).

## Why this is a stop and not a quiet fix

The plan says any repository found that is not already backed up must be tarred and then stops the plan with `review_content_found`. Treating three empty test repositories as harmless would be a judgement the plan reserves for a decision, and the IN-05 count is a different result from the one the plan expects. Editing the check to pass would weaken it.

## Options to unblock (decision needed, not taken)

1. Accept both results as recorded exceptions: the three bare repositories are empty test leftovers already kept in `review-repos-13.tar`, and the `mirror.git` origin is git's own record of where the mirror came from. Amend plan 13 (check WR-13 (b) to record empty bare repositories as backed up rather than stopping, and IN-05 to expect the one `mirror.git` origin), then rerun plan 13 from the start. The new backups and restore lines can be reused; the rerun regenerates `SHA256SUMS.13` and `SHA256SUMS`.
2. Or decide that the 27 unarchived build symlinks in the keep entries need an archive too, add that as a gap plan, and run it first.

## Next command

`$gsd-execute-phase 189 --gaps-only --ws quality-ratchet-release` after the `review_content_found` cause above is decided (plan 13 amended, or the gap plan added). Phase 190 works in `<durable-candidate>`.

## Self-Check: PASSED

The blocked state is recorded; there is no `189-13-SUMMARY.md`; nothing was staged or committed in the recovery checkout; the four new backup files and `review-content-13.tar` exist and `SHA256SUMS` verifies 165 of 165.
