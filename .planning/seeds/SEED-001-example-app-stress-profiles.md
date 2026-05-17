---
id: SEED-001
status: dormant
planted: 2026-05-17
planted_during: "Phase 5 complete — v1 roadmap complete, proof-backed repo posture reconciled"
trigger_when: "Surface during v2 planning, when the project shifts from finishing the v1 substrate to stress-testing it with realistic adopter-shaped example apps."
scope: Medium
---

# SEED-001: Build realistic example-app stress profiles for the main Crosswake adopter types

## Why This Matters

Crosswake now has a proof-backed v1 substrate, but it still needs realistic, minimal example apps that pressure the design the way actual adopters will. The goal is not a pile of demo apps or product templates. The goal is a small set of stress-test exemplars that validate whether the route-policy thesis, manifest contract, shell behavior, offline boundaries, pack lifecycle, transfer seams, diagnostics, and support posture still hold up under credible product shapes.

These examples should stay realistic enough to expose design gaps, but still narrow enough to avoid turning the library into a vendor-heavy application bundle. They should help test the architecture against the strongest early app archetypes already named in the project thesis instead of inventing new framework scope.

## When to Surface

**Trigger:** Surface during v2 planning, when the project is choosing the next milestone after the completed v1 substrate and needs realistic adopter-shaped design pressure.

This seed should be presented during `$gsd-new-milestone` when the milestone scope matches any of these conditions:
- the next milestone is about validating the v1 substrate against real-world adopter profiles
- the roadmap shifts from core contract-building to exemplar apps, proof expansion, or product-shape stress testing
- milestone discussion starts asking which realistic app types Crosswake is actually designed to support well

## Scope Estimate

**Medium** — likely one or two phases to define the profile matrix, choose one minimal-but-realistic app for each profile, and decide which Crosswake surfaces each exemplar must pressure without widening core scope.

## Breadcrumbs

Related code and decisions found in the current codebase:

- [.planning/PROJECT.md](/Users/jon/projects/crosswake/.planning/PROJECT.md:40) — names the strongest early app archetypes as Phoenix-backed SaaS portals, subscription apps with selective native flows, and local-first study/training/content apps
- [.planning/STATE.md](/Users/jon/projects/crosswake/.planning/STATE.md:10) — records that the v1 roadmap is complete and the current focus is reconciling release posture against the proof-backed repo state
- [.planning/STATE.md](/Users/jon/projects/crosswake/.planning/STATE.md:41) — preserves the narrow offline-island posture and the route-local/runtime-boundary decisions that future examples should stress
- [examples/phoenix_host/lib/crosswake_example/router.ex](/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/router.ex:39) — current example host already exercises packs, transfers, and a `:native_screen` route, which can inform future exemplar boundaries
- [guides/offline.md](/Users/jon/projects/crosswake/guides/offline.md:6) — documents the one study-session offline-island story that should influence the local-first exemplar
- [guides/native_shell.md](/Users/jon/projects/crosswake/guides/native_shell.md:92) — documents the single public `:native_screen` media-capture escape hatch, relevant to selective native-flow exemplars
- [guides/packs.md](/Users/jon/projects/crosswake/guides/packs.md:3) — documents required-pack, transfer, and native-capture handoff contract surfaces that future stress-test apps should exercise intentionally
- [script/verify_phase5_example_hosts.sh](/Users/jon/projects/crosswake/script/verify_phase5_example_hosts.sh:1) — shows the current proof posture for checked-in example hosts that future exemplars should likely integrate with rather than bypass

## Notes

Initial profile matrix for future planning:

- **Phoenix-backed SaaS portal**
  Stress mostly server-centric routes, authenticated account/settings/admin flows, billing-portal-style pressure, and narrow native affordances without widening core abstractions.
- **Subscription app with selective native flows**
  Stress mixed ownership where most routes remain shell-hosted/LiveView-backed but a few routes need explicit native ownership, pack gating, transfer seams, or entitlement-adjacent posture.
- **Local-first study/training/content app**
  Stress offline islands, journals/outboxes/replay, cached read-only degradation, content/media packs, and explicit sync/reconciliation vocabulary.

Constraints for the future milestone:

- These should be stress-test exemplars, not product templates.
- Keep them realistic but minimal.
- Do not let billing, identity-provider, or other vendor-heavy flows leak into core abstractions unless a later milestone explicitly chooses that.
- Prefer one app per profile over many overlapping demos.
