# Phase 15: Base Capability Bridges - Context

**Date:** 2026-05-20
**Phase:** 15-base-capability-bridges
**Goal:** Implement the simplest low-frequency stateless capabilities to establish the bridge pattern for v3.1.
**Requirements:** `CAP-HAPTICS`, `CAP-SHARE`, `CAP-APPINFO`

## Scope

This phase introduces the first three bounded bridge capabilities across both native shells and the Phoenix host. They are deliberately chosen as stateless, low-frequency, fire-and-forget (or simple request-reply) operations to validate the native bridge payload structure before we tackle complex asynchronous operations like file pickers or permissions.

## Key Decisions

### 1. Share Payload Format and Scope
**Decision:** Restrict share payloads to primitive strings (`url`, `text`, `title`).
**Rationale:** To maintain a strictly stateless bridge without complex Android `FileProvider` lifecycles or temporary file garbage collection, we are mirroring the Web Share API. If a user needs to share a generated PDF, the server should host the file at an ephemeral URL and send that `url` over the bridge. This keeps the native shells thin and fail-closed.

### 2. Command Naming Conventions
**Decision:** Standardize on `<family>.<action>`.
- Haptics: `haptics.impact` (payload: `%{style: "light" | "medium" | "heavy"}`)
- App Info: `app.info.get` (returns `%{version: string, build: string, bundle_id: string}`)
- Share: `share.invoke` (payload: `%{url?: string, text?: string, title?: string}`)
**Rationale:** `haptics.impact` and `app.info.get` are already documented as legacy/existing IDs in the manifest builder. Introducing `share.invoke` aligns perfectly with this dot-separated taxonomy.

### 3. Registry Allowlisting
**Decision:** Explicitly map all three commands in `lib/crosswake/bridge/registry.ex`.
**Rationale:** Crosswake operates on a fail-closed paradigm. If a capability command is not explicitly mapped in the bridge registry, the Elixir host rejects it with `:unsupported_command`. This guarantees no native boundary is ever crossed by an arbitrary or malicious string.

## Architecture

- **Elixir (Host):** Add commands to `Crosswake.Bridge.Registry`. Create well-typed struct modules for each command's request and reply payloads to ensure strong serialization contracts.
- **iOS Shell:** Extend `BridgeChannel.swift` enum with `share` case. Use `UIActivityViewController` for sharing, `UIImpactFeedbackGenerator` for haptics, and `Bundle.main.infoDictionary` for app info.
- **Android Shell:** Extend `BridgeChannel.kt` enum with `share` case. Use `Intent.ACTION_SEND` for sharing, `HapticFeedbackConstants` for haptics, and `PackageInfo` for app info.

## Reopened Decisions (None)
No foundational routing or UI state decisions are being reopened. The bounded bridge paradigm established in v1.0 and hardened in v2.0 remains completely intact.
