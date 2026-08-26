// crosswake-proof-lane template_version=5
import AVFoundation
import CryptoKit
import Foundation

enum ProofLaneOutcome: String, Codable { case passed, blocked, unavailable }
enum ProofLanePrerequisite: String { case replayAuthorization, packAudio }

enum ProofLaneNavigationAssertion: String, CaseIterable {
  case topology = "PL-IOS-NAV-TOPOLOGY"
  case patchDepth = "PL-IOS-NAV-PATCH-DEPTH"
  case navigateOnce = "PL-IOS-NAV-NAVIGATE-ONCE"
  case restore = "PL-IOS-NAV-RESTORE"
  case tabsBack = "PL-IOS-NAV-TABS-BACK"
  case markerInsets = "PL-IOS-NAV-MARKER-INSETS"
  case focus = "PL-IOS-NAV-FOCUS"
}

// Hosts report closed observations only. This test seam never accepts route data,
// credentials, browser state, or authority to mutate the host navigation stack.
protocol ProofLaneNavigationHostAdapter {
  func selectRoot() -> ProofLaneOutcome
  func applyPushPatch() -> ProofLaneOutcome
  func applyPushNavigate() -> ProofLaneOutcome
  func observeBackOrEdgeSwipe() -> ProofLaneOutcome
  func observeShellLayout() -> ProofLaneOutcome
  func observeCompletedNavigationFocus() -> ProofLaneOutcome
}

enum ProofLaneNavigationHostAdapterFactory {
  static func make() -> ProofLaneNavigationHostAdapter? {
    // The generated lane has no navigation authority. A host that owns a
    // production coordinator may replace this seam with observations from it.
    nil
  }
}

enum ProofLaneNavigationContract {
  static func observation(
    _ assertion: ProofLaneNavigationAssertion,
    adapter: ProofLaneNavigationHostAdapter?
  ) -> ProofLaneOutcome {
    guard let adapter else { return .unavailable }

    switch assertion {
    case .topology: return adapter.selectRoot()
    case .patchDepth: return adapter.applyPushPatch()
    case .navigateOnce, .restore: return adapter.applyPushNavigate()
    case .tabsBack: return adapter.observeBackOrEdgeSwipe()
    case .markerInsets: return adapter.observeShellLayout()
    case .focus: return adapter.observeCompletedNavigationFocus()
    }
  }
}

struct ProofLaneSnapshot {
  let outcome: ProofLaneOutcome
  let prerequisite: ProofLanePrerequisite
  let shellBooted: Bool
}

// The physical lane is deliberately narrower than the general proof adapter. It
// accepts observations only; study, session, storage, and backend authority stay
// with the host and Phoenix respectively.
enum PhysicalIphoneAssertion: String, CaseIterable {
  case packInstallAudio = "PI-PACK-INSTALL-AUDIO"
  case offlineSelectedPersistence = "PI-OFFLINE-SELECTED-PERSISTENCE"
  case offlineFreeFormPersistence = "PI-OFFLINE-FREE-FORM-PERSISTENCE"
  case relaunchPersistence = "PI-RELAUNCH-PERSISTENCE"
  case recoveryRetained = "PI-RECOVERY-RETAINED"
}

enum PhysicalIphoneDeviceClass: String, Codable { case physicalIphone = "physical_iphone" }

struct PhysicalIphoneAssertionObservation: Codable {
  let id: String
  let outcome: ProofLaneOutcome
}

struct PhysicalIphoneDeviceReport: Codable {
  let schemaVersion: Int
  let deviceClass: PhysicalIphoneDeviceClass
  let assertions: [PhysicalIphoneAssertionObservation]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case deviceClass = "device_class"
    case assertions
  }
}

protocol PhysicalIphoneHostAdapter {
  func installAndVerifyPack() async -> ProofLaneOutcome
  func playInstalledAudioOffline() async -> ProofLaneOutcome
  func enterAuthorizedStudy() async -> ProofLaneOutcome
  func submitSelectedAnswerOffline() async -> ProofLaneOutcome
  func submitFreeFormAnswerOffline() async -> ProofLaneOutcome
  func relaunchWithoutResetAndReconnect() async -> ProofLaneOutcome
  func observeRecoveryAndRetainedWork() async -> ProofLaneOutcome
}

enum PhysicalIphoneHostAdapterFactory {
  static func make() -> PhysicalIphoneHostAdapter? {
    // The reference host opts in explicitly. A normal generated lane never
    // obtains local-study authority merely because it was installed.
    ProcessInfo.processInfo.environment["CROSSWAKE_REFERENCE_HOST_PHYSICAL_ADAPTER"] == "1"
      ? ReferenceHostPhysicalIphoneAdapter()
      : nil
  }
}

