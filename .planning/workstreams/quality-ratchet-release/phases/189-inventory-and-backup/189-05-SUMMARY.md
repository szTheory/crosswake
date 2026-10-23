---
phase: 189-inventory-and-backup
plan: 05
subsystem: infra
tags: [ignored-files, env-files, backup, tar, restore-check, inventory]
status: complete
requires:
  - phase: 189-02
    provides: SHA256SUMS.02, frozen snapshot
provides:
  - restricted archive of local environment files (3 files, mode 0600) with a passing restore test
  - ignored-keep.tar (46066 non-regenerable ignored files) with a passing restore test
  - ignored-entries.tsv, env-counts.txt, rows-05.md (R-ENV, R-IGN-REGEN-*, R-IGN-KEEP, R-LOST-FOUND), restore-05.tsv
  - SHA256SUMS.05 over 5 backup files
affects: [189-09, 189-10, 193]
requirements-completed: [INV-01, INV-02]
actuals:
  size_chars_over_4: 30000
  tasks: 2
  commits: 0
  commits_note: "commit skipped per checkout rule; nothing was staged or committed in the recovery checkout"
plan_head_before: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
plan_head_after: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
key-files:
  created:
    - 189-EVIDENCE/ignored-entries.tsv
    - 189-EVIDENCE/env-counts.txt
    - 189-EVIDENCE/rows-05.md
    - 189-EVIDENCE/restore-05.tsv
---

# Phase 189 Plan 05: Ignored content and environment files Summary

Everything in the recovery checkout that git status does not show is now accounted for: local environment files sit in a restricted archive, non-regenerable ignored files sit in a second archive, regenerable build folders are marked obsolete, and the lost-found folder is recorded for removal in Phase 193. Both archives restore exactly, and planning holds counts only.

## What was done

**Environment files (R-ENV).** Counts only: recovery checkout 3, extra worktrees 0, frozen tmp entries 0, total 3. Tracked-and-clean files skipped: 23. Tracked-and-dirty: 0. The 3 files are in `env-local.tar` (mode 0600) with `env-local.files` (mode 0600) in the backup root. Restore test passed (3 files, sha256 and mode equal); its restored copy was removed. R-ENV is class unclassified (the user decides before Phase 193). No name, path, hash or content is in planning.

**Ignored content.** 83 ignored entries listed by sanitised name and size in `ignored-entries.tsv`. Regenerable (obsolete, marker-checked, no backup): mix build output 7, mix dependencies listed in mix.lock 4, npm packages listed in package files 3, Gradle build output 4, SwiftPM build output 1, Python bytecode cache 1. Everything else is kept: 46066 regular files (about 3.2 GB; `ignored-keep.tar` is 3321830912 bytes) including `.claude/settings.local.json`, the six worker json/log files, `prompts/ARCHITECTURE-CODE-WALKTHROUGH-DNA.md`, `.expert`, `doc`, `tmp` minus regenerable subfolders, the root `.build` folder (no Package.swift beside it, so its marker fails and it is kept), root `deps` and two package `deps` folders (marker fails), `erl_crash.dump` files, `.DS_Store` files and test output. Restore test passed (46066 files, sha256 and mode equal, no symlinks, no AppleDouble entries). The `.claude/worktrees/agent-*` directory is excluded (plan 04 worktree rows).

**Lost-found.** R-LOST-FOUND, 248 files, obsolete, "created by Phase 189 research ... remove in Phase 193"; untouched.

`SHA256SUMS.05` covers `ignored-keep.tar`, `ignored-keep.files`, `ignored-regenerable.list`, `env-local.tar`, `env-local.files` (5 lines, all OK). Task 1 and task 2 verifies passed; `verify-189 quick: ok` after both; privacy scan of the four evidence files: files 4, hits 0.

## Deviations from Plan

**1. [Rule 3 - plan verify defect] Registry grep used a space.** The task 1 verify greps `'^env-local.tar '` (space) in the registry, but restore-189.sh writes tab-separated lines, so the literal check would count 0. I ran the same check with a tab-aware match (exactly one registry line). All other conditions ran as written.

**2. [Rule 2 - fidelity] 12 symlinks in the keep set are not archived.** The restore test forbids symlinks, and `find -type f` omits them. They are build-cache links (`.expert/build/.../priv|src`, a tmp `.build/debug` link, one test link back to the checkout). Each is listed with its target (path placeholders applied) in `ignored-regenerable.list` as "symlink not archived". Phase 193 can treat them as regenerable.

**3. Notes, not defects.** `ignored-regenerable.list` also lists nested regenerable folders inside kept roots (for example an `_build` inside the agent worktree and a `.build` under tmp) and 22 of its lines are folders plus 12 symlink lines (34 total after de-duplication). The ignored-keep restore scratch copy (about 3 GB, non-sensitive) remains under the run folder's restore directory, as for earlier plans.

Commits: commit skipped per checkout rule. STATE.md, ROADMAP.md and REQUIREMENTS.md untouched.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

Files verified present: backup-ignored-189.sh, backup-env-189.sh, the five backup files and SHA256SUMS.05 (all OK), the four evidence files; lost-found folder still present.
