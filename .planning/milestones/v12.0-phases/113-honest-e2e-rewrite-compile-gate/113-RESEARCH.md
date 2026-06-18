# Phase 113: Honest E2E Rewrite + Compile Gate — Research

**Researched:** 2026-06-17
**Domain:** Playwright E2E rewrite (IndexedDB observation + CDP offline + Phoenix test endpoint) + GitHub Actions compile gate
**Confidence:** HIGH — consolidated from two waves of pre-baked research (CONTEXT.md D-01..D-07) plus live tree verification of every code anchor cited below

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01** Test isolation: `beforeEach` `addInitScript(() => indexedDB.deleteDatabase('crosswake_offline_study'))` — never `beforeAll`; DB name verified at `offline_study.js:3`; prefer importing the exported `DB_NAME` constant over a hardcoded string.
- **D-01b** Ecto isolation: no reset endpoint, no SQL.Sandbox; key every assertion on the app-generated `client_mutation_id`; `retries: 2` is safe under this scheme.
- **D-02** Extend `GET /_e2e/sync-state/:client_mutation_id` to return a **scoped** `count` (WHERE `client_mutation_id = ^id`); bare table aggregate is a deterministic failure bug. Add `@moduledoc` stating test-only purpose (pre-stages GUARD-02).
- **D-02b** Duplicate-POST via `page.request.post('/study/sync', { data: { events: [...] } })` replaying the IndexedDB-read `capturedId`; assert `count === 1`; sequence: let app flush first, then fire the duplicate.
- **D-03** After `context.setOffline(false)`, MUST do `await page.evaluate(() => window.dispatchEvent(new Event('online')))` — `setOffline(false)` does NOT fire the browser `online` event; `flushOutbox` (bound at `offline_study.js:280`) never fires without this.
- **D-03b** `await page.waitForResponse(r => r.url().includes('/study/sync') && r.status() === 200)` between the `online` dispatch and the Ecto poll (deterministic reconnect assertion per PITFALLS Pitfall 2).
- **D-03c** `page.evaluate` permitted ONLY for read-only IndexedDB observation and the `online` dispatch; forbidden if it writes app state, invokes `flushOutbox` directly, or calls `fetch(`.
- **D-03d** Full flow: `goto /offline` → `setOffline(true)` → click `#btn-flip` then `#btn-good` → read IndexedDB (observe `{client_mutation_id, card_id, rating}`) → `setOffline(false)` + dispatch `online` → `waitForResponse('/study/sync', 200)` → `expect.poll('/_e2e/sync-state/:id')` `synced: true` → read IndexedDB (assert outbox empty) → duplicate case.
- **D-04** Add compile step to `offline-sync-e2e-gate.yml` after "Install Mix dependencies" and before npm/Playwright steps: `MIX_ENV=test mix compile --warnings-as-errors` in `examples/phoenix_host`. `MIX_ENV=test` is mandatory.
- **D-04b** Pre-flight: fix all warnings in demo app and parent lib before landing the step; the gate must land green.
- **D-05** Fix `offline_storage.spec.ts:89` `#btn-pass` → `#btn-good` (hard fix — lane is red today). `offline_storage.spec.ts:92` text locator: tighten to full string (recommended).
- **D-06** Recommended: assert `expect(await page.evaluate(() => !!window.liveSocket)).toBe(false)` — proves the Offline Island boundary. Defer if socket-detection surface is awkward.
- **D-07** Test-as-documentation DX: step-labeled comment blocks, precise describe/test name, `// OBSERVATION_ONLY` on every surviving `page.evaluate`.
- **DO NOT rename the CI job** `e2e-offline-sync` (Phase 114 renames it to `merge-blocking-offline-sync-e2e`; renaming early silently drops it from any future required-checks list).

### Claude's Discretion
- IndexedDB read/delete plumbing for the spec (cursor vs `getAll`) — mirror the in-file promise-wrapped tx helpers (`getAllMutations`/`deleteAcceptedMutations` at `offline_study.js:123`+).
- Whether to `export DB_NAME` from `offline_study.js` for the spec import vs inline with a `// keep in sync with offline_study.js:3` comment.
- Whether to include D-06 socketless-boundary assertion or defer.

### Deferred Ideas (OUT OF SCOPE)
- `data-testid` selector convention across the offline HEEx.
- TODO-001: `FlashcardsTest` field-name drift + flaky `Chimeway.RegistryNotificationOpenTest` (`mix test` concern → Phase 115).
- D-06 boundary assertion if socket-detection surface proves awkward.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| E2E-03 | `offline_sync.spec.ts` proves the full offline→reconnect→reconcile loop with zero `page.evaluate()` calls that write app state: (a) real UI click while offline queues via app code; (b) IndexedDB read asserts queued record and extracts app-generated `client_mutation_id`; (c) `setOffline(false)` + `dispatchEvent(new Event('online'))` triggers app's own `flushOutbox()`; (d) `expect.poll` on `/_e2e/sync-state/:id` confirms Ecto row; (e) follow-up IndexedDB read confirms outbox empty; (f) duplicate-flush POSTs same id twice and asserts single Ecto row; `beforeEach` resets IndexedDB | Sections: Standard Stack, Architecture Patterns, Code Examples, Validation Architecture |
| E2E-04 | `offline-sync-e2e-gate.yml` runs `mix compile --warnings-as-errors` in `examples/phoenix_host` BEFORE Playwright, so a compile break fails loudly instead of masquerading as a port-connection timeout | Sections: Standard Stack, Code Examples, Common Pitfalls, Validation Architecture |
</phase_requirements>

