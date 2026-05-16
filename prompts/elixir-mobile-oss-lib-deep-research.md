1. Executive recommendation

Build Keelway: a Phoenix-native mobile shell and bridge toolkit for shipping iOS and Android apps from existing Phoenix/LiveView apps without pretending LiveView is magically offline-native.

The right v1 is not a full native renderer, not a React Native competitor, and not a “LiveView Native revival.” It should be a Hotwire Native–style Phoenix library:

* A small Elixir/Phoenix Hex core that gives the host app mobile-aware routing, path policies, bridge contracts, telemetry, manifests, testing fixtures, and generators.
* Swift and Kotlin packages that provide a polished WKWebView/Android WebView shell with native navigation, native screens, bridge components, push/deep links, permissions, haptics, media, audio, and store billing hooks.
* Optional packages for offline sync, billing, push, media, and szTheory adapters.
* Explicitly limited offline behavior: cached pages and selected resource sync, not “offline LiveView.”

This fits Phoenix because Phoenix/LiveView is server-rendered HTML over normal Phoenix routes and LiveView diffs; Phoenix’s current docs continue to frame LiveView as server-rendered HTML for rich realtime web experiences, while Phoenix itself remains a server-side web framework over Plug/Ecto-style boundaries.  ￼

The ecosystem gap is clear: Rails has Hotwire Native, Bridge Components, and now PurchaseKit-style in-app purchase infrastructure; Phoenix has excellent LiveView but no mature, policy-aware, testable, batteries-included “ship my Phoenix app to the app stores” substrate. Hotwire Native’s own docs describe a web-first native shell with native navigation and server-rendered HTML, plus path configuration and bridge components; that is the closest proven pattern to copy for Phoenix.  ￼

Why this beats the alternatives:

* It preserves the Phoenix server-centric productivity model.
* It reuses the existing web app instead of creating a second frontend.
* It gives you native polish where users actually feel it: navigation, sheets, haptics, permissions, camera, push, audio, billing, offline state, review prompts.
* It avoids depending on LiveView Native’s archived main repository. The main live_view_native repo is read-only as of February 10, 2026; related repositories and client packages still exist, but the archived core makes it risky as a required dependency.  ￼
* It avoids the false promise that WebSockets plus LiveView equals offline-first mobile. Service workers, native caches, SQLite, mutation queues, and conflict resolution are separate product surfaces.  ￼

What Keelway should not try to do:

* Replace Phoenix, LiveView, React Native, Flutter, Capacitor, or native apps.
* Render arbitrary LiveViews as native SwiftUI/Compose trees.
* Promise full offline LiveView.
* Become an app-store legal advisor.
* Own the host app’s business schemas, billing model, auth model, or UI design system.
* Force dependencies on sigra, accrue, chimeway, rindle, or any szTheory package.

Naming strategy

I would use keelway as the working name.

It has the szTheory feel of “infrastructure pathing/flow,” it is short, pronounceable, and works as:

* Hex: keelway, keelway_sync, keelway_billing, keelway_push, keelway_media
* Elixir modules: Keelway, Keelway.Sync, Keelway.Billing
* Swift Package: KeelwayKit
* Android Maven coordinates: io.sztheory.keelway:keelway-android

Hex package names are globally published through Hex, and publishing requires package metadata plus mix hex.publish; public OSS packages and docs are available through Hex/HexDocs. I found no obvious Hex search result for keelway, wayline, dockway, or bridgeway, but that is not a reservation guarantee; run mix hex.info keelway, check Hex directly, and reserve the GitHub org/repo before final branding.  ￼

Other candidate names that fit the ecosystem:

1. keelway — recommended.
2. wayline
3. dockway
4. tideway — nice, but close to existing tidewave.
5. routeway
6. pathdeck
7. bridgelane
8. navra
9. keelpath
10. shellway

2. Comparison matrix

Approach	Ergonomics / Phoenix fit	Native UX quality	Web reuse / offline	Store risk / CI complexity	Maintenance / szTheory fit	Biggest footguns	Lessons to copy
Phoenix Hotwire-style WebView shell	Best fit. Phoenix keeps routes, controllers, LiveViews, sessions, layouts, Ecto contexts. Keelway adds path policies, manifests, bridge contracts, telemetry.	High when native nav, sheets, haptics, permissions, push, audio, and billing are native; mediocre if it is “just a WebView.”	Excellent web reuse. Offline is honest: cached read-only pages plus selected sync resources.	Moderate. Store review still matters, but architecture is conventional native app + WebView. CI requires Swift/Kotlin builds.	Excellent. Composable packages/adapters match szTheory.	WebView security, stale LiveViews, app-store billing mistakes, “native-ish” feeling cheap if polish is skipped.	Copy Hotwire Native path config, bridge components, native screens, and local+remote manifest strategy.  ￼
LiveView Native adapter/revival	Superficially attractive for Elixir, but risky now. Main repo archived; related repos remain but ecosystem appears unstable.	Could be excellent if maintained, because SwiftUI/Compose-like rendering can be native.	Web reuse is weaker because templates diverge from HTML. Offline still not solved automatically.	High. You own renderer churn and LiveView internals.	Poor as required dependency; okay as optional adapter/learning source.	Breaking LiveView internals, low adoption, unclear production base, fork maintenance.	Copy typed components and server-driven UI ambition, but do not bet v1 on it.  ￼
PWA-only	Easy for Phoenix. No native code.	Lower native polish; push/offline varies by platform and user install behavior.	Excellent web reuse. Service worker caching works well for assets/pages but cannot replace native capabilities or robust sync.	Lower store risk because no stores, but lower distribution/reputation leverage.	Good docs-only target.	Users do not perceive it as a real app; native permissions, background audio, billing, app reviews suffer.	Copy service worker cache strategies and stale-while-revalidate language.  ￼
Capacitor/Ionic	Good for web apps, but more JS-toolchain-centered than Phoenix-centered.	Good if custom native plugins are written.	Good WebView reuse, but you inherit Capacitor’s plugin ecosystem and build model.	Moderate. Native projects and plugins still require app-store discipline.	Useful inspiration, not ideal core dependency.	JS/native plugin drift, permission misconfiguration, WebView assumptions.	Copy plugin permission documentation discipline; Capacitor explicitly expects app developers to declare needed permissions.  ￼
React Native / Expo	Poor for Phoenix-first teams unless you create APIs and a separate frontend.	High potential. Expo/EAS is mature.	Low web reuse unless app is redesigned around APIs. Offline can be strong but app-specific.	High CI/build/versioning complexity; native modules and new architecture churn matter.	Poor for Unix-like Phoenix packages; good for teams already using React.	Two frontend codebases, OTA/native module mismatch, API contract drift.	Copy EAS-style release automation, fixture-driven testing, and native module capability boundaries.  ￼
Flutter	Poor Phoenix ergonomics; Phoenix becomes backend API.	High and consistent, but not native-native.	Low web reuse. Offline can be excellent if designed.	High separate app lifecycle.	Poor ecosystem fit.	Dart app becomes the product; Phoenix web app becomes secondary.	Copy strong design-token discipline and predictable rendering/testing.  ￼
Kotlin Multiplatform	Poor for Phoenix-first UI; good for shared business logic in native apps.	High if native UI per platform.	Low web reuse. Offline strong but expensive.	High. iOS + Android expertise required.	Better as enterprise later-phase option, not v1.	Shared logic does not eliminate platform UI work.	Copy local domain-model and sync-core ideas, not the whole strategy. Google describes KMP as officially supported for sharing Android/iOS business logic.  ￼
Electron / Tauri desktop shell	Good for desktop wrappers. Tauri is compelling for small binaries and permissioned IPC.	Desktop-only polish can be good. Not primary mobile path.	Strong web reuse. Offline similar to WebView/PWA.	Desktop signing/updating has its own complexity.	Good later package: keelway_desktop.	Scope creep; desktop concerns distract from app-store mobile.	Copy Tauri capabilities/permission model and updater distribution.  ￼
Native iOS/Android from scratch	Worst for Phoenix reuse unless APIs are the product.	Best possible UX.	Low web reuse. Offline best if fully engineered.	Highest CI, staffing, review, release, test burden.	Bad for small-team SaaS-in-a-box.	Two native apps plus web app. Slow iteration.	Copy native permission UX, audio/background APIs, app-store review discipline.  ￼

