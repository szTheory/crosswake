# Phase 136: Core Decoupling — Research

**Researched:** 2026-06-30
**Domain:** Elixir behaviour callbacks / registry inversion / AST guard extension
**Confidence:** HIGH — all findings verified against live codebase

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-136-A — Core baseline PII forbidden-metadata-key denylist (D-5 / DECOUPLE-05)**
Exactly 10 hardcoded atoms: `:access_token, :refresh_token, :id_token, :authorization_code,
:token, :session_ref, :subject_ref, :actor_id, :ip, :email`. Exact-atom MapSet membership, NOT
substring/regex. Built once and captured in `attach_default_logger/1` handler closure. Exposed
as `Crosswake.Telemetry.baseline_forbidden_metadata_keys/0` (semver: add = minor, remove = major).

**D-136-B — `evaluate_auth/3` returns `Denial.t()` in 136; `Finding` refactor is Phase 137**
New dedicated optional callback pair `evaluate_auth/3` + `auth_authority?/0`. Core's
`prepend_auth_evaluation_denials/4` stays a direct passthrough of `Denial.t()` — zero
type-translation layer. Remove `alias …Sigra.Evaluator` (route_gate.ex L9); keep `Denial` import;
dispatch through registry via `function_exported?/3`. Finding-boundary refactor deferred to Phase 137.

**D-136-C — AST `__aliases__` prefix-walk guard, stdlib-only (DECOUPLE-06)**
Two surgical fixes to `lib/crosswake/companion_guard.ex`:
1. Exact-match → prefix containment: replace `parts in @banned_alias_parts` with
   `Enum.any?(@banned_alias_parts, &List.starts_with?(parts, &1))`.
2. Scope: walk `lib/**/*.ex` minus `lib/crosswake/companions/**/*.ex`.
Add `Sigra` + `Chimeway` to `@extracted_companion_names`. No allowlist needed (prose and
telemetry atom-list literals are not `__aliases__` AST nodes).

**D-136-D — reserved-events test: shape assertion + keep stub-seeded merge test**
Drop `length(reserved_events) >= 24` assertion and its `stable_id_message` block (lines
343-352 in `phase133_telemetry_contract_test.exs`). Add count-independent shape assertion:
every `:reserved` entry matches `%{event: [_ | _], tier: :reserved, measurements: list,
metadata: list}`. Keep `TELEM-01` stub-seeded `:active`-event membership test and the
`refute MapSet.member?(active_prefixes, event)` no-overlap invariant.

### Claude's Discretion

- Exact helper names / module placement for runtime aggregation functions
  (`support_matrix.ex` `@auth_contract_truth` / `@notification_support_truth` module attributes → `def` runtime helpers).
- Precise wording of guard failure messages and public `@doc` text.

### Deferred Ideas (OUT OF SCOPE)

- Finding-boundary refactor for sigra auth (D-4) — `:auth` axis on `Finding` / `finding_to_denial/2`,
  StepUpCeremony match re-point, `sanitize_details` move to package boundary, full `Denial.new`
  call-site audit. → Phase 137.
- Per-companion Side-A "declared ⇔ emitted" telemetry contract tests (D-6). → Phases 137-140.
- `Crosswake.Live.Threadline` Phoenix-dep-optional consideration (D-7). → Phase 139.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DECOUPLE-01 | `Crosswake.Telemetry` aggregates companion telemetry events AND forbidden-metadata-keys at runtime via optional behaviour callbacks, zero compile-time companion references | Verified: telemetry.ex L143-150 is the static call site; L287-292 is `all_forbidden_keys/0` static call site; both must become runtime aggregations |
| DECOUPLE-02 | `RouteGate` resolves auth evaluator at runtime via `evaluate_auth/3` + `auth_authority?/0` callback pair, no static `Sigra.Evaluator` alias | Verified: route_gate.ex L9 `alias … Evaluator`, L258 `Evaluator.evaluate_route_auth` are the exact two sites to invert |
| DECOUPLE-03 | `SupportMatrix` and `Doctor` obtain companion denial codes and support truth at runtime via optional `denial_codes/0` callback; `@auth_contract_truth`/`@notification_support_truth` become runtime helpers | Verified: support_matrix.ex L128-236 (`@auth_contract_truth`) and L254-276 (`@notification_support_truth`) are module attributes calling companion functions at eval time; doctor.ex L792/797 has fallback calls to `Sigra.DenialCodes` |
| DECOUPLE-04 | Auth-predicated routes deny with `:dependency_missing` when no auth companion registered; companion raising during eval is rescued and denies; "no eval = allow" reachable only on non-auth routes | Verified: current `prepend_auth_evaluation_denials/4` (L252-262) has no no-companion guard and no rescue; both must be added |
| DECOUPLE-05 | Core ships 10-atom hardcoded baseline PII denylist always applied regardless of companion presence; exposed as `baseline_forbidden_metadata_keys/0` | Locked (D-136-A); `all_forbidden_keys/0` (L287-292) currently calls three static modules; must become `@baseline_forbidden_keys` MapSet unioned with runtime companion aggregation |
| DECOUPLE-06 | AST/grep guards cover all core `lib/` files; `crosswake` compiles `--warnings-as-errors` with no companion present; COMPAT-01 and Phase-129 freeze test pass | Verified: guard currently uses exact-match (silent miss on child modules); scope currently includes `lib/crosswake/companions/**`; two surgical fixes required |
</phase_requirements>

