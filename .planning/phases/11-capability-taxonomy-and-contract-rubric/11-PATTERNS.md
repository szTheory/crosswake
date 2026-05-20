# Phase 11: Capability Taxonomy And Contract Rubric - Pattern Map

**Mapped:** 2026-05-19
**Files analyzed:** 10
**Analogs found:** 10 / 10

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality | Primary plan seam |
|---|---|---|---|---|---|
| `lib/crosswake/manifest/types.ex` | model | transform | `lib/crosswake/manifest/types.ex` | exact-self | 11-02 |
| `lib/crosswake/manifest/builder.ex` | service | transform | `lib/crosswake/manifest/builder.ex` | exact-self | 11-02 |
| `lib/crosswake/manifest/validator.ex` | utility | transform | `lib/crosswake/manifest/validator.ex` | exact-self | 11-02 |
| `lib/crosswake/bridge/registry.ex` | service | request-response | `lib/crosswake/bridge/registry.ex` | exact-self | 11-01 |
| `lib/crosswake/support_matrix/support_matrix.ex` | service | transform | `lib/crosswake/support_matrix/support_matrix.ex` | exact-self | 11-02 |
| `lib/crosswake/support_matrix/renderer.ex` | utility | file-I/O | `lib/crosswake/support_matrix/renderer.ex` | exact-self | 11-02 |
| `lib/crosswake/policy/schema.ex` | config | transform | `lib/crosswake/policy/schema.ex` | exact-self | 11-01 |
| `guides/bridge.md` | guide | request-response | `guides/bridge.md` | exact-self | 11-01 |
| `guides/native_shell.md` | guide | request-response | `guides/native_shell.md` | exact-self | 11-01 / 11-03 |
| `guides/support_matrix.md` | guide | file-I/O | `guides/support_matrix.md` | exact-self | 11-02 / 11-03 |

## Pattern Assignments

### `lib/crosswake/manifest/types.ex` (model, transform)

**Primary analog:** `lib/crosswake/manifest/types.ex`

**Typed struct expansion pattern** (`lib/crosswake/manifest/types.ex:102-114`, `131-163`, `267-295`):
```elixir
defmodule Capability do
  @enforce_keys [:id, :version]
  defstruct [:id, :version, status: :supported]
end

defmodule RouteEntry do
  @enforce_keys [:id, :path, :runtime]
  defstruct [..., capabilities: [], packs: [], sync: [], transfers: [], allowlisted_origins: []]
end

defmodule SupportEntry do
  @enforce_keys [:target, :version, :status]
  defstruct [:target, :version, :status, :proof, :notes, :boundary_link]
end
```

**Constructor pattern** (`lib/crosswake/manifest/types.ex:346-352`, `355-370`, `425-444`):
```elixir
def new_capability(attrs) when is_list(attrs) do
  struct!(Capability, %{id: ..., version: ..., status: ...})
end
```

**Serializer pattern** (`lib/crosswake/manifest/types.ex:482-487`, `499-513`, `556-576`):
```elixir
def to_map(%Capability{} = capability) do
  %{"id" => capability.id, "version" => capability.version, "status" => format_status(capability.status)}
end
```

**Likely modification seam:** extend `Capability` with family metadata here first, then thread the same fields through `new_capability/1` and `to_map/1`. Keep route entries lean; do not duplicate family metadata onto every route.

**Secondary analog:** `lib/crosswake/transfer/contracts.ex:17-50`, which shows the project’s pattern for introducing typed declaration structs without widening authority.

---

### `lib/crosswake/manifest/builder.ex` (service, transform)

**Primary analog:** `lib/crosswake/manifest/builder.ex`

**Registry derivation pattern** (`lib/crosswake/manifest/builder.ex:42-49`):
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

**Route entry assembly pattern** (`lib/crosswake/manifest/builder.ex:52-75`):
```elixir
entry =
  Types.new_route_entry(
    id: route.id,
    path: path,
    runtime: route.runtime,
    ...
    capabilities: route.capabilities,
    ...
  )
```

**Typed seam compilation analog** (`lib/crosswake/manifest/builder.ex:95-106`):
```elixir
defp transfer_seams(transfers) do
  Enum.map(transfers, fn transfer ->
    Types.new_transfer_seam(...)
  end)
end
```

