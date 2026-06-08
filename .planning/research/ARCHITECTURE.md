# Architecture Patterns: Adoption Evidence Demo App

**Domain:** Phoenix-native Mobile Shells (v5.1 Standalone Dependency Proof)
**Researched:** 2026-06-06

## Recommended Architecture

The "Adoption Evidence" architecture demonstrates the **Standalone Binary + Hosted Glue** strategy. The native app is a "Thin Host" that consumes a published binary core and provides only a small amount of delegate-based customization.

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| Host Phoenix App | Authority, Route Policy, Manifest. | Native Shell (HTTP/WS) |
| Crosswake Core (Binary) | WebView management, Bridge routing, Manifest parsing. | Host Native UI (Reactive State) |
| Host Native UI (SwiftUI/Compose) | Renders the "Outer Shell" (tabs, nav bar). | Crosswake Core (Observers) |
| Bridge Components | Handle native capabilities (Share, Haptics). | Host Phoenix App (JS/WS) |

### Data Flow (Reactive State)

1. **Native Event:** User toggles "Airplane Mode" on device.
2. **Core Observation:** Crosswake Core detects connectivity change.
3. **Reactive Stream:** Core emits update on `shellState` stream (Combine/Flow).
4. **Host UI Update:** Host SwiftUI/Compose view observing the stream updates its "Offline" banner automatically.

## Patterns to Follow

### Pattern 1: Reactive State Observation
**What:** Native UI observes shell state via persistent streams rather than one-off callbacks.
**When:** Displaying connection status, auth status, or active route metadata.
**Example (Swift):**
```swift
shell.statePublisher
    .map { $0.isOnline }
    .removeDuplicates()
    .receive(on: DispatchQueue.main)
    .assign(to: &$isOnline)
```

### Pattern 2: Component Registration (Not Code Generation)
**What:** Adopters register native components in a builder instead of modifying generated shell code.
**When:** Adding custom native capabilities.
**Example (Kotlin):**
```kotlin
val shell = CrosswakeShell.Builder(context)
    .registerComponent(ShareComponent())
    .build()
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: The "Eject Trap"
**What:** Modifying the internal code of the Crosswake shell library.
**Why bad:** Makes future updates impossible and increases maintenance burden.
**Instead:** Use the provided delegate/builder pattern to customize behavior from the host project.

### Anti-Pattern 2: Global State Fragmentation
**What:** Storing business state in the native shell that isn't reflected on the server.
**Why bad:** Breaks the "Backend Authority" principle.
**Instead:** Use the reactive state API for *shell-specific* metadata (connection, bridge status) and keep business data in Phoenix/LiveView.

## Sources
- `PROJECT.md` v5.0 Architectural Shift
- [SwiftUI State and Data Flow](https://developer.apple.com/documentation/swiftui/state-and-data-flow)
