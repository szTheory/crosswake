import XCTest
@testable import CrosswakeShellCore

/// SEAM-04: offline_island routes are admitted as a separately named presentation that passes
/// the same ordered checks as live_view; every other runtime is explicitly denied (D-11, D-12, D-14).
@MainActor
final class OfflineIslandAdmissionTests: XCTestCase {
    private let origin = "https://app.example.com"
    private let runtimeHint = "The bounded shell opens live_view and offline_island routes only. Use a declared native capture route or update the shell."
    private var bridgeVersion: String!

    override func setUp() {
        super.setUp()
        let url = Bundle.module.url(forResource: "bridge_contract_vectors", withExtension: "json")!
        let json = try! JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [String: Any]
        bridgeVersion = (json["bridge_protocol_version"] as? String)!
    }

    private func manifest(runtime: String, entry: String = "internal_only", packs: [String] = [], origins: [String]? = nil, active: Bool = true) -> ShellManifest {
        ShellManifest(
            compatibility: ShellManifest.Compatibility(nativeRuntimeVersion: "1.0.0"),
            routes: active ? ["dashboard": ShellManifest.Route(
                id: "dashboard", path: "/dashboard", runtime: runtime, entry: entry, capabilities: [],
                packs: packs, transfers: [], allowlistedOrigins: origins ?? [origin]
            )] : [:]
        )
    }

    private func request(source: ActivationSource = .coldStart, origin: String? = nil, native: String = "1.0.0", url: URL? = nil) -> ActivationRequest {
        ActivationRequest(
            routeID: "dashboard", url: url, source: source, origin: origin ?? self.origin, manifestSource: .bundled,
            bridgeProtocolVersion: bridgeVersion, nativeRuntimeVersion: native, correlationID: "test-correlation-id"
        )
    }

    private func coordinator(_ manifest: ShellManifest, _ request: ActivationRequest, packStore: PackStore? = nil, config: CrosswakeShellConfig = CrosswakeShellConfig()) -> ActivationCoordinator {
        ActivationCoordinator(
            manifestLoader: { manifest }, requestLoader: { request },
            packStore: packStore ?? PackStore(requiredVersions: [:], inventory: []), config: config
        )
    }

    private func resolve(runtime: String, entry: String = "internal_only", packs: [String] = [], origins: [String]? = nil, active: Bool = true, request req: ActivationRequest? = nil, packStore: PackStore? = nil) -> ShellPresentation {
        let m = manifest(runtime: runtime, entry: entry, packs: packs, origins: origins, active: active)
        let r = req ?? request()
        return coordinator(m, r, packStore: packStore).resolve(request: r, manifest: m)
    }

    private func denial(_ presentation: ShellPresentation, file: StaticString = #filePath, line: UInt = #line) -> RouteDenialPresentation? {
        guard case let .denied(d) = presentation else {
            XCTFail("expected denied, got \(presentation)", file: file, line: line)
            return nil
        }
        return d
    }

    /// Denial content without recovery actions: the safe-fallback action depends on whether the
    /// manifest also holds a live_view route, which is unrelated to the runtime under test.
    private func content(_ d: RouteDenialPresentation?) -> [String?] {
        [d?.reason.rawValue, d?.message, d?.hint, d?.routeID]
    }

    // MARK: tracer

    func test_offline_island_route_resolves_to_offlineIsland_presentation() {
        guard case let .offlineIsland(session) = resolve(runtime: "offline_island") else {
            return XCTFail("expected offlineIsland")
        }
        XCTAssertEqual(session.runtime, .offlineIsland)
        XCTAssertEqual(session.routeID, "dashboard")
        XCTAssertEqual(session.url, URL(string: origin + "/dashboard"))
    }

    func test_live_view_route_still_resolves_to_liveView_with_liveView_runtime() {
        guard case let .liveView(session) = resolve(runtime: "live_view") else {
            return XCTFail("expected liveView")
        }
        XCTAssertEqual(session.runtime, .liveView)
        XCTAssertEqual(session.routeID, "dashboard")
    }

