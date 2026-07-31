defmodule Crosswake.Proof.Phase35PaywallLiveTest do
  use ExUnit.Case, async: false

  # Depends on the checked-in example Phoenix app (CrosswakeExample.*) being
  # compiled. Run by phase5-proof.yml, which builds the example host first;
  # excluded from the hermetic full-suite runs via --exclude requires_example_host.
  #
  # This lane replaces the four manual human-UAT items from Phase 35 verification:
  # the async :stale -> :pending -> :granted transitions (subscribe + restore) and
  # the four-state render distinctions. The complementary Phase 36 hermetic proof
  # asserts the pure MockBackend/projection core WITHOUT processes; this test asserts
  # the LiveView callbacks + the PubSub message path, which DO require a process.
  #
  # The LiveView module is resolved through a variable (paywall_live/0) rather than a
  # literal alias so this file compiles warning-free even in lanes where the example
  # host is not loaded (mirrors phase7_saas_lane_test.exs).
  @moduletag :requires_example_host

  alias Phoenix.Component
  alias Phoenix.LiveViewTest

  @topic "entitlement:sub_pro_monthly"

  setup_all do
    Crosswake.TestSupport.ExampleHost.load!()
    :ok
  end

  setup do
    # PubSub is the only process this lane needs — ingest_evidence/2, simulate_*,
    # project_snapshot/2 and derived_state/1 are all pure. start_supervised! gives
    # each test a fresh, isolated broker (async: false serializes the global name).
    start_supervised!({Phoenix.PubSub, name: CrosswakeExample.PubSub})
    Phoenix.PubSub.subscribe(CrosswakeExample.PubSub, @topic)
    :ok
  end

  describe "mount" do
    test "initializes fail-closed to :stale (transitions only via the PubSub message path)" do
      assert {:ok, socket} = mount()
      assert socket.assigns.derived_state == :stale
    end
  end

  describe "four-state rendering" do
    test ":denied renders provider-neutral subscribe and restore actions" do
      html = render_state(:denied)

      assert html =~ "Subscribe to Pro Monthly"
      assert html =~ "$" <> "9.99 / month"
      assert html =~ ~s(phx-click="subscribe")
      assert html =~ "Restore purchase"
      assert html =~ "Backend entitlement projection"
    end

    test ":pending shows a backend verification state" do
      html = render_state(:pending)

      assert html =~ "Verifying backend entitlement"
      assert html =~ "Awaiting backend verification"
    end

    test ":granted shows a backend-projected access state" do
      html = render_state(:granted)

      assert html =~ "Access active from backend projection"
      assert html =~ "Projection refreshed"
    end

    test ":stale is structurally distinct from :denied — no pricing, no purchase action" do
      stale = render_state(:stale)

      assert stale =~ "Unable to verify access"
      assert stale =~ "Access is closed until backend entitlement projection refreshes"
      refute stale =~ "$" <> "9.99 / month"
      refute stale =~ ~s(phx-click="subscribe")
    end

    test "changing entitlement state is announced through an accessible status region" do
      for state <- [:granted, :pending, :denied, :stale] do
        html = render_state(state)

        assert html =~ ~s(role="status")
        assert html =~ ~s(aria-live="polite")
      end
    end

    test "read-only backend status block appears in every state" do
      for state <- [:granted, :pending, :denied, :stale] do
        html = render_state(state)

        assert html =~ "Projection state"
        assert html =~ "Freshness"
        assert html =~ "Reconciliation posture"
        assert html =~ "Authority source"
        assert html =~ "Backend entitlement projection"
      end
    end
  end

  describe "PubSub-driven state transitions" do
    test "subscribe drives :stale -> :pending -> :granted through the message path" do
      live = paywall_live()
      assert {:ok, socket} = mount()
      assert socket.assigns.derived_state == :stale

      assert {:noreply, _socket} = live.handle_event("subscribe", %{}, socket)

      # Immediate :pending broadcast, then :granted after the verify Task (1.5s sleep).
      assert_receive {:entitlement_update, :pending}
      assert_receive {:entitlement_update, :granted}, 3_000

      # The message path is what re-renders the LiveView.
      assert {:noreply, pending} = live.handle_info({:entitlement_update, :pending}, socket)
      assert pending.assigns.derived_state == :pending
      assert render_assigns(pending.assigns) =~ "Verifying backend entitlement"

      assert {:noreply, granted} = live.handle_info({:entitlement_update, :granted}, socket)
      assert granted.assigns.derived_state == :granted
      assert render_assigns(granted.assigns) =~ "Access active from backend projection"
    end

    test "restore drives the same :pending -> :granted transition" do
      live = paywall_live()
      assert {:ok, socket} = mount()

      assert {:noreply, _socket} = live.handle_event("restore", %{}, socket)

      assert_receive {:entitlement_update, :pending}
      assert_receive {:entitlement_update, :granted}, 3_000
    end

    test "handle_info maps every {:entitlement_update, state} to the derived_state assign" do
      live = paywall_live()
      assert {:ok, socket} = mount()

      for state <- [:granted, :pending, :denied, :stale] do
        assert {:noreply, updated} = live.handle_info({:entitlement_update, state}, socket)
        assert updated.assigns.derived_state == state
      end
    end
  end

  describe "provider-vocabulary fence" do
    test "no provider-SDK vocabulary leaks into any rendered state" do
      forbidden = [
        "store" <> "kit",
        "play" <> "_billing",
        "play" <> " billing",
        "revenue" <> "cat"
      ]

      for state <- [:granted, :pending, :denied, :stale] do
        html = String.downcase(render_state(state))

        for token <- forbidden do
          refute html =~ token, "rendered #{state} state leaked forbidden token #{inspect(token)}"
        end
      end
    end

    test "no subscription-management copy leaks into any rendered state" do
      forbidden = [
        "manage subscription",
        "cancel subscription",
        "invoice",
        "payment method",
        "plan change",
        "seats",
        "tax",
        "por" <> "tal"
      ]

      for state <- [:granted, :pending, :denied, :stale] do
        html = String.downcase(render_state(state))

        for token <- forbidden do
          refute html =~ token, "rendered #{state} state leaked forbidden token #{inspect(token)}"
        end
      end
    end
  end

  # --- helpers (mirror phase7_saas_lane_test.exs: bare socket, direct callbacks via a
  #     runtime-resolved module so the file compiles warning-free) ---

  # Resolved at runtime so the compiler performs no static undefined-function check
  # against the example host (which is only loaded in the :requires_example_host lane).
  defp paywall_live, do: Module.concat(["CrosswakeExample", "PaywallEntryLive"])

  defp mount do
    paywall_live().mount(%{}, %{}, %Phoenix.LiveView.Socket{})
  end

  defp render_state(state) do
    assert {:ok, socket} = mount()

    socket
    |> Component.assign(:derived_state, state)
    |> Map.fetch!(:assigns)
    |> render_assigns()
  end

  defp render_assigns(assigns) do
    assigns
    |> paywall_live().render()
    |> LiveViewTest.rendered_to_string()
  end
end
