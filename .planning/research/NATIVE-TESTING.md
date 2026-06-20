# Native Shell-Core Package Behavioral Testing

**Project:** Crosswake v14.0 Runtime Contract Confidence
**Date:** 2026-06-20
**Scope:** Behavioral test architecture for `crosswake-shell-core-ios` (SwiftPM) and `crosswake-shell-core-android` (Maven Central)

---

## 1. The Problem Statement

Both packages currently have one test file each that asserts almost nothing:

- iOS: `CrosswakeShellCoreTests.swift` — empty `XCTestCase` subclass
- Android: `CrosswakeShellConfigTest.kt` — three smoke tests for `registeredCapabilities` only

The real behavioral proof lives in checked-in example host integration tests that require a live Phoenix server and a simulator/emulator. That means:

- The published packages make no self-contained contract guarantee
- A bridge protocol version bump (`1.0.0` → `1.1.0`) can silently drift between Elixir, the packages, and their host tests
- A contributor adding a new bridge command has no obvious place to add a cross-runtime conformance check

The goal is deterministic, fast behavioral tests that run on every `swift package test` / `./gradlew test` without a server, simulator, or emulator.

---

## 2. The Core Architectural Insight: What Already Exists

Reading the source code, the seams are already nearly correct. The critical observation is:

**`BridgeChannel.evaluate()` on both platforms takes a `BridgeRequestEnvelope` (a plain struct/data class) and returns a `BridgeReplyEnvelope` (iOS) or a JSON string (Android).** No WebView is required. The `WKScriptMessageHandler` conformance and `WebViewCompat.addWebMessageListener` are thin I/O wrappers around `evaluate()`.

On Android, `evaluateForTesting(request: BridgeRequestEnvelope): String` already exists as a testing seam — it calls `evaluate()` directly and errors on deferred results. This is the right pattern.

On iOS, `evaluate(_ request: BridgeRequestEnvelope, completion: @escaping (BridgeReplyEnvelope) -> Void)` is already `public`. No subclass or mock of `WKWebView` is needed.

For `ActivationCoordinator`, `resolve(request:manifest:)` is already `public` on iOS and `private` on Android (but can be exercised through `activate()`). No bundle loading is required: both coordinators take injected `manifestLoader` and `requestLoader` closures.

**Conclusion: almost no new seam work is needed. The test architecture is mostly a matter of writing the tests and adding the shared vector file.**

---

## 3. Swift Testing: XCTest vs swift-testing

### Recommendation: XCTest now, swift-testing for new test files going forward

| Criterion | XCTest | swift-testing (`@Test`/`#expect`) |
|-----------|--------|----------------------------------|
| Linux SwiftPM CI support | Full (required for pure-JVM CI) | Full as of Swift 6.0+ |
| macOS CI support | Full | Full |
| Async test support | `XCTestExpectation` / `async throws` | `@Test` functions are natively async |
| Error assertion | `XCTAssertThrowsError` | `#expect(throws:)` |
| Parameterized tests | Manual loop or `XCTestCase` overrides | `@Test(arguments:)` — native, clean |
| Swift 5.9 (minimum in Package.swift) | Full | Partial — requires 5.10+ for stability |
| IDE integration (Xcode 15/16) | Full | Full for Xcode 16+ |

**Use XCTest for the Package.swift minimum tools version of 5.9.** The package declares `swift-tools-version: 5.9` and `.iOS(.v15)` / `.macOS(.v12)`. swift-testing ships stable in Swift 5.10 and is available as a package in 5.9 but requires adding `swift-testing` as a package dependency and is not yet universally supported in the SwiftPM Linux CI matrix that GitHub Actions uses without explicit toolchain pinning. Use XCTest for the conformance test suite. An upgrade path to swift-testing can happen when the minimum tools version bumps.

**What runs on Linux SwiftPM CI vs needs macOS:**

- `ActivationCoordinator.resolve()` — runs on Linux (pure Swift, no UIKit/AppKit)
- `BridgeChannel.evaluate()` — the `evaluate()` function itself runs on Linux but the class imports `WebKit` and `UIKit` inside `#if canImport(UIKit)`. The `WKScriptMessageHandler` conformance requires macOS/iOS. The solution: extract `evaluate()` into a testable non-WK type (see Section 6)
- `PackStore` — imports `SwiftUI` for `@Published`. SwiftUI is not available on Linux. `PackStore` needs `#if canImport(SwiftUI)` guards or a test-double `blockingStatus` that takes `[RequiredPackStatus]` directly (see Section 6)
- `ActivationCoordinator` — imports `SwiftUI` for `@Published`. Same issue. The `resolve()` method itself is pure logic and can be tested on macOS where SwiftUI is available. For Linux, an alternative is to test `resolve()` as a static function extracted from the class

**Pragmatic CI split for iOS:**
- `swift test --filter BridgeConformanceTests` runs on `ubuntu-latest` only for the bridge eval logic extracted to a Linux-safe module
- Full `swift test` runs on `macos-latest` for all tests including activation coordinator

### Concrete Swift test examples (XCTest)

