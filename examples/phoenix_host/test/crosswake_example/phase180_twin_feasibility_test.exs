defmodule CrosswakeExample.Phase180TwinFeasibilityTest do
  use ExUnit.Case, async: true

  # Phase 180 feasibility gate facts G2, G6 and the declaration-driven invariants.
  # Characterization only; synthetic public values; no Repo.

  @command "host.study.audio.play"
  @origin "https://study.crosswake.test"
  @probe System.get_env("PHASE180_PROBE_ROUTE", "offline-study")

  defp config(entry) do
    %Crosswake.Shell.IOSHostConfig{
      router: CrosswakeExample.Router,
      origin: @origin,
      entry_route_id: entry,
      app_bundle_id: "org.crosswake.twin",
      proof_app_bundle_id: "org.crosswake.twin.proof",
      device_signing: %{mode: :automatic, team_id: "ABCDE12345"}
    }
  end

  defp manifest_map do
    {:ok, %{manifest: manifest}} =
      Crosswake.Manifest.compile(CrosswakeExample.Router, origin: @origin)

    manifest |> Crosswake.Manifest.render() |> Jason.decode!()
  end

  defp activation_capabilities(bytes) do
    bytes |> Jason.decode!() |> Map.fetch!("capabilities")
  end

  defp host_keys(map),
    do: map |> Map.keys() |> Enum.filter(&String.starts_with?(&1, "host.")) |> MapSet.new()

  defp declared_host(manifest, id) do
    manifest["routes"][id]["capabilities"]
    |> List.wrap()
    |> Enum.filter(&String.starts_with?(&1, "host."))
    |> MapSet.new()
  end

  @tag phase180_gate: "G6"
  test "G6 gate: no compiled route declares a host capability" do
    manifest = manifest_map()

    assert map_size(manifest["routes"]) > 0

    for {_id, route} <- manifest["routes"] do
      refute Enum.any?(route["capabilities"] || [], &String.starts_with?(&1, "host."))
    end

    assert manifest["routes"]["offline-study"]["runtime"] == "offline_island"
  end

  @tag phase180_control: "G6"
  test "G6 control: the scan reads real declared capabilities" do
    manifest = manifest_map()
    assert Enum.any?(manifest["routes"], fn {_id, r} -> (r["capabilities"] || []) != [] end)
  end

  @tag phase180_gate: "G2"
  test "G2 gate: generated activation for the probe carries no host command" do
    assert {:ok, out} = Crosswake.Shell.IOSHostGeneration.render(config(@probe))
    refute Map.has_key?(activation_capabilities(out.activation), @command)
  end

  @tag phase180_control: "G2"
  test "G2 control: the activation path can show a carried host command" do
    activation =
      Crosswake.Shell.Activation.new_request(
        route_id: @probe,
        url: @origin <> "/offline",
        source: :cold_start,
        origin: @origin,
        manifest_source: :bundled,
        bridge_protocol_version: Crosswake.Bridge.Contract.version(),
        native_runtime_version: "1.0.0",
        correlation_id: "ios-build-entry",
        capabilities: %{@command => "1.0.0"}
      )

    bytes = Jason.encode!(Crosswake.Shell.Activation.to_map(activation), pretty: true) <> "\n"
    assert activation_capabilities(bytes) == %{@command => "1.0.0"}
    assert {:ok, _} = Crosswake.Shell.IOSHostGeneration.render(config(@probe))
  end

  @tag phase180_export: "probe"
  test "probe export: write generated activation and manifest bytes" do
    assert {:ok, out} = Crosswake.Shell.IOSHostGeneration.render(config(@probe))
    dir = Path.join(["_build", "phase180", "probe"])
    File.mkdir_p!(dir)
    File.write!(Path.join(dir, "route_activation.json"), out.activation)
    File.write!(Path.join(dir, "crosswake_manifest.json"), out.manifest)
    assert File.read!(Path.join(dir, "route_activation.json")) == out.activation
    assert File.read!(Path.join(dir, "crosswake_manifest.json")) == out.manifest
  end

  @tag phase180_invariant: "G2_nondeclaring_clean"
  test "G2 invariant: a non-declaring route renders no host key" do
    manifest = manifest_map()

    candidates =
      manifest["routes"]
      |> Map.keys()
      |> Enum.sort()
      |> Enum.reject(&(&1 == @probe))
      |> Enum.filter(&(MapSet.size(declared_host(manifest, &1)) == 0))

    caps =
      Enum.find_value(candidates, fn id ->
        case Crosswake.Shell.IOSHostGeneration.render(config(id)) do
          {:ok, out} -> activation_capabilities(out.activation)
          _ -> nil
        end
      end)

    if is_nil(caps), do: flunk("no non-declaring route rendered")
    assert MapSet.size(host_keys(caps)) == 0
  end

  @tag phase180_invariant: "G2_probe_matches_declaration"
  test "G2 invariant: probe host keys equal its own declared host list" do
    manifest = manifest_map()
    assert {:ok, out} = Crosswake.Shell.IOSHostGeneration.render(config(@probe))
    declared = declared_host(manifest, @probe)
    assert host_keys(activation_capabilities(out.activation)) == declared

    if System.get_env("PHASE180_BASE_KIND") == "authorized_seam_rerun" do
      assert MapSet.member?(declared, @command)
    end
  end
end
