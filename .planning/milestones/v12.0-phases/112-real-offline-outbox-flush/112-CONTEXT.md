# Phase 112: Real Offline Outbox Flush - Context

**Gathered:** 2026-06-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the `/offline` study island's `offline_study.js` a **real** IndexedDB-outbox-with-reconnect-flush, so any test run against it exercises the app's own code path — not a test-injected fabrication. Three files are modified, **none created**:

1. `offline_study.js` — fix the queued-mutation shape to the server contract, generate `client_mutation_id` at queue time, add a real `flushOutbox()` + reconnect triggers, and surface honest sync status.
2. `offline_html/index.html.heex` — reconcile the rating controls with the server vocabulary and wire the status live-region.
3. `study_session_live.ex` — remove the `sync_outbox` mock handler, its "Simulate Network Sync" button, and the `outbox`/`sync_result` assigns entirely.

**The server side is already correct and is NOT changed** (`SyncController` → `Study.sync_events/1`, idempotent `insert_all` on `client_mutation_id`). The `/_e2e/sync-state/:client_mutation_id` endpoint already exists and is consumed by the Phase 113 test, not built here.

**Maps to requirements:** E2E-01, E2E-02. **The honest test rewrite (E2E-03/04) is Phase 113 — not this phase.**

### Locked upstream — DO NOT re-open in planning
These are fixed by REQUIREMENTS.md + the v12.0 milestone research (`SUMMARY.md` §"Two scope decisions are locked"). Listed so the planner treats them as settled inputs:
- **Trigger surface = browser `window 'online'` event** on the existing socketless `/offline` island. **No** LiveView migration; **no** Background Sync API. The `/offline` page has no LiveView socket (`put_root_layout(false)`), so a `reconnected()` Hook is architecturally impossible there (`research/ARCHITECTURE.md`).
- **Three flush triggers** (E2E-02): `window.addEventListener('online', flushOutbox)`, an optimistic call when already online at review time, and an on-load drain.
- **Payload shape** = server contract `{client_mutation_id, card_id, rating}`, `client_mutation_id` from `crypto.randomUUID()` at **queue** time (not POST time). Replaces today's `{type, payload:{cardId, result}}`.
- **De-mock** `study_session_live.ex` entirely; `mix test` must stay green (no test depends on the deleted handler).
- **Flush contract** = batch POST `{"events":[…]}` to `POST /study/sync`; delete on 2xx, leave on failure for retry.

</domain>

<decisions>
## Implementation Decisions

All three open micro-decisions were resolved by parallel deep research (3 advisor agents: rating-control UX, outbox delete semantics, flush-feedback UX). They converge on the **explicit / honest / in-brand** option — coherent with the v12.0 proof-honesty ethos. Full research in `112-DISCUSSION-LOG.md`.

### Rating control vocabulary
- **D-01:** Relabel the `/offline` page buttons **Pass/Fail → "Good" / "Hard"** so label = queued value = server `rating` contract = `StudySessionLive`. No hidden label→value mapping (that indirection is the same class of dishonesty this milestone exists to eliminate; "Pass/Fail" also imports shame-laden grade semantics that Anki/SuperMemo/Duolingo all moved away from — these are SRS *scheduling signals*, not grades). Rename element IDs `btn-pass`/`btn-fail` → `btn-good`/`btn-hard`; `handleReview('good')` / `handleReview('hard')`. `card.id` (`'1'`) → integer `card_id` via `parseInt`.
- **D-02:** Drop the `.btn-success`/`.btn-danger` (green/rust) split — "Hard" is not an error. Mirror `StudySessionLive`: **Good = primary affordance, Hard = neutral/secondary** outlined. Exact tokens at executor discretion; must pass AA in light/dark/system with no color-only signaling. (Constraint: `--cw-status-error` rust-600 is ~3.1:1 — never use it as small-text color; borders/non-text only, per the D-06 render-verify note already in the HTML.)

