defmodule CrosswakeExample.SaaSPortal.AccountLive do
  use Phoenix.LiveView

  alias CrosswakeExample.PageTitle
  alias CrosswakeExample.SaaSPortal.Accounts
  alias CrosswakeExample.SaaSPortal.Approvals
  alias CrosswakeExample.SaaSPortal.Components
  alias CrosswakeExample.SaaSPortal.Diagnostics
  alias CrosswakeExample.SaaSPortal.Fixtures

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: PageTitle.admin("Account Health"),
       account: socket.assigns.current_saas_account,
       account_summary: Accounts.account_summary!(socket.assigns.current_saas_account),
       approval_summary: %{pending: 0, approved: 0},
       team: nil,
       settings: nil,
       activity_context: nil,
       role_summaries: [],
       diagnostics_rows: Diagnostics.route_policy_rows(),
       diagnostics_links: Diagnostics.guide_links()
     )}
  end

  @impl true
  def handle_params(%{"id" => account_id}, _uri, socket) do
    account = Accounts.get_account!(account_id)
    account_summary = Accounts.account_summary!(account)
    activity_context = Accounts.activity_context_for_account!(account)

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
       account_summary: account_summary,
       approval_summary: summary,
       team: Accounts.team_for_account!(account),
       settings: Accounts.settings_for_account!(account),
       activity_context: activity_context,
       role_summaries: Enum.map(Fixtures.roles(), &Accounts.role_summary(&1.key)),
       page_title: PageTitle.admin(account.name)
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Components.admin_shell
      page_title={@account.name <> " account health"}
      route_id="saas-account"
      current_saas_account={@current_saas_account}
      current_saas_user={@current_saas_user}
      posture_badges={["LiveView route", "Cached read-only", "Server authority"]}
    >
      <Components.kpi_strip
        items={[
          %{label: "Health", value: format_atom(@account.health), detail: @account_summary.plan},
          %{label: "Members", value: @account_summary.member_count, detail: @team.name},
          %{label: "Pending", value: @approval_summary.pending, detail: "Approvals"},
          %{label: "Renewal", value: @account_summary.renewal_window, detail: @account.region}
        ]}
      />

      <section class="adminpilot-panel">
        <h2>Read-only account context</h2>
        <p>
          {@account.name} keeps one account boundary for AdminPilot. No edit controls
          are exposed here; the lane shows context around the approval workflow without
          becoming a generic admin console.
        </p>
        <dl>
          <dt>Team</dt>
          <dd>{@team.name} · {@team.focus}</dd>
          <dt>Approval threshold</dt>
          <dd>{@settings.approval_threshold}</dd>
          <dt>Member access review</dt>
          <dd>{@settings.member_access_review}</dd>
          <dt>Native boundary</dt>
          <dd>{@settings.native_boundary}</dd>
        </dl>
      </section>

      <div class="adminpilot-panel-grid">
        <section class="adminpilot-panel">
          <h2>Roles</h2>
          <ul class="adminpilot-record-list">
            <li :for={role <- @role_summaries}>
              <strong>{role.label}</strong>
              <p>{role.posture}</p>
              <small>{role.server_authority}</small>
              <ul>
                <li :for={member <- role.members}>{member.name}</li>
              </ul>
              <Components.status_badge label={role.server_authority} tone={:authority} />
            </li>
          </ul>
        </section>

        <section class="adminpilot-panel">
          <h2>Operational records</h2>
          <ul class="adminpilot-record-list">
            <li :for={record <- @activity_context.operational_records}>
              <strong>{record.title}</strong>
              <p>{format_atom(record.status)}</p>
              <small>{record.route_id}</small>
            </li>
          </ul>
        </section>
      </div>

      <section class="adminpilot-panel">
        <h2>Policies and activity</h2>
        <ul class="adminpilot-record-list">
          <li :for={policy <- @activity_context.approval_policies}>
            <strong>{policy.title}</strong>
            <p>{format_atom(policy.required_role)} required</p>
            <Components.status_badge label={policy.support_label} tone={:authority} />
          </li>
        </ul>
        <Components.activity_feed activities={@activity_context.activity_events} />
      </section>

      <Components.diagnostics_panel
        route_id="saas-account"
        rows={@diagnostics_rows}
        guide_links={@diagnostics_links}
      />
    </Components.admin_shell>
    """
  end

  defp format_atom(atom) when is_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp format_atom(value), do: to_string(value)
end
