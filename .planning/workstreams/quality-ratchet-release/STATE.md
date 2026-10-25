---
gsd_state_version: "1.0"
milestone: v28.0
milestone_name: Truth and Release Train
current_phase: 194
current_phase_name: Bearings reset and ADR amendments
status: executing
stopped_at: Completed 194-05-PLAN.md
last_updated: "2026-10-25T13:50:58.164Z"
state_head: 16b8a738236197d7d8d720f739ab143a7eab0098
progress:
  total_phases: 1
  completed_phases: 0
  total_plans: 9
  completed_plans: 5
  percent: 0
last_activity: 2026-10-25
last_activity_desc: Plan 194-05 AGENTS.md trim and STATE trim
---

# Project State

See `.planning/BEARINGS.md` (posture and tripwires), `.planning/ROADMAP-ROLLING.md` (now, next, later, parked) and [ROADMAP.md](ROADMAP.md) for the v28.0 phases 194–199.

## Current Position

Phase: 194 (Bearings reset and ADR amendments), executing
Plan: 6 of 9 next
Status: Plans 01–05 complete; plans 06–09 not started

## Exact Next Action

What was checked: AGENTS.md against main (the approval gate, Sensitive Data Rules and How changes land are byte-identical), the gate contract test with negative controls, and the byte-snapshot ritual search. What happened: AGENTS.md is trimmed to 102 lines (the measured cap; 90 was not reachable without deleting a rule), this file is trimmed, and nothing live in the repo still defines the snapshot ritual. What is unknown: whether later GSD state writes regrow this file past 40 lines; plan 08 re-measures. Nothing was pushed, merged, released or tagged.

Next command: `$gsd-execute-phase 194 --ws quality-ratchet-release` (plan 06).

## Carried debt

See [the v27.0 debt disposition](milestones/v27.0-closeout/debt-disposition.md); the v23 deferred table is in `milestones/v23.0-closeout`. The adopter lane stays parked; its resume is in ROLLING PARKED.
