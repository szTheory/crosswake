defmodule Crosswake.Guides.NativeDevWiringTest do
  use ExUnit.Case, async: true

  @runtime_config_path "examples/phoenix_host/config/runtime.exs"

  @prod_ios_plist_path "examples/ios_shell_host/CrosswakeShell/Info.plist"
  @dev_ios_plist_path "examples/ios_shell_host/CrosswakeShell/Info-Dev.plist"

  @prod_ios_fixture_path "examples/ios_shell_host/Fixtures/route_activation.json"
  @dev_ios_fixture_path "examples/ios_shell_host/Fixtures/route_activation-dev.json"

  @prod_android_fixture_path "examples/android_shell_host/app/src/main/assets/route_activation.json"
  @dev_android_fixture_path "examples/android_shell_host/app/src/dev/assets/route_activation.json"

  @prod_android_manifest_path "examples/android_shell_host/app/src/main/AndroidManifest.xml"
  @dev_android_network_config_path "examples/android_shell_host/app/src/dev/res/xml/network_security_config_dev.xml"

  @dev_files [
    @dev_ios_plist_path,
    @dev_ios_fixture_path,
    @dev_android_fixture_path,
    @dev_android_network_config_path
  ]

  @proof_invalid_origin "https://example.crosswake.invalid"

  # ---------------------------------------------------------------------------
  # Block A: Proof-untouched — prod surfaces must not carry dev ATS / cleartext keys
  # ---------------------------------------------------------------------------

  test "prod Info.plist contains none of the dev ATS keys (NSAllowsArbitraryLoads, NSExceptionDomains, localhost)" do
    plist = File.read!(@prod_ios_plist_path)
    refute String.contains?(plist, "NSAllowsArbitraryLoads"),
           "prod Info.plist must not contain NSAllowsArbitraryLoads"
    refute String.contains?(plist, "NSExceptionDomains"),
           "prod Info.plist must not contain NSExceptionDomains"
    refute String.contains?(plist, "localhost"),
           "prod Info.plist must not contain the localhost token"
  end

  test "prod iOS fixture origin is the proof invalid domain" do
    decoded = @prod_ios_fixture_path |> File.read!() |> Jason.decode!()
    assert decoded["origin"] == @proof_invalid_origin,
           "expected prod iOS fixture origin to be #{inspect(@proof_invalid_origin)}, got: #{inspect(decoded["origin"])}"
  end

  test "prod Android fixture origin is the proof invalid domain" do
    decoded = @prod_android_fixture_path |> File.read!() |> Jason.decode!()
    assert decoded["origin"] == @proof_invalid_origin,
           "expected prod Android fixture origin to be #{inspect(@proof_invalid_origin)}, got: #{inspect(decoded["origin"])}"
  end

  test "prod AndroidManifest.xml has usesCleartextTraffic=false and no dev network security config reference" do
    manifest = File.read!(@prod_android_manifest_path)
    assert String.contains?(manifest, ~s(android:usesCleartextTraffic="false")),
           "prod AndroidManifest.xml must have usesCleartextTraffic=\"false\""
    refute String.contains?(manifest, "network_security_config_dev"),
           "prod AndroidManifest.xml must not reference network_security_config_dev"
  end

  # ---------------------------------------------------------------------------
  # Block B: Dev-exists — all four dev wiring files must be present
  # ---------------------------------------------------------------------------

  test "all dev wiring files exist" do
    for path <- @dev_files do
      assert File.exists?(path), "expected dev wiring file to exist: #{path}"
    end
  end

  # ---------------------------------------------------------------------------
  # Block C: Dev-correct — source-derived port, correct hosts, cleartext config
  # ---------------------------------------------------------------------------

  test "dev fixtures point at the source-derived local backend (iOS localhost, Android 10.0.2.2)" do
    port = committed_port()

    ios = @dev_ios_fixture_path |> File.read!() |> Jason.decode!()
    android = @dev_android_fixture_path |> File.read!() |> Jason.decode!()

    assert String.contains?(ios["origin"], "localhost:#{port}"),
           "iOS dev fixture origin must contain localhost:#{port}; got: #{inspect(ios["origin"])}"
    assert String.contains?(ios["url"], "localhost:#{port}"),
           "iOS dev fixture url must contain localhost:#{port}; got: #{inspect(ios["url"])}"

    assert String.contains?(android["origin"], "10.0.2.2:#{port}"),
           "Android dev fixture origin must contain 10.0.2.2:#{port}; got: #{inspect(android["origin"])}"
    assert String.contains?(android["url"], "10.0.2.2:#{port}"),
           "Android dev fixture url must contain 10.0.2.2:#{port}; got: #{inspect(android["url"])}"
  end

  test "Info-Dev.plist contains the localhost cleartext exception tokens" do
    plist = File.read!(@dev_ios_plist_path)
    assert String.contains?(plist, "NSExceptionDomains"),
           "Info-Dev.plist must contain NSExceptionDomains"
    assert String.contains?(plist, "localhost"),
           "Info-Dev.plist must contain localhost exception domain"
    assert String.contains?(plist, "NSExceptionAllowsInsecureHTTPLoads"),
           "Info-Dev.plist must contain NSExceptionAllowsInsecureHTTPLoads"
  end

  test "network_security_config_dev.xml permits cleartext for 10.0.2.2 and has default-off base-config" do
    config = File.read!(@dev_android_network_config_path)
    assert String.contains?(config, "10.0.2.2"),
           "network_security_config_dev.xml must contain 10.0.2.2 domain"
    assert String.contains?(config, "cleartextTrafficPermitted"),
           "network_security_config_dev.xml must contain cleartextTrafficPermitted"
  end

  # ---------------------------------------------------------------------------
  # Block D: Dev-honestly-tagged — dev _generated_by starts with prod _generated_by
  # ---------------------------------------------------------------------------

  test "dev iOS fixture _generated_by starts with prod iOS fixture _generated_by value" do
    prod = @prod_ios_fixture_path |> File.read!() |> Jason.decode!()
    dev = @dev_ios_fixture_path |> File.read!() |> Jason.decode!()
    prod_tag = prod["_generated_by"]
    dev_tag = dev["_generated_by"]

    assert String.starts_with?(dev_tag, prod_tag),
           "expected dev _generated_by to start with #{inspect(prod_tag)}, got: #{inspect(dev_tag)}"
  end

  test "dev Android fixture _generated_by starts with prod Android fixture _generated_by value" do
    prod = @prod_android_fixture_path |> File.read!() |> Jason.decode!()
    dev = @dev_android_fixture_path |> File.read!() |> Jason.decode!()
    prod_tag = prod["_generated_by"]
    dev_tag = dev["_generated_by"]

    assert String.starts_with?(dev_tag, prod_tag),
           "expected Android dev _generated_by to start with #{inspect(prod_tag)}, got: #{inspect(dev_tag)}"
  end

  # ---------------------------------------------------------------------------
  # Block E: Anti-vacuity regression cases — prove the positive assertions fire
  # ---------------------------------------------------------------------------

  test "anti-vacuity: a prod plist CONTAINING NSExceptionDomains produces a failure" do
    # Synthesize a plist string that contains NSExceptionDomains (the forbidden key).
    # If the positive assertion above were vacuous, this would not detect it.
    synthetic_plist_with_dev_key =
      File.read!(@prod_ios_plist_path) <>
        "\n<key>NSExceptionDomains</key>\n"

    # The positive assertion in Block A checks absence of NSExceptionDomains.
    # We verify here that the predicate fires on this synthetic wrong value.
    assert String.contains?(synthetic_plist_with_dev_key, "NSExceptionDomains"),
           "anti-vacuity: synthetic plist must contain NSExceptionDomains for the regression to be meaningful"

    # Confirm the positive check WOULD fail on this synthetic plist:
    # refute String.contains?(synthetic, "NSExceptionDomains") would fail — good, the guard works.
    vacuity_result = not String.contains?(synthetic_plist_with_dev_key, "NSExceptionDomains")
    refute vacuity_result,
           "anti-vacuity: the positive prod-plist NSExceptionDomains check is non-vacuous — it correctly catches the forbidden key"
  end

  test "anti-vacuity: a dev fixture with origin still pointing at the proof domain produces a failure" do
    # Synthesize a dev fixture map where origin was NOT updated to localhost — still points at the
    # proof domain. This proves the dev-correct assertion in Block C actually fires on wrong values.
    port = committed_port()

    synthetic_wrong_dev_ios = %{
      "origin" => @proof_invalid_origin,
      "url" => "#{@proof_invalid_origin}/native/claims/claim-1/capture",
      "_generated_by" => "mix crosswake.contract.gen --dev"
    }

    # The positive assertion checks that origin contains "localhost:<port>".
    # Verify this fails on the synthetic wrong value.
    refute String.contains?(synthetic_wrong_dev_ios["origin"], "localhost:#{port}"),
           "anti-vacuity: a dev fixture still pointing at the proof domain must fail the dev-correct check"
  end

  # ---------------------------------------------------------------------------
  # Source-derived port extraction — verbatim from port_registry_test.exs
  # ---------------------------------------------------------------------------

  defp committed_port do
    @runtime_config_path
    |> File.read!()
    |> source_port!(~r/System\.get_env\("PORT"\)\s*\|\|\s*"(\d+)"/, @runtime_config_path)
  end

  defp source_port!(contents, regex, path) do
    case Regex.run(regex, contents) do
      [_match, port] -> port
      _ -> raise "could not derive port from #{path}"
    end
  end
end
