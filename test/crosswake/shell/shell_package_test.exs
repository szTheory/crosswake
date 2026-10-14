defmodule Crosswake.Shell.ShellPackageTest do
  use ExUnit.Case, async: true

  alias Crosswake.Shell.ShellPackage

  @swift_rel "Sources/CrosswakeShellCore/ActivationCoordinator.swift"

  defp tmp_dir do
    dir = Path.join(System.tmp_dir!(), "shell-package-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)
    dir
  end

  defp package_with(source) do
    dir = tmp_dir()
    File.mkdir_p!(Path.join(dir, Path.dirname(@swift_rel)))
    File.write!(Path.join(dir, @swift_rel), source)
    dir
  end

  defp project(managed_pbx) do
    root = tmp_dir()
    proj = Path.join(root, "CrosswakeShell.xcodeproj")
    File.mkdir_p!(proj)
    File.write!(Path.join(proj, "project.pbxproj"), managed_pbx)
    root
  end

  test "seam_version_at reads the constant inside the HostCommandSeam enum" do
    dir =
      package_with(
        "public enum Other { public static let version = \"9.9.9\" }\n" <>
          "public enum HostCommandSeam {\n    public static let version = \"1.2.3\"\n}\n"
      )

    assert ShellPackage.seam_version_at(dir) == "1.2.3"
  end

  test "seam_version_at is nil without the enum, with a malformed version or without the file" do
    assert ShellPackage.seam_version_at(package_with("struct A {}\n")) == nil

    assert ShellPackage.seam_version_at(
             package_with("public enum HostCommandSeam {\n    public static let version = \"one\"\n}\n")
           ) == nil

    assert ShellPackage.seam_version_at(tmp_dir()) == nil
  end

  test "first_seam_release is nil because no release carries the seam" do
    assert ShellPackage.first_seam_release() == nil
  end

  test "resolve project with a local relativePath resolves against the managed root" do
    root = tmp_dir()
    pkg = Path.join(root, "pkg")
    File.mkdir_p!(Path.join(pkg, Path.dirname(@swift_rel)))

    File.write!(
      Path.join(pkg, @swift_rel),
      "public enum HostCommandSeam {\n    public static let version = \"1.0.0\"\n}\n"
    )

    managed = Path.join(root, "managed")
    File.mkdir_p!(Path.join(managed, "CrosswakeShell.xcodeproj"))

    File.write!(
      Path.join(managed, "CrosswakeShell.xcodeproj/project.pbxproj"),
      "isa = XCLocalSwiftPackageReference;\n relativePath = \"../pkg\";\n"
    )

    assert {:ok, %{kind: :local, seam_version: "1.0.0"}} =
             ShellPackage.resolve({:project, managed})
  end

  test "resolve project with a remote minimumVersion has no seam" do
    root = project("kind = upToNextMajorVersion;\n minimumVersion = 0.2.11;\n")

    assert {:ok, %{kind: :remote, version: "0.2.11", seam_version: nil}} =
             ShellPackage.resolve({:project, root})
  end

  test "resolve project prefers the Package.resolved pin" do
    root = project("minimumVersion = 0.2.11;\n")
    resolved = Path.join(root, "CrosswakeShell.xcodeproj/project.xcworkspace/xcshareddata/swiftpm")
    File.mkdir_p!(resolved)

    File.write!(
      Path.join(resolved, "Package.resolved"),
      Jason.encode!(%{
        "pins" => [
          %{
            "location" => "https://github.com/szTheory/crosswake-shell-core-ios.git",
            "state" => %{"version" => "0.2.14"}
          }
        ]
      })
    )

    assert {:ok, %{kind: :remote, version: "0.2.14"}} = ShellPackage.resolve({:project, root})
  end

  test "resolve project without a project file is an error" do
    assert ShellPackage.resolve({:project, tmp_dir()}) == {:error, :no_project}
  end

  test "satisfies? compares against the required seam version" do
    assert ShellPackage.satisfies?(%{kind: :local, seam_version: "1.0.0"}, "1.0.0") == :ok
    assert ShellPackage.satisfies?(%{kind: :local, seam_version: "1.1.0"}, "1.0.0") == :ok
    assert {:error, _} = ShellPackage.satisfies?(%{kind: :local, seam_version: "0.9.0"}, "1.0.0")
    assert {:error, _} = ShellPackage.satisfies?(%{kind: :local, seam_version: nil}, "1.0.0")
  end
end
