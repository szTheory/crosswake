# Phase 112: Real Offline Outbox Flush - Pattern Map

**Mapped:** 2026-06-17
**Files analyzed:** 3 (all modified, none created)
**Analogs found:** 3 / 3 (all from within the same three files — each file is its own closest analog)

---

## File Classification

| Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---------------|------|-----------|----------------|---------------|
| `examples/phoenix_host/priv/static/offline_study.js` | client service + utility | event-driven + CRUD (IndexedDB read/write/delete + HTTP POST) | Itself — `initDB`, `getAllCards`, `queueMutation` are the established tx-promise pattern to replicate | exact (self-analog) |
| `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex` | template / view | request-response (static HTML render) | Itself — existing button markup + `#status` div | exact (self-analog) |
| `examples/phoenix_host/lib/crosswake_example/local_first/study_session_live.ex` | LiveView controller | request-response (LiveView events) | Itself — `sync_outbox` handler, `outbox`/`sync_result` assigns, and render block are the exact code to delete | exact (self-analog) |

---

## Pattern Assignments

### `offline_study.js` (client service, event-driven + CRUD)

**Analog:** Itself — the three existing IndexedDB promise-wrapper helpers.

---

#### Pattern 1: IndexedDB tx-promise pattern (the shape to replicate for `flushOutbox`)

**Source:** `examples/phoenix_host/priv/static/offline_study.js` lines 96–121

```javascript
// getAllCards — readonly getAll tx (replicate for reading STORE_MUTATIONS)
function getAllCards() {
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_CARDS, 'readonly');
    const store = tx.objectStore(STORE_CARDS);
    const request = store.getAll();

    request.onsuccess = () => resolve(request.result);
    request.onerror = (event) => reject(event.target.error);
  });
}

// queueMutation — readwrite add tx (replicate for delete-accepted in flushOutbox)
function queueMutation(mutation) {
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_MUTATIONS, 'readwrite');
    const store = tx.objectStore(STORE_MUTATIONS);
    const request = store.add(mutation);

    request.onsuccess = () => resolve();
    request.onerror = (event) => {
      reject(event.target.error);
    };
    tx.onabort = (event) => {
      reject(tx.error);
    };
  });
}
```

**How to replicate for `flushOutbox`:**

- Read-all step: open `STORE_MUTATIONS` in `'readonly'`, call `store.getAll()`, resolve with `request.result` — identical shape to `getAllCards` but targeting `STORE_MUTATIONS`.
- Delete-accepted step: open `STORE_MUTATIONS` in `'readwrite'`, loop over `acceptedIds` (the autoIncrement `.id` values captured before the POST), call `store.delete(id)` for each. Use `tx.oncomplete` / `tx.onerror` on the single transaction wrapping all deletes (do not open one transaction per record). The `tx.onabort` guard from `queueMutation` applies here too.

**Critical detail (D-03):** `acceptedIds` = only the `.id` values of records whose `client_mutation_id` appears in `data.accepted_records` from the server response — not every record in the batch. Records whose `client_mutation_id` is in `data.rejected` are left in the store for retry.

---

#### Pattern 2: Current `queueMutation` call-site — the shape that MUST change

**Source:** `examples/phoenix_host/priv/static/offline_study.js` lines 166–198

```javascript
// CURRENT (wrong — does not match server contract):
async function handleReview(result) {
  const card = cards[currentCardIndex];

  const mutation = {
    type: 'REVIEW_CARD',
    payload: {
      cardId: card.id,       // string, nested, wrong key
      result: result,        // 'pass'/'fail', wrong key + wrong vocabulary
      timestamp: new Date().toISOString()
    }
  };

  try {
    await queueMutation(mutation);
    // ...
  }
}
```

**Target shape (server contract from `review_event.ex` changeset, lines 15–21):**

The `ReviewEvent.changeset/2` validates:
- `client_mutation_id` — required string, unique
- `card_id` — required integer
- `rating` — required, `validate_inclusion(["good", "hard"])`

So the normalized record stored in `STORE_MUTATIONS` must be:

```javascript
// TARGET — stored at queue time, POSTed verbatim by flushOutbox:
const mutation = {
  client_mutation_id: crypto.randomUUID(),   // generated HERE (not in flushOutbox)
  card_id: parseInt(card.id, 10),            // string '1' → integer 1
  rating: result                             // 'good' or 'hard' (D-01 renames)
};
```

