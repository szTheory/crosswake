Yes — and this stress test makes the architecture stronger.

The big refinement is: Keelway should not only support “LiveView + mobile shell.” It should support a spectrum of mobile screen modes, because different apps have different “must keep working offline / must feel native / must be server-authoritative” pressure.

The durable strategy is:

LiveView for online-first screens. Cached/degraded web for read-only screens. Offline islands for offline-critical web-compatible workflows. Native screens for high-polish or platform-bound workflows. Sync/event logs/content packs for reconciliation.

That is the difference between a useful Phoenix mobile library and a fragile “WebView wrapper.”

⸻

1. The architecture after stress-testing

I would formalize Keelway around five screen/runtime modes.

route "/dashboard",
  mode: :live_view,
  offline: :unavailable
route "/invoices/:id",
  mode: :live_view,
  offline: {:cached_read_only, ttl: {7, :days}}
route "/support/new",
  mode: :live_view,
  offline: {:draft_only, key: "support_ticket"}
route "/study/session",
  mode: {:offline_island, "study.session"},
  content_packs: [:daily_study],
  sync: [:study_reviews]
route "/camera/capture",
  mode: {:native_screen, "media.capture"},
  sync: [:media_uploads]

Those modes map to real constraints:

Mode	Best for	Offline behavior	Native work
:live_view	Dashboards, settings, admin, billing overview	reconnect banner only	low
:cached_read_only	Invoices, docs, lesson pages, status summaries	stale page, disabled actions	low/moderate
:draft_only	Support tickets, notes, long forms	local draft, submit later manually	moderate
:offline_island	Flashcards, POS cart, event scanning, checklists	local data + local logic + sync queue	moderate/high
:native_screen	camera, audio, maps, health, payments, complex offline	native local store + native UX	high

This matches Android’s official offline-first guidance: offline-first starts in the data layer, requires a local data source, and should let users read local data without network access. It also matches the Hotwire Native lesson that WebView/native-shell apps need path configuration, bridge components, and native screens instead of pretending all web screens are equal.  ￼

The main architectural addition I would make before GSD starts is a new package:

keelway_offline
  content packs
  offline islands
  storage budgets
  media manifests
  local schema contracts
  durable event journals

Then keelway_sync handles resource sync, mutation queues, and reconciliation.

⸻

2. Cross-cutting primitives Keelway should have

2.1 Content packs

A content pack is a downloadable, versioned bundle of structured data plus media.

It is not just “cache this URL.” It is:

{
  "name": "daily_study",
  "version": "2026-05-12:user_123:abc",
  "schema_version": 4,
  "expires_at": "2026-05-19T00:00:00Z",
  "resources": {
    "cards": "/packs/daily_study/cards.json",
    "decks": "/packs/daily_study/decks.json"
  },
  "media": [
    {
      "id": "card_123_audio",
      "url": "https://cdn.example.com/card_123.m4a",
      "sha256": "abc...",
      "bytes": 42102,
      "priority": "required"
    }
  ]
}

This unlocks flashcards, training apps, field manuals, maps, audio lessons, onboarding modules, support knowledge bases, and media-heavy apps.

The web/PWA side can use service workers, Cache Storage, and IndexedDB; MDN and web.dev both recommend separating cached network resources from structured data storage. But browser storage is not a perfect guarantee because quota and eviction behavior vary, so native apps should use SQLite/file cache for serious offline support.  ￼

2.2 Durable outbox / event journal

A durable outbox is for “I did something offline; sync it later.”

event_log :study_reviews,
  event: MyApp.Study.ReviewEvent,
  idempotency_key: true,
  reconcile: MyApp.Study.Reconciler

This is better than mutating arbitrary rows locally when the domain is event-like: flashcard reviews, POS sales, event ticket scans, support drafts, sensor readings, audit events, and media captures.

Firebase Realtime Database is a useful reference: with persistence enabled, it stores local data and queues writes to send after reconnect, but its docs also warn that some transactions are not persisted across app restarts and that auth expiration can pause writes. That is exactly the kind of nuance Keelway should surface rather than hide.  ￼

2.3 Resource sync

A resource sync is for normal CRUD-ish things.

defmodule MyApp.Mobile.TodoSync do
  use Keelway.Sync.Resource,
    name: :todos,
    schema: MyApp.Todos.Todo,
    scope: :current_user
  fields [:id, :title, :completed, :lock_version, :updated_at]
  version field: :lock_version
  tombstone field: :deleted_at
  mutations [:create, :update, :delete],
    idempotency_key: true,
    conflict: MyApp.Mobile.TodoConflictResolver
