defmodule Crosswake.Policy.HostCommandsTest do
  use ExUnit.Case, async: true

  alias Crosswake.Policy.Compiler
  alias Crosswake.Policy.Diagnostic
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
end
