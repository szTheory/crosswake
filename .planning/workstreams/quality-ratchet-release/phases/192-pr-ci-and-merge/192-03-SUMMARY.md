---
phase: 192-pr-ci-and-merge
plan: 03
subsystem: release-gate
tags: [ci-poll, gh-shim, real-shapes, fail-closed, LAND-03]
requires:
  - phase: 192-pr-ci-and-merge
    provides: common-192.sh (plan 01)
provides:
  - gh/curl test double built only from captured live responses
  - CI poller that decides LAND-03 for the exact PR head and records the synthetic merge (D-08)
affects: [192-04, 192-05, 192-08, 192-10]
requirements-completed: [LAND-03]
actuals:
  tokens: 14000
  tasks: 2
  commits: 0
key-files:
  created:
    - scripts/gh-shim-192.sh
    - scripts/ci-poll-192.sh
    - scripts/selftest-ci-192.sh
    - 192-EVIDENCE/ci-tracer-192.txt
    - 192-EVIDENCE/selftest-ci-192.out
status: complete
---

# Phase 192 Plan 03: CI poller and real-shape test double Summary

A live check on the head of the pull request that produced main (a public, merged PR) returned "completed success", and the same check through the test double built from captured responses gave the same answer. Live branch protection lists exactly one required check, "Crosswake CI" from app 15368, with strict mode on. The self-test passed 15 of 15 controls. Three new scripts and two evidence files were added. Only GET requests were made; nothing was written to GitHub. Commits were skipped per the recovery-checkout rule, so `commits: 0` and all files are plain, uncommitted files. STATE.md and ROADMAP.md were not touched.

## What was built

- `gh-shim-192.sh`: `capture DIR` (16 live read-only responses into a throwaway fixture folder, refused outside the fixture prefix), `install BIN SCEN` (gh and curl stubs answering only from scenario files, with ordered numbered files, field-union checks, exit codes 97/98/99), `derive CAPTURED FILTER OUT` (refuses with `shim: shape changed` unless the output's normalized path set is a subset of the captured set; several captured files may be joined with a colon).
- `ci-poll-192.sh`: `required`, `check SHA` and `wait PR SHA MAX_POLLS`. Selection is by name, app id and head_sha, then highest check-run id. Empty, unreadable and changed-head results all fail closed. On success `wait` writes `ci-192.txt` with the D-08 lines and appends `ci-history-192.txt` with failing job names on every completed wait.
- `selftest-ci-192.sh`: controls C01-C15.

## Evidence

- `ci-tracer-192.txt`: sample head, live and shim `completed success`, `required_set ok`, `capture_files 16`, `result pass`.
- `selftest-ci-192.out` ends `selftest-ci: controls 15 of 15 as expected`. The real `ci-192.txt` was not created.
- RED check: with selection changed to "first line" the self-test reported C02 and C03 NOT as expected; with the app-id condition removed it reported C04 NOT as expected. The script was restored byte-for-byte afterwards.

## Deviations from Plan

**1. [Rule 1 - Bug] Ordering controls were order-blind**
- Found during: Task 2 mutation check.
- Issue: C02 and C03 listed the runs in an order where a "take the first line" bug still gave the right verdict.
- Fix: each control now runs both list orders.
- Files modified: scripts/selftest-ci-192.sh.

**2. [Rule 3 - Blocking] gh needs a repository flag**
- `gh pr view` and `gh pr list` fail from the non-git run folder, so every pr/run call passes `-R` with the repository slug. The shim ignores `-R`.

**3.** The tracer's first run failed on a fixture run folder with the wrong mode (needs 0700); fixed in the tracer driver only. The tracer driver and verify drivers were run from the session scratch folder, not saved in the phase.

## Known Stubs

None.

## Threat Flags

None. All requests are GET reads; captured responses stayed in removed fixture folders.

## Self-Check: PASSED

Both task verifies pass; all five files exist; no tracer fixture folder remains; no private path, account or token appears in the scripts or evidence.