---

## Summary

Phase 113 is a surgical, well-bounded change to three files (spec rewrite, controller extension, CI step insertion) and one collateral file (sibling spec fix). The research is complete — two waves of parallel deep research in CONTEXT.md (D-01..D-07) resolved every implementation decision, and a live tree verification pass (this document) confirms all code anchors.

The phase exists because `offline_sync.spec.ts` is structurally fraudulent: it injects mutations into `window['crosswake_offline_mutations']` (a global the app never reads), manually fires `fetch('/study/sync')`, and asserts on a test-minted UUID it placed there itself. Phase 112 shipped the real app; Phase 113 writes the real test. The server side (`Study.sync_events/1`, `SyncController`, `/_e2e/sync-state/:id`) is already correct and is NOT touched.

The two deterministic failure bugs that the red-team caught are now locked into the decisions: (1) bare `Repo.aggregate` over the whole table returns > 1 in any multi-test run — scope it to the `client_mutation_id`; (2) `context.setOffline(false)` does NOT dispatch the browser `online` event — `flushOutbox` bound at `offline_study.js:280` never fires without an explicit `page.evaluate(() => window.dispatchEvent(new Event('online')))`.

**Primary recommendation:** Execute the five-file change surface in the order: pre-flight compile clean → sibling spec fix (D-05) → controller extension (D-02) → spec rewrite (D-03d) → CI step insertion (D-04). This order lets each step be verified independently.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Offline mutation queue (write) | Browser / Client (`offline_study.js`) | — | `queueMutation()` writes to IndexedDB `mutations` store; the store lives entirely in the browser |
| Outbox flush + reconnect | Browser / Client (`offline_study.js::flushOutbox`) | API / Backend (`/study/sync`) | Client owns the trigger and drain; server owns idempotent reconciliation |
| Sync reconciliation | API / Backend (`Study.sync_events/1`) | Database / Storage (Ecto/Postgres) | `insert_all on_conflict: :nothing` is a server-side Ecto decision |
| Test observation endpoint | API / Backend (`SyncStateController`) | — | Compile-time gated (`Mix.env() in [:test, :e2e]`); never mounted in prod |
| CI compile gate | CDN / Static (GitHub Actions) | — | YAML step runs before Playwright spins up the webServer |
| Playwright test driver | Browser / Client (CDP) | — | `context.setOffline` is a CDP network-layer toggle; `page.evaluate` is JS in the browser sandbox |

---

## Standard Stack

### Core (no new dependencies — all already installed)

| Library | Version | Purpose | Status |
|---------|---------|---------|--------|
| `@playwright/test` | 1.60.0 (already in package.json) | E2E test runner; `context.setOffline`, `page.addInitScript`, `expect.poll`, `page.request.*` | Already installed |
| Phoenix / Ecto | (project version) | `SyncStateController` extension; `Repo.aggregate` with scoped query | Already installed |

**No new packages are installed in this phase.** The Package Legitimacy Audit is therefore empty.

### Playwright APIs Required

| API | Use |
|-----|-----|
| `page.addInitScript(fn)` | Delete IndexedDB before page scripts run (`beforeEach`) |
| `context.setOffline(bool)` | CDP network-layer offline toggle |
| `page.evaluate(fn)` | Read-only IndexedDB observation; `window.dispatchEvent(new Event('online'))` |
| `page.waitForResponse(predicate)` | Deterministic reconnect confirmation (D-03b) |
| `expect.poll(fn, opts)` | Poll `/_e2e/sync-state/:id` until `synced: true` |
| `page.request.post(url, opts)` | `APIRequestContext` duplicate POST (D-02b); unaffected by `context.setOffline` |
| `page.click(selector)` | Real UI interaction — `#btn-flip`, `#btn-good` |

---

## Package Legitimacy Audit

No external packages are added in this phase. This section is intentionally omitted.

---

## Architecture Patterns

### System Architecture Diagram

```
[Playwright test]
    │
    ├─ page.addInitScript → deleteDatabase('crosswake_offline_study')     [ISOLATION]
    │
    ├─ page.goto('/offline')
    │
    ├─ context.setOffline(true)                                           [CDP LAYER]
    │
    ├─ page.click('#btn-flip') → page.click('#btn-good')                  [REAL UI]
    │       │
    │       └─ app offline_study.js: handleReview('good')
    │               → queueMutation({client_mutation_id, card_id, rating})
    │               → IndexedDB mutations store
    │
    ├─ page.evaluate: read IndexedDB mutations store                       [OBSERVATION]
    │       → extract {client_mutation_id, card_id, rating}
    │       → assert 1 record present (E2E-03b)
    │
    ├─ context.setOffline(false)                                          [CDP LAYER]
    │
    ├─ page.evaluate: window.dispatchEvent(new Event('online'))           [ENV SIMULATION]
    │       │
    │       └─ app offline_study.js: flushOutbox() (listener at :280)
    │               → POST /study/sync {"events":[...]}
    │               → Study.sync_events/1: insert_all on_conflict: :nothing
    │               → deleteAcceptedMutations (by client_mutation_id)
    │
    ├─ page.waitForResponse('/study/sync', 200)                           [DETERMINISM]
    │
    ├─ expect.poll: GET /_e2e/sync-state/:capturedId                     [SERVER CONFIRM]
    │       → SyncStateController.show: {synced: true, status: ..., count: 1}
    │
    ├─ page.evaluate: read IndexedDB mutations store                       [OBSERVATION]
    │       → assert 0 records (outbox drained, E2E-03e)
    │
    └─ page.request.post('/study/sync', {events: [capturedId replay]})   [IDEMPOTENCY]
            → APIRequestContext (unblocked by setOffline)
            → expect.poll: count === 1 (on_conflict: :nothing held)
```

