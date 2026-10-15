defmodule Crosswake.ProofLane.TwinGitFixtures do
  @moduledoc false
  # Real temporary git repositories for the twin source probe tests. Each fixture lives
  # under the system temp dir with a sibling "<dir>-side" directory for identity files
  # and the run root, so nothing the probe or a test writes lands inside the repository.

  alias Crosswake.ProofLane.{TwinProducers, TwinRuntime}

  @old_mtime 978_307_200

  @doc "Whole-second POSIX mtime used for same-size, same-mtime recipes."
  def old_mtime, do: @old_mtime

  def repo! do
    dir =
      Path.join(
        System.tmp_dir!(),
        "twin-probe-" <> Base.encode16(:crypto.strong_rand_bytes(4))
      )

    host = Path.join(dir, "examples/phoenix_host")
    fixtures = Path.join(host, "native/ios/crosswake_shell/Fixtures")

    media_dir =
      Path.join(host, "native/ios/CrosswakeProofLane/Resources/ReferenceLearningBundle")

    File.mkdir_p!(fixtures)
    File.mkdir_p!(media_dir)
    File.mkdir_p!(Path.join(host, "priv/static"))
    File.write!(Path.join(dir, "mix.lock"), "%{}\n")
    File.write!(Path.join(host, "mix.lock"), "%{a: 1}\n")
    File.write!(Path.join(fixtures, "crosswake_manifest.json"), "{\"m\":1}")
    File.write!(Path.join(fixtures, "route_activation.json"), "{\"a\":1}")
    File.write!(Path.join(media_dir, "pronunciation.aiff"), "synthetic media")
    File.write!(Path.join(host, "priv/static/offline_study.js"), "// js")
    File.write!(Path.join(dir, "run.sh"), "#!/bin/sh\n")
    File.chmod!(Path.join(dir, "run.sh"), 0o644)
    # Same-mtime recipes need the recorded mtime set before the first `git add`.
    File.write!(Path.join(dir, "stat.txt"), "aaaa\n")
    File.touch!(Path.join(dir, "stat.txt"), @old_mtime)
    File.write!(Path.join(dir, "swap.txt"), "aaaa\n")
    File.touch!(Path.join(dir, "swap.txt"), @old_mtime)
    side = dir <> "-side"
    File.mkdir_p!(side)

    ExUnit.Callbacks.on_exit(fn -> File.rm_rf(dir) end)
    ExUnit.Callbacks.on_exit(fn -> File.rm_rf(side) end)

    git!(dir, ["init", "-q"])
    git!(dir, ["add", "-A"])
    git!(dir, ["commit", "-q", "-m", "fixture"])
    git!(dir, ["update-index", "--refresh"])

    head = git!(dir, ["rev-parse", "HEAD"])
    tree = git!(dir, ["rev-parse", "HEAD^{tree}"])

    {:ok, registry} = Agent.start_link(fn -> %{children: %{}, first_failure: nil} end)

    runtime = %TwinRuntime{
      run_id: "twin-0123456789abcdef",
      run_root: side,
      database_path: Path.join(side, "twin.sqlite3"),
      origin: "http://127.0.0.1:1",
      origin_port: 1,
      registry: registry,
      run_deadline_at: System.monotonic_time(:millisecond) + 60_000,
      candidate_path: dir,
      candidate_head: head,
      candidate_tree: tree
    }

    identity = fn overrides ->
      {:ok, media} = TwinProducers.file_digest(Path.join(media_dir, "pronunciation.aiff"))

      {:ok, manifest} =
        TwinProducers.file_digest(Path.join(fixtures, "crosswake_manifest.json"))

      {:ok, activation} =
        TwinProducers.file_digest(Path.join(fixtures, "route_activation.json"))

      base = %{
        "media" => %{"sha256" => media, "size" => 15},
        "generated" => %{"manifest_sha256" => manifest, "activation_sha256" => activation}
      }

      path = Path.join(side, "identity-#{System.unique_integer([:positive])}.json")
      File.write!(path, Jason.encode!(Map.merge(base, overrides)))
      path
    end

    %{
      dir: dir,
      side: side,
      head: head,
      tree: tree,
      runtime: runtime,
      identity: identity
    }
  end

  # Isolated real git: no user or system config, fixed dates, no signing.
  def git_env(dir) do
    home = dir <> "-side/home"
    File.mkdir_p!(home)

    [
      {"HOME", home},
      {"XDG_CONFIG_HOME", Path.join(home, ".config")},
      {"GIT_CONFIG_NOSYSTEM", "1"},
      {"GIT_CONFIG_GLOBAL", "/dev/null"},
      {"GIT_AUTHOR_DATE", "2026-01-01T00:00:00Z"},
      {"GIT_COMMITTER_DATE", "2026-01-01T00:00:00Z"}
    ]
  end

  @doc "Raw git: returns `{output, status}`; `env` entries override the isolated defaults."
  def raw_git(dir, args, env \\ []) do
    merged =
      Enum.reduce(env, git_env(dir), fn {name, value}, acc ->
        List.keystore(acc, name, 0, {name, value})
      end)

    System.cmd(
      "git",
      [
        "-c",
        "user.name=t",
        "-c",
        "user.email=t@example.test",
        "-c",
        "commit.gpgsign=false",
        "-c",
        "core.autocrlf=false",
        "-C",
        dir | args
      ],
      env: merged,
      stderr_to_stdout: true
    )
  end

  @doc "Raw git that must exit 0; returns the trimmed output."
  def git!(dir, args) do
    {out, 0} = raw_git(dir, args)
    String.trim(out)
  end

  @doc "Restores an environment variable at the end of the test."
  def env_restore(name) do
    old = System.get_env(name)

    ExUnit.Callbacks.on_exit(fn ->
      if old, do: System.put_env(name, old), else: System.delete_env(name)
    end)
  end

  @doc "Rewrites a file with the same size and puts its mtime back (same inode, same mtime)."
  def same_mtime_edit!(path, content, mtime \\ @old_mtime) do
    File.write!(path, content)
    File.touch!(path, mtime)
  end

  @doc "Sets an index flag (`--assume-unchanged`, `--skip-worktree`, ...) on a path."
  def flag!(dir, flag, path), do: git!(dir, ["update-index", flag, path])

  @doc "Sets a repository-local config key."
  def set_config!(dir, key, value), do: git!(dir, ["config", "--local", key, value])

  @doc "Points core.worktree at a clean copy of the repository; returns the copy path."
  def worktree_redirect!(dir) do
    copy = dir <> "-side/redirect-copy"
    File.cp_r!(dir, copy)
    git!(dir, ["config", "--local", "core.worktree", copy])
    copy
  end

  @doc "Writes a config file outside the repository and includes it from local config."
  def include_config!(dir, name, body) do
    file = Path.join(dir <> "-side", name)
    File.write!(file, body)
    git!(dir, ["config", "--local", "include.path", file])
    file
  end

  @doc "Leaves the repository with one conflicted (unmerged) path."
  def unmerged!(dir) do
    git!(dir, ["checkout", "-q", "-b", "other"])
    File.write!(Path.join(dir, "mix.lock"), "%{other: 1}\n")
    git!(dir, ["commit", "-q", "-am", "other"])
    git!(dir, ["checkout", "-q", "-"])
    File.write!(Path.join(dir, "mix.lock"), "%{main: 1}\n")
    git!(dir, ["commit", "-q", "-am", "main"])
    {_out, status} = raw_git(dir, ["merge", "other"])
    true = status != 0
    :ok
  end

  @doc "Replaces LF with CRLF in a tracked text file."
  def crlf_edit!(dir, rel) do
    path = Path.join(dir, rel)
    File.write!(path, path |> File.read!() |> String.replace("\n", "\r\n"))
  end

  @doc "Sorted `{relative_path, size, mtime}` for every entry under `root` (including .git)."
  def listing(root) do
    root
    |> Path.join("**")
    |> Path.wildcard(match_dot: true)
    |> Enum.map(fn path ->
      {:ok, %{size: size, mtime: mtime}} = File.lstat(path, time: :posix)
      {Path.relative_to(path, root), size, mtime}
    end)
    |> Enum.sort()
  end
end
