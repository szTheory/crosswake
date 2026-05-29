# Phase 35: Reconciliation Wiring And Four-State LiveView - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-29
**Phase:** 35-Reconciliation Wiring And Four-State LiveView
**Areas discussed:** Verification pipeline shape, Corridor component topology, Four-state UI + demo drivers, PubSub topic & message contract

**Mode:** Advisor (USER-PROFILE.md present; calibration tier `minimal_decisive`, vendor_philosophy `opinionated`). Two parallel research agents (Sonnet) covered the ecosystem-driven parts (Phoenix LiveView async/PubSub idioms; four-state UI rendering); the internal-reconciliation parts were decided from codebase facts. Recommendations synthesized into one coherent plan; two genuine forks escalated to the user.

---

## Gray area selection

All four offered gray areas were selected for discussion: Verification pipeline shape, Corridor component topology, Four-state UI + demo drivers, PubSub topic & message contract.

---

## Corridor component topology (escalated — reinterprets a success criterion)

| Option | Description | Selected |
|--------|-------------|----------|
| PaywallEntryLive + thin controllers | Honor Phase 33 D-03: PaywallEntryLive owns Subscribe/Restore via handle_event delegating to MockBackend; CorridorController.purchase/restore implemented as real thin seams on the same path; treat roadmap's PurchaseIntentLive/RestoreIntentLive as the intent *flows*, reword Criterion #1. | ✓ |
| Literal separate LiveViews | Build PurchaseIntentLive + RestoreIntentLive as standalone modules to match roadmap wording verbatim; contradicts Phase 33 D-03 (native/companion-owned roles) and orphans the POST routes. | |

**User's choice:** PaywallEntryLive + thin controllers
**Notes:** Keeps native-owned corridors from masquerading as Phoenix screens — consistent with the runtime-ownership thesis. Captured as D-06/D-07/D-08; verifier should evaluate Criterion #1 against the reinterpretation.

---

## Verification timing (escalated — affects :pending observability)

| Option | Description | Selected |
|--------|-------------|----------|
| Async (pending → then granted) | Ingest → broadcast :pending immediately; Task (small delay) runs MockBackend verification → broadcasts terminal state; both via handle_info. Proof calls the synchronous core directly. | ✓ |
| Synchronous (straight to granted) | Run the full pipeline inline, broadcast terminal state in one step; :pending only via dev button. Simpler but happy path never surfaces :pending. | |

**User's choice:** Async (pending → then granted)
**Notes:** Mirrors real backend webhook topology and makes the :pending branch genuinely reachable at runtime. Captured as D-04/D-05.

---

## Verification pipeline shape (decided from research + codebase, accepted in synthesis)

| Option | Description | Selected |
|--------|-------------|----------|
| Separate MockBackend context module | New plain-Elixir module owns build-snapshot → project_snapshot → derived_state → broadcast; LiveView and Phase 36 proof both call it (same code path). | ✓ |
| Inline in LiveView handle_event | No new module, but the hermetic proof cannot reach handle_event without a running server — violates the test constraint. | |

**User's choice:** Accepted recommendation (MockBackend)
**Notes:** Resolves the open STATE todo. Captured as D-01/D-02/D-03.

---

## Four-state UI + demo drivers (decided from research, accepted in synthesis)

| Option | Description | Selected |
|--------|-------------|----------|
| `case @derived_state` → four named function components | Exhaustive branch map; named components findable + individually readable; stale structurally distinct from denied; dev-only scenario buttons run real snapshots through derived_state/1. | ✓ |
| Inline case / shared flagged component / query-param demo | Collapse branches into a wall of markup, or drive demo states by directly assigning atoms — undermines the derivation thesis. | |

**User's choice:** Accepted recommendation
**Notes:** Captured as D-09..D-11, D-15. Detailed visual design optionally deferred to /gsd-ui-phase.

---

## PubSub topic & message contract (decided from research, accepted in synthesis)

| Option | Description | Selected |
|--------|-------------|----------|
| `"entitlement:" <> group_id` + atom-only message | Canonical Phoenix topic convention; subscribe in mount when connected?; message `{:entitlement_update, derived_state}` carries the atom only (no raw lane fields → STATE-01). Start Phoenix.PubSub in application.ex. | ✓ |

**User's choice:** Accepted recommendation
**Notes:** Captured as D-12/D-13/D-14. Resolves the Phase 33 PubSub-not-started prerequisite todo.

## Claude's Discretion

- MockBackend function names/signatures and per-state verified-snapshot field values.
- Task delay duration for the async pending→granted transition.
- Concrete `group_id` constant (anchored to `sub_pro_monthly`).
- Function-component names, HEEx markup, copy, CSS/visual treatment.
- CorridorController action response shape.

## Deferred Ideas

- Phase 36 merge-blocking hermetic full-lane proof (this phase provides the shared MockBackend path).
- Phase 37 `guides/commerce.md` walkthrough + docs-contract lock.
- Detailed four-state visual/UX polish — optional `/gsd-ui-phase`.
- Multi-product paywalls (AF-04, out of scope); real provider adapters (AF-01, v3.6).
