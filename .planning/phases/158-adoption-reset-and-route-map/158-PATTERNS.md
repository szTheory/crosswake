# Phase 158: Adoption Reset and Route Map - Pattern Map

**Mapped:** 2026-07-31
**Files analyzed:** 24
**Analogs found:** 24 / 24

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/ADR-FIRST-B2C-ADOPTER.md` | documentation | transform | `.planning/ADR-FIRST-B2C-ADOPTER.md` | exact-existing |
| `.planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md` | documentation | transform | `.planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md` | exact-existing |
| `.planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md` | documentation | transform | `.planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md` | exact-existing |
| `.planning/FIRST-B2C-ADOPTER-LINEAR-ISSUE-DRAFTS.md` | documentation | transform | `.planning/STATE.md` | role-match |
| `.planning/todos/TODO-002-first-b2c-adopter-route-inputs.md` | documentation | transform | `.planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md` | role-match |
| `.planning/PROJECT.md` | documentation | transform | `.planning/PROJECT.md` | exact-existing |
| `.planning/REQUIREMENTS.md` | documentation | transform | `.planning/REQUIREMENTS.md` | exact-existing |
| `.planning/ROADMAP.md` | documentation | transform | `.planning/ROADMAP.md` | exact-existing |
| `.planning/STATE.md` | documentation | transform | `.planning/STATE.md` | exact-existing |
| `.planning/MILESTONES.md` | documentation | transform | `.planning/PROJECT.md` | role-match |
| `.planning/milestones/v20.0-ROADMAP.md` | documentation | transform | `.planning/ROADMAP.md` | role-match |
| `.planning/milestones/v20.0-REQUIREMENTS.md` | documentation | transform | `.planning/REQUIREMENTS.md` | role-match |
| `AGENTS.md` | config | transform | `AGENTS.md` | exact-existing |
| `lib/crosswake/planning/first_adopter_context.ex` | utility | file-I/O | `test/crosswake/planning/first_adopter_context_test.exs` | data-flow-match |
| `lib/crosswake/adoption/route_inventory.ex` | model | transform | `lib/crosswake/policy/schema.ex` + `lib/crosswake/policy/route.ex` | role-match |
| `lib/crosswake/capability_map.ex` | model | transform | `lib/crosswake/capability_map.ex` | exact-existing |
| `lib/crosswake/capability_map/renderer.ex` | service | file-I/O | `lib/crosswake/capability_map/renderer.ex` | exact-existing |
| `lib/crosswake/support_matrix/support_matrix.ex` | model | transform | `lib/crosswake/support_matrix/support_matrix.ex` | exact-existing |
| `lib/crosswake/support_matrix/renderer.ex` | service | file-I/O | `lib/crosswake/support_matrix/renderer.ex` | exact-existing |
| `guides/capability_map.md` | documentation | transform | `lib/crosswake/capability_map/renderer.ex` | generated-output |
| `guides/support_matrix.md` | documentation | transform | `lib/crosswake/support_matrix/renderer.ex` | generated-output |
| `test/crosswake/planning/first_adopter_context_test.exs` | test | file-I/O | `test/crosswake/planning/first_adopter_context_test.exs` | exact-existing |
| `test/crosswake/adoption/route_inventory_test.exs` | test | transform | `test/crosswake/policy/schema_test.exs` | role-match |
| `test/crosswake/capability_map/capability_map_test.exs` | test | transform | `test/crosswake/capability_map/capability_map_test.exs` | exact-existing |
| `test/crosswake/capability_map/renderer_test.exs` | test | file-I/O | `test/crosswake/capability_map/renderer_test.exs` | exact-existing |
| `test/crosswake/support_matrix/support_matrix_test.exs` | test | transform | `test/crosswake/support_matrix/support_matrix_test.exs` | exact-existing |
| `test/crosswake/support_matrix/renderer_test.exs` | test | file-I/O | `test/crosswake/support_matrix/renderer_test.exs` | exact-existing |

## Pattern Assignments

### `lib/crosswake/adoption/route_inventory.ex` (model, transform)

**Analog:** `lib/crosswake/policy/schema.ex` and `lib/crosswake/policy/route.ex`

**Imports and enum pattern** (`lib/crosswake/policy/schema.ex` lines 1-20):

```elixir
defmodule Crosswake.Policy.Schema do
  @moduledoc """
  NimbleOptions schema for Phase 1 Crosswake route policy declarations.
  """

  alias Crosswake.Transfer.Contracts
  alias Crosswake.Offline.ContentPack

  @mfa_level_vocabulary [:none, :password, :mfa, :phishing_resistant]

  @runtime_values [:live_view, :offline_island, :native_screen]
  @offline_values [:unavailable, :cached_read_only, :local_first]
  @entry_values [:internal_only, :external]
  @security_values [:standard, :sensitive]
