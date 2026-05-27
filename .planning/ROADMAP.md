# Roadmap: Crosswake

## Milestones

- ✅ **v1.0 Route-Policy Substrate** — Phases 1-5 shipped on 2026-05-17.
- ✅ **v2.0 Adopter Stress Profiles** — Phases 6-10 shipped on 2026-05-19. Full archive: [.planning/milestones/v2.0-ROADMAP.md](/Users/jon/projects/crosswake/.planning/milestones/v2.0-ROADMAP.md)
- ✅ **v3.0 Capability Contract And Packaging** — Phases 11-14 shipped on 2026-05-20. Full archive: [.planning/milestones/v3.0-ROADMAP.md](/Users/jon/projects/crosswake/.planning/milestones/v3.0-ROADMAP.md)
- ✅ **v3.1 Native Capabilities and Bridge Expansion** — Phases 15-18 shipped on 2026-05-27. Full archive: [.planning/milestones/v3.1-ROADMAP.md](/Users/jon/projects/crosswake/.planning/milestones/v3.1-ROADMAP.md)
- ◆ **v3.2 Commerce And Entitlement Seams** — Phases 19-24 active.

## Current Milestone: v3.2 Commerce And Entitlement Seams

**Goal:** Make Crosswake's commerce seam usable and provable for Phoenix teams while keeping entitlement truth backend-owned and native/storefront provider work outside core.

## Phases

| Phase | Name | Goal | Requirements | Success Criteria |
|-------|------|------|--------------|------------------|
| 19 | Commerce Route Corridors | 3/3 | Complete    | 2026-05-27 |
| 20 | Entitlement Lifecycle Semantics | 4/4 | Complete    | 2026-05-27 |
| 21 | Reconciliation Example | 2/2 | Complete    | 2026-05-27 |
| 22 | Commerce Support, Review, And Proof (decomposed) | Decomposed by milestone audit into focused closure phases before execution. | Decomposed into Phases 23-24 | Split |
| 23 | Commerce Support And Proof Closure | 4/4 | Complete    | 2026-05-27 |
| 24 | Reconciliation Traceability Hardening | 1/3 | In Progress|  |

## Phase Details

### Phase 19: Commerce Route Corridors

**Goal:** Declare and validate commerce-sensitive route ownership and support truth.

**Requirements:** COMM-04, COMM-05, COMM-06

**Plan progress:** 3/3 complete (`19-01`, `19-02`, and `19-03` complete)

**Success criteria:**

1. Route policy can express Phoenix-owned paywall/account surfaces separately from native-screen or companion storefront loops.
2. Manifest output exposes commerce corridor truth without provider-specific vocabulary.
3. Unsupported or undeclared commerce corridors fail closed with explicit denial/fallback reasons.
4. Public docs explain when commerce remains Phoenix-owned versus when native-screen or companion posture is required.

### Phase 20: Entitlement Lifecycle Semantics

**Goal:** Expand normalized contract semantics for entitlement authority, access, freshness, and evidence.

**Requirements:** ENTL-01, ENTL-02, ENTL-03

**Success criteria:**

1. Entitlement snapshots separate authority state, access state, reconciliation state, freshness, effective dates, and evidence metadata.
2. Pending, restore, verification, grace, billing retry, canceled scheduled end, revoked/refunded, expired, and stale states are represented through Crosswake-owned vocabulary.
3. Tests prove device, storefront, webhook, and support evidence cannot directly grant core entitlement authority.
4. Provider-specific StoreKit/Play Billing states remain mapped at the boundary instead of leaking into route policy or core structs.

### Phase 21: Reconciliation Example

**Goal:** Provide a minimal Phoenix-owned reconciliation inbox and entitlement projection example.

**Requirements:** RECN-01, RECN-02, RECN-03

**Success criteria:**

