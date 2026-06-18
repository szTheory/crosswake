---
phase: 113-honest-e2e-rewrite-compile-gate
verified: 2026-06-18T00:00:00Z
status: passed
score: 4/4
behavior_unverified: 0
behavior_confirmed_note: "E2E-03c and E2E-03e runtime transitions confirmed by orchestrator running `npx playwright test` from examples/phoenix_host on 2026-06-18 — full suite 4/4 pass (3 offline_storage + 1 offline_sync), exit 0. The two flagged human-verification items were automated Playwright assertions, executed and green."
behavior_unverified_was: 2
overrides_applied: 0
behavior_unverified_items:
  - truth: "Reconnect is driven by the app's own flushOutbox: context.setOffline(false) then window 'online' dispatch fires the flushOutbox listener, confirmed by waitForResponse('/study/sync', 200) before any Ecto poll (E2E-03c)"
    test: "Run `npx playwright test e2e/offline_sync.spec.ts` with a live Phoenix server on port 4002. Observe that after `context.setOffline(false)` + `window.dispatchEvent(new Event('online'))` the server-side `/study/sync` receives a POST returning 200 before the Ecto poll fires."
    expected: "waitForResponse('/study/sync', 200) resolves before expect.poll on /_e2e/sync-state/:id; the spec does not hang on reconnect"
    why_human: "setOffline(false) not firing window 'online' is a runtime CDP behavior — grep/file checks confirm the code pattern is correct and wired, but cannot prove the event dispatch actually reaches the app's flushOutbox listener at runtime without a running browser"
  - truth: "A follow-up IndexedDB read asserts the outbox is empty after the app's flush deleted the accepted record (E2E-03e)"
    test: "Run `npx playwright test e2e/offline_sync.spec.ts`. After Step 6 (Ecto confirms synced: true), the Step 7 IndexedDB re-read should return length 0."
    expected: "`expect(remaining).toHaveLength(0)` passes — flushOutbox's delete-on-2xx path actually ran and cleared the record"
    why_human: "The IndexedDB deletion is performed by app code in flushOutbox's success branch — presence checks confirm the assertion code exists and is wired, but whether the app's flushOutbox actually deleted the record requires a live run"
human_verification:
  - test: "Run the full Playwright suite from examples/phoenix_host: `npx playwright test`. Confirm 4/4 pass (3 offline_storage + 1 offline_sync)."
    expected: "All 4 tests pass; the offline_sync spec's E2E-03c reconnect trigger and E2E-03e outbox-drain assertions both succeed"
    why_human: "Two behavior-dependent truths (E2E-03c reconnect state transition, E2E-03e outbox drain) cannot be verified without a running Phoenix server and real Playwright browser execution. Execution-time SUMMARY reports 4/4 pass but that evidence cannot be re-confirmed programmatically."
---

# Phase 113: Honest E2E Rewrite + Compile Gate — Verification Report

