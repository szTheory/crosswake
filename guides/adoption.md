# Crosswake Adoption Guide

This guide shows the shipped flashcard proof first, then turns it into a
route-local recipe for Phoenix SaaS teams.

Crosswake is not asking you to make the whole app local-first. The proof path is
one explicit owner decision: `/offline` is an `:offline_island` route whose local
work is owned by app JavaScript and reconciled by Phoenix/Ecto.

For the setup commands, start with [examples/QUICK_START.md](https://github.com/szTheory/crosswake/blob/main/examples/QUICK_START.md).
For route-owner selection, read [guides/route_policy.md](route_policy.md) and
[guides/web_to_mobile_migration.md](web_to_mobile_migration.md).

## Proof Walkthrough

The checked-in proof is the flashcard study island:

- Route: `/offline`
- Route owner: `:offline_island`
- HTML entry point: `CrosswakeExample.OfflineController`
- Browser island code: `examples/phoenix_host/priv/static/offline_study.js`
- Sync endpoint: `/study/sync`
- API controller: `CrosswakeExample.LocalFirst.SyncController`
- Reconciliation context: `CrosswakeExample.LocalFirst.Study.sync_events/1`
- Ecto schema: `CrosswakeExample.LocalFirst.ReviewEvent`

Run the proof from `examples/phoenix_host`:

```bash
npm ci
npx playwright install chromium
npx playwright test e2e/offline_sync.spec.ts
```

That Playwright test opens `/offline`, drives the real UI, observes IndexedDB,
reconnects the browser, waits for `/study/sync`, checks Ecto state, proves the
accepted local record is removed from the outbox, and verifies duplicate replay
is idempotent.

## Current Data Path

The current implementation path is intentionally small and inspectable:

```text
User rates a card on /offline
  -> offline_study.js handleReview(rating)
  -> queueMutation(...)
  -> IndexedDB mutations store
  -> window online event or foreground route activity
  -> flushOutbox()
  -> POST /study/sync
  -> CrosswakeExample.LocalFirst.SyncController.sync/2
  -> CrosswakeExample.LocalFirst.Study.sync_events/1
  -> CrosswakeExample.LocalFirst.ReviewEvent.changeset/2
  -> Ecto insert_all(... on_conflict: :nothing ...)
  -> accepted_records deleted from the local outbox
```

`queueMutation` stores small semantic events, not UI state snapshots. Each event
contains:

- `client_mutation_id`
- `card_id`
- `rating`

`flushOutbox` reads queued mutations from IndexedDB and posts them to
`/study/sync`. The browser `online` event triggers `flushOutbox`; the route also
tries an eager flush while the user is online. This is reconnect-triggered,
route-local replay, not a background service for the whole app.

On the Phoenix side, `SyncController.sync/2` accepts a batch and delegates to
`Study.sync_events/1`. `ReviewEvent.changeset/2` validates required fields and
rating values. Valid rows are inserted with `insert_all` using
`on_conflict: :nothing` and `conflict_target: :client_mutation_id`, so duplicate
replay does not create duplicate canonical rows.

## Replay Outcomes

Use these outcome words precisely:

- **accepted** - Phoenix/Ecto validated and persisted the event. The browser
  deletes the matching accepted record from the IndexedDB outbox.
- **rejected** - Phoenix/Ecto rejected the event with validation errors. The
  record stays visible/queued locally so the app can show the failure and decide
  what to do next.
- **duplicate-idempotent** - replaying the same `client_mutation_id` is accepted
  by the API shape but inserts no new row because Ecto uses
  `on_conflict: :nothing`.
- **conflict** - canonical Crosswake replay vocabulary for a server-side state
  disagreement that needs attention. The current `/study/sync` demo teaches the
  outcome class, but it does not ship a full conflict-resolution UI.

The browser status copy should stay plain: queued locally, syncing, synced count,
queued count, or sync failed with local records retained.

## Reusable Offline-Island Recipe

Use this pattern only for a route that truly owns local mutation and replay.
Cached read-only routes are covered in [guides/offline.md](offline.md).

### 1. Declare the route owner

Choose `:offline_island` only for the route that owns local work:

```elixir
get("/offline", CrosswakeExample.OfflineController, :index,
  crosswake: [
    id: "offline-study",
    runtime: :offline_island,
    offline: :local_first,
    security: :standard
  ]
)
```

Nearby routes can stay `:live_view` or cached read-only. Crosswake works best
when each route owner is explicit.

### 2. Build the island

Render a small route-owned island that can run without a LiveView socket. The
checked-in proof uses `CrosswakeExample.OfflineController` and a static module
script loaded by `offline_html/index.html.heex`.

Keep the island focused on the user job. For the flashcard proof, the user rates
one card and gets status about local save and replay.

### 3. Persist semantic events

Store small semantic events in local browser storage. In the proof, IndexedDB has
separate stores for `flashcards` and `mutations`.

Prefer durable event fields that Phoenix can validate:

- app-generated mutation id
- stable domain id
- user action or rating
- enough route/session context for reconciliation

Do not store broad UI snapshots and call that sync. Do not make the bounded
bridge own local writes.

### 4. Flush on reconnect or explicit sync

Trigger replay when the route is active and the browser is online. The current
proof uses the `window` `online` event and an eager foreground flush.

If the network request fails, keep queued records in the outbox and show a clear
local status. Do not silently drop the work.

### 5. Reconcile in Phoenix/Ecto

Keep canonical truth on the Phoenix side:

1. Receive batched events at a route-local endpoint such as `/study/sync`.
2. Validate each event with an Ecto changeset.
3. Insert valid events idempotently by client mutation id.
4. Return accepted records and rejected records separately.
5. Leave conflicts explicit instead of silently overwriting server truth.

The browser deletes only accepted records. Rejected or conflict outcomes stay
visible until the app can guide the user.

### 6. Test the whole loop

The useful proof is end-to-end:

- user action queues an IndexedDB event
- reconnect triggers app code
- Phoenix receives `/study/sync`
- Ecto persists one canonical row
- duplicate replay stays idempotent
- accepted outbox records are deleted
- rejected records remain inspectable

Use Playwright or an equivalent browser E2E to prove that flow. Unit tests alone
do not prove route ownership or reconnect behavior.

## Bridge Boundary

The bounded bridge remains a low-frequency request/reply affordance for a
Phoenix-owned route. It can help with a semantic native action such as Share, but
it does not own offline writes, replay, or reconciliation.

If a flow needs continuous client authority, move it toward an offline island or
a native screen. Do not push that authority through bridge messages.

## What This Does Not Prove

- No whole-app local-first claim.
- No whole-app background replay claim.
- No bridge authority over local writes.
- No native/device/provider authority for the offline path.
- No full conflict-resolution UI in the current `/study/sync` demo.
- No screenshots, recordings, artifact manifests, or native evidence promotion in
  this phase.

## Reference Map

- [examples/QUICK_START.md](https://github.com/szTheory/crosswake/blob/main/examples/QUICK_START.md) - runnable commands and proof ladder
- [guides/route_policy.md](route_policy.md) - route-owner decisions
- [guides/web_to_mobile_migration.md](web_to_mobile_migration.md) - existing Phoenix SaaS route inventory
- [guides/offline.md](offline.md) - cached read-only versus offline island
- [guides/bridge.md](bridge.md) - bounded bridge contract and denials
- [guides/support_matrix.md](support_matrix.md) - support-truth labels