```swift
// Tests/CrosswakeShellCoreTests/BridgeConformanceTests.swift
import XCTest
@testable import CrosswakeShellCore

final class BridgeConformanceTests: XCTestCase {

    // MARK: - Helpers

    func makeSession(
        bridgeProtocolVersion: String = "1.1.0",
        nativeRuntimeVersion: String = "1.0.0",
        routeID: String = "dashboard",
        allowedOrigin: URL = URL(string: "https://app.example.com")!,
        capabilities: [String: String] = ["app.info.get": "1"],
        installedPacks: [String: String] = [:],
        routeRequiredPacks: [String] = []
    ) -> LiveViewSession {
        LiveViewSession(
            routeID: routeID,
            url: URL(string: "https://app.example.com/dashboard")!,
            allowedOrigin: allowedOrigin,
            bridgeProtocolVersion: bridgeProtocolVersion,
            nativeRuntimeVersion: nativeRuntimeVersion,
            threadID: "test-thread-id",
            installedPacks: installedPacks,
            routeRequiredPacks: routeRequiredPacks,
            capabilities: capabilities,
            declaredTransfers: []
        )
    }

    func makeRequest(
        command: String = "app.info.get",
        capability: String = "app.info.get",
        version: String = "1.1.0",
        nativeRuntimeVersion: String = "1.0.0",
        routeID: String = "dashboard",
        activeRouteID: String = "dashboard",
        origin: String = "https://app.example.com",
        capabilities: [String: String] = ["app.info.get": "1"],
        installedPacks: [String: String] = [:]
    ) -> BridgeRequestEnvelope {
        BridgeRequestEnvelope(
            protocolName: "crosswake.bridge",
            version: version,
            command: command,
            capability: capability,
            routeID: routeID,
            activeRouteID: activeRouteID,
            origin: origin,
            nativeRuntimeVersion: nativeRuntimeVersion,
            correlationID: "test-correlation-id",
            capabilities: capabilities,
            installedPacks: installedPacks,
            payload: [:]
        )
    }

    func makeAppInfoDelegate() -> AppInfoDelegate {
        final class Stub: AppInfoDelegate {
            func getAppInfo() -> [String: String] { ["version": "1.0.0", "build": "42"] }
        }
        return Stub()
    }

    // MARK: - Activation success

    func test_activation_liveView_resolves_known_route() {
        let manifest = ShellManifest(routes: [
            "dashboard": .init(id: "dashboard", path: "/dashboard", runtime: "live_view",
                               entry: "internal_only", capabilities: [], packs: [],
                               transfers: [], allowlistedOrigins: ["https://app.example.com"])
        ])
        let request = ActivationRequest(
            routeID: "dashboard", url: nil, source: .coldStart,
            origin: "https://app.example.com", manifestSource: .bundled,
            bridgeProtocolVersion: "1.1.0", nativeRuntimeVersion: "1.0.0",
            correlationID: "c1", capabilities: [:]
        )
        let coordinator = ActivationCoordinator(
            manifestLoader: { manifest },
            requestLoader: { request },
            packStore: PackStore(requiredVersions: [:], inventory: []),
            config: CrosswakeShellConfig()
        )

        let result = coordinator.resolve(request: request, manifest: manifest)

        guard case let .liveView(session) = result else {
            XCTFail("Expected liveView, got \(result)")
            return
        }
        XCTAssertEqual(session.routeID, "dashboard")
        XCTAssertEqual(session.bridgeProtocolVersion, "1.1.0")
    }

    // MARK: - Activation denial: inactive route

    func test_activation_denies_unknown_route() {
        let manifest = ShellManifest(routes: [:])
        let request = ActivationRequest(
            routeID: "unknown-route", url: nil, source: .coldStart,
            origin: "https://app.example.com", manifestSource: .bundled,
            bridgeProtocolVersion: "1.1.0", nativeRuntimeVersion: "1.0.0",
            correlationID: "c1", capabilities: [:]
        )
        let coordinator = ActivationCoordinator(
            manifestLoader: { manifest },
            requestLoader: { request },
            packStore: PackStore(requiredVersions: [:], inventory: []),
            config: CrosswakeShellConfig()
        )

        let result = coordinator.resolve(request: request, manifest: manifest)

        guard case let .denied(denial) = result else {
            XCTFail("Expected denied, got \(result)")
            return
        }
        XCTAssertEqual(denial.reason, .inactiveRoute)
    }

    // MARK: - Activation denial: origin not allowlisted

    func test_activation_denies_non_allowlisted_origin() {
        let manifest = ShellManifest(routes: [
            "dashboard": .init(id: "dashboard", path: "/dashboard", runtime: "live_view",
                               entry: "internal_only", capabilities: [], packs: [],
                               transfers: [], allowlistedOrigins: ["https://trusted.example.com"])
        ])
        let request = ActivationRequest(
            routeID: "dashboard", url: nil, source: .coldStart,
            origin: "https://attacker.example.com", manifestSource: .bundled,
            bridgeProtocolVersion: "1.1.0", nativeRuntimeVersion: "1.0.0",
            correlationID: "c1", capabilities: [:]
        )
        let coordinator = ActivationCoordinator(
            manifestLoader: { manifest },
            requestLoader: { request },
            packStore: PackStore(requiredVersions: [:], inventory: []),
            config: CrosswakeShellConfig()
        )

        let result = coordinator.resolve(request: request, manifest: manifest)

        guard case let .denied(denial) = result else {
            XCTFail("Expected denied, got \(result)")
            return
        }
        XCTAssertEqual(denial.reason, .originDenied)
    }

    // MARK: - Activation denial: external entry not declared

    func test_activation_denies_deeplink_to_internal_only_route() {
        let manifest = ShellManifest(routes: [
            "admin": .init(id: "admin", path: "/admin", runtime: "live_view",
                           entry: "internal_only", capabilities: [], packs: [],
                           transfers: [], allowlistedOrigins: ["https://app.example.com"])
        ])
        let request = ActivationRequest(
            routeID: "admin", url: URL(string: "https://app.example.com/admin"),
            source: .deepLink, origin: "https://app.example.com",
            manifestSource: .bundled, bridgeProtocolVersion: "1.1.0",
            nativeRuntimeVersion: "1.0.0", correlationID: "c1", capabilities: [:]
        )
        let coordinator = ActivationCoordinator(
            manifestLoader: { manifest },
            requestLoader: { request },
            packStore: PackStore(requiredVersions: [:], inventory: []),
            config: CrosswakeShellConfig()
        )

        let result = coordinator.resolve(request: request, manifest: manifest)

        guard case let .denied(denial) = result else {
            XCTFail("Expected denied, got \(result)")
            return
        }
        XCTAssertEqual(denial.reason, .externalEntryDenied)
    }

    // MARK: - Activation: missing pack blocks activation

    func test_activation_blocks_when_required_pack_missing() {
        let manifest = ShellManifest(routes: [
            "flashcards": .init(id: "flashcards", path: "/flashcards", runtime: "live_view",
                                entry: "internal_only", capabilities: [],
                                packs: ["spanish-pack@1.0.0"],
                                transfers: [], allowlistedOrigins: ["https://app.example.com"])
        ])
        let request = ActivationRequest(
            routeID: "flashcards", url: nil, source: .coldStart,
            origin: "https://app.example.com", manifestSource: .bundled,
            bridgeProtocolVersion: "1.1.0", nativeRuntimeVersion: "1.0.0",
            correlationID: "c1", installedPacks: [:], capabilities: [:]
        )
        let coordinator = ActivationCoordinator(
            manifestLoader: { manifest },
            requestLoader: { request },
            packStore: PackStore(requiredVersions: ["spanish-pack": "1.0.0"], inventory: []),
            config: CrosswakeShellConfig()
        )

        let result = coordinator.resolve(request: request, manifest: manifest)

        guard case .requiredPack = result else {
            XCTFail("Expected requiredPack, got \(result)")
            return
        }
    }
}

// Tests/CrosswakeShellCoreTests/BridgeChannelEvalTests.swift
final class BridgeChannelEvalTests: XCTestCase {

    // MARK: - Bridge success

    func test_bridge_appInfoGet_succeeds_when_delegate_configured() {
        let appInfoStub = makeAppInfoDelegate()
        let config = CrosswakeShellConfig(appInfoDelegate: appInfoStub)
        let session = makeSession(capabilities: ["app.info.get": "1"])
        let channel = BridgeChannel(session: session, transferCoordinator: nil,
                                    replySink: { _ in }, config: config)
        let request = makeRequest(command: "app.info.get", capability: "app.info.get",
                                  capabilities: ["app.info.get": "1"])

        var reply: BridgeReplyEnvelope?
        channel.evaluate(request) { reply = $0 }

        XCTAssertEqual(reply?.status, "ok")
        XCTAssertEqual(reply?.command, "app.info.get")
    }

    // MARK: - Bridge denial: protocol version mismatch

    func test_bridge_denies_wrong_protocol_version() {
        let session = makeSession(bridgeProtocolVersion: "1.1.0")
        let channel = BridgeChannel(session: session, transferCoordinator: nil,
                                    replySink: { _ in }, config: CrosswakeShellConfig())
        let request = makeRequest(version: "1.0.0")   // stale version

        var reply: BridgeReplyEnvelope?
        channel.evaluate(request) { reply = $0 }

        XCTAssertEqual(reply?.status, "deny")
        XCTAssertEqual(reply?.denial?.denial.reason, "compatibility_mismatch")
    }

    // MARK: - Bridge denial: inactive route

    func test_bridge_denies_request_from_wrong_route() {
        let session = makeSession(routeID: "dashboard")
        let channel = BridgeChannel(session: session, transferCoordinator: nil,
                                    replySink: { _ in }, config: CrosswakeShellConfig())
        let request = makeRequest(command: "app.info.get", capability: "app.info.get",
                                  routeID: "settings", activeRouteID: "settings")

        var reply: BridgeReplyEnvelope?
        channel.evaluate(request) { reply = $0 }

        XCTAssertEqual(reply?.status, "deny")
        XCTAssertEqual(reply?.denial?.denial.reason, "inactive_route")
    }

    // MARK: - Bridge denial: origin not allowlisted

    func test_bridge_denies_request_from_wrong_origin() {
        let session = makeSession(allowedOrigin: URL(string: "https://trusted.example.com")!)
        let channel = BridgeChannel(session: session, transferCoordinator: nil,
                                    replySink: { _ in }, config: CrosswakeShellConfig())
        let request = makeRequest(origin: "https://attacker.example.com")

        var reply: BridgeReplyEnvelope?
        channel.evaluate(request) { reply = $0 }

        XCTAssertEqual(reply?.status, "deny")
        XCTAssertEqual(reply?.denial?.denial.reason, "origin_denied")
    }

    // MARK: - Bridge denial: undeclared command

    func test_bridge_denies_unknown_command() {
        let session = makeSession()
        let channel = BridgeChannel(session: session, transferCoordinator: nil,
                                    replySink: { _ in }, config: CrosswakeShellConfig())
        let request = makeRequest(command: "xss.inject", capability: "xss.inject",
                                  capabilities: ["xss.inject": "1"])

        var reply: BridgeReplyEnvelope?
        channel.evaluate(request) { reply = $0 }

        XCTAssertEqual(reply?.status, "deny")
        XCTAssertEqual(reply?.denial?.denial.reason, "undeclared_capability")
    }

    // MARK: - Bridge denial: capability version mismatch

    func test_bridge_denies_mismatched_capability_version() {
        // session declares "app.info.get": "2", request carries "1"
        let session = makeSession(capabilities: ["app.info.get": "2"])
        let config = CrosswakeShellConfig(appInfoDelegate: makeAppInfoDelegate())
        let channel = BridgeChannel(session: session, transferCoordinator: nil,
                                    replySink: { _ in }, config: config)
        let request = makeRequest(capabilities: ["app.info.get": "1"])

        var reply: BridgeReplyEnvelope?
        channel.evaluate(request) { reply = $0 }

        XCTAssertEqual(reply?.status, "deny")
        XCTAssertEqual(reply?.denial?.denial.reason, "unavailable_capability")
    }

    // MARK: - Bridge denial: pack incompatible

    func test_bridge_denies_when_required_pack_not_installed() {
        let session = LiveViewSession(
            routeID: "flashcards",
            url: URL(string: "https://app.example.com/flashcards")!,
            allowedOrigin: URL(string: "https://app.example.com")!,
            bridgeProtocolVersion: "1.1.0",
            nativeRuntimeVersion: "1.0.0",
            threadID: "t1",
            installedPacks: [:],  // nothing installed
            routeRequiredPacks: ["spanish-pack@1.0.0"],
            capabilities: ["app.info.get": "1"],
            declaredTransfers: []
        )
        let config = CrosswakeShellConfig(appInfoDelegate: makeAppInfoDelegate())
        let channel = BridgeChannel(session: session, transferCoordinator: nil,
                                    replySink: { _ in }, config: config)
        let request = makeRequest(routeID: "flashcards", activeRouteID: "flashcards",
                                  capabilities: ["app.info.get": "1"])

        var reply: BridgeReplyEnvelope?
        channel.evaluate(request) { reply = $0 }

        XCTAssertEqual(reply?.status, "deny")
        XCTAssertEqual(reply?.denial?.denial.reason, "pack_incompatible")
    }

    // MARK: - Bridge denial: delegate not configured

    func test_bridge_denies_appInfoGet_when_delegate_missing() {
        let session = makeSession(capabilities: ["app.info.get": "1"])
        let config = CrosswakeShellConfig()  // no appInfoDelegate
        let channel = BridgeChannel(session: session, transferCoordinator: nil,
                                    replySink: { _ in }, config: config)
        let request = makeRequest(capabilities: ["app.info.get": "1"])

        var reply: BridgeReplyEnvelope?
        channel.evaluate(request) { reply = $0 }

        XCTAssertEqual(reply?.status, "deny")
        XCTAssertEqual(reply?.denial?.denial.reason, "undeclared_capability")
    }
}
```

