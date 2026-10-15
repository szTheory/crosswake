import XCTest

/// Control client for the run-owned loopback fault boundary. The boundary's closed command
/// set is the only thing this reaches; the port comes from the runner through the
/// environment.
private enum TwinControl {
    static var port: Int {
        Int(ProcessInfo.processInfo.environment["CROSSWAKE_TWIN_CONTROL_PORT"] ?? "") ?? 0
    }

    @discardableResult
    static func send(_ method: String, _ path: String) -> Bool {
        guard port > 0, let url = URL(string: "http://127.0.0.1:\(port)\(path)") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 90
        let done = DispatchSemaphore(value: 0)
        var accepted = false
        URLSession.shared.dataTask(with: request) { _, response, _ in
            accepted = (response as? HTTPURLResponse)?.statusCode == 200
            done.signal()
        }.resume()
        done.wait()
        return accepted
    }

    static func pass() -> Bool { send("POST", "/pass") }
    static func refuse() -> Bool { send("POST", "/refuse") }
    static func epoch(_ name: String) -> Bool { send("POST", "/epoch/\(name)") }
    static func fault(_ kind: String) -> Bool { send("POST", "/fault/\(kind)") }
    static func dropNextReplayResponse() -> Bool { send("POST", "/drop_next_response/replay") }
}

