# Phase 33: Corridor Routes And CI Infrastructure — Research

**Researched:** 2026-05-29
**Domain:** Phoenix router DSL, Crosswake commerce policy schema, GitHub Actions CI
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Declare all three corridor routes in a new `scope "/commerce", CrosswakeExample` block in `examples/phoenix_host/lib/crosswake_example/router.ex`, each carrying `commerce: [corridor: :subscription_default, role: <role>]` so every role_ownership entry lands in the manifest.
- **D-02:** `paywall_entry` → `live "/paywall", PaywallEntryLive, :index, commerce: [corridor: :subscription_default, role: :paywall_entry]`.
- **D-03:** `purchase_intent` and `restore_intent` → `post` controller routes (CorridorController, :purchase / :restore). Rationale: both roles are `:native_or_companion_required`; declaring as `live` screens would misrepresent native-owned corridors.
- **D-04:** Forward-reference `PaywallEntryLive` and `CorridorController` (both land in Phase 35). No throwaway stub modules.
- **D-05:** Add the two forward-referenced modules to `@compile {:no_warn_undefined, ...}`.
- **D-06:** Two-job split mirroring `.github/workflows/phase23-proof.yml`: hermetic `merge-blocking` job + advisory job with `continue-on-error: true`, including the 4-condition `promotion_path` comment block.
- **D-07:** Hermetic job runs: `mix compile --warnings-as-errors` then `mix test --exclude requires_example_host`.
- **D-08:** `requires_example_host` tags only server/integration-backed example tests. Phase 36 proof stays UNtagged; uses `Code.require_file` at module scope (mirrors phase21/phase23).
- **D-09:** Advisory job = echo placeholder steps (StoreKit / Play Billing / device-storefront), `continue-on-error: true`, `schedule` + `workflow_dispatch` only. Hermetic job triggers on `pull_request` + `push` to main + `workflow_dispatch`.
- **D-10:** Workflow filename is `phase34-proof.yml` (named for the milestone proof surface it gates, not the phase creating it).

### Claude's Discretion

- Exact `/commerce` sub-paths (`/paywall`, `/purchase`, `/restore`), pipeline reuse (`:browser` vs dedicated), controller/LiveView module names, and whether the proof job lists the proof file explicitly vs relies on broad `mix test`.

### Deferred Ideas (OUT OF SCOPE)

- PubSub startup (Phase 35 prerequisite)
- CorridorController action bodies (Phase 35)
- Verification simulation shape (Phase 35)
- Retroactive SHA-pinning of pre-v3.3 proof workflows
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PWAL-01 | Adopter can copy a `paywall_entry` route declaring `commerce: [corridor: :subscription_default, role: :paywall_entry]` from `examples/phoenix_host` | Schema validation accepts atom form; normalizes to string internally; existing proof tests confirm this pattern works verbatim |
| PROOF-02 | A `phase34-proof.yml` two-job CI split keeps hermetic lane merge-blocking (`--exclude requires_example_host` honored) while provider/storefront/device checks stay advisory-only, with documented 4-condition `promotion_path` | `phase23-proof.yml` is a complete working template; exact copy-and-adapt path documented below |
</phase_requirements>

---

## Summary

Phase 33 is pure scaffolding: two files change. The `examples/phoenix_host` router gains a new `scope "/commerce"` block declaring three `subscription_default` corridor routes, and `.github/workflows/phase34-proof.yml` is created as a two-job CI split mirroring `phase23-proof.yml`. No commerce logic, no LiveView bodies, no proof test.

The single real technical unknown going into this phase was whether the schema validator accepts the atom form `corridor: :subscription_default` or requires the string `"subscription_default"`. This is now fully resolved: **the atom form is the correct DSL form** — `validate_commerce_declaration` funnels the corridor value through `validate_identifier`, which calls `Atom.to_string/1` on atoms (schema.ex:126). The stored `commerce_declaration` map always holds `corridor: "subscription_default"` (string), but adopters write `:subscription_default` (atom). Existing proof tests at phase23 use the atom form verbatim (`commerce: [corridor: :subscription_default, role: :paywall_entry]`). The ROADMAP's success criterion #1 is satisfiable exactly as written.

The manifest builder's `commerce_corridor_registry/1` reads only the route's `commerce:` policy metadata — specifically the normalized string `corridor` value — and does a `Map.get` against `CorridorProfiles.commerce_corridors()` which is keyed by `"subscription_default"` (string). Forward-referencing `PaywallEntryLive` and `CorridorController` is safe because the builder never touches the route target module. The `route_commerce/1` guard at builder.ex:210 explicitly asserts `is_binary(corridor)`, confirming the post-normalization contract.

