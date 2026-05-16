# Phase 03: Native Shell Boot And Bounded Bridge - Pattern Map

**Mapped:** 2026-05-14
**Files analyzed:** 18
**Analogs found:** 16 / 18

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mix/tasks/crosswake.gen.shell.ex` | config | request-response | `lib/mix/tasks/crosswake.install.ex` | exact |
| `lib/crosswake/manifest/types.ex` | model | transform | `lib/crosswake/manifest/types.ex` | exact |
| `lib/crosswake/shell/activation.ex` | service | request-response | `lib/crosswake/compatibility/route_gate.ex` | role-match |
| `lib/crosswake/shell/denial.ex` | model | transform | `lib/crosswake/doctor/check.ex` | role-match |
| `lib/crosswake/bridge/contract.ex` | model | request-response | `lib/crosswake/manifest/types.ex` | role-match |
| `lib/crosswake/bridge/registry.ex` | service | request-response | `lib/crosswake/manifest/builder.ex` | role-match |
| `lib/crosswake/bridge/denial.ex` | model | request-response | `lib/crosswake/compatibility/compatibility.ex` | partial |
| `lib/crosswake/compatibility/compatibility.ex` | service | transform | `lib/crosswake/compatibility/compatibility.ex` | exact |
| `lib/crosswake/compatibility/route_gate.ex` | service | request-response | `lib/crosswake/compatibility/route_gate.ex` | exact |
| `lib/crosswake/doctor/check.ex` | model | transform | `lib/crosswake/doctor/check.ex` | exact |
| `lib/crosswake/doctor/doctor.ex` | service | request-response | `lib/crosswake/doctor/doctor.ex` | exact |
| `guides/install.md` | docs | file-I/O | `guides/install.md` | exact |
| `guides/compatibility.md` | docs | transform | `guides/compatibility.md` | exact |
| `guides/native_shell.md` | docs | file-I/O | `guides/support_matrix.md` | partial |
| `guides/bridge.md` | docs | file-I/O | `guides/compatibility.md` | role-match |
| `test/support/router_fixtures.ex` | test | transform | `test/support/router_fixtures.ex` | exact |
| `test/mix/tasks/crosswake_gen_shell_test.exs` | test | request-response | `test/mix/tasks/crosswake_gen_shell_test.exs` | exact |
| `test/crosswake/compatibility/compatibility_test.exs` | test | transform | `test/crosswake/compatibility/compatibility_test.exs` | exact |
| `test/crosswake/doctor/doctor_test.exs` | test | request-response | `test/crosswake/doctor/doctor_test.exs` | exact |
| `test/mix/tasks/crosswake_doctor_test.exs` | test | request-response | `test/mix/tasks/crosswake_doctor_test.exs` | exact |

## Pattern Assignments

### `lib/mix/tasks/crosswake.gen.shell.ex` (config, request-response)

**Analog:** `lib/mix/tasks/crosswake.install.ex`

**Strict CLI/task shape** ([lib/mix/tasks/crosswake.install.ex](/Users/jon/projects/crosswake/lib/mix/tasks/crosswake.install.ex:14), lines 14-29):
```elixir
@switches [
  target: :string,
  router: :string,
  web_module: :string,
  policy_module: :string,
  manifest_path: :string
]