end

PowerSync and Replicache are the strongest inspiration here. PowerSync keeps backend data in sync with in-app SQLite and uses scoped sync streams for offline-first data; Replicache uses local mutators, push/pull endpoints, and app-specific conflict handling. Keelway should copy the conceptual contract without forcing either dependency.  ￼

2.4 Offline islands

An offline island is a JS/web component that can run without LiveView.

route "/study/session",
  mode: {:offline_island, "study.session"},
  content_packs: [:daily_study],
  sync: [:study_reviews]

This is perfect for the language-learning flashcard example. It lets Phoenix own data, auth, billing, and sync, while the study loop runs locally in JS when offline.

2.5 Native screens

A native screen is for workflows where WebView/JS is the wrong runtime:

route "/audio/player",
  mode: {:native_screen, "audio.player"},
  content_packs: [:lesson_audio],
  sync: [:playback_events]

Use native screens for audio, video, camera, maps, POS terminals, health sensors, background location, and high-performance gesture UI.

2.6 Capability and runtime version negotiation

Keelway should copy one lesson from Expo and React Native: native capability versioning must be explicit. Expo EAS Update uses runtime versions so JS updates only go to builds with compatible native code, and React Native’s new architecture uses Codegen specs for typed native-module boundaries. Keelway should similarly version bridge commands, native screens, content pack schemas, and capability availability.  ￼

Example:

{
  "bridge_version": "0.2",
  "runtime_version": "ios-0.2.1",
  "capabilities": {
    "content_pack.download": "1.0",
    "audio.play": "1.0",
    "purchase.start": "0.2",
    "location.track": "0.1"
  }
}

⸻

3. Stress-test app types

3.1 Language learning / flashcard / media education app

This is your example, and it is one of the best stress tests.

Hard parts

* Daily curriculum must download ahead of time.
* Cards must render offline.
* Audio/images/video must be cached.
* The “next card” decision must run locally.
* Answers must be recorded offline.
* Progress must sync and reconcile.
* Multiple devices may study the same deck.
* Scheduler version changes can make old local calculations stale.

Recommended Keelway mode

route "/study/session",
  mode: {:offline_island, "study.session"},
  content_packs: [:daily_study],
  sync: [:study_reviews],
  fallback: {:native_screen, "study.session"}

Design implication

Use content packs + append-only review events.

defmodule MyApp.Mobile.DailyStudyPack do
  use Keelway.Offline.ContentPack,
    name: :daily_study,
    scope: :current_user
  resources [:cards, :decks, :curriculum_nodes, :card_progress]
  media [:card_audio, :card_images, :lesson_video]
  storage_budget max_bytes: 750 * 1024 * 1024,
                 required: [:cards, :card_audio],
                 optional: [:lesson_video]
end
defmodule MyApp.Mobile.StudyReviews do
  use Keelway.Sync.EventLog,
    name: :study_reviews,
    idempotency_key: true
  reconcile MyApp.Study.Reconciler
end

Anti-pattern

Do not make the actual study loop a normal LiveView where every answer calls handle_event/3. If the user goes offline, the core job-to-be-done breaks.

Big win

This app proves Keelway can support true offline product workflows without becoming a native renderer.

⸻

3.2 Field service / inspections / forms app

Think: HVAC inspections, property management, construction punch lists, safety audits, medical-device field checks.

Hard parts

* Users work in basements, rural areas, factories, or job sites with poor connectivity.
* They need checklists, PDFs/manuals, photos, signatures, GPS stamps, and offline form submission.
* Sync must survive app restarts.
* Attachments can be large.
* Conflicts often require manual review, not silent last-write-wins.

Recommended Keelway mode

route "/jobs/:id/inspection",
  mode: {:offline_island, "inspection.form"},
  content_packs: [:assigned_jobs],
  sync: [:inspection_events, :media_uploads]

Design implication

Add a first-class draft + event log + media upload queue pattern.

offline_form :inspection,
  draft: true,
  autosave_every: {10, :seconds},
  attachments: :queued,
  completion_event: :inspection_submitted

Android’s offline-first docs specifically call out local data sources, queued writes, retry/backoff, and conflict handling for writes; Android WorkManager is the right native primitive for persistent deferred work with constraints such as network availability.  ￼

Anti-pattern

Do not use a normal LiveView form with “submit later” hacked into localStorage. That loses attachments, signatures, and restart durability.

Big win

Keelway can ship a generator:

mix keelway.gen.offline_form Inspection \
  --photos \
  --signature \
  --gps \
  --sync event_log

That is a huge DX advantage for Phoenix SaaS/internal-tools teams.

