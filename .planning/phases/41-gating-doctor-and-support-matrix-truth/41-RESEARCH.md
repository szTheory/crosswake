# Phase 41: Gating Doctor And Support-Matrix Truth - Research

**Researched:** 2026-05-30
**Domain:** Elixir — Crosswake Doctor diagnostics + SupportMatrix extensions for companion gating
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** Gating checks get a new top-level doctor category ("Gating") — a sibling to the Phase 38 "Companion Dependencies" category. Not merged into companion findings.

**D-02:** One finding per gated route (each route with `gated_by != nil`). Mirrors `phase_19_commerce_corridor_posture/1`.

**D-03:** Per-route informational findings carry `:info` severity. Gating is intentional configuration — `:info` communicates "this route is gated, here's the posture" without implying a problem.

**D-04:** When a route's `gated_by` atom does not match any registered companion's `companion_id()`, doctor emits an `:error` finding (code `"gating.flag_reference_unknown"`). An unresolvable flag reference is a config error, not a warning.

**D-05:** When no companions are registered but gated routes exist, the same per-route `"gating.flag_reference_unknown"` `:error` fires for each gated route.

**D-06:** `Companion.State.gate_status` typespec grows:
```elixir
@type gate_status :: :active | :inactive | :unconfigured | {:rolling_out, non_neg_integer()}
```
`report_state/0` returns this richer type. The support matrix reads it directly. No "magic key" in the `details` map.

**D-07:** `kill_switch_status` stays as-is: `:inactive | :active | :unconfigured`.

**D-08:** Support-matrix display mapping:
- `gate_status: :active` → `"gated"`
- `gate_status: {:rolling_out, n}` → `"rolling_out (N%)"`
- `kill_switch_status: :active` → `"killed"` (overrides gate_status)
- `gate_status: :inactive` → route not currently gated
- `gate_status: :unconfigured` → companion not yet configured for gating
- Column labeled runtime-distinct from build-proof state

**D-09:** `on_unavailable: {:fallback_phoenix, route_id}` surfaced as a hint on the per-route `:info` finding. No separate finding for routes that have the fallback posture.

**D-10:** Doctor validates that the fallback `route_id` in `{:fallback_phoenix, route_id}` exists in the manifest routes map. If not found, a `:warning` finding is emitted (code `"gating.fallback_route_unknown"`). Not `:error` because the route is still gated/fail-closed — the redirect just won't work.

### Claude's Discretion

- Exact finding codes: `"gating.route_registered"`, `"gating.flag_reference_unknown"`, `"gating.fallback_route_unknown"` — suggested names; planner may refine to match conventions.
- Whether to call `report_state/0` inside the gating check or reuse Phase 38's companion state. Avoid calling it twice per doctor run.
- Exact support-matrix accessor function name (e.g., `SupportMatrix.gating_truth/0`). Follow `commerce_corridors/0` / `commerce_corridor_proof_classes/0` precedent.
- Exact column label text and placement in rendered support-matrix output.

### Deferred Ideas (OUT OF SCOPE)

- `kill_switch_status` richer typespec (reason string) — Phase 42+.
- Multiple companion gate-state rows for same route — Phase 42+.
- `mix crosswake.doctor --check-publish` surface — already deferred.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GATE-05 | `mix crosswake.doctor` lists gated routes, flags unknown-referenced flags, and reports each gate's unavailable-posture; support-matrix output surfaces runtime gate state (`gated` / `rolling_out (N%)` / `killed`) labeled distinct from build-proof state. | `phase_41_gating_findings/1` in `Doctor`, `gate_status` typespec extension in `Companion.State`, new gating accessor in `SupportMatrix` |

</phase_requirements>

---

## Summary

Phase 41 is a pure Elixir extension of three existing modules — `Doctor`, `Companion.State`, and `SupportMatrix` — with no new dependencies and no new infrastructure. All patterns are firmly established by prior phases.

