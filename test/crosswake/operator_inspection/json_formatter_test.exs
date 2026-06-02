defmodule Crosswake.OperatorInspection.JSONFormatterTest do
  use ExUnit.Case, async: true

  alias Crosswake.OperatorInspection.JSONFormatter
  alias Crosswake.OperatorInspection.Types

  test "renders the stable inspection document shape as JSON" do
    document =
      Types.document(
        generated_at: "2026-05-31T00:00:00Z",
        crosswake_version: "0.1.0",
        source: %{
          manifest_schema_version: "1.0.0",
          bridge_protocol_version: "1.0.0",
          native_runtime_version: "0.1.0"
        },
        summary: %{
          status: :ok,
          route_count: 1,
          verification_required_count: 0,
          rebuild_required_count: 0,
          blocking_count: 0,
          finding_count: 0
        },
        routes: %{
          "dashboard" =>
            Types.route(
              id: "dashboard",
              path: "/dashboard",
              runtime: :live_view,
              entry: :internal_only,
              ownership: %{owner_plane: :phoenix, fail_closed: true},
              offline: %{mode: :unavailable, cache_contract: false, island_contract: false},
              capabilities: [],
              commerce: nil,
              companion: %{
                gated_by: nil,
                on_unavailable: nil,
                gate_state: nil,
                dependency_status: :not_applicable,
                posture: :not_applicable
              },
              auth: %{
                auth_min_level: nil,
                requires_recent_auth: nil,
                auth_posture: nil,
                readiness: :supported,
                posture: :not_applicable,
                fallback: nil,
                denial_codes: [],
                non_goals: []
              },
              notifications: %{
                token_capability_declared: false,
                provider_readiness: :not_applicable,
                posture: :not_applicable,
                supported_providers: ["apns", "fcm"],
                delivery_supported: false
              },
              support: %{
                status: :supported,
                proof_class: :merge_blocking,
                advisory_only: false,
                blocking_reasons: []
              },
              rebuild: %{native_required: false, companion_required: false, reasons: []},
              denials: [],
              conditions: [
                Types.condition(
                  type: :support_status,
                  status: true,
                  reason: :supported,
                  severity: :advisory,
                  message: "route dashboard support status is supported",
                  route_id: "dashboard",
                  details: %{support_status: :supported}
                ),
                Types.condition(
                  type: :auth_contract,
                  status: :unknown,
                  reason: :step_up_required,
                  severity: :advisory,
                  message: "contract-only auth state is unknown",
                  route_id: "dashboard",
                  details: %{fallback: :step_up_required}
                )
              ]
            )
        },
        indexes: %{
          by_runtime: %{"live_view" => ["dashboard"]},
          by_capability: %{},
          by_companion: %{},
          by_auth_predicate: %{},
          by_rebuild_requirement: %{},
          by_support_status: %{"supported" => ["dashboard"]}
        },
        findings: [],
        provenance: %{generator: "Crosswake.OperatorInspection", inputs: ["manifest"]}
      )

    json = JSONFormatter.render(document)
    decoded = Jason.decode!(json)

    assert decoded["schema_version"] == "1.0.0"
    assert decoded["routes"]["dashboard"]["runtime"] == "live_view"
    assert decoded["routes"]["dashboard"]["ownership"]["fail_closed"] == true
    assert decoded["routes"]["dashboard"]["notifications"]["delivery_supported"] == false

    assert decoded["routes"]["dashboard"]["conditions"] |> Enum.at(1) |> Map.fetch!("status") ==
             "unknown"

    assert json =~ ~s("routes")
    assert json =~ ~s("indexes")
  end
end
