# Phase 40: Runtime Gate Evaluation And Fail-Closed Denial - Context

**Gathered:** 2026-05-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire `route_gated?/2` and `kill_switch_active?/1` companion callbacks into
`RouteGate.evaluate/4` so that gated routes (those with `gated_by != nil`) fail
closed by default — producing structured, explainable `:gate_denied` /
`:kill_switch_active` denials — and kill switches short-circuit all other gate
evaluation.

**Satisfies:** GATE-03 (`:gate_denied` denial with OpenFeature-shaped `details`),
GATE-04 (kill-switch short-circuit; `{:fallback_phoenix}` is the only fail-open
path).

**In scope:**
- Add `:gate_denied` and `:kill_switch_active` to `Denial.@reasons` and `reason`
  typespec in `Shell.Denial`.
- Extend `RouteGate.evaluate/4` with a kill-switch short-circuit step (mirrors the
  `prepend_commerce_corridor_findings/3` pattern) — iterate all enabled companions,
  call `kill_switch_active?/1` on each; if any return `true` → produce
  `:kill_switch_active` denial, stop.
- Extend `RouteGate.evaluate/4` with a gate evaluation step for gated routes —
  iterate all enabled companions, call `route_gated?/2`; first `{:deny, finding}`
  → produce `:gate_denied` denial. Non-gated routes skip both steps entirely.
- Broaden `Decision.transition` typespec to include `{:redirect, atom()}` (see D-02).
- `transition_for/2` reads `route.on_unavailable` when building a deny decision;
  `{:fallback_phoenix, route_id}` → `{:redirect, route_id}`, `:deny` → `:halt`.
- OpenFeature-shaped `Denial.details` for `:gate_denied` (see D-03).
- Emit `[:crosswake, :companion, :route_gate, ...]` and
  `[:crosswake, :companion, :kill_switch, ...]` telemetry spans (specified in
  Phase 38 behaviour docs; emit sites belong to this phase).
- Hermetic proof: new `test/crosswake/proof/phase40_gate_evaluation_test.exs`
  (untagged, picked up by `phase34-proof.yml` automatically). Covers SC#1–4.

**Out of scope (belongs to later phases — do NOT pull forward):**
- Doctor gating category + `{:fallback_phoenix}` visibility — **Phase 41**.
- Runtime gate-state support-matrix column (`gated` / `rolling_out` / `killed`) — **Phase 41**.
- Real rulestead companion impl at `lib/crosswake/companions/rulestead/` — **Phase 42**.
- `finding.subject` carrying companion-supplied reason/variant strings — **Phase 42+**.
- `flag_variant` field on `Finding` struct — **Phase 42** (if needed for named variants).

</domain>

<decisions>
## Implementation Decisions

### ① Decision.t() for `on_unavailable: {:fallback_phoenix}` — LOCKED
- **D-01:** `Decision.transition` is broadened to a union type:
  `transition: :activate | :halt | :stay_put | {:redirect, atom()}`.
  No new struct fields. When the gate denies AND `route.on_unavailable == {:fallback_phoenix, route_id}`,
  `transition_for/2` returns `{:redirect, route_id}` instead of `:halt`.
- **D-02:** `Decision.status` remains `:deny` in all denial cases — the denial is
  still produced (`:gate_denied` or `:kill_switch_active`); only the `transition`
  field changes to communicate redirect intent. The caller does a single
  `case decision.transition` with four exhaustive arms:
  ```elixir
  case decision.transition do
    :activate      -> ...
    :halt          -> ...
    :stay_put      -> ...
    {:redirect, id} -> ...
  end
  ```
- **D-02 rationale:** Tagged transition tuple is the right choice because:
  (a) the codebase already uses `{:fallback_phoenix, atom()}` as a tagged tuple
  on a struct field for this exact semantic in `RouteEntry.on_unavailable`;
  (b) it makes illegal states unrepresentable (no `{:halt, fallback_route: "x"}`
  contradiction); (c) a separate `fallback_route_id` field (Option B) allows
  both `:halt` and `fallback_route_id` to be set simultaneously — contradictory;
  (d) a recovery map (Option C) conflates machine-navigable routing instructions
  with human-readable hints, creating a nil-safety chain at every call site.

