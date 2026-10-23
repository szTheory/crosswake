# v25 stack decision

Use the repository's supported Elixir/Phoenix/Plug/Ecto, existing browser/IndexedDB code, Swift package, host-owned WKWebView/AVFoundation adapters, XCTest/XCUITest and Playwright. No new framework, testing platform, database engine, companion or dependency upgrade is selected.

Generation uses normal Mix build configuration and compilation; explicitly avoid evaluating unrelated `runtime.exs` or starting the host. [CONFIG-LOADING-RESOLUTION.md](CONFIG-LOADING-RESOLUTION.md) and [build-config-experiment.json](build-config-experiment.json) resolve the lifecycle choice. The fixture is dependency-free and does not establish full host compatibility.

Native identity/signing projection uses Xcode configuration files and effective build-setting checks. Origins remain canonical manifest JSON. The generated candidate must bind the actual resolved native package, app build, WebView assets and backend source; a public SwiftPM mirror pin cannot be silently relabeled as local candidate code.

Audio uses the existing registered host-command extension and host-owned native adapter. No new public audio capability, native file service or generic storage layer. Crosswake remains route policy plus typed low-frequency contracts.

End-to-end runs use a fresh owned instance of the reference host's existing database engine. Sandbox remains appropriate for owned in-process transactional tests, not an assumed transaction shared with external browser/XCTest processes.

One narrow derived twin receipt is the only new reporting contract proposed. It stays outside the unchanged physical promotion path. No general telemetry taxonomy or attestation service.
