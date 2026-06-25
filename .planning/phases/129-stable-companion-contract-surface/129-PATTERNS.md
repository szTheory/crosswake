# Phase 129: Stable Companion Contract Surface - Pattern Map

**Mapped:** 2026-06-25
**Files analyzed:** 9 new/modified files
**Analogs found:** 9 / 9

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/crosswake/companion.ex` | module/doc | transform (moduledoc edit) | self (existing moduledoc) | exact |
| `lib/crosswake/companion/state.ex` | model | — | `lib/crosswake/shell/denial.ex` (real moduledoc on a struct) | role-match |
| `lib/crosswake/compatibility/compatibility.ex` (Finding + Target nested) | model | — | `lib/crosswake/companion/state.ex` (nested `@moduledoc false` struct) | exact |
| `lib/crosswake/manifest/types.ex` (RouteEntry nested) | model | — | `lib/crosswake/companion/state.ex` | role-match |
| `lib/crosswake/shell/denial.ex` | model | — | self (append to existing real moduledoc) | exact |
| `mix.exs` `defp docs/0` | config | — | `mix.exs` lines 83-157 (self) | exact |
| `guides/companion_contract.md` | doc/guide | — | `guides/companions.md`, `guides/compatibility.md` | role-match |
| `test/crosswake/proof/phase129_companion_contract_freeze_test.exs` | test/proof | request-response (read-only reflection) | `test/crosswake/proof/phase65_diagnostic_export_seam_test.exs`, `test/crosswake/proof/phase38_companion_contract_test.exs` | exact |
| `test/crosswake/hex_page_test.exs` | test/unit | — | self (lines 118-165) | exact |

---

## Pattern Assignments

### `lib/crosswake/companion.ex` (modify: replace stale para, add frozen-surface block)

**Analog:** self — `lib/crosswake/companion.ex` lines 1-41

**Current moduledoc structure** (lines 1-41):
```elixir
defmodule Crosswake.Companion do
  @moduledoc """
  Behaviour for first-party Phoenix-native companion integrations.

  A companion is a bounded integration seam between Crosswake's route-policy
  system and an external Elixir library (e.g. rulestead for feature flags,
  rindle for media, sigra for auth). Companions live in-tree under
  `lib/crosswake/companions/<name>/` for the v3.5 milestone and may be extracted
  to separate packages in a future milestone once the seam stabilizes.

  ## Implementing a companion
  ...
  """
```

**What to change (D-05):** Lines 7-9 contain the stale sentence:
```
  Companions live in-tree under
  `lib/crosswake/companions/<name>/` for the v3.5 milestone and may be extracted
  to separate packages in a future milestone once the seam stabilizes.
```
Replace the entire opening paragraph (lines 4-9) with a frozen-surface paragraph naming the 5 public modules and stating semver stability, placed immediately before `## Implementing a companion`. The `## Implementing a companion` heading (line 11) is the section boundary — insert before it.

**Frozen-surface paragraph to insert (D-05):**
```
  The public companion contract surface — the types and callbacks extension packages
  may depend on under semver — is exactly five modules:
  `Crosswake.Companion`, `Crosswake.Companion.State`, `Crosswake.Compatibility.Finding`,
  `Crosswake.Compatibility.Target`, and `Crosswake.Manifest.Types.RouteEntry`. These are
  semver-stable under `crosswake` >= 0.1.0. All other modules in `crosswake` are
  internal implementation details subject to change.
```

No `@moduledoc since:` needed on `Crosswake.Companion` itself — it already has a real moduledoc; `since:` is only added to the 4 newly-promoted types (D-03).

---

### `lib/crosswake/companion/state.ex` (modify: promote `@moduledoc false`)

**Analog:** `lib/crosswake/shell/denial.ex` lines 1-4 (a struct module with a real single-sentence moduledoc)

**Current state** (lines 1-2):
```elixir
defmodule Crosswake.Companion.State do
  @moduledoc false
```

