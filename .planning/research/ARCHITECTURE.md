# Architecture Research

**Domain:** Mocked-storefront paywall archetype integration (v3.4 Commerce Archetype Proof)
**Researched:** 2026-05-29
**Confidence:** HIGH — all findings grounded in committed source code and planning files; no external sources required.

---

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         EXAMPLE HOST LAYER                           │
│              examples/phoenix_host/lib/crosswake_example/            │
├────────────────────┬────────────────────┬───────────────────────────┤
│   Router (MODIFY)  │  PaywallLive (NEW) │  Paywall corridor routes  │
│   /paywall         │  /purchase_intent  │  wired via commerce: DSL  │
│   /purchase_intent │  /restore_intent   │                           │
│   /restore_intent  │  PaywallEntryLive  │                           │
├────────────────────┴────────────────────┴───────────────────────────┤
│                       MOCK ADAPTER LAYER (NEW)                       │
│            commerce/mock_storefront.ex  (example host only)          │
│                                                                      │
│  Consumes PurchaseIntent + RestoreIntent structs from Contracts.     │
│  Emits ReconciliationEvidence with source: :storefront.              │
│  Provider-neutral: provider field = "mock"; no real SDK code.        │
├──────────────────────────────────────────────────────────────────────┤
│                   BACKEND RECONCILIATION LAYER (EXISTING + EXTEND)   │
│  commerce/reconciliation_inbox.ex    (EXISTS — used as-is)           │
│  commerce/reconciliation_keys.ex     (EXISTS — used as-is)           │
│  commerce/entitlement_projection.ex  (EXISTS — used as-is)           │
├──────────────────────────────────────────────────────────────────────┤
│                        CROSSWAKE CORE LIBRARY                        │
│  Crosswake.Commerce.Contracts        (EXISTS — do not modify)        │
│  Crosswake.Commerce.Reconciliation   (EXISTS — do not modify)        │
│  Crosswake.Router DSL                (EXISTS — add commerce: routes) │
└──────────────────────────────────────────────────────────────────────┘

                             DATA FLOW
MockStorefront.simulate_purchase/1
    ↓  returns ReconciliationEvidence{source: :storefront, provider: "mock", ...}
ReconciliationInbox.ingest_evidence/2
    ↓  returns {:ok, attempt}  (status: :awaiting_verification, never grants authority)
[Host backend simulates verification — sets reconciliation to :projection_refreshed]
EntitlementProjection.project_snapshot/2
    ↓  returns {:ok, EntitlementSnapshot.t()}  (monotonic as_of, verified reconciliation)
EntitlementProjection.derived_state/1
    ↓  returns :stale | :pending | :denied | :granted
Phoenix.PubSub.broadcast/3
    ↓  {:entitlement_update, derived_state}
PaywallEntryLive.handle_info/2
    ↓  assign(socket, entitlement_state: derived_state)
