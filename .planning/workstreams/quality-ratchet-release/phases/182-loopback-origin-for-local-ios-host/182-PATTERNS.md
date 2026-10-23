# Phase 182: Loopback Origin for Local iOS Host - Pattern Map

**Mapped:** 2026-10-14
**Files analyzed:** 22 new/modified
**Analogs found:** 20 / 22
**Analog source:** `/private/tmp/crosswake-phase181-impl` (HEAD 12f84cd, clean; all analog paths below are git-tracked there, verified with `git ls-files`). Paths are repo-relative.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/crosswake/shell/ios_host_config.ex` (modify) | config/validator | request-response (validate) | itself: `valid_origin/1`, `normalize/1` | exact (extend) |
| `lib/crosswake/shell/ios_host_origin_mode.ex` (NEW) | utility (pure reconcile) | transform + file-I/O via ManagedOutputs | `lib/crosswake/shell/ios_host_project_migration.ex` + `ManagedOutputs.read/write_migration_project` | role-match |
| `lib/crosswake/shell/managed_outputs.ex` (modify: sibling `read/write_origin_plist`) | service | file-I/O | `read_migration_project/1`, `write_migration_project/3` (lines 14-51) | exact |
| `lib/crosswake/shell/ios_host_generation.ex` (modify: defense-in-depth) | service | transform | itself (`render/2`) | exact |
| `lib/mix/tasks/crosswake.gen.shell.ex` (modify) | mix task | file-I/O, batch | itself: `render_template/5`, `report_managed_check/3`, `report_project_migration/2` | exact |
| `priv/templates/crosswake/shell/ios/Info.plist.eex` (modify) | template | transform | itself (EEx end-of-line conditional) | exact |
| `lib/mix/tasks/crosswake.gen.proof_lane.ex` (modify) | mix task | request-response | itself: `load_host_config/1` (128-143) | exact |
| `lib/crosswake/proof_lane/generator.ex` (modify) | service | transform | itself: `normalize_host!/1` (677-686) | exact |
| `lib/crosswake/doctor/doctor.ex` (modify: `ios_host_origin_findings`) | service | request-response | `host_command_seam_findings/3` + `stale_host_command_findings/2` (2374-2420), `check/6` (2017) | exact |
| `lib/crosswake/doctor/publish_readiness.ex` (modify: conditional check) | service | request-response | `result_check/1`, `check/1`, `build_checks/4` (163-178, 926-966) | role-match |
| `lib/crosswake/doctor/formatter.ex` (modify, optional one line) | utility | transform | its own `status:` line | role-match |
| `lib/mix/tasks/crosswake.inspect.ex` (modify, human trailing line) | mix task | request-response | itself | role-match |
| `lib/crosswake/support_matrix/renderer.ex` (modify, ~line 137) | renderer | transform | itself | exact |
| `lib/crosswake/capability_map/renderer.ex` (modify, ~line 81) | renderer | transform | itself | exact |
| `guides/native_shell.md`, `guides/support_matrix.md`, `guides/capability_map.md`, `guides/native_shell_upgrade.md` | docs | transform | regenerate via `mix crosswake.docs.sync`; `test/crosswake/capability_map/renderer_test.exs:36-39` | exact |
| `test/crosswake/shell/ios_host_config_test.exs` (extend) | test | unit | itself (`@valid`, "canonicalizes valid authorities") | exact |
| `test/crosswake/shell/ios_host_origin_mode_test.exs` (NEW) | test | unit | `test/crosswake/shell/ios_host_migration_security_test.exs` (style) | role-match |
| `test/mix/tasks/crosswake_gen_shell_origin_mode_test.exs` (NEW) | test | integration | `test/mix/tasks/crosswake_gen_shell_host_commands_test.exs` (setup/restore, lines 1-16) | exact |
| `test/crosswake/doctor/doctor_origin_mode_test.exs` (NEW) | test | integration | `test/crosswake/doctor/doctor_host_commands_test.exs` | exact |
| `test/fixtures/shell/ios/Info.plist.production.golden` (NEW) | fixture | n/a | none (rendered from base template at 12f84cd) | no analog |
| `script/verify_loopback_origin_simulator.sh` (NEW) | harness script | event-driven (poll) | `script/verify_generated_ios_shell.sh` | role-match |
| `182-CANDIDATE-MOVE.json` (NEW, plain file) | record | batch | `180-CANDIDATE.json` + `180-SEAM-HANDOFF.json` (Phase 181 move precedent) | role-match |

## Pattern Assignments

### `lib/crosswake/shell/ios_host_config.ex` (config/validator, request-response)

**Analog:** itself, lines 1-114 at 12f84cd.

**Struct / key set** (lines 4-15). Add the optional key WITHOUT enforcing it (the pinned Phase 180 example test builds `%IOSHostConfig{}` with six keys):
```elixir
  @enforce_keys [:router, :origin, :entry_route_id, :app_bundle_id, :proof_app_bundle_id, :device_signing]
  defstruct @enforce_keys
  @keys @enforce_keys
