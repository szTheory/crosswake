defmodule CrosswakeExample.SaaSPortal.Approvals do
  @moduledoc """
  Minimal approval queue surface for the Phase 7 SaaS example lane.
  """

  alias CrosswakeExample.SaaSPortal.Auth
  alias CrosswakeExample.SaaSPortal.Fixtures

  def list_approvals(account_id) when is_binary(account_id) do
    Fixtures.approvals()
    |> Enum.filter(&(&1.account_id == account_id))
  end

  def get_approval!(id) when is_binary(id) do
    Enum.find(Fixtures.approvals(), &(&1.id == id)) ||
      raise ArgumentError, "unknown SaaS approval: #{inspect(id)}"
  end

  def approve(%{account_id: account_id} = approval, %{account_id: account_id} = user) do
    if Auth.approver?(user) do
      {:ok, %{approval | status: :approved, reviewed_by: user.id}}
    else
      {:error, :forbidden}
    end
  end

  def approve(_approval, _user), do: {:error, :forbidden}
end
