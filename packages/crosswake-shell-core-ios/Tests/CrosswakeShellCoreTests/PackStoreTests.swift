import XCTest
@testable import CrosswakeShellCore

@MainActor
final class PackStoreTests: XCTestCase {
    func testNilProviderIsClosedUnavailable() async {
        let requirement = PackRequirement(packID: "audio", requiredVersion: "1", expectedByteCount: 1, expectedSHA256: "a")
        let store = PackStore(requirements: [requirement])

        XCTAssertEqual(store.statuses["audio"]?.state, .failed)
        XCTAssertEqual(store.statuses["audio"]?.failureReason, .providerUnavailable)

        await store.reconcileAll()
        XCTAssertEqual(store.statuses["audio"]?.failureReason, .providerUnavailable)
    }

    func testProviderStartsCheckingThenReconcilesOnce() async {
        let requirement = PackRequirement(packID: "audio", requiredVersion: "1", expectedByteCount: 1, expectedSHA256: "a")
        let provider = CountingProvider()
        let store = PackStore(requirements: [requirement], provider: provider)

        XCTAssertEqual(store.statuses["audio"]?.state, .checking)
        await store.reconcileAll()
        let statusCalls = await provider.statusCalls
        XCTAssertEqual(statusCalls, 1)
        XCTAssertEqual(store.statuses["audio"]?.state, .notInstalled)
    }

    func testClosedStatesAndReasonsRoundTripWithoutProviderDetails() {
        XCTAssertEqual(Set(PackState.allCases.map(\.rawValue)), Set(["checking", "not_installed", "installing", "available", "stale", "invalidating", "failed"]))
        XCTAssertEqual(Set(PackFailureReason.allCases.map(\.rawValue)), Set(["provider_unavailable", "transfer_interrupted", "insufficient_storage", "size_mismatch", "digest_mismatch", "version_mismatch", "atomic_install_failed", "inventory_persistence_failed", "invalidation_failed", "malformed_provider_result", "provider_failed"]))
        XCTAssertEqual(PackFailureReason(rawValue: "host-private-details"), nil)
    }

    func testConfigKeepsProviderOutOfRegisteredCapabilities() {
        let config = CrosswakeShellConfig(packProvider: CountingProvider())
        XCTAssertNotNil(config.packProvider)
        XCTAssertFalse(config.registeredCapabilities.contains(where: { $0.contains("pack") }))
    }
}

private actor CountingProvider: PackProvider {
    private(set) var statusCalls = 0

    func status(for requirement: PackRequirement) async -> PackProviderResult {
        statusCalls += 1
        return .notInstalled
    }

    func install(_ requirement: PackRequirement) async -> PackProviderResult { .notInstalled }
    func invalidate(_ requirement: PackRequirement) async -> PackProviderResult { .notInstalled }
}
