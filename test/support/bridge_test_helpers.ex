defmodule Crosswake.Bridge.NoAskInFlightError do
  @moduledoc """
  Raised by `Crosswake.Bridge.Test.reply/2` when there is nothing in flight to answer (or
  more than one ask, with no `:select` option to disambiguate).

  `Crosswake.Bridge.Test` never fabricates a correlation id in this situation. A fabricated
  or copy-pasted-stale id is, correctly, dropped by the seam's compare-and-delete
  machinery (D-23) exactly as an unrecognized or expired reply would be in production —
  without this named error, that silent drop is exactly the confusion D-77 named this
  helper as necessary scope to prevent.
  """
  defexception [:message]
end

defmodule Crosswake.Bridge.Test do
  @moduledoc """
  Test-only helper for simulating a native shell's reply to an in-flight `Crosswake.Bridge`
  ask, without a real shell or JS hook attached.

  `Crosswake.Bridge.push/3` mints its own internal, epoch-embedded `correlation_id` (D-20,
  D-23) — nothing outside `Crosswake.Bridge` can construct a valid one. Feeding
  `Phoenix.LiveViewTest.render_hook/3` a fabricated or stale correlation id is, correctly,
  dropped by the seam exactly as an unrecognized or expired reply would be dropped in
  production. Without this helper, a test author would see a `render_hook/3` call silently
  do nothing and could reasonably (but wrongly) conclude the seam itself is broken (D-77).

  `reply/2` reads the *real* correlation id straight out of the target LiveView's own
  in-flight table and builds a correctly wire-shaped reply payload correlated against it —
  composing with `render_hook/3` rather than replacing it, so a test reads like any other
  `Phoenix.LiveViewTest` assertion:

      {:ok, view, _html} = live(conn, "/my-route")
      render_click(view, "ask-for-something")

      reply = Crosswake.Bridge.Test.reply(view, status: :ok, payload: %{"answer" => "yes"})
      render_hook(view, "crosswake:bridge_reply", reply)

  ## Deny replies

      denial = Crosswake.Shell.Denial.new(reason: :origin_denied, code: "origin_denied", message: "...")
      reply = Crosswake.Bridge.Test.reply(view, status: :deny, denial: denial)
      render_hook(view, "crosswake:bridge_reply", reply)

  ## Multiple in-flight asks

  With more than one ask in flight, pass `:select` — a 1-arity function receiving the list
  of `{correlation_id, entry}` tuples (`entry` carries `:ref`, `:acked`, `:command`,
  `:route_id`, and `:request` — the exact envelope pushed to the hook) and returning the
  one to answer:

      reply =
        Crosswake.Bridge.Test.reply(view,
          select: fn asks -> Enum.find(asks, fn {_id, entry} -> entry.ref == :second end) end
        )

  Calling `reply/2` with nothing in flight, or with more than one ask and no `:select`,
  raises `Crosswake.Bridge.NoAskInFlightError` — it never fabricates an id.
  """

  alias Crosswake.Bridge.Contract
  alias Crosswake.Bridge.NoAskInFlightError
  alias Crosswake.Shell.Denial
  alias Phoenix.LiveViewTest.View

  @private_key :crosswake_bridge

  @doc """
  Builds a wire-shaped reply payload correlated against one of `view`'s in-flight bridge
  asks, suitable for `render_hook(view, "crosswake:bridge_reply", reply)`.

  ## Options

    * `:status` — `:ok` (default) or `:deny`.
    * `:payload` — the ok-reply payload map (default `%{}`). Ignored for `:deny`.
    * `:denial` — a `%Crosswake.Shell.Denial{}` (or an already wire-shaped denial map) used
      when `:status` is `:deny`. Defaults to a generic `:unavailable_capability` denial if
      omitted.
    * `:select` — a 1-arity function choosing among multiple in-flight asks. Required
      whenever more than one ask is in flight.

  Raises `Crosswake.Bridge.NoAskInFlightError` when there is nothing in flight to
  answer, or when there is more than one in-flight ask and no `:select` was given.
  """
  @spec reply(View.t(), keyword()) :: map()
  def reply(%View{} = view, opts \\ []) do
    {correlation_id, entry} = pick_in_flight!(view, opts)
    build_wire_reply(correlation_id, entry, opts)
  end

  @doc """
  Returns `view`'s current in-flight bridge asks as a map of
  `correlation_id => %{ref:, acked:, command:, route_id:, request:}`.

  Reads the real `Crosswake.Bridge` private state directly out of the running LiveView
  process (via `view.pid`, the actual LiveView pid — not the `Phoenix.LiveViewTest` proxy).
  """
  @spec in_flight(View.t()) :: %{optional(String.t()) => map()}
  def in_flight(%View{pid: pid}) when is_pid(pid) do
    pid
    |> :sys.get_state()
    |> Map.fetch!(:socket)
    |> Map.get(:private, %{})
    |> Map.get(@private_key, %{in_flight: %{}})
    |> Map.get(:in_flight, %{})
  end

  defp pick_in_flight!(view, opts) do
    asks = view |> in_flight() |> Map.to_list()

    case Keyword.get(opts, :select) do
      nil ->
        case asks do
          [] ->
            raise NoAskInFlightError,
              message: """
              [crosswake.bridge.test.no_ask_in_flight] nothing is in flight on #{inspect(view.module)} \
              to answer. Crosswake.Bridge.Test never fabricates a correlation id — dispatch a \
              Crosswake.Bridge.push/3 call first (e.g. render_click the element that calls it), then \
              call Crosswake.Bridge.Test.reply/2.
              """

          [only] ->
            only

          many ->
            raise NoAskInFlightError,
              message: """
              [crosswake.bridge.test.ambiguous_ask] #{length(many)} asks are in flight on \
              #{inspect(view.module)}. Pass `select: fn asks -> ... end` to choose one — refs in \
              flight: #{inspect(Enum.map(many, fn {_id, entry} -> entry.ref end))}.
              """
        end

      select_fn when is_function(select_fn, 1) ->
        case select_fn.(asks) do
          {correlation_id, entry} when is_binary(correlation_id) and is_map(entry) ->
            {correlation_id, entry}

          other ->
            raise ArgumentError,
                  "[crosswake.bridge.test.select] :select must return a " <>
                    "{correlation_id, entry} tuple from the given list; got #{inspect(other)}"
        end
    end
  end

  defp build_wire_reply(correlation_id, entry, opts) do
    status = Keyword.get(opts, :status, :ok)

    base = %{
      "protocol" => Contract.protocol(),
      "version" => Contract.version(),
      "command" => entry.command,
      "route_id" => entry.route_id,
      "correlation_id" => correlation_id,
      "status" => Atom.to_string(status)
    }

    case status do
      :ok ->
        Map.put(base, "payload", Keyword.get(opts, :payload, %{}))

      :deny ->
        denial = Keyword.get(opts, :denial) || default_denial()
        Map.put(base, "denial", %{"denial" => wire_denial(denial)})
    end
  end

  defp wire_denial(%Denial{} = denial), do: Denial.to_map(denial)
  defp wire_denial(%{} = raw_wire_denial), do: raw_wire_denial

  defp default_denial do
    Denial.new(
      reason: :unavailable_capability,
      code: "unavailable_capability",
      message: "Crosswake.Bridge.Test fabricated deny reply (no :denial option given)."
    )
  end
end
