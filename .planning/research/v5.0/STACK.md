# Technology Stack

**Project:** Crosswake v5.0 (Standalone Publishable Shell Packages)
**Researched:** 2026-06-03

## Recommended Stack

### iOS Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Swift Package Manager (SPM) | Swift 5.9+ | Dependency Distribution | Native to Xcode, standard for modern iOS libraries. Provides seamless integration without CocoaPods/Carthage overhead. |
| Combine / Observation | iOS 14+ / iOS 17+ | Reactive State Management | Replaces manual delegates for UI state updates, allowing host SwiftUI views to natively observe shell state. |

### Android Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Maven Central (AAR) | AGP 8+ | Dependency Distribution | The canonical method for distributing Android binaries. Protects core logic and simplifies version upgrades. |
| Kotlin Coroutines & Flow | Kotlin 1.9+ | Reactive State Management | Provides `StateFlow` and `SharedFlow`, the modern standard for exposing state and events, replacing massive callback interfaces. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| iOS Distribution | SPM | CocoaPods | Deprecated in modern workflows, requires external Ruby dependencies, slower integration. |
| Code Boilerplate | Pre-compiled Binaries (SPM/AAR) | KSP / Swift Macros | While KSP/Macros are great for generating mapping logic, Crosswake's core routing and bridge enforcement is uniform across apps and does not benefit from per-app code generation. A binary core is vastly simpler to maintain. |
| State Management | Flow / Combine | RxJava / RxSwift | Overly heavy, steep learning curve, and largely superseded by first-party language features (Coroutines/Combine). |

## Installation

```bash
# Elixir Host (Generation Phase)
mix crosswake.gen.shell ios
mix crosswake.gen.shell android
```

*Note: The generated code will now be a thin scaffold that relies on the published packages in `build.gradle` and `Package.swift`.*

## Sources

- Ecosystem Best Practices for SDK Distribution (iOS/Android)
- Kotlin Coroutines & Flow Documentation
- Swift Package Manager Documentation
