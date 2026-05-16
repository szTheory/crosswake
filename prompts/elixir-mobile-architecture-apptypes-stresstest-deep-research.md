Yes — the broader stress test says Keelway should support more than offline, but only by being disciplined about where each capability lives.

The stronger framing is:

Keelway is a Phoenix-native mobile deployment substrate. It should let Phoenix/LiveView own server-centric app flows, while native screens/adapters own platform-heavy flows, and offline islands own local-first flows.

It should not become “Phoenix React Native,” “Phoenix Flutter,” or “one framework for every mobile app.” The architecture wins when it provides route policy, native navigation, bridge contracts, capability negotiation, content/media packs, telemetry, CI/testing, generators, and adapter seams — then lets app-specific native modules take over where WebView/LiveView is the wrong runtime.

⸻

1. The refined architecture after this broader stress test

The library should classify every mobile route by runtime mode, native capability level, and offline/media/security policy.

route "/dashboard",
  runtime: :live_view,
  offline: :unavailable,
  capabilities: []
route "/lesson/:id",
  runtime: :live_view,
  offline: {:cached_read_only, ttl: {14, :days}},
  media_pack: :lesson_assets
route "/study/session",
  runtime: {:offline_island, "study.session"},
  content_pack: :daily_study,
  sync: :study_reviews,
  capabilities: [:audio, :haptics]
route "/audio/player",
  runtime: {:native_screen, "audio.player"},
  media_pack: :lesson_audio,
  capabilities: [:background_audio, :lock_screen_controls]
route "/camera/capture",
  runtime: {:native_screen, "media.capture"},
  capabilities: [:camera, :microphone, :file_upload],
  sync: :media_uploads
route "/billing",
  runtime: {:native_screen, "billing.paywall"},
  capabilities: [:storekit, :play_billing],
  cache: :never,
  sensitive: true

The key idea: do not choose one runtime for every screen. Choose per route.

Hotwire Native is the closest precedent: it uses path configuration for native navigation behavior, bridge components for web/native communication, and native screens for cases that should leave web content entirely. That triad is exactly what Keelway should copy, but with Phoenix route policy, LiveView helpers, Telemetry, and Ecto/sync semantics layered in. (native.hotwired.dev￼, native.hotwired.dev￼, native.hotwired.dev￼)

⸻

2. The “capability ladder”

Keelway should offer a ladder from least-native to most-native. This keeps the architecture flexible without becoming a giant framework.

Level	Runtime	Use when	Example
0	Plain Phoenix / LiveView	Online-first SaaS UX	dashboard, settings, admin
1	LiveView + native shell	Needs native nav/polish but server UI is fine	invoices, account, profile
2	LiveView + bridge components	Needs small native affordances	share sheet, haptics, alert, menu
3	Cached/degraded route	Useful stale/read-only	lesson page, docs, invoice
4	Offline island	Must run local web/JS logic	flashcards, quiz, cart, drafts
5	Native screen	Platform-heavy UX	camera, audio, maps, billing, scanner
6	Native SDK adapter	Deep platform/vendor SDK	POS terminal, HealthKit, ARCore, WebRTC
7	Do not use Keelway as primary UI	Needs full custom app/game engine	AAA game, advanced AR, heavy 3D, pro creative tools

This is the most important product/API idea. Keelway should help teams climb the ladder only when needed.

⸻

3. Cross-ecosystem lessons to bake in

Hotwire Native lesson: path config + bridge + native screens

Hotwire Native’s docs explicitly say Bridge Components solve the communication gap between siloed web content and the native app, while native screens are for fully native Swift/Kotlin screens. Keelway should treat that as a proven architectural pattern, not just an inspiration. (native.hotwired.dev￼, native.hotwired.dev￼)

Keelway takeaway: ship RoutePolicy, BridgeComponent, and NativeScreen as first-class concepts.

Capacitor lesson: capability plugins need explicit permission and web fallback semantics

