import SwiftUI
import UIKit
import CrosswakeShellCore
import UserNotifications

@MainActor
final class ChimewayNotificationAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, ObservableObject {
  @Published private(set) var status = "Preparing notification proof"

  private var configuration: (hostURL: URL, sessionAuth: String)? {
    let environment = ProcessInfo.processInfo.environment
    guard environment["CROSSWAKE_CHIMEWAY_PHYSICAL_PROOF"] == "1",
          let host = environment["CROSSWAKE_CHIMEWAY_HOST_URL"],
          let hostURL = URL(string: host),
          let sessionAuth = environment["CROSSWAKE_CHIMEWAY_SESSION_AUTH"],
          sessionAuth.isEmpty == false
    else { return nil }
    return (hostURL, sessionAuth)
  }

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    guard configuration != nil else { return true }

    let center = UNUserNotificationCenter.current()
    center.delegate = self
    center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
      guard let self else { return }
      let outcome = granted ? "passed" : "blocked"
      self.post(path: "permission", body: ["outcome": outcome])
      Task { @MainActor in
        self.status = granted ? "Permission granted; registering with APNs" : "Notification permission unavailable"
        if granted { application.registerForRemoteNotifications() }
      }
    }
    return true
  }

  func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let token = deviceToken.map { String(format: "%02x", $0) }.joined()
    guard token.isEmpty == false else { return }
    status = "Registered; waiting for Chimeway alert"
    post(path: "register", body: ["provider": "apns", "token": token])
  }

  func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    status = "APNs registration unavailable"
    post(path: "registration-failed", body: ["outcome": "blocked"])
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    status = "Alert received; tap the banner"
    post(path: "received", body: openReferenceBody(notification.request.content.userInfo))
    completionHandler([.banner, .list, .sound])
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let body = openReferenceBody(response.notification.request.content.userInfo)
    status = body.isEmpty ? "Notification open unavailable" : "Notification opened; verifying authority"
    post(path: "activate", body: body) { [weak self] accepted in
      Task { @MainActor in
        self?.status = accepted ? "Protected activation accepted once" : "Protected activation rejected"
      }
      completionHandler()
    }
  }

  private func openReferenceBody(_ userInfo: [AnyHashable: Any]) -> [String: String] {
    guard let value = userInfo["chimeway_open_ref"] as? String, value.isEmpty == false else { return [:] }
    return ["open_ref": value]
  }

  private func post(path: String, body: [String: String], completion: ((Bool) -> Void)? = nil) {
    guard let configuration,
          let url = URL(string: path, relativeTo: configuration.hostURL)
    else {
      completion?(false)
      return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.timeoutInterval = 10
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(configuration.sessionAuth)", forHTTPHeaderField: "Authorization")
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    URLSession.shared.dataTask(with: request) { _, response, _ in
      let status = (response as? HTTPURLResponse)?.statusCode
      completion?(status.map { (200..<300).contains($0) } ?? false)
    }.resume()
  }
}

@main
struct CrosswakeProofLaneApp: App {
  @UIApplicationDelegateAdaptor(ChimewayNotificationAppDelegate.self) private var notificationDelegate
  private let adapter: ProofLaneHostAdapter?
  private let navigationAdapter: ProofLaneNavigationHostAdapter?
  private let physicalReferenceHost: Bool

  init() {
    let environment = ProcessInfo.processInfo.environment
    physicalReferenceHost = environment["CROSSWAKE_REFERENCE_HOST_PHYSICAL_ADAPTER"] == "1"
    UIApplication.shared.isIdleTimerDisabled = physicalReferenceHost

    if physicalReferenceHost,
       environment["CROSSWAKE_REFERENCE_HOST_RESET_STUDY"] == "1" {
      ReferenceHostPhysicalIphoneAdapter.resetReferenceStudyPersistenceForTests()
    }

    if environment["CROSSWAKE_PROOF_LANE_REFERENCE_PACK_ADAPTER"] == "1",
       environment["CROSSWAKE_PROOF_LANE_RESET_REFERENCE_PACK"] == "1" {
      ProofLaneReferencePackAdapter.resetReferencePersistenceForTests()
    }

    adapter = ProofLaneHostAdapterFactory.make()
    navigationAdapter = ProofLaneNavigationHostAdapterFactory.make()
  }