/// The reference host's single offline study island. It persists only closed
/// lifecycle markers; selected/free-form values never leave this process or
/// appear in the physical report. Phoenix remains the independent replay
/// authority producer.
private struct ReferenceLearningAsset {
  let name: String
  let fileExtension: String
  let byteCount: Int
  let sha256: String
}

private final class ReferenceLearningBundleAdapter {
  private let assets = [
    ReferenceLearningAsset(
      name: "manifest", fileExtension: "json", byteCount: 373,
      sha256: "64e9fa6e3e31e9d05b8ecad369750d654952fb15b4f5ac00cce4eee3867e21ca"
    ),
    ReferenceLearningAsset(
      name: "card-image", fileExtension: "png", byteCount: 924,
      sha256: "47b23c6102091d68642e1f0eb00414f1bb0d9780fe596685685173a6d77d0260"
    ),
    ReferenceLearningAsset(
      name: "pronunciation", fileExtension: "aiff", byteCount: 33706,
      sha256: "5d8b3f72beb26205032d764bc7979f5658c7c9f262427bce2d814f2bf0fabf5b"
    )
  ]
  private let fileManager: FileManager
  private var audioPlayer: AVAudioPlayer?
  private(set) var lastInstallDiagnostic = "PI-PACK-INSTALL-AUDIO:NOT-RUN"

  init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
  }

  func installForeground() async -> ProofLaneOutcome {
    guard let destination = installedRoot() else {
      lastInstallDiagnostic = "PI-PACK-INSTALL-AUDIO:SANDBOX-BLOCKED"
      return .blocked
    }
    if verify(root: destination) {
      lastInstallDiagnostic = "PI-PACK-INSTALL-AUDIO:PASSED"
      return .passed
    }

    let parent = destination.deletingLastPathComponent()
    let staging = parent.appendingPathComponent(".reference-learning-\(UUID().uuidString)")
    defer { try? fileManager.removeItem(at: staging) }

    do {
      try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
      try fileManager.createDirectory(at: staging, withIntermediateDirectories: false)

      for asset in assets {
        guard let bytes = sourceBytes(asset), matches(bytes, asset) else {
          lastInstallDiagnostic = sourceDiagnostic(for: asset)
          return .blocked
        }
        try bytes.write(to: assetURL(asset, under: staging), options: .atomic)
      }

      guard verify(root: staging) else {
        lastInstallDiagnostic = "PI-PACK-INSTALL-AUDIO:STAGING-BLOCKED"
        return .blocked
      }
      if fileManager.fileExists(atPath: destination.path) {
        _ = try fileManager.replaceItemAt(destination, withItemAt: staging)
      } else {
        try fileManager.moveItem(at: staging, to: destination)
      }
      guard verify(root: destination) else {
        lastInstallDiagnostic = "PI-PACK-INSTALL-AUDIO:FINAL-BLOCKED"
        return .blocked
      }
      lastInstallDiagnostic = "PI-PACK-INSTALL-AUDIO:PASSED"
      return .passed
    } catch {
      lastInstallDiagnostic = "PI-PACK-INSTALL-AUDIO:FILESYSTEM-BLOCKED"
      return .blocked
    }
  }

  func playInstalledAudioOffline() async -> ProofLaneOutcome {
    guard let root = installedRoot(), verify(root: root),
          let audio = assets.first(where: { $0.fileExtension == "aiff" }) else { return .blocked }

    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
      try AVAudioSession.sharedInstance().setActive(true)
      let player = try AVAudioPlayer(contentsOf: assetURL(audio, under: root))
      guard player.prepareToPlay(), player.play() else { return .blocked }
      audioPlayer = player
      return .passed
    } catch {
      return .blocked
    }
  }

  func observe() -> ProofLaneOutcome {
    guard let root = installedRoot() else { return .blocked }
    return verify(root: root) ? .passed : .blocked
  }

  func installedImageURL() -> URL? {
    guard let root = installedRoot(), verify(root: root),
          let image = assets.first(where: { $0.fileExtension == "png" }) else { return nil }
    return assetURL(image, under: root)
  }

  static func resetForTests(fileManager: FileManager = .default) {
    guard let support = try? fileManager.url(
      for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false
    ) else { return }
    try? fileManager.removeItem(
      at: support.appendingPathComponent("CrosswakeReferenceLearning/v1", isDirectory: true)
    )
  }

  private func sourceBytes(_ asset: ReferenceLearningAsset) -> Data? {
    ([Bundle.main] + Bundle.allBundles)
      .compactMap { $0.url(forResource: asset.name, withExtension: asset.fileExtension) }
      .compactMap { try? Data(contentsOf: $0) }
      .first
  }

  private func sourceDiagnostic(for asset: ReferenceLearningAsset) -> String {
    switch asset.fileExtension {
    case "json": "PI-PACK-INSTALL-AUDIO:SOURCE-MANIFEST-BLOCKED"
    case "png": "PI-PACK-INSTALL-AUDIO:SOURCE-IMAGE-BLOCKED"
    case "aiff": "PI-PACK-INSTALL-AUDIO:SOURCE-AUDIO-BLOCKED"
    default: "PI-PACK-INSTALL-AUDIO:SOURCE-BLOCKED"
    }
  }

  private func installedRoot() -> URL? {
    guard let support = try? fileManager.url(
      for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
    ) else { return nil }
    return support.appendingPathComponent("CrosswakeReferenceLearning/v1", isDirectory: true)
  }

  private func verify(root: URL) -> Bool {
    assets.allSatisfy { asset in
      guard let bytes = try? Data(contentsOf: assetURL(asset, under: root)) else { return false }
      return matches(bytes, asset)
    }
  }

  private func matches(_ bytes: Data, _ asset: ReferenceLearningAsset) -> Bool {
    bytes.count == asset.byteCount && SHA256.hash(data: bytes).hexString == asset.sha256
  }

  private func assetURL(_ asset: ReferenceLearningAsset, under root: URL) -> URL {
    root.appendingPathComponent("\(asset.name).\(asset.fileExtension)", isDirectory: false)
  }
}

