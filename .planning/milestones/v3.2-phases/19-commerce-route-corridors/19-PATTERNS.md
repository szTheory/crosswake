## PATTERN MAPPING COMPLETE

# Phase 19 Pattern Map: Commerce Route Corridors

This map translates the Phase 19 change surface into concrete "copy this pattern" anchors from the current codebase, so planning and implementation stay additive and drift-resistant.

## Scope Snapshot

Likely modifications are concentrated in:

- Route DSL + policy compile/validate pipeline
- Manifest types/build/validate layers
- Runtime compatibility to denial mapping
- Support matrix + doctor truth surfaces
- Commerce/capabilities/support docs and parity tests

No mandatory net-new top-level modules are required by existing conventions; current patterns prefer additive extension inside the listed files.

## Non-Drift Rules (apply everywhere)

1. Keep corridor vocabulary provider-neutral (no StoreKit/PlayBilling terms in core schema/manifest keys or enums).
2. Keep validations layered: schema shape -> route semantics -> manifest referential/vocabulary -> runtime findings -> denial envelope.
3. Keep denials explicit and fail-closed with canonical code + non-empty fallback/recovery guidance.
4. Reuse registry+reference shape (`root registry` + `route ref`) rather than duplicating full objects per route.
5. Keep doctor/support/docs language synchronized to the same corridor terms and denial codes.

## Reusable Code Patterns (source excerpts)

### P1) Schema enum + custom validator style (`lib/crosswake/policy/schema.ex`)

```elixir
@runtime_values [:live_view, :offline_island, :native_screen]

runtime: [
  type: {:custom, __MODULE__, :validate_runtime, []},
  required: true,
  type_spec: quote(do: :live_view | :offline_island | :native_screen)
]
```

### P2) Route semantic gate with NimbleOptions error (`lib/crosswake/policy/route.ex`)

```elixir
defp validate_entry_policy(validated) do
  case {validated[:entry], validated[:runtime]} do
    {:external, :offline_island} ->
      {:error, validation_error(:entry, validated[:entry], "entry :external is not supported on offline_island routes")}
    _other ->
      {:ok, validated}
  end
end
```

### P3) Compiler hint mapping by message classification (`lib/crosswake/policy/compiler.ex`)

```elixir
defp validation_hint(error) do
  message = Exception.message(error)

  cond do
    String.contains?(message, "invalid value for :entry") ->
      "use entry: :internal_only | :external"
    true ->
      nil
  end
end
```

### P4) Validator pipeline + structured route errors (`lib/crosswake/policy/validator.ex`)

```elixir
[]
|> validate_runtime_offline(route)
|> validate_entry(route)
|> validate_capabilities(route)
|> validate_unique_list(route, :capabilities, route.capabilities)
```

### P5) Manifest root typed extension point (`lib/crosswake/manifest/types.ex`)

```elixir
defstruct [
  :manifest_schema_version,
  :crosswake_version,
  :generated_at,
  :host,
  :compatibility,
  :support_matrix,
  capability_registry: %{},
  pack_registry: %{},
  routes: %{}
]
```

### P6) Builder registry + route references (`lib/crosswake/manifest/builder.ex`)

```elixir
Types.new_root(
  capability_registry: capability_registry,
  pack_registry: pack_registry(routes),
  routes: route_entries(routes, managed_routes, host.origin)
)
```

### P7) Manifest referential check style (`lib/crosswake/manifest/validator.ex`)

```elixir
if Map.has_key?(pack_registry, pack_reference) do
  acc
else
  [%{key: :packs, route_id: route.id, message: "... outside the manifest pack registry"} | acc]
end
```

### P8) Stable denial envelope shape (`lib/crosswake/shell/denial.ex`)

```elixir
@enforce_keys [:reason, :code, :message]
defstruct [:reason, :code, :message, :hint, :route_id, details: %{}, recovery: %{}]
```

### P9) Finding axis -> denial mapping (`lib/crosswake/compatibility/compatibility.ex`)

```elixir
case finding.axis do
  :pack_version -> {:pack_incompatible, recovery_for(:pack_incompatible, opts), pack_details(finding, opts)}
  :origin -> {:origin_denied, %{}, %{}}
  _other -> {:compatibility_mismatch, recovery_for(:compatibility_mismatch, opts), %{}}
end
```

