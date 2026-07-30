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

  # Pulls the JSON body back out of a rendered <div> — HEEx escapes the quotes, so the
  # entity forms have to be reversed before Jason can decode it (&amp; last, or the
  # earlier replacements would be double-decoded).
  defp extract_json!(rendered) do
    rendered
    |> String.replace(~r/<[^>]*>/, "")
    |> String.trim()
    |> String.replace("&quot;", "\"")
    |> String.replace("&#39;", "'")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&amp;", "&")
    |> Jason.decode!()
  end

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

    test "dispatched/2 hands back the SAME envelope that was pushed to the hook (D-67)" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      render_click(view, "dispatch", %{"ref" => "tap"})
      assert_push_event(view, "crosswake:bridge", pushed_envelope)

      read_back = view |> reply_element("dispatched-envelope") |> extract_json!()

      # Byte-for-byte the same envelope, not a re-derived summary: an evidence panel
      # rendering this can never drift from what the seam actually dispatched.
      assert read_back == pushed_envelope
      assert read_back["command"] == "haptics.impact"
      assert read_back["capability"] == "haptics"
    end

    test "dispatched/2 returns nil for a ref with nothing in flight" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      dispatch!(view, %{"ref" => "tap"})
      assert reply_element(view, "dispatched-envelope") =~ "haptics.impact"

      render_click(view, "read_dispatched", %{"ref" => "never_pushed"})

      assert reply_element(view, "dispatched-envelope") == "<div id=\"dispatched-envelope\"></div>"
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

  # ---------------------------------------------------------------------------
  # Task 1 — opaque ref, per-mount epoch, three-layer compare-and-delete, resolve/2
  # (CTRL-01, CTRL-02, D-20..D-25)
  # ---------------------------------------------------------------------------

  describe "Task 1: epoch, exactly-once delivery, and resolve/2 (D-20..D-25)" do
    test "twenty concurrent asks, each with a distinct ref, deliver twenty distinct replies matched by ref" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      refs = for n <- 1..20, do: "ref-#{n}"

      correlation_ids =
        for ref <- refs do
          {ref, dispatch!(view, %{"ref" => ref})}
        end

      for {_ref, correlation_id} <- correlation_ids do
        render_hook(view, "crosswake:bridge_reply", ok_wire_reply(correlation_id))
      end

      assert reply_element(view, "replies-by-ref-count") =~ "20"

      for ref <- refs do
        # render() HTML-escapes the inspect/1 output, so `"` becomes `&quot;`.
        assert reply_element(view, "replies-by-ref") =~ "&quot;#{ref}&quot;: :ok"
      end
    end

    test "a push with no ref option delivers nothing to handle_info/2, but still resolves its in-flight bookkeeping" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      render_click(view, "dispatch_fire_and_forget", %{})
      Process.sleep(100)
      render_click(view, "unrelated", %{})

      assert reply_element(view, "reply-count") =~ "0"
      assert reply_element(view, "in-flight-count") =~ "0"
    end

    test "delivering the same correlation id twice results in exactly one handle_info/2 delivery" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      correlation_id = dispatch!(view, %{"ref" => "tap"})
      render_hook(view, "crosswake:bridge_reply", ok_wire_reply(correlation_id))
      assert reply_element(view, "reply-count") =~ "1"

      render_hook(view, "crosswake:bridge_reply", ok_wire_reply(correlation_id))
      assert reply_element(view, "reply-count") =~ "1"
    end

    test "a reply minted under a previous epoch is dropped as foreign-epoch after a simulated remount" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      stale_correlation_id = dispatch!(view, %{"ref" => "tap"})

      render_click(view, "remount", %{})

      render_hook(view, "crosswake:bridge_reply", ok_wire_reply(stale_correlation_id))

      assert reply_element(view, "reply-count") =~ "0"
    end

    test "Crosswake.Bridge.resolve/2 clears the ask; a native reply arriving afterward for that same ask delivers nothing" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      correlation_id = dispatch!(view, %{"ref" => "tap"})
      render_click(view, "resolve", %{"ref" => "tap"})

      render_hook(view, "crosswake:bridge_reply", ok_wire_reply(correlation_id))

      assert reply_element(view, "reply-count") =~ "0"
    end

    test "calling resolve/2 twice for the same ref is a no-op the second time and does not raise" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      dispatch!(view, %{"ref" => "tap"})
      render_click(view, "resolve", %{"ref" => "tap"})
      render_click(view, "resolve", %{"ref" => "tap"})

      assert reply_element(view, "unrelated-hit") =~ "false"
    end

    test "the adopter's ref never appears in the pushed client-event payload" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      render_click(view, "dispatch", %{"ref" => "tap"})
      assert_push_event(view, "crosswake:bridge", envelope)

      refute Enum.any?(Map.values(envelope), fn
               value when is_binary(value) -> String.contains?(value, "tap")
               _other -> false
             end)
    end
  end

  # ---------------------------------------------------------------------------
  # Task 2 — two timers and the bridge telemetry catalog (D-22)
  # ---------------------------------------------------------------------------

  describe "Task 2: two timers and telemetry (D-22)" do
    setup do
      previous_margin = Application.get_env(:crosswake, :bridge_reply_deadline_margin_ms)
      Application.put_env(:crosswake, :bridge_reply_deadline_margin_ms, 10)

      on_exit(fn ->
        case previous_margin do
          nil -> Application.delete_env(:crosswake, :bridge_reply_deadline_margin_ms)
          value -> Application.put_env(:crosswake, :bridge_reply_deadline_margin_ms, value)
        end
      end)

      :ok
    end

    test "a push with an explicit short timeout delivers a :shell_unreachable denial with the reply-timeout failing moment" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      # Ack immediately so the wiring-deadline path never fires first — only the
      # reply-deadline backstop should resolve this ask.
      correlation_id = dispatch!(view, %{"ref" => "tap", "timeout" => 200})
      render_hook(view, "crosswake:bridge_ack", %{"correlation_id" => correlation_id})

      Process.sleep(300)

      assert reply_element(view, "reply-status") =~ ":deny"
      assert reply_element(view, "reply-reason") =~ ":shell_unreachable"
      assert reply_element(view, "reply-failing-moment") =~ ":reply_timeout"
    end

    test "a push with an unbounded timeout never fires the server reply backstop" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      correlation_id = dispatch!(view, %{"ref" => "tap", "timeout" => "infinity"})
      render_hook(view, "crosswake:bridge_ack", %{"correlation_id" => correlation_id})

      Process.sleep(150)

      assert reply_element(view, "reply-count") =~ "0"
      assert reply_element(view, "in-flight-count") =~ "1"
    end

    test "each of the five bridge events appears in Crosswake.Telemetry.events/0 with a description, measurements, and metadata" do
      bridge_events =
        Crosswake.Telemetry.events()
        |> Enum.filter(fn e -> match?([:crosswake, :bridge | _], e.event) end)

      expected_suffixes = [:push, :reply, :dropped, :hook_ack, :hook_missing]

      for suffix <- expected_suffixes do
        entry = Enum.find(bridge_events, fn e -> e.event == [:crosswake, :bridge, suffix] end)

        assert entry, "expected [:crosswake, :bridge, #{inspect(suffix)}] in events/0"
        assert entry.tier == :active
        assert is_binary(entry.description) and entry.description != ""
        assert is_list(entry.measurements) and entry.measurements != []
        assert is_list(entry.metadata) and entry.metadata != []
      end
    end

    test "the reply event's denial-reason metadata is drawn from the bounded 14-atom vocabulary" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      ref = :telemetry_test.attach_event_handlers(self(), [[:crosswake, :bridge, :reply, :stop]])
      on_exit(fn -> :telemetry.detach(ref) end)

      correlation_id = dispatch!(view, %{"ref" => "tap"})
      Process.sleep(100)

      assert_received {[:crosswake, :bridge, :reply, :stop], ^ref, _measurements, metadata}
      assert metadata.denial_reason in Crosswake.Shell.Denial.reasons()
    end

    test "the dropped-reply event fires once for a duplicate delivery and once for a foreign-epoch delivery" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      ref = :telemetry_test.attach_event_handlers(self(), [[:crosswake, :bridge, :dropped, :stop]])
      on_exit(fn -> :telemetry.detach(ref) end)

      correlation_id = dispatch!(view, %{"ref" => "tap"})
      render_hook(view, "crosswake:bridge_reply", ok_wire_reply(correlation_id))
      render_hook(view, "crosswake:bridge_reply", ok_wire_reply(correlation_id))

      assert_received {[:crosswake, :bridge, :dropped, :stop], ^ref, _m1, %{reason: :duplicate}}

      stale_correlation_id = dispatch!(view, %{"ref" => "tap2"})
      render_click(view, "remount", %{})
      render_hook(view, "crosswake:bridge_reply", ok_wire_reply(stale_correlation_id))

      assert_received {[:crosswake, :bridge, :dropped, :stop], ^ref, _m2, %{reason: :foreign_epoch}}
    end

    test "the hook-missing event fires when the wiring deadline expires with no ack" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      ref = :telemetry_test.attach_event_handlers(self(), [[:crosswake, :bridge, :hook_missing, :stop]])
      on_exit(fn -> :telemetry.detach(ref) end)

      dispatch!(view, %{"ref" => "tap"})
      Process.sleep(100)

      assert_received {[:crosswake, :bridge, :hook_missing, :stop], ^ref, _measurements, _metadata}
    end

    test "the hook-ack event fires when the bridge hook's acknowledgement arrives" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      ref = :telemetry_test.attach_event_handlers(self(), [[:crosswake, :bridge, :hook_ack, :stop]])
      on_exit(fn -> :telemetry.detach(ref) end)

      correlation_id = dispatch!(view, %{"ref" => "tap"})
      render_hook(view, "crosswake:bridge_ack", %{"correlation_id" => correlation_id})

      assert_received {[:crosswake, :bridge, :hook_ack, :stop], ^ref, _measurements, _metadata}
    end
  end

  # ---------------------------------------------------------------------------
  # Task 3 — Crosswake.Bridge.Test, the render_hook/3 correlation-id fabrication
  # helper without which the seam is untestable without a shell (D-77)
  # ---------------------------------------------------------------------------

  describe "Task 3: Crosswake.Bridge.Test (D-77)" do
    test "produces an ok reply for the sole in-flight ask that, fed through render_hook/3, delivers a %Reply{status: :ok}" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      render_click(view, "dispatch", %{"ref" => "tap"})

      reply = Crosswake.Bridge.Test.reply(view, status: :ok)
      render_hook(view, "crosswake:bridge_reply", reply)

      assert reply_element(view, "reply-ref") =~ ":tap"
      assert reply_element(view, "reply-status") =~ ":ok"
    end

    test "produces a deny reply carrying a caller-chosen Shell.Denial reason" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      render_click(view, "dispatch", %{"ref" => "tap"})

      denial =
        Crosswake.Shell.Denial.new(
          reason: :origin_denied,
          code: "origin_denied",
          message: "origin not allowlisted"
        )

      reply = Crosswake.Bridge.Test.reply(view, status: :deny, denial: denial)
      render_hook(view, "crosswake:bridge_reply", reply)

      assert reply_element(view, "reply-status") =~ ":deny"
      assert reply_element(view, "reply-reason") =~ ":origin_denied"
    end

    test "calling the helper with nothing in flight raises a named error rather than fabricating a correlation id" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      assert_raise Crosswake.Bridge.NoAskInFlightError, ~r/no_ask_in_flight/, fn ->
        Crosswake.Bridge.Test.reply(view, status: :ok)
      end
    end

    test "with two asks in flight, the helper can select which one to answer" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      render_click(view, "dispatch", %{"ref" => "first"})
      render_click(view, "dispatch", %{"ref" => "second"})

      reply =
        Crosswake.Bridge.Test.reply(view,
          status: :ok,
          select: fn asks -> Enum.find(asks, fn {_id, entry} -> entry.ref == :second end) end
        )

      render_hook(view, "crosswake:bridge_reply", reply)

      assert reply_element(view, "reply-ref") =~ ":second"
    end

    test "calling the helper with two asks in flight and no :select raises the ambiguity error" do
      {:ok, view, _html} = live(tracer_conn(), "/bridge-tracer")

      render_click(view, "dispatch", %{"ref" => "first"})
      render_click(view, "dispatch", %{"ref" => "second"})

      assert_raise Crosswake.Bridge.NoAskInFlightError, ~r/ambiguous_ask/, fn ->
        Crosswake.Bridge.Test.reply(view, status: :ok)
      end
    end
  end
end