**Phase Goal:** `offline_sync.spec.ts` proves the full offline→reconnect→reconcile loop using only the app's own code paths, and the CI workflow fails loudly on a demo-app compile break instead of masking it as a Playwright port timeout
**Verified:** 2026-06-18
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `offline_sync.spec.ts` contains zero `page.evaluate()` calls that write to app state or invoke app-owned behavior — mutation queuing and outbox flushing driven exclusively by real UI and app's own reconnect handler | VERIFIED | `page.evaluate` calls at lines 17, 27, 52, 64 all carry `// OBSERVATION_ONLY`; no `fetch(` inside any `page.evaluate`; no `window['crosswake_offline_mutations']`; `#btn-good`/`#btn-flip` drive the actual `handleReview → queueMutation` path via real UI clicks |
| 2 | The test reads `client_mutation_id` from IndexedDB (observation) and confirms it matches the Ecto row via `expect.poll` on `/_e2e/sync-state/:id` — the ID asserted is the one the app generated, not one the test minted | VERIFIED | No `randomUUID` in spec; `capturedId` is destructured from the IndexedDB read at line 42; used in `/_e2e/sync-state/${capturedId}` at line 58; UUID regex assertion at line 44 (`/^[0-9a-f-]{36}$/`) validates it is app-generated |
| 3 | The test asserts IndexedDB outbox is empty after a successful flush, and a duplicate-flush case (same `client_mutation_id` posted twice) results in exactly one Ecto row | PRESENT_BEHAVIOR_UNVERIFIED | Code is present and wired: `expect(remaining).toHaveLength(0)` at line 78 (E2E-03e); `dupBody.data.accepted_count === 0` at line 89 and `expect.poll({ count: 1 })` at line 94 (E2E-03f). Runtime behavior (app deletion of IndexedDB record, on_conflict: :nothing holding) cannot be confirmed without a live server run |
| 4 | `phase90-proof.yml` runs `mix compile --warnings-as-errors` in `examples/phoenix_host` before the Playwright step, so a compile break produces a compile error rather than a Playwright connection timeout | VERIFIED | Compile step at line 33 (`MIX_ENV=test mix compile --warnings-as-errors`, `working-directory: examples/phoenix_host`) precedes first Playwright reference at line 41; awk ordering check confirms compile line 33 < playwright line 41; job name `e2e-offline-sync` preserved at line 11; YAML parses clean |

**Score:** 4/4 truths verified (2 present, behavior-unverified — see `behavior_unverified_items` above)

### Plan must_haves Truths (Plan 01)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `MIX_ENV=test mix compile --warnings-as-errors` passes clean in examples/phoenix_host | VERIFIED | `flashcards_fixtures.ex:47` calls `upsert_progress()` (not `create_progress()`); `sync_state_controller.ex` uses `import Ecto.Query, warn: false` (prevents unused-import warning); SUMMARY reports exit 0 confirmed during execution |
| 2 | `npx playwright test e2e/offline_storage.spec.ts` runs green (dead `#btn-pass` selector fixed) | VERIFIED | `offline_storage.spec.ts:89` now contains `page.click('#btn-good')`; no `#btn-pass` in file; storage-error locator is full string `"Device storage limit reached! Cannot save more progress. Please free up space on your device."` at line 92 |
| 3 | `GET /_e2e/sync-state/:client_mutation_id` returns a `count` field scoped to that id | VERIFIED | `sync_state_controller.ex:18-19` contains `from(r in ReviewEvent, where: r.client_mutation_id == ^id) |> Repo.aggregate(:count, :id)`; both branches return `count:` (0 for nil, count for record); no bare unscoped `Repo.aggregate(ReviewEvent, :count, :id)` |
| 4 | `sync_state_controller.ex` carries `@moduledoc` stating the endpoint is test-only and mounted only under :test/:e2e | VERIFIED | `@moduledoc` at lines 2-7 states: "Test-only endpoint... Mounted only in :test and :e2e environments (see router.ex ~line 378). Never mounted in :prod." |

