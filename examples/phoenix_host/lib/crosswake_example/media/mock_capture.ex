defmodule CrosswakeExample.Media.MockCapture do
  @moduledoc """
  Pure-Elixir mock media capture evidence emitter for the example host.

  Grant creation and capture evidence emission are intentionally separate so
  the proof lane can show the authority boundary: device evidence records an
  upload attempt, while backend verification owns availability.
  """

  alias Crosswake.Companions.Rindle.Contracts

  @default_subject "user_123"
  @default_media "photo_123"
  @default_idempotency "media-idem-123"

  @spec issue_upload_grant(String.t(), keyword()) ::
          {:ok, Contracts.UploadGrant.t()} | {:error, keyword()}
  def issue_upload_grant(subject_id \\ @default_subject, opts \\ []) do
    media_id = Keyword.get(opts, :media_id, @default_media)
    idempotency_key = Keyword.get(opts, :idempotency_key, @default_idempotency)
    key_prefix = "media/#{subject_id}/#{media_id}/"

    Contracts.new_upload_grant(%{
      grant_id: "grant_#{media_id}",
      idempotency_key: idempotency_key,
      expires_at: Keyword.get_lazy(opts, :expires_at, &default_expires_at/0),
      max_bytes: Keyword.get(opts, :max_bytes, 5_000_000),
      accepted_types: Keyword.get(opts, :accepted_types, ["image/jpeg", "image/png"]),
      key_prefix: key_prefix,
      storage_target: Keyword.get(opts, :storage_target, "mock"),
      integrity_algorithms: ["sha256"]
    })
  end

  @spec emit_capture_evidence(Contracts.UploadGrant.t(), keyword()) ::
          {:ok, Contracts.CaptureEvidence.t()} | {:error, term()}
  def emit_capture_evidence(%Contracts.UploadGrant{} = grant, opts \\ []) do
    with :ok <-
           validate_idempotency(grant, Keyword.get(opts, :idempotency_key, grant.idempotency_key)) do
      Contracts.new_capture_evidence(%{
        grant_id: grant.grant_id,
        idempotency_key: Keyword.get(opts, :idempotency_key, grant.idempotency_key),
        storage_key: Keyword.get(opts, :storage_key, grant.key_prefix <> "capture.jpg"),
        mime: Keyword.get(opts, :mime, "image/jpeg"),
        bytes: Keyword.get(opts, :bytes, 1024),
        captured_at: Keyword.get_lazy(opts, :captured_at, &now_iso/0),
        client_upload_ref: Keyword.get(opts, :client_upload_ref, "local_upload_123"),
        content_hash: Keyword.get(opts, :content_hash, "sha256:abc123"),
        correlation_id: Keyword.get(opts, :correlation_id, "corr_1"),
        trace_metadata: %{queue_ref: Keyword.get(opts, :queue_ref, "local_queue_1")},
        source: :device
      })
    end
  end

  defp validate_idempotency(_grant, value) when not is_binary(value) or byte_size(value) == 0 do
    {:error, :idempotency_key_required}
  end

  defp validate_idempotency(%Contracts.UploadGrant{idempotency_key: expected}, actual) do
    if actual == expected do
      :ok
    else
      {:error, :idempotency_key_mismatch}
    end
  end

  defp default_expires_at do
    DateTime.utc_now()
    |> DateTime.add(15 * 60, :second)
    |> DateTime.to_iso8601()
  end

  defp now_iso, do: DateTime.utc_now() |> DateTime.to_iso8601()
end
