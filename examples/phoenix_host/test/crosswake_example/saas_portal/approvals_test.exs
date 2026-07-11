defmodule CrosswakeExample.SaaSPortal.ApprovalsTest do
  use ExUnit.Case, async: false

  @approvals Module.concat([CrosswakeExample, SaaSPortal, Approvals])
  @approver_scope %{
    account_id: "acct-north",
    user_id: "approver-1",
    role: :approver,
    route_id: "saas-approval"
  }
  @member_scope %{
    account_id: "acct-north",
    user_id: "member-1",
    role: :member,
    route_id: "saas-approval"
  }
  @cross_account_scope %{
    account_id: "acct-south",
    user_id: "approver-1",
    role: :approver,
    route_id: "saas-approval"
  }

  @tag :approval_schema_persistence
  test "AdminPilot approval schema persistence contract persists approval and activity evidence through reset" do
    module =
      assert_exported!(
        @approvals,
        :reset!,
        0,
        "AdminPilot approval schema persistence contract D-08/D-10/D-34 requires #{@approvals}.reset!/0"
      )

    assert_exported!(
      module,
      :list_approvals,
      1,
      "AdminPilot approval schema persistence contract D-08/D-09 requires #{@approvals}.list_approvals/1 to accept a current user/account scope"
    )

    assert_exported!(
      module,
      :activity_events,
      1,
      "AdminPilot approval schema persistence contract D-08/D-10 requires #{@approvals}.activity_events/1 for support-safe activity evidence"
    )

    apply(module, :reset!, [])
    before = apply(module, :list_approvals, [@approver_scope])

    assert Enum.any?(
             before,
             &(Map.get(&1, :id) == "approval-1" and Map.get(&1, :status) == :pending)
           ),
           "AdminPilot approval schema persistence contract D-06/D-08 requires approval-1 to start pending after deterministic reset"

    {:ok, approved} =
      apply(module, :approve_approval, [@approver_scope, "approval-1", %{haptics: :missing}])

    assert approved.status == :approved,
           "AdminPilot approval schema persistence contract D-07 requires Phoenix/server approval status before optional haptics"

    after_update = apply(module, :list_approvals, [@approver_scope])

    assert Enum.any?(
             after_update,
             &(Map.get(&1, :id) == "approval-1" and Map.get(&1, :status) == :approved)
           ),
           "AdminPilot approval schema persistence contract D-08 requires approval evidence to survive a context reload"

    activity = apply(module, :activity_events, [@approver_scope])

    assert Enum.any?(activity, &(Map.get(&1, :event_type) == :approval_approved)),
           "AdminPilot approval schema persistence contract D-08/D-10 requires a low-cardinality activity trail, not broad account persistence"
  end

  @tag :approval_context_workflow
  test "AdminPilot approval context workflow contract authorizes by current user and account scope" do
    module =
      assert_exported!(
        @approvals,
        :approve_approval,
        3,
        "AdminPilot approval context workflow contract D-06/D-07/D-09/T-149-01 requires #{@approvals}.approve_approval/3"
      )

    assert_exported!(
      module,
      :get_approval,
      2,
      "AdminPilot approval context workflow contract D-09 requires #{@approvals}.get_approval/2 scoped by current user/account"
    )

    assert {:error, :forbidden} =
             apply(module, :approve_approval, [@member_scope, "approval-1", %{haptics: "spoofed"}]),
           "AdminPilot approval context workflow contract D-07/T-149-04 requires non-approvers to fail before any native confirmation"

    assert {:error, :forbidden} =
             apply(module, :approve_approval, [@cross_account_scope, "approval-1", %{}]),
           "AdminPilot approval context workflow contract D-09/T-149-04 rejects cross-account approval authority"

    assert {:ok, approved} =
             apply(module, :approve_approval, [@approver_scope, "approval-1", %{}])

    assert approved.reviewed_by == "approver-1",
           "AdminPilot approval context workflow contract D-07 requires reviewed_by to come from current server-owned scope"
  end

  defp assert_exported!(module, function, arity, message) do
    assert Code.ensure_loaded?(module), "#{message}; module is not loadable"
    assert function_exported?(module, function, arity), "#{message}; function is not exported"
    module
  end
end