### Recommended File Change Surface

```
examples/phoenix_host/
├── e2e/
│   ├── offline_sync.spec.ts          # Full rewrite (the fraud → honest loop)
│   └── offline_storage.spec.ts       # Collateral fix: lines 89 + 92
├── lib/crosswake_example/
│   └── e2e/
│       └── sync_state_controller.ex  # Add scoped count field + @moduledoc
└── priv/static/
    └── offline_study.js              # Optional: export DB_NAME (D-01 executor discretion)
.github/workflows/
└── offline-sync-e2e-gate.yml                 # Add compile step (D-04)
```

### Pattern 1: IndexedDB Delete in `beforeEach` (D-01)

**What:** Delete the `crosswake_offline_study` database before each test using `addInitScript`, which runs BEFORE the page's own scripts (the app opens the DB on `DOMContentLoaded`).

**Critical:** Must be `beforeEach`, not `beforeAll` — `beforeAll` reintroduces a dirty-DB-on-retry hazard under `retries: 2`.

```typescript
// Source: CONTEXT.md D-01; mirrors offline_storage.spec.ts addInitScript pattern
test.beforeEach(async ({ page }) => {
  await page.addInitScript(() => {
    // keep in sync with offline_study.js:3 (DB_NAME = 'crosswake_offline_study')
    indexedDB.deleteDatabase('crosswake_offline_study');
  });
});
```

### Pattern 2: Read-Only IndexedDB Observation (D-03c)

**What:** Wrap a `getAll` on the `mutations` store in a promise, return the first record. This is the established in-file pattern from `offline_study.js:123` (`getAllMutations`).

```typescript
// Source: CONTEXT.md D-03c; mirrors offline_study.js getAllMutations pattern
const mutationRecord = await page.evaluate(() => {
  return new Promise((resolve, reject) => {
    const req = indexedDB.open('crosswake_offline_study', 1); // OBSERVATION_ONLY
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
expect(mutationRecord).toHaveLength(1);
const { client_mutation_id: capturedId, card_id, rating } = mutationRecord[0];
```

### Pattern 3: Reconnect Trigger (D-03 — the critical fix)

**What:** Two-step reconnect: CDP transport back online, then explicitly dispatch the `online` event the app's listener is waiting for.

```typescript
// Source: CONTEXT.md D-03; research/SUMMARY.md "load-bearing gotcha"
await context.setOffline(false);
// page.dispatchEvent cannot target window — use page.evaluate exclusively
await page.evaluate(() => window.dispatchEvent(new Event('online'))); // OBSERVATION_ONLY (env simulation)
// D-03b: deterministic reconnect assertion before polling Ecto
await page.waitForResponse(r => r.url().includes('/study/sync') && r.status() === 200);
```

### Pattern 4: Scoped Ecto Count in SyncStateController (D-02)

**What:** Extend the existing `show/2` to also return a `count` scoped to the specific `client_mutation_id`. A bare `Repo.aggregate(ReviewEvent, :count, :id)` counts the whole table and returns > 1 in any multi-test run — this is the red-team-caught deterministic failure bug.

```elixir
# Source: CONTEXT.md D-02
import Ecto.Query, warn: false

def show(conn, %{"client_mutation_id" => id}) do
  case Repo.get_by(ReviewEvent, client_mutation_id: id) do
    nil ->
      json(conn, %{synced: false, count: 0})

    record ->
      count =
        from(r in ReviewEvent, where: r.client_mutation_id == ^id)
        |> Repo.aggregate(:count, :id)

      json(conn, %{synced: true, status: record.status, count: count})
  end
end
```

**Note:** `import Ecto.Query` must be added to the module — it is not currently present.

### Pattern 5: Duplicate-POST Idempotency Check (D-02b)

**What:** Fire a second POST with `page.request.post` (APIRequestContext, not `page.evaluate`) replaying the IndexedDB-read `capturedId`. `APIRequestContext` is unaffected by `context.setOffline`. The `:api` pipeline has no CSRF. Sequence: app flush completes → `synced: true` confirmed → THEN fire the duplicate.

