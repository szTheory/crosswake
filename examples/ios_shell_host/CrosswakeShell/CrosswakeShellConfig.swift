import Foundation

public struct CrosswakeShellConfig {
    public weak var appInfoDelegate: AppInfoDelegate?
    public weak var hapticsDelegate: HapticsDelegate?
    public weak var permissionStatusDelegate: PermissionStatusDelegate?
    public weak var notificationTokenDelegate: NotificationTokenDelegate?
    public weak var shareDelegate: ShareDelegate?
    public weak var filesPickDelegate: FilesPickDelegate?

    public init(
        appInfoDelegate: AppInfoDelegate? = nil,
        hapticsDelegate: HapticsDelegate? = nil,
        permissionStatusDelegate: PermissionStatusDelegate? = nil,
        notificationTokenDelegate: NotificationTokenDelegate? = nil,
        shareDelegate: ShareDelegate? = nil,
        filesPickDelegate: FilesPickDelegate? = nil
    ) {
        self.appInfoDelegate = appInfoDelegate
        self.hapticsDelegate = hapticsDelegate
        self.permissionStatusDelegate = permissionStatusDelegate
        self.notificationTokenDelegate = notificationTokenDelegate
        self.shareDelegate = shareDelegate
        self.filesPickDelegate = filesPickDelegate
    }
}