---

## 4. Kotlin/Android Testing: Pure JVM JUnit

### Recommendation: JUnit 4 (already in dependencies) + kotlinx-coroutines-test for the current published library; add JUnit 5 via JUnit Platform if test ergonomics matter more than Maven Central compat later

| Criterion | JUnit 4 (`junit:junit:4.13.2`) | JUnit 5 (JUnit Platform) | Robolectric | Instrumented |
|-----------|-------------------------------|--------------------------|-------------|--------------|
| Already in build.gradle.kts | Yes | No (add `junit-vintage`) | No | No |
| Requires emulator | No | No | No | Yes — blocked |
| Android API classes (`Context`, `Intent`) | No | No | Simulates them | Real |
| `ActivationCoordinator`, `BridgeChannel` | Full (no Context) | Full | Full | Full |
| `PackStore.bundled()` | Blocked (uses Context) | Blocked | Works | Works |
| `PackStore.inMemory()` | Full — already exists | Full | Full | Full |
| `StateFlow` / `SharedFlow` testing | `runBlocking` + `Turbine` or manual collect | Same | Same | Same |
| Published library norm | JUnit 4 common | JUnit 5 growing | Rare for libs | Rare for libs |

**Use JUnit 4 with `kotlinx-coroutines-test` and `app.cash.turbine:turbine`.** Robolectric is not appropriate for a published library's own tests — it increases the build surface and pulls in a large Android framework simulator that adopters should not need to understand. `PackStore.inMemory()` (already exists in the source) is the correct escape hatch for any test that needs PackStore without `Context`.

**BridgeChannel has no Android-specific imports in its `evaluate()` path** — the `attach()` method references `WebView` and `WebViewCompat`, but `evaluate()` and `evaluateForTesting()` only use standard Kotlin/Java types. All bridge conformance tests run on the JVM with zero Robolectric overhead.

**ActivationCoordinator** takes injected `manifestLoader` and `requestLoader` lambdas. The only Android-specific use is `ActivationFixtures` (which uses `Context`) and `PackStore.bundled()`. Tests inject plain in-memory versions of both. `PackStore.inMemory()` already exists.

### Concrete Kotlin test examples (JUnit 4)

