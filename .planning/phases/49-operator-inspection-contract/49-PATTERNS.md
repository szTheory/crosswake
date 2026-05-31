# Phase 49: Operator Inspection Contract - Pattern Map

**Mapped:** 2026-05-31  
**Files analyzed:** 8  
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mix/tasks/crosswake.inspect.ex` | route | request-response | `lib/mix/tasks/crosswake.doctor.ex` | exact |
| `lib/crosswake/operator_inspection.ex` | service | transform | `lib/crosswake/doctor/doctor.ex` | role-match |
| `lib/crosswake/operator_inspection/types.ex` | model | transform | `lib/crosswake/manifest/types.ex` | exact |
| `lib/crosswake/operator_inspection/formatter.ex` | utility | transform | `lib/crosswake/doctor/formatter.ex` | exact |
| `lib/crosswake/operator_inspection/json_formatter.ex` | utility | transform | `lib/crosswake/doctor/json_formatter.ex` | exact |
| `test/mix/tasks/crosswake_inspect_test.exs` | test | request-response | `test/mix/tasks/crosswake_doctor_test.exs` | exact |
| `test/crosswake/operator_inspection/operator_inspection_test.exs` | test | transform | `test/crosswake/doctor/doctor_test.exs` | role-match |
| `test/crosswake/operator_inspection/formatter_test.exs` | test | transform | `test/crosswake/doctor/formatter_test.exs` | exact |

## Pattern Assignments

### `lib/mix/tasks/crosswake.inspect.ex` (route, request-response)
**Analog:** `lib/mix/tasks/crosswake.doctor.ex`

**Imports + task setup** (`lib/mix/tasks/crosswake.doctor.ex:1-8`):
```elixir
defmodule Mix.Tasks.Crosswake.Doctor do
  use Mix.Task

  alias Crosswake.Doctor
  alias Crosswake.Doctor.Formatter
  alias Crosswake.Doctor.JSONFormatter
