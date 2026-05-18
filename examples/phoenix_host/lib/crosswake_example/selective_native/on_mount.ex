defmodule CrosswakeExample.SelectiveNative.OnMount do
  import Phoenix.LiveView

  def on_mount(:require_authenticated_member, _params, _session, socket) do
    {:cont, socket}
  end
end
