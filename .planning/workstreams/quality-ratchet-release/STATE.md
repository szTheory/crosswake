---
gsd_state_version: "1.0"
milestone: v28.0
milestone_name: Truth and Release Train
current_plan: Not started
status: executing
stopped_at: Phase 198 complete, ready to plan Phase 199
last_updated: "2026-11-06T02:21:21.529Z"
state_head: d032c554b380fb0fb45ce183975c4ba6a08d082a
progress:
  total_phases: 5
  completed_phases: 3
  total_plans: 74
  completed_plans: 74
  percent: 60
current_phase: 199
current_phase_name: Release 0.2.12
last_activity_desc: "Phase 196 verified and complete 2026-10-29: UAT 36/36, security 39/39 closed, verification 5/5, full core suite 2923/0 on main 97ec5f7b; SPEC-04 moved to v29.0"
---

## Current Position

Current Plan: Not started
Total Plans in Phase: 12

## Exact Next Action

Last completed phase: 198 (Android foreign-host proof): 12 of 12 plans, verification passed 4 of 4, PR 270 merged to main as 00adfd23, closeout docs PR 271 merged as d032c554; AND-01, AND-02 and AND-03 complete. Phase 197 is also complete. Active phase: none open; the next milestone phase is 199 (Release 0.2.12), not yet planned. Exact next actions: (1) promote the foreign-host leg to a required check in its own reviewed PR (D-20): `bash script/android_foreign_promotion.sh` reported `clean_runs=2/2 eligible=yes` on head 9b96b483; the PR edits the final proof leaf list and the umbrella needs, and its merge needs a fresh one-use `allow`; (2) plan Phase 199 with `/gsd-plan-phase 199 --ws quality-ratchet-release`; every merge, publish and tag in 199 needs its own `allow`. Open items: Phase 198 has no SECURITY.md (secure-phase never ran; run `/gsd-secure-phase 198 --ws quality-ratchet-release` or record why it is not needed). Earlier handoffs are in `history/`.

## Carried debt

WINDOWS46/47 record missing full coverage and blocked classification/decision;43/44 remain resolved by useful bootstrap/controls. WINDOWS40/41/42/45 and SPEC-05/ARCH-02 review flags remain. Collection default is enforce (recaptured on actual main); the ratchet tests already run in required root-proof, and no new required job exists. Review R-03 defers other trailing-line-end identifier patterns outside the offline boundary. Cleanroom WR-04/05/06 and IN-03 stay with197;adopter lane parked. Commands,hashes and measured actuals live in14-SUMMARY. Source-verifier mismatch resolved at00cc1f3b:exact committed13/14 amendment,original receipt unchanged,50 helper controls and actual verify-source1359 passed;see196-SOURCE-VERIFIER-FOLLOWUP.md. Branch fix/spec-structure-ratchet;no external delivery.

## Session

**Last session:** 2026-11-06T01:57:38.147Z
**Stopped at:** Phase 198 complete, ready to plan Phase 199
**Resume file:** None

## Accumulated Context

### Roadmap Evolution

