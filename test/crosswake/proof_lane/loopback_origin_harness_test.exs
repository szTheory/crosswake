defmodule Crosswake.ProofLane.LoopbackOriginHarnessTest do
  # Phase 186 (LOOP-06, D-14): drives the real loopback Simulator harness script, copied into a
  # committed temp git clone, through PATH shims. It never starts a Simulator, xcodebuild or the
  # twin. Each case changes exactly one thing from the passing baseline, except the one composed
  # unavailable-plus-evidence case. Shim state, TMPDIR and evidence live outside the clone.
  use ExUnit.Case, async: false

  @repo_root Path.expand("../../..", __DIR__)
  @script_rel "script/verify_loopback_origin_simulator.sh"
  @helper_files ~w(ProbeApp.swift generate.exs listener.py)
  @outcome_for_exit %{0 => "passed", 2 => "blocked", 3 => "unavailable"}

  @shim_prelude ~S"""
  #!/usr/bin/env bash
  set -u
  MODE="${CROSSWAKE_LOOP_SHIM_MODE:-baseline}"
  STATE="${CROSSWAKE_LOOP_SHIM_STATE:?}"
  mode_is() { case ",$MODE," in *",$1,"*) return 0 ;; esac; return 1; }
  """

  @mix_shim ~S"""
  if [ "${1:-}" = run ] && [ "${2:-}" = "--no-start" ]; then
    gen="$4"
    port="$5"
    printf '%s\n' "$port" >"$STATE/port"
    proj="$gen/native/ios/crosswake_shell"
    mkdir -p "$proj/CrosswakeShell.xcodeproj" "$proj/CrosswakeShell" "$proj/Fixtures"
    printf 'pbxproj\n' >"$proj/CrosswakeShell.xcodeproj/project.pbxproj"
    printf 'plist\n' >"$proj/CrosswakeShell/Info.plist"
    printf 'coordinator\n' >"$proj/CrosswakeShell/CrosswakeCoordinator.swift"
    printf 'xcconfig\n' >"$proj/CrosswakeHostSettings.xcconfig"
    printf '{}\n' >"$proj/Fixtures/crosswake_manifest.json"
    if mode_is nothing-swapped; then
      cp "$(dirname "$3")/ProbeApp.swift" "$proj/CrosswakeShell/CrosswakeShellApp.swift"
    else
      printf '// generated placeholder app\n' >"$proj/CrosswakeShell/CrosswakeShellApp.swift"
    fi
    exit 0
  fi
  exit 1
  """

  @xcodebuild_shim ~S"""
  if [ "${1:-}" = "-version" ]; then
    printf 'Xcode 99.0\nBuild version FAKE\n'
    exit 0
  fi
  if [ "${1:-}" = build ]; then
    printf '%s\n' "$*" >>"$STATE/xcodebuild.trace"
    dd=""
    proj=""
    while [ "$#" -gt 0 ]; do
      case "$1" in
        -derivedDataPath) dd="$2"; shift ;;
        -project) proj="$(dirname "$2")"; shift ;;
      esac
      shift
    done
    printf '%s\n' "$proj" >"$STATE/proj"
    app="$dd/Build/Products/Debug-iphonesimulator/CrosswakeShell.app"
    mkdir -p "$app"
    printf 'built plist\n' >"$app/Info.plist"
    if mode_is build-rewrite-coordinator; then
      printf 'rewritten by build\n' >"$proj/CrosswakeShell/CrosswakeCoordinator.swift"
    fi
    if mode_is build-rewrite-app; then
      printf '// some other bytes\n' >"$proj/CrosswakeShell/CrosswakeShellApp.swift"
    fi
    if mode_is build-extra; then
      printf 'extra\n' >"$proj/CrosswakeShell/Extra.swift"
    fi
    if mode_is build-byproducts; then
      mkdir -p "$proj/CrosswakeShell.xcodeproj/project.xcworkspace/xcshareddata/swiftpm" \
        "$proj/CrosswakeShell.xcodeproj/xcuserdata/shim.xcuserdatad"
      printf 'resolved\n' >"$proj/CrosswakeShell.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
      printf 'state\n' >"$proj/CrosswakeShell.xcodeproj/xcuserdata/shim.xcuserdatad/UserInterfaceState.xcuserstate"
    fi
  fi
  exit 0
  """

  @plutil_shim ~S"""
  case "${2:-}" in
    NSAppTransportSecurity) printf '{"NSAllowsLocalNetworking":true}\n' ;;
    CrosswakeOriginMode) printf 'local_loopback\n' ;;
    CFBundleIdentifier) printf 'org.crosswake.loopbackprobe\n' ;;
    *) exit 1 ;;
  esac
  exit 0
  """

  @xcrun_shim ~S"""
  [ "${1:-}" = simctl ] || exit 1
  shift
  sub="${1:-}"
  shift || true
  case "$sub" in
    list)
      if [ "${1:-}" = devices ] && [ "${2:-}" = available ]; then
        if mode_is empty-devices; then
          printf '{"devices":{}}\n'
        else
          printf '%s\n' '{"devices":{"com.apple.CoreSimulator.SimRuntime.iOS-18-0":[{"udid":"FAKE-UDID","state":"Shutdown","name":"iPhone 17","isAvailable":true}]}}'
        fi
      elif mode_is huge-list; then
        awk 'BEGIN { for (i = 0; i < 200000; i++) print (i == 0 ? "    iPhone 17 (FAKE-UDID) (Shutdown)" : "    iPhone 17 (FAKE-UDID) (Booted)") }'
      elif mode_is not-restored; then
        printf '== Devices ==\n    iPhone 17 (FAKE-UDID) (Booted)\n'
      else
        printf '== Devices ==\n    iPhone 17 (FAKE-UDID) (Shutdown)\n'
      fi
      ;;
    boot | bootstatus | install | terminate) exit 0 ;;
    uninstall)
      if mode_is uninstall-fails && [ -f "$STATE/launched" ]; then exit 1; fi
      exit 0
      ;;
    get_app_container)
      mkdir -p "$STATE/data/tmp"
      printf '%s\n' "$STATE/data"
      ;;
    launch)
      mkdir -p "$STATE/data/tmp"
      : >"$STATE/launched"
      if [ -n "${SIMCTL_CHILD_PROBE_URL:-}" ]; then
        printf 'didFailProvisional NSURLErrorDomain -1022' >"$STATE/data/tmp/result.txt"
      else
        python3 -I -c '
  import http.client, sys
  for path in ("/study-session", "/__loaded"):
      try:
          conn = http.client.HTTPConnection("127.0.0.1", int(sys.argv[1]), timeout=10)
          conn.request("GET", path)
          conn.getresponse().read()
          conn.close()
      except Exception:
          pass
  ' "$(cat "$STATE/port")"
        printf 'didFinish' >"$STATE/data/tmp/result.txt"
        if mode_is launch-rewrite-fixture; then
          printf '{"changed":true}\n' >"$(cat "$STATE/proj")/Fixtures/crosswake_manifest.json"
        fi
      fi
      ;;
    *) exit 0 ;;
  esac
  exit 0
  """

  @mv_shim ~S"""
  for last in "$@"; do :; done
  if mode_is mv-fails && [ "$last" = "${CROSSWAKE_LOOP_SHIM_EVIDENCE:-}" ]; then
    exit 1
  fi
  exec /bin/mv "$@"
  """

  @shasum_shim ~S"""
  [ "${1:-}" = "-a" ] && shift 2
  exec sha256sum "$@"
  """

  setup do
    base = Path.join(System.tmp_dir!(), "SENTINEL-186-H-#{System.unique_integer([:positive])}")
    dirs = for d <- ~w(clone bin state tmp ev), into: %{}, do: {d, Path.join(base, d)}
    Enum.each(Map.values(dirs), &File.mkdir_p!/1)
    on_exit(fn -> File.rm_rf!(base) end)
    build_clone(dirs["clone"])
    write_shims(dirs["bin"])

    %{
      base: base,
      clone: dirs["clone"],
      bin: dirs["bin"],
      state: dirs["state"],
      tmp: dirs["tmp"],
      ev: dirs["ev"]
    }
  end

  test "baseline: a clean shimmed run passes with one JSON object equal to the evidence file and no leaked path",
       ctx do
    result = run_harness(ctx, "baseline")
    json = assert_verdict(ctx, result, "passed", nil)

    assert json["cleanup"]["app_uninstalled"] == true
    assert json["cleanup"]["device_left_as_found"] == true
    assert map_size(json["assertions"]) > 0
    assert File.read!(result.evidence) |> String.trim() == String.trim(result.stdout)
    assert Jason.decode!(File.read!(result.evidence)) == json
    assert File.read!(Path.join(ctx.state, "xcodebuild.trace")) =~ "build"
  end

  test "cleanup: a failed uninstall after a passing run blocks with LOOP-IOS-CLEANUP", ctx do
    result = run_harness(ctx, "uninstall-fails")
    json = assert_verdict(ctx, result, "blocked", "LOOP-IOS-CLEANUP")
    assert json["cleanup"]["app_uninstalled"] == false
  end

  test "cleanup: a device not restored to Shutdown blocks with LOOP-IOS-CLEANUP", ctx do
    result = run_harness(ctx, "not-restored")
    json = assert_verdict(ctx, result, "blocked", "LOOP-IOS-CLEANUP")
    assert json["cleanup"]["device_left_as_found"] == false
  end

  test "cleanup: a very long device list still reads the restored Shutdown state", ctx do
    result = run_harness(ctx, "huge-list")
    json = assert_verdict(ctx, result, "passed", nil)
    assert json["cleanup"]["device_left_as_found"] == true
  end

  test "hash: a changed generated file other than the swap target blocks with LOOP-IOS-OWNED-HASH",
       ctx do
    result = run_harness(ctx, "build-rewrite-coordinator")
    json = assert_verdict(ctx, result, "blocked", "LOOP-IOS-OWNED-HASH")
    assert json["cause"] =~ "CrosswakeCoordinator.swift"
  end

  test "hash: a swap target whose bytes differ from ProbeApp.swift blocks with LOOP-IOS-OWNED-HASH",
       ctx do
    result = run_harness(ctx, "build-rewrite-app")
    json = assert_verdict(ctx, result, "blocked", "LOOP-IOS-OWNED-HASH")
    assert json["cause"] =~ "CrosswakeShellApp.swift"
  end

  test "hash: a run in which nothing was swapped blocks with LOOP-IOS-OWNED-HASH", ctx do
    result = run_harness(ctx, "nothing-swapped")
    assert_verdict(ctx, result, "blocked", "LOOP-IOS-OWNED-HASH")
  end

  test "hash: a generated file changed during launch blocks at exit with LOOP-IOS-OWNED-HASH",
       ctx do
    result = run_harness(ctx, "launch-rewrite-fixture")
    assert_verdict(ctx, result, "blocked", "LOOP-IOS-OWNED-HASH")
  end

  test "hash: a file added by the build outside the allow-list blocks with LOOP-IOS-OWNED-HASH",
       ctx do
    result = run_harness(ctx, "build-extra")
    json = assert_verdict(ctx, result, "blocked", "LOOP-IOS-OWNED-HASH")
    assert json["cause"] =~ "Extra.swift"
  end

  test "hash: build byproducts under the generated xcodeproj are allowed", ctx do
    result = run_harness(ctx, "build-byproducts")
    assert_verdict(ctx, result, "passed", nil)
  end

  test "evidence: an empty evidence value blocks with LOOP-IOS-EVIDENCE before any build", ctx do
    result = run_harness(ctx, "baseline", evidence_arg: "")
    assert_verdict(ctx, result, "blocked", "LOOP-IOS-EVIDENCE")
    assert result.exit == 2
    refute_build_called(ctx)
  end

  test "evidence: a bare evidence flag blocks with LOOP-IOS-EVIDENCE and still prints one JSON object",
       ctx do
    result = run_harness(ctx, "baseline", argv: ["--evidence"])
    assert_verdict(ctx, result, "blocked", "LOOP-IOS-EVIDENCE")
    assert result.exit == 2
    refute_build_called(ctx)
  end

  test "evidence: a missing evidence directory blocks with LOOP-IOS-EVIDENCE before any build",
       ctx do
    result = run_harness(ctx, "baseline", evidence_arg: Path.join([ctx.ev, "nope", "out.json"]))
    assert_verdict(ctx, result, "blocked", "LOOP-IOS-EVIDENCE")
    refute_build_called(ctx)
  end

  test "evidence: an evidence path that is a directory blocks with LOOP-IOS-EVIDENCE before any build",
       ctx do
    result = run_harness(ctx, "baseline", evidence_arg: ctx.ev)
    assert_verdict(ctx, result, "blocked", "LOOP-IOS-EVIDENCE")
    refute_build_called(ctx)
  end

  test "evidence: a failed move into place blocks with LOOP-IOS-EVIDENCE and leaves no temp file",
       ctx do
    result = run_harness(ctx, "mv-fails")
    assert_verdict(ctx, result, "blocked", "LOOP-IOS-EVIDENCE")
    refute File.exists?(result.evidence)
    assert File.ls!(ctx.ev) == []
  end

  test "evidence: a relative evidence path resolves against the invoking directory", ctx do
    result = run_harness(ctx, "baseline", evidence_arg: "out.json", cwd: ctx.ev)
    assert_verdict(ctx, result, "passed", nil)
    assert File.regular?(Path.join(ctx.ev, "out.json"))
    assert git(ctx.clone, ["status", "--porcelain"]) == ""
  end

  test "evidence: a write failure on an unavailable run keeps exit 3 and adds LOOP-IOS-EVIDENCE",
       ctx do
    result = run_harness(ctx, "empty-devices,mv-fails")
    json = assert_verdict(ctx, result, "unavailable", "LOOP-IOS-EVIDENCE")
    assert result.exit == 3
    assert "LOOP-IOS-SIMULATOR" in json["rule_ids"]
    refute File.exists?(result.evidence)
    assert File.ls!(ctx.ev) == []
  end

  # ------------------------------------------------------------------ helpers

  defp build_clone(clone) do
    for rel <- [@script_rel | Enum.map(@helper_files, &"script/loopback_origin_simulator/#{&1}")] do
      dest = Path.join(clone, rel)
      File.mkdir_p!(Path.dirname(dest))
      File.cp!(Path.join(@repo_root, rel), dest)
    end

    File.chmod!(Path.join(clone, @script_rel), 0o755)
    pkg = Path.join(clone, "packages/crosswake-shell-core-ios")
    File.mkdir_p!(pkg)
    File.write!(Path.join(pkg, "Package.swift"), "// minimal fixture package\n")

    git(clone, ["init", "-q"])
    git(clone, ["add", "-A"])
    git(clone, ["-c", "user.email=t@t", "-c", "user.name=t", "commit", "-q", "-m", "fixture"])
  end

  defp refute_build_called(ctx) do
    trace = Path.join(ctx.state, "xcodebuild.trace")
    refute File.exists?(trace) and File.read!(trace) =~ "build"
  end

  defp git(dir, args) do
    {out, 0} = System.cmd("git", args, cd: dir, stderr_to_stdout: true)
    out
  end

  defp write_shims(bin) do
    shims = [
      {"mix", @mix_shim},
      {"xcodebuild", @xcodebuild_shim},
      {"plutil", @plutil_shim},
      {"xcrun", @xcrun_shim},
      {"mv", @mv_shim}
    ]

    shims =
      if System.find_executable("shasum") == nil,
        do: [{"shasum", @shasum_shim} | shims],
        else: shims

    for {name, body} <- shims do
      path = Path.join(bin, name)
      File.write!(path, @shim_prelude <> body)
      File.chmod!(path, 0o755)
    end
  end

  # Runs the clone's script with shims first on PATH. Returns stdout (stderr goes to a file),
  # the exit status and the absolute evidence path used.
  defp run_harness(ctx, mode, opts \\ []) do
    evidence_arg = Keyword.get(opts, :evidence_arg, Path.join(ctx.ev, "evidence.json"))
    cwd = Keyword.get(opts, :cwd, ctx.clone)
    argv = Keyword.get(opts, :argv, ["--evidence", evidence_arg])
    stderr_file = Path.join(ctx.base, "stderr-#{System.unique_integer([:positive])}.txt")

    env = [
      {"PATH", ctx.bin <> ":" <> System.get_env("PATH")},
      {"TMPDIR", ctx.tmp},
      {"CROSSWAKE_LOOP_SHIM_MODE", mode},
      {"CROSSWAKE_LOOP_SHIM_STATE", ctx.state},
      {"CROSSWAKE_LOOP_SHIM_EVIDENCE", Path.join(ctx.ev, "evidence.json")}
    ]

    {stdout, exit_status} =
      System.cmd(
        "bash",
        [
          "-c",
          ~s(stderr_file="$1"; shift; exec bash "$0" "$@" 2>"$stderr_file"),
          Path.join(ctx.clone, @script_rel),
          stderr_file
          | argv
        ],
        cd: cwd,
        env: env
      )

    %{
      stdout: stdout,
      exit: exit_status,
      evidence: Path.expand(evidence_arg, cwd),
      stderr_file: stderr_file
    }
  end

  # One JSON object on stdout; outcome agrees with exit; expected rule present; no leaked path;
  # no run directory left behind.
  defp assert_verdict(ctx, result, expected_outcome, expected_rule) do
    assert Map.has_key?(@outcome_for_exit, result.exit), "unexpected exit #{result.exit}"
    json = Jason.decode!(result.stdout)
    assert is_map(json)
    assert json["outcome"] == @outcome_for_exit[result.exit]
    assert json["outcome"] == expected_outcome

    if expected_rule do
      assert expected_rule in json["rule_ids"]
    else
      assert json["rule_ids"] == []
    end

    sentinel = Path.basename(ctx.base)
    refute result.stdout =~ sentinel
    refute result.stdout =~ System.user_home!()

    if File.regular?(result.evidence) do
      body = File.read!(result.evidence)
      refute body =~ sentinel
      refute body =~ System.user_home!()
    end

    assert Path.wildcard(Path.join(ctx.tmp, "crosswake-loopback-sim.*")) == []
    json
  end
end
