# Requirements: Crosswake Adoption Evidence Demo App

**Defined:** 2026-06-06
**Core Value:** Replace host-owned generated shell code with standalone SPM/Maven dependencies to eliminate the "eject trap".

## v1 Requirements

### Setup & Integration

- [ ] **SETUP-01**: Demo apps (iOS and Android) must consume Crosswake via standalone SPM and Maven Central dependencies (no local project references).
- [ ] **SETUP-02**: Demo apps must implement a thin host project structure with zero generated `ActivationCoordinator` or `BridgeChannel` source files.

### Reactive State

- [x] **STATE-01**: Demo apps must observe and display the shell connection state (connected/disconnected/retrying) using reactive APIs (Combine on iOS, StateFlow on Android).
- [x] **STATE-02**: Native UI must react to at least one server-pushed event (e.g., a "Welcome" or "Sync complete" toast) via the reactive bridge.

### Navigation & Handshake

- [x] **NAV-01**: Demo app must demonstrate manifest-driven navigation, correctly transitioning between server-owned LiveView routes and a native escape hatch.
- [x] **NAV-02**: Demo app must implement the "Capability Handshake" where the native shell reports its locally registered bridge components to the Phoenix backend.

### Bounded Bridge

- [x] **BRIDGE-01**: Demo app must implement at least one bounded bridge command (e.g., native Share) to prove the component registration pattern.

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| SETUP-01 | Phase 80 | Pending |
| SETUP-02 | Phase 80 | Pending |
| STATE-01 | Phase 81 | Complete |
| STATE-02 | Phase 81 | Complete |
| NAV-01   | Phase 82 | Complete |
| NAV-02   | Phase 82 | Complete |
| BRIDGE-01| Phase 83 | Complete |

**Coverage:**
- v1 requirements: 7 total
- Mapped to phases: 7
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-06*
*Last updated: 2026-06-06 after roadmap creation*
