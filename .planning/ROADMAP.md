# Roadmap: Crosswake

## Overview

Crosswake now moves from a proven v1 substrate to realistic adopter pressure. The next milestone should validate whether the route-policy thesis, bounded shell model, offline contract, pack lifecycle, transfer seams, and support posture still hold when exercised through credible product shapes instead of isolated feature proofs.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Route Policy Foundation** - Phoenix hosts declare per-route runtime ownership and get actionable compile-time validation.
- [x] **Phase 2: Manifest Truth And Compatibility** - Crosswake compiles route policy into a versioned contract with diagnostics and explicit support boundaries.
- [x] **Phase 3: Native Shell Boot And Bounded Bridge** - iOS and Android shells boot from the manifest, resolve routes, and enforce capability access safely.
- [x] **Phase 4: Honest Offline Contract** - Crosswake proves one real offline island with explicit cache, journal, sync, and telemetry seams.
- [x] **Phase 5: Packs, Native Escape, And Proof Lanes** - Asset-heavy and device-heavy routes work through explicit contracts backed by deterministic install proof.
- [x] **Phase 6: Adopter Profile Matrix And Pressure Contract** - Crosswake defines the exemplar profiles, route classes, proof posture, and non-goals that will pressure the v1 substrate.
- [x] **Phase 7: Phoenix SaaS Portal Exemplar** - Crosswake proves a server-centric, authenticated product shape that stays mostly LiveView while exercising bounded mobile affordances.
- [ ] **Phase 8: Selective Native Flow Exemplar** - Crosswake proves a mixed-ownership product shape where a narrow device-heavy or entitlement-adjacent route moves into explicit native ownership.
- [ ] **Phase 9: Local-First Content Flow Exemplar** - Crosswake proves a realistic local-first product shape that depends on the existing offline, cache, and reconciliation contract.
- [ ] **Phase 10: Cross-Profile Hardening, Proof, And Guidance** - Crosswake closes the gaps exposed by the exemplars and turns the resulting support posture into public product truth.

## Phase Details

### Phase 1: Route Policy Foundation
**Goal**: Phoenix developers can declare explicit runtime ownership and route constraints without ambiguity.
**Depends on**: Nothing (first phase)
**Requirements**: ROUTE-01, ROUTE-02, ROUTE-03, ROUTE-04, DX-01
**Success Criteria** (what must be TRUE):
  1. Phoenix developers can label each route as LiveView, offline island, native screen, or adapter in Crosswake policy.
  2. Phoenix developers can declare offline mode, required capabilities, pack dependencies, sync resources, and security sensitivity per route.
  3. Invalid or internally inconsistent route policy fails at compile time with error messages that identify the conflicting declaration.
  4. Developers can bootstrap a host Phoenix app and native shell workspace with generators/installers that make ownership boundaries explicit.
**Clarification**: Public Phase 1 runtime taxonomy is `:live_view`, `:offline_island`, and `:native_screen`. `adapter` remains reserved for future extension, so Phase 1 plans compensate for the older success-criteria wording through explicit diagnostics and documentation instead of exposing `adapter` as a public runtime.
**Plans**: 4 plans

Plans:
- [x] 01-01-PLAN.md - Establish the core policy contracts, typed schemas, and normalization defaults.
- [x] 01-02-PLAN.md - Add router-adjacent DSL, scope defaults, and route metadata attachment.
- [x] 01-03-PLAN.md - Enforce compile-time validation, aggregated diagnostics, and incremental-adoption warnings.
- [x] 01-04-PLAN.md - Ship additive installers and native shell generators with explicit ownership boundaries.

### Phase 2: Manifest Truth And Compatibility
**Goal**: Crosswake produces a versioned runtime contract that hosts and adopters can trust before shipping artifacts.
**Depends on**: Phase 1
**Requirements**: MANI-01, MANI-02, MANI-04, DX-02, DX-04
**Success Criteria** (what must be TRUE):
  1. Crosswake compiles declared route policy into a versioned runtime manifest consumable by Phoenix hosts and native shells.
  2. Manifest schema, compatibility versions, and support-matrix rules are validated before release artifacts are produced.
  3. Developers can run doctor/diagnostics tooling that surfaces setup, compatibility, capability, and route-policy problems in one report.
  4. Adopters can read documentation and a support matrix that clearly state supported baselines, runtime modes, prerequisites, non-goals, and rough edges.
**Plans**: 4 plans

Plans:
- [x] 02-01-PLAN.md - Define the typed compatibility and support-matrix contract that all Phase 2 surfaces share.
- [x] 02-02-PLAN.md - Compile and validate the single canonical route-first manifest artifact.
- [x] 02-03-PLAN.md - Ship the host-truth-first doctor engine and Mix task surface.
- [x] 02-04-PLAN.md - Render and wire the adopter-facing compatibility and support documentation from canonical truth.

