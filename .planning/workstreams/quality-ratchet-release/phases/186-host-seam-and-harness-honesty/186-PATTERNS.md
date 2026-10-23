# Phase 186: Host seam and harness honesty - Pattern Map

**Mapped:** 2026-10-16
**Code truth:** candidate checkout (detached HEAD `25614cf6`); all paths below are repo-relative to it.
**Files analyzed:** 27 (11 modified product/script files, 5 new test files, 11 modified test/guide files)
**Analogs found:** 26 / 27 (one partial: symlink-canonicalizing `display_location`)

Gate and mutation files live in the run directory (`<runs>`), not in the repo. No absolute home paths appear here.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `lib/crosswake/doctor/doctor.ex` (stale/legacy/skipped, `cwd` threading) | service (doctor checks) | transform (file read to findings) | same file, `stale_host_command_findings/2`, `shell_unsupported_finding/5`, `check/6` | exact |
| `lib/crosswake/shell/shell_package.ex` (`display_location/2`) | utility | transform | `relative_path/2` in `lib/mix/tasks/crosswake.gen.shell.ex:793-806` | partial |
| `lib/crosswake/shell/ios_host_generation.ex` (`shell_gate_message`, `project_root`) | service | request-response | same file `:95`, `:121`; `doctor.ex` `ios_host_origin_observation` for opt reading | exact |
| `lib/mix/tasks/crosswake.gen.shell.ex` (`render_opts`) | task | request-response | same file `:134-141` | exact |
| `packages/.../ActivationCoordinator.swift` (`grantHostCommands` legacy branch) | service | request-response | same function, declared branch `:287-299` | exact |
| `lib/crosswake/proof_lane/physical_iphone_preflight.ex` (only if red) | service | request-response | same file `config/1`; `doctor.ex` `ios_host_origin_observation/2` | role-match |
| `script/verify_loopback_origin_simulator.sh` | script | event-driven (EXIT trap) | same file `cleanup_and_emit` `:136-176` | exact |
| `guides/compatibility.md`, `native_shell_upgrade.md`, `native_shell.md`, `CHANGELOG.md` | docs | n/a | existing paragraphs/rows | exact |
| `test/crosswake/doctor/doctor_host_commands_test.exs` (rewrite + new) | test | CRUD fixtures | itself (`managed_root/4`, `findings/3`, `codes/1`) | exact |
| `test/crosswake/shell/path_redaction_test.exs` (new) | test | transform | `doctor_host_commands_test.exs` + `crosswake_gen_shell_host_commands_test.exs:26-66` | role-match |
| `test/crosswake/proof_lane/loopback_origin_harness_test.exs` (new) | test | process / PATH shim | `test/crosswake/proof_lane/ios_verifier_test.exs` | exact |
| `test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs` (new cases) | test | request-response | itself (`ready_options/0`, `device_report/0`) + `doctor_origin_mode_test.exs` | exact |
| `test/crosswake/guides/host_command_seam_guide_test.exs`, `loopback_origin_guide_test.exs` | test | file read | themselves (`flat/1`, `guide/1`, needle `for`) | exact |
| Swift tests: `HostCommandNavigationTests`, `HostCommandSeamTests`, `Phase180TwinFeasibilityTests` | test | XCTest | themselves | exact |
| `<runs>/mutate-186.sh` (not committed) | script | batch | `<runs>/mutate-185.sh` | exact |

## Pattern Assignments

### `lib/crosswake/doctor/doctor.ex` (service, transform) - Plan 01 only, one edit session

**Analog:** itself. Finding constructor (`doctor.ex:2033`):
```elixir
defp check(severity, code, check_name, message, hint, details \\ %{}) do
  %Check{severity: severity, code: code, check: check_name, message: message, hint: hint, details: details}
end
```
Severities are `:error | :warning | :advisory` (`lib/crosswake/doctor/check.ex:7-9`); status turns `:error` only when some finding is `:error` (`doctor.ex` ~:211-213), so `:advisory` and `:warning` never fail doctor.

