defmodule Crosswake.Bridge.NotMountedError do
  @moduledoc """
  Raised by `Crosswake.Bridge.push/3` when called on a socket that never called
  `Crosswake.Bridge.attach/1` (directly or via `on_mount: Crosswake.Bridge`). Crosswake
  never guesses a route id — a missing attach call is a distinct, named, install-time
  failure surface rather than a silent no-op.

  Defined at the top level (not nested inside `Crosswake.Bridge`) so this module's own
  name is exactly `Crosswake.Bridge.NotMountedError` — nesting a `defmodule
  Crosswake.Bridge.NotMountedError` block inside `defmodule Crosswake.Bridge` would
  concatenate to `Crosswake.Bridge.Crosswake.Bridge.NotMountedError` instead.
  """
  defexception [:message]
end

defmodule Crosswake.Bridge.UndeclaredCapabilityError do
  @moduledoc """
  Raised by `Crosswake.Bridge.push/3` when a route's policy never declared the
  requested capability family. This is an outbound preflight failure (D-04): nothing
  has reached the wire and no shell has been asked, so there is no shell fact for a
  `Crosswake.Shell.Denial` to honestly report (D-06). It raises unconditionally, in
  every environment including `:prod` (D-05) — the message names the route id, the
  missing family, what IS currently declared, the calling LiveView module, the router
  location (best-effort), and the literal capabilities line to add.

  Defined at the top level for the same reason as `Crosswake.Bridge.NotMountedError`
  above — nesting would double the module prefix.
  """
  defexception [:message]
end

