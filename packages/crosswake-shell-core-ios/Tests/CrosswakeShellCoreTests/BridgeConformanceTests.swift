import XCTest
@testable import CrosswakeShellCore

// MARK: - Codable models for bridge_contract_vectors.json

struct BridgeVectorsFile: Codable {
    let bridgeProtocolVersion: String
    let nativeRuntimeVersion: String
    let vectors: [BridgeVector]

    enum CodingKeys: String, CodingKey {
        case bridgeProtocolVersion = "bridge_protocol_version"
        case nativeRuntimeVersion = "native_runtime_version"
        case vectors
    }
}

struct BridgeVector: Codable {
    let id: String
    let description: String
    let requestOverride: [String: String]
    let sessionOverride: SessionOverride
    let expectedOutcome: String
    let expectedDenialReason: String?

    enum CodingKeys: String, CodingKey {
        case id
        case description
        case requestOverride = "request_override"
        case sessionOverride = "session_override"
        case expectedOutcome = "expected_outcome"
        case expectedDenialReason = "expected_denial_reason"
    }
}

/// Session overrides from JSON — may be an empty array or an object with optional fields.
struct SessionOverride: Codable {
    let capabilities: [String: String]?
    let installedPacks: [String: String]?
    let routeRequiredPacks: [String]?
    /// Floor conformance override (COMPAT-01 / D-05): allows per-vector session version axes.
    let bridgeProtocolVersion: String?
    let nativeRuntimeVersion: String?

    init(capabilities: [String: String]? = nil, installedPacks: [String: String]? = nil,
         routeRequiredPacks: [String]? = nil, bridgeProtocolVersion: String? = nil,
         nativeRuntimeVersion: String? = nil) {
        self.capabilities = capabilities
        self.installedPacks = installedPacks
        self.routeRequiredPacks = routeRequiredPacks
        self.bridgeProtocolVersion = bridgeProtocolVersion
        self.nativeRuntimeVersion = nativeRuntimeVersion
    }

    init(from decoder: Decoder) throws {
        // The JSON encodes empty session_override as [] (an empty array) and non-empty as an object.
        // We must handle both cases.
        if (try? decoder.unkeyedContainer()) != nil {
            // Empty array [] — no overrides
            self.capabilities = nil
            self.installedPacks = nil
            self.routeRequiredPacks = nil
            self.bridgeProtocolVersion = nil
            self.nativeRuntimeVersion = nil
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.capabilities = try container.decodeIfPresent([String: String].self, forKey: .capabilities)
        self.routeRequiredPacks = try container.decodeIfPresent([String].self, forKey: .routeRequiredPacks)
        self.bridgeProtocolVersion = try container.decodeIfPresent(String.self, forKey: .bridgeProtocolVersion)
        self.nativeRuntimeVersion = try container.decodeIfPresent(String.self, forKey: .nativeRuntimeVersion)

        // installed_packs in JSON is [] (empty array) for the pack vector — decode as array then ignore
        // The bridge session only needs routeRequiredPacks + installedPacks as [String: String] dict
        if let _ = try? container.decodeIfPresent([String].self, forKey: .installedPacks) {
            self.installedPacks = nil  // empty array means no installed packs
        } else {
            self.installedPacks = try container.decodeIfPresent([String: String].self, forKey: .installedPacks)
        }
    }

    enum CodingKeys: String, CodingKey {
        case capabilities
        case installedPacks = "installed_packs"
        case routeRequiredPacks = "route_required_packs"
        case bridgeProtocolVersion = "bridge_protocol_version"
        case nativeRuntimeVersion = "native_runtime_version"
    }
}

// MARK: - BridgeConformanceTests

final class BridgeConformanceTests: XCTestCase {

    private var vectorsFile: BridgeVectorsFile!

