import Foundation
import XCTest
@testable import CrosswakeShell

@MainActor
final class BridgeChannelTests: XCTestCase {
    func testPermissionsStatusReturnsNormalizedNotificationsPayload() async {
        let channel = bridgeChannel(
            permissionsStatusProvider: PermissionStatusProvider { permissionAlias in
                guard permissionAlias == "notifications" else { return nil }

                return [
                    "alias": "notifications",
                    "status": "granted",
                    "detail.authorization_status": "authorized"
                ]
            }
        )

        let reply = await evaluate(
            channel,
            request: request(
                command: "permissions.status",
                capability: "permissions.status",
                correlationID: "perm-1",
                capabilities: [
                    "permissions.status": "1.0.0",
                    "notification_token": "1.0.0",
                    "file_picker": "1.0.0"
                ],
                payload: ["alias": "notifications"]
            )
        )

        XCTAssertEqual(reply.status, "ok")
        XCTAssertEqual(reply.payload["alias"], "notifications")
        XCTAssertEqual(reply.payload["status"], "granted")
        XCTAssertEqual(reply.payload["detail.authorization_status"], "authorized")
    }

    func testPermissionsStatusRejectsUnsupportedAliases() async {
        let channel = bridgeChannel(
            permissionsStatusProvider: PermissionStatusProvider { permissionAlias in
                guard permissionAlias == "notifications" else { return nil }
                return ["alias": "notifications", "status": "denied"]
            }
        )

        let reply = await evaluate(
            channel,
            request: request(
                command: "permissions.status",
                capability: "permissions.status",
                correlationID: "perm-2",
                capabilities: [
                    "permissions.status": "1.0.0",
                    "notification_token": "1.0.0",
                    "file_picker": "1.0.0"
                ],
                payload: ["alias": "camera"]
            )
        )

        XCTAssertEqual(reply.status, "deny")
        XCTAssertEqual(reply.denial?.denial.reason, "unavailable_capability")
    }

    func testNotificationTokenReturnsProviderExplicitSnapshotWithoutPrompting() async {
        let channel = bridgeChannel(
            notificationTokenProvider: .available(
                provider: "apns",
                token: "deadbeef",
                detail: [
                    "detail.registration_state": "registered",
                    "detail.snapshot_source": "app_delegate"
                ]
            ),
            permissionsStatusProvider: PermissionStatusProvider { permissionAlias in
                guard permissionAlias == "notifications" else { return nil }

                return [
                    "alias": "notifications",
                    "status": "granted",
                    "detail.authorization_status": "authorized"
                ]
            }
        )

        let reply = await evaluate(
            channel,
            request: request(
                command: "notifications.token.get",
                capability: "notification_token",
                correlationID: "token-1",
                capabilities: [
                    "permissions.status": "1.0.0",
                    "notification_token": "1.0.0",
                    "file_picker": "1.0.0"
                ]
            )
        )

        XCTAssertEqual(reply.status, "ok")
        XCTAssertEqual(reply.payload["provider"], "apns")
        XCTAssertEqual(reply.payload["token"], "deadbeef")
        XCTAssertEqual(reply.payload["notification_status"], "granted")
        XCTAssertEqual(reply.payload["detail.authorization_status"], "authorized")
        XCTAssertEqual(reply.payload["detail.registration_state"], "registered")
        XCTAssertEqual(reply.payload["detail.snapshot_source"], "app_delegate")
    }

    func testNotificationTokenDeniesWhenAuthorizationIsMissing() async {
        let channel = bridgeChannel(
            notificationTokenProvider: .available(provider: "apns", token: "deadbeef", detail: [:]),
            permissionsStatusProvider: PermissionStatusProvider { permissionAlias in
                guard permissionAlias == "notifications" else { return nil }

                return [
                    "alias": "notifications",
                    "status": "denied",
                    "detail.authorization_status": "denied"
                ]
            }
        )

        let reply = await evaluate(
            channel,
            request: request(
                command: "notifications.token.get",
                capability: "notification_token",
                correlationID: "token-2",
                capabilities: [
                    "permissions.status": "1.0.0",
                    "notification_token": "1.0.0",
                    "file_picker": "1.0.0"
                ]
            )
        )

        XCTAssertEqual(reply.status, "deny")
        XCTAssertEqual(reply.denial?.denial.reason, "notification_authorization_required")
    }

