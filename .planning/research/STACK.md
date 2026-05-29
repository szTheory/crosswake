# Stack Research

**Domain:** Hermetic mocked-storefront paywall archetype example (v3.4)
**Researched:** 2026-05-29
**Confidence:** HIGH

## Verdict: No New Dependencies Required

The paywall corridor example can be built entirely with what is already in
`examples/phoenix_host/mix.exs`. Every new file is pure Elixir wired through
existing contracts. The only decisions are about *which existing pieces to use
and how*, not about adding deps.

---

## Existing Stack (What We Already Have)

### Core Technologies in examples/phoenix_host

| Technology | Pinned Range | Current Stable | Purpose | Status |
|------------|-------------|----------------|---------|--------|
| `crosswake` | `path: "../.."` | n/a (local) | Route policy DSL, commerce contracts, reconciliation primitives | Already ships `Contracts`, `Reconciliation` used directly by paywall lane |
| `phoenix` | `~> 1.8` | 1.8.7 | HTTP routing, Plug pipelines, controller/LiveView host | Already wires all existing exemplar lanes |
| `phoenix_live_view` | `~> 1.1` | 1.1.31 (stable); 1.2.0-rc.3 (preview) | Server-rendered reactive UI, socket assigns, `handle_event` | Pattern proven by SaaS approvals lane and study session lane |
| `ecto_sql` | `~> 3.10` | 3.12.x | Schema, changeset, query layer for SQLite | Already used for claims/submissions in selective_native lane |
| `ecto_sqlite3` | `~> 0.16` | 0.24.0 | SQLite adapter; no external DB process needed | Already wired via `CrosswakeExample.Repo` |
| `jason` | `~> 1.4` | 1.4.x | JSON codec for evidence payloads, doc-contract tests | Already present |
| `plug` | `~> 1.16` | 1.16.x | Conn/pipeline plumbing, controller for intent endpoints | Already present |

Versions verified against hex.pm API on 2026-05-29. All dep ranges in the
existing `mix.exs` accommodate current stable releases with no changes required.

### Existing Commerce Infrastructure (Already Shipped in v3.2)

These files exist in `examples/phoenix_host/lib/crosswake_example/commerce/` and are
already exercised by the Phase 21 proof test. They are the foundation for v3.4 — not
new additions.

| File | What It Does |
|------|-------------|
| `reconciliation_keys.ex` | `event_key/1`, `subject_key/2`, `trace_metadata/2` — provider-aware identity helpers |
| `reconciliation_inbox.ex` | `ingest_evidence/2` — append-only evidence ingestion, replay detection |
| `entitlement_projection.ex` | `project_snapshot/2`, `derived_state/1` — snapshot projection and state derivation (`:stale`, `:pending`, `:denied`, `:granted`) |

---

## What v3.4 Adds (New Files, Zero New Deps)

All new artifacts are plain Elixir modules that consume the existing contract types.

### MockStorefront Module

New file: `examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex`
Module: `CrosswakeExample.Commerce.MockStorefront`

Accepts a `PurchaseIntent` or `RestoreIntent` struct (both already defined in
`Crosswake.Commerce.Contracts`) and returns a `ReconciliationEvidence` struct with
`source: :storefront`, `provider: "mock"`, and a deterministic `event_kind`
(`"purchase"` or `"restore"`). No network call, no SDK, no NIF — pure struct
construction.

Why no new dep: `ReconciliationEvidence` is already a typed struct in
`lib/crosswake/commerce/contracts.ex`. The mock just builds one with known values.
The existing `ReconciliationInbox.ingest_evidence/2` handles the downstream path.
There is no behavior to simulate beyond "return a plausible evidence struct."

### Router Additions

Three new routes added to the existing
`examples/phoenix_host/lib/crosswake_example/router.ex` under a `/commerce` scope:

- `GET /commerce/paywall` — `PaywallLive` with `commerce: [corridor: :subscription_default, role: :paywall_entry]` policy. Reflects entitlement state from socket assigns.
- `POST /commerce/purchase_intent` — Controller action: `MockStorefront.purchase/1` → `ReconciliationInbox.ingest_evidence/2` → `EntitlementProjection.project_snapshot/2` → assigns result.
- `POST /commerce/restore_intent` — Same pipeline, `RestoreIntent` path.

Why no new dep: Existing `Crosswake.Router` `crosswake_defaults` DSL already supports
the `commerce:` corridor keyword (shipped in v3.2). Existing `phoenix` router `scope`,
`live`, and `post` macros cover everything.

### PaywallLive LiveView

New file: `examples/phoenix_host/lib/crosswake_example/commerce/paywall_live.ex`
Module: `CrosswakeExample.Commerce.PaywallLive`

Standard LiveView `mount`, `handle_event`, `assign/3` to reflect entitlement state.
`EntitlementProjection.derived_state/1` (already exists) returns `:stale | :pending |
:denied | :granted`; the LiveView assigns that atom and renders the appropriate paywall
or content gate. Pattern is identical to `ApprovalsLive` (status from Ecto context)
and `StudySessionLive` (local state via assigns).

Why no new dep: `Phoenix.LiveView` `assign/3` and `handle_event/3` cover all needed
state transitions. No PubSub subscription is needed — the hermetic proof drives the
full round trip synchronously through controller actions and explicit `assign` calls,
not real-time broadcast.

### Optional: Entitlement State Persistence

If the example also shows persistence across page refreshes: add a minimal
`CommerceEntitlement` Ecto schema backed by the existing SQLite repo — same pattern
as `selective_native/claim.ex`. This is optional for the hermetic proof; the proof
test can drive everything through in-memory socket state.

Why no new dep: `ecto_sql` and `ecto_sqlite3` are already in the example host.

### Hermetic Proof Test

New file: `test/crosswake/proof/phase34_paywall_lane_test.exs`

Follows the established `Code.require_file` pattern from Phase 21:

```elixir
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex", __DIR__)
# reconciliation_keys.ex, reconciliation_inbox.ex, entitlement_projection.ex
# already loaded by phase21 test or repeated here
```

The test drives the full lane:
1. `MockStorefront.purchase/1` returns `%ReconciliationEvidence{source: :storefront, event_kind: "purchase", ...}`
2. `ReconciliationInbox.ingest_evidence/2` returns `{:ok, %{status: :awaiting_verification, ...}}`
3. Caller builds incoming `EntitlementSnapshot` with `reconciliation.state: :projection_refreshed` and `authority.state: :active`
4. `EntitlementProjection.project_snapshot/2` returns `{:ok, snapshot}`
5. `EntitlementProjection.derived_state/1` returns `:granted`

Separate assertions: `:pending` after ingest before projection; restore path also
yields `:granted` after projection; provider-token fence (no `"storekit"`,
`"play_billing"`, `"revenuecat"` in any example file).

Why no new dep: `ExUnit.Case` is stdlib. Same hermetic pattern as Phase 21 and Phase
23. No `Phoenix.ConnTest`, no `LiveViewTest`, no running endpoint needed. The proof
is pure function composition over typed structs.

---

## What NOT to Add

| Do Not Add | Why |
|------------|-----|
| StoreKit SDK, Play Billing SDK, revenue_cat, or any billing provider dep | Out of scope by contract. v3.4 is explicitly mocked only. Provider adapters are v3.6. |
| `Phoenix.LiveViewTest` / `ConnTest` | The hermetic proof operates at the function level, not HTTP/WebSocket. Adds running endpoint complexity without improving proof quality. |
| `mox` or any mock library | `MockStorefront` is a hand-written deterministic module, not a behavior mock. No mock framework needed. |
| `Phoenix.PubSub` | The example host does not currently start PubSub. The hermetic proof does not require broadcast. If added later for UX polish it requires supervising a PubSub server — scope creep. |
| HEEx component libraries (Surface, LiveSvelte, etc.) | Plain `~H` sigil is sufficient for a copy-able adopter example. A UI component dep obscures the commerce architecture. |
| Any new Hex package | Everything needed is already present. Adding a dep to an OSS example that real adopters copy expands the install surface with zero benefit. |
| Ecto migrations for the paywall (as a proof requirement) | Optional for UX polish; not required for merge-blocking proof. If added, use the existing repo — do not introduce a second DB. |

