defmodule Crosswake.Plug.ThreadlineTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  alias Crosswake.Plug.Threadline

  test "inbound x-crosswake-thread-id header uses id verbatim, sets source: :inbound" do
    handler_id = "test-threadline-inbound"

    :telemetry.attach(
      handler_id,
      [:crosswake, :threadline, :request, :start],
      fn _name, _measurements, metadata, _config ->
        send(self(), {:telemetry_start, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    conn(:get, "/")
    |> put_req_header("x-crosswake-thread-id", "inbound-1234")
    |> Threadline.call(Threadline.init([]))

    assert_receive {:telemetry_start, metadata}
    assert metadata[:thread_id] == "inbound-1234"
    assert metadata[:source] == :inbound
  end

  test "absent header mints fresh UUID, sets source: :minted" do
    handler_id = "test-threadline-minted"

    :telemetry.attach(
      handler_id,
      [:crosswake, :threadline, :request, :start],
      fn _name, _measurements, metadata, _config ->
        send(self(), {:telemetry_start, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    conn(:get, "/")
    |> Threadline.call(Threadline.init([]))

    assert_receive {:telemetry_start, metadata}
    id = metadata[:thread_id]
    assert is_binary(id)
    assert id =~ ~r/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/
    assert metadata[:source] == :minted
  end

  test "Logger.metadata()[:crosswake_thread_id] equals the id after call/2" do
    conn =
      conn(:get, "/")
      |> put_req_header("x-crosswake-thread-id", "logger-test-id")

    Threadline.call(conn, Threadline.init([]))

    assert Logger.metadata()[:crosswake_thread_id] == "logger-test-id"
  end

  test "response header x-crosswake-thread-id echoes the id" do
    conn =
      conn(:get, "/")
      |> put_req_header("x-crosswake-thread-id", "echo-test-id")
      |> Threadline.call(Threadline.init([]))

    assert get_resp_header(conn, "x-crosswake-thread-id") == ["echo-test-id"]
  end

  test "[:crosswake, :threadline, :request, :stop] fires when response is sent" do
    handler_id = "test-threadline-stop"

    :telemetry.attach(
      handler_id,
      [:crosswake, :threadline, :request, :stop],
      fn _name, measurements, metadata, _config ->
        send(self(), {:telemetry_stop, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    conn(:get, "/")
    |> put_req_header("x-crosswake-thread-id", "stop-test-id")
    |> Threadline.call(Threadline.init([]))
    |> send_resp(200, "ok")

    assert_receive {:telemetry_stop, measurements, metadata}
    assert metadata[:thread_id] == "stop-test-id"
    assert metadata[:source] == :inbound
    assert Map.has_key?(measurements, :duration)
    assert measurements[:duration] >= 0
  end

  test "forbidden/PII metadata keys never reach handlers" do
    # Since the plug only puts thread_id and source anyway, we just verify the exact map shape.
    handler_id = "test-threadline-clean"

    :telemetry.attach(
      handler_id,
      [:crosswake, :threadline, :request, :start],
      fn _name, _measurements, metadata, _config ->
        send(self(), {:telemetry_start, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    conn(:get, "/")
    |> put_req_header("x-crosswake-thread-id", "clean-test")
    |> Threadline.call(Threadline.init([]))

    assert_receive {:telemetry_start, metadata}
    # It should strictly only contain thread_id and source
    assert map_size(metadata) == 2
    assert metadata[:thread_id] == "clean-test"
    assert metadata[:source] == :inbound
  end

  test "a raise in the plug's own minting work emits [:crosswake, :threadline, :request, :exception] and re-raises" do
    handler_id = "test-threadline-exception"

    :telemetry.attach(
      handler_id,
      [:crosswake, :threadline, :request, :exception],
      fn _name, measurements, metadata, _config ->
        send(self(), {:telemetry_exception, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    # We will trigger an error by passing a badly-formed opts map
    assert_raise FunctionClauseError, fn ->
      Threadline.call(conn(:get, "/"), %{header_name: :not_a_string_to_cause_error})
    end

    assert_receive {:telemetry_exception, measurements, _metadata}
    assert Map.has_key?(measurements, :duration)
  end
end