**Entry point and opt-reading pattern** (`doctor.ex:~2422-2446`): thread `cwd` into `host_command_shell_findings/3` (Pitfall 7).
```elixir
declaration =
  Keyword.get_lazy(opts, :ios_host, fn -> Application.get_env(:crosswake, :ios_host) end)

defp host_command_seam_findings(manifest, cwd, opts) do
  declaring = manifest.routes |> Enum.filter(fn {_id, entry} -> entry.host_commands != %{} end) |> Enum.sort_by(&elem(&1, 0))
  root = shell_root(:ios, cwd, opts)
  if File.dir?(root) do
    stale_host_command_findings(manifest, root) ++ host_command_shell_findings(declaring, root)
  else
    []
  end
end
```
`File.dir?(root)` already provides the D-05 "iOS root exists" precondition. Pass `declaring` into the stale function for the `stale_skipped` decision.

**Defect to replace** (`doctor.ex:2448-2482`): `with {:ok, bytes} <- File.read(...), {:ok, %{"routes" => generated}} when is_map(generated) <- Jason.decode(bytes) do ... else _ -> [] end`. Replace the `else` with a `case File.read` ordered as in RESEARCH Pattern 2: `{:error, :enoent}` gives advisory `host_commands_stale_skipped` only if `declaring != []`; other `{:error, posix}` gives `host_commands_stale` with `details.reason: "unreadable"`; a pure shape validator returns `:malformed`; then per router route: route absent from fixture and router declares gives `reason: "route_missing"`; key absent gives a legacy group; otherwise compare as today. Keep the mismatch finding details `%{route_id:, commands:, platform: :ios}` unchanged.

**Finding style to copy for new codes** (`doctor.ex:2465-2474`):
```elixir
check(:error, "host_commands_stale", "host_commands",
  "Route #{route_id} host commands in the generated iOS manifest differ from the router declaration",
  "Run mix crosswake.gen.shell ios to regenerate the manifest; do not edit generated fixtures",
  %{route_id: route_id, commands: commands, platform: :ios})
```
Name the fixture by its relative form `Fixtures/crosswake_manifest.json`; never interpolate `root`.

**Redaction call site** (`doctor.ex:2516-2535`, `shell_unsupported_finding/5`): replace `#{package.location}` and `package_location: package.location` with `ShellPackage.display_location(package.location, cwd)`. The `package = %{location: "the managed project", ...}` fallback branch must pass through unchanged (not a path).

---

### `lib/crosswake/shell/shell_package.ex` (utility, transform) - `display_location/2`

**Analog (partial):** `relative_path/2` and `common_prefix_length/2`, `lib/mix/tasks/crosswake.gen.shell.ex:793-815`:
```elixir
defp relative_path(from_dir, to_path) do
  from_parts = from_dir |> Path.expand() |> Path.split()
  to_parts = to_path |> Path.expand() |> Path.split()
  common_length = common_prefix_length(from_parts, to_parts)
  up = from_parts |> Enum.drop(common_length) |> Enum.map(fn _part -> ".." end)
  down = Enum.drop(to_parts, common_length)
  case up ++ down do
    [] -> "."
    parts -> Path.join(parts)
  end
end
defp common_prefix_length(left, right) do
  left |> Enum.zip(right) |> Enum.take_while(fn {l, r} -> l == r end) |> length()
end
```
Copy the component-wise (`Path.split`) common-prefix body ONLY for the inside-project branch. It leaks `..` chains for outside paths, so it is not a redactor on its own. New code needed: canonicalize (a private bounded `File.read_link/1` component walker; Elixir has no realpath), the `<home>/...` branch via `System.user_home!()` (env `HOME` cannot fake it), and the `<outside project>` branch. `"remote " <> _` returns unchanged. Module header is `@moduledoc false`, helper is `@doc false` (existing style, e.g. `@doc false def local_mode_refusal` in `generator.ex:677`).

