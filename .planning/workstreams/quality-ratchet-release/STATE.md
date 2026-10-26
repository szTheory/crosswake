---
gsd_state_version: "1.0"
milestone: v28.0
milestone_name: Truth and Release Train
current_phase: 195
current_phase_name: Pipeline repair and hygiene
status: executing
stopped_at: Completed 195-07-PLAN.md
last_updated: "2026-10-26T03:52:28.464Z"
state_head: 1c59f28ebdc9591f2eb15158b389004c23daa1c6
progress:
  total_phases: 2
  completed_phases: 1
  total_plans: 22
  completed_plans: 16
  percent: 50
last_activity: 2026-10-25
last_activity_desc: Phase 195 planned
---

# Project State

See `.planning/BEARINGS.md` (posture and tripwires), `.planning/ROADMAP-ROLLING.md` (now, next, later, parked) and [ROADMAP.md](ROADMAP.md) for the v28.0 phases 194–199.

## Current Position

Phase: 195 (Pipeline repair and hygiene) — EXECUTING
Plan: 7 of 13
Status: Ready to execute

## Exact Next Action

What was checked: Phase 195 has 13 plans (195-01 to 195-13, waves 1 to 13 in order). They cover REL-01 to REL-06, HYG-01 and HYG-02. The plan checker ran three times, then a targeted fix closed the last 5 warnings. The probes found no verify-path or failing-direction problems in 53 commands. What happened: Phase 194's closeout PR #249 is merged. The plans are committed on local branch `fix/release-fixture-version-stamp` and are not pushed; plan 195-01 expects to start on that branch, and the plans reach `main` inside PR1. What is unknown: CI on PR1, because it is not opened yet. Nothing was released, tagged or pushed.

Next action: `/gsd-execute-phase 195 --ws quality-ratchet-release` from branch `fix/release-fixture-version-stamp`. Every merge, tag push and remote branch delete in the plans needs its own one-use `allow`.

## Carried debt

See [the v27.0 debt disposition](milestones/v27.0-closeout/debt-disposition.md); the v23 deferred table is in `milestones/v23.0-closeout`. The adopter lane stays parked; its resume is in ROLLING PARKED.

## Performance Metrics

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 195 P01 | 100 min | 3 tasks | 11 files |
| Phase 195 P04 | 1 session | 2 tasks | 6 files |
| Phase 195 P06 | 25min | 2 tasks | 10 files |
| Phase 195 P07 | 25min | 2 tasks | 9 files |

## Decisions

- [Phase 195]: Shell fixture comparisons normalize only version-derived values (stamp, crosswake_version, SwiftPM minimumVersion) on both sides; fixtures keep literal 0.2.11

## Session

**Last session:** 2026-10-26T03:52:28.421Z
**Stopped at:** Completed 195-07-PLAN.md
**Resume file:** None
