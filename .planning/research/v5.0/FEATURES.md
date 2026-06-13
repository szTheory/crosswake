# Feature Landscape

**Domain:** Mobile SDK Architecture & Dependency Management
**Researched:** 2026-06-03

## Table Stakes

Features users expect. Missing = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| SPM & Maven Artifacts | Adopters need a standard way to pull in the Crosswake core without copying source files. | Medium | Requires establishing publishing pipelines (CI/CD) for Swift and Kotlin code. |
| Initialization Builder | A single entry point (e.g., `CrosswakeShell.initialize()`) to configure the shell. | Low | Must support injecting manifest, origins, and optional delegates. |
| Reactive State Exposure | Host UI (SwiftUI / Jetpack Compose) needs to observe the shell state (`booting`, `denied`, `live_view`). | Low | Use `StateFlow` (Android) and `ObservableObject` or `@Observable` (iOS). |
| Delegate Protocol / Callbacks | Host needs to handle specific side-effects (e.g., file picking, custom haptics, routing denial UI overrides). | Medium | Keep interfaces narrow. Prefer lambda injection or small, single-purpose interfaces over massive catch-all delegates. |

## Differentiators

Features that set product apart. Not expected, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Headless Execution | Ability to run the `ActivationCoordinator` logic entirely without UI, useful for background testing or highly custom host UIs. | High | Decouples routing and bridge logic completely from WebViews and Activities/ViewControllers. |
| Automated Capability Manifesting | Providing a simple way for the library to assert its required capabilities to the host build system (e.g., merging AndroidManifest declarations). | Medium | AARs handle this well automatically. SPM may require build tool plugins or careful documentation for `Info.plist`. |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Massive Java-Style Callback Interfaces | Creates boilerplate and forces adopters to implement methods they don't care about. | Use optional lambdas, builder patterns, or modern reactive streams (Flow/Combine). |
| Universal UI Wrapper | Crosswake should not attempt to wrap every possible UI component. It must remain a route-policy substrate. | Keep the UI boundary clear. The shell handles the WebView and specific native captures, while the host manages the outer window and navigation stack. |
| Over-Generation | Generating complex KSP/Swift Macro code for things that could just be a static binary dependency. | Ship a static binary. Only generate code where the user's specific types must interface with the SDK. |

## Feature Dependencies

```
SPM & Maven Artifacts → Initialization Builder
Initialization Builder → Reactive State Exposure
Reactive State Exposure → Delegate Protocol
```

## MVP Recommendation

Prioritize:
1. Extract `ActivationCoordinator` and `BridgeChannel` into SPM/Maven libraries.
2. Implement the Initialization Builder and Reactive State Exposure.
3. Update `mix crosswake.gen.shell` to output a thin host project that consumes the new libraries.

Defer:
- Headless Execution (until explicitly requested by advanced adopters).
