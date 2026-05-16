Yes — the plan can support offline mode and reconciliation, but only if we draw a hard architectural boundary:

LiveView remains the online, server-connected experience. Offline mode is handled by an explicit mobile sync/data layer, not by pretending LiveView WebSocket state can survive offline and replay perfectly.

That distinction is the whole thing. It is how we avoid both the fake offline trap and the LiveView Native coupling trap.

Phoenix LiveView already handles transient disconnects well for web apps: on a dropped connection it reconnects, and the docs say the client gracefully reconnects and calls mount/3 and handle_params/3 again; deployment docs also say LiveView reconnects with exponential backoff. But that is recovery, not offline-first semantics. It does not mean arbitrary LiveView assigns, client-side events, websocket state, in-flight native commands, or business mutations can be safely preserved across long offline periods.  ￼

So the refined answer is:

Keelway v0.1 should support connection loss gracefully. Keelway v0.2/v0.3 should support offline read/write sync for explicitly declared resources. It should never claim “offline LiveView” for arbitrary pages.

⸻

1. The hard truth: LiveView is not the offline engine

LiveView’s superpower is that the server owns state and renders updates to HTML clients. That is also why arbitrary offline LiveView is not a thing.

When the socket is live, LiveView gives you excellent server-side productivity. When the socket drops, LiveView can show disconnected UI and reconnect. It even has phx-connected and phx-disconnected bindings for showing reconnect state, and form recovery for forms with phx-change and an id.  ￼

But those are reconnect affordances, not a general-purpose offline mutation log.

The correct product framing should be:

Mode	Supported?	What it means
Online LiveView	Yes	Normal Phoenix/LiveView over WebSocket.
Spotty connection recovery	Yes	Reconnect banner, disabled risky actions, form recovery, idempotent commands, native connection telemetry.
Cached read-only pages	Yes	Previously visited or prefetched pages can render stale/readonly.
Offline resource reads	Yes, opt-in	Selected resources are stored in local SQLite/IndexedDB/native cache.
Offline writes/mutations	Yes, opt-in	Selected mutations queue locally, replay with idempotency and conflict policy.
Arbitrary offline LiveView	No	Would require reimplementing server logic/client diff behavior locally.
Collaborative offline editing	Later / advanced	Requires CRDT/OT or specialized sync semantics.

That last distinction is important because Brian Cardarella’s complaint is directionally the exact risk we should avoid: LiveView Native tried to make LiveView serve a non-HTML/native rendering target, while LiveView itself remains optimized around the browser/HTML pipeline. The main live_view_native repo is now archived/read-only as of February 10, 2026, which makes it especially risky as a foundation.  ￼

Keelway should not fight LiveView. It should route around the limitation:

* Use LiveView for online HTML UI in the WebView.
* Use public LiveView hooks/push_event only for coarse bridge commands, because those are documented public APIs.  ￼
* Use Phoenix Controllers/Channels/sync endpoints for offline resource sync.
* Use native SQLite + native screens/components for offline-capable flows.
* Use Phoenix/Ecto as the authoritative reconciliation backend.

That aligns with the “build on the abstraction below LiveView” point from the thread you pasted: Phoenix Channels and HTTP endpoints are the better long-lived sync substrate than trying to crack open LiveView internals. Phoenix Channels are explicitly a bidirectional soft-realtime abstraction over clients and PubSub, while LiveView is a higher-level HTML UI framework.  ￼

⸻

2. The refined architecture: two runtimes, one product

Keelway should internally split the app into two cooperating runtimes:

Online runtime
  Phoenix LiveView / Controllers / HEEx
  WebView shell
  Native bridge commands
  Server-owned realtime state
Offline runtime
  Native SQLite / local store
  Sync resource registry
  Mutation queue
  Conflict resolver
  Native offline screens / web fallback screens
  Server reconciliation endpoints

The app should feel like one product to the user, but the architecture should not pretend it is one mechanism.

