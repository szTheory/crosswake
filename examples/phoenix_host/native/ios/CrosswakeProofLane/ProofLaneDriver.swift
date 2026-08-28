// crosswake-proof-lane template_version=5
import AVFoundation
import CrosswakeShellCore
import CryptoKit
import Foundation
/// The physical host owns this short-lived configuration seam.  It accepts only
/// a current invocation's closed topology and never constructs navigation state.
struct ReferenceHostNavigationConfiguration {
  let topology: NavigationTopology

  static func decode(envelope: String?, currentNonce: String?, manifestSchemaVersion: String) -> ReferenceHostNavigationConfiguration? {
    guard let envelope, let currentNonce, !currentNonce.isEmpty,
          let data = envelope.data(using: .utf8),
          let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          Set(object.keys) == ["schema_version", "run_binding", "topology"],
          object["schema_version"] as? Int == 1,
          object["run_binding"] as? String == currentNonce,
          let topologyObject = object["topology"] as? [String: Any],
          Set(topologyObject.keys) == ["topology_schema_version", "manifest_schema_version", "status", "entries"],
          let topologyData = try? JSONSerialization.data(withJSONObject: object["topology"] as Any),
          let topology = try? JSONDecoder().decode(NavigationTopology.self, from: topologyData),
          topology.status == .ready,
          !topology.entries.isEmpty,
          topology.topologySchemaVersion == manifestSchemaVersion,
          topology.manifestSchemaVersion == manifestSchemaVersion
    else { return nil }

    return ReferenceHostNavigationConfiguration(topology: topology)
  }
}

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
  case rejection = "PI-RECOVERY-REJECTION"
  case conflict = "PI-RECOVERY-CONFLICT"
  case logout = "PI-LOGOUT-FENCE"
  case accountSwitch = "PI-ACCOUNT-SWITCH-FENCE"
  case entryDisablement = "PI-ENTRY-DISABLEMENT"
  case replayDisablement = "PI-REPLAY-DISABLEMENT"
}

enum PhysicalIphoneCase: String, CaseIterable {
  case rejection
  case conflict
  case logout
  case accountSwitch = "account_switch"
  case entryDisablement = "entry_disablement"
  case replayDisablement = "replay_disablement"

  var assertion: PhysicalIphoneAssertion {
    switch self {
    case .rejection: .rejection
    case .conflict: .conflict
    case .logout: .logout
    case .accountSwitch: .accountSwitch
    case .entryDisablement: .entryDisablement
    case .replayDisablement: .replayDisablement
    }
  }
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
  func submitFreeFormAnswerOffline(_ value: String) async -> ProofLaneOutcome
  func relaunchWithoutResetAndReconnect() async -> ProofLaneOutcome
  func observeRecoveryAndRetainedWork() async -> ProofLaneOutcome
  func resetCase() async -> ProofLaneOutcome
  func prepareCase(_ caseRef: PhysicalIphoneCase) async -> ProofLaneOutcome
  func performCase(_ caseRef: PhysicalIphoneCase) async -> ProofLaneOutcome
  func verifyCase(_ caseRef: PhysicalIphoneCase) async -> ProofLaneOutcome
}

// This is intentionally host-private: the reference lane has one scoped study
// journal, not a reusable native-storage or sync product.
protocol ReferenceStudyScopeProviding {
  func currentScopeRef() -> String?
  func didLogout()
  func didSwitchAccount(to scopeRef: String?)
}

final class ReferenceHostPhysicalIphoneScopeProvider: ReferenceStudyScopeProviding {
  private var activeScopeRef: String?

  init(environment: [String: String] = ProcessInfo.processInfo.environment) {
    let configured = environment["CROSSWAKE_REFERENCE_HOST_SCOPE_REF"]
    activeScopeRef = configured?.isEmpty == false ? configured : nil
  }

  func currentScopeRef() -> String? { activeScopeRef }
  func didLogout() { activeScopeRef = nil }
  func didSwitchAccount(to scopeRef: String?) { activeScopeRef = scopeRef?.isEmpty == false ? scopeRef : nil }
}

fileprivate struct ReferenceStudyJournalRecord: Codable {
  let version: Int
  let scopeRef: String
  let mutationID: String
  let cardID: Int
  let value: String
}

final class ReferenceStudyJournal {
  private let fileManager: FileManager
  private let root: URL