Verdict: choose the Phoenix Hotwire-style WebView shell, with optional LiveView Native learning/adapters, and explicit future room for Tauri desktop.

3. Recommended architecture

Use a monorepo with separate release artifacts. One repo reduces coordination pain for bridge fixtures, native examples, CI, docs, and release choreography. Each artifact still has independent semver and package-manager release rules.

keelway — main Hex package

Responsibilities

* Phoenix plugs for platform/app detection.
* Manifest endpoint.
* Path/route policy DSL.
* LiveView helpers.
* Bridge command/event envelope.
* JSON schema fixture generation.
* Capability registry.
* Telemetry definitions.
* Native fallback helpers.
* Mix/Igniter generators.
* Example app scaffolding.

Public APIs

Keelway.Manifest
Keelway.RoutePolicy
Keelway.Bridge
Keelway.Bridge.Command
Keelway.Bridge.Event
Keelway.Capability
Keelway.LiveView
Keelway.Plug.Platform
Keelway.Plug.Manifest
Keelway.Telemetry

Dependencies

* Required: phoenix, plug, telemetry, jason.
* Optional: ecto, phoenix_live_view, igniter, open_api_spex or JSON-schema generator.
* No mandatory szTheory dependencies.

Plug’s “connection in, connection out” model and Phoenix’s Plug integration make platform detection and manifest routing idiomatic as plugs; Ecto and Phoenix contexts should stay host-owned.  ￼

Must not do

* Store business state by default.
* Own auth.
* Own billing.
* Hard-code routes.
* Hide app-store-sensitive behavior behind magic.

Testing

* ExUnit for route policies, manifest generation, bridge schemas, capability negotiation.
* Phoenix.LiveViewTest for LiveView helper behavior.
* Contract fixtures shared with Swift/Kotlin.

Release target

* Hex + HexDocs.

keelway_sync — optional Hex package

Responsibilities

* Offline cache policy DSL.
* Ecto resource sync contracts.
* Mutation queue API.
* Idempotency and conflict-resolution protocols.
* Sync endpoint generators.
* Native SQLite schema contract fixtures.

Public APIs

Keelway.Sync.Resource
Keelway.Sync.Policy
Keelway.Sync.Mutation
Keelway.Sync.ConflictResolver
Keelway.Sync.Checkpoint
Keelway.Sync.Tombstone

Dependencies

* Required: keelway.
* Optional: ecto, ecto_sql, oban.

Must not do

* Promise collaborative offline by default.
* Infer arbitrary LiveView state.
* Sync every schema automatically.

Testing

* ExUnit contract tests.
* Property tests for mutation idempotency.
* Deterministic sync fixture server.
* Native SQLite replay tests.

Release target

* Hex.

keelway_billing — optional Hex package

Responsibilities

* StoreKit/Play Billing bridge contracts.
* Server receipt verification behaviours.
* Subscription state normalization.
* Restore purchase flow.
* Refund/grace/hold event ingestion.
* Optional accrue adapter.

Public APIs

Keelway.Billing.Provider
Keelway.Billing.ReceiptVerifier
Keelway.Billing.EntitlementMapper
Keelway.Billing.PurchaseEvent
Keelway.Billing.AccrueAdapter

Dependencies

* Required: keelway.
* Optional: accrue, lattice_stripe, oarlock.

Must not do

* Tell apps when Apple/Google legally require IAP.
* Route in-app digital goods through Stripe/Paddle by default.
* Treat client purchase success as entitlement success.

Testing

* StoreKit signed transaction fixtures.
* Google purchase token/RTDN fixtures.
* Sandbox test guides.
* Contract tests with normalized lifecycle events.

Apple StoreKit transactions are signed, Apple provides App Store Server APIs and App Store Server Notifications, and Google recommends a secure backend for purchase verification and real-time developer notifications.  ￼

Release target

* Hex.

keelway_push

Responsibilities

* Push notification payload helpers.
* Deep-link routing helpers.
* Device token registration.
* Optional chimeway adapter.

Public APIs

Keelway.Push.Device
Keelway.Push.DeepLink
Keelway.Push.Payload
Keelway.Push.ChimewayAdapter

Dependencies

* Required: keelway.
* Optional: chimeway.

Must not do

* Become an APNs/FCM provider SDK replacement unless the adapter explicitly opts in.
* Store tokens without host consent.

Testing

* Payload validation.
* Deep-link signature/allowlist tests.
* Chimeway adapter tests with no hard dependency.

Release target

* Hex.

keelway_media

Responsibilities

* Native camera/file/media capture bridge contracts.
* Upload session helpers.
* Optional rindle adapter.
* Signed URL handoff helpers.

Public APIs

Keelway.Media.Capture
Keelway.Media.UploadIntent
Keelway.Media.RindleAdapter

Dependencies

* Required: keelway.
* Optional: rindle.

Must not do

* Own long-term asset lifecycle if rindle or host app already does.
* Assume camera/microphone permissions are globally granted.

Testing

* Upload intent fixture tests.
* Permission-denied bridge fixtures.
* Rindle adapter contract tests.

Release target

* Hex.

KeelwayKit — iOS Swift Package

Responsibilities

* WKWebView shell.
* Native navigation.
* Path config loading.
* Bridge component runtime.
* Capability registry.
* Deep links/universal links.
* Push token handoff.
* StoreKit adapter.
* AVFoundation/AVKit audio hooks.
* Camera/media/share/haptics adapters.

Dependencies

* Swift Package Manager.
* WebKit, StoreKit, UserNotifications, AVFoundation, AVKit.

Must not do

* Encode host business logic.
* Hard-code app routes.
* Bypass App Transport Security casually.

Apple documents WKWebView as the native web view for browsing experiences, StoreKit as the IAP framework, APNs/local notifications through the notifications framework, Universal Links for deep app content, and AVFoundation/AVAudioEngine/AVKit for audiovisual media.  ￼

Testing

* XCTest unit tests.
* Snapshot/golden tests for native screens.
* Contract tests against JSON fixtures.
* Maestro smoke tests.

Release target

* Swift Package Manager tags.

keelway-android — Kotlin/Gradle package

Responsibilities

* Android WebView shell.
* Native navigation.
* Path config loading.
* Bridge component runtime.
* Capability registry.
* Deep links/app links.
* Push token handoff.
* Play Billing adapter.
* Media3 audio hooks.
* Camera/media/share/haptics adapters.

Dependencies

* Gradle/Kotlin.
* AndroidX.
* Play Billing.
* Media3.

Android’s permission model is explicit, Play Billing is the official purchase client surface, and Android Media3 recommends a service-backed media session/player for background playback.  ￼