---

## Summary

Phase 136 is a pure refactor with zero publish risk. The design mechanism is fully locked; this
research exists only to ground-truth the CONTEXT.md line numbers against the live codebase and
surface the implementation landmines the planner needs.

**Key finding:** The CONTEXT.md line numbers are approximate and have drifted. The actual coupling
sites are documented with precise line numbers below. The most significant drift is in
`telemetry.ex`: the CONTEXT.md cites `~L143` for `build_reserved_events/0` (actual: L143-151),
`~L280-320` for forbidden-key aggregation (actual: L287-292 — only 6 lines, not a block), and
`~L59` for companion iteration (actual: L59-62). The `attach_default_logger/1` cache-point concern
is structural — the current implementation calls `events()` at attach time but the forbidden-key
scrubbing happens per-event in `__handle_event__/4` via `all_forbidden_keys/0`, which is NOT cached.
This is the performance gap D-136-A's "built once and captured in handler closure" directive closes.

The **phase129 freeze test will break** when the four new callbacks are added to `companion.ex`
because it asserts `MapSet.equal?` on exactly 7 callbacks. The planner must include a task to
update `@expected_callbacks` in that test file in the same PR as the `companion.ex` additions.

The **phase133 telemetry contract test** at line 343 asserts `length(reserved_events) >= 24` and
will break when `build_reserved_events/0` is converted from static companion calls to runtime
aggregation (with no companions registered, reserved set is empty). This is the D-136-D fix target.

The **phase130 extraction guards test** at line 86-136 currently asserts that Sigra/Chimeway
references in `route_gate.ex` and `companion_guard.ex` are NOT flagged (because they are
in-tree). After the guard is extended to ban Sigra/Chimeway, those positive-pass assertions
become negative evidence and will need updating. The scope exclusion of
`lib/crosswake/companions/**` keeps in-tree sigra/chimeway files from tripping the guard
during the phase before extraction.

**Primary recommendation:** Implement in six atomic tasks: (1) extend `Companion` behaviour +
update Phase-129 freeze test; (2) invert `telemetry.ex` static calls + add baseline PII denylist
+ cache forbidden-key MapSet in handler closure + update Phase-133 test; (3) invert `route_gate.ex`
auth dispatch + add fail-closed no-companion guard + rescue wrapper; (4) invert `support_matrix.ex`
module attributes to runtime helpers; (5) invert `doctor.ex` fallback calls; (6) extend
`companion_guard.ex` (exact→prefix, scope, Sigra+Chimeway to banned set) + update Phase-130 test.
All six must land in one PR for `mix compile --warnings-as-errors` to pass (any partial state
leaves dangling static references that fail compile). Alternatively, tasks 1-5 can sequence with
task 6 last — the guard fixes do not affect compile correctness.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Runtime companion registry iteration | Core library (`telemetry.ex`, `route_gate.ex`, `support_matrix.ex`, `doctor.ex`) | `companion.ex` behaviour | Registry is `Application.get_env` — owned by each consumer at call time |
| PII scrubbing baseline | Core library (`telemetry.ex`) | — | Must be independent of companion presence by design |
| Auth dispatch / fail-closed guard | Core library (`route_gate.ex`) | Companion behaviour (`evaluate_auth/3`, `auth_authority?/0`) | Core owns the fail-closed contract; companions provide auth evaluation |
| AST boundary enforcement | Core library (`companion_guard.ex`) | CI workflow (phase136-proof.yml) | stdlib-only, no external dep |
| Callback shape contract | `companion.ex` behaviour | Phase-129 freeze test | Both files must change in same PR |

---

## Code-Site Drift Verification

The following are ACTUAL current file states. CONTEXT.md approximate line numbers are corrected here.

### 1. `lib/crosswake/telemetry.ex` (293 lines total)

**Coupling site A — `build_reserved_events/0` (DECOUPLE-01):**
```
L143  defp build_reserved_events do
L144    Enum.map(
L145      Crosswake.Companions.Sigra.Telemetry.event_names() ++
L146        Crosswake.Companions.Chimeway.Telemetry.event_names(),
L147      fn name ->
L148        %{event: name, tier: :reserved, description: "", measurements: [], metadata: []}
L149      end
L150    )
L151  end
```
Static calls: `Sigra.Telemetry.event_names()` at L145 and `Chimeway.Telemetry.event_names()` at L146.
Sigra has 14 event names; Chimeway has 10 — total 24, which is the `>= 24` assertion in phase133 test.
After inversion, this function either returns `[]` (runtime companion aggregation goes to `events/0`)
or is repurposed to aggregate via `function_exported?/3` over the registry.

**Coupling site B — `all_forbidden_keys/0` (DECOUPLE-01 / DECOUPLE-05):**
```
L287  defp all_forbidden_keys do
L288    (Crosswake.Threadline.Telemetry.forbidden_metadata_keys() ++
L289       Crosswake.Companions.Sigra.Telemetry.forbidden_metadata_keys() ++
L290       Crosswake.Companions.Chimeway.Telemetry.forbidden_metadata_keys())
L291    |> Enum.uniq()
L292  end
```
Called from `__handle_event__/4` at L244 — called **per-event**, not once at attach time.
This is the D-136-A cache gap: must become `@baseline_forbidden_keys` MapSet unioned with
runtime companion aggregation, built once in `attach_default_logger/1` and captured in the
handler closure. Current Threadline.Telemetry call at L288 is fine (Threadline stays in-tree for
Phase 136); only Sigra (L289) and Chimeway (L290) calls must be replaced.

