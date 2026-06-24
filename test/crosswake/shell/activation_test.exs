defmodule Crosswake.Shell.ActivationTest do
  use ExUnit.Case, async: true

  alias Crosswake.Manifest.Types
  alias Crosswake.Packs.Inventory
  alias Crosswake.Shell.Activation
  alias Crosswake.Shell.Activation.Decision
  alias Crosswake.Shell.Activation.Request
  alias Crosswake.Shell.Denial
  alias Crosswake.SupportMatrix

  test "cold start, deep link, notification, and in-app navigation normalize into one activation request shape" do
    requests = [
      Activation.new_request(
        route_id: "dashboard",
        source: :cold_start,
        origin: Types.default_origin(),
        manifest_source: :bundled,
        bridge_protocol_version: "1.0.0",
        native_runtime_version: "1.0.0",
        correlation_id: "cold-start-1",
        declared_pack_requirements: %{"shell.chrome" => "1.0.0"},
        installed_packs: %{"shell.chrome" => "1.0.0"},
        capabilities: %{"app.info.get" => "1.0.0"}
      ),
      Activation.new_request(
        url: "#{Types.default_origin()}/dashboard",
        source: :deep_link,
        manifest_source: :cached,
        bridge_protocol_version: "1.0.0",
        native_runtime_version: "1.0.0",
        correlation_id: "deep-link-1",
        declared_pack_requirements: %{},
        installed_packs: %{},
        capabilities: %{}
      ),
      Activation.new_request(
        route_id: "dashboard",
        url: "#{Types.default_origin()}/dashboard",
        source: :notification,
        manifest_source: :bundled,
        bridge_protocol_version: "1.0.0",
        native_runtime_version: "1.0.0",
        correlation_id: "notification-1",
        declared_pack_requirements: %{},
        installed_packs: %{},
        capabilities: %{"haptics.impact" => "1.0.0"}
      ),
      Activation.new_request(
        route_id: "dashboard",
        source: :in_app_navigation,
        origin: Types.default_origin(),
        manifest_source: :bundled,
        bridge_protocol_version: "1.0.0",
        native_runtime_version: "1.0.0",
        correlation_id: "in-app-1",
        declared_pack_requirements: %{},
        installed_packs: %{},
        capabilities: %{"files.pick" => "1.0.0"}
      )
    ]

    assert Enum.all?(requests, &match?(%Request{}, &1))
    assert Enum.map(requests, & &1.source) == [:cold_start, :deep_link, :notification, :in_app_navigation]
    assert Enum.map(requests, & &1.manifest_source) == [:bundled, :cached, :bundled, :bundled]
    assert Enum.map(requests, & &1.bridge_protocol_version) == ["1.0.0", "1.0.0", "1.0.0", "1.0.0"]
    assert Enum.map(requests, & &1.native_runtime_version) == ["1.0.0", "1.0.0", "1.0.0", "1.0.0"]
    assert Enum.map(requests, & &1.correlation_id) == ["cold-start-1", "deep-link-1", "notification-1", "in-app-1"]
    assert Enum.at(requests, 1).origin == Types.default_origin()
  end

  test "activation resolves to explicit allow or deny before any runtime mount" do
    manifest = manifest_fixture()

    allow_decision =
      manifest
      |> Activation.resolve(
        Activation.new_request(
          route_id: "dashboard",
          source: :cold_start,
          origin: Types.default_origin(),
          manifest_source: :bundled,
          bridge_protocol_version: Crosswake.Bridge.Contract.version(),
          native_runtime_version: "1.0.0",
          correlation_id: "allow-1",
          declared_pack_requirements: %{},
          installed_packs: %{},
          capabilities: %{}
        )
      )

    deny_decision =
      manifest
      |> Activation.resolve(
        Activation.new_request(
          route_id: "missing",
          source: :deep_link,
          origin: Types.default_origin(),
          manifest_source: :bundled,
          bridge_protocol_version: "1.0.0",
          native_runtime_version: "1.0.0",
          correlation_id: "deny-1",
          declared_pack_requirements: %{},
          installed_packs: %{},
          capabilities: %{}
        )
      )

    assert %Decision{status: :allow, route_id: "dashboard", denial: nil} = allow_decision
    assert %Decision{status: :deny, route_id: "missing", denial: %Denial{reason: :inactive_route}} =
             deny_decision
  end

  test "deep-link activation denies known routes that do not allow external entry" do
    manifest = manifest_fixture()

    deny_decision =
      manifest
      |> Activation.resolve(
        Activation.new_request(
          route_id: "dashboard",
          url: "#{Types.default_origin()}/dashboard",
          source: :deep_link,
          manifest_source: :bundled,
          bridge_protocol_version: Crosswake.Bridge.Contract.version(),
          native_runtime_version: "1.0.0",
          correlation_id: "deny-entry-1",
          declared_pack_requirements: %{},
          installed_packs: %{},
          capabilities: %{}
        )
      )

    assert %Decision{
             status: :deny,
             route_id: "dashboard",
             denial: %Denial{reason: :external_entry_denied}
           } = deny_decision
  end

  test "deep-link activation matches dynamic path segments before runtime mount" do
    manifest =
      manifest_fixture()
      |> put_in(
        [Access.key!(:routes), "capture"],
        Types.new_route_entry(
          id: "capture",
          path: "/native/claims/:id/capture",
          runtime: :native_screen,
          entry: :external,
          allowlisted_origins: [Types.default_origin()]
        )
      )

    decision =
      Activation.resolve(
        manifest,
        Activation.new_request(
          url: "#{Types.default_origin()}/native/claims/claim-1/capture",
          source: :deep_link,
          manifest_source: :bundled,
          bridge_protocol_version: Crosswake.Bridge.Contract.version(),
          native_runtime_version: "1.0.0",
          correlation_id: "capture-1",
          declared_pack_requirements: %{},
          installed_packs: %{},
          capabilities: %{}
        )
      )

    assert %Decision{status: :allow, route_id: "capture"} = decision
  end

  test "denials expose stable product reasons and machine readable details" do
    reasons = [
      :compatibility_mismatch,
      :undeclared_capability,
      :unavailable_capability,
      :origin_denied,
      :inactive_route,
      :external_entry_denied,
      :pack_incompatible
    ]

    denials =
      Enum.map(reasons, fn reason ->
        Denial.new(
          reason: reason,
          route_id: "dashboard",
          message: "denied",
          details: %{axis: Atom.to_string(reason)}
        )
      end)

    assert Enum.map(denials, & &1.reason) == reasons

    assert Enum.map(denials, &Denial.to_map/1) == [
             %{
               "code" => "compatibility_mismatch",
               "details" => %{"axis" => "compatibility_mismatch"},
               "message" => "denied",
               "reason" => "compatibility_mismatch",
               "route_id" => "dashboard"
             },
             %{
               "code" => "undeclared_capability",
               "details" => %{"axis" => "undeclared_capability"},
               "message" => "denied",
               "reason" => "undeclared_capability",
               "route_id" => "dashboard"
             },
             %{
               "code" => "unavailable_capability",
               "details" => %{"axis" => "unavailable_capability"},
               "message" => "denied",
               "reason" => "unavailable_capability",
               "route_id" => "dashboard"
             },
             %{
               "code" => "origin_denied",
               "details" => %{"axis" => "origin_denied"},
               "message" => "denied",
               "reason" => "origin_denied",
               "route_id" => "dashboard"
             },
             %{
               "code" => "inactive_route",
               "details" => %{"axis" => "inactive_route"},
               "message" => "denied",
               "reason" => "inactive_route",
               "route_id" => "dashboard"
             },
             %{
               "code" => "external_entry_denied",
               "details" => %{"axis" => "external_entry_denied"},
               "message" => "denied",
               "reason" => "external_entry_denied",
               "route_id" => "dashboard"
             },
             %{
               "code" => "pack_incompatible",
               "details" => %{"axis" => "pack_incompatible"},
               "message" => "denied",
               "reason" => "pack_incompatible",
               "route_id" => "dashboard"
             }
           ]
  end

  test "activation stays fail closed until installed-pack inventory verifies as available and current" do
    manifest =
      Types.new_root(
        crosswake_version: "0.1.0",
        generated_at: "2026-05-17T00:00:00Z",
        host: Types.new_host(),
        compatibility: Types.new_compatibility(),
        support_matrix: SupportMatrix.canonical(),
        capability_registry: %{},
        routes: %{
          "library" =>
            Types.new_route_entry(
              id: "library",
              path: "/library",
              runtime: :live_view,
              offline: :cached_read_only,
              packs: ["library.bundle@1.0.0"],
              allowlisted_origins: [Types.default_origin()]
            )
        }
      )

    allow_decision =
      Activation.resolve(
        manifest,
        Activation.new_request(
          route_id: "library",
          source: :cold_start,
          origin: Types.default_origin(),
          manifest_source: :bundled,
          bridge_protocol_version: Crosswake.Bridge.Contract.version(),
          native_runtime_version: "1.0.0",
          correlation_id: "allow-library",
          installed_packs: %{
            "library.bundle" =>
              Inventory.record(
                pack_id: "library.bundle",
                required_version: "1.0.0",
                installed_version: "1.0.0",
                bytes: 8192,
                integrity_status: :verified,
                verified_at: ~U[2026-05-17 10:00:00Z]
              )
          }
        )
      )

    deny_decision =
      Activation.resolve(
        manifest,
        Activation.new_request(
          route_id: "library",
          source: :cold_start,
          origin: Types.default_origin(),
          manifest_source: :bundled,
          bridge_protocol_version: "1.0.0",
          native_runtime_version: "1.0.0",
          correlation_id: "deny-library",
          installed_packs: %{
            "library.bundle" =>
              Inventory.record(
                pack_id: "library.bundle",
                required_version: "1.0.0",
                installed_version: "1.0.0",
                bytes: 8192,
                integrity_status: :pending,
                verified_at: nil
              )
          }
        )
      )

    assert %Decision{status: :allow, route_id: "library"} = allow_decision

    assert %Decision{status: :deny, route_id: "library", denial: %Denial{reason: :pack_incompatible}} =
             deny_decision
  end

  test "commerce corridor denials stay fail closed with explicit recovery guidance" do
    manifest =
      Types.new_root(
        crosswake_version: "0.1.0",
        generated_at: "2026-05-27T00:00:00Z",
        host: Types.new_host(),
        compatibility: Types.new_compatibility(),
        support_matrix: SupportMatrix.canonical(),
        capability_registry: %{},
        commerce_corridors: %{},
        routes: %{
          "billing" =>
            Types.new_route_entry(
              id: "billing",
              path: "/billing",
              runtime: :live_view,
              offline: :unavailable,
              commerce: Types.new_route_commerce(corridor_ref: "missing_corridor", role: :purchase_intent),
              allowlisted_origins: [Types.default_origin()]
            )
        }
      )

    activation_result =
      manifest
      |> Activation.resolve(
        Activation.new_request(
          route_id: "billing",
          source: :cold_start,
          origin: Types.default_origin(),
          manifest_source: :bundled,
          bridge_protocol_version: "1.0.0",
          native_runtime_version: "1.0.0",
          correlation_id: "commerce-deny-1",
          installed_packs: %{},
          capabilities: %{}
        )
      )
      |> activation_gate_result()

    refute match?({:ok, _}, activation_result)

    assert {:error,
            %Decision{
              status: :deny,
              route_id: "billing",
              denial: %Denial{reason: :commerce_corridor, code: "commerce.corridor.undeclared"} =
                denial
            }} = activation_result

    assert denial.details[:corridor_ref] == "missing_corridor"
    assert denial.details[:role] == :purchase_intent
    assert denial.recovery != %{}
    assert denial.recovery[:fallback] == :return_to_phoenix_guidance
    assert Enum.any?(denial.recovery[:actions], &(&1 == :declare_corridor_or_disable_commerce_route))
  end

  # thread_id tests (Task 1 - 91-02)

  test "Activation.Request accepts optional thread_id defaulting to nil" do
    request =
      Activation.new_request(
        source: :cold_start,
        origin: Types.default_origin(),
        manifest_source: :bundled,
        bridge_protocol_version: "1.0.0",
        native_runtime_version: "1.0.0",
        correlation_id: "corr-act-1"
      )

    assert is_nil(request.thread_id)
  end

  test "thread_id round-trips through Activation.new_request when provided" do
    request =
      Activation.new_request(
        source: :cold_start,
        origin: Types.default_origin(),
        manifest_source: :bundled,
        bridge_protocol_version: "1.0.0",
        native_runtime_version: "1.0.0",
        correlation_id: "corr-act-2",
        thread_id: "thread-act-abc"
      )

    assert request.thread_id == "thread-act-abc"
  end

  test "Activation.Request.to_map omits thread_id when nil and includes it when present" do
    request_nil =
      Activation.new_request(
        source: :cold_start,
        origin: Types.default_origin(),
        manifest_source: :bundled,
        bridge_protocol_version: "1.0.0",
        native_runtime_version: "1.0.0",
        correlation_id: "corr-act-3"
      )

    map_nil = Activation.to_map(request_nil)
    refute Map.has_key?(map_nil, "thread_id")

    request_with =
      Activation.new_request(
        source: :cold_start,
        origin: Types.default_origin(),
        manifest_source: :bundled,
        bridge_protocol_version: "1.0.0",
        native_runtime_version: "1.0.0",
        correlation_id: "corr-act-4",
        thread_id: "t-act"
      )

    map_with = Activation.to_map(request_with)
    assert map_with["thread_id"] == "t-act"
  end

  defp activation_gate_result(%Decision{status: :allow} = decision), do: {:ok, decision}
  defp activation_gate_result(%Decision{} = decision), do: {:error, decision}

  defp manifest_fixture do
    Types.new_root(
      crosswake_version: "0.1.0",
      generated_at: "2026-05-15T00:00:00Z",
      host: Types.new_host(),
      compatibility: Types.new_compatibility(),
      support_matrix: SupportMatrix.canonical(),
      capability_registry: %{},
      routes: %{
        "dashboard" =>
          Types.new_route_entry(
            id: "dashboard",
            path: "/dashboard",
            runtime: :live_view,
            offline: :unavailable,
            entry: :internal_only,
            allowlisted_origins: [Types.default_origin()]
          )
      }
    )
  end
end
