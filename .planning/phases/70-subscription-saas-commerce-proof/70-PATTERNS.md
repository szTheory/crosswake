# Phase 70: Subscription SaaS Commerce Proof - Pattern Map

**Mapped:** 2026-06-04
**Phase:** 70 - subscription-saas-commerce-proof
**Output role:** planner implementation analogs only

## Scope Extracted From Context And Research

Phase 70 needs a deterministic, CI-hermetic subscription SaaS proof lane over the existing commerce contracts. The required implementation surface is narrow:

1. Create `test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs`.
2. Optionally add a deterministic verifier helper under `examples/phoenix_host/lib/crosswake_example/commerce/` if `MockBackend.build_verified_snapshot/2` is too grant-only or nondeterministic for the adversarial matrix.
3. Create `.github/workflows/phase70-proof.yml`.
4. Optionally make narrow `examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex` updates only for truth-preserving status/copy/accessibility polish.
5. Do not edit implementation files outside those surfaces during proof planning.

The phase must prove SAAS-01 and SAAS-02: StoreKit/Play Billing-shaped purchase and restore evidence flows through the example-host facade, inbox, backend verification/projection, and Paywall state without storefront/device/client success directly granting entitlement authority.

## Target File Patterns

### `test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs`

**Role:** merge-blocking hermetic ExUnit proof.

**Data flow to prove:**

`PurchaseIntent` or `RestoreIntent` -> `ProviderAdapterStorefront` or `MockStorefront` -> `%ReconciliationEvidence{}` -> `ReconciliationInbox.ingest_evidence/2` -> pending/awaiting verification -> rejected direct projection -> deterministic backend verified `%EntitlementSnapshot{}` -> `EntitlementProjection.project_snapshot/2` -> `derived_state/1`.

**Closest analogs:**

- `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs`
- `test/crosswake/proof/phase48_provider_adapter_proof_test.exs`
- `test/crosswake/proof/phase34_mock_storefront_test.exs`

**Exact require-file shape to reuse and extend:**

```elixir
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex", __DIR__)
```

Phase 70 will likely need the Phase 48 broader set:

```elixir
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/storefront_adapter.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/provider_adapter_storefront.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex", __DIR__)
```

If a new deterministic verifier is added, include only that pure commerce file in the same pattern. Keep the self-scan allowlist updated to exactly the pure modules required.

**ExUnit module shape:**

```elixir
defmodule Crosswake.Proof.Phase70SubscriptionSaasCommerceProofTest do
  use ExUnit.Case, async: false

  alias Crosswake.Commerce.Contracts
  alias CrosswakeExample.Commerce.EntitlementProjection
  alias CrosswakeExample.Commerce.ProviderAdapterStorefront
  alias CrosswakeExample.Commerce.ReconciliationInbox
  alias CrosswakeExample.Commerce.ReconciliationKeys

  @group_id "sub_pro_monthly"
end
```

Use `async: false` because provider facade tests mutate `Application` env. Phase 48 uses env cleanup:

```elixir
setup do
  previous_adapter = Application.get_env(:crosswake_example, :paywall_storefront_adapter)
  previous_provider = Application.get_env(:crosswake_example, :paywall_storefront_provider)

  on_exit(fn ->
    restore_env(:paywall_storefront_adapter, previous_adapter)
    restore_env(:paywall_storefront_provider, previous_provider)
  end)

  :ok
end

defp restore_env(key, nil), do: Application.delete_env(:crosswake_example, key)
defp restore_env(key, value), do: Application.put_env(:crosswake_example, key, value)
```

**Provider facade analogs to reuse:**

```elixir
Application.put_env(:crosswake_example, :paywall_storefront_adapter, ProviderAdapterStorefront)
Application.put_env(:crosswake_example, :paywall_storefront_provider, :storekit)

adapter = Application.fetch_env!(:crosswake_example, :paywall_storefront_adapter)
intent = %Contracts.PurchaseIntent{entry_id: @group_id, correlation_id: "corr-storekit-swap"}

assert {:ok, evidence} = adapter.simulate_purchase(intent)
assert evidence.provider == "storekit"
assert evidence.event_kind == "purchase"
```

```elixir
Application.put_env(:crosswake_example, :paywall_storefront_provider, :play_billing)

intent = %Contracts.RestoreIntent{correlation_id: "corr-play-swap"}

assert {:ok, evidence} = adapter.simulate_restore(intent)
assert evidence.provider == "play_billing"
assert evidence.event_kind == "restore"
```

