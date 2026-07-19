defmodule CrosswakeExample.FieldService.Evidence do
  @moduledoc """
  Server-authoritative Fieldserv evidence workflow context.

  This context persists only representative evidence events and technician job
  state. It is not a local-first journal, outbox, or generic sync surface.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias CrosswakeExample.FieldService.EvidenceEvent
  alias CrosswakeExample.FieldService.Fixtures
  alias CrosswakeExample.FieldService.TechnicianJobState
  alias CrosswakeExample.Repo

  @base_event_at ~U[2026-07-11 12:50:00Z]
  @default_route_id "fieldserv-evidence-review"
  @default_support_ref "support:fieldserv:evidence"

  def reset! do
    evidence_items = Fixtures.evidence_items()
    jobs = Fixtures.jobs()

    {:ok, counts} =
      Repo.transaction(fn ->
        Repo.delete_all(TechnicianJobState)
        Repo.delete_all(EvidenceEvent)

        evidence_items
        |> Enum.with_index()
        |> Enum.each(fn {fixture, index} ->
          fixture
          |> seed_event_attrs(index)
          |> then(&EvidenceEvent.changeset(%EvidenceEvent{}, &1))
          |> Repo.insert!()
        end)

        jobs
        |> Enum.each(fn job ->
          job
          |> seed_state_attrs()
          |> then(&TechnicianJobState.changeset(%TechnicianJobState{}, &1))
          |> Repo.insert!()
        end)

        %{
          evidence_events: length(evidence_items),
          technician_job_states: length(jobs)
        }
      end)

    counts
  end

  def digest_components do
    [
      "field_service.persisted.evidence_events=#{Repo.aggregate(EvidenceEvent, :count)}",
      "field_service.persisted.technician_job_states=#{Repo.aggregate(TechnicianJobState, :count)}",
      persisted_event_components(),
      persisted_state_components()
    ]
    |> List.flatten()
    |> Enum.sort()
  end

  def list_evidence_events(job_id) when is_binary(job_id) do
    EvidenceEvent
    |> where([event], event.job_id == ^job_id)
    |> order_by([event], asc: event.occurred_at, asc: event.event_id)
    |> Repo.all()
    |> Enum.map(&event_to_map/1)
  end

  def record_inspection_event(job_id, evidence_id, metadata)
      when is_binary(job_id) and is_binary(evidence_id) and is_map(metadata) do
    attrs =
      event_attrs(
        job_id,
        evidence_id,
        metadata,
        :inspection_step_completed,
        :backend_verification_pending
      )

    %EvidenceEvent{}
    |> EvidenceEvent.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, event} -> {:ok, event_to_map(event)}
      {:error, _changeset} -> {:error, :invalid}
    end
  end

  def record_device_evidence(job_id, evidence_id, metadata)
      when is_binary(job_id) and is_binary(evidence_id) and is_map(metadata) do
    persist_event_and_state(
      job_id,
      evidence_id,
      metadata,
      :device_evidence_recorded,
      :device_evidence_recorded
    )
  end

  def start_backend_verification(job_id, evidence_id, metadata)
      when is_binary(job_id) and is_binary(evidence_id) and is_map(metadata) do
    persist_event_and_state(
      job_id,
      evidence_id,
      metadata,
      :backend_verification_started,
      :backend_verification_pending
    )
  end

  def mark_backend_verified(job_id, evidence_id, metadata)
      when is_binary(job_id) and is_binary(evidence_id) and is_map(metadata) do
    persist_event_and_state(
      job_id,
      evidence_id,
      metadata,
      :backend_verified_available,
      :backend_verified
    )
  end

  def mark_backend_rejected(job_id, evidence_id, metadata)
      when is_binary(job_id) and is_binary(evidence_id) and is_map(metadata) do
    persist_event_and_state(job_id, evidence_id, metadata, :backend_rejected, :backend_rejected)
  end

  defp persist_event_and_state(job_id, evidence_id, metadata, event_type, status) do
    event_attrs = event_attrs(job_id, evidence_id, metadata, event_type, status)
    state_attrs = state_attrs(job_id, event_attrs)
    state = Repo.get_by(TechnicianJobState, job_id: job_id) || %TechnicianJobState{}

    Multi.new()
    |> Multi.insert(:evidence_event, EvidenceEvent.changeset(%EvidenceEvent{}, event_attrs))
    |> Multi.insert_or_update(
      :technician_job_state,
      TechnicianJobState.changeset(state, state_attrs)
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{evidence_event: event}} -> {:ok, event_to_map(event)}
      {:error, _step, _changeset, _changes} -> {:error, :invalid}
    end
  end

  defp event_attrs(job_id, evidence_id, metadata, event_type, status) do
    job = job_for!(job_id)
    evidence = evidence_for!(evidence_id)

    %{
      event_id: event_id(job_id, evidence_id, event_type),
      job_id: job.id,
      evidence_id: evidence.id,
      asset_id: job.asset_id,
      technician_id: job.technician_id,
      event_type: Atom.to_string(event_type),
      status: Atom.to_string(status),
      route_id: Map.get(metadata, :route_id, Map.get(metadata, "route_id", @default_route_id)),
      support_ref:
        Map.get(metadata, :support_ref, Map.get(metadata, "support_ref", @default_support_ref)),
      occurred_at: DateTime.truncate(DateTime.utc_now(), :second),
      metadata:
        support_metadata(
          Map.merge(%{source: evidence.source, evidence_title: evidence.title}, metadata)
        )
    }
  end

  defp state_attrs(job_id, event_attrs) do
    job = job_for!(job_id)

    %{
      job_id: job.id,
      technician_id: job.technician_id,
      status: event_attrs.status,
      last_event_id: event_attrs.event_id,
      route_id: event_attrs.route_id,
      support_ref: event_attrs.support_ref,
      metadata:
        support_metadata(%{
          asset_id: event_attrs.asset_id,
          evidence_id: event_attrs.evidence_id,
          status: event_attrs.status
        })
    }
  end

  defp seed_event_attrs(evidence, index) do
    job = job_for!(evidence.job_id)

    %{
      event_id: "#{evidence.id}-seeded",
      job_id: evidence.job_id,
      evidence_id: evidence.id,
      asset_id: job.asset_id,
      technician_id: job.technician_id,
      event_type: seed_event_type(evidence.status),
      status: Atom.to_string(evidence.status),
      route_id: evidence.route_id,
      support_ref: support_ref_for(evidence),
      occurred_at: DateTime.add(@base_event_at, index, :minute),
      metadata:
        support_metadata(%{
          evidence_title: evidence.title,
          available_media: evidence.available_media,
          backend_authority: evidence.backend_authority
        })
    }
  end

  defp seed_state_attrs(job) do
    evidence = evidence_for!(job.evidence_id)

    %{
      job_id: job.id,
      technician_id: job.technician_id,
      status: Atom.to_string(evidence.status),
      last_event_id: "#{evidence.id}-seeded",
      route_id: evidence.route_id,
      support_ref: support_ref_for(evidence),
      metadata:
        support_metadata(%{
          asset_id: job.asset_id,
          evidence_id: evidence.id,
          source: evidence.source,
          available_media: evidence.available_media
        })
    }
  end

  defp job_for!(job_id) do
    Fixtures.jobs()
    |> Enum.find(&(&1.id == job_id))
    |> case do
      nil -> raise ArgumentError, "unknown Fieldserv job: #{inspect(job_id)}"
      job -> job
    end
  end

  defp evidence_for!(evidence_id) do
    Fixtures.evidence_items()
    |> Enum.find(&(&1.id == evidence_id))
    |> case do
      nil -> raise ArgumentError, "unknown Fieldserv evidence: #{inspect(evidence_id)}"
      evidence -> evidence
    end
  end

  defp event_id(job_id, evidence_id, event_type) do
    suffix = System.unique_integer([:positive, :monotonic])
    "#{job_id}-#{evidence_id}-#{event_type}-#{suffix}"
  end

  defp seed_event_type(:device_evidence_recorded), do: "device_evidence_recorded"
  defp seed_event_type(:backend_verification_pending), do: "backend_verification_started"
  defp seed_event_type(:backend_verified), do: "backend_verified_available"
  defp seed_event_type(:backend_rejected), do: "backend_rejected"

  defp support_ref_for(%{id: evidence_id}) do
    "support:fieldserv:#{evidence_id}"
  end

  defp support_metadata(metadata) when is_map(metadata) do
    metadata
    |> Enum.reject(fn {key, _value} ->
      key in [
        :token,
        "token",
        :session,
        "session",
        :session_ref,
        "session_ref",
        :provider_payload,
        "provider_payload",
        :secret,
        "secret"
      ]
    end)
    |> Map.new(fn {key, value} -> {to_string(key), stringify_metadata_value(value)} end)
  end

  defp stringify_metadata_value(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_metadata_value(value), do: value

  defp event_to_map(%EvidenceEvent{} = event) do
    %{
      id: event.event_id,
      event_id: event.event_id,
      job_id: event.job_id,
      evidence_id: event.evidence_id,
      asset_id: event.asset_id,
      technician_id: event.technician_id,
      event_type: String.to_atom(event.event_type),
      status: String.to_atom(event.status),
      route_id: event.route_id,
      support_ref: event.support_ref,
      occurred_at: event.occurred_at,
      metadata: event.metadata || %{}
    }
  end

  defp persisted_event_components do
    EvidenceEvent
    |> order_by([event], asc: event.event_id)
    |> Repo.all()
    |> Enum.map(fn event ->
      "field_service.persisted.evidence_event:#{event.event_id}:#{event.event_type}:#{event.status}:#{event.technician_id}"
    end)
  end

  defp persisted_state_components do
    TechnicianJobState
    |> order_by([state], asc: state.job_id)
    |> Repo.all()
    |> Enum.map(fn state ->
      "field_service.persisted.technician_job_state:#{state.job_id}:#{state.status}:#{state.last_event_id}"
    end)
  end
end
