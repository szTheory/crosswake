# Phase 113: Honest E2E Rewrite + Compile Gate — Pattern Map

**Mapped:** 2026-06-18
**Files analyzed:** 6 (5 in-scope + 1 optional)
**Analogs found:** 6 / 6

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `examples/phoenix_host/e2e/offline_sync.spec.ts` | test | event-driven + request-response | `examples/phoenix_host/e2e/offline_storage.spec.ts` | role-match (same test framework, same route `/offline`, same `addInitScript` pattern) |
| `examples/phoenix_host/lib/crosswake_example/e2e/sync_state_controller.ex` | controller | request-response | self (extend existing `show/2`) | exact — only additive change |
| `.github/workflows/phase90-proof.yml` | config | batch | self (insert step between existing anchors) | exact — surgical YAML edit |
| `examples/phoenix_host/e2e/offline_storage.spec.ts` | test | event-driven | self (fix two lines) | exact — two-line selector/text fix |
| `examples/phoenix_host/test/support/flashcards_fixtures.ex` | test | CRUD | self (fix line 47) | exact — one-line rename fix |
| `examples/phoenix_host/priv/static/offline_study.js` | utility | event-driven | self (optional `export`) | exact — one-line export addition |

---

## Pattern Assignments

### `examples/phoenix_host/e2e/offline_sync.spec.ts` (test, event-driven + request-response)

**Analog:** `examples/phoenix_host/e2e/offline_storage.spec.ts`

**Imports pattern** (`offline_storage.spec.ts` lines 1):
```typescript
import { test, expect } from '@playwright/test';
```
Drop the fraudulent `import { randomUUID } from 'crypto'` — no test-minted UUIDs in the honest rewrite.

**`addInitScript` isolation pattern** (`offline_storage.spec.ts` lines 6–16, adapted for `beforeEach`):
```typescript
// offline_storage.spec.ts uses addInitScript inside each test body.
// offline_sync.spec.ts uses it in beforeEach (D-01: must be beforeEach, not beforeAll).
test.beforeEach(async ({ page }) => {
  await page.addInitScript(() => {
    // keep in sync with offline_study.js:3 (DB_NAME = 'crosswake_offline_study')
    indexedDB.deleteDatabase('crosswake_offline_study');
  });
});
```

**`page.goto('/offline')` + real UI click pattern** (`offline_storage.spec.ts` lines 18, 88):
```typescript
await page.goto('/offline');
// ... later, real UI interaction (no page.evaluate for state writing):
await page.click('#btn-flip');
await page.click('#btn-good');   // was '#btn-pass' before Phase 112 rename
```

**IndexedDB read-only observation pattern** (mirrors `offline_study.js:123–133` `getAllMutations` shape):
```typescript
// OBSERVATION_ONLY — reads IndexedDB, writes nothing
const mutations = await page.evaluate(() => {
  return new Promise((resolve, reject) => {
    const req = indexedDB.open('crosswake_offline_study', 1);
    req.onsuccess = () => {
      const db = req.result;
      const tx = db.transaction('mutations', 'readonly');
      const store = tx.objectStore('mutations');
      const getAll = store.getAll();
      getAll.onsuccess = () => resolve(getAll.result);
      getAll.onerror = () => reject(getAll.error);
    };
    req.onerror = () => reject(req.error);
  });
});
expect(mutations).toHaveLength(1);
const { client_mutation_id: capturedId, card_id, rating } = mutations[0];
```
This mirrors `getAllMutations()` at `offline_study.js:123–133` exactly — same transaction + `getAll` promise-wrap structure, no cursor.

**Reconnect trigger pattern** (new — no existing analog; D-03 locked decision):
```typescript
await context.setOffline(false);
// page.dispatchEvent cannot target window — use page.evaluate exclusively
await page.evaluate(() => window.dispatchEvent(new Event('online'))); // OBSERVATION_ONLY (env simulation)
// D-03b: deterministic reconnect — confirm app reacted before polling Ecto
await page.waitForResponse(r => r.url().includes('/study/sync') && r.status() === 200);
```

