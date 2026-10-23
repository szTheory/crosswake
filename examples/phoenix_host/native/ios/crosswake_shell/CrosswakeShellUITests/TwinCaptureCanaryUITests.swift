import XCTest

/// Capture canary for the bounded digital-twin run.
///
/// It exists only so the runner can prove, before any study payload exists, that a failing
/// UI test leaves no screenshot, recording or other attachment in its result bundle under
/// the TwinJourney test plan. It launches the app without observation or a study context,
/// waits for the first screen, and fails on purpose with a fixed message. The runner
/// expects this one test to fail and requires zero exported attachments afterwards.
final class TwinCaptureCanaryUITests: XCTestCase {
    func test_capture_canary() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        XCTFail("Intentional capture canary failure on a payload-free screen.")
    }
}
