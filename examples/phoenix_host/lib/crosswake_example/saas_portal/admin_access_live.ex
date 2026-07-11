defmodule CrosswakeExample.SaaSPortal.AdminAccessLive do
  use Phoenix.LiveView

  alias CrosswakeExample.PageTitle
  alias CrosswakeExample.SaaSPortal.Components
  alias CrosswakeExample.SaaSPortal.Diagnostics

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: PageTitle.admin("Admin Member Access"),
       proof_state: :blocked,
       route_id: "saas-admin-member-access",
       runtime_owner: "Phoenix LiveView",
       offline_policy: "unavailable",
       required_auth: "MFA, strict recent",
       session_source: "persistent native session",
       decision: "step_up_required",
       audit_ref: "support:admin-access",
       diagnostics_rows: Diagnostics.route_policy_rows(),
       diagnostics_links: Diagnostics.guide_links()
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Components.admin_shell
      page_title="Admin member access"
      route_id="saas-admin-member-access"
      current_saas_account={@current_saas_account}
      current_saas_user={@current_saas_user}
      posture_badges={[
        "LiveView route",
        "Offline unavailable",
        "Sensitive route",
        "MFA required",
        "Server authority"
      ]}
    >
      <section class="adminpilot-panel">
        <h2>Blocked member-access proof</h2>
        <p>
          A persistent shell session was present, but AdminPilot does not treat device
          continuity as admin authority. The Phoenix session needs backend step-up before
          this sensitive route can proceed.
        </p>
        <p role="status">
          Persistent shell session does not grant admin authority.
        </p>
      </section>

      <div class="adminpilot-panel-grid">
        <section class="adminpilot-panel">
          <h2>Decision posture</h2>
          <dl>
            <dt>Route</dt>
            <dd>{@route_id}</dd>
            <dt>Runtime</dt>
            <dd>{@runtime_owner}</dd>
            <dt>Offline</dt>
            <dd>{@offline_policy}</dd>
            <dt>Required auth</dt>
            <dd>MFA required / strict recent auth</dd>
          </dl>
        </section>

        <section class="adminpilot-panel">
          <h2>Support-safe finding</h2>
          <dl>
            <dt>Session source</dt>
            <dd>{@session_source}</dd>
            <dt>Decision</dt>
            <dd>{@decision}</dd>
            <dt>Authority</dt>
            <dd>Server authority</dd>
            <dt>Safe audit ref</dt>
            <dd>{@audit_ref}</dd>
          </dl>
        </section>
      </div>

      <Components.diagnostics_panel
        route_id="saas-admin-member-access"
        rows={@diagnostics_rows}
        guide_links={@diagnostics_links}
      />
    </Components.admin_shell>
    """
  end
end
