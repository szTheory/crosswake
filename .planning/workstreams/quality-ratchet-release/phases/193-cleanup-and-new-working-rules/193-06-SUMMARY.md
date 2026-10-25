---
phase: 193-cleanup-and-new-working-rules
plan: 06
subsystem: infra
tags: [copy-forward, build-proof, folder-swap]
requires:
  - phase: 193-cleanup-and-new-working-rules
    provides: PR 1 merged (plan 05), frozen copy-forward and swap scripts (plan 03)
provides:
  - clean main clone completed from the backups and proven to build
  - folder swap performed as the last writing step (result in 193-EVIDENCE/swap-193.txt)
affects: [193-07]
requirements-completed: []
actuals:
  tasks: 2
  commits: 0
plan_head_before: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
plan_head_after: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
status: complete
completed: 2026-10-24
---

# Phase 193 Plan 06: Copy-forward, build proof, folder swap

This is run 2. Run 1 stopped (copyforward_failed, record 193-06-BLOCKED.run1.md) because the env backup names its files under the original checkout root. Repair R1 (193-06-REPAIR-R1.md) fixed the copy-forward script and re-froze the hash list. Amended precondition for this run: the clean clone is on main at the live tip (ed853e38) and shows exactly two modified files, the re-frozen hash list and the fixed copy-forward script, byte-identical to the recovery copies. That was checked before starting (cmp passed, nothing else in the status).

## What happened

- Runtime backup: already current; the backup files were byte-identical before and after, nothing overwritten.
- Preflight (both sum lists): pass.
- Copy-forward apply into the clone: settings 6, env 3, runtime 3 files; 2 env files tightened to mode 600. Pass.
- Build in the clone: `mix deps.get` exit 0, `mix compile --warnings-as-errors` exit 0.
- Copy-forward verify: pass, with 2 allowed changes (the two repair files above) and nothing else in the clone's status.
- The folders are swapped as the last step, after this file. The result is in 193-EVIDENCE/swap-193.txt in the retired folder. No file is written after the swap in this session.
- Next, in a new session opened in `<home>/projects/crosswake`: `$gsd-execute-phase 193 --ws quality-ratchet-release`.

## Deviations from Plan

**1. [Rule 3 - Blocking] `.env.local` was untracked in the clone.** On the recovery checkout `.env.local` is hidden through its local `.git/info/exclude`, not through `.gitignore`, so the clone showed it as untracked and verify failed `tree_dirty`. Fix: one line `.env.local` appended to the clone's `.git/info/exclude` (git-internal, not a tracked file), mirroring the recovery checkout. Verify then passed. Consequence: verify reports `exclude_lines 4` where the plan expected 3 (the runtime file count). The extra line is this one.

**2. Redundant build rerun.** The build was run twice (the first run finished inside a backgrounded command); both exited 0.

## Notes

- No git write or commit in the recovery checkout; no remote write. Nothing deleted.
- Env file contents and names were not printed or recorded.
- ROADMAP.md and STATE.md untouched; this plan's state update is recorded by the next session.

## Known Stubs

None.
