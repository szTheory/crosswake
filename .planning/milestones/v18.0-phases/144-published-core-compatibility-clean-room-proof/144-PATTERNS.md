# Phase 144: Published-Core Compatibility & Clean-Room Proof - Pattern Map

**Mapped:** 2026-07-07
**Files analyzed:** 8
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `script/verify_companion_cleanroom.sh` | utility/script | batch + file-I/O + request-response | `script/verify_companion_cleanroom.sh`; `script/guarded_hex_publish.sh` | exact + role-match |
| `script/check_release_workflow_integrity.exs` | utility/static scanner | file-I/O + transform | `script/check_release_workflow_integrity.exs` | exact |
| `test/crosswake/proof/phase142_release_integrity_test.exs` | test | file-I/O + transform | `test/crosswake/proof/phase142_release_integrity_test.exs` | exact |
| `lib/mix/tasks/crosswake.doctor.ex` | route/Mix task | request-response + transform | `lib/mix/tasks/crosswake.doctor.ex`; `lib/mix/tasks/crosswake.inspect.ex` | exact + role-match |
| `lib/crosswake/doctor/doctor.ex` | service/report aggregator | transform | `lib/crosswake/doctor/doctor.ex` | exact |
| `test/mix/tasks/crosswake_doctor_router_test.exs` | test | request-response + file-I/O | `test/mix/tasks/crosswake_doctor_test.exs`; `test/mix/tasks/crosswake_install_test.exs` | role-match |
| `script/guarded_hex_publish.sh` | utility/script reference | request-response + batch | `script/guarded_hex_publish.sh` | exact |
| `.github/workflows/release-please.yml` | config/workflow reference | event-driven + batch | `.github/workflows/release-please.yml` | exact |

## Pattern Assignments

### `script/verify_companion_cleanroom.sh` (utility/script, batch + file-I/O + request-response)

**Analog:** `script/verify_companion_cleanroom.sh` for clean-room host/profile flow; `script/guarded_hex_publish.sh` for package allowlist, semver validation, Hex JSON identity parsing, and `[crosswake]` failure copy.

**Strict Bash and repo-root pattern** (`script/verify_companion_cleanroom.sh` lines 48-78):

```bash
set -euo pipefail

PACKAGE="${1:-crosswake_rulestead}"
VERSION="${2:?}" # required: VERSION?: pass a semver string as \$2 (e.g. bash script/verify_companion_cleanroom.sh crosswake_rulestead 0.1.0)

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
PACKAGE_DIR="$REPO_ROOT/packages/$PACKAGE"
```

**Current local-floor anti-pattern to replace** (`script/verify_companion_cleanroom.sh` lines 80-86):

```bash
if [ -f "$PACKAGE_DIR/mix.exs" ]; then
  CORE_REQUIREMENT=$(grep -E 'do: \{:crosswake, "[^"]+"\}' "$PACKAGE_DIR/mix.exs" \
    | sed -E 's/.*do: \{:crosswake, "([^"]+)".*/\1/' \
    | head -1)
else
  CORE_REQUIREMENT="${CROSSWAKE_CORE_REQUIREMENT:-~> 0.2}"
fi
```

Replace that with a Hex release metadata parser. Local package `mix.exs` and docs stay drift guards, not release-proof authority.

**Copy allowlist + input validation style** (`script/guarded_hex_publish.sh` lines 63-120):

```bash
package_config() {
  case "$PACKAGE" in
    crosswake)
      WORKDIR="."
      VERSION_FILE="mix.exs"
      RELEASE_ENV=""
      TEST_CMD="mix test --exclude requires_example_host"
      PUBLISH_CMD="mix hex.publish --yes"
      ;;
    crosswake_rulestead)
      WORKDIR="packages/crosswake_rulestead"
      VERSION_FILE="packages/crosswake_rulestead/mix.exs"
      RELEASE_ENV="CROSSWAKE_RELEASE=1"
      TEST_CMD="mix test"
      PUBLISH_CMD="mix hex.publish --yes"
      ;;
    *)
      fail "unknown Hex package '${PACKAGE:-<empty>}'." "Choose one of: crosswake, crosswake_rulestead, crosswake_rindle, crosswake_sigra, crosswake_chimeway, crosswake_threadline."
      ;;
  esac
}

validate_inputs() {
  if [ -z "$PACKAGE" ]; then
    fail "PACKAGE is required as argument 1."
  fi

  if ! printf "%s" "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z._-]+)?$'; then
    fail "VERSION '${VERSION:-<empty>}' does not look like a valid semver string." "Pass the exact Release Please version output for ${PACKAGE}."
  fi
}
```

Phase 144 should use the same package-family allowlist before building URLs or generated `mix.exs` content. Include all five companion/observer packages.

**Copy Hex JSON identity parsing shape** (`script/guarded_hex_publish.sh` lines 137-165):

```bash
hex_release_state() {
  local body_file="$1"
  local code_file="$2"
  local url="https://hex.pm/api/packages/${PACKAGE}/releases/${VERSION}"
  local code

  code=$(curl -sS -o "$body_file" -w "%{http_code}" "$url" || true)
  printf "%s" "$code" > "$code_file"
}

live_release_version() {
  local body_file="$1"

  python3 - "$body_file" <<'PYEOF'
import json
import sys

try:
    with open(sys.argv[1], "r", encoding="utf-8") as handle:
        payload = json.load(handle)
except Exception:
    sys.exit(2)

version = payload.get("version")
if not isinstance(version, str):
    sys.exit(3)

print(version)
PYEOF
}
```

Extend this parser for `requirements.crosswake.requirement`, version mismatch, retirement/unusable release state, and missing field failures.

