import XCTest
@testable import CrosswakeShellCore

final class NotificationRegistrationTests: XCTestCase {
    func test_permission_and_observation_do_not_imply_binding() {
        let delegate = RecordingRegistrationDelegate(binding: .rejected(reason: .hostRejected))
        let coordinator = NotificationRegistrationCoordinator(
            permissionStatusProvider: { .granted },
            delegate: delegate
        )

        coordinator.recordPermissionRequest(granted: true)
        XCTAssertEqual(coordinator.state, .permissionGranted)

        let outcome = coordinator.observeAPNSToken(Data("transient-token".utf8), scope: scope())
        XCTAssertEqual(outcome, .rejected(reason: .hostRejected))
        XCTAssertEqual(coordinator.state, .failed(reason: .hostRejected))
        XCTAssertFalse(coordinator.diagnostics.contains("transient-token"))
    }

    func test_denied_recheck_revokes_exact_binding_once_and_never_retains_token() throws {
        let transcript = try permissionLossTranscript()
        var status = NotificationPermissionStatus.granted
        let delegate = RecordingRegistrationDelegate(binding: .bound(bindingRef: transcript.bindingRef))
        let coordinator = NotificationRegistrationCoordinator(permissionStatusProvider: { status }, delegate: delegate)

        coordinator.recordPermissionRequest(granted: true)
        XCTAssertEqual(coordinator.observeAPNSToken(Data("forbidden-apns-token".utf8), scope: transcript.scope), .bound(bindingRef: transcript.bindingRef))

        status = .denied
        XCTAssertEqual(coordinator.recheckPermissionState(), .staleNoop)
        XCTAssertEqual(delegate.permissionLossCommands, [transcript.command])
        XCTAssertEqual(coordinator.state, .permissionDenied)
        XCTAssertFalse(coordinator.diagnostics.contains("forbidden-apns-token"))

        XCTAssertEqual(coordinator.recheckPermissionState(), .permissionDeniedNoop)
        XCTAssertEqual(delegate.permissionLossCommands.count, 1)
    }

    func test_capability_is_advertised_only_with_delegate() {
        XCTAssertFalse(CrosswakeShellConfig().registeredCapabilities.contains("notification_registration"))
        let delegate = RecordingRegistrationDelegate(binding: .rejected(reason: .hostRejected))
        XCTAssertTrue(CrosswakeShellConfig(notificationRegistrationDelegate: delegate).registeredCapabilities.contains("notification_registration"))
    }

    private func scope() -> NotificationRegistrationScope {
        NotificationRegistrationScope(tenantRef: "tenant-1", subjectRef: "subject-1", installationRef: "installation-1", provider: "apns", environment: "sandbox", topic: "com.example.app", sessionRef: "session-1", sessionVersion: "1", channel: "push")
    }

    private func permissionLossTranscript() throws -> NotificationPermissionLossTranscript {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "chimeway_notification_permission_loss_v1", withExtension: "json"))
        return try JSONDecoder().decode(NotificationPermissionLossTranscript.self, from: Data(contentsOf: url))
    }
}

private final class RecordingRegistrationDelegate: NotificationRegistrationDelegate {
    let binding: NotificationBindingOutcome
    var permissionLossCommands: [NotificationPermissionLossCommand] = []

    init(binding: NotificationBindingOutcome) { self.binding = binding }

    func bindObservedNotificationToken(_ token: Data, scope: NotificationRegistrationScope) -> NotificationBindingOutcome { binding }

    func revokeNotificationBindingForPermissionLoss(_ command: NotificationPermissionLossCommand) -> NotificationPermissionLossOutcome {
        permissionLossCommands.append(command)
        return .staleNoop
    }
}