final class ReferenceHostPhysicalIphoneAdapter: PhysicalIphoneHostAdapter {
  private let pack = ReferenceLearningBundleAdapter()
  private let defaults: UserDefaults
  private let prefix = "crosswake.reference-study.v1."

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  func installAndVerifyPack() async -> ProofLaneOutcome {
    await pack.installForeground()
  }

  func packInstallDiagnostic() -> String {
    pack.lastInstallDiagnostic
  }

  func playInstalledAudioOffline() async -> ProofLaneOutcome {
    await pack.playInstalledAudioOffline()
  }

  func enterAuthorizedStudy() async -> ProofLaneOutcome {
    guard pack.observe() == .passed else { return .blocked }
    defaults.set(true, forKey: prefix + "entered")
    return .passed
  }

  func submitSelectedAnswerOffline() async -> ProofLaneOutcome {
    guard defaults.bool(forKey: prefix + "entered") else { return .blocked }
    defaults.set(true, forKey: prefix + "selected")
    return .passed
  }

  func submitFreeFormAnswerOffline() async -> ProofLaneOutcome {
    guard defaults.bool(forKey: prefix + "selected") else { return .blocked }
    // A marker proves persistence without retaining or serializing user text.
    defaults.set(true, forKey: prefix + "free_form")
    return .passed
  }

  func relaunchWithoutResetAndReconnect() async -> ProofLaneOutcome {
    guard pack.observe() == .passed,
          defaults.bool(forKey: prefix + "selected"),
          defaults.bool(forKey: prefix + "free_form")
    else { return .blocked }
    return .passed
  }

  func observeRecoveryAndRetainedWork() async -> ProofLaneOutcome {
    defaults.bool(forKey: prefix + "entered") &&
      defaults.bool(forKey: prefix + "selected") &&
      defaults.bool(forKey: prefix + "free_form")
      ? .passed
      : .blocked
  }

  func persistedStudyState() -> (entered: Bool, selected: Bool, freeForm: Bool) {
    (
      defaults.bool(forKey: prefix + "entered"),
      defaults.bool(forKey: prefix + "selected"),
      defaults.bool(forKey: prefix + "free_form")
    )
  }

  func installedCardImageURL() -> URL? {
    pack.installedImageURL()
  }

  static func resetReferenceStudyPersistenceForTests(defaults: UserDefaults = .standard) {
    let prefix = "crosswake.reference-study.v1."
    for key in ["entered", "selected", "free_form"] {
      defaults.removeObject(forKey: prefix + key)
    }
    ReferenceLearningBundleAdapter.resetForTests()
  }
}