**Target pattern — promotion with stability section (D-01, D-03, D-04):**
```elixir
defmodule Crosswake.Companion.State do
  @moduledoc """
  Typed runtime state snapshot returned by `report_state/0`.

  Carries the companion's current enabled status, dependency health,
  gate configuration, and kill-switch position at a point in time.
  `checked_at` is a monotonic millisecond timestamp
  (`System.monotonic_time(:millisecond)`).

  ## Stability

  Public stable — part of the Crosswake companion contract surface. Semver-protected
  under `crosswake` >= 0.1.0: no breaking changes to this module's struct fields,
  types, or callbacks without a major version bump. Companion packages
  (`crosswake_rulestead`, `crosswake_rindle`, etc.) may safely `alias` and
  pattern-match on this type.
  """
  @moduledoc since: "0.1.0"
```

**Key placement rule (A1):** `@moduledoc since: "0.1.0"` must be on its own line, immediately after the closing `"""` of the docstring, before `@enforce_keys`.

**`@typedoc` to add on `t()` (D-14):**
```elixir
  @typedoc "Runtime state snapshot for a companion at a point in time."
  @type t :: %__MODULE__{...}
```
The `@typedoc` must immediately precede the `@type t` line.

---

### `lib/crosswake/compatibility/compatibility.ex` — nested `Finding` and `Target` modules (modify: promote both)

**Analog:** `lib/crosswake/companion/state.ex` (same pattern: `@moduledoc false` nested defmodule with `defstruct` + `@type t`)

**Current state of `Target`** (lines 14-38):
```elixir
  defmodule Target do
    @moduledoc false

    defstruct [
      :manifest_schema_version,
      ...
    ]

    @type t :: %__MODULE__{...}
  end
```

**Current state of `Finding`** (lines 40-55):
```elixir
  defmodule Finding do
    @moduledoc false

    @enforce_keys [:axis, :message]
    defstruct [:axis, :message, :required, :available, :hint, :route_id, :subject]

    @type t :: %__MODULE__{...}
  end
```

**Target pattern for `Target` promotion:**
```elixir
  defmodule Target do
    @moduledoc """
    Evaluation context passed to companion callbacks `route_gated?/2` and
    `kill_switch_active?/1`.

    Carries the request-time compatibility context: runtime versions, origin,
    active route, capabilities, and pack state. Companion implementations
    receive this struct and may read any field but must not construct it directly.

    ## Stability

    Public stable — part of the Crosswake companion contract surface. Semver-protected
    under `crosswake` >= 0.1.0: no breaking changes to this module's struct fields,
    types, or callbacks without a major version bump. Companion packages
    (`crosswake_rulestead`, `crosswake_rindle`, etc.) may safely `alias` and
    pattern-match on this type.
    """
    @moduledoc since: "0.1.0"

    defstruct [...]

    @typedoc "Request-time evaluation context passed to companion gate and kill-switch callbacks."
    @type t :: %__MODULE__{...}
  end
```

**Target pattern for `Finding` promotion:**
```elixir
  defmodule Finding do
    @moduledoc """
    Typed restriction evidence returned by `route_gated?/2`.

    Companion implementations return `{:deny, %Finding{}}` to signal that a
    route is restricted. Core translates findings into `Crosswake.Shell.Denial`
    structs internally — companions must never construct `Denial` directly.

    Required fields: `:axis` (atom identifying the policy axis, e.g. `:feature_flag`)
    and `:message` (human-readable explanation). Optional fields add structured
    evidence for logging and support surfaces.

    ## Stability

    Public stable — part of the Crosswake companion contract surface. Semver-protected
    under `crosswake` >= 0.1.0: no breaking changes to this module's struct fields,
    types, or callbacks without a major version bump. Companion packages
    (`crosswake_rulestead`, `crosswake_rindle`, etc.) may safely `alias` and
    pattern-match on this type.
    """
    @moduledoc since: "0.1.0"

    @enforce_keys [:axis, :message]
    defstruct [...]

    @typedoc "Restriction evidence emitted by a companion's `route_gated?/2` callback."
    @type t :: %__MODULE__{...}
  end
```

---

### `lib/crosswake/manifest/types.ex` — nested `RouteEntry` (modify: promote)

**Analog:** Same pattern as `Finding`/`Target`. `RouteEntry` lives at line 208.

**Current state** (lines 208-209):
```elixir
  defmodule RouteEntry do
    @moduledoc false
```