**`attach_default_logger/1` (L186-202):** Currently calls `events()` to get active event names
for `:telemetry.attach_many`. This does NOT cache the forbidden-key set — that happens per-event.
The Phase 136 task adds a `forbidden` binding computed once here and captures it in the handler
closure via a custom config key or opts key passed through `attach_many` config map.

**Companion iteration (already runtime, L59-62):**
```
L59   companion_events =
L60     Application.get_env(:crosswake, :companions, [])
L61     |> Enum.flat_map(fn mod ->
L62       if function_exported?(mod, :telemetry_events, 0), do: mod.telemetry_events(), else: []
```
This is the **exact pattern** the four new inversions will copy. [VERIFIED: live codebase]

### 2. `lib/crosswake/compatibility/route_gate.ex` (387 lines total)

**Coupling site A — alias (DECOUPLE-02):**
```
L9    alias Crosswake.Companions.Sigra.Evaluator
```
Action: delete this line.

**Coupling site B — `prepend_auth_evaluation_denials/4` (DECOUPLE-02 / DECOUPLE-04):**
```
L252  defp prepend_auth_evaluation_denials(acc, _route, _opts, gate_denials) when gate_denials != [],
L253    do: acc
L254
L255  defp prepend_auth_evaluation_denials(acc, nil, _opts, _gate_denials), do: acc
L256
L257  defp prepend_auth_evaluation_denials(acc, %RouteEntry{} = route, opts, _gate_denials) do
L258    case Evaluator.evaluate_route_auth(route, Keyword.get(opts, :auth_context), opts) do
L259      {:allow, _result} -> acc
L260      {:deny, denial} -> [denial | acc]
L261    end
L262  end
```
The third clause (L257-262) must be replaced with: (a) a guard checking whether the route has
auth predicates (`auth_min_level`/`requires_recent_auth`/`auth_posture` set); (b) if predicated,
find the single `auth_authority?/0` companion (with multiple-companion telemetry warning + doctor
flag handling); (c) if none found → deny with `:dependency_missing`; (d) if found → dispatch
`evaluate_auth/3` wrapped in `try/rescue` → deny on raise; (e) if not predicated → `acc`.

**Auth predicate detection** — currently lives in `Sigra.Evaluator.auth_predicated?/1` (L265-267):
```
not is_nil(route.auth_min_level) or not is_nil(route.requires_recent_auth) or
  not is_nil(route.auth_posture)
```
Core must inline or extract this predicate check since it can no longer call the Sigra module.

**Existing companion registry read (L103-107) — already runtime:**
```
L103  companions =
L104    Application.get_env(:crosswake, :companions, [])
L105    |> Enum.filter(fn companion ->
L106      config = Application.get_env(:crosswake, companion.companion_id(), %{})
L107      companion.enabled?(config)
```
The new `auth_authority?/0` lookup follows this same pattern.

### 3. `lib/crosswake/support_matrix/support_matrix.ex` (1545 lines total)

**Coupling site A — alias (L16):**
```
L16   alias Crosswake.Companions.Sigra.Telemetry, as: SigraTelemetry
```
Action: delete this alias.

**Coupling site B — `@auth_contract_truth` module attribute (L128-237) — STALE-BEAM FOOTGUN:**
The entire `@auth_contract_truth` list literal beginning at L128 contains companion function calls
at the module-attribute level:
- L211: `event_names: SigraTelemetry.event_names(),`
- L212: `metadata_keys: SigraTelemetry.metadata_keys(),`
- L213: `forbidden_metadata_keys: SigraTelemetry.forbidden_metadata_keys(),`
- L226: `denial_codes: Crosswake.Companions.Sigra.DenialCodes.codes(),`
- L227: `safe_detail_keys: Crosswake.Companions.Sigra.DenialCodes.allowed_detail_keys(),`

These calls execute at module-evaluation time, baking values into the `.beam`. The public
`auth_contract_truth/0` function (L696-697) simply returns `@auth_contract_truth`. This entire
pattern must convert to a `def auth_contract_truth` that calls the registry at runtime.

**Coupling site C — `@notification_support_truth` module attribute (L254-276) — STALE-BEAM FOOTGUN:**
- L266: `event_names: Crosswake.Companions.Chimeway.Telemetry.event_names(),`
- L267: `metadata_keys: Crosswake.Companions.Chimeway.Telemetry.metadata_keys(),`
- L268-269: `forbidden_metadata_keys: Crosswake.Companions.Chimeway.Telemetry.forbidden_metadata_keys(),`

Same stale-beam pattern. Public `notification_support_truth/0` (L480-481) returns `@notification_support_truth`.

**Planner note on module-attribute scope:** The `@auth_contract_truth` and `@notification_support_truth`
attributes are large list-of-maps literals. Converting to `def` runtime helpers means the static
companion values must be replaced with runtime registry lookups. The planner has discretion on
helper names and module placement. The key constraint: NO companion function call at module-eval
time. Permitted approach: sentinel static values (empty lists / nil) for telemetry data and denial
codes, filled at runtime by the companion registry callbacks.

**`@companion_support_truth` (L238-253) and `@audit_ledger_support_truth` (L278-296):** These
module attributes contain NO companion function calls — `@companion_support_truth` is pure static
data and `@audit_ledger_support_truth` calls `ThreadlineTelemetry` which stays in-tree. These
need no conversion in Phase 136.

