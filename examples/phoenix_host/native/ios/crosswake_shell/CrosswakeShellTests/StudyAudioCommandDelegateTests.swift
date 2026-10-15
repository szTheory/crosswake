import XCTest
import AVFoundation
import CryptoKit
import CrosswakeShellCore
@testable import CrosswakeShell

/// Unit tests for the host-owned installer and audio delegate. They touch only the public
/// reference pronunciation fixture. The installer's URLSession uses a local URLProtocol
/// stub; nothing here involves WebKit and no study payload exists.
final class StudyAudioCommandDelegateTests: XCTestCase {
    private let origin = URL(string: "http://127.0.0.1:4790")!

    /// The tracked public fixture, found relative to this source file.
    private static func fixtureBytes() throws -> Data {
        var url = URL(fileURLWithPath: #filePath)
        url.deleteLastPathComponent() // CrosswakeShellTests
        url.deleteLastPathComponent() // crosswake_shell
        url.appendPathComponent("../CrosswakeProofLane/Resources/ReferenceLearningBundle/pronunciation.aiff")
        return try Data(contentsOf: url.standardized)
    }

    private func sha(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private func makeDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("twin-installer-\(UUID().uuidString)", isDirectory: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    private func makeInstaller(directory: URL, observe: Bool = false) -> StudyPackInstaller {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        StubURLProtocol.reset()
        return StudyPackInstaller(
            origin: origin,
            session: URLSession(configuration: configuration),
            directory: directory,
            log: TwinObservationLog(environment: [:], directory: directory)
        )
    }

    private func handle(_ delegate: StudyAudioCommandDelegate, assetKey: String = "pronunciation") async -> BridgeChannel.CommandResult {
        await withCheckedContinuation { continuation in
            delegate.handle(
                command: StudyAudioCommandDelegate.command,
                payload: ["asset_key": assetKey],
                correlationID: "cw-test"
            ) { continuation.resume(returning: $0) }
        }
    }

    func testRegisteredCommandsAreExactlyTheOneStudyAudioCommand() async throws {
        let installer = makeInstaller(directory: try makeDirectory())
        let delegate = StudyAudioCommandDelegate(media: installer, log: TwinObservationLog(environment: [:]))
        XCTAssertEqual(delegate.registeredCommands, ["host.study.audio.play"])
    }

    func testExpectedConstantsEqualTheTrackedFixture() throws {
        let bytes = try Self.fixtureBytes()
        XCTAssertEqual(bytes.count, StudyPackInstaller.expectedSize)
        XCTAssertEqual(sha(bytes), StudyPackInstaller.expectedSHA256)
    }

    func testInstallFetchesOnceVerifiesAndReturnsTheInstalledBytes() async throws {
        let bytes = try Self.fixtureBytes()
        let directory = try makeDirectory()
        let installer = makeInstaller(directory: directory)
        StubURLProtocol.respond(status: 200, body: bytes)

        let verified = try await installer.install()

        XCTAssertEqual(verified.data, bytes)
        XCTAssertEqual(verified.sha256, StudyPackInstaller.expectedSHA256)
        XCTAssertEqual(StubURLProtocol.requestCount, 1)
        XCTAssertEqual(StubURLProtocol.lastPath, "/_e2e/twin/media/pronunciation")
        let readBack = try Data(contentsOf: directory.appendingPathComponent("pronunciation.aiff"))
        XCTAssertEqual(readBack, bytes)
        let leftovers = try FileManager.default.contentsOfDirectory(atPath: directory.path)
            .filter { $0.contains("tmp") }
        XCTAssertEqual(leftovers, [])
    }

    func testInstallRejectsWrongSizeAndKeepsThePreviousInstalledBytes() async throws {
        let bytes = try Self.fixtureBytes()
        let directory = try makeDirectory()
        let installer = makeInstaller(directory: directory)
        StubURLProtocol.respond(status: 200, body: bytes)
        _ = try await installer.install()

        StubURLProtocol.respond(status: 200, body: bytes.prefix(100))
        do {
            _ = try await installer.install()
            XCTFail("a short download must be rejected")
        } catch let failure as StudyMediaFailure {
            XCTAssertEqual(failure, .mediaCorrupt)
        }
        let installed = try await installer.installedVerifiedData()
        XCTAssertEqual(installed.data, bytes)
    }

    func testInstallRejectsWrongDigestAtTheRightSize() async throws {
        var corrupt = try Self.fixtureBytes()
        corrupt[corrupt.count / 2] ^= 0x01
        let directory = try makeDirectory()
        let installer = makeInstaller(directory: directory)
        StubURLProtocol.respond(status: 200, body: corrupt)

        do {
            _ = try await installer.install()
            XCTFail("a corrupt download must be rejected")
        } catch let failure as StudyMediaFailure {
            XCTAssertEqual(failure, .mediaCorrupt)
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.appendingPathComponent("pronunciation.aiff").path))
    }

    func testInstallReportsMissingMediaFor404() async throws {
        let installer = makeInstaller(directory: try makeDirectory())
        StubURLProtocol.respond(status: 404, body: Data())
        do {
            _ = try await installer.install()
            XCTFail("a 404 must be reported")
        } catch let failure as StudyMediaFailure {
            XCTAssertEqual(failure, .mediaMissing)
        }
    }

    func testPlayWithInstalledAssetSucceedsAndPlaysTheVerifiedBytes() async throws {
        let bytes = try Self.fixtureBytes()
        let installer = makeInstaller(directory: try makeDirectory())
        StubURLProtocol.respond(status: 200, body: bytes)
        _ = try await installer.install()
        let requestsBeforePlay = StubURLProtocol.requestCount
        let delegate = StudyAudioCommandDelegate(media: installer, log: TwinObservationLog(environment: [:]))

        let result = await handle(delegate)

        XCTAssertEqual(result, .success(["state": "playing"]))
        XCTAssertEqual(StubURLProtocol.requestCount, requestsBeforePlay, "playing must not touch the network")
        let playerDigest = await MainActor.run { delegate.playerSourceSHA256 }
        XCTAssertEqual(playerDigest, StudyPackInstaller.expectedSHA256)
        var progressed = false
        for _ in 0..<80 where !progressed {
            progressed = await MainActor.run { delegate.maxObservedProgress > 0 }
            if !progressed { try await Task.sleep(nanoseconds: 50_000_000) }
        }
        XCTAssertTrue(progressed, "playback progress must become greater than zero")
    }

    func testPlayDeniesMissingAssetWithoutAnyNetworkRequest() async throws {
        let installer = makeInstaller(directory: try makeDirectory())
        let delegate = StudyAudioCommandDelegate(media: installer, log: TwinObservationLog(environment: [:]))

        let result = await handle(delegate)

        guard case let .deny(reason, _, _) = result else { return XCTFail("expected a denial, got \(result)") }
        XCTAssertEqual(reason, "media_missing")
        XCTAssertEqual(StubURLProtocol.requestCount, 0)
    }

    func testPlayDeniesInstalledBytesWhoseDigestNoLongerMatches() async throws {
        let bytes = try Self.fixtureBytes()
        let directory = try makeDirectory()
        let installer = makeInstaller(directory: directory)
        StubURLProtocol.respond(status: 200, body: bytes)
        _ = try await installer.install()
        var tampered = bytes
        tampered[tampered.count / 2] ^= 0x01
        try tampered.write(to: directory.appendingPathComponent("pronunciation.aiff"))
        let requestsBeforePlay = StubURLProtocol.requestCount
        let delegate = StudyAudioCommandDelegate(media: installer, log: TwinObservationLog(environment: [:]))

        let result = await handle(delegate)

        guard case let .deny(reason, _, _) = result else { return XCTFail("expected a denial, got \(result)") }
        XCTAssertEqual(reason, "media_corrupt")
        XCTAssertEqual(StubURLProtocol.requestCount, requestsBeforePlay)
    }

    func testPlayDeniesAnUnknownAssetKey() async throws {
        let installer = makeInstaller(directory: try makeDirectory())
        let delegate = StudyAudioCommandDelegate(media: installer, log: TwinObservationLog(environment: [:]))
        let result = await handle(delegate, assetKey: "../../etc/passwd")
        guard case let .deny(reason, _, _) = result else { return XCTFail("expected a denial, got \(result)") }
        XCTAssertEqual(reason, "asset_unknown")
    }

    func testPlayerIsHeldUntilItFinishesOrIsReplaced() async throws {
        let bytes = try Self.fixtureBytes()
        let installer = makeInstaller(directory: try makeDirectory())
        StubURLProtocol.respond(status: 200, body: bytes)
        _ = try await installer.install()
        let delegate = StudyAudioCommandDelegate(media: installer, log: TwinObservationLog(environment: [:]))

        _ = await handle(delegate)
        let first = await MainActor.run { delegate.player }
        XCTAssertNotNil(first)

        _ = await handle(delegate)
        let second = await MainActor.run { delegate.player }
        XCTAssertNotNil(second)
        XCTAssertFalse(first === second, "the next play command replaces the held player")

        await MainActor.run {
            if let held = delegate.player { delegate.audioPlayerDidFinishPlaying(held, successfully: true) }
        }
        let afterFinish = await MainActor.run { delegate.player }
        XCTAssertNil(afterFinish)
    }

    @MainActor
    func testCompositionRetainsTheDelegateAndRegistersTheCommand() throws {
        var composition: StudyHostComposition? = StudyHostComposition(origin: origin, log: TwinObservationLog(environment: [:]))
        let config = composition!.makeConfig()
        XCTAssertNotNil(config.hostBridgeCommandDelegate)
        XCTAssertTrue(config.registeredCapabilities.contains("host.study.audio.play"))
        XCTAssertNotNil(config.packProvider)
        composition = nil
        // CrosswakeShellConfig holds the delegate weakly, so only the composition keeps it alive.
        XCTAssertNil(config.hostBridgeCommandDelegate)
    }
}

/// Local URLProtocol stub for the installer's URLSession only (not for WebKit).
final class StubURLProtocol: URLProtocol {
    private static let lock = NSLock()
    private static var status = 200
    private static var body = Data()
    private static var count = 0
    private static var path = ""

    static func reset() {
        lock.lock(); defer { lock.unlock() }
        status = 200; body = Data(); count = 0; path = ""
    }
    static func respond(status: Int, body: Data) {
        lock.lock(); defer { lock.unlock() }
        self.status = status; self.body = body
    }
    static var requestCount: Int { lock.lock(); defer { lock.unlock() }; return count }
    static var lastPath: String { lock.lock(); defer { lock.unlock() }; return path }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lock.lock()
        Self.count += 1
        Self.path = request.url?.path ?? ""
        let status = Self.status
        let body = Self.body
        Self.lock.unlock()
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
