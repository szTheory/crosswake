# Roadmap: Crosswake

## Milestones

- ✅ **v1.0 Route-Policy Substrate** — Phases 1-5 shipped on 2026-05-17.
- ✅ **v2.0 Adopter Stress Profiles** — Phases 6-10 shipped on 2026-05-19. Full archive: [.planning/milestones/v2.0-ROADMAP.md](/Users/jon/projects/crosswake/.planning/milestones/v2.0-ROADMAP.md)
- ✅ **v3.0 Capability Contract And Packaging** — Phases 11-14 shipped on 2026-05-20. Full archive: [.planning/milestones/v3.0-ROADMAP.md](/Users/jon/projects/crosswake/.planning/milestones/v3.0-ROADMAP.md)
- ✅ **v3.1 Native Capabilities and Bridge Expansion** — Phases 15-18 shipped on 2026-05-27. Full archive: [.planning/milestones/v3.1-ROADMAP.md](/Users/jon/projects/crosswake/.planning/milestones/v3.1-ROADMAP.md)
- ◆ **v3.2 Commerce And Entitlement Seams** — Phases 19-22 active.

## Current Milestone: v3.2 Commerce And Entitlement Seams

**Goal:** Make Crosswake's commerce seam usable and provable for Phoenix teams while keeping entitlement truth backend-owned and native/storefront provider work outside core.

## Phases

| Phase | Name | Goal | Requirements | Success Criteria |
|-------|------|------|--------------|------------------|
| 19 | Commerce Route Corridors | Declare and validate commerce-sensitive route ownership and support truth. | COMM-04, COMM-05, COMM-06 | 4 |
| 20 | Entitlement Lifecycle Semantics | Expand normalized contract semantics for entitlement authority, access, freshness, and evidence. | ENTL-01, ENTL-02, ENTL-03 | 4 |
| 21 | Reconciliation Example | Provide a minimal Phoenix-owned reconciliation inbox and entitlement projection example. | RECN-01, RECN-02, RECN-03 | 4 |
| 22 | Commerce Support, Review, And Proof | Publish doctor/support/reviewer guidance and split merge-blocking from advisory proof. | SUPP-04, SUPP-05, SUPP-06 | 5 |

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

**Goal:** Publish doctor/support/reviewer guidance and split merge-blocking from advisory proof.

**Requirements:** SUPP-04, SUPP-05, SUPP-06

**Success criteria:**
1. Doctor and support-matrix output identify missing commerce prerequisites, unsupported native corridors, stale snapshots, and native rebuild requirements.
2. Public commerce docs include reviewer/storefront sandbox setup, restore expectations, fallback behavior, and rough-edge guidance.
3. Merge-blocking tests cover hermetic commerce contracts, route denials, support truth, and docs integrity.
4. StoreKit/Play Billing simulator, device, or storefront checks are documented as advisory until adapter milestones ship.
5. Requirements traceability shows all v3.2 requirements mapped and no provider adapter implementation included in current scope.

## Coverage

- v3.2 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0

## Current Position

Phase 19 is complete (3 of 3 plans complete). Phase 20 is next.

Start with:

`$gsd-execute-phase 20`
