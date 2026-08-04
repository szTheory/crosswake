import XCTest
@testable import CrosswakeShell
import CrosswakeShellCore

@MainActor
final class NavigationShellTests: XCTestCase {
    func testOrderedProductionNavigationProofEmitsClosedMarkers() {
        let coordinator = NavigationShellSyntheticTopology.coordinator()
        var focusMarkers: [String] = []
        let container = NavigationShellViewController(
            navigationCoordinator: coordinator,
            makeLeafController: { _ in UIViewController() },
            accessibilityPost: { _, _ in focusMarkers.append("completed") }
        )
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = container
        window.makeKeyAndVisible()
        container.loadViewIfNeeded()

        XCTAssertTrue(NavigationShellViewController.isSystemContainerContract)
        XCTAssertEqual(container.viewControllers?.count, 2)
        print("PL-IOS-NAV-TOPOLOGY: passed")

        guard let tabs = container.viewControllers as? [UINavigationController],
              let navigation = tabs.first else {
            return XCTFail("cw-nav-proof-containers")
        }
        container.tabBarController(container, didSelect: navigation)

        let navigate = NavigationTransition(
            protocolName: NavigationTransition.protocolName,
            version: NavigationTransition.supportedVersion,
            transitionID: "nav-0000000000000001",
            kind: .pushNavigate,
            routeID: "route-0000000000000003",
            restorationRef: nil
        )
        XCTAssertEqual(coordinator.apply(navigate), .applied)
        container.synchronizeForTesting()
        XCTAssertEqual(navigation.viewControllers.count, 2)
        XCTAssertEqual(coordinator.apply(navigate), .denied)
        XCTAssertEqual(navigation.viewControllers.count, 2)

        let patch = NavigationTransition(
            protocolName: NavigationTransition.protocolName,
            version: NavigationTransition.supportedVersion,
            transitionID: "nav-0000000000000002",
            kind: .pushPatch,
            routeID: "route-0000000000000003",
            restorationRef: nil
        )
        XCTAssertEqual(coordinator.apply(patch), .applied)
        XCTAssertEqual(navigation.viewControllers.count, 2)
        print("PL-IOS-NAV-PATCH-DEPTH: passed")
        print("PL-IOS-NAV-NAVIGATE-ONCE: passed")

        XCTAssertEqual(coordinator.completeNativePop(completed: false), .denied)
        XCTAssertEqual(navigation.viewControllers.count, 2)
        navigation.setViewControllers([navigation.viewControllers[0]], animated: false)
        container.navigationController(navigation, didShow: navigation.topViewController!, animated: false)
        XCTAssertEqual(coordinator.stacks["tab-0000000000000001"]?.count, 1)
        let completedFocusMarkers = focusMarkers
        print("PL-IOS-NAV-RESTORE: passed")

        container.tabBarController(container, didSelect: tabs[1])
        XCTAssertEqual(coordinator.selectedTabID, "tab-0000000000000002")
        container.tabBarController(container, didSelect: navigation)
        XCTAssertEqual(coordinator.selectedTabID, "tab-0000000000000001")
        print("PL-IOS-NAV-TABS-BACK: passed")

        let documentStart = LiveViewContainerViewController.documentStartShellScript
        let layout = LiveViewContainerViewController.layoutDeliveryScript(for: [1, 2, 3, 4, 5])
        XCTAssertTrue(documentStart.contains("cwNativeShell = \"ios\""))
        XCTAssertTrue(layout.contains("5.0px"))
        for key in ["--cw-safe-area-top", "--cw-safe-area-right", "--cw-safe-area-bottom", "--cw-safe-area-left", "--cw-keyboard-inset-bottom"] {
            XCTAssertTrue(documentStart.contains(key))
            XCTAssertTrue(layout.contains(key))
        }
        print("PL-IOS-NAV-MARKER-INSETS: passed")

        XCTAssertEqual(completedFocusMarkers, ["completed"])
        print("PL-IOS-NAV-FOCUS: passed")
    }

    func testSystemContainerContractIsAvailableForValidatedTopologyOnly() {
        XCTAssertTrue(NavigationShellViewController.isSystemContainerContract)
    }

    func testDocumentStartShellContractUsesOnlyFixedMarkerAndFiveDefaults() {
        let script = LiveViewContainerViewController.documentStartShellScript
        XCTAssertTrue(script.contains("cwNativeShell = \"ios\""))
        for key in ["--cw-safe-area-top", "--cw-safe-area-right", "--cw-safe-area-bottom", "--cw-safe-area-left", "--cw-keyboard-inset-bottom"] { XCTAssertTrue(script.contains(key)) }
    }