Direct provider helpers also exist and are useful for a compact matrix:

```elixir
ProviderAdapterStorefront.simulate_storekit_purchase(intent, captured_at: "2026-06-01T00:00:00Z")
ProviderAdapterStorefront.simulate_storekit_restore(intent, captured_at: "2026-06-01T00:00:00Z")
ProviderAdapterStorefront.simulate_play_billing_purchase(intent, captured_at: "2026-06-01T00:00:00Z")
ProviderAdapterStorefront.simulate_play_billing_restore(intent, captured_at: "2026-06-01T00:00:00Z")
```

**Authority-fence assertions to preserve:**

From Phase 34:

```elixir
assert Crosswake.Commerce.Reconciliation.authority_mutation_allowed_from_evidence?(evidence) == false

assert {:error, :unverified_reconciliation_outcome} =
         EntitlementProjection.project_snapshot(nil, unverified)
```

From Phase 48:

```elixir
assert {:ok, attempt} = ReconciliationInbox.ingest_evidence(evidence)
assert attempt.status == :awaiting_verification

pending_snapshot = pending_snapshot(attempt.event_key)
assert EntitlementProjection.derived_state(pending_snapshot) == :pending
assert {:error, :unverified_reconciliation_outcome} =
         EntitlementProjection.project_snapshot(nil, pending_snapshot)
```

Core direct-override negative:

```elixir
assert {:error, :authority_lane_mutation_forbidden} =
         Crosswake.Commerce.Reconciliation.ingest_evidence(evidence, authority_state: :active)
```

Monotonic stale-authority negative:

```elixir
assert {:error, {:stale_authority, stale}} =
         EntitlementProjection.project_snapshot(current_granted_snapshot, older_incoming_snapshot)

assert stale.reconciliation.state == :stale_authority
```

**Identity and replay assertions to preserve:**

StoreKit subject identity is lineage-based:

```elixir
assert ReconciliationKeys.subject_key(storekit_evidence) ==
         "subject::storekit::storekit_original_#{@group_id}"
```

StoreKit event identity may vary by transaction/notification:

```elixir
assert ReconciliationKeys.event_key(storekit_evidence) ==
         "event::storekit::storekit_original_#{@group_id}::purchase::storekit_txn_001"
```

Play Billing subject identity is purchase-token-based:

```elixir
assert ReconciliationKeys.subject_key(play_restore_evidence) ==
         "subject::play_billing::play_token_#{@group_id}"
```

Correlation ID is trace metadata only. For replay, keep provider identity stable and vary correlation:

```elixir
assert {:ok, first} = ReconciliationInbox.ingest_evidence(evidence, correlation_id: "corr-a")
assert {:ok, replay} =
         ReconciliationInbox.ingest_evidence(evidence,
           correlation_id: "corr-b",
           seen_event_keys: [first.event_key]
         )

assert replay.replay? == true
assert replay.event_key == first.event_key
refute replay.trace_metadata.correlation_id == first.trace_metadata.correlation_id
```

**Provider vocabulary rejection pattern:**

```elixir
assert {:error, {:invalid_event_kind, _details}} =
         StoreKitEvidence.new(
           original_transaction_id: "orig-1",
           transaction_id: "txn-1",
           event_kind: "DID_RENEW",
           environment: :sandbox,
           source: :storefront,
           captured_at: "2026-06-01T00:00:00Z"
         )
```

Use the Play Billing equivalent from Phase 48 for `"PURCHASED"`.

**Hermeticity self-scan guard:**

Phase 34 scans the proof file for allowed `Code.require_file` calls and forbidden runtime tokens. Reuse the same structure, adjusted for Phase 70's allowed pure commerce modules:

```elixir
require_call_lines =
  source
  |> String.split("\n")
  |> Enum.filter(&Regex.match?(~r/^\s*code\.require_file\s*\(/, &1))

allowed_modules = [
  "reconciliation_keys.ex",
  "reconciliation_inbox.ex",
  "entitlement_projection.ex",
  "mock_backend.ex",
  "storefront_adapter.ex",
  "provider_adapter_storefront.ex",
  "mock_storefront.ex"
]

for line <- require_call_lines do
  assert Enum.any?(allowed_modules, &String.contains?(line, &1))
end
```

Keep forbidden runtime substrings at least:

