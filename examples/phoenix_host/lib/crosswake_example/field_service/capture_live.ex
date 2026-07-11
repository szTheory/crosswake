defmodule CrosswakeExample.FieldService.CaptureLive do
  use Phoenix.LiveView

  alias CrosswakeExample.FieldService.Components
  alias CrosswakeExample.FieldService.Diagnostics
  alias CrosswakeExample.FieldService.Jobs
  alias CrosswakeExample.PageTitle

  @route_id "fieldserv-job-capture"

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: PageTitle.field("Capture"),
       job_summary: nil,
       evidence_context: nil,
       capture_row: nil,
       pressure_rows: Diagnostics.capability_map_rows(),
       diagnostics_rows: Diagnostics.route_policy_rows(),
       diagnostics_links: Diagnostics.guide_links()
     )}
  end

  @impl true
  def handle_params(%{"id" => job_id}, _uri, socket) do
    job_summary = Jobs.job_summary!(job_id)

    {:noreply,
     assign(socket,
       page_title: PageTitle.field("#{job_summary.title} Capture"),
       job_summary: job_summary,
       evidence_context: Jobs.evidence_context!(job_id),
       capture_row: route_row!(@route_id)
     )}
  end

  @impl true
  def render(%{job_summary: nil} = assigns) do
    ~H"""
    <Components.fieldserv_shell
      page_title="Native capture handoff"
      route_id="fieldserv-job-capture"
      diagnostics_rows={@diagnostics_rows}
      diagnostics_links={@diagnostics_links}
      posture_badges={["Native screen", "Cached read-only"]}
    >
      <section class="fieldserv-capture-handoff">
        <h2>Capture loading</h2>
        <p>Fieldserv capture context is loaded by route parameters.</p>
      </section>
    </Components.fieldserv_shell>
    """
  end

  def render(assigns) do
    ~H"""
    <Components.fieldserv_shell
      page_title="Native capture handoff"
      route_id="fieldserv-job-capture"
      job={@job_summary}
      diagnostics_rows={@diagnostics_rows}
      diagnostics_links={@diagnostics_links}
      posture_badges={["Native screen", "Cached read-only", "Permission needed"]}
    >
      <Components.job_status_strip
        items={[
          %{label: "Runtime", value: @capture_row.runtime_owner_label, detail: @capture_row.route_id},
          %{label: "Capability", value: list_text(@capture_row.capability_labels), detail: "camera"},
          %{label: "Transfer", value: list_text(@capture_row.transfer_labels), detail: "capture_upload"},
          %{label: "Security", value: @capture_row.security_posture_label, detail: @capture_row.offline_posture_label}
        ]}
      />

      <section class="fieldserv-capture-handoff" aria-labelledby="fieldserv-capture-heading">
        <div class="fieldserv-section-heading">
          <div>
            <h2 id="fieldserv-capture-heading">Native capture route</h2>
            <p>
              Camera capture requires the native app runtime. Fieldserv keeps the job
              and evidence context visible here while the host app owns permission,
              capture session, and platform UI.
            </p>
          </div>
          <Components.status_badge label="Native screen" tone={:native} />
        </div>

        <dl>
          <dt>Route ID</dt>
          <dd>{@capture_row.route_id}</dd>
          <dt>Runtime owner</dt>
          <dd>{@capture_row.runtime_owner_label}</dd>
          <dt>Declared capability</dt>
          <dd>{list_text(@capture_row.capability_labels)}</dd>
          <dt>Media pack</dt>
          <dd>{declaration_text(@capture_row.packs)}</dd>
          <dt>Transfer posture</dt>
          <dd>{list_text(@capture_row.transfer_labels)}</dd>
          <dt>Evidence authority</dt>
          <dd>{@evidence_context.backend_authority}</dd>
        </dl>
      </section>

      <section class="fieldserv-panel" aria-labelledby="fieldserv-device-pressure-heading">
        <h2 id="fieldserv-device-pressure-heading">Device pressure</h2>
        <ul class="fieldserv-record-list">
          <li :for={row <- capture_pressure_rows(@pressure_rows)}>
            <strong>{format_atom(row.capability)}</strong>
            <p>{row.rough_edge}</p>
            <Components.status_badge label={row.support_label} tone={pressure_tone(row.support_label)} />
          </li>
        </ul>
      </section>

      <section class="fieldserv-panel" aria-labelledby="fieldserv-capture-next-heading">
        <h2 id="fieldserv-capture-next-heading">Review next</h2>
        <p>
          Device evidence is pending backend verification. The evidence review page
          keeps backend verification separate from native capture.
        </p>
        <footer class="fieldserv-action-footer">
          <span role="status">Permission needed inside native capture.</span>
          <a class="btn-secondary" href={"/fieldserv/jobs/#{@job_summary.id}"}>Back to job</a>
          <a
            class="btn-primary"
            href={"/fieldserv/jobs/#{@job_summary.id}/evidence/#{@job_summary.evidence_id}/review"}
          >
            Open evidence review
          </a>
        </footer>
      </section>
    </Components.fieldserv_shell>
    """
  end

  defp route_row!(route_id) do
    Diagnostics.route_policy_rows()
    |> Enum.find(&(&1.route_id == route_id))
    |> case do
      nil -> raise ArgumentError, "unknown Fieldserv route row: #{inspect(route_id)}"
      row -> row
    end
  end

  defp capture_pressure_rows(rows) do
    Enum.filter(
      rows,
      &(&1.capability in [:capture, :scanner, :document_scan, :permissions, :media_upload])
    )
  end

  defp pressure_tone("Future gap"), do: :gap
  defp pressure_tone("Next-pack candidate"), do: :native
  defp pressure_tone(_label), do: :warning

  defp declaration_text([]), do: "No pack declared"
  defp declaration_text(nil), do: "No pack declared"

  defp declaration_text(declarations) do
    declarations
    |> Enum.map(fn declaration ->
      [
        declaration_field(declaration, :id),
        declaration_field(declaration, :version),
        declaration_field(declaration, :kind)
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&to_string/1)
      |> Enum.join(" / ")
    end)
    |> Enum.join(", ")
  end

  defp declaration_field(declaration, field) when is_map(declaration),
    do: Map.get(declaration, field)

  defp declaration_field(declaration, field) when is_list(declaration),
    do: Keyword.get(declaration, field)

  defp list_text(nil), do: "Not declared"
  defp list_text([]), do: "Not declared"
  defp list_text(values), do: Enum.join(values, ", ")

  defp format_atom(atom) when is_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp format_atom(value), do: to_string(value)
end
