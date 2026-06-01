# Phase 51: Support Matrix and Native Rebuild Truth - Pattern Map

**Mapped:** 2026-06-01
**Files analyzed:** 12
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/crosswake/support_matrix/support_matrix.ex` | utility | transform | `lib/crosswake/support_matrix/support_matrix.ex` | exact |
| `lib/crosswake/support_matrix/renderer.ex` | utility | file-I/O | `lib/crosswake/support_matrix/renderer.ex` | exact |
| `lib/crosswake/operator_inspection.ex` | service | transform | `lib/crosswake/operator_inspection.ex` | exact |
| `lib/crosswake/operator_inspection/types.ex` | model | transform | `lib/crosswake/operator_inspection/types.ex` | exact |
| `lib/crosswake/doctor/publish_readiness.ex` | service | request-response | `lib/crosswake/doctor/publish_readiness.ex` | exact |
| `test/crosswake/support_matrix/support_matrix_test.exs` | test | transform | `test/crosswake/support_matrix/support_matrix_test.exs` | exact |
| `test/crosswake/support_matrix/renderer_test.exs` | test | file-I/O | `test/crosswake/support_matrix/renderer_test.exs` | exact |
| `test/crosswake/operator_inspection/operator_inspection_test.exs` | test | request-response | `test/crosswake/operator_inspection/operator_inspection_test.exs` | exact |
| `test/crosswake/doctor/publish_readiness_test.exs` | test | request-response | `test/crosswake/doctor/publish_readiness_test.exs` | exact |
| `guides/support_matrix.md` | config | file-I/O | `guides/support_matrix.md` (renderer-owned) | exact |
| `test/crosswake/guides/companions_test.exs` | test | file-I/O | `test/crosswake/guides/companions_test.exs` | role-match |
| `test/crosswake/guides/commerce_test.exs` | test | file-I/O | `test/crosswake/guides/commerce_test.exs` | role-match |

## Pattern Assignments

### `lib/crosswake/support_matrix/support_matrix.ex` (utility, transform)
**Analog:** `lib/crosswake/support_matrix/support_matrix.ex`

**Imports + typed aliases** (lines 6-13):
```elixir
alias Crosswake.Manifest.Types
alias Crosswake.Manifest.Types.Capability
alias Crosswake.Manifest.Types.CapabilitySupportEntry
alias Crosswake.Manifest.Types.ChangeClassEntry
alias Crosswake.Manifest.Types.PackageSurfaceEntry
alias Crosswake.Manifest.Types.ReleaseBoundaryEntry
alias Crosswake.Manifest.Types.SupportEntry
alias Crosswake.Manifest.Types.SupportMatrix
```

**Closed vocabulary pattern** (lines 15, 219-220):
```elixir
@statuses [:supported, :verification_required, :unsupported]
@spec statuses() :: [atom()]
def statuses, do: @statuses
```

**Canonical structured constant rows** (lines 22-46, 497-538):
```elixir
@commerce_corridor_entries [%{corridor_role: "paywall_entry", ... proof_class: :merge_blocking, ...}]
...
Types.new_change_class_entry(change_class: "docs-only", ...)
Types.new_change_class_entry(change_class: "core-only/no native rebuild", ...)
```

**Validation pattern** (lines 210-217):
```elixir
def validate(%SupportMatrix{} = support_matrix) do
  []
  |> validate_categories_present(support_matrix)
  |> validate_exact_statuses(support_matrix)
  |> validate_narrow_baseline(support_matrix)
  |> validate_capability_families_present(support_matrix)
end
```

### `lib/crosswake/support_matrix/renderer.ex` (utility, file-I/O)
**Analog:** `lib/crosswake/support_matrix/renderer.ex`

**Deterministic section assembly** (lines 15-52):
```elixir
@spec render(SupportMatrix.t()) :: String.t()
def render(%SupportMatrix{} = support_matrix) do
  [ ..., section("Phoenix", support_matrix.phoenix), ..., change_class_section(support_matrix.change_classes), ""]
  |> Enum.join("\n")
end
```

**Idempotent write semantics** (lines 54-74):
```elixir
case File.read(path) do
  {:ok, ^contents} -> {:ok, :reused}
  {:ok, _previous} -> File.write!(path, contents); {:ok, :updated}
  {:error, :enoent} -> File.write!(path, contents); {:ok, :created}
  {:error, reason} -> raise "could not persist ..."
end
```

**Table cell hardening** (lines 228-245):
```elixir
defp escape_cell(value) when is_binary(value) do
  value
  |> String.replace("\\", "\\\\")
  |> String.replace("|", "\\|")
  |> String.replace("\n", " ")
end
```

### `lib/crosswake/operator_inspection.ex` (service, transform)
**Analog:** `lib/crosswake/operator_inspection.ex`

**Route-authoritative compile -> derive pipeline** (lines 15-49):
```elixir
case Manifest.compile(route_source, opts) do
  {:ok, %{manifest: manifest}} -> from_manifest(manifest, opts)
  {:error, diagnostic} -> raise ArgumentError, "could not compile ..."
