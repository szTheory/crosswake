---
phase: 35-reconciliation-wiring-and-four-state-liveview
verified: 2026-05-29T21:30:00Z
status: human_needed
score: 5/5 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Visit /commerce/paywall in a running dev server and click Subscribe"
    expected: "UI transitions :stale -> :pending immediately (synchronous broadcast), then :granted after ~1.5 seconds (Task broadcast). The :pending component shows 'Processing your purchase' with no action buttons."
    why_human: "Async PubSub timing and LiveView re-render sequence cannot be verified by grep"
  - test: "Use the 'Force: denied' dev scenario button while on /commerce/paywall"
    expected: "UI shows 'Subscribe to continue' with price display '$9.99 / month', Subscribe button, and Restore purchase link"
    why_human: "Live render of the :denied component consuming @paywall_entry assigns requires a running server"
  - test: "Use the 'Force: stale' dev scenario button while on /commerce/paywall"
    expected: "UI shows 'Access unavailable' with no price display and no Subscribe/Restore buttons — structurally distinct from :denied"
    why_human: "Visual structural distinction between :stale and :denied requires human confirmation"
  - test: "Click Restore on /commerce/paywall when in :denied state"
    expected: "UI transitions :denied -> :pending synchronously, then :granted after ~1.5 seconds"
    why_human: "Restore flow async timing requires running server observation"
---

# Phase 35: Reconciliation Wiring And Four-State LiveView Verification Report

**Phase Goal:** `PaywallEntryLive`, `PurchaseIntentLive`, and `RestoreIntentLive` are wired end-to-end — mock evidence flows through `ReconciliationInbox.ingest_evidence/2` and `EntitlementProjection.project_snapshot/2`, and `PaywallEntryLive` renders all four `derived_state/1` outputs as distinct UI states.
**Verified:** 2026-05-29T21:30:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Note on Phase Goal Wording vs D-08

The phase goal names `PurchaseIntentLive` and `RestoreIntentLive` as literal modules. Per locked decision D-08 (confirmed with user in 35-CONTEXT.md): these are satisfied by the purchase-intent and restore-intent **flows** on `PaywallEntryLive` plus the `CorridorController` seams, not by literal separate modules. All five success criteria are evaluated against this reinterpretation.

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Purchase-intent flow submits mock `ReconciliationEvidence` to `ReconciliationInbox.ingest_evidence/2` and handles `EvidenceResult` (status `:awaiting_verification`) — per D-08, satisfied by `PaywallEntryLive.handle_event("subscribe")` + `CorridorController.purchase` | ✓ VERIFIED | `paywall_entry_live.ex:33` — `case ReconciliationInbox.ingest_evidence(evidence) do`; `corridor_controller.ex:52` — `{:ok, attempt} = ReconciliationInbox.ingest_evidence(evidence)`. Pattern-matched `{:ok, _attempt}` in LiveView triggers `:pending` broadcast. |
| 2 | `EntitlementProjection.project_snapshot/2` is invoked after simulated backend verification, producing the authoritative entitlement snapshot used to derive UI state | ✓ VERIFIED | `mock_backend.ex:56-57` — `{:ok, projected} = EntitlementProjection.project_snapshot(nil, snapshot)` then `state = EntitlementProjection.derived_state(projected)`. Called synchronously in `verify_and_broadcast/2`, which is invoked via `Task.start` from both `PaywallEntryLive.handle_event("subscribe"/"restore")` and `CorridorController.purchase/restore`. |
| 3 | `PaywallEntryLive` renders a single subscription `PaywallEntry` (pricing display + "Subscribe" action) with zero provider-SDK code visible | ✓ VERIFIED | `paywall_entry_live.ex:335-346` — `%Contracts.PaywallEntry{id: @group_id, price_display: "$9.99 / month", ...}` constructed in private `paywall_entry/0`. The `:denied` component at line 303-310 renders `{@paywall_entry.price_display}` and `phx-click="subscribe"`. Provider-vocabulary fence holds: grep of all three new files returns zero matches for storekit/play_billing/revenuecat. |
| 4 | `PaywallEntryLive` has explicit `case` branches for all four `derived_state/1` values — `:granted`, `:pending`, `:denied`, `:stale` — where `:stale` is visually distinct from `:denied` and `:pending` shows a "processing" state | ✓ VERIFIED | `paywall_entry_live.ex:266-275` — exhaustive `case @derived_state` with four explicit atom branch heads and NO `_ ->` fallthrough (confirmed by grep). `:stale` component (lines 314-320) has NO `phx-click="subscribe"` and NO price display — structurally distinct from `:denied`. `:pending` component shows "Processing your purchase" with no action buttons. |
| 5 | `PaywallEntryLive` initializes to `:stale` on mount (fail-closed) and transitions to other states only via the PubSub `{:entitlement_update, derived_state}` message path | ✓ VERIFIED | `paywall_entry_live.ex:11-22` — `mount/3` assigns `derived_state: :stale` before returning. Line 12-14: `if connected?(socket) do Phoenix.PubSub.subscribe(CrosswakeExample.PubSub, "entitlement:" <> @group_id) end`. Line 258: `handle_info({:entitlement_update, derived_state}, socket)` is the only post-mount state-transition path — it assigns `derived_state: derived_state`. Note: `:stale`-on-mount is a LOCKED design decision (fail-closed). |

