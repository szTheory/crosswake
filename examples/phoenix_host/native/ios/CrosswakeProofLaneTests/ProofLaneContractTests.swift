import XCTest
import CryptoKit
@testable import CrosswakeProofLane

final class ProofLaneContractTests: XCTestCase {
  func testNavigationConfigurationAcceptsOnlyTheCurrentNonceBoundReadyTopology() throws {
    let topology = """
    {"topology_schema_version":"1.0.0","manifest_schema_version":"1.0.0","status":"ready","entries":[{"route_id":"route-0123456789abcdef","root_tab_id":"tab-0123456789abcdef","presentation":"root","deep_link_posture":"allow","restoration_posture":"allow"}]}
    """
    let envelope = "{\"schema_version\":1,\"run_binding\":\"current-run\",\"topology\":\(topology)}"

    XCTAssertNotNil(
      ReferenceHostNavigationConfiguration.decode(
        envelope: envelope,
        currentNonce: "current-run",
        manifestSchemaVersion: "1.0.0"
      )
    )

    for invalid in ["", "{}", envelope.replacingOccurrences(of: "current-run", with: "stale-run"), "{\"schema_version\":1,\"run_binding\":\"current-run\",\"topology\":{}}"] {
      XCTAssertNil(
        ReferenceHostNavigationConfiguration.decode(
          envelope: invalid,
          currentNonce: "current-run",
          manifestSchemaVersion: "1.0.0"
        )
      )
    }
  }

  func testNavigationRemainsUnavailableWithoutProductionHostObservations() {
    XCTAssertNil(ProofLaneNavigationHostAdapterFactory.make())
    for assertion in ProofLaneNavigationAssertion.allCases {
      XCTAssertEqual(ProofLaneNavigationContract.observation(assertion, adapter: nil), .unavailable)
    }
  }

  func testMissingAdapterRemainsUnavailable() {
    let adapter = ProofLaneHostAdapterFactory.make()
    if ProcessInfo.processInfo.environment["CROSSWAKE_PROOF_LANE_REFERENCE_PACK_ADAPTER"] == "1" {
      XCTAssertNotNil(adapter)
    } else {
      XCTAssertNil(adapter)
    }
  }

  func testReferencePackDoesNotCreateNavigationEvidence() {
    XCTAssertNil(ProofLaneNavigationHostAdapterFactory.make())
    emitNavigationEvidence(outcome: .unavailable)
  }

  func testPhysicalSequenceRequiresAProductionAdapter() async {
    let report = await PhysicalIphoneSequence.run(adapter: nil)

    XCTAssertEqual(report.schemaVersion, 1)
    XCTAssertEqual(report.deviceClass, .physicalIphone)
    XCTAssertEqual(report.assertions.map(\.id), PhysicalIphoneAssertion.allCases.map(\.rawValue))
    XCTAssertTrue(report.assertions.allSatisfy { $0.outcome == .unavailable })
  }

  func testPhysicalSequenceStopsAtTheFirstNonPassingHostOperation() async {
    let operations = PhysicalIphoneOperation.allCases

    for stoppingOutcome in [ProofLaneOutcome.blocked, .unavailable] {
      for (index, operation) in operations.enumerated() {
        let adapter = RecordingPhysicalIphoneAdapter(failing: operation, outcome: stoppingOutcome)
        let report = await PhysicalIphoneSequence.run(adapter: adapter)

        XCTAssertEqual(adapter.calls, Array(operations.prefix(index + 1)))
        XCTAssertEqual(
          report.assertions.map(\.id),
          PhysicalIphoneAssertion.allCases.map(\.rawValue)
        )

        XCTAssertEqual(
          report.assertions.map(\.outcome),
          expectedOutcomes(stoppingAt: operation, outcome: stoppingOutcome)
        )
      }
    }
  }

  func testPhysicalSequenceCallsEveryOperationOnceWhenAllPass() async {
    let adapter = RecordingPhysicalIphoneAdapter()
    let report = await PhysicalIphoneSequence.run(adapter: adapter)

    XCTAssertEqual(adapter.calls, PhysicalIphoneOperation.allCases)
    XCTAssertTrue(report.assertions.allSatisfy { $0.outcome == .passed })
  }

  func testPhysicalSequenceCarriesOneNonemptyFreeFormValue() async {
    let adapter = RecordingPhysicalIphoneAdapter()
    _ = await adapter.submitFreeFormAnswerOffline("contract-value")
    XCTAssertEqual(adapter.calls, [.freeForm])
    let emptyValueOutcome = await adapter.submitFreeFormAnswerOffline("")
    XCTAssertEqual(emptyValueOutcome, .blocked)
  }

