Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/provider_adapter_storefront.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex", __DIR__)

defmodule Crosswake.Proof.Phase48ProviderAdapterProofTest do
  use ExUnit.Case, async: true

  alias Crosswake.Commerce.Contracts
  alias Crosswake.SupportMatrix
  alias Crosswake.TestSupport.ProofAssertions
  alias CrosswakeExample.Commerce.EntitlementProjection
  alias CrosswakeExample.Commerce.MockBackend
  alias CrosswakeExample.Commerce.ProviderAdapterStorefront
  alias CrosswakeExample.Commerce.ReconciliationInbox

  @group_id "sub_pro_monthly"

  test "storekit purchase evidence uses provider-neutral inbox/projection path" do
    intent = %Contracts.PurchaseIntent{entry_id: @group_id, correlation_id: "corr-storekit"}
    assert {:ok, evidence} = ProviderAdapterStorefront.simulate_storekit_purchase(intent, captured_at: "2026-06-01T00:00:00Z")
    assert evidence.provider == "storekit"
    assert evidence.event_kind == "purchase"

    assert {:ok, attempt} = ReconciliationInbox.ingest_evidence(evidence)
    assert attempt.status == :awaiting_verification

    verified = MockBackend.build_verified_snapshot(evidence, @group_id)
    assert {:ok, projected} = EntitlementProjection.project_snapshot(nil, verified)
    assert EntitlementProjection.derived_state(projected) == :granted
  end

  test "play billing restore evidence remains non-authoritative until projection refreshes" do
    intent = %Contracts.RestoreIntent{correlation_id: "corr-play-restore"}
    assert {:ok, evidence} = ProviderAdapterStorefront.simulate_play_billing_restore(intent, captured_at: "2026-06-01T00:00:00Z")
    assert evidence.provider == "play_billing"
    assert evidence.event_kind == "restore"

    assert {:ok, attempt} = ReconciliationInbox.ingest_evidence(evidence)
    assert attempt.status == :awaiting_verification

    pending_snapshot =
      struct!(Contracts.EntitlementSnapshot, %{
        group_id: @group_id,
        authority: %Contracts.EntitlementSnapshot.AuthorityLane{state: :none, reason: nil},
        access: %Contracts.EntitlementSnapshot.AccessLane{decision: :denied, reason: nil},
        reconciliation: %Contracts.EntitlementSnapshot.ReconciliationLane{
          state: :awaiting_verification,
          reference: attempt.event_key
        },
        freshness: %Contracts.EntitlementSnapshot.FreshnessLane{
          state: :fresh,
          checked_at: "2026-06-01T00:00:00Z",
          stale_after: nil
        },
        effective: %Contracts.EntitlementSnapshot.EffectiveLane{
          effective_from: "2026-06-01T00:00:00Z",
          effective_until: nil
        },
        evidence: %Contracts.EntitlementSnapshot.EvidenceLane{
          source: :storefront,
          reference: attempt.event_key,
          observed_at: "2026-06-01T00:00:00Z"
        },
        as_of: 200
      })

    assert EntitlementProjection.derived_state(pending_snapshot) == :pending
    assert {:error, :unverified_reconciliation_outcome} =
             EntitlementProjection.project_snapshot(nil, pending_snapshot)
  end

  test "provider promotion claims remain advisory with provider_adapter action class and demotion semantics" do
    provider_rules =
      SupportMatrix.promotion_rules()
      |> Enum.filter(fn rule ->
        rule.claim_id in [
          "purchase_intent.provider.storekit",
          "restore_intent.provider.storekit",
          "purchase_intent.provider.play_billing",
          "restore_intent.provider.play_billing"
        ]
      end)

    assert length(provider_rules) == 4

    for rule <- provider_rules do
      assert rule.action_class == "provider_adapter"
      assert rule.current_proof_class == :advisory
      assert rule.promotes_to == :merge_blocking
      assert rule.check_ids != []
      assert is_binary(rule.demotion_trigger) and rule.demotion_trigger != ""
    end
  end

  test "changelog keeps unreleased v3.7 seam claims distinct from published hex truth" do
    ProofAssertions.assert_contains_exact(
      "proof.docs.provider_adapters.changelog_unreleased",
      "CHANGELOG.md",
      "v3.7 StoreKit and Play Billing adapter seams are unreleased support claims until the next Hex package is cut.",
      source: "CHANGELOG.md [Unreleased] support claims",
      hint: "separate local support truth from published Hex release truth",
      posture: :merge_blocking
    )

    ProofAssertions.assert_contains_exact(
      "proof.docs.provider_adapters.changelog_advisory_proof",
      "CHANGELOG.md",
      "Provider/device sandbox proof remains advisory unless promotion criteria pass.",
      source: "CHANGELOG.md [Unreleased] advisory provider proof posture",
      hint: "do not collapse advisory provider proof into shipped support claims",
      posture: :merge_blocking
    )

    ProofAssertions.assert_contains_exact(
      "proof.docs.provider_adapters.changelog_hex_truth",
      "CHANGELOG.md",
      "The latest published Hex release remains `0.1.0`.",
      source: "CHANGELOG.md published release section",
      hint: "preserve distinction between unreleased planning claims and published package truth",
      posture: :merge_blocking
    )
  end
end