Google’s Android offline-first guidance is useful here: it says offline-first design starts in the data layer, requires a local data source, and the local data source should be the canonical source read by higher layers while the network source is synchronized into it.  ￼

For Keelway, the equivalent is:

Native screen / WebView offline component
        reads from
Local SQLite / local cache
        syncs with
Phoenix sync endpoints
        reconcile into
Ecto/Postgres source of truth

LiveView is not in the middle of that offline path. LiveView can observe sync status when online, but it should not be the offline source of truth.

⸻

3. What v0.1 should do for spotty connections

v0.1 should not ship full sync. It should ship the primitives that make sync safe later.

v0.1 connection-resilience features

1. Native connection monitor
    * iOS reachability / URLSession reachability checks.
    * Android connectivity monitor.
    * Emits connection.offline, connection.recovered.
2. LiveView disconnected UI
    * Generated <.mobile_connection_banner />.
    * Uses phx-connected / phx-disconnected for web.
    * Native overlay for iOS/Android shell.
    * Debounced so tiny disconnects do not flash.
3. Route cache policy
    * cache: :never
    * cache: {:network_first, ttl: ...}
    * cache: {:stale_while_revalidate, ttl: ...}
    * cache: {:cache_first, ttl: ...}
4. Read-only cached pages
    * Home, settings, help, invoices index, docs, etc.
    * Always labeled as stale/readonly when offline.
    * Sensitive pages never cached.
5. Native command idempotency
    * Bridge commands include correlation_id, idempotency_key, requires_ack, timeout_ms.
    * If a native command is side-effecting, the server must know whether it completed.
6. Telemetry
    * Offline duration.
    * Reconnect count.
    * Command retry count.
    * Cache hits/misses.
    * Stale page views.
7. Testing
    * Playwright network offline.
    * Maestro airplane-mode smoke test.
    * ExUnit tests for route cache policy.
    * Native tests for command retry/ack behavior.

This is enough to make a Phoenix app feel much more robust on spotty mobile connections without overclaiming.

⸻

4. What v0.2/v0.3 should do: explicit sync resources

Full offline support should come through keelway_sync.

The API shape from the earlier plan is still right, but I would sharpen it:

defmodule MyApp.Mobile.TodoSync do
  use Keelway.Sync.Resource,
    name: :todos,
    schema: MyApp.Todos.Todo,
    repo: MyApp.Repo,
    scope: :current_user
  fields [:id, :title, :completed, :position, :updated_at, :lock_version]
  tombstone field: :deleted_at
  version field: :lock_version
  read_policy :push_pull,
    preload: true,
    ttl: {7, :days}
  mutations [:create, :update, :delete],
    idempotency_key: true,
    conflict: MyApp.Mobile.TodoConflictResolver
end

This explicitly says: “Todos are offline-capable.” It does not say: “Every LiveView is offline-capable.”

Server sync endpoints

Keelway should generate endpoints like:

GET /keelway/sync/todos?checkpoint=ck_123

Response:

{
  "resource": "todos",
  "schema_version": 3,
  "checkpoint": "ck_124",
  "server_time": "2026-05-12T18:00:00Z",
  "rows": [
    {
      "id": "todo_1",
      "version": 7,
      "updated_at": "2026-05-12T17:55:00Z",
      "data": {
        "title": "Call customer",
        "completed": false,
        "position": 100
      }
    }
  ],
  "tombstones": [
    {
      "id": "todo_2",
      "version": 4,
      "deleted_at": "2026-05-12T17:00:00Z"
    }
  ]
}

Mutation push:

POST /keelway/sync/todos/mutations
{
  "client_id": "ios:device-installation-uuid",
  "client_seq": 42,
  "base_checkpoint": "ck_123",
  "mutations": [
    {
      "client_mutation_id": "m_001",
      "idempotency_key": "todo_1-complete-v7-device123",
      "op": "update",
      "id": "todo_1",
      "base_version": 7,
      "patch": {
        "completed": true
      },
      "created_at": "2026-05-12T17:58:00Z"
    }
  ]
}