**`expect.poll` Ecto assertion pattern** (mirrors `offline_sync.spec.ts` lines 61–68 but with `page.request.get` + scoped `count` field):
```typescript
await expect.poll(async () => {
  const res = await page.request.get(`/_e2e/sync-state/${capturedId}`);
  return res.ok() ? res.json() : { synced: false };
}, { timeout: 8000, message: 'Ecto row should reflect the flushed mutation' })
  .toMatchObject({ synced: true, count: 1 });
```

**`APIRequestContext` duplicate POST pattern** (D-02b — `page.request.post` unaffected by `context.setOffline`):
```typescript
// Sequence: original flush fully confirmed (synced: true) BEFORE firing duplicate
const dupRes = await page.request.post('/study/sync', {
  data: { events: [{ client_mutation_id: capturedId, card_id, rating }] }
});
expect(dupRes.ok()).toBe(true);
const dupBody = await dupRes.json();
// accepted_count is nested under .data (Phoenix JSON wrapper) — not top-level
expect(dupBody.data.accepted_count).toBe(0); // on_conflict: :nothing held

await expect.poll(async () => {
  const res = await page.request.get(`/_e2e/sync-state/${capturedId}`);
  return res.ok() ? res.json() : { count: -1 };
}, { timeout: 5000 }).toMatchObject({ count: 1 }); // still exactly one row
```

**`describe`/test name pattern** (D-07 — teaching artifact naming):
```typescript
test.describe('Crosswake offline island: card rating queues in IndexedDB, reconnect flushes via app code, Ecto confirms exactly one review row', () => {
  test('offline rating queues in IndexedDB, reconnect via app flush, Ecto confirms one row, duplicate is idempotent', async ({ page, context }) => {
```

**Step-labeled comment structure** (D-07):
```typescript
// Step 1: Navigate to the offline island
// Step 2: Go offline at the network layer
// Step 3: Queue a mutation via real UI (drives handleReview('good') → queueMutation)
// Step 4: Observe the queued record from IndexedDB (OBSERVATION_ONLY — no app state written)
// Step 5: Reconnect — two-step: CDP transport + explicit 'online' event
// Step 6: Server confirms exactly one row
// Step 7: Assert outbox is empty (app deleted the accepted record)
// Step 8: Duplicate flush — same client_mutation_id — assert exactly one Ecto row
```

**Optional D-06 socketless boundary assertion** (one-liner; include unless awkward):
```typescript
// Proves /offline is a socketless island (no LiveView WebSocket dependency)
expect(await page.evaluate(() => !!window.liveSocket)).toBe(false);
```

---

### `examples/phoenix_host/lib/crosswake_example/e2e/sync_state_controller.ex` (controller, request-response)

**Analog:** self — additive extension of the existing `show/2` at lines 7–15.

**Current file** (`sync_state_controller.ex` lines 1–16 — read verbatim above):
```elixir
defmodule CrosswakeExample.E2E.SyncStateController do
  use Phoenix.Controller, formats: [:json]

  alias CrosswakeExample.Repo
  alias CrosswakeExample.LocalFirst.ReviewEvent

  def show(conn, %{"client_mutation_id" => id}) do
    case Repo.get_by(ReviewEvent, client_mutation_id: id) do
      nil ->
        json(conn, %{synced: false})

      record ->
        json(conn, %{synced: true, status: record.status})
    end
  end
end
```

