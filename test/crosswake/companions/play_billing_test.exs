defmodule Crosswake.Companions.PlayBillingTest do
  use ExUnit.Case, async: true

  alias Crosswake.Commerce.Contracts
  alias Crosswake.Commerce.Reconciliation
  alias Crosswake.Companion.State
  alias Crosswake.Companions.PlayBilling
  alias Crosswake.Companions.PlayBilling.Evidence
  alias Crosswake.Companions.PlayBilling.Result

  describe "companion state" do
    test "reports companion state with commerce provider surface" do
      assert %State{} = state = PlayBilling.report_state()
      assert state.companion_id == :play_billing
      assert is_boolean(state.enabled)
      assert state.details == %{surface: :commerce_provider, provider: :play_billing, mode: :evidence_adapter}
    end
  end

  describe "evidence mapping" do
    test "maps play purchase evidence into reconciliation evidence" do
      attrs = %{
        purchase_token: "play-token-123",
        rtdn_message_id: "rtdn-001",
        event_kind: :purchase,
        environment: :license_test,
        source: :storefront,
        captured_at: "2026-06-01T10:00:00Z"
      }

      assert {:ok, evidence} = Evidence.new(attrs)
      assert {:ok, %Contracts.ReconciliationEvidence{} = normalized} = Evidence.to_reconciliation_evidence(evidence)

      assert normalized.provider == "play_billing"
      assert normalized.provider_reference == "play-token-123"
      assert normalized.evidence_ref == "rtdn-001"
      assert normalized.event_kind == "purchase"
      assert normalized.source == :storefront

      assert {:ok, result} = Reconciliation.ingest_evidence(normalized)
      assert result.status == :awaiting_verification
    end

    test "maps restore, renewal, billing retry, refund, and revoked evidence kinds" do
      fixtures = [
        {"restore", "order-1", :storefront},
        {"renewal", "sha256:play", :webhook},
        {"billing_retry", "rtdn-002", :webhook},
        {"refund", "rtdn-003", :webhook},
        {"revoked", "rtdn-004", :webhook}
      ]

      for {event_kind, evidence_ref, source} <- fixtures do
        assert {:ok, evidence} =
                 Evidence.new(%{
                   purchase_token: "play-token-123",
                   rtdn_message_id: if(String.starts_with?(evidence_ref, "rtdn-"), do: evidence_ref, else: nil),
                   order_id: if(String.starts_with?(evidence_ref, "order-"), do: evidence_ref, else: nil),
                   payload_digest: if(String.starts_with?(evidence_ref, "sha256:"), do: evidence_ref, else: nil),
                   event_kind: event_kind,
                   environment: :production,
                   source: source,
                   captured_at: "2026-06-01T10:00:00Z"
                 })

        assert {:ok, normalized} = Evidence.to_reconciliation_evidence(evidence)
        assert normalized.event_kind == event_kind
      end
    end

    test "requires purchase_token as provider subject lineage" do
      assert {:error, {:missing_field, :purchase_token}} =
               Evidence.new(%{
                 rtdn_message_id: "rtdn-001",
                 event_kind: :purchase,
                 environment: :license_test,
                 source: :storefront,
                 captured_at: "2026-06-01T10:00:00Z"
               })
    end

    test "rejects raw play billing status as event_kind" do
      assert {:error, {:invalid_event_kind, details}} =
               Evidence.new(%{
                 purchase_token: "play-token-123",
                 rtdn_message_id: "rtdn-001",
                 event_kind: "SUBSCRIPTION_STATE_ON_HOLD",
                 environment: :license_test,
                 source: :storefront,
                 captured_at: "2026-06-01T10:00:00Z"
               })

      assert details[:event_kind] == "SUBSCRIPTION_STATE_ON_HOLD"
    end

    test "order_id is evidence identity metadata and never the provider subject reference" do
      assert {:ok, evidence} =
               Evidence.new(%{
                 purchase_token: "play-token-123",
                 order_id: "GPA.1111-2222-3333-44444",
                 event_kind: :restore,
                 environment: :production,
                 source: :webhook,
                 captured_at: "2026-06-01T10:00:00Z"
               })

      assert {:ok, normalized} = Evidence.to_reconciliation_evidence(evidence)
      assert normalized.provider_reference == "play-token-123"
      assert normalized.evidence_ref == "GPA.1111-2222-3333-44444"
    end

    test "rejects authority mutation attempt when evidence is ingested" do
      assert {:ok, evidence} =
               Evidence.new(%{
                 purchase_token: "play-token-123",
                 payload_digest: "sha256:play",
                 event_kind: :purchase,
                 environment: :license_test,
                 source: :storefront,
                 captured_at: "2026-06-01T10:00:00Z"
               })

      assert {:ok, normalized} = Evidence.to_reconciliation_evidence(evidence)

      assert {:error, :authority_lane_mutation_forbidden} =
               Reconciliation.ingest_evidence(normalized, authority_state: :active)
    end

    test "pending purchase evidence does not grant authority and stays unresolved without explicit verification" do
      assert {:ok, evidence} =
               Evidence.new(%{
                 purchase_token: "play-token-123",
                 rtdn_message_id: "rtdn-001",
                 event_kind: :purchase,
                 environment: :license_test,
                 source: :storefront,
                 captured_at: "2026-06-01T10:00:00Z",
                 metadata: %{purchase_state: :pending}
               })

      assert {:ok, normalized} = Evidence.to_reconciliation_evidence(evidence)
      assert {:ok, result} = Reconciliation.ingest_evidence(normalized)
      assert result.status in [:awaiting_verification, :verification_failed]
      assert result.status != :projection_refreshed

      assert {:ok, projected} = Reconciliation.ingest_evidence(normalized, verified_projection: true)
      assert projected.status == :projection_refreshed
    end
  end

  describe "result" do
    test "accepts provider provenance fields" do
      assert {:ok, %Result{} = result} =
               Result.new(%{
                 status: :pending,
                 lifecycle_hint: :pending_external,
                 message: "purchase pending",
                 acknowledgement_state: :pending,
                 consumption_state: :not_consumed,
                 metadata: %{order_id: "GPA.1111-2222-3333-44444"}
               })

      assert result.acknowledgement_state == :pending
      assert result.consumption_state == :not_consumed
    end
  end
end
