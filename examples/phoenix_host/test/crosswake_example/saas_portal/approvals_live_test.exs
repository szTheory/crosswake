defmodule CrosswakeExample.SaaSPortal.ApprovalsLiveTest do
  use ExUnit.Case, async: false

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

  @tag :approval_detail_live
  test "AdminPilot approval detail LiveView contract handles success, forbidden, and bridge-absent render states" do
    module =
      assert_exported!(
        @approval_live,
        :handle_event,
        3,
        "AdminPilot approval detail LiveView contract D-07/D-11/D-12/D-17 requires #{@approval_live}.handle_event/3"
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

    {:noreply, loaded} =
      apply(module, :handle_params, [
        %{"id" => "approval-1"},
        "/saas/approvals/approval-1",
        mounted
      ])

    initial_html = render_to_string(module, loaded.assigns)

    assert initial_html =~ "Server authority",
           "AdminPilot approval detail LiveView contract D-07/D-11 requires visible server-authoritative action copy for saas-approval"

    assert initial_html =~ "Optional haptics",
           "AdminPilot approval detail LiveView contract D-12 requires bridge-absent haptics to be framed as optional support truth"

    {:noreply, approved} = apply(module, :handle_event, ["approve", %{}, loaded])
    success_html = render_to_string(module, approved.assigns)

    assert success_html =~ "role=\"status\"",
           "AdminPilot approval detail LiveView contract D-11 requires success state to be announced with role=\"status\""

    assert success_html =~ "Phoenix recorded the decision",
           "AdminPilot approval detail LiveView contract D-07 requires approval success text to name Phoenix/server authority before haptics"

    assert approved.assigns.bridge_request["command"] == "haptics.impact",
           "AdminPilot approval detail LiveView contract D-07/D-12 allows only post-success haptics.impact as a secondary signal"
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
