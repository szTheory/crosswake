---
phase: 200-forward-fix-and-release-0-2-13-default-ios-generation-builds
plan: 09
subsystem: release-train
tags: [rel-08, rel-09, reconcile, ledger]
provides:
  - 0.2.12 and 0.2.13 reconciled in writing from live reads
  - issue 281 closed, Hex retire and threadline dispositions recorded, planning truth made to agree
closed_by: 201-08
superseded_by_run: 42713010358
requirements-completed: [REL-08, REL-09]
status: complete
completed: 2026-11-09
---

# Phase 200 Plan 09: Reconcile 0.2.12 and close Phase 200 Summary

**Phase 201 plan 08 carried out this plan's closeout from the COMPLETE 0.2.14 run: both earlier runs are dispositioned with nothing re-run, issue 281 is closed, the deferred items keep their owners, and REQUIREMENTS, ROADMAP and STATE agree.**

## What the plan's truths required, and what happened

| Truth | Result | Evidence |
|---|---|---|
| 0.2.12 run 42494651844 still attempt 1 and PARTIAL as recorded, superseded by a COMPLETE run; issue 281 closed with a plain-language reason; PR 280 recorded; no Phase 199 approval reused | met, with the 0.2.14 run as the superseding COMPLETE run (0.2.13's run ended FAILURE, also superseded and never re-run) | `201-EVIDENCE/reconcile-201.json` |
| Hex retire of 0.2.12 recorded undecided, with recommendation (do not retire) and receiver (a new plan with gate `hex-retire-0.2.12`) | met, nothing retired | `201-EVIDENCE/reconcile-201.json` |
| Threadline 0.1.1 (PR 262) deferred with condition and receiver; live head recorded | met (head moved from `3d65f3fb` to `0fc93dcf`, Release Please refresh, observed only) | `201-EVIDENCE/reconcile-201.json` |
| The 0.2.13 ledger line lands on main byte-identical through a human PR | met through Phase 201's landing PR, together with the 0.2.14 line (see `201-EVIDENCE/ledger-pr-201.json`); bot PR 285 closed with a reason, branch left | `201-EVIDENCE/ledger-pr-201.json` |
| REQUIREMENTS, ROADMAP and STATE agree: REL-08 and REL-09 Complete, REL-07 Pending, one handoff with the exact next command | met | `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md` |

## Deviations from Plan

- The plan closed 0.2.12 against a COMPLETE 0.2.13 run. 0.2.13's run ended FAILURE, so Phase 201 reconciled both runs against the COMPLETE 0.2.14 run.
- The plan landed one ledger line through a ledger-only PR with no `.planning/` path. Phase 201 landed both lines together with the unpushed planning record in one privacy-cleared PR (user decision of 2026-11-09, plan 201-08 landing route).
- The local worktree and branch cleanup this plan listed is carried out by plan 201-08 Task 3.