**Likely modification seam:** replace the current flat `capability -> version` registry build with a canonical family catalog function that still derives route usage from declared ids. Follow the existing pattern: central registry truth, lean route entries, typed constructor calls.

**Secondary analog:** `lib/crosswake/transfer/contracts.ex:124-150`, where normalization produces canonical typed declarations from lighter caller input.

---

### `lib/crosswake/manifest/validator.ex` (utility, transform)

**Primary analog:** `lib/crosswake/manifest/validator.ex`

**Validation pipeline pattern** (`lib/crosswake/manifest/validator.ex:12-18`):
```elixir
def validate(%Types.Root{} = manifest) do
  []
  |> validate_top_level_sections(manifest)
  |> validate_compatibility(manifest.compatibility)
  |> validate_support_matrix(manifest.support_matrix)
  |> validate_routes(manifest.routes, manifest.capability_registry, manifest.pack_registry)
end
```

**Route-to-registry consistency pattern** (`lib/crosswake/manifest/validator.ex:94-113`):
```elixir
defp validate_route_capabilities(errors, route, capability_registry) do
  Enum.reduce(route.capabilities, errors, fn capability, acc ->
    if Map.has_key?(capability_registry, capability) do
      acc
    else
      [%{key: :capabilities, ...} | acc]
    end
  end)
end
```

**Canonical re-normalization pattern** (`lib/crosswake/manifest/validator.ex:145-248`):
```elixir
transfer.protocol != Contracts.protocol()
...
case Contracts.normalize_declaration(attrs) do
  {:ok, declaration} -> ...
  {:error, reason} -> ...
end
```

**Likely modification seam:** add capability-family vocabulary checks here, not in ad hoc docs or bridge code. This file is the right place to fail closed on invalid owner class, package class, proof class, rebuild expectation, or unsupported denial/fallback metadata.

**Secondary analogs:** `lib/crosswake/policy/route.ex:69-175` for cross-field semantic validation, and `lib/crosswake/shell/denial.ex:8-18` for stable denial vocabulary that capability metadata should reuse rather than invent around.

---

### `lib/crosswake/bridge/registry.ex` (service, request-response)

**Primary analog:** `lib/crosswake/bridge/registry.ex`

**Commands separate from registry entry pattern** (`lib/crosswake/bridge/registry.ex:11-22`, `68-78`):
```elixir
@capability_commands %{
  "app.info.get" => "app.info.get",
  "haptics.impact" => "haptics.impact",
  "files.pick" => "files.pick"
}

cond do
  capability_id = Map.get(@capability_commands, command) ->
    capability_entry(manifest, route, command, capability_id)
```

**Fail-closed lookup pattern** (`lib/crosswake/bridge/registry.ex:55-65`, `81-98`):
```elixir
with true <- command_supported?(command) || {:error, :unsupported_command},
     %RouteEntry{} = route <- Map.get(manifest.routes, route_id) || {:error, :inactive_route} do
  lookup_entry(manifest, route, command)
end
```

**Likely modification seam:** if Phase 11 needs family awareness, add it as metadata lookup against the manifest capability registry, not as new plugin-style command buckets. Preserve the existing split: public family semantics in manifest types, operation-level bridge commands here.

**Secondary analog:** `guides/bridge.md:3-15`, which states the same contract in public wording and explicitly forbids generic plugin-bus drift.

---

### `lib/crosswake/support_matrix/support_matrix.ex` (service, transform)

**Primary analog:** `lib/crosswake/support_matrix/support_matrix.ex`

**Canonical truth builder pattern** (`lib/crosswake/support_matrix/support_matrix.ex:12-67`):
```elixir
def canonical(opts \\ []) do
  Types.new_support_matrix(
    phoenix: [support_entry(...)],
    live_view: [support_entry(...)],
    ios: [support_entry(...)],
    android: [support_entry(...)],
    shells: [support_entry(...), support_entry(...)]
  )
end
```

**Strict narrowness guard pattern** (`lib/crosswake/support_matrix/support_matrix.ex:69-75`, `130-156`):
```elixir
[]
|> validate_categories_present(support_matrix)
|> validate_exact_statuses(support_matrix)
|> validate_narrow_baseline(support_matrix)
```

**Likely modification seam:** add capability-family support posture as manifest-derived truth without turning this module into a second source of truth. Reuse the exact status vocabulary and proof-note boundary-link shape already used for platform support.

