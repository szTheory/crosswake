---
phase: "196"
slug: "spec-and-structure-ratchet"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-27"
---

# Phase 196 — Validation Strategy

Planning contract only. No implementation, repaired baseline or full mutation pilot is claimed.

## Test Infrastructure

| Property | Value |
|---|---|
| Framework | Existing ExUnit, Node test runner, Swift Testing/XCTest and Kotlin JVM tests |
| Config | mix.exs, test/test_helper.exs, .github/workflows/crosswake-ci.yml |
| Quick behavioral command | `mix test test/crosswake/offline/journal_test.exs test/crosswake/offline/safe_observation_test.exs test/crosswake/policy/compiler_test.exs test/crosswake/policy/route_test.exs test/crosswake/bridge/bridge_behavioral_vector_test.exs` |
| Quick grammar command | `node --test --test-name-pattern='live workflow tree|derivedSecretViolations|derived chains|live fire-drill' test/js/ci_secret_masking.test.mjs` |
| Full root and companion suite | `mix verify` |
| Full Node suite | `node --test test/js/*.mjs` |
| Native suites | `swift test --package-path packages/crosswake-shell-core-ios`; Android `./gradlew testDebugUnitTest` from package cwd with explicit JDK |
| Formatting | `mix format --check-formatted` plus explicit changed scripts/companion Elixir files |
| Focused feedback target | Under 30 seconds warm for focused controls; new scoped wrapper checks have a 20-second deadline. Actual quick and integration runtimes remain unmeasured until execution. |

## Sampling Rate

Run the relevant focused suite and its negative controls after each task change and before each task commit. Per wave run complete changed-language suites and touched bridge/compiler tests. Before phase verification run root/companion, Node and changed native suites, generated-manifest proof, fresh compilation and real xref gates. Run checks once at the appropriate scope; broaden only for changed behavior or unresolved failures. Do not replace timed-out integrations with static checks.

For the longer vector/pilot/aggregate tasks, run the task-specific fast companion below first on ordinary edits, then its unchanged full acceptance command before accepting the task. Each companion is produced in the existing wrapper by its named task, uses only Node built-ins with a 20-second deadline and measures its own runtime at execution. These isolated behavior/process/adapter checks invoke no native build or Muex, mutate no canonical source and write no accepted proof receipt. They do not establish native behavior, useful-mutant coverage, measured appetite or CI success. Every real clean resource rebuild/control, five-file pilot and complete candidate/landed proof remains required; the pilot's aggregate 1800-second/20% limits are unchanged.

Measure each new recurring guard against an identified actual-main commit before required integration. Preserve findings, semantic baselines and red controls. Existing required CI remains authoritative; report/advisory lanes do not become required automatically. Muex is one-time local evidence.

## Per-Task Verification Map

Final plan map: 17 sequential waves, 40 tasks, one main checkout. The first table preserves all 40 required acceptance commands; the companion table adds 16 bounded per-edit checks in those same tasks. Every command assumes repository root; long native/pilot/aggregate commands yield progress while running and retain actual runtime. New command owners and fixtures are created in their producing task before invocation; all remain pending execution. Source audit and shared safe-source/privacy/promotion rules are in 196-01-PLAN.md.

