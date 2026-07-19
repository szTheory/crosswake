defmodule CrosswakeExample.SaaSPortal.ApprovalsLive do
  use Phoenix.LiveView

  alias CrosswakeExample.PageTitle
  alias CrosswakeExample.SaaSPortal.Approvals
  alias CrosswakeExample.SaaSPortal.Components
  alias CrosswakeExample.SaaSPortal.Diagnostics

  @impl true
  def mount(_params, _session, socket) do
    approvals = Approvals.list_approvals(socket.assigns.current_saas_account.id)
    grouped = Enum.group_by(approvals, & &1.status)

    {:ok,
     assign(socket,
       page_title: PageTitle.admin("Approvals"),
       approvals: approvals,
       pending_count: length(Map.get(grouped, :pending, [])),
       approved_count: length(Map.get(grouped, :approved, [])),
       diagnostics_rows: Diagnostics.route_policy_rows(),
       diagnostics_links: Diagnostics.guide_links()
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Components.admin_shell
      page_title="Approvals queue"
      route_id="saas-approvals"
      current_saas_account={@current_saas_account}
      current_saas_user={@current_saas_user}
      posture_badges={["LiveView route", "Cached read-only", "Server authority"]}
    >
      <Components.kpi_strip
        items={[
          %{label: "Pending", value: @pending_count, detail: "Needs review"},
          %{label: "Approved", value: @approved_count, detail: "Server recorded"},
          %{label: "Route owner", value: "Phoenix", detail: "LiveView route"},
          %{label: "Offline", value: "Read-only", detail: "No local writes"}
        ]}
      />

      <section class="adminpilot-panel" aria-labelledby="approval-queue-heading">
        <div class="adminpilot-section-heading">
          <div>
            <h2 id="approval-queue-heading">Focused approval workspace</h2>
            <p>
              Review each request from cached read-only queue context, then open the detail route
              for the one server-authoritative approval action.
            </p>
          </div>
          <span role="status">
            {@pending_count} pending and {@approved_count} approved approvals are visible in this queue.
          </span>
        </div>

        <ol class="adminpilot-record-list" aria-label="AdminPilot approval requests">
          <li :for={approval <- @approvals}>
            <div class="adminpilot-record-main">
              <strong>
                <a href={"/saas/approvals/#{approval.id}"}>{approval.title}</a>
              </strong>
              <p>{status_label(approval.status)} · {approval.policy_id}</p>
              <dl>
                <dt>Requested by</dt>
                <dd>{approval.requested_by}</dd>
                <dt>Reviewer</dt>
                <dd>{approval.reviewed_by || "Pending server review"}</dd>
                <dt>Support ref</dt>
                <dd>{approval.support_ref}</dd>
              </dl>
            </div>
            <div class="adminpilot-record-actions">
              <Components.status_badge label={status_label(approval.status)} tone={status_tone(approval.status)} />
              <Components.status_badge label="Server authority" tone={:authority} />
              <a class="btn-secondary" href={"/saas/approvals/#{approval.id}"}>Review detail</a>
            </div>
          </li>
        </ol>
      </section>

      <section class="adminpilot-panel">
        <h2>Support posture</h2>
        <p>
          This queue is a LiveView route with cached read-only support truth. AdminPilot does not
          claim approval decisions are available while disconnected, queued for later replay, or
          owned by native confirmation.
        </p>
        <div class="adminpilot-posture-badges" aria-label="Approval queue support badges">
          <Components.status_badge label="Cached read-only" tone={:warning} />
          <Components.status_badge label="Server authority" tone={:authority} />
          <Components.status_badge label="Detail route owns approval action" tone={:success} />
        </div>
      </section>

      <Components.diagnostics_panel
        route_id="saas-approvals"
        rows={@diagnostics_rows}
        guide_links={@diagnostics_links}
      />
    </Components.admin_shell>
    """
  end

  defp status_label(:pending), do: "Pending review"
  defp status_label(:approved), do: "Approved"
  defp status_label(status), do: status |> to_string() |> String.capitalize()

  defp status_tone(:pending), do: :warning
  defp status_tone(:approved), do: :success
  defp status_tone(_status), do: :default
end
