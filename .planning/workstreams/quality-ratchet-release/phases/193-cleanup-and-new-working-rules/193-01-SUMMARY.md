---
phase: 193-cleanup-and-new-working-rules
plan: 01
subsystem: infra
tags: [backup, preflight, bundle, restore-check, cleanup]
requires:
  - phase: 189-inventory-and-backup
    provides: the backup root, its sums files, restore-189.sh and the 189 inventory
provides:
  - preflight-193.sh and backup-post189-193.sh (with self-tests) and paths-193.sh
  - integration-191-trials.bundle, post189-tmp.tar, post189-dirty.tar, the checkpoint bundle copy and SHA256SUMS.193 (plus a first dirty-refresh, SHA256SUMS.193r1)
  - 193-POST189-RECORD.md with row ids for every post-189 item
affects: [193-02, 193-04, 193-08]
actuals:
  tokens: 21000
  tasks: 3
  commits: 0
plan_head_before: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
plan_head_after: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
status: complete
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/scripts/paths-193.sh
    - .planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/scripts/preflight-193.sh
    - .planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/scripts/backup-post189-193.sh
    - .planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/193-POST189-RECORD.md
  modified: []
key-decisions:
  - "Bundle has complete history (no ^origin/main prefix), per D-23."
  - "Status comparison done per path by blob (D-27), because 189-SNAPSHOT-AFTER.txt has no single status key."
completed: 2026-10-24
---

# Phase 193 Plan 01: Re-verify the 189 backups and make the post-189 backup

The 189 backups still verify, and everything made after Phase 189 that no backup held is now backed up and restore-tested. Nothing was deleted or moved, the recovery checkout had no git write, and its before/after digest is identical.

## What was checked

- The 22 Phase 189 scripts and every 189 sums file (167, 2, 8, 13, 5, 1, 3, 123, 2, 7 and 2 lines) pass `shasum -a 256 -c` with the expected line counts. The two env archives are mode 600; the ignored-keep listing has 46066 lines.
- Nine 189 archives restore from a hash-checked scratch copy of the 189 scripts: both bundles, ignored-keep, the env archive, both worktree tars and patches, and the phase 179 tar (`restore <archive>: pass` for each).
- The recovery checkout matches the 189 after-snapshot: HEAD, the four stash ids and the three worktree heads are equal.
- 20 refs exist that are not in the 189 ref list. All 20 equal values on the remote (17 tags, `origin/main`, `origin/HEAD`, `pr/238`), so none holds unique content (`published 20, unexpected 0`).
- 1075 dirty paths were already covered by a 189 backup or by `main`; 87 were not (planning records of Phases 189-193, six workstream state files, one local GSD runtime file).
- Ancestry against a freshly fetched `origin/main` (equal to the live remote value): `land/v25-v27`, `candidate-src`, `carry-trial-3` and the durable `candidate` are all on `main`. `carry-trial` and `carry-trial-2` are not.

## What was newly backed up (all new files in the backup root)

- `integration-191-trials.bundle`: five refs (`carry-trial`, `carry-trial-2`, `carry-trial-3`, `land/v25-v27`, `candidate-src`). It has complete history instead of the `^origin/main` prefix D-07 named. This follows D-23: a prefix bundle cannot restore into an empty repository, so the same intent is met with a self-contained bundle.
- `post189-tmp.tar`: 10 temporary entries, 798 files plus one file list per entry. The tree folders (`cut*.d`, `dryrun.d`, `sync.d`, `fin-*.d`, `npm10`, `work`, `compare-build`) are listed, not archived.
- `crosswake-checkpoint-24c8389.bundle`: no 189 sums file held it, so it was copied into the backup root and hashed.
- `post189-dirty.tar`: the 87 uncovered recovery files. A later `dirty-refresh` run added `post189-dirty-r1.tar` (6 files written between the first preflight and the dirty tar).
- `SHA256SUMS.193` (7 lines) and `SHA256SUMS.193r1` (2 lines), each with a `.count` file; both pass `shasum -c`.
- Every new bundle and tar passed the 189 restore check before it was installed.

The second preflight (`preflight-after-backup-193.txt`) passes with both new sums files and reports `dirty covered 1166 difference 0`.

## Deviations from Plan

**1. [Rule 1 - Fact drift] Ten temporary rows, not eleven.** The plan expects 11 un-inventoried `<tmp>` entries. The 11-byte `crosswake-191-locate.out` file was already gone when this plan ran, so 10 entries exist and `193-POST189-RECORD.md` has R-POST-TMP-01..10. The plan's automated check, which asserts exactly 11 TMP rows, therefore does not pass literally. Plan 04 and the final check must derive the expected count from the record, not from 11.

**2. [Rule 1 - Fact drift] 20 published refs, not 18.** Seventeen tags plus `origin/main`, `origin/HEAD` and `pr/238`. All are on the remote. Record rows R-POST-PUB-01..20.

**3. [Rule 1 - Fact drift] `env-local.files` has no `sensitive` first line.** The plan asserted one; the file has 3 plain lines, mode 600. The preflight asserts mode and line count only. Because the restore tool does not delete the scratch copy for such a file, preflight removes the whole restore scratch folder after every restore.

**4. [Rule 3 - Blocking] The durable candidate clone's `origin` is a local bundle file**, so the D-05 fresh fetch uses the GitHub URL of the recovery repo's `origin` for both sibling clones, written into `refs/remotes/origin/main`.

**5. [Rule 2 - Missing handling] Live outputs of this plan are not "differences".** A path under the 193 phase folder modified after `post189-dirty.tar` was made is reported as `info live-after-snapshot`, not as a difference (otherwise the plan's own evidence files could never reach `difference 0`). Plan 08's `dirty-refresh` covers them before any removal. One file the backup run wrote before the dirty tar existed (`ancestry-193.txt`) was a real difference in the first re-check (`preflight-after-backup-193.firstrun.txt`: difference 1); I ran `dirty-refresh` for real (`dirty-refresh-01-193.txt`) and re-ran the preflight, which gave difference 0.

**6. [Rule 3 - Scope] `commits: 0` is by design.** D-03 forbids any git write in the recovery checkout, so there is no per-task commit and no plan-head ledger file (it would live inside `.git`). `plan_head_before` and `plan_head_after` are the unchanged recovery HEAD.

Substitution to record (D-27, user-approved): the D-04 status-checksum comparison was done path by path with blob hashes (and sha256 against the 189 tar listings), because `189-SNAPSHOT-AFTER.txt` has no single status key and its porcelain digests change with every plain-file write in Phases 190-193.

No 191/192 run-folder tool ran after the temporary-entry tar was built. The privacy check of this plan's records is left to plan 02 Task 2 (`privacy-01-193.txt`).

## Verification

- Self-tests: preflight 16 of 16 controls, backup tool 16 of 16 controls (each failure case fails closed; clean fixtures pass).
- Recovery no-change digest: identical at the start and the end.
- Exit codes of every gate were captured directly; no gate was piped through `tail` or `head`.

## Known Stubs

None.

## Self-Check: PASSED

All four created files, the seven new backup artifacts, `SHA256SUMS.193` and `SHA256SUMS.193r1`, and the evidence files exist; the recovery HEAD is unchanged (`d0f3e2f1`).
