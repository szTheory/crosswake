import Foundation
import UserNotifications

final class PermissionStatusProvider: PermissionStatusDelegate {
    private let resolver: (String) -> [String: String]?

    init(resolver: @escaping (String) -> [String: String]?) {
        self.resolver = resolver
    }

    convenience init(center: UNUserNotificationCenter = .current()) {
        self.init { permissionAlias in
            guard permissionAlias == "notifications" else { return nil }

            let semaphore = DispatchSemaphore(value: 0)
            var payload: [String: String]?

            center.getNotificationSettings { settings in
                let authorizationStatus = settings.authorizationStatus
                let normalizedStatus: String

                switch authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    normalizedStatus = "granted"
                case .denied, .notDetermined:
                    normalizedStatus = "denied"
                @unknown default:
                    normalizedStatus = "restricted"
                }

                payload = [
                    "alias": "notifications",
                    "status": normalizedStatus,
                    "detail.authorization_status": Self.authorizationStatusString(authorizationStatus)
                ]

                semaphore.signal()
            }

            _ = semaphore.wait(timeout: .now() + 1.0)

            return payload ?? [
                "alias": "notifications",
                "status": "restricted",
                "detail.error": "unavailable"
            ]
        }
    }

    func status(for permissionAlias: String) -> [String: String]? {
        resolver(permissionAlias)
    }

    private static func authorizationStatusString(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "not_determined"
        case .denied:
            return "denied"
        case .authorized:
            return "authorized"
        case .provisional:
            return "provisional"
        case .ephemeral:
            return "ephemeral"
        @unknown default:
            return "unknown"
        }
    }
}
