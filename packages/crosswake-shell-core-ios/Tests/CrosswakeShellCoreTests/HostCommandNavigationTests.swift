import XCTest
@testable import CrosswakeShellCore

@MainActor
final class HostCommandNavigationTests: XCTestCase {
    private func topology() -> NavigationTopology {
        let root = NavigationTopologyEntry(routeID: seamLessonID, rootTabID: "tab-0123456789abcdef", presentation: .root, parentRouteID: nil, deepLinkPosture: .allow, restorationPosture: .allow)
        let push = NavigationTopologyEntry(routeID: seamReviewID, rootTabID: root.rootTabID, presentation: .push, parentRouteID: root.routeID, deepLinkPosture: .allow, restorationPosture: .allow)
        return NavigationTopology(topologySchemaVersion: "1.0.0", manifestSchemaVersion: "1.0.0", status: .ready, entries: [root, push])
    }

    /// A fresh resolve(request:manifest:) of the route on the same coordinator (same thread id), with no navigation history in the request.
    private func freshSession(world: SeamWorld, routeID: String, coordinator: ActivationCoordinator, request: ActivationRequest? = nil) throws -> LiveViewSession {
        let baseline = world.activations["lesson"]!
        let built = request ?? ActivationRequest(
            routeID: routeID, url: nil, source: .inAppNavigation, origin: baseline.origin,
            manifestSource: baseline.manifestSource, bridgeProtocolVersion: baseline.bridgeProtocolVersion,
            nativeRuntimeVersion: baseline.nativeRuntimeVersion, correlationID: baseline.correlationID
        )
        guard case let .liveView(session) = coordinator.resolve(request: built, manifest: world.manifest) else {
            XCTFail("fresh resolve was not a live view")
            throw XCTSkip("denied")
        }
        return session
    }

    private func liveSession(_ presentation: ShellPresentation?) throws -> LiveViewSession {
        guard case let .liveView(session)? = presentation else {
            XCTFail("expected live view, got \(String(describing: presentation))")
            throw XCTSkip("denied")
        }
        return session
    }

    func test_navigation_matrix_each_step_equals_a_fresh_resolve() throws {
        let world = try SeamWorld.load()
        let delegate = SeamRecordingDelegate(registered: [seamLessonCommand, seamReviewCommand])
        let coordinator = world.coordinator(entry: seamLessonID, delegate: delegate)
        let nav = coordinator.makeNavigationCoordinator(topology: topology())

        // 1. A (root)
        XCTAssertEqual(nav.selectRoot(routeID: seamLessonID), .authorized)
        let tab = try XCTUnwrap(nav.selectedTabID)
        let a1 = try liveSession(nav.stacks[tab]?.last?.presentation)
        XCTAssertEqual(a1, try freshSession(world: world, routeID: seamLessonID, coordinator: coordinator))
        XCTAssertEqual(a1.capabilities[seamLessonCommand], "1.0.0")

        // 2. B (push)
        let push = NavigationTransition(protocolName: "crosswake.navigation_transition", version: "1.0.0", transitionID: "nav-0123456789abcdef", kind: .pushNavigate, routeID: seamReviewID, restorationRef: nil)
        XCTAssertEqual(nav.apply(push), .applied)
        let b = try liveSession(nav.stacks[tab]?.last?.presentation)
        XCTAssertEqual(b, try freshSession(world: world, routeID: seamReviewID, coordinator: coordinator))
        XCTAssertNil(b.capabilities[seamLessonCommand])
        XCTAssertEqual(b.capabilities[seamReviewCommand], "1.1.0")

        // 3. back to A
        XCTAssertEqual(nav.completeNativePop(completed: true), .authorized)
        let a2 = try liveSession(nav.stacks[tab]?.last?.presentation)
        XCTAssertEqual(a2, a1)
        XCTAssertNil(a2.capabilities[seamReviewCommand])

        // 4. deep link to B, 5. deep link to A
        let reviewURL = try XCTUnwrap(URL(string: "https://seam.crosswake.test/review"))
        coordinator.bootstrapIfNeeded()
        coordinator.openURL(reviewURL)
        let deepB = try liveSession(coordinator.presentation)
        let baseline = world.activations["lesson"]!
        let deepRequest = ActivationRequest.forIncomingURL(reviewURL, source: .deepLink, seededBy: baseline)
        XCTAssertEqual(deepB, try freshSession(world: world, routeID: seamReviewID, coordinator: coordinator, request: deepRequest))
        XCTAssertNil(deepB.capabilities[seamLessonCommand])

        let lessonURL = try XCTUnwrap(URL(string: "https://seam.crosswake.test/lesson"))
        coordinator.openURL(lessonURL)
        let deepA = try liveSession(coordinator.presentation)
        XCTAssertEqual(deepA.capabilities[seamLessonCommand], "1.0.0")
        XCTAssertNil(deepA.capabilities[seamReviewCommand])
    }