```kotlin
// src/test/java/dev/crosswake/shell/core/BridgeConformanceTest.kt
package dev.crosswake.shell.core

import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

class BridgeConformanceTest {

    // ── Helpers ──────────────────────────────────────────────────────────

    private fun makeSession(
        bridgeProtocolVersion: String = "1.1.0",
        nativeRuntimeVersion: String = "1.0.0",
        routeId: String = "dashboard",
        allowedOrigin: String = "https://app.example.com",
        capabilities: Map<String, String> = mapOf("app.info.get" to "1"),
        installedPacks: Map<String, String> = emptyMap(),
        routeRequiredPacks: List<String> = emptyList()
    ) = LiveViewSession(
        routeId = routeId,
        url = "https://app.example.com/dashboard",
        allowedOrigin = allowedOrigin,
        bridgeProtocolVersion = bridgeProtocolVersion,
        nativeRuntimeVersion = nativeRuntimeVersion,
        threadId = "test-thread-id",
        installedPacks = installedPacks,
        routeRequiredPacks = routeRequiredPacks,
        capabilities = capabilities,
        declaredTransfers = emptyList()
    )

    private fun makeRequest(
        command: String = "app.info.get",
        capability: String = "app.info.get",
        version: String = "1.1.0",
        nativeRuntimeVersion: String = "1.0.0",
        routeId: String = "dashboard",
        activeRouteId: String = "dashboard",
        origin: String = "https://app.example.com",
        capabilities: Map<String, String> = mapOf("app.info.get" to "1"),
        installedPacks: Map<String, String> = emptyMap()
    ) = BridgeRequestEnvelope(
        protocol = "crosswake.bridge",
        version = version,
        command = command,
        capability = capability,
        routeId = routeId,
        activeRouteId = activeRouteId,
        origin = origin,
        nativeRuntimeVersion = nativeRuntimeVersion,
        correlationId = "test-correlation-id",
        capabilities = capabilities,
        installedPacks = installedPacks,
        payload = emptyMap()
    )

    private fun stubAppInfoDelegate() = object : AppInfoDelegate {
        override fun getAppInfo() = mapOf("version" to "1.0.0", "build" to "42")
    }

    private fun parseReply(json: String) = JSONObject(json)

    // ── Bridge success ────────────────────────────────────────────────────

    @Test
    fun `bridge appInfoGet succeeds when delegate configured`() {
        val config = CrosswakeShellConfig(appInfoDelegate = stubAppInfoDelegate())
        val channel = BridgeChannel(makeSession(), transferCoordinator = null, config = config)
        val reply = parseReply(channel.evaluateForTesting(makeRequest()))
        assertEquals("ok", reply.getString("status"))
        assertEquals("app.info.get", reply.getString("command"))
    }

    // ── Bridge denial: protocol version mismatch ─────────────────────────

    @Test
    fun `bridge denies request with wrong protocol version`() {
        val session = makeSession(bridgeProtocolVersion = "1.1.0")
        val channel = BridgeChannel(session, transferCoordinator = null, config = CrosswakeShellConfig())
        val request = makeRequest(version = "1.0.0")   // stale
        val reply = parseReply(channel.evaluateForTesting(request))
        assertEquals("deny", reply.getString("status"))
        assertEquals("compatibility_mismatch", reply.getJSONObject("denial").getJSONObject("denial").getString("reason"))
    }

    // ── Bridge denial: inactive route ────────────────────────────────────

    @Test
    fun `bridge denies request scoped to wrong route`() {
        val session = makeSession(routeId = "dashboard")
        val channel = BridgeChannel(session, transferCoordinator = null, config = CrosswakeShellConfig())
        val request = makeRequest(routeId = "settings", activeRouteId = "settings")
        val reply = parseReply(channel.evaluateForTesting(request))
        assertEquals("deny", reply.getString("status"))
        assertEquals("inactive_route", reply.getJSONObject("denial").getJSONObject("denial").getString("reason"))
    }

    // ── Bridge denial: origin not allowlisted ────────────────────────────

    @Test
    fun `bridge denies request from non-allowlisted origin`() {
        val session = makeSession(allowedOrigin = "https://trusted.example.com")
        val channel = BridgeChannel(session, transferCoordinator = null, config = CrosswakeShellConfig())
        val request = makeRequest(origin = "https://attacker.example.com")
        val reply = parseReply(channel.evaluateForTesting(request))
        assertEquals("deny", reply.getString("status"))
        assertEquals("origin_denied", reply.getJSONObject("denial").getJSONObject("denial").getString("reason"))
    }

    // ── Bridge denial: undeclared command ────────────────────────────────

    @Test
    fun `bridge denies unknown bridge command`() {
        val session = makeSession()
        val channel = BridgeChannel(session, transferCoordinator = null, config = CrosswakeShellConfig())
        val request = makeRequest(command = "xss.inject", capability = "xss.inject",
                                  capabilities = mapOf("xss.inject" to "1"))
        val reply = parseReply(channel.evaluateForTesting(request))
        assertEquals("deny", reply.getString("status"))
        assertEquals("undeclared_capability", reply.getJSONObject("denial").getJSONObject("denial").getString("reason"))
    }

    // ── Bridge denial: capability version mismatch ───────────────────────

    @Test
    fun `bridge denies when request carries stale capability version`() {
        val session = makeSession(capabilities = mapOf("app.info.get" to "2"))
        val config = CrosswakeShellConfig(appInfoDelegate = stubAppInfoDelegate())
        val channel = BridgeChannel(session, transferCoordinator = null, config = config)
        val request = makeRequest(capabilities = mapOf("app.info.get" to "1"))
        val reply = parseReply(channel.evaluateForTesting(request))
        assertEquals("deny", reply.getString("status"))
        assertEquals("unavailable_capability", reply.getJSONObject("denial").getJSONObject("denial").getString("reason"))
    }

    // ── Bridge denial: pack incompatible ─────────────────────────────────

    @Test
    fun `bridge denies when required pack not installed`() {
        val session = makeSession(
            routeId = "flashcards",
            capabilities = mapOf("app.info.get" to "1"),
            installedPacks = emptyMap(),
            routeRequiredPacks = listOf("spanish-pack@1.0.0")
        )
        val config = CrosswakeShellConfig(appInfoDelegate = stubAppInfoDelegate())
        val channel = BridgeChannel(session, transferCoordinator = null, config = config)
        val request = makeRequest(routeId = "flashcards", activeRouteId = "flashcards",
                                  capabilities = mapOf("app.info.get" to "1"))
        val reply = parseReply(channel.evaluateForTesting(request))
        assertEquals("deny", reply.getString("status"))
        assertEquals("pack_incompatible", reply.getJSONObject("denial").getJSONObject("denial").getString("reason"))
    }

    // ── Bridge denial: delegate not configured ───────────────────────────

    @Test
    fun `bridge denies appInfoGet when delegate not configured`() {
        val session = makeSession(capabilities = mapOf("app.info.get" to "1"))
        val config = CrosswakeShellConfig()  // no delegate
        val channel = BridgeChannel(session, transferCoordinator = null, config = config)
        val request = makeRequest(capabilities = mapOf("app.info.get" to "1"))
        val reply = parseReply(channel.evaluateForTesting(request))
        assertEquals("deny", reply.getString("status"))
    }
}

// src/test/java/dev/crosswake/shell/core/ActivationConformanceTest.kt
class ActivationConformanceTest {

    private fun makeManifest(
        routeId: String = "dashboard",
        runtime: String = "live_view",
        entry: String = "internal_only",
        packs: List<String> = emptyList(),
        allowlistedOrigins: List<String> = listOf("https://app.example.com"),
        nativeRuntimeVersion: String = "1.0.0"
    ) = ShellManifest(
        routes = mapOf(routeId to ShellManifest.Route(
            id = routeId, path = "/$routeId", runtime = runtime,
            entry = entry, capabilities = emptyList(),
            packs = packs, transfers = emptyList(),
            allowlistedOrigins = allowlistedOrigins
        )),
        nativeRuntimeVersion = nativeRuntimeVersion
    )

    private fun makeRequest(
        routeId: String = "dashboard",
        source: ActivationSource = ActivationSource.COLD_START,
        origin: String = "https://app.example.com",
        nativeRuntimeVersion: String = "1.0.0"
    ) = ActivationRequest(
        routeId = routeId, url = null, source = source,
        origin = origin, manifestSource = ManifestSource.BUNDLED,
        bridgeProtocolVersion = "1.1.0", nativeRuntimeVersion = nativeRuntimeVersion,
        correlationId = "c1"
    )

    private fun makeCoordinator(
        manifest: ShellManifest,
        request: ActivationRequest,
        packStore: dev.crosswake.shell.core.packs.PackStore =
            dev.crosswake.shell.core.packs.PackStore.inMemory(emptyMap())
    ) = ActivationCoordinator(
        config = CrosswakeShellConfig(),
        manifestLoader = { manifest },
        requestLoader = { request },
        packStore = packStore
    )

    @Test
    fun `activation resolves live_view route to LiveView presentation`() {
        val manifest = makeManifest()
        val request = makeRequest()
        val coordinator = makeCoordinator(manifest, request)
        val result = coordinator.activate(request)
        assertTrue("Expected LiveView but got $result", result is ShellPresentation.LiveView)
        assertEquals("dashboard", (result as ShellPresentation.LiveView).session.routeId)
    }

    @Test
    fun `activation denies unknown route with inactive_route reason`() {
        val manifest = makeManifest()
        val request = makeRequest(routeId = "ghost-route")
        val coordinator = makeCoordinator(manifest, request)
        val result = coordinator.activate(request)
        assertTrue(result is ShellPresentation.Denied)
        assertEquals(RouteDenialReason.INACTIVE_ROUTE, (result as ShellPresentation.Denied).denial.reason)
    }

    @Test
    fun `activation denies deep link to internal_only route`() {
        val manifest = makeManifest(entry = "internal_only")
        val request = makeRequest(routeId = "dashboard", source = ActivationSource.DEEP_LINK)
        val coordinator = makeCoordinator(manifest, request)
        val result = coordinator.activate(request)
        assertTrue(result is ShellPresentation.Denied)
        assertEquals(RouteDenialReason.EXTERNAL_ENTRY_DENIED, (result as ShellPresentation.Denied).denial.reason)
    }

    @Test
    fun `activation denies when origin not in allowlisted origins`() {
        val manifest = makeManifest(allowlistedOrigins = listOf("https://trusted.example.com"))
        val request = makeRequest(origin = "https://evil.example.com")
        val coordinator = makeCoordinator(manifest, request)
        val result = coordinator.activate(request)
        assertTrue(result is ShellPresentation.Denied)
        assertEquals(RouteDenialReason.ORIGIN_DENIED, (result as ShellPresentation.Denied).denial.reason)
    }

    @Test
    fun `activation blocks on missing required pack`() {
        val manifest = makeManifest(packs = listOf("spanish-pack@1.0.0"))
        val request = makeRequest()
        val packStore = dev.crosswake.shell.core.packs.PackStore.inMemory(
            requiredVersions = mapOf("spanish-pack" to "1.0.0"),
            inventory = emptyList()
        )
        val coordinator = makeCoordinator(manifest, request, packStore)
        val result = coordinator.activate(request)
        assertTrue(result is ShellPresentation.RequiredPack)
    }

    @Test
    fun `activation denies when manifest nativeRuntimeVersion does not match request`() {
        val manifest = makeManifest(nativeRuntimeVersion = "2.0.0")
        val request = makeRequest(nativeRuntimeVersion = "1.0.0")
        val coordinator = makeCoordinator(manifest, request)
        val result = coordinator.activate(request)
        assertTrue(result is ShellPresentation.Denied)
        assertEquals(RouteDenialReason.COMPATIBILITY_MISMATCH, (result as ShellPresentation.Denied).denial.reason)
    }
}
```

