Code.require_file(
  "../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex",
  __DIR__
)

Code.require_file(
  "../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex",
  __DIR__
)

Code.require_file(
  "../../../examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex",
  __DIR__
)

Code.require_file(
  "../../../examples/phoenix_host/lib/crosswake_example/commerce/mock_backend_verifier.ex",
  __DIR__
)

Code.require_file(
  "../../../examples/phoenix_host/lib/crosswake_example/commerce/storefront_adapter.ex",
  __DIR__
)

Code.require_file(
  "../../../examples/phoenix_host/lib/crosswake_example/commerce/provider_adapter_storefront.ex",
  __DIR__
)

Code.require_file(
  "../../../examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex",
  __DIR__
)

defmodule Crosswake.Proof.Phase70SubscriptionSaasCommerceProofTest do
  use ExUnit.Case, async: false

  alias Crosswake.Commerce.Contracts
  alias Crosswake.Commerce.Reconciliation
  alias Crosswake.Companions.PlayBilling.Evidence, as: PlayBillingEvidence
  alias Crosswake.Companions.StoreKit.Evidence, as: StoreKitEvidence
  alias CrosswakeExample.Commerce.EntitlementProjection
  alias CrosswakeExample.Commerce.MockBackendVerifier
  alias CrosswakeExample.Commerce.ProviderAdapterStorefront
  alias CrosswakeExample.Commerce.ReconciliationInbox
  alias CrosswakeExample.Commerce.ReconciliationKeys

  @group_id "sub_pro_monthly"
  @captured_at "2026-06-04T00:00:00Z"

  setup do
    previous_adapter = Application.get_env(:crosswake_example, :paywall_storefront_adapter)
    previous_provider = Application.get_env(:crosswake_example, :paywall_storefront_provider)

    on_exit(fn ->
      restore_env(:paywall_storefront_adapter, previous_adapter)
      restore_env(:paywall_storefront_provider, previous_provider)
    end)

    :ok
  end

  describe "provider purchase and restore matrix" do
    test "StoreKit purchase remains awaiting verification until backend projection" do
      intent = purchase_intent("corr-storekit-purchase")

      assert {:ok, evidence} =
               ProviderAdapterStorefront.simulate_storekit_purchase(intent,
                 captured_at: @captured_at,
                 transaction_id: "storekit_txn_001"
               )

      assert evidence.provider == "storekit"
      assert evidence.event_kind == "purchase"

      assert ReconciliationKeys.subject_key(evidence) ==
               "subject::storekit::storekit_original_#{@group_id}"

      assert ReconciliationKeys.event_key(evidence) ==
               "event::storekit::storekit_original_#{@group_id}::purchase::storekit_txn_001"

      assert_evidence_only_pending(evidence, "corr-storekit-purchase")
      assert_verified_projection_required(evidence, provider: :storekit, operation: :purchase)
    end

    test "StoreKit restore remains awaiting verification until backend projection" do
      intent = restore_intent("corr-storekit-restore")

      assert {:ok, evidence} =
               ProviderAdapterStorefront.simulate_storekit_restore(intent,
                 captured_at: @captured_at,
                 notification_uuid: "storekit_note_restore_001"
               )

      assert evidence.provider == "storekit"
      assert evidence.event_kind == "restore"

      assert ReconciliationKeys.subject_key(evidence) ==
               "subject::storekit::storekit_original_#{@group_id}"

      assert ReconciliationKeys.event_key(evidence) ==
               "event::storekit::storekit_original_#{@group_id}::restore::storekit_note_restore_001"

      assert_evidence_only_pending(evidence, "corr-storekit-restore")
      assert_verified_projection_required(evidence, provider: :storekit, operation: :restore)
    end

    test "Play Billing purchase remains awaiting verification until backend projection" do
      intent = purchase_intent("corr-play-purchase")

      assert {:ok, evidence} =
               ProviderAdapterStorefront.simulate_play_billing_purchase(intent,
                 captured_at: @captured_at,
                 order_id: "GPA.play.purchase.001"
               )

      assert evidence.provider == "play_billing"
      assert evidence.event_kind == "purchase"

      assert ReconciliationKeys.subject_key(evidence) ==
               "subject::play_billing::play_token_#{@group_id}"

      assert ReconciliationKeys.event_key(evidence) ==
               "event::play_billing::play_token_#{@group_id}::purchase::GPA.play.purchase.001"

      assert_evidence_only_pending(evidence, "corr-play-purchase")
      assert_verified_projection_required(evidence, provider: :play_billing, operation: :purchase)
    end

    test "Play Billing restore remains awaiting verification until backend projection" do
      intent = restore_intent("corr-play-restore")

      assert {:ok, evidence} =
               ProviderAdapterStorefront.simulate_play_billing_restore(intent,
                 captured_at: @captured_at,
                 rtdn_message_id: "play_rtdn_restore_001"
               )

      assert evidence.provider == "play_billing"
      assert evidence.event_kind == "restore"

      assert ReconciliationKeys.subject_key(evidence) ==
               "subject::play_billing::play_token_#{@group_id}"

      assert ReconciliationKeys.event_key(evidence) ==
               "event::play_billing::play_token_#{@group_id}::restore::play_rtdn_restore_001"

      assert_evidence_only_pending(evidence, "corr-play-restore")
      assert_verified_projection_required(evidence, provider: :play_billing, operation: :restore)
    end
  end

  describe "authority fence negative cases" do
    test "storefront and device success alone cannot grant entitlement authority" do
      %Contracts.ReconciliationEvidence{} = storefront = mock_storefront_purchase()
      device = %Contracts.ReconciliationEvidence{storefront | source: :device}

      for evidence <- [storefront, device] do
        assert Reconciliation.authority_mutation_allowed_from_evidence?(evidence) == false
        assert {:ok, attempt} = ReconciliationInbox.ingest_evidence(evidence)
        assert attempt.status == :awaiting_verification

        pending_snapshot = pending_snapshot(attempt.event_key, event_kind: evidence.event_kind)
        assert EntitlementProjection.derived_state(pending_snapshot) == :pending

        assert {:error, :unverified_reconciliation_outcome} =
                 EntitlementProjection.project_snapshot(nil, pending_snapshot)
      end
    end

    test "direct authority_state evidence override is forbidden" do
      evidence = mock_storefront_purchase()

      assert Reconciliation.authority_mutation_allowed_from_evidence?(evidence) == false

      assert {:error, :authority_lane_mutation_forbidden} =
               Reconciliation.ingest_evidence(evidence, authority_state: :active)
    end

    test "duplicate replay with different correlation_id keeps the same event key" do
      assert {:ok, evidence} =
               ProviderAdapterStorefront.simulate_storekit_purchase(purchase_intent("corr-first"),
                 captured_at: @captured_at,
                 transaction_id: "storekit_txn_replay"
               )

      assert {:ok, first} =
               ReconciliationInbox.ingest_evidence(evidence, correlation_id: "corr-first")

      assert {:ok, replay} =
               ReconciliationInbox.ingest_evidence(evidence,
                 correlation_id: "corr-second",
                 seen_event_keys: [first.event_key]
               )

      assert replay.replay? == true
      assert replay.event_key == first.event_key
      assert replay.subject_key == first.subject_key
      assert replay.trace_metadata.correlation_id == "corr-second"
      assert first.trace_metadata.correlation_id == "corr-first"
    end

    test "stale incoming authority fails closed instead of overwriting a fresher grant" do
      current =
        verified_snapshot(
          authority: :active,
          access: :granted,
          reconciliation: :projection_refreshed,
          as_of: 300
        )

      incoming =
        verified_snapshot(
          authority: :active,
          access: :granted,
          reconciliation: :projection_refreshed,
          as_of: 200
        )

      assert {:error, {:stale_authority, snapshot}} =
               EntitlementProjection.project_snapshot(current, incoming)

      assert snapshot.reconciliation.state == :stale_authority
      assert EntitlementProjection.derived_state(snapshot) == :denied
    end

    test "pending purchase and restore snapshots derive pending and cannot project" do
      for event_kind <- ["purchase", "restore"] do
        snapshot = pending_snapshot("phase70-pending-#{event_kind}", event_kind: event_kind)

        assert EntitlementProjection.derived_state(snapshot) == :pending

        assert {:error, :unverified_reconciliation_outcome} =
                 EntitlementProjection.project_snapshot(nil, snapshot)
      end
    end

    test "refunded revoked and expired provider results derive denied after backend verification" do
      evidence = mock_storefront_purchase()

      for lifecycle <- [:refunded, :revoked, :expired] do
        assert {:ok, snapshot} =
                 verify_provider_evidence(evidence,
                   lifecycle: lifecycle,
                   group_id: @group_id,
                   checked_at: @captured_at,
                   as_of: 400 + lifecycle_rank(lifecycle)
                 )

        assert {:ok, projected} = EntitlementProjection.project_snapshot(nil, snapshot)
        assert EntitlementProjection.derived_state(projected) == :denied
      end
    end

    test "invalid provider event vocabulary is rejected before projection" do
      assert {:error, {:invalid_event_kind, _details}} =
               StoreKitEvidence.new(
                 original_transaction_id: "orig-1",
                 transaction_id: "txn-1",
                 event_kind: "DID_RENEW",
                 environment: :sandbox,
                 source: :storefront,
                 captured_at: @captured_at
               )

      assert {:error, {:invalid_event_kind, _details}} =
               PlayBillingEvidence.new(
                 purchase_token: "play-token-1",
                 order_id: "GPA.invalid.001",
                 event_kind: "PURCHASED",
                 environment: :license_test,
                 source: :storefront,
                 captured_at: @captured_at
               )
    end
  end

  describe "hermeticity self-scan guard" do
    test "requires exactly the allowed pure commerce files" do
      source = File.read!(__ENV__.file) |> String.downcase()

      require_paths =
        ~r/code\.require_file\(\s*"([^"]+)"/
        |> Regex.scan(source, capture: :all_but_first)
        |> List.flatten()

      allowed_modules = [
        "reconciliation_keys.ex",
        "reconciliation_inbox.ex",
        "entitlement_projection.ex",
        "mock_backend_verifier.ex",
        "storefront_adapter.ex",
        "provider_adapter_storefront.ex",
        "mock_storefront.ex"
      ]

      assert length(require_paths) == 7

      for path <- require_paths do
        assert Enum.any?(allowed_modules, &String.contains?(path, &1)),
               "proof requires an unapproved file: #{inspect(path)}"
      end

      forbidden_runtime_substrings = [
        "_live",
        "endpoint",
        "application",
        "router",
        "repo",
        "_web"
      ]

      for path <- require_paths, forbidden <- forbidden_runtime_substrings do
        refute String.contains?(path, forbidden),
               "proof requires a runtime path containing #{inspect(forbidden)}: #{inspect(path)}"
      end
    end

    test "does not contain process or server tokens" do
      source = File.read!(__ENV__.file) |> String.downcase()

      forbidden_tokens = [
        "start" <> "_supervised",
        "phoenix" <> ".pubsub",
        "genserver" <> ".start",
        "liveview" <> "test"
      ]

      for token <- forbidden_tokens do
        refute String.contains?(source, String.downcase(token)),
               "proof body contains non-hermetic token #{inspect(token)}"
      end
    end
  end

  defp assert_evidence_only_pending(
         %Contracts.ReconciliationEvidence{} = evidence,
         correlation_id
       ) do
    assert {:ok, attempt} =
             ReconciliationInbox.ingest_evidence(evidence, correlation_id: correlation_id)

    assert attempt.status == :awaiting_verification

    pending_snapshot = pending_snapshot(attempt.event_key, event_kind: evidence.event_kind)
    assert EntitlementProjection.derived_state(pending_snapshot) == :pending

    assert {:error, :unverified_reconciliation_outcome} =
             EntitlementProjection.project_snapshot(nil, pending_snapshot)
  end

  defp assert_verified_projection_required(%Contracts.ReconciliationEvidence{} = evidence, opts) do
    assert {:ok, snapshot} =
             verify_provider_evidence(evidence,
               group_id: @group_id,
               provider: Keyword.fetch!(opts, :provider),
               operation: Keyword.fetch!(opts, :operation),
               checked_at: @captured_at,
               as_of: 500
             )

    assert snapshot.reconciliation.state == :projection_refreshed
    assert {:ok, projected} = EntitlementProjection.project_snapshot(nil, snapshot)
    assert EntitlementProjection.derived_state(projected) == :granted
  end

  defp purchase_intent(correlation_id) do
    %Contracts.PurchaseIntent{entry_id: @group_id, correlation_id: correlation_id}
  end

  defp restore_intent(correlation_id),
    do: %Contracts.RestoreIntent{correlation_id: correlation_id}

  defp mock_storefront_purchase do
    {:ok, %Contracts.ReconciliationEvidence{} = evidence} =
      CrosswakeExample.Commerce.MockStorefront.simulate_purchase(%Contracts.PurchaseIntent{
        entry_id: @group_id,
        correlation_id: "corr-mock-success"
      })

    %Contracts.ReconciliationEvidence{evidence | captured_at: @captured_at}
  end

  defp pending_snapshot(reference, opts) do
    event_kind = Keyword.fetch!(opts, :event_kind)

    reconciliation_state =
      if event_kind == "restore", do: :pending_restore, else: :pending_purchase

    snapshot(
      authority: :none,
      access: :denied,
      reconciliation: reconciliation_state,
      reference: reference,
      as_of: 100
    )
  end

  defp verified_snapshot(opts) do
    snapshot(
      authority: Keyword.fetch!(opts, :authority),
      access: Keyword.fetch!(opts, :access),
      reconciliation: Keyword.fetch!(opts, :reconciliation),
      reference: Keyword.get(opts, :reference, "phase70-verified"),
      as_of: Keyword.fetch!(opts, :as_of)
    )
  end

  defp snapshot(opts) do
    struct!(Contracts.EntitlementSnapshot, %{
      group_id: @group_id,
      authority: %Contracts.EntitlementSnapshot.AuthorityLane{
        state: Keyword.fetch!(opts, :authority),
        reason: nil
      },
      access: %Contracts.EntitlementSnapshot.AccessLane{
        decision: Keyword.fetch!(opts, :access),
        reason: nil
      },
      reconciliation: %Contracts.EntitlementSnapshot.ReconciliationLane{
        state: Keyword.fetch!(opts, :reconciliation),
        reference: Keyword.fetch!(opts, :reference)
      },
      freshness: %Contracts.EntitlementSnapshot.FreshnessLane{
        state: :fresh,
        checked_at: @captured_at,
        stale_after: nil
      },
      effective: %Contracts.EntitlementSnapshot.EffectiveLane{
        effective_from: @captured_at,
        effective_until: nil
      },
      evidence: %Contracts.EntitlementSnapshot.EvidenceLane{
        source: :storefront,
        reference: Keyword.fetch!(opts, :reference),
        observed_at: @captured_at
      },
      as_of: Keyword.fetch!(opts, :as_of)
    })
  end

  defp lifecycle_rank(:refunded), do: 1
  defp lifecycle_rank(:revoked), do: 2
  defp lifecycle_rank(:expired), do: 3

  defp verify_provider_evidence(evidence, opts) do
    {group_id, verifier_opts} = Keyword.pop(opts, :group_id, @group_id)

    MockBackendVerifier.verify_evidence(evidence, group_id, verifier_opts)
  end

  defp restore_env(key, nil), do: Application.delete_env(:crosswake_example, key)
  defp restore_env(key, value), do: Application.put_env(:crosswake_example, key, value)
end
