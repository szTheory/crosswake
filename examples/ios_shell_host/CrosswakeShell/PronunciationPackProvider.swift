import CryptoKit
import Foundation
import CrosswakeShellCore

/// The example host owns byte acquisition, private storage, and inventory. Core sees only the
/// requirement-bound, closed PackProvider contract.
actor PronunciationPackProvider: PackProvider {
    typealias Source = @Sendable () throws -> Data

    private let source: Source
    private let storageRoot: URL
    private let fileManager: FileManager

    init(source: @escaping Source, storageRoot: URL, fileManager: FileManager = .default) {
        self.source = source
        self.storageRoot = storageRoot
        self.fileManager = fileManager
    }

    func status(for requirement: PackRequirement) async -> PackProviderResult {
        guard let record = loadInventory()[requirement.packID] else { return .notInstalled }
        return .installed(record)
    }

    func install(_ requirement: PackRequirement) async -> PackProviderResult {
        let staging = storageRoot.appendingPathComponent(".staging-\(UUID().uuidString)")
        defer { try? fileManager.removeItem(at: staging) }

        do {
            try fileManager.createDirectory(at: storageRoot, withIntermediateDirectories: true)
            let bytes = try source()
            try bytes.write(to: staging, options: .atomic)
            let digest = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
            guard bytes.count == requirement.expectedByteCount else { return .failure(.sizeMismatch) }
            guard digest == requirement.expectedSHA256 else { return .failure(.digestMismatch) }

            let destination = artifactURL(for: requirement)
            if fileManager.fileExists(atPath: destination.path) {
                _ = try fileManager.replaceItemAt(destination, withItemAt: staging)
            } else {
                try fileManager.moveItem(at: staging, to: destination)
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
            try saveInventory(inventory)
            return .installed(record)
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
        try data.write(to: inventoryURL, options: .atomic)
    }
}
