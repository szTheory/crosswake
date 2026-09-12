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

    func testStaleReconciliationCannotClearFailedInvalidationRevocation() async {
        let requirement = uniqueRequirement()
        let provider = ControlledPackProvider()
        let store = PackStore(requirements: [requirement], provider: provider)
        let initialStatus = store.statuses[requirement.packID]!

        let reconciliation = Task { await store.reconcileAll() }
        await provider.waitForStatusEntries(1)
        let invalidation = Task { await store.invalidatePack(initialStatus) }
        await provider.waitForInvalidationEntries(1)

        await provider.resumeNextStatus(installedResult(for: requirement))
        await provider.resumeNextInvalidation(.failure(.providerFailed))
        await invalidation.value
        await reconciliation.value

        XCTAssertEqual(store.statuses[requirement.packID]?.failureReason, .invalidationFailed)
        let relaunch = PackStore(requirements: [requirement], provider: provider)
        XCTAssertEqual(relaunch.statuses[requirement.packID]?.failureReason, .invalidationFailed)
    }

    func testOlderInvalidationCannotClearNewerRevocation() async {
        let requirement = uniqueRequirement()
        let provider = ControlledPackProvider()
        let store = PackStore(requirements: [requirement], provider: provider)
        let initialStatus = store.statuses[requirement.packID]!

        let older = Task { await store.invalidatePack(initialStatus) }
        await provider.waitForInvalidationEntries(1)
        let newer = Task { await store.invalidatePack(initialStatus) }
        await provider.waitForInvalidationEntries(2)

        await provider.resumeNextInvalidation(.notInstalled)
        await older.value
        await provider.resumeNextInvalidation(.failure(.providerFailed))
        await newer.value

        XCTAssertEqual(store.statuses[requirement.packID]?.failureReason, .invalidationFailed)
        let relaunch = PackStore(requirements: [requirement], provider: provider)
        XCTAssertEqual(relaunch.statuses[requirement.packID]?.failureReason, .invalidationFailed)
    }

    func testSameGenerationFreshAbsenceClearsRevocation() async {
        let requirement = uniqueRequirement()
        let provider = ControlledPackProvider()
        let store = PackStore(requirements: [requirement], provider: provider)
        let status = store.statuses[requirement.packID]!

        let invalidation = Task { await store.invalidatePack(status) }
        await provider.waitForInvalidationEntries(1)
        await provider.resumeNextInvalidation(.notInstalled)
        await provider.waitForStatusEntries(1)
        await provider.resumeNextStatus(.notInstalled)
        await invalidation.value

        XCTAssertEqual(store.statuses[requirement.packID]?.state, .notInstalled)
        let relaunch = PackStore(requirements: [requirement], provider: provider)
        XCTAssertEqual(relaunch.statuses[requirement.packID]?.state, .checking)
    }

    func testVerifiedReinstallAndFreshExactStatusClearRevocation() async {
        let requirement = uniqueRequirement()
        let provider = ControlledPackProvider()
        let store = PackStore(requirements: [requirement], provider: provider)
        let status = store.statuses[requirement.packID]!

        let invalidation = Task { await store.invalidatePack(status) }
        await provider.waitForInvalidationEntries(1)
        await provider.resumeNextInvalidation(.failure(.providerFailed))
        await invalidation.value

        await provider.setInstallResult(installedResult(for: requirement))
        let reinstall = Task { await store.installRequiredPack(store.statuses[requirement.packID]!) }
        await provider.waitForStatusEntries(1)
        await provider.resumeNextStatus(installedResult(for: requirement))
        await reinstall.value

        XCTAssertEqual(store.statuses[requirement.packID]?.state, .available)
        let relaunch = PackStore(requirements: [requirement], provider: provider)
        XCTAssertEqual(relaunch.statuses[requirement.packID]?.state, .checking)
    }

    private func uniqueRequirement() -> PackRequirement {
        PackRequirement(packID: "audio-\(UUID().uuidString.lowercased())", requiredVersion: "1", expectedByteCount: 1, expectedSHA256: "a")
    }

    private func installedResult(for requirement: PackRequirement) -> PackProviderResult {
        .installed(PackInstalledRecord(contractVersion: requirement.contractVersion, packID: requirement.packID, installedVersion: requirement.requiredVersion, byteCount: requirement.expectedByteCount, integrityVerified: true, atomicPromotionCompleted: true))
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

private actor ControlledPackProvider: PackProvider {
    private var statusContinuations: [CheckedContinuation<PackProviderResult, Never>] = []
    private var invalidationContinuations: [CheckedContinuation<PackProviderResult, Never>] = []
    private var statusEntries = 0
    private var invalidationEntries = 0
    private var installResult: PackProviderResult = .failure(.providerFailed)
    private var statusWaiters: [(Int, CheckedContinuation<Void, Never>)] = []
    private var invalidationWaiters: [(Int, CheckedContinuation<Void, Never>)] = []

    func status(for requirement: PackRequirement) async -> PackProviderResult {
        statusEntries += 1
        resumeStatusWaiters()
        return await withCheckedContinuation { statusContinuations.append($0) }
    }

    func install(_ requirement: PackRequirement) async -> PackProviderResult { installResult }

    func invalidate(_ requirement: PackRequirement) async -> PackProviderResult {
        invalidationEntries += 1
        resumeInvalidationWaiters()
        return await withCheckedContinuation { invalidationContinuations.append($0) }
    }

    func waitForStatusEntries(_ count: Int) async {
        guard statusEntries < count else { return }
        await withCheckedContinuation { statusWaiters.append((count, $0)) }
    }

    func waitForInvalidationEntries(_ count: Int) async {
        guard invalidationEntries < count else { return }
        await withCheckedContinuation { invalidationWaiters.append((count, $0)) }
    }

    func resumeNextStatus(_ result: PackProviderResult) {
        statusContinuations.removeFirst().resume(returning: result)
    }

    func resumeNextInvalidation(_ result: PackProviderResult) {
        invalidationContinuations.removeFirst().resume(returning: result)
    }

    func setInstallResult(_ result: PackProviderResult) {
        installResult = result
    }

    private func resumeStatusWaiters() {
        let ready = statusWaiters.filter { waiter in waiter.0 <= statusEntries }
        statusWaiters.removeAll { waiter in waiter.0 <= statusEntries }
        ready.forEach { waiter in waiter.1.resume() }
    }

    private func resumeInvalidationWaiters() {
        let ready = invalidationWaiters.filter { waiter in waiter.0 <= invalidationEntries }
        invalidationWaiters.removeAll { waiter in waiter.0 <= invalidationEntries }
        ready.forEach { waiter in waiter.1.resume() }
    }
}
