import XCTest
@testable import CrosswakeShellCore

@MainActor
final class NavigationCoordinatorTests: XCTestCase {
    func testPatchDoesNotGrowAndNavigateIsIdempotent() {
        let root = NavigationTopologyEntry(routeID: "route-0123456789abcdef", rootTabID: "tab-0123456789abcdef", presentation: .root, parentRouteID: nil, deepLinkPosture: .allow, restorationPosture: .allow)
        let child = NavigationTopologyEntry(routeID: "route-fedcba9876543210", rootTabID: root.rootTabID, presentation: .push, parentRouteID: root.routeID, deepLinkPosture: .allow, restorationPosture: .allow)
        let manifest = ShellManifest(compatibility: .init(nativeRuntimeVersion: "1.0.0"), routes: [root.routeID: route(root.routeID), child.routeID: route(child.routeID)])
        var patches = 0
        let coordinator = NavigationCoordinator(topology: .init(topologySchemaVersion: "1.0.0", manifestSchemaVersion: "1.0.0", status: .ready, entries: [root, child]), manifest: manifest, resolver: authorize, patchSink: { _ in patches += 1 })
        XCTAssertEqual(coordinator.selectRoot(routeID: root.routeID), .authorized)

        XCTAssertEqual(coordinator.apply(.init(protocolName: "crosswake.navigation_transition", version: "1.0.0", transitionID: "nav-0123456789abcdef", kind: .pushPatch, routeID: root.routeID, restorationRef: nil)), .applied)
        XCTAssertEqual(coordinator.stacks[root.rootTabID]?.count, 1)
        XCTAssertEqual(patches, 1)
        let navigate = NavigationTransition(protocolName: "crosswake.navigation_transition", version: "1.0.0", transitionID: "nav-fedcba9876543210", kind: .pushNavigate, routeID: child.routeID, restorationRef: nil)
        XCTAssertEqual(coordinator.apply(navigate), .applied)
        XCTAssertEqual(coordinator.apply(navigate), .denied)
        XCTAssertEqual(coordinator.stacks[root.rootTabID]?.count, 2)
    }
    func testCompiledRootRequiresResolverAuthorization() throws {
        let vectorURL = URL(fileURLWithPath: "../../priv/contract_vectors/navigation_topology_vectors.json", relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath))
        let vectors = try JSONDecoder().decode(NavigationTopologyVectors.self, from: Data(contentsOf: vectorURL))
        let topology = try XCTUnwrap(vectors.topology(for: "synthetic_authorized_root"))
        let manifest = makeManifest(routeID: "route-0123456789abcdef")
        let coordinator = NavigationCoordinator(topology: topology, manifest: manifest, resolver: authorize)

