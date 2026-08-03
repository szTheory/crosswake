import CryptoKit
import Foundation
import XCTest
@testable import CrosswakeShell
@testable import CrosswakeShellCore

@MainActor
final class PronunciationPackProviderTests: XCTestCase {
    func testDurabilityOrderingRecordsJournalSyncBeforeRetentionRename() async throws {
        let bytes = try fixtureBytes()
        let requirement = requirement(for: bytes)
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        _ = await PronunciationPackProvider(source: { bytes }, storageRoot: root).install(requirement)
        let recorder = DurabilityOperationRecorder()
        _ = await PronunciationPackProvider(source: { bytes }, storageRoot: root, publicationOperations: recorder.operations).install(self.requirement(for: bytes, version: "2"))
        let events = recorder.events
        let journalSync = try XCTUnwrap(events.firstIndex(of: "sync-file:replacement-journal.json"))
        let rename = try XCTUnwrap(events.firstIndex(where: { $0.hasPrefix("move:pack-") }))
        XCTAssertLessThan(journalSync, rename)
    }
    func testBundledConstructionPropagatesExactRequirementThroughConcreteProvider() async throws {
        let fixture = try fixtureBytes()
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let provider = PronunciationPackProvider(source: { fixture }, storageRoot: root)
        let store = try PackStore.bundled(bundle: Bundle.main, provider: provider)
        let initial = try XCTUnwrap(store.statuses["lesson_library"])
        XCTAssertEqual(initial.state, .checking)

        await store.installRequiredPack(initial)
        XCTAssertEqual(store.statuses["lesson_library"]?.state, .available)
    }

    func testFixtureInstallPersistsExactVerifiedRecordForNewProvider() async throws {
        let fixture = try fixtureBytes()
        let requirement = requirement(for: fixture)
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let provider = PronunciationPackProvider(source: { fixture }, storageRoot: root)
        let installResult = await provider.install(requirement)
        XCTAssertEqual(installResult, .installed(expectedRecord(for: requirement)))
        let relaunched = PronunciationPackProvider(source: { fixture }, storageRoot: root)
        let relaunchStatus = await relaunched.status(for: requirement)
        XCTAssertEqual(relaunchStatus, .installed(expectedRecord(for: requirement)))
    }

    func testDeletedArtifactBlocksFreshProviderAndPackStore() async throws {
        let fixture = try fixtureBytes()
        let requirement = requirement(for: fixture)
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let provider = PronunciationPackProvider(source: { fixture }, storageRoot: root)
        let installResult = await provider.install(requirement)
        XCTAssertEqual(installResult, .installed(expectedRecord(for: requirement)))
        try FileManager.default.removeItem(at: artifactURL(in: root, for: requirement))

        let relaunched = PronunciationPackProvider(source: { fixture }, storageRoot: root)
        let status = await relaunched.status(for: requirement)
        XCTAssertEqual(status, .notInstalled)
        let store = PackStore(requirements: [requirement], provider: relaunched)
        await store.reconcileAll()
        XCTAssertEqual(store.statuses[requirement.packID]?.state, .notInstalled)
        XCTAssertNotNil(store.blockingStatus(for: ["\(requirement.packID)@\(requirement.requiredVersion)"]))
    }

    func testSameSizeCorruptionFailsDigestVerificationAfterRelaunch() async throws {
        let fixture = try fixtureBytes()
        let requirement = requirement(for: fixture)
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let provider = PronunciationPackProvider(source: { fixture }, storageRoot: root)
        _ = await provider.install(requirement)
        var corrupted = fixture
        corrupted[0] ^= 0xFF
        try corrupted.write(to: artifactURL(in: root, for: requirement), options: .atomic)

        let relaunched = PronunciationPackProvider(source: { fixture }, storageRoot: root)
        let status = await relaunched.status(for: requirement)
        XCTAssertEqual(status, .failure(.digestMismatch))
        let store = PackStore(requirements: [requirement], provider: relaunched)
        await store.reconcileAll()
        XCTAssertEqual(store.statuses[requirement.packID]?.failureReason, .digestMismatch)
    }

