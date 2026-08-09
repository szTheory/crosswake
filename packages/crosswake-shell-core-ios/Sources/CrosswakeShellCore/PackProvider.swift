import Foundation

public enum PackProviderContractVersion: String, Codable, CaseIterable, Sendable {
    case v0
    case v1
}

public enum PackProviderContract {
    public static let currentVersion: PackProviderContractVersion = .v1
}

public struct PackRequirement: Codable, Equatable, Sendable {
    public let contractVersion: PackProviderContractVersion
    public let packID: String
    public let requiredVersion: String
    public let expectedByteCount: Int
    public let expectedSHA256: String

    public init(
        contractVersion: PackProviderContractVersion = PackProviderContract.currentVersion,
        packID: String,
        requiredVersion: String,
        expectedByteCount: Int,
        expectedSHA256: String
    ) {
        self.contractVersion = contractVersion
        self.packID = packID
        self.requiredVersion = requiredVersion
        self.expectedByteCount = expectedByteCount
        self.expectedSHA256 = expectedSHA256
    }
}

public struct PackInstalledRecord: Codable, Equatable, Sendable {
    public let contractVersion: PackProviderContractVersion
    public let packID: String
    public let installedVersion: String
    public let byteCount: Int
    public let integrityVerified: Bool
    public let atomicPromotionCompleted: Bool

    public init(
        contractVersion: PackProviderContractVersion,
        packID: String,
        installedVersion: String,
        byteCount: Int,
        integrityVerified: Bool,
        atomicPromotionCompleted: Bool
    ) {
        self.contractVersion = contractVersion
        self.packID = packID
        self.installedVersion = installedVersion
        self.byteCount = byteCount
        self.integrityVerified = integrityVerified
        self.atomicPromotionCompleted = atomicPromotionCompleted
    }
}

public enum PackFailureReason: String, Codable, CaseIterable, Sendable {
    case providerUnavailable = "provider_unavailable"
    case transferInterrupted = "transfer_interrupted"
    case insufficientStorage = "insufficient_storage"
    case sizeMismatch = "size_mismatch"
    case digestMismatch = "digest_mismatch"
    case versionMismatch = "version_mismatch"
    case atomicInstallFailed = "atomic_install_failed"
    case inventoryPersistenceFailed = "inventory_persistence_failed"
    case invalidationFailed = "invalidation_failed"
    case malformedProviderResult = "malformed_provider_result"
    case providerFailed = "provider_failed"
}

public enum PackProviderResult: Equatable, Sendable {
    case installed(PackInstalledRecord)
    case notInstalled
    case failure(PackFailureReason)
    case cancelled
    case malformed
}

public protocol PackProvider: Sendable {
    func status(for requirement: PackRequirement) async -> PackProviderResult
    func install(_ requirement: PackRequirement) async -> PackProviderResult
    func invalidate(_ requirement: PackRequirement) async -> PackProviderResult
}
