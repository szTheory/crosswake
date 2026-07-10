defmodule CrosswakeExample.SaaSPortal.ApprovalsLive do
  use Phoenix.LiveView

  alias CrosswakeExample.PageTitle
  alias CrosswakeExample.SaaSPortal.Approvals

  @impl true
  def mount(_params, _session, socket) do
    approvals = Approvals.list_approvals(socket.assigns.current_saas_account.id)

    {:ok,
     assign(socket,
       page_title: PageTitle.admin("Approvals"),
       approvals: approvals,
       pending_count: Enum.count(approvals, &(&1.status == :pending))
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section>
      <h1>Approvals queue</h1>
      <p>
        This is the center of the SaaS companion lane: Phoenix-owned queue review with one guarded
        server-authoritative action on the detail route.
      </p>

      <p>Pending approvals: {@pending_count}</p>

      <ul>
        <li :for={approval <- @approvals}>
          <strong>{approval.title}</strong>
          <span> status: {approval.status}</span>
        </li>
      </ul>
    </section>
    """
  end
end