**Test the pure function** with `Path.join(System.user_home!(), "x/shell-pkg")`, a self-built `File.ln_s!` symlink (do not rely on `/var`), and `/proj` vs `/proj-evil`.

---

### `lib/crosswake/shell/ios_host_generation.ex` and `lib/mix/tasks/crosswake.gen.shell.ex` (service/task, request-response)

**Gate message** (`ios_host_generation.ex:94-101`): the `at #{location}` interpolation is the leak. Two call sites: `:121` passes `package.location` (redact), `:126-130` passes the literal `"the managed project"` (leave).
```elixir
{:error, found} -> {:error, shell_gate_message(route_id, command, package.location, found)}
```
Keep `shell_gate_message/4` signature (public `@doc false`, tests call it); redact in `shell_gate/2` before calling, with `Keyword.get(opts, :project_root, File.cwd!())` so existing callers redact by default. Note `render/2` reads opts with `Keyword.fetch(opts, :shell_package)` (`:20`); `shell_gate/2` must be passed the root.

**Task plumbing** (`gen.shell.ex:134-141`):
```elixir
render_opts = [generated_at: generated_at, shell_package: shell_package_context(managed_root, local_ios_package())]
case IOSHostGeneration.render(host_config, render_opts) do
  {:ok, outputs} -> outputs
  {:error, reason} -> Mix.raise(reason)
end
```
Add `project_root: File.cwd!()` to `render_opts`; the raise text is fixed by fixing the message.

---

### `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift` (service, request-response)

**Analog:** `grantHostCommands` declared branch (`:272-299`), reuse reason vocabulary; do not add reason strings.
```swift
guard let declared = route.hostCommands else {
    // D-28 legacy path: absent field keeps today's behavior, entry route only.
    guard let entryRouteID, route.id == entryRouteID else { return ([:], [:]) }
    var granted: [String: String] = [:]
    for (key, version) in request.capabilities where key.hasPrefix("host.") && registered.contains(key) { granted[key] = version }
    return (granted, [:])
}
...
if !seamOK { denials[command] = "seam_unsupported" }
else if !registered.contains(command) { denials[command] = "not_registered" }
else if !HostCommandSeam.supportsCommandVersion(version) { denials[command] = "version_unsupported" }
```
Replacement shape is in RESEARCH Pattern 1: iterate `route.capabilities where hasPrefix("host.")` giving `not_registered`; on the entry route also the request's `host.*` keys, `version_unsupported` if `!HostCommandSeam.supportsCommandVersion(version)`; return `([:], denials)`. The caller already strips `host.*` and routes denials through `recordHostCommandDenials` (`:589-596`, `:643-651`); the `loadAndFilterRequest` drop at `:704-709` is why declared names come from `route.capabilities`.

**Tests to flip red first:**
- `HostCommandNavigationTests.swift:95-116` `test_legacy_entry_route_keeps_its_registered_command_and_other_routes_get_nothing`: currently asserts `entry.capabilities[seamLessonCommand] == "1.0.0"` and `entry.hostCommandDenials == [:]`. Flip to no `host.*` capability and `hostCommandDenials == [seamLessonCommand: "not_registered"]`; push to review gives `[seamReviewCommand: "not_registered"]` (assertion style at `:85-91`: `XCTAssertEqual(b.hostCommandDenials, [seamReviewCommand: "not_registered"])`).
- `:118-128` extend with a denial assertion; add `version_unsupported` ("2.0.0") and `plain` (no diagnostics) cases using `SeamWorld.load(legacy: true)`, `SeamRecordingDelegate(registered:)`, `world.coordinator(entry:delegate:)`, `liveSession(...)`.
- `Phase180TwinFeasibilityTests.test_G3_control_exported_request_carrying_command_reaches_delegate`: skipped unless `PHASE180_EXPORT_DIR`; asserts `live.capabilities[command] == "1.0.0"` on a legacy manifest; rewrite so it is not stale when Phase 188 runs it.
- Pinned text that must NOT change (`HostCommandSeamTests.swift:326-332`): "Route \(seamLessonID) declared host command \(seamLessonCommand), but this app has not registered it."
- Independent truth: `Resources/host_command_seam_fixture.json` `legacy_manifest` (`lesson`, `review` have `host.*` in capabilities and no `host_commands`; `plain` has none).