**Clean-room deps patching pattern** (`script/verify_companion_cleanroom.sh` lines 166-226):

```bash
if [ "$NO_ENGINE" = "1" ]; then
python3 - <<PYEOF
import re

with open("mix.exs", "r") as f:
    content = f.read()

deps_block = '''  defp deps do
    [
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.2"},
      {:crosswake, "${CORE_REQUIREMENT}"},
      {:${PACKAGE}, "${PACKAGE_REQUIREMENT}"}
    ]
  end'''
```

Keep this Python patching style. Change `CORE_REQUIREMENT` source to Hex metadata and keep `PACKAGE_REQUIREMENT="== ${VERSION}"`.

**Clean-room compile and router stub pattern** (`script/verify_companion_cleanroom.sh` lines 234-261):

```bash
echo "[crosswake] Step 3: mix deps.get..."
mix deps.get

echo "[crosswake] Step 3: mix compile --warnings-as-errors..."
mix compile --warnings-as-errors

echo "[crosswake] Step 4: writing minimal Phoenix router stub..."

mkdir -p lib/clean_room_host

cat > lib/clean_room_host/router.ex <<'ROUTEREOF'
defmodule CleanRoomHost.Router do
  use Phoenix.Router
  # minimal router stub — no routes required for doctor smoke (Open Question 1)
end
ROUTEREOF

mix compile
```

Keep the minimal `use Phoenix.Router` stub. For PREF-02, remove the later `mix run -e Code.ensure_loaded?` proof masking; the doctor command itself must load/compile it.

**Package-profile smoke patterns** (`script/verify_companion_cleanroom.sh` lines 292-353 and 354-398):

```bash
if [ "$PACKAGE" = "crosswake_threadline" ]; then
cat > test/smoke_test.exs <<SMOKEEOF
ExUnit.start()

defmodule CleanRoom.SmokeTest do
  use ExUnit.Case

  test "Threadline.Telemetry.event_names/0 returns 3 request-span events (canary: Telemetry shipped)" do
    events = Crosswake.Threadline.Telemetry.event_names()
    assert is_list(events) and length(events) == 3
  end

  test "crosswake_sigra and crosswake_chimeway are NOT installed (zero-sibling-dep mode)" do
    deps = Mix.Project.config()[:deps] || []
    dep_names = Enum.map(deps, fn
      {name, _} -> name
      {name, _, _} -> name
      dep when is_atom(dep) -> dep
      _ -> nil
    end)
    assert :crosswake_sigra not in dep_names
    assert :crosswake_chimeway not in dep_names
    assert dep_names != [], "[crosswake] dep_names must be non-empty (non-vacuity guard)"
  end
end
SMOKEEOF
elif [ "$PACKAGE" = "crosswake_chimeway" ]; then
cat > test/smoke_test.exs <<SMOKEEOF
ExUnit.start()

defmodule CleanRoom.SmokeTest do
  use ExUnit.Case

  alias ${COMPANION_MODULE}

  test "enabled?/1 defaults to true (chimeway enabled by default — no :enabled key required)" do
    assert ${COMPANION_MODULE_SUFFIX}.enabled?(%{})
  end
end
SMOKEEOF
```

Preserve package-specific smoke profiles. Do not flatten `rulestead`/`rindle` engine-present, `sigra`/`chimeway` no-engine, and `threadline` observer-zero-sibling behavior into one generic assertion.

**Doctor proof anti-pattern to remove** (`script/verify_companion_cleanroom.sh` lines 536-543):

```bash
echo "[crosswake] Step 7: running mix crosswake.doctor --router CleanRoomHost.Router..."

# Recompile to pick up config/runtime.exs changes and prove the router beam is loadable
# before invoking the doctor task in a fresh Mix process.
mix compile --force
mix run -e 'Code.ensure_loaded?(CleanRoomHost.Router) || raise "CleanRoomHost.Router was not loadable after compile"'

mix crosswake.doctor --router CleanRoomHost.Router
```

Keep a compile if needed for config/runtime changes, but the separate `mix run -e` pre-load must go away or become non-proof setup. The decisive proof is `mix crosswake.doctor --router CleanRoomHost.Router`.

---

### `script/check_release_workflow_integrity.exs` (utility/static scanner, file-I/O + transform)

**Analog:** `script/check_release_workflow_integrity.exs`

**Imports/constants pattern** (lines 1-18):

```elixir
#!/usr/bin/env elixir

defmodule Crosswake.ReleaseWorkflowIntegrity do
  @default_workflow ".github/workflows/release-please.yml"
  @default_recovery_workflow ".github/workflows/hex-publish.yml"
  @default_helper "script/guarded_hex_publish.sh"
  @default_release_config "release-please-config.json"
  @default_manifest ".release-please-manifest.json"
  @default_companion_root "packages"
  @components ~w(rulestead rindle sigra chimeway threadline)
  @hex_packages ~w(crosswake crosswake_rulestead crosswake_rindle crosswake_sigra crosswake_chimeway crosswake_threadline)
  @companion_floors %{
    "crosswake_rulestead" => "~> 0.1",
    "crosswake_rindle" => "~> 0.1",
    "crosswake_sigra" => "~> 0.2",
    "crosswake_chimeway" => "~> 0.2",
    "crosswake_threadline" => "~> 0.2"
  }
```

Add Phase 144 defaults for reading the clean-room script and doctor task by env override, mirroring existing env-driven fixture paths.

**Scanner run orchestration pattern** (lines 20-78):