⸻

3.3 POS / retail / restaurant app

This is a brutal stress test because offline is useful but risky.

Hard parts

* Cart should work offline.
* Inventory may become stale.
* Taxes/discounts can be complex.
* Payments may be impossible or risky offline.
* Receipts, refunds, and reconciliation matter.
* Offline card payments have provider-specific limits and decline risk.

Stripe Terminal supports offline collection by storing payments locally and forwarding them when connectivity returns, but it also says authorization only happens after the payment is forwarded after reconnect. Square’s offline docs similarly impose time and amount limits; payments may be declined if not processed in time.  ￼

Recommended Keelway mode

route "/pos",
  mode: {:native_screen, "pos.terminal"},
  sync: [:pos_sales],
  capabilities: ["terminal.offline_payments", "receipt.print"]

Design implication

Keelway should not own POS payments, but it should support an adapter pattern:

defmodule MyApp.Mobile.POS do
  use Keelway.Sync.EventLog,
    name: :pos_sales,
    idempotency_key: true
  reconcile MyApp.POS.Reconciler
  payment_adapter MyApp.POS.StripeTerminalAdapter
end

Event model:

{
  "event": "sale_recorded",
  "sale_id": "sale_123",
  "cart": [...],
  "payment": {
    "mode": "offline_terminal",
    "provider": "stripe_terminal",
    "provider_reference": "..."
  },
  "risk": {
    "authorization_pending": true
  }
}

Anti-pattern

Do not show “paid” when the transaction is merely collected offline and authorization is pending. Use “payment pending sync” or “offline payment captured; authorization pending.”

Big win

Keelway can provide a generic risk-aware offline action primitive:

offline_action :collect_payment,
  risk: :provider_authorization_pending,
  requires_user_ack: true,
  settlement_deadline: {24, :hours}

That pattern also helps with uploads, signatures, and compliance approvals.

⸻

3.4 Event ticketing / access control app

Think conference check-in, venue entry, school pickup, secure facility access.

Hard parts

* Ticket scans must work offline.
* Duplicate scans must be prevented locally.
* Multiple gates/devices may scan the same ticket offline.
* Server must reconcile duplicates later.
* Fraud and replay attacks matter.
* Local data must expire.

Recommended Keelway mode

route "/events/:id/checkin",
  mode: {:native_screen, "ticket.scanner"},
  content_packs: [:event_ticket_manifest],
  sync: [:ticket_scan_events]

Design implication

Use signed content packs + append-only scan events.

content_pack :event_ticket_manifest,
  signed: true,
  expires_in: {12, :hours},
  resources: [:valid_tickets],
  privacy: :sensitive
event_log :ticket_scans,
  idempotency_key: true,
  conflict: :server_reconcile

Anti-pattern

Do not model ticket state as one mutable “redeemed: true” row on each device. Two offline gates can both mark the same ticket redeemed. Use scan events and let the server reconcile.

Big win

This motivates signed manifests and short-lived offline packs. That security work benefits billing, enterprise auth, and field apps too.

⸻

3.5 Chat / support inbox / collaboration feed

Think embedded customer support, team chat, comments, notification center.

Hard parts

* Realtime online behavior matters.
* Offline send queue matters.
* Message ordering is subtle.
* Read receipts and delivery state can be stale.
* Attachments need upload queues.
* Encryption may be needed.
* “Last write wins” is wrong for message streams.

Matrix is a useful reference: its client-server API is designed for clients that either keep little state or maintain a full local persistent copy of server state. Firebase Realtime Database is another reference: it persists data and write queues locally and syncs after reconnect, but with caveats around auth tokens and transactions.  ￼

Recommended Keelway mode

route "/inbox",
  mode: :live_view,
  offline: {:offline_island, "inbox.local"},
  sync: [:messages, :message_drafts, :attachments]

Design implication

Provide a stream sync primitive distinct from CRUD resource sync.

stream_sync :messages,
  order: :server_sequence,
  local_outbox: true,
  delivery_states: [:queued, :sent, :delivered, :failed],
  attachments: :queued

Anti-pattern

Do not use LiveView streams as the offline storage model. LiveView streams are excellent for rendering server-managed lists online, but offline chat needs local persistent message state, durable outbox, and server sequence reconciliation.

Big win

Keelway can integrate well with cairnloop and chimeway later:

Keelway.Push.ChimewayAdapter
Keelway.Support.CairnloopAdapter

The UX pattern also generalizes to notifications, comments, and activity feeds.

⸻

3.6 Collaborative document / whiteboard / shared notes app

This is the hardest offline-sync stress test.

