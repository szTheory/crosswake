defmodule Crosswake.ProofLane.ProvenanceTest do
  use ExUnit.Case, async: false

  alias Crosswake.ProofLane.Provenance

  setup do
    dir =
      Path.join(
        System.tmp_dir!(),
        "crosswake-provenance-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf(dir) end)
    {:ok, dir: dir}
  end

  defp git!(dir, args) do
    {out, 0} =
      System.cmd(
        "git",
        [
          "-c",
          "user.email=provenance@example.invalid",
          "-c",
          "user.name=provenance",
          "-c",
          "commit.gpgsign=false"
        ] ++
          args,
        cd: dir,
        stderr_to_stdout: true,
        env: [{"GIT_DIR", nil}, {"GIT_WORK_TREE", nil}, {"GIT_INDEX_FILE", nil}]
      )

    out
  end

  defp clean_repo!(dir) do
    git!(dir, ["init", "-q"])
    File.write!(Path.join(dir, "a.txt"), "one\n")
    git!(dir, ["add", "a.txt"])
    git!(dir, ["commit", "-q", "-m", "init"])
    String.trim(git!(dir, ["rev-parse", "HEAD"]))
  end

  test "a clean repository yields git- and its HEAD", %{dir: dir} do
    head = clean_repo!(dir)
    assert Provenance.commit_ref(dir) == "git-" <> head
  end

  test "a directory with no .git yields git-unknown", %{dir: dir} do
    refute File.exists?(Path.join(dir, ".git"))
    assert Provenance.commit_ref(dir) == "git-unknown"

    assert dir |> Provenance.read() |> Map.keys() |> Enum.sort() ==
             [:commit_ref, :crosswake_version, :template_version]
  end

  defp restore_env(name) do
    previous = System.get_env(name)

    on_exit(fn ->
      if previous, do: System.put_env(name, previous), else: System.delete_env(name)
    end)
  end

  defp write_manifest!(dir, contents) do
    path = Path.join([dir, "native", "ios", "crosswake_shell", ".crosswake", "shell.json"])
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, contents)
  end

  test "a repository with no commit yields git-unknown", %{dir: dir} do
    git!(dir, ["init", "-q"])
    assert Provenance.commit_ref(dir) == "git-unknown"
  end

  test "a missing host directory yields git-unknown", %{dir: dir} do
    assert Provenance.commit_ref(Path.join(dir, "does-not-exist")) == "git-unknown"
  end

  test "no git executable on PATH yields git-unknown", %{dir: dir} do
    clean_repo!(dir)
    empty = Path.join(dir, "empty-path")
    File.mkdir_p!(empty)
    restore_env("PATH")
    System.put_env("PATH", empty)
    assert Provenance.commit_ref(dir) == "git-unknown"
  end

  test "a modified or staged tracked file yields git-unknown", %{dir: dir} do
    clean_repo!(dir)
    File.write!(Path.join(dir, "a.txt"), "two\n")
    assert Provenance.commit_ref(dir) == "git-unknown"
    git!(dir, ["add", "a.txt"])
    assert Provenance.commit_ref(dir) == "git-unknown"
  end

  test "an untracked file alone keeps the real commit", %{dir: dir} do
    head = clean_repo!(dir)
    File.write!(Path.join(dir, "new.txt"), "untracked\n")
    assert Provenance.commit_ref(dir) == "git-" <> head
  end

  test "an inherited GIT_DIR does not redirect the read away from the host directory", %{dir: dir} do
    first = Path.join(dir, "first")
    second = Path.join(dir, "second")
    File.mkdir_p!(first)
    File.mkdir_p!(second)
    head = clean_repo!(first)
    other = clean_repo!(second)
    File.write!(Path.join(second, "a.txt"), "different\n")
    git!(second, ["commit", "-q", "-a", "-m", "second"])

    other =
      String.trim(git!(second, ["rev-parse", "HEAD"])) |> then(&(&1 <> String.slice(other, 0, 0)))

    refute head == other
    restore_env("GIT_DIR")
    System.put_env("GIT_DIR", Path.join(second, ".git"))
    assert Provenance.commit_ref(first) == "git-" <> head
  end

  test "a valid host shell manifest template_version is used", %{dir: dir} do
    cases = [7, 1, 99_999_999]
    assert length(cases) == 3

    for n <- cases do
      write_manifest!(dir, Jason.encode!(%{"template_version" => n}))
      assert Provenance.template_version(dir) == Integer.to_string(n)
    end
  end

  test "an absent, malformed or out-of-range manifest falls back to the generator template version",
       %{dir: dir} do
    fallback = Integer.to_string(Mix.Tasks.Crosswake.Gen.Shell.template_version())
    assert Provenance.template_version(dir) == fallback

    bodies = [
      "not json",
      "{}",
      ~s({"template_version":"7"}),
      ~s({"template_version":7.0}),
      ~s({"template_version":0}),
      ~s({"template_version":100000000})
    ]

    assert length(bodies) == 6

    for body <- bodies do
      write_manifest!(dir, body)
      assert Provenance.template_version(dir) == fallback
    end
  end

  test "crosswake_version is the loaded application version" do
    assert Provenance.crosswake_version() == to_string(Application.spec(:crosswake, :vsn))
    refute Provenance.crosswake_version() == "unknown"
  end
end
