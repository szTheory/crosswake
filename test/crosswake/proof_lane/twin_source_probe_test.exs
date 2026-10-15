defmodule Crosswake.ProofLane.TwinSourceProbeTest do
  # Real temporary repositories prove that the twin source probe blocks every way git can
  # be set up to hide a difference between the working tree and HEAD. Each hiding fixture
  # first proves with raw git that the difference really is hidden, then asserts the exact
  # counts the probe returns.
  use ExUnit.Case, async: false

  alias Crosswake.ProofLane.{TwinGitFixtures, TwinProducers}

  @empty_tree "4b825dc642cb6eb9a060e54bf8d69288fbee4904"

  setup do
    {:ok, TwinGitFixtures.repo!()}
  end

  defp frozen_opts, do: [backend_digest: fn -> {:ok, String.duplicate("9", 64)} end]

  defp blind?(dir, env \\ []), do: TwinGitFixtures.raw_git(dir, ["status", "--porcelain"], env)

  # An unpinned git comparing the tree with a fresh index built from HEAD. A size change
  # already betrays an edit against a stat-carrying index, so the attribute fixtures
  # prove blindness here, where the index carries no sizes.
  defp fresh_blind?(ctx, env \\ []) do
    index = Path.join(ctx.side, "unpinned-index-#{System.unique_integer([:positive])}")
    index_env = [{"GIT_INDEX_FILE", index} | env]
    {_, 0} = TwinGitFixtures.raw_git(ctx.dir, ["read-tree", "HEAD"], index_env)
    blind?(ctx.dir, index_env)
  end

  test "an untouched clone probes clean", ctx do
    assert TwinProducers.probe_source(ctx.dir) == {:ok, %{modified: 0, flagged: 0, excludes: 0}}
    assert TwinProducers.clean_tree(ctx.dir) == :ok
    assert TwinProducers.dirty_count(ctx.dir) == 0
  end

  test "an assume-unchanged edit blocks with modified 1 and flagged 1", ctx do
    TwinGitFixtures.flag!(ctx.dir, "--assume-unchanged", "mix.lock")
    File.write!(Path.join(ctx.dir, "mix.lock"), "%{changed: true}\n")

    assert blind?(ctx.dir) == {"", 0}

    assert TwinProducers.probe_source(ctx.dir) == {:ok, %{modified: 1, flagged: 1, excludes: 0}}
    assert TwinProducers.clean_tree(ctx.dir) == {:blocked, :source_dirty}

    assert TwinProducers.freeze(ctx.runtime, ctx.identity.(%{}), frozen_opts()) ==
             {:blocked, :source_dirty}

    refute File.exists?(Path.join(ctx.runtime.run_root, "expectations.json"))
  end

  test "an info/exclude rule blocks with excludes 1", ctx do
    exclude = Path.join(ctx.dir, ".git/info/exclude")
    File.mkdir_p!(Path.dirname(exclude))
    File.write!(exclude, "# comment\nsecret.txt\n")

    assert TwinProducers.probe_source(ctx.dir) == {:ok, %{modified: 0, flagged: 0, excludes: 1}}
  end

  test "a skip-worktree edit blocks", ctx do
    TwinGitFixtures.flag!(ctx.dir, "--skip-worktree", "mix.lock")
    File.write!(Path.join(ctx.dir, "mix.lock"), "%{changed: true}\n")

    assert blind?(ctx.dir) == {"", 0}
    assert TwinProducers.probe_source(ctx.dir) == {:ok, %{modified: 1, flagged: 1, excludes: 0}}
  end

  test "an ignoreStat edit blocks", ctx do
    # core.ignoreStat only marks entries while git rewrites them, so it is set before add.
    TwinGitFixtures.set_config!(ctx.dir, "core.ignoreStat", "true")
    File.write!(Path.join(ctx.dir, "mix.lock"), "%{first: true}\n")
    TwinGitFixtures.git!(ctx.dir, ["add", "mix.lock"])
    TwinGitFixtures.git!(ctx.dir, ["commit", "-q", "-m", "first"])
    File.write!(Path.join(ctx.dir, "mix.lock"), "%{second: true}\n")

    assert String.starts_with?(
             TwinGitFixtures.git!(ctx.dir, ["ls-files", "-v", "mix.lock"]),
             "h "
           )

    assert blind?(ctx.dir) == {"", 0}
    assert TwinProducers.probe_source(ctx.dir) == {:ok, %{modified: 1, flagged: 1, excludes: 0}}
  end

  test "a trustctime=false same-size same-mtime edit blocks through the fresh index", ctx do
    TwinGitFixtures.set_config!(ctx.dir, "core.trustctime", "false")
    TwinGitFixtures.same_mtime_edit!(Path.join(ctx.dir, "stat.txt"), "bbbb\n")

    assert blind?(ctx.dir) == {"", 0}
    assert TwinProducers.probe_source(ctx.dir) == {:ok, %{modified: 1, flagged: 0, excludes: 0}}
  end

  test "a checkStat=minimal swapped file blocks through the fresh index", ctx do
    TwinGitFixtures.set_config!(ctx.dir, "core.checkStat", "minimal")
    replacement = Path.join(ctx.side, "swap-replacement")
    TwinGitFixtures.same_mtime_edit!(replacement, "bbbb\n")
    File.rename!(replacement, Path.join(ctx.dir, "swap.txt"))
    File.touch!(Path.join(ctx.dir, "swap.txt"), TwinGitFixtures.old_mtime())

    assert blind?(ctx.dir) == {"", 0}
    assert TwinProducers.probe_source(ctx.dir) == {:ok, %{modified: 1, flagged: 0, excludes: 0}}
  end

  test "a local filemode=false mode change blocks", ctx do
    TwinGitFixtures.set_config!(ctx.dir, "core.filemode", "false")
    File.chmod!(Path.join(ctx.dir, "run.sh"), 0o755)

    assert blind?(ctx.dir) == {"", 0}
    assert TwinProducers.probe_source(ctx.dir) == {:ok, %{modified: 1, flagged: 0, excludes: 0}}
  end

  test "a global filemode=false mode change blocks while unpinned git is fooled", ctx do
    # git init writes core.filemode=true locally, which beats the global value.
    TwinGitFixtures.git!(ctx.dir, ["config", "--local", "--unset", "core.filemode"])
    global = Path.join(ctx.side, "global-gitconfig")
    File.write!(global, "[core]\n\tfilemode = false\n")
    File.chmod!(Path.join(ctx.dir, "run.sh"), 0o755)

    # With no global value git sees the mode change; with it git is blind.
    assert {" M run.sh\n", 0} = blind?(ctx.dir)
    assert blind?(ctx.dir, [{"GIT_CONFIG_GLOBAL", global}]) == {"", 0}

    TwinGitFixtures.env_restore("GIT_CONFIG_GLOBAL")
    System.put_env("GIT_CONFIG_GLOBAL", global)

    assert TwinProducers.probe_source(ctx.dir) == {:ok, %{modified: 1, flagged: 0, excludes: 0}}
  end

  test "an assume-unchanged flag without an edit blocks with flagged 1", ctx do
    TwinGitFixtures.flag!(ctx.dir, "--assume-unchanged", "mix.lock")

    assert TwinProducers.probe_source(ctx.dir) == {:ok, %{modified: 0, flagged: 1, excludes: 0}}
    assert TwinProducers.clean_tree(ctx.dir) == {:blocked, :source_dirty}
  end

  test "an unmerged entry counts once as flagged", ctx do
    TwinGitFixtures.unmerged!(ctx.dir)

    assert {:ok, %{flagged: 1, excludes: 0}} = TwinProducers.probe_source(ctx.dir)
    assert TwinProducers.clean_tree(ctx.dir) == {:blocked, :source_dirty}
  end

  test "an untracked file blocks", ctx do
    File.write!(Path.join(ctx.dir, "new.ex"), "defmodule New do\nend\n")

    assert TwinProducers.probe_source(ctx.dir) == {:ok, %{modified: 1, flagged: 0, excludes: 0}}
  end

  test "a tracked eol attribute cannot hide a CRLF-only edit", ctx do
    File.write!(Path.join(ctx.dir, ".gitattributes"), "* text eol=lf\n")
    TwinGitFixtures.git!(ctx.dir, ["add", ".gitattributes"])
    TwinGitFixtures.git!(ctx.dir, ["commit", "-q", "-m", "attributes"])
    TwinGitFixtures.crlf_edit!(ctx.dir, "mix.lock")

    assert fresh_blind?(ctx) == {"", 0}
    assert TwinProducers.probe_source(ctx.dir) == {:ok, %{modified: 1, flagged: 0, excludes: 0}}
  end

  test "a user-level attributes file cannot hide a CRLF-only edit", ctx do
    home = Path.join(ctx.side, "attr-home")
    File.mkdir_p!(Path.join(home, ".config/git"))
    File.write!(Path.join(home, ".config/git/attributes"), "* text eol=lf\n")
    user_env = [{"HOME", home}, {"XDG_CONFIG_HOME", Path.join(home, ".config")}]
    TwinGitFixtures.crlf_edit!(ctx.dir, "mix.lock")

    assert fresh_blind?(ctx, user_env) == {"", 0}

    TwinGitFixtures.env_restore("HOME")
    TwinGitFixtures.env_restore("XDG_CONFIG_HOME")
    System.put_env("HOME", home)
    System.put_env("XDG_CONFIG_HOME", Path.join(home, ".config"))

    assert TwinProducers.probe_source(ctx.dir) == {:ok, %{modified: 1, flagged: 0, excludes: 0}}
  end

  test "a hostile caller GIT_ environment is ignored", ctx do
    other = Path.join(ctx.side, "other-repo")
    File.mkdir_p!(other)
    TwinGitFixtures.git!(other, ["init", "-q"])
    hostile_index = Path.join(ctx.side, "hostile-index")

    for name <-
          ~w(GIT_CONFIG_COUNT GIT_CONFIG_KEY_0 GIT_CONFIG_VALUE_0 GIT_INDEX_FILE GIT_ATTR_SOURCE GIT_DIR) do
      TwinGitFixtures.env_restore(name)
    end

    System.put_env("GIT_CONFIG_COUNT", "1")
    System.put_env("GIT_CONFIG_KEY_0", "core.filemode")
    System.put_env("GIT_CONFIG_VALUE_0", "false")
    System.put_env("GIT_INDEX_FILE", hostile_index)
    System.put_env("GIT_ATTR_SOURCE", @empty_tree)
    System.put_env("GIT_DIR", Path.join(other, ".git"))

    assert TwinProducers.probe_source(ctx.dir) == {:ok, %{modified: 0, flagged: 0, excludes: 0}}

    File.chmod!(Path.join(ctx.dir, "run.sh"), 0o755)

    assert TwinProducers.probe_source(ctx.dir) == {:ok, %{modified: 1, flagged: 0, excludes: 0}}
    refute File.exists?(hostile_index)
  end

  test "a temp dir that cannot be created or removed fails closed", ctx do
    sandbox = Path.join(ctx.side, "tmp-sandbox")
    File.mkdir_p!(sandbox)

    missing = Path.join(ctx.side, "no-such-dir")
    assert TwinProducers.probe_source(ctx.dir, tmp_dir: missing) == :unavailable

    assert TwinProducers.clean_tree(ctx.dir, tmp_dir: missing) ==
             {:blocked, :prerequisite_missing}

    stuck = fn _dir -> {:error, :eperm, "x"} end

    assert TwinProducers.probe_source(ctx.dir, tmp_dir: sandbox, remove_dir: stuck) ==
             :unavailable

    assert TwinProducers.clean_tree(ctx.dir, tmp_dir: sandbox, remove_dir: stuck) ==
             {:blocked, :prerequisite_missing}

    assert TwinProducers.dirty_count(ctx.dir, tmp_dir: sandbox, remove_dir: stuck) == nil

    # A relative base is refused and a working base leaves nothing behind.
    assert TwinProducers.probe_source(ctx.dir, tmp_dir: "relative-base") == :unavailable
    assert File.ls!(sandbox) == []

    assert TwinProducers.probe_source(ctx.dir, tmp_dir: sandbox) ==
             {:ok, %{modified: 0, flagged: 0, excludes: 0}}

    assert File.ls!(sandbox) == []
  end

  test "a temp dir inside the candidate is refused and nothing is created there", ctx do
    inside = Path.join(ctx.dir, "scratch-inside")
    File.mkdir!(inside)
    File.chmod!(inside, 0o700)
    before = TwinGitFixtures.listing(ctx.dir)

    assert TwinProducers.probe_source(ctx.dir, tmp_dir: inside) == :unavailable

    TwinGitFixtures.env_restore("TMPDIR")
    System.put_env("TMPDIR", inside)
    assert TwinProducers.probe_source(ctx.dir) == :unavailable

    # The git dir and the run root are protected too.
    git_dir = Path.join(ctx.dir, ".git")
    assert TwinProducers.probe_source(ctx.dir, tmp_dir: git_dir) == :unavailable

    run_root = Path.join(ctx.side, "run-root")
    File.mkdir_p!(run_root)

    assert TwinProducers.probe_source(ctx.dir, tmp_dir: run_root, run_root: ctx.side) ==
             :unavailable

    assert TwinGitFixtures.listing(ctx.dir) == before
    assert File.ls!(run_root) == []
  end

  test "a core.worktree redirect is refused as not the top-level directory", ctx do
    copy = TwinGitFixtures.worktree_redirect!(ctx.dir)
    File.write!(Path.join(ctx.dir, "mix.lock"), "%{changed: true}\n")

    # git now reads the clean copy, so the edit in the candidate is invisible to it.
    index = Path.join(ctx.side, "redirect-index")
    env = [{"GIT_INDEX_FILE", index}]
    assert {_, 0} = TwinGitFixtures.raw_git(ctx.dir, ["read-tree", "HEAD"], env)
    assert blind?(ctx.dir, env) == {"", 0}
    assert File.read!(Path.join(copy, "mix.lock")) == "%{}\n"

    assert TwinProducers.probe_source(ctx.dir) == {:refused, :not_toplevel}
    assert TwinProducers.clean_tree(ctx.dir) == {:blocked, :source_dirty}
    assert TwinProducers.dirty_count(ctx.dir) == nil

    assert TwinProducers.freeze(ctx.runtime, ctx.identity.(%{}), frozen_opts()) ==
             {:blocked, :source_dirty}

    refute File.exists?(Path.join(ctx.runtime.run_root, "expectations.json"))
  end

  test "a filter key in local config is refused even with nothing modified", ctx do
    TwinGitFixtures.set_config!(ctx.dir, "filter.x.clean", "cat")

    assert TwinProducers.probe_source(ctx.dir) == {:refused, :hiding_config}
    assert TwinProducers.clean_tree(ctx.dir) == {:blocked, :source_dirty}
    assert TwinProducers.dirty_count(ctx.dir) == nil

    TwinGitFixtures.git!(ctx.dir, ["config", "--local", "--unset", "filter.x.clean"])
    TwinGitFixtures.set_config!(ctx.dir, "filter.Foo.clean", "cat")
    assert TwinProducers.probe_source(ctx.dir) == {:refused, :hiding_config}
  end

  test "a filter key in an included config file is refused", ctx do
    TwinGitFixtures.include_config!(ctx.dir, "included.cfg", "[filter \"x\"]\n\tclean = cat\n")

    assert TwinProducers.probe_source(ctx.dir) == {:refused, :hiding_config}
    assert TwinProducers.clean_tree(ctx.dir) == {:blocked, :source_dirty}
  end

  test "an active info/attributes line is refused even with nothing modified", ctx do
    attributes = Path.join(ctx.dir, ".git/info/attributes")
    File.mkdir_p!(Path.dirname(attributes))
    File.write!(attributes, "*.lock -text\n")

    assert TwinProducers.probe_source(ctx.dir) == {:refused, :hiding_config}
    assert TwinProducers.clean_tree(ctx.dir) == {:blocked, :source_dirty}
    assert TwinProducers.dirty_count(ctx.dir) == nil
  end

  test "a comment-only info/attributes file is not refused", ctx do
    attributes = Path.join(ctx.dir, ".git/info/attributes")
    File.mkdir_p!(Path.dirname(attributes))
    File.write!(attributes, "# comment\n\n")

    assert TwinProducers.probe_source(ctx.dir) == {:ok, %{modified: 0, flagged: 0, excludes: 0}}
  end

  test "core.bare, core.symlinks=false and extensions.worktreeConfig are refused", ctx do
    clean = {:ok, %{modified: 0, flagged: 0, excludes: 0}}

    TwinGitFixtures.set_config!(ctx.dir, "extensions.worktreeConfig", "false")
    TwinGitFixtures.set_config!(ctx.dir, "core.symlinks", "true")
    assert TwinProducers.probe_source(ctx.dir) == clean

    TwinGitFixtures.set_config!(ctx.dir, "core.bare", "true")
    assert TwinProducers.probe_source(ctx.dir) == {:refused, :hiding_config}
    TwinGitFixtures.set_config!(ctx.dir, "core.bare", "false")

    TwinGitFixtures.set_config!(ctx.dir, "core.symlinks", "false")
    assert TwinProducers.probe_source(ctx.dir) == {:refused, :hiding_config}
    TwinGitFixtures.set_config!(ctx.dir, "core.symlinks", "true")

    TwinGitFixtures.set_config!(ctx.dir, "extensions.worktreeConfig", "true")
    assert TwinProducers.probe_source(ctx.dir) == {:refused, :hiding_config}
  end

  test "a subdirectory candidate is refused", ctx do
    sub = Path.join(ctx.dir, "examples/phoenix_host")

    assert TwinProducers.probe_source(sub) == {:refused, :not_toplevel}
    assert TwinProducers.clean_tree(sub) == {:blocked, :source_dirty}
    assert TwinProducers.dirty_count(sub) == nil
  end

  test "a symlink alias of the candidate is not refused", ctx do
    alias_path = Path.join(ctx.side, "alias-of-candidate")
    File.ln_s!(ctx.dir, alias_path)

    assert TwinProducers.probe_source(alias_path) ==
             {:ok, %{modified: 0, flagged: 0, excludes: 0}}
  end

  # A git_cmd stub: `reply.(argv_after_sh, env)` returns `:real` to delegate to System.cmd/3
  # or the value to hand back. Every call is counted.
  defp stub(counter, reply) do
    fn cmd, args, opts ->
      Agent.update(counter, &(&1 + 1))
      ["-c", _script, "sh", "git" | argv] = args

      case reply.(argv, Keyword.fetch!(opts, :env)) do
        :real -> System.cmd(cmd, args, opts)
        other -> other
      end
    end
  end

  defp counter, do: start_supervised!({Agent, fn -> 0 end}, id: make_ref())
  defp calls(counter), do: Agent.get(counter, & &1)

  defp subcommand?(argv, name), do: name in argv

  defp fresh_index?(env) do
    case List.keyfind(env, "GIT_INDEX_FILE", 0) do
      {_, value} when is_binary(value) -> true
      _ -> false
    end
  end

  defp bare_repo_dir(ctx, name) do
    dir = Path.join(ctx.side, name)
    File.mkdir_p!(dir)
    TwinGitFixtures.git!(dir, ["init", "-q"])
    dir
  end

  test "zero tracked entries fail closed", ctx do
    dir = bare_repo_dir(ctx, "empty-tree-repo")
    TwinGitFixtures.git!(dir, ["commit", "-q", "--allow-empty", "-m", "empty"])

    assert TwinProducers.probe_source(dir) == :unavailable
    assert TwinProducers.clean_tree(dir) == {:blocked, :prerequisite_missing}
    assert TwinProducers.dirty_count(dir) == nil
  end

  test "a repository without commits fails closed", ctx do
    dir = bare_repo_dir(ctx, "no-commit-repo")
    File.write!(Path.join(dir, "f.txt"), "x\n")
    TwinGitFixtures.git!(dir, ["add", "f.txt"])

    assert TwinProducers.probe_source(dir) == :unavailable
    assert TwinProducers.clean_tree(dir) == {:blocked, :prerequisite_missing}
  end

  test "an unknown ls-files tag fails closed", ctx do
    c = counter()

    git_cmd =
      stub(c, fn argv, _env ->
        if subcommand?(argv, "ls-files"), do: {"X f\0", 0}, else: :real
      end)

    assert TwinProducers.probe_source(ctx.dir, git_cmd: git_cmd) == :unavailable

    assert TwinProducers.clean_tree(ctx.dir, git_cmd: git_cmd) ==
             {:blocked, :prerequisite_missing}
  end

  test "truncated -z output fails closed", ctx do
    c = counter()

    git_cmd =
      stub(c, fn argv, _env ->
        if subcommand?(argv, "ls-files"), do: {"H f", 0}, else: :real
      end)

    assert TwinProducers.probe_source(ctx.dir, git_cmd: git_cmd) == :unavailable

    status_cut =
      stub(counter(), fn argv, env ->
        if subcommand?(argv, "status") and fresh_index?(env), do: {" M f", 0}, else: :real
      end)

    assert TwinProducers.probe_source(ctx.dir, git_cmd: status_cut) == :unavailable

    config_cut =
      stub(counter(), fn argv, _env ->
        if subcommand?(argv, "--list"), do: {"core.bare\nfalse", 0}, else: :real
      end)

    assert TwinProducers.probe_source(ctx.dir, git_cmd: config_cut) == :unavailable
  end

  test "a non-H entry in the fresh index fails closed", ctx do
    git_cmd =
      stub(counter(), fn argv, env ->
        if subcommand?(argv, "ls-files") and fresh_index?(env),
          do: {"h mix.lock\0", 0},
          else: :real
      end)

    assert TwinProducers.probe_source(ctx.dir, git_cmd: git_cmd) == :unavailable

    assert TwinProducers.clean_tree(ctx.dir, git_cmd: git_cmd) ==
             {:blocked, :prerequisite_missing}
  end

  test "a rejected argv fails closed", ctx do
    for rc <- [128, 129] do
      git_cmd =
        stub(counter(), fn argv, _env ->
          if subcommand?(argv, "--version"), do: :real, else: {"", rc}
        end)

      assert TwinProducers.probe_source(ctx.dir, git_cmd: git_cmd) == :unavailable

      assert TwinProducers.clean_tree(ctx.dir, git_cmd: git_cmd) ==
               {:blocked, :prerequisite_missing}

      assert TwinProducers.dirty_count(ctx.dir, git_cmd: git_cmd) == nil
    end
  end

  test "git older than 2.41 or an unparseable version fails closed", ctx do
    for text <- ["git version 2.40.9\n", "git version 2.9.0\n", "not git\n"] do
      c = counter()

      git_cmd =
        stub(c, fn argv, _env ->
          if subcommand?(argv, "--version"), do: {text, 0}, else: :real
        end)

      assert TwinProducers.probe_source(ctx.dir, git_cmd: git_cmd) == :unavailable
      # only the version call ran: nothing pinned and no retry
      assert calls(c) == 1
    end

    for text <- ["git version 2.41.0\n", "git version 2.50.1 (Apple Git-155)\n"] do
      git_cmd =
        stub(counter(), fn argv, _env ->
          if subcommand?(argv, "--version"), do: {text, 0}, else: :real
        end)

      assert TwinProducers.probe_source(ctx.dir, git_cmd: git_cmd) ==
               {:ok, %{modified: 0, flagged: 0, excludes: 0}}
    end
  end

  test "a raising spawn fails closed without leaking its message", ctx do
    marker = "/secret/place-" <> Base.encode16(:crypto.strong_rand_bytes(6))

    raisers = [
      fn -> raise ArgumentError, "invalid path " <> marker end,
      fn -> raise ErlangError, original: {:enoent, marker} end
    ]

    for raiser <- raisers, target <- ["--version", "ls-files", "--list"] do
      git_cmd =
        stub(counter(), fn argv, _env ->
          if subcommand?(argv, target), do: raiser.(), else: :real
        end)

      result = TwinProducers.probe_source(ctx.dir, git_cmd: git_cmd)
      assert result == :unavailable
      refute inspect(result) =~ marker
      refute inspect(TwinProducers.clean_tree(ctx.dir, git_cmd: git_cmd)) =~ marker
    end
  end

  test "a NUL in the candidate path is refused before spawning", ctx do
    c = counter()
    git_cmd = stub(c, fn _argv, _env -> flunk("git must not be spawned") end)
    nul_path = ctx.dir <> <<0>> <> "tail"

    assert TwinProducers.probe_source(nul_path, git_cmd: git_cmd) == :unavailable

    assert TwinProducers.clean_tree(nul_path, git_cmd: git_cmd) ==
             {:blocked, :prerequisite_missing}

    assert TwinProducers.dirty_count(nul_path, git_cmd: git_cmd) == nil
    assert calls(c) == 0
  end

  test "a hung git call times out closed", ctx do
    git_cmd =
      stub(counter(), fn argv, _env ->
        if subcommand?(argv, "ls-files") do
          Process.sleep(5_000)
          {"", 0}
        else
          :real
        end
      end)

    started = System.monotonic_time(:millisecond)

    assert TwinProducers.probe_source(ctx.dir, git_cmd: git_cmd, git_timeout_ms: 50) ==
             :unavailable

    assert System.monotonic_time(:millisecond) - started < 4_000
  end

  @expected_pins [
    "--no-optional-locks",
    "--no-replace-objects",
    "--attr-source=" <> @empty_tree,
    "-c",
    "core.fsmonitor=false",
    "-c",
    "core.filemode=true",
    "-c",
    "core.excludesFile=/dev/null",
    "-c",
    "core.attributesFile=/dev/null",
    "-c",
    "core.quotePath=false",
    "-c",
    "core.ignoreStat=false",
    "-c",
    "status.showUntrackedFiles=all",
    "-c",
    "core.autocrlf=false"
  ]

  defp recorder do
    {:ok, agent} = Agent.start_link(fn -> [] end)

    git_cmd = fn cmd, args, opts ->
      Agent.update(agent, &[{cmd, args, Keyword.fetch!(opts, :env)} | &1])
      System.cmd(cmd, args, opts)
    end

    {agent, git_cmd}
  end

  defp recorded(agent), do: agent |> Agent.get(& &1) |> Enum.reverse()

  defp conforming?({"sh", ["-c", _script, "sh", "git" | argv], env}) do
    shaped =
      argv == ["--version"] or
        (Enum.take(argv, length(@expected_pins)) == @expected_pins and
           Enum.at(argv, length(@expected_pins)) == "-C")

    shaped and {"GIT_CONFIG_GLOBAL", "/dev/null"} in env and {"GIT_DIR", nil} in env
  end

  defp conforming?(_), do: false

  defp nonconforming(entries), do: Enum.reject(entries, &conforming?/1)

  defp live_for(frozen) do
    %{
      installed_manifest: frozen.identity.manifest,
      installed_activation: frozen.identity.activation,
      installed_media: frozen.identity.media,
      executable_stable: true,
      served_js: frozen.study_js,
      backend_build: frozen.backend_build
    }
  end

  test "every twin git call goes through the shared builder", ctx do
    {agent, git_cmd} = recorder()

    assert {:ok, frozen} =
             TwinProducers.freeze(
               ctx.runtime,
               ctx.identity.(%{}),
               [git_cmd: git_cmd] ++ frozen_opts()
             )

    freeze_calls = recorded(agent)
    assert length(freeze_calls) >= 10
    assert nonconforming(freeze_calls) == []

    entry_points = [
      probe_source: fn opts -> TwinProducers.probe_source(ctx.dir, opts) end,
      clean_tree: fn opts -> TwinProducers.clean_tree(ctx.dir, opts) end,
      dirty_count: fn opts -> TwinProducers.dirty_count(ctx.dir, opts) end,
      source_gate: fn opts ->
        TwinProducers.source_gate(ctx.runtime, ctx.identity.(%{}), opts)
      end,
      observe_identities: fn opts ->
        TwinProducers.observe_identities(frozen, live_for(frozen), opts)
      end,
      checked_identities: fn opts ->
        TwinProducers.checked_identities(frozen, live_for(frozen), opts)
      end
    ]

    for {name, run} <- entry_points do
      {entry_agent, entry_cmd} = recorder()
      run.(git_cmd: entry_cmd)
      entry_calls = recorded(entry_agent)
      assert {name, length(entry_calls) >= 1} == {name, true}
      assert {name, nonconforming(entry_calls)} == {name, []}
    end
  end

  test "source_gate checks identity, head, tree and cleanliness without writing", ctx do
    target = %{candidate_path: ctx.dir, candidate_head: ctx.head, candidate_tree: ctx.tree}
    identity = ctx.identity.(%{})
    listed = TwinGitFixtures.listing(ctx.side)
    repo_listed = TwinGitFixtures.listing(ctx.dir)

    assert {:ok, gate} = TwinProducers.source_gate(target, identity)
    assert Map.keys(gate) |> Enum.sort() == [:head, :identity, :locks, :study_js, :tree]
    assert gate.head == ctx.head
    assert gate.tree == ctx.tree
    assert gate.identity.size == 15
    assert length(gate.locks) == 2
    assert TwinGitFixtures.listing(ctx.side) == listed
    assert TwinGitFixtures.listing(ctx.dir) == repo_listed

    assert TwinProducers.source_gate(
             %{target | candidate_head: String.duplicate("0", 40)},
             identity
           ) ==
             {:blocked, :identity_mismatch}

    assert TwinProducers.source_gate(target, Path.join(ctx.side, "missing.json")) ==
             {:blocked, :identity_unknown}

    File.write!(Path.join(ctx.dir, "untracked.txt"), "x")
    assert TwinProducers.source_gate(target, identity) == {:blocked, :source_dirty}
  end

  test "a raising spawn in freeze or observe_identities leaks no path", ctx do
    {:ok, frozen} = TwinProducers.freeze(ctx.runtime, ctx.identity.(%{}), frozen_opts())
    marker = "/secret/place-" <> Base.encode16(:crypto.strong_rand_bytes(6))
    git_cmd = fn _cmd, _args, _opts -> raise ArgumentError, "invalid path " <> marker end

    frozen_result =
      TwinProducers.freeze(ctx.runtime, ctx.identity.(%{}), [git_cmd: git_cmd] ++ frozen_opts())

    assert frozen_result == {:blocked, :prerequisite_missing}
    refute inspect(frozen_result) =~ marker
    refute inspect(frozen_result) =~ ctx.dir

    observed = TwinProducers.observe_identities(frozen, live_for(frozen), git_cmd: git_cmd)
    refute Map.has_key?(observed, :source)
    refute Map.has_key?(observed, :installed_build)
    refute inspect(observed) =~ marker
    refute inspect(observed) =~ ctx.dir

    checked = TwinProducers.checked_identities(frozen, live_for(frozen), git_cmd: git_cmd)
    assert checked == {:blocked, :prerequisite_missing}
    refute inspect(checked) =~ marker
  end

  @tail ", then write a new prepared record and run into a new run root."
  @unknown "The candidate has changes git could not count. Run git ls-files -v in the candidate " <>
             "(entries not marked H are flagged) and read the local exclude file " <>
             ".git/info/exclude to find them, and commit or remove them" <> @tail
  @flag_fix "clear the flags with git update-index --no-assume-unchanged or git update-index --no-skip-worktree (git ls-files -v shows them as entries not marked H)"
  @hiding "The candidate's git configuration can hide changes (a worktree redirect, a filter, or .git/info/attributes); remove it" <>
            @tail
  @not_toplevel "The candidate is not the top-level directory of its git work tree (a subdirectory was given, or a core.worktree setting points git at another directory). Use the repository's top-level directory as the candidate, and if git config --local --get core.worktree prints a value, remove that setting" <>
                  @tail

  defp counts(m, f, x), do: {:ok, %{modified: m, flagged: f, excludes: x}}

  test "line-4 text for each probe outcome is exact" do
    assert TwinProducers.source_block_action(counts(1, 0, 0)) ==
             "The candidate has 1 changed or untracked file. Commit or remove the changes" <>
               @tail

    assert TwinProducers.source_block_action(counts(2, 0, 0)) ==
             "The candidate has 2 changed or untracked files. Commit or remove the changes" <>
               @tail

    assert TwinProducers.source_block_action(counts(0, 1, 0)) ==
             "The candidate has 1 tracked file marked unchanged in git's index (assume-unchanged or skip-worktree flags), so edits to it would go unseen. Clear the flags with git update-index --no-assume-unchanged or git update-index --no-skip-worktree (git ls-files -v shows them as entries not marked H)" <>
               @tail

    x_only = TwinProducers.source_block_action(counts(0, 0, 2))

    assert x_only ==
             "The candidate has 2 local ignore rules in .git/info/exclude. Remove the ignore rules from .git/info/exclude" <>
               @tail

    refute x_only =~ "files"

    assert TwinProducers.source_block_action(counts(1, 2, 1)) ==
             "The candidate has 1 changed or untracked file; and 2 tracked files marked unchanged in git's index (assume-unchanged or skip-worktree flags), so edits to them would go unseen; and 1 local ignore rule in .git/info/exclude. Commit or remove the changes; " <>
               @flag_fix <>
               "; remove the ignore rules from .git/info/exclude" <> @tail

    assert TwinProducers.source_block_action({:refused, :hiding_config}) == @hiding
    assert TwinProducers.source_block_action({:refused, :not_toplevel}) == @not_toplevel

    for unknown <- [:unavailable, counts(1_000_001, 0, 0), counts(0, 0, 0), :garbage] do
      text = TwinProducers.source_block_action(unknown)
      assert text == @unknown
      refute text =~ ~r/\d/
    end
  end

  test "a candidate that is not the top-level directory gets its own next action", ctx do
    text = TwinProducers.source_block_action({:refused, :not_toplevel})
    assert text == @not_toplevel
    assert text != TwinProducers.source_block_action({:refused, :hiding_config})
    refute text =~ "remove it"

    sub = Path.join(ctx.dir, "examples/phoenix_host")
    assert TwinProducers.source_block_action(TwinProducers.probe_source(sub)) == @not_toplevel
  end

  test "dirty_counts reports modified, flagged and excludes separately", ctx do
    assert TwinProducers.dirty_counts(ctx.dir) == %{modified: 0, flagged: 0, excludes: 0}

    TwinGitFixtures.flag!(ctx.dir, "--assume-unchanged", "mix.lock")
    File.write!(Path.join(ctx.dir, "mix.lock"), "%{changed: true}\n")

    assert TwinProducers.dirty_counts(ctx.dir) == %{modified: 1, flagged: 1, excludes: 0}
    assert TwinProducers.dirty_count(ctx.dir) == 2

    sub = Path.join(ctx.dir, "examples/phoenix_host")
    assert TwinProducers.dirty_counts(sub) == nil
    assert TwinProducers.dirty_count(sub) == nil

    assert TwinProducers.dirty_counts(ctx.dir, git_cmd: fn _, _, _ -> {"", 1} end) == nil
  end

  test "the dirty bound equals the receipt measure bound" do
    attrs = fn measure ->
      %{
        id: "TW-T01-01",
        owner: :host_adapter,
        run_id: "twin-0123456789abcdef",
        outcome: :blocked,
        measure: measure,
        cause: :source_dirty
      }
    end

    max = TwinProducers.max_dirty_count()
    {id, owner} = first_roster_entry()
    ok = Crosswake.ProofLane.TwinReceipt.observation(%{attrs.(max) | id: id, owner: owner})
    over = Crosswake.ProofLane.TwinReceipt.observation(%{attrs.(max + 1) | id: id, owner: owner})

    assert {:ok, %{measure: ^max}} = ok
    assert {:error, _} = over
  end

  defp first_roster_entry do
    [%{sub_observations: [%{id: id, owner: owner} | _]} | _] =
      Crosswake.ProofLane.TwinReceipt.roster()

    {id, owner}
  end
end