```typescript
// Source: CONTEXT.md D-02b
// Sequence is load-bearing: app flush must complete first
await expect.poll(async () => {
  const res = await page.request.get(`/_e2e/sync-state/${capturedId}`);
  return res.ok() ? res.json() : { synced: false };
}, { timeout: 8000 }).toMatchObject({ synced: true });

// Duplicate POST — exercises on_conflict: :nothing
const dupRes = await page.request.post('/study/sync', {
  data: { events: [{ client_mutation_id: capturedId, card_id, rating }] }
});
expect(dupRes.ok()).toBe(true);
// Optional defense-in-depth: accepted_count is nested under .data
const dupData = await dupRes.json();
// dupData.data.accepted_count === 0 (on_conflict: :nothing held)

// Assert exactly one Ecto row
await expect.poll(async () => {
  const res = await page.request.get(`/_e2e/sync-state/${capturedId}`);
  return res.ok() ? res.json() : { count: -1 };
}, { timeout: 5000 }).toMatchObject({ count: 1 });
```

### Pattern 6: CI Compile Gate (D-04)

**What:** Insert after "Install Mix dependencies" (step 4 at YAML line 28–30) and before "Install dependencies" (step 5 at YAML line 32). `MIX_ENV=test` is mandatory — it compiles the `_e2e` route and `elixirc_paths(:test)` tree (the exact v6.0 break path a dev-env compile misses).

```yaml
# Source: CONTEXT.md D-04; insert after line 30 in offline-sync-e2e-gate.yml
      - name: Compile (warnings as errors)
        run: MIX_ENV=test mix compile --warnings-as-errors
        working-directory: examples/phoenix_host
```

### Pattern 7: Sibling Spec Fix (D-05)

| File | Line | Current (broken) | Fix |
|------|------|------------------|-----|
| `offline_storage.spec.ts` | 89 | `await page.click('#btn-pass');` | `await page.click('#btn-good');` |
| `offline_storage.spec.ts` | 92 | `text=Device storage limit reached! Cannot save more progress.` | Tighten to full string: `text=Device storage limit reached! Cannot save more progress. Please free up space on your device.` (recommended, not required) |

**Note:** The `#btn-pass` selector is dead after Phase 112's D-01 rename. This times out and makes the entire Playwright lane red. This fix is a hard prerequisite for E2E-04's "loud only for honest reasons" claim.

### Anti-Patterns to Avoid

- **State-writing `page.evaluate`:** Any `page.evaluate` that assigns to `window['crosswake_offline_mutations']` or calls `fetch(` is GUARD-01-caught and exactly what this phase eliminates.
- **`page.dispatchEvent` targeting `window`:** Playwright's selector-based `dispatchEvent` cannot target `window`; use `page.evaluate(() => window.dispatchEvent(...))` exclusively.
- **Bare `Repo.aggregate` (no `where`):** Counts the whole `review_events` table; returns > 1 in any multi-test run. Always scope: `from(r in ReviewEvent, where: r.client_mutation_id == ^id)`.
- **Asserting on a test-minted UUID before any IndexedDB read:** The test must read the `client_mutation_id` the app generated, not pre-mint one. Minting then asserting is GUARD-01 pattern 3.
- **Sequencing duplicate POST before original flush completes:** Must wait for `synced: true` on the first POST before firing the duplicate.
- **`MIX_ENV=dev mix compile`:** Misses the `_e2e` route and `test/support` — exactly the gap the compile gate must close.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Server-side idempotency | Custom dedup logic | Ecto `insert_all on_conflict: :nothing, conflict_target: :client_mutation_id` (already in `Study.sync_events/1`) | Already correct; touching it is out of scope |
| IndexedDB deletion before test | Custom browser context factory | `page.addInitScript(() => indexedDB.deleteDatabase('crosswake_offline_study'))` in `beforeEach` | Runs before page scripts; one line |
| Polling Ecto state | `waitForTimeout` + manual fetch | `expect.poll` with `page.request.get` | Respects timeout, gives clear failure message |
| Duplicate POST | `page.evaluate(() => fetch(...))` | `page.request.post(...)` (APIRequestContext) | Unaffected by `context.setOffline`; GUARD-01-safe |
| Reconnect simulation | `waitForTimeout(2000)` | `page.waitForResponse(...)` + `expect.poll` | Deterministic; no timing race |

---

## Live Tree Verification

> All code anchors from CONTEXT.md verified against the live tree on 2026-06-17.

### `offline_study.js` Anchors

| Claim | Verified Line | Status |
|-------|--------------|--------|
| `DB_NAME = 'crosswake_offline_study'` | :3 | CONFIRMED |
| `async function flushOutbox()` | :174 | CONFIRMED |
| `window.addEventListener('online', flushOutbox)` | :280 | CONFIRMED |
| On-load drain `flushOutbox()` (inside `setupEventListeners`) | :287 | CONFIRMED |
| Optimistic `flushOutbox()` when `navigator.onLine` | :308 | CONFIRMED |
| `async function handleReview(rating)` | :290 | CONFIRMED |
| `#btn-flip` event listener | :270 | CONFIRMED (note: :265 starts `setupEventListeners` second definition — `#btn-flip`/:btn-good`/#btn-hard` appear at :266–268 and :270–278) |
| `btnGood.addEventListener('click', () => handleReview('good'))` | :277 | CONFIRMED |
| `btnHard.addEventListener('click', () => handleReview('hard'))` | :278 | CONFIRMED |
| Response body: `data.data.accepted_records` (not top-level) | :211 | CONFIRMED — `(data.data && data.data.accepted_records)` |
| IndexedDB store name: `'mutations'` (`STORE_MUTATIONS`) | :6 | CONFIRMED |
| `keyPath: 'id', autoIncrement: true` (auto id is delete handle) | :72 | CONFIRMED |
| `getAllMutations()` promise-wrapper pattern | :123–134 | CONFIRMED — mirrors pattern to use in spec |