### Phase 3: Native Shell Boot And Bounded Bridge
**Goal**: Mobile shells can boot from the manifest, open routes in the declared runtime, and fail closed on unsafe capability use.
**Depends on**: Phase 2
**Requirements**: SHELL-01, SHELL-02, SHELL-03, MANI-03, BRDG-01, BRDG-02, BRDG-03
**Success Criteria** (what must be TRUE):
  1. The iOS shell can boot from a Crosswake manifest, resolve route ownership, and host LiveView routes inside a bounded WebKit container.
  2. The Android shell can boot from a Crosswake manifest, resolve route ownership, and host LiveView routes inside a bounded WebView container.
  3. Deep links and app-entry handoff open the runtime declared by route policy instead of falling back to a generic container.
  4. Bridge calls execute only through the typed request/reply contract for capabilities that are declared, allowlisted, active-route valid, and compatibility-safe.
**Plans**: 6 plans
**UI hint**: yes

Plans:
- [x] 03-01-PLAN.md - Normalize app entry into manifest-first activation requests and shared denial contracts.
- [x] 03-02-PLAN.md - Upgrade shell generation to real host-owned Android baseline assets and canonical shell fixtures.
- [x] 03-03-PLAN.md - Ship the iOS shell boot path, denial UI, Xcode baseline, and WebKit proof hook.
- [x] 03-04-PLAN.md - Ship the Android shell boot path, denial UI, Gradle baseline, and WebView proof hook.
- [x] 03-05-PLAN.md - Add the bounded typed bridge, manifest-backed capability registry, and platform bridge channels.
- [x] 03-06-PLAN.md - Wire shell and bridge proof into doctor output and adopter-facing native shell guidance.

### Phase 4: Honest Offline Contract
**Goal**: Crosswake proves one credible local-first route class with explicit cache, mutation, reconciliation, and failure visibility.
**Depends on**: Phase 3
**Requirements**: OFFL-01, OFFL-02, OFFL-03, OFFL-04
**Success Criteria** (what must be TRUE):
  1. A LiveView-backed route can run as cached read-only with explicit staleness policy and cache restrictions.
  2. One offline island can complete its intended workflow without LiveView round-trips while offline.
  3. Offline mutations persist as local drafts or journal/outbox entries and expose explicit reconciliation hooks before server-authoritative commit.
  4. Developers and operators can inspect telemetry or diagnostics for offline replay, sync, and reconciliation failures.
**Plans**: 4 plans

Plans:
- [x] 04-01-PLAN.md - Extend route policy and manifest truth with explicit cached-route and offline-island subcontracts.
- [x] 04-02-PLAN.md - Wire the study-session exemplar through SQLite-backed local persistence, journal/replay, and generated shell runtime seams.
- [x] 04-03-PLAN.md - Add route-local offline status vocabulary, telemetry contract, and doctor/report surfaces.
- [x] 04-04-PLAN.md - Publish proof-oriented offline guidance and a hermetic offline proof lane while broader shell-runtime proof remains verification-required.

### Phase 5: Packs, Native Escape, And Proof Lanes
**Goal**: Crosswake supports asset-heavy and device-heavy flows through explicit pack and transfer contracts backed by deterministic install proof.
**Depends on**: Phase 4
**Requirements**: PACK-01, PACK-02, PACK-03, PACK-04, DX-03
**Success Criteria** (what must be TRUE):
  1. Routes can declare versioned content packs or media packs, and the runtime can install them, check availability, and invalidate them through a defined lifecycle.
  2. One documented native screen or adapter can own a device-heavy flow such as camera or media capture without relying on generic WebView behavior.
  3. Upload, download, and media transfer flows use explicit Crosswake seams rather than ad hoc container behavior.
  4. Example hosts and deterministic CI verify the documented public install path across Phoenix, iOS, and Android surfaces.
**Clarification**: Phase 5 implements the first device-heavy escape hatch as one `:native_screen` media-capture flow. `:adapter` remains deferred.
**Plans**: 10 plans
**UI hint**: yes

Plans:
- [x] 05-01-PLAN.md - Establish manifest-owned pack registry and route-policy pack truth.
- [x] 05-02-PLAN.md - Add typed pack lifecycle, inventory, and fail-closed compatibility/activation gating.
- [x] 05-03-PLAN.md - Generate iOS and Android required-pack runtime surfaces from the shared lifecycle contract.
- [x] 05-04-PLAN.md - Define explicit upload/download/import/export route and manifest truth.
- [x] 05-05-PLAN.md - Bound the bridge allowlist to explicit manifest-backed transfer commands.
- [x] 05-06-PLAN.md - Ship one media-capture `:native_screen` escape hatch in generated iOS and Android shells.
- [x] 05-07-PLAN.md - Wire explicit transfer command execution and native-capture handoff into generated shells.
- [x] 05-08-PLAN.md - Land passing example-host and generated-host proof lanes with deterministic CI.
- [x] 05-09-PLAN.md - Publish canonical doctor and support-matrix truth from the passing proof posture.
- [x] 05-10-PLAN.md - Refresh adopter guides from the final proof-backed Phase 5 contract.

