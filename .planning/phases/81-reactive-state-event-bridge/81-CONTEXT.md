# Phase 81: Reactive State & Event Bridge - Context

**Gathered:** 2026-06-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Native UI reacts to shell state and server events via reactive APIs, proving the new reactive observer pattern.
</domain>

<decisions>
## Implementation Decisions

### Connection Status UI
- **D-01:** Display the connection status using a subtle native indicator (e.g., a small banner or icon that hides on success) to ensure the user is informed of connectivity state without being overly intrusive.

### Toast Event Design
- **D-02:** Render server-pushed events (like toasts) using standard native Snackbar (Android) or Toast-equivalent overlays (iOS) to keep the experience aligned with platform conventions.

### Lifecycle Management
- **D-03:** Tie observer disposal strictly to the View lifecycle (`onDispose` in Compose, `onDisappear` / `deinit` in SwiftUI) to prevent memory leaks and unexpected background state updates.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project and Requirements
- `.planning/REQUIREMENTS.md` - For `STATE-01` and `STATE-02`
- `.planning/ROADMAP.md` - For phase boundaries and success criteria

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The `CrosswakeShell` instance instantiated as `@StateObject` (iOS) or managed by `MainActivity` (Android) serves as the source of truth for shell presentation states.
- iOS `RootSceneView` and Android `RenderPresentation` handle the shell's top-level navigation states and can be expanded to include connection status.

### Established Patterns
- Reactive UI wrappers: SwiftUI's `@Published` / `ObservableObject`, and Jetpack Compose's `StateFlow` (`collectAsState()`).
- Hermetic-vs-advisory CI split is the default pattern for environment-sensitive proof surfaces.

### Integration Points
- Add connection status view above or floating over `LiveViewContainerView` (iOS) and `LiveViewScreen` / `LiveViewFragment` (Android).
- Subscribe to the backend event bus for toast events locally where `CrosswakeShell` manages the connection.
</code_context>

<specifics>
## Specific Ideas

- The implementation should prove the "new reactive observer pattern", avoiding legacy callbacks in favor of modern reactive pipelines (`Combine` and `StateFlow`).

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 81-Reactive State & Event Bridge*
*Context gathered: 2026-06-08*