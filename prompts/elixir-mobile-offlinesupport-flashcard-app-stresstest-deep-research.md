Yes. That is the right mental model:

Use Phoenix LiveView for screens that are online-first. For screens that absolutely must work offline, do not make the core interaction depend on LiveView. Make those screens offline-capable islands: local data, local media, local logic, queued mutations, and server reconciliation.

For a language-learning flashcard app, I would not build the actual study loop as a normal LiveView screen. I would build the surrounding product in LiveView, then make the study session itself an offline-capable island.

That gives you the best of both worlds:

LiveView:
  dashboard
  course selection
  account/billing
  teacher/admin tools
  progress summaries
  online search
  deck management
  review analytics
Offline-capable island:
  today’s study queue
  flashcard rendering
  audio/image/video playback
  answer grading
  next-card scheduling
  local session progress
  queued review events
  sync/reconcile when online

The architecture we discussed does support this, but this flashcard example sharpens the design: Keelway needs first-class “offline islands” and “content packs,” not only cached pages and sync resources.

⸻

1. The screen taxonomy should be explicit

Keelway should support four screen classes.

A. Normal LiveView screen

Use this for online-first screens.

route "/dashboard",
  presentation: :push,
  offline: :unavailable

Behavior:

Online: LiveView works normally.
Disconnected briefly: LiveView reconnect UI.
Offline long-term: show native/web offline state.

This is fine for dashboards, billing, account settings, admin tools, analytics, and most SaaS flows.

LiveView has public JS hooks, pushEvent, handleEvent, server push_event/3, and disconnected/reconnected lifecycle callbacks, so Keelway can build robust online bridge behavior without patching private LiveView internals. (hexdocs.pm￼)

B. LiveView with graceful degradation

Use this when the page is mostly online but can still be useful stale/read-only.

route "/lesson/:id",
  presentation: :push,
  offline: {:read_only_cache, ttl: {14, :days}},
  cache: :stale_while_revalidate

Behavior:

Online: LiveView.
Offline: cached page with "stale/read-only" badge.
Forms/actions: disabled unless explicitly offline-capable.

This is good for curriculum outlines, help docs, lesson text, already-rendered explanations, and invoice/document previews.

Service workers can act like a proxy that serves cached assets/responses while offline, and common caching strategies include cache-first, network-first, and stale-while-revalidate. (developer.mozilla.org￼)

C. Offline web island

Use this when the UI can be written as a client-side JS island inside the WebView/PWA.

route "/study",
  presentation: :push,
  offline: {:web_island, MyAppWeb.Offline.StudyIsland},
  sync: [MyApp.Mobile.StudySync],
  content_packs: [MyApp.Mobile.DailyStudyPack]

Behavior:

Online: can be launched from LiveView.
Offline: JS island boots from cached assets.
Data: IndexedDB / native SQLite bridge.
Media: Cache API / OPFS / native file cache.
Mutations: queued review events.
Reconnect: sync + reconcile.

This is probably the best first implementation for your language flashcard example because it preserves web/PWA compatibility and still works in a native shell.

Web platform guidance is clear: use Cache Storage for network resources such as HTML/CSS/JS/images/video/audio, and use IndexedDB for structured searchable/combinable data. (web.dev￼)

D. Native offline screen

Use this for the most premium, media-heavy, or performance-sensitive offline screens.

route "/study",
  presentation: {:native_screen, "study.session"},
  offline: {:native_screen, "study.session"},
  sync: [MyApp.Mobile.StudySync],
  content_packs: [MyApp.Mobile.DailyStudyPack]

Behavior:

Online: native study UI can still use Phoenix backend.
Offline: native study UI reads local SQLite/files.
Reconnect: native sync engine flushes review events.

This is best for high-end audio/video, haptics, gestures, spaced-repetition speed, and “game feel.” It is more work than a JS island, but it gives the best mobile experience.

⸻

2. For the flashcard app, the study loop should be offline-first

A flashcard app is a perfect example where normal LiveView is not enough.

The user story is:

I connected earlier.
The app downloaded today’s study pack.
Now I’m on a train / plane / bad Wi-Fi.
I can still study.
Cards, audio, images, and maybe video still work.
My answers are saved locally.
When I reconnect, my progress syncs.
If the server changed something, it reconciles safely.

That requires a local study runtime.

Flashcard offline architecture

Phoenix/LiveView online shell
  -> user chooses deck/course/session
  -> Keelway downloads content pack