  var body: some Scene {
    WindowGroup {
      if ProcessInfo.processInfo.environment["CROSSWAKE_CHIMEWAY_PHYSICAL_PROOF"] == "1" {
        ChimewayNotificationProofView(delegate: notificationDelegate)
      } else if physicalReferenceHost {
        ReferencePhysicalNavigationShell(environment: ProcessInfo.processInfo.environment)
      } else {
        ProofLaneView(adapter: adapter, navigationAdapter: navigationAdapter)
      }
    }
  }
}

private struct ChimewayNotificationProofView: View {
  @ObservedObject var delegate: ChimewayNotificationAppDelegate

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "bell.badge.fill")
        .font(.system(size: 54))
      Text("Chimeway physical proof")
        .font(.title2.bold())
      Text(delegate.status)
        .multilineTextAlignment(.center)
        .accessibilityIdentifier("chimeway-notification-proof-status")
      Text("Keep this app open and tap the notification banner when it appears.")
        .font(.footnote)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding(24)
  }
}

@MainActor
final class ReferenceHostShellAuthority: ObservableObject {
  let coordinator: NavigationCoordinator?

  init(environment: [String: String]) {
    guard let manifestText = environment["CROSSWAKE_REFERENCE_HOST_NAVIGATION_MANIFEST"],
          let manifestData = manifestText.data(using: .utf8),
          let manifest = try? JSONDecoder().decode(ShellManifest.self, from: manifestData),
          let configuration = ReferenceHostNavigationConfiguration.decode(
            envelope: environment["CROSSWAKE_REFERENCE_HOST_NAVIGATION_CONFIGURATION"],
            currentNonce: environment["CROSSWAKE_REFERENCE_HOST_NAVIGATION_NONCE"],
            manifestSchemaVersion: environment["CROSSWAKE_REFERENCE_HOST_NAVIGATION_MANIFEST_SCHEMA_VERSION"] ?? ""
          ),
          configuration.topology.validate(against: manifest) == .valid
    else {
      coordinator = nil
      return
    }

    let authorizedRouteIDs = Set(
      (environment["CROSSWAKE_REFERENCE_HOST_AUTHORIZED_ROUTE_IDS"] ?? "")
        .split(separator: ",")
        .map(String.init)
    )
    guard authorizedRouteIDs.isEmpty == false else {
      coordinator = nil
      return
    }

    coordinator = NavigationCoordinator(
      topology: configuration.topology,
      manifest: manifest,
      resolver: { routeID, _ in
        authorizedRouteIDs.contains(routeID) ? .authorized(.booting) : .denied
      }
    )
  }
}

private struct ReferencePhysicalNavigationShell: View {
  @StateObject private var authority: ReferenceHostShellAuthority

  init(environment: [String: String]) {
    _authority = StateObject(wrappedValue: ReferenceHostShellAuthority(environment: environment))
  }

  var body: some View {
    if let coordinator = authority.coordinator {
      NavigationShellView(navigationCoordinator: coordinator, makeLeafController: makeStudyLeaf)
        .accessibilityIdentifier("cw-physical-navigation-shell")
    } else {
      ContentUnavailableView("Study unavailable", systemImage: "lock.fill")
        .accessibilityIdentifier("cw-physical-study-unavailable")
    }
  }

  private func makeStudyLeaf(_ presentation: ShellPresentation) -> UIViewController {
    let controller = UIHostingController(rootView: ReferencePhysicalStudyView())
    controller.title = "Study"
    controller.tabBarItem = UITabBarItem(title: "Study", image: UIImage(systemName: "book.closed"), selectedImage: nil)
    controller.view.accessibilityIdentifier = "cw-physical-study-leaf"
    return controller
  }
}

private struct ReferencePhysicalStudyView: View {
  private let adapter = ReferenceHostPhysicalIphoneAdapter()
  @State private var packReady = false
  @State private var packDiagnostic = "PI-PACK-INSTALL-AUDIO:NOT-RUN"
  @State private var selectedReady = false
  @State private var freeFormReady = false
  @State private var recoveryReady = false
  @State private var freeFormDraft = ""
  @State private var status = ReferenceStudyStatus.savedLocally