**Secondary analog:** `guides/support_matrix.md:3-5`, which shows the intended public posture: narrow, proof-oriented, explicit.

---

### `lib/crosswake/support_matrix/renderer.ex` (utility, file-I/O)

**Primary analog:** `lib/crosswake/support_matrix/renderer.ex`

**Deterministic Markdown assembly pattern** (`lib/crosswake/support_matrix/renderer.ex:11-38`):
```elixir
[
  "# Crosswake Support Matrix",
  "",
  "This guide stays narrow and proof-oriented.",
  ...
  section("Phoenix", support_matrix.phoenix),
  ...
]
|> Enum.join("\n")
```

**Stable table row rendering pattern** (`lib/crosswake/support_matrix/renderer.ex:63-91`):
```elixir
"| Target | Version | Status | Proof | Boundaries | Notes |"
...
"| #{entry.target} | #{entry.version} | #{format_status(entry.status)} | #{proof} | #{boundaries} | #{notes} |"
```

**Likely modification seam:** add a new rendered capability-family section or guide variant using the same deterministic row discipline. Keep output manifest-derived, link-based, and explicit about proof/boundaries/rebuilds.

**Secondary analog:** `guides/support_matrix.md:15-42`, which is the generated shape this renderer already targets.

---

### `lib/crosswake/policy/schema.ex` (config, transform)

**Primary analog:** `lib/crosswake/policy/schema.ex`

**NimbleOptions enum and custom validator pattern** (`lib/crosswake/policy/schema.ex:13-61`, `100-141`):
```elixir
@schema NimbleOptions.new!([
  runtime: [type: {:custom, __MODULE__, :validate_runtime, []}, ...],
  capabilities: [type: {:list, {:custom, __MODULE__, :validate_identifier, []}}, default: []],
  ...
])
```

**Reserved future extension pattern** (`lib/crosswake/policy/schema.ex:105-110`):
```elixir
def validate_runtime(:adapter), do: {:error, "runtime :adapter is a reserved future extension point"}
```

**Likely modification seam:** if Phase 11 introduces route-facing taxonomy hints, keep them explicit and typed here. Do not collapse family taxonomy, package class, and route owner into one overloaded field; the existing schema style favors separate enums and custom validators.

**Secondary analog:** `lib/crosswake/policy/route.ex:69-167`, where field-level schema validation is followed by cross-field ownership rules.

---

### `guides/bridge.md` (guide, request-response)

**Primary analog:** `guides/bridge.md`

**Bounded-surface framing pattern** (`guides/bridge.md:3-15`):
```markdown
Crosswake exposes one typed, versioned, request/reply-only bridge.
...
Everything else is denied. The bridge is not navigation authority, not render synchronization, and not a generic plugin bus.
```

**Enforcement checklist pattern** (`guides/bridge.md:33-47`):
```markdown
Before any side effect runs, Crosswake checks:
- The active route matches `route_id`
- The route declares the capability
- The manifest capability registry provides the capability version
...
```

**Likely modification seam:** add Phase 11 family-versus-command explanation here. Keep this guide command-level and bounded; if family taxonomy is documented here, it should explain why commands remain protocol details under a family.

**Secondary analog:** `lib/crosswake/bridge/registry.ex:11-22`, the code source for command allowlisting.

---

### `guides/native_shell.md` (guide, request-response)

**Primary analog:** `guides/native_shell.md`

**Ownership-first contract pattern** (`guides/native_shell.md:13-21`, `40-52`):
```markdown
- Activation is `manifest-first` and `native-first`.
- Unsupported routes land on an explicit `route unavailable` surface.
- Bridge calls stay typed, versioned, request/reply-only, and low-frequency.
```

**Fail-closed degraded-behavior pattern** (`guides/native_shell.md:53-66`, `108-119`, `137-144`):
```markdown
Crosswake does not silently fall back to a generic web container.
...
If a route declares native capture, the shell opens the declared native surface or fails closed.
```

**Likely modification seam:** publish the ownership rubric here for bounded-bridge versus native-screen classification. This guide already carries the project’s public “who owns the route interaction loop” language.

**Secondary analog:** `guides/adopter_profiles.md:13-18`, `101-108`, where Crosswake already distinguishes route classes by ownership and explicit non-goals.

---

### `guides/support_matrix.md` (guide, file-I/O)

**Primary analog:** `guides/support_matrix.md`

