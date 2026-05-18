defmodule CrosswakeExample.SelectiveNative.OnMount do

  def on_mount(:require_authenticated_member, _params, _session, socket) do
    {:cont, socket}
  end
end