Hard parts

* Multiple users edit the same document offline.
* Conflicts should merge automatically.
* Ordering and intent preservation matter.
* “Server wins” or “last write wins” destroys user work.
* Data structures can grow large.
* Sync protocol must be domain-specific.

Automerge is explicitly built for local-first collaborative apps and uses CRDTs so concurrent changes can be merged automatically without a central server deciding every conflict. But its own materials note that lower-level CRDT libraries still need storage/networking/application integration.  ￼

Recommended Keelway mode

route "/docs/:id",
  mode: {:offline_island, "collab.document"},
  sync: [{:crdt, adapter: MyApp.Mobile.AutomergeAdapter}]

Design implication

Keelway should not implement CRDTs in core. It should provide a CRDT adapter slot:

collaboration :crdt,
  adapter: MyApp.Mobile.AutomergeAdapter,
  storage: :local,
  server_archive: MyApp.Documents.Archive

Anti-pattern

Do not expose:

conflict :auto_merge_everything

CRDTs work for certain data structures, not arbitrary business state like billing, permissions, or inventory.

Big win

Keelway remains honest: normal apps get resource/event sync; collaborative apps plug in CRDT engines.

⸻

3.7 Maps / logistics / delivery / route planning app

Think delivery driver, field technician, outdoor guide, inspection routes.

Hard parts

* Maps must work offline.
* Routes may need predictive caching.
* Background location permissions are heavily restricted.
* Location updates drain battery.
* Users need route progress even with spotty network.
* App review may reject unnecessary background location.

Mapbox’s mobile SDK supports offline map regions and predictive caching for navigation; Android’s Play guidance says background location must be core to the app and expected by users, and Android foreground services have strict restrictions and required service types. Apple also requires explicit background modes for location-related behavior.  ￼

Recommended Keelway mode

route "/routes/:id",
  mode: {:native_screen, "logistics.route"},
  content_packs: [:route_manifest, :offline_map_region],
  sync: [:location_events, :delivery_events]

Design implication

Add a Keelway.Location capability package or adapter boundary:

location_tracking :delivery_route,
  mode: :foreground_service,
  background: :only_when_route_active,
  sampling: {:adaptive, min_meters: 25, max_seconds: 60},
  battery_budget: :medium

Anti-pattern

Do not ask for background location globally during onboarding. Permission prompts must be point-of-need, scoped, and justified.

Big win

Keelway can ship a permission story generator:

mix keelway.gen.permission_story location --background --reason route_tracking

This could generate docs, native strings, app-store checklist items, and runtime rationale screens.

⸻

3.8 Podcast / audio course / music-learning app

Think language audio, guided meditations, podcasts, music practice.

Hard parts

* Background playback.
* Offline downloads.
* Lock-screen controls.
* Interruption handling.
* Audio session/category handling.
* Large media storage.
* Progress sync.
* Low-latency sound effects may need native audio.

Android Media3 supports offline media downloads using download services, indexes, caches, and requirements; Apple supports background audio modes and background/download URL sessions. Web audio is not enough for serious background playback.  ￼

Recommended Keelway mode

route "/audio/player",
  mode: {:native_screen, "audio.player"},
  content_packs: [:audio_lessons],
  sync: [:playback_events]

Design implication

Add native media abstractions:

media_pack :audio_lessons,
  assets: [:lesson_audio],
  playback: :native,
  background: true,
  resume_position: true

Event log:

event_log :playback_events,
  events: [:started, :paused, :completed, :position_checkpoint]

Anti-pattern

Do not send playback progress every second through LiveView. Native owns high-frequency playback state; server receives coarse events.

Big win

The same media-pack infrastructure helps flashcards, training apps, creator apps, and offline courseware.

⸻

3.9 Creator / media capture / upload app

Think video testimonials, bug reports with screenshots, field evidence, document scanning, creator uploads.

Hard parts

* Camera and microphone permissions.
* Large uploads.
* App can be killed mid-upload.
* Background upload behavior differs across platforms.
* Local media storage can leak sensitive data.
* Upload status must be visible.

Apple documents background URLSession downloads/uploads for background transfers; Android foreground/background restrictions make long-running media operations platform-sensitive. Capacitor’s camera docs are also a useful reminder that native permissions and platform-specific file/storage behavior must be explicit, even in hybrid apps.  ￼

Recommended Keelway mode

route "/media/capture",
  mode: {:native_screen, "media.capture"},
  sync: [:media_uploads]

Design implication

Use upload intents:

