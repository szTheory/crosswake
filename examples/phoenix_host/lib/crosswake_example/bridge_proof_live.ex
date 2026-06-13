defmodule CrosswakeExample.BridgeProofLive do
  use Phoenix.LiveView

  @bridge_capability_version "1.0.0"
  @bridge_protocol "crosswake.bridge"
  @bridge_route_id "bridge-proof"
  @shell_origin "https://example.crosswake.invalid"

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, bridge_request: nil)}
  end

  @impl true
  def handle_event("share", _params, socket) do
    {:noreply, assign(socket, bridge_request: share_request())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section>
      <h1>Bridge Proof</h1>
      <p>Demonstrating bounded bridge capability integration.</p>

      <button type="button" phx-click="share">
        Share
      </button>

      <script :if={@bridge_request} id={"crosswake-share-#{@bridge_request["correlation_id"]}"}>
        <%= Phoenix.HTML.raw(bridge_script(@bridge_request)) %>
      </script>
    </section>
    """
  end

  defp share_request do
    %{
      "protocol" => @bridge_protocol,
      "version" => @bridge_capability_version,
      "command" => "share.invoke",
      "capability" => "share",
      "route_id" => @bridge_route_id,
      "active_route_id" => @bridge_route_id,
      "origin" => @shell_origin,
      "native_runtime_version" => "1.0.0",
      "correlation_id" => "share-#{System.unique_integer([:positive])}",
      "capabilities" => %{"share" => @bridge_capability_version},
      "installed_packs" => %{},
      "payload" => %{
        "title" => "Crosswake Bridge Proof",
        "text" => "Testing the native share dialog from Phoenix LiveView!",
        "url" => "https://crosswake.com"
      }
    }
  end

  defp bridge_script(request) do
    payload_json = Jason.encode!(request)

    """
    (() => {
      const payload = #{payload_json};
      if (window.webkit?.messageHandlers?.crosswakeBridge) {
        window.webkit.messageHandlers.crosswakeBridge.postMessage(payload);
      } else if (window.crosswakeBridge?.postMessage) {
        window.crosswakeBridge.postMessage(payload);
      }
    })();
    """
  end
end
