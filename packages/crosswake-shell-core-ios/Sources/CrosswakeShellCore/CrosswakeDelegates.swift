import Foundation

public protocol AppInfoDelegate: AnyObject {
    func getAppInfo() -> [String: String]
}

public protocol HapticsDelegate: AnyObject {
    func impact(style: String)
}

public protocol PermissionStatusDelegate: AnyObject {
    func status(for alias: String) -> [String: String]?
}

public protocol NotificationTokenDelegate: AnyObject {
    func currentToken() -> BridgeChannel.NotificationTokenCommandSnapshot
}

/// Host-owned notification registration authority. APNs token bytes cross this
/// seam only for the duration of `bindObservedNotificationToken`; Crosswake
/// retains only the opaque binding reference returned by the host.
public protocol NotificationRegistrationDelegate: AnyObject {
    func bindObservedNotificationToken(_ token: Data, scope: NotificationRegistrationScope) -> NotificationBindingOutcome
    func revokeNotificationBindingForPermissionLoss(_ command: NotificationPermissionLossCommand) -> NotificationPermissionLossOutcome
}

public protocol ShareDelegate: AnyObject {
    func invoke(payload: [String: String])
}

public protocol FilesPickDelegate: AnyObject {
    func pickFiles(payload: [String: String], correlationID: String, completion: @escaping (BridgeChannel.CommandResult) -> Void)
}

/// Host-owned, manifest-declared bridge behavior. The shell validates the
/// request's protocol, version, route, origin, required packs, and declared
/// capability before it invokes this delegate.
///
/// This is an extension seam, not a Crosswake commerce API: host commands and
/// their payloads remain owned by the adopting application.
public protocol HostBridgeCommandDelegate: AnyObject {
    var registeredCommands: [String] { get }
    func handle(
        command: String,
        payload: [String: String],
        correlationID: String,
        completion: @escaping (BridgeChannel.CommandResult) -> Void
    )
}

public protocol RouteDelegate: AnyObject {
    func isRouteRegistered(routeID: String) -> Bool
    var registeredRoutes: [String] { get }
}