    func testWrongSizeArtifactFailsSizeVerificationAfterRelaunch() async throws {
        let fixture = try fixtureBytes()
        let requirement = requirement(for: fixture)
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let provider = PronunciationPackProvider(source: { fixture }, storageRoot: root)
        _ = await provider.install(requirement)
        try Data(fixture.dropLast()).write(to: artifactURL(in: root, for: requirement), options: .atomic)

        let relaunched = PronunciationPackProvider(source: { fixture }, storageRoot: root)
        let status = await relaunched.status(for: requirement)
        XCTAssertEqual(status, .failure(.sizeMismatch))
    }

    func testArtifactReadFailureReturnsClosedProviderFailure() async throws {
        let fixture = try fixtureBytes()
        let requirement = requirement(for: fixture)
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let provider = PronunciationPackProvider(source: { fixture }, storageRoot: root)
        _ = await provider.install(requirement)

        let relaunched = PronunciationPackProvider(
            source: { fixture },
            storageRoot: root,
            artifactVerifier: { _, _ in throw CocoaError(.fileReadNoPermission) }
        )
        let status = await relaunched.status(for: requirement)
        XCTAssertEqual(status, .failure(.providerFailed))
    }

    func testReplacementInventoryFailureRestoresKnownGoodArtifactAndRecord() async throws {
        let oldBytes = try fixtureBytes()
        var replacementBytes = oldBytes
        replacementBytes[0] ^= 0xFF
        let oldRequirement = requirement(for: oldBytes, version: "1")
        let replacementRequirement = requirement(for: replacementBytes, version: "2")
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let initial = PronunciationPackProvider(source: { oldBytes }, storageRoot: root)
        let initialResult = await initial.install(oldRequirement)
        XCTAssertEqual(initialResult, .installed(expectedRecord(for: oldRequirement)))

        let failingReplacement = PronunciationPackProvider(
            source: { replacementBytes },
            storageRoot: root,
            inventoryWriter: { _, _ in throw CocoaError(.fileWriteNoPermission) }
        )
        let result = await failingReplacement.install(replacementRequirement)
        XCTAssertEqual(result, .failure(.inventoryPersistenceFailed))
        XCTAssertEqual(try Data(contentsOf: artifactURL(in: root, for: oldRequirement)), oldBytes)

        let relaunched = PronunciationPackProvider(source: { oldBytes }, storageRoot: root)
        let oldStatus = await relaunched.status(for: oldRequirement)
        let replacementStatus = await relaunched.status(for: replacementRequirement)
        XCTAssertEqual(oldStatus, .installed(expectedRecord(for: oldRequirement)))
        XCTAssertEqual(replacementStatus, .failure(.digestMismatch))
    }

    func testReplacementPromotionMoveFailureRestoresKnownGoodArtifactAndInventoryAfterRelaunch() async throws {
        let oldBytes = try fixtureBytes()
        var replacementBytes = oldBytes
        replacementBytes[0] ^= 0xFF
        let oldRequirement = requirement(for: oldBytes, version: "1")
        let replacementRequirement = requirement(for: replacementBytes, version: "2")
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let initial = PronunciationPackProvider(source: { oldBytes }, storageRoot: root)
        let initialResult = await initial.install(oldRequirement)
        XCTAssertEqual(initialResult, .installed(expectedRecord(for: oldRequirement)))
        let priorInventoryData = try Data(contentsOf: inventoryURL(in: root))

        let failingReplacement = PronunciationPackProvider(
            source: { replacementBytes },
            storageRoot: root,
            publicationMover: { source, destination in
                if source.lastPathComponent.hasPrefix(".staging-") &&
                    destination.lastPathComponent.hasPrefix("pack-") {
                    throw CocoaError(.fileWriteNoPermission)
                }
                try FileManager.default.moveItem(at: source, to: destination)
            }
        )

        let replacementResult = await failingReplacement.install(replacementRequirement)
        XCTAssertEqual(replacementResult, .failure(.atomicInstallFailed))
        XCTAssertEqual(try Data(contentsOf: artifactURL(in: root, for: oldRequirement)), oldBytes)
        XCTAssertEqual(try Data(contentsOf: inventoryURL(in: root)), priorInventoryData)
        let immediateOldStatus = await failingReplacement.status(for: oldRequirement)
        let immediateReplacementStatus = await failingReplacement.status(for: replacementRequirement)
        XCTAssertEqual(immediateOldStatus, .installed(expectedRecord(for: oldRequirement)))
        XCTAssertEqual(immediateReplacementStatus, .failure(.digestMismatch))

        let relaunched = PronunciationPackProvider(source: { oldBytes }, storageRoot: root)
        let relaunchedOldStatus = await relaunched.status(for: oldRequirement)
        let relaunchedReplacementStatus = await relaunched.status(for: replacementRequirement)
        XCTAssertEqual(relaunchedOldStatus, .installed(expectedRecord(for: oldRequirement)))
        XCTAssertEqual(relaunchedReplacementStatus, .failure(.digestMismatch))
    }