    func test_command_registered_only_for_a_is_denied_on_b_after_navigating_there() throws {
        let world = try SeamWorld.load()
        let delegate = SeamRecordingDelegate(registered: [seamLessonCommand])
        let coordinator = world.coordinator(entry: seamLessonID, delegate: delegate)
        let nav = coordinator.makeNavigationCoordinator(topology: topology())
        XCTAssertEqual(nav.selectRoot(routeID: seamLessonID), .authorized)
        let push = NavigationTransition(protocolName: "crosswake.navigation_transition", version: "1.0.0", transitionID: "nav-0123456789abcdef", kind: .pushNavigate, routeID: seamReviewID, restorationRef: nil)
        XCTAssertEqual(nav.apply(push), .applied)
        let tab = try XCTUnwrap(nav.selectedTabID)
        let b = try liveSession(nav.stacks[tab]?.last?.presentation)
        XCTAssertEqual(b.capabilities.filter { $0.key.hasPrefix("host.") }, [:])
        XCTAssertEqual(b.hostCommandDenials, [seamReviewCommand: "not_registered"])
    }

    // MARK: D-28 legacy path (manifest without host_commands)

    func test_legacy_entry_route_denies_its_registered_command_and_other_routes_deny_theirs() throws {
        let world = try SeamWorld.load(legacy: true)
        XCTAssertNil(world.route(seamLessonID).hostCommands)
        let delegate = SeamRecordingDelegate(registered: [seamLessonCommand, seamReviewCommand])
        let coordinator = world.coordinator(entry: seamLessonID, delegate: delegate)
        coordinator.bootstrapIfNeeded()
        let entry = try liveSession(coordinator.presentation)
        XCTAssertEqual(entry.capabilities.filter { $0.key.hasPrefix("host.") }, [:])
        XCTAssertEqual(entry.hostCommandDenials, [seamLessonCommand: "not_registered"])
        XCTAssertTrue(coordinator.hostCommandDiagnostics.contains(HostCommandDiagnostic(routeID: seamLessonID, command: seamLessonCommand, issue: "not_registered")))

        let nav = coordinator.makeNavigationCoordinator(topology: topology())
        XCTAssertEqual(nav.selectRoot(routeID: seamLessonID), .authorized)
        let tab = try XCTUnwrap(nav.selectedTabID)
        XCTAssertEqual(try liveSession(nav.stacks[tab]?.last?.presentation).capabilities.filter { $0.key.hasPrefix("host.") }, [:])
        let push = NavigationTransition(protocolName: "crosswake.navigation_transition", version: "1.0.0", transitionID: "nav-0123456789abcdef", kind: .pushNavigate, routeID: seamReviewID, restorationRef: nil)
        XCTAssertEqual(nav.apply(push), .applied)
        let review = try liveSession(nav.stacks[tab]?.last?.presentation)
        XCTAssertEqual(review.capabilities.filter { $0.key.hasPrefix("host.") }, [:])
        XCTAssertEqual(review.hostCommandDenials, [seamReviewCommand: "not_registered"])

        // A deep link to review seeded from the lesson baseline grants nothing.
        coordinator.openURL(try XCTUnwrap(URL(string: "https://seam.crosswake.test/review")))
        XCTAssertEqual(try liveSession(coordinator.presentation).capabilities.filter { $0.key.hasPrefix("host.") }, [:])
    }

    private func legacyLessonWithoutRequestKey() throws -> SeamWorld {
        var world = try SeamWorld.load(legacy: true)
        let lesson = world.activations["lesson"]!
        world.activations["lesson"] = ActivationRequest(
            routeID: lesson.routeID, url: lesson.url, source: lesson.source, origin: lesson.origin,
            manifestSource: lesson.manifestSource, bridgeProtocolVersion: lesson.bridgeProtocolVersion,
            nativeRuntimeVersion: lesson.nativeRuntimeVersion, correlationID: lesson.correlationID
        )
        return world
    }

