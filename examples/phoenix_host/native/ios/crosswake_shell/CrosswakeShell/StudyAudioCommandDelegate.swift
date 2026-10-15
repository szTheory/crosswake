import Foundation
import AVFoundation
import CrosswakeShellCore

/// Host-owned adapter for the one typed `host.study.audio.play` command.
///
/// The page never names a file, URL or path: it sends the opaque asset key `pronunciation`.
/// The adapter obtains the installed bytes already verified by size and SHA-256, then builds
/// `AVAudioPlayer(data:)` from that same `Data` value, never by reopening a path. There is
/// no remote fallback: missing or corrupt installed media is an explicit denial and performs
/// no network request.
final class StudyAudioCommandDelegate: NSObject, HostBridgeCommandDelegate, AVAudioPlayerDelegate {
    static let command = "host.study.audio.play"
    static let assetKey = "pronunciation"

    private let media: StudyVerifiedMediaSource
    private let log: TwinObservationLog

    /// Held from play until audioPlayerDidFinishPlaying or until the next play command
    /// replaces it, so playback is not cut off by deallocation.
    @MainActor private(set) var player: AVAudioPlayer?
    @MainActor private(set) var playerSourceSHA256: String?
    @MainActor private(set) var maxObservedProgress: TimeInterval = 0

    var registeredCommands: [String] { [Self.command] }

    init(media: StudyVerifiedMediaSource, log: TwinObservationLog = .shared) {
        self.media = media
        self.log = log
        super.init()
    }

    func handle(
        command: String,
        payload: [String: String],
        correlationID: String,
        completion: @escaping (BridgeChannel.CommandResult) -> Void
    ) {
        guard command == Self.command else {
            completion(Self.denial("undeclared_capability", "This command is not handled by the host adapter."))
            return
        }
        guard payload["asset_key"] == Self.assetKey else {
            completion(Self.denial("asset_unknown", "The requested audio asset is not available."))
            return
        }

        let media = self.media
        Task.detached { [weak self] in
            do {
                let verified = try await media.installedVerifiedData()
                await MainActor.run { self?.play(verified, completion: completion) }
            } catch let failure as StudyMediaFailure {
                await MainActor.run { self?.deny(failure, completion: completion) }
            } catch {
                await MainActor.run { self?.deny(.mediaMissing, completion: completion) }
            }
        }
    }

    @MainActor
    private func deny(_ failure: StudyMediaFailure, completion: (BridgeChannel.CommandResult) -> Void) {
        switch failure {
        case .mediaMissing:
            log.append(channel: .hostAdapter, kind: "TW-T04-04", value: .word("passed"), cause: "media_missing")
            completion(Self.denial("media_missing", "The pronunciation audio is not installed on this device."))
        case .mediaCorrupt:
            log.append(channel: .hostAdapter, kind: "TW-T04-05", value: .word("passed"), cause: "media_corrupt")
            completion(Self.denial("media_corrupt", "The installed pronunciation audio failed verification."))
        case .installFailed:
            completion(Self.denial("media_missing", "The pronunciation audio is not installed on this device."))
        }
    }

    @MainActor
    private func play(_ verified: StudyVerifiedMedia, completion: (BridgeChannel.CommandResult) -> Void) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true)

            let next = try AVAudioPlayer(data: verified.data)
            next.delegate = self
            next.prepareToPlay()
            player?.stop()
            guard next.play() else {
                log.append(channel: .hostAdapter, kind: "TW-T04-03", value: .word("failed"), cause: "playback_failed")
                completion(Self.denial("playback_failed", "Playback could not start."))
                return
            }
            player = next
            playerSourceSHA256 = verified.sha256
            maxObservedProgress = 0
            log.append(channel: .hostAdapter, kind: "TW-T04-02", value: .word("passed"))
            monitorProgress(of: next)
            completion(.success(["state": "playing"]))
        } catch {
            log.append(channel: .hostAdapter, kind: "TW-T04-03", value: .word("failed"), cause: "playback_failed")
            completion(Self.denial("playback_failed", "Playback could not start."))
        }
    }

    /// Records TW-T04-03 passed only when currentTime is greater than zero within 3 seconds.
    @MainActor
    private func monitorProgress(of observed: AVAudioPlayer) {
        Task { @MainActor [weak self, weak observed] in
            let deadline = Date().addingTimeInterval(3)
            while Date() < deadline {
                if let self, let observed, observed.currentTime > 0 {
                    self.maxObservedProgress = max(self.maxObservedProgress, observed.currentTime)
                    self.log.append(channel: .hostAdapter, kind: "TW-T04-03", value: .word("passed"))
                    return
                }
                try? await Task.sleep(nanoseconds: 25_000_000)
            }
            self?.log.append(channel: .hostAdapter, kind: "TW-T04-03", value: .word("failed"), cause: "timeout")
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ finished: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            if let self, self.player === finished { self.player = nil }
        }
    }

    private static func denial(_ reason: String, _ message: String) -> BridgeChannel.CommandResult {
        .deny(reason: reason, message: message, hint: "Retry from the study screen when the audio is installed.")
    }
}
