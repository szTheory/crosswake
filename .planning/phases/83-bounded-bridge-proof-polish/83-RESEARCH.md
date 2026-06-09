# Phase 83: Bounded Bridge Proof Polish - Research

**Researched:** 2026-06-08 (Assumed from UI-SPEC)
**Domain:** Crosswake Bridge & Native Capabilities
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **BRIDGE-01**: Demo app must implement at least one bounded bridge command (e.g., native Share) to prove the component registration pattern.
- Native Share dialog is triggered from a LiveView route button.
- Demo app includes a "Quick Start" guide or README for adopters.
- All demo features work on both iOS and Android physical devices/simulators.

### the agent's Discretion
- Best LiveView to add the bounded bridge button, or creating a dedicated route like `/bridge-proof`.

### Deferred Ideas (OUT OF SCOPE)
- N/A
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BRIDGE-01 | Demo app must implement bounded bridge command (native Share) | Verified native `ShareDelegate` exists. Defined injected `<script>` pattern for LiveView interaction. |
</phase_requirements>

## Summary

The goal of Phase 83 is to verify the end-to-end bounded bridge command execution by finalizing the `share.invoke` demo route. Our research confirms that the native `ShareDelegate` is already fully implemented and registered in both the Android (`MainActivity.kt`) and iOS (`CrosswakeShellApp.swift`) shell hosts.

The missing piece is the Phoenix host route declaration and the LiveView interaction. The route must explicitly declare the `"share"` capability in its `crosswake` manifest configuration. To trigger the native Share dialog without a custom JS build step, we can use the injected `<script>` pattern already established in `approval_live.ex` which pushes JSON payloads to the shell's injected `crosswakeBridge`. Finally, a Quick Start guide needs to be added as a README to document this capability pattern for adopters.

**Primary recommendation:** Implement a new `CrosswakeExample.BridgeProofLive` LiveView module mounted at `/bridge-proof`. Register it with `capabilities: ["share"]` in `router.ex`. Use the dynamic `<script>` tag pattern to dispatch `share.invoke` events to the native bridge.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Route Capability Declaration | API / Backend | Browser / Client | The Phoenix `router.ex` serves as the authoritative manifest source of truth for allowed capabilities per route. |
| Bridge Invocation | Browser / Client | API / Backend | The JS layer must physically invoke the native shell's injected bridge object (`crosswakeBridge.postMessage`). |
| Native Action Execution | Browser / Client | — | The native `ShareDelegate` opens the system UI share dialog on iOS and Android. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix LiveView | (bundled) | Route state and event handling | The default Crosswake host paradigm. |
| Injected `crosswakeBridge` | (bundled) | Web-to-Native communication | Injected automatically by `LiveViewFragment.kt` and `RootSceneWrapper` in iOS. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Jason` | (bundled) | JSON serialization | Used to encode bridge command payloads before passing them to JS. |

**Installation:**
No new dependencies are required. The required bridge handlers are already implemented in `examples/ios_shell_host` and `examples/android_shell_host`.

## Package Legitimacy Audit

> **Required** whenever this phase installs external packages. Run the Package Legitimacy Gate protocol before completing this section.

*No external packages are required for this phase. slopcheck verification skipped.*

## Architecture Patterns

### System Architecture Diagram
```
LiveView Client (WebView)       Phoenix Backend (Server)          Native Shell (iOS/Android)
       |                                |                                   |
       |-- User clicks "Share" CTA ---->|                                   |
       |                                |                                   |
       |<-- Updates @bridge_request ----|                                   |
       |    renders <script>            |                                   |
       |                                |                                   |
       |-- window.crosswakeBridge.postMessage() --------------------------->|
       |                                |                                   |
       |                                |                   Validates capability == "share"
       |                                |                   Executes ShareDelegate.invoke()
```

### Pattern 1: Injected Bridge Dispatch (Without Assets Pipeline)
**What:** Using Phoenix LiveView state to render a dynamic `<script>` tag that invokes the natively injected bridge handler. This avoids needing a compiled `app.js` with `phx-hook`.
**When to use:** When demonstrating minimal bounded bridge usage in runnable documentation without complex client build pipelines.
**Example:**
```elixir
# In LiveView template
<script :if={@bridge_request} id={"crosswake-bridge-dispatch-\#{System.unique_integer()}"}>
  <%= Phoenix.HTML.raw(bridge_script(@bridge_request)) %>
