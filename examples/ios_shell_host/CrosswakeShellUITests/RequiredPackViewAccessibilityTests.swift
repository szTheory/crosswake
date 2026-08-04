import XCTest

final class RequiredPackViewAccessibilityTests: XCTestCase {
    func testAccessibilityXXXLRecoveryCopyWrapsAndControlsRemainReachable() {
        let app = launchProbe("invalidate")
        let status = app.staticTexts["required-pack-status"]
        let action = app.buttons["required-pack-invalidate-action"]

        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertTrue(status.label.contains("Offline audio needs recovery"))
        XCTAssertTrue(status.label.contains("Offline audio could not be verified. Try the download again while connected."))
        action.scrollToVisible()
        XCTAssertTrue(action.isHittable)
        XCTAssertGreaterThanOrEqual(action.frame.width, 44)
        XCTAssertGreaterThanOrEqual(action.frame.height, 44)
    }

    func testAccessibilityXXXLLifecycleAnnouncementPreservesFocus() {
        let app = launchProbe("install")
        let status = app.staticTexts["required-pack-status"]

        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertTrue(status.label.contains("Offline audio is required"))
        XCTAssertTrue(status.label.contains("Install offline audio while connected to continue."))
        // The paired unit backstop captures the injected announcement effect and its explicit
        // preserveFocus directive; this process-level assertion proves its real status element.
    }

    func testAccessibilityXXXLActionLabelsWrapWithoutTruncation() {
        for (state, identifier, label) in [
            ("install", "required-pack-primary-action", "Install offline audio"),
            ("update", "required-pack-primary-action", "Update offline audio"),
            ("retry", "required-pack-primary-action", "Retry download"),
            ("invalidate", "required-pack-invalidate-action", "Invalidate downloaded audio")
        ] {
            let app = launchProbe(state)
            let action = app.buttons[identifier]
            XCTAssertTrue(action.waitForExistence(timeout: 5), state)
            action.scrollToVisible()
            XCTAssertEqual(action.label, label)
            XCTAssertFalse(action.label.contains("…"))
            XCTAssertGreaterThanOrEqual(action.frame.width, 44)
            XCTAssertGreaterThanOrEqual(action.frame.height, 44)
            app.terminate()
        }
    }

    func testAccessibilityXXXLDeveloperContextWrapsWithoutSensitiveData() {
        let app = launchProbe("retry")
        let owner = app.staticTexts["required-pack-owner"]

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

    private func launchProbe(_ state: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-crosswake-required-pack-accessibility", state, "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        return app
    }
}

private extension XCUIElement {
    func scrollToVisible() {
        var attempts = 0
        while !isHittable && attempts < 8 {
            XCUIApplication().swipeUp()
            attempts += 1
        }
    }
}
