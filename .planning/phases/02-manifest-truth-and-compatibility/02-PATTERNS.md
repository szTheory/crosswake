# Phase 02: Manifest Truth And Compatibility - Pattern Map

**Mapped:** 2026-05-14
**Files analyzed:** 22
**Analogs found:** 22 / 22

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mix.exs` | config | request-response | `mix.exs` | exact |
| `lib/crosswake/manifest/manifest.ex` | service | request-response | `lib/crosswake/policy/compiler.ex` | role-match |
| `lib/crosswake/manifest/builder.ex` | service | transform | `lib/crosswake/policy/compiler.ex` | role-match |
| `lib/crosswake/manifest/serializer.ex` | service | file-I/O | `lib/crosswake/install/manifest.ex` | exact |
| `lib/crosswake/manifest/validator.ex` | service | transform | `lib/crosswake/policy/validator.ex` | exact |
| `lib/crosswake/manifest/types.ex` | model | transform | `lib/crosswake/policy/route.ex` | exact |
| `lib/crosswake/compatibility/compatibility.ex` | service | transform | `lib/crosswake/policy/validator.ex` | role-match |
| `lib/crosswake/compatibility/route_gate.ex` | service | transform | `lib/crosswake/policy/diagnostic.ex` | partial |
| `lib/crosswake/doctor/doctor.ex` | service | request-response | `lib/crosswake/policy/compiler.ex` | role-match |
| `lib/crosswake/doctor/check.ex` | model | transform | `lib/crosswake/policy/error.ex` | exact |
| `lib/crosswake/doctor/formatter.ex` | utility | transform | `lib/crosswake/policy/diagnostic.ex` | exact |
| `lib/crosswake/doctor/json_formatter.ex` | utility | transform | `lib/crosswake/install/manifest.ex` | role-match |
| `lib/crosswake/support_matrix/support_matrix.ex` | service | transform | `lib/crosswake/policy/route.ex` | partial |
| `lib/crosswake/support_matrix/renderer.ex` | utility | file-I/O | `lib/crosswake/install/manifest.ex` | role-match |
| `lib/mix/tasks/crosswake.doctor.ex` | config | request-response | `lib/mix/tasks/crosswake.install.ex` | exact |
| `test/support/router_fixtures.ex` | test | transform | `test/support/router_fixtures.ex` | exact |
| `test/crosswake/manifest/manifest_test.exs` | test | transform | `test/crosswake/policy/compiler_test.exs` | role-match |
| `test/crosswake/manifest/validator_test.exs` | test | transform | `test/crosswake/policy/compiler_test.exs` | role-match |
| `test/crosswake/compatibility/compatibility_test.exs` | test | transform | `test/crosswake/policy/compiler_test.exs` | partial |
| `test/crosswake/doctor/doctor_test.exs` | test | request-response | `test/crosswake/policy/compile_error_test.exs` | partial |
| `test/crosswake/support_matrix/support_matrix_test.exs` | test | transform | `test/crosswake/policy/compiler_test.exs` | partial |
| `test/mix/tasks/crosswake_doctor_test.exs` | test | request-response | `test/mix/tasks/crosswake_install_test.exs` | exact |

## Pattern Assignments

### `mix.exs` (config, request-response)

**Analog:** `mix.exs`

**Dependency pattern** ([mix.exs](/Users/jon/projects/crosswake/mix.exs:24), lines 24-30):
```elixir
defp deps do
  [
    {:nimble_options, "~> 1.1"},
    {:phoenix, "~> 1.8"},
    {:phoenix_live_view, "~> 1.1"}
  ]
end
```

Use the existing flat dependency list style. If Phase 2 adds `:jason`, add it here as one more explicit tuple rather than introducing env-specific logic or helper indirection.

### `lib/crosswake/manifest/manifest.ex` (service, request-response)

**Analog:** `lib/crosswake/policy/compiler.ex`

**Imports/result-shape pattern** ([compiler.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/compiler.ex:6), lines 6-18):
```elixir
alias Crosswake.Policy.Diagnostic
alias Crosswake.Policy.Error
alias Crosswake.Policy.Route
alias Crosswake.Policy.Validator
alias Crosswake.Policy.Warning

@type result ::
        {:ok, %{routes: [Route.t()], warnings: [term()]}}
        | {:error, Diagnostic.t()}