```

---

## Component Boundaries

### Integration Points: New vs. Modified vs. Existing

| Component | Path | Status | Role |
|-----------|------|--------|------|
| `CrosswakeExample.Router` | `examples/phoenix_host/lib/crosswake_example/router.ex` | MODIFY | Add `/paywall` scope with three corridor routes |
| `CrosswakeExample.Commerce.MockStorefront` | `examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex` | NEW | Mock adapter; emits `ReconciliationEvidence` without provider SDK |
| `CrosswakeExample.Paywall.PaywallEntryLive` | `examples/phoenix_host/lib/crosswake_example/paywall/paywall_entry_live.ex` | NEW | LiveView for paywall display; subscribes to entitlement state via PubSub |
| `CrosswakeExample.Paywall.PurchaseIntentLive` | `examples/phoenix_host/lib/crosswake_example/paywall/purchase_intent_live.ex` | NEW | LiveView that calls MockStorefront, feeds evidence into ReconciliationInbox |
| `CrosswakeExample.Paywall.RestoreIntentLive` | `examples/phoenix_host/lib/crosswake_example/paywall/restore_intent_live.ex` | NEW | LiveView that calls MockStorefront restore path, feeds evidence into inbox |
| `CrosswakeExample.Commerce.ReconciliationInbox` | `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex` | EXISTING (unchanged) | Ingests evidence; returns attempt map; never grants authority |
| `CrosswakeExample.Commerce.EntitlementProjection` | `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex` | EXISTING (unchanged) | `derived_state/1` and `project_snapshot/2` are already correct and proven in phase21 |
| `CrosswakeExample.Commerce.ReconciliationKeys` | `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex` | EXISTING (unchanged) | `event_key/1`, `subject_key/2` for idempotency |
| `Crosswake.Commerce.Contracts` | `lib/crosswake/commerce/contracts.ex` | EXISTING (do not modify) | Canonical struct definitions consumed by the example host |
| `Crosswake.Commerce.Reconciliation` | `lib/crosswake/commerce/reconciliation.ex` | EXISTING (do not modify) | Outcome vocabulary; `ingest_evidence/2` is the reference contract |
| Hermetic proof test | `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` | NEW | Merge-blocking; drives full data layer without example-host runtime or PubSub |
| Advisory CI workflow | `.github/workflows/phase34-proof.yml` | NEW | Mirrors phase23-proof.yml two-job split; hermetic job + advisory placeholder |
| `guides/commerce.md` | `guides/commerce.md` | MODIFY | Add end-to-end paywall corridor walkthrough; docs-contract test locks it |

---

## Recommended Project Structure

```
examples/phoenix_host/lib/crosswake_example/
├── commerce/
│   ├── mock_storefront.ex          # NEW — mock adapter only; example/docs-only
│   ├── reconciliation_inbox.ex     # EXISTS — unchanged
│   ├── reconciliation_keys.ex      # EXISTS — unchanged
│   └── entitlement_projection.ex  # EXISTS — unchanged
├── paywall/
│   ├── paywall_entry_live.ex      # NEW — subscribes to entitlement state
│   ├── purchase_intent_live.ex    # NEW — triggers mock purchase path
│   └── restore_intent_live.ex     # NEW — triggers mock restore path
├── router.ex                      # MODIFY — add /paywall scope

test/crosswake/proof/
├── phase34_paywall_corridor_proof_test.exs  # NEW — hermetic merge-blocking
├── phase21_reconciliation_example_test.exs  # EXISTS — unchanged
├── phase23_commerce_support_proof_test.exs  # EXISTS — unchanged

.github/workflows/
├── phase34-proof.yml              # NEW — hermetic + advisory split
├── phase23-proof.yml              # EXISTS — unchanged

guides/
└── commerce.md                    # MODIFY — add paywall walkthrough section
```

### Structure Rationale

- **`commerce/`:** Groups all reconciliation plumbing. `mock_storefront.ex` belongs here (not in `paywall/`) because it is the adapter layer, not a UI layer. This mirrors how a real StoreKit adapter would be organized by an adopter. Keeping it adjacent to the existing inbox/projection/keys files makes the adoption pattern explicit.
- **`paywall/`:** A dedicated namespace for corridor LiveViews mirrors how `saas_portal/` and `selective_native/` are organized in the existing example host. Route owners live next to their corridor declaration context.
- **No GenServer or ETS for v3.4:** The proof is hermetic-first. `EntitlementProjection` stays a pure-function module. LiveViews hold in-socket state derived from `EntitlementProjection.derived_state/1`. A persistent state process is a valid adopter extension but is not required by this proof and would add non-hermetic scope.

---

## Architectural Patterns

### Pattern 1: MockStorefront as a Thin Evidence Emitter

**What:** `MockStorefront` is a single pure-function module with two public functions: `simulate_purchase/1` (takes `PurchaseIntent.t()`) and `simulate_restore/1` (takes `RestoreIntent.t()`). Both return `{:ok, %ReconciliationEvidence{}}`. The mock sets `provider: "mock"` and derives `provider_reference` deterministically from the intent's `entry_id` or `correlation_id`. No external calls, no processes.

**When to use:** In example-host LiveViews and the hermetic proof test. In real adopter apps, `MockStorefront` is replaced by a StoreKit or Play Billing adapter that emits the same `ReconciliationEvidence` contract struct. The rest of the pipeline (inbox, projection, LiveView) is identical.

**Why this shape preserves the non-authoritative boundary:** `ReconciliationEvidence` is the struct boundary between storefront and Phoenix. It structurally cannot express authority — there are no authority or access fields. Downstream modules (`ReconciliationInbox`, `EntitlementProjection`) behave identically whether evidence came from the mock or a real storefront. `Crosswake.Commerce.Reconciliation.authority_mutation_allowed_from_evidence?/1` returns `false` unconditionally as the contract-level guard.

**Example:**
```elixir
defmodule CrosswakeExample.Commerce.MockStorefront do
  alias Crosswake.Commerce.Contracts.{PurchaseIntent, RestoreIntent, ReconciliationEvidence}

  @provider "mock"

  @spec simulate_purchase(PurchaseIntent.t()) :: {:ok, ReconciliationEvidence.t()}
  def simulate_purchase(%PurchaseIntent{entry_id: entry_id, correlation_id: correlation_id}) do
    {:ok, %ReconciliationEvidence{
      source: :storefront,
      provider: @provider,
      provider_reference: "mock-purchase-#{entry_id}",
      event_kind: "purchase",
      evidence_ref: "mock-evidence-#{correlation_id}",
      captured_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      integrity_digest: nil,
      idempotency_ref: correlation_id
    }}
  end

  @spec simulate_restore(RestoreIntent.t()) :: {:ok, ReconciliationEvidence.t()}
  def simulate_restore(%RestoreIntent{correlation_id: correlation_id}) do
    {:ok, %ReconciliationEvidence{
      source: :storefront,
      provider: @provider,
      provider_reference: "mock-restore-#{correlation_id}",
      event_kind: "restore",
      evidence_ref: "mock-restore-evidence-#{correlation_id}",
      captured_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      integrity_digest: nil,
      idempotency_ref: correlation_id
    }}
  end