defmodule MyApp.Mobile.MediaUploads do
  use Keelway.Sync.EventLog,
    name: :media_uploads
  upload_intent MyApp.Media.UploadIntent
  adapter Keelway.Media.RindleAdapter
end

Native flow:

capture locally
compress/transcode if configured
create local upload record
upload when network allows
mark uploaded
server finalizes media lifecycle

Anti-pattern

Do not base large uploads on a WebView form post. It is too fragile for app backgrounding, retries, progress, and resumability.

Big win

This becomes a natural optional integration with rindle.

⸻

3.10 Fitness / health / habit tracking app

Think habit tracker, medication reminders, workout logs, wearable integration, health metrics.

Hard parts

* Sensitive data and permission UX.
* HealthKit / Health Connect data is user-controlled.
* Background sensors and workouts are platform-specific.
* Sync must be privacy-preserving.
* App-store and Play policies are stricter for health data.

Apple HealthKit requires fine-grained authorization and gives users control over health data sharing. Health Connect similarly requires SDK setup and user permissions; Google Play has specific guidance for health permissions.  ￼

Recommended Keelway mode

route "/workout",
  mode: {:native_screen, "fitness.session"},
  sync: [:workout_events],
  capabilities: ["health.read", "health.write"]

Design implication

Keelway should treat health data as a high-sensitivity capability:

capability :health_read,
  sensitivity: :high,
  requires_explicit_user_action: true,
  telemetry_payloads: :redacted,
  cache: :encrypted

Anti-pattern

Do not store raw health metrics in generic telemetry or bridge logs.

Big win

This forces Keelway’s privacy model to be serious: redaction, local encryption, permission rationale screens, and low-cardinality telemetry.

⸻

3.11 Telehealth / live class / video appointment app

Think video call with doctor/tutor, live class, coaching session.

Hard parts

* Realtime audio/video cannot be LiveView.
* Camera/microphone permissions.
* Network quality changes.
* Background behavior is constrained.
* Privacy and recording rules.
* Chat/notes/forms alongside call.

Recommended Keelway mode

route "/appointments/:id",
  mode: {:native_screen, "video.session"},
  online_required: true,
  degraded: {:cached_read_only, "appointment.details"}

Design implication

Keelway should not own WebRTC/video SDKs. It should expose native screen adapters:

native_screen "video.session",
  adapter: MyApp.Mobile.VideoAdapter,
  required_capabilities: ["camera", "microphone", "network.realtime"]

Anti-pattern

Do not try to run serious realtime video as a LiveView bridge command stream. LiveView can coordinate metadata and post-call flows, but not own video frames.

Big win

This validates the “native screen escape hatch” for high-performance workflows.

⸻

3.12 Finance / accounting / invoicing app

Think invoicing, expense approvals, payroll, bill pay, financial dashboards.

Hard parts

* Sensitive data.
* Stale data can mislead.
* Offline edits must be carefully scoped.
* Payments cannot be casually queued.
* Audit trails matter.
* Reconciliation and idempotency are mandatory.

Recommended Keelway mode

route "/invoices/:id",
  mode: :live_view,
  offline: {:cached_read_only, ttl: {24, :hours}},
  sensitive: true
route "/expenses/new",
  mode: :live_view,
  offline: {:draft_only, key: "expense_draft"}

Design implication

Add a route sensitivity model:

sensitive "/billing/*",
  cache: :never,
  bridge_payload_logging: false,
  commands: ["purchase.start", "purchase.restore"]
sensitive "/invoices/:id",
  cache: {:read_only, ttl: {24, :hours}},
  redact_telemetry: true

Anti-pattern

Do not queue money movement or entitlement-changing actions as generic offline mutations.

Big win

This integrates beautifully with threadline audit and accrue billing state while keeping them optional.

⸻

3.13 Marketplace / e-commerce / booking app

Think inventory, carts, checkout, reservations, subscriptions.

Hard parts

* Inventory changes quickly.
* Cart can be offline, but checkout usually cannot.
* Pricing, taxes, discounts, and availability must be authoritative.
* App-store billing rules apply for digital goods.
* External payment rules vary by region and change over time.

Apple’s App Review Guidelines are explicitly organized around safety, performance, business, design, and legal, and Apple’s IAP materials describe StoreKit for premium content, virtual goods, and subscriptions. This is a policy-sensitive category that Keelway must document as guardrails rather than legal advice.  ￼

Recommended Keelway mode

route "/cart",
  mode: {:offline_island, "cart.local"},
  sync: [:cart_events]
route "/checkout",
  mode: :live_view,
  online_required: true,
  cache: :never

Design implication

Separate “offline cart intent” from “server-authorized checkout.”

