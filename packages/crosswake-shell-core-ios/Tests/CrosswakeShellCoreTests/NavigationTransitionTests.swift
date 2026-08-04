import XCTest
import WebKit
@testable import CrosswakeShellCore

@MainActor
final class NavigationTransitionTests: XCTestCase {
    func testTransitionDecodingAndNavigateAreIdempotent() throws {
        let coordinator = makeCoordinator()
        let channel = NavigationTransitionChannel(coordinator: coordinator)
        let body: [String: Any] = [
            "protocol": "crosswake.navigation_transition", "version": "1.0.0",
            "transition_id": "nav-0123456789abcdef", "kind": "push_navigate",
            "route_id": "route-fedcba9876543210"
        ]

        XCTAssertEqual(channel.submit(body), .applied)
        XCTAssertEqual(coordinator.stacks["tab-0123456789abcdef"]?.count, 2)
        XCTAssertEqual(channel.submit(body), .denied)
        XCTAssertEqual(coordinator.stacks["tab-0123456789abcdef"]?.count, 2)
    }

    func testPatchDoesNotGrowAndMalformedBodiesDoNotMutate() throws {
        let patchCount = LockedInt()
        let coordinator = makeCoordinator(patchSink: { _ in patchCount.value += 1 })
        XCTAssertEqual(coordinator.selectRoot(routeID: "route-0123456789abcdef"), .authorized)
        let channel = NavigationTransitionChannel(coordinator: coordinator)
        let patch: [String: Any] = [
            "protocol": "crosswake.navigation_transition", "version": "1.0.0",
            "transition_id": "nav-0123456789abcdef", "kind": "push_patch",
            "route_id": "route-0123456789abcdef"
        ]
        let selectedBefore = coordinator.selectedTabID
        let stacksBefore = coordinator.stacks
        let routeBefore = coordinator.activeRouteID

        XCTAssertEqual(channel.submit(patch), .applied)
        XCTAssertEqual(coordinator.stacks["tab-0123456789abcdef"]?.count, 1)
        XCTAssertEqual(patchCount.value, 1)
        XCTAssertEqual(channel.submit(["protocol": "crosswake.navigation_transition"]), .denied)
        XCTAssertEqual(coordinator.selectedTabID, selectedBefore)
        XCTAssertEqual(coordinator.stacks, stacksBefore)
        XCTAssertEqual(coordinator.activeRouteID, routeBefore)
        XCTAssertEqual(patchCount.value, 1)
    }

    private func makeCoordinator(patchSink: @escaping (NavigationStackEntry) -> Void = { _ in }) -> NavigationCoordinator {
        let root = NavigationTopologyEntry(routeID: "route-0123456789abcdef", rootTabID: "tab-0123456789abcdef", presentation: .root, parentRouteID: nil, deepLinkPosture: .allow, restorationPosture: .allow)
        let push = NavigationTopologyEntry(routeID: "route-fedcba9876543210", rootTabID: root.rootTabID, presentation: .push, parentRouteID: root.routeID, deepLinkPosture: .allow, restorationPosture: .allow)
        let manifest = ShellManifest(compatibility: .init(nativeRuntimeVersion: "1.0.0"), routes: [root.routeID: route(root.routeID), push.routeID: route(push.routeID)])
        let topology = NavigationTopology(topologySchemaVersion: "1.0.0", manifestSchemaVersion: "1.0.0", status: .ready, entries: [root, push])
        let resolver: (String, ShellManifest) -> NavigationResolution = { routeID, _ in
            .authorized(.liveView(LiveViewSession(routeID: routeID, url: URL(string: "https://app.example.com")!, allowedOrigin: URL(string: "https://app.example.com")!, bridgeProtocolVersion: "1.0.0", nativeRuntimeVersion: "1.0.0", threadID: "test", installedPacks: [:], routeRequiredPacks: [], capabilities: [:], declaredTransfers: [])))
        }
        return NavigationCoordinator(topology: topology, manifest: manifest, resolver: resolver, patchSink: patchSink)
    }

    private func route(_ routeID: String) -> ShellManifest.Route { .init(id: routeID, path: "/study", runtime: "live_view", entry: "internal_only", capabilities: [], packs: [], transfers: [], allowlistedOrigins: ["https://app.example.com"]) }
}

private final class LockedInt { var value = 0 }