The CI template diff between `phase23-proof.yml` and what `phase34-proof.yml` needs is minimal: swap the hermetic test invocation from explicit file list to `mix test --exclude requires_example_host`, update the advisory echo steps to reference the Phase 34+ commerce proof surface, and adjust the workflow `name:` and step names accordingly.

**Primary recommendation:** Write the router block and CI file in one plan wave. No preparatory work needed — all prerequisites (schema, corridor profiles, manifest builder, CI template) are already in place.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Route declarations (DSL) | Example host router (`examples/phoenix_host`) | — | The example router is the adopter-facing teaching artifact; all commerce DSL lives here |
| Commerce policy schema validation | Library (`lib/crosswake/policy/schema.ex`) | — | Already exists; router invokes it at compile time via `crosswake_defaults` |
| Manifest corridor registry | Library (`lib/crosswake/manifest/builder.ex`) | — | Auto-discovers from route metadata; no registration step needed in this phase |
| CI merge gate | `.github/workflows/phase34-proof.yml` | — | New file; hermetic job gates merges; advisory job never blocks |
| Forward-reference suppression | Router `@compile` attribute | — | `@compile {:no_warn_undefined, ...}` prevents warnings for modules landing in Phase 35 |

---

## Standard Stack

No new packages. This phase is purely additive file changes using existing infrastructure.

### Core (existing — reuse, do not modify)

| Module | File | Purpose |
|--------|------|---------|
| `Crosswake.Router` | `lib/crosswake/router.ex` | Provides `crosswake_defaults` macro used in new scope |
| `Crosswake.Policy.Schema` | `lib/crosswake/policy/schema.ex` | Validates `commerce:` declarations at compile time |
| `Crosswake.Policy.CorridorProfiles` | `lib/crosswake/policy/corridor_profiles.ex` | Provides `:subscription_default` profile at manifest build time |
| `Crosswake.Manifest.Builder` | `lib/crosswake/manifest/builder.ex` | Auto-discovers corridor registry from route metadata |
| `Crosswake.SupportMatrix` | `lib/crosswake/support_matrix/support_matrix.ex` | Exposes `commerce_corridors/0` for verification |

### CI Infrastructure (existing — copy-and-adapt)

| File | Purpose |
|------|---------|
| `.github/workflows/phase23-proof.yml` | Source template for `phase34-proof.yml` |

---

## Package Legitimacy Audit

No new packages are installed in this phase. [VERIFIED: codebase inspection — zero `mix.exs` changes]

---

## Architecture Patterns

### System Architecture Diagram

```
Router DSL (author writes atom form)
  :subscription_default (atom)
        |
        v
crosswake_defaults macro → Crosswake.Policy.Schema.validate_commerce_declaration/1
        |
        v  validate_optional_identifier → validate_identifier → Atom.to_string/1
        |
  "subscription_default" (string stored in %{corridor: "subscription_default", role: :paywall_entry})
        |
        v
Route struct: %Route{commerce: %{corridor: "subscription_default", role: :paywall_entry}}
        |
        v
Manifest.Builder.commerce_corridor_registry/1
  Map.get(canonical_profiles, "subscription_default")  ← CorridorProfiles keyed by string
        |
        v
%CommerceCorridor{id: "subscription_default", role_ownership: %{paywall_entry: :phoenix_owned, ...}}
        |
        v
SupportMatrix.commerce_corridors/0  ← verification accessor for success criterion #2
```

### Recommended Project Structure

No new directories. Two file writes:

```
.github/workflows/
└── phase34-proof.yml          [NEW]

examples/phoenix_host/lib/crosswake_example/
└── router.ex                  [MODIFIED — add scope "/commerce" block]
```

### Pattern 1: Commerce Route DSL Shape

**What:** A `scope "/commerce"` block inside `crosswake_defaults do` with the three corridor routes, forward-referencing Phase 35 modules. [VERIFIED: schema.ex:140-154, phase23 proof test:47-86]