event_log :cart_events,
  events: [:item_added, :item_removed, :quantity_changed],
  reconcile: MyApp.Cart.Reconciler
online_only :checkout,
  reason: :pricing_inventory_payment_authority

Anti-pattern

Do not let stale offline inventory imply that a product is reserved.

Big win

This is a clean pattern for many SaaS flows: offline intent, online commitment.

⸻

3.14 Enterprise admin / internal ops dashboard

Think admin panels, customer support back office, data tables, feature flags, audit logs.

Hard parts

* Mostly online.
* Security > offline.
* Data can be stale or sensitive.
* Deep links and native shell still useful.
* App may need SSO/SAML/OIDC.
* App review less relevant if internal/TestFlight/enterprise distribution.

Recommended Keelway mode

route "/admin/*",
  mode: :live_view,
  offline: :unavailable,
  cache: :never,
  commands: []

Design implication

Keelway should have safe defaults:

deny "/admin/*",
  native_commands: [],
  cache: :never,
  offline: :unavailable

Anti-pattern

Do not cache admin pages just because the WebView cache can.

Big win

This mode is easy and very valuable: Keelway gives native nav, SSO-friendly routing, push/deep links, and telemetry while not creating offline risk.

⸻

3.15 IoT / device control / Nerves-adjacent app

Think local network device dashboards, smart home, industrial sensors, Nerves devices.

Hard parts

* Device may be on local network without internet.
* Phoenix server may run on the device.
* Local discovery, BLE, LAN, mDNS, or direct IP.
* Offline from cloud does not mean offline from device.
* Safety-critical commands need confirmation and audit.
* Native permissions may include Bluetooth/location.

Recommended Keelway mode

route "/devices/:id/control",
  mode: {:native_screen, "device.control"},
  connectivity: [:cloud, :lan, :ble],
  sync: [:device_command_log]

Design implication

Keelway should distinguish internet offline from local device reachable.

connection_states [:internet, :lan, :device, :server_socket]

Anti-pattern

Do not equate “not connected to Phoenix cloud” with “no functionality.” A Nerves/local Phoenix device could be reachable over LAN.

Big win

This expands Keelway beyond SaaS consumer apps into edge/device apps without changing the core architecture.

⸻

3.16 AI copilot / voice assistant / long-running workflow app

Think AI tutor, coding assistant, support assistant, data analyst, voice coach.

Hard parts

* Streaming UX.
* Long-running jobs.
* Cancellation/stop/pause controls.
* Offline fallback may require local cached prompts/content but not model execution.
* Tool calls must be safe.
* Reconnect after long generation.
* Telemetry/evals matter.

Recommended Keelway mode

route "/assistant",
  mode: :live_view,
  offline: {:cached_read_only, "recent_threads"},
  controls: [:stop, :retry, :resume],
  sync: [:draft_messages]

Design implication

Keelway should provide control semantics for long-running operations:

native_action :stop_generation,
  command: "ai.stop",
  idempotency_key: true
offline :draft_only

Anti-pattern

Do not let native bridge commands trigger unbounded server tools without idempotency, cancellation, timeout, and audit.

Big win

This fits your scoria ecosystem: traces, evals, tool approvals, and mobile UX controls can compose through telemetry/adapters.

⸻

4. The stress-test matrix

App type	Best primary mode	Sync primitive	Native capability pressure	Biggest design lesson
Flashcards / language learning	Offline island or native screen	Content pack + event log	media cache/audio	Offline-critical UX needs local logic.
Field service	Offline island/native	Draft + event log + media queue	camera, GPS, signatures	Forms need restart-safe drafts and queued attachments.
POS	Native screen	Sale event log	terminal/payment SDK	Offline payment is risk state, not success state.
Event check-in	Native screen	Signed pack + scan events	barcode/NFC	Use event logs, not local mutable redeemed flags.
Chat/support	LiveView + offline island	Stream sync + outbox	push, attachments	Message ordering and delivery states matter.
Collaborative docs	Offline island	CRDT adapter	low/moderate	CRDTs are opt-in, not default CRUD sync.
Maps/logistics	Native screen	Location/delivery events	maps, GPS, background	Background location is policy/battery-sensitive.
Audio/course	Native screen	Playback event log + media pack	background audio	Native owns playback; server gets coarse events.
Media capture	Native screen	Upload queue	camera, mic, background upload	WebView uploads are too fragile for large media.
Fitness/health	Native screen	Health/workout events	HealthKit/Health Connect	Privacy and permissions are first-class.
Telehealth/video	Native screen	Session metadata	camera/mic/video SDK	LiveView coordinates; native/video SDK renders.
Finance/accounting	LiveView + read-only cache	Drafts only for safe forms	secure storage	Do not queue money movement generically.
Marketplace	LiveView + cart island	Cart intent events	billing/payment	Offline cart, online checkout.
Admin dashboard	LiveView	none	low	Default deny cache/native commands.
IoT/device	Native screen + local web	Command event log	BLE/LAN/local network	Distinguish cloud offline from device reachable.
AI copilot	LiveView + draft cache	Drafts + job controls	audio/voice optional	Long-running controls need idempotency/cancel/audit.

