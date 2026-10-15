import SwiftUI
import UIKit
import WebKit
import CrosswakeShellCore

/// Native facts about one script message, reduced to what the origin gate may look at.
struct StudyFrameFacts: Equatable {
    var isOwnWebView: Bool
    var isMainFrame: Bool
    var scheme: String
    var host: String
    var port: Int
}

enum StudyGateVerdict: Equatable {
    case forward
    case reject
}

/// Forwards a script message to the shell's BridgeChannel only when it comes from this
/// controller's own visible WKWebView, from its main frame, at the prepared primary origin.
/// Every other message is dropped and counted as frame_identity_rejected.
@MainActor
final class StudyBridgeGate: NSObject, WKScriptMessageHandler {
    weak var expectedWebView: WKWebView?
    var onDecision: ((StudyGateVerdict) -> Void)?
    private(set) var forwardedCount = 0
    private(set) var rejectedCount = 0
    private let primaryOrigin: URL
    private let forward: (WKUserContentController, WKScriptMessage) -> Void

    init(primaryOrigin: URL, forward: @escaping (WKUserContentController, WKScriptMessage) -> Void) {
        self.primaryOrigin = primaryOrigin
        self.forward = forward
        super.init()
    }

    static func verdict(for facts: StudyFrameFacts, primaryOrigin: URL) -> StudyGateVerdict {
        guard facts.isOwnWebView, facts.isMainFrame,
              let scheme = primaryOrigin.scheme?.lowercased(),
              let host = primaryOrigin.host?.lowercased(),
              facts.scheme.lowercased() == scheme,
              facts.host.lowercased() == host else { return .reject }
        let defaultPort = scheme == "https" ? 443 : 80
        let expectedPort = primaryOrigin.port ?? defaultPort
        // WebKit reports 0 for the scheme's default port.
        let actualPort = facts.port == 0 ? defaultPort : facts.port
        return actualPort == expectedPort ? .forward : .reject
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let origin = message.frameInfo.securityOrigin
        let facts = StudyFrameFacts(
            isOwnWebView: message.webView != nil && message.webView === expectedWebView,
            isMainFrame: message.frameInfo.isMainFrame,
            scheme: origin.protocol,
            host: origin.host,
            port: origin.port
        )
        let decision = Self.verdict(for: facts, primaryOrigin: primaryOrigin)
        switch decision {
        case .forward:
            forwardedCount += 1
            forward(userContentController, message)
        case .reject:
            rejectedCount += 1
        }
        onDecision?(decision)
    }
}

/// Samples native WKWebView facts and count/enum-only JavaScript probes into the webview
/// channel. It runs only when observation is enabled and appends a sample only when its
/// value changed. It never reads or records URLs, answers, scope values or tokens.
@MainActor
final class StudyWebObserver {
    private let log: TwinObservationLog
    private let primaryOrigin: URL
    private let gate: StudyBridgeGate
    private weak var webView: WKWebView?
    private var forwardedCorrelations = Set<String>()
    private var replyOK = 0
    private var replyDenied = 0
    private var lastSampled: [String: String] = [:]
    private var probeInFlight = false
    private var timer: Timer?

    init(log: TwinObservationLog, primaryOrigin: URL, gate: StudyBridgeGate, webView: WKWebView) {
        self.log = log
        self.primaryOrigin = primaryOrigin
        self.gate = gate
        self.webView = webView
    }

    static func pathClass(for url: URL?) -> String {
        switch url?.path {
        case "/offline": return "study"
        case "/offline/review": return "review"
        default: return "other"
        }
    }

