---
phase: 112-real-offline-outbox-flush
plan: "01"
subsystem: offline-study-island
tags: [offline, indexeddb, sync, accessibility, javascript, heex]
dependency_graph:
  requires: []
  provides: [real-outbox-flush, queue-time-uuid, good-hard-controls, aria-live-status]
  affects: [e2e/offline_sync.spec.ts (Phase 113 will consume this real code path)]
tech_stack:
  added: []
  patterns: [IndexedDB tx-promise wrapper, single-flight async guard, semantic CSS token usage]
key_files:
  created: []
  modified:
    - examples/phoenix_host/priv/static/offline_study.js
    - examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex
decisions:
  - "queue-time UUID (not flush-time): client_mutation_id generated at queueMutation call so retry reuses same id and server on_conflict:nothing deduplicates correctly"
  - "single-flight flushing flag prevents overlapping flush status counts even though server idempotency makes double-POSTs harmless"
  - "three reconnect triggers: window online event + optimistic flush when navigator.onLine at review time + on-load drain in setupEventListeners"
  - "partial-success delete semantics: only delete records whose client_mutation_id is in data.data.accepted_records, leave rejected queued"
  - "D-08 cleanup applied: replaced hardcoded hex (#9A4D35, #fee2e2, #ef4444) with brand tokens in displayHardBlock and QuotaExceededError handler"
  - "btn-secondary neutral outlined (--cw-border-default) for Hard button: not an error state, no color-only signaling, passes AA both modes"
requirements-completed: [E2E-01, E2E-02]
metrics:
  duration: "~20 minutes"
  completed: "2026-06-17T22:00:13Z"
  tasks_completed: 3
  files_modified: 2
---

# Phase 112 Plan 01: Real Offline Outbox Flush Summary

Real IndexedDB outbox with reconnect-flush and queue-time UUID in offline_study.js; Good/Hard controls with aria-live status region in index.html.heex.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Fix queued-mutation shape and queue-time UUID | 118a0d3 | offline_study.js |
| 2 | Add real flushOutbox() with three reconnect triggers | 118a0d3 | offline_study.js |
| 3 | Relabel rating controls Good/Hard, wire aria-live | 2d727e6 | index.html.heex |

Note: Tasks 1 and 2 both modified offline_study.js and were implemented together in a single coherent edit, committed as 118a0d3. All acceptance criteria for both tasks were verified before the commit.

## What Was Built

### offline_study.js

