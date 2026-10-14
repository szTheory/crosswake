defmodule Crosswake.Shell.IOSHostGenerationHostCommandsTest do
  use ExUnit.Case, async: true

  alias Crosswake.Shell.IOSHostConfig
  alias Crosswake.Shell.IOSHostGeneration
  alias Crosswake.TestSupport.HostCommandFixtures, as: Fixtures

  defp config(router, entry_route_id) do
    %IOSHostConfig{
      router: router,
      origin: "https://study.crosswake.test",
      entry_route_id: entry_route_id,
      app_bundle_id: "org.crosswake.host",
      proof_app_bundle_id: "org.crosswake.host.proof",
      device_signing: %{mode: :automatic, team_id: "ABCDE12345"}
    }
  end

  defp render!(router, entry_route_id) do
    assert {:ok, rendered} = IOSHostGeneration.render(config(router, entry_route_id))
    rendered
  end

  defp activation_capabilities(rendered), do: Jason.decode!(rendered.activation)["capabilities"]

  test "each declaring route renders as entry with activation capabilities equal to its own declaration" do
    assert activation_capabilities(render!(Fixtures.DeclaringRouter, "lesson")) ==
             %{"host.lesson.audio.play" => "1.0.0"}

    assert activation_capabilities(render!(Fixtures.DeclaringRouter, "review")) ==
             %{"host.review.camera.scan" => "1.1.0"}
  end

  test "a non-declaring entry renders empty activation capabilities" do
    assert activation_capabilities(render!(Fixtures.DeclaringRouter, "plain")) == %{}
  end

  test "activation capabilities equal the manifest entry host_commands (parity) for every entry" do
    for entry <- ["lesson", "review", "plain"] do
      rendered = render!(Fixtures.DeclaringRouter, entry)
      manifest_commands = Jason.decode!(rendered.manifest)["routes"][entry]["host_commands"]

      assert activation_capabilities(rendered) == manifest_commands
      assert manifest_commands == Fixtures.declared(Fixtures.DeclaringRouter)[entry]
    end
  end

  test "the same command on two routes projects independently per entry" do
    for entry <- ["lesson", "practice"] do
      assert activation_capabilities(render!(Fixtures.SameCommandRouter, entry)) ==
               %{"host.lesson.audio.play" => "1.0.0"}
    end

    assert activation_capabilities(render!(Fixtures.SameCommandRouter, "plain")) == %{}
  end

  test "two renders of the same entry are byte-identical, and a permuted registry matches" do
    first = render!(Fixtures.DeclaringRouter, "lesson")
    second = render!(Fixtures.DeclaringRouter, "lesson")
    permuted = render!(Fixtures.PermutedRegistryRouter, "lesson")

    assert first.activation == second.activation
    assert first.activation == permuted.activation
    assert first.managed_outputs["Fixtures/route_activation.json"] == first.activation
  end

  test "entry_host_commands/2 reads only the entry route's manifest entry" do
    {:ok, %{manifest: manifest}} =
      Crosswake.Manifest.compile(Fixtures.DeclaringRouter, origin: "https://study.crosswake.test")

    assert IOSHostGeneration.entry_host_commands(manifest, "review") ==
             %{"host.review.camera.scan" => "1.1.0"}

    assert IOSHostGeneration.entry_host_commands(manifest, "plain") == %{}
  end
end