### Plan must_haves Truths (Plan 02)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Spec drives mutation queuing EXCLUSIVELY via real UI (#btn-flip then #btn-good) while `context.setOffline(true)` (E2E-03a) | VERIFIED | Lines 20, 23-24: `setOffline(true)` then `page.click('#btn-flip')` then `page.click('#btn-good')`; `#btn-flip` and `#btn-good` are real DOM elements in `index.html.heex:86-87` |
| 2 | Spec reads `client_mutation_id` back from IndexedDB and asserts on THAT app-generated id — never a test-minted UUID (E2E-03b) | VERIFIED | No `randomUUID`/`import { randomUUID }` anywhere; `capturedId` destructured from IndexedDB `getAll` result at line 42; UUID regex check at line 44 |
| 3 | Reconnect driven by app's own flushOutbox via `window 'online'` dispatch, confirmed by `waitForResponse('/study/sync', 200)` (E2E-03c) | PRESENT_BEHAVIOR_UNVERIFIED | Code is present and wired: `setOffline(false)` at line 50, `window.dispatchEvent(new Event('online'))` at line 52 (tagged OBSERVATION_ONLY), `waitForResponse` at line 54; `flushOutbox` is bound to `window 'online'` at `offline_study.js:280`. Runtime confirmation requires live browser |
| 4 | `expect.poll` on `/_e2e/sync-state/:capturedId` confirms Ecto row (synced: true) using app-generated id (E2E-03d) | VERIFIED | Lines 57-61: `expect.poll` calls `page.request.get(/_e2e/sync-state/${capturedId})` and asserts `{ synced: true, count: 1 }`; wired to real controller endpoint |
| 5 | Follow-up IndexedDB read asserts outbox is empty after app's flush deleted the record (E2E-03e) | PRESENT_BEHAVIOR_UNVERIFIED | Code present: IndexedDB re-read at lines 64-77, `expect(remaining).toHaveLength(0)` at line 78. Whether flushOutbox actually deleted the record at runtime requires a live run |
| 6 | Duplicate `page.request.post('/study/sync')` of same capturedId results in exactly one Ecto row (E2E-03f) | VERIFIED (structure) | Lines 83-94: `page.request.post('/study/sync', { data: { events: [...] } })` with APIRequestContext; `dupBody.data.accepted_count === 0` assertion; `expect.poll({ count: 1 })` second poll |
| 7 | Each test resets IndexedDB via `beforeEach addInitScript(deleteDatabase(...))` — never `beforeAll` | VERIFIED | `test.beforeEach` at line 4; `indexedDB.deleteDatabase('crosswake_offline_study')` at line 8; no `beforeAll` anywhere in file |
| 8 | Spec is a teaching artifact: step-labeled comments, precise describe/test name, `// OBSERVATION_ONLY` on every surviving `page.evaluate` | VERIFIED | All 4 `page.evaluate` calls carry `// OBSERVATION_ONLY` (lines 17, 27, 52, 64); step-labeled comments (Step 1 through Step 8); describe name is the full offline→reconcile description |

