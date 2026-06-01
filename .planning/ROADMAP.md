# Roadmap: Crosswake

## Milestones

- ✅ **v1.0 Route-Policy Substrate** — Phases 1-5 shipped on 2026-05-17.
- ✅ **v2.0 Adopter Stress Profiles** — Phases 6-10 shipped on 2026-05-19. Full archive: [v2.0-ROADMAP.md](milestones/v2.0-ROADMAP.md)
- ✅ **v3.0 Capability Contract And Packaging** — Phases 11-14 shipped on 2026-05-20. Full archive: [v3.0-ROADMAP.md](milestones/v3.0-ROADMAP.md)
- ✅ **v3.1 Native Capabilities and Bridge Expansion** — Phases 15-18 shipped on 2026-05-27. Full archive: [v3.1-ROADMAP.md](milestones/v3.1-ROADMAP.md)
- ✅ **v3.2 Commerce And Entitlement Seams** — Phases 19-25 shipped on 2026-05-27. Full archive: [v3.2-ROADMAP.md](milestones/v3.2-ROADMAP.md)
- ✅ **v3.3 Release Readiness** — Phases 26-32 shipped on 2026-05-29 (`crosswake 0.1.0` live on hex.pm). Full archive: [v3.3-ROADMAP.md](milestones/v3.3-ROADMAP.md)
- ✅ **v3.4 Commerce Archetype Proof** — Phases 33-37 shipped on 2026-05-29. Full archive: [v3.4-ROADMAP.md](milestones/v3.4-ROADMAP.md)
- ✅ **v3.5 First-Party Companions** — Phases 38-47 shipped on 2026-05-31. Full archive: [v3.5-ROADMAP.md](milestones/v3.5-ROADMAP.md)
- 🔄 **v3.6 Operator Truth and Production Diagnostics** — Phases 48-53 active. Goal: make Crosswake inspectable and supportable for production SaaS mobile apps before adding more provider/native breadth.

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

Full phase details: [v3.3-ROADMAP.md](milestones/v3.3-ROADMAP.md)

</details>

<details>
<summary>✅ v3.4 Commerce Archetype Proof (Phases 33-37) — SHIPPED 2026-05-29</summary>

- [x] Phase 33: Corridor Routes And CI Infrastructure (2/2 plans) — completed 2026-05-29
- [x] Phase 34: MockStorefront And Idempotency Invariants (2/2 plans) — completed 2026-05-29
- [x] Phase 35: Reconciliation Wiring And Four-State LiveView (2/2 plans) — completed 2026-05-29
- [x] Phase 36: Hermetic Proof Lane (1/1 plan) — completed 2026-05-29
- [x] Phase 37: Guides Walkthrough And Docs-Contract Lock (1/1 plan) — completed 2026-05-29

Full phase details: [v3.4-ROADMAP.md](milestones/v3.4-ROADMAP.md)

</details>

<details>
<summary>✅ v3.5 First-Party Companions (Phases 38-47) — SHIPPED 2026-05-31</summary>

- [x] Phase 38: Companion Seam Contract (2/2 plans) — completed 2026-05-30
- [x] Phase 39: Route-Policy Gating DSL And Manifest Binding (2/2 plans) — completed 2026-05-30
- [x] Phase 40: Runtime Gate Evaluation And Fail-Closed Denial (1/1 plan) — completed 2026-05-30
- [x] Phase 41: Gating Doctor And Support-Matrix Truth (2/2 plans) — completed 2026-05-30
- [x] Phase 42: Rulestead In-Tree Companion And Mock Example (2/2 plans) — completed 2026-05-30
- [x] Phase 43: Rulestead Hermetic+Advisory Proof And Guide (2/2 plans) — completed 2026-05-30
- [x] Phase 44: Rindle Media Seam Contracts And Reconciliation Vocabulary (2/2 plans) — completed 2026-05-31
- [x] Phase 45: Rindle In-Tree Companion, Mock Example, And Proof (3/3 plans) — completed 2026-05-31
- [x] Phase 46: Sigra Auth Contract-Only Slice (4/4 plans) — completed 2026-05-31
- [x] Phase 47: Companion Arc Guide And Milestone Proof (2/2 plans) — completed 2026-05-31