end
```

**Critical constraints:**
- `MockStorefront` must live in `examples/phoenix_host/`, not in `lib/`. It is example/docs-only per the capability taxonomy. Putting it in `lib/` would ship it to hex.pm as part of the Crosswake library.
- The hermetic proof test does NOT import `CrosswakeExample.MockStorefront`. It constructs `ReconciliationEvidence` directly (same as phase21 proof constructs evidence inline). The `:requires_example_host` tagged test loads it via `Code.require_file` as phase21 does.

---

### Pattern 2: Paywall Corridor Route Policy Declaration

**What:** Three routes in a new `/paywall` scope, each with a `commerce:` key matching the canonical corridor vocabulary from `Crosswake.SupportMatrix.commerce_corridors/0`. The corridor role values must exactly match the support matrix atoms `:paywall_entry`, `:purchase_intent`, `:restore_intent`.

**When to use:** This is the only correct shape. The `commerce:` DSL key is already wired to manifest compilation and doctor output. Incorrect role atoms will fail corridor checks.

**Example (addition to router.ex):**
```elixir
scope "/paywall", CrosswakeExample.Paywall do
  pipe_through [:browser]

  crosswake_defaults runtime: :live_view, offline: :unavailable, security: :sensitive do
    live "/", PaywallEntryLive,
      crosswake: [
        id: "paywall-entry",
        runtime: :live_view,
        commerce: [corridor: :subscription_default, role: :paywall_entry]
      ]

    live "/purchase", PurchaseIntentLive,
      crosswake: [
        id: "paywall-purchase-intent",
        runtime: :native_screen,
        commerce: [corridor: :subscription_default, role: :purchase_intent]
      ]

    live "/restore", RestoreIntentLive,
      crosswake: [
        id: "paywall-restore-intent",
        runtime: :native_screen,
        commerce: [corridor: :subscription_default, role: :restore_intent]
      ]
  end
end
```

**Rationale for `runtime: :native_screen` on purchase/restore:** The support matrix declares `purchase_intent` and `restore_intent` as `native_or_companion_required`. Using `:native_screen` is semantically correct — it signals the storefront execution is native-side. The mock simulates that evidence path from Phoenix for proof purposes; the runtime declaration is not changed by the mock.

**Rationale for `offline: :unavailable`:** Commerce routes must not cache or degrade silently. Fail-closed posture matches the corridor denial vocabulary (`commerce.corridor.prerequisite_missing`, etc.).

---

### Pattern 3: LiveView Entitlement State Subscription

**What:** `PaywallEntryLive` subscribes to a PubSub topic on mount and receives `{:entitlement_update, derived_state}` messages. The assign `@entitlement_state` holds one of `:stale | :pending | :denied | :granted`. `render/1` pattern-matches on it.

**When to use:** This is the mechanism that closes the end-to-end proof: mock purchase emits evidence → inbox ingests → projection derives state → PubSub broadcast → LiveView assigns update.

**Why not a GenServer for v3.4:** A persistent state process is a valid adopter implementation choice, but adds non-hermetic scope that the proof does not need. The hermetic lane calls `EntitlementProjection.derived_state/1` directly on constructed snapshots. The `:requires_example_host` integration test drives the LiveView assign-update path by triggering `PurchaseIntentLive` actions and asserting `PaywallEntryLive`'s socket assigns update.

**Example (PaywallEntryLive skeleton):**
```elixir
def mount(_params, _session, socket) do
  if connected?(socket), do: Phoenix.PubSub.subscribe(CrosswakeExample.PubSub, "entitlement")
  {:ok, assign(socket, entitlement_state: :stale)}
