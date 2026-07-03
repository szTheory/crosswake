defmodule Crosswake.Live.ThreadlineTest do
  use ExUnit.Case, async: true

  alias Crosswake.Live.Threadline

  setup do
    Logger.metadata(crosswake_thread_id: nil)
    :ok
  end

  # -----------------------------------------------------------------------
  # Contract: on_mount/4 sets metadata for connected socket with valid param
  # -----------------------------------------------------------------------

  test "connected socket with valid _crosswake_thread_id connect param sets metadata" do
    socket = %Phoenix.LiveView.Socket{
      transport_pid: self(),
      private: %{connect_params: %{"_crosswake_thread_id" => "tid-123"}}
    }

    assert {:cont, ^socket} = Threadline.on_mount(:default, %{}, %{}, socket)

    assert Logger.metadata()[:crosswake_thread_id] == "tid-123"
  end

  # -----------------------------------------------------------------------
  # Contract: on_mount/4 is no-op for disconnected/static socket
  # -----------------------------------------------------------------------

  test "disconnected/static socket returns {:cont, socket} and does not set metadata" do
    socket = %Phoenix.LiveView.Socket{
      transport_pid: nil,
      private: %{connect_params: nil}
    }

    assert {:cont, ^socket} = Threadline.on_mount(:default, %{}, %{}, socket)

    assert Logger.metadata()[:crosswake_thread_id] == nil
  end

  # -----------------------------------------------------------------------
  # Contract: on_mount/4 is no-op when connect param is absent
  # -----------------------------------------------------------------------

  test "connected socket with absent _crosswake_thread_id returns {:cont, socket} and does not set metadata" do
    socket = %Phoenix.LiveView.Socket{
      transport_pid: self(),
      private: %{connect_params: %{"other" => "value"}}
    }

    assert {:cont, ^socket} = Threadline.on_mount(:default, %{}, %{}, socket)

    assert Logger.metadata()[:crosswake_thread_id] == nil
  end

  # -----------------------------------------------------------------------
  # Contract: on_mount/4 is no-op for invalid param values (non-binary/empty)
  # -----------------------------------------------------------------------

  test "connected socket with empty string _crosswake_thread_id does not set metadata" do
    socket = %Phoenix.LiveView.Socket{
      transport_pid: self(),
      private: %{connect_params: %{"_crosswake_thread_id" => ""}}
    }

    assert {:cont, ^socket} = Threadline.on_mount(:default, %{}, %{}, socket)

    assert Logger.metadata()[:crosswake_thread_id] == nil
  end

  test "connected socket with non-binary _crosswake_thread_id does not set metadata" do
    socket = %Phoenix.LiveView.Socket{
      transport_pid: self(),
      private: %{connect_params: %{"_crosswake_thread_id" => 123}}
    }

    assert {:cont, ^socket} = Threadline.on_mount(:default, %{}, %{}, socket)

    assert Logger.metadata()[:crosswake_thread_id] == nil
  end
end
