# Technology Stack

**Project:** Crosswake  
**Scope:** Stack research for a Phoenix-native mobile substrate  
**Researched:** 2026-05-12  
**Overall recommendation confidence:** HIGH

## Recommended Stack

Crosswake should be built as a **Phoenix library first**, with **thin native shell libraries** for iOS and Android, and with **example host apps** proving the public contract. The center of gravity is route policy, manifest generation, bounded bridge contracts, and offline island semantics. Do not optimize the first versions around shared UI runtimes.

### Core Phoenix / Elixir

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Elixir | 1.19.x | Primary language for the library | Current stable Elixir branch as of May 12, 2026. Strong compiler/tooling improvements and current OTP support. |
| Erlang/OTP | 28.x | Runtime | Matches the current Elixir support line and keeps the project on the active BEAM baseline. |
| Phoenix | 1.8.x | Host framework integration | Current Phoenix line with the router, verified routes, and component model Crosswake should extend rather than replace. |
| Phoenix LiveView | 1.1.x | Server-centric route ownership | Still the correct runtime for online-first Phoenix screens. Crosswake should compose with LiveView, not abstract it away. |
| Ecto | 3.13.x | Manifest, contract, and embedded schema validation | Use embedded schemas and changesets for runtime manifest, capability contracts, and compatibility docs. |
| NimbleOptions | current | DSL and config validation | Best fit for route-policy DSL option validation at compile and boot time. |
| Jason | current | JSON encoding/decoding | Keep manifest and bridge payloads human-readable and easy to diff, inspect, sign, and test. |
| Req | current | HTTP client | Modern Elixir default for outbound HTTP in proof lanes, docs checks, and compatibility fetches. |

### Persistence and Background Work

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| PostgreSQL | 18.x | Example host app database | Current PostgreSQL major release. Use it in proof hosts and operator surfaces, but do not make database-heavy assumptions part of Crosswake core. |
| Oban | 2.22.x | Sync jobs, reconciliation, advisory proof lanes | The right BEAM-native job layer for server-side reconciliation, upload follow-up, and compatibility checks. |

### iOS Native Shell

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Swift | 6.2.x | iOS shell language | Current stable Swift line in the Xcode 26 era. Strong concurrency tooling and first-class package support. |
| SwiftUI | current | Native chrome and native screens | Use for shell navigation, native-only flows, settings, diagnostics, and device-heavy screens. |
| WebKit (`WKWebView`) | current | LiveView/web route host | The standard and review-safe way to host Phoenix-owned screens inside the shell. |
| `WKContentWorld` + `WKScriptMessageHandler` | current | Bounded bridge | Apple’s scoped message-handler model fits Crosswake’s bridge thesis better than ad hoc JS injection. |
| `WKURLSchemeHandler` | current | Offline islands and packaged content | Correct primitive for serving packaged or device-local content into the web runtime without fake universal runtime claims. |
| Swift Package Manager | current | Shell distribution | Standard OSS delivery path for an iOS library. Keep the shell as a package, not as generated opaque project files. |
| GRDB.swift | 7.10.0 | Offline-island SQLite storage | Best fit for explicit SQLite-backed journals, drafts, packs, and reconciliation state. Crosswake needs SQL-level control more than Apple-managed persistence magic. |

### Android Native Shell

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Kotlin | 2.3.x | Android shell language | Current stable Kotlin line as of May 12, 2026. Standard choice for modern Android library work. |
| Jetpack Compose | 1.11 / BOM `2026.04.01` | Native chrome and native screens | Correct UI layer for Android-native shell surfaces and device-heavy screens. |
| AndroidX WebKit | 1.15.x | WebView compatibility layer | Required for secure, modern WebView features across device/WebView versions. |
| Android WebView | current system component | LiveView/web route host | Standard host for Phoenix-owned mobile routes. |
| `WebViewCompat.addWebMessageListener` with allowed origins/worlds | current | Bounded bridge | This is the current Android-sanctioned pattern for scoped JS/native messaging. |
| `WebViewAssetLoader` | current | Offline islands and packaged content | Standard secure way to serve in-app content over app-local HTTP(S)-style URLs instead of `file://`. |
| Room | 2.8.4 | Offline-island SQLite storage | Officially recommended over raw SQLite APIs, while still giving a real SQLite substrate for journals and packs. |
| KSP | current | Android code generation | Standard processor path for Room and any generated contract bindings. |
| Gradle Android Library | current | Shell distribution | Correct packaging for an Android substrate library; keep app examples separate from the reusable library. |