```

**Closed schema pattern** (`lib/crosswake/policy/schema.ex` lines 56-71):

```elixir
@schema NimbleOptions.new!(
          id: [
            type: {:custom, __MODULE__, :validate_identifier, []},
            required: true,
            type_spec: quote(do: String.t())
          ],
          runtime: [
            type: {:custom, __MODULE__, :validate_runtime, []},
            required: true,
            type_spec: quote(do: :live_view | :offline_island | :native_screen)
          ],
          offline: [
            type: {:in, @offline_values},
            default: :unavailable,
            type_spec: quote(do: :unavailable | :cached_read_only | :local_first)
          ],
```

**Validate/validate! pattern** (`lib/crosswake/policy/schema.ex` lines 217-226):

```elixir
@spec validate(keyword()) ::
        {:ok, validated_options()} | {:error, NimbleOptions.ValidationError.t()}
def validate(options) when is_list(options) do
  NimbleOptions.validate(options, @schema)
end

@spec validate!(keyword()) :: validated_options()
def validate!(options) when is_list(options) do
  NimbleOptions.validate!(options, @schema)
end
```

**Normalized struct and cross-field validation pattern** (`lib/crosswake/policy/route.ex` lines 26-47, 71-87):

```elixir
@enforce_keys [:id, :runtime]
defstruct [
  :id,
  :runtime,
  :security,
  :cache_contract,
  :island_contract,
  :commerce,
  :gated_by,
  :on_unavailable,
  :auth_min_level,
  :requires_recent_auth,
  :auth_posture,
  :auth_return,
  :notification_open,
  offline: :unavailable,
  entry: :internal_only,
  capabilities: [],
  packs: [],
  sync: [],
  transfers: []
]

@spec new(keyword()) :: {:ok, t()} | {:error, NimbleOptions.ValidationError.t()}
def new(options) when is_list(options) do
  options
  |> merged_options()
  |> Schema.validate()
  |> case do
    {:ok, validated} ->
      with {:ok, validated} <- validate_offline_contracts(validated),
           {:ok, validated} <- validate_gating_posture(validated),
           {:ok, validated} <- validate_entry_policy(validated),
           {:ok, validated} <- validate_commerce_declaration(validated),
           {:ok, validated} <- validate_auth_return_declaration(validated),
           {:ok, validated} <- validate_auth_posture(validated),
           {:ok, validated} <- validate_pack_requirements(validated),
           {:ok, validated} <- validate_transfer_declarations(validated) do
        {:ok, struct!(__MODULE__, validated)}
      end
```

**Planner notes:**

- Use closed vocabularies for `confirmed_sanitized`, `known_default`, `unknown_blocking`, and `not_applicable`.
- Reject unknown keys through `NimbleOptions`; do not parse free-form Markdown tables.
- Do not include raw route payload examples, endpoints, exact byte counts, digests, URLs, real flag names, account IDs, tokens, stable device IDs, or proprietary taxonomy.
- Use `unknown_blocking` as an explicit value for unavailable adopter-supplied safety fields; do not use blank cells or defaults for auth, scope, mutation, media, fallback, or disablement.

---

### `test/crosswake/adoption/route_inventory_test.exs` (test, transform)

**Analog:** `test/crosswake/policy/schema_test.exs`

**Test module/import pattern** (lines 1-7):

```elixir
defmodule Crosswake.Policy.SchemaTest do
  use ExUnit.Case, async: true

  alias Crosswake.Policy.Route
  alias Crosswake.Policy.Schema
  alias Crosswake.Transfer.Contracts
  alias Crosswake.Manifest.Types
```

**Required fields and enum rejection pattern** (lines 9-28):

```elixir
describe "validate!/1" do
  test "requires both id and runtime" do
    assert_raise NimbleOptions.ValidationError, ~r/required :id option not found/, fn ->
      Schema.validate!(runtime: :live_view)
    end

    assert_raise NimbleOptions.ValidationError, ~r/required :runtime option not found/, fn ->
      Schema.validate!(id: "home")
    end
  end

  test "rejects reserved and unknown runtime values" do
    assert_raise NimbleOptions.ValidationError, ~r/reserved future extension point/, fn ->
      Schema.validate!(id: "camera", runtime: :adapter)
    end

    assert_raise NimbleOptions.ValidationError, ~r/expected one of/, fn ->
      Schema.validate!(id: "camera", runtime: :webview)
    end
  end
```

**Positive closed data pattern** (lines 30-59):

```elixir
test "accepts explicit cache and island contract identifiers" do
  validated =
    Schema.validate!(
      id: "library",
      runtime: :live_view,
      offline: :cached_read_only,
      entry: :external,
      cache_contract: :lesson_library_v1
    )

  assert validated[:id] == "library"
  assert validated[:runtime] == :live_view
  assert validated[:offline] == :cached_read_only
  assert validated[:entry] == :external
  assert validated[:cache_contract] == "lesson_library_v1"
```

**Planner notes:**

- Add tests for required route-row safety fields, closed status vocabulary, unknown key rejection, sensitive field rejection, and `unknown_blocking` preservation.
- Add conflict tests for any family default trying to fill route-local auth/scope/mutation/media/fallback/disablement posture.

---

### `lib/crosswake/planning/first_adopter_context.ex` (utility, file-I/O)

**Analog:** `test/crosswake/planning/first_adopter_context_test.exs`

**Current path registry pattern** (lines 4-21):

```elixir
@durable_paths [
  ".planning/ADR-FIRST-B2C-ADOPTER.md",
  ".planning/DECISIONS.md",
  ".planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md",
  ".planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md",
  ".planning/FIRST-B2C-ADOPTER-LINEAR-ISSUE-DRAFTS.md",
  ".planning/PROJECT.md",
  ".planning/REQUIREMENTS.md",
  ".planning/ROADMAP.md",
  ".planning/STATE.md",
  ".planning/todos/TODO-002-first-b2c-adopter-route-inputs.md",
  "AGENTS.md"
]

@public_guide_paths [
  "guides/capability_map.md",
  "guides/support_matrix.md"
]
```

**Private-term env scan pattern** (lines 64-73):

```elixir
private_terms =
  System.get_env("CROSSWAKE_PRIVATE_ADOPTER_TERMS", "")
  |> String.split(",", trim: true)
  |> Enum.map(&String.trim/1)
  |> Enum.reject(&(&1 == ""))

for term <- private_terms do
  refute String.contains?(String.downcase(contents), String.downcase(term)),
         "active adopter artifacts contain a configured private adopter term"
end
```

**Planner notes:**

- Move the route/path matrix into a small module only if multiple tests need the same path categories.
- Return stable rule IDs and affected paths; never echo private terms.
- Keep scanning scope explicit and exclude historical archives, prompt lineage, raw fixtures/evidence, and git history.

---

### `test/crosswake/planning/first_adopter_context_test.exs` (test, file-I/O)

**Analog:** same file

**Discoverability assertion pattern** (lines 23-38):

```elixir
test "adopter-readiness context is durable and discoverable" do
  for path <- @durable_paths do
    assert File.exists?(path), "missing adopter-readiness context: #{path}"
  end

  assert File.read!("AGENTS.md") =~ ".planning/ADR-FIRST-B2C-ADOPTER.md"
  assert File.read!("AGENTS.md") =~ ".planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md"
  assert File.read!(".planning/STATE.md") =~ "$gsd-discuss-phase 158"
  assert File.read!(".planning/ROADMAP.md") =~ "Physical-iPhone Adoption Proof"
```

**Codename/public phrase split pattern** (lines 40-50):

```elixir
for path <- @durable_paths do
  assert File.read!(path) =~ ~r/First B2C Adopter|first-adopter|first adopter/i,
         "#{path} does not preserve adopter-priority context"
end

for path <- @public_guide_paths do
  contents = File.read!(path)
  assert contents =~ ~r/first adopter|first-adopter/i
  refute contents =~ "First B2C Adopter"
end
```

**Privacy rejection pattern** (lines 53-62):

```elixir
contents =
  (@durable_paths ++ @public_guide_paths)
  |> Enum.map_join("\n", &File.read!/1)

refute contents =~ ~r/\$\s*\d+/,
       "active adopter artifacts must not contain pricing"

refute contents =~ ~r/customer[-_ ]?(email|name|address)|legal[-_ ]?name/i,
       "active adopter artifacts must not contain customer or legal identity fields"
```

**Planner notes:**

- Extend this test or point it at `Crosswake.Planning.FirstAdopterContext` for centralized path categories.
- Add drift checks that active first-adopter files are represented in exactly one destination category.
- Add a synthetic private-term canary using `CROSSWAKE_PRIVATE_ADOPTER_TERMS` without printing the term.

---

### `lib/crosswake/capability_map.ex` (model, transform)

**Analog:** same file

**Data-oriented module and row struct pattern** (lines 1-41):

```elixir
defmodule Crosswake.CapabilityMap do
  @moduledoc """
  Canonical capability-map truth for support posture, proof posture, and first-adopter pressure.

  This module is intentionally small and data-oriented. It classifies current support,
  proof-backed evidence, first-adopter pressure, and future gaps without
  adding native controls, provider adapters, storage/sync productization, or dashboard UI.
  """

  defmodule Row do
    @moduledoc false

    @enforce_keys [
      :id,
      :surface,
      :route_or_evidence_source,
      :category,
      :display_label,
      :route_runtime_owner,
      :package_owner,
      :proof_posture,
      :rebuild,
      :denial_fallback,
      :v20_implication
    ]

    defstruct @enforce_keys
```

**Vocabulary getter pattern** (lines 44-109):

```elixir
@categories [:shipped, :demoed, :missing, :deferred, :next_pack_candidate]
@package_owners [:core, :native_shell, :first_party_companion, :example_docs_only, :deferred]
@proof_postures [:merge_blocking, :advisory, :not_yet_proven, :unsupported]
@rebuild_classes [:none, :native_required, :companion_required]

@route_runtime_owners [
  :live_view,
  :bounded_bridge,
  :native_shell,
  :native_screen,
  :offline_island,
  :backend_projection,
  :future_native_control
]

@spec categories() :: [category()]
def categories, do: @categories

@spec route_runtime_owners() :: [route_runtime_owner()]
def route_runtime_owners, do: @route_runtime_owners
```

**Canonical row pattern** (lines 111-127):

```elixir
@spec canonical() :: [Row.t()]
def canonical do
  [
    row(
      id: "route-policy",
      surface: "Route policy DSL and runtime ownership",
      route_or_evidence_source: "guides/route_policy.md and compiled router metadata",
      category: :shipped,
      rebuild: :none,
      display_label: "Available today",
      route_runtime_owner: :live_view,
      package_owner: :core,
      proof_posture: :merge_blocking,
      denial_fallback:
        "Routes fail closed through explicit runtime policy, manifest validation, and support-matrix diagnostics.",
      v20_implication: "Use as the policy gate for every Native Controls Pack 1 affordance."
    ),
```

**Planner notes:**

- Migrate `v20_implication` to canonical `adoption_implication`, preserving `v20_implication` as a legacy map input alias for one compatibility window.
- New canonical rows should use `adoption_implication`; tests should fail on conflicting dual values.

---

### `lib/crosswake/capability_map/renderer.ex` (service, file-I/O)

**Analog:** same file

**Render and normalize pattern** (lines 17-35, 141-142):

```elixir
@spec render([CapabilityMap.Row.t() | map()]) :: String.t()
def render(rows) when is_list(rows) do
  rows = Enum.map(rows, &normalize_row/1)

  [
    "# Crosswake Capability Map",
    "",
    "This guide is rendered from `Crosswake.CapabilityMap`. It classifies what Crosswake supports today, what existing proof demonstrates, what the first adopter pressures, and what remains a future gap.",
    "",
    what_works_today_section(rows),
    "",
    what_evidence_exists_section(rows),
    "",
    adoption_priority_section(rows),
    "",
    detailed_rows_section(rows),
    ""
  ]
  |> Enum.join("\n")
end

defp normalize_row(%_{} = row), do: Map.from_struct(row)
defp normalize_row(row) when is_map(row), do: row
```

**Idempotent write pattern** (lines 43-62):

```elixir
@spec write(String.t(), [CapabilityMap.Row.t() | map()]) :: {:ok, action()}
def write(path, rows) when is_binary(path) and is_list(rows) do
  File.mkdir_p!(Path.dirname(path))
  contents = render(rows)

  case File.read(path) do
    {:ok, ^contents} ->
      {:ok, :reused}

    {:ok, _previous} ->
      File.write!(path, contents)
      {:ok, :updated}

    {:error, :enoent} ->
      File.write!(path, contents)
      {:ok, :created}

    {:error, reason} ->
      raise "could not persist Crosswake capability map guide #{path}: #{:file.format_error(reason)}"
  end
end
```

**Table and escape pattern** (lines 118-138, 176-191):

```elixir
defp detailed_rows_section(rows) do
  [
    "## Detailed Capability Rows",
    "",
    "| Capability or surface | Display label | Route or evidence source | Current category | Route runtime owner | Package owner | Proof posture | Rebuild | Denial/fallback behavior | Adoption implication |",
    "|-----------------------|---------------|--------------------------|------------------|---------------------|---------------|---------------|---------|--------------------------|-----------------|",
    Enum.map_join(rows, "\n", &table_row/1)
  ]
  |> Enum.join("\n")
end

defp table_row(row) do
  "| #{escape_cell(row.surface)} | #{escape_cell(row.display_label)} | #{escape_cell(row.route_or_evidence_source)} | #{escape_cell(category_label(row.category))} | #{escape_cell(owner_label(row.route_runtime_owner))} | #{escape_cell(owner_label(row.package_owner))} | #{escape_cell(proof_label(row.proof_posture))} | #{escape_cell(rebuild_label(row.rebuild))} | #{escape_cell(row.denial_fallback)} | #{escape_cell(row.v20_implication)} |"
end

defp escape_cell(nil), do: "-"

defp escape_cell(value) when is_binary(value) do
  value
  |> String.replace("\\", "\\\\")
  |> String.replace("|", "\\|")
  |> String.replace("\n", " ")
end
```

**Planner notes:**

- Implement alias normalization inside `normalize_row/1`: prefer `adoption_implication`, accept `v20_implication`, raise on conflict.
- Update renderer internals to read `adoption_implication`; the rendered guide column title remains `Adoption implication`.
- `guides/capability_map.md` should be generated by renderer output and byte-checked, not hand-maintained.

---

### `test/crosswake/capability_map/capability_map_test.exs` (test, transform)

**Analog:** same file

**Vocabulary and required field pattern** (lines 6-43):

```elixir
@categories [:shipped, :demoed, :missing, :deferred, :next_pack_candidate]
@display_labels [
  "Available today",
  "Proof-backed example",
  "Demo pressure",
  "Advisory evidence",
  "Future gap",
  "Next-pack candidate"
]
@package_owners [:core, :native_shell, :first_party_companion, :example_docs_only, :deferred]
@proof_postures [:merge_blocking, :advisory, :not_yet_proven, :unsupported]
@rebuild_classes [:none, :native_required, :companion_required]

@required_fields [
  :id,
  :surface,
  :route_or_evidence_source,
  :category,
  :display_label,
  :route_runtime_owner,
  :package_owner,
  :proof_posture,
  :rebuild,
  :denial_fallback,
  :v20_implication
]
```

**Canonical row assertion pattern** (lines 107-144):

```elixir
test "D-03 canonical rows expose every public support-truth axis" do
  rows = canonical_rows()

  assert rows != []

  assert Enum.map(rows, & &1.id) == Enum.uniq(Enum.map(rows, & &1.id)),
         "D-03/D-30: capability map row ids must stay stable and unique"

  for row <- rows do
    for field <- @required_fields do
      assert Map.has_key?(row, field),
             "D-03: #{inspect(row.id)} missing required capability-map field #{field}"
    end

    assert row.category in @categories,
           "D-02: #{inspect(row.id)} uses unsupported category #{inspect(row.category)}"
```

**Planner notes:**

- Replace required `:v20_implication` with `:adoption_implication` for canonical rows.
- Add explicit legacy compatibility tests in `renderer_test.exs`, not canonical source, because the compatibility input is map-based renderer input.

---

### `test/crosswake/capability_map/renderer_test.exs` (test, file-I/O)

**Analog:** same file

**Deterministic write semantics pattern** (lines 9-34):

```elixir
test "D-06/D-20/D-21 renderer emits deterministic markdown and write semantics" do
  path =
    Path.join(
      System.tmp_dir!(),
      "crosswake-capability-map-#{System.unique_integer([:positive])}.md"
    )

  File.rm(path)

  rendered_once = Renderer.render()
  rendered_twice = Renderer.render()

  assert rendered_once == rendered_twice
  assert {:ok, :created} = Renderer.write(path)
  assert {:ok, :reused} = Renderer.write(path)

  changed_rows =
    CapabilityMap.canonical()
    |> Enum.map(&normalize_row/1)
    |> Enum.map(fn
      %{id: "route-policy"} = row -> %{row | v20_implication: "temporary update"}
      row -> row
    end)

  assert {:ok, :updated} = Renderer.write(path, changed_rows)
end
```

**Byte parity pattern** (lines 36-43):

```elixir
test "D-06/D-20/D-21 guides/capability_map.md is byte-identical to renderer output" do
  rendered = Renderer.render()

  assert File.read!(@guide_path) == rendered,
         "D-06/D-20/D-21: #{@guide_path} drifted from Crosswake.CapabilityMap.Renderer.render/0"

  assert rendered == Renderer.render()
end
```

**Escaping pattern** (lines 85-109):

```elixir
risky_row = %{
  id: "synthetic-risky-row",
  surface: "Risky | Surface",
  route_or_evidence_source: "line one\nline two",
  category: :demoed,
  display_label: "Demo pressure",
  route_runtime_owner: :live_view,
  package_owner: :example_docs_only,
  proof_posture: :advisory,
  rebuild: :native_required,
  denial_fallback: "alpha | beta",
  v20_implication: "gamma\ndelta"
}

rendered = Renderer.render([risky_row])

assert rendered =~ "Risky \\| Surface"
assert rendered =~ "line one line two"
assert rendered =~ "alpha \\| beta"
assert rendered =~ "gamma delta"
```

**Planner notes:**

- Update changed row fixtures to use `adoption_implication`.
- Add legacy map input using `v20_implication`, canonical map input using `adoption_implication`, and conflict rejection when both differ.

---

### `lib/crosswake/support_matrix/support_matrix.ex` (model, transform)

**Analog:** same file

**Canonical truth module pattern** (lines 1-18):

```elixir
defmodule Crosswake.SupportMatrix do
  @moduledoc """
  Canonical support-matrix truth shared across manifest generation, doctor, and docs.
  """

  alias Crosswake.Manifest.Types
  alias Crosswake.Manifest.Types.Capability
  alias Crosswake.Manifest.Types.CapabilitySupportEntry
  alias Crosswake.Manifest.Types.ChangeClassEntry
  alias Crosswake.Manifest.Types.PackageSurfaceEntry
  alias Crosswake.Manifest.Types.RebuildDecisionEntry
  alias Crosswake.Manifest.Types.ReleaseBoundaryEntry
  alias Crosswake.Manifest.Types.RuntimeLineRow
  alias Crosswake.Manifest.Types.SupportEntry
  alias Crosswake.Manifest.Types.SupportMatrix
  @statuses [:supported, :verification_required, :unsupported]
  @proof_classes [:merge_blocking, :advisory, :not_applicable]
```

**Authority boundary pattern** (lines 131-210):

```elixir
@auth_contract_truth_static %{
  surface:
    "Sigra SessionAuthorityLane route authority evaluator, handoff contract, step-up ceremony, and auth-return boundaries",
  owner: :backend_seam,
  package_class: :companion,
  proof_class: :merge_blocking,
  shipped_contracts: [
    :session_authority,
    :handoff_ticket,
    :server_record_redemption,
    :step_up_intent,
    :plug_liveview_ceremony,
    :auth_return_boundary,
    :auth_return_attempt
  ],
  handoff: %{
    status: :shipped,
    authority_source: :server_record,
    envelope_authority: false,
```

**Planner notes:**

- Keep canonical support status vocabulary; do not add new labels unless current labels cannot state Phase 158 truth.
- Update rows or helper sections to clarify that first-adopter readiness is verification-required and not physical-device proof.

---

### `lib/crosswake/support_matrix/renderer.ex` (service, file-I/O)

**Analog:** same file

**Deterministic render/write pattern** (lines 18-33, 82-102):

```elixir
@spec render(SupportMatrix.t()) :: String.t()
def render(%SupportMatrix{} = support_matrix) do
  [
    "# Crosswake Support Matrix",
    "",
    "This guide stays narrow and proof-oriented. Generated-shell coordinate support is",
    "backed by release-time clean-room proof plus generated-shell verification hooks.",
    "The checked-in native hosts are `checked-in public-coordinate proof`; the explicit",
    "maintainer path stays `local-dev proof` behind `--local`.",
    "The default non-local generator path resolves native shell cores from `github.com/szTheory/crosswake-shell-core-ios`",
    "and Maven Central `io.github.sztheory:crosswake-shell-core-android` at the Crosswake",
    "Hex package version; the release-time clean-room proof promotes that path after the",
    "coordinated cut.",
    "",
    support_truth_legend_section(),
```

```elixir
@spec write(String.t(), SupportMatrix.t()) :: {:ok, action()}
def write(path, %SupportMatrix{} = support_matrix) do
  File.mkdir_p!(Path.dirname(path))

  contents = render(support_matrix)

  case File.read(path) do
    {:ok, ^contents} ->
      {:ok, :reused}

    {:ok, _previous} ->
      File.write!(path, contents)
      {:ok, :updated}
```

**First-adopter support truth pattern** (lines 329-343):

```elixir
defp first_adopter_readiness_section do
  [
    "## First-Adopter Readiness",
    "",
    "These rows name the current adoption gaps without widening the support-truth taxonomy. Existing generated-shell, browser, simulator, JVM, and contract evidence remains valid at its stated level; none of it substitutes for host or physical-device proof.",
    "",
    "| Surface | Current truth | Promotion evidence | Boundary |",
    "|---------|---------------|--------------------|----------|",
    "| host-reusable offline/shell proof | verification required | A generated host-owned scaffold runs against an external Phoenix router, real route/storage identifiers, existing browser tests, and the iOS shell flow. | Example-host proof does not automatically transfer to a host application. |",
    "| privacy-safe scoped replay | verification required | Opaque scope references, scope-partitioned outbox, logout/account-switch stops, endpoint reauthorization, and redacted evidence all pass. | Raw mutation payloads, account identifiers, media, transcripts, tokens, and stable device identifiers are never diagnostics. |",
    "| foreground iOS pronunciation pack | verification required | A host provider downloads real bytes, verifies expected size and SHA-256, and atomically installs one immutable archive before reporting available. | Current timed native pack transitions are simulated lifecycle evidence, not productionized native content-pack storage. |",
    "| physical-iPhone offline study | verification required | One dated physical-device artifact proves offline answers, offline audio, kill/relaunch persistence, exactly-once replay, conflict/rejection recovery, account isolation, and server-side disablement. | This promotes one adopter flow on one iOS runtime line only. |",
    "| Android during first-adopter readiness | advisory evidence frozen at current posture | Existing generator, Maven, JVM, and shared-vector checks may remain green. | No new Android feature, parity, template, emulator/device, or release requirement is active. |"
  ]
  |> Enum.join("\n")
end
```

**Escape pattern** (lines 454-470):

```elixir
# Escape a value for inclusion as a single Markdown table cell. Replaces the
# pipe character (which would otherwise break column layout) with the
# backslash-escaped form GitHub Flavored Markdown understands, and collapses
# embedded newlines into spaces so a multi-line value cannot rip the row in
# two.
defp escape_cell(nil), do: "-"

defp escape_cell(value) when is_binary(value) do
  value
  |> String.replace("\\", "\\\\")
  |> String.replace("|", "\\|")
  |> String.replace("\n", " ")
end
```

**Planner notes:**

- Keep public guide phrasing as `first adopter`, never `First B2C Adopter`.
- Keep support claims narrow: `supported` is not physical-device proof; frozen Android is not device-verified.

---

### `test/crosswake/support_matrix/support_matrix_test.exs` (test, transform)

**Analog:** same file

**Typed manifest slot assertion pattern** (lines 8-43):

```elixir
test "canonical support matrix provides the typed manifest slots used by phase 2" do
  matrix = SupportMatrix.canonical()

  root =
    Types.new_root(
      crosswake_version: "0.1.0",
      generated_at: "2026-05-14T00:00:00Z",
      host: Types.new_host(),
      compatibility: Types.new_compatibility(),
      support_matrix: matrix,
      capability_registry: %{},
      routes: %{}
    )

  root_map = Types.to_map(root)

  assert Map.keys(root_map) == [
           "capability_registry",
           "commerce_corridors",
           "compatibility",
           "crosswake_version",
           "generated_at",
           "host",
           "manifest_schema_version",
           "pack_registry",
           "routes",
           "support_matrix"
         ]
```

**Narrow proof-oriented assertion pattern** (lines 63-76):

```elixir
test "the first support matrix stays narrow and proof-oriented" do
  matrix = SupportMatrix.canonical()

  assert length(matrix.phoenix) == 1
  assert length(matrix.live_view) == 1
  assert length(matrix.ios) == 1
  assert length(matrix.android) == 1
  assert length(matrix.shells) == 2
  assert matrix.capability_families != []
  assert length(matrix.package_surfaces) == 5
  assert length(matrix.release_boundaries) == 4
  assert length(matrix.change_classes) == 4
  assert SupportMatrix.validate(matrix) == []
end
```

**Planner notes:**

- Add tests for first-adopter readiness rows, Android freeze, physical-device non-claim, and route inventory blocking support promotion.

---

### `test/crosswake/support_matrix/renderer_test.exs` (test, file-I/O)

**Analog:** same file

**Determinism pattern** (lines 7-27):

```elixir
test "renderer emits deterministic markdown and preserves created, reused, and updated semantics" do
  matrix = SupportMatrix.canonical()

  path =
    Path.join(
      System.tmp_dir!(),
      "crosswake-support-matrix-#{System.unique_integer([:positive])}.md"
    )

  File.rm(path)

  rendered_once = Renderer.render(matrix)
  rendered_twice = Renderer.render(matrix)

  assert rendered_once == rendered_twice
  assert {:ok, :created} = Renderer.write(path, matrix)
  assert {:ok, :reused} = Renderer.write(path, matrix)

  updated_matrix = SupportMatrix.canonical(ios_version: "18.0")
  assert {:ok, :updated} = Renderer.write(path, updated_matrix)
end
```

**Support truth/non-claim assertion pattern** (lines 37-65):

```elixir
test "generated guide renders support-truth labels with proof and non-proof meanings" do
  guide = Renderer.render(SupportMatrix.canonical())

  assert guide =~ "## Support-Truth Label Legend"

  for label <- [
        "merge-blocking proof",
        "advisory evidence",
        "checked-in public-coordinate proof",
        "local-dev proof",
        "generated public-coordinate proof",
        "JVM hermetic proof",
        "emulator evidence",
        "device evidence",
        "verification-required",
        "rebuild-required"
      ] do
    assert guide =~ label
  end

  assert guide =~ "supported` is not the same as device-verified"
  assert guide =~ "JVM hermetic proof is not emulator evidence or physical-device proof"
  assert guide =~ "Emulator evidence is not physical-device proof"
  assert guide =~ "Visual collateral is not correctness proof by itself"
  assert guide =~ "Device/provider evidence is not backend/session authority"
  assert guide =~ "Cached read-only is not offline mutation"
  assert guide =~ "Bridge is not high-frequency or mutation authority"
end
```

**Planner notes:**

- Extend with exact public first-adopter strings and refute durable codename in generated guide.
- Keep guide parity byte checks if present in this test file or add them following capability renderer.

---

### `guides/capability_map.md` and `guides/support_matrix.md` (documentation, transform)

**Analogs:** `lib/crosswake/capability_map/renderer.ex`, `lib/crosswake/support_matrix/renderer.ex`

**Generated guide rule:** Edit canonical Elixir source/renderers, then regenerate guides through the existing renderer write path. Preserve byte-parity tests:

```elixir
assert File.read!(@guide_path) == rendered,
       "D-06/D-20/D-21: #{@guide_path} drifted from Crosswake.CapabilityMap.Renderer.render/0"
```

**Planner notes:**

- Public guides use `first adopter`.
- Generated Markdown tables must escape pipes and collapse newlines through the renderer.
- Do not hand-write `First B2C Adopter` into public guides.

---

### Planning Markdown and `AGENTS.md` (documentation/config, transform)

**Analogs:** existing planning docs and `test/crosswake/planning/first_adopter_context_test.exs`

**Route-policy map pattern** (`.planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md`):

```markdown
| Product surface | Runtime owner | Offline posture | Authority and fallback |
| --- | --- | --- |
| Study session | `:offline_island` | Local mutation with journal, scoped outbox, replay, rejection, and conflict handling | Host backend reauthorizes every replay; route visibly blocks when account or feature state is invalid |
```

**Requirements traceability pattern** (`.planning/REQUIREMENTS.md`):

```markdown
| Requirement | Phase | Status |
| --- | --- | --- |
| RESET-01 | Phase 158 | Pending |
| RESET-02 | Phase 158 | Pending |
| RESET-03 | Phase 158 | Pending |
| RESET-04 | Phase 158 | Pending |
```

**State warning pattern** (`.planning/STATE.md`):

```markdown
## Working-Tree Note

The pre-existing `.planning/config.json` modification is unrelated and must not be overwritten by
this milestone reset.
```

**Planner notes:**

- Durable docs may use `First B2C Adopter`; public guides should use `first adopter`.
- Keep `.planning/config.json` untouched.
- Preserve v20 as stopped/partial; do not promote Phases 156-157 to active or shipped evidence.
- Keep TODO-002 open until sanitized concrete route rows are supplied.

## Shared Patterns

### Closed Validation

**Source:** `lib/crosswake/policy/schema.ex` lines 56-71 and 217-226  
**Apply to:** `lib/crosswake/adoption/route_inventory.ex`, capability alias normalization, route-row fixtures.

Use `NimbleOptions.new!` plus `validate/1` and `validate!/1`; cast only named fields, enforce enums, and return field-specific `NimbleOptions.ValidationError` values.

### Cross-Field Route Safety

**Source:** `lib/crosswake/policy/route.ex` lines 71-87 and 115-164  
**Apply to:** route inventory route-local auth/scope/mutation/media/fallback/disablement checks.

Use a normalized struct after schema validation, then `with` through named cross-field validators. Do not silently inherit safety-critical posture from product-surface defaults.

### Deterministic Rendering

**Source:** `lib/crosswake/capability_map/renderer.ex` lines 17-35 and `lib/crosswake/support_matrix/renderer.ex` lines 18-80  
**Apply to:** capability map guide, support matrix guide, any generated route-inventory guide.

Render as a list of strings joined with `"\n"`. Keep renderer output deterministic and byte-identical with generated guides.

### Idempotent Guide Writes

**Source:** `lib/crosswake/capability_map/renderer.ex` lines 43-62 and `lib/crosswake/support_matrix/renderer.ex` lines 82-102  
**Apply to:** generated guide writers.

Return `{:ok, :created | :reused | :updated}` and only write when content differs.

### Markdown Escaping

**Source:** `lib/crosswake/support_matrix/renderer.ex` lines 454-470 and `lib/crosswake/capability_map/renderer.ex` lines 176-191  
**Apply to:** all generated Markdown tables.

Escape backslashes and pipes, collapse newlines, and use `"-"` for nil cells.

### Privacy and Context Routing

**Source:** `test/crosswake/planning/first_adopter_context_test.exs` lines 4-21, 40-73  
**Apply to:** `lib/crosswake/planning/first_adopter_context.ex`, planning context tests, public guide scans.

Centralize path categories, enforce codename/public phrase split, and read `CROSSWAKE_PRIVATE_ADOPTER_TERMS` without printing configured terms.

## No Analog Found

No files are fully without analog. The weakest match is `lib/crosswake/planning/first_adopter_context.ex` because the current path registry lives inside a test, but the data flow and expected API are directly inferable from `test/crosswake/planning/first_adopter_context_test.exs`.

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| none | - | - | Existing codebase patterns cover all planned file roles. |

## Metadata

**Analog search scope:** `lib/crosswake`, `test/crosswake`, `guides`, active `.planning` docs  
**Files scanned:** 260 listed; 12 analog files read with line numbers  
**Pattern extraction date:** 2026-07-31  
**Privacy guard:** Did not inspect git history or external sources for adopter identity.  
**Write scope:** Created only `.planning/phases/158-adoption-reset-and-route-map/158-PATTERNS.md`.
