# Phase 112: Real Offline Outbox Flush - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-17
**Phase:** 112-real-offline-outbox-flush
**Areas discussed:** Rating control vocabulary, Outbox delete semantics, Reconnect status feedback
**Mode:** advisor (USER-PROFILE.md present) → `minimal_decisive` tier; user requested deep subagent research per area, synthesized into one coherent recommendation set.

---

## Pre-discussion: what was already locked (not re-asked)

Most of this phase was pre-decided by `REQUIREMENTS.md` (E2E-01/02) and the v12.0 milestone research. Surfaced to the user as settled inputs, not questions: `window 'online'` trigger (no LiveView migration, no Background Sync); three flush triggers (online + optimistic + on-load); payload shape `{client_mutation_id, card_id, rating}` with `crypto.randomUUID()` at queue time; remove the `sync_outbox` mock entirely; batch POST to `/study/sync`, delete on 2xx / leave on failure.

Three genuinely-open low-stakes micro-decisions remained. User asked for deep parallel research (idiomatic Elixir/Phoenix/Ecto fit, cross-ecosystem lessons, DX, UI/UX + brand book + microcopy + a11y) → 3 advisor subagents (Sonnet).

---

## Rating control vocabulary

| Option | Description | Selected |
|--------|-------------|----------|
| Relabel to Good/Hard | One vocabulary: label = queued value = server contract = LiveView; rename IDs `btn-good`/`btn-hard` | ✓ |
| Keep Pass/Fail, map to good/hard at queue time | Preserve current copy; add an implicit label→value mapping layer | |

**User's choice:** Resolved by research → relabel to Good/Hard (Option A).
**Notes:** A hidden Pass→good mapping is the same class of implicit-contract dishonesty the proof-honesty milestone exists to eliminate. "Pass/Fail" imports shame-laden grade semantics; Anki ("Again/Good"), SuperMemo, Duolingo all moved off binary pass/fail because these are SRS *scheduling signals*, not grades. Follow-on: drop the green/rust success-danger color split ("Hard" is not an error) → Good = primary, Hard = neutral, mirroring `StudySessionLive`.

---

## Outbox delete semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Delete only accepted records | On 2xx, delete records in `data.accepted_records`; leave `rejected` queued | ✓ |
| Delete whole batch on any 2xx | Literal reading of "delete on 2xx"; any 200 clears the whole POST | |

**User's choice:** Resolved by research → delete only accepted (Option A).
**Notes:** The idempotency key, not the batch, is the unit of resolution (Replicache/PouchDB/ElectricSQL/WatermelonDB all confirm only acknowledged ops). A 200 with a `rejected` array is *partial success*; the server already returns `accepted_records` + `rejected` so the client can do this. Rejected events are structurally impossible in this demo → handle with a `console.warn` + honest status line only; **no** dead-letter queue / conflict UI (over-engineering for a teaching demo).

---

## Reconnect status feedback

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal inline status | Update existing `#status`: `Syncing…` → `Synced N · queued M`; offline/failure copy | ✓ |
| Silent | No UI update; outbox empties invisibly | |

**User's choice:** Resolved by research → minimal inline status (Option A).
**Notes:** Offline-first trust JTBD requires sync state be ambient-quiet — never silent (reads as data loss), never a toast (drama the brand book forbids). Google Docs "All changes saved" / Linear / Things as the model: a low-weight factual inline line. Brand book settles the register ("status-oriented, no drama"). Includes `aria-live="polite" role="status" aria-atomic="true"`; muted text for steady states; error conveyed via `border-left` rust (3:1 non-text) not rust small text (D-06 ≤3.1:1 constraint), never color-alone.

---

## Claude's Discretion

- Optional in-file cleanup: migrate hardcoded hex in `displayHardBlock()` + `QuotaExceededError` handler to brand tokens (not required by E2E-01/02).
- IndexedDB read/delete plumbing for `flushOutbox()`; in-flight single-flight guard across the three triggers.
- Keep `mutations` store `keyPath:'id', autoIncrement:true` (auto id = delete handle; `client_mutation_id` is a stored field).

## Deferred Ideas

None — discussion stayed within phase scope.
