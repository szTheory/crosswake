import XCTest
@testable import CrosswakeShellCore

/// Phase 180 feasibility gate, facts G3 (native session) and G4 (runtime admission).
/// Characterization only; nothing under Sources/ is changed. Synthetic public values.
@MainActor
final class Phase180TwinFeasibilityTests: XCTestCase {

    private let command = "host.study.audio.play"
    private let origin = "https://study.crosswake.test"

    // MARK: - Helpers

    private func makeManifest(
        routeID: String,
        runtime: String,
        allowlistedOrigin: String? = nil,
        hostCommands: [String: String]? = nil
    ) -> ShellManifest {
        ShellManifest(
            compatibility: ShellManifest.Compatibility(nativeRuntimeVersion: "1.0.0"),
            routes: [
                routeID: ShellManifest.Route(
                    id: routeID,
                    path: "/\(routeID)",
                    runtime: runtime,
                    entry: "internal_only",
                    capabilities: hostCommands.map { Array($0.keys) } ?? [],
                    packs: [],
                    transfers: [],
                    allowlistedOrigins: [allowlistedOrigin ?? origin],
                    hostCommands: hostCommands
                )
            ]
        )
    }

    private func makeRequest(routeID: String, capabilities: [String: String] = [:]) -> ActivationRequest {
        ActivationRequest(
            routeID: routeID,
            url: nil,
            source: .coldStart,
            origin: origin,
            manifestSource: .bundled,
            bridgeProtocolVersion: bridgeVersion(),
            nativeRuntimeVersion: "1.0.0",
            correlationID: "phase180-correlation",
            capabilities: capabilities
        )
    }

    private func bridgeVersion() -> String {
        let url = Bundle.module.url(forResource: "bridge_contract_vectors", withExtension: "json")!
        let json = try! JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [String: Any]
        return json["bridge_protocol_version"] as! String
    }

    private func coordinator(
        manifest: ShellManifest,
        request: ActivationRequest,
        delegate: Phase180RecordingHostDelegate?
    ) -> ActivationCoordinator {
        ActivationCoordinator(
            manifestLoader: { manifest },
            requestLoader: { request },
            packStore: PackStore(requiredVersions: [:], inventory: []),
            config: CrosswakeShellConfig(hostBridgeCommandDelegate: delegate)
        )
    }

    private func liveViewSession(_ coordinator: ActivationCoordinator, file: StaticString = #filePath, line: UInt = #line) -> LiveViewSession? {
        guard case let .liveView(session) = coordinator.presentation else {
            XCTFail("Expected liveView presentation, got \(coordinator.presentation)", file: file, line: line)
            return nil
        }
        return session
    }