  init(fileManager: FileManager = .default, root: URL? = nil) {
    self.fileManager = fileManager
    self.root = root ?? ((try? fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask,
      appropriateFor: nil, create: true))?.appendingPathComponent("CrosswakeReferenceStudy/v1", isDirectory: true)
      ?? URL(fileURLWithPath: "/dev/null"))
  }

  func append(value: String, scopeRef: String?, mutationID: String? = nil) -> ProofLaneOutcome {
    guard !value.isEmpty, let scopeRef, !scopeRef.isEmpty else { return .blocked }
    let record = ReferenceStudyJournalRecord(version: 1, scopeRef: scopeRef, mutationID: mutationID ?? UUID().uuidString,
                                             cardID: 1, value: value)
    do {
      try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
      try JSONEncoder().encode(record).write(to: fileURL(for: scopeRef), options: .atomic)
      return .passed
    } catch { return .blocked }
  }

  func recover(scopeRef: String?) -> ProofLaneOutcome {
    guard let record = read(scopeRef: scopeRef), record.version == 1,
          record.scopeRef == scopeRef, !record.value.isEmpty else { return .blocked }
    return .passed
  }

  func hasRecord(scopeRef: String?) -> Bool { read(scopeRef: scopeRef) != nil }

  fileprivate func record(scopeRef: String?) -> ReferenceStudyJournalRecord? { read(scopeRef: scopeRef) }

  fileprivate func remove(_ record: ReferenceStudyJournalRecord, scopeRef: String?) -> ProofLaneOutcome {
    guard let current = read(scopeRef: scopeRef), current.scopeRef == record.scopeRef,
          current.mutationID == record.mutationID else { return .blocked }
    do {
      try fileManager.removeItem(at: fileURL(for: record.scopeRef))
      return .passed
    } catch { return .blocked }
  }

  func reset() { try? fileManager.removeItem(at: root) }

  private func read(scopeRef: String?) -> ReferenceStudyJournalRecord? {
    guard let scopeRef, !scopeRef.isEmpty,
          let data = try? Data(contentsOf: fileURL(for: scopeRef)),
          let record = try? JSONDecoder().decode(ReferenceStudyJournalRecord.self, from: data),
          record.scopeRef == scopeRef else { return nil }
    return record
  }

  private func fileURL(for scopeRef: String) -> URL {
    let name = SHA256.hash(data: Data(scopeRef.utf8)).hexString
    return root.appendingPathComponent(name + ".json", isDirectory: false)
  }
}

// Deliberately foreground-only and reference-host-private. It carries one
// journal record through the existing session-authorized Phoenix endpoints;
// callers receive only a closed outcome and never response or payload bytes.
private final class ReferenceStudyReplayTransport {
  private let environment: [String: String]
  private let session: URLSession

  init(environment: [String: String] = ProcessInfo.processInfo.environment) {
    self.environment = environment
    let configuration = URLSessionConfiguration.ephemeral
    configuration.httpShouldSetCookies = true
    configuration.httpCookieAcceptPolicy = .always
    self.session = URLSession(configuration: configuration)
  }

  func replay(_ record: ReferenceStudyJournalRecord, scopeRef: String?) async -> ProofLaneOutcome {
    guard let scopeRef, scopeRef == record.scopeRef,
          let base = environment["CROSSWAKE_REFERENCE_HOST_BASE_URL"],
          let baseURL = URL(string: base), baseURL.scheme != nil,
          let action = environment["CROSSWAKE_REFERENCE_HOST_ESTABLISH_ACTION"], action == "establish",
          let nonce = environment["CROSSWAKE_REFERENCE_HOST_PHYSICAL_PROOF_NONCE"], !nonce.isEmpty,
          let expectedMutationID = environment["CROSSWAKE_REFERENCE_HOST_PHYSICAL_MUTATION_ID"], !expectedMutationID.isEmpty,
          record.mutationID == expectedMutationID
    else { return .blocked }

    guard await post(baseURL, path: "/_e2e/replay-session", body: ["action": action, "physical_proof_nonce": nonce, "client_mutation_id": expectedMutationID]) else { return .blocked }
    let event: [String: Any] = [
      "client_mutation_id": record.mutationID,
      "card_id": record.cardID,
      "rating": "good",
      "free_form_answer": record.value,
      "physical_proof_nonce": nonce
    ]
    let body: [String: Any] = ["scope_ref": scopeRef, "events": [event]]
    guard await accepted(baseURL, body: body, expectedMutationID: expectedMutationID), await accepted(baseURL, body: body, expectedMutationID: expectedMutationID),
          await oneRow(baseURL, mutationID: expectedMutationID) else { return .blocked }
    return .passed
  }

