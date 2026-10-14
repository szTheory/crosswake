defmodule Crosswake.Doctor.HostCommandsTest do
  use ExUnit.Case, async: false

  alias Crosswake.Doctor
  alias Crosswake.TestSupport.HostCommandFixtures.DeclaringRouter
  alias Crosswake.TestSupport.RouterFixtures.ManagedRouter

  @allowed_detail_keys [
    :route_id,
    :commands,
    :platform,
    :package_location,
    :found_version,
    :required_version
  ]
  @swift_rel "Sources/CrosswakeShellCore/ActivationCoordinator.swift"

  setup do
    dir =
      Path.join(System.tmp_dir!(), "doctor-host-commands-#{System.unique_integer([:positive])}")

    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)
    %{dir: dir}
  end

  defp managed_root(dir, router, pbx, mutate \\ & &1) do
    root = Path.join(dir, "native/ios/crosswake_shell")
    File.mkdir_p!(Path.join(root, "Fixtures"))
    File.mkdir_p!(Path.join(root, "CrosswakeShell.xcodeproj"))

    {:ok, %{manifest: manifest}} =
      Crosswake.Manifest.compile(router, origin: "https://study.crosswake.test")

    generated = manifest |> Crosswake.Manifest.render() |> Jason.decode!() |> mutate.()
    File.write!(Path.join(root, "Fixtures/crosswake_manifest.json"), Jason.encode!(generated))
    if pbx, do: File.write!(Path.join(root, "CrosswakeShell.xcodeproj/project.pbxproj"), pbx)
    root
  end

  defp local_package(dir, version) do
    pkg = Path.join(dir, "shell-pkg")
    File.mkdir_p!(Path.join(pkg, Path.dirname(@swift_rel)))

    body =
      if version,
        do: "public enum HostCommandSeam {\n    public static let version = \"#{version}\"\n}\n",
        else: "struct Other {}\n"

    File.write!(Path.join(pkg, @swift_rel), body)
    pkg
  end

  defp findings(dir, router, root) do
    report =
      Doctor.run(
        route_source: router,
        install_manifest_path: Path.join(dir, "missing_install.json"),
        cwd: dir,
        ios_shell_root: root
      )

    Enum.filter(report.findings, &(&1.check == "host_commands"))
  end

  defp codes(found), do: found |> Enum.map(& &1.code) |> Enum.sort()

  test "a stale generated route is one error finding naming route and commands", %{dir: dir} do
    pbx = "relativePath = \"../../../shell-pkg\";\n"
    local_package(dir, "1.0.0")

    root =
      managed_root(dir, DeclaringRouter, pbx, fn manifest ->
        update_in(manifest, ["routes", "lesson"], &Map.delete(&1, "host_commands"))
      end)

    found = findings(dir, DeclaringRouter, root)
    assert codes(found) == ["host_commands_stale"]
    [finding] = found
    assert finding.severity == :error

    assert finding.details == %{
             route_id: "lesson",
             commands: ["host.lesson.audio.play"],
             platform: :ios
           }

    assert finding.hint =~ "mix crosswake.gen.shell ios"
  end

  test "a matching generated manifest and a seam-carrying package produce no finding", %{dir: dir} do
    local_package(dir, "1.0.0")
    root = managed_root(dir, DeclaringRouter, "relativePath = \"../../../shell-pkg\";\n")
    assert codes(findings(dir, DeclaringRouter, root)) == []
  end

  test "an older shell package is reported as unsupported with the package name and fix", %{
    dir: dir
  } do
    local_package(dir, "0.9.0")
    root = managed_root(dir, DeclaringRouter, "relativePath = \"../../../shell-pkg\";\n")

    found = findings(dir, DeclaringRouter, root)
    assert codes(found) == ["host_command_shell_unsupported"]
    [finding] = found
    assert finding.hint =~ "crosswake-shell-core-ios"
    assert finding.details.found_version == "0.9.0"
    assert finding.details.required_version == "1.0.0"
  end

  test "an undeterminable shell package is unsupported, never silently accepted", %{dir: dir} do
    local_package(dir, nil)
    root = managed_root(dir, DeclaringRouter, "relativePath = \"../../../shell-pkg\";\n")
    assert codes(findings(dir, DeclaringRouter, root)) == ["host_command_shell_unsupported"]

    remote = managed_root(dir, DeclaringRouter, "minimumVersion = 0.2.11;\n")
    assert codes(findings(dir, DeclaringRouter, remote)) == ["host_command_shell_unsupported"]
  end

  test "a router with no declaring route gets no host-command finding", %{dir: dir} do
    root = managed_root(dir, ManagedRouter, "minimumVersion = 0.2.11;\n")
    assert codes(findings(dir, ManagedRouter, root)) == []
  end

  test "no managed iOS root means no finding", %{dir: dir} do
    assert codes(findings(dir, DeclaringRouter, Path.join(dir, "native/ios/not_generated"))) == []
  end

  test "finding details only carry the allowed keys", %{dir: dir} do
    local_package(dir, "0.9.0")

    root =
      managed_root(
        dir,
        DeclaringRouter,
        "relativePath = \"../../../shell-pkg\";\n",
        fn manifest ->
          update_in(manifest, ["routes", "lesson"], &Map.delete(&1, "host_commands"))
        end
      )

    found = findings(dir, DeclaringRouter, root)
    assert codes(found) == ["host_command_shell_unsupported", "host_commands_stale"]

    assert Enum.all?(found, fn finding ->
             Map.keys(finding.details) -- @allowed_detail_keys == []
           end)
  end
end
