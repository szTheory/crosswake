import XCTest
@testable import CrosswakeShellCore

@MainActor
final class ProtectedNotificationActivationTests: XCTestCase {
    func test_protected_activation_uses_allowed_request_and_never_adds_safe_fallback() {
        let coordinator = coordinator(manifest: manifest(entry: "external"))
        coordinator.activateAllowedNotification(NotificationOpenAllowedActivation(request: request(routeID: "dashboard")))

        guard case let .liveView(session) = coordinator.presentation else { return XCTFail("expected activation") }
        XCTAssertEqual(session.routeID, "dashboard")
    }

    func test_protected_activation_denial_has_no_safe_fallback() {
        let coordinator = coordinator(manifest: manifest(entry: "internal_only"))
        coordinator.activateAllowedNotification(NotificationOpenAllowedActivation(request: request(routeID: "dashboard")))

        guard case let .denied(denial) = coordinator.presentation else { return XCTFail("expected denial") }
        XCTAssertFalse(denial.actions.contains { if case .safeFallback = $0 { return true }; return false })
    }

    private func coordinator(manifest: ShellManifest) -> ActivationCoordinator {
        ActivationCoordinator(manifestLoader: { manifest }, requestLoader: { self.request(routeID: "dashboard") }, packStore: PackStore(requiredVersions: [:], inventory: []), config: CrosswakeShellConfig())
    }

    private func manifest(entry: String) -> ShellManifest {
        ShellManifest(compatibility: .init(nativeRuntimeVersion: "1.0.0"), routes: ["dashboard": .init(id: "dashboard", path: "/dashboard", runtime: "live_view", entry: entry, capabilities: [], packs: [], transfers: [], allowlistedOrigins: ["https://app.example.com"])])
    }

    private func request(routeID: String) -> ActivationRequest {
        ActivationRequest(routeID: routeID, url: nil, source: .notification, origin: "https://app.example.com", manifestSource: .bundled, bridgeProtocolVersion: "1", nativeRuntimeVersion: "1.0.0", correlationID: "trusted")
    }
}