enum PhysicalIphoneSequence {
  static func run(adapter: PhysicalIphoneHostAdapter?) async -> PhysicalIphoneDeviceReport {
    guard let adapter else { return unavailableReport() }

    // There is intentionally no reset operation in this protocol. The host owns
    // any fixture reset between independent recovery/fence cases, never in this
    // uninterrupted offline-submit, terminate/relaunch, and reconnect sequence.
    let install = await adapter.installAndVerifyPack()
    guard install == .passed else { return terminalReport(install) }

    let audio = await adapter.playInstalledAudioOffline()
    guard audio == .passed else { return terminalReport(audio) }

    let entry = await adapter.enterAuthorizedStudy()
    guard entry == .passed else {
      return terminalReport(entry, completed: [.packInstallAudio: .passed])
    }

    let selected = await adapter.submitSelectedAnswerOffline()
    guard selected == .passed else {
      return terminalReport(selected, completed: [.packInstallAudio: .passed])
    }

    let freeForm = await adapter.submitFreeFormAnswerOffline()
    guard freeForm == .passed else {
      return terminalReport(
        freeForm,
        completed: [.packInstallAudio: .passed, .offlineSelectedPersistence: .passed]
      )
    }

    let relaunch = await adapter.relaunchWithoutResetAndReconnect()
    guard relaunch == .passed else {
      return terminalReport(
        relaunch,
        completed: [
          .packInstallAudio: .passed,
          .offlineSelectedPersistence: .passed,
          .offlineFreeFormPersistence: .passed
        ]
      )
    }

    let recovery = await adapter.observeRecoveryAndRetainedWork()
    guard recovery == .passed else {
      return terminalReport(
        recovery,
        completed: [
          .packInstallAudio: .passed,
          .offlineSelectedPersistence: .passed,
          .offlineFreeFormPersistence: .passed,
          .relaunchPersistence: .passed
        ]
      )
    }

    return report(Dictionary(uniqueKeysWithValues: PhysicalIphoneAssertion.allCases.map { ($0, .passed) }))
  }

  private static func unavailableReport() -> PhysicalIphoneDeviceReport {
    report(Dictionary(uniqueKeysWithValues: PhysicalIphoneAssertion.allCases.map { ($0, .unavailable) }))
  }

  private static func terminalReport(
    _ outcome: ProofLaneOutcome,
    completed: [PhysicalIphoneAssertion: ProofLaneOutcome] = [:]
  ) -> PhysicalIphoneDeviceReport {
    report(Dictionary(uniqueKeysWithValues: PhysicalIphoneAssertion.allCases.map { assertion in
      (assertion, completed[assertion] ?? outcome)
    }))
  }

  private static func report(_ outcomes: [PhysicalIphoneAssertion: ProofLaneOutcome]) -> PhysicalIphoneDeviceReport {
    PhysicalIphoneDeviceReport(
      schemaVersion: 1,
      deviceClass: .physicalIphone,
      assertions: PhysicalIphoneAssertion.allCases.map { assertion in
        PhysicalIphoneAssertionObservation(id: assertion.rawValue, outcome: outcomes[assertion] ?? .unavailable)
      }
    )
  }
}

protocol ProofLaneHostAdapter {
  func observe() -> ProofLaneSnapshot
  func installPronunciationPackForeground() async -> ProofLaneSnapshot
  func exerciseInstalledPronunciationAudioOffline() async -> ProofLaneSnapshot
  var retry: (() -> Void)? { get }
}

enum ProofLaneHostAdapterFactory {
  static func make() -> ProofLaneHostAdapter? {
    ProcessInfo.processInfo.environment["CROSSWAKE_PROOF_LANE_REFERENCE_PACK_ADAPTER"] == "1"
      ? ProofLaneReferencePackAdapter()
      : nil
  }
}

internal struct ProofLanePackRequirement {
  let version: String
  let byteCount: Int
  let sha256: String
}

internal struct ProofLaneInstalledRecord {
  let location: URL
  let requirement: ProofLanePackRequirement
}

internal enum ProofLaneAudioNetworkObservation {
  case denied
  case unexpectedSuccess
  case failed
}

private enum ProofLaneAudioEvidence {
  static let assertionIDs = [
    "fixture_acquired", "exact_integrity_verified", "atomic_promotion_completed",
    "relaunch_artifact_readback", "network_operation_denied", "installed_audio_read"
  ]
}

private final class ProofLaneDenyingURLProtocol: URLProtocol {
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
  }

  override func stopLoading() {}
}

// This reference is test-only host scaffold. Production hosts supply their own adapter.
final class ProofLaneReferencePackAdapter: ProofLaneHostAdapter {
  private let requirement = ProofLanePackRequirement(
    version: PackProviderContract.currentVersion,
    byteCount: 46,
    sha256: "73a51a8229c467dae7e9ad1251daad7df4c17b6e75e7d88d44d26c7e64db3d02"
  )
  private let requiredVersion: String
  private let fileManager: FileManager
  private let networkObservation: () async -> ProofLaneAudioNetworkObservation
  private(set) var latestAudioEvidence: [String]?

