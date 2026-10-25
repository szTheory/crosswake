import XCTest
import WebKit
@testable import CrosswakeShell

/// Unit tests for the identity-checked visible study WebView and the closed host-local
/// observation log. They use real WKWebView instances and real script messages; the
/// primary origin is established with loadHTMLString(baseURL:), so no network is used.
@MainActor
final class StudyWebViewControllerTests: XCTestCase {
    private let primary = URL(string: "http://127.0.0.1:4790")!

    private func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("twin-observe-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    private func makeWebView(handler: WKScriptMessageHandler) -> WKWebView {
        let configuration = StudyWebViewController.makeConfiguration(
            capabilities: ["host.study.audio.play": "1.0.0"],
            threadID: "thread-test",
            handler: handler
        )
        return WKWebView(frame: CGRect(x: 0, y: 0, width: 320, height: 480), configuration: configuration)
    }

    private func loadAndWaitForDecision(
        _ webView: WKWebView,
        html: String,
        baseURL: URL,
        gate: StudyBridgeGate
    ) async {
        let decided = expectation(description: "gate decision")
        gate.onDecision = { _ in decided.fulfill() }
        webView.loadHTMLString(html, baseURL: baseURL)
        await fulfillment(of: [decided], timeout: 10)
    }

    private let postScript = "<script>window.webkit.messageHandlers.crosswakeBridge.postMessage('{}');</script>"

    func testForwardsMessageFromOwnMainFrameAtPrimaryOrigin() async {
        var forwarded = 0
        let gate = StudyBridgeGate(primaryOrigin: primary) { _, _ in forwarded += 1 }
        let webView = makeWebView(handler: gate)
        gate.expectedWebView = webView

        await loadAndWaitForDecision(webView, html: postScript, baseURL: primary, gate: gate)

        XCTAssertEqual(forwarded, 1)
        XCTAssertEqual(gate.forwardedCount, 1)
        XCTAssertEqual(gate.rejectedCount, 0)
    }

    func testDropsMessageFromADifferentWebView() async {
        var forwarded = 0
        let gate = StudyBridgeGate(primaryOrigin: primary) { _, _ in forwarded += 1 }
        let other = makeWebView(handler: gate)
        gate.expectedWebView = makeWebView(handler: StudyBridgeGate(primaryOrigin: primary) { _, _ in })

        await loadAndWaitForDecision(other, html: postScript, baseURL: primary, gate: gate)

        XCTAssertEqual(forwarded, 0)
        XCTAssertEqual(gate.rejectedCount, 1)
    }

    func testDropsMessageFromANonMainFrame() async {
        var forwarded = 0
        let gate = StudyBridgeGate(primaryOrigin: primary) { _, _ in forwarded += 1 }
        let webView = makeWebView(handler: gate)
        gate.expectedWebView = webView
        // A same-origin child frame posts through its own window; WebKit reports it as a non-main frame.
        let frameHTML = """
        <body><script>
        var child = document.createElement('iframe');
        document.body.appendChild(child);
        child.contentWindow.webkit.messageHandlers.crosswakeBridge.postMessage('{}');
        </script></body>
        """

        await loadAndWaitForDecision(webView, html: frameHTML, baseURL: primary, gate: gate)

        XCTAssertEqual(forwarded, 0)
        XCTAssertEqual(gate.rejectedCount, 1)
    }

    func testDropsMessageWhoseSecurityOriginDiffers() async {
        var forwarded = 0
        let gate = StudyBridgeGate(primaryOrigin: primary) { _, _ in forwarded += 1 }
        let webView = makeWebView(handler: gate)
        gate.expectedWebView = webView

        await loadAndWaitForDecision(webView, html: postScript, baseURL: URL(string: "http://127.0.0.1:4791")!, gate: gate)

        XCTAssertEqual(forwarded, 0)
        XCTAssertEqual(gate.rejectedCount, 1)
    }

    func testOriginComparisonIsExactOnSchemeHostAndPort() {
        let ok = StudyFrameFacts(isOwnWebView: true, isMainFrame: true, scheme: "http", host: "127.0.0.1", port: 4790)
        XCTAssertEqual(StudyBridgeGate.verdict(for: ok, primaryOrigin: primary), .forward)

        var wrongScheme = ok; wrongScheme.scheme = "https"
        var wrongHost = ok; wrongHost.host = "localhost"
        var wrongPort = ok; wrongPort.port = 80
        var notOwn = ok; notOwn.isOwnWebView = false
        var notMain = ok; notMain.isMainFrame = false
        for facts in [wrongScheme, wrongHost, wrongPort, notOwn, notMain] {
            XCTAssertEqual(StudyBridgeGate.verdict(for: facts, primaryOrigin: primary), .reject)
        }
    }

    func testConfigurationUsesDefaultPersistentDataStore() {
        let configuration = StudyWebViewController.makeConfiguration(
            capabilities: [:],
            threadID: "t",
            handler: StudyBridgeGate(primaryOrigin: primary) { _, _ in }
        )
        XCTAssertTrue(configuration.websiteDataStore === WKWebsiteDataStore.default())
        XCTAssertTrue(configuration.websiteDataStore.isPersistent)
    }