```elixir
def run(argv \\ System.argv(), env_path \\ System.get_env("RELEASE_WORKFLOW_PATH")) do
  workflow_path = workflow_path(argv, env_path)
  workflow = File.read!(workflow_path)
  non_comment_workflow = strip_full_line_comments(workflow)
  jobs = job_blocks(workflow)
  recovery_workflow = File.read!(path_from_env("HEX_PUBLISH_WORKFLOW_PATH", @default_recovery_workflow))
  non_comment_recovery = strip_full_line_comments(recovery_workflow)
  helper = File.read!(path_from_env("GUARDED_HEX_PUBLISH_PATH", @default_helper))
  non_comment_helper = strip_full_line_comments(helper)

  checks =
    [
      concurrency_not_cancelled(non_comment_workflow),
      concurrency_queue_max(non_comment_workflow),
      no_true_cancellation(non_comment_workflow),
      paths_released(non_comment_workflow),
      aggregate_gate_absent(jobs),
      ios_proof_decoupled(jobs),
      android_proof_decoupled(jobs),
      mirror_token_preflight(jobs),
      cleanup_after_publish_and_proof(jobs)
    ] ++ component_gates(jobs) ++ component_proof_gates(jobs)
```

Append new `cleanroom_*` and `doctor_*` checks into this same `checks` list; do not create a second scanner.

**Comment-stripping and YAML-block parsing pattern** (lines 104-115):

```elixir
defp job_blocks(workflow) do
  ~r/(?ms)^  ([A-Za-z0-9_-]+):\n(.*?)(?=^  [A-Za-z0-9_-]+:\n|\z)/
  |> Regex.scan(workflow, capture: :all_but_first)
  |> Map.new(fn [name, block] -> {name, strip_full_line_comments(block)} end)
end

defp strip_full_line_comments(text) do
  text
  |> String.split("\n", trim: false)
  |> Enum.reject(&(String.trim_leading(&1) |> String.starts_with?("#")))
  |> Enum.join("\n")
end
```

Use this for Phase 144 checks so comment-only or step-text decoys cannot satisfy policy.

**Stable check helper pattern** (lines 169-174):

```elixir
defp check(id, true, detail), do: {:ok, id, detail}
defp check(id, false, detail), do: {:error, id, detail}

defp includes?(text, value) when is_binary(value), do: String.contains?(text, value)
defp includes?(text, %Regex{} = regex), do: Regex.match?(regex, text)
```

All new PREF-03 IDs should be stable strings from context, e.g. `release.cleanroom.hex_metadata_floor`, `release.cleanroom.exact_companion_pin`, `release.cleanroom.lockfile_postcondition`, `release.cleanroom.package_matrix_complete`, `release.doctor.app_config_requirement`, and `release.doctor.fresh_router_loaded`.

**Existing script-content check pattern** (lines 175-185):

```elixir
defp hex_publish_already_live_preflight(helper) do
  check(
    "release.hex_publish.already_live_preflight",
    includes?(helper, "https://hex.pm/api/packages/${PACKAGE}/releases/${VERSION}") and
      includes?(helper, "json.load") and
      includes?(helper, "seen_version") and
      includes?(helper, "[crosswake] OK:") and
      includes?(helper, "already live on Hex.pm; no publish attempted") and
      includes?(helper, "Continuing to proof"),
    "guarded Hex helper must parse exact Hex release JSON and report already-live package/version as success"
  )
end
```

Copy this style for clean-room script checks. For `release.cleanroom.hex_metadata_floor`, assert the script names `requirements.crosswake.requirement` and does not use the local `grep -E 'do: \{:crosswake` source as floor authority.

**Workflow gate patterns** (lines 490-524):

```elixir
defp component_gates(jobs) do
  for component <- @components do
    job = "publish-hex-#{component}"

    check(
      "release.#{component}.component_gate",
      job_if(jobs, job) == component_gate_expression(component),
      "#{job} must gate on #{component}_release_created, not aggregate releases_created; run elixir script/check_release_workflow_integrity.exs"
    )
  end
end

defp component_proof_gates(jobs) do
  for component <- @components do
    job = "clean-room-proof-#{component}"

    check(
      "release.#{component}.proof_gate",
      component_proof_after_publish?(jobs, component),
      "#{job} must gate on #{component}_release_created and need publish-hex-#{component}; run elixir script/check_release_workflow_integrity.exs"
    )
  end
end

defp component_proof_after_publish?(jobs, component) do
  job = "clean-room-proof-#{component}"

  job_if(jobs, job) == component_gate_expression(component) and
    job_needs?(jobs, job, "release-please") and
    job_needs?(jobs, job, "publish-hex-#{component}") and
    not includes?(job_if(jobs, job), "needs.release-please.outputs.releases_created")
end
```

Use `@components` for package-matrix completeness instead of hardcoding one-off checks.

---

### `test/crosswake/proof/phase142_release_integrity_test.exs` (test, file-I/O + transform)

**Analog:** `test/crosswake/proof/phase142_release_integrity_test.exs`

**Imports/constants/check-ID list pattern** (lines 11-31):

```elixir
use ExUnit.Case, async: true

@workflow ".github/workflows/release-please.yml"
@recovery_workflow ".github/workflows/hex-publish.yml"
@scanner "script/check_release_workflow_integrity.exs"
@cleanroom_script "script/verify_companion_cleanroom.sh"
@guarded_helper "script/guarded_hex_publish.sh"
@release_config "release-please-config.json"

@phase143_ids ~w(
  release.hex_publish.already_live_preflight
  release.hex_publish.no_replace
  release.hex_publish.shared_helper
  recovery.hex.component_input
)
```

Add `@phase144_ids` and a focused test that asserts scanner output includes each `OK` line.

