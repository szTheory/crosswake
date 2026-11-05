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
    {"CLEANROOM_DOCS_REF", nil},
    {"CLEANROOM_DOCS_BASE", nil},
    {"CLEANROOM_HEX_REPO", nil},
    {"CLEANROOM_KEEP_WORK", nil},
    {"CLEANROOM_DOCS_STEP_TIMEOUT", nil},
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

  # The docs leg's list is read from the live script so a tool added later is covered
  # without editing this test.
  defp listed_tools("docs") do
    listed = need_tools_from_source("docs")
    assert listed != [], "no need_tools list parsed for docs"

    for required <- ~w(awk env bash sleep) do
      assert required in listed, "docs need_tools list lacks #{required}"
    end

    refute "rm" in listed
    listed
  end

  defp listed_tools(leg) do
    listed = need_tools_from_source(leg)
    assert listed != [], "no need_tools list parsed for #{leg}"
    assert listed == @leg_tools[leg]
    listed
  end

  defp tool_universe do
    @leg_tools
    |> Map.values()
    |> List.flatten()
    |> Enum.concat(listed_tools("docs"))
    |> Enum.uniq()
  end

  # Remove one tool from a PATH holding every tool any leg lists, run the leg, and require
  # it to fail closed with tool_unavailable. Tools missing from the host are replaced by an
  # empty executable so the tool is in the set before its removal. For the docs leg `mix`
  # is the capture stub, so a step that ran despite the missing tool would write the
  # capture file; none may.
  defp assert_tool_removal(root, leg, tool) do
    bash = System.find_executable("bash")
    bin = Path.join(root, "bin-#{leg}-#{tool}")
    capture = Path.join(root, "capture-#{leg}-#{tool}")
    File.mkdir_p!(bin)

    stub_dir = mix_stub(root, capture)

    for present <- tool_universe() -- [tool] do
      target = Path.join(bin, present)

      cond do
        leg == "docs" and present == "mix" ->
          File.ln_s!(Path.join(stub_dir, "mix"), target)

        path = System.find_executable(present) ->
          File.ln_s!(path, target)

        true ->
          File.write!(target, "#!/bin/sh\nexit 0\n")
          File.chmod!(target, 0o755)
      end
    end

    refute File.exists?(Path.join(bin, tool))

    docs_env =
      if leg == "docs" do
        base = write_docs(root, docs_readme(), docs_install())
        [{"CLEANROOM_DOCS_BASE", base}, {"CLEANROOM_DOCS_REF", @zero_ref}]
      else
        []
      end

    {out, rc} =
      System.cmd(bash, [@script, "0.0.1"],
        env:
          @selftest_env ++
            [{"CLEANROOM_SELFTEST", "1"}, {"CLEANROOM_LEGS", leg}, {"PATH", bin}] ++ docs_env,
        stderr_to_stdout: true
      )

    assert rc == 1, "#{leg} without #{tool}: #{out}"
    assert out =~ "cleanroom: FAIL #{leg} tool_unavailable", "#{leg} without #{tool}: #{out}"
    refute out =~ "leg #{leg} PASS"
    refute out =~ "cleanroom: result PASS"
    refute File.exists?(capture), "#{leg} without #{tool}: a documented step ran"
  end

  defp assert_every_listed_tool_is_required(root, leg) do
    for tool <- listed_tools(leg) do
      assert tool in tool_universe()
      assert_tool_removal(root, leg, tool)
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

  # ---- docs leg (D-01, D-02, D-03, D-07a) ------------------------------------------------

  @zero_ref String.duplicate("0", 40)
  @sentinel "cw-sentinel-197"
  @allowed_step_vars ~w(PATH LANG HOME MIX_HOME HEX_HOME MIX_ENV ASDF_DIR ASDF_DATA_DIR PWD OLDPWD SHLVL _)

  defp docs_readme do
    """
    # Crosswake

    Intro text.

    ## Quick start

    ```bash
    this unmarked fence sits before the Integrating section
    ```

    ### Integrating Crosswake

    Steps below.

    <!-- cleanroom:run id=readme_deps -->
    ```bash
    mix deps.get
    ```

    <!-- cleanroom:run id=readme_install -->
    ```bash
    mix crosswake.install
    ```

    <!-- cleanroom:show -->
    ```elixir
    Crosswake.Bridge.attach()
    ```

    <!-- cleanroom:clone id=readme_clone -->
    ```bash
    script/verify_phase5_example_hosts.sh
    ```

    ### License

    ```text
    this unmarked fence sits after the Integrating section
    ```
    """
  end

  defp docs_install do
    """
    # Install

    <!-- cleanroom:run id=deps -->
    ```bash
    mix deps.get
    ```

    <!-- cleanroom:run id=install -->
    ```bash
    mix crosswake.install
    ```

    <!-- cleanroom:run id=doctor -->
    ```bash
    mix crosswake.doctor
    ```

    <!-- cleanroom:show -->
    ```elixir
    Crosswake.Bridge.attach()
    ```

    <!-- cleanroom:clone id=install_clone -->
    ```bash
    script/verify_generated_ios_shell.sh
    ```
    """
  end

  # Writes <root>/<name>/<ref>/README.md and guides/install.md; returns the file:// base.
  defp write_docs(root, readme, install, name \\ "docs") do
    base = Path.join(root, name)
    dir = Path.join(base, @zero_ref)
    File.mkdir_p!(Path.join(dir, "guides"))
    File.write!(Path.join(dir, "README.md"), readme)
    File.write!(Path.join(dir, "guides/install.md"), install)
    "file://" <> base
  end

  # A PATH-first `mix` stub: the generator and install tasks succeed, anything else is the
  # real "task could not be found" failure (exit 1).
  defp mix_stub(root, capture \\ nil) do
    stubs = Path.join(root, "mixstubs")
    File.mkdir_p!(stubs)
    path = Path.join(stubs, "mix")
    # With a capture path the stub appends its whole environment there before acting.
    capture_line = if capture, do: "env >> '#{capture}'\n", else: ""

    File.write!(path, """
    #!/bin/sh
    #{capture_line}case "$1" in
      local.hex|local.rebar|archive.install|deps.get|crosswake.install|crosswake.doctor|compile)
        exit 0 ;;
      phx.new)
        mkdir -p "$2" && : > "$2/mix.exs"
        exit 0 ;;
      *)
        echo "The task \\"$1\\" could not be found"
        exit 1 ;;
    esac
    """)

    File.chmod!(path, 0o755)
    stubs
  end

  defp docs_selftest_env(root, base, extra \\ [], capture \\ nil) do
    path = mix_stub(root, capture) <> ":" <> System.get_env("PATH", "")

    [
      {"CLEANROOM_SELFTEST", "1"},
      {"CLEANROOM_LEGS", "docs"},
      {"CLEANROOM_DOCS_BASE", base},
      {"CLEANROOM_DOCS_REF", @zero_ref},
      {"PATH", path}
    ] ++ extra
  end

  defp last_line(out), do: out |> String.trim_trailing() |> String.split("\n") |> List.last()

  test "docs leg: commit-pinned docs execute every run block, count clone and show blocks", %{
    root: root
  } do
    base = write_docs(root, docs_readme(), docs_install())
    {out, rc} = run(@script, ["0.0.1"], docs_selftest_env(root, base))

    assert rc == 0, out
    assert out =~ "cleanroom: docs source commit #{@zero_ref}"

    assert out =~
             "cleanroom: leg docs PASS 0.0.1 executed=5 not_applicable=0 clone=2 shown=2 source=commit:#{@zero_ref} phx_new=1.8.13"

    assert last_line(out) == "cleanroom: result SELFTEST legs docs version 0.0.1"
    refute out =~ "cleanroom: result PASS"
  end

  test "docs leg: a doctor block naming a nonexistent task fails exactly that step (D-07a)", %{
    root: root
  } do
    install = docs_install()
    mutated = String.replace(install, "mix crosswake.doctor", "mix crosswake.no_such_task")
    assert mutated != install

    base = write_docs(root, docs_readme(), mutated)
    {out, rc} = run(@script, ["0.0.1"], docs_selftest_env(root, base))

    assert rc == 1, out
    lines = String.split(out, "\n")
    assert "cleanroom: FAIL docs step doctor exit 1" in lines
    assert Enum.count(lines, &String.starts_with?(&1, "cleanroom: FAIL")) == 1
    assert last_line(out) == "cleanroom: result FAIL legs docs version 0.0.1"
    refute out =~ "leg docs PASS"
  end

  test "docs leg: a fence with no marker is parse unmarked_fence", %{root: root} do
    install = docs_install()
    mutated = String.replace(install, "<!-- cleanroom:run id=install -->\n", "", global: false)
    assert mutated != install

    base = write_docs(root, docs_readme(), mutated)
    {out, rc} = run(@script, ["0.0.1"], docs_selftest_env(root, base))

    assert rc == 1, out
    assert out =~ "cleanroom: FAIL docs parse unmarked_fence guides/install.md"
    refute out =~ "leg docs PASS"
  end

  test "docs leg: README fences outside the Integrating section need no marker", %{root: root} do
    readme = docs_readme()
    # The two unmarked fences (before and after the section) are the whole point of this
    # fixture: the passing run above proves they are ignored; here the section marker goes.
    mutated = String.replace(readme, "### Integrating Crosswake", "### Something Else")
    assert mutated != readme

    base = write_docs(root, mutated, docs_install())
    {out, rc} = run(@script, ["0.0.1"], docs_selftest_env(root, base))

    assert rc == 1, out
    assert out =~ "cleanroom: FAIL docs parse readme_scope_missing"
    refute out =~ "leg docs PASS"
  end

  test "docs leg: an id reused across the two files is parse duplicate_id", %{root: root} do
    install = docs_install()
    mutated = String.replace(install, "id=deps", "id=readme_deps", global: false)
    assert mutated != install

    base = write_docs(root, docs_readme(), mutated)
    {out, rc} = run(@script, ["0.0.1"], docs_selftest_env(root, base))

    assert rc == 1, out
    assert out =~ "cleanroom: FAIL docs parse duplicate_id"
    refute out =~ "leg docs PASS"
  end

  test "docs leg: a run marker without id and an unknown attribute are parse errors", %{
    root: root
  } do
    install = docs_install()

    no_id = String.replace(install, "<!-- cleanroom:run id=deps -->", "<!-- cleanroom:run -->")
    assert no_id != install
    base = write_docs(root, docs_readme(), no_id)
    {out, rc} = run(@script, ["0.0.1"], docs_selftest_env(root, base))
    assert rc == 1, out
    assert out =~ "cleanroom: FAIL docs parse missing_id"

    odd =
      String.replace(
        install,
        "<!-- cleanroom:run id=deps -->",
        "<!-- cleanroom:run id=deps colour=red -->"
      )

    assert odd != install
    base = write_docs(root, docs_readme(), odd, "docs-odd")
    {out, rc} = run(@script, ["0.0.1"], docs_selftest_env(root, base))
    assert rc == 1, out
    assert out =~ "cleanroom: FAIL docs parse unknown_attr"
  end

  test "docs leg: an apply marker parses but is not yet supported", %{root: root} do
    install = docs_install()

    mutated =
      String.replace(
        install,
        "<!-- cleanroom:show -->",
        "<!-- cleanroom:apply id=wire file=lib/x.ex mode=append -->"
      )

    assert mutated != install
    base = write_docs(root, docs_readme(), mutated)
    {out, rc} = run(@script, ["0.0.1"], docs_selftest_env(root, base))

    assert rc == 1, out
    assert out =~ "cleanroom: FAIL docs parse apply_unsupported"
  end

  # ---- default docs source: the Hex tarball of the version under test (D-03) ----------------

  # Writes <root>/<name>/tarballs/crosswake-<version>.tar the way Hex packs it: an outer
  # uncompressed tar holding VERSION and contents.tar.gz, the latter a gzip tar of the package
  # files. Built with :erl_tar so the test assumes no external tar. `members` are
  # {path, binary} pairs for the inner archive. Returns the file:// repo root.
  defp write_tarball(root, version, members, name \\ "hexrepo") do
    repo = Path.join(root, name)
    dir = Path.join(repo, "tarballs")
    File.mkdir_p!(dir)
    inner = Path.join(root, "#{name}-contents-#{System.unique_integer([:positive])}.tar.gz")
    :ok = :erl_tar.create(String.to_charlist(inner), to_entries(members), [:compressed])

    outer = Path.join(dir, "crosswake-#{version}.tar")

    :ok =
      :erl_tar.create(String.to_charlist(outer), [
        {~c"VERSION", "3"},
        {~c"contents.tar.gz", File.read!(inner)}
      ])

    "file://" <> repo
  end

  defp to_entries(members) do
    for {path, body} <- members, do: {String.to_charlist(path), body}
  end

  defp tarball_env(root, repo, extra \\ []) do
    path = mix_stub(root) <> ":" <> System.get_env("PATH", "")

    [
      {"CLEANROOM_SELFTEST", "1"},
      {"CLEANROOM_LEGS", "docs"},
      {"CLEANROOM_HEX_REPO", repo},
      {"PATH", path}
    ] ++ extra
  end

  test "docs leg: with no ref the docs come from the Hex tarball of the version under test", %{
    root: root
  } do
    repo =
      write_tarball(root, "0.0.1", [
        {"README.md", docs_readme()},
        {"guides/install.md", docs_install()}
      ])

    {out, rc} = run(@script, ["0.0.1"], tarball_env(root, repo))

    assert rc == 0, out
    assert out =~ "cleanroom: docs source tarball crosswake-0.0.1.tar\n"
    refute out =~ "docs source commit"

    assert out =~
             "cleanroom: leg docs PASS 0.0.1 executed=5 not_applicable=0 clone=2 shown=2 source=tarball phx_new=1.8.13"

    assert last_line(out) == "cleanroom: result SELFTEST legs docs version 0.0.1"
    refute out =~ "cleanroom: result PASS"
  end

  test "docs leg: a tarball without guides/install.md is fetch guides/install.md", %{root: root} do
    repo = write_tarball(root, "0.0.1", [{"README.md", docs_readme()}])
    {out, rc} = run(@script, ["0.0.1"], tarball_env(root, repo))

    assert rc == 1, out
    assert out =~ "cleanroom: FAIL docs fetch guides/install.md"
    refute out =~ "docs source tarball"
    refute out =~ "leg docs PASS"
    assert last_line(out) == "cleanroom: result FAIL legs docs version 0.0.1"
  end

  test "docs leg: a tarball without README.md is fetch README.md", %{root: root} do
    repo = write_tarball(root, "0.0.1", [{"guides/install.md", docs_install()}])
    {out, rc} = run(@script, ["0.0.1"], tarball_env(root, repo))

    assert rc == 1, out
    assert out =~ "cleanroom: FAIL docs fetch README.md"
    refute out =~ "leg docs PASS"
  end

  test "docs leg: a missing tarball is fetch tarball", %{root: root} do
    empty = Path.join(root, "emptyrepo")
    File.mkdir_p!(empty)
    {out, rc} = run(@script, ["0.0.1"], tarball_env(root, "file://" <> empty))

    assert rc == 1, out
    assert out =~ "cleanroom: FAIL docs fetch tarball"
    refute out =~ "docs source tarball"
    refute out =~ "leg docs PASS"
  end

  test "docs leg: a tarball for another version is fetch tarball", %{root: root} do
    repo =
      write_tarball(root, "0.0.2", [
        {"README.md", docs_readme()},
        {"guides/install.md", docs_install()}
      ])

    {out, rc} = run(@script, ["0.0.1"], tarball_env(root, repo))

    assert rc == 1, out
    assert out =~ "cleanroom: FAIL docs fetch tarball"
    refute out =~ "leg docs PASS"
  end

  test "docs leg: a file that is not a tar archive is fetch tarball", %{root: root} do
    repo = Path.join(root, "garbagerepo")
    File.mkdir_p!(Path.join(repo, "tarballs"))
    File.write!(Path.join(repo, "tarballs/crosswake-0.0.1.tar"), "this is not a tar archive")
    {out, rc} = run(@script, ["0.0.1"], tarball_env(root, "file://" <> repo))

    assert rc == 1, out
    assert out =~ "cleanroom: FAIL docs fetch tarball"
    refute out =~ "leg docs PASS"
  end

  test "docs leg: only the two named members are extracted from the tarball", %{root: root} do
    repo =
      write_tarball(root, "0.0.1", [
        {"README.md", docs_readme()},
        {"guides/install.md", docs_install()},
        {"mix.exs", "# not a doc"},
        {"guides/other.md", "# not a doc"},
        {"lib/crosswake.ex", "# not a doc"}
      ])

    {out, rc} = run(@script, ["0.0.1"], tarball_env(root, repo, [{"CLEANROOM_KEEP_WORK", "1"}]))
    assert rc == 0, out
    [_, work] = Regex.run(~r/^cleanroom: work kept (.+)$/m, out)

    extract = Path.join([work, "docs", "extract"])
    assert File.regular?(Path.join(extract, "README.md"))
    assert File.regular?(Path.join(extract, "guides/install.md"))
    refute File.exists?(Path.join(extract, "mix.exs"))
    refute File.exists?(Path.join(extract, "guides/other.md"))
    refute File.exists?(Path.join(extract, "lib"))

    File.rm_rf!(work)
  end

  test "docs leg: a ref wins over the tarball and the Hex repo is not read", %{root: root} do
    base = write_docs(root, docs_readme(), docs_install())
    empty = Path.join(root, "unusedrepo")
    File.mkdir_p!(empty)

    {out, rc} =
      run(
        @script,
        ["0.0.1"],
        docs_selftest_env(root, base, [{"CLEANROOM_HEX_REPO", "file://" <> empty}])
      )

    assert rc == 0, out
    assert out =~ "cleanroom: docs source commit #{@zero_ref}"
    refute out =~ "docs source tarball"
    assert out =~ "source=commit:#{@zero_ref}"
  end

  test "CLEANROOM_HEX_REPO is refused without CLEANROOM_SELFTEST=1", %{root: root} do
    repo =
      write_tarball(root, "0.0.1", [
        {"README.md", docs_readme()},
        {"guides/install.md", docs_install()}
      ])

    {out, rc} = run(@script, ["0.0.1"], [{"CLEANROOM_HEX_REPO", repo}])
    assert rc == 2
    assert out =~ "cleanroom: override refused"
    refute out =~ "cleanroom: result"
    refute out =~ "docs source tarball"
  end

  test "the tarball default points at repo.hex.pm and CLEANROOM_HEX_REPO is an override, not a selector" do
    src = File.read!(@script)
    assert src =~ ~r/^HEX_REPO_DEFAULT="https:\/\/repo\.hex\.pm"$/m
    assert src =~ "tarballs/$name"

    [line] = Enum.filter(String.split(src, "\n"), &(&1 =~ ~s(if [ "$LEGS" != "$DEFAULT_LEGS" ])))
    assert line =~ "CLEANROOM_HEX_REPO"
  end

  test "the script header names every docs selector and selftest override" do
    header =
      @script
      |> File.read!()
      |> String.split("\n")
      |> Enum.take_while(&String.starts_with?(&1, "#"))

    header = Enum.join(header, "\n")

    for name <-
          ~w(CLEANROOM_DOCS_REF CLEANROOM_DOCS_BASE CLEANROOM_HEX_REPO CLEANROOM_KEEP_WORK) do
      assert header =~ name, "header does not name #{name}"
    end

    assert header =~ ~r/selector/
    assert header =~ ~r/Selftest overrides/
  end

  test "docs leg: a missing doc at the pinned commit is fetch <file>", %{root: root} do
    base = write_docs(root, docs_readme(), docs_install())
    File.rm!(Path.join([root, "docs", @zero_ref, "guides/install.md"]))
    {out, rc} = run(@script, ["0.0.1"], docs_selftest_env(root, base))

    assert rc == 1, out
    assert out =~ "cleanroom: FAIL docs fetch guides/install.md"
    refute out =~ "leg docs PASS"
  end

  test "docs ref: anything but 40 lowercase hex exits 2 before any fetch", %{root: root} do
    base = write_docs(root, docs_readme(), docs_install())

    for bad <- [
          "xyz",
          String.duplicate("a", 39),
          String.duplicate("a", 41),
          String.duplicate("A", 40),
          String.duplicate("g", 40)
        ] do
      {out, rc} =
        run(@script, ["0.0.1"], docs_selftest_env(root, base) ++ [{"CLEANROOM_DOCS_REF", bad}])

      assert rc == 2, "#{bad}: #{out}"
      assert out =~ "cleanroom: usage", "#{bad}: #{out}"
      refute out =~ "docs source commit", "#{bad}: #{out}"
    end

    {out, rc} = run(@script, ["0.2.11"], [{"CLEANROOM_DOCS_REF", "xyz"}])
    assert rc == 2
    assert out =~ "cleanroom: usage"
  end

  test "docs base and keep-work overrides are refused without CLEANROOM_SELFTEST=1", %{root: root} do
    base = write_docs(root, docs_readme(), docs_install())

    {out, rc} = run(@script, ["0.0.1"], [{"CLEANROOM_DOCS_BASE", base}])
    assert rc == 2
    assert out =~ "cleanroom: override refused"
    refute out =~ "cleanroom: result"

    {out, rc} = run(@script, ["0.0.1"], [{"CLEANROOM_KEEP_WORK", "1"}])
    assert rc == 2
    assert out =~ "cleanroom: override refused"
  end

  test "the docs ref is a selector: the refusal chain names the two overrides, not the ref" do
    src = File.read!(@script)
    [line] = Enum.filter(String.split(src, "\n"), &(&1 =~ ~s(if [ "$LEGS" != "$DEFAULT_LEGS" ])))

    assert line =~ "CLEANROOM_DOCS_BASE"
    assert line =~ "CLEANROOM_KEEP_WORK"
    refute line =~ "CLEANROOM_DOCS_REF"
  end

  test "the default legs are hex,maven,ios,docs and docs is an accepted leg" do
    src = File.read!(@script)
    assert src =~ ~r/^DEFAULT_LEGS="hex,maven,ios,docs"$/m
    assert src =~ ~r/hex \| maven \| ios \| docs\) ;;/
  end

  defp captured_env_names(capture) do
    capture
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.filter(&(&1 =~ ~r/^[A-Za-z_][A-Za-z0-9_]*=/))
  end

  defp run_with_env_capture(root, script, name) do
    capture = Path.join(root, "env-capture-#{name}")
    base = write_docs(root, docs_readme(), docs_install(), "docs-#{name}")

    env =
      docs_selftest_env(
        root,
        base,
        [{"HEX_API_KEY", @sentinel}, {"CLEANROOM_KEEP_WORK", "1"}],
        capture
      )

    {out, rc} = run(script, ["0.0.1"], env)
    {out, rc, capture}
  end

  test "docs steps see an allowlisted environment: a caller credential never reaches them", %{
    root: root
  } do
    {out, rc, capture} = run_with_env_capture(root, @script, "scrubbed")

    assert rc == 0, out
    assert File.exists?(capture)
    captured = File.read!(capture)
    assert captured != ""
    lines = captured_env_names(capture)
    assert lines != []
    refute captured =~ @sentinel
    refute captured =~ "HEX_API_KEY"
    refute captured =~ "CLEANROOM_"

    [_, work] = Regex.run(~r/^cleanroom: work kept (.+)$/m, out)

    for prefix <- ["HOME=", "MIX_HOME=", "HEX_HOME="] do
      values = for line <- lines, String.starts_with?(line, prefix), do: line
      assert values != [], "no #{prefix} captured"

      for value <- values do
        assert String.starts_with?(value, prefix <> work <> "/"), value
      end
    end

    for line <- lines do
      [name, _] = String.split(line, "=", parts: 2)
      assert name in @allowed_step_vars, "variable #{name} crossed the scrub"
    end

    File.rm_rf!(work)
  end

  test "the env-sentinel check can fail: without env -i the same run leaks the sentinel", %{
    root: root
  } do
    src = File.read!(@script)
    mutated = String.replace(src, ~s(env -i "${vars[@]}" "$@"), ~s(env "${vars[@]}" "$@"))
    assert mutated != src
    copy = Path.join(root, "unscrubbed.sh")
    File.write!(copy, mutated)

    {out, rc, capture} = run_with_env_capture(root, copy, "unscrubbed")

    assert rc == 0, out
    assert File.read!(capture) =~ @sentinel

    [_, work] = Regex.run(~r/^cleanroom: work kept (.+)$/m, out)
    File.rm_rf!(work)
  end

  test "docs leg: removing awk from PATH is tool_unavailable and no step runs", %{root: root} do
    assert "awk" in listed_tools("docs")
    assert_tool_removal(root, "docs", "awk")
  end

  test "docs leg: removing env from PATH is tool_unavailable, never an unscrubbed run", %{
    root: root
  } do
    assert "env" in listed_tools("docs")
    assert_tool_removal(root, "docs", "env")
  end

  test "docs leg: removing any tool in its need_tools list is tool_unavailable", %{root: root} do
    assert_every_listed_tool_is_required(root, "docs")
  end

  test "docs leg: need_tools is the first statement of leg_docs, before any fetch" do
    src = File.read!(@script)
    [_, body] = Regex.run(~r/^leg_docs\(\) \{\n(.*?)^\}/ms, src)
    [first | _] = body |> String.split("\n", trim: true)
    assert first =~ ~r/^\s*need_tools docs /
  end

  @tool_candidates ~w(curl awk sed grep tr head tail cut mktemp mkdir cp mv tar gzip mix env bash
                      sleep cat chmod sort uniq perl wc ls touch find xargs date rm)

  # Command words from the docs-leg functions that appear in the candidate list. Comment
  # lines are dropped; a word counts only in command position.
  defp docs_tools_used(src) do
    bodies =
      ~r/^(?:leg_docs|docs_[a-z_]+)\(\) \{\n.*?^\}/ms
      |> Regex.scan(src)
      |> Enum.map(&hd/1)

    assert length(bodies) >= 5, "expected at least five docs-leg functions"

    code =
      bodies
      |> Enum.join("\n")
      |> String.split("\n")
      |> Enum.reject(&(&1 =~ ~r/^\s*#/))
      |> Enum.join("\n")

    for tool <- @tool_candidates,
        code =~ ~r/(^|[;&|({\s]|\$\()#{tool}(\s|$)/m,
        do: tool
  end

  test "docs leg: every external command its functions call is in need_tools (IN-03)" do
    src = File.read!(@script)
    used = docs_tools_used(src)
    assert used != []
    listed = need_tools_from_source("docs")
    assert listed != []

    for tool <- used -- ["leg_docs"] do
      assert tool in listed, "docs leg calls #{tool} but need_tools does not list it"
    end

    # rm belongs to the EXIT cleanup trap only.
    refute "rm" in used

    # The detector can see an undeclared tool: inject one command into a docs function.
    mutated =
      String.replace(src, ~s(  cp "$body" "$step"), ~s(  sort "$body"\n  cp "$body" "$step"),
        global: false
      )

    assert mutated != src
    assert "sort" in docs_tools_used(mutated)
    refute "sort" in used
  end

  # ---- per-step time bound (docs_bounded) ------------------------------------------------

  # install.md whose first run block starts a background sleep (pid written to pidfile) and
  # then sleeps itself: only a process-group kill ends both.
  defp stuck_install(pidfile) do
    """
    # Install

    <!-- cleanroom:run id=stuck -->
    ```bash
    sleep 30 & echo $! > #{pidfile}
    sleep 30
    ```
    """
  end

  defp stuck_env(root, extra \\ []) do
    pidfile = Path.join(root, "child.pid")
    base = write_docs(root, docs_readme(), stuck_install(pidfile))
    {pidfile, docs_selftest_env(root, base, extra)}
  end

  defp os_alive?(pid), do: match?({_, 0}, System.cmd("kill", ["-0", pid], stderr_to_stdout: true))

  defp wait_until_dead(pid, tries \\ 30) do
    cond do
      not os_alive?(pid) -> true
      tries == 0 -> false
      true -> Process.sleep(100) && wait_until_dead(pid, tries - 1)
    end
  end

  test "docs leg: a step over the time bound is killed with its whole group and named", %{
    root: root
  } do
    {pidfile, env} = stuck_env(root, [{"CLEANROOM_DOCS_STEP_TIMEOUT", "2"}])

    started = System.monotonic_time(:millisecond)
    {out, rc} = run(@script, ["0.0.1"], env)
    elapsed = System.monotonic_time(:millisecond) - started

    assert rc == 1, out
    lines = String.split(out, "\n")
    assert "cleanroom: FAIL docs step stuck timeout 2" in lines
    assert last_line(out) == "cleanroom: result FAIL legs docs version 0.0.1"
    refute out =~ "leg docs PASS"
    assert elapsed < 20_000, "took #{elapsed} ms"

    child = pidfile |> File.read!() |> String.trim()
    assert child =~ ~r/^[0-9]+$/
    assert wait_until_dead(child), "background child #{child} outlived its step"
  end

  test "docs leg: a host-generation command over the time bound is step host_setup timeout", %{
    root: root
  } do
    base = write_docs(root, docs_readme(), docs_install())
    stubs = Path.join(root, "slowmix")
    File.mkdir_p!(stubs)
    File.write!(Path.join(stubs, "mix"), "#!/bin/sh\nsleep 30\n")
    File.chmod!(Path.join(stubs, "mix"), 0o755)

    env =
      docs_selftest_env(root, base, [
        {"CLEANROOM_DOCS_STEP_TIMEOUT", "2"},
        {"PATH", stubs <> ":" <> System.get_env("PATH", "")}
      ])

    started = System.monotonic_time(:millisecond)
    {out, rc} = run(@script, ["0.0.1"], env)

    assert rc == 1, out
    assert "cleanroom: FAIL docs step host_setup timeout 2" in String.split(out, "\n")
    refute out =~ "leg docs PASS"
    assert System.monotonic_time(:millisecond) - started < 20_000
  end

  defp port_env(env) do
    for {k, v} <- @selftest_env ++ env do
      {String.to_charlist(k), if(v, do: String.to_charlist(v), else: false)}
    end
  end

  defp collect_port(port, acc, deadline) do
    left = max(deadline - System.monotonic_time(:millisecond), 0)

    receive do
      {^port, {:data, data}} -> collect_port(port, acc <> data, deadline)
      {^port, {:exit_status, status}} -> {acc, status}
    after
      left -> {acc, :timeout}
    end
  end

  defp wait_for_file(path, tries \\ 150) do
    cond do
      File.exists?(path) and File.read!(path) != "" -> true
      tries == 0 -> false
      true -> Process.sleep(100) && wait_for_file(path, tries - 1)
    end
  end

  test "docs leg: TERM while a step runs kills its group and ends interrupted, never 0", %{
    root: root
  } do
    {pidfile, env} = stuck_env(root)

    port =
      Port.open({:spawn_executable, System.find_executable("bash")}, [
        :binary,
        :exit_status,
        :stderr_to_stdout,
        args: [@script, "0.0.1"],
        env: port_env(env)
      ])

    {:os_pid, os_pid} = Port.info(port, :os_pid)
    assert wait_for_file(pidfile), "the step never started"
    {_, 0} = System.cmd("kill", ["-TERM", Integer.to_string(os_pid)])

    {out, status} = collect_port(port, "", System.monotonic_time(:millisecond) + 20_000)

    if status == :timeout, do: System.cmd("kill", ["-KILL", Integer.to_string(os_pid)])

    assert status == 1, out
    lines = String.split(out, "\n")
    assert "cleanroom: FAIL docs step stuck interrupted" in lines
    assert last_line(out) == "cleanroom: result FAIL legs docs version 0.0.1"
    refute out =~ "leg docs PASS"

    child = pidfile |> File.read!() |> String.trim()
    assert wait_until_dead(child), "background child #{child} outlived the interrupted step"
  end

  test "an invalid step time bound exits 2 with the usage line before any fetch", %{root: root} do
    base = write_docs(root, docs_readme(), docs_install())

    for bad <- ["abc", "0", "-5", "1.5", "07"] do
      {out, rc} =
        run(
          @script,
          ["0.0.1"],
          docs_selftest_env(root, base, [{"CLEANROOM_DOCS_STEP_TIMEOUT", bad}])
        )

      assert rc == 2, "#{bad}: #{out}"
      assert out =~ "cleanroom: usage", "#{bad}: #{out}"
      refute out =~ "docs source commit", "#{bad}: #{out}"
    end

    # A selector, not an override: the bad value is a usage error, not a refusal.
    {out, rc} = run(@script, ["0.2.11"], [{"CLEANROOM_DOCS_STEP_TIMEOUT", "abc"}])
    assert rc == 2
    assert out =~ "cleanroom: usage"
    refute out =~ "override refused"
  end

  test "the step time bound is a script constant and a selector, not a refused override" do
    src = File.read!(@script)
    assert src =~ ~r/^DOCS_STEP_TIMEOUT_DEFAULT=900$/m
    [line] = Enum.filter(String.split(src, "\n"), &(&1 =~ ~s(if [ "$LEGS" != "$DEFAULT_LEGS" ])))
    refute line =~ "CLEANROOM_DOCS_STEP_TIMEOUT"

    # Every documented step and every host-generation command goes through the bound.
    assert length(Regex.scan(~r/docs_bounded /, src)) >= 3
    assert src =~ ~r/docs_bounded "\$id" docs_step_exec/
    assert src =~ ~r/docs_bounded host_setup docs_setup_exec/
  end

  test "the script locates nothing relative to itself or a checkout" do
    src = File.read!(@script)
    refute src =~ "BASH_SOURCE"
    refute src =~ ~r/dirname "?\$0/
    refute src =~ "rev-parse --show-toplevel"
    refute src =~ ~r/cp [^#\n]*tool-versions/
  end
end