    func test_island_without_capabilities_is_admitted_with_empty_host_capabilities() {
        guard case let .offlineIsland(session) = resolve(runtime: "offline_island") else {
            return XCTFail("expected offlineIsland")
        }
        XCTAssertEqual(session.capabilities, [:])
        XCTAssertEqual(session.hostCommandDenials, [:])
    }

    // MARK: same checks, same order (D-12)

    func test_native_runtime_version_mismatch_is_identical_for_island_and_live_view() {
        let island = denial(resolve(runtime: "offline_island", request: request(native: "9.0.0")))
        let live = denial(resolve(runtime: "live_view", request: request(native: "9.0.0")))
        XCTAssertEqual(content(island), content(live))
        XCTAssertEqual(island?.reason, .compatibilityMismatch)
        XCTAssertEqual(island?.message, "This route requires a newer shell binary to boot.")
    }

    func test_inactive_island_route_is_denied_inactive_route() {
        let island = denial(resolve(runtime: "offline_island", active: false))
        XCTAssertEqual(island, denial(resolve(runtime: "live_view", active: false)))
        XCTAssertEqual(island?.reason, .inactiveRoute)
    }

    func test_internal_only_island_opened_by_deep_link_is_external_entry_denied() {
        let deep = request(source: .deepLink)
        let island = denial(resolve(runtime: "offline_island", request: deep))
        XCTAssertEqual(content(island), content(denial(resolve(runtime: "live_view", request: deep))))
        XCTAssertEqual(island?.reason, .externalEntryDenied)
    }

    func test_external_island_opened_by_deep_link_is_admitted() {
        guard case .offlineIsland = resolve(runtime: "offline_island", entry: "external", request: request(source: .deepLink)) else {
            return XCTFail("expected offlineIsland")
        }
    }

    func test_island_with_missing_pack_is_requiredPack_labelled_offline_island_never_offlineIsland() {
        let store = PackStore(requiredVersions: ["content-pack": "1.0.0"], inventory: [])
        let island = resolve(runtime: "offline_island", packs: ["content-pack@1.0.0"], packStore: store)
        guard case let .requiredPack(p) = island else { return XCTFail("expected requiredPack, got \(island)") }
        XCTAssertEqual(p.runtimeLabel, "Offline island")
        let live = resolve(runtime: "live_view", packs: ["content-pack@1.0.0"], packStore: store)
        guard case let .requiredPack(l) = live else { return XCTFail("expected requiredPack, got \(live)") }
        XCTAssertEqual(l.runtimeLabel, "LiveView")
    }

    func test_pack_block_wins_over_a_bad_origin_for_islands() {
        let store = PackStore(requiredVersions: ["content-pack": "1.0.0"], inventory: [])
        let m = manifest(runtime: "offline_island", packs: ["content-pack@1.0.0"])
        let r = request(origin: "https://evil.example.com")
        guard case .requiredPack = coordinator(m, r, packStore: store).resolve(request: r, manifest: m) else {
            return XCTFail("pack check must precede origin check")
        }
    }

    func test_island_with_non_allowlisted_origin_is_origin_denied() {
        let r = request(origin: "https://evil.example.com")
        let island = denial(resolve(runtime: "offline_island", request: r))
        XCTAssertEqual(content(island), content(denial(resolve(runtime: "live_view", request: r))))
        XCTAssertEqual(island?.reason, .originDenied)
    }

    // MARK: closed runtime allowlist (D-14, T-181-18)

    func test_near_miss_and_unknown_runtimes_are_denied_with_the_accurate_hint() {
        for runtime in ["Offline_Island", "offline-island", "offline_island ", "liveview", "", "adapter", "LIVE_VIEW"] {
            let d = denial(resolve(runtime: runtime))
            XCTAssertEqual(d?.reason, .compatibilityMismatch, "runtime \(runtime.debugDescription)")
            XCTAssertEqual(d?.message, "This runtime is not available in the bounded shell.", "runtime \(runtime.debugDescription)")
            XCTAssertEqual(d?.hint, runtimeHint, "runtime \(runtime.debugDescription)")
        }
    }

