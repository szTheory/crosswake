defmodule Mix.Tasks.Crosswake.Docs.SyncTest do
  use ExUnit.Case, async: false

  import Mix.Tasks.Crosswake.Docs.Sync, only: [run: 1]

  alias Crosswake.CapabilityMap
  alias Crosswake.CapabilityMap.Renderer, as: CapabilityRenderer
  alias Crosswake.SupportMatrix
  alias Crosswake.SupportMatrix.Renderer, as: SupportRenderer

  @remediation "mix crosswake.docs.sync"

  setup do
    root =
      Path.join(
        System.tmp_dir!(),
        "crosswake-docs-sync-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(Path.join(root, "guides"))
    on_exit(fn -> File.rm_rf!(root) end)

    Mix.shell(Mix.Shell.Process)
    on_exit(fn -> Mix.shell(Mix.Shell.IO) end)

    {:ok, root: root}
  end

  test "default mode writes both canonical projections and is idempotent", %{root: root} do
    in_root(root, fn -> run([]) end)

    capability_path = Path.join(root, "guides/capability_map.md")
    support_path = Path.join(root, "guides/support_matrix.md")

    assert File.read!(capability_path) == CapabilityRenderer.render(CapabilityMap.canonical())
    assert File.read!(support_path) == SupportRenderer.render(SupportMatrix.canonical())

    before = metadata([capability_path, support_path])
    in_root(root, fn -> run([]) end)
    assert metadata([capability_path, support_path]) == before

    messages = shell_messages()
    assert messages =~ "crosswake.docs.sync complete"
    assert messages =~ "reused: guides/capability_map.md"
    assert messages =~ "reused: guides/support_matrix.md"
  end

  test "check mode is observational when both projections match", %{root: root} do
    write_canonical_guides(root)
    paths = guide_paths(root)
    repo_snapshot = repository_snapshot()
    before = %{bytes: bytes(paths), metadata: metadata(paths)}

    in_root(root, fn -> run(["--check"]) end)

    assert %{bytes: bytes(paths), metadata: metadata(paths)} == before
    assert repository_snapshot() == repo_snapshot
    assert shell_messages() =~ "crosswake.docs.sync --check passed"
  end

  test "check mode reports all drift in target order without writing or leaking contents", %{
    root: root
  } do
    capability_path = Path.join(root, "guides/capability_map.md")
    support_path = Path.join(root, "guides/support_matrix.md")
    File.write!(capability_path, "CAPABILITY_SECRET")
    File.write!(support_path, "SUPPORT_SECRET")

    paths = guide_paths(root)
    before = %{bytes: bytes(paths), metadata: metadata(paths)}

    error =
      assert_raise Mix.Error, fn ->
        in_root(root, fn -> run(["--check"]) end)
      end

    assert %{bytes: bytes(paths), metadata: metadata(paths)} == before
    assert error.message =~ "lib/crosswake/capability_map.ex"
    assert error.message =~ "guides/capability_map.md"
    assert error.message =~ "lib/crosswake/support_matrix/support_matrix.ex"
    assert error.message =~ "guides/support_matrix.md"
    assert count(error.message, @remediation) == 1
    refute error.message =~ "CAPABILITY_SECRET"
    refute error.message =~ "SUPPORT_SECRET"

    assert :binary.match(error.message, "guides/capability_map.md") <
             :binary.match(error.message, "guides/support_matrix.md")
  end

  test "check mode reports a missing projection without creating it", %{root: root} do
    capability_path = Path.join(root, "guides/capability_map.md")
    support_path = Path.join(root, "guides/support_matrix.md")
    File.write!(capability_path, CapabilityRenderer.render())
    refute File.exists?(support_path)

    error = assert_raise Mix.Error, fn -> in_root(root, fn -> run(["--check"]) end) end

    refute File.exists?(support_path)
    assert error.message =~ "guides/support_matrix.md"
    assert count(error.message, @remediation) == 1
  end

  test "unknown, repeated, and combined options fail closed without echoing arguments", %{root: root} do
    for args <- [["--unknown-secret"], ["--check", "--check"], ["--check", "extra-secret"]] do
      error = assert_raise Mix.Error, fn -> in_root(root, fn -> run(args) end) end

      assert error.message ==
               "invalid arguments for crosswake.docs.sync; expected exactly `mix crosswake.docs.sync` or `mix crosswake.docs.sync --check`"

      refute error.message =~ "unknown-secret"
      refute error.message =~ "extra-secret"
    end
  end

  defp write_canonical_guides(root) do
    File.write!(Path.join(root, "guides/capability_map.md"), CapabilityRenderer.render())

    File.write!(
      Path.join(root, "guides/support_matrix.md"),
      SupportRenderer.render(SupportMatrix.canonical())
    )
  end

  defp guide_paths(root) do
    [
      Path.join(root, "guides/capability_map.md"),
      Path.join(root, "guides/support_matrix.md")
    ]
  end

  defp in_root(root, fun), do: File.cd!(root, fun)

  defp bytes(paths), do: Map.new(paths, &{&1, File.read!(&1)})

  defp metadata(paths) do
    Map.new(paths, fn path ->
      stat = File.stat!(path, time: :nanosecond)
      {path, Map.take(stat, [:size, :mode, :mtime, :ctime, :inode])}
    end)
  end

  defp repository_snapshot do
    root = File.cwd!()
    git_dir = String.trim(System.cmd("git", ["rev-parse", "--git-dir"], cd: root) |> elem(0))
    index_path = Path.expand(git_dir, root) |> Path.join("index")

    %{
      index: File.read!(index_path),
      status: System.cmd("git", ["status", "--porcelain=v1", "-z"], cd: root) |> elem(0)
    }
  end

  defp shell_messages do
    Stream.repeatedly(fn ->
      receive do
        {:mix_shell, :info, [message]} -> {:ok, message}
      after
        0 -> :halt
      end
    end)
    |> Enum.take_while(&(&1 != :halt))
    |> Enum.map_join("\n", fn {:ok, message} -> message end)
  end

  defp count(haystack, needle), do: length(String.split(haystack, needle)) - 1
end