The Doctor extension follows the same per-route iteration pattern as `phase_19_commerce_corridor_posture/1` and the companion-list-iteration pattern of `phase_38_companion_seam_findings/0`. The new `phase_41_gating_findings/1` function receives the manifest, filters routes by `gated_by != nil`, and emits: one `:info` finding per gated route (with posture details and fallback hint), one `:error` per route whose `gated_by` atom is not found in any registered companion's `companion_id()`, and one `:warning` per route whose `{:fallback_phoenix, route_id}` target is not in `manifest.routes`.

The `Companion.State.gate_status` typespec is extended additively with `{:rolling_out, non_neg_integer()}`. This mirrors the existing `{:fallback_phoenix, atom()}` tagged-tuple pattern already used for `RouteEntry.on_unavailable`. No struct fields change — only the typespec union grows.

The SupportMatrix gains a new module-level function (following `commerce_corridors/0` naming) that reads `report_state/0` on each registered companion and maps the `gate_status` / `kill_switch_status` fields to the display strings locked in D-08. The column is labeled to distinguish runtime state from build-proof state. The hermetic proof goes in `test/crosswake/proof/phase41_gating_doctor_test.exs` with `async: false` and Application.put_env / on_exit cleanup, following Phase 38 and Phase 40 patterns exactly.

**Primary recommendation:** Implement `phase_41_gating_findings/1` first, then extend the `gate_status` typespec, then add the support-matrix accessor. The proof test exercises all three surfaces together. No new packages, no new infrastructure.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Gating doctor diagnostics | API / Backend (Elixir library) | — | Doctor is a pure Elixir diagnostic function; no network, no native tier |
| Companion gate-state typespec | API / Backend | — | `Companion.State` is a typed Elixir struct; type extension is local |
| Support-matrix gate-state column | API / Backend | — | `SupportMatrix` is a pure data-returning Elixir module |
| Proof test | API / Backend (test) | — | ExUnit hermetic lane; no native or browser tier involvement |

---

## Standard Stack

### Core

No new dependencies. This phase is entirely within the existing Elixir project.

| Module | File | Purpose |
|--------|------|---------|
| `Crosswake.Doctor` | `lib/crosswake/doctor/doctor.ex` | Add `phase_41_gating_findings/1` |
| `Crosswake.Companion.State` | `lib/crosswake/companion/state.ex` | Extend `gate_status` typespec |
| `Crosswake.SupportMatrix` | `lib/crosswake/support_matrix/support_matrix.ex` | Add gating accessor function |
| `Crosswake.Doctor.Check` | `lib/crosswake/doctor/check.ex` | Existing finding struct — read-only |
| `Crosswake.Manifest.Types.RouteEntry` | `lib/crosswake/manifest/types.ex` | Source of `gated_by` / `on_unavailable` — read-only |

### Test Infrastructure

