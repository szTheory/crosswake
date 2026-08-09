import XCTest
@testable import CrosswakeShellCore

final class HostBridgeCommandTests: XCTestCase {
    func test_declared_host_command_runs_only_after_core_validation() {
        let delegate = RecordingHostDelegate()
        let session = session(capabilities: ["host.accrue.purchase": "1.0.0"])
        let channel = BridgeChannel(
            session: session,
            transferCoordinator: nil,
            replySink: { _ in },
            config: CrosswakeShellConfig(hostBridgeCommandDelegate: delegate)
        )

        var reply: BridgeReplyEnvelope?
        channel.evaluate(request(command: "host.accrue.purchase")) { reply = $0 }

        XCTAssertEqual(reply?.status, "ok")
        XCTAssertEqual(delegate.commands, ["host.accrue.purchase"])
    }

    func test_host_command_denies_before_delegate_for_wrong_route_or_undeclared_command() {
        let delegate = RecordingHostDelegate()
        let channel = BridgeChannel(
            session: session(capabilities: ["host.accrue.purchase": "1.0.0"]),
            transferCoordinator: nil,
            replySink: { _ in },
            config: CrosswakeShellConfig(hostBridgeCommandDelegate: delegate)
        )

        var wrongRoute: BridgeReplyEnvelope?
        channel.evaluate(request(command: "host.accrue.purchase", routeID: "other")) { wrongRoute = $0 }
        XCTAssertEqual(wrongRoute?.denial?.denial.reason, "inactive_route")

        var unknown: BridgeReplyEnvelope?
        channel.evaluate(request(command: "host.accrue.restore")) { unknown = $0 }
        XCTAssertEqual(unknown?.denial?.denial.reason, "undeclared_capability")
        XCTAssertTrue(delegate.commands.isEmpty)
    }

    private func session(capabilities: [String: String]) -> LiveViewSession {
        LiveViewSession(
            routeID: "study",
            url: URL(string: "https://app.example.com/study")!,
            allowedOrigin: URL(string: "https://app.example.com")!,
            bridgeProtocolVersion: "1.1.0",
            nativeRuntimeVersion: "1.0.0",
            threadID: "thread",
            installedPacks: [:],
            routeRequiredPacks: [],
            capabilities: capabilities,
            declaredTransfers: []
        )
    }

    private func request(command: String, routeID: String = "study") -> BridgeRequestEnvelope {
        BridgeRequestEnvelope(
            protocolName: "crosswake.bridge",
            version: "1.1.0",
            command: command,
            capability: command,
            routeID: routeID,
            activeRouteID: routeID,
            origin: "https://app.example.com",
            nativeRuntimeVersion: "1.0.0",
            correlationID: "correlation",
            capabilities: [command: "1.0.0"],
            installedPacks: [:],
            payload: [:]
        )
    }
}

private final class RecordingHostDelegate: HostBridgeCommandDelegate {
    var registeredCommands: [String] { ["host.accrue.purchase"] }
    private(set) var commands: [String] = []

    func handle(command: String, payload: [String: String], correlationID: String, completion: @escaping (BridgeChannel.CommandResult) -> Void) {
        commands.append(command)
        completion(.success(["result": "submitted"]))
    }
}