⸻

5. What this means for Keelway’s package design

I would adjust the package map:

keelway
  Phoenix plugs, route policy, manifest, bridge, telemetry, LiveView helpers.
keelway_offline
  content packs, offline islands, storage budgets, local schema metadata,
  media manifests, web/PWA service worker helpers.
keelway_sync
  resource sync, event logs, mutation queue, durable outbox,
  conflict resolution, checkpoints, Phoenix/Ecto endpoints.
keelway_media
  media download/cache/upload intents, audio/video handoff,
  optional rindle integration.
keelway_billing
  StoreKit/Play Billing, purchase verification, entitlement mapping,
  optional accrue/lattice_stripe/oarlock adapters.
keelway_native_ios
  Swift package: WKWebView shell, navigation, bridge, content packs,
  native cache, media, background transfer, screens.
keelway_native_android
  Kotlin package: WebView shell, navigation, bridge, content packs,
  Room/SQLite, WorkManager, media, screens.

I would avoid creating too many domain packages early. For example, do not make keelway_pos, keelway_health, keelway_maps in v0.x. Instead expose adapter seams:

Keelway.NativeScreen
Keelway.Capability
Keelway.Sync.EventLog
Keelway.Offline.ContentPack
Keelway.Media.Downloader
Keelway.PermissionStory

That gives you the big wins without dependency hell.

⸻

6. Design changes I would make before implementation

6.1 Add offline: to route policy from day zero

route "/study/session",
  mode: {:offline_island, "study.session"},
  offline: :read_write,
  content_packs: [:daily_study],
  sync: [:study_reviews]

Do not retrofit offline later.

6.2 Add content pack interfaces in v0.1

Even if minimal:

defmodule MyApp.Mobile.DailyStudyPack do
  use Keelway.Offline.ContentPack,
    name: :daily_study
  resources [:cards]
  media [:card_audio]
end

6.3 Add event log before full resource sync

Event logs are simpler and safer than bidirectional row sync for many offline workflows: flashcard reviews, scans, sales, location pings, uploads, playback, drafts, and audit events.

event_log :study_reviews,
  idempotency_key: true,
  reconcile: MyApp.Study.Reconciler

6.4 Add native storage adapters

Web/PWA:
  IndexedDB + Cache API + service worker
iOS:
  SQLite/GRDB or lightweight SQLite wrapper + file cache
Android:
  Room/SQLite + WorkManager + file cache

6.5 Add bridge security as a first-class product surface

Android explicitly warns that addJavascriptInterface exposes Java objects to all WebView frames and lacks origin-based access control; Android’s newer WebView bridge docs recommend more careful origin-aware patterns. WebKit’s App-Bound Domains similarly constrains powerful APIs to app-bound domains for privacy/security. Keelway should therefore use route/capability allowlists, origin-scoped bridge access, and no wildcard bridge permissions in production.  ￼

6.6 Add native runtime compatibility rules

Borrow the Expo/RN lesson:

Server manifest version
Bridge protocol version
Native runtime version
Content pack schema version
Sync resource schema version
Capability version

A server should not send audio.download_hls@2.0 to an app binary that only supports audio.download_hls@1.0.

⸻

7. Lessons from other ecosystems distilled

Hotwire Native

Copy:

* path configuration,
* native navigation,
* bridge components,
* native screens,
* “web content, native navigation” mindset.

Avoid:

* pretending offline is solved by the shell.
* DOM-only bridge when LiveView can also emit server commands.

Hotwire Native’s docs explicitly describe server-rendered HTML in a native shell, native navigation/animations, bridge components, and path configuration.  ￼

LiveView Native

Copy:

* ambition,
* typed native UI interest,
* Phoenix-native enthusiasm.

Avoid:

* dependency on LiveView private renderer/diff assumptions,
* native rendering as the core bet,
* archived/unstable core dependency.

The main LiveView Native repository is archived/read-only as of February 10, 2026, and the project positioned itself as letting one LiveView serve web and non-web clients through platform-specific native UI templates; that is exactly the risky coupling Keelway should avoid.  ￼