Content pack
  -> card JSON
  -> deck/curriculum JSON
  -> scheduling metadata
  -> media manifest
  -> image/audio/video assets
  -> integrity hashes
  -> expiry/version metadata
Offline island/native screen
  -> reads local content
  -> runs local scheduler
  -> plays cached media
  -> records review events
  -> queues mutations
Reconnect
  -> upload review event journal
  -> server validates/idempotently applies
  -> server returns canonical progress/checkpoint
  -> client rebases local state

The study loop should not call handle_event/3 for every answer. It should write a local event.

⸻

3. The key design trick: append-only review events

For flashcards, the safest sync model is append-only review events, not “mutate user progress row directly.”

Bad offline model:

card_progress.due_at = new_due_at
card_progress.ease = new_ease
card_progress.interval = new_interval

That creates painful conflicts if the user studies on two devices.

Better offline model:

review_events append-only:
  user saw card X
  answered at time T
  rating was again/hard/good/easy
  elapsed_ms was 2200
  local_session_id was S
  scheduling_algorithm_version was V

Then the server derives canonical progress from events.

Example event:

{
  "id": "rev_01JZ...",
  "user_id": "user_123",
  "card_id": "card_456",
  "deck_id": "deck_spanish_a1",
  "session_id": "sess_789",
  "rating": "good",
  "elapsed_ms": 2300,
  "answered_at": "2026-05-12T19:15:00Z",
  "base_card_version": 12,
  "base_progress_version": 8,
  "scheduler": {
    "name": "my_app_sm2",
    "version": "2026.05"
  },
  "idempotency_key": "ios-device-abc:sess_789:card_456:3"
}

Server reconciliation:

1. Accept event if user/card/session authorized.
2. Deduplicate by idempotency key.
3. Validate card/deck still exists or map to tombstone behavior.
4. Recompute canonical progress.
5. Return updated due queue/checkpoint.

This drastically reduces conflict complexity. You can still have conflicts, but they become more semantic:

Card deleted while offline.
Deck assignment removed while offline.
User studied same card on two devices.
Scheduler version changed.
Media/content pack expired.

Those are manageable.

⸻

4. Keelway should add “content packs”

The previous plan covered cached pages and sync resources. For flashcards/media-heavy offline, add a new concept:

Content packs: versioned, downloadable bundles of structured data + media assets + integrity metadata.

Example Elixir API:

defmodule MyApp.Mobile.DailyStudyPack do
  use Keelway.Offline.ContentPack,
    name: :daily_study,
    scope: :current_user,
    repo: MyApp.Repo
  version :by_query_hash
  resources do
    resource :cards,
      schema: MyApp.Cards.Card,
      fields: [:id, :front, :back, :deck_id, :tags, :updated_at, :version]
    resource :decks,
      schema: MyApp.Cards.Deck,
      fields: [:id, :title, :language, :updated_at, :version]
    resource :curriculum_nodes,
      schema: MyApp.Curriculum.Node,
      fields: [:id, :title, :position, :parent_id, :updated_at]
  end
  media do
    asset :card_audio, from: MyApp.Cards.CardAudio, ttl: {30, :days}
    asset :card_images, from: MyApp.Cards.CardImage, ttl: {30, :days}
    asset :lesson_video, from: MyApp.Curriculum.Video, ttl: {7, :days}
  end
  preload fn user ->
    MyApp.Study.daily_assignment(user)
  end
  storage_budget max_bytes: 750 * 1024 * 1024,
                 eviction: :least_recently_used,
                 required: [:cards, :card_audio],
                 optional: [:lesson_video]
end

Manifest response:

{
  "pack": "daily_study",
  "version": "2026-05-12:user_123:a1b2c3",
  "expires_at": "2026-05-19T00:00:00Z",
  "schema_version": 4,
  "resources": {
    "cards": "/keelway/packs/daily_study/cards.json",
    "decks": "/keelway/packs/daily_study/decks.json",
    "curriculum_nodes": "/keelway/packs/daily_study/curriculum_nodes.json"
  },
  "media": [
    {
      "id": "audio_card_456_front",
      "url": "https://cdn.example.com/audio/card_456_front.m4a",
      "content_type": "audio/mp4",
      "bytes": 48720,
      "sha256": "abc...",
      "priority": "required"
    },
    {
      "id": "image_card_456",
      "url": "https://cdn.example.com/images/card_456.webp",
      "content_type": "image/webp",
      "bytes": 92134,
      "sha256": "def...",
      "priority": "required"
    }
  ]
}

