# Stack Research

**Domain:** CI/test hardening — real browser E2E for IndexedDB-outbox reconnect flush, merge-blocking GitHub Actions required status check
**Researched:** 2026-06-17
**Confidence:** HIGH (Playwright APIs verified against official docs; GitHub branch protection state verified via live `gh api` call against the repo)

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `@playwright/test` | 1.60.0 (current lockfile) | Drive the browser, emulate offline/online transitions, wait for real network activity, assert against backend | Already installed and used. `setOffline`, `waitForResponse`, `expect.poll`, and `page.evaluate` to fire `window` events are all available at this version. No upgrade needed. |
| `context.setOffline(bool)` | Playwright API (added before v1.9) | Block/unblock all HTTP(S) requests for the browser context via CDP `Network.emulateNetworkConditions` | The correct tool for network-level offline emulation. Requests fail when offline; they succeed when online. Already used correctly in the existing spec. |
| `page.evaluate(() => window.dispatchEvent(new Event('online')))` | Standard DOM API via Playwright | Fire the browser `online` connectivity event that `offline_study.js` must listen on to trigger the outbox flush | Critical gap: `context.setOffline(false)` does NOT automatically fire `window`'s `online`/`offline` events. The app's reconnect listener will never run without an explicit `dispatchEvent`. This is a documented Playwright behavior (confirmed via official docs). The test must call `setOffline(false)` + `dispatchEvent(new Event('online'))` in sequence. |
| `page.waitForResponse(predicate)` | Playwright API | Await the real `/study/sync` POST that the app fires autonomously after the `online` event | Set up the promise BEFORE dispatching the `online` event so no race condition. Use a predicate: `res => res.url().includes('/study/sync') && res.request().method() === 'POST'`. This waits for the app-driven network call — not a manually injected fetch. |
| `expect.poll(fn, opts)` | Playwright assertion API | Poll `/_e2e/sync-state/:id` until `{ synced: true }` — the Ecto-backed truth check | Already used in the spec. Adequate for the assertion tier. Tune `timeout` to ~8000ms with default intervals `[100, 250, 500, 1000]` to handle Phoenix startup jitter in CI. |
| GitHub branch protection `checks` API | `PATCH /repos/{owner}/{repo}/branches/{branch}/protection/required_status_checks` | Declare a workflow job as a required status check so merging to `main` is blocked until it passes | Already used in the repo for `merge-blocking rulestead proof (hermetic)` and `brand-structural`. The mechanism is live and proven — just add the new job name. Use `gh api` to add the check (see pattern below). |

### Supporting Tools / Actions

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `page.addInitScript(fn)` | Playwright API | Override `navigator.onLine` before navigation so the app correctly reads `false` while offline | Use this to add a page-level override of `navigator.onLine` to return `false` before the offline study session starts, complementing `context.setOffline(true)`. Without this, the app's `if (navigator.onLine)` guards see stale `true` even after `setOffline(true)`. Remove the override (or set to `true`) before dispatching the `online` event. |
| `Object.defineProperty(navigator, 'onLine', { get: () => false })` | Standard JS (via `page.evaluate`) | Synchronously update `navigator.onLine` mid-test when transitioning from online→offline mid-session | Use inside `page.evaluate` after navigation when you need to toggle `onLine` during an already-loaded page rather than before load. `addInitScript` sets the value before DOMContentLoaded; `evaluate` patches it after. |
| `trace: 'on-first-retry'` | Already in `playwright.config.ts` | Capture trace on CI failures for diagnosis | Already correctly configured. No change needed. |
| `retries: 2` (in CI) | Already in `playwright.config.ts` | Allow one transient CI flake before failing | Already correctly configured. The `waitForResponse`-based approach will be more deterministic than the current injected-fetch approach, so flakes should decrease. |
| `gh api` (GitHub CLI) | CLI tool in CI environment | Add a new required status check to branch protection without a UI step | Idiomatic for codifying the protection in a one-time runbook step. The existing protection uses the `checks` array (not deprecated `contexts`). |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `offline_study.js` — `window.addEventListener('online', flushOutbox)` | The reconnect flush that does not yet exist | This is not a tooling addition — it is the primary app change. The E2E test can only drive a real flush if the app fires one. Must: read all pending mutations from the `mutations` IndexedDB store, POST them to `/study/sync`, clear the store on success. The test then drives this naturally by dispatching `new Event('online')`. |
| `playwright.config.ts` — no changes needed | Server startup, retry, trace config are already correct | The `webServer` block correctly boots Phoenix with `MIX_ENV=test` and fresh DB migrations. The `serviceWorkers: 'block'` setting prevents SW caching from masking results. No config changes needed for v12.0. |
| `offline-sync-e2e-gate.yml` — rename job to `merge-blocking-*` | Make the E2E job name match the repo's merge-blocking naming convention | Current job name is `e2e-offline-sync`. Required status checks are matched by job `name:` string. The job must be renamed (e.g. `merge-blocking-offline-sync-proof`) and that string added to branch protection. |

