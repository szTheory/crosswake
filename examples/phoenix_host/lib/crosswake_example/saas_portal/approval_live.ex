defmodule CrosswakeExample.SaaSPortal.ApprovalLive do
  use Phoenix.LiveView

  alias CrosswakeExample.PageTitle
  alias CrosswakeExample.SaaSPortal.Approvals
  alias CrosswakeExample.SaaSPortal.Components
  alias CrosswakeExample.SaaSPortal.Diagnostics

  @bridge_capability_version "1.0.0"
  @bridge_protocol "crosswake.bridge"
  @bridge_route_id "saas-approval"
  @shell_origin "https://example.crosswake.invalid"

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: PageTitle.admin("Approval Detail"),
       approval: nil,
       activity_events: [],
       approval_notice: nil,
       approval_error: nil,
       bridge_request: nil,
       diagnostics_rows: Diagnostics.route_policy_rows(),
       diagnostics_links: Diagnostics.guide_links()
     )}
  end

  @impl true
  def handle_params(%{"id" => approval_id}, _uri, socket) do
    approval = Approvals.get_approval!(approval_scope(socket), approval_id)

    {:noreply,
     assign(socket,
       approval: approval,
       activity_events: activity_for_display(approval.id),
       page_title: PageTitle.admin(approval.title)
     )}
  end

  @impl true
  def handle_event("approve", _params, socket) do
    approval = socket.assigns.approval

    case Approvals.approve_approval(approval_scope(socket), approval.id, %{
           haptics: "post_success_optional"
         }) do
      {:ok, approved} ->
        {:noreply,
         assign(socket,
           approval: approved,
           activity_events: activity_for_display(approved.id),
           approval_notice:
             "Phoenix recorded the decision for #{approved.title}. Haptics is optional confirmation only.",
           approval_error: nil,
           bridge_request: haptics_request(approved.id)
         )}

      {:error, :forbidden} ->
        {:noreply,
         assign(socket,
           approval_notice: nil,
           approval_error:
             "Approver role required. Phoenix kept the request unchanged at the server boundary.",
           bridge_request: nil
         )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Components.admin_shell
      page_title={if @approval, do: @approval.title, else: "Approval detail"}
      route_id="saas-approval"
      current_saas_account={@current_saas_account}
      current_saas_user={@current_saas_user}
      posture_badges={["LiveView route", "Cached read-only", "Server authority", "haptics.impact"]}
    >
      <section :if={@approval} class="adminpilot-panel" aria-labelledby="approval-detail-heading">
        <div class="adminpilot-section-heading">
          <div>
            <h2 id="approval-detail-heading">Server-authoritative decision</h2>
            <p>
              Phoenix owns this approval mutation through the AdminPilot context. Optional haptics
              can confirm success after the server records the decision.
            </p>
          </div>
          <Components.status_badge label={status_label(@approval.status)} tone={status_tone(@approval.status)} />
        </div>

        <dl>
          <dt>Status</dt>
          <dd>{status_label(@approval.status)}</dd>
          <dt>Requested by</dt>
          <dd>{@approval.requested_by}</dd>
          <dt>Reviewer</dt>
          <dd>{@approval.reviewed_by || "Pending server review"}</dd>
          <dt>Policy</dt>
          <dd>{@approval.policy_id}</dd>
          <dt>Support ref</dt>
          <dd>{@approval.support_ref}</dd>
        </dl>
      </section>

      <section :if={@approval} class="adminpilot-panel">
        <h2>Action footer</h2>
        <p>
          Server authority is required before any shell confirmation. The success message remains
          visible even when no bridge object is present in the browser.
        </p>

        <p :if={@approval_notice} role="status">
          <strong>{@approval_notice}</strong>
        </p>
        <p :if={@approval_error} role="alert">
          <strong>{@approval_error}</strong>
        </p>

        <button
          :if={@approval.status == :pending}
          class="btn-primary"
          type="button"
          phx-click="approve"
          phx-disable-with="Approving through Phoenix..."
        >
          Approve request
        </button>

        <p :if={@approval.status == :approved} role="status">
          Phoenix recorded the decision. Optional haptics can only acknowledge this completed
          server action.
        </p>
      </section>

      <section :if={@approval} class="adminpilot-panel">
        <h2>Activity trail</h2>
        <Components.activity_feed activities={@activity_events} />
      </section>

      <section :if={@approval} class="adminpilot-panel">
        <h2>Optional haptics</h2>
        <p>
          The route declares <code>haptics.impact</code> as a bounded, low-frequency confirmation.
          Approval success does not depend on <code>window.webkit</code> or
          <code>window.crosswakeBridge</code>.
        </p>
        <dl :if={@bridge_request}>
          <dt>Command</dt>
          <dd>{@bridge_request["command"]}</dd>
          <dt>Capability</dt>
          <dd>{@bridge_request["capability"]}</dd>
          <dt>Route</dt>
          <dd>{@bridge_request["route_id"]}</dd>
          <dt>Correlation</dt>
          <dd>{@bridge_request["correlation_id"]}</dd>
        </dl>
      </section>

      <Components.diagnostics_panel
        route_id="saas-approval"
        rows={@diagnostics_rows}
        guide_links={@diagnostics_links}
      />

      <script :if={@bridge_request} id="crosswake-approval-haptics">
        <%= Phoenix.HTML.raw(bridge_script(@bridge_request)) %>
      </script>
    </Components.admin_shell>
    """
  end

  defp approval_scope(socket) do
    %{
      user: socket.assigns.current_saas_user,
      account: socket.assigns.current_saas_account,
      route_id: @bridge_route_id
    }
  end

  defp activity_for_display(approval_id) do
    approval_id
    |> Approvals.activity_for_approval()
    |> Enum.map(fn event -> Map.put_new(event, :summary, activity_summary(event)) end)
  end

  defp activity_summary(%{event_type: :approval_approved, actor_id: actor_id}) do
    "Approved by #{actor_id} through Phoenix server authority."
  end

  defp activity_summary(%{event_type: :approval_seeded, actor_id: actor_id}) do
    "Seeded as deterministic AdminPilot evidence for #{actor_id}."
  end

  defp activity_summary(%{event_type: event_type, actor_id: actor_id}) do
    "#{event_type} by #{actor_id}."
  end

  defp status_label(:pending), do: "Pending review"
  defp status_label(:approved), do: "Approved"
  defp status_label(status), do: status |> to_string() |> String.capitalize()

  defp status_tone(:pending), do: :warning
  defp status_tone(:approved), do: :success
  defp status_tone(_status), do: :default

  defp haptics_request(approval_id) do
    %{
      "protocol" => @bridge_protocol,
      "version" => @bridge_capability_version,
      "command" => "haptics.impact",
      "capability" => "haptics.impact",
      "route_id" => @bridge_route_id,
      "active_route_id" => @bridge_route_id,
      "origin" => @shell_origin,
      "native_runtime_version" => "1.0.0",
      "correlation_id" => "approval-haptics-#{approval_id}",
      "capabilities" => %{"haptics.impact" => @bridge_capability_version},
      "installed_packs" => %{},
      "payload" => %{"style" => "light"}
    }
  end

  defp bridge_script(request) do
    payload = Jason.encode!(request)

    """
    (() => {
      const payload = #{Jason.encode!(payload)};
      if (window.webkit?.messageHandlers?.crosswakeBridge) {
        window.webkit.messageHandlers.crosswakeBridge.postMessage(payload);
      } else if (window.crosswakeBridge?.postMessage) {
        window.crosswakeBridge.postMessage(payload);
      }
    })();
    """
  end
end
