defmodule CrosswakeExample.BridgeProofLive do
  use Phoenix.LiveView

  @bridge_capability_version "1.0.0"
  @bridge_protocol "crosswake.bridge"
  @bridge_route_id "bridge-proof"
  @shell_origin "https://example.crosswake.invalid"

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, bridge_request: nil, bridge_contract: share_request())}
  end

  @impl true
  def handle_event("share", _params, socket) do
    {:noreply, assign(socket, bridge_request: share_request())}
  end

  @impl true
  def render(assigns) do
    assigns = Map.put_new(assigns, :bridge_contract, share_request())

    ~H"""
    <link rel="stylesheet" href="/css/tokens.css" />
    <style>
      body {
        font-family: var(--cw-font-body);
        background-color: var(--cw-surface-default);
        color: var(--cw-text-default);
        margin: 0;
        padding: 2rem;
        display: flex;
        flex-direction: column;
        align-items: center;
      }
      .cw-bridge { width: 100%; max-width: 40rem; }
      .cw-bridge h1 { margin: 0.5rem 0; }
      .cw-bridge p { color: var(--cw-text-muted); }
      .cw-bridge button {
        padding: 0.75rem 1.5rem;
        border-radius: var(--cw-radius-sm);
        border: 2px solid transparent;
        font-weight: bold;
        cursor: pointer;
        background: var(--cw-action-bg);
        color: var(--cw-action-fg);
      }
      /* Wrap the bounded-bridge payload so the page does not stretch to the
         width of the single-line JSON. white-space: pre-wrap is visual only —
         the element's textContent is unchanged, so the route-tour payload
         assertions (JSON.parse of #crosswake-bridge-payload) still hold. */
      #crosswake-bridge-payload {
        background: var(--cw-surface-inset);
        border: 1px solid var(--cw-border-default);
        border-radius: var(--cw-radius-md);
        padding: 1rem;
        margin-top: 1.5rem;
        white-space: pre-wrap;
        overflow-wrap: anywhere;
        word-break: break-word;
        font-size: var(--cw-text-scale-sm);
        max-width: 100%;
        box-sizing: border-box;
      }
    </style>
    <section class="cw-bridge">
      <h1>Bridge Proof</h1>
      <p>Demonstrating bounded bridge capability integration.</p>

      <button
        type="button"
        phx-click="share"
        onclick="document.getElementById('crosswake-bridge-payload')?.removeAttribute('hidden')"
      >
        Share
      </button>

      <script :if={@bridge_request} id={"crosswake-share-#{@bridge_request["correlation_id"]}"}>
        <%= Phoenix.HTML.raw(bridge_script(@bridge_request)) %>
      </script>
      <pre :if={@bridge_request} id="crosswake-bridge-payload" hidden>
        <%= Jason.encode!(@bridge_request) %>
      </pre>
      <pre :if={!@bridge_request} id="crosswake-bridge-payload" hidden>
        <%= Jason.encode!(@bridge_contract) %>
      </pre>
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
