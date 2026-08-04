import SwiftUI
import CrosswakeShellCore
import UIKit
import UniformTypeIdentifiers
import WebKit

struct LiveViewContainerView: UIViewControllerRepresentable {
    let session: LiveViewSession
    let shell: CrosswakeShell
    let notificationTokenProvider: NotificationTokenProvider
    let uiActionDelegates: UIActionDelegates
    let onDenied: (RouteDenialPresentation) -> Void

    func makeUIViewController(context: Context) -> LiveViewContainerViewController {
        LiveViewContainerViewController(
            session: session,
            shell: shell,
            notificationTokenProvider: notificationTokenProvider,
            uiActionDelegates: uiActionDelegates,
            onDenied: onDenied
        )
    }

    func updateUIViewController(_ uiViewController: LiveViewContainerViewController, context: Context) {
        uiViewController.update(
            session: session,
            shell: shell,
            notificationTokenProvider: notificationTokenProvider,
            uiActionDelegates: uiActionDelegates
        )
    }
}

@MainActor
final class FilePickerCoordinator: NSObject, UIDocumentPickerDelegate {
    private struct PendingRequest {
        let transferID: String
        let allowsMultipleSelection: Bool
        let correlationID: String
        let completion: (BridgeChannel.CommandResult) -> Void
    }

    private weak var presenter: UIViewController?
    private let transferCoordinatorProvider: () -> TransferCoordinator?
    private var pendingRequest: PendingRequest?

    init(
        presenterProvider: @escaping () -> UIViewController?,
        transferCoordinatorProvider: @escaping () -> TransferCoordinator?
    ) {
        self.presenter = presenterProvider()
        self.transferCoordinatorProvider = transferCoordinatorProvider
        super.init()
    }

    func updatePresenter(_ presenter: UIViewController?) {
        self.presenter = presenter
    }

    func presentPicker(
        payload: [String: String],
        correlationID: String,
        completion: @escaping (BridgeChannel.CommandResult) -> Void
    ) {
        guard pendingRequest == nil else {
            completion(
                .deny(
                    reason: "picker_in_progress",
                    message: "The shell already has a file picker request in progress for this route.",
                    hint: "Wait for the current picker request to finish before retrying files.pick."
                )
            )
            return
        }

        guard let presenter else {
            completion(
                .deny(
                    reason: "picker_unavailable",
                    message: "The shell could not present a document picker for this route.",
                    hint: "Retry after the LiveView container is visible."
                )
            )
            return
        }

        guard let transferID = payload["transfer_id"], transferID.isEmpty == false else {
            completion(
                .deny(
                    reason: "undeclared_capability",
                    message: "files.pick requires a manifest-declared transfer_id.",
                    hint: "Retry only with the active route's manifest-declared picker transfer_id."
                )
            )
            return
        }

        guard let seam = transferCoordinatorProvider()?.declaredPickerTransfer(id: transferID) else {
            completion(
                .deny(
                    reason: "undeclared_capability",
                    message: "This route does not declare the requested picker transfer seam.",
                    hint: "Retry only with the active route's manifest-declared picker transfer_id."
                )
            )
            return
        }

        let allowsMultipleSelection = payload["multiple_allowed"] == "true"
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: contentTypes(for: seam.mediaTypes, payload: payload),
            asCopy: true
        )
        picker.delegate = self
        picker.allowsMultipleSelection = allowsMultipleSelection

        pendingRequest = PendingRequest(
            transferID: transferID,
            allowsMultipleSelection: allowsMultipleSelection,
            correlationID: correlationID,
            completion: completion
        )

        presenter.present(picker, animated: true)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        guard let pendingRequest else { return }
        defer { self.pendingRequest = nil }

        transferCoordinatorProvider()?.markPickerCanceled(
            transferID: pendingRequest.transferID,
            correlationID: pendingRequest.correlationID
        )

        pendingRequest.completion(
            .success(
                [
                    "transfer_id": pendingRequest.transferID,
                    "outcome": "canceled",
                    "detail.reason": "user_canceled",
                    "items": "[]"
                ]
            )
        )
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let pendingRequest else { return }
        defer { self.pendingRequest = nil }