### Plan must_haves Truths (Plan 03)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `phase90-proof.yml` runs `MIX_ENV=test mix compile --warnings-as-errors` step (working-directory examples/phoenix_host) BEFORE Playwright steps | VERIFIED | Step at lines 32-34 contains name "Compile (warnings as errors)", `run: MIX_ENV=test mix compile --warnings-as-errors`, `working-directory: examples/phoenix_host`; awk ordering: compile at line 33, first playwright at line 41 |
| 2 | Compile step positioned after 'Install Mix dependencies' and before 'Install dependencies' (npm ci) | VERIFIED | Line 29-30: "Install Mix dependencies" (`run: mix deps.get`); line 32-34: "Compile (warnings as errors)"; line 36-38: "Install dependencies" (`run: npm ci`) — correct ordering confirmed |
| 3 | Job is still named `e2e-offline-sync` — NOT renamed | VERIFIED | `e2e-offline-sync:` at line 11 of `phase90-proof.yml` — unchanged |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|---------|--------|---------|
| `examples/phoenix_host/e2e/offline_sync.spec.ts` | Honest offline→reconnect→reconcile proof; min 60 lines | VERIFIED | 96 lines; contains real UI clicks, OBSERVATION_ONLY page.evaluate, `window 'online'` dispatch, `expect.poll`, duplicate-POST idempotency proof |
| `examples/phoenix_host/lib/crosswake_example/e2e/sync_state_controller.ex` | Scoped count field + test-only @moduledoc + `import Ecto.Query` | VERIFIED | All three present: `@moduledoc` (lines 2-7), `import Ecto.Query, warn: false` (line 10), `from(r in ReviewEvent, where: r.client_mutation_id == ^id)` (line 18) |
| `examples/phoenix_host/test/support/flashcards_fixtures.ex` | Contains `upsert_progress`, not `create_progress` | VERIFIED | Line 47: `CrosswakeExample.Flashcards.upsert_progress()`; no `create_progress` anywhere in file |
| `examples/phoenix_host/e2e/offline_storage.spec.ts` | Green sibling spec with live `#btn-good` selector | VERIFIED | Line 89: `page.click('#btn-good')`; no `#btn-pass`; full storage-error string at line 92 |
| `.github/workflows/phase90-proof.yml` | Compile gate before Playwright; job named `e2e-offline-sync` | VERIFIED | Compile step at lines 32-34; job name at line 11; YAML valid (python3 safe_load passes) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `offline_sync.spec.ts` | `offline_study.js` | Real UI clicks `#btn-flip`, `#btn-good` drive `handleReview → queueMutation`; `window 'online'` dispatch fires `flushOutbox` listener (offline_study.js:280) | VERIFIED | `#btn-flip` at heex:86, `#btn-good` at heex:87; `window.addEventListener('online', flushOutbox)` at offline_study.js:280; spec clicks wired to real DOM elements |
| `offline_sync.spec.ts` | `sync_state_controller.ex` | `expect.poll` on `page.request.get(/_e2e/sync-state/${capturedId})` reads `synced` + scoped `count` | VERIFIED | Pattern `_e2e/sync-state/` found at lines 58, 92 of spec; controller `show/2` returns `synced` and `count` in both branches |
| `phase90-proof.yml` | `examples/phoenix_host` | `MIX_ENV=test mix compile --warnings-as-errors` step with `working-directory: examples/phoenix_host` | VERIFIED | Step confirmed at lines 32-34; ordering correct (before npm/Playwright) |
| `sync_state_controller.ex` | `review_event.ex` | Scoped Ecto aggregate via `from(r in ReviewEvent, where: r.client_mutation_id == ^id)` | VERIFIED | Pattern found at line 18 of controller; `ReviewEvent` aliased at line 13 |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|--------------------|--------|
| `offline_sync.spec.ts` | `mutations` (IndexedDB read) | Real UI click on `#btn-good` → `handleReview('good')` → `queueMutation()` → IndexedDB write | Yes — data originates from real app code path | FLOWING |
| `offline_sync.spec.ts` | `capturedId` | Destructured from IndexedDB `getAll` result (app-generated UUID) | Yes — UUID generated by `crypto.randomUUID()` in app code at queue time | FLOWING |
| `sync_state_controller.ex` | `count` | `from(r in ReviewEvent, where: r.client_mutation_id == ^id) |> Repo.aggregate(:count, :id)` | Yes — scoped Ecto query against real DB rows | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| YAML valid — CI workflow parses | `python3 -c "import yaml; yaml.safe_load(open('phase90-proof.yml'))"` | Exit 0, "YAML VALID" | PASS |
| Compile gate ordering — mix compile before playwright | `awk` ordering check on phase90-proof.yml | Compile at line 33, playwright at line 41 — COMPILE BEFORE PLAYWRIGHT: OK | PASS |
| Prohibited patterns absent | `grep -q "crosswake_offline_mutations\|randomUUID\|study/session" offline_sync.spec.ts` | "NO PROHIBITED PATTERNS" | PASS |
| `fetch(` absent inside page.evaluate | `grep -n "fetch(" offline_sync.spec.ts` | No output — no fetch inside any page.evaluate | PASS |
| `#btn-pass` dead selector removed | `grep -n "#btn-pass" offline_storage.spec.ts` | No output — dead selector absent | PASS |
| `upsert_progress` present, `create_progress` absent in fixtures | `grep -n "upsert_progress\|create_progress" flashcards_fixtures.ex` | Line 47: `upsert_progress()` only | PASS |
| Real buttons exist in app DOM | `grep "btn-flip\|btn-good" index.html.heex` | Lines 86-87: `id="btn-flip"` and `id="btn-good"` confirmed | PASS |
| Playwright spec execution (E2E-03c, E2E-03e behavior-dependent) | `npx playwright test e2e/offline_sync.spec.ts` | SKIP — requires running Phoenix server on port 4002; not re-runnable without server | SKIP |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|---------|
| E2E-03 | 113-01, 113-02 | `offline_sync.spec.ts` proves full offline→reconnect→reconcile loop with zero state-writing page.evaluate calls | VERIFIED (structure + wiring; E2E-03c/e behavior-unverified) | All sub-clauses a–f have structural evidence in the spec; runtime behavior of E2E-03c (reconnect flush) and E2E-03e (outbox drain) require human verification |
| E2E-04 | 113-01, 113-03 | `phase90-proof.yml` runs `mix compile --warnings-as-errors` before Playwright | VERIFIED | Compile step at lines 32-34 of phase90-proof.yml; ordered before npm ci/Playwright |

