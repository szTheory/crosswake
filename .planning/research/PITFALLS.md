# Domain Pitfalls: Adoption Evidence Demo App

**Domain:** Phoenix-native Mobile Shells (iOS/Android)
**Researched:** 2026-06-06
**Confidence:** HIGH

## Critical Pitfalls

Mistakes that cause rewrites, integration abandonment, or major production "eject trap" issues.

### Pitfall 1: The "Local Project" Mirage
**What goes wrong:** The Demo App works perfectly because it references the library as a local project sibling (`implementation project(':lib')` or local folder reference in SPM).
**Why it happens:** Developers prioritize speed of iteration during library development.
**Consequences:** Transitive dependencies, public/private header visibility, and ProGuard/R8 rules that work locally fail immediately when the adopter tries to use the published SPM/Maven dependency.
**Prevention:** The Demo App **must** consume the library as a standalone dependency (e.g., via `mavenLocal()` or a specific git tag/branch in SPM) rather than a project reference.
**Detection:** CI should fail if the Demo App includes a direct project reference to the library core.

### Pitfall 2: Reactive State "Zombies" & Leaks
**What goes wrong:** Reactive streams (Combine `AnyCancellable`, Kotlin `Flow` collectors) are created during bridge initialization but never disposed of when the WebView reloads or the View Controller is dismissed.
**Why it happens:** WebView-centric UIs often have a different lifecycle than the native container. A "Reactive State API" that exposes shell state to the host UI is particularly prone to this.
**Consequences:** Memory leaks, duplicate event processing, and crashes when an observer tries to update a dismissed UI element.
**Prevention:**
- **iOS:** Use `[weak self]` in all `sink` closures. Bind the lifecycle of observers to the `ActivationCoordinator` or a specific `BridgeComponent` lifecycle.
- **Android:** Use `collectAsStateWithLifecycle()` or `repeatOnLifecycle` to ensure collection stops when the app is backgrounded.
**Detection:** Run the demo app through Xcode Memory Graph or Android Studio Profiler; reload the WebView 10 times and check for increasing instance counts of bridge-related classes.

### Pitfall 3: Manifest-Capability Desync
**What goes wrong:** The Phoenix server publishes a manifest claiming the app supports `share` and `haptics`, but the native binary used in the demo wasn't compiled with those components registered.
**Why it happens:** Rapid iteration on the server side without a corresponding native rebuild.
**Consequences:** Silent failures. The web UI shows a "Share" button (because the manifest said it's allowed), but tapping it does nothing because the native bridge has no registered handler.
**Prevention:** Implement a "Capability Handshake" on launch. Native should announce its *actual* registered capabilities to the bridge; the web layer should use this "Local Truth" to hide/show UI, even if the "Manifest Truth" (server) says otherwise.
**Detection:** Use `mix keelway.doctor` or a native debug overlay to highlight mismatches between "Manifest Claims" and "Active Capabilities".

---

## Moderate Pitfalls

### Pitfall 1: Redundant UI "Double Vision"
**What goes wrong:** A screen shows both a native navigation bar button and a web-rendered button for the same action (e.g., "Save").
**Prevention:** The demo app should demonstrate idiomatic use of CSS classes (like `.native-only` / `.web-only`) and the `Keelway-Platform` header to conditionally render or hide elements based on the active runtime.

### Pitfall 2: Threading Assumption Crashes
**What goes wrong:** The Bridge receives a message on a background thread (common in networking/Kotlin flows) and tries to update a native UI element or the WebView without switching to the Main thread.
**Prevention:** Ensure the `BridgeChannel` or `ActivationCoordinator` explicitly dispatches bridge callbacks to the Main thread before handing them to host UI observers.

---

## Minor Pitfalls

### Pitfall 1: "Kitchen Sink" Obscurity
**What goes wrong:** The demo app is one massive file that shows every feature at once.
**Prevention:** Break the "Adoption Evidence" into clear, copy-pasteable feature slices (e.g., `BasicNavigation`, `ReactiveStateSync`, `NativeCapabilityBridge`).

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| **SPM/Maven Integration** | Transitive Dependency Conflict | Use `compileOnly` for optional dependencies; test with a "clean" host project. |
| **Reactive State API** | Main-Thread Violation | Wrap bridge-to-UI updates in `DispatchQueue.main.async` or `withContext(Dispatchers.Main)`. |
| **Demo App Bootstrap** | Hardcoded Base URLs | Use environment-based configuration for the Phoenix endpoint to allow easy local testing. |
| **Capability Demo** | Silent Bridge Failure | Implement a "Bridge Logger" in the demo app that visually shows messages flowing between Web and Native. |

## Sources

- [Hotwire Native Bridge Components Pitfalls](https://jessewaites.com/hotwire-native-bridge-components)
- [Android Maven Central Publishing (2025)](https://central.sonatype.org/publish/publish-portal/)
- [Swift Package Manager Binary Targets Guide](https://developer.apple.com/documentation/swift_packages/distributing_binary_frameworks_as_swift_packages)
- [Reactive State Leaks (Combine/Flows)](https://medium.com/android-news/collecting-flows-safely-in-jetpack-compose-7a102061f102)
