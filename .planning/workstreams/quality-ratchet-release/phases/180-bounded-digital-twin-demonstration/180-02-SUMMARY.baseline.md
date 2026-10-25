---
phase: 180-bounded-digital-twin-demonstration
plan: 02
subsystem: scope-decision
tags: [twin, scope-decision, core-seam]
status: complete
requirements_completed: []
decision: allow
gate_verdict: stop_missing_seam
candidate_head: 96e5a63efab657f89f3ac84d5b1d84ff5da5d822
commits: 0
plan_head_before: 96e5a63efab657f89f3ac84d5b1d84ff5da5d822
plan_head_after: 96e5a63efab657f89f3ac84d5b1d84ff5da5d822
actuals:
  tasks: 2
  commits: 0
---

# Phase 180 Plan 02: Scope Decision Summary

The user replied "allow" to the plain-language question about the missing host-command seam. This authorizes a separate core-seam phase. Phase 180 itself changes no core code, and 180-03..180-07 now wait for a fresh gate rerun.

## What was checked

The feasibility gate (180-01) found, against candidate HEAD `96e5a63efab657f89f3ac84d5b1d84ff5da5d822`, that the route policy rejects the host audio command, the generated start-up file carries no capabilities, the native session lacks the command, and the bounded shell refuses offline-island routes. Each fact had a passing control. The verdict was `stop_missing_seam`. That verdict and head were shown to the user, whose own reply ("allow") is bound to them in `180-DECISION.json` (`decided_by: user_reply`).

## What changed

- `180-DECISION.json` written (decision allow, `rebound_from` null, all five plans `awaiting_gate_rerun`, no refuting or control test lists because the decision is not `not_required`).
- STATE.md: one active handoff (superseded planning handoff moved to a history entry), pending core-seam scope item, the "Seam handoff contract:" line (including declaration-driven projection for every declaring route), T01..T10 `not_observed`, failed/blocked, fidelity limits and residual external gates.
- ROADMAP.md: 180-01 and 180-02 marked complete, 180-03..180-07 open and waiting, progress 2/7, new Exact Next Action.
- REQUIREMENTS.md: TWIN-01..TWIN-06 stay Pending with the blocked reason.
- No SUMMARY files were written for 180-03..180-07, so they remain selectable and halt at their gate check.

## User guidance recorded with the decision

Do the core-seam phase properly and not nerfed: declaration-driven projection for every declaring route, offline-island admission in the bounded shell, and a versioned wire contract so existing hosts are not silently broken.

## Deviations from Plan

None - plan executed as written for the allow branch. Task 1 was resolved by the orchestrator using the user's verbatim reply.

## Verification

The plan's automated check passed (decision bound to gate verdict and head, five plan keys, seam handoff line, T01..T10 lines, failed/blocked facts G1-G4 and G6, fidelity and residual lines, phase-plan-index shows no summaries for 180-03..180-07, no TWIN row Complete, feasibility gate text present, recovery index has no staged paths).

## Known Stubs

None.

## Next action

`$gsd-phase --ws quality-ratchet-release` to insert the authorized core-seam phase; afterwards `$gsd-execute-phase 180 --ws quality-ratchet-release` reruns 180-01 in `authorized_seam_rerun` mode.

## Self-Check: PASSED

180-DECISION.json and this file exist; nothing staged or committed in the recovery checkout.