        guard let transferCoordinator = transferCoordinatorProvider() else {
            pendingRequest.completion(
                .deny(
                    reason: "undeclared_capability",
                    message: "This route does not declare the requested picker transfer seam.",
                    hint: "Retry only with the active route's manifest-declared picker transfer_id."
                )
            )
            return
        }

        let selectedURLs = pendingRequest.allowsMultipleSelection ? urls : Array(urls.prefix(1))

        do {
            let items = try selectedURLs.compactMap { url in
                try transferCoordinator.stagePickedDocument(
                    transferID: pendingRequest.transferID,
                    sourceURL: url,
                    correlationID: pendingRequest.correlationID
                )
            }

            pendingRequest.completion(
                .success(
                    [
                        "transfer_id": pendingRequest.transferID,
                        "outcome": "picked",
                        "items": jsonString(items)
                    ]
                )
            )
        } catch {
            pendingRequest.completion(
                .deny(
                    reason: "file_staging_failed",
                    message: "The shell could not stage a copy-first file handle for this picker selection.",
                    hint: error.localizedDescription
                )
            )
        }
    }

    private func contentTypes(for mediaTypes: [String], payload: [String: String]) -> [UTType] {
        let advisoryTypes = payload["media_types"]
            .map(parseMediaTypes(from:))
            .flatMap { $0.isEmpty ? nil : $0 }

        let requestedMediaTypes = advisoryTypes ?? mediaTypes
        let resolvedTypes = requestedMediaTypes.compactMap(resolveContentType(from:))
        return resolvedTypes.isEmpty ? [.data] : resolvedTypes
    }

    private func parseMediaTypes(from value: String) -> [String] {
        if let data = value.data(using: .utf8),
           let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [String] {
            return jsonArray
        }

        return value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
    }

    private func resolveContentType(from mediaType: String) -> UTType? {
        switch mediaType {
        case "image/*":
            return .image
        case "audio/*":
            return .audio
        case "video/*":
            return .movie
        default:
            return UTType(mimeType: mediaType) ?? .data
        }
    }

    private func jsonString(_ items: [[String: String]]) -> String {
        let data = (try? JSONSerialization.data(withJSONObject: items, options: [.sortedKeys])) ?? Data("[]".utf8)
        return String(data: data, encoding: .utf8) ?? "[]"
    }
}

final class LiveViewContainerViewController: UIViewController, WKNavigationDelegate {
    private struct ShellLayoutInsets: Equatable {
        let top: CGFloat; let right: CGFloat; let bottom: CGFloat; let left: CGFloat; let keyboardBottom: CGFloat
    }
    static let documentStartShellScript = """
    document.documentElement.dataset.cwNativeShell = "ios";
    document.documentElement.style.setProperty("--cw-safe-area-top", "0px");
    document.documentElement.style.setProperty("--cw-safe-area-right", "0px");
    document.documentElement.style.setProperty("--cw-safe-area-bottom", "0px");
    document.documentElement.style.setProperty("--cw-safe-area-left", "0px");
    document.documentElement.style.setProperty("--cw-keyboard-inset-bottom", "0px");
    """

