# Feature Landscape: Adoption Evidence Demo App

**Domain:** Phoenix-native Mobile Shells (v5.1 Standalone Dependency Proof)
**Researched:** 2026-06-06

## Table Stakes

Features users expect in a mobile demo of a web-to-native library.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Clean Setup | Adopters need to see how little code is required to start. | Low | Must use standalone SPM/Maven, not local project links. |
| Navigation Flow | Shows hybrid push/modal transitions. | Med | Proves manifest-driven navigation. |
| Reactive State UI | Shows how native UI reacts to shell state (e.g. connection). | Med | Uses new Combine/Flows APIs. |
| Basic Capability | Demonstrates a simple native bridge action (e.g. Share). | Low | Proves the component registration pattern. |

## Differentiators

Features that prove Crosswake's unique value in the v5.0 standalone era.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Zero-Boilerplate Shell | Prove that no `ActivationCoordinator` or `BridgeChannel` code needs to be generated. | Low | Contrast with v4.0 "generated shell" approach. |
| Capability Handshake | Native shell announcing registered components to web. | Med | Solves manifest-capability desync. |
| Async Command Ack | Server triggers native action and receives reactive ack. | High | Proves the server-event plane. |

## Anti-Features

Features to explicitly NOT build in this demo.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Custom Local Proxy | Too complex for a demo; hides core bridge logic. | Use standard Phoenix/LiveView transport. |
| Generic Sync Engine | Outside scope of "Adoption Evidence". | Use explicit reactive state for specific shell data. |
| UI Framework Overload | Native UI should be minimal to highlight the bridge. | Use basic SwiftUI/Compose views. |

## Feature Dependencies

```
Standalone Bootstrap → Manifest Navigation → Reactive State API → Capability Handshake
```

## MVP Recommendation

Prioritize:
1. **Clean Standalone Integration** (iOS/Android)
2. **Reactive Connection State** (proving the state API)
3. **Basic Share Action** (proving the component registration)

Defer: **Advanced Auth Step-up** (already proven in Sigra research, keep demo app lean).

## Sources
- `PROJECT.md` Standalone Shell Requirements
- `SUMMARY.md` Roadmap Implications
