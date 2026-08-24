import Foundation

/// Opaque evidence captured from a notification interaction. It deliberately
/// contains no target, URL, payload, credential, scope identity, or authority
/// decision; the host must re-resolve all of those on reconnect.
public struct NotificationOpenEvidence: Codable, Equatable, Sendable {
    public let openRef: String
    public let bindingRef: String
    public let actionRef: String
    public let correlationID: String

    public init(openRef: String, bindingRef: String, actionRef: String, correlationID: String) {
        self.openRef = openRef
        self.bindingRef = bindingRef
        self.actionRef = actionRef
        self.correlationID = correlationID
    }

    enum CodingKeys: String, CodingKey {
        case openRef = "open_ref"
        case bindingRef = "binding_ref"
        case actionRef = "action_ref"
        case correlationID = "correlation_id"
    }
}

/// A host-produced request that has already passed current protected-open
/// authority. This value is transient and is never written by the queue.
public struct NotificationOpenAllowedActivation: Equatable {
    public let request: ActivationRequest

    public init(request: ActivationRequest) {
        self.request = request
    }
}

public enum NotificationOpenDenial: String, Equatable, Sendable {
    case denied
    case replayed
    case expired
    case revoked
    case wrongBinding = "wrong_binding"
    case logoutOrSessionChanged = "logout_or_session_changed"
    case tenantSwitched = "tenant_switched"
    case removedRoute = "removed_route"
    case removedAction = "removed_action"
    case malformedPolicy = "malformed_policy"
    case routeGateDenied = "route_gate_denied"
    case routeActionRemoved = "route_action_removed"
}

/// Closed outcomes prevent a queue item from being mistaken for authority.
/// Only an explicit host allow can carry a transient activation request.
public enum NotificationOpenConsumptionOutcome: Equatable {
    case allowed(NotificationOpenAllowedActivation)
    case denied(NotificationOpenDenial)
    case retryableTransportFailure
}

/// Host-owned reconnect authority. The host consumes the opaque evidence once,
/// applies current binding/session/route policy, and returns a closed outcome.
public protocol NotificationOpenDelegate: AnyObject {
    func consume(_ evidence: NotificationOpenEvidence) async -> NotificationOpenConsumptionOutcome
}
