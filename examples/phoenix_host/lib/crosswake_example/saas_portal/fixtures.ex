defmodule CrosswakeExample.SaaSPortal.Fixtures do
  @moduledoc """
  Minimal host-owned SaaS fixtures for the Phase 7 example lane.
  """

  @account %{
    id: "acct-north",
    name: "Northwind Workspace",
    health: :steady,
    renewal_window: "14 days",
    open_approvals: 2
  }

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
    }
  ]

  @approvals [
    %{
      id: "approval-1",
      account_id: @account.id,
      title: "Quarterly spend increase",
      status: :pending,
      requested_by: "member-1",
      reviewed_by: nil
    },
    %{
      id: "approval-2",
      account_id: @account.id,
      title: "Vendor access renewal",
      status: :pending,
      requested_by: "member-1",
      reviewed_by: nil
    },
    %{
      id: "approval-3",
      account_id: @account.id,
      title: "Contract archive export",
      status: :approved,
      requested_by: "member-1",
      reviewed_by: "approver-1"
    }
  ]

  def seed do
    %{account: @account, users: @users, approvals: @approvals}
  end

  def account, do: @account
  def users, do: @users
  def approvals, do: @approvals

  def user!(role) when role in [:member, :approver] do
    Enum.find(@users, &(&1.role == role)) ||
      raise ArgumentError, "unknown SaaS user role: #{inspect(role)}"
  end

  def user_by_id(id) when is_binary(id) do
    Enum.find(@users, &(&1.id == id))
  end
end