    func testConstructionBootstrapRecoversRetainedKnownGoodPublication() async throws {
        let bytes = try fixtureBytes()
        let requirement = requirement(for: bytes)
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let record = expectedRecord(for: requirement)
        let destination = artifactURL(in: root, for: requirement)
        let retained = root.appendingPathComponent(".previous-transaction-old")
        try bytes.write(to: retained)
        try writeInventory([requirement.packID: record], in: root)
        try writeJournal(
            ReplacementJournal(
                schemaVersion: 1,
                phase: .retentionPending,
                packID: requirement.packID,
                nonce: "transaction",
                stagingLeaf: ".staging-transaction",
                destinationLeaf: destination.lastPathComponent,
                retainedLeaf: retained.lastPathComponent,
                priorRecord: record,
                currentRecord: record
            ),
            in: root
        )

        let relaunched = PronunciationPackProvider(source: { bytes }, storageRoot: root)
        let status = await relaunched.status(for: requirement)
        XCTAssertEqual(status, .installed(record))
        XCTAssertEqual(try Data(contentsOf: destination), bytes)
        XCTAssertFalse(FileManager.default.fileExists(atPath: journalURL(in: root).path))
    }

    func testConstructionBootstrapRollsBackPromotedReplacementBeforeInventoryCommit() async throws {
        let oldBytes = try fixtureBytes()
        var replacementBytes = oldBytes
        replacementBytes[0] ^= 0xFF
        let oldRequirement = requirement(for: oldBytes, version: "1")
        let replacementRequirement = requirement(for: replacementBytes, version: "2")
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let oldRecord = expectedRecord(for: oldRequirement)
        let replacementRecord = expectedRecord(for: replacementRequirement)
        let destination = artifactURL(in: root, for: oldRequirement)
        let retained = root.appendingPathComponent(".previous-transaction-old")
        try oldBytes.write(to: retained)
        try replacementBytes.write(to: destination)
        try writeInventory([oldRequirement.packID: oldRecord], in: root)
        try writeJournal(
            ReplacementJournal(
                schemaVersion: 1,
                phase: .inventoryCommitPending,
                packID: oldRequirement.packID,
                nonce: "transaction",
                stagingLeaf: ".staging-transaction",
                destinationLeaf: destination.lastPathComponent,
                retainedLeaf: retained.lastPathComponent,
                priorRecord: oldRecord,
                currentRecord: replacementRecord
            ),
            in: root
        )

        let relaunched = PronunciationPackProvider(source: { oldBytes }, storageRoot: root)
        let oldStatus = await relaunched.status(for: oldRequirement)
        let replacementStatus = await relaunched.status(for: replacementRequirement)
        XCTAssertEqual(oldStatus, .installed(oldRecord))
        XCTAssertEqual(replacementStatus, .failure(.digestMismatch))
        XCTAssertEqual(try Data(contentsOf: destination), oldBytes)
        XCTAssertFalse(FileManager.default.fileExists(atPath: journalURL(in: root).path))
    }

