defmodule Crosswake.Live.Threadline do
  @moduledoc """
  LiveView on_mount thread_id metadata bridge.

  Reads `_crosswake_thread_id` from the LiveView connect params
  and sets it as `crosswake_thread_id` in the process `Logger.metadata`.
  The Plug is the sole mint authority, and an absent param is a valid gap until Phase 93.
  """

  @doc false
  @spec on_mount(atom(), map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:cont, Phoenix.LiveView.Socket.t()}
  def on_mount(:default, _params, _session, socket) do
    if Phoenix.LiveView.connected?(socket) do
      case Phoenix.LiveView.get_connect_params(socket) do
        %{"_crosswake_thread_id" => id} when is_binary(id) and byte_size(id) > 0 ->
          Logger.metadata(crosswake_thread_id: id)

        _ ->
          :ok
      end
    end

    {:cont, socket}
  end
end
