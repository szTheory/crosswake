import Foundation
import SwiftUI

public enum PackState: String, Codable, CaseIterable, Sendable {
    case checking = "checking"
    case notInstalled = "not_installed"
    case installing = "installing"
    case available = "available"
    case stale = "stale"
    case invalidating = "invalidating"
    case failed = "failed"
}

public enum InstallStage: String, Codable, Sendable {
    case preparing = "Preparing"
    case downloading = "Downloading"
    case verifying = "Verifying"
    case installing = "Installing"
}

/// Retained only for source compatibility with hosts that previously decoded bundled inventory.
/// PackStore never treats this legacy shape as availability authority.
public struct PackInventoryRecord: Codable {
    public let packID: String
    public let requiredVersion: String
    public let installedVersion: String
    public let bytes: Int
    public let integrityStatus: String
    public let verifiedAt: Date?
    public let status: String

    enum CodingKeys: String, CodingKey {
        case packID = "pack_id"
        case requiredVersion = "required_version"
        case installedVersion = "installed_version"
        case bytes
        case integrityStatus = "integrity_status"
        case verifiedAt = "verified_at"
        case status
    }
}

public struct RequiredPackStatus: Equatable, Identifiable {
    public let id: String
    public let packID: String
    public let requiredVersion: String
    public var state: PackState
    public var installedVersion: String?
    public var bytes: Int?
    public var verifiedAt: Date?
    public var integrityStatus: String?
    public var installStage: InstallStage?
    public var failureReason: PackFailureReason?
    public var lastKnownVersion: String?
}

@MainActor
public final class PackStore: ObservableObject {
    @Published public private(set) var statuses: [String: RequiredPackStatus]

    private let requirements: [String: PackRequirement]
    private let provider: (any PackProvider)?
    private static let revocationKey = "crosswake.pack-revocations.v1"
    private var revokedPackIDs: Set<String>

    public init(requirements: [PackRequirement], provider: (any PackProvider)? = nil) {
        self.requirements = Dictionary(uniqueKeysWithValues: requirements.map { ($0.packID, $0) })
        self.provider = provider
        let persistedRevocations = Set(UserDefaults.standard.stringArray(forKey: Self.revocationKey) ?? [])
        self.revokedPackIDs = persistedRevocations
        self.statuses = Dictionary(uniqueKeysWithValues: requirements.map {
            ($0.packID, persistedRevocations.contains($0.packID)
                ? Self.failedStatusStatic(for: $0, reason: .invalidationFailed)
                : provider == nil
                ? Self.closedUnavailableStatus(for: $0)
                : Self.checkingStatus(for: $0))
        })
    }

    /// Source-compatible initializer. Legacy inventory is intentionally ignored: it is not a
    /// provider attestation and must never grant route activation.
    public convenience init(requiredVersions: [String: String], inventory: [PackInventoryRecord], now: @escaping () -> Date = Date.init) {
        let declarations = requiredVersions.map {
            PackRequirement(packID: $0.key, requiredVersion: $0.value, expectedByteCount: 0, expectedSHA256: "")
        }
        self.init(requirements: declarations, provider: nil)
    }

    public static func bundled(bundle: Bundle = .main, provider: (any PackProvider)? = nil) throws -> PackStore {
        let declaration: BundledPackRequirementDeclaration = try decode("declared_pack_requirements", bundle: bundle)
        return PackStore(requirements: try declaration.requirements.map { try $0.validatedRequirement() }, provider: provider)
    }

    public func blockingStatus(for packReferences: [String]) -> RequiredPackStatus? {
        packReferences
            .compactMap(parse(packReference:))
            .compactMap { statuses[$0.packID] ?? fallbackStatus(packID: $0.packID, requiredVersion: $0.requiredVersion) }
            .first(where: { $0.state != .available })
    }

    public func reconcileAll() async {
        for requirement in requirements.values {
            await reconcile(requirement)
        }
    }

    public func installRequiredPack(_ status: RequiredPackStatus) async {
        guard let requirement = requirements[status.packID] else { return }
        statuses[requirement.packID] = updated(status, state: .installing, stage: .preparing, failureReason: nil)
        guard let provider else {
            statuses[requirement.packID] = updated(status, state: .failed, stage: nil, failureReason: .providerUnavailable)
            return
        }
        _ = await provider.install(requirement)
        await reconcile(requirement)
    }

