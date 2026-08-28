# Phase 164: Dependency Security and Gate Authority - Pattern Map

**Mapped:** 2026-08-28
**Files classified:** 14 new or modified files
**Analogs found:** 13 / 14
**Scope:** `quality-ratchet-release` only; product runtime, Android, and the parked First B2C Adopter lane remain untouched

## File Classification

The table is the planner's working set. Files named later under **Reuse Boundaries** are authorities to consume unchanged, not additional implementation targets.

| New/Modified File | Change | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|---|
| `mix.lock` | modify | config | batch dependency resolution | `examples/phoenix_host/mix.lock` | exact-role |
| `examples/phoenix_host/mix.lock` | modify | config | batch dependency resolution | `mix.lock` | exact-role |
| `script/check_dependency_security.sh` | create | utility | batch + file-I/O | `script/check_required_checks_registered.sh` | role-match |
| `test/fixtures/security/advisory-bearing.lock` (exact name discretionary) | create | test fixture | file-I/O | none | no analog |
| `.github/workflows/dependency-security.yml` (exact name discretionary) | create | config | event-driven batch | `.github/workflows/requires-example-host-gate.yml` | exact-role |
| `script/list_merge_blocking_checks.py` | modify | utility | file-I/O transform | same file | exact |
| `script/check_required_checks_registered.sh` | modify | utility | request-response + transform | same file | exact |
| `script/check_exunit_ownership.exs` | create | utility | file-I/O transform | `script/list_merge_blocking_checks.py` | partial-role |
| `test/support/example_host.ex` | modify | utility | file-I/O + process lifecycle | same file | exact |
| `.github/workflows/requires-example-host-gate.yml` | modify after isolation proof | config | event-driven batch | same file | exact |
| `.github/workflows/aggregator-negative-control.yml` | modify | config | event-driven transform | same file | exact |
| `test/crosswake/proof/phase153_1_gate_integrity_test.exs` | modify | test | file-I/O + process | same file | exact |
| `test/crosswake/proof/phase134_native_gate_blocking_proof_test.exs` | modify | test | file-I/O transform | same file | exact |
| `test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs` | create | test | batch + file-I/O | `test/crosswake/proof/phase153_1_gate_integrity_test.exs` | role-match |

Potential tagged-test call-site edits are deliberately not predeclared. Change a caller of `Crosswake.TestSupport.ExampleHost` only if the chosen cleanup-token API or an isolation probe requires it. Do not turn Phase 164 into a broad rewrite of every `:requires_example_host` test.

## Pattern Assignments

### `mix.lock` and `examples/phoenix_host/mix.lock` (config, batch resolution)

**Analogs:** each supported lock is the other's sibling authority. Resolve them as a pair, but audit them independently.

**Public-range boundary — copy nothing into the manifests** (`mix.exs:47-58`, `examples/phoenix_host/mix.exs:86-100`):

```elixir
{:phoenix, "~> 1.8"},
{:phoenix_live_view, "~> 1.1"},

{:plug, "~> 1.16"},
{:bandit, "~> 1.0"},
```

**Current lock-entry shape** (`mix.lock:15-20`, `examples/phoenix_host/mix.lock:2,13,18-24`):

```elixir
"phoenix": {:hex, :phoenix, "1.8.7", ...},
"phoenix_live_view": {:hex, :phoenix_live_view, "1.1.30", ...},
"plug": {:hex, :plug, "1.19.1", ...},

"bandit": {:hex, :bandit, "1.12.0", ...},
"hpax": {:hex, :hpax, "1.0.3", ...},
"plug": {:hex, :plug, "1.19.2", ...},
```

**Apply:** produce canonical lock tuples through constrained Mix resolution, review the entire diff, and retain only resolver-required coherent changes. The research target set is Phoenix `1.8.13`, LiveView `1.1.33`, Plug `1.19.5`, Bandit `1.12.5`, and hpax `1.0.4`; live `mix hex.audit` and the constrained resolver remain the final authorities.

**Trap:** `~> 1.1` and `~> 1.16` admit later minors. Do not use an unconstrained refresh, manually synthesize checksums, change `mix.exs`, or refresh unrelated packages.

---

### `script/check_dependency_security.sh` (utility, batch + file-I/O)

**Analog:** `script/check_required_checks_registered.sh`

