# Roadmap: Crosswake

## Milestones

- ✅ **v1.0 Route-Policy Substrate** — Phases 1-5 shipped on 2026-05-17.
- ✅ **v2.0 Adopter Stress Profiles** — Phases 6-10 shipped on 2026-05-19. Full archive: [.planning/milestones/v2.0-ROADMAP.md](milestones/v2.0-ROADMAP.md)
- ✅ **v3.0 Capability Contract And Packaging** — Phases 11-14 shipped on 2026-05-20. Full archive: [.planning/milestones/v3.0-ROADMAP.md](milestones/v3.0-ROADMAP.md)
- ✅ **v3.1 Native Capabilities and Bridge Expansion** — Phases 15-18 shipped on 2026-05-27. Full archive: [.planning/milestones/v3.1-ROADMAP.md](milestones/v3.1-ROADMAP.md)
- ✅ **v3.2 Commerce And Entitlement Seams** — Phases 19-25 shipped on 2026-05-27. Full archive: [.planning/milestones/v3.2-ROADMAP.md](milestones/v3.2-ROADMAP.md)
- ✅ **v3.3 Release Readiness** — Phases 26-32 shipped on 2026-05-29 (`crosswake 0.1.0` live on hex.pm). Full archive: [.planning/milestones/v3.3-ROADMAP.md](milestones/v3.3-ROADMAP.md)
- ✅ **v3.4 Commerce Archetype Proof** — Phases 33-37 shipped on 2026-05-29. Full archive: [.planning/milestones/v3.4-ROADMAP.md](milestones/v3.4-ROADMAP.md)
- 🚧 **v3.5 First-Party Companions** — Phases 38-47 (in progress)

## Phases

<details>
<summary>✅ v3.3 Release Readiness (Phases 26-32) — SHIPPED 2026-05-29</summary>

- [x] Phase 26: Package Metadata Audit (4/4 plans) — completed 2026-05-28
- [x] Phase 27: Versioning Decision And CHANGELOG Synthesis (2/2 plans) — completed 2026-05-28
- [x] Phase 28: release-please Configuration Files (1/1 plan) — completed 2026-05-28
- [x] Phase 29: Release Workflows And Supply-Chain Hardening (1/1 plan) — completed 2026-05-28
- [x] Phase 30: Hex Page Polish And Tarball Dry-Run (2/2 plans) — completed 2026-05-29
- [x] Phase 31: First Hex Publish (Human-Gated) — completed 2026-05-29 (`crosswake 0.1.0` live)
- [x] Phase 32: Post-Publish Cleanup — completed 2026-05-29

</details>

<details>
<summary>✅ v3.4 Commerce Archetype Proof (Phases 33-37) — SHIPPED 2026-05-29</summary>

- [x] Phase 33: Corridor Routes And CI Infrastructure (2/2 plans) — completed 2026-05-29
- [x] Phase 34: MockStorefront And Idempotency Invariants (2/2 plans) — completed 2026-05-29
- [x] Phase 35: Reconciliation Wiring And Four-State LiveView (2/2 plans) — completed 2026-05-29
- [x] Phase 36: Hermetic Proof Lane (1/1 plan) — completed 2026-05-29
- [x] Phase 37: Guides Walkthrough And Docs-Contract Lock (1/1 plan) — completed 2026-05-29

Full phase details: [.planning/milestones/v3.4-ROADMAP.md](milestones/v3.4-ROADMAP.md)

</details>

### 🚧 v3.5 First-Party Companions (Phases 38-47)

**Milestone Goal:** Lock a reusable Phoenix-native companion-seam pattern, prove it generalizes across two real companions (rulestead gating + rindle media), and ship the auth-context contract that unblocks the rest — all in-tree, all fail-closed, all proven by the established hermetic+advisory + docs-contract template.