| File | Purpose |
|------|---------|
| `test/crosswake/proof/phase41_gating_doctor_test.exs` | New hermetic proof file (SC#1, SC#2) |
| `test/support/stub_companion.ex` | Extended with gating fixture companions (inline or in support file) |

---

## Package Legitimacy Audit

No external packages are installed in this phase. The change is entirely internal to the existing Crosswake Elixir project.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
Doctor.run/1
  │
  ├── phase_38_companion_seam_findings/0
  │     └── Application.get_env(:crosswake, :companions, [])
  │           └── companion.validate_dependency()  [telemetry span]
  │
  └── phase_41_gating_findings/1 (NEW)
        ├── manifest.routes |> filter(gated_by != nil)
        │     ├── per-route :info finding (route_id, flag_ref, posture)
        │     │     └── hint: fallback_phoenix target if present
        │     ├── :error if gated_by atom ∉ companion_ids (D-04/D-05)
        │     └── :warning if {:fallback_phoenix, route_id} target not in manifest.routes (D-10)
        └── companion_ids = Application.get_env(:crosswake, :companions, [])
                            |> Enum.map(& &1.companion_id())

SupportMatrix.gating_truth/0 (NEW accessor)
  └── Application.get_env(:crosswake, :companions, [])
        └── companion.report_state()
              ├── gate_status: :active         → "gated"
              ├── gate_status: {:rolling_out,n} → "rolling_out (N%)"
              ├── kill_switch_status: :active   → "killed" (overrides gate_status)
              ├── gate_status: :inactive        → (not gated)
              └── gate_status: :unconfigured    → (not configured)

Companion.State.gate_status typespec (EXTENDED)
  :active | :inactive | :unconfigured | {:rolling_out, non_neg_integer()}
```

### Recommended Project Structure

```
lib/crosswake/
├── doctor/
│   └── doctor.ex                    # Add phase_41_gating_findings/1
├── companion/
│   └── state.ex                     # Extend gate_status typespec
└── support_matrix/
    └── support_matrix.ex            # Add gating_truth/0 (or equivalent)

test/crosswake/proof/
└── phase41_gating_doctor_test.exs   # New hermetic proof lane
```

### Pattern 1: Per-Route Iteration (from phase_19_commerce_corridor_posture/1)

**What:** Filter manifest routes, flat-map over them to produce findings.
**When to use:** Any doctor check that needs one finding per route matching some condition.

```elixir
# Source: lib/crosswake/doctor/doctor.ex lines 486-501 [VERIFIED: codebase grep]
defp phase_19_commerce_corridor_posture(nil), do: []

defp phase_19_commerce_corridor_posture(manifest) do
  manifest.routes
  |> Map.values()
  |> Enum.filter(&(not is_nil(&1.commerce)))
  |> Enum.flat_map(fn route ->
    # ... per-route findings
  end)
end
```

Phase 41 mirrors this: filter by `gated_by != nil`, flat-map producing `:info` + optional `:error` / `:warning` per route.

### Pattern 2: Companion List Iteration (from phase_38_companion_seam_findings/0)

**What:** Read companion list from Application env, iterate, emit per-companion findings.
**When to use:** Any check that needs to call a callback on each registered companion.

```elixir
# Source: lib/crosswake/doctor/doctor.ex lines 514-568 [VERIFIED: codebase grep]
defp phase_38_companion_seam_findings do
  companions = Application.get_env(:crosswake, :companions, [])
  Enum.flat_map(companions, fn companion ->
    companion_id = companion.companion_id()
    # ... per-companion findings
  end)
end
```

Phase 41 uses this to build the `known_companion_ids` set for checking `gated_by` atom resolution (D-04/D-05).

### Pattern 3: Check struct construction

**What:** All findings are built via the private `check/6` helper in `Doctor`.
**When to use:** Every new finding.

```elixir
# Source: lib/crosswake/doctor/doctor.ex line 1408 [VERIFIED: codebase grep]
defp check(severity, code, check_name, message, hint, details \\ %{}) do
  %Check{
    severity: severity,
    code: code,
    check: check_name,
    message: message,
    hint: hint,
    details: details
  }
end
```

The `hint` field is the correct field for the `{:fallback_phoenix, route_id}` posture note (D-09, confirmed by `Check.t()` definition).

### Pattern 4: Additive typespec extension

**What:** Add a new arm to an existing union type without breaking existing arms.
**When to use:** Tagged-tuple extension of `gate_status`.

```elixir
# Current (lib/crosswake/companion/state.ex line 8) [VERIFIED: codebase grep]
@type gate_status :: :active | :inactive | :unconfigured

# Extended (Phase 41)
@type gate_status :: :active | :inactive | :unconfigured | {:rolling_out, non_neg_integer()}
```

The `t()` struct type references `gate_status()` by name so it automatically inherits the extended union. No struct field changes needed.

### Pattern 5: SupportMatrix module-level accessor

**What:** Module attribute holds data; public function exposes it. Named parallel to existing accessors.
**When to use:** New canonical data table in SupportMatrix.

```elixir
# Source: lib/crosswake/support_matrix/support_matrix.ex lines 232-233 [VERIFIED: codebase grep]
@spec commerce_corridors() :: [map()]
def commerce_corridors, do: @commerce_corridor_entries
```

The gating accessor should follow the same pattern: a module-level function that either (a) builds from Application.get_env at call time, or (b) is a pure data function returning static mapping. Given the display mapping (D-08) is static, a pure function mapping `Companion.State.t()` → display string is cleaner than storing companion state at module level.

### Pattern 6: Hermetic proof test

**What:** `async: false`, `Application.put_env(:crosswake, :companions, [...])`, `on_exit` cleanup, inline fixture modules defined in the test file.
**When to use:** Any proof test that writes to shared Application env.

```elixir
# Source: test/crosswake/proof/phase38_companion_contract_test.exs line 26 [VERIFIED: codebase grep]
use ExUnit.Case, async: false
# ...
Application.put_env(:crosswake, :companions, [FixtureCompanion])
on_exit(fn -> Application.delete_env(:crosswake, :companions) end)
```

Phase 40 also uses this exact pattern with inline defmodule companions inside the test file. Phase 41 should use inline companions unless the fixture is complex enough to warrant test/support/.

### Anti-Patterns to Avoid

- **Merging gating findings into companion findings section:** D-01 is explicit — gating gets its own top-level doctor category.
- **Using `:warning` for unknown flag references:** D-04 locks this as `:error`. An unresolvable flag reference means the gate cannot evaluate — it's a config error.
- **Using `:error` for unknown fallback targets:** D-10 locks this as `:warning`. The gate still works fail-closed; the redirect just won't fire. A typo in the fallback route_id is a defect but not a gate-correctness defect.
- **Calling `report_state/0` in `phase_41_gating_findings/1` if Phase 38 already called it:** The CONTEXT.md flags this — avoid double-calling per doctor run. The planner should decide whether to thread Phase 38's already-computed states through or call once in a shared pre-pass.
- **Using `compile_env` for `:companions`:** The existing code uses `Application.get_env` (not `compile_env`) specifically so tests can register fixture companions via `put_env`. This must not change.
- **Extending `kill_switch_status` typespec:** D-07 explicitly locks this out of scope.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Finding severity | Custom severity type | Existing `Check.severity()` (`:error`, `:warning`, `:advisory`, `:info`) | Already in `Doctor.Check.t()` |
| Companion list access | Custom registry | `Application.get_env(:crosswake, :companions, [])` | Established pattern from Phase 38; tests depend on it |
| Route iteration | Custom manifest walk | `manifest.routes |> Map.values() |> Enum.filter(...)` | Established in `phase_19_commerce_corridor_posture/1` |
| Support matrix display | Custom formatter | Map `Companion.State.gate_status` / `kill_switch_status` atoms directly | D-08 is a closed mapping with 5 cases |

**Key insight:** Every building block already exists in the codebase. Phase 41 is assembly, not invention.

---

## Common Pitfalls

### Pitfall 1: `:info` severity is not in the current `Check.severity()` typespec

**What goes wrong:** `Crosswake.Doctor.Check` currently defines `@type severity :: :error | :warning | :advisory`. The CONTEXT.md D-03 says per-route gating findings carry `:info` severity, but `:info` is not in the existing typespec.

**Why it happens:** The CONTEXT.md uses `:info` as the intended severity for "this route is gated, here's the posture" findings, but the `Check.t()` type was defined before this phase.

**How to avoid:** The planner must decide: (a) extend `Check.severity()` to add `:info` (small additive change, update the formatter to handle it), or (b) use `:advisory` as the closest existing severity that communicates "informational, not a problem." The CONTEXT.md language is "`:info` communicates" but the type is `:advisory` — these may be synonymous in this codebase. Verify the formatter's `severity_order/1` function handles any new atom before adding it.

**Warning signs:** A `FunctionClauseError` from the formatter when rendering a finding with an unrecognized severity atom.

### Pitfall 2: Double-calling `report_state/0` if Phase 38 and Phase 41 both need it

**What goes wrong:** Phase 38's `phase_38_companion_seam_findings/0` may already call `report_state/0` on each companion. If `phase_41_gating_findings/1` also calls it to populate the support-matrix column, each companion's `report_state/0` fires twice per `Doctor.run/1` call.

**Why it happens:** The gating check needs the `gate_status` from each companion's state to populate the support-matrix display. Phase 38 doesn't currently call `report_state/0` — it calls `validate_dependency/0`. So there may be no actual duplication.

**How to avoid:** Verify Phase 38's code path: `phase_38_companion_seam_findings/0` calls `companion.validate_dependency()`, NOT `companion.report_state()`. The CONTEXT.md notes this explicitly. Therefore calling `report_state/0` only in Phase 41 is safe. If the support-matrix accessor is a separate function (`SupportMatrix.gating_truth/0`) called independently, it will call `report_state/0` once per companion per call — no duplication with Phase 38.

**Warning signs:** Unexpected telemetry emissions counted twice; performance concerns with expensive companion state reads.

### Pitfall 3: `manifest` is nil when no manifest compiled

**What goes wrong:** `phase_41_gating_findings/1` receives `nil` when manifest compilation failed. Calling `Map.values(nil.routes)` crashes.

**Why it happens:** Prior phase functions follow the `defp phase_XX(nil), do: []` guard pattern. Forgetting this causes a `BadMapError`.

**How to avoid:** Follow the established nil-guard pattern:

```elixir
defp phase_41_gating_findings(nil), do: []
defp phase_41_gating_findings(manifest) do ... end
```

All prior phase functions (`phase_10_posture/1`, `phase_19_commerce_corridor_posture/1`, `phase_4_posture/1`) follow this exact pattern.

### Pitfall 4: `on_unavailable: nil` routes treated as having explicit `:deny` posture

**What goes wrong:** `RouteEntry.on_unavailable` is `nil` when the field was not declared in the DSL. `nil` means "not set" — not the same as `:deny`. If the finding message says "posture: deny" when `on_unavailable` is nil, it misrepresents the route's actual posture.

**Why it happens:** The default fail-closed behavior when `on_unavailable` is nil is effectively deny, but the DSL has not explicitly declared it. Displaying `nil` as `:deny` conflates explicit declaration with implicit behavior.

**How to avoid:** In the `:info` finding message, distinguish `nil` from `:deny`:
- `nil` → "posture: fail-closed (default)" or "posture: deny (implicit)"
- `:deny` → "posture: deny (explicit)"
- `{:fallback_phoenix, id}` → hint text per D-09

### Pitfall 5: Forgetting to wire `phase_41_gating_findings/1` into `Doctor.run/1`

**What goes wrong:** The function is implemented but never called, so the findings list in `Report.t()` never includes gating findings.

**Why it happens:** `Doctor.run/1` has an explicit findings accumulation pattern where each phase function must be appended manually. Forgetting this means tests would pass in isolation but `Doctor.run/1` would silently emit no gating findings.

**How to avoid:** The findings accumulation in `run/1` (lines 119-148 of `doctor.ex`) must be updated:

```elixir
phase_41_findings = phase_41_gating_findings(manifest)

findings =
  findings ++
    phase_3_findings ++
    phase_4_findings ++
    phase_10_findings ++ phase_19_findings ++ phase_23_findings ++ phase_38_findings ++
    phase_41_findings  # ADD THIS
```

---

## Code Examples

Verified patterns from the codebase:

### Finding codes pattern (from existing code)

```elixir
# Source: lib/crosswake/doctor/doctor.ex [VERIFIED: codebase grep]
# Existing codes follow "<category>.<specific_problem>":
"companion.dependency_missing"
"commerce.corridor.undeclared"
"commerce.corridor.prerequisite_missing"
"commerce.corridor.role_unknown"

# Phase 41 codes (Claude's discretion to finalize):
"gating.route_registered"          # :info — route is gated, here's the posture
"gating.flag_reference_unknown"    # :error — gated_by atom resolves to no companion
"gating.fallback_route_unknown"    # :warning — {:fallback_phoenix, id} target not in manifest
```

### Check struct fields for gating findings

```elixir
# :info finding per gated route
check(
  :info,          # or :advisory if :info not in severity type
  "gating.route_registered",
  "gating.#{route.id}",
  "Route #{route.id} is gated by :#{route.gated_by} with #{format_posture(route.on_unavailable)} posture",
  fallback_hint(route.on_unavailable),  # D-09: hint field carries fallback posture note
  %{
    route_id: route.id,
    gated_by: route.gated_by,
    on_unavailable: format_on_unavailable(route.on_unavailable)
  }
)

# :error finding for unknown flag reference
check(
  :error,
  "gating.flag_reference_unknown",
  "gating.#{route.id}",
  "Route #{route.id} declares gated_by: :#{route.gated_by} but no registered companion has this companion_id",
  "Register a companion with companion_id/0 returning :#{route.gated_by} or update the gated_by declaration",
  %{route_id: route.id, gated_by: route.gated_by}
)

# :warning finding for unknown fallback route
check(
  :warning,
  "gating.fallback_route_unknown",
  "gating.#{route.id}",
  "Route #{route.id} declares on_unavailable: {:fallback_phoenix, :#{fallback_id}} but :#{fallback_id} is not in the manifest routes",
  "Add a route with id #{fallback_id} to the manifest or correct the fallback target",
  %{route_id: route.id, gated_by: route.gated_by, fallback_route_id: fallback_id}
)
```

### gate_status typespec extension

```elixir
# Source: lib/crosswake/companion/state.ex [VERIFIED: codebase grep]
# Current:
@type gate_status :: :active | :inactive | :unconfigured

# Phase 41 extension (additive):
@type gate_status :: :active | :inactive | :unconfigured | {:rolling_out, non_neg_integer()}
```

### Support-matrix gate state display mapping

```elixir
# D-08 display mapping
defp gate_state_display(%Crosswake.Companion.State{kill_switch_status: :active}), do: "killed"
defp gate_state_display(%Crosswake.Companion.State{gate_status: :active}), do: "gated"
defp gate_state_display(%Crosswake.Companion.State{gate_status: {:rolling_out, n}}),
  do: "rolling_out (#{n}%)"
defp gate_state_display(%Crosswake.Companion.State{gate_status: :inactive}), do: nil
defp gate_state_display(%Crosswake.Companion.State{gate_status: :unconfigured}), do: nil
```

### Fixture companion for Phase 41 proof test

```elixir
# Pattern: inline defmodule in test file (Phase 40 style)
# Source: test/crosswake/proof/phase40_gate_evaluation_test.exs [VERIFIED: codebase grep]

defmodule GatingActiveCompanion do
  @behaviour Crosswake.Companion
  @impl true; def companion_id, do: :test_gating_companion
  @impl true; def enabled?(_config), do: true
  @impl true; def route_gated?(_route, _target), do: :pass
  @impl true; def kill_switch_active?(_target), do: false
  @impl true; def validate_dependency, do: :ok
  @impl true
  def report_state do
    %Crosswake.Companion.State{
      companion_id: :test_gating_companion,
      enabled: true,
      dependency_status: :present,
      gate_status: :active,            # <-- drives "gated" display
      kill_switch_status: :inactive,
      checked_at: System.monotonic_time(:millisecond)
    }
  end
end

defmodule RollingOutCompanion do
  @behaviour Crosswake.Companion
  @impl true; def companion_id, do: :rolling_companion
  @impl true; def enabled?(_config), do: true
  @impl true; def route_gated?(_route, _target), do: :pass
  @impl true; def kill_switch_active?(_target), do: false
  @impl true; def validate_dependency, do: :ok
  @impl true
  def report_state do
    %Crosswake.Companion.State{
      companion_id: :rolling_companion,
      enabled: true,
      dependency_status: :present,
      gate_status: {:rolling_out, 10},  # <-- drives "rolling_out (10%)" display
      kill_switch_status: :inactive,
      checked_at: System.monotonic_time(:millisecond)
    }
  end
end
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| No gating doctor category | Phase 41 adds a dedicated "Gating" category | Phase 41 | Operators can see full gate health picture |
| `gate_status :: :active \| :inactive \| :unconfigured` | Extended with `{:rolling_out, non_neg_integer()}` | Phase 41 | Support matrix can display partial rollout truth |
| Support matrix has no runtime gate-state column | Phase 41 adds gate-state column labeled runtime-distinct | Phase 41 | Operators won't misread `rolling_out (10%)` as "supported" |

**Deprecated/outdated:**
- None — this phase is purely additive.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `:info` is a valid severity atom to add to `Check.severity()` without breaking the formatter's `severity_order/1` and `format_check/1` functions | Architecture Patterns / Pitfall 1 | Formatter crashes on `:info` severity; must fall back to `:advisory` or add formatter handler first |
| A2 | Phase 38's `phase_38_companion_seam_findings/0` does NOT call `report_state/0` on companions (it calls `validate_dependency/0` only) | Pitfall 2 | If Phase 38 also calls `report_state/0`, the planner must avoid double-calling; share computed states |

**A1 note:** The current `Check.severity()` type is `:error | :warning | :advisory`. The CONTEXT.md uses `:info` as the intended severity atom but the type doesn't include it. The planner must either: (1) add `:info` to `Check.severity()` and update the formatter, or (2) map `:info` intent to `:advisory` (the least-alarming existing severity). The CONTEXT.md language is "`:info` communicates 'this route is gated, here's the posture' without implying a problem" — `:advisory` has the same semantics in the existing codebase.

---

## Open Questions (RESOLVED)

1. **`:info` vs `:advisory` severity for gating findings**
   - What we know: D-03 says `:info`; existing `Check.severity()` type has `:advisory` as the closest match; formatter handles `:advisory` already.
   - What's unclear: Whether the intent is to add `:info` as a new severity atom (and update the formatter) or use `:advisory` as a semantic synonym.
   - Recommendation: Use `:advisory` unless the planner has a reason to widen the severity type. It avoids formatter changes and matches the semantics described in D-03 ("without implying a problem").

2. **Support-matrix accessor placement: new function vs. new section on existing module**
   - What we know: `SupportMatrix` already has `commerce_corridors/0` and `commerce_corridor_proof_classes/0` as pure module-level functions.
   - What's unclear: Whether `gating_truth/0` should be a pure function reading Application env at call time, or whether it belongs as a new section in the `canonical/1` function.
   - Recommendation: A standalone `gating_truth/0` function (calling `Application.get_env(:crosswake, :companions, [])` and `report_state/0` on each companion) mirrors the `commerce_corridors/0` precedent most directly. The `canonical/1` support matrix struct is for build-proof state; runtime gate state is explicitly labeled as distinct.

3. **`phase_41_gating_findings/1` call site in `Doctor.run/1`**
   - What we know: It must be called after `manifest` is compiled (needs `manifest.routes`), alongside phase_38 findings.
   - What's unclear: Whether to call it before or after `phase_38_companion_seam_findings/0` in the findings accumulation.
   - Recommendation: Call it after Phase 38 findings, since both read from `Application.get_env(:crosswake, :companions, [])` and the gating check conceptually follows the dependency check.

---

## Environment Availability

Step 2.6: SKIPPED — this phase has no external dependencies. Pure Elixir module extensions within the existing project. ExUnit and mix are already confirmed available (v3.4 shipped 2026-05-29).

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built into Elixir/OTP) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/crosswake/proof/phase41_gating_doctor_test.exs` |
| Full suite command | `mix test --exclude requires_example_host` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| GATE-05 (SC#1) | `mix crosswake.doctor` emits dedicated gating category: one `:info` per gated route, `:error` for unknown flag references, `:warning` for unknown fallback targets, `on_unavailable` posture surfaced | unit (hermetic) | `mix test test/crosswake/proof/phase41_gating_doctor_test.exs --only sc1` | ❌ Wave 0 |
| GATE-05 (SC#2) | Support-matrix gate-state column emits `gated` / `rolling_out (N%)` / `killed` strings from `report_state/0` values; column labeled runtime-distinct from build-proof state | unit (hermetic) | `mix test test/crosswake/proof/phase41_gating_doctor_test.exs --only sc2` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/crosswake/proof/phase41_gating_doctor_test.exs`
- **Per wave merge:** `mix test --exclude requires_example_host`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/crosswake/proof/phase41_gating_doctor_test.exs` — covers GATE-05 SC#1 and SC#2; new file, does not exist yet
- [ ] Hermetic setup block (temp dir + install manifest + router) reused from Phase 38 pattern — must be duplicated in the new test file

*(Existing test infrastructure is sufficient; only the new proof file needs to be created in Wave 0.)*

---

## Security Domain

This phase adds doctor diagnostics and a support-matrix display column. There is no new input surface, no authentication, no session management, no cryptography, and no user-facing data handling. All computation is pure Elixir over already-compiled manifest data and Application env.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | no | Manifest data already validated in earlier phases |
| V6 Cryptography | no | — |

No ASVS categories apply to this phase.

---

## Sources

### Primary (HIGH confidence)

- `lib/crosswake/doctor/doctor.ex` — Full source read; verified all phase function patterns, `check/6` helper, findings accumulation in `run/1`, `phase_19_commerce_corridor_posture/1` and `phase_38_companion_seam_findings/0` implementation details
- `lib/crosswake/companion/state.ex` — Full source read; verified current `gate_status` typespec (`:active | :inactive | :unconfigured`)
- `lib/crosswake/support_matrix/support_matrix.ex` — Full source read; verified `commerce_corridors/0` and `commerce_corridor_proof_classes/0` naming and pattern
- `lib/crosswake/doctor/check.ex` — Full source read; verified `Check.t()` struct fields (`severity`, `code`, `check`, `message`, `hint`, `details`)
- `lib/crosswake/manifest/types.ex` — Grepped and read `RouteEntry` struct; verified `gated_by: atom() | nil` and `on_unavailable: :deny | {:fallback_phoenix, atom()} | nil`
- `test/crosswake/proof/phase38_companion_contract_test.exs` — Full source read; verified `async: false`, `Application.put_env`, `on_exit` cleanup, setup block pattern
- `test/crosswake/proof/phase40_gate_evaluation_test.exs` — Full source read; verified inline `defmodule` companion fixture pattern
- `test/support/stub_companion.ex` — Full source read; verified `StubCompanion` and `BrokenCompanion` with `gate_status: :unconfigured`
- `lib/crosswake/companion.ex` — Full source read; verified `report_state/0` callback contract
- `.planning/phases/41-gating-doctor-and-support-matrix-truth/41-CONTEXT.md` — Full source read; all locked decisions

### Secondary (MEDIUM confidence)

- `.planning/REQUIREMENTS.md` — GATE-05 requirement description verified
- `.planning/STATE.md` — Milestone state verified (phase 41 ready to plan)
- `mix.exs` — Verified no new dependencies needed; existing deps (Jason, Phoenix, ExUnit) sufficient

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; all implementation targets are verified in-codebase files
- Architecture: HIGH — all patterns lifted directly from existing verified implementations
- Pitfalls: HIGH — all pitfalls derived from reading actual source code; not speculation

**Research date:** 2026-05-30
**Valid until:** 2026-06-30 (stable codebase; no external ecosystem dependency)
