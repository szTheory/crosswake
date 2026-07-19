defmodule CrosswakeExample.SaaSPortal.DashboardLive do
  use Phoenix.LiveView

  alias CrosswakeExample.PageTitle
  alias CrosswakeExample.SaaSPortal.Accounts
  alias CrosswakeExample.SaaSPortal.Approvals
  alias CrosswakeExample.SaaSPortal.Components
  alias CrosswakeExample.SaaSPortal.Diagnostics

  @impl true
  def mount(_params, _session, socket) do
    account = socket.assigns.current_saas_account
    approvals = Approvals.list_approvals(account.id)
    account_summary = Accounts.account_summary!(account)
    activity_context = Accounts.activity_context_for_account!(account)

    {:ok,
     assign(socket,
       page_title: PageTitle.admin("Dashboard"),
       account_summary: account_summary,
       activity_context: activity_context,
       pending_approvals: Enum.filter(approvals, &(&1.status == :pending)),
       recent_activity: Enum.take(activity_context.activity_events, 3),
       kpis: dashboard_kpis(account_summary, approvals),
       diagnostics_rows: Diagnostics.route_policy_rows(),
       diagnostics_links: Diagnostics.guide_links()
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Components.admin_shell
      page_title="Northwind mobile approvals"
      route_id="saas-dashboard"
      current_saas_account={@current_saas_account}
      current_saas_user={@current_saas_user}
      posture_badges={["LiveView route", "Cached read-only", "Server authority"]}
    >
      <Components.kpi_strip items={@kpis} />

      <section class="adminpilot-panel">
        <h2>Approvals queue</h2>
        <p>
          Daily admin work stays Phoenix-owned. Account context is cached read-only,
          while approval decisions require the server before anything is committed.
        </p>
        <ul class="adminpilot-record-list">
          <li :for={approval <- @pending_approvals}>
            <strong>{approval.title}</strong>
            <p>Waiting for an approver under {approval.policy_id}.</p>
            <Components.status_badge label="Server authority" tone={:authority} />
          </li>
        </ul>
        <footer class="adminpilot-action-footer">
          <span role="status">{length(@pending_approvals)} approvals need review.</span>
          <a class="btn-primary" href="/saas/approvals">Open approvals</a>
        </footer>
      </section>

      <div class="adminpilot-panel-grid">
        <section class="adminpilot-panel">
          <h2>Account posture</h2>
          <dl>
            <dt>Plan</dt>
            <dd>{@account_summary.plan}</dd>
            <dt>Renewal window</dt>
            <dd>{@account_summary.renewal_window}</dd>
            <dt>Members</dt>
            <dd>{@account_summary.member_count}</dd>
            <dt>Cached read posture</dt>
            <dd>{@account_summary.cached_read_posture}</dd>
          </dl>
        </section>

        <section class="adminpilot-panel">
          <h2>Admin pressure</h2>
          <p>{@activity_context.admin_pressure.label}</p>
          <p>{@activity_context.admin_pressure.posture}</p>
          <a class="btn-secondary" href="/saas/admin/member-access">Review member access posture</a>
        </section>
      </div>

      <section class="adminpilot-panel">
        <h2>Recent activity</h2>
        <Components.activity_feed activities={@recent_activity} />
      </section>

      <Components.diagnostics_panel
        route_id="saas-dashboard"
        rows={@diagnostics_rows}
        guide_links={@diagnostics_links}
      />
    </Components.admin_shell>
    """
  end

  defp dashboard_kpis(account_summary, approvals) do
    grouped = Enum.group_by(approvals, & &1.status)

    [
      %{
        label: "Pending approvals",
        value: length(Map.get(grouped, :pending, [])),
        detail: "Review queue"
      },
      %{
        label: "Approved",
        value: length(Map.get(grouped, :approved, [])),
        detail: "Server recorded"
      },
      %{
        label: "Team members",
        value: account_summary.member_count,
        detail: "#{account_summary.role_count} roles"
      },
      %{label: "Renewal", value: account_summary.renewal_window, detail: "Account window"}
    ]
  end
end
