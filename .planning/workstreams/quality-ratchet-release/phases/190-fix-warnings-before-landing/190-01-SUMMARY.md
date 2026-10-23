---
phase: 190-fix-warnings-before-landing
plan: 01
subsystem: test-baseline
tags: [baseline, work-clone, suite-gate]
status: complete
requirements: []
key-files:
  created:
    - scripts/locate-190.sh
    - scripts/ensure-work-190.sh
    - scripts/suite-gate-190.sh
    - scripts/recovery-snap-190.sh
    - 190-EVIDENCE/setup-01.txt
    - 190-EVIDENCE/recovery-before.txt
    - 190-EVIDENCE/no-twin-before.txt
    - 190-EVIDENCE/baseline-failures.txt
    - 190-EVIDENCE/baseline-totals.txt
    - 190-EVIDENCE/baseline-dispositions.md
commits: 0
actuals:
  tasks: 2
  commits: 0
---

# Phase 190 Plan 01: Work clone and measured baseline Summary

A rebuildable work clone and a measured list of the tests that already failed at a53fbef now exist, so later fixes can be judged against real numbers.

## What was checked and what happened

- The locate script found the checkout, the backup folder and the durable candidate by folder walking only (no git command), and wrote the environment file under the Phase 190 temp folder (folder mode 0700, file mode 0600).
- The work clone was created from the durable candidate at a53fbef (tree f7c4d7dc), dependencies fetched, test build compiled. A second run of the ensure script reported `reused`. The durable candidate still has no deps or _build folder and a clean status.
- The quick test (provenance_test.exs) passed: 11 tests, 0 failures.
- The recovery checkout's git state was recorded as digests and counts read from files under its .git folder; a fresh snapshot matches the recorded one. The Phase 180 run folder is absent after the reboot (recorded as `phase180_run absent`, zero started sentinels, zero go/no-go records).
- One full suite run in the work clone was measured: 2622 tests, 6 failures, 78 excluded, exit 2.

## Difference from the research figures

Research expected 1 failure (the Phase180TwinFeasibilityTest "G1 gate" test). The measured run has 6: that test plus five Phase170VacuousAssertionLedgerTest tests. In those five, a JSON decode of a spawned tool's output stops at an unexpected character near byte 790, which looks like extra text mixed into the output; I did not investigate the root cause (outside FIX-01..07 and not rerun, to avoid quietly choosing a nicer number). Test count (2622) and excluded count (78) match research. The measured list is the gate, per D-10 and assumption A2.

The example-host suite (G2/G6) and the Swift suite (G4) are outside the root suite, untouched by FIX-01..07, and were not rerun.

## Dispositions

`190-EVIDENCE/baseline-dispositions.md` has one `listed` row with a plain reason for each of the 6 failures, plus three `listed (not run in Phase 190)` rows (G2, G6, G4). The Phase 188 privacy scan over the six evidence files reported `scan: files 6`, `scan: hits 0`.

## Deviations from Plan

None - plan executed as written. (Executor note: the plan's verify one-liners were run piecewise rather than as one chain; every clause held.)

## Commit

Commit skipped per checkout rule (planning files are plain files; nothing staged). No git command was run in the recovery checkout; the durable candidate was only read and cloned from.

## Known Stubs

None.

## Self-Check: PASSED
