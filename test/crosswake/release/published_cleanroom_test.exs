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
  @maven_path "io/github/sztheory/crosswake-shell-core-android/0.0.1"
  @artifact "crosswake-shell-core-android-0.0.1"

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

  defp build_maven_fixture(root) do
    base = Path.join(root, "maven")
    dir = Path.join(base, @maven_path)
    File.mkdir_p!(dir)

    files = %{
      "#{@artifact}.pom" =>
        "<project><version>0.0.1</version><packaging>aar</packaging></project>\n",
      "#{@artifact}.module" => ~s({"formatVersion":"1.1"}\n),
      "#{@artifact}.aar" => "PK-fixture-aar-bytes"
    }

    for {name, body} <- files do
      File.write!(Path.join(dir, name), body)

      digest = :crypto.hash(:sha256, body) |> Base.encode16(case: :lower)
      File.write!(Path.join(dir, name <> ".sha256"), digest <> "\n")
    end

    {"file://" <> base, dir}
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

  test "a pom whose version differs is pom_mismatch", %{root: root} do
    {base, dir} = build_maven_fixture(root)
    body = "<project><version>0.0.2</version><packaging>aar</packaging></project>\n"
    File.write!(Path.join(dir, "#{@artifact}.pom"), body)

    File.write!(
      Path.join(dir, "#{@artifact}.pom.sha256"),
      (:crypto.hash(:sha256, body) |> Base.encode16(case: :lower)) <> "\n"
    )

    {out, rc} = run(@script, ["0.0.1"], maven_selftest_env(base))
    assert rc == 1
    assert out =~ "cleanroom: FAIL maven pom_mismatch"
  end

  test "a missing tool is tool_unavailable, never a skip", %{root: root} do
    {base, _dir} = build_maven_fixture(root)
    bin = Path.join(root, "bin")
    File.mkdir_p!(bin)

    # Everything the script needs except curl.
    for tool <- ~w(mktemp rm cat grep sed tr cut head awk date mkdir uname shasum perl) do
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

  test "the script locates nothing relative to itself or a checkout" do
    src = File.read!(@script)
    refute src =~ "BASH_SOURCE"
    refute src =~ ~r/dirname "?\$0/
    refute src =~ "rev-parse --show-toplevel"
    refute src =~ ~r/cp [^#\n]*tool-versions/
  end
end
