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
            if let probe = RequiredPackAccessibilityProbe.fromLaunchArguments {
                probe
            } else if let probe = NavigationShellSyntheticProbe.fromLaunchArguments {
                probe
            } else {
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
}

/// Exact XCUITest-only composition. The opaque fixture remains a candidate and every
/// root/transition is authorized by the production coordinator before UIKit changes.
private struct NavigationShellSyntheticProbe: View {
    @StateObject private var coordinator = NavigationShellSyntheticTopology.coordinator()
    @State private var marker = "cw-navigation-ready"

    static var fromLaunchArguments: Self? {
        ProcessInfo.processInfo.arguments.contains("-crosswake-navigation-synthetic") ? Self() : nil
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationShellView(navigationCoordinator: coordinator) { _ in
                let view = UIViewController()
                view.view.accessibilityIdentifier = "cw-navigation-leaf"
                return view
            }
            HStack {
                Button("Navigate") {
                    _ = coordinator.apply(NavigationTransition(protocolName: NavigationTransition.protocolName, version: NavigationTransition.supportedVersion, transitionID: "nav-0000000000000001", kind: .pushNavigate, routeID: "route-0000000000000003", restorationRef: nil))
                    marker = "cw-navigation-push-completed"
                }
                Button("Patch") {
                    _ = coordinator.apply(NavigationTransition(protocolName: NavigationTransition.protocolName, version: NavigationTransition.supportedVersion, transitionID: "nav-0000000000000002", kind: .pushPatch, routeID: "route-0000000000000003", restorationRef: nil))
                    marker = "cw-navigation-patch-depth-invariant"
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(marker)
        }
    }
}

@MainActor
enum NavigationShellSyntheticTopology {
    static func coordinator() -> NavigationCoordinator {
        let manifest = try! JSONDecoder().decode(ShellManifest.self, from: Data("""
        {"compatibility":{"native_runtime_version":"1.0.0"},"routes":{"route-0000000000000001":{"id":"route-0000000000000001","path":"/","runtime":"live_view","entry":"root","capabilities":[],"packs":[],"transfers":[],"allowlisted_origins":[]},"route-0000000000000002":{"id":"route-0000000000000002","path":"/two","runtime":"live_view","entry":"root","capabilities":[],"packs":[],"transfers":[],"allowlisted_origins":[]},"route-0000000000000003":{"id":"route-0000000000000003","path":"/detail","runtime":"live_view","entry":"root","capabilities":[],"packs":[],"transfers":[],"allowlisted_origins":[]}}}
        """.utf8))
        let topology = NavigationTopology(topologySchemaVersion: "1.0.0", manifestSchemaVersion: "1.0.0", status: .ready, entries: [
            .init(routeID: "route-0000000000000001", rootTabID: "tab-0000000000000001", presentation: .root, parentRouteID: nil, deepLinkPosture: .allow, restorationPosture: .allow),
            .init(routeID: "route-0000000000000002", rootTabID: "tab-0000000000000002", presentation: .root, parentRouteID: nil, deepLinkPosture: .allow, restorationPosture: .allow),
            .init(routeID: "route-0000000000000003", rootTabID: "tab-0000000000000001", presentation: .push, parentRouteID: "route-0000000000000001", deepLinkPosture: .allow, restorationPosture: .allow)
        ])
        return NavigationCoordinator(topology: topology, manifest: manifest) { _, _ in .authorized(.booting) }
    }
}

/// Debug-only launch seam for the executable accessibility contract. It is inert unless the
/// dedicated UI-test argument is present and never supplies storage, media, or route authority.
private struct RequiredPackAccessibilityProbe: View {
    let states: [(PackState, PackFailureReason?)]

    static var fromLaunchArguments: Self? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-crosswake-required-pack-accessibility"),
              arguments.indices.contains(index + 1) else { return nil }
        switch arguments[index + 1] {
        case "install": return Self(states: [(.notInstalled, nil)])
        case "update": return Self(states: [(.stale, nil)])
        case "retry": return Self(states: [(.failed, .transferInterrupted)])
        case "invalidate": return Self(states: [(.failed, .digestMismatch)])
        case "all": return Self(states: [(.notInstalled, nil), (.stale, nil), (.failed, .transferInterrupted), (.failed, .digestMismatch)])
        default: return nil
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(states.indices, id: \.self) { index in
                    view(state: states[index].0, reason: states[index].1)
                }
            }
        }
    }

    @ViewBuilder
    private func view(state: PackState, reason: PackFailureReason?) -> some View {
        if var status = PackStore(requirements: [
            PackRequirement(packID: "pack", requiredVersion: "1", expectedByteCount: 0, expectedSHA256: "")
        ]).statuses["pack"] {
            RequiredPackView(
                routeID: "route-0123456789abcdef",
                runtimeLabel: "reference runtime",
                status: {
                    status.state = state
                    status.failureReason = reason
                    return status
                }(),
                onInstall: {}, onRetry: {}, onInvalidate: {}
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

        let pronunciationPackProvider = HostPronunciationPackConfiguration.provider()
        let config = CrosswakeShellConfig(
            packProvider: pronunciationPackProvider,
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

/// Reference-host configuration stays private: Core receives only its PackProvider protocol.
private enum HostPronunciationPackConfiguration {
    private static let fixtureName = "pronunciation-pack-fixture"
    private static let fixtureExtension = "bin"

    static func provider() -> any PackProvider {
        let storageRoot = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CrosswakePronunciation", isDirectory: true)
        return PronunciationPackProvider(source: {
            guard let url = Bundle.main.url(forResource: fixtureName, withExtension: fixtureExtension) else {
                throw CocoaError(.fileNoSuchFile)
            }
            return try Data(contentsOf: url)
        }, storageRoot: storageRoot)
    }
}

private struct RootSceneView: View {
    @ObservedObject var shell: CrosswakeShell
    @ObservedObject var notificationTokenProvider: NotificationTokenProvider
    @ObservedObject var uiActionDelegates: UIActionDelegates

    @State private var toastMessage: String? = nil

    var body: some View {
        ZStack(alignment: .top) {
            if shell.navigationCoordinator.hasPromotableTopology {
                NavigationShellView(navigationCoordinator: shell.navigationCoordinator) { presentation in
                    UIHostingController(rootView: presentationView(presentation))
                }
            } else {
                presentationView(shell.presentation)
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

    @ViewBuilder
    private func presentationView(_ presentation: ShellPresentation) -> some View {
        switch presentation {
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