**Positive scanner proof pattern** (lines 33-52):

```elixir
test "release workflow integrity script passes" do
  {output, exit_code} = run_scanner(@workflow)

  assert exit_code == 0, output
  assert output =~ "release.root_hex.path_gate"
  assert output =~ "release.concurrency.queue_max"
  assert output =~ "release.aggregate_gate.behavioral_jobs_absent"
  assert output =~ "release.cleanup.after_publish_and_proof"
end

@tag :phase143_auto_publish
test "phase 143 guarded auto publish scanner ids pass" do
  {output, exit_code} = run_scanner(@workflow)

  assert exit_code == 0, output

  for check_id <- @phase143_ids do
    assert output =~ "[crosswake] OK: #{check_id}"
  end
end
```

Use the same shape for `@tag :phase144_cleanroom`.

**Negative fixture mutation pattern** (lines 89-116 and 118-157):

```elixir
test "missing queue max fails with stable check id" do
  workflow =
    real_workflow()
    |> String.replace(~r/^\s+queue:\s*max\n/m, "")

  assert_failure!("release.concurrency.queue_max", workflow)
end

test "aggregate identity in a behavioral job fails with stable check id" do
  workflow =
    real_workflow()
    |> String.replace(
      "if: ${{ contains(fromJSON(needs.release-please.outputs.paths_released), '.') }}",
      "if: ${{ needs.release-please.outputs.releases_created == 'true' }}",
      global: false
    )

  assert_failure!("release.aggregate_gate.behavioral_jobs_absent", workflow)
end

test "inline comments and step text cannot satisfy path gates" do
  inline_comment_decoy =
    real_workflow()
    |> replace_in_job(
      "publish-hex",
      "if: ${{ contains(fromJSON(needs.release-please.outputs.paths_released), '.') }}",
      "if: ${{ false }} # contains(fromJSON(needs.release-please.outputs.paths_released), '.')"
    )

  assert_failure!("release.root_hex.path_gate", inline_comment_decoy)
end
```

Add negative fixtures for local-floor use, missing exact pin, missing lockfile postcondition, missing package family member, and doctor pre-load masking.

**Fixture env override pattern** (lines 353-405):

```elixir
defp assert_failure_with_fixtures!(check_id, fixtures) do
  {output, exit_code} = run_fixture_set(fixtures)

  assert exit_code == 1, output
  assert output =~ "[crosswake] FAIL: #{check_id}"
end

defp run_fixture_set(fixtures) do
  env =
    fixtures
    |> Enum.map(fn {name, contents} ->
      path =
        Path.join(
          System.tmp_dir!(),
          "crosswake-phase143-#{name}-#{System.unique_integer([:positive])}"
        )

      File.write!(path, contents)
      on_exit(fn -> File.rm(path) end)

      {fixture_env_name(name), path}
    end)

  run_scanner(@workflow, env)
end

defp fixture_env_name(:recovery_workflow), do: "HEX_PUBLISH_WORKFLOW_PATH"
defp fixture_env_name(:helper), do: "GUARDED_HEX_PUBLISH_PATH"
defp fixture_env_name(:release_config), do: "RELEASE_PLEASE_CONFIG_PATH"

defp run_scanner(path, env \\ []) do
  System.cmd("elixir", [@scanner, path], stderr_to_stdout: true, env: env)
end
```

Extend `fixture_env_name/1` for `:cleanroom_script` and `:doctor_task` if the scanner reads those paths.

---

### `lib/mix/tasks/crosswake.doctor.ex` (route/Mix task, request-response + transform)

**Analog:** `lib/mix/tasks/crosswake.doctor.ex`; secondary role-match `lib/mix/tasks/crosswake.inspect.ex`

**Mix task import/switch pattern** (`lib/mix/tasks/crosswake.doctor.ex` lines 1-21):

```elixir
defmodule Mix.Tasks.Crosswake.Doctor do
  use Mix.Task

  alias Crosswake.Doctor
  alias Crosswake.Doctor.Formatter
  alias Crosswake.Doctor.JSONFormatter

  @shortdoc "Diagnose Crosswake install, policy, manifest, and support truth"

  @switches [
    format: :string,
    router: :string,
    install_manifest: :string,
    native_checks: :boolean,
    check_publish: :boolean
  ]
```

Add `@requirements ["app.config"]` in this module. Do not use `app.start`; Phase 144 explicitly wants config/load readiness without booting endpoint/database/supervision.

**CLI parse + formatter pattern** (`lib/mix/tasks/crosswake.doctor.ex` lines 23-57):

```elixir
@impl Mix.Task
def run(args) do
  args = normalize_args(args)
  {check_publish?, args} = pop_flag(args, "--check-publish")
  {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

  if invalid != [] do
    Mix.raise("invalid options: #{inspect(invalid)}")
  end

  report =
    Doctor.run(
      route_source: router_module!(opts[:router]),
      install_manifest_path: opts[:install_manifest],
      check_native_tools?: opts[:native_checks],
      check_publish?: check_publish? or opts[:check_publish],
      cwd: File.cwd!()
    )

  output =
    case opts[:format] do
      nil -> Formatter.render(report)
      "human" -> Formatter.render(report)
      "json" -> JSONFormatter.render(report)
      other -> Mix.raise("unsupported format: #{inspect(other)}")
    end

  Mix.shell().info(output)

  if report.status == :error do
    Mix.raise("Crosswake doctor found blocking issues")
  end
end
```

Preserve the formatter/report separation. Router-loading errors should be clear before calling `Doctor.run/1`; report findings stay in `Crosswake.Doctor`.