    func start() {
        guard log.isEnabled, timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.sample() }
        }
        sample()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func forwarded(correlationID: String?) {
        if let correlationID { forwardedCorrelations.insert(correlationID) }
        sample()
    }

    func replied(_ reply: BridgeReplyEnvelope) {
        guard forwardedCorrelations.remove(reply.correlationID) != nil else { return }
        if reply.status == "ok" { replyOK += 1 } else { replyDenied += 1 }
        sample()
    }

    func sample() {
        guard log.isEnabled, let webView else { return }
        let url = webView.url
        let originMatches = url.flatMap { Self.origin(of: $0) } == Self.origin(of: primaryOrigin)
        record("main_frame_origin_match", .count(originMatches ? 1 : 0))
        record("route_path", .word(Self.pathClass(for: url)))
        record("bridge_forwarded", .count(gate.forwardedCount))
        record("frame_identity_rejected", .count(gate.rejectedCount))
        record("host_reply_ok", .count(replyOK))
        record("host_reply_denied", .count(replyDenied))
        let persistent = webView.configuration.websiteDataStore === WKWebsiteDataStore.default()
            && webView.configuration.websiteDataStore.isPersistent
        record("data_store_persistent", .count(persistent ? 1 : 0))
        guard originMatches, !probeInFlight else { return }
        probeInFlight = true
        let onReview = Self.pathClass(for: url) == "review"
        Task { @MainActor [weak self] in
            await self?.probePage(onReview: onReview)
            self?.probeInFlight = false
        }
    }

    /// Runs one probe pass immediately and waits for it; used by the host driver right after
    /// it activates the scope so the first outbox sample of a launch is not a race.
    func sampleNow() async {
        guard log.isEnabled, let webView else { return }
        while probeInFlight { try? await Task.sleep(nanoseconds: 50_000_000) }
        probeInFlight = true
        let onReview = Self.pathClass(for: webView.url) == "review"
        await probePage(onReview: onReview)
        probeInFlight = false
    }

    private func probePage(onReview: Bool) async {
        guard let webView else { return }

        // Counts first, then the learner state: a state that is only reached after the outbox
        // drained can never be recorded ahead of the drained count.
        // Outbox counts are sampled only for a document the host has activated (or the
        // review page, which reads the already-active lifecycle), never before activation.
        let counts = try? await webView.callAsyncJavaScript(
            "if (document.body.dataset.page !== 'review' && document.body.dataset.twinActivated !== '1') { return null; } if (!window.crosswakeIsland || typeof window.crosswakeIsland.outboxCounts !== 'function') { return null; } const c = await window.crosswakeIsland.outboxCounts(); return [c.selected, c.free_form, c.active_scope_total, c.retained_total];",
            arguments: [:], in: nil, contentWorld: .page
        )
        if let values = counts as? [Any], values.count == 4 {
            let kinds = ["outbox_selected", "outbox_free_form", "outbox_active", "outbox_retained"]
            for (kind, raw) in zip(kinds, values) {
                if let number = Self.integer(raw) {
                    record(kind, .count(number))
                } else {
                    record(kind, .count(0), cause: "probe_invalid")
                }
            }
        }

        let state = try? await webView.callAsyncJavaScript(
            "const e = document.getElementById('crosswake-study-status'); return e && e.dataset ? (e.dataset.islandState || '') : '';",
            arguments: [:], in: nil, contentWorld: .page
        )
        if let state = state as? String, !state.isEmpty {
            record("island_state", .word(state))
        }

        if onReview {
            let retry = try? await webView.callAsyncJavaScript(
                "return Array.from(document.querySelectorAll('#review-list button')).some(b => b.textContent.trim() === 'Try again') ? 1 : 0;",
                arguments: [:], in: nil, contentWorld: .page
            )
            if let retry = Self.integer(retry as Any), retry == 0 || retry == 1 {
                record("retry_offered", .count(retry))
            }
        }
    }

    /// A JavaScript number that is an integer and not a boolean; anything else is invalid.
    private static func integer(_ raw: Any) -> Int? {
        guard let number = raw as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() else { return nil }
        let value = number.doubleValue
        guard value.rounded() == value, value >= 0, value <= Double(TwinVocabulary.maxCount) else { return nil }
        return Int(value)
    }

    private static func origin(of url: URL) -> String? {
        guard let scheme = url.scheme?.lowercased(), let host = url.host?.lowercased() else { return nil }
        let port = url.port ?? (scheme == "https" ? 443 : 80)
        return "\(scheme)://\(host):\(port)"
    }

    private func record(_ kind: String, _ value: TwinValue, cause: String? = nil) {
        let key: String
        switch value {
        case let .count(number): key = "\(number)|\(cause ?? "")"
        case let .word(word): key = "\(word)|\(cause ?? "")"
        }
        guard lastSampled[kind] != key else { return }
        if log.append(channel: .webview, kind: kind, value: value, cause: cause) {
            lastSampled[kind] = key
        }
    }
}

/// The visible study WebView. It uses the default persistent website data store, configured
/// before the view is created, and the single prepared primary origin. There is no reset
/// argument, store replacement or reinstall path.
@MainActor
final class StudyWebViewController: UIViewController, WKNavigationDelegate {
    private(set) var session: LiveViewSession
    private let shell: CrosswakeShell
    private var gate: StudyBridgeGate!
    private var bridgeChannel: BridgeChannel!
    private var observer: StudyWebObserver!
    private var driver: TwinHostDriver!
    private var webView: WKWebView!
    private let log: TwinObservationLog
    private var loadFailed = false