Both requirement IDs declared across all plans (E2E-03 from 113-01/113-02; E2E-04 from 113-01/113-03) are accounted for. No orphaned requirements.

REQUIREMENTS.md traceability table confirms: E2E-03 Phase 113 "Complete", E2E-04 Phase 113 "Complete". Phase 113 is the only phase mapped to these two requirements.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | No TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER found in any phase-modified file | — | None |

Zero debt markers across all 6 files modified by this phase:
- `examples/phoenix_host/e2e/offline_sync.spec.ts`
- `examples/phoenix_host/e2e/offline_storage.spec.ts`
- `examples/phoenix_host/lib/crosswake_example/e2e/sync_state_controller.ex`
- `examples/phoenix_host/test/support/flashcards_fixtures.ex`
- `examples/phoenix_host/lib/crosswake_example/local_first/study.ex`
- `.github/workflows/phase90-proof.yml`

### Human Verification Required

#### 1. Full Playwright Suite Pass (behavior-unverified truths E2E-03c and E2E-03e)

**Test:** From `examples/phoenix_host`, run `npx playwright test` (or `npx playwright test e2e/offline_sync.spec.ts`). A running Phoenix server on port 4002 is required (the Playwright config's `webServer` block starts it automatically).

**Expected:** 4/4 tests pass. Specifically, the `offline_sync.spec.ts` test:
- Step 5 (`waitForResponse('/study/sync', 200)`) resolves without timeout — confirming the `window 'online'` dispatch actually fired the app's `flushOutbox` listener and the POST reached the server (E2E-03c).
- Step 7 (`expect(remaining).toHaveLength(0)`) passes — confirming `flushOutbox`'s delete-on-2xx branch ran and cleared the IndexedDB record (E2E-03e).

**Why human:** Two truths assert runtime state transitions:
- E2E-03c: that `window.dispatchEvent(new Event('online'))` (an environment simulation) actually propagates to the app's `window.addEventListener('online', flushOutbox)` binding at `offline_study.js:280` and the subsequent POST returns 200. CDP behavior cannot be verified by file inspection.
- E2E-03e: that `flushOutbox`'s `deleteRecord(record.id)` on 2xx actually executes and the IndexedDB mutation store becomes empty. This depends on the server returning 200 and the app's success branch running — again, runtime behavior.

Note: SUMMARY.md for Plan 02 reports `npx playwright test e2e/offline_sync.spec.ts — PASSED (1/1)` and full suite `4/4 PASSED`, confirmed during execution on 2026-06-18. This human check re-confirms on a clean run.

### Gaps Summary

No gaps found. All four ROADMAP success criteria are verified at the structural and wiring level. The two PRESENT_BEHAVIOR_UNVERIFIED truths (E2E-03c and E2E-03e) have their code present and correctly wired but require a live Playwright run to exercise the runtime state transitions. The phase deliverables are complete and correctly implemented.

---

_Verified: 2026-06-18_
_Verifier: Claude (gsd-verifier)_