### `offline_storage.spec.ts` Anchors

| Claim | Verified Line | Status |
|-------|--------------|--------|
| Dead selector `#btn-pass` | :89 | CONFIRMED — `await page.click('#btn-pass')` |
| Text locator for storage error | :92 | CONFIRMED — `text=Device storage limit reached! Cannot save more progress.` (partial; full JS string is `...Please free up space on your device.`) |

**Actual full JS string** (from `offline_study.js:317`): `'Device storage limit reached! Cannot save more progress. Please free up space on your device.'` — the spec's substring locator passes today; tightening is honesty, not a hard fix.

### `sync_state_controller.ex` Anchors

| Claim | Verified | Status |
|-------|----------|--------|
| Existing `show/2` returns `%{synced: true, status: record.status}` | `offline_study.js:12–13` | CONFIRMED — no `count` field yet |
| `import Ecto.Query` NOT currently present | Verified by grep | CONFIRMED — must add when extending |
| `Repo`, `ReviewEvent` already aliased | Lines 4–5 | CONFIRMED |

### `offline-sync-e2e-gate.yml` Anchors

| Claim | Verified Line | Status |
|-------|--------------|--------|
| Job name: `e2e-offline-sync` | :11 | CONFIRMED — do NOT rename |
| "Install Mix dependencies" step | :28–30 | CONFIRMED — compile step inserts AFTER line 30 |
| "Install dependencies" (npm ci) | :32–34 | CONFIRMED — compile step inserts BEFORE line 32 |
| No `mix compile` step currently | Verified by grep | CONFIRMED — entirely absent |

### Router Anchors

| Claim | Verified Line | Status |
|-------|--------------|--------|
| `/_e2e/sync-state/:client_mutation_id` scoped to `Mix.env() in [:test, :e2e]` | :378–383 | CONFIRMED |
| Mounted under `:api` pipeline | :379 | CONFIRMED — no CSRF |

### Compile Gate Pre-Flight

**CRITICAL FINDING:** `MIX_ENV=test mix compile --warnings-as-errors` currently FAILS.

```
warning: CrosswakeExample.Flashcards.create_progress/1 is undefined or private. Did you mean:
  * upsert_progress/1
  └─ test/support/flashcards_fixtures.ex:47:38: CrosswakeExample.FlashcardsFixtures.progress_fixture/1

Compilation failed due to warnings while using the --warnings-as-errors option
```

**Root cause:** `test/support/flashcards_fixtures.ex:47` calls `CrosswakeExample.Flashcards.create_progress()` which was renamed to `upsert_progress/1` (the current function at `flashcards.ex:82`).

**Fix required (D-04b):** Change line 47 of `test/support/flashcards_fixtures.ex` from `.create_progress()` to `.upsert_progress()`. This is in-scope per D-04b ("fix any warnings so the gate lands green"). No other warnings were found in the compile output.

---

## Common Pitfalls

### Pitfall 1: `setOffline(false)` Does Not Fire `window 'online'`
**What goes wrong:** `flushOutbox` (bound at `offline_study.js:280`) never fires; the test hangs deterministically, burns all 3 retries.
**Root cause:** CDP `setOffline` toggles the network transport layer only; it does not dispatch DOM events.
**How to avoid:** Always follow `context.setOffline(false)` with `page.evaluate(() => window.dispatchEvent(new Event('online')))`.
**Warning signs:** Test times out after ~30s on every CI run regardless of retries.

### Pitfall 2: Bare `Repo.aggregate` Returns > 1 in Multi-Test Run
**What goes wrong:** A bare `Repo.aggregate(ReviewEvent, :count, :id)` counts ALL rows; with `workers: 1` and `retries: 2`, accumulated rows from prior tests or retries cause `count > 1` assertion failures.
**Root cause:** The `ReviewEvent` table accumulates rows across test runs within a session; only the Ecto DB is dropped/recreated between full `npx playwright test` invocations (via `webServer.command`), not between individual tests.
**How to avoid:** Scope to the id: `from(r in ReviewEvent, where: r.client_mutation_id == ^id) |> Repo.aggregate(:count, :id)`.
**Warning signs:** `count === 1` assertion fails even though `synced: true` — accumulated rows from other tests.

### Pitfall 3: `page.dispatchEvent` Cannot Target `window`
**What goes wrong:** `page.dispatchEvent('window', new Event('online'))` fails or is silently ignored — Playwright's `dispatchEvent` requires a CSS selector targeting a DOM element.
**How to avoid:** Use `page.evaluate(() => window.dispatchEvent(new Event('online')))` exclusively.

### Pitfall 4: Duplicate POST Before First Flush Completes
**What goes wrong:** If the duplicate POST fires before the app's own flush completes, there may be no row yet, and the `count === 1` assertion is meaningless (it could be 0 or 1 depending on timing).
**How to avoid:** Fully await `expect.poll ... synced: true` before firing the duplicate POST.

