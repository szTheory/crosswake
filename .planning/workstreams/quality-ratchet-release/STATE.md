---
gsd_state_version: "1.0"
milestone: v28.0
milestone_name: Truth and Release Train
current_plan: 4
status: executing
stopped_at: Completed 197-03-PLAN.md
last_updated: "2026-11-05T15:54:21.733Z"
state_head: 91503186a6f96892bb42b2f5c3a39c15d60bfc52
progress:
  total_phases: 4
  completed_phases: 3
  total_plans: 62
  completed_plans: 50
  percent: 75
current_phase: 197
current_phase_name: Public docs truth
last_activity_desc: "Phase 196 verified and complete 2026-10-29: UAT 36/36, security 39/39 closed, verification 5/5, full core suite 2923/0 on main 97ec5f7b; SPEC-04 moved to v29.0"
---

## Current Position

Current Plan: 4
Total Plans in Phase: 15

## Exact Next Action

Phase 197 is executing on branch `docs/197-public-docs-truth` (cut from origin/main, planning commits cherry-picked; not pushed). Last completed plan: 197-01 (docs-report, shared `mix test` gate). Next: execute 197-02 via `/gsd-execute-phase 197 --ws quality-ratchet-release`. The merge to main needs a fresh one-use allow and is not executor work. The user's uncommitted `.planning/config.json` change stays uncommitted.

## Carried debt

WINDOWS46/47 record missing full coverage and blocked classification/decision;43/44 remain resolved by useful bootstrap/controls. WINDOWS40/41/42/45 and SPEC-05/ARCH-02 review flags remain. Collection default is enforce (recaptured on actual main); the ratchet tests already run in required root-proof, and no new required job exists. Review R-03 defers other trailing-line-end identifier patterns outside the offline boundary. Cleanroom WR-04/05/06 and IN-03 stay with197;adopter lane parked. Commands,hashes and measured actuals live in14-SUMMARY. Source-verifier mismatch resolved at00cc1f3b:exact committed13/14 amendment,original receipt unchanged,50 helper controls and actual verify-source1359 passed;see196-SOURCE-VERIFIER-FOLLOWUP.md. Branch fix/spec-structure-ratchet;no external delivery.

## Session

**Last session:** 2026-11-05T15:54:21.570Z
**Stopped at:** Completed 197-03-PLAN.md
**Resume file:** None

## Accumulated Context

### Roadmap Evolution

- Phase 196 edited: edited fields: requirements, success_criteria — SPEC-04 moved intact to v29.0 (overrun cut order, D-03/D-24); both attempts preserved

## Performance Metrics

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 196 P15 | 3h 40m | 3 tasks | 20 files |
| Phase 196 P16 | 6h 15m | 2 tasks | 11 files |
| Phase 196 P17 | about 1h 50m (this run; landed proof 66 min) | 3 tasks | 5 files |
| Phase 197 P01 | 70min | 3 tasks | 6 files |
| Phase 197 P02 | 45min | 3 tasks | 8 files |
| Phase 197 P03 | 55min | 2 tasks | 3 files |

## Decisions

- [Phase 196]: Second fixed reviewed replan identity (base 90a809ce, commit f04c98cf) in verify-source beside the 13/14 amendment; never a caller registry.
- [Phase 196]: Candidate identity hashes phase-evidence.mjs and measure-main.mjs whole, so plans 16 and 17 run finished modes only and edit neither tool.
- [Phase 196]: Facade stages expose no counts, so the core, Swift and Android suites also run directly; Gradle is forced to execute because an unchanged test task reports UP-TO-DATE.
- [Phase 196]: Post-halt candidate is recorded as an amendment with failed runs retained; the 196-15 summary and both tools stay unedited, and the actual-main receipts stay pinned to b8398c38 (guard blobs unchanged).
- [Phase 196]: Absence collections default is enforce; the Phase 170 ledger is regenerated with cited overrides rather than retired, since retiring it is a separate decision.
- [Phase 197]: Plan 01: leak patterns carry a leading word boundary so SEED-NN is not also counted as D-NN
- [Phase 197]: Plan 01: scan floor below parsed .md extras is UNVERIFIED for both leaks and links; every later mix test gate runs through script/mix_test_gate.sh
- [Phase 197]: DOCS-01, DOCS-02 and SC1/SC2 amended 2026-10-29 to CONTEXT D-04 (:ios_host deferred to Phase 199), D-06 (clone-labeled blocks) and D-10 (matrix links to the registry).
- [Phase 197]: Plan 02: warning location is the first corner-marker line before the next warning, not any path:digits line; D-19 baseline differs from discussion only by counting unit (occurrences vs distinct lines)
- [Phase 197]: 197-03: file:// fixtures answered locally in fetch (missing 3, uncopyable 4); version validation uses a bash regex so a missing grep is tool_unavailable, not usage

### Blockers

None. The 196-16 halt is superseded (history in 196-EVIDENCE/196-16-halt-1-superseded.md).

Carried concerns from Phase 196 verification (non-blocking):
- [Phase 196] The grammar receipt (`main-grammar.json`, blob e0891db6) is stale on main since PR 265 commit 94d2d788 changed `test/js/ci_secret_masking.test.mjs` (timing bound only; 207/207 pass). The snapshot tools refuse at HEAD by design (`stale_measured_blob`, `main_ref_mismatch`); any later re-verification of promotion at HEAD needs a recapture or an amendment.
- [Phase 196] Two candidate runs each failed one child with no observed cause (`example-host-proof`; `root-core-suite` 1 of 2920); the runner keeps only output hashes, so a recurring flake would stay undiagnosed.
- [Phase 196] T-196-37 partial: `gateReady` does not rerun the SPEC-04 prose scan (medium, below block_on). `measure-main.mjs self-test` rewrites the tracked `196-EVIDENCE/measurement-controls.json` on each run. `MUEX-DECISION.md` still says the deferral is proposed; ROADMAP and REQUIREMENTS are authoritative. `196-VALIDATION.md` is still draft (the Nyquist audit was not completed).