| Task | Wave | Requirement | Exact automated command | Threat refs | Evidence status |
|---|---|---|---|---|---|
| 196-01-01 | 1 | SPEC-01, SPEC-02, ARCH-01, ARCH-02, ARCH-03 | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/measure-main.mjs verify-source` | T-196-01, T-196-02 | Pending execution |
| 196-01-02 | 1 | SPEC-01, SPEC-02, ARCH-01, ARCH-02, ARCH-03 | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/measure-main.mjs self-test` | T-196-01, T-196-02 | Pending execution |
| 196-02-01 | 2 | SPEC-01 | `mix test test/crosswake/guides/evidence_manifest_test.exs` | T-196-03, T-196-04 | Pending execution |
| 196-02-02 | 2 | SPEC-01 | `mix cmd --cd packages/crosswake_threadline mix test test/crosswake/proof/phase139_threadline_cleanroom_test.exs` | T-196-03, T-196-04 | Pending execution |
| 196-03-01 | 3 | SPEC-01 | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/vector-controls.mjs elixir` | T-196-05, T-196-06 | Pending execution |
| 196-03-02 | 3 | SPEC-01 | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/vector-controls.mjs swift-request` | T-196-05, T-196-06 | Pending execution |
| 196-04-01 | 4 | SPEC-01 | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/vector-controls.mjs swift-reply` | T-196-07, T-196-08 | Pending execution |
| 196-04-02 | 4 | SPEC-01 | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/vector-controls.mjs swift-metadata` | T-196-07, T-196-08 | Pending execution |
| 196-04-03 | 4 | SPEC-01 | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/vector-controls.mjs swift-topology` | T-196-07, T-196-08 | Pending execution |
| 196-05-01 | 5 | SPEC-01 | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/vector-controls.mjs kotlin-request` | T-196-09, T-196-10 | Pending execution |
| 196-05-02 | 5 | SPEC-01 | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/vector-controls.mjs kotlin-other` | T-196-09, T-196-10 | Pending execution |
| 196-06-01 | 6 | SPEC-02 | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/measure-main.mjs capture --guard absence --candidate HEAD --output .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/main-absence.json` | T-196-11, T-196-12 | Pending execution |
| 196-06-02 | 6 | SPEC-02 | `elixir script/check_absence_is_not_success.exs --collections-mode enforce` | T-196-11, T-196-12 | Pending execution |
| 196-06-03 | 6 | SPEC-02 | `mix test test/crosswake/proof/absence_is_not_success_test.exs` | T-196-11, T-196-12 | Pending execution |
| 196-07-01 | 7 | SPEC-03 | `mix test test/crosswake/offline/journal_test.exs` | T-196-13, T-196-14 | Pending execution |
| 196-07-02 | 7 | SPEC-03 | `mix test test/crosswake/offline/safe_observation_test.exs` | T-196-13, T-196-14 | Pending execution |
| 196-08-01 | 8 | SPEC-05 | `mix test test/crosswake/policy/compiler_test.exs` | T-196-15, T-196-16 | Pending execution |
| 196-08-02 | 8 | SPEC-05 | `mix test test/crosswake/policy/finite_product_test.exs test/crosswake/policy/route_test.exs` | T-196-15, T-196-16 | Pending execution |
| 196-08-03 | 8 | SPEC-05 | `mix test test/crosswake/policy/finite_product_test.exs test/crosswake/policy/compiler_test.exs test/crosswake/policy/route_test.exs` | T-196-15, T-196-16 | Pending execution |
| 196-09-01 | 9 | ARCH-01 | `MIX_ENV=test mix compile --force --warnings-as-errors && MIX_ENV=test mix xref graph --format cycles --label compile-connected --fail-above 0` | T-196-17, T-196-18 | Pending execution |
| 196-09-02 | 9 | ARCH-01 | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/measure-main.mjs capture --guard compile --candidate HEAD --output .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/main-compile.json` | T-196-17, T-196-18 | Pending execution |
| 196-09-03 | 9 | ARCH-01 | `mix test test/crosswake/proof/compile_structure_ratchet_test.exs` | T-196-17, T-196-18 | Pending execution |
| 196-10-01 | 10 | ARCH-02 | `mix test test/crosswake/bridge/location_diagnostics_test.exs test/crosswake/router_test.exs` | T-196-19, T-196-20 | Pending execution |
| 196-10-02 | 10 | ARCH-02 | `mix test test/crosswake/compatibility/compatibility_test.exs` | T-196-19, T-196-20 | Pending execution |
| 196-10-03 | 10 | ARCH-02 | `mix test test/crosswake/proof/rescue_boundary_ratchet_test.exs` | T-196-19, T-196-20 | Pending execution |
| 196-11-01 | 11 | ARCH-03 | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/measure-main.mjs capture --guard dependencies --candidate HEAD --output .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/main-dependencies.json` | T-196-21, T-196-22 | Pending execution |
| 196-11-02 | 11 | ARCH-03 | `mix test test/crosswake/proof/runtime_dependency_ratchet_test.exs` | T-196-21, T-196-22 | Pending execution |
| 196-12-01 | 12 | SPEC-02 + GR-06 | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/measure-main.mjs capture --guard grammar --candidate HEAD --output .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/main-grammar.json` | T-196-23, T-196-24 | Pending execution |
| 196-12-02 | 12 | SPEC-02 + GR-06 | `node --test test/js/ci_secret_masking.test.mjs` | T-196-23, T-196-24 | Pending execution |
| 196-13-01 | 13 | SPEC-04 | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/muex-pilot.mjs bootstrap` | T-196-25, T-196-26 | Pending execution |
| 196-13-02 | 13 | SPEC-04 | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/muex-pilot.mjs controls` | T-196-25, T-196-26 | Pending execution |
| 196-14-01 | 14 | SPEC-04 | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/muex-pilot.mjs baseline` | T-196-27, T-196-28 | Pending execution |
| 196-14-02 | 14 | SPEC-04 | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/muex-pilot.mjs decision` | T-196-27, T-196-28 | Pending execution |
| 196-15-01 | 15 | SPEC-01, SPEC-02, SPEC-03, SPEC-04, SPEC-05, ARCH-01, ARCH-02, ARCH-03 | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/phase-evidence.mjs self-test` | T-196-29, T-196-30 | Pending execution |
| 196-15-02 | 15 | SPEC-01, SPEC-02, SPEC-03, SPEC-04, SPEC-05, ARCH-01, ARCH-02, ARCH-03 | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/phase-evidence.mjs candidate` | T-196-29, T-196-30 | Pending execution |
| 196-16-01 | 16 | SPEC-01, SPEC-02, SPEC-03, SPEC-04, SPEC-05, ARCH-01, ARCH-02, ARCH-03 | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/phase-evidence.mjs gate --stage pr-open` | T-196-31, T-196-32 | Pending execution |
| 196-16-02 | 16 | SPEC-01, SPEC-02, SPEC-03, SPEC-04, SPEC-05, ARCH-01, ARCH-02, ARCH-03 | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/phase-evidence.mjs gate --stage ready` | T-196-31, T-196-32 | Pending execution |
| 196-17-01 | 17 | SPEC-01, SPEC-02, SPEC-03, SPEC-04, SPEC-05, ARCH-01, ARCH-02, ARCH-03 | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/phase-evidence.mjs gate --stage merge` | T-196-33, T-196-34 | Pending execution |
| 196-17-02 | 17 | SPEC-01, SPEC-02, SPEC-03, SPEC-04, SPEC-05, ARCH-01, ARCH-02, ARCH-03 | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/phase-evidence.mjs gate --stage approval-binding` | T-196-33, T-196-34 | Pending execution |
| 196-17-03 | 17 | SPEC-01, SPEC-02, SPEC-03, SPEC-04, SPEC-05, ARCH-01, ARCH-02, ARCH-03 | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/phase-evidence.mjs landed` | T-196-33, T-196-34 | Pending execution |

