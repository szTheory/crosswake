---
gsd_state_version: "1.0"
milestone: v28.0
milestone_name: Truth and Release Train
current_phase: 195
current_phase_name: Pipeline repair and hygiene
status: planning
last_updated: "2026-10-25T15:55:08.215Z"
state_head: a6460a923fe8053ff8a036cd2a028ea95d8c3903
progress:
  total_phases: 1
  completed_phases: 1
  total_plans: 9
  completed_plans: 9
  percent: 100
last_activity: 2026-10-25
stopped_at: Phase 194 complete, ready to plan Phase 195
last_activity_desc: Phase 194 verified and marked complete
---

# Project State

See `.planning/BEARINGS.md` (posture and tripwires), `.planning/ROADMAP-ROLLING.md` (now, next, later, parked) and [ROADMAP.md](ROADMAP.md) for the v28.0 phases 194–199.

## Current Position

Phase: 195 — Pipeline repair and hygiene
Plan: Not started
Status: Ready to plan

## Exact Next Action

What was checked: Phase 194 is verified as passed (194-VERIFICATION.md, 5 of 5 must-haves met). The regression lane ran 2747 tests with 0 failures. The code review found 0 critical issues; its 10 advisory findings in bearings-report are open in 194-REVIEW-DISPOSITION.md. What happened: PR #247 and PR #248 are merged. The closeout PR `docs/194-closeout` carries the review, the verification and the completion records. What is unknown: CI on the closeout PR head. Nothing was released or tagged.

Next action: merging the closeout PR needs its own one-use `allow` (not given). Then `/gsd-plan-phase 195 --ws quality-ratchet-release`.

## Carried debt

See [the v27.0 debt disposition](milestones/v27.0-closeout/debt-disposition.md); the v23 deferred table is in `milestones/v23.0-closeout`. The adopter lane stays parked; its resume is in ROLLING PARKED.