---

## Integration Points with Existing Stack

| Integration | Mechanism | File(s) |
|-------------|-----------|---------|
| `MockStorefront` → `ReconciliationInbox` | `MockStorefront.purchase/1` returns `%ReconciliationEvidence{}` → passed directly to `ReconciliationInbox.ingest_evidence/2` | mock_storefront.ex (new) → reconciliation_inbox.ex (exists) |
| `ReconciliationInbox` → `EntitlementProjection` | `ingest_evidence/2` returns `{:ok, attempt}` → caller builds incoming `EntitlementSnapshot` → `EntitlementProjection.project_snapshot/2` | reconciliation_inbox.ex (exists) → entitlement_projection.ex (exists) |
| `EntitlementProjection` → `PaywallLive` | `derived_state/1` called in LiveView/controller; result assigned via `assign(socket, :entitlement_state, state)` | entitlement_projection.ex (exists) → paywall_live.ex (new) |
| Router corridor declaration | `commerce: [corridor: :subscription_default, role: :paywall_entry]` — valid `Crosswake.Router` option since v3.2 | router.ex (extend existing) |
| Proof test → example files | `Code.require_file` pattern established in Phase 21; new proof loads mock_storefront.ex additionally | phase34_paywall_lane_test.exs (new) |

---

## Alternatives Considered

| Considered | Decision | Rationale |
|------------|----------|-----------|
| `Phoenix.LiveViewTest` for proof | Rejected | Requires a running endpoint and compiled Plug router. The hermetic proof needs only function-level assertions over typed structs. `Code.require_file` + `ExUnit` is sufficient and follows the established Phase 21 pattern. |
| GenServer-based entitlement store | Rejected | Adds a supervised process, restart semantics, and test isolation complexity. Socket assigns are sufficient for the hermetic proof; Ecto is sufficient for the demo UX. A GenServer would imply a singleton entitlement server, conflicting with the multi-user reality real adopters have. |
| PubSub for real-time entitlement update | Deferred | Architecturally correct for real adopters but not needed for the hermetic proof. Adds application supervision complexity. Can be documented as the "next step" in guides/commerce.md without implementing in v3.4. |
| Separate `mix.exs` package for the mock storefront | Rejected | The mock is example-only; it belongs in the example host source tree, not as a published Hex dep. |

---

## Sources

- Verified from source: `examples/phoenix_host/mix.exs` — complete existing dep tree
- Verified from source: `lib/crosswake/commerce/contracts.ex` — `PurchaseIntent`, `RestoreIntent`, `ReconciliationEvidence`, `EntitlementSnapshot` typed structs
- Verified from source: `lib/crosswake/commerce/reconciliation.ex` — `ingest_evidence/2` signature
- Verified from source: `examples/phoenix_host/lib/crosswake_example/commerce/` — three existing commerce modules (reconciliation_keys, reconciliation_inbox, entitlement_projection)
- Verified from source: `test/crosswake/proof/phase21_reconciliation_example_test.exs` — `Code.require_file` hermetic proof pattern
- Verified from source: `test/crosswake/proof/phase23_commerce_support_proof_test.exs` — hermetic-vs-advisory lane split and provider-token fence pattern
- hex.pm API (2026-05-29): phoenix 1.8.7, phoenix_live_view 1.1.31 / 1.2.0-rc.3, ecto_sqlite3 0.24.0 — confirmed current stable releases
- Context7 `/phoenixframework/phoenix_live_view` — `assign/3`, `handle_event/3` patterns confirmed (HIGH confidence)

---
*Stack research for: v3.4 Commerce Archetype Proof — mocked-storefront paywall example*
*Researched: 2026-05-29*
