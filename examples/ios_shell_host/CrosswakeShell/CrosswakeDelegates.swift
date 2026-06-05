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

public protocol ShareDelegate: AnyObject {
    func invoke(payload: [String: String])
}

public protocol FilesPickDelegate: AnyObject {
    func pickFiles(payload: [String: String], correlationID: String, completion: @escaping (BridgeChannel.CommandResult) -> Void)
}