Verify with `swift test --scratch-path <runs>/_swiftbuild_186_NN` from the package; baseline has 1 pre-existing G4 failure, so gate on the failing-test set.

---

### `script/verify_loopback_origin_simulator.sh` (script, event-driven)

**Analog:** itself. Trap body to harden (`:136-176`, excerpt `:155-175`):
```bash
if [[ -n "$UDID" && "$WE_BOOTED" == "1" ]]; then
  xcrun simctl shutdown "$UDID" >/dev/null 2>&1
  if xcrun simctl list devices 2>/dev/null | grep -F "$UDID" | grep -q "(Shutdown)"; then   # IN-02: pipefail + grep -q
    DEVICE_LEFT_AS_FOUND="true"
  else
    DEVICE_LEFT_AS_FOUND="false"
  fi
fi
[[ -n "$RUN" ]] && rm -rf "$RUN"
local json
json="$(emit_json)"
printf '%s\n' "$json"
if [[ -n "$EVIDENCE" ]]; then
  printf '%s\n' "$json" >"$EVIDENCE"        # WR-04: unchecked
fi
if [[ "$OUTCOME" == "passed" ]]; then exit 0; fi
exit "$FINAL_RC"
```
Changes (one concern each): variable-capture IN-02 fix (also `:354` `printf ... | grep -qx`); post-cleanup downgrade to `blocked`/rc 2/`LOOP-IOS-CLEANUP` set directly (never call `block`/`unavailable` inside the trap, they `exit`); temp write plus checked `mv` with `LOOP-IOS-EVIDENCE` and re-run `emit_json` so stdout agrees with the exit code; writable-evidence precheck before step 0 and resolve a relative `--evidence` before the `cd "$ROOT_DIR"` at `:180`; full-tree `find ... -print0 | LC_ALL=C sort -z | xargs -0 shasum -a 256` at three points replacing `owned_hashes` (`:251-262`); `/usr/libexec/PlistBuddy` (`:312`) to `plutil -extract CFBundleIdentifier raw -o - "$APP/Info.plist"`. The step-0 style to copy for guard calls: `block "LOOP-IOS-CANDIDATE-DIRTY" "..."` (`:180-186`), `unavailable "LOOP-IOS-TOOLCHAIN" "..."`.

---

### `test/crosswake/proof_lane/loopback_origin_harness_test.exs` (new; test, process)

**Analog:** `test/crosswake/proof_lane/ios_verifier_test.exs`.

**Setup** (`:6-33`):
```elixir
use ExUnit.Case, async: false
@script Path.expand("../../../script/verify_generated_ios_shell.sh", __DIR__)
setup do
  root = Path.join(System.tmp_dir!(), "ios-verifier-#{System.unique_integer([:positive])}")
  bin = Path.join(root, "bin")
  File.mkdir_p!(bin)
  ...
  on_exit(fn -> File.rm_rf!(root) end)
  %{root: root, bin: bin, project: project}
end
```
**Shim** (`:362-420`): bash file written to `bin` with a `case "${CROSSWAKE_IOS_SHIM_MODE:-success}" in ... esac` switch, argv tracing via `CROSSWAKE_IOS_XCODEBUILD_TRACE` using `printf '%q ' "$@" >> ...`. Run with `System.cmd("bash", [@script, ...], env: [{"PATH", bin <> ":" <> System.get_env("PATH")}, {"CROSSWAKE_IOS_SHIM_MODE", mode}], ...)`, assert exit status and `Jason.decode(String.trim(output))`.

