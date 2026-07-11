defmodule CrosswakeExample.FieldService.JobsLive do
  use Phoenix.LiveView

  alias CrosswakeExample.FieldService.Components
  alias CrosswakeExample.FieldService.Diagnostics
  alias CrosswakeExample.FieldService.Fixtures
  alias CrosswakeExample.FieldService.Jobs
  alias CrosswakeExample.PageTitle

  @impl true
  def mount(_params, _session, socket) do
    job_summaries =
      Jobs.list_jobs()
      |> Enum.map(&job_queue_summary/1)

    {:ok,
     assign(socket,
       page_title: PageTitle.field("Jobs"),
       jobs: job_summaries,
       dispatcher: Fixtures.dispatcher(),
       technicians: Fixtures.technicians(),
       status_items: queue_status_items(job_summaries),
       diagnostics_rows: Diagnostics.route_policy_rows(),
       diagnostics_links: Diagnostics.guide_links()
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Components.fieldserv_shell
      page_title="Ridgeway job queue"
      route_id="fieldserv-jobs"
      diagnostics_rows={@diagnostics_rows}
      diagnostics_links={@diagnostics_links}
      posture_badges={["LiveView route", "Cached read-only", "Dispatcher queue"]}
    >
      <Components.job_status_strip items={@status_items} />

      <section class="fieldserv-panel" aria-labelledby="fieldserv-jobs-heading">
        <div class="fieldserv-section-heading">
          <div>
            <h2 id="fieldserv-jobs-heading">Dispatch queue</h2>
            <p>
              {@dispatcher.name} is triaging Ridgeway jobs from cached read-only context.
              Evidence blockers stay visible before a technician opens a job.
            </p>
          </div>
          <span role="status">
            {length(@jobs)} jobs visible for {@dispatcher.shift}.
          </span>
        </div>

        <ol class="fieldserv-record-list fieldserv-job-grid" aria-label="Fieldserv jobs">
          <li :for={job <- @jobs}>
            <div class="fieldserv-record-main">
              <strong>
                <a href={"/fieldserv/jobs/#{job.id}"}>{job.title}</a>
              </strong>
              <p>{job.priority_label} · {job.status_label} · {job.technician_label}</p>
              <dl>
                <dt>Asset</dt>
                <dd>{job.asset_label}</dd>
                <dt>Technician state</dt>
                <dd>{job.technician_state_label}</dd>
                <dt>Evidence blocker</dt>
                <dd>{job.blocker}</dd>
                <dt>Snapshot</dt>
                <dd>{job.cached_snapshot} · {job.cached_snapshot_updated_at}</dd>
              </dl>
            </div>
            <div class="fieldserv-record-actions">
              <Components.status_badge label={job.status_label} tone={status_tone(job.status)} />
              <Components.status_badge label="Cached read-only" tone={:warning} />
              <a class="btn-secondary" href={"/fieldserv/jobs/#{job.id}"}>Open job</a>
            </div>
          </li>
        </ol>
      </section>

      <section class="fieldserv-panel" aria-labelledby="fieldserv-tech-heading">
        <h2 id="fieldserv-tech-heading">Technician state</h2>
        <ul class="fieldserv-record-list">
          <li :for={technician <- @technicians}>
            <strong>{technician.label}</strong>
            <p>{format_atom(technician.state)} · {technician.device_state}</p>
            <small>{technician.last_seen}</small>
          </li>
        </ul>
      </section>
    </Components.fieldserv_shell>
    """
  end

  defp job_queue_summary(job) do
    job
    |> Jobs.job_summary!()
    |> Map.put(:queue_rank, job.queue_rank)
  end

  defp queue_status_items(jobs) do
    blockers = Enum.count(jobs, &String.contains?(&1.blocker, "requires"))

    [
      %{label: "Jobs", value: length(jobs), detail: "Ridgeway dispatch"},
      %{
        label: "Evidence blocker",
        value: blockers,
        detail: "Needs native runtime or backend proof"
      },
      %{label: "Route owner", value: "Phoenix", detail: "LiveView route"},
      %{label: "Offline", value: "Read-only", detail: "Cached snapshot"}
    ]
  end

  defp status_tone(:backend_review), do: :authority
  defp status_tone(:inspection_in_progress), do: :warning
  defp status_tone(:awaiting_capture), do: :native
  defp status_tone(_status), do: :default

  defp format_atom(atom) when is_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp format_atom(value), do: to_string(value)
end
