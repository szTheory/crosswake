import CryptoKit
import Foundation
import XCTest
@testable import CrosswakeShell
@testable import CrosswakeShellCore

@MainActor
final class PronunciationPackProviderTests: XCTestCase {
    func testFixtureInstallPersistsExactVerifiedRecordForNewProvider() async throws {
        let fixture = try fixtureBytes()
        let requirement = requirement(for: fixture)
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let provider = PronunciationPackProvider(source: { fixture }, storageRoot: root)
        XCTAssertEqual(await provider.install(requirement), .installed(expectedRecord(for: requirement)))
        let relaunched = PronunciationPackProvider(source: { fixture }, storageRoot: root)
        XCTAssertEqual(await relaunched.status(for: requirement), .installed(expectedRecord(for: requirement)))
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
        XCTAssertEqual(await rejected.install(newRequirement), .failure(.sizeMismatch))
        XCTAssertEqual(await rejected.status(for: newRequirement), .installed(expectedRecord(for: oldRequirement)))
    }

    private func fixtureBytes() throws -> Data {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "pronunciation-pack-fixture", withExtension: "bin"))
        return try Data(contentsOf: url)
    }

    private func requirement(for bytes: Data, version: String = "1") -> PackRequirement {
        PackRequirement(packID: "pronunciation-fixture", requiredVersion: version, expectedByteCount: bytes.count, expectedSHA256: SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined())
    }

    private func expectedRecord(for requirement: PackRequirement) -> PackInstalledRecord {
        PackInstalledRecord(contractVersion: .v1, packID: requirement.packID, installedVersion: requirement.requiredVersion, byteCount: requirement.expectedByteCount, integrityVerified: true, atomicPromotionCompleted: true)
    }

    private func makeTemporaryRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }
}
