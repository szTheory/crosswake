import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class NotificationTokenProvider: ObservableObject {
    enum Snapshot: Equatable {
        case available(provider: String, token: String, detail: [String: String])
        case unavailable(reason: String, detail: [String: String])
    }

    private(set) var registrationState = "unconfigured"
    private var tokenHex: String?
    private var lastErrorDescription: String?

    func markConfigured() {
        if registrationState == "unconfigured" {
            registrationState = "idle"
        }
    }

    func refreshRegistration(using application: UIApplication) {
        markConfigured()
        registrationState = "registering"
        application.registerForRemoteNotifications()
    }

    func updateDeviceToken(_ tokenData: Data) {
        tokenHex = tokenData.map { String(format: "%02x", $0) }.joined()
        lastErrorDescription = nil
        registrationState = "registered"
    }

    func markRegistrationFailure(_ error: Error) {
        tokenHex = nil
        lastErrorDescription = error.localizedDescription
        registrationState = "failed"
    }

    func snapshot() -> Snapshot {
        if let tokenHex, tokenHex.isEmpty == false {
            return .available(
                provider: "apns",
                token: tokenHex,
                detail: [
                    "detail.registration_state": registrationState,
                    "detail.snapshot_source": "app_delegate"
                ]
            )
        }

        var detail = ["detail.registration_state": registrationState]
        if let lastErrorDescription {
            detail["detail.error"] = lastErrorDescription
        }

        let reason = registrationState == "unconfigured"
            ? "notification_setup_missing"
            : "notification_token_unavailable"

        return .unavailable(reason: reason, detail: detail)
    }
}

final class NotificationAppDelegate: NSObject, UIApplicationDelegate {
    let notificationTokenProvider: NotificationTokenProvider

    override init() {
        self.notificationTokenProvider = NotificationTokenProvider()
        super.init()
        notificationTokenProvider.markConfigured()
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        notificationTokenProvider.markConfigured()
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        notificationTokenProvider.refreshRegistration(using: application)
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        notificationTokenProvider.updateDeviceToken(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        notificationTokenProvider.markRegistrationFailure(error)
    }
}

@main
struct CrosswakeShellApp: App {
    @UIApplicationDelegateAdaptor(NotificationAppDelegate.self) private var appDelegate
    @StateObject private var activationCoordinator = ActivationCoordinator.bundled()

    var body: some Scene {
        WindowGroup {
            RootSceneView(
                coordinator: activationCoordinator,
                notificationTokenProvider: appDelegate.notificationTokenProvider
            )
                .task {
                    activationCoordinator.bootstrapIfNeeded()
                }
                .onOpenURL { url in
                    activationCoordinator.openURL(url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    activationCoordinator.continueUserActivity(userActivity)
                }
        }
    }
}

private struct RootSceneView: View {
    @ObservedObject var coordinator: ActivationCoordinator
    @ObservedObject var notificationTokenProvider: NotificationTokenProvider

    var body: some View {
        switch coordinator.presentation {
        case .booting:
            ProgressView("Resolving route from bundled manifest truth…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .requiredPack(requiredPack):
            RequiredPackView(
                routeID: requiredPack.routeID,
                runtimeLabel: requiredPack.runtimeLabel,
                status: requiredPack.status,
                onInstall: {
                    Task {
                        await coordinator.installRequiredPack(requiredPack)
                    }
                },
                onRetry: {
                    Task {
                        await coordinator.retryRequiredPack(requiredPack)
                    }
                },
                onInvalidate: {
                    Task {
                        await coordinator.invalidateRequiredPack(requiredPack)
                    }
                }
            )
        case let .nativeCapture(nativeCapture):
            NativeCaptureView(
                routeID: nativeCapture.routeID,
                routeTitle: nativeCapture.routeTitle,
                runtimeLabel: nativeCapture.runtimeLabel,
                transferID: nativeCapture.transferID,
                transferCoordinator: coordinator.transferCoordinator
            )
        case let .liveView(session):
            LiveViewContainerView(
                session: session,
                transferCoordinator: coordinator.transferCoordinator,
                notificationTokenProvider: notificationTokenProvider
            ) { denial in
                coordinator.presentNavigationDenial(denial)
            }
        case let .denied(denial):
            RouteUnavailableView(denial: denial) { action in
                coordinator.perform(action)
            }
        }
    }
}