**Target pattern (D-06 scoping note required):**
```elixir
  defmodule RouteEntry do
    @moduledoc """
    Typed route definition passed as the first argument to `route_gated?/2`.

    Companions receive this struct to inspect route metadata when evaluating
    gate policy. Read-only from the companion's perspective — never construct
    or modify a `RouteEntry` in companion code.

    Only `RouteEntry.t()` is part of the companion contract surface. All other
    nested modules in `Crosswake.Manifest.Types` (`Crosswake.Manifest.Types.Root`,
    `Crosswake.Manifest.Types.Host`, `Crosswake.Manifest.Types.Compatibility`, etc.)
    are `@moduledoc false` and internal to Crosswake core.

    ## Stability

    Public stable — part of the Crosswake companion contract surface. Semver-protected
    under `crosswake` >= 0.1.0: no breaking changes to this module's struct fields,
    types, or callbacks without a major version bump. Companion packages
    (`crosswake_rulestead`, `crosswake_rindle`, etc.) may safely `alias` and
    pattern-match on this type.
    """
    @moduledoc since: "0.1.0"

    @enforce_keys [:id, :path, :runtime]
    defstruct [...]

    @typedoc "Route definition struct passed to companion gate callbacks."
    @type t :: %__MODULE__{...}
  end
```

**Naming-collision note (Research Finding 4):** The D-06 scoping sentence must spell out `Crosswake.Manifest.Types.Compatibility` (not just `Compatibility`) to avoid confusion with the public `Crosswake.Compatibility` module.

---

### `lib/crosswake/shell/denial.ex` (modify: append steering note to existing moduledoc)

**Analog:** self — lines 1-4. Current moduledoc is one sentence.

**Current moduledoc** (lines 2-4):
```elixir
  @moduledoc """
  Stable denial envelope shared by shell activation and bounded bridge replies.
  """
```

**Target pattern — append steering note (D-20):**
```elixir
  @moduledoc """
  Stable denial envelope shared by shell activation and bounded bridge replies.

  Core-owned denial envelope. Not part of the companion contract surface.
  Companion implementations return `{:deny, Crosswake.Compatibility.Finding.t()}`
  from `route_gated?/2`; core translates findings into `Denial` structs internally.
  Extension authors should never construct or return a `Denial` directly — reach
  for `Crosswake.Compatibility.Finding` instead.
  """
```

No `@moduledoc since:` added — `Denial` already has a real moduledoc and is NOT being added to the "Companion Contract" group. The steering note is purely informational.

---

### `mix.exs` `defp docs/0` (modify: add two groups + one extras entry)

**Analog:** self — lines 83-157 (read above in full)

**Current `extras` list** (lines 90-114): Add `"guides/companion_contract.md"` between `"guides/companions.md"` and `"guides/compatibility.md"` (or at the end of the companions section — position is flexible as long as it is in the list).

**Current `groups_for_modules`** (lines 115-120):
```elixir
      groups_for_modules: [
        Policy: [Crosswake.Policy, Crosswake.Router],
        Bridge: ~r/Crosswake\.Bridge(\.|$)/,
        Manifest: [Crosswake.Manifest],
        Capabilities: ~r/Crosswake\.(Commerce|Offline|Packs)/
      ],
```

**Target — add "Companion Contract" group using full atom list (D-10):**
```elixir
      groups_for_modules: [
        Policy: [Crosswake.Policy, Crosswake.Router],
        Bridge: ~r/Crosswake\.Bridge(\.|$)/,
        Manifest: [Crosswake.Manifest],
        Capabilities: ~r/Crosswake\.(Commerce|Offline|Packs)/,
        "Companion Contract": [
          Crosswake.Companion,
          Crosswake.Companion.State,
          Crosswake.Compatibility.Finding,
          Crosswake.Compatibility.Target,
          Crosswake.Manifest.Types.RouteEntry
        ]
      ],
```

**Current `groups_for_extras`** (lines 121-155): 5 groups. Add "Extension Authors" between "Truth" and "Advanced/Companions" (D-10):
```elixir
        "Extension Authors": [
          "guides/companion_contract.md"
        ],
        "Advanced/Companions": [
          "guides/companions.md",
          ...
        ]
```

**Cross-file ordering dependency (Research Finding 6):** `guides/companion_contract.md` MUST be in the `extras` list in the same commit that creates the file, or the existing `hex_page_test.exs` orphan guard (lines 151-163) will fail.