    func testNotificationTokenDeniesWhenSnapshotIsUnavailable() async {
        let channel = bridgeChannel(
            notificationTokenProvider: .unavailable(
                reason: "notification_token_unavailable",
                detail: [
                    "detail.registration_state": "registering"
                ]
            ),
            permissionsStatusProvider: PermissionStatusProvider { permissionAlias in
                guard permissionAlias == "notifications" else { return nil }

                return [
                    "alias": "notifications",
                    "status": "granted",
                    "detail.authorization_status": "authorized"
                ]
            }
        )

        let reply = await evaluate(
            channel,
            request: request(
                command: "notifications.token.get",
                capability: "notification_token",
                correlationID: "token-3",
                capabilities: [
                    "permissions.status": "1.0.0",
                    "notification_token": "1.0.0",
                    "file_picker": "1.0.0"
                ]
            )
        )

        XCTAssertEqual(reply.status, "deny")
        XCTAssertEqual(reply.denial?.denial.reason, "notification_token_unavailable")
    }

    func testFilesPickReturnsTypedTransferBoundItems() async throws {
        let itemJSON = try XCTUnwrap(
            jsonString(
                [
                    [
                        "handle": "picked-1",
                        "name": "report.pdf",
                        "native_type": "com.adobe.pdf"
                    ]
                ]
            )
        )

        let channel = bridgeChannel(
            declaredTransfers: [pickerTransfer(id: "lesson_import")],
            filesPickHandler: { payload, correlationID, completion in
                XCTAssertEqual(payload["transfer_id"], "lesson_import")
                XCTAssertEqual(correlationID, "pick-1")

                completion(
                    .success(
                        [
                            "transfer_id": "lesson_import",
                            "outcome": "picked",
                            "items": itemJSON
                        ]
                    )
                )
            }
        )

        let reply = await evaluate(
            channel,
            request: request(
                command: "files.pick",
                capability: "file_picker",
                correlationID: "pick-1",
                capabilities: [
                    "permissions.status": "1.0.0",
                    "notification_token": "1.0.0",
                    "file_picker": "1.0.0"
                ],
                payload: ["transfer_id": "lesson_import"]
            )
        )

        XCTAssertEqual(reply.status, "ok")
        XCTAssertEqual(reply.payload["transfer_id"], "lesson_import")
        XCTAssertEqual(reply.payload["outcome"], "picked")
        XCTAssertEqual(reply.payload["items"], itemJSON)
        XCTAssertNil(reply.payload["url"])
    }

    func testFilesPickReturnsTypedCanceledOutcome() async {
        let channel = bridgeChannel(
            declaredTransfers: [pickerTransfer(id: "lesson_import")],
            filesPickHandler: { payload, _, completion in
                completion(
                    .success(
                        [
                            "transfer_id": payload["transfer_id"] ?? "",
                            "outcome": "canceled",
                            "detail.reason": "user_canceled",
                            "items": "[]"
                        ]
                    )
                )
            }
        )

        let reply = await evaluate(
            channel,
            request: request(
                command: "files.pick",
                capability: "file_picker",
                correlationID: "pick-2",
                capabilities: [
                    "permissions.status": "1.0.0",
                    "notification_token": "1.0.0",
                    "file_picker": "1.0.0"
                ],
                payload: ["transfer_id": "lesson_import"]
            )
        )

        XCTAssertEqual(reply.status, "ok")
        XCTAssertEqual(reply.payload["transfer_id"], "lesson_import")
        XCTAssertEqual(reply.payload["outcome"], "canceled")
        XCTAssertEqual(reply.payload["detail.reason"], "user_canceled")
        XCTAssertEqual(reply.payload["items"], "[]")
    }

