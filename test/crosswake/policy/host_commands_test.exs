defmodule Crosswake.Policy.HostCommandsTest do
  use ExUnit.Case, async: true

  alias Crosswake.Policy.Compiler
  alias Crosswake.Policy.Diagnostic
  alias Crosswake.Policy.Route
  alias Crosswake.Policy.Validator
  alias Crosswake.TestSupport.HostCommandFixtures, as: Fixtures

  defp capabilities(routes, id), do: Enum.find(routes, &(&1.id == id)).capabilities

  test "a declared host command referenced by name compiles" do
    assert {:ok, %{routes: routes}} = Compiler.compile(Fixtures.DeclaringRouter)
    assert "host.lesson.audio.play" in capabilities(routes, "lesson")
    assert "host.review.camera.scan" in capabilities(routes, "review")
    assert capabilities(routes, "plain") == []
  end

  test "use-option sugar compiles to the same route capabilities" do
    assert {:ok, %{routes: sugar}} = Compiler.compile(Fixtures.UseSugarRouter)
    assert {:ok, %{routes: macro}} = Compiler.compile(Fixtures.DeclaringRouter)

    assert Enum.map(sugar, &{&1.id, &1.capabilities}) ==
             Enum.map(macro, &{&1.id, &1.capabilities})

    assert Fixtures.UseSugarRouter.__crosswake_host_commands__() ==
             Fixtures.DeclaringRouter.__crosswake_host_commands__()
  end

  test "the same reference without a registry is denied" do
    assert {:error, %Diagnostic{errors: errors}} = Compiler.compile(Fixtures.NoRegistryRouter)

    assert Enum.any?(errors, fn error ->
             error.key == :capabilities and error.message =~ "host.lesson.audio.play"
           end)
  end

  defp errors_for(source, opts \\ []) do
    assert {:error, %Diagnostic{errors: errors}} = Compiler.compile(source, opts)
    errors
  end

  defp list_route(runtime, capabilities, id \\ "lesson") do
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
      helper: "route",
      verb: :get,
      source: %{file: "lib/example_router.ex", line: 7}
    }
  end

  # Hand-built Route structs carry unrelated defaults (offline, security), so these
  # direct-validator cases look only at capability errors.
  defp capability_errors(routes, opts \\ []) do
    managed = Enum.map(routes, fn _ -> %{source: %{file: "r.ex", line: 3}} end)

    routes
    |> Validator.validate(managed, opts)
    |> Enum.filter(&(&1.key == :capabilities))
  end

  @declared [{"host.lesson.audio.play", "1.0.0"}]

  test "exact declared name is accepted on live_view and offline_island" do
    for runtime <- [:live_view, :offline_island] do
      assert {:ok, _} =
               Compiler.compile([list_route(runtime, ["host.lesson.audio.play"])],
                 host_commands: @declared
               )
    end
  end

  test "native_screen and adapter runtimes are rejected with the runtime code" do
    [error] = errors_for(Fixtures.NativeScreenRouter)
    assert error.key == :capabilities
    assert error.message =~ "[crosswake.route.host_command_runtime]"
    assert error.message =~ "scan"
    assert error.message =~ "native_screen"
    assert error.hint =~ "live_view"
    assert error.hint =~ "offline_island"

    route =
      struct!(Route, id: "adapted", runtime: :adapter, capabilities: ["host.lesson.audio.play"])

    assert [adapter_error] = capability_errors([route], host_commands: @declared)

    assert adapter_error.message =~ "[crosswake.route.host_command_runtime]"
    assert adapter_error.message =~ "adapter"
    assert adapter_error.file == "r.ex"
    assert adapter_error.line == 3
  end

  test "a misspelled command gets a stable code, did-you-mean, declared list and fix line" do
    [error] = errors_for(Fixtures.MisspelledRouter)
    assert error.key == :capabilities
    assert error.message =~ "[crosswake.route.unknown_host_command]"
    assert error.message =~ ~s(route "lesson")
    assert error.message =~ "host.lesson.audio.ply"
    assert error.message =~ ~s(Did you mean "host.lesson.audio.play")
    assert error.message =~ "Declared host commands"
    assert error.hint =~ "crosswake_host_commands"
    assert error.hint =~ "capabilities:"
  end

  test "suffix and prefix neighbors of a declared id are unknown (no prefix or glob matching)" do
    for neighbor <- ["host.lesson.audio.player", "host.lesson.audio"] do
      [error] =
        errors_for([list_route(:live_view, [neighbor])], host_commands: @declared)

      assert error.message =~ "[crosswake.route.unknown_host_command]"
      assert error.message =~ neighbor
    end
  end

  test "malformed names are grammar errors naming the expected shape (validate/2)" do
    for bad <- [
          "host.Lesson.play",
          "host.lesson",
          "host.a.b.c.d.e",
          "host.lesson.*",
          "host.lessón.play"
        ] do
      route = struct!(Route, id: "r", runtime: :live_view, capabilities: [bad])
      assert [error] = capability_errors([route])
      assert error.key == :capabilities
      assert error.message =~ "host.<namespace>.<action>"
    end
  end

  test "reserved names are rejected (validate/2)" do
    for bad <- ["host.crosswake.x.y", "host.bridge.x.y"] do
      route = struct!(Route, id: "r", runtime: :live_view, capabilities: [bad])
      assert [error] = capability_errors([route])
      assert error.message =~ "reserved"
    end
  end

  test "validate/2 without a registry accepts a well-formed host command on an island" do
    route =
      struct!(Route,
        id: "offline-study",
        runtime: :offline_island,
        capabilities: ["host.study.audio.play"]
      )

    assert [] == capability_errors([route])
    assert [] == capability_errors([route], [])
  end

  test "Compiler denies host.* with an empty or absent registry" do
    for opts <- [[], [host_commands: []]] do
      [error] = errors_for([list_route(:live_view, ["host.lesson.audio.play"])], opts)
      assert error.message =~ "[crosswake.route.unknown_host_command]"
    end
  end

  test "an empty capabilities list produces no host-command error" do
    assert {:ok, _} = Compiler.compile([list_route(:live_view, [])])
  end

  test "the closed core capability set stays closed" do
    [error] = errors_for([list_route(:live_view, ["audio_playback"])], host_commands: @declared)
    assert error.message =~ ~s(unknown capability "audio_playback")
  end

  test "registry order does not change Compiler output" do
    assert Compiler.compile(Fixtures.DeclaringRouter) ==
             Compiler.compile(Fixtures.PermutedRegistryRouter)
  end
end
