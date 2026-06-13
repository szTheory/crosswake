import SwiftUI
import CrosswakeShellCore

#if canImport(UIKit)
import UIKit
#endif

final class AppInfoProvider: AppInfoDelegate {
    func getAppInfo() -> [String: String] {
        let info = Bundle.main.infoDictionary
        return [
            "version": info?["CFBundleShortVersionString"] as? String ?? "",
            "build": info?["CFBundleVersion"] as? String ?? "",
            "bundle_id": info?["CFBundleIdentifier"] as? String ?? ""
        ]
    }
}

final class HapticsProvider: HapticsDelegate {
    func impact(style styleString: String) {
        let style: UIImpactFeedbackGenerator.FeedbackStyle
        switch styleString {
        case "light": style = .light
        case "heavy": style = .heavy
        case "medium": fallthrough
        default: style = .medium
        }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

@MainActor
final class UIActionDelegates: ShareDelegate, FilesPickDelegate, ObservableObject {
    weak var presenter: UIViewController?
    weak var filePickerCoordinator: FilePickerCoordinator?

    func invoke(payload: [String: String]) {
        guard let presenter = presenter else { return }
        var items: [Any] = []
        if let text = payload["text"] { items.append(text) }
        if let urlString = payload["url"], let url = URL(string: urlString) { items.append(url) }
        if items.isEmpty { return }

        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let title = payload["title"] {
            activityVC.setValue(title, forKey: "subject")
        }
        if let popover = activityVC.popoverPresentationController, let view = presenter.view {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        presenter.present(activityVC, animated: true)
    }

    func pickFiles(payload: [String: String], correlationID: String, completion: @escaping (BridgeChannel.CommandResult) -> Void) {
        guard let filePickerCoordinator = filePickerCoordinator else {
            completion(.deny(reason: "picker_unavailable", message: "File picker coordinator not ready.", hint: "Retry later."))
            return
        }
        filePickerCoordinator.presentPicker(payload: payload, correlationID: correlationID, completion: completion)
    }
}

@MainActor
final class NotificationTokenProvider: ObservableObject, NotificationTokenDelegate {
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

    func currentToken() -> BridgeChannel.NotificationTokenCommandSnapshot {
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
        DiagnosticExportManager.shared.start()
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

final class NavigationRouteDelegate: RouteDelegate {
    let registeredRoutes = ["selective-native-claim-capture"]

    func isRouteRegistered(routeID: String) -> Bool {
        return registeredRoutes.contains(routeID)
    }
}

@main
struct CrosswakeShellApp: App {
    @UIApplicationDelegateAdaptor(NotificationAppDelegate.self) private var appDelegate
    @StateObject private var uiActionDelegates = UIActionDelegates()

    private let permissionProvider = PermissionStatusProvider()
    private let appInfoProvider = AppInfoProvider()
    private let hapticsProvider = HapticsProvider()
    private let routeDelegate = NavigationRouteDelegate()

    var body: some Scene {
        WindowGroup {
            RootSceneWrapper(
                notificationTokenProvider: appDelegate.notificationTokenProvider,
                uiActionDelegates: uiActionDelegates,
                permissionProvider: permissionProvider,
                appInfoProvider: appInfoProvider,
                hapticsProvider: hapticsProvider,
                routeDelegate: routeDelegate
            )
        }
    }
}

private struct RootSceneWrapper: View {
    @StateObject private var shell: CrosswakeShell
    @ObservedObject var uiActionDelegates: UIActionDelegates
    let notificationTokenProvider: NotificationTokenProvider

    init(
        notificationTokenProvider: NotificationTokenProvider,
        uiActionDelegates: UIActionDelegates,
        permissionProvider: PermissionStatusProvider,
        appInfoProvider: AppInfoProvider,
        hapticsProvider: HapticsProvider,
        routeDelegate: RouteDelegate
    ) {
        self.notificationTokenProvider = notificationTokenProvider
        self.uiActionDelegates = uiActionDelegates

        let config = CrosswakeShellConfig(
            appInfoDelegate: appInfoProvider,
            hapticsDelegate: hapticsProvider,
            permissionStatusDelegate: permissionProvider,
            notificationTokenDelegate: notificationTokenProvider,
            shareDelegate: uiActionDelegates,
            filesPickDelegate: uiActionDelegates,
            routeDelegate: routeDelegate
        )

        _shell = StateObject(wrappedValue: CrosswakeShell(config: config))
    }

    var body: some View {
        RootSceneView(
            shell: shell,
            notificationTokenProvider: notificationTokenProvider,
            uiActionDelegates: uiActionDelegates
        )
    }
}

private struct RootSceneView: View {
    @ObservedObject var shell: CrosswakeShell
    @ObservedObject var notificationTokenProvider: NotificationTokenProvider
    @ObservedObject var uiActionDelegates: UIActionDelegates

    @State private var toastMessage: String? = nil

    var body: some View {
        ZStack(alignment: .top) {
            switch shell.presentation {
            case .booting:
                ProgressView("Resolving route from bundled manifest truth…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .task {
                        shell.bootstrap()
                    }
                    .onOpenURL { url in
                        shell.bootstrap(intent: url)
                    }
                    .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                        if let url = userActivity.webpageURL {
                            shell.bootstrap(intent: url)
                        }
                    }
            case let .requiredPack(requiredPack):
                RequiredPackView(
                    routeID: requiredPack.routeID,
                    runtimeLabel: requiredPack.runtimeLabel,
                    status: requiredPack.status,
                    onInstall: {
                        Task { await shell.coordinator.installRequiredPack(requiredPack) }
                    },
                    onRetry: {
                        Task { await shell.coordinator.retryRequiredPack(requiredPack) }
                    },
                    onInvalidate: {
                        Task { await shell.coordinator.invalidateRequiredPack(requiredPack) }
                    }
                )
            case let .nativeCapture(nativeCapture):
                NativeCaptureView(
                    routeID: nativeCapture.routeID,
                    routeTitle: nativeCapture.routeTitle,
                    runtimeLabel: nativeCapture.runtimeLabel,
                    transferID: nativeCapture.transferID,
                    transferCoordinator: shell.coordinator.transferCoordinator
                )
            case let .liveView(session):
                LiveViewContainerView(
                    session: session,
                    shell: shell,
                    notificationTokenProvider: notificationTokenProvider,
                    uiActionDelegates: uiActionDelegates
                ) { denial in
                    shell.coordinator.presentNavigationDenial(denial)
                }
            case let .denied(denial):
                RouteUnavailableView(denial: denial) { action in
                    shell.coordinator.perform(action)
                }
            }

            VStack {
                if shell.connectionState != .connected && shell.connectionState != .disconnected {
                    Text(shell.connectionState == .connecting ? "Connecting..." : "Retrying...")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.yellow.opacity(0.9))
                        .cornerRadius(8)
                        .padding(.top, 40)
                }

                if let toastMessage {
                    Text(toastMessage)
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                }
            }
            .animation(.easeInOut, value: shell.connectionState)
            .animation(.easeInOut, value: toastMessage)
        }
        .onReceive(shell.serverEvents) { event in
            if event.name == "toast" {
                let message = event.payload["message"] ?? "Notification"
                showToast(message: message)
            }
        }
    }

    private func showToast(message: String) {
        toastMessage = message
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if toastMessage == message {
                toastMessage = nil
            }
        }
    }
}