### Fast Companion Map — Run Before Required Acceptance

All entries are pending implementation/execution. Each new command's `<automated>` is immediately followed by its concrete `<fails_when>` in the task. Producer paths are the existing phase-owned vector-controls.mjs, muex-pilot.mjs and phase-evidence.mjs wrappers, with no new framework, dependency or plan. Real output is required before report fixtures: quick bootstrap tests only protocol/process construction; later Muex adapter checks use Task196-13-02's genuine captured fixture. A single-file fixture must fail the full five-file coverage predicate. Fast results are never promoted to full acceptance results.

| Task | Producing task / focused behavior | Exact fast automated command | Fails when |
|---|---|---|---|
| 196-03-01 | Same task creates dispatcher and Elixir 15/9 resource/command-plan checks; real tiny-child failure and synthetic-byte restoration | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/vector-controls.mjs quick elixir` | Wrong mode/counts or empty input accepted; child failure swallowed; restoration fails; deadline exceeded |
| 196-03-02 | Same task extends dispatcher for Swift request15/14, real owner/filter/resource and clean-rebuild plan | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/vector-controls.mjs quick swift-request` | Wrong eligibility/reader plan accepted; rebuild omitted; child/cleanup failure or deadline exceeded |
| 196-04-01 | Same task adds reply2/2 selection and rebuilt-suite plan | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/vector-controls.mjs quick swift-reply` | Missing/empty/suppressed reply selection accepted; wrong plan or child/cleanup/deadline failure |
| 196-04-02 | Same task adds all three metadata owners' loaded15 and reader-kind plans | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/vector-controls.mjs quick swift-metadata` | Owner omitted; wrong loaded count/kind accepted; rebuild or child/cleanup/deadline failure |
| 196-04-03 | Same task adds topology loaded5/selected1 and absent/duplicate-ID refusal | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/vector-controls.mjs quick swift-topology` | Wrong selection or absent/duplicate ID accepted; wrong rebuild plan or child/cleanup/deadline failure |
| 196-05-01 | Same task adds Kotlin15/14 and explicit JDK/cwd/test/clean-build plan | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/vector-controls.mjs quick kotlin-request` | Wrong eligibility/empty input or command plan accepted; child/cleanup/deadline failure |
| 196-05-02 | Same task adds reply2/2 and metadata loaded15 with distinct reader kinds | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/vector-controls.mjs quick kotlin-other` | Reader omitted; wrong selection/kind or native command plan accepted; child/cleanup/deadline failure |
| 196-13-01 | Same task creates quick bootstrap: five-target/flag/pin/homes/fresh-path construction, injected clock, actual tiny-child exit/timeout/cleanup | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/muex-pilot.mjs quick bootstrap` | Changed protocol accepted; reused path/budget overflow or child failure ignored; cleanup fails; Muex invoked or deadline exceeded |
| 196-13-02 | Same task adds real-fixture schema adapter and deliberately corrupted copies after genuine capture | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/muex-pilot.mjs quick controls` | Fixture provenance absent; invalid copy accepted; categories collapse; child/cleanup fails; Muex invoked or deadline exceeded |
| 196-14-01 | Same task adds frozen full-selection/terminal-budget checks and scoped real-fixture replay with explicit full-coverage refusal | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/muex-pilot.mjs quick baseline` | Changed flags/budget or terminal reuse accepted; bootstrap credited as full baseline; corrupt report accepted; Muex invoked or deadline exceeded |
| 196-14-02 | Same task adds arithmetic 1800s/20% boundary cases and genuine-record survivor identity/normalization checks | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/muex-pilot.mjs quick decision` | Wrong appetite boundary; zero denominator/incomplete/unclassified/timeout accepted as completion; identity lost; Muex invoked or deadline exceeded |
| 196-15-01 | Same task produces all scoped self-tests; promotion validates final-hash/measurement and early-wiring refusal | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/phase-evidence.mjs self-test --scope promotion` | Stale/missing measurement or premature wiring accepted; child/cleanup fails; evidence written/full integration runs/deadline exceeded |
| 196-15-02 | 196-15-01 produces candidate scope; same task updates final suite/target/control registry and process adapter | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/phase-evidence.mjs self-test --scope candidate` | Missing lane/target/control, stale source or zero/failed child accepted; candidate receipt written/aggregate launched/deadline exceeded |
| 196-17-01 | 196-15-01 produces merge scope; same task finalizes isolated stale-identity/one-use/deletion refusals before approval | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/phase-evidence.mjs self-test --scope merge` | Stale identity/changed or consumed approval/hidden deletion accepted; child failure ignored; write/evidence/deadline violation |
| 196-17-01 | 196-15-01 produces landed scope; same task finishes ancestry/restoration/command-plan controls before approval | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/phase-evidence.mjs self-test --scope landed` | Wrong ancestry/absent approved head/dirty restore/missing proof accepted; merge/full proof/evidence/deadline violation |
| 196-17-03 | Rechecks the already-produced landed scope before consuming the sole preceding approval; no post-approval implementation | `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/phase-evidence.mjs self-test --scope landed` | Invalid ancestry/restore/proof plan accepted; quick check consumes approval/merges/stamps evidence/runs full integration or exceeds deadline |

Task196-17-02 retains its existing approval-binding acceptance check and the single operation-specific decision gate. Task196-17-03 carries rating one-way for the actual shared-history main merge. A fast check cannot grant or reuse approval. These additions alter neither waves nor task count; no runtime has been measured by authoring them.

## Spec-less Edge Coverage

The supplied engine report has 25 items total: 23 classified edges and two unclassified entries. Its coverage.applicable value of 25 includes those two; this map preserves every item. Each classified edge below is resolved in the planning sense by an explicit predicate lifted to the referenced plan's must_haves.truths, with execution still pending. No backstop, dismissal or successful execution is inferred.

| Requirement | Engine category | Explicit acceptance criterion | Plan |
|---|---|---|---|
| SPEC-01 | boundary | Enabled zero/missing route/artifact fails; each real reader loses file/case/all cases and turns red | 02–05 |
| SPEC-01 | precision | Independently pinned integer loaded/completed counts, no self-derived expectation or skipped-as-executed credit | 02–05 |
| SPEC-02 | adjacency | Same text in another context is distinct; duplicate exempt expression increases multiplicity | 06 |
| SPEC-02 | empty | Empty scan/unsafe collection/empty attribute fails; intentional exact-empty assertion remains valid | 06 |
| SPEC-02 | ordering | Reachable prior same-branch proof is required; normalized findings sort deterministically | 06 |
| SPEC-03 | boundary | Scope suffix15/16/128/129 and measurement0/1000000/1000001 discriminate | 07 |
| SPEC-03 | adjacency | Closed atoms/keys remain distinct; matching text in a wrong field has no authority | 07 |
| SPEC-03 | empty | Nil/empty/wrong-shaped boundary inputs reject; legitimate empty measurement map stays valid | 07 |
| SPEC-03 | encoding | Absolute ASCII scope/route grammar rejects LF/CRLF/Unicode lookalikes without normalization widening | 07 |
| SPEC-03 | ordering | Input map/key order does not change validated projections | 07 |
| SPEC-03 | precision | Integer bounds exact; negative/floating/above-limit measurements reject without rounding | 07 |
| SPEC-04 | empty | Missing/zero/invalid-only/useless-target report is incomplete and cannot pass as drop | 13–14 |
| SPEC-04 | encoding | Survivor normalized before/after preserves token/string meaning; missing patch identity rejects | 13–14 |
| SPEC-04 | concurrency | One sequential fresh attempt, monotonic aggregate budget, terminal interruption and verified restoration | 13–14 |
| SPEC-05 | unclassified | Flagged unresolved assumption; explicit108-case/staged/provenance contract requires checker review | 08 |
| ARCH-01 | boundary | Compile threshold0 fails on1; exact repaired all-cycle cap passes and overflow fails | 09 |
| ARCH-01 | adjacency | Pinned Mix handles mixed-label SCC membership without only-direct filtering | 09 |
| ARCH-01 | empty | Missing/malformed/stale manifest and empty/source-incomplete compilation fail | 09 |
| ARCH-01 | encoding | Repository-relative normalized source paths exactly match actual manifest coverage | 09 |
| ARCH-01 | ordering | Source traversal order does not alter coverage or Mix threshold verdict | 09 |
| ARCH-01 | precision | Built-in integer thresholds, no graph text count/rounding/parser substitution | 09 |
| ARCH-02 | unclassified | Flagged unresolved assumption; exact extension authority/custom-error/record criteria require checker review | 10 |
| ARCH-03 | adjacency | Same dependency name with optional/prod/runtime classification drift fails | 11 |
| ARCH-03 | empty | Missing/extra project, empty declarations or blank purpose fails | 11 |
| ARCH-03 | ordering | Reordered declarations/version/path spellings leave normalized membership unchanged | 11 |

The two unclassified rows stay unresolved and flagged; they are never auto-dismissed. The explicit criteria make implementation deterministic without claiming the engine classified them.

## Prohibition Recall

196-01-PLAN.md records the adversarial recall/precision pass and two descriptor-less project-specific prohibitions projected by the installed projectProhibitions serializer. They remain flagged-unverified pending independent phase verification: no device/adopter claim from hermetic native proof, and no completed SPEC-04 from an incomplete pilot relabeled drop. Canon injection/logging/privacy controls are referred to the STRIDE/security pass rather than minted as duplicate generic prohibitions.

## Wave 0 Requirements

- Add controls in each producing task before its implementation; existing test frameworks need no dependency.
- Create lexical/multiset AST fixtures, policy oracle, real mixed-cycle Mix fixtures and exact rescue records.
- Create evaluated dependency baseline with optionality/purposes and both-branch controls.
- Add disposable native-vector mutation/rebuild controls; restore canonical sources and verify restoration.
- Produce the task-specific bounded quick branches above in their existing wrapper owners before invocation; report timing separately from full native/pilot/aggregate evidence.
- Add bounded GR-06 classifier and execution controls in existing Node owner.
- Freeze pilot attempt identity/budget/test selection, then capture nonempty real output for adapters. Isolate MIX_HOME/MIX_ARCHIVES/HEX_HOME; no mix.exs/mix.lock changes.

## Manual-Only Verifications

All phase assertions are automated. Each main merge and any other irreversible action has its own one-use approval gate after concrete proof; approval is not behavioral evidence. No device setup or physical proof is in scope.

## Validation Sign-Off

- [ ] Every final task mapped to an automated command or producing-task prerequisite
- [ ] No three consecutive tasks without automated verification
- [ ] Every new test path has an explicit producing task
- [ ] Every guard has meaningful red controls and measured-main evidence
- [ ] No watch commands or hidden pipeline exit statuses
- [ ] Actual native/pilot runtime and full-target coverage retained at execution

Planning checks: 17 frontmatter schemas and 17 structural plans validated; all 27 decision IDs occur in must-have truths, all eight requirement IDs are covered, and 34 numbered threat IDs are unique. API detector returned detected:false. Assumption-delta detector fired on optional proof wording; plan02 records no-change with explicit attempt identity. No schema-pattern path is in the scoped files. Execution and independent checker verdicts remain pending.

Approval: pending implementation; planning review does not set nyquist_compliant true.
