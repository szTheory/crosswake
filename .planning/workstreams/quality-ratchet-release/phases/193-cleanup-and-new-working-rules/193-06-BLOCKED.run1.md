---
phase: 193-cleanup-and-new-working-rules
plan: 06
status: blocked
cause: copyforward_failed
requirements-completed: []
---

# Phase 193 Plan 06: BLOCKED (copyforward_failed)

Nothing was swapped. Both folders are where they were: `crosswake` is still the recovery checkout and `crosswake-clean-main` is still the clean clone on main.

## What happened

- Runtime backup: ran for real, 3 files backed up (post189-runtime.tar, SHA256SUMS.193b).
- Preflight (with SHA256SUMS.193 and .193b): pass. Record: 193-EVIDENCE/preflight-06-193.txt.
- Copy-forward apply into the clone: reported pass (settings 6, env 3, runtime 3, env_tightened 2).
- Build in the clone: `mix deps.get` exit 0, `mix compile --warnings-as-errors` exit 0 (193-EVIDENCE/build-proof-193.txt).
- Copy-forward verify: FAILED with `tree_dirty`. The clone's git status is not empty.

## Cause

The 3 env-file entries in `env-local.tar` / `env-local.files` are stored with their full original path (they start with `Users/<user>/projects/crosswake/`), not relative to the repository root. `apply` extracts them as listed, so they landed in an untracked `Users/<user>/projects/crosswake/...` folder inside the clone instead of at `.env.local` and the two `local.properties` locations. They are therefore untracked, not ignored, and not at the place the project expects. The self-test fixtures used repo-relative names, so it did not catch this. The frozen scripts (checked by hash) cannot be edited in this plan.

## State left behind

- Clone `crosswake-clean-main`: on main at ed853e3, plus one untracked top-level folder `Users/` (the misplaced env files, mode 600). Nothing else changed. Not removed, so nothing is lost.
- Recovery checkout: no git write. Only plain evidence files and this note were written.
- Backup root: new post189-runtime.tar/.files and SHA256SUMS.193b/.count exist and are valid.

## Needed

Fix `copyforward-193.sh` (strip the leading original-root prefix for env members in `apply` and `verify`, and `.files` path check), refresh 193-SCRIPTS.sha256, add a self-test control using the real absolute-style member names, delete the misplaced `Users/` folder in the clone, then re-run plan 06 from `apply`.
