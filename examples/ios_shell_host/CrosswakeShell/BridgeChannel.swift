import Foundation
import WebKit

#if canImport(UIKit)
import UIKit
#endif

enum BridgeCommand: String, CaseIterable {
    case appInfoGet = "app.info.get"
    case hapticsImpact = "haptics.impact"
    case permissionsStatus = "permissions.status"
    case notificationsTokenGet = "notifications.token.get"
    case shareInvoke = "share.invoke"
    case filesPick = "files.pick"
    case transferImport = "transfer.import"
    case transferExport = "transfer.export"
    case transferDownload = "transfer.download"
    case transferUploadPrepare = "transfer.upload.prepare"

    var capability: String {
        switch self {
        case .notificationsTokenGet:
            return "notification_token"
        case .filesPick:
            return "file_picker"
        default:
            return rawValue
        }
    }

    var isTransferCommand: Bool {
        switch self {
        case .transferImport, .transferExport, .transferDownload, .transferUploadPrepare:
            return true
        default:
            return false
        }
    }
}

struct BridgeRequestEnvelope: Codable, Equatable {
    let protocolName: String
    let version: String
    let command: String
    let capability: String
    let routeID: String
    let activeRouteID: String
    let origin: String
    let nativeRuntimeVersion: String
    let correlationID: String
    let capabilities: [String: String]
    let installedPacks: [String: String]
    let payload: [String: String]

    enum CodingKeys: String, CodingKey {
        case protocolName = "protocol"
        case version
        case command
        case capability
        case routeID = "route_id"
        case activeRouteID = "active_route_id"
        case origin
        case nativeRuntimeVersion = "native_runtime_version"
        case correlationID = "correlation_id"
        case capabilities
        case installedPacks = "installed_packs"
        case payload
    }
}

struct BridgeReplyEnvelope: Codable, Equatable {
    let protocolName: String
    let version: String
    let command: String
    let routeID: String
    let correlationID: String
    let status: String
    let payload: [String: String]
    let denial: BridgeDenialEnvelope?

    enum CodingKeys: String, CodingKey {
        case protocolName = "protocol"
        case version
        case command
        case routeID = "route_id"
        case correlationID = "correlation_id"
        case status
        case payload
        case denial
    }
}

struct BridgeDenialEnvelope: Codable, Equatable {
    let command: String
    let routeID: String
    let correlationID: String
    let denial: RouteDenialPayload

    enum CodingKeys: String, CodingKey {
        case command
        case routeID = "route_id"
        case correlationID = "correlation_id"
        case denial
    }
}

struct RouteDenialPayload: Codable, Equatable {
    let reason: String
    let code: String
    let message: String
    let routeID: String?
    let hint: String?

    enum CodingKeys: String, CodingKey {
        case reason
        case code
        case message
        case routeID = "route_id"
        case hint
    }
}

final class BridgeChannel: NSObject, WKScriptMessageHandler {
    enum NotificationTokenCommandSnapshot: Equatable {
        case available(provider: String, token: String, detail: [String: String])
        case unavailable(reason: String, detail: [String: String])
    }

    enum CommandResult: Equatable {
        case success([String: String])
        case deny(reason: String, message: String, hint: String)
    }

    typealias FilesPickHandler = ([String: String], String, @escaping (CommandResult) -> Void) -> Void

    static let handlerName = "crosswakeBridge"
    static let protocolName = "crosswake.bridge"

    private var session: LiveViewSession
    private var transferCoordinator: TransferCoordinator?
    private let replySink: (BridgeReplyEnvelope) -> Void
    private let appInfoProvider: () -> [String: String]
    private let hapticsHandler: (String) -> Void
    private let permissionStatusProvider: (String) -> [String: String]?
    private let notificationTokenProvider: () -> NotificationTokenCommandSnapshot
    private let shareHandler: ([String: String]) -> Void
    private let filesPickHandler: FilesPickHandler

