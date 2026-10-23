// Test-owned probe for the Phase 182 loopback Simulator harness (D-17.7).
// Replaces only the host-owned CrosswakeShellApp.swift. It loads the generated
// activation url (or PROBE_URL when the launcher sets SIMCTL_CHILD_PROBE_URL)
// in a WKWebView and records the navigation result in NSTemporaryDirectory().
import SwiftUI
import WebKit

private func probeResultURL() -> URL {
    URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("result.txt")
}

private func record(_ text: String) {
    try? text.write(to: probeResultURL(), atomically: true, encoding: .utf8)
}

private func probeTarget() -> URL? {
    if let override = ProcessInfo.processInfo.environment["PROBE_URL"], !override.isEmpty {
        return URL(string: override)
    }
    guard
        let file = Bundle.main.url(forResource: "route_activation", withExtension: "json"),
        let data = try? Data(contentsOf: file),
        let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let text = object["url"] as? String
    else { return nil }
    return URL(string: text)
}

final class ProbeDelegate: NSObject, WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        record("didFinish")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        record("didFailProvisional \(nsError.domain) \(nsError.code)")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        record("didFail \(nsError.domain) \(nsError.code)")
    }
}

struct ProbeWebView: UIViewRepresentable {
    let delegate = ProbeDelegate()

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView(frame: .zero)
        view.navigationDelegate = delegate
        if let url = probeTarget() {
            view.load(URLRequest(url: url))
        } else {
            record("noTarget")
        }
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

@main
struct CrosswakeShellApp: App {
    var body: some Scene {
        WindowGroup {
            ProbeWebView()
        }
    }
}
