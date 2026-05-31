defmodule CrosswakeExample.Media.MediaLaneLive do
  use Phoenix.LiveView

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
         seen_event_keys: [],
         last_attempt: nil
       )}
    else
      {:error, reason} ->
        {:ok,
         socket
         |> assign(
           grant: nil,
           media_object: nil,
           derived_state: :rejected,
           seen_event_keys: [],
           last_attempt: nil
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
         derived_state: MediaProjection.derived_state(media_object)
       )}
    else
      nil ->
        {:noreply, put_error(socket, "Media lane unavailable: no media object")}

      {:error, reason} ->
        {:noreply, put_error(socket, "Media verification rejected: #{inspect(reason)}")}
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
      <p data-state={@derived_state}><%= state_copy(@derived_state) %></p>
      <button type="button" phx-click="record_upload">Record device evidence</button>
      <button type="button" phx-click="start_scan">Start backend verification</button>
      <button type="button" phx-click="verify_backend">Mark backend verified</button>
    </section>
    """
  end

  defp state_copy(:queued), do: "Queued capture intent only; media is not committed."
  defp state_copy(:uploaded), do: "Device upload evidence recorded; media is not available."
  defp state_copy(:scanning), do: "Backend verification is in progress."
  defp state_copy(:available), do: "Backend verified media is available."
  defp state_copy(:rejected), do: "Backend rejected this media object."
end