    init(
        session: LiveViewSession,
        transferCoordinator: TransferCoordinator?,
        replySink: @escaping (BridgeReplyEnvelope) -> Void,
        appInfoProvider: @escaping () -> [String: String],
        hapticsHandler: @escaping (String) -> Void,
        permissionStatusProvider: @escaping (String) -> [String: String]?,
        notificationTokenProvider: @escaping () -> NotificationTokenCommandSnapshot,
        shareHandler: @escaping ([String: String]) -> Void,
        filesPickHandler: @escaping FilesPickHandler
    ) {
        self.session = session
        self.transferCoordinator = transferCoordinator
        self.replySink = replySink
        self.appInfoProvider = appInfoProvider
        self.hapticsHandler = hapticsHandler
        self.permissionStatusProvider = permissionStatusProvider
        self.notificationTokenProvider = notificationTokenProvider
        self.shareHandler = shareHandler
        self.filesPickHandler = filesPickHandler
        super.init()
    }

    func update(session: LiveViewSession, transferCoordinator: TransferCoordinator?) {
        self.session = session
        self.transferCoordinator = transferCoordinator
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? String,
              let data = body.data(using: .utf8),
              let request = try? JSONDecoder().decode(BridgeRequestEnvelope.self, from: data) else {
            return
        }

        evaluate(request, completion: replySink)
    }

    func evaluate(_ request: BridgeRequestEnvelope, completion: @escaping (BridgeReplyEnvelope) -> Void) {
        guard request.protocolName == Self.protocolName,
              request.version == session.bridgeProtocolVersion,
              request.nativeRuntimeVersion == session.nativeRuntimeVersion else {
            completion(deny(request, reason: "compatibility_mismatch", message: "Bridge protocol or runtime mismatch.", hint: "Update the shell before retrying this bridge request."))
            return
        }

        guard request.routeID == session.routeID, request.activeRouteID == session.routeID else {
            completion(deny(request, reason: "inactive_route", message: "The bridge request is not scoped to the active route.", hint: "Retry from the current active route only."))
            return
        }

        guard request.origin == session.allowedOrigin.absoluteString else {
            completion(deny(request, reason: "origin_denied", message: "The bridge request origin is not allowlisted for the active route.", hint: "Retry from the declared same-origin route surface."))
            return
        }

        guard let command = BridgeCommand(rawValue: request.command), request.capability == command.capability else {
            completion(
                deny(
                    request,
                    reason: "undeclared_capability",
                    message: "The bridge command is outside the bounded transfer contract.",
                    hint: "Use app.info.get, haptics.impact, permissions.status, notifications.token.get, files.pick, transfer.import, transfer.export, transfer.download, or transfer.upload.prepare only."
                )
            )
            return
        }

        guard session.routeRequiredPacks.allSatisfy({ packRequirement in
            let parts = packRequirement.split(separator: "@", maxSplits: 1).map(String.init)
            let packID = parts[0]
            let requiredVersion = parts.count == 2 ? parts[1] : nil
            let installedVersion = session.installedPacks[packID]
            return requiredVersion == nil ? installedVersion != nil : installedVersion == requiredVersion
        }) else {
            completion(deny(request, reason: "pack_incompatible", message: "The active route is missing a compatible declared pack.", hint: "Install or update the required pack before retrying."))
            return
        }

        switch command {
        case .appInfoGet:
            guard capabilityAvailable(for: command, request: request) else {
                completion(unavailableCapability(request))
                return
            }

            completion(ok(request, payload: appInfoProvider()))

        case .hapticsImpact:
            guard capabilityAvailable(for: command, request: request) else {
                completion(unavailableCapability(request))
                return
            }

            let style = request.payload["style"] ?? "medium"
            hapticsHandler(style)
            completion(ok(request, payload: ["style": style]))

        case .permissionsStatus:
            guard capabilityAvailable(for: command, request: request) else {
                completion(unavailableCapability(request))
                return
            }

            guard let permissionAlias = request.payload["alias"],
                  let payload = permissionStatusProvider(permissionAlias) else {
                completion(deny(request, reason: "unavailable_capability", message: "The requested permission alias is outside the shipped read-only permissions.status scope.", hint: "Use the notifications alias only."))
                return
            }

            completion(ok(request, payload: payload))

        case .notificationsTokenGet:
            guard capabilityAvailable(for: command, request: request) else {
                completion(unavailableCapability(request))
                return
            }

            guard let permissionPayload = permissionStatusProvider("notifications") else {
                completion(deny(request, reason: "notification_status_unavailable", message: "The shell could not resolve notification authorization status without prompting.", hint: "Ship notifications status support before retrying notification_token."))
                return
            }

            let notificationStatus = permissionPayload["status"] ?? "restricted"
            guard notificationStatus == "granted" else {
                completion(deny(request, reason: "notification_authorization_required", message: "notification_token stays prompt-free and requires authorization to be resolved before token snapshot lookup.", hint: "Check permissions.status for notifications before retrying notification_token."))
                return
            }

            switch notificationTokenProvider() {
            case let .available(provider, token, detail):
                var payload = permissionPayload
                payload["provider"] = provider
                payload["token"] = token
                payload["notification_status"] = notificationStatus
                payload["detail.snapshot_source"] = detail["detail.snapshot_source"] ?? "app_delegate"

                for (key, value) in detail {
                    payload[key] = value
                }

                completion(ok(request, payload: payload))

            case let .unavailable(reason, detail):
                completion(
                    deny(
                        request,
                        reason: reason,
                        message: "The shell does not have provider-tagged APNs token evidence available for this route.",
                        hint: detail["detail.registration_state"] == "unconfigured"
                            ? "Wire APNs registration into the shell lifecycle before retrying notification_token."
                            : "Wait for the shell-local APNs snapshot to refresh before retrying notification_token."
                    )
                )
            }

        case .shareInvoke:
            guard capabilityAvailable(for: command, request: request) else {
                completion(unavailableCapability(request))
                return
            }

            shareHandler(request.payload)
            completion(ok(request, payload: [:]))

        case .filesPick:
            guard capabilityAvailable(for: command, request: request) else {
                completion(unavailableCapability(request))
                return
            }

            filesPickHandler(request.payload, request.correlationID) { [weak self] result in
                guard let self else { return }

                switch result {
                case let .success(payload):
                    completion(self.ok(request, payload: payload))
                case let .deny(reason, message, hint):
                    completion(self.deny(request, reason: reason, message: message, hint: hint))
                }
            }

        case .transferImport, .transferExport, .transferDownload, .transferUploadPrepare:
            guard let transferCoordinator,
                  let payload = transferCoordinator.execute(
                    command: command.rawValue,
                    payload: request.payload,
                    correlationID: request.correlationID
                  ) else {
                completion(deny(request, reason: "undeclared_capability", message: "This route does not declare the requested transfer seam.", hint: "Retry only with the active route's manifest-declared transfer command and transfer_id."))
                return
            }

            completion(ok(request, payload: payload))
        }
    }

