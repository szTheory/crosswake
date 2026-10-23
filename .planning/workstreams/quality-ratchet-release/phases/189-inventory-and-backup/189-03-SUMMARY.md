---
phase: 189-inventory-and-backup
plan: 03
subsystem: infra
tags: [git, stash, backup, restore-check, branch-classification, inventory]
status: complete
requires:
  - phase: 189-02
    provides: refs-all.bundle, scratch mirror and compare clone
provides:
  - four stash backups (patch + untracked tar) with SHA256SUMS.03, each restored exactly
  - content classification of 4 stashes, 56 local branches and 5 ref groups (rows-03.md)
affects: [189-09, 189-10, 193]
actuals:
  size_chars_over_4: 20000
  tasks: 2
  commits: 0
  commits_note: "commit skipped per checkout rule; nothing was staged or committed in the recovery checkout"
plan_head_before: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
plan_head_after: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
key-files:
  created:
    - 189-EVIDENCE/rows-03.md
    - 189-EVIDENCE/restore-03.tsv
    - 189-EVIDENCE/branch-classes.tsv
    - 189-EVIDENCE/ref-counts.txt
    - 189-EVIDENCE/stash-0-paths.tsv
    - 189-EVIDENCE/stash-1-paths.tsv
    - 189-EVIDENCE/stash-2-paths.tsv
    - 189-EVIDENCE/stash-3-paths.tsv
  modified: []
requirements-completed: [INV-01, INV-02]
---

# Phase 189 Plan 03: Stash backup and ref classification Summary

**All four stashes are exported as a tracked patch plus an untracked-files tar and restored exactly; all 56 local branches and the 5 other ref groups (174 refs total) are classified by content, with 23 branches ancestors of main, 6 more whose merge result equals main's tree, and 27 left for the user to decide.**

## What was checked and what happened

I exported each stash from the scratch mirror: the tracked diff (the content of `stash show -p`) and the third-parent archive (the content of `--include-untracked`). Each one was restored into a fresh folder from `refs-all.bundle`: the reapplied tree id equalled the stash tree id and every untracked file hashed to its recorded blob. All four passed (restore-03.tsv). Untracked counts were 15, 15, 2 and 83, as expected. Stashes 2 and 3 have an empty tracked patch (they hold only untracked files). The eight artifacts are hashed in `SHA256SUMS.03` (8 of 8 OK).

Content comparison against fresh main (`d0dbdf7bf196cea167ced3c50cf620bf3cb2452b`) and the candidate: none of the paths in any stash matches either, so all four stashes are **unclassified** (backed up; the user decides before Phase 193). Path counts: 30, 30, 2 and 83, with 0 equal to main and 0 equal to the candidate in each case.

Branches (56, matching the checkout's 56): **23 ancestor of main, 6 merge result equals main tree, 0 patch-equivalent with matching paths, 0 to land, 27 unclassified.**

- Merge-tree on main: `feat/sigra-personal-session-release`, `fix/align-companion-core-constraints`, `fix/hex-publish-clean-release`, `fix/remove-stale-rulestead-release-as`, `fix/sigra-cleanroom-default`, `test/pack-store-waiter-clarity`.
- Unclassified (san form): `agent-169-05-gap-closure`, `agent-169-05-gap-closure-pr`, `archive/v21-parked-pre-reconcile-20260828`, `backup/pre-179-local-main`, `chore/accrue-host-command-bridge`, `chore/first-adopter-guidance-cleanup`, `chore/sync-main-20260805`, `chore/track-110-patterns`, `chore/v15-coll01-advisory-deferred`, `chore/v15-milestone-archive`, `docs/alpha-reference-host-seed`, `docs/seed-007-ci-cd-performance`, `docs/sigra-personal-account-authority-seed`, `feat/iphone-rehearsal-handoff`, `fix/hex-registry-cache`, `fix/release-rollup-dependencies-pr`, `gsd/phase-168-0-2-1-release-candidate-readiness`, `gsd/phase-175-evidence-execution`, `local/main-pre-remote-sync-20260808`, `main`, `phase-174-clean-room-host-realism`, `phase-175-ios-tag-repair`, `phase-175-receipt-assembly`, `recovery/phase-175-orchestrator-2026-09-27`, `release-please--branches--main--components--crosswake_sigra`, `resume/chimeway-notification-physical-proof`, `worktree-agent-p78-20261004T153017`.

Research patch-equivalent branches that moved: under the stricter path rule no branch qualifies by patch-equivalence alone-plus-paths (count 0). The research expected 7 patch-equivalent and 2 merge-tree; the measured result is 6 merge-tree and 0 patch-equivalent-with-matching-paths, so up to 7 research "patch-equivalent" branches are either among the 4 additional merge-tree branches or sit in the unclassified list. The check is count based (23 / 0 to land / at least 24 unclassified / both named merge-tree branches on main), and it passed.

Ref groups (namespace counts 56 heads, 56 remotes, 59 tags, 1 gsd, 1 tmp, 1 stash = 174): `refs/gsd` is on main (1 of 1 ancestors). Remote-tracking refs (27 of 56 ancestors of main; 36 of 56 reachable from a GitHub branch), tags (56 of 59 ancestors; 56 of 59 reachable), `refs/tmp` (0 of 1) and `refs/stash` (0 of 1) are unclassified. Nothing is called obsolete.

## Verification

- Task 1 verify conditions: restore-03.tsv 4 pass lines; SHA256SUMS.03 8 of 8 OK; registry 4 lines; 4 R-STASH rows; `expect` mode 700; 4 expectations; `verify-189 quick: ok`.
- Task 2 verify conditions: 56 eleven-column lines; class counts equal the recount and sum to 56; main equals main-sha.txt; 23 / 0 / 27 at d0dbdf7; both named branches on main; namespace counts sum to 174; 56 R-BR rows and 5 R-REFS rows; all Class cells within the four classes; no obsolete; `verify-189 quick: ok`; privacy scan `scan: files 8`, `scan: hits 0`.
- I ran the block's checks as bash scripts (equivalent conditions, outputs shown above), not as a single pasted command.
- Recovery HEAD unchanged at `d0f3e2f1`.

## Deviations from Plan

**1. Commit skipped per checkout rule.** No staging or commit; `commits: 0`.

**2. [Rule 1 - Bug] Own script fix.** `classify-refs-189.sh` first used the wrong argument for the ref-group helper (counts 0); fixed and rerun before any row was written. Only this plan's own script was touched.

No plan-01 or plan-02 script was edited.

## Auth gates

None.

## Known Stubs

None.

## Threat Flags

None. All merge-tree and classification work ran in `scratch-03/cmp.git`; the recovery checkout, mirror and compare repos were only read.

## Notes for later plans

- `scratch-03/cmp.git` holds a ready shared clone with all refs. `scratch-03/groups.txt` holds the group stats.
- Stashes 2 and 3 have empty tracked patches by design; the restore handles that.
- Stash-0 and stash-1 are the same size; they may hold near-identical content (both noted as planning preservation work).
- 27 unclassified branches (listed above) and the unclassified remote/tag/tmp/stash groups need a user decision before Phase 193. `main` (local) is among them (9 commits not in fresh main).
- Rows file is `189-EVIDENCE/rows-03.md` (4 stash, 56 branch, 5 ref-group rows, 9 cells each).

## Self-Check: PASSED

Artifacts exist in OUT and in 189-EVIDENCE; both verify blocks pass; recovery HEAD and snapshot unchanged.
