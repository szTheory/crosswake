# v25 Twin Challenge: Generated WebView and Installed Pack

**Scope:** Convergence check of `GENERATION.md`, `DX.md`, and `TWIN-ARCHITECTURE.md` against the approved source. This note adds unresolved composition conflicts only.

## Material contradictions

1. **The proposed origin agreement conflates distinct policies.** `GENERATION.md` IOS-03 says the production origin populates “manifest route allowlists, activation URL, and native-origin policy,” while DX leaves possible auth/media origins open. At the pinned source, `Crosswake.Manifest.Builder` gives route entries the host origin; bridge registry consumes route `allowlisted_origins`; and `LiveViewContainerViewController` separately permits navigation only when the URL origin equals `LiveViewSession.allowedOrigin`. It does not consult a secondary-origin inventory. Thus “route allowlist” is not an available generic place to insert auth or CDN origins, and `WKWebView.limitsNavigationsToAppBoundDomains` is an additional WebKit boundary, not a replacement for the host’s same-origin check.

   **Correction:** define one primary Phoenix origin for generated activation, the manifest host, route/bridge origin, and the current visible WebView navigation gate. Keep auth continuation and media delivery as separately named, exact host-owned dependencies. Do not emit them into route bridge allowlists or relax navigation policy by implication. First verify whether the selected route needs a top-level cross-origin auth navigation or only same-origin authenticated requests. If it needs another origin, the host must explicitly own that path and test it; current reference shell behavior does not support it. Cross-origin audio subresource behavior is also not proven by the navigation delegate. A wildcard or silent expansion invalidates the candidate.

2. **A visible WebView and installed native pack are individually present but not composed.** The reference iOS shell injects `HostPronunciationPackConfiguration.provider()` into `CrosswakeShellConfig`; that provider installs into the app’s `Application Support/CrosswakePronunciation`. The reference physical proof adapter is another lane: it verifies an installed file and calls `AVAudioPlayer`. The visible `WKWebView` loads the route and uses the same-origin navigation gate, but the source shows no assertion or adapter path by which its study island’s `<audio>` consumes bytes installed by that provider. The browser-side study corpus and native pack test are therefore separate real tests, not evidence of an integrated offline-audio path.

   **Narrow experiment:** in the generated candidate, first trace the selected island’s media URL/pack schema and compare it with the installed provider’s verified asset identity. Then run a disposable, host-owned spike that loads the actual route in its visible WebView, blocks external network access, and proves the WebView audio element decoded the exact bytes whose installed size and digest were checked. Keep any test adapter route-specific and read-only. If this requires a reusable native-to-WebView file API, generic scheme/bridge contract, or Crosswake-owned storage layer, stop and return the decision to the host owner; do not fold that product into IOS-01 or declare TWIN-02 complete.

## Evidence boundaries and false greens

Keep three records distinct: (a) historical physical-device evidence from the signed Phase 162/163 reference proof host, which exercised its native adapter and AVFoundation path; (b) existing Chromium/Playwright evidence for the Phoenix/browser IndexedDB island and real host replay; and (c) the latest generated-candidate simulator twin, which must be a fresh source/build-bound observation. The historical physical result is genuine for its tested composition but does not validate a later generated app, visible WebView audio, or IndexedDB persistence. The simulator twin must not inherit its signed-device or physical authority.

Any of these apparent greens is a failure:

- Simulator Safari, app launch, or a passing reference-shell XCTest is reported as generated-candidate WebView coverage.
- The marker/bridge reply comes from a hidden, second, or separately constructed WebView instead of the visible study WebView that loaded the generated route.
- `AVAudioPlayer` plays the installed file while the page’s audio element uses a remote response, browser cache, or different fixture bytes; require digest-to-installed-file provenance and WebView playback with network blocked.
- Offline is simulated only by firing a JS event or Playwright’s browser-context toggle while the simulator app’s native transport remains online; do not infer simulator-wide isolation from browser-only coverage.
- A test relaunch resets/reinstalls the app, changes `WKWebsiteDataStore`, or reads native storage while claiming that the same WebView IndexedDB outbox survived process termination.
- Replay uses URLSession/APIRequestContext or direct test fetch with a separate cookie jar rather than the visible app’s normal request path; accept only the actual host response plus the real Ecto effect/duplicate observation.
- A successful primary-origin check masks an unconfigured auth redirect/media host, a wildcard allowlist, or a fallback to network audio.

## Decisive implementation-only experiments

1. Generate and unsigned-simulator-build the candidate from the declared router/origin. Assert the activation, manifest host, route/bridge origin, and visible `WKWebView` navigation all resolve to the same primary origin. Attempt one intentionally unlisted navigation and prove it is denied. Inspect rather than assume any auth continuation or media origin required by the actual route.
2. With that same visible WebView, install and verify the host pack, cut WebView network access, and test whether the study island can consume those installed bytes through a currently supported host path. Record the byte identity and playback observation. If no path exists, return blocked with the exact missing owner seam; do not add generic storage or bridge APIs.
3. Only if the route needs a secondary origin, test the exact auth/media use separately: show its host owner, intended request/navigation type, exact origin, and denial when omitted. Preserve the primary origin as the sole current route/bridge authority. If support would require broader navigation semantics or changes to core route allowlists, stop for an explicit scope decision.

The challenge does not reopen scenario count or the fixed roster. Existing browser/backend and native pack observations remain reusable at their stated layers; only the generated visible-WebView joins above are missing. Stop when these decisive tests pass or the audio seam is shown to require a generic runtime/bridge/storage product. Physical-device/adopter proof remains its own gate.

## Pinned source references

- [`LiveViewContainerViewController.swift`](https://github.com/szTheory/crosswake/blob/d0dbdf7bf196cea167ced3c50cf620bf3cb2452b/examples/ios_shell_host/CrosswakeShell/LiveViewContainerViewController.swift) — visible WebView setup, App-Bound Domains, and exact same-origin navigation gate.
- [`CrosswakeShellApp.swift`](https://github.com/szTheory/crosswake/blob/d0dbdf7bf196cea167ced3c50cf620bf3cb2452b/examples/ios_shell_host/CrosswakeShell/CrosswakeShellApp.swift) — host provider registration and Application Support storage root.
- [`ProofLaneDriver.swift`](https://github.com/szTheory/crosswake/blob/d0dbdf7bf196cea167ced3c50cf620bf3cb2452b/examples/phoenix_host/native/ios/CrosswakeProofLane/ProofLaneDriver.swift) — separate physical adapter’s installed-file verification and AVAudioPlayer playback.
- [`Manifest.Builder`](https://github.com/szTheory/crosswake/blob/d0dbdf7bf196cea167ced3c50cf620bf3cb2452b/lib/crosswake/manifest/builder.ex), [`Manifest.Types`](https://github.com/szTheory/crosswake/blob/d0dbdf7bf196cea167ced3c50cf620bf3cb2452b/lib/crosswake/manifest/types.ex), and [`Bridge.Registry`](https://github.com/szTheory/crosswake/blob/d0dbdf7bf196cea167ced3c50cf620bf3cb2452b/lib/crosswake/bridge/registry.ex) — primary host-origin construction and route bridge allowlist representation.