Testing

* Kotlin unit tests.
* Espresso or Robolectric for components.
* Contract fixture tests.
* Maestro smoke tests.

Release target

* v0.x: GitHub Packages or JitPack for speed.
* v1.0: Maven Central.

keelway_desktop — later

Make this a later package, not v0.1. Tauri is the better fit than Electron for a future Keelway desktop bridge because Tauri has explicit capabilities/permissions and now supports desktop plus Android/iOS, but desktop distribution/signing/updating is a distinct problem.  ￼

4. Idiomatic Elixir/Phoenix API design

Use Keelway as placeholder name.

# config/config.exs
config :keelway,
  otp_app: :my_app,
  endpoint: MyAppWeb.Endpoint,
  repo: MyApp.Repo,
  app_name: "My SaaS",
  ios: [
    bundle_id: "com.example.mysaas",
    app_bound_domains: ["app.example.com"],
    universal_links: ["https://app.example.com/mobile/*"]
  ],
  android: [
    application_id: "com.example.mysaas",
    app_links: ["https://app.example.com/mobile/*"]
  ],
  telemetry_prefix: [:my_app, :mobile]
# router.ex
pipeline :mobile do
  plug Keelway.Plug.Platform
  plug Keelway.Plug.Manifest
end
scope "/", MyAppWeb do
  pipe_through [:browser, :mobile]
  live "/", HomeLive
  live "/invoices/:id", InvoiceLive
end
scope "/keelway" do
  pipe_through [:browser, :mobile]
  get "/manifest.json", Keelway.ManifestController, :show
  post "/bridge/events", Keelway.BridgeController, :event
end
# lib/my_app_web/mobile/path_policy.ex
defmodule MyAppWeb.Mobile.PathPolicy do
  use Keelway.RoutePolicy
  path "/", native: [presentation: :root, cache: :network_first]
  path "/settings", native: [presentation: :push, title: "Settings"]
  path "/billing", native: [presentation: :native_screen, screen: "billing.paywall"]
  path "/invoices/:id", native: [presentation: :push, cache: :stale_while_revalidate]
  fallback native: [presentation: :push]
end
defmodule MyAppWeb.HomeLive do
  use MyAppWeb, :live_view
  use Keelway.LiveView
  native_action :share_invoice,
    platforms: [:ios, :android],
    payload: MyApp.Mobile.ShareInvoicePayload,
    fallback: &__MODULE__.web_share_fallback/2
  def handle_event("share", %{"invoice_id" => id}, socket) do
    {:noreply,
     push_native_command(socket, :share_invoice, %{
       invoice_id: id,
       title: "Invoice #{id}",
       url: ~p"/invoices/#{id}"
     })}
  end
  def handle_native_event("purchase.updated", params, socket) do
    # Host app decides what to do with the update.
    {:noreply, assign(socket, :purchase_status, params["status"])}
  end
  def web_share_fallback(payload, socket) do
    {:noreply, put_flash(socket, :info, "Copy this link: #{payload.url}")}
  end
end
defmodule MyApp.Mobile.TodoSync do
  use Keelway.Sync.Resource,
    schema: MyApp.Todos.Todo,
    repo: MyApp.Repo,
    scope: :current_user
  cache :network_first, ttl: {7, :days}
  mutations [:create, :update, :delete],
    idempotency_key: true,
    conflict: MyApp.Mobile.TodoConflictResolver
end
defmodule MyApp.Mobile.TodoConflictResolver do
  @behaviour Keelway.Sync.ConflictResolver
  @impl true
  def resolve(%Keelway.Sync.Conflict{} = conflict) do
    case conflict.field_changes do
      [:completed] -> {:merge, conflict.client_patch}
      _ -> {:manual, view: MyAppWeb.TodoConflictLive}
    end
  end
end

Generators

Use Igniter where possible because Igniter is built for semantic project modification and Phoenix library installation workflows.  ￼

Recommended generators:

mix igniter.install keelway
mix keelway.install
mix keelway.gen.native ios android
mix keelway.gen.path_policy
mix keelway.gen.native_action ShareInvoice
mix keelway.gen.sync_resource Todos Todo
mix keelway.gen.billing --provider storekit --provider play_billing --adapter accrue
mix keelway.gen.push --adapter chimeway
mix keelway.doctor

Behaviours and protocols

Prefer behaviours over macro-heavy DSLs:

Keelway.Bridge.Payload
Keelway.Bridge.Handler
Keelway.Capability.Provider
Keelway.Sync.Resource
Keelway.Sync.ConflictResolver
Keelway.Billing.ReceiptVerifier
Keelway.Billing.EntitlementMapper
Keelway.Push.DeviceRegistry
Keelway.Media.UploadAdapter

Macros are acceptable for:

* use Keelway.LiveView to inject a small set of helpers.
* use Keelway.RoutePolicy for compile-time path matching validation.
* use Keelway.Sync.Resource to declare a resource contract.

Avoid macros for business behavior. Generated host modules should be normal Elixir modules that developers can edit.

Error structs

%Keelway.Bridge.Error{}
%Keelway.Bridge.MissingCapabilityError{}
%Keelway.Bridge.PermissionDeniedError{}
%Keelway.Bridge.PolicyViolationError{}
%Keelway.Manifest.StaleManifestError{}
%Keelway.Sync.ConflictError{}
%Keelway.Billing.UnverifiedReceiptError{}

Supervision tree

Core v0.1 should require little runtime state. Provide an optional child spec:

children = [
  {Keelway, otp_app: :my_app}
]

Internally this can supervise:

* Manifest cache.
* Capability registry.
* Telemetry reporter.
* Optional sync queue only when keelway_sync is installed.

Runtime config should own app identity, endpoint, repo, platform settings, and public URLs. Compile-time config should only affect code generation and schema validation.

Making LiveView mobile-aware without pollution

Do not make every LiveView know about mobile. Instead:

* Assign platform metadata in a root layout or on_mount.
* Use route policy to determine presentation.
* Provide helpers like mobile?(socket), native_capability?(socket, :share), and push_native_command/3.
* Let LiveViews opt into native actions only when useful.

5. Native bridge protocol

The bridge must be treated like a public API.

Envelope

{
  "protocol": "keelway.bridge",
  "version": "1.0",
  "id": "01JZ7E5T0A6N5Z9DS9B2R4N2QH",
  "kind": "command",
  "name": "share.invoice",
  "platform": "ios",
  "app_version": "1.2.3",
  "capabilities": ["share", "haptics", "secure_storage"],
  "payload": {
    "invoice_id": "inv_123",
    "title": "Invoice #123",
    "url": "https://app.example.com/invoices/inv_123"
  },
  "correlation_id": "01JZ7E5V3GJ52F7X8P8X8PBJGA",
  "idempotency_key": "share-invoice-inv_123-2026-05-12",
  "requires_ack": true,
  "issued_at": "2026-05-12T16:00:00Z"
}

Rules

* Versioned: protocol + semver version.
* Typed: every command/event has JSON Schema fixtures.
* Secure by default: route/action allowlists, origin validation, no dynamic eval, no arbitrary JS bridge exposure.
* Backward compatible: native apps ignore unknown optional fields; server refuses unknown required versions.
* Observable: every command emits telemetry.
* Degradable: missing native capability falls back to web behavior.

Android’s addJavascriptInterface risk is especially important: Android documents that injected Java objects are exposed to all frames in a WebView, and OWASP recommends origin-scoped messaging and exposing bridges only to fully trusted content.  ￼