**Repository-root and fail-closed shell pattern** (`script/check_required_checks_registered.sh:18-25`):

```bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"
```

**Explicit non-pass pattern** (`script/check_required_checks_registered.sh:64-68`):

```bash
if ! current="$(gh api "${EP}" 2>/dev/null)"; then
  echo "[crosswake] UNVERIFIED (exit 3): cannot read branch protection for ${REPO}@${BRANCH}."
  echo "[crosswake]   Needs gh CLI authenticated with repo-admin scope. This is NOT a pass —"
  exit 3
fi
```

**Apply:** use one accumulator so the root and example audits both execute and any finding or tool error produces nonzero. Name the failing lock/project, affected package, and corrective command in concise output. Run the inactive fixture assertion separately from the two canonical audits so expected fixture failure cannot mask a real failure.

**Trap:** do not require Hex publishing credentials, print environment state, add an advisory allowlist, or wrap either real audit in `continue-on-error`.

---

### `test/fixtures/security/advisory-bearing.lock` (test fixture, file-I/O)

**Analog:** none close enough. Existing canonical locks are active authorities and must never become negative fixtures.

**Apply:** store the smallest inactive lock snapshot accepted by the audit seam and known to contain an advisory. Give the test an explicit fixture path override rather than copying the fixture onto either canonical path.

**Trap:** the fixture must contain no credentials, account/device identifiers, adopter data, raw payloads, or revealing links. Never commit a vulnerable version into `mix.lock` or `examples/phoenix_host/mix.lock` just to test CI.

---

### `.github/workflows/dependency-security.yml` (config, event-driven batch)

**Analog:** `.github/workflows/requires-example-host-gate.yml`

**Single literal producer pattern** (`.github/workflows/requires-example-host-gate.yml:43-50`):

```yaml
jobs:
  merge-blocking-requires-example-host:
    name: merge-blocking-requires-example-host
    runs-on: ubuntu-latest
    timeout-minutes: 25
    steps:
      - uses: actions/checkout@v7
```

**Toolchain and scoped working-directory pattern** (`.github/workflows/requires-example-host-gate.yml:52-70`):

```yaml
- uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93
  with:
    version-file: .tool-versions
    version-type: strict

- name: Compile the example Phoenix host (dev env)
  working-directory: examples/phoenix_host
```

**Actionable summary pattern** (`.github/workflows/requires-example-host-gate.yml:96-100`):

```yaml
- name: Step summary
  if: always()
  run: |
    echo "GATE-03 — executed the :requires_example_host tag (serial)." >> "$GITHUB_STEP_SUMMARY"
```

**Apply:** create exactly one literal job display name containing `merge-blocking`; that job directly runs the dependency-security script and its deterministic negative control. Keep the existing push/PR trigger posture; Phase 165 owns trigger consolidation.

**Trap:** do not add a sibling security leaf plus a same-named aggregator, dynamically construct the display name, register the new context in the same change, add caching/runner migration, or dump raw audit/environment output into summaries.

---

### `script/list_merge_blocking_checks.py` (utility, file-I/O transform)

**Analog:** extend the existing sole detector; do not create a second inventory.

**Current parser and record shape** (`script/list_merge_blocking_checks.py:56-86`):

```python
emitters_mode = "--emitters" in sys.argv[1:]
contexts = []
emitters = []
paths = sorted(glob.glob(".github/workflows/*.yml") + glob.glob(".github/workflows/*.yaml"))
for path in paths:
    with open(path) as f:
        doc = yaml.safe_load(f)

emitters.append((name, path, jid))

for name, path, jid in sorted(emitters):
    print(f"{name}\t{path}\t{jid}")
```

**Current fail-open branches to replace** (`script/list_merge_blocking_checks.py:61-80`):

```python
except Exception:
    continue
name = job.get("name") or jid
if "${{" in name:
    continue
```

**Apply:** retain PyYAML `safe_load`, both `.yml`/`.yaml` globs, deterministic ordering, and emitter provenance. Add a stable machine-readable/full-producer mode if needed by the checker. Malformed YAML, non-map `jobs`, authority-bearing unnamed jobs, and dynamic required context names must produce actionable nonzero diagnostics.

**Trap:** do not use regex YAML parsing, silently substitute a job id for an authority-bearing missing display name, or let the default de-duplicated view be the uniqueness authority.