**Score:** 5/5 truths verified

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex` | MockBackend: `build_verified_snapshot/2` + `verify_and_broadcast/2` | ✓ VERIFIED | 120-line module. Contains `def build_verified_snapshot`, `def verify_and_broadcast`, `EntitlementProjection.project_snapshot`, `EntitlementProjection.derived_state`, `struct!(Contracts.EntitlementSnapshot`, `System.system_time(:microsecond)` for `as_of`, and `{:entitlement_update,` broadcast. |
| `examples/phoenix_host/lib/crosswake_example/corridor_controller.ex` | Thin JSON POST seam with `purchase/2` and `restore/2` | ✓ VERIFIED | 76-line module. Contains `use Phoenix.Controller, formats: [:json]`, `def purchase(conn`, `def restore(conn`, `ReconciliationInbox.ingest_evidence`, `MockBackend.verify_and_broadcast`. `restore/2` builds `%Contracts.RestoreIntent{correlation_id:` with no `entry_id` key. |
| `examples/phoenix_host/lib/crosswake_example/application.ex` | PubSub started in supervision tree as first child | ✓ VERIFIED | `{Phoenix.PubSub, name: CrosswakeExample.PubSub}` is the FIRST child before `CrosswakeExample.Repo`. |
| `examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex` | Four-state LiveView: mount/subscribe/handle_event/handle_info/render | ✓ VERIFIED | 347-line module. All required patterns present: `connected?(socket)` guard, fail-closed `:stale`, exhaustive `case`, four named components (`granted/pending/denied/stale`), `dev_scenarios`, six `handle_event` clauses, `handle_info`. |
| `examples/phoenix_host/lib/crosswake_example/router.ex` | Suppressions for `PaywallEntryLive` and `CorridorController` removed | ✓ VERIFIED | Only `@compile {:no_warn_undefined, CrosswakeExample.Crosswake.Policy}` remains. `live "/paywall", PaywallEntryLive` and both POST routes intact. |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `mock_backend.ex` | `EntitlementProjection.project_snapshot/2` | `verify_and_broadcast/2` calls it synchronously | ✓ WIRED | Line 56: `{:ok, projected} = EntitlementProjection.project_snapshot(nil, snapshot)` |
| `corridor_controller.ex` | `ReconciliationInbox.ingest_evidence` | `purchase/2` and `restore/2` call it | ✓ WIRED | Lines 52, 72: `{:ok, attempt} = ReconciliationInbox.ingest_evidence(evidence)` |
| `paywall_entry_live.ex` | `CrosswakeExample.PubSub` topic `entitlement:sub_pro_monthly` | `Phoenix.PubSub.subscribe` inside `if connected?(socket)` | ✓ WIRED | Lines 12-14: `Phoenix.PubSub.subscribe(CrosswakeExample.PubSub, "entitlement:" <> @group_id)` |
| `paywall_entry_live.ex` | `MockBackend.verify_and_broadcast/2` | `Task.start` fire-and-forget after synchronous `:pending` broadcast | ✓ WIRED | Lines 41-44 (subscribe) and 74-77 (restore): `Task.start(fn -> :timer.sleep(1_500); MockBackend.verify_and_broadcast(evidence, @group_id) end)` |
| `paywall_entry_live.ex` | `handle_info({:entitlement_update, derived_state}, socket)` | PubSub message arrives via `handle_info`, assigns derived atom | ✓ WIRED | Line 258: `def handle_info({:entitlement_update, derived_state}, socket)` → `assign(socket, derived_state: derived_state)` |

---

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `paywall_entry_live.ex` `render/1` | `@derived_state` | Initialized in `mount/3` as `:stale`; updated exclusively via `handle_info({:entitlement_update, ...})` which receives from `Phoenix.PubSub.broadcast` in `MockBackend.verify_and_broadcast/2` | Yes — PubSub message carries real `derived_state/1` output from real `project_snapshot/2` call on a real `%EntitlementSnapshot{}` | ✓ FLOWING |
| `paywall_entry_live.ex` `:denied` component | `@paywall_entry` (price_display, etc.) | Constructed in mount via `paywall_entry/0` private function returning `%Contracts.PaywallEntry{price_display: "$9.99 / month", ...}` | Yes — mock display values intentional for example host; adopters substitute real values | ✓ FLOWING (intentional mock values) |

**No raw `EntitlementSnapshot` lane fields appear in any render function.** The UI consumes only the derived atom (`@derived_state`) and the static `PaywallEntry` contract (`@paywall_entry`). D-11 / STATE-01 satisfied.

---

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Example host compiles clean | `cd examples/phoenix_host && mix compile --warnings-as-errors` | Exit 0, no output | ✓ PASS |
| Provider vocabulary fence holds (all three new files) | `grep -iE 'storekit\|play[ _]billing\|revenuecat' mock_backend.ex corridor_controller.ex paywall_entry_live.ex` | No matches | ✓ PASS |
| No debt markers (TBD/FIXME/XXX) in any modified file | `grep -n -E 'TBD\|FIXME\|XXX' [all 5 files]` | No matches | ✓ PASS |
| Root test suite (294 tests, 0 failures) | `mix test --exclude requires_example_host` | 294 tests, 0 failures (29 excluded) | ✓ PASS |
| Root suite `--warnings-as-errors` wave gate | `mix test --exclude requires_example_host --warnings-as-errors` | Aborts due to pre-existing unused variable warning in `test/crosswake/offline/proof_lane_test.exs:37` (variable `support`) — pre-dates Phase 35, confirmed by git log. Not introduced by this phase. | ? SKIP (pre-existing) |

---

## Probe Execution

No probes declared for this phase. Phase 36 will contain the hermetic proof probes (PROOF-01/PROOF-03). Step 7c: SKIPPED (no probe files declared for Phase 35).

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| WIRE-01 | 35-01 | Adopter can see the example submit mock `ReconciliationEvidence` to `ReconciliationInbox.ingest_evidence/2` and handle the returned `EvidenceResult` | ✓ SATISFIED | `PaywallEntryLive.handle_event("subscribe"/"restore")` — `case ReconciliationInbox.ingest_evidence(evidence)` with `{:ok, _attempt}` + `{:error, _}` branches. `CorridorController.purchase/restore` — `{:ok, attempt} = ReconciliationInbox.ingest_evidence(evidence)` + `json(conn, %{status: attempt.status})`. |
| WIRE-02 | 35-01 | Adopter can see `EntitlementProjection.project_snapshot/2` produce the authoritative entitlement snapshot after successful ingestion | ✓ SATISFIED | `MockBackend.verify_and_broadcast/2` calls `EntitlementProjection.project_snapshot(nil, snapshot)` then `EntitlementProjection.derived_state(projected)` and broadcasts the derived atom. Called from both LiveView and CorridorController. |
| STATE-01 | 35-02 | `PaywallLive` reflects entitlement access via `EntitlementProjection.derived_state/1`, surfacing `:granted`, `:pending`, `:denied`, and `:stale` as four distinct UI states without exposing raw `EntitlementSnapshot` lane fields | ✓ SATISFIED | Exhaustive `case @derived_state` with four explicit branches, no `_ ->` fallthrough. `:stale` is structurally distinct (no pricing, no Subscribe). Only derived atom and `PaywallEntry` contract exposed in render. |
| PWAL-02 | 35-02 | Adopter can see a `PaywallLive` LiveView render a single subscription `PaywallEntry` (pricing display + "Subscribe" action) with zero provider-SDK code | ✓ SATISFIED | `:denied` component renders `%Contracts.PaywallEntry{}` fields only — `{@paywall_entry.price_display}`, `phx-click="subscribe"`, `phx-click="restore"`. No provider-SDK tokens anywhere. |

**Orphaned requirement check:** All four requirements (WIRE-01, WIRE-02, STATE-01, PWAL-02) claimed in plan frontmatter and verified above. No Phase 35 requirements from REQUIREMENTS.md are unclaimed.

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `mock_backend.ex` | 56 | Bare match `{:ok, projected} = EntitlementProjection.project_snapshot(nil, snapshot)` inside `verify_and_broadcast/2` (which is called from a fire-and-forget Task) | ⚠️ Warning | `build_verified_snapshot/2` always constructs a `:projection_refreshed` snapshot, so the error branch is unreachable in the current mock. However, if the snapshot constructor is changed, a silent Task crash would leave every LiveView stuck in `:pending`. The Phase 36 hermetic proof calls this function directly (outside a Task), so the bare match does not endanger the proof. Does not block success criteria. |

**Debt marker gate:** No TBD/FIXME/XXX markers found in any file modified by this phase.

**Pre-existing issues noted in REVIEW.md but not introduced by Phase 35:**

- **WR-02** (No Endpoint in application.ex): The example host has no `Endpoint` module and has never had one — it is a manifest-generation host (`gen_manifest.exs`), not a running HTTP server. This is pre-existing architecture, not a Phase 35 change.
- **CR-02** (Commerce POST routes in `:browser` pipeline): The `/commerce` scope's `pipe_through [:browser]` was established in Phase 33 commit `adf1f55`. Phase 35 only removed two `@compile` suppression lines. The `:browser` pipeline contains `plug :accepts, ["html"]`, which would refuse JSON-only requests to the POST routes. This is a pre-existing Phase 33 decision and out of Phase 35's scope.
- **WR-05** (`:stale`-on-mount is "semantically incorrect"): LOCKED decision. Fail-closed `:stale`-on-mount is intentional per success criterion #5 and D-13. Not a defect.

---

## Human Verification Required

### 1. Subscribe Flow: :stale -> :pending -> :granted Transition

**Test:** Run `cd examples/phoenix_host && mix phx.server` (requires adding an Endpoint — note this is currently a manifest-generation host without one), navigate to `/commerce/paywall`, click "Subscribe".
**Expected:** UI transitions `:stale` → `:pending` immediately (synchronous broadcast), then `:granted` after approximately 1.5 seconds (Task + `MockBackend.verify_and_broadcast`). The `:pending` state shows "Processing your purchase" with no action buttons.
**Why human:** Async PubSub timing and LiveView re-render sequence cannot be verified by static analysis.

### 2. :denied Component Rendering

**Test:** Use the "Force: denied" dev scenario button on `/commerce/paywall`.
**Expected:** UI shows "Subscribe to continue", product name "Pro Monthly", price "$9.99 / month", Subscribe button, and "Already subscribed? Restore purchase" link.
**Why human:** Live render of the `:denied` component consuming `@paywall_entry` assigns requires a running LiveView socket.

### 3. :stale vs :denied Structural Distinction

**Test:** Use the "Force: stale" dev scenario button on `/commerce/paywall`, then "Force: denied".
**Expected:** `:stale` shows "Access unavailable" with NO price display and NO Subscribe/Restore buttons — structurally distinct from `:denied`. Only messaging confirms verification failure; no commerce actions offered.
**Why human:** Visual confirmation of structural distinction requires rendering the actual components.

### 4. Restore Flow

**Test:** When in `:denied` state, click "Already subscribed? Restore purchase".
**Expected:** UI transitions `:denied` → `:pending` synchronously, then `:granted` after ~1.5 seconds. Same transition shape as Subscribe flow.
**Why human:** Async timing of restore-intent flow through `MockStorefront.simulate_restore` → `ingest_evidence` → `:pending` broadcast → `MockBackend.verify_and_broadcast` requires running server.

---

## Gaps Summary

No gaps blocking goal achievement. All five success criteria are satisfied by the codebase as verified. The one anti-pattern found (bare match in MockBackend Task path, CR-01 from the code review) does not block any success criterion — it is a code quality warning for future robustness.

The phase goal is achieved: mock evidence flows through `ReconciliationInbox.ingest_evidence/2` and `EntitlementProjection.project_snapshot/2`, and `PaywallEntryLive` renders all four `derived_state/1` outputs as distinct UI states with the correct structural properties. Human verification is needed to confirm the async timing and visual rendering of the four states in a live server.

---

_Verified: 2026-05-29T21:30:00Z_
_Verifier: Claude (gsd-verifier)_
