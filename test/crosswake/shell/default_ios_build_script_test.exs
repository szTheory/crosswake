defmodule Crosswake.Shell.DefaultIOSBuildScriptTest do
  # Mix task state and the app env are process-wide test resources.
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @script Path.expand("../../../script/verify_default_ios_generation_build.sh", __DIR__)
  @workflow Path.expand("../../../.github/workflows/crosswake-ci.yml", __DIR__)
  @task "crosswake.gen.shell"
  @settings "CrosswakeHostSettings.xcconfig"
  @step_line "        run: bash script/verify_default_ios_generation_build.sh"

  # A fake xcodebuild that models only what it can: the missing base configuration file and
  # the resolved package line. It never models a relative local package path, because local
  # projects are only built in generate mode against the real xcodebuild.
  @fake_xcodebuild ~S"""
  #!/usr/bin/env bash
  set -u
  if [ -n "${FAKE_XCODEBUILD_LOG:-}" ]; then echo "$*" >> "$FAKE_XCODEBUILD_LOG"; fi
  project=""
  while [ "$#" -gt 0 ]; do
    if [ "$1" = "-project" ]; then project="$2"; shift; fi
    shift
  done
  dir="$(dirname "$project")"
  minimum="$(sed -n 's/.*minimumVersion = \([^;]*\);.*/\1/p' "$project/project.pbxproj")"
  resolved_line="CrosswakeShellCore: https://github.com/szTheory/crosswake-shell-core-ios.git @ ${minimum}"
  case "${FAKE_XCODEBUILD_MODE:-honest}" in
    honest)
      if [ ! -f "$dir/CrosswakeHostSettings.xcconfig" ]; then
        echo "$project: error: Unable to open base configuration reference file '$dir/CrosswakeHostSettings.xcconfig'. (in target 'CrosswakeShell' from project 'CrosswakeShell')"
        exit 65
      fi
      echo "Resolved source packages:"
      echo "  $resolved_line"
      echo "** BUILD SUCCEEDED **"
      ;;
    always_pass)
      echo "  $resolved_line"
      echo "** BUILD SUCCEEDED **"
      ;;
    wrong_version)
      echo "  CrosswakeShellCore: https://github.com/szTheory/crosswake-shell-core-ios.git @ 9.9.9"
      echo "** BUILD SUCCEEDED **"
      ;;
    no_resolved_line)
      echo "** BUILD SUCCEEDED **"
      ;;
    no_resolve)
      echo "xcodebuild: error: Could not resolve package dependencies:"
      exit 74
      ;;
  esac
  """

  setup do
    previous = Application.fetch_env(:crosswake, :ios_host)
    Application.delete_env(:crosswake, :ios_host)

    on_exit(fn ->
      case previous do
        {:ok, value} -> Application.put_env(:crosswake, :ios_host, value)
        :error -> Application.delete_env(:crosswake, :ios_host)
      end
    end)

    tmp = tmp_dir!("crosswake-default-ios-build-script")
    fake = Path.join(tmp, "fake_xcodebuild")
    File.write!(fake, @fake_xcodebuild)
    File.chmod!(fake, 0o755)
    runner_temp = Path.join(tmp, "runner_temp")
    File.mkdir_p!(runner_temp)

    {:ok, tmp: tmp, fake: fake, runner_temp: runner_temp}
  end

  describe "remote form on a given default project (honest fake)" do
    test "passes, names the resolved core, leaves the given project byte-unchanged", ctx do
      project = generate_default!(ctx.tmp, "remote", [])
      before = snapshot(project)
      mix_version = Mix.Project.config()[:version]

      log = Path.join(ctx.tmp, "fake-args.log")

      {status, output, verdict} =
        run_gate(ctx, ["--project-root", project, "--remote-version", "0.0.1"], "honest", log)

      assert status == 0, output

      # Two builds (the build and its negative control), both with the release clean-room flags.
      [first, second] = log |> File.read!() |> String.split("\n", trim: true)

      for line <- [first, second] do
        assert line =~ "-scheme CrosswakeShell -sdk iphonesimulator"
        assert line =~ "-destination generic/platform=iOS Simulator"
        assert line =~ "CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=YES ARCHS="
        assert String.ends_with?(line, " build")
      end

      assert verdict =~
               "default-ios-build: mode=remote project=given generator=- generator_dirty=-"

      assert verdict =~ " remote_from=#{mix_version} remote_min=0.0.1 resolved=0.0.1 "
      assert verdict =~ " control=detected verdict=PASS first_error=none"
      assert verdict =~ ~r/build_rc=0 build_seconds=\d+ control_rc=65 /

      assert snapshot(project) == before

      assert File.read!(Path.join(project, "CrosswakeShell.xcodeproj/project.pbxproj")) =~
               "minimumVersion = #{mix_version};"

      assert File.regular?(Path.join(project, @settings))
      assert no_leftover_work_root?(ctx)
      refute verdict =~ ~r{/tmp|/private|/Users}
    end

    test "fails build_failed, with a scrubbed first error, when the settings file is absent",
         ctx do
      project = generate_default!(ctx.tmp, "remote-missing", [])
      File.rm!(Path.join(project, @settings))

      {status, output, verdict} =
        run_gate(ctx, ["--project-root", project, "--remote-version", "0.0.1"])

      assert status == 1, output
      assert verdict =~ "verdict=FAIL reason=build_failed"
      assert verdict =~ ~r/build_rc=65 .* control=skipped /
      assert verdict =~ "Unable to open base configuration reference file '<work>/"
      assert verdict =~ @settings
      refute verdict =~ ctx.tmp
      refute verdict =~ ~r{/tmp|/private|/Users}
      assert no_leftover_work_root?(ctx)
    end
  end

  describe "the gate cannot pass while asserting nothing" do
    test "fails negative_control_passed when the build succeeds without the settings file", ctx do
      project = generate_default!(ctx.tmp, "always-pass", [])

      {status, output, verdict} =
        run_gate(ctx, ["--project-root", project, "--remote-version", "0.0.1"], "always_pass")

      assert status == 1, output
      assert verdict =~ "control=not_detected verdict=FAIL reason=negative_control_passed"
      refute verdict =~ "verdict=PASS"
    end

    test "fails resolved_version_mismatch when the resolved core is not the requested one", ctx do
      project = generate_default!(ctx.tmp, "wrong-version", [])

      {status, output, verdict} =
        run_gate(ctx, ["--project-root", project, "--remote-version", "0.0.1"], "wrong_version")

      assert status == 1, output
      assert verdict =~ "resolved=9.9.9 "
      assert verdict =~ "verdict=FAIL reason=resolved_version_mismatch"
      assert verdict =~ "control=skipped"
    end

    test "errors resolved_unreadable and never prints PASS when no resolved line exists", ctx do
      project = generate_default!(ctx.tmp, "no-resolved", [])

      {status, output, verdict} =
        run_gate(
          ctx,
          ["--project-root", project, "--remote-version", "0.0.1"],
          "no_resolved_line"
        )

      assert status == 2, output
      assert verdict =~ "resolved=- "
      assert verdict =~ "verdict=ERROR reason=resolved_unreadable"
      refute output =~ "verdict=PASS"
    end

    test "errors package_resolution_failed when packages cannot be resolved", ctx do
      project = generate_default!(ctx.tmp, "no-resolve", [])

      {status, output, verdict} =
        run_gate(ctx, ["--project-root", project, "--remote-version", "0.0.1"], "no_resolve")

      assert status == 2, output
      assert verdict =~ "build_rc=74 "
      assert verdict =~ "verdict=ERROR reason=package_resolution_failed"
    end
  end

  describe "refusals before any build" do
    test "a --local default project is refused: copying it would break its package path", ctx do
      project = generate_default!(ctx.tmp, "local-form", ["--local"])
      log = Path.join(ctx.tmp, "fake.log")

      {status, output, verdict} =
        run_gate(ctx, ["--project-root", project, "--remote-version", "0.0.1"], "honest", log)

      assert status == 2, output
      assert verdict =~ "verdict=ERROR reason=local_copy_unsupported"
      refute File.exists?(log)
    end

    test "a project with two minimumVersion lines is not the remote form", ctx do
      project = generate_default!(ctx.tmp, "two-minimums", [])
      pbxproj = Path.join(project, "CrosswakeShell.xcodeproj/project.pbxproj")
      File.write!(pbxproj, File.read!(pbxproj) <> "\n// minimumVersion = 9.9.9;\n")
      log = Path.join(ctx.tmp, "fake.log")

      {status, output, verdict} =
        run_gate(ctx, ["--project-root", project, "--remote-version", "0.0.1"], "honest", log)

      assert status == 2, output
      assert verdict =~ "verdict=ERROR reason=not_remote_form"
      refute File.exists?(log)
    end

    test "a project with managed host metadata is not the default path", ctx do
      project = generate_default!(ctx.tmp, "managed", [])
      metadata = Path.join(project, ".crosswake/ios_host_generation.json")
      File.mkdir_p!(Path.dirname(metadata))
      File.write!(metadata, "{}\n")

      {status, output, verdict} =
        run_gate(ctx, ["--project-root", project, "--remote-version", "0.0.1"])

      assert status == 2, output
      assert verdict =~ "verdict=ERROR reason=not_default_path"
    end

    test "--project-root without --remote-version is a usage error", ctx do
      project = generate_default!(ctx.tmp, "no-version", [])
      {status, output, verdict} = run_gate(ctx, ["--project-root", project])

      assert status == 2, output
      assert verdict =~ "verdict=ERROR reason=bad_usage"
    end

    test "--source-root together with --project-root is a usage error", ctx do
      project = generate_default!(ctx.tmp, "both-roots", [])

      {status, output, verdict} =
        run_gate(ctx, [
          "--source-root",
          ctx.tmp,
          "--project-root",
          project,
          "--remote-version",
          "0.0.1"
        ])

      assert status == 2, output
      assert verdict =~ "verdict=ERROR reason=bad_usage"
    end

    test "a malformed remote version is a usage error", ctx do
      {status, output, verdict} = run_gate(ctx, ["--remote-version", "1.2"])

      assert status == 2, output
      assert verdict =~ "verdict=ERROR reason=bad_usage"
    end

    test "--source-root without a crosswake mix.exs is bad_source", ctx do
      empty = Path.join(ctx.tmp, "empty_source")
      File.mkdir_p!(empty)

      {status, output, verdict} = run_gate(ctx, ["--source-root", empty])

      assert status == 2, output
      assert verdict =~ "verdict=ERROR reason=bad_source"
    end
  end

  describe "the CI step" do
    test "phase79-ios-proof runs the gate as a blocking step on every full-proof run" do
      workflow = File.read!(@workflow)

      assert blocking_gate_step?(workflow)
      assert job_body(workflow, "phase79-ios-proof") =~ "classification == 'full_proof'"
    end

    test "the pin has teeth: removing the step or making it non-blocking fails it" do
      workflow = File.read!(@workflow)
      assert blocking_gate_step?(workflow)

      removed = String.replace(workflow, @step_line, "        run: echo removed")
      refute blocking_gate_step?(removed)

      soft =
        String.replace(workflow, @step_line, @step_line <> "\n        continue-on-error: true")

      refute blocking_gate_step?(soft)
    end

    test "the remote rehearsal is not wired into CI" do
      refute File.read!(@workflow) =~ "remote-version"
    end
  end

  # -- helpers ------------------------------------------------------------------------------

  defp run_gate(ctx, args, mode \\ "honest", fake_log \\ nil) do
    env =
      [
        {"CROSSWAKE_IOS_XCODEBUILD_BIN", ctx.fake},
        {"FAKE_XCODEBUILD_MODE", mode},
        {"RUNNER_TEMP", ctx.runner_temp}
      ] ++ if(fake_log, do: [{"FAKE_XCODEBUILD_LOG", fake_log}], else: [])

    {output, status} = System.cmd("bash", [@script | args], env: env, stderr_to_stdout: true)

    verdict =
      output
      |> String.split("\n", trim: true)
      |> List.last()

    assert verdict =~ "default-ios-build: mode=", "no verdict line in:\n#{output}"
    assert length(Regex.scan(~r/^default-ios-build: mode=/m, output)) == 1
    {status, output, verdict}
  end

  defp generate_default!(tmp, name, args) do
    target = Path.join(tmp, name)
    File.mkdir_p!(target)

    capture_io(fn ->
      Mix.Task.reenable(@task)
      Mix.Task.run(@task, ["ios", "--target", target] ++ args)
    end)

    Path.join(target, "native/ios/crosswake_shell")
  end

  defp snapshot(root) do
    root
    |> Path.join("**")
    |> Path.wildcard(match_dot: true)
    |> Enum.filter(&File.regular?/1)
    |> Enum.sort()
    |> Map.new(fn path -> {Path.relative_to(path, root), File.read!(path)} end)
  end

  defp no_leftover_work_root?(ctx) do
    File.ls!(ctx.runner_temp) == []
  end

  defp blocking_gate_step?(workflow) do
    body = job_body(workflow, "phase79-ios-proof")

    job_level_soft? =
      body |> String.split("\n    steps:\n", parts: 2) |> hd() =~ "continue-on-error"

    steps = body |> String.split("\n      - ") |> tl()

    gate_steps =
      Enum.filter(
        steps,
        &Regex.match?(
          ~r/^        run: bash script\/verify_default_ios_generation_build\.sh$/m,
          &1
        )
      )

    not job_level_soft? and
      match?([_], gate_steps) and
      Enum.all?(gate_steps, &(not String.contains?(&1, "continue-on-error")))
  end

  defp job_body(workflow, job) do
    [_prefix, rest] = String.split(workflow, "  #{job}:", parts: 2)
    [body | _] = String.split(rest, ~r/^  [a-z0-9_-]+:/m, parts: 2)
    body
  end

  defp tmp_dir!(prefix) do
    path = Path.join(System.tmp_dir!(), "#{prefix}-#{System.unique_integer([:positive])}")
    File.rm_rf!(path)
    File.mkdir_p!(path)
    on_exit(fn -> File.rm_rf(path) end)
    path
  end
end
