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
end
