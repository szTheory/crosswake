# Phase180 discussion research

**Date:** 2026-10-13 (research completed across 2026-10-14 UTC)
**Scope:** decision support for the approved bounded twin; no implementation or runtime proof.
**Source:** separate Phase179 candidate `96e5a63efab657f89f3ac84d5b1d84ff5da5d822`, tree `0514b6244ec814c1d0701d580b04651f70f57019`.
**Planning authority:** current files under `<home>/projects/crosswake/.planning`; the candidate's older tracked workstream files do not route this work.

## Result and confidence

Keep the approved architecture: existing Phoenix study island and browser corpus, one generated-iOS composition through a host-owned audio adapter, an owned SQLite/Phoenix runtime, and a small derived twin receipt. Add no dependency or testing platform. However, the exact candidate cannot currently authorize the proposed `host.study.audio.play` round trip: route validation rejects it and generated activation omits its capability projection. The existing iOS delegate is only the execution half of that path. This confirmed source gap triggers the selected scope stop; it is not permission to add core capability support.

The same read-only review found ordinary host gaps that would otherwise fit T03/T07: no visible free-form answer action and no positive saved-answer recovery destination. Actual simulator playback, target network denial, persistent-store survival and backend joins remain unexecuted. The context preserves these distinctions and leaves every TWIN requirement pending.

Three specialist agents researched composition, backend/operations and receipt/UX. Targeted follow-ups challenged the weak points rather than restarting broad research. Their initial port-zero and private-raw-log recommendations were rejected during synthesis. Two initial missing-file reports came from checking the candidate's older planning/prompt tree; the authoritative root has the v25 research and all thirteen prompts. Those path mistakes are corrected and are not product blockers. The parent independently checked candidate HEAD/tree, clean tracked source and recovery preservation.

## Tradeoffs and selected choices

| Decision | Viable alternatives and tradeoff | Selected recommendation and reason |
|---|---|---|
| Runtime ownership | Browser-only is cheap but misses iOS joins; a second native study screen bypasses the island; full matrix duplication multiplies maintenance | Preserve the existing browser/backend corpus and add only the required actual generated-app observations |
| Playback | Existing host-command delegate preserves ownership; custom WebKit scheme/file access adds resource/security/cache contracts | Host-owned AVFoundation player initiated by the ordinary visible island action, conditional on a supported declared/activated command; missing support stops work |
| Pack source | Bundled bytes prove installation while connected; HTTP acquisition proves a real foreground installer; production CDN/auth adds unrelated operations | One synthetic fixture from the owned reference server, exact size/hash and installed readback; reuse small private host code, no new public storage contract |
| WebView identity | Page-provided markers are easy but can be echoed; native callback/frame checks observe the actual view | Host-local concrete visible-controller/view/main-frame/security-origin checks, correlated request/reply and independent loaded-byte identity |
| Offline fault | Events/path monitors show state; 503 proves a responding server; laptop-wide network changes affect unrelated work | Invocation-owned endpoint transport fault observed by the actual WebView/native request path, with no assumed cross-transport interception |
| Persistence | Page reload is fast but not process death; reset/reinstall creates an unrelated clean state | Terminate/relaunch the same installed app, persistent store and primary origin without reset, then inspect actual retained local state |
| Database | Sandbox is ideal in process; another database/container adds semantics/dependencies; shared example DB risks destructive cleanup | Fresh owned SQLite committed through real cross-process Phoenix HTTP; Sandbox retains its existing unit-test role |
| Origin and port | Kernel-selected port is convenient but can disagree with generated static activation; fixed default server reuse is unsafe | Exclusively bind the prepared candidate's exact loopback origin, block if occupied; choose an ephemeral port only in an explicit supported preparation before generation/freeze |
| Replay | Direct service calls isolate logic but omit actual client/session transport; exactly-once delivery is not achievable by counting requests | Normal app replay plus an independent Ecto observation of one durable effect under duplicate delivery and accepted outbox drain |
| Fault authority | Test injectors simplify cases but can self-certify; client-canned outcomes miss server behavior | Test-gated run-owned preparation followed by independent server and visible durable-state observations |
| Recovery | Status-only avoids new routes but cannot prove an action; generic conflict tools exceed scope | Minimal active-scope reference-host review/return/retry behavior for real rejection/conflict; no silent overwrite/discard and no guessed adopter routes |
| Receipt | Physical schema has strong existing checks but the wrong authority/roster; navigation advisory lacks scenario outcomes | Small twin-only derived record, exact T01–T10 plus mandatory owner sub-observations, failed over blocked over passed |
| Identity join | Copying expected SHA everywhere looks consistent but proves nothing about installed/served bytes; signing a new attestation expands scope | Freeze expectations, independently observe each producer, compare before receipt creation; explicitly describe trusted-runner fidelity limits |
| Diagnostic retention | Raw private traces can help diagnosis but violate the payload boundary and make failures an exfiltration path | Prevent sensitive capture, retain only closed screened causes and counts, say when a cause was not retained |
| User experience | Debug controls expose test authority and internals; broad redesign consumes the adopter budget | Truthful durable-state copy, ordinary accessible actions, current tokens/themes and only required recovery affordances |
| Dependencies and CI | New orchestration/container/UI layers supply features but widen supply chain and operations | Existing Mix/OTP, Ecto/SQLite, XCTest/XCUITest, Playwright, Foundation/AVFoundation; stable recurring guards in current CI leaves, full twin local |

