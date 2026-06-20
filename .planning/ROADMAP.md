# Roadmap: Crosswake

## Milestones

- ✅ **v8.0 Offline Sync Hardening and UI Polish** — Phases 99-101 (shipped 2026-06-11)
- ✅ **v9.0 Brand System & Visual Identity** — Phases 102-106 (shipped 2026-06-13)
- ✅ **v10.0 Brand Normalization** — Phases 107-109 (shipped 2026-06-14)
- ✅ **v11.0 Release & Distribution Truth** — Phases 110-111 (shipped 2026-06-17)
- ✅ **v12.0 CI Honesty & Real-E2E Sweep** — Phases 112-115 (shipped 2026-06-18)
- ✅ **v13.0 Adopter Confidence & Native Evidence** — Phases 116-120 (shipped 2026-06-19)
- 🚧 **v14.0 Runtime Contract Confidence** — Phases 121-124 (in progress)

## Phases

<details>
<summary>✅ v8.0 Offline Sync Hardening and UI Polish (Phases 99-101) — SHIPPED 2026-06-11</summary>

- [x] Phase 99: Real Network-Toggling E2E Tests (2/2 plans) — completed 2026-06-11
- [x] Phase 100: Storage Budget Enforcement (2/2 plans) — completed 2026-06-11
- [x] Phase 101: Offline UI Consolidation & Polish (2/2 plans) — completed 2026-06-11

Full phase detail archived in `.planning/milestones/v8.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v9.0 Brand System & Visual Identity (Phases 102-106) — SHIPPED 2026-06-13</summary>

- [x] Phase 102: Brand Audit & Token Foundation (4/4 plans) — completed 2026-06-12
- [x] Phase 103: Logo Tournament (4/4 plans) — completed 2026-06-12
- [x] Phase 104: Logo Refinement & Production Suite (3/3 plans) — completed 2026-06-12
- [x] Phase 105: HTML Brand Book (3/3 plans) — completed 2026-06-12
- [x] Phase 106: Collateral, Integration & Closeout (2/2 plans) — completed 2026-06-13

Full phase detail archived in `.planning/milestones/v9.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v10.0 Brand Normalization (Phases 107-109) — SHIPPED 2026-06-14</summary>

- [x] Phase 107: Token Source & Distribution (3/3 plans) — completed 2026-06-13
- [x] Phase 108: Consumer Normalization (4/4 plans) — completed 2026-06-14
- [x] Phase 109: Drift-Prevention Gate (3/3 plans) — completed 2026-06-14

Full phase detail archived in `.planning/milestones/v10.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v11.0 Release & Distribution Truth (Phases 110-111) — SHIPPED 2026-06-17</summary>

- [x] Phase 110: Native Publish & Lockstep Infrastructure (3/3 plans) — completed 2026-06-14
- [x] Phase 111: Generator Rewire, Clean-Room Proof & Release (5/5 plans) — completed 2026-06-17

Full phase detail archived in `.planning/milestones/v11.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v12.0 CI Honesty & Real-E2E Sweep (Phases 112-115) — SHIPPED 2026-06-18</summary>

- [x] Phase 112: Real Offline Outbox Flush (2/2 plans) — completed 2026-06-17
- [x] Phase 113: Honest E2E Rewrite + Compile Gate (3/3 plans) — completed 2026-06-18
- [x] Phase 114: Merge-Blocking CI Gate + Permanent Honesty Guard (5/5 plans) — completed 2026-06-18
- [x] Phase 115: Closeout-Verifier Honesty + Ledger Backlog + Doc Truth (3/3 plans) — completed 2026-06-18

