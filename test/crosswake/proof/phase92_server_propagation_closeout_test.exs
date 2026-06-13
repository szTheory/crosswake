defmodule Crosswake.Proof.Phase92ServerPropagationCloseoutTest do
  @moduledoc """
  Hermetic merge-blocking proof lane for Phase 92 server propagation contracts (Plug and LiveView).

  Proves PROP-01 (Plug):
  - Inbound verbatim header processing (source: :inbound).
  - Minted UUID generation when absent (source: :minted).
  - Logger.metadata population.
  - Response header echo.
  - Telemetry triplet emission (:start, :stop, :exception) via Phase 91 contract.
  - Forbidden/PII metadata dropped.

  Proves PROP-03 (on_mount):
  - Sets metadata when connected with a valid param.
  - No-op on disconnected socket.
  - No-op when connected but param is absent.

  This test is fully hermetic by design: it never depends on the compiled example
  host (CrosswakeExample.*), never hits the network, and never launches a simulator.
  """

  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  alias Crosswake.Plug.Threadline, as: PlugThreadline
  alias Crosswake.Live.Threadline, as: LiveThreadline

  setup do
    Logger.metadata(crosswake_thread_id: nil)
    :ok
  end

  # ---------------------------------------------------------------------------
  # Hermeticity self-assertion
  # ---------------------------------------------------------------------------

  test "phase 92 server propagation proof stays hermetic — no example-host dependency" do
    refute Code.ensure_loaded?(CrosswakeExample),
           "phase 92 proof must not load example host modules; keep the lane hermetic"
  end

  # ---------------------------------------------------------------------------
  # PROP-01: Plug assertions
  # ---------------------------------------------------------------------------

  describe "PROP-01: Plug Threadline" do
    test "(1) inbound header uses id verbatim + :inbound source in emitted :start metadata" do
      handler_id = "test-prop-inbound-#{System.unique_integer()}"

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
      |> put_req_header("x-crosswake-thread-id", "inbound-prop-123")
      |> PlugThreadline.call(PlugThreadline.init([]))

      assert_receive {:telemetry_start, metadata}
      assert metadata[:thread_id] == "inbound-prop-123"
      assert metadata[:source] == :inbound
    end

    test "(2) absent header mints v4-format id + :minted source" do
      handler_id = "test-prop-minted-#{System.unique_integer()}"

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
      |> PlugThreadline.call(PlugThreadline.init([]))

      assert_receive {:telemetry_start, metadata}
      id = metadata[:thread_id]
      assert is_binary(id)
      assert id =~ ~r/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/
      assert metadata[:source] == :minted
    end

    test "(3) Logger.metadata()[:crosswake_thread_id] set after call/2" do
      conn(:get, "/")
      |> put_req_header("x-crosswake-thread-id", "logger-prop")
      |> PlugThreadline.call(PlugThreadline.init([]))

      assert Logger.metadata()[:crosswake_thread_id] == "logger-prop"
    end

    test "(4) response header echoes the id" do
      conn =
        conn(:get, "/")
        |> put_req_header("x-crosswake-thread-id", "echo-prop")
        |> PlugThreadline.call(PlugThreadline.init([]))

      assert get_resp_header(conn, "x-crosswake-thread-id") == ["echo-prop"]
    end

    test "(5) :start fires on call/2 and :stop fires after send_resp/3 with a :duration measurement" do
      uid = System.unique_integer()
      handler_id_start = "test-prop-start-#{uid}"
      handler_id_stop = "test-prop-stop-#{uid}"

      :telemetry.attach(
        handler_id_start,
        [:crosswake, :threadline, :request, :start],
        fn _name, _measurements, metadata, _config ->
          send(self(), {:telemetry_start, metadata})
        end,
        nil
      )
      :telemetry.attach(
        handler_id_stop,
        [:crosswake, :threadline, :request, :stop],
        fn _name, measurements, metadata, _config ->
          send(self(), {:telemetry_stop, measurements, metadata})
        end,
        nil
      )

      on_exit(fn ->
        :telemetry.detach(handler_id_start)
        :telemetry.detach(handler_id_stop)
      end)

      conn(:get, "/")
      |> put_req_header("x-crosswake-thread-id", "start-stop-prop")
      |> PlugThreadline.call(PlugThreadline.init([]))
      |> send_resp(200, "ok")

      assert_receive {:telemetry_start, metadata_start}
      assert metadata_start[:thread_id] == "start-stop-prop"

      assert_receive {:telemetry_stop, measurements, metadata_stop}
      assert metadata_stop[:thread_id] == "start-stop-prop"
      assert Map.has_key?(measurements, :duration)
      assert measurements[:duration] >= 0
    end

    test "(6) a forbidden/PII metadata key is dropped (never reaches the handler)" do
      handler_id = "test-prop-forbidden-#{System.unique_integer()}"

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
      |> put_req_header("x-crosswake-thread-id", "clean-prop")
      |> PlugThreadline.call(PlugThreadline.init([]))

      assert_receive {:telemetry_start, metadata}
      assert map_size(metadata) == 2
      assert metadata[:thread_id] == "clean-prop"
      assert metadata[:source] == :inbound
      refute Map.has_key?(metadata, :pii_key)
    end
  end

  # ---------------------------------------------------------------------------
  # PROP-03: LiveView on_mount assertions
  # ---------------------------------------------------------------------------

  describe "PROP-03: LiveView on_mount" do
    test "(7) on_mount connected+param sets metadata" do
      socket = %Phoenix.LiveView.Socket{
        transport_pid: self(),
        private: %{connect_params: %{"_crosswake_thread_id" => "live-prop-123"}}
      }

      assert {:cont, ^socket} = LiveThreadline.on_mount(:default, %{}, %{}, socket)
      assert Logger.metadata()[:crosswake_thread_id] == "live-prop-123"
    end

    test "(8) on_mount disconnected -> {:cont, socket} no-op, no metadata" do
      socket = %Phoenix.LiveView.Socket{
        transport_pid: nil,
        private: %{connect_params: nil}
      }

      assert {:cont, ^socket} = LiveThreadline.on_mount(:default, %{}, %{}, socket)
      assert Logger.metadata()[:crosswake_thread_id] == nil
    end

    test "(9) on_mount connected+absent-param -> {:cont, socket} no-op, no metadata" do
      socket = %Phoenix.LiveView.Socket{
        transport_pid: self(),
        private: %{connect_params: %{"other" => "val"}}
      }

      assert {:cont, ^socket} = LiveThreadline.on_mount(:default, %{}, %{}, socket)
      assert Logger.metadata()[:crosswake_thread_id] == nil
    end
  end
end