**Narrow proof-surface framing pattern** (`guides/support_matrix.md:1-5`):
```markdown
This guide stays narrow and proof-oriented.
```

**Simple matrix section pattern** (`guides/support_matrix.md:13-42`):
```markdown
## Phoenix
| Target | Version | Status | Proof | Boundaries | Notes |
...
```

**Likely modification seam:** add capability-family support posture in the same sparse tabular style. Keep proof, boundaries, notes, and rebuild truth visible; do not turn this into a marketing catalog.

**Secondary analog:** `lib/crosswake/support_matrix/renderer.ex:63-91`, which defines the stable table layout.

## Shared Patterns

### 1. Central registry truth, lean route declarations
**Sources:** `lib/crosswake/manifest/builder.ex:42-49`, `52-75`; `lib/crosswake/policy/schema.ex:37-60`

Routes declare ids and local seams; shared semantics live in typed registries and structs. Phase 11 should keep capability-family metadata in manifest registry entries, not copied across every route.

### 2. Typed constructors plus `to_map/1` serialization
**Sources:** `lib/crosswake/manifest/types.ex:346-352`, `355-370`, `425-444`, `482-576`

When adding metadata, update struct, constructor, and serializer together. Crosswake’s manifest code treats missing serializer coverage as contract drift.

### 3. Fail-closed semantic validation
**Sources:** `lib/crosswake/manifest/validator.ex:12-18`, `94-113`, `145-248`; `lib/crosswake/policy/route.ex:69-167`

Validation is pipeline-based and semantic, not just shape-based. The project re-normalizes declarations against canonical contracts and rejects drift with explicit messages and hints.

### 4. Stable denial vocabulary
**Sources:** `lib/crosswake/shell/denial.ex:8-18`, `56-68`; `guides/bridge.md:62-71`

Capability metadata should point at explicit denial/fallback behavior using existing typed reasons where possible. Avoid new vague statuses that hide runtime truth.

### 5. Support truth stays narrow and proof-backed
**Sources:** `lib/crosswake/support_matrix/support_matrix.ex:130-156`; `guides/support_matrix.md:3-5`; `guides/native_shell.md:80-106`

Phase 11 can expand vocabulary, but not widen claims. New capability-family sections should inherit the same proof/boundary discipline as the current platform matrix.

### 6. Ownership-first docs, not plugin-catalog docs
**Sources:** `guides/native_shell.md:13-21`, `55-66`, `118-144`; `guides/bridge.md:14`; `guides/adopter_profiles.md:15-18`, `83-90`, `147-154`

Public writing consistently explains who owns the interaction loop, what fails closed, and what is deferred. Keep Phase 11 docs in that voice; avoid generic plugin-bus framing or widened runtime authority.

## Likely Modification Seams By Plan

### Plan 11-01
- `lib/crosswake/policy/schema.ex`: add only minimal typed route-facing taxonomy hooks if needed.
- `lib/crosswake/bridge/registry.ex`: preserve family-versus-command separation.
- `guides/bridge.md`: explain commands as operation-level details under families.
- `guides/native_shell.md`: publish bounded-bridge versus native-screen rubric in ownership-first language.

### Plan 11-02
- `lib/crosswake/manifest/types.ex`: add typed capability-family metadata.
- `lib/crosswake/manifest/builder.ex`: compile canonical family metadata into the registry.
- `lib/crosswake/manifest/validator.ex`: enforce allowed vocabularies and fail-closed metadata truth.
- `lib/crosswake/support_matrix/support_matrix.ex`: hold capability-family support posture as canonical typed data.
- `lib/crosswake/support_matrix/renderer.ex`: render the new support surface deterministically.
- `guides/support_matrix.md`: stay generated-looking, sparse, and proof-oriented.

### Plan 11-03
- `guides/native_shell.md`: reinforce explicit native-screen-first families and no silent fallback.
- `guides/bridge.md`: keep bounded-bridge exemplar families narrow.
- `guides/support_matrix.md`: show capability-family proofs, prerequisites, denials, and rebuild expectations.

## No Analog Found

None. The codebase already has strong local analogs for typed registries, fail-closed validators, narrow support matrices, and bounded public contract guides.

## Metadata

**Analog search scope:** `lib/crosswake`, `guides`, `.planning/phases/11-capability-taxonomy-and-contract-rubric`
**Files scanned:** 16
**Pattern extraction date:** 2026-05-19
