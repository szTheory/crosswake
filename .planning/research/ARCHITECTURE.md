# Architecture Research

**Domain:** CI Honesty / Real-E2E Sweep — reconnect-driven outbox flush integration for the Crosswake offline study island demo
**Researched:** 2026-06-17
**Confidence:** HIGH (grounded in direct inspection of every relevant file in the repo)

---

## System Overview

The current state of the offline study island has a structural gap: mutations are written to IndexedDB correctly, but nothing drains them on reconnect. The E2E test works around this by injecting mutations directly into a window-global and manually firing a `fetch` — the actual demo app code is untested.

```
CURRENT (dishonest):

  [User reviews card]
       │
       ▼
  offline_study.js
  queueMutation() → IndexedDB STORE_MUTATIONS
       │
       │  ← nothing happens here on reconnect
       │
  [Test injects window['crosswake_offline_mutations'] via page.evaluate]
  [Test manually fires fetch('/study/sync') via page.evaluate]
       │
       ▼
  SyncController → Study.sync_events → ReviewEvent upsert (on_conflict: :nothing)

---

TARGET (honest):

  [User reviews card]
       │
       ▼
  offline_study.js
  queueMutation() → IndexedDB STORE_MUTATIONS  (EXISTING, unchanged)
       │
  [browser goes offline → no pending flush]
       │
  [window 'online' event fires when connectivity returns]  ← NEW
       │
       ▼
  flushOutbox()  ← NEW function in offline_study.js
  reads all rows from STORE_MUTATIONS
  → POST /study/sync { events: [...] }  (with per-mutation client_mutation_id keys)
  → on success: clears flushed rows from STORE_MUTATIONS
  → on failure: leaves rows in store, retries on next reconnect
       │
       ▼
  SyncController → Study.sync_events → ReviewEvent upsert (EXISTING, unchanged)

  [E2E test]
  context.setOffline(true)
  → user interacts with real UI (btn-flip / btn-pass / btn-fail)  ← NEW
  → real queueMutation() writes to IndexedDB
  context.setOffline(false)
  → real 'online' event fires in the browser
  → real flushOutbox() POSTs to /study/sync
  → assert Ecto state via /_e2e/sync-state/:client_mutation_id  (EXISTING)
```

---

## Component Responsibilities

| Component | Status | Responsibility | Communicates With |
|-----------|--------|---------------|-------------------|
| `offline_study.js` — `queueMutation()` | EXISTING — keep as-is | Appends a mutation (type, payload, timestamp) to IndexedDB `STORE_MUTATIONS` | IndexedDB |
| `offline_study.js` — `flushOutbox()` | NEW | Reads all pending mutations from `STORE_MUTATIONS`, POSTs to `/study/sync`, clears flushed rows on success | IndexedDB, `SyncController` |
| `offline_study.js` — reconnect listener | NEW | Registers `window.addEventListener('online', flushOutbox)` at init time; fires automatically when browser regains connectivity | `flushOutbox()` |
| `offline_study.js` — `handleReview()` | EXISTING — MODIFIED | After queuing mutation, call `flushOutbox()` optimistically if `navigator.onLine` is true at review time | `queueMutation()`, `flushOutbox()` |
| `StudySessionLive` — `sync_outbox` handler | EXISTING — MODIFIED | Remove the mock comment; remove the LiveView-side outbox simulation; keep or retire the button (see below) | `Study.sync_events/1` |
| `SyncController.sync/2` | EXISTING — unchanged | Accepts `{"events": [...]}` POST, delegates to `Study.sync_events/1` | `Study` context |
| `Study.sync_events/1` | EXISTING — unchanged | `insert_all` with `on_conflict: :nothing, conflict_target: :client_mutation_id` — idempotency is already correct | `ReviewEvent` schema, `Repo` |
| `ReviewEvent` schema | EXISTING — unchanged | `client_mutation_id` unique constraint provides the idempotency key | Postgres |
| `offline_sync.spec.ts` | EXISTING — MODIFIED (replace) | Replace manual `page.evaluate` injection with real UI interaction + real reconnect flow | Playwright browser context |
| `/_e2e/sync-state/:id` endpoint | EXISTING — unchanged | Verification probe for E2E assertions | `ReviewEvent`, `Repo` |

---

## Integration Points

### Where Reconnect Detection Lives

The reconnect trigger belongs exclusively in `offline_study.js`, not in `StudySessionLive`. Reasons:

1. The offline island page (`/offline`) is a standalone HTML page served by `OfflineController` with `put_root_layout(false)`. It loads `offline_study.js` as a plain `<script type="module">`. There is no LiveView socket on this page — `StudySessionLive` lives at `/study/session`, a separate route.

2. `StudySessionLive` is a LiveView that already has its own server-connection lifecycle. Its `sync_outbox` handler was always a simulation seam, not a real client signal. The honest fix is in the client that owns the outbox.

3. The `Crosswake.Offline` contract (`guides/offline.md`) is explicit: "No Background Sync — sync only occurs while the app is active and the user is on the relevant route." A `window` `online` event on the active `/offline` page is exactly the right scope — it fires only when the island page is open and the browser regains connectivity.

4. `navigator.online` / `window 'online'` events are the standard Web API for this. They are reliable enough for a demo proof; the guide already documents that true background sync is out of scope.

**Do NOT use:**
- `visibilitychange` — fires on tab-switch, not on network reconnect; wrong semantic
- LiveView reconnect lifecycle — this is the wrong page; the offline island has no LiveView socket
- Service Worker — out of scope per the existing boundary rules; adds substantial complexity

### The Idempotency Key Contract

`Study.sync_events/1` already has the right server-side contract: `on_conflict: :nothing` on `client_mutation_id`. The mutation shape already written by `queueMutation()` in `offline_study.js` is:

```javascript
{
  type: 'REVIEW_CARD',
  payload: {
    cardId: card.id,
    result: result,   // 'pass' or 'fail'
    timestamp: new Date().toISOString()
  }
}
```

The `SyncController` and `ReviewEvent` changeset expect:

```json
{
  "client_mutation_id": "<uuid>",
  "card_id": <integer>,
  "rating": "good" | "hard"
}
```

There is a field-name mismatch: `offline_study.js` uses `result` with values `'pass'/'fail'`; the changeset validates `rating` with values `"good"/"hard"`. The `client_mutation_id` is not currently set on the mutation in `queueMutation()` — it is generated only inside `StudySessionLive` for its simulation path.

**Required reconciliation (NEW in `offline_study.js`):**
- Add a `crypto.randomUUID()` call when constructing the mutation in `handleReview()` to generate a stable `client_mutation_id`
- Map `result` → `rating` and `'pass'` → `'good'`, `'fail'` → `'hard'` either at queue time or at flush time
- Map `card.id` (string from IndexedDB seed) → integer `card_id` for the POST payload

**Recommended approach:** normalize at queue time so `STORE_MUTATIONS` holds the canonical server shape. This means `queueMutation()` stores `{ client_mutation_id, card_id, rating }` directly — matching what `flushOutbox()` POSTs verbatim.

### The `StudySessionLive` Mock Comment

The `sync_outbox` handler in `study_session_live.ex` (line 29-47) comments "Usually this would be pushed by the client offline capability, but here we mock it." This comment is the explicit proof of dishonesty. The fix is surgical:

- **Option A (minimal):** Remove the comment; leave the button and handler as a secondary "manual sync" affordance that remains functional. This is honest — the button still works, it is just no longer the only path.
- **Option B (cleaner):** Remove the button from the LiveView render, remove the `sync_outbox` handler entirely, and add a code comment explaining that sync is driven by `offline_study.js` on the `online` event. The LiveView at `/study/session` shows outbox status from its own server-side state but does not drive the flush.

Option B is the honest posture aligned with the project's "explicit" principle. The LiveView was simulating something the JS island should do; removing the simulation makes the boundary clear.

---

## Data Flow

### Reconnect-Driven Flush Flow (Target)

```
1. User navigates to /offline (OfflineController renders island page)
       │
2. offline_study.js DOMContentLoaded:
       ├── initDB() opens IndexedDB crosswake_offline_study
       ├── seeds dummy cards if empty
       └── window.addEventListener('online', flushOutbox)   ← NEW

3. User reviews cards while online or offline:
       ├── btn-flip → btn-pass/btn-fail → handleReview('pass'|'fail')
       ├── constructs mutation: { client_mutation_id: crypto.randomUUID(), card_id, rating }  ← MODIFIED
       └── queueMutation(mutation) → IndexedDB STORE_MUTATIONS

4. If navigator.onLine at review time:
       └── flushOutbox() called immediately (optimistic flush)  ← NEW

5. If browser is offline at review time:
       └── mutation sits in IndexedDB

6. Browser regains connectivity → window 'online' event fires:
       └── flushOutbox()  ← NEW

7. flushOutbox():
       ├── reads all rows from STORE_MUTATIONS
       ├── if empty: returns immediately
       ├── POST /study/sync { events: [{ client_mutation_id, card_id, rating }, ...] }
       │       headers: { 'Content-Type': 'application/json' }
       ├── on 2xx response:
       │       └── delete flushed rows from STORE_MUTATIONS by id
       │           (use autoIncrement IDs captured before the POST)
       └── on error/non-2xx:
               └── leave rows in store; next 'online' event will retry

8. SyncController.sync/2 (EXISTING — unchanged):
       └── Study.sync_events(events)
               └── Repo insert_all ReviewEvent, on_conflict: :nothing, conflict_target: :client_mutation_id
```