end

def handle_info({:entitlement_update, derived_state}, socket) do
  {:noreply, assign(socket, entitlement_state: derived_state)}
end
```

**Projection precedence (from existing `EntitlementProjection.derived_state/1` — do not reimplement):**
1. freshness `:stale` or `:unknown` — returns `:stale` (fail-closed)
2. reconciliation in `[:pending_purchase, :pending_restore, :awaiting_verification]` — returns `:pending`
3. freshness `:fresh`, reconciliation `:projection_refreshed`, authority in grantable states, access `:granted` — returns `:granted`
4. all other resolved outcomes — returns `:denied`

This function already exists and is proven correct in phase21. Do not reimplement it.

---

### Pattern 4: Hermetic Proof Test Structure (mirrors phase23)

**What:** The merge-blocking proof test uses inline router fixture modules (as phase23 does), never imports `CrosswakeExample.Router` or loads any example-host file via `Code.require_file`, makes no network calls, starts no processes.

**Key assertions the hermetic lane must drive:**
1. A router with `commerce: [corridor: :subscription_default, role: :paywall_entry]` compiles and the route appears in the manifest with correct corridor metadata.
2. A `ReconciliationEvidence` struct with `source: :storefront, provider: "mock", event_kind: "purchase"` validates against `Crosswake.Commerce.Contracts` (no error from `canonical_reconciliation_evidence_source/1`).
3. `ReconciliationInbox.ingest_evidence/2` returns `{:ok, attempt}` where `attempt.status == :awaiting_verification` and the attempt map has no authority or access fields.
4. `Crosswake.Commerce.Reconciliation.authority_mutation_allowed_from_evidence?/1` returns `false` for any `ReconciliationEvidence`.
5. `EntitlementProjection.derived_state/1` returns `:stale` for a snapshot with freshness `:stale` or `:unknown`.
6. `EntitlementProjection.derived_state/1` returns `:pending` for a snapshot with reconciliation `:awaiting_verification` and fresh freshness.
7. `EntitlementProjection.project_snapshot/2` promotes a snapshot to `{:ok, snapshot}` when given `:projection_refreshed` reconciliation + `:active` authority + `:granted` access + fresh freshness + monotonic `as_of`.
8. `EntitlementProjection.derived_state/1` returns `:granted` for that promoted snapshot.
9. Provider-vocabulary fence: the proof test's own source must not contain "storekit", "play_billing", "play billing", or "revenuecat".

The `:requires_example_host` tagged test (run in the CI example-host lane, not the hermetic lane) loads MockStorefront via `Code.require_file` and drives the full LiveView assign-update path.

---

## Data Flow

### Full Purchase Flow (Mock Corridor)

```
[User views PaywallEntryLive — @entitlement_state: :stale on mount]
    ↓ (user taps "Subscribe" → navigate to /paywall/purchase)
[PurchaseIntentLive mounts]
    ↓ builds PurchaseIntent{entry_id: "pro", correlation_id: UUID}
[MockStorefront.simulate_purchase/1]
    ↓ {:ok, %ReconciliationEvidence{
         source: :storefront, provider: "mock",
         event_kind: "purchase", provider_reference: "mock-purchase-pro", ...}}
[ReconciliationInbox.ingest_evidence/2]
    ↓ {:ok, %{source: :storefront, status: :awaiting_verification,
              event_key: "event::mock::mock-purchase-pro::purchase::...",
              subject_key: "subject::mock::mock-purchase-pro",
              replay?: false, ...}}
    ↓ (status is :awaiting_verification — no authority or access fields set)
[Host backend verification step — in example: inline, in production: worker/job]
    ↓ builds EntitlementSnapshot with:
         authority: %AuthorityLane{state: :active}
         access: %AccessLane{decision: :granted}
         reconciliation: %ReconciliationLane{state: :projection_refreshed}
         freshness: %FreshnessLane{state: :fresh, checked_at: now}
         evidence: %EvidenceLane{source: :storefront, reference: attempt.event_key}
         as_of: System.monotonic_time()