```

**Orchestration pattern** ([compiler.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/compiler.ex:18), lines 18-54):
```elixir
def compile(source, opts \\ []) do
  routes = routes_from_source(source)
  source_module = source_module(source)
  warnings = build_warnings(unmanaged_routes, source_module, opts)

  {compiled_routes, errors} =
    Enum.reduce(managed_routes, {[], []}, fn route, {compiled, compile_errors} ->
      case normalize_route(route) do
        {:ok, compiled_route} -> {[compiled_route | compiled], compile_errors}
        {:error, error} -> {compiled, [error | compile_errors]}
      end
    end)

  case errors do
    [] -> {:ok, %{routes: compiled_routes, warnings: warnings}}
    _errors -> {:error, Diagnostic.new(module: source_module, errors: errors, warnings: [])}
  end
end
```

Mirror this entrypoint shape for manifest compilation: accept compiler output or router source, build typed manifest data, run validation, and return either a typed success payload or a structured diagnostic payload.

### `lib/crosswake/manifest/builder.ex` (service, transform)

**Analog:** `lib/crosswake/policy/compiler.ex`

**Core transform pattern** ([compiler.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/compiler.ex:31), lines 31-45):
```elixir
{compiled_routes, errors} =
  Enum.reduce(managed_routes, {[], []}, fn route, {compiled, compile_errors} ->
    case normalize_route(route) do
      {:ok, compiled_route} -> {[compiled_route | compiled], compile_errors}
      {:error, error} -> {compiled, [error | compile_errors]}
    end
  end)

errors =
  errors
  |> Enum.reverse()
  |> Kernel.++(duplicate_id_errors(compiled_routes, managed_routes))
  |> Kernel.++(Validator.validate(compiled_routes, managed_routes))
```

Follow the same accumulate-then-validate pattern. Builder should assemble typed manifest structs from normalized `%Route{}` values first, then append derived compatibility/support data, then hand off to validators.

### `lib/crosswake/manifest/serializer.ex` (service, file-I/O)

**Analog:** `lib/crosswake/install/manifest.ex`

**File persistence pattern** ([install/manifest.ex](/Users/jon/projects/crosswake/lib/crosswake/install/manifest.ex:17), lines 17-38):
```elixir
@spec write(String.t(), map()) :: {:ok, action()}
def write(path, attrs) do
  File.mkdir_p!(Path.dirname(path))

  contents = render(attrs)

  case File.read(path) do
    {:ok, ^contents} -> {:ok, :reused}
    {:ok, _previous} -> File.write!(path, contents); {:ok, :updated}
    {:error, :enoent} -> File.write!(path, contents); {:ok, :created}
    {:error, reason} ->
      raise "could not persist Crosswake install manifest #{path}: #{:file.format_error(reason)}"
  end
end
```

**Deterministic render boundary** ([install/manifest.ex](/Users/jon/projects/crosswake/lib/crosswake/install/manifest.ex:40), lines 40-58):
```elixir
@spec render(map()) :: String.t()
def render(attrs) do
  render_template(
    Map.merge(attrs, %{
      files_json: json(Map.fetch!(attrs, :files)),
      markers_json: json(Map.fetch!(attrs, :markers))
    })
  )
end
```

Keep the same idempotent `write/2` contract. For Phase 2 the render implementation will likely move to `Jason.encode!/2`, but the planner should preserve the stable `:created | :reused | :updated` return semantics.

### `lib/crosswake/manifest/validator.ex` (service, transform)

**Analog:** `lib/crosswake/policy/validator.ex`

**Validation pipeline pattern** ([validator.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/validator.ex:27), lines 27-47):
```elixir
@spec validate([Route.t()], [map()]) :: [Error.t()]
def validate(routes, managed_routes) do
  routes
  |> Enum.zip(managed_routes)
  |> Enum.flat_map(fn {route, managed_route} ->
    route
    |> route_errors()
    |> Enum.map(&build_error(managed_route, route, &1))
  end)
end
```

**Per-rule error payload pattern** ([validator.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/validator.ex:49), lines 49-98):
```elixir
%{
  key: :offline,
  message: "offline_island routes cannot declare offline :unavailable",
  hint: "set offline: :cached_read_only or :local_first for offline_island routes"
}
```

Use one function per compatibility/support invariant and return operator-language messages plus hints. Do not collapse layered compatibility into a single boolean.

### `lib/crosswake/manifest/types.ex` (model, transform)

**Analog:** `lib/crosswake/policy/route.ex`

**Typed contract pattern** ([route.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/route.ex:9), lines 9-39):
```elixir
@enforce_keys [:id, :runtime]
defstruct [:id, :runtime, :security, offline: :unavailable, capabilities: [], packs: [], sync: []]