---

### `guides/companion_contract.md` (CREATE — Diátaxis reference)

**Analog:** `guides/companions.md` (tone + structure), `guides/compatibility.md` (reference format, anchor conventions)

**Guide structure (D-07, D-08, D-09):**

```markdown
# Companion Contract

> **Reference** — This guide enumerates the stable public surface
> that companion packages may depend on. For implementing a companion,
> see [guides/companions.md](companions.md). For declaring compatibility
> ranges, see [Companion Compatibility Contract](compatibility.md#companion-compatibility-contract).

## Contract Surface

The following five modules are the public companion contract surface,
semver-stable under `crosswake` >= 0.1.0.

| Module | Role | What companion code does with it | Stability tier |
|---|---|---|---|
| `Crosswake.Companion` | Behaviour | Declare `@behaviour Crosswake.Companion` and implement all 6 callbacks | Public stable |
| `Crosswake.Companion.State` | Return type | Return from `report_state/0` | Public stable |
| `Crosswake.Compatibility.Finding` | Return type | Return `{:deny, %Finding{}}` from `route_gated?/2` | Public stable |
| `Crosswake.Compatibility.Target` | Input type | Receive as argument in `route_gated?/2` and `kill_switch_active?/1` | Public stable |
| `Crosswake.Manifest.Types.RouteEntry` | Input type | Receive as argument in `route_gated?/2` | Public stable |

## Stability Tiers

- **Public stable** — semver-protected under `crosswake` >= 0.1.0. No breaking changes to struct fields, types, or callbacks without a major version bump.
- **Private** — `@moduledoc false`. Not part of any public API. May change without notice.

## What Is Not Contract

Any module carrying `@moduledoc false` is internal to Crosswake core and
must not be aliased or pattern-matched in companion code. Specifically:

- `Crosswake.Shell.Denial` — core-owned envelope. Companions return
  `{:deny, Finding.t()}` from `route_gated?/2`; core translates findings
  into `Denial` structs internally. **Companions must never construct or
  reference `Denial` directly**, including `Denial.reasons/0` — that
  function is for core operators, not companion authors. Emit your own
  denial-code strings via `Finding.t()`.
- All other `Crosswake.Manifest.Types.*` nested modules (`Root`, `Host`,
  `Crosswake.Manifest.Types.Compatibility`, `Capability`, etc.) — internal.
- Eval machinery: `Crosswake.Compatibility` (the parent module), its
  internal functions and private helpers.

## Declaring Compatibility

Companion packages declare the `crosswake` version range they are compatible
with. See [Companion Compatibility Contract](compatibility.md#companion-compatibility-contract)
for the required format.

## Telemetry Events

Crosswake emits the following static companion span event names that
companion implementations may observe (source of truth: `Crosswake.Companion`
moduledoc):

- `[:crosswake, :companion, :validate_dependency, :start | :stop | :exception]`
- `[:crosswake, :companion, :route_gate, :start | :stop | :exception]`
- `[:crosswake, :companion, :kill_switch, :start | :stop | :exception]`

All events carry `%{companion_id: atom(), route_id: binary() | nil}` metadata.
```

**Cross-link required in `guides/companions.md`:** Add a forward link near the top of `companions.md` pointing to this guide (D-08 reader journey).

---

### `test/crosswake/proof/phase129_companion_contract_freeze_test.exs` (CREATE)

**Analog:** `test/crosswake/proof/phase65_diagnostic_export_seam_test.exs` (file structure, `ProofAssertions.stable_id_message/7` pattern, `use ExUnit.Case`) and `test/crosswake/proof/phase38_companion_contract_test.exs` (companion context, `behaviour_info` idiom)

**Module structure pattern** (from phase38 lines 1-26, phase65 lines 1-8):
```elixir
defmodule Crosswake.Proof.Phase129CompanionContractFreezeTest do
  @moduledoc """
  Merge-blocking proof lane for Phase 129: Stable Companion Contract Surface.

  Proves SEAM-01 (5 contract modules have non-hidden moduledoc + typedoc on t()),
  SEAM-01 (Companion callback set frozen at exactly 6), SEAM-02 (companion_contract.md
  guide exists), and SEAM-03 (Shell.Denial absent / Compatibility.Finding present
  in the "Companion Contract" groups_for_modules entry).

  Runs UNTAGGED so the existing PR-gating proof lane auto-picks it. async: true
  (read-only — no Application.put_env, no shared state mutation).
  """

  use ExUnit.Case, async: true

  alias Crosswake.TestSupport.ProofAssertions
```

