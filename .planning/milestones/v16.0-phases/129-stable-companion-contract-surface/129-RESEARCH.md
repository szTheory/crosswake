# Phase 129: Stable Companion Contract Surface - Research

**Researched:** 2026-06-25
**Domain:** Elixir moduledocs, ExDoc grouping, EEP-48 doc assertions, behaviour freeze testing
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- D-01: Prose `## Stability` section at the END of each public moduledoc (not `@stability` attr, not `tags:` only)
- D-02: Three-tier vocabulary: public stable, private (`@moduledoc false`), patch-volatile. No patch-volatile modules needed this phase.
- D-03: Supplement with `@moduledoc since: "0.1.0"` on the four promoted types (own line, AFTER moduledoc string)
- D-04: Canonical `## Stability` template (verbatim, no per-module variation)
- D-05: Replace stale `Crosswake.Companion` moduledoc line ("Companions live in-tree… for the v3.5 milestone…") immediately before `## Implementing a companion`
- D-06: `RouteEntry` promotion must scope its guarantee — note OTHER nested modules remain `@moduledoc false`
- D-07: `guides/companion_contract.md` is pure Diátaxis REFERENCE (enumerate, don't tutorialize); 5-row surface table as heart
- D-08: Clean division: companion_contract.md = what is stable; companions.md = how to implement; compatibility.md = what ranges to declare
- D-09: Guide sections: Intro · Contract Surface table · Stability Tiers · What Is Not Contract · Declaring Compatibility (cross-link) · Telemetry Events
- D-10: NEW `groups_for_extras` group "Extension Authors" between `Truth` and `Advanced/Companions`; NEW `groups_for_modules` entry "Companion Contract" listing 5 modules by FULL NAME (not regex)
- D-11: `@moduledoc false` is a hard prerequisite — promote moduledocs BEFORE adding to `groups_for_modules`
- D-12: Inline `behaviour_info(:callbacks)` equality assertion using `MapSet.equal?` (both additions and removals fail)
- D-13: Frozen callback set (6): `companion_id/0`, `enabled?/1`, `route_gated?/2`, `kill_switch_active?/1`, `validate_dependency/0`, `report_state/0` — CONFIRMED against live source (see Finding 1)
- D-14: Moduledoc assertion via `Code.fetch_docs/1` — assert moduledoc is neither `false`, `:hidden`, nor `:none` for all 5 types; assert `@typedoc` present on `t()` for the 4 struct-bearing types
- D-15: Single source of truth — derive "Companion Contract" module set in test from `Mix.Project.config()[:docs][:groups_for_modules]`
- D-16: Test location: `test/crosswake/proof/phase129_companion_contract_freeze_test.exs`, untagged, `async: true`
- D-17: Actionable failure UX on callback drift; on hidden/missing moduledoc point at guide + SEAM-01
- D-18: Write-test-first forcing function — freeze test FAILS until 4 `@moduledoc false` promotions land
- D-19: ACTIVE enforcement in freeze test: `Crosswake.Shell.Denial` ABSENT from group; `Crosswake.Compatibility.Finding` PRESENT
- D-20: Add steering note to `Crosswake.Shell.Denial` moduledoc (verbatim text provided in CONTEXT.md)
- D-21: `guides/companion_contract.md` must explicitly state companions NEVER reference `Denial.reasons/0`
- D-22: Seam-audit finding (informational, no action this phase) — sigra/chimeway DO alias Denial internally; their in-tree usage is the reason D-20 steering note matters

### Claude's Discretion
- Exact one-liner microcopy in the guide table rows and intro (within established brand voice)
- Precise wording of `ProofAssertions.stable_id_message` stable-id slugs
- Whether `@typedoc` assertion covers only `t()` or additional exported types (researcher recommends `t()` for the 4 struct types)

### Deferred Ideas (OUT OF SCOPE)
- Promoting iOS UAT / other LIFE work — Phase 134
- Removing in-tree Denial coupling in sigra/chimeway — EXTRACT-FUT-01/02
- `boundary` library for compile-time enforcement — out of scope for 129's footprint
- Telemetry as full public API — Phase 133
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SEAM-01 | Extension author can depend on a documented, semver-governed set of public companion-contract types — each carries non-`false` `@moduledoc`/`@typedoc` and a stability note | Moduledoc promotion + `## Stability` template + freeze test asserting all 5 have non-hidden docs |
| SEAM-02 | A reader can find one curated `guides/companion_contract.md` enumerating exactly the public surface | New guide file + ExDoc extras registration + forward cross-link from companions.md |
| SEAM-03 | A companion implementation can return restriction evidence (`Compatibility.Finding`) but cannot author the user-facing denial — `Crosswake.Shell.Denial` absent from public surface | D-19 assertion in freeze test + D-20 steering note + D-21 guide language |
| SEAM-04 | A developer browsing hexdocs sees companion-contract types grouped under "Companion Contract" `groups_for_modules` heading | `groups_for_modules` entry with 5 full module names + D-10 "Extension Authors" extras group |
</phase_requirements>

---

## Summary

Phase 129 is a documentation-and-one-test phase with zero behavioural code changes. All 22 decisions in CONTEXT.md are locked and mutually consistent. This research does NOT re-litigate those decisions; it grounds every CONTEXT.md claim against the live codebase, surfaces discrepancies a planner would trip on, and captures the exact idioms the implementer needs.

The core change set is: (1) promote 4 modules from `@moduledoc false` to real moduledocs with `## Stability` notes and `@moduledoc since:`, (2) replace one stale line in `Crosswake.Companion`'s moduledoc and add a frozen-surface paragraph, (3) add a steering note to `Crosswake.Shell.Denial`, (4) write `guides/companion_contract.md`, (5) update `mix.exs` `docs/0` with one new extras group and one new module group, (6) add a forward cross-link to `guides/companions.md`, and (7) write one untagged proof test in the existing PR-gating lane.

**Primary recommendation:** Implement in dependency order — moduledoc promotions first (D-11 prerequisite), then `mix.exs` groups, then the guide, then the proof test (write-test-first means it will fail until promotions land — this is the intended forcing function).

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Moduledoc stability notes | Library source (`lib/`) | — | Each module owns its own documentation |
| ExDoc grouping | `mix.exs` docs config | `test/crosswake/hex_page_test.exs` | Config is single source; hex_page_test guards config drift |
| Companion contract reference guide | `guides/companion_contract.md` | `mix.exs` extras list | Guide is Diátaxis reference; extras list is how ExDoc includes it |
| Freeze proof test | `test/crosswake/proof/` lane | `Mix.Project.config()[:docs]` | Test derives module list from config to keep single source of truth |
| Shell.Denial boundary enforcement | `groups_for_modules` assertion in test | `Crosswake.Shell.Denial` moduledoc | Active test guard + passive steering note cover both edges |

---

## Codebase Verification Findings

### Finding 1: Callback set — CONFIRMED with one caveat [VERIFIED: lib/crosswake/companion.ex]

The live `lib/crosswake/companion.ex` contains exactly **6 `@callback` declarations** matching D-13:

```
companion_id/0
enabled?/1
route_gated?/2
kill_switch_active?/1
validate_dependency/0
report_state/0
```

`behaviour_info(:callbacks)` will return these as `{name, arity}` tuples:
`[companion_id: 0, enabled?: 1, route_gated?: 2, kill_switch_active?: 1, validate_dependency: 0, report_state: 0]`

**Caveat for D-12:** The codebase precedent (phase65, phase48, commerce_test) uses membership (`in`) assertions, NOT `MapSet.equal?`. D-12 deliberately upgrades to equality for Phase 129 to catch additions. The implementer must consciously write `MapSet.equal?` and add a comment explaining why equality is stronger than membership. This is NOT a discrepancy — D-12 is correct; just flag it explicitly in the test.

---

### Finding 2: Stale moduledoc line to replace (D-05) — CONFIRMED [VERIFIED: lib/crosswake/companion.ex]

The exact stale text at lines 7-10 of `lib/crosswake/companion.ex`:

```elixir
  Companions live in-tree under
  `lib/crosswake/companions/<name>/` for the v3.5 milestone and may be extracted
  to separate packages in a future milestone once the seam stabilizes.
```

This is the third sentence of the module-level paragraph (after "A companion is a bounded…" and the list of companion examples). The replacement frozen-surface paragraph must go **immediately before** the `## Implementing a companion` section (line 12 in the current file). Current line sequence:

- Line 1: `@moduledoc """`
- Line 2: `Behaviour for first-party Phoenix-native companion integrations.`
- Line 3: blank
- Line 4: `A companion is a bounded integration seam…`
- Lines 5-10: continuation including the stale sentence
- Line 11: blank
- Line 12: `## Implementing a companion`

The frozen-surface paragraph replaces lines 4-10 (the entire opening paragraph) OR is inserted between the opening paragraph and `## Implementing a companion` — planner's call, but the stale sentence must be removed.

---

### Finding 3: `@moduledoc false` states — ALL CONFIRMED [VERIFIED: live source files]

All four types scheduled for promotion are currently `@moduledoc false`:

| Module | File | Current state | Has `t()` type | `@enforce_keys` |
|--------|------|--------------|----------------|-----------------|
| `Crosswake.Companion.State` | `lib/crosswake/companion/state.ex` | `@moduledoc false` | Yes | Yes |
| `Crosswake.Compatibility.Target` | `lib/crosswake/compatibility/compatibility.ex` (nested `defmodule Target`) | `@moduledoc false` | Yes | No (plain defstruct) |
| `Crosswake.Compatibility.Finding` | `lib/crosswake/compatibility/compatibility.ex` (nested `defmodule Finding`) | `@moduledoc false` | Yes | Yes (`:axis`, `:message`) |
| `Crosswake.Manifest.Types.RouteEntry` | `lib/crosswake/manifest/types.ex` (nested `defmodule RouteEntry`) | `@moduledoc false` | Yes | Yes (`:id`, `:path`, `:runtime`) |

The parent `Crosswake.Compatibility` module has a REAL moduledoc ("Layered compatibility evaluation for manifests and route activation.") — it is NOT `@moduledoc false`. CONTEXT.md correctly states it is not part of the companion contract.

---

### Finding 4: Complete list of `@moduledoc false` nested modules in `Crosswake.Manifest.Types` (D-06 scoping) [VERIFIED: lib/crosswake/manifest/types.ex]

The `Crosswake.Manifest.Types` parent module has a real moduledoc. The following nested modules ALL carry `@moduledoc false` — only `RouteEntry` is being promoted:

`Root`, `Host`, `Compatibility` (the nested one, not `Crosswake.Compatibility`), `Capability`, `PackEntry`, `CommerceCorridor`, `RouteCommerce`, `RouteAuthReturn`, **`RouteEntry`** (→ promote), `TransferSeam`, `CacheContract`, `IslandContract`, `SupportMatrix`, `SupportEntry`, `CapabilitySupportEntry`, `PackageSurfaceEntry`, `ReleaseBoundaryEntry`, `ChangeClassEntry`, `RebuildDecisionEntry`, `ActionClassEntry`, `PromotionRuleEntry`, `RuntimeLineRow`

**Naming collision alert for D-06:** There is a `Crosswake.Manifest.Types.Compatibility` (nested, internal) AND a `Crosswake.Compatibility` (public parent). The D-06 scoping note in `RouteEntry`'s moduledoc must use the full module names to avoid confusion. Recommend listing: "Other nested types (`Crosswake.Manifest.Types.Root`, `Crosswake.Manifest.Types.Host`, etc.) remain `@moduledoc false` and are internal to Crosswake core."

---

### Finding 5: `route_gated?/2` return contract — CONFIRMED [VERIFIED: lib/crosswake/companion.ex]

Line 83-84 of `lib/crosswake/companion.ex`:

```elixir
@callback route_gated?(route :: RouteEntry.t(), context :: Target.t()) ::
            {:deny, Finding.t()} | :pass
```

The return type is closed: `{:deny, Finding.t()} | :pass`. No bare `term()`. `Finding` and `Denial` are already type-separated in the codebase — `Finding` lives in `Crosswake.Compatibility.Finding`, `Denial` in `Crosswake.Shell.Denial`. CONTEXT.md D-13 is accurate. [VERIFIED: lib/crosswake/companion.ex]

---

### Finding 6: `mix.exs docs/0` exact current structure [VERIFIED: mix.exs lines 83-157]

**`extras` list (current, 18 entries):**
```
README.md, guides/see_it_run.md, CHANGELOG.md, LICENSE, guides/install.md,
guides/route_policy.md, guides/web_to_mobile_migration.md, guides/troubleshooting.md,
guides/support_matrix.md, guides/adopter_profiles.md, guides/adoption.md,
guides/user_flows.md, guides/capabilities.md, guides/bridge.md, guides/offline.md,
guides/tokens.md, guides/commerce.md, guides/companions.md, guides/compatibility.md,
guides/native_shell.md, guides/android_uat.md, guides/packs.md, guides/threadline.md
```

**`groups_for_modules` (current, 4 groups):**
```elixir
groups_for_modules: [
  Policy: [Crosswake.Policy, Crosswake.Router],
  Bridge: ~r/Crosswake\.Bridge(\.|$)/,
  Manifest: [Crosswake.Manifest],
  Capabilities: ~r/Crosswake\.(Commerce|Offline|Packs)/
]
```

Groups use a MIX of full module atom lists AND regexes. The existing `Policy` and `Manifest` groups use atom lists. D-10 requires the new "Companion Contract" group to use full names (NOT regex) — this is consistent with the existing `Policy`/`Manifest` group pattern.

**`groups_for_extras` (current, 5 groups):**
```
Start, Adopt, "Runtime Owners", Truth, "Advanced/Companions"
```

D-10 inserts "Extension Authors" between "Truth" and "Advanced/Companions". The new ordering will be:
```
Start, Adopt, "Runtime Owners", Truth, "Extension Authors", "Advanced/Companions"
```

**Orphan-guide guard alert:** `test/crosswake/hex_page_test.exs` lines 151-163 has a live test that FAILS if any `guides/*.md` file exists on disk but is not in `docs[:extras]`. Therefore, `guides/companion_contract.md` MUST be added to the `extras` list in the SAME commit that creates the file, or the existing `hex_page_test` will fail the build. This is a cross-file ordering dependency the planner must capture.

---

### Finding 7: `stable_id_message/7` signature — CONFIRMED [VERIFIED: test/support/proof_assertions.ex]

```elixir
def stable_id_message(id, subject, source, observed, path, hint, posture)
```

Returns a formatted string: `[#{id}] subject=... source=... observed=... path=... hint=... posture=...`

All 7 positional args, all strings. `posture` is conventionally passed as `:merge_blocking` (atom), and the function interpolates it directly. Example usage pattern from phase65:

```elixir
ProofAssertions.stable_id_message(
  "proof.seam_01.companion.callback_shape",        # id
  "Companion.behaviour_info(:callbacks) exact set", # subject
  "Crosswake.Companion.behaviour_info(:callbacks)", # source
  "unexpected callback set: #{inspect(actual)}",    # observed
  "lib/crosswake/companion.ex",                     # path
  "change @expected_callbacks AND @callback defs in SAME PR", # hint
  :merge_blocking                                   # posture
)
```

---

### Finding 8: `behaviour_info(:callbacks)` assertion idiom in existing proof tests [VERIFIED: test/crosswake/proof/]

Three precedents exist:

1. **phase65** (`async: false`, per-test `@tag`): uses membership-only: `assert {:export, 1} in callbacks`
2. **phase48** (`async: true`, no tags): uses membership-only: `assert {:simulate_purchase, 1} in callbacks`
3. **commerce/contracts_test** (`async` not set, no tags): uses membership-only: `callbacks = Crosswake.Commerce.behaviour_info(:callbacks); assert {:submit_purchase_intent, 1} in callbacks`

**None of the precedents uses `MapSet.equal?`** — D-12 introduces this as a deliberate upgrade for Phase 129 specifically because companions form a semver-governed contract. The implementer must write:

```elixir
expected = MapSet.new([
  {:companion_id, 0}, {:enabled?, 1}, {:route_gated?, 2},
  {:kill_switch_active?, 1}, {:validate_dependency, 0}, {:report_state, 0}
])
actual = MapSet.new(Crosswake.Companion.behaviour_info(:callbacks))
assert MapSet.equal?(expected, actual), ProofAssertions.stable_id_message(...)
```

**`async: true` is correct for Phase 129** (unlike phase38/phase65 which are `async: false` due to `Application.put_env` shared state mutations). Phase 129's freeze test is read-only — no `put_env`, no Application state mutation.

---

### Finding 9: `Code.fetch_docs/1` EEP-48 shape [VERIFIED: lib/crosswake/companion.ex + Elixir stdlib]

The function returns:
```
{:docs_v1, anno, beam_language, format, moduledoc, metadata, docs}
```
where `moduledoc` is one of: `%{"en" => "..."}` (present), `:none` (no `@moduledoc`), `:hidden` (`@moduledoc false`).

For the D-14 assertion, check: `moduledoc not in [:none, :hidden]` — i.e., `moduledoc` must be a non-empty map. The `false` atom does not appear here — `@moduledoc false` compiles to `:hidden` at the EEP-48 level. CONTEXT.md's "neither `false`, `:hidden`, nor `:none`" is correct when checking the raw value at the call site; at the EEP-48 level `false` → `:hidden`, but being explicit in the assertion about all three is defensive and correct.

For `@typedoc` assertions: `docs` is a list of `{{kind, name, arity}, anno, signatures, doc, metadata}` tuples. To find `t/0`'s typedoc: filter where `kind == :type`, `name == :t`, `arity == 0`, then check `doc` is not `:none` or `:hidden`.

---

### Finding 10: D-15 feasibility — `Mix.Project.config()[:docs][:groups_for_modules]` [VERIFIED: test/crosswake/hex_page_test.exs]

`test/crosswake/hex_page_test.exs` already uses this exact pattern at line 120:
```elixir
gfm = config()[:docs][:groups_for_modules]
```
where `defp config, do: Mix.Project.config()`.

The return value is a **keyword list** of `{group_name_atom, spec}` pairs where `spec` is either a list of module atoms or a `Regex.t()`. D-15's approach of reading `groups_for_modules` in the proof test and filtering for the `:"Companion Contract"` key to get the module list is feasible and already has a live precedent in `hex_page_test.exs`.

**Gotcha:** When the "Companion Contract" group uses full module name atoms (D-10), `spec` will be `[Crosswake.Companion, Crosswake.Companion.State, ...]` — atom list, not regex. The test can directly use this list as the `expected_modules` set. If the value were a regex (which D-10 explicitly forbids), the test would need to enumerate all loaded modules and filter by regex match — much more complex. Full names keep D-15 trivial.

---

### Finding 11: `guides/companions.md` Denial.reasons mention (D-21) — CONFIRMED [VERIFIED: guides/companions.md]

Lines 167-170 of `guides/companions.md`:

```
- `Crosswake.Shell.Denial.reasons/0`
...
For denial vocabulary, `Crosswake.Shell.Denial.reasons/0` is canonical and includes `:gate_denied`, `:kill_switch_active`, and `:step_up_required`.
```

This is in the "Support Truth Surfaces" section. The NEW `guides/companion_contract.md` must explicitly clarify that companions NEVER call or reference `Denial.reasons/0` — they emit their own denial-code strings via `Finding.t()`. D-21 is addressing real risk: an author reading `guides/companions.md` could reasonably infer that companion implementations should use `Denial.reasons/0` as their vocabulary.

---

### Finding 12: `guides/compatibility.md` "Companion Compatibility Contract" anchor — CONFIRMED [VERIFIED: guides/compatibility.md]

Line 54 of `guides/compatibility.md`:
```markdown
## Companion Compatibility Contract
```

D-08/D-09 instructs the new guide to cross-link to `compatibility.md#companion-compatibility-contract`. ExDoc converts `##` section headings to lowercase-hyphenated anchors, so the correct link is:

```markdown
[guides/compatibility.md#companion-compatibility-contract](compatibility.md#companion-compatibility-contract)
```

---

### Finding 13: `Crosswake.Shell.Denial` moduledoc state — CONFIRMED [VERIFIED: lib/crosswake/shell/denial.ex]

`lib/crosswake/shell/denial.ex` currently has a **real, non-false moduledoc**: `"Stable denial envelope shared by shell activation and bounded bridge replies."` — it is NOT `@moduledoc false`. It is a public core type.

D-20 requires ADDING the steering note to the existing moduledoc (appending, not replacing). The current moduledoc is 1 sentence; after D-20 it will have that sentence plus the steering paragraph.

`Denial.reasons/0` is a real public function returning the `@reasons` module attribute list.

---

### Finding 14: `hex_page_test` will need updating [VERIFIED: test/crosswake/hex_page_test.exs lines 133-139]

The `hex_page_test.exs` groups_for_extras test currently asserts exactly these 5 groups:
```elixir
for group <- [:Start, :Adopt, :"Runtime Owners", :Truth, :"Advanced/Companions"] do
  assert Keyword.has_key?(gfe, group), ...
end
```

Adding "Extension Authors" to `groups_for_extras` in `mix.exs` does NOT break this test (it only checks that the listed groups are present, not that they are the ONLY groups). No update needed to `hex_page_test` for the extras group addition.

However, the `groups_for_modules` test at line 119-130 currently checks:
```elixir
for group <- [:Policy, :Bridge, :Manifest, :Capabilities] do
  assert Keyword.has_key?(gfm, group), ...
end
```
Adding "Companion Contract" does NOT break this test either. But the test at line 127-130 checks that all module atoms in list-type groups are loadable — once `"Companion Contract"` is added with the 5 module atoms, this loop will also iterate over the new group's modules and verify they are loadable. This means the 4 `@moduledoc false` → promotion step does NOT affect `Code.ensure_loaded?` (modules are loaded regardless of `@moduledoc` state), so the hex_page_test will pass even before docs are written. The freeze test is what enforces docs quality.

---

### Finding 15: `guides/companion_contract.md` does not yet exist [VERIFIED: guides/ directory listing]

The file `guides/companion_contract.md` does not exist. It must be created. Due to the orphan-guide guard in `hex_page_test.exs`, it MUST be added to `mix.exs` `extras` in the same commit/wave that creates it.

---

## Standard Stack

This phase uses no external packages. All tooling is already present in the project.

| Tool | Version | Purpose |
|------|---------|---------|
| ExDoc | existing in mix.exs | `groups_for_modules`, `groups_for_extras`, `extras` config |
| ExUnit | built-in | Proof test |
| `Code.fetch_docs/1` | Elixir stdlib | EEP-48 moduledoc/typedoc assertions |
| `Mix.Project.config/0` | Elixir stdlib | Single-source-of-truth module list derivation |

## Package Legitimacy Audit

Not applicable. No new packages are installed in this phase.

---

## Architecture Patterns

### System Architecture Diagram

```
mix.exs docs/0
  ├── extras: [..., "guides/companion_contract.md", ...]
  ├── groups_for_extras: [..., "Extension Authors": [...], ...]
  └── groups_for_modules: [..., "Companion Contract": [5 modules], ...]
         │
         └─→ test reads Mix.Project.config()[:docs][:groups_for_modules]
                    │
                    └─→ phase129 proof test derives expected module set
                             │
                             ├─→ assert moduledoc non-hidden (Code.fetch_docs/1)
                             ├─→ assert typedoc on t() (Code.fetch_docs/1)
                             ├─→ assert callbacks exact set (behaviour_info/MapSet.equal?)
                             ├─→ assert Crosswake.Shell.Denial NOT in group
                             └─→ assert Crosswake.Compatibility.Finding IS in group

lib/crosswake/companion.ex
  └── moduledoc: replace stale para + frozen-surface para

lib/crosswake/companion/state.ex
lib/crosswake/compatibility/compatibility.ex (Finding + Target nested modules)
lib/crosswake/manifest/types.ex (RouteEntry nested module)
  └── @moduledoc false → real moduledoc + ## Stability + @moduledoc since: "0.1.0"

lib/crosswake/shell/denial.ex
  └── moduledoc: append steering note

guides/companion_contract.md (NEW)
  └── cross-linked from guides/companions.md (forward link added)
```

### Recommended File Touches

```
lib/
├── crosswake/
│   ├── companion.ex                    # replace stale para + add frozen-surface block
│   ├── companion/state.ex              # promote @moduledoc false → real docs
│   ├── compatibility/compatibility.ex  # promote Finding + Target nested modules
│   ├── manifest/types.ex               # promote RouteEntry nested module
│   └── shell/denial.ex                 # append steering note to moduledoc
guides/
├── companion_contract.md               # NEW reference guide
└── companions.md                       # add forward cross-link to companion_contract.md
mix.exs                                 # docs/0: new extras entry + two new groups entries
test/crosswake/proof/
└── phase129_companion_contract_freeze_test.exs   # NEW untagged proof test
```

### Pattern 1: Moduledoc promotion with stability note

```elixir
# Source: confirmed idiom from Elixir/Phoenix ecosystem (ExDoc @moduledoc since:)
defmodule Crosswake.Companion.State do
  @moduledoc """
  Typed runtime state snapshot returned by `Crosswake.Companion.report_state/0`.

  ...field documentation...

  ## Stability

  Public stable — part of the Crosswake companion contract surface. Semver-protected
  under `crosswake` >= 0.1.0: no breaking changes to this module's struct fields,
  types, or callbacks without a major version bump. Companion packages
  (`crosswake_rulestead`, `crosswake_rindle`, etc.) may safely `alias` and
  pattern-match on this type.
  """
  @moduledoc since: "0.1.0"

  # ... rest unchanged ...
end
```

**Note on `@moduledoc since:` placement:** It must appear on its OWN LINE, after the closing `"""` of the moduledoc string. This is the ExDoc convention (confirmed from Elixir/Phoenix source and ExDoc docs). [ASSUMED: exact syntax verified against ExDoc docs conventions]

### Pattern 2: EEP-48 moduledoc assertion idiom

```elixir
# Derive module list from single source of truth
contract_modules =
  Mix.Project.config()[:docs][:groups_for_modules]
  |> Keyword.get(:"Companion Contract", [])

for mod <- contract_modules do
  assert match?({:docs_v1, _, _, _, moduledoc, _, _} when is_map(moduledoc),
                Code.fetch_docs(mod)),
         ProofAssertions.stable_id_message(
           "proof.seam_01.moduledoc.#{mod}",
           "#{mod} must have a non-hidden moduledoc",
           "Code.fetch_docs(#{mod})",
           inspect(Code.fetch_docs(mod)),
           "see guides/companion_contract.md and SEAM-01",
           "add @moduledoc with ## Stability section (SEAM-01)",
           :merge_blocking
         )
end
```

### Pattern 3: Callback freeze with MapSet equality

```elixir
# The @expected_callbacks module attribute IS the canonical "pre-phase-129 shape"
@expected_callbacks MapSet.new([
  {:companion_id, 0},
  {:enabled?, 1},
  {:route_gated?, 2},
  {:kill_switch_active?, 1},
  {:validate_dependency, 0},
  {:report_state, 0}
])

test "Companion behaviour callbacks are frozen at the Phase 129 contract shape" do
  actual = MapSet.new(Crosswake.Companion.behaviour_info(:callbacks))

  assert MapSet.equal?(@expected_callbacks, actual),
         ProofAssertions.stable_id_message(
           "proof.seam_01.companion.callback_shape",
           "Crosswake.Companion callbacks must match the frozen Phase 129 set",
           "Crosswake.Companion.behaviour_info(:callbacks)",
           "drift detected — actual: #{inspect(MapSet.to_list(actual))}, expected: #{inspect(MapSet.to_list(@expected_callbacks))}",
           "lib/crosswake/companion.ex",
           "change @expected_callbacks in this test AND the @callback defs in companion.ex in the SAME PR",
           :merge_blocking
         )
end
```

### Pattern 4: Boundary assertion (D-19)

```elixir
test "Crosswake.Shell.Denial is NOT in the Companion Contract module group" do
  contract_modules = Mix.Project.config()[:docs][:groups_for_modules]
                     |> Keyword.get(:"Companion Contract", [])

  refute Crosswake.Shell.Denial in contract_modules,
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

test "Crosswake.Compatibility.Finding IS in the Companion Contract module group" do
  contract_modules = Mix.Project.config()[:docs][:groups_for_modules]
                     |> Keyword.get(:"Companion Contract", [])

  assert Crosswake.Compatibility.Finding in contract_modules,
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

### Anti-Patterns to Avoid

- **Regex in `groups_for_modules` for "Companion Contract":** `~r/Crosswake\.Compatibility/` would pull in the parent `Crosswake.Compatibility` module and all its internal machinery. Use full atom names.
- **Skipping `@moduledoc since:` line:** Without the `since:` option, hexdocs will not show the version badge. The option must be on its own line after the docstring.
- **Membership-only callback assertion:** `assert {:companion_id, 0} in callbacks` passes silently when new callbacks are added. Use `MapSet.equal?` to make additions fail.
- **Testing `moduledoc != false`:** At the EEP-48 level, `@moduledoc false` compiles to `:hidden`. The correct check is `is_map(moduledoc)` (accepting only the map form, rejecting `:none`, `:hidden`, and any atom).
- **Creating `guides/companion_contract.md` without adding it to `mix.exs` extras:** The `hex_page_test.exs` orphan-guide test will fail. Add guide to extras in the same commit.
- **Writing the proof test after the moduledoc promotions:** D-18 says write-test-first is the intended forcing function. The test should be written first, and it will fail until docs are promoted.
- **`async: false` on the Phase 129 proof test:** Unlike phase38 (which uses `Application.put_env`), Phase 129's test is read-only. Use `async: true`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Detecting if moduledoc is present | Custom reflection | `Code.fetch_docs/1` | EEP-48 is the stdlib standard; cross-version stable |
| Listing all public modules | Walk `lib/` tree | `Mix.Project.config()[:docs][:groups_for_modules]` | Single source of truth per D-15 |
| Failure message formatting | Custom string | `ProofAssertions.stable_id_message/7` | Established codebase pattern; grep-friendly stable IDs |
| Checking `@moduledoc since:` version | Parse source | ExDoc renders it; test only checks doc presence | Over-testing source syntax is fragile |

---

## Common Pitfalls

### Pitfall 1: Empty "Companion Contract" hexdocs group
**What goes wrong:** If `groups_for_modules: ["Companion Contract": [...5 modules...]]` is added to `mix.exs` before the modules have real `@moduledoc` strings, the group header renders but with empty content in hexdocs. Modules with `@moduledoc false` are hidden from hexdocs entirely.
**Why it happens:** ExDoc filters out `@moduledoc false` modules from the sidebar.
**How to avoid:** D-11 makes this explicit — promote moduledocs first, then add to `groups_for_modules`. The proof test (D-18 forcing function) enforces this order in CI.
**Warning signs:** `mix docs` produces a "Companion Contract" group with no modules listed.

### Pitfall 2: `guide/companion_contract.md` orphan
**What goes wrong:** Creating the guide file without registering it in `mix.exs` extras causes `hex_page_test.exs` line 151-163 to fail with "Guides exist on disk but are not listed in docs `:extras`".
**Why it happens:** The existing `hex_page_test` has a mandatory orphan guard.
**How to avoid:** Add `"guides/companion_contract.md"` to `mix.exs` extras in the SAME commit/wave as creating the file.
**Warning signs:** `mix test test/crosswake/hex_page_test.exs` fails with the orphan message.

### Pitfall 3: `Crosswake.Manifest.Types.Compatibility` confusion
**What goes wrong:** There is a `Crosswake.Manifest.Types.Compatibility` nested module (internal, `@moduledoc false`) AND a separate `Crosswake.Compatibility` top-level module (public, real moduledoc, NOT in the companion contract). Using a regex like `~r/Crosswake\.Compatibility/` would match both.
**Why it happens:** Name collision between nested type module and the public evaluation module.
**How to avoid:** Use full atom names for the "Companion Contract" group: `Crosswake.Compatibility.Finding` and `Crosswake.Compatibility.Target` — NOT any regex.
**Warning signs:** Both `Crosswake.Compatibility` AND `Crosswake.Compatibility.Finding` appearing in the group when only Finding/Target should.

### Pitfall 4: Scoping `RouteEntry`'s stability note
**What goes wrong:** Authors reading `RouteEntry`'s moduledoc might infer that ALL `Crosswake.Manifest.Types.*` nested modules are public contract.
**Why it happens:** `RouteEntry` lives inside `Crosswake.Manifest.Types`, which has 20+ internal nested modules.
**How to avoid:** D-06 requires explicitly naming that other nested modules (`Root`, `Host`, `Compatibility`, etc.) remain `@moduledoc false` and internal. Include a sentence like: "Only `RouteEntry.t()` is part of the companion contract surface. All other nested modules in `Crosswake.Manifest.Types` are `@moduledoc false` and internal to Crosswake core."

### Pitfall 5: `Denial.reasons/0` cargo-culted into companion guide
**What goes wrong:** The existing `guides/companions.md` (line 167) references `Crosswake.Shell.Denial.reasons/0` as a "Support Truth Surface." An author reading this might try to use `Denial.reasons/0` to author their companion's denial vocabulary.
**Why it happens:** `companions.md` predates the companion contract surface formalization. The line is technically correct for core operators, but misleading for companion AUTHORS.
**How to avoid:** D-21 requires `guides/companion_contract.md` to explicitly state companions never reference `Denial.reasons/0`. The "What Is Not Contract" section is the right place. Do NOT modify `companions.md` to remove the `Denial.reasons/0` reference (it's accurate for the core-operator audience of that guide).

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/crosswake/proof/phase129_companion_contract_freeze_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SEAM-01 | 5 contract modules have non-hidden `@moduledoc` and `@typedoc` on `t()` | proof | `mix test test/crosswake/proof/phase129_companion_contract_freeze_test.exs` | ❌ Wave 0 |
| SEAM-01 | `Crosswake.Companion` callback set is frozen at exactly 6 callbacks | proof | `mix test test/crosswake/proof/phase129_companion_contract_freeze_test.exs` | ❌ Wave 0 |
| SEAM-02 | `guides/companion_contract.md` file exists on disk | proof (file check) | `mix test test/crosswake/proof/phase129_companion_contract_freeze_test.exs` | ❌ Wave 0 |
| SEAM-03 | `Crosswake.Shell.Denial` absent from contract group | proof | `mix test test/crosswake/proof/phase129_companion_contract_freeze_test.exs` | ❌ Wave 0 |
| SEAM-03 | `Crosswake.Compatibility.Finding` present in contract group | proof | `mix test test/crosswake/proof/phase129_companion_contract_freeze_test.exs` | ❌ Wave 0 |
| SEAM-04 | "Companion Contract" group exists in `groups_for_modules` | unit (hex_page_test already covers all groups) | `mix test test/crosswake/hex_page_test.exs` | ✅ (guards group membership) |
| SEAM-04 | "Extension Authors" group exists in `groups_for_extras` | unit | `mix test test/crosswake/hex_page_test.exs` | — (test only checks existing groups; new group auto-tested once hex_page_test updated) |
| SEAM-04 | `guides/companion_contract.md` in extras | integration | `mix test test/crosswake/hex_page_test.exs` | ✅ (orphan guard auto-triggers) |

### Sampling Rate
- **Per task commit:** `mix test test/crosswake/proof/phase129_companion_contract_freeze_test.exs test/crosswake/hex_page_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/crosswake/proof/phase129_companion_contract_freeze_test.exs` — covers SEAM-01, SEAM-02, SEAM-03 (all assertions)
- Note: `hex_page_test.exs` already exists and guards SEAM-04 (orphan guide, groups presence) — no new test file needed for SEAM-04, only `mix.exs` changes

---

## Security Domain

Not applicable. This phase writes documentation and one read-only test assertion. No user input, no authentication, no cryptography, no data storage changes.

---

## Open Questions

1. **`@moduledoc since:` syntax**
   - What we know: `@moduledoc since: "0.1.0"` must appear on its own line AFTER the closing `"""` of the string
   - What's unclear: Whether ExDoc requires it to be immediately adjacent to the `@moduledoc` string or can be anywhere in the module body before `def` functions
   - Recommendation: Place it on the line immediately following the closing `"""` — that is the conventional placement in Elixir standard library source and avoids ambiguity. [ASSUMED]

2. **hex_page_test groups_for_extras gap**
   - What we know: The test currently checks for exactly 5 known groups in `groups_for_extras`; adding "Extension Authors" as group 6 does not break the existing test
   - What's unclear: Whether the planner should also update `hex_page_test.exs` to assert "Extension Authors" is present (closing the gap for future regressions)
   - Recommendation: Add "Extension Authors" to the groups_for_extras assertion in `hex_page_test.exs` as part of this phase. Low-cost, high-value.

3. **`guides/companion_contract.md` telemetry events section content**
   - What we know: D-09 says to include 3 static companion span names; the 3 are documented in `Crosswake.Companion`'s moduledoc under "## Telemetry events"
   - What's unclear: Whether to quote these verbatim from the moduledoc or describe them in the guide's own words
   - Recommendation: Reference/link to `Crosswake.Companion` moduledoc for the definitive list; guide should list the 3 names with one-line descriptions, noting the moduledoc is the source of truth (DRY with D-07).

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `@moduledoc since: "0.1.0"` must appear on its own line AFTER the closing `"""` | Patterns section | Syntax error at compile time if wrong placement; easy to verify with `mix compile` |
| A2 | ExDoc renders `@moduledoc since:` as a version badge on the module page | Architecture/Patterns | Badge does not appear; purely cosmetic, does not affect contract enforcement |

---

## Sources

### Primary (HIGH confidence)
- `lib/crosswake/companion.ex` — exact 6 callbacks, exact stale moduledoc text, exact `route_gated?/2` return type
- `lib/crosswake/companion/state.ex` — confirmed `@moduledoc false`, `t()` type present
- `lib/crosswake/compatibility/compatibility.ex` — confirmed `Finding` and `Target` both `@moduledoc false`, parent `Crosswake.Compatibility` has real moduledoc
- `lib/crosswake/manifest/types.ex` — complete list of 20+ nested modules, all `@moduledoc false` except RouteEntry (also false, awaiting promotion)
- `lib/crosswake/shell/denial.ex` — confirmed real moduledoc, `reasons/0` is a public function
- `mix.exs` lines 83-157 — exact `docs/0` structure, 4 existing groups_for_modules entries (2 atom-list, 2 regex), 5 groups_for_extras
- `test/support/proof_assertions.ex` — `stable_id_message/7` exact signature (7 positional args)
- `test/crosswake/proof/phase65_diagnostic_export_seam_test.exs` — membership-only `behaviour_info` idiom, `@tag` per test, `async: false`
- `test/crosswake/proof/phase38_companion_contract_test.exs` — `async: false`, untagged
- `test/crosswake/commerce/contracts_test.exs` — membership-only `behaviour_info` idiom
- `test/crosswake/hex_page_test.exs` — `Mix.Project.config()[:docs][:groups_for_modules]` pattern, orphan-guide test
- `guides/companions.md` line 167 — `Denial.reasons/0` reference confirmed
- `guides/compatibility.md` line 54 — "## Companion Compatibility Contract" anchor confirmed

### Secondary (MEDIUM confidence)
- ExDoc `@moduledoc since:` placement convention [ASSUMED from Elixir ecosystem knowledge]

---

## Metadata

**Confidence breakdown:**
- Callback set: HIGH — read directly from source, exact count confirmed
- `@moduledoc false` states: HIGH — read directly from all 4 source files
- `mix.exs` docs structure: HIGH — read directly, exact line numbers
- Proof test idioms: HIGH — read from 3 existing precedent files
- `stable_id_message/7` signature: HIGH — read from source
- EEP-48 assertion approach: HIGH — confirmed via hex_page_test precedent
- `@moduledoc since:` placement: MEDIUM/ASSUMED — ecosystem convention

**Research date:** 2026-06-25
**Valid until:** 2026-07-25 (stable Elixir docs API; source files locked until Phase 130)