Capacitor describes itself as a native runtime for web apps across iOS, Android, and PWA, with plugins exposing native APIs; its camera docs show the kind of platform permission detail that quickly appears even for one “simple” feature. (capacitorjs.com￼, capacitorjs.com￼)

Keelway takeaway: every native capability should have:

platform support
permission requirements
web fallback
payload schema
telemetry
test fixtures
failure modes

React Native / Expo lesson: version the native/web boundary

React Native’s Turbo Native Modules use typed specs and Codegen to define the methods/data that cross the JS/native boundary. Expo’s EAS Update runtime-version docs say updates must match the native runtime because native code cannot be changed by an over-the-air update. (reactnative.dev￼, docs.expo.dev￼)

Keelway takeaway: version everything crossing the boundary:

bridge_protocol_version
native_runtime_version
capability_version
native_screen_version
content_pack_schema_version
sync_resource_schema_version

WebView security lesson: the bridge is dangerous by default

Android warns that addJavascriptInterface exposes a Java object to all WebView frames, and OWASP recommends origin-scoped messaging over legacy bridge models because iframe access and missing origin controls make JS bridges unsuitable as a security boundary. WebKit App-Bound Domains likewise limit powerful WKWebView APIs to app-declared domains. (developer.android.com￼, mas.owasp.org￼, webkit.org￼)

Keelway takeaway: route allowlists, origin allowlists, manifest signatures, capability allowlists, and active-route checks are not optional.

Media lesson: web playback is not enough for serious audio/video apps

Android Media3 documents offline media downloads and recommends a DownloadService when downloads should continue in the background; Apple AVFoundation documents offline playback/storage for streamed content. (developer.android.com￼, developer.apple.com￼)

Keelway takeaway: create media_pack and native_media_adapter concepts. Do not route high-frequency playback state through LiveView.

Animation lesson: polish belongs in native/UI-thread primitives

Lottie renders After Effects animations natively on iOS/Android/Web, while Rive provides interactive state-machine-driven animations across runtimes. React Native Reanimated emphasizes UI-thread animations for smooth interaction. Apple’s reduced-motion evaluation criteria also make motion accessibility a product requirement, not a nice-to-have. (lottie.airbnb.tech￼, rive.app￼, docs.swmansion.com￼, developer.apple.com￼)

Keelway takeaway: native transition/haptic primitives should be built in; Lottie/Rive should be optional adapters; reduced-motion settings should be propagated to Phoenix/LiveView and offline islands.

⸻

4. App archetype stress tests

4.1 B2B SaaS / admin / customer portal

Fit: excellent.

This is the core Keelway sweet spot: dashboards, settings, account pages, invoices, billing portals, support, notifications, and customer/admin workflows. Most screens can be LiveView with native navigation, bridge components, deep links, push notifications, and modest caching.

route "/dashboard",
  runtime: :live_view,
  offline: :unavailable
route "/invoices/:id",
  runtime: :live_view,
  offline: {:cached_read_only, ttl: {7, :days}},
  capabilities: [:share, :document_preview]

Design accommodation: strong path policy, native nav, share sheets, document preview, push/deep links, app-store screenshots, review/support prompts, telemetry.