**Module-attribute callback set (D-12, D-13)** — define at module level so it appears in failure messages:
```elixir
  # The canonical pre-phase-129 callback shape. Equality (not membership) means
  # both additions AND removals fail. Change this attribute AND the @callback defs
  # in companion.ex in the SAME PR to signal intentional shape change.
  @expected_callbacks MapSet.new([
    {:companion_id, 0},
    {:enabled?, 1},
    {:route_gated?, 2},
    {:kill_switch_active?, 1},
    {:validate_dependency, 0},
    {:report_state, 0}
  ])
```

**Derive contract module list from single source of truth (D-15):**
```elixir
  defp contract_modules do
    Mix.Project.config()[:docs][:groups_for_modules]
    |> Keyword.get(:"Companion Contract", [])
  end
```

**Test 1 — callback freeze (D-12, SEAM-01):**
```elixir
  test "Companion behaviour callbacks are frozen at the Phase 129 contract shape" do
    actual = MapSet.new(Crosswake.Companion.behaviour_info(:callbacks))

    assert MapSet.equal?(@expected_callbacks, actual),
           ProofAssertions.stable_id_message(
             "proof.seam_01.companion.callback_shape",
             "Crosswake.Companion callbacks must match the frozen Phase 129 set",
             "Crosswake.Companion.behaviour_info(:callbacks)",
             "drift detected — actual: #{inspect(MapSet.to_list(actual))}, expected: #{inspect(MapSet.to_list(@expected_callbacks))}",
             "lib/crosswake/companion.ex",
             "change @expected_callbacks in this test AND the @callback defs in companion.ex in the SAME PR so the reviewer sees the intentional shape change",
             :merge_blocking
           )
  end
```

**Test 2 — moduledoc non-hidden for all 5 (D-14, SEAM-01):**
```elixir
  test "all Companion Contract modules have non-hidden moduledoc" do
    for mod <- contract_modules() do
      result = Code.fetch_docs(mod)

      assert match?({:docs_v1, _, _, _, moduledoc, _, _} when is_map(moduledoc), result),
             ProofAssertions.stable_id_message(
               "proof.seam_01.moduledoc.#{mod}",
               "#{inspect(mod)} must have a non-hidden @moduledoc",
               "Code.fetch_docs(#{inspect(mod)})",
               "got #{inspect(result)}",
               "see guides/companion_contract.md and SEAM-01",
               "add @moduledoc with ## Stability section to #{inspect(mod)} (SEAM-01)",
               :merge_blocking
             )
    end
  end
```

**Test 3 — @typedoc on t() for the 4 struct types (D-14, SEAM-01):**
```elixir
  @struct_contract_modules [
    Crosswake.Companion.State,
    Crosswake.Compatibility.Finding,
    Crosswake.Compatibility.Target,
    Crosswake.Manifest.Types.RouteEntry
  ]

  test "all struct-bearing Companion Contract modules have @typedoc on t/0" do
    for mod <- @struct_contract_modules do
      {:docs_v1, _, _, _, _, _, docs} = Code.fetch_docs(mod)

      t_typedoc =
        Enum.find_value(docs, fn
          {{:type, :t, 0}, _anno, _sigs, doc, _meta} -> doc
          _ -> nil
        end)

      assert is_map(t_typedoc),
             ProofAssertions.stable_id_message(
               "proof.seam_01.typedoc.#{mod}.t",
               "#{inspect(mod)}.t/0 must have a non-hidden @typedoc",
               "Code.fetch_docs(#{inspect(mod)}) type :t/0 doc",
               "got #{inspect(t_typedoc)}",
               "lib/crosswake/#{mod |> Module.split() |> Enum.map(&Macro.underscore/1) |> Enum.join("/")}",
               "add @typedoc immediately before @type t :: ... (SEAM-01)",
               :merge_blocking
             )
    end
  end
```

