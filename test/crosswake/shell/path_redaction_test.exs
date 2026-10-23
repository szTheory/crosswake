defmodule Crosswake.Shell.PathRedactionTest do
  use ExUnit.Case, async: false

  alias Crosswake.Doctor
  alias Crosswake.Shell.IOSHostConfig
  alias Crosswake.Shell.IOSHostGeneration
  alias Crosswake.TestSupport.HostCommandFixtures.DeclaringRouter

  @swift_rel "Sources/CrosswakeShellCore/ActivationCoordinator.swift"

  setup do
    sentinel = "SENTINEL-186-#{System.unique_integer([:positive])}"
    project = Path.join(System.tmp_dir!(), sentinel)
    File.mkdir_p!(project)
    previous_env = Application.get_env(:crosswake, :ios_host)
    cwd = File.cwd!()

    on_exit(fn ->
      File.cd!(cwd)
      File.rm_rf!(project)

      if previous_env,
        do: Application.put_env(:crosswake, :ios_host, previous_env),
        else: Application.delete_env(:crosswake, :ios_host)

      Mix.Task.reenable("crosswake.gen.shell")
    end)

    %{sentinel: sentinel, project: project}
  end

  defp seam_package(dir, version) do
    File.mkdir_p!(Path.join(dir, Path.dirname(@swift_rel)))

    File.write!(
      Path.join(dir, @swift_rel),
      "public enum HostCommandSeam {\n    public static let version = \"#{version}\"\n}\n"
    )

    dir
  end

  defp managed_root(project, relative_package) do
    root = Path.join(project, "native/ios/crosswake_shell")
    File.mkdir_p!(Path.join(root, "Fixtures"))
    File.mkdir_p!(Path.join(root, "CrosswakeShell.xcodeproj"))

    {:ok, %{manifest: manifest}} =
      Crosswake.Manifest.compile(DeclaringRouter, origin: "https://study.crosswake.test")

    File.write!(
      Path.join(root, "Fixtures/crosswake_manifest.json"),
      manifest |> Crosswake.Manifest.render()
    )

    File.write!(
      Path.join(root, "CrosswakeShell.xcodeproj/project.pbxproj"),
      "relativePath = \"#{relative_package}\";\n"
    )

    root
  end

  defp host_command_findings(project, root) do
    report =
      Doctor.run(
        route_source: DeclaringRouter,
        install_manifest_path: Path.join(project, "missing_install.json"),
        cwd: project,
        ios_shell_root: root
      )

    Enum.filter(report.findings, &(&1.check == "host_commands"))
  end

  defp scanned(findings) do
    findings
    |> Enum.map(fn finding ->
      inspect({finding.message, finding.hint, finding.details}, limit: :infinity)
    end)
    |> Enum.join("\n")
  end

  defp refute_leaks(text, sentinel) do
    refute text =~ sentinel
    refute text =~ System.user_home!()
  end

  defp config do
    %IOSHostConfig{
      router: DeclaringRouter,
      origin: "https://study.crosswake.test",
      entry_route_id: "lesson",
      app_bundle_id: "org.crosswake.host",
      proof_app_bundle_id: "org.crosswake.host.proof",
      device_signing: %{mode: :automatic, team_id: "ABCDE12345"}
    }
  end

  test "doctor names an in-project shell package relatively and leaks neither the sentinel nor the home path",
       %{sentinel: sentinel, project: project} do
    seam_package(Path.join(project, "shell-pkg"), "0.9.0")
    root = managed_root(project, "../../../shell-pkg")

    found = host_command_findings(project, root)
    assert [finding] = Enum.filter(found, &(&1.code == "host_command_shell_unsupported"))
    assert finding.message =~ "at shell-pkg cannot honor it"
    assert finding.details.package_location == "shell-pkg"
    refute_leaks(scanned(found), sentinel)
  end

  test "doctor names an outside shell package without its path and leaks neither the sentinel nor the home path",
       %{sentinel: sentinel, project: project} do
    outside =
      Path.join(System.tmp_dir!(), "outside-pkg-186-#{System.unique_integer([:positive])}")

    on_exit(fn -> File.rm_rf!(outside) end)
    seam_package(outside, "0.9.0")
    root = managed_root(project, outside)

    found = host_command_findings(project, root)
    assert [finding] = Enum.filter(found, &(&1.code == "host_command_shell_unsupported"))
    location = finding.details.package_location
    assert location == "<outside project>" or String.starts_with?(location, "<home>/")
    assert finding.message =~ "at #{location} cannot honor it"
    refute_leaks(scanned(found), sentinel)
    refute scanned(found) =~ outside
  end

  test "the generation gate error names the package relatively and leaks neither the sentinel nor the home path",
       %{sentinel: sentinel, project: project} do
    package = seam_package(Path.join(project, "packages/crosswake-shell-core-ios"), "0.9.0")

    assert {:error, message} =
             IOSHostGeneration.render(config(),
               shell_package: {:local, package},
               project_root: project
             )

    assert message =~ "at packages/crosswake-shell-core-ios cannot honor it"
    refute_leaks(message, sentinel)
  end

  test "the raised gen.shell gate text names the package relatively and leaks neither the sentinel nor the home path",
       %{sentinel: sentinel, project: project} do
    seam_package(Path.join(project, "packages/crosswake-shell-core-ios"), "0.9.0")

    Application.put_env(:crosswake, :ios_host,
      router: DeclaringRouter,
      origin: "https://study.crosswake.test",
      entry_route_id: "lesson",
      app_bundle_id: "org.crosswake.host",
      proof_app_bundle_id: "org.crosswake.host.proof",
      device_signing: [mode: :automatic, team_id: "ABCDE12345"]
    )

    File.cd!(project)

    error =
      assert_raise Mix.Error, fn ->
        ExUnit.CaptureIO.capture_io(fn ->
          Mix.Tasks.Crosswake.Gen.Shell.run(["ios", "--target", project])
        end)
      end

    assert error.message =~ "packages/crosswake-shell-core-ios"
    assert error.message =~ "at packages/crosswake-shell-core-ios cannot honor it"
    refute_leaks(error.message, sentinel)
  end
end
