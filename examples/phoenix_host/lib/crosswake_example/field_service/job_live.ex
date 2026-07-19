defmodule CrosswakeExample.FieldService.JobLive do
  use Phoenix.LiveView

  alias CrosswakeExample.FieldService.Components
  alias CrosswakeExample.FieldService.Diagnostics
  alias CrosswakeExample.FieldService.Jobs
  alias CrosswakeExample.PageTitle

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: PageTitle.field("Job"),
       job_summary: nil,
       inspection_context: nil,
       evidence_context: nil,
       diagnostics_rows: Diagnostics.route_policy_rows(),
       diagnostics_links: Diagnostics.guide_links()
     )}
  end

  @impl true
  def handle_params(%{"id" => job_id}, _uri, socket) do
    job_summary = Jobs.job_summary!(job_id)
    inspection_context = Jobs.inspection_context!(job_id)
    evidence_context = Jobs.evidence_context!(job_id)

    {:noreply,
     assign(socket,
       page_title: PageTitle.field(job_summary.title),
       job_summary: job_summary,
       inspection_context: inspection_context,
       evidence_context: evidence_context
     )}
  end

  @impl true
  def render(%{job_summary: nil} = assigns) do
    ~H"""
    <Components.fieldserv_shell
      page_title="Fieldserv job"
      route_id="fieldserv-job"
      diagnostics_rows={@diagnostics_rows}
      diagnostics_links={@diagnostics_links}
      posture_badges={["LiveView route", "Cached read-only"]}
    >
      <section class="fieldserv-panel">
        <h2>Job loading</h2>
        <p>Fieldserv job context is loaded by route parameters.</p>
      </section>
    </Components.fieldserv_shell>
    """
  end

  def render(assigns) do
    ~H"""
    <Components.fieldserv_shell
      page_title={@job_summary.title <> " field inspection"}
      route_id="fieldserv-job"
      job={@job_summary}
      diagnostics_rows={@diagnostics_rows}
      diagnostics_links={@diagnostics_links}
      posture_badges={["LiveView route", "Cached read-only", @job_summary.status_label]}
    >
      <Components.job_status_strip
        items={[
          %{label: "Priority", value: @job_summary.priority_label, detail: @job_summary.claim_id},
          %{label: "Technician", value: @job_summary.technician_label, detail: @job_summary.technician_state_label},
          %{label: "Evidence", value: @job_summary.evidence_status_label, detail: "Backend verification owns availability"},
          %{label: "Snapshot", value: @job_summary.cached_snapshot, detail: @job_summary.cached_snapshot_updated_at}
        ]}
      />

      <div class="fieldserv-job-grid">
        <section class="fieldserv-panel" aria-labelledby="fieldserv-asset-heading">
          <h2 id="fieldserv-asset-heading">Asset</h2>
          <p>{@inspection_context.asset.summary}</p>
          <dl>
            <dt>Claim</dt>
            <dd>{@job_summary.claim_id}</dd>
            <dt>Asset</dt>
            <dd>{@inspection_context.asset.label}</dd>
            <dt>Site</dt>
            <dd>{@inspection_context.asset.site}</dd>
            <dt>Risk</dt>
            <dd>{format_atom(@inspection_context.asset.risk)}</dd>
          </dl>
        </section>

        <section class="fieldserv-panel" aria-labelledby="fieldserv-people-heading">
          <h2 id="fieldserv-people-heading">Dispatch and reviewer</h2>
          <dl>
            <dt>Dispatcher</dt>
            <dd>{@inspection_context.dispatcher.name} · {@inspection_context.dispatcher.shift}</dd>
            <dt>Technician</dt>
            <dd>{@inspection_context.technician.name} · {@inspection_context.technician.device_state}</dd>
            <dt>Adjuster</dt>
            <dd>{@inspection_context.adjuster.name} · {@inspection_context.adjuster.queue}</dd>
          </dl>
        </section>
      </div>

      <section class="fieldserv-panel" aria-labelledby="fieldserv-inspection-heading">
        <h2 id="fieldserv-inspection-heading">Inspection</h2>
        <p>
          Checklist context is visible from a cached read-only snapshot. The native capture
          path is explicit because device evidence requires host app runtime ownership.
        </p>
        <Components.checklist_rows items={Enum.take(@inspection_context.checklist_items, 3)} />
      </section>

      <section class="fieldserv-panel" aria-labelledby="fieldserv-notes-heading">
        <h2 id="fieldserv-notes-heading">Notes and activity</h2>
        <ol class="fieldserv-record-list">
          <li :for={note <- @inspection_context.notes}>
            <strong>{format_atom(note.event_type)}</strong>
            <p>{note.summary}</p>
            <small>{note.route_id} · {note.recorded_at}</small>
          </li>
        </ol>
      </section>

      <Components.evidence_timeline items={@evidence_context.evidence_items} />

      <section class="fieldserv-panel" aria-labelledby="fieldserv-support-heading">
        <h2 id="fieldserv-support-heading">Cached read-only posture</h2>
        <p>
          {@inspection_context.degraded_notice} Backend verification controls media
          availability after native device evidence is recorded.
        </p>
        <footer class="fieldserv-action-footer">
          <span role="status">{@job_summary.blocker}</span>
          <a class="btn-secondary" href={"/fieldserv/jobs/#{@job_summary.id}/inspection"}>Open inspection</a>
          <a class="btn-primary" href={"/fieldserv/jobs/#{@job_summary.id}/capture"}>Open capture</a>
          <a
            class="btn-secondary"
            href={"/fieldserv/jobs/#{@job_summary.id}/evidence/#{@job_summary.evidence_id}/review"}
          >
            Review evidence
          </a>
        </footer>
      </section>
    </Components.fieldserv_shell>
    """
  end

  defp format_atom(atom) when is_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp format_atom(value), do: to_string(value)
end
