---
gsd_state_version: "1.0"
milestone: v28.0
milestone_name: Truth and Release Train
current_phase: 195
current_phase_name: Pipeline repair and hygiene
status: ready_to_execute
stopped_at: Planned round-3 gap closure 195-19 through 195-21
last_updated: "2026-10-27T02:46:20Z"
state_head: 6b6dcf6315ca150def2b18a71faf217a41caafea
progress:
  total_phases: 6
  completed_phases: 1
  total_plans: 30
  completed_plans: 27
  percent: 17
last_activity: 2026-10-27
last_activity_desc: Phase 195 round-3 gap plans verified
---

# Project State

See `.planning/BEARINGS.md`, `.planning/ROADMAP-ROLLING.md` and [ROADMAP.md](ROADMAP.md).

## Current Position

Last completed phase: 194. Phase 195: 18/21 plans executed; round-3 plans 19–21 ready in waves 4–6. Verification remains gaps_found (7/8); only REL-03 is pending. Plan checking passed after two blocker corrections; validation strategy is draft.

## Exact Next Action

What was checked: authoritative closeout history reconciled locally; six leak probes and quadratic padding reproduced; existing masking 138/138 and targeted ExUnit 46/46 passed. Three new command gates correctly reject the current suite's missing round-3 families. Plans and requirement coverage passed independent review. Nothing is implemented by these plans yet; arbitrary secrets remain outside finite supported-rule proof.

Next: `$gsd-execute-phase 195 --gaps-only --ws quality-ratchet-release` (start 195-19; do not repeat 01–18). Planning is local on `chore/codex-model-profile`; execution must reconcile intended phase artifacts onto `docs/195-closeout`, then branch code from fresh `origin/main` as plan 19 specifies. No push or irreversible operation was performed in this planning run; CI has not run on the new local planning head.

## Carried debt

GR-06 stays with Phase 196; prior clean-room debt stays with Phase 197; [v27 debt](milestones/v27.0-closeout/debt-disposition.md) remains. Phase 196 waits for fresh passing Phase 195 verification. The adopter lane remains parked.
