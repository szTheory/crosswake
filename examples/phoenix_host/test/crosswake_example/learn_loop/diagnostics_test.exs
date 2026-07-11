defmodule CrosswakeExample.LearnLoop.DiagnosticsTest do
  use ExUnit.Case, async: true

  @diagnostics Module.concat([CrosswakeExample, LearnLoop, Diagnostics])
  @router CrosswakeExample.Router
  @route_ids [
    "learnloop-dashboard",
    "learnloop-course",
    "learnloop-pack",
    "learnloop-study-session",
    "learnloop-history",
    "learnloop-subscription"
  ]
  @visible_labels [
    "LiveView route",
    "Cached read-only",
    "Offline island",
    "Local-first outbox",
    "Backend projection",
    "Mocked storefront evidence"
  ]
  @allowed_support_labels [
    "Available today",
    "Proof-backed example",
    "Demo pressure",
    "Advisory evidence",
    "Future gap",
    "Next-pack candidate"
  ]

  @tag :learnloop_diagnostics_route_rows
  test "LearnLoop diagnostics route rows contract derives six LearnLoop rows from compiled router metadata" do
    module =
      assert_exported!(
        @diagnostics,
        :route_policy_rows,
        1,
        "LearnLoop diagnostics route rows contract D-06/D-08/D-10/D-41 requires #{@diagnostics}.route_policy_rows/1"
      )

    assert_exported!(
      module,
      :route_ids,
      0,
      "LearnLoop diagnostics route rows contract D-41 requires route_ids/0 for drift checks"
    )

    assert apply(module, :route_ids, []) == @route_ids

    rows = apply(module, :route_policy_rows, [@router])
    assert Enum.map(rows, & &1.route_id) == @route_ids

    compiled = compiled_route_map()

    for row <- rows do
      compiled_row = Map.fetch!(compiled, row.route_id)

      assert row.path == compiled_row.route.path,
             "LearnLoop diagnostics route rows contract D-04 path drift for #{row.route_id}"

      assert row.runtime_owner == compiled_row.policy.runtime,
             "LearnLoop diagnostics route rows contract D-08/D-10 runtime owner drift for #{row.route_id}"

      assert row.offline_posture == compiled_row.policy.offline,
             "LearnLoop diagnostics route rows contract D-08/D-10 offline posture drift for #{row.route_id}"

      assert row.security_posture == compiled_row.policy.security,
             "LearnLoop diagnostics route rows contract D-41 security posture drift for #{row.route_id}"
    end

    study = Enum.find(rows, &(&1.route_id == "learnloop-study-session"))

    assert study.path == "/learnloop/study/session"
    assert study.runtime_owner == :offline_island
    assert study.offline_posture == :local_first
    assert inspect(study.packs) =~ "learnloop_daily_pack"
    assert inspect(study) =~ "Local-first outbox"

    for route_id <- @route_ids -- ["learnloop-study-session"] do
      row = Enum.find(rows, &(&1.route_id == route_id))
      assert row.runtime_owner == :live_view
      assert row.offline_posture == :cached_read_only
    end
  end

  @tag :learnloop_diagnostics_route_rows
  test "LearnLoop diagnostics enrichment contract keeps support truth allowlisted and capability pressure honest" do
    module =
      assert_exported!(
        @diagnostics,
        :allowed_support_labels,
        0,
        "LearnLoop diagnostics route rows contract D-41/D-45 requires allowed_support_labels/0"
      )

    assert_exported!(
      module,
      :guide_links,
      0,
      "LearnLoop diagnostics route rows contract D-41 requires guide_links/0"
    )

    assert_exported!(
      module,
      :capability_pressure_rows,
      0,
      "LearnLoop diagnostics route rows contract D-46 requires capability_pressure_rows/0"
    )

    assert apply(module, :allowed_support_labels, []) == @allowed_support_labels

    rows = apply(module, :route_policy_rows, [@router])
    rows_text = inspect(rows)

    for label <- @visible_labels do
      assert rows_text =~ label,
             "LearnLoop diagnostics route rows contract D-13/D-20 requires visible #{label} label"
    end

    for row <- rows do
      assert row.support_label in @allowed_support_labels
      assert is_binary(row.rough_edge) and row.rough_edge != ""
      refute row.rough_edge =~ ~r/token|secret|provider payload/i
    end

    pressure_rows = apply(module, :capability_pressure_rows, [])
    capabilities = Enum.map(pressure_rows, &Map.fetch!(&1, :capability))

    for capability <- [
          :content_pack,
          :offline_study,
          :sync_reconciliation,
          :entitlement_projection,
          :native_storage_pressure,
          :commerce_paywall_pressure
        ] do
      assert capability in capabilities,
             "LearnLoop diagnostics route rows contract D-46 requires #{inspect(capability)} capability pressure evidence"
    end

    refute inspect(pressure_rows) =~ ~r/live StoreKit|Play Billing support shipped|RevenueCat adapter|native storage shipped|generic sync engine/i,
           "LearnLoop diagnostics route rows contract D-45 rejects unsupported native/storage/storefront claims"
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

  defp assert_exported!(module, function, arity, message) do
    assert Code.ensure_loaded?(module), "#{message}; module is not loadable"
    assert function_exported?(module, function, arity), "#{message}; function is not exported"
    module
  end
end
