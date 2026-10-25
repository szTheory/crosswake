---
gsd_state_version: "1.0"
milestone: v28.0
milestone_name: Truth and Release Train
current_phase: 194
current_phase_name: Bearings reset and ADR amendments
status: executing
stopped_at: Completed 194-07-PLAN.md
last_updated: "2026-10-25T13:50:58.164Z"
state_head: 16b8a738236197d7d8d720f739ab143a7eab0098
progress:
  total_phases: 1
  completed_phases: 0
  total_plans: 9
  completed_plans: 7
  percent: 0
last_activity: 2026-10-25
last_activity_desc: Plan 194-07 bearings-report sync, PR classes and local work
---

# Project State

See `.planning/BEARINGS.md` (posture and tripwires), `.planning/ROADMAP-ROLLING.md` (now, next, later, parked) and [ROADMAP.md](ROADMAP.md) for the v28.0 phases 194–199.

## Current Position

Phase: 194 (Bearings reset and ADR amendments), executing
Plan: 8 of 9 next
Status: Plans 01–07 complete; plans 08–09 not started

## Exact Next Action

What was checked: the bearings-report sync, PR-class and local-work checks against real captured fixtures and a live run, with negative controls (40 tests, 0 failures). What happened: the report prints ahead/behind, PR classes with stale PRs and local-work counts, and a failed fetch or truncated list is UNVERIFIED. What is unknown: file checks and the 40-line truncation are not built yet (plan 08). Nothing was pushed, merged, released or tagged.

Next command: `$gsd-execute-phase 194 --ws quality-ratchet-release` (plan 08).

## Carried debt

See [the v27.0 debt disposition](milestones/v27.0-closeout/debt-disposition.md); the v23 deferred table is in `milestones/v23.0-closeout`. The adopter lane stays parked; its resume is in ROLLING PARKED.