---

## 5. The Shared Conformance Vector Mechanism

This is the highest-leverage architectural decision. Three options:

### Option A: Hand-mirrored test constants in each language

Copy the contract values (`"crosswake.bridge"`, `"1.1.0"`, denial reasons, command strings) into Swift, Kotlin, and Elixir test files separately.

**Pros:** Zero tooling, immediate.
**Cons:** This is exactly how the current `1.0.0`/`1.1.0` drift happened. A version bump in `contract.ex` requires the maintainer to remember to update three files. No test catches the divergence until a runtime failure. This is the status quo and it is broken.

### Option B: Codegen from Elixir contract to native test fixtures

Write a Mix task that reads `Crosswake.Bridge.Contract` and emits a `BridgeContractFixtures.swift` and `BridgeContractFixtures.kt` into the test directories, then CI runs the generator and verifies the output is unchanged.

**Pros:** Elixir is the single source of truth, enforced mechanically.
**Cons:** Codegen adds a new artifact class and a build step. The generated files must be committed (or CI must run Elixir before running Swift/Kotlin tests, which defeats isolation). The generator itself needs tests. This is the right long-term answer for a large multi-SDK project (see OpenTelemetry semantic conventions, gRPC conformance tests) but adds meaningful complexity for a single maintainer.

### Option C: Committed JSON golden vector file, loaded by all three test suites

A single file, e.g. `test/fixtures/bridge_contract_vectors.json`, committed in the monorepo root. The Elixir test suite loads it with `File.read!` and asserts the contract matches. The Swift test suite bundles it as a test resource and loads it with `Bundle.module.url(forResource:)`. The Kotlin test suite loads it from `src/test/resources/`. All three assert the same denial reasons, protocol string, version string, and command list.

**Pros:** One file to update. Git diff shows contract changes. No codegen tooling. Cross-language consistency is enforced by tests in all three runtimes failing on mismatch. A contributor adding a bridge command edits one JSON file and adds one test case in each language.
**Cons:** Loading JSON in tests adds a tiny bit of boilerplate vs inline constants. The file must be in a location reachable from all three test suites (see below).

### Recommendation: Option C — Committed JSON golden vectors

**Place the file at:** `test/fixtures/bridge_contract_vectors.json`

This is within the Elixir test tree (Elixir tests use `test/` by convention), symlinked or referenced from native test resource directories, OR the native packages reference it via a relative path from their test bundle.