```elixir
# Source: examples/phoenix_host/lib/crosswake_example/router.ex (Phase 33 addition)
scope "/commerce", CrosswakeExample do
  pipe_through :browser

  crosswake_defaults do
    live "/paywall", PaywallEntryLive, :index,
      commerce: [corridor: :subscription_default, role: :paywall_entry]

    post "/purchase", CorridorController, :purchase,
      commerce: [corridor: :subscription_default, role: :purchase_intent]

    post "/restore", CorridorController, :restore,
      commerce: [corridor: :subscription_default, role: :restore_intent]
  end
end
```

**Atom form accepted:** `validate_identifier/1` converts atom to string (schema.ex:126); the stored commerce_declaration uses `"subscription_default"` string internally. [VERIFIED: schema.ex:124-127, builder.ex:209-212]

### Pattern 2: Forward-Reference Suppression

**What:** Router already uses `@compile {:no_warn_undefined, CrosswakeExample.Crosswake.Policy}` (router.ex:28). Add both Phase 35 modules. [VERIFIED: router.ex:28]

```elixir
# Source: examples/phoenix_host/lib/crosswake_example/router.ex (line 28, existing pattern)
@compile {:no_warn_undefined, CrosswakeExample.Crosswake.Policy}
# Add for Phase 33:
@compile {:no_warn_undefined, CrosswakeExample.PaywallEntryLive}
@compile {:no_warn_undefined, CrosswakeExample.CorridorController}
```

The `@compile {:no_warn_undefined, Mod}` attribute accepts one module per attribute declaration. Each forward-referenced module needs its own attribute line. [ASSUMED — standard Elixir `@compile` behavior; no single-declaration multi-module form verified]

### Pattern 3: CI Two-Job Split (phase34-proof.yml)

**What:** Direct copy-and-adapt from `phase23-proof.yml`. The structure is fully documented in the source file with inline rationale comments. [VERIFIED: .github/workflows/phase23-proof.yml — read in full]

Key structural elements to preserve verbatim:
- The `name:` field at workflow top level
- All four trigger events on the `on:` block: `pull_request`, `push: branches: [main]`, `workflow_dispatch`, `schedule`
- The `if: ${{ github.event_name == 'pull_request' || ... || github.event_name == 'workflow_dispatch' }}` guard on the hermetic job (skips on `schedule`)
- The `if: ${{ github.event_name == 'schedule' || github.event_name == 'workflow_dispatch' }}` guard on the advisory job
- `continue-on-error: true` on the advisory job
- The 4-condition `promotion_path` comment block (lines 19-28 of phase23-proof.yml) — copy verbatim, update milestone references
- `uses: actions/checkout@v6` and `uses: erlef/setup-beam@v1` with pinned versions

Key swaps for `phase34-proof.yml`:
- Hermetic test step: replace the explicit `mix test test/crosswake/proof/phase23_commerce_support_proof_test.exs` + multi-file run with `mix test --exclude requires_example_host` (D-07)
- Advisory echo steps: replace Phase 23 advisory echo content with Phase 34+ advisory content (StoreKit / Play Billing / device-storefront placeholders remain; update references from "v3.2" to "v3.4" commerce surface)
- `name:` at workflow top: `Phase 34 Proof`
- Job `name:` fields: update to reference Phase 34 paywall corridor proof

### Anti-Patterns to Avoid

- **Stub module creation:** Do NOT create empty `PaywallEntryLive` or `CorridorController` modules in Phase 33. Phoenix router uses quoted AST so `mix compile` succeeds without them. Stubs would need to be deleted or modified in Phase 35 — unnecessary churn. [VERIFIED: D-04, CONTEXT.md:125]
- **String form in DSL:** Do NOT write `corridor: "subscription_default"` in the router — adopter-facing code should show the atom form (cleaner DSL, consistent with all existing crosswake policy options). [VERIFIED: phase23 proof tests use atom form]
- **Tagging Phase 36 proof test:** Do NOT add `@moduletag :requires_example_host` to the Phase 36 proof file. It must stay untagged to run inside the hermetic merge-blocking lane. [VERIFIED: D-08]
- **Modifying `crosswake_defaults` defaults:** The new scope should NOT pass global defaults to `crosswake_defaults` (e.g., `runtime:`, `offline:`) unless all three routes share them. The `live` route will carry its own `runtime: :live_view`; the `post` routes carry none of those fields. Omit global crosswake_defaults args or set only shared values.

---

## Critical Finding: Atom-vs-String Schema Reconciliation

**Status: RESOLVED — NO BLOCKER** [VERIFIED: schema.ex:124-154, builder.ex:158-214, phase23 proof tests]

### Evidence Chain

