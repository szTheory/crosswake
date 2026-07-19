defmodule CrosswakeExample.Media.MediaLaneLive do
  use Phoenix.LiveView

  alias CrosswakeExample.PageTitle
  alias Crosswake.Companions.Rindle.Contracts
  alias CrosswakeExample.Media.{MediaProjection, MockCapture, ReconciliationInbox}

  @impl true
  def mount(_params, _session, socket) do
    with {:ok, grant} <- MockCapture.issue_upload_grant("user_123"),
         {:ok, queued} <- queued_media_object(grant) do
      {:ok,
       assign(socket,
         grant: grant,
         media_object: queued,
         derived_state: MediaProjection.derived_state(queued),
         page_title: PageTitle.crosswake("Media Proof"),
         proof_step: :queued,
         network_state: :ready,
         seen_event_keys: [],
         last_attempt: nil,
         error_message: nil
       )}
    else
      {:error, reason} ->
        {:ok,
         socket
         |> assign(
           grant: nil,
           media_object: nil,
           derived_state: :rejected,
           page_title: PageTitle.crosswake("Media Proof"),
           proof_step: :unavailable,
           network_state: :unavailable,
           seen_event_keys: [],
           last_attempt: nil,
           error_message: nil
         )
         |> put_error("Media lane unavailable: #{inspect(reason)}")}
    end
  end

  defp queued_media_object(%Contracts.UploadGrant{} = grant) do
    Contracts.new_media_object(%{
      media_object_id: "media_#{grant.grant_id}",
      subject_key: "subject::media::user_123",
      storage_key: grant.key_prefix <> "capture.jpg",
      state: :queued,
      as_of: System.system_time(:microsecond),
      trace_metadata: %{grant_id: grant.grant_id, idempotency_key: grant.idempotency_key}
    })
  end

  @impl true
  def handle_event("record_local_capture", _params, socket) do
    {:noreply,
     assign(socket,
       proof_step: :local_capture_recorded,
       network_state: :degraded_capture_recorded,
       error_message: nil
     )}
  end

  @impl true
  def handle_event("fail_upload", _params, socket) do
    {:noreply,
     assign(socket,
       proof_step: :upload_failed,
       network_state: :upload_attempt_failed,
       error_message: nil
     )}
  end

  @impl true
  def handle_event("recover_network", _params, socket) do
    {:noreply,
     assign(socket,
       proof_step: :network_recovered,
       network_state: :network_recovered,
       error_message: nil
     )}
  end

  @impl true
  def handle_event("record_upload", params, socket) do
    correlation_id = Map.get(params, "correlation_id", "corr_live_upload")

    with %Contracts.UploadGrant{} = grant <- socket.assigns.grant,
         {:ok, evidence} <-
           MockCapture.emit_capture_evidence(grant, correlation_id: correlation_id),
         {:ok, ingestion} <-
           ReconciliationInbox.ingest_capture_evidence(evidence,
             correlation_id: correlation_id,
             seen_event_keys: socket.assigns.seen_event_keys
           ),
         {:ok, media_object} <-
           MediaProjection.project_object(socket.assigns.media_object, ingestion) do
      {:noreply,
       assign(socket,
         media_object: media_object,
         derived_state: MediaProjection.derived_state(media_object),
         proof_step: :device_evidence_recorded,
         seen_event_keys: [ingestion.event_key | socket.assigns.seen_event_keys],
         last_attempt: ingestion
       )}
    else
      nil ->
        {:noreply, put_error(socket, "Media lane unavailable: no active grant")}

      {:error, reason} ->
        {:noreply, put_error(socket, "Media evidence rejected: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("start_scan", _params, socket) do
    with %Contracts.UploadGrant{} = grant <- socket.assigns.grant,
         {:ok, evidence} <-
           MockCapture.emit_capture_evidence(grant, correlation_id: "corr_live_scan"),
         {:ok, ingestion} <-
           ReconciliationInbox.ingest_capture_evidence(evidence,
             event_kind: "capture_uploaded",
             backend_scan_started: true
           ),
         {:ok, media_object} <-
           MediaProjection.project_object(socket.assigns.media_object, ingestion) do
      {:noreply,
       assign(socket,
         media_object: media_object,
         derived_state: MediaProjection.derived_state(media_object),
         proof_step: :backend_verification_in_progress,
         last_attempt: ingestion
       )}
    else
      nil ->
        {:noreply, put_error(socket, "Media lane unavailable: no active grant")}

      {:error, reason} ->
        {:noreply, put_error(socket, "Media scan rejected: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("verify_backend", _params, socket) do
    with %Contracts.MediaObject{} = current <- socket.assigns.media_object,
         {:ok, media_object} <-
           MediaProjection.project_object(current, %{
             backend_verified: true,
             media_object_id: current.media_object_id,
             subject_key: current.subject_key,
             storage_key: current.storage_key,
             verification_ref: "verify_media_123",
             authoritative_at: DateTime.utc_now() |> DateTime.to_iso8601(),
             trace_metadata: current.trace_metadata
           }) do
      {:noreply,
       assign(socket,
         media_object: media_object,
         derived_state: MediaProjection.derived_state(media_object),
         proof_step: :backend_verified_available
       )}
    else
      nil ->
        {:noreply, put_error(socket, "Media lane unavailable: no media object")}

      {:error, reason} ->
        {:noreply, put_error(socket, "Media verification rejected: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("reject_backend", _params, socket) do
    with %Contracts.MediaObject{} = current <- socket.assigns.media_object,
         {:ok, media_object} <-
           Contracts.new_media_object(%{
             media_object_id: current.media_object_id,
             subject_key: current.subject_key,
             storage_key: current.storage_key,
             state: :rejected,
             as_of: System.system_time(:microsecond),
             rejection_reason: :backend_rejected,
             trace_metadata: current.trace_metadata
           }) do
      {:noreply,
       assign(socket,
         media_object: media_object,
         derived_state: MediaProjection.derived_state(media_object),
         proof_step: :backend_rejected
       )}
    else
      nil ->
        {:noreply, put_error(socket, "Media lane unavailable: no media object")}

      {:error, reason} ->
        {:noreply, put_error(socket, "Media rejection failed: #{inspect(reason)}")}
    end
  end

  defp put_error(socket, message) do
    assign(socket, :error_message, message)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section id="media-proof-lane">
      <h1>Media proof lane</h1>
      <p role="status" data-state={@derived_state} data-step={@proof_step}>
        <%= state_copy(@proof_step, @derived_state) %>
      </p>
      <p>Local capture evidence does not grant media availability</p>
      <p>This proof does not use a real storage provider</p>
      <p>Route owner: Phoenix. Capture seam: Rindle. Authority lane: backend verification.</p>
      <button type="button" phx-click="record_local_capture">Record local capture</button>
      <button type="button" phx-click="fail_upload">Fail upload</button>
      <button type="button" phx-click="recover_network">Recover network</button>
      <button type="button" phx-click="record_upload">Record device evidence</button>
      <button type="button" phx-click="start_scan">Start backend verification</button>
      <button type="button" phx-click="verify_backend">Mark backend verified</button>
      <button type="button" phx-click="reject_backend">Reject media</button>
    </section>
    """
  end

  defp state_copy(:local_capture_recorded, _state),
    do: "Capture recorded locally; media is not available yet."

  defp state_copy(:upload_failed, _state),
    do: "Upload failed during simulated network degradation."

  defp state_copy(:network_recovered, _state), do: "Network recovered. Reconciliation can retry."

  defp state_copy(:device_evidence_recorded, _state),
    do: "Device evidence recorded; backend verification still required."

  defp state_copy(:backend_verification_in_progress, _state),
    do: "Backend verification in progress."

  defp state_copy(:backend_verified_available, _state), do: "Backend verified media is available."
  defp state_copy(:backend_rejected, _state), do: "Backend rejected this media object."
  defp state_copy(_step, :queued), do: "Queued capture intent only; media is not committed."

  defp state_copy(_step, :uploaded),
    do: "Device upload evidence recorded; media is not available."

  defp state_copy(_step, :scanning), do: "Backend verification is in progress."
  defp state_copy(_step, :available), do: "Backend verified media is available."
  defp state_copy(_step, :rejected), do: "Backend rejected this media object."
end
