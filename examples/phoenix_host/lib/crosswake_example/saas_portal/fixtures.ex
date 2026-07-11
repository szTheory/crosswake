defmodule CrosswakeExample.SaaSPortal.Fixtures do
  @moduledoc """
  Deterministic AdminPilot fixtures for the SaaS/admin showcase lane.
  """

  @account %{
    id: "acct-north",
    name: "Northwind Workspace",
    health: :steady,
    renewal_window: "14 days",
    open_approvals: 2,
    plan: "Enterprise",
    region: "US East",
    support_ref: "support:acct-north"
  }

  @team [
    %{
      id: "team-ops",
      account_id: @account.id,
      name: "Operations Control",
      timezone: "America/New_York",
      member_count: 3,
      focus: "approvals, vendor access, and account posture"
    }
  ]

  @users [
    %{
      id: "member-1",
      name: "Marta Member",
      email: "marta@example.crosswake.invalid",
      role: :member,
      account_id: @account.id
    },
    %{
      id: "approver-1",
      name: "Alex Approver",
      email: "alex@example.crosswake.invalid",
      role: :approver,
      account_id: @account.id
    },
    %{
      id: "owner-1",
      name: "Priya Owner",
      email: "priya@example.crosswake.invalid",
      role: :owner,
      account_id: @account.id
    }
  ]

  @roles [
    %{
      id: "role-member",
      key: :member,
      label: "Member",
      posture: "Can request and inspect routine approvals",
      server_authority: "Session grants read access only"
    },
    %{
      id: "role-approver",
      key: :approver,
      label: "Approver",
      posture: "Can approve queued operational requests",
      server_authority: "Phoenix checks role before mutation"
    },
    %{
      id: "role-owner",
      key: :owner,
      label: "Owner",
      posture: "Owns account and admin-pressure review",
      server_authority: "Sensitive access still requires backend step-up"
    }
  ]

  @settings %{
    id: "settings-acct-north",
    account_id: @account.id,
    approval_threshold: "$25,000",
    renewal_notice_window: "14 days",
    member_access_review: "MFA and recent-auth required",
    cached_read_posture: "Cached read-only",
    native_boundary: "No native admin mutation authority"
  }

  @approvals [
    %{
      id: "approval-1",
      account_id: @account.id,
      title: "Quarterly spend increase",
      status: :pending,
      requested_by: "member-1",
      reviewed_by: nil,
      amount: "$42,000",
      policy_id: "policy-spend",
      route_id: "saas-approval"
    },
    %{
      id: "approval-2",
      account_id: @account.id,
      title: "Vendor access renewal",
      status: :pending,
      requested_by: "member-1",
      reviewed_by: nil,
      amount: "$8,400",
      policy_id: "policy-access",
      route_id: "saas-approval"
    },
    %{
      id: "approval-3",
      account_id: @account.id,
      title: "Contract archive export",
      status: :approved,
      requested_by: "member-1",
      reviewed_by: "approver-1",
      amount: "$0",
      policy_id: "policy-export",
      route_id: "saas-approval"
    }
  ]

  @operational_records [
    %{
      id: "ops-record-spend",
      account_id: @account.id,
      title: "Quarterly spend increase",
      owner_id: "approver-1",
      status: :needs_review,
      route_id: "saas-approvals"
    },
    %{
      id: "ops-record-vendor",
      account_id: @account.id,
      title: "Vendor access renewal",
      owner_id: "member-1",
      status: :pending_security_review,
      route_id: "saas-admin-member-access"
    },
    %{
      id: "ops-record-export",
      account_id: @account.id,
      title: "Contract archive export",
      owner_id: "owner-1",
      status: :approved,
      route_id: "saas-account"
    }
  ]

  @approval_policies [
    %{
      id: "policy-spend",
      title: "Spend approvals above $25,000",
      required_role: :approver,
      support_label: "Server authority"
    },
    %{
      id: "policy-access",
      title: "Vendor access renewals",
      required_role: :owner,
      support_label: "MFA required"
    },
    %{
      id: "policy-export",
      title: "Archive exports",
      required_role: :approver,
      support_label: "Cached read-only review"
    }
  ]

  @activity_events [
    %{
      id: "activity-open-lane",
      account_id: @account.id,
      actor_id: "member-1",
      event_type: :opened_lane,
      summary: "Marta opened the AdminPilot approval workspace",
      route_id: "saas-dashboard"
    },
    %{
      id: "activity-review-queue",
      account_id: @account.id,
      actor_id: "approver-1",
      event_type: :reviewed_queue,
      summary: "Alex reviewed pending operational approvals",
      route_id: "saas-approvals"
    },
    %{
      id: "activity-support-truth",
      account_id: @account.id,
      actor_id: "owner-1",
      event_type: :inspected_support_truth,
      summary: "Priya inspected route posture before member-access review",
      route_id: "saas-admin-member-access"
    }
  ]

  @admin_pressure %{
    id: "admin-pressure-member-access",
    account_id: @account.id,
    route_id: "saas-admin-member-access",
    label: "Sensitive member access",
    decision: "step_up_required",
    posture: "Persistent shell session does not grant admin authority",
    required_auth: "MFA and strict recent auth",
    support_label: "Sensitive route"
  }

  @digest_fields %{
    account: [:id, :name, :health, :renewal_window],
    team: [:id, :name, :member_count],
    user: [:id, :name, :role],
    role: [:id, :key, :label],
    approval: [:id, :title, :status],
    operational_record: [:id, :title, :status],
    approval_policy: [:id, :title, :required_role],
    activity_event: [:id, :event_type, :route_id]
  }

  def seed do
    %{
      account: @account,
      teams: @team,
      users: @users,
      roles: @roles,
      settings: @settings,
      approvals: @approvals,
      operational_records: @operational_records,
      approval_policies: @approval_policies,
      activity_events: @activity_events,
      admin_pressure: @admin_pressure
    }
  end

  def account, do: @account
  def team, do: @team
  def teams, do: @team
  def users, do: @users
  def roles, do: @roles
  def settings, do: @settings
  def approvals, do: @approvals
  def operational_records, do: @operational_records
  def approval_policies, do: @approval_policies
  def activity_events, do: @activity_events
  def admin_pressure, do: @admin_pressure

  def digest_components do
    [
      digest_component(:account, @account),
      Enum.map(@team, &digest_component(:team, &1)),
      Enum.map(@users, &digest_component(:user, &1)),
      Enum.map(@roles, &digest_component(:role, &1)),
      digest_component(:settings, @settings),
      Enum.map(@approvals, &digest_component(:approval, &1)),
      Enum.map(@operational_records, &digest_component(:operational_record, &1)),
      Enum.map(@approval_policies, &digest_component(:approval_policy, &1)),
      Enum.map(@activity_events, &digest_component(:activity_event, &1)),
      digest_component(:admin_pressure, @admin_pressure)
    ]
    |> List.flatten()
    |> Enum.sort()
  end

  def user!(role) when role in [:member, :approver, :owner] do
    Enum.find(@users, &(&1.role == role)) ||
      raise ArgumentError, "unknown SaaS user role: #{inspect(role)}"
  end

  def user_by_id(id) when is_binary(id) do
    Enum.find(@users, &(&1.id == id))
  end

  defp digest_component(:settings, settings) do
    "saas_admin.settings:#{settings.id}:#{settings.approval_threshold}:#{settings.member_access_review}"
  end

  defp digest_component(:admin_pressure, pressure) do
    "saas_admin.admin_pressure:#{pressure.id}:#{pressure.route_id}:#{pressure.decision}"
  end

  defp digest_component(type, record) do
    fields =
      @digest_fields
      |> Map.fetch!(type)
      |> Enum.map(&Map.fetch!(record, &1))
      |> Enum.join(":")

    "saas_admin.#{type}:#{fields}"
  end
end
