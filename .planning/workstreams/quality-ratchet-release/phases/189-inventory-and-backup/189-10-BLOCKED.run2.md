# Phase 189 Plan 10: BLOCKED (run 2)

**Cause: `deletion_detected`.** Plan 10 run 2 stopped in Task 1, at the no-deletion check and the after-snapshot comparison. Task 2 (scan record, final scan, phase-folder backup) was not started. Task 3 was run only in its BLOCKED branch (handoff text). The recovery checkout is unchanged; the one difference is in the temp folder.

## What was checked and what happened

- Run 1 history: run 1 stopped at the final privacy scan on two array-expansion at-sign hits in byte-copied scripts. The user chose a narrow scan fix (see `189-EVIDENCE/scan-fix-10.txt`); the record of run 1 is `189-10-BLOCKED.run1.md`.
- Scripts copy (passed): the 22 scripts were re-copied into `scripts/` from the current run-folder files; every copy is byte-identical to its source and `189-SCRIPTS.sha256` was regenerated and verifies 22 of 22.
- After-snapshot (failed): `189-SNAPSHOT-AFTER.txt` was retaken. Every compared line equals the before-snapshot (recovery HEAD, 4 stashes, 56 branches, 3 worktrees, planning digest, index, git-directory digest, reflog, candidate state, backup root) except two lines: the listing of loose `crosswake*` names in the temp folder, which had 159 entries before and has 99 now.
- No-deletion check (failed): 60 of the 159 recorded temp-folder names are gone. They are 59 plain files (handoff scripts, probe and diagnostic logs, proof JSON files, closeout helper scripts and notes from phases 175 to 180 and the v23 to v25 milestones) and 1 empty folder. Phase 189 deletes nothing and none of its scripts removes anything, so something outside this phase removed them between plan 10 run 1 (when the names matched) and run 2. The backup root still holds only the two candidate bundles plus `inventory-189`, and both bundles keep their before checksums.
- Is anything lost? Probably not. 58 of the 60 are inside the loose-file backup tar made by plan 08 (`tmp-loose-files.tar`, restore-tested). The other 2 were classified earlier as nothing to keep (an empty folder, and a note whose text is identical to a file on main). `189-EVIDENCE/no-deletion.txt` records `tmp_names_equal: no`, the other two `yes` lines, and the detail.
- Not run, per the stop rule: the pre-execution document scan record, the final privacy scan, the phase-folder tar and its restore, the regenerated `SHA256SUMS`, and the `restore-10` registry line. Nothing in the backup folder was changed by this run.

## Why this is a stop and not a quiet fix

The plan says a "no" in the no-deletion check stops the plan with cause `deletion_detected`, and the after-snapshot must equal the before-snapshot. Editing the before-snapshot, the frozen listing or the check would weaken the proof, which the plan forbids. Putting the 60 files back is not possible here (nothing is restored over the temp folder in Phase 189).

## Options to unblock (decision needed, not taken)

1. Accept that these 60 loose files were removed by something outside the phase (they are backed up or had nothing to keep), amend plan 10 so the baseline is the listing at the moment plan 10 run 1 passed (or compares only names that still exist plus the backup coverage), and rerun plan 10.
2. Or first find out what removed them (another session's cleanup, or the system's temp cleaner), and stop it before rerunning.

## Other findings

- Run 1's Task 1 verify defect still applies: the run folder holds ad-hoc helper scripts from earlier plans, so the literal "every `*.sh` equals the 22 names" clause cannot hold. The intent was checked instead: all 22 named scripts exist and `scripts/` holds exactly those 22, byte-identical.
- `lib-189.sh` prints a warning when sourced from zsh; all work was run under bash.

## Next command

`$gsd-execute-phase 189 --ws quality-ratchet-release` after the `deletion_detected` cause above is decided (plan 10 amended or the temp-folder removal investigated).

## Self-Check: PASSED

The blocked state is recorded; there is no `189-10-SUMMARY.md`; nothing was staged or committed in the recovery checkout.