**Current router loading pattern to harden** (`lib/mix/tasks/crosswake.doctor.ex` lines 82-109):

```elixir
defp router_module!(nil) do
  Mix.raise("pass --router Elixir.YourAppWeb.Router so doctor can compile Crosswake policy")
end

defp router_module!(name) when is_binary(name) do
  module = String.to_atom(name)

  if ensure_router_loaded?(module) do
    module
  else
    Mix.raise("router module #{name} is not available")
  end
end

defp ensure_router_loaded?(module) do
  router_compiled?(module) || compile_and_reload_router?(module)
end

defp compile_and_reload_router?(module) do
  Mix.Task.run("compile")
  router_compiled?(module)
rescue
  Mix.Error -> false
end

defp router_compiled?(module) do
  Code.ensure_compiled(module) == {:module, module}
end
```

Keep doctor-owned compile/load behavior, but distinguish:

- module unavailable after compile/config
- module loaded but not a Phoenix router
- valid fresh Phoenix router accepted

Use the existing compiler contract as the Phoenix-router boundary: `Crosswake.Policy.Compiler` calls `source.__routes__/0` for atom route sources.

**Router-source contract** (`lib/crosswake/policy/compiler.ex` lines 17-20 and 57-60):

```elixir
@spec compile(route_source(), keyword()) :: result()
def compile(source, opts \\ []) do
  routes = routes_from_source(source)
  source_module = source_module(source)
end

defp routes_from_source(source) when is_atom(source), do: source.__routes__()
defp routes_from_source(source) when is_list(source), do: source
defp source_module(source) when is_atom(source), do: source
defp source_module(_source), do: nil
```

For a non-router diagnostic, `function_exported?(module, :__routes__, 0)` is a practical local check before handing the module to `Doctor.run/1`.

**Secondary task analog** (`lib/mix/tasks/crosswake.inspect.ex` lines 19-41):

```elixir
@impl Mix.Task
def run(args) do
  {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

  if invalid != [] do
    Mix.raise("invalid options: #{inspect(invalid)}")
  end

  document =
    OperatorInspection.inspect(
      route_source: router_module!(opts[:router]),
      cwd: File.cwd!()
    )

  output =
    case opts[:format] do
      nil -> Formatter.render(document)
      "human" -> Formatter.render(document)
      "json" -> JSONFormatter.render(document)
      other -> Mix.raise("unsupported format: #{inspect(other)}")
    end

  Mix.shell().info(output)
end
```

This confirms the codebase's Mix task style: parse, validate, delegate, format, print.

---

### `lib/crosswake/doctor/doctor.ex` (service/report aggregator, transform)

**Analog:** `lib/crosswake/doctor/doctor.ex`

**Imports/report struct pattern** (lines 1-20 and 22-49):

```elixir
defmodule Crosswake.Doctor do
  @moduledoc """
  Host-truth-first diagnostics over install state, policy compilation, manifest truth,
  shell posture, bounded bridge posture, and support verification.
  """

  alias Crosswake.Doctor.Check
  alias Crosswake.Doctor.PublishReadiness
  alias Crosswake.Manifest
  alias Crosswake.Policy.Compiler
  alias Crosswake.Policy.Diagnostic

  defmodule Report do
    @moduledoc false

    defstruct [
      :status,
      :install_manifest,
      :manifest,
      shells: %{},
      bridge: %{},
      offline: %{},
      support: %{},
      commerce_summary: %{},
      publish_readiness: nil,
      findings: []
    ]
  end
end
```

Only touch this file if Phase 144 needs structured doctor findings for router-unavailable/non-router cases. Otherwise keep the router-load DX in the Mix task.

**Report aggregation pattern** (lines 128-188):

```elixir
@spec run(keyword()) :: Report.t()
def run(opts \\ []) do
  cwd = Keyword.get(opts, :cwd, File.cwd!())

  install_manifest_path =
    Path.expand(
      Keyword.get(opts, :install_manifest_path) || @default_install_manifest,
      cwd
    )

  {install_manifest, findings} = load_install_manifest(install_manifest_path)
  findings = findings ++ router_and_policy_findings(install_manifest, cwd)
  {manifest, findings} = compile_and_validate_manifest(findings, opts)

  publish_readiness = publish_readiness(manifest, opts, cwd)

  publish_findings =
    if publish_readiness, do: PublishReadiness.findings(publish_readiness), else: []

  findings = findings ++ publish_findings

  %Report{
    status: if(Enum.any?(findings, &(&1.severity == :error)), do: :error, else: :ok),
    install_manifest: install_manifest,
    manifest: manifest,
    findings: findings
  }
end
```

Preserve the pattern: gather findings, derive `status` from any `:error`, return a report.

**Finding construction style** (`lib/crosswake/doctor/doctor.ex` lines 217-260 and `lib/crosswake/doctor/check.ex` lines 1-18):

```elixir
check(
  :error,
  "install_manifest_invalid",
  "installer_state",
  "install manifest at #{path} is not valid JSON",
  Exception.message(error)
)
```

```elixir
defmodule Crosswake.Doctor.Check do
  @moduledoc """
  Structured doctor finding.
  """

  @enforce_keys [:severity, :code, :message, :check]
  defstruct [:severity, :code, :message, :hint, :check, details: %{}]
end
```

If router diagnostics move into `Doctor`, use stable `code`, `check`, `message`, `hint`, and `details` fields; do not print ad hoc text from deep service functions.

**Policy compile error pattern** (lines 340-396):

