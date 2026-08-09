import XCTest

/// Advisory simulator coverage only. It deliberately creates no attachments, screenshots,
/// route history, or retained device-output artifact.
final class NavigationShellTests: XCTestCase {
    func testSyntheticProductionNavigationFlow() {
        let app = XCUIApplication()
        app.launchArguments = ["-crosswake-navigation-synthetic"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons.element(boundBy: 1).waitForExistence(timeout: 5), "cw-ui-tabs")
        app.tabBars.buttons.element(boundBy: 1).tap()
        app.buttons["Navigate"].tap()
        XCTAssertTrue(app.otherElements["cw-navigation-push-completed"].waitForExistence(timeout: 2), "cw-ui-push")
        app.buttons["Patch"].tap()
        XCTAssertTrue(app.otherElements["cw-navigation-patch-depth-invariant"].waitForExistence(timeout: 2), "cw-ui-patch")
    }

    func testRequiredPackProbeRemainsReachableAtAccessibilitySize() {
        let app = XCUIApplication()
        app.launchArguments = ["-crosswake-required-pack-accessibility", "install", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let action = app.buttons["Install offline audio"]
        XCTAssertTrue(action.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(action.frame.width, 44)
        XCTAssertGreaterThanOrEqual(action.frame.height, 44)
    }
}