**Step 1 — Input form (what adopter writes in DSL):**
```elixir
commerce: [corridor: :subscription_default, role: :paywall_entry]
```
Atom form. This is the canonical DSL shape for all crosswake options.

**Step 2 — Validation path (schema.ex:140-154):**
```elixir
def validate_commerce_declaration(declaration) when is_list(declaration) do
  declaration
  |> Enum.into(%{})
  |> validate_commerce_declaration()
end

def validate_commerce_declaration(declaration) when is_map(declaration) do
  with {:ok, corridor} <-
         validate_optional_identifier(
           Map.get(declaration, :corridor, Map.get(declaration, "corridor"))
         ),
```
The keyword list `[corridor: :subscription_default]` is converted to map `%{corridor: :subscription_default}` then `validate_optional_identifier/1` is called on the atom `:subscription_default`.

**Step 3 — Atom normalization (schema.ex:124-127):**
```elixir
def validate_identifier(value) when is_binary(value) and byte_size(value) > 0, do: {:ok, value}
def validate_identifier(value) when is_atom(value), do: {:ok, Atom.to_string(value)}
def validate_identifier(_value), do: {:error, "expected a non-empty string or atom"}
```
`:subscription_default` → `{:ok, "subscription_default"}`. The stored commerce_declaration map is `%{corridor: "subscription_default", role: :paywall_entry}`.

**Step 4 — Type annotation vs runtime value (schema.ex:82-85):**
```elixir
@type commerce_declaration :: %{
  corridor: String.t() | nil,
  role: commerce_role() | nil
}
```
The `String.t()` type annotation describes the *post-validation stored form*, not the input form. Both atom and string inputs are accepted; strings are stored. The CONTEXT.md flag about `String.t() | nil` in the type spec was correct to note — but it describes the output of validation, not a restriction on input.

**Step 5 — Manifest builder guard (builder.ex:209-212):**
```elixir
defp route_commerce(%Route{commerce: %{corridor: corridor, role: role}})
     when is_binary(corridor) and is_atom(role) do
  Types.new_route_commerce(corridor_ref: corridor, role: role)
end
```
The builder explicitly requires `is_binary(corridor)`. The atom form in the DSL produces a string after validation — this guard is satisfied.

**Step 6 — CorridorProfiles key form (corridor_profiles.ex:18):**
```elixir
@commerce_corridors %{
  "subscription_default" => %{id: "subscription_default", ...}
}
```
String key. The `commerce_corridor_registry/1` does `Map.get(canonical_profiles, corridor_ref)` where `corridor_ref` is the post-normalization string `"subscription_default"`. Match confirmed.

**Step 7 — Existing proof test confirmation (phase23_commerce_support_proof_test.exs:51):**
```elixir
commerce: [corridor: :subscription_default, role: :paywall_entry]
```
The atom form has been in production use since Phase 23. Success criterion #1 is satisfiable as written.

**Verdict:** The ROADMAP's "atom form `corridor: :subscription_default`" is correct DSL. The `String.t()` in the type_spec is the internal stored form. No reconciliation needed — the implementation already handles both.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Corridor registration in manifest | Manual registry or separate config | `commerce_corridor_registry/1` auto-discovery | Builder reads route `commerce:` metadata automatically; any route with a valid `commerce:` declaration is discovered |
| Stub modules for compile safety | Empty `PaywallEntryLive` / `CorridorController` modules | `@compile {:no_warn_undefined, Mod}` | Phoenix router uses quoted AST; stubs are unnecessary and create Phase 35 debt |
| Custom CI job structure | New workflow shape | Copy `phase23-proof.yml` structure | The pattern (hermetic gate + advisory placeholder + promotion_path commentary) is established project discipline |

---

## Runtime State Inventory

Not applicable — greenfield file additions, no rename/migration.

---

## Common Pitfalls

### Pitfall 1: `crosswake_defaults` defaults contaminating POST routes

**What goes wrong:** If the `crosswake_defaults do` block is given `runtime: :live_view` as a default, it would be applied to the `post "/purchase"` and `post "/restore"` routes, which are controller routes, not LiveView screens. This may cause validation errors or mislead manifest consumers.
**Why it happens:** Existing router scopes all use `crosswake_defaults runtime: :live_view, offline: :cached_read_only` — copying that pattern blindly into the commerce scope would apply inappropriate defaults.
**How to avoid:** Either omit `runtime:` from the `crosswake_defaults` call entirely (letting each route carry its own declaration), or pass only values that apply to all three routes. The `live` route already declares `commerce:` inline; the `post` routes declare `commerce:` inline. No shared crosswake defaults are needed.
**Warning signs:** Compile-time `NimbleOptions.ValidationError` for a non-LiveView route with `runtime: :live_view` set.

