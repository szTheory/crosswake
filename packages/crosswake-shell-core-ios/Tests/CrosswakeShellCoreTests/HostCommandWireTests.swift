import XCTest
@testable import CrosswakeShellCore

@MainActor
final class HostCommandWireTests: XCTestCase {
    private func manifestJSON(routeExtra: String, compatExtra: String = "") -> Data {
        Data("""
        {"compatibility":{"native_runtime_version":"1.0.0"\(compatExtra)},
         "routes":{"lesson":{"id":"lesson","path":"/lesson","runtime":"live_view","entry":"internal_only",
         "capabilities":[],"packs":[],"transfers":[],"allowlisted_origins":["https://seam.crosswake.test"]\(routeExtra)}}}
        """.utf8)
    }

    private func decode(_ routeExtra: String, compatExtra: String = "") throws -> ShellManifest {
        try JSONDecoder().decode(ShellManifest.self, from: manifestJSON(routeExtra: routeExtra, compatExtra: compatExtra))
    }

    func test_generated_fixture_manifest_decodes() throws {
        let world = try SeamWorld.load()
        XCTAssertEqual(world.route(seamLessonID).hostCommands, [seamLessonCommand: "1.0.0"])
        XCTAssertEqual(world.route(seamReviewID).hostCommands, [seamReviewCommand: "1.1.0"])
        XCTAssertEqual(world.route(seamPlainID).hostCommands, [:])
        XCTAssertEqual(world.manifest.compatibility.hostCommandSeamVersion, "1.0.0")
        let legacy = try SeamWorld.load(legacy: true)
        XCTAssertNil(legacy.route(seamLessonID).hostCommands)
        XCTAssertNil(legacy.manifest.compatibility.hostCommandSeamVersion)
    }

    func test_valid_shapes() throws {
        XCTAssertNil(try decode("").routes["lesson"]?.hostCommands)
        XCTAssertEqual(try decode(",\"host_commands\":null").routes["lesson"]?.hostCommands, [:])
        XCTAssertEqual(try decode(",\"host_commands\":{}").routes["lesson"]?.hostCommands, [:])
        XCTAssertEqual(
            try decode(",\"host_commands\":{\"host.a.b\":\"1.0.0\"},\"future_key\":{\"x\":1}", compatExtra: ",\"future\":true").routes["lesson"]?.hostCommands,
            ["host.a.b": "1.0.0"]
        )
    }

    func test_invalid_shapes_throw() {
        let invalid = [
            ",\"host_commands\":[]",
            ",\"host_commands\":\"x\"",
            ",\"host_commands\":{\"HOST.x.y\":\"1.0.0\"}",
            ",\"host_commands\":{\"host.x\":\"1.0.0\"}",
            ",\"host_commands\":{\"host.a.b.c\":1}",
            ",\"host_commands\":{\"host.crosswake.a.b\":\"1.0.0\"}",
        ]
        for extra in invalid {
            XCTAssertThrowsError(try decode(extra), extra)
        }
    }

    func test_malformed_host_commands_block_boot() {
        let data = manifestJSON(routeExtra: ",\"host_commands\":[]")
        let coordinator = ActivationCoordinator(
            manifestLoader: { try JSONDecoder().decode(ShellManifest.self, from: data) },
            requestLoader: {
                ActivationRequest(
                    routeID: "lesson", url: nil, source: .coldStart, origin: "https://seam.crosswake.test",
                    manifestSource: .bundled, bridgeProtocolVersion: "1.1.0", nativeRuntimeVersion: "1.0.0",
                    correlationID: "c"
                )
            },
            packStore: PackStore(requirements: [], provider: nil),
            config: CrosswakeShellConfig()
        )
        coordinator.bootstrapIfNeeded()
        guard case let .denied(denial) = coordinator.presentation else {
            return XCTFail("expected a denial, got \(coordinator.presentation)")
        }
        XCTAssertEqual(denial.title, "Shell boot blocked")
    }
}
