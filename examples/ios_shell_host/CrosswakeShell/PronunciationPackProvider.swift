import CryptoKit
import Foundation
import CrosswakeShellCore

/// The example host owns byte acquisition, private storage, and inventory. Core sees only the
/// requirement-bound, closed PackProvider contract.
actor PronunciationPackProvider: PackProvider {
    typealias Source = @Sendable () throws -> Data
    typealias ArtifactVerifier = @Sendable (URL, Int) async throws -> (byteCount: Int, sha256: String)
    typealias InventoryWriter = @Sendable (Data, URL) throws -> Void
    private typealias PublicationMover = @Sendable (URL, URL) throws -> Void

    private let source: Source
    private let storageRoot: URL
    private let fileManager: FileManager
    private let verificationChunkSize: Int
    private let artifactVerifier: ArtifactVerifier
    private let inventoryWriter: InventoryWriter
    private let publicationMover: PublicationMover

    init(
        source: @escaping Source,
        storageRoot: URL,
        fileManager: FileManager = .default,
        verificationChunkSize: Int = 64 * 1024,
        artifactVerifier: ArtifactVerifier? = nil,
        inventoryWriter: InventoryWriter? = nil,
        publicationMover: (@Sendable (URL, URL) throws -> Void)? = nil
    ) {
        self.source = source
        self.storageRoot = storageRoot
        self.fileManager = fileManager
        self.verificationChunkSize = max(1, verificationChunkSize)
        self.artifactVerifier = artifactVerifier ?? { url, chunkSize in
            let verification = try await PronunciationPackProvider.verifyStagedFile(url, chunkSize: chunkSize)
            return (verification.byteCount, verification.sha256)
        }
        self.inventoryWriter = inventoryWriter ?? { data, url in
            try data.write(to: url, options: .atomic)
        }
        self.publicationMover = publicationMover ?? { source, destination in
            try FileManager.default.moveItem(at: source, to: destination)
        }
    }

    func status(for requirement: PackRequirement) async -> PackProviderResult {
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
        let staging = storageRoot.appendingPathComponent(".staging-\(UUID().uuidString)")
        let retainedArtifact = storageRoot.appendingPathComponent(".previous-\(UUID().uuidString)")
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
            if hadPriorArtifact {
                try publicationMover(destination, retainedArtifact)
                publicationState = .priorArtifactRetained
            }

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
                try publicationMover(staging, destination)
                publicationState = .replacementPromoted
                try saveInventory(inventory)
                publicationState = .inventoryCommitted
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
        do {
            let destination = artifactURL(for: requirement)
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
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

    private func loadInventory() -> [String: PackInstalledRecord] {
        guard let data = try? Data(contentsOf: inventoryURL),
              let inventory = try? JSONDecoder().decode([String: PackInstalledRecord].self, from: data)
        else { return [:] }
        return inventory
    }

    private func saveInventory(_ inventory: [String: PackInstalledRecord]) throws {
        let data = try JSONEncoder().encode(inventory)
        try inventoryWriter(data, inventoryURL)
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
