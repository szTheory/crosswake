defmodule Crosswake.Shell.IOSHostMigrationSecurityTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  @task "crosswake.gen.shell"

  test "migration diff and apply reject target ancestors that are symlinks without changing the outside project" do
    with_generated_shell(fn root ->
      project = project_file(root)
      original = File.read!(project)
      legacy = legacy_bundle_ids(original)
      File.write!(project, legacy)

      base = temp_root("shell-migration-ancestor")
      File.mkdir_p!(base)
      link = Path.join(base, "target-link")
      File.ln_s!(root, link)

      outcomes =
        Enum.map(["--diff", "--migrate-project-settings"], fn action ->
          run_task(link, action)
        end)

      assert length(outcomes) == 2
      assert Enum.all?(outcomes, &migration_failure?(&1, "unsafe_path"))
      assert File.read!(project) == legacy
      File.rm_rf!(base)
    end)
  end

  test "migration diff and apply reject a symlinked Xcode project directory" do
    with_generated_shell(fn root ->
      project_dir = Path.join(root, "native/ios/crosswake_shell/CrosswakeShell.xcodeproj")
      outside = temp_root("shell-migration-project-dir")
      File.mkdir_p!(outside)
      external_project = Path.join(outside, "CrosswakeShell.xcodeproj")
      File.cp_r!(project_dir, external_project)
      File.rm_rf!(project_dir)
      File.ln_s!(external_project, project_dir)
      project = Path.join(external_project, "project.pbxproj")
      before = File.read!(project)

      outcomes =
        Enum.map(["--diff", "--migrate-project-settings"], fn action ->
          run_task(root, action)
        end)

      assert length(outcomes) == 2
      assert Enum.all?(outcomes, &migration_failure?(&1, "unsafe_path"))
      assert File.read!(project) == before
      File.rm_rf!(outside)
    end)
  end

  test "migration diff and apply reject a symlinked PBX project file" do
    with_generated_shell(fn root ->
      project = project_file(root)
      outside = temp_root("shell-migration-project-file")
      File.mkdir_p!(Path.dirname(outside))
      File.cp!(project, outside)
      File.rm!(project)
      File.ln_s!(outside, project)
      legacy = legacy_bundle_ids(File.read!(outside))
      File.write!(outside, legacy)

      outcomes =
        Enum.map(["--diff", "--migrate-project-settings"], fn action ->
          run_task(root, action)
        end)

      assert length(outcomes) == 2
      assert Enum.all?(outcomes, &migration_failure?(&1, "unsafe_path"))
      assert File.read!(outside) == legacy
      File.rm!(outside)
    end)
  end

  test "project migration refuses to cross a pending managed-output boundary" do
    with_generated_shell(fn root ->
      project = project_file(root)
      original = File.read!(project)
      legacy = legacy_bundle_ids(original)
      File.write!(project, legacy)

      pending =
        Path.join(Path.dirname(project), "../.crosswake/ios_host_generation.pending")
        |> Path.expand()

      File.write!(pending, "pending\n")

      outcomes =
        Enum.map(["--diff", "--migrate-project-settings"], fn action ->
          run_task(root, action)
        end)

      assert length(outcomes) == 2
      assert Enum.all?(outcomes, &migration_failure?(&1, "interrupted"))
      assert File.read!(project) == legacy
    end)
  end

  test "legacy shell migration restores declared app and test bundle IDs in both configurations" do
    with_generated_shell(fn root ->
      declaration = host_declaration()
      project = project_file(root)

      legacy =
        File.read!(project)
        |> String.replace("$(CROSSWAKE_APP_BUNDLE_ID)", "org.crosswake.legacy.app")
        |> String.replace("$(CROSSWAKE_SHELL_TEST_BUNDLE_ID)", "org.crosswake.legacy.tests")

      File.write!(project, legacy)
      assert :ok = run_task(root, "--migrate-project-settings")
      assert_xcode_bundle_ids(project, declaration)
    end)
  end

  test "current shell migration is idempotent and preserves declared app/test IDs in Xcode" do
    with_generated_shell(fn root ->
      declaration = host_declaration()
      project = project_file(root)
      assert :ok = run_task(root, "--migrate-project-settings")
      migrated = File.read!(project)
      assert :ok = run_task(root, "--migrate-project-settings")
      assert File.read!(project) == migrated
      assert_xcode_bundle_ids(project, declaration)
    end)
  end

  defp with_generated_shell(fun) do
    previous = Application.get_env(:crosswake, :ios_host)
    root = temp_root("shell-migration-generated")

    Application.put_env(:crosswake, :ios_host, host_declaration())

    try do
      Mix.Task.reenable(@task)
      capture_io(fn -> Mix.Task.run(@task, ["ios", "--target", root]) end)
      fun.(root)
    after
      if is_nil(previous),
        do: Application.delete_env(:crosswake, :ios_host),
        else: Application.put_env(:crosswake, :ios_host, previous)

      File.rm_rf!(root)
    end
  end

  defp host_declaration do
    %{
      router: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
      origin: "https://migration-host.test",
      entry_route_id: "study-session",
      app_bundle_id: "org.crosswake.migration.host",
      proof_app_bundle_id: "org.crosswake.migration.proof",
      device_signing: [mode: :manual, team_id: "ABCDE12345"]
    }
  end

  defp run_task(target, action) do
    try do
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["ios", "--target", target, action])
      end)

      :ok
    rescue
      error in Mix.Error -> {:error, error.message}
    end
  end

  defp migration_failure?({:error, message}, cause),
    do:
      String.contains?(message, "project migration blocked") and
        String.contains?(message, "cause: #{cause}")

  defp migration_failure?(_, _), do: false

  defp legacy_bundle_ids(contents) do
    contents
    |> String.replace("$(CROSSWAKE_APP_BUNDLE_ID)", "org.crosswake.legacy.app")
    |> String.replace("$(CROSSWAKE_SHELL_TEST_BUNDLE_ID)", "org.crosswake.legacy.tests")
  end

  defp project_file(root),
    do: Path.join(root, "native/ios/crosswake_shell/CrosswakeShell.xcodeproj/project.pbxproj")

  defp temp_root(prefix) do
    path = Path.join(System.tmp_dir!(), "#{prefix}-#{System.unique_integer([:positive])}")
    File.rm_rf!(path)
    path
  end

  defp assert_xcode_bundle_ids(project, declaration) do
    for configuration <- ["Debug", "Release"] do
      assert xcode_target_settings(project, "CrosswakeShell", configuration)[
               "PRODUCT_BUNDLE_IDENTIFIER"
             ] == declaration.app_bundle_id

      assert xcode_target_settings(project, "CrosswakeShellTests", configuration)[
               "PRODUCT_BUNDLE_IDENTIFIER"
             ] == declaration.app_bundle_id <> ".tests"
    end
  end

  defp xcode_target_settings(project, target, configuration) do
    {output, status} =
      System.cmd(
        "/bin/sh",
        [
          "-c",
          "exec xcodebuild \"$@\" 2>/dev/null",
          "crosswake-xcode",
          "-project",
          Path.dirname(project),
          "-target",
          target,
          "-configuration",
          configuration,
          "-sdk",
          "iphonesimulator",
          "-showBuildSettings",
          "-json"
        ],
        stderr_to_stdout: false
      )

    assert status == 0
    [row] = Jason.decode!(output)
    row["buildSettings"]
  end
end
