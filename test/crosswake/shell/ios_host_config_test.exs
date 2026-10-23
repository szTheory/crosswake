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

  test "rejects malformed and out-of-range ports and canonicalizes valid authorities" do
    for origin <- [
          "https://study.crosswake.test:abc",
          "https://study.crosswake.test:",
          "https://study.crosswake.test:0",
          "https://study.crosswake.test:65536",
          "https://study.crosswake.test:443abc"
        ] do
      assert {:error, reason} = IOSHostConfig.normalize(%{@valid | origin: origin})
      assert reason =~ "origin"
    end

    assert {:ok, config} =
             IOSHostConfig.normalize(%{@valid | origin: "HTTPS://Study.Crosswake.Test:8443"})

    assert config.origin == "https://study.crosswake.test:8443"

    assert {:ok, default_port} =
             IOSHostConfig.normalize(%{@valid | origin: "https://Study.Crosswake.Test:443"})

    assert default_port.origin == "https://study.crosswake.test"
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

  describe "origin_mode :local_loopback" do
    @local_deny "invalid local origin; origin_mode :local_loopback accepts only http://127.0.0.1 or http://localhost with an optional port"
    @unknown_mode "invalid origin_mode; use :local_loopback or omit the key for HTTPS production origins"
    @prod_refusal "origin_mode :local_loopback is not accepted when MIX_ENV=prod; remove it from production config"

    defp local(origin, extra) do
      IOSHostConfig.normalize(Map.merge(%{@valid | origin: origin}, Map.new(extra)), env: :test)
    end

    defp local_mode(origin), do: local(origin, origin_mode: :local_loopback)

    test "accepts and canonicalizes only the two loopback hosts" do
      for {input, expected} <- [
            {"http://127.0.0.1", "http://127.0.0.1"},
            {"http://127.0.0.1:4790", "http://127.0.0.1:4790"},
            {"http://localhost", "http://localhost"},
            {"HTTP://LOCALHOST:80", "http://localhost"},
            {"http://127.0.0.1:04790", "http://127.0.0.1:4790"},
            {"http://localhost:4790", "http://localhost:4790"},
            {"http://127.0.0.1:80", "http://127.0.0.1"}
          ] do
        assert {:ok, %IOSHostConfig{origin: ^expected, origin_mode: :local_loopback}} =
                 local_mode(input)
      end
    end

    test "denies every non-loopback or malformed origin with the local-origin repair" do
      for origin <- [
            "http://[::1]",
            "http://[::1]:80",
            "http://0.0.0.0",
            "http://127.0.0.2",
            "http://127.1",
            "http://2130706433",
            "http://192.168.1.100",
            "http://10.0.0.1",
            "http://study.local",
            "http://127.0.0.1.evil.com",
            "http://localhost@attacker.invalid",
            "http://user:pw@127.0.0.1",
            "http://localhost.",
            "http://127.0.0.1:0",
            "http://127.0.0.1:65536",
            "http://127.0.0.1:",
            "http://127.0.0.1:80:80",
            "http://127.0.0.1/",
            "http://127.0.0.1?x=1",
            "http://127.0.0.1#f",
            "http://127.0.0.1\n",
            "http://127.0.0.1 ",
            ""
          ] do
        assert {:error, @local_deny} == local_mode(origin),
               "expected denial for #{inspect(origin)}"
      end
    end

    test "errors never echo the supplied origin" do
      for canary <- ["evil.com", "192.168.1.100", "study.local", "user:pw"] do
        assert {:error, reason} = local_mode("http://#{canary}")
        refute reason =~ canary
      end
    end

    test "https under the mode is refused with its own repair" do
      assert {:error,
              "invalid origin_mode; :local_loopback requires an http loopback origin; remove origin_mode to use an HTTPS origin"} ==
               local_mode("https://study.crosswake.test")
    end

    test "an unknown mode value is refused before the origin is parsed" do
      for mode <- [:production, "local_loopback", :other] do
        assert {:error, @unknown_mode} == local("http://evil.example", origin_mode: mode)
        assert {:error, @unknown_mode} == local("https://study.crosswake.test", origin_mode: mode)
      end
    end

    test "the mode is refused under env :prod before the origin is examined" do
      for origin <- ["http://127.0.0.1:4790", "https://study.crosswake.test", "http://evil.com"] do
        assert {:error, @prod_refusal} ==
                 IOSHostConfig.normalize(
                   %{@valid | origin: origin} |> Map.put(:origin_mode, :local_loopback),
                   env: :prod
                 )
      end
    end

    test "without the mode an http origin gets the production message with the local hint" do
      assert {:error, reason} =
               IOSHostConfig.normalize(%{@valid | origin: "http://127.0.0.1:4790"}, env: :test)

      assert String.starts_with?(
               reason,
               "invalid origin; use an absolute HTTPS origin without credentials, path, query, or fragment"
             )

      assert reason =~ "origin_mode: :local_loopback"
      assert reason =~ "http://127.0.0.1:PORT"
      assert reason =~ "http://localhost:PORT"
    end

    test "https production declarations are unchanged and normalize/1 still works" do
      assert {:ok, %IOSHostConfig{origin: "https://study.crosswake.test", origin_mode: nil}} =
               IOSHostConfig.normalize(@valid)

      assert {:error, reason} = IOSHostConfig.normalize(%{@valid | origin: "https://example.com"})
      assert reason =~ "placeholder host"
    end

    test "an unknown extra key is still rejected and a six-key struct literal builds" do
      assert {:error, reason} = IOSHostConfig.normalize(Map.put(@valid, :unknown, "x"))
      assert reason =~ "declaration keys"

      literal = %IOSHostConfig{
        router: ManagedRouter,
        origin: "https://study.crosswake.test",
        entry_route_id: "study-session",
        app_bundle_id: "org.crosswake.host",
        proof_app_bundle_id: "org.crosswake.host.proof",
        device_signing: %{mode: :automatic, team_id: "ABCDE12345"}
      }

      assert literal.origin_mode == nil
    end
  end
end
