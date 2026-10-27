---
gsd_state_version: "1.0"
milestone: v28.0
milestone_name: Truth and Release Train
current_phase: 195
current_phase_name: Pipeline repair and hygiene
status: verifying
stopped_at: Independent verification passed8/8; orchestrator Phase195 completion transaction pending
last_updated: "2026-10-27T12:24:03Z"
state_head: ed7d050f9966ccdb334b748bbd3d7a0d22ba5bfe
progress:
  total_phases: 6
  completed_phases: 1
  total_plans: 30
  completed_plans: 30
  percent: 17
last_activity: 2026-10-27
last_activity_desc: Release CI49/49 success; final verification passed8/8; phase completion remains with orchestrator
---

# Project State

See `.planning/BEARINGS.md`, `.planning/ROADMAP-ROLLING.md` and [ROADMAP.md](ROADMAP.md).

## Current Position

Last completed phase:194. Phase195:21/21 plans summarized. PR259 merged once as b8398c38 at reviewed24baafa3; separate current merge/deletion approvals were consumed and the named remote branch is absent. Actual-main proof passed quick190/full327, five controls, zero masked leaks. Nyquist validated/compliant; ASVS L1 security91/91 closed; UI N/A. No human approval is pending.

## Exact Next Action

Release PR236 remains OPEN at bot headf30bd49 with no non-release commits; CI run40499982698 completed49/49 success. Final195-VERIFICATION.md is passed8/8 and the canonical verification.status query returns passed. Next: the parent consumes that verdict and completes Phase195's lifecycle transaction. REL-03 remains pending only for that transaction. Do not repeat delivery, main proof or earlier plans; no Phase196 execution command is eligible before phase completion.

## Carried debt

GR-06 stays with Phase196; original clean-room WR-04/05/06 and IN-03 stay with Phase197; the historical HYG-02 batch override gives no new permission. The adopter lane remains parked.