  func physicalCase(
    _ operation: String,
    caseRef: PhysicalIphoneCase,
    binding: (nonce: String, mutationID: String)
  ) async -> Bool {
    guard let base = environment["CROSSWAKE_REFERENCE_HOST_BASE_URL"],
          let baseURL = URL(string: base), baseURL.scheme != nil,
          operation == "prepare" || operation == "verify"
    else { return false }

    return await closedOutcome(
      baseURL,
      path: "/_e2e/physical-case/\(operation)",
      body: [
        "nonce": binding.nonce,
        "mutation_id": binding.mutationID,
        "case_ref": caseRef.rawValue
      ],
      expected: operation == "prepare" ? "prepared" : "passed"
    )
  }

  func session(action: String) async -> Bool {
    guard let base = environment["CROSSWAKE_REFERENCE_HOST_BASE_URL"],
          let baseURL = URL(string: base), baseURL.scheme != nil,
          action == "clear" || action == "switch"
    else { return false }
    return await post(baseURL, path: "/_e2e/replay-session", body: ["action": action])
  }

  private func post(_ baseURL: URL, path: String, body: [String: Any]) async -> Bool {
    guard JSONSerialization.isValidJSONObject(body), let data = try? JSONSerialization.data(withJSONObject: body),
          let url = URL(string: path, relativeTo: baseURL) else { return false }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = data
    guard let (_, response) = try? await session.data(for: request),
          let http = response as? HTTPURLResponse else { return false }
    return (200...299).contains(http.statusCode)
  }

  private func accepted(_ baseURL: URL, body: [String: Any], expectedMutationID: String) async -> Bool {
    guard JSONSerialization.isValidJSONObject(body), let data = try? JSONSerialization.data(withJSONObject: body),
          let url = URL(string: "/study/sync", relativeTo: baseURL) else { return false }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = data
    guard let (responseData, response) = try? await session.data(for: request),
          let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
          let object = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
          let dataObject = object["data"] as? [String: Any],
          let accepted = dataObject["accepted_records"] as? [[String: Any]], accepted.count == 1,
          accepted.first?["outcome"] as? String == "accepted",
          accepted.first?["client_mutation_id"] as? String == expectedMutationID else { return false }
    return true
  }

  private func closedOutcome(_ baseURL: URL, path: String, body: [String: Any], expected: String) async -> Bool {
    guard JSONSerialization.isValidJSONObject(body), let data = try? JSONSerialization.data(withJSONObject: body),
          let url = URL(string: path, relativeTo: baseURL) else { return false }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = data
    guard let (responseData, response) = try? await session.data(for: request),
          let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
          let object = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
          object["outcome"] as? String == expected
    else { return false }
    return true
  }

  private func oneRow(_ baseURL: URL, mutationID: String) async -> Bool {
    guard let encoded = mutationID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
          let url = URL(string: "/_e2e/sync-state/\(encoded)", relativeTo: baseURL),
          let (data, response) = try? await session.data(from: url),
          let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
          let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          object["count"] as? Int == 1 else { return false }
    return true
  }
}

enum PhysicalIphoneHostAdapterFactory {
  @MainActor
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

#if false
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

#endif

@MainActor
final class ReferenceHostPhysicalIphoneAdapter: PhysicalIphoneHostAdapter {
  private let packProvider: HostLearningBundleProvider
  private let packStore: PackStore
  private var audioPlayer: AVAudioPlayer?
  private let defaults: UserDefaults
  private let prefix = "crosswake.reference-study.v1."
  private let scopeProvider: ReferenceStudyScopeProviding
  private let journal: ReferenceStudyJournal
  private let expectedMutationID: String?

  init(defaults: UserDefaults = .standard,
       scopeProvider: ReferenceStudyScopeProviding = ReferenceHostPhysicalIphoneScopeProvider(),
       journal: ReferenceStudyJournal = ReferenceStudyJournal(),
       environment: [String: String] = ProcessInfo.processInfo.environment) {
    let provider = HostLearningBundleProvider()
    self.packProvider = provider
    self.packStore = PackStore(requirements: [HostLearningBundleProvider.requirement], provider: provider)
    self.defaults = defaults
    self.scopeProvider = scopeProvider
    self.journal = journal
    self.expectedMutationID = environment["CROSSWAKE_REFERENCE_HOST_PHYSICAL_MUTATION_ID"]
  }

