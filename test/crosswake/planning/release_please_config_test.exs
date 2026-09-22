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
        ~r/# x-release-please-version\s+@version\s+"(?<version>[^"]+)"/
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
           ] ==
             get_in(config, ["packages", "packages/crosswake-shell-core-android", "extra-files"])
  end

  test "dispatch-only lockstep check reads the declaration after the marker and rejects empty values" do
    workflow = File.read!(".github/workflows/release-please.yml")

    assert workflow =~ "MIX_VERSION=$(sed -n '/# x-release-please-version/"
    assert workflow =~ "@version \"\\([^\\\"]*\\)\""

    assert workflow =~
             "LOCKSTEP EXTRACTION FAILED: one or more configured version coordinates are empty."

    assert workflow =~ "[ -z \"$MIX_VERSION\" ]"
    assert workflow =~ "[ -z \"$GRADLE_VERSION\" ]"
    assert workflow =~ "[ -z \"$MANIFEST_ROOT\" ]"
    assert workflow =~ "[ -z \"$MANIFEST_ANDROID\" ]"
  end

  test "Maven fire-drill retains and prints only the Portal validation errors on failure" do
    workflow = File.read!(".github/workflows/maven-publish-fire-drill.yml")

    assert workflow =~ "STATUS_JSON=$(curl -fsS -X POST -H \"$AUTH\""
    assert workflow =~ "Central Portal validation errors:"

    assert workflow =~
             "errors=json.load(sys.stdin).get(\"errors\", []); json.dump(errors, sys.stdout, ensure_ascii=False); print()"

    refute workflow =~ "Deployment FAILED — retaining for inspection (not dropping).\"; exit 1"
  end

  test "Maven fire-drill uses a fresh run-scoped coordinate rather than an already-published release coordinate" do
    workflow = File.read!(".github/workflows/maven-publish-fire-drill.yml")
    gradle = File.read!(@android_gradle_path)

    assert workflow =~ "fire_drill_version:"
    assert workflow =~ "FIRE_DRILL_VERSION_INVALID"
    assert workflow =~ "${FIRE_DRILL_BASE_VERSION}-firedrill-${GITHUB_RUN_ID}"
    assert workflow =~ "FIRE_DRILL_COORDINATE_UNAVAILABLE"
    assert workflow =~ "-PcrosswakeVersion=\"$FIRE_DRILL_VERSION\""
    assert workflow =~ "VERSION=\"$FIRE_DRILL_VERSION\""
    assert gradle =~ "(findProperty(\"crosswakeVersion\") as String?)?.let { version = it }"
  end

  test "workflow dispatch isolates the fire drill from Release Please housekeeping" do
    conditions =
      workflow_json!(
        ".github/workflows/release-please.yml",
        "{name: job.get('if') for name, job in doc['jobs'].items() if name in " <>
          "['release-please', 'android-publish-fire-drill', 'lockstep-truth']}"
      )

    assert conditions["release-please"] == "${{ github.event_name == 'push' }}"

    refute Map.has_key?(conditions, "android-publish-fire-drill")

    assert conditions["lockstep-truth"] == "${{ github.event_name == 'workflow_dispatch' }}"
  end

  defp workflow_json!(path, extractor) do
    {output, 0} =
      System.cmd("python3", [
        "-c",
        """
        import json, sys, yaml
        with open(sys.argv[1], encoding="utf-8") as workflow:
            doc = yaml.safe_load(workflow)
        print(json.dumps(#{extractor}))
        """,
        path
      ])

    Jason.decode!(output)
  end

  defp release_please_version(contents, regex) do
    case Regex.named_captures(regex, contents) do
      %{"version" => version} -> version
      _ -> flunk("expected a version with x-release-please-version marker")
    end
  end
end