**Why at queue time:** If `client_mutation_id` were generated inside `flushOutbox`, a retry after a failed POST would generate a different UUID — the server's `on_conflict: :nothing` on `client_mutation_id` (study.ex line 35) would create a duplicate row instead of deduplicating.

---

#### Pattern 3: `updateStatus` — existing function to call from `flushOutbox`

**Source:** `examples/phoenix_host/priv/static/offline_study.js` lines 200–205

```javascript
function updateStatus(message) {
  const statusElement = document.getElementById('status');
  if (statusElement) {
    statusElement.textContent = message;
  }
}
```

**D-05 microcopy to pass as `message`:**
- Before POST: `'Syncing…'`
- After 2xx (full drain): `\`Synced ${n} · queued ${remaining}\``
- Optimistic / on-load with nothing to send: do NOT call `updateStatus` — leave the prior card-progress line
- On `'offline'` event: `\`Offline — ${q} saved locally\``
- On fetch error / non-2xx: `\`Sync failed — ${q} still saved locally. Retrying on reconnect.\``

---

#### Pattern 4: `setupEventListeners` — where to register the `'online'` listener

**Source:** `examples/phoenix_host/priv/static/offline_study.js` lines 150–164

```javascript
function setupEventListeners() {
  const btnFlip = document.getElementById('btn-flip');
  const btnPass = document.getElementById('btn-pass');
  const btnFail = document.getElementById('btn-fail');

  btnFlip.addEventListener('click', () => { /* flip */ });
  btnPass.addEventListener('click', () => handleReview('pass'));
  btnFail.addEventListener('click', () => handleReview('fail'));
}
```

**Additions needed here:**
1. After D-01 rename, wire `btnGood`/`btnHard` (replace `btnPass`/`btnFail`) → `handleReview('good')` / `handleReview('hard')`.
2. Register: `window.addEventListener('online', flushOutbox);`
3. Register: `window.addEventListener('offline', () => { /* D-05 offline microcopy */ });`
4. On-load drain: call `flushOutbox()` once at the end of `setupEventListeners` (or in `DOMContentLoaded` after `setupEventListeners()`) — this is the third reconnect trigger (handles the case where the page loads while already online with queued mutations from a prior offline session).

