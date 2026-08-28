defmodule Crosswake.Proof.Phase164DependencySecurityAndGateAuthorityTest do
  @moduledoc """
  SEC-01..03: dependency security has two independently audited lock authorities,
  one inactive advisory-bearing negative control, and one literal CI producer.
  """
  use ExUnit.Case, async: true

  @script "script/check_dependency_security.sh"
  @fixture "test/fixtures/security/advisory-bearing.lock"

  @root_targets %{
    "phoenix" => "1.8.13",
    "phoenix_live_view" => "1.1.33",
    "plug" => "1.19.5",
    "plug_crypto" => "2.2.0"
  }

  @example_targets %{
    "bandit" => "1.12.5",
    "hpax" => "1.0.4",
    "phoenix" => "1.8.13",
    "phoenix_live_view" => "1.1.33",
    "plug" => "1.19.5",
    "plug_crypto" => "2.2.0"
  }

  test "canonical locks resolve the exact patched targets inside unchanged public ranges" do
    assert lock_versions("mix.lock", Map.keys(@root_targets)) == @root_targets

    assert lock_versions("examples/phoenix_host/mix.lock", Map.keys(@example_targets)) ==
             @example_targets

    root_manifest = File.read!("mix.exs")
    example_manifest = File.read!("examples/phoenix_host/mix.exs")

    assert root_manifest =~ ~s({:phoenix, "~> 1.8"})
    assert root_manifest =~ ~s({:phoenix_live_view, "~> 1.1"})
    assert example_manifest =~ ~s({:phoenix, "~> 1.8"})
    assert example_manifest =~ ~s({:phoenix_live_view, "~> 1.1"})
    assert example_manifest =~ ~s({:plug, "~> 1.16"})
    assert example_manifest =~ ~s({:bandit, "~> 1.0"})
  end

  @tag :tmp_dir
  test "canonical mode runs both audits and fails closed after the first audit fails", %{
    tmp_dir: tmp
  } do
    fixture_root = Path.join(tmp, "repo")
    fake_bin = Path.join(tmp, "bin")
    audit_log = Path.join(tmp, "audit.log")

    File.mkdir_p!(Path.join(fixture_root, "script"))
    File.mkdir_p!(Path.join(fixture_root, "examples/phoenix_host"))
    File.mkdir_p!(fake_bin)
    File.cp!(@script, Path.join(fixture_root, @script))
    File.write!(Path.join(fixture_root, "mix.lock"), "%{fixture: :root}\n")
    File.write!(Path.join(fixture_root, "examples/phoenix_host/mix.lock"), "%{fixture: :example}\n")

    fake_mix = Path.join(fake_bin, "mix")

    File.write!(fake_mix, """
    #!/usr/bin/env bash
    printf '%s\\n' "$PWD" >> "$AUDIT_LOG"
    if [ "$PWD" = "$FAIL_AUDIT_DIR" ]; then
      echo 'Package  Advisory  Patched in'
      echo 'phoenix  EEF-CVE-fixture  1.8.13'
      exit 1
    fi
    echo 'No retired packages found'
    """)

    File.chmod!(fake_mix, 0o755)

    env = [
      {"PATH", fake_bin <> ":" <> System.get_env("PATH")},
      {"AUDIT_LOG", audit_log},
      {"FAIL_AUDIT_DIR", fixture_root}
    ]

    {output, status} =
      System.cmd("bash", [@script],
        cd: fixture_root,
        env: env,
        stderr_to_stdout: true
      )

    assert status != 0

    assert File.read!(audit_log) |> String.split("\n", trim: true) == [
             fixture_root,
             Path.join(fixture_root, "examples/phoenix_host")
           ]

    assert output =~ "mix.lock"
    assert output =~ "phoenix"
    assert output =~ "mix deps.update phoenix"
    refute output =~ "AUDIT_LOG"
    refute output =~ "FAIL_AUDIT_DIR"
  end

  test "inactive advisory fixture is rejected with bounded actionable output" do
    {output, status} =
      System.cmd("bash", [@script, "--assert-vulnerable-fixture", @fixture],
        stderr_to_stdout: true
      )

    assert status == 0
    assert output =~ @fixture
    assert output =~ "phoenix"
    assert output =~ "mix deps.update phoenix"

    for forbidden <- [
          "credential",
          "environment",
          "token",
          "account",
          "device",
          "payload",
          "First B2C Adopter"
        ] do
      refute output =~ forbidden
    end
  end

  @tag :tmp_dir
  test "missing lock input fails before an audit can report a vacuous pass", %{tmp_dir: tmp} do
    fixture_root = Path.join(tmp, "repo")
    File.mkdir_p!(Path.join(fixture_root, "script"))
    File.mkdir_p!(Path.join(fixture_root, "examples/phoenix_host"))
    File.cp!(@script, Path.join(fixture_root, @script))
    File.write!(Path.join(fixture_root, "mix.lock"), "%{fixture: :root}\n")

    {output, status} =
      System.cmd("bash", [@script],
        cd: fixture_root,
        stderr_to_stdout: true
      )

    assert status != 0
    assert output =~ "examples/phoenix_host/mix.lock"
    assert output =~ "mix deps.get"
  end

  test "dependency-security script stays compatible with macOS bash 3.2" do
    source = File.read!(@script)

    for {pattern, feature} <- [
          {~r/^\s*(mapfile|readarray)\b/m, "mapfile/readarray"},
          {~r/declare\s+-A\b/, "associative arrays"},
          {~r/\$\{[a-zA-Z_][a-zA-Z0-9_]*(,,|\^\^)\}/, "case conversion"}
        ] do
      refute Regex.match?(pattern, source),
             "#{@script} uses bash-4-only #{feature}"
    end
  end

  defp lock_versions(path, packages) do
    source = File.read!(path)

    Map.new(packages, fn package ->
      pattern = ~r/"#{Regex.escape(package)}":\s*\{:hex,\s*:#{Regex.escape(package)},\s*"([^"]+)"/

      case Regex.run(pattern, source, capture: :all_but_first) do
        [version] -> {package, version}
        _ -> flunk("#{path} is missing a literal #{package} Hex tuple")
      end
    end)
  end
end