    static func layoutDeliveryScript(for values: [CGFloat]) -> String {
        precondition(values.count == 5)
        return "document.documentElement.style.setProperty('--cw-safe-area-top','\\(values[0])px');document.documentElement.style.setProperty('--cw-safe-area-right','\\(values[1])px');document.documentElement.style.setProperty('--cw-safe-area-bottom','\\(values[2])px');document.documentElement.style.setProperty('--cw-safe-area-left','\\(values[3])px');document.documentElement.style.setProperty('--cw-keyboard-inset-bottom','\\(values[4])px');"
    }
    private var pendingLayoutInsets: ShellLayoutInsets?
    private var deliveredLayoutInsets: ShellLayoutInsets?
    private let layoutObservationSink: (([CGFloat]) -> Void)?
    private let onDenied: (RouteDenialPresentation) -> Void
    private var session: LiveViewSession
    private let shell: CrosswakeShell
    private var notificationTokenProvider: NotificationTokenProvider
    private var uiActionDelegates: UIActionDelegates
    private lazy var filePickerCoordinator = FilePickerCoordinator(
        presenterProvider: { [weak self] in self },
        transferCoordinatorProvider: { [weak self] in self?.shell.coordinator.transferCoordinator }
    )
    // The bridge reply RETURN leg (D-02).
    //
    // `WKScriptMessageHandler` is send-only by design: the page posts into the shell
    // and nothing carries a reply back. Android has been duplex since day one; on iOS
    // the only way home is evaluating JavaScript against the hook's landing pad in
    // `priv/static/crosswake.esm.js`.
    //
    // CrosswakeShellCore owns WHAT is evaluated and how the envelope is serialized —
    // a denial message is host-influenced content and string-concatenating it into
    // evaluated JavaScript would be a script-injection boundary into this app's own
    // origin. The host owns only "run this script against my WebView".
    private lazy var bridgeChannel = shell.createBridgeChannel(
        session: session,
        transferCoordinator: shell.coordinator.transferCoordinator,
        evaluateJavaScript: { [weak self] script in
            Task { @MainActor in
                self?.webView.evaluateJavaScript(script, completionHandler: nil)
            }
        }
    )
    private lazy var navigationTransitionChannel = shell.createNavigationTransitionChannel()
    private lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.addUserScript(WKUserScript(source: Self.documentStartShellScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))

        userContentController.add(bridgeChannel, name: BridgeChannel.handlerName)
        userContentController.add(navigationTransitionChannel, name: NavigationTransitionChannel.handlerName)
        
