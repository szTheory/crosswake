import CryptoKit
import Foundation
import XCTest
@testable import CrosswakeShell
@testable import CrosswakeShellCore

@MainActor
final class PronunciationPackProviderTests: XCTestCase {
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

    private func makeTemporaryRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }
}
