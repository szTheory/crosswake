defmodule Crosswake.Commerce.ReconciliationTest do
  use ExUnit.Case, async: true

  alias Crosswake.Commerce.Reconciliation
  alias Crosswake.Commerce.Contracts

  describe "reconciliation outcome vocabulary" do
    test "distinguishes evidence processing outcomes from authority semantics" do
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
  end

  describe "evidence ingestion authority separation" do
    test "maps unverified evidence to awaiting_verification and never to active authority" do
      evidence = sample_evidence()

      assert {:ok, result} = Reconciliation.ingest_evidence(evidence)
      assert result.status == :awaiting_verification
      assert result.attempt.status == :awaiting_verification
      refute result.attempt.status == :active
      refute Reconciliation.authority_mutation_allowed_from_evidence?(evidence)
    end

    test "allows projection_refreshed only with backend verification marker" do
      evidence = sample_evidence()

      assert {:ok, awaiting_result} = Reconciliation.ingest_evidence(evidence)
      assert awaiting_result.status == :awaiting_verification

      assert {:ok, verified_result} =
               Reconciliation.ingest_evidence(evidence, verified_projection: true)

      assert verified_result.status == :projection_refreshed
      refute verified_result.attempt.status == :active
    end

    test "marks duplicate evidence as replay and keeps authority non-granting" do
      evidence = sample_evidence()

      assert {:ok, first_result} = Reconciliation.ingest_evidence(evidence)

      assert {:ok, replay_result} =
               Reconciliation.ingest_evidence(
                 evidence,
                 seen_idempotency_keys: [first_result.idempotency_key]
               )

      assert replay_result.replay?
      assert replay_result.idempotency_key == first_result.idempotency_key
      assert replay_result.status == :awaiting_verification
      refute replay_result.attempt.status == :active
    end

    test "unknown evidence kinds fail closed" do
      evidence = sample_evidence(%{event_kind: "new_provider_status"})

      assert {:ok, result} = Reconciliation.ingest_evidence(evidence)
      assert result.status == :verification_failed
      refute result.attempt.status == :active
    end

    test "rejects attempts to set authority lane from evidence input" do
      evidence = sample_evidence()

      assert {:error, :authority_lane_mutation_forbidden} =
               Reconciliation.ingest_evidence(evidence, authority_state: :active)
    end
  end

  defp sample_evidence(overrides \\ %{}) do
    base = %{
      source: :device,
      provider: "app_store",
      provider_reference: "tx_123",
      event_kind: "purchase",
      evidence_ref: "receipt_ref_123",
      captured_at: "2023-01-01T12:00:00Z",
      integrity_digest: "sha256:abc123",
      idempotency_ref: "idem_123"
    }

    struct!(Contracts.ReconciliationEvidence, Map.merge(base, overrides))
  end
end
