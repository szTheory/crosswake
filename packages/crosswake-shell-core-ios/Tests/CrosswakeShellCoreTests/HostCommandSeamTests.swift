import XCTest
@testable import CrosswakeShellCore

let seamLessonID = "route-aaaaaaaaaaaaaaaa"
let seamReviewID = "route-bbbbbbbbbbbbbbbb"
let seamPlainID = "route-cccccccccccccccc"
let seamLessonCommand = "host.lesson.audio.play"
let seamReviewCommand = "host.review.camera.scan"

/// Recording host delegate. Tests keep a strong reference because the config holds it weakly.
final class SeamRecordingDelegate: HostBridgeCommandDelegate {
    let registered: [String]
    private(set) var commands: [String] = []

    init(registered: [String]) { self.registered = registered }

    var registeredCommands: [String] { registered }

    func handle(command: String, payload: [String: String], correlationID: String, completion: @escaping (BridgeChannel.CommandResult) -> Void) {
        commands.append(command)
        completion(.success(["result": "ok"]))
    }
}

/// The generated 181-03 fixture, with route ids rewritten to opaque topology ids and every
/// route made a live_view route (the shell resolves only live_view and native_screen).
struct SeamWorld {
    var manifest: ShellManifest
    var activations: [String: ActivationRequest]

    static let idMap = ["lesson": seamLessonID, "review": seamReviewID, "plain": seamPlainID]

    static func load(legacy: Bool = false) throws -> SeamWorld {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "host_command_seam_fixture", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let manifestData = try JSONSerialization.data(withJSONObject: try XCTUnwrap(root[legacy ? "legacy_manifest" : "manifest"]))
        let decoded = try JSONDecoder().decode(ShellManifest.self, from: manifestData)
        var routes: [String: ShellManifest.Route] = [:]
        for (name, route) in decoded.routes {
            let id = try XCTUnwrap(idMap[name])
            routes[id] = ShellManifest.Route(
                id: id, path: route.path, runtime: "live_view", entry: "external",
                capabilities: route.capabilities, packs: route.packs, transfers: route.transfers,
                allowlistedOrigins: route.allowlistedOrigins, hostCommands: route.hostCommands
            )
        }
        let activationData = try JSONSerialization.data(withJSONObject: try XCTUnwrap(root["activations"]))
        let rawActivations = try JSONDecoder().decode([String: ActivationRequest].self, from: activationData)
        var activations: [String: ActivationRequest] = [:]
        for (name, a) in rawActivations {
            activations[name] = ActivationRequest(
                routeID: try XCTUnwrap(idMap[name]), url: a.url, source: a.source, origin: a.origin,
                manifestSource: a.manifestSource, bridgeProtocolVersion: a.bridgeProtocolVersion,
                nativeRuntimeVersion: a.nativeRuntimeVersion, correlationID: a.correlationID,
                threadID: a.threadID, declaredPackRequirements: a.declaredPackRequirements,
                installedPacks: a.installedPacks, capabilities: a.capabilities
            )
        }
        return SeamWorld(
            manifest: ShellManifest(compatibility: decoded.compatibility, routes: routes),
            activations: activations
        )
    }

    func route(_ id: String) -> ShellManifest.Route { manifest.routes[id]! }

    func replacing(_ id: String, hostCommands: [String: String]?) -> SeamWorld {
        var copy = self
        let r = route(id)
        copy.manifest = ShellManifest(
            compatibility: manifest.compatibility,
            routes: manifest.routes.merging([id: ShellManifest.Route(
                id: r.id, path: r.path, runtime: r.runtime, entry: r.entry, capabilities: r.capabilities,
                packs: r.packs, transfers: r.transfers, allowlistedOrigins: r.allowlistedOrigins, hostCommands: hostCommands
            )]) { _, new in new }
        )
        return copy
    }

    func withSeam(_ version: String?) -> SeamWorld {
        var copy = self
        copy.manifest = ShellManifest(
            compatibility: ShellManifest.Compatibility(nativeRuntimeVersion: manifest.compatibility.nativeRuntimeVersion, hostCommandSeamVersion: version),
            routes: manifest.routes
        )
        return copy
    }

