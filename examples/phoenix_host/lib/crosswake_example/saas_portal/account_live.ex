defmodule CrosswakeExample.SaaSPortal.AccountLive do
  use Phoenix.LiveView

  alias CrosswakeExample.PageTitle
  alias CrosswakeExample.SaaSPortal.Accounts
  alias CrosswakeExample.SaaSPortal.Approvals

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: PageTitle.admin("Account Health"),
       account: socket.assigns.current_saas_account,
       approval_summary: %{pending: 0, approved: 0}
     )}
  end

  @impl true
  def handle_params(%{"id" => account_id}, _uri, socket) do
    account = Accounts.get_account!(account_id)

    summary =
      account.id
      |> Approvals.list_approvals()
      |> Enum.group_by(& &1.status)
      |> then(fn grouped ->
        %{
          pending: length(Map.get(grouped, :pending, [])),
          approved: length(Map.get(grouped, :approved, []))
        }
      end)

    {:noreply,
     assign(socket,
       account: account,
       approval_summary: summary,
       page_title: PageTitle.admin(account.name)
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section>
      <h1>Account health</h1>
      <p>
        {@account.name} keeps one steady account boundary for the SaaS lane. This route explains
        why the approval queue matters without widening into admin-console breadth.
      </p>

      <dl>
        <dt>Health</dt>
        <dd>{@account.health}</dd>
        <dt>Renewal window</dt>
        <dd>{@account.renewal_window}</dd>
        <dt>Pending approvals</dt>
        <dd>{@approval_summary.pending}</dd>
        <dt>Approved approvals</dt>
        <dd>{@approval_summary.approved}</dd>
      </dl>
    </section>
    """
  end
end