### 4. `lib/crosswake/doctor/doctor.ex` (2068 lines total)

**Coupling sites — `phase_46_auth_findings/1` (L734-806):**
Both compiler calls appear as fallback defaults inside `Map.get` calls:
```
L792  denial_codes:
L793    Map.get(auth_truth, :denial_codes, Crosswake.Companions.Sigra.DenialCodes.codes()),
L794  safe_detail_keys:
L795    Map.get(
L796      auth_truth,
L797      :safe_detail_keys,
L798      Crosswake.Companions.Sigra.DenialCodes.allowed_detail_keys()
L799    ),
```
These are default-value expressions in `Map.get/3` — they are evaluated eagerly even when
the key exists (Elixir is strict). They will be called at runtime today but after Phase 136
the module they call no longer exists in core. The fix: replace the static defaults with runtime
registry lookups via `denial_codes/0` callback, or use `nil` as default and handle downstream.

**Existing runtime registry reads in doctor.ex (already correct pattern):**
- L565: `companions = Application.get_env(:crosswake, :companions, [])` — `phase_38_companion_seam_findings/0`
- L635: `companions = Application.get_env(:crosswake, :companions, [])` — `phase_41_gating_findings/1`

---

## `companion.ex` — Callback Shape Ground Truth

Current file: 144 lines. One optional callback defined:
```
L141  @callback telemetry_events() :: [Crosswake.Telemetry.event_doc()]
L143  @optional_callbacks telemetry_events: 0
```

The four new callbacks follow this exact shape. Their type signatures (from D-136-B/CONTEXT.md):

```elixir
@callback forbidden_metadata_keys() :: [atom()]
@callback denial_codes() :: [String.t()]
@callback evaluate_auth(route :: RouteEntry.t(), auth_context :: map(), opts :: keyword()) ::
            {:allow, map()} | {:deny, Crosswake.Shell.Denial.t()}
@callback auth_authority?() :: boolean()

@optional_callbacks [
  telemetry_events: 0,
  forbidden_metadata_keys: 0,
  denial_codes: 0,
  evaluate_auth: 3,
  auth_authority?: 0
]
```

Note: `@optional_callbacks` must be updated from `telemetry_events: 0` to the full keyword list.
The Phase-129 freeze test (`phase129_companion_contract_freeze_test.exs`) asserts:
```elixir
@expected_callbacks MapSet.new([
  {:companion_id, 0},
  {:enabled?, 1},
  {:route_gated?, 2},
  {:kill_switch_active?, 1},
  {:validate_dependency, 0},
  {:report_state, 0},
  {:telemetry_events, 0}   # ← currently exactly 7
])
```
Adding four callbacks makes the freeze test fail. The freeze test and `companion.ex` MUST be
updated in the same PR/commit (D-12/D-17 pattern — "reviewer sees intentional shape change").

---

## `companion_guard.ex` — Guard State Ground Truth

**Current exact-match pattern (L94-95):**
```elixir
{:__aliases__, _meta, parts} = node, acc
when parts in @banned_alias_parts ->
```
`parts in @banned_alias_parts` is Elixir's `in/2` operator on a list — this checks **exact
equality** of the `parts` list against each element of `@banned_alias_parts`. `[:Crosswake,
:Companions, :Sigra, :Evaluator]` does NOT equal `[:Crosswake, :Companions, :Sigra]` so child
modules like `Sigra.Evaluator`, `Sigra.DenialCodes`, and `Chimeway.Telemetry` all pass silently.
The comment in the moduledoc (L78) claims "prefix match" but the code does not do it.

**Fix (D-136-C):**
```elixir
{:__aliases__, _meta, parts} = node, acc ->
  if Enum.any?(@banned_alias_parts, &List.starts_with?(parts, &1)) do
    {node, [node | acc]}
  else
    {node, acc}
  end
```
The `when` guard cannot call non-guard-safe functions like `Enum.any?/2`, so the pattern
match must be unconditional and the test moved to the function body.

**Current `@extracted_companion_names` (L36-41):**
```elixir
@extracted_companion_names [
  "Crosswake.Companions.Rulestead",   # Phase 130
  "Crosswake.Companions.Rindle"       # Phase 132
]
```
Phase 136 adds: `"Crosswake.Companions.Sigra"` and `"Crosswake.Companions.Chimeway"`.
Note: these are string representations, converted to atom-part lists at L52-54 via `String.split(".")`.

**Current scope (L190):** `lib_glob = Path.join(File.cwd!(), "lib/**/*.ex")` — walks ALL of
`lib/`, including `lib/crosswake/companions/**`. After adding Sigra and Chimeway to the banned
set, the in-tree companion files themselves (`lib/crosswake/companions/sigra/*.ex`) will contain
`Crosswake.Companions.Sigra.*` aliases and will trip the guard. Fix: exclude
`lib/crosswake/companions/**/*.ex` from the glob. In Elixir `Path.wildcard`, `**` expansion
does not support negative globs natively; the standard fix is:
```elixir
lib_files = Path.wildcard(Path.join(File.cwd!(), "lib/**/*.ex"))
companion_files = Path.wildcard(Path.join(File.cwd!(), "lib/crosswake/companions/**/*.ex"))
walk_files = lib_files -- companion_files
```