Footgun: caching admin or sensitive billing screens. Keelway should default-deny /admin/*, /auth/*, /billing/checkout, and any route marked sensitive: true.

Verdict: first-class target.

⸻

4.2 Subscription SaaS / digital goods / paywalled apps

Fit: good, but policy-sensitive.

This includes course apps, creator subscriptions, premium tools, language learning apps, and paid communities. The app may use LiveView for product UX, but billing needs native StoreKit/Play Billing when app-store rules require it, plus server-side receipt verification and entitlement mapping.

Apple’s App Review Guidelines organize review expectations across safety, performance, business, design, and legal, and Apple’s App Store Server Notifications send server-to-server events for in-app purchase lifecycle changes. Google Play’s alternative billing docs and real-time developer notification docs show that billing policy and entitlement sync are moving, backend-integrated surfaces. (developer.apple.com￼, developer.apple.com￼, developer.android.com￼, developer.android.com￼)

route "/billing",
  runtime: {:native_screen, "billing.paywall"},
  capabilities: [:storekit, :play_billing],
  cache: :never,
  sensitive: true

Design accommodation: keelway_billing, provider adapters, server verification behaviours, receipt fixtures, restore purchases, entitlement events, optional accrue adapter.

Footgun: treating purchase success as entitlement success. Entitlement must become active only after server verification and reconciliation.

Verdict: first-class target, but separate package and explicit compliance checklist.

⸻

4.3 Language learning / flashcards / training content

Fit: very good if offline islands/content packs exist.

This app stresses offline, media, animation, haptics, local scheduling logic, and progress sync.

route "/study/session",
  runtime: {:offline_island, "study.session"},
  content_pack: :daily_study,
  sync: :study_reviews,
  media_pack: :card_media,
  capabilities: [:audio, :haptics]

Design accommodation: content packs, media packs, local JS/native study engine, append-only review event log, scheduler test vectors, Rive/Lottie optional animations, native audio cache.

Footgun: making every answer call handle_event/3. The study loop should not depend on LiveView.

Verdict: a flagship example app. It proves Keelway can do more than “wrap a SaaS dashboard.”

⸻

4.4 Media course / podcast / audio-learning app

Fit: good only with native media support.

LiveView can handle catalog, notes, progress, comments, and subscription. Native should handle playback, background audio, lock-screen controls, downloads, and interruption handling.

route "/audio/player",
  runtime: {:native_screen, "audio.player"},
  media_pack: :lesson_audio,
  sync: :playback_events,
  capabilities: [:background_audio, :lock_screen_controls]

Design accommodation: keelway_media, media_pack, native audio adapters, coarse playback telemetry, offline downloads, storage budget UI.

Footgun: streaming playback progress every second through LiveView. Native owns high-frequency playback state; Phoenix receives coarse events like started, paused, completed, checkpoint.

Verdict: support as a serious optional package, not core v0.1.

⸻

4.5 Video course / telehealth / live coaching

Fit: mixed.

For asynchronous video courses, Keelway can work well with native media downloads and playback. For live telehealth/video calls, Keelway should coordinate the session but not own the media stack. WebRTC is a specialized runtime for peer audio/video/data; the official WebRTC project describes it as supporting video, voice, and generic data across browsers and native clients. (webrtc.org￼)

route "/appointments/:id",
  runtime: {:native_screen, "video.session"},
  online_required: true,
  capabilities: [:camera, :microphone, :webrtc]

Design accommodation: native screen adapter for WebRTC/Twilio/Daily/Agora/etc.; LiveView for scheduling, intake forms, post-call notes, payments, support.

Footgun: trying to pipe real-time video/audio through LiveView or the generic bridge.

Verdict: support via native screen/adapters only. Do not make video SDKs part of core.

⸻

4.6 Creator / camera / media upload app

Fit: good with native capture/upload adapters.

Think bug-report screenshots, customer support attachments, creator video clips, document scans, field evidence, insurance claims.

route "/media/capture",
  runtime: {:native_screen, "media.capture"},
  capabilities: [:camera, :microphone, :file_picker],
  sync: :media_uploads

Design accommodation: upload intents, native file cache, background/resumable upload, optional rindle adapter, progress UI, privacy redaction.

Apple’s BackgroundTasks framework is for keeping app content up to date and running tasks that take minutes in the background, while Android foreground-service rules and permissions make long-running camera/microphone/location/media work highly platform-sensitive. (developer.apple.com￼, developer.android.com￼)

Footgun: using a WebView form upload for large files. App backgrounding, retries, file permissions, and upload progress all get fragile.

Verdict: strong optional package; natural rindle integration.

⸻

4.7 Field service / inspections / logistics forms

Fit: excellent if offline forms/media/location are first-class.

This app stresses GPS, camera, signatures, large forms, offline drafts, queueing, and sync reconciliation.

route "/jobs/:id/inspection",
  runtime: {:offline_island, "inspection.form"},
  content_pack: :assigned_jobs,
  sync: [:inspection_events, :media_uploads],
  capabilities: [:camera, :location, :signature]

Design accommodation: offline form generator, draft persistence, media upload queue, location permission story, conflict review screens, operator telemetry.

Android’s location permission docs emphasize that requested permissions depend on use case and that foreground/background access differ; this reinforces why Keelway should generate permission rationale screens and app-store checklist items. (developer.android.com￼)

Footgun: requesting location/camera/microphone globally at onboarding. Prompts should be point-of-need and route/capability-driven.

Verdict: flagship example app candidate.

⸻

4.8 Maps / delivery / route planning

Fit: moderate to good, but maps should be native/vendor SDK.

LiveView can manage dispatch, lists, stops, customer details, proof-of-delivery, and operations dashboards. Native should own maps, route visualization, location updates, offline map tiles, and turn-by-turn navigation.

Mapbox’s mobile docs explicitly support offline maps by downloading selected regions for rendering without internet access. (docs.mapbox.com￼)

route "/routes/:id",
  runtime: {:native_screen, "route.map"},
  capabilities: [:maps, :location, :background_location],
  content_pack: :route_manifest,
  sync: :delivery_events

Design accommodation: maps adapter boundary, content pack for route/stop data, offline map adapter, location event log, battery-aware telemetry.

Footgun: treating background location as a normal permission. It is expensive, sensitive, and policy-reviewed.

Verdict: support through adapter seams, not core map implementation.

⸻

4.9 Event check-in / barcode / NFC / access control

Fit: very good.

This app stresses scanners, local manifests, duplicate detection, signed short-lived data, and reconciliation.

route "/events/:id/checkin",
  runtime: {:native_screen, "ticket.scanner"},
  content_pack: :event_ticket_manifest,
  sync: :ticket_scans,
  capabilities: [:barcode_scanner, :nfc]

Design accommodation: signed content packs, barcode/NFC bridge components, append-only scan events, local duplicate detection, short-lived sensitive cache.

Footgun: modeling scans as ticket.redeemed = true in local mutable state. Multiple offline devices will conflict. Use scan events and server reconciliation.

Verdict: strong support; good security test case.

⸻

4.10 POS / retail / restaurant / payments

Fit: limited but strategically important.

Cart UI, menu browsing, loyalty, and order drafts can work well. Payments and terminal integrations require vendor SDK adapters and risk-aware UX.

Stripe Terminal’s offline docs say offline card payment info is collected at time of sale, but authorization is only attempted after connectivity returns; Square similarly imposes offline limits and upload deadlines. (docs.stripe.com￼, squareup.com￼)

route "/pos",
  runtime: {:native_screen, "pos.terminal"},
  capabilities: [:terminal_payments, :receipt_printer],
  sync: :pos_sales,
  risk: [:offline_authorization_pending]

Design accommodation: adapter seam for Stripe Terminal/Square/etc.; offline-sale event log; explicit risk state; receipts; settlement deadlines.

Footgun: showing “paid” when payment is merely captured offline and not authorized.

Verdict: support as adapter pattern, not core. Keelway should not become a POS SDK.

⸻

4.11 Chat / support / inbox / social feed

Fit: good for lightweight chat/support; not ideal for high-scale realtime social unless backed by specialized sync.

LiveView is strong for online support inboxes and admin/operator UX. Mobile needs local message cache, push, delivery state, attachment queue, and optimistic sending.

route "/inbox",
  runtime: :live_view,
  offline: {:offline_island, "inbox.local"},
  sync: [:message_stream, :message_outbox],
  capabilities: [:push, :file_picker]

Design accommodation: stream sync primitive, local outbox, attachment queue, message delivery states, push/deep links, optional cairnloop and chimeway integrations.

Footgun: using LiveView streams as if they were durable mobile sync. LiveView streams render online lists; mobile chat needs local persistent stream state and ordering rules.

Verdict: good support for support/chat-lite. For Slack/Discord-scale chat, Keelway should be shell/glue around a dedicated messaging backend.

⸻

4.12 AI copilot / voice tutor / long-running workflow app

Fit: good if control semantics are explicit.

LiveView is great for streaming server output and operator workflows. Mobile needs cancellation, retry, resume, push notification, offline drafts, voice/audio capture, and guardrails around tool calls.

route "/assistant",
  runtime: :live_view,
  offline: {:draft_only, key: "assistant_prompt"},
  capabilities: [:microphone, :audio_playback, :push],
  controls: [:stop, :retry, :resume]

Design accommodation: bridge commands for stop/pause/resume; idempotent job IDs; Scoria/OpenInference telemetry adapter; native microphone/audio components.

Footgun: unbounded bridge-triggered AI tool calls with no cancellation, timeout, audit, or idempotency.

Verdict: strong fit, especially with scoria, as long as controls are first-class.

⸻

4.13 Health / fitness / wellness / habit tracking

Fit: possible, but privacy/permission-heavy.

Habit tracking and wellness content fit well. HealthKit/Health Connect, workouts, sensors, and medical data need native adapters and strict privacy.

Apple HealthKit requires fine-grained permission to read/share each health data type, and Google’s Health Connect publishing guidance requires declaring data types, Data Safety details, and policy compliance. (developer.apple.com￼, developer.android.com￼)

route "/workout/session",
  runtime: {:native_screen, "fitness.session"},
  capabilities: [:health_read, :health_write, :sensors],
  sync: :workout_events,
  sensitive: true

Design accommodation: health capability package, redacted telemetry, local encryption, permission story generator, Data Safety/App Privacy checklist docs.

Footgun: treating health data like normal telemetry or bridge payloads.

Verdict: adapter-only; high compliance burden. Not v0.1.

⸻

4.14 Fintech / banking / accounting / payroll

Fit: moderate.

Read-only dashboards, invoices, receipts, approvals, and expense drafts fit. Money movement, payroll, trades, and entitlements must be online-authoritative and heavily audited.

route "/expenses/new",
  runtime: :live_view,
  offline: {:draft_only, key: "expense_draft"},
  capabilities: [:camera, :document_scanner]
route "/transfers/new",
  runtime: :live_view,
  online_required: true,
  cache: :never,
  sensitive: true

Design accommodation: draft-only mode, document scanning, secure storage, threadline audit adapter, idempotency, redaction, no offline financial commits.

Footgun: generic offline mutation queue for financial actions.

Verdict: good for peripheral workflows; critical financial execution must remain online/server-authoritative.

⸻

4.15 Marketplace / booking / ecommerce

Fit: good with separation between intent and commitment.

Browse/catalog/cart can degrade or run offline. Inventory, pricing, checkout, and reservation commitment must be online-authoritative.

route "/cart",
  runtime: {:offline_island, "cart.local"},
  sync: :cart_events
route "/checkout",
  runtime: :live_view,
  online_required: true,
  cache: :never

Design accommodation: local cart event log, stale price labels, online checkout gate, billing/payment policy guardrails.

Footgun: letting stale offline inventory imply an item is reserved or price is guaranteed.

Verdict: strong if Keelway makes “offline intent, online commit” easy.

⸻

4.16 Gaming / highly animated interactive apps

Fit: weak for real games; decent for game-like UI.

Keelway can support gamified SaaS, language learning, habit streaks, badges, haptics, animations, and lightweight mini-games. It should not try to be a game engine.

Flutter’s Flame engine exists specifically to provide game-loop, component system, collisions, gestures, sprites, animations, and audio on top of Flutter. That is the kind of specialized runtime Keelway should not recreate. (docs.flame-engine.org￼, pub.dev￼)

route "/streaks",
  runtime: :live_view,
  capabilities: [:haptics, :lottie, :rive]
route "/mini-game",
  runtime: {:native_screen, "game.embedded"},
  engine: :custom

Design accommodation: haptic primitives, Rive/Lottie adapters, reduced-motion propagation, native screen escape hatch.

Footgun: driving game-loop animation through LiveView diffs or bridge messages.

Verdict: gamification yes; serious games no.

⸻

4.17 AR / VR / spatial apps

Fit: poor as core, possible as native screen launchpad.

AR requires camera, sensors, depth, spatial anchors, rendering, device support, and native/engine-level lifecycle. Android’s ARCore/Jetpack XR docs discuss depth maps and geospatial APIs for placing content in real-world locations; those are deeply native capabilities. (developer.android.com￼, developers.google.com￼)

route "/ar/lesson",
  runtime: {:native_screen, "ar.lesson"},
  capabilities: [:camera, :arcore, :arkit],
  online_required: false

Design accommodation: native screen adapter only. Phoenix can provide content/config/sync; native owns AR.

Footgun: trying to make AR a bridge component inside a WebView.

Verdict: not a primary target. Support as native module escape hatch.

⸻

4.18 IoT / device control / Nerves-adjacent apps

Fit: surprisingly good if connection model is richer.

A device app may be “offline from cloud” but still connected over LAN/BLE to a local Phoenix/Nerves device. Keelway should distinguish internet, server socket, LAN, BLE, and device reachability.

route "/devices/:id/control",
  runtime: {:native_screen, "device.control"},
  connectivity: [:cloud, :lan, :ble],
  capabilities: [:bluetooth, :local_network],
  sync: :device_command_log

Design accommodation: connectivity-state model, BLE/local-network capability adapters, command event logs, safety confirmations.

Footgun: treating “no internet” as “no functionality.” For edge apps, the local device may still be reachable.

Verdict: good adapter target, not core v0.1.

⸻

4.19 Enterprise SSO / regulated internal apps

Fit: excellent for internal tooling, but auth flows need care.

LiveView is excellent for enterprise workflows. Native app needs deep links, universal/app links, secure session handling, SAML/OIDC browser handoff, and device trust signals.

route "/sso/callback",
  runtime: :web_auth_callback,
  cache: :never,
  sensitive: true

Design accommodation: optional lockspire/relyra/sigra docs and adapters, external browser auth sessions, token/session handoff policies, secure storage.

Footgun: embedding third-party SSO flows entirely inside a WebView when provider/platform guidelines expect system browser/auth-session behavior.

Verdict: strong fit with careful auth adapters.

⸻

5. The app-type fit matrix

App type	Fit	Primary Keelway mode	Must be native?	Main risk
B2B SaaS/mobile portal	Excellent	LiveView + shell	Sometimes	stale/sensitive cache
Billing/subscription SaaS	Good	LiveView + native paywall	Yes for IAP	policy rejection
Flashcards/education	Very good	offline island + media packs	Sometimes	fake offline
Podcast/audio course	Good	native audio screen	Yes	background playback
Video course	Good	native media screen	Usually	storage/range requests
Telehealth/live video	Mixed	native video SDK screen	Yes	realtime media complexity
Creator/camera uploads	Good	native capture screen	Yes	background uploads
Field service	Excellent	offline island/native	Sometimes	conflict/media queue
Maps/logistics	Moderate/good	native map screen	Yes	battery/location policy
Event check-in	Very good	native scanner + signed pack	Yes	duplicate/fraud
POS/restaurant	Limited/good	native terminal adapter	Yes	payment risk
Chat/support	Good	LiveView + local outbox	Sometimes	ordering/delivery state
AI copilot	Good	LiveView + controls	Sometimes	runaway jobs/tools
Health/fitness	Possible	native health adapter	Yes	privacy/policy
Fintech/accounting	Moderate	LiveView + drafts	Sometimes	unsafe offline mutation
Marketplace/ecommerce	Good	cart island + online checkout	Sometimes	stale price/inventory
Gaming	Weak/moderate	native screen/game engine	Yes	game loop/performance
AR/VR	Weak	native AR screen	Yes	rendering/sensors
IoT/device	Good	native/local screen	Often	connectivity semantics
Enterprise/internal	Excellent	LiveView + auth adapters	Sometimes	SSO/session handling

⸻

6. Architecture decisions this stress test suggests

Decision 1: Add runtime: not just offline:

Earlier we mostly talked about offline. That is too narrow. Use a route-level runtime declaration:

runtime :live_view
runtime {:offline_island, "study.session"}
runtime {:native_screen, "audio.player"}
runtime {:external_browser, reason: :auth}

This cleanly handles audio, video, AR, maps, payment terminals, and WebRTC without forcing them into “offline” language.

Decision 2: Add a capability registry with permission stories

capability :camera,
  platforms: [:ios, :android],
  permission: :runtime,
  rationale: MyApp.Mobile.PermissionStories.Camera,
  telemetry: true
capability :background_location,
  platforms: [:ios, :android],
  permission: :sensitive,
  app_store_review_notes: true

This is how Keelway avoids the Capacitor-style plugin sprawl footgun while still supporting many capabilities.

Decision 3: Add media_pack separate from content_pack

content_pack is structured JSON/data. media_pack is files/download/playback/storage.

media_pack :lesson_audio,
  assets: [:audio],
  playback: :native,
  background: true,
  storage_budget: 2_000_000_000

This matters because audio/video/map tiles behave differently from JSON.

Decision 4: Make native screens host-owned but contract-generated

Generated native screen stubs should be host-owned:

mix keelway.gen.native_screen AudioPlayer --ios --android

Keelway owns the protocol and base runtime. The app owns the screen logic.

Decision 5: Keep bridge messages semantic and low-frequency

Good bridge message:

{"name": "audio.play", "payload": {"track_id": "lesson_123"}}

Bad bridge message:

{"name": "audio.progress", "payload": {"position_ms": 12345}}

High-frequency UI, audio, video, sensor, gesture, and animation loops must stay native/local.

Decision 6: Add runtime compatibility gates

Borrow Expo’s runtime-version idea:

requires_runtime ios: ">=0.3.0", android: ">=0.3.0"
requires_capability "audio.player", ">=1.0"

The server manifest should never tell old app binaries to use unsupported native screens or commands.

⸻

7. Concrete API sketch after this pass

defmodule MyAppWeb.Mobile.RoutePolicy do
  use Keelway.RoutePolicy
  route "/dashboard",
    runtime: :live_view,
    presentation: :root,
    offline: :unavailable
  route "/lessons/:id",
    runtime: :live_view,
    presentation: :push,
    offline: {:cached_read_only, ttl: {14, :days}},
    content_pack: :lesson_text,
    media_pack: :lesson_images
  route "/study/session",
    runtime: {:offline_island, "study.session"},
    presentation: :push,
    offline: :read_write,
    content_pack: :daily_study,
    media_pack: :card_media,
    sync: :study_reviews,
    capabilities: [:audio, :haptics]
  route "/audio/player",
    runtime: {:native_screen, "audio.player"},
    presentation: :modal,
    media_pack: :lesson_audio,
    sync: :playback_events,
    capabilities: [:background_audio, :lock_screen_controls]
  route "/media/capture",
    runtime: {:native_screen, "media.capture"},
    capabilities: [:camera, :microphone, :file_picker],
    sync: :media_uploads
  route "/billing",
    runtime: {:native_screen, "billing.paywall"},
    capabilities: [:storekit, :play_billing],
    cache: :never,
    sensitive: true
  deny "/admin/*",
    cache: :never,
    capabilities: []
end

Capability declaration:

defmodule MyApp.Mobile.Capabilities do
  use Keelway.Capabilities
  capability :share
  capability :haptics
  capability :camera, permission_story: MyApp.Mobile.PermissionStories.Camera
  capability :background_audio, native_required: true
  capability :storekit, platform: :ios, package: :keelway_billing
  capability :play_billing, platform: :android, package: :keelway_billing
end

Native screen registry:

defmodule MyApp.Mobile.NativeScreens do
  use Keelway.NativeScreens
  screen "audio.player",
    ios: "AudioPlayerViewController",
    android: "AudioPlayerFragment",
    contract: MyApp.Mobile.AudioPlayerContract
  screen "billing.paywall",
    ios: "PaywallViewController",
    android: "PaywallFragment",
    contract: MyApp.Mobile.PaywallContract
end

⸻

8. What Keelway should deliberately not support deeply

AAA games / serious 3D games

Keelway can launch a native/game-engine screen, but should not provide the game loop, renderer, physics, sprite system, or asset pipeline. Use Unity, Unreal, Godot, Flame, Flutter, or native engines.

Advanced AR/spatial apps

Keelway can provide content/config/sync and a native screen hook. ARKit/ARCore/XR lifecycle belongs to native code or game engines.

High-frequency trading / mission-critical financial execution

Keelway can wrap dashboards and approvals. Do not queue critical trades or money movement through generic offline mutation queues.

Medical diagnosis / regulated clinical workflows

Keelway can help with app shell, auth, telemetry, and native adapters. Regulatory validation, clinical safety, device certification, and HIPAA/GDPR-style compliance are outside the library’s scope.

Pro creative tools

Drawing, video editing, music production, CAD, and timeline editing usually need native/engine-level rendering and device-specific performance. Keelway can host account/project/sync screens, not the core editor.

⸻

9. GSD-oriented validation plan

Before building too much, prototype five examples that stress different axes.

Example A: SaaS portal

Validates:

LiveView shell
native nav
bridge components
deep links
telemetry

Example B: Flashcard/audio study app

Validates:

offline island
content pack
media pack
local scheduler
review event log
haptics/animation

Example C: Field inspection app

Validates:

offline form
camera
signature
location permission story
media upload queue
conflict UI

Example D: Audio player app

Validates:

native screen
background audio
offline media download
lock-screen controls
playback telemetry

Example E: Billing/paywall app

Validates:

StoreKit/Play Billing bridge
server verification
entitlement state
restore purchases
app-store checklist

If those five examples work, Keelway’s architecture is probably broad enough for most Phoenix SaaS/mobile products without becoming a monster.

⸻

10. Final takeaways

The broader app-type stress test does not invalidate the plan. It makes the plan more precise.

The final architecture should be:

Phoenix/LiveView:
  online-first UI, server business logic, dashboards, portals, settings
Keelway core:
  route policy, native shell, bridge, telemetry, manifest, navigation
Keelway offline:
  content packs, offline islands, local data, sync/event journals
Keelway media:
  media packs, native download/playback/upload adapters
Keelway billing:
  native purchases, server verification, entitlement mapping
Native screens:
  camera, audio, maps, POS, health, AR, video, hardware SDKs
Adapters:
  app-specific native/vendor integrations without bloating core

The architecture should accommodate many app categories by letting each route declare:

What runtime owns this screen?
What native capabilities may it use?
What happens offline?
What data/media must be local?
What events/resources sync?
What must remain online/server-authoritative?

That keeps Keelway powerful without destroying its architecture. The winning constraint is: Keelway should make the hard boundary explicit, not invisible.