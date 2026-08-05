import Foundation
import WebKit

#if canImport(UIKit)
import UIKit
#endif

public enum BridgeCommand: String, CaseIterable {
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
    case connectionStateUpdate = "connection.state.update"
    case serverEventPush = "server.event.push"

    public var capability: String {
        switch self {
        case .notificationsTokenGet:
            return "notification_token"
        case .filesPick:
            return "file_picker"
        default:
            return rawValue
        }
    }

    public var isTransferCommand: Bool {
        switch self {
        case .transferImport, .transferExport, .transferDownload, .transferUploadPrepare:
            return true
        default:
            return false
        }
    }
}

public struct BridgeRequestEnvelope: Codable, Equatable {
    public let protocolName: String
    public let version: String
    public let command: String
    public let capability: String
    public let routeID: String
    public let activeRouteID: String
    public let origin: String
    public let nativeRuntimeVersion: String
    public let correlationID: String
    public let capabilities: [String: String]
    public let installedPacks: [String: String]
    public let payload: [String: String]

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

public struct BridgeReplyEnvelope: Codable, Equatable {
    public let protocolName: String
    public let version: String
    public let command: String
    public let routeID: String
    public let correlationID: String
    public let status: String
    public let payload: [String: String]
    public let denial: BridgeDenialEnvelope?

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

public struct BridgeDenialEnvelope: Codable, Equatable {
    public let command: String
    public let routeID: String
    public let correlationID: String
    public let denial: RouteDenialPayload

    enum CodingKeys: String, CodingKey {
        case command
        case routeID = "route_id"
        case correlationID = "correlation_id"
        case denial
    }
}

public struct RouteDenialPayload: Codable, Equatable {
    public let reason: String
    public let code: String
    public let message: String
    public let routeID: String?
    public let hint: String?

    enum CodingKeys: String, CodingKey {
        case reason
        case code
        case message
        case routeID = "route_id"
        case hint
    }
}

public final class BridgeChannel: NSObject, WKScriptMessageHandler {
    public enum NotificationTokenCommandSnapshot: Equatable {
        case available(provider: String, token: String, detail: [String: String])
        case unavailable(reason: String, detail: [String: String])
    }

    public enum CommandResult: Equatable {
        case success([String: String])
        case deny(reason: String, message: String, hint: String)
    }

    public typealias FilesPickHandler = ([String: String], String, @escaping (CommandResult) -> Void) -> Void

    public static let handlerName = "crosswakeBridge"
    public static let protocolName = "crosswake.bridge"

    private var session: LiveViewSession
    private var transferCoordinator: TransferCoordinator?
    private let replySink: (BridgeReplyEnvelope) -> Void
    private let config: CrosswakeShellConfig
    private let connectionStateSink: ((ConnectionState) -> Void)?
    private let eventSink: ((ServerEvent) -> Void)?

    public init(
        session: LiveViewSession,
        transferCoordinator: TransferCoordinator?,
        replySink: @escaping (BridgeReplyEnvelope) -> Void,
        config: CrosswakeShellConfig,
        connectionStateSink: ((ConnectionState) -> Void)? = nil,
        eventSink: ((ServerEvent) -> Void)? = nil
    ) {
        self.session = session
        self.transferCoordinator = transferCoordinator
        self.replySink = replySink
        self.config = config
        self.connectionStateSink = connectionStateSink
        self.eventSink = eventSink
        super.init()
    }

    public func update(session: LiveViewSession, transferCoordinator: TransferCoordinator?) {
        self.session = session
        self.transferCoordinator = transferCoordinator
    }

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? String,
              let data = body.data(using: .utf8),
              let request = try? JSONDecoder().decode(BridgeRequestEnvelope.self, from: data) else {
            return
        }

        evaluate(request, completion: replySink)
    }