Response:

{
  "accepted": [
    {
      "client_mutation_id": "m_001",
      "server_version": 8,
      "status": "committed"
    }
  ],
  "conflicts": [],
  "checkpoint": "ck_125"
}

Conflict response:

{
  "accepted": [],
  "conflicts": [
    {
      "client_mutation_id": "m_002",
      "resource": "todos",
      "id": "todo_1",
      "reason": "stale_base_version",
      "client_base_version": 7,
      "server_version": 9,
      "server_data": {
        "title": "Call enterprise customer",
        "completed": false
      },
      "client_patch": {
        "title": "Call customer"
      },
      "resolution": "manual"
    }
  ],
  "checkpoint": "ck_126"
}

This is the right shape because Android’s offline-first guidance explicitly distinguishes queued writes, lazy writes, sync on restored connectivity, versioning, and conflict resolution; it also notes that writes require more care than reads because conflicts can occur.  ￼

⸻

5. Client-side sync internals

Native local store

Use SQLite on both platforms.

CREATE TABLE keelway_resource_rows (
  resource TEXT NOT NULL,
  id TEXT NOT NULL,
  scope_hash TEXT NOT NULL,
  version INTEGER,
  payload_json TEXT NOT NULL,
  updated_at TEXT,
  deleted_at TEXT,
  dirty INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (resource, id, scope_hash)
);
CREATE TABLE keelway_mutation_queue (
  id TEXT PRIMARY KEY,
  resource TEXT NOT NULL,
  operation TEXT NOT NULL,
  row_id TEXT,
  base_version INTEGER,
  payload_json TEXT NOT NULL,
  idempotency_key TEXT NOT NULL,
  client_seq INTEGER NOT NULL,
  status TEXT NOT NULL,
  attempts INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  last_attempt_at TEXT,
  last_error_json TEXT
);
CREATE TABLE keelway_sync_checkpoints (
  resource TEXT NOT NULL,
  scope_hash TEXT NOT NULL,
  checkpoint TEXT,
  updated_at TEXT,
  PRIMARY KEY (resource, scope_hash)
);
CREATE TABLE keelway_conflicts (
  id TEXT PRIMARY KEY,
  resource TEXT NOT NULL,
  row_id TEXT NOT NULL,
  server_payload_json TEXT NOT NULL,
  client_payload_json TEXT NOT NULL,
  resolver TEXT NOT NULL,
  created_at TEXT NOT NULL
);

Android

Use:

* Room for SQLite mapping.
* Kotlin Flow for observable local reads.
* WorkManager for durable background queue draining.

That matches Android’s own offline-first guidance: local data source first, local reads exposed as observable types, write queues, connectivity monitors, and WorkManager for persistent work that waits for network and retries with exponential backoff.  ￼

iOS

Use:

* SQLite directly, GRDB, or Core Data depending on how heavy the native package should be.
* URLSession for network requests.
* BackgroundTasks for opportunistic sync.
* Background URLSession for large media/file transfers.

Apple’s BackgroundTasks framework is for keeping app content up to date and running tasks in the background; URLSession supports background downloads while the app is suspended. But iOS background work is opportunistic, not guaranteed, so Keelway should sync aggressively when the app is foregrounded and treat background sync as a bonus.  ￼

⸻

6. Reconciliation strategy

Keelway should offer four conflict modes, not one.

1. Server wins

Good for:

* billing state
* permissions
* account status
* roles
* entitlements
* audit-sensitive data

conflict :server_wins

The client discards local mutation and shows: “This changed on the server.”

2. Client wins

Good for:

* drafts
* local preferences
* non-critical notes

conflict :client_wins

Still must be server-authorized.

3. Merge patch

Good for:

* independent fields
* simple to-do updates
* profile preferences