Full phase details: [v3.5-ROADMAP.md](milestones/v3.5-ROADMAP.md)

</details>

<details open>
<summary>🔄 v3.6 Operator Truth and Production Diagnostics (Phases 48-53) — ACTIVE</summary>

- [x] Phase 48: Strategic Signal and Milestone Memory — refresh the durable milestone arc, closeout checklist, and future queue. (completed 2026-05-31)
- [x] Phase 49: Operator Inspection Contract — define route/capability/companion/provider/auth/notification readiness inspection and machine-readable output. (completed 2026-05-31)
- [x] Phase 50: Doctor Publish and Readiness Checks — implement `mix crosswake.doctor --check-publish` and richer actionable findings. (completed 2026-06-01)
- [ ] Phase 51: Support Matrix and Native Rebuild Truth — synchronize support, rebuild, advisory, merge-blocking, companion, commerce, auth, notification, and shell truth.
- [ ] Phase 52: Operator Proof and Docs-Contract Locks — lock inspection, doctor, support matrix, denial/rebuild vocabulary, and guidance with hermetic proof.
- [ ] Phase 53: Release Continuity and Closeout Hardening — align changelog/release support truth and enforce closeout parity for future milestones.

### Phase Details

**Phase 48: Strategic Signal and Milestone Memory**

Goal: Make `.planning/MILESTONE-ARC.md` the current strategic source of truth after v3.5.

Requirements: STRAT-01, STRAT-02

Success criteria:
1. Shipped milestones through v3.5 are accurately marked complete.
2. The next 4-6 milestone bets are listed with dependencies and why-now rationale.
3. Durable lessons from retrospectives and audits are promoted into planning-time guidance.
4. The milestone closeout checklist covers roadmap parity, requirements state, verification reports, validation ledgers, threads/seeds, and release continuity.

**Plans**: 3 plans
Plans:
**Wave 1**

- [x] 48-01-PLAN.md — refresh `MILESTONE-ARC.md` to the locked strategic-memory field contract and collapse project-level queue drift onto that canonical source
- [x] 48-02-PLAN.md — create `.planning/milestones/v3.6-CLOSEOUT.md` as the live closeout ledger, checklist, and explicit Phase 53 enforcement target

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 48-03-PLAN.md — add deterministic ExUnit parity guards for the strategic arc, closeout ledger, and exact `closeout.verify` promotion target

**Phase 49: Operator Inspection Contract**

Goal: Define the inspection surface operators and CI use to understand Crosswake route/runtime readiness without reading code.

Requirements: OPER-01, OPER-02

Success criteria:
1. Inspection output covers route ownership, runtime mode, capability declarations, commerce corridors, companion bindings, auth predicates, notification readiness, and rebuild requirements.
2. Output has a stable machine-readable shape for CI/support tooling.
3. Human-facing output remains concise and actionable.
4. Inspection semantics preserve route ownership and fail-closed support truth.

**Plans**: 2 plans
Plans:
**Wave 1**

- [x] 49-01-PLAN.md — create the typed `Crosswake.OperatorInspection` contract, route-authoritative schema, and stable JSON surface with focused ExUnit coverage

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 49-02-PLAN.md — add the concise human formatter and `mix crosswake.inspect` CLI without widening into doctor publish checks or deferred provider/auth/notification claims

**Phase 50: Doctor Publish and Readiness Checks**

Goal: Extend doctor into release/support readiness with actionable findings.

Requirements: DIAG-01, DIAG-02

Success criteria:
1. `mix crosswake.doctor --check-publish` reports Hex metadata, changelog, docs/support parity, proof posture, and verification-required surfaces.
2. Companion dependency health, provider-adapter readiness, notification-token readiness, auth/session predicate readiness, and native shell verification gaps have explicit severities and remediations.
3. Findings are machine-readable and human-readable.
4. Missing readiness never silently passes as supported.

