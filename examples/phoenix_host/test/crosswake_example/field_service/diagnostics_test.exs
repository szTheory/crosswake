defmodule CrosswakeExample.FieldService.DiagnosticsTest do
  use ExUnit.Case, async: true

  @diagnostics Module.concat([CrosswakeExample, FieldService, Diagnostics])
  @router CrosswakeExample.Router
  @route_ids [
    "fieldserv-jobs",
    "fieldserv-job",
    "fieldserv-inspection",
    "fieldserv-job-capture",
    "fieldserv-evidence-review"
  ]
  @allowed_support_labels [
    "Available today",
    "Proof-backed example",
    "Demo pressure",
    "Future gap",
    "Next-pack candidate"
  ]

  @tag :fieldserv_diagnostics_route_rows
  test "Fieldserv diagnostics route rows contract derives five Fieldserv rows from compiled router metadata" do
    module =
      assert_exported!(
        @diagnostics,
        :route_policy_rows,
        1,
        "Fieldserv diagnostics route rows contract D-15/D-16/D-20/D-25 requires #{@diagnostics}.route_policy_rows/1"
      )

    assert_exported!(
      module,
      :route_ids,
      0,
      "Fieldserv diagnostics route rows contract D-37 requires route_ids/0 for drift checks"
    )

    assert apply(module, :route_ids, []) == @route_ids

    rows = apply(module, :route_policy_rows, [@router])
    assert Enum.map(rows, & &1.route_id) == @route_ids

    compiled = compiled_route_map()

    for row <- rows do
      compiled_row = Map.fetch!(compiled, row.route_id)

      assert row.path == compiled_row.route.path,
             "Fieldserv diagnostics route rows contract D-37 path drift for #{row.route_id}"

      assert row.runtime_owner == compiled_row.policy.runtime,
             "Fieldserv diagnostics route rows contract D-15/D-25 runtime owner drift for #{row.route_id}"

      assert row.offline_posture == compiled_row.policy.offline,
             "Fieldserv diagnostics route rows contract D-23 offline posture drift for #{row.route_id}"

      assert row.security_posture == compiled_row.policy.security,
             "Fieldserv diagnostics route rows contract D-16 security posture drift for #{row.route_id}"

      assert normalized(row.capabilities) == normalized(compiled_row.policy.capabilities),
             "Fieldserv diagnostics route rows contract D-16 capability drift for #{row.route_id}"
    end

    capture = Enum.find(rows, &(&1.route_id == "fieldserv-job-capture"))

    assert capture.runtime_owner == :native_screen
    assert capture.offline_posture == :cached_read_only
    assert capture.security_posture == :sensitive
    assert "camera" in Enum.map(capture.capabilities, &to_string/1)
    assert inspect(capture.packs) =~ "camera_capture_assets"
    assert inspect(capture.transfers) =~ "native_capture"
    assert inspect(capture.transfers) =~ "required"
  end

  @tag :fieldserv_diagnostics_enrichment
  test "Fieldserv diagnostics enrichment contract keeps support labels allowlisted and native/offline gaps honest" do
    module =
      assert_exported!(
        @diagnostics,
        :capability_map_rows,
        0,
        "Fieldserv diagnostics enrichment contract D-20/D-41 requires capability_map_rows/0"
      )

    assert_exported!(
      module,
      :allowed_support_labels,
      0,
      "Fieldserv diagnostics enrichment contract D-20 requires allowed_support_labels/0"
    )

    rows = apply(module, :route_policy_rows, [@router])

    for row <- rows do
      assert row.support_label in @allowed_support_labels
      assert is_binary(row.rough_edge) and row.rough_edge != ""
      refute row.rough_edge =~ ~r/token|secret|provider payload/i
    end

    capability_rows = apply(module, :capability_map_rows, [])
    capabilities = Enum.map(capability_rows, &Map.fetch!(&1, :capability))

    for capability <- [
          :capture,
          :scanner,
          :document_scan,
          :permissions,
          :media_upload,
          :offline_inspection,
          :native_rebuild
        ] do
      assert capability in capabilities,
             "Fieldserv diagnostics enrichment contract D-41 requires #{inspect(capability)} capability-map evidence"
    end

    refute Enum.any?(capability_rows, &(Map.get(&1, :support_label) == "Available today")),
           "Fieldserv diagnostics enrichment contract D-20/D-41 forbids missing native controls from being labeled shipped"
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