Full phase detail archived in `.planning/milestones/v12.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v13.0 Adopter Confidence & Native Evidence (Phases 116-120) — SHIPPED 2026-06-19</summary>

- [x] Phase 116: Proof Debt And Release Truth (3/3 plans) — completed 2026-06-18
- [x] Phase 117: Route-Policy And Support-Truth Guide Foundation (3/3 plans) — completed 2026-06-19
- [x] Phase 118: Runnable Quick Start And Real Adoption Proof (3/3 plans) — completed 2026-06-19
- [x] Phase 119: Native Evidence Classification (3/3 plans) — completed 2026-06-19
- [x] Phase 120: Collateral, Artifact CI, And Troubleshooting (4/4 plans) — completed 2026-06-19

Full phase detail archived in `.planning/milestones/v13.0-ROADMAP.md`.

</details>

### 🚧 v14.0 Runtime Contract Confidence (In Progress)

**Milestone Goal:** Make the bridge/runtime contract boringly canonical and hard to drift — one source of truth across Elixir, manifest compatibility, generated shells, reusable native packages, examples, proof lanes, and docs — then prove it directly in the native packages rather than only in checked-in example hosts. Coherence work, not feature breadth.

- [x] **Phase 121: Canonical Contract Source** - Collapse protocol-version drift to one Elixir authority; generate all derived surfaces; kill the Kotlin fallback (verified 5/5 after 121-04 gap closure; see 121-VERIFICATION.md) (completed 2026-06-20)
- [x] **Phase 122: Drift Guards** - Merge-blocking parse-based ExUnit drift test, generate-and-diff CI check, and doctor check so canonical source can never silently re-diverge (completed 2026-06-20)
- [x] **Phase 123: Native Package Behavioral Proof** - Six-behavior XCTest and JUnit test suites driven by shared canonical vectors; CI lanes with required-vs-advisory split (completed 2026-06-20)
- [ ] **Phase 124: Compatibility Semantics & Adopter Truth** - Reconcile `>=` floor negotiation across Elixir and native; map rebuild classes; communicate through support matrix, guide, doctor, and changelog

## Phase Details

### Phase 121: Canonical Contract Source

**Goal**: Every version surface in the system derives from one Elixir constant; the 1.1.0 / 1.0.0 divergence is resolved; all generated JSON fixtures, shell templates, and native conformance vectors are emitted by `mix crosswake.contract.gen`; the Kotlin silent fallback is gone.
**Depends on**: Nothing (first phase of this milestone)
**Requirements**: CANON-01, CANON-02, CANON-03, CANON-04, CANON-05
**Success Criteria** (what must be TRUE):

  1. `Crosswake.Bridge.Contract.version()` is the sole declared constant; `Crosswake.Manifest.Types` and shell fixtures derive from it at compile time with no independent literals.
  2. Each of the three version axes (manifest schema, bridge protocol, native runtime) has exactly one named authoritative source; `grep -rn '"bridge_protocol_version"' lib/ test/ packages/ examples/` returns a single value everywhere.
  3. Running `mix crosswake.contract.gen` regenerates all derived surfaces (JSON fixtures, generated shell templates, native conformance vector stubs, docs snippet) from the canonical constant in a hermetic, network-free step.
  4. The 1.1.0 vs 1.0.0 protocol-version conflict is resolved to one correct current value without altering behavior visible to existing 0.1.x adopters.
  5. `ActivationCoordinator.kt` line 594 no longer contains a `?: "1.0.0"` fallback; native always reads the manifest-provided value and fails closed if absent.

**Plans**: 4/4 plans complete

- [x] 121-01-PLAN.md — Single-source the bridge-protocol axis in Manifest.Types + Shell.Fixtures and repair all test drift (CANON-01/02/04)
- [x] 121-02-PLAN.md — `mix crosswake.contract.gen` task + emitted JSON fixtures, vectors, docs snippet, idempotent (CANON-02/03)
- [x] 121-03-PLAN.md — Remove the silent Kotlin `?: "1.0.0"` fallback; native fails closed (CANON-05)
- [x] 121-04-PLAN.md — Gap closure: align both committed crosswake_manifest.json to bridge 1.1.0 (closes SC-2 BLOCKER), fix Map.new comment (WR-01), sync CANON-05 tracking (CANON-02/04/05)

### Phase 122: Drift Guards

**Goal**: Any future hand-edit or generator-skip that re-introduces contract-version divergence is caught immediately by merge-blocking CI before it reaches main; operators can discover drift without reading CI logs.
**Depends on**: Phase 121
**Requirements**: GUARD-01, GUARD-02, GUARD-03, GUARD-04
**Success Criteria** (what must be TRUE):

  1. A pure-Elixir ExUnit drift test (no Xcode, no Gradle) reads each derived surface via a JSON parser — not a text grep — and asserts it equals `Crosswake.Bridge.Contract.version()`; the failure message names the one canonical file to edit and the exact regenerate command.
  2. A CI step runs `mix crosswake.contract.gen && git diff --exit-code` and fails on any difference between generated output and checked-in artifacts; this check runs without any native toolchain.
  3. `mix crosswake.doctor` emits a `contract_version_parity` finding that reports drift to operators alongside the existing `generator_coordinate_parity` check; it is green when all surfaces agree.
  4. The drift checks are registered in the merge-blocking CI aggregator; a registration script is committed that documents the branch-protection PATCH step (matching the v12.0 pattern of script + document, not auto-toggle).

**Plans**: 3/3 plans complete
**Wave 1**

- [x] 122-01-PLAN.md — GUARD-01 parse-based ExUnit drift test over all committed contract surfaces + anti-vacuous synthetic regressions
- [x] 122-02-PLAN.md — GUARD-03 contract_version_parity read-only doctor check (sibling to generator_coordinate_parity) + tests

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 122-03-PLAN.md — GUARD-02 generate-and-diff + GUARD-04 contract-drift-gate.yml (two hermetic jobs + alls-green aggregator) and register-contract-gate.sh

### Phase 123: Native Package Behavioral Proof

**Goal**: The reusable iOS and Android shell-core packages have real behavioral tests for all six key behaviors, all driven from a single committed canonical vector file rather than hardcoded literals, with CI lanes whose required-vs-advisory split matches the project's established hermetic/native split.
**Depends on**: Phase 121
**Requirements**: NTEST-01, NTEST-02, NTEST-03, NTEST-04
**Success Criteria** (what must be TRUE):

  1. A committed `bridge_contract_vectors.json` is the sole source for expected request/outcome pairs in Elixir, Swift, and Kotlin test suites; bumping the version in the canonical source causes test failures in all three suites until the vectors are regenerated.
  2. The `crosswake-shell-core-ios` Swift package has XCTest behavioral tests (no simulator required) covering activation success/failure, bridge denial on version mismatch, capability allowlist enforcement, active-route check, pack-version check, and delegate/escape-hatch behavior — all parametrized from `bridge_contract_vectors.json`.
  3. The `crosswake-shell-core-android` Kotlin package has JVM JUnit behavioral tests (no emulator required) covering the same six behaviors, also parametrized from `bridge_contract_vectors.json`; async assertions use `runTest` not `runBlocking`.
  4. Kotlin JUnit tests run in a merge-blocking CI lane (JVM only); Swift XCTest tests run in an advisory `macos-latest` CI lane; no test hardcodes a version literal — all load fixture JSON derived from the canonical Elixir source.

**Plans**: 3/4 plans executed

**Wave 1**

- [x] 123-01-PLAN.md — Expand gen task to 7 vectors (+session_override) + emit native copies + regenerate + Elixir behavioral vector test + GUARD-01 tripwire (NTEST-01)

**Wave 2** *(parallel siblings; depend on Wave 1 vectors)*

- [x] 123-02-PLAN.md — Replace corrupted iOS test file + Package.swift resources + XCTest bridge & activation conformance suites (NTEST-02)
- [x] 123-03-PLAN.md — Android JVM JUnit bridge & activation conformance suites + conditional kotlinx-coroutines-test (NTEST-03)

**Wave 3** *(depends on the suites existing)*

- [x] 123-04-PLAN.md — native-behavioral-proof-gate.yml (Android blocking + iOS advisory + aggregator) + register-native-gate.sh + human-gated branch-protection registration (NTEST-04)

### Phase 124: Compatibility Semantics & Adopter Truth

**Goal**: The bridge-protocol compatibility check uses `>=` min-version-floor semantics across both Elixir and native, eliminating the exact-equality denial footgun; adopters have a clear decision table mapping each version-axis change to its rebuild requirement; doctor output names the full action sequence when a mismatch is detected.
**Depends on**: Phase 123
**Requirements**: COMPAT-01, COMPAT-02, COMPAT-03, COMPAT-04, COMPAT-05
**Success Criteria** (what must be TRUE):

  1. Native bridge code (`BridgeChannel.swift:182`, `BridgeChannel.kt:101`) now negotiates by `>=` min-version-floor rather than exact string equality, matching `compatible_version?/2`; an additive protocol bump no longer silently denies a valid request from an older native shell.
  2. Each version axis (manifest schema / bridge protocol / native runtime) is mapped to a rebuild class (core-only / compat-bump only / native-rebuild-required) with documented additive-vs-breaking rules in one committed source, guarded by a docs-contract test asserting the table is present.
  3. The support matrix and a `guides/compatibility.md` guide lead with a decision table ("this change type → this rebuild class → this action") before any explanatory prose; the guide is machine-tested via a docs-contract ExUnit test.
  4. Doctor output for a version/rebuild mismatch names the change class, the full action sequence (regenerate shell → rebuild native app → resubmit App Store/Play Store → coordinated deploy), the denial reason from logs, and a link to the compatibility guide.
  5. CHANGELOG entries that touch the bridge/runtime contract carry an upgrade-impact label (e.g., "native rebuild required" or "core-only, no native rebuild") so adopters can triage release notes without reading the full diff.

**Plans**: 3/5 plans executed

Plans:
**Wave 1**

- [x] 124-01-PLAN.md — Native `>=` floor: SemVer ports (iOS+Android), 4 fix sites, fail-closed fallback, floor conformance vectors (COMPAT-01)
- [x] 124-02-PLAN.md — Canonical `rebuild_decision_table/0` + Renderer `## Rebuild Decision Table` section, byte-parity guarded (COMPAT-02)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 124-03-PLAN.md — `guides/compatibility.md` decision-table-first w/ Denial-signal column + `compatibility_test.exs` docs-contract test (COMPAT-03)
- [ ] 124-04-PLAN.md — Doctor advisory `compatibility_rebuild_guidance` check + `action_sequence_for/1` + shared parity detector (COMPAT-04)
- [ ] 124-05-PLAN.md — CHANGELOG `### Upgrade Impact` labels + CONTRIBUTING intent-gate + `release_boundaries_test` asserts (COMPAT-05)

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 99. Real Network-Toggling E2E Tests | v8.0 | 2/2 | Complete | 2026-06-11 |
| 100. Storage Budget Enforcement | v8.0 | 2/2 | Complete | 2026-06-11 |
| 101. Offline UI Consolidation & Polish | v8.0 | 2/2 | Complete | 2026-06-11 |
| 102. Brand Audit & Token Foundation | v9.0 | 4/4 | Complete | 2026-06-12 |
| 103. Logo Tournament | v9.0 | 4/4 | Complete | 2026-06-12 |
| 104. Logo Refinement & Production Suite | v9.0 | 3/3 | Complete | 2026-06-12 |
| 105. HTML Brand Book | v9.0 | 3/3 | Complete | 2026-06-12 |
| 106. Collateral, Integration & Closeout | v9.0 | 2/2 | Complete | 2026-06-13 |
| 107. Token Source & Distribution | v10.0 | 3/3 | Complete | 2026-06-13 |
| 108. Consumer Normalization | v10.0 | 4/4 | Complete | 2026-06-14 |
| 109. Drift-Prevention Gate | v10.0 | 3/3 | Complete | 2026-06-14 |
| 110. Native Publish & Lockstep Infrastructure | v11.0 | 3/3 | Complete | 2026-06-14 |
| 111. Generator Rewire, Clean-Room Proof & Release | v11.0 | 5/5 | Complete | 2026-06-17 |
| 112. Real Offline Outbox Flush | v12.0 | 2/2 | Complete | 2026-06-17 |
| 113. Honest E2E Rewrite + Compile Gate | v12.0 | 3/3 | Complete | 2026-06-18 |
| 114. Merge-Blocking CI Gate + Permanent Honesty Guard | v12.0 | 5/5 | Complete | 2026-06-18 |
| 115. Closeout-Verifier Honesty + Ledger Backlog + Doc Truth | v12.0 | 3/3 | Complete | 2026-06-18 |
| 116. Proof Debt And Release Truth | v13.0 | 3/3 | Complete | 2026-06-18 |
| 117. Route-Policy And Support-Truth Guide Foundation | v13.0 | 3/3 | Complete | 2026-06-19 |
| 118. Runnable Quick Start And Real Adoption Proof | v13.0 | 3/3 | Complete | 2026-06-19 |
| 119. Native Evidence Classification | v13.0 | 3/3 | Complete | 2026-06-19 |
| 120. Collateral, Artifact CI, And Troubleshooting | v13.0 | 4/4 | Complete | 2026-06-19 |
| 121. Canonical Contract Source | v14.0 | 4/4 | Complete    | 2026-06-20 |
| 122. Drift Guards | v14.0 | 3/3 | Complete    | 2026-06-20 |
| 123. Native Package Behavioral Proof | v14.0 | 4/4 | Complete    | 2026-06-20 |
| 124. Compatibility Semantics & Adopter Truth | v14.0 | 3/5 | In Progress|  |