**Phase-130 extraction guards test impact:** The test at line 86-136 of
`phase130_extraction_guards_test.exs` contains:
- L86-103: `"A real Sigra-referencing core file is NOT flagged"` — asserts `check_source(route_gate_source) == :ok`. After Phase 136 this test becomes **correct** (route_gate.ex will no longer contain Sigra refs). No test change needed IF the production code is inverted first and the test is still run after.
- L122-136: `"check_source/1 does NOT detect Crosswake.Companions.Sigra alias (legitimate in-tree)"` — asserts `check_source("alias Crosswake.Companions.Sigra.Evaluator") == :ok`. After adding Sigra to the banned set this assertion INVERTS to `{:violation, _}`. **This test must be updated** in the same PR as the guard extension.

---

## Common Pitfalls

### Pitfall 1: Partial Inversion Breaks Compile

**What goes wrong:** If only some of the four coupling sites are inverted in a commit, the
remaining static references fail `mix compile --warnings-as-errors` (UndefinedFunctionError for
modules that no longer exist — but sigra/chimeway DO still exist in-tree for Phase 136, so this
specific failure is deferred until extraction). However, the test suite failure is immediate: the
Phase-129 freeze test fails the moment companion.ex callbacks change without the test update.

**How to avoid:** Wave 0 adds the four callbacks to `companion.ex` AND updates `@expected_callbacks`
in the freeze test together. Subsequent waves invert each coupling site with its companion
test update.

### Pitfall 2: Module-Attribute Stale-Beam Footgun in `support_matrix.ex`

**What goes wrong:** `@auth_contract_truth` and `@notification_support_truth` call companion
functions at module-evaluation time. The values are baked into the `.beam` file. If companion
telemetry metadata drifts after compilation, `SupportMatrix.auth_contract_truth/0` silently
returns stale data without recompiling.

**Why it happens:** Elixir module attributes are computed once at compile time.
`Application.get_env` would be safe; `SomeMod.some_function()` is not.

**How to avoid:** Convert both attributes to `def` functions that call the runtime registry.

**Warning signs:** `SupportMatrix.auth_contract_truth()` returns hardcoded Sigra event names
even with no companions registered.

### Pitfall 3: Exact-Match Guard Silently Passes Child Modules

**What goes wrong:** The existing `companion_guard.ex` `when parts in @banned_alias_parts` check
uses Elixir's `in/2` list membership with exact equality. `Sigra.Evaluator` has parts
`[:Crosswake, :Companions, :Sigra, :Evaluator]` — this does NOT match `[:Crosswake, :Companions, :Sigra]`.
The guard comment claims prefix matching but the implementation does not do it.

**How to avoid:** Replace with `Enum.any?(@banned_alias_parts, &List.starts_with?(parts, &1))`.
Add the exact Sigra child module non-vacuity test (`Sigra.Evaluator` is detected) to the guard
test file.

### Pitfall 4: `attach_default_logger/1` Forbidden-Key Set Not Cached

**What goes wrong:** `all_forbidden_keys/0` is called on every telemetry event in
`__handle_event__/4` (L244). This aggregates companion forbidden keys per event. Under load
this is a repeated `Application.get_env` + `Enum.flat_map` + `Enum.uniq` per telemetry event.

**How to avoid:** D-136-A directs: build the merged `MapSet` once in `attach_default_logger/1`
and capture it in the handler closure. Pass it through the `config` map argument of
`:telemetry.attach_many/4` (the `opts` in the handler signature). Remove `all_forbidden_keys/0`.

### Pitfall 5: Auth-Predicated Route Has No Route Guard for `auth_authority?/0` Check

**What goes wrong:** The new `prepend_auth_evaluation_denials/4` must detect whether the route
is auth-predicated before dispatching to companions. The predicate logic is currently inside
`Sigra.Evaluator.auth_predicated?/1` at L265-267. After removing the static alias, core must
replicate or inline this three-field nil-check:
`not is_nil(route.auth_min_level) or not is_nil(route.requires_recent_auth) or not is_nil(route.auth_posture)`.

If this check is omitted, every route (auth-predicated or not) will trigger the companion
registry scan for `auth_authority?/0`, adding overhead and potentially denying non-auth routes.

### Pitfall 6: Phase-130 Non-Vacuity Test Must Invert for Sigra

**What goes wrong:** `phase130_extraction_guards_test.exs` L122-136 asserts that a synthetic
source string `"alias Crosswake.Companions.Sigra.Evaluator"` is NOT flagged by `check_source/1`.
After adding Sigra to `@extracted_companion_names`, this assertion becomes a false positive — the
guard correctly flags it, but the test says it should not be flagged.

**How to avoid:** In the same PR as the guard extension, update the test:
- Change the L122-136 assertion from `assert :ok =` to `assert {:violation, _} =`.
- Update the test description to reflect Sigra is now extracted/banned.
- Add a new non-vacuity test asserting that in-tree companion files are excluded by the scope
  change (i.e., `check_source` on a sigra companion source file returns `:ok` because the scope
  walk excludes `lib/crosswake/companions/**`).

### Pitfall 7: `when` Guard Clause Cannot Use `Enum.any?/2`

**What goes wrong:** The fix to `companion_guard.ex` must replace the guard clause
`when parts in @banned_alias_parts` with prefix-matching. Elixir `when` guards can only
contain guard-safe expressions. `Enum.any?/2` and `List.starts_with?/2` are NOT guard-safe.

