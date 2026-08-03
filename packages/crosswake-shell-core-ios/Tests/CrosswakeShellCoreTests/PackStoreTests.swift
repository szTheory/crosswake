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

    func testBlockingStatusClosesEveryInvalidRequiredReferenceInRouteOrder() async {
        let requirement = PackRequirement(packID: "audio", requiredVersion: "1", expectedByteCount: 1, expectedSHA256: "a")
        let store = PackStore(requirements: [requirement], provider: ExactInstalledProvider())
        await store.reconcileAll()

        let cases: [(reference: String, reason: PackFailureReason)] = [
            ("", .malformedProviderResult),
            ("   ", .malformedProviderResult),
            ("audio", .malformedProviderResult),
            ("audio@@1", .malformedProviderResult),
            ("@1", .malformedProviderResult),
            ("audio@", .malformedProviderResult),
            (" audio@1", .malformedProviderResult),
            ("unknown@1", .providerUnavailable),
            ("audio@2", .versionMismatch)
        ]

        for testCase in cases {
            let blocking = store.blockingStatus(for: [testCase.reference])
            XCTAssertEqual(blocking?.state, .failed, "expected a closed block")
            XCTAssertEqual(blocking?.failureReason, testCase.reason)
        }

        let firstInvalid = store.blockingStatus(for: ["audio@1", "@1"])
        XCTAssertEqual(firstInvalid?.failureReason, .malformedProviderResult)
        XCTAssertNotNil(store.blockingStatus(for: ["", "audio@1"]))
        XCTAssertNil(store.blockingStatus(for: ["audio@1"]))
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

private actor ExactInstalledProvider: PackProvider {
    func status(for requirement: PackRequirement) async -> PackProviderResult {
        .installed(
            PackInstalledRecord(
                contractVersion: requirement.contractVersion,
                packID: requirement.packID,
                installedVersion: requirement.requiredVersion,
                byteCount: requirement.expectedByteCount,
                integrityVerified: true,
                atomicPromotionCompleted: true
            )
        )
    }

    func install(_ requirement: PackRequirement) async -> PackProviderResult { await status(for: requirement) }
    func invalidate(_ requirement: PackRequirement) async -> PackProviderResult { .notInstalled }
}