```elixir
defp compile_and_validate_manifest(findings, opts) do
  route_source = Keyword.get(opts, :route_source)
  warn_on_unmanaged? = Keyword.get(opts, :warn_on_unmanaged?, true)

  case Compiler.compile(route_source, warn_on_unmanaged?: warn_on_unmanaged?) do
    {:ok, %{warnings: warnings}} ->
      warning_findings =
        Enum.map(warnings, fn warning ->
          check(
            :warning,
            "unmanaged_routes",
            "policy_compile",
            warning.message,
            "decide whether unmanaged routes are intentionally outside Crosswake ownership"
          )
        end)

      case Manifest.compile(route_source, manifest_opts) do
        {:ok, %{manifest: manifest}} ->
          {manifest, findings ++ warning_findings ++ support_findings}

        {:error, %Diagnostic{errors: errors}} ->
          manifest_findings = Enum.map(errors, &manifest_compile_check/1)
          {nil, findings ++ warning_findings ++ manifest_findings}
      end

    {:error, %Diagnostic{errors: errors}} ->
      compile_findings =
        Enum.map(errors, fn error ->
          check(:error, "policy_compile_failed", "policy_compile", error.message, error.hint, %{
            key: error.key,
            route_id: error.route_id,
            path: error.path
          })
        end)

      {nil, findings ++ compile_findings}
  end
end
```

Router load/type failures should be distinct from `policy_compile_failed`; do not let a non-router crash become an opaque compiler failure.

---

### `test/mix/tasks/crosswake_doctor_router_test.exs` (test, request-response + file-I/O)

**Analog:** `test/mix/tasks/crosswake_doctor_test.exs`; secondary analogs `test/mix/tasks/crosswake_install_test.exs`, `test/mix/tasks/crosswake_gen_shell_diff_test.exs`

**Non-async Mix task test pattern** (`test/mix/tasks/crosswake_doctor_test.exs` lines 1-9):

```elixir
defmodule Mix.Tasks.Crosswake.DoctorTest do
  # async: false — this test changes the global process working directory via
  # File.cd!/2 while exercising the mix task.
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO
```

Use `async: false` for `crosswake_doctor_router_test.exs`; temp project tests will change cwd and Mix task state.

**Temp project/file setup pattern** (`test/mix/tasks/crosswake_doctor_test.exs` lines 40-82):

```elixir
setup do
  target =
    Path.join(System.tmp_dir!(), "crosswake-doctor-task-#{System.unique_integer([:positive])}")

  router_path = Path.join(target, "lib/demo_web/router.ex")
  policy_path = Path.join(target, "lib/demo_web/crosswake/policy.ex")
  install_manifest_path = Path.join(target, "priv/crosswake/install_manifest.json")

  File.mkdir_p!(Path.dirname(router_path))
  File.mkdir_p!(Path.dirname(policy_path))
  File.mkdir_p!(Path.dirname(install_manifest_path))

  File.write!(router_path, "...")
  File.write!(policy_path, "defmodule DemoWeb.Crosswake.Policy do\nend\n")
  File.write!(install_manifest_path, Jason.encode!(%{...}))

  %{target: target, install_manifest_path: install_manifest_path}
end
```

For fresh-router proof, create a temp Mix project or temp app tree, write `CleanRoomHost.Router` with `use Phoenix.Router`, then call the Mix task from that cwd.

**Task invocation and output capture pattern** (`test/mix/tasks/crosswake_doctor_test.exs` lines 90-104 and 219-229):

```elixir
output =
  capture_io(fn ->
    try do
      File.cd!(target, fn ->
        Mix.Tasks.Crosswake.Doctor.run([
          "--router",
          "Elixir.Crosswake.TestSupport.RouterFixtures.ManagedRouter",
          "--install-manifest",
          install_manifest_path
        ])
      end)
    rescue
      Mix.Error -> :ok
    end
  end)

assert output =~ "Crosswake doctor report"
```

```elixir
assert_raise Mix.Error, fn ->
  File.cd!(System.tmp_dir!(), fn ->
    Mix.Tasks.Crosswake.Doctor.run([
      "--router",
      "Elixir.Crosswake.TestSupport.RouterFixtures.ManagedRouter",
      "--install-manifest",
      "does-not-exist.json"
    ])
  end)
end
```

Use this for the three required cases: fresh router accepted, unavailable module, and loaded non-router module.

**Temp cleanup pattern** (`test/mix/tasks/crosswake_install_test.exs` lines 76-81 and `test/mix/tasks/crosswake_gen_shell_diff_test.exs` lines 44-80):

```elixir
defp tmp_dir!(prefix) do
  path = Path.join(System.tmp_dir!(), "#{prefix}-#{System.unique_integer([:positive])}")
  File.rm_rf!(path)
  File.mkdir_p!(path)
  path
end
```

```elixir
try do
  capture_io(fn ->
    Mix.Task.rerun(@gen_shell_task, ["android", "--target", tmp])
  end)
after
  File.rm_rf!(tmp)
end
```

Prefer `on_exit/1` or `try/after` cleanup for generated temp projects.

**Phoenix router fixture pattern** (`test/support/router_fixtures.ex` lines 48-60):

```elixir
defmodule Crosswake.TestSupport.RouterFixtures do
  defmodule ManagedRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :cached_read_only, security: :standard do
        get "/dashboard", Crosswake.TestSupport.PageController, :index,
          crosswake: [
            id: "dashboard",
            capabilities: ["app_info", "haptics", "permissions.status", "notification_token", "share"]
          ]
```

Use a minimal `use Phoenix.Router` module for the fresh-router acceptance case; use a plain `defmodule NotRouter do end` for the non-router rejection case.

---

### `script/guarded_hex_publish.sh` (utility/script reference, request-response + batch)

**Analog:** `script/guarded_hex_publish.sh`