**Plans**: 2 plans
Plans:
**Wave 1**

- [x] 50-01-PLAN.md — build the reusable publish-readiness contract and derivation engine from deterministic local project truth plus Phase 49 inspection/support data

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 50-02-PLAN.md — wire `--check-publish` through doctor CLI/report/human/JSON output and lock additive behavior with regression coverage

**Phase 51: Support Matrix and Native Rebuild Truth**

Goal: Make public support truth match the widened v3.6 diagnostic surface.

Requirements: SUPP-01, SUPP-02

Success criteria:
1. Support matrix distinguishes supported, verification-required, advisory, merge-blocking, rebuild-required, and unsupported states.
2. Rebuild requirements are explicit for native, companion, provider, route/manifest, and docs-only changes.
3. Public guidance does not imply StoreKit, Play Billing, full Sigra machinery, Chimeway delivery, or standalone shell packages have shipped.
4. Advisory-to-merge-blocking promotion criteria are visible in docs and runtime diagnostics.

**Plans**: 3 plans
Plans:
**Wave 1**

- [x] 51-01-PLAN.md — extend canonical support truth with typed action classes, promotion rules, and deferred-scope support rows without collapsing the existing split axes

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 51-02-PLAN.md — render the canonical rebuild, promotion, and non-claim contract into support_matrix/install/native_shell/compatibility docs with deterministic guide tests
- [ ] 51-03-PLAN.md — feed canonical rebuild and promotion metadata through operator inspection and publish-readiness runtime surfaces without inventing a second readiness model

**Phase 52: Operator Proof and Docs-Contract Locks**

Goal: Make v3.6 operator truth mechanically durable.

Requirements: PROOF-01, PROOF-02

Success criteria:
1. Hermetic tests lock inspection output and doctor readiness findings.
2. Docs-contract tests keep support matrix, guides, denial vocabulary, and rebuild truth synchronized with live code.
3. CI clearly separates merge-blocking operator proof from advisory native/device/provider checks.
4. Proof failures point to actionable support-truth drift.

**Phase 53: Release Continuity and Closeout Hardening**

Goal: Ensure public release/changelog truth and milestone closeout discipline survive future context clears.

Requirements: REL-01

Success criteria:
1. Changelog/release guidance distinguishes unreleased support claims from published Hex truth.
2. v3.6 closeout verifies roadmap parity, requirements traceability, state frontmatter, verification reports, validation ledgers, and thread/seed status.
3. Follow-on milestone candidates remain visible in `PROJECT.md` and `MILESTONE-ARC.md`.
4. `$gsd-discuss-phase 48` is the clear next execution step.

</details>

## Progress

| Phase Range | Milestone | Plans Complete | Status | Completed |
|-------------|-----------|----------------|--------|-----------|
| 1-5 | v1.0 Route-Policy Substrate | — | Complete | 2026-05-17 |
| 6-10 | v2.0 Adopter Stress Profiles | 16/16 | Complete | 2026-05-19 |
| 11-14 | v3.0 Capability Contract And Packaging | 12/12 | Complete | 2026-05-20 |
| 15-18 | v3.1 Native Capabilities and Bridge Expansion | 16/16 | Complete | 2026-05-27 |
| 19-25 | v3.2 Commerce And Entitlement Seams | 18/18 | Complete | 2026-05-27 |
| 26-32 | v3.3 Release Readiness | 11/11 | Complete | 2026-05-29 |
| 33-37 | v3.4 Commerce Archetype Proof | 8/8 | Complete | 2026-05-29 |
| 38-47 | v3.5 First-Party Companions | 22/22 | Complete | 2026-05-31 |
| 48-53 | v3.6 Operator Truth and Production Diagnostics | 7/10 | Active | — |

## Next

Start execution with `$gsd-execute-phase 51`.
