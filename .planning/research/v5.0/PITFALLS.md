# Domain Pitfalls

**Domain:** Mobile SDK Architecture & Dependency Management
**Researched:** 2026-06-03

## Critical Pitfalls

Mistakes that cause rewrites or major issues.

### Pitfall 1: The "Eject Trap" via Code Generation
**What goes wrong:** Generating complex business logic (e.g., `ActivationCoordinator`, Bridge validation) directly into the host project.
**Why it happens:** It is often the fastest way to get a working prototype and allows the user to see exactly how the code works.
**Consequences:** "Version drift." When the underlying framework updates its routing logic or bridge contract, the user cannot easily upgrade because they have likely modified the generated code. They are "ejected" from the update path.
**Prevention:** Package core logic as a binary library (SPM/Maven). Generate only a thin "glue" layer that wires the library into the host app lifecycle.

### Pitfall 2: Leaky Abstractions & Boilerplate Callbacks
**What goes wrong:** Forcing the host app to implement massive, monolithic callback interfaces (`CrosswakeShellDelegate` with 30 methods).
**Why it happens:** The SDK developer wants to give the host maximum flexibility and control over every possible event.
**Consequences:** Extremely poor developer ergonomics. Onboarding requires copying massive blocks of boilerplate code. Users implement empty methods for events they don't care about.
**Prevention:** Use modern reactive patterns (`StateFlow`, Combine) for state observation. Use narrow, optional delegate protocols or lambda injection for specific side-effects (e.g., `onHapticsRequested = { ... }`).

## Moderate Pitfalls

### Pitfall 3: Permission and Entitlement Blindness
**What goes wrong:** The core library requires certain capabilities (e.g., Camera access, Push Notifications), but the host app forgets to declare them in `Info.plist` or `AndroidManifest.xml`.
**Prevention:** Android AARs can automatically merge manifest permissions. For iOS, the SDK must clearly document required `Info.plist` entries, and the Elixir generation tool (`mix crosswake.gen.shell`) should still output the necessary permission templates or configure the Xcode project correctly during initial scaffolding.

## Minor Pitfalls

### Pitfall 4: Hardcoding UI in the Core Library
**What goes wrong:** The core library (`crosswake-shell-core`) directly embeds specific UI views (like a specific "Route Unavailable" screen) that the host app cannot customize.
**Prevention:** The core library should emit *State* (e.g., `ShellPresentation.Denied(reason)`). The default generated Host Glue can provide a basic UI for that state, but the host app remains free to render whatever they want when that state is observed.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Core Extraction | Breaking existing behavior while refactoring into a library. | Ensure the existing Hermetic CI lanes continue to pass against the newly extracted libraries. |
| API Design | Designing Java-era callback APIs instead of modern Kotlin/Swift reactive APIs. | Mandate the use of `StateFlow` (Android) and `ObservableObject` (iOS) for all state exposure. |
| Scaffold Generation | Generating code that doesn't compile out of the box because the new dependencies aren't correctly added to `build.gradle` / `Package.swift`. | Thoroughly test the new `mix crosswake.gen.shell` output against clean host projects. |

## Sources

- Ecosystem Research on Modern Android/iOS SDK Design
- Crosswake MILESTONE-ARC.md and existing codebase analysis