    func testPathClassNeverCarriesTheURL() {
        XCTAssertEqual(StudyWebObserver.pathClass(for: URL(string: "http://127.0.0.1:4790/offline?scope=secret")), "study")
        XCTAssertEqual(StudyWebObserver.pathClass(for: URL(string: "http://127.0.0.1:4790/offline/review")), "review")
        XCTAssertEqual(StudyWebObserver.pathClass(for: URL(string: "http://127.0.0.1:4790/anything")), "other")
        XCTAssertEqual(StudyWebObserver.pathClass(for: nil), "other")
    }

    func testObservationLogWritesNothingWhenEnvironmentIsUnset() throws {
        let dir = try makeTempDirectory()
        let log = TwinObservationLog(environment: [:], directory: dir)
        XCTAssertFalse(log.append(channel: .webview, kind: "bridge_forwarded", value: .count(1)))
        log.appendLaunchSample()
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: dir.path), [])
    }

    func testObservationLogRejectsRecordsOutsideItsClosedVocabulary() throws {
        let dir = try makeTempDirectory()
        let log = TwinObservationLog(environment: ["CROSSWAKE_TWIN_OBSERVE": "1"], directory: dir)
        XCTAssertFalse(log.append(channel: .webview, kind: "answer_text", value: .count(1)))
        XCTAssertFalse(log.append(channel: .webview, kind: "bridge_forwarded", value: .count(1_000_001)))
        XCTAssertFalse(log.append(channel: .webview, kind: "bridge_forwarded", value: .count(-1)))
        XCTAssertFalse(log.append(channel: .webview, kind: "route_path", value: .word("http://127.0.0.1:4790/offline")))
        XCTAssertFalse(log.append(channel: .webview, kind: "bridge_forwarded", value: .word("passed")))
        XCTAssertFalse(log.append(channel: .hostAdapter, kind: "TW-T01-01", value: .word("maybe")))
        XCTAssertFalse(log.append(channel: .hostAdapter, kind: "bridge_forwarded", value: .count(1)))
        XCTAssertFalse(log.append(channel: .webview, kind: "outbox_active", value: .count(0), cause: "token=abc"))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: dir.path), [])
    }

    func testObservationLogWritesEachChannelToItsOwnFileWithExactlyFiveKeys() throws {
        let dir = try makeTempDirectory()
        let log = TwinObservationLog(environment: ["CROSSWAKE_TWIN_OBSERVE": "1"], directory: dir)
        XCTAssertTrue(log.append(channel: .hostAdapter, kind: "TW-T01-01", value: .word("passed")))
        XCTAssertTrue(log.append(channel: .webview, kind: "island_state", value: .word("saved_local")))
        XCTAssertTrue(log.append(channel: .webview, kind: "outbox_active", value: .count(0), cause: "probe_invalid"))

        XCTAssertEqual(
            Set(try FileManager.default.contentsOfDirectory(atPath: dir.path)),
            ["twin-host-adapter.jsonl", "twin-webview.jsonl"]
        )
        let lines = try String(contentsOf: dir.appendingPathComponent("twin-webview.jsonl"), encoding: .utf8)
            .split(separator: "\n")
        XCTAssertEqual(lines.count, 2)
        for line in lines {
            let record = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any])
            XCTAssertEqual(Set(record.keys), ["kind", "launch", "seq", "value", "cause"])
        }
        let second = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(lines[1].utf8)) as? [String: Any])
        XCTAssertEqual(second["seq"] as? Int, 2)
        XCTAssertEqual(second["cause"] as? String, "probe_invalid")
    }

    func testEachProcessStartAppendsExactlyOneLaunchSampleWithTheProcessIdentifier() throws {
        let dir = try makeTempDirectory()
        let log = TwinObservationLog(environment: ["CROSSWAKE_TWIN_OBSERVE": "1"], directory: dir)
        log.appendLaunchSample(processIdentifier: 4242)
        let text = try String(contentsOf: dir.appendingPathComponent("twin-app-process.jsonl"), encoding: .utf8)
        let lines = text.split(separator: "\n")
        XCTAssertEqual(lines.count, 1)
        let record = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(lines[0].utf8)) as? [String: Any])
        XCTAssertEqual(record["kind"] as? String, "launch")
        XCTAssertEqual(record["value"] as? Int, 4242)
        XCTAssertEqual(record["launch"] as? Int, 1)

        let nextProcess = TwinObservationLog(environment: ["CROSSWAKE_TWIN_OBSERVE": "1"], directory: dir)
        nextProcess.appendLaunchSample(processIdentifier: 4343)
        let after = try String(contentsOf: dir.appendingPathComponent("twin-app-process.jsonl"), encoding: .utf8)
        XCTAssertEqual(after.split(separator: "\n").count, 2)
    }
}
