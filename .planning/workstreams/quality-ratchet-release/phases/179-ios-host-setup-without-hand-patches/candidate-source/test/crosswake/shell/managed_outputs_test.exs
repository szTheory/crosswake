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

  test "interrupted publication remains blocked until recovery restores one prior generation" do
    root = temp_root("managed-recovery")
    prior = desired_outputs()
    desired = Map.put(prior, "Fixtures/crosswake_manifest.json", "new manifest\n")

    assert :ok = ManagedOutputs.publish(root, prior)

    assert {:error, %{cause: :interrupted}} =
             ManagedOutputs.publish(root, desired, interrupt_after_first: true)

    interrupted_snapshot = snapshot(root)
    assert {:error, %{cause: :interrupted, repair: repair}} = ManagedOutputs.check(root, prior)
    assert repair =~ "--recover"
    assert snapshot(root) == interrupted_snapshot

    assert {:ok, %{status: :recovered}} = ManagedOutputs.recover(root)
    assert {:ok, %{status: :current}} = ManagedOutputs.check(root, prior)
    refute File.exists?(Path.join(root, ".crosswake/ios_host_generation.pending"))
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

  test "ancestor symlinks outside the requested managed root are denied before publication" do
    base = temp_root("managed-ancestor")
    outside = temp_root("managed-ancestor-outside")
    File.mkdir_p!(outside)
    File.mkdir_p!(base)
    File.ln_s!(outside, Path.join(base, "parent-link"))
    root = Path.join(base, "parent-link/host")

    assert {:error, %{cause: :unsafe_path}} = ManagedOutputs.publish(root, desired_outputs())
    assert File.ls!(outside) == []
  end

  test "bounded PBX migration preview removes only known identity overrides" do
    pbx = project_fixture() <> "\n// unrelated host comment\n"

    assert {:ok, %{status: :migration_required, contents: migrated}} =
             Crosswake.Shell.IOSHostProjectMigration.preview_contents(pbx)

    assert String.ends_with?(migrated, "// unrelated host comment\n")

    assert length(
             Regex.scan(
               ~r/PRODUCT_BUNDLE_IDENTIFIER\s*=\s*"\$\(CROSSWAKE_APP_BUNDLE_ID\)";/,
               migrated
             )
           ) == 2

    assert length(
             Regex.scan(
               ~r/PRODUCT_BUNDLE_IDENTIFIER\s*=\s*"\$\(CROSSWAKE_SHELL_TEST_BUNDLE_ID\)";/,
               migrated
             )
           ) == 2

    refute migrated =~ "CODE_SIGNING_ALLOWED = NO;"
    assert migrated =~ "baseConfigurationReference = A10000400000000000000001"
  end

  test "bounded PBX migration refuses unfamiliar configuration identities" do
    pbx = String.replace(project_fixture(), "name = Debug;", "name = Preview;", global: false)

    assert {:error, %{cause: :unrecognized_project, repair: repair}} =
             Crosswake.Shell.IOSHostProjectMigration.preview_contents(pbx)

    assert repair =~ "restore the recognized shell project structure"
  end

  defp project_fixture do
    EEx.eval_file(
      "priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex",
      assigns: [local: true, local_ios_core_path: "/tmp/unused-local-core", version: "1.0.0"]
    )
    |> String.replace("$(CROSSWAKE_APP_BUNDLE_ID)", "dev.crosswake.legacy.app")
    |> String.replace("$(CROSSWAKE_SHELL_TEST_BUNDLE_ID)", "dev.crosswake.legacy.tests")
    |> String.replace("SWIFT_VERSION = 5.0;", "CODE_SIGNING_ALLOWED = NO; SWIFT_VERSION = 5.0;")
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
