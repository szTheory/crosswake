---
gsd_state_version: "1.0"
milestone: v28.0
milestone_name: Truth and Release Train
current_phase: 195
current_phase_name: Pipeline repair and hygiene
status: awaiting_decision
stopped_at: 195-21 Task2 fresh gate after expiry; merge and automatic deletion pending
last_updated: "2026-10-27T11:47:32.343Z"
state_head: b8f1353facec1f2e8740b007624b9ea6d600f66a
progress:
  total_phases: 6
  completed_phases: 1
  total_plans: 30
  completed_plans: 29
  percent: 17
last_activity: 2026-10-27
last_activity_desc: PR259 CI49/49 and candidate gate passed; approval checkpoint ready
---

# Project State

See `.planning/BEARINGS.md`, `.planning/ROADMAP-ROLLING.md` and [ROADMAP.md](ROADMAP.md).

## Current Position

Last completed phase: 194. Phase 195:20/21 plans executed. Plan21 Task1 is complete; Task2 awaits fresh merge and automatic branch-deletion decisions after the prior display expired. REL-03 and verification7/8 remain pending until approved delivery and actual-main proof.

## Exact Next Action

What was checked: reviewed head24baafa3 passed masking190/190, fullNode327/327 and independent review with zero open findings. Crosswake CI run40449366324 passed49/49 on that head; actual synthetic checkout86bc26ca is separately verified. Helper97/97 selftests and candidate gate passed. Exactly two code/test files change. The prior merge allow is recorded historically but its display expired under the helper; no approval was consumed. The proposed expiry removal was automatically rejected and restored. No main merge, deletion, publish, tag or actual-main proof occurred.

Next: no phase command is eligible before fresh separate merge allow/hold and automatic deletion allow/hold for PR259/fix/secret-mask-structural. Resume plan21 at Task2 using195-21-CHECKPOINT.md and gap3-delivery.json; do not repeat01–20 or Task1. On current allows rerun live gate, merge once with match-head-commit, reconcile docs and run landed proof. Phase196 remains ineligible until fresh passing Phase195 verification.

## Carried debt

GR-06 stays with Phase 196; prior clean-room debt stays with Phase 197; [v27 debt](milestones/v27.0-closeout/debt-disposition.md) remains. Phase 196 waits for fresh passing Phase 195 verification. The adopter lane remains parked.
