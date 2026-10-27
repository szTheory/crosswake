---
gsd_state_version: "1.0"
milestone: v28.0
milestone_name: Truth and Release Train
current_phase: 195
current_phase_name: Pipeline repair and hygiene
status: executing
stopped_at: Completed 195-19; executing 195-20
last_updated: "2026-10-27T03:31:53Z"
state_head: 6b6dcf6315ca150def2b18a71faf217a41caafea
progress:
  total_phases: 6
  completed_phases: 1
  total_plans: 30
  completed_plans: 28
  percent: 17
last_activity: 2026-10-27
last_activity_desc: Phase 195 plan 19 verified and committed; plan 20 next
---

# Project State

See `.planning/BEARINGS.md`, `.planning/ROADMAP-ROLLING.md` and [ROADMAP.md](ROADMAP.md).

## Current Position

Last completed phase: 194. Phase 195: 19/21 plans executed; plan 19 structural repair is committed on the isolated fix branch. Plans 20–21 remain. Verification stays gaps_found (7/8); REL-03 remains pending until fresh actual-main proof.

## Exact Next Action

What was checked: plan 19 candidate masking file passed 149/149 and full Node suite passed 286/286; required TAP families, pre-fix, identity-mask and quadratic controls behaved as expected. Only the two planned code/test files differ on fix/secret-mask-structural (base 7621c0ce; head b0233b8e). No push or irreversible operation occurred. Planning and summary are preserved on docs/195-closeout; model-profile changes remain separate.

Next: continue `$gsd-execute-phase 195 --gaps-only --ws quality-ratchet-release` at 195-20, then 195-21. Do not repeat 01–19. The current execution is ongoing; no user verification is needed. Main delivery will require a fresh scoped merge decision after independent review and exact-head green CI.

## Carried debt

GR-06 stays with Phase 196; prior clean-room debt stays with Phase 197; [v27 debt](milestones/v27.0-closeout/debt-disposition.md) remains. Phase 196 waits for fresh passing Phase 195 verification. The adopter lane remains parked.