conflict MyApp.Mobile.ProfileMergeResolver
defmodule MyApp.Mobile.ProfileMergeResolver do
  @behaviour Keelway.Sync.ConflictResolver
  def resolve(%Keelway.Sync.Conflict{} = conflict) do
    if disjoint_fields?(conflict.server_patch, conflict.client_patch) do
      {:merge, Map.merge(conflict.server_data, conflict.client_patch)}
    else
      {:manual, view: MyAppWeb.Mobile.ProfileConflictLive}
    end
  end
end

4. Manual conflict

Good for:

* invoices
* collaborative edits
* business-critical workflows
* anything where silent merge would break trust

conflict :manual,
  screen: "sync.conflict.review"

Manual conflict UI should be a native screen or a cached web screen that can show:

* server version
* local version
* changed fields
* keep mine
* use server
* edit merged version

Why not default to last-write-wins?

Last-write-wins is simple and common; Android’s docs list it as a common mobile conflict strategy, and Firestore also says multiple offline changes to a document are resolved as last write wins.  ￼

But for SaaS apps it can be dangerous. Last-write-wins is acceptable for low-value preferences and simple todos. It is not acceptable for billing, permissions, inventory, financial actions, medical records, or collaborative documents.

So Keelway should allow :last_write_wins, but make it opt-in and noisy:

conflict :last_write_wins,
  allow_data_loss?: true

That name is intentionally scary.

⸻

7. Sync trigger model

Keelway should sync on multiple triggers:

App launched
App foregrounded
Network recovered
User opens sync-enabled route
Server sends push/poke notification
Manual retry
Periodic background opportunity

The Replicache model is a useful inspiration: it separates local mutators, subscriptions, push endpoint, pull endpoint, and server “poke” notifications. Its docs say mutators encapsulate local changes and conflict behavior, and remote mutations are periodically sent to a push endpoint.  ￼

Keelway’s Phoenix equivalent:

local mutation
  -> SQLite mutation queue
  -> optimistic local state
  -> push mutations endpoint
  -> Ecto.Multi transaction
  -> txid/checkpoint
  -> pull changes endpoint
  -> rebase local state
  -> clear committed mutation

A server “poke” can be:

* Phoenix Channel message,
* APNs/FCM silent-ish push where appropriate,
* polling fallback,
* LiveView event when online.

But again, the sync does not depend on LiveView.

⸻

8. Phoenix/Ecto server internals

A sync mutation should apply inside Ecto.Multi.

defmodule Keelway.Sync.MutationApplier do
  def apply(resource, mutation, actor) do
    Ecto.Multi.new()
    |> Keelway.Sync.Idempotency.ensure_new(mutation.idempotency_key)
    |> resource.load_current(mutation.id)
    |> resource.authorize(actor, mutation)
    |> resource.detect_conflict(mutation)
    |> resource.apply_mutation(mutation)
    |> resource.write_audit(actor, mutation)
    |> resource.write_checkpoint()
  end
end

Use Ecto.Multi because sync writes are exactly the kind of thing that need atomicity:

* idempotency record
* resource update
* tombstone
* audit event
* outbox notification
* checkpoint update

Phoenix.Sync is also worth tracking closely. It already adds real-time sync to Postgres-backed Phoenix apps, integrates with Plug/Phoenix Controller/LiveView/Router/Stream, uses ElectricSQL for core sync delivery, and maps Ecto.Query to Electric “Shapes.” It now also exposes Phoenix.Sync.Writer for write-path sync with Ecto transactions.  ￼

My recommendation:

* v0.1: no dependency on Phoenix.Sync.
* v0.2/v0.3: support a Keelway.Sync.Adapter.PhoenixSync experimental adapter.
* v1.0: decide whether Phoenix.Sync/Electric becomes the preferred read-path engine, or whether Keelway’s simple resource sync stays the default.

Why not immediately depend on Phoenix.Sync? Because Electric historically focused on read-path sync and did not prescribe write-path sync, although Phoenix.Sync.Writer now exists. Keelway’s mobile product needs a very opinionated queue/conflict/UX story, not just replication mechanics.  ￼

⸻

9. How offline screens relate to LiveView screens

There are three viable patterns.