@type t :: %__MODULE__{
        id: String.t(),
        runtime: Schema.runtime(),
        offline: Schema.offline(),
        capabilities: [String.t()],
        packs: [String.t()],
        sync: [String.t()],
        security: Schema.security() | nil
      }
```

Define manifest top-level and nested structs the same way: explicit `defstruct`, explicit `@type`, small constructor functions, and defaults at the data boundary rather than ad hoc map merging throughout the pipeline.

### `lib/crosswake/compatibility/compatibility.ex` (service, transform)

**Analog:** `lib/crosswake/policy/validator.ex`

**Rule-by-rule function split** ([validator.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/validator.ex:38), lines 38-84):
```elixir
defp route_errors(route) do
  []
  |> validate_runtime_offline(route)
  |> validate_sync(route)
  |> validate_security(route)
  |> validate_capabilities(route)
end
```

Implement per-axis checks the same way: `validate_manifest_schema/2`, `validate_bridge_protocol/2`, `validate_native_runtime/2`, `validate_capabilities/2`, then aggregate findings.

### `lib/crosswake/compatibility/route_gate.ex` (service, transform)

**Analog:** `lib/crosswake/policy/diagnostic.ex`

**Operator-language explanation pattern** ([diagnostic.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/diagnostic.ex:43), lines 43-52):
```elixir
[
  "Route #{error.path || "(unknown path)"}#{route_id_suffix(error.route_id)}",
  context_line(error),
  "reason: #{error.message}",
  key_line(error.key),
  hint_line(error.hint)
]
```

Route-gate failures should keep this style: name the route, name the failed axis, and emit a concrete reason and hint. There is no exact route-gate analog yet, so combine `validator.ex` rule functions with this presentation style.

### `lib/crosswake/doctor/doctor.ex` (service, request-response)

**Analog:** `lib/crosswake/policy/compiler.ex`

**Structured orchestration pattern** ([compiler.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/compiler.ex:18), lines 18-54):
```elixir
def compile(source, opts \\ []) do
  ...
  case errors do
    [] ->
      emit_warnings(warnings, opts)
      {:ok, %{routes: compiled_routes, warnings: warnings}}

    _errors ->
      {:error, Diagnostic.new(module: source_module, errors: errors, warnings: [])}
  end
end
```

Doctor should follow the same pattern but across checks: collect install findings, compiler diagnostics, manifest validation findings, and support-matrix findings as structured data first; render later.

### `lib/crosswake/doctor/check.ex` (model, transform)

**Analog:** `lib/crosswake/policy/error.ex`

**Finding struct pattern** ([error.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/error.ex:6), lines 6-29):
```elixir
@enforce_keys [:message]
defstruct [
  :message,
  :hint,
  :key,
  :path,
  :helper,
  :verb,
  :route_id,
  :file,
  :line
]
```

Use an explicit struct for doctor findings as well. Replace route-local fields with doctor-specific ones like `:severity`, `:code`, `:details`, and `:check`, but preserve the explicit typed-payload approach.

### `lib/crosswake/doctor/formatter.ex` (utility, transform)

**Analog:** `lib/crosswake/policy/diagnostic.ex`

**Header/body formatting pattern** ([diagnostic.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/diagnostic.ex:25), lines 25-40):
```elixir
header = [
  "Crosswake route policy compilation failed",
  module_line(diagnostic.module),
  "found #{length(errors)} route policy error#{if length(errors) == 1, do: "", else: "s"}"
]

body =
  errors
  |> Enum.map(&format_error/1)
  |> Enum.join("\n\n")
```

Doctor terminal output should use the same deterministic sectioning and pluralization style. Severity grouping can be layered on top, but keep the formatter as a pure render function over structured checks.

### `lib/crosswake/doctor/json_formatter.ex` (utility, transform)

**Analog:** `lib/crosswake/install/manifest.ex`

**Structured serialization boundary** ([install/manifest.ex](/Users/jon/projects/crosswake/lib/crosswake/install/manifest.ex:50), lines 50-81):
```elixir
def json(value) when is_map(value) do
  value
  |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
  |> Enum.map(fn {key, nested} ->
    "#{json(to_string(key))}: #{json(nested)}"
  end)
  |> Enum.join(", ")
  |> then(&"{#{&1}}")