    @MainActor
    func coordinator(entry: String, delegate: SeamRecordingDelegate?) -> ActivationCoordinator {
        let activation = activations[entry == seamLessonID ? "lesson" : entry == seamReviewID ? "review" : "plain"]!
        let manifest = self.manifest
        return ActivationCoordinator(
            manifestLoader: { manifest },
            requestLoader: { activation },
            packStore: PackStore(requirements: [], provider: nil),
            config: CrosswakeShellConfig(hostBridgeCommandDelegate: delegate)
        )
    }
}

@MainActor
final class HostCommandSeamTests: XCTestCase {
    private func session(_ presentation: ShellPresentation, file: StaticString = #filePath, line: UInt = #line) throws -> LiveViewSession {
        guard case let .liveView(session) = presentation else {
            XCTFail("expected live view, got \(presentation)", file: file, line: line)
            throw XCTSkip("not a live view")
        }
        return session
    }

    private func dispatch(_ session: LiveViewSession, command: String, delegate: SeamRecordingDelegate) -> BridgeReplyEnvelope? {
        let channel = BridgeChannel(
            session: session, transferCoordinator: nil, replySink: { _ in },
            config: CrosswakeShellConfig(hostBridgeCommandDelegate: delegate)
        )
        var reply: BridgeReplyEnvelope?
        channel.evaluate(
            BridgeRequestEnvelope(
                protocolName: "crosswake.bridge", version: "1.1.0", command: command, capability: command,
                routeID: session.routeID, activeRouteID: session.routeID, origin: "https://seam.crosswake.test",
                nativeRuntimeVersion: "1.0.0", correlationID: "c", capabilities: [command: "1.0.0"],
                installedPacks: [:], payload: [:]
            )
        ) { reply = $0 }
        return reply
    }

    func test_declared_registered_command_reaches_delegate() throws {
        let world = try SeamWorld.load()
        let delegate = SeamRecordingDelegate(registered: [seamLessonCommand])
        let coordinator = world.coordinator(entry: seamLessonID, delegate: delegate)
        coordinator.bootstrapIfNeeded()

        let lesson = try session(coordinator.presentation)
        XCTAssertEqual(lesson.capabilities[seamLessonCommand], "1.0.0")
        XCTAssertEqual(lesson.hostCommandDenials, [:])

        let reply = dispatch(lesson, command: seamLessonCommand, delegate: delegate)
        XCTAssertEqual(reply?.status, "ok")
        XCTAssertEqual(delegate.commands, [seamLessonCommand])
    }

    func test_command_registered_for_route_a_is_denied_on_route_b() throws {
        let world = try SeamWorld.load()
        let delegate = SeamRecordingDelegate(registered: [seamLessonCommand])
        let coordinator = world.coordinator(entry: seamLessonID, delegate: delegate)
        coordinator.bootstrapIfNeeded()

        let review = try session(coordinator.resolve(request: reviewRequest(world), manifest: world.manifest))
        XCTAssertNil(review.capabilities[seamLessonCommand])

        let reply = dispatch(review, command: seamLessonCommand, delegate: delegate)
        XCTAssertEqual(reply?.denial?.denial.reason, "undeclared_capability")
        XCTAssertEqual(delegate.commands, [])
    }

    func reviewRequest(_ world: SeamWorld) -> ActivationRequest {
        world.activations["review"]!
    }

    // D-10 table: 3 routes x 3 registered sets x 7 declared versions = 63 rows.
    func test_grant_table_routes_by_registered_set_by_version() throws {
        let world = try SeamWorld.load()
        let routeIDs = [seamLessonID, seamReviewID, seamPlainID]
        let registeredSets: [[String]] = [[], [seamLessonCommand], [seamLessonCommand, seamReviewCommand]]
        let versions = ["1.0.0", "1.4.2", "2.0.0", "9.0.0", "0.9.0", "1.0", "x"]
        let supported: Set<String> = ["1.0.0", "1.4.2"]
        var rows = 0

        for routeID in routeIDs {
            for registered in registeredSets {
                for version in versions {
                    let declaredNames = Array((world.route(routeID).hostCommands ?? [:]).keys)
                    let declared = Dictionary(uniqueKeysWithValues: declaredNames.map { ($0, version) })
                    let route = world.replacing(routeID, hostCommands: declared).route(routeID)

                    let result = grantHostCommands(
                        route: route, request: world.activations["lesson"]!, entryRouteID: nil,
                        registered: registered, seamDemand: nil
                    )

                    var expectedGranted: [String: String] = [:]
                    var expectedDenials: [String: String] = [:]
                    for name in declaredNames {
                        if !registered.contains(name) {
                            expectedDenials[name] = "not_registered"
                        } else if supported.contains(version) {
                            expectedGranted[name] = version
                        } else {
                            expectedDenials[name] = "version_unsupported"
                        }
                    }
                    XCTAssertEqual(result.granted, expectedGranted, "\(routeID) \(registered) \(version)")
                    XCTAssertEqual(result.denials, expectedDenials, "\(routeID) \(registered) \(version)")
                    rows += 1
                }
            }
        }
        XCTAssertEqual(rows, 63)
    }

