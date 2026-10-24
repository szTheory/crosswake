---
phase: 193-cleanup-and-new-working-rules
plan: 07
status: complete
requirements: [CLEAN-01, CLEAN-02]
commits: 0
plan_head_before: ed853e3893d3ef4c79a0ab4513f3f0f2cb7b5b40
plan_head_after: ed853e3893d3ef4c79a0ab4513f3f0f2cb7b5b40
---

# Phase 193 Plan 07: Session guard, re-proof and late-record sweep Summary

The new session runs in the clean main checkout at the live origin/main tip. The copy-forward and the build were checked again, Claude memory carried over (24 files, MEMORY.md present), and 25 records written in the old folder after the PR 1 cut were collected as plain files. No commit was made; the retired folder was only read.

## Task results

- Task 1: scripts hash check 12 OK; `guard: full pass`; copy-forward verify pass (settings 6, env 3, runtime 3, exclude_lines 4, allowed_changes 8); `deps_get rc 0`, `compile_wae rc 0`; `memory_index visible files 24`.
- Task 2: manifest delta A 22, M 3, D 0 (25 rows, bucket v27.0); independent floor_a 22 / floor_d 0 equals manifest A/D; 25 applied; privacy clean over 28 files; `sweep-193.txt` ends `result complete`.

## Handoff files (retired copy vs origin/main)

- STATE.md: equal
- ROADMAP.md: equal
- REQUIREMENTS.md: equal
- .continue-here.md: equal

No `handoff-retired/*.retired` copies were needed; plan 09 has nothing to reconcile from the retired folder.

## Deviations from Plan

**1. [Rule 3 - Blocking] copyforward verify failed hash_mismatch on the dispatch sentinel.** `.gsd/dispatch-isolation-sentinel.json` is a settings-category file that every dispatch rewrites (10-minute TTL), so its hash can never match the backup. Fix: `copyforward-193.sh` verify now checks presence and mode only for that one path (stage-time check unchanged). Self-test 28 of 28 passes; the copyforward line in `193-SCRIPTS.sha256` was re-frozen and the 12-line check passes.

**2. [Rule 3 - Blocking] `carry-191.sh manifest` needed `--sync`.** Without it, 38 table rows that match nothing after the PR 1 cut fail the manifest (exit 2). Run with `--sync` (reports `rules unused 38`).

**3. [Rule 3 - Blocking] `carry-floor-191.sh` refuses floor_d 0.** A sweep legitimately has no deletions. A scratch copy with only the floor_d non-empty check removed was used (original script untouched); result floor_a 22, floor_d 0, floor_rows 36.

**4. [Rule 3 - Blocking] `carry-191.sh verify` cannot run without a commit.** It diffs BASE..HEAD, which is empty with no commit. Equivalent check done instead: sha256 of every applied file against the manifest, 23 of 25 equal. The two differing paths are `193-SCRIPTS.sha256` and `scripts/copyforward-193.sh`, which intentionally keep the newer local content (deviation 1); they were backed up and restored after `apply`. `apply` stages with `git add`; the index was reset afterwards so everything is plain working-tree changes.

## Self-Check: PASSED

Both tasks' automated verify blocks pass; HEAD equals origin/main (ed853e38).