**Target pattern** — add `@moduledoc`, `import Ecto.Query`, and scoped `count` field:
```elixir
defmodule CrosswakeExample.E2E.SyncStateController do
  @moduledoc """
  Test-only endpoint for asserting server-side sync state in E2E specs.

  Mounted only in :test and :e2e environments (see router.ex ~line 378).
  Never mounted in :prod. See Phase 114 GUARD-02 for the enforced assertion.
  """
  use Phoenix.Controller, formats: [:json]

  import Ecto.Query, warn: false

  alias CrosswakeExample.Repo
  alias CrosswakeExample.LocalFirst.ReviewEvent

  def show(conn, %{"client_mutation_id" => id}) do
    # count MUST be scoped to the id — bare aggregate counts the whole table (> 1 in multi-test runs)
    count =
      from(r in ReviewEvent, where: r.client_mutation_id == ^id)
      |> Repo.aggregate(:count, :id)

    case Repo.get_by(ReviewEvent, client_mutation_id: id) do
      nil ->
        json(conn, %{synced: false, count: 0})

      record ->
        json(conn, %{synced: true, status: record.status, count: count})
    end
  end
end
```

Key additions:
- `@moduledoc` block at top (pre-stages Phase 114 GUARD-02)
- `import Ecto.Query, warn: false` (line after `use` — NOT currently present)
- `count =` scoped query before the `case` (scoped to `^id`, not bare aggregate)
- `count: 0` in `nil` branch; `count: count` in `record` branch

Ecto query pattern sourced from `local_first/` context pattern (same `from/2` + `Repo.aggregate` idiom used elsewhere in the app).

---

### `.github/workflows/phase90-proof.yml` (config, batch)

**Analog:** self — insert a new step between two existing verified anchors.

**Existing step anchors** (lines 28–34 — read verbatim above):
```yaml
      - name: Install Mix dependencies    # line 28 — INSERT AFTER this step (line 30 closes it)
        run: mix deps.get
        working-directory: examples/phoenix_host
                                          # ← INSERT NEW STEP HERE
      - name: Install dependencies        # line 32 — new step goes BEFORE this
        run: npm ci
        working-directory: examples/phoenix_host
```

**Step to insert** (D-04):
```yaml
      - name: Compile (warnings as errors)
        run: MIX_ENV=test mix compile --warnings-as-errors
        working-directory: examples/phoenix_host
```

