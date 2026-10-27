---
gsd_state_version: "1.0"
milestone: v28.0
milestone_name: Truth and Release Train
current_phase: 195
current_phase_name: Pipeline repair and hygiene
status: executing
stopped_at: 195-21 Task 1 reviewed PR259; waiting for exact-head CI
last_updated: "2026-10-27T04:39:55Z"
state_head: c427365b9fbe16b78dfd7df3b717a78542cd6f94
progress:
  total_phases: 6
  completed_phases: 1
  total_plans: 30
  completed_plans: 29
  percent: 17
last_activity: 2026-10-27
last_activity_desc: PR259 open; GAP3 fixes reviewed on 24baafa3; CI running
---

# Project State

See `.planning/BEARINGS.md`, `.planning/ROADMAP-ROLLING.md` and [ROADMAP.md](ROADMAP.md).

## Current Position

Last completed phase: 194. Phase 195: 20/21 plans executed. Plan 21 Task 1 is waiting for PR #259 CI; all eight GAP3 findings are repaired and independently reviewed. Verification stays gaps_found (7/8); REL-03 needs approved delivery and fresh actual-main proof.

## Exact Next Action

What was checked: final fix head 24baafa3 passed masking 190/190 and full Node 327/327; independent re-review passed the nine new families and full suite with zero open findings. Helper self-tests passed 97/97. The privacy-scanned two-file branch is pushed and PR #259 is open. Crosswake CI run 40449366324 targets that head; its distinct synthetic merge is 86bc26ca. CI is still pending: 47 of 48 jobs complete with no failure; the example-host isolation matrix remains. No approval, main merge, deletion, publish or tag occurred.

Next: continue the active execution by monitoring run 40449366324, then run the candidate evidence gate. Do not repeat plans 01–20. Only after exact-head CI and candidate readiness pass may Task 2 display separate merge and automatic branch-deletion decisions. No command starts Phase 196 before fresh passing Phase 195 verification.

## Carried debt

GR-06 stays with Phase 196; prior clean-room debt stays with Phase 197; [v27 debt](milestones/v27.0-closeout/debt-disposition.md) remains. Phase 196 waits for fresh passing Phase 195 verification. The adopter lane remains parked.
