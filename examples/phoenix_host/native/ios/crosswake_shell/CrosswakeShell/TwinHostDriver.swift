import Foundation
import WebKit

/// Readiness flag read by the root view's accessibility marker. It carries one bit and no
/// study content.
@MainActor
final class TwinHostState: ObservableObject {
    static let shared = TwinHostState()
    @Published var ready = false
}

/// Test-gated, run-owned host driver for the bounded digital-twin demonstration.
///
/// It runs only when CROSSWAKE_TWIN_OBSERVE=1. It plays the part the real host plays around
/// the offline island: it checks that the origin is reachable (with a request from the page
/// itself), establishes the synthetic account session and activates the island's scope once
/// the session exists, signals the island when connectivity returns, and fences the island
/// when the server stops honouring the active scope. It never writes an observation, never
/// reads answers or scope values back, and its fixed synthetic scope is a public fixture
/// name, not a recorded value.
@MainActor
final class TwinHostDriver {
    static let controlPortKey = "CROSSWAKE_TWIN_CONTROL_PORT"
    static let sessionKey = "CROSSWAKE_TWIN_SESSION"
    /// Index of the scope_fence epoch in the boundary's closed epoch list.
    static let scopeFenceEpoch = 8
    static let primaryScope = "v1.scope_fixture_alpha_01"
    private static let retryStates: Set<String> = ["waiting", "unavailable", "entry_disabled"]

    private weak var webView: WKWebView?
    private let observer: StudyWebObserver
    private let log: TwinObservationLog
    private let controlPort: Int?
    private let establishesSession: Bool
    private var task: Task<Void, Never>?
    private var switched = false
    private var fenced = false

    init(
        webView: WKWebView,
        observer: StudyWebObserver,
        log: TwinObservationLog,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        self.webView = webView
        self.observer = observer
        self.log = log
        self.controlPort = environment[Self.controlPortKey].flatMap(Int.init)
        self.establishesSession = (environment[Self.sessionKey] ?? "establish") == "establish"
    }

    func start() {
        guard log.isEnabled, task == nil else { return }
        task = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                await self?.tick()
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    private func tick() async {
        guard let webView, StudyWebObserver.pathClass(for: webView.url) == "study" else { return }

        // The probe is a real WebView request, so it is refused (and counted) while the
        // boundary refuses and passes when it passes.
        let reachable = await boolean(
            "try { const r = await fetch('/offline_study.js', { method: 'HEAD', cache: 'no-store' }); return r.ok; } catch (e) { return false; }"
        )
        guard reachable else { return }

        let activated = await boolean(
            "return !!(document.body && document.body.dataset.twinActivated === '1');"
        )
        if !activated {
            TwinHostState.shared.ready = false
            if establishesSession { await establishAndActivate() }
            return
        }
        TwinHostState.shared.ready = true

        if !switched, await currentEpoch() == Self.scopeFenceEpoch {
            switched = await postSession("switch")
        }

        let island = await islandState()
        if switched, !fenced, island == "unavailable" {
            // The server no longer honours the active scope: stop browser authority, then log out.
            fenced = true
            _ = await boolean("await window.crosswakeOfflineStudy.fenceScope(); return true;")
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            _ = await postSession("clear")
            return
        }
        if !fenced, Self.retryStates.contains(island) {
            _ = await boolean("window.dispatchEvent(new Event('online')); return true;")
        }
    }

    private func establishAndActivate() async {
        let ok = await boolean(
            """
            const r = await fetch('/_e2e/replay-session', {
              method: 'POST',
              headers: { 'content-type': 'application/json', 'accept': 'application/json' },
              body: JSON.stringify({ action: 'establish' })
            });
            if (!r.ok) { return false; }
            try { await window.crosswakeOfflineStudy.activateScope(scope); } catch (e) { return false; }
            document.body.dataset.twinActivated = '1';
            return true;
            """,
            arguments: ["scope": Self.primaryScope]
        )
        guard ok else { return }
        TwinHostState.shared.ready = true
        await observer.sampleNow()
    }

    private func postSession(_ action: String) async -> Bool {
        await boolean(
            """
            const r = await fetch('/_e2e/replay-session', {
              method: 'POST',
              headers: { 'content-type': 'application/json', 'accept': 'application/json' },
              body: JSON.stringify({ action: action })
            });
            return r.ok;
            """,
            arguments: ["action": action]
        )
    }

    private func islandState() async -> String {
        let value = try? await webView?.callAsyncJavaScript(
            "const e = document.getElementById('crosswake-study-status'); return e && e.dataset ? (e.dataset.islandState || '') : '';",
            arguments: [:], in: nil, contentWorld: .page
        )
        return (value as? String) ?? ""
    }

    private func boolean(_ body: String, arguments: [String: Any] = [:]) async -> Bool {
        let value = try? await webView?.callAsyncJavaScript(
            body, arguments: arguments, in: nil, contentWorld: .page
        )
        return (value as? Bool) ?? false
    }

    /// Reads the boundary's closed epoch index (an integer) from the run-owned control port.
    private func currentEpoch() async -> Int? {
        guard let controlPort, let url = URL(string: "http://127.0.0.1:\(controlPort)/status") else { return nil }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Int] else { return nil }
        return object["epoch"]
    }
}
