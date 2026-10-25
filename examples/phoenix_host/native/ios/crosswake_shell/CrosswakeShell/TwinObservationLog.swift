import Foundation

/// Host-local, closed observation records for the bounded digital-twin demonstration.
///
/// Writes happen only when the launch environment sets CROSSWAKE_TWIN_OBSERVE=1. Every
/// record has exactly the keys kind, launch, seq, value and cause. The kind must belong to
/// the channel's closed vocabulary, the value is a bounded integer or a closed word, and
/// the cause is a closed identifier or null. Nothing here can carry answers, media bytes,
/// URLs, query values, scope values, tokens or device identifiers, because there is no
/// field that accepts free text.
enum TwinChannel: String, CaseIterable {
    case hostAdapter = "host_adapter"
    case webview
    case appProcess = "app_process"

    var fileName: String { "twin-" + rawValue.replacingOccurrences(of: "_", with: "-") + ".jsonl" }
}

enum TwinValue: Equatable {
    case count(Int)
    case word(String)
}

enum TwinVocabulary {
    enum Shape {
        case count
        case word(Set<String>)
    }

    static let maxCount = 1_000_000

    static let causes: Set<String> = [
        "media_missing", "media_corrupt", "install_failed", "playback_failed",
        "probe_invalid", "timeout",
    ]

    static let verdicts: Set<String> = ["passed", "failed", "blocked"]

    static let hostAdapterKinds: Set<String> = [
        "TW-T01-01", "TW-T01-02", "TW-T01-03", "TW-T01-04",
        "TW-T04-02", "TW-T04-03", "TW-T04-04", "TW-T04-05",
    ]

    /// The closed data-island-state vocabulary mirrored by the study page (180-04).
    static let islandStates: Set<String> = [
        "saved_local", "waiting", "sending", "saved_account", "needs_review",
        "unavailable", "audio_unavailable", "fenced", "entry_disabled",
    ]

    static let routePaths: Set<String> = ["study", "review", "other"]

    static let webviewShapes: [String: Shape] = [
        "main_frame_origin_match": .count,
        "route_path": .word(routePaths),
        "bridge_forwarded": .count,
        "frame_identity_rejected": .count,
        "host_reply_ok": .count,
        "host_reply_denied": .count,
        "island_state": .word(islandStates),
        "outbox_selected": .count,
        "outbox_free_form": .count,
        "outbox_active": .count,
        "outbox_retained": .count,
        "data_store_persistent": .count,
        "retry_offered": .count,
    ]

    static func shape(channel: TwinChannel, kind: String) -> Shape? {
        switch channel {
        case .hostAdapter:
            return hostAdapterKinds.contains(kind) ? .word(verdicts) : nil
        case .webview:
            return webviewShapes[kind]
        case .appProcess:
            return kind == "launch" ? .count : nil
        }
    }
}

final class TwinObservationLog: @unchecked Sendable {
    static let environmentKey = "CROSSWAKE_TWIN_OBSERVE"
    static let shared = TwinObservationLog()

    let isEnabled: Bool
    private let directory: URL
    private let launch: Int
    private let queue = DispatchQueue(label: "org.crosswake.twin.observation")
    private var sequences: [TwinChannel: Int] = [:]

    init(environment: [String: String] = ProcessInfo.processInfo.environment, directory: URL? = nil) {
        self.isEnabled = environment[Self.environmentKey] == "1"
        self.directory = directory
            ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        if isEnabled {
            let processFile = self.directory.appendingPathComponent(TwinChannel.appProcess.fileName)
            let prior = (try? String(contentsOf: processFile, encoding: .utf8))?
                .split(separator: "\n").count ?? 0
            self.launch = prior + 1
        } else {
            self.launch = 0
        }
    }

    /// Appends one closed record. Returns false (and writes nothing) when observation is off
    /// or when any part of the record is outside the closed vocabulary.
    @discardableResult
    func append(channel: TwinChannel, kind: String, value: TwinValue, cause: String? = nil) -> Bool {
        guard isEnabled, Self.isValid(channel: channel, kind: kind, value: value, cause: cause) else {
            return false
        }
        return queue.sync {
            let seq = (sequences[channel] ?? 0) + 1
            let valueObject: Any
            switch value {
            case let .count(number): valueObject = number
            case let .word(word): valueObject = word
            }
            let record: [String: Any] = [
                "kind": kind,
                "launch": launch,
                "seq": seq,
                "value": valueObject,
                "cause": cause.map { $0 as Any } ?? NSNull(),
            ]
            guard var line = try? JSONSerialization.data(withJSONObject: record, options: [.sortedKeys]) else {
                return false
            }
            line.append(0x0A)
            let url = directory.appendingPathComponent(channel.fileName)
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                if !FileManager.default.fileExists(atPath: url.path) {
                    FileManager.default.createFile(atPath: url.path, contents: nil)
                }
                let handle = try FileHandle(forWritingTo: url)
                defer { try? handle.close() }
                try handle.seekToEnd()
                try handle.write(contentsOf: line)
            } catch {
                return false
            }
            sequences[channel] = seq
            return true
        }
    }

    /// One launch sample per process start; the value is the process identifier.
    func appendLaunchSample(processIdentifier: Int32 = ProcessInfo.processInfo.processIdentifier) {
        append(channel: .appProcess, kind: "launch", value: .count(Int(processIdentifier)))
    }

    static func isValid(channel: TwinChannel, kind: String, value: TwinValue, cause: String?) -> Bool {
        guard let shape = TwinVocabulary.shape(channel: channel, kind: kind) else { return false }
        if let cause, !TwinVocabulary.causes.contains(cause) { return false }
        switch (shape, value) {
        case let (.count, .count(number)):
            return (0...TwinVocabulary.maxCount).contains(number)
        case let (.word(allowed), .word(word)):
            return allowed.contains(word)
        default:
            return false
        }
    }
}
