---
phase: 189-inventory-and-backup
plan: 02
subsystem: infra
tags: [git, bundle, reflog, backup, restore-check, inventory]
status: complete
requires:
  - phase: 189-01
    provides: read-only wrappers, snapshot, restore, manifest, verify and scan tooling
provides:
  - scratch mirror and compare clone (read-only for later plans)
  - refs-all.bundle with complete history, its ref list and SHA256SUMS.02
  - reflog-only commit classification and first 189-INVENTORY.md
affects: [189-03, 189-04, 189-05, 189-06, 189-07, 189-08, 189-09, 189-10]
actuals:
  size_chars_over_4: 17500
  tasks: 2
  commits: 0
  commits_note: "commit skipped per checkout rule; nothing was staged or committed in the recovery checkout"
plan_head_before: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
plan_head_after: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
key-files:
  created:
    - 189-INVENTORY.md
    - 189-EVIDENCE/main-sha.txt
    - 189-EVIDENCE/reflog-only.tsv
    - 189-EVIDENCE/rows-02.md
    - 189-EVIDENCE/restore-02.tsv
  modified: []
requirements-completed: [INV-01, INV-02]
---

# Phase 189 Plan 02: Refs and reflog tracer Summary

**All 174 refs, the 4 stash commits and 571 reflog-only commits are in one complete-history bundle outside the temp folder; it restored exactly, is hashed, and the reflog-only commits are classified by content in the first inventory.**

## What was checked and what happened

I copied the recovery checkout into a scratch mirror (read only; the mirror's 174 refs equal the checkout's byte for byte), added backup refs for the four stash commits and for every commit reachable only from a reflog, then bundled the mirror. The bundle restored in a scratch folder with a complete history, a clean connectivity check, an identical ref list and the same HEAD commit and tree. A hash manifest of the bundle and its ref list verifies 2 of 2.

Fresh main was read from the remote and is `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b` (same as the plan's minimum). A fresh bare clone of the remote plus the candidate (`a53fbef7...`, from the existing incremental bundle) and the mirror's refs form the read-only compare clone for later plans. Nothing was fetched into the recovery checkout.

## Numbers

| Measure | Value |
|---|---|
| reflog commit ids (plain-file read, new column) | 2897 |
| independent `log -g --all` ids | 2897 (sets equal; also equal to the before-snapshot) |
| old-column extras added to the capture set | 11 |
| stash reflog / `stash list` | 4 / 4 (sets equal) |
| absent objects | 0 |
| commits reachable from refs after stash-backup refs | 5303 |
| reflog-only commits (R) | 571 |
| refs-all.reflist lines | 174 + 4 + 571 = 749 plus 2 header lines |
| refs-all.bundle | 67758809 bytes, sha256 e4d44517bf216eb52e7cb881dee5502adadaf67f74ac8593955fd30fdf73dd5b |

Classification of the 571: 17 on main (patch-equivalent in main with every changed path matching main; none is an ancestor of main), 0 to land (none is in the candidate), 554 unclassified (backed up; the user decides before Phase 193). Detail of the 554: 108 not patch-equivalent, 444 patch-equivalent but with at least one changed path that differs from main, 1 merge/root commit, 1 not patch-equivalent although its paths match. Nothing is called obsolete.

## Verification

- Task 1 verify block: exit 0 (verify-189 quick ok, counts, reflist, one restore pass, scan with 5 files and 0 hits).
- Task 2 verify block: exit 0 (three rows summing to 571, no obsolete, verify-189 quick ok, scan with 3 files and 0 hits).
- `shasum -a 256 -c SHA256SUMS.02`: 2 OK lines. Recovery HEAD unchanged at `d0f3e2f1`.

## Deviations from Plan

**1. [Rule 3 - Blocking] Compare clone needed an explicit ref fetch.** A bare `--shared` clone copies only branch refs, so `refs/cand/head` and `refs/rec/*` were not in `scratch-02/cmp.git`. `classify-reflog-189.sh` fetches `+refs/*:refs/*` from the compare clone (inside scratch) right after cloning. No effect on the recovery checkout.

**2. Commit skipped per checkout rule.** No task commit, no commit ledger; `commits: 0` with unchanged HEAD.

**3.** The `rows-02.md` first assembly row was provisional (R-REFLOG-OTHER only) and was replaced by the three final rows in Task 2, as planned.

## Auth gates

None.

## Known Stubs

None.

## Threat Flags

None. Only read access to the remote (`ls-remote`, bare clone); no network write.

## Notes for wave-3 plans

- Source `env-189.sh` and `lib-189.sh`; export the plan's own `RESTORE_PLAN`. `restore-189.sh stash` and `headpatch` use `$OUT/refs-all.bundle` as their base (it exists now).
- `RUNS/compare.git` holds `refs/heads/main`, `refs/cand/head` and `refs/rec/*` (including `refs/rec/stash-backup/N` and `refs/rec/reflog-backup/<id>`); take your own `git clone --bare --shared` of it. A shared clone does not carry non-branch refs: fetch `+refs/*:refs/*` from compare.git into it, as `classify-reflog-189.sh` does.
- `RUNS/scratch-02/` holds the id lists (reflog-new, reflog-all, log-g, reachable, reflog-only) and a ready `cmp.git`.
- `assemble-inventory-189.sh` rejects rows without exactly 9 cells, a non-integer Count or a Class outside the four classes; rows files must be named `rows-NN.md`; `pr-table.md` and `scope-note-*.md` are appended as is.
- `verify-189.sh --quick` takes the last line `verify-189 quick: ok`; `SHA256SUMS.02` is now in OUT, so later quick runs also check it.
- Patch-equivalence is common among the unclassified (444 of 554 are patch-equivalent but touch paths that differ on main now); these need user judgement, not automatic "on main".

## Self-Check: PASSED

Output files and OUT contents listed; both verify blocks exit 0; the recovery HEAD and snapshot are unchanged.