    func testConstructionBootstrapFinalizesCommittedReplacement() async throws {
        let oldBytes = try fixtureBytes()
        var replacementBytes = oldBytes
        replacementBytes[0] ^= 0xFF
        let oldRequirement = requirement(for: oldBytes, version: "1")
        let replacementRequirement = requirement(for: replacementBytes, version: "2")
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let oldRecord = expectedRecord(for: oldRequirement)
        let replacementRecord = expectedRecord(for: replacementRequirement)
        let destination = artifactURL(in: root, for: oldRequirement)
        let retained = root.appendingPathComponent(".previous-transaction-old")
        try oldBytes.write(to: retained)
        try replacementBytes.write(to: destination)
        try writeInventory([oldRequirement.packID: replacementRecord], in: root)
        try writeJournal(
            ReplacementJournal(
                schemaVersion: 1,
                phase: .committedCleanupPending,
                packID: oldRequirement.packID,
                nonce: "transaction",
                stagingLeaf: ".staging-transaction",
                destinationLeaf: destination.lastPathComponent,
                retainedLeaf: retained.lastPathComponent,
                priorRecord: oldRecord,
                currentRecord: replacementRecord
            ),
            in: root
        )

        let relaunched = PronunciationPackProvider(source: { oldBytes }, storageRoot: root)
        let status = await relaunched.status(for: replacementRequirement)
        XCTAssertEqual(status, .installed(replacementRecord))
        XCTAssertEqual(try Data(contentsOf: destination), replacementBytes)
        XCTAssertFalse(FileManager.default.fileExists(atPath: retained.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: journalURL(in: root).path))
    }

    func testRestartRecoveryRejectsMalformedSchemaAndPhase() async throws {
        let bytes = try fixtureBytes()
        let requirement = requirement(for: bytes)
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let record = expectedRecord(for: requirement)
        let destination = artifactURL(in: root, for: requirement)
        try bytes.write(to: destination)
        try writeInventory([requirement.packID: record], in: root)
        try writeJournal(ReplacementJournal(schemaVersion: 99, phase: .promotionPending, packID: requirement.packID, nonce: "transaction", stagingLeaf: ".staging-transaction", destinationLeaf: destination.lastPathComponent, retainedLeaf: ".previous-transaction", priorRecord: record, currentRecord: record), in: root)
        let snapshot = try directoryEntries(root)

        let provider = PronunciationPackProvider(source: { bytes }, storageRoot: root)
        let status = await provider.status(for: requirement)
        XCTAssertEqual(status, .failure(.providerFailed))
        XCTAssertEqual(try directoryEntries(root), snapshot)
    }

    func testRestartRecoveryRejectsSiblingPackDestination() async throws {
        let bytes = try fixtureBytes()
        let requirement = requirement(for: bytes)
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let record = expectedRecord(for: requirement)
        let sibling = root.appendingPathComponent("pack-sibling")
        try bytes.write(to: sibling)
        try writeInventory([requirement.packID: record], in: root)
        try writeJournal(ReplacementJournal(schemaVersion: 1, phase: .promotionPending, packID: requirement.packID, nonce: "transaction", stagingLeaf: ".staging-transaction", destinationLeaf: sibling.lastPathComponent, retainedLeaf: ".previous-transaction", priorRecord: record, currentRecord: record), in: root)
        let snapshot = try directorySnapshot(root)

        let provider = PronunciationPackProvider(source: { bytes }, storageRoot: root)
        let status = await provider.status(for: requirement)
        XCTAssertEqual(status, .failure(.providerFailed))
        XCTAssertEqual(try directorySnapshot(root), snapshot)
    }

    func testRestartRecoveryRejectsRecordIdentityOrVersionMismatch() async throws {
        let bytes = try fixtureBytes()
        let requirement = requirement(for: bytes)
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let record = expectedRecord(for: requirement)
        let retained = root.appendingPathComponent(".previous-transaction")
        try bytes.write(to: retained)
        try writeInventory([requirement.packID: record], in: root)
        let mismatched = PackInstalledRecord(contractVersion: .v1, packID: "sibling", installedVersion: "1", byteCount: record.byteCount, integrityVerified: true, atomicPromotionCompleted: true)
        try writeJournal(ReplacementJournal(schemaVersion: 1, phase: .retentionPending, packID: requirement.packID, nonce: "transaction", stagingLeaf: ".staging-transaction", destinationLeaf: artifactURL(in: root, for: requirement).lastPathComponent, retainedLeaf: retained.lastPathComponent, priorRecord: mismatched, currentRecord: record), in: root)
        let snapshot = try directorySnapshot(root)

        let provider = PronunciationPackProvider(source: { bytes }, storageRoot: root)
        let status = await provider.status(for: requirement)
        XCTAssertEqual(status, .failure(.providerFailed))
        XCTAssertEqual(try directorySnapshot(root), snapshot)
    }