    func testFilesPickDeniesUndeclaredTransferIDs() async {
        let channel = bridgeChannel()

        let reply = await evaluate(
            channel,
            request: request(
                command: "files.pick",
                capability: "file_picker",
                correlationID: "pick-3",
                capabilities: [
                    "permissions.status": "1.0.0",
                    "notification_token": "1.0.0",
                    "file_picker": "1.0.0"
                ],
                payload: ["transfer_id": "lesson_import"]
            )
        )

        XCTAssertEqual(reply.status, "deny")
        XCTAssertEqual(reply.denial?.denial.reason, "undeclared_capability")
    }

    private func bridgeChannel(
        notificationTokenProvider: NotificationTokenProvider.Snapshot = .unavailable(
            reason: "notification_setup_missing",
            detail: ["detail.registration_state": "unconfigured"]
        ),
        permissionsStatusProvider: PermissionStatusProvider = PermissionStatusProvider { _ in nil },
        declaredTransfers: [ShellManifest.TransferSeam] = [],
        filesPickHandler: @escaping BridgeChannel.FilesPickHandler = { _, _, completion in
            completion(
                .deny(
                    reason: "undeclared_capability",
                    message: "This route does not declare the requested picker transfer seam.",
                    hint: "Retry only with the active route's manifest-declared picker transfer_id."
                )
            )
        }
    ) -> BridgeChannel {
        let transferCoordinator = declaredTransfers.isEmpty
            ? nil
            : TransferCoordinator(routeID: "dashboard", declaredTransfers: declaredTransfers)

        let bridgeSnapshotProvider = {
            switch notificationTokenProvider {
            case let .available(provider, token, detail):
                return BridgeChannel.NotificationTokenCommandSnapshot.available(
                    provider: provider,
                    token: token,
                    detail: detail
                )
            case let .unavailable(reason, detail):
                return BridgeChannel.NotificationTokenCommandSnapshot.unavailable(
                    reason: reason,
                    detail: detail
                )
            }
        }

        return BridgeChannel(
            session: LiveViewSession(
                routeID: "dashboard",
                url: URL(string: "https://example.crosswake.invalid/dashboard")!,
                allowedOrigin: URL(string: "https://example.crosswake.invalid")!,
                bridgeProtocolVersion: "1.0.0",
                nativeRuntimeVersion: "1.0.0",
                installedPacks: [:],
                routeRequiredPacks: [],
                capabilities: [
                    "permissions.status": "1.0.0",
                    "notification_token": "1.0.0",
                    "file_picker": "1.0.0"
                ],
                declaredTransfers: declaredTransfers
            ),
            transferCoordinator: transferCoordinator,
            replySink: { _ in },
            appInfoProvider: { [:] },
            hapticsHandler: { _ in },
            permissionStatusProvider: permissionsStatusProvider.statusPayload(for:),
            notificationTokenProvider: bridgeSnapshotProvider,
            shareHandler: { _ in },
            filesPickHandler: filesPickHandler
        )
    }

    private func request(
        command: String,
        capability: String,
        correlationID: String,
        capabilities: [String: String],
        payload: [String: String] = [:]
    ) -> BridgeRequestEnvelope {
        BridgeRequestEnvelope(
            protocolName: BridgeChannel.protocolName,
            version: "1.0.0",
            command: command,
            capability: capability,
            routeID: "dashboard",
            activeRouteID: "dashboard",
            origin: "https://example.crosswake.invalid",
            nativeRuntimeVersion: "1.0.0",
            correlationID: correlationID,
            capabilities: capabilities,
            installedPacks: [:],
            payload: payload
        )
    }

    private func pickerTransfer(id: String) -> ShellManifest.TransferSeam {
        ShellManifest.TransferSeam(
            id: id,
            intent: "import",
            direction: "inbound",
            source: "native_picker",
            destination: nil,
            verification: "required",
            mediaTypes: ["application/pdf"],
            states: ["queued", "preparing", "canceled"]
        )
    }

    private func evaluate(
        _ channel: BridgeChannel,
        request: BridgeRequestEnvelope
    ) async -> BridgeReplyEnvelope {
        await withCheckedContinuation { continuation in
            channel.evaluate(request) { reply in
                continuation.resume(returning: reply)
            }
        }
    }

    private func jsonString(_ value: Any) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }
}
