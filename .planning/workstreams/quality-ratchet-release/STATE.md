---
gsd_state_version: "1.0"
milestone: v28.0
milestone_name: Truth and Release Train
current_plan: 8
status: executing
stopped_at: Completed 201-07-PLAN.md
last_updated: "2026-11-09T23:28:57.065Z"
state_head: 437307329be7f2f49ff41d94a9410e7461391155
progress:
  total_phases: 8
  completed_phases: 3
  total_plans: 110
  completed_plans: 100
  percent: 38
current_phase: 200
current_phase_name: Fix the exact-public companion digest proof so a release run can complete
last_activity_desc: "Phase 196 verified and complete 2026-10-29: UAT 36/36, security 39/39 closed, verification 5/5, full core suite 2923/0 on main 97ec5f7b; SPEC-04 moved to v29.0"
---

## Current Position

Current Plan: 8
Total Plans in Phase: 8

## Exact Next Action

Last completed phase: 201 (Fix the exact-public companion digest proof). 0.2.14 is released COMPLETE: release run 42713010358 published Hex, Maven and the iOS mirror, both clean-room proofs passed, and the exact-public proof judged all six packages fully_proven under the user's companions-only rule (PD-01, user decision of 2026-11-09: the five companions' digests ignore Hex's `build_env` stamp, the core keeps it, so the core's exact-public digest depends on the Hex version). Phase 200 is complete (9 of 9): 0.2.13 stays recorded as published and FAILURE at the exact-public proof (run 42639651064), superseded by the 0.2.14 run, never re-run; 200-08 and 200-09 were closed by Phase 201 (200-08-BLOCKED.md stays as history). REL-08 and REL-09 are Complete (REL-09 carries the amendment: direction confirmed by the user on 2026-11-09, wording drafted by the planner). REL-07 stays Pending. Phase 199 is still halted at 12 of 19 plans, with plans 13-19 on hold. Standing release approvals are committed (PR 284 merged as 44e2f69b): merges including the release PR, the release-tags step and the Hex, Maven and iOS publishes need no gate; the Maven fire-drill dispatch and remote-branch deletion keep a one-use allow. Reconciled in writing (201-EVIDENCE/reconcile-201.json): runs 42494651844 (0.2.12, PARTIAL) and 42639651064 (0.2.13, FAILURE) each still on attempt 1; issue 281 closed with a scanned comment; PR 280 shipped 0.2.13 and PR 283 shipped 0.2.14; TODO-012 closed as stale; no earlier approval reused.