    override func setUp() {
        super.setUp()
        let url = Bundle.module.url(forResource: "bridge_contract_vectors", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        vectorsFile = try! JSONDecoder().decode(BridgeVectorsFile.self, from: data)
    }

    // MARK: - Helpers

    /// Build a permissive LiveViewSession, then apply session_override fields.
    func makeSession(
        bridgeProtocolVersion: String,
        override sessionOverride: SessionOverride
    ) -> LiveViewSession {
        let baseCapabilities: [String: String] = sessionOverride.capabilities ?? [:]
        let baseInstalledPacks: [String: String] = sessionOverride.installedPacks ?? [:]
        let baseRouteRequiredPacks: [String] = sessionOverride.routeRequiredPacks ?? []
        // Floor conformance (COMPAT-01 / D-05): per-vector version axis overrides.
        let sessionBridgeVersion = sessionOverride.bridgeProtocolVersion ?? bridgeProtocolVersion
        let sessionNativeRuntimeVersion = sessionOverride.nativeRuntimeVersion ?? vectorsFile.nativeRuntimeVersion

        return LiveViewSession(
            routeID: "dashboard",
            url: URL(string: "https://app.example.com/dashboard")!,
            allowedOrigin: URL(string: "https://app.example.com")!,
            bridgeProtocolVersion: sessionBridgeVersion,
            nativeRuntimeVersion: sessionNativeRuntimeVersion,
            threadID: "test-thread-id",
            installedPacks: baseInstalledPacks,
            routeRequiredPacks: baseRouteRequiredPacks,
            capabilities: baseCapabilities,
            declaredTransfers: []
        )
    }

    /// Build a permissive BridgeRequestEnvelope, then apply request_override fields.
    /// The request.capabilities default matches a passing baseline; session_override.capabilities
    /// modifies the session independently (so a version mismatch between session and request fires
    /// unavailable_capability as expected for vec-007).
    func makeRequest(
        bridgeProtocolVersion: String,
        override requestOverride: [String: String]
    ) -> BridgeRequestEnvelope {
        // Start from permissive defaults
        let version = requestOverride["version"] ?? bridgeProtocolVersion
        let command = requestOverride["command"] ?? "app.info.get"
        let capability = requestOverride["capability"] ?? "app.info.get"
        let routeID = requestOverride["route_id"] ?? "dashboard"
        let activeRouteID = requestOverride["active_route_id"] ?? "dashboard"
        let origin = requestOverride["origin"] ?? "https://app.example.com"
        // Floor conformance (COMPAT-01 / D-05): allow request native_runtime_version override.
        let nativeRuntimeVersion = requestOverride["native_runtime_version"] ?? vectorsFile.nativeRuntimeVersion

        // Request capabilities default to the base "ok" version for the command.
        // vec-007 has session.capabilities["app.info.get"] = "2.0.0" while the request
        // carries the default "1.0.0", triggering capabilityAvailable() to return false.
        let requestCapabilities: [String: String] = ["app.info.get": "1.0.0"]

        return BridgeRequestEnvelope(
            protocolName: "crosswake.bridge",
            version: version,
            command: command,
            capability: capability,
            routeID: routeID,
            activeRouteID: activeRouteID,
            origin: origin,
            nativeRuntimeVersion: nativeRuntimeVersion,
            correlationID: "test-correlation-id",
            capabilities: requestCapabilities,
            installedPacks: [:],
            payload: [:]
        )
    }

    /// Build a CrosswakeShellConfig for the given vector.
    /// The ok-path vector must include an appInfoDelegate (Pitfall 6).
    func makeConfig(for vector: BridgeVector, appInfoDelegate: AppInfoDelegate?) -> CrosswakeShellConfig {
        CrosswakeShellConfig(appInfoDelegate: appInfoDelegate)
    }

    // MARK: - Data-driven bridge evaluate() test

    func test_bridge_vectors_data_driven() {
        // All version values come from the loaded vectors file (D-10).
        let bridgeVersion = vectorsFile.bridgeProtocolVersion

        for vector in vectorsFile.vectors {
            let session = makeSession(bridgeProtocolVersion: bridgeVersion, override: vector.sessionOverride)
            let request = makeRequest(
                bridgeProtocolVersion: bridgeVersion,
                override: vector.requestOverride
            )

            // The ok-path vector (vec-003) configures appInfoDelegate (Pitfall 6).
            // Hold a strong reference so the weak var in CrosswakeShellConfig is not nil during evaluate().
            let stubDelegate = StubAppInfoDelegate()
            let appInfoDelegate: AppInfoDelegate? = vector.expectedOutcome == "ok" ? stubDelegate : nil
            let config = makeConfig(for: vector, appInfoDelegate: appInfoDelegate)

            let channel = BridgeChannel(session: session, transferCoordinator: nil, replySink: { _ in }, config: config)

            var reply: BridgeReplyEnvelope?
            channel.evaluate(request) { reply = $0 }

            XCTAssertEqual(reply?.status, vector.expectedOutcome,
                           "[\(vector.id)] status: expected \(vector.expectedOutcome), got \(reply?.status ?? "nil")")

            if let expectedReason = vector.expectedDenialReason {
                XCTAssertEqual(reply?.denial?.denial.reason, expectedReason,
                               "[\(vector.id)] denial reason: expected \(expectedReason), got \(reply?.denial?.denial.reason ?? "nil")")
            }
        }
    }

    // MARK: - Delegate escape-hatch tests

    /// Delegate present → app.info.get returns ok.
    func test_appInfoGet_with_delegate_returns_ok() {
        let bridgeVersion = vectorsFile.bridgeProtocolVersion
        let capabilities = ["app.info.get": "1.0.0"]
        let session = LiveViewSession(
            routeID: "dashboard",
            url: URL(string: "https://app.example.com/dashboard")!,
            allowedOrigin: URL(string: "https://app.example.com")!,
            bridgeProtocolVersion: bridgeVersion,
            nativeRuntimeVersion: vectorsFile.nativeRuntimeVersion,
            threadID: "t1",
            installedPacks: [:],
            routeRequiredPacks: [],
            capabilities: capabilities,
            declaredTransfers: []
        )
        // Hold a strong reference — CrosswakeShellConfig.appInfoDelegate is weak (D-ARC)
        let stub = StubAppInfoDelegate()
        let config = CrosswakeShellConfig(appInfoDelegate: stub)
        let channel = BridgeChannel(session: session, transferCoordinator: nil, replySink: { _ in }, config: config)
        let request = BridgeRequestEnvelope(
            protocolName: "crosswake.bridge",
            version: bridgeVersion,
            command: "app.info.get",
            capability: "app.info.get",
            routeID: "dashboard",
            activeRouteID: "dashboard",
            origin: "https://app.example.com",
            nativeRuntimeVersion: vectorsFile.nativeRuntimeVersion,
            correlationID: "t1",
            capabilities: capabilities,
            installedPacks: [:],
            payload: [:]
        )

        var reply: BridgeReplyEnvelope?
        channel.evaluate(request) { reply = $0 }

        XCTAssertEqual(reply?.status, "ok", "app.info.get with delegate configured should return ok")
    }

    /// Delegate absent → app.info.get returns deny (undeclared_capability).
    func test_appInfoGet_without_delegate_returns_deny() {
        let bridgeVersion = vectorsFile.bridgeProtocolVersion
        let capabilities = ["app.info.get": "1.0.0"]
        let session = LiveViewSession(
            routeID: "dashboard",
            url: URL(string: "https://app.example.com/dashboard")!,
            allowedOrigin: URL(string: "https://app.example.com")!,
            bridgeProtocolVersion: bridgeVersion,
            nativeRuntimeVersion: vectorsFile.nativeRuntimeVersion,
            threadID: "t1",
            installedPacks: [:],
            routeRequiredPacks: [],
            capabilities: capabilities,
            declaredTransfers: []
        )
        // No appInfoDelegate configured
        let config = CrosswakeShellConfig()
        let channel = BridgeChannel(session: session, transferCoordinator: nil, replySink: { _ in }, config: config)
        let request = BridgeRequestEnvelope(
            protocolName: "crosswake.bridge",
            version: bridgeVersion,
            command: "app.info.get",
            capability: "app.info.get",
            routeID: "dashboard",
            activeRouteID: "dashboard",
            origin: "https://app.example.com",
            nativeRuntimeVersion: vectorsFile.nativeRuntimeVersion,
            correlationID: "t1",
            capabilities: capabilities,
            installedPacks: [:],
            payload: [:]
        )

        var reply: BridgeReplyEnvelope?
        channel.evaluate(request) { reply = $0 }

        XCTAssertEqual(reply?.status, "deny", "app.info.get without delegate should return deny")
        XCTAssertEqual(reply?.denial?.denial.reason, "undeclared_capability",
                       "app.info.get without delegate should deny with undeclared_capability")
    }
}

// MARK: - Stub delegates

private final class StubAppInfoDelegate: AppInfoDelegate {
    func getAppInfo() -> [String: String] {
        return ["version": "1.0.0", "build": "42"]
    }
}
