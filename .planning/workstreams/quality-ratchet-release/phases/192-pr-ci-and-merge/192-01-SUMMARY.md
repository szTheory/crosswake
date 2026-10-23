---
phase: 192-pr-ci-and-merge
plan: 01
subsystem: release-gate
tags: [push-gate, git, selftest, fail-closed]
requires:
  - phase: 191-integration-branch-and-local-suite
    provides: finalize-191.sh --check-binding, scan record at the SYNC head, pinned git helper
provides:
  - push gate that can send only the scanned HEAD to refs/heads/land/v25-v27
  - shared library common-192.sh for Plans 02-05
affects: [192-02, 192-03, 192-04, 192-05, 192-06, 192-07, 192-08, 192-09, 192-10]
actuals:
  tokens: 4500
  tasks: 2
  commits: 0
key-files:
  created:
    - scripts/common-192.sh
    - scripts/push-192.sh
    - scripts/selftest-push-192.sh
    - 192-EVIDENCE/recovery-before-192.txt
    - 192-EVIDENCE/scan-191-at-SYNC.txt
    - 192-EVIDENCE/push-192.txt
    - 192-EVIDENCE/selftest-push-192.out
status: complete
---

# Phase 192 Plan 01: Push gate and dry run Summary

The recovery snapshot taken before any Phase 192 work is byte-identical to the Phase 191 after-snapshot. A dry-run push at the scanned SYNC head was accepted by GitHub. The self-test passed 15 of 15 controls. Nothing was written to GitHub. Commits were skipped per the recovery-checkout rule (all files are plain, uncommitted files), so `commits: 0`.

## What was built

- `common-192.sh`: sourced library (paths, constants, `is_sha40`, `is_int`, `ev_write`, `live_ref`, `ghx`, `log_write`, and the self-test hook guard).
- `push-192.sh` (`--dry-run`, `--push`): refuses unless `finalize-191.sh --check-binding` exits 0 and prints `finalize: binding pass`. It also checks that remote `main` still equals MAIN_SHA, that MAIN_SHA is in HEAD, and that any existing remote branch tip is a strict ancestor of HEAD. It pushes only `HEAD:refs/heads/land/v25-v27`, with `--no-follow-tags --porcelain`, once, then reads the remote back.
- `selftest-push-192.sh`: 15 controls against a local bare remote.

## Evidence

- `recovery-before-192.txt` equals `recovery-after-191.txt` (cmp exit 0).
- `push-192.txt` line 1: dry-run at head 98e0d390..., main d0dbdf7b..., remote_before absent, remote_after absent, result dry-run_ok. The credential came from the per-command `gh auth git-credential` helper.
- `scan-191-at-SYNC.txt`: head equals SYNC, `scan_exit 0`, `scan: result clean`.
- `selftest-push-192.out` ends `selftest-push: controls 15 of 15 as expected`. The real clone HEAD was unchanged.
- RED: with step (h) (remote branch tip handling) removed, the self-test reported 12 of 15, with P10 and P12 (and P13, see below) NOT as expected.

## Deviations from Plan

**1. [Rule 1 - Bug] Self-test P13 fixture**
- Found during: Task 2, first real run (14 of 15).
- Issue: the orphan commit used the main tree, while the working tree held the land file, so the clone was dirty and `push: clone dirty` fired instead of `push: main not in head`.
- Fix: the orphan commit now reuses HEAD's own tree. The production script was not changed.
- Note: P13 was therefore also red in the RED run; that was this fixture bug, not the removed step.

Otherwise the plan was executed as written. The Task 2 automated verify was run with `sh`, because the interactive shell is zsh and does not split `set -- $T`.

## Known Stubs

None.

## Threat Flags

None. No new network surface beyond the planned push gate.

## Self-Check: PASSED

All three scripts and four evidence files exist; both task verifies pass; no private path, account or token appears in the scripts or evidence (grep found none).