    func testRestartRecoveryRejectsNonRegularDescendantWithoutMutation() async throws {
        let bytes = try fixtureBytes()
        let requirement = requirement(for: bytes)
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let record = expectedRecord(for: requirement)
        let retained = root.appendingPathComponent(".previous-transaction")
        try FileManager.default.createDirectory(at: retained, withIntermediateDirectories: false)
        try writeInventory([requirement.packID: record], in: root)
        try writeJournal(ReplacementJournal(schemaVersion: 1, phase: .retentionPending, packID: requirement.packID, nonce: "transaction", stagingLeaf: ".staging-transaction", destinationLeaf: artifactURL(in: root, for: requirement).lastPathComponent, retainedLeaf: retained.lastPathComponent, priorRecord: record, currentRecord: record), in: root)
        let snapshot = try directoryEntries(root)

        let provider = PronunciationPackProvider(source: { bytes }, storageRoot: root)
        let status = await provider.status(for: requirement)
        XCTAssertEqual(status, .failure(.providerFailed))
        XCTAssertEqual(try directoryEntries(root), snapshot)
    }

    func testRestartRecoveryRejectsInjectedMismatchedVolumeExistingLeafWithoutMutation() async throws {
        let bytes = try fixtureBytes()
        let requirement = requirement(for: bytes)
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let record = expectedRecord(for: requirement)
        let retained = root.appendingPathComponent(".previous-transaction")
        try bytes.write(to: retained)
        try writeInventory([requirement.packID: record], in: root)
        try writeJournal(ReplacementJournal(schemaVersion: 1, phase: .retentionPending, packID: requirement.packID, nonce: "transaction", stagingLeaf: ".staging-transaction", destinationLeaf: artifactURL(in: root, for: requirement).lastPathComponent, retainedLeaf: retained.lastPathComponent, priorRecord: record, currentRecord: record), in: root)
        let snapshot = try directorySnapshot(root)
        let provider = PronunciationPackProvider(source: { bytes }, storageRoot: root, filesystemIdentity: { url in
            url.lastPathComponent == retained.lastPathComponent ? "different" : "root"
        })
        let status = await provider.status(for: requirement)
        XCTAssertEqual(status, .failure(.providerFailed))
        XCTAssertEqual(try directorySnapshot(root), snapshot)
    }

    func testFirstInstallInventoryFailureRemovesUncommittedArtifactAndRecord() async throws {
        let fixture = try fixtureBytes()
        let requirement = requirement(for: fixture)
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let provider = PronunciationPackProvider(
            source: { fixture },
            storageRoot: root,
            inventoryWriter: { _, _ in throw CocoaError(.fileWriteNoPermission) }
        )

        let result = await provider.install(requirement)
        XCTAssertEqual(result, .failure(.inventoryPersistenceFailed))
        XCTAssertFalse(FileManager.default.fileExists(atPath: artifactURL(in: root, for: requirement).path))
        let relaunched = PronunciationPackProvider(source: { fixture }, storageRoot: root)
        let status = await relaunched.status(for: requirement)
        XCTAssertEqual(status, .notInstalled)
    }

    func testRejectedReplacementPreservesKnownGoodArtifact() async throws {
        let fixture = try fixtureBytes()
        let oldRequirement = requirement(for: fixture, version: "1")
        let newRequirement = requirement(for: fixture, version: "2")
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let provider = PronunciationPackProvider(source: { fixture }, storageRoot: root)
        _ = await provider.install(oldRequirement)
        let rejected = PronunciationPackProvider(source: { Data("substituted".utf8) }, storageRoot: root)
        let rejectedResult = await rejected.install(newRequirement)
        XCTAssertEqual(rejectedResult, .failure(.sizeMismatch))
        let retainedStatus = await rejected.status(for: newRequirement)
        XCTAssertEqual(retainedStatus, .installed(expectedRecord(for: oldRequirement)))
    }

