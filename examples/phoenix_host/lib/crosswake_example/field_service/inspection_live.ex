defmodule CrosswakeExample.FieldService.InspectionLive do
  use Phoenix.LiveView

  alias CrosswakeExample.FieldService.Components
  alias CrosswakeExample.FieldService.Diagnostics
  alias CrosswakeExample.FieldService.Evidence
  alias CrosswakeExample.FieldService.Jobs
  alias CrosswakeExample.PageTitle

  @route_id "fieldserv-inspection"
  @support_ref "support:fieldserv:inspection"

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: PageTitle.field("Inspection"),
       job_summary: nil,
       inspection_context: nil,
       evidence_events: [],
       status_message: nil,
       status_error: nil,
       diagnostics_rows: Diagnostics.route_policy_rows(),
       diagnostics_links: Diagnostics.guide_links()
     )}
  end

  @impl true
  def handle_params(%{"id" => job_id}, _uri, socket) do
    inspection_context = Jobs.inspection_context!(job_id)
    job_summary = inspection_context.job

    {:noreply,
     assign(socket,
       page_title: PageTitle.field("#{job_summary.title} Inspection"),
       job_summary: job_summary,
       inspection_context: inspection_context,
       evidence_events: Evidence.list_evidence_events(job_summary.id)
     )}
  end

  @impl true
  def handle_event("record-step", %{"step_id" => step_id}, socket) do
    context = socket.assigns.inspection_context
    job = context.job

    metadata = %{
      route_id: @route_id,
      support_ref: @support_ref,
      step_id: step_id,
      asset_id: context.asset.id,
      technician_id: context.technician.id,
      actor_id: context.technician.id,
      source: "liveview_online_action"
    }

    case Evidence.record_inspection_event(job.id, job.evidence_id, metadata) do
      {:ok, event} ->
        {:noreply,
         assign(socket,
           evidence_events: Evidence.list_evidence_events(job.id),
           status_message:
             "Server recorded #{format_atom(event.event_type)} for #{step_id}. Backend verification remains authoritative.",
           status_error: nil
         )}

      {:error, :invalid} ->
        {:noreply,
         assign(socket,
           status_message: nil,
           status_error: "Server rejected the inspection event. The cached snapshot is unchanged."
         )}
    end
  end

  @impl true
  def render(%{inspection_context: nil} = assigns) do
    ~H"""
    <Components.fieldserv_shell
      page_title="Inspection workspace"
      route_id="fieldserv-inspection"
      diagnostics_rows={@diagnostics_rows}
      diagnostics_links={@diagnostics_links}
      posture_badges={["LiveView route", "Cached read-only"]}
    >
      <section class="fieldserv-panel">
        <h2>Inspection loading</h2>
        <p>Fieldserv inspection context is loaded by route parameters.</p>
      </section>
    </Components.fieldserv_shell>
    """
  end

  def render(assigns) do
    ~H"""
    <Components.fieldserv_shell
      page_title="Inspection workspace"
      route_id="fieldserv-inspection"
      job={@job_summary}
      diagnostics_rows={@diagnostics_rows}
      diagnostics_links={@diagnostics_links}
      posture_badges={["LiveView route", "Cached read-only", "Future offline island candidate"]}
    >
      <Components.job_status_strip
        items={[
          %{label: "Job", value: @job_summary.title, detail: @job_summary.claim_id},
          %{label: "Technician", value: @inspection_context.technician.label, detail: @job_summary.technician_state_label},
          %{label: "Snapshot", value: @inspection_context.cached_snapshot, detail: @inspection_context.cached_snapshot_updated_at},
          %{label: "Mode", value: "Server action", detail: "No local mutation"}
        ]}
      />

      <section class="fieldserv-panel" aria-labelledby="fieldserv-inspection-workspace-heading">
        <div class="fieldserv-section-heading">
          <div>
            <h2 id="fieldserv-inspection-workspace-heading">Inspection workspace</h2>
            <p>
              {@inspection_context.degraded_notice} Checklist actions below use Phoenix server
              authority; device-heavy capture stays on its native route.
            </p>
          </div>
          <Components.status_badge label="Cached read-only" tone={:warning} />
        </div>

        <dl>
          <dt>Asset</dt>
          <dd>{@inspection_context.asset.label}</dd>
          <dt>Site</dt>
          <dd>{@inspection_context.asset.site}</dd>
          <dt>Dispatcher</dt>
          <dd>{@inspection_context.dispatcher.name}</dd>
          <dt>Reviewer</dt>
          <dd>{@inspection_context.adjuster.name}</dd>
        </dl>

        <p :if={@status_message} role="status">
          <strong>{@status_message}</strong>
        </p>
        <p :if={@status_error} role="alert">
          <strong>{@status_error}</strong>
        </p>
      </section>

      <Components.checklist_rows items={@inspection_context.checklist_items} />

      <section class="fieldserv-panel" aria-labelledby="fieldserv-online-action-heading">
        <h2 id="fieldserv-online-action-heading">Online step action</h2>
        <p>
          This representative action records an inspection event on the server. It does not
          create route-local draft state or replay behavior.
        </p>
        <footer class="fieldserv-action-footer">
          <span role="status">{length(@evidence_events)} evidence events visible for this job.</span>
          <button
            class="btn-primary"
            type="button"
            phx-click="record-step"
            phx-value-step_id="step-1"
            phx-disable-with="Recording on server..."
          >
            Record step
          </button>
          <a class="btn-secondary" href={"/fieldserv/jobs/#{@job_summary.id}/capture"}>Open capture route</a>
        </footer>
      </section>

      <section class="fieldserv-panel" aria-labelledby="fieldserv-offline-candidate-heading">
        <h2 id="fieldserv-offline-candidate-heading">{@inspection_context.future_offline_island_label}</h2>
        <p>
          Fieldserv inspection drafts are future pressure only in this phase. A shipped offline
          island would need all of these requirements before local mutation is presented:
        </p>
        <ul class="fieldserv-record-list">
          <li :for={requirement <- @inspection_context.future_offline_island_requirements}>
            <strong>{requirement}</strong>
          </li>
        </ul>
      </section>

      <section class="fieldserv-panel" aria-labelledby="fieldserv-events-heading">
        <h2 id="fieldserv-events-heading">Server evidence events</h2>
        <ol class="fieldserv-record-list">
          <li :for={event <- @evidence_events}>
            <strong>{format_atom(event.event_type)}</strong>
            <p>{format_atom(event.status)} · {event.route_id}</p>
            <small>{event.support_ref}</small>
          </li>
        </ol>
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
