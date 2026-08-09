import Foundation
import WebKit

/// The sole WebKit delivery boundary for D-04. Decode happens before the main-actor
/// hop; all state and authorization remain in `NavigationCoordinator`.
public final class NavigationTransitionChannel: NSObject, WKScriptMessageHandler {
    public static let handlerName = "crosswakeNavigation"
    private let coordinator: NavigationCoordinator

    @MainActor public init(coordinator: NavigationCoordinator) {
        self.coordinator = coordinator
        super.init()
    }

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let transition = NavigationTransition.decode(body: message.body) else { return }
        Task { @MainActor [coordinator] in _ = coordinator.apply(transition) }
    }

    @MainActor public func submit(_ body: Any) -> NavigationTransitionOutcome {
        guard let transition = NavigationTransition.decode(body: body) else { return .denied }
        return coordinator.apply(transition)
    }
}
