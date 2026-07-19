defmodule CrosswakeExample.BridgeProofLiveTest do
  use ExUnit.Case

  alias CrosswakeExample.BridgeProofLive

  test "renders initially without bridge script" do
    assigns = %{bridge_request: nil}
    html = Phoenix.HTML.Safe.to_iodata(BridgeProofLive.render(assigns)) |> IO.iodata_to_binary()

    assert html =~ "Bridge Proof"
    assert html =~ "Demonstrating bounded bridge capability integration"
    refute html =~ "crosswake-share-"
  end

  test "renders bridge script on share click" do
    # test handle_event
    socket = %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}, bridge_request: nil}}
    {:noreply, new_socket} = BridgeProofLive.handle_event("share", %{}, socket)

    assert new_socket.assigns.bridge_request["command"] == "share.invoke"
    assert new_socket.assigns.bridge_request["capability"] == "share"

    # test render with new assigns
    assigns = %{bridge_request: new_socket.assigns.bridge_request}
    html = Phoenix.HTML.Safe.to_iodata(BridgeProofLive.render(assigns)) |> IO.iodata_to_binary()

    assert html =~ "crosswake-share-"
    assert html =~ "crosswakeBridge.postMessage"
    assert html =~ ~s("command":"share.invoke")
    assert html =~ ~s("capability":"share")
    assert html =~ ~s("route_id":"bridge-proof")
  end
end
