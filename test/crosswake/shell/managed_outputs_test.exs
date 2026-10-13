defmodule Crosswake.Shell.ManagedOutputsTest do
  use ExUnit.Case, async: false

  alias Crosswake.Shell.ManagedOutputs

  test "inspection of an absent host reports missing without creating anything" do
    root = temp_root("managed-missing")
    desired = desired_outputs()

    assert {:error, %{cause: :missing, repair: repair}} = ManagedOutputs.check(root, desired)
    assert repair =~ "mix crosswake.gen.shell ios"
    refute File.exists?(root)
  end

  test "recognized output becomes stale when declaration changes and check remains read-only" do
    root = temp_root("managed-stale")
    first = desired_outputs()
    second = Map.put(first, "CrosswakeHostSettings.xcconfig", "private-canary
")

    assert :ok = ManagedOutputs.publish(root, first)
    before = snapshot(root)

    assert {:error, %{cause: :stale}} = ManagedOutputs.check(root, second)
    assert snapshot(root) == before
  end

  test "externally edited managed output is a conflict and private bytes stay out of diagnostics" do
    root = temp_root("managed-conflict")
    desired = desired_outputs()

    assert :ok = ManagedOutputs.publish(root, desired)
    path = Path.join(root, "Fixtures/crosswake_manifest.json")
    File.write!(path, "secret-origin-canary")

    assert {:error, %{cause: :conflict, repair: repair}} = ManagedOutputs.check(root, desired)
    refute inspect(repair) =~ "secret-origin-canary"
  end

  test "unsafe symlink destinations are denied before publication" do
    root = temp_root("managed-symlink")
    File.mkdir_p!(root)
    outside = temp_root("managed-outside")
    File.mkdir_p!(outside)
    File.ln_s!(outside, Path.join(root, "Fixtures"))

    assert {:error, %{cause: :unsafe_path}} = ManagedOutputs.publish(root, desired_outputs())
    assert File.ls!(outside) == []
  end

  defp desired_outputs do
    %{
      "Fixtures/crosswake_manifest.json" => "manifest-safe
",
      "Fixtures/route_activation.json" => "activation-safe
",
      "CrosswakeHostSettings.xcconfig" => "settings-safe
"
    }
  end

  defp snapshot(root) do
    root
    |> Path.join("**/*")
    |> Path.wildcard(match_dot: true)
    |> Enum.sort()
    |> Enum.map(fn path ->
      case File.lstat(path) do
        {:ok, %{type: :directory}} -> {Path.relative_to(path, root), :directory}
        {:ok, %{type: :regular}} -> {Path.relative_to(path, root), File.read!(path)}
        other -> {Path.relative_to(path, root), other}
      end
    end)
  end

  defp temp_root(prefix) do
    path = Path.join(System.tmp_dir!(), "#{prefix}-#{System.unique_integer([:positive])}")
    File.rm_rf!(path)
    path
  end
end