### Outbox flush — delete semantics
- **D-03:** On HTTP 2xx, delete **only the records the server accepted** (those whose `client_mutation_id` is in `data.accepted_records`, equivalently not in `data.rejected`); leave non-2xx / network-failure batches **fully queued** for retry. Read the locked "delete on 2xx" criterion as "delete *confirmed-accepted* records" — a 200 carrying a `rejected` array is partial success, and the idempotency key (not the batch) is the unit of resolution. Matches Replicache / PouchDB / ElectricSQL / WatermelonDB sync semantics; the server already returns `accepted_records` + `rejected` precisely so the client can do this.
- **D-04:** Rejected events are structurally impossible in this demo (the client only ever emits valid `good`/`hard` + integer `card_id` + a UUID). Handle them with a `console.warn(client_mutation_id, errors)` and an honest status line only. **No dead-letter queue, no conflict UI** — that is over-engineering for a teaching demo.

### Reconnect status feedback (UX)
- **D-05:** Drive the **existing `#status` line** through honest, non-alarmist states (inline status — **not** a toast or badge). Exact microcopy:
  - Reconnect, before drain: `Syncing…`
  - After success: `Synced {n} · queued {remaining}` (full drain naturally reads `Synced 3 · queued 0`)
  - Optimistic / on-load drain with nothing to send: leave the prior card-progress line (no "Synced 0" non-event noise)
  - Offline event: `Offline — {q} saved locally`
  - Flush failure: `Sync failed — {q} still saved locally. Retrying on reconnect.`
- **D-06:** Accessibility — add `aria-live="polite" role="status" aria-atomic="true"` to `<div id="status">`. `polite` (a routine sync must not interrupt a screen-reader user mid-card); `aria-atomic` (re-announce the whole "Synced N · queued M" string, not just the changed digit). Passive region — no `tabindex`, no hover/focus styling, no layout shift (text-only, already bottom-anchored).
- **D-07:** Color — steady states (`Syncing…`, `Synced…`, `Offline…`) keep `color: var(--cw-text-muted)` (calm, AA both modes); **do not** color the success line green (`--cw-status-success` flips across modes and a routine sync needs no celebration). Error state: keep text at `--cw-text-default` (full AA) and convey error with `border-left: 3px solid var(--cw-status-error)` (3:1 non-text threshold passes) — never rust small text, never color alone (the word "failed" carries meaning).

### Claude's Discretion
- **D-08 (optional, in-file cleanup):** While editing `offline_study.js`, migrate the hardcoded hex in `displayHardBlock()` and the `QuotaExceededError` handler (`#9A4D35`, `#fee2e2`, `#ef4444`) to brand tokens (`--cw-status-error` border + `--cw-text-default`) so the island is fully token-backed. Not required by E2E-01/02 — executor discretion.
- IndexedDB read/delete plumbing for `flushOutbox()` (transaction shape, cursor vs getAll) — executor's choice; mirror the existing promise-wrapped tx helpers.
- Keep the `mutations` store's `keyPath: 'id', autoIncrement: true`; the auto `id` is the delete handle, `client_mutation_id` is a stored field.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & milestone research (LOCKED inputs)
- `.planning/REQUIREMENTS.md` — E2E-01, E2E-02 (locked requirements); §"Two scope decisions are locked" (window 'online'; remove sync_outbox mock)
- `.planning/research/SUMMARY.md` — v12.0 proof-honesty synthesis; hard build-order; the load-bearing `setOffline(false)` does-not-fire-`online` gotcha; payload-shape-fix-as-prerequisite
- `.planning/research/ARCHITECTURE.md` — `/offline` island has no LiveView socket → `window 'online'` is the only viable trigger
- `.planning/research/FEATURES.md` — reconnect-trigger / flush feature shape
- `.planning/research/PITFALLS.md` — offline-sync footguns (offline-validation-pretending-to-be-server-validation, etc.)
- `.planning/research/JTBD-AND-USER-FLOWS.md` — "my progress is safe offline and syncs when I'm back" trust JTBD