---

### `script/check_required_checks_registered.sh` (utility, request-response + transform)

**Analog:** extend the same read-only auditor.

**Local-before-remote authority pattern** (`script/check_required_checks_registered.sh:40-68`):

```bash
dupes="$(python3 script/list_merge_blocking_checks.py --emitters \
  | awk -F'\t' '{c[$1]++; src[$1]=src[$1]"\n      - "$2" ("$3")"} END{for(n in c) if(c[n]>1) printf "%s%s\n", n, src[n]}')"

if [ -n "$dupes" ]; then
  echo "[crosswake] FAIL: duplicate-merge-blocking-name - one check name is emitted by more than one job."
  exit 1
fi

if ! current="$(gh api "${EP}" 2>/dev/null)"; then
  # exit 3 is UNVERIFIED, never success
  exit 3
fi
```

**Current one-directional comparison to extend** (`script/check_required_checks_registered.sh:71-82`):

```bash
registered="$(printf '%s' "$current" | jq -r '.checks[]?.context')"
missing=()
for c in "${DECLARED[@]}"; do
  printf '%s\n' "$registered" | grep -qxF "$c" || missing+=("$c")
done
```

**Apply:** preserve the pure-local uniqueness check before the credentialed read and bash 3.2-compatible array loops. Add the reverse assertion: every live registered context has exactly one literal producer in the full producer map, while every local `merge-blocking` candidate remains registered.

**Trap:** the live policy includes required names that do not contain `merge-blocking`; candidate-set equality is wrong. Compare registered contexts to the full literal producer inventory, and candidates to registration. Missing admin credentials remain exit `3`, not green.

---

### `script/check_exunit_ownership.exs` (utility, file-I/O transform)

**Analog:** partial only: `script/list_merge_blocking_checks.py` supplies the authority/diagnostic model; `test/test_helper.exs` supplies execution classes.

**Live exclusion authority** (`test/test_helper.exs:13-17,23-31,41-49`):

```elixir
exclude =
  []
  |> then(fn acc ->
    if System.get_env("MIX_INCLUDE_RULESTEAD") == "1", do: acc, else: [{:advisory_only, true} | acc]
  end)
  # ... :collateral_binaries and :engine_present ...
  |> then(fn acc ->
    if System.get_env("CROSSWAKE_INCLUDE_EXAMPLE_HOST") == "1",
      do: acc,
      else: [{:requires_example_host, true} | acc]
  end)

if exclude != [], do: ExUnit.configure(exclude: exclude)
```

**Dedicated class authority** (`.github/workflows/requires-example-host-gate.yml:77-94`):

```yaml
- name: Run the example-host-tagged suite
  env:
    MIX_ENV: test
  run: mix test --only requires_example_host --max-cases 1
```

**Apply:** parse `test/**/*_test.exs` as Elixir syntax and classify executable module/test tags against an explicit execution-class manifest. Report each unowned path, its effective exclusions, and one concrete remediation. Add fixtures where comments/strings mention a tag but executable syntax does not.

**Trap:** there is no close AST-detector analog in the repository. Do not copy the regex/string parsing used for simple workflow structural tests, use hard-coded test counts, or treat a lexical `requires_example_host` occurrence as ownership.

---

### `test/support/example_host.ex` (utility, resource lifecycle)

**Analog:** this file is the central seam to harden.

**Code-path acquisition boundary** (`test/support/example_host.ex:8-16`):

```elixir
@app_root
|> Path.join("_build/dev/lib/*/ebin")
|> Path.wildcard()
|> Enum.reject(&(Path.basename(Path.dirname(&1)) == "crosswake"))
|> Enum.each(&Code.prepend_path/1)
```

**Unique resource pattern and current leak** (`test/support/example_host.ex:34-45`):

```elixir
db =
  Path.join(System.tmp_dir!(), "cw_saas_proof_#{System.unique_integer([:positive])}.db")

Application.put_env(:crosswake_example, repo, database: db, pool_size: 1, log: false)

case apply(repo, :start_link, []) do
  {:ok, _pid} -> :ok
  {:error, {:already_started, _pid}} -> :ok
end
```

**Detached-global anti-pattern to replace** (`test/support/example_host.ex:103-117`):

