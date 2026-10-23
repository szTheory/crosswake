---
phase: 189-inventory-and-backup
plan: 12
subsystem: recovery-inventory
tags: [durable-candidate, no-deletion, full-restore-rerun]
requires: [189-11]
provides:
  - candidate proof against the durable clone
  - amended no-deletion record
  - full restore rerun result
affects: [189-13]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/189-inventory-and-backup/189-EVIDENCE/candidate-durable-12.txt
    - .planning/workstreams/quality-ratchet-release/phases/189-inventory-and-backup/189-EVIDENCE/snapshot-now-12.txt
    - .planning/workstreams/quality-ratchet-release/phases/189-inventory-and-backup/189-EVIDENCE/no-deletion-12.txt
    - .planning/workstreams/quality-ratchet-release/phases/189-inventory-and-backup/189-EVIDENCE/verify-full-12.out
decisions:
  - "Closing candidate proof rests on <durable-candidate>, not the <tmp> candidate."
metrics:
  duration: about 35 minutes (full rerun about 30 minutes)
status: complete
commits: 0
plan_head_before: not recorded (checkout frozen, no commits by rule)
plan_head_after: not recorded (checkout frozen, no commits by rule)
actuals:
  size_chars_over_4: 9000
  tasks: 2
  commits: 0
---

# Phase 189 Plan 12: Durable candidate, no-deletion and full rerun Summary

All checks passed. The durable candidate clone equals the candidate, nothing was deleted, and the full restore rerun finished clean.

## What was checked and what happened

- **Durable candidate.** The clone beside the backup root (<durable-candidate>) was read with read-only git. HEAD is a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4, tree f7c4d7dc1a86f251c3ba845d3cde8d4c770ae729, branch refs/heads/candidate, 0 changed paths, and its 90 commits since main match the recorded candidate commit list line for line. Result: ok.
- **Frozen state.** A fresh snapshot (candidate lines taken from the durable clone) equals the before-snapshot on every compared line except the two temp-listing lines (159 names before, 99 now; same digest as the earlier after-snapshot). The recovery checkout still has the same HEAD, 4 stashes, 56 branches, 3 worktrees and an empty index.
- **No deletion.** 60 of the 159 recorded temp names are gone; these are the same 60 as in plan 10, none new, none added. 58 are covered by the loose-files tar (restore pass in plan 08), 2 are obsolete with a stated reason, 0 uncovered. The two phase-179 repo folders lost old files; their git-directory tars each have a restore pass. Backup root top level is still the two bundles plus inventory-189; both bundle hashes unchanged. The 22 phase scripts verify 22 of 22 and match their run copies.
- **Disk.** About 490 GB free on the temp volume (need 40 GB). Ok.
- **Full rerun.** Started at 21:17 local (inside the allowed window), finished at about 21:47 with exit 0 and empty error output. It printed 2 quick ok lines, reconcile ok, 77 restore pass lines (74 registered plus 3 candidate bundles), no other restore line, and last line "verify-189 full: ok". Output saved as verify-full-12.out (111 lines).
- **Rewritten evidence.** restore-07.tsv, candidate-commits.tsv, rows-07.md and SHA256SUMS.07 came out byte-identical to their pre-run copies. candidate-check.txt was also identical, so the temp-folder candidate had not changed yet; no restore-back was needed.
- **Commit.** Commit skipped per checkout rule. No git write was made in the recovery checkout or the durable candidate. Nothing was deleted.

## Deviations from Plan

None - plan executed as written. (The frozen-state amended snapshot, scratch-12/snapshot-before-amended.txt, is kept for plan 13.)

## Notes for plan 13

- The amended snapshot is at <tmp>/crosswake-phase189-run/scratch-12/snapshot-before-amended.txt; use with VERIFY_SNAPSHOT and SNAP_CAND set on the command line.
- Fresh restore scratch from this rerun sits under restore/ and scratch-07/; left in place for Phase 193.
- Helper scripts of this plan are in scratch-12/ (t1b.sh, t1c.sh, v1.sh, v2.sh, launch.sh) and scratch-12-t1.sh in the run folder; none are phase scripts.

## Known Stubs

None.

## Self-Check: PASSED

All four evidence files exist; both task verify commands returned 0.
