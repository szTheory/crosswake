
defmodule Crosswake.Proof.Phase18DeepLinkActivationLaneTest do
  use ExUnit.Case, async: true

  alias Crosswake.Manifest
  alias Crosswake.Manifest.Types
  alias Crosswake.Shell.Activation
  alias Crosswake.Shell.Activation.Decision
  alias Crosswake.Shell.Denial
  alias Crosswake.TestSupport.RouterFixtures

  test "deep link activation stays separate from bounded bridge authorization" do
    {:ok, %{manifest: manifest}} = Manifest.compile(RouterFixtures.ManagedRouter)

    denied =
      Activation.resolve(
        manifest,
        Activation.new_request(
          url: "#{Types.default_origin()}/dashboard",
          source: :deep_link,
          manifest_source: :bundled,
          bridge_protocol_version: Crosswake.Bridge.Contract.version(),
          native_runtime_version: "1.0.0",
          correlation_id: "phase18-deep-link-denied",
          capabilities: %{
            "app_info" => "1.0.0",
            "haptics" => "1.0.0",
            "notification_token" => "1.0.0",
            "permissions.status" => "1.0.0",
            "share" => "1.0.0"
          },
          declared_pack_requirements: %{},
          installed_packs: %{}
        )
      )

    assert %Decision{
             status: :deny,
             route_id: "dashboard",
             denial: %Denial{reason: :external_entry_denied}
           } = denied

    unknown =
      Activation.resolve(
        manifest,
        Activation.new_request(
          route_id: "missing",
          url: "#{Types.default_origin()}/missing",
          source: :deep_link,
          manifest_source: :bundled,
          bridge_protocol_version: "1.0.0",
          native_runtime_version: "1.0.0",
          correlation_id: "phase18-deep-link-missing",
          declared_pack_requirements: %{},
          installed_packs: %{},
          capabilities: %{}
        )
      )

    assert %Decision{
             status: :deny,
             route_id: "missing",
             denial: %Denial{reason: :inactive_route}
           } =
             unknown
  end
end
