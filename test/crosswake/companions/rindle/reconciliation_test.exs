defmodule Crosswake.Companions.Rindle.ReconciliationTest do
  use ExUnit.Case, async: true

  alias Crosswake.Companions.Rindle.Contracts
  alias Crosswake.Companions.Rindle.Reconciliation

  describe "media reconciliation outcome vocabulary" do
    test "locks the backend-owned outcome vocabulary" do
      assert Reconciliation.outcome_vocabulary() == [
               :queued_capture,
               :upload_recorded,
               :awaiting_verification,
               :verification_in_progress,
               :projection_refreshed,
               :verification_failed,
               :rejected,
               :conflict,
               :stale_authority
             ]

      assert Reconciliation.reconciliation_outcome?(:awaiting_verification)
      refute Reconciliation.reconciliation_outcome?(:available)
    end

    test "separates unresolved workflow states from reporting outcomes" do
      assert Reconciliation.unresolved_outcome?(:awaiting_verification)
      assert Reconciliation.unresolved_outcome?(:verification_in_progress)

      assert Reconciliation.workflow_reporting_outcome?(:projection_refreshed)
      assert Reconciliation.workflow_reporting_outcome?(:verification_failed)
      assert Reconciliation.workflow_reporting_outcome?(:rejected)
    end

    test "no reconciliation outcome implies availability" do
      for outcome <- Reconciliation.outcome_vocabulary() do
        refute Reconciliation.outcome_implies_availability?(outcome)
      end

      refute Reconciliation.outcome_implies_availability?(:available)
    end
  end

  describe "capture evidence ingestion availability fence" do
    test "maps success-like upload evidence to awaiting verification, not availability" do
      evidence = sample_evidence()

      assert {:ok, result} = Reconciliation.ingest_capture_evidence(evidence)

      assert %Reconciliation.EvidenceResult{} = result
      assert result.status == :awaiting_verification
      assert result.attempt.status == :awaiting_verification
      refute result.status == :available
      refute Reconciliation.availability_mutation_allowed_from_evidence?(evidence)
    end

    test "returns evidence results and never media objects" do
      assert {:ok, result} = Reconciliation.ingest_capture_evidence(sample_evidence())

      assert %Reconciliation.EvidenceResult{} = result
      refute match?(%Contracts.MediaObject{}, result)
    end

    test "marks duplicate stable idempotency keys as replay despite changed correlation ids" do
      assert {:ok, first_result} =
               Reconciliation.ingest_capture_evidence(sample_evidence(%{correlation_id: "corr_1"}))

      assert {:ok, replay_result} =
               Reconciliation.ingest_capture_evidence(
                 sample_evidence(%{correlation_id: "corr_2"}),
                 seen_idempotency_keys: MapSet.new([first_result.idempotency_key])
               )

      assert replay_result.replay?
      assert replay_result.idempotency_key == first_result.idempotency_key
    end

    test "rejects invalid source values before creating evidence results" do
      evidence = sample_evidence(%{source: :device_callback})

      assert {:error, [source: {:invalid_source, details}]} =
               Reconciliation.ingest_capture_evidence(evidence)

      assert Keyword.fetch!(details, :source) == :device_callback
    end

    test "rejects direct authority and availability overrides" do
      evidence = sample_evidence()

      assert Reconciliation.ingest_capture_evidence(evidence, authority_state: :available) ==
               {:error, :authority_lane_mutation_forbidden}

      assert Reconciliation.ingest_capture_evidence(evidence, availability_state: :available) ==
               {:error, :availability_lane_mutation_forbidden}
    end
  end

  describe "backend verification availability path" do
    test "evidence ingestion alone does not create available media" do
      assert {:ok, result} = Reconciliation.ingest_capture_evidence(sample_evidence())

      refute match?(%Contracts.MediaObject{state: :available}, result)
      refute result.status == :available
    end

    test "verified_media_object promotes scanning media only with backend verification fields" do
      scanning_object = media_object(%{state: :scanning})

      assert {:ok, verified} =
               Contracts.verified_media_object(scanning_object,
                 verification_ref: "ver_1",
                 authoritative_at: "2026-05-31T00:00:00Z"
               )

      assert verified.state == :available
      assert verified.verification_ref == "ver_1"

      assert Contracts.verified_media_object(scanning_object, []) ==
               {:error, :backend_verification_required}
    end

    test "verified_media_object rejects queued and terminal states" do
      opts = [verification_ref: "ver_1", authoritative_at: "2026-05-31T00:00:00Z"]

      assert Contracts.verified_media_object(media_object(%{state: :queued}), opts) ==
               {:error, {:invalid_source_state, :queued}}

      assert Contracts.verified_media_object(
               media_object(%{
                 state: :available,
                 verification_ref: "ver_1",
                 authoritative_at: "2026-05-31T00:00:00Z"
               }),
               opts
             ) == {:error, {:invalid_source_state, :available}}

      assert Contracts.verified_media_object(
               media_object(%{state: :rejected, rejection_reason: :policy_rejected}),
               opts
             ) == {:error, {:invalid_source_state, :rejected}}
    end
  end

  defp sample_evidence(overrides \\ %{}) do
    base = %{
      grant_id: "grant_123",
      idempotency_key: "idem_123",
      storage_key: "uploads/user_123/photo.jpg",
      mime: "image/jpeg",
      bytes: 1024,
      captured_at: "2026-05-31T00:01:00Z",
      client_upload_ref: "local_upload_123",
      content_hash: "sha256:abc123",
      correlation_id: "corr_1",
      trace_metadata: %{queue_ref: "local_1"},
      source: :device
    }

    struct!(Contracts.CaptureEvidence, Map.merge(base, overrides))
  end

  defp media_object(overrides) do
    base = %{
      media_object_id: "media_123",
      subject_key: "user:user_123",
      storage_key: "uploads/user_123/photo.jpg",
      state: :uploaded,
      as_of: "2026-05-31T00:02:00Z",
      trace_metadata: %{grant_id: "grant_123"}
    }

    struct!(Contracts.MediaObject, Map.merge(base, overrides))
  end
end
