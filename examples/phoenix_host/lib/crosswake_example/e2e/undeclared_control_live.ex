defmodule CrosswakeExample.E2E.UndeclaredControlLive do
  @moduledoc """
  Test-only LiveView proving PROOF-01's A2 condition (Phase 155 Plan 07, D-43,
  D-46): the route DECLARES its capability family (`haptics`), so `Bridge.push/3`
  dispatches for real — the point of A2 is a SHELL-SIDE rejection decoded off the
  wire, not the server-side `UndeclaredCapabilityError` preflight raise that fires
  when a route never declares the capability at all. Only the shell-side moment is
  browser-observable (D-43); the outbound raise renders nothing and is proven
  server-side in ExUnit instead.

  Mounted only in `:test` and `:e2e` environments — see the compile-time guard in
  `router.ex`. Never mounted in `:prod`.
  """
  use Phoenix.LiveView

  alias Crosswake.Bridge
  alias CrosswakeExample.Crosswake.Policy
  alias CrosswakeExample.Layouts
  alias CrosswakeExampleWeb.CrosswakeFallbacks

  @route_id "e2e-a2-shell-denial"
  # Reuses the ALREADY-DECLARED, already-shipped "haptics" family (D-43): adding a
  # new capability here would touch CatalogGuard's six-step recipe, which is out of
  # scope for a test-only proof route. The route's `crosswake:` policy declares it,
  # so `push/3` dispatches for real instead of raising the preflight error.
  @haptics_family "haptics"
  @control_ref :undeclared_control

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(
        crosswake_manifest: Policy.manifest(),
        crosswake_route_id: @route_id,
        bridge_reply: nil,
        fallback_kind: nil,
        effect_count: 0
      )
      |> Bridge.attach()

    {:ok, socket}
  end

  @impl true
  def handle_event("attempt_control", _params, socket) do
    socket =
      socket
      |> assign(bridge_reply: nil, fallback_kind: nil)
      |> Bridge.push(@haptics_family, ref: @control_ref, payload: %{"style" => "light"})

    {:noreply, socket}
  end

  # The negative control that matters (D-46): the server-side effect only ever
  # increments on an :ok reply, never merely because a request was dispatched or a
  # denial rendered. A rendered denial is not evidence the mutation did not happen —
  # this is the code path that makes that evidence real.
  @impl true
  def handle_info({:crosswake_bridge, @control_ref, %Bridge.Reply{status: :ok} = reply}, socket) do
    {:noreply,
     assign(socket, bridge_reply: reply, effect_count: socket.assigns.effect_count + 1)}
  end

  @impl true
  def handle_info({:crosswake_bridge, @control_ref, %Bridge.Reply{status: :deny} = reply}, socket) do
    {:noreply,
     assign(socket, bridge_reply: reply, fallback_kind: fallback_kind(reply.denial))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <link rel="stylesheet" href="/crosswake/tokens.css" />
    <style>
      body {
        font-family: var(--cw-font-body);
        background-color: var(--cw-surface-default);
        color: var(--cw-text-default);
        margin: 0;
        padding: 2rem;
      }
    </style>
    <section>
      <h1>E2E: undeclared control (PROOF-01 A2)</h1>
      <p>
        This route declares <code>haptics</code> in its route policy, so the request
        dispatches for real. PROOF-01's A2 condition injects a shell-side denial to
        prove the denial renders AND the effect below does not proceed.
      </p>

      <button type="button" id="undeclared-control-trigger" phx-click="attempt_control">
        Attempt the control
      </button>

      <p id="undeclared-control-success" :if={@bridge_reply && @bridge_reply.status == :ok} role="status">
        Control succeeded.
      </p>

      <p id="undeclared-control-effect" data-cw-effect-count={@effect_count}>
        Server-side effect count: {@effect_count}
      </p>

      <CrosswakeFallbacks.fallback_alert :if={@fallback_kind} kind={@fallback_kind} />

      <Layouts.crosswake_bridge />
    </section>
    """
  end

  # The two-remediation-collapse regression guard lives here (D-13, D-46): an
  # `:undeclared_capability` wire reason must map to `kind: :undeclared`, never to
  # `:stale_binary` (the remediation `fallback_alert/1` renders for a reason it does
  # not itself recognize as undeclared) — collapsing the two would make an adopter
  # tell a user to update the app when the real fix is a route policy change.
  defp fallback_kind(%{reason: :undeclared_capability}), do: :undeclared
  defp fallback_kind(%{reason: :shell_unreachable}), do: :shell_unreachable
  defp fallback_kind(_other), do: :stale_binary
end