### Pitfall 2: `@compile {:no_warn_undefined, [Mod1, Mod2]}` list form

**What goes wrong:** Some Elixir versions or documentation examples show `@compile {:no_warn_undefined, [ModA, ModB]}` list form — this is NOT the established pattern in this router. The router uses one `@compile` per module.
**Why it happens:** Documentation ambiguity; list form may not be universally supported.
**How to avoid:** Follow the existing router pattern: one `@compile {:no_warn_undefined, Mod}` line per forward-referenced module.
**Warning signs:** `mix compile --warnings-as-errors` still emitting undefined module warnings after adding the attribute.

### Pitfall 3: Advisory job triggering on `pull_request`

**What goes wrong:** If the `if:` guard on the advisory job is omitted or set to match `pull_request`, the advisory job could theoretically block merges (if `continue-on-error` is not set or is accidentally removed).
**Why it happens:** Copying only part of the phase23 job structure without the `if:` guard.
**How to avoid:** The advisory job MUST have `if: ${{ github.event_name == 'schedule' || github.event_name == 'workflow_dispatch' }}` AND `continue-on-error: true`. Both are required.
**Warning signs:** Advisory job appears in PR check list as a required status check.

### Pitfall 4: Missing `mix compile --warnings-as-errors` as a separate step

**What goes wrong:** Running only `mix test` in the hermetic CI job skips compile-time warning detection. A missing module warning that `@compile {:no_warn_undefined, ...}` was supposed to suppress would only be caught at test run, with a less obvious error.
**Why it happens:** Assuming `mix test` always compiles first (it does, but without `--warnings-as-errors`).
**How to avoid:** Keep `mix compile --warnings-as-errors` as an explicit step before `mix test --exclude requires_example_host`, mirroring phase23.

---

## Code Examples

### Commerce Scope Block (final form)

```elixir
# Source: D-01/D-02/D-03, verified against schema.ex and existing router patterns
scope "/commerce", CrosswakeExample do
  pipe_through :browser

  crosswake_defaults do
    live "/paywall", PaywallEntryLive, :index,
      commerce: [corridor: :subscription_default, role: :paywall_entry]

    post "/purchase", CorridorController, :purchase,
      commerce: [corridor: :subscription_default, role: :purchase_intent]

    post "/restore", CorridorController, :restore,
      commerce: [corridor: :subscription_default, role: :restore_intent]
  end
end
```

### Forward-Reference Attributes (append to existing @compile line block)

```elixir
# Source: D-05, mirrors router.ex:28 pattern
@compile {:no_warn_undefined, CrosswakeExample.PaywallEntryLive}
@compile {:no_warn_undefined, CrosswakeExample.CorridorController}
```

### phase34-proof.yml Hermetic Job Test Step

```yaml
# Source: D-07 — replaces phase23's explicit file list with broad hermetic run
- name: Run hermetic Phase 34 paywall corridor proof lane
  run: mix test --exclude requires_example_host
```

### phase34-proof.yml Workflow Header (promotion_path comment block)

```yaml
# Source: phase23-proof.yml lines 19-28 — copy verbatim, update milestone references
# Advisory-to-merge-blocking promotion is NOT automatic. Promoting an advisory
# lane to merge-blocking requires:
#   1. An explicit requirement / roadmap scope change documented in
#      .planning/REQUIREMENTS.md and .planning/ROADMAP.md.
#   2. Sustained stability evidence from the advisory lane (typically several
#      consecutive scheduled runs without flakes).
#   3. A planned milestone that ships the provider adapter (the proof lane
#      cannot be merge-blocking before the code it proves is core scope).
#   4. An explicit workflow edit moving the relevant step from
#      advisory-commerce-proof into merge-blocking-commerce-proof, plus
#      branch-protection updates if needed.
```

---

## Manifest Landing Verification

**Finding: Forward-referencing Phase 35 modules is safe.** [VERIFIED: builder.ex:158-187, 209-214]

The `commerce_corridor_registry/1` function (builder.ex:158-187):
1. Iterates `routes` matching `%Route{commerce: %{corridor: corridor}}` — extracts only the corridor string
2. Looks up the corridor in `CorridorProfiles.commerce_corridors()` — a compile-time map, no module reference
3. Builds `CommerceCorridor` structs from profile data — no target module used