  func installAndVerifyPack() async -> ProofLaneOutcome {
    await packStore.reconcileAll()
    guard let status = packStore.statuses[HostLearningBundleProvider.requirement.packID] else { return .blocked }
    await packStore.installRequiredPack(status)
    return await hasFreshInstalledBundle() ? .passed : .blocked
  }

  func packInstallDiagnostic() -> String {
    hasAvailablePackStatus() ? "PI-PACK-INSTALL-AUDIO:PASSED" : "PI-PACK-INSTALL-AUDIO:BLOCKED"
  }

  func playInstalledAudioOffline() async -> ProofLaneOutcome {
    guard await hasFreshInstalledBundle(),
          let audioURL = await packProvider.installedAssetURL(named: "pronunciation.aiff", requirement: HostLearningBundleProvider.requirement)
    else { return .blocked }

    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
      try AVAudioSession.sharedInstance().setActive(true)
      let player = try AVAudioPlayer(contentsOf: audioURL)
      guard player.prepareToPlay(), player.play() else { return .blocked }
      audioPlayer = player
      return .passed
    } catch {
      return .blocked
    }
  }

  func enterAuthorizedStudy() async -> ProofLaneOutcome {
    guard await hasFreshInstalledBundle() else { return .blocked }
    defaults.set(true, forKey: prefix + "entered")
    return .passed
  }

  func submitSelectedAnswerOffline() async -> ProofLaneOutcome {
    guard defaults.bool(forKey: prefix + "entered") else { return .blocked }
    defaults.set(true, forKey: prefix + "selected")
    return .passed
  }

  func submitFreeFormAnswerOffline(_ value: String) async -> ProofLaneOutcome {
    guard defaults.bool(forKey: prefix + "selected") else { return .blocked }
    return journal.append(value: value, scopeRef: scopeProvider.currentScopeRef(), mutationID: expectedMutationID)
  }

  func relaunchWithoutResetAndReconnect() async -> ProofLaneOutcome {
    guard await hasFreshInstalledBundle(),
          defaults.bool(forKey: prefix + "selected"),
          journal.recover(scopeRef: scopeProvider.currentScopeRef()) == .passed
    else { return .blocked }
    return .passed
  }

  func observeRecoveryAndRetainedWork() async -> ProofLaneOutcome {
    guard defaults.bool(forKey: prefix + "entered"), defaults.bool(forKey: prefix + "selected"),
          let scopeRef = scopeProvider.currentScopeRef(), let record = journal.record(scopeRef: scopeRef),
          journal.recover(scopeRef: scopeRef) == .passed,
          await ReferenceStudyReplayTransport().replay(record, scopeRef: scopeRef) == .passed
    else { return .blocked }
    return journal.remove(record, scopeRef: scopeRef)
  }

  // Case controls stay host-private and closed. The sequence invokes this only
  // after the uninterrupted journey, and before every independent D-10 case.
  // It deliberately does not reset pack truth or expose a case name to a learner.
  func resetCase() async -> ProofLaneOutcome {
    defaults.removeObject(forKey: prefix + "entered")
    defaults.removeObject(forKey: prefix + "selected")
    journal.reset()
    return .passed
  }

  func prepareCase(_ caseRef: PhysicalIphoneCase) async -> ProofLaneOutcome {
    guard let binding = currentRunBinding() else { return .blocked }
    return await ReferenceStudyReplayTransport().physicalCase(
      "prepare", caseRef: caseRef, binding: binding
    ) ? .passed : .blocked
  }

  // The learner action is intentionally ordinary: save work, then let the
  // current server/session posture determine replay. A missing or mismatched
  // host condition remains blocked rather than being synthesized on-device.
  func performCase(_ caseRef: PhysicalIphoneCase) async -> ProofLaneOutcome {
    guard let scopeRef = scopeProvider.currentScopeRef(),
          journal.append(value: "case-work", scopeRef: scopeRef, mutationID: expectedMutationID) == .passed,
          let record = journal.record(scopeRef: scopeRef)
    else { return .blocked }

    switch caseRef {
    case .logout:
      scopeProvider.didLogout() // Fence before the host makes a new request.
      guard await ReferenceStudyReplayTransport().session(action: "clear") else { return .blocked }
      return await ReferenceStudyReplayTransport().replay(record, scopeRef: nil) == .blocked ? .passed : .blocked
    case .accountSwitch:
      scopeProvider.didSwitchAccount(to: nil) // Old partition is ineligible first.
      guard await ReferenceStudyReplayTransport().session(action: "switch") else { return .blocked }
      return await ReferenceStudyReplayTransport().replay(record, scopeRef: nil) == .blocked ? .passed : .blocked
    case .rejection, .conflict, .entryDisablement, .replayDisablement:
      // The prepared Phoenix condition must cause the closed normal-replay
      // result. An accepted response is never re-labelled as recovery proof.
      return await ReferenceStudyReplayTransport().replay(record, scopeRef: scopeRef) == .blocked ? .passed : .blocked
    }
  }

