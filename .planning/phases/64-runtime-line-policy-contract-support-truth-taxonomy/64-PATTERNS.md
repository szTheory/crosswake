# Phase 64: Runtime-Line Policy Contract & Support-Truth Taxonomy - Pattern Map

**Mapped:** 2026-06-03
**Files analyzed:** 9 (1 new module, 1 new struct in existing file, 5 modified files, 1 new test)
**Analogs found:** 9 / 9

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/crosswake/runtime_line/rebuild_policy.ex` (NEW) | contract module | request-response | `lib/crosswake/native_escape/contract.ex` | exact |
| `lib/crosswake/manifest/types.ex` — add `RuntimeLineRow` (NEW struct) | model/typed-struct | transform | `lib/crosswake/manifest/types.ex` `ReleaseBoundaryEntry` / `ChangeClassEntry` | exact |
| `lib/crosswake/manifest/types.ex` — add `CapabilitySupportEntry.verification_method` (MODIFY) | model/typed-struct | transform | same file `CapabilitySupportEntry` (lines 426-460) + `new_capability_support_entry/1` (lines 823-839) | exact |
| `lib/crosswake/manifest/types.ex` — add `PromotionRuleEntry.required_verification_method` (MODIFY) | model/typed-struct | transform | same file `PromotionRuleEntry` (lines 557-614) + `new_promotion_rule_entry/1` (lines 885-904) | exact |
| `lib/crosswake/manifest/types.ex` — add `SupportMatrix.rebuild_matrix` field (MODIFY) | model/typed-struct | transform | same file `SupportMatrix` (lines 362-397) + `new_support_matrix/1` (lines 792-805) | exact |
| `lib/crosswake/support_matrix/support_matrix.ex` — add `@rebuild_matrix_rows` + `rebuild_matrix/1` + two Android promotion rows + evidence-tier validation (MODIFY) | service/registry | CRUD | same file `capability_families/1` (lines 388-390), `validate_promotion_rule_rows/1` (lines 774-816), `promotion_rule_entries/0` (lines 882-1082) | exact |
| `lib/crosswake/doctor/doctor.ex` — extend `release_policy_snapshot/1` (MODIFY) | service | request-response | same file `release_policy_snapshot/1` (lines 1186-1203) | exact |
| `lib/crosswake/doctor/formatter.ex` + `json_formatter.ex` — add `format_rebuild_matrix/1` + `evidence posture:` line (MODIFY) | utility/formatter | transform | `formatter.ex` `format_change_classes/1` (lines 141-148), `format_release_policy/1` (lines 60-109); `json_formatter.ex` `format_release_policy/1` (lines 103-116) | exact |
| `test/crosswake/proof/phase64_runtime_line_policy_test.exs` (NEW) | test/proof | request-response | `test/crosswake/proof/phase52_operator_truth_test.exs` + `test/support/proof_assertions.ex` | exact |

---

## Pattern Assignments

---

### `lib/crosswake/runtime_line/rebuild_policy.ex` (NEW — contract module, request-response)

**Primary analog:** `lib/crosswake/native_escape/contract.ex` (lines 1-12 — module header, `@protocol`/`@version` module attributes, narrow typed public API, `struct!` constructors)
**Secondary analog:** `lib/crosswake/bridge/contract.ex` (lines 1-22 — `@moduledoc`, module-level constants `@protocol`/`@version`/`@commands`, typed nested modules, `@spec` + public functions, private helpers absent)

**Module header + module attribute constants pattern** (`lib/crosswake/native_escape/contract.ex` lines 1-12):
```elixir
defmodule Crosswake.NativeEscape.Contract do
  @moduledoc """
  Typed contract for Crosswake's single public native escape hatch: ...
  """

  @protocol "crosswake.native_escape"
  @version "1.0.0"
  @purposes [:media_capture]
  @permission_postures [:required, :granted, :denied]
  @states [:captured_local, :transfer_complete]
