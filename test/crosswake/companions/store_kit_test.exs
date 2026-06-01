defmodule Crosswake.Companions.StoreKitTest do
  use ExUnit.Case, async: true

  alias Crosswake.Commerce.Contracts
  alias Crosswake.Commerce.Reconciliation
  alias Crosswake.Companion.State
  alias Crosswake.Companions.StoreKit
  alias Crosswake.Companions.StoreKit.Evidence

  describe "companion state" do
    test "reports companion state with commerce provider surface" do
      assert %State{} = state = StoreKit.report_state()
      assert state.companion_id == :storekit
      assert is_boolean(state.enabled)
      assert state.details == %{surface: :commerce_provider, provider: :storekit, mode: :evidence_adapter}
    end
  end

  describe "evidence mapping" do
    test "maps storekit purchase evidence into reconciliation evidence" do
      attrs = %{
        original_transaction_id: "1000000123456789",
        transaction_id: "2000000123456789",
        event_kind: :purchase,
        environment: :sandbox,
        source: :storefront,
        captured_at: "2026-06-01T10:00:00Z"
      }

      assert {:ok, evidence} = Evidence.new(attrs)
      assert {:ok, %Contracts.ReconciliationEvidence{} = normalized} = Evidence.to_reconciliation_evidence(evidence)

      assert normalized.provider == "storekit"
      assert normalized.provider_reference == "1000000123456789"
      assert normalized.evidence_ref == "2000000123456789"
      assert normalized.event_kind == "purchase"
      assert normalized.source == :storefront

      assert {:ok, result} = Reconciliation.ingest_evidence(normalized)
      assert result.status == :awaiting_verification
    end

    test "maps restore, renewal, refund, and revoked evidence kinds" do
      for {event_kind, suffix} <- [restore: "1", renewal: "2", refund: "3", revoked: "4"] do
        assert {:ok, evidence} =
                 Evidence.new(%{
                   original_transaction_id: "1000000123456789",
                   transaction_id: "200000012345678#{suffix}",
                   event_kind: event_kind,
                   environment: :production,
                   source: :storefront,
                   captured_at: "2026-06-01T10:00:00Z"
                 })

        assert {:ok, normalized} = Evidence.to_reconciliation_evidence(evidence)
        assert normalized.event_kind == Atom.to_string(event_kind)
      end
    end

    test "requires original_transaction_id as provider subject lineage" do
      assert {:error, {:missing_field, :original_transaction_id}} =
               Evidence.new(%{
                 transaction_id: "2000000123456789",
                 event_kind: :purchase,
                 environment: :sandbox,
                 source: :storefront,
                 captured_at: "2026-06-01T10:00:00Z"
               })
    end

    test "rejects raw storekit status as event_kind" do
      assert {:error, {:invalid_event_kind, details}} =
               Evidence.new(%{
                 original_transaction_id: "1000000123456789",
                 transaction_id: "2000000123456789",
                 event_kind: :did_renew,
                 environment: :sandbox,
                 source: :storefront,
                 captured_at: "2026-06-01T10:00:00Z"
               })

      assert details[:event_kind] == :did_renew
    end

    test "rejects authority mutation attempt when evidence is ingested" do
      assert {:ok, evidence} =
               Evidence.new(%{
                 original_transaction_id: "1000000123456789",
                 transaction_id: "2000000123456789",
                 event_kind: :purchase,
                 environment: :sandbox,
                 source: :storefront,
                 captured_at: "2026-06-01T10:00:00Z"
               })

      assert {:ok, normalized} = Evidence.to_reconciliation_evidence(evidence)

      assert {:error, :authority_lane_mutation_forbidden} =
               Reconciliation.ingest_evidence(normalized, authority_state: :active)
    end
  end
end
