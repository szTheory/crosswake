---
gsd_state_version: "1.0"
milestone: v28.0
milestone_name: Truth and Release Train
current_phase: 194
current_phase_name: Bearings reset and ADR amendments
status: executing
stopped_at: Completed 194-08-PLAN.md
last_updated: "2026-10-25T13:50:58.164Z"
state_head: 16b8a738236197d7d8d720f739ab143a7eab0098
progress:
  total_phases: 1
  completed_phases: 0
  total_plans: 9
  completed_plans: 8
  percent: 0
last_activity: 2026-10-25
last_activity_desc: Plan 194-08 bearings-report caps, triggers, persona tags, 40-line cap
---

# Project State

See `.planning/BEARINGS.md` (posture and tripwires), `.planning/ROADMAP-ROLLING.md` (now, next, later, parked) and [ROADMAP.md](ROADMAP.md) for the v28.0 phases 194–199.

## Current Position

Phase: 194 (Bearings reset and ADR amendments), executing
Plan: 9 of 9 next
Status: Plans 01–08 complete; plan 09 not started

## Exact Next Action

What was checked: the bearings-report line caps, seed and debt triggers, persona tags and 40-line cap against fixtures with negative controls (72 tests, 0 failures), the merge-blocking lane (2747 tests, 0 failures) and a live run on this branch. What happened: the live run prints no UNVERIFIED line (4 caps ok, 22 prose-only seeds, 12 carried debt rows, 30 of 30 requirements tagged); no workflow or merge-blocking list names the report. What is unknown: nothing is pushed, so CI has not run on these commits. Nothing was pushed, merged, released or tagged.

Next command: `$gsd-execute-phase 194 --ws quality-ratchet-release` (plan 09).

## Carried debt

See [the v27.0 debt disposition](milestones/v27.0-closeout/debt-disposition.md); the v23 deferred table is in `milestones/v23.0-closeout`. The adopter lane stays parked; its resume is in ROLLING PARKED.
