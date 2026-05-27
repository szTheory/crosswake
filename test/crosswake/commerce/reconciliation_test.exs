defmodule Crosswake.Commerce.ReconciliationTest do
  use ExUnit.Case, async: true

  alias Crosswake.Commerce.Contracts
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

      assert Reconciliation.reconciliation_outcome?(:pending_purchase)
      assert Reconciliation.reconciliation_outcome?(:pending_restore)
      assert Reconciliation.reconciliation_outcome?(:awaiting_verification)
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

    test "pending and verification outcomes stay reconciliation-only and never become authority grants" do
      assert Reconciliation.unresolved_outcome?(:pending_purchase)
      assert Reconciliation.unresolved_outcome?(:pending_restore)
      assert Reconciliation.unresolved_outcome?(:awaiting_verification)

      refute Reconciliation.outcome_implies_authority_grant?(:pending_purchase)
      refute Reconciliation.outcome_implies_authority_grant?(:pending_restore)
      refute Reconciliation.outcome_implies_authority_grant?(:awaiting_verification)
    end

    test "reconciliation outcomes do not imply access granted decisions" do
      for outcome <- Reconciliation.outcome_vocabulary() do
        refute Reconciliation.outcome_implies_access_granted?(outcome)
      end

      assert Reconciliation.workflow_reporting_outcome?(:projection_refreshed)
      assert Reconciliation.workflow_reporting_outcome?(:verification_failed)
      assert Reconciliation.workflow_reporting_outcome?(:conflict)
      assert Reconciliation.workflow_reporting_outcome?(:stale_authority)
    end

    test "reconciliation outcomes are rejected when treated as authority states" do
      {:error, errors} =
        Contracts.new_entitlement_snapshot(
          snapshot_attrs(%{
            authority: %Contracts.EntitlementSnapshot.AuthorityLane{state: :pending_restore}
          })
        )

      assert {:authority, {:invalid_state, :pending_restore}} in errors
      refute Reconciliation.outcome_implies_authority_grant?(:pending_restore)
    end
  end

  defp snapshot_attrs(overrides) do
    base_attrs = %{
      group_id: "premium",
      authority: %Contracts.EntitlementSnapshot.AuthorityLane{state: :active},
      access: %Contracts.EntitlementSnapshot.AccessLane{decision: :granted, reason: :active_subscription},
      reconciliation: %Contracts.EntitlementSnapshot.ReconciliationLane{
        state: :projection_refreshed,
        reference: "attempt_123"
      },
      freshness: %Contracts.EntitlementSnapshot.FreshnessLane{
        state: :fresh,
        checked_at: "2023-01-01T12:00:00Z",
        stale_after: "2023-01-01T13:00:00Z"
      },
      effective: %Contracts.EntitlementSnapshot.EffectiveLane{
        effective_from: "2023-01-01T12:00:00Z",
        effective_until: "2023-02-01T12:00:00Z"
      },
      evidence: %Contracts.EntitlementSnapshot.EvidenceLane{
        source: :storefront,
        reference: "tx_123",
        observed_at: "2023-01-01T12:00:00Z"
      },
      as_of: 42
    }

    Map.merge(base_attrs, overrides)
  end
end