This file is primarily a pattern source for Phase 144. Do not modify it unless planning discovers an actual PREF regression in publish identity behavior.

**Operator-copy pattern** (lines 29-60):

```bash
log() {
  echo "[crosswake] $*"
}

ok() {
  echo "[crosswake] OK: $*"
}

fail() {
  local message="$1"
  local next_action="${2:-Stop and inspect the package, version, release ref, and registry state before retrying.}"
  local url="https://hex.pm/packages/${PACKAGE:-unknown}/versions/${VERSION:-unknown}"

  echo "[crosswake] FAIL: ${message}"
  log "What to do next: ${next_action}"
  emit_outputs "failed" "$url"
  exit 1
}
```

Use this exact calm, technical failure style in `verify_companion_cleanroom.sh`: name package, version, derived floor, selected core version when known, and next safe action.

**Already-live / fail-closed registry handling** (lines 259-282):

```bash
case "$code" in
  200)
    if ! seen_version=$(live_release_version "$body_file"); then
      fail "Hex.pm returned 200 for ${PACKAGE} ${VERSION}, but JSON identity could not be parsed." "Inspect https://hex.pm/api/packages/${PACKAGE}/releases/${VERSION} before retrying."
    fi

    if [ "$seen_version" != "$VERSION" ]; then
      fail "Hex.pm returned ${seen_version} for ${PACKAGE}, not expected ${VERSION}." "Stop and inspect the package/version identity before continuing."
    fi

    ok "${PACKAGE} ${VERSION} is already live on Hex.pm; no publish attempted. Continuing to proof."
    ;;
  404)
    ok "${PACKAGE} ${VERSION} is not live on Hex.pm yet; publish is required for this released package."
    ;;
  *)
    fail "Hex.pm release preflight returned HTTP ${code} for ${PACKAGE} ${VERSION}." "Retry after confirming Hex.pm status; do not publish until registry identity can be checked."
    ;;
esac
```

For the clean-room proof script, `404` should fail closed because the proof runs after publish. Do not silently skip missing releases.

---

### `.github/workflows/release-please.yml` (config/workflow reference, event-driven + batch)

**Analog:** `.github/workflows/release-please.yml`

**Concurrency and Release Please output pattern** (lines 24-43 and 47-80):

```yaml
concurrency:
  group: release-please-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: false
  queue: max

jobs:
  release-please:
    outputs:
      releases_created: ${{ steps.release.outputs.releases_created }}
      paths_released: ${{ steps.release.outputs.paths_released || '[]' }}
      rulestead_release_created: ${{ steps.release.outputs['packages/crosswake_rulestead--release_created'] }}
      rulestead_tag_name: ${{ steps.release.outputs['packages/crosswake_rulestead--tag_name'] }}
      rulestead_version: ${{ steps.release.outputs['packages/crosswake_rulestead--version'] }}
      threadline_release_created: ${{ steps.release.outputs['packages/crosswake_threadline--release_created'] }}
      threadline_tag_name: ${{ steps.release.outputs['packages/crosswake_threadline--tag_name'] }}
      threadline_version: ${{ steps.release.outputs['packages/crosswake_threadline--version'] }}
```

PREF-03 scanner checks should keep protecting `queue: max`, `cancel-in-progress: false`, and per-component aliases.

**Thin publish job pattern** (lines 135-184):

```yaml
publish-hex-rulestead:
  name: Publish crosswake_rulestead to Hex.pm
  needs: release-please
  if: ${{ needs.release-please.outputs.rulestead_release_created == 'true' }}
  runs-on: ubuntu-latest
  env:
    CROSSWAKE_RELEASE: "1"
  steps:
    - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0
      with:
        ref: ${{ needs.release-please.outputs.rulestead_tag_name }}

    - name: Guarded Hex publish
      env:
        HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
      run: >
        bash script/guarded_hex_publish.sh
        crosswake_rulestead
        "${{ needs.release-please.outputs.rulestead_version }}"
        "${{ needs.release-please.outputs.rulestead_tag_name }}"
```

**Thin clean-room proof jobs** (lines 792-823, 824-861, 862-895, 896-933, 934-972):

```yaml
clean-room-proof-rulestead:
  name: Clean-room proof — crosswake_rulestead resolvability + doctor
  needs: [release-please, publish-hex-rulestead]
  if: ${{ needs.release-please.outputs.rulestead_release_created == 'true' }}
  runs-on: ubuntu-latest
  steps:
    - name: Run clean-room proof (D-16 — logic lives in script; YAML stays thin)
      run: >
        bash script/verify_companion_cleanroom.sh
        crosswake_rulestead
        "${{ needs.release-please.outputs.rulestead_version }}"

clean-room-proof-rindle:
  needs: [release-please, publish-hex-rindle]
  if: ${{ needs.release-please.outputs.rindle_release_created == 'true' }}
  steps:
    - name: Run clean-room proof (D-16 — logic lives in script; YAML stays thin)
      run: >
        bash script/verify_companion_cleanroom.sh
        crosswake_rindle
        "${{ needs.release-please.outputs.rindle_version }}"
        rindle
        Rindle

clean-room-proof-threadline:
  needs: [release-please, publish-hex-threadline]
  if: ${{ needs.release-please.outputs.threadline_release_created == 'true' }}
  steps:
    - name: Run clean-room proof (D-16 / T-139-11 — logic lives in script; YAML stays thin)
      run: >
        bash script/verify_companion_cleanroom.sh
        crosswake_threadline
        "${{ needs.release-please.outputs.threadline_version }}"
```

Keep YAML thin. Phase 144 behavior belongs in scripts and scanner tests, not repeated workflow inline logic.

