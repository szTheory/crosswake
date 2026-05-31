# Phase 46: Sigra Auth Contract-Only Slice - Pattern Map

**Mapped:** 2026-05-31  
**Files analyzed:** 14  
**Analogs found:** 14 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/crosswake/companions/sigra/contracts.ex` | service | request-response | `lib/crosswake/companions/rindle/contracts.ex` | exact |
| `lib/crosswake/policy/schema.ex` | config | request-response | `lib/crosswake/policy/schema.ex` | exact |
| `lib/crosswake/policy/route.ex` | model | request-response | `lib/crosswake/policy/route.ex` | exact |
| `lib/crosswake/manifest/types.ex` | model | transform | `lib/crosswake/manifest/types.ex` | exact |
| `lib/crosswake/manifest/builder.ex` | service | transform | `lib/crosswake/manifest/builder.ex` | exact |
| `lib/crosswake/compatibility/route_gate.ex` | service | request-response | `lib/crosswake/compatibility/route_gate.ex` | exact |
| `lib/crosswake/shell/denial.ex` | model | transform | `lib/crosswake/shell/denial.ex` | exact |
| `lib/crosswake/doctor/doctor.ex` | service | transform | `lib/crosswake/doctor/doctor.ex` | exact |
| `lib/crosswake/support_matrix/support_matrix.ex` | service | transform | `lib/crosswake/support_matrix/support_matrix.ex` | exact |
| `test/crosswake/companions/sigra/contracts_test.exs` | test | request-response | `test/crosswake/companions/rindle/contracts_test.exs` | exact |
| `test/crosswake/policy/schema_test.exs` | test | request-response | `test/crosswake/policy/schema_test.exs` | exact |
| `test/crosswake/doctor/doctor_test.exs` | test | request-response | `test/crosswake/doctor/doctor_test.exs` | exact |
| `test/crosswake/support_matrix/support_matrix_test.exs` | test | request-response | `test/crosswake/support_matrix/support_matrix_test.exs` | exact |
| `test/crosswake/proof/phase46_sigra_auth_contract_test.exs` | test | request-response | `test/crosswake/proof/phase40_gate_evaluation_test.exs` | role-match |

## Pattern Assignments

### `lib/crosswake/companions/sigra/contracts.ex` (service, request-response)

**Analog:** `lib/crosswake/companions/rindle/contracts.ex`

**Typed structs + vocab pattern** (`lib/crosswake/companions/rindle/contracts.ex:10-117`)
```elixir
defmodule UploadGrant do
  @enforce_keys [...]
  defstruct [...]
  @type t :: %__MODULE__{...}
end
...
@media_state_vocabulary [:queued, :uploaded, :scanning, :available, :rejected]
```

**Constructor + validator pattern** (`lib/crosswake/companions/rindle/contracts.ex:150-201`)
```elixir
@spec new_capture_evidence(map() | keyword()) :: {:ok, CaptureEvidence.t()} | {:error, keyword()}
def new_capture_evidence(attrs), do: build_and_validate(attrs, CaptureEvidence, &validate_capture_evidence/1, :capture_evidence)

def validate_capture_evidence(%CaptureEvidence{} = evidence) do
  []
  |> validate_required_string(:grant_id, evidence.grant_id)
  |> validate_evidence_source(evidence.source)
  |> reject_trace_authority_lane(evidence.trace_metadata)
  |> to_validation_result()
end
```

**Authority-lane rejection pattern** (`lib/crosswake/companions/rindle/contracts.ex:269-280`)
```elixir
defp reject_trace_authority_lane(errors, trace_metadata) when is_map(trace_metadata) do
  errors
  |> reject_trace_key(trace_metadata, :authority_state)
  |> reject_trace_key(trace_metadata, :availability_state)
end
```

### `lib/crosswake/policy/schema.ex` + `lib/crosswake/policy/route.ex` (config/model, request-response)

**Analogs:** same files

**DSL key declaration pattern** (`lib/crosswake/policy/schema.ex:16-81`)
```elixir
@schema NimbleOptions.new!([
  ...,
  gated_by: [type: {:custom, __MODULE__, :validate_flag_key, []}, ...],
  on_unavailable: [type: {:custom, __MODULE__, :validate_on_unavailable, []}, ...]
])
```

**Custom validator shape** (`lib/crosswake/policy/schema.ex:139-173`)
```elixir
@spec validate_flag_key(term()) :: {:ok, atom()} | {:error, String.t()}
def validate_flag_key(value) when is_atom(value) and value not in [true, false, nil] do
  ...
end
```

**Route-level cross-field default/fail-closed pattern** (`lib/crosswake/policy/route.ex:116-135`)
```elixir
defp validate_gating_posture(validated) do
  gated_by = validated[:gated_by]
  on_unavailable = validated[:on_unavailable]

  cond do
    on_unavailable != nil and is_nil(gated_by) -> {:error, validation_error(...)}
    gated_by != nil and is_nil(on_unavailable) -> {:ok, Keyword.put(validated, :on_unavailable, :deny)}
    true -> {:ok, validated}
  end
end
```

### `lib/crosswake/manifest/types.ex` + `lib/crosswake/manifest/builder.ex` (model/service, transform)

**Analogs:** same files

**RouteEntry contract extension pattern** (`lib/crosswake/manifest/types.ex:192-232`)
```elixir
defmodule RouteEntry do
  defstruct [..., :gated_by, :on_unavailable, ...]
  @type t :: %__MODULE__{..., gated_by: atom() | nil, on_unavailable: :deny | {:fallback_phoenix, atom()} | nil}