### Pitfall 5: Renaming the CI Job
**What goes wrong:** GitHub matches required status checks by exact job-name string. Renaming `e2e-offline-sync` now silently drops it from the future Phase 114 required-checks list.
**How to avoid:** Phase 113 does NOT rename the job. Phase 114 renames it and re-registers it as `merge-blocking-offline-sync-e2e`.

### Pitfall 6: `MIX_ENV=dev mix compile` in the Gate
**What goes wrong:** Dev env compile succeeds even when `test/support` has stale calls; the `_e2e` route is missing; `elixirc_paths(:test)` patterns are skipped.
**How to avoid:** Always `MIX_ENV=test mix compile --warnings-as-errors`.

### Pitfall 7: `data.data.accepted_count` vs `data.accepted_count`
**What goes wrong:** The sync response body nests under `data.data` (the Phoenix JSON wrapper), not at the top level. `response.data.accepted_count` is undefined.
**How to avoid:** Destructure as `(await dupRes.json()).data.accepted_count`.

---

## Code Examples

### Complete Spec Structure (the honest rewrite)

```typescript
// Source: CONTEXT.md D-03d, D-07; verified against offline_study.js live tree
import { test, expect } from '@playwright/test';

test.describe('Crosswake offline island: card rating queues in IndexedDB, reconnect flushes via app code, Ecto confirms exactly one review row', () => {
  test.beforeEach(async ({ page }) => {
    // D-01: delete IndexedDB BEFORE page scripts open it (addInitScript runs first)
    // keep in sync with offline_study.js:3 (DB_NAME = 'crosswake_offline_study')
    await page.addInitScript(() => {
      indexedDB.deleteDatabase('crosswake_offline_study');
    });
  });

  test('offline rating queues in IndexedDB, reconnect via app flush, Ecto confirms one row, duplicate is idempotent', async ({ page, context }) => {
    // Step 1: Navigate to the offline island
    await page.goto('/offline');

    // Step 2: Go offline at the network layer
    await context.setOffline(true);

    // Step 3: Queue a mutation via real UI (drives handleReview('good') → queueMutation)
    await page.click('#btn-flip');
    await page.click('#btn-good');

    // Step 4: Observe the queued record from IndexedDB (OBSERVATION_ONLY — no app state written)
    const mutations = await page.evaluate(() => { // OBSERVATION_ONLY
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
    expect(typeof capturedId).toBe('string');
    expect(capturedId).toMatch(/^[0-9a-f-]{36}$/); // app-generated UUID
    expect(rating).toBe('good');

    // Step 5: Reconnect — two-step: CDP transport + explicit 'online' event
    await context.setOffline(false);
    // page.dispatchEvent cannot target window; use page.evaluate
    await page.evaluate(() => window.dispatchEvent(new Event('online'))); // OBSERVATION_ONLY (env simulation)
    // D-03b: deterministic reconnect assertion (not retries)
    await page.waitForResponse(r => r.url().includes('/study/sync') && r.status() === 200);

    // Step 6: Server confirms exactly one row
    await expect.poll(async () => {
      const res = await page.request.get(`/_e2e/sync-state/${capturedId}`);
      return res.ok() ? res.json() : { synced: false };
    }, { timeout: 8000, message: 'Ecto row should reflect the flushed mutation' })
      .toMatchObject({ synced: true, count: 1 });

    // Step 7: Assert outbox is empty (app deleted the accepted record)
    const remaining = await page.evaluate(() => { // OBSERVATION_ONLY
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
    expect(remaining).toHaveLength(0);

    // Step 8: Duplicate flush — same client_mutation_id — assert exactly one Ecto row
    // page.request.post is APIRequestContext; unaffected by context.setOffline; :api pipeline has no CSRF
    const dupRes = await page.request.post('/study/sync', {
      data: { events: [{ client_mutation_id: capturedId, card_id, rating }] }
    });
    expect(dupRes.ok()).toBe(true);
    const dupBody = await dupRes.json();
    // accepted_count is nested under .data (Phoenix JSON wrapper)
    expect(dupBody.data.accepted_count).toBe(0); // on_conflict: :nothing held

    await expect.poll(async () => {
      const res = await page.request.get(`/_e2e/sync-state/${capturedId}`);
      return res.ok() ? res.json() : { count: -1 };
    }, { timeout: 5000 }).toMatchObject({ count: 1 }); // still exactly one row
  });
});
```

### Extended `SyncStateController` (D-02)

```elixir
# Source: CONTEXT.md D-02; verified against live sync_state_controller.ex
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

### CI Compile Gate (D-04)

```yaml
# Source: CONTEXT.md D-04
# Insert into .github/workflows/offline-sync-e2e-gate.yml
# AFTER "Install Mix dependencies" step (line 28–30)
# BEFORE "Install dependencies" (npm ci) step (line 32)

      - name: Compile (warnings as errors)
        run: MIX_ENV=test mix compile --warnings-as-errors
        working-directory: examples/phoenix_host