  func testReferenceReplayTransportKeepsOnlyItsInMemorySessionCookie() throws {
    let driverPath = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("CrosswakeProofLane/ProofLaneDriver.swift")
    let source = try String(contentsOf: driverPath, encoding: .utf8)

    XCTAssertTrue(source.contains("let configuration = URLSessionConfiguration.ephemeral"))
    XCTAssertTrue(source.contains("configuration.httpShouldSetCookies = true"))
    XCTAssertTrue(source.contains("configuration.httpCookieAcceptPolicy = .always"))
    XCTAssertFalse(source.contains("configuration.httpCookieStorage = HTTPCookieStorage()"))
  }

  func testReferenceJournalRecoversOnlyInsideItsOriginalScope() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let journal = ReferenceStudyJournal(root: root)

    XCTAssertEqual(journal.append(value: "neutral-answer", scopeRef: "v1.scope_fixture_alpha_01"), .passed)
    XCTAssertEqual(journal.recover(scopeRef: "v1.scope_fixture_alpha_01"), .passed)
    XCTAssertEqual(journal.recover(scopeRef: "v1.scope_fixture_bravo_01"), .blocked)
    XCTAssertEqual(journal.recover(scopeRef: nil), .blocked)
  }

  func testScopeTransitionsFenceRetainedJournalBytesUntilTheOriginalScopeReturns() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let provider = ReferenceHostPhysicalIphoneScopeProvider(
      environment: ["CROSSWAKE_REFERENCE_HOST_SCOPE_REF": "v1.scope_fixture_alpha_01"]
    )
    let journal = ReferenceStudyJournal(root: root)

    XCTAssertEqual(journal.append(value: "neutral-answer", scopeRef: provider.currentScopeRef()), .passed)
    provider.didSwitchAccount(to: "v1.scope_fixture_bravo_01")
    XCTAssertEqual(journal.recover(scopeRef: provider.currentScopeRef()), .blocked)
    provider.didLogout()
    XCTAssertEqual(journal.recover(scopeRef: provider.currentScopeRef()), .blocked)
    provider.didSwitchAccount(to: "v1.scope_fixture_alpha_01")
    XCTAssertEqual(journal.recover(scopeRef: provider.currentScopeRef()), .passed)
  }

  func testCorruptJournalBytesRemainBlockedWithoutRenderingTheirContents() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let scope = "v1.scope_fixture_alpha_01"
    let filename = sha256Hex(Data(scope.utf8)) + ".json"
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    try Data("{".utf8).write(to: root.appendingPathComponent(filename))

    XCTAssertEqual(ReferenceStudyJournal(root: root).recover(scopeRef: scope), .blocked)
  }

  func testPhysicalReportNeverCarriesHostValues() async throws {
    let report = await PhysicalIphoneSequence.run(adapter: nil)
    let data = try JSONEncoder().encode(report)
    let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    XCTAssertEqual(Set(object.keys), ["schema_version", "device_class", "assertions"])
    XCTAssertFalse(String(data: data, encoding: .utf8)!.contains("path"))
    XCTAssertFalse(String(data: data, encoding: .utf8)!.contains("owner"))
  }

  func testPhysicalContractModeEmitsOwnerFreeReport() async throws {
    guard ProcessInfo.processInfo.environment["CROSSWAKE_PHYSICAL_IPHONE_CONTRACT_MODE"] == "1" else { return }
    let report = await PhysicalIphoneSequence.run(adapter: PhysicalIphoneHostAdapterFactory.make())
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    print(String(decoding: try encoder.encode(report), as: UTF8.self))
  }

  func testFixtureInstallReconcilesAfterRelaunch() async throws {
    ProofLaneReferencePackAdapter.resetReferencePersistenceForTests()
    let adapter = try XCTUnwrap(ProofLaneReferencePackAdapter())
    XCTAssertEqual(adapter.observe().outcome, .blocked)

    let installed = await adapter.installPronunciationPackForeground()
    XCTAssertEqual(installed.outcome, .passed, "PACK-INSTALL-READY")

    let relaunched = ProofLaneReferencePackAdapter().observe()
    XCTAssertEqual(relaunched.outcome, .passed, "PACK-RELAUNCH-READY")

    let audioAdapter = ProofLaneReferencePackAdapter()
    let audio = await audioAdapter.exerciseInstalledPronunciationAudioOffline()
    XCTAssertEqual(audio.outcome, .passed)
    emitStructuredEvidence(from: audioAdapter.audioEvidenceForContractTest())
  }

  func testWrongRequirementAndFailedAudioRemainNonPassing() async {
    ProofLaneReferencePackAdapter.resetReferencePersistenceForTests()
    let adapter = ProofLaneReferencePackAdapter()
    let audio = await adapter.exerciseInstalledPronunciationAudioOffline()
    let wrongRequirement = await ProofLaneReferencePackAdapter(requiredVersion: "wrong").installPronunciationPackForeground()

    XCTAssertEqual(audio.outcome, .blocked, "PACK-AUDIO-OFFLINE")
    XCTAssertEqual(wrongRequirement.outcome, .blocked)
  }

  func testUnexpectedNetworkObservationBlocksAudioAndEmitsNoEvidence() async {
    ProofLaneReferencePackAdapter.resetReferencePersistenceForTests()
    let adapter = ProofLaneReferencePackAdapter(networkObservation: { .unexpectedSuccess })
    let installed = await adapter.installPronunciationPackForeground()
    let audio = await adapter.exerciseInstalledPronunciationAudioOffline()
    XCTAssertEqual(installed.outcome, .passed)
    XCTAssertEqual(audio.outcome, .blocked)
    XCTAssertNil(adapter.audioEvidenceForContractTest())
  }

  private func emitStructuredEvidence(from assertionIDs: [String]?) {
    guard let assertionIDs else { return }
    let document = ProofLaneEvidenceDocument(
      schemaVersion: 2,
      outcome: "passed",
      assertionIDs: assertionIDs
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    guard let data = try? encoder.encode(document),
          let output = String(data: data, encoding: .utf8) else { return }
    print(output)
  }

  private func sha256Hex(_ data: Data) -> String {
    SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
  }

  private func emitNavigationEvidence(outcome: ProofLaneOutcome) {
    let document = ProofLaneNavigationEvidenceDocument(
      schemaVersion: 3,
      outcome: outcome.rawValue,
      scope: "advisory",
      assertionIDs: ProofLaneNavigationAssertion.allCases.map(\.rawValue)
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    guard let data = try? encoder.encode(document),
          let output = String(data: data, encoding: .utf8) else { return }
    print(output)
  }

  private func expectedOutcomes(
    stoppingAt operation: PhysicalIphoneOperation,
    outcome: ProofLaneOutcome
  ) -> [ProofLaneOutcome] {
    switch operation {
    case .install, .audio:
      return Array(repeating: outcome, count: PhysicalIphoneAssertion.allCases.count)
    case .entry, .selected:
      return [.passed, outcome, outcome, outcome, outcome]
    case .freeForm:
      return [.passed, .passed, outcome, outcome, outcome]
    case .relaunch:
      return [.passed, .passed, .passed, outcome, outcome]
    case .recovery:
      return [.passed, .passed, .passed, .passed, outcome]
    }
  }
}

private enum PhysicalIphoneOperation: CaseIterable {
  case install
  case audio
  case entry
  case selected
  case freeForm
  case relaunch
  case recovery
}

private final class RecordingPhysicalIphoneAdapter: PhysicalIphoneHostAdapter {
  private(set) var calls: [PhysicalIphoneOperation] = []
  private let failing: PhysicalIphoneOperation?
  private let outcome: ProofLaneOutcome

  init(failing: PhysicalIphoneOperation? = nil, outcome: ProofLaneOutcome = .passed) {
    self.failing = failing
    self.outcome = outcome
  }

  func installAndVerifyPack() async -> ProofLaneOutcome { record(.install) }
  func playInstalledAudioOffline() async -> ProofLaneOutcome { record(.audio) }
  func enterAuthorizedStudy() async -> ProofLaneOutcome { record(.entry) }
  func submitSelectedAnswerOffline() async -> ProofLaneOutcome { record(.selected) }
  func submitFreeFormAnswerOffline(_ value: String) async -> ProofLaneOutcome {
    guard value == "contract-value" else { return .blocked }
    return record(.freeForm)
  }
  func relaunchWithoutResetAndReconnect() async -> ProofLaneOutcome { record(.relaunch) }
  func observeRecoveryAndRetainedWork() async -> ProofLaneOutcome { record(.recovery) }

  private func record(_ operation: PhysicalIphoneOperation) -> ProofLaneOutcome {
    calls.append(operation)
    return failing == operation ? outcome : .passed
  }
}

private struct ProofLaneEvidenceDocument: Codable {
  let schemaVersion: Int
  let outcome: String
  let assertionIDs: [String]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case outcome
    case assertionIDs = "assertion_ids"
  }
}

private struct ProofLaneNavigationEvidenceDocument: Codable {
  let schemaVersion: Int
  let outcome: String
  let scope: String
  let assertionIDs: [String]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case outcome
    case scope
    case assertionIDs = "assertion_ids"
  }
}
