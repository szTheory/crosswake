Code.require_file(
  "../../../examples/phoenix_host/lib/crosswake_example/media/reconciliation_keys.ex",
  __DIR__
)

Code.require_file(
  "../../../examples/phoenix_host/lib/crosswake_example/media/reconciliation_inbox.ex",
  __DIR__
)

Code.require_file(
  "../../../examples/phoenix_host/lib/crosswake_example/media/mock_capture.ex",
  __DIR__
)

Code.require_file(
  "../../../examples/phoenix_host/lib/crosswake_example/media/media_projection.ex",
  __DIR__
)

defmodule Crosswake.Proof.Phase72MediaEvidenceWorkflowProofTest do
  use ExUnit.Case, async: false

  alias Crosswake.Companions.Rindle.Contracts
  alias Crosswake.Companions.Rindle.Reconciliation
  alias CrosswakeExample.Media.MockCapture
  alias CrosswakeExample.Media.ReconciliationInbox
  alias CrosswakeExample.Media.MediaProjection

  defmodule QueuedCapture do
    defstruct [
      :grant,
      :evidence,
      :state,
      :queue_ref,
      :network_state,
      :last_failure
    ]
  end

  defmodule LocalUploadQueue do
    def degraded_capture_recorded(%Contracts.UploadGrant{} = grant) do
      %QueuedCapture{
        grant: grant,
        state: :degraded_capture_recorded,
        queue_ref: "local_queue_72",
        network_state: :degraded_capture_recorded
      }
    end

    def upload_attempt_failed(%QueuedCapture{} = queued, reason) do
      %QueuedCapture{queued | state: :upload_attempt_failed, network_state: :upload_attempt_failed, last_failure: reason}
    end

    def queued_capture(%QueuedCapture{} = queued, %Contracts.CaptureEvidence{} = evidence) do
      %QueuedCapture{queued | evidence: evidence, state: :queued_capture, network_state: :queued_capture}
    end

    def network_recovered(%QueuedCapture{} = queued) do
      %QueuedCapture{queued | network_state: :network_recovered}
    end
  end

  @fixed_now "2026-06-05T00:00:00Z"
  @hostile_values [
    "raw-payload-must-not-leak",
    "/private/var/mobile/capture.jpg",
    "route-secret",
    "actor-private",
    "session-private",
    "device-private",
    "person@example.test",
    "203.0.113.72",
    "private-user-agent",
    "raw-" <> "storage-credential",
    "availability:available",
    "authority:verified"
  ]

  describe "degraded capture recovery over Rindle evidence" do
    test "degraded_capture_reconciles_after_recovery_without_availability" do
      {:ok, grant} = MockCapture.issue_upload_grant("user_72", expires_at: "2026-06-05T00:15:00Z")

      queued =
        grant
        |> LocalUploadQueue.degraded_capture_recorded()
        |> LocalUploadQueue.upload_attempt_failed(:simulated_degraded_network)

      assert queued.state == :upload_attempt_failed

      {:ok, evidence} =
        MockCapture.emit_capture_evidence(grant,
          captured_at: @fixed_now,
          queue_ref: queued.queue_ref,
          correlation_id: "corr_degraded"
        )

      queued =
        queued
        |> LocalUploadQueue.queued_capture(evidence)
        |> LocalUploadQueue.network_recovered()

      assert queued.state == :queued_capture
      assert queued.network_state == :network_recovered

      assert {:ok, ingestion} =
               ReconciliationInbox.ingest_capture_evidence(queued.evidence,
                 correlation_id: "corr_recovered"
               )

      assert ingestion.status == :awaiting_verification
      assert ingestion.result.status == :awaiting_verification
      refute Reconciliation.outcome_implies_availability?(ingestion.status)

      assert {:ok, projected} = MediaProjection.project_object(nil, ingestion)
      assert projected.state in [:uploaded, :scanning]
      refute projected.state == :available

      assert {:ok, available} =
               MediaProjection.project_object(projected, %{
                 backend_verified: true,
                 media_object_id: projected.media_object_id,
                 subject_key: projected.subject_key,
                 storage_key: projected.storage_key,
                 verification_ref: "verify_media_72",
                 authoritative_at: @fixed_now
               })

      assert available.state == :available
      assert available.verification_ref == "verify_media_72"
      assert available.authoritative_at == @fixed_now
    end
  end

  describe "replay, multipart, integrity, and authority matrix" do
    test "multipart_completion_requires_full_payload" do
      {:ok, evidence} = evidence(multipart: %{parts_total: 3, parts_uploaded: 3, completed?: true})

      assert {:ok, ingestion} =
               ReconciliationInbox.ingest_capture_evidence(evidence, event_kind: "multipart_complete")

      assert ingestion.status == :awaiting_verification
      assert {:ok, projected} = MediaProjection.project_object(nil, ingestion)
      refute projected.state == :available
    end

    test "idempotent_replay_ignores_trace_correlation" do
      {:ok, evidence} = evidence(correlation_id: "corr_first")
      assert {:ok, first} = ReconciliationInbox.ingest_capture_evidence(evidence, correlation_id: "corr_first")

      assert {:ok, replay} =
               ReconciliationInbox.ingest_capture_evidence(evidence,
                 correlation_id: "corr_second",
                 seen_event_keys: [first.event_key],
                 seen_idempotency_keys: [first.result.idempotency_key]
               )

      assert replay.replay? == true
      assert replay.event_key == first.event_key
      assert replay.result.idempotency_key == first.result.idempotency_key
      assert replay.trace_metadata.correlation_id == "corr_second"
    end

    test "scan_started_then_verified" do
      {:ok, evidence} = evidence()
      assert {:ok, ingestion} = ReconciliationInbox.ingest_capture_evidence(evidence, backend_scan_started: true)
      assert ingestion.status == :verification_in_progress

      assert {:ok, scanning} = MediaProjection.project_object(nil, ingestion)
      assert scanning.state == :scanning

      assert {:ok, available} =
               MediaProjection.project_object(scanning, %{
                 backend_verified: true,
                 media_object_id: scanning.media_object_id,
                 subject_key: scanning.subject_key,
                 storage_key: scanning.storage_key,
                 verification_ref: "verify_media_72",
                 authoritative_at: @fixed_now
               })

      assert available.state == :available
    end

    test "stale_grant_is_rejected_before_reconciliation" do
      {:ok, stale_grant} = MockCapture.issue_upload_grant("user_72", expires_at: "2026-06-04T23:59:00Z")
      assert {:ok, evidence} = MockCapture.emit_capture_evidence(stale_grant, captured_at: @fixed_now)

      assert {:ok, ingestion} =
               ReconciliationInbox.ingest_capture_evidence(evidence, grant_expired?: true)

      assert ingestion.status == :stale_authority
      refute Reconciliation.outcome_implies_availability?(ingestion.status)
    end

    test "missing_payload_identity_is_rejected" do
      assert {:error, errors} =
               Contracts.new_capture_evidence(%{
                 grant_id: "grant_media_72",
                 idempotency_key: "idem_72",
                 storage_key: "",
                 mime: "image/jpeg",
                 bytes: 1024,
                 captured_at: @fixed_now,
                 source: :device
               })

      assert {:storage_key, :required} in errors
    end

    test "partial_multipart_cannot_complete_upload" do
      {:ok, evidence} = evidence(multipart: %{parts_total: 3, parts_uploaded: 2, completed?: false})

      assert {:ok, ingestion} =
               ReconciliationInbox.ingest_capture_evidence(evidence, event_kind: "multipart_complete")

      assert ingestion.status == :upload_recorded
      assert {:ok, projected} = MediaProjection.project_object(nil, ingestion)
      refute projected.state == :available
    end

    test "corrupt_hash_or_unsupported_integrity_is_rejected" do
      for opts <- [[content_hash: "sha256:corrupt"], [integrity_algorithm: "md5"]] do
        {:ok, evidence} = evidence(opts)
        assert {:ok, ingestion} = ReconciliationInbox.ingest_capture_evidence(evidence)
        assert ingestion.status in [:verification_failed, :rejected]
        refute Reconciliation.outcome_implies_availability?(ingestion.status)
      end
    end

    test "backend_scan_failure_projects_rejected_or_verification_failed" do
      {:ok, evidence} = evidence()
      assert {:ok, ingestion} = ReconciliationInbox.ingest_capture_evidence(evidence, backend_scan_failed: true)
      assert ingestion.status == :verification_failed

      assert {:ok, projected} = MediaProjection.project_object(nil, ingestion)
      assert projected.state == :rejected
      assert projected.rejection_reason
    end

    test "direct_availability_override_is_forbidden" do
      {:ok, evidence} = evidence()

      assert Reconciliation.ingest_capture_evidence(evidence, availability_state: :available) ==
               {:error, :availability_lane_mutation_forbidden}

      assert Reconciliation.ingest_capture_evidence(evidence, authority_state: :verified) ==
               {:error, :authority_lane_mutation_forbidden}
    end

    test "invalid_or_spoofed_evidence_source_is_rejected" do
      assert {:error, errors} =
               Contracts.new_capture_evidence(%{
                 grant_id: "grant_media_72",
                 idempotency_key: "idem_72",
                 storage_key: "media/user_72/photo_72/capture.jpg",
                 mime: "image/jpeg",
                 bytes: 1024,
                 captured_at: @fixed_now,
                 source: :device_callback
               })

      assert {:source, {:invalid_source, details}} = List.keyfind(errors, :source, 0)
      assert Keyword.fetch!(details, :source) == :device_callback
    end

    test "available_media_requires_backend_fields" do
      assert {:error, errors} =
               Contracts.new_media_object(%{
                 media_object_id: "media_72",
                 subject_key: "subject::media::user_72",
                 storage_key: "media/user_72/photo_72/capture.jpg",
                 state: :available,
                 as_of: @fixed_now
               })

      assert {:state, :backend_verification_required} in errors
    end
  end

  describe "redaction and hermeticity guards" do
    test "hostile metadata is absent from public details and inspected proof output" do
      {:ok, evidence} = evidence(trace_metadata: hostile_metadata())
      assert {:ok, ingestion} = ReconciliationInbox.ingest_capture_evidence(evidence)

      details = inspect(ingestion.trace_metadata)
      inspected = inspect(ingestion)

      for value <- @hostile_values do
        refute details =~ value
        refute inspected =~ value
      end
    end

    test "hermeticity self-scan allows only proof-safe media helpers" do
      source = File.read!(__ENV__.file)

      required_paths =
        ~r/Code\.require_file\(\s*"([^"]+)"/
        |> Regex.scan(source, capture: :all_but_first)
        |> List.flatten()
        |> Enum.map(&Path.basename/1)

      assert Enum.sort(required_paths) ==
               Enum.sort([
                 "reconciliation_keys.ex",
                 "reconciliation_inbox.ex",
                 "mock_capture.ex",
                 "media_projection.ex"
               ])

      forbidden_path_tokens = [
        "_live",
        "endpoint",
        "application",
        "router",
        "repo",
        "_web",
        "storage",
        "native",
        "ios",
        "android",
        "provider",
        "background"
      ]

      for path <- required_paths, token <- forbidden_path_tokens do
        refute String.contains?(path, token)
      end
    end

    test "proof source avoids process server network provider native and storage claims" do
      source = File.read!(__ENV__.file) |> String.downcase()

      scanned_source =
        source
        |> strip_function("hostile_metadata")
        |> strip_function("forbidden_runtime_tokens")

      for token <- forbidden_runtime_tokens() do
        refute Regex.match?(~r/(^|[^a-z0-9_])#{Regex.escape(token)}([^a-z0-9_]|$)/, scanned_source),
               "proof leaked forbidden runtime token #{inspect(token)}"
      end
    end
  end

  defp evidence(opts \\ []) do
    {:ok, grant} = MockCapture.issue_upload_grant("user_72", expires_at: "2026-06-05T00:15:00Z")
    MockCapture.emit_capture_evidence(grant, Keyword.put_new(opts, :captured_at, @fixed_now))
  end

  defp hostile_metadata do
    %{
      raw_payload: "raw-payload-must-not-leak",
      local_path: "/private/var/mobile/capture.jpg",
      route_params: "route-secret",
      actor_ref: "actor-private",
      session_ref: "session-private",
      device_id: "device-private",
      email: "person@example.test",
      ip: "203.0.113.72",
      user_agent: "private-user-agent",
      raw_credential: "raw-" <> "storage-credential",
      availability_hint: "availability:available",
      authority_hint: "authority:verified"
    }
  end

  defp strip_function(source, function_name) do
    Regex.replace(~r/  defp #{function_name} do.*?^  end/ms, source, "")
  end

  defp forbidden_runtime_tokens do
    [
      "system.cmd",
      "start_supervised",
      "phoenix.pubsub",
      "liveviewtest",
      "req.",
      "finch.",
      "store" <> "kit",
      "play" <> "billing",
      "s" <> "3",
      "g" <> "cs",
      "az" <> "ure",
      "t" <> "us",
      "url" <> "session",
      "work" <> "manager",
      "bg" <> "processing" <> "task"
    ]
  end
end
