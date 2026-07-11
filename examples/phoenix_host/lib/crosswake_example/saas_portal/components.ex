defmodule CrosswakeExample.SaaSPortal.Components do
  @moduledoc """
  AdminPilot-specific function components for the SaaS/admin showcase lane.

  These components are intentionally lane-local. They render product chrome and
  support truth for AdminPilot without becoming a generic admin framework.
  """

  use Phoenix.Component

  alias CrosswakeExample.SaaSPortal.Diagnostics
  alias CrosswakeExample.Showcase.Branding

  attr(:page_title, :string, required: true)
  attr(:route_id, :string, required: true)
  attr(:current_saas_account, :map, required: true)
  attr(:current_saas_user, :map, required: true)
  attr(:posture_badges, :list, default: [])
  slot(:inner_block)

  def admin_shell(assigns) do
    assigns =
      assigns
      |> assign(:brand, Branding.brand_for!(:saas_admin))
      |> assign(:nav_items, nav_items(assigns.current_saas_account.id))

    ~H"""
    <div class={"adminpilot-shell #{@brand.theme_class}"} data-route-id={@route_id}>
      <header class="adminpilot-topbar" aria-label="AdminPilot workspace">
        <div class="adminpilot-brand-lockup">
          <span class="adminpilot-mark" aria-hidden="true">{@brand.mark}</span>
          <div class="adminpilot-brand-copy">
            <p class="adminpilot-category">{@brand.category}</p>
            <p class="adminpilot-product">{@brand.name}</p>
            <p class="adminpilot-tagline">{@brand.tagline}</p>
          </div>
        </div>

        <div class="adminpilot-session-summary" aria-label="Current AdminPilot session">
          <span>{@current_saas_account.name}</span>
          <span>{@current_saas_user.name} · {format_role(@current_saas_user.role)}</span>
        </div>
      </header>

      <nav class="adminpilot-nav" aria-label="AdminPilot routes">
        <a
          :for={item <- @nav_items}
          href={item.path}
          class={[
            "adminpilot-nav-link",
            item.route_id == @route_id && "adminpilot-nav-link-active"
          ]}
          aria-current={if item.route_id == @route_id, do: "page", else: nil}
        >
          {item.label}
        </a>
      </nav>

      <div class="adminpilot-layout">
        <main class="adminpilot-main" aria-labelledby="adminpilot-page-title">
          <header class="adminpilot-page-heading">
            <div>
              <p class="adminpilot-page-kicker">{@brand.tone}</p>
              <h1 id="adminpilot-page-title">{@page_title}</h1>
            </div>
            <.posture_badges badges={@posture_badges} />
          </header>

          {render_slot(@inner_block)}
        </main>
      </div>
    </div>
    """
  end

  attr(:badges, :list, default: [])

  def posture_badges(assigns) do
    ~H"""
    <div class="adminpilot-posture-badges" aria-label="Route posture">
      <span
        :for={badge <- @badges}
        class={["adminpilot-route-badge", badge_tone_class(badge)]}
      >
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
    <details class="adminpilot-diagnostics" data-route-id={@route_id}>
      <summary>
        <span>Route policy diagnostics</span>
        <small>AdminPilot routes only</small>
      </summary>

      <div class="adminpilot-diagnostics-body">
        <div class="adminpilot-diagnostics-table" role="table" aria-label="AdminPilot route policy rows">
          <div class="adminpilot-diagnostics-row adminpilot-diagnostics-row-head" role="row">
            <span role="columnheader">Route</span>
            <span role="columnheader">Owner</span>
            <span role="columnheader">Offline</span>
            <span role="columnheader">Security</span>
            <span role="columnheader">Support truth</span>
          </div>

          <div
            :for={row <- @rows}
            class={[
              "adminpilot-diagnostics-row",
              row.route_id == @route_id && "adminpilot-diagnostics-row-current"
            ]}
            role="row"
          >
            <span role="cell">
              <strong>{row.route_id}</strong>
              <code>{row.path}</code>
            </span>
            <span role="cell">{row.runtime_owner_label}</span>
            <span role="cell">{row.offline_posture_label}</span>
            <span role="cell">
              {row.security_posture_label}<br />
              <small>{row.auth_posture_label}</small>
            </span>
            <span role="cell">
              <strong>{row.support_label}</strong><br />
              <small>{row.approval_authority}</small><br />
              <small>{row.rough_edge}</small><br />
              <small>{Enum.join(row.capability_labels, ", ")}</small>
            </span>
          </div>
        </div>

        <div class="adminpilot-diagnostics-links" aria-label="AdminPilot support references">
          <a :for={link <- @guide_links} href={"/#{link.path}"}>{link.label}</a>
        </div>
      </div>
    </details>
    """
  end

  attr(:items, :list, default: [])

  def kpi_strip(assigns) do
    ~H"""
    <div class="adminpilot-kpi-strip" aria-label="AdminPilot workspace metrics">
      <section :for={item <- @items} class="adminpilot-kpi">
        <p>{item.label}</p>
        <strong>{item.value}</strong>
        <span>{item.detail}</span>
      </section>
    </div>
    """
  end

  attr(:activities, :list, default: [])

  def activity_feed(assigns) do
    ~H"""
    <ol class="adminpilot-activity-feed" aria-label="AdminPilot activity feed">
      <li :for={activity <- @activities}>
        <span class="adminpilot-activity-type">{format_event(activity.event_type)}</span>
        <p>{activity.summary}</p>
        <small>{activity.route_id}</small>
      </li>
    </ol>
    """
  end

  attr(:label, :string, required: true)
  attr(:tone, :atom, default: :default)

  def status_badge(assigns) do
    ~H"""
    <span class={["adminpilot-status-badge", status_tone_class(@tone)]}>{@label}</span>
    """
  end

  defp nav_items(account_id) do
    [
      %{label: "Dashboard", path: "/saas/dashboard", route_id: "saas-dashboard"},
      %{label: "Approvals", path: "/saas/approvals", route_id: "saas-approvals"},
      %{label: "Account", path: "/saas/accounts/#{account_id}", route_id: "saas-account"},
      %{label: "Settings", path: "/saas/settings/profile", route_id: "saas-profile-settings"},
      %{
        label: "Admin access",
        path: "/saas/admin/member-access",
        route_id: "saas-admin-member-access"
      }
    ]
  end

  defp badge_tone_class(label) do
    cond do
      label =~ "Cached" or label =~ "Offline" -> "adminpilot-route-badge-offline"
      label =~ "Sensitive" or label =~ "MFA" -> "adminpilot-route-badge-sensitive"
      label =~ "Server" -> "adminpilot-route-badge-authority"
      label =~ "LiveView" -> "adminpilot-route-badge-liveview"
      true -> "adminpilot-route-badge-default"
    end
  end

  defp status_tone_class(:authority), do: "adminpilot-status-badge-authority"
  defp status_tone_class(:sensitive), do: "adminpilot-status-badge-sensitive"
  defp status_tone_class(:success), do: "adminpilot-status-badge-success"
  defp status_tone_class(:warning), do: "adminpilot-status-badge-warning"
  defp status_tone_class(_tone), do: "adminpilot-status-badge-default"

  defp format_role(role) when is_atom(role) do
    role
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp format_role(role), do: to_string(role)

  defp format_event(event_type) when is_atom(event_type) do
    event_type
    |> Atom.to_string()
    |> String.replace("_", " ")
  end

  defp format_event(event_type), do: to_string(event_type)
end