This is stronger than “service worker cache some URLs” because it gives the app:

* exact list of assets,
* exact byte budget,
* exact schema version,
* exact integrity hashes,
* required vs optional media,
* expiration policy,
* route/offline policy,
* user/deck/course scope.

⸻

5. Storage strategy for flashcards

Use different stores for different things.

Browser/PWA/offline web island

Cache Storage:
  app shell JS/CSS
  images
  audio files
  video files when feasible
  JSON endpoints if URL-addressable
IndexedDB:
  cards
  decks
  curriculum nodes
  local study sessions
  review event journal
  sync checkpoints
  media metadata
  search indexes / lightweight lookup tables
OPFS:
  larger file-like content if supported and useful

Web.dev recommends Cache Storage for network resources and IndexedDB for structured data; it also recommends OPFS for file-based content and warns against synchronous localStorage for significant storage. (web.dev￼)

Native shell

SQLite:
  cards
  decks
  curriculum nodes
  local sessions
  review events
  mutation queue
  sync checkpoints
  media metadata
Native file cache:
  images
  audio
  video
  thumbnails
  downloaded pack files
Native media download subsystem:
  larger audio/video, background/resumable downloads

This should be the recommended path for serious native mobile because browser storage can be evicted and quotas vary by browser/origin. MDN documents that browser storage is generally best-effort by default, can be evicted under quota/storage pressure, and persistent storage requires navigator.storage.persist() where supported. (developer.mozilla.org￼)

⸻

6. Media: images/audio/video need special care

Flashcard media is not just “some URLs.”

Images

Good options:

PWA/WebView:
  Cache API runtime cache
  content pack prefetch
  WebP/AVIF where supported
Native:
  file cache
  memory/disk image cache
  signed CDN URLs

Audio

For short card audio, web playback from cached assets can work. For serious offline audio, native playback is more reliable.

Short audio clips:
  Cache API or native file cache.
Long audio / playlists / background playback:
  native iOS AVFoundation
  native Android Media3

Video

Video is the first place where a browser-only strategy gets fragile. Service workers can serve cached audio/video and handle Range requests, but partial-response handling is nontrivial; Workbox has a range-request module to help. (web.dev￼)

For native offline video/audio, use native platform tools:

* Android Media3/ExoPlayer supports offline media downloads; Android docs recommend DownloadService for downloads that continue in the background, with DownloadManager, DownloadIndex, network requirements, cache storage, and schedulers such as WorkManager. (developer.android.com￼)
* iOS supports offline HLS through AVFoundation APIs such as AVAssetDownloadURLSession, and Apple’s offline HLS materials focus on downloading HLS content for offline playback. (developer.apple.com￼)

So Keelway should expose media policies:

media_policy :card_audio,
  storage: :required,
  playback: :web_or_native,
  max_bytes_per_asset: 250_000
media_policy :lesson_video,
  storage: :optional,
  playback: :native_preferred,
  background_download: true

⸻

7. Service workers: yes for PWA/offline islands, but not the only mobile layer

For a flashcard app, service workers are useful for the web/PWA version and can help inside WebViews, but they should not be the sole guarantee.

Reason:

* Service workers are widely useful for browser offline experiences; MDN describes them as proxy-like workers that can serve cached assets and data offline. (developer.mozilla.org￼)
* In WebViews, service-worker support is more nuanced. CanIWebView summarizes service workers as widely available in browsers but not consistently in WebViews. (caniwebview.com￼)
* Joe Masilotti’s Hotwire Native offline write-up says iOS blocks service workers in WKWebView by default and requires limitsNavigationsToAppBoundDomains = true; he also notes that enabling app-bound domains blocks requests to domains not explicitly listed. (newsletter.masilotti.com￼)

Therefore:

PWA:
  service worker + Cache API + IndexedDB can be the primary offline runtime.
Native iOS/Android:
  service worker can help, but native SQLite/file cache should be the durable offline substrate.

Keelway should support both.

⸻

8. What the study screen implementation could look like

Route policy

defmodule MyAppWeb.Mobile.RoutePolicy do
  use Keelway.RoutePolicy
  route "/study",
    id: :study,
    presentation: :push,
    online: {:live_view, MyAppWeb.StudyLive},
    offline: {:web_island, MyAppWeb.Offline.StudyIsland},
    content_packs: [MyApp.Mobile.DailyStudyPack],
    sync: [MyApp.Mobile.StudySync],
    cache: :never,
    commands: ["media.prefetch", "haptic.play", "audio.play"]
