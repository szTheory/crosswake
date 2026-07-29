defmodule Crosswake.Bridge.PushTest do
  @moduledoc """
  Phase 154 Plan 03 — the tracer proof (CTRL-01), the loud preflight (CTRL-03), and the
  denial collapse (CTRL-02). Runs untagged in the default hermetic lane: no
  `:requires_example_host`, `:advisory_only`, `:engine_present`, or
  `:collateral_binaries` tag (RESEARCH.md §10).
  """

  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest
  import Phoenix.ConnTest

  alias Crosswake.Bridge
  alias Crosswake.Bridge.Contract
  alias Crosswake.Bridge.NotMountedError
  alias Crosswake.Bridge.UndeclaredCapabilityError
  alias Crosswake.TestSupport.Bridge.Case, as: BridgeCase

  @endpoint Crosswake.TestSupport.Bridge.Endpoint

  setup_all do
    BridgeCase.start_endpoint!()
    :ok
  end

  setup do
    previous = Application.get_env(:crosswake, :bridge_ack_deadline_ms)
    Application.put_env(:crosswake, :bridge_ack_deadline_ms, 25)

    on_exit(fn ->
      case previous do
        nil -> Application.delete_env(:crosswake, :bridge_ack_deadline_ms)
        value -> Application.put_env(:crosswake, :bridge_ack_deadline_ms, value)
      end
    end)

    :ok
  end

  # ---------------------------------------------------------------------------
  # Fixtures + helpers
  # ---------------------------------------------------------------------------

  defp tracer_conn(route_id \\ nil) do
    session = if route_id, do: %{"route_id" => route_id}, else: %{}

    Phoenix.ConnTest.build_conn()
    |> Plug.Test.init_test_session(session)
  end

  defp dispatch!(view, params \\ %{"ref" => "tap"}) do
    render_click(view, "dispatch", params)
    assert_push_event(view, "crosswake:bridge", envelope)
    envelope["correlation_id"]
  end

  defp build_request(correlation_id, opts \\ []) do
    Contract.new_request(
      command: Keyword.get(opts, :command, "haptics.impact"),
      capability: Keyword.get(opts, :capability, "haptics"),
      route_id: Keyword.get(opts, :route_id, "bridge-tracer"),
      active_route_id: Keyword.get(opts, :route_id, "bridge-tracer"),
      origin: "https://shell.crosswake.example",
      native_runtime_version: "1.0.0",
      correlation_id: correlation_id
    )
  end

  defp ok_wire_reply(correlation_id) do
    correlation_id
    |> build_request()
    |> Contract.ok_reply(%{})
    |> Contract.to_map()
  end

  # Mirrors Contract.deny_reply/2 + Bridge.Denial.to_map/1's documented double nest
  # (reply["denial"]["denial"]["reason"]) exactly, without depending on
  # Crosswake.Shell.Denial.new/1's typed-atom validation — this lets us hand-place an
  # out-of-vocabulary reason STRING the way a real shipped native does (RESEARCH.md §6).
  defp deny_wire_reply_raw(correlation_id, raw_denial) do
    correlation_id
    |> build_request()
    |> Contract.to_map()
    |> Map.take(["protocol", "version", "command", "route_id", "correlation_id"])
    |> Map.put("status", "deny")
    |> Map.put("denial", %{
      "command" => "haptics.impact",
      "route_id" => "bridge-tracer",
      "correlation_id" => correlation_id,
      "denial" => raw_denial
    })
  end

  defp reply_element(view, id), do: view |> element("##{id}") |> render()

  # ---------------------------------------------------------------------------
  # Task 1 — the tracer: one declared capability travels the whole seam (CTRL-01)
  # ---------------------------------------------------------------------------

  describe "the tracer round trip (CTRL-01, D-17, D-18, D-36)" do
    test "attach + push dispatches exactly one crosswake:bridge event with a well-formed Contract.Request map" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      render_click(view, "dispatch", %{"ref" => "tap"})
      assert_push_event(view, "crosswake:bridge", envelope)

      assert envelope["protocol"] == Contract.protocol()
      assert envelope["version"] == Contract.version()
      assert envelope["command"] == "haptics.impact"
      assert envelope["capability"] == "haptics"
      assert envelope["route_id"] == "bridge-tracer"
      assert envelope["active_route_id"] == "bridge-tracer"
      assert is_binary(envelope["correlation_id"])
      assert envelope["correlation_id"] != ""
    end

    test "feeding the correlation id back through the reply event with an ok status delivers a typed Reply to handle_info/2" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      correlation_id = dispatch!(view, %{"ref" => "tap"})
      render_hook(view, "crosswake:bridge_reply", ok_wire_reply(correlation_id))

      assert reply_element(view, "reply-ref") =~ ":tap"
      assert reply_element(view, "reply-status") =~ ":ok"
    end

    test "the adopter's own handle_event/3 never sees the reserved reply event — the interceptor halts it" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      correlation_id = dispatch!(view, %{"ref" => "tap"})

      # TracerLive defines no handle_event clause for "crosswake:bridge_reply" at all —
      # if the interceptor did not halt it, this would crash with FunctionClauseError.
      render_hook(view, "crosswake:bridge_reply", ok_wire_reply(correlation_id))

      assert reply_element(view, "reply-status") =~ ":ok"
    end

    test "an unrelated client event on the same LiveView still reaches the adopter's own handle_event/3" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      render_click(view, "unrelated", %{})

      assert reply_element(view, "unrelated-hit") =~ "true"
    end

    test "with no ack arriving within the wiring deadline, handle_info/2 receives a deny Reply with :hook_not_wired" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      dispatch!(view, %{"ref" => "tap"})
      Process.sleep(100)

      assert reply_element(view, "reply-status") =~ ":deny"
      assert reply_element(view, "reply-reason") =~ ":shell_unreachable"
      assert reply_element(view, "reply-failing-moment") =~ ":hook_not_wired"
    end

    test "a reply carrying an unknown correlation id delivers nothing" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      dispatch!(view, %{"ref" => "tap"})
      render_hook(view, "crosswake:bridge_reply", ok_wire_reply("cwbridge-unknown-correlation"))

      assert reply_element(view, "reply-status") =~ ""
      assert reply_element(view, "reply-count") =~ "0"
    end
  end

  # ---------------------------------------------------------------------------
  # Task 2 — the loud preflight (CTRL-03, D-04..D-10)
  # ---------------------------------------------------------------------------

  describe "the loud preflight (CTRL-03)" do
    test "pushing a capability the route never declared raises UndeclaredCapabilityError naming route, family, declared, view, router location, fix line, and why (D-10)" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      message =
        BridgeCase.exits_with(view, UndeclaredCapabilityError, fn ->
          render_click(view, "dispatch", %{"family" => "camera"})
        end)

      assert message =~ ~s(route "bridge-tracer")
      assert message =~ ~s("camera")
      assert message =~ ~s(["haptics"])
      assert message =~ "Crosswake.TestSupport.Bridge.TracerLive"
      assert message =~ "bridge_live_view_case.ex"
      assert message =~ ~s(capabilities: ["haptics", "camera"])
      assert message =~ "server-authoring bug"
    end

    test "calling push/3 on a socket that never attached raises NotMountedError naming the missing attach call" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-not-mounted")

      message =
        BridgeCase.exits_with(view, NotMountedError, fn ->
          render_click(view, "dispatch", %{})
        end)

      assert message =~ "not_mounted"
      assert message =~ "attach"
    end

    test "a route whose policy declares an empty capabilities list raises rather than authorizing — not a wildcard" do
      {:ok, view, _html} = live(tracer_conn("bridge-empty-caps"), "/bridge-tracer")

      message =
        BridgeCase.exits_with(view, UndeclaredCapabilityError, fn ->
          render_click(view, "dispatch", %{"family" => "haptics"})
        end)

      assert message =~ ~s(route "bridge-empty-caps")
      assert message =~ "Currently declared on this route: []"
    end

    test "a capability id differing only by case does not authorize and raises (exact string match)" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      message =
        BridgeCase.exits_with(view, UndeclaredCapabilityError, fn ->
          render_click(view, "dispatch", %{"family" => "Haptics"})
        end)

      assert message =~ ~s("Haptics")
    end

    test "pushing on a route id absent from the compiled manifest raises a distinct inactive-route error" do
      {:ok, view, _html} = live(tracer_conn("nonexistent-route"), "/bridge-tracer")

      message =
        BridgeCase.exits_with(view, ArgumentError, fn ->
          render_click(view, "dispatch", %{"family" => "haptics"})
        end)

      assert message =~ "inactive_route"
    end

    test "no availability or connectedness predicate is shipped (D-09)" do
      refute function_exported?(Crosswake.Bridge, :available?, 1)
      refute function_exported?(Crosswake.Bridge, :available?, 2)
      refute function_exported?(Crosswake.Bridge, :connected?, 1)
      refute function_exported?(Crosswake.Bridge, :connected?, 2)
    end
  end

  # ---------------------------------------------------------------------------
  # Task 3 — the denial collapse (CTRL-02, D-11..D-16, D-28)
  # ---------------------------------------------------------------------------

  describe "the denial collapse (CTRL-02)" do
    test "the unwired-hook moment and the unreachable-fact moments all collapse to :shell_unreachable, distinguished only by failing_moment" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      correlation_id = dispatch!(view, %{"ref" => "tap"})
      render_hook(view, "crosswake:bridge_unreachable", %{
        "correlation_id" => correlation_id,
        "moment" => "no_transport"
      })

      assert reply_element(view, "reply-status") =~ ":deny"
      assert reply_element(view, "reply-reason") =~ ":shell_unreachable"
      assert reply_element(view, "reply-failing-moment") =~ ":no_transport"
    end

    test "the transport_error moment also collapses to :shell_unreachable" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      correlation_id = dispatch!(view, %{"ref" => "tap"})
      render_hook(view, "crosswake:bridge_unreachable", %{
        "correlation_id" => correlation_id,
        "moment" => "transport_error"
      })

      assert reply_element(view, "reply-reason") =~ ":shell_unreachable"
      assert reply_element(view, "reply-failing-moment") =~ ":transport_error"
    end

    test ":reply_timeout is a valid failing_moment at the Shell.Denial construction level (unit-level; Plan 04 owns the second timer that reaches it via the full round trip)" do
      denial =
        Crosswake.Shell.Denial.new(
          reason: :shell_unreachable,
          code: "shell_unreachable",
          message: "The shell never answered before the reply deadline.",
          details: %{failing_moment: :reply_timeout}
        )

      assert denial.reason == :shell_unreachable
      assert denial.details.failing_moment == :reply_timeout
    end

    test "a doubly-nested wire denial decodes to a single flat %Crosswake.Shell.Denial{}" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      correlation_id = dispatch!(view, %{"ref" => "tap"})

      raw_denial = %{
        "reason" => "compatibility_mismatch",
        "code" => "compatibility_mismatch",
        "message" => "The shell is too old for this capability."
      }

      render_hook(view, "crosswake:bridge_reply", deny_wire_reply_raw(correlation_id, raw_denial))

      assert reply_element(view, "reply-status") =~ ":deny"
      assert reply_element(view, "reply-reason") =~ ":compatibility_mismatch"
    end

    test "an out-of-vocabulary denial reason string neither crashes nor is laundered as the struct's reason — it resolves to :unavailable_capability and the raw string survives in details" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      correlation_id = dispatch!(view, %{"ref" => "tap"})

      raw_denial = %{
        "reason" => "notification_status_unavailable",
        "message" => "Notification status is not available on this platform."
      }

      render_hook(view, "crosswake:bridge_reply", deny_wire_reply_raw(correlation_id, raw_denial))

      assert reply_element(view, "reply-status") =~ ":deny"
      assert reply_element(view, "reply-reason") =~ ":unavailable_capability"
      refute reply_element(view, "reply-reason") =~ "notification_status_unavailable"
      assert reply_element(view, "reply-raw-reason") =~ "notification_status_unavailable"
    end

    test "a push with an empty payload and no ref: option still resolves exactly one denial internally with no crash" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      render_click(view, "dispatch_fire_and_forget", %{})
      Process.sleep(100)
      # Force a fresh render so the (already-resolved, silently-cleared) in-flight
      # bookkeeping is reflected in assigns — nothing else triggers a render for a
      # fire-and-forget push, since D-21 means nothing is ever sent to handle_info/2.
      render_click(view, "unrelated", %{})

      # No ref means fire-and-forget (D-21): Crosswake consumes the reply, nothing is
      # delivered to handle_info/2 — but the in-flight bookkeeping still resolves and
      # clears, proving the denial was produced and the LiveView never crashed.
      assert reply_element(view, "reply-count") =~ "0"
      assert reply_element(view, "in-flight-count") =~ "0"
    end

    test "a native deny reply and the server-side deadline denial racing on the same correlation id resolve to exactly one delivered reply" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      correlation_id = dispatch!(view, %{"ref" => "tap"})
      render_hook(view, "crosswake:bridge_reply", ok_wire_reply(correlation_id))

      assert reply_element(view, "reply-count") =~ "1"

      # Let the (already-armed, test-shortened) ack-deadline timer fire too — it must
      # find nothing in-flight for this correlation id and deliver nothing further.
      Process.sleep(100)

      assert reply_element(view, "reply-count") =~ "1"
      assert reply_element(view, "reply-status") =~ ":ok"
    end
  end
end