```
Target shape: `defstruct @enforce_keys ++ [origin_mode: nil]`; strict-key check becomes "required exactly present, `:origin_mode` optional", keeping the substring `declaration keys` (asserted by `test/mix/tasks/crosswake_gen_shell_host_test.exs:403`).

**normalize arity** (lines 15-39): `normalize(input) when is_list` re-enters `normalize(Map.new(input))`; `normalize(input) when is_map` runs the `cond` key checks then `validate/1`. Make it `normalize(input, opts \\ [])` (keep arity-1 callers); add `env: Keyword.get(opts, :env, current_env())` where `current_env/0` returns `:prod` when Mix is absent (fail closed).

**Origin core to parameterize** (lines 63-114): the raw-authority cross-check is the anti `URI.parse` leniency control; keep it:
```elixir
    authority =
      case Regex.run(~r{\Ahttps://([^/?#]*)}i, origin, capture: :all_but_first) do
        [value] -> value
        _ -> nil
      end
    {authority_host, raw_port} =
      case authority && String.split(authority, ":", parts: 2) do
        [value] -> {String.downcase(value), nil}
        [value, port] -> {String.downcase(value), port}
        _ -> {nil, nil}
      end
    valid_port = case raw_port do
        nil -> true
        value -> Regex.match?(~r/\A[0-9]+\z/, value) and String.to_integer(value) in 1..65_535
      end
    ...
        canonical_port = if raw_port in [nil, "443"], do: "", else: ":#{String.to_integer(raw_port)}"
        {:ok, "https://#{host}#{canonical_port}"}
```
Local branch: same regex with `http`, exact `host in ["127.0.0.1", "localhost"]` after downcase, drop `"80"` instead of `"443"`, return `"http://#{host}#{port}"`. Check mode value and env FIRST (before origin), then origin. Error strings are the D-05 strings verbatim; never echo the supplied origin (existing test "rejects a malformed origin authority without echoing the supplied host"). Error style: `{:error, "invalid origin; use ..."}`. Keep the `rescue _ ->` fallback.

---

### `lib/crosswake/shell/ios_host_origin_mode.ex` (NEW, utility, transform + guarded file I/O)

**Analog:** `lib/crosswake/shell/ios_host_project_migration.ex` (`@moduledoc false`, pure `preview_contents/1` returning `{:ok, %{status:, contents:}}` or `error()`; recognize-before-rewrite; re-validate the rewritten bytes before returning).

**Shape to copy** (lines 1-16, 58-85): public pure preview functions; `migrate/2` rewrites by byte offsets, then re-parses and re-checks recognized shape; any failure falls to a single `error()`; `rescue _ -> error()`.
```elixir
defmodule Crosswake.Shell.IOSHostProjectMigration do
  @moduledoc false
  def preview_contents(contents), do: migrate(contents, spec(:shell))
  ...
      with {:ok, checked} <- PBXProject.parse(migrated),
           true <- recognized_graph?(checked, spec),
           true <- managed_settings?(checked["objects"], spec) do
        {:ok, %{status: :migration_required, contents: migrated}}
      else
        _ -> error()
      end
  rescue
    _ -> error()
```
For the new module: `block(:local_loopback)` (exact D-06 bytes), `desired(bytes, mode)` (strip exact block, insert after the `LSRequiresIPhoneOS` `<true/>` anchor only if it occurs exactly once), `inspect_plist(bytes)` returning mode/ATS-shape facts (any of `NSAppTransportSecurity`, `CrosswakeOriginMode`, `NSAllowsArbitraryLoads*`, `NSExceptionDomains` in a non-recognized shape => refuse), and error maps `%{cause:, repair:}`.

**Guarded I/O** (copy into `ManagedOutputs` as a sibling pair, `managed_outputs.ex` lines 14-51):
```elixir
  def read_migration_project(root) do
    with :ok <- safe_layout(root), :ok <- no_pending(root),
         :ok <- safe_components(root, "CrosswakeShell.xcodeproj"),
         {:ok, bytes} <- safe_read(root, "CrosswakeShell.xcodeproj/project.pbxproj") do
      {:ok, bytes}
    else
      {:error, :missing} -> error(:missing_project)
      {:error, :interrupted} -> error(:interrupted)
      _ -> error(:unsafe_path)
    end
  end
  def write_migration_project(root, expected, bytes) when is_binary(expected) and is_binary(bytes) and byte_size(bytes) <= @max_bytes do
    with :ok <- safe_layout(root), :ok <- no_pending(root), ...
         {:ok, current} <- safe_read(root, relative),
         true <- current == expected,
         :ok <- atomic_replace(root, relative, bytes) do
      :ok
    else
      false -> error(:conflict) ...
```
Do NOT extend `@paths` (three managed paths; `decode_outputs` requires `map_size(e) == 3`). Relative path for the new pair: `"CrosswakeShell/Info.plist"` (use `safe_components(root, "CrosswakeShell")`).

---

### `lib/mix/tasks/crosswake.gen.shell.ex` (mix task, file-I/O)

**Analog:** itself at 12f84cd.

**Facts**: `@ios_templates` line 62 (Info.plist at ~64); `ensure_file/2` lines 810-824 (create-only, returns `:reused` when file exists); `host_input = Application.get_env(:crosswake, :ios_host)` ~line 91; `generate_ios_shell/5` line 537 (calls `ensure_file(readme, shell_readme("ios"))` then `render_ios_templates(root, capabilities, local)`); `shell_readme/1` line 764 is the real README source (inline string, not `README.md.eex`).

**render_template/5** (628-643): add `origin_mode: nil` to the default assign list so every template and the legacy `--diff` path (`run_diff`, line 278) keep working:
```elixir
    EEx.eval_file(template,
      assigns: [capabilities: capabilities, local: local, version: version,
                template_version: @template_version,
                cutout_mode: String.contains?(relative_path, "/values-v28/")] ++ assigns)
```
Existing assigns merge by `++`, so passing `origin_mode: mode` in `assigns` for the Info.plist template overrides only that call. Do not bump `@template_version` (4); commit 12f84cd set that precedent.

**Reconcile call site:** after `render_ios_templates` inside `generate_ios_shell`, only when `host_config` is present, call the origin-mode reconcile both directions.

**--check reporting pattern** (lines 193-207) to copy for the mode drift line and the D-13 info line:
```elixir
  defp report_managed_check(root, desired, strict?) do
    case Crosswake.Shell.ManagedOutputs.check(root, desired) do
      {:ok, _result} -> Mix.shell().info("[crosswake] checked managed iOS outputs: current; cause: none; repair: none")
      {:error, %{cause: cause, repair: repair}} ->
        Mix.shell().info("[crosswake] checked managed iOS outputs: #{if(strict?, do: "blocked", else: "needs-attention")}; cause: #{cause}; repair: #{repair}")
        if strict?, do: Mix.raise("managed iOS outputs are #{cause}; #{repair}")
    end
  end
```
Mode mismatch: same line with `cause: origin mode changed; repair: rerun mix crosswake.gen.shell ios`. Local-mode info line is separate and never changes the freshness result.

**Bounded-rewrite reporting pattern** (`report_project_migration/2`, 209-237): `{:ok, bytes}` -> preview -> write with expected bytes -> `Mix.shell().info("[crosswake] ... applied ...; cause: ...; repair: ...")`, error -> `Mix.raise("[crosswake] ... blocked; cause: #{cause}; repair: #{repair}")`. `managed_failure/2` (257-268) is the template for `info_plist_conflict`.

---

### `priv/templates/crosswake/shell/ios/Info.plist.eex` (template)

**Analog:** itself. Insert after `LSRequiresIPhoneOS` using the end-of-line conditional (verified byte-identical in production by research):
```eex
    <key>LSRequiresIPhoneOS</key>
    <true/><%= if @origin_mode == :local_loopback do %>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsLocalNetworking</key>
        <true/>
    </dict>
    <key>CrosswakeOriginMode</key>
    <string>local_loopback</string><% end %>
    <key>UIApplicationSceneManifest</key>
```
Header comment "Host-owned after generation" stays. Capture the production golden from the BASE template before editing (Wave 0).

---

### `lib/mix/tasks/crosswake.gen.proof_lane.ex` and `lib/crosswake/proof_lane/generator.ex` (refusal)

**Analog:** themselves.

Task `load_host_config/1` (128-143): add the refusal after a successful normalize:
```elixir
          case IOSHostConfig.normalize(declaration) do
            {:ok, host_config} -> {:ok, host_config}
            {:error, reason} -> Mix.raise("IOS-HOST-CONFIG: #{reason}")
          end
```
Generator `normalize_host!/1` (677-686) is hit by `generate/2`, `check/2`, `diff/2`; library callers bypass the task, so raise there too:
```elixir
  defp normalize_host!(nil), do: nil
  defp normalize_host!(%IOSHostConfig{} = config), do: config      # <- refusal must apply here too
  defp normalize_host!(config) do
    case IOSHostConfig.normalize(config) do
      {:ok, normalized} -> normalized
      {:error, reason} -> raise ArgumentError, "invalid iOS host configuration: #{reason}"
    end
  end
```
Message (D-10): `physical proof lane refuses origin_mode :local_loopback; loopback reaches the device itself, so use the HTTPS production origin`. Note: `--config PATH` bypasses `:ios_host` (accepted limit).

---

### `lib/crosswake/doctor/doctor.ex` (service, request-response)

**Analog:** `host_command_seam_findings/3` (2374-2388) and `stale_host_command_findings/2`.

**Check constructor** (line 2017):
```elixir
  defp check(severity, code, check_name, message, hint, details \\ %{}) do
    %Check{severity: severity, code: code, check: check_name, message: message, hint: hint, details: details}
  end
```
**Gate pattern** (root guarded by `File.dir?`, reading generated fixtures defensively, `else _ -> []`):
```elixir
    root = shell_root(:ios, cwd, opts)
    if File.dir?(root) do ... else [] end
    ...
    with {:ok, bytes} <- File.read(Path.join(root, "Fixtures/crosswake_manifest.json")),
         {:ok, %{"routes" => generated}} when is_map(generated) <- Jason.decode(bytes) do ...
    else
      _ -> []
    end
```
Wire in `run/1` next to `host_command_findings = host_command_seam_findings(manifest, cwd, opts)` (line 164); publish findings merge at ~line 175 (`PublishReadiness.findings(publish_readiness)`). Existing Info.plist path read at lines 2340-2346 (`Path.join(ios_shell_root, "CrosswakeShell/Info.plist")`). Unreadable/missing plist must not assert production (D-08). Details map is strictly `%{origin:, mode:}`. Dedupe: with `check_publish` true emit only the `:error` form.

---

### `lib/crosswake/doctor/publish_readiness.ex` (conditional readiness check)

**Analog:** `check/1` and `result_check/1` (926-966), `build_checks/4` (163-178, list of 11 checks pinned by `test/fixtures/proof/phase52_publish_readiness.json`, `total_count: 11`).
```elixir
  defp result_check(opts) do
    passed? = Keyword.fetch!(opts, :passed?)
    check(Keyword.merge(opts, result: if(passed?, do: :pass, else: :fail),
        severity: if(passed?, do: :advisory, else: :error), blocking: not passed?))
  end
  defp check(opts) do
    %ReadinessCheck{id: ..., code: ..., category: ..., severity: ..., result: ..., blocking: ...,
      message: ..., hint: ..., docs_reference: ..., proof_class: ..., claim_scope: ..., details: ...}
```
Append the new check to `build_checks` ONLY when an iOS-host signal exists (so the 11-check fixture stays byte-identical). Use `category: :ios_host_origin`; `findings/1` derives `check: "ios_host_origin"`. PublishReadiness is a library-release profile (reads `mix.exs` name, CHANGELOG, template coordinates), not a host profile; record this in the plan.

---

### `lib/crosswake/support_matrix/renderer.ex` (~137) and `lib/crosswake/capability_map/renderer.ex` (~81)

**Analog:** the existing strings:
- support matrix: `"... declared entry route, HTTPS primary origin, app/proof identities, and device-signing settings. ..."`
- capability map: `"One ordinary `:crosswake, :ios_host` Mix declaration supplies the compiled router, entry route, HTTPS origin, ..."`

Keep "HTTPS primary origin"; append the `origin_mode: :local_loopback` sentence. Regenerate guides with `mix crosswake.docs.sync`; `capability_map/renderer_test.exs:36-39` asserts the guide is byte-identical to the renderer. Avoid forbidden phrases in `test/crosswake/guides/native_evidence_drift_test.exs:311-359` (`physical-device support`, `app-store readiness`, `local-development proof`, `screenshot proof`, `verified Android`).

---

### `test/crosswake/doctor/doctor_origin_mode_test.exs` (NEW)

**Analog:** `test/crosswake/doctor/doctor_host_commands_test.exs` (`async: false`, tmp dir setup, `Doctor.run(route_source:, install_manifest_path:, cwd:, ios_shell_root:)`, allowed-keys leak guard):
```elixir
  @allowed_detail_keys [:route_id, :commands, :platform, :package_location, :found_version, :required_version]
  setup do
    dir = Path.join(System.tmp_dir!(), "doctor-host-commands-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir); on_exit(fn -> File.rm_rf!(dir) end); %{dir: dir}
  end
  ...
      assert Map.keys(finding.details) -- @allowed_detail_keys == []
```
New file: `@allowed_detail_keys [:origin, :mode]`; paired HTTPS control (code absent); exactly one warning for local; `--check-publish` => `:error` and status `:not_ready`; mismatch cases `:error`; unreadable plist is not treated as production; leak guard (no entry URL, bundle id, team id).

### `test/mix/tasks/crosswake_gen_shell_origin_mode_test.exs` (NEW)

**Analog:** `test/mix/tasks/crosswake_gen_shell_host_commands_test.exs` setup (async: false, put/restore env):
```elixir
    previous = Application.get_env(:crosswake, :ios_host)
    on_exit(fn ->
      if previous, do: Application.put_env(:crosswake, :ios_host, previous), else: Application.delete_env(:crosswake, :ios_host)
      Mix.Task.reenable("crosswake.gen.shell")
    end)
```
Cover prod->local->prod round trip on the same target, host-edited plist refusal (file unchanged), README banner, `--check` line and drift.

### `test/crosswake/shell/ios_host_config_test.exs` (extend)

Validator matrix (table-driven) per RESEARCH LOOP-02 list; prod env via `normalize(input, env: :prod)`; assert errors never echo the supplied origin; assert a six-key struct literal still builds.

---

### `script/verify_loopback_origin_simulator.sh` (NEW harness)

**Analog:** `script/verify_generated_ios_shell.sh` (lines 34-48, 139-141, 166-185, 321-322, 365-375):
```bash
emit_proof_outcome() {
  printf '{"outcome":"%s","rule_id":"%s","scope":"%s"}\n' "$1" "$2" "$3"
}
if ! command -v "$XCODEBUILD" >/dev/null 2>&1; then
    emit_proof_outcome "unavailable" "PL-IOS-XCODEBUILD" "generated-proof-targets"; exit 3
fi
cleanup() { [[ -n "${RUN_ROOT}" ]] && rm -rf "${RUN_ROOT}"; return 0; }; trap cleanup EXIT
export GIT_CONFIG_COUNT=1
export GIT_CONFIG_KEY_0="url.${ios_core_clone}.insteadOf"
export GIT_CONFIG_VALUE_0="${ios_core_remote}"
run_xcodebuild -project "$project" -scheme "$scheme" -derivedDataPath "$DERIVED_DATA_ROOT" -clonedSourcePackagesDirPath "$IOS_SPM_CACHE" -showdestinations >"${destinations_capture}" 2>&1
xcrun simctl boot "$destination_id" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$destination_id" -b
xcrun simctl uninstall ... ; xcrun simctl install "$destination_id" "$app_path"
launch_output="$(xcrun simctl launch "$destination_id" "$BUNDLE_ID" 2>&1)"
```
Emit `passed|blocked|unavailable` with a `LOOP-IOS-*` rule id; missing Simulator = blocked/unavailable, never passed. Use a hermetic tag like `0.9.99` (not the real release tag, Pitfall 7); generate via the declared path (Pitfall 8); poll rather than sleep; `grep -a` for logs. Assertions per RESEARCH skeleton: built-bundle plist ATS keys == `[NSAllowsLocalNetworking]`, listener saw entry GET and `/__loaded` ping, `http://example.com/` still `-1022`; never assert that production plist cannot load loopback.

---

### `182-CANDIDATE-MOVE.json` and candidate move (LOOP-05)

**Analog:** `180-CANDIDATE.json` (`base_kind: "authorized_seam_rerun"`, `gate_base_head: 12f84cd9...`, `gate_base_tree: e51f069d...`, `source`, `isolation`, `remote_writes_authorized: false`) and `180-SEAM-HANDOFF.json` (`schema: "crosswake.phase180.seam_handoff/1"`, `source_repo`, `source_branch: phase181-impl`, `repaired_head`, `repaired_tree`, `authorized_paths[]`). New schema `crosswake.phase182.candidate_move/1` with fields from D-21. Do not edit `180-CANDIDATE.json`, `180-GATE.json`, `180-05-BLOCKED.md`, `180-ORIGIN-DECISION.json`.

Precheck commands to copy (RESEARCH "Candidate-move precheck"):
```bash
test "$(git -C $C180 rev-parse HEAD)" = 12f84cd950d4574921767df823faed6797c17c26
git -C $C182 diff --name-only 12f84cd9..HEAD | sort > "$S/core_paths"
git -C $C180 status --porcelain | cut -c4- | sort > "$S/dirty_paths"
test -z "$(comm -12 "$S/core_paths" "$S/dirty_paths")"
```
Never pipe a gate into `tail`; capture output to a file, test `$?`, then grep.

---

## Shared Patterns

### Fail-closed, repair-bearing messages
**Sources:** `ios_host_config.ex` (`{:error, "invalid <thing>; <repair>"}`), `crosswake.gen.shell.ex` (`cause: ...; repair: ...` lines).
**Apply to:** validator, reconcile, `--check`, doctor, proof-lane refusal. Every refusal states cause and repair; none echoes the supplied origin.

### Privacy of reports
**Source:** `doctor_host_commands_test.exs` `@allowed_detail_keys` leak guard.
**Apply to:** all doctor/inspect/`--check` output: print only canonical `scheme://host:port`; details keys exactly `[:origin, :mode]`.

### Absence is not production (D-08)
**Apply to:** doctor, `--check`, reconcile. Missing/unreadable plist with a declared mode is a mismatch/warning, never silent success. Every detector needs a missing/unreadable-input test.

### Safe file mutation
**Source:** `ManagedOutputs` `safe_layout`, `no_pending`, `safe_components`, `safe_read`, `atomic_replace`, expected-bytes compare. **Apply to:** the Info.plist reconcile only; never write outside it.

### Pinned-fixture avoidance
Do not enforce `origin_mode` in the struct; do not add an unconditional 12th readiness check; do not touch `README.md.eex`; do not create `twin_*`, `*verify_twin*`, `phase180_*` files or anything under `examples/phoenix_host/**`; do not change `@template_version`.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `test/fixtures/shell/ios/Info.plist.production.golden` | fixture | n/a | No Info.plist golden exists; render base `Info.plist.eex` at 12f84cd with fixed assigns (`version: "GOLDEN"`, `template_version: 4`, `capabilities: []`, `local: false`, `cutout_mode: false`) BEFORE editing the template |
| loopback listener (inside harness) | test helper | event-driven | No existing listener; use a 15-line `python3 -I` or `node:http` handler (no dependency) |

## Metadata

**Analog search scope:** `lib/crosswake/shell`, `lib/mix/tasks`, `lib/crosswake/doctor`, `lib/crosswake/proof_lane`, `priv/templates/crosswake/shell/ios`, `script/`, `test/crosswake/doctor`, `test/mix/tasks`, Phase 180 planning JSON.
**Files scanned:** ~25 (targeted reads and greps; large files read by line range).
**Pattern extraction date:** 2026-10-14
