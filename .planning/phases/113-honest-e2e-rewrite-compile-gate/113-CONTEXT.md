# Phase 113: Honest E2E Rewrite + Compile Gate - Context

**Gathered:** 2026-06-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Rewrite the structurally-fraudulent `examples/phoenix_host/e2e/offline_sync.spec.ts` so it proves the full **offline → reconnect → reconcile** loop using **only the app's own code paths** (no `page.evaluate` that writes app state or invokes app-owned behavior), and add a **loud compile gate** to the CI workflow so a demo-app compile break fails as a compile error instead of masquerading as a Playwright port-connection timeout (the v6.0 failure mode).

**Change surface (the honest list):**
1. `examples/phoenix_host/e2e/offline_sync.spec.ts` — full rewrite (the fraud → the honest loop on `/offline`).
2. `examples/phoenix_host/lib/crosswake_example/e2e/sync_state_controller.ex` — extend the existing `/_e2e/sync-state/:id` to also return a **scoped** `count`; add a test-only `@moduledoc` (pre-stages Phase 114 GUARD-02).
3. `.github/workflows/phase90-proof.yml` — add a `MIX_ENV=test mix compile --warnings-as-errors` step before the Playwright step.
4. `examples/phoenix_host/e2e/offline_storage.spec.ts` — fix the two lines Phase 112's button rename left stale (collateral; the whole Playwright lane is red without it).
5. (Optional, drift-proofing) `examples/phoenix_host/priv/static/offline_study.js` — `export` the `DB_NAME` constant so the spec can import it instead of hardcoding the string.

**The server-side sync/reconciliation is already correct and is NOT changed** (`Study.sync_events/1` — idempotent `insert_all` `on_conflict: :nothing, conflict_target: :client_mutation_id`; `SyncController`). The `/_e2e/sync-state/:id` endpoint already exists and is already `:test`/`:e2e`-gated — Phase 113 only *adds a field* to it.

**Maps to requirements:** E2E-03 (honest test), E2E-04 (compile gate). **GATE/GUARD enforcement is Phase 114; closeout/ledger/doc-truth is Phase 115 — not this phase.**

