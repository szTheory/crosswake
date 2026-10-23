# Phase 189 Plan 10: BLOCKED

**Cause: `scan_hit`.** Plan 10 stopped at the final privacy scan (Task 2, step 2). Task 1 passed completely. Task 2 stopped before the phase-folder backup. Task 3 was run only in its BLOCKED branch (handoff text).

## What was checked and what happened

- Task 1 (passed): the 22 scripts were copied into the phase folder, each byte-identical to its source, and `189-SCRIPTS.sha256` verifies 22 of 22. The after-snapshot's compared lines are byte-identical to the before-snapshot (the recovery checkout is unchanged, HEAD still `d0f3e2f1`, 4 stashes, 56 branches, 3 worktrees, nothing staged). The no-deletion check wrote three `yes` lines: the temp-folder names equal the frozen listing, the backup root gained only `inventory-189`, and both existing candidate bundles keep their before checksums.
- Task 2, step 1 (passed): the 14 pre-execution documents were scanned and recorded in `189-EVIDENCE/predoc-scan.txt`: exit 1, class `credential` has 11 hits (the quoted scan word in 189-CONTEXT.md and plans 01 to 10), every other class is 0, so home, user, gituser and owner are all 0. No phase file contains the reflog stash notation.
- Task 2, step 2 (failed): the final scan over the 74 other phase files reported `files 74`, `hits 2`. Both hits are class `at` (the at-sign) in byte-copied scripts: `scripts/classify-tmp-189.sh` and `scripts/backup-tmp-189.sh`. The matches are the shell array-expansion form (the prune array written with an at-sign index) in a find command, which is not a leak of any kind. The scan only neutralises two known at-sign forms, and this form is a third that the scan class does not exclude.
- Not run, per the plan's stop rule: the phase-folder tar and its restore, the regenerated `SHA256SUMS`, and the `restore-10` registry line. Nothing in the backup folder was changed by plan 10.

## Why this is a stop and not a quiet fix

The plan says a hit in a byte-copied file stops the plan. Fixing it would mean either editing an earlier plan's script (the copy must stay byte-identical to the one that produced the evidence) or weakening the scan or the scope. Both are forbidden by this plan's prohibitions, so the decision needs the orchestrator or user.

## Other findings

- The plan's Task 1 verify requires every `*.sh` in the run folder (except `env-189.sh`) to equal the 22 named scripts. The run folder also holds 16 ad-hoc helper scripts left by earlier plans (for example `finish-09.sh`, `run-t1.sh`, `v1.sh`) plus this plan's `t1.sh`. Nothing was deleted (Phase 189 deletes nothing), so that equality clause cannot hold literally. I checked the intent instead: all 22 named scripts exist in the run folder, and the phase-folder copy holds exactly those 22.
- `lib-189.sh` prints a `BASH_SOURCE` warning when sourced from zsh; all work was run under bash.

## Options to unblock (decision needed, not taken)

1. Amend the plan so the scan or its scope handles this at-sign form for the two byte-copied scripts, then rerun plan 10 from Task 2.
2. Or accept recording these two script files as a documented, named scan exemption (a false positive) in a revised plan 10, and then continue with the tar, restore and manifest.

## Next command

`$gsd-execute-phase 189 --ws quality-ratchet-release` after the `scan_hit` cause above is repaired (plan 10 amended or the exemption decided).

## Self-Check: PASSED

The blocked state is recorded; there is no `189-10-SUMMARY.md`; nothing was staged or committed in the recovery checkout.