### P10) Canonical support matrix generation (`lib/crosswake/support_matrix/support_matrix.ex`)

```elixir
Types.new_support_matrix(
  phoenix: [...],
  live_view: [...],
  capability_families: capability_family_entries(capability_registry),
  package_surfaces: package_surface_entries()
)
```

### P11) Deterministic markdown rendering (`lib/crosswake/support_matrix/renderer.ex`)

```elixir
[
  "## Capability Families",
  "| Family | Owner | Posture | ... |",
  Enum.map_join(entries, "\n", &capability_row/1)
]
|> Enum.join("\n")
```

### P12) Doctor findings as structured checks (`lib/crosswake/doctor/doctor.ex`)

```elixir
%Check{
  severity: severity,
  code: code,
  check: check_name,
  message: message,
  hint: hint,
  details: details
}
```

## File-by-File Mapping (target -> closest analog -> reusable pattern)

### Runtime and Manifest Files

| Target file (Phase 19) | Closest analog | Reuse pattern |
|---|---|---|
| `lib/crosswake/policy/schema.ex` | Existing `packs` and `transfers` option schemas | Add `commerce` using P1 style (`{:custom, ...}` validator), normalize atom/string ids, and reject provider-specific vocab early. |
| `lib/crosswake/policy/route.ex` | Existing `validate_entry_policy/1`, `validate_pack_requirements/1` | Add `validate_commerce_*` semantic gates using P2; enforce corridor ref presence, role explicitness, and uniqueness/shape invariants. |
| `lib/crosswake/policy/compiler.ex` | Existing `validation_hint/1` + `validation_key/1` | Add corridor-specific key/hint rewrites using P3 so errors are actionable and consistent with other policy compile diagnostics. |
| `lib/crosswake/policy/validator.ex` | Existing route invariant pipeline | Extend pipeline via P4 style (`|> validate_commerce(route)`) for provider-neutral vocabulary and route-level ownership checks. |
| `lib/crosswake/manifest/types.ex` | Existing `Root`, `RouteEntry`, `CapabilitySupportEntry` additions | Add `commerce_corridors` root field and route commerce ref fields using P5 additive struct conventions and `to_map/1` atom->string boundary behavior. |
| `lib/crosswake/manifest/builder.ex` | Existing `capability_registry/1`, `pack_registry/1`, `route_entries/3` | Build corridor registry once at root and route refs in route entry using P6 registry+reference pattern. |
| `lib/crosswake/manifest/validator.ex` | Existing route pack/capability referential checks | Validate corridor existence/completeness/required fallback using P7 referential + required-field errors. |
| `lib/crosswake/shell/denial.ex` | Existing reason list + stable envelope | Add `:commerce_corridor` reason and keep envelope unchanged per P8; corridor denials still require explicit `code`, `details`, `recovery`. |
| `lib/crosswake/compatibility/compatibility.ex` | Existing `finding_to_denial/2` axis mapping | Introduce corridor-related finding axes and map to canonical `commerce.corridor.*` code taxonomy using P9. |
| `lib/crosswake/support_matrix/support_matrix.ex` | Existing capability-family support derivation | Add corridor support rows/metadata using P10 typed-entry generation and validation guards. |
| `lib/crosswake/support_matrix/renderer.ex` | Existing capability families table rendering | Add deterministic "commerce corridor" section using P11 table construction and guide-link formatting. |
| `lib/crosswake/doctor/doctor.ex` | Existing `check/6` posture findings | Add corridor prerequisite/denial/fallback checks using P12 structured finding shape. |
| `lib/crosswake/doctor/formatter.ex` | Existing support/release/capability print blocks | Add corridor summary lines in the same human-readable "keyword=value" style; avoid introducing new formatting dialects. |
| `lib/crosswake/doctor/json_formatter.ex` | Existing stable map serialization | Add corridor fields to JSON payload as additive keys only; keep existing envelope and status formatting untouched. |
| `guides/commerce.md` | Existing "Commerce Moment Map" + "Fallback Behavior" sections | Expand with explicit corridor declaration semantics and canonical denial code list; preserve provider-neutral language. |
| `guides/capabilities.md` | Existing ownership rubric and commerce boundaries | Add corridor-role linkage to ownership categories without changing capability-family public vocabulary. |
| `guides/support_matrix.md` | Generated output from renderer | Do not hand-edit; update renderer/support matrix source and keep file in lockstep via renderer test pattern. |