The `route_commerce/1` function (builder.ex:209-212):
- Extracts `corridor_ref` (string) and `role` (atom) — never touches the target module

The three new routes will appear in the manifest with:
- `commerce_corridors["subscription_default"]` → `CommerceCorridor{id: "subscription_default", role_ownership: %{paywall_entry: :phoenix_owned, purchase_intent: :native_or_companion_required, restore_intent: :native_or_companion_required, account_management: :phoenix_owned}, denial: "commerce.corridor.unsupported", ...}` [VERIFIED: corridor_profiles.ex:17-34]
- Each route entry carries `RouteCommerce{corridor_ref: "subscription_default", role: :paywall_entry/:purchase_intent/:restore_intent}`

Note: `SupportMatrix.commerce_corridors/0` (support_matrix.ex:233) returns `@commerce_corridor_entries` which is a static compile-time list — it does NOT dynamically read the example host's manifest. Verification of "routes appear in manifest" must use `Manifest.Builder.build/2` directly against the example host router, not `SupportMatrix.commerce_corridors/0`. See Validation Architecture below.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `mix test test/specific_file.exs` in hermetic CI | `mix test --exclude requires_example_host` (broad run) | Phase 33 (D-07) | Phase 36 proof file is automatically included without explicit listing; tag discipline is the gate |
| Phase 23 proof file targeted explicitly in CI | Broad `--exclude` tag approach | Phase 33 | Simpler CI; relies on tag discipline rather than file list maintenance |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `@compile {:no_warn_undefined, Mod}` requires one attribute per module (not list form) | Pattern 2, Pitfall 2 | If list form is supported, no harm — the single-per-line form is strictly safe; list form would be shorter but not necessary |
| A2 | The Phase 36 proof test file will be discovered automatically by `mix test --exclude requires_example_host` without explicit path listing | D-07 | If the proof file lives outside the standard test tree, it would not be discovered — but phase discipline places it in `test/crosswake/proof/` (confirmed by phase23 precedent) |

**All other claims are VERIFIED against source files read in this session.**

---

## Validation Architecture

> nyquist_validation: true — this section is required.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in to Elixir/OTP) |
| Config file | `test/test_helper.exs` (existing) |
| Quick compile check | `mix compile --warnings-as-errors` |
| Full suite command | `mix test --exclude requires_example_host` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PWAL-01 | `paywall_entry` route with `commerce: [corridor: :subscription_default, role: :paywall_entry]` is copy-able from the example host router | Compile + manifest introspection | `mix compile --warnings-as-errors` (compile gate); manifest assertion in existing test or new inline check | ✅ existing test infrastructure |
| PROOF-02 | `phase34-proof.yml` has hermetic job + advisory job + promotion_path comment | YAML file structure assertion | Inspect file existence + grep for required job names and `promotion_path` string | ❌ Wave 0 gap — new file |

### Success Criterion → Verification Map

**Criterion 1: Adopter can copy the `paywall_entry` route declaration and see the canonical DSL shape**
- Verification: `mix compile --warnings-as-errors` in the project root passes cleanly.
- Deeper check: `Code.require_file` on the router in a test, build the manifest, assert `manifest.routes` contains a route with `commerce.corridor_ref == "subscription_default"` and `commerce.role == :paywall_entry`.
- Accessible via: `Manifest.Builder.build(CrosswakeExample.Router.crosswake_routes(), [])` then check `manifest.routes`.
- Note: this is a compile-time artifact — no HTTP request needed.

**Criterion 2: All three corridor routes appear in the manifest with correct corridor metadata**
- Verification: Manifest assertion test.
  ```elixir
  routes = CrosswakeExample.Router.crosswake_routes()
  manifest = Crosswake.Manifest.Builder.build(routes, [])
  corridor = manifest.commerce_corridors["subscription_default"]
  assert corridor.role_ownership.paywall_entry == :phoenix_owned
  assert corridor.role_ownership.purchase_intent == :native_or_companion_required
  assert corridor.role_ownership.restore_intent == :native_or_companion_required
  ```
  Role ownership values sourced from: `corridor_profiles.ex:20-25` [VERIFIED].
  All three route roles will produce a single `commerce_corridors["subscription_default"]` entry (the registry deduplicates by corridor, not by role).
- Each route's `RouteCommerce` can be verified via the route entry's `commerce` field in `manifest.routes`.