## Confirmed source findings

### First composition gate

`lib/crosswake/policy/validator.ex` validates route capabilities against a closed known set. The proposed host command is absent. `lib/crosswake/shell/ios_host_generation.ex` compiles the selected manifest but does not pass route capabilities into `Activation.new_request/1`. The native `ActivationCoordinator` filters registered host commands; it does not manufacture missing route capabilities. `BridgeChannel.evaluateHostCommand` requires the exact command key and compatible version in the session. Registration in `CrosswakeShellConfig` is a separate fact.

Consequently, neither editing the JS request nor retaining a delegate closes the authorization path. A manually patched activation, broad capability substitution or native proof adapter would hide the gap. A potential future repair would involve declaration validation and generated projection while preserving registration/version/origin checks, but this discussion does not authorize that public/core change. The approved synthesis expressly says to stop when the declared path cannot carry the required command.

### Reference host and media

`examples/ios_shell_host/CrosswakeShell/CrosswakeShellApp.swift` supplies a pack provider without a playback command delegate. Its `PronunciationPackProvider.swift` installs an opaque artifact, exposes no public asset resolver and currently reads a bundled source. The separate Phoenix proof host's `HostLearningBundleProvider.swift`/`ProofLaneDriver.swift` contain playable asset and AVFoundation precedents. Their native UI, journal and URLSession replay do not prove the generated island path.

The existing `PackProvider` async contract can accommodate host-private foreground acquisition without a new core protocol. A strongly retained reference-host delegate is necessary because config delegate references are weak. A host-local wrapper around the script-message callback can check the concrete view/frame and forward into the existing bridge. These design possibilities do not resolve the missing declaration/activation authority or establish execution success.

### Mutations, recovery and owned runtime

The visible `offline_study.js` review action writes mutation/card/rating data; the selected template has rating controls without free-form entry. `ReplayAdmission` and the Ecto model accept optional free-form data, which is only backend support. `OfflineController` reports recovery unavailable; the positive recovery destination is absent. Existing tests that manipulate a DOM recovery dataset are safety negatives, not a real recovery flow.

Existing study/replay modules contain scoped admission, idempotency constraints and durable effect logic. Existing E2E setup can drop a default database, bind a conventional port and reuse a server, so the twin cannot invoke it unchanged. Runtime config falls back to a default DB and permits broad binding through configuration. Verify a new SQLite path and exact loopback address before starting/migrating. Hold owned handles for cleanup; never find-and-kill a PID by port or drop a pre-existing database.