### Locked upstream — DO NOT re-open in planning
Fixed by REQUIREMENTS.md (E2E-03/04, GUARD-01/02) + v12.0 research + Phase 112's shipped app. Settled inputs:
- **Test target = `/offline`** (the socketless island where Phase 112's real outbox lives). The old fraud hit `/study/session` — wrong page.
- **Reconnect is driven by the browser `window 'online'` event.** The app binds `window.addEventListener('online', flushOutbox)` (`offline_study.js:280`). `context.setOffline(false)` does **NOT** dispatch `window 'online'` (CDP only toggles the transport) — so the test MUST explicitly dispatch it (see D-03). This is locked in STATE.md and `research/SUMMARY.md`.
- **The app-generated `client_mutation_id` is observed from IndexedDB, never test-minted** (E2E-03b). A test-minted UUID asserted before any IndexedDB read is a GUARD-01 anti-pattern.
- **Compile gate runs `mix compile --warnings-as-errors` in `examples/phoenix_host` BEFORE Playwright** (E2E-04).
- **Phase 113 does not rename or restructure the CI job** — Phase 114 (GATE-01) renames it to `merge-blocking-offline-sync-e2e` and registers it as a required check. Renaming early would silently drop it from any future required-checks list (GitHub matches by exact job-name string).
- **The honesty boundary:** `page.evaluate` is permitted ONLY for (a) read-only IndexedDB **observation** and (b) dispatching the `window 'online'` **environment event**. Any `page.evaluate` that writes app state, invokes app-owned behavior, or calls `fetch(` is forbidden and is exactly what Phase 114's GUARD-01 will scan for.

</domain>

<decisions>
## Implementation Decisions

Resolved by two waves of parallel deep research (4 advisor agents on idiom/footguns/DX, then 2 agents on project-DNA/JTBD coherence + an adversarial SWE/DevOps/SRE red-team). All converge on the **honest / minimal / app-driven** option, coherent with the v12.0 "every green check proves what it claims" thesis. The red-team caught two deterministic-failure bugs (D-02 unscoped count, D-03 missing `online` dispatch) now folded in. Full research in `113-DISCUSSION-LOG.md`.

### Test isolation (IndexedDB + Ecto)
- **D-01:** `test.beforeEach` runs `await page.addInitScript(() => indexedDB.deleteDatabase('crosswake_offline_study'))` so each test starts with an empty outbox (satisfies E2E-03 "resets IndexedDB via `beforeEach`"). `addInitScript` runs **before** the page's scripts (the app opens the DB on `DOMContentLoaded`), so the delete is not blocked by an open connection — order is delete-then-navigate. **Must be `beforeEach`, never `beforeAll`** (a `beforeAll` reintroduces a dirty-DB-on-retry hazard under `retries: 2`).
  - DB name **verified** = `offline_study.js:3` `const DB_NAME = 'crosswake_offline_study'`. To prevent silent isolation drift (a wrong name makes the delete a no-op — the exact false-green class this milestone kills), prefer **`export`ing `DB_NAME` and importing it in the spec** over a hardcoded literal; if hardcoded, add a `// keep in sync with offline_study.js:3` comment. Executor discretion.
- **D-01b (Ecto isolation):** **No reset endpoint, no `SQL.Sandbox`.** Sandbox-over-HTTP is architecturally impossible here — the app's own `fetch('/study/sync')` cannot carry a sandbox token without `addInitScript` injection, which would itself be the dishonesty v12.0 exists to eliminate. The webServer already `ecto.drop + create + migrate` once at boot; each test keys every assertion on its own app-generated `client_mutation_id`, so accumulated rows are invisible noise. `retries: 2` is safe: a failed attempt never flushed (no Ecto row) and `beforeEach` re-wipes IndexedDB, and a fresh UUID is generated on the retry click.

### "Exactly one Ecto row" proof (E2E-03f)
- **D-02:** Extend the **existing** `GET /_e2e/sync-state/:client_mutation_id` to also return `count`. **It MUST be scoped to the id** — a bare table aggregate counts cross-test rows and returns > 1:
  ```elixir
  count =
    from(r in ReviewEvent, where: r.client_mutation_id == ^id)
    |> Repo.aggregate(:count, :id)
  json(conn, %{synced: synced, status: status, count: count})
  ```
  Add `@moduledoc` stating the endpoint is test-only and mounted only under `:test`/`:e2e` (pre-stages GUARD-02; one endpoint only, GUARD-02 surface unchanged).
- **D-02b (duplicate-POST mechanism + sequence):** Issue the duplicate via Playwright **`page.request.post('/study/sync', { data: { events: [{ client_mutation_id: capturedId, card_id, rating }] } })`** — an `APIRequestContext` call (NOT `page.evaluate`; unaffected by `context.setOffline`; the `:api` pipeline has no CSRF), replaying the **IndexedDB-read app-generated** `capturedId`. This exercises the server's `on_conflict: :nothing` idempotency directly and trips none of GUARD-01's three patterns. **Sequencing is load-bearing:** (1) let the app's own flush run and `expect.poll` `synced: true`, THEN (2) fire the duplicate POST, THEN (3) `expect.poll` `count === 1`. Optional defense-in-depth: assert `data.accepted_count === 0` on the duplicate response (note the value is nested under `.data`).

### The honest rewrite + the reconnect trigger (E2E-03 a–e)
- **D-03 (reconnect trigger — the critical fix):** After `await context.setOffline(false)`, the test MUST do
  ```ts
  await page.evaluate(() => window.dispatchEvent(new Event('online')));
  ```
  Without it the app's `flushOutbox` (bound to `window 'online'` at `offline_study.js:280`) **never fires** and the test times out deterministically on every run, burning all three retries. `page.dispatchEvent` (the selector-based Playwright method) **cannot target `window`** — use `page.evaluate` exclusively for this.
  - **Honesty classification (carry into Phase 114 GUARD-01):** this single `page.evaluate` is **environment simulation** — it replicates the OS-level connectivity event a real browser fires on reconnect. It writes no app state, touches no `window['crosswake_offline_mutations']`, and calls no `fetch(`; the app's `flushOutbox` *reacting* to it IS the code path under test. It is **permitted** by E2E-03(a) and **required** by E2E-03 + `research/SUMMARY.md`. GUARD-01 must whitelist `dispatchEvent(new Event('online'))` and only flag `page.evaluate` that writes app state or calls `fetch(`.
- **D-03b (deterministic reconnect assertion — closes PITFALLS Pitfall 2):** Between the `online` dispatch and the Ecto poll, add `await page.waitForResponse(r => r.url().includes('/study/sync') && r.status() === 200)`. This proves the app actually reacted, instead of leaning on `retries: 2` to paper over a timing race.
- **D-03c (`page.evaluate` boundary):** Permitted — read-only IndexedDB **observation** (extract the app id; assert the outbox is empty per E2E-03e) and the `online` dispatch above. Forbidden / GUARD-01-caught — any `page.evaluate` that writes app state, invokes the app's flush directly, or calls `fetch(`; `window['crosswake_offline_mutations']`; a test-minted UUID asserted before any IndexedDB read.
- **D-03d (full flow):** `goto /offline` → `context.setOffline(true)` → real UI: `click('#btn-flip')` then `click('#btn-good')` (drives `handleReview('good')`) → read IndexedDB `mutations` store, observe app-generated `{client_mutation_id, card_id, rating}` → `context.setOffline(false)` + `page.evaluate` dispatch `online` → `waitForResponse('/study/sync', 200)` → `expect.poll('/_e2e/sync-state/:id')` `synced: true` → read IndexedDB, assert outbox empty (E2E-03e) → duplicate case (D-02b).

### Compile gate (E2E-04)
- **D-04:** Insert this step into `phase90-proof.yml` **after** "Install Mix dependencies" and **before** the npm/Playwright steps:
  ```yaml
  - name: Compile (warnings as errors)
    run: MIX_ENV=test mix compile --warnings-as-errors
    working-directory: examples/phoenix_host
  ```
  `MIX_ENV=test` is **mandatory** — it compiles the same tree the webServer boots, including the `if Mix.env() in [:test, :e2e]` `_e2e` route and `elixirc_paths(:test)`/`test/support` (exactly the v6.0 break path a dev-env compile would miss). `--warnings-as-errors` only flags the demo's own code **plus the path-dep parent lib** (`{:crosswake, path: "../.."}` compiles as application code) — NOT hex deps.
- **D-04b (pre-flight, in-scope):** Before wiring the step, run `cd examples/phoenix_host && MIX_ENV=test mix compile --warnings-as-errors` locally and fix any warnings (demo app **and** parent lib) so the gate lands green — a gate born red provides no value. Do **not** rename/restructure the job (Phase 114).

### Sibling-spec hygiene (collateral, in-scope)
- **D-05:** `offline_storage.spec.ts:89` `#btn-pass` → `#btn-good` (**hard fix** — Phase 112's D-01 rename left a dead selector; the click times out and the whole Playwright lane is red today, which would block E2E-04's "loud only for honest reasons" and Phase 114's required green run). `#btn-good` verified at `index.html.heex:87` / `offline_study.js:277`. `offline_storage.spec.ts:92` — extend the text locator to the full current string (`…Please free up space on your device.`); this passes today by substring match, so it's an **honesty tightening** (closes a lie-by-omission), recommended not required. **No app code, no `data-testid`** (touching the HEEx triggers render-verify/brand-token churn = scope creep; defer). TODO-001 (FlashcardsTest field drift + flaky `Chimeway.RegistryNotificationOpenTest`) is a `mix test` concern, NOT Playwright — stays Phase 115.

### Adoption-proof boundary assertion (recommended; beyond literal E2E-03 a–f)
- **D-06 (recommended, executor/planner discretion):** Add one observation-only assertion that the `/offline` island is **socketless** — e.g. `expect(await page.evaluate(() => !!window.liveSocket)).toBe(false)`. `research/ADOPTION-PROOF-STRATEGY.md` names this the *primary* adoption claim ("the deck selection is LiveView, but the study loop is an Offline Island running locally without WebSocket dependency"). The current E2E-03(a–f) proves the sync mechanics are real but does not prove the architectural boundary the proof exists to demonstrate. Low cost, high teaching value; include unless the socket-detection surface proves awkward, in which case defer to a follow-up. Stays observation-only (no app behavior invoked).

### Claude's Discretion — test-as-documentation DX (in-scope, no creep)
- **D-07:** Make the rewritten spec read as an exemplary teaching artifact for adopters (an E2E test doubles as the canonical "how offline sync works" doc): step-labeled comment blocks (Step 1 queue → 2 observe id → 3 reconnect via app code → 4 server confirms one row → 5 outbox drained → 6 duplicate idempotent); a precise `describe`/test name ("Crosswake offline island: card rating queues in IndexedDB, reconnect flushes via app code, Ecto confirms exactly one review row"); and a `// OBSERVATION_ONLY` comment on every surviving `page.evaluate` read (eases Phase 114's GUARD-01 scan). IndexedDB read plumbing (cursor vs getAll) — mirror the in-file promise-wrapped tx helpers.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & milestone research (LOCKED inputs)
- `.planning/REQUIREMENTS.md` — E2E-03, E2E-04 (this phase); GUARD-01/02 wording (Phase 114, but D-02/D-03 must stay compatible)
- `.planning/research/SUMMARY.md` — the load-bearing `setOffline(false)` does-NOT-fire-`online` gotcha; required `page.evaluate(() => window.dispatchEvent(new Event('online')))`; observation-vs-injection line; `waitForResponse` reconnect determinism
- `.planning/research/PITFALLS.md` — Pitfall 1 (no state-writing `page.evaluate`), Pitfall 2 (deterministic reconnect assertion, not retries), Pitfall 3 (`beforeEach` IndexedDB delete), Pitfall 4 (compile gate ordering), Pitfall 5 (don't rename the job — drops it from required checks)
- `.planning/research/ADOPTION-PROOF-STRATEGY.md` — why the proof must demonstrate the Offline-Island socketless boundary (D-06), not just sync mechanics
- `.planning/research/JTBD-AND-USER-FLOWS.md` — "my offline progress is safe and syncs when I'm back" trust JTBD; "one real offline workflow without claiming app-wide sync"
- `.planning/phases/112-real-offline-outbox-flush/112-CONTEXT.md` — what Phase 112 shipped (button rename, payload shape, three flush triggers, status microcopy) — the app the test now exercises

### Demo-app change surface
- `examples/phoenix_host/e2e/offline_sync.spec.ts` — the fraud to rewrite (injects `window['crosswake_offline_mutations']`, manual `fetch`, test-minted UUID, wrong route `/study/session`)
- `examples/phoenix_host/e2e/offline_storage.spec.ts` — sibling spec; fix lines 89 (`#btn-pass`→`#btn-good`) + 92 (full text) (D-05)
- `examples/phoenix_host/priv/static/offline_study.js` — the app under test: `DB_NAME` (:3, store `mutations`), `flushOutbox` (:174), `window 'online'` listener (:280), on-load drain (:287), optimistic `navigator.onLine` flush (:307), `handleReview` (:290), buttons `#btn-flip`/`#btn-good`/`#btn-hard` (:277-278). Optionally `export DB_NAME` (D-01)
- `examples/phoenix_host/lib/crosswake_example/e2e/sync_state_controller.ex` — extend with scoped `count` + test-only `@moduledoc` (D-02)
- `examples/phoenix_host/lib/crosswake_example/local_first/study.ex` — `sync_events/1` returns `%{accepted_count, accepted_records, rejected}`; `insert_all on_conflict: :nothing, conflict_target: :client_mutation_id` (DO NOT change)
- `examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex` — `POST /study/sync`, body `{"events":[…]}`, 200 `%{data: result}` (DO NOT change)
- `examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex` — `rating ∈ {"good","hard"}`, `card_id` integer, `client_mutation_id` unique (DO NOT change)
- `examples/phoenix_host/lib/crosswake_example/router.ex` — `/offline`, `/study/sync` (`:api`), `/_e2e/sync-state/:client_mutation_id` (mounted `if Mix.env() in [:test, :e2e]`, lines ~378-383)
- `examples/phoenix_host/playwright.config.ts` — webServer boots `MIX_ENV=test mix do ecto.drop+create+migrate + phx.server` on :4002; `workers: 1`, `retries: 2` (CI), `serviceWorkers: 'block'`
- `.github/workflows/phase90-proof.yml` — single job `e2e-offline-sync`; add the compile step after "Install Mix dependencies" (D-04). Do NOT rename the job (Phase 114)

### Project DNA / vision (coherence inputs)
- `prompts/crosswake-elixir-oss-dna.md` — "install truth is product truth"; deterministic host-app proof lane from the same public path users adopt
- `prompts/elixir-mobile-offlinesupport-stresstest-deep-research.md` / `…-flashcard-app-…` — append-only review-event + idempotency-key dedup model the test demonstrates

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `/_e2e/sync-state/:client_mutation_id` already exists and is already `:test`/`:e2e`-gated — Phase 113 only *adds a scoped `count` field* + a `@moduledoc`; no new route, no new endpoint (keeps GUARD-02's Phase-114 surface a single endpoint).
- The app already owns the entire offline→flush path (`queueMutation`, `flushOutbox`, three reconnect triggers, status line) from Phase 112 — the test only drives the real UI and observes; it injects nothing.
- `offline_storage.spec.ts` is the established in-repo Playwright pattern (`addInitScript`, `page.goto('/offline')`, `serviceWorkers: 'block'`) — mirror it.
- Server `Study.sync_events/1` + `SyncController` are already idempotent and correct — `on_conflict: :nothing` is what makes the duplicate-flush assert exactly one row.

### Established Patterns
- Test-only surface via compile-time `if Mix.env() in [:test, :e2e]` (not a runtime check) — the idiomatic Phoenix pattern; the `_e2e` scope already uses it.
- Playwright `APIRequestContext` (`page.request.*`) for server-contract assertions vs `page.evaluate` for in-page behavior — the observation/injection line.

### Integration Points
- `context.setOffline(false)` → `page.evaluate(dispatch 'online')` → app `flushOutbox` → `waitForResponse('/study/sync', 200)` → `expect.poll('/_e2e/sync-state/:id')`.
- Duplicate POST (`page.request.post('/study/sync')`) is unaffected by `context.setOffline` (CDP offline emulation does not block `APIRequestContext`).
- Compile gate compiles the parent lib path-dep too (`{:crosswake, path: "../.."}`) — parent must be warnings-clean for the gate to land green.

### Footguns (verified by red-team)
- Bare `Repo.aggregate(ReviewEvent, :count, :id)` (no `where`) counts the whole table → > 1 in any multi-test run. Scope it to the id.
- `context.setOffline(false)` does not fire `window 'online'` → flush hangs deterministically without the explicit dispatch.
- `page.dispatchEvent` cannot target `window`; use `page.evaluate`.
- `data.accepted_count` is nested under `.data`, not top-level — destructure before asserting.
- Sequence the duplicate POST AFTER `synced: true`, so the original goes through the app's real path first.

</code_context>

<specifics>
## Specific Ideas

- User asked (twice, emphatically) for deep multi-subagent research per decision: pros/cons/tradeoffs, idiomatic Elixir/Plug/Ecto/Phoenix + Playwright fit, lessons from comparable libs/apps cross-ecosystem (right and wrong), DX, footguns, principle-of-least-surprise, SWE/architecture/DevOps/SRE lenses, and coherence with the project's own `prompts/`+`research/` vision — "one-shot a perfect coherent set so I don't have to think."
- Comparable-system lessons that shaped the calls: Stripe idempotency-key testing (replay same key, assert no new charge) and WatermelonDB/Replicache/ElectricSQL push tests (assert the data store, not the response) → assert the DB row `count`, not just `accepted_count`. Playwright team guidance → `APIRequestContext` for server postconditions, `page.evaluate` for in-page observation only. PITFALLS/SUMMARY (project's own scar tissue) → the `online`-event and compile-gate fixes are the two footguns the project already bled on (v6.0).

</specifics>

<deferred>
## Deferred Ideas

- **`data-testid` selector convention** — replacing CSS-ID selectors with `data-testid` across the offline HEEx is a durable drift-prevention investment, but it touches app HTML (render-verify + brand-token churn) and is broader than E2E-03/04. Defer to a dedicated hygiene pass or Phase 115.
- **TODO-001** (`FlashcardsTest` field-name drift + flaky `Chimeway.RegistryNotificationOpenTest`) — a `mix test` concern, not Playwright; out of scope here, slated for Phase 115 (DEBT-01) or standalone cleanup.
- **D-06 boundary assertion** — recommended in-scope, but if the LiveView-socket-absence detection surface is awkward, it may be deferred to a follow-up without blocking E2E-03's literal a–f criteria.

</deferred>

---

*Phase: 113-honest-e2e-rewrite-compile-gate*
*Context gathered: 2026-06-17*
