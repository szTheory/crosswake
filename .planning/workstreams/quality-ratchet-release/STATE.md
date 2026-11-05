---
gsd_state_version: "1.0"
milestone: v28.0
milestone_name: Truth and Release Train
current_plan: Not started
status: executing
stopped_at: Phase 197 complete, ready to plan Phase 198
last_updated: "2026-11-05T20:06:50.651Z"
state_head: d81c110a2458294f9fb311892195667f91742572
progress:
  total_phases: 4
  completed_phases: 3
  total_plans: 62
  completed_plans: 62
  percent: 75
current_phase: 198
current_phase_name: Android foreign-host proof
last_activity_desc: "Phase 196 verified and complete 2026-10-29: UAT 36/36, security 39/39 closed, verification 5/5, full core suite 2923/0 on main 97ec5f7b; SPEC-04 moved to v29.0"
---

## Current Position

Current Plan: Not started
Total Plans in Phase: 15

## Exact Next Action

All 15 plans of Phase 197 are done on branch `docs/197-public-docs-truth`, pushed at `e49366372c41c2854520dc80985529ffb0a89dae` (PR 268, open). Last completed plan: 197-14 (real four-leg clean-room PASS against 0.2.11 with `:ios_host` a named Phase 199 deferral; PR 268 Crosswake CI green 38 of 38 on the synthetic merge `9d0aa1f0`, run 42089200558; the earlier red run was fixed by the separately merged PR 269 and a merge of main; full suite 3134/0 and docs-report remeasured at `35f18f93`). DOCS-01, DOCS-02 and DOCS-03 are marked complete. The 197-14 SUMMARY commit is local and not pushed. Phase 197 is ready for verification, but the merge of PR 268 to main needs a fresh one-use allow for the PR head at that time (not executor work; re-read the delete-branch-on-merge setting first, `false` on 2026-11-05). After the merge the exact next command is `/gsd-verify-work 197 --ws quality-ratchet-release`. The user's uncommitted `.planning/config.json` change stays uncommitted.

## Carried debt

WINDOWS46/47 record missing full coverage and blocked classification/decision;43/44 remain resolved by useful bootstrap/controls. WINDOWS40/41/42/45 and SPEC-05/ARCH-02 review flags remain. Collection default is enforce (recaptured on actual main); the ratchet tests already run in required root-proof, and no new required job exists. Review R-03 defers other trailing-line-end identifier patterns outside the offline boundary. Cleanroom WR-04/05/06 and IN-03 stay with197;adopter lane parked. Commands,hashes and measured actuals live in14-SUMMARY. Source-verifier mismatch resolved at00cc1f3b:exact committed13/14 amendment,original receipt unchanged,50 helper controls and actual verify-source1359 passed;see196-SOURCE-VERIFIER-FOLLOWUP.md. Branch fix/spec-structure-ratchet;no external delivery.

## Session

**Last session:** 2026-11-05T19:18:36.737Z
**Stopped at:** Phase 197 complete, ready to plan Phase 198
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
| Phase 197 P04 | 95min | 3 tasks | 2 files |
| Phase 197 P05 | 25min | 2 tasks | 2 files |
| Phase 197 P06 | 75min | 2 tasks | 2 files |
| Phase 197 P07 | 55min | 2 tasks | 2 files |
| Phase 197 P08 | 45min | 2 tasks | 3 files |
| Phase 197 P09 | 50min | 2 tasks | 5 files |
| Phase 197 P10 | 25min | 2 tasks | 3 files |
| Phase 197 P11 | 20min | 2 tasks | 6 files |
| Phase 197 P12 | 25min | 3 tasks | 7 files |
| Phase 197 P15 | 25 min | 3 tasks | 11 files |
| Phase 197 P13 | 75min | 2 tasks | 8 files |
| Phase 197 P14 | about 1h 10m (second session; first session blocked at CI) | 2 tasks | 8 files |

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
- [Phase 197]: 197-04: docs leg runs only run blocks; a failed run block stops its own file only; extra fail-closed parse reasons (no_fences, readme_scope_missing, unterminated_fence, bad_id); asdf callers must set CLEANROOM_ELIXIR_VERSION and CLEANROOM_ERLANG_VERSION for the docs leg
- [Phase 197]: 197-05: CLEANROOM_DOCS_REF wins over the Hex tarball default; tarball members must be regular non-symlink files
- [Phase 197]: 197-06: compile_warning names the leg-written host path; apply blocks and harness compile count in executed; apply structure and doctor requirement are validated at parse time
- [Phase 197]: 197-07: required-step check is dynamic over executed bodies per file; :ios_host exemption is version-conditional on DOCS_IOS_HOST_SINCE=0.2.12; DOCS_EXECUTED_FLOOR=1 is a placeholder until 197-09
- [Phase 197]: 197-09: DOCS_EXECUTED_FLOOR pinned to 18 (16 run/apply blocks without since= plus 2 harness compiles), asserted equal in the marker test
- [Phase 197]: 197-11: publish.parity candidate rule keys on the Published Hex truth pointer (GitHub Releases + hex.pm links), not version sentences; CHANGELOG makes no current-release claim
- [Phase 197]: 197-15: qualifier sentences sit on one physical line and the guard reads heading plus body, so a wrapped or heading-only claim cannot slip past D-26
- [Phase 197]: 197-13: ledger fix-forward regenerates the collection-assertion snapshot with the script classifier; D-07b literal mutation is rejected statically by required_step doctor, so a --router mutation is also run to reach the runtime doctor step
- [Phase 197]: 197-14: dependency advisories fixed by separate PR 269 to main, then main merged into the branch; mix.lock is a measured input so suite and docs-report after-counts were remeasured; PR 268 green 38/38 on e4936637 (CI ran on synthetic merge 9d0aa1f0)

### Blockers

The 196-16 halt is superseded (history in 196-EVIDENCE/196-16-halt-1-superseded.md).

Carried concerns from Phase 196 verification (non-blocking):
- [Phase 196] The grammar receipt (`main-grammar.json`, blob e0891db6) is stale on main since PR 265 commit 94d2d788 changed `test/js/ci_secret_masking.test.mjs` (timing bound only; 207/207 pass). The snapshot tools refuse at HEAD by design (`stale_measured_blob`, `main_ref_mismatch`); any later re-verification of promotion at HEAD needs a recapture or an amendment.
- [Phase 196] Two candidate runs each failed one child with no observed cause (`example-host-proof`; `root-core-suite` 1 of 2920); the runner keeps only output hashes, so a recurring flake would stay undiagnosed.
- [Phase 196] T-196-37 partial: `gateReady` does not rerun the SPEC-04 prose scan (medium, below block_on). `measure-main.mjs self-test` rewrites the tracked `196-EVIDENCE/measurement-controls.json` on each run. `MUEX-DECISION.md` still says the deferral is proposed; ROADMAP and REQUIREMENTS are authoritative. `196-VALIDATION.md` is still draft (the Nyquist audit was not completed).
- 197-14 blocked at CI: PR 268 red on proof-dependency-security (new advisories phoenix_html 4.3.0, ecto 3.13.6; needs mix.lock bumps outside the plan's fix targets) and e2e-proof (apt timeout, rerun). See 197-14-BLOCKED.md
