# Technology Stack: Adoption Evidence Demo App

**Project:** Crosswake (v5.1 Standalone Dependency Proof)
**Researched:** 2026-06-06

## Recommended Stack

### Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Elixir / Phoenix | ~> 1.17 | Backend Host & Authority | Current stable Phoenix version for modern LiveView features. |
| Phoenix LiveView | ~> 1.0 | Server-Rendered UI | Utilizing the latest stable LiveView features for the demo. |
| Crosswake Core | v5.0.x | Mobile Shell Integration | The target version to be proven via standalone dependencies. |

### Standalone Dependencies
| Technology | Distribution | Purpose | Why |
|------------|--------------|---------|-----|
| Crosswake iOS | SPM | Native iOS Shell | Standalone dependency (Git-based) to prove "no eject trap". |
| Crosswake Android | Maven | Native Android Shell | Published Maven Central artifact (or local Maven simulated) for integration. |

### Reactive State Libraries
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Combine (Swift) | Native | iOS Reactive State | Standard Apple framework for shell state observation. |
| Kotlin Flows | Native | Android Reactive State | Standard Kotlin Coroutines API for reactive streams. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Dependency | Standalone SPM/Maven | Project Reference | Project references mask integration friction; Standalone is the core v5.0 value. |
| UI State | Reactive Streams | Callback Delegates | Massive callbacks create boilerplate; reactive APIs improve developer ergonomics and host UI decoupling. |

## Installation

```bash
# Core Elixir
mix deps.add crosswake

# iOS (Package.swift)
.package(url: "https://github.com/crosswake/crosswake-shell-core-ios", from: "5.0.0")

# Android (build.gradle)
implementation "io.crosswake:shell-core-android:5.0.0"
```

## Sources
- `PROJECT.md` v5.0 Key Decisions
- [Kotlin Flows Documentation](https://kotlinlang.org/docs/flow.html)
- [Apple Combine Documentation](https://developer.apple.com/documentation/combine)