    public func retry(_ status: RequiredPackStatus) async {
        await installRequiredPack(status)
    }

    public func invalidatePack(_ status: RequiredPackStatus) async {
        guard let requirement = requirements[status.packID] else { return }
        revoke(requirement.packID)
        statuses[requirement.packID] = updated(status, state: .invalidating, stage: nil, failureReason: nil)
        guard let provider else {
            statuses[requirement.packID] = updated(status, state: .failed, stage: nil, failureReason: .providerUnavailable)
            return
        }
        guard case .notInstalled = await provider.invalidate(requirement),
              case .notInstalled = await provider.status(for: requirement) else {
            statuses[requirement.packID] = failedStatus(for: requirement, reason: .invalidationFailed)
            return
        }
        clearRevocation(requirement.packID)
        statuses[requirement.packID] = unavailableStatus(for: requirement)
    }

    private func reconcile(_ requirement: PackRequirement) async {
        guard let provider else {
            statuses[requirement.packID] = failedStatus(for: requirement, reason: .providerUnavailable)
            return
        }

        let result = await provider.status(for: requirement)
        if revokedPackIDs.contains(requirement.packID) {
            let reconciled = status(for: result, requirement: requirement)
            if reconciled.state == .available {
                clearRevocation(requirement.packID)
            } else {
                statuses[requirement.packID] = failedStatus(for: requirement, reason: .invalidationFailed)
                return
            }
        }
        statuses[requirement.packID] = status(for: result, requirement: requirement)
    }

    private func status(for result: PackProviderResult, requirement: PackRequirement) -> RequiredPackStatus {
        switch result {
        case .installed(let record):
            guard record.contractVersion == PackProviderContract.currentVersion,
                  record.contractVersion == requirement.contractVersion,
                  record.packID == requirement.packID,
                  record.byteCount == requirement.expectedByteCount,
                  record.integrityVerified,
                  record.atomicPromotionCompleted
            else {
                return failedStatus(for: requirement, reason: .malformedProviderResult)
            }
            guard record.installedVersion == requirement.requiredVersion else {
                return staleStatus(for: requirement, record: record)
            }
            return RequiredPackStatus(id: requirement.packID, packID: requirement.packID, requiredVersion: requirement.requiredVersion, state: .available, installedVersion: record.installedVersion, bytes: record.byteCount, verifiedAt: nil, integrityStatus: "verified", installStage: nil, failureReason: nil, lastKnownVersion: record.installedVersion)
        case .notInstalled:
            return unavailableStatus(for: requirement)
        case .failure(let reason):
            return failedStatus(for: requirement, reason: reason)
        case .cancelled:
            return failedStatus(for: requirement, reason: .transferInterrupted)
        case .malformed:
            return failedStatus(for: requirement, reason: .malformedProviderResult)
        }
    }

    private static func checkingStatus(for requirement: PackRequirement) -> RequiredPackStatus {
        RequiredPackStatus(id: requirement.packID, packID: requirement.packID, requiredVersion: requirement.requiredVersion, state: .checking, installedVersion: nil, bytes: nil, verifiedAt: nil, integrityStatus: nil, installStage: nil, failureReason: nil, lastKnownVersion: nil)
    }

    private static func closedUnavailableStatus(for requirement: PackRequirement) -> RequiredPackStatus {
        RequiredPackStatus(id: requirement.packID, packID: requirement.packID, requiredVersion: requirement.requiredVersion, state: .failed, installedVersion: nil, bytes: nil, verifiedAt: nil, integrityStatus: nil, installStage: nil, failureReason: .providerUnavailable, lastKnownVersion: nil)
    }

    private static func failedStatusStatic(for requirement: PackRequirement, reason: PackFailureReason) -> RequiredPackStatus {
        RequiredPackStatus(id: requirement.packID, packID: requirement.packID, requiredVersion: requirement.requiredVersion, state: .failed, installedVersion: nil, bytes: nil, verifiedAt: nil, integrityStatus: nil, installStage: nil, failureReason: reason, lastKnownVersion: nil)
    }

    private func revoke(_ packID: String) {
        revokedPackIDs.insert(packID)
        UserDefaults.standard.set(Array(revokedPackIDs), forKey: Self.revocationKey)
    }

    private func clearRevocation(_ packID: String) {
        revokedPackIDs.remove(packID)
        UserDefaults.standard.set(Array(revokedPackIDs), forKey: Self.revocationKey)
    }

