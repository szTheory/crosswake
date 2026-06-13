import Foundation

public struct CrosswakeShellConfig {
    public weak var appInfoDelegate: AppInfoDelegate?
    public weak var hapticsDelegate: HapticsDelegate?
    public weak var permissionStatusDelegate: PermissionStatusDelegate?
    public weak var notificationTokenDelegate: NotificationTokenDelegate?
    public weak var shareDelegate: ShareDelegate?
    public weak var filesPickDelegate: FilesPickDelegate?
    public weak var routeDelegate: RouteDelegate?

    public init(
        appInfoDelegate: AppInfoDelegate? = nil,
        hapticsDelegate: HapticsDelegate? = nil,
        permissionStatusDelegate: PermissionStatusDelegate? = nil,
        notificationTokenDelegate: NotificationTokenDelegate? = nil,
        shareDelegate: ShareDelegate? = nil,
        filesPickDelegate: FilesPickDelegate? = nil,
        routeDelegate: RouteDelegate? = nil
    ) {
        self.appInfoDelegate = appInfoDelegate
        self.hapticsDelegate = hapticsDelegate
        self.permissionStatusDelegate = permissionStatusDelegate
        self.notificationTokenDelegate = notificationTokenDelegate
        self.shareDelegate = shareDelegate
        self.filesPickDelegate = filesPickDelegate
        self.routeDelegate = routeDelegate
    }

    public var registeredCapabilities: [String] {
        var caps: [String] = []
        if appInfoDelegate != nil { caps.append("app.info.get") }
        if hapticsDelegate != nil { caps.append("haptics.impact") }
        if permissionStatusDelegate != nil { caps.append("permissions.status") }
        if notificationTokenDelegate != nil { caps.append("notification_token") }
        if shareDelegate != nil { caps.append("share.invoke") }
        if filesPickDelegate != nil { caps.append("file_picker") }
        if let routeDelegate = routeDelegate {
            caps.append(contentsOf: routeDelegate.registeredRoutes.map { "route.\($0)" })
        }
        return caps
    }
}
