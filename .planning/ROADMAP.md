# Roadmap: Crosswake

## Milestones

- ✅ **v1.0 Route-Policy Substrate** — Phases 1-5 shipped on 2026-05-17.
- ✅ **v2.0 Adopter Stress Profiles** — Phases 6-10 shipped on 2026-05-19. Full archive: [.planning/milestones/v2.0-ROADMAP.md](/Users/jon/projects/crosswake/.planning/milestones/v2.0-ROADMAP.md)
- ◆ **v3.0 Capability Contract And Packaging** — Phases 11-14 initialized on 2026-05-19.

## Active Milestone

# Milestone v3.0: Capability Contract And Packaging

**Status:** ◆ ACTIVE
**Phases:** 11-14
**Total Plans:** 12 planned

## Overview

Crosswake uses `v3.0` to lock the rules for capability breadth before shipping that breadth. The milestone formalizes how capability families are classified, where package boundaries live, how Phoenix-facing commerce seams stay backend-truthful, and how doctor/support/proof surfaces must speak honestly about prerequisites, denials, rebuilds, and rough edges.

## Phases

### Phase 11: Capability Taxonomy And Contract Rubric

**Goal**: Crosswake defines the capability-family taxonomy, route-owner decision rules, and manifest/support-matrix metadata needed before future capability delivery.
**Depends on**: Phase 10
**Plans**: 3 plans
**Requirements**: `CAPA-01`, `CAPA-02`, `CAPA-03`

Plans:

- [x] 11-01: Publish the capability-family inventory, route-owner rubric, and bounded-bridge versus native-screen decision rules.
- [x] 11-02: Extend manifest and support-matrix truth so capability-family metadata and support posture can be declared explicitly.
- [x] 11-03: Document example classifications for first-target capability families and explicit defer rules for out-of-thesis surfaces.

**Success criteria:**
1. Phoenix teams can place candidate capability families into bounded bridge, native screen, or deferred buckets using one published rubric.
2. Manifest and support documentation can represent capability-family metadata without granting broader runtime authority.
3. Public guidance explains what belongs in `core`, what needs a `companion`, and what stays deferred.

### Phase 12: Packaging Ledger And Release Boundaries

**Goal**: Crosswake formalizes `core` versus `companion` versus docs-only boundaries and the release choreography that follows from those choices.
**Depends on**: Phase 11
**Plans**: 3 plans
**Requirements**: `PKG-01`, `PKG-02`, `PKG-03`

Plans:

- [x] 12-01: Publish the packaging ledger covering `core`, `companion`, `example/docs-only`, and deferred surfaces.
- [x] 12-02: Define companion-ready release/versioning policy for manifest, shell, and package compatibility changes.
- [x] 12-03: Publish rebuild, compatibility-bump, and docs-only change rules for future capability and companion work.

**Success criteria:**
1. Adopters can tell which major surfaces belong in `core` and which require first-party companions or examples.
2. Maintainers have one explicit release/versioning policy for future multi-package work.
3. Capability and companion changes clearly state whether they require native rebuilds, compatibility bumps, or docs-only publication.

### Phase 13: Commerce And Entitlement Contract

**Goal**: Crosswake defines a Phoenix-facing commerce seam that preserves backend-owned entitlement truth and keeps provider-specific logic outside core.
**Depends on**: Phase 12
**Plans**: 3 plans
**Requirements**: `COMM-01`, `COMM-02`, `COMM-03`

Plans:

- [ ] 13-01: Define the normalized commerce vocabulary for paywall entry, purchase intent, restore intent, entitlement snapshot, and reconciliation hooks.
- [ ] 13-02: Document backend-truth entitlement flow, reconciliation rules, and explicit non-goals around device-local authority.
- [ ] 13-03: Classify core-versus-companion commerce boundaries and identify which storefront-sensitive flows require explicit native screens or guidance.

**Success criteria:**
1. Phoenix teams can model purchase-related flows through one Crosswake contract without treating device events as final entitlement truth.
2. Commerce docs separate core semantics from provider- or storefront-specific implementation details.
3. Policy-sensitive commerce flows clearly declare whether they require a native screen, a companion adapter, or future milestone work.

### Phase 14: Proof, Doctor, And Support Truth

**Goal**: Crosswake upgrades operator-facing proof and support surfaces so future capability and commerce claims stay honest before breadth lands.
**Depends on**: Phase 13
**Plans**: 3 plans
**Requirements**: `SUPP-01`, `SUPP-02`, `SUPP-03`

Plans:

- [ ] 14-01: Extend doctor and support-matrix outputs for capability-family, package-boundary, and commerce-seam prerequisites and denials.
- [ ] 14-02: Split merge-blocking proof from advisory environment-sensitive proof for future capability and commerce claims.
- [ ] 14-03: Publish rebuild guidance, fallback behavior, reviewer/storefront notes, and rough-edge documentation for the new contract surfaces.

**Success criteria:**
1. Doctor and support-matrix surfaces expose explicit denial behavior and prerequisites for capability, companion, and commerce claims.
2. Maintainers can distinguish merge-blocking proof from advisory proof before widening public support claims.
3. Public guides explain rebuild expectations, fallback behavior, and rough edges before future feature breadth is declared supported.

---

## Milestone Summary

**Requirements mapped:** 12/12 complete in roadmap coverage terms
**Coverage:** All active milestone requirements mapped exactly once ✓

**Key sequencing decisions:**

- Lock taxonomy before package boundaries so classification rules exist before companion policy.
- Lock package and rebuild truth before commerce seam work so policy-sensitive surfaces inherit explicit release constraints.
- Finish support and proof posture last so it can absorb the final capability, packaging, and commerce vocabulary without contradiction.

**Issues intentionally deferred:**

- Shipping the first broad capability catalog.
- Store-specific billing or entitlement adapters.
- Generic plugin-bus behavior, high-frequency bridges, and desktop packaging work.

---

## ▶ Next Up

**Phase 13: Commerce And Entitlement Contract** — define a Phoenix-facing commerce seam that preserves backend-owned entitlement truth and keeps provider-specific logic outside core.

`$gsd-discuss-phase 13`

Also available:
- `$gsd-plan-phase 13` — skip discussion and plan directly

---