  var body: some View {
    VStack(spacing: 16) {
      Text("Offline study")
        .accessibilityIdentifier("reference-study-ready")

      ReferenceStudyStatusView(status: status)

      Text(packReady ? "Pronunciation ready offline" : "Pronunciation unavailable")
        .accessibilityIdentifier("reference-pack-state")

      Text(packDiagnostic)
        .accessibilityIdentifier("reference-pack-diagnostic")

      if let location = adapter.installedCardImageURL(),
         let image = UIImage(contentsOfFile: location.path) {
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
          .frame(width: 96, height: 96)
          .accessibilityLabel("Installed study card image")
          .accessibilityIdentifier("reference-card-image")
      }

      Button("Install pronunciation pack") {
        Task {
          let installed = await adapter.installAndVerifyPack()
          guard installed == .passed else {
            packDiagnostic = adapter.packInstallDiagnostic()
            return
          }

          let audio = await adapter.playInstalledAudioOffline()
          guard audio == .passed else {
            packDiagnostic = "PI-PACK-INSTALL-AUDIO:AUDIO-BLOCKED"
            return
          }

          let entered = await adapter.enterAuthorizedStudy()
          guard entered == .passed else {
            packDiagnostic = "PI-PACK-INSTALL-AUDIO:ENTRY-BLOCKED"
            return
          }

          packReady = true
          packDiagnostic = "PI-PACK-INSTALL-AUDIO:PASSED"
        }
      }
      .frame(minWidth: 44, minHeight: 44)
      .accessibilityIdentifier("reference-pack-install")

      Button("Save selected answer") {
        Task {
          selectedReady = await adapter.submitSelectedAnswerOffline() == .passed
          if selectedReady { updateStatus(.savedLocally) }
        }
      }
      .disabled(!packReady)
      .frame(minWidth: 44, minHeight: 44)
      .accessibilityIdentifier("reference-selected-submit")

      Text(selectedReady ? "Selected answer saved" : "Selected answer pending")
        .accessibilityIdentifier("reference-selected-state")

      TextField("Free-form answer", text: $freeFormDraft)
        .textFieldStyle(.roundedBorder)
        .accessibilityIdentifier("reference-free-form-input")

      Button("Save free-form answer") {
        guard !freeFormDraft.isEmpty else { return }
        Task {
          freeFormReady = await adapter.submitFreeFormAnswerOffline(freeFormDraft) == .passed
          if freeFormReady {
            freeFormDraft = ""
            updateStatus(.syncPaused)
          } else {
            updateStatus(.needsAttention)
          }
        }
      }
      .disabled(!selectedReady)
      .frame(minWidth: 44, minHeight: 44)
      .accessibilityIdentifier("reference-free-form-submit")

      Text(freeFormReady ? "Free-form answer saved" : "Free-form answer pending")
        .accessibilityIdentifier("reference-free-form-state")

      Text(selectedReady && freeFormReady ? "Relaunch state retained" : "Relaunch state pending")
        .accessibilityIdentifier("reference-relaunch-state")

      Text(recoveryReady ? "Recovery work retained" : "Recovery work pending")
        .accessibilityIdentifier("reference-recovery-state")
    }
    .padding(24)
    .onAppear {
      let state = adapter.persistedStudyState()
      selectedReady = state.selected
      freeFormReady = state.freeForm
      packReady = state.entered
      if packReady {
        packDiagnostic = "PI-PACK-INSTALL-AUDIO:PASSED"
      }
      if selectedReady && freeFormReady {
        Task {
          recoveryReady = await adapter.observeRecoveryAndRetainedWork() == .passed
          if recoveryReady { updateStatus(.syncing) }
        }
      }
    }
  }

  private func updateStatus(_ value: ReferenceStudyStatus) {
    guard status != value else { return }
    status = value
    UIAccessibility.post(notification: .announcement, argument: value.announcement)
  }
}