```

### Compile Warning Fix (D-04b — pre-flight, in-scope)

```elixir
# File: examples/phoenix_host/test/support/flashcards_fixtures.ex:47
# Change:
|> CrosswakeExample.Flashcards.create_progress()
# To:
|> CrosswakeExample.Flashcards.upsert_progress()
```

`CrosswakeExample.Flashcards.upsert_progress/1` is at `flashcards.ex:82`. This is the only warning found in the pre-flight run.

---

## Runtime State Inventory

> Omitted — Phase 113 is not a rename/refactor/migration phase. No runtime state is renamed.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | Compile gate pre-flight | ✓ | (project .tool-versions) | — |
| Node.js 20 | npm ci / Playwright | ✓ | 20 (CI setup-node) | — |
| PostgreSQL | Playwright webServer (`ecto.drop+create+migrate`) | ✓ | (project dev DB) | — |
| `@playwright/test` 1.60.0 | Spec execution | ✓ | Already in package.json | — |

**Missing dependencies with no fallback:** None.

**Note on CI:** `offline-sync-e2e-gate.yml` uses `erlef/setup-beam` with `version-file: .tool-versions` — the same toolchain as the local dev environment.

---

## Validation Architecture

> `nyquist_validation` is not explicitly false in `.planning/config.json` — this section is REQUIRED.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `@playwright/test` 1.60.0 |
| Config file | `examples/phoenix_host/playwright.config.ts` |
| Quick run command | `cd examples/phoenix_host && npx playwright test e2e/offline_sync.spec.ts` |
| Full suite command | `cd examples/phoenix_host && npx playwright test` |
| CI command | `npx playwright test` (from `examples/phoenix_host`, in `offline-sync-e2e-gate.yml`) |

### Phase Requirements → Test Map

| Req ID | Sub-clause | Behavior | Test Type | Command / Assertion | File Exists? |
|--------|------------|----------|-----------|---------------------|-------------|
| E2E-03a | Real UI click while offline queues via app code | `#btn-flip` + `#btn-good` → `handleReview('good')` → IndexedDB write | E2E | `npx playwright test e2e/offline_sync.spec.ts` — Step 3 | ❌ Wave 0 (rewrite) |
| E2E-03b | IndexedDB read asserts queued record + app-generated `client_mutation_id` | `page.evaluate` reads `mutations` store; asserts 1 record; UUID pattern matches | E2E | Same test, Step 4 | ❌ Wave 0 (rewrite) |
| E2E-03c | `setOffline(false)` + `dispatchEvent` triggers app's `flushOutbox` | `waitForResponse('/study/sync', 200)` confirms app reacted | E2E | Same test, Steps 5–5 | ❌ Wave 0 (rewrite) |
| E2E-03d | `expect.poll` on `/_e2e/sync-state/:id` confirms Ecto row | `{ synced: true }` returned from controller | E2E | Same test, Step 6 | ❌ Wave 0 (rewrite) |
| E2E-03e | Follow-up IndexedDB read confirms outbox empty | `mutations` store `getAll()` returns `[]` | E2E | Same test, Step 7 | ❌ Wave 0 (rewrite) |
| E2E-03f | Duplicate-flush case: same `client_mutation_id` twice → single Ecto row | `page.request.post` duplicate; `count === 1` poll | E2E | Same test, Step 8 | ❌ Wave 0 (rewrite) |
| E2E-04 | Compile gate runs before Playwright | `mix compile --warnings-as-errors` step exists AND precedes Playwright step in YAML | CI check | CI log order; can also verify locally: introduce deliberate compile error → confirm `mix compile` step fails before Playwright starts | ❌ Wave 0 (YAML edit) |

### Held-Out / Property / Backstop Checks

| Check | What Proves | How to Verify |
|-------|-------------|---------------|
| `count === 1` after duplicate POST | `on_conflict: :nothing` held; server did not insert a second row | `expect.poll` on `/_e2e/sync-state/:capturedId` returns `{ count: 1 }` |
| Outbox empty after flush (E2E-03e) | App deleted the accepted mutation from IndexedDB | `page.evaluate` `getAll` returns `[]` |
| `accepted_count === 0` on duplicate response | Server acknowledged the duplicate without creating a row | `(await dupRes.json()).data.accepted_count === 0` |
| `#btn-pass` gone (sibling spec fix) | Phase 112 rename is reflected in test | `npx playwright test e2e/offline_storage.spec.ts` runs green |
| Compile step order in YAML | Gate catches compile breaks before Playwright | Introduce deliberate compile error in `examples/phoenix_host/lib/`; confirm CI fails on compile step, not Playwright step |
| `window.liveSocket` is falsy (D-06, recommended) | `/offline` is a socketless island | `page.evaluate(() => !!window.liveSocket)` returns `false` |

### Sampling Rate

- **Per task commit:** `cd examples/phoenix_host && npx playwright test e2e/offline_sync.spec.ts` (quick — single spec)
- **Per wave merge:** `cd examples/phoenix_host && npx playwright test` (full suite — both E2E specs)
- **Phase gate:** Full suite green + manual CI run green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `examples/phoenix_host/e2e/offline_sync.spec.ts` — full rewrite (E2E-03 a–f)
- [ ] `examples/phoenix_host/e2e/offline_storage.spec.ts:89` — `#btn-pass` → `#btn-good` (collateral; D-05)
- [ ] `examples/phoenix_host/lib/crosswake_example/e2e/sync_state_controller.ex` — add `count` field + `@moduledoc` (D-02)
- [ ] `examples/phoenix_host/test/support/flashcards_fixtures.ex:47` — `create_progress` → `upsert_progress` (D-04b pre-flight)
- [ ] `.github/workflows/offline-sync-e2e-gate.yml` — insert compile step (D-04)

