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

      assert Enum.all?(outcomes, &migration_failure?(&1, "interrupted"))
      assert File.read!(project) == legacy
    end)
  end

  defp with_generated_shell(fun) do
    previous = Application.get_env(:crosswake, :ios_host)
    root = temp_root("shell-migration-generated")

    Application.put_env(:crosswake, :ios_host, %{
      router: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
      origin: "https://migration-host.test",
      entry_route_id: "study-session",
      app_bundle_id: "org.crosswake.migration.host",
      proof_app_bundle_id: "org.crosswake.migration.proof",
      device_signing: [mode: :manual, team_id: "ABCDE12345"]
    })

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
end