`MIX_ENV=test` is mandatory — it compiles the `_e2e` route and `elixirc_paths(:test)` tree (the exact v6.0 break path that `MIX_ENV=dev` misses). Do NOT rename the job `e2e-offline-sync` at line 11 (Phase 114's responsibility).

---

### `examples/phoenix_host/e2e/offline_storage.spec.ts` (test, event-driven)

**Analog:** self — two-line surgical fix.

**Line 89 — hard fix** (lane is red today; whole Playwright suite blocked):
```typescript
// Current (broken — Phase 112 renamed the button):
await page.click('#btn-pass');

// Fix:
await page.click('#btn-good');
```
Selector `#btn-good` verified at `offline_study.js:277` and `index.html.heex:87`.

**Line 92 — honesty tightening** (recommended, not required; passes today by substring):
```typescript
// Current (partial string — passes by substring match today):
const notification = page.locator('text=Device storage limit reached! Cannot save more progress.');

// Recommended fix (full string from offline_study.js:317):
const notification = page.locator('text=Device storage limit reached! Cannot save more progress. Please free up space on your device.');
```

---

### `examples/phoenix_host/test/support/flashcards_fixtures.ex` (test, CRUD)

**Analog:** self — one-line rename fix required to unblock `MIX_ENV=test mix compile --warnings-as-errors`.

**Line 47 — pre-flight fix** (D-04b; compile gate is born red without this):
```elixir
# Current (broken — function was renamed to upsert_progress/1):
|> CrosswakeExample.Flashcards.create_progress()

# Fix:
|> CrosswakeExample.Flashcards.upsert_progress()
```
`CrosswakeExample.Flashcards.upsert_progress/1` confirmed at `flashcards.ex:82`. This is the ONLY compile warning the pre-flight run surfaced.

---

### `examples/phoenix_host/priv/static/offline_study.js` (utility, event-driven) — OPTIONAL

**Analog:** self — optional one-line `export` addition (D-01 executor discretion).

**Line 3 — current:**
```javascript
const DB_NAME = 'crosswake_offline_study';
```

**Optional change:**
```javascript
export const DB_NAME = 'crosswake_offline_study';
```

**Recommendation from RESEARCH.md:** Use a `// keep in sync with offline_study.js:3` comment in the spec instead. The file is served as `<script type="module">` (ES module export is technically supported), but the spec would need to import from a served static URL — more friction than a comment. Unless the executor prefers the import, keep line 3 unchanged and comment the spec inline.

---

## Shared Patterns

### IndexedDB Promise-Wrap (read-only observation)
**Source:** `offline_study.js:123–133` (`getAllMutations` function)
**Apply to:** Both IndexedDB `page.evaluate` blocks in `offline_sync.spec.ts` (Step 4 and Step 7)
```javascript
// App's own getAllMutations pattern (offline_study.js:123–133):
function getAllMutations() {
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_MUTATIONS, 'readonly');
    const store = tx.objectStore(STORE_MUTATIONS);
    const request = store.getAll();
    request.onsuccess = () => resolve(request.result);
    request.onerror = (event) => reject(event.target.error);
    tx.onabort = () => reject(tx.error);
  });
}
```
The spec version must `indexedDB.open(...)` first (no shared `db` handle in the browser context), then mirrors the `tx → store → getAll → promise` shape exactly.

### Scoped Ecto Query
**Source:** D-02 locked decision; footgun: bare `Repo.aggregate` returns > 1 in multi-test run
**Apply to:** `sync_state_controller.ex` `count` calculation
```elixir
# Always scope to the id — never bare aggregate
from(r in ReviewEvent, where: r.client_mutation_id == ^id)
|> Repo.aggregate(:count, :id)
```

### `addInitScript` Isolation
**Source:** `offline_storage.spec.ts` lines 6–16
**Apply to:** `offline_sync.spec.ts` `beforeEach`
- `addInitScript` callback runs BEFORE the page's own scripts (before `DOMContentLoaded`)
- `beforeEach` (not `beforeAll`) is mandatory — `beforeAll` reintroduces dirty-DB-on-retry hazard under `retries: 2`

### `MIX_ENV=test` Compile Requirement
**Source:** D-04 locked decision
**Apply to:** `phase90-proof.yml` compile step; local pre-flight verification
- `MIX_ENV=dev` misses `elixirc_paths(:test)` (includes `test/support/`) and the `if Mix.env() in [:test, :e2e]` `_e2e` route — exactly the v6.0 gap
- Always: `MIX_ENV=test mix compile --warnings-as-errors`

### Sequence Discipline (duplicate POST)
**Source:** D-02b locked decision; Pitfall 4
**Apply to:** Step 8 of the spec rewrite
- WRONG: fire duplicate POST, then await `synced: true`
- CORRECT: await `synced: true` (original flush confirmed), THEN fire duplicate POST, THEN assert `count === 1`

---

## No Analog Found

All files have either an exact self-analog (surgical edits) or a close role-match analog (`offline_storage.spec.ts`). No files lack an analog.

The reconnect trigger pattern (`context.setOffline(false)` + `page.evaluate(dispatchEvent('online'))`) has no existing in-repo analog — it is a net-new pattern introduced by Phase 113 per the D-03 locked decision. The RESEARCH.md provides the complete code excerpt; no codebase analog search is needed.

---

## Metadata

**Analog search scope:** `examples/phoenix_host/e2e/`, `examples/phoenix_host/lib/crosswake_example/e2e/`, `examples/phoenix_host/priv/static/offline_study.js`, `.github/workflows/phase90-proof.yml`, `examples/phoenix_host/test/support/`
**Files read:** 7 (offline_storage.spec.ts, offline_sync.spec.ts, sync_state_controller.ex, phase90-proof.yml, flashcards_fixtures.ex, offline_study.js lines 1–15 + 120–139)
**Pattern extraction date:** 2026-06-18
