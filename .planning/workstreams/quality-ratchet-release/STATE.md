---
gsd_state_version: "1.0"
milestone: v28.0
milestone_name: Truth and Release Train
current_phase: 194
current_phase_name: Bearings reset and ADR amendments
status: executing
stopped_at: Completed 194-06-PLAN.md
last_updated: "2026-10-25T13:50:58.164Z"
state_head: 16b8a738236197d7d8d720f739ab143a7eab0098
progress:
  total_phases: 1
  completed_phases: 0
  total_plans: 9
  completed_plans: 6
  percent: 0
last_activity: 2026-10-25
last_activity_desc: Plan 194-06 bearings-report core and CI check
---

# Project State

See `.planning/BEARINGS.md` (posture and tripwires), `.planning/ROADMAP-ROLLING.md` (now, next, later, parked) and [ROADMAP.md](ROADMAP.md) for the v28.0 phases 194–199.

## Current Position

Phase: 194 (Bearings reset and ADR amendments), executing
Plan: 7 of 9 next
Status: Plans 01–06 complete; plans 07–09 not started

## Exact Next Action

What was checked: the new bearings-report CI check against real captured gh output and a live run, with a negative control per CI read (21 tests, 0 failures). What happened: the report names the PR head CI ran on for the main tip and exits 2 on any failed read. What is unknown: ahead/behind, PR classes, local work and file checks are not built yet (plans 07 and 08). Nothing was pushed, merged, released or tagged.

Next command: `$gsd-execute-phase 194 --ws quality-ratchet-release` (plan 07).

## Carried debt

See [the v27.0 debt disposition](milestones/v27.0-closeout/debt-disposition.md); the v23 deferred table is in `milestones/v23.0-closeout`. The adopter lane stays parked; its resume is in ROLLING PARKED.