```elixir
["_live", "endpoint", "application", "router", "repo", "_web"]
```

Do not use `@moduletag :requires_example_host` in the merge-blocking Phase 70 proof.

**Recommended test groups:**

- StoreKit purchase E2E: evidence -> awaiting verification -> projection reject -> verified grant.
- StoreKit restore E2E: lineage identity -> awaiting verification -> verified grant only after backend snapshot.
- Play Billing purchase E2E: purchase token identity -> awaiting verification -> verified grant.
- Play Billing restore E2E: provider facade restore -> awaiting verification -> verified grant only after backend snapshot.
- Mock storefront purchase through default facade remains evidence-only before backend projection.
- Client/device/storefront success alone cannot grant.
- Direct authority override forbidden.
- Duplicate replay with different `correlation_id` does not create new authority.
- Stale incoming authority fails closed as `:stale_authority`.
- Refunded/revoked/expired verified snapshots derive `:denied`, not `:granted`.
- Invalid provider vocabulary is rejected before projection.

### Optional `examples/phoenix_host/lib/crosswake_example/commerce/mock_backend_verifier.ex`

**Role:** pure deterministic proof/example helper for backend authority promotion, only if the existing `MockBackend` is too narrow.

**Data flow:** normalized `%ReconciliationEvidence{}` plus fixed opts -> verified `%EntitlementSnapshot{}` with explicit authority/access/reconciliation/freshness/effective/evidence/as_of lanes.

**Closest analog:** `examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex`

Current limitation to account for:

```elixir
now_iso = DateTime.utc_now() |> DateTime.to_iso8601()
as_of: System.system_time(:microsecond)
```

That is fine for interactive mock UI, but Phase 70 exact assertions need fixed timestamps and stable `as_of`.

**Verifier helper pattern:**

```elixir
defmodule CrosswakeExample.Commerce.MockBackendVerifier do
  @moduledoc """
  Deterministic, pure-Elixir backend verification helper for proof lanes.

  Storefront/device evidence remains evidence-only; this module is the backend
  promotion boundary that emits verified entitlement snapshots.
  """

  alias Crosswake.Commerce.Contracts

  @default_checked_at "2026-06-04T00:00:00Z"

  @spec verify_evidence(Contracts.ReconciliationEvidence.t(), String.t(), keyword()) ::
          {:ok, Contracts.EntitlementSnapshot.t()} | {:error, term()}
  def verify_evidence(%Contracts.ReconciliationEvidence{} = evidence, group_id, opts \\ []) do
    {:ok,
     struct!(Contracts.EntitlementSnapshot, %{
       group_id: group_id,
       authority: %Contracts.EntitlementSnapshot.AuthorityLane{
         state: Keyword.get(opts, :authority_state, :active),
         reason: Keyword.get(opts, :authority_reason)
       },
       access: %Contracts.EntitlementSnapshot.AccessLane{
         decision: Keyword.get(opts, :access_decision, :granted),
         reason: Keyword.get(opts, :access_reason)
       },
       reconciliation: %Contracts.EntitlementSnapshot.ReconciliationLane{
         state: Keyword.get(opts, :reconciliation_state, :projection_refreshed),
         reference: Keyword.get(opts, :reference, evidence.evidence_ref)
       },
       freshness: %Contracts.EntitlementSnapshot.FreshnessLane{
         state: Keyword.get(opts, :freshness_state, :fresh),
         checked_at: Keyword.get(opts, :checked_at, @default_checked_at),
         stale_after: Keyword.get(opts, :stale_after)
       },
       effective: %Contracts.EntitlementSnapshot.EffectiveLane{
         effective_from: Keyword.get(opts, :effective_from, @default_checked_at),
         effective_until: Keyword.get(opts, :effective_until)
       },
       evidence: %Contracts.EntitlementSnapshot.EvidenceLane{
         source: Keyword.get(opts, :evidence_source, evidence.source),
         reference: evidence.evidence_ref,
         observed_at: evidence.captured_at
       },
       as_of: Keyword.get(opts, :as_of, 700)
     })}
  end
end
```

Keep this module example-host/proof-only. Do not introduce Ecto, Repo, migrations, an outbox, generic event sourcing, provider SDK calls, Stripe, RevenueCat, Paddle, or generic billing adapter vocabulary.

**Lifecycle deny fixtures:**

Use verified backend snapshots with `reconciliation_state: :projection_refreshed` and denial authority/access lanes:

```elixir
verify_evidence(evidence, @group_id,
  authority_state: :refunded,
  access_decision: :denied,
  access_reason: :provider_refund,
  as_of: 710
)
```

Repeat for `:revoked` and `:expired`. These should project successfully but derive `:denied`.

### `.github/workflows/phase70-proof.yml`

**Role:** CI proof lane.

**Data flow:** GitHub event -> BEAM setup -> dependencies -> compile warnings-as-errors -> targeted Phase 70 ExUnit proof; separate advisory provider/device job never gates merge.

**Closest analog:** `.github/workflows/phase48-proof.yml`

**Workflow skeleton to copy:**

```yaml
name: Phase 70 Proof

permissions:
  contents: read

on:
  pull_request:
  push:
    branches:
      - main
  workflow_dispatch:
    inputs:
      lane:
        description: "Proof lane to run"
        required: true
        default: merge-blocking
        type: choice
        options:
          - merge-blocking
          - advisory
          - all
  schedule:
    - cron: "0 6 * * 1"

env:
  DEVELOPER_DIR: /Applications/Xcode_26.0.app/Contents/Developer
```

**Merge-blocking job pattern:**

```yaml
jobs:
  merge-blocking-subscription-saas-commerce-proof:
    name: merge-blocking subscription SaaS commerce proof (hermetic)
    runs-on: macos-15
    timeout-minutes: 20
    if: ${{ github.event_name == 'pull_request' || github.event_name == 'push' || (github.event_name == 'workflow_dispatch' && (inputs.lane == 'merge-blocking' || inputs.lane == 'all')) }}

    steps:
      - name: Checkout
        uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6

      - name: Setup BEAM
        uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93 # v1
        with:
          elixir-version: "1.19.5"
          otp-version: "27.3"

      - name: Install Elixir dependencies
        run: mix deps.get

      - name: Compile (warnings as errors)
        run: mix compile --warnings-as-errors

      - name: Run hermetic Phase 70 subscription SaaS commerce proof
        run: mix test test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs
```

**Advisory job pattern:**

```yaml
  advisory-provider-sandbox-proof:
    name: advisory provider sandbox/device proof (storekit + play billing)
    runs-on: ubuntu-24.04
    timeout-minutes: 30
    if: ${{ github.event_name == 'schedule' || (github.event_name == 'workflow_dispatch' && (inputs.lane == 'advisory' || inputs.lane == 'all')) }}
    continue-on-error: true
```

Use Phase 48's credential-gated StoreKit and Play Billing notice steps. Keep the language explicit that advisory passing does not promote support posture or gate merge.

### Optional `examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex`

**Role:** Phoenix-owned paywall proof surface.

**Data flow:** LiveView button -> storefront adapter -> evidence ingestion -> immediate pending broadcast -> backend verification task -> derived state broadcast -> rendered status.

**Closest analogs:**

- Implementation: `examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex`
- Test style: `test/crosswake/proof/phase35_paywall_live_test.exs`

**Current event flow to preserve:**

```elixir
case storefront_adapter().simulate_purchase(intent) do
  {:ok, evidence} ->
    case ReconciliationInbox.ingest_evidence(evidence) do
      {:ok, _attempt} ->
        Phoenix.PubSub.broadcast(
          CrosswakeExample.PubSub,
          "entitlement:" <> @group_id,
          {:entitlement_update, :pending}
        )

        Task.start(fn ->
          :timer.sleep(1_500)
          MockBackend.verify_and_broadcast(evidence, @group_id)
        end)
```

Do not move authority into LiveView. It may initiate evidence submission and render state only.

**Current UI scope issue to remove if UI is touched:**

```elixir
<a href="#">Manage subscription</a>
```

Subscription management is out of scope for Phase 70. Replace with read-only backend entitlement/status copy if the UI is modified.

**Accessible status pattern:**

Wrap changing state output in a polite status region:

```heex
<div class="paywall-corridor" role="status" aria-live="polite">
  ...
</div>
```

or place `role="status"` on the state block. Keep headings semantic and buttons as real `<button>` controls.

**Truth-preserving copy patterns:**

- `Subscribe to Pro Monthly`
- `Restore purchase`
- `Verifying backend entitlement`
- `Access active from backend projection`
- `Unable to verify access`

Avoid cancellation, invoice history, payment method editing, plan changes, seats, tax, hosted portals, and generic subscription portal behavior.