```

Mirror for `RebuildPolicy` — replace protocol/version constants with `@system_rebuild_classes`:
```elixir
defmodule Crosswake.RuntimeLine.RebuildPolicy do
  @moduledoc """
  Policy contract deriving OTA-safe vs. rebuild-required classification from the
  existing `native_runtime_version` compatibility axis.
  ...
  """

  alias Crosswake.Manifest.Types.Capability
  alias Crosswake.Manifest.Types.Root

  @system_rebuild_classes [:sdk_floor_bump, :privacy_manifest_entry]
  # Closed set. New system classes go through a phase, not a config key.
```

**Typed public API with `@spec`** (`lib/crosswake/bridge/contract.ex` lines 98-108):
```elixir
  @spec protocol() :: String.t()
  def protocol, do: @protocol

  @spec version() :: String.t()
  def version, do: @version

  @spec commands() :: [String.t()]
  def commands, do: @commands

  @spec command_supported?(String.t()) :: boolean()
  def command_supported?(command), do: command in @commands
```

Mirror for `RebuildPolicy` — three public specs from D-04:
```elixir
  @type change_class ::
    :bridge_schema_change
    | :capability_family_add
    | :permission_add
    | :entitlement_add
    | :sdk_floor_bump
    | :privacy_manifest_entry
    | :push_capability_change
    | :url_scheme_change

  @type verdict :: :ota_safe | {:rebuild_required, :native_shell | :companion_shell}

  @spec classify(change_class(), Capability.t() | nil) :: verdict()
  @spec diff(Root.t(), Root.t()) :: [{change_class(), verdict()}]
  @spec rebuild_required?(Capability.rebuild()) :: boolean()
```

**Guard clause in constructor** (`lib/crosswake/native_escape/contract.ex` lines 126-130):
```elixir
  def new_request(attrs) when is_list(attrs) do
    permission_posture = Keyword.fetch!(attrs, :permission_posture)

    unless permission_posture in @permission_postures do
      raise ArgumentError,
            "permission_posture must be one of #{inspect(@permission_postures)}, got: #{inspect(permission_posture)}"
    end
```

Mirror guard clause in `classify/2` for `capability` nil check when `change_class` is NOT in `@system_rebuild_classes`.

---

### `lib/crosswake/manifest/types.ex` — `RuntimeLineRow` struct (NEW struct)

**Primary analog:** `ReleaseBoundaryEntry` (`lib/crosswake/manifest/types.ex` lines 478-496) — exact template: `@moduledoc false`, `@derive Jason.Encoder`, `@enforce_keys`, `defstruct`, `@type t`.

**Struct definition pattern** (lines 478-496):
```elixir
  defmodule ReleaseBoundaryEntry do
    @moduledoc false
    @derive Jason.Encoder

    @enforce_keys [:target, :versioning, :compatibility_contract, :release_rule]
    defstruct [
      :target,
      :versioning,
      :compatibility_contract,
      :release_rule
    ]

    @type t :: %__MODULE__{
            target: String.t(),
            versioning: String.t(),
            compatibility_contract: String.t(),
            release_rule: String.t()
          }
  end
```

Mirror for `RuntimeLineRow` — all 6 fields in `@enforce_keys` (new struct, no back-compat concern):
```elixir
  defmodule RuntimeLineRow do
    @moduledoc false
    @derive Jason.Encoder

    @enforce_keys [:runtime_line, :capability_surface, :change_class, :ota_safe, :rebuild_required, :evidence_tier]
    defstruct [
      :runtime_line,
      :capability_surface,
      :change_class,
      :ota_safe,
      :rebuild_required,
      :evidence_tier
    ]

    @type evidence_tier :: :none | :provider_advisory | :jvm_hermetic | :emulator_advisory | :device_verified

    @type t :: %__MODULE__{
            runtime_line: String.t(),
            capability_surface: [String.t()],
            change_class: String.t(),
            ota_safe: boolean(),
            rebuild_required: boolean(),
            evidence_tier: evidence_tier()
          }
  end
```

**Constructor pattern** (analog: `new_release_boundary_entry/1` lines 852-860):
```elixir
  @spec new_release_boundary_entry(keyword()) :: ReleaseBoundaryEntry.t()
  def new_release_boundary_entry(attrs) when is_list(attrs) do
    struct!(ReleaseBoundaryEntry, %{
      target: Keyword.fetch!(attrs, :target),
      versioning: Keyword.fetch!(attrs, :versioning),
      compatibility_contract: Keyword.fetch!(attrs, :compatibility_contract),
      release_rule: Keyword.fetch!(attrs, :release_rule)
    })
  end