**File structure:**

```json
{
  "_comment": "Canonical bridge contract vectors. Edit here, then verify all three test suites pass.",
  "protocol": "crosswake.bridge",
  "version": "1.1.0",
  "commands": [
    "app.info.get",
    "haptics.impact",
    "permissions.status",
    "notifications.token.get",
    "share.invoke",
    "files.pick",
    "transfer.download",
    "transfer.export",
    "transfer.import",
    "transfer.upload.prepare"
  ],
  "denial_reasons": [
    "compatibility_mismatch",
    "inactive_route",
    "origin_denied",
    "undeclared_capability",
    "unavailable_capability",
    "pack_incompatible"
  ],
  "activation_denial_reasons": [
    "compatibility_mismatch",
    "undeclared_capability",
    "unavailable_capability",
    "origin_denied",
    "inactive_route",
    "external_entry_denied",
    "pack_incompatible"
  ],
  "vectors": [
    {
      "id": "bridge_version_mismatch",
      "description": "Request with wrong bridge protocol version is denied with compatibility_mismatch",
      "request_overrides": { "version": "0.9.0" },
      "expected_status": "deny",
      "expected_denial_reason": "compatibility_mismatch"
    },
    {
      "id": "bridge_wrong_route",
      "description": "Request scoped to wrong route is denied with inactive_route",
      "request_overrides": { "route_id": "other-route", "active_route_id": "other-route" },
      "expected_status": "deny",
      "expected_denial_reason": "inactive_route"
    },
    {
      "id": "bridge_wrong_origin",
      "description": "Request from non-allowlisted origin is denied with origin_denied",
      "request_overrides": { "origin": "https://evil.example.com" },
      "expected_status": "deny",
      "expected_denial_reason": "origin_denied"
    },
    {
      "id": "bridge_unknown_command",
      "description": "Request with unknown command is denied with undeclared_capability",
      "request_overrides": { "command": "evil.xss.inject", "capability": "evil.xss.inject" },
      "expected_status": "deny",
      "expected_denial_reason": "undeclared_capability"
    },
    {
      "id": "bridge_stale_capability_version",
      "description": "Request where capability version is behind session is denied with unavailable_capability",
      "request_overrides": { "capabilities": { "app.info.get": "0" } },
      "session_overrides": { "capabilities": { "app.info.get": "1" } },
      "expected_status": "deny",
      "expected_denial_reason": "unavailable_capability"
    },
    {
      "id": "bridge_pack_incompatible",
      "description": "Request where required pack is not installed is denied with pack_incompatible",
      "session_overrides": { "routeRequiredPacks": ["test-pack@1.0.0"], "installedPacks": {} },
      "expected_status": "deny",
      "expected_denial_reason": "pack_incompatible"
    }
  ]
}
```

**How each runtime consumes it:**

- **Elixir:** `ExUnit` test reads `Path.join([File.cwd!(), "test/fixtures/bridge_contract_vectors.json"])` and asserts `Crosswake.Bridge.Contract.version() == json["version"]`, `Crosswake.Bridge.Contract.protocol() == json["protocol"]`, and the commands list matches
- **Swift:** Copy (or symlink) the file into the test bundle resources, or read it via a relative path in the test process working directory (`#file` + relative navigation)
- **Kotlin:** Place at `packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json` and load with `javaClass.getResourceAsStream("/bridge_contract_vectors.json")`

**Contributor workflow when adding a new bridge command:**

1. Add the command to `Crosswake.Bridge.Contract` in `contract.ex`
2. Add it to `bridge_contract_vectors.json` commands array
3. Add it to `BridgeCommand` enum in Swift and Kotlin
4. `mix test` catches missing JSON vector entry
5. `swift test` catches missing enum case or missing test
6. `./gradlew test` catches missing Kotlin coverage

That is the "obvious, low-ceremony place." One JSON file edit with a failing test in all three runtimes as the feedback.

---

## 6. Source Seams to Add

Very minimal source changes are needed. The delegate protocols already exist. The seams are listed in order of priority:

### 6.1 Swift: No new source seams needed for BridgeChannel

`BridgeChannel.evaluate()` is already public and takes a `BridgeRequestEnvelope` directly. Tests call it without a `WKWebView`.

The only constraint: `BridgeChannel` imports `WebKit` and `UIKit`, so tests must run on macOS (not Linux). This is acceptable — macOS runners are standard for SwiftPM CI. The tests are still simulator-free (macOS runner, not iOS Simulator).

### 6.2 Swift: `ActivationCoordinator.resolve()` is already public

No new seam needed. Tests call `resolve(request:manifest:)` directly with in-memory fixtures.

### 6.3 Swift: SwiftUI dependency blocks Linux test runs

`ActivationCoordinator` and `PackStore` both `import SwiftUI` for `@Published` and `ObservableObject`. On Linux, SwiftUI is unavailable. Options:

- **Option A (recommended):** Gate the `@Published` / `ObservableObject` declarations behind `#if canImport(SwiftUI)` / `#if canImport(Combine)` and expose a plain `var presentation: ShellPresentation` on Linux. Tests on Linux get the pure logic without reactive wrappers.
- **Option B:** Accept that all tests run on macOS. This is simpler and consistent with the iOS target. Given the bridge logic is macOS-compatible and the existing Package.swift declares `.macOS(.v12)`, requiring macOS for tests is honest and fine.

**Recommendation: Accept Option B for now.** Run all tests on `macos-latest`. Add a comment in Package.swift noting Linux support for the core types is aspirational. This avoids conditional compilation complexity before the test suite is written.

### 6.4 Android: `evaluateForTesting()` already exists

`BridgeChannel.evaluateForTesting(request)` is already public and already bypasses the WebView I/O layer. No new seam.

### 6.5 Android: `PackStore.inMemory()` already exists

`PackStore.inMemory(requiredVersions, inventory)` is already a public factory that skips `Context`. No new seam.

### 6.6 Android: `ActivationCoordinator` already takes injected loaders

`ActivationCoordinator` already takes `manifestLoader: () -> ShellManifest` and `requestLoader: () -> ActivationRequest`. Tests pass lambdas directly. No new seam.

### 6.7 Android: Missing `testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test")`

Add to `build.gradle.kts`:

```kotlin
testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.3")
testImplementation("app.cash.turbine:turbine:1.1.0")   // optional, for StateFlow testing
```

`runTest` from `kotlinx-coroutines-test` provides a test coroutine scope that advances virtual time, making `PackStore.installRequiredPack()` (which uses `delay()`) testable without real time passing.

---

## 7. The Six Target Behaviors: Test Names and Assertions