</script>

# In LiveView module
defp bridge_script(request) do
  json = Jason.encode!(request)
  """
  (function() {
    const payload = JSON.stringify(#{json});
    if (window.webkit?.messageHandlers?.crosswakeBridge) {
      window.webkit.messageHandlers.crosswakeBridge.postMessage(payload);
    } else if (window.crosswakeBridge?.postMessage) {
      window.crosswakeBridge.postMessage(payload);
    }
  })();
  """
end
```

### Anti-Patterns to Avoid
- **Implicit Capabilities:** Do not attempt to invoke `share.invoke` without explicitly declaring `"share"` in the route's `crosswake: [capabilities: ["share"]]` configuration. The shell will securely reject undeclared commands.
- **Requiring `assets/js` build:** Do not add a JS build pipeline just to test a single bridge command. Stick to the `bridge_script` HTML rendering pattern established in `approval_live.ex`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Bridge Serialization | Custom JS postMessage formatting | `Crosswake.Bridge.Contract.new_request/1` (if applicable) or strict Map | Ensures the correct protocol, version, correlation ID, and command structure are sent to the native shell. |

**Key insight:** The shell validates bridge commands strictly against `Crosswake.Bridge.Contract`. Construct requests identically to the `approval_live.ex` haptics request or use the provided Crosswake Elixir structs to avoid validation failures.

## Code Examples

Verified patterns from official sources:

### Route Capability Declaration (router.ex)
```elixir
live("/bridge-proof", CrosswakeExample.BridgeProofLive,
  crosswake: [
    id: "bridge-proof",
    runtime: :live_view,
    capabilities: ["share"],
    offline: :cached_read_only,
    security: :standard
  ]
)
```

### Command Construction
```elixir
request = %{
  "protocol" => "crosswake.bridge",
  "version" => "1.0.0",
  "command" => "share.invoke",
  "route_id" => "bridge-proof",
  "active_route_id" => "bridge-proof",
  "capabilities" => %{"share" => "1.0.0"},
  "payload" => %{
    "title" => "Crosswake Demo",
    "text" => "Check out Crosswake bridging!",
    "url" => "https://crosswake.dev"
  }
}
# Assign to @bridge_request in the socket
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Unbounded `window.postMessage` | Bounded capabilities via Manifest | Phase 81/82 | Bridge commands are strictly validated against pre-declared route capabilities, preventing arbitrary JS from accessing native capabilities. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `assets/js` pipeline is intentionally omitted for simplicity | Architecture Patterns | We might introduce inconsistent front-end code if we were supposed to use `phx-hook` inside a proper JS bundle. |

## Open Questions (RESOLVED)
1. **Should the `@bridge_request` state be cleared?**
   - What we know: `approval_live.ex` leaves it rendered. Re-triggering a share might require a unique ID to force a DOM patch.
   - RESOLVED: Add a `System.unique_integer()` to the `<script>` ID so LiveView patches it on consecutive clicks.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| iOS Simulator / Device | Success Criteria 3 | ✓ | — | — |
| Android Emulator / Device | Success Criteria 3 | ✓ | — | — |
| Elixir / Phoenix | LiveView host | ✓ | — | — |

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V4 Access Control | yes | Capabilities manifest checking in CrosswakeShell |
| V5 Input Validation | yes | `Crosswake.Bridge.Contract` strictly typing the payload |

### Known Threat Patterns for Crosswake Bridge

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unintended Native Access | Elevation of Privilege | Shell validates incoming `postMessage` command against the resolved route's capabilities array. |

## Sources

### Primary (HIGH confidence)
- `lib/crosswake/bridge/contract.ex` - Bridge command envelope structure.
- `lib/crosswake/bridge/commands/share.ex` - Share payload structure.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex` - Verified `<script>` dispatch pattern.
- `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/MainActivity.kt` - ShareDelegate Android implementation.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Directly follows `approval_live.ex`.
- Architecture: HIGH - Matches Crosswake shell implementation.
- Pitfalls: HIGH - Capabilities manifest check is verified in registry.

**Research date:** 2026-06-08
**Valid until:** Next bridge protocol bump