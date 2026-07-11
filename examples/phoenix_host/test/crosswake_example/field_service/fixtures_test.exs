defmodule CrosswakeExample.FieldService.FixturesTest do
  use ExUnit.Case, async: true

  @fixtures Module.concat([CrosswakeExample, FieldService, Fixtures])

  @tag :fieldserv_fixture_density
  test "Fieldserv fixture density contract covers jobs, assets, inspection, people, evidence, pressure, and digest" do
    module =
      assert_exported!(
        @fixtures,
        :seed,
        0,
        "Fieldserv fixture density contract D-04/D-05/D-10 requires #{@fixtures}.seed/0"
      )

    data = apply(module, :seed, [])

    assert is_map(data),
           "Fieldserv fixture density contract D-04 requires seed/0 to return deterministic lane data"

    jobs =
      assert_min_list(
        data,
        :jobs,
        3,
        "Fieldserv fixture density contract D-04/D-07 requires at least three realistic jobs without broad scheduling scope"
      )

    assert Enum.any?(jobs, &(Map.get(&1, :id) == "job-1")),
           "Fieldserv fixture density contract D-02 requires stable job-1 for the route-tour click path"

    assert_min_list(data, :assets, 3, "Fieldserv fixture density contract D-04 requires assets")
    assert_min_list(data, :technicians, 3, "Fieldserv fixture density contract D-04 requires technician state")
    assert_min_list(data, :notes, 3, "Fieldserv fixture density contract D-06 requires notes/activity events")

    templates =
      assert_min_list(
        data,
        :inspection_templates,
        1,
        "Fieldserv fixture density contract D-04/D-10 requires inspection template data"
      )

    assert templates
           |> List.first(%{})
           |> Map.get(:checklist_items, [])
           |> length() >= 5,
           "Fieldserv fixture density contract D-04 requires at least five checklist items"

    evidence =
      assert_min_list(
        data,
        :evidence_items,
        4,
        "Fieldserv fixture density contract D-19 requires evidence items across the backend authority ladder"
      )

    evidence_statuses = evidence |> Enum.map(&Map.get(&1, :status)) |> MapSet.new()

    for status <- [
          :device_evidence_recorded,
          :backend_verification_pending,
          :backend_verified,
          :backend_rejected
        ] do
      assert MapSet.member?(evidence_statuses, status),
             "Fieldserv fixture density contract D-19 requires evidence status #{inspect(status)}"
    end

    assert is_map(Map.get(data, :dispatcher)),
           "Fieldserv fixture density contract D-31 requires dispatcher context"

    assert is_map(Map.get(data, :adjuster)),
           "Fieldserv fixture density contract D-31 requires adjuster/reviewer context"

    assert_min_list(
      data,
      :route_postures,
      5,
      "Fieldserv fixture density contract D-25 requires route posture rows for all Fieldserv routes"
    )

    pressure =
      assert_min_list(
        data,
        :permission_pressure,
        7,
        "Fieldserv fixture density contract D-20/D-41 requires capture, scanner, document scan, permissions, media upload, offline inspection, and native rebuild pressure"
      )

    refute Enum.any?(pressure, &(Map.get(&1, :support_label) == "Available today")),
           "Fieldserv fixture density contract D-17/D-20 forbids labeling scanner/document-scan/permission pressure as shipped support"

    digest_module =
      assert_exported!(
        @fixtures,
        :digest_components,
        0,
        "Fieldserv fixture density contract D-13 requires #{@fixtures}.digest_components/0"
      )

    digest_components = apply(digest_module, :digest_components, [])

    assert is_list(digest_components) and digest_components != [],
           "Fieldserv fixture density contract D-13 requires stable digest components"

    assert Enum.all?(digest_components, &String.starts_with?(&1, "field_service.")),
           "Fieldserv fixture density contract D-13 requires lane-scoped digest components"
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
end
