import Foundation
import XCTest
@testable import CrosswakeShellCore

@MainActor
final class NotificationOpenQueueTests: XCTestCase {
    func test_queue_is_bounded_reloads_and_serializes_only_opaque_evidence() async throws {
        let directory = try temporaryDirectory()
        let enqueueTime = Date(timeIntervalSince1970: 1_000)
        let queue = try NotificationOpenQueue(directory: directory, maximumCount: 2, maximumAge: 60, now: { enqueueTime })

        try await queue.enqueue(evidence(openRef: "open-1", correlationID: "correlation-1"))
        try await queue.enqueue(evidence(openRef: "open-2", correlationID: "correlation-2"))
        try await queue.enqueue(evidence(openRef: "open-3", correlationID: "correlation-3"))

        let bounded = try await queue.pendingEvidence()
        XCTAssertEqual(bounded.map(\.openRef), ["open-2", "open-3"])
        let persisted = try String(contentsOf: directory.appendingPathComponent("notification-open-queue-v1.json"), encoding: .utf8)
        ["url", "route", "token", "tenant", "session", "payload", "authorized"].forEach { forbidden in
            XCTAssertFalse(persisted.lowercased().contains(forbidden))
        }

        let reloaded = try NotificationOpenQueue(directory: directory, maximumCount: 2, maximumAge: 60, now: { enqueueTime })
        let reloadedEvidence = try await reloaded.pendingEvidence()
        XCTAssertEqual(reloadedEvidence.map(\.openRef), ["open-2", "open-3"])
        let expired = try NotificationOpenQueue(directory: directory, maximumCount: 2, maximumAge: 60, now: { enqueueTime.addingTimeInterval(61) })
        let expiredEvidence = try await expired.pendingEvidence()
        XCTAssertTrue(expiredEvidence.isEmpty)
    }

    func test_drain_consumes_once_and_removes_terminal_outcomes() async throws {
        let directory = try temporaryDirectory()
        let queue = try NotificationOpenQueue(directory: directory)
        let allow = NotificationOpenAllowedActivation(request: request())
        let delegate = RecordingOpenDelegate(outcomes: [.allowed(allow), .denied(.replayed), .retryableTransportFailure])

        try await queue.enqueue(evidence(openRef: "allow", correlationID: "one"))
        try await queue.enqueue(evidence(openRef: "replayed", correlationID: "two"))
        try await queue.enqueue(evidence(openRef: "retry", correlationID: "three"))

        var allowed: [NotificationOpenAllowedActivation] = []
        try await queue.drain(using: delegate) { allowed.append($0) }

        XCTAssertEqual(delegate.consumed.map(\.openRef), ["allow", "replayed", "retry"])
        XCTAssertEqual(allowed, [allow])
        let pending = try await queue.pendingEvidence()
        XCTAssertEqual(pending.map(\.openRef), ["retry"])
    }

    func test_duplicate_open_ref_is_first_wins_across_reload_and_production_drain() async throws {
        let directory = try temporaryDirectory()
        let evidence = evidence(openRef: "one-time-open", correlationID: "first-correlation")
        let queue = try NotificationOpenQueue(directory: directory)

        try await queue.enqueue(evidence)
        try await queue.enqueue(evidence)

        let reloaded = try NotificationOpenQueue(directory: directory)
        let reloadedEvidence = try await reloaded.pendingEvidence()
        XCTAssertEqual(reloadedEvidence, [evidence])

        let allowed = NotificationOpenAllowedActivation(request: request())
        let delegate = RecordingOpenDelegate(outcomes: [.allowed(allowed), .denied(.replayed)])
        let coordinator = ActivationCoordinator(
            manifestLoader: { self.manifest(entry: "external") },
            requestLoader: { self.request() },
            packStore: PackStore(requiredVersions: [:], inventory: []),
            config: CrosswakeShellConfig()
        )

        try await reloaded.drain(using: delegate, activationCoordinator: coordinator)

        XCTAssertEqual(delegate.consumed, [evidence])
        let pendingEvidence = try await reloaded.pendingEvidence()
        XCTAssertTrue(pendingEvidence.isEmpty)
        guard case let .liveView(session) = coordinator.presentation else {
            return XCTFail("expected allowed protected activation to remain presented")
        }
        XCTAssertEqual(session.routeID, "dashboard")
    }

    func test_corrupt_storage_is_discarded_without_exposing_contents() async throws {
        let directory = try temporaryDirectory()
        let file = directory.appendingPathComponent("notification-open-queue-v1.json")
        try Data("not-json-secret".utf8).write(to: file)

        let queue = try NotificationOpenQueue(directory: directory)
        let pending = try await queue.pendingEvidence()
        XCTAssertTrue(pending.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
    }

    private func evidence(openRef: String, correlationID: String) -> NotificationOpenEvidence {
        NotificationOpenEvidence(openRef: openRef, bindingRef: "binding-1", actionRef: "tap", correlationID: correlationID)
    }

    private func request() -> ActivationRequest {
        ActivationRequest(routeID: "dashboard", url: nil, source: .notification, origin: "https://app.example.com", manifestSource: .bundled, bridgeProtocolVersion: "1", nativeRuntimeVersion: "1.0.0", correlationID: "trusted")
    }

    private func manifest(entry: String) -> ShellManifest {
        ShellManifest(
            compatibility: .init(nativeRuntimeVersion: "1.0.0"),
            routes: ["dashboard": .init(id: "dashboard", path: "/dashboard", runtime: "live_view", entry: entry, capabilities: [], packs: [], transfers: [], allowlistedOrigins: ["https://app.example.com"])]
        )
    }

    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}

private final class RecordingOpenDelegate: NotificationOpenDelegate {
    private var outcomes: [NotificationOpenConsumptionOutcome]
    private(set) var consumed: [NotificationOpenEvidence] = []

    init(outcomes: [NotificationOpenConsumptionOutcome]) { self.outcomes = outcomes }

    func consume(_ evidence: NotificationOpenEvidence) async -> NotificationOpenConsumptionOutcome {
        consumed.append(evidence)
        return outcomes.removeFirst()
    }
}
