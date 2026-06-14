defmodule Crosswake.Planning.ReleasePleaseConfigTest do
  use ExUnit.Case, async: true

  @config_path "release-please-config.json"
  @android_gradle_path "packages/crosswake-shell-core-android/build.gradle.kts"

  test "root release PR updates Hex and Android Maven version files together" do
    config = @config_path |> File.read!() |> Jason.decode!()
    root_extra_files = get_in(config, ["packages", ".", "extra-files"])

    assert "mix.exs" in root_extra_files

    assert %{"type" => "generic", "path" => @android_gradle_path} in root_extra_files,
           "the root release PR must bump the Android Gradle version before publish-android-core runs"

    gradle = File.read!(@android_gradle_path)
    assert gradle =~ ~s(version = "0.1.0" // x-release-please-version)
  end

  test "android component still declares its own package-level extra file" do
    config = @config_path |> File.read!() |> Jason.decode!()

    assert [
             %{"type" => "generic", "path" => @android_gradle_path}
           ] == get_in(config, ["packages", "packages/crosswake-shell-core-android", "extra-files"])
  end
end