end
```

**Builder projection pattern** (`lib/crosswake/manifest/builder.ex:122-139`)
```elixir
Types.new_route_entry(
  ...,
  gated_by: route.gated_by,
  on_unavailable: route.on_unavailable
)
```

**Manifest serialization pattern** (`lib/crosswake/manifest/types.ex:808-828`)
```elixir
"gated_by" => route.gated_by && Atom.to_string(route.gated_by),
"on_unavailable" => serialize_on_unavailable(route.on_unavailable)
|> Enum.reject(fn {k, v} -> k in ["gated_by", "on_unavailable"] and is_nil(v) end)
```

### `lib/crosswake/compatibility/route_gate.ex` + `lib/crosswake/shell/denial.ex` (service/model, request-response)

**Analogs:** same files

**Reason vocabulary extension pattern** (`lib/crosswake/shell/denial.ex:8-35`)
```elixir
@reasons [..., :gate_denied, :kill_switch_active]
@type reason :: ... | :gate_denied | :kill_switch_active
```

**Fail-closed prepend pipeline pattern** (`lib/crosswake/compatibility/route_gate.ex:36-50`)
```elixir
gate_denials = prepend_gate_evaluation_findings([], route, target)
...
denials = gate_denials ++ compatibility_denials
```

**Structured denial payload pattern** (`lib/crosswake/compatibility/route_gate.ex:149-161`)
```elixir
Denial.new(
  reason: :gate_denied,
  ...,
  details: %{
    "flag_key" => Atom.to_string(route.gated_by),
    "reason" => "DISABLED",
    "variant" => "off",
    "evaluated_at" => DateTime.utc_now() |> DateTime.to_iso8601()
  }
)
```

### `lib/crosswake/doctor/doctor.ex` + `lib/crosswake/support_matrix/support_matrix.ex` (service, transform)

**Analogs:** same files

**Doctor phase-hook integration pattern** (`lib/crosswake/doctor/doctor.ex:130-139`)
```elixir
phase_41_findings = phase_41_gating_findings(manifest)
...
findings = findings ++ ... ++ phase_41_findings
```

**Route-scoped finding family pattern** (`lib/crosswake/doctor/doctor.ex:572-676`)
```elixir
# one advisory per route + error/warning variants
check(:advisory, "gating.route_gated", "gating.#{route.id}", ...)
check(:error, "gating.flag_reference_unknown", "gating.#{route.id}", ...)
```

**Support truth function pattern** (`lib/crosswake/support_matrix/support_matrix.ex:242-270`)
```elixir
@spec gating_truth() :: [map()]
def gating_truth do
  Application.get_env(:crosswake, :companions, [])
  |> Enum.map(fn companion ->
    state = companion.report_state()
    %{companion_id: state.companion_id, gate_state: gate_state_display(state)}
  end)
end
```

### Tests (`test/crosswake/...`)

**Contract tests pattern:** `test/crosswake/companions/rindle/contracts_test.exs:6-160`
- `describe` blocks by contract lane.
- Vocabulary lock assertions.
- Constructor happy path + invalid vocabulary + forbidden authority-field tests.

**Schema tests pattern:** `test/crosswake/policy/schema_test.exs:7-120`
- Use `Schema.validate!/1` for positive cases and `assert_raise NimbleOptions.ValidationError` for invalid DSL.

**Doctor integration tests pattern:** `test/crosswake/doctor/doctor_test.exs:703-747`
- Define inline router fixture, run `Doctor.run/1`, assert typed finding codes in both human and JSON formatters.

**Support-matrix truth tests pattern:** `test/crosswake/support_matrix/support_matrix_test.exs:8-71`
- Assert canonical shape via `Types.new_root |> Types.to_map`.
- Keep matrix narrow and proof-oriented with explicit entry counts.

## Shared Patterns

### Auth/Evidence Boundary
**Source:** `lib/crosswake/companions/rindle/contracts.ex:269-280`  
**Apply to:** `lib/crosswake/companions/sigra/contracts.ex`

```elixir
defp reject_trace_authority_lane(errors, trace_metadata) when is_map(trace_metadata) do
  errors
  |> reject_trace_key(trace_metadata, :authority_state)
  |> reject_trace_key(trace_metadata, :availability_state)
end
```

### Route Policy to Manifest Truth
**Source:** `lib/crosswake/policy/schema.ex:16-81`, `lib/crosswake/policy/route.ex:116-135`, `lib/crosswake/manifest/builder.ex:122-139`, `lib/crosswake/manifest/types.ex:808-828`  
**Apply to:** `auth_min_level` and `requires_recent_auth` end-to-end path.

### Denial Vocabulary + Fail-Closed Gate
**Source:** `lib/crosswake/shell/denial.ex:8-35`, `lib/crosswake/compatibility/route_gate.ex:36-50`  
**Apply to:** new `:step_up_required` reason and auth predicate gate insertion after companion gate checks.

### Product-Truth Surfaces
**Source:** `lib/crosswake/doctor/doctor.ex:572-676`, `lib/crosswake/support_matrix/support_matrix.ex:242-270`  
**Apply to:** auth doctor category + support matrix auth contract truth row family.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/crosswake/companions/sigra/contracts.ex` | service | request-response | No existing Sigra module yet; use Rindle contract seam as direct template. |
| `test/crosswake/proof/phase46_sigra_auth_contract_test.exs` | test | request-response | Phase-specific proof file does not exist yet; copy structure from existing `phase40`/`phase41` proof suites. |

## Metadata

**Analog search scope:** `lib/crosswake`, `test/crosswake`, `.planning/phases/46-sigra-auth-contract-only-slice`  
**Files scanned:** 15 core analog files + 2 phase context files  
**Pattern extraction date:** 2026-05-31