### Phase 6: Adopter Profile Matrix And Pressure Contract
**Goal**: Crosswake defines the adopter-shaped exemplar matrix and the exact support posture each profile is meant to pressure.
**Depends on**: Phase 5
**Requirements**: PROF-01, PROF-02
**Success Criteria** (what must be TRUE):
  1. Crosswake publishes a three-profile matrix covering Phoenix-backed SaaS portal, selective-native mobile flow, and local-first study or content flow.
  2. Each profile maps to explicit route classes, runtime ownership expectations, required seams, and milestone non-goals.
  3. Example-host or exemplar ownership is chosen deliberately so the milestone pressures the product without drifting into starter-app scope.
  4. Contributors can see which parts of the current support posture each later exemplar phase is expected to validate or challenge.
**Plans**: 2 plans

Plans:
- [x] 06-01-PLAN.md - Publish the adopter-profile matrix, public pressure guide, and profile-fit cross-links.
- [x] 06-02-PLAN.md - Lock the shared example-host lane contract and profile-proof scaffold for later exemplar phases.

### Phase 7: Phoenix SaaS Portal Exemplar
**Goal**: Crosswake proves a realistic server-centric product shape that mostly stays LiveView-owned inside the mobile shells.
**Depends on**: Phase 6
**Requirements**: SAAS-01, SAAS-02
**Success Criteria** (what must be TRUE):
  1. A checked-in exemplar route set exercises authenticated or account-style product flows without collapsing into a generic native wrapper.
  2. The SaaS exemplar uses at least one bounded native affordance through declared Crosswake seams instead of app-local shell hacks.
  3. Docs and proof artifacts state which SaaS-profile boundaries are supported, degraded, or intentionally deferred.
**Plans**: 3 plans

Plans:
- [x] 07-01-PLAN.md - Establish the authenticated `/saas` lane, host-owned auth boundary, and minimal fixture scaffolding inside the shared example host.
- [x] 07-02-PLAN.md - Implement the approvals-led LiveView flow, bounded haptics seam, and checked-in shell-fixture proof alignment.
- [x] 07-03-PLAN.md - Publish SaaS boundary guidance and extend the checked-in proof posture through the shared host entrypoints.

### Phase 8: Selective Native Flow Exemplar
**Goal**: Crosswake proves a mixed-ownership product shape where one narrow flow becomes explicitly native without distorting surrounding Phoenix routes.
**Depends on**: Phase 7
**Requirements**: NATIVE-01, NATIVE-02
**Success Criteria** (what must be TRUE):
  1. A realistic exemplar flow moves one device-heavy or entitlement-adjacent route into `:native_screen` ownership while surrounding routes remain manifest-driven Phoenix routes.
  2. The exemplar uses declared pack, transfer, and capability seams rather than fallback container behaviors or generic bridge authority.
  3. Any contract gaps exposed by the exemplar are made explicit and bounded instead of widened into a capability wishlist.
**Plans**: 0 plans

### Phase 9: Local-First Content Flow Exemplar
**Goal**: Crosswake proves a realistic local-first product shape using the existing offline island and cached-route posture.
**Depends on**: Phase 8
**Requirements**: LOCAL-01, LOCAL-02
**Success Criteria** (what must be TRUE):
  1. A local-first exemplar can complete meaningful offline work through Crosswake's journal, outbox, and reconciliation contract.
  2. The exemplar also exercises cached read-only degradation and explicit replay outcomes in a way adopters can understand and verify.
  3. The local-first story stays honest about what is local-first, what is cached-only, and what still requires server authority.
**Plans**: 0 plans

### Phase 10: Cross-Profile Hardening, Proof, And Guidance
**Goal**: Crosswake hardens the core and support posture based on the pressure revealed by the three exemplar profiles.
**Depends on**: Phase 9
**Requirements**: HARD-01, HARD-02, HARD-03
**Success Criteria** (what must be TRUE):
  1. The exemplar flows run without app-local shell forks, undocumented bridge behavior, or drift into a generic plugin architecture.
  2. Deterministic proof lanes validate the declared support posture for each exemplar profile across docs, host code, and runtime hooks.
  3. Guides, diagnostics, and support truth clearly separate first-class profile support from rough edges and future capability expansion.
**Plans**: 0 plans

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Route Policy Foundation | 4/4 | Complete | 2026-05-13 |
| 2. Manifest Truth And Compatibility | 4/4 | Complete | 2026-05-14 |
| 3. Native Shell Boot And Bounded Bridge | 6/6 | Complete | 2026-05-17 |
| 4. Honest Offline Contract | 4/4 | Complete | 2026-05-16 |
| 5. Packs, Native Escape, And Proof Lanes | 10/10 | Complete | 2026-05-17 |
| 6. Adopter Profile Matrix And Pressure Contract | 2/2 | Complete | 2026-05-17 |
| 7. Phoenix SaaS Portal Exemplar | 3/3 | Complete | 2026-05-18 |
| 8. Selective Native Flow Exemplar | 0/0 | Planned | - |
| 9. Local-First Content Flow Exemplar | 0/0 | Planned | - |
| 10. Cross-Profile Hardening, Proof, And Guidance | 0/0 | Planned | - |