/// The ordered twin journey. Each test method is one case. The runner resets the owned app
/// context only between methods; nothing inside a method reinstalls or clears app data.
/// The tests drive visible controls by their accessible labels and the run-owned control
/// port, write no observation, build no attachment and never read or print element values.
final class TwinJourneyUITests: XCTestCase {
    /// Fixed public synthetic text. Never a learner's answer.
    private static let syntheticAnswer = "synthetic study answer"

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        XCTAssertTrue(TwinControl.pass(), "The boundary did not accept pass.")
        XCTAssertTrue(TwinControl.fault("clear"), "The boundary did not accept fault clear.")
    }

    // MARK: Cases

    func test_01_uninterrupted_journey() {
        XCTAssertTrue(TwinControl.epoch("online_install"), "Epoch online_install was not accepted.")
        launch()
        waitForStudy()
        settle(4)  // the foreground install runs while the study opens

        XCTAssertTrue(TwinControl.epoch("offline"), "Epoch offline was not accepted.")
        XCTAssertTrue(TwinControl.refuse(), "The boundary did not accept refuse.")
        settle(4)

        tap(app.buttons["Flip Card"], "Flip Card is not available.")
        tap(app.buttons["Good"], "Good is not available.")
        settle(1)
        saveFreeFormAnswer()
        settle(2)

        XCTAssertTrue(TwinControl.epoch("playback"), "Epoch playback was not accepted.")
        tap(app.buttons["Play pronunciation"], "Play pronunciation is not available.")
        XCTAssertTrue(
            app.staticTexts["Playing pronunciation"].waitForExistence(timeout: 30),
            "The pronunciation did not reach the playing state."
        )
        settle(3)

        XCTAssertTrue(TwinControl.epoch("relaunch"), "Epoch relaunch was not accepted.")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 30), "The app did not relaunch.")
        settle(5)

        XCTAssertTrue(TwinControl.epoch("replay"), "Epoch replay was not accepted.")
        XCTAssertTrue(TwinControl.dropNextReplayResponse(), "The boundary did not accept drop_next_response.")
        XCTAssertTrue(TwinControl.pass(), "The boundary did not accept pass.")
        waitForStudy()
        XCTAssertTrue(
            app.staticTexts["Saved to your account"].waitForExistence(timeout: 90),
            "The saved answers were not confirmed as saved to the account."
        )
        settle(3)
    }

    func test_02_media_faults() {
        XCTAssertTrue(TwinControl.epoch("offline_install"), "Epoch offline_install was not accepted.")
        XCTAssertTrue(TwinControl.refuse(), "The boundary did not accept refuse.")
        launch()
        settle(6)  // the foreground install attempt meets the refusal

        XCTAssertTrue(TwinControl.epoch("media_faults"), "Epoch media_faults was not accepted.")
        XCTAssertTrue(TwinControl.fault("media_missing"), "Fault media_missing was not accepted.")
        XCTAssertTrue(TwinControl.pass(), "The boundary did not accept pass.")
        waitForStudy()
        tap(app.buttons["Play pronunciation"], "Play pronunciation is not available.")
        settle(4)

        XCTAssertTrue(TwinControl.fault("clear"), "Fault clear was not accepted.")
        XCTAssertTrue(TwinControl.fault("media_corrupt"), "Fault media_corrupt was not accepted.")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 30), "The app did not relaunch.")
        waitForStudy()
        settle(3)
        tap(app.buttons["Play pronunciation"], "Play pronunciation is not available.")
        XCTAssertTrue(
            app.staticTexts["Audio unavailable"].waitForExistence(timeout: 30),
            "The audio was not reported unavailable."
        )
        settle(2)
    }

    func test_03_rejection_conflict() {
        XCTAssertTrue(TwinControl.epoch("recovery"), "Epoch recovery was not accepted.")
        launch()
        waitForStudy()

        XCTAssertTrue(TwinControl.fault("replay_reject"), "Fault replay_reject was not accepted.")
        saveFreeFormAnswer()
        XCTAssertTrue(
            app.links["Review saved answers"].waitForExistence(timeout: 60),
            "The rejected answer did not offer the review link."
        )

        XCTAssertTrue(TwinControl.fault("clear"), "Fault clear was not accepted.")
        XCTAssertTrue(TwinControl.fault("replay_conflict"), "Fault replay_conflict was not accepted.")
        saveFreeFormAnswer()
        settle(5)

        tap(app.links["Review saved answers"], "The review link is not available.")
        XCTAssertTrue(
            app.links["Return to study"].waitForExistence(timeout: 30),
            "The review page did not open."
        )
        settle(3)

        XCTAssertTrue(TwinControl.fault("clear"), "Fault clear was not accepted.")
        XCTAssertTrue(TwinControl.fault("replay_disable"), "Fault replay_disable was not accepted.")
        tap(tryAgainButton(), "Try again is not offered.")
        settle(6)

        XCTAssertTrue(TwinControl.fault("clear"), "Fault clear was not accepted.")
        tap(app.links["Return to study"], "Return to study is not available.")
        waitForStudy()
        saveFreeFormAnswer()
        settle(6)

        tap(app.links["Review saved answers"], "The review link is not available.")
        XCTAssertTrue(
            tryAgainButton().waitForExistence(timeout: 30),
            "Try again was not offered after replay became available."
        )
        settle(3)
    }

    func test_04_scope_fence() {
        launch()
        waitForStudy()

        XCTAssertTrue(TwinControl.refuse(), "The boundary did not accept refuse.")
        settle(3)
        saveFreeFormAnswer()
        settle(2)

        XCTAssertTrue(TwinControl.epoch("scope_fence"), "Epoch scope_fence was not accepted.")
        XCTAssertTrue(TwinControl.pass(), "The boundary did not accept pass.")
        XCTAssertTrue(
            app.staticTexts["Paused. Saved answers stay on this device."].waitForExistence(timeout: 90),
            "The island was not paused after the account changed."
        )
        settle(6)
    }

    func test_05_disablement() {
        XCTAssertTrue(TwinControl.epoch("disablement"), "Epoch disablement was not accepted.")
        launch()
        waitForStudy()

        XCTAssertTrue(TwinControl.fault("entry_disable"), "Fault entry_disable was not accepted.")
        saveFreeFormAnswer()
        XCTAssertTrue(
            app.staticTexts["Temporarily unavailable. Your answer is still saved on this device."]
                .waitForExistence(timeout: 60),
            "The disabled entry was not reported as temporarily unavailable."
        )
        settle(4)

        XCTAssertTrue(TwinControl.fault("clear"), "Fault clear was not accepted.")
        XCTAssertTrue(TwinControl.fault("replay_disable"), "Fault replay_disable was not accepted.")
        settle(8)
    }

    // MARK: Helpers

    private func launch() {
        app = XCUIApplication()
        app.launchEnvironment["CROSSWAKE_TWIN_OBSERVE"] = "1"
        app.launchEnvironment["CROSSWAKE_TWIN_CONTROL_PORT"] = String(TwinControl.port)
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 30), "The app did not launch.")
    }

    /// The host reports one bit when the study document is open and its scope is active.
    private func waitForStudy() {
        XCTAssertTrue(
            app.otherElements["twin-ready"].waitForExistence(timeout: 120),
            "The study did not become ready."
        )
    }

    private func answerField() -> XCUIElement {
        let area = app.textViews["Your answer"]
        return area.exists ? area : app.textFields["Your answer"]
    }

    private func saveFreeFormAnswer() {
        let field = answerField()
        XCTAssertTrue(field.waitForExistence(timeout: 30), "The answer field is not available.")
        field.tap()
        field.typeText(Self.syntheticAnswer)
        tap(app.buttons["Save answer"], "Save answer is not available.")
    }

    private func tryAgainButton() -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Try again'")).firstMatch
    }

    private func tap(_ element: XCUIElement, _ message: String) {
        XCTAssertTrue(element.waitForExistence(timeout: 30), message)
        element.tap()
    }

    private func settle(_ seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }
}
