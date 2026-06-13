import Foundation
import SwiftUI

public enum PackState: String, Codable, CaseIterable {
    case checking = "checking"
    case notInstalled = "not_installed"
    case installing = "installing"
    case available = "available"
    case stale = "stale"
    case invalidating = "invalidating"
    case failed = "failed"
}

public enum InstallStage: String, Codable {
    case preparing = "Preparing"
    case downloading = "Downloading"
    case verifying = "Verifying"
    case installing = "Installing"
}

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
    public var failureReason: String?
    public var lastKnownVersion: String?
}

@MainActor
public final class PackStore: ObservableObject {
    @Published public private(set) var statuses: [String: RequiredPackStatus]

    private let requiredVersions: [String: String]
    private let now: () -> Date

    public init(requiredVersions: [String: String], inventory: [PackInventoryRecord], now: @escaping () -> Date = Date.init) {
        self.requiredVersions = requiredVersions
        self.now = now
        self.statuses = PackStore.seedStatuses(requiredVersions: requiredVersions, inventory: inventory)
    }

    public static func bundled(bundle: Bundle = .main) throws -> PackStore {
        let requiredVersions: [String: String] = try decode("declared_pack_requirements", bundle: bundle)
        let inventory: [PackInventoryRecord] = try decode("pack_inventory", bundle: bundle)
        return PackStore(requiredVersions: requiredVersions, inventory: inventory)
    }

    public func blockingStatus(for packReferences: [String]) -> RequiredPackStatus? {
        packReferences
            .compactMap(parse(packReference:))
            .compactMap { statuses[$0.packID] ?? fallbackStatus(packID: $0.packID, requiredVersion: $0.requiredVersion) }
            .first(where: { $0.state != .available })
    }

    public func installRequiredPack(_ status: RequiredPackStatus) async {
        await transition(status, through: [.preparing, .downloading, .verifying, .installing])

        statuses[status.packID] = RequiredPackStatus(
            id: status.packID,
            packID: status.packID,
            requiredVersion: status.requiredVersion,
            state: .available,
            installedVersion: status.requiredVersion,
            bytes: status.bytes ?? 24576,
            verifiedAt: now(),
            integrityStatus: "verified",
            installStage: nil,
            failureReason: nil,
            lastKnownVersion: status.installedVersion ?? status.lastKnownVersion
        )
    }

    public func retry(_ status: RequiredPackStatus) async {
        await installRequiredPack(status)
    }

    public func invalidatePack(_ status: RequiredPackStatus) async {
        statuses[status.packID] = updated(status, state: .invalidating, stage: nil, failureReason: nil)
        try? await Task.sleep(nanoseconds: 150_000_000)

        statuses[status.packID] = RequiredPackStatus(
            id: status.packID,
            packID: status.packID,
            requiredVersion: status.requiredVersion,
            state: .notInstalled,
            installedVersion: nil,
            bytes: status.bytes,
            verifiedAt: nil,
            integrityStatus: nil,
            installStage: nil,
            failureReason: nil,
            lastKnownVersion: status.installedVersion ?? status.lastKnownVersion
        )
    }

    private func transition(_ status: RequiredPackStatus, through stages: [InstallStage]) async {
        var current = status
        current.state = .installing

        for stage in stages {
            current.installStage = stage
            current.failureReason = nil
            statuses[status.packID] = current
            try? await Task.sleep(nanoseconds: 150_000_000)
        }
    }

    private func fallbackStatus(packID: String, requiredVersion: String) -> RequiredPackStatus {
        RequiredPackStatus(
            id: packID,
            packID: packID,
            requiredVersion: requiredVersion,
            state: .notInstalled,
            installedVersion: nil,
            bytes: nil,
            verifiedAt: nil,
            integrityStatus: nil,
            installStage: nil,
            failureReason: nil,
            lastKnownVersion: nil
        )
    }

    private func parse(packReference: String) -> (packID: String, requiredVersion: String)? {
        let components = packReference.split(separator: "@", maxSplits: 1).map(String.init)
        guard components.count == 2 else { return nil }
        return (components[0], components[1])
    }

    private func updated(_ status: RequiredPackStatus, state: PackState, stage: InstallStage?, failureReason: String?) -> RequiredPackStatus {
        RequiredPackStatus(
            id: status.id,
            packID: status.packID,
            requiredVersion: status.requiredVersion,
            state: state,
            installedVersion: status.installedVersion,
            bytes: status.bytes,
            verifiedAt: status.verifiedAt,
            integrityStatus: status.integrityStatus,
            installStage: stage,
            failureReason: failureReason,
            lastKnownVersion: status.installedVersion ?? status.lastKnownVersion
        )
    }

    private static func seedStatuses(requiredVersions: [String: String], inventory: [PackInventoryRecord]) -> [String: RequiredPackStatus] {
        let byPack = Dictionary(uniqueKeysWithValues: inventory.map { ($0.packID, $0) })

        return requiredVersions.reduce(into: [:]) { result, entry in
            let (packID, requiredVersion) = entry
            let record = byPack[packID]
            result[packID] = buildStatus(packID: packID, requiredVersion: requiredVersion, record: record)
        }
    }

    private static func buildStatus(packID: String, requiredVersion: String, record: PackInventoryRecord?) -> RequiredPackStatus {
        guard let record else {
            return RequiredPackStatus(
                id: packID,
                packID: packID,
                requiredVersion: requiredVersion,
                state: .notInstalled,
                installedVersion: nil,
                bytes: nil,
                verifiedAt: nil,
                integrityStatus: nil,
                installStage: nil,
                failureReason: nil,
                lastKnownVersion: nil
            )
        }

        let state: PackState
        let failureReason: String?

        if record.status == "invalidating" {
            state = .invalidating
            failureReason = nil
        } else if record.integrityStatus != "verified" || record.verifiedAt == nil {
            state = .failed
            failureReason = "verification_missing"
        } else if record.installedVersion != requiredVersion {
            state = .stale
            failureReason = nil
        } else {
            state = .available
            failureReason = nil
        }

        return RequiredPackStatus(
            id: packID,
            packID: packID,
            requiredVersion: requiredVersion,
            state: state,
            installedVersion: record.installedVersion,
            bytes: record.bytes,
            verifiedAt: record.verifiedAt,
            integrityStatus: record.integrityStatus,
            installStage: nil,
            failureReason: failureReason,
            lastKnownVersion: record.installedVersion
        )
    }

    private static func decode<T: Decodable>(_ name: String, bundle: Bundle) throws -> T {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: Data(contentsOf: url))
    }
}