Command flow

Server-to-native:

1. LiveView/controller requests command.
2. Keelway validates route policy + capability allowlist.
3. Server emits [:keelway, :bridge, :command, :start].
4. Native executes command.
5. Native sends ack, error, or event.
6. Server emits stop/exception telemetry.

Native-to-server:

1. Native emits event envelope.
2. Server validates app/session/origin/idempotency.
3. Handler runs in host app.
4. Server returns ack or command response.

Feature negotiation

Native app sends capabilities on initial load:

{
  "kind": "event",
  "name": "capabilities.announced",
  "payload": {
    "bridge_version": "1.0",
    "capabilities": {
      "share": "1.0",
      "haptics": "1.0",
      "camera": "1.0",
      "storekit": "2.0",
      "audio": "1.0",
      "sqlite_sync": "0.1"
    }
  }
}

Server manifest responds with route-specific permissions:

{
  "routes": [
    {
      "pattern": "/invoices/:id",
      "presentation": "push",
      "commands": ["share.invoice", "document.preview"],
      "cache": {"strategy": "stale_while_revalidate", "ttl_seconds": 604800}
    }
  ]
}

Telemetry event names

Use stable telemetry names as public API, with low-cardinality measurements/metadata. Telemetry is a lightweight event dispatch library, and Phoenix already builds on Telemetry conventions.  ￼

[:keelway, :navigation, :proposed]
[:keelway, :navigation, :accepted]
[:keelway, :bridge, :command, :start]
[:keelway, :bridge, :command, :stop]
[:keelway, :bridge, :command, :exception]
[:keelway, :capability, :missing]
[:keelway, :connection, :offline]
[:keelway, :connection, :recovered]
[:keelway, :sync, :mutation, :queued]
[:keelway, :sync, :mutation, :flushed]
[:keelway, :purchase, :started]
[:keelway, :purchase, :verified]
[:keelway, :purchase, :refunded]
[:keelway, :audio, :playback, :started]

6. Offline and spotty connection strategy

Be brutally honest: LiveView online is online. Offline support is a separate layer.

Five modes

1. Online LiveView

Normal Phoenix LiveView over WebSocket/long-poll fallback. This is the best experience when connected.

2. Cached read-only pages

Use native cache and service worker cache where available. These pages can show recently visited or explicitly prefetched content with a stale badge. Service workers support fine-grained caching and request handling, but strategy choice matters: cache-first, network-first, and stale-while-revalidate each have tradeoffs.  ￼

3. Offline-capable resources

Selected resources expose sync endpoints and local SQLite storage. This is opt-in per Ecto schema/context.

4. Offline mutations

Selected forms/actions enqueue idempotent mutations and replay later.

5. True collaborative offline

Out of scope for v1 unless the app explicitly integrates CRDT/OT/local-first tooling. CRDT tools like Yjs and Automerge are real, but they are a different product tier; Replicache’s docs also emphasize that conflict resolution is application-specific.  ￼

Cache policy DSL

defmodule MyApp.Mobile.CachePolicy do
  use Keelway.CachePolicy
  route "/", :network_first, ttl: {1, :day}
  route "/invoices/:id", :stale_while_revalidate, ttl: {7, :days}
  route "/settings", :cache_first, ttl: {30, :days}
  prefetch ["/", "/settings"]
  never_cache ["/admin", "/billing/checkout", "/auth/*"]
end

Native cache strategy

* Cache manifest locally.
* Cache static assets aggressively by digest.
* Cache HTML snapshots only for approved routes.
* Store snapshot metadata: route, user/session scope, timestamp, auth scope, manifest version.
* Refuse cached pages for sensitive routes unless explicitly allowed.
* Display stale/readonly state in the shell, not hidden in the page.

iOS caveats

WKWebView service-worker behavior is historically more constrained than normal Safari. Apple’s App-Bound Domains feature limits WKWebView navigation to app-owned domains and is intended to improve privacy in in-app browsing; use it for security posture, but do not make iOS offline depend solely on undocumented WebView/service-worker behavior.  ￼

Android caveats

Android WebView supports many web capabilities, but it is still an embedded browser surface with its own lifecycle and SSL/cache behavior. Treat native SQLite/cache as the reliable offline substrate and the service worker as an optimization.  ￼

Sync endpoint shape

GET /keelway/sync/todos?since=ck_123
{
  "resource": "todos",
  "schema_version": 3,
  "checkpoint": "ck_124",
  "server_time": "2026-05-12T16:10:00Z",
  "rows": [
    {
      "id": "todo_1",
      "version": 7,
      "updated_at": "2026-05-12T16:00:00Z",
      "data": {"title": "Call customer", "completed": false}
    }
  ],
  "tombstones": [
    {"id": "todo_2", "deleted_at": "2026-05-12T15:00:00Z"}
  ]
}
POST /keelway/sync/todos/mutations
{
  "client_id": "ios-device-123",
  "mutations": [
    {
      "client_mutation_id": "m_001",
      "idempotency_key": "todo_1-complete-7",
      "base_version": 7,
      "op": "update",
      "id": "todo_1",
      "patch": {"completed": true}
    }
  ]
}

Response:

{
  "accepted": ["m_001"],
  "committed": [
    {"client_mutation_id": "m_001", "server_version": 8}
  ],
  "conflicts": []
}

SQLite schema

Native packages should create predictable tables:

keelway_resources
keelway_resource_rows
keelway_mutation_queue
keelway_sync_checkpoints
keelway_conflicts
keelway_cache_entries

Conflict behavior

Default policies:

* :server_wins
* :client_wins
* :merge_changeset
* :manual
* custom resolver module

Manual conflicts must have UX: “Your offline edit conflicts with a newer server edit. Review changes.”

User-visible offline states

* Offline banner.
* Stale badge.
* Queued changes chip.
* Retry button.
* Conflict screen.
* Read-only mode label.
* “Last updated at” timestamp.
* Connection recovered toast.
* Sync progress queue.

Tests

* Offline page loads from native cache.
* Sensitive route does not cache.
* Mutation queues offline and flushes once.
* Duplicate mutation idempotently no-ops.
* Conflict resolver returns manual conflict.
* LiveView reconnect shows stale state before fresh data.

7. Billing and entitlement strategy

This is the most app-store-sensitive package. Treat it as an engineering compliance layer, not legal advice. Apple and Google policies change frequently, including recent changes around external links/payment options and Google’s 2026 billing flexibility announcements; verify current Apple/Google terms before each release.  ￼

Core rule

The server is the source of entitlement truth.

Native purchase success is not entitlement success. A user gets access only after server verification and subscription state mapping.

Apple flow

1. Server-rendered paywall shows mobile-safe product IDs.
2. Native bridge starts StoreKit purchase.
3. StoreKit returns signed transaction data.
4. Native sends transaction to Phoenix server.
5. Server verifies with Apple/App Store Server APIs.
6. Server updates entitlement.
7. App Store Server Notifications update renewals, refunds, grace periods, expiration, and offer events.
8. LiveView/UI receives update through normal Phoenix mechanisms.

Apple StoreKit provides signed transaction data, App Store Server API lets your server query customer purchase data, and App Store Server Notifications deliver real-time server-to-server events for in-app purchase lifecycle changes such as purchases, renewals, offer redemptions, and refunds.  ￼

Google flow