end

Interpretation:

Online:
  show StudyLive or launch island from StudyLive.
Offline:
  if content pack exists, boot StudyIsland.
  if pack missing, show "Connect once to download today’s cards."
Native:
  can use the same policy but choose a native study screen instead.

LiveView launcher

defmodule MyAppWeb.StudyLive do
  use MyAppWeb, :live_view
  use Keelway.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:pack_status, :checking)
     |> push_native("content_pack.ensure", %{
       pack: "daily_study",
       route: "/study"
     })}
  end
  def handle_native_event("content_pack.ready", %{"pack" => "daily_study"}, socket) do
    {:noreply, assign(socket, :pack_status, :ready)}
  end
  def handle_event("start_study", _params, socket) do
    {:noreply,
     push_native(socket, "offline_island.open", %{
       island: "study",
       pack: "daily_study"
     })}
  end
end

Offline island boot

<div
  id="study-island"
  data-keelway-island="study"
  data-pack="daily_study"
>
  Loading study session…
</div>
import { StudyEngine } from "./study_engine"
import { KeelwayStore } from "./keelway_store"
async function bootStudyIsland() {
  const store = await KeelwayStore.open("daily_study")
  const cards = await store.cards.dueToday()
  const media = await store.media.resolveMap(cards)
  const engine = new StudyEngine({
    cards,
    media,
    schedulerVersion: "2026.05",
    now: () => new Date()
  })
  engine.on("reviewed", async review => {
    await store.reviewEvents.append(review)
    await store.queueMutation("review_event.append", review)
  })
  engine.render(document.getElementById("study-island"))
}

This can run without LiveView because it has cached assets, cached data, and local JS.

⸻

9. Sync API for flashcard review events

Resource declaration

defmodule MyApp.Mobile.StudySync do
  use Keelway.Sync.Resource,
    name: :study,
    repo: MyApp.Repo,
    scope: :current_user
  event_log :review_events,
    schema: MyApp.Study.ReviewEvent,
    idempotency_key: true,
    conflict: :append_only
  materialized_state :card_progress,
    schema: MyApp.Study.CardProgress,
    server_derived: true
  pull [:cards, :decks, :curriculum_nodes, :card_progress]
  push [:review_events, :study_sessions]
end

Push review events

POST /keelway/sync/study/review-events
{
  "client_id": "ios:install_123",
  "pack_version": "2026-05-12:user_123:a1b2c3",
  "events": [
    {
      "id": "rev_01JZ",
      "session_id": "sess_abc",
      "card_id": "card_456",
      "rating": "good",
      "elapsed_ms": 2300,
      "answered_at": "2026-05-12T19:15:00Z",
      "base_card_version": 12,
      "base_progress_version": 8,
      "scheduler_version": "2026.05",
      "idempotency_key": "install_123:sess_abc:card_456:3"
    }
  ]
}

Server response

{
  "accepted": ["rev_01JZ"],
  "duplicates": [],
  "rejected": [],
  "conflicts": [],
  "next_checkpoint": "study_ck_789",
  "updated_progress": [
    {
      "card_id": "card_456",
      "due_at": "2026-05-15T08:00:00Z",
      "state": "learning",
      "version": 9
    }
  ]
}

Conflict examples

{
  "conflicts": [
    {
      "event_id": "rev_02",
      "reason": "card_removed_from_assignment",
      "resolution": "accepted_but_not_scheduled"
    },
    {
      "event_id": "rev_03",
      "reason": "scheduler_version_expired",
      "resolution": "server_recomputed"
    }
  ]
}

This is the right tradeoff: the user’s offline work is not lost, but the server can still enforce canonical business rules.

⸻

10. The local study algorithm problem

A flashcard app needs local scheduling logic: “what is the next card?” and “what happens after I answer?”

There are three options.

Option A: server-only scheduler

Online only.
Every answer asks server for next card.

Bad for your use case. It breaks offline.

Option B: client scheduler with server reconciliation

Client runs scheduler offline.
Server recomputes/validates on sync.

Best v1 choice.

scheduler MyApp.Study.Schedulers.SM2,
  client_bundle: "study_scheduler_2026_05",
  server_recompute: true

The server should treat the client’s scheduling outputs as hints, not authoritative truth.

Option C: shared scheduler core