- [x] **Phase 38: Companion Seam Contract** — `Crosswake.Companion` behaviour, optional-dep handling, in-tree convention, telemetry (completed 2026-05-30)
- [x] **Phase 39: Route-Policy Gating DSL And Manifest Binding** — `gated_by` key + `:custom` validator; build-time binding / runtime value split carried into `RouteEntry` (completed 2026-05-30)
- [x] **Phase 40: Runtime Gate Evaluation And Fail-Closed Denial** — `:gate_denied`/`:kill_switch_active` injected into `RouteGate`; kill-switch short-circuit; OpenFeature-shaped `Denial.details` (completed 2026-05-30)
- [x] **Phase 41: Gating Doctor And Support-Matrix Truth** — doctor category for gated routes; runtime gate-state column distinct from build-proof state (completed 2026-05-30)
- [x] **Phase 42: Rulestead In-Tree Companion And Mock Example** — `lib/crosswake/companions/rulestead/`; mock flag source in `examples/phoenix_host`; route through all gate states (completed 2026-05-30)
- [ ] **Phase 43: Rulestead Hermetic+Advisory Proof And Guide** — hermetic CI lane (no optional dep, asserts fail-closed); advisory lane; `guides/companions.md` rulestead section with docs-contract lock
- [x] **Phase 44: Rindle Media Seam Contracts And Reconciliation Vocabulary** — `UploadGrant`/`CaptureEvidence`/`MediaObject` contracts; backend-owned non-authoritative reconciliation vocabulary (completed 2026-05-31)
- [x] **Phase 45: Rindle In-Tree Companion, Mock Example, And Proof** — pure-Elixir mock upload/verify; hermetic proof; generalization proof that the pattern isn't flag-specific (completed 2026-05-31)
- [ ] **Phase 46: Sigra Auth Contract-Only Slice** — `AuthContext` + `SessionAuthorityLane` + route auth predicates; fail-closed `:step_up_required`; doctor/support-matrix truth
- [ ] **Phase 47: Companion Arc Guide And Milestone Proof** — `guides/companions.md` overview; deferred non-goals documented; cross-companion docs-contract parity; milestone-level hermetic proof

## Phase Details

### Phase 38: Companion Seam Contract

**Goal**: A maintainer can define a first-party companion by implementing `Crosswake.Companion` — the shared behaviour that all companions (rulestead, rindle, sigra) build on, generalized from `Crosswake.Commerce`.
**Depends on**: Phase 37 (v3.4 complete)
**Requirements**: COMP-01, COMP-02, COMP-03
**Success Criteria** (what must be TRUE):

  1. A module can `@behaviour Crosswake.Companion` and satisfy all declared callbacks (`companion_id/0`, `enabled?/1`, `route_gated?/2`, `kill_switch_active?/1`, `validate_dependency/0`, `report_state/0`) without implementing any additional boilerplate.
  2. A companion that is enabled in host config but whose optional library is missing causes `mix crosswake.doctor` to emit an `:error` finding that names the missing dependency — never a silent no-op or a crash.
  3. `lib/crosswake/companions/<name>/` is established as the canonical in-tree location convention, verifiable by inspecting the module namespace of any shipped companion.
  4. Companion events emit as `[:crosswake, :companion, …]` telemetry spans with static event names differentiated by `companion_id` metadata, following Keathley conventions.**Plans**: 2 plans

**Wave 1**