**How to avoid:** Remove the `when` clause from the alias match and move the test to the
function body using an `if` expression (see code example in Pitfall 3 fix above).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Companion aggregation | Custom ETS / GenServer registry | `Application.get_env(:crosswake, :companions, [])` + `function_exported?/3` | Already shipped in Phase 129; no new process/ETS needed |
| Boundary enforcement | `mix xref` or `boundary` hex lib | `Code.string_to_quoted` + `Macro.prewalk` in `companion_guard.ex` | xref misses alias-only refs; `boundary` is a new dep; existing guard already proven |
| PII scrubbing | Substring/regex key matching | Exact-atom `MapSet.drop` | Atom keys are bounded dev-defined; substring silently drops `:notification_token_count` |
| Auth dispatch compile-time wiring | `@before_compile` accumulation or protocol consolidation | `function_exported?/3` at runtime | Conflicts with `optional: true` deps; stale-beam trap |

---

## Package Legitimacy Audit

No new external packages are installed in this phase. All changes are to existing core files.
This section is not applicable.

---

## Existing Tests — Exact Locations for D-136-D

### The `>= 24` Assertion to Drop

**File:** `test/crosswake/proof/phase133_telemetry_contract_test.exs`
**Test name:** `"TELEM-04 :reserved tier events are excluded from declared=>emitted check"` (L337)
**Assertion to drop:** L343-352:
```elixir
assert length(reserved_events) >= 24,
       ProofAssertions.stable_id_message(
         "proof.telem_04.reserved.minimum_count",
         "expected at least 24 reserved events (Sigra 14 + Chimeway 10)",
         "Crosswake.Telemetry.events/0 |> filter(tier == :reserved)",
         "got #{length(reserved_events)} reserved events",
         "lib/crosswake/telemetry.ex",
         "include Sigra.Telemetry.event_names/0 and Chimeway.Telemetry.event_names/0 as :reserved tier in events/0",
         :merge_blocking
       )
```

**Replace with (D-136-D shape assertion):**
```elixir
# Shape assertion: every reserved entry has non-empty event list, correct tier, lists for measurements/metadata
for entry <- reserved_events do
  assert match?(%{event: [_ | _], tier: :reserved, measurements: m, metadata: meta}
                when is_list(m) and is_list(meta), entry),
         "reserved entry failed shape check: #{inspect(entry)}"
end
```
The no-overlap invariant at L354-370 (`refute MapSet.member?(active_prefixes, event)`) is
**kept unchanged** as per D-136-D.

### The Stub-Seeded Merge Test to Keep

**Test:** `"TELEM-01 companion merge: stub companion's declared events appear in events/0"` (L306-329)
This test is count-independent — it only asserts that each stub event appears in the result.
**No change needed.**

### The Phase-129 Freeze Test to Update

**File:** `test/crosswake/proof/phase129_companion_contract_freeze_test.exs`
**Lines 21-29:** `@expected_callbacks` must gain the four new callbacks:
```elixir
@expected_callbacks MapSet.new([
  {:companion_id, 0},
  {:enabled?, 1},
  {:route_gated?, 2},
  {:kill_switch_active?, 1},
  {:validate_dependency, 0},
  {:report_state, 0},
  {:telemetry_events, 0},
  # Added in Phase 136:
  {:forbidden_metadata_keys, 0},
  {:denial_codes, 0},
  {:evaluate_auth, 3},
  {:auth_authority?, 0}
])
```

### The Phase-130 Extraction Guards Test to Update

**File:** `test/crosswake/proof/phase130_extraction_guards_test.exs`
**Lines 122-136:** The assertion that `check_source("alias Crosswake.Companions.Sigra.Evaluator") == :ok`
must invert to `{:violation, _}` after Sigra is added to the banned set.

---

## Validation Architecture