### E2E Test Flow (Target — replacing the mock)

```
1. page.goto('/offline')
2. waitFor h1 "Offline Study Island"

3. context.setOffline(true)

4. page.click('#btn-flip')
   page.click('#btn-pass')  ← real UI interaction, real queueMutation() call
   (mutation written to IndexedDB with real client_mutation_id)

5. Capture the client_mutation_id written to IndexedDB:
       page.evaluate(() => {
         return new Promise(resolve => {
           const req = indexedDB.open('crosswake_offline_study', 1);
           req.onsuccess = e => {
             const db = e.target.result;
             const tx = db.transaction('mutations', 'readonly');
             tx.objectStore('mutations').getAll().onsuccess = ev => resolve(ev.target.result);
           };
         });
       })

6. page.waitForRequest('/study/sync')  ← set up before going online

7. context.setOffline(false)
   → browser fires 'online' event automatically
   → real flushOutbox() fires
   → real POST to /study/sync

8. await syncRequest; verify payload matches IndexedDB mutation

9. expect.poll(() => page.request.get('/_e2e/sync-state/<id>'))
       .toEqual({ synced: true })
```

---

## New vs Modified Files

### NEW (does not exist yet)

None — no new files needed. All logic lives in existing files.

### MODIFIED

**`examples/phoenix_host/priv/static/offline_study.js`** — the primary change surface

Changes:
1. In `handleReview()`: generate `client_mutation_id` via `crypto.randomUUID()`; normalize `result` ('pass'/'fail') to `rating` ('good'/'hard'); normalize `card.id` to integer `card_id`; store `{ client_mutation_id, card_id, rating }` directly
2. Add `flushOutbox()` function: reads STORE_MUTATIONS, POSTs to `/study/sync`, deletes flushed rows on success, leaves rows on failure
3. In `setupEventListeners()` (or DOMContentLoaded): register `window.addEventListener('online', flushOutbox)`
4. In `handleReview()` after `queueMutation()`: call `flushOutbox()` if `navigator.onLine` is true (optimistic path)
5. Update `updateStatus()` calls in `flushOutbox()` to show "Syncing..." / "Synced N events" / "Sync failed, will retry on reconnect" — honest microcopy

**`examples/phoenix_host/lib/crosswake_example/local_first/study_session_live.ex`** — surgical cleanup only

Changes:
1. Remove the mock comment on line 31 ("Usually this would be pushed by the client offline capability, but here we mock it")
2. Either: remove the `sync_outbox` handler and button entirely (Option B — recommended), or: reword the button label to "Manual Sync" and remove the mock framing from the comment (Option A)
3. If keeping the handler: the underlying `Study.sync_events/1` call is correct and idempotent; it can stay as a manual escape hatch

**`examples/phoenix_host/e2e/offline_sync.spec.ts`** — replace the mock flow

Changes:
1. Remove `page.evaluate` that injects `window['crosswake_offline_mutations']`
2. Remove `page.evaluate` that manually calls `fetch('/study/sync')`
3. Replace with real UI interaction: `page.click('#btn-flip')`, `page.click('#btn-pass')`
4. Extract the `client_mutation_id` from IndexedDB via `page.evaluate` (read-only probe)
5. Use `page.waitForRequest('/study/sync')` before `context.setOffline(false)` to capture the real outgoing request
6. Keep the `expect.poll` against `/_e2e/sync-state/:id` — this is the correct Ecto assertion

### UNCHANGED

