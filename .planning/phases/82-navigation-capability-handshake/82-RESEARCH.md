# Phase 82: Navigation & Capability Handshake - Research

**Researched:** 2026-06-08
**Domain:** Crosswake Bridge Navigation and Capability Sync
**Confidence:** HIGH

## Summary

This phase proves manifest-driven routing and local-truth capability reporting in the Crosswake architecture. The host application must be able to transition between LiveView web contexts and native escape hatch screens (NAV-01). Concurrently, the native shell must report the exact list of capabilities (bridge components) it has registered to the Phoenix backend during the LiveView connection handshake (NAV-02).

**Primary recommendation:** Use LiveView socket connection parameters to pass the native capabilities array during connection establishment, and rely on explicit bridge messaging for return flows from native captures.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Implement a **Registry/Delegate Pattern** for route mapping. The `CrosswakeShellConfig` initialized by the host app must accept a `RouteDelegate` or a registry that maps a `routeID` (e.g., `capture`) to a native UI factory (Intent/ViewController). 
- **D-02:** Execute the capability handshake via **Connection Parameters during Socket Connect**. The native shell will inject its registered capability list (e.g., `["share", "haptics", "file_picker"]`) into the LiveView WebSocket connection parameters.
- **D-03:** Use **Native Dismissal + Explicit Bridge Event**. When the native escape hatch is finished, it dismisses itself using platform-idiomatic navigation and invokes an explicit bridge event (e.g., `shell.sendBridgeEvent("route_return", payload)`) to update the LiveView backend.

### the agent's Discretion
- Ensure developer ergonomics (DX) in the host app are excellent: registering a native screen should be a simple one-liner in the configuration step (e.g., `config.registerRoute("capture") { route -> Intent(...) }`).
- The capability list sent to Phoenix should reflect only the actual delegates/coordinators passed into the configuration, proving "local-truth" capability reporting.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| NAV-01 | Demo app must demonstrate manifest-driven navigation, transitioning between server-owned LiveView routes and native escape hatch. | D-01 specifies using a Registry/Delegate Pattern via CrosswakeShellConfig. |
| NAV-02 | Demo app must implement "Capability Handshake" reporting local capabilities to the Phoenix backend. | D-02 details injecting the capability list into LiveView WebSocket connection params. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Route Resolution | Native Shell | Backend Manifest | The shell resolves deep links against the bundled manifest and evaluates boundaries *before* navigating the web view. |
| Capability Handshake | Native Shell | LiveView Socket | The shell sends locally-registered capabilities via connection parameters to the Phoenix channel. |
| Native Capture UI | Native Shell | — | Native code fully owns the UI flow of the escape hatch. |
| Escape Hatch Return | Native Shell | Bridge Channel | The shell dismisses the screen and sends a typed bridge event back to Phoenix to resume the flow. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix LiveView | ~> 1.0 (implied) | Backend state management | Core framework for the Crosswake backend |
| CrosswakeShellCore | 0.1.0 | Standalone Shell Logic | Host app depends on SPM/Maven standalone core to avoid the eject trap |

## Architecture Patterns

### Component Responsibilities

1. **Host App Config (`CrosswakeShellConfig`)**: Registers route delegates.
2. **ActivationCoordinator**: Resolves routes against the manifest and generates the `LiveViewSession`.
3. **LiveView Web Client**: Connects via `Phoenix.Socket`, appending capabilities to `params`.
4. **BridgeChannel**: Translates bridge commands and manages return payloads.

### Pattern 1: Connection Parameter Capability Handshake
**What:** Pass capabilities dynamically at connect time.
**When to use:** In the frontend Javascript responsible for establishing the LiveView socket inside the Web container.
**Example:**
```javascript
// On the web side (e.g. app.js)
let liveSocket = new LiveSocket("/live", Socket, {
  params: {
    _csrf_token: csrfToken,
    capabilities: window.crosswakeBridge ? window.crosswakeBridge.capabilities : []
  }
});
```

### Pattern 2: Native Route Return via Bridge
**What:** The native capture flow dismisses itself and sends an event over the bridge.
**When to use:** When concluding an explicit native escape hatch session.

## Code Examples

### Capability Extraction in Elixir
```elixir
# In the Phoenix LiveView mount
def mount(_params, _session, socket) do
  # Extract connection info
  capabilities = get_connect_params(socket)["capabilities"] || []
  socket = assign(socket, :native_capabilities, capabilities)
  {:ok, socket}
end
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Route interception | Custom URL Overrides | Manifest Verification | Crosswake's core value relies on manifest-truth before allowing route entry. |
| Capability probing | Polling Javascript | Connect params | Polling causes race conditions and flashes of unsupported UI. Syncing at connect is robust. |

## Validation Architecture
- Check that the `CrosswakeShellConfig` exposes a routing registry.
- Check that connection parameters from Javascript include the `capabilities` payload.
- Check that Phoenix backend logs/detects these parameters on mount.