1. Server-rendered paywall shows Play product IDs.
2. Native bridge uses Play Billing.
3. Native sends purchase token to server.
4. Server verifies through Google Play Developer APIs.
5. Server updates entitlement.
6. Real-time Developer Notifications via Pub/Sub update subscription lifecycle.
7. Server maps grace/account-hold/refund/cancel states.

Google’s Play Billing docs cover client integration, subscription lifecycle management, real-time developer notifications, and strongly recommend secure backend verification for purchase handling.  ￼

Subscription state model

%Keelway.Billing.SubscriptionState{
  provider: :apple | :google | :stripe | :paddle,
  provider_subscription_id: binary(),
  product_id: binary(),
  status:
    :trialing |
    :active |
    :grace_period |
    :account_hold |
    :paused |
    :canceled |
    :expired |
    :refunded |
    :revoked,
  current_period_start: DateTime.t(),
  current_period_end: DateTime.t(),
  auto_renews?: boolean(),
  entitlement_key: atom(),
  verified_at: DateTime.t()
}

Restore purchases

Native shell should expose:

push_native_command(socket, "purchase.restore", %{})

Server must handle restored purchases as verification inputs, not as local trust.

Refunds, grace periods, holds

* Apple refund notification → revoke or adjust entitlement.
* Apple grace period → keep or restrict access based on host policy.
* Google grace/account hold → map state and notify user.
* Refund/refund-reversal fixtures must be part of tests.

Apple documents billing grace periods for auto-renewable subscriptions, and Google documents grace/account-hold states in subscription lifecycle handling.  ￼

Trials, offers, promo codes

Support metadata, not magic:

%Keelway.Billing.Offer{
  provider: :apple,
  product_id: "pro_annual",
  offer_id: "spring_2026",
  eligibility: :new_subscriber
}

Apple supports promotional offers, offer codes, and promo codes, but the exact eligibility and limits must be enforced through current store configuration and server verification.  ￼

Digital goods vs physical goods vs SaaS

Keelway should ship a billing decision checklist, not a legal conclusion:

* Digital content/features consumed in the app: default to StoreKit/Play Billing.
* Physical goods: usually external payment can be appropriate.
* Person-to-person services: often different rules.
* Reader apps / external account apps: special rules.
* Enterprise SaaS / B2B access: often nuanced.
* Existing web subscribers: keep their entitlement path; do not force repurchase.
* External purchase links: region/program/storefront-specific and changing.

accrue integration

keelway_billing should optionally map native purchase events into Accrue entitlement/subscription state.

config :keelway_billing,
  entitlement_adapter: Keelway.Billing.AccrueAdapter,
  web_billing_adapters: [
    stripe: LatticeStripe,
    paddle: Oarlock
  ]

Accrue is positioned as a Phoenix-era billing library with subscriptions, invoices, checkout, webhooks, and billing-state modeling; AccrueAdmin and AccruePortal are admin/customer billing surfaces.  ￼

Paywall UX

Copy the good part of PurchaseKit: server-rendered paywalls, native payment sheets, normalized store lifecycle events, and existing web subscriber support. Do not copy the SaaS dependency model unless you want a hosted service; for szTheory, the stronger OSS play is host-owned verification adapters and fixtures.  ￼

8. Native UX polish

The shell must feel intentional, not like a website trapped in a phone.

Navigation

* Native stack navigation.
* Native modal/sheet presentation.
* Per-route titles and buttons.
* Pull-to-refresh for cacheable GET routes.
* Native back behavior.
* Deep link restoration.
* Loading progress with skeletons.

Hotwire Native’s path configuration and native screens are the right conceptual model: the server declares route behavior; the native app decides presentation.  ￼

Loading, empty, retry

Ship native templates for:

* Launch loading.
* Offline cached page.
* Network failure.
* Auth expired.
* Permission denied.
* Sync conflict.
* Billing verification pending.
* Native capability missing.

Haptics and gestures

Native haptics should be small, semantic, and optional:

* success
* warning
* error
* selection
* impact light/medium/heavy

Animation

Adopt a restrained “game feel” approach:

* Button press feedback.
* Native transitions.
* Origin-aware sheets/popovers.
* Fast ease-out entry.
* Avoid scale(0) and overly slow motion.
* Respect reduced motion.

Emil Kowalski’s animation guidance emphasizes immediate feedback, correct easing, origin-aware motion, and avoiding heavy-handed animation; Apple’s Human Interface guidance also requires reduced-motion accommodation.  ￼

Lottie vs Rive

* Lottie: great for preauth/onboarding/empty states; simple one-shot animations.
* Rive: better for interactive state machines and game-feel UI, with native runtimes across platforms.
* Native animations: best for nav, sheets, haptics, gestures, and accessibility.

Rive positions itself as an interactive animation/runtime engine with iOS, Android, web, Flutter, React, and React Native runtimes; Lottie is a widely used open vector animation format/runtime.  ￼

Audio

Audio must be native-first when it matters.

Use web audio only for simple UI sounds. Use native audio when you need:

* background audio
* playback queues
* interruption handling
* lock-screen controls
* low latency
* offline audio cache
* media sessions
* stable long-running playback

Apple’s AVFoundation/AVAudioEngine/AVKit stack is the right iOS substrate, and Android Media3 recommends a service-backed player/media session for background playback.  ￼

Push, deep links, permissions

* Permission prompts should happen at point of need.
* Pre-permission explainer should be native and concise.
* Deep links must be signed/allowlisted when invoking privileged actions.
* Universal Links/App Links should map to Phoenix routes.

Apple documents Universal Links for app deep content, and Android emphasizes designing permission UX around specific actions requiring permissions.  ￼

Review prompts and support

Integrate with Cairnloop-style support/sentiment events later: ask for reviews only after high-satisfaction events, never after support failures, refunds, sync conflicts, or crashes.

9. Telemetry, observability, and SRE

Keelway telemetry must be stable, documented, low-cardinality, and adapter-friendly.

Measurements and metadata

[:keelway, :bridge, :command, :stop]
measurements: %{duration: native_ms}
metadata: %{
  command: "share.invoice",
  platform: :ios,
  app_version: "1.2.3",
  bridge_version: "1.0",
  route_id: "invoice_show",
  capability: :share,
  result: :ok
}

Never put raw user IDs, emails, full paths, product IDs with user-specific suffixes, or device IDs into metric labels. Put sensitive or high-cardinality fields into structured logs/audit/evidence stores.

Event families

* Connection health.
* WebSocket reconnects.
* Offline duration.
* Cache hit/miss.
* Sync lag.
* Mutation queue depth.
* Bridge command latency.
* Capability failure rate.
* Billing funnel.
* App version/platform/device class.
* Crash breadcrumbs.
* Review prompt outcomes.
* Push/deep-link conversion.

Integrations

* Phoenix LiveDashboard: expose a “Mobile” page.
* OpenTelemetry: adapter mapping telemetry events to spans/metrics.
* Parapet: SLO pack for mobile journeys.
* Threadline: optional durable audit/evidence for bridge commands, billing, permission-sensitive actions.
* Chimeway: optional notification adapter for push and operator alerts.

Phoenix and LiveView already emit telemetry, so Keelway should augment, not replace, Phoenix observability.  ￼

Privacy safeguards

* Truncate/normalize route names.
* Hash or avoid device identifiers.
* Do not log bridge payloads by default.
* Redact billing receipt data.
* Provide Keelway.Telemetry.redact/1.
* Include Google Data Safety / Apple privacy checklist docs. Google explicitly says developers are responsible for complete, accurate Data Safety declarations and must account for third-party SDK data handling.  ￼

