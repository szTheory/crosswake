defmodule CrosswakeExample.HostCommandSeamTest do
  use ExUnit.Case, async: true

  alias Crosswake.Shell.IOSHostConfig
  alias Crosswake.Shell.IOSHostGeneration

  @command "host.study.audio.play"

  defp manifest_json do
    {:ok, %{manifest: manifest}} =
      Crosswake.Manifest.compile(CrosswakeExample.Router,
        origin: "https://study.crosswake.test",
        generated_at: "2026-10-14T00:00:00Z"
      )

    manifest |> Crosswake.Manifest.render() |> Jason.decode!()
  end

  defp config(entry_route_id) do
    %IOSHostConfig{
      router: CrosswakeExample.Router,
      origin: "https://study.crosswake.test",
      entry_route_id: entry_route_id,
      app_bundle_id: "org.crosswake.twin",
      proof_app_bundle_id: "org.crosswake.twin.proof",
      device_signing: %{mode: :automatic, team_id: "ABCDE12345"}
    }
  end

  test "offline-study carries its own host command in the compiled manifest" do
    route = manifest_json()["routes"]["offline-study"]

    assert route["runtime"] == "offline_island"
    assert route["capabilities"] == [@command]
    assert route["host_commands"] == %{@command => "1.0.0"}
  end

  test "every other route emits an empty host_commands and no host capability" do
    others = Map.delete(manifest_json()["routes"], "offline-study")

    assert map_size(others) > 0

    offenders =
      for {id, route} <- others,
          route["host_commands"] != %{} or
            Enum.filter(route["capabilities"], &String.starts_with?(&1, "host.")) != [],
          do: id

    assert offenders == []
  end

  test "the generated entry activation for offline-study carries exactly its own declaration" do
    assert {:ok, rendered} = IOSHostGeneration.render(config("offline-study"))

    assert Jason.decode!(rendered.activation)["capabilities"] == %{@command => "1.0.0"}
  end

  test "a non-declaring entry route yields empty activation capabilities" do
    assert {:ok, rendered} = IOSHostGeneration.render(config("showcase-hub"))

    assert Jason.decode!(rendered.activation)["capabilities"] == %{}
  end

  describe "generated entry activation against the compiled manifest" do
    alias Crosswake.Compatibility
    alias Crosswake.Compatibility.Target
    alias Crosswake.Shell.Activation

    defp request_from(rendered, capabilities) do
      decoded = Jason.decode!(rendered.activation)

      Activation.new_request(
        route_id: decoded["route_id"],
        url: decoded["url"],
        source: :cold_start,
        origin: decoded["origin"],
        manifest_source: :bundled,
        bridge_protocol_version: decoded["bridge_protocol_version"],
        native_runtime_version: decoded["native_runtime_version"],
        correlation_id: "seam-test",
        capabilities: capabilities
      )
    end

    defp compiled_manifest do
      {:ok, %{manifest: manifest}} =
        Crosswake.Manifest.compile(CrosswakeExample.Router,
          origin: "https://study.crosswake.test",
          generated_at: "2026-10-14T00:00:00Z"
        )

      manifest
    end

    defp findings(manifest, request) do
      Compatibility.route_findings(manifest, "offline-study", %Target{
        manifest_schema_version: Crosswake.Manifest.Types.manifest_schema_version(),
        bridge_protocol_version: request.bridge_protocol_version,
        native_runtime_version: request.native_runtime_version,
        origin: request.origin,
        manifest_source: request.manifest_source,
        capabilities: request.capabilities,
        packs: request.installed_packs
      })
    end

    test "offline-study resolves with the generated entry activation and has no capability_version finding" do
      assert {:ok, rendered} = IOSHostGeneration.render(config("offline-study"))
      manifest = compiled_manifest()
      request = request_from(rendered, Jason.decode!(rendered.activation)["capabilities"])

      assert findings(manifest, request) == []

      decision = Activation.resolve(manifest, request)
      assert decision.status == :allow
      assert decision.runtime == :offline_island
    end

    test "control: an activation lacking the declared command does produce a capability_version finding" do
      assert {:ok, rendered} = IOSHostGeneration.render(config("offline-study"))
      manifest = compiled_manifest()

      assert [%{axis: :capability_version, subject: "host.study.audio.play"}] =
               findings(manifest, request_from(rendered, %{}))
    end
  end
end
