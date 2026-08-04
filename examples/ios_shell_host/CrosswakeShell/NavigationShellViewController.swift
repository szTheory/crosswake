import Combine
import CrosswakeShellCore
import SwiftUI
import UIKit

/// Keeps UIKit callbacks narrow: host presentation remains outside this protocol.
@MainActor
protocol NavigationShellControllerDelegate: AnyObject {
    func navigationShellDidCompleteNavigation(_ controller: NavigationShellViewController)
}

/// Standard UIKit tabs and stacks for an already-authorized, compiled topology.
/// This controller never matches routes or creates a generic web renderer.
@MainActor
final class NavigationShellViewController: UITabBarController, UITabBarControllerDelegate, UINavigationControllerDelegate {
    static let isSystemContainerContract = true

    weak var shellDelegate: NavigationShellControllerDelegate?
    private let navigationCoordinator: NavigationCoordinator
    private let makeLeafController: (ShellPresentation) -> UIViewController
    private var controllerByEntry: [String: UIViewController] = [:]
    private var navigationControllerByRoot: [String: UINavigationController] = [:]
    private var rootRouteByNavigationController: [ObjectIdentifier: String] = [:]
    private var cancellable: AnyCancellable?
    private var isSynchronizing = false
    private var lastFocusedController: UIViewController?
    private let accessibilityPost: (UIAccessibility.Notification, Any?) -> Void
    private let navigationObservation: (String) -> Void

    init(
        navigationCoordinator: NavigationCoordinator,
        makeLeafController: @escaping (ShellPresentation) -> UIViewController,
        accessibilityPost: @escaping (UIAccessibility.Notification, Any?) -> Void = { notification, argument in
            UIAccessibility.post(notification: notification, argument: argument)
        },
        navigationObservation: @escaping (String) -> Void = { _ in }
    ) {
        self.navigationCoordinator = navigationCoordinator
        self.makeLeafController = makeLeafController
        self.accessibilityPost = accessibilityPost
        self.navigationObservation = navigationObservation
        super.init(nibName: nil, bundle: nil)
        delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        mountValidatedRoots()
        cancellable = navigationCoordinator.$stacks.sink { [weak self] _ in self?.synchronizeFromCoordinator() }
    }

    private func mountValidatedRoots() {
        let roots = navigationCoordinator.rootRouteIDs
        guard roots.isEmpty == false else {
            viewControllers = []
            return
        }

        let controllers = roots.compactMap { rootRouteID -> UINavigationController? in
            guard navigationCoordinator.selectRoot(routeID: rootRouteID) == .authorized,
                  let entry = navigationCoordinator.stacks.values.flatMap({ $0 }).first(where: { $0.routeID == rootRouteID }) else {
                return nil
            }
            let navigation = UINavigationController(rootViewController: leafController(for: entry))
            navigation.tabBarItem.accessibilityIdentifier = "cw-native-tab-\(rootRouteID)"
            navigation.delegate = self
            navigationControllerByRoot[rootRouteID] = navigation
            rootRouteByNavigationController[ObjectIdentifier(navigation)] = rootRouteID
            return navigation
        }
        viewControllers = controllers
        if let first = controllers.first { selectedViewController = first }
    }

    private func leafController(for entry: NavigationStackEntry) -> UIViewController {
        if let retained = controllerByEntry[entry.routeID] { return retained }
        let controller = makeLeafController(entry.presentation)
        controllerByEntry[entry.routeID] = controller
        return controller
    }

    private func synchronizeFromCoordinator() {
        guard isSynchronizing == false else { return }
        isSynchronizing = true
        defer { isSynchronizing = false }
        let retainedIDs = Set(navigationCoordinator.stacks.values.flatMap { $0.map(\.routeID) })

        for (rootRouteID, navigation) in navigationControllerByRoot {
            guard let stack = navigationCoordinator.stacks.values.first(where: { $0.first?.routeID == rootRouteID }) else { continue }
            let desired = stack.map(leafController(for:))
            if navigation.viewControllers.map(ObjectIdentifier.init) != desired.map(ObjectIdentifier.init) {
                navigation.setViewControllers(desired, animated: false)
            }
        }
        controllerByEntry = controllerByEntry.filter { retainedIDs.contains($0.key) }
    }

    /// Internal host-test seam: invokes the same coordinator subscription body after
    /// direct transition driving, without adding an alternate stack authority.
    func synchronizeForTesting() {
        synchronizeFromCoordinator()
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard isSynchronizing == false,
              let navigation = viewController as? UINavigationController,
              let rootRouteID = rootRouteByNavigationController[ObjectIdentifier(navigation)],
              navigationCoordinator.selectRoot(routeID: rootRouteID) == .authorized else { return }
        announceCompletedNavigation(target: navigation.topViewController)
    }

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        guard isSynchronizing == false,
              let rootRouteID = rootRouteByNavigationController[ObjectIdentifier(navigationController)],
              let expected = navigationCoordinator.stacks.values.first(where: { $0.first?.routeID == rootRouteID })?.last,
              controllerByEntry[expected.routeID] !== viewController else { return }
        guard navigationCoordinator.completeNativePop(completed: true) == .authorized else { return }
        announceCompletedNavigation(target: viewController)
    }

    private func announceCompletedNavigation(target: UIViewController?) {
        guard let target, target !== lastFocusedController else { return }
        lastFocusedController = target
        accessibilityPost(.screenChanged, target.view)
        navigationObservation("cw-navigation-focus-completed")
        shellDelegate?.navigationShellDidCompleteNavigation(self)
    }
}

struct NavigationShellView: UIViewControllerRepresentable {
    let navigationCoordinator: NavigationCoordinator
    let makeLeafController: (ShellPresentation) -> UIViewController

    func makeUIViewController(context: Context) -> NavigationShellViewController {
        NavigationShellViewController(navigationCoordinator: navigationCoordinator, makeLeafController: makeLeafController)
    }

    func updateUIViewController(_ uiViewController: NavigationShellViewController, context: Context) {}
}