### ② OpenFeature-shaped `Denial.details` for `:gate_denied` — LOCKED
- **D-03:** The complete `Denial.details` map for `:gate_denied` in Phase 40:
  ```elixir
  %{
    "flag_key"     => Atom.to_string(route.gated_by),
    "reason"       => "DISABLED",
    "variant"      => "off",
    "evaluated_at" => DateTime.utc_now() |> DateTime.to_iso8601()
  }
  ```
- **D-04 (`evaluated_at` source):** RouteGate stamps `DateTime.utc_now()` and
  serializes it immediately to an ISO8601 string
  (`DateTime.utc_now() |> DateTime.to_iso8601()`). This keeps `Denial.to_map/1`
  simple (no special `DateTime` handling in `Types.to_map/1`), is human-readable,
  and is consistent with Ecto/Phoenix `utc_datetime` conventions.
  NOTE: `evaluated_at` is NOT in the OpenFeature 1.x spec — it is a Crosswake-owned
  explainability extension. `Companion.State.checked_at` uses monotonic time for
  internal perf measurement, which is correct there but NOT appropriate here (not
  human-readable, not serializable).
- **D-05 (`reason` vocabulary):** Use exact OpenFeature reason strings:
  `"DISABLED"` for a binary flag-is-off denial in Phase 40.
  OpenFeature standard vocabulary: `STATIC`, `DEFAULT`, `TARGETING_MATCH`,
  `SPLIT`, `CACHED`, `DISABLED`, `UNKNOWN`, `STALE`, `ERROR`.
  Phase 42+ companions supply the real reason via `finding.subject` — RouteGate
  reads `finding.subject` when non-nil, falls back to `"DISABLED"`.
- **D-06 (`variant` in Phase 40):** `"off"` is the constant variant for Phase 40.
  This is the correct and conventional OpenFeature binary flag variant string (all
  major SDKs use `"off"` / `"on"`). Phase 42+ companions supply real variants via
  `finding.subject` (or a future `Finding.flag_variant` field added then — not now).
  Never nil — `Denial.to_map/1` strips nil values; an absent field is worse than
  `"off"` for explainability.
- **D-07 (`flag_key`):** `Atom.to_string(route.gated_by)` — RouteGate has the
  route in scope; `gated_by` is an atom; string form is correct for the wire format.

### ③ `:kill_switch_active` denial details — LOCKED
- **D-08:** `Denial.details` for `:kill_switch_active` is minimal — no OpenFeature
  fields (kill switch is companion-level, not flag-level). Planner discretion on
  exact shape; at minimum include `%{"companion_id" => Atom.to_string(companion.companion_id())}`.

### ④ Companion dispatch strategy — LOCKED (from Phase 38 behaviour contract)
- **D-09:** For gated routes (`route.gated_by != nil`), RouteGate iterates
  ALL enabled companions (read from `Application.get_env(:crosswake, :companions, [])`)
  for both kill-switch and gate checks. Each companion decides internally in
  `kill_switch_active?/1` / `route_gated?/2` whether it applies to the given
  route/target. A companion that does not handle the route's flag returns `false`
  from `kill_switch_active?/1` and `:pass` from `route_gated?/2`. This matches
  the Phase 38 contract (D-03 in 38-CONTEXT.md) and the existing
  `Application.get_env(:crosswake, :companions, [])` config pattern.
- **D-10:** Kill-switch check is a short-circuit: first companion returning `true`
  from `kill_switch_active?/1` → `:kill_switch_active` denial; remaining companions
  are not called. Gate check: first companion returning `{:deny, finding}` from
  `route_gated?/2` → `:gate_denied` denial; remaining companions are not called.
  (Consistent with "kill switches short-circuit ahead of ALL other gate evaluation.")
- **D-11:** `kill_switch_active?/1` is called ONLY for gated routes (`gated_by != nil`).
  Non-gated routes skip both kill-switch and gate evaluation entirely.

### ⑤ Proof test strategy — LOCKED
- **D-12:** New `test/crosswake/proof/phase40_gate_evaluation_test.exs`, untagged,
  picked up automatically by `phase34-proof.yml`. No new CI workflow file.
