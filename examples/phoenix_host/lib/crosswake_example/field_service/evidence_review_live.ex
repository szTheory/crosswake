defmodule CrosswakeExample.FieldService.EvidenceReviewLive do
  use Phoenix.LiveView

  alias CrosswakeExample.FieldService.Components
  alias CrosswakeExample.FieldService.Diagnostics
  alias CrosswakeExample.FieldService.Evidence
  alias CrosswakeExample.FieldService.Jobs
  alias CrosswakeExample.PageTitle

  @route_id "fieldserv-evidence-review"
  @support_ref "support:fieldserv:evidence-review"

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: PageTitle.field("Evidence Review"),
       job_summary: nil,
       evidence_context: nil,
       evidence_item: nil,
       status_ladder: [],
       evidence_events: [],
       current_status_label: "Pending server confirmation",
       status_message: nil,
       status_error: nil,
       diagnostics_rows: Diagnostics.route_policy_rows(),
       diagnostics_links: Diagnostics.guide_links()
     )}
  end

  @impl true
  def handle_params(%{"id" => job_id, "evidence_id" => evidence_id}, _uri, socket) do
    evidence_context = Jobs.evidence_context!(job_id)
    evidence_item = evidence_item!(evidence_context, evidence_id)
    events = Evidence.list_evidence_events(job_id)

    {:noreply,
     assign(socket,
       page_title: PageTitle.field("#{evidence_item.title} Review"),
       job_summary: evidence_context.job,
       evidence_context: evidence_context,
       evidence_item: evidence_item,
       status_ladder: status_ladder(evidence_context),
       evidence_events: events,
       current_status_label: current_status_label(events, evidence_item)
     )}
  end

  @impl true
  def handle_event("record-device-evidence", _params, socket) do
    transition(socket, :record_device_evidence)
  end

  def handle_event("start-backend-verification", _params, socket) do
    transition(socket, :start_backend_verification)
  end

  def handle_event("mark-backend-verified", _params, socket) do
    transition(socket, :mark_backend_verified)
  end

  def handle_event("mark-backend-rejected", _params, socket) do
    transition(socket, :mark_backend_rejected)
  end

  @impl true
  def render(%{evidence_context: nil} = assigns) do
    ~H"""
    <Components.fieldserv_shell
      page_title="Evidence review"
      route_id="fieldserv-evidence-review"
      diagnostics_rows={@diagnostics_rows}
      diagnostics_links={@diagnostics_links}
      posture_badges={["LiveView route", "Cached read-only", "Backend authority"]}
    >
      <section class="fieldserv-review-panel">
        <h2>Evidence loading</h2>
        <p>Fieldserv evidence context is loaded by route parameters.</p>
      </section>
    </Components.fieldserv_shell>
    """
  end

  def render(assigns) do
    ~H"""
    <Components.fieldserv_shell
      page_title="Evidence review"
      route_id="fieldserv-evidence-review"
      job={@job_summary}
      diagnostics_rows={@diagnostics_rows}
      diagnostics_links={@diagnostics_links}
      posture_badges={["LiveView route", "Cached read-only", "Backend authority"]}
    >
      <Components.job_status_strip
        items={[
          %{label: "Evidence", value: @evidence_item.title, detail: @job_summary.claim_id},
          %{label: "Current status", value: @current_status_label, detail: "Server event state"},
          %{label: "Authority", value: "Backend verification", detail: "Device evidence is not availability"},
          %{label: "Route", value: "LiveView", detail: "Sensitive cached review"}
        ]}
      />

      <section class="fieldserv-review-panel" aria-labelledby="fieldserv-review-heading">
        <div class="fieldserv-section-heading">
          <div>
            <h2 id="fieldserv-review-heading">Evidence review</h2>
            <p>
              {@evidence_context.backend_authority} Device evidence recording and upload
              preparation remain evidence only until backend verification changes availability.
            </p>
          </div>
          <Components.status_badge label={@current_status_label} tone={status_tone_for_label(@current_status_label)} />
        </div>

        <dl>
          <dt>Job</dt>
          <dd>{@job_summary.title}</dd>
          <dt>Evidence</dt>
          <dd>{@evidence_item.id}</dd>
          <dt>Source</dt>
          <dd>{format_atom(@evidence_item.source)}</dd>
          <dt>Initial fixture status</dt>
          <dd>{@evidence_item.status_label}</dd>
        </dl>

        <p :if={@status_message} role="status">
          <strong>{@status_message}</strong>
        </p>
        <p :if={@status_error} role="alert">
          <strong>{@status_error}</strong>
        </p>
      </section>

      <section class="fieldserv-panel" aria-labelledby="fieldserv-status-ladder-heading">
        <h2 id="fieldserv-status-ladder-heading">Backend authority ladder</h2>
        <ul class="fieldserv-record-list">
          <li :for={status <- @status_ladder}>
            <strong>{status.label}</strong>
            <p>{status_copy(status.status)}</p>
            <Components.status_badge label={status.label} tone={status_tone(status.status)} />
          </li>
        </ul>
      </section>

      <section class="fieldserv-panel" aria-labelledby="fieldserv-review-actions-heading">
        <h2 id="fieldserv-review-actions-heading">Review actions</h2>
        <p>
          These actions persist server-side evidence events. Device evidence and upload
          preparation are not final media availability.
        </p>
        <footer class="fieldserv-action-footer">
          <button class="btn-secondary" type="button" phx-click="record-device-evidence">
            Record device evidence
          </button>
          <button class="btn-secondary" type="button" phx-click="start-backend-verification">
            Start backend verification
          </button>
          <button class="btn-primary" type="button" phx-click="mark-backend-verified">
            Mark backend verified
          </button>
          <button class="btn-secondary" type="button" phx-click="mark-backend-rejected">
            Mark backend rejected
          </button>
        </footer>
      </section>

      <section class="fieldserv-panel" aria-labelledby="fieldserv-review-events-heading">
        <h2 id="fieldserv-review-events-heading">Evidence event trail</h2>
        <ol class="fieldserv-record-list">
          <li :for={event <- @evidence_events}>
            <strong>{status_label(event.status)}</strong>
            <p>{format_atom(event.event_type)} · {event.route_id}</p>
            <small>{event.support_ref}</small>
          </li>
        </ol>
      </section>

      <section class="fieldserv-panel" aria-labelledby="fieldserv-review-boundary-heading">
        <h2 id="fieldserv-review-boundary-heading">Support boundary</h2>
        <p>
          This review route is cached read-only for job context and server-authoritative
          for evidence transitions. It does not add a production storage provider,
          background transfer, or offline media workflow.
        </p>
        <footer class="fieldserv-action-footer">
          <span role="status">Backend verification owns final evidence availability.</span>
          <a class="btn-secondary" href={"/fieldserv/jobs/#{@job_summary.id}"}>Back to job</a>
          <a class="btn-secondary" href={"/fieldserv/jobs/#{@job_summary.id}/capture"}>Open capture route</a>
        </footer>
      </section>
    </Components.fieldserv_shell>
    """
  end

  defp transition(socket, action) do
    job = socket.assigns.job_summary
    evidence = socket.assigns.evidence_item

    result =
      apply(Evidence, action, [
        job.id,
        evidence.id,
        metadata(action, job, evidence)
      ])

    case result do
      {:ok, event} ->
        events = Evidence.list_evidence_events(job.id)

        {:noreply,
         assign(socket,
           evidence_events: events,
           current_status_label: status_label(event.status),
           status_message: transition_message(event.status),
           status_error: nil
         )}

      {:error, :invalid} ->
        {:noreply,
         assign(socket,
           status_message: nil,
           status_error:
             "Server rejected the evidence transition. Evidence availability is unchanged."
         )}
    end
  end

  defp metadata(action, job, evidence) do
    %{
      route_id: @route_id,
      support_ref: @support_ref,
      action: action,
      job_id: job.id,
      evidence_id: evidence.id,
      reviewer_id: "adjuster-inez"
    }
  end

  defp evidence_item!(evidence_context, evidence_id) do
    evidence_context.evidence_items
    |> Enum.find(&(&1.id == evidence_id))
    |> case do
      nil -> raise ArgumentError, "unknown Fieldserv evidence: #{inspect(evidence_id)}"
      evidence -> evidence
    end
  end

  defp status_ladder(evidence_context) do
    evidence_context.status_ladder
    |> Enum.map(fn status ->
      %{status: status.status, label: status_label(status.status)}
    end)
  end

  defp current_status_label(events, evidence_item) do
    events
    |> Enum.filter(&(&1.evidence_id == evidence_item.id))
    |> List.last()
    |> case do
      nil -> evidence_item.status_label
      event -> status_label(event.status)
    end
  end

  defp transition_message(:device_evidence_recorded),
    do: "Device evidence recorded; backend verification still required."

  defp transition_message(:backend_verification_pending),
    do: "Backend verification pending; evidence is not available yet."

  defp transition_message(:backend_verified),
    do: "Backend verified. Evidence is available to reviewers after server verification."

  defp transition_message(:backend_rejected),
    do: "Backend rejected this evidence. Reviewer action is required before availability changes."

  defp transition_message(status), do: "#{status_label(status)} recorded by the server."

  defp status_copy(:device_evidence_recorded),
    do: "Native device capture produced evidence, but backend verification is still required."

  defp status_copy(:backend_verification_pending),
    do: "Backend verification has started and media availability remains pending."

  defp status_copy(:backend_verified),
    do: "Backend verified evidence can be shown to reviewers."

  defp status_copy(:backend_rejected),
    do: "Backend rejected evidence stays unavailable until review resolves it."

  defp status_copy(status), do: "#{status_label(status)} is recorded as a closed evidence state."

  defp status_label(:device_evidence_recorded), do: "Device evidence recorded"
  defp status_label(:backend_verification_pending), do: "Backend verification pending"
  defp status_label(:backend_verified), do: "Backend verified"
  defp status_label(:backend_rejected), do: "Backend rejected"
  defp status_label(status), do: format_atom(status)

  defp status_tone(:device_evidence_recorded), do: :native
  defp status_tone(:backend_verification_pending), do: :warning
  defp status_tone(:backend_verified), do: :success
  defp status_tone(:backend_rejected), do: :danger
  defp status_tone(_status), do: :default

  defp status_tone_for_label("Device evidence recorded"), do: :native
  defp status_tone_for_label("Backend verification pending"), do: :warning
  defp status_tone_for_label("Backend verified"), do: :success
  defp status_tone_for_label("Backend rejected"), do: :danger
  defp status_tone_for_label(_label), do: :default

  defp format_atom(atom) when is_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp format_atom(value), do: to_string(value)
end
