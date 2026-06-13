defmodule CrosswakeExample.SelectiveNative.ClaimCaptureLiveTest do
  use ExUnit.Case
  alias CrosswakeExample.SelectiveNative.ClaimCaptureLive

  test "handle_event route_return assigns capture_completed to true" do
    socket = %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}, capture_completed: false}}
    
    {:noreply, new_socket} = ClaimCaptureLive.handle_event("route_return", %{}, socket)
    
    assert new_socket.assigns.capture_completed == true
  end
end
