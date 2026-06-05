# Requirements: Crosswake — v5.0 Standalone Publishable Shell Packages

**Defined:** 2026-06-05
**Core Value:** Replace host-owned generated shell code (`ActivationCoordinator`, `BridgeChannel`) with standalone SPM/Maven dependencies, enforcing strict delegate-based customization to eliminate the "eject trap" and boilerplate for adopters.

## v1 Requirements

### Core Extraction & Packaging (CORE)

- [ ] **CORE-01**: Crosswake core logic (`ActivationCoordinator`, `BridgeChannel`) must be extracted into a standalone Swift Package Manager (SPM) dependency for iOS.
- [ ] **CORE-02**: Crosswake core logic must be extracted into a standalone Maven Central artifact (AAR) for Android.
- [ ] **CORE-03**: The core libraries must internally enforce route policy, manifest parsing, bridge command validation, and capability checking without requiring host-app duplication.

### API Standardization & State (API)

- [x] **API-01**: The libraries must provide a single initialization entry point (e.g., `CrosswakeShell.initialize()`) to replace raw object generation in the host.
- [x] **API-02**: Shell state must be exposed to the host UI via modern reactive streams (`StateFlow` for Android, `ObservableObject` / `@Published` for iOS) rather than monolithic callbacks.
- [x] **API-03**: The libraries must expose strictly-typed, narrow Delegate protocols or lambda injection for specific host-provided capabilities (e.g., custom haptics, file picking) to avoid the "boilerplate trap" of massive interfaces.

### Scaffold Generation & Integration (GEN)

- [ ] **GEN-01**: `mix crosswake.gen.shell` must be updated to output a thin, dependency-driven host project that consumes the new SPM/Maven artifacts instead of full source copies.
- [ ] **GEN-02**: The generated host app must contain a "Glue" layer that wires the library into the host app lifecycle and observes its state for UI rendering.
- [ ] **GEN-03**: The generation tooling must configure or template the necessary host permission requests (`Info.plist` / `AndroidManifest.xml`) required by the core SDK.

### Proof & Closeout (PROOF)

- [ ] **PROOF-01**: All v5.0 core extraction and API standardization changes must run hermetically in CI, ensuring existing E2E and archetype proof lanes continue to pass against the new standalone libraries.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CORE-01 | Phase 76 | Pending |
| CORE-02 | Phase 76 | Pending |
| CORE-03 | Phase 76 | Pending |
| API-01 | Phase 77 | Complete |
| API-02 | Phase 77 | Complete |
| API-03 | Phase 77 | Complete |
| GEN-01 | Phase 78 | Pending |
| GEN-02 | Phase 78 | Pending |
| GEN-03 | Phase 78 | Pending |
| PROOF-01 | Phase 79 | Pending |

**Coverage:**
- v1 requirements: 10 total
- Mapped to phases: 10 ✓
- Unmapped: 0
