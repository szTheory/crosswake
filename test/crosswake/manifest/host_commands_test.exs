defmodule Crosswake.Manifest.HostCommandsTest do
  use ExUnit.Case, async: true

  alias Crosswake.Manifest
  alias Crosswake.Manifest.Builder
  alias Crosswake.Shell.IOSHostGeneration
  alias Crosswake.SupportMatrix
  alias Crosswake.TestSupport.HostCommandFixtures, as: Fixtures

  @origin "https://study.crosswake.test"

  # Six grammar-valid commands (host.<namespace>.<action>).
  @pool ~w(
    host.alpha.audio.play
    host.alpha.audio.stop
    host.beta.camera.scan
    host.beta.haptic.tap
    host.gamma.file.open
    host.gamma.share.sheet
  )

  defp compile!(source, opts \\ []) do
    assert {:ok, %{manifest: manifest}} =
             Manifest.compile(
               source,
               [origin: @origin, generated_at: "2026-10-14T00:00:00Z"] ++ opts
             )

    manifest
  end

  defp rendered(source), do: source |> compile!() |> Manifest.render()

  defp shuffle_subset(list, min) do
    kept = Enum.filter(list, fn _ -> :rand.uniform(2) == 1 end)
    if length(kept) < min, do: Enum.take(Enum.shuffle(list), min), else: Enum.shuffle(kept)
  end

  defp generated_route(id, runtime, capabilities) do
    %{
      path: "/#{id}",
      metadata: %{
        crosswake: [
          id: id,
          runtime: runtime,
          offline: if(runtime == :offline_island, do: :local_first, else: :unavailable),
          security: :standard,
          capabilities: capabilities
        ]
      },
      helper: id,
      verb: :get,
      source: %{file: "lib/generated_router.ex", line: 1}
    }
  end

  describe "D-10 fixed-seed generated loop (no dependency; seed {1, 2, 3})" do
    test "each route's manifest host_commands equals its own declaration across 50 route sets" do
      :rand.seed(:exsss, {1, 2, 3})

      violations =
        for iteration <- 1..50, reduce: [] do
          acc ->
            registry =
              for name <- shuffle_subset(@pool, 1) do
                {name, "1.#{:rand.uniform(4) - 1}.#{:rand.uniform(10) - 1}"}
              end

            versions = Map.new(registry)
            names = Map.keys(versions)

            routes =
              for index <- 1..(1 + :rand.uniform(4)) do
                runtime = Enum.random([:live_view, :offline_island])

                capabilities =
                  Enum.take(Enum.shuffle(names), :rand.uniform(length(names) + 1) - 1)

                {generated_route("r#{iteration}-#{index}", runtime, capabilities), capabilities}
              end

            manifest = compile!(Enum.map(routes, &elem(&1, 0)), host_commands: registry)
            rendered = manifest |> Manifest.render() |> Jason.decode!()

            mismatches =
              for {route, capabilities} <- routes,
                  id = route.metadata.crosswake[:id],
                  expected = Map.new(capabilities, &{&1, Map.fetch!(versions, &1)}),
                  rendered["routes"][id]["host_commands"] != expected,
                  do: {iteration, id, expected, rendered["routes"][id]["host_commands"]}

            mismatches ++ acc
        end

      assert violations == []
    end
  end

  describe "declaration-driven matrix (D-10)" do
    test "the real projection reports no violation for the two-declaring-route router" do
      assert Fixtures.check_matrix(
               &IOSHostGeneration.entry_host_commands/2,
               Fixtures.DeclaringRouter
             ) ==
               []
    end

    test "a projection keyed to one probe route turns the matrix red (mutation check)" do
      probe_keyed = fn manifest, _route_id -> manifest.routes["lesson"].host_commands end

      assert violations = Fixtures.check_matrix(probe_keyed, Fixtures.DeclaringRouter)

      assert violations == [
               "route plain: projected %{\"host.lesson.audio.play\" => \"1.0.0\"}, declared %{}",
               "route review: projected %{\"host.lesson.audio.play\" => \"1.0.0\"}, declared %{\"host.review.camera.scan\" => \"1.1.0\"}"
             ]
    end

    test "manifest host_commands equals each declaring route's own declaration" do
      manifest = compile!(Fixtures.DeclaringRouter)

      assert Map.new(manifest.routes, fn {id, route} -> {id, route.host_commands} end) == %{
               "lesson" => %{"host.lesson.audio.play" => "1.0.0"},
               "review" => %{"host.review.camera.scan" => "1.1.0"},
               "plain" => %{}
             }
    end

    test "two routes that declare the same command each carry it independently" do
      manifest = compile!(Fixtures.SameCommandRouter)

      assert Map.new(manifest.routes, fn {id, route} -> {id, route.host_commands} end) == %{
               "lesson" => %{"host.lesson.audio.play" => "1.0.0"},
               "practice" => %{"host.lesson.audio.play" => "1.0.0"},
               "plain" => %{}
             }
    end

    test "host_commands is always serialized as an object, empty for a non-declaring route" do
      decoded = Jason.decode!(rendered(Fixtures.DeclaringRouter))

      assert decoded["routes"]["plain"]["host_commands"] == %{}
      assert decoded["routes"]["lesson"]["capabilities"] == ["host.lesson.audio.play"]
    end
  end

  describe "determinism" do
    test "rendering the same router twice is byte-identical" do
      assert rendered(Fixtures.DeclaringRouter) == rendered(Fixtures.DeclaringRouter)
    end

    test "a router with a permuted registry order renders the same manifest bytes" do
      assert rendered(Fixtures.PermutedRegistryRouter) == rendered(Fixtures.DeclaringRouter)
    end

    test "permuting the route capability order does not change the host_commands bytes" do
      registry = [{"host.alpha.audio.play", "1.0.0"}, {"host.beta.camera.scan", "1.1.0"}]

      host_commands = fn capabilities ->
        [generated_route("probe", :live_view, capabilities)]
        |> compile!(host_commands: registry)
        |> Manifest.render()
        |> Jason.decode!()
        |> get_in(["routes", "probe", "host_commands"])
        |> Jason.encode!()
      end

      assert host_commands.(["host.alpha.audio.play", "host.beta.camera.scan"]) ==
               host_commands.(["host.beta.camera.scan", "host.alpha.audio.play"])
    end
  end

  describe "capability registry entries" do
    test "a referenced host command is a host_command family entry owned by the host" do
      manifest = compile!(Fixtures.DeclaringRouter)

      assert %{
               id: "host.lesson.audio.play",
               family: "host_command",
               owner: :host,
               version: "1.0.0",
               rebuild: :native_required
             } = manifest.capability_registry["host.lesson.audio.play"]

      assert manifest.capability_registry["host.review.camera.scan"].version == "1.1.0"
    end

    test "a declared but unreferenced command is not emitted" do
      manifest = compile!(Fixtures.UnreferencedRouter)

      assert Map.has_key?(manifest.capability_registry, "host.lesson.audio.play")
      refute Map.has_key?(manifest.capability_registry, "host.review.camera.scan")
      assert Map.keys(Jason.decode!(Manifest.render(manifest))["routes"]) == ["lesson"]
    end

    test "no support-matrix family row appears for host commands" do
      manifest = compile!(Fixtures.DeclaringRouter)
      baseline = SupportMatrix.canonical(capability_registry: Builder.capability_registry([]))

      assert manifest.support_matrix.capability_families ==
               baseline.capability_families
    end

    test "host_commands_for/2 projects only host.* entries of the route's own capabilities" do
      route = %{capabilities: ["share", "host.beta.camera.scan", "host.alpha.audio.play"]}

      registry = [
        {"host.alpha.audio.play", "1.0.0"},
        {"host.beta.camera.scan", "1.1.0"},
        {"host.gamma.file.open", "1.0.0"}
      ]

      assert Builder.host_commands_for(route, registry) == %{
               "host.alpha.audio.play" => "1.0.0",
               "host.beta.camera.scan" => "1.1.0"
             }

      assert Builder.host_commands_for(%{capabilities: ["share"]}, registry) == %{}
    end
  end

  describe "manifest schema 1.2.0 and the seam version key (D-15, D-29)" do
    test "schema is 1.2.0 while the bridge protocol stays 1.1.0" do
      manifest = compile!(Fixtures.DeclaringRouter)

      assert Crosswake.Manifest.Types.manifest_schema_version() == "1.2.0"
      assert manifest.manifest_schema_version == "1.2.0"
      assert Crosswake.Bridge.Contract.version() == "1.1.0"
    end

    test "a declaring router carries the seam version" do
      rendered = rendered(Fixtures.DeclaringRouter) |> Jason.decode!()

      assert rendered["compatibility"]["host_command_seam_version"] ==
               Crosswake.HostCommands.seam_version()

      assert rendered["compatibility"]["host_command_seam_version"] == "1.0.0"
    end

    test "a router with no host commands has no seam key" do
      rendered = rendered(Fixtures.NoRegistryRouter) |> Jason.decode!()

      refute Map.has_key?(rendered["compatibility"], "host_command_seam_version")
      assert rendered["manifest_schema_version"] == "1.2.0"
    end
  end
end