Same deterministic scheduler compiled/ported across JS, Swift/Kotlin, Elixir.

Best long-term, but more work.

For v1, use Option B. For v2, consider a shared scheduler package or generated test vectors:

{
  "input": {
    "card_state": {"interval": 3, "ease": 2.5},
    "rating": "good",
    "answered_at": "2026-05-12T19:15:00Z"
  },
  "expected": {
    "interval": 5,
    "due_at": "2026-05-17T19:15:00Z"
  }
}

Then Elixir, JS, Swift, and Kotlin all run the same fixture tests.

⸻

11. How this fits LiveView

The study app can still use LiveView heavily.

LiveView-owned

/login
/dashboard
/courses
/decks
/study/setup
/progress
/settings
/billing
/admin

Offline island-owned

/study/session
/study/review
/study/listen-and-repeat
/study/quiz

Shared

/study
  online: LiveView wrapper
  offline: island/native screen

The route policy makes that explicit:

route "/study/session",
  online: {:live_view, MyAppWeb.StudySessionLive},
  offline: {:island, "study.session"},
  fallback: :native_offline_screen,
  requires_pack: :daily_study

When online, you can still decide to use the island because it gives faster UX. The LiveView can become the host/configurator rather than the interaction engine.

⸻

12. “Graceful degradation” should be policy-driven

Keelway should let each route declare what happens offline:

offline :unavailable
offline :read_only_cache
offline :draft_only
offline {:mutation_queue, resource: MyApp.Mobile.TodoSync}
offline {:web_island, island: "study.session", pack: :daily_study}
offline {:native_screen, screen: "study.session", pack: :daily_study}

Example:

route "/billing",
  offline: :unavailable,
  cache: :never
route "/lesson/:id",
  offline: :read_only_cache
route "/support/new",
  offline: :draft_only
route "/todos",
  offline: {:mutation_queue, resource: MyApp.Mobile.TodoSync}
route "/study/session",
  offline: {:web_island, island: "study.session", pack: :daily_study}

This avoids magic and makes the behavior obvious.

⸻

13. Native package additions needed

The native packages should include content-pack and sync subsystems.

iOS

KeelwayKit/
  ContentPacks/
    ContentPackManifest.swift
    ContentPackDownloader.swift
    ContentPackStore.swift
    ContentPackVerifier.swift
    MediaCache.swift
  Sync/
    SyncEngine.swift
    MutationQueue.swift
    ReviewEventJournal.swift
    CheckpointStore.swift
  OfflineScreens/
    OfflineIslandHostViewController.swift
    NativeStudyScreenFactory.swift
  Media/
    AudioClipCache.swift
    VideoDownloadCoordinator.swift

iOS background work should be treated as opportunistic. Apple’s BackgroundTasks framework is for keeping app content up to date and running longer tasks in the background, but the app still needs foreground sync and explicit user-visible download progress. (developer.apple.com￼)

Android

io.sztheory.keelway/
  contentpacks/
    ContentPackManifest.kt
    ContentPackDownloader.kt
    ContentPackStore.kt
    ContentPackVerifier.kt
    MediaCache.kt
  sync/
    SyncEngine.kt
    MutationQueue.kt
    ReviewEventJournal.kt
    CheckpointStore.kt
    SyncWorker.kt
  offline/
    OfflineIslandFragment.kt
    NativeStudyFragment.kt
  media/
    AudioClipCache.kt
    Media3DownloadCoordinator.kt

Android’s offline-first guidance explicitly calls out queues, connectivity monitors, synchronization, conflict resolution, and WorkManager for persistent work that drains queues when connectivity returns. (developer.android.com￼)

⸻

14. Storage budget and eviction are product features

Flashcard content can get big fast.

Keelway should make storage budget visible:

content_pack :daily_study,
  max_bytes: 750 * 1024 * 1024,
  required_bytes_soft_limit: 250 * 1024 * 1024,
  eviction: [
    keep_required_for: {7, :days},
    evict_optional_after: {3, :days},
    strategy: :least_recently_used
  ]

User-facing UI:

Downloaded for offline study
  Spanish A1 daily cards: 128 MB
  Audio: 84 MB
  Images: 32 MB
  Optional video: not downloaded
[Download videos]
[Clear offline content]

This matters because browser and device storage can be constrained or evicted. MDN’s storage quota docs explain that browser-stored data is per-origin, quotas/eviction vary by browser, and best-effort storage may be evicted without user interruption when needed. (developer.mozilla.org￼)