    init(session: LiveViewSession, shell: CrosswakeShell, log: TwinObservationLog = .shared) {
        self.session = session
        self.shell = shell
        self.log = log
        super.init(nibName: nil, bundle: nil)

        let observeHolder = ObserverHolder()
        let reply = BridgeReplyDelivery.sink { [weak self] script in
            Task { @MainActor in self?.webView?.evaluateJavaScript(script, completionHandler: nil) }
        }
        bridgeChannel = shell.createBridgeChannel(
            session: session,
            transferCoordinator: shell.coordinator.transferCoordinator,
            replySink: { envelope in
                Task { @MainActor in observeHolder.observer?.replied(envelope) }
                reply(envelope)
            }
        )
        let channel = bridgeChannel!
        gate = StudyBridgeGate(primaryOrigin: session.allowedOrigin) { controller, message in
            let correlation = (message.body as? String)
                .flatMap { $0.data(using: .utf8) }
                .flatMap { try? JSONDecoder().decode(BridgeRequestEnvelope.self, from: $0) }?
                .correlationID
            observeHolder.observer?.forwarded(correlationID: correlation)
            channel.userContentController(controller, didReceive: message)
        }
        let configuration = Self.makeConfiguration(
            capabilities: session.capabilities,
            threadID: session.threadID,
            handler: gate
        )
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = self
        view.allowsBackForwardNavigationGestures = false
        webView = view
        gate.expectedWebView = view
        observer = StudyWebObserver(log: log, primaryOrigin: session.allowedOrigin, gate: gate, webView: view)
        observeHolder.observer = observer
        driver = TwinHostDriver(webView: view, observer: observer, log: log)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Builds the configuration with the default persistent data store set before the
    /// WKWebView is created. The capabilities object is the session's granted capability map
    /// (command to version), which is the shape the study page checks.
    static func makeConfiguration(
        capabilities: [String: String],
        threadID: String,
        handler: WKScriptMessageHandler
    ) -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.default()

        let userContentController = WKUserContentController()
        userContentController.add(handler, name: BridgeChannel.handlerName)
        let facts: [String: Any] = ["capabilities": capabilities, "threadId": threadID]
        if let data = try? JSONSerialization.data(withJSONObject: facts, options: [.sortedKeys]),
           let json = String(data: data, encoding: .utf8) {
            let source = """
            (function () {
              var facts = \(json);
              window.crosswakeBridge = window.crosswakeBridge || {};
              window.crosswakeBridge.capabilities = facts.capabilities;
              window.crosswakeBridge.threadId = facts.threadId;
            })();
            """
            userContentController.addUserScript(
                WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
            )
        }
        configuration.userContentController = userContentController
        return configuration
    }

    override func loadView() { view = webView }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadSession()
        observer.start()
        driver.start()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        observer.stop()
        driver.stop()
    }

    func update(session next: LiveViewSession) {
        guard next != session else { return }
        session = next
        bridgeChannel.update(session: next, transferCoordinator: shell.coordinator.transferCoordinator)
        loadSession()
    }

    private func loadSession() {
        guard Self.isAllowed(session.url, origin: session.allowedOrigin) else { return }
        var request = URLRequest(url: session.url)
        request.setValue(session.threadID, forHTTPHeaderField: "X-Crosswake-Thread-Id")
        webView.load(request)
    }

    private static func isAllowed(_ url: URL, origin: URL) -> Bool {
        url.scheme?.lowercased() == origin.scheme?.lowercased()
            && url.host?.lowercased() == origin.host?.lowercased()
            && url.port == origin.port
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url,
              url.scheme == "about" || Self.isAllowed(url, origin: session.allowedOrigin) else {
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        TwinHostState.shared.ready = false
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadFailed = false
        observer.sample()
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        retryLoadSoon()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        retryLoadSoon()
    }

    /// A study document that could not be fetched is requested again shortly after, which is
    /// what a host does when its first load fails. Only while the twin observes, so the
    /// ordinary host behaviour is unchanged.
    private func retryLoadSoon() {
        guard log.isEnabled else { return }
        loadFailed = true
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard let self, self.loadFailed else { return }
            self.loadSession()
        }
    }

    private final class ObserverHolder {
        weak var observer: StudyWebObserver?
    }
}

struct StudyWebView: UIViewControllerRepresentable {
    let session: LiveViewSession
    let shell: CrosswakeShell

    func makeUIViewController(context: Context) -> StudyWebViewController {
        StudyWebViewController(session: session, shell: shell)
    }

    func updateUIViewController(_ controller: StudyWebViewController, context: Context) {
        controller.update(session: session)
    }
}