    func test_legacy_activation_lacking_the_command_grants_nothing() throws {
        let world = try legacyLessonWithoutRequestKey()
        let delegate = SeamRecordingDelegate(registered: [seamLessonCommand])
        let coordinator = world.coordinator(entry: seamLessonID, delegate: delegate)
        coordinator.bootstrapIfNeeded()
        let session = try liveSession(coordinator.presentation)
        XCTAssertEqual(session.capabilities.filter { $0.key.hasPrefix("host.") }, [:])
        XCTAssertEqual(session.hostCommandDenials, [seamLessonCommand: "not_registered"])
    }

    func test_legacy_entry_request_at_an_unsupported_version_is_denied_version_unsupported() throws {
        var world = try SeamWorld.load(legacy: true)
        let lesson = world.activations["lesson"]!
        world.activations["lesson"] = ActivationRequest(
            routeID: lesson.routeID, url: lesson.url, source: lesson.source, origin: lesson.origin,
            manifestSource: lesson.manifestSource, bridgeProtocolVersion: lesson.bridgeProtocolVersion,
            nativeRuntimeVersion: lesson.nativeRuntimeVersion, correlationID: lesson.correlationID,
            capabilities: [seamLessonCommand: "2.0.0"]
        )
        let delegate = SeamRecordingDelegate(registered: [seamLessonCommand])
        let coordinator = world.coordinator(entry: seamLessonID, delegate: delegate)
        coordinator.bootstrapIfNeeded()
        let session = try liveSession(coordinator.presentation)
        XCTAssertEqual(session.capabilities.filter { $0.key.hasPrefix("host.") }, [:])
        XCTAssertEqual(session.hostCommandDenials, [seamLessonCommand: "version_unsupported"])
    }

    func test_legacy_declared_command_the_app_did_not_register_is_denied_with_a_diagnostic() throws {
        let world = try SeamWorld.load(legacy: true)
        let coordinator = world.coordinator(entry: seamLessonID, delegate: SeamRecordingDelegate(registered: []))
        coordinator.bootstrapIfNeeded()
        let session = try liveSession(coordinator.presentation)
        XCTAssertEqual(session.capabilities.filter { $0.key.hasPrefix("host.") }, [:])
        XCTAssertEqual(session.hostCommandDenials, [seamLessonCommand: "not_registered"])
        XCTAssertEqual(
            coordinator.hostCommandDiagnostics,
            [HostCommandDiagnostic(routeID: seamLessonID, command: seamLessonCommand, issue: "not_registered")]
        )
    }

    func test_legacy_plain_route_records_no_denial_and_no_diagnostic() throws {
        let world = try SeamWorld.load(legacy: true)
        let coordinator = world.coordinator(entry: seamPlainID, delegate: SeamRecordingDelegate(registered: [seamLessonCommand]))
        coordinator.bootstrapIfNeeded()
        let session = try liveSession(coordinator.presentation)
        XCTAssertEqual(session.capabilities.filter { $0.key.hasPrefix("host.") }, [:])
        XCTAssertEqual(session.hostCommandDenials, [:])
        XCTAssertEqual(coordinator.hostCommandDiagnostics, [])
    }

    // MARK: D-09 fallbacks

    func test_throwing_manifest_loader_records_manifest_unavailable() {
        struct Boom: Error {}
        let coordinator = ActivationCoordinator(
            manifestLoader: { throw Boom() },
            requestLoader: { throw Boom() },
            packStore: PackStore(requirements: [], provider: nil),
            config: CrosswakeShellConfig()
        )
        _ = coordinator.makeNavigationCoordinator(topology: topology())
        XCTAssertEqual(coordinator.hostCommandDiagnostics, [HostCommandDiagnostic(routeID: nil, command: nil, issue: "manifest_unavailable")])
    }

    func test_throwing_request_loader_records_request_unavailable_and_denies() throws {
        struct Boom: Error {}
        let world = try SeamWorld.load()
        let manifest = world.manifest
        let coordinator = ActivationCoordinator(
            manifestLoader: { manifest },
            requestLoader: { throw Boom() },
            packStore: PackStore(requirements: [], provider: nil),
            config: CrosswakeShellConfig()
        )
        let nav = coordinator.makeNavigationCoordinator(topology: topology())
        XCTAssertEqual(nav.selectRoot(routeID: seamLessonID), .denied)
        XCTAssertEqual(coordinator.hostCommandDiagnostics, [HostCommandDiagnostic(routeID: nil, command: nil, issue: "request_unavailable")])
    }

    func test_diagnostic_stores_only_route_command_and_issue() {
        let labels = Mirror(reflecting: HostCommandDiagnostic(routeID: "r", command: "c", issue: "i")).children.compactMap { $0.label }
        XCTAssertEqual(labels, ["routeID", "command", "issue"])
    }
}
