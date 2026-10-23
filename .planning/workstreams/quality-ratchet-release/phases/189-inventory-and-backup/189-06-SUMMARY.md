---
phase: 189-inventory-and-backup
plan: 06
subsystem: infra
tags: [git, tmp-clones, shallow, reflog, inventory, classification]
status: complete
requires:
  - phase: 189-02
    provides: compare clone, reference refs, SHA256SUMS.02
provides:
  - classification of all 159 frozen temp-folder crosswake entries
  - tmp-tips.tsv, tmp-gitdirs.tsv and tmp-unique.tsv for plan 08
  - tmp-repos.tsv, tmp-entries.tsv, tmp-entry-map.tsv, rows-06.md
  - tmp-entries-full.tsv (real names, backup root) and SHA256SUMS.06
affects: [189-08, 189-09, 189-10, 193]
requirements-completed: [INV-01]
actuals:
  size_chars_over_4: 60000
  tasks: 2
  commits: 0
  commits_note: "commit skipped per checkout rule; nothing was staged or committed in the recovery checkout"
plan_head_before: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
plan_head_after: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
key-files:
  created:
    - 189-EVIDENCE/tmp-repos.tsv
    - 189-EVIDENCE/tmp-entries.tsv
    - 189-EVIDENCE/tmp-entry-map.tsv
    - 189-EVIDENCE/rows-06.md
---

# Phase 189 Plan 06: Temp-folder repos and entries Summary

**All 159 frozen temp-folder crosswake entries are classified by content: 20 valid repos read with every ref, stash entry and reflog commit, 9 broken stubs, 5 distinct commits that exist nowhere else in main, the candidate or the recovery refs, and 5 shallow repos routed to git-directory tars.**

## What was checked and what happened

I read the frozen listing (159 entries: 81 folders and 78 loose files, as the research counted) and found every nested git folder up to four levels deep: 29 candidates, of which 20 are valid repos and 9 are broken stubs (the research counted 8; the live listing has one more). I built a scratch compare clone (not shallow) from the plan-02 compare clone plus GitHub pull-request heads (read only), and a list of every commit and every patch-id reachable from main, the candidate and the recovery refs.

For each of the 20 repos I enumerated stash entries and reflog commits from the absolute git directory and compared them with git's own `stash list` and `log -g --all`. They were equal in every repo.

| Measure | Value |
|---|---|
| valid repos / broken stubs | 20 / 9 |
| refs found (heads / remote-tracking / tags / other) | 10 / 74 / 921 / 0 |
| stash entries (enumerated / independent) | 0 / 0 |
| reflog commits (enumerated / independent `log -g`) | 116 / 116, no `log -g` error |
| unreadable ids | 0 |
| dirty files (environment files set aside, never read) | 2188 (0) |

The 15 non-shallow repos were fetched from (never into) the source, and in every one the created ref count equals the source ref count. In cmp.git the `refs/tmpitem` total equals the sum of captured refs, and cmp.git is not shallow.

**Shallow repos (5).** phase179-impl, phase179-source, phase180-impl (the candidate), phase181-impl, phase182-impl. None was fetched. They were read in place by commit id and patch-id and are listed in `tmp-gitdirs.tsv` with reason shallow and their boundary: 1, 1, 2, 1 and 2 boundary lines (the boundary is the fresh main commit; in two repos the shallow file repeats the same line twice). No tip of a shallow repo is in `tmp-tips.tsv`. There are no zero-ref repos and no repos with unreadable ids, so `tmp-gitdirs.tsv` has exactly the 5 shallow lines.

**Unique work.** 5 distinct commits are not in main, the candidate or the recovery refs (19 repo-level hits). 1 of them is on GitHub; 4 are on no remote, including 5923a679 (held in four repos, none of it on GitHub). 3 are fetched (14 tip lines in `tmp-tips.tsv` for the bundle in plan 08); 2 come only from shallow repos (phase179-impl and the candidate repo) and are covered by those repos' git-directory tars. Unique stash entries: 0.

**Repo classes.** 1 on main (phase179-source), 2 to land (phase181-impl, phase182-impl, both only because none of their refs or reflog commits is unique), 17 unclassified (unique commits, or dirty files that match nothing in main, the candidate or the recovery checkout; 72 such dirty files in 11 repos). Nothing with unique work is obsolete.