end
```

Keep JSON formatting stable and deterministic. The implementation should probably use `Jason`, but the planner should preserve the current repo expectation that machine-readable output has predictable key ordering and no string scraping.

### `lib/crosswake/support_matrix/support_matrix.ex` (service, transform)

**Analog:** `lib/crosswake/policy/route.ex`

**Typed canonical-data pattern** ([route.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/route.ex:12), lines 12-20):
```elixir
@type t :: %__MODULE__{
        id: String.t(),
        runtime: Schema.runtime(),
        offline: Schema.offline(),
        capabilities: [String.t()],
        packs: [String.t()],
        sync: [String.t()],
        security: Schema.security() | nil
      }
```

There is no direct support-matrix module yet. Treat this as a new canonical-data module with typed structs and narrow constructors, not an inline docs table.

### `lib/crosswake/support_matrix/renderer.ex` (utility, file-I/O)

**Analog:** `lib/crosswake/install/manifest.ex`

**Artifact writer pattern** ([install/manifest.ex](/Users/jon/projects/crosswake/lib/crosswake/install/manifest.ex:17), lines 17-38):
```elixir
case File.read(path) do
  {:ok, ^contents} -> {:ok, :reused}
  {:ok, _previous} -> File.write!(path, contents); {:ok, :updated}
  {:error, :enoent} -> File.write!(path, contents); {:ok, :created}
end
```

Use the same write contract for generated support-matrix JSON/Markdown so docs drift checks can assert whether generated artifacts changed.

### `lib/mix/tasks/crosswake.doctor.ex` (config, request-response)

**Analog:** `lib/mix/tasks/crosswake.install.ex`

**CLI parsing pattern** ([crosswake.install.ex](/Users/jon/projects/crosswake/lib/mix/tasks/crosswake.install.ex:14), lines 14-30):
```elixir
@switches [
  target: :string,
  router: :string,
  web_module: :string,
  policy_module: :string,
  manifest_path: :string
]

{opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

if invalid != [] do
  Mix.raise("invalid options: #{inspect(invalid)}")
end
```

**Task summary pattern** ([crosswake.install.ex](/Users/jon/projects/crosswake/lib/mix/tasks/crosswake.install.ex:62), lines 62-67):
```elixir
Mix.shell().info("""
Crosswake install complete for #{Path.basename(target)}
  router: #{Path.relative_to(router_path, target)} (#{format_router_actions(router_result.actions)})
  policy module: #{Path.relative_to(policy_path, target)} (#{policy_action})
  install manifest: #{Path.relative_to(manifest_path, target)} (#{manifest_action})
""")
```

`mix crosswake.doctor` should follow the same task shape: parse strict switches, delegate real work to library modules, then print one deterministic summary. Add `--format json` in the same task rather than creating a parallel CLI surface.

### `test/support/router_fixtures.ex` (test, transform)

**Analog:** `test/support/router_fixtures.ex`

**Fixture richness pattern** ([router_fixtures.ex](/Users/jon/projects/crosswake/test/support/router_fixtures.ex:40), lines 40-100):
```elixir
defmodule ManagedRouter do
  use Crosswake.Router

  scope "/" do
    crosswake_defaults runtime: :live_view, offline: :cached_read_only, security: :standard do
      get "/dashboard", ...
      live "/library", ..., crosswake: [id: "library", runtime: :offline_island, sync: [:journal]]
      live "/camera", ..., crosswake: [id: "camera", runtime: :native_screen, capabilities: [:camera], security: :sensitive]
    end
  end
end
```

Extend these fixtures instead of inventing new test-only routers elsewhere. Add manifest/compatibility-support cases here so compiler, manifest, and doctor tests all share one route truth source.

### `test/crosswake/manifest/manifest_test.exs` (test, transform)

**Analog:** `test/crosswake/policy/compiler_test.exs`

**End-to-end contract test pattern** ([compiler_test.exs](/Users/jon/projects/crosswake/test/crosswake/policy/compiler_test.exs:8), lines 8-17):
```elixir
test "valid routes across all three public runtimes compile into normalized policy output" do
  assert {:ok, %{routes: routes, warnings: []}} = Compiler.compile(ManagedRouter)

  assert Enum.map(routes, &{&1.id, &1.runtime}) == [
           {"dashboard", :live_view},
           {"library", :offline_island},
           {"camera", :native_screen}
         ]
end
```

Model manifest tests the same way: assert full typed output shape from a fixture router, then assert key contract fragments rather than isolated helper internals only.

### `test/crosswake/manifest/validator_test.exs` (test, transform)

**Analog:** `test/crosswake/policy/compiler_test.exs`

**Negative-path aggregation pattern** ([compiler_test.exs](/Users/jon/projects/crosswake/test/crosswake/policy/compiler_test.exs:19), lines 19-36):
```elixir
assert {:error, %{errors: errors, warnings: []}} = Compiler.compile(routes)

assert Enum.any?(errors, &String.contains?(&1.message, "duplicate id"))
assert Enum.any?(errors, &String.contains?(&1.message, "required :runtime"))
assert Enum.any?(errors, &String.contains?(&1.message, "invalid value for :offline"))
```

Use the same style for schema-version, bridge-version, runtime-version, origin, capability, and support-matrix failures.

### `test/crosswake/compatibility/compatibility_test.exs` (test, transform)

**Analog:** `test/crosswake/policy/compiler_test.exs`

**Rule-oriented assertions** ([compiler_test.exs](/Users/jon/projects/crosswake/test/crosswake/policy/compiler_test.exs:39), lines 39-77):
```elixir
assert {:error, %{errors: errors}} = Compiler.compile(routes)

assert Enum.any?(errors, &String.contains?(&1.message, "live_view routes cannot declare offline :local_first"))
assert Enum.any?(errors, &String.contains?(&1.message, "offline_island routes cannot declare offline :unavailable"))
assert Enum.any?(errors, &String.contains?(&1.message, "sync declarations require offline support"))
```

Compatibility tests should stay focused on one failed axis per assertion and one fully valid route/runtime example at the end.

### `test/crosswake/doctor/doctor_test.exs` (test, request-response)

**Analog:** `test/crosswake/policy/compile_error_test.exs`

**Structured finding + formatted-output pattern** ([compile_error_test.exs](/Users/jon/projects/crosswake/test/crosswake/policy/compile_error_test.exs:17), lines 17-29):
```elixir
assert {:error, diagnostic} = Compiler.compile(routes)

assert %Diagnostic{errors: [%Error{} = error]} = diagnostic
assert error.path == "/adapter"
assert error.helper == "camera"

formatted = Diagnostic.format(diagnostic)
assert formatted =~ "Route /adapter"
assert formatted =~ "helper: camera"
```

Doctor service tests should assert both the structured findings and the human-readable formatter output from the same underlying payload.

### `test/crosswake/support_matrix/support_matrix_test.exs` (test, transform)

**Analog:** `test/crosswake/policy/compiler_test.exs`

Use the same fixture-driven, exact-fragment assertion style as the compiler tests. There is no existing support-matrix test analog, so keep the tests focused on generated support truth and drift detection rather than prose-heavy docs snapshots.

### `test/mix/tasks/crosswake_doctor_test.exs` (test, request-response)

**Analog:** `test/mix/tasks/crosswake_install_test.exs`

**CaptureIO task test pattern** ([crosswake_install_test.exs](/Users/jon/projects/crosswake/test/mix/tasks/crosswake_install_test.exs:32), lines 32-72):
```elixir
output =
  capture_io(fn ->
    Mix.Task.reenable(@task)
    Mix.Task.run(@task, ["--target", target])
  end)

assert output =~ "install manifest"

output =
  capture_io(fn ->
    Mix.Task.reenable(@task)
    Mix.Task.run(@task, ["--target", target])
  end)

assert File.read!(manifest_path) == manifest_contents
```

Copy this structure for doctor task tests: create temp host state, run once for human output, run again for idempotence, then assert exit-driving failures only come from blocking checks. Add a separate JSON-mode assertion rather than mixing formats in one test.

## Shared Patterns

### Typed Contract Modules
**Source:** [lib/crosswake/policy/route.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/route.ex:9)
**Apply to:** `manifest/types.ex`, `doctor/check.ex`, `support_matrix/support_matrix.ex`
```elixir
@enforce_keys [:id, :runtime]
defstruct [:id, :runtime, :security, offline: :unavailable, capabilities: [], packs: [], sync: []]

@spec new(keyword()) :: {:ok, t()} | {:error, NimbleOptions.ValidationError.t()}
def new(options) when is_list(options) do
  options
  |> merged_options()
  |> Schema.validate()
  |> case do
    {:ok, validated} -> {:ok, struct!(__MODULE__, validated)}
    {:error, error} -> {:error, error}
  end
end
```

### Aggregate-Then-Render Diagnostics
**Source:** [lib/crosswake/policy/compiler.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/compiler.ex:31), [lib/crosswake/policy/diagnostic.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/diagnostic.ex:25)
**Apply to:** `manifest/manifest.ex`, `doctor/doctor.ex`, `doctor/formatter.ex`, `compatibility/route_gate.ex`
```elixir
errors =
  errors
  |> Enum.reverse()
  |> Kernel.++(duplicate_id_errors(compiled_routes, managed_routes))
  |> Kernel.++(Validator.validate(compiled_routes, managed_routes))

case errors do
  [] -> {:ok, %{routes: compiled_routes, warnings: warnings}}
  _errors -> {:error, Diagnostic.new(module: source_module, errors: errors, warnings: [])}
end
```

### Machine-Readable Artifact Writes
**Source:** [lib/crosswake/install/manifest.ex](/Users/jon/projects/crosswake/lib/crosswake/install/manifest.ex:17), [priv/templates/crosswake/install_manifest.json.eex](/Users/jon/projects/crosswake/priv/templates/crosswake/install_manifest.json.eex:1)
**Apply to:** `manifest/serializer.ex`, `support_matrix/renderer.ex`, doctor JSON output if persisted
```elixir
case File.read(path) do
  {:ok, ^contents} -> {:ok, :reused}
  {:ok, _previous} -> File.write!(path, contents); {:ok, :updated}
  {:error, :enoent} -> File.write!(path, contents); {:ok, :created}
end
```

### Mix Task Surface
**Source:** [lib/mix/tasks/crosswake.install.ex](/Users/jon/projects/crosswake/lib/mix/tasks/crosswake.install.ex:22), [lib/mix/tasks/crosswake.gen.shell.ex](/Users/jon/projects/crosswake/lib/mix/tasks/crosswake.gen.shell.ex:16)
**Apply to:** `mix/tasks/crosswake.doctor.ex`
```elixir
@impl Mix.Task
def run(args) do
  {opts, argv, invalid} = OptionParser.parse(args, strict: @switches)

  if invalid != [] do
    Mix.raise("invalid options: #{inspect(invalid)}")
  end

  Mix.shell().info("""
  ...
  """)
end
```

### Test Style: Rich Fixtures + Focused Assertions
**Source:** [test/support/router_fixtures.ex](/Users/jon/projects/crosswake/test/support/router_fixtures.ex:40), [test/crosswake/policy/compiler_test.exs](/Users/jon/projects/crosswake/test/crosswake/policy/compiler_test.exs:8), [test/mix/tasks/crosswake_install_test.exs](/Users/jon/projects/crosswake/test/mix/tasks/crosswake_install_test.exs:32)
**Apply to:** all new manifest, compatibility, doctor, support-matrix, and Mix task tests
```elixir
assert {:ok, %{routes: routes, warnings: []}} = Compiler.compile(ManagedRouter)
assert Enum.any?(errors, &String.contains?(&1.message, "duplicate id"))
output = capture_io(fn -> Mix.Task.run(@task, ["--target", target]) end)
```

### Docs Tone And Product-Honesty Posture
**Source:** [guides/install.md](/Users/jon/projects/crosswake/guides/install.md:8)
**Apply to:** support-matrix docs, doctor messaging, install-guide updates
```markdown
The generated Phoenix and native files are `host-owned`, reviewable, and editable
after generation.
...
What it does not do in Phase 1:
- it does not prove shell boot
- it does not activate runtime manifests
```

Phase 2 docs and doctor copy should preserve this honest-boundary style: explicit claims, explicit non-claims, no implied runtime proof beyond the phase boundary.

## No Analog Found

None. The repo does not have exact Phase 2 subsystems yet, but every planned file has a usable exact, role-match, or partial analog in the existing policy/compiler/install/task/test seams.

## Metadata

**Analog search scope:** `lib/crosswake/**`, `lib/mix/tasks/**`, `test/**`, `guides/**`, `priv/templates/**`, `.planning/phases/01-route-policy-foundation/**`
**Files scanned:** 35
**Pattern extraction date:** 2026-05-14
