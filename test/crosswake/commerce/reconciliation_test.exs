defmodule Crosswake.Commerce.ReconciliationTest do
  use ExUnit.Case, async: true

  alias Crosswake.Commerce.Reconciliation

  describe "reconciliation attempt types and outcomes" do
    test "distinguishes evidence submission, verification, projection refresh, conflict, failure, and stale authority states" do
      # Attempt should capture idempotency and evidence
      attempt = %Reconciliation.Attempt{
        provider: :app_store,
        provider_reference: "tx_123",
        event_kind: :purchase,
        correlation_id: "corr_456", # Supplemental
        evidence_token: "receipt_data",
        status: :pending_purchase
      }

      assert attempt.status == :pending_purchase

      # Outcomes distinguish evidence vs authority
      assert Reconciliation.outcome_vocabulary() == [
        :pending_purchase,
        :pending_restore,
        :awaiting_verification,
        :projection_refreshed,
        :conflict,
        :verification_failed,
        :stale_authority
      ]
    end

    test "idempotency fields are provider-aware and backend-owned, instead of transient device correlation ids" do
      # Idempotency relies on provider, reference, and kind, NOT correlation_id
      idempotency_key = %Reconciliation.IdempotencyKey{
        provider: :play_store,
        provider_reference: "GPA.1234-5678",
        event_kind: :renewal
      }

      assert idempotency_key.provider == :play_store
      assert idempotency_key.provider_reference == "GPA.1234-5678"
      assert idempotency_key.event_kind == :renewal
      refute Map.has_key?(idempotency_key, :correlation_id)
    end

    test "device purchase success, restore success, and native callback success remain evidence-only result states" do
      evidence_result = %Reconciliation.EvidenceResult{
        source: :device_purchase,
        status: :submitted,
        attempt: %Reconciliation.Attempt{
          provider: :app_store,
          provider_reference: "tx_123",
          event_kind: :purchase,
          status: :pending_purchase
        }
      }

      # These outcomes shouldn't grant access
      assert evidence_result.status == :submitted
      assert evidence_result.attempt.status == :pending_purchase
      refute Map.has_key?(evidence_result, :access_state)
      refute Map.has_key?(evidence_result, :authority_state)
    end
  end
end
