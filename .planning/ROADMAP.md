# Roadmap: Crosswake — v5.0 Standalone Publishable Shell Packages

## Phases

- [ ] **Phase 76: Core Shell Extraction & Packaging** - Isolate Crosswake core logic into SPM and Maven libraries
- [x] **Phase 77: Reactive State & API Standardization** - Replace raw object generation with a unified builder and reactive state APIs (completed 2026-06-05)
- [ ] **Phase 78: Automated Host Scaffold Generation** - Update generator tooling to output thin dependency-driven host projects
- [ ] **Phase 79: v5.0 Closeout & Hermetic Verification** - Verify all new libraries and generators are hermetic and break no existing archetype lanes

## Phase Details

### Phase 76: Core Shell Extraction & Packaging
**Goal**: Isolate Crosswake core logic into SPM and Maven libraries without changing internal behavior.
**Depends on**: Nothing
**Requirements**: CORE-01, CORE-02, CORE-03
**Success Criteria** (what must be TRUE):
  1. `crosswake-shell-core` exists as a standalone Swift Package containing iOS `ActivationCoordinator` and `BridgeChannel`.
  2. `crosswake-shell-core` exists as a standalone Maven AAR project containing Android `ActivationCoordinator` and `BridgeChannel`.
  3. The extracted libraries compile independently of any specific host app.
**Plans**: 2 plans
- [ ] 76-01-PLAN.md — Extract iOS SPM Core Library
- [ ] 76-02-PLAN.md — Extract Android Maven Core Library

### Phase 77: Reactive State & API Standardization
**Goal**: Replace raw object generation with a unified builder and reactive state APIs.
**Depends on**: Phase 76
**Requirements**: API-01, API-02, API-03
**Success Criteria** (what must be TRUE):
  1. Developer can initialize the shell via a single `CrosswakeShell.initialize()` entry point.
  2. Host UI can observe shell state (`booting`, `denied`, `live_view`) via `ObservableObject`/`@Published` (iOS) or `StateFlow` (Android).
  3. Host app can inject narrow delegates (e.g., `HapticsDelegate`) instead of implementing a monolithic callback interface.
**Plans**: TBD

### Phase 78: Automated Host Scaffold Generation
**Goal**: Update generator tooling to output thin dependency-driven host projects.
**Depends on**: Phase 77
**Requirements**: GEN-01, GEN-02, GEN-03
**Success Criteria** (what must be TRUE):
  1. `mix crosswake.gen.shell` generates a host project that pulls in the new SPM/Maven libraries rather than copying source files.
  2. The generated host app wires the initialization and state observation into its native UI lifecycle.
  3. The generation tooling outputs required `Info.plist` and `AndroidManifest.xml` permission templates.
**Plans**: TBD
**UI hint**: yes

### Phase 79: v5.0 Closeout & Hermetic Verification
**Goal**: Verify all new libraries and generators are hermetic and break no existing archetype lanes.
**Depends on**: Phase 78
**Requirements**: PROOF-01
**Success Criteria** (what must be TRUE):
  1. `mix closeout.verify` passes for v5.0.
  2. All existing E2E and archetype proofs continue to execute deterministically in CI against the new standalone dependencies.
  3. The hermetic CI pipelines correctly build the new SPM/Maven dependencies and integrate them.
**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 76. Core Shell Extraction & Packaging | 0/2 | Not started | - |
| 77. Reactive State & API Standardization | 4/4 | Complete   | 2026-06-05 |
| 78. Automated Host Scaffold Generation | 0/0 | Not started | - |
| 79. v5.0 Closeout & Hermetic Verification | 0/0 | Not started | - |