Pattern A: cached LiveView HTML, read-only

Use when:

* page is useful stale
* no complex local interaction
* “last viewed” data is acceptable

Example:

route "/invoices/:id",
  cache: {:stale_while_revalidate, ttl: {7, :days}},
  offline: :read_only

User sees:

Invoice #123
Last updated 2 days ago
[Offline: read-only]

Pattern B: native offline screen backed by SQLite

Use when:

* user must continue working offline
* local writes matter
* UI should be fast and reliable

Example:

route "/todos",
  presentation: {:native_screen, "todos.index"},
  sync_resource: MyApp.Mobile.TodoSync,
  offline: :read_write

Native screen reads SQLite and writes mutations into queue.

Pattern C: WebView offline component backed by local JS store

Use when:

* you want a web-ish offline UI
* browser/PWA is also important
* native screens are too heavy

This could use IndexedDB on web and bridge to native SQLite in mobile, but it is trickier and risks reinventing a frontend app. Use sparingly.

My recommendation:

* v0.1: Pattern A only.
* v0.2/v0.3: Pattern B for serious offline.
* Pattern C only for carefully constrained components.

⸻

10. Service workers: useful, but not the source of truth

Service workers can intercept network requests, cache resources, and create offline experiences. MDN describes them as proxy-like workers between web apps and the network, with granular cache control; MDN also documents cache-first, network-first, and stale-while-revalidate strategies.  ￼

But Keelway should not rely solely on service workers for mobile offline because WebViews are inconsistent and constrained. CanIWebView currently summarizes service workers as widely available in browsers but not reliably available in WebViews, and shows unsupported API details for WKWebView.  ￼

So:

Browser/PWA:
  service worker is useful.
Native WebView:
  native cache + SQLite should be the reliable offline layer.
  service worker is optional enhancement.

That matches Hotwire’s own ecosystem lesson: Joe Masilotti wrote that his answer to “does Hotwire Native support offline mode” had been “NO,” while newer work explores cached-on-visit via service workers and caching rules.  ￼

Keelway should be more explicit from day one.

⸻

11. Avoiding the LiveView Native footguns

The LVN problem we need to avoid is not “using LiveView at all.” The problem is depending on LiveView internals or forcing LiveView to be a native renderer.

Footgun 1: building on private LiveView renderer internals

Bad:

LiveView diff protocol
  -> custom native renderer
  -> depends on LiveView internals
  -> breaks on LiveView minor changes

Keelway should instead use:

LiveView public HTML output
LiveView public JS hooks
LiveView public push_event/pushEvent
Phoenix public Channels/Controllers

The official JS interop docs support hooks pushing events to the LiveView and LiveView pushing events back to hooks, which is enough for coarse bridge events; Keelway should not monkey-patch LiveView’s JS client or depend on hidden closure internals.  ￼

Footgun 2: “one language, all platforms” overreach

Bad:

Elixir LiveView renders web, iOS, Android, offline, audio, billing, camera, everything.

Good:

Elixir/Phoenix owns business logic, auth, billing truth, sync truth.
Native owns native UX, local cache, SQLite, permissions, audio, camera, app-store billing surface.
The bridge is typed and narrow.

Footgun 3: arbitrary offline LiveView

Bad:

When disconnected, keep accepting LiveView clicks and replay them later.

This can corrupt data. There are real-world reports of stale LiveView reconnect/form state causing bad writes after reconnect. LiveView form recovery is useful, but it intentionally replays form change events after reconnect, which is not the same as validating offline business mutations.  ￼

Good:

When disconnected:
  - disable online-only LiveView actions
  - allow explicitly offline-capable actions
  - write those actions into a typed mutation queue
  - reconcile through server sync endpoint

Footgun 4: no backpressure on reconnect

If many clients reconnect after deploy or network recovery, they can all re-run mount/3 and hit DB-heavy paths. A recent reconnect analysis calls out this “thundering herd” problem when many LiveViews reconnect simultaneously and rebuild state.  ￼

Keelway mitigation:

* jittered reconnect telemetry,
* native cache to avoid blank screens,
* sync endpoints with backoff,
* rate-limited manifest refresh,
* route-level preload control,
* mount/3 guidance: avoid expensive repeated work; use URL/session/cache thoughtfully.

⸻

12. The sync API should be boring and explicit

Resource declaration

defmodule MyApp.Mobile.NoteSync do
  use Keelway.Sync.Resource,
    name: :notes,
    schema: MyApp.Notes.Note,
    repo: MyApp.Repo,
    scope: :current_user
  fields [:id, :title, :body, :updated_at, :lock_version]
  version field: :lock_version
  tombstone field: :deleted_at
  read_policy :pull,
    ttl: {30, :days},
    preload: false
  mutations [:create, :update, :delete],
    idempotency_key: true,
    conflict: :manual
end

Generated controller

defmodule MyAppWeb.Mobile.NoteSyncController do
  use MyAppWeb, :controller
  use Keelway.Sync.Controller,
    resource: MyApp.Mobile.NoteSync
end

Router

scope "/keelway/sync", MyAppWeb.Mobile do
  pipe_through [:browser, :mobile, :require_authenticated_user]
  keelway_sync "/notes", NoteSyncController
end

Mutation resolver

defmodule MyApp.Mobile.NoteConflictResolver do
  @behaviour Keelway.Sync.ConflictResolver
  @impl true
  def resolve(%Keelway.Sync.Conflict{} = conflict) do
    cond do
      only_title_changed?(conflict) ->
        {:merge, merge_title(conflict)}
      only_body_changed_on_one_side?(conflict) ->
        {:merge, merge_body(conflict)}
      true ->
        {:manual, native_screen: "notes.conflict"}
    end
  end
end

⸻

13. Native UX states for offline/sync

Offline must be visible but not annoying.

Required states

Online
Connecting
Offline
Offline + cached page
Offline + no cached page
Offline + queued changes
Syncing
Synced
Conflict
Auth expired
Server rejected mutation

UI examples

Cached read-only page

You’re offline
Showing invoice from May 10, 2026.
Actions are disabled until connection returns.

Offline write queue

3 changes queued
They’ll sync automatically when you’re back online.
[Review changes]

Conflict

This note changed elsewhere while you were offline.
[Use server version]
[Keep my version]
[Review changes]

Recovered

Back online
Synced 3 changes.

This is a product feature, not just infrastructure.

⸻

14. Testing offline properly

Keelway should have an explicit “offline confidence suite.”

ExUnit

test "duplicate idempotency key does not apply mutation twice"
test "stale base_version returns conflict"
test "server_wins conflict discards local patch"
test "manual conflict produces conflict record"
test "sync endpoint only returns resources in user scope"
test "tombstone is returned after delete"
test "billing route is never cacheable"

Native unit tests

func testMutationQueuePersistsAcrossRestart()
func testSyncDoesNotDrainWithoutNetwork()
func testConflictIsStoredLocally()
func testCachedSensitiveRouteIsRejected()
@Test fun mutationQueueDrainsSequentially()
@Test fun workManagerWaitsForConnectedNetwork()
@Test fun staleServerVersionCreatesConflict()
@Test fun localStoreIsReadBeforeNetwork()

E2E

1. Open todo list online.
2. Go offline.
3. Create todo.
4. Kill app.
5. Relaunch offline.
6. See todo still present, marked queued.
7. Restore network.
8. Mutation syncs.
9. Server shows committed todo.
10. Queue clears.

Failure-mode tests

Network drops mid-flush.
Same mutation sent twice.
Server returns 401.
Server returns 409 conflict.
Server schema version changed.
App version lacks resolver for resource schema.
Background sync starts but app is killed.

⸻

15. Sync package decision points

Decision A: build simple sync vs depend on Phoenix.Sync/Electric

Build simple Keelway sync first

Pros:

* Easier to reason about.
* Ecto-native.
* Matches szTheory host-owned philosophy.
* Can be small and explicit.
* Better for mobile UX and conflict screens.

