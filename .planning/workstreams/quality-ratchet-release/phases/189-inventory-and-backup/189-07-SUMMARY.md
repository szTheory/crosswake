---
phase: 189-inventory-and-backup
plan: 07
subsystem: infra
tags: [git, bundle, candidate, pull-requests, inventory]
status: complete
requires:
  - phase: 189-02
    provides: compare clone with candidate ref, SHA256SUMS.02
provides:
  - re-verified existing candidate bundles plus one connected (complete-history) bundle
  - C-CAND inventory row (90 commits to land)
  - disposition for each of the seven open PRs
affects: [189-09, 189-10, 191, 192]
requirements-completed: [INV-01, INV-02, INV-03]
actuals:
  size_chars_over_4: 30000
  tasks: 2
  commits: 0
  commits_note: "commit skipped per checkout rule; nothing was staged or committed in the recovery checkout"
plan_head_before: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
plan_head_after: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
key-files:
  created:
    - 189-EVIDENCE/candidate-check.txt
    - 189-EVIDENCE/candidate-commits.tsv
    - 189-EVIDENCE/rows-07.md
    - 189-EVIDENCE/restore-07.tsv
    - 189-EVIDENCE/pr-facts.tsv
    - 189-EVIDENCE/pr-table.md
---

# Phase 189 Plan 07: Candidate bundles and PR dispositions Summary

**The candidate (90 commits beyond fresh main d0dbdf7bf196) now has three verified backups, one of them a complete-history bundle, and all seven open PRs have a recorded, content-based disposition: six "redo after landing", one "hold".**

## What was checked and what happened

I asked GitHub for its current main (still d0dbdf7bf196cea167ced3c50cf620bf3cb2452b, equal to main-sha.txt). In a scratch clone the candidate is 90 commits ahead and 0 behind, so main has not moved and the plan did not stop. The candidate folder is unchanged: HEAD a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4 and 0 changed files.

| Bundle | sha256 | Result |
|---|---|---|
| candidate-a53fbef-full.bundle (existing) | 9f384a3839063b6335a68e5eed6fc63e6520216c70a824990194d3e12102d8fe | sha256 equals the pre-phase record; clone gives HEAD a53fbef7, tree f7c4d7dc, and a bounded count of 90 over d0dbdf7b; no fsck run (shallow boundary) |
| candidate-a53fbef.bundle (existing) | 72e24cdee40718c2fcf1c4ba8a9dc5c2a052348aff3d40b7bc5b5aff808f30ab | sha256 equals the pre-phase record; verifies in a shared clone of the compare clone, requires d0dbdf7b, fetch gives a53fbef7 |
| candidate-a53fbef-connected.bundle (new, in the inventory-189 folder) | 40acd4fe52edfd0052cffce4f37089878e71665ec26a122637b8785a6078399b | records a complete history; mirror clone in scratch passes the connectivity check; candidate a53fbef7, tree f7c4d7dc, main d0dbdf7b, count main..candidate 90 |

The two existing bundles were not touched. SHA256SUMS.07 holds all three and verifies 3 of 3. restore-07.tsv has 3 pass lines. candidate-commits.tsv lists the 90 commit ids with sanitized subjects. rows-07.md holds the C-CAND row (Count 90, class to land).

## PR dispositions (no PR was changed; read-only calls only)

All seven are open and mergeable; each head equals the head fetched from refs/pull/N/head.

| PR | Disposition | Reason in one line |
|---|---|---|
| 238 | redo after landing | 0 of 8 files already in the candidate; the assertion ledger json is edited on both sides, review content at redo time |
| 236 | hold | no release or Hex publish in v27; landing changes what release-please computes, so it will be regenerated |
| 210 | redo after landing | checkout bump; 45 workflow uses already carry the new version, 63 still the old one; rebase may shrink it |
| 211 | redo after landing | setup-beam bump; 10 new, 31 old |
| 239 | redo after landing | setup-node bump; 0 new, 16 old |
| 240 | redo after landing | upload-artifact bump; 0 new, 17 old |
| 241 | redo after landing | download-artifact bump; 0 new, 2 old |

No PR's merge onto the candidate equals the candidate tree, so none is "close as superseded". Uses-line counts are counts only; no pin text is recorded.

## Verification results

- Task 1 checks (all candidate-check values, SHA256SUMS.07 3 of 3, restore-07 3 pass, 90 commit lines, C-CAND row, `verify-189 quick: ok`): passed.
- Task 2 checks (7 rows, allowed dispositions, 236 hold, all OPEN, quick verify ok, scan of 6 evidence files `files 6`, `hits 0`): passed.
- Commit steps: commit skipped per checkout rule.

## Deviations from Plan

**1. [Rule 3 - Blocking] The recovery checkout and candidate were never written to.** Per the frozen-checkout rule no commit was made and the two per-task commits were skipped. Not a plan change otherwise.

**2. gh needs a repository directory.** `ghr pr view` is run from the recovery checkout directory (read only); the first attempt from the run folder failed with "not a git repository" and changed nothing.

**3. Ahead/behind computed in a refreshed shared clone.** A bare `--shared` clone copies only branch refs, so `+refs/*:refs/*` is fetched from compare.git into each scratch clone before use (as noted by plan 06).

## Known Stubs

None.

## Threat Flags

None.

## Notes for plans 08-10

- Plan 09 reruns `verify-candidate-189.sh` (bash, with RESTORE_PLAN unset is fine; it needs `. env-189.sh`); it reuses an existing connected bundle and re-verifies it.
- SHA256SUMS.07 lines name the existing bundles as `../candidate-a53fbef-full.bundle` and `../candidate-a53fbef.bundle`.
- The 4 unique tmp commits that exist only in shallow repos are covered by plan 08 tars, not by the connected bundle.

## Self-Check: PASSED
