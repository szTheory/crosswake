defmodule CrosswakeExample.SaaSPortal.DashboardLive do
  use Phoenix.LiveView

  alias CrosswakeExample.PageTitle
  alias CrosswakeExample.SaaSPortal.Approvals

  @impl true
  def mount(_params, _session, socket) do
    approvals = Approvals.list_approvals(socket.assigns.current_saas_account.id)

    {:ok,
     assign(socket,
       page_title: PageTitle.admin("Dashboard"),
       pending_approvals: Enum.filter(approvals, &(&1.status == :pending)),
       recent_activity: Enum.take(Enum.reverse(approvals), 2)
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section>
      <h1>Northwind mobile approvals</h1>
      <p>
        <strong>{@current_saas_account.name}</strong> stays Phoenix-owned here. Account health
        gives context, but approvals stay the daily action surface.
      </p>

      <div>
        <p>Account health: {@current_saas_account.health}</p>
        <p>Renewal window: {@current_saas_account.renewal_window}</p>
        <p>Open approvals: {length(@pending_approvals)}</p>
      </div>

      <section>
        <h2>Pending approvals</h2>
        <ul>
          <li :for={approval <- @pending_approvals}>
            <strong>{approval.title}</strong> is waiting for an approver.
          </li>
        </ul>
      </section>

      <section>
        <h2>Recent activity</h2>
        <ul>
          <li :for={approval <- @recent_activity}>
            {approval.title} is {approval.status}.
          </li>
        </ul>
      </section>
    </section>
    """
  end
end
