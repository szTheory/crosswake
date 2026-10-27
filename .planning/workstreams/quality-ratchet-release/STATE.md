---
gsd_state_version: "1.0"
milestone: v28.0
milestone_name: Truth and Release Train
current_phase: 195
current_phase_name: Pipeline repair and hygiene
status: executing
stopped_at: Completed 195-20; executing 195-21 review and delivery
last_updated: "2026-10-27T03:31:53Z"
state_head: 6b6dcf6315ca150def2b18a71faf217a41caafea
progress:
  total_phases: 6
  completed_phases: 1
  total_plans: 30
  completed_plans: 29
  percent: 17
last_activity: 2026-10-27
last_activity_desc: Phase 195 plans 19–20 verified and committed; plan 21 active
---

# Project State

See `.planning/BEARINGS.md`, `.planning/ROADMAP-ROLLING.md` and [ROADMAP.md](ROADMAP.md).

## Current Position

Last completed phase: 194. Phase 195: 20/21 plans executed; plans 19–20 are committed on fix/secret-mask-structural. Plan 21 independent review and delivery are active. Verification stays gaps_found (7/8); REL-03 remains pending until fresh actual-main proof.

## Exact Next Action

What was checked: committed candidate masking passed 181/181 and full Node passed 318/318; live census has 94 reference lines, 30 aliases, 2 derived assignments and zero violations. Docs hold the summaries and 202-row numeric timing evidence. Fix head 8c519bff differs from base 7621c0ce in exactly two code/test paths. Nothing has been pushed or merged.

Next: continue `$gsd-execute-phase 195 --gaps-only --ws quality-ratchet-release` at 195-21 Task 1. Do not repeat 01–20. Finish independent review/repairs, evidence helper and exact-head CI before presenting the fresh scoped main-merge decision. Phase 196 is ineligible until fresh passing Phase 195 verification.

## Carried debt

GR-06 stays with Phase 196; prior clean-room debt stays with Phase 197; [v27 debt](milestones/v27.0-closeout/debt-disposition.md) remains. Phase 196 waits for fresh passing Phase 195 verification. The adopter lane remains parked.