[EntitlementProjection.project_snapshot/2]
    ↓ {:ok, %EntitlementSnapshot{...}}  (monotonic as_of passes)
[EntitlementProjection.derived_state/1]
    ↓ :granted
[Phoenix.PubSub.broadcast(CrosswakeExample.PubSub, "entitlement", {:entitlement_update, :granted})]
    ↓
[PaywallEntryLive.handle_info({:entitlement_update, :granted}, socket)]
    ↓ assign(socket, entitlement_state: :granted)
[LiveView renders "Access granted" UI state]
```

### Full Restore Flow (Mock Corridor)

```
[User taps "Restore Purchases" on PaywallEntryLive]
    ↓ (navigate to /paywall/restore)
[RestoreIntentLive mounts]
    ↓ builds RestoreIntent{correlation_id: UUID}
[MockStorefront.simulate_restore/1]
    ↓ {:ok, %ReconciliationEvidence{event_kind: "restore", source: :storefront, provider: "mock", ...}}
[ReconciliationInbox.ingest_evidence/2]
    ↓ {:ok, %{status: :awaiting_verification, ...}}
— same projection path as purchase from this point forward —
→ derived_state → :granted → broadcast → LiveView assign update
```

### Stale and Denied States (LiveView reflects correctly)

```
Initial PaywallEntryLive mount:
    entitlement_state: :stale
    (fail-closed default; no snapshot yet)

After ReconciliationInbox.ingest_evidence, before backend verification:
    reconciliation.state == :awaiting_verification
    → EntitlementProjection.derived_state → :pending
    → broadcast → LiveView renders "Purchase processing..." UI

After verification_failed (unknown event kind or integrity failure):
    reconciliation.state == :verification_failed
    access.decision == :denied
    → derived_state → :denied
    → broadcast → LiveView renders "Access denied" UI

Out-of-order as_of update rejected by project_snapshot/2:
    {:error, {:stale_authority, snapshot}}
    reconciliation.state set to :stale_authority on returned snapshot
    → derived_state(stale_authority_snapshot) → :denied
