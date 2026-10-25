---
gsd_state_version: "1.0"
milestone: v28.0
milestone_name: Truth and Release Train
current_phase: 194
current_phase_name: Bearings reset and ADR amendments
status: executing
stopped_at: Completed 194-09-PLAN.md
last_updated: "2026-10-25T13:50:58.164Z"
state_head: 16b8a738236197d7d8d720f739ab143a7eab0098
progress:
  total_phases: 1
  completed_phases: 0
  total_plans: 9
  completed_plans: 9
  percent: 0
last_activity: 2026-10-25
last_activity_desc: Plan 194-09 PR2 merged, closeout PR opened
---

# Project State

See `.planning/BEARINGS.md` (posture and tripwires), `.planning/ROADMAP-ROLLING.md` (now, next, later, parked) and [ROADMAP.md](ROADMAP.md) for the v28.0 phases 194–199.

## Current Position

Phase: 194 (Bearings reset and ADR amendments), executing
Plan: 9 of 9 complete
Status: PR #248 merged; closeout PR open, not merged

## Exact Next Action

What was checked: PR #248 head 106e5a5 (Crosswake CI 49 of 49 green on that head), then `script/bearings-report` on fresh main. What happened: PR #248 merged as ff70560 after its own `allow`; the report prints no UNVERIFIED line (verdict ATTENTION 2: stale dependabot PRs #210 and #211; one worktree, one unlanded branch). Remote tags stayed at 94. What is unknown: CI on the closeout PR head. Nothing was released or tagged.

Next action: merging the closeout PR `docs/194-closeout` needs its own one-use `allow` (not given). Then `$gsd-verify-work 194 --ws quality-ratchet-release`.

## Carried debt

See [the v27.0 debt disposition](milestones/v27.0-closeout/debt-disposition.md); the v23 deferred table is in `milestones/v23.0-closeout`. The adopter lane stays parked; its resume is in ROLLING PARKED.