        // Inject capabilities into the window.crosswakeBridge object
        let capabilities = shell.coordinator.registeredCapabilities
        if let capabilitiesData = try? JSONSerialization.data(withJSONObject: capabilities, options: []),
           let capabilitiesString = String(data: capabilitiesData, encoding: .utf8) {
            let scriptSource = """
            window.crosswakeBridge = window.crosswakeBridge || {};
            window.crosswakeBridge.capabilities = \(capabilitiesString);
            window.crosswakeBridge.threadId = "\(session.threadID)";
            """
            let userScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: false)
            userContentController.addUserScript(userScript)
        }

        configuration.userContentController = userContentController

        // App-Bound Domains keep the generated shell inside declared WebKit authority.
        if #available(iOS 14.0, *) {
            configuration.limitsNavigationsToAppBoundDomains = true
        }

        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = self
        view.allowsBackForwardNavigationGestures = false
        return view
    }()

    init(
        session: LiveViewSession,
        shell: CrosswakeShell,
        notificationTokenProvider: NotificationTokenProvider,
        uiActionDelegates: UIActionDelegates,
        onDenied: @escaping (RouteDenialPresentation) -> Void,
        layoutObservationSink: (([CGFloat]) -> Void)? = nil
    ) {
        self.session = session
        self.shell = shell
        self.notificationTokenProvider = notificationTokenProvider
        self.uiActionDelegates = uiActionDelegates
        self.onDenied = onDenied
        self.layoutObservationSink = layoutObservationSink
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = webView
    }

    deinit {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: BridgeChannel.handlerName)
        webView.configuration.userContentController.removeScriptMessageHandler(forName: NavigationTransitionChannel.handlerName)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        filePickerCoordinator.updatePresenter(self)
        uiActionDelegates.presenter = self
        uiActionDelegates.filePickerCoordinator = filePickerCoordinator
        loadRouteIfNeeded()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChanged(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    override func viewSafeAreaInsetsDidChange() { super.viewSafeAreaInsetsDidChange(); scheduleLayoutDelivery() }

    func update(
        session: LiveViewSession,
        shell: CrosswakeShell,
        notificationTokenProvider: NotificationTokenProvider,
        uiActionDelegates: UIActionDelegates
    ) {
        guard self.session != session
            || self.notificationTokenProvider !== notificationTokenProvider
            || self.uiActionDelegates !== uiActionDelegates else { return }

        self.session = session
        self.notificationTokenProvider = notificationTokenProvider
        self.uiActionDelegates = uiActionDelegates
        
        webView.configuration.userContentController.removeAllUserScripts()
        webView.configuration.userContentController.addUserScript(WKUserScript(source: Self.documentStartShellScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        let capabilities = shell.coordinator.registeredCapabilities
        if let capabilitiesData = try? JSONSerialization.data(withJSONObject: capabilities, options: []),
           let capabilitiesString = String(data: capabilitiesData, encoding: .utf8) {
            let scriptSource = """
            window.crosswakeBridge = window.crosswakeBridge || {};
            window.crosswakeBridge.capabilities = \(capabilitiesString);
            window.crosswakeBridge.threadId = "\(session.threadID)";
            """
            let userScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: false)
            webView.configuration.userContentController.addUserScript(userScript)
        }
        
        filePickerCoordinator.updatePresenter(self)
        uiActionDelegates.presenter = self
        uiActionDelegates.filePickerCoordinator = filePickerCoordinator
        
        bridgeChannel.update(session: session, transferCoordinator: shell.coordinator.transferCoordinator)
        loadRouteIfNeeded()
    }

    @objc private func keyboardChanged(_ notification: Notification) {
        let frame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .null
        let overlap = max(0, view.bounds.maxY - view.convert(frame, from: nil).minY)
        scheduleLayoutDelivery(keyboardBottom: overlap)
    }

    private func scheduleLayoutDelivery(keyboardBottom: CGFloat? = nil) {
        let safe = view.safeAreaInsets
        let next = ShellLayoutInsets(top: safe.top, right: safe.right, bottom: safe.bottom, left: safe.left, keyboardBottom: keyboardBottom ?? deliveredLayoutInsets?.keyboardBottom ?? 0)
        guard next != deliveredLayoutInsets, next != pendingLayoutInsets else { return }
        pendingLayoutInsets = next
        DispatchQueue.main.async { [weak self] in self?.deliverPendingLayoutInsets() }
    }

    private func deliverPendingLayoutInsets() {
        guard let insets = pendingLayoutInsets, insets != deliveredLayoutInsets else { return }
        pendingLayoutInsets = nil; deliveredLayoutInsets = insets
        let values = [insets.top, insets.right, insets.bottom, insets.left, insets.keyboardBottom].map { max(0, $0.isFinite ? $0 : 0) }
        layoutObservationSink?(values)
        let script = Self.layoutDeliveryScript(for: values)
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        // same-origin gate: allowlisted runtime content stays on the manifest-owned origin only.
        guard Self.isNavigationAllowed(url, allowedOrigin: session.allowedOrigin) else {
            decisionHandler(.cancel)
            onDenied(
                RouteDenialPresentation(
                    reason: .originDenied,
                    title: "Route unavailable",
                    message: "This navigation left the declared allowlisted origin.",
                    hint: "Retry or return to a safe fallback route.",
                    routeID: session.routeID,
                    actions: [
                        .retry,
                        .safeFallback(Self.fallbackURL(for: session))
                    ]
                )
            )
            return
        }

        decisionHandler(.allow)
    }

    static func isNavigationAllowed(_ url: URL, allowedOrigin: URL) -> Bool {
        url.crosswakeOrigin == allowedOrigin.crosswakeOrigin
    }

    private func loadRouteIfNeeded() {
        guard Self.isNavigationAllowed(session.url, allowedOrigin: session.allowedOrigin) else {
            onDenied(
                RouteDenialPresentation(
                    reason: .originDenied,
                    title: "Route unavailable",
                    message: "This route is outside the declared same-origin boundary.",
                    hint: "Open a declared safe fallback route instead.",
                    routeID: session.routeID,
                    actions: [
                        .retry,
                        .safeFallback(Self.fallbackURL(for: session))
                    ]
                )
            )
            return
        }

        var request = URLRequest(url: session.url)
        request.setValue(session.threadID, forHTTPHeaderField: "X-Crosswake-Thread-Id")
        webView.load(request)
    }

    private static func fallbackURL(for session: LiveViewSession) -> URL {
        session.allowedOrigin.appending(path: session.url.path)
    }
}