```elixir
case apply(mod, fun, args) do
  {:ok, pid} ->
    Process.unlink(pid)
    :ok

  {:error, {:already_started, _pid}} ->
    :ok
end
```

**Apply:** snapshot every Application key with `Application.fetch_env/2`, register restoration immediately, and restore present values with `put_env` or absence with `delete_env`. Return/retain ownership tokens for newly prepended code paths, owned PIDs, and the unique database path; call `Code.delete_path/1`, stop only owned processes, and remove only the created file during cleanup.

**Trap:** `{:already_started, pid}` means the helper does not own that process. Never stop it. `get_env(..., default)` cannot distinguish an absent key from a key equal to the default. Never globally reset processes/config or leave `Process.unlink/1` as the lifetime strategy.

---

### `.github/workflows/requires-example-host-gate.yml` (config, event-driven batch)

**Analog:** preserve the lane's build split and stable producer.

**Load-bearing dev/test split** (`.github/workflows/requires-example-host-gate.yml:57-75`):

```yaml
- name: Compile the example Phoenix host (dev env)
  env:
    MIX_ENV: dev
  working-directory: examples/phoenix_host
  run: |
    mix deps.get
    mix compile

- name: Compile root project
  env:
    MIX_ENV: test
  run: mix compile
```

**Apply:** retain the job id/display name and dev build path. Replace stale fixed-count summary wording with live-derived paths/counts. Remove `--max-cases 1` only after the helper/call-site cleanup tests and a bounded fixed-seed matrix pass for the tagged class alone and for the complete suite.

**Trap:** a single parallel green run is not evidence. Do not add retries, exclusions, or permanent serialization; do not fold the workflow into another lane in Phase 164.

---

### `.github/workflows/aggregator-negative-control.yml` (config, event-driven transform)

**Analog:** extend the existing one-job synthetic-input harness.

**Synthetic result-arm pattern** (`.github/workflows/aggregator-negative-control.yml:46-65`):

```yaml
- name: alls-green must FAIL on a failed leaf result
  id: neg_fail
  continue-on-error: true
  uses: re-actors/alls-green@release/v1
  with:
    jobs: '{"synthetic-leaf": {"result": "failure"}}'

- name: alls-green must PASS on an all-green leaf result
  id: pos
  continue-on-error: true
  uses: re-actors/alls-green@release/v1
  with:
    jobs: '{"synthetic-leaf": {"result": "success"}}'
```

**Outcome assertion pattern** (`.github/workflows/aggregator-negative-control.yml:67-84`):

```yaml
- name: Assert alls-green rollup semantics
  env:
    NEG_FAIL: ${{ steps.neg_fail.outcome }}
    POS: ${{ steps.pos.outcome }}
  run: |
    set -euo pipefail
    rc=0
    [ "$NEG_FAIL" = "failure" ] || { echo "::error::BROKEN"; rc=1; }
    [ "$POS" = "success" ] || { echo "::error::BROKEN"; rc=1; }
    exit "$rc"
```

**Apply:** add cancelled, disallowed skipped, explicitly allowed skipped, unknown, and empty/missing synthetic arms. Keep intentional action failures step-local with `continue-on-error`, then assert every outcome in the final step. Only the explicitly irrelevant arm may use `allowed-skips`; never use `allowed-failures`.

**Trap:** GitHub `needs` itself emits only `success`, `failure`, `cancelled`, and `skipped`; `timed_out`, `action_required`, and `stale` belong at API/reporting boundaries and must be treated as non-success there. The direct missing-leaf contract also needs structural proof because a leaf absent from `needs` cannot appear in `toJSON(needs)`.

---

### `test/crosswake/proof/phase153_1_gate_integrity_test.exs` (test, file-I/O + process)

**Analog:** extend its real-tree assertion plus synthetic-tree negative controls.

**Command/output record pattern** (`test/crosswake/proof/phase153_1_gate_integrity_test.exs:16-28`):

```elixir
@discover "script/list_merge_blocking_checks.py"
@checker "script/check_required_checks_registered.sh"

{out, 0} = System.cmd("python3", [@discover, "--emitters"])

out
|> String.split("\n", trim: true)
|> Enum.map(fn line ->
  [name, path, jid] = String.split(line, "\t")
  %{name: name, path: path, job: jid}
end)
```

**Hermetic fixture-tree pattern** (`test/crosswake/proof/phase153_1_gate_integrity_test.exs:57-94`):