- Phase 196 edited: edited fields: requirements, success_criteria — SPEC-04 moved intact to v29.0 (overrun cut order, D-03/D-24); both attempts preserved
- Phase 198 edited: AND-01 and SC1 corpus wording (D-01) and Phase 199 SC6 removal list gains guides/parity_ledger.md (D-08)

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
| Phase 198 P01 | 25min | 3 tasks | 9 files |
| Phase 198 P02 | 20min | 3 tasks | 2 files |
| Phase 198 P03 | 15min | 3 tasks | 3 files |
| Phase 198 P04 | 30min | 3 tasks | 11 files |
| Phase 198 P05 | 25min | 3 tasks | 11 files |
| Phase 198 P06 | 20min | 3 tasks | 9 files |
| Phase 198 P07 | 30min | 3 tasks | 10 files |
| Phase 198 P08 | 40min | 3 tasks | 12 files |
| Phase 198 P09 | 35min | 2 tasks | 3 files |
| Phase 198 P10 | 50min | 3 tasks | 4 files |
| Phase 198 P11 | 35min | 2 tasks | 3 files |
| Phase 198 P12 | about 3h 30m (two CI fix-forward cycles) | 3 tasks | 19 files |

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
- [Phase 198]: JVM tests use AOSP-derived android-json test artifact; production keeps platform org.json (D-09)
- [Phase 198]: SemVer digit-only on Android; divergence from iOS Int(_:) recorded as debt row (e)
- [Phase 198]: Plan 02: BridgeChannel boundary tests run with counted near-miss loops and positive controls; every D-12 near miss denied fail closed, no finding. server.event.push and server.state.update ungated behavior is pinned as characterization only (debt row a)
- [Phase 198]: Plan 03: Kotlin JVM test floor runs as separate android-package-unit steps (Option A, stage argv unchanged); floor 25 ratchet with derived XML-to-source equality, measured 37/37/20; selftest controls verified by mutation
- [Phase 198]: Plan 04: generator hashes the one binary written to the three corpus copies and emits VectorSetHash.kt; every Kotlin corpus load goes through VectorCorpus.loadVerifiedBytes (CW-VECTOR-HASH); AND-01 stays open until Swift (Plan 05) and the ledger (Plan 07)
- [Phase 198]: Plan 05: Swift constant generated from the same hex as Kotlin and outside Resources/; five Swift loaders verify via CryptoKit (CW-VECTOR-HASH); one-time byte-flip turned both native suites red; AND-01 stays open until the ledger (Plans 06/07)
- [Phase 198]: Plan 06: Android evidence ceiling typed at :jvm_hermetic (validate raises above it), only bounded-bridge-app-info carries JVM hermetic proof, boundary sentence single-sourced via android_boundary/0; native_shell.md is a pinned hand-written exemption; AND-01 stays open until the ledger (Plan 07)
- [Phase 198]: Plan 07: ParityLedger reads both corpus locations at run time, computes the Android cell from reference checks plus a two-sided consumer registry (registry entries carry an executes scope), and ships as a third docs.sync projection with a tamper control; AND-01 floor met locally, wording amendment (Plan 08) and CI evidence (Plan 12) still owed
- [Phase 198]: Plan 08: Android ceiling test derives its allowed set from the typed ceiling; prose backstop patterns measured at 0 unsuppressed hits after rewording 3 source lines; phase 170 collection ledger regenerated (290 sites) after Phase 198 test edits; AND-01 corpus wording amended on the record (D-01)
- [Phase 198]: Plan 09: foreign-host proof picks the highest version on both Maven Central and Hex, proves non-vacuity three ways (host probe, runtime-jar code source, AAR sha256), and stops at the first failing leg; AND-03 stays open until Linux CI evidence (Plans 11/12)
- [Phase 198]: Plan 10: promotion readiness is derived from CI history plus evidence content and the current script blob; each gh read is attempted twice (GitHub 502s), a double failure is UNVERIFIED never zero; AND-03 stays open until Linux CI evidence (Plans 11/12)
- [Phase 198]: Plan 11: advisory android-foreign-host job outside required authority via ADVISORY_JOBS loop; cache key carries runner.os and arch (Phase 153.1 contract); sibling test avoids refute Enum.any? so the Phase 170 ledger and absence baseline are unchanged; AND-03 stays open until Linux CI evidence (Plan 12)
- [Phase 198]: Plan 12: PR 270 green 39/39 on final head 9b96b483 (CI ran on synthetic merge 0747b23f); advisory android-foreign-host job succeeded on Linux, outcome A, D-18 wording confirmed on Gradle 8.7, promotion derived 2/2 eligible=yes but not attempted (D-20); e2e-proof apt stall fixed forward with a bounded install retry, not rerun

### Blockers

The 196-16 halt is superseded (history in 196-EVIDENCE/196-16-halt-1-superseded.md).

Carried concerns from Phase 196 verification (non-blocking):
- [Phase 196] The grammar receipt (`main-grammar.json`, blob e0891db6) is stale on main since PR 265 commit 94d2d788 changed `test/js/ci_secret_masking.test.mjs` (timing bound only; 207/207 pass). The snapshot tools refuse at HEAD by design (`stale_measured_blob`, `main_ref_mismatch`); any later re-verification of promotion at HEAD needs a recapture or an amendment.
- [Phase 196] Two candidate runs each failed one child with no observed cause (`example-host-proof`; `root-core-suite` 1 of 2920); the runner keeps only output hashes, so a recurring flake would stay undiagnosed.
- [Phase 196] T-196-37 partial: `gateReady` does not rerun the SPEC-04 prose scan (medium, below block_on). `measure-main.mjs self-test` rewrites the tracked `196-EVIDENCE/measurement-controls.json` on each run. `MUEX-DECISION.md` still says the deferral is proposed; ROADMAP and REQUIREMENTS are authoritative. `196-VALIDATION.md` is still draft (the Nyquist audit was not completed).
- 197-14 blocked at CI: PR 268 red on proof-dependency-security (new advisories phoenix_html 4.3.0, ecto 3.13.6; needs mix.lock bumps outside the plan's fix targets) and e2e-proof (apt timeout, rerun). See 197-14-BLOCKED.md
