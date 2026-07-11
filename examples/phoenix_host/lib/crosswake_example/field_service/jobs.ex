defmodule CrosswakeExample.FieldService.Jobs do
  @moduledoc """
  Read-only Fieldserv job context backed by deterministic fixtures.
  """

  alias CrosswakeExample.FieldService.Fixtures

  @future_offline_island_requirements [
    "local draft storage for inspection steps before the route can mutate without a server round trip",
    "journal/outbox records with idempotency keys for every submitted inspection action",
    "replay outcomes that distinguish accepted, rejected, and conflict states",
    "conflict review owned by the backend before canonical job state changes",
    "reconciliation proof that shows Phoenix and Ecto remain authoritative after replay"
  ]

  def list_jobs do
    Fixtures.jobs()
    |> Enum.sort_by(& &1.queue_rank)
  end

  def get_job!(id) when is_binary(id) do
    Fixtures.jobs()
    |> Enum.find(&(&1.id == id))
    |> case do
      nil -> raise ArgumentError, "unknown Fieldserv job: #{inspect(id)}"
      job -> job
    end
  end

  def job_summary!(job_or_id) do
    job = job_or_id |> job_id_for() |> get_job!()
    asset = asset_for!(job.asset_id)
    technician = technician_for!(job.technician_id)
    evidence = evidence_for!(job.evidence_id)

    %{
      id: job.id,
      claim_id: job.claim_id,
      title: job.title,
      route_id: job.route_id,
      priority: job.priority,
      priority_label: priority_label(job.priority),
      status: job.status,
      status_label: job_status_label(job.status),
      blocker: job.blocker,
      asset_id: asset.id,
      asset_label: asset.label,
      asset_summary: asset.summary,
      technician_id: technician.id,
      technician_label: technician.label,
      technician_state: technician.state,
      technician_state_label: technician_state_label(technician.state),
      evidence_id: evidence.id,
      evidence_status: evidence.status,
      evidence_status_label: evidence.status_label,
      cached_snapshot: "Cached read-only",
      cached_snapshot_updated_at: job.cached_snapshot_updated_at
    }
  end

  def inspection_context!(job_or_id) do
    job = job_or_id |> job_id_for() |> get_job!()
    template = inspection_template_for!(job.inspection_template_id)

    %{
      job: job_summary!(job),
      asset: asset_for!(job.asset_id),
      technician: technician_for!(job.technician_id),
      dispatcher: Fixtures.dispatcher(),
      adjuster: Fixtures.adjuster(),
      checklist_items: template.checklist_items,
      notes: notes_for_job(job.id),
      online_note_events: online_note_events_for_job(job.id),
      cached_snapshot: "Cached read-only",
      cached_snapshot_updated_at: job.cached_snapshot_updated_at,
      degraded_notice: "This cached job snapshot cannot be edited offline.",
      future_offline_island_label: "Future offline island candidate",
      future_offline_island_requirements: @future_offline_island_requirements
    }
  end

  def evidence_context!(job_or_id) do
    job = job_or_id |> job_id_for() |> get_job!()
    evidence_items = evidence_items_for_job(job.id)

    %{
      job: job_summary!(job),
      evidence_items: evidence_items,
      primary_evidence: evidence_for!(job.evidence_id),
      status_ladder: evidence_status_ladder(),
      backend_authority: "Backend verification owns media availability.",
      cached_snapshot: "Cached read-only"
    }
  end

  def route_posture!(route_id) when is_binary(route_id) do
    Fixtures.route_postures()
    |> Enum.find(&(&1.route_id == route_id))
    |> case do
      nil -> raise ArgumentError, "unknown Fieldserv route posture: #{inspect(route_id)}"
      posture -> posture
    end
  end

  defp job_id_for(%{id: id}) when is_binary(id), do: id
  defp job_id_for(job_id) when is_binary(job_id), do: job_id

  defp asset_for!(asset_id) do
    Fixtures.assets()
    |> Enum.find(&(&1.id == asset_id))
    |> case do
      nil -> raise ArgumentError, "unknown Fieldserv asset: #{inspect(asset_id)}"
      asset -> asset
    end
  end

  defp technician_for!(technician_id) do
    Fixtures.technicians()
    |> Enum.find(&(&1.id == technician_id))
    |> case do
      nil -> raise ArgumentError, "unknown Fieldserv technician: #{inspect(technician_id)}"
      technician -> technician
    end
  end

  defp inspection_template_for!(template_id) do
    Fixtures.inspection_templates()
    |> Enum.find(&(&1.id == template_id))
    |> case do
      nil -> raise ArgumentError, "unknown Fieldserv inspection template: #{inspect(template_id)}"
      template -> template
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

  defp notes_for_job(job_id) do
    Fixtures.notes()
    |> Enum.filter(&(&1.job_id == job_id))
    |> Enum.sort_by(& &1.recorded_at)
  end

  defp online_note_events_for_job(job_id) do
    notes_for_job(job_id)
    |> Enum.filter(&(&1.event_type in [:job_assigned, :inspection_started, :capture_intent_requested]))
  end

  defp evidence_items_for_job(job_id) do
    Fixtures.evidence_items()
    |> Enum.filter(&(&1.job_id == job_id))
    |> Enum.sort_by(& &1.id)
  end

  defp evidence_status_ladder do
    Fixtures.evidence_items()
    |> Enum.map(fn evidence ->
      %{status: evidence.status, label: evidence.status_label, available_media: evidence.available_media}
    end)
    |> Enum.uniq_by(& &1.status)
  end

  defp priority_label(:urgent), do: "Urgent"
  defp priority_label(:high), do: "High"
  defp priority_label(:standard), do: "Standard"

  defp job_status_label(:awaiting_capture), do: "Awaiting native capture"
  defp job_status_label(:inspection_in_progress), do: "Inspection in progress"
  defp job_status_label(:backend_review), do: "Backend review"

  defp technician_state_label(:en_route), do: "Technician en route"
  defp technician_state_label(:on_site), do: "Technician on site"
  defp technician_state_label(:awaiting_review), do: "Awaiting reviewer"
end