```elixir
@tag :tmp_dir
test "negative control: the uniqueness assertion fails on two jobs sharing a name", %{tmp_dir: tmp} do
  File.mkdir_p!(Path.join(tmp, "script"))
  File.mkdir_p!(Path.join(tmp, ".github/workflows"))
  File.cp!(@discover, Path.join(tmp, @discover))
  File.cp!(@checker, Path.join(tmp, @checker))

  {out, status} = System.cmd("bash", [@checker], cd: tmp, stderr_to_stdout: true)
  assert status == 1
  assert out =~ "duplicate-merge-blocking-name"
end
```

**Apply:** add malformed YAML, non-map jobs, unnamed/dynamic authority names, and registered-without-producer fixtures. Assert exit code, stable diagnostic, exact workflow/job source, and remediation. Preserve the bash 3.2 construct guard at lines 96-121.

**Trap:** do not make credentialed `gh` access a unit-test prerequisite. Inject/stub the registered-context input or isolate detector behavior so local negative controls remain hermetic.

---

### `test/crosswake/proof/phase134_native_gate_blocking_proof_test.exs` (test, file-I/O transform)

**Analog:** extend the existing aggregator structural parity helper.

**Scoped aggregator contract** (`test/crosswake/proof/phase134_native_gate_blocking_proof_test.exs:202-219`):

```elixir
case job_block(File.read!(file), aggregator) do
  nil ->
    ["aggregator job '#{aggregator}' not found in #{file}"]

  block ->
    # require if: always(), alls-green, and toJSON(needs)
    if_errors ++ alls_green_errors ++ missing_needs(block, leaves)
end
```

**Current subset-only logic to replace** (`test/crosswake/proof/phase134_native_gate_blocking_proof_test.exs:239-250`):

```elixir
case Enum.reject(leaves, &(&1 in declared)) do
  [] -> []
  missing -> ["needs: is missing #{inspect(missing)} (declared: #{inspect(declared)})"]
end
```

**Apply:** compare exact sets, reporting both missing and unexpected leaves, and add a direct fixture where one expected leaf is removed. Keep checks scoped to the named aggregator block and preserve the renamed/missing-job non-vacuity behavior.

**Trap:** this pure-Elixir parser supports the repository's single-line `needs: [a, b]` convention only. Either preserve that YAML form or deliberately replace the structural parser; do not silently broaden unsupported YAML syntax. Do not change Android jobs, runners, vectors, or proof claims while strengthening shared aggregator semantics.

---

### `test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs` (test, batch + file-I/O)

**Analog:** `test/crosswake/proof/phase153_1_gate_integrity_test.exs`

**Apply:** use `ExUnit.Case`, `@tag :tmp_dir`, repository script execution via `System.cmd/3`, and synthetic copied fixtures. Cover exact safe lock targets, unchanged manifest ranges, independent canonical audits, vulnerable-fixture rejection, exactly one security producer, ExUnit ownership positive/negative cases, and exact resource cleanup. Assert nonzero and actionable path/package output for every negative control.

**Trap:** keep this proof hermetic and privacy-safe. No network-only advisory lookup should be the sole negative control; no admin credentials; no adopter fixtures; no fixed repository test counts. If test responsibilities become too broad, split by contract but retain one phase-level entry point for the planner's focused command.

## Shared Patterns

### Stable names are governance contracts

**Sources:** `script/list_merge_blocking_checks.py:7-23`, `.github/workflows/requires-example-host-gate.yml:26-30`, `script/register_required_checks.sh:22-28`

Apply to every authority-bearing workflow job:

```yaml
jobs:
  merge-blocking-<purpose>:
    name: merge-blocking-<purpose>
```

The display name must be literal and have exactly one producer. Land it, observe it green on `main`, and only then use the existing green-first registrar. Registration remains a specific maintainer handoff; it is not an automated Phase 164 write.

### Local proof precedes credentialed governance reads

**Source:** `script/check_required_checks_registered.sh:40-68`

Duplicate/malformed/unnamed/dynamic producer checks and ExUnit ownership are repository-local and must run without GitHub administration authority. Branch-protection read failure remains visibly UNVERIFIED. Do not allow missing credentials to suppress the local checks.

### Negative controls prove non-vacuity

