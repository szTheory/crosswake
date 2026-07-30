defmodule CrosswakeExample.BridgeProofLive do
  use Phoenix.LiveView

  alias CrosswakeExample.Crosswake.Policy
  alias CrosswakeExample.Layouts
  alias CrosswakeExample.PageTitle

  @bridge_route_id "bridge-proof"
  @share_ref :share

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(
        crosswake_manifest: Policy.manifest(),
        crosswake_route_id: @bridge_route_id,
        bridge_request: nil,
        bridge_reply: nil,
        page_title: PageTitle.crosswake("Bridge Proof")
      )
      |> Crosswake.Bridge.attach()

    {:ok, socket}
  end

  @impl true
  def handle_event("share", _params, socket) do
    socket =
      Crosswake.Bridge.push(socket, "share",
        ref: @share_ref,
        payload: %{
          "title" => "Crosswake Bridge Proof",
          "text" => "Testing the native share dialog from Phoenix LiveView!",
          "url" => "https://crosswake.com"
        }
      )

    {:noreply,
     assign(socket,
       bridge_request: Crosswake.Bridge.dispatched(socket, @share_ref),
       bridge_reply: nil
     )}
  end

  @impl true
  def handle_info({:crosswake_bridge, @share_ref, %Crosswake.Bridge.Reply{} = reply}, socket) do
    {:noreply, assign(socket, bridge_reply: reply)}
  end

  @impl true
  def render(assigns) do
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
      #crosswake-bridge-reply {
        margin-top: 1.5rem;
        padding: 1rem;
        border: 1px solid var(--cw-border-default);
        border-radius: var(--cw-radius-md);
        background: var(--cw-surface-inset);
      }
      #crosswake-bridge-reply strong { color: var(--cw-text-default); }
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
      <Layouts.crosswake_bridge />

      <h1>Bridge Proof</h1>
      <p>Demonstrating bounded bridge capability integration.</p>

      <button type="button" phx-click="share">
        Share
      </button>

      <p
        id="crosswake-bridge-reply"
        role="status"
        aria-live="polite"
        aria-atomic="true"
        data-cw-reply-status={reply_status(@bridge_reply)}
      >
        {reply_sentence(@bridge_request, @bridge_reply)}
      </p>

      <pre id="crosswake-bridge-payload" hidden={@bridge_request == nil}>{@bridge_request && Jason.encode!(@bridge_request)}</pre>
    </section>
    """
  end

  # The raw protocol surface is deliberate here (D-68): this is the protocol-proof
  # route, so it dumps the whole envelope Crosswake.Bridge.push/3 actually built. The
  # product-shaped AdminPilot route shows curated evidence instead.

  defp reply_status(nil), do: "pending"
  defp reply_status(%Crosswake.Bridge.Reply{status: :ok}), do: "ok"
  defp reply_status(%Crosswake.Bridge.Reply{status: :deny}), do: "deny"

  defp reply_sentence(nil, _reply) do
    "No share request sent. Phoenix sends one when you press Share."
  end

  defp reply_sentence(_request, nil) do
    "Share request dispatched. Waiting for the shell to answer."
  end

  defp reply_sentence(_request, %Crosswake.Bridge.Reply{status: :ok}) do
    "Shell accepted the share request."
  end

  defp reply_sentence(_request, %Crosswake.Bridge.Reply{status: :deny, denial: denial}) do
    "Shell declined: #{denial.reason}. #{denial.message}"
  end
end
