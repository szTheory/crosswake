defmodule CrosswakeExample.SaaSPortal.ApprovalsLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint CrosswakeExample.Endpoint

  @approvals_live Module.concat([CrosswakeExample, SaaSPortal, ApprovalsLive])
  @approval_live Module.concat([CrosswakeExample, SaaSPortal, ApprovalLive])
  @approver %{
    id: "approver-1",
    name: "Alex Approver",
    email: "alex@example.crosswake.invalid",
    role: :approver,
    account_id: "acct-north"
  }
  @account %{id: "acct-north", name: "Northwind Workspace"}

  @tag :approval_queue_live
  test "AdminPilot approval queue LiveView contract renders pending queue, loading, disabled, and support states" do
    module =
      assert_exported!(
        @approvals_live,
        :mount,
        3,
        "AdminPilot approval queue LiveView contract D-11/D-12/D-17/D-18 requires #{@approvals_live}.mount/3"
      )

    socket = %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        current_saas_account: @account,
        current_saas_user: @approver,
        saas_role: :approver
      }
    }

    {:ok, mounted} = apply(module, :mount, [%{}, %{}, socket])
    html = render_to_string(module, mounted.assigns)

    assert html =~ "role=\"status\"",
           "AdminPilot approval queue LiveView contract D-11 requires role=\"status\" pending/loading feedback for saas-approvals"

    assert html =~ "Cached read-only",
           "AdminPilot approval queue LiveView contract D-12/D-14 requires cached read-only support truth without offline write claims"

    assert html =~ "Server authority",
           "AdminPilot approval queue LiveView contract D-07/D-14 requires Phoenix/server authority copy before native affordances"

    refute html =~ ~r/outbox|journal|reconciliation|local[- ]first/i,
           "AdminPilot approval queue LiveView contract D-12 forbids offline mutation, outbox, journal, or local-first approval claims"
  end

  # A real LiveViewTest round trip since Phase 154 (HRDN-01): the haptics dispatch runs
  # through Crosswake.Bridge.push/3, which raises on a socket that never attached, so a
  # hand-constructed %Phoenix.LiveView.Socket{} can no longer stand in for a mounted one.
  @tag :approval_detail_live
  test "AdminPilot approval detail LiveView contract handles success, bridge-absent, and typed-denial render states" do
    assert_exported!(
      @approval_live,
      :handle_event,
      3,
      "AdminPilot approval detail LiveView contract D-07/D-11/D-12/D-17 requires #{@approval_live}.handle_event/3"
    )

    previous = Application.get_env(:crosswake, :bridge_ack_deadline_ms)
    Application.put_env(:crosswake, :bridge_ack_deadline_ms, 25)

    on_exit(fn ->
      case previous do
        nil -> Application.delete_env(:crosswake, :bridge_ack_deadline_ms)
        value -> Application.put_env(:crosswake, :bridge_ack_deadline_ms, value)
      end
    end)

    CrosswakeExample.Showcase.Reset.reset!()

    {:ok, view, initial_html} = live(approver_conn(), "/saas/approvals/approval-1")

    assert initial_html =~ "Server authority",
           "AdminPilot approval detail LiveView contract D-07/D-11 requires visible server-authoritative action copy for saas-approval"

    assert initial_html =~ "Optional haptics",
           "AdminPilot approval detail LiveView contract D-12 requires bridge-absent haptics to be framed as optional support truth"

    assert initial_html =~ "No haptics request sent",
           "AdminPilot approval detail LiveView contract D-12 requires an honest idle state before any approval commits"

    render_click(view, "approve")

    # The dispatch is the one the seam built, and it happened INSIDE the committed
    # branch — D-07 and D-12 hold, now enforced by the seam rather than by convention.
    assert_push_event(view, "crosswake:bridge", envelope)
    assert envelope["command"] == "haptics.impact",
           "AdminPilot approval detail LiveView contract D-07/D-12 allows only post-success haptics.impact as a secondary signal"

    assert envelope["capability"] == "haptics",
           "the route-policy capability id is the family form; only the wire command keeps the dotted form"

    success_html = render(view)

    assert success_html =~ "role=\"status\"",
           "AdminPilot approval detail LiveView contract D-11 requires success state to be announced with role=\"status\""

    assert success_html =~ "Phoenix recorded the decision",
           "AdminPilot approval detail LiveView contract D-07 requires approval success text to name Phoenix/server authority before haptics"

    assert success_html =~ "Capability (route policy)" and success_html =~ "Command (wire protocol)",
           "the evidence panel must label the two identity rows distinctly (D-66)"

    refute success_html =~ "crosswakeBridge.postMessage",
           "HRDN-01 deletes the hand-rolled inline-script dispatch from this route"

    # No shell is listening in a test process, exactly as in a desktop browser: the
    # server-armed wiring deadline turns that into a rendered typed denial (D-65).
    Process.sleep(120)
    denied_html = render(view)

    assert denied_html =~ "Shell declined — shell_unreachable"
    assert denied_html =~ "The approval stands"
  end

  defp approver_conn do
    Plug.Test.init_test_session(build_conn(), %{
      CrosswakeExample.SaaSPortal.Auth.session_key() => @approver.id
    })
  end

  defp assert_exported!(module, function, arity, message) do
    assert Code.ensure_loaded?(module), "#{message}; module is not loadable"
    assert function_exported?(module, function, arity), "#{message}; function is not exported"
    module
  end

  defp render_to_string(module, assigns) do
    assigns =
      assigns
      |> Map.put_new(:__changed__, %{})
      |> Map.put_new(:flash, %{})

    module.render(assigns)
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end
end