defmodule Crosswake.Bridge do
  @moduledoc """
  The typed control-contract seam every future native-controls pack rides on.

  A LiveView that has attached the bridge (`attach/1`, or `on_mount: Crosswake.Bridge`)
  can call `push/3` for a route-declared capability family and receive a correlated,
  typed `Crosswake.Bridge.Reply` in its own `handle_info/2` — never stringly-typed wire
  JSON. There is no configuration in which `push/3` resolves to silence: no shell, an
  unwired hook, and a shell refusal each deliver exactly one typed reply, collapsed onto
  the single `Crosswake.Shell.Denial` shape at `status`, distinguished only at `reason`
  (CTRL-01, CTRL-02).

  ## Ship no availability predicate

  This module deliberately does NOT ship `available?/2` or `connected?/1`. A pre-check
  invites `if available?, do: push, else: fallback` — a three-way branch by the back
  door that reintroduces exactly the branching CTRL-02 exists to collapse. Expo shipped
  exactly this footgun: its `isAvailableAsync` returns `true` on browsers where the
  feature does not actually work. `push/3` is the only entry point; it always resolves
  to a typed reply.

  ## Attaching

  `attach/1` requires `:crosswake_manifest` (a compiled `Crosswake.Manifest.Types.Root.t()`)
  and `:crosswake_route_id` to already be assigned on the socket — Crosswake never
  guesses a route id. Assign both, then call `attach/1` (or use `on_mount: Crosswake.Bridge`
  after another `on_mount` hook has assigned them):

      def mount(_params, _session, socket) do
        socket =
          socket
          |> assign(crosswake_manifest: MyApp.manifest(), crosswake_route_id: "my-route")
          |> Crosswake.Bridge.attach()

        {:ok, socket}
      end

  Calling `push/3` on a socket that never attached raises `Crosswake.Bridge.NotMountedError`.
  """

  alias Crosswake.Bridge.Contract
  alias Crosswake.Bridge.NotMountedError
  alias Crosswake.Bridge.Registry
  alias Crosswake.Bridge.Reply
  alias Crosswake.Bridge.UndeclaredCapabilityError
  alias Crosswake.Policy.RouterMetadata
  alias Crosswake.Shell.Denial

  @private_key :crosswake_bridge
  @timer_hook_id :crosswake_bridge_timer

  @dispatch_event "crosswake:bridge"
  @ack_event "crosswake:bridge_ack"
  @reply_event "crosswake:bridge_reply"
  @unreachable_event "crosswake:bridge_unreachable"

  @ack_deadline_tag :crosswake_bridge_ack_deadline
  @default_ack_deadline_ms 2_000

  @failing_moments ~w(no_transport reply_timeout transport_error hook_not_wired)a

  @doc """
  Attaches the bridge to a mounted LiveView socket.

  Requires `:crosswake_manifest` and `:crosswake_route_id` to already be assigned.
  Registers the reserved-event interceptor (`handle_event`) and the server-armed
  wiring-deadline interceptor (`handle_info`) — both halt on Crosswake's own reserved
  messages and `{:cont, socket}` on everything else, so unrelated events and messages
  reach the LiveView's own callbacks unchanged.
  """
  @spec attach(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def attach(%Phoenix.LiveView.Socket{} = socket) do
    manifest = required_assign!(socket, :crosswake_manifest)
    route_id = required_assign!(socket, :crosswake_route_id)

    socket
    |> Phoenix.LiveView.put_private(@private_key, %{
      manifest: manifest,
      route_id: route_id,
      in_flight: %{}
    })
    |> Phoenix.LiveView.attach_hook(@private_key, :handle_event, &handle_bridge_event/3)
    |> Phoenix.LiveView.attach_hook(@timer_hook_id, :handle_info, &handle_bridge_info/2)
  end

  @doc """
  `on_mount` callback delegating to `attach/1`, for `live_session ..., on_mount: Crosswake.Bridge`.

  Must run AFTER whatever `on_mount` hook assigns `:crosswake_manifest` and
  `:crosswake_route_id` — `on_mount` hooks in a `live_session` run in declared order.
  """
  @spec on_mount(atom(), map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:cont, Phoenix.LiveView.Socket.t()}
  def on_mount(_name, _params, _session, %Phoenix.LiveView.Socket{} = socket) do
    {:cont, attach(socket)}
  end

  @doc """
  Dispatches a bounded capability to the native shell and arms the correlation +
  wiring-deadline machinery. Returns the socket immediately (chainable, mirroring
  `Phoenix.LiveView.stream_insert/3`'s "a chainable socket-to-socket function may
  raise" precedent) — the reply always arrives later via `handle_info/2` as
  `{:crosswake_bridge, ref, %Crosswake.Bridge.Reply{}}`.

  ## Options

    * `:ref` — an opaque routing handle echoed back on delivery. Omit it for a
      fire-and-forget push (e.g. haptics) — no reply is delivered to `handle_info/2`
      in that case, matching the "no ref, no reply clause needed" shape.
    * `:payload` — the command payload map. Defaults to `%{}`.

  Raises `Crosswake.Bridge.NotMountedError` if the socket never attached, and
  `Crosswake.Bridge.UndeclaredCapabilityError` if the route never declared
  `capability_family` (unconditionally, in every environment).
  """
  @spec push(Phoenix.LiveView.Socket.t(), String.t(), keyword()) :: Phoenix.LiveView.Socket.t()
  def push(%Phoenix.LiveView.Socket{} = socket, capability_family, opts \\ [])
      when is_binary(capability_family) and is_list(opts) do
    state = fetch_state!(socket)

    case Registry.capability_command(capability_family) do
      nil ->
        raise_undeclared_capability!(state, socket, capability_family)

      command ->
        case Registry.lookup(state.manifest, state.route_id, command) do
          {:ok, entry} ->
            dispatch(socket, state, entry, command, capability_family, opts)

          {:error, :undeclared_capability} ->
            raise_undeclared_capability!(state, socket, capability_family)

          {:error, :inactive_route} ->
            raise ArgumentError, """
            [crosswake.bridge.inactive_route] route #{inspect(state.route_id)} is not an \
            active route in the compiled manifest. Confirm the route id assigned via \
            :crosswake_route_id matches a route declared in the router, and that the \
            manifest passed to Crosswake.Bridge.attach/1 was compiled from that same router.
            """

          {:error, :unsupported_command} ->
            raise ArgumentError, """
            [crosswake.bridge.unsupported_command] #{inspect(command)} is not a command in \
            the bounded bridge command vocabulary (Crosswake.Bridge.Contract.commands/0).
            """
        end
    end
  end

  # ---------------------------------------------------------------------------
  # Dispatch
  # ---------------------------------------------------------------------------

  defp dispatch(socket, state, entry, command, capability_family, opts) do
    ref = Keyword.get(opts, :ref)
    payload = Keyword.get(opts, :payload, %{})
    correlation_id = generate_correlation_id()

    request =
      Contract.new_request(
        command: command,
        capability: capability_family,
        route_id: entry.route_id,
        active_route_id: entry.route_id,
        origin: List.first(entry.allowlisted_origins) || "",
        native_runtime_version: "1.0.0",
        correlation_id: correlation_id,
        payload: payload
      )

    Process.send_after(self(), {@ack_deadline_tag, correlation_id}, ack_deadline_ms())

    new_state = track_in_flight(state, correlation_id, ref)

    socket
    |> put_state(new_state)
    |> Phoenix.LiveView.push_event(@dispatch_event, Contract.to_map(request))
  end

  # ---------------------------------------------------------------------------
  # Reserved client-event interception (D-18)
  # ---------------------------------------------------------------------------

  defp handle_bridge_event(@ack_event, payload, socket) do
    {:halt, mark_acked(socket, correlation_id_from(payload))}
  end

  defp handle_bridge_event(@reply_event, payload, socket) do
    {:halt,
     resolve_and_deliver(socket, correlation_id_from(payload), fn -> decode_wire_reply(payload) end)}
  end

  defp handle_bridge_event(@unreachable_event, payload, socket) do
    moment = normalize_failing_moment(Map.get(payload, "moment"))

    {:halt,
     resolve_and_deliver(socket, correlation_id_from(payload), fn ->
       %Reply{
         status: :deny,
         denial:
           Denial.new(
             reason: :shell_unreachable,
             code: "shell_unreachable",
             message: "The bridge hook reported it could not reach a native transport.",
             details: %{failing_moment: moment}
           )
       }
     end)}
  end

  defp handle_bridge_event(_event, _payload, socket), do: {:cont, socket}

  # ---------------------------------------------------------------------------
  # Server-armed wiring-deadline interception (D-36)
  # ---------------------------------------------------------------------------

  defp handle_bridge_info({@ack_deadline_tag, correlation_id}, socket) do
    state = fetch_state!(socket)

    socket =
      case Map.fetch(state.in_flight, correlation_id) do
        {:ok, %{acked: false}} ->
          resolve_and_deliver(socket, correlation_id, fn ->
            %Reply{
              status: :deny,
              denial:
                Denial.new(
                  reason: :shell_unreachable,
                  code: "shell_unreachable",
                  message:
                    "No acknowledgement arrived from the bridge hook before the wiring deadline.",
                  details: %{failing_moment: :hook_not_wired}
                )
            }
          end)

        _already_acked_or_resolved ->
          socket
      end

    {:halt, socket}
  end

  defp handle_bridge_info(_msg, socket), do: {:cont, socket}

  # ---------------------------------------------------------------------------
  # In-flight bookkeeping
  # ---------------------------------------------------------------------------

  defp track_in_flight(state, correlation_id, ref) do
    %{state | in_flight: Map.put(state.in_flight, correlation_id, %{ref: ref, acked: false})}
  end

  defp mark_acked(socket, nil), do: socket

  defp mark_acked(socket, correlation_id) do
    state = fetch_state!(socket)

    case Map.fetch(state.in_flight, correlation_id) do
      {:ok, entry} ->
        new_in_flight = Map.put(state.in_flight, correlation_id, %{entry | acked: true})
        put_state(socket, %{state | in_flight: new_in_flight})

      :error ->
        socket
    end
  end

  # Exactly-once delivery for the reachable paths in this plan: a correlation id is
  # removed from the in-flight map the first time ANY terminal event resolves it (a
  # real reply, an unreachable fact, or the ack-deadline firing) — a second event for
  # the same id finds nothing and is dropped, never delivered twice.
  defp resolve_and_deliver(socket, nil, _build_reply), do: socket

  defp resolve_and_deliver(socket, correlation_id, build_reply) do
    state = fetch_state!(socket)

    case Map.pop(state.in_flight, correlation_id) do
      {nil, _in_flight} ->
        socket

      {%{ref: ref}, in_flight} ->
        socket = put_state(socket, %{state | in_flight: in_flight})

        # No `ref:` means the adopter opted for fire-and-forget (e.g. haptics) — Crosswake
        # consumes the reply and delivers nothing to handle_info/2 (D-21).
        if ref != nil do
          send(self(), {:crosswake_bridge, ref, build_reply.()})
        end

        socket
    end
  end

  defp put_state(socket, state), do: Phoenix.LiveView.put_private(socket, @private_key, state)

  defp fetch_state!(socket) do
    case socket.private[@private_key] do
      nil ->
        raise NotMountedError,
          message: """
          [crosswake.bridge.not_mounted] #{inspect(socket.view)} called Crosswake.Bridge.push/3 \
          without ever calling Crosswake.Bridge.attach/1.

          Call `Crosswake.Bridge.attach(socket)` in mount/3 (after assigning \
          :crosswake_manifest and :crosswake_route_id), or add `on_mount: Crosswake.Bridge` \
          to the LiveView's live_session, before calling push/3. Crosswake never guesses a \
          route id.
          """

      state ->
        state
    end
  end

  defp required_assign!(socket, key) do
    case socket.assigns[key] do
      nil ->
        raise ArgumentError, """
        [crosswake.bridge.missing_assign] Crosswake.Bridge.attach/1 requires :#{key} to \
        already be assigned on the socket. Assign it in mount/3 (directly, or via a prior \
        on_mount hook) before calling attach/1 — Crosswake.Bridge never guesses a route id \
        or a manifest.
        """

      value ->
        value
    end
  end

  # ---------------------------------------------------------------------------
  # The loud outbound preflight (CTRL-03, D-05..D-10)
  # ---------------------------------------------------------------------------

  defp raise_undeclared_capability!(state, socket, capability_family) do
    route = Map.get(state.manifest.routes, state.route_id)
    declared = (route && route.capabilities) || []
    {router_file, router_line} = router_location(socket, state.route_id)
    fix_line = "capabilities: #{inspect(Enum.uniq(declared ++ [capability_family]))}"

    message = """
    [crosswake.bridge.undeclared_capability] route #{inspect(state.route_id)} never \
    declared the #{inspect(capability_family)} capability family.

    Currently declared on this route: #{inspect(declared)}
    LiveView module: #{inspect(socket.view)}
    Router location: #{router_file}#{router_line}

    Add the family to this route's declaration:

        #{fix_line}

    This raised instead of returning a Crosswake.Shell.Denial because a route policy \
    that never declared this capability is a server-authoring bug, not a fact about the \
    shell — no request reached the wire and no shell was ever asked, so there is nothing \
    here for a denial to honestly report.
    """

    raise UndeclaredCapabilityError, message: message
  end

  # `Phoenix.Router.routes/1` (== `router.__routes__/0`) deliberately strips `:line`
  # from its public route summary (`Phoenix.Router`'s own `Map.take(&1, [:verb, :path,
  # :plug, :plug_opts, :helper, :metadata])` — verified by direct read) — the compiled
  # route line is a compile-time-only detail, not part of the public runtime API. The
  # file IS resolvable (`router.module_info(:compile)[:source]`); the line is
  # recovered best-effort by grepping that file's text for the route id literal —
  # advisory, never authoritative, mirroring doctor's own host-file-grep precedent
  # (`phase_66_generator_drift_findings/3`, D-37).
  defp router_location(socket, route_id) do
    with router when not is_nil(router) <- Map.get(socket, :router),
         true <- find_router_route(router, route_id) != nil do
      file = router_source_file(router)
      {file, best_effort_line_suffix(file, route_id)}
    else
      _ -> {"(router location unavailable — pass a mounted socket with a resolvable router)", ""}
    end
  end

  defp find_router_route(router, route_id) do
    router
    |> Phoenix.Router.routes()
    |> Enum.find(fn route ->
      case RouterMetadata.fetch(route.metadata) do
        {:ok, %{id: ^route_id}} -> true
        _other -> false
      end
    end)
  rescue
    _ -> nil
  end

  defp router_source_file(router) do
    case router.module_info(:compile)[:source] do
      nil -> "(unknown file)"
      source -> to_string(source)
    end
  rescue
    _ -> "(unknown file)"
  end

  defp best_effort_line_suffix(file, route_id) do
    needle = "id: #{inspect(route_id)}"

    file
    |> File.read!()
    |> String.split("\n")
    |> Enum.find_index(&String.contains?(&1, needle))
    |> case do
      nil -> ""
      index -> ":#{index + 1}"
    end
  rescue
    _ -> ""
  end

  # ---------------------------------------------------------------------------
  # Wire reply decoding (CTRL-02, D-16, D-28)
  # ---------------------------------------------------------------------------

  defp decode_wire_reply(%{"status" => "ok"} = wire_reply) do
    %Reply{
      status: :ok,
      command: Map.get(wire_reply, "command"),
      route_id: Map.get(wire_reply, "route_id"),
      payload: Map.get(wire_reply, "payload") || %{}
    }
  end

  defp decode_wire_reply(%{"status" => "deny"} = wire_reply) do
    %Reply{
      status: :deny,
      command: Map.get(wire_reply, "command"),
      route_id: Map.get(wire_reply, "route_id"),
      denial: decode_wire_denial(Map.get(wire_reply, "denial"))
    }
  end

  defp decode_wire_reply(wire_reply) do
    %Reply{
      status: :deny,
      command: Map.get(wire_reply, "command"),
      route_id: Map.get(wire_reply, "route_id"),
      denial:
        Denial.new(
          reason: :unavailable_capability,
          code: "unavailable_capability",
          message: "The shell sent a reply with an unrecognized status.",
          details: %{raw_status: Map.get(wire_reply, "status")}
        )
    }
  end

  # `Crosswake.Bridge.Denial.to_map/1` nests the shell denial map under a SECOND
  # "denial" key (the documented double nest, D-28) — flatten it here, in the Elixir
  # decoder only. The wire shape itself is unchanged on the way out.
  defp decode_wire_denial(%{"denial" => inner_denial}) when is_map(inner_denial) do
    build_denial_from_wire(inner_denial)
  end

  defp decode_wire_denial(wire_denial) when is_map(wire_denial) do
    build_denial_from_wire(wire_denial)
  end

  defp decode_wire_denial(_other) do
    Denial.new(
      reason: :unavailable_capability,
      code: "unavailable_capability",
      message: "The shell sent a deny reply with no denial payload."
    )
  end

  defp build_denial_from_wire(raw) do
    {reason, raw_reason} = normalize_reason(Map.get(raw, "reason"))
    details = normalize_details(Map.get(raw, "details"))
    details = if raw_reason, do: Map.put(details, :raw_reason, raw_reason), else: details

    Denial.new(
      reason: reason,
      code: Map.get(raw, "code") || Atom.to_string(reason),
      message: Map.get(raw, "message") || "The shell declined the request.",
      hint: Map.get(raw, "hint"),
      route_id: Map.get(raw, "route_id"),
      details: details,
      recovery: normalize_details(Map.get(raw, "recovery"))
    )
  end

  # Tolerant of reason strings outside the closed 14-reason vocabulary (D-16):
  # shipped natives already emit at least four out-of-vocabulary strings. An
  # unrecognized reason resolves to the documented `:unavailable_capability` reason —
  # never :shell_unreachable, which would falsely assert no shell answered when one
  # did, just not in-vocabulary — and the raw string is preserved in `details`.
  defp normalize_reason(nil), do: {:unavailable_capability, nil}

  defp normalize_reason(reason) when is_binary(reason) do
    if reason in known_reason_strings() do
      {String.to_existing_atom(reason), nil}
    else
      {:unavailable_capability, reason}
    end
  end

  defp normalize_reason(_other), do: {:unavailable_capability, nil}

  defp known_reason_strings, do: Enum.map(Denial.reasons(), &Atom.to_string/1)

  defp normalize_details(nil), do: %{}

  defp normalize_details(details) when is_map(details) do
    Enum.reduce(details, %{}, fn
      {"failing_moment", value}, acc -> Map.put(acc, :failing_moment, normalize_failing_moment(value))
      {key, value}, acc -> Map.put(acc, key, value)
    end)
  end

  defp normalize_details(_other), do: %{}

  defp normalize_failing_moment(value) when is_atom(value) and value in @failing_moments, do: value

  defp normalize_failing_moment(value) when is_binary(value) do
    if value in Enum.map(@failing_moments, &Atom.to_string/1) do
      String.to_existing_atom(value)
    else
      :hook_not_wired
    end
  end

  defp normalize_failing_moment(_other), do: :hook_not_wired

  defp correlation_id_from(payload) when is_map(payload) do
    Map.get(payload, "correlation_id") || Map.get(payload, :correlation_id)
  end

  defp correlation_id_from(_other), do: nil

  defp generate_correlation_id do
    "cwbridge-" <> (12 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false))
  end

  defp ack_deadline_ms do
    Application.get_env(:crosswake, :bridge_ack_deadline_ms, @default_ack_deadline_ms)
  end
end