**Test 4 — Shell.Denial absent (D-19, SEAM-03):**
```elixir
  test "Crosswake.Shell.Denial is NOT in the Companion Contract module group" do
    refute Crosswake.Shell.Denial in contract_modules(),
           ProofAssertions.stable_id_message(
             "proof.seam_03.denial.absent_from_contract_group",
             "Crosswake.Shell.Denial must not appear in the 'Companion Contract' groups_for_modules entry",
             "mix.exs docs/0 groups_for_modules :\"Companion Contract\"",
             "Crosswake.Shell.Denial found in contract group",
             "mix.exs",
             "Shell.Denial is core-owned. Companions emit Finding.t(), not Denial. (SEAM-03)",
             :merge_blocking
           )
  end
```

**Test 5 — Compatibility.Finding present (D-19, SEAM-03):**
```elixir
  test "Crosswake.Compatibility.Finding IS in the Companion Contract module group" do
    assert Crosswake.Compatibility.Finding in contract_modules(),
           ProofAssertions.stable_id_message(
             "proof.seam_03.finding.present_in_contract_group",
             "Crosswake.Compatibility.Finding must appear in the 'Companion Contract' groups_for_modules entry",
             "mix.exs docs/0 groups_for_modules :\"Companion Contract\"",
             "Crosswake.Compatibility.Finding not found in contract group",
             "mix.exs",
             "Add Crosswake.Compatibility.Finding to the 'Companion Contract' group in mix.exs (SEAM-03)",
             :merge_blocking
           )
  end
```

**Test 6 — guide file exists (SEAM-02):**
```elixir
  test "guides/companion_contract.md exists on disk" do
    path = Path.join(File.cwd!(), "guides/companion_contract.md")

    assert File.exists?(path),
           ProofAssertions.stable_id_message(
             "proof.seam_02.guide.exists",
             "guides/companion_contract.md must exist on disk",
             "File.exists?(\"guides/companion_contract.md\")",
             "file not found at #{path}",
             "guides/companion_contract.md",
             "create guides/companion_contract.md and register it in mix.exs extras (SEAM-02)",
             :merge_blocking
           )
  end
```

**Key differences from phase65 analog:**
- `async: true` (phase65 is `async: false` due to `Application.put_env` — Phase 129 is read-only)
- No `@tag` decorators — untagged tests are picked up by the PR-gating lane automatically
- Uses `MapSet.equal?` for callback assertion (not `in` membership like phase65) — this is a deliberate upgrade (D-12)
- Derives module list from `Mix.Project.config()` rather than hardcoding — single source of truth (D-15)

---

### `test/crosswake/hex_page_test.exs` (modify: extend group assertions)

**Analog:** self — lines 118-165 (read above)

**Current `groups_for_modules` assertion** (lines 119-131):
```elixir
    test "groups_for_modules defines the expected groups and references real modules" do
      gfm = config()[:docs][:groups_for_modules]

      for group <- [:Policy, :Bridge, :Manifest, :Capabilities] do
        assert Keyword.has_key?(gfm, group),
               "groups_for_modules is missing the :#{group} group"
      end
      ...
    end
```

**Target — add `:"Companion Contract"` to the membership check:**
```elixir
      for group <- [:Policy, :Bridge, :Manifest, :Capabilities, :"Companion Contract"] do
        assert Keyword.has_key?(gfm, group),
               "groups_for_modules is missing the :#{group} group"
      end
```

**Current `groups_for_extras` assertion** (lines 133-140):
```elixir
    test "groups_for_extras defines the expected groups" do
      gfe = config()[:docs][:groups_for_extras]

      for group <- [:Start, :Adopt, :"Runtime Owners", :Truth, :"Advanced/Companions"] do
        assert Keyword.has_key?(gfe, group),
               "groups_for_extras is missing the :#{group} group"
      end
    end
```

**Target — add `:"Extension Authors"` to the membership check (Research Finding 14 / Open Question 2 recommendation):**
```elixir
      for group <- [:Start, :Adopt, :"Runtime Owners", :Truth, :"Extension Authors", :"Advanced/Companions"] do
        assert Keyword.has_key?(gfe, group),
               "groups_for_extras is missing the :#{group} group"
      end
```