    private func unavailableStatus(for requirement: PackRequirement) -> RequiredPackStatus {
        RequiredPackStatus(id: requirement.packID, packID: requirement.packID, requiredVersion: requirement.requiredVersion, state: .notInstalled, installedVersion: nil, bytes: nil, verifiedAt: nil, integrityStatus: nil, installStage: nil, failureReason: nil, lastKnownVersion: statuses[requirement.packID]?.lastKnownVersion)
    }

    private func failedStatus(for requirement: PackRequirement, reason: PackFailureReason) -> RequiredPackStatus {
        RequiredPackStatus(id: requirement.packID, packID: requirement.packID, requiredVersion: requirement.requiredVersion, state: .failed, installedVersion: nil, bytes: nil, verifiedAt: nil, integrityStatus: nil, installStage: nil, failureReason: reason, lastKnownVersion: statuses[requirement.packID]?.lastKnownVersion)
    }

    private func staleStatus(for requirement: PackRequirement, record: PackInstalledRecord) -> RequiredPackStatus {
        RequiredPackStatus(id: requirement.packID, packID: requirement.packID, requiredVersion: requirement.requiredVersion, state: .stale, installedVersion: record.installedVersion, bytes: record.byteCount, verifiedAt: nil, integrityStatus: "verified", installStage: nil, failureReason: nil, lastKnownVersion: record.installedVersion)
    }

    private func fallbackStatus(packID: String, requiredVersion: String) -> RequiredPackStatus {
        RequiredPackStatus(id: packID, packID: packID, requiredVersion: requiredVersion, state: .failed, installedVersion: nil, bytes: nil, verifiedAt: nil, integrityStatus: nil, installStage: nil, failureReason: .providerUnavailable, lastKnownVersion: nil)
    }

    private func parse(packReference: String) -> (packID: String, requiredVersion: String)? {
        let components = packReference.split(separator: "@", maxSplits: 1).map(String.init)
        guard components.count == 2 else { return nil }
        return (components[0], components[1])
    }

    private func updated(_ status: RequiredPackStatus, state: PackState, stage: InstallStage?, failureReason: PackFailureReason?) -> RequiredPackStatus {
        RequiredPackStatus(id: status.id, packID: status.packID, requiredVersion: status.requiredVersion, state: state, installedVersion: status.installedVersion, bytes: status.bytes, verifiedAt: status.verifiedAt, integrityStatus: status.integrityStatus, installStage: stage, failureReason: failureReason, lastKnownVersion: status.installedVersion ?? status.lastKnownVersion)
    }

    private static func decode<T: Decodable>(_ name: String, bundle: Bundle) throws -> T {
        guard let url = bundle.url(forResource: name, withExtension: "json") else { throw CocoaError(.fileNoSuchFile) }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: Data(contentsOf: url))
    }
}

private struct BundledPackRequirementDeclaration: Decodable {
    let requirements: [Requirement]

    struct Requirement: Decodable {
        let contractVersion: PackProviderContractVersion
        let packID: String
        let requiredVersion: String
        let expectedByteCount: Int
        let expectedSHA256: String

        enum CodingKeys: String, CodingKey {
            case contractVersion = "contract_version"
            case packID = "pack_id"
            case requiredVersion = "required_version"
            case expectedByteCount = "expected_byte_count"
            case expectedSHA256 = "expected_sha256"
        }

        func validatedRequirement() throws -> PackRequirement {
            guard contractVersion == PackProviderContract.currentVersion,
                  (1...128).contains(packID.count),
                  (1...128).contains(requiredVersion.count),
                  expectedByteCount > 0,
                  expectedSHA256.count == 64,
                  expectedSHA256.allSatisfy({ $0.isNumber || ("a"..."f").contains($0) })
            else {
                throw CocoaError(.coderInvalidValue)
            }

            return PackRequirement(
                contractVersion: contractVersion,
                packID: packID,
                requiredVersion: requiredVersion,
                expectedByteCount: expectedByteCount,
                expectedSHA256: expectedSHA256
            )
        }
    }

    private enum CodingKeys: String, CodingKey { case requirements }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        requirements = try container.decode([Requirement].self, forKey: .requirements)
        guard !requirements.isEmpty,
              Set(requirements.map(\.packID)).count == requirements.count
        else {
            throw CocoaError(.coderInvalidValue)
        }
    }
}