Open items, each with its owner. (1) REL-07 and Phase 199 SC1 and SC2 carry the `(Annotated 2026-11-09, Phase 201: ...)` note, to be restated by the exact next command (the Phase 199 replanning); the two release runbooks already match the standing rule through PR 284. (2) Threadline 0.1.1 (PR 262) is deferred; reopening condition: a COMPLETE core run (met by 0.2.14) and Phase 199 plans 13-14 revised for current facts; receiver: Phase 199 plans 13-14. (3) Retiring 0.2.12 on Hex is undecided and not recommended; receiver: a new plan with its own one-way gate `hex-retire-0.2.12`. (4) Landing: one human PR from `docs/release-0-2-14-ledger-and-planning` (cut from origin/main, merge oid in 201-EVIDENCE/ledger-pr-201.json) carries the 0.2.13 and 0.2.14 ledger lines and the docs-branch planning record that was not yet on main. The 0.2.14 ledger line was appended by `script/append_release_ledger.sh` because the runner's record-ledger job could not open its own PR while ledger PR 285 (0.2.13) was open; PR 285 was closed with a reason after the landing merge, its branch left. (5) Route B exclusions: 13 retained pre-merge raw sources under 201-EVIDENCE/premerge-201-sources/ (class home_path, a public API URL segment, no local home directory) are left out of the landing; reopening condition: each is redacted in a new commit, or re-dispositioned as not-identifying, and then landed by the next landing PR; owner: the agent running the next command. Because Route B does not merge docs-branch history, the docs-branch commit ids that phase evidence records are not on main (references stay literal). (6) Trailing commits on `docs/199-release-0-2-12` after the landing (ledger-pr-201.json, the 201-08 summary and later metadata) land with the first PR of the next session's work, repeating this route; owner: the agent running the next command. (7) Pre-existing local worktree `~/projects/crosswake-agents-wt` (clean, holding the merged branch `docs/agents-standing-release-approvals`) is left in place for the next milestone-boundary hygiene pass (`docs/MILESTONE-BOUNDARY-HYGIENE.md`) to remove with `git worktree remove` without force. (8) Remote branches remain, and each deletion needs its own allow: `fix/default-ios-generation-builds`, `fix/exact-public-build-env-provenance`, `docs/agents-standing-release-approvals`, `docs/201-planning-record`, `docs/release-0-2-14-ledger-and-planning` and `chore/release-ledger-42639651064` (PR 285's branch); no 0.2.14 bot branch exists. Also open and not touched: release PR 288 (the next release), PR 279, PR 262.

Exact next command: `/gsd-plan-phase 199 --ws quality-ratchet-release`, to revise plans 13-19 for current facts (they name 0.2.12 facts), then `/gsd-execute-phase 199 --ws quality-ratchet-release`. Previous handoff: history/201-08-prior-handoff.md.

## Carried debt

WINDOWS46/47 record missing full coverage and blocked classification/decision;43/44 remain resolved by useful bootstrap/controls. WINDOWS40/41/42/45 and SPEC-05/ARCH-02 review flags remain. Collection default is enforce (recaptured on actual main); the ratchet tests already run in required root-proof, and no new required job exists. Review R-03 defers other trailing-line-end identifier patterns outside the offline boundary. Cleanroom WR-04/05/06 and IN-03 stay with197;adopter lane parked. Commands,hashes and measured actuals live in14-SUMMARY. Source-verifier mismatch resolved at00cc1f3b:exact committed13/14 amendment,original receipt unchanged,50 helper controls and actual verify-source1359 passed;see196-SOURCE-VERIFIER-FOLLOWUP.md. Branch fix/spec-structure-ratchet;no external delivery.

## Session

**Last session:** 2026-11-09T23:28:56.747Z
**Stopped at:** Completed 201-07-PLAN.md
**Resume file:** None

## Accumulated Context

### Roadmap Evolution

- Phase 196 edited: edited fields: requirements, success_criteria — SPEC-04 moved intact to v29.0 (overrun cut order, D-03/D-24); both attempts preserved
- Phase 198 edited: AND-01 and SC1 corpus wording (D-01) and Phase 199 SC6 removal list gains guides/parity_ledger.md (D-08)
- Phase 200 added 2026-11-08: forward fix and release 0.2.13 after Phase 199's 0.2.12 release run ended PARTIAL (iOS clean-room proof failed: default `gen.shell ios` writes a project that references a CrosswakeHostSettings.xcconfig it never writes). Phase 199 plans 13-19 are held until the fix path is settled.
- Phase 201 added 2026-11-09: fix the exact-public companion digest proof so a release run can complete; 0.2.13's run ended FAILURE at that proof after every publish succeeded (see 200-08-BLOCKED.md)
- Phase 201 closed 2026-11-09: 0.2.14 released COMPLETE (run 42713010358); Phase 200 closed with it (200-08 and 200-09 by Phase 201); REL-08 and REL-09 Complete, REL-07 annotated and still Pending

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
| Phase 199 P01 | wall clock 8h 58m incl. user decision wait | 3 tasks | 6 files |
| Phase 199 P02 | 5 min | 3 tasks | 1 files |
| Phase 199 P03 | 10 min | 3 tasks | 7 files |
| Phase 199 P04 | 19 min | 3 tasks | 7 files |
| Phase 199 P05 | 43min | 3 tasks | 10 files |
| Phase 199 P06 | 14 min | 3 tasks | 6 files |
| Phase 199 P07 | about 1h 20m (second session; first stopped on a safety-check denial) | 3 tasks | 7 files |
| Phase 199 P08 | about 40 min of agent work (wall clock spans a 13-hour wait for the user's reply) | 3 tasks | 5 files |
| Phase 199 P09 | about 25 min | 2 tasks | 8 files |
| Phase 199 P10 | about 10 h wall clock (9.5 h waiting for the reply) | 3 tasks | 3 files |
| Phase 199 P11 | about 40 min | 3 tasks | 3 files |
| Phase 199 P12 | about 55 min (49 min waiting for the reply) | 3 tasks | 4 files |
| Phase 200 P01 | 35 min | 2 tasks | 5 files |
| Phase 200 P02 | about 20 min | 3 tasks | 5 files |
| Phase 200 P03 | about 20 min | 3 tasks | 2 files |
| Phase 200 P04 | 70 min | 3 tasks | 6 files |
| Phase 200 P05 | about 10 min | 3 tasks | 31 files |
| Phase 200 P06 | about 37 min wall clock (waiting on user replies) | 3 tasks | 3 files |
| Phase 201 P01 | 30min | 2 tasks | 12 files |
| Phase 201 P02 | 53 min | 3 tasks | 6 files |
| Phase 201 P03 | about 35 min | 3 tasks | 3 files |
| Phase 201 P04 | 32 min | 3 tasks | 7 files |
| Phase 201 P05 | 45min | 3 tasks | 8 files |
| Phase 201 P06 | 17 min | 3 tasks | 38 files |
| Phase 201 P07 | 57 min | 3 tasks | 6 files |

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
- [Phase 199]: D-01 to D-05, D-07, D-08 recommended package chosen by the user (2026-11-07): four protected environments, Hex then Maven then iOS in the core run, threadline 0.1.1 included, one allow per tag-creating step, AGENTS.md condensed, Maven fire drill gated as core-maven-drill
- [Phase 199]: D-06 option B: PR 258 is closed with a recorded reason by plan 199-02 Task 3 (user, 2026-11-07)
- [Phase 199]: SC3 evidence command is bash script/check_ios_mirror_release_tag.sh --version V; proven on real 0.2.11 PASS and 0.2.10 newer_mirror_tag
- [Phase 199]: 199-02: PR 252 closed (CI red for real cause: setup-java pin guard); PR 258 closed per D-06 B; PR 253 left open for the user (no CI on head, close denied by permission system)
- [Phase 199]: Anonymous environment reads include protection_rules and required reviewers, so the preflight needs no token; environment reads are cached 60s publicly
- [Phase 199]: 199-04: iOS mirror waits only on publish-android-core (Hex, then Maven, then iOS); scanner pins release.ios.independent_publication and release.approval.linked_graph to the D-01/D-02 wiring
- [Phase 199]: 199-06: companion receipt attestation takes any of the five companions via CANDIDATE_PACKAGE; companion_publish_authorization.sh render|check derives and verifies the companion REL-17 trailer (closed six-reason BLOCKED set, envelope content cross-check), proven on the real guard predicate and loader
- [Phase 199]: 199-07: PR 278 merged (a9c4ff74) after green CI on head 04e8160a (ran on synthetic merge 40e9cbf9); first post-merge Release Please run flowed with hosted env preflight PASS; release-PR-head predicate proven by 19 controls and 11 mutants, PR 236 (0.2.12) and PR 262 (0.1.1) pass it with CI green; privacy scan scoped for five pre-existing email-shaped files by orchestrator decision
- [Phase 199]: 199-08: PR 236 (0.2.12, head efbc7912) rehearsed and receipted: Hex run 42390193460 and iOS run 42390232440 changed nothing; Maven drill run 42450991698 ran once on the user's core-maven-drill allow (dispatched by the orchestrator) and was validated then dropped, POM still 404; attestation run 42451279582 gave a READY FOR APPROVAL receipt, 13 of 13 checks, publication NONE, expires 2026-11-22
- [Phase 199]: 199-09: candidate docs at PR 236 head efbc7912 pass REL-06 against 0.2.11 (four legs, deferred=ios_host); REL-17 pre_merge gate PASS (expected policy digest unchanged since 0.2.11); trailer 'publish successor core 42390193460' rendered and checked, merge command staged with --match-head-commit and not run; raw pre-merge sources carry the maintainer noreply email, flagged for the 199-19 privacy scope
- [Phase 199]: 199-10: precheck treats the guard-run age rule as satisfied by the latest main run on the current main head; merge_oid added to the merge record
- [Phase 199]: 199-11: Hex then Maven published, each under its own allow; run 42494651844 waits at publish-ios-mirror
- [Phase 199]: 199-12: iOS mirror v0.2.12 published and SC3 proven live both ways; run 42494651844 ended PARTIAL (iOS clean-room proof failed), recorded as observed, phase halted, REL-07 Pending
- [Phase 200]: 200-01: default gen.shell ios writes CrosswakeHostSettings.xcconfig once (placeholder dev.crosswake.shell, scaffold-once, host-owned, not managed); regression test red on 0.2.12 then green; --local xcodebuild exit 65 then 0; declared output unchanged (61 tests before and after); the project has 4 base configurations and 6 mentions of the file, not six base configurations
- [Phase 200]: 200-02: pre-release gate script/verify_default_ios_generation_build.sh builds both default iOS forms with an in-run negative control; red on the exact 0.2.12 generator and green on the fix (local 3 s then 13 s, no-flag remote against the public mirror at 0.2.12 4 s then 14 s); blocking step in phase79-ios-proof (local mode only), contract test 16 tests plus CI step pin; fix branch has 3 commits, 7 paths, full suite 3176 ran 0 failures, scanner 106 of 106, nothing pushed
- [Phase 200]: 200-03: fix PR 282 merged to main as merge commit e8d44c6c (parents 1dcdaad8 and CI-green head 3696f38c) under the standing exception; CI run 42554142308 ran on synthetic merge 6e511a9a; hosted gate step 32 s PASS with control detected, phase79-ios-proof 122 s vs 104 s baseline, 174 billable min vs 250, advisory flags recorded; issue 281 commented; remote fix branch left; residual (remote-form compile not in PR CI) accepted knowingly
- [Phase 200]: 200-04: drill uploads disposable 0.2.13-firedrill-<run id>, not 0.2.13; gated dispatch performed by the orchestrator on the user's allow (10 h display-to-reply gap, facts rechecked)
- [Phase 200]: 200-05: candidate docs at PR 280 head 5a6a7521 pass REL-06 against 0.2.12 (four legs, deferred=none, executed=20); no-flag remote form of that head builds against the public mirror 0.2.12 with the control detected; REL-17 pre_merge PASS (policy digest unchanged since 0.2.11); trailer 'publish successor core 42558226150' rendered and checked, merge staged and not run; 23 retained raw sources listed in privacy-carry-200.txt (13 with scanner hits: public API URL path segments and git@github.com)
- [Phase 201]: 201-01: test names are flat (no describe blocks) so failure output reads 'test <prefix>: ...' for the grading awk
- [Phase 201]: 201-02: PR 284 was behind main when its pinned merge was attempted; main was merged into the branch (no rebase or force), CI was waited on again, and the merge was pinned to the new head ccfe93d8. Planning record (PR 286) merged first as 665f0b9b; PR 284 merged as 44e2f69b.
- [Phase 201]: 201-03: companions-only fix landed on the fix branch (user decision 2026-11-09): build_env shape-validated for every package, dropped from the metadata digest only for the five literal companion names, core keeps it (its digest stays Hex-version-sensitive; release plan re-reads the newest Hex before the core merge and publish); real-tarball regression 19 red-to-green then 22 with three provenance tests; six mutations each red on their own controls and restored; release_candidate suite 218 (floor 196 plus 22), hermetic 3198 ran 0 failures, three guards rc 0; nothing pushed
- [Phase 201]: Plan 201-04: the companions-only build_env fix was measured on the real 0.2.13 family (old rule reproduces metadata 1/6; fix gives 6/6 under Hex 2.7.0 and 5 of 5 companions under Hex 2.5.1, core differing by design) and merged to main as PR 287 (merge fdc218f9, CI ran on synthetic merge 76d6415f of head 57024c87).
- [Phase 201]: 201-05: core candidate builder Hex read from the Hex rehearsal run provenance lines (attestation log has none); hex_latest 2.7.0 must be re-read at 201-07 prechecks
- [Phase 201]: 201-06: every privacy-hit retained pre-merge source (13 of 23, all class home_path) is dispositioned exclude-from-landing under the disposition rule; Plan 08 decides the landing scope
- [Phase 201]: 201-07: 0.2.14 shipped under the standing approvals; exact-public proof judged all six packages fully_proven (run 42713010358). Ledger line for 0.2.14 has no bot PR because ledger PR 285 (0.2.13) is still open; Plan 08 must choose the route.
- [Phase 201]: PD-01 (user decision 2026-11-09): `build_env` is shape-validated for every package and excluded from the digest only for the five literal companion names; the core keeps it, so its exact-public digest depends on the Hex version.
- [Phase 201]: PD-02: fixtures are three real Hex tarballs (public and Hex 2.6+ rebuild of rulestead 0.1.1, public core 0.2.13), with `inspect_single!/2` so tests use only real data.
- [Phase 201]: PD-03: red-before-fix evidence captured on the unchanged digest rule; green captured after the fix.
- [Phase 201]: PD-04: measurements M1 to M4 stay in phase evidence, not CI; the exact-public proof stays release-blocking and is not added to the required-check policy.
- [Phase 201]: PD-05: REL-09 amended to name the 0.2.14 run, keeping the original sentence; the user confirmed the direction on 2026-11-09 and the planner drafted the wording.
- [Phase 201]: PD-06: the planning record landed on main by PR first, the rest of the docs branch lands through 201-08; a named, narrowed exception to the one-main-checkout rule (worktrees for the parallel run and for code).
- [Phase 201]: PD-07 (user decision 2026-11-09): PR 284 (standing release approvals) merges before any release step; the Maven fire drill and remote-branch deletion keep their own allow.
- [Phase 201]: PD-08: `artifact-provenance:` stderr line per tarball names the builder Hex version and whether `build_env` was digested; one diagnostic line, no new label taxonomy.
- [Phase 201]: 201-08: 0.2.12 and 0.2.13 reconciled from live reads (both runs still attempt 1, superseded by 0.2.14); issue 281 and TODO-012 closed; REL-08 and REL-09 Complete, REL-07 Pending; Phase 200 9/9 and Phase 201 8/8; the 0.2.14 ledger line was generated by script because ledger PR 285 was still open.

### Blockers

The 196-16 halt is superseded (history in 196-EVIDENCE/196-16-halt-1-superseded.md).

Carried concerns from Phase 196 verification (non-blocking):
- [Phase 196] The grammar receipt (`main-grammar.json`, blob e0891db6) is stale on main since PR 265 commit 94d2d788 changed `test/js/ci_secret_masking.test.mjs` (timing bound only; 207/207 pass). The snapshot tools refuse at HEAD by design (`stale_measured_blob`, `main_ref_mismatch`); any later re-verification of promotion at HEAD needs a recapture or an amendment.
- [Phase 196] Two candidate runs each failed one child with no observed cause (`example-host-proof`; `root-core-suite` 1 of 2920); the runner keeps only output hashes, so a recurring flake would stay undiagnosed.
- [Phase 196] T-196-37 partial: `gateReady` does not rerun the SPEC-04 prose scan (medium, below block_on). `measure-main.mjs self-test` rewrites the tracked `196-EVIDENCE/measurement-controls.json` on each run. `MUEX-DECISION.md` still says the deferral is proposed; ROADMAP and REQUIREMENTS are authoritative. `196-VALIDATION.md` is still draft (the Nyquist audit was not completed).
- 197-14 blocked at CI: PR 268 red on proof-dependency-security (new advisories phoenix_html 4.3.0, ecto 3.13.6; needs mix.lock bumps outside the plan's fix targets) and e2e-proof (apt timeout, rerun). See 197-14-BLOCKED.md