    public func evaluate(_ request: BridgeRequestEnvelope, completion: @escaping (BridgeReplyEnvelope) -> Void) {
        guard request.protocolName == Self.protocolName,
              SemVer.compatible(provides: session.bridgeProtocolVersion, demands: request.version),
              SemVer.compatible(provides: session.nativeRuntimeVersion, demands: request.nativeRuntimeVersion) else {
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

        guard let command = BridgeCommand(rawValue: request.command) else {
            evaluateHostCommand(request, completion: completion)
            return
        }

        guard request.capability == command.capability else {
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
            return requiredVersion == nil ? installedVersion != nil : SemVer.compatible(provides: installedVersion ?? "", demands: requiredVersion!)
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

            guard let appInfoDelegate = config.appInfoDelegate else {
                completion(deny(request, reason: "undeclared_capability", message: "App info delegate is not configured.", hint: "Implement AppInfoDelegate."))
                return
            }

            completion(ok(request, payload: appInfoDelegate.getAppInfo()))

        case .hapticsImpact:
            guard capabilityAvailable(for: command, request: request) else {
                completion(unavailableCapability(request))
                return
            }

            guard let hapticsDelegate = config.hapticsDelegate else {
                completion(deny(request, reason: "undeclared_capability", message: "Haptics delegate is not configured.", hint: "Implement HapticsDelegate."))
                return
            }

            let style = request.payload["style"] ?? "medium"
            hapticsDelegate.impact(style: style)
            completion(ok(request, payload: ["style": style]))

        case .permissionsStatus:
            guard capabilityAvailable(for: command, request: request) else {
                completion(unavailableCapability(request))
                return
            }

            guard let permissionStatusDelegate = config.permissionStatusDelegate else {
                completion(deny(request, reason: "undeclared_capability", message: "Permission status delegate is not configured.", hint: "Implement PermissionStatusDelegate."))
                return
            }

            guard let permissionAlias = request.payload["alias"],
                  let payload = permissionStatusDelegate.status(for: permissionAlias) else {
                completion(deny(request, reason: "unavailable_capability", message: "The requested permission alias is outside the shipped read-only permissions.status scope.", hint: "Use the notifications alias only."))
                return
            }

            completion(ok(request, payload: payload))

        case .notificationsTokenGet:
            guard capabilityAvailable(for: command, request: request) else {
                completion(unavailableCapability(request))
                return
            }

            guard let permissionStatusDelegate = config.permissionStatusDelegate else {
                completion(deny(request, reason: "undeclared_capability", message: "Permission status delegate is not configured.", hint: "Implement PermissionStatusDelegate."))
                return
            }

            guard let notificationTokenDelegate = config.notificationTokenDelegate else {
                completion(deny(request, reason: "undeclared_capability", message: "Notification token delegate is not configured.", hint: "Implement NotificationTokenDelegate."))
                return
            }

            guard let permissionPayload = permissionStatusDelegate.status(for: "notifications") else {
                completion(deny(request, reason: "notification_status_unavailable", message: "The shell could not resolve notification authorization status without prompting.", hint: "Ship notifications status support before retrying notification_token."))
                return
            }

            let notificationStatus = permissionPayload["status"] ?? "restricted"
            guard notificationStatus == "granted" else {
                completion(deny(request, reason: "notification_authorization_required", message: "notification_token stays prompt-free and requires authorization to be resolved before token snapshot lookup.", hint: "Check permissions.status for notifications before retrying notification_token."))
                return
            }

            switch notificationTokenDelegate.currentToken() {
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

            guard let shareDelegate = config.shareDelegate else {
                completion(deny(request, reason: "undeclared_capability", message: "Share delegate is not configured.", hint: "Implement ShareDelegate."))
                return
            }

            shareDelegate.invoke(payload: request.payload)
            completion(ok(request, payload: [:]))

        case .filesPick:
            guard capabilityAvailable(for: command, request: request) else {
                completion(unavailableCapability(request))
                return
            }

            guard let filesPickDelegate = config.filesPickDelegate else {
                completion(deny(request, reason: "undeclared_capability", message: "Files pick delegate is not configured.", hint: "Implement FilesPickDelegate."))
                return
            }

            filesPickDelegate.pickFiles(payload: request.payload, correlationID: request.correlationID) { [weak self] result in
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

        case .connectionStateUpdate:
            if let stateString = request.payload["state"] {
                let state: ConnectionState
                switch stateString {
                case "connecting": state = .connecting
                case "connected": state = .connected
                case "disconnected": state = .disconnected
                case "retrying": state = .retrying
                default: state = .disconnected
                }
                connectionStateSink?(state)
            }
            completion(ok(request, payload: [:]))

        case .serverEventPush:
            if let eventName = request.payload["name"] {
                var eventPayload = request.payload
                eventPayload.removeValue(forKey: "name")
                eventSink?(ServerEvent(name: eventName, payload: eventPayload))
            }
            completion(ok(request, payload: [:]))
        }
    }

    private func capabilityAvailable(for command: BridgeCommand, request: BridgeRequestEnvelope) -> Bool {
        guard let requiredCapabilityVersion = session.capabilities[command.capability] else {
            return false
        }

        return SemVer.compatible(provides: request.capabilities[command.capability], demands: requiredCapabilityVersion)
    }

    private func evaluateHostCommand(
        _ request: BridgeRequestEnvelope,
        completion: @escaping (BridgeReplyEnvelope) -> Void
    ) {
        guard request.command.hasPrefix("host."), request.capability == request.command,
              let delegate = config.hostBridgeCommandDelegate,
              delegate.registeredCommands.contains(request.command),
              capabilityAvailable(for: request) else {
            completion(deny(
                request,
                reason: "undeclared_capability",
                message: "The bridge command is outside the host-declared contract.",
                hint: "Declare the command for this host and active route before retrying."
            ))
            return
        }

        delegate.handle(command: request.command, payload: request.payload, correlationID: request.correlationID) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(payload):
                completion(self.ok(request, payload: payload))
            case let .deny(reason, message, hint):
                completion(self.deny(request, reason: reason, message: message, hint: hint))
            }
        }
    }

    private func capabilityAvailable(for request: BridgeRequestEnvelope) -> Bool {
        guard let requiredCapabilityVersion = session.capabilities[request.command] else {
            return false
        }

        return SemVer.compatible(
            provides: request.capabilities[request.command],
            demands: requiredCapabilityVersion
        )
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
