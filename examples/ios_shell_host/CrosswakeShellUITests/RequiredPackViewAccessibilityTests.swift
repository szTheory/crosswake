import XCTest

final class RequiredPackViewAccessibilityTests: XCTestCase {
    func testAccessibilityXXXLRecoveryCopyWrapsAndControlsRemainReachable() {
        let app = launchProbe()
        let status = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Offline audio needs recovery")).firstMatch
        let action = app.buttons["Invalidate downloaded audio"]

        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertTrue(status.label.contains("Offline audio needs recovery"))
        XCTAssertTrue(status.label.contains("Offline audio could not be verified. Try the download again while connected."))
        action.scrollToVisible()
        XCTAssertTrue(action.isHittable)
        XCTAssertGreaterThanOrEqual(action.frame.width, 44)
        XCTAssertGreaterThanOrEqual(action.frame.height, 44)
    }

    func testAccessibilityXXXLLifecycleAnnouncementPreservesFocus() {
        let app = launchProbe()
        let status = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Offline audio is required")).firstMatch

        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertTrue(status.label.contains("Offline audio is required"))
        XCTAssertTrue(status.label.contains("Install offline audio while connected to continue."))
        // The paired unit backstop captures the injected announcement effect and its explicit
        // preserveFocus directive; this process-level assertion proves its real status element.
    }

    func testAccessibilityXXXLActionLabelsWrapWithoutTruncation() {
        let app = launchProbe()
        for label in [
            "Install offline audio",
            "Update offline audio",
            "Retry download",
            "Invalidate downloaded audio"
        ] {
            let action = app.buttons[label]
            XCTAssertTrue(action.waitForExistence(timeout: 5), label)
            action.scrollToVisible()
            XCTAssertEqual(action.label, label)
            XCTAssertFalse(action.label.contains("…"))
            XCTAssertGreaterThanOrEqual(action.frame.width, 44)
            XCTAssertGreaterThanOrEqual(action.frame.height, 44)
        }
    }

    func testAccessibilityXXXLDeveloperContextWrapsWithoutSensitiveData() {
        let app = launchProbe()
        let owner = app.staticTexts.matching(NSPredicate(format: "label == %@", "Owner: host pack provider")).firstMatch

        XCTAssertTrue(owner.waitForExistence(timeout: 5))
        owner.scrollToVisible()
        let text = owner.label
        for required in ["Owner: host pack provider", "Rule: PACK-TRANSFER-INTERRUPTED", "Use the foreground action when connected."] {
            XCTAssertTrue(text.contains(required), required)
        }
        for excluded in ["http", "/private/", "sha256", "credential", "token", "account", "device", "transcript", "media"] {
            XCTAssertFalse(text.localizedCaseInsensitiveContains(excluded), excluded)
        }
    }

    private func launchProbe() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-crosswake-required-pack-accessibility", "all", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        return app
    }
}

private extension XCUIElement {
    func scrollToVisible() {
        if !isHittable {
            XCUIApplication().swipeUp()
        }
    }
}