---

## The Core Gap and Its Fix (plain language)

**What the current spec does (dishonest):**

1. Calls `context.setOffline(true)` — correctly blocks HTTP.
2. Injects directly into `window['crosswake_offline_mutations']` — a scratch variable the app does not use. `offline_study.js` writes to IndexedDB; it does not use this variable.
3. Manually calls `fetch('/study/sync', ...)` from inside `page.evaluate` — bypasses the app's reconnect path entirely.
4. Calls `context.setOffline(false)` — re-enables HTTP but does not fire `window`'s `online` event, so the app never knows it reconnected.

**What the honest spec must do:**

1. `context.setOffline(true)` + `page.evaluate(() => window.dispatchEvent(new Event('offline')))` — blocks HTTP and fires the offline event so `navigator.onLine` guards behave correctly.
2. Click the flashcard UI (Pass/Fail button) — causes `offline_study.js`'s `handleReview()` to call `queueMutation()`, which writes to the IndexedDB `mutations` store.
3. Set up `page.waitForResponse(res => res.url().includes('/study/sync') && res.request().method() === 'POST')` promise — must be created before going online.
4. `context.setOffline(false)` + `page.evaluate(() => window.dispatchEvent(new Event('online')))` — re-enables HTTP and fires the `online` event.
5. `offline_study.js`'s new `window.addEventListener('online', flushOutbox)` handler fires autonomously — reads from IndexedDB, POSTs to `/study/sync`.
6. `await syncResponsePromise` — awaits the real app-driven POST.
7. `expect.poll(...)` against `/_e2e/sync-state/:id` — asserts Ecto inserted the row.

**App-side change required:** Add a `flushOutbox()` function and `window.addEventListener('online', flushOutbox)` to `offline_study.js`. The function must read all records from the `mutations` store, POST them to `/study/sync` with the correct payload shape (`{ events: [{ client_mutation_id, card_id, rating }] }`), and clear the store on success. The ReviewEvent changeset requires `client_mutation_id` (string), `card_id` (integer), `rating` ("good" or "hard") — so the mutation stored by `queueMutation` must include those fields or be transformed at flush time.

**Payload shape mismatch to fix:** The current `queueMutation` call stores `{ type: 'REVIEW_CARD', payload: { cardId, result, timestamp } }`. The `/study/sync` endpoint requires `{ client_mutation_id, card_id, rating }`. Either `queueMutation` must store the right shape directly, or `flushOutbox` must transform it. Storing the correct shape directly is simpler.

---

## GitHub Branch Protection — Adding the New Required Check

The repo uses the classic branch protection API (no rulesets). The current `required_status_checks.checks` array is:
```json
[
  { "context": "merge-blocking rulestead proof (hermetic)", "app_id": 15368 },
  { "context": "brand-structural", "app_id": 15368 }
]
```

The `context` value is the workflow job's `name:` field (not the job ID). `app_id: 15368` is the GitHub Actions app.

To add the new E2E check after the workflow job name is set, run:

```bash
gh api repos/szTheory/crosswake/branches/main/protection/required_status_checks \
  --method PATCH \
  --field strict=true \
  --field 'checks[][context]=merge-blocking offline-sync proof (hermetic)' \
  --field 'checks[][app_id]=15368' \
  --field 'checks[][context]=merge-blocking rulestead proof (hermetic)' \
  --field 'checks[][app_id]=15368' \
  --field 'checks[][context]=brand-structural' \
  --field 'checks[][app_id]=15368'
```

**Important:** The PATCH to `required_status_checks` replaces the full `checks` array — you must include ALL existing required checks in the same call or they will be removed. Include the existing two alongside the new one.

**Prerequisite:** The workflow job must have run at least once on `main` before GitHub will accept it as a required check. Merge a green run of the renamed job before adding the protection.