- [x] 38-01-PLAN.md — Crosswake.Companion behaviour + Companion.State struct + direct :telemetry dep (contract surface)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 38-02-PLAN.md — Doctor fail-closed wiring + validate_dependency telemetry span + fixture & hermetic proof (SC#1/SC#2/SC#4)

### Phase 39: Route-Policy Gating DSL And Manifest Binding

**Goal**: A Phoenix team can declare a named `gated_by` flag on any route in the DSL, and the binding is recorded in the compiled manifest — so the flag relationship is auditable at build time even before any runtime evaluation.
**Depends on**: Phase 38
**Requirements**: GATE-01, GATE-02
**Success Criteria** (what must be TRUE):

  1. `gated_by: :my_flag` is a valid key in the route-policy DSL and is validated at compile time as a typed atom identifier; invalid values (wrong type, unknown shape) are rejected with a clear error.
  2. The compiled runtime manifest `RouteEntry` carries the `gated_by` binding for every gated route, readable by introspection and visible in doctor output.
  3. The manifest build step records the binding (which flag governs this route) distinctly from the flag value (enabled/disabled/kill-switched), so offline manifest inspection is accurate without any runtime flag evaluation.

**Plans**: 2 plans

**Wave 1**

- [x] 39-01-PLAN.md — `gated_by` + `on_unavailable` DSL keys: `Policy.Schema` validators + `Policy.Route` struct/cross-key validation + GATE-01 hermetic proof (SC#1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 39-02-PLAN.md — manifest binding: `RouteEntry` fields + `Builder` pass-through + `to_map/1` serialization + GATE-02 binding-vs-value proof (SC#2/SC#3)

### Phase 40: Runtime Gate Evaluation And Fail-Closed Denial

**Goal**: Route activation for a gated route fails closed by default — producing a structured, explainable denial — and kill switches short-circuit all other gate checks ahead of the standard evaluation path.
**Depends on**: Phase 39
**Requirements**: GATE-03, GATE-04
**Success Criteria** (what must be TRUE):

  1. When a gate denies, `RouteGate.evaluate/4` produces a `:gate_denied` denial carrying `flag_key`, `reason`, `variant`, and `evaluated_at` in an OpenFeature-shaped `details` map — not a generic error or a silent fall-through.
  2. Kill switches produce `:kill_switch_active` and short-circuit ahead of all other gate evaluation (mirrors the `prepend_commerce_corridor_findings/3` pattern); no other logic can unblock a killed route.
  3. When the flag snapshot is unavailable, the default posture is `:deny`; the only exception is an explicit `on_unavailable: :fallback_phoenix` pointing to a fully-owned Phoenix route, and that carve-out is visible in doctor output as a deliberate choice.
  4. Flag evaluation reads from a local snapshot with no network call in the activation decision path.

**Plans**: 1 plan
Plans:

- [x] 40-01-PLAN.md — wire gate + kill-switch evaluation into RouteGate; :gate_denied/:kill_switch_active denials; OpenFeature-shaped details; on_unavailable redirect; SC#1-4 proof

### Phase 41: Gating Doctor And Support-Matrix Truth

**Goal**: `mix crosswake.doctor` surfaces the full gate health picture — which routes are gated, which flag references are unknown, and what the unavailable posture is — and the support matrix distinguishes runtime gate state from build-proof state.
**Depends on**: Phase 40
**Requirements**: GATE-05
**Success Criteria** (what must be TRUE):

  1. `mix crosswake.doctor` emits a dedicated gating category that lists every gated route by name, flags any `gated_by` reference that does not resolve to a known companion, and reports each route's `on_unavailable` posture.
  2. Support-matrix output includes a runtime gate-state column with values `gated`, `rolling_out (N%)`, or `killed` — explicitly labeled as runtime-distinct from build-proof state, so `rolling_out (10%)` is never read as "supported."

**Plans**: 2 plans
Plans:
**Wave 1**

- [x] 41-01-PLAN.md — Extend gate_status typespec, implement phase_41_gating_findings/1 doctor category, wire into run/1, create SC#1 proof scaffold

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 41-02-PLAN.md — Add SupportMatrix.gating_truth/0 runtime gate-state accessor (gated/rolling_out (N%)/killed) and SC#2 proof coverage

### Phase 42: Rulestead In-Tree Companion And Mock Example

**Goal**: A working rulestead companion lives at `lib/crosswake/companions/rulestead/` and a route in `examples/phoenix_host` exercises all three gate states (`gated`, `rolling_out`, `killed`) via a pure-Elixir mock flag source.
**Depends on**: Phase 41
**Requirements**: COMP-01, COMP-02, COMP-03, GATE-01, GATE-02, GATE-03, GATE-04, GATE-05
**Success Criteria** (what must be TRUE):

  1. `lib/crosswake/companions/rulestead/` contains an impl module that satisfies `Crosswake.Companion` with `companion_id: :rulestead`, wires into the existing `RouteGate` pipeline, and reads from a local ETS-style snapshot with no network call.
  2. `examples/phoenix_host` contains a route declaring `gated_by: :my_flag` and a pure-Elixir mock flag source that can be swapped to drive the route through `gated`, `rolling_out`, and `killed` states during local development and in the hermetic proof lane.
  3. Enabling the rulestead companion with the `rulestead` library absent causes doctor to emit a named `:error`; enabling it with the library present and the mock source configured produces a clean doctor output.

**Plans**: 2 plans

**Wave 1**

- [x] 42-01-PLAN.md — Crosswake.Companions.Rulestead companion + MockFlagSource named Agent + hermetic proof (SC#1/SC#3; COMP-01/02/03, GATE-02/03/04/05)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 42-02-PLAN.md — phoenix_host /gating scope + BetaFeatureLive + MockFlagSource supervisor child + companion config (SC#2; GATE-01)

### Phase 43: Rulestead Hermetic+Advisory Proof And Guide

**Goal**: The rulestead seam has a merge-blocking hermetic CI lane that passes without the optional dependency present (proving fail-closed), an advisory lane with it present, and a `guides/companions.md` rulestead section locked by a docs-contract test.
**Depends on**: Phase 42
**Requirements**: PROOF-01, PROOF-02
**Success Criteria** (what must be TRUE):

  1. A hermetic CI job compiles and runs the rulestead proof suite with `rulestead` absent from the dep tree; all assertions about fail-closed behavior pass; the job is merge-blocking.
  2. An advisory CI job runs the same suite with `rulestead` present; it uses `continue-on-error: true` and is documented with a promotion path (the conditions under which it graduates to merge-blocking).
  3. `guides/companions.md` contains a rulestead section covering `gated_by` DSL, gate-state semantics, kill-switch behavior, and the mock swap target; a docs-contract ExUnit test asserts the section exists and that key anchor strings match live code.

**Plans**: 2 plans

**Wave 1**

- [x] 43-01-PLAN.md — mix.exs MIX_INCLUDE_RULESTEAD conditional dep + advisory proof test (validate_dependency :ok) + phase43-proof.yml two-job hermetic/advisory workflow (PROOF-01)

**Wave 2** *(blocked on Wave 1 completion — shared mix.exs edit)*

- [x] 43-02-PLAN.md — guides/companions.md (intro + rulestead section, exact DSL anchors) + companions_test.exs docs-contract test + ExDoc extras registration (PROOF-02)

### Phase 44: Rindle Media Seam Contracts And Reconciliation Vocabulary

**Goal**: The typed contracts for the rindle media lane are defined — `UploadGrant`, `CaptureEvidence`, `MediaObject` — along with a backend-owned reconciliation vocabulary that mirrors `Crosswake.Commerce.Reconciliation` and enforces device evidence as non-authoritative.
**Depends on**: Phase 43
**Requirements**: MEDIA-01, MEDIA-02
**Success Criteria** (what must be TRUE):

  1. `Crosswake.Companions.Rindle.Contracts` exposes `UploadGrant` (expiry, max_bytes, accepted_types, key_prefix, idempotency_key), `CaptureEvidence` (hash, size, mime — evidence only), and `MediaObject` with a typed state lane (`:queued | :uploaded | :scanning | :available | :rejected`); all are documented structs with validation functions following the `validate_*/1 :: :ok | {:error, kw}` pattern.
  2. The reconciliation vocabulary is backend-owned: device-reported upload success alone does not advance a `MediaObject` to `:available`; only backend verification can; this invariant is enforced at the contract level, not merely by convention.
  3. The `MediaObject` state machine mirrors the `Crosswake.Commerce.Reconciliation` vocabulary structurally, making it recognizable to anyone who has read the commerce contracts.

**Plans**: 2 plans
Plans:
**Wave 1**

- [x] 44-01-PLAN.md — Rindle contract structs + validators + MEDIA-01 hermetic proof

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 44-02-PLAN.md — backend-owned reconciliation vocabulary + evidence-only availability fence + MEDIA-02 proof

**UI hint**: yes

### Phase 45: Rindle In-Tree Companion, Mock Example, And Proof

**Goal**: A working rindle companion lives at `lib/crosswake/companions/rindle/`, a pure-Elixir mock upload/verify example in `examples/phoenix_host` proves the media lane end-to-end with no external SDK, and a hermetic proof lane confirms fail-closed behavior and mandatory idempotency.
**Depends on**: Phase 44
**Requirements**: MEDIA-03, PROOF-01
**Success Criteria** (what must be TRUE):

  1. `lib/crosswake/companions/rindle/` contains an impl module satisfying `Crosswake.Companion` with `companion_id: :rindle`; the module body is guarded by `Code.ensure_loaded?` and `validate_dependency/0` fails closed when `rindle` is absent.
  2. `examples/phoenix_host` contains a pure-Elixir mock upload/verify flow (no external SDK) that drives a `MediaObject` through `:queued → :uploaded → :scanning → :available`, enforces idempotency (stable `idempotency_key`, not transient correlation), and never presents `:queued` media as committed.
  3. A hermetic CI job compiles and runs the rindle proof suite without the `rindle` library present; fail-closed assertions pass; this is the generalization proof that the companion-seam pattern works for a non-flag use case.

**Plans**: 3 plans

**Wave 1**

- [x] 45-01-PLAN.md — Rindle companion implementation + optional dependency wiring + doctor fail-closed proof (MEDIA-03/PROOF-01)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 45-02-PLAN.md — phoenix_host pure-Elixir media mock lane + `/media/proof` LiveView route + idempotency/replay proof (MEDIA-03)

**Wave 3** *(blocked on Waves 1-2 completion)*

- [x] 45-03-PLAN.md — Phase 45 hermetic/advisory proof hardening + `phase45-proof.yml` CI workflow (MEDIA-03/PROOF-01)

### Phase 46: Sigra Auth Contract-Only Slice

**Goal**: The typed auth contracts (`AuthContext`, `SessionAuthorityLane`, `StepUpChallenge`) and route auth predicates (`auth_min_level`, `requires_recent_auth`) are defined and wired into `RouteGate` as fail-closed `:step_up_required` denials — with no handoff, step-up, or passkey machinery built.
**Depends on**: Phase 45
**Requirements**: AUTH-01, AUTH-02
**Success Criteria** (what must be TRUE):

  1. `AuthContext` (actor_id, org_id, mfa_level, auth_age) and `SessionAuthorityLane` (backend-set only) are defined as typed structs; device/client auth signals are accepted only as evidence fields, never as authority fields, enforced at the contract level.
  2. `auth_min_level` and `requires_recent_auth` are valid keys in the route-policy DSL; when a route's auth predicates are unmet at evaluation time, `RouteGate.evaluate/4` produces a fail-closed `:step_up_required` denial — no silent pass-through.
  3. `mix crosswake.doctor` reports routes with auth predicates in its output, and support-matrix truth includes a row for the sigra auth contract surface; both outputs are accurate without any sigra machinery (handoff/step-up/passkey) being present.

**Plans**: 4 plans

Plans:
**Wave 1**

- [x] 46-01-PLAN.md — sigra auth contract structs, validators, and AUTH-01 unit coverage

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 46-02-PLAN.md — route DSL, manifest truth, checked-in shell fixture manifests, and AUTH-02 proof scaffold

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 46-03-PLAN.md — fail-closed `:step_up_required` RouteGate wiring and denial precedence proof

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 46-04-PLAN.md — auth doctor diagnostics and support-matrix contract truth

### Phase 47: Companion Arc Guide And Milestone Proof

**Goal**: `guides/companions.md` documents the full companion-seam pattern (behaviour, optional-dep posture, in-tree convention, telemetry, gating, media, auth), explicitly records deferred work as non-goals, and is locked by docs-contract tests; a milestone-level hermetic proof confirms all companions compile and pass fail-closed checks without any optional dependency present.
**Depends on**: Phase 46
**Requirements**: PROOF-02
**Success Criteria** (what must be TRUE):

  1. `guides/companions.md` exists with an overview section covering the `Crosswake.Companion` behaviour, the `lib/crosswake/companions/<name>/` convention, optional-dep handling (fail-closed), and the telemetry contract — readable as a standalone "how to build a companion" guide.
  2. The guide explicitly lists deferred non-goals: chimeway seam-only (not delivery), full sigra machinery (handoff/step-up/passkey), threadline capstone, and separate-package extraction — and notes the sequencing rationale for each.
  3. A docs-contract ExUnit test asserts parity between the guide and live doctor/support-matrix truth: key anchor strings (companion IDs, denial codes, DSL keys) present in the guide match what the shipped code actually emits.
  4. A milestone-level hermetic CI job compiles all three companions (rulestead, rindle, sigra contract) with their optional deps absent and asserts that every enabled-but-missing path produces a doctor `:error` finding rather than a crash or silent no-op.

**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 33. Corridor Routes And CI Infrastructure | v3.4 | 2/2 | Complete | 2026-05-29 |
| 34. MockStorefront And Idempotency Invariants | v3.4 | 2/2 | Complete | 2026-05-29 |
| 35. Reconciliation Wiring And Four-State LiveView | v3.4 | 2/2 | Complete | 2026-05-29 |
| 36. Hermetic Proof Lane | v3.4 | 1/1 | Complete | 2026-05-29 |
| 37. Guides Walkthrough And Docs-Contract Lock | v3.4 | 1/1 | Complete | 2026-05-29 |
| 38. Companion Seam Contract | v3.5 | 2/2 | Complete    | 2026-05-30 |
| 39. Route-Policy Gating DSL And Manifest Binding | v3.5 | 2/2 | Complete    | 2026-05-30 |
| 40. Runtime Gate Evaluation And Fail-Closed Denial | v3.5 | 1/1 | Complete    | 2026-05-30 |
| 41. Gating Doctor And Support-Matrix Truth | v3.5 | 2/2 | Complete    | 2026-05-30 |
| 42. Rulestead In-Tree Companion And Mock Example | v3.5 | 2/2 | Complete    | 2026-05-30 |
| 43. Rulestead Hermetic+Advisory Proof And Guide | v3.5 | 2/2 | In Progress|  |
| 44. Rindle Media Seam Contracts And Reconciliation Vocabulary | v3.5 | 2/2 | Complete   | 2026-05-31 |
| 45. Rindle In-Tree Companion, Mock Example, And Proof | v3.5 | 3/3 | Complete    | 2026-05-31 |
| 46. Sigra Auth Contract-Only Slice | v3.5 | 3/4 | In Progress|  |
| 47. Companion Arc Guide And Milestone Proof | v3.5 | 0/? | Not started | - |
