defmodule Crosswake.Manifest.HostCommandSeamFixtureTest do
  use ExUnit.Case, async: true

  alias Crosswake.Shell.IOSHostConfig
  alias Crosswake.Shell.IOSHostGeneration
  alias Crosswake.TestSupport.HostCommandFixtures.DeclaringRouter

  @origin "https://seam.crosswake.test"
  @generated_at "2026-10-14T00:00:00Z"
  @fixture Path.expand(
             "../../../packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/host_command_seam_fixture.json",
             __DIR__
           )

  defp config(entry_route_id) do
    %IOSHostConfig{
      router: DeclaringRouter,
      origin: @origin,
      entry_route_id: entry_route_id,
      app_bundle_id: "org.crosswake.host",
      proof_app_bundle_id: "org.crosswake.host.proof",
      device_signing: %{mode: :automatic, team_id: "ABCDE12345"}
    }
  end

  defp render!(entry_route_id) do
    assert {:ok, rendered} =
             IOSHostGeneration.render(config(entry_route_id), generated_at: @generated_at)

    rendered
  end

  # Sorted-key ordered object so the committed bytes never depend on map iteration order.
  defp sorted(map) when is_map(map) do
    values = map |> Enum.sort_by(&elem(&1, 0)) |> Enum.map(fn {k, v} -> {k, sorted(v)} end)
    %Jason.OrderedObject{values: values}
  end

  defp sorted(list) when is_list(list), do: Enum.map(list, &sorted/1)
  defp sorted(other), do: other

  defp legacy(manifest) do
    routes =
      Map.new(manifest["routes"], fn {id, route} -> {id, Map.delete(route, "host_commands")} end)

    manifest
    |> Map.put("routes", routes)
    |> update_in(["compatibility"], &Map.delete(&1, "host_command_seam_version"))
  end

  defp expected_bytes do
    manifest = render!("lesson").manifest |> Jason.decode!()

    activations =
      Map.new(["lesson", "review", "plain"], fn id ->
        {id, render!(id).activation |> Jason.decode!()}
      end)

    document = %{
      "manifest" => manifest,
      "activations" => activations,
      "legacy_manifest" => legacy(manifest)
    }

    Jason.encode!(sorted(document), pretty: true) <> "\n"
  end

  test "committed Swift seam fixture is byte-identical to a fresh Elixir render" do
    bytes = expected_bytes()

    if System.get_env("CROSSWAKE_WRITE_SEAM_FIXTURE") == "1" do
      File.write!(@fixture, bytes)
    end

    assert File.read!(@fixture) == bytes
  end

  test "fixture shape: legacy manifest has no seam fields, activations match declarations" do
    decoded = Jason.decode!(expected_bytes())

    assert decoded["manifest"]["compatibility"]["host_command_seam_version"] == "1.0.0"
    assert decoded["manifest"]["routes"]["plain"]["host_commands"] == %{}

    assert decoded["activations"]["review"]["capabilities"] == %{
             "host.review.camera.scan" => "1.1.0"
           }

    refute Map.has_key?(decoded["legacy_manifest"]["compatibility"], "host_command_seam_version")
    refute Map.has_key?(decoded["legacy_manifest"]["routes"]["lesson"], "host_commands")
  end
end