### Contract, Telemetry, and Proof Tooling

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| JSON manifests + versioned schemas | project-defined | Runtime manifest and compatibility contract | Crosswake needs inspectable, diffable contracts across Elixir, iOS, Android, and docs. JSON is the lowest-friction shared format. |
| Telemetry | current | Library event surface | Native Elixir instrumentation for route decisions, bridge calls, sync outcomes, cache hits, and compatibility failures. |
| OpenTelemetry | current | Cross-system traces | Use for traces in example hosts and operator proof lanes; it keeps Crosswake vendor-neutral. |
| ExDoc | current | API and guides docs | Standard Elixir OSS docs surface. Crosswake’s support envelope must be documented as a contract. |
| GitHub Actions | current | CI/proof automation | Standard OSS CI surface across Elixir, Swift, and Android builds. |
| release-please | current | Version PRs and changelog discipline | Good fit for recovery-conscious releases and explicit version bumps across public packages. |

## Architecture Bias Embedded in the Stack

These stack choices intentionally reinforce the project thesis:

- **Phoenix owns route policy and runtime truth.**
- **Native shells own navigation chrome, capability negotiation, and device-heavy routes.**
- **The bridge stays semantic, low-frequency, versioned, and origin-scoped.**
- **Offline islands use native SQLite stores, not browser-storage wishful thinking.**
- **OSS delivery is proven by example hosts and CI lanes before broad support claims.**

## What Crosswake Should Prove Early

### Phase-1 stack to prove

| Area | Minimum proof stack |
|------|---------------------|
| Route policy | Elixir 1.19 + Phoenix 1.8 + LiveView 1.1 + NimbleOptions + Ecto embedded schemas |
| Runtime manifest | JSON manifest generation + compatibility validation in Elixir |
| iOS shell | SwiftUI + WKWebView + `WKContentWorld` bridge + custom scheme loader |
| Android shell | Compose + WebView + AndroidX WebKit bridge + `WebViewAssetLoader` |
| Offline island | SQLite-backed local draft/outbox prototype: GRDB on iOS, Room on Android |
| Delivery | Hex package for Elixir core, SPM package for iOS shell, Android library module in-repo with publish pipeline ready but not promised until stable |
| Proof posture | GitHub Actions, example host apps, docs-contract checks, doctor tasks |

### Package shape

Start with a **monorepo**:

- `crosswake` Hex package for the Elixir core
- `shells/ios` Swift package
- `shells/android` Gradle Android library
- `examples/` host apps that exercise the supported contract

This is the right compromise. Crosswake needs separate native artifacts, but v1 should still ship as one coherently versioned OSS product.

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Cross-platform UI | Phoenix + native shells | React Native / Expo | Pushes the product toward a JS-first app stack instead of Phoenix-native route policy. |
| Cross-platform UI | Phoenix + native shells | Flutter | Same problem in a different language: Crosswake becomes a generic app framework instead of a Phoenix substrate. |
| Native rendering strategy | WebView shell + explicit native screens | LiveView Native | Wrong thesis for Crosswake, and the official `live_view_native` repo was archived on **February 10, 2026**. |
| Shared runtime | Per-platform native shells | Kotlin Multiplatform / Compose Multiplatform core | Useful later for narrow shared logic if needed, but it is the wrong early bet for proving route policy and bounded bridges. |
| Offline storage | SQLite via GRDB/Room | Browser storage only | Not credible for durable drafts, journals, media metadata, migrations, or reconciliation. |
| Android bridge | AndroidX WebKit listener APIs | raw `addJavascriptInterface` patterns | Too easy to widen the trust surface. Crosswake should bias toward origin-scoped, feature-checked messaging. |
| Android local content | `WebViewAssetLoader` | `file://` loading | Official docs explicitly steer developers away from insecure file access patterns. |
| iOS persistence | GRDB / explicit SQLite | SwiftData / Core Data first | Too opaque for a transport-contract product that needs explicit journals, migrations, and pack lifecycle control. |

## What Not To Use

### Do not use a “single runtime everywhere” stack