| Behavior | Swift test name | Kotlin test name | What it asserts |
|----------|----------------|-----------------|-----------------|
| **Activation success** | `test_activation_liveView_resolves_known_route` | `` `activation resolves live_view route to LiveView presentation` `` | `ShellPresentation.liveView` with correct `routeID`/`routeId`; session carries protocol version from request |
| **Activation failure** | `test_activation_denies_unknown_route` | `` `activation denies unknown route with inactive_route reason` `` | `ShellPresentation.denied` with `reason == .inactiveRoute` / `INACTIVE_ROUTE` |
| **Bridge denial paths** | `test_bridge_denies_wrong_protocol_version` | `` `bridge denies request with wrong protocol version` `` | `status == "deny"`, `denial.reason == "compatibility_mismatch"` |
| **Capability allowlist** | `test_bridge_denies_mismatched_capability_version` | `` `bridge denies when request carries stale capability version` `` | `status == "deny"`, reason `"unavailable_capability"` when session version ≠ request version |
| **Active-route check** | `test_bridge_denies_request_from_wrong_route` | `` `bridge denies request scoped to wrong route` `` | `status == "deny"`, reason `"inactive_route"` when `routeID != session.routeID` |
| **Pack version/installed-pack check** | `test_bridge_denies_when_required_pack_not_installed` + `test_activation_blocks_when_required_pack_missing` | `` `bridge denies when required pack not installed` `` + `` `activation blocks on missing required pack` `` | Bridge: `"pack_incompatible"`; Activation: `ShellPresentation.requiredPack` / `RequiredPack` |
| **Delegate behavior** | `test_bridge_appInfoGet_succeeds_when_delegate_configured` + `test_bridge_denies_appInfoGet_when_delegate_missing` | `` `bridge appInfoGet succeeds when delegate configured` `` + `` `bridge denies appInfoGet when delegate not configured` `` | When delegate present: `status == "ok"` with payload; when absent: `status == "deny"` |

---

## 8. Lessons From Comparable Native SDKs

### 8.1 Hotwire Turbo Native (turbo-ios, turbo-android) and Strada

Turbo Native's approach to testing the bridge is instructive. In `turbo-ios`, the `VisitableViewController` and `SessionDelegate` protocol are tested with stub implementations — there is no real `WKWebView` in the test suite. The `Session` class takes a `WKWebView` but all behavioral tests run against the delegate protocol and the visit state machine, which are pure Swift.

Strada (turbo bridge-components) tests each bridge component by constructing it with a mock `BridgeComponent.Data` struct and asserting on the resulting `BridgeMessage`. No JavaScript evaluation happens. The test double pattern is: implement the delegate protocol in the test with a trivial `class MockBridgeDelegate: BridgeDelegate { var receivedMessages: [BridgeMessage] = [] }` and verify `receivedMessages.last?.component == "expected"`.

**Copy:** The delegate-protocol stub pattern directly. All six delegate protocols in Crosswake (`AppInfoDelegate`, `HapticsDelegate`, `PermissionStatusDelegate`, `NotificationTokenDelegate`, `ShareDelegate`, `FilesPickDelegate`) are already protocol-typed on both platforms — stubs are trivial anonymous classes (Swift) or object expressions (Kotlin).

**Footgun from Turbo Native:** Early versions of `turbo-ios` shipped with `WKWebView` as a stored property with no injection seam, making behavioral tests impossible. The fix required extracting the transport to a protocol. Crosswake already avoids this — `BridgeChannel.evaluate()` takes a struct, not a WebView.

Joe Masilotti's testing guidance for Turbo Native emphasizes: test the session state machine and visit lifecycle, not the JavaScript evaluation. The equivalent for Crosswake is: test the `evaluate()` dispatch logic and `resolve()` activation logic, not the WK/WebView I/O.

### 8.2 Capacitor / Cordova Plugin Testing

Capacitor's core plugin bridge tests use a `MockCAPBridgeProtocol` that satisfies the `CAPBridgeProtocol` interface without a real WebView. Plugin tests construct a plugin with this mock bridge and call plugin methods directly. The `call.resolve()` / `call.reject()` callbacks are captured in test closures.

The pattern translates directly to Crosswake: `BridgeChannel.evaluate()` is already the equivalent of a plugin method. The `completion` closure is the `call.resolve()` equivalent. No bridge protocol to mock.

**Copy:** The pattern of verifying the denial reason in the reply struct/JSON rather than testing internal dispatch state. Tests should assert `reply.status == "deny"` and `reply.denial.denial.reason == "exact_string"`, not whether a specific `guard` branch fired.

**Footgun from Capacitor:** Version negotiation tests that hardcode the protocol version string in test helpers. When the version bumps, tests pass in CI but the runtime breaks because the test helper still carries the old version. The shared golden vector file (Section 5) directly mitigates this.

### 8.3 Stripe, Segment, Sentry Mobile SDKs

These mature SDKs follow a consistent pattern for published library tests:

- **No emulator/simulator in the main test target.** All behavioral logic runs on the JVM (Android) or macOS (iOS) with protocol stubs. Device features (NFC, camera, push) are behind delegate interfaces that are stubbed in tests.
- **Conformance fixtures are files, not inline constants.** Stripe's mobile SDKs use JSON fixture files in `Tests/Resources/` for API response shapes. When the API changes, the fixture file changes and all tests that load it fail simultaneously.
- **Separate targets for UI tests.** Stripe and Sentry both split their test targets: a `XCTest`/`JUnit` target for behavioral logic (fast, merge-blocking) and a separate UI/integration target (slow, advisory or manual). This maps directly to Crosswake's existing required-vs-advisory CI split.

**Copy:** The fixture-file-per-contract pattern. One file per external contract (bridge contract vectors, activation manifest fixtures).

**Footgun from Sentry:** Overly broad test fakes that test the fake, not the real behavior. A `MockTransport` that always returns success means the error-path tests never exercise real failure modes. In Crosswake: do not mock `BridgeChannel.evaluate()` — call the real `evaluate()` with a fake request. The denial logic being tested is inside `evaluate()`, not in the caller.

### 8.4 Shared Conformance Vectors: Prior Art

**OpenTelemetry Semantic Conventions:** The OTEL project maintains a `semantic-conventions` repository that generates language-specific test fixture files from a single YAML source. The pattern: one authoritative source, language-specific generated outputs, CI verifies generated outputs are up to date. This is Option B from Section 5 at scale. For Crosswake, the Elixir contract is the equivalent of the YAML source.

**protobuf conformance runner:** The protobuf project ships a `conformance/` binary that reads test vectors from standard input and checks serialization/deserialization behavior. Any language's protobuf implementation runs the conformance binary and must produce matching output. The equivalent for Crosswake would be an Elixir-hosted test server that native packages POST requests to and assert responses — closer to integration testing than package unit testing.

**Apple Sign In / Google Sign In:** Both ship language-specific SDKs that share no test infrastructure. Behavioral drift is caught by app developers at runtime, not by conformance tests. This is the current Crosswake situation and it is the reason the `1.0.0`/`1.1.0` drift went undetected.

**Recommendation for Crosswake:** Start with Option C (committed JSON vectors) rather than building a codegen pipeline. The codegen approach (Option B) is the correct long-term answer if the bridge protocol grows substantially or if external SDK authors need to implement conformant bridges. For a single-maintainer project with one Elixir authority and two native platforms, a JSON vector file with three test suites that load it is the right tradeoff.

---

## 9. Source Seams Summary: What to Add vs What Already Exists

### iOS (Swift)