Deviations required here: do NOT use `stderr_to_stdout: true` (harness logs to stderr; the single-JSON assertion needs clean stdout); run against a temp git repo clone holding copies of the script, `script/loopback_origin_simulator/*`, and a stub `packages/crosswake-shell-core-ios/Package.swift`, committed so `git status --porcelain` is empty; keep shim state, `TMPDIR`, and absolute `--evidence` outside the clone; shim `mix`, `xcrun`, `xcodebuild`, `plutil`, plus `shasum` (via `sha256sum`) when `System.find_executable("shasum")` is nil, and `mv` for the evidence-write failure. Each case changes one thing from the passing baseline (case table in RESEARCH Pattern 4). Assert `rule_ids` agrees with exit code; assert a non-empty case list.

---

### `test/crosswake/doctor/doctor_host_commands_test.exs` (rewrite and extend)

**Analog:** itself. Helpers to reuse unchanged: `managed_root(dir, router, pbx, mutate)` (`:27-39`, renders through `Crosswake.Manifest.render` so fixtures carry the key), `local_package(dir, version)` (`:41-52`), `findings(dir, router, root)` (`:54-64`, filters `check == "host_commands"`), `codes/1` (`:66`-ish sorted list). Setup uses `System.tmp_dir!()` plus `System.unique_integer` plus `on_exit(File.rm_rf!)`.

Rewrite required (they delete the key, which is now the legacy shape):
- `"a stale generated route is one error finding..."` (`:66-86`): change `mutate` to set `"host_commands" => %{"host.lesson.audio.play" => "1.1.0"}`.
- `"finding details only carry the allowed keys"` (`:126-146`): its `update_in(manifest, ["routes","lesson"], &Map.delete(&1, "host_commands"))` mutation now yields the legacy code; switch to a version mismatch and extend `@allowed_detail_keys` (`:7-14`) with `:route_ids`, `:reason`, `:error`. Keep the "codes/1 pins non-empty before the loop" comment idiom.
- New: legacy (key deleted) gives only `host_commands_legacy_manifest`, severity `:error` for `DeclaringRouter`; `:warning` for a non-declaring router. Unreadable: `File.rm!(fixture); File.mkdir_p!(fixture)` (eisdir, works as root). Malformed: `for` over 7 shapes with non-empty guard. route_missing: `update_in(manifest, ["routes"], &Map.delete(&1, "lesson"))`. Absent: `File.rm!` gives exactly `["host_commands_stale_skipped"]`, `:advisory`, and `refute` any `:error` in `host_commands`.

---

### `test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs` (LOOP-07 new cases)

**Analog:** itself. Run shape (`:48-63`):
```elixir
assert {:passed, %{device_class: "physical_iphone", assertions: assertions}} =
  PhysicalIphone.run_with(["--run", "--json"],
    ready_options() ++ [device_report: fn contract -> send(parent, {:device, contract}); device_report() end,
                        backend_report: fn _ -> backend_report() end, cleanup_run: fn -> send(parent, :cleanup_run); :ok end])
```
Readiness shape (`:23-44`): `{:readiness, %{outcome: "blocked", checks: checks}}` with check ids including `"PI-PREFLIGHT-CONFIG"`, each with `state`. `ready_options/0` (`:321-385`) sets `config.ios_shell_root: "/tmp/crosswake/native/ios"` and all host callbacks to passing. New cases append `ios_host: [...]` (local declaration) and `send(parent, :device_report_called)` in `device_report`, then `refute_received`. Add a production-declaration control that still passes. For case (b) build disk fixtures as `test/crosswake/doctor/doctor_origin_mode_test.exs` does: golden `test/fixtures/shell/ios/Info.plist.production.golden`, `elem(Mode.desired(production_plist(), :local_loopback), 1)` written to `CrosswakeShell/Info.plist` (helpers `production_plist/0`, `local_plist/0`, `:46-47`), `Fixtures/route_activation.json` with `{"origin":"http://127.0.0.1:4790"}`; dir setup `System.tmp_dir!()` plus `System.unique_integer` (`:40-48`).