    func test_supported_versions_are_granted_and_others_are_version_unsupported_through_resolve() throws {
        let world = try SeamWorld.load()
        for version in ["1.0.0", "1.4.2"] {
            let delegate = SeamRecordingDelegate(registered: [seamLessonCommand])
            let w = world.replacing(seamLessonID, hostCommands: [seamLessonCommand: version])
            let coordinator = w.coordinator(entry: seamLessonID, delegate: delegate)
            coordinator.bootstrapIfNeeded()
            let s = try session(coordinator.presentation)
            XCTAssertEqual(s.capabilities[seamLessonCommand], version)
            XCTAssertEqual(s.hostCommandDenials, [:])
        }
        for version in ["2.0.0", "9.0.0", "0.9.0"] {
            let delegate = SeamRecordingDelegate(registered: [seamLessonCommand])
            let w = world.replacing(seamLessonID, hostCommands: [seamLessonCommand: version])
            let coordinator = w.coordinator(entry: seamLessonID, delegate: delegate)
            coordinator.bootstrapIfNeeded()
            let s = try session(coordinator.presentation)
            XCTAssertNil(s.capabilities[seamLessonCommand])
            XCTAssertEqual(s.hostCommandDenials, [seamLessonCommand: "version_unsupported"])
            XCTAssertEqual(
                coordinator.hostCommandDiagnostics,
                [HostCommandDiagnostic(routeID: seamLessonID, command: seamLessonCommand, issue: "version_unsupported")]
            )
        }
    }

    func test_registered_but_undeclared_command_never_appears_and_names_must_match_exactly() throws {
        let world = try SeamWorld.load()
        let delegate = SeamRecordingDelegate(registered: [seamReviewCommand, "host.lesson.audio", "host.lesson.audio.play.extra"])
        let coordinator = world.coordinator(entry: seamLessonID, delegate: delegate)
        coordinator.bootstrapIfNeeded()
        let s = try session(coordinator.presentation)
        XCTAssertEqual(s.capabilities.filter { $0.key.hasPrefix("host.") }, [:])
        XCTAssertEqual(s.hostCommandDenials, [seamLessonCommand: "not_registered"])
    }

    func test_registered_order_does_not_change_the_result() throws {
        let world = try SeamWorld.load()
        let route = world.route(seamLessonID).hostCommands == nil
            ? world.route(seamLessonID)
            : world.replacing(seamLessonID, hostCommands: [seamLessonCommand: "1.0.0", "host.lesson.quiz.open": "1.2.0"]).route(seamLessonID)
        let a = grantHostCommands(route: route, request: world.activations["lesson"]!, entryRouteID: nil, registered: [seamLessonCommand, "host.lesson.quiz.open"], seamDemand: nil)
        let b = grantHostCommands(route: route, request: world.activations["lesson"]!, entryRouteID: nil, registered: ["host.lesson.quiz.open", seamLessonCommand], seamDemand: nil)
        XCTAssertEqual(a.granted, b.granted)
        XCTAssertEqual(a.denials, b.denials)
        XCTAssertEqual(a.granted, [seamLessonCommand: "1.0.0", "host.lesson.quiz.open": "1.2.0"])
    }

