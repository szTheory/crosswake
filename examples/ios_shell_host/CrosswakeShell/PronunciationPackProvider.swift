import CryptoKit
import Darwin
import Foundation
import CrosswakeShellCore

/// Host-private, non-sensitive transaction metadata for a replacement that was interrupted
/// between retaining a known-good artifact and removing the transaction debris.
struct ReplacementJournal: Codable, Sendable {
    enum Phase: String, Codable, Sendable {
        case retentionPending
        case promotionPending
        case inventoryCommitPending
        case committedCleanupPending
    }

    let schemaVersion: Int
    let phase: Phase
    let packID: String
    let nonce: String
    let stagingLeaf: String
    let destinationLeaf: String
    let retainedLeaf: String
    let priorRecord: PackInstalledRecord?
    let currentRecord: PackInstalledRecord
}

/// Internal filesystem identity boundary. It deliberately never escapes the example host.
typealias PublicationFilesystemIdentity = @Sendable (URL) throws -> String

struct PublicationOperations: Sendable {
    let atomicWrite: @Sendable (Data, URL) throws -> Void
    let move: @Sendable (URL, URL) throws -> Void
    let remove: @Sendable (URL) throws -> Void
    let synchronizeFile: @Sendable (URL) throws -> Void
    let synchronizeDirectory: @Sendable (URL) throws -> Void
}