end
```

**Per-route decomposition pattern** (lines 51-77):
```elixir
capabilities = Enum.map(route.capabilities, &capability_entry(&1, manifest))
commerce = commerce_entry(route, manifest)
...
support = support_entry(capabilities, commerce, companion, auth, notifications, rebuild)
```

**Derived conditions (do not replace raw axes)** (lines 376-401):
```elixir
Types.condition(type: :support_status, status: support.status == :supported, ...)
Types.condition(type: :rebuild_required, status: not (rebuild.native_required or rebuild.companion_required), ...)
```

**Finding mapping from conditions** (lines 540-555):
```elixir
%Check{
  severity: condition.severity,
  code: "operator.#{condition.type}.#{condition.reason}",
  check: "operator_inspection",
  ...
}
```

### `lib/crosswake/operator_inspection/types.ex` (model, transform)
**Analog:** `lib/crosswake/operator_inspection/types.ex`

**Versioned schema + enforce_keys structs** (lines 10-37, 39-83):
```elixir
@schema_version "1.0.0"
defmodule Document do
  @enforce_keys [:schema_version, :generated_at, ...]
  defstruct [:schema_version, :generated_at, ...]
end
```

**Stable string serialization boundary** (lines 137-199):
```elixir
def to_map(%Route{} = route) do
  %{"runtime" => atom_label(route.runtime), ...}
end
```

### `lib/crosswake/doctor/publish_readiness.ex` (service, request-response)
**Analog:** `lib/crosswake/doctor/publish_readiness.ex`

**Report contract struct + check struct** (lines 27-39, 41-92):
```elixir
defmodule Report do
  @enforce_keys [:schema_version, :status, :summary, :checks]
  defstruct [:schema_version, :status, :summary, :checks]
end
```

**Deterministic check pipeline** (lines 161-171):
```elixir
[
  publish_parity_check(cwd, opts),
  companion_dependency_health_check(inspection),
  ...
  proof_posture_check(support_matrix, inspection)
]
```

**Result vs advisory check helpers** (lines 465-504):
```elixir
defp result_check(opts) do
  ... result: if(passed?, do: :pass, else: :fail), severity: if(passed?, do: :advisory, else: :error)
end

defp advisory_check(opts) do
  ... check(Keyword.put(opts, :blocking, severity == :error and result == :fail))
end
```

### Test files (all ExUnit contract-lock style)
**Analog set:** `test/crosswake/support_matrix/support_matrix_test.exs`, `test/crosswake/support_matrix/renderer_test.exs`, `test/crosswake/operator_inspection/operator_inspection_test.exs`, `test/crosswake/doctor/publish_readiness_test.exs`

**Pattern to copy:**
- module header + aliases (e.g., support matrix test lines 1-7)
- explicit vocabulary assertions (support matrix test lines 152-160, 231-247)
- router fixture + env setup/restore for operator/doctor tests (operator test lines 13-85; publish readiness test lines 12-75)
- deterministic renderer parity assertions (renderer test lines 137-151)
- non-claim checks in readiness output (publish readiness test lines 137-161)

### Guide non-claim tests
**Analogs:** `test/crosswake/guides/companions_test.exs`, `test/crosswake/guides/commerce_test.exs`, `test/crosswake/guides/capabilities_test.exs`

**Pattern to copy:**
- `setup_all` reads guide once and shares content (companions lines 25-28; commerce lines 31-34)
- explicit deferred/non-claim assertions (companions lines 57-62; commerce lines 128-145, 190-195)
- parity lock to runtime/canonical module output where possible (companions lines 82-113, 115-135; commerce lines 207-249)

## Shared Patterns

### Closed vocabulary + typed rows
**Source:** `lib/crosswake/support_matrix/support_matrix.ex:15`, `:22-134`, `:497-538`  
**Apply to:** support matrix row expansion, action-class/promotions fields, doctor/inspection consumers.

### Route-authoritative derivation
**Source:** `lib/crosswake/operator_inspection.ex:29-77`, `:323-375`, `:376-470`  
**Apply to:** any new derived conditions or summaries; never make summaries canonical.

### Severity/proof/support axis separation
**Source:** `lib/crosswake/operator_inspection.ex:323-362`; `lib/crosswake/doctor/publish_readiness.ex:75-91,465-503`; `test/crosswake/operator_inspection/operator_inspection_test.exs:140-164`  
**Apply to:** all v3.6 support truth additions.

### Deterministic docs generation + parity lock
**Source:** `lib/crosswake/support_matrix/renderer.ex:15-75`; `test/crosswake/support_matrix/renderer_test.exs:137-151`  
**Apply to:** `guides/support_matrix.md` and any new generated support sections.

### Deferred non-claim guardrails
**Source:** `test/crosswake/doctor/publish_readiness_test.exs:137-161`; `test/crosswake/guides/companions_test.exs:57-62`; `test/crosswake/guides/commerce_test.exs:128-145`  
**Apply to:** StoreKit/Play, full Sigra, Chimeway delivery, standalone shell-package defers.

## No Analog Found

None for requested Phase 51 focus files; all have direct in-repo analogs.

## Metadata

**Analog search scope:** `lib/crosswake/**`, `test/crosswake/**`, `guides/**`  
**Files scanned:** 12 primary + 3 guide-lock tests  
**Pattern extraction date:** 2026-06-01