The `Code.ensure_loaded?` loop at lines 127-130 automatically covers the new "Companion Contract" module atoms — no additional change needed there.

---

## Shared Patterns

### `ProofAssertions.stable_id_message/7` — failure message helper
**Source:** `test/support/proof_assertions.ex` lines 8-13
**Apply to:** all assertions in `phase129_companion_contract_freeze_test.exs`
```elixir
def stable_id_message(id, subject, source, observed, path, hint, posture) do
  """
  [#{id}] subject=#{subject} source=#{source} observed=#{observed} path=#{path} hint=#{hint} posture=#{posture}
  """
  |> String.trim()
end
```

All 7 args are positional strings. `posture` is passed as `:merge_blocking` (atom, interpolated directly). Stable-id slug convention: `"proof.<req_id>.<module_shortname>.<assertion_noun>"`.

### `Mix.Project.config()[:docs][:groups_for_modules]` derivation
**Source:** `test/crosswake/hex_page_test.exs` line 120
**Apply to:** `phase129_companion_contract_freeze_test.exs` `contract_modules/0` helper
```elixir
defp config, do: Mix.Project.config()
# then:
gfm = config()[:docs][:groups_for_modules]
```

### `@moduledoc since: "0.1.0"` placement
**Source:** Elixir/ExDoc convention (A1 in RESEARCH.md)
**Apply to:** all 4 promoted struct modules (State, Finding, Target, RouteEntry)
```elixir
  @moduledoc """
  ...prose...

  ## Stability

  Public stable — part of the Crosswake companion contract surface. Semver-protected
  under `crosswake` >= 0.1.0: no breaking changes to this module's struct fields,
  types, or callbacks without a major version bump. Companion packages
  (`crosswake_rulestead`, `crosswake_rindle`, etc.) may safely `alias` and
  pattern-match on this type.
  """
  @moduledoc since: "0.1.0"
```
`@moduledoc since:` appears on its own line immediately after the closing `"""`, before `@enforce_keys` or `defstruct`.

### `@typedoc` placement on `t()`
**Source:** inferred from existing type declarations in `state.ex`, `denial.ex`
**Apply to:** all 4 promoted struct modules
```elixir
  @typedoc "One-line description of the struct type."
  @type t :: %__MODULE__{...}
```
`@typedoc` must immediately precede the `@type t` declaration to be associated with it by EEP-48.

### `behaviour_info(:callbacks)` → `MapSet.equal?` freeze pattern
**Source:** `test/crosswake/proof/phase65_diagnostic_export_seam_test.exs` lines 80-93 (membership idiom) — **upgraded** per D-12
**Apply to:** callback freeze test in `phase129_companion_contract_freeze_test.exs`
```elixir
# Upgrade from membership (`in`) to equality (MapSet.equal?) to catch additions
expected = MapSet.new([{:callback_name, arity}, ...])
actual = MapSet.new(SomeModule.behaviour_info(:callbacks))
assert MapSet.equal?(expected, actual), ProofAssertions.stable_id_message(...)
```

### `Code.fetch_docs/1` EEP-48 moduledoc check
**Source:** Research Finding 9 (no existing codebase precedent — first use in Phase 129)
**Apply to:** moduledoc and typedoc assertions in `phase129_companion_contract_freeze_test.exs`
```elixir
# moduledoc is %{"en" => "..."} when present, :none or :hidden when not
assert match?({:docs_v1, _, _, _, moduledoc, _, _} when is_map(moduledoc),
              Code.fetch_docs(MyModule))

# typedoc on t/0: filter docs list for {:type, :t, 0} entry
{:docs_v1, _, _, _, _, _, docs} = Code.fetch_docs(MyModule)
t_doc = Enum.find_value(docs, fn
  {{:type, :t, 0}, _anno, _sigs, doc, _meta} -> doc
  _ -> nil
end)
assert is_map(t_doc)
```

---

## No Analog Found

All files have analogs. No entries.

---

## Metadata

**Analog search scope:** `lib/crosswake/`, `test/crosswake/proof/`, `test/support/`, `test/crosswake/hex_page_test.exs`, `mix.exs`
**Files scanned:** 9 source files read directly
**Pattern extraction date:** 2026-06-25