---

## Security Domain

> No new authentication, session, or cryptographic surfaces are added. The `/_e2e/sync-state/:id` endpoint extension (adding a `count` field) is already behind the `Mix.env() in [:test, :e2e]` compile-time gate (router.ex:378). No ASVS categories are newly implicated.

| ASVS Category | Applies | Control |
|---------------|---------|---------|
| V5 Input Validation | Yes (test endpoint) | `client_mutation_id` is bound as a named param; Ecto query parameterizes it — no injection surface |
| All others | No | Phase adds no auth, session, crypto, or new public routes |

---

## Assumptions Log

No claims in this research are tagged `[ASSUMED]`. All findings are either:
- Verified directly against the live source tree (code anchors), or
- Cited from CONTEXT.md decisions (D-01..D-07) which were themselves produced by two waves of multi-agent research and a red-team pass.

**If this table is empty:** All claims in this research were verified or cited — no user confirmation needed.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | — | — | — |

---

## Open Questions

1. **D-06 socketless-boundary assertion**
   - What we know: `/offline` uses `put_root_layout(false)` (confirmed at `offline_controller.ex:22`); `window.liveSocket` is not defined in `offline_study.js` or the offline HEEx template (grep confirms no reference)
   - What's unclear: whether `page.evaluate(() => !!window.liveSocket)` returns `false` reliably in the Playwright Chromium context (it should, as the app JS doesn't define it)
   - Recommendation: include D-06 — it is a one-liner, the grep confirms no `liveSocket` in the offline island, and it documents the architectural boundary the whole proof exists to demonstrate.

2. **`DB_NAME` export vs inline string**
   - What we know: CONTEXT.md flags this as executor discretion (D-01)
   - What's unclear: whether `offline_study.js` is served as a plain static file (no bundler) or via an import pipeline that supports named exports
   - Finding: `offline_study.js` is served via `<script type="module">` (offline HEEx line 93) — ES module `export` is supported. However, the spec would need an `import` from the static path, which requires knowing the served URL. A comment is simpler.
   - Recommendation: use a `// keep in sync with offline_study.js:3` comment in the spec rather than a cross-file import, unless the executor prefers the import.

---

## State of the Art

| Old Approach (what `offline_sync.spec.ts` currently does) | Current Approach (what Phase 113 ships) |
|-------------------------------------------------------------|----------------------------------------|
| `page.evaluate` writes to `window['crosswake_offline_mutations']` | `page.click('#btn-flip')` + `page.click('#btn-good')` drives real `handleReview` |
| Test-minted `randomUUID()` injected before any app code runs | App-generated UUID read back from IndexedDB after app code runs |
| `page.evaluate(() => fetch('/study/sync', ...))` manually fires the sync | `page.evaluate(() => window.dispatchEvent(new Event('online')))` lets the app's bound listener fire `flushOutbox` |
| `waitForRequest` (request-level intercept, brittle) | `waitForResponse` + `expect.poll` (response-confirmed, deterministic) |
| No `count` assertion (could be any number of rows) | `count === 1` scoped to `client_mutation_id` (duplicate-flush proof) |
| No `beforeEach` IndexedDB reset | `beforeEach` `addInitScript(deleteDatabase)` (isolation) |
| No `mix compile` before Playwright in CI | `MIX_ENV=test mix compile --warnings-as-errors` as a named step before npm/Playwright |

---

## Sources

### Primary (HIGH confidence)

- Live source tree verification (this session): `offline_study.js`, `offline_storage.spec.ts`, `offline_sync.spec.ts`, `sync_state_controller.ex`, `offline-sync-e2e-gate.yml`, `router.ex:378–383`, `playwright.config.ts`, `flashcards.ex`, `flashcards_fixtures.ex` — all verified by direct file read and grep
- CONTEXT.md D-01..D-07 — produced by two waves of parallel deep-research agents + red-team, embedded in this phase's planning artifact
- `MIX_ENV=test mix compile --warnings-as-errors` pre-flight run (this session) — surfaced the `create_progress` → `upsert_progress` warning

### Secondary (MEDIUM confidence)

- `research/SUMMARY.md` — milestone-level research synthesis (load-bearing `setOffline` gotcha, reconnect determinism, architecture approach)
- `research/PITFALLS.md` — pitfalls 1–5 (injection, setOffline, IndexedDB isolation, compile gate, job rename)
- `research/ADOPTION-PROOF-STRATEGY.md` — socketless-island adoption thesis (D-06 rationale)

---

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no new packages; all Playwright APIs verified in use
- Architecture: HIGH — all code anchors verified against live tree
- Pitfalls: HIGH — two red-team-caught bugs (bare aggregate, missing `online` dispatch) folded into locked decisions
- Pre-flight compile warning: HIGH — reproduced live in this session

**Research date:** 2026-06-17
**Valid until:** Stable (no external dependencies); re-verify if Phase 112's files are further modified before Phase 113 executes.

---

## RESEARCH COMPLETE
