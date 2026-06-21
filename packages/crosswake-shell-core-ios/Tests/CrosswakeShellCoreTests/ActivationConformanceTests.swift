import XCTest
@testable import CrosswakeShellCore

/// Activation conformance tests covering success and denial paths.
///
/// Version-anchored to bridge_contract_vectors.json (D-01): `bridgeProtocolVersion` is loaded
/// from the vectors file in setUp so a version bump in the regenerated copy flows through.
/// No bridge version literal is hardcoded anywhere (D-10).
@MainActor
final class ActivationConformanceTests: XCTestCase {

    private var bridgeProtocolVersion: String!

    override func setUp() {
        super.setUp()
        let url = Bundle.module.url(forResource: "bridge_contract_vectors", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let json = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
        bridgeProtocolVersion = (json["bridge_protocol_version"] as? String)!
    }

    // MARK: - Helpers

    /// Build a permissive ShellManifest with a single live_view route at routeID.
    func makeManifest(
        routeID: String = "dashboard",
        runtime: String = "live_view",
        entry: String = "internal_only",
        packs: [String] = [],
        allowlistedOrigins: [String] = ["https://app.example.com"]
    ) -> ShellManifest {
        ShellManifest(
            compatibility: ShellManifest.Compatibility(nativeRuntimeVersion: "1.0.0"),
            routes: [
                routeID: ShellManifest.Route(
                    id: routeID,
                    path: "/\(routeID)",
                    runtime: runtime,
                    entry: entry,
                    capabilities: [],
                    packs: packs,
                    transfers: [],
                    allowlistedOrigins: allowlistedOrigins
                )
            ]
        )
    }

    /// Build an ActivationRequest anchored to the loaded bridgeProtocolVersion.
    func makeRequest(
        routeID: String = "dashboard",
        source: ActivationSource = .coldStart,
        origin: String = "https://app.example.com"
    ) -> ActivationRequest {
        ActivationRequest(
            routeID: routeID,
            url: nil,
            source: source,
            origin: origin,
            manifestSource: .bundled,
            bridgeProtocolVersion: bridgeProtocolVersion,
            nativeRuntimeVersion: "1.0.0",
            correlationID: "test-correlation-id"
        )
    }

    func makeCoordinator(
        manifest: ShellManifest,
        request: ActivationRequest,
        packStore: PackStore
    ) -> ActivationCoordinator {
        ActivationCoordinator(
            manifestLoader: { manifest },
            requestLoader: { request },
            packStore: packStore,
            config: CrosswakeShellConfig()
        )
    }

    func emptyPackStore() -> PackStore {
        PackStore(requiredVersions: [:], inventory: [])
    }

    // MARK: - Activation success: liveView presentation

    func test_activation_success_resolves_to_liveView() {
        let manifest = makeManifest()
        let request = makeRequest()
        let coordinator = makeCoordinator(manifest: manifest, request: request, packStore: emptyPackStore())

        let result = coordinator.resolve(request: request, manifest: manifest)

        guard case let .liveView(session) = result else {
            XCTFail("Expected liveView presentation, got \(result)")
            return
        }
        XCTAssertEqual(session.routeID, "dashboard")
        XCTAssertEqual(session.bridgeProtocolVersion, bridgeProtocolVersion,
                       "session.bridgeProtocolVersion should match vectors file version")
    }

    // MARK: - Activation denial: inactive route

    func test_activation_denies_inactive_route() {
        // Manifest has no routes — any routeID resolves to inactive
        let manifest = ShellManifest(compatibility: ShellManifest.Compatibility(nativeRuntimeVersion: "1.0.0"), routes: [:])
        let request = makeRequest(routeID: "nonexistent-route")
        let coordinator = makeCoordinator(manifest: manifest, request: request, packStore: emptyPackStore())

        let result = coordinator.resolve(request: request, manifest: manifest)

        guard case let .denied(denial) = result else {
            XCTFail("Expected denied presentation, got \(result)")
            return
        }
        XCTAssertEqual(denial.reason, .inactiveRoute,
                       "Missing route should deny with inactiveRoute")
    }

    // MARK: - Activation denial: required pack blocks presentation

    func test_activation_blocks_when_required_pack_missing() {
        // Route declares a required pack; PackStore has no inventory
        let manifest = makeManifest(packs: ["content-pack@1.0.0"])
        let request = makeRequest()
        let packStore = PackStore(requiredVersions: ["content-pack": "1.0.0"], inventory: [])
        let coordinator = makeCoordinator(manifest: manifest, request: request, packStore: packStore)

        let result = coordinator.resolve(request: request, manifest: manifest)

        guard case let .requiredPack(presentation) = result else {
            XCTFail("Expected requiredPack presentation, got \(result)")
            return
        }
        XCTAssertEqual(presentation.routeID, "dashboard",
                       "requiredPack presentation should carry the blocked route ID")
    }
}
