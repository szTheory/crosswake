import Foundation
import Combine
import SwiftUI
import WebKit

/// The iOS half of the bridge REPLY return leg (D-02).
///
/// The `WKScriptMessageHandler` API is send-only by design: the page can post into the
/// shell, but nothing carries a reply back. Android has been duplex since day one (its
/// `WebMessageListener` hands the page a `replyProxy`); on iOS the only way home is to
/// evaluate JavaScript against the hook's landing pad.
///
/// Everything here is `nonisolated` so a host can build a sink off the main actor and
/// so the unit tests can exercise the serialization without a WebView.
public enum BridgeReplyDelivery {
    /// The exact JavaScript the native side calls back into.
    ///
    /// This name is part of the shipped client/native contract: renaming it after
    /// release means every shell binary in the field is calling a function that no
    /// longer exists (D-02). It is defined once, here, and matched by
    /// `LANDING_PAD` in `priv/static/crosswake.esm.js`.
    public static let landingPad = "window.crosswakeBridge.__reply"

    /// Builds the JavaScript that delivers `reply` to the hook's landing pad, or
    /// `nil` when the envelope cannot be serialized.
    ///
    /// The envelope is serialized with the platform JSON encoder and embedded as a
    /// JSON **string literal** that the evaluated script parses back into data. The
    /// envelope's fields are never interpolated into script source text: a denial
    /// message is host-influenced content, and string-concatenating it into evaluated
    /// JavaScript is a script-injection boundary into the adopter's own origin
    /// (T-154-23, the highest-severity threat in this plan).
    ///
    /// A `nil` return means NO script is evaluated at all — a serialization failure
    /// must never degrade into evaluating a partially built string.
    ///
    /// - Parameter encode: seam for injecting a failing encoder in tests.
    public static func script(
        for reply: BridgeReplyEnvelope,
        encode: (BridgeReplyEnvelope) throws -> Data = { try JSONEncoder().encode($0) }
    ) -> String? {
        guard let data = try? encode(reply),
              let json = String(data: data, encoding: .utf8),
              let literal = jsonStringLiteral(json) else {
            return nil
        }

        return "if (\(landingPad) && typeof \(landingPad) === 'function') { \(landingPad)(JSON.parse(\(literal))); }"
    }

    /// Wraps a host-supplied "run this script" closure into a reply sink.
    ///
    /// The host supplies only HOW to run a script (typically
    /// `webView.evaluateJavaScript`); the library owns WHAT script and how it is
    /// serialized, so no host has to rediscover the injection-safety rules above.
    public static func sink(
        evaluate: @escaping (String) -> Void
    ) -> (BridgeReplyEnvelope) -> Void {
        { reply in
            guard let script = script(for: reply) else { return }
            evaluate(script)
        }
    }

    /// Serializes `text` as a JSON string literal that is safe to embed in evaluated
    /// JavaScript source.
    ///
    /// JSON string escaping already neutralizes quotes, backslashes, and control
    /// characters including newlines. U+2028 and U+2029 are legal *inside* a JSON
    /// string but are JavaScript line terminators to pre-ES2019 parsers, so they are
    /// escaped explicitly — a raw one could otherwise terminate the statement and let
    /// the remainder of a host-influenced message be parsed as source.
    private static func jsonStringLiteral(_ text: String) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: text, options: [.fragmentsAllowed]),
              let literal = String(data: data, encoding: .utf8) else {
            return nil
        }

        return literal
            .replacingOccurrences(of: "\u{2028}", with: "\\u2028")
            .replacingOccurrences(of: "\u{2029}", with: "\\u2029")
    }
}

@MainActor
public final class CrosswakeShell: ObservableObject {
    @Published public var presentation: ShellPresentation = .booting
    @Published public var connectionState: ConnectionState = .disconnected
    public let serverEvents = PassthroughSubject<ServerEvent, Never>()
    
    public let coordinator: ActivationCoordinator
    /// Shell state is published for the host-owned UIKit composition only. It carries
    /// no host labels, route payloads, browser history, or identity facts.
    public lazy var navigationCoordinator = coordinator.makeNavigationCoordinator(topology: Self.loadNavigationTopology(bundle: bundle))
    private let config: CrosswakeShellConfig
    private let bundle: Bundle
    private var cancellables = Set<AnyCancellable>()

    public init(config: CrosswakeShellConfig, bundle: Bundle = .main) {
        self.config = config
        self.bundle = bundle
        self.coordinator = ActivationCoordinator.bundled(bundle: bundle, config: config)

        self.coordinator.$presentation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newPresentation in
                self?.presentation = newPresentation
            }
            .store(in: &cancellables)
    }

    /// Creates the one dedicated D-04 WebKit delivery channel. It is intentionally
    /// separate from `BridgeChannel` and has no request/reply capability authority.
    public func createNavigationTransitionChannel() -> NavigationTransitionChannel {
        NavigationTransitionChannel(coordinator: navigationCoordinator)
    }

    public func createBridgeChannel(
        session: LiveViewSession,
        transferCoordinator: TransferCoordinator?,
        replySink: @escaping (BridgeReplyEnvelope) -> Void
    ) -> BridgeChannel {
        BridgeChannel(
            session: session,
            transferCoordinator: transferCoordinator,
            replySink: replySink,
            config: config,
            connectionStateSink: { [weak self] state in
                Task { @MainActor in
                    self?.connectionState = state
                }
            },
            eventSink: { [weak self] event in
                Task { @MainActor in
                    self?.serverEvents.send(event)
                }
            }
        )
    }

    /// Creates a bridge channel whose reply sink already closes the return leg.
    ///
    /// Prefer this over the `replySink:` overload: it is the default construction
    /// that does the right thing, so a host never has to rediscover the
    /// injection-safe serialization in `BridgeReplyDelivery.script(for:encode:)`.
    /// The host supplies only how to run a script against its own WebView.
    public func createBridgeChannel(
        session: LiveViewSession,
        transferCoordinator: TransferCoordinator?,
        evaluateJavaScript: @escaping (String) -> Void
    ) -> BridgeChannel {
        createBridgeChannel(
            session: session,
            transferCoordinator: transferCoordinator,
            replySink: BridgeReplyDelivery.sink(evaluate: evaluateJavaScript)
        )
    }

    public func bootstrap(intent: URL? = nil) {
        if let intent = intent {
            coordinator.openURL(intent)
        } else {
            coordinator.bootstrapIfNeeded()
        }
    }

    private static func loadNavigationTopology(bundle: Bundle) -> NavigationTopology {
        guard let url = bundle.url(forResource: "navigation_topology", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let topology = try? JSONDecoder().decode(NavigationTopology.self, from: data) else {
            return NavigationTopology(topologySchemaVersion: "0.0.0", manifestSchemaVersion: "0.0.0", status: .unknownBlocking, entries: [])
        }
        return topology
    }
}
