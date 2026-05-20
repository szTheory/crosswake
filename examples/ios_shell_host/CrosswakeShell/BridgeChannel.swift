import Foundation
import WebKit

#if canImport(UIKit)
import UIKit
#endif

enum BridgeCommand: String, CaseIterable {
    case appInfoGet = "app.info.get"
    case hapticsImpact = "haptics.impact"
    case filesPick = "files.pick"
    case transferImport = "transfer.import"
    case transferExport = "transfer.export"
    case transferDownload = "transfer.download"
    case transferUploadPrepare = "transfer.upload.prepare"

    var capability: String { rawValue }

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
    static let handlerName = "crosswakeBridge"
    static let protocolName = "crosswake.bridge"

    private var session: LiveViewSession
    private let replySink: (BridgeReplyEnvelope) -> Void
    private let appInfoProvider: () -> [String: String]
    private let hapticsHandler: (String) -> Void
    private let filesPickHandler: ([String: String]) -> [String: String]
    private let transferCoordinator: TransferCoordinator?

    init(
        session: LiveViewSession,
        transferCoordinator: TransferCoordinator?,
        replySink: @escaping (BridgeReplyEnvelope) -> Void,
        appInfoProvider: @escaping () -> [String: String],
        hapticsHandler: @escaping (String) -> Void,
        filesPickHandler: @escaping ([String: String]) -> [String: String]
    ) {
        self.session = session
        self.transferCoordinator = transferCoordinator
        self.replySink = replySink
        self.appInfoProvider = appInfoProvider
        self.hapticsHandler = hapticsHandler
        self.filesPickHandler = filesPickHandler
        super.init()
    }

    func update(session: LiveViewSession) {
        self.session = session
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? String,
              let data = body.data(using: .utf8),
              let request = try? JSONDecoder().decode(BridgeRequestEnvelope.self, from: data) else {
            return
        }

        guard request.protocolName == Self.protocolName,
              request.version == session.bridgeProtocolVersion,
              request.nativeRuntimeVersion == session.nativeRuntimeVersion else {
            replySink(deny(request, reason: "compatibility_mismatch", message: "Bridge protocol or runtime mismatch.", hint: "Update the shell before retrying this bridge request."))
            return
        }

        guard request.routeID == session.routeID, request.activeRouteID == session.routeID else {
            replySink(deny(request, reason: "inactive_route", message: "The bridge request is not scoped to the active route.", hint: "Retry from the current active route only."))
            return
        }

        guard request.origin == session.allowedOrigin.absoluteString else {
            replySink(deny(request, reason: "origin_denied", message: "The bridge request origin is not allowlisted for the active route.", hint: "Retry from the declared same-origin route surface."))
            return
        }

        guard let command = BridgeCommand(rawValue: request.command), request.capability == command.capability else {
            replySink(deny(request, reason: "undeclared_capability", message: "The bridge command is outside the bounded transfer contract.", hint: "Use app.info.get, haptics.impact, files.pick, transfer.import, transfer.export, transfer.download, or transfer.upload.prepare only."))
            return
        }

        guard session.routeRequiredPacks.allSatisfy({ packRequirement in
            let parts = packRequirement.split(separator: "@", maxSplits: 1).map(String.init)
            let packID = parts[0]
            let requiredVersion = parts.count == 2 ? parts[1] : nil
            let installedVersion = session.installedPacks[packID]
            return requiredVersion == nil ? installedVersion != nil : installedVersion == requiredVersion
        }) else {
            replySink(deny(request, reason: "pack_incompatible", message: "The active route is missing a compatible declared pack.", hint: "Install or update the required pack before retrying."))
            return
        }

        switch command {
        case .appInfoGet:
            guard let requiredCapabilityVersion = session.capabilities[command.capability],
                  request.capabilities[command.capability] == requiredCapabilityVersion else {
                replySink(deny(request, reason: "unavailable_capability", message: "The requested capability is not available at the manifest-backed version.", hint: "Ship the declared capability version before retrying."))
                return
            }

            replySink(ok(request, payload: appInfoProvider()))

        case .hapticsImpact:
            guard let requiredCapabilityVersion = session.capabilities[command.capability],
                  request.capabilities[command.capability] == requiredCapabilityVersion else {
                replySink(deny(request, reason: "unavailable_capability", message: "The requested capability is not available at the manifest-backed version.", hint: "Ship the declared capability version before retrying."))
                return
            }

            let style = request.payload["style"] ?? "medium"
            hapticsHandler(style)
            replySink(ok(request, payload: ["style": style]))

        case .filesPick:
            guard let requiredCapabilityVersion = session.capabilities[command.capability],
                  request.capabilities[command.capability] == requiredCapabilityVersion else {
                replySink(deny(request, reason: "unavailable_capability", message: "The requested capability is not available at the manifest-backed version.", hint: "Ship the declared capability version before retrying."))
                return
            }

            replySink(ok(request, payload: filesPickHandler(request.payload)))

        case .transferImport, .transferExport, .transferDownload, .transferUploadPrepare:
            guard let transferCoordinator,
                  let payload = transferCoordinator.execute(
                    command: command.rawValue,
                    payload: request.payload,
                    correlationID: request.correlationID
                  ) else {
                replySink(deny(request, reason: "undeclared_capability", message: "This route does not declare the requested transfer seam.", hint: "Retry only with the active route's manifest-declared transfer command and transfer_id."))
                return
            }

            replySink(ok(request, payload: payload))
        }
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
