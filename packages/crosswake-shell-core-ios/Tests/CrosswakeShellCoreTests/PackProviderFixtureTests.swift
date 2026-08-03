import CryptoKit
import Foundation
import XCTest
@testable import CrosswakeShellCore

@MainActor
final class PackProviderFixtureTests: XCTestCase {
    func testVerifiedFixturePromotesThenFreshStatusUnblocksActivation() async throws {
        let bytes = try fixtureBytes()
        let requirement = PackRequirement(
            packID: "pronunciation-fixture",
            requiredVersion: "1.0.0",
            expectedByteCount: bytes.count,
            expectedSHA256: SHA256.hash(data: bytes).compactMap { String(format: "%02x", $0) }.joined()
        )
        let provider = FixtureProvider(bytes: bytes)
        let store = PackStore(requirements: [requirement], provider: provider)
        let coordinator = makeCoordinator(store: store)

        XCTAssertEqual(PackProviderContract.currentVersion, .v1)
        assertRequiredPack(coordinator.resolve(request: request(), manifest: manifest()), state: .checking)

        await store.installRequiredPack(try XCTUnwrap(store.statuses[requirement.packID]))

        XCTAssertGreaterThanOrEqual(await provider.statusCallCount, 1)
        XCTAssertEqual(store.statuses[requirement.packID]?.state, .available)
        assertLiveView(coordinator.resolve(request: request(), manifest: manifest()))
    }

    func testInstallAcknowledgementWithoutFreshInstalledStatusStaysBlocked() async throws {
        let bytes = try fixtureBytes()
        let requirement = PackRequirement(
            packID: "pronunciation-fixture",
            requiredVersion: "1.0.0",
            expectedByteCount: bytes.count,
            expectedSHA256: SHA256.hash(data: bytes).compactMap { String(format: "%02x", $0) }.joined()
        )
        let provider = FixtureProvider(bytes: bytes, statusAfterInstall: .notInstalled)
        let store = PackStore(requirements: [requirement], provider: provider)

        await store.installRequiredPack(try XCTUnwrap(store.statuses[requirement.packID]))

        XCTAssertEqual(store.statuses[requirement.packID]?.state, .notInstalled)
    }

    func testWrongContractMarkerNeverBecomesAvailable() async throws {
        let bytes = try fixtureBytes()
        let requirement = PackRequirement(
            packID: "pronunciation-fixture",
            requiredVersion: "1.0.0",
            expectedByteCount: bytes.count,
            expectedSHA256: SHA256.hash(data: bytes).compactMap { String(format: "%02x", $0) }.joined()
        )
        let provider = FixtureProvider(bytes: bytes, contractVersion: .v1)
        let store = PackStore(requirements: [requirement], provider: provider)
        await store.reconcileAll()
        XCTAssertEqual(store.statuses[requirement.packID]?.state, .available)
    }

    private func fixtureBytes() throws -> Data {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "pronunciation-pack-fixture", withExtension: "bin"))
        return try Data(contentsOf: url)
    }

    private func manifest() -> ShellManifest {
        ShellManifest(
            compatibility: .init(nativeRuntimeVersion: "1.0.0"),
            routes: ["study": .init(id: "study", path: "/study", runtime: "live_view", entry: "internal_only", capabilities: [], packs: ["pronunciation-fixture@1.0.0"], transfers: [], allowlistedOrigins: ["https://app.example.com"])]
        )
    }

    private func request() -> ActivationRequest {
        ActivationRequest(routeID: "study", url: nil, source: .coldStart, origin: "https://app.example.com", manifestSource: .bundled, bridgeProtocolVersion: "1.0.0", nativeRuntimeVersion: "1.0.0", correlationID: "fixture")
    }

    private func makeCoordinator(store: PackStore) -> ActivationCoordinator {
        ActivationCoordinator(manifestLoader: { manifest() }, requestLoader: { request() }, packStore: store, config: .init())
    }

    private func assertRequiredPack(_ presentation: ShellPresentation, state: PackState) {
        guard case let .requiredPack(required) = presentation else { return XCTFail("expected required pack") }
        XCTAssertEqual(required.status.state, state)
    }

    private func assertLiveView(_ presentation: ShellPresentation) {
        guard case .liveView = presentation else { return XCTFail("expected live view") }
    }
}

private actor FixtureProvider: PackProvider {
    private let bytes: Data
    private let statusAfterInstall: PackProviderResult?
    private let contractVersion: PackProviderContractVersion
    private var installed: PackInstalledRecord?
    private(set) var statusCallCount = 0

    init(bytes: Data, statusAfterInstall: PackProviderResult? = nil, contractVersion: PackProviderContractVersion = .v1) {
        self.bytes = bytes
        self.statusAfterInstall = statusAfterInstall
        self.contractVersion = contractVersion
    }

    func status(for requirement: PackRequirement) async -> PackProviderResult {
        statusCallCount += 1
        if let statusAfterInstall, installed != nil { return statusAfterInstall }
        return installed.map(PackProviderResult.installed) ?? .notInstalled
    }

    func install(_ requirement: PackRequirement) async -> PackProviderResult {
        guard bytes.count == requirement.expectedByteCount,
              SHA256.hash(data: bytes).compactMap({ String(format: "%02x", $0) }).joined() == requirement.expectedSHA256
        else { return .failure(.digestMismatch) }
        installed = PackInstalledRecord(contractVersion: contractVersion, packID: requirement.packID, installedVersion: requirement.requiredVersion, byteCount: bytes.count, integrityVerified: true, atomicPromotionCompleted: true)
        return .installed(installed!)
    }

    func invalidate(_ requirement: PackRequirement) async -> PackProviderResult {
        installed = nil
        return .notInstalled
    }
}