```

Mirror as `new_runtime_line_row/1` — all 6 fields via `Keyword.fetch!` (enforced keys only).

**`to_map/1` clause pattern** (analog: `to_map(%ReleaseBoundaryEntry{})` lines 1123-1130):
```elixir
  def to_map(%ReleaseBoundaryEntry{} = entry) do
    %{
      "target" => entry.target,
      "versioning" => entry.versioning,
      "compatibility_contract" => entry.compatibility_contract,
      "release_rule" => entry.release_rule
    }
  end
```

Mirror for `RuntimeLineRow` — atom fields (`evidence_tier`) use `Atom.to_string/1` (see `CapabilitySupportEntry.to_map/1` line 1096 pattern: `"owner" => Atom.to_string(support_entry.owner)`).

---

### `lib/crosswake/manifest/types.ex` — `CapabilitySupportEntry.verification_method` (MODIFY)

**Analog:** `CapabilitySupportEntry` struct itself (lines 426-460) + `new_capability_support_entry/1` (lines 823-839) + `to_map(%CapabilitySupportEntry{})` (lines 1093-1111).

**Existing struct** (lines 426-460 — add `verification_method: :none` to `defstruct`, NOT to `@enforce_keys`):
```elixir
  defmodule CapabilitySupportEntry do
    @moduledoc false
    @derive Jason.Encoder

    @enforce_keys [:family, :owner, :package_class, :proof_class, :rebuild]
    defstruct [
      :family,
      :owner,
      :posture,
      :baseline_status,
      :proof_status,
      :package_class,
      :proof_class,
      :rebuild,
      prerequisites: [],
      denial: nil,
      fallback: nil,
      guide: nil
      # ADD: verification_method: :none
    ]
```

**Existing constructor** (lines 823-839 — add one `Keyword.get` line):
```elixir
  @spec new_capability_support_entry(keyword()) :: CapabilitySupportEntry.t()
  def new_capability_support_entry(attrs) when is_list(attrs) do
    struct!(CapabilitySupportEntry, %{
      family: Keyword.fetch!(attrs, :family),
      owner: Keyword.fetch!(attrs, :owner),
      ...
      guide: Keyword.get(attrs, :guide)
      # ADD: verification_method: Keyword.get(attrs, :verification_method, :none)
    })
  end
