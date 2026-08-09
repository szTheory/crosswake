defmodule CrosswakeExample.BridgeProofLiveTest do
  @moduledoc """
  The bridge-proof route runs on `Crosswake.Bridge.push/3` (Phase 154, HRDN-01/D-70).

  These are real `Phoenix.LiveViewTest` round trips rather than hand-constructed
  `%Phoenix.LiveView.Socket{}` structs, because the seam has a mount contract: a socket
  that never called `Crosswake.Bridge.attach/1` raises `NotMountedError` instead of
  guessing a route id. A bare struct can no longer stand in for a mounted LiveView, and
  that is the point — it is the same requirement an adopter hits exactly once.
  """

  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint CrosswakeExample.Endpoint

  test "renders the idle state with no dispatched envelope" do
    {:ok, _view, html} = live(build_conn(), "/bridge-proof")

    assert html =~ "Bridge Proof"
    assert html =~ "Demonstrating bounded bridge capability integration"
    assert html =~ "No share request sent"

    refute html =~ "crosswakeBridge.postMessage",
           "HRDN-01 deletes the hand-rolled inline-script dispatch from this route"

    refute html =~ "share.invoke",
           "nothing is dispatched before the Share button is pressed"
  end

  test "pressing Share dispatches through the seam and renders the envelope the seam built" do
    {:ok, view, _html} = live(build_conn(), "/bridge-proof")

    render_click(view, "share")
    assert_push_event(view, "crosswake:bridge", envelope)

    assert envelope["command"] == "share.invoke"
    assert envelope["capability"] == "share"
    assert envelope["route_id"] == "bridge-proof"

    # The rendered raw payload IS the dispatched envelope, not a second hand-built copy
    # of it — so protocol and version can never drift from the shipped contract (D-67).
    html = render(view)
    assert html =~ ~s(&quot;command&quot;:&quot;share.invoke&quot;)
    assert html =~ ~s(&quot;capability&quot;:&quot;share&quot;)
    assert html =~ ~s(&quot;route_id&quot;:&quot;bridge-proof&quot;)
    assert html =~ ~s(&quot;version&quot;:&quot;#{Crosswake.Bridge.Contract.version()}&quot;)

    refute html =~ "crosswakeBridge.postMessage",
           "HRDN-01 deletes the hand-rolled inline-script dispatch from this route"
  end

  test "with nothing acknowledging the dispatch, the route renders a typed denial rather than silence (CTRL-02)" do
    previous = Application.get_env(:crosswake, :bridge_ack_deadline_ms)
    Application.put_env(:crosswake, :bridge_ack_deadline_ms, 25)

    on_exit(fn ->
      case previous do
        nil -> Application.delete_env(:crosswake, :bridge_ack_deadline_ms)
        value -> Application.put_env(:crosswake, :bridge_ack_deadline_ms, value)
      end
    end)

    {:ok, view, _html} = live(build_conn(), "/bridge-proof")

    render_click(view, "share")
    Process.sleep(120)

    html = render(view)
    assert html =~ "Shell declined: shell_unreachable"
    assert html =~ "before the wiring deadline"
  end
end