**Fix analog (only if red):** `PhysicalIphonePreflight.config/1` (`:~110-116`) is the home (`readiness/1` and `check/1` both call it; maps to existing `{:config_error, _}` giving `PI-PREFLIGHT-CONFIG`, `:63`):
```elixir
defp config(options) do
  case Config.normalize(Keyword.get(options, :config)) do
    {:ok, config} -> {:ok, config}
    {:error, _} -> {:config_error, :invalid}
  end
end
```
Read the declaration with the `doctor.ex` `ios_host_origin_observation/2` idiom (`Keyword.get_lazy(opts, :ios_host, fn -> Application.get_env(:crosswake, :ios_host) end)`), `IOSHostOriginMode.observe(Path.join(config.ios_shell_root, "crosswake_shell"), declaration) != :none` gives `{:config_error, :local_loopback}`. Refusal text source: `Crosswake.ProofLane.Generator.local_mode_refusal/0` (`generator.ex:677-680`). Departure from D-17 wording (`run_with` vs `config/1`) is flagged as RESEARCH A5; planner to confirm.

---

### `test/crosswake/shell/path_redaction_test.exs` (new; test, transform)

**Analogs:** `ios_host_generation_host_commands_test.exs` (`IOSHostConfig` struct builder `config/2` at `:7-20`, `IOSHostGeneration.render(config, opts)`) for the gate; `crosswake_gen_shell_host_commands_test.exs:26-66` for the raised-text path (the `Application.put_env(:crosswake, :ios_host, ...)`, `File.cd!(target)` with `on_exit(File.cd!(cwd))`, `assert_raise Mix.Error` wrapping `ExUnit.CaptureIO.capture_io`) and the doctor test helpers for findings. Sentinel dir: `Path.join(System.tmp_dir!(), "SENTINEL-186-#{System.unique_integer([:positive])}")`. Assert both absence of sentinel and `System.user_home!()` AND presence of redacted forms (`shell-pkg`, `<outside project>`) so it cannot pass vacuously.

---

### Guide/changelog tests (`test/crosswake/guides/*`)

**Analog:** `host_command_seam_guide_test.exs`:
```elixir
defp flat(text), do: text |> String.split() |> Enum.join(" ")
defp guide(name), do: flat(File.read!(Path.join(["guides", name])))
test "..." do
  text = guide("native_shell_upgrade.md")
  for needle <- ["| New shell with an old manifest (before 1.2.0) |", "keeps working for the entry route only", ...] do
    assert text =~ needle, "native_shell_upgrade.md is missing: #{needle}"
  end
end
```
Flip the needle `"keeps working for the entry route only"` and the table row (`native_shell_upgrade.md:70-77`) together; add a compatibility.md test (`assert text =~ "denied with \`seam_unsupported\`"` and `refute text =~ "refuses to activate"`). CHANGELOG footgun: the existing `Regex.run(~r/\* \*\*Host-command seam[^\n]*/, changelog)` (`:41`) requires the new Unreleased bullet NOT start with `**Host-command seam`. For the harness paragraph needle copy `loopback_origin_guide_test.exs:6-20` (`guide/1` raw `File.read!`, `for needle`).

---

### `<runs>/mutate-186.sh` (batch)

