import XCTest

/// Advisory simulator coverage only. It deliberately creates no attachments, screenshots,
/// route history, or retained device-output artifact.
final class NavigationShellTests: XCTestCase {
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
