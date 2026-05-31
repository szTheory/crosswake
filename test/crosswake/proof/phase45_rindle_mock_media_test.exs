Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/media/reconciliation_keys.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/media/reconciliation_inbox.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/media/mock_capture.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/media/media_projection.ex", __DIR__)

defmodule Crosswake.Proof.Phase45RindleMockMediaTest do
  use ExUnit.Case, async: false

  alias Crosswake.Companions.Rindle.Contracts
  alias CrosswakeExample.Media.{MediaProjection, MockCapture, ReconciliationInbox, ReconciliationKeys}

  test "mock capture issues valid grants and device evidence through Phase 44 contracts" do
    assert {:ok, %Contracts.UploadGrant{} = grant} = MockCapture.issue_upload_grant("user_123")
    assert {:ok, %Contracts.CaptureEvidence{} = evidence} = MockCapture.emit_capture_evidence(grant)

    assert grant.idempotency_key == evidence.idempotency_key
    assert evidence.source == :device
  end

  test "stable event keys ignore changed correlation ids and replay is marked" do
    {:ok, grant} = MockCapture.issue_upload_grant("user_123")
    {:ok, first_evidence} = MockCapture.emit_capture_evidence(grant, correlation_id: "corr_1")
    {:ok, second_evidence} = MockCapture.emit_capture_evidence(grant, correlation_id: "corr_2")

    assert ReconciliationKeys.event_key(first_evidence, "capture_uploaded") ==
             ReconciliationKeys.event_key(second_evidence, "capture_uploaded")

    assert {:ok, first} = ReconciliationInbox.ingest_capture_evidence(first_evidence, correlation_id: "corr_1")

    assert {:ok, replay} =
             ReconciliationInbox.ingest_capture_evidence(second_evidence,
               correlation_id: "corr_2",
               seen_event_keys: [first.event_key],
               seen_idempotency_keys: [first.result.idempotency_key]
             )

    assert replay.replay?
    assert replay.event_key == first.event_key
    assert replay.trace_metadata.correlation_id == "corr_2"
  end

  test "missing or mismatched idempotency key is rejected before evidence is emitted" do
    {:ok, grant} = MockCapture.issue_upload_grant("user_123")

    assert MockCapture.emit_capture_evidence(grant, idempotency_key: "") ==
             {:error, :idempotency_key_required}

    assert MockCapture.emit_capture_evidence(grant, idempotency_key: "different") ==
             {:error, :idempotency_key_mismatch}
  end

  test "evidence-only ingestion cannot produce available media" do
    {:ok, grant} = MockCapture.issue_upload_grant("user_123")
    {:ok, evidence} = MockCapture.emit_capture_evidence(grant)
    {:ok, ingestion} = ReconciliationInbox.ingest_capture_evidence(evidence)

    assert {:ok, media_object} = MediaProjection.project_object(nil, ingestion)
    assert media_object.state == :uploaded
    refute media_object.state == :available
  end

  test "projection can model scanning and only backend verification produces available" do
    {:ok, grant} = MockCapture.issue_upload_grant("user_123")
    {:ok, evidence} = MockCapture.emit_capture_evidence(grant)
    {:ok, scanning_ingestion} = ReconciliationInbox.ingest_capture_evidence(evidence, backend_scan_started: true)

    assert {:ok, scanning} = MediaProjection.project_object(nil, scanning_ingestion)
    assert scanning.state == :scanning

    assert {:ok, available} =
             MediaProjection.project_object(scanning, %{
               backend_verified: true,
               media_object_id: scanning.media_object_id,
               subject_key: scanning.subject_key,
               storage_key: scanning.storage_key,
               verification_ref: "verify_123",
               authoritative_at: "2026-05-31T00:03:00Z"
             })

    assert available.state == :available
  end

  test "queued media remains queued and is not treated as committed" do
    queued =
      struct!(Contracts.MediaObject, %{
        media_object_id: "media_queued",
        subject_key: "subject::media::user_123",
        storage_key: "media/user_123/photo_123/capture.jpg",
        state: :queued,
        as_of: 1
      })

    assert MediaProjection.derived_state(queued) == :queued
  end

  test "media mock source contains no provider SDK vocabulary or upload shortcut" do
    files = [
      "examples/phoenix_host/lib/crosswake_example/media/mock_capture.ex",
      "examples/phoenix_host/lib/crosswake_example/media/reconciliation_inbox.ex",
      "examples/phoenix_host/lib/crosswake_example/media/media_projection.ex"
    ]

    forbidden = ["s" <> "3", "g" <> "cs", "az" <> "ure", "t" <> "us", "store" <> "kit", "play" <> "_billing"]

    for file <- files do
      source = File.read!(file) |> String.downcase()

      refute source =~ "upload_and_verify"

      for token <- forbidden do
        refute Regex.match?(~r/(^|[^a-z0-9_])#{Regex.escape(token)}([^a-z0-9_]|$)/, source),
               "#{file} leaked forbidden token #{inspect(token)}"
      end
    end
  end
end