### Demo-app change surface
- `examples/phoenix_host/priv/static/offline_study.js` — has `queueMutation()`; needs payload-shape fix + `flushOutbox()` + reconnect triggers + status (D-01/03/04/05)
- `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex` — the `/offline` page (buttons → Good/Hard, `#status` live-region)
- `examples/phoenix_host/lib/crosswake_example/local_first/study_session_live.ex` — remove `sync_outbox` handler + "Simulate Network Sync" button + `outbox`/`sync_result` assigns
- `examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex` — `POST /study/sync` contract: body `{"events":[…]}`, 200 `%{data: result}` even on partial rejection (DO NOT change)
- `examples/phoenix_host/lib/crosswake_example/local_first/study.ex` — `sync_events/1`: idempotent `insert_all` (`on_conflict: :nothing`, `conflict_target: :client_mutation_id`), returns `%{accepted_count, accepted_records, rejected}` (DO NOT change)
- `examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex` — changeset: `rating ∈ {"good","hard"}`, `card_id` integer, `client_mutation_id` unique (DO NOT change)
- `examples/phoenix_host/lib/crosswake_example/router.ex` — `/study/sync` (`:api`), `/offline`, `/_e2e/sync-state/:client_mutation_id`
- `examples/phoenix_host/e2e/offline_sync.spec.ts` — the structurally-fraudulent test; **rewritten in Phase 113, not here** (reference only, to understand what the app must make honest)

### Brand
- `brandbook/` — AUTHORITATIVE current brand book (newer than `prompts/crosswake-brand-book.md`; prefer `brandbook/` on conflict). Semantic tokens, success/error-state rules, microcopy tone ("status-oriented, no drama"), and the D-06 rust-600 ≤3.1:1 contrast constraint

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `queueMutation()` in `offline_study.js` already writes to the IndexedDB `mutations` store (`keyPath:'id', autoIncrement:true`) — keep it; only change the record *shape* and add the UUID. The auto `id` becomes the delete handle for `flushOutbox()`.
- `updateStatus()` + the `<div id="status">` element already exist — reuse for D-05/06/07 (no new layout).
- Promise-wrapped IndexedDB tx helpers (`initDB`, `getAllCards`, `queueMutation`) are the established in-file pattern — mirror for the flush read-all + delete-accepted.
- Server `SyncController` + `Study.sync_events/1` are already idempotent and correct — the entire fix is client-side + de-mocking the LiveView.
- `/_e2e/sync-state/:client_mutation_id` endpoint already mounted (`:test`/`:e2e` scope) — Phase 113 consumes it.

### Established Patterns
- Semantic CSS custom properties (`--cw-*`) from `tokens.css`; outlined button treatment is render-verified (108-RENDER-VERIFY note already in the HEEx).
- Mutation event log → server-derived canonical state via `insert_all` (append-only, dedup on idempotency key).

### Integration Points
- `flushOutbox()` → `POST /study/sync` (`:api` JSON pipeline), body `{"events":[…]}`; parse `data.accepted_records` / `data.rejected` for D-03.
- Reconnect triggers: `window 'online'`, optimistic call when `navigator.onLine` at review time, on-load drain (with an in-flight guard so the three triggers don't double-drain — server idempotency makes a double-POST harmless, but a single-flight flag keeps the status counts clean).
- De-mocking `StudySessionLive` must keep `mix test` green — confirm no test references `sync_outbox`/`outbox`/`sync_result` before deleting.

</code_context>

<specifics>
## Specific Ideas

- User asked for deep subagent research on each open decision (idiomatic Elixir/Phoenix/Ecto fit, lessons from comparable libs/apps cross-ecosystem, DX, UI/UX + brand book + microcopy + a11y), synthesized into one coherent decisive set "so I don't have to think." Delivered: 3 parallel advisor agents → the D-01..D-08 set above, all pulling in the same explicit/honest/in-brand direction as the milestone.
- Comparable-app lessons that shaped the calls: Anki/SuperMemo/Duolingo (drop Pass/Fail grade vocabulary); Replicache/PouchDB/ElectricSQL/WatermelonDB (idempotency-key, not batch, is the unit of resolution); Google Docs "All changes saved" / Linear / Things (ambient-quiet sync status, never silent, never a toast).

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope. (The button-color refinement (D-02) and the hex→token cleanup (D-08) are in-file decisions captured above, not deferred to other phases.)

</deferred>

---

*Phase: 112-real-offline-outbox-flush*
*Context gathered: 2026-06-17*