**Job naming convention (from existing workflows):** Use `name: merge-blocking offline-sync proof (hermetic)` as the job's `name:` field, matching the `merge-blocking-*` job ID naming convention already in use. The `name:` string is what appears in the branch protection UI and what the `context` field must match.

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `window['crosswake_offline_mutations']` scratch injection | This variable is not used by `offline_study.js` — the app writes to IndexedDB. Injecting it bypasses the outbox entirely and tests nothing real. | Click the real UI buttons to trigger `handleReview()` → `queueMutation()` → IndexedDB write |
| `page.evaluate(() => fetch('/study/sync', ...))` (manual fetch) | Bypasses the app's reconnect path. The test proves the test can call fetch, not that the app syncs on reconnect. | Let the app's `window.addEventListener('online', flushOutbox)` fire the POST naturally after `dispatchEvent(new Event('online'))` |
| Expecting `context.setOffline(false)` alone to trigger `online` event | Documented Playwright behavior: `setOffline` does not dispatch `online`/`offline` window events. The app's listener will never fire. | `setOffline(false)` + `page.evaluate(() => window.dispatchEvent(new Event('online')))` |
| Adding a new testing framework (Cypress, Puppeteer, etc.) | Playwright is already installed, configured, and has a working webServer block that boots Phoenix. New frameworks add zero value here. | Playwright only |
| GitHub rulesets | The repo uses classic branch protection (confirmed via live API call — `[]` rulesets, populated protection on `main`). Rulesets are a separate, parallel mechanism. Mixing both adds confusion. | Classic branch protection PATCH API |
| `contexts` array in branch protection PATCH | Deprecated. The existing repo protection already uses `checks` (with `app_id`). Using `contexts` would downgrade to the older mechanism. | `checks` array with `context` + `app_id: 15368` |
| Upgrading `@playwright/test` for this milestone | 1.60.0 has every API needed. Upgrades risk breaking existing brand-structural and other E2E specs. | Stay on 1.60.0 |

---

## Alternatives Considered

| Recommended | Alternative | Why Not |
|-------------|-------------|---------|
| `window.dispatchEvent(new Event('online'))` via `page.evaluate` | Rely on `context.setOffline(false)` alone | `setOffline` does not dispatch browser `online` events; documented Playwright behavior; the app's listener never fires |
| `page.waitForResponse(predicate)` | `page.waitForRequest(predicate)` (current spec) | `waitForRequest` completes when the request is dispatched, before the server has processed it. `waitForResponse` waits for the server response, giving confidence the sync POST was accepted before polling Ecto. |
| Click real UI buttons to queue mutations | `page.evaluate` IndexedDB write | Writing directly to IndexedDB bypasses `queueMutation()` entirely. A real click exercises the full JS path including error handling and QuotaExceededError guards. |
| Store correct payload shape in `queueMutation` | Transform in `flushOutbox` | Storing the right shape at write time keeps `flushOutbox` simple and honest. Transformation in `flushOutbox` adds a mapping layer that could silently drift from the ReviewEvent changeset schema. |

---

## Version Compatibility

| Component | Version | Notes |
|-----------|---------|-------|
| `@playwright/test` | 1.60.0 (resolved) | All needed APIs (`setOffline`, `waitForResponse`, `expect.poll`, `addInitScript`, `evaluate`) confirmed available |
| `context.setOffline` | Added before v1.9 | Stable, no version concern |
| `window.dispatchEvent` workaround | Any Playwright version | Standard DOM, works in all browser engines |
| `expect.poll` | Available since v1.23 | Well within 1.60.0 |
| GitHub branch protection `checks` API | Current (not deprecated) | `contexts` is deprecated; `checks` is the current API |

---

## Sources

- Playwright `BrowserContext.setOffline` official docs: https://playwright.dev/docs/api/class-browsercontext#browser-context-set-offline — added before v1.9; emulates network offline via CDP (HIGH confidence)
- Playwright network events / `waitForResponse`: https://playwright.dev/docs/network#network-events — predicate/glob/regex overloads verified (HIGH confidence)
- Playwright `expect.poll` docs: https://playwright.dev/docs/test-assertions#expectpoll — `timeout`, `intervals`, `message` options verified (HIGH confidence)
- Playwright mock browser APIs / `addInitScript`: https://playwright.dev/docs/mock-browser-apis — `Object.defineProperty` + `window.dispatchEvent` pattern for `navigator.onLine` (HIGH confidence)
- `setOffline` does not fire `online`/`offline` window events: https://adequatica.medium.com/hidden-gems-of-playwright-part-2-ca3e38a5954a — documented limitation confirmed; workaround is `dispatchEvent` (MEDIUM confidence — official docs do not state this explicitly; community source agrees with CDP behavior)
- GitHub branch protection REST API: https://docs.github.com/en/rest/branches/branch-protection — `PATCH required_status_checks` with `checks` array (HIGH confidence)
- Live `gh api` call to `repos/szTheory/crosswake/branches/main/protection`: confirmed `checks` array with `app_id: 15368`, no rulesets active (HIGH confidence — live data)
- Existing project files read directly: `examples/phoenix_host/playwright.config.ts`, `e2e/offline_sync.spec.ts`, `priv/static/offline_study.js`, `.github/workflows/offline-sync-e2e-gate.yml`, all `merge-blocking-*` workflow job names across `.github/workflows/*.yml` (HIGH confidence)

---
*Stack research for: Crosswake v12.0 CI Honesty / Real-E2E Sweep*
*Researched: 2026-06-17*