    // MARK: host commands share the live_view grant (D-12)

    private func islandWorld() throws -> SeamWorld {
        var world = try SeamWorld.load()
        let lesson = world.route(seamLessonID)
        world.manifest = ShellManifest(
            compatibility: world.manifest.compatibility,
            routes: world.manifest.routes.merging([seamLessonID: ShellManifest.Route(
                id: lesson.id, path: lesson.path, runtime: "offline_island", entry: lesson.entry,
                capabilities: lesson.capabilities, packs: lesson.packs, transfers: lesson.transfers,
                allowlistedOrigins: lesson.allowlistedOrigins, hostCommands: lesson.hostCommands
            )]) { _, new in new }
        )
        return world
    }

    func test_seam_lesson_island_carries_registered_host_command() throws {
        let world = try islandWorld()
        let delegate = SeamRecordingDelegate(registered: [seamLessonCommand])
        let coordinator = world.coordinator(entry: seamLessonID, delegate: delegate)
        coordinator.bootstrapIfNeeded()
        guard case let .offlineIsland(session) = coordinator.presentation else {
            return XCTFail("expected offlineIsland, got \(coordinator.presentation)")
        }
        XCTAssertEqual(session.runtime, .offlineIsland)
        XCTAssertEqual(session.capabilities[seamLessonCommand], "1.0.0")
        XCTAssertEqual(session.hostCommandDenials, [:])
    }

    func test_seam_lesson_island_without_registration_records_not_registered() throws {
        let world = try islandWorld()
        let coordinator = world.coordinator(entry: seamLessonID, delegate: SeamRecordingDelegate(registered: []))
        coordinator.bootstrapIfNeeded()
        guard case let .offlineIsland(session) = coordinator.presentation else {
            return XCTFail("expected offlineIsland, got \(coordinator.presentation)")
        }
        XCTAssertNil(session.capabilities[seamLessonCommand])
        XCTAssertEqual(session.hostCommandDenials, [seamLessonCommand: "not_registered"])
    }

    // MARK: native_screen unchanged

    func test_native_screen_route_keeps_its_own_denial_not_the_runtime_denial() {
        let d = denial(resolve(runtime: "native_screen"))
        XCTAssertNotEqual(d?.message, "This runtime is not available in the bounded shell.")
        XCTAssertNotEqual(d?.hint, runtimeHint)
    }

    // MARK: navigation

    func test_navigation_to_island_route_is_authorized_and_equals_a_fresh_resolve() throws {
        let world = try islandWorld()
        let delegate = SeamRecordingDelegate(registered: [seamLessonCommand])
        let coordinator = world.coordinator(entry: seamLessonID, delegate: delegate)
        let root = NavigationTopologyEntry(routeID: seamLessonID, rootTabID: "tab-0123456789abcdef", presentation: .root, parentRouteID: nil, deepLinkPosture: .allow, restorationPosture: .allow)
        let topology = NavigationTopology(topologySchemaVersion: "1.0.0", manifestSchemaVersion: "1.0.0", status: .ready, entries: [root])
        let nav = coordinator.makeNavigationCoordinator(topology: topology)
        XCTAssertEqual(nav.selectRoot(routeID: seamLessonID), .authorized)
        let tab = try XCTUnwrap(nav.selectedTabID)
        guard case let .offlineIsland(navigated)? = nav.stacks[tab]?.last?.presentation else {
            return XCTFail("expected offlineIsland on the navigation stack")
        }
        let baseline = world.activations["lesson"]!
        let fresh = ActivationRequest(
            routeID: seamLessonID, url: nil, source: .inAppNavigation, origin: baseline.origin,
            manifestSource: baseline.manifestSource, bridgeProtocolVersion: baseline.bridgeProtocolVersion,
            nativeRuntimeVersion: baseline.nativeRuntimeVersion, correlationID: baseline.correlationID
        )
        guard case let .offlineIsland(direct) = coordinator.resolve(request: fresh, manifest: world.manifest) else {
            return XCTFail("fresh resolve was not offlineIsland")
        }
        XCTAssertEqual(navigated, direct)
    }
}
