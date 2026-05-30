# Phase 41: Gating Doctor And Support-Matrix Truth - Context

**Gathered:** 2026-05-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Add a dedicated "Gating" doctor category and a runtime gate-state column to the
support matrix so operators can see the full gate health picture — which routes
are gated, which flag references are unresolvable, what the unavailable posture is,
and whether each companion is currently gating, rolling out, or kill-switched.

**Satisfies:** GATE-05

**In scope:**
- New `phase_41_gating_findings/1` (or equivalent) in `Doctor` — one `:info`
  finding per gated route (route_id, flag reference, on_unavailable posture) plus
  `:error` for unknown flag references and `:warning` for unknown fallback targets.
- `Companion.State.gate_status` typespec extended with `{:rolling_out, non_neg_integer()}`.
- Support-matrix gate-state column: `report_state/0` value maps to display string
  (`gated`, `rolling_out (N%)`, `killed`) labeled runtime-distinct from build-proof state.
- `{:fallback_phoenix, route_id}` posture surfaced as a hint on the per-route `:info`
  finding; unknown fallback route_id emits a separate `:warning`.
- Hermetic proof: `test/crosswake/proof/phase41_gating_doctor_test.exs` (SC#1, SC#2).

**Out of scope:**
- Real rulestead companion impl — Phase 42.
- Companion-supplied reason/variant strings — Phase 42+.
- Support-matrix for non-gating companion surfaces — future phases as needed.

</domain>

<decisions>
## Implementation Decisions

### ① Doctor category structure — LOCKED
- **D-01:** Gating checks get a new top-level doctor category ("Gating") — a sibling
  to the Phase 38 "Companion Dependencies" category. Gating findings are not merged into
  the companion findings section. This mirrors how commerce corridors and companion
  dependencies each got their own section.
- **D-02:** One finding per gated route — each route with `gated_by != nil` emits its own
  doctor finding. Mirrors `phase_19_commerce_corridor_posture/1` which emits one finding
  per commerce-route. Makes per-route severity and details natural.
- **D-03:** Per-route informational findings carry `:info` severity. Gating is intentional
  configuration — `:info` communicates "this route is gated, here's the posture" without
  implying a problem.

### ② Unknown flag reference severity — LOCKED
- **D-04:** When a route's `gated_by` atom does not match any registered companion's
  `companion_id()`, doctor emits an `:error` finding (e.g., code
  `"gating.flag_reference_unknown"`). This mirrors `companion.dependency_missing`
  (Phase 38, `:error`). An unresolvable flag reference means the gate cannot evaluate
  at runtime — it is a config error, not a warning.
- **D-05:** When no companions are registered (`Application.get_env(:crosswake,
  :companions, [])` is empty) but gated routes exist, the same per-route
  `"gating.flag_reference_unknown"` `:error` fires for each gated route. No separate
  "no companions registered" top-level error — the per-route pattern is consistent
  and sufficient.

### ③ Runtime gate-state column — LOCKED
- **D-06:** `Companion.State.gate_status` typespec grows a tagged-tuple variant:
  ```elixir
  @type gate_status :: :active | :inactive | :unconfigured | {:rolling_out, non_neg_integer()}
  ```
  `report_state/0` returns this richer type. The support matrix reads it directly.
  No "magic key" in the `details` map.
- **D-07:** `kill_switch_status` stays as-is: `:inactive | :active | :unconfigured`.
  Kill switches are binary — no percentage applies. Extending it is deferred to Phase 42+
  when a real companion populates it.
- **D-08:** Support-matrix display mapping (gate-state column):
  - `gate_status: :active` → `"gated"` (companion is actively evaluating the route)
  - `gate_status: {:rolling_out, n}` → `"rolling_out (N%)"` (partial rollout)
  - `kill_switch_status: :active` → `"killed"` (kill switch thrown; overrides gate_status)
  - `gate_status: :inactive` → route is not currently gated by this companion
  - `gate_status: :unconfigured` → companion not yet configured for gating

  **Kill switch takes precedence:** if `kill_switch_status: :active`, display `"killed"`
  regardless of `gate_status`. The column must be labeled runtime-distinct from
  build-proof state (e.g., "Runtime Gate State — not build-proof posture").

### ④ {:fallback_phoenix} doctor visibility — LOCKED
- **D-09:** `on_unavailable: {:fallback_phoenix, route_id}` is surfaced as a hint on
  the per-route `:info` finding. Example hint text: "deliberate redirect posture —
  gate denial navigates to `:some_route` instead of halting". No separate finding
  for routes that have the fallback posture.
- **D-10:** Doctor validates that the fallback `route_id` in `{:fallback_phoenix, route_id}`
  exists in the manifest routes map. If the target route is not found, a `:warning` finding
  is emitted (e.g., code `"gating.fallback_route_unknown"`). Consistent with the
  "unknown gated_by reference" `:error` approach — catches typos at doctor-run time.

### Claude's Discretion
- Exact finding codes: `"gating.route_registered"`, `"gating.flag_reference_unknown"`,
  `"gating.fallback_route_unknown"` are suggested names; planner may refine to match
  existing naming conventions (observe `"companion.dependency_missing"`,
  `"commerce.corridor.*"` patterns).
- Whether to call `report_state/0` on companions inside the gating check or reuse the
  state already produced by Phase 38's companion check. Planner decides — avoid
  calling it twice per doctor run if avoidable.
- Exact support-matrix accessor function name (e.g., `SupportMatrix.gating_truth/0`
  or a new section on the existing `SupportMatrix` module). Follow the
  `commerce_corridors/0` / `commerce_corridor_proof_classes/0` precedent.
- The exact column label text ("Runtime Gate State") and placement in the rendered
  support-matrix output. Planner follows the rendered support matrix section ordering.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` §"Phase 41" — goal, success criteria SC#1–SC#2, plan count TBD
- `.planning/REQUIREMENTS.md` §GATE — GATE-05 (the sole active requirement this phase)

### Core implementation files to extend
- `lib/crosswake/doctor/doctor.ex` — add `phase_41_gating_findings/1` function;
  observe `phase_38_companion_seam_findings/0` (companion pattern) and
  `phase_19_commerce_corridor_posture/1` (per-route finding pattern)
- `lib/crosswake/support_matrix/support_matrix.ex` — add gate-state column entries;
  observe `commerce_corridors/0`, `commerce_corridor_proof_classes/0` for naming
  and structure conventions
- `lib/crosswake/companion/state.ex` — extend `gate_status` typespec to include
  `{:rolling_out, non_neg_integer()}`; `kill_switch_status` unchanged
- `lib/crosswake/companion.ex` — `report_state/0` callback; verify `State.t()` type
  reference is updated consistently
- `lib/crosswake/manifest/types.ex` §RouteEntry — `gated_by` and `on_unavailable`
  fields (added Phase 39); `new_route_entry/1` builder — read-only reference for
  the doctor check

### Prior phase context
- `.planning/phases/40-runtime-gate-evaluation-and-fail-closed-denial/40-CONTEXT.md` —
  D-01 notes that Phase 40 deferred `{:fallback_phoenix}` visibility and the gating
  doctor category to this phase; D-03/D-05 specify OpenFeature details shape
- `.planning/phases/39-route-policy-gating-dsl-and-manifest-binding/39-CONTEXT.md` —
  `gated_by` / `on_unavailable` DSL decisions; Phase 39 owns the manifest binding
- `.planning/phases/38-companion-seam-contract/38-CONTEXT.md` —
  companion dispatch pattern, `validate_dependency/0` `:error` finding precedent
  (D-03 doctor pattern), `report_state/0` contract

### Proof test patterns
- `test/crosswake/proof/phase38_companion_contract_test.exs` — `Application.put_env`
  fixture companion pattern, `async: false`, `on_exit` cleanup
- `test/crosswake/proof/phase40_gate_evaluation_test.exs` — inline fixture companion
  modules, untagged hermetic proof convention

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Doctor.phase_38_companion_seam_findings/0` — reads `Application.get_env(:crosswake,
  :companions, [])`, iterates companions, emits per-companion findings; gating check
  follows this exact structure but adds per-route iteration
- `Doctor.phase_19_commerce_corridor_posture/1` — emits one finding per commerce route;
  the per-gated-route finding pattern mirrors this
- `Doctor.Check.t()` — `%{severity:, code:, message:, hint:, check:, details: %{}}`;
  `hint` is the right field for the fallback posture note (D-09)
- `SupportMatrix.commerce_corridors/0` and `commerce_corridor_proof_classes/0` —
  naming and structure convention for new gate-state accessor
- `Companion.State.t()` — already has `gate_status` and `kill_switch_status` fields;
  Phase 40 wired them; Phase 41 reads them for support-matrix output

### Established Patterns
- Finding codes follow `"<category>.<specific_problem>"` pattern:
  `"companion.dependency_missing"`, `"commerce.corridor.undeclared"` — use
  `"gating.flag_reference_unknown"`, `"gating.fallback_route_unknown"` (or similar)
- Companion state is fetched via `companion.report_state()` (no Application.get_env
  needed for state — only for the companions list)
- Support-matrix runtime-state columns are labeled to distinguish them from
  build-proof posture (see commerce `proof_class` vs. runtime corridor state)
- `async: false` with `Application.put_env` / `on_exit` cleanup in all companion
  proof tests (global Application state)

### Integration Points
- New `phase_41_gating_findings/1` called in `Doctor.run/2` alongside Phase 38/19
  findings; must receive the manifest as argument (for route iteration)
- `Companion.State.gate_status` typespec change is additive — existing
  `:active | :inactive | :unconfigured` arms remain valid; new
  `{:rolling_out, non_neg_integer()}` arm adds the rollout case
- The gate-state support-matrix column reads `report_state/0` on each companion;
  if Phase 38's companion check already calls `report_state/0`, consider reusing
  that result rather than calling it again (planner's call)

</code_context>

<specifics>
## Specific Ideas

- The `{:rolling_out, non_neg_integer()}` typespec extension mirrors the existing
  `{:fallback_phoenix, atom()}` pattern used for `RouteEntry.on_unavailable` — Crosswake
  consistently uses tagged tuples to make illegal states unrepresentable and carry
  typed payloads alongside a discriminant atom.
- The hint text for `{:fallback_phoenix, route_id}` on the per-route `:info` finding
  should be human-readable, e.g.: `"deliberate redirect posture — gate denial
  navigates to :some_route instead of halting"` (Phase 40 CONTEXT.md §deferred).
- `"gating.fallback_route_unknown"` at `:warning` (not `:error`) because the route is
  still gated/fail-closed — the redirect just won't work. It's a config defect but
  not one that makes the gate evaluate incorrectly.

</specifics>

<deferred>
## Deferred Ideas

- **`kill_switch_status` richer typespec** — extend `kill_switch_status` to carry a
  reason string (e.g., `{:active, reason_string}`) for richer explainability. Deferred
  to Phase 42+ when a real companion populates it.
- **Multiple companion gate-state rows in support matrix** — if multiple companions
  gate the same route, the display logic for conflicting states. Deferred to Phase 42+
  when multiple companions coexist in the test fixture.
- **`mix crosswake.doctor --check-publish` surface** — already deferred from v3.3;
  not in scope here.

</deferred>

---

*Phase: 41-gating-doctor-and-support-matrix-truth*
*Context gathered: 2026-05-30*
