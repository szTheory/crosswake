defmodule Crosswake.ProofLane.TwinFaultBoundary do
  @moduledoc """
  Invocation-owned loopback fault boundary for one twin run.

  The boundary takes over the origin listener that `TwinRuntime.prepare/1` already
  acquired (it never binds the origin itself, so the origin stays held from preflight to
  shutdown), forwards byte streams to the run's own Phoenix child on a private loopback
  port, and can refuse traffic at the transport level: in refuse mode an incoming request
  is read only as far as its request line and the connection is closed without any
  response. Because WebKit, URLSession and AVFoundation all reach the origin through this
  listener, the refusal is the real transport behaviour the tested app meets.

  Only the request-line method and path prefix are inspected, and only to place a request
  into one closed path class (`webview_document`, `webview_static`, `native_media`,
  `replay`, plus an uncounted-by-producers `other`). Passed and refused counts are kept
  per class per closed epoch. Bodies, headers and query values are never stored. The one
  public static digest (the SHA-256 of the `offline_study.js` body as served) is the only
  content-derived value that leaves the module.

  A second listener on an ephemeral loopback port accepts the closed control command set:
  `pass`, `refuse`, `drop_next_response/<class>`, `epoch/<name>`, `fault/<kind>` and
  `status`. Anything else is answered with 422. Each epoch change calls the injected
  snapshot callback exactly once, before the new epoch's counters start.

  This is a single-run, single-origin fault boundary owned by the invocation, not a general
  proxy service.
  """

  use GenServer

  alias Crosswake.ProofLane.TwinRuntime

  @classes [:webview_document, :webview_static, :native_media, :replay, :other]
  @epochs ~w(online_install offline playback relaunch replay offline_install media_faults
             recovery scope_fence disablement)
  @faults ~w(replay_reject replay_conflict entry_disable replay_disable media_missing
             media_corrupt clear)
  @static_path "/offline_study.js"
  @max_head 65_536
  @max_capture 4_194_304
  @idle_timeout 120_000
  @upstream_timeout 30_000

  @type epoch :: String.t()
  @type counters :: %{
          epoch() => %{atom() => %{passed: non_neg_integer(), refused: non_neg_integer()}}
        }

  # ------------------------------------------------------------------ public API

  @doc """
  Starts the boundary. Options: `:origin_listener` (an already-listening socket),
  `:upstream_port` (private Phoenix port) and `:snapshot` (a function called once per epoch
  change with the epoch that just ended; its return value is kept, never inspected).
  """
  @spec start(keyword()) :: {:ok, pid()} | {:error, term()}
  def start(opts) do
    listener = Keyword.fetch!(opts, :origin_listener)
    upstream = Keyword.fetch!(opts, :upstream_port)
    snapshot = Keyword.get(opts, :snapshot, fn _epoch -> :ok end)

    with {:ok, pid} <- GenServer.start(__MODULE__, %{upstream: upstream, snapshot: snapshot}),
         :ok <- :gen_tcp.controlling_process(listener, pid),
         {:ok, _control} <- GenServer.call(pid, {:begin, listener}) do
      {:ok, pid}
    else
      {:error, _} = error -> error
      other -> {:error, other}
    end
  end

  @spec control_port(pid()) :: pos_integer()
  def control_port(pid), do: GenServer.call(pid, :control_port)

  @doc "Per-epoch, per-class passed/refused counts only."
  @spec counters(pid()) :: counters()
  def counters(pid), do: GenServer.call(pid, :counters)

  @doc "Values the snapshot callback returned, as `[{epoch_that_ended, value}]` in order."
  @spec snapshots(pid()) :: [{epoch(), term()}]
  def snapshots(pid), do: GenServer.call(pid, :snapshots)

  @doc "Hex SHA-256 of the `offline_study.js` body as it was served through the boundary."
  @spec static_digest(pid()) :: String.t() | nil
  def static_digest(pid), do: GenServer.call(pid, :static_digest)

  @doc """
  Ends the current epoch (invoking the snapshot callback once) without starting another.
  Used once at the end of a run.
  """
  @spec finish(pid()) :: :ok
  def finish(pid), do: GenServer.call(pid, :finish, 60_000)

  @spec stop(pid()) :: :ok
  def stop(pid) do
    if Process.alive?(pid), do: GenServer.stop(pid, :normal, 5_000)
    :ok
  catch
    :exit, _ -> :ok
  end

  @doc "The closed request path classes."
  @spec classes() :: [atom()]
  def classes, do: @classes

  @doc "Closed classification used for counting; exposed for tests."
  @spec classify(String.t(), String.t()) :: atom()
  def classify(method, target) do
    path = target |> String.split("?", parts: 2) |> hd()

    cond do
      String.starts_with?(path, "/_e2e/twin/media") -> :native_media
      method == "POST" and path in ["/study/sync", "/learnloop/sync"] -> :replay
      path in ["/offline", "/offline/review", "/"] -> :webview_document
      String.starts_with?(path, ["/crosswake/", "/assets/"]) -> :webview_static
      Regex.match?(~r/\.(js|css|svg|png|ico|woff2?|map)\z/, path) -> :webview_static
      true -> :other
    end
  end

  @doc """
  Read-only check that the private upstream listener belongs to the run's own Phoenix
  child. Returns `:ok` only when the listener PID reported by a read-only `lsof` child is
  the tracked child PID (or a member of the process group that child leads). Never signals
  anything.
  """
  @spec verify_upstream_owner(TwinRuntime.t(), keyword()) ::
          :ok | {:blocked, :backend_listener_not_owned}
  def verify_upstream_owner(runtime, opts) do
    port = Keyword.fetch!(opts, :port)
    os_pid = Keyword.fetch!(opts, :os_pid)
    lsof = System.find_executable("lsof")

    with true <- is_binary(lsof),
         {:ok, output} <-
           run_readonly(runtime, :lsof_owner, lsof, [
             "-nP",
             "-iTCP:#{port}",
             "-sTCP:LISTEN",
             "-Fp"
           ]),
         [_ | _] = pids <- listener_pids(output),
         true <- Enum.all?(pids, &owned?(&1, os_pid)) do
      :ok
    else
      _ -> {:blocked, :backend_listener_not_owned}
    end
  end

  @doc """
  One bounded HTTP request to the private upstream (never through the origin). Returns
  `{:ok, status, body}`; bodies are returned to the caller only, never stored here.
  """
  @spec upstream_request(pos_integer(), String.t(), String.t(), binary()) ::
          {:ok, non_neg_integer(), binary()} | {:error, term()}
  def upstream_request(port, method, path, body \\ "") do
    request =
      [
        method,
        " ",
        path,
        " HTTP/1.1\r\nhost: 127.0.0.1\r\naccept: application/json\r\n",
        "content-type: application/json\r\ncontent-length: ",
        Integer.to_string(byte_size(body)),
        "\r\nconnection: close\r\n\r\n",
        body
      ]
      |> IO.iodata_to_binary()

    with {:ok, socket} <-
           :gen_tcp.connect({127, 0, 0, 1}, port, [:binary, active: false], 5_000),
         :ok <- :gen_tcp.send(socket, request),
         {:ok, raw} <- recv_all(socket, <<>>, 4_194_304),
         _ = :gen_tcp.close(socket) do
      parse_response(raw)
    end
  end

  # ------------------------------------------------------------------ GenServer

  @impl true
  def init(%{upstream: upstream, snapshot: snapshot}) do
    {:ok,
     %{
       upstream: upstream,
       snapshot: snapshot,
       mode: :pass,
       drop: nil,
       epoch: nil,
       counters: %{},
       snapshots: [],
       static_digest: nil,
       listener: nil,
       control: nil,
       control_port: nil
     }}
  end

  @impl true
  def handle_call({:begin, listener}, _from, state) do
    {:ok, control} =
      :gen_tcp.listen(0, [
        :binary,
        ip: {127, 0, 0, 1},
        active: false,
        reuseaddr: true,
        packet: :raw
      ])

    {:ok, control_port} = :inet.port(control)
    boundary = self()

    spawn_link(fn ->
      accept_loop(listener, fn socket -> serve(socket, boundary, state.upstream) end)
    end)

    spawn_link(fn ->
      accept_loop(control, fn socket -> control_serve(socket, boundary, state.upstream) end)
    end)

    {:reply, {:ok, control_port},
     %{state | listener: listener, control: control, control_port: control_port}}
  end

  def handle_call(:control_port, _from, state), do: {:reply, state.control_port, state}
  def handle_call(:counters, _from, state), do: {:reply, state.counters, state}
  def handle_call(:snapshots, _from, state), do: {:reply, Enum.reverse(state.snapshots), state}
  def handle_call(:static_digest, _from, state), do: {:reply, state.static_digest, state}

  def handle_call({:route, class}, _from, state) do
    {action, state} =
      cond do
        state.mode == :refuse ->
          {:refuse, bump(state, class, :refused)}

        state.drop == class ->
          {:drop, bump(%{state | drop: nil}, class, :passed)}

        true ->
          {:pass, bump(state, class, :passed)}
      end

    {:reply, action, state}
  end

  def handle_call({:static_digest, digest}, _from, state),
    do: {:reply, :ok, %{state | static_digest: state.static_digest || digest}}

  def handle_call({:command, :pass}, _from, state),
    do: {:reply, {:ok, %{mode: 0}}, %{state | mode: :pass}}

  def handle_call({:command, :refuse}, _from, state),
    do: {:reply, {:ok, %{mode: 1}}, %{state | mode: :refuse}}

  def handle_call({:command, {:drop, class}}, _from, state),
    do: {:reply, {:ok, %{drop_armed: 1}}, %{state | drop: class}}

  def handle_call({:command, {:epoch, name}}, _from, state) do
    {:reply, {:ok, %{epoch: epoch_index(name)}}, change_epoch(state, name)}
  end

  def handle_call({:command, :status}, _from, state) do
    {:reply,
     {:ok,
      %{
        mode: if(state.mode == :refuse, do: 1, else: 0),
        drop_armed: if(state.drop, do: 1, else: 0),
        epoch: if(state.epoch, do: epoch_index(state.epoch), else: -1)
      }}, state}
  end

  def handle_call(:finish, _from, state) do
    {:reply, :ok, change_epoch(state, nil)}
  end

  @impl true
  def terminate(_reason, state) do
    for socket <- [state.listener, state.control], socket != nil, do: :gen_tcp.close(socket)
    :ok
  end

  # ------------------------------------------------------------------ state helpers

  defp bump(state, class, key) do
    epoch = state.epoch || "none"

    counters =
      update_in(
        state.counters,
        [Access.key(epoch, %{}), Access.key(class, %{passed: 0, refused: 0})],
        fn counts -> Map.update!(counts, key, &(&1 + 1)) end
      )

    %{state | counters: counters}
  end

  # Exactly one snapshot call per epoch change, before the new epoch's counters start.
  defp change_epoch(state, next) do
    ended = state.epoch
    value = if ended, do: safe_snapshot(state.snapshot, ended), else: nil
    snapshots = if ended, do: [{ended, value} | state.snapshots], else: state.snapshots
    %{state | epoch: next, snapshots: snapshots}
  end

  defp safe_snapshot(fun, epoch) do
    fun.(epoch)
  rescue
    _ -> :snapshot_failed
  catch
    _, _ -> :snapshot_failed
  end

  defp epoch_index(name), do: Enum.find_index(@epochs, &(&1 == name))

  # ------------------------------------------------------------------ origin traffic

  defp accept_loop(listener, handler) do
    case :gen_tcp.accept(listener) do
      {:ok, socket} ->
        pid =
          spawn(fn ->
            receive do
              :go -> handler.(socket)
            end
          end)

        :ok = :gen_tcp.controlling_process(socket, pid)
        send(pid, :go)
        accept_loop(listener, handler)

      {:error, _closed} ->
        :ok
    end
  end

  defp serve(client, boundary, upstream_port) do
    loop(client, boundary, upstream_port, nil, <<>>)
  end

  defp loop(client, boundary, upstream_port, upstream, buffer) do
    case read_head(client, buffer) do
      {:ok, head, rest} ->
        {method, target} = request_line(head)
        class = classify(method, target)

        case GenServer.call(boundary, {:route, class}) do
          :refuse ->
            close_both(client, upstream)

          action ->
            forward(
              action,
              client,
              boundary,
              upstream_port,
              upstream,
              {method, target, class},
              head,
              rest
            )
        end

      _closed ->
        close_both(client, upstream)
    end
  end

  defp forward(
         action,
         client,
         boundary,
         upstream_port,
         upstream,
         {method, target, class},
         head,
         rest
       ) do
    with {:ok, upstream} <- ensure_upstream(upstream, upstream_port),
         {:ok, body_rest} <- relay_request(client, upstream, head, rest, content_length(head)) do
      pump = ensure_pump(upstream, client)

      if action == :drop do
        # Phoenix handles the request; the pump drops the first response bytes it sees.
        send(pump, {:drop, self()})

        receive do
          :dropped -> :ok
        after
          @upstream_timeout -> close_both(client, upstream)
        end
      else
        maybe_capture(pump, boundary, method, target, class)
        loop(client, boundary, upstream_port, upstream, body_rest)
      end
    else
      _ -> close_both(client, upstream)
    end
  end

  defp ensure_upstream(nil, port) do
    :gen_tcp.connect({127, 0, 0, 1}, port, [:binary, active: false, packet: :raw], 5_000)
  end

  defp ensure_upstream(socket, _port), do: {:ok, socket}

  # Forward head and body bytes unchanged; returns the bytes already read past this request.
  defp relay_request(client, upstream, head, rest, length) do
    have = min(byte_size(rest), length)
    <<body::binary-size(have), after_body::binary>> = rest

    with :ok <- :gen_tcp.send(upstream, [head, body]),
         :ok <- relay_remaining(client, upstream, length - have) do
      {:ok, after_body}
    end
  end

  defp relay_remaining(_client, _upstream, 0), do: :ok

  defp relay_remaining(client, upstream, left) when left > 0 do
    with {:ok, data} <- :gen_tcp.recv(client, 0, @idle_timeout),
         take = min(byte_size(data), left),
         <<chunk::binary-size(take), _extra::binary>> = data,
         :ok <- :gen_tcp.send(upstream, chunk) do
      relay_remaining(client, upstream, left - take)
    end
  end

  # One pump per upstream connection copies response bytes to the client unchanged.
  defp ensure_pump(upstream, client) do
    key = {:pump, upstream}

    case Process.get(key) do
      nil ->
        parent = self()
        pid = spawn(fn -> pump(upstream, client, parent, nil) end)
        Process.put(key, pid)
        pid

      pid ->
        pid
    end
  end

  defp pump(upstream, client, parent, capture) do
    case :gen_tcp.recv(upstream, 0, :infinity) do
      {:ok, data} ->
        receive do
          {:drop, handler} ->
            :gen_tcp.close(upstream)
            :gen_tcp.close(client)
            send(handler, :dropped)
            exit(:normal)
        after
          0 -> :ok
        end

        capture = receive_capture(capture)
        capture = feed_capture(capture, data)
        _ = :gen_tcp.send(client, data)
        pump(upstream, client, parent, capture)

      {:error, _} ->
        :gen_tcp.close(client)

        receive do
          {:drop, handler} -> send(handler, :dropped)
        after
          0 -> :ok
        end
    end
  end

  defp maybe_capture(pump, boundary, "GET", target, _class) do
    if target |> String.split("?", parts: 2) |> hd() == @static_path,
      do: send(pump, {:capture, boundary})

    :ok
  end

  defp maybe_capture(_pump, _boundary, _method, _target, _class), do: :ok

  defp receive_capture(capture) do
    receive do
      {:capture, boundary} -> %{boundary: boundary, buffer: <<>>}
    after
      0 -> capture
    end
  end

  defp feed_capture(nil, _data), do: nil

  defp feed_capture(%{buffer: buffer} = capture, data) do
    buffer = buffer <> data

    cond do
      byte_size(buffer) > @max_capture ->
        nil

      true ->
        case split_head(buffer) do
          {:ok, head, body} ->
            case static_body_length(head) do
              {:ok, length} when byte_size(body) >= length ->
                <<served::binary-size(length), _::binary>> = body
                digest = :crypto.hash(:sha256, served) |> Base.encode16(case: :lower)
                GenServer.call(capture.boundary, {:static_digest, digest})
                nil

              {:ok, _length} ->
                %{capture | buffer: buffer}

              :unavailable ->
                nil
            end

          :partial ->
            %{capture | buffer: buffer}
        end
    end
  end

  defp split_head(buffer) do
    case :binary.split(buffer, "\r\n\r\n") do
      [head, body] -> {:ok, head, body}
      _ -> :partial
    end
  end

  defp static_body_length(head) do
    lower = String.downcase(head)

    cond do
      not String.starts_with?(lower, "http/1.1 200") and
          not String.starts_with?(lower, "http/1.0 200") ->
        :unavailable

      String.contains?(lower, "\r\ntransfer-encoding:") or
          String.contains?(lower, "\r\ncontent-encoding:") ->
        :unavailable

      true ->
        case Regex.run(~r/\r\ncontent-length:\s*(\d+)/, lower) do
          [_, value] -> {:ok, String.to_integer(value)}
          _ -> :unavailable
        end
    end
  end

  defp read_head(socket, buffer) do
    case :binary.split(buffer, "\r\n\r\n") do
      [head, rest] ->
        {:ok, head <> "\r\n\r\n", rest}

      _ when byte_size(buffer) > @max_head ->
        {:error, :too_large}

      _ ->
        case :gen_tcp.recv(socket, 0, @idle_timeout) do
          {:ok, data} -> read_head(socket, buffer <> data)
          {:error, reason} -> {:error, reason}
        end
    end
  end

  defp request_line(head) do
    case head |> String.split("\r\n", parts: 2) |> hd() |> String.split(" ") do
      [method, target | _] -> {method, target}
      _ -> {"", ""}
    end
  end

  defp content_length(head) do
    case Regex.run(~r/\r\ncontent-length:\s*(\d+)/i, head) do
      [_, value] -> String.to_integer(value)
      _ -> 0
    end
  end

  defp close_both(client, upstream) do
    if upstream, do: :gen_tcp.close(upstream)
    :gen_tcp.close(client)
    :ok
  end

  # ------------------------------------------------------------------ control listener

  defp control_serve(socket, boundary, upstream_port) do
    {status, payload} =
      case read_head(socket, <<>>) do
        {:ok, head, _rest} ->
          {method, target} = request_line(head)
          run_control(method, target, boundary, upstream_port)

        _ ->
          {422, %{error: "invalid_command"}}
      end

    body = Jason.encode!(payload)
    reason = if status == 200, do: "OK", else: "Unprocessable Entity"

    :gen_tcp.send(socket, [
      "HTTP/1.1 ",
      Integer.to_string(status),
      " ",
      reason,
      "\r\ncontent-type: application/json\r\ncontent-length: ",
      Integer.to_string(byte_size(body)),
      "\r\nconnection: close\r\n\r\n",
      body
    ])

    :gen_tcp.close(socket)
  end

  defp run_control(method, target, boundary, upstream_port) do
    path = target |> String.split("?", parts: 2) |> hd()

    case {method, String.split(path, "/", trim: true)} do
      {"POST", ["pass"]} -> command(boundary, :pass)
      {"POST", ["refuse"]} -> command(boundary, :refuse)
      {"GET", ["status"]} -> command(boundary, :status)
      {"POST", ["drop_next_response", "replay"]} -> command(boundary, {:drop, :replay})
      {"POST", ["epoch", name]} when name in @epochs -> command(boundary, {:epoch, name})
      {"POST", ["fault", kind]} when kind in @faults -> fault(kind, upstream_port)
      _ -> {422, %{error: "invalid_command"}}
    end
  end

  defp command(boundary, command) do
    case GenServer.call(boundary, {:command, command}, 60_000) do
      {:ok, map} -> {200, map}
      _ -> {422, %{error: "invalid_command"}}
    end
  end

  defp fault(kind, upstream_port) do
    case upstream_request(upstream_port, "POST", "/_e2e/twin/fault", Jason.encode!(%{kind: kind})) do
      {:ok, status, _body} when status in 200..299 -> {200, %{fault: 1}}
      _ -> {422, %{error: "fault_not_prepared"}}
    end
  end

  # ------------------------------------------------------------------ upstream client

  # Reads one response: by content-length when present, to the final chunk when chunked,
  # otherwise until the peer closes.
  defp recv_all(socket, acc, max) do
    if response_complete?(acc) do
      {:ok, acc}
    else
      case :gen_tcp.recv(socket, 0, @upstream_timeout) do
        {:ok, data} when byte_size(acc) + byte_size(data) <= max ->
          recv_all(socket, acc <> data, max)

        {:ok, _} ->
          {:error, :too_large}

        {:error, :closed} ->
          {:ok, acc}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp response_complete?(acc) do
    case :binary.split(acc, "\r\n\r\n") do
      [head, body] ->
        cond do
          match = Regex.run(~r/\r\ncontent-length:\s*(\d+)/i, head) ->
            byte_size(body) >= String.to_integer(Enum.at(match, 1))

          Regex.match?(~r/\r\ntransfer-encoding:\s*chunked/i, head) ->
            String.ends_with?(body, "0\r\n\r\n")

          true ->
            false
        end

      _ ->
        false
    end
  end

  defp parse_response(raw) do
    with [head, body] <- :binary.split(raw, "\r\n\r\n"),
         [_, code] <- Regex.run(~r/\AHTTP\/1\.[01] (\d{3})/, head) do
      body =
        if Regex.match?(~r/\r\ntransfer-encoding:\s*chunked/i, head),
          do: dechunk(body, <<>>),
          else: body

      {:ok, String.to_integer(code), body}
    else
      _ -> {:error, :bad_response}
    end
  end

  defp dechunk(data, acc) do
    case :binary.split(data, "\r\n") do
      [size_line, rest] ->
        case Integer.parse(size_line, 16) do
          {0, _} ->
            acc

          {size, _} when byte_size(rest) >= size ->
            <<chunk::binary-size(size), "\r\n", tail::binary>> = rest
            dechunk(tail, acc <> chunk)

          _ ->
            acc
        end

      _ ->
        acc
    end
  end

  # ------------------------------------------------------------------ ownership check

  defp run_readonly(runtime, name, path, args) do
    case TwinRuntime.start_child(runtime, name, %{path: path, args: args, deadline_ms: 10_000}) do
      {:ok, child} -> collect(child.port, <<>>, System.monotonic_time(:millisecond) + 10_000)
      {:error, _} -> :error
    end
  end

  defp collect(port, acc, deadline) do
    wait = max(deadline - System.monotonic_time(:millisecond), 0)

    receive do
      {^port, {:data, data}} -> collect(port, acc <> data, deadline)
      {^port, {:exit_status, _}} -> {:ok, acc}
    after
      wait -> :error
    end
  end

  defp listener_pids(output) do
    for "p" <> digits <- String.split(output, "\n", trim: true),
        {pid, ""} <- [Integer.parse(digits)],
        do: pid
  end

  defp owned?(pid, os_pid) when pid == os_pid, do: true

  defp owned?(pid, os_pid) do
    case System.cmd("/bin/ps", ["-o", "pgid=", "-p", Integer.to_string(pid)],
           stderr_to_stdout: true
         ) do
      {out, 0} -> String.trim(out) == Integer.to_string(os_pid)
      _ -> false
    end
  end
end
