defmodule Crosswake.Release.PublishedCleanroomTest do
  @moduledoc """
  Hermetic proof for `script/verify_published_cleanroom.sh` (REL-06).

  Every case here is offline: the Maven leg reads a `file://` fixture built at
  runtime, and the Hex leg reads a `file://` registry shape with no release in
  it. Real-registry proof lives in the retained 195-EVIDENCE runs, not in
  `mix test`.
  """

  use ExUnit.Case, async: false

  @script Path.expand("../../../script/verify_published_cleanroom.sh", __DIR__)
  @artifact "crosswake-shell-core-android-0.0.1"
  @real_pom Path.expand(
              "../../fixtures/cleanroom/crosswake-shell-core-android-0.2.11.pom",
              __DIR__
            )

  # The external tools each leg's `need_tools` call must list (IN-03). The test parses the
  # real lists out of the script source and requires them to equal these.
  @leg_tools %{
    "hex" => ~w(curl grep cut tr head tail mktemp mkdir),
    "maven" => ~w(curl cut grep mktemp head tr sed mkdir),
    "ios" => ~w(git swift mktemp cut)
  }

  @selftest_env [
    {"CLEANROOM_SELFTEST", nil},
    {"CLEANROOM_LEGS", nil},
    {"CLEANROOM_MAVEN_BASE", nil},
    {"CLEANROOM_HEX_API", nil},
    {"CLEANROOM_ELIXIR_VERSION", nil},
    {"CLEANROOM_ERLANG_VERSION", nil}
  ]

  setup do
    root =
      Path.join(System.tmp_dir!(), "cw-cleanroom-test-#{System.unique_integer([:positive])}")

    File.mkdir_p!(root)
    on_exit(fn -> File.rm_rf!(root) end)
    {:ok, root: root}
  end

  # A multi-line project POM with its own coordinates and a dependency block whose
  # <version> is 0.0.1, the shape that fooled the old substring check.
  defp synthetic_pom(opts) do
    group = Keyword.get(opts, :group, "io.github.sztheory")
    artifact = Keyword.get(opts, :artifact, "crosswake-shell-core-android")
    version = Keyword.get(opts, :version, "0.0.1")
    packaging = Keyword.get(opts, :packaging, "aar")

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <project>
      <modelVersion>4.0.0</modelVersion>
      <groupId>#{group}</groupId>
      <artifactId>#{artifact}</artifactId>
      <version>#{version}</version>
      <packaging>#{packaging}</packaging>
      <dependencies>
        <dependency>
          <groupId>io.github.sztheory</groupId>
          <artifactId>crosswake-shell-core-android</artifactId>
          <version>0.0.1</version>
        </dependency>
      </dependencies>
    </project>
    """
  end

  defp sha256_hex(body), do: :crypto.hash(:sha256, body) |> Base.encode16(case: :lower)

  defp write_with_sha(dir, name, body) do
    File.write!(Path.join(dir, name), body)
    File.write!(Path.join(dir, name <> ".sha256"), sha256_hex(body) <> "\n")
  end

  defp build_maven_fixture(root, opts \\ []) do
    version = Keyword.get(opts, :version, "0.0.1")
    pom = Keyword.get(opts, :pom, synthetic_pom(version: version))
    art = "crosswake-shell-core-android-#{version}"
    base = Path.join(root, "maven")
    dir = Path.join([base, "io/github/sztheory/crosswake-shell-core-android", version])
    File.mkdir_p!(dir)

    write_with_sha(dir, "#{art}.pom", pom)
    write_with_sha(dir, "#{art}.module", ~s({"formatVersion":"1.1"}\n))
    write_with_sha(dir, "#{art}.aar", "PK-fixture-aar-bytes")

    {"file://" <> base, dir}
  end

  defp assert_pom_mismatch({out, rc}) do
    assert rc == 1, out
    assert out =~ "cleanroom: FAIL maven pom_mismatch"
    refute out =~ "cleanroom: result PASS"
    refute out =~ "cleanroom: result SELFTEST"
    refute out =~ ~r/^cleanroom: leg maven PASS/m
  end

  defp run(script, args, env, opts \\ []) do
    System.cmd("bash", [script | args],
      env: @selftest_env ++ env,
      stderr_to_stdout: true,
      cd: Keyword.get(opts, :cd, File.cwd!())
    )
  end

  defp maven_selftest_env(base) do
    [
      {"CLEANROOM_SELFTEST", "1"},
      {"CLEANROOM_LEGS", "maven"},
      {"CLEANROOM_MAVEN_BASE", base}
    ]
  end

  test "no arguments is a usage error (exit 2)" do
    {out, rc} = run(@script, [], [])
    assert rc == 2
    assert out =~ "cleanroom: usage"
  end

  test "a non-version argument exits 2" do
    {out, rc} = run(@script, ["not-a-version"], [])
    assert rc == 2
    assert out =~ "cleanroom: usage"
  end

  test "a maven base override without CLEANROOM_SELFTEST=1 is refused", %{root: root} do
    {base, _dir} = build_maven_fixture(root)
    {out, rc} = run(@script, ["0.0.1"], [{"CLEANROOM_MAVEN_BASE", base}])
    assert rc == 2
    assert out =~ "cleanroom: override refused"
    refute out =~ "cleanroom: result PASS"
  end

  test "a restricted leg list without CLEANROOM_SELFTEST=1 is refused" do
    {out, rc} = run(@script, ["0.0.1"], [{"CLEANROOM_LEGS", "maven"}])
    assert rc == 2
    assert out =~ "cleanroom: override refused"
  end

  test "maven fixture passes only as SELFTEST, never PASS", %{root: root} do
    {base, _dir} = build_maven_fixture(root)
    {out, rc} = run(@script, ["0.0.1"], maven_selftest_env(base))

    assert rc == 0, out
    assert out =~ "cleanroom: selftest overrides active"
    assert out =~ ~r/^cleanroom: leg maven PASS 0\.0\.1 aar [0-9a-f]{12}$/m

    assert String.trim_trailing(out) |> String.split("\n") |> List.last() ==
             "cleanroom: result SELFTEST legs maven version 0.0.1"

    refute out =~ "cleanroom: result PASS"
  end

  test "a changed .aar is a checksum_mismatch failure", %{root: root} do
    {base, dir} = build_maven_fixture(root)
    File.write!(Path.join(dir, "#{@artifact}.aar"), "PK-tampered")

    {out, rc} = run(@script, ["0.0.1"], maven_selftest_env(base))
    assert rc == 1
    assert out =~ "cleanroom: FAIL maven checksum_mismatch"
    refute out =~ "cleanroom: result PASS"
    refute out =~ "cleanroom: result SELFTEST"
  end

  test "a missing .aar is not_published", %{root: root} do
    {base, dir} = build_maven_fixture(root)
    File.rm!(Path.join(dir, "#{@artifact}.aar"))

    {out, rc} = run(@script, ["0.0.1"], maven_selftest_env(base))
    assert rc == 1
    assert out =~ "cleanroom: FAIL maven not_published"
  end

  test "a pom whose project version differs is pom_mismatch even when a dependency carries the run version",
       %{root: root} do
    {base, _dir} = build_maven_fixture(root, pom: synthetic_pom(version: "0.0.2"))
    assert_pom_mismatch(run(@script, ["0.0.1"], maven_selftest_env(base)))
  end

  test "a pom whose project groupId differs is pom_mismatch", %{root: root} do
    {base, _dir} = build_maven_fixture(root, pom: synthetic_pom(group: "io.github.other"))
    assert_pom_mismatch(run(@script, ["0.0.1"], maven_selftest_env(base)))
  end

  test "a pom whose project artifactId differs is pom_mismatch", %{root: root} do
    {base, _dir} = build_maven_fixture(root, pom: synthetic_pom(artifact: "something-else"))
    assert_pom_mismatch(run(@script, ["0.0.1"], maven_selftest_env(base)))
  end

  test "a pom whose packaging is not aar is pom_mismatch", %{root: root} do
    {base, _dir} = build_maven_fixture(root, pom: synthetic_pom(packaging: "jar"))
    assert_pom_mismatch(run(@script, ["0.0.1"], maven_selftest_env(base)))
  end

  test "the real published 0.2.11 pom passes the pom check", %{root: root} do
    pom = File.read!(@real_pom)
    assert pom =~ "<dependency>"
    {base, _dir} = build_maven_fixture(root, version: "0.2.11", pom: pom)

    {out, rc} = run(@script, ["0.2.11"], maven_selftest_env(base))

    assert rc == 0, out
    assert out =~ ~r/^cleanroom: leg maven PASS 0\.2\.11 aar [0-9a-f]{12}$/m
    refute out =~ "pom_mismatch"
    refute out =~ "cleanroom: result PASS"
  end

  test "the real pom with only the project version changed is pom_mismatch", %{root: root} do
    real = File.read!(@real_pom)

    derived =
      String.replace(
        real,
        "  <version>0.2.11</version>\n  <packaging>",
        "  <version>0.2.10</version>\n  <packaging>",
        global: false
      )

    assert derived != real
    # Every dependency <version> is untouched.
    assert derived =~ "<version>1.9.24</version>"

    {base, _dir} = build_maven_fixture(root, version: "0.2.11", pom: derived)
    assert_pom_mismatch(run(@script, ["0.2.11"], maven_selftest_env(base)))
  end

  test "the real pom with a parent block carrying the real coordinates and a changed project groupId is pom_mismatch",
       %{root: root} do
    real = File.read!(@real_pom)

    project_head =
      "  <groupId>io.github.sztheory</groupId>\n  <artifactId>crosswake-shell-core-android</artifactId>\n  <version>0.2.11</version>\n"

    parent =
      "  <parent>\n    <groupId>io.github.sztheory</groupId>\n    <artifactId>crosswake-shell-core-android</artifactId>\n    <version>0.2.11</version>\n  </parent>\n  <groupId>io.github.other</groupId>\n  <artifactId>crosswake-shell-core-android</artifactId>\n  <version>0.2.11</version>\n"

    assert real =~ project_head
    derived = String.replace(real, project_head, parent, global: false)
    assert derived != real

    {base, _dir} = build_maven_fixture(root, version: "0.2.11", pom: derived)
    assert_pom_mismatch(run(@script, ["0.2.11"], maven_selftest_env(base)))
  end

  test "a missing tool is tool_unavailable, never a skip", %{root: root} do
    {base, _dir} = build_maven_fixture(root)
    bin = Path.join(root, "bin")
    File.mkdir_p!(bin)

    # Everything the script needs except curl.
    for tool <- ~w(mktemp rm cat grep sed tr cut head tail awk date mkdir uname shasum perl) do
      case System.find_executable(tool) do
        nil -> :ok
        path -> File.ln_s!(path, Path.join(bin, tool))
      end
    end

    bash = System.find_executable("bash")

    {out, rc} =
      System.cmd(bash, [@script, "0.0.1"],
        env: @selftest_env ++ maven_selftest_env(base) ++ [{"PATH", bin}],
        stderr_to_stdout: true
      )

    assert rc == 1, out
    assert out =~ "cleanroom: FAIL maven tool_unavailable"
    refute out =~ "cleanroom: result PASS"
  end

  test "runs from a directory outside the checkout without a clone", %{root: root} do
    {base, _dir} = build_maven_fixture(root)
    nc = Path.join(root, "no-checkout")
    File.mkdir_p!(nc)
    copy = Path.join(nc, "verify_published_cleanroom.sh")
    File.cp!(@script, copy)

    {out, rc} = run("./verify_published_cleanroom.sh", [], [], cd: nc)
    assert rc == 2
    assert out =~ "cleanroom: usage"

    {out, rc} =
      run("./verify_published_cleanroom.sh", ["0.0.1"], maven_selftest_env(base), cd: nc)

    assert rc == 0, out
    assert out =~ "cleanroom: result SELFTEST legs maven version 0.0.1"
  end

  test "hex leg: an unknown version in the registry shape is not_published, offline", %{
    root: root
  } do
    empty_api = Path.join(root, "hexapi")
    File.mkdir_p!(empty_api)

    {out, rc} =
      run(@script, ["0.0.1"], [
        {"CLEANROOM_SELFTEST", "1"},
        {"CLEANROOM_LEGS", "hex"},
        {"CLEANROOM_HEX_API", "file://" <> empty_api}
      ])

    assert rc == 1, out
    assert out =~ "cleanroom: FAIL hex not_published"
    refute out =~ "cleanroom: result PASS"
    refute out =~ "cleanroom: result SELFTEST"
  end

  defp hex_selftest_env(api) do
    [
      {"CLEANROOM_SELFTEST", "1"},
      {"CLEANROOM_LEGS", "hex"},
      {"CLEANROOM_HEX_API", "file://" <> api}
    ]
  end

  defp hex_release_path(api), do: Path.join([api, "packages", "crosswake", "releases", "0.0.1"])

  # A PATH-first directory holding stubs for `git` and `swift` only; every other tool
  # stays on the inherited PATH.
  defp stub_path(root, git_body) do
    stubs = Path.join(root, "stubs")
    File.mkdir_p!(stubs)

    for {name, body} <- [{"git", git_body}, {"swift", "exit 0\n"}] do
      path = Path.join(stubs, name)
      File.write!(path, "#!/bin/sh\n" <> body)
      File.chmod!(path, 0o755)
    end

    stubs <> ":" <> System.get_env("PATH", "")
  end

  # The flags the network curl call must carry (WR-04). Returns the missing ones.
  defp missing_curl_pins(src) do
    lines = String.split(src, "\n")
    network = Enum.filter(lines, &(&1 =~ ~r/^\s*code=\$\(curl /))
    assert length(network) == 1, "expected exactly one network curl line, got #{inspect(network)}"
    [line] = network

    Enum.reject(
      ["--max-time", "--retry", "--proto '=https'", "--proto-redir '=https'"],
      &String.contains?(line, &1)
    )
  end

  test "hex leg: a 200 response with no checksum is parse_failed, never not_published", %{
    root: root
  } do
    api = Path.join(root, "hexapi")
    File.mkdir_p!(Path.dirname(hex_release_path(api)))
    File.write!(hex_release_path(api), "{}\n")

    {out, rc} = run(@script, ["0.0.1"], hex_selftest_env(api))

    assert rc == 1, out
    assert out =~ "cleanroom: FAIL hex parse_failed"
    refute out =~ "not_published"
    refute out =~ "cleanroom: result PASS"
    refute out =~ "cleanroom: result SELFTEST"
  end

  test "hex leg: a fixture path that exists but cannot be copied is resolve_failed", %{
    root: root
  } do
    api = Path.join(root, "hexapi")
    # A directory where the release file should be: present, but not copyable.
    File.mkdir_p!(hex_release_path(api))

    {out, rc} = run(@script, ["0.0.1"], hex_selftest_env(api))

    assert rc == 1, out
    assert out =~ "cleanroom: FAIL hex resolve_failed"
    refute out =~ "not_published"
    refute out =~ "cleanroom: result PASS"
  end

  test "ios leg: a failing git ls-remote is resolve_failed, never not_published", %{root: root} do
    path = stub_path(root, ~s(if [ "$1" = ls-remote ]; then exit 128; fi\nexit 0\n))

    {out, rc} =
      run(@script, ["0.0.1"], [
        {"CLEANROOM_SELFTEST", "1"},
        {"CLEANROOM_LEGS", "ios"},
        {"PATH", path}
      ])

    assert rc == 1, out
    assert out =~ "cleanroom: FAIL ios resolve_failed"
    refute out =~ "not_published"
    refute out =~ "cleanroom: result PASS"
  end

  test "ios leg: a successful empty git ls-remote is not_published", %{root: root} do
    path = stub_path(root, "exit 0\n")

    {out, rc} =
      run(@script, ["0.0.1"], [
        {"CLEANROOM_SELFTEST", "1"},
        {"CLEANROOM_LEGS", "ios"},
        {"PATH", path}
      ])

    assert rc == 1, out
    assert out =~ "cleanroom: FAIL ios not_published"
    refute out =~ "resolve_failed"
    refute out =~ "cleanroom: result PASS"
  end

  test "every network curl call is bounded and https-pinned (WR-04), with a removal control" do
    src = File.read!(@script)
    assert missing_curl_pins(src) == []

    assert src =~ "CURL_MAX_TIME=120"
    assert src =~ "CURL_RETRY=2"
    refute src =~ "--retry-all-errors"

    mutated = String.replace(src, " --proto-redir '=https'", "")
    assert mutated != src
    assert missing_curl_pins(mutated) == ["--proto-redir '=https'"]
  end

  defp need_tools_from_source(leg) do
    src = File.read!(@script)

    case Regex.run(~r/^\s*need_tools #{leg} (.+?) \|\| return$/m, src) do
      [_, list] -> String.split(list, " ", trim: true)
      nil -> []
    end
  end

  # Remove each tool the leg lists from PATH, one at a time, and require that exact
  # leg to fail closed with tool_unavailable. Tools missing from the host are replaced
  # by an empty executable so every tool is in the set before its removal.
  defp assert_every_listed_tool_is_required(root, leg) do
    listed = need_tools_from_source(leg)
    assert listed != [], "no need_tools list parsed for #{leg}"
    assert listed == @leg_tools[leg]

    universe = @leg_tools |> Map.values() |> List.flatten() |> Enum.uniq()
    bash = System.find_executable("bash")

    for tool <- listed do
      assert tool in universe
      bin = Path.join(root, "bin-#{leg}-#{tool}")
      File.mkdir_p!(bin)

      for present <- universe -- [tool] do
        target = Path.join(bin, present)

        case System.find_executable(present) do
          nil ->
            File.write!(target, "#!/bin/sh\nexit 0\n")
            File.chmod!(target, 0o755)

          path ->
            File.ln_s!(path, target)
        end
      end

      refute File.exists?(Path.join(bin, tool))

      {out, rc} =
        System.cmd(bash, [@script, "0.0.1"],
          env:
            @selftest_env ++
              [{"CLEANROOM_SELFTEST", "1"}, {"CLEANROOM_LEGS", leg}, {"PATH", bin}],
          stderr_to_stdout: true
        )

      assert rc == 1, "#{leg} without #{tool}: #{out}"
      assert out =~ "cleanroom: FAIL #{leg} tool_unavailable", "#{leg} without #{tool}: #{out}"
      refute out =~ "leg #{leg} PASS"
      refute out =~ "cleanroom: result PASS"
    end
  end

  test "hex leg: removing any tool in its need_tools list is tool_unavailable", %{root: root} do
    assert_every_listed_tool_is_required(root, "hex")
  end

  test "maven leg: removing any tool in its need_tools list is tool_unavailable", %{root: root} do
    assert_every_listed_tool_is_required(root, "maven")
  end

  test "ios leg: removing any tool in its need_tools list is tool_unavailable", %{root: root} do
    assert_every_listed_tool_is_required(root, "ios")
  end

  test "the script locates nothing relative to itself or a checkout" do
    src = File.read!(@script)
    refute src =~ "BASH_SOURCE"
    refute src =~ ~r/dirname "?\$0/
    refute src =~ "rev-parse --show-toplevel"
    refute src =~ ~r/cp [^#\n]*tool-versions/
  end
end