**Criterion 3: `phase34-proof.yml` exists with both jobs + promotion_path comment**
- Verification: File existence check + structural assertions:
  - `File.exists?(".github/workflows/phase34-proof.yml")` → true
  - File contains `merge-blocking` job name string
  - File contains `advisory` job name string
  - File contains `continue-on-error: true`
  - File contains `promotion_path` comment string (or the canonical 4-condition text)
  - File contains the `if: ${{ github.event_name == 'schedule'` guard on advisory job
- These are grep/string-presence assertions, not YAML parse assertions. Fast, hermetic.

**Criterion 4: Hermetic CI job runs `mix test --exclude requires_example_host` cleanly**
- Verification: The hermetic CI job itself, once the workflow file exists and a PR is opened. Locally: `mix test --exclude requires_example_host` from repo root.
- Pre-merge local gate: `mix compile --warnings-as-errors && mix test --exclude requires_example_host`.

### Sampling Rate

- **Per task commit:** `mix compile --warnings-as-errors` — catches forward-reference warning suppressions and DSL validation errors immediately.
- **Per wave merge:** `mix compile --warnings-as-errors && mix test --exclude requires_example_host` — confirms manifest discovery and no regression in existing tests.
- **Phase gate:** Full suite + CI workflow file existence check before `/gsd-verify-work`.

### Wave 0 Gaps

- [ ] No new test files needed in Wave 0 — manifest assertions for corridor presence can be added as a brief inline check in the plan, or verified post-hoc against existing `phase23_commerce_support_proof_test.exs` infrastructure. The Phase 33 plan should include a verification step asserting the manifest and the workflow file structure.
- [ ] `.github/workflows/phase34-proof.yml` — new file; CI gate activates on first PR after creation.

*(No new test framework install needed — ExUnit is already in the project.)*

---

## Security Domain

The security_enforcement setting is not explicitly `false` in config.json — including this section.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No auth on commerce routes in Phase 33 (auth is explicitly out of scope per AF-05) |
| V3 Session Management | No | No session handling in Phase 33 scaffold |
| V4 Access Control | No | Corridor declaration only; access control is adopter responsibility |
| V5 Input Validation | Yes (compile-time) | `Crosswake.Policy.Schema.validate_commerce_declaration/1` validates at compile time via NimbleOptions custom validator |
| V6 Cryptography | No | No cryptographic operations |

No runtime security surface is introduced in Phase 33. The routes are declaration artifacts only — no request handlers, no session reads, no auth gates. The compile-time schema validation provides input validation for the corridor/role values.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | Route compilation, test suite | ✅ | Project uses OTP 27.3 / Elixir 1.19.5 per phase23-proof.yml | — |
| GitHub Actions | CI workflow activation | ✅ (on PR/push) | — | Local `mix test --exclude requires_example_host` |

No blocking missing dependencies.

---

## Open Questions

1. **Single vs multi-module `@compile {:no_warn_undefined, ...}` form**
   - What we know: The router uses one attribute per module (line 28). Standard Elixir docs show single-module form. Some examples show list form.
   - What's unclear: Whether a multi-module list `@compile {:no_warn_undefined, [ModA, ModB]}` is supported.
   - Recommendation: Use single-per-line form (matches existing router pattern; definitely safe).

2. **`crosswake_defaults` with no arguments**
   - What we know: Existing scopes always pass `runtime:`, `offline:`, `security:` to `crosswake_defaults`. The commerce scope has a `live` route and two `post` controller routes with different semantic ownership.
   - What's unclear: Whether `crosswake_defaults do ... end` with no arguments (bare block) is valid, or whether defaults must be supplied.
   - Recommendation: The planner should check if `crosswake_defaults` requires at least one default argument. If bare form is not valid, pass `runtime: :live_view` and let the post routes' `commerce:` declaration satisfy the manifest builder (which reads only the `commerce:` field, not runtime/offline). Alternatively, check whether post routes even need `crosswake_defaults` wrapping at all — they may just need `commerce:` options.

---

## Sources

