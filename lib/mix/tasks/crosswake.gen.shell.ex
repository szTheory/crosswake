defmodule Mix.Tasks.Crosswake.Gen.Shell do
  use Mix.Task

  @shortdoc "Generates host-owned native shell skeletons for Crosswake"

  @moduledoc """
  Generates reviewable iOS or Android shell skeletons, bundled Phase 1 fixtures,
  and handoff documentation without implying runtime behavior Crosswake has not
  proven yet.
  """

  @switches [target: :string]

  @platforms ~w(ios android)

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
      fixture: #{generated.fixture}
      source: #{generated.source}
    """)
  end

  defp generate_ios_shell(target) do
    root = Path.join(target, "native/ios/crosswake_shell")
    readme = Path.join(root, "README.md")
    source = Path.join(root, "Sources/AppShell.swift")
    fixture = Path.join(root, "Fixtures/phase1_route_policy.json")

    ensure_file(readme, render_shell_readme("ios"))
    ensure_file(source, ios_source())
    ensure_file(fixture, fixture_json("ios"))

    %{root: root, readme: readme, source: source, fixture: fixture}
  end

  defp generate_android_shell(target) do
    root = Path.join(target, "native/android/crosswake_shell")
    readme = Path.join(root, "README.md")
    source = Path.join(root, "app/src/main/java/dev/crosswake/shell/AppShell.kt")
    fixture = Path.join(root, "app/src/main/assets/phase1_route_policy.json")

    ensure_file(readme, render_shell_readme("android"))
    ensure_file(source, android_source())
    ensure_file(fixture, fixture_json("android"))

    %{root: root, readme: readme, source: source, fixture: fixture}
  end

  defp render_shell_readme(platform) do
    template =
      Application.app_dir(:crosswake, "priv/templates/crosswake/shell/#{platform}/README.md.eex")

    EEx.eval_file(template, assigns: [platform: platform])
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

  defp ios_source do
    """
    import Foundation

    struct AppShell {
      let phaseBoundary = "Phase 1 route-policy scaffold only"

      func bootNotes() -> String {
        "Host-owned placeholder: wire manifest activation and runtime boot in Phase 3."
      }
    }
    """
  end

  defp android_source do
    """
    package dev.crosswake.shell

    object AppShell {
      const val PHASE_BOUNDARY = "Phase 1 route-policy scaffold only"

      fun bootNotes(): String {
        return "Host-owned placeholder: wire manifest activation and runtime boot in Phase 3."
      }
    }
    """
  end

  defp fixture_json(platform) do
    """
    {
      "platform": "#{platform}",
      "phase_boundary": "Phase 1 route-policy scaffold only",
      "ownership": "host-owned",
      "next_phase": "manifest truth and shell boot land in later phases"
    }
    """
  end
end