- `SyncController` — already correct; accepts `{"events": [...]}`, delegates to `Study.sync_events/1`
- `Study.sync_events/1` — already correct; idempotent via `on_conflict: :nothing, conflict_target: :client_mutation_id`
- `ReviewEvent` schema — already correct; unique constraint on `client_mutation_id`
- `SyncStateController` (E2E probe) — already correct
- `OfflineController` + `index.html.heex` — unchanged; no reconnect logic belongs here
- `Crosswake.Offline.Contracts` — unchanged; `StudySessionIsland` struct already captures `sync_seam: "study_reviews"` which names the seam this flush targets
- Router (`/study/sync` POST route) — unchanged
- `storage_logic.js` + `offline_storage.spec.ts` — unchanged; storage quota enforcement is a separate concern

---

## Architectural Patterns

### Pattern: Client-Owned Reconnect Flush (Island Contract)

**What:** The offline island is a standalone JS page with no LiveView socket. Sync responsibility belongs entirely to the client code in `offline_study.js`. The server endpoint (`/study/sync`) is stateless and idempotent. The reconnect trigger (`window 'online'`) is a standard browser event.

**Why this fits the Crosswake posture:**
- The `guides/offline.md` document already states "Sync only occurs while the app is active and the user is on the relevant route" — a `window 'online'` listener on the active island page is exactly that scope
- The island contract (`Crosswake.Offline.Contracts.StudySessionIsland`) declares `reconciliation: :explicit` and `authoritative_source: :phoenix` — the flush POST is the explicit reconciliation act
- The `sync_seam: "study_reviews"` field names this seam in the island contract; the JS POSTs to the route that implements it

**What this is NOT:**
- Not a generic sync framework — the flush targets one named seam (`study_reviews`) at one fixed URL (`/study/sync`)
- Not background sync — it fires only while the island page is open
- Not LiveView-driven — the LiveView at `/study/session` and the standalone island at `/offline` are separate routes with separate responsibilities

### Pattern: Idempotency Key in IndexedDB

**What:** Generate `client_mutation_id` at mutation creation time (before queuing to IndexedDB), not at POST time. Store the canonical server shape in `STORE_MUTATIONS` so that `flushOutbox()` can POST rows verbatim without transformation.

**Why:** If `client_mutation_id` is generated at POST time, a retry after a network failure generates a new ID and creates a duplicate row (the server's `on_conflict: :nothing` relies on the same key appearing). Generating the ID at queue time makes the key stable across retries.

### Pattern: Delete-After-Confirm, Not Delete-Preemptively

**What:** In `flushOutbox()`, capture the autoIncrement `id` values of rows before the POST, then delete those specific rows only after receiving a 2xx response.

**Why:** Deleting before confirmation loses mutations if the POST fails (network drop mid-flight, 5xx, etc.). Deleting after 2xx is safe because the server's `on_conflict: :nothing` makes re-delivery of already-accepted mutations harmless.

---

## Anti-Patterns

### Anti-Pattern 1: Reconnect Detection in LiveView

**What people do:** Attach a Phoenix LiveView `handle_event("reconnect", ...)` handler or use `phx-connected` to trigger the flush.

**Why it's wrong:** The offline island page at `/offline` has no LiveView socket — it is rendered by `OfflineController` with `put_root_layout(false)`. The LiveView at `/study/session` is a different route with a different purpose. Coupling the flush to LiveView reconnect would tightly bind the island's sync lifecycle to a server-side process that does not own the outbox.

**Do this instead:** Use `window.addEventListener('online', flushOutbox)` in `offline_study.js`. This is self-contained within the island page's boundary.

### Anti-Pattern 2: Generating `client_mutation_id` at POST Time

**What people do:** Call `crypto.randomUUID()` inside `flushOutbox()` rather than inside `handleReview()`.

**Why it's wrong:** A retry after a failed POST generates a different ID. The server creates a new row rather than deduplicating — the `on_conflict: :nothing` guard becomes ineffective.

**Do this instead:** Generate `client_mutation_id` in `handleReview()` at the moment the mutation is constructed, before calling `queueMutation()`. The ID is immutable from that point forward.

### Anti-Pattern 3: Clearing the Outbox Before the POST Succeeds

**What people do:** Delete rows from STORE_MUTATIONS immediately before or during the `fetch()` call.

**Why it's wrong:** If the network drops mid-POST or the server returns 5xx, the mutations are gone with no way to retry.

**Do this instead:** Capture the row IDs before the POST; delete only those specific rows after receiving a 2xx response. Leave everything in the store on any error.

### Anti-Pattern 4: Using `visibilitychange` as the Reconnect Trigger

**What people do:** Add `document.addEventListener('visibilitychange', ...)` to trigger the flush when the tab regains focus.

**Why it's wrong:** `visibilitychange` fires on tab-switch, not on network reconnect. A user who keeps the tab visible while offline and then regains connectivity would never trigger the flush.

**Do this instead:** Use `window 'online'` for reconnect. Optionally combine with `visibilitychange` as a secondary trigger (flush on tab-focus if `navigator.onLine` is true), but `online` is the primary and sufficient signal.

### Anti-Pattern 5: Keeping the Mock Comment and Button Unchanged

**What people do:** Add the real reconnect flush but leave the `sync_outbox` mock in `StudySessionLive` as-is.

**Why it's wrong:** The comment still says "here we mock it." The example-as-proof-artifact convention means adopters reading the code will see a contradiction: the comment implies no real client flush exists.

**Do this instead:** Remove the mock comment. Either remove the button entirely (cleanest) or re-label it "Manual Sync" with an honest comment explaining it is a secondary escape hatch, not the primary sync path.

---

## Suggested Build Order

The dependency constraint is: the E2E test cannot be rewritten until `offline_study.js` actually fires a real POST. The LiveView cleanup is independent and can happen in parallel.

```
Step 1 — Reconcile the mutation shape (prerequisite for everything else):
    a. In offline_study.js handleReview(): generate client_mutation_id
    b. Map 'pass'→'good', 'fail'→'hard' (result → rating)
    c. Map card.id (string) → integer card_id
    d. Store { client_mutation_id, card_id, rating } in queueMutation call
    Verify: open /offline in browser, review a card, open DevTools IndexedDB inspector,
            confirm mutations store has the correct shape

Step 2 — Add flushOutbox() function (depends on Step 1 — needs correct mutation shape):
    a. Read all rows from STORE_MUTATIONS
    b. POST /study/sync { events: rows }
    c. On 2xx: delete flushed rows by autoIncrement id
    d. On error: leave rows, update status with retry message
    e. Register window.addEventListener('online', flushOutbox) in DOMContentLoaded
    f. Call flushOutbox() optimistically in handleReview() when navigator.onLine is true
    Verify: manually in browser — go offline, review cards, go online, observe POST in DevTools Network,
            confirm rows cleared from IndexedDB

Step 3 — Clean up StudySessionLive (independent of Steps 1-2):
    a. Remove mock comment from sync_outbox handler
    b. Remove the handler and button (Option B), or re-label as "Manual Sync" (Option A)
    Verify: /study/session page renders without the mock button (Option B)
            or renders with correctly-labeled "Manual Sync" button (Option A)

Step 4 — Rewrite E2E test (depends on Steps 1-2 being complete and working):
    a. Remove page.evaluate mutation injection
    b. Remove page.evaluate manual fetch
    c. Add page.click('#btn-flip'), page.click('#btn-pass') (real UI)
    d. Add page.evaluate to read client_mutation_id from IndexedDB
    e. Use page.waitForRequest('/study/sync') before context.setOffline(false)
    f. Keep expect.poll against /_e2e/sync-state/:id (unchanged)
    Verify: run playwright test — the test should pass end-to-end with no mocks
```

---

## Sources

- Direct file inspection: `examples/phoenix_host/priv/static/offline_study.js` (the actual queueMutation implementation)
- Direct file inspection: `examples/phoenix_host/lib/crosswake_example/local_first/study_session_live.ex` (the mock comment at line 31)
- Direct file inspection: `examples/phoenix_host/e2e/offline_sync.spec.ts` (the manual page.evaluate flush)
- Direct file inspection: `examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex`
- Direct file inspection: `examples/phoenix_host/lib/crosswake_example/local_first/study.ex` (on_conflict: :nothing idempotency)
- Direct file inspection: `examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex` (unique_constraint on client_mutation_id)
- Direct file inspection: `examples/phoenix_host/lib/crosswake_example/router.ex` (POST /study/sync route)
- Direct file inspection: `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_controller.ex` (put_root_layout(false), island contract construction)
- Direct file inspection: `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex` (data attributes from island contract, script tag for offline_study.js)
- Direct file inspection: `lib/crosswake/offline/contracts.ex` (StudySessionIsland struct — sync_seam, reconciliation: :explicit, authoritative_source: :phoenix)
- Direct file inspection: `guides/offline.md` (No Background Sync boundary, explicit posture)
- Direct file inspection: `.planning/PROJECT.md` (honest-and-explicit posture, example-host-as-proof-artifact convention)

---
*Architecture research for: Crosswake v12.0 CI Honesty / Real-E2E Sweep — reconnect-driven outbox flush*
*Researched: 2026-06-17*
