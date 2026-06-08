# Phase 82: Navigation & Capability Handshake - Context

**Gathered:** 2026-06-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove manifest-driven routing and local-truth capability reporting. The demo app must transition between LiveView and a native escape hatch, and the shell must report its registered bridge components to the Phoenix backend.
</domain>

<decisions>
## Implementation Decisions

### Native Route Mapping (Navigation Triggering)
- **D-01:** Implement a **Registry/Delegate Pattern** for route mapping. The `CrosswakeShellConfig` initialized by the host app must accept a `RouteDelegate` or a registry that maps a `routeID` (e.g., `capture`) to a native UI factory (Intent/ViewController). 
- **Rationale:** This prevents the "eject trap" by keeping host-specific screens entirely out of the standalone shell dependency. Unmapped native routes will predictably fail-closed to a `RouteUnavailableView`.

### Capability Handshake Timing
- **D-02:** Execute the capability handshake via **Connection Parameters during Socket Connect**. The native shell will inject its registered capability list (e.g., `["share", "haptics", "file_picker"]`) into the LiveView WebSocket connection parameters.
- **Rationale:** This is idiomatic for Phoenix/LiveView (`connect/3` params). It ensures the backend knows the client's capabilities synchronously before the initial mount completes, eliminating race conditions, flashes of unsupported UI, and unnecessary re-renders.

### Return Flow from Native Screen
- **D-03:** Use **Native Dismissal + Explicit Bridge Event**. When the native escape hatch is finished, it dismisses itself using platform-idiomatic navigation and invokes an explicit bridge event (e.g., `shell.sendBridgeEvent("route_return", payload)`) to update the LiveView backend.
- **Rationale:** Aligns with Crosswake's ethos of explicit boundaries and bounded bridge contracts. It avoids brittle polling or generic `onResume` refreshes, ensuring the server state is patched predictably with low-frequency, typed data.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project and Requirements
- `.planning/REQUIREMENTS.md` - For `NAV-01` and `NAV-02`
- `.planning/ROADMAP.md` - For phase boundaries and success criteria
- `guides/native_shell.md` - For manifest-first activation documentation
- `guides/user_flows.md` - For Crosswake job-to-be-done framing

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/NativeCaptureActivity.kt` - Existing Android native escape hatch.
- `examples/ios_shell_host/CrosswakeShell/NativeCaptureView.swift` - Existing iOS native escape hatch.
- `CrosswakeShellConfig` (Android/iOS) - The initialization surface where the route registry and delegates should be passed.

### Established Patterns
- Manifest-first activation (routes are validated against manifest truth before mounting).
- Fail-closed behavior for unsupported routes or missing capabilities.
- Bounded, typed bridge messaging.

### Integration Points
- Update LiveView socket connection configuration in both Swift and Kotlin clients to append capability parameters.
- Expose a `RouteDelegate` or routing closure in `CrosswakeShellConfig`.
</code_context>

<specifics>
## Specific Ideas

- Ensure developer ergonomics (DX) in the host app are excellent: registering a native screen should be a simple one-liner in the configuration step (e.g., `config.registerRoute("capture") { route -> Intent(...) }`).
- The capability list sent to Phoenix should reflect only the actual delegates/coordinators passed into the configuration, proving "local-truth" capability reporting.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.
</deferred>

---

*Phase: 82-Navigation & Capability Handshake*
*Context gathered: 2026-06-08*