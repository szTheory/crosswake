# Roadmap: v5.1 Adoption Evidence Demo App

**Milestone:** v5.1
**Granularity:** balanced
**Coverage:** 7/7 v1 requirements mapped

## Phases

- [ ] **Phase 80: Standalone Dependency Bootstrap** - Transition demo apps to published SPM/Maven dependencies.
- [ ] **Phase 81: Reactive State & Event Bridge** - Implement reactive UI observers for shell state and server events.
- [ ] **Phase 82: Navigation & Capability Handshake** - Prove manifest-driven routing and local-truth capability reporting.
- [ ] **Phase 83: Bounded Bridge Proof & Polish** - Verify end-to-end bridge command and finalize demo experience.

## Phase Details

### Phase 80: Standalone Dependency Bootstrap
**Goal**: Demo app consumes published dependencies instead of local source, proving the v5.0 standalone distribution.
**Depends on**: Nothing (v5.1 start)
**Requirements**: SETUP-01, SETUP-02
**Success Criteria** (what must be TRUE):
  1. iOS demo app builds successfully using Crosswake SPM dependency.
  2. Android demo app builds successfully using Crosswake Maven dependency.
  3. No `ActivationCoordinator` or `BridgeChannel` source files exist in the demo host project.
**Plans**: 1 plan
- [ ] 80-01-PLAN.md — Migrate Android/iOS host apps to Maven/SPM dependencies

### Phase 81: Reactive State & Event Bridge
**Goal**: Native UI reacts to shell state and server events via reactive APIs, proving the new reactive observer pattern.
**Depends on**: Phase 80
**Requirements**: STATE-01, STATE-02
**Success Criteria** (what must be TRUE):
  1. Native UI updates connection status (e.g., "Connected") automatically when socket connects.
  2. Server-pushed toast event is displayed in native UI without manual polling.
  3. Native observers are correctly disposed of on view lifecycle changes.
**Plans**: TBD
**UI hint**: yes

### Phase 82: Navigation & Capability Handshake
**Goal**: Prove manifest-driven routing and local-truth capability reporting.
**Depends on**: Phase 81
**Requirements**: NAV-01, NAV-02
**Success Criteria** (what must be TRUE):
  1. User can navigate from a LiveView route to a native escape hatch screen.
  2. Native shell sends its capability list to the backend upon connection.
  3. Backend logs/detects the specific native capabilities reported by the shell.
**Plans**: TBD
**UI hint**: yes

### Phase 83: Bounded Bridge Proof & Polish
**Goal**: Verify end-to-end bridge command and finalize the demo as "runnable documentation".
**Depends on**: Phase 82
**Requirements**: BRIDGE-01
**Success Criteria** (what must be TRUE):
  1. Native Share dialog is triggered from a LiveView route button.
  2. Demo app includes a "Quick Start" guide or README for adopters.
  3. All demo features work on both iOS and Android physical devices/simulators.
**Plans**: TBD
**UI hint**: yes

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 80. Standalone Dependency Bootstrap | 2/2 | Complete | 2026-06-08 |
| 81. Reactive State & Event Bridge | 0/0 | Not started | - |
| 82. Navigation & Capability Handshake | 0/0 | Not started | - |
| 83. Bounded Bridge Proof & Polish | 0/0 | Not started | - |

---
*Roadmap generated: 2026-06-06*
ted | - |

---
*Roadmap generated: 2026-06-06*
