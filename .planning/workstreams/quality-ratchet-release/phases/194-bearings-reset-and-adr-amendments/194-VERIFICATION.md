---
phase: 194-bearings-reset-and-adr-amendments
verified: 2026-10-25T00:00:00Z
status: passed
score: 5/5 must-haves verified
covered_files:
  - .planning/ADR-FIRST-B2C-ADOPTER.md
  - .planning/BEARINGS.md
  - .planning/PERSONAS.md
  - .planning/ROADMAP-ROLLING.md
  - .planning/workstreams/quality-ratchet-release/STATE.md
  - .planning/workstreams/quality-ratchet-release/phases/194-bearings-reset-and-adr-amendments/194-01-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/194-bearings-reset-and-adr-amendments/194-01-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/194-bearings-reset-and-adr-amendments/194-02-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/194-bearings-reset-and-adr-amendments/194-02-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/194-bearings-reset-and-adr-amendments/194-03-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/194-bearings-reset-and-adr-amendments/194-03-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/194-bearings-reset-and-adr-amendments/194-04-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/194-bearings-reset-and-adr-amendments/194-04-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/194-bearings-reset-and-adr-amendments/194-05-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/194-bearings-reset-and-adr-amendments/194-05-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/194-bearings-reset-and-adr-amendments/194-06-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/194-bearings-reset-and-adr-amendments/194-06-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/194-bearings-reset-and-adr-amendments/194-07-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/194-bearings-reset-and-adr-amendments/194-07-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/194-bearings-reset-and-adr-amendments/194-08-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/194-bearings-reset-and-adr-amendments/194-08-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/194-bearings-reset-and-adr-amendments/194-09-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/194-bearings-reset-and-adr-amendments/194-09-SUMMARY.md
  - AGENTS.md
  - script/bearings-report
  - script/bearings_report.exs
  - test/crosswake/bearings_report_test.exs
  - test/crosswake/planning/agents_contract_test.exs
covered_digest: "v3:sha256:4408cd00334d20a4871b993395909ecd9a12954219ef9e8588af57452a172727"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 194: Bearings reset and ADR amendments Verification Report

**Phase Goal:** A new session can orient from three short files and one command, and every governing rule text says the same thing about Android and synthetic profiles.
**Status:** passed
**Re-verification:** No, initial verification

## Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | ROADMAP-ROLLING (<=120), BEARINGS (<=60), PERSONAS exist; BEARINGS listed first in AGENTS.md; MILESTONE-ARC marked historical; AGENTS.md <=102 with gate paragraph byte-identical; JTBD ordering recorded not executed | VERIFIED | wc -l: 67 / 35 / 25 / AGENTS 102. AGENTS.md line 7 lists BEARINGS first. MILESTONE-ARC banner reads HISTORICAL with lessons moved. Gate paragraph diffed against pre-phase main (af1f4f67): identical. ROADMAP-ROLLING row 59 records the superseded JTBD ordering as "not executed". 194-AGENTS-DISPOSITION.md exists. |
| 2 | STATE.md <=40 lines, one handoff, no "Handoff history"; byte-snapshot ritual out of the milestone-start convention | VERIFIED | STATE.md is 39 lines, 0 "Handoff history" matches. Ritual appears only as a dropped row in ROADMAP-ROLLING and in requirement text. |
| 3 | script/bearings-report prints <=40 plain lines, covers the required checks, exits non-zero with UNVERIFIED on read failure, has negative controls, not required | VERIFIED | Ran the tool: 15 lines, rc=1 ATTENTION (stale #210/#211, CI not run on local HEAD; the tool working). CI line names PR #248 head 106e5a5 and says main is only a synthetic merge. Caps, seeds, debt and personas lines present. Focused tests (bearings_report_test, agents_contract_test): 84 tests, 0 failures. Merge-blocking lane reported 2747 tests, 0 failures by the orchestrator. |
| 4 | ADR amendments A1 and A2 in one PR; "frozen" Android posture text only amendment history | VERIFIED | ADR A1 (Android unfrozen, re-freeze trigger) and A2 (five-field gate, one per milestone, profile scenario rows over one host) present; AGENTS.md and PROJECT.md carry the same posture text. Re-ran the SC4 script: 14 scope files, 7 hits, 7 allowlisted (all dated history or refute-pins), 14 posture needles ok, pass. Support matrix and capability map renderers carry "unfrozen" text. |
| 5 | A check confirms every requirement carries a persona/job tag or M | VERIFIED | Tool output "personas: 30/30 requirements tagged"; test coverage in bearings_report_test.exs "persona tags". |

**Score:** 5/5 truths verified, 0 behavior-unverified.

## AGENTS.md cap honesty

The cap is 102, measured 2026-10-25, not the 90 first sketched. It is recorded the same way in ROADMAP SC1, REQUIREMENTS PLAN-02 and 194-EVIDENCE/agents-gate-194.txt ("lines 102 cap 102", gate blocks and bullet rows retained). Not a silent pass: the value was reset openly in the requirement texts. v28.0-SCOPE.md still says "about 90"; it is scoping history, not a rule text.

## Requirements Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| PLAN-01 | SATISFIED | ROADMAP-ROLLING 67/120, five sections, cap enforced by report |
| PLAN-02 | SATISFIED | BEARINGS 35/60 first in AGENTS.md; ARC historical; AGENTS 102/102; gate identical; disposition file |
| PLAN-03 | SATISFIED | STATE 39/40, no history section |
| PLAN-04 | SATISFIED | tool run and tests above |
| PLAN-05 | SATISFIED | PERSONAS P1-P7, J1-J5, 25 lines; 30/30 tagged; JTBD not executed |
| ADR-01 | SATISFIED | A1 plus aligned AGENTS/PROJECT/support-matrix/capability-map text |
| ADR-02 | SATISFIED | A2 |

No orphaned requirements: all seven IDs are mapped to Phase 194 in REQUIREMENTS.md and marked Complete.

## Anti-Patterns / Review

194-REVIEW.md: 0 critical, 6 warning, 4 info, all in the bearings-report tool or its tests, all open and advisory (194-REVIEW-DISPOSITION.md). Notable: WR-01 (a crash exits 1 instead of the UNVERIFIED exit 2) and WR-02 (no git/gh timeouts) weaken the fail-closed claim in edge cases. They do not falsify the verified read-failure path, and are carried as a follow-up. Not a blocker.

## Human Verification Required

None.

## Gaps Summary

No gaps. Phase goal achieved. Advisory follow-up: close the bearings-report review findings.

_Verifier: Claude (gsd-verifier)_