```

**Existing `to_map/1`** (lines 1093-1111 — add one key, mirroring existing atom serialization pattern):
```elixir
  def to_map(%CapabilitySupportEntry{} = support_entry) do
    %{
      "family" => support_entry.family,
      "owner" => Atom.to_string(support_entry.owner),
      ...
      # ADD: "verification_method" => Atom.to_string(support_entry.verification_method)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
```

Note: `Atom.to_string/1` is the atom serialization convention (not `atom_label/1`) — consistent with `"owner"`, `"package_class"` fields in the same clause. `verification_method: :none` must never be nil so it will NOT be rejected by the `Enum.reject(is_nil)` pipeline.

---

### `lib/crosswake/manifest/types.ex` — `PromotionRuleEntry.required_verification_method` (MODIFY)

**Analog:** `PromotionRuleEntry` struct (lines 557-614) + `new_promotion_rule_entry/1` (lines 885-904) + `to_map(%PromotionRuleEntry{})` (lines 1153-1171).

**Existing struct** (lines 557-614 — add to `defstruct` only, NOT to `@enforce_keys`):
```elixir
  defmodule PromotionRuleEntry do
    @moduledoc false
    @derive Jason.Encoder

    @enforce_keys [
      :claim_id, :claim_scope, :current_proof_class, :promotes_to, :evidence_class,
      :required_evidence, :minimum_consecutive_passes, :freshness_window, :failure_budget,
      :required_platforms, :required_docs_anchors, :change_class, :action_class,
      :check_ids, :demotion_trigger
    ]
    defstruct [
      ...all existing fields...
      # ADD: required_verification_method: :none
    ]
```

**Existing constructor** (lines 885-904 — add one `Keyword.get` line at the end):
```elixir
  @spec new_promotion_rule_entry(keyword()) :: PromotionRuleEntry.t()
  def new_promotion_rule_entry(attrs) when is_list(attrs) do
    struct!(PromotionRuleEntry, %{
      claim_id: Keyword.fetch!(attrs, :claim_id),
      ...
      demotion_trigger: Keyword.fetch!(attrs, :demotion_trigger)
      # ADD: required_verification_method: Keyword.get(attrs, :required_verification_method, :none)
    })
  end
```

**Existing `to_map/1`** (lines 1153-1171 — add one key, using `atom_label/1` which is already the convention for `current_proof_class`/`promotes_to` in this clause):
```elixir
  def to_map(%PromotionRuleEntry{} = entry) do
    %{
      "claim_id" => entry.claim_id,
      "current_proof_class" => atom_label(entry.current_proof_class),
      "promotes_to" => atom_label(entry.promotes_to),
      ...
      "demotion_trigger" => entry.demotion_trigger
      # ADD: "required_verification_method" => atom_label(entry.required_verification_method)
    }
  end
```

Note: Use `atom_label/1` (not `Atom.to_string/1`) because `PromotionRuleEntry.to_map/1` consistently uses `atom_label/1` for its atom fields. This is different from `CapabilitySupportEntry.to_map/1` which uses `Atom.to_string/1`.

---

### `lib/crosswake/manifest/types.ex` — `SupportMatrix.rebuild_matrix` field (MODIFY)

**Analog:** `SupportMatrix` struct (lines 362-397) + `new_support_matrix/1` (lines 792-805) + `to_map(%SupportMatrix{})` (lines 1063-1075).

**Existing struct** (lines 362-397 — add `rebuild_matrix: []` to `defstruct` ONLY, NOT to `@enforce_keys`):
```elixir
  defmodule SupportMatrix do
    @moduledoc false

    @enforce_keys [
      :phoenix, :live_view, :ios, :android, :shells,
      :capability_families, :package_surfaces, :release_boundaries, :change_classes
    ]
    defstruct phoenix: [],
              live_view: [],
              ios: [],
              android: [],
              shells: [],
              capability_families: [],
              package_surfaces: [],
              release_boundaries: [],
              change_classes: []
              # ADD: rebuild_matrix: []

    @type t :: %__MODULE__{
            ...
            change_classes: [Crosswake.Manifest.Types.ChangeClassEntry.t()]
            # ADD: rebuild_matrix: [Crosswake.Manifest.Types.RuntimeLineRow.t()]
          }
  end
```

**Existing constructor** (lines 792-805 — add one `Keyword.get` line):
```elixir
  @spec new_support_matrix(keyword()) :: SupportMatrix.t()
  def new_support_matrix(attrs) when is_list(attrs) do
    struct!(SupportMatrix, %{
      ...
      change_classes: Keyword.get(attrs, :change_classes, [])
      # ADD: rebuild_matrix: Keyword.get(attrs, :rebuild_matrix, [])
    })
  end
```

**Existing `to_map/1`** (lines 1063-1075 — add one `Enum.map` line):
```elixir
  def to_map(%SupportMatrix{} = support_matrix) do
    %{
      ...
      "change_classes" => Enum.map(support_matrix.change_classes, &to_map/1)
      # ADD: "rebuild_matrix" => Enum.map(support_matrix.rebuild_matrix, &to_map/1)
    }
  end
```

---

### `lib/crosswake/support_matrix/support_matrix.ex` — `@rebuild_matrix_rows` + `rebuild_matrix/1` + two Android promotion rows + evidence-tier validation (MODIFY)

**Analog 1 — module attribute static data + accessor:** `@commerce_corridor_entries` (lines 25-...) + `def commerce_corridors` (line 443) and `capability_families/1` (lines 388-390).

**Accessor pattern** (lines 388-399 — mirror exactly):
```elixir
  @spec capability_families(SupportMatrix.t()) :: [CapabilitySupportEntry.t()]
  def capability_families(%SupportMatrix{} = support_matrix),
    do: support_matrix.capability_families

  @spec package_surfaces(SupportMatrix.t()) :: [PackageSurfaceEntry.t()]
  def package_surfaces(%SupportMatrix{} = support_matrix), do: support_matrix.package_surfaces

  @spec release_boundaries(SupportMatrix.t()) :: [ReleaseBoundaryEntry.t()]
  def release_boundaries(%SupportMatrix{} = support_matrix), do: support_matrix.release_boundaries

  @spec change_classes(SupportMatrix.t()) :: [ChangeClassEntry.t()]
  def change_classes(%SupportMatrix{} = support_matrix), do: support_matrix.change_classes
```

New accessor added alongside these:
```elixir
  @spec rebuild_matrix(SupportMatrix.t()) :: [Types.RuntimeLineRow.t()]
  def rebuild_matrix(%SupportMatrix{} = support_matrix),
    do: support_matrix.rebuild_matrix
```

**`@rebuild_matrix_rows` module attribute** — mirrors `@commerce_corridor_entries` (line 25 list-of-maps pattern) but uses typed structs via `Types.new_runtime_line_row/1`:
```elixir
  @rebuild_matrix_rows [
    Types.new_runtime_line_row(
      runtime_line: "1.x",
      capability_surface: [...],
      change_class: "native or companion rebuild required",
      ota_safe: false,
      rebuild_required: true,
      evidence_tier: :jvm_hermetic
    ),
    ...
  ]
```

Then `rebuild_matrix` field is populated in `canonical/1` (line 272) alongside the other typed-row list fields, following the same lifecycle.

**Analog 2 — Android promotion row:** `shell.android.generated_project` (lines 902-922):
```elixir
      promotion_rule(
        claim_id: "shell.android.generated_project",
        claim_scope: "Generated Android shell support",
        current_proof_class: :advisory,
        promotes_to: :merge_blocking,
        evidence_class: "generated_shell",
        required_evidence: [
          "script/verify_generated_android_shell.sh",
          "Java-enabled BridgeChannel proof"
        ],
        minimum_consecutive_passes: 2,
        freshness_window: "current release branch",
        failure_budget: "zero merge-blocking failures",
        required_platforms: ["android"],
        required_docs_anchors: ["guides/support_matrix.md", "guides/native_shell.md"],
        change_class: "native or companion rebuild required",
        action_class: "native_shell",
        check_ids: ["diag.shell.verification_required"],
        demotion_trigger:
          "Keep or demote to verification_required when Android JVM or generated-shell proof is stale or unavailable."
      )
```

The two new Phase 64 rows (`shell.android.jvm_hermetic`, `shell.android.device_verified`) follow exactly this pattern with the addition of `required_verification_method:` field (the new additive field on `PromotionRuleEntry`).

**Analog 3 — `validate_promotion_rule_rows/1`** (lines 774-816 — add a new `validate_verification_method_invariant/1` private clause added to the pipe in `validate/1` at line 347):
```elixir
  def validate(%SupportMatrix{} = support_matrix) do
    []
    |> validate_categories_present(support_matrix)
    |> validate_exact_statuses(support_matrix)
    |> validate_narrow_baseline(support_matrix)
    |> validate_capability_families_present(support_matrix)
    |> validate_phase51_support_truth()
    # ADD: |> validate_verification_method_invariant(support_matrix)
  end
```

The new `validate_verification_method_invariant/1` follows the same `Enum.reduce(errors, fn entry, acc -> cond do ... end end)` shape as `validate_promotion_rule_rows/1` (lines 774-816).

---

### `lib/crosswake/doctor/doctor.ex` — extend `release_policy_snapshot/1` (MODIFY)

**Analog:** `release_policy_snapshot/1` (lines 1186-1203):
```elixir
  defp release_policy_snapshot(manifest) do
    compatibility = manifest.compatibility
    support_matrix = manifest.support_matrix

    %{
      crosswake_version: manifest.crosswake_version,
      manifest_schema_version: compatibility.manifest_schema_version,
      bridge_protocol_version: compatibility.bridge_protocol_version,
      native_runtime_version: compatibility.native_runtime_version,
      package_version_truth: "Package versions alone do not determine support truth.",
      companion_requirement: "...",
      capability_families: support_matrix.capability_families,
      package_surfaces: support_matrix.package_surfaces,
      release_boundaries: support_matrix.release_boundaries,
      change_classes: support_matrix.change_classes
    }
  end
```

Add two keys — the matrix is accessed via the new `SupportMatrix.rebuild_matrix/1` accessor; evidence posture is a new private helper (planner discretion: private `evidence_posture_snapshot/1` in `doctor.ex`, or a `SupportMatrix.evidence_posture/0` accessor — either satisfies D-16):
```elixir
      # ADD to the returned map:
      rebuild_matrix: SupportMatrix.rebuild_matrix(support_matrix),
      evidence_posture: evidence_posture_snapshot(support_matrix)
```

---

### `lib/crosswake/doctor/formatter.ex` — `format_rebuild_matrix/1` + `evidence posture:` line (MODIFY)

**Analog:** `format_change_classes/1` (lines 141-148):
```elixir
  defp format_change_classes(classes) do
    lines =
      Enum.map(classes, fn change_class ->
        "    #{change_class.change_class}: signal=\"#{change_class.compatibility_signal}\", proof=\"#{change_class.required_proof}\""
      end)

    ["  change classes:" | lines] |> Enum.join("\n")
  end
```

New private helper mirrors this exactly — section header + `Enum.map` over row fields:
```elixir
  defp format_rebuild_matrix(rows) do
    lines =
      Enum.map(rows, fn row ->
        "    #{row.runtime_line}: ota_safe=#{row.ota_safe}, rebuild_required=#{row.rebuild_required}, evidence_tier=#{format_evidence_tier(row.evidence_tier)}, capability_surface=[#{Enum.join(row.capability_surface, ", ")}]"
      end)

    ["  rebuild & compatibility matrix:" | lines] |> Enum.join("\n")
  end

  defp format_evidence_tier(:jvm_hermetic), do: "jvm-hermetic (CI only)"
  defp format_evidence_tier(:device_verified), do: "device-verified"
  defp format_evidence_tier(tier), do: Atom.to_string(tier)
```

**`format_release_policy/1` full clause** (lines 60-87) — add `evidence posture:` line and the matrix block. The `evidence posture:` line is INSIDE the main body (alongside `native_runtime_version=` lines), the matrix block is appended via `format_rebuild_matrix/1` call (alongside `format_change_classes/1`):
```elixir
  defp format_release_policy(%{
         ...
         change_classes: change_classes,
         rebuild_matrix: rebuild_matrix,     # ADD to pattern match
         evidence_posture: evidence_posture  # ADD to pattern match
       }) do
    [
      "release policy:",
      ...
      "  native_runtime_version=#{native_runtime_version}",
      "  evidence posture: #{format_evidence_posture(evidence_posture)}",  # ADD
      ...
      format_change_classes(change_classes),
      format_rebuild_matrix(rebuild_matrix)  # ADD
    ]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join("\n")
  end
```

The minimal clause (lines 89-107) does NOT get the new keys — it matches only the 6 version/policy fields and is unchanged.

### `lib/crosswake/doctor/json_formatter.ex` — `rebuild_matrix` + `evidence_posture` keys (MODIFY)

**Analog:** `format_release_policy/1` in `json_formatter.ex` (lines 103-116):
```elixir
  defp format_release_policy(nil), do: nil

  defp format_release_policy(release_policy) do
    %{
      crosswake_version: release_policy.crosswake_version,
      manifest_schema_version: release_policy.manifest_schema_version,
      bridge_protocol_version: release_policy.bridge_protocol_version,
      native_runtime_version: release_policy.native_runtime_version,
      package_version_truth: release_policy.package_version_truth,
      companion_requirement: release_policy.companion_requirement,
      package_surfaces: release_policy.package_surfaces,
      change_classes: release_policy.change_classes
    }
  end
```

Add two keys — `rebuild_matrix` list and `evidence_posture` map. Both keys reference the same `release_policy` map fields added to `release_policy_snapshot/1` in `doctor.ex`. The `rebuild_matrix` list should be mapped through `Types.to_map/1` (or the struct's `@derive Jason.Encoder` handles it — planner to confirm which serialization path `json_formatter.ex` uses for existing struct lists like `package_surfaces`):
```elixir
      # ADD to the returned map:
      rebuild_matrix: release_policy.rebuild_matrix,
      evidence_posture: release_policy.evidence_posture
```

---

### `test/crosswake/proof/phase64_runtime_line_policy_test.exs` (NEW — hermetic proof lane)

**Primary analog:** `test/crosswake/proof/phase52_operator_truth_test.exs` (lines 1-56 — module structure, `use ExUnit.Case, async: false`, `import ExUnit.CaptureIO`, `alias Crosswake.TestSupport.ProofAssertions`).

**Module header + setup pattern** (lines 1-12):
```elixir
defmodule Crosswake.Proof.Phase52OperatorTruthTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Crosswake.TestSupport.ProofAssertions

  @inspect_task "crosswake.inspect"
  @inspect_fixture "test/fixtures/proof/phase52_operator_inspection.json"
  @readiness_fixture "test/fixtures/proof/phase52_publish_readiness.json"
```

Mirror for phase64 — no `@moduletag :requires_example_host` (hermetic; no external host):
```elixir
defmodule Crosswake.Proof.Phase64RuntimeLinePolicyTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Crosswake.TestSupport.ProofAssertions
  alias Crosswake.RuntimeLine.RebuildPolicy
  alias Crosswake.SupportMatrix
  alias Crosswake.Manifest.Types
```

**`ProofAssertions` usage pattern** (lines 59-73):
```elixir
  @tag :phase52_smoke
  test "stable proof id helper contract is present for operator drift checks" do
    message =
      ProofAssertions.stable_id_message(
        "proof.operator.inspect.schema_version",
        "operator inspection schema version",
        "Crosswake.OperatorInspection.Types.schema_version/0",
        "schema_version drift",
        "test/fixtures/proof/phase52_operator_inspection.json",
        "update canonical inspection output and fixture together",
        :merge_blocking
      )

    assert message =~ "proof.operator.inspect.schema_version"
    assert message =~ "merge_blocking"
  end
```

**`assert_normalized_json_fixture` with `CaptureIO`** (lines 75-99):
```elixir
  test "normalized inspect json matches fixture and keeps schema stable" do
    output =
      capture_io(fn ->
        Mix.Task.reenable(@inspect_task)
        Mix.Task.run(@inspect_task, ["--router", "...", "--format", "json"])
      end)

    assert output =~ "\"schema_version\""

    ProofAssertions.assert_normalized_json_fixture(
      "proof.operator.inspect.json_contract",
      output,
      @inspect_fixture,
      source: "mix crosswake.inspect --format json",
      path: @inspect_fixture,
      hint: "normalize volatile fields and refresh fixture only for intended semantic changes",
      posture: :merge_blocking
    )
  end
```

For phase64, RLINE-02 no-new-field proof is a simple struct key assertion (no fixture file needed):
```elixir
  @tag :rline_02
  test "Compatibility struct has exactly the 5 locked fields — no new field added" do
    fields = Map.keys(%Types.Compatibility{
      manifest_schema_version: "1.0.0",
      bridge_protocol_version: "1.0.0",
      native_runtime_version: "1.0.0",
      supported_manifest_sources: [],
      remote_updates: []
    }) -- [:__struct__]

    assert Enum.sort(fields) == Enum.sort([
      :manifest_schema_version,
      :bridge_protocol_version,
      :native_runtime_version,
      :supported_manifest_sources,
      :remote_updates
    ])
  end
```

For RLINE-03 doctor rendering proofs, use `CaptureIO` over `mix crosswake.doctor` (same pattern as `capture_io(fn -> Mix.Task.reenable(...); Mix.Task.run(...) end)`).

**`ProofAssertions` API surface** (`test/support/proof_assertions.ex` lines 1-67):
- `stable_id_message/7` — returns formatted `[id] subject=... source=... observed=... path=... hint=... posture=...` string
- `assert_normalized_json_fixture/4` — normalizes JSON, strips volatile keys, compares to fixture file, fails with `stable_id_message` output
- `assert_file_exact/4` — reads a generated file, compares bytes, fails with `stable_id_message` output
- `assert_contains_exact/4` — reads a file, checks `String.contains?`, fails with `stable_id_message` output

---

## Shared Patterns

### `@derive Jason.Encoder` on typed structs
**Source:** `lib/crosswake/manifest/types.ex` — every typed row struct (`CapabilitySupportEntry` line 428, `PackageSurfaceEntry` line 464, `ReleaseBoundaryEntry` line 480, `ChangeClassEntry` line 500, `ActionClassEntry` line 527, `PromotionRuleEntry` line 559)
**Apply to:** `RuntimeLineRow` — required for JSON doctor output via `@derive Jason.Encoder`
```elixir
  @moduledoc false
  @derive Jason.Encoder
  @enforce_keys [...]
  defstruct [...]
```

### `atom_label/1` vs `Atom.to_string/1` serialization
**Source:** `lib/crosswake/manifest/types.ex`
- `PromotionRuleEntry.to_map/1` (lines 1153-1171) uses `atom_label/1` for proof-class atoms (`current_proof_class`, `promotes_to`)
- `CapabilitySupportEntry.to_map/1` (lines 1093-1111) uses `Atom.to_string/1` for other atom fields (`owner`)
**Apply to:** `required_verification_method` in `PromotionRuleEntry.to_map/1` → use `atom_label/1`; `verification_method` in `CapabilitySupportEntry.to_map/1` → use `Atom.to_string/1`; `evidence_tier` in `RuntimeLineRow.to_map/1` → use `Atom.to_string/1`

### Additive field back-compat (default, not enforced)
**Source:** `lib/crosswake/manifest/types.ex` — fields like `denial: nil`, `fallback: nil`, `guide: nil`, `prerequisites: []` in `CapabilitySupportEntry` (lines 440-443); `capabilities: %{}`, `installed_packs: %{}`, `payload: %{}` in `Bridge.Contract.Request` (lines 48-50)
**Apply to:** `CapabilitySupportEntry.verification_method`, `PromotionRuleEntry.required_verification_method`, `SupportMatrix.rebuild_matrix` — all must NOT be in `@enforce_keys`; must have safe defaults (`:none` or `[]`)

### Hermetic proof lane (no `@moduletag :requires_example_host`)
**Source:** `test/crosswake/proof/phase52_operator_truth_test.exs` line 1 — absent `@moduletag :requires_example_host`
**Contrast:** `test/crosswake/proof/phase5_proof_lane_test.exs` which DOES have `@moduletag :requires_example_host`
**Apply to:** `phase64_runtime_line_policy_test.exs` — hermetic, no external host tag

### `Enum.reject(fn {_key, value} -> is_nil(value) end) |> Map.new()` sparse map
**Source:** `lib/crosswake/manifest/types.ex` `to_map(%CapabilitySupportEntry{})` (lines 1109-1110), `to_map(%SupportEntry{})` (lines 1089-1090)
**Apply to:** `CapabilitySupportEntry.to_map/1` already uses this; `verification_method: :none` is NEVER nil so will always be present in the output — this is correct. Do NOT add a nil-check on `verification_method`.

---

## No Analog Found

All files have close codebase analogs. No entries in this category.

---

## Metadata

**Analog search scope:** `lib/crosswake/`, `test/crosswake/proof/`, `test/support/`
**Files scanned:** 9 analog files read directly
**Pattern extraction date:** 2026-06-03

**Key implementation order (from RESEARCH.md recommendation):**
1. Add `verification_method` type/field to `CapabilitySupportEntry` + `required_verification_method` to `PromotionRuleEntry` in `types.ex`
2. Add `RuntimeLineRow` struct + `new_runtime_line_row/1` + `to_map/1` clause to `types.ex`
3. Add `rebuild_matrix` field to `SupportMatrix` struct + `new_support_matrix/1` + `to_map/1` clause to `types.ex`
4. Implement `RebuildPolicy` module (`classify/2`, `diff/2`, `rebuild_required?/1`)
5. Add `@rebuild_matrix_rows` module attribute + `rebuild_matrix/1` accessor + evidence-tier validation to `support_matrix.ex`; add two Android promotion rows to `promotion_rule_entries/0`
6. Extend `release_policy_snapshot/1` in `doctor.ex` + both formatters
7. Write `phase64_runtime_line_policy_test.exs` hermetic proof lane