    private func capabilityAvailable(for command: BridgeCommand, request: BridgeRequestEnvelope) -> Bool {
        guard let requiredCapabilityVersion = session.capabilities[command.capability] else {
            return false
        }

        return request.capabilities[command.capability] == requiredCapabilityVersion
    }

    private func unavailableCapability(_ request: BridgeRequestEnvelope) -> BridgeReplyEnvelope {
        deny(
            request,
            reason: "unavailable_capability",
            message: "The requested capability is not available at the manifest-backed version.",
            hint: "Ship the declared capability version before retrying."
        )
    }

    private func ok(_ request: BridgeRequestEnvelope, payload: [String: String]) -> BridgeReplyEnvelope {
        BridgeReplyEnvelope(
            protocolName: request.protocolName,
            version: request.version,
            command: request.command,
            routeID: request.routeID,
            correlationID: request.correlationID,
            status: "ok",
            payload: payload,
            denial: nil
        )
    }

    private func deny(_ request: BridgeRequestEnvelope, reason: String, message: String, hint: String) -> BridgeReplyEnvelope {
        BridgeReplyEnvelope(
            protocolName: request.protocolName,
            version: request.version,
            command: request.command,
            routeID: request.routeID,
            correlationID: request.correlationID,
            status: "deny",
            payload: [:],
            denial: BridgeDenialEnvelope(
                command: request.command,
                routeID: request.routeID,
                correlationID: request.correlationID,
                denial: RouteDenialPayload(
                    reason: reason,
                    code: reason,
                    message: message,
                    routeID: request.routeID,
                    hint: hint
                )
            )
        )
    }
}
