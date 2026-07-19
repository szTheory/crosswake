defmodule CrosswakeExample.SaaSPortal.DiagnosticsTest do
  use ExUnit.Case, async: true

  @diagnostics Module.concat([CrosswakeExample, SaaSPortal, Diagnostics])
  @router CrosswakeExample.Router
  @route_ids [
    "saas-dashboard",
    "saas-approvals",
    "saas-approval",
    "saas-account",
    "saas-profile-settings",
    "saas-admin-member-access"
  ]
  @guide_links [
    "guides/route_policy.md",
    "guides/bridge.md",
    "guides/support_matrix.md",
    "guides/compatibility.md"
  ]

  @tag :diagnostics_route_rows
  test "AdminPilot diagnostics route rows contract derives six SaaS rows from compiled router metadata" do
    module =
      assert_exported!(
        @diagnostics,
        :route_policy_rows,
        1,
        "AdminPilot diagnostics route rows contract D-19/D-20/D-21/D-22/D-24 requires #{@diagnostics}.route_policy_rows/1"
      )

    rows = apply(module, :route_policy_rows, [@router])

    assert is_list(rows),
           "AdminPilot diagnostics route rows contract D-21 requires a list derived from Crosswake.Policy.RouterMetadata"

    assert Enum.map(rows, & &1.route_id) == @route_ids,
           "AdminPilot diagnostics route rows contract D-21/D-22 must keep route ids in router order: #{Enum.join(@route_ids, ", ")}"

    compiled = compiled_route_map()

    for row <- rows do
      compiled_row = Map.get(compiled, row.route_id)

      assert compiled_row,
             "AdminPilot diagnostics route rows contract D-21 requires #{row.route_id} to exist in compiled router metadata"

      assert row.path == compiled_row.route.path,
             "AdminPilot diagnostics route rows contract D-22 path drift for #{row.route_id}"

      assert row.runtime_owner == compiled_row.policy.runtime,
             "AdminPilot diagnostics route rows contract D-22 runtime owner drift for #{row.route_id}"

      assert row.offline_posture == compiled_row.policy.offline,
             "AdminPilot diagnostics route rows contract D-22 offline posture drift for #{row.route_id}"

      assert row.entry_posture == Map.get(compiled_row.policy, :entry),
             "AdminPilot diagnostics route rows contract D-22 entry posture drift for #{row.route_id}"

      assert row.security_posture == compiled_row.policy.security,
             "AdminPilot diagnostics route rows contract D-22 security posture drift for #{row.route_id}"

      assert normalized(row.capabilities) == normalized(compiled_row.policy.capabilities),
             "AdminPilot diagnostics route rows contract D-22 capability drift for #{row.route_id}"
    end
  end

  @tag :diagnostics_enrichment
  test "AdminPilot diagnostics enrichment contract adds support labels, rough edges, and guide links safely" do
    module =
      assert_exported!(
        @diagnostics,
        :route_policy_rows,
        1,
        "AdminPilot diagnostics enrichment contract D-19/D-20/D-23/D-24 requires #{@diagnostics}.route_policy_rows/1"
      )

    rows = apply(module, :route_policy_rows, [@router])

    for route_id <- @route_ids do
      row = Enum.find(rows, &(Map.get(&1, :route_id) == route_id))

      assert row,
             "AdminPilot diagnostics enrichment contract D-20 requires inline and panel support truth for #{route_id}"

      assert is_binary(row.support_label) and row.support_label != "",
             "AdminPilot diagnostics enrichment contract D-20/D-22 requires visible support label text for #{route_id}"

      assert is_binary(row.rough_edge) and row.rough_edge != "",
             "AdminPilot diagnostics enrichment contract D-22/D-23 requires a rough-edge note for #{route_id}"

      assert Enum.all?(row.guide_links, &(&1 in @guide_links)),
             "AdminPilot diagnostics enrichment contract D-23 requires canonical route/support guide links for #{route_id}"

      refute row.support_label =~ ~r/raw|denial|token|secret/i,
             "AdminPilot diagnostics enrichment contract D-17/T-149-03 forbids raw denial or sensitive identity dumps for #{route_id}"
    end
  end

  defp compiled_route_map do
    @router
    |> Phoenix.Router.routes()
    |> Enum.reduce(%{}, fn route, acc ->
      case Crosswake.Policy.RouterMetadata.fetch(route.metadata) do
        {:ok, policy} -> Map.put(acc, policy.id, %{route: route, policy: policy})
        :error -> acc
      end
    end)
  end

  defp normalized(capabilities) do
    capabilities
    |> List.wrap()
    |> Enum.map(&to_string/1)
    |> MapSet.new()
  end

  defp assert_exported!(module, function, arity, message) do
    assert Code.ensure_loaded?(module), "#{message}; module is not loadable"
    assert function_exported?(module, function, arity), "#{message}; function is not exported"
    module
  end
end
