defmodule CrosswakeExample.SaaSPortal.SettingsLive do
  use Phoenix.LiveView

  alias CrosswakeExample.PageTitle
  alias CrosswakeExample.SaaSPortal.Accounts
  alias CrosswakeExample.SaaSPortal.Components
  alias CrosswakeExample.SaaSPortal.Diagnostics

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: PageTitle.admin("Profile Settings"),
       settings: Accounts.settings_for_account!(socket.assigns.current_saas_account),
       role_summary: Accounts.role_summary(socket.assigns.current_saas_user),
       diagnostics_rows: Diagnostics.route_policy_rows(),
       diagnostics_links: Diagnostics.guide_links()
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Components.admin_shell
      page_title="Profile settings"
      route_id="saas-profile-settings"
      current_saas_account={@current_saas_account}
      current_saas_user={@current_saas_user}
      posture_badges={["LiveView route", "Cached read-only", "Authenticated session"]}
    >
      <div class="adminpilot-panel-grid">
        <section class="adminpilot-panel">
          <h2>Authenticated member</h2>
          <p>
            {@current_saas_user.name} is signed in as {format_role(@current_saas_user.role)}.
            This route shows profile posture from the Phoenix session and does not move
            authentication into the native shell.
          </p>
          <dl>
            <dt>Email</dt>
            <dd>{@current_saas_user.email}</dd>
            <dt>Account</dt>
            <dd>{@current_saas_account.name}</dd>
            <dt>Session posture</dt>
            <dd>Authenticated session</dd>
          </dl>
        </section>

        <section class="adminpilot-panel">
          <h2>Settings posture</h2>
          <dl>
            <dt>Approval threshold</dt>
            <dd>{@settings.approval_threshold}</dd>
            <dt>Cached read posture</dt>
            <dd>{@settings.cached_read_posture}</dd>
            <dt>Admin mutation boundary</dt>
            <dd>{@settings.native_boundary}</dd>
            <dt>Member access review</dt>
            <dd>{@settings.member_access_review}</dd>
          </dl>
        </section>
      </div>

      <section class="adminpilot-panel">
        <h2>Role summary</h2>
        <ul class="adminpilot-record-list">
          <li>
            <strong>{@role_summary.label}</strong>
            <p>{@role_summary.posture}</p>
            <small>{@role_summary.server_authority}</small>
          </li>
        </ul>
      </section>

      <Components.diagnostics_panel
        route_id="saas-profile-settings"
        rows={@diagnostics_rows}
        guide_links={@diagnostics_links}
      />
    </Components.admin_shell>
    """
  end

  defp format_role(role) when is_atom(role) do
    role
    |> Atom.to_string()
    |> String.capitalize()
  end

  defp format_role(role), do: to_string(role)
end
