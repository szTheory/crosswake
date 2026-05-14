defmodule Mix.Tasks.Crosswake.Gen.Shell do
  use Mix.Task

  alias Crosswake.Shell.Fixtures

  @shortdoc "Generates host-owned native shell baselines for Crosswake"

  @moduledoc """
  Generates reviewable iOS or Android shell baselines, bundled manifest-backed
  activation fixtures, and explicit ownership guidance without claiming runtime
  behavior Crosswake has not proven yet.
  """

  @switches [target: :string]
  @platforms ~w(ios android)

  @android_templates [
    {"settings.gradle", "android/settings.gradle.eex"},
    {"build.gradle", "android/build.gradle.eex"},
    {"gradle.properties", "android/gradle.properties.eex"},
    {"gradlew", "android/gradlew.eex"},
    {"gradlew.bat", "android/gradlew.bat.eex"},
    {"gradle/wrapper/gradle-wrapper.properties",
     "android/gradle/wrapper/gradle-wrapper.properties.eex"},
    {"app/build.gradle", "android/app/build.gradle.eex"},
    {"app/src/main/AndroidManifest.xml", "android/app/src/main/AndroidManifest.xml.eex"}
  ]

  @impl Mix.Task
  def run(args) do
    {opts, argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("invalid options: #{inspect(invalid)}")
    end

    platform =
      case argv do
        [platform] when platform in @platforms -> platform
        _other -> Mix.raise("usage: mix crosswake.gen.shell ios|android [--target PATH]")
      end

    target = Path.expand(opts[:target] || File.cwd!())

    generated =
      case platform do
        "ios" -> generate_ios_shell(target)
        "android" -> generate_android_shell(target)
      end

    Mix.shell().info("""
    Crosswake #{platform} shell scaffold complete
      generated root: #{generated.root}
      ownership docs: #{generated.readme}
      manifest fixture: #{generated.manifest}
      activation fixture: #{generated.activation}
      denial fixture: #{generated.denial}
      baseline entrypoint: #{generated.entrypoint}
      ownership: host-owned, scaffold once, and not safely regeneratable over host edits
    """)
  end

  defp generate_ios_shell(target) do
    root = Path.join(target, "native/ios/crosswake_shell")
    fixtures = Fixtures.export("ios")

    readme = Path.join(root, "README.md")
    project = Path.join(root, "CrosswakeShell.xcodeproj/project.pbxproj")
    entrypoint = Path.join(root, "CrosswakeShell/AppShell.swift")

    ensure_file(readme, shell_readme("ios"))
    ensure_file(project, ios_project())
    ensure_file(Path.join(root, "CrosswakeShell/Info.plist"), ios_info_plist())
    ensure_file(entrypoint, ios_app_shell())
    ensure_file(Path.join(root, "CrosswakeShell/Assets.xcassets/Contents.json"), asset_catalog())
    write_fixture_files(root, fixtures)

    %{
      root: root,
      readme: readme,
      manifest: Path.join(root, "Fixtures/crosswake_manifest.json"),
      activation: Path.join(root, "Fixtures/route_activation.json"),
      denial: Path.join(root, "Fixtures/route_denial.json"),
      entrypoint: entrypoint
    }
  end

  defp generate_android_shell(target) do
    root = Path.join(target, "native/android/crosswake_shell")
    fixtures = Fixtures.export("android")

    ensure_file(Path.join(root, "README.md"), shell_readme("android"))
    render_android_templates(root)

    entrypoint = Path.join(root, "app/src/main/java/dev/crosswake/shell/MainActivity.kt")
    ensure_file(entrypoint, android_main_activity())
    write_fixture_files(Path.join(root, "app/src/main"), fixtures)

    ensure_executable(Path.join(root, "gradlew"))

    %{
      root: root,
      readme: Path.join(root, "README.md"),
      manifest: Path.join(root, "app/src/main/assets/crosswake_manifest.json"),
      activation: Path.join(root, "app/src/main/assets/route_activation.json"),
      denial: Path.join(root, "app/src/main/assets/route_denial.json"),
      entrypoint: entrypoint
    }
  end

  defp render_android_templates(root) do
    Enum.each(@android_templates, fn {relative_path, template_path} ->
      ensure_file(Path.join(root, relative_path), render_template(template_path))
    end)
  end

  defp render_template(template_path) do
    template =
      Application.app_dir(:crosswake, Path.join("priv/templates/crosswake/shell", template_path))

    EEx.eval_file(template, assigns: [])
  end

  defp write_fixture_files(root, fixtures) do
    Enum.each(fixtures, fn {relative_path, contents} ->
      ensure_file(Path.join(root, relative_path), contents)
    end)
  end

  defp shell_readme(platform) do
    """
    # Crosswake #{String.upcase(platform)} Shell Baseline

    This generated project is `host-owned`. Crosswake uses a scaffold once posture so your
    team can review, ship, and patch the native shell as an application artifact.
    Do not treat this directory as library-owned or safely regeneratable over host
    edits.

    ## Included Baseline

    - Real #{platform_readme_label(platform)} project files that match the class of artifact adopters ship
    - Bundled canonical manifest, activation, denial, and pack inventory fixtures
    - Thin native seams for app boot, manifest loading, and route-unavailable handling

    ## Boundary

    - The generated shell is intentionally thin and manifest-first.
    - Crosswake does not claim offline journals, pack managers, or broad plugin registries here.
    - Upgrade this shell with patch-or-doc guidance after generation instead of expecting safe re-ownership.
    """
  end

  defp platform_readme_label("ios"), do: "Xcode"
  defp platform_readme_label("android"), do: "Android Studio"

  defp ios_project do
    """
    // !$*UTF8*$!
    {
      archiveVersion = 1;
      classes = {};
      objectVersion = 56;
      objects = {};
      rootObject = CrosswakeShellProject;
      targets = (CrosswakeShell);
    }
    """
  end

  defp ios_info_plist do
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleDisplayName</key>
      <string>CrosswakeShell</string>
      <key>CFBundleIdentifier</key>
      <string>dev.crosswake.shell</string>
    </dict>
    </plist>
    """
  end

  defp ios_app_shell do
    """
    import Foundation

    struct AppShell {
      let activationFixture = "Fixtures/route_activation.json"
      let manifestFixture = "Fixtures/crosswake_manifest.json"

      func loadBundledManifestFixture() -> String {
        manifestFixture
      }

      func loadActivationFixture() -> String {
        activationFixture
      }

      func routeUnavailableSurface() -> String {
        "Render the manifest-first denial surface before mounting any runtime."
      }
    }
    """
  end

  defp asset_catalog do
    """
    {
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }
    """
  end

  defp android_main_activity do
    """
    package dev.crosswake.shell

    import android.app.Activity
    import android.os.Bundle

    class MainActivity : Activity() {
        override fun onCreate(savedInstanceState: Bundle?) {
            super.onCreate(savedInstanceState)
        }

        fun loadBundledManifestFixture(): String = "assets/crosswake_manifest.json"

        fun routeUnavailableSurface(): String =
            "Render the manifest-first denial surface before mounting any runtime."
    }
    """
  end

  defp ensure_file(path, contents) do
    File.mkdir_p!(Path.dirname(path))

    case File.read(path) do
      {:ok, _existing} ->
        :reused

      {:error, :enoent} ->
        File.write!(path, contents)
        :created

      {:error, reason} ->
        Mix.raise("could not create #{path}: #{:file.format_error(reason)}")
    end
  end

  defp ensure_executable(path) do
    case File.stat(path) do
      {:ok, %File.Stat{mode: mode}} ->
        File.chmod!(path, Bitwise.bor(mode, 0o111))

      {:error, reason} ->
        Mix.raise("could not update permissions for #{path}: #{:file.format_error(reason)}")
    end
  end
end