**Analog:** `<runs>/mutate-185.sh` (present). Copy: header `set -u; umask 022`, `C=`/`RUNS=`/`M=` vars, `rsync -a --exclude .git "$C"/ "$M"/` into a throwaway copy with its own `MIX_BUILD_PATH`; helpers `touch_file`, `restore_all`, `sha`, `apply` (perl one-liner, requires `before != after`), `apply_whole_old`, `totals` (parse `N tests, M failures`), `has_header`, `harness_fail`, and `finish` (fails the harness if `rc==0`, `N<1` or `MF<1`, then checks each expected test name appears as a failure header). Add a Swift variant that runs `swift test --filter` and a bash-script variant for the harness controls. The 13 controls are listed in RESEARCH "Mutation controls".

---

## Shared Patterns

### Fail visibly, never score absence as success
**Apply to:** doctor stale check, harness cleanup/evidence/hash, LOOP-07. Source: Phase 184/185 carry-forward (CONTEXT). Every guard needs a red run before the fix, a recorded mutation control, and a test that asserts non-emptiness before looping (`doctor_host_commands_test.exs:140` comment idiom: `codes/1` pins the count so `for` is never empty).

### Doctor severities
**Source:** `lib/crosswake/doctor/check.ex:7-9`, `doctor.ex:2033`. `:advisory` for visible-skipped, `:warning` for non-declaring legacy, `:error` for stale/unreadable/malformed/route_missing/declaring legacy.

### Redaction rule
**Source:** new `ShellPackage.display_location/2`. Apply at print sites only (doctor message and `details.package_location`, `shell_gate_message`); `ShellPackage.resolve/1` keeps raw locations because tests compare them. Never `Path.relative_to/2` as a final answer, never `String.starts_with?` for containment, never return the input.

### Test sandbox idiom (Elixir)
**Source:** `doctor_host_commands_test.exs:17-25`: `System.tmp_dir!()` plus `System.unique_integer([:positive])`, `on_exit(fn -> File.rm_rf!(dir) end)`, `async: false`.

### Verification command style
**Source:** 185 gates. `MIX_BUILD_PATH=<runs>/_build_186_NN_test mix test <file> > <runs>/<name>.out 2>&1; echo $? > <runs>/<name>.exit`, then `test "$(cat ...exit)" = 0 && grep -Eq '^[1-9][0-9]* tests, 0 failures' <out>`. Never pipe a gating command into `tail`/`head`; no two mix runs share a `MIX_BUILD_PATH`; full suite runs with it unset and the failure set is `cmp`-ed against `<runs>/fix-185.failures`. Keep red outputs as `*-186-NN.red.out`.

### Tracked-source check
All named analogs are tracked in the candidate repo (verified `lib/crosswake/shell/shell_package.ex`; the others are standard `lib/`, `test/`, `script/`, `packages/` paths, none under a `.gsd/capabilities` mirror).

## No Analog Found

| File / piece | Role | Data Flow | Reason |
|---|---|---|---|
| symlink-resolving `canonical/1` inside `display_location/2` | utility | transform | No realpath in Elixir stdlib or the repo; write a small bounded `File.read_link/1` walker (about 15 lines) |
| Full-tree three-point hash comparison in the harness | script | transform | Existing `owned_hashes` covers four file groups only; new logic. Beware Xcode build side-writes (`xcuserdata/`, `project.xcworkspace/`), RESEARCH assumption A2, first exercised in Phase 188 |
| Evidence temp-file plus checked `mv` | script | file-I/O | No other script in `script/` does this; implement per RESEARCH Pattern 4 item 2 |

## Metadata

**Analog search scope:** `lib/crosswake/doctor`, `lib/crosswake/shell`, `lib/crosswake/proof_lane`, `lib/mix/tasks`, `test/crosswake/{doctor,shell,guides,proof_lane}`, `test/mix/tasks`, `script/`, Swift package sources and tests, run directory mutation script.
**Pattern extraction date:** 2026-10-16
**Privacy:** no home path, username, or adopter-identifying content recorded; the only path placeholder form used is `<runs>`.