    func test_denial_diagnostics_are_sorted_by_command() throws {
        let world = try SeamWorld.load().replacing(seamLessonID, hostCommands: ["host.z.last.run": "1.0.0", "host.a.first.run": "1.0.0", "host.m.mid.run": "1.0.0"])
        let coordinator = world.coordinator(entry: seamLessonID, delegate: SeamRecordingDelegate(registered: []))
        coordinator.bootstrapIfNeeded()
        XCTAssertEqual(
            coordinator.hostCommandDiagnostics.map { $0.command },
            ["host.a.first.run", "host.m.mid.run", "host.z.last.run"]
        )
    }

    func test_seam_demand_equal_grants_and_higher_minor_or_major_grants_nothing() throws {
        let world = try SeamWorld.load()
        let route = world.route(seamLessonID)
        let request = world.activations["lesson"]!
        let ok = grantHostCommands(route: route, request: request, entryRouteID: nil, registered: [seamLessonCommand], seamDemand: HostCommandSeam.version)
        XCTAssertEqual(ok.granted, [seamLessonCommand: "1.0.0"])
        for demand in ["1.1.0", "2.0.0"] {
            let denied = grantHostCommands(route: route, request: request, entryRouteID: nil, registered: [seamLessonCommand], seamDemand: demand)
            XCTAssertEqual(denied.granted, [:])
            XCTAssertEqual(denied.denials, [seamLessonCommand: "seam_unsupported"])
        }
        let absent = grantHostCommands(route: route, request: request, entryRouteID: nil, registered: [seamLessonCommand], seamDemand: nil)
        XCTAssertEqual(absent.granted, [seamLessonCommand: "1.0.0"])
    }

    func test_manifest_seam_key_flows_through_resolve() throws {
        let world = try SeamWorld.load()
        XCTAssertEqual(world.manifest.compatibility.hostCommandSeamVersion, "1.0.0")
        let newer = world.withSeam("1.1.0")
        let delegate = SeamRecordingDelegate(registered: [seamLessonCommand])
        let coordinator = newer.coordinator(entry: seamLessonID, delegate: delegate)
        coordinator.bootstrapIfNeeded()
        let s = try session(coordinator.presentation)
        XCTAssertNil(s.capabilities[seamLessonCommand])
        XCTAssertEqual(s.hostCommandDenials, [seamLessonCommand: "seam_unsupported"])
    }

    func test_empty_registered_and_nil_delegate_grant_nothing_and_empty_declarations_grant_nothing() throws {
        let world = try SeamWorld.load()
        let nilDelegate = world.coordinator(entry: seamLessonID, delegate: nil)
        nilDelegate.bootstrapIfNeeded()
        let s = try session(nilDelegate.presentation)
        XCTAssertEqual(s.capabilities.filter { $0.key.hasPrefix("host.") }, [:])
        XCTAssertEqual(s.hostCommandDenials, [seamLessonCommand: "not_registered"])

        let plain = world.coordinator(entry: seamPlainID, delegate: SeamRecordingDelegate(registered: [seamLessonCommand]))
        plain.bootstrapIfNeeded()
        let p = try session(plain.presentation)
        XCTAssertEqual(p.capabilities, [:])
        XCTAssertEqual(p.hostCommandDenials, [:])
    }

    func test_command_name_grammar_and_version_range_helpers() {
        for ok in ["host.lesson.audio.play", "host.a.b", "host.a1.b_2.c3"] {
            XCTAssertTrue(HostCommandSeam.isValidName(ok), ok)
        }
        for bad in ["host.x", "HOST.x.y", "host.A.b", "host.a.b.c.d.e", "host.crosswake.x.y", "host.bridge.x.y", "host.a.1b", "host.é.b", "host..a.b", "app.info.get", ""] {
            XCTAssertFalse(HostCommandSeam.isValidName(bad), bad)
        }
        for ok in ["1.0.0", "1.4.2", "1.10.200"] {
            XCTAssertTrue(HostCommandSeam.supportsCommandVersion(ok), ok)
        }
        for bad in ["2.0.0", "9.0.0", "0.9.0", "1.0", "x", "v1.0.0", "1.0.0-beta", "1.0.0+b", "1..0", "", "1.0.0.0"] {
            XCTAssertFalse(HostCommandSeam.supportsCommandVersion(bad), bad)
        }
        XCTAssertEqual(HostCommandSeam.supportedCommandMajor, 1)
    }
}
