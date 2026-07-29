defmodule Crosswake.TestSupport.Bridge.PageController do
  @moduledoc false
  def init(opts), do: opts
  def call(conn, _opts), do: conn
end

defmodule Crosswake.TestSupport.Bridge.Router do
  @moduledoc false
  use Crosswake.Router

  pipeline :browser do
    plug(Plug.Session,
      store: :cookie,
      key: "_crosswake_bridge_test",
      signing_salt: "cwbridgesess123"
    )

    plug(:fetch_session)
    plug(:fetch_live_flash)
  end

  scope "/" do
    pipe_through([:browser])

    crosswake_defaults runtime: :live_view, offline: :cached_read_only, security: :standard do
      live("/bridge-tracer", Crosswake.TestSupport.Bridge.TracerLive,
        crosswake: [id: "bridge-tracer", capabilities: ["haptics"]]
      )

      get("/bridge-empty-caps-decl", Crosswake.TestSupport.Bridge.PageController, :index,
        crosswake: [id: "bridge-empty-caps", capabilities: []]
      )
    end

    # Deliberately declared OUTSIDE crosswake_defaults — this route carries no
    # `crosswake:` metadata at all, so Manifest.compile/1 never manages it and
    # NotMountedLive never attaches the bridge, proving Crosswake.Bridge.push/3
    # raises NotMountedError rather than guessing a route id.
    live("/bridge-not-mounted", Crosswake.TestSupport.Bridge.NotMountedLive)
  end
end

defmodule Crosswake.TestSupport.Bridge.Endpoint do
  @moduledoc false
  use Phoenix.Endpoint, otp_app: :crosswake

  socket("/live", Phoenix.LiveView.Socket)

  defoverridable config: 1, config: 2

  def config(:live_view), do: [signing_salt: "crosswakebridgetestsalt12345678"]
  def config(:secret_key_base), do: String.duplicate("cwbridgetest1234", 4)
  def config(:pubsub_server), do: Crosswake.TestSupport.Bridge.PubSub
  def config(:render_errors), do: [formats: [html: __MODULE__], layout: false]
  def config(:url), do: [host: "localhost"]
  def config(which), do: super(which)
  def config(which, default), do: super(which, default)

  plug(Crosswake.TestSupport.Bridge.Router)

  def render(template, _assigns), do: Phoenix.Controller.status_message_from_template(template)
end

defmodule Crosswake.TestSupport.Bridge.TracerLive do
  # Attaches in mount/3, dispatches a declared capability via Crosswake.Bridge.push/3,
  # and surfaces whatever arrives at handle_info/2 back into rendered assigns so a
  # Phoenix.LiveViewTest round trip can assert on it without reaching into
  # LiveView-process-private state. :crosswake_route_id is read from the session
  # (defaulting to "bridge-tracer") so one fixture module can be mounted against
  # multiple manifest-declared route scenarios (an empty capabilities list, etc.)
  # without needing one LiveView per scenario.
  @moduledoc false

  use Phoenix.LiveView

  alias Crosswake.Bridge
  alias Crosswake.Manifest

  def mount(_params, session, socket) do
    {:ok, %{manifest: manifest}} = Manifest.compile(Crosswake.TestSupport.Bridge.Router)
    route_id = Map.get(session, "route_id", "bridge-tracer")

    socket =
      socket
      |> Phoenix.Component.assign(
        crosswake_manifest: manifest,
        crosswake_route_id: route_id,
        reply: nil,
        reply_ref: nil,
        reply_count: 0,
        unrelated_hit: false,
        in_flight_count: 0
      )
      |> Bridge.attach()

    {:ok, socket}
  end

  def handle_event("dispatch", params, socket) do
    ref = params |> Map.get("ref", "tap") |> String.to_atom()
    family = Map.get(params, "family", "haptics")
    payload = Map.get(params, "payload", %{})

    socket = Bridge.push(socket, family, ref: ref, payload: payload)
    {:noreply, refresh_in_flight_count(socket)}
  end

  def handle_event("dispatch_fire_and_forget", params, socket) do
    family = Map.get(params, "family", "haptics")
    socket = Bridge.push(socket, family)
    {:noreply, refresh_in_flight_count(socket)}
  end

  def handle_event("unrelated", _params, socket) do
    socket = Phoenix.Component.assign(socket, unrelated_hit: true)
    {:noreply, refresh_in_flight_count(socket)}
  end

  def handle_info({:crosswake_bridge, ref, reply}, socket) do
    socket =
      socket
      |> Phoenix.Component.assign(reply: reply, reply_ref: ref)
      |> Phoenix.Component.assign(:reply_count, socket.assigns.reply_count + 1)

    {:noreply, refresh_in_flight_count(socket)}
  end

  defp refresh_in_flight_count(socket) do
    count =
      socket.private
      |> Map.get(:crosswake_bridge, %{in_flight: %{}})
      |> Map.get(:in_flight, %{})
      |> map_size()

    Phoenix.Component.assign(socket, :in_flight_count, count)
  end

  def render(assigns) do
    ~H"""
    <div id="unrelated-hit">{inspect(@unrelated_hit)}</div>
    <div id="reply-ref">{inspect(@reply_ref)}</div>
    <div id="reply-count">{@reply_count}</div>
    <div id="in-flight-count">{@in_flight_count}</div>
    <div id="reply-status">{@reply && inspect(@reply.status)}</div>
    <div id="reply-reason">{@reply && @reply.denial && inspect(@reply.denial.reason)}</div>
    <div id="reply-failing-moment">
      {@reply && @reply.denial && inspect(Map.get(@reply.denial.details, :failing_moment))}
    </div>
    <div id="reply-raw-reason">{@reply && @reply.denial && inspect(Map.get(@reply.denial.details, :raw_reason))}</div>
    """
  end
end

defmodule Crosswake.TestSupport.Bridge.NotMountedLive do
  # Deliberately never calls Crosswake.Bridge.attach/1 — proves push/3 raises
  # Crosswake.Bridge.NotMountedError rather than guessing a route id.
  @moduledoc false

  use Phoenix.LiveView

  alias Crosswake.Bridge

  def mount(_params, _session, socket), do: {:ok, socket}

  def handle_event("dispatch", _params, socket) do
    {:noreply, Bridge.push(socket, "haptics")}
  end

  def render(assigns) do
    ~H"""
    <div id="not-mounted">not-mounted-fixture</div>
    """
  end
end

defmodule Crosswake.TestSupport.Bridge.Case do
  # Test-support helpers for exercising Crosswake.Bridge through a real
  # Phoenix.LiveViewTest round trip.
  @moduledoc false

  @doc """
  Starts the self-contained test endpoint once. Idempotent — safe to call from every
  test file's `setup_all`.
  """
  def start_endpoint! do
    case Crosswake.TestSupport.Bridge.Endpoint.start_link() do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end
  end

  @doc """
  Calls `func` after unlinking the test process from the LiveView's proxy pid, then
  catches the `:exit` a raise inside a hook/callback propagates as, returning the
  raised exception's `message`. Mirrors the exact pattern `phoenix_live_view`'s own
  test suite uses to assert on an exception raised inside `handle_event`/`handle_info`.
  """
  def exits_with(view, exception_module, func) do
    Process.unlink(proxy_pid(view))

    try do
      func.()
      raise "expected #{inspect(view)} to exit due to #{inspect(exception_module)}, but it didn't"
    catch
      :exit, {{%mod{message: message}, _stacktrace}, _call_info} when mod == exception_module ->
        message
    end
  end

  defp proxy_pid(%{proxy: {_ref, _topic, pid}}), do: pid
end