### Test Files

| Target test file (Phase 19) | Closest analog | Reuse pattern |
|---|---|---|
| `test/crosswake/policy/schema_test.exs` | Existing packs/transfers validation tests | Add positive + negative corridor DSL shape tests mirroring current "accepts typed ... / rejects ..." style. |
| `test/crosswake/policy/route_test.exs` | Existing semantic contradiction tests | Add route semantic tests for corridor role/ref presence and forbidden combos. |
| `test/crosswake/policy/compiler_test.exs` | Existing compile error/hint assertions | Add corridor compile failure coverage with assertion on helpful hint text and key classification. |
| `test/crosswake/manifest/manifest_test.exs` | Existing capability/pack registry + route reference tests | Add assertions for root `commerce_corridors` + route `corridor_ref`/role references and typed normalization. |
| `test/crosswake/manifest/validator_test.exs` | Existing referential and vocabulary rejection tests | Add failures for undeclared corridor refs, missing fallback metadata, and provider vocabulary leakage. |
| `test/crosswake/compatibility/compatibility_test.exs` | Existing `route_findings`/`finding_to_denial` tests | Add explicit checks for canonical `commerce.corridor.*` codes and fail-closed behavior. |
| `test/crosswake/shell/activation_test.exs` | Existing stable denial reason assertions | Extend denial reason/code assertions for corridor family and ensure non-empty recovery/fallback metadata. |
| `test/crosswake/support_matrix/support_matrix_test.exs` | Existing canonical matrix shape tests | Add corridor support section presence + narrowness assertions to prevent support truth drift. |
| `test/crosswake/support_matrix/renderer_test.exs` | Existing exact rendered section checks | Add "commerce corridor" table string expectations and keep generated guide equality assertions. |
| `test/crosswake/doctor/doctor_test.exs` | Existing structured finding checks | Add corridor prerequisite/denial/fallback findings with stable `code`, `check`, and details assertions. |
| `test/crosswake/doctor/formatter_test.exs` | Existing release-policy text rendering checks | Add corridor formatter output expectations (human-readable path). |
| `test/mix/tasks/crosswake_doctor_test.exs` | Existing CLI human/json output checks | Assert corridor findings appear in both human and JSON output modes. |
| `test/crosswake/guides/commerce_test.exs` | Existing keyword-presence guide tests | Add assertions for corridor declaration terms + canonical denial codes list. |
| `test/crosswake/guides/capabilities_test.exs` | Existing ownership/rubric guide tests | Add assertions for corridor-role guidance alignment with ownership-first rubric. |

## Practical Implementation Sequence (to minimize drift)

1. **Policy shape first:** `schema.ex` -> `route.ex` -> `compiler.ex` -> `validator.ex`.
2. **Manifest shape second:** `types.ex` -> `builder.ex` -> `validator.ex`.
3. **Runtime denial mapping:** `denial.ex` -> `compatibility.ex` -> `activation`-path tests.
4. **Truth surfaces:** support matrix + renderer -> doctor + formatters.
5. **Docs and parity tests:** guides + guide tests + renderer equality tests.

## High-Risk Drift Traps and Counter-Patterns

- **Trap:** put full corridor objects under each route entry.  
  **Counter-pattern:** root registry + route refs (P6/P7).
- **Trap:** add free-form denial strings in runtime code paths.  
  **Counter-pattern:** axis -> reason + canonical code mapping (P8/P9).
- **Trap:** doc wording diverges from doctor/support matrix terms.  
  **Counter-pattern:** generated sections + literal token assertions in tests.
- **Trap:** provider names leak into validation enums or guide examples.  
  **Counter-pattern:** provider-neutral vocabulary checks in policy + manifest validators.

## Ready-to-Use Checklist for Planner

- [ ] Every route with `commerce` has explicit corridor ref (or inline equivalent) and role.
- [ ] Manifest exposes root `commerce_corridors` and route-level corridor references.
- [ ] Manifest validator enforces corridor referential integrity and fallback completeness.
- [ ] Runtime corridor incompatibilities map to canonical `commerce.corridor.*` codes.
- [ ] Doctor/support/guides reuse same corridor/denial vocabulary.
- [ ] Guide files stay mechanically validated by tests (no silent wording drift).
