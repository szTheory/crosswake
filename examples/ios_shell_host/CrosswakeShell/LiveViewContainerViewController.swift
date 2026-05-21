import SwiftUI
import UIKit
import UniformTypeIdentifiers
import WebKit

struct LiveViewContainerView: UIViewControllerRepresentable {
    let session: LiveViewSession
    let transferCoordinator: TransferCoordinator?
    let notificationTokenProvider: NotificationTokenProvider
    let onDenied: (RouteDenialPresentation) -> Void

    func makeUIViewController(context: Context) -> LiveViewContainerViewController {
        LiveViewContainerViewController(
            session: session,
            transferCoordinator: transferCoordinator,
            notificationTokenProvider: notificationTokenProvider,
            onDenied: onDenied
        )
    }

    func updateUIViewController(_ uiViewController: LiveViewContainerViewController, context: Context) {
        uiViewController.update(
            session: session,
            transferCoordinator: transferCoordinator,
            notificationTokenProvider: notificationTokenProvider
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
    private let onDenied: (RouteDenialPresentation) -> Void
    private var session: LiveViewSession
    private var transferCoordinator: TransferCoordinator?
    private var notificationTokenProvider: NotificationTokenProvider
    private let permissionStatusProvider = PermissionStatusProvider()
    private lazy var filePickerCoordinator = FilePickerCoordinator(
        presenterProvider: { [weak self] in self },
        transferCoordinatorProvider: { [weak self] in self?.transferCoordinator }
    )
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
        permissionStatusProvider: permissionStatusProvider.statusPayload(for:),
        notificationTokenProvider: { [weak self] in
            guard let snapshot = self?.notificationTokenProvider.snapshot() else {
                return .unavailable(
                    reason: "notification_setup_missing",
                    detail: ["detail.registration_state": "unconfigured"]
                )
            }

            switch snapshot {
            case let .available(provider, token, detail):
                return .available(provider: provider, token: token, detail: detail)
            case let .unavailable(reason, detail):
                return .unavailable(reason: reason, detail: detail)
            }
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
        filesPickHandler: { [weak self] payload, correlationID, completion in
            guard let self else {
                completion(
                    .deny(
                        reason: "picker_unavailable",
                        message: "The shell could not present a document picker for this route.",
                        hint: "Retry after the LiveView container is visible."
                    )
                )
                return
            }

            self.filePickerCoordinator.presentPicker(
                payload: payload,
                correlationID: correlationID,
                completion: completion
            )
        }
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
        notificationTokenProvider: NotificationTokenProvider,
        onDenied: @escaping (RouteDenialPresentation) -> Void
    ) {
        self.session = session
        self.transferCoordinator = transferCoordinator
        self.notificationTokenProvider = notificationTokenProvider
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
        filePickerCoordinator.updatePresenter(self)
        loadRouteIfNeeded()
    }

    func update(
        session: LiveViewSession,
        transferCoordinator: TransferCoordinator?,
        notificationTokenProvider: NotificationTokenProvider
    ) {
        guard self.session != session
            || self.transferCoordinator !== transferCoordinator
            || self.notificationTokenProvider !== notificationTokenProvider else { return }

        self.session = session
        self.transferCoordinator = transferCoordinator
        self.notificationTokenProvider = notificationTokenProvider
        filePickerCoordinator.updatePresenter(self)
        bridgeChannel.update(session: session, transferCoordinator: transferCoordinator)
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
