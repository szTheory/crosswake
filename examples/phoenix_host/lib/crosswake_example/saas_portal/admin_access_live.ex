defmodule CrosswakeExample.SaaSPortal.AdminAccessLive do
  use Phoenix.LiveView

  alias CrosswakeExample.PageTitle

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
       audit_ref: "support:admin-access"
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section>
      <h1>Admin member access</h1>
      <p>
        Native session found; admin access still requires step-up. Backend session authority
        decides access.
      </p>

      <dl>
        <dt>Route</dt>
        <dd>{@route_id}</dd>
        <dt>Runtime</dt>
        <dd>{@runtime_owner}</dd>
        <dt>Offline</dt>
        <dd>{@offline_policy}</dd>
        <dt>Required auth</dt>
        <dd>{@required_auth}</dd>
        <dt>Session</dt>
        <dd>{@session_source}</dd>
        <dt>Decision</dt>
        <dd>{@decision}</dd>
        <dt>Safe audit ref</dt>
        <dd>{@audit_ref}</dd>
      </dl>

      <p role="status">
        Persistent shell session does not grant admin authority.
      </p>
    </section>
    """
  end
end
