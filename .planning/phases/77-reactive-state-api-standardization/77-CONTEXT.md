# Phase 77: Reactive State & API Standardization - Context

**Gathered:** 2026-06-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Standardize the API shape of the standalone Crosswake native shell libraries (iOS and Android). This phase locks in the patterns for SDK initialization, state exposure, and host capability delegation before building the host generation tooling. It does not include automated scaffold generation or full E2E verification.

</domain>

<decisions>
## Implementation Decisions

### Initialization Shape
- **D-01:** Implement `CrosswakeShell` as a scoped instance (e.g. `val shell = CrosswakeShell(config)`) rather than a global singleton (`CrosswakeShell.shared`).
- **D-02:** This scoped approach preserves the Elixir/Phoenix principle of explicit lifecycle ownership (like a GenServer or Supervision tree) and avoids the "eject trap" of hidden global state.

### Android State Flow
- **D-03:** Expose shell state as a single atomic `ShellState` snapshot (e.g. `val state: StateFlow<ShellState>`) rather than granular properties (`isOnline: StateFlow<Boolean>`).
- **D-04:** This mimics Phoenix LiveView's Unidirectional Data Flow (`socket.assigns`) and guarantees tear-free UI renders.

### Capability Delegation
- **D-05:** Define narrow Protocol/Interface delegates (e.g. `interface HapticsDelegate`) for host-provided capabilities instead of using inline lambda injections (e.g. `hapticsHandler: (String) -> Void`).
- **D-06:** Use these delegates for deterministic capability negotiation: the shell inspects the configured delegates at startup and automatically limits the `capabilities.announced` payload to the provided interfaces.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and milestone posture
- `.planning/PROJECT.md` - Crosswake thesis, explicit runtime boundaries, and native abstraction limits.
- `.planning/REQUIREMENTS.md` - API-01, API-02, and API-03 traceability.
- `.planning/ROADMAP.md` - Phase 77 goal and API standardization boundaries.
- `.planning/STATE.md` - Current v5.0 posture tracking toward standalone package adoption.

### Architectural Research & Guidelines
- `prompts/crosswake-elixir-oss-dna.md` - Focus on explicit contracts and maintaining the "Elixir-brained" OSS house style.
- `prompts/crosswake-research-synthesis.md` - Prior research on avoiding the "eject trap" and respecting declarative boundaries.
- `prompts/elixir-mobile-oss-lib-deep-research.md` - Library ergonomics and integration design for native environments.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ActivationCoordinator` (Kotlin/Swift) - Existing core orchestrator; its initialization semantics will be refactored to align with the new `CrosswakeShell(config)` shape.
- `BridgeChannel` (Kotlin/Swift) - Where lambda handlers currently exist and will be migrated to the new Protocol/Interface delegate structure.

### Established Patterns
- Existing reactive streams (`ObservableObject` / `@Published` in iOS) will inform the structural shape of the atomic `ShellState` approach on Android (`StateFlow<ShellState>`).

### Integration Points
- Refactored `CrosswakeShell` instance injection into `CrosswakeShellApp.swift` (SwiftUI Environment) and `MainActivity.kt` (Jetpack Compose / Fragment lifecycle).

</code_context>

<specifics>
## Specific Ideas

- Host apps should treat `CrosswakeShell` conceptually like starting a GenServer—providing configuration, starting the instance, and holding the reference, ensuring completely explicit and tear-free lifecycle management.

</specifics>

<deferred>
## Deferred Ideas

- `mix crosswake.gen.shell` generation tooling updates (Phase 78).
- E2E hermetic verification of the v5.0 core extraction (Phase 79).

</deferred>

---

*Phase: 77-Reactive State & API Standardization*
*Context gathered: 2026-06-05*
