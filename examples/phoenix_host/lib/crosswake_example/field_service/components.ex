defmodule CrosswakeExample.FieldService.Components do
  @moduledoc """
  Fieldserv-specific function components for the field-service showcase lane.

  These components are intentionally lane-local. They render dispatch,
  inspection, evidence, and support-truth UI without becoming a generic
  field-service framework.
  """

  use Phoenix.Component

  alias CrosswakeExample.FieldService.Diagnostics
  alias CrosswakeExample.Showcase.Branding

  attr(:page_title, :string, required: true)
  attr(:route_id, :string, required: true)
  attr(:job, :any, default: nil)
  attr(:diagnostics_rows, :list, default: [])
  attr(:diagnostics_links, :list, default: [])
  attr(:posture_badges, :list, default: [])
  slot(:inner_block)

  def fieldserv_shell(assigns) do
    assigns =
      assigns
      |> assign(:brand, Branding.brand_for!(:field_service))
      |> assign(:nav_items, nav_items(assigns[:job]))
      |> assign_new(:diagnostics_rows, fn -> Diagnostics.route_policy_rows() end)
      |> assign_new(:diagnostics_links, fn -> Diagnostics.guide_links() end)

    ~H"""
    <div class={"fieldserv-shell #{@brand.theme_class}"} data-route-id={@route_id}>
      <header class="fieldserv-topbar" aria-label="Fieldserv workspace">
        <div class="fieldserv-brand-lockup">
          <span class="fieldserv-mark" aria-hidden="true">{@brand.mark}</span>
          <div class="fieldserv-brand-copy">
            <p class="fieldserv-category">{@brand.category}</p>
            <p class="fieldserv-product">{@brand.name}</p>
            <p class="fieldserv-tagline">{@brand.tagline}</p>
          </div>
        </div>

        <div class="fieldserv-dispatch-summary" aria-label="Fieldserv dispatch context">
          <span>{@brand.fixture_brief.organization}</span>
          <span>{@brand.fixture_brief.pressure}</span>
        </div>
      </header>

      <nav class="fieldserv-nav" aria-label="Fieldserv routes">
        <a
          :for={item <- @nav_items}
          href={item.path}
          class={[
            "fieldserv-nav-link",
            item.route_id == @route_id && "fieldserv-nav-link-active"
          ]}
          aria-current={if item.route_id == @route_id, do: "page", else: nil}
        >
          {item.label}
        </a>
      </nav>

      <main class="fieldserv-main" aria-labelledby="fieldserv-page-title">
        <header class="fieldserv-page-heading">
          <div>
            <p class="fieldserv-page-kicker">{@brand.tone}</p>
            <h1 id="fieldserv-page-title">{@page_title}</h1>
          </div>
          <.posture_badges badges={@posture_badges} />
        </header>

        {render_slot(@inner_block)}

        <.diagnostics_panel
          route_id={@route_id}
          rows={@diagnostics_rows}
          guide_links={@diagnostics_links}
        />
      </main>
    </div>
    """
  end

  attr(:badges, :list, default: [])

  def posture_badges(assigns) do
    ~H"""
    <div class="fieldserv-posture-badges" aria-label="Route posture">
      <span :for={badge <- @badges} class={["fieldserv-route-badge", badge_tone_class(badge)]}>
        {badge}
      </span>
    </div>
    """
  end

  attr(:route_id, :string, required: true)
  attr(:rows, :list, default: [])
  attr(:guide_links, :list, default: [])

  def diagnostics_panel(assigns) do
    assigns =
      assigns
      |> assign_new(:rows, fn -> Diagnostics.route_policy_rows() end)
      |> assign_new(:guide_links, fn -> Diagnostics.guide_links() end)

    ~H"""
    <details class="fieldserv-diagnostics" data-route-id={@route_id}>
      <summary>
        <span>Route policy diagnostics</span>
        <small>Fieldserv routes only</small>
      </summary>

      <div class="fieldserv-diagnostics-body">
        <div class="fieldserv-diagnostics-table" role="table" aria-label="Fieldserv route policy rows">
          <div class="fieldserv-diagnostics-row fieldserv-diagnostics-row-head" role="row">
            <span role="columnheader">Route</span>
            <span role="columnheader">Owner</span>
            <span role="columnheader">Offline</span>
            <span role="columnheader">Security</span>
            <span role="columnheader">Support truth</span>
          </div>

          <div
            :for={row <- @rows}
            class={[
              "fieldserv-diagnostics-row",
              row.route_id == @route_id && "fieldserv-diagnostics-row-current"
            ]}
            role="row"
          >
            <span role="cell">
              <strong>{row.route_id}</strong>
              <code>{row.path}</code>
            </span>
            <span role="cell">{row.runtime_owner_label}</span>
            <span role="cell">{row.offline_posture_label}</span>
            <span role="cell">{row.security_posture_label}</span>
            <span role="cell">
              <strong>{row.support_label}</strong><br />
              <small>{row.rough_edge}</small><br />
              <small>{list_text(row.capability_labels)}</small><br />
              <small>{list_text(row.transfer_labels)}</small>
            </span>
          </div>
        </div>

        <div class="fieldserv-diagnostics-links" aria-label="Fieldserv support references">
          <a :for={link <- @guide_links} href={"/#{link.path}"}>{link.label}</a>
        </div>
      </div>
    </details>
    """
  end

  attr(:items, :list, default: [])

  def job_status_strip(assigns) do
    ~H"""
    <div class="fieldserv-status-strip" aria-label="Fieldserv job status">
      <section :for={item <- @items} class="fieldserv-status-item">
        <p>{item.label}</p>
        <strong>{item.value}</strong>
        <span>{item.detail}</span>
      </section>
    </div>
    """
  end

  attr(:items, :list, default: [])

  def evidence_timeline(assigns) do
    ~H"""
    <section class="fieldserv-evidence-timeline" aria-labelledby="fieldserv-evidence-heading">
      <h2 id="fieldserv-evidence-heading">Evidence timeline</h2>
      <ol>
        <li :for={item <- @items}>
          <div class="fieldserv-timeline-main">
            <strong>{item.title}</strong>
            <p>{Map.get(item, :backend_authority, "Backend verification owns media availability.")}</p>
          </div>
          <.status_badge
            label={Map.get(item, :status_label, format_atom(Map.get(item, :status)))}
            tone={status_tone(Map.get(item, :status))}
          />
        </li>
      </ol>
    </section>
    """
  end

  attr(:items, :list, default: [])

  def checklist_rows(assigns) do
    ~H"""
    <section class="fieldserv-checklist" aria-labelledby="fieldserv-checklist-heading">
      <h2 id="fieldserv-checklist-heading">Inspection checklist</h2>
      <ol>
        <li :for={item <- @items}>
          <div>
            <strong>{item.label}</strong>
            <p>{if item.evidence_required, do: "Evidence required", else: "Evidence optional"}</p>
          </div>
          <.status_badge label={format_atom(item.status)} tone={status_tone(item.status)} />
        </li>
      </ol>
    </section>
    """
  end

  attr(:label, :string, required: true)
  attr(:tone, :atom, default: :default)

  def status_badge(assigns) do
    ~H"""
    <span class={["fieldserv-status-badge", status_tone_class(@tone)]}>{@label}</span>
    """
  end

  defp nav_items(nil) do
    [
      %{label: "Jobs", path: "/fieldserv/jobs", route_id: "fieldserv-jobs"}
    ]
  end

  defp nav_items(%{id: job_id, evidence_id: evidence_id}) do
    [
      %{label: "Jobs", path: "/fieldserv/jobs", route_id: "fieldserv-jobs"},
      %{
        label: "Inspection",
        path: "/fieldserv/jobs/#{job_id}/inspection",
        route_id: "fieldserv-inspection"
      },
      %{
        label: "Capture",
        path: "/fieldserv/jobs/#{job_id}/capture",
        route_id: "fieldserv-job-capture"
      },
      %{
        label: "Evidence review",
        path: "/fieldserv/jobs/#{job_id}/evidence/#{evidence_id}/review",
        route_id: "fieldserv-evidence-review"
      }
    ]
  end

  defp nav_items(_job), do: nav_items(nil)

  defp badge_tone_class(label) do
    label = to_string(label)

    cond do
      String.contains?(label, "Native") or String.contains?(label, "native") ->
        "fieldserv-route-badge-native"

      String.contains?(label, "Cached") or String.contains?(label, "offline") ->
        "fieldserv-route-badge-offline"

      String.contains?(label, "Future") or String.contains?(label, "gap") ->
        "fieldserv-route-badge-gap"

      String.contains?(label, "LiveView") ->
        "fieldserv-route-badge-liveview"

      true ->
        "fieldserv-route-badge-default"
    end
  end

  defp status_tone(:backend_verified), do: :success
  defp status_tone(:complete), do: :success
  defp status_tone(:device_evidence_recorded), do: :native
  defp status_tone(:backend_verification_pending), do: :warning
  defp status_tone(:waiting_backend), do: :warning
  defp status_tone(:in_progress), do: :warning
  defp status_tone(:blocked_native_runtime), do: :native
  defp status_tone(:future_gap), do: :gap
  defp status_tone(:backend_rejected), do: :danger
  defp status_tone(_status), do: :default

  defp status_tone_class(:authority), do: "fieldserv-status-badge-authority"
  defp status_tone_class(:danger), do: "fieldserv-status-badge-danger"
  defp status_tone_class(:gap), do: "fieldserv-status-badge-gap"
  defp status_tone_class(:native), do: "fieldserv-status-badge-native"
  defp status_tone_class(:success), do: "fieldserv-status-badge-success"
  defp status_tone_class(:warning), do: "fieldserv-status-badge-warning"
  defp status_tone_class(_tone), do: "fieldserv-status-badge-default"

  defp format_atom(nil), do: "Not declared"

  defp format_atom(atom) when is_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp format_atom(value), do: to_string(value)

  defp list_text(nil), do: "Not declared"
  defp list_text([]), do: "Not declared"
  defp list_text(values), do: Enum.join(values, ", ")
end