10. Testing strategy

Use a pyramid, not one giant flaky E2E suite.

Layer 1: Elixir unit tests

Test:

* path policies
* manifest generation
* bridge schema validation
* capability negotiation
* telemetry metadata shape
* security allowlists
* billing normalization
* sync conflict resolution

Phoenix testing uses ExUnit, and Phoenix.LiveViewTest can interact with LiveViews through process communication instead of a browser, which is perfect for fast confidence tests.  ￼

Example tests:

test "manifest excludes admin routes from native cache"
test "bridge command refuses route without capability"
test "native_action emits fallback when capability missing"
test "billing event normalizes apple refund"
test "sync mutation is idempotent across duplicate replay"

Layer 2: Contract tests

Shared JSON fixtures:

contracts/bridge/v1/command.share_invoice.schema.json
contracts/bridge/v1/event.purchase_updated.schema.json
fixtures/bridge/share_invoice.ios.ok.json
fixtures/bridge/share_invoice.android.missing_capability.json
fixtures/billing/apple/refund.json
fixtures/billing/google/grace_period.json

Elixir, Swift, and Kotlin test the same fixtures.

Layer 3: Phoenix feature tests

Use PhoenixTest for host app feature flows across static pages and LiveViews; it is designed as a unified feature testing API for Phoenix/LiveView flows.  ￼

Example tests:

test "mobile invoice flow can request native share"
test "mobile paywall waits for server verification"
test "offline banner appears when native shell reports disconnect"

Layer 4: Playwright web/PWA tests

Use Playwright for:

* mobile viewport rendering
* service worker cache
* network offline/slow 3G simulation
* PWA-like fallback
* accessibility scan hooks

Layer 5: Native unit tests

* XCTest for KeelwayKit.
* Kotlin/JUnit/Robolectric for Android package.
* Contract fixture decoding.
* Capability registry tests.
* Native command execution tests.

Layer 6: Native E2E

Recommend Maestro for v0.1 because it is simple, black-box, YAML-based, and works through accessibility-layer user interactions. Keep Appium as a later option for teams needing full WebDriver ecosystem breadth. Maestro describes itself as an open-source mobile/web UI testing framework and supports iOS/Android flows; Appium is the broader WebDriver-based automation ecosystem.  ￼

Minimum v0.1 Maestro flows:

- launch_app_loads_home.yml
- navigate_native_stack.yml
- bridge_share_invoice.yml
- offline_cached_home.yml
- auth_expired_redirect.yml

Billing tests

* StoreKit configuration file tests.
* Google license tester/sandbox guide.
* Signed transaction fixtures.
* Server notification fixtures.
* Refund/grace/expired state tests.
* “Verified server entitlement before UI unlocks” test.

Flake mitigation

* Deterministic fixture server.
* Seeded database.
* Frozen clock.
* No real third-party APIs in CI.
* Record bridge fixtures.
* Retry only at test-runner orchestration layer, not assertions.
* Keep full native E2E smoke small.

11. CI/CD and release automation

Monorepo layout

Use one repo:

keelway/
  packages/
    keelway/
    keelway_sync/
    keelway_billing/
    keelway_push/
    keelway_media/
  native/
    ios/KeelwayKit/
    android/keelway/
  examples/
    basic_liveview/
    billing_accrue/
    offline_todo/
    media_rindle/
    audio_player/
  contracts/
  fixtures/
  guides/
  .github/workflows/

GitHub Actions supports matrix builds and dependency caching, so use it as the OSS CI backbone.  ￼

Workflows

elixir.yml       # mix format, compile, credo, dialyzer, test
contracts.yml    # JSON schema + fixture compatibility
ios.yml          # swift build/test on macOS runner
android.yml      # gradle test/lint
maestro.yml      # smoke on example app, nightly or protected branches
docs.yml         # ExDoc + guides
release.yml      # Hex/SPM/Maven release orchestration
security.yml     # dependency audit, secret scan, SBOM

Elixir compatibility

Start with:

* Elixir 1.17+ minimum if you want to match existing szTheory packages.
* CI should include latest stable Elixir, currently Elixir 1.19.x as of this research; Elixir 1.19 requires Erlang/OTP 26+ and officially supports OTP 28.1+.  ￼
* Phoenix 1.8+ support. Phoenix 1.8 was released in August 2025 and requires Erlang/OTP 25+.  ￼

Release targets

* Hex: mix hex.publish.
* Docs: HexDocs/ExDoc.
* iOS: SPM tags like ios-v0.1.0 or monorepo tag v0.1.0 with package path.
* Android: GitHub Packages/JitPack during v0.x; Maven Central for v1.0.
* Example apps: fastlane lanes for TestFlight and Play internal track.

fastlane is still the right automation layer for screenshots, signing, TestFlight, and Play uploads; TestFlight supports App Store Connect beta testing and Apple documents Xcode/TestFlight/App Store distribution flows.  ￼

Mobile release pipeline

PR:
  Elixir tests
  Contract tests
  Swift/Kotlin unit tests
  Example app build without signing
Protected branch:
  All above
  Maestro smoke
  Docs build
Release tag:
  Publish Hex packages
  Push SPM tag
  Publish Android artifact
  Publish docs
  Build example app
  Optional TestFlight / Play internal

Signing and secrets

* Never require signing secrets for OSS PRs.
* Use unsigned simulator builds in CI.
* Use protected environments for release signing.
* Template host app secrets:
    * Apple API key
    * App Store Connect issuer/key ID
    * Android keystore
    * Play service account
    * provisioning profiles
* Document revocation and rotation.

Rollback plan

* Hex: publish patch; do not yank except severe cases.
* SPM: release new tag; do not mutate tags.
* Android: publish patch artifact.
* Example app: halt staged rollout or roll forward. Google Play supports staged rollouts for app updates, which can be increased over time.  ￼

12. Documentation and DX

Docs are part of the product.

Required docs:

1. README with 5-minute happy path.
2. Installation guide.
3. “Add mobile to an existing Phoenix app.”
4. “First native action.”
5. “Path configuration and native navigation.”
6. “Offline cache vs offline sync.”
7. “Billing compliance guardrails.”
8. “Testing guide.”
9. “CI/CD guide.”
10. Native bridge protocol reference.
11. Telemetry reference.
12. Security guide.
13. App-store checklist.
14. Troubleshooting guide.
15. Migration guide.
16. Compatibility matrix.
17. szTheory integration guide.

Example apps:

1. Basic Phoenix LiveView app.
2. Billing app integrated with accrue.
3. Offline todo/resource sync app.
4. Media upload/capture app integrated with rindle.
5. Audio playback app.
6. Push/deep-link app.
7. Enterprise auth app with SAML/OIDC docs-only integration.

ExDoc should be excellent. HexDocs is a primary distribution surface for Elixir packages, and ExDoc is the standard documentation generator for Elixir/Erlang projects.  ￼

13. Integration plan for szTheory ecosystem

