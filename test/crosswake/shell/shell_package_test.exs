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
             package_with(
               "public enum HostCommandSeam {\n    public static let version = \"one\"\n}\n"
             )
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

    resolved =
      Path.join(root, "CrosswakeShell.xcodeproj/project.xcworkspace/xcshareddata/swiftpm")

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

  describe "display_location/2" do
    test "a location inside the project prints the project-relative path" do
      root = tmp_dir()
      assert ShellPackage.display_location(Path.join(root, "a/b"), root) == "a/b"
    end

    test "the project root itself prints a dot" do
      root = tmp_dir()
      assert ShellPackage.display_location(root, root) == "."
    end

    test "a location under the home directory and outside the project prints the home placeholder" do
      root = tmp_dir()
      location = Path.join(System.user_home!(), "crosswake-186-nowhere/shell-pkg")
      shown = ShellPackage.display_location(location, root)
      assert shown == "<home>/crosswake-186-nowhere/shell-pkg"
      refute shown =~ System.user_home!()
    end

    test "a location outside the project and the home directory prints the outside placeholder" do
      root = tmp_dir()

      assert ShellPackage.display_location("/crosswake-186-nowhere/pkg", root) ==
               "<outside project>"
    end

    test "a remote reference is returned unchanged" do
      assert ShellPackage.display_location("remote crosswake-shell-core-ios", tmp_dir()) ==
               "remote crosswake-shell-core-ios"
    end

    test "a non-absolute input is never echoed" do
      root = tmp_dir()
      assert ShellPackage.display_location("relative/pkg", root) == "<outside project>"
      assert ShellPackage.display_location("", root) == "<outside project>"
    end

    test "a project reached through a symlink still prints the in-project location relative" do
      base = tmp_dir()
      real = Path.join(base, "real")
      link = Path.join(base, "link")
      File.mkdir_p!(Path.join(real, "pkg"))
      File.ln_s!(real, link)

      assert ShellPackage.display_location(Path.join(real, "pkg"), link) == "pkg"
      assert ShellPackage.display_location(Path.join(link, "pkg"), real) == "pkg"
    end

    test "a sibling directory sharing the project name prefix is outside the project" do
      base = tmp_dir()
      proj = Path.join(base, "proj")
      File.mkdir_p!(proj)
      File.mkdir_p!(Path.join(base, "proj-evil/pkg"))

      shown = ShellPackage.display_location(Path.join(base, "proj-evil/pkg"), proj)
      refute shown in ["../proj-evil/pkg", "proj-evil/pkg"]
      assert shown == "<outside project>" or String.starts_with?(shown, "<home>/")
    end
  end
end