Nyquist validation is enabled (config.json `workflow.nyquist_validation` key is absent, treated as enabled).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir stdlib) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/crosswake/proof/phase129_companion_contract_freeze_test.exs test/crosswake/proof/phase133_telemetry_contract_test.exs test/crosswake/proof/phase130_fail_closed_contract_test.exs test/crosswake/proof/phase130_extraction_guards_test.exs` |
| Full suite command | `mix test --exclude requires_example_host --exclude advisory_only` |
| Compile gate | `mix compile --warnings-as-errors` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DECOUPLE-01 | `events/0` returns empty reserved set (no companions) and aggregates forbidden keys from companion registry | unit | `mix test test/crosswake/proof/phase133_telemetry_contract_test.exs` | ✅ (must be modified — drop `>= 24` assertion) |
| DECOUPLE-01 | `all_forbidden_keys` built once and passed via handler closure | unit | `mix test test/crosswake/proof/phase136_decouple_proof_test.exs` | ❌ Wave 0 |
| DECOUPLE-02 | `route_gate.ex` resolves auth evaluator via `function_exported?/3` registry dispatch | unit | `mix test test/crosswake/proof/phase136_decouple_proof_test.exs` | ❌ Wave 0 |
| DECOUPLE-03 | `SupportMatrix` and `Doctor` obtain denial codes via `denial_codes/0` callback at runtime | unit | `mix test test/crosswake/proof/phase136_decouple_proof_test.exs` | ❌ Wave 0 |
| DECOUPLE-04 | Auth-predicated route + no `auth_authority?/0` companion → `:dependency_missing` denial | integration | `mix test test/crosswake/proof/phase136_decouple_proof_test.exs` | ❌ Wave 0 |
| DECOUPLE-04 | Companion raising in `evaluate_auth/3` → rescued → deny | integration | `mix test test/crosswake/proof/phase136_decouple_proof_test.exs` | ❌ Wave 0 |
| DECOUPLE-04 | Non-auth-predicated route + no auth companion → allow | integration | `mix test test/crosswake/proof/phase136_decouple_proof_test.exs` | ❌ Wave 0 |
| DECOUPLE-05 | `baseline_forbidden_metadata_keys/0` returns exactly the 10-atom set regardless of companion presence | unit | `mix test test/crosswake/proof/phase136_decouple_proof_test.exs` | ❌ Wave 0 |
| DECOUPLE-05 | Baseline forbidden keys always applied even with `companions: []` | unit | `mix test test/crosswake/proof/phase136_decouple_proof_test.exs` | ❌ Wave 0 |
| DECOUPLE-06 | `companion_guard.ex` detects `Sigra.Evaluator` child-module alias (prefix match, non-vacuity) | unit | `mix test test/crosswake/proof/phase130_extraction_guards_test.exs` | ✅ (must be modified — invert L122-136 assertion) |
| DECOUPLE-06 | `companion_guard.ex` scope excludes `lib/crosswake/companions/**` (in-tree companion files not flagged) | unit | `mix test test/crosswake/proof/phase130_extraction_guards_test.exs` | ✅ (new test case needed) |
| DECOUPLE-06 | `mix compile --warnings-as-errors` passes with no companion packages | compile | `mix compile --warnings-as-errors` | ✅ (always run in CI) |
| DECOUPLE-06 | COMPAT-01 fail-closed behavior passes with no companion present | integration | `mix test test/crosswake/proof/phase130_fail_closed_contract_test.exs` | ✅ (no change) |
| DECOUPLE-06 | Phase-129 companion-contract freeze test passes (7+4 callbacks) | unit | `mix test test/crosswake/proof/phase129_companion_contract_freeze_test.exs` | ✅ (must be modified — add 4 callbacks to `@expected_callbacks`) |

### Backstop Tests Required (Non-Inferable from Existing Suite)

The following behaviors are NOT covered by existing tests and require new test cases in
`test/crosswake/proof/phase136_decouple_proof_test.exs`:

1. **"companion that raises during `evaluate_auth/3` is rescued and denies" edge (DECOUPLE-04)**
   Existing COMPAT-01 test (`phase130_fail_closed_contract_test.exs` L284-301) covers
   `validate_dependency/0` raising → `:dependency_missing`. There is NO existing test for
   `evaluate_auth/3` raising → deny. A stub companion that raises in `evaluate_auth/3` must be
   registered, an auth-predicated route evaluated, and the resulting decision must have `status: :deny`
   and `denial.reason: :dependency_missing` (or `:auth_evaluator_error` — planner decides name).

2. **"zero-companion compile: `events/0` returns non-empty list, reserved set is empty" (DECOUPLE-01)**
   The existing `fail-closed (D-10)` test (phase133 L378-408) registers `companions: []` and
   asserts `length(result) > 0`. After Phase 136, `reserved_events` with `companions: []` will be
   `[]`. The existing test does not specifically assert the reserved-set-empty condition under
   zero-companion state — add an explicit `assert reserved_events == []` assertion for the
   zero-companion case.

3. **"multiple `auth_authority?/0` companions → first-registered used + telemetry warning"
   (DECOUPLE-04 / D-3)**
   No existing test covers multiple auth-authority companions. New stub needed.

4. **"`baseline_forbidden_metadata_keys/0` is callable and returns exactly 10 atoms" (DECOUPLE-05)**
   New public API with no existing test.

5. **"`attach_default_logger/1` builds forbidden-key set at attach time, not per-event" (DECOUPLE-05)**
   This is a performance/correctness property. Test approach: attach with a stub companion that
   returns a known key from `forbidden_metadata_keys/0`, then call `detach_companion_list` between
   emit and verify — the forbidden key should still be scrubbed (proving the set was captured at
   attach, not re-evaluated at emit). Alternatively, verify the handler config map contains a
   `:forbidden_keys` entry.

### Sampling Rate

- **Per task commit:** `mix test test/crosswake/proof/phase129_companion_contract_freeze_test.exs test/crosswake/proof/phase133_telemetry_contract_test.exs test/crosswake/proof/phase130_fail_closed_contract_test.exs test/crosswake/proof/phase130_extraction_guards_test.exs`
- **Per wave merge:** `mix compile --warnings-as-errors && mix test --exclude requires_example_host --exclude advisory_only`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/crosswake/proof/phase136_decouple_proof_test.exs` — covers DECOUPLE-01/02/03/04/05 (all new behaviors not covered by existing tests)
- [ ] `test/crosswake/proof/phase133_telemetry_contract_test.exs` L343-352 — drop `>= 24` assertion, add shape assertion (DECOUPLE-01 / D-136-D)
- [ ] `test/crosswake/proof/phase129_companion_contract_freeze_test.exs` L21-29 — add 4 callbacks to `@expected_callbacks` (DECOUPLE-06)
- [ ] `test/crosswake/proof/phase130_extraction_guards_test.exs` L122-136 — invert Sigra non-vacuity assertion; add scope-exclusion test (DECOUPLE-06)

---

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified — Phase 136 is pure code/config changes with no new CLI tools, services, or runtimes beyond the existing Elixir/OTP stack).

---

## Security Domain

`security_enforcement` key is absent from `.planning/config.json` — treated as enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | Yes | `evaluate_auth/3` callback is the auth evaluation seam; fail-closed per D-3 |
| V3 Session Management | No | Not modified in this phase |
| V4 Access Control | Yes | Auth-predicated route denial with `:dependency_missing`; fail-closed is structural |
| V5 Input Validation | Yes | `forbidden_metadata_keys` baseline prevents PII leakage in telemetry events |
| V6 Cryptography | No | No cryptographic operations in this phase |

### Known Threat Patterns for this Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Fail-open auth (Guardian pattern) | Elevation of privilege | `auth_authority?/0` absent → deny; companion raises → rescue → deny; never allow by default |
| PII in telemetry metadata | Information disclosure | `@baseline_forbidden_keys` MapSet always applied; companion-provided keys additive |
| Stale-beam stale auth data | Spoofing | `Application.get_env` not `compile_env`; no module-attribute companion calls |
| Slop/hallucinated companion callbacks | Tampering | `function_exported?/3` guard before every dispatch |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `doctor.ex` L565 and L635 are the `phase_38` and `phase_41` companion registry reads; exact function boundaries not verified beyond those lines | Code-Site Drift Verification | Planner may miss additional registry reads in doctor; should grep doctor.ex for all `Application.get_env(:crosswake, :companions` calls |
| A2 | The `when parts in @banned_alias_parts` guard limitation (no `Enum.any?` in guards) is standard Elixir; verified from Elixir guard semantics | companion_guard.ex | None — this is a language invariant |
| A3 | `phase136_decouple_proof_test.exs` is the appropriate new file name following the phase-prefixed naming convention | Validation Architecture | Planner could choose a different name; adjust CI workflow step accordingly |

**If this table were empty:** All claims were verified or cited. Only A1 has residual uncertainty.

---

## Open Questions

1. **Multiple `auth_authority?/0` companions: doctor flag mechanism**
   - What we know: D-3 specifies "first-registered + telemetry warning + doctor flag"
   - What's unclear: What doctor finding code should the warning use? What telemetry event name?
   - Recommendation: Planner defines the doctor code string (e.g., `"auth.multiple_authority_companions"`) and emits a `[:crosswake, :companion, :auth_authority_conflict]` event via `:telemetry.execute`. Claude's discretion per CONTEXT.md.

2. **`@auth_contract_truth` / `@notification_support_truth` runtime helper shape**
   - What we know: Planner has discretion on helper names and module placement
   - What's unclear: Should the runtime helpers call `denial_codes/0` callbacks directly, or should the SupportMatrix return sentinel values and Doctor/callers do the registry lookup?
   - Recommendation: Have `SupportMatrix.auth_contract_truth/0` return the full static structural data EXCEPT the companion-sourced fields (`event_names`, `metadata_keys`, `forbidden_metadata_keys`, `denial_codes`, `safe_detail_keys`), which become `nil` / `[]` sentinels. Doctor and callers do the runtime registry lookup when those fields are needed. This keeps SupportMatrix from taking a dependency on the registry pattern.

---

## Sources

### Primary (HIGH confidence — verified against live codebase)
- `lib/crosswake/telemetry.ex` — all four telemetry coupling sites verified with exact line numbers
- `lib/crosswake/compatibility/route_gate.ex` — Evaluator alias L9, `prepend_auth_evaluation_denials` L252-262 verified
- `lib/crosswake/support_matrix/support_matrix.ex` — module attribute coupling sites L128/L254/L16 verified
- `lib/crosswake/doctor/doctor.ex` — DenialCodes fallback calls L792/797 verified
- `lib/crosswake/companion.ex` — existing `@optional_callbacks telemetry_events: 0` at L143 verified
- `lib/crosswake/companion_guard.ex` — exact-match guard at L94-95, scope at L190, banned set at L35-54 verified
- `test/crosswake/proof/phase133_telemetry_contract_test.exs` — `>= 24` assertion at L343-352 verified
- `test/crosswake/proof/phase129_companion_contract_freeze_test.exs` — `@expected_callbacks` at L21-29 verified (7 callbacks)
- `test/crosswake/proof/phase130_extraction_guards_test.exs` — Sigra non-vacuity assertion L122-136 verified

### Secondary (HIGH confidence — verified live codebase, implementation details)
- `lib/crosswake/companions/sigra/telemetry.ex` — 14 event_names verified
- `lib/crosswake/companions/chimeway/telemetry.ex` — 10 event_names verified
- `lib/crosswake/companions/sigra/evaluator.ex` — `auth_predicated?/1` logic at L265-267 verified
- `.github/workflows/phase130-proof.yml`, `phase132-proof.yml` — CI wiring for guard and COMPAT tests verified

---

## Metadata

**Confidence breakdown:**
- Code-site line numbers: HIGH — all verified against live files
- Guard fix mechanism: HIGH — verified against Elixir guard semantics + live code
- Test file locations: HIGH — all verified with exact line numbers
- Phase-130 test inversion requirement: HIGH — logical consequence of adding Sigra to banned set
- Runtime helper shape for SupportMatrix: MEDIUM — structural approach recommended; planner has discretion

**Research date:** 2026-06-30
**Valid until:** 2026-07-30 (codebase is stable; no external deps)
