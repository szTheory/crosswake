defmodule Crosswake.Planning.ReleasePleaseConfigTest do
  use ExUnit.Case, async: true

  @config_path "release-please-config.json"
  @mix_path "mix.exs"
  @android_gradle_path "packages/crosswake-shell-core-android/build.gradle.kts"

  test "root release PR updates Hex and Android Maven version files together" do
    config = @config_path |> File.read!() |> Jason.decode!()
    root_extra_files = get_in(config, ["packages", ".", "extra-files"])

    assert @mix_path in root_extra_files

    assert %{"type" => "generic", "path" => @android_gradle_path} in root_extra_files,
           "the root release PR must bump the Android Gradle version before publish-android-core runs"

    mix_version =
      release_please_version(
        File.read!(@mix_path),
        ~r/@version\s+"(?<version>[^"]+)"\s+# x-release-please-version/
      )

    android_version =
      release_please_version(
        File.read!(@android_gradle_path),
        ~r/version\s*=\s*"(?<version>[^"]+)"\s*\/\/ x-release-please-version/
      )

    assert android_version == mix_version
  end

  test "android component still declares its own package-level extra file" do
    config = @config_path |> File.read!() |> Jason.decode!()

    assert [
             %{"type" => "generic", "path" => @android_gradle_path}
           ] == get_in(config, ["packages", "packages/crosswake-shell-core-android", "extra-files"])
  end

  defp release_please_version(contents, regex) do
    case Regex.named_captures(regex, contents) do
      %{"version" => version} -> version
      _ -> flunk("expected a version with x-release-please-version marker")
    end
  end
end
