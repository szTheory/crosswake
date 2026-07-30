defmodule Crosswake.CompatibilityTest do
  use ExUnit.Case, async: true

  alias Crosswake.Compatibility
  alias Crosswake.Bridge.Contract
  alias Crosswake.Compatibility.RouteGate
  alias Crosswake.Compatibility.Target
  alias Crosswake.Manifest.Types
  alias Crosswake.Packs.Inventory
  alias Crosswake.Shell.Denial
  alias Crosswake.SupportMatrix

  test "compatibility findings cover runtime, capability, and declared pack mismatches separately" do
    manifest = manifest_fixture()

    findings =
      Compatibility.route_findings(
        manifest,
        "camera",
        %Target{
          manifest_schema_version: Types.manifest_schema_version(),
          bridge_protocol_version: Contract.version(),
          native_runtime_version: "0.9.0",
          manifest_source: :bundled,
          capabilities: %{"camera" => "0.8.0"},
          packs: %{"camera.assets" => "0.9.0"},
          origin: Types.default_origin()
        }
      )

    assert Enum.map(findings, & &1.axis) |> Enum.sort() == [
             :capability_version,
             :native_runtime_version,
             :pack_version
           ]
  end

  test "route gate returns typed denial codes instead of free form strings" do
    manifest = manifest_fixture()

    decision =
      RouteGate.evaluate(
        manifest,
        "camera",
        %Target{
          manifest_schema_version: Types.manifest_schema_version(),
          bridge_protocol_version: Contract.version(),
          native_runtime_version: "1.0.0",
          manifest_source: :bundled,
          capabilities: %{"camera" => "1.0.0"},
          packs: %{"camera.assets" => "2.0.0"},
          origin: "https://untrusted.example"
        }
      )

    assert decision.status == :deny
    assert %Denial{reason: :origin_denied, route_id: "camera"} = decision.denial
    assert Enum.map(decision.denials, & &1.reason) == [:origin_denied]
  end

  test "deep link denial happens before runtime boot and exposes only safe recovery metadata" do
    manifest = manifest_fixture()

    decision =
      RouteGate.evaluate(
        manifest,
        "camera",
        %Target{
          manifest_schema_version: "1.0.0",
          bridge_protocol_version: "1.0.0",
          native_runtime_version: "1.0.0",
          manifest_source: :bundled,
          capabilities: %{"camera" => "1.0.0"},
          packs: %{},
          origin: Types.default_origin()
        },
        activation_source: :deep_link,
        fallback_route_id: "dashboard"
      )

    assert decision.status == :deny
    assert %Denial{reason: :pack_incompatible} = decision.denial

    assert decision.denial.recovery == %{
             actions: [:retry, :open_safe_fallback, :update_app],
             fallback_route_id: "dashboard",
             mode: :safe_fallback
           }
  end

  test "notification open denial happens when notification_open is absent on a notification activation" do
    manifest =
      Types.new_root(
        crosswake_version: "0.1.0",
        generated_at: "2026-05-15T00:00:00Z",
        host: Types.new_host(),
        compatibility: Types.new_compatibility(),
        support_matrix: SupportMatrix.canonical(),
        capability_registry: %{},
        routes: %{
          "external_route" =>
            Types.new_route_entry(
              id: "external_route",
              path: "/external",
              runtime: :live_view,
              entry: :external,
              offline: :unavailable,
              allowlisted_origins: [Types.default_origin()]
            )
        }
      )

    decision =
      RouteGate.evaluate(
        manifest,
        "external_route",
        %Target{
          manifest_schema_version: Types.manifest_schema_version(),
          bridge_protocol_version: Contract.version(),
          native_runtime_version: "1.0.0",
          manifest_source: :bundled,
          capabilities: %{},
          packs: %{},
          origin: Types.default_origin()
        },
        activation_source: :notification,
        fallback_route_id: "dashboard"
      )

    assert decision.status == :deny
    assert %Denial{reason: :notification_open_denied} = decision.denial
    assert decision.denial.message =~ "does not allow notification open"
  end

  test "in app navigation denial keeps the current route stable and reports an interrupting pack denial" do
    manifest = manifest_fixture()

    decision =
      RouteGate.evaluate(
        manifest,
        "camera",
        %Target{
          manifest_schema_version: "1.0.0",
          bridge_protocol_version: "1.0.0",
          native_runtime_version: "1.0.0",
          manifest_source: :bundled,
          capabilities: %{"camera" => "1.0.0"},
          packs: %{},
          origin: Types.default_origin()
        },
        activation_source: :in_app_navigation,
        current_route_id: "dashboard"
      )

    assert decision.status == :deny
    assert decision.transition == :stay_put
    assert %Denial{reason: :pack_incompatible} = decision.denial
    assert decision.denial.details == %{current_route_id: "dashboard"}
  end

  test "bridge findings fail closed on active route origin capability and pack mismatches" do
    manifest = bridge_manifest_fixture()

    findings =
      Compatibility.bridge_findings(
        manifest,
        Contract.new_request(
          command: "files.pick",
          capability: "file_picker",
          route_id: "library",
          active_route_id: "dashboard",
          origin: "https://untrusted.example",
          native_runtime_version: "0.9.0",
          correlation_id: "bridge-1",
          capabilities: %{"file_picker" => "0.9.0"},
          installed_packs: %{}
        )
      )

    assert Enum.map(findings, & &1.axis) |> Enum.sort() == [
             :active_route,
             :capability_version,
             :native_runtime_version,
             :origin,
             :pack_version
           ]
  end

  test "bridge findings reject commands outside the bounded command set" do
    manifest = bridge_manifest_fixture()

    findings =
      Compatibility.bridge_findings(
        manifest,
        Contract.new_request(
          command: "share.sheet.present",
          capability: "share.sheet.present",
          route_id: "dashboard",
          active_route_id: "dashboard",
          origin: Types.default_origin(),
          native_runtime_version: "1.0.0",
          correlation_id: "bridge-2"
        )
      )

    assert [%Compatibility.Finding{axis: :bridge_command} = finding] = findings
    assert finding.message =~ "outside the bounded Phase 3 command set"
  end

  test "bridge denials reuse the shared denial vocabulary and report pack_incompatible" do
    manifest = bridge_manifest_fixture()

    [finding] =
      Compatibility.bridge_findings(
        manifest,
        Contract.new_request(
          command: "files.pick",
          capability: "file_picker",
          route_id: "library",
          active_route_id: "library",
          origin: Types.default_origin(),
          native_runtime_version: "1.0.0",
          correlation_id: "bridge-3",
          capabilities: %{"file_picker" => "1.0.0"},
          installed_packs: %{}
        )
      )
      |> Enum.filter(&(&1.axis == :pack_version))

    denial = Compatibility.finding_to_denial(finding, route_id: "library")

    assert %Denial{reason: :pack_incompatible, route_id: "library"} = denial
  end

  test "route findings deny missing stale invalidated and unverified pack inventory through pack_incompatible posture" do
    manifest = manifest_fixture()

    states = [
      %{},
      %{
        "camera.assets" =>
          Inventory.record(
            pack_id: "camera.assets",
            required_version: "1.0.0",
            installed_version: "0.9.0",
            bytes: 2048,
            integrity_status: :verified,
            verified_at: ~U[2026-05-17 10:00:00Z]
          )
      },
      %{
        "camera.assets" =>
          Inventory.record(
            pack_id: "camera.assets",
            required_version: "1.0.0",
            installed_version: "1.0.0",
            bytes: 2048,
            integrity_status: :verified,
            verified_at: ~U[2026-05-17 10:00:00Z],
            status: :invalidating,
            invalidation_reason: :manifest_replaced,
            invalidated_at: ~U[2026-05-17 10:05:00Z],
            last_known_state: %{state: :available, version: "1.0.0"}
          )
      },
      %{
        "camera.assets" =>
          Inventory.record(
            pack_id: "camera.assets",
            required_version: "1.0.0",
            installed_version: "1.0.0",
            bytes: 2048,
            integrity_status: :pending,
            verified_at: nil
          )
      }
    ]

    for installed_packs <- states do
      findings =
        Compatibility.route_findings(
          manifest,
          "camera",
          %Target{
            manifest_schema_version: "1.0.0",
            bridge_protocol_version: "1.0.0",
            native_runtime_version: "1.0.0",
            manifest_source: :bundled,
            capabilities: %{"camera" => "1.0.0"},
            packs: installed_packs,
            origin: Types.default_origin()
          }
        )

      assert Enum.any?(findings, &(&1.axis == :pack_version))
    end
  end

  test "commerce corridor finding axes map to canonical denial codes with recovery payloads" do
    scenarios = [
      {:commerce_corridor_undeclared, "commerce.corridor.undeclared", %{corridor_ref: "subscription_default"}},
      {:commerce_corridor_unsupported, "commerce.corridor.unsupported", %{}},
      {:commerce_corridor_prerequisite_missing, "commerce.corridor.prerequisite_missing",
       %{prerequisite: "backend_entitlement_contract"}},
      {:commerce_corridor_runtime_incompatible, "commerce.corridor.runtime_incompatible",
       %{required_runtime: :native_screen, available_runtime: :live_view}},
      {:commerce_corridor_entry_denied, "commerce.corridor.entry_denied", %{}},
      {:commerce_corridor_origin_denied, "commerce.corridor.origin_denied", %{}},
      {:commerce_corridor_policy_blocked, "commerce.corridor.policy_blocked",
       %{policy: "paywall_entry", available: :native_screen}},
      {:commerce_corridor_pack_incompatible, "commerce.corridor.pack_incompatible", %{}}
    ]

    Enum.each(scenarios, fn {axis, expected_code, expected_details} ->
      finding =
        %Compatibility.Finding{
          axis: axis,
          route_id: "billing",
          required: expected_details[:policy] || expected_details[:required_runtime] || "required",
          available: expected_details[:available] || expected_details[:available_runtime] || "available",
          subject: expected_details[:corridor_ref] || expected_details[:prerequisite] || "subject",
          message: "commerce corridor denied",
          hint: "explicit remediation"
        }

      denial =
        Compatibility.finding_to_denial(
          finding,
          route_id: "billing",
          activation_source: :deep_link
        )

      assert denial.reason == :commerce_corridor
      assert denial.code == expected_code
      assert denial.recovery != %{}
      assert denial.recovery[:fallback] == :return_to_phoenix_guidance
      assert Denial.to_map(denial)["recovery"] != %{}

      Enum.each(expected_details, fn {key, value} ->
        assert denial.details[key] == value
      end)
    end)
  end

  test "route gate emits runtime_incompatible and policy_blocked corridor denials deterministically" do
    runtime_incompatible_decision =
      RouteGate.evaluate(
        commerce_manifest_fixture(
          route_runtime: :live_view,
          route_role: :purchase_intent
        ),
        "billing",
        %Target{
          manifest_schema_version: "1.0.0",
          bridge_protocol_version: "1.0.0",
          native_runtime_version: "1.0.0",
          manifest_source: :bundled,
          origin: Types.default_origin(),
          capabilities: %{},
          packs: %{}
        }
      )

    policy_blocked_decision =
      RouteGate.evaluate(
        commerce_manifest_fixture(
          route_runtime: :native_screen,
          route_role: :paywall_entry
        ),
        "billing",
        %Target{
          manifest_schema_version: "1.0.0",
          bridge_protocol_version: "1.0.0",
          native_runtime_version: "1.0.0",
          manifest_source: :bundled,
          origin: Types.default_origin(),
          capabilities: %{},
          packs: %{}
        }
      )

    assert runtime_incompatible_decision.status == :deny

    assert Enum.any?(runtime_incompatible_decision.denials, fn denial ->
             denial.code == "commerce.corridor.runtime_incompatible" and
               denial.reason == :commerce_corridor
           end)

    assert policy_blocked_decision.status == :deny

    assert Enum.any?(policy_blocked_decision.denials, fn denial ->
             denial.code == "commerce.corridor.policy_blocked" and
               denial.reason == :commerce_corridor
           end)
  end

  # D-137-A / D-137-B: auth Finding→Denial translation and base_details guard

  test "finding_to_denial on an :auth Finding returns :step_up_required with details UNMERGED" do
    finding = %Compatibility.Finding{
      axis: :auth,
      message: "stale authentication — step-up required",
      code: "auth.step_up.stale_auth",
      details: %{"max_auth_age_seconds" => 300}
    }

    denial = Compatibility.finding_to_denial(finding, route_id: "secure")

    assert denial.reason == :step_up_required
    assert denial.code == "auth.step_up.stale_auth"
    assert denial.details == %{"max_auth_age_seconds" => 300}
    # :axis must NOT be injected into already-sanitized auth details (audit fix ①)
    refute Map.has_key?(denial.details, :axis)
    refute Map.has_key?(denial.details, "axis")
  end

  test "finding_to_denial on an :auth Finding with nil code falls back to string reason" do
    finding = %Compatibility.Finding{
      axis: :auth,
      message: "auth denied",
      code: nil,
      details: %{}
    }

    denial = Compatibility.finding_to_denial(finding, route_id: "secure")

    assert denial.reason == :step_up_required
    # nil code downgrades to Atom.to_string(reason) — documented nil-code downgrade (T-137-03)
    assert denial.code == "step_up_required"
  end

  test "Finding struct builds without :code/:details and existing non-auth axes are unchanged" do
    # :code defaults nil, :details defaults %{} — additive, non-breaking
    finding = %Compatibility.Finding{axis: :route, message: "route inactive"}
    assert finding.code == nil
    assert finding.details == %{}

    # Non-auth axis translation is unchanged
    denial = Compatibility.finding_to_denial(finding, route_id: "camera")
    assert denial.reason == :inactive_route
    # Non-auth finding still gets base_details merged (includes :axis)
    assert denial.details[:axis] == :route
  end

  test "compatibility guide keeps package versions separate from runtime axes" do
    guide = File.read!("guides/compatibility.md")

    assert guide =~ "Package Versions Versus Compatibility Axes"
    assert guide =~ "Companion Compatibility Contract"
    assert guide =~ "Release Choreography"
    assert guide =~ "Runtime Line Rules"
    assert guide =~ "package versions alone"
    assert guide =~ "manifest_schema_version"
    assert guide =~ "bridge_protocol_version"
    assert guide =~ "native_runtime_version"
    assert guide =~ "minimum compatible ranges"
  end

  defp manifest_fixture do
    Types.new_root(
      crosswake_version: "0.1.0",
      generated_at: "2026-05-15T00:00:00Z",
      host: Types.new_host(),
      compatibility: Types.new_compatibility(),
      support_matrix: SupportMatrix.canonical(),
      capability_registry: %{
        "camera" => Types.new_capability(id: "camera", version: "1.0.0")
      },
      routes: %{
        "dashboard" =>
          Types.new_route_entry(
            id: "dashboard",
            path: "/dashboard",
            runtime: :live_view,
            offline: :unavailable,
            allowlisted_origins: [Types.default_origin()]
          ),
        "camera" =>
          Types.new_route_entry(
            id: "camera",
            path: "/camera",
            runtime: :native_screen,
            offline: :unavailable,
            capabilities: ["camera"],
            packs: ["camera.assets@1.0.0"],
            security: :sensitive,
            allowlisted_origins: [Types.default_origin()]
          )
      }
    )
  end

  defp bridge_manifest_fixture do
    Types.new_root(
      crosswake_version: "0.1.0",
      generated_at: "2026-05-16T00:00:00Z",
      host: Types.new_host(),
      compatibility:
        Types.new_compatibility(
          native_runtime_version: "1.0.0",
          bridge_protocol_version: "1.0.0"
        ),
      support_matrix: SupportMatrix.canonical(),
      capability_registry: %{
        "app.info.get" => Types.new_capability(id: "app.info.get", version: "1.0.0"),
        "file_picker" => Types.new_capability(id: "file_picker", version: "1.0.0")
      },
      routes: %{
        "dashboard" =>
          Types.new_route_entry(
            id: "dashboard",
            path: "/dashboard",
            runtime: :live_view,
            offline: :unavailable,
            capabilities: ["app.info.get"],
            allowlisted_origins: [Types.default_origin()]
          ),
        "library" =>
          Types.new_route_entry(
            id: "library",
            path: "/library",
            runtime: :live_view,
            offline: :cached_read_only,
            capabilities: ["file_picker"],
            packs: ["library.bundle@1.0.0"],
            allowlisted_origins: [Types.default_origin()]
          )
      }
    )
  end

  defp commerce_manifest_fixture(opts) do
    route_runtime = Keyword.get(opts, :route_runtime, :live_view)
    route_role = Keyword.get(opts, :route_role, :purchase_intent)

    Types.new_root(
      crosswake_version: "0.1.0",
      generated_at: "2026-05-27T00:00:00Z",
      host: Types.new_host(),
      compatibility: Types.new_compatibility(),
      support_matrix: SupportMatrix.canonical(),
      capability_registry: %{},
      commerce_corridors: %{
        "subscription_default" =>
          Types.new_commerce_corridor(
            id: "subscription_default",
            role_ownership: %{
              paywall_entry: :phoenix_owned,
              purchase_intent: :native_or_companion_required,
              restore_intent: :native_or_companion_required,
              account_management: :phoenix_owned
            },
            denial: "commerce.corridor.unsupported",
            fallback: "return_to_phoenix_guidance",
            prerequisites: ["backend_entitlement_contract"]
          )
      },
      routes: %{
        "billing" =>
          Types.new_route_entry(
            id: "billing",
            path: "/billing",
            runtime: route_runtime,
            offline: :unavailable,
            commerce: Types.new_route_commerce(corridor_ref: "subscription_default", role: route_role),
            allowlisted_origins: [Types.default_origin()]
          )
      }
    )
  end
end