⸻

15. Major footguns this avoids

Footgun: “Study session is LiveView”

What goes wrong:

User goes offline.
Clicks answer.
handle_event/3 cannot run.
Next card cannot be chosen.
Progress not saved.

Prevention:

Study session is offline island/native screen.
Answers are local review events.
Sync happens later.

Footgun: “Service worker is the whole offline strategy”

What goes wrong:

Works in Chrome PWA.
Breaks or behaves differently in iOS/Android WebView.
Media range requests get weird.
Storage evicts unexpectedly.

Prevention:

Use service worker for PWA and enhancement.
Use native SQLite/file cache for native shell.
Use explicit content packs.

Footgun: “Progress row is mutated offline”

What goes wrong:

Two devices study same deck.
Both mutate due_at/ease/interval.
Last write wins silently loses data.

Prevention:

Append-only review events.
Server derives canonical progress.
Duplicate/idempotent event handling.

Footgun: “Media is treated like JSON”

What goes wrong:

Audio/video downloads fail midway.
Cache can’t serve range requests.
User thinks deck is downloaded but audio missing.

Prevention:

Media manifest with required/optional assets.
Download progress.
Integrity checks.
Native media downloaders for serious audio/video.

Footgun: “Offline validation pretends to be server validation”

What goes wrong:

Client accepts an answer/session/action that server later rejects.
User loses trust.

Prevention:

Local validation is UX only.
Server reconciliation is authoritative.
Rejected events are visible and explainable.

⸻

16. Refined Keelway architecture for this use case

The project should now include these first-class concepts:

Keelway.RoutePolicy
  route-level online/offline behavior
Keelway.Offline.ContentPack
  downloadable data/media manifests
Keelway.Offline.Island
  JS/web offline app runtime
Keelway.Sync.Resource
  structured resources
Keelway.Sync.EventLog
  append-only offline event journal
Keelway.Media.Cache
  required/optional media downloads
Keelway.NativeScreen
  optional native offline screens

Package map adjustment:

keelway
  route policy
  bridge
  platform
  cache policy
  connection state
  offline route metadata
keelway_offline
  content packs
  offline islands
  media manifests
  storage budgets
keelway_sync
  mutation queues
  event logs
  reconciliation
keelway_media
  native media download/playback
  optional rindle integration

For v0.1, I would add at least the interfaces for ContentPack and OfflineIsland, even if the implementation is minimal.

⸻

17. MVP stress-test recommendation

For the first prototype, build a tiny flashcard example app:

Online:
  LiveView dashboard
  "Download today’s cards" button
  "Start study" button
Offline:
  JS island loads from cached app shell
  IndexedDB contains 20 cards
  Cache API contains 20 audio/image assets
  User answers 5 cards
  Review events are queued
Reconnect:
  Events POST to Phoenix
  Server deduplicates by idempotency key
  Server recomputes progress
  Client receives updated checkpoint

Minimum prototype APIs:

defmodule MyApp.Mobile.DailyStudyPack do
  use Keelway.Offline.ContentPack,
    name: :daily_study
  resources [:cards, :decks, :card_progress]
  media [:card_audio, :card_images]
end
defmodule MyApp.Mobile.StudySync do
  use Keelway.Sync.EventLog,
    name: :study_reviews,
    event: MyApp.Study.ReviewEvent,
    idempotency_key: true
  reconcile MyApp.Study.Reconciler
end
route "/study/session",
  offline: {:web_island, "study.session"},
  content_pack: :daily_study,
  sync: :study_reviews

That prototype will prove whether the architecture works for the hardest common offline case.

⸻

18. Final answer

Yes: the design should absolutely support “LiveView for most screens, offline islands/native screens for critical offline workflows.”

For your language-learning flashcard example, I would build it like this:

LiveView:
  product shell, auth, dashboard, settings, billing, progress summaries.
Offline island/native screen:
  study session, card queue, audio/images/video, answer capture, local scheduler.
Keelway offline:
  content packs for cards/media/curriculum.
  IndexedDB/Cache API for PWA.
  SQLite/file cache for native.
  append-only review event journal.
  sync/reconcile on reconnect.

The critical architecture sentence is:

Do not degrade an offline-critical LiveView into a broken LiveView. Promote it into an offline-capable island with its own local data and local logic, then sync through Phoenix/Ecto when the network returns.

That is the version of Keelway that supports your flashcard/media use case without falling into the LiveView Native trap or making fake offline promises.