/// The example host owns byte acquisition, private storage, and inventory. Core sees only the
/// requirement-bound, closed PackProvider contract.
actor PronunciationPackProvider: PackProvider {
    typealias Source = @Sendable () throws -> Data
    typealias ArtifactVerifier = @Sendable (URL, Int) async throws -> (byteCount: Int, sha256: String)
    typealias InventoryWriter = @Sendable (Data, URL) throws -> Void
    typealias StartupRecovery = @Sendable () async throws -> Void
    private typealias PublicationMover = @Sendable (URL, URL) throws -> Void

    private let source: Source
    private let storageRoot: URL
    private let fileManager: FileManager
    private let verificationChunkSize: Int
    private let artifactVerifier: ArtifactVerifier
    private let inventoryWriter: InventoryWriter
    private let publicationMover: PublicationMover
    private let publicationOperations: PublicationOperations
    private let filesystemIdentity: PublicationFilesystemIdentity
    private let startupRecovery: Task<Void, Error>

    init(
        source: @escaping Source,
        storageRoot: URL,
        fileManager: FileManager = .default,
        verificationChunkSize: Int = 64 * 1024,
        artifactVerifier: ArtifactVerifier? = nil,
        inventoryWriter: InventoryWriter? = nil,
        publicationMover: (@Sendable (URL, URL) throws -> Void)? = nil,
        filesystemIdentity: PublicationFilesystemIdentity? = nil,
        publicationOperations: PublicationOperations? = nil,
        startupRecoveryOverride: StartupRecovery? = nil
    ) {
        self.source = source
        self.storageRoot = storageRoot
        self.fileManager = fileManager
        self.verificationChunkSize = max(1, verificationChunkSize)
        self.artifactVerifier = artifactVerifier ?? { url, chunkSize in
            let verification = try await PronunciationPackProvider.verifyStagedFile(url, chunkSize: chunkSize)
            return (verification.byteCount, verification.sha256)
        }
        self.inventoryWriter = inventoryWriter ?? { _, _ in }
        self.publicationMover = publicationMover ?? { source, destination in
            try FileManager.default.moveItem(at: source, to: destination)
        }
        self.publicationOperations = publicationOperations ?? PublicationOperations(
            atomicWrite: { try $0.write(to: $1, options: .atomic) },
            move: publicationMover ?? { try FileManager.default.moveItem(at: $0, to: $1) },
            remove: { try FileManager.default.removeItem(at: $0) },
            synchronizeFile: { url in let handle = try FileHandle(forWritingTo: url); defer { try? handle.close() }; try handle.synchronize() },
            synchronizeDirectory: { url in let fd = open(url.path, O_RDONLY); guard fd >= 0 else { throw POSIXError(.EIO) }; defer { _ = close(fd) }; guard fsync(fd) == 0 else { throw POSIXError(.EIO) } }
        )
        self.filesystemIdentity = filesystemIdentity ?? { url in
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: url.path)
            guard let number = attributes[.systemNumber] else { throw CocoaError(.fileReadUnknown) }
            return String(describing: number)
        }
        let recoveryRoot = storageRoot
        let recoveryManager = fileManager
        let recoveryIdentity = self.filesystemIdentity
        let recoveryOperations = self.publicationOperations
        self.startupRecovery = Task.detached(priority: .utility) {
            if let startupRecoveryOverride { try await startupRecoveryOverride() }
            else { try Self.recoverInterruptedPublication(storageRoot: recoveryRoot, fileManager: recoveryManager, filesystemIdentity: recoveryIdentity, operations: recoveryOperations) }
        }
    }

    func status(for requirement: PackRequirement) async -> PackProviderResult {
        guard await awaitStartupRecovery() else { return .failure(.providerFailed) }
        guard let record = loadInventory()[requirement.packID] else { return .notInstalled }
        guard record.contractVersion == requirement.contractVersion,
              record.packID == requirement.packID
        else { return .failure(.providerFailed) }

        let destination = artifactURL(for: requirement)
        guard fileManager.fileExists(atPath: destination.path) else { return .notInstalled }

        do {
            let verification = try await verifyArtifact(destination)
            guard verification.byteCount == requirement.expectedByteCount else { return .failure(.sizeMismatch) }
            guard verification.sha256 == requirement.expectedSHA256 else { return .failure(.digestMismatch) }
            return .installed(record)
        } catch {
            return .failure(.providerFailed)
        }
    }

    func install(_ requirement: PackRequirement) async -> PackProviderResult {
        guard await awaitStartupRecovery() else { return .failure(.atomicInstallFailed) }
        let transactionNonce = UUID().uuidString
        let staging = storageRoot.appendingPathComponent(".staging-\(transactionNonce)")
        let retainedArtifact = storageRoot.appendingPathComponent(".previous-\(transactionNonce)")
        var publicationState = PublicationState.noPriorArtifact
        defer { try? fileManager.removeItem(at: staging) }
        defer {
            if publicationState != .priorArtifactRetained {
                try? fileManager.removeItem(at: retainedArtifact)
            }
        }

        do {
            try fileManager.createDirectory(at: storageRoot, withIntermediateDirectories: true)
            let bytes = try source()
            try bytes.write(to: staging, options: .atomic)
            let verification = try await verifyArtifact(staging)
            guard verification.byteCount == requirement.expectedByteCount else { return .failure(.sizeMismatch) }
            guard verification.sha256 == requirement.expectedSHA256 else { return .failure(.digestMismatch) }

            let destination = artifactURL(for: requirement)
            let priorInventoryData = try? Data(contentsOf: inventoryURL)
            let hadPriorArtifact = fileManager.fileExists(atPath: destination.path)
            // A journaled prior record is authoritative only when its matching bytes are
            // retained. Inventory alone must never manufacture a last-known-good artifact.
            let priorRecord = hadPriorArtifact ? loadInventory()[requirement.packID] : nil
            let record = PackInstalledRecord(
                contractVersion: requirement.contractVersion,
                packID: requirement.packID,
                installedVersion: requirement.requiredVersion,
                byteCount: requirement.expectedByteCount,
                integrityVerified: true,
                atomicPromotionCompleted: true
            )
            var inventory = loadInventory()
            inventory[requirement.packID] = record
            do {
                let journal = ReplacementJournal(
                    schemaVersion: 1,
                    phase: hadPriorArtifact ? .retentionPending : .promotionPending,
                    packID: requirement.packID,
                    nonce: transactionNonce,
                    stagingLeaf: staging.lastPathComponent,
                    destinationLeaf: destination.lastPathComponent,
                    retainedLeaf: retainedArtifact.lastPathComponent,
                    priorRecord: priorRecord,
                    currentRecord: record
                )
                try persistJournal(journal)
                if hadPriorArtifact {
                    try publicationOperations.move(destination, retainedArtifact)
                    try publicationOperations.synchronizeDirectory(storageRoot)
                    publicationState = .priorArtifactRetained
                    try persistJournal(ReplacementJournal(
                        schemaVersion: journal.schemaVersion, phase: .promotionPending,
                        packID: journal.packID, nonce: journal.nonce, stagingLeaf: journal.stagingLeaf,
                        destinationLeaf: journal.destinationLeaf, retainedLeaf: journal.retainedLeaf,
                        priorRecord: journal.priorRecord, currentRecord: journal.currentRecord
                    ))
                }
                try publicationOperations.move(staging, destination)
                try publicationOperations.synchronizeDirectory(storageRoot)
                publicationState = .replacementPromoted
                try persistJournal(ReplacementJournal(
                    schemaVersion: journal.schemaVersion, phase: .inventoryCommitPending,
                    packID: journal.packID, nonce: journal.nonce, stagingLeaf: journal.stagingLeaf,
                    destinationLeaf: journal.destinationLeaf, retainedLeaf: journal.retainedLeaf,
                    priorRecord: journal.priorRecord, currentRecord: journal.currentRecord
                ))
                try saveInventory(inventory)
                publicationState = .inventoryCommitted
                try persistJournal(ReplacementJournal(
                    schemaVersion: journal.schemaVersion, phase: .committedCleanupPending,
                    packID: journal.packID, nonce: journal.nonce, stagingLeaf: journal.stagingLeaf,
                    destinationLeaf: journal.destinationLeaf, retainedLeaf: journal.retainedLeaf,
                    priorRecord: journal.priorRecord, currentRecord: journal.currentRecord
                ))
                try removeDurablyIfPresent(retainedArtifact)
                try removeDurablyIfPresent(replacementJournalURL)
                return .installed(record)
            } catch {
                let failure: PackFailureReason = publicationState == .replacementPromoted
                    ? .inventoryPersistenceFailed
                    : .atomicInstallFailed
                do {
                    try rollbackPublication(
                        destination: destination,
                        retainedArtifact: hadPriorArtifact ? retainedArtifact : nil,
                        priorInventoryData: priorInventoryData
                    )
                    try? removeDurablyIfPresent(replacementJournalURL)
                    publicationState = .noPriorArtifact
                    return .failure(failure)
                } catch {
                    publicationState = .priorArtifactRetained
                    return .failure(.atomicInstallFailed)
                }
            }
        } catch {
            return .failure(.atomicInstallFailed)
        }
    }

    func invalidate(_ requirement: PackRequirement) async -> PackProviderResult {
        guard await awaitStartupRecovery() else { return .failure(.invalidationFailed) }
        do {
            let destination = artifactURL(for: requirement)
            if fileManager.fileExists(atPath: destination.path) {
                try publicationOperations.remove(destination)
                try publicationOperations.synchronizeDirectory(storageRoot)
            }
            var inventory = loadInventory()
            inventory.removeValue(forKey: requirement.packID)
            try saveInventory(inventory)
            return .notInstalled
        } catch {
            return .failure(.invalidationFailed)
        }
    }

    private func artifactURL(for requirement: PackRequirement) -> URL {
        storageRoot.appendingPathComponent("pack-\(requirement.packID)")
    }

    private var inventoryURL: URL { storageRoot.appendingPathComponent("inventory.json") }
    private var replacementJournalURL: URL { storageRoot.appendingPathComponent("replacement-journal.json") }

    private func loadInventory() -> [String: PackInstalledRecord] {
        guard let data = try? Data(contentsOf: inventoryURL),
              let inventory = try? JSONDecoder().decode([String: PackInstalledRecord].self, from: data)
        else { return [:] }
        return inventory
    }

    private func saveInventory(_ inventory: [String: PackInstalledRecord]) throws {
        let data = try JSONEncoder().encode(inventory)
        try inventoryWriter(data, inventoryURL)
        try publicationOperations.atomicWrite(data, inventoryURL)
        try publicationOperations.synchronizeFile(inventoryURL)
        try publicationOperations.synchronizeDirectory(storageRoot)
    }

    private func persistJournal(_ journal: ReplacementJournal) throws {
        let data = try JSONEncoder().encode(journal)
        try publicationOperations.atomicWrite(data, replacementJournalURL)
        try publicationOperations.synchronizeFile(replacementJournalURL)
        try publicationOperations.synchronizeDirectory(storageRoot)
    }

    private func awaitStartupRecovery() async -> Bool {
        do {
            try await startupRecovery.value
            return true
        } catch {
            return false
        }
    }

    nonisolated private static func recoverInterruptedPublication(storageRoot: URL, fileManager: FileManager, filesystemIdentity: PublicationFilesystemIdentity, operations: PublicationOperations) throws {
        let journalURL = storageRoot.appendingPathComponent("replacement-journal.json")
        guard fileManager.fileExists(atPath: journalURL.path) else { return }
        let journal = try JSONDecoder().decode(ReplacementJournal.self, from: Data(contentsOf: journalURL))
        guard journal.schemaVersion == 1,
              journal.destinationLeaf == "pack-\(journal.packID)",
              safeLeaf(journal.stagingLeaf), safeLeaf(journal.retainedLeaf),
              journal.stagingLeaf.contains(journal.nonce), journal.retainedLeaf.contains(journal.nonce),
              journal.destinationLeaf != journal.stagingLeaf,
              journal.destinationLeaf != journal.retainedLeaf,
              journal.stagingLeaf != journal.retainedLeaf,
              journal.currentRecord.packID == journal.packID,
              journal.priorRecord?.packID == nil || journal.priorRecord?.packID == journal.packID
        else { throw CocoaError(.fileReadCorruptFile) }

        try fileManager.createDirectory(at: storageRoot, withIntermediateDirectories: true)
        let rootAttributes = try fileManager.attributesOfItem(atPath: storageRoot.path)
        guard rootAttributes[.type] as? FileAttributeType == .typeDirectory else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let canonicalRoot = storageRoot.standardizedFileURL
        let rootIdentity = try filesystemIdentity(canonicalRoot)
        let destination = canonicalRoot.appendingPathComponent(journal.destinationLeaf)
        let retained = canonicalRoot.appendingPathComponent(journal.retainedLeaf)
        let staging = canonicalRoot.appendingPathComponent(journal.stagingLeaf)
        for leaf in [destination, retained, staging] where fileManager.fileExists(atPath: leaf.path) {
            let canonicalLeaf = leaf.resolvingSymlinksInPath().standardizedFileURL
            guard canonicalLeaf.deletingLastPathComponent() == canonicalRoot,
                  (try fileManager.attributesOfItem(atPath: leaf.path))[.type] as? FileAttributeType == .typeRegular,
                  try filesystemIdentity(canonicalLeaf) == rootIdentity
            else { throw CocoaError(.fileReadCorruptFile) }
        }
        var inventory = loadInventory(storageRoot: storageRoot)
        switch journal.phase {
        case .committedCleanupPending:
            guard inventory[journal.packID] == journal.currentRecord,
                  fileManager.fileExists(atPath: destination.path)
            else { throw CocoaError(.fileReadCorruptFile) }
            if fileManager.fileExists(atPath: retained.path) { try operations.remove(retained); try operations.synchronizeDirectory(canonicalRoot) }
        case .retentionPending, .promotionPending, .inventoryCommitPending:
            let hasDestination = fileManager.fileExists(atPath: destination.path)
            let hasRetainedArtifact = fileManager.fileExists(atPath: retained.path)
            let isInventoryOnlyPromotionPending = journal.phase == .promotionPending
                && journal.priorRecord != nil
                && inventory[journal.packID] == journal.priorRecord
                && !hasDestination
                && !hasRetainedArtifact
                && fileManager.fileExists(atPath: staging.path)

            if isInventoryOnlyPromotionPending {
                inventory.removeValue(forKey: journal.packID)
                try writeInventory(inventory, storageRoot: canonicalRoot, operations: operations)
                break
            }

            if journal.priorRecord != nil && !hasRetainedArtifact {
                throw CocoaError(.fileReadCorruptFile)
            }
            if fileManager.fileExists(atPath: destination.path) { try operations.remove(destination); try operations.synchronizeDirectory(canonicalRoot) }
            if let priorRecord = journal.priorRecord {
                guard fileManager.fileExists(atPath: retained.path) else { throw CocoaError(.fileReadCorruptFile) }
                try operations.move(retained, destination); try operations.synchronizeDirectory(canonicalRoot)
                inventory[journal.packID] = priorRecord
            } else {
                inventory.removeValue(forKey: journal.packID)
            }
            try writeInventory(inventory, storageRoot: canonicalRoot, operations: operations)
        }
        if fileManager.fileExists(atPath: journalURL.path) { try operations.remove(journalURL); try operations.synchronizeDirectory(canonicalRoot) }
    }

    nonisolated private static func safeLeaf(_ value: String) -> Bool {
        !value.isEmpty && !value.contains("/") && !value.contains("\\") && value != "." && value != ".."
    }

    nonisolated private static func loadInventory(storageRoot: URL) -> [String: PackInstalledRecord] {
        let url = storageRoot.appendingPathComponent("inventory.json")
        guard let data = try? Data(contentsOf: url),
              let inventory = try? JSONDecoder().decode([String: PackInstalledRecord].self, from: data)
        else { return [:] }
        return inventory
    }

    nonisolated private static func writeInventory(_ inventory: [String: PackInstalledRecord], storageRoot: URL, operations: PublicationOperations) throws {
        let url = storageRoot.appendingPathComponent("inventory.json")
        let data = try JSONEncoder().encode(inventory)
        try operations.atomicWrite(data, url)
        try operations.synchronizeFile(url)
        try operations.synchronizeDirectory(storageRoot)
    }

    private func rollbackPublication(destination: URL, retainedArtifact: URL?, priorInventoryData: Data?) throws {
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        if let retainedArtifact {
            try fileManager.moveItem(at: retainedArtifact, to: destination)
        }
        if let priorInventoryData {
            try priorInventoryData.write(to: inventoryURL, options: .atomic)
        } else if fileManager.fileExists(atPath: inventoryURL.path) {
            try fileManager.removeItem(at: inventoryURL)
        }
    }

    private func removeDurablyIfPresent(_ url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else { return }
        try publicationOperations.remove(url)
        try publicationOperations.synchronizeDirectory(storageRoot)
    }

    private enum PublicationState {
        case noPriorArtifact
        case priorArtifactRetained
        case replacementPromoted
        case inventoryCommitted
    }

    private func verifyArtifact(_ url: URL) async throws -> Verification {
        let result = try await artifactVerifier(url, verificationChunkSize)
        return Verification(byteCount: result.byteCount, sha256: result.sha256)
    }

    nonisolated private static func verifyStagedFile(_ url: URL, chunkSize: Int) async throws -> Verification {
        try await Task.detached(priority: .utility) {
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }
            var hasher = SHA256()
            var byteCount = 0
            while let chunk = try handle.read(upToCount: chunkSize), !chunk.isEmpty {
                let (updatedCount, overflow) = byteCount.addingReportingOverflow(chunk.count)
                guard !overflow else { throw CocoaError(.fileReadTooLarge) }
                byteCount = updatedCount
                hasher.update(data: chunk)
            }
            return Verification(byteCount: byteCount, sha256: hasher.finalize().map { String(format: "%02x", $0) }.joined())
        }.value
    }

    private struct Verification: Sendable {
        let byteCount: Int
        let sha256: String
    }
}
