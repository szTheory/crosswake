defmodule Crosswake.Shell.IOSHostConfigTest do
  use ExUnit.Case, async: true

  alias Crosswake.Shell.IOSHostConfig
  alias Crosswake.Shell.IOSHostGeneration
  alias Crosswake.TestSupport.RouterFixtures.DefaultsRouter
  alias Crosswake.TestSupport.RouterFixtures.ManagedRouter

  @valid %{
    router: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
    origin: "https://study.crosswake.test",
    entry_route_id: "study-session",
    app_bundle_id: "org.crosswake.host",
    proof_app_bundle_id: "org.crosswake.host.proof",
    device_signing: [mode: :automatic, team_id: "ABCDE12345"]
  }

  test "rejects a malformed origin authority without echoing the supplied host" do
    canary = "private host value"
    assert {:error, reason} = IOSHostConfig.normalize(%{@valid | origin: "https://#{canary}"})
    assert reason =~ "origin"
    refute reason =~ canary
  end

  test "accepts only the declared host keys and unique keyword entries" do
    assert {:ok, %IOSHostConfig{router: ManagedRouter}} = IOSHostConfig.normalize(@valid)

    assert {:error, key_error} =
             IOSHostConfig.normalize(Map.put(@valid, :private_key, "secret canary"))

    refute key_error =~ "secret canary"

    duplicate = Keyword.new(Map.to_list(@valid)) ++ [origin: "https://duplicate.crosswake.test"]
    assert {:error, duplicate_error} = IOSHostConfig.normalize(duplicate)
    refute duplicate_error =~ "duplicate.crosswake.test"
  end

  test "rejects placeholder origins, malformed identities, and invalid signing input" do
    cases = [
      %{origin: "https://example.com"},
      %{app_bundle_id: "bad bundle"},
      %{proof_app_bundle_id: "org.crosswake.host.tests"},
      %{device_signing: [mode: :automatic, team_id: "team-private"]},
      %{device_signing: [mode: :automatic, team_id: "ABCDE12345", extra: "private"]}
    ]

    Enum.each(cases, fn override ->
      input = Map.merge(@valid, override)
      assert {:error, reason} = IOSHostConfig.normalize(input)
      refute reason =~ inspect(Map.to_list(override))
    end)
  end

  test "rejects a loaded module that is not a Crosswake Phoenix router" do
    assert {:error, reason} =
             IOSHostConfig.normalize(%{@valid | router: Crosswake.TestSupport.PageController})

    assert reason =~ "router"
  end

  test "compiles the selected router routes and emits route-only static entry activation" do
    assert {:ok, first} =
             IOSHostGeneration.render(%{
               config(ManagedRouter, "study-session")
               | app_bundle_id: "org.crosswake.host"
             })

    assert {:ok, second} =
             IOSHostGeneration.render(%{
               config(DefaultsRouter, "reader")
               | app_bundle_id: "org.crosswake.host"
             })

    first_manifest = Jason.decode!(first.manifest)
    second_manifest = Jason.decode!(second.manifest)
    first_activation = Jason.decode!(first.activation)
    second_activation = Jason.decode!(second.activation)

    assert Map.has_key?(first_manifest["routes"], "study-session")
    refute Map.has_key?(first_manifest["routes"], "reader")
    assert Map.has_key?(second_manifest["routes"], "reader")

    refute MapSet.equal?(
             MapSet.new(Map.keys(first_manifest["routes"])),
             MapSet.new(Map.keys(second_manifest["routes"]))
           )

    assert first_activation["route_id"] == "study-session"
    assert second_activation["route_id"] == "reader"
    assert first_activation["url"] == "https://study.crosswake.test/study-session"
    refute Map.has_key?(first_activation, "scope_ref")
    refute Map.has_key?(first_activation, "session")
    refute Map.has_key?(first_activation, "replay_authority")
  end

  test "rejects an entry that is absent from the selected router before output rendering" do
    assert {:error, reason} = IOSHostGeneration.render(config(ManagedRouter, "not-a-route"))
    assert reason =~ "entry_route_id"
  end

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
end