Crosswake should not start from React Native, Flutter, Compose Multiplatform, or any other stack whose value proposition is “share the whole UI.” That is not the thesis and it will distort the public API immediately.

### Do not use LiveView Native as the foundation

Even if the architecture thesis were closer, it is not the safe platform bet now. The official `live_view_native` repository is archived and read-only as of **February 10, 2026**.

### Do not build the bridge on broad arbitrary JS/native messaging

Use scoped message worlds, explicit origin rules, versioned payload types, and active-route checks. Avoid generic “send any JSON anywhere” bridge APIs.

### Do not make browser storage the offline story

Offline islands need durable local storage with migrations, indexing, outbox semantics, and bounded media/content-pack lifecycles. That means SQLite-backed native stores.

### Do not publish three independent public artifacts on day one

Publish the Elixir package first. Keep iOS and Android shells proven in-repo with release pipelines, then publish them once the bridge and manifest contracts stop moving.

## Confidence Assessment

| Area | Level | Notes |
|------|-------|-------|
| Elixir/Phoenix base | HIGH | Current official docs clearly show Elixir 1.19 and Phoenix 1.8 / LiveView 1.1 as the active stable line. |
| iOS shell stack | HIGH | WebKit and SwiftUI primitives are official and stable; they align tightly with the shell-and-policy architecture. |
| Android shell stack | HIGH | AndroidX WebKit, `WebViewAssetLoader`, and Room are explicitly documented and fit the bounded-bridge/offline thesis. |
| Release tooling | MEDIUM | GitHub Actions and release-please are standard and pragmatic, but final publish choreography may change once package boundaries are implemented. |
| GRDB recommendation | MEDIUM | Strong fit and active upstream, but it is a strategic choice rather than a platform-default requirement. |
| Monorepo/package-shape recommendation | MEDIUM | Best operational fit for v1, but exact split can evolve after first proof lanes. |

## Sources

- Elixir stable docs: https://elixir-lang.org/docs.html
- Elixir 1.19 release: https://elixir-lang.org/blog/2025/10/16/elixir-v1-19-0-released/
- Phoenix docs (`v1.8.7`): https://hexdocs.pm/phoenix/Phoenix.html
- Phoenix LiveView docs (`v1.1.30`): https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html
- Ecto docs (`v3.13.6`): https://hexdocs.pm/ecto/Ecto.html
- Oban docs (`v2.22.1`): https://hexdocs.pm/oban/Oban.html
- PostgreSQL current docs: https://www.postgresql.org/docs/
- Swift 6.2 release: https://www.swift.org/blog/swift-6.2-released
- Xcode 26 release notes: https://developer.apple.com/documentation/Xcode-Release-Notes/xcode-26-release-notes
- SwiftUI docs: https://developer.apple.com/documentation/swiftui
- WebKit message handler with content worlds: https://developer.apple.com/documentation/webkit/wkusercontentcontroller/add%28_%3Acontentworld%3Aname%3A%29
- `WKURLSchemeHandler` docs: https://developer.apple.com/documentation/webkit/wkurlschemehandler
- Kotlin release process / current released version info: https://kotlinlang.org/docs/releases.html and https://kotlinlang.org/docs/faq.html
- Jetpack Compose April 2026 stable release: https://developer.android.com/blog/posts/whats-new-in-the-jetpack-compose-april-26-release
- AndroidX WebKit API reference: https://developer.android.com/reference/androidx/webkit/package-summary
- `WebViewCompat.addWebMessageListener`: https://developer.android.com/reference/androidx/webkit/WebViewCompat
- `WebViewAssetLoader` docs: https://developer.android.com/reference/androidx/webkit/WebViewAssetLoader
- Android local-content guidance: https://developer.android.com/develop/ui/views/layout/webapps/load-local-content
- Android JS bridge guidance: https://developer.android.com/develop/ui/views/layout/webapps/native-api-access-jsbridge
- Room docs and release notes: https://developer.android.com/training/data-storage/room and https://developer.android.com/jetpack/androidx/releases/room
- OpenTelemetry Erlang/Elixir docs: https://opentelemetry.io/docs/languages/erlang/
- GRDB.swift official repo and releases: https://github.com/groue/GRDB.swift
- `live_view_native` archived repository state: https://github.com/liveview-native/live_view_native