### Primary (HIGH confidence)
- `lib/crosswake/policy/schema.ex` — complete file read; `validate_commerce_declaration/1` at lines 137-157, `validate_identifier/1` at lines 124-127, `commerce_declaration` type at lines 82-85
- `lib/crosswake/policy/corridor_profiles.ex` — complete file read; `@commerce_corridors` map at lines 17-34; string keys confirmed
- `lib/crosswake/manifest/builder.ex` — `commerce_corridor_registry/1` at lines 158-187; `route_commerce/1` at lines 207-214
- `lib/crosswake/manifest/types.ex` — `CommerceCorridor` struct at lines 164-178; `commerce_corridors` map type at lines 50-51
- `.github/workflows/phase23-proof.yml` — complete file read; all 179 lines
- `examples/phoenix_host/lib/crosswake_example/router.ex` — complete file read; `@compile` at line 28; scope patterns throughout

### Secondary (MEDIUM confidence)
- `test/crosswake/proof/phase23_commerce_support_proof_test.exs` — lines 42-87 confirm atom form usage in production test code
- `test/mix/tasks/crosswake_doctor_test.exs` — line 35 confirms atom form in test fixtures
- `.planning/phases/33-corridor-routes-and-ci-infrastructure/33-CONTEXT.md` — authoritative locked decisions D-01..D-10
- `.planning/REQUIREMENTS.md` — PWAL-01, PROOF-02 definitions
- `.planning/ROADMAP.md` — Phase 33 success criteria (4 items)

---

## Metadata

**Confidence breakdown:**
- Atom-vs-string reconciliation: HIGH — traced through four source files with line citations
- Manifest forward-reference safety: HIGH — builder.ex confirms no module lookup
- `@compile` no_warn_undefined pattern: HIGH (existing router) / ASSUMED (multi vs single module form)
- CI template diff: HIGH — phase23-proof.yml read in full; all structural elements documented
- Validation architecture: HIGH — concrete module/function calls identified for each criterion

**Research date:** 2026-05-29
**Valid until:** Phase 33 execution (stable infrastructure, no moving parts)

---

## RESEARCH COMPLETE

**Phase:** 33 — Corridor Routes And CI Infrastructure
**Confidence:** HIGH

### Key Findings

- **Atom form is correct and accepted.** `corridor: :subscription_default` in the router DSL is the established pattern. `validate_identifier/1` normalizes atoms to strings (schema.ex:126); the stored `commerce_declaration` and manifest use `"subscription_default"` (string) internally. ROADMAP success criterion #1 is satisfiable as written. No schema reconciliation needed.
- **Forward-referencing Phase 35 modules is safe.** `commerce_corridor_registry/1` reads only the route's `commerce:` metadata string — it never touches the target module. The `route_commerce/1` guard at builder.ex:210 confirms `is_binary(corridor)` post-normalization. Three routes → one `"subscription_default"` corridor entry in the manifest with correct `role_ownership` values from `corridor_profiles.ex`.
- **`@compile {:no_warn_undefined, ...}` is the established suppression pattern.** Router already uses this at line 28 for one module. Add one line per Phase 35 forward-referenced module (`PaywallEntryLive`, `CorridorController`).
- **`phase34-proof.yml` is a direct copy-and-adapt from `phase23-proof.yml`.** All structural elements (promotion_path 4-condition comment, hermetic `if:` guard, advisory `if:` guard + `continue-on-error: true`, schedule trigger, BEAM setup steps) are documented with exact line references. The key swap: hermetic test step uses `mix test --exclude requires_example_host` instead of an explicit file list.
- **Phase 33 is two file writes.** No new packages, no new test infrastructure, no PubSub, no stub modules. Router scope block + CI workflow file.

### Files Created
`.planning/phases/33-corridor-routes-and-ci-infrastructure/33-RESEARCH.md`

### Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| Atom-vs-string schema | HIGH | Traced through schema.ex:124-154, builder.ex:209-212, confirmed by phase23 proof tests |
| Manifest forward-reference safety | HIGH | builder.ex:158-214 read in full; no target module used |
| CI template diff | HIGH | phase23-proof.yml read in full (179 lines); structural elements documented |
| `@compile` suppression | HIGH (pattern) | Existing router line 28 is the template; ASSUMED for multi-module form |
| Validation architecture | HIGH | Concrete module/function calls for each success criterion |

### Open Questions

- Whether `crosswake_defaults do` bare (no arguments) is syntactically valid — planner should verify or pass `runtime:` only where it applies.
- Whether multi-module `@compile {:no_warn_undefined, [Mod1, Mod2]}` list form is supported — safe to use single-per-line form regardless.

### Ready for Planning
Research complete. Planner can now create PLAN.md with one or two plan waves: (1) router scope block + `@compile` lines, (2) `phase34-proof.yml` creation. Both are minimal file writes against fully understood infrastructure.