**Sources:** `test/crosswake/proof/phase153_1_gate_integrity_test.exs:57-94`, `.github/workflows/aggregator-negative-control.yml:46-84`

Every new detector needs both a known-bad fixture that fails and a known-good fixture that passes. Assert the path and remediation, not only the exit code. Expected fixture failures must be contained so the overall proof job is green only when the detector behaves correctly.

### Exact state restoration

**Source seam:** `test/support/example_host.ex:8-15,34-45,87-99,103-117`

Use the following shape for every Application key:

```elixir
before = Application.fetch_env(app, key)

on_exit(fn ->
  case before do
    {:ok, value} -> Application.put_env(app, key, value)
    :error -> Application.delete_env(app, key)
  end
end)

Application.put_env(app, key, temporary_value)
```

Register cleanup at the mutation boundary. Pair it with owned PID tokens, `Code.delete_path/1` for paths actually added, per-test unique files/databases, and deletion of only those resources.

### Required aggregators fail closed

**Sources:** `.github/workflows/contract-drift-gate.yml:105-115`, `test/crosswake/proof/phase134_native_gate_blocking_proof_test.exs:202-250`

```yaml
merge-blocking-contract-drift:
  name: merge-blocking-contract-drift
  if: always()
  needs: [guard-01-contract-drift-test, guard-02-generate-and-diff]
  steps:
    - uses: re-actors/alls-green@release/v1
      with:
        jobs: ${{ toJSON(needs) }}
```

The structural proof must establish exact leaf parity before the action checks result values. Only a leaf explicitly declared irrelevant may use visible neutral/`allowed-skips`.

### Actionable, bounded output

Gate output names the affected lock, workflow/job, or test path and one corrective command/action. Do not print environment dumps, credentials, tokens, raw answers/media/transcripts, stable device/account identifiers, offline mutation payloads, or any First B2C Adopter identifying detail.

## Reuse Boundaries and Traps

| Authority | Reuse boundary | Trap to avoid |
|---|---|---|
| `mix.exs`, `examples/phoenix_host/mix.exs` | Read compatibility ranges; keep unchanged unless a fixed release cannot resolve inside them | Compatibility-floor expansion or unrelated dependency refresh |
| `script/register_required_checks.sh` | Reuse green-first, idempotent, admin-only registration unchanged | Auto-registering the first producer run or adding a second admin client |
| `.github/workflows/required-checks-audit.yml` | Reuse scheduled credentialed audit/handoff semantics | Treating absent/expired PAT as success or moving local proof behind the credential gate |
| `test/test_helper.exs` | Treat live exclusions as execution-class authority | Hard-coded tag/file counts or substring-only classification |
| Existing three sibling aggregators | Preserve `if: always()` + exact `needs` + alls-green | Workflow consolidation, runner moves, cache/trigger changes (Phase 165) |
| Product runtime under `lib/` | No planned changes | Fixing only hypothetical runtime defects not demonstrated by isolation evidence |
| Android workflows/scripts/templates/vectors | Frozen; read only if needed to verify shared aggregator wiring | Android feature, parity, runner, device-proof, generator, Maven, JVM, or vector changes |
| `first-b2c-adopter-readiness` workstream and adopter artifacts | Parked and read-only | Activating adopter work, adding adopter-specific fixtures, or recording identity/revealing data |

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `test/fixtures/security/advisory-bearing.lock` | test fixture | file-I/O | No inactive vulnerable-lock snapshot exists; canonical locks must not be repurposed |

`script/check_exunit_ownership.exs` has only a partial analog. Reuse detector diagnostics and provenance, but derive its parser from Elixir syntax rather than copying existing regex/string structural checks.

## Metadata

**Analog search scope:** `mix.exs`, both lockfiles, `script/`, `.github/workflows/`, `test/test_helper.exs`, `test/support/`, and `test/crosswake/proof/`

**Strong analogs read:** 9 files; additional authorities inspected by targeted search

**Primary analog families:** required-context detector/auditor, merge-blocking workflow lane, example-host lifecycle, synthetic negative-control workflow, structural ExUnit proof

**Pattern extraction date:** 2026-08-28

**Scope stop:** no Phase 165 optimization, Phase 166 cleanup, Phase 167 reconciliation/docs refresh, Phase 168 publication, Android work, or First B2C Adopter activation belongs in this map.