## Primary-source lessons and their limits

- **Apple testing:** keep many fast contracts and a small high-fidelity UI layer. XCTest/XCUIAutomation remains the appropriate existing UI tool; a Swift Testing migration would not supply the missing joins. [Apple testing strategy](https://developer.apple.com/documentation/xcode/testing), [XCTest](https://developer.apple.com/documentation/xctest).
- **WebKit persistence and callback identity:** configure a persistent store before view creation and observe actual retention after termination. Native view/frame/security-origin information helps bind a bridge observation to the visible page. API availability is setup evidence, not proof that this app retained work. [WKWebsiteDataStore](https://developer.apple.com/documentation/webkit/wkwebsitedatastore), [WKWebViewConfiguration](https://developer.apple.com/documentation/webkit/wkwebviewconfiguration), [WKScriptMessage](https://developer.apple.com/documentation/webkit/wkscriptmessage), [WKFrameInfo](https://developer.apple.com/documentation/webkit/wkframeinfo), [XCUIApplication](https://developer.apple.com/documentation/xcuiautomation/xcuiapplication).
- **Media ownership:** AVAudioPlayer can consume verified data; bind the input used by the player to installed bytes rather than merely seeing that a player started. Progress on Simulator is not physical speaker quality. [AVAudioPlayer](https://developer.apple.com/documentation/avfaudio/avaudioplayer), [data initializer](https://developer.apple.com/documentation/avfaudio/avaudioplayer/init(data:)).
- **Network fidelity:** a path monitor observes path changes; URLSession protocol classes are not documentation that WKWebView traffic is intercepted. A custom WebKit scheme handler is a separate resource API and is unnecessary for the selected host-player approach. [NWPathMonitor](https://developer.apple.com/documentation/network/nwpathmonitor), [URLProtocol](https://developer.apple.com/documentation/foundation/urlprotocol), [URLSession protocol classes](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/protocolclasses), [WKURLSchemeHandler](https://developer.apple.com/documentation/webkit/wkurlschemehandler).
- **Ecto/Phoenix/Plug:** Sandbox connection ownership protects transactional tests; it does not turn a separate simulator/server into a participant in an uncommitted test transaction. Use a committed owned database for actual HTTP. Read the bound server address and verify loopback, but preserve the prepared candidate's origin. [Ecto Sandbox](https://ecto-sql.hexdocs.pm/Ecto.Adapters.SQL.Sandbox.html), [Phoenix Endpoint](https://phoenix.hexdocs.pm/1.8.15/Phoenix.Endpoint.html), [Plug.Cowboy](https://plug-cowboy.hexdocs.pm/Plug.Cowboy.html), [Mix.Task](https://mix.hexdocs.pm/Mix.Task.html). These are official API references; use the candidate's locked versions before adopting exact calls.
- **Elixir process ownership:** use executable-plus-argument APIs instead of shell interpolation, and do not assume terminating the calling task terminates descendants. The current physical runner's unbounded `System.cmd` calls are not a safe timeout precedent. [System.cmd](https://elixir.hexdocs.pm/main/System.html#cmd/3). The linked main docs may describe a newer Elixir; implement against the pinned toolchain.
- **Cross-ecosystem ownership lesson:** Hotwire Native keeps web content and native host responsibilities explicit. That supports the ownership split, not adoption of another routing framework. [Hotwire native handbook](https://turbo.hotwired.dev/handbook/native).
- **Accessible state and diagnosis:** announce meaningful status without moving focus; preserve text/non-color meaning, focus, contrast and usable targets. Use system theme behavior and existing tokens. [W3C status messages](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html), [WCAG guidance](https://www.w3.org/WAI/WCAG22/Understanding/), [Apple buttons](https://developer.apple.com/design/human-interface-guidelines/buttons), [Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode), [accessibility testing](https://developer.apple.com/documentation/accessibility/testing-system-accessibility-features-in-your-app), [Playwright locators](https://playwright.dev/docs/api/class-locator). These inform the required flow only, not a compliance or redesign program.

These sources establish API behavior and design lessons. The choice of a small host-owned composition and its finite stop is a project-specific inference from the approved scope and inspected code, not a claim that the external sources validate Crosswake.

## Prompt and stakeholder coverage

All thirteen root prompt files are present. The existing v25 [coverage register](../../../../research/v25/PROMPT-COVERAGE.md) accounts for each. Refreshed relevant original sections and the register informed this discussion; historical queues do not become approved requirements.

| Root prompt | Applied lens and limit |
|---|---|
| `ARCHITECTURE-CODE-WALKTHROUGH-DNA.md` | Derive behavior from actual owners/tests; exposed the incomplete command path |
| `crosswake-elixir-oss-dna.md` | Ordinary Mix entry, small modules, explicit config, actionable failure and limited dependencies |
| `crosswake-gsd-project-brief.md` | Phoenix-first ownership and proof as developer surface |
| `crosswake-research-synthesis.md` | Runtime ladder and semantic low-frequency bridge; no universal rendering/sync |
| `crosswake-integrations-and-companions.md` | Host/core/companion boundaries; no new companion |
| `elixir-mobile-oss-lib-deep-research.md` | Consumer-facing API/DX and ecosystem comparisons; no new framework |
| `elixir-mobile-oss-refined-plan-deep-research.md` | Supported lifecycle/config and native host ownership |
| `elixir-mobile-architecture-apptypes-stresstest-deep-research.md` | Cross-runtime failure joins, limited to this one study island |
| `elixir-mobile-offlinesupport-stresstest-deep-research.md` | Persistence, duplicate/rejection/conflict, scope and connectivity failures |
| `elixir-mobile-offlinesupport-flashcard-app-stresstest-deep-research.md` | Concrete selected/free-form work, media, lifecycle and recovery |
| `elixir-mobile-apptypes-design-stresstest-deep-research.md` | Learner jobs, visible state/action and accessibility |
| `new elixir oss lib prompt.txt` | Relevant breadth/depth, least surprise and small dependency tree |
| `crosswake-brand-book.md` | Historical seed only; current `brandbook/BRAND-SPEC.md` and tokens take precedence |

The learner's job is to keep studying through connectivity loss, know what is saved, hear installed audio and resolve work safely. The maintainer's job is to run one prepared reference flow, locate the first concrete failure and know the next action. Security/privacy owns scope and egress; architecture owns route/runtime/media authority; backend engineering owns transactional effects; SRE/DevOps owns bounded runtime/cleanup and disablement; accessibility/design owns necessary controls and truthful state; release/support owns the simulator/physical/adopter boundary; the solo maintainer owns a finite maintenance budget. Each lens maps to acceptance above rather than a separate feature program. Graphics, commerce, Android and broader rendering-engine work do not contribute to these jobs and were excluded.

## Adversarial convergence and stop

The follow-ups resolved six material mistakes/ambiguities: bundled install versus HTTP acquisition; actual WebKit/native transport denial; concrete frame identity versus echoed fields; private diagnostics versus payload privacy; dynamic port versus static origin; and delegate registration versus route/activation authority. They also exposed the missing free-form and positive recovery paths. No further broad research will resolve the confirmed capability gap or prove unexecuted runtime behavior.

Planning must make the initial feasibility/scope gate concrete and preserve its incomplete result if no authorized existing path is found. It may not assume the missing core support is already approved. If a later explicit scope decision makes the path feasible, require the complete T01–T10 owner roster and meaningful producer/identity/privacy negative controls. Stop when those virtual observations pass; list the physical/adopter residuals without promoting them. No new phase, cleanup campaign, permanent CI lane or unrelated fix follows automatically.
