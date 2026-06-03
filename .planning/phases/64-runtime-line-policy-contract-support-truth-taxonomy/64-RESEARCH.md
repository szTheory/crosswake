# Phase 64: Runtime-Line Policy Contract & Support-Truth Taxonomy — Research

**Researched:** 2026-06-03
**Domain:** Elixir typed-struct contracts, support-matrix policy derivation, doctor formatter parity
**Confidence:** HIGH (all findings verified against live codebase)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** New public module `Crosswake.RuntimeLine.RebuildPolicy` (name is planner discretion; preserve the `RuntimeLine` namespace). Derives classification from existing data — NOT a full static duplicate.

**D-02:** Capability-axis change classes (`capability_family_add`, `bridge_schema_change`, `permission_add`, `entitlement_add`, `push_capability_change`, `url_scheme_change`) derive from `Capability.rebuild`:
- `:native_required → {:rebuild_required, :native_shell}`
- `:companion_required → {:rebuild_required, :companion_shell}`
- `:none → :ota_safe`

**D-03:** System-level classes with no capability owner (`sdk_floor_bump`, `privacy_manifest_entry`) map via a locked `@system_rebuild_classes` module attribute. Closed set. NOT runtime-configurable.

**D-04:** Public API (exact signatures planner's discretion; preserve intent):
```elixir
@spec classify(change_class(), Capability.t() | nil) ::
        :ota_safe | {:rebuild_required, :native_shell | :companion_shell}
@spec diff(Root.t(), Root.t()) :: [{change_class(), verdict()}]
@spec rebuild_required?(Capability.rebuild()) :: boolean()
```

**D-05:** `native_runtime_version`-derivation proved hermeticaly in phase-64 proof test:
- Co-truth parity: `classify/2` agrees with `SupportMatrix.action_classes()` `rebuild_required` for every action class
- No-new-field assertion: `Compatibility` struct still has EXACTLY its current 5 fields and `manifest_schema_version` is unchanged

**D-06:** Footguns: (a) never classify by label alone — key off `Capability.rebuild`; (b) never treat `:companion_required` as OTA-safe; (c) `diff/2` classifies only, does not know if binary already shipped.

**D-07:** `verification_method` is a NEW orthogonal axis on `CapabilitySupportEntry`. Do NOT collapse into `proof_class`. `proof_class` answers "does this block merge?"; `verification_method` answers "what evidence backs this claim?"

**D-08:** Add typed `verification_method` to `CapabilitySupportEntry` (the claim), default `:none`. Add typed `required_verification_method` to `PromotionRuleEntry` (the gate). Keep existing `evidence_class` STRING field for back-compat.

**D-09:** Tier enum (weakest→strongest):
`:none | :provider_advisory | :jvm_hermetic | :emulator_advisory | :device_verified`
iOS entries = `:device_verified`; Android = `:jvm_hermetic` (CI-only).

**D-10:** CI-only-never-device invariant: construction/validation rejects `:device_verified` on CI-only entries; formatter renders `:jvm_hermetic` as `"jvm-hermetic (CI only)"` and `"device-verified"` only for genuine `:device_verified`.

**D-11:** Do NOT add `verification_method` to per-platform baseline `SupportEntry` rows (`:phoenix`/`:ios`/`:android`/`:shells`). Only on `CapabilitySupportEntry` + `PromotionRuleEntry`.

**D-12:** New struct `Crosswake.Manifest.Types.RuntimeLineRow` (`@derive Jason.Encoder`, `@enforce_keys`). Added to `SupportMatrix` as a `rebuild_matrix` field populated from `@rebuild_matrix_rows` module attribute — same lifecycle as `@change_class_entries`.

**D-13:** Accessor `@spec rebuild_matrix(SupportMatrix.t()) :: [Types.RuntimeLineRow.t()]` mirroring `capability_families/1` exactly (1-arity, no options, no computed projection).

**D-14:** Granularity: one row per major runtime-line band (`"1.x"`, `"2.x"`). Columns: `runtime_line`, `capability_surface` (`[String.t()]`), `change_class`, `ota_safe` (bool), `rebuild_required` (bool), `evidence_tier`.

**D-15:** Cross-seam reconciliation: matrix DISPLAYS other two seams, does NOT re-decide them. `evidence_tier` reuses the same `verification_method` enum from D-09.

**D-16:** Doctor rendering: new `rebuild & compatibility matrix:` block UNDER existing `release policy:` section in BOTH formatters. Human/JSON parity by shared traversal of `[RuntimeLineRow.t()]`. Add `evidence posture:` line so operator sees `ios=device-verified  android=jvm-hermetic (CI only)`.

**D-17:** Extend `SupportMatrix.promotion_rules()` with TWO new `PromotionRuleEntry` rows. Bind to D-09 taxonomy via `required_verification_method`.

**D-18:** `shell.android.jvm_hermetic` row: `required_verification_method: :jvm_hermetic`, `promotes_to: :merge_blocking`, `minimum_consecutive_passes: 3`, `freshness_window: "current release branch, within 30 CI runs"`, `failure_budget: "zero consecutive failures; single failure resets counter"`.

**D-19:** `shell.android.device_verified` row: `required_verification_method: :device_verified`. `demotion_trigger` prose states device/emulator proof is unavailable until Phases 67/68 and jvm_hermetic promotion MUST NOT be read as device_verified.

**D-20:** Phase 64 AUTHORS criteria as data only. Android `SupportEntry.status`/`proof_status` stays `:verification_required`. Do NOT promote Android in Phase 64.

### Claude's Discretion

- Exact module/struct/function names (`RebuildPolicy` vs `Policy`, `RuntimeLineRow`, accessor names, `verification_method`/`required_verification_method` spellings) — preserve locked semantics.
- Exact `change_class()` atom spellings and `@system_rebuild_classes` representation.
- Exact `PromotionRuleEntry` field population, `check_ids`, telemetry/check identifiers, and `demotion_trigger` prose.
- Test file placement and proof-lane naming (follow `test/crosswake/proof/phaseNN_*` conventions).
- Whether `verification_method` validation lives in a constructor guard vs. `SupportMatrix.validate/1` clause.

### Deferred Ideas (OUT OF SCOPE)

- Native shell code, iOS/Android permission/entitlement + runtime-line generator templates, `ADOPT:` markers, placeholder/drift doctor checks, Xcode 26 CI — Phase 66.
- Native shell implementation mirroring these contracts, Android toolchain floor bumps, and the actual merge-blocking JVM-hermetic CI proof lane — Phase 67.
- Advisory emulator lane + device-UAT checklist — Phase 68.
- Merge-blocking manifest↔shell↔guide↔doctor parity gate, guides parity-locked to live truth, actual Android `:verification_required → :supported` promotion, `mix closeout.verify` — Phase 69.
- Diagnostic export seam — Phase 65.
- Nyquist validation-ledger cleanup for Phases 59/60/62/63 — handle alongside v4.0 validation, not inside Phase 64.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RLINE-01 | Adopters can determine, for any manifest/capability/shell change, whether it is OTA-safe or requires a native rebuild, classified per change class (8 classes). | `RebuildPolicy.classify/2` derives from `Capability.rebuild`; `@system_rebuild_classes` covers SDK/privacy classes. |
| RLINE-02 | Rebuild/OTA policy derives from existing `native_runtime_version` axis without a new manifest schema field or `manifest_schema_version` bump. | `Compatibility` struct has exactly 5 fields (verified below); proof test asserts no new field added. |
| RLINE-03 | Operators can view a rebuild & compatibility matrix through `SupportMatrix` and `mix crosswake.doctor`. | `@rebuild_matrix_rows` + `rebuild_matrix/1` accessor + `format_rebuild_matrix/1` in both formatters. |
| RLINE-04 | Support truth distinguishes `:jvm_hermetic` from `:device_verified` and never reports CI-only evidence as device-verified. | New `verification_method` atom field on `CapabilitySupportEntry`; formatter + validation invariant. |
| RLINE-05 | Android support state carries explicit, documented promotion criteria for moving from `:verification_required` to `:supported`. | Two new `PromotionRuleEntry` rows in `promotion_rules()`. |
</phase_requirements>

---

## Summary

Phase 64 is a pure Elixir contract phase — no native code, no new hex deps, no manifest schema bump. It locks three interrelated contracts (rebuild policy derivation, evidence taxonomy, compatibility matrix) by adding one new module, one new struct, two new typed fields, and two new data rows to existing structures.

The primary risk is evidence-laundering: any code path that promotes `:jvm_hermetic` to `:device_verified`, or that renders CI-only proof as device-verified in doctor output, would violate the core design invariant. All four locked decisions are mutually reinforcing: the `verification_method` axis (D-07–D-11) feeds directly into the `evidence_tier` column of `RuntimeLineRow` (D-12–D-16), and both are asserted by the same proof lane.

The integration surface is narrow and additive. Every new element has an exact existing template in the codebase: `RuntimeLineRow` follows `ReleaseBoundaryEntry`/`ChangeClassEntry` house style; `rebuild_matrix/1` mirrors `capability_families/1`; `format_rebuild_matrix/1` mirrors `format_change_classes/1`; the two Android `PromotionRuleEntry` rows follow the `shell.ios.generated_project` / `shell.android.generated_project` precedents exactly.

**Primary recommendation:** Implement in this order — (1) add `verification_method` type + field to `CapabilitySupportEntry` + `required_verification_method` to `PromotionRuleEntry`, (2) add `RuntimeLineRow` struct to `types.ex` + `@enforce_keys` + `new_runtime_line_row/1` constructor, (3) implement `RebuildPolicy` module, (4) add `@rebuild_matrix_rows` + `rebuild_matrix` field + `rebuild_matrix/1` to `SupportMatrix`, (5) add two Android promotion rows, (6) extend both formatters, (7) write the phase-64 hermetic proof lane.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Rebuild/OTA classification (RLINE-01) | Elixir library (`RebuildPolicy`) | `SupportMatrix` (co-truth parity) | Policy lives in the Elixir contract layer; native shells only mirror it |
| No-new-field proof (RLINE-02) | Test proof lane | `Compatibility` struct (fixed shape) | Mechanical struct-field assertion; no runtime component |
| Rebuild & compatibility matrix (RLINE-03) | `SupportMatrix` typed-row list | `Doctor.Formatter` + `Doctor.JSONFormatter` (render) | Data is in the matrix; rendering is in doctor |
| Evidence taxonomy (RLINE-04) | `CapabilitySupportEntry` field | `SupportMatrix.validate/1` + formatter | Claim lives on the entry struct; invariant enforced at construction/validation + render |
| Android promotion criteria (RLINE-05) | `SupportMatrix.promotion_rules()` data rows | `PromotionRuleEntry` struct (gate field) | Criteria-as-code in the same `promotion_rule_entries/0` private function |

---

## Standard Stack

No new external packages. All work is within the existing Crosswake Elixir library.

### Existing Modules Being Extended

| Module | File | Change |
|--------|------|--------|
| `Crosswake.Manifest.Types` | `lib/crosswake/manifest/types.ex` | Add `RuntimeLineRow` struct + `new_runtime_line_row/1` + `to_map/1` clause; add `verification_method` field to `CapabilitySupportEntry`; add `required_verification_method` field to `PromotionRuleEntry`; add `rebuild_matrix` field to `SupportMatrix` |
| `Crosswake.SupportMatrix` | `lib/crosswake/support_matrix/support_matrix.ex` | Add `@rebuild_matrix_rows` module attribute + `rebuild_matrix/1` accessor + two Android `PromotionRuleEntry` rows; update `validate/1` for `verification_method` CI-only invariant |
| `Crosswake.Doctor.Formatter` | `lib/crosswake/doctor/formatter.ex` | Add `format_rebuild_matrix/1` + `evidence posture:` line to `format_release_policy/1` |
| `Crosswake.Doctor.JSONFormatter` | `lib/crosswake/doctor/json_formatter.ex` | Add `rebuild_matrix` + `evidence_posture` keys to `format_release_policy/1` |
| `Crosswake.Doctor` | `lib/crosswake/doctor/doctor.ex` | Expose `rebuild_matrix` + `evidence_posture` in `release_policy_snapshot/1` |

### New Module

| Module | File |
|--------|------|
| `Crosswake.RuntimeLine.RebuildPolicy` | `lib/crosswake/runtime_line/rebuild_policy.ex` |

### Proof Test

| File | Type |
|------|------|
| `test/crosswake/proof/phase64_runtime_line_policy_test.exs` | Hermetic merge-blocking proof |

---

## Package Legitimacy Audit

No external packages are installed in this phase.

**Packages removed due to slopcheck verdict:** none
**Packages flagged as suspicious:** none

---

## Architecture Patterns

### System Architecture Diagram

```
Capability.rebuild field (:none | :native_required | :companion_required)
         │
         ▼
Crosswake.RuntimeLine.RebuildPolicy.classify/2
         │  ↑ co-truth parity assertion (proof test)
         │  └─ SupportMatrix.action_classes() [ActionClassEntry.rebuild_required]
         │
         ├──[capability-axis]──► :ota_safe | {:rebuild_required, :native_shell | :companion_shell}
         │
         └──[system-axis]──► @system_rebuild_classes (:sdk_floor_bump, :privacy_manifest_entry)
                              → {:rebuild_required, :native_shell}

CapabilitySupportEntry.verification_method  ←─ new orthogonal field (atom enum)
         │
         ├── :jvm_hermetic (Android today)
         └── :device_verified (iOS today)
         
         Construction invariant: :device_verified requires real-device evidence artifact
         Validation invariant: SupportMatrix.validate/1 rejects :device_verified on CI-only entry

RuntimeLineRow (new struct in types.ex)
    runtime_line :: String.t()       ("1.x", "2.x")
    capability_surface :: [String.t()]
    change_class :: String.t()
    ota_safe :: boolean()
    rebuild_required :: boolean()
    evidence_tier :: verification_method()  ← reuses D-09 enum, no new type
         │
         ▼
SupportMatrix.rebuild_matrix/1 (1-arity accessor, no options)
         │
         ▼
Doctor.release_policy_snapshot/1 (adds rebuild_matrix + evidence_posture to map)
         │
         ├── Formatter.format_release_policy/1
         │     "release policy:"
         │       "  native_runtime_version=1.0.0"
         │       "  evidence posture: ios=device-verified  android=jvm-hermetic (CI only)"
         │       "  rebuild & compatibility matrix:"
         │         "    runtime_line  ota_safe  rebuild_required  evidence_tier  capability_surface"
         │
         └── JSONFormatter.format_release_policy/1
               { "native_runtime_version": ...,
                 "evidence_posture": { "ios": "device-verified", "android": "jvm-hermetic (CI only)" },
                 "rebuild_matrix": [ { "runtime_line": "1.x", ... } ] }

promotion_rules() [in SupportMatrix]
    existing rows: shell.ios.generated_project, shell.android.generated_project, ...
    NEW row: shell.android.jvm_hermetic  (required_verification_method: :jvm_hermetic)
    NEW row: shell.android.device_verified  (required_verification_method: :device_verified, GATED)
```

### Recommended Project Structure

```
lib/
├── crosswake/
│   ├── manifest/
│   │   └── types.ex              # Add RuntimeLineRow, CapabilitySupportEntry.verification_method,
│   │                              #   PromotionRuleEntry.required_verification_method,
│   │                              #   SupportMatrix.rebuild_matrix field
│   ├── runtime_line/
│   │   └── rebuild_policy.ex     # NEW — classify/2, diff/2, rebuild_required?/1
│   ├── support_matrix/
│   │   └── support_matrix.ex     # @rebuild_matrix_rows + rebuild_matrix/1 + 2 Android promo rows
│   └── doctor/
│       ├── doctor.ex             # release_policy_snapshot/1 adds rebuild_matrix + evidence_posture
│       ├── formatter.ex          # format_rebuild_matrix/1 + evidence posture line
│       └── json_formatter.ex     # rebuild_matrix + evidence_posture keys
test/
└── crosswake/
    └── proof/
        └── phase64_runtime_line_policy_test.exs  # NEW hermetic proof lane
```

### Pattern 1: Existing Typed-Row-List + Accessor Template

The `@change_class_entries` attribute + `change_classes/1` accessor is the EXACT template for `@rebuild_matrix_rows` + `rebuild_matrix/1`. Verified in `support_matrix.ex`:

```elixir
# Source: lib/crosswake/support_matrix/support_matrix.ex lines 818-879 (action_class_entries)
# and lib/crosswake/support_matrix/support_matrix.ex lines 388-399 (accessors)

# Template accessor (from capability_families/1 which RuntimeLineRow must mirror):
@spec capability_families(SupportMatrix.t()) :: [CapabilitySupportEntry.t()]
def capability_families(%SupportMatrix{} = support_matrix),
  do: support_matrix.capability_families

# Follow this shape exactly:
@spec rebuild_matrix(SupportMatrix.t()) :: [Types.RuntimeLineRow.t()]
def rebuild_matrix(%SupportMatrix{} = support_matrix),
  do: support_matrix.rebuild_matrix
```

### Pattern 2: RuntimeLineRow Struct Template

Mirror `ReleaseBoundaryEntry` and `ChangeClassEntry` (both use `@derive Jason.Encoder`, `@enforce_keys`, `new_*/1` constructor, `to_map/1` clause):

```elixir
# Source: lib/crosswake/manifest/types.ex lines 478-524

# Template (ReleaseBoundaryEntry):
defmodule ReleaseBoundaryEntry do
  @moduledoc false
  @derive Jason.Encoder

  @enforce_keys [:target, :versioning, :compatibility_contract, :release_rule]
  defstruct [:target, :versioning, :compatibility_contract, :release_rule]

  @type t :: %__MODULE__{...}
end

# New RuntimeLineRow must follow this same shape exactly:
defmodule RuntimeLineRow do
  @moduledoc false
  @derive Jason.Encoder

  @enforce_keys [:runtime_line, :capability_surface, :change_class, :ota_safe, :rebuild_required, :evidence_tier]
  defstruct [:runtime_line, :capability_surface, :change_class, :ota_safe, :rebuild_required, :evidence_tier]

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

### Pattern 3: CapabilitySupportEntry Additive Field

Current `CapabilitySupportEntry` (verified, lines 426-460 in types.ex):
```elixir
# @enforce_keys [:family, :owner, :package_class, :proof_class, :rebuild]
# defstruct has: :family, :owner, :posture, :baseline_status, :proof_status,
#            :package_class, :proof_class, :rebuild,
#            prerequisites: [], denial: nil, fallback: nil, guide: nil
# @derive Jason.Encoder is PRESENT
```

Add `verification_method` with default `:none` (NOT in `@enforce_keys` — additive, back-compat):
```elixir
# Additive field — no @enforce_keys change needed
defstruct [
  ...,  # existing fields unchanged
  verification_method: :none   # NEW — default :none preserves back-compat
]
```

The `to_map/1` clause for `CapabilitySupportEntry` (lines 1093-1111) must add:
```elixir
"verification_method" => Atom.to_string(support_entry.verification_method)
```

### Pattern 4: PromotionRuleEntry Additive Field

Current `PromotionRuleEntry` (verified, lines 557-614 in types.ex) has these `@enforce_keys`:
`:claim_id, :claim_scope, :current_proof_class, :promotes_to, :evidence_class, :required_evidence, :minimum_consecutive_passes, :freshness_window, :failure_budget, :required_platforms, :required_docs_anchors, :change_class, :action_class, :check_ids, :demotion_trigger`

Add `required_verification_method` as a non-enforced field with default `:none`:
```elixir
defstruct [
  ..., # all existing fields unchanged
  required_verification_method: :none  # NEW — not in @enforce_keys
]
```

The `new_promotion_rule_entry/1` constructor (lines 886-904) must handle:
```elixir
required_verification_method: Keyword.get(attrs, :required_verification_method, :none)
```

The `to_map/1` clause for `PromotionRuleEntry` (lines 1153-1171) must add:
```elixir
"required_verification_method" => atom_label(entry.required_verification_method)
```

### Pattern 5: Doctor `release_policy_snapshot/1` Extension

Current `release_policy_snapshot/1` (lines 1186-1203 in doctor.ex) returns a map with keys:
`crosswake_version, manifest_schema_version, bridge_protocol_version, native_runtime_version, package_version_truth, companion_requirement, capability_families, package_surfaces, release_boundaries, change_classes`

Extend it to also include:
```elixir
rebuild_matrix: SupportMatrix.rebuild_matrix(support_matrix),
evidence_posture: evidence_posture_snapshot(support_matrix)
```

Where `evidence_posture_snapshot/1` derives from the `rebuild_matrix` rows' `evidence_tier` values grouped by platform.

### Pattern 6: Formatter Section-Rendering Template

The `format_change_classes/1` in `formatter.ex` (lines 141-148) is the exact template for `format_rebuild_matrix/1`:

```elixir
# Source: lib/crosswake/doctor/formatter.ex lines 141-148
defp format_change_classes(classes) do
  lines =
    Enum.map(classes, fn change_class ->
      "    #{change_class.change_class}: signal=\"#{change_class.compatibility_signal}\", proof=\"#{change_class.required_proof}\""
    end)
  ["  change classes:" | lines] |> Enum.join("\n")
end

# Template for new:
defp format_rebuild_matrix(rows) do
  lines = Enum.map(rows, fn row ->
    "    #{row.runtime_line}: ota_safe=#{row.ota_safe}, rebuild_required=#{row.rebuild_required}, evidence_tier=#{format_evidence_tier(row.evidence_tier)}, capability_surface=[#{Enum.join(row.capability_surface, ", ")}]"
  end)
  ["  rebuild & compatibility matrix:" | lines] |> Enum.join("\n")
end

defp format_evidence_tier(:jvm_hermetic), do: "jvm-hermetic (CI only)"
defp format_evidence_tier(:device_verified), do: "device-verified"
defp format_evidence_tier(tier), do: Atom.to_string(tier)
```

The `evidence posture:` line goes INSIDE `format_release_policy/1` alongside the other `"  native_runtime_version=..."` lines.

The JSON formatter follows the same shared-traversal approach as the human formatter — no independent serialization.

### Pattern 7: RebuildPolicy Contract Module Style

Mirror `Crosswake.Bridge.Contract` and `Crosswake.NativeEscape.Contract`: module-level `@moduledoc`, module attribute constants (`@system_rebuild_classes`), typed public API with `@spec`, narrow surface, private implementation helpers.

```elixir
# Source: lib/crosswake/bridge/contract.ex lines 1-22 (module + constants pattern)
# Source: lib/crosswake/native_escape/contract.ex lines 1-12 (protocol/version constants)

defmodule Crosswake.RuntimeLine.RebuildPolicy do
  @moduledoc """
  Policy contract deriving OTA-safe vs. rebuild-required classification from the
  existing `native_runtime_version` compatibility axis.

  Classification derives entirely from `Capability.rebuild` for capability-axis change
  classes and from a locked `@system_rebuild_classes` closed set for system-level
  change classes. No runtime configuration; new system classes go through a phase.
  """

  alias Crosswake.Manifest.Types.Capability
  alias Crosswake.Manifest.Types.Root

  @system_rebuild_classes [:sdk_floor_bump, :privacy_manifest_entry]

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
end
```

### Pattern 8: SupportMatrix.rebuild_matrix Field Addition

Current `Crosswake.Manifest.Types.SupportMatrix` struct (lines 362-396 in types.ex) has `@enforce_keys` and `defstruct` but does NOT include `rebuild_matrix`. It must be added with a default of `[]`:

```elixir
# Currently (verified):
@enforce_keys [
  :phoenix, :live_view, :ios, :android, :shells,
  :capability_families, :package_surfaces, :release_boundaries, :change_classes
]
defstruct phoenix: [], live_view: [], ios: [], android: [], shells: [],
          capability_families: [], package_surfaces: [], release_boundaries: [], change_classes: []

# After (add rebuild_matrix — NOT in @enforce_keys for back-compat):
defstruct phoenix: [], ..., change_classes: [],
          rebuild_matrix: []  # NEW — additive, default []
```

The `@type t` must also gain `rebuild_matrix: [Crosswake.Manifest.Types.RuntimeLineRow.t()]`.

The `to_map/1` clause for `SupportMatrix` (lines 1063-1075) must add:
```elixir
"rebuild_matrix" => Enum.map(support_matrix.rebuild_matrix, &to_map/1)
```

The `new_support_matrix/1` constructor (lines 793-805) must handle:
```elixir
rebuild_matrix: Keyword.get(attrs, :rebuild_matrix, [])
```

### Anti-Patterns to Avoid

- **Classifying by change-class label string alone:** The correct source of truth is `Capability.rebuild`. Classifying `:capability_family_add` as rebuild-required without checking `Capability.rebuild == :native_required | :companion_required` is the Expo EAS / CodePush "it's just JS → silent OTA break" failure mode (D-06a).
- **Treating `:companion_required` as OTA-safe:** A companion binary rebuild is still a rebuild (D-06b). `:companion_required → {:rebuild_required, :companion_shell}`, not `:ota_safe`.
- **`diff/2` as a release gate oracle:** `diff/2` classifies changes; it does not know whether a binary with the new `native_runtime_version` already shipped. Do not use it as a release gate (D-06c).
- **Collapsing `verification_method` into `proof_class`:** `proof_class` answers "does this block merge?"; `verification_method` answers "what evidence backs this claim?" Collapsing them is badge inflation / evidence laundering (D-07). SLSA provenance levels, Apple notarization vs. TestFlight, CI vs. device test pyramid all keep these separate.
- **Implicit `:device_verified` promotion in the formatter:** The formatter renders `:jvm_hermetic` as `"jvm-hermetic (CI only)"` — never silently upgrade it to `"device-verified"` (D-10).
- **Version-keyed map instead of typed row list:** A `%{"1.x" => row}` map form was explicitly rejected (D-12) — it breaks the uniform typed-struct convention and creates two independent serialization paths that can drift.
- **Adding `verification_method` to `SupportEntry` (the platform baseline rows):** D-11 is explicit — this distinction only applies to `CapabilitySupportEntry` and `PromotionRuleEntry`.
- **Serialization drift between human and JSON formatters:** Both must traverse the same `[RuntimeLineRow.t()]` list. Any independent JSON serialization of the matrix that duplicates formatting logic will drift (D-16).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| OTA-vs-rebuild classification | Custom rebuild registry or map | Derive from `Capability.rebuild` field | The `rebuild` field is already the source of truth on every `Capability.t()` in the manifest registry; duplicating it is the drift vector |
| Evidence tier labeling | New enum or string table | The existing `Capability.rebuild` atom enum pattern + the D-09 verification_method enum | Matches the existing `proof_class`, `status`, and `rebuild` atom vocabulary used throughout types.ex |
| Human/JSON formatter parity | Separate serialization code per formatter | Shared traversal of `[RuntimeLineRow.t()]` list in doctor.ex then passed to both formatters | The formatters already do this for capability_families, change_classes, release_boundaries — same lifecycle |
| Promotion criteria prose | Free-text in guides | `PromotionRuleEntry` data rows with `required_evidence`, `minimum_consecutive_passes`, `freshness_window`, `failure_budget`, `demotion_trigger` | Criteria-as-code is the established idiom; prose lives in the struct fields |

**Key insight:** Every new element in this phase has an exact existing template. The planner must FIND and MIRROR the template, not design from scratch.

---

## Exact Code Shapes (Verified Against Live Codebase)

### `Compatibility` Struct — Complete Field List (RLINE-02 proof target)

Verified at `lib/crosswake/manifest/types.ex` lines 78-105:

```elixir
@enforce_keys [
  :manifest_schema_version,   # 1
  :bridge_protocol_version,   # 2
  :native_runtime_version,    # 3
  :supported_manifest_sources, # 4
  :remote_updates             # 5
]
defstruct [
  :manifest_schema_version,
  :bridge_protocol_version,
  :native_runtime_version,
  :remote_updates,
  supported_manifest_sources: [:bundled, :cached, :remote]
]
```

**EXACTLY 5 fields.** The no-new-field proof test must assert this count and enumerate the exact field names. `manifest_schema_version` value must also be asserted as unchanged (currently `"1.0.0"` at line 617).

### `ActionClassEntry.rebuild_required` — Co-truth Source

Verified at `lib/crosswake/manifest/types.ex` lines 526-555 and `lib/crosswake/support_matrix/support_matrix.ex` lines 818-879. The `action_classes()` function returns 6 entries:
- `"docs_only"` → `rebuild_required: false`
- `"route_manifest"` → `rebuild_required: false`
- `"compatibility"` → `rebuild_required: false`
- `"native_shell"` → `rebuild_required: true`
- `"companion_native"` → `rebuild_required: true`
- `"provider_adapter"` → `rebuild_required: true`

The `classify/2` co-truth parity proof asserts that for every entry where `rebuild_required: true`, the corresponding capability-axis classification is `{:rebuild_required, _}` and for `rebuild_required: false`, the classification is `:ota_safe`.

### Existing Android `promotion_rules()` Row Template

Verified at `lib/crosswake/support_matrix/support_matrix.ex` lines 905-921:

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

The new `shell.android.jvm_hermetic` and `shell.android.device_verified` rows follow this same structure and are added to the same `promotion_rule_entries/0` private function. They ALSO need `required_verification_method:` field (new additive field).

### `validate_promotion_rule_rows/1` Validation Guards

Verified at `lib/crosswake/support_matrix/support_matrix.ex` lines 774-816. The validator checks:
1. `entry.action_class` is in the `action_classes()` known set
2. `entry.required_evidence != []` AND `entry.required_docs_anchors != []` AND `entry.check_ids != []`
3. `entry.demotion_trigger` is not `nil` or empty string

The new rows must satisfy all three. The `validation_method` invariant (`validate_verification_method/1`) is a NEW validation clause to add.

### Doctor `release_policy_snapshot/1` — Current Full Shape

Verified at `lib/crosswake/doctor/doctor.ex` lines 1186-1203:

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

Add to this map: `rebuild_matrix: SupportMatrix.rebuild_matrix(support_matrix)` and `evidence_posture: evidence_posture_snapshot(support_matrix)`.

### Formatter `format_release_policy/1` — Current Full Pattern Clauses

Verified at `lib/crosswake/doctor/formatter.ex` lines 60-108. There are TWO clauses: one full (with capability_families, package_surfaces, release_boundaries, change_classes) and one minimal (just the 6 version/policy lines). The new `evidence posture:` line and `rebuild & compatibility matrix:` block must be added to the FULL clause only (matching the release_policy map shape from doctor.ex).

The JSON formatter `format_release_policy/1` at lines 103-116 only includes a subset of fields (not capability_families). The new `rebuild_matrix` and `evidence_posture` keys should be added here.

### `compatible_version?/2` — For Proof Reference Only

Verified at `lib/crosswake/compatibility/compatibility.ex` lines 616-627:
```elixir
defp compatible_version?(available, required)
     when is_binary(available) and is_binary(required) do
  case {normalize_version(available), normalize_version(required)} do
    {{:ok, normalized_available}, {:ok, normalized_required}} ->
      Version.compare(normalized_available, normalized_required) != :lt
    _other ->
      available == required
  end
end
```

No changes to `Compatibility` module — reference only.

---

## Common Pitfalls

### Pitfall 1: Evidence Laundering via `verification_method` Default

**What goes wrong:** If the default for `verification_method` on `CapabilitySupportEntry` is `:jvm_hermetic` instead of `:none`, every existing iOS capability entry silently gets a weaker evidence label than its actual `:device_verified` posture.

**Why it happens:** Choosing a "safe" default that seems reasonable but under-claims evidence for entries that already have device proof.

**How to avoid:** Default must be `:none`. iOS entries explicitly set `:device_verified` in `SupportMatrix.canonical/1`. The proof lane checks that iOS capability entries with `:device_verified` are not rendering as `:jvm_hermetic`.

**Warning signs:** Any test that renders iOS doctor output and does NOT see `device-verified`.

### Pitfall 2: `SupportMatrix.SupportMatrix` Field Addition Breaking Constructor

**What goes wrong:** Adding `rebuild_matrix` to `@enforce_keys` breaks every `new_support_matrix/1` call that doesn't pass `rebuild_matrix:`.

**Why it happens:** Looking at other `@enforce_keys` entries and assuming new fields follow the same pattern.

**How to avoid:** Do NOT add `rebuild_matrix` to `@enforce_keys`. It is a defaulted field like `capability_families: []`. The `new_support_matrix/1` constructor handles it with `Keyword.get(attrs, :rebuild_matrix, [])`.

**Warning signs:** Compile error `KeyError: key :rebuild_matrix not found` in any `new_support_matrix/1` call site.

### Pitfall 3: `PromotionRuleEntry` New Row Validation Failure

**What goes wrong:** The new Android promotion rows fail `validate_promotion_rule_rows/1` because `required_evidence`, `required_docs_anchors`, or `check_ids` are empty, or `demotion_trigger` is nil.

**Why it happens:** The D-18/D-19 data is specified in the CONTEXT.md but the validator is strict about non-empty lists.

**How to avoid:** Populate all three list fields and the `demotion_trigger` string in every new row. The `shell.android.device_verified` row must have a `demotion_trigger` that includes the Phase 67/68 gate prose from D-19.

**Warning signs:** `validate_promotion_rule_rows/1` returns errors in the doctor test.

### Pitfall 4: Human/JSON Formatter Divergence on `rebuild_matrix`

**What goes wrong:** The JSON formatter independently serializes `rebuild_matrix` rows with atom fields directly, while the human formatter converts them to strings — producing different field names or value formats between the two.

**Why it happens:** The JSON formatter has historically received the release_policy map fields differently from the human formatter (compare lines 103-116 vs. 60-108 in formatter/json_formatter). The `format_release_policy/1` clauses have different field subsets.

**How to avoid:** Both formatters must traverse `[RuntimeLineRow.t()]` from the same `release_policy.rebuild_matrix` list. Use the same `format_evidence_tier/1` display-string helper (or its equivalent) in both, not independent atom→string conversions.

**Warning signs:** Doctor human output renders `"jvm-hermetic (CI only)"` but JSON renders `"jvm_hermetic"` without the qualifier.

### Pitfall 5: `Capability.rebuild` Source Bypassed in `classify/2`

**What goes wrong:** `classify/2` receives a `change_class` atom and pattern-matches on the change-class label to decide rebuild (`e.g., :bridge_schema_change → {:rebuild_required, :native_shell}`) without checking the `Capability.t()` argument.

**Why it happens:** It's simpler to have a static lookup table by label. But it's wrong: the actual rebuild determination for capability-axis classes IS the `Capability.rebuild` field.

**How to avoid:** For the 6 capability-axis change classes, the classification must read `capability.rebuild` and branch on `:native_required | :companion_required | :none`. The `capability` arg in `classify/2` is nil only for system-level classes (`sdk_floor_bump`, `privacy_manifest_entry`), where `@system_rebuild_classes` applies.

**Warning signs:** A capability with `rebuild: :none` added as a `capability_family_add` gets classified as `{:rebuild_required, _}`.

---

## Runtime State Inventory

This is a greenfield contracts phase — no rename/migration/refactor. No existing runtime state is modified.

**Stored data:** None — no Mem0 records, ChromaDB collections, or databases reference runtime-line or verification-method identifiers.
**Live service config:** None — no n8n workflows, Datadog service names, or Tailscale ACL tags affected.
**OS-registered state:** None — no Task Scheduler tasks, pm2 processes, or launchd plists affected.
**Secrets/env vars:** None — no SOPS keys or env var names change.
**Build artifacts:** None — no egg-info directories, compiled binaries, or npm globals affected.

---

## Validation Architecture

Nyquist validation is enabled (`workflow.nyquist_validation: true` in config.json).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (existing, no install needed) |
| Config file | `test/test_helper.exs` (existing) |
| Quick run command | `mix test test/crosswake/proof/phase64_runtime_line_policy_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RLINE-01 | `classify/2` returns correct verdict for all 8 change classes | unit | `mix test test/crosswake/proof/phase64_runtime_line_policy_test.exs --only rline_01` | ❌ Wave 0 |
| RLINE-01 | `rebuild_required?/1` returns correct boolean for all 3 `Capability.rebuild` values | unit | `mix test test/crosswake/proof/phase64_runtime_line_policy_test.exs --only rline_01` | ❌ Wave 0 |
| RLINE-02 | `Compatibility` struct has exactly 5 fields with enumerated names | proof | `mix test test/crosswake/proof/phase64_runtime_line_policy_test.exs --only rline_02` | ❌ Wave 0 |
| RLINE-02 | `manifest_schema_version` constant is unchanged | proof | `mix test test/crosswake/proof/phase64_runtime_line_policy_test.exs --only rline_02` | ❌ Wave 0 |
| RLINE-02 | `classify/2` agrees with `action_classes()` `rebuild_required` for every action class (co-truth parity) | proof | `mix test test/crosswake/proof/phase64_runtime_line_policy_test.exs --only rline_02` | ❌ Wave 0 |
| RLINE-03 | `SupportMatrix.rebuild_matrix/1` returns `[RuntimeLineRow.t()]` with expected runtime_line bands | unit | `mix test test/crosswake/proof/phase64_runtime_line_policy_test.exs --only rline_03` | ❌ Wave 0 |
| RLINE-03 | Doctor human output contains `"rebuild & compatibility matrix:"` block | integration | `mix test test/crosswake/proof/phase64_runtime_line_policy_test.exs --only rline_03` | ❌ Wave 0 |
| RLINE-03 | Doctor JSON output contains `"rebuild_matrix"` key with rows | integration | `mix test test/crosswake/proof/phase64_runtime_line_policy_test.exs --only rline_03` | ❌ Wave 0 |
| RLINE-03 | Doctor human and JSON render the same `rebuild_matrix` data (parity) | integration | `mix test test/crosswake/proof/phase64_runtime_line_policy_test.exs --only rline_03` | ❌ Wave 0 |
| RLINE-04 | `CapabilitySupportEntry` with `verification_method: :device_verified` renders as `"device-verified"` | unit | `mix test test/crosswake/proof/phase64_runtime_line_policy_test.exs --only rline_04` | ❌ Wave 0 |
| RLINE-04 | `CapabilitySupportEntry` with `verification_method: :jvm_hermetic` renders as `"jvm-hermetic (CI only)"` | unit | `mix test test/crosswake/proof/phase64_runtime_line_policy_test.exs --only rline_04` | ❌ Wave 0 |
| RLINE-04 | `SupportMatrix.validate/1` rejects `:device_verified` on a CI-only entry | unit | `mix test test/crosswake/proof/phase64_runtime_line_policy_test.exs --only rline_04` | ❌ Wave 0 |
| RLINE-04 | Doctor `evidence posture:` line renders `ios=device-verified  android=jvm-hermetic (CI only)` | integration | `mix test test/crosswake/proof/phase64_runtime_line_policy_test.exs --only rline_04` | ❌ Wave 0 |
| RLINE-05 | `promotion_rules()` contains `shell.android.jvm_hermetic` with `minimum_consecutive_passes: 3`, `required_verification_method: :jvm_hermetic` | proof | `mix test test/crosswake/proof/phase64_runtime_line_policy_test.exs --only rline_05` | ❌ Wave 0 |
| RLINE-05 | `promotion_rules()` contains `shell.android.device_verified` with `required_verification_method: :device_verified` and gating note in `demotion_trigger` | proof | `mix test test/crosswake/proof/phase64_runtime_line_policy_test.exs --only rline_05` | ❌ Wave 0 |
| RLINE-05 | Android `SupportEntry.status` stays `:verification_required` after Phase 64 changes | proof | `mix test test/crosswake/proof/phase64_runtime_line_policy_test.exs --only rline_05` | ❌ Wave 0 |
| RLINE-05 | `validate_promotion_rule_rows/1` passes for both new Android rows | unit | `mix test test/crosswake/proof/phase64_runtime_line_policy_test.exs --only rline_05` | ❌ Wave 0 |

### Proof Lane Structure

The `phase64_runtime_line_policy_test.exs` file must be a hermetic test (no `@moduletag :requires_example_host`) following the `phase52_operator_truth_test.exs` pattern. It uses `ExUnit.CaptureIO` to render doctor output and `Crosswake.TestSupport.ProofAssertions` for any fixture-based assertions.

```elixir
defmodule Crosswake.Proof.Phase64RuntimeLinePolicyTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  alias Crosswake.TestSupport.ProofAssertions
  alias Crosswake.RuntimeLine.RebuildPolicy
  alias Crosswake.SupportMatrix

  # RLINE-01: classify/2 and rebuild_required?/1
  # RLINE-02: co-truth parity + no-new-field assertion
  # RLINE-03: rebuild_matrix accessor + doctor rendering
  # RLINE-04: CI-only-never-device construction + render invariant
  # RLINE-05: Android promotion rows present and gated
end
```

### Sampling Rate

- **Per task commit:** `mix test test/crosswake/proof/phase64_runtime_line_policy_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `test/crosswake/proof/phase64_runtime_line_policy_test.exs` — covers all RLINE-01..05 assertions above

*(All other test infrastructure is in place — ExUnit, ProofAssertions, CaptureIO already used in phase52)*

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Atom enum validation in `SupportMatrix.validate/1`; guard clause in `RebuildPolicy.classify/2` |
| V6 Cryptography | no | — |

### Known Threat Patterns for This Phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Evidence laundering (CI-only labeled as device-verified) | Spoofing/Elevation | `SupportMatrix.validate/1` rejects `:device_verified` on CI-only entries; formatter uses explicit string conversion, not implicit atom promotion |
| Overclaiming rebuild safety (classifying by label, not `Capability.rebuild`) | Spoofing | `RebuildPolicy.classify/2` keys off `Capability.rebuild` field, not string label |
| Android support promotion before criteria pass | Elevation | D-20 is explicit: Android `SupportEntry.status` must stay `:verification_required` in Phase 64; the proof test asserts this |
| Serialization drift (human vs JSON doctor) | Information Disclosure | Shared traversal of `[RuntimeLineRow.t()]` enforced by the proof test comparing both outputs |

---

## Environment Availability

This phase is code/config changes only — no external dependencies beyond the existing Elixir/Mix toolchain.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | All | ✓ | Existing project | — |
| ExUnit | Proof lane | ✓ | Existing | — |
| Jason | `@derive Jason.Encoder` on new struct | ✓ | Existing hex dep | — |

**Missing dependencies with no fallback:** None.

---

## Assumptions Log

All claims in this research were verified directly against the live codebase. No assumed claims.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | — | — | — |

**All claims verified or cited against the live codebase files read in this session.**

---

## Open Questions

1. **`evidence_posture_snapshot/1` helper scope**
   - What we know: The doctor `release_policy_snapshot/1` needs to add `evidence_posture` derived from the `rebuild_matrix` rows' `evidence_tier` values grouped by platform.
   - What's unclear: Whether to derive this from the matrix rows (which have `evidence_tier` but not explicit platform keys) or from a separate lookup in `SupportMatrix` itself (e.g., a new `evidence_posture/0` accessor).
   - Recommendation: Planner's discretion per Claude's Discretion in D-03/D-14. A simple private helper in `doctor.ex` that reads the matrix rows and groups by platform is sufficient. Alternatively, a dedicated `SupportMatrix.evidence_posture/0` accessor returning `%{ios: :device_verified, android: :jvm_hermetic}` is cleaner — this is planner discretion.

2. **`@enforce_keys` on `RuntimeLineRow` vs. back-compat**
   - What we know: `@enforce_keys` means struct construction MUST supply all keys. `RuntimeLineRow` is a new struct with no existing call sites.
   - What's unclear: The CONTEXT says `@enforce_keys` — this is fine since it's new with no back-compat concern.
   - Recommendation: Use `@enforce_keys` for all 6 fields on `RuntimeLineRow` (consistent with all other `@derive Jason.Encoder` structs in types.ex that have `@enforce_keys`).

3. **Validation placement for `verification_method` invariant**
   - What we know: D-10 requires that `:device_verified` is never set without real-device evidence. Claude's Discretion covers whether this is a constructor guard or `validate/1` clause.
   - Recommendation: Add a `validate_verification_method_invariant/1` private clause to `SupportMatrix.validate/1` (consistent with `validate_promotion_rule_rows/1`, `validate_action_class_rows/1` pattern). The constructor defaults to `:none` which is always safe.

---

## Sources

### Primary (HIGH confidence — verified against live codebase)

- `lib/crosswake/manifest/types.ex` — complete struct shapes for `Compatibility`, `CapabilitySupportEntry`, `PromotionRuleEntry`, `SupportMatrix`, `ReleaseBoundaryEntry`, `ChangeClassEntry`, `ActionClassEntry`; all `new_*/1` constructors; all `to_map/1` clauses
- `lib/crosswake/support_matrix/support_matrix.ex` — `capability_families/1` accessor template; complete `promotion_rule_entries/0` with all existing rows; `action_class_entries/0` with all 6 entries and `rebuild_required` fields; `validate/1` structure; `@change_class_entries` and `@commerce_corridor_entries` module attribute pattern
- `lib/crosswake/doctor/doctor.ex` — `release_policy_snapshot/1` complete map shape; `support_posture/2`
- `lib/crosswake/doctor/formatter.ex` — `format_release_policy/1` full and minimal clauses; `format_change_classes/1` template; `format_release_boundaries/1` template
- `lib/crosswake/doctor/json_formatter.ex` — `format_release_policy/1` JSON shape; `format_support/1`
- `lib/crosswake/compatibility/compatibility.ex` — `compatible_version?/2` and `validate_native_runtime/4` signatures
- `lib/crosswake/bridge/contract.ex` — contract module style with `@protocol`, `@version`, typed structs, narrow public API
- `lib/crosswake/native_escape/contract.ex` — contract module style with module attribute constants
- `test/support/proof_assertions.ex` — available assertion helpers: `assert_normalized_json_fixture/4`, `assert_file_exact/4`, `assert_contains_exact/4`, `stable_id_message/6`
- `test/crosswake/proof/phase52_operator_truth_test.exs` — hermetic proof lane structure, use of `CaptureIO`, `ProofAssertions`, vocabulary/canonicality assertions
- `test/crosswake/proof/phase5_proof_lane_test.exs` — example of `@moduletag :requires_example_host` vs. hermetic distinction

### Secondary (MEDIUM confidence)

- `.planning/phases/64-runtime-line-policy-contract-support-truth-taxonomy/64-CONTEXT.md` — all 20 locked decisions verified against codebase
- `.planning/REQUIREMENTS.md` — RLINE-01..05 exact text
- `.planning/STATE.md` and `.planning/ROADMAP.md` — phase boundary and adjacency

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; all existing modules verified line-by-line
- Architecture: HIGH — all struct shapes, accessor patterns, and formatter sections verified directly
- Pitfalls: HIGH — derived from locked decisions (D-06, D-10, D-12) and verified code patterns
- Proof patterns: HIGH — verified against phase52, phase63, phase5 proof lane files

**Research date:** 2026-06-03
**Valid until:** This research reflects the exact state of the codebase at research time. Stable — no external dependencies change. Valid until Phase 64 is planned and implemented.