private enum ReferenceStudyStatus: Equatable {
  case savedLocally
  case syncing
  case needsAttention
  case syncPaused

  var label: String {
    switch self {
    case .savedLocally: "Saved on this iPhone"
    case .syncing: "Syncing saved answers"
    case .needsAttention: "Some saved answers need review"
    case .syncPaused: "Saved answers paused"
    }
  }

  var message: String {
    switch self {
    case .savedLocally: "It will sync when you’re back online."
    case .syncing: ""
    case .needsAttention: "Review saved answers when you’re ready."
    case .syncPaused: "Your saved answers remain on this iPhone."
    }
  }

  var announcement: String { message.isEmpty ? label : "\(label). \(message)" }
}

private struct ReferenceStudyStatusView: View {
  let status: ReferenceStudyStatus

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(status.label).font(.headline)
      if !status.message.isEmpty { Text(status.message).font(.subheadline) }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    .accessibilityElement(children: .combine)
    .accessibilityIdentifier("reference-study-status")
  }
}

private struct ProofLaneView: View {
  let adapter: ProofLaneHostAdapter?
  let navigationAdapter: ProofLaneNavigationHostAdapter?
  @State private var snapshot = ProofLaneSnapshot(
    outcome: .unavailable, prerequisite: .packAudio, shellBooted: false
  )

  var body: some View {
    VStack(spacing: 16) {
      Text("Proof lane")
        .accessibilityIdentifier("proof-lane-ready")
      Text("Backend authority required")
        .accessibilityIdentifier("proof-lane-auth-posture")
      Text(adapter == nil ? "Pronunciation provider unavailable" : "Pronunciation pack status")
        .accessibilityIdentifier("proof-lane-pack-status")
      Text("\(snapshot.outcome.rawValue.capitalized): \(snapshot.prerequisite.rawValue)")
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier("proof-lane-outcome")
      if let adapter {
        Button("Install pronunciation pack") {
          Task { snapshot = await adapter.installPronunciationPackForeground() }
        }
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityIdentifier("proof-lane-pack-install")
        Button("Play installed pronunciation audio") {
          Task { snapshot = await adapter.exerciseInstalledPronunciationAudioOffline() }
        }
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityIdentifier("proof-lane-pack-audio")
      }
      if let retry = adapter?.retry {
        Button("Retry proof check") {
          retry()
          refresh()
        }
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityIdentifier("proof-lane-reconnect")
      }
      NavigationProofView(adapter: navigationAdapter)
    }
    .padding(24)
    .onAppear(perform: refresh)
  }

  private func refresh() {
    guard let adapter else { return }
    snapshot = adapter.observe()
  }
}

private struct NavigationProofView: View {
  let adapter: ProofLaneNavigationHostAdapter?
  @State private var outcome: ProofLaneOutcome = .unavailable

  var body: some View {
    VStack(spacing: 12) {
      Text(adapter == nil ? "Navigation shell marker unavailable" : "Navigation shell marker observed")
        .accessibilityIdentifier("proof-lane-navigation-marker")
      Text(adapter == nil ? "Navigation insets unavailable" : "Navigation insets observed")
        .accessibilityIdentifier("proof-lane-navigation-insets")
      Text(adapter == nil ? "Navigation focus unavailable" : "Navigation focus observed")
        .accessibilityIdentifier("proof-lane-navigation-focus")
      Text("Navigation advisory: \(outcome.rawValue.capitalized)")
        .accessibilityIdentifier("proof-lane-navigation-outcome")
      if let adapter {
        Button("Select proof tab") { outcome = adapter.selectRoot() }
          .frame(minWidth: 44, minHeight: 44)
          .accessibilityIdentifier("proof-lane-navigation-tab")
        Button("Navigate once") { outcome = adapter.applyPushNavigate() }
          .frame(minWidth: 44, minHeight: 44)
          .accessibilityIdentifier("proof-lane-navigation-navigate")
        Button("Observe back") { outcome = adapter.observeBackOrEdgeSwipe() }
          .frame(minWidth: 44, minHeight: 44)
          .accessibilityIdentifier("proof-lane-navigation-back")
      }
    }
  }
}
