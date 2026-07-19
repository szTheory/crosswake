defmodule CrosswakeExample.SaaSPortal.Accounts do
  @moduledoc """
  Read-only account context for the AdminPilot SaaS/admin showcase lane.
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

  def account_summary!(account_or_id) do
    account = account_or_id |> account_id_for() |> get_account!()

    %{
      id: account.id,
      name: account.name,
      health: account.health,
      plan: account.plan,
      renewal_window: account.renewal_window,
      open_approvals: account.open_approvals,
      member_count: account_member_count(account.id),
      team_count: account_team_count(account.id),
      role_count: length(Fixtures.roles()),
      cached_read_posture: Fixtures.settings().cached_read_posture
    }
  end

  def team_for_account!(account_or_id) do
    account_id = account_id_for(account_or_id)
    get_account!(account_id)

    Fixtures.teams()
    |> Enum.find(&(&1.account_id == account_id))
    |> case do
      nil -> raise ArgumentError, "unknown SaaS team for account: #{inspect(account_id)}"
      team -> team
    end
  end

  def role_summary(%{role: role}), do: role_summary(role)

  def role_summary(role) when is_atom(role) do
    role_record =
      Fixtures.roles()
      |> Enum.find(&(&1.key == role))
      |> case do
        nil -> raise ArgumentError, "unknown SaaS role: #{inspect(role)}"
        role_record -> role_record
      end

    members = Enum.filter(Fixtures.users(), &(&1.role == role))

    role_record
    |> Map.put(:members, members)
    |> Map.put(:member_count, length(members))
  end

  def settings_for_account!(account_or_id) do
    account_id = account_id_for(account_or_id)
    get_account!(account_id)

    settings = Fixtures.settings()

    if settings.account_id == account_id do
      settings
    else
      raise ArgumentError, "unknown SaaS settings for account: #{inspect(account_id)}"
    end
  end

  def activity_context_for_account!(account_or_id) do
    account_id = account_id_for(account_or_id)
    get_account!(account_id)

    %{
      operational_records: filter_account(Fixtures.operational_records(), account_id),
      approval_policies: Fixtures.approval_policies(),
      activity_events: filter_account(Fixtures.activity_events(), account_id),
      admin_pressure: Fixtures.admin_pressure()
    }
  end

  defp account_id_for(%{account_id: account_id}) when is_binary(account_id), do: account_id
  defp account_id_for(%{id: account_id}) when is_binary(account_id), do: account_id
  defp account_id_for(account_id) when is_binary(account_id), do: account_id

  defp account_member_count(account_id) do
    Fixtures.users()
    |> filter_account(account_id)
    |> length()
  end

  defp account_team_count(account_id) do
    Fixtures.teams()
    |> filter_account(account_id)
    |> length()
  end

  defp filter_account(records, account_id) do
    Enum.filter(records, &(&1.account_id == account_id))
  end
end