    func testLayoutDeliveryKeepsFourSafeAreaFactsSeparateFromKeyboard() {
        let script = LiveViewContainerViewController.layoutDeliveryScript(for: [1, 2, 3, 4, 5])
        for key in ["--cw-safe-area-top", "--cw-safe-area-right", "--cw-safe-area-bottom", "--cw-safe-area-left", "--cw-keyboard-inset-bottom"] {
            XCTAssertTrue(script.contains(key), "cw-layout-\(key)")
        }
        XCTAssertTrue(script.contains("5.0px"), "cw-layout-keyboard-separate")
    }

    func testProductionContainerAuthorizesRootsAndMirrorsOneNavigateWithoutDuplicate() {
        let coordinator = NavigationShellSyntheticTopology.coordinator()
        let container = NavigationShellViewController(navigationCoordinator: coordinator, makeLeafController: { _ in UIViewController() })
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = container
        window.makeKeyAndVisible()
        container.loadViewIfNeeded()
        XCTAssertEqual(container.viewControllers?.count, 2, "cw-nav-roots-mounted")
        guard let tabs = container.viewControllers as? [UINavigationController] else { return XCTFail("cw-nav-tabs-present") }
        container.tabBarController(container, didSelect: tabs[1])
        XCTAssertEqual(coordinator.selectedTabID, "tab-0000000000000002", "cw-nav-tab-selected")
        container.tabBarController(container, didSelect: tabs[0])
        let navigate = NavigationTransition(protocolName: NavigationTransition.protocolName, version: NavigationTransition.supportedVersion, transitionID: "nav-0000000000000001", kind: .pushNavigate, routeID: "route-0000000000000003", restorationRef: nil)
        XCTAssertEqual(coordinator.apply(navigate), .applied, "cw-nav-push-once")
        container.synchronizeForTesting()
        XCTAssertEqual(tabs[0].viewControllers.count, 2, "cw-nav-uikit-depth")
        XCTAssertEqual(coordinator.apply(navigate), .denied, "cw-nav-duplicate-inert")
        XCTAssertEqual(tabs[0].viewControllers.count, 2, "cw-nav-duplicate-depth")
    }

    func testPatchAndCancelledThenCompletedPopPreserveProductionStackAndFocus() {
        let coordinator = NavigationShellSyntheticTopology.coordinator()
        var focusMarkers: [String] = []
        let container = NavigationShellViewController(navigationCoordinator: coordinator, makeLeafController: { _ in UIViewController() }, accessibilityPost: { _, _ in focusMarkers.append("cw-navigation-focus-completed") })
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = container
        window.makeKeyAndVisible()
        container.loadViewIfNeeded()
        guard let navigation = container.viewControllers?.first as? UINavigationController else { return XCTFail("cw-nav-stack-present") }
        container.tabBarController(container, didSelect: navigation)
        let navigate = NavigationTransition(protocolName: NavigationTransition.protocolName, version: NavigationTransition.supportedVersion, transitionID: "nav-0000000000000001", kind: .pushNavigate, routeID: "route-0000000000000003", restorationRef: nil)
        XCTAssertEqual(coordinator.apply(navigate), .applied)
        container.synchronizeForTesting()
        let patch = NavigationTransition(protocolName: NavigationTransition.protocolName, version: NavigationTransition.supportedVersion, transitionID: "nav-0000000000000002", kind: .pushPatch, routeID: "route-0000000000000003", restorationRef: nil)
        XCTAssertEqual(coordinator.apply(patch), .applied, "cw-nav-patch-applied")
        XCTAssertEqual(navigation.viewControllers.count, 2, "cw-nav-patch-depth-invariant")
        XCTAssertEqual(coordinator.completeNativePop(completed: false), .denied, "cw-nav-pop-cancelled")
        XCTAssertEqual(navigation.viewControllers.count, 2, "cw-nav-pop-cancelled-depth")
        navigation.setViewControllers([navigation.viewControllers[0]], animated: false)
        container.navigationController(navigation, didShow: navigation.topViewController!, animated: false)
        XCTAssertEqual(coordinator.stacks["tab-0000000000000001"]?.count, 1, "cw-nav-pop-completed-depth")
        XCTAssertEqual(focusMarkers.count, 1, "cw-nav-focus-once")
    }
}