1. Example host or guide shows a minimal reconciliation inbox for purchase, restore, webhook, and support evidence.
2. Idempotency guidance uses provider-aware identity rather than transient device correlation IDs.
3. Example projection produces one authoritative entitlement snapshot with stale, pending, denied, and granted states.
4. The example remains example/docs-only or companion-ready and does not impose a persistence or job framework on core.

### Phase 22: Commerce Support, Review, And Proof

**Goal:** Original closure phase for support/proof guidance.

**Requirements:** Decomposed into Phases 23-24 before execution.

**Status:** Superseded by audit-driven phase split to reduce execution risk and isolate traceability hardening.

**Success criteria:**

1. Scope split accepted: runtime/support closure moved to Phase 23.
2. Traceability hardening and metadata normalization moved to Phase 24.
3. Milestone closure continues with explicit merge-blocking versus advisory proof posture.

### Phase 23: Commerce Support And Proof Closure

**Goal:** Close blocking support/proof gaps and publish merge-blocking versus advisory commerce truth.

**Requirements:** SUPP-04, SUPP-05, SUPP-06

**Plan progress:** 0/4 complete

**Plans:**

4/4 plans complete
|------|------|------|---------|--------------|--------|
| 23-01 | Doctor Commerce Summary And Stale-Snapshot Diagnostics | 1 | — | SUPP-04 | Pending |
| 23-02 | Support Matrix Enrichment And Guide Synchronization | 1 | — | SUPP-04, SUPP-05 | Pending |
| 23-03 | Reviewer/Storefront Guidance And Non-Claims | 2 | 23-01, 23-02 | SUPP-05 | Pending |
| 23-04 | Merge-Blocking vs Advisory Proof Lanes | 2 | 23-01, 23-02 | SUPP-06 | Pending |

**Success criteria:**

1. Doctor and support-matrix output identify missing commerce prerequisites, unsupported native corridors, stale snapshots, and native rebuild requirements.
2. Public commerce docs include reviewer/storefront sandbox setup, restore expectations, fallback behavior, and rough-edge guidance.
3. Merge-blocking tests cover hermetic commerce contracts, route denials, support truth, and docs integrity.
4. StoreKit/Play Billing simulator, device, or storefront checks are documented as advisory until adapter milestones ship.

### Phase 24: Reconciliation Traceability Hardening

**Goal:** Normalize reconciliation traceability artifacts so audit automation reflects verified behavior without manual interpretation.

**Requirements:** RECN-01, RECN-02, RECN-03

**Plans:** 1/3 plans executed

Plans:
**Wave 1**

- [x] 24-01-PLAN.md — Phase 21 SUMMARY frontmatter key rename + REQUIREMENTS.md bullets/traceability sync

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 24-02-PLAN.md — ExUnit parity test (test/crosswake/planning/summary_frontmatter_test.exs) + phase23-proof.yml CI merge-gate amendment

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 24-03-PLAN.md — Append-only re-audit section + reaudits[] frontmatter entry in v3.2-MILESTONE-AUDIT.md

**Success criteria:**

1. Phase summaries use canonical `requirements-completed` frontmatter for reconciliation requirements.
2. Reconciliation requirement traceability status is synchronized across summary, verification, and requirements artifacts.
3. Re-audit evidence for RECN requirements reports satisfied (not partial) due to artifact-shape consistency.

## Coverage

- v3.2 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0

## Current Position

Phase 21 is complete (2 of 2 plans complete). Phase 23 is planned (4 plans, 2 waves). Phase 24 is planned (3 plans, 3 waves).

Phase 24 waves:
Wave 1: `24-01` (Phase 21 SUMMARY rename + REQUIREMENTS.md sync — artifact-shape gap closure).
Wave 2 (depends on 24-01): `24-02` (ExUnit parity test + phase23-proof.yml CI merge-gate amendment).
Wave 3 (depends on 24-01 and 24-02): `24-03` (append-only re-audit to v3.2-MILESTONE-AUDIT.md).

Start with:

`$gsd-execute-phase 23`
