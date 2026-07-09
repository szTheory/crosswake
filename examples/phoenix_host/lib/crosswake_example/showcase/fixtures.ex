defmodule CrosswakeExample.Showcase.Fixtures do
  @moduledoc """
  Deterministic foundation records for the example-host showcase reset.

  This module keeps static showcase accounting local to the example host while
  lane-specific persistence stays owned by its lane context.
  """

  alias CrosswakeExample.SaaSPortal.Fixtures, as: SaaSFixtures

  def reset_saas_admin! do
    data = SaaSFixtures.seed()

    %{
      accounts: 1,
      users: length(data.users),
      approvals: length(data.approvals)
    }
  end

  def saas_admin_digest_components do
    data = SaaSFixtures.seed()

    [
      "saas_admin.account:#{data.account.id}:#{data.account.name}:#{data.account.health}",
      data.users
      |> Enum.sort_by(& &1.id)
      |> Enum.map_join("|", &"saas_admin.user:#{&1.id}:#{&1.name}:#{&1.role}"),
      data.approvals
      |> Enum.sort_by(& &1.id)
      |> Enum.map_join("|", &"saas_admin.approval:#{&1.id}:#{&1.title}:#{&1.status}")
    ]
  end
end
