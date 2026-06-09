# Phase 95: Operator Surface - Pattern Map

**Mapped:** 2026-06-09
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mix/tasks/crosswake.threadline.ex` | utility/CLI task | read/request-response | `lib/mix/tasks/crosswake.inspect.ex` | role-match |
| `test/mix/tasks/crosswake.threadline_test.exs` | test | read | `test/mix/tasks/crosswake_inspect_test.exs` | role-match |
| `lib/crosswake/doctor/doctor.ex` | utility/service | check/validation | `lib/crosswake/doctor/doctor.ex` (phase_62_notification_findings) | exact |
| `lib/crosswake/support_matrix/support_matrix.ex` | config/truth | static | `lib/crosswake/support_matrix/support_matrix.ex` (@notification_support_truth) | exact |

## Pattern Assignments

### `lib/mix/tasks/crosswake.threadline.ex` (utility/CLI task, read/request-response)

**Analog:** `lib/mix/tasks/crosswake.inspect.ex` (and Research Patterns)

**Imports and CLI definition** (lines 1-8 of inspect):
```elixir
defmodule Mix.Tasks.Crosswake.Inspect do
  use Mix.Task

  alias Crosswake.OperatorInspection
  alias Crosswake.OperatorInspection.Formatter
  alias Crosswake.OperatorInspection.JSONFormatter

  @shortdoc "Inspect route-level Crosswake operator readiness"
```

**CLI Argument Parsing** (from RESEARCH.md):
```elixir
def run(args) do
  {opts, _, _} = OptionParser.parse(args, strict: [thread_id: :string, actor_ref: :string])
  
  thread_id = Keyword.get(opts, :thread_id)
  actor_ref = Keyword.get(opts, :actor_ref)

  cond do
    thread_id == nil and actor_ref == nil ->
      Mix.raise("Expected either --thread-id or --actor-ref")
    true ->
      execute(thread_id, actor_ref)
  end
end
```

**Ecto Context Startup Pattern** (from RESEARCH.md Pitfalls):
```elixir
# Must start app for Ecto
Mix.Task.run("app.start")
```

---

### `test/mix/tasks/crosswake.threadline_test.exs` (test, read)

**Analog:** `test/mix/tasks/crosswake_inspect_test.exs`

**Test Structure Pattern** (lines 1-13):
```elixir
defmodule Mix.Tasks.Crosswake.InspectTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @task "crosswake.inspect"

  test "mix crosswake.inspect emits human-readable route inventory" do
    output =
      capture_io(fn ->
        Mix.Task.reenable(@task)

        Mix.Task.run(@task, [
```

---

### `lib/crosswake/doctor/doctor.ex` (utility/service, check/validation)

**Analog:** Existing doctor phases in `lib/crosswake/doctor/doctor.ex`

**Phase Finding Extractor** (lines 512-527, Phase 62 notification analog):
```elixir
  defp phase_62_notification_findings(nil), do: []

  defp phase_62_notification_findings(manifest) do
    routes = manifest.routes |> Map.values()
    capabilities = Map.keys(manifest.capability_registry || %{})
    
    has_notifications? = Enum.any?(routes, fn route ->
      "notification_token" in route.capabilities or route.notification_open == true
    end) or "notification_token" in capabilities

    if has_notifications? do
      truth = SupportMatrix.notification_support_truth() |> List.first(%{})
      telemetry = Map.get(truth, :telemetry, %{})
      
      [
        check(
```

**PII Schema Reflection Pattern** (from RESEARCH.md):
```elixir
defp check_pii_forbidden_fields(schema) do
  if Code.ensure_loaded?(schema) and function_exported?(schema, :__schema__, 1) do
    fields = schema.__schema__(:fields)
    forbidden = [:email, :ip_address, :user_id, :name] # derived from SupportMatrix
    
    offending_keys = Enum.filter(fields, &(&1 in forbidden))
    
    if offending_keys != [] do
      # emit threadline.pii_forbidden_field_present error
    end
  end
end
```

---

### `lib/crosswake/support_matrix/support_matrix.ex` (config/truth, static)

**Analog:** Existing module attributes in `lib/crosswake/support_matrix/support_matrix.ex`

**Support Truth Attribute Pattern** (lines 185-199, Notification analog):
```elixir
  @notification_support_truth [
    %{
      surface: "notification-open route activation proof",
      proof_class: :advisory,
      action_class: "companion_native",
      docs_anchor: "guides/support_matrix.md#notification-surface-v39",
      delivery_supported: false,
      route_activation_proof: :hermetic,
      activation_authority: :route_gate_sigra,
      evidence_authority: false,
      telemetry: %{
        status: :shipped,
        event_names: Crosswake.Companions.Chimeway.Telemetry.event_names(),
```
*(Planner will need to implement `@audit_ledger_support_truth` and matching accessor function based on this).*

---

## Shared Patterns

### Ephemeral State Output
**Source:** CONTEXT.md (D-02)
**Apply to:** `mix crosswake.threadline`
```elixir
Mix.shell().info("Posture: Ephemeral. No ledger configured.")
# Followed by normal exit 0
```

### Option Parsing and App Environment 
**Source:** Elixir built-ins / Application configs
**Apply to:** `mix crosswake.threadline` and `lib/crosswake/doctor/doctor.ex`
```elixir
Application.get_env(:crosswake, :audit_repo)
Application.get_env(:crosswake, :audit_ledger)
```

## Metadata

**Analog search scope:** `lib/mix/tasks/*.ex`, `lib/crosswake/doctor/*.ex`, `lib/crosswake/support_matrix/*.ex`, `test/mix/tasks/*.exs`
**Files scanned:** ~120
**Pattern extraction date:** 2026-06-09