```

---

## Build Order

The following order respects module dependencies and the proof-before-wiring discipline established by prior milestones.

**Step 1 — Route policy (router.ex modification)**
Add the `/paywall` scope with three corridor routes. This is the contract anchor — the manifest, doctor output, and proof test fixtures all derive from this corridor declaration. Do this first so all downstream assertions have a concrete router to reference.

**Step 2 — MockStorefront adapter**
Implement `CrosswakeExample.Commerce.MockStorefront` with `simulate_purchase/1` and `simulate_restore/1`. No persistence, no process, pure functions. Depends only on `Crosswake.Commerce.Contracts` which already exists. Can be written and manually verified in isolation.

**Step 3 — Paywall LiveViews (scaffold level)**
Create `PaywallEntryLive`, `PurchaseIntentLive`, `RestoreIntentLive` with minimal renders and the `@entitlement_state` assign structure. At this step they do not need PubSub wiring — the hermetic proof drives the data layer directly.

**Step 4 — Hermetic proof test (merge-blocking lane)**
Write `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs`. Use inline router fixtures as phase23 does; no `CrosswakeExample.Router` import. Prove all assertions listed in Pattern 4 above. This test must pass before Step 5 (wiring) is considered done, because it validates the data layer independently of any runtime or process dependency.

**Step 5 — Wire LiveViews to inbox → projection → PubSub**
Connect `PurchaseIntentLive` to call `MockStorefront.simulate_purchase/1` → `ReconciliationInbox.ingest_evidence/2` → simulate backend verification → `EntitlementProjection.project_snapshot/2` → `Phoenix.PubSub.broadcast`. Wire `PaywallEntryLive` to subscribe and update `@entitlement_state`. Connect `RestoreIntentLive` to the restore path.

**Step 6 — Example-host integration test**
Write the `:requires_example_host` tagged test. It loads example modules via `Code.require_file` (same as phase21), drives the full corridor, and asserts LiveView assign transitions through `:stale → :pending → :granted`. This runs in the existing CI example-host lane (phase5-proof.yml) under the `:requires_example_host` tag, not in the hermetic merge-blocking lane.

**Step 7 — CI workflow**
Add `.github/workflows/phase34-proof.yml` mirroring `phase23-proof.yml`:
- `merge-blocking-paywall-corridor-proof`: runs hermetic proof test on PR and push to main; `if: github.event_name == 'pull_request' || ...`; no network, no processes.
- `advisory-paywall-corridor-proof`: placeholder for future real StoreKit/Play Billing corridor validation; runs on schedule with `continue-on-error: true`; never gates merge.

**Step 8 — guides/commerce.md update and docs-contract test**
Add a "Paywall Corridor Walkthrough" section to `guides/commerce.md`. Extend `test/crosswake/guides/commerce_test.exs` to assert the new section is present and that walkthrough references match the actual example module names. This locks the guide against implementation drift.

---

## Anti-Patterns

### Anti-Pattern 1: MockStorefront That Grants Authority Directly

**What people do:** Set `authority_state: :active` or `access_decision: :granted` inside `MockStorefront`, bypassing `ReconciliationInbox` and `EntitlementProjection`.

**Why it's wrong:** This violates ENTL-03 (device/storefront evidence cannot directly grant authority) and breaks the proof. The value of the hermetic lane is demonstrating that the inbox → projection path is the only authority path. A mock that short-circuits the path proves nothing and teaches adopters the wrong architecture.

**Do this instead:** `MockStorefront` returns only `ReconciliationEvidence`. Authority is set only when `EntitlementProjection.project_snapshot/2` is called with a verified snapshot (reconciliation state `:projection_refreshed`). The hermetic proof asserts `authority_mutation_allowed_from_evidence?/1` returns `false`.

---

### Anti-Pattern 2: Placing MockStorefront in `lib/`

**What people do:** Create `lib/crosswake/commerce/mock_storefront.ex` so it is available to the hermetic proof test without `Code.require_file`.

**Why it's wrong:** MockStorefront is example/docs-only per the capability taxonomy. Putting it in `lib/` ships it on hex.pm as part of the Crosswake library — a provider-specific concern polluting the core package boundary.

**Do this instead:** Place it in `examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex`. The hermetic proof test constructs `ReconciliationEvidence` structs directly (no `MockStorefront` import needed). The `:requires_example_host` tagged test loads `MockStorefront` via `Code.require_file` as phase21 does with the existing reconciliation modules.

---

### Anti-Pattern 3: Storing Entitlement Truth in LiveView Socket State Only

**What people do:** Treat the `@entitlement_state` socket assign as the authoritative entitlement store. On LiveView reconnect, there is no snapshot to restore from.

**Why it's wrong:** Backend-owned truth means the LiveView is a read model, not the authority store. A LiveView that silently reverts to `:stale` on remount is correct by contract (fail-closed), but a LiveView that "remembers" a prior `:granted` in socket state without re-deriving from a backend snapshot is not.

**Do this instead:** LiveView initializes to `:stale` on mount (correct fail-closed posture). State transitions happen only through the inbox → projection → broadcast path. The proof asserts initial state is `:stale` and that `:granted` can only be reached after a full reconciliation chain.

---

### Anti-Pattern 4: Adding v3.4 Assertions to the Phase23 Proof File

**What people do:** Append paywall-corridor assertions to `phase23_commerce_support_proof_test.exs` to avoid creating a new file.

**Why it's wrong:** Phase 23 is a stable shipped proof that gates v3.2 claims. Mixing v3.4 corridor proof blurs requirements-to-proof traceability. If the v3.4 paywall proof needs rework, v3.2 claims should not be affected by the edit.

**Do this instead:** New file `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` with its own inline fixtures and `@moduletag`. New CI workflow `phase34-proof.yml` mirroring the two-job split from `phase23-proof.yml`.

---

## Integration Points

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| `MockStorefront` → `ReconciliationInbox` | Direct function call; caller passes `ReconciliationEvidence` struct | No process boundary; both pure-function modules in example host |
| `ReconciliationInbox` → `EntitlementProjection` | Direct function call by host LiveView | `ReconciliationInbox.ingest_evidence/2` returns an attempt map; the caller constructs the `EntitlementSnapshot` for projection — the inbox does not directly call the projection |
| `EntitlementProjection` → `PaywallEntryLive` | `Phoenix.PubSub.broadcast/3` → `handle_info/2` | In hermetic proof: `derived_state/1` called directly on constructed snapshots; PubSub wiring validated in `:requires_example_host` tagged test |
| `CrosswakeExample.Router` → Crosswake core | `commerce:` DSL key at compile time → `Crosswake.Policy.Compiler.compile/2` → manifest | Router modification is the only required Crosswake-core integration point; no runtime callbacks added |
| Hermetic proof → example modules | Inline structs only; no `Code.require_file` for example-host files | Mirrors phase23 hermeticity guard exactly |
| `:requires_example_host` test → example modules | `Code.require_file` for mock_storefront, reconciliation_inbox, entitlement_projection | Mirrors phase21 pattern exactly |

### What the Mock Boundary Does Not Cross

| Boundary | Reason |
|----------|--------|
| MockStorefront → StoreKit / Play Billing SDK | No SDK calls; `simulate_purchase/1` is deterministic and in-process |
| MockStorefront → any network | No HTTP, no port, no `:gen_tcp`; hermetic by construction |
| `ReconciliationEvidence` → authority lanes | Struct has no authority or access fields; `authority_mutation_allowed_from_evidence?/1` returns `false` unconditionally |
| LiveView socket → entitlement authority | Socket holds derived read state only; `EntitlementProjection` owns the source-of-truth determination |
| Mock evidence → idempotency authority | `idempotency_ref` in mock evidence is a `correlation_id` which is trace-only per RECN-02; real idempotency identity is `event_key` derived from `provider + provider_reference + event_kind + evidence_ref` |

---

## Confidence Assessment

| Area | Confidence | Basis |
|------|------------|-------|
| MockStorefront shape | HIGH | Derived directly from `ReconciliationEvidence` struct in `contracts.ex:150-183`; source: `:storefront` is a canonical vocabulary atom |
| Router corridor DSL | HIGH | Copied from phase23 fixture routers (`PaywallCorridorRouter`, `PurchaseCorridorRouter`) which already use `commerce: [corridor: :subscription_default, role: :paywall_entry]` and are proven in CI |
| ReconciliationInbox reuse | HIGH | `phase21_reconciliation_example_test.exs` proves inbox against all four evidence sources with no changes needed; function signatures match exactly |
| EntitlementProjection reuse | HIGH | `derived_state/1` and `project_snapshot/2` are proven in phase21; the four state branches exactly match v3.4 LiveView requirements |
| LiveView PubSub pattern | HIGH | Standard Phoenix LiveView pattern; no Crosswake-specific constraint; scope limited to example host |
| Hermetic proof structure | HIGH | phase23 provides the exact template including the hermeticity guard self-check; replication is mechanical |
| Build order | HIGH | Dependency graph is explicit; proof-before-wiring matches established milestone discipline |

---

## Sources

- `/Users/jon/projects/crosswake/lib/crosswake/commerce/contracts.ex` — `ReconciliationEvidence`, `PurchaseIntent`, `RestoreIntent`, `EntitlementSnapshot` struct definitions
- `/Users/jon/projects/crosswake/lib/crosswake/commerce/reconciliation.ex` — `ingest_evidence/2`, `authority_mutation_allowed_from_evidence?/1`, outcome vocabulary
- `/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex` — existing inbox implementation
- `/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex` — existing `derived_state/1` and `project_snapshot/2`
- `/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex` — `event_key/1`, `subject_key/2`
- `/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/router.ex` — existing router DSL patterns and corridor fixture shape
- `/Users/jon/projects/crosswake/test/crosswake/proof/phase23_commerce_support_proof_test.exs` — hermetic proof template, hermeticity guard, inline fixture router pattern
- `/Users/jon/projects/crosswake/test/crosswake/proof/phase21_reconciliation_example_test.exs` — `:requires_example_host` test pattern with `Code.require_file`
- `/Users/jon/projects/crosswake/.github/workflows/phase23-proof.yml` — two-job hermetic + advisory CI split reference
- `/Users/jon/projects/crosswake/.planning/threads/commerce-archetype-proof.md` — milestone scope, references, build steps
- `/Users/jon/projects/crosswake/.planning/PROJECT.md` — locked guardrails, capability taxonomy, ENTL-03 requirement
- `/Users/jon/projects/crosswake/.planning/MILESTONE-ARC.md` — non-goals (no StoreKit/Play Billing), proof requirements for v3.4
- `/Users/jon/projects/crosswake/guides/commerce.md` — canonical corridor ownership table, authority-vs-evidence contract, reconciliation flow

---

*Architecture research for: v3.4 Commerce Archetype Proof — mocked paywall corridor integration*
*Researched: 2026-05-29*
