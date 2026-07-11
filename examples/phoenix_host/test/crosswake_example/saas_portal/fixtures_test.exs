defmodule CrosswakeExample.SaaSPortal.FixturesTest do
  use ExUnit.Case, async: true

  @fixtures Module.concat([CrosswakeExample, SaaSPortal, Fixtures])
  @required_route_ids [
    "saas-dashboard",
    "saas-approvals",
    "saas-approval",
    "saas-account",
    "saas-profile-settings",
    "saas-admin-member-access"
  ]

  @tag :fixture_density
  test "AdminPilot fixture density contract covers account, team, roles, settings, activity, and digest" do
    module =
      assert_exported!(
        @fixtures,
        :seed,
        0,
        "AdminPilot fixture density contract D-03/D-31/D-32 requires #{@fixtures}.seed/0 for #{route_ids()}"
      )

    data = apply(module, :seed, [])

    assert is_map(data),
           "AdminPilot fixture density contract D-03 requires SaaSPortal.Fixtures.seed/0 to return a map"

    account = Map.get(data, :account, %{})

    assert is_map(account) and account[:id] == "acct-north",
           "AdminPilot fixture density contract D-31 expects one deterministic Northwind account for #{route_ids()}"

    teams =
      assert_min_list(
        data,
        :teams,
        1,
        "AdminPilot fixture density contract D-03/D-31/D-32 requires at least one AdminPilot team, not broad CRUD sprawl"
      )

    assert Enum.any?(teams, &(is_map(&1) and is_binary(Map.get(&1, :name)))),
           "AdminPilot fixture density contract D-32 requires team records with visible names"

    people =
      assert_min_list(
        data,
        :users,
        3,
        "AdminPilot fixture density contract D-31 requires at least three people for member, approver, and owner role pressure"
      )

    roles =
      people
      |> Enum.filter(&is_map/1)
      |> Enum.map(&Map.get(&1, :role))
      |> Enum.reject(&is_nil/1)
      |> MapSet.new()

    assert MapSet.size(roles) >= 3,
           "AdminPilot fixture density contract D-31/D-32 requires at least three distinct roles for admin pressure"

    approvals =
      assert_min_list(
        data,
        :approvals,
        3,
        "AdminPilot fixture density contract D-31/D-33 requires at least three operational approval records"
      )

    assert Enum.any?(approvals, &(is_map(&1) and Map.get(&1, :id) == "approval-1")),
           "AdminPilot fixture density contract D-02/D-06 requires approval-1 for the dashboard -> approvals -> detail -> approve path"

    settings = Map.get(data, :settings, %{})

    assert is_map(settings) and map_size(settings) > 0,
           "AdminPilot fixture density contract D-03/D-32 requires visible settings context without a generic admin DSL"

    assert_min_list(
      data,
      :activity_events,
      2,
      "AdminPilot fixture density contract D-33 requires at least two activity events around open lane, review queue, and inspect support truth verbs"
    )

    assert Map.has_key?(data, :admin_pressure),
           "AdminPilot fixture density contract D-13/D-15/D-16 requires explicit backend-owned admin/security pressure without provider MFA or native auth claims"

    digest_module =
      assert_exported!(
        @fixtures,
        :digest_components,
        0,
        "AdminPilot fixture density contract D-34 requires #{@fixtures}.digest_components/0 for deterministic reset truth"
      )

    digest_components = apply(digest_module, :digest_components, [])

    assert is_list(digest_components) and digest_components != [],
           "AdminPilot fixture density contract D-34 requires stable digest components for deterministic reset"
  end

  defp assert_exported!(module, function, arity, message) do
    assert Code.ensure_loaded?(module), "#{message}; module is not loadable"
    assert function_exported?(module, function, arity), "#{message}; function is not exported"
    module
  end

  defp assert_min_list(data, key, minimum, message) do
    value = Map.get(data, key, [])

    assert is_list(value), "#{message}; expected #{inspect(key)} to be a list"

    assert length(value) >= minimum,
           "#{message}; expected at least #{minimum}, got #{length(value)}"

    value
  end

  defp route_ids, do: Enum.join(@required_route_ids, ", ")
end
