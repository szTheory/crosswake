---
phase: 192-pr-ci-and-merge
plan: 04
subsystem: release-gate
tags: [merge-gate, one-use-binding, fail-closed, real-shapes, LAND-04]
requires:
  - phase: 192-pr-ci-and-merge
    provides: common-192.sh, gh-shim-192.sh, ci-poll-192.sh (plans 01 and 03)
provides:
  - one-use merge gate (propose, answer, merge, status) binding a plain allow to one displayed head
affects: [192-09, 192-10]
requirements-completed: [LAND-04]
actuals:
  tokens: 20000
  tasks: 2
  commits: 0
key-files:
  created:
    - scripts/merge-gate-192.sh
    - scripts/selftest-merge-192.sh
    - 192-EVIDENCE/selftest-merge-192.out
  modified:
    - scripts/gh-shim-192.sh
status: complete
---

# Phase 192 Plan 04: One-use merge gate Summary

The merge gate was checked with 17 of 17 controls, all built from response shapes captured live (read-only) from GitHub. Two new scripts and one evidence file were added, and the test double got one small change. Nothing was sent to GitHub: every merge call went to the stub inside a throwaway fixture, and no real binding file exists yet. Commits were skipped per the recovery-checkout rule, so `commits: 0` and all files are plain uncommitted files. STATE.md and ROADMAP.md were not touched.

## What was built

- `merge-gate-192.sh`: `propose PR` captures the live head itself, runs every pre-check (scan binding, PR identity, scanned head, CLEAN, Crosswake CI success, main unmoved, synthetic merge parents and tree), writes a mode-600 binding in an owner-only mode-700 folder `192-EVIDENCE/binding/`, and writes `proposal-192.txt` (head, URL, merge method, the three-fact meaning of "CI on main is green", allow and hold scope). `answer allow|hold` re-reads the head and voids on difference. `merge` re-reads everything, voids with its own label on any difference, writes `consumed` before the call, logs `pr_merge pr merge PR -R szTheory/crosswake --merge --match-head-commit HEAD`, calls once, and reconciles by reading the PR back (merged, not merged with a cause, or delivery uncertain exit 3). Fixed argv with a forbidden-option refusal.
- `selftest-merge-192.sh`: controls M01-M17 (no binding, no answer, hold, head change, not clean, failed check, main moved, happy path with five assertions, synthetic tree change, consumed, no retry, read-back reconcile, unscanned head, empty scan verdict, re-ask with new nonce, unsafe folder, aggregate forbidden-option check).

## Evidence

- `selftest-merge-192.out` ends `selftest-merge: controls 17 of 17 as expected`.
- Mutation check: with the consumed write removed, M08, M10 and M11 reported NOT as expected; with the merge-time head re-read removed, M04 did. Gate restored byte-for-byte afterwards.
- `answer maybe` exits 2 with `merge-gate: answer invalid`; `192-EVIDENCE/binding/` does not exist.
- `selftest-ci-192.sh` re-run after the shim change: 15 of 15.

## Deviations from Plan

**1. [Rule 3 - Blocking] Stub could not model "call fails but merge landed"**
- Found during: Task 2 (M12).
- Issue: the stub only applied the post-merge PR state when the merge exit code was 0.
- Fix: also apply it when a `pr-merge-lands` marker file exists in the scenario.
- Files modified: scripts/gh-shim-192.sh (one line).

**2. M15 flow** follows the plan text (propose, head changes, answer allow voids), not an already-allowed binding, since `answer` only accepts state proposed.

**3.** Argv log lines from the stub carry a leading `gh `; M08 strips it to compare with the plan's `pr merge 4242 ...` form.

## Known Stubs

None.

## Threat Flags

None. Binding holds only public PR values, commit ids, a nonce, a time and the state.

## Self-Check: PASSED

Both task verifies pass; all files exist; no fixture folder remains in the temp area; no private path, account or token appears in the scripts or evidence.