    func testStreamedVerifierUsesMultipleBoundedReads() async throws {
        let fixture = try fixtureBytes()
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let provider = PronunciationPackProvider(
            source: { fixture },
            storageRoot: root,
            verificationChunkSize: 8
        )
        let requirement = requirement(for: fixture)
        let result = await provider.install(requirement)
        XCTAssertEqual(result, .installed(expectedRecord(for: requirement)))
    }

    func testInstallStreamsStagedFileOffMainActorBeforePromotion() throws {
        let sourceURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("CrosswakeShell/PronunciationPackProvider.swift")
        let source = try String(contentsOf: sourceURL)

        XCTAssertTrue(source.contains("Task.detached(priority: .utility)"))
        XCTAssertTrue(source.contains("read(upToCount: chunkSize)"))
        XCTAssertTrue(source.range(of: "SHA256.hash(data: bytes)") == nil)
        XCTAssertLessThan(source.range(of: "verifyStagedFile")?.lowerBound ?? source.endIndex,
                          source.range(of: "replaceItemAt")?.lowerBound ?? source.endIndex)
    }

    private func fixtureBytes() throws -> Data {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "pronunciation-pack-fixture", withExtension: "bin"))
        return try Data(contentsOf: url)
    }

    private func requirement(for bytes: Data, version: String = "1") -> PackRequirement {
        PackRequirement(packID: "pronunciation-fixture", requiredVersion: version, expectedByteCount: bytes.count, expectedSHA256: SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined())
    }

    private func expectedRecord(for requirement: PackRequirement) -> PackInstalledRecord {
        PackInstalledRecord(contractVersion: .v1, packID: requirement.packID, installedVersion: requirement.requiredVersion, byteCount: requirement.expectedByteCount, integrityVerified: true, atomicPromotionCompleted: true)
    }

    private func artifactURL(in root: URL, for requirement: PackRequirement) -> URL {
        root.appendingPathComponent("pack-\(requirement.packID)")
    }

    private func inventoryURL(in root: URL) -> URL {
        root.appendingPathComponent("inventory.json")
    }

    private func journalURL(in root: URL) -> URL {
        root.appendingPathComponent("replacement-journal.json")
    }

    private func writeInventory(_ inventory: [String: PackInstalledRecord], in root: URL) throws {
        try JSONEncoder().encode(inventory).write(to: inventoryURL(in: root), options: .atomic)
    }

    private func writeJournal(_ journal: ReplacementJournal, in root: URL) throws {
        try JSONEncoder().encode(journal).write(to: journalURL(in: root), options: .atomic)
    }

    private func directorySnapshot(_ root: URL) throws -> [String: Data] {
        try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
            .reduce(into: [:]) { snapshot, url in
                snapshot[url.lastPathComponent] = try Data(contentsOf: url)
            }
    }

    private func directoryEntries(_ root: URL) throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: root.path).sorted()
    }


    private func makeTemporaryRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }
}

private final class DurabilityOperationRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String] = []
    var events: [String] { lock.lock(); defer { lock.unlock() }; return storage }
    private func record(_ event: String) { lock.lock(); storage.append(event); lock.unlock() }
    lazy var operations = PublicationOperations(
        atomicWrite: { [weak self] data, url in self?.record("write:\(url.lastPathComponent)"); try data.write(to: url, options: .atomic) },
        move: { [weak self] from, to in self?.record("move:\(from.lastPathComponent):\(to.lastPathComponent)"); try FileManager.default.moveItem(at: from, to: to) },
        remove: { [weak self] url in self?.record("remove:\(url.lastPathComponent)"); try FileManager.default.removeItem(at: url) },
        synchronizeFile: { [weak self] url in self?.record("sync-file:\(url.lastPathComponent)") },
        synchronizeDirectory: { [weak self] url in self?.record("sync-directory:\(url.lastPathComponent)") }
    )
}