**LiveView proof style if UI changes:**

Phase 35 uses direct callback/render testing with `@moduletag :requires_example_host`:

```elixir
@moduletag :requires_example_host

setup_all do
  Crosswake.TestSupport.ExampleHost.load!()
  :ok
end
```

Render assertions are direct:

```elixir
html = render_state(:denied)
assert html =~ "Subscribe to continue"
assert html =~ ~s(phx-click="subscribe")
```

Provider vocabulary fence:

```elixir
for state <- [:granted, :pending, :denied, :stale] do
  html = String.downcase(render_state(state))
  refute html =~ "store" <> "kit"
  refute html =~ "play" <> "_billing"
end
```

Keep UI tests separate from the Phase 70 merge-blocking pure proof unless the plan intentionally adds a second example-host lane.

## Existing Module Semantics The Planner Must Preserve

### `ReconciliationInbox`

Evidence ingestion is append-only and evidence-only:

```elixir
status: evidence_status(evidence.event_kind),
replay?: replay?,
trace_metadata: ReconciliationKeys.trace_metadata(...)
```

Success-like events map to `:awaiting_verification`, not `:granted`:

```elixir
@success_like_event_kinds MapSet.new(["purchase", "restore", "renewal", "grace_period", "billing_retry"])
```

### `EntitlementProjection`

Projection accepts only verified reconciliation states:

```elixir
@verified_reconciliation_states [:projection_refreshed, :verification_failed, :conflict, :stale_authority]
```

Derived state order:

```elixir
snapshot.freshness.state in [:stale, :unknown] -> :stale
snapshot.reconciliation.state in @pending_reconciliation_states -> :pending
granted_snapshot?(snapshot) -> :granted
true -> :denied
```

Grant requires all of:

```elixir
snapshot.freshness.state == :fresh
resolved_reconciliation?(snapshot.reconciliation.state)
snapshot.authority.state in @grantable_authority_states
snapshot.access.decision == :granted
```

Only `:projection_refreshed` is resolved for a grant:

```elixir
defp resolved_reconciliation?(:projection_refreshed), do: true
defp resolved_reconciliation?(_state), do: false
```

### `ProviderAdapterStorefront`

Provider selection is configured and fail-closed:

```elixir
case Application.get_env(:crosswake_example, :paywall_storefront_provider, nil) do
  nil -> {:error, :provider_not_configured}
  :storekit -> {:ok, :storekit}
  :play_billing -> {:ok, :play_billing}
  provider -> {:error, {:invalid_provider, provider}}
end
```

StoreKit purchase identity:

```elixir
original_transaction_id: "storekit_original_" <> intent.entry_id
transaction_id: "storekit_txn_" <> intent.entry_id <> "_purchase"
event_kind: :purchase
```

Play Billing restore identity:

```elixir
purchase_token: "play_token_" <> @group_id
rtdn_message_id: "rtdn_" <> @group_id <> "_restore"
event_kind: :restore
```

## Proof Regression Commands

Primary Phase 70 gate:

```sh
mix test test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs
```

Compile gate matching workflow:

```sh
mix compile --warnings-as-errors
```

Relevant regression context:

```sh
mix test test/crosswake/proof/phase34_paywall_corridor_proof_test.exs
mix test test/crosswake/proof/phase34_mock_storefront_test.exs
mix test test/crosswake/proof/phase48_provider_adapter_proof_test.exs
```

Only if Paywall LiveView is touched and the example host is compiled/loaded:

```sh
mix test test/crosswake/proof/phase35_paywall_live_test.exs --include requires_example_host
```

## Planner Notes

- Prefer one integrated product-shaped story over separate reruns of Phase 34 and Phase 48.
- Keep the merge-blocking proof pure ExUnit with `Code.require_file`; no Endpoint, Repo, PubSub, LiveView server infrastructure, network, simulators, provider SDKs, or device lanes.
- Keep provider names in adapter/proof surfaces only. Do not leak StoreKit/Play Billing vocabulary into route policy, provider-neutral support truth, or user-facing Paywall states.
- Restore is evidence-only. Access changes only after backend verification/projection.
- New verifier helper, if needed, belongs under example-host commerce and should be deterministic.
- Do not add persisted reconciliation infrastructure, generic billing abstractions, or subscription management UI in Phase 70.

## PATTERN MAPPING COMPLETE
