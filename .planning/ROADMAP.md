# Roadmap: Crosswake

## Overview

Crosswake v1 should move from explicit route truth to proven mobile runtime behavior in five coarse phases: declare runtime ownership in Phoenix, compile it into a trustworthy compatibility contract, boot thin iOS and Android shells around that contract, prove one honest offline workflow, and then add the smallest asset-heavy and device-heavy escape hatches needed to make the substrate credible.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Route Policy Foundation** - Phoenix hosts declare per-route runtime ownership and get actionable compile-time validation.
- [x] **Phase 2: Manifest Truth And Compatibility** - Crosswake compiles route policy into a versioned contract with diagnostics and explicit support boundaries.
- [ ] **Phase 3: Native Shell Boot And Bounded Bridge** - iOS and Android shells boot from the manifest, resolve routes, and enforce capability access safely.
- [x] **Phase 4: Honest Offline Contract** - Crosswake proves one real offline island with explicit cache, journal, sync, and telemetry seams.
- [ ] **Phase 5: Packs, Native Escape, And Proof Lanes** - Asset-heavy and device-heavy routes work through explicit contracts backed by deterministic install proof.

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
- [ ] 03-04-PLAN.md - Ship the Android shell boot path, denial UI, Gradle baseline, and WebView proof hook.
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
**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Route Policy Foundation | 4/4 | Complete | 2026-05-13 |
| 2. Manifest Truth And Compatibility | 4/4 | Complete | 2026-05-14 |
| 3. Native Shell Boot And Bounded Bridge | 5/6 | In progress | - |
| 4. Honest Offline Contract | 4/4 | Complete | 2026-05-16 |
| 5. Packs, Native Escape, And Proof Lanes | 0/TBD | Not started | - |
