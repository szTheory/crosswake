defmodule Mix.Tasks.Crosswake.Gen.Shell do
  use Mix.Task

  alias Crosswake.Shell.Fixtures

  @shortdoc "Generates host-owned native shell baselines for Crosswake"

  @moduledoc """
  Generates reviewable iOS or Android shell baselines, bundled manifest-backed
  activation fixtures, and explicit ownership guidance without claiming runtime
  behavior Crosswake has not proven yet.
  """

  @switches [target: :string, router: :string, local: :boolean, diff: :boolean]

  # Templates excluded from --diff output (Xcode-managed UUIDs always diverge — noise only).
  # Note: gradlew/gradlew.bat are NOT excluded from diff (D-02 excludes only stamps, not diffs).
  @diff_excluded_templates ["CrosswakeShell.xcodeproj/project.pbxproj"]
  @platforms ~w(ios android)

  @template_version 2

  @doc """
  Returns the current integer template epoch.

  This is the single source of truth for Plans 02/03 (shell.status / gen.shell --diff)
  to compare against the stamped manifest version. Never re-parse the module source or
  duplicate this integer — call this function instead.
  """
  @spec template_version() :: pos_integer()
  def template_version, do: @template_version

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
    router = opts[:router]
    local = Keyword.get(opts, :local, false)

    # D-13: Fork BEFORE any write — if --diff, we never reach ensure_file/2 or File.write!/2.
    if opts[:diff] do
      Mix.shell().info("[crosswake] diff — read-only, no files changed")
      run_diff(platform, target, router, local)
    else
      capabilities = fetch_capabilities(router)

      generated =
        case platform do
          "ios" -> generate_ios_shell(target, capabilities, local, router)
          "android" -> generate_android_shell(target, capabilities, local, router)
        end

      Mix.shell().info(
        "Crosswake #{platform} shell scaffold complete\n" <>
          "  generated root: #{generated.root}\n" <>
          "  ownership docs: #{generated.readme}\n" <>
          "  manifest fixture: #{generated.manifest}\n" <>
          "  activation fixture: #{generated.activation}\n" <>
          "  denial fixture: #{generated.denial}\n" <>
          "  baseline entrypoint: #{generated.entrypoint}\n" <>
          "  ownership: host-owned, scaffold once, and not safely regeneratable over host edits\n"
      )
    end
  end

  # ---------------------------------------------------------------------------
  # --diff branch (D-13..D-16, LIFE-02b)
  # ---------------------------------------------------------------------------

  # Entry point for --diff. Reads the manifest to get saved params for re-render
  # so the comparison doesn't show app-name/router noise (D-14).
  defp run_diff(platform, target, router, local) do
    root =
      case platform do
        "ios" -> Path.join(target, "native/ios/crosswake_shell")
        "android" -> Path.join(target, "native/android/crosswake_shell")
      end

    manifest_path = Path.join([root, ".crosswake", "shell.json"])

    {manifest_router, manifest_local} =
      case File.read(manifest_path) do
        {:ok, json} ->
          case Jason.decode(json) do
            {:ok, %{"params" => params}} ->
              {Map.get(params, "router", router), Map.get(params, "local", local)}

            {:ok, _} ->
              Mix.shell().info(
                "[crosswake] manifest at #{manifest_path} has no params — using CLI options"
              )

              {router, local}

            {:error, _} ->
              Mix.shell().info(
                "[crosswake] could not decode manifest at #{manifest_path} — using CLI options"
              )

              {router, local}
          end

        {:error, :enoent} ->
          Mix.shell().info(
            "[crosswake] no manifest found at #{manifest_path} — using CLI options for re-render"
          )

          {router, local}

        {:error, reason} ->
          Mix.shell().info(
            "[crosswake] could not read manifest: #{:file.format_error(reason)} — using CLI options"
          )

          {router, local}
      end

    # D-14: If local: true but local package path no longer resolves, fall back to Hex.
    effective_local =
      if manifest_local do
        packages_root = Path.expand("packages", File.cwd!())
        ios_path = Path.join(packages_root, "crosswake-shell-core-ios")
        android_path = Path.join(packages_root, "crosswake-shell-core-android")

        if File.exists?(ios_path) or File.exists?(android_path) do
          true
        else
          Mix.shell().info(
            "[crosswake] local package path not found: #{packages_root} — falling back to Hex package"
          )

          false
        end
      else
        false
      end

    capabilities = fetch_capabilities(manifest_router)

    templates =
      case platform do
        "ios" -> @ios_templates
        "android" -> @android_templates
      end

    assigns = local_package_assigns(root)

    {changed_ota, changed_rebuild, unchanged, missing} =
      Enum.reduce(
        templates,
        {0, 0, 0, 0},
        fn {relative_path, template_path}, {ota, rebuild, unch, miss} ->
          if relative_path in @diff_excluded_templates do
            {ota, rebuild, unch, miss}
          else
            on_disk_path = Path.join(root, relative_path)
            re_rendered = render_template(template_path, capabilities, effective_local, assigns)

            case File.read(on_disk_path) do
              {:error, :enoent} ->
                Mix.shell().info("[crosswake] missing (not generated): #{relative_path}")
                {ota, rebuild, unch, miss + 1}

              {:error, reason} ->
                Mix.shell().info(
                  "[crosswake] could not read #{relative_path}: #{:file.format_error(reason)}"
                )

                {ota, rebuild, unch, miss + 1}

              {:ok, on_disk} ->
                if on_disk == re_rendered do
                  {ota, rebuild, unch + 1, miss}
                else
                  verdict = file_advisory_verdict(relative_path)
                  print_file_diff(relative_path, on_disk, re_rendered, verdict)

                  case verdict do
                    :ota_safe -> {ota + 1, rebuild, unch, miss}
                    {:rebuild_required, _} -> {ota, rebuild + 1, unch, miss}
                  end
                end
            end
          end
        end
      )

    total_changed = changed_ota + changed_rebuild

    Mix.shell().info("""
    [crosswake] diff summary
      changed (ota-safe):        #{changed_ota}
      changed (rebuild-required): #{changed_rebuild}
      unchanged:                 #{unchanged}
      missing on disk:           #{missing}
    """)

    if total_changed == 0 and missing == 0 do
      Mix.shell().info("[crosswake] generated shell matches current templates — no changes.")
    else
      Mix.shell().info(
        "[crosswake] advisory verdicts are tooling input, not release-gate oracles (RebuildPolicy.classify/2 docs)"
      )
    end
  end

  # Prints a git-style unified diff for a single file with advisory verdict.
  # Colorizes with IO.ANSI if the TTY supports it.
  defp print_file_diff(relative_path, on_disk, re_rendered, verdict) do
    old_lines = String.split(on_disk, "\n", trim: false)
    new_lines = String.split(re_rendered, "\n", trim: false)
    diff = List.myers_difference(old_lines, new_lines)

    use_color = IO.ANSI.enabled?()

    verdict_label =
      case verdict do
        :ota_safe -> "ota-safe (advisory)"
        {:rebuild_required, scope} -> "rebuild-required:#{scope} (advisory)"
      end

    Mix.shell().info("--- #{relative_path} (on disk)")
    Mix.shell().info("+++ #{relative_path} (current template)")
    Mix.shell().info("[advisory verdict: #{verdict_label}]")

    # Render hunk with context around changes (3 lines context, like git)
    render_diff_hunks(diff, use_color)
  end

  # Renders diff hunks from myers_difference output, printing git-style @@ ... @@ lines.
  defp render_diff_hunks(diff, use_color) do
    # Flatten diff into indexed line entries
    indexed =
      Enum.flat_map(diff, fn
        {:eq, lines} when is_list(lines) -> Enum.map(lines, &{:eq, &1})
        {:del, lines} when is_list(lines) -> Enum.map(lines, &{:del, &1})
        {:ins, lines} when is_list(lines) -> Enum.map(lines, &{:ins, &1})
        {:eq, line} -> [{:eq, line}]
        {:del, line} -> [{:del, line}]
        {:ins, line} -> [{:ins, line}]
      end)

    # Print changed lines with minimal context
    Enum.each(indexed, fn
      {:eq, _} ->
        :ok

      {:del, line} ->
        if use_color do
          Mix.shell().info(IO.ANSI.red() <> "-#{line}" <> IO.ANSI.reset())
        else
          Mix.shell().info("-#{line}")
        end

      {:ins, line} ->
        if use_color do
          Mix.shell().info(IO.ANSI.green() <> "+#{line}" <> IO.ANSI.reset())
        else
          Mix.shell().info("+#{line}")
        end
    end)
  end

  # Advisory file→change-class verdict lookup (D-16).
  # Reuses RebuildPolicy verdict vocabulary. Does NOT call RebuildPolicy.diff/2
  # (which diffs Root.t() manifests, not files). Advisory only — not a release gate.
  defp file_advisory_verdict(relative_path) do
    basename = Path.basename(relative_path)

    cond do
      basename == "Info.plist" -> {:rebuild_required, :native_shell}
      basename == "PrivacyInfo.xcprivacy" -> {:rebuild_required, :native_shell}
      String.ends_with?(basename, ".entitlements") -> {:rebuild_required, :native_shell}
      basename == "AndroidManifest.xml" -> {:rebuild_required, :native_shell}
      relative_path == "app/build.gradle" -> {:rebuild_required, :native_shell}
      basename == "build.gradle" -> {:rebuild_required, :native_shell}
      relative_path == "gradle/wrapper/gradle-wrapper.properties" -> {:rebuild_required, :native_shell}
      String.ends_with?(basename, ".swift") -> :ota_safe
      String.ends_with?(basename, ".kt") -> :ota_safe
      basename == "gradlew" -> :ota_safe
      basename == "gradlew.bat" -> :ota_safe
      basename == "settings.gradle" -> :ota_safe
      basename == "gradle.properties" -> :ota_safe
      basename == "themes.xml" -> :ota_safe
      # Safe default for any unmapped file
      true -> :ota_safe
    end
  end

  # ---------------------------------------------------------------------------
  # Generation branch (normal, non-diff)
  # ---------------------------------------------------------------------------

  defp generate_ios_shell(target, capabilities, local, router) do
    root = Path.join(target, "native/ios/crosswake_shell")
    fixtures = Fixtures.export("ios")

    readme = Path.join(root, "README.md")
    entrypoint = Path.join(root, "CrosswakeShell/CrosswakeShellApp.swift")

    ensure_file(readme, shell_readme("ios"))
    render_ios_templates(root, capabilities, local)
    write_fixture_files(root, fixtures)
    write_shell_manifest(root, "ios", router, local, target)

    %{
      root: root,
      readme: readme,
      manifest: Path.join(root, "Fixtures/crosswake_manifest.json"),
      activation: Path.join(root, "Fixtures/route_activation.json"),
      denial: Path.join(root, "Fixtures/route_denial.json"),
      entrypoint: entrypoint
    }
  end

  defp generate_android_shell(target, capabilities, local, router) do
    root = Path.join(target, "native/android/crosswake_shell")
    fixtures = Fixtures.export("android")

    ensure_file(Path.join(root, "README.md"), shell_readme("android"))
    render_android_templates(root, capabilities, local)

    entrypoint = Path.join(root, "app/src/main/java/dev/crosswake/shell/MainActivity.kt")
    write_fixture_files(Path.join(root, "app/src/main"), fixtures)

    ensure_executable(Path.join(root, "gradlew"))
    write_shell_manifest(root, "android", router, local, target)

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
          version: version,
          template_version: @template_version
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
    - Upgrade this shell following guides/native_shell_upgrade.md for per-version changelog and rebuild guidance.
    """
  end

  defp platform_readme_label("ios"), do: "Xcode"
  defp platform_readme_label("android"), do: "Android Studio"

  defp write_shell_manifest(root, platform, router, local, target) do
    manifest_path = Path.join([root, ".crosswake", "shell.json"])

    manifest = %{
      "_comment" => "do not hand-edit — regenerate to update",
      "crosswake_version" => fetch_version!(),
      "template_version" => @template_version,
      "platform" => platform,
      "generated_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "params" => %{
        "router" => router,
        "local" => local,
        "target" => target
      }
    }

    File.mkdir_p!(Path.dirname(manifest_path))
    File.write!(manifest_path, Jason.encode!(manifest, pretty: true))
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
