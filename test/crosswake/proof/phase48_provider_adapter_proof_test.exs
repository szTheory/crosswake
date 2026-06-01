Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/provider_adapter_storefront.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex", __DIR__)

defmodule Crosswake.Proof.Phase48ProviderAdapterProofTest do
  use ExUnit.Case, async: true

  alias Crosswake.Commerce.ProviderEvidence
  alias Crosswake.Companions.PlayBilling.Evidence, as: PlayBillingEvidence
  alias Crosswake.Companions.StoreKit.Evidence, as: StoreKitEvidence
  alias Crosswake.Commerce.Contracts
  alias Crosswake.Doctor.PublishReadiness
  alias Crosswake.SupportMatrix
  alias Crosswake.TestSupport.ProofAssertions
  alias CrosswakeExample.Commerce.EntitlementProjection
  alias CrosswakeExample.Commerce.MockBackend
  alias CrosswakeExample.Commerce.ProviderAdapterStorefront
  alias CrosswakeExample.Commerce.ReconciliationInbox
  alias CrosswakeExample.Commerce.ReconciliationKeys

  @group_id "sub_pro_monthly"
  @readiness_fixture "test/fixtures/proof/phase48_provider_adapter_readiness.json"

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

  test "provider evidence stays in canonical event vocabulary and event/subject identity is stable" do
    purchase_intent = %Contracts.PurchaseIntent{entry_id: @group_id, correlation_id: "corr-storekit-keys"}
    restore_intent = %Contracts.RestoreIntent{correlation_id: "corr-play-keys"}

    assert {:ok, storekit_evidence} =
             ProviderAdapterStorefront.simulate_storekit_purchase(purchase_intent,
               captured_at: "2026-06-01T00:00:00Z",
               transaction_id: "storekit_txn_001"
             )

    assert {:ok, play_restore_evidence} =
             ProviderAdapterStorefront.simulate_play_billing_restore(restore_intent,
               captured_at: "2026-06-01T00:00:00Z",
               rtdn_message_id: "play_rtdn_001"
             )

    assert storekit_evidence.event_kind in ProviderEvidence.event_kind_vocabulary()
    assert play_restore_evidence.event_kind in ProviderEvidence.event_kind_vocabulary()

    assert ReconciliationKeys.subject_key(storekit_evidence) ==
             "subject::storekit::storekit_original_#{@group_id}"

    assert ReconciliationKeys.event_key(storekit_evidence) ==
             "event::storekit::storekit_original_#{@group_id}::purchase::storekit_txn_001"

    assert ReconciliationKeys.subject_key(play_restore_evidence) ==
             "subject::play_billing::play_token_#{@group_id}"

    assert ReconciliationKeys.event_key(play_restore_evidence) ==
             "event::play_billing::play_token_#{@group_id}::restore::play_rtdn_001"
  end

  test "raw provider enum/status values are rejected from core event kinds" do
    assert {:error, {:invalid_event_kind, _details}} =
             StoreKitEvidence.new(
               original_transaction_id: "orig-1",
               transaction_id: "txn-1",
               event_kind: "DID_RENEW",
               environment: :sandbox,
               source: :storefront,
               captured_at: "2026-06-01T00:00:00Z"
             )

    assert {:error, {:invalid_event_kind, _details}} =
             PlayBillingEvidence.new(
               purchase_token: "token-1",
               order_id: "GPA.1234",
               event_kind: "PURCHASED",
               environment: :license_test,
               source: :storefront,
               captured_at: "2026-06-01T00:00:00Z"
             )
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

  test "provider readiness keeps shipped seams and advisory proof contract in stable fixture" do
    report =
      PublishReadiness.run(
        generated_at: "2026-06-01T00:00:00Z",
        cwd: File.cwd!()
      )

    provider =
      report.checks
      |> Enum.find(&(&1.id == "provider.adapter_readiness"))

    assert provider.result == :verification_required
    assert provider.proof_class == :advisory
    assert provider.blocking == false
    assert provider.details.shipped_seams? == true
    assert provider.details.advisory_provider_proof? == true
    assert provider.details.storekit_check_id == "diag.provider.storekit.advisory_proof"
    assert provider.details.play_billing_check_id == "diag.provider.play_billing.advisory_proof"

    ProofAssertions.assert_normalized_json_fixture(
      "proof.provider_adapters.readiness.json_contract",
      Jason.encode!(PublishReadiness.to_map(report)["checks"] |> Enum.find(&(&1["id"] == "provider.adapter_readiness"))),
      @readiness_fixture,
      source: "Crosswake.Doctor.PublishReadiness.run/1 provider.adapter_readiness check",
      path: @readiness_fixture,
      hint: "update fixture only for intended provider-readiness semantic changes",
      posture: :merge_blocking
    )
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

  test "docs keep provider adapter support and advisory posture explicit" do
    ProofAssertions.assert_contains_exact(
      "proof.docs.provider_adapters.commerce_shipped_seams",
      "guides/commerce.md",
      "StoreKit and Play Billing adapter seams ship as reconciliation evidence emitters only.",
      source: "guides/commerce.md provider adapter seam contract section",
      hint: "preserve shipped seam claim while keeping backend authority explicit",
      posture: :merge_blocking
    )

    ProofAssertions.assert_contains_exact(
      "proof.docs.provider_adapters.support_matrix_advisory_boundary",
      "guides/support_matrix.md",
      "StoreKit and Play Billing provider adapter seams are shipped, but provider/storefront proof remains advisory until promotion criteria pass",
      source: "guides/support_matrix.md non-claim compatibility boundary",
      hint: "preserve shipped seam plus advisory provider proof boundary",
      posture: :merge_blocking
    )

    ProofAssertions.assert_contains_exact(
      "proof.docs.provider_adapters.commerce_advisory_boundary",
      "guides/commerce.md",
      "Provider/device verification lanes remain `advisory` and cannot redefine core merge-blocking support truth.",
      source: "guides/commerce.md rough edges and advisory proof posture",
      hint: "keep provider sandbox/device checks advisory and non-blocking",
      posture: :merge_blocking
    )
  end
end