    /// Reads the generator's exported activation bytes. Throws XCTSkip when unusable.
    private func exportedActivation(replacingCapabilities: [String: String]? = nil) throws -> ActivationRequest {
        guard let dir = ProcessInfo.processInfo.environment["PHASE180_EXPORT_DIR"], !dir.isEmpty else {
            throw XCTSkip("PHASE180_EXPORT_DIR is not set")
        }
        let base = URL(fileURLWithPath: dir)
        let activationURL = base.appendingPathComponent("route_activation.json")
        let manifestURL = base.appendingPathComponent("crosswake_manifest.json")
        guard FileManager.default.fileExists(atPath: manifestURL.path),
              let data = try? Data(contentsOf: activationURL) else {
            throw XCTSkip("exported files are missing")
        }
        var payload = data
        if let caps = replacingCapabilities {
            guard var obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw XCTSkip("exported activation is not a JSON object")
            }
            obj["capabilities"] = caps
            payload = try JSONSerialization.data(withJSONObject: obj)
        }
        guard let request = try? JSONDecoder().decode(ActivationRequest.self, from: payload) else {
            throw XCTSkip("exported activation does not decode as ActivationRequest")
        }
        return request
    }

    private func session(capabilities: [String: String]) -> LiveViewSession {
        LiveViewSession(
            routeID: "study",
            url: URL(string: "\(origin)/study")!,
            allowedOrigin: URL(string: origin)!,
            bridgeProtocolVersion: "1.1.0",
            nativeRuntimeVersion: "1.0.0",
            threadID: "thread",
            installedPacks: [:],
            routeRequiredPacks: [],
            capabilities: capabilities,
            declaredTransfers: []
        )
    }

    private func bridgeRequest(command: String) -> BridgeRequestEnvelope {
        BridgeRequestEnvelope(
            protocolName: "crosswake.bridge",
            version: "1.1.0",
            command: command,
            capability: command,
            routeID: "study",
            activeRouteID: "study",
            origin: origin,
            nativeRuntimeVersion: "1.0.0",
            correlationID: "correlation",
            capabilities: [command: "1.0.0"],
            installedPacks: [:],
            payload: [:]
        )
    }

    // MARK: - G3 invariants (must hold in every mode)

    func test_G3_invariant_activation_does_not_manufacture_registered_host_command() {
        let delegate = Phase180RecordingHostDelegate()
        let manifest = makeManifest(routeID: "study", runtime: "live_view")
        let c = coordinator(manifest: manifest, request: makeRequest(routeID: "study"), delegate: delegate)
        c.bootstrapIfNeeded()
        guard let session = liveViewSession(c) else { return }
        XCTAssertNil(session.capabilities[command])
        withExtendedLifetime(delegate) {}
    }

    func test_G3_invariant_bridge_denies_registered_command_absent_from_session() {
        let delegate = Phase180RecordingHostDelegate()
        let channel = BridgeChannel(
            session: session(capabilities: [:]),
            transferCoordinator: nil,
            replySink: { _ in },
            config: CrosswakeShellConfig(hostBridgeCommandDelegate: delegate)
        )
        var reply: BridgeReplyEnvelope?
        channel.evaluate(bridgeRequest(command: command)) { reply = $0 }
        XCTAssertEqual(reply?.denial?.denial.reason, "undeclared_capability")
        XCTAssertTrue(delegate.commands.isEmpty)
        withExtendedLifetime(delegate) {}
    }

    // MARK: - G3 gate and control

    func test_G3_gate_generated_activation_session_lacks_host_command() throws {
        let request = try exportedActivation()
        let delegate = Phase180RecordingHostDelegate()
        let routeID = try XCTUnwrap(request.routeID)
        let manifest = makeManifest(routeID: routeID, runtime: "live_view", allowlistedOrigin: request.origin)
        let c = coordinator(manifest: manifest, request: request, delegate: delegate)
        c.bootstrapIfNeeded()
        guard let session = liveViewSession(c) else { return }
        XCTAssertNil(session.capabilities[command])
        withExtendedLifetime(delegate) {}
    }

    func test_G3_control_exported_request_carrying_command_reaches_delegate() throws {
        let request = try exportedActivation(replacingCapabilities: [command: "1.0.0"])
        let delegate = Phase180RecordingHostDelegate()
        let routeID = try XCTUnwrap(request.routeID)
        // D-01: a route that does not declare the command grants nothing, so the control declares it.
        let manifest = makeManifest(routeID: routeID, runtime: "live_view", allowlistedOrigin: request.origin, hostCommands: [command: "1.0.0"])
        let c = coordinator(manifest: manifest, request: request, delegate: delegate)
        c.bootstrapIfNeeded()
        guard let live = liveViewSession(c) else { return }
        XCTAssertEqual(live.capabilities[command], "1.0.0")

        let channel = BridgeChannel(
            session: LiveViewSession(
                routeID: "study",
                url: URL(string: "\(origin)/study")!,
                allowedOrigin: URL(string: origin)!,
                bridgeProtocolVersion: "1.1.0",
                nativeRuntimeVersion: "1.0.0",
                threadID: "thread",
                installedPacks: [:],
                routeRequiredPacks: [],
                capabilities: live.capabilities,
                declaredTransfers: []
            ),
            transferCoordinator: nil,
            replySink: { _ in },
            config: CrosswakeShellConfig(hostBridgeCommandDelegate: delegate)
        )
        var reply: BridgeReplyEnvelope?
        channel.evaluate(bridgeRequest(command: command)) { reply = $0 }
        XCTAssertEqual(reply?.status, "ok")
        XCTAssertEqual(delegate.commands, [command])
        withExtendedLifetime(delegate) {}
    }

    // MARK: - G4 gate and control

    func test_G4_gate_bounded_shell_denies_offline_island_runtime() {
        let manifest = makeManifest(routeID: "study", runtime: "offline_island")
        let request = makeRequest(routeID: "study")
        let c = coordinator(manifest: manifest, request: request, delegate: nil)
        let result = c.resolve(request: request, manifest: manifest)
        guard case let .denied(denial) = result else {
            XCTFail("Expected denied, got \(result)")
            return
        }
        XCTAssertTrue(denial.message.contains("bounded shell"))
    }

    func test_G4_control_live_view_runtime_resolves() {
        let manifest = makeManifest(routeID: "study", runtime: "live_view")
        let request = makeRequest(routeID: "study")
        let c = coordinator(manifest: manifest, request: request, delegate: nil)
        let result = c.resolve(request: request, manifest: manifest)
        guard case .liveView = result else {
            XCTFail("Expected liveView, got \(result)")
            return
        }
    }
}

private final class Phase180RecordingHostDelegate: HostBridgeCommandDelegate {
    var registeredCommands: [String] { ["host.study.audio.play"] }
    private(set) var commands: [String] = []

    func handle(command: String, payload: [String: String], correlationID: String, completion: @escaping (BridgeChannel.CommandResult) -> Void) {
        commands.append(command)
        completion(.success(["result": "submitted"]))
    }
}