  func verifyCase(_ caseRef: PhysicalIphoneCase) async -> ProofLaneOutcome {
    guard let binding = currentRunBinding() else { return .blocked }
    return await ReferenceStudyReplayTransport().physicalCase(
      "verify", caseRef: caseRef, binding: binding
    ) ? .passed : .blocked
  }

  func persistedStudyState() -> (entered: Bool, selected: Bool, freeForm: Bool) {
    (
      defaults.bool(forKey: prefix + "entered"),
      defaults.bool(forKey: prefix + "selected"),
      journal.recover(scopeRef: scopeProvider.currentScopeRef()) == .passed
    )
  }

  func installedCardImageURL() -> URL? {
    guard hasAvailablePackStatus() else { return nil }
    return nil
  }

  static func resetReferenceStudyPersistenceForTests(defaults: UserDefaults = .standard) {
    let prefix = "crosswake.reference-study.v1."
    for key in ["entered", "selected"] {
      defaults.removeObject(forKey: prefix + key)
    }
    ReferenceStudyJournal().reset()
    HostLearningBundleProvider.resetForTests()
  }

  private func hasFreshInstalledBundle() async -> Bool {
    await packStore.reconcileAll()
    return hasAvailablePackStatus()
  }

  private func hasAvailablePackStatus() -> Bool {
    packStore.statuses[HostLearningBundleProvider.requirement.packID]?.state == .available
  }

  private func currentRunBinding() -> (nonce: String, mutationID: String)? {
    let environment = ProcessInfo.processInfo.environment
    guard let nonce = environment["CROSSWAKE_REFERENCE_HOST_PHYSICAL_PROOF_NONCE"], !nonce.isEmpty,
          let mutationID = expectedMutationID, !mutationID.isEmpty
    else { return nil }
    return (nonce, mutationID)
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

    let freeForm = await adapter.submitFreeFormAnswerOffline("contract-value")
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
      schemaVersion: 2,
      deviceClass: .physicalIphone,
      assertions: PhysicalIphoneAssertion.allCases.map { assertion in
        PhysicalIphoneAssertionObservation(id: assertion.rawValue, outcome: outcomes[assertion] ?? .unavailable)
      }
    )
  }
}

enum PhysicalIphoneCaseSequence {
  static func run(adapter: PhysicalIphoneHostAdapter?) async -> PhysicalIphoneDeviceReport {
    let happy = await PhysicalIphoneSequence.run(adapter: adapter)
    guard let adapter, happy.assertions.allSatisfy({ $0.outcome == .passed }) else { return happy }

    var outcomes = Dictionary(uniqueKeysWithValues: happy.assertions.compactMap { observation in
      PhysicalIphoneAssertion(rawValue: observation.id).map { ($0, observation.outcome) }
    })

    for caseRef in PhysicalIphoneCase.allCases {
      guard await adapter.resetCase() == .passed,
            await adapter.prepareCase(caseRef) == .passed,
            await adapter.performCase(caseRef) == .passed,
            await adapter.verifyCase(caseRef) == .passed
      else {
        outcomes[caseRef.assertion] = .blocked
        return report(outcomes)
      }
      outcomes[caseRef.assertion] = .passed
    }

    return report(outcomes)
  }

  private static func report(_ outcomes: [PhysicalIphoneAssertion: ProofLaneOutcome]) -> PhysicalIphoneDeviceReport {
    PhysicalIphoneDeviceReport(
      schemaVersion: 2,
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
    version: "v1",
    byteCount: 46,
    sha256: "73a51a8229c467dae7e9ad1251daad7df4c17b6e75e7d88d44d26c7e64db3d02"
  )
  private let requiredVersion: String
  private let fileManager: FileManager
  private let networkObservation: () async -> ProofLaneAudioNetworkObservation
  private(set) var latestAudioEvidence: [String]?

  init(
    requiredVersion: String = "v1",
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
