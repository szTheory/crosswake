# Phase 14: Proof, Doctor, And Support Truth Context

**Goal**: Crosswake upgrades operator-facing proof and support surfaces so future capability and commerce claims stay honest before breadth lands.
**Depends on**: Phase 13
**Plans**: 3 plans
**Requirements**: `SUPP-01`, `SUPP-02`, `SUPP-03`

### Plans:
- 14-01: Extend doctor and support-matrix outputs for capability-family, package-boundary, and commerce-seam prerequisites and denials.
- 14-02: Split merge-blocking proof from advisory environment-sensitive proof for future capability and commerce claims.
- 14-03: Publish rebuild guidance, fallback behavior, reviewer/storefront notes, and rough-edge documentation for the new contract surfaces.

### Success criteria:
1. Doctor and support-matrix surfaces expose explicit denial behavior and prerequisites for capability, companion, and commerce claims.
2. Maintainers can distinguish merge-blocking proof from advisory proof before widening public support claims.
3. Public guides explain rebuild expectations, fallback behavior, and rough edges before future feature breadth is declared supported.

### Current Implementation State:
- `lib/crosswake/support_matrix/support_matrix.ex` currently contains `capability_families`, `package_surfaces`, `release_boundaries`, and `change_classes`.
- `lib/crosswake/support_matrix/renderer.ex` handles writing these fields to the markdown output.
- `lib/crosswake/doctor/doctor.ex` currently exposes some `support` logic and a `release_policy` snapshot.
- `lib/crosswake/doctor/formatter.ex` formats the doctor report but lacks display of capability-families, package-surfaces, or change classes.