- **D-13:** Fixture companions defined inline as modules within the test file.
  `Application.put_env(:crosswake, :companions, [...])` in `setup_all` with
  `on_exit` cleanup. `async: false` (global Application state). Mirrors the
  Phase 38 `TestCompanion` fixture pattern.
- **D-14:** Full SC#1–4 coverage in Phase 40:
  - **SC#1:** `RouteGate.evaluate/4` with a fixture gate companion produces a
    `:gate_denied` denial with `details["flag_key"]`, `details["reason"]`,
    `details["variant"]`, `details["evaluated_at"]` all present and non-nil.
  - **SC#2:** When a fixture kill-switch companion returns `true` from
    `kill_switch_active?/1`, the Decision produces `:kill_switch_active` denial,
    `route_gated?/2` is never called (assert via side-effect spy or counter).
  - **SC#3:** Fixture companion simulating unavailable snapshot returns
    `{:deny, finding}` from `route_gated?/2`; route with `on_unavailable: :deny`
    → `transition: :halt`; route with `on_unavailable: {:fallback_phoenix, :home}`
    → `transition: {:redirect, :home}`.
  - **SC#4:** `RouteGate.evaluate/4` is a pure function call with no network
    dependency (all state derived from `Root.t()`, `Target.t()`, and registered
    companion modules — no HTTP in the evaluation path).

### Claude's Discretion
- Exact `finding_to_denial/2` extension strategy: RouteGate may either (a)
  produce `Denial.t()` directly for gate/kill-switch findings (bypassing
  `finding_to_denial/2`) OR (b) use new `:gate_denied` / `:kill_switch_active`
  axes in `finding_to_denial/2`. The `evaluated_at` and `flag_key` fields come
  from the RouteGate context, not the Finding, so Option (a) is likely cleaner.
  Planner decides.
- Telemetry span implementation: `:telemetry.span/3` wrapping each companion
  callback is the preferred Keathley pattern; planner verifies this matches the
  Phase 38 `validate_dependency` span implementation.
- `maybe_add_finding`-style helper vs. inline prepend: follow existing RouteGate
  patterns (see `prepend_commerce_corridor_findings/3` / `maybe_add_finding/2`).
