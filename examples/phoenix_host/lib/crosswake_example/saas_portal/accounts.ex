defmodule CrosswakeExample.SaaSPortal.Accounts do
  @moduledoc """
  Minimal account lookup surface for the Phase 7 example lane.
  """

  alias CrosswakeExample.SaaSPortal.Fixtures

  def get_account!(id) when is_binary(id) do
    account = Fixtures.account()

    if account.id == id do
      account
    else
      raise ArgumentError, "unknown SaaS account: #{inspect(id)}"
    end
  end

  def get_account_for_user!(%{account_id: account_id}), do: get_account!(account_id)
end