        XCTAssertEqual(coordinator.selectRoot(routeID: "route-0123456789abcdef"), .authorized)
        XCTAssertEqual(coordinator.selectedTabID, "tab-0123456789abcdef")
        XCTAssertEqual(coordinator.stacks["tab-0123456789abcdef"]?.count, 1)
        XCTAssertEqual(coordinator.activeRouteID, "route-0123456789abcdef")
    }

    func testDeniedSelectionPreservesExistingState() throws {
        let topology = NavigationTopology(
            topologySchemaVersion: "1.0.0", manifestSchemaVersion: "1.0.0", status: .ready,
            entries: [NavigationTopologyEntry(routeID: "route-0123456789abcdef", rootTabID: "tab-0123456789abcdef", presentation: .root, parentRouteID: nil, deepLinkPosture: .deny, restorationPosture: .deny)]
        )
        let manifest = makeManifest(routeID: "route-0123456789abcdef")
        let coordinator = NavigationCoordinator(topology: topology, manifest: manifest, resolver: { _, _ in .denied })
        let before = (coordinator.selectedTabID, coordinator.stacks, coordinator.activeRouteID)

        XCTAssertEqual(coordinator.selectRoot(routeID: "route-0123456789abcdef"), .denied)
        XCTAssertEqual(coordinator.selectedTabID, before.0)
        XCTAssertEqual(coordinator.stacks, before.1)
        XCTAssertEqual(coordinator.activeRouteID, before.2)
    }

    func testUnknownBlockingTopologyCannotCreateARoot() {
        let topology = NavigationTopology(topologySchemaVersion: "1.0.0", manifestSchemaVersion: "1.0.0", status: .unknownBlocking, entries: [])
        let coordinator = NavigationCoordinator(topology: topology, manifest: makeManifest(routeID: "route-0123456789abcdef"), resolver: authorize)

        XCTAssertEqual(coordinator.selectRoot(routeID: "route-0123456789abcdef"), .denied)
        XCTAssertNil(coordinator.selectedTabID)
        XCTAssertEqual(coordinator.stacks, [:])
    }

    func testMalformedTopologyDoesNotCallResolverOrMutateState() {
        let topology = NavigationTopology(topologySchemaVersion: "1.0.0", manifestSchemaVersion: "2.0.0", status: .ready, entries: [])
        var calls = 0
        let coordinator = NavigationCoordinator(topology: topology, manifest: makeManifest(routeID: "route-0123456789abcdef"), resolver: { _, _ in calls += 1; return .denied })

        XCTAssertEqual(coordinator.selectRoot(routeID: "route-0123456789abcdef"), .denied)
        XCTAssertEqual(calls, 0)
        XCTAssertNil(coordinator.activeRouteID)
    }

    func testCyclicTopologyIsDeniedBeforeResolverInvocation() {
        let root = NavigationTopologyEntry(routeID: "route-0123456789abcdef", rootTabID: "tab-0123456789abcdef", presentation: .root, parentRouteID: nil, deepLinkPosture: .deny, restorationPosture: .deny)
        let first = NavigationTopologyEntry(routeID: "route-fedcba9876543210", rootTabID: "tab-0123456789abcdef", presentation: .push, parentRouteID: "route-aaaaaaaaaaaaaaaa", deepLinkPosture: .deny, restorationPosture: .deny)
        let second = NavigationTopologyEntry(routeID: "route-aaaaaaaaaaaaaaaa", rootTabID: "tab-0123456789abcdef", presentation: .push, parentRouteID: "route-fedcba9876543210", deepLinkPosture: .deny, restorationPosture: .deny)
        let topology = NavigationTopology(topologySchemaVersion: "1.0.0", manifestSchemaVersion: "1.0.0", status: .ready, entries: [root, first, second])
        let manifest = ShellManifest(compatibility: .init(nativeRuntimeVersion: "1.0.0"), routes: [root.routeID: route(root.routeID), first.routeID: route(first.routeID), second.routeID: route(second.routeID)])
        var calls = 0
        let coordinator = NavigationCoordinator(topology: topology, manifest: manifest, resolver: { _, _ in calls += 1; return .denied })

        XCTAssertEqual(coordinator.selectRoot(routeID: root.routeID), .denied)
        XCTAssertEqual(calls, 0)
    }

    private func authorize(_ routeID: String, _ manifest: ShellManifest) -> NavigationResolution {
        guard manifest.routes[routeID] != nil else { return .denied }
        return .authorized(.liveView(LiveViewSession(routeID: routeID, url: URL(string: "https://app.example.com")!, allowedOrigin: URL(string: "https://app.example.com")!, bridgeProtocolVersion: "1.0.0", nativeRuntimeVersion: "1.0.0", threadID: "test", installedPacks: [:], routeRequiredPacks: [], capabilities: [:], declaredTransfers: [])))
    }

    private func makeManifest(routeID: String) -> ShellManifest {
        ShellManifest(compatibility: .init(nativeRuntimeVersion: "1.0.0"), routes: [routeID: route(routeID)])
    }

    private func route(_ routeID: String) -> ShellManifest.Route { .init(id: routeID, path: "/study", runtime: "live_view", entry: "internal_only", capabilities: [], packs: [], transfers: [], allowlistedOrigins: ["https://app.example.com"]) }
}

private struct NavigationTopologyVectors: Decodable {
    let topologySchemaVersion: String
    let manifestSchemaVersion: String
    let vectors: [Vector]

    struct Vector: Decodable {
        let id: String
        let status: NavigationTopologyStatus
        let entries: [NavigationTopologyEntry]
    }

    func topology(for id: String) -> NavigationTopology? {
        guard let vector = vectors.first(where: { $0.id == id }) else { return nil }
        return NavigationTopology(topologySchemaVersion: topologySchemaVersion, manifestSchemaVersion: manifestSchemaVersion, status: vector.status, entries: vector.entries)
    }

    enum CodingKeys: String, CodingKey { case topologySchemaVersion = "topology_schema_version", manifestSchemaVersion = "manifest_schema_version", vectors }
}
