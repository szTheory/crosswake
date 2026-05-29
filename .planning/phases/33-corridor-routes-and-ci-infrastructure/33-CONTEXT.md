# Phase 33: Corridor Routes And CI Infrastructure - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Declare the three `subscription_default` corridor routes in the `examples/phoenix_host`
router (so they land in the runtime manifest with correct corridor metadata) and stand
up the `phase34-proof.yml` two-job CI split that will gate every PR for the rest of v3.4.

**In scope:** route declarations (DSL + manifest presence) and CI scaffolding only.
**Out of scope:** `MockStorefront` (Phase 34), reconciliation/LiveView wiring (Phase 35),
the hermetic proof test (Phase 36), guides walkthrough (Phase 37). This phase builds the
scaffold those phases hang off — no commerce logic, no LiveView bodies, no proof test yet.

**Requirements:** PWAL-01, PROOF-02.

</domain>

<decisions>
## Implementation Decisions

### Corridor Route Shape
- **D-01:** Declare all three corridor routes in a new `scope "/commerce", CrosswakeExample`
  block in `examples/phoenix_host/lib/crosswake_example/router.ex`, each carrying
  `commerce: [corridor: :subscription_default, role: <role>]` so every role_ownership entry
  lands in the manifest (satisfies Success Criterion #2).
- **D-02:** `paywall_entry` → a `live` route: `live "/paywall", PaywallEntryLive, :index,
  commerce: [corridor: :subscription_default, role: :paywall_entry]`. Phoenix-owned role,
  so a LiveView screen is the honest shape.
- **D-03:** `purchase_intent` and `restore_intent` → `post` controller routes
  (`post "/purchase", CorridorController, :purchase` / `post "/restore", CorridorController, :restore`),
  NOT `live` routes. Rationale: both roles are `:native_or_companion_required`; declaring them
  as Phoenix `live` screens would misrepresent native-owned corridors as Phoenix-owned and
  contradict the runtime-ownership thesis. As POST endpoints they read honestly as "the backend
  seam a native screen/companion POSTs evidence to." They are declaration artifacts here — in the
  mock lane (Phase 35) purchase is driven by a LiveView `handle_event` button on `PaywallEntryLive`,
  not by these HTTP routes — but they put the full corridor role topology into the manifest and
  show adopters the real integration seam.

### Route Targets When Modules Absent
- **D-04:** Forward-reference `PaywallEntryLive` and `CorridorController` (both land in Phase 35).
  No throwaway stub modules. Justification: Phoenix routes are quoted AST so `mix compile`
  succeeds without the targets; no Phase-33 test hits the routes at runtime; and the manifest
  builder reads only the route `commerce:` policy metadata, not the target module
  (`lib/crosswake/manifest/builder.ex` `commerce_corridor_registry/1`).
- **D-05:** Add the two forward-referenced modules to the router's
  `@compile {:no_warn_undefined, ...}` list (the router already does this for the policy module)
  to keep `mix compile --warnings-as-errors` clean.

### CI Test Topology (`phase34-proof.yml`)
- **D-06:** Two-job split mirroring `.github/workflows/phase23-proof.yml`:
  a hermetic `merge-blocking` job and an `advisory` job with `continue-on-error: true`,
  including the 4-condition `promotion_path` comment block copied/adapted from phase23.
- **D-07:** Hermetic job runs from repo root: `mix compile --warnings-as-errors` then
  `mix test --exclude requires_example_host`. This is the standing gate; the Phase 36 proof
  file is picked up automatically by the broad run (no per-file path list needed, unlike
  phase23 — but a path-targeted invocation of the proof file is acceptable if the planner
  prefers phase23's explicit-file style).
- **D-08:** Tag semantics: `requires_example_host` (an ExUnit `@tag`/`@moduletag`) marks ONLY
  server/integration-backed example tests. The Phase 36 hermetic proof stays UNtagged and pulls
  example-host modules via `Code.require_file` at module scope (per locked STATE discipline,
  mirrors phase21/phase23), so it runs inside the merge-blocking lane despite using example-host code.
- **D-09:** Advisory job = phase23-style placeholder echo steps (StoreKit / Play Billing /
  device-storefront), `continue-on-error: true`, scheduled + `workflow_dispatch` triggered, never
  gating a merge. Hermetic job triggers on `pull_request` + `push` to main + `workflow_dispatch`.

### Naming Note
- **D-10:** The workflow filename is `phase34-proof.yml` (locked by requirement PROOF-02 and the
  ROADMAP), even though it is created in Phase 33 — it is named for the milestone proof surface
  (Phase 34+) it gates, paralleling how `phase23-proof.yml` covers a span of commerce work. Do not
  rename to `phase33-proof.yml`.

### Claude's Discretion
- Exact `/commerce` sub-paths (`/paywall`, `/purchase`, `/restore`), pipeline reuse (`:browser`
  vs a dedicated pipeline), controller/LiveView module names, and whether the proof job lists the
  proof file explicitly vs relies on the broad `mix test` run — all planner-level details.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone / Requirements
- `.planning/REQUIREMENTS.md` — v3.4 requirements (PWAL-01, PROOF-02 for this phase) + Out of Scope table (anti-features AF-01..AF-08).
- `.planning/ROADMAP.md` §"Phase 33: Corridor Routes And CI Infrastructure" — goal + 4 success criteria.
- `.planning/threads/commerce-archetype-proof.md` — milestone thread / strategic intent.
- `.planning/research/SUMMARY.md` — grounding: reuse-don't-rebuild module inventory.

### Commerce Route-Policy DSL (reuse, do not modify)
- `lib/crosswake/policy/schema.ex` §50-85 — `commerce:` declaration schema; `@commerce_role_values` = `[:paywall_entry, :purchase_intent, :restore_intent, :account_management]`; `commerce_declaration` type.
- `lib/crosswake/policy/corridor_profiles.ex` §17-34 — `:subscription_default` corridor + role→ownership map (paywall_entry/account_management → `:phoenix_owned`; purchase_intent/restore_intent → `:native_or_companion_required`).
- `lib/crosswake/policy/route.ex` §18 — route struct commerce field.
- `lib/crosswake/compatibility/compatibility.ex` — canonical `commerce.corridor.*` denial vocabulary.

### Manifest / Support Truth (verify routes land correctly)
- `lib/crosswake/manifest/builder.ex` §158-185 — `commerce_corridor_registry/1` (discovers corridors from routes; reads policy metadata, not target modules).
- `lib/crosswake/manifest/types.ex` §50-51, §164-178 — `commerce_corridors` manifest map + `CommerceCorridor` struct (`id`, `role_ownership`, `denial`, `fallback`, `prerequisites`).
- `lib/crosswake/support_matrix/support_matrix.ex` §233 — `commerce_corridors/0` accessor.

### CI Pattern (mirror exactly)
- `.github/workflows/phase23-proof.yml` — two-job hermetic+advisory template; `promotion_path` 4-condition comment (§19-28); job structure, triggers, `continue-on-error: true` on advisory.

### Example Host (where this phase writes)
- `examples/phoenix_host/lib/crosswake_example/router.ex` — target router; existing `crosswake_defaults`/`live_session` scope patterns; existing `@compile {:no_warn_undefined, ...}` (§28).
- `examples/phoenix_host/lib/crosswake_example/application.ex` — supervision tree (Repo only; NO PubSub — see deferred todo).
- `examples/phoenix_host/lib/crosswake_example/commerce/{reconciliation_inbox,entitlement_projection,reconciliation_keys}.ex` — Phase 21 modules reused downstream (not modified in Phase 33).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `:subscription_default` corridor + role-ownership map already exist in `corridor_profiles.ex` — Phase 33 references, never defines.
- Router already uses `crosswake_defaults do ... end` blocks mixing `live` and controller (`get`/`post`) routes (see `/study`, root, `/saas`, `/native` scopes) — the new `/commerce` scope follows the same idiom.
- `phase23-proof.yml` is a complete, working two-job template — copy its structure, swap the test targets/echo steps.
- Manifest builder auto-discovers corridors from any route carrying a `commerce:` declaration — no separate registration step needed.

### Established Patterns
- Phoenix routes compile from quoted AST → forward-referencing not-yet-existing target modules is safe (validated by scout); add to `@compile {:no_warn_undefined, ...}` for warnings-as-errors.
- CI proof discipline: hermetic merge-blocking lane vs scheduled-only advisory lane with documented `promotion_path` (PROJECT.md Key Decision, v3.3+ default).
- `Code.require_file` at module scope is the established way example-host-driven tests reach example modules from the root suite (phase21/phase23) — keeps them hermetic, no running server.

### Integration Points
- New `/commerce` routes → `Crosswake.Manifest.Builder` → `SupportMatrix.commerce_corridors/0` (verify metadata correctness in this phase).
- `phase34-proof.yml` → repo-root `mix test --exclude requires_example_host` → becomes the gate Phases 34-37 PRs must pass.

</code_context>

<specifics>
## Specific Ideas

- Concrete recommended router block (planner may refine paths/names):
  ```elixir
  scope "/commerce", CrosswakeExample do
    pipe_through :browser
    crosswake_defaults do
      live "/paywall",  PaywallEntryLive, :index,
        commerce: [corridor: :subscription_default, role: :paywall_entry]
      post "/purchase", CorridorController, :purchase,
        commerce: [corridor: :subscription_default, role: :purchase_intent]
      post "/restore",  CorridorController, :restore,
        commerce: [corridor: :subscription_default, role: :restore_intent]
    end
  end
  ```
- Verify the `commerce:` declaration value form against `schema.ex` `validate_commerce_declaration` during planning — ROADMAP locks the atom form `corridor: :subscription_default`; confirm the validator accepts it (schema `type_spec` lists `corridor: String.t() | nil`, so reconcile atom-vs-string before asserting the "canonical DSL shape" copy-able criterion).

</specifics>

<deferred>
## Deferred Ideas

- **PubSub startup (Phase 35 prerequisite):** `CrosswakeExample.PubSub` is NOT started in
  `application.ex` (Repo only). Tracked in STATE pending-todos for Phase 33 confirmation; the
  actual add belongs before Phase 35 LiveView wiring — not required for Phase 33's route/CI scaffold.
- **CorridorController implementation:** forward-referenced here; its action bodies (and whether they
  delegate to the mock evidence path) are Phase 35 wiring decisions.
- **Verification simulation shape** (inline LiveView handler vs separate context fn) — Phase 35 todo.
- **Retroactive SHA-pinning of pre-v3.3 proof workflows** — deferred (STATE); not in this phase's scope.

None of the above are scope creep into Phase 33 — they are correctly downstream.

</deferred>

---

*Phase: 33-Corridor Routes And CI Infrastructure*
*Context gathered: 2026-05-29*
