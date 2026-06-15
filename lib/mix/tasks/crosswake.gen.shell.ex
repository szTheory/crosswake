defmodule Mix.Tasks.Crosswake.Gen.Shell do
  use Mix.Task

  alias Crosswake.Shell.Fixtures

  @shortdoc "Generates host-owned native shell baselines for Crosswake"

  @moduledoc """
  Generates reviewable iOS or Android shell baselines, bundled manifest-backed
  activation fixtures, and explicit ownership guidance without claiming runtime
  behavior Crosswake has not proven yet.
  """

  @switches [target: :string, router: :string, local: :boolean]
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
    {"app/src/main/AndroidManifest.xml", "android/app/src/main/AndroidManifest.xml.eex"},
    {"app/src/main/java/dev/crosswake/shell/MainActivity.kt",
     "android/app/src/main/java/dev/crosswake/shell/MainActivity.kt.eex"},
    {"app/src/main/java/dev/crosswake/shell/CrosswakeViewModel.kt",
     "android/app/src/main/java/dev/crosswake/shell/CrosswakeViewModel.kt.eex"},
    {"app/src/main/res/values/themes.xml", "android/app/src/main/res/values/themes.xml.eex"}
  ]
  @ios_templates [
    {"CrosswakeShell/CrosswakeShellApp.swift", "ios/CrosswakeShellApp.swift.eex"},
    {"CrosswakeShell/Info.plist", "ios/Info.plist.eex"},
    {"CrosswakeShell/CrosswakeCoordinator.swift", "ios/CrosswakeCoordinator.swift.eex"},
    {"CrosswakeShell.xcodeproj/project.pbxproj",
     "ios/CrosswakeShell.xcodeproj/project.pbxproj.eex"},
    {"CrosswakeShell.xcodeproj/xcshareddata/xcschemes/CrosswakeShell.xcscheme",
     "ios/CrosswakeShell.xcodeproj/xcshareddata/xcschemes/CrosswakeShell.xcscheme.eex"},
    {"CrosswakeShell/CrosswakeShell.entitlements", "ios/CrosswakeShell.entitlements.eex"},
    {"CrosswakeShell/PrivacyInfo.xcprivacy", "ios/PrivacyInfo.xcprivacy.eex"}
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
    capabilities = fetch_capabilities(opts[:router])
    local = Keyword.get(opts, :local, false)

    generated =
      case platform do
        "ios" -> generate_ios_shell(target, capabilities, local)
        "android" -> generate_android_shell(target, capabilities, local)
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

  defp generate_ios_shell(target, capabilities, local) do
    root = Path.join(target, "native/ios/crosswake_shell")
    fixtures = Fixtures.export("ios")

    readme = Path.join(root, "README.md")
    entrypoint = Path.join(root, "CrosswakeShell/CrosswakeShellApp.swift")

    ensure_file(readme, shell_readme("ios"))
    render_ios_templates(root, capabilities, local)
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

  defp generate_android_shell(target, capabilities, local) do
    root = Path.join(target, "native/android/crosswake_shell")
    fixtures = Fixtures.export("android")

    ensure_file(Path.join(root, "README.md"), shell_readme("android"))
    render_android_templates(root, capabilities, local)

    entrypoint = Path.join(root, "app/src/main/java/dev/crosswake/shell/MainActivity.kt")
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

  defp render_android_templates(root, capabilities, local) do
    assigns = local_package_assigns(root)

    Enum.each(@android_templates, fn {relative_path, template_path} ->
      ensure_file(
        Path.join(root, relative_path),
        render_template(template_path, capabilities, local, assigns)
      )
    end)
  end

  defp render_ios_templates(root, capabilities, local) do
    assigns = local_package_assigns(root)

    Enum.each(@ios_templates, fn {relative_path, template_path} ->
      ensure_file(
        Path.join(root, relative_path),
        render_template(template_path, capabilities, local, assigns)
      )
    end)
  end

  defp render_template(template_path, capabilities, local, assigns) do
    template =
      Application.app_dir(:crosswake, Path.join("priv/templates/crosswake/shell", template_path))

    version = fetch_version!()

    EEx.eval_file(
      template,
      assigns:
        [
          capabilities: capabilities,
          local: local,
          version: version
        ] ++ assigns
    )
  end

  defp local_package_assigns(root) do
    packages_root = Path.expand("packages", File.cwd!())

    [
      local_ios_core_path:
        relative_path(root, Path.join(packages_root, "crosswake-shell-core-ios")),
      local_android_core_path:
        relative_path(root, Path.join(packages_root, "crosswake-shell-core-android"))
    ]
  end

  defp relative_path(from_dir, to_path) do
    from_parts = from_dir |> Path.expand() |> Path.split()
    to_parts = to_path |> Path.expand() |> Path.split()
    common_length = common_prefix_length(from_parts, to_parts)

    up =
      from_parts
      |> Enum.drop(common_length)
      |> Enum.map(fn _part -> ".." end)

    down = Enum.drop(to_parts, common_length)

    case up ++ down do
      [] -> "."
      parts -> Path.join(parts)
    end
  end

  defp common_prefix_length(left, right) do
    left
    |> Enum.zip(right)
    |> Enum.take_while(fn {left_part, right_part} -> left_part == right_part end)
    |> length()
  end

  defp fetch_version! do
    version =
      Application.spec(:crosswake, :vsn) ||
        Keyword.get(Mix.Project.config(), :version)

    case version do
      nil ->
        Mix.raise("""
        could not determine the crosswake version from Application.spec(:crosswake, :vsn) or Mix.Project.config()[:version].
        Run `mix app.start` before generating a shell from the Crosswake source checkout, or install crosswake as a Hex dependency in your host project.
        """)

      vsn ->
        to_string(vsn)
    end
  end

  defp fetch_capabilities(nil), do: Crosswake.Manifest.Builder.public_route_capability_ids()

  defp fetch_capabilities(router) do
    module = String.to_atom(router)

    if Code.ensure_loaded?(module) do
      {:ok, %{manifest: manifest}} = Crosswake.Manifest.compile(module)
      Map.keys(manifest.capability_registry)
    else
      Mix.raise("router module #{router} is not available")
    end
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