## Shared Patterns

### Package Family Allowlist

**Source:** `script/check_release_workflow_integrity.exs` lines 10-18 and `script/guarded_hex_publish.sh` lines 63-110  
**Apply to:** clean-room script, scanner, workflow proof matrix, recovery helper checks

```elixir
@components ~w(rulestead rindle sigra chimeway threadline)
@hex_packages ~w(crosswake crosswake_rulestead crosswake_rindle crosswake_sigra crosswake_chimeway crosswake_threadline)
@companion_floors %{
  "crosswake_rulestead" => "~> 0.1",
  "crosswake_rindle" => "~> 0.1",
  "crosswake_sigra" => "~> 0.2",
  "crosswake_chimeway" => "~> 0.2",
  "crosswake_threadline" => "~> 0.2"
}
```

### Mixed Floor Truth

**Source:** `guides/companion_compatibility.md` lines 22-28 and package `mix.exs` `crosswake_dep/0` functions  
**Apply to:** clean-room proof, scanner matrix completeness, docs/status assertions

```markdown
| `crosswake_rulestead` | `:rulestead` | `0.1.0` | `~> 0.1` | `{:rulestead, "~> 0.1", optional: true}` |
| `crosswake_rindle` | `:rindle` | `0.1.0` | `~> 0.1` | `{:rindle, "~> 0.1", optional: true}` |
| `crosswake_sigra` | `:sigra` | `0.1.1` | `~> 0.2` | none (pure-Elixir auth machinery) |
| `crosswake_chimeway` | `:chimeway` | `0.1.0` | `~> 0.2` | none (pure-Elixir notification machinery) |
| `crosswake_threadline` | N/A (observer — not a `:companions` registrant) | `0.1.0` | `~> 0.2` | none |
```

### Drift Tests Prefer Stable IDs

**Source:** `test/support/proof_assertions.ex` lines 8-13 and `test/crosswake/proof/phase132_compat_matrix_drift_test.exs` lines 74-113  
**Apply to:** new Phase 144 release-integrity negative fixtures

```elixir
def stable_id_message(id, subject, source, observed, path, hint, posture) do
  """
  [#{id}] subject=#{subject} source=#{source} observed=#{observed} path=#{path} hint=#{hint} posture=#{posture}
  """
  |> String.trim()
end
```

### AST/Structured Parsing Over Grep For Source Semantics

**Source:** `test/crosswake/proof/phase132_compat_matrix_drift_test.exs` lines 224-263  
**Apply to:** tests that inspect Elixir source; avoid broad grep for release-truth floor

```elixir
defp extract_crosswake_requirement(mix_exs_path) do
  source = File.read!(mix_exs_path)
  {:ok, ast} = Code.string_to_quoted(source, [])

  {_ast, req} =
    Macro.prewalk(ast, nil, fn
      {:defp, _, [{:crosswake_dep, _, _}, [do: if_expr]]} = node, _acc ->
        {node, extract_hex_req_from_if(if_expr)}

      node, acc ->
        {node, acc}
    end)

  req
end
```

For the release proof itself, do not parse local package source as authority. Use Hex metadata and `mix.lock` postconditions.

### Doctor Findings Are Structured

**Source:** `lib/crosswake/doctor/check.ex` lines 1-18; formatters in `lib/crosswake/doctor/formatter.ex` and `lib/crosswake/doctor/json_formatter.ex`  
**Apply to:** any new doctor report behavior

```elixir
@enforce_keys [:severity, :code, :message, :check]
defstruct [:severity, :code, :message, :hint, :check, details: %{}]
```

### Release Status Is Adjacent, Not Primary Phase 144 Surface

**Source:** `lib/crosswake/release_status.ex` lines 173-180 and 435-442; `test/mix/tasks/crosswake_release_status_test.exs` lines 21-30 and 43-50  
**Apply to:** avoid false-positive status claims unless Phase 144 explicitly updates status after scanner proof

```elixir
check(
  :warning,
  "release.cleanroom_dependency_floor",
  "downstream clean-room dependency-floor evidence is present; PREF validation remains Phase 144",
  cleanroom_script_hardened?(cwd),
  "downstream clean-room dependency-floor evidence is missing; PREF validation remains Phase 144"
)
```

```elixir
script =~ "CORE_REQUIREMENT=" and
  script =~ "PACKAGE_REQUIREMENT=\"${PACKAGE_REQUIREMENT:-== ${VERSION}}\"" and
  script =~ "{:crosswake, \"${CORE_REQUIREMENT}\"}" and
  script =~ "{:${PACKAGE}, \"${PACKAGE_REQUIREMENT}\"}"
```

The research flags this as shallow. If touched, update the status tests so the command does not claim PREF completion before the stronger scanner IDs pass.

## No Analog Found

No primary Phase 144 file lacks a usable analog. If the planner splits clean-room script tests into a new optional `test/crosswake/proof/phase144_cleanroom_exactness_test.exs`, use `test/crosswake/proof/phase142_release_integrity_test.exs` as the direct analog for scanner fixtures and `test/support/proof_assertions.ex` for stable failure messages.

## Metadata

**Analog search scope:** `script/`, `lib/`, `test/`, `.github/workflows/`, `packages/`, `guides/`  
**Files scanned:** `rg --files script lib test .github packages guides` plus targeted `rg` for release/doctor/router terms  
**Pattern extraction date:** 2026-07-07  
**Local project skills:** no `.codex/skills/` or `.agents/skills/` directory exists in this repo  
**Primary phase inputs:** `144-CONTEXT.md`, `144-RESEARCH.md`, `144-VALIDATION.md`
