defmodule Crosswake.ProofLane.TwinFaultBoundaryTest do
  use ExUnit.Case, async: false

  alias Crosswake.ProofLane.{TwinFaultBoundary, TwinRuntime}

  @static_body "console.log('synthetic static body');\n"

  # A raw :gen_tcp upstream. It answers every request with a fixed body, keeps
  # connections alive, and records the request lines it saw (method and target only).
  defp start_upstream do
    {:ok, listener} =
      :gen_tcp.listen(0, [:binary, ip: {127, 0, 0, 1}, active: false, reuseaddr: true])

    {:ok, port} = :inet.port(listener)
    {:ok, seen} = Agent.start_link(fn -> [] end)
    spawn_link(fn -> upstream_accept(listener, seen) end)
    on_exit(fn -> :gen_tcp.close(listener) end)
    {port, seen}
  end

  defp upstream_accept(listener, seen) do
    case :gen_tcp.accept(listener) do
      {:ok, socket} ->
        pid =
          spawn(fn ->
            receive do
              :go -> upstream_conn(socket, seen, <<>>)
            end
          end)

        :gen_tcp.controlling_process(socket, pid)
        send(pid, :go)
        upstream_accept(listener, seen)

      _ ->
        :ok
    end
  end

  defp upstream_conn(socket, seen, buffer) do
    case :binary.split(buffer, "\r\n\r\n") do
      [head, rest] ->
        [line | _] = String.split(head, "\r\n")
        [method, target | _] = String.split(line, " ")
        length = content_length(head)
        rest = read_body(socket, rest, length)
        Agent.update(seen, &(&1 ++ [{method, target}]))
        <<_body::binary-size(length), after_body::binary>> = rest
        :gen_tcp.send(socket, response_for(method, target))
        upstream_conn(socket, seen, after_body)

      _ ->
        case :gen_tcp.recv(socket, 0, 5_000) do
          {:ok, data} -> upstream_conn(socket, seen, buffer <> data)
          _ -> :gen_tcp.close(socket)
        end
    end
  end

  defp read_body(_socket, rest, length) when byte_size(rest) >= length, do: rest

  defp read_body(socket, rest, length) do
    {:ok, data} = :gen_tcp.recv(socket, 0, 5_000)
    read_body(socket, rest <> data, length)
  end

  defp content_length(head) do
    case Regex.run(~r/\r\ncontent-length:\s*(\d+)/i, head) do
      [_, v] -> String.to_integer(v)
      _ -> 0
    end
  end

  defp response_for("POST", "/_e2e/twin/fault"),
    do: "HTTP/1.1 204 No Content\r\ncontent-length: 0\r\n\r\n"

  defp response_for("GET", "/offline_study.js"),
    do:
      "HTTP/1.1 200 OK\r\ncontent-type: text/javascript\r\ncontent-length: #{byte_size(@static_body)}\r\n\r\n" <>
        @static_body

  defp response_for(_method, _target),
    do: "HTTP/1.1 200 OK\r\ncontent-length: 2\r\n\r\nok"

  defp start_boundary(snapshot \\ fn _epoch -> :ok end) do
    {upstream_port, seen} = start_upstream()

    {:ok, origin} =
      :gen_tcp.listen(0, [
        :binary,
        ip: {127, 0, 0, 1},
        active: false,
        reuseaddr: false,
        packet: :raw
      ])

    {:ok, origin_port} = :inet.port(origin)

    {:ok, boundary} =
      TwinFaultBoundary.start(
        origin_listener: origin,
        upstream_port: upstream_port,
        snapshot: snapshot
      )

    on_exit(fn -> TwinFaultBoundary.stop(boundary) end)
    %{boundary: boundary, origin_port: origin_port, upstream_port: upstream_port, seen: seen}
  end

  defp request(port, method, target, body \\ "") do
    {:ok, socket} = :gen_tcp.connect({127, 0, 0, 1}, port, [:binary, active: false])

    :ok =
      :gen_tcp.send(socket, [
        method,
        " ",
        target,
        " HTTP/1.1\r\nhost: x\r\ncontent-length: ",
        Integer.to_string(byte_size(body)),
        "\r\n\r\n",
        body
      ])

    result = recv_response(socket, <<>>)
    :gen_tcp.close(socket)
    result
  end

  defp recv_response(socket, acc) do
    case :gen_tcp.recv(socket, 0, 2_000) do
      {:ok, data} ->
        acc = acc <> data

        case :binary.split(acc, "\r\n\r\n") do
          [head, body] ->
            length = content_length(head)
            if byte_size(body) >= length, do: {:ok, acc}, else: recv_response(socket, acc)

          _ ->
            recv_response(socket, acc)
        end

      {:error, reason} ->
        if acc == <<>>, do: {:error, reason}, else: {:ok, acc}
    end
  end

  defp control(ctx, method, path) do
    request(TwinFaultBoundary.control_port(ctx.boundary), method, path)
  end

  defp status_of({:ok, raw}) do
    [_, code] = Regex.run(~r/\AHTTP\/1\.1 (\d{3})/, raw)
    String.to_integer(code)
  end

  test "start accepts an already-listening origin socket and keeps the origin bound" do
    ctx = start_boundary()
    assert {:ok, response} = request(ctx.origin_port, "GET", "/offline")
    assert String.ends_with?(response, "ok")
    # The origin port is still held by the boundary: nothing else can bind it.
    assert {:error, :eaddrinuse} =
             :gen_tcp.listen(ctx.origin_port, ip: {127, 0, 0, 1}, reuseaddr: false)
  end

  test "pass mode relays a real HTTP request and returns the upstream response unchanged" do
    ctx = start_boundary()
    assert {:ok, response} = request(ctx.origin_port, "POST", "/study/sync", "{\"events\":[]}")
    assert response == "HTTP/1.1 200 OK\r\ncontent-length: 2\r\n\r\nok"
    assert [{"POST", "/study/sync"}] = Agent.get(ctx.seen, & &1)
  end

  test "refuse mode closes without a response and counts per class and epoch" do
    ctx = start_boundary()
    assert status_of(control(ctx, "POST", "/epoch/offline")) == 200
    assert status_of(control(ctx, "POST", "/refuse")) == 200

    assert {:error, :closed} = request(ctx.origin_port, "GET", "/offline")
    assert {:error, :closed} = request(ctx.origin_port, "GET", "/offline_study.js")
    assert {:error, :closed} = request(ctx.origin_port, "GET", "/_e2e/twin/media/pronunciation")
    assert Agent.get(ctx.seen, & &1) == []

    counters = TwinFaultBoundary.counters(ctx.boundary)
    assert counters["offline"].webview_document == %{passed: 0, refused: 1}
    assert counters["offline"].webview_static == %{passed: 0, refused: 1}
    assert counters["offline"].native_media == %{passed: 0, refused: 1}

    # The origin is still bound by the boundary, and pass mode resumes serving.
    assert status_of(control(ctx, "POST", "/pass")) == 200
    assert {:ok, _} = request(ctx.origin_port, "GET", "/offline")
    assert TwinFaultBoundary.counters(ctx.boundary)["offline"].webview_document.passed == 1
  end

  test "drop_next_response drops the replay response once after upstream handled it, then passes" do
    ctx = start_boundary()
    assert status_of(control(ctx, "POST", "/drop_next_response/replay")) == 200

    assert {:error, :closed} = request(ctx.origin_port, "POST", "/study/sync", "{}")
    # Upstream did receive and handle the request (it was committed before the drop).
    assert [{"POST", "/study/sync"}] = Agent.get(ctx.seen, & &1)

    assert {:ok, response} = request(ctx.origin_port, "POST", "/study/sync", "{}")
    assert String.ends_with?(response, "ok")
    assert length(Agent.get(ctx.seen, & &1)) == 2
  end

  test "the control listener accepts only the closed command set and reports integers only" do
    ctx = start_boundary()
    assert status_of(control(ctx, "POST", "/epoch/not_an_epoch")) == 422
    assert status_of(control(ctx, "POST", "/fault/not_a_fault")) == 422
    assert status_of(control(ctx, "POST", "/drop_next_response/webview_static")) == 422
    assert status_of(control(ctx, "POST", "/shell")) == 422
    assert status_of(control(ctx, "GET", "/status")) == 200

    {:ok, raw} = control(ctx, "GET", "/status")
    [_, body] = String.split(raw, "\r\n\r\n", parts: 2)
    decoded = Jason.decode!(body)
    refute Enum.empty?(Map.values(decoded))
    assert Enum.all?(Map.values(decoded), &is_integer/1)
  end

  test "a closed fault kind is forwarded to the private upstream fault endpoint" do
    ctx = start_boundary()
    assert status_of(control(ctx, "POST", "/fault/replay_reject")) == 200
    assert status_of(control(ctx, "POST", "/fault/clear")) == 200
    seen = Agent.get(ctx.seen, & &1)
    assert Enum.count(seen, &(&1 == {"POST", "/_e2e/twin/fault"})) == 2
  end

  test "each epoch change calls the snapshot exactly once, before the new epoch counters start" do
    test_pid = self()

    snapshot = fn epoch ->
      send(test_pid, {:snapshot, epoch})
      :captured
    end

    ctx = start_boundary(snapshot)
    control(ctx, "POST", "/epoch/online_install")
    request(ctx.origin_port, "GET", "/offline")
    control(ctx, "POST", "/epoch/offline")
    assert_receive {:snapshot, "online_install"}
    refute_receive {:snapshot, _}, 100

    request(ctx.origin_port, "GET", "/offline")
    TwinFaultBoundary.finish(ctx.boundary)
    assert_receive {:snapshot, "offline"}
    refute_receive {:snapshot, _}, 100

    assert TwinFaultBoundary.snapshots(ctx.boundary) == [
             {"online_install", :captured},
             {"offline", :captured}
           ]

    counters = TwinFaultBoundary.counters(ctx.boundary)
    assert counters["online_install"].webview_document.passed == 1
    assert counters["offline"].webview_document.passed == 1
  end

  test "the boundary exposes only the SHA-256 of the offline_study.js body as served" do
    ctx = start_boundary()
    assert TwinFaultBoundary.static_digest(ctx.boundary) == nil
    assert {:ok, response} = request(ctx.origin_port, "GET", "/offline_study.js")
    assert String.ends_with?(response, @static_body)
    Process.sleep(100)

    expected = :crypto.hash(:sha256, @static_body) |> Base.encode16(case: :lower)
    assert TwinFaultBoundary.static_digest(ctx.boundary) == expected
  end

  test "paths are placed in closed classes by method and path prefix only" do
    assert TwinFaultBoundary.classify("GET", "/offline") == :webview_document
    assert TwinFaultBoundary.classify("GET", "/offline/review?x=1") == :webview_document
    assert TwinFaultBoundary.classify("GET", "/offline_study.js") == :webview_static
    assert TwinFaultBoundary.classify("GET", "/crosswake/tokens.css") == :webview_static
    assert TwinFaultBoundary.classify("GET", "/_e2e/twin/media/pronunciation") == :native_media
    assert TwinFaultBoundary.classify("POST", "/study/sync") == :replay
    assert TwinFaultBoundary.classify("GET", "/study/sync") == :other
    assert TwinFaultBoundary.classify("POST", "/_e2e/replay-session") == :other
  end

  describe "verify_upstream_owner/2" do
    defp runtime do
      {:ok, registry} = Agent.start_link(fn -> %{children: %{}, first_failure: nil} end)

      %TwinRuntime{
        run_id: "twin-0123456789abcdef",
        run_root: System.tmp_dir!(),
        database_path: Path.join(System.tmp_dir!(), "unused.sqlite3"),
        origin: "http://127.0.0.1:1",
        origin_port: 1,
        registry: registry,
        run_deadline_at: System.monotonic_time(:millisecond) + 60_000
      }
    end

    test "returns :ok only when the listener pid is the tracked child pid" do
      {:ok, listener} = :gen_tcp.listen(0, ip: {127, 0, 0, 1}, active: false)
      {:ok, port} = :inet.port(listener)
      own = String.to_integer(System.pid())

      assert :ok = TwinFaultBoundary.verify_upstream_owner(runtime(), port: port, os_pid: own)

      assert {:blocked, :backend_listener_not_owned} =
               TwinFaultBoundary.verify_upstream_owner(runtime(),
                 port: port,
                 os_pid: own + 100_000
               )

      :gen_tcp.close(listener)
    end

    test "blocks when nothing listens on the port, and never signals anything" do
      {:ok, l} = :gen_tcp.listen(0, ip: {127, 0, 0, 1})
      {:ok, port} = :inet.port(l)
      :gen_tcp.close(l)

      assert {:blocked, :backend_listener_not_owned} =
               TwinFaultBoundary.verify_upstream_owner(runtime(), port: port, os_pid: 1)
    end
  end

  test "the module never listens on the origin port and binds its control listener to loopback only" do
    source = File.read!("lib/crosswake/proof_lane/twin_fault_boundary.ex")
    listens = Regex.scan(~r/:gen_tcp\.listen\(/, source)
    assert length(listens) == 1
    assert source =~ "ip: {127, 0, 0, 1}"
  end
end
