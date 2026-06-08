defmodule CrosswakeExample.SelectiveNative.OnMount do
  import Phoenix.Component
  import Phoenix.LiveView

  def on_mount(:require_authenticated_member, _params, _session, socket) do
    capabilities =
      if connected?(socket) do
        get_connect_params(socket)["capabilities"] || []
      else
        []
      end

    socket = assign(socket, :native_capabilities, capabilities)

    {:cont, socket}
  end
end