```

**Option parsing + invalid option fail-closed** (`lib/mix/tasks/crosswake.doctor.ex:24-28`):
```elixir
{opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

if invalid != [] do
  Mix.raise("invalid options: #{inspect(invalid)}")
end
```

**Format switch + unsupported format error** (`lib/mix/tasks/crosswake.doctor.ex:38-44`):
```elixir
output =
  case opts[:format] do
    nil -> Formatter.render(report)
    "human" -> Formatter.render(report)
    "json" -> JSONFormatter.render(report)
    other -> Mix.raise("unsupported format: #{inspect(other)}")
  end
```

**Required router gate** (`lib/mix/tasks/crosswake.doctor.ex:53-64`):
```elixir
defp router_module!(nil) do
  Mix.raise("pass --router Elixir.YourAppWeb.Router so doctor can compile Crosswake policy")
end
```

### `lib/crosswake/operator_inspection.ex` (service, transform)
**Analog:** `lib/crosswake/doctor/doctor.ex`

**Alias block and explicit dependencies** (`lib/crosswake/doctor/doctor.ex:7-20`):
```elixir
alias Crosswake.Bridge.Contract
alias Crosswake.Bridge.Registry
alias Crosswake.Compatibility.RouteGate
alias Crosswake.Doctor.Check
alias Crosswake.Manifest
alias Crosswake.Shell.Denial
alias Crosswake.SupportMatrix
```

**Typed report struct pattern** (`lib/crosswake/doctor/doctor.ex:21-47`):
```elixir
defmodule Report do
  @moduledoc false

  defstruct [
    :status,
    :manifest,
    support: %{},
    findings: []
  ]
end
```

**Pipeline assembly and derived status** (`lib/crosswake/doctor/doctor.ex:112-153`):
```elixir
findings = findings ++ phase_3_findings ++ phase_4_findings ++ phase_10_findings

%Report{
  status: if(Enum.any?(findings, &(&1.severity == :error)), do: :error, else: :ok),
  manifest: manifest,
  support: support,
  findings: findings
}
```

### `lib/crosswake/operator_inspection/types.ex` (model, transform)
**Analog:** `lib/crosswake/manifest/types.ex`

**Typed structs with enforce keys** (`lib/crosswake/manifest/types.ex:9-35`):
```elixir
defmodule Root do
  @moduledoc false
  @enforce_keys [:manifest_schema_version, :crosswake_version, :generated_at, :routes]
  defstruct [:manifest_schema_version, :crosswake_version, :generated_at, routes: %{}]
end
```

**Closed enum unions for statuses** (`lib/crosswake/manifest/types.ex:127-132`):
```elixir
@type status :: :supported | :verification_required | :unsupported
@type proof_class :: :merge_blocking | :advisory
@type rebuild :: :none | :native_required | :companion_required
```

**Route-centric entry model** (`lib/crosswake/manifest/types.ex:192-237`): keep route as canonical authority, sidecars derived.

### `lib/crosswake/operator_inspection/formatter.ex` (utility, transform)
**Analog:** `lib/crosswake/doctor/formatter.ex`

**Top-level render composition** (`lib/crosswake/doctor/formatter.ex:8-25`):
```elixir
def render(report) do
  findings = Map.get(report, :findings, [])

  [...]
  |> Enum.reject(&(&1 in [nil, ""]))
  |> Enum.join("\n")
end
```

**Concise section helpers with sorted output** (`lib/crosswake/doctor/formatter.ex:148-158`):
```elixir
shells
|> Enum.sort_by(fn {platform, _shell} -> platform end)
|> Enum.map(fn {_platform, shell} -> ... end)
```

**Human wording keeps raw axes visible** (`lib/crosswake/doctor/formatter.ex:39-44`, `176-199`, `211-234`): separate support, offline, commerce/findings sections.

### `lib/crosswake/operator_inspection/json_formatter.ex` (utility, transform)
**Analog:** `lib/crosswake/doctor/json_formatter.ex`

**Stable JSON payload + pretty encoding** (`lib/crosswake/doctor/json_formatter.ex:10-21`):
```elixir
payload = %{status: Map.get(report, :status) |> Atom.to_string(), findings: ...}
Jason.encode!(payload, pretty: true)
```

**Enum serialization to strings** (`lib/crosswake/doctor/json_formatter.ex:75-90`, `161-169`):
```elixir
status: Atom.to_string(status)
severity: Atom.to_string(check.severity)
```

**Nil-safe and false-preserving detail lookup** (`lib/crosswake/doctor/json_formatter.ex:205-222`):
```elixir
defp detail(nil, _key), do: nil
defp detail(details, key) when is_map(details) do
  cond do
    Map.has_key?(details, key) -> Map.get(details, key)
    is_atom(key) and Map.has_key?(details, Atom.to_string(key)) -> Map.get(details, Atom.to_string(key))
    true -> nil
  end
end
```

### `test/mix/tasks/crosswake_inspect_test.exs` (test, request-response)
**Analog:** `test/mix/tasks/crosswake_doctor_test.exs`

**Task harness pattern** (`test/mix/tasks/crosswake_doctor_test.exs:23`, `90-107`, `126-143`):
```elixir
@task "crosswake.doctor"
output = capture_io(fn -> Mix.Task.reenable(@task); Mix.Task.run(@task, [...]) end)
decoded = Jason.decode!(output)
```

**Blocking error behavior assertion** (`test/mix/tasks/crosswake_doctor_test.exs:160-173`):
```elixir
assert_raise Mix.Error, fn -> Mix.Task.run(@task, [...]) end
```

### `test/crosswake/operator_inspection/operator_inspection_test.exs` (test, transform)
**Analog:** `test/crosswake/doctor/doctor_test.exs`

**Direct module API assertions** (`test/crosswake/doctor/doctor_test.exs:75-101`): assert typed fields, statuses, route-level outputs.

**Human + JSON parity checks** (`test/crosswake/doctor/doctor_test.exs:151-187`):
```elixir
human = Formatter.render(report)
json = JSONFormatter.render(report)
decoded = Jason.decode!(json)
```

### `test/crosswake/operator_inspection/formatter_test.exs` (test, transform)
**Analog:** `test/crosswake/doctor/formatter_test.exs`

**Table/section wording assertions** (`test/crosswake/doctor/formatter_test.exs:41-59`, `92-136`): lock output vocabulary and key fields.

**Edge-case guards for nil/false details** (`test/crosswake/doctor/formatter_test.exs:143-169`, `171-204`): preserve non-crashing and false-value correctness.

## Shared Patterns

### Support/Readiness Vocabulary
**Source:** `lib/crosswake/support_matrix/support_matrix.ex:15`, `219-220`  
**Apply to:** `operator_inspection.ex`, `types.ex`, `json_formatter.ex`, tests
```elixir
@statuses [:supported, :verification_required, :unsupported]
@spec statuses() :: [atom()]
def statuses, do: @statuses
```

### Finding Severity Vocabulary
**Source:** `lib/crosswake/doctor/check.ex:9-18`  
**Apply to:** inspection `findings` and condition severity fields
```elixir
@type severity :: :error | :warning | :advisory
```

### Denial Vocabulary
**Source:** `lib/crosswake/shell/denial.ex:8-20`, `48-49`  
**Apply to:** route `denials` and condition `reason` fields
```elixir
@reasons [:compatibility_mismatch, :undeclared_capability, :unavailable_capability, :commerce_corridor, :origin_denied, :inactive_route, :external_entry_denied, :pack_incompatible, :gate_denied, :kill_switch_active, :step_up_required]
def reasons, do: @reasons
```

### Deterministic Contract Serialization
**Source:** `lib/crosswake/manifest/serializer.ex:11-18`, `43-53`  
**Apply to:** stable JSON contract rendering expectations
```elixir
manifest
|> Types.to_map()
|> ordered()
|> Jason.encode_to_iodata!(pretty: true)
```

## No Analog Found

None. All planned files have strong existing analogs.

## Metadata

**Analog search scope:** `lib/`, `test/`, `.planning/phases/49-operator-inspection-contract/`  
**Files scanned:** 16  
**Pattern extraction date:** 2026-05-31