def run(args) do
  Mix.shell().info("Crosswake installer: additive, idempotent, and marker-driven.")

  {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

  if invalid != [] do
    Mix.raise("invalid options: #{inspect(invalid)}")
  end
```

**Generated-artifact summary output** ([lib/mix/tasks/crosswake.install.ex](/Users/jon/projects/crosswake/lib/mix/tasks/crosswake.install.ex:41), lines 41-67):
```elixir
{:ok, manifest_action} =
  Manifest.write(manifest_path, %{...})

Mix.shell().info("""
Crosswake install complete for #{Path.basename(target)}
  router: #{Path.relative_to(router_path, target)} (#{format_router_actions(router_result.actions)})
  policy module: #{Path.relative_to(policy_path, target)} (#{policy_action})
  install manifest: #{Path.relative_to(manifest_path, target)} (#{manifest_action})
""")
```

**Current shell generator boundary** ([lib/mix/tasks/crosswake.gen.shell.ex](/Users/jon/projects/crosswake/lib/mix/tasks/crosswake.gen.shell.ex:17), lines 17-44):
```elixir
def run(args) do
  {opts, argv, invalid} = OptionParser.parse(args, strict: @switches)
  ...
  generated =
    case platform do
      "ios" -> generate_ios_shell(target)
      "android" -> generate_android_shell(target)
    end

  Mix.shell().info("""
  Crosswake #{platform} shell scaffold complete
    generated root: #{generated.root}
    ownership docs: #{generated.readme}
    fixture: #{generated.fixture}
    source: #{generated.source}
  """)
end
```

Use the same strict parse -> delegate -> summarize pattern. Extend this task with real Phase 3 native artifacts and scaffold metadata, but keep the host-owned, explicit-boundary CLI posture.

### `lib/crosswake/manifest/types.ex` (model, transform)

**Analog:** `lib/crosswake/manifest/types.ex`

**Typed nested struct pattern** ([lib/crosswake/manifest/types.ex](/Users/jon/projects/crosswake/lib/crosswake/manifest/types.ex:7), lines 7-42):
```elixir
defmodule Root do
  @enforce_keys [
    :manifest_schema_version,
    :crosswake_version,
    :generated_at,
    :host,
    :compatibility,
    :support_matrix,
    :capability_registry,
    :routes
  ]
  defstruct [
    :manifest_schema_version,
    :crosswake_version,
    :generated_at,
    :host,
    :compatibility,
    :support_matrix,
    capability_registry: %{},
    routes: %{}
  ]
end
```

**Capability and route-entry shape** ([lib/crosswake/manifest/types.ex](/Users/jon/projects/crosswake/lib/crosswake/manifest/types.ex:95), lines 95-137):
```elixir
defmodule Capability do
  @enforce_keys [:id, :version]
  defstruct [:id, :version, status: :supported]
end

defmodule RouteEntry do
  @enforce_keys [:id, :path, :runtime]
  defstruct [
    :id,
    :path,
    :runtime,
    :offline,
    :security,
    capabilities: [],
    packs: [],
    sync: [],
    allowlisted_origins: []
  ]
end
```

**Constructor + serialization boundary** ([lib/crosswake/manifest/types.ex](/Users/jon/projects/crosswake/lib/crosswake/manifest/types.ex:200), lines 200-237; [lib/crosswake/manifest/types.ex](/Users/jon/projects/crosswake/lib/crosswake/manifest/types.ex:262), lines 262-315):
```elixir
def new_compatibility(attrs \\ []) do
  struct!(Compatibility, %{...})
end

def new_route_entry(attrs) when is_list(attrs) do
  struct!(RouteEntry, %{...})
end

def to_map(%Compatibility{} = compatibility) do
  %{
    "manifest_schema_version" => compatibility.manifest_schema_version,
    "bridge_protocol_version" => compatibility.bridge_protocol_version,
    "native_runtime_version" => compatibility.native_runtime_version,
    "supported_manifest_sources" =>
      Enum.map(compatibility.supported_manifest_sources, &Atom.to_string/1),
    "remote_updates" => Enum.map(compatibility.remote_updates, &Atom.to_string/1)
  }
end
```

New bridge envelope, denial, and shell-contract structs should follow this exact pattern: nested modules, explicit `@enforce_keys`, `new_*` constructors, and one `to_map/1` boundary.

### `lib/crosswake/shell/activation.ex` (service, request-response)

**Analog:** `lib/crosswake/compatibility/route_gate.ex`

**Manifest-first activation decision** ([lib/crosswake/compatibility/route_gate.ex](/Users/jon/projects/crosswake/lib/crosswake/compatibility/route_gate.ex:22), lines 22-30):
```elixir
@spec evaluate(Root.t(), String.t(), Target.t()) :: Decision.t()
def evaluate(%Root{} = manifest, route_id, %Target{} = target) do
  findings = Compatibility.route_findings(manifest, route_id, target)

  %Decision{
    route_id: route_id,
    status: if(findings == [], do: :allow, else: :deny),
    reasons: Enum.map(findings, &format_finding/1)
  }
end
```

**Finding-to-user-reason formatting** ([lib/crosswake/compatibility/route_gate.ex](/Users/jon/projects/crosswake/lib/crosswake/compatibility/route_gate.ex:33), lines 33-44):
```elixir
defp format_finding(finding) do
  [
    "Route #{finding.route_id || "(unknown route)"}",
    "axis: #{finding.axis}",
    "reason: #{finding.message}",
    finding.required && "required: #{finding.required}",
    finding.available && "available: #{finding.available}",
    finding.hint && "fix hint: #{finding.hint}"
  ]
  |> Enum.reject(&is_nil/1)
  |> Enum.join("\n")
end
```

`Shell.Activation` should keep the same shape: one typed request in, one typed allow/deny decision out, with no partial activation path.

### `lib/crosswake/shell/denial.ex` (model, transform)

**Analog:** `lib/crosswake/doctor/check.ex`

**Small typed finding struct** ([lib/crosswake/doctor/check.ex](/Users/jon/projects/crosswake/lib/crosswake/doctor/check.ex:6), lines 6-18):
```elixir
@enforce_keys [:severity, :code, :message, :check]
defstruct [:severity, :code, :message, :hint, :check, details: %{}]

@type t :: %__MODULE__{
  severity: severity(),
  code: String.t(),
  message: String.t(),
  hint: String.t() | nil,
  check: String.t(),
  details: map()
}
```

Model route-activation denials the same way: stable code, stable reason vocabulary, optional hint, and machine-readable `details`.

### `lib/crosswake/bridge/contract.ex` (model, request-response)

**Analog:** `lib/crosswake/manifest/types.ex`

**Versioned contract fields** ([lib/crosswake/manifest/types.ex](/Users/jon/projects/crosswake/lib/crosswake/manifest/types.ex:66), lines 66-92):
```elixir
defmodule Compatibility do
  @enforce_keys [
    :manifest_schema_version,
    :bridge_protocol_version,
    :native_runtime_version,
    :supported_manifest_sources,
    :remote_updates
  ]
  defstruct [...]
end
```

**Route-linked typed payloads** ([lib/crosswake/manifest/types.ex](/Users/jon/projects/crosswake/lib/crosswake/manifest/types.ex:225), lines 225-237):
```elixir
def new_route_entry(attrs) when is_list(attrs) do
  struct!(RouteEntry, %{
    id: Keyword.fetch!(attrs, :id),
    path: Keyword.fetch!(attrs, :path),
    runtime: Keyword.fetch!(attrs, :runtime),
    ...
    allowlisted_origins: Keyword.get(attrs, :allowlisted_origins, [])
  })
end
```

Follow this pattern for bridge request/reply modules: explicit version field, route identity, origin, capability/command identity, correlation id, and typed payload maps instead of loose ad hoc message shapes.

### `lib/crosswake/bridge/registry.ex` (service, request-response)

**Analog:** `lib/crosswake/manifest/builder.ex`

**Registry derivation from canonical route truth** ([lib/crosswake/manifest/builder.ex](/Users/jon/projects/crosswake/lib/crosswake/manifest/builder.ex:40), lines 40-47):
```elixir
defp capability_registry(routes) do
  routes
  |> Enum.flat_map(& &1.capabilities)
  |> Enum.uniq()
  |> Enum.sort()
  |> Map.new(fn capability ->
    {capability, Types.new_capability(id: capability, version: capability_version(capability))}
  end)
end
```

**Route-scoped allowlist derivation** ([lib/crosswake/manifest/builder.ex](/Users/jon/projects/crosswake/lib/crosswake/manifest/builder.ex:50), lines 50-70):
```elixir
defp route_entries(routes, managed_routes, origin) do
  routes
  |> Enum.zip(managed_routes)
  |> Map.new(fn {%Route{} = route, managed_route} ->
    entry =
      Types.new_route_entry(
        id: route.id,
        ...
        capabilities: route.capabilities,
        allowlisted_origins: [origin]
      )

    {route.id, entry}
  end)
end
```

Bridge registry code should derive command/capability allowlists from manifest truth, not from a second native-only registry.

### `lib/crosswake/bridge/denial.ex` (model, request-response)

**Analog:** `lib/crosswake/compatibility/compatibility.ex`

**Stable finding fields with required/available/hint** ([lib/crosswake/compatibility/compatibility.ex](/Users/jon/projects/crosswake/lib/crosswake/compatibility/compatibility.ex:32), lines 32-45):
```elixir
defmodule Finding do
  @enforce_keys [:axis, :message]
  defstruct [:axis, :message, :required, :available, :hint, :route_id]
end
```

**Operator-language denial messages** ([lib/crosswake/compatibility/compatibility.ex](/Users/jon/projects/crosswake/lib/crosswake/compatibility/compatibility.ex:166), lines 166-236):
```elixir
finding(
  :bridge_protocol_version,
  route_id,
  compatibility.bridge_protocol_version,
  target.bridge_protocol_version,
  "route requires bridge protocol #{compatibility.bridge_protocol_version} but the shell exposes #{target.bridge_protocol_version || "none"}",
  "upgrade the shell bridge before activating #{route_id}"
)
...
finding(
  :capability_version,
  route.id,
  required_version,
  available_version,
  "route requires capability #{capability_id} at #{required_version}",
  "bundle capability #{capability_id} at #{required_version} or remove it from the route allowlist"
)
```

Bridge denials should reuse this vocabulary style: explicit axis, explicit requirement, explicit available state, explicit fix hint, and no side-effect ambiguity.

### `lib/crosswake/compatibility/compatibility.ex` (service, transform)

**Analog:** `lib/crosswake/compatibility/compatibility.ex`

**Target/finding submodule pattern** ([lib/crosswake/compatibility/compatibility.ex](/Users/jon/projects/crosswake/lib/crosswake/compatibility/compatibility.ex:10), lines 10-46):
```elixir
defmodule Target do
  defstruct [
    :manifest_schema_version,
    :bridge_protocol_version,
    :native_runtime_version,
    :origin,
    manifest_source: :bundled,
    capabilities: %{}
  ]
end

defmodule Finding do
  @enforce_keys [:axis, :message]
  defstruct [:axis, :message, :required, :available, :hint, :route_id]
end
```

**Layered evaluation pipeline** ([lib/crosswake/compatibility/compatibility.ex](/Users/jon/projects/crosswake/lib/crosswake/compatibility/compatibility.ex:58), lines 58-70):
```elixir
def route_findings(%Root{} = manifest, route_id, %Target{} = target) do
  route = Map.get(manifest.routes, route_id)

  []
  |> validate_route_presence(route_id, route)
  |> validate_manifest_schema(manifest.compatibility, target, route)
  |> validate_bridge_protocol(manifest.compatibility, target, route)
  |> validate_native_runtime(manifest.compatibility, target, route)
  |> validate_capabilities(route, manifest.capability_registry, target)
  |> validate_manifest_source(manifest.compatibility, target, route)
  |> validate_origin(route, manifest.host.origin, target.origin)
end
```

**Compatibility-source and origin checks** ([lib/crosswake/compatibility/compatibility.ex](/Users/jon/projects/crosswake/lib/crosswake/compatibility/compatibility.ex:245), lines 245-335):
```elixir
if target.manifest_source in compatibility.supported_manifest_sources do
  errors
else
  [%Finding{axis: :manifest_source, ...} | errors]
end

if actual_origin in allowed_origins do
  errors
else
  [%Finding{axis: :origin, ...} | errors]
end
```

Add bridge-specific checks here in the same one-axis-per-function style. Do not collapse route activation and bridge authorization into one monolithic boolean.

### `lib/crosswake/compatibility/route_gate.ex` (service, request-response)

**Analog:** `lib/crosswake/compatibility/route_gate.ex`

Keep this module as the shell-facing fail-closed adapter. Phase 3 route activation and denial UI should consume a `Decision`-like result instead of calling lower-level compatibility functions directly.

### `lib/crosswake/doctor/check.ex` (model, transform)

**Analog:** `lib/crosswake/doctor/check.ex`

Phase 3 diagnostics should extend, not replace, this finding struct. Add native-shell and bridge checks as new `check`/`code` values and preserve the same severity taxonomy.

### `lib/crosswake/doctor/doctor.ex` (service, request-response)

**Analog:** `lib/crosswake/doctor/doctor.ex`

**Report aggregation pattern** ([lib/crosswake/doctor/doctor.ex](/Users/jon/projects/crosswake/lib/crosswake/doctor/doctor.ex:13), lines 13-24; [lib/crosswake/doctor/doctor.ex](/Users/jon/projects/crosswake/lib/crosswake/doctor/doctor.ex:29), lines 29-47):
```elixir
defmodule Report do
  defstruct [:status, :install_manifest, :manifest, findings: []]
end

def run(opts \\ []) do
  ...
  {install_manifest, findings} = load_install_manifest(install_manifest_path)
  findings = findings ++ router_and_policy_findings(install_manifest, cwd)
  {manifest, findings} = compile_and_validate_manifest(findings, opts)
  findings = findings ++ advisory_findings(opts)

  %Report{
    status: if(Enum.any?(findings, &(&1.severity == :error)), do: :error, else: :ok),
    install_manifest: install_manifest,
    manifest: manifest,
    findings: findings
  }
end
```

**Blocking-check helper style** ([lib/crosswake/doctor/doctor.ex](/Users/jon/projects/crosswake/lib/crosswake/doctor/doctor.ex:49), lines 49-92; [lib/crosswake/doctor/doctor.ex](/Users/jon/projects/crosswake/lib/crosswake/doctor/doctor.ex:106), lines 106-169):
```elixir
check(
  :error,
  "install_manifest_missing",
  "installer_state",
  "install manifest not found at #{path}",
  "run mix crosswake.install before mix crosswake.doctor"
)
...
check(
  :error,
  "router_markers_missing",
  "router_markers",
  "router markers are missing from #{path}",
  "re-run mix crosswake.install to restore #{Enum.join(missing, ", ")}"
)
```

**Manifest compile -> doctor findings projection** ([lib/crosswake/doctor/doctor.ex](/Users/jon/projects/crosswake/lib/crosswake/doctor/doctor.ex:172), lines 172-243):
```elixir
case Manifest.compile(route_source, manifest_opts) do
  {:ok, %{manifest: manifest}} ->
    ...
    {manifest, findings ++ warning_findings ++ support_findings}

  {:error, %Diagnostic{errors: errors}} ->
    manifest_findings =
      Enum.map(errors, fn error ->
        check(
          :error,
          "manifest_invalid",
          "manifest_contract",
          error.message,
          error.hint,
          %{key: error.key, route_id: error.route_id, path: error.path}
        )
      end)
```

Phase 3 doctor work should follow the same aggregation model: load scaffold truth, compile manifest truth, add native-shell/bridge checks, emit structured findings, render later.

### `guides/install.md` (docs, file-I/O)

**Analog:** `guides/install.md`

**Ownership and public-boundary style** ([guides/install.md](/Users/jon/projects/crosswake/guides/install.md:3), lines 3-11; [guides/install.md](/Users/jon/projects/crosswake/guides/install.md:61), lines 61-73):
```markdown
Crosswake Phase 1 exposes a two-step, additive setup path:

The generated Phoenix and native files are `host-owned`, reviewable, and editable
after generation.
...
What it does not do in Phase 1:

- it does not prove shell boot
- it does not activate runtime manifests
- it does not claim bridge behavior or Phase 3 runtime support
```

Update this guide with the same explicit “does / does not” posture for real shell boot and bridge boundaries.

### `guides/compatibility.md` (docs, transform)

**Analog:** `guides/compatibility.md`

**Axis-by-axis contract language** ([guides/compatibility.md](/Users/jon/projects/crosswake/guides/compatibility.md:8), lines 8-19; [guides/compatibility.md](/Users/jon/projects/crosswake/guides/compatibility.md:35), lines 35-45):
```markdown
Crosswake evaluates compatibility through separate contract axes:

- `manifest_schema_version`
- `bridge_protocol_version`
- `native_runtime_version`
...
Crosswake activation is fail-closed.
```

Bridge docs should use the same vocabulary. Keep route activation, capability gating, and failure posture explicit and non-marketing.

### `guides/native_shell.md` and `guides/bridge.md` (docs, file-I/O)

**Analogs:** `guides/support_matrix.md`, `guides/compatibility.md`

**Mechanical-doc truth style** ([guides/support_matrix.md](/Users/jon/projects/crosswake/guides/support_matrix.md:3), lines 3-4):
```markdown
This guide is mechanically derived from `Crosswake.SupportMatrix.canonical/1`.
It is intentionally narrow and proof-oriented for Phase 2.
```

**Constraint language** ([guides/compatibility.md](/Users/jon/projects/crosswake/guides/compatibility.md:30), lines 30-33):
```markdown
Remote updates stay constrained to versioned replacement or explicitly versioned
companion data.
```

Any new shell/bridge guide should read as a product-contract surface, not tutorial prose. Prefer declarative statements, version names, denial reasons, and proof-lane references.

### `test/support/router_fixtures.ex` (test, transform)

**Analog:** `test/support/router_fixtures.ex`

**Fixture router style with realistic runtime/capability mixes** ([test/support/router_fixtures.ex](/Users/jon/projects/crosswake/test/support/router_fixtures.ex:40), lines 40-63; [test/support/router_fixtures.ex](/Users/jon/projects/crosswake/test/support/router_fixtures.ex:65), lines 65-100):
```elixir
defmodule ManagedRouter do
  use Crosswake.Router

  scope "/" do
    crosswake_defaults runtime: :live_view, offline: :cached_read_only, security: :standard do
      get "/dashboard", ..., crosswake: [id: "dashboard"]
      live "/library", ..., crosswake: [id: "library", runtime: :offline_island, sync: [:journal]]
      live "/camera", ..., crosswake: [
        id: "camera",
        runtime: :native_screen,
        capabilities: [:camera],
        security: :sensitive
      ]
```

Phase 3 tests should extend these fixtures with bridge-friendly capabilities like `app.info.get`, `haptics.impact`, and `files.pick`, plus explicit allow/deny route mixes.

### `test/mix/tasks/crosswake_gen_shell_test.exs` (test, request-response)

**Analog:** `test/mix/tasks/crosswake_gen_shell_test.exs`

**Capture-IO task test pattern** ([test/mix/tasks/crosswake_gen_shell_test.exs](/Users/jon/projects/crosswake/test/mix/tasks/crosswake_gen_shell_test.exs:8), lines 8-58):
```elixir
ios_output =
  capture_io(fn ->
    Mix.Task.reenable(@task)
    Mix.Task.run(@task, ["ios", "--target", target])
  end)

assert ios_output =~ "Crosswake ios shell scaffold complete"
assert File.read!(ios_readme) =~ "host-owned"
assert File.read!(ios_source) =~ "Phase 1 route-policy scaffold only"
```

Keep this exact shape for Phase 3: run task in temp dir, assert generated paths, assert source placeholders become real boot files, assert README and fixture/manifest content.

### `test/crosswake/compatibility/compatibility_test.exs` (test, transform)

**Analog:** `test/crosswake/compatibility/compatibility_test.exs`

**Axis-specific assertions** ([test/crosswake/compatibility/compatibility_test.exs](/Users/jon/projects/crosswake/test/crosswake/compatibility/compatibility_test.exs:10), lines 10-33):
```elixir
findings = Compatibility.route_findings(manifest, "camera", %Target{...})

assert Enum.map(findings, & &1.axis) |> Enum.sort() == [
  :bridge_protocol_version,
  :capability_version,
  :manifest_schema_version,
  :native_runtime_version
]
```

**Fail-closed route gate assertions** ([test/crosswake/compatibility/compatibility_test.exs](/Users/jon/projects/crosswake/test/crosswake/compatibility/compatibility_test.exs:57), lines 57-79):
```elixir
decision = RouteGate.evaluate(manifest, "camera", %Target{...})

assert decision.status == :deny
assert Enum.any?(decision.reasons, &String.contains?(&1, "newer shell runtime"))
assert Enum.any?(decision.reasons, &String.contains?(&1, "bridge protocol 1.0.0"))
```

Phase 3 bridge tests should mirror this style: one denied axis per assertion group, and reason strings that stay stable enough for docs and diagnostics.

### `test/crosswake/doctor/doctor_test.exs` and `test/mix/tasks/crosswake_doctor_test.exs` (test, request-response)

**Analogs:** `test/crosswake/doctor/doctor_test.exs`, `test/mix/tasks/crosswake_doctor_test.exs`

**Structured report assertions** ([test/crosswake/doctor/doctor_test.exs](/Users/jon/projects/crosswake/test/crosswake/doctor/doctor_test.exs:58), lines 58-99):
```elixir
report = Doctor.run(...)

assert report.status == :ok
assert report.manifest != nil
assert Enum.any?(report.findings, &(&1.check == "policy_compile" and &1.severity == :warning))

human = Formatter.render(report)
json = JSONFormatter.render(report)
decoded = Jason.decode!(json)
```

**Mix-task output and blocking failure assertions** ([test/mix/tasks/crosswake_doctor_test.exs](/Users/jon/projects/crosswake/test/mix/tasks/crosswake_doctor_test.exs:51), lines 51-112):
```elixir
assert output =~ "Crosswake doctor report"
assert output =~ "policy_compile"

decoded = Jason.decode!(output)
assert decoded["status"] == "ok"

assert_raise Mix.Error, fn ->
  Mix.Task.run(@task, [...])
end
```

Use this same pattern for new native-shell and bridge doctor checks: assert human output, assert JSON output, and assert blocking failures raise instead of degrading to warnings.

## Shared Patterns

### Host-Owned Scaffold And Idempotent Writes
**Sources:** [lib/mix/tasks/crosswake.gen.shell.ex](/Users/jon/projects/crosswake/lib/mix/tasks/crosswake.gen.shell.ex:47), [lib/crosswake/install/manifest.ex](/Users/jon/projects/crosswake/lib/crosswake/install/manifest.ex:17), [lib/crosswake/manifest/serializer.ex](/Users/jon/projects/crosswake/lib/crosswake/manifest/serializer.ex:20)
**Apply to:** shell generation, scaffold metadata, machine-readable native manifests

```elixir
case File.read(path) do
  {:ok, ^contents} -> {:ok, :reused}
  {:ok, _previous} -> File.write!(path, contents); {:ok, :updated}
  {:error, :enoent} -> File.write!(path, contents); {:ok, :created}
  {:error, reason} -> raise "could not persist ... #{:file.format_error(reason)}"
end
```

### Fail-Closed Compatibility And Activation
**Sources:** [lib/crosswake/compatibility/compatibility.ex](/Users/jon/projects/crosswake/lib/crosswake/compatibility/compatibility.ex:58), [lib/crosswake/compatibility/route_gate.ex](/Users/jon/projects/crosswake/lib/crosswake/compatibility/route_gate.ex:22)
**Apply to:** route activation, bridge authorization, denial modeling

```elixir
[]
|> validate_route_presence(route_id, route)
|> validate_manifest_schema(manifest.compatibility, target, route)
|> validate_bridge_protocol(manifest.compatibility, target, route)
|> validate_native_runtime(manifest.compatibility, target, route)
|> validate_capabilities(route, manifest.capability_registry, target)
|> validate_manifest_source(manifest.compatibility, target, route)
|> validate_origin(route, manifest.host.origin, target.origin)
```

### Typed Contract Modules
**Sources:** [lib/crosswake/manifest/types.ex](/Users/jon/projects/crosswake/lib/crosswake/manifest/types.ex:66), [lib/crosswake/doctor/check.ex](/Users/jon/projects/crosswake/lib/crosswake/doctor/check.ex:6)
**Apply to:** bridge envelopes, denial structs, shell request/decision modules

```elixir
@enforce_keys [...]
defstruct [...]

@type t :: %__MODULE__{...}
```

### Structured Diagnostics First, Rendering Second
**Sources:** [lib/crosswake/doctor/doctor.ex](/Users/jon/projects/crosswake/lib/crosswake/doctor/doctor.ex:29), [lib/crosswake/doctor/formatter.ex](/Users/jon/projects/crosswake/lib/crosswake/doctor/formatter.ex:8), [lib/crosswake/doctor/json_formatter.ex](/Users/jon/projects/crosswake/lib/crosswake/doctor/json_formatter.ex:8)
**Apply to:** doctor native checks, bridge denial reporting, shell diagnostics surface

```elixir
report = Doctor.run(...)
human = Formatter.render(report)
json = JSONFormatter.render(report)
```

### Fixture-Driven Contract Tests
**Sources:** [test/support/router_fixtures.ex](/Users/jon/projects/crosswake/test/support/router_fixtures.ex:40), [test/crosswake/manifest/manifest_test.exs](/Users/jon/projects/crosswake/test/crosswake/manifest/manifest_test.exs:9), [test/crosswake/compatibility/compatibility_test.exs](/Users/jon/projects/crosswake/test/crosswake/compatibility/compatibility_test.exs:81)
**Apply to:** bridge contract tests, route activation tests, deep-link tests

```elixir
Types.new_root(
  crosswake_version: "0.1.0",
  generated_at: "2026-05-14T00:00:00Z",
  host: Types.new_host(),
  compatibility: Types.new_compatibility(),
  support_matrix: SupportMatrix.canonical(),
  capability_registry: %{...},
  routes: %{...}
)
```

### Mechanical Docs Checks
**Sources:** [lib/crosswake/support_matrix/renderer.ex](/Users/jon/projects/crosswake/lib/crosswake/support_matrix/renderer.ex:11), [test/crosswake/support_matrix/renderer_test.exs](/Users/jon/projects/crosswake/test/crosswake/support_matrix/renderer_test.exs:35)
**Apply to:** shell guide, bridge guide, compatibility/support updates

```elixir
assert File.read!("guides/support_matrix.md") == Renderer.render(SupportMatrix.canonical())
```

If Phase 3 introduces generated docs, add the same exact-file equality test instead of looser substring-only checks.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `native/ios/crosswake_shell/...` real runtime boot files | component | request-response | Repo only contains placeholder Swift generated by `mix crosswake.gen.shell`; no existing real iOS runtime implementation yet |
| `native/android/crosswake_shell/...` real runtime boot files | component | request-response | Repo only contains placeholder Kotlin generated by `mix crosswake.gen.shell`; no existing real Android runtime implementation yet |

Planner should treat these as host-owned generated artifacts whose Elixir-side analog is the existing generator/task and fixture posture, not a native runtime implementation pattern.

## Metadata

**Analog search scope:** `lib/`, `test/`, `guides/`, `.planning/phases/02-*`
**Files scanned:** 28
**Pattern extraction date:** 2026-05-14
