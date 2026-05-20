# Phase 6 Patterns

Use these patterns when executing Phase 6 plans. They compress the locked decisions from `06-CONTEXT.md` and the recommendations from `06-RESEARCH.md` into the minimum reusable guidance for this phase.

## Pattern 1: Lean Matrix, Narrative Below

- Publish one matrix only.
- Use the exact columns from D-08:
  `Profile`, `Product shape`, `Primary route classes`, `Runtime ownership expectation`, `Required seams`, `What it pressures`, `Explicit non-goals`.
- Keep support statuses, platform baselines, and exact proof script names out of the matrix per D-09.
- Put representative routes, rough-edge cautions, proof posture summary, and why-it-exists prose in profile sections below the matrix per D-10.

## Pattern 2: Locked Names, Behavioral Framing

- Use the public names verbatim:
  - `Phoenix SaaS Portal`
  - `Selective Native Flow`
  - `Local-First Study Flow`
- Keep the copy route-local and behavioral.
- Do not rename these to market buckets like subscription app, learning app, or template labels.

## Pattern 3: Reuse Existing Crosswake Vocabulary

- Stay inside the existing runtime and seam contract:
  - `:live_view`
  - `:offline_island`
  - `:native_screen`
  - packs
  - transfers
  - bounded bridge capabilities
  - shell activation truth
  - offline replay semantics
- Do not introduce new runtime classes, generic plugin-bus language, or broad wrapper framing.

## Pattern 4: Shared Example-Host Artifact Class

- Treat the checked-in Phoenix host as the primary exemplar artifact class.
- Treat the checked-in iOS and Android hosts as paired proof artifacts of that same shared host.
- Later phases separate profile work by route/module/fixture/proof-lane boundaries inside that shared host.
- Do not split the milestone into three standalone starter apps.

## Pattern 5: Cross-Link To Existing Truth

- `guides/adopter_profiles.md` answers adopter-fit and pressure questions.
- `guides/support_matrix.md` remains the canonical support/status surface.
- `guides/native_shell.md`, `guides/offline.md`, `guides/packs.md`, and `guides/install.md` remain the deeper contract and proof-entry guides.
- Prefer links over duplicated prose when the detail already exists in those guides.

## Pattern 6: Proof Scaffold, Not Exemplar Implementation

- Phase 6 may add doc checks, host-lane contract docs, and verification scaffolding.
- Phase 6 must not implement the Phase 7-10 exemplar routes early.
- New verification should extend the existing checked-in example-host proof posture instead of inventing a separate proof system.

## Guardrails

- Keep each profile tied to one believable job-to-be-done and roughly 4-8 routes.
- Keep one primary failure vocabulary focus per profile.
- Use generic/fake domain data only.
- Avoid billing, entitlement, identity-provider, analytics, push, or vendor-heavy scope unless a later phase explicitly targets that boundary.