| Seam | Status | Action needed |
|------|--------|--------------|
| `BridgeChannel.evaluate(request:completion:)` public | EXISTS | None — call directly in tests |
| `ActivationCoordinator.resolve(request:manifest:)` public | EXISTS | None — call directly in tests |
| `ActivationCoordinator(manifestLoader:requestLoader:packStore:config:)` init | EXISTS | None — inject closures in tests |
| `PackStore(requiredVersions:inventory:)` init (no Bundle) | EXISTS | None — construct directly |
| Protocol stubs for all six delegate types | MISSING | Add `StubAppInfoDelegate`, etc. as `private` test helpers in test files |
| `bundle_contract_vectors.json` test resource | MISSING | Add to `Tests/CrosswakeShellCoreTests/Resources/` |
| Bridge contract version constant | MISSING | Add `BridgeChannel.protocolVersion = "1.1.0"` to make version assertion drift-proof |

### Android (Kotlin)

| Seam | Status | Action needed |
|------|--------|--------------|
| `BridgeChannel.evaluateForTesting(request)` | EXISTS | None — already public |
| `ActivationCoordinator(config, manifestLoader, requestLoader, packStore)` constructor | EXISTS | None — inject lambdas |
| `PackStore.inMemory(requiredVersions, inventory)` | EXISTS | None — call directly |
| Anonymous delegate implementations | EXISTS (used in `CrosswakeShellConfigTest`) | None — extend pattern |
| `bridge_contract_vectors.json` test resource | MISSING | Add to `src/test/resources/` |
| `kotlinx-coroutines-test` dependency | MISSING | Add to `build.gradle.kts` |
| Bridge contract version constant | MISSING | Add `const val PROTOCOL_VERSION = "1.1.0"` to `BridgeChannel.Companion` |

---

## 10. CI Lane Recommendation

The existing CI architecture has a well-established required-vs-advisory split. The native package tests map cleanly onto it:

| Lane | Runner | Trigger | Merge-blocking | What it runs |
|------|--------|---------|----------------|--------------|
| `ios-package-unit` | `macos-latest` | `push`, `pull_request` | **Yes** | `swift test` in `packages/crosswake-shell-core-ios/` — all behavioral tests, no simulator |
| `android-package-unit` | `ubuntu-latest` | `push`, `pull_request` | **Yes** | `./gradlew test` in `packages/crosswake-shell-core-android/` — JVM-only, no emulator |
| `bridge-contract-parity` | `ubuntu-latest` | `push`, `pull_request` | **Yes** | `mix test test/bridge_contract_vectors_test.exs` — asserts Elixir contract matches vectors file |
| `native-collateral-advisory` | `macos-latest` | `workflow_dispatch` | No | Existing simulator/emulator evidence capture (unchanged) |

The `bridge-contract-parity` lane is new and merge-blocking. It runs the Elixir ExUnit test that loads `test/fixtures/bridge_contract_vectors.json` and asserts `Crosswake.Bridge.Contract.version/0`, `Crosswake.Bridge.Contract.protocol/0`, and `Crosswake.Bridge.Contract.commands/0` all match the file.

When a contributor adds a bridge command:
1. They update `contract.ex` — `bridge-contract-parity` fails (vectors file is stale)
2. They update `bridge_contract_vectors.json` — `bridge-contract-parity` passes
3. `ios-package-unit` fails (new command not in Swift enum)
4. `android-package-unit` fails (new command not in Kotlin enum)
5. Contributor adds the command to both enums and adds a test vector in each test suite
6. All three lanes go green simultaneously

That is the enforced contributor workflow with no extra tooling.

---

## 11. The Explicit Recommendation

**Test framework:** XCTest (iOS), JUnit 4 (Android). No migration to swift-testing or JUnit 5 yet — the existing dependencies and minimum versions are the constraint. Add `kotlinx-coroutines-test` to Android.

**Test double mechanism:** Anonymous Swift protocol implementations in test files; anonymous Kotlin object expressions in test files. No mocking library. The delegate protocols are trivial enough that mocks would be overengineered.

**Shared vector mechanism:** Committed JSON file at `test/fixtures/bridge_contract_vectors.json`. Swift tests bundle it as a test resource in `Tests/CrosswakeShellCoreTests/Resources/`. Kotlin tests place it at `src/test/resources/bridge_contract_vectors.json`. Elixir test asserts the live contract matches. This is the single most important structural decision: it is what ensures a protocol version bump in `contract.ex` immediately fails three CI lanes simultaneously instead of being caught in production.

**No new source seams required** beyond adding `BridgeChannel.protocolVersion` and `BridgeChannel.PROTOCOL_VERSION` constants and adding `kotlinx-coroutines-test` to the Android build. All test-time seams already exist.

**CI lanes:** `ios-package-unit` (macOS, merge-blocking), `android-package-unit` (Ubuntu, merge-blocking), `bridge-contract-parity` (Ubuntu, merge-blocking). The existing `native-collateral-advisory` stays advisory and unchanged.

**Files to create (in priority order):**

1. `test/fixtures/bridge_contract_vectors.json` — shared source of truth
2. `test/bridge_contract_vectors_test.exs` — Elixir parity test
3. `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeConformanceTests.swift`
4. `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/ActivationConformanceTests.swift`
5. `packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeConformanceTest.kt`
6. `packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/ActivationConformanceTest.kt`
7. `.github/workflows/ios-package-unit.yml`
8. `.github/workflows/android-package-unit.yml`
9. `.github/workflows/bridge-contract-parity.yml`

---

## 12. What the Test Suite Does NOT Need

- `WKWebView` subclass or mock — `evaluate()` is already callable without one
- `WebView` instance or Robolectric — `evaluateForTesting()` is already callable without one
- A live Phoenix server — all test inputs are in-memory structs
- An iOS Simulator — all Swift tests run on macOS
- An Android Emulator — all Kotlin tests run on the JVM
- A codegen pipeline — a committed JSON file is sufficient for one maintainer
- Protocol version literals in multiple places — constants on `BridgeChannel` in both languages prevent hardcoding

---

## Sources

- Hotwire Turbo iOS source and test patterns: https://github.com/hotwired/turbo-ios
- Hotwire Turbo Android source and test patterns: https://github.com/hotwired/turbo-android
- Strada bridge component testing: https://github.com/hotwired/strada-ios, https://github.com/hotwired/strada-android
- Joe Masilotti on testing Turbo Native without a server: https://masilotti.com/turbo-ios/
- Swift Testing framework docs: https://developer.apple.com/documentation/testing
- kotlinx-coroutines-test: https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-test/
- app.cash.turbine for Flow testing: https://github.com/cashapp/turbine
- OpenTelemetry semantic conventions cross-language vector pattern: https://github.com/open-telemetry/semantic-conventions
- Capacitor bridge testing patterns: https://github.com/ionic-team/capacitor
- Stripe iOS/Android SDK test structure: https://github.com/stripe/stripe-ios, https://github.com/stripe/stripe-android
- Crosswake bridge contract (Elixir authority): `lib/crosswake/bridge/contract.ex`
- iOS package: `packages/crosswake-shell-core-ios/`
- Android package: `packages/crosswake-shell-core-android/`