Package	When	Mechanism	Example API	Failure mode	Why
sigra	Now	Adapter + docs	Keelway.Sigra.mobile_session(conn)	Auth session drift between WebView/native	Mobile auth/session/passkeys/MFA/deep-link login are core. Sigra is already positioned around sessions, MFA, OAuth, passkeys, and generated host-owned auth.  ￼
accrue	v0.2/v0.3	Billing adapter	Keelway.Billing.AccrueAdapter	Native subscription state diverges from web billing	Billing is critical; Accrue owns host billing state.  ￼
accrue_admin	Later	Docs + telemetry	mobile billing dashboard cards	Admin UI couples to mobile package	Useful but not MVP.
accrue_portal	Later	Docs + route policy	hide/alter portal routes in native app	App-store external billing violations	Portal is useful, but mobile billing policy makes it sensitive.  ￼
lattice_stripe	Later	Docs-only + billing adapter boundary	web_provider: :stripe	Accidentally using Stripe for IAP-required digital goods	Keep web billing distinct from StoreKit/Play Billing.  ￼
oarlock	Later	Docs-only + adapter boundary	web_provider: :paddle	Same as Stripe	Paddle can remain web/external only.
threadline	Now	Telemetry adapter	audit bridge.command, purchase.verified	Too much PII in audit metadata	Mobile actor context and billing/security events need durable evidence.
chimeway	v0.2	Push adapter	Keelway.Push.ChimewayAdapter.deliver/2	Push tokens stale or over-notify	Chimeway is durable notifications; mobile push is natural.  ￼
mailglass	Later	Docs + events	onboarding, receipt, review/support emails	Email flows duplicate mobile push	Useful for onboarding/billing/support loops. Mailglass composes on Swoosh with previews/admin/event ledger.  ￼
scrypath	v0.3+	Offline search adapter	export search shards to local cache	Index size/privacy leaks	Offline search is useful but not MVP. Scrypath is Ecto-native search indexing.  ￼
rindle	v0.2/v0.3	Media adapter	Keelway.Media.RindleAdapter.create_upload_intent/2	Upload sessions leak or orphan	Camera/file capture maps naturally to Rindle’s media lifecycle.  ￼
rendro	Later	Docs + bridge action	preview/share PDFs	Large documents cached insecurely	Useful for invoices/documents, not MVP.
lockspire	Later	Docs + enterprise auth routing	OIDC/SAML deep-link callback guide	Enterprise auth callback breaks in app	Important for B2B later.
relyra	Later	Docs + adapter	SAML mobile session continuation	Same	Valuable but not first release.
cairnloop	Later	Telemetry listener	review prompt after resolved support	Asking for reviews after bad outcomes	Great for reputation loops.
parapet	Now	SLO pack	Keelway.Parapet.mobile_slos/0	Metric cardinality	Mobile SLOs are high-leverage.
scoria	Later	Controls/streaming UX docs	safe controls for AI/mobile long-running actions	Overcouple mobile shell to AI	Shape-of-AI-style controls are useful patterns, but not core mobile. Shape of AI’s “Controls” pattern emphasizes stop/pause/queue for expensive long-running actions.  ￼

14. MVP and roadmap

v0.1 MVP

Ambitious enough to matter, small enough to ship:

* keelway Hex core.
* iOS WKWebView shell.
* Android WebView shell.
* Path configuration.
* Local bundled manifest + remote manifest refresh.
* Platform detection plug.
* Manifest endpoint.
* Bridge envelope and JSON schema fixtures.
* One native action: share.
* One native UX primitive: native navigation stack.
* One offline feature: cached read-only home/settings route + offline banner.
* Telemetry baseline.
* Mix/Igniter installer.
* Example Phoenix LiveView app.
* Maestro smoke test.
* GitHub Actions CI.
* HexDocs.
* No full sync.
* No full billing implementation, but include billing guardrail docs and protocol placeholders.

Challenge to the hypothesis: billing is critical, but a half-baked StoreKit/Play Billing package in v0.1 is dangerous. Ship the billing architecture, checklist, and fixtures in v0.1; implement adapters in v0.2 after the bridge and native shell are stable.

v0.2

* Native bridge components:
    * haptics
    * native alert
    * native sheet
    * file picker
    * camera stub
    * pull-to-refresh
* Push/deep-link basic support.
* StoreKit/Play Billing alpha.
* Accrue entitlement adapter alpha.
* iOS/Android contract test expansion.
* App-store checklist generator.

v0.3

* keelway_sync alpha.
* SQLite native sync client.
* Mutation queue.
* Conflict UI template.
* Rindle media adapter.
* Chimeway push adapter.
* Parapet SLO pack.
* Audio player demo.

v1.0 stability bar

* At least two production reference apps.
* Stable bridge protocol v1.
* Stable telemetry contract.
* Security review.
* App-store submission checklist validated by example apps.
* Store billing sandbox flows tested.
* Offline docs brutally clear.
* Migration guide from v0.x.
* Compatibility matrix for Phoenix/LiveView/iOS/Android.

Explicit non-goals

* Full native renderer.
* LiveView Native replacement.
* Full collaborative offline.
* Universal billing legal compliance engine.
* Hosted SaaS.
* Cross-platform desktop in v0.1.
* AI controls as core product.

First 10 PRs/issues

1. Repo skeleton, license, code of conduct, security policy.
2. packages/keelway Mix project.
3. Bridge envelope structs + JSON schemas.
4. Manifest/path policy DSL.
5. Platform detection plug.
6. iOS shell initial WKWebView + local/remote manifest.
7. Android shell initial WebView + local/remote manifest.
8. Native share bridge action.
9. Telemetry events + ExUnit/contract tests.
10. Example Phoenix app + Maestro smoke + CI.

Risk register

Risk	Severity	Mitigation
App-store billing rejection	High	Billing checklist, native IAP default for app digital goods, server verification, latest-policy review.
WebView security bug	High	Origin allowlists, app-bound domains, no arbitrary JS bridge, OWASP-guided bridge design.
Offline overpromise	High	Explicit docs, route opt-in, stale UI, no full offline LiveView claim.
Native maintenance load	High	Minimal shell, contract tests, small bridge surface.
CI signing complexity	Medium	Unsigned PR builds, protected release environments, fastlane templates.
E2E flake	Medium	Small Maestro smoke, deterministic fixture server.
Version skew	Medium	Protocol negotiation, semver, shared fixtures.
LiveView changes	Medium	Use public Phoenix/LiveView APIs only; no renderer internals.

15. Implementation blueprint

Repo tree

keelway/
  README.md
  LICENSE
  SECURITY.md
  CHANGELOG.md
  mix.exs                         # umbrella-style tooling only, not one package
  packages/
    keelway/
      mix.exs
      lib/
        keelway.ex
        keelway/config.ex
        keelway/manifest.ex
        keelway/route_policy.ex
        keelway/capability.ex
        keelway/live_view.ex
        keelway/telemetry.ex
        keelway/plug/platform.ex
        keelway/plug/manifest.ex
        keelway/bridge/envelope.ex
        keelway/bridge/command.ex
        keelway/bridge/event.ex
        keelway/bridge/error.ex
        keelway/controllers/manifest_controller.ex
        mix/tasks/keelway.install.ex
        mix/tasks/keelway.doctor.ex
      test/
    keelway_sync/
    keelway_billing/
    keelway_push/
    keelway_media/
  native/
    ios/
      Package.swift
      Sources/KeelwayKit/
        KeelwayApp.swift
        KeelwayWebView.swift
        Manifest/
        Bridge/
        Navigation/
        Capabilities/
        Billing/
        Audio/
      Tests/KeelwayKitTests/
    android/
      settings.gradle.kts
      build.gradle.kts
      keelway/
        build.gradle.kts
        src/main/java/io/sztheory/keelway/
          KeelwayActivity.kt
          KeelwayWebView.kt
          manifest/
          bridge/
          navigation/
          capabilities/
          billing/
          audio/
        src/test/
  contracts/
    bridge/v1/
      envelope.schema.json
      command.share.schema.json
      event.capabilities_announced.schema.json
    billing/v1/
    sync/v1/
  fixtures/
    bridge/
    billing/
    sync/
  examples/
    basic_liveview/
    billing_accrue/
    offline_todo/
    media_rindle/
    audio_player/
  guides/
    installation.md
    first-native-action.md
    offline-cache-vs-sync.md
    billing-guardrails.md
    testing.md
    ci-cd.md
    app-store-checklist.md
  .github/workflows/
    elixir.yml
    contracts.yml
    ios.yml
    android.yml
    maestro.yml
    docs.yml
    release.yml
    security.yml