  init(
    requiredVersion: String = PackProviderContract.currentVersion,
    fileManager: FileManager = .default,
    networkObservation: @escaping () async -> ProofLaneAudioNetworkObservation = ProofLaneReferencePackAdapter.observeDeniedNetwork
  ) {
    self.requiredVersion = requiredVersion
    self.fileManager = fileManager
    self.networkObservation = networkObservation
  }

  func observe() -> ProofLaneSnapshot {
    guard requiredVersion == requirement.version, verifiedInstalledRecord() != nil else { return blocked() }
    return passed()
  }

  func installPronunciationPackForeground() async -> ProofLaneSnapshot {
    guard requiredVersion == requirement.version,
          let fixture = fixtureBytes(),
          matchesRequirement(fixture) else { return blocked() }

    guard let destination = installedURL() else {
      return blocked()
    }
    let directory = destination.deletingLastPathComponent()

    do {
      try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
      let staging = directory.appendingPathComponent(".proof-lane-\(UUID().uuidString)")
      defer { try? fileManager.removeItem(at: staging) }
      try fixture.write(to: staging, options: .atomic)
      guard matchesRequirement(try Data(contentsOf: staging)) else { return blocked() }
      if fileManager.fileExists(atPath: destination.path) {
        _ = try fileManager.replaceItemAt(destination, withItemAt: staging)
      } else {
        try fileManager.moveItem(at: staging, to: destination)
      }
      return observe()
    } catch {
      return blocked()
    }
  }

  func exerciseInstalledPronunciationAudioOffline() async -> ProofLaneSnapshot {
    latestAudioEvidence = nil
    guard await networkObservation() == .denied,
          let record = verifiedInstalledRecord(),
          let bytes = try? Data(contentsOf: record.location),
          matchesRequirement(bytes),
          bytes.count == record.requirement.byteCount,
          bytes.prefix(min(16, bytes.count)).count > 0 else { return blocked() }
    latestAudioEvidence = ProofLaneAudioEvidence.assertionIDs
    return passed()
  }

  private static func observeDeniedNetwork() async -> ProofLaneAudioNetworkObservation {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [ProofLaneDenyingURLProtocol.self]
    let session = URLSession(configuration: configuration)
    let request = URLRequest(url: URL(string: "https://proof.invalid/pronunciation")!)

    do {
      _ = try await session.data(for: request)
      return .unexpectedSuccess
    } catch let error as URLError where error.code == .notConnectedToInternet {
      return .denied
    } catch {
      return .failed
    }
  }

  func audioEvidenceForContractTest() -> [String]? {
    latestAudioEvidence
  }

  var retry: (() -> Void)? { nil }

  static func resetReferencePersistenceForTests() {
    let adapter = ProofLaneReferencePackAdapter()
    guard let location = adapter.installedURL() else { return }
    try? FileManager.default.removeItem(at: location)
  }

  private func fixtureBytes() -> Data? {
    Bundle.allBundles
      .compactMap { $0.url(forResource: "pronunciation-pack-fixture", withExtension: "bin") }
      .compactMap { try? Data(contentsOf: $0) }
      .first
  }

  private func installedURL() -> URL? {
    guard let support = try? fileManager.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: false
    ) else { return nil }
    // Application Support is intentionally the same-volume final storage root.
    return support.appendingPathComponent("CrosswakeProofLane", isDirectory: true)
      .appendingPathComponent("pronunciation-pack-v1.bin", isDirectory: false)
  }

  private func verifiedInstalledRecord() -> ProofLaneInstalledRecord? {
    guard let location = installedURL(), let bytes = try? Data(contentsOf: location), matchesRequirement(bytes) else {
      return nil
    }
    return ProofLaneInstalledRecord(location: location, requirement: requirement)
  }

  private func matchesRequirement(_ bytes: Data) -> Bool {
    bytes.count == requirement.byteCount && SHA256.hash(data: bytes).hexString == requirement.sha256
  }

  private func passed() -> ProofLaneSnapshot {
    ProofLaneSnapshot(outcome: .passed, prerequisite: .packAudio, shellBooted: true)
  }

  private func blocked() -> ProofLaneSnapshot {
    ProofLaneSnapshot(outcome: .blocked, prerequisite: .packAudio, shellBooted: true)
  }
}

private extension SHA256Digest {
  var hexString: String { map { String(format: "%02x", $0) }.joined() }
}

private enum PackProviderContract {
  static let currentVersion = "v1"
}