Android offline-first

Copy:

* local data source first,
* repository abstraction,
* queued writes,
* sync worker,
* conflict handling,
* battery/network-aware fetch.

Avoid:

* UI-first offline design.

Android’s official guidance says offline-first design starts in the data layer and that repositories need local and network data sources.  ￼

Firebase

Copy:

* local cache + write queue + automatic reconnect semantics.

Avoid:

* hiding conflict semantics and transaction caveats.

Firestore and Realtime Database both support offline data access and queued writes, but Firebase’s own docs show important caveats around query cache, auth tokens, and transactions.  ￼

PowerSync / Replicache

Copy:

* local SQLite,
* scoped sync,
* push/pull,
* mutators/event logs,
* explicit backend reconciliation.

Avoid:

* making Keelway a full database replication company in v0.1.

PowerSync positions itself as syncing backend databases with in-app SQLite, and Replicache positions itself as backend-agnostic realtime/offline sync.  ￼

Automerge / CRDTs

Copy:

* CRDT adapter for collaborative documents.

Avoid:

* CRDTs as default for SaaS CRUD.

Automerge is designed for local-first collaborative apps with automatic merging, but CRDTs are a specialized model, not a replacement for all business workflows.  ￼

Capacitor / React Native / Flutter

Copy:

* capability/plugin boundaries,
* typed native bridges,
* permission discipline,
* runtime compatibility.

Avoid:

* plugin sprawl,
* hidden native version mismatches,
* chatty high-frequency bridge calls.

Capacitor’s plugin docs show explicit permission handling; React Native’s new architecture emphasizes typed specs and generated native interfaces; Flutter platform channels are the official mechanism for platform-specific native calls.  ￼

⸻

8. The most important anti-goals after this stress test

Keelway should not say:

Every Phoenix LiveView works offline.

It should say:

Every Phoenix mobile route declares its offline behavior.
Offline-critical workflows use offline islands or native screens.
Data sync is explicit, typed, observable, and reconcilable.

Keelway should not try to become:

* a full native UI framework,
* a full database replication engine,
* a POS payment provider,
* a telehealth SDK,
* a maps SDK,
* a CRDT engine,
* a health data platform.

It should provide the Phoenix-native glue, contracts, generators, telemetry, and mobile shell architecture that let those capabilities slot in cleanly.

⸻

9. Proposed “hard mode” prototype suite

Before building the full library, I would create four example apps that cover most stress dimensions.

Example 1: Basic SaaS mobile app

Covers:

* LiveView routes.
* native navigation.
* bridge commands.
* push/deep links.
* telemetry.

Example 2: Flashcard offline app

Covers:

* content packs.
* media cache.
* offline island.
* event log.
* sync/reconciliation.

Example 3: Field inspection app

Covers:

* offline form.
* drafts.
* photos.
* signatures.
* upload queue.
* conflict review.

Example 4: Ticket scanning app

Covers:

* signed short-lived content pack.
* barcode scanner.
* duplicate local detection.
* multi-device conflict reconciliation.
* sensitive local data expiration.

Those four examples will reveal more architectural issues than a dozen happy-path demos.

⸻

10. Final recommendation

The stress tests confirm the core strategy, but add one important new emphasis:

Keelway should be an offline-capable mobile deployment substrate for Phoenix, not merely a LiveView WebView wrapper.

The implementation should revolve around:

Route policy:
  what kind of screen is this?
Bridge:
  what native capabilities can this route use?
Offline:
  what can this route do without network?
Content packs:
  what data/media must be downloaded?
Sync:
  what events/resources reconcile later?
Native screens:
  what workflows must leave WebView entirely?
Telemetry:
  what happened, how long, and where did it fail?

The design is well-rounded if it can express all of these without hacks:

route "/study/session",
  mode: {:offline_island, "study.session"},
  content_packs: [:daily_study],
  sync: [:study_reviews],
  media: [:card_audio, :card_images]
route "/jobs/:id/inspection",
  mode: {:offline_island, "inspection.form"},
  sync: [:inspection_events, :media_uploads],
  capabilities: [:camera, :location, :signature]
route "/pos",
  mode: {:native_screen, "pos.terminal"},
  sync: [:pos_sales],
  capabilities: [:terminal_payments],
  risk: [:offline_authorization_pending]
route "/admin/*",
  mode: :live_view,
  offline: :unavailable,
  cache: :never,
  commands: []

That is the defensible architecture: LiveView where it shines, offline islands where local logic is required, native screens where the platform matters, and Phoenix/Ecto as the authoritative reconciliation layer.