**Entries (159).** By class: 31 obsolete (30 folders with no regular file outside git, 1 loose file already in main/candidate/recovery HEAD), 1 on main, 2 to land, 124 unclassified (47 folder rows plus 77 loose files), and the candidate entry mapped to C-CAND without a class. Rows file: 50 individual folder rows R-TMP-001..050, group rows R-TMP-EMPTY (30), R-TMP-LOOSE-SUPERSEDED (1), R-TMP-LOOSE-KEEP (77) and R-TMP-COMMITS (5). There is no R-TMP-LOOSE-EMPTY row because no loose file was empty.

## Verification results

- Task 1 verify (22 columns, equal enumerated and independent counts, shallow routing, captured refs equal source refs, tmp-gitdirs/tmp-tips consistency, cmp.git not shallow, `verify-189 quick: ok`): passed.
- Task 2 verify (159 map and entry lines, one C-CAND, every row id present, classes and obsolete reasons valid, candidate backup plan contains gitdir-tar, R-TMP-COMMITS Count 5 equals distinct ids, `shasum -c SHA256SUMS.06` one OK line, `verify-189 quick: ok`, scan of the 4 evidence files `files 4`, `hits 0`): passed.
- `SHA256SUMS.06` holds 1 line (tmp-entries-full.tsv), OK. Recovery HEAD and the frozen snapshot are unchanged.

## Deviations from Plan

**1. [Rule 1 - Bug] Reflog and stash ids that already exist in cmp.git still get a per-repo ref.** The plan fetches by id only ids "not already present". Once repos share a commit (several clones hold the same detached-HEAD commit), the second repo would find the object present, get no ref, and lose its unique commit. For present objects outside the reference set I create `refs/tmpextra/<n>/<id>` locally with update-ref; only absent ones are fetched by id. All stay in the separate tmpextra namespace.

**2. Nine broken stubs instead of eight.** Expected (the live listing differs from research). They are in tmp-repos.tsv with "-" in numeric columns; folders holding only stubs and no files are in R-TMP-EMPTY.

**3. Validity needs the stub's own top level.** A `.git` stub inside a valid repo's tree would answer `rev-parse HEAD` with the outer repo's HEAD; the script requires the toplevel to equal the folder, so stubs are not mistaken for repos.

**4. Symlinks are not regular files.** Seven of the 30 "empty" folders contain only build-cache symlinks (links into the same or sibling temp folders). They count as zero regular files (D-04) and are not archived; this is the same treatment as plan 05.

**5. The 178 toolchain folder is NOT regenerable by the marker check.** Its `bin` folder holds only a checksum tool, no erl/elixir/mix, so `regen_check` fails and the folder is unclassified with a folder tar (about 3.6 GB on disk, 17063 files kept after the subfolders that pass regen_check are excluded). Plan 08 must budget disk for this; the user may judge it obsolete later.

**6. "Files outside git" means files outside every .git folder and every valid repo working tree.** Ignored or untracked-but-ignored files inside a repo's working tree (for example build folders) are not inspected; dirty-file rules cover only what `status --untracked-files=all` shows.

**7. Commit skipped per checkout rule.** No staging or commit; STATE.md, ROADMAP.md and REQUIREMENTS.md untouched. Nothing in any temp source was written (reads with gr, fetch from sources into scratch only).

## Auth gates

None.

## Known Stubs

None.

## Threat Flags

None. Only a read-only fetch of GitHub pull-request heads into scratch.

## Notes for plan 08

- `tmp-tips.tsv` columns: n, real repo path, ref name in cmp.git (`refs/tmpextra/<n>/<id>`), 40-hex tip; 14 lines, all non-shallow repos (n 2 to 15). `tmp-unique.tsv`: n, id, `fetched` (17 lines) or `shallow-read` (2 lines, repos 16 and 18). `tmp-gitdirs.tsv`: 5 lines (n 16 to 20), absolute git directory in column 3, boundary in column 6 as `k:id12[,id12]`.
- Per-repo unmatched dirty paths (relative, environment files excluded) are in `RUNS/scratch-06/dirty-<n>.txt`; `RUNS/scratch-06/repo-index.tsv` maps n to the real path.
- `tmp-entries.tsv` columns: name, type, nested repos, broken stubs, files outside git, environment files, size KB, class, reason, row id, backup plan; `tmp-entries-full.tsv` has the same columns with real names. The candidate entry has class "-" and plan gitdir-tar.
- Rows whose Backup and Restore are `pending` (50 folder rows minus those covered, the loose-keep and commits rows) are for plan 08 to fill; obsolete rows are already `none needed` / `n/a`.

## Self-Check: PASSED

All four evidence files, the three plan-08 lists, tmp-entries-full.tsv and SHA256SUMS.06 exist; both verify blocks exited 0; the recovery HEAD is unchanged.