Cons:

* You own replication mechanics.
* Harder to scale to complex relational graphs.
* Could duplicate Phoenix.Sync/Electric work.

Use Phoenix.Sync/Electric

Pros:

* Already focused on Postgres-backed Phoenix sync.
* Supports partial replication via Ecto queries/shapes.
* Integrates with Plug/Phoenix/LiveView/Router.
* Writer support exists for batched client writes.  ￼

Cons:

* Adds infrastructure/dependency complexity.
* Still need mobile SQLite/offline UX/conflict surface.
* Electric’s own docs historically emphasize read-path sync and not prescribing write-path behavior, so the full product semantics remain yours.  ￼

Recommendation:

v0.2:
  Keelway simple sync.
v0.3:
  Phoenix.Sync adapter experiment.
v1.0:
  Choose whether Phoenix.Sync is preferred for heavy read-path sync.

Decision B: use CRDTs?

Use CRDTs only for true collaborative offline editing.

Good for:

* shared documents
* whiteboards
* comments
* realtime collaborative text
* distributed counters/sets

Bad for:

* billing
* entitlements
* permissions
* most SaaS CRUD
* simple to-do lists

Recommendation:

collaboration :none # default
# Later:
collaboration {:crdt, adapter: Keelway.Sync.CRDT.Yjs}

Do not put CRDTs in the mainline v0.1/v0.2 path.

Decision C: should native screens be required for offline writes?

For serious offline writes, yes, or at least strongly recommended.

A WebView LiveView page can display stale HTML, but once the socket is gone it cannot safely run server-side logic. A native screen backed by SQLite can continue to work honestly. You can still make the screen feel Phoenix-owned by generating it from a manifest/schema and keeping all authoritative validation on the server.

⸻

16. Updated roadmap for offline

v0.1: connection-resilient shell

* Online LiveView shell.
* Native offline banner.
* phx-connected / phx-disconnected helper components.
* Cached read-only pages.
* Cache policy DSL.
* Sensitive route guardrails.
* Bridge command idempotency/acks.
* Telemetry.
* Tests for disconnect/reconnect.
* No offline mutations.

v0.2: offline mutation queue alpha

* keelway_sync.
* SQLite local store.
* Resource DSL.
* Pull endpoint.
* Push mutation endpoint.
* Idempotency.
* Basic conflict detection.
* Manual conflict record.
* Todo example app.
* Android WorkManager.
* iOS foreground sync + background task hooks.

v0.3: reconciliation UX

* Native conflict screens.
* Merge resolver behaviours.
* Sync status UI components.
* Phoenix.Sync/Electric adapter experiment.
* Push/poke sync triggers.
* Schema migration/versioning.
* Multi-resource sync.

v1.0: production offline bar

* Stable sync protocol.
* Stable resource DSL.
* Proven on two production apps.
* Cross-platform fixture suite.
* Clear “offline capability matrix.”
* Security review.
* Migration strategy for local schemas.
* Documented app-store-safe background behavior.

⸻

17. Final answer

Yes, Keelway should support offline mode and reconciliation — but not by making LiveView itself offline.

The defensible architecture is:

LiveView = online server-rendered UI
Keelway core = native shell, route policy, bridge, cache, telemetry
Keelway sync = explicit offline resources, SQLite, mutation queue, reconciliation
Phoenix/Ecto = authoritative server state
Native = local offline UX and queue draining

This avoids the LiveView Native pitfall because Keelway does not depend on LiveView internals, does not try to render native UI from LiveView diffs, and does not ask LiveView to become something it is not. It uses LiveView where it is excellent, and uses Phoenix/Ecto/Channels/controllers/native storage where offline requires real data-layer architecture.

The key product promise should be:

“Keelway makes Phoenix apps mobile-resilient by default and offline-capable by explicit resource declaration.”

Not:

“Every LiveView works offline.”

That one sentence keeps the library honest and prevents the biggest architectural trap.