import SwiftUI
import UIKit
import WebKit

struct LiveViewContainerView: UIViewControllerRepresentable {
    let session: LiveViewSession
    let transferCoordinator: TransferCoordinator?
    let onDenied: (RouteDenialPresentation) -> Void

    func makeUIViewController(context: Context) -> LiveViewContainerViewController {
        LiveViewContainerViewController(
            session: session,
            transferCoordinator: transferCoordinator,
            onDenied: onDenied
        )
    }

    func updateUIViewController(_ uiViewController: LiveViewContainerViewController, context: Context) {
        uiViewController.update(session: session, transferCoordinator: transferCoordinator)
    }
}

final class LiveViewContainerViewController: UIViewController, WKNavigationDelegate {
    private let onDenied: (RouteDenialPresentation) -> Void
    private var session: LiveViewSession
    private var transferCoordinator: TransferCoordinator?
    private lazy var bridgeChannel = BridgeChannel(
        session: session,
        transferCoordinator: transferCoordinator,
        replySink: { _ in },
        appInfoProvider: {
            let info = Bundle.main.infoDictionary
            return [
                "version": info?["CFBundleShortVersionString"] as? String ?? "",
                "build": info?["CFBundleVersion"] as? String ?? "",
                "bundle_id": info?["CFBundleIdentifier"] as? String ?? ""
            ]
        },
        hapticsHandler: { styleString in
            let style: UIImpactFeedbackGenerator.FeedbackStyle
            switch styleString {
            case "light": style = .light
            case "heavy": style = .heavy
            case "medium": fallthrough
            default: style = .medium
            }
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        },
        shareHandler: { [weak self] payload in
            var items: [Any] = []
            if let text = payload["text"] { items.append(text) }
            if let urlString = payload["url"], let url = URL(string: urlString) { items.append(url) }
            if items.isEmpty { return }
            
            let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
            if let title = payload["title"] {
                activityVC.setValue(title, forKey: "subject")
            }
            if let popover = activityVC.popoverPresentationController, let view = self?.view {
                popover.sourceView = view
                popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            self?.present(activityVC, animated: true)
        },
        filesPickHandler: { payload in payload }
    )
    private lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()

        userContentController.add(bridgeChannel, name: BridgeChannel.handlerName)
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
        transferCoordinator: TransferCoordinator?,
        onDenied: @escaping (RouteDenialPresentation) -> Void
    ) {
        self.session = session
        self.transferCoordinator = transferCoordinator
        self.onDenied = onDenied
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadRouteIfNeeded()
    }

    func update(session: LiveViewSession, transferCoordinator: TransferCoordinator?) {
        guard self.session != session || self.transferCoordinator !== transferCoordinator else { return }
        self.session = session
        self.transferCoordinator = transferCoordinator
        bridgeChannel.update(session: session)
        loadRouteIfNeeded()
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

        webView.load(URLRequest(url: session.url))
    }

    private static func fallbackURL(for session: LiveViewSession) -> URL {
        session.allowedOrigin.appending(path: session.url.path)
    }
}