- Whether to add a `prepend_gate_evaluation_findings/3` function following the
  commerce corridor pattern, or a separate `gate_evaluation_step/3`: planner
  discretion.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` §"Phase 40" — goal, success criteria SC#1–4, plan count TBD
- `.planning/REQUIREMENTS.md` §GATE — GATE-03 and GATE-04 (active requirements this phase)

### Core implementation files
- `lib/crosswake/compatibility/route_gate.ex` — `RouteGate.evaluate/4`, `Decision.t()`,
  `prepend_commerce_corridor_findings/3` pattern, `transition_for/2` — the primary file
  being extended in this phase
- `lib/crosswake/shell/denial.ex` — `Denial.t()`, `@reasons`, `Denial.new/1`,
  `to_map/1` — `:gate_denied` and `:kill_switch_active` atoms must be added here
- `lib/crosswake/companion.ex` — `Crosswake.Companion` behaviour, callback specs
  for `route_gated?/2` and `kill_switch_active?/1`, telemetry event name contracts
- `lib/crosswake/manifest/types.ex` §RouteEntry — `gated_by`, `on_unavailable` fields
  (added in Phase 39); `new_route_entry/1` builder
- `lib/crosswake/compatibility/compatibility.ex` lines 105–165 — `finding_to_denial/2`
  extension point; existing axis→reason mapping pattern

### Prior phase context
- `.planning/phases/39-route-policy-gating-dsl-and-manifest-binding/39-CONTEXT.md` —
  all Phase 39 decisions; D-07 (binding vs. value split), D-05 (on_unavailable semantics)
- `.planning/phases/38-companion-seam-contract/38-CONTEXT.md` —
  companion dispatch pattern (D-03), kill-switch route-independence (D-07),
  telemetry span convention (D-08/D-09)

### Proof test patterns
- `test/crosswake/proof/phase38_companion_contract_test.exs` — Application.put_env
  fixture companion pattern, `async: false`, `on_exit` cleanup
- `test/crosswake/proof/phase39_route_policy_gating_test.exs` — inline router fixture
  pattern, untagged hermetic proof convention

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `RouteGate.prepend_commerce_corridor_findings/3` — the insertion pattern for
  custom findings ahead of standard compatibility findings; gate evaluation follows
  this same structure
- `RouteGate.maybe_add_finding/2` — nil-safe finding accumulator; reuse for
  gate denial and kill-switch finding assembly
- `Compatibility.finding_to_denial/2` — existing Finding→Denial path; gate
  findings may use this (new axes) or bypass it (direct Denial.new/1); planner
  decides which is cleaner given `flag_key`/`evaluated_at` come from RouteGate scope
- `Denial.ensure_commerce_corridor_payload/3` — precedent for enriching `details`
  and `recovery` maps based on `reason` atom in `Denial.new/1`
- `Companion.State.t()` — `gate_status` and `kill_switch_status` fields are
  currently `:unconfigured`; Phase 40 wiring makes them meaningful for Phase 41
  doctor reporting

### Established Patterns
- Kill-switch and gate steps run ONLY for gated routes (`route.gated_by != nil`);
  non-gated routes skip both steps entirely — consistent with "gating is opt-in"
- Companions registered in `Application.get_env(:crosswake, :companions, [])`;
  RouteGate reads this at evaluation time (no compile-time registry)
- `[:crosswake, :companion, :route_gate, :start | :stop | :exception]` and
  `[:crosswake, :companion, :kill_switch, :start | :stop | :exception]` are the
  pre-specified telemetry event names (Phase 38 behaviour docs); do NOT invent new names
- Phase 38 test pattern: `async: false`, `Application.put_env` with `on_exit` cleanup,
  inline module fixtures — this proof follows that exact setup

### Integration Points
- `RouteGate.evaluate/4` signature unchanged — new behavior is additive (new
  prepend step runs before commerce corridor steps for gated routes)
- `Decision.t()` gets a broader `transition` typespec — callers already pattern-matching
  `:halt` need to be updated if they exist outside the library; check call sites
- `Denial.@reasons` grows two atoms — additive; existing `finding_to_denial/2` cases
  are unchanged

</code_context>

<specifics>
## Specific Ideas

- The tagged transition tuple `{:redirect, atom()}` mirrors `RouteEntry.on_unavailable`'s
  `{:fallback_phoenix, atom()}` shape — intentional symmetry, makes the on_unavailable
  contract legible end-to-end
- OpenFeature reason strings are ALL_CAPS strings, not atoms — `"DISABLED"`, not
  `:disabled` — because `Denial.details` is a plain `map()` that crosses the wire
  as strings; no atom-to-string translation needed in `to_map/1`
- `evaluated_at` as pre-serialized ISO8601 string (not a `DateTime` struct) means
  `Types.to_map/1` needs no special clause — it passes through as a string value

</specifics>

<deferred>
## Deferred Ideas

- **`{:fallback_phoenix, route_id}` visibility in doctor output** — Phase 41. The
  ROADMAP SC#3 note "visible in doctor output as a deliberate choice" belongs to
  Phase 41's doctor category work, not Phase 40 evaluation wiring.
- **Companion-supplied `reason` and `variant` via `finding.subject`** — Phase 42.
  When rulestead is in-tree, companions can populate `finding.subject` with a
  compact encoding of reason+variant; RouteGate prefers it over the Phase 40
  constants. The `Finding` struct needs no change in Phase 40.
- **`Finding.flag_variant` dedicated field** — Phase 42 if needed for named
  segments/rollouts. Not worth adding for Phase 40's binary fixture.
- **Multiple companion denials accumulation** — Currently first-deny-wins (D-10).
  If accumulating all companion denials into `Decision.denials: [Denial.t()]` is
  desired (matching how commerce corridors accumulate), this is a Phase 42+ concern
  once multiple companions coexist.
- **`crosswake_openfeature` companion** — v3.6+. The OpenFeature data shape adopted
  here makes this a drop-in without retrofit.

</deferred>

---

*Phase: 40-runtime-gate-evaluation-and-fail-closed-denial*
*Context gathered: 2026-05-30*