**handleReview rewrite (Task 1):**
- Single `rating` parameter ('good' | 'hard') replaces old `result` ('pass' | 'fail')
- Mutation record now `{client_mutation_id, card_id, rating}` matching `ReviewEvent.changeset/2`
- `client_mutation_id` generated via `crypto.randomUUID()` at queue time so retries reuse the same UUID (server's `on_conflict: :nothing` on `client_mutation_id` deduplicates)
- `card_id` uses `parseInt(card.id, 10)` — converts string '1' to integer 1
- Old `{type: 'REVIEW_CARD', payload: {cardId, result, timestamp}}` wrapper removed entirely

**setupEventListeners updates (Task 1):**
- `btn-pass`/`btn-fail` lookups replaced with `btn-good`/`btn-hard`
- `window.addEventListener('online', flushOutbox)` registered — first reconnect trigger
- `window.addEventListener('offline', ...)` updates status with `Offline — ${q} saved locally`
- `flushOutbox()` called at end of `setupEventListeners` — on-load drain (third trigger)

**flushOutbox() — new (Task 2):**
- Module-level `let flushing = false` single-flight guard
- Reads all records from STORE_MUTATIONS via new `getAllMutations()` helper (mirrors getAllCards pattern)
- Empty queue: returns early without calling `updateStatus` (preserves card-progress line, no "Synced 0" noise)
- POSTs `{events: [{client_mutation_id, card_id, rating}, ...]}` to `/study/sync`
- On 2xx: extracts `data.data.accepted_records`, deletes only accepted records via `deleteAcceptedMutations()` in a single readwrite transaction; logs `console.warn` for rejected records; sets `Synced ${n} · queued ${remaining}`
- On non-2xx or network error: leaves all records queued, sets error border (3px solid `--cw-status-error`) + `Sync failed — ${q} still saved locally. Retrying on reconnect.`
- All non-error status updates clear the error border via `updateStatusClear()`

**New helpers (Task 2):**
- `getAllMutations()` — readonly getAll on STORE_MUTATIONS (mirrors getAllCards)
- `deleteAcceptedMutations(records, acceptedIds)` — single readwrite transaction deletes only accepted auto-increment IDs
- `countMutations()` — count remaining after delete for status line
- `updateStatusClear()` — resets error border/padding/color to fall back to #status rule

**Optimistic flush (Task 2 — second trigger):**
- At end of handleReview, if `navigator.onLine` is true, calls `flushOutbox()` immediately

**D-08 cleanup (discretionary):**
- `displayHardBlock()` hex `#9A4D35`/`#fee2e2`/`#ef4444` replaced with `color: var(--cw-text-default)` and `border-left: 3px solid var(--cw-status-error)`
- `QuotaExceededError` handler hex replaced with `color: var(--cw-text-default)`

### index.html.heex

**Button relabel (Task 3):**
- `id="btn-pass"` → `id="btn-good"`, label Pass → Good, `class="btn-primary"` (primary affordance)
- `id="btn-fail"` → `id="btn-hard"`, label Fail → Hard, `class="btn-secondary"` (neutral outlined)
- Removed `.btn-success`/`.btn-danger` CSS rules (green/rust color split)
- Added `.btn-secondary { background: transparent; color: var(--cw-text-default); border-color: var(--cw-border-default); }` — neutral, no color-only signaling, AA in both modes

**Accessibility (Task 3):**
- `<div id="status">` gains `aria-live="polite" role="status" aria-atomic="true"` (D-06)
- Passive region: no tabindex, no hover/focus styling, no layout shift

## Deviations from Plan

### Auto-applied Discretionary (D-08)

**1. [Rule 2 - Missing D-08 cleanup] Migrated hardcoded hex to brand tokens**
- **Found during:** Task 1 — editing handleReview, noticed `displayHardBlock` and `QuotaExceededError` still had `#9A4D35`/`#fee2e2`/`#ef4444`
- **Fix:** Replaced with `var(--cw-text-default)` and `border-left: 3px solid var(--cw-status-error)` — consistent with D-07 error state pattern
- **Files modified:** `offline_study.js`
- **Commit:** 118a0d3

Note: D-08 was listed as "executor discretion" in the plan. Applied because it was in-file, trivial, and makes the island fully token-backed consistent with the brand-structural drift gate.

### Implementation Notes

Tasks 1 and 2 were implemented in the same offline_study.js edit (both target the same file and their changes are interleaved — flushOutbox is called from handleReview and setupEventListeners which Task 1 rewrites). Single commit 118a0d3 satisfies both task verifications.

## Known Stubs

None — all data flows are wired. The IndexedDB outbox is real, `flushOutbox()` issues a real HTTP POST, and the status region reports real server-response-derived counts.

## Threat Flags

No new threat surface introduced. Changes conform to the threat model defined in the plan:
- T-112-01 (Tampering): client emits only valid `good`/`hard` + integer `card_id` + UUID; server validates and rejects bad data
- T-112-02 (Spoofing): `client_mutation_id` remains an idempotency key only
- T-112-03 (DoS): single-flight `flushing` guard is implemented
- T-112-04 (Info Disclosure): status text is non-sensitive counts/state words

## Self-Check: PASSED

| Item | Status |
|------|--------|
| examples/phoenix_host/priv/static/offline_study.js | FOUND |
| examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex | FOUND |
| .planning/phases/112-real-offline-outbox-flush/112-01-SUMMARY.md | FOUND |
| Commit 118a0d3 (Tasks 1+2) | FOUND |
| Commit 2d727e6 (Task 3) | FOUND |
