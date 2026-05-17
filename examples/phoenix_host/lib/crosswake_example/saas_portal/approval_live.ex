defmodule CrosswakeExample.SaaSPortal.ApprovalLive do
  use Phoenix.LiveView

  alias CrosswakeExample.SaaSPortal.Approvals

  @bridge_capability_version "1.0.0"
  @bridge_protocol "crosswake.bridge"
  @bridge_route_id "saas-approval"
  @shell_origin "https://example.crosswake.invalid"

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Approval detail",
       approval: nil,
       approval_notice: nil,
       approval_error: nil,
       bridge_request: nil
     )}
  end

  @impl true
  def handle_params(%{"id" => approval_id}, _uri, socket) do
    {:noreply, assign(socket, approval: Approvals.get_approval!(approval_id))}
  end

  @impl true
  def handle_event("approve", _params, socket) do
    approval = socket.assigns.approval
    user = socket.assigns.current_saas_user

    case Approvals.approve(approval, user) do
      {:ok, approved} ->
        {:noreply,
         assign(socket,
           approval: approved,
           approval_notice: "Approval confirmed by #{user.name}. Phoenix remains the authority.",
           approval_error: nil,
           bridge_request: haptics_request(approved.id)
         )}

      {:error, :forbidden} ->
        {:noreply,
         assign(socket,
           approval_notice: nil,
           approval_error: "Approver role required at the action boundary.",
           bridge_request: nil
         )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section :if={@approval}>
      <h1>{@approval.title}</h1>
      <p>
        Approval detail keeps the one write path server-authoritative. The shell only adds a
        bounded confirmation signal after success.
      </p>

      <dl>
        <dt>Status</dt>
        <dd>{@approval.status}</dd>
        <dt>Requested by</dt>
        <dd>{@approval.requested_by}</dd>
        <dt>Reviewed by</dt>
        <dd>{@approval.reviewed_by || "pending"}</dd>
      </dl>

      <p :if={@approval_notice}><strong>{@approval_notice}</strong></p>
      <p :if={@approval_error}><strong>{@approval_error}</strong></p>

      <button
        :if={@approval.status == :pending}
        type="button"
        phx-click="approve"
      >
        Approve request
      </button>

      <p :if={@approval.status == :approved}>
        Approval complete. The route stays LiveView-owned; the shell confirmation is secondary.
      </p>

      <script :if={@bridge_request} id="crosswake-approval-haptics">
        <%= Phoenix.HTML.raw(bridge_script(@bridge_request)) %>
      </script>
    </section>
    """
  end

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
