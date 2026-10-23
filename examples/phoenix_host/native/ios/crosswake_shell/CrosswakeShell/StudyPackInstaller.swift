import Foundation
import CryptoKit
import CrosswakeShellCore

/// Closed failure causes for the installed study media. The raw values are the wire reasons
/// the audio delegate returns and the causes the observation log accepts.
enum StudyMediaFailure: String, Error, Equatable {
    case mediaMissing = "media_missing"
    case mediaCorrupt = "media_corrupt"
    case installFailed = "install_failed"
}

struct StudyVerifiedMedia: Equatable, Sendable {
    let data: Data
    let sha256: String
}

protocol StudyVerifiedMediaSource: Sendable {
    /// Re-hashes the installed bytes and returns them only when size and digest match.
    func installedVerifiedData() async throws -> StudyVerifiedMedia
}

/// Foreground installer for the one public reference pronunciation fixture.
///
/// It fetches from the run-owned endpoint on the activation's primary origin, verifies the
/// exact byte size and SHA-256, writes to a temporary file and atomically replaces the
/// installed file, then reads the installed bytes back. There is no bundled copy, no remote
/// fallback and no archive framework. An interrupted install leaves the previous installed
/// bytes or none, never partial bytes. As an actor it hashes off the main actor.
actor StudyPackInstaller: StudyVerifiedMediaSource {
    // Expectations copied once from 180-IDENTITY.json media.size and media.sha256. They are
    // expectations, not observations.
    static let expectedSize = 33706
    static let expectedSHA256 = "5d8b3f72beb26205032d764bc7979f5658c7c9f262427bce2d814f2bf0fabf5b"
    static let endpointPath = "/_e2e/twin/media/pronunciation"
    static let installedFileName = "pronunciation.aiff"

    static var defaultDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CrosswakeTwin", isDirectory: true)
    }

    private let origin: URL
    private let session: URLSession
    private let directory: URL
    private let expectedSize: Int
    private let expectedSHA256: String
    private let log: TwinObservationLog

    init(
        origin: URL,
        session: URLSession = .shared,
        directory: URL = StudyPackInstaller.defaultDirectory,
        expectedSize: Int = StudyPackInstaller.expectedSize,
        expectedSHA256: String = StudyPackInstaller.expectedSHA256,
        log: TwinObservationLog = .shared
    ) {
        self.origin = origin
        self.session = session
        self.directory = directory
        self.expectedSize = expectedSize
        self.expectedSHA256 = expectedSHA256
        self.log = log
    }

    private var installedURL: URL { directory.appendingPathComponent(Self.installedFileName) }

    static func hexDigest(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private func note(_ kind: String, _ verdict: String, cause: String? = nil) {
        log.append(channel: .hostAdapter, kind: kind, value: .word(verdict), cause: cause)
    }

    /// Installs only when nothing verified is installed yet. Errors are recorded, not thrown.
    func installIfNeeded() async {
        if (try? await installedVerifiedData()) != nil { return }
        _ = try? await install()
    }

    func install() async throws -> StudyVerifiedMedia {
        guard let url = URL(string: Self.endpointPath, relativeTo: origin)?.absoluteURL else {
            note("TW-T01-01", "failed", cause: "install_failed")
            throw StudyMediaFailure.installFailed
        }

        let body: Data
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse else {
                note("TW-T01-01", "failed", cause: "install_failed")
                throw StudyMediaFailure.installFailed
            }
            if http.statusCode == 404 {
                note("TW-T01-01", "failed", cause: "media_missing")
                throw StudyMediaFailure.mediaMissing
            }
            guard http.statusCode == 200 else {
                note("TW-T01-01", "failed", cause: "install_failed")
                throw StudyMediaFailure.installFailed
            }
            body = data
        } catch let failure as StudyMediaFailure {
            throw failure
        } catch {
            note("TW-T01-01", "failed", cause: "install_failed")
            throw StudyMediaFailure.installFailed
        }
        note("TW-T01-01", "passed")

        guard body.count == expectedSize, Self.hexDigest(body) == expectedSHA256 else {
            note("TW-T01-02", "failed", cause: "media_corrupt")
            note("TW-T04-05", "passed", cause: "media_corrupt")
            throw StudyMediaFailure.mediaCorrupt
        }
        note("TW-T01-02", "passed")

        let temporary = directory.appendingPathComponent("\(Self.installedFileName).tmp-\(UUID().uuidString)")
        do {
            try prepareDirectory()
            try body.write(to: temporary, options: [.atomic])
            if FileManager.default.fileExists(atPath: installedURL.path) {
                _ = try FileManager.default.replaceItemAt(installedURL, withItemAt: temporary)
            } else {
                try FileManager.default.moveItem(at: temporary, to: installedURL)
            }
        } catch {
            try? FileManager.default.removeItem(at: temporary)
            note("TW-T01-03", "failed", cause: "install_failed")
            throw StudyMediaFailure.installFailed
        }
        note("TW-T01-03", "passed")

        let verified: StudyVerifiedMedia
        do {
            verified = try readBackVerified()
        } catch {
            note("TW-T01-04", "failed", cause: "media_corrupt")
            throw StudyMediaFailure.mediaCorrupt
        }
        note("TW-T01-04", "passed")
        return verified
    }

    func installedVerifiedData() async throws -> StudyVerifiedMedia {
        guard FileManager.default.fileExists(atPath: installedURL.path) else {
            throw StudyMediaFailure.mediaMissing
        }
        return try readBackVerified()
    }

    private func readBackVerified() throws -> StudyVerifiedMedia {
        guard let data = try? Data(contentsOf: installedURL) else { throw StudyMediaFailure.mediaMissing }
        let digest = Self.hexDigest(data)
        guard data.count == expectedSize, digest == expectedSHA256 else { throw StudyMediaFailure.mediaCorrupt }
        return StudyVerifiedMedia(data: data, sha256: digest)
    }

    private func prepareDirectory() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutable = directory
        try mutable.setResourceValues(values)
    }
}

/// Adapts the installer to the shell's pack provider seam. The study route declares no pack,
/// so this only answers for the one study media key and refuses to invalidate: the host has
/// no reset or reinstall path (D-09).
struct StudyPackProvider: PackProvider {
    static let packID = "study.pronunciation"
    let installer: StudyPackInstaller

    func status(for requirement: PackRequirement) async -> PackProviderResult {
        guard requirement.packID == Self.packID else { return .notInstalled }
        guard let verified = try? await installer.installedVerifiedData() else { return .notInstalled }
        return .installed(record(for: requirement, byteCount: verified.data.count))
    }

    func install(_ requirement: PackRequirement) async -> PackProviderResult {
        guard requirement.packID == Self.packID else { return .failure(.providerUnavailable) }
        do {
            let verified = try await installer.install()
            return .installed(record(for: requirement, byteCount: verified.data.count))
        } catch let failure as StudyMediaFailure {
            return .failure(failure == .mediaCorrupt ? .digestMismatch : .providerFailed)
        } catch {
            return .failure(.providerFailed)
        }
    }

    func invalidate(_ requirement: PackRequirement) async -> PackProviderResult {
        .failure(.invalidationFailed)
    }

    private func record(for requirement: PackRequirement, byteCount: Int) -> PackInstalledRecord {
        PackInstalledRecord(
            contractVersion: requirement.contractVersion,
            packID: requirement.packID,
            installedVersion: requirement.requiredVersion,
            byteCount: byteCount,
            integrityVerified: true,
            atomicPromotionCompleted: true
        )
    }
}
