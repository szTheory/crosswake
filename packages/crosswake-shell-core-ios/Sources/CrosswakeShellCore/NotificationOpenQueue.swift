import Foundation

/// File-backed, discardable evidence for notification taps received while the
/// host cannot evaluate current authority. It is intentionally not an outbox:
/// it cannot resolve targets or activate routes on its own.
public actor NotificationOpenQueue {
    private struct StoredItem: Codable, Equatable {
        let id: UUID
        let evidence: NotificationOpenEvidence
        let enqueuedAt: Date
        let state: State

        enum State: String, Codable { case pending }

        enum CodingKeys: String, CodingKey {
            case id
            case evidence
            case enqueuedAt = "enqueued_at"
            case state
        }
    }

    private struct PersistedQueue: Codable {
        let version: Int
        let items: [StoredItem]
    }

    private static let filename = "notification-open-queue-v1.json"
    private static let currentVersion = 1

    private let fileURL: URL
    private let maximumCount: Int
    private let maximumAge: TimeInterval
    private let now: @Sendable () -> Date
    private var items: [StoredItem]

    public init(
        directory: URL,
        maximumCount: Int = 32,
        maximumAge: TimeInterval = 86_400,
        now: @escaping @Sendable () -> Date = { Date() }
    ) throws {
        precondition(maximumCount > 0, "maximumCount must be positive")
        precondition(maximumAge > 0, "maximumAge must be positive")

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.fileURL = directory.appendingPathComponent(Self.filename, isDirectory: false)
        self.maximumCount = maximumCount
        self.maximumAge = maximumAge
        self.now = now
        self.items = Self.load(from: fileURL)
    }

    public func enqueue(_ evidence: NotificationOpenEvidence) throws {
        let changed = pruneAndCompactPendingItems()
        if items.contains(where: { $0.evidence.openRef == evidence.openRef }) {
            if changed { try persist() }
            return
        }

        items.append(StoredItem(id: UUID(), evidence: evidence, enqueuedAt: now(), state: .pending))
        trimToCount()
        try persist()
    }

    public func pendingEvidence() throws -> [NotificationOpenEvidence] {
        let changed = pruneAndCompactPendingItems()
        if changed { try persist() }
        return items.map(\.evidence)
    }

    /// Submits each currently surviving item once. Terminal host outcomes are
    /// deleted; only an explicit retryable transport failure remains queued.
    /// The callback is the sole bridge to activation and receives only an
    /// allowed, transient host request.
    public func drain(
        using delegate: NotificationOpenDelegate,
        onAllowed: @MainActor @escaping (NotificationOpenAllowedActivation) -> Void
    ) async throws {
        let changed = pruneAndCompactPendingItems()
        if changed { try persist() }

        for item in items {
            switch await delegate.consume(item.evidence) {
            case let .allowed(activation):
                await onAllowed(activation)
                try remove(item)
            case .denied:
                try remove(item)
            case .retryableTransportFailure:
                continue
            }
        }
    }

    /// The production reconnect path: a host result may reach the shell only
    /// through the dedicated protected notification activation entry.
    public func drain(
        using delegate: NotificationOpenDelegate,
        activationCoordinator: ActivationCoordinator
    ) async throws {
        let changed = pruneAndCompactPendingItems()
        if changed { try persist() }

        for item in items {
            let outcome = await delegate.consume(item.evidence)
            await activationCoordinator.handleProtectedNotificationOutcome(outcome)

            switch outcome {
            case .allowed, .denied:
                try remove(item)
            case .retryableTransportFailure:
                continue
            }
        }
    }

    private static func load(from fileURL: URL) -> [StoredItem] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode(PersistedQueue.self, from: data)
            guard decoded.version == currentVersion else { throw CocoaError(.coderInvalidValue) }
            return decoded.items
        } catch {
            // Corrupt evidence is never surfaced or retried; discard it closed.
            try? FileManager.default.removeItem(at: fileURL)
            return []
        }
    }

    @discardableResult
    private func pruneExpired() -> Bool {
        let cutoff = now().addingTimeInterval(-maximumAge)
        let retained = items.filter { $0.enqueuedAt >= cutoff }
        let changed = retained.count != items.count
        items = retained
        return changed
    }

    /// Retains the earliest pending evidence for each one-time open reference.
    /// This compacts records written by prior versions before they can consume
    /// host authority, while preserving FIFO order and original enqueue age.
    @discardableResult
    private func pruneAndCompactPendingItems() -> Bool {
        let pruned = pruneExpired()
        var openRefs = Set<String>()
        let compacted = items.filter { openRefs.insert($0.evidence.openRef).inserted }
        let deduplicated = compacted.count != items.count
        items = compacted
        return pruned || deduplicated
    }

    private func trimToCount() {
        if items.count > maximumCount {
            items.removeFirst(items.count - maximumCount)
        }
    }

    private func remove(_ item: StoredItem) throws {
        items.removeAll { $0.id == item.id }
        try persist()
    }

    private func persist() throws {
        let data = try JSONEncoder().encode(PersistedQueue(version: Self.currentVersion, items: items))
        let temporaryURL = fileURL.appendingPathExtension("tmp")
        try data.write(to: temporaryURL, options: .atomic)

        if FileManager.default.fileExists(atPath: fileURL.path) {
            _ = try FileManager.default.replaceItemAt(fileURL, withItemAt: temporaryURL)
        } else {
            try FileManager.default.moveItem(at: temporaryURL, to: fileURL)
        }
    }
}
