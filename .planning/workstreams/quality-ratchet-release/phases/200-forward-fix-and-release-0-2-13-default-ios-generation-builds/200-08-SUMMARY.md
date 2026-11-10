---
phase: 200-forward-fix-and-release-0-2-13-default-ios-generation-builds
plan: 08
subsystem: release-train
tags: [rel-08, rel-09, release-0.2.13, release-0.2.14]
provides:
  - the iOS mirror gate for 0.2.13 and the mirror tag check both ways (evidence from the original 200-08 session)
  - the final release state, closed by Phase 201 after the 0.2.14 run ended COMPLETE
release_run_id: 42639651064
closed_by: 201-08
superseded_by_run: 42713010358
requirements-completed: [REL-08, REL-09]
status: complete
completed: 2026-11-09
---

# Phase 200 Plan 08: iOS mirror gate and final release state Summary

**The 0.2.13 release run published Hex, Maven and the iOS mirror and passed the iOS clean-room proof, then ended FAILURE at the exact-public proof; the plan's COMPLETE truth was met by the 0.2.14 run 42713010358 under Phase 201, and this plan is closed by Phase 201 plan 08.**

## What the plan's truths required, and what happened

| Truth | Result | Evidence |
|---|---|---|
| Mirror tag check for 0.2.13 fails with `mirror_tag_missing` before the iOS gate | met, in the original session | `200-EVIDENCE/mirror-tag-0.2.13-200.txt` |
| Mirror main and tag v0.2.13 pushed only after the publish-ios-mirror allow | met | `200-EVIDENCE/core-ios-200.json`, `gates-200.txt` |
| After the push the tag check passes for 0.2.13 and 0.2.12 fails with `newer_mirror_tag`; parity passes | met | `200-EVIDENCE/mirror-tag-0.2.13-200.txt` |
| The run's mirror tag job passed and the iOS swift build clean-room, which failed for 0.2.12, succeeded for 0.2.13 | met | `200-EVIDENCE/core-run-final-200.json` |
| The run ends COMPLETE with native_core complete and exact-public success, and its ledger job opens a PR with the 0.2.13 line | **not met by run 42639651064**: the run ended FAILURE at `release: exact-public artifact proof` (all five companions `digest_mismatch`, core fully proven); its ledger PR 285 recorded outcome failure | `200-08-BLOCKED.md`, `200-EVIDENCE/core-run-final-200.json` |

## How it closed

The exact-public failure was a defect in the proof, not in the release: the proof digested Hex's `build_env` toolchain stamp, which differs between the CI build and the registry tarball. Phase 201 fixed it (PR 287, merge fdc218f9, companions-only rule) and released 0.2.14. Release run 42713010358 ended COMPLETE: linked rollup COMPLETE, native core complete, iOS clean-room success, mirror tag check PASS, exact-public success with all six packages fully_proven. Evidence: `201-EVIDENCE/run-final-201.json`, `201-EVIDENCE/mirror-tag-0.2.14-201.txt`.

Run 42639651064 stays recorded as FAILURE on attempt 1, never re-run, superseded by the 0.2.14 run (`201-EVIDENCE/reconcile-201.json`). Its ledger line is a failure line, kept faithfully in the release ledger. `200-08-BLOCKED.md` stays as history.

## Deviations from Plan

The plan's COMPLETE outcome was reached by a later run under a different phase, not by the 0.2.13 run. The user confirmed this route on 2026-11-09 through the Phase 201 planning decisions (PD-05).