First implementation order

1. Bridge envelope.
2. Manifest format.
3. Route policy DSL.
4. Platform plug.
5. Manifest controller.
6. LiveView helper.
7. iOS shell loads app and manifest.
8. Android shell loads app and manifest.
9. Native navigation.
10. share command.
11. Telemetry.
12. Example app.
13. Contract fixtures.
14. Maestro smoke.
15. Docs.

Elixir type/spec strategy

Use structs, typespecs, and schema validation:

defmodule Keelway.Bridge.Envelope do
  @type kind :: :command | :event | :ack | :error
  @type t :: %__MODULE__{
          protocol: String.t(),
          version: Version.t(),
          id: String.t(),
          kind: kind(),
          name: String.t(),
          payload: map(),
          correlation_id: String.t() | nil,
          idempotency_key: String.t() | nil,
          requires_ack?: boolean()
        }
  @enforce_keys [:protocol, :version, :id, :kind, :name, :payload]
  defstruct [
    :protocol,
    :version,
    :id,
    :kind,
    :name,
    :payload,
    :correlation_id,
    :idempotency_key,
    requires_ack?: false
  ]
end

CI YAML outline

name: elixir
on:
  pull_request:
  push:
    branches: [main]
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        elixir: ["1.17", "1.18", "1.19"]
        otp: ["26", "27", "28"]
        exclude:
          - elixir: "1.17"
            otp: "28"
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          elixir-version: ${{ matrix.elixir }}
          otp-version: ${{ matrix.otp }}
      - uses: actions/cache@v4
        with:
          path: |
            ~/.hex
            ~/.mix
            packages/keelway/deps
            packages/keelway/_build
          key: ${{ runner.os }}-${{ matrix.elixir }}-${{ matrix.otp }}-${{ hashFiles('**/mix.lock') }}
      - run: mix deps.get
        working-directory: packages/keelway
      - run: mix format --check-formatted
        working-directory: packages/keelway
      - run: mix test
        working-directory: packages/keelway

16. Footguns and hard-earned lessons

Footgun	What goes wrong	Why	Keelway prevention	Residual risk
Hotwire-style app feels like a cheap WebView	Users notice browser-like nav, bad loading, no native polish	Shell only wraps website	Native nav, sheets, skeletons, haptics, pull-to-refresh, route policies	Some flows still need fully native screens
Path config drift	Native app presents route incorrectly	Manifest changed server-side	Bundle local manifest, refresh remote, version policies	Old binaries still exist
Bridge security hole	Untrusted page calls native privileged action	JS bridge exposed too broadly	Origin allowlists, route command allowlists, signed manifest, schema validation	XSS in trusted origin still serious
LiveView offline fantasy	Offline page looks interactive but can’t act	LiveView needs server connection	Stale/readonly state, explicit sync resources	Users may still expect full offline
Service worker assumptions	iOS/Android WebView behavior differs	Embedded browser constraints	Native cache as source of offline truth	Platform changes
Billing rejection	App links to external payment for IAP-required digital goods	Store rules nuanced and changing	Billing checklist, native IAP default, region docs, server verification	Legal/policy ambiguity remains
Receipt spoofing	Client purchase success unlocks access	Trusting native client too much	Server verification required	Provider outage delays access
React Native/Expo-style version skew	OTA/UI expects native capability not installed	App binary lags server	Capability negotiation and fallback	Users on ancient app versions
Capacitor plugin sprawl	Every feature is a plugin/version problem	Hidden native dependency surface	Small official capability registry	Advanced apps need custom native code
Flutter/KMP rewrite trap	Phoenix app becomes only an API backend	Separate frontend dominates	Keelway keeps Phoenix routes first	Complex consumer apps may need full native
App permission fatigue	Users deny camera/location/push	Prompt too early or unclearly	Point-of-use pre-permission UX	User can still deny
Audio over WebView	Background/queue/interruptions fail	Web audio/browser limits	Native AVFoundation/Media3 adapters	Audio apps need serious native work
CI signing hell	OSS PRs cannot build/release	Secrets unavailable	Unsigned simulator builds, protected release lanes	Release setup remains painful
E2E flake	Tests fail randomly	Network, animation, simulator state	Small Maestro smoke + deterministic fixture server	Native E2E never zero-flake
Cross-language semver mismatch	Swift expects bridge v1.1; server emits v1.2	Multiple package managers	Shared contracts, compatibility matrix, protocol negotiation	Maintainer discipline required
OSS maintainer overload	Library tries to support everything	Scope creep	Modular packages, strict non-goals	Demand will push for more adapters
Crux dependency temptation	Rust shared core adds a third runtime	Crux solves shared behavior, not Phoenix server shell	Borrow typed boundary/effects ideas only	Could revisit for native sync core later

Crux is worth studying, not adopting as the core. It has excellent ideas: shared behavior core, thin native shells, managed effects, cross-language type generation, and fast tests. But it is Rust-centered, pre-1.0 with expected breaking changes, and aimed at sharing app behavior across native/web shells—not preserving a Phoenix/LiveView server-centric app.  ￼

17. Final recommendation and first PR checklist

Build Keelway as the Phoenix equivalent of “Hotwire Native done with Elixir taste”: server-rendered Phoenix first, native shell second, explicit bridge contracts, honest offline, strict telemetry, serious billing guardrails, and optional szTheory adapters.

The winning strategy is:

1. Core Phoenix package for route policies, platform detection, manifest, bridge, telemetry, generators.
2. Small native shells in Swift/Kotlin.
3. Native polish by default where users feel it.
4. No fake offline.
5. Billing handled as a first-class compliance engineering surface.
6. Adapters, not forced dependencies, for szTheory packages.
7. Contract tests and CI from day zero.

First PR checklist

[ ] Create repo, license, SECURITY.md, CODE_OF_CONDUCT.md
[ ] Add packages/keelway Mix project
[ ] Add Keelway.Bridge.Envelope + JSON schema
[ ] Add Keelway.Manifest + RoutePolicy
[ ] Add Keelway.Plug.Platform
[ ] Add manifest endpoint/controller
[ ] Add use Keelway.LiveView helper
[ ] Add iOS KeelwayKit skeleton
[ ] Add Android keelway skeleton
[ ] Add native share command contract
[ ] Add telemetry events and docs
[ ] Add example Phoenix LiveView app
[ ] Add Maestro smoke flow
[ ] Add GitHub Actions for Elixir/contracts/iOS/Android
[ ] Publish HexDocs draft

The most important product decision is restraint: Keelway should make Phoenix apps shippable to mobile with native polish, not become a sprawling cross-platform UI framework. Build the bridge, navigation, manifest, telemetry, tests, and app-store guardrails first; add sync, billing, media, push, and audio as explicit opt-in packages once the core shell is trusted.