**Single-flight guard:** add a module-level flag `let flushing = false` before `flushOutbox` entry; set `flushing = true` on entry, `flushing = false` in `finally`. Guard: `if (flushing) return;`. This keeps status counts clean when all three triggers fire close together (the server's idempotency makes a double-POST harmless, but the guard prevents confusing "Syncing…" → "Syncing…" → "Synced 2" sequences).

---

#### Pattern 5: Server response shape — what `flushOutbox` must parse

**Source:** `examples/phoenix_host/lib/crosswake_example/local_first/study.ex` lines 39–42

```elixir
{:ok, %{accepted_count: count, accepted_records: records, rejected: Enum.reverse(rejections)}}
```

**Source:** `examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex` lines 5–8

```elixir
def sync(conn, %{"events" => events}) when is_list(events) do
  case Study.sync_events(events) do
    {:ok, result} ->
      json(conn, %{data: result})
```

So the HTTP 200 body is `{ "data": { "accepted_count": N, "accepted_records": [...], "rejected": [...] } }`.

**Client parsing:**
```javascript
const data = await response.json();
// data.data.accepted_records — array of accepted ReviewEvent structs (with client_mutation_id)
// data.data.rejected         — array of { client_mutation_id, errors }
```

**POST body the server requires** (sync_controller.ex line 5, `%{"events" => events}`):
```javascript
JSON.stringify({ events: pendingMutations })
// where pendingMutations = array of { client_mutation_id, card_id, rating }
```

---

### `offline_html/index.html.heex` (template, request-response)

**Analog:** Itself — the existing button elements and `#status` div.

---

#### Pattern 6: Button markup to relabel (D-01 + D-02)

**Source:** `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex` lines 87–96

```html
<!-- CURRENT (to be replaced): -->
<div id="controls">
  <button id="btn-flip" class="btn-primary">Flip Card</button>
  <button id="btn-pass" class="btn-success" style="display: none;">Pass</button>
  <button id="btn-fail" class="btn-danger" style="display: none;">Fail</button>
</div>

<div id="status"></div>
```

**Target (D-01 + D-02 + D-06):**
- `id="btn-pass"` → `id="btn-good"`, label `Pass` → `Good`
- `id="btn-fail"` → `id="btn-hard"`, label `Fail` → `Hard`
- D-02: `btn-good` = primary affordance (`class="btn-primary"`); `btn-hard` = neutral/secondary outlined — executor may use `btn-secondary` or an outlined variant; must pass AA in light + dark with no color-only signaling. The existing `.btn-success` / `.btn-danger` classes are what carry the green/rust border — consider replacing `.btn-danger` on the Hard button with a neutral outlined style (e.g., `border-color: var(--cw-border-default)`).
- D-06: Add `aria-live="polite" role="status" aria-atomic="true"` to `<div id="status">`.

**Final markup target:**
```html
<div id="controls">
  <button id="btn-flip" class="btn-primary">Flip Card</button>
  <button id="btn-good" class="btn-primary" style="display: none;">Good</button>
  <button id="btn-hard" class="btn-secondary" style="display: none;">Hard</button>
</div>

<div id="status" aria-live="polite" role="status" aria-atomic="true"></div>
```

(Exact class names for `btn-hard` at executor discretion — must be outlined/neutral, not `.btn-danger` rust.)

---

#### Pattern 7: Existing CSS button tokens (inline `<style>`) — what the executor can reuse

**Source:** `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex` lines 59–73

```css
button {
  padding: 0.75rem 1.5rem;
  border-radius: var(--cw-radius-sm);
  border: 2px solid transparent;
  font-weight: bold;
  cursor: pointer;
}
.btn-primary { background: var(--cw-action-bg); color: var(--cw-action-fg); }
/*
  D-06 outlined treatment: --cw-status-error (rust-600) does NOT flip in dark mode
  and sits at ~3.1:1 against the near-black surface in either role, so it cannot
  carry AA text. Status is conveyed by a >=3:1 colored border + the button label;
  text uses --cw-text-default for full AA in both modes.
*/
.btn-success { background: transparent; color: var(--cw-text-default); border-color: var(--cw-status-success); }
.btn-danger  { background: transparent; color: var(--cw-text-default); border-color: var(--cw-status-error); }
#status {
  margin-top: 2rem;
  font-size: var(--cw-text-scale-sm);
  color: var(--cw-text-muted);
}
```

**For `btn-hard` neutral treatment:** add a `btn-secondary` rule:
```css
.btn-secondary { background: transparent; color: var(--cw-text-default); border-color: var(--cw-border-default); }
```

**D-07 error state on `#status`:** when `flushOutbox` fails, `updateStatus` sets the text — the error variant requires a left border to convey error without color-alone. `offline_study.js` should toggle a class or inline style, not a new element:
```javascript
// On flush failure — add error indicator via border (non-text threshold: 3:1)
statusElement.style.borderLeft = '3px solid var(--cw-status-error)';
statusElement.style.paddingLeft = '0.5rem';
statusElement.style.color = 'var(--cw-text-default)';  // full AA
// On all other states — clear it:
statusElement.style.borderLeft = '';
statusElement.style.paddingLeft = '';
statusElement.style.color = '';  // falls back to #status rule's --cw-text-muted
```

---

### `study_session_live.ex` (LiveView controller, request-response)

**Analog:** Itself — every line to delete is already in this file.

---

#### Pattern 8: Full inventory of what to delete

**Source:** `examples/phoenix_host/lib/crosswake_example/local_first/study_session_live.ex`

**Lines 5–9 — `mount/3` assigns to remove:**
```elixir
def mount(_params, _session, socket) do
  {:ok, assign(socket,
    current_card_id: 1,
    outbox: [],        # DELETE THIS LINE
    sync_result: nil   # DELETE THIS LINE
  )}
end
```
After deletion, `mount/3` assigns only `current_card_id: 1`.

**Lines 29–47 — entire `sync_outbox` handler to delete:**
```elixir
def handle_event("sync_outbox", _params, socket) do
  # Artificially simulate pushing to the outbox via the sync controller or context
  # Usually this would be pushed by the client offline capability, but here we mock it

  payload = Enum.map(socket.assigns.outbox, fn ev ->
    %{
      "client_mutation_id" => ev.client_mutation_id,
      "card_id" => ev.card_id,
      "rating" => ev.rating
    }
  end)

  case CrosswakeExample.LocalFirst.Study.sync_events(payload) do
    {:ok, result} ->
      {:noreply, assign(socket, outbox: [], sync_result: "Synced #{result.accepted_count} events")}
    {:error, _reason} ->
      {:noreply, assign(socket, sync_result: "Sync failed")}
  end
end
```
DELETE all of lines 29–47.

**Lines 22–26 — `rate` handler outbox accumulation to simplify:**
```elixir
# Lines 22–26 — current (references outbox):
next_card_id = socket.assigns.current_card_id + 1
outbox = [event | socket.assigns.outbox]
{:noreply, assign(socket, current_card_id: next_card_id, outbox: outbox, sync_result: nil)}
```
After deletion of `outbox`/`sync_result` assigns, simplify to:
```elixir
next_card_id = socket.assigns.current_card_id + 1
{:noreply, assign(socket, current_card_id: next_card_id)}
```
The local `event` variable (lines 14–19) also becomes unused — delete it too, or the compiler will warn. The `rate` handler's purpose (progressing the card) still stands; only the outbox accumulation is removed.

**Lines 64–74 — render outbox-status block to delete:**
```heex
<div class="outbox-status">
  <h3>Local Outbox (<%= length(@outbox) %> items)</h3>
  <%= if length(@outbox) > 0 do %>
    <button phx-click="sync_outbox" class="button secondary">Simulate Network Sync</button>
  <% end %>

  <%= if @sync_result do %>
    <p class="success"><%= @sync_result %></p>
  <% end %>
</div>
```
DELETE this entire block (lines 64–74).

**No test cleanup needed:** `grep -rn "sync_outbox|outbox|sync_result" examples/phoenix_host/test/` returned no results. Deletion is safe.

---

## Shared Patterns

### IndexedDB Promise-Wrapper Convention

**Source:** `examples/phoenix_host/priv/static/offline_study.js` — all three existing helpers (`initDB` lines 55–76, `getAllCards` lines 96–105, `queueMutation` lines 107–121).

**Apply to:** The two new helpers inside `flushOutbox` (read-all from STORE_MUTATIONS; delete-accepted records).

**Convention:** `new Promise((resolve, reject) => { const tx = db.transaction(STORE, mode); const store = tx.objectStore(STORE); /* request */ request.onsuccess = () => resolve(...); request.onerror = (event) => reject(event.target.error); tx.onabort = (event) => reject(tx.error); })` — always attach both `request.onerror` and `tx.onabort`.

---

### Server Contract Shape

**Source:** `examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex` lines 15–21 (changeset); `sync_controller.ex` lines 5–8 (POST handler); `study.ex` lines 39–42 (response shape).

**Apply to:** `offline_study.js` — both the mutation record stored in IndexedDB and the payload POSTed to `/study/sync`.

**Rule:** The IndexedDB record shape and the POST body array element must be identical: `{ client_mutation_id: "<uuid>", card_id: <integer>, rating: "good"|"hard" }`. No wrapper fields (`type`, `payload`), no string `card_id`, no `'pass'`/`'fail'` values.

---

### CSS Semantic Token Convention

**Source:** `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex` lines 9–74 (inline `<style>` block).

**Apply to:** All additions to the HEEx file (new button class; `#status` error state). Never use hardcoded hex — always `var(--cw-*)` from `tokens.css`. The D-08 cleanup of the hardcoded hex in `displayHardBlock()` and `QuotaExceededError` handler in `offline_study.js` (lines 48, 189–191) follows the same rule.

---

## No Analog Found

None — all three files are their own closest analogs and contain sufficient pattern material for the executor to replicate.

---

## Metadata

**Analog search scope:** `examples/phoenix_host/priv/static/`, `examples/phoenix_host/lib/crosswake_example/local_first/`, `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/`
**Files read:** 6 (`offline_study.js`, `index.html.heex`, `study_session_live.ex`, `sync_controller.ex`, `study.ex`, `review_event.ex`)
**Test scan:** `examples/phoenix_host/test/` — zero references to `sync_outbox`, `outbox` assign, or `sync_result`
**Pattern extraction date:** 2026-06-17
