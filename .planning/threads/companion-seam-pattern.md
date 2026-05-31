---
slug: companion-seam-pattern
title: Companion-package seam pattern (Rulestead probe, unblocks v3.5+)
status: completed
created: 2026-05-27
updated: 2026-05-31
resolution: Shipped as v3.5 First-Party Companions (Phases 38-47), including the shared `Crosswake.Companion` behaviour, in-tree companion convention, Rulestead/Rindle/Sigra companion surfaces, fail-closed optional dependency handling, doctor/support truth, and companion guide/proof parity.
---

# Thread: Companion-package seam pattern

## Goal

Define a stable companion-package seam pattern for Crosswake. Use **Rulestead** (rollout safety / feature flags / kill switches / capability gating) as the design probe because `MILESTONE-ARC.md` says rulestead should precede wider risky feature rollout.

Recommended sequencing: ship as **v3.5** after v3.4 (Commerce Archetype Proof). Blocked until v3.3 Release Readiness ships.

## Context

*Created 2026-05-27 during post-v3.2 milestone-next-step assessment.*

Repo-grounded facts:

- Zero first-party companions are shipped today. ARC (`MILESTONE-ARC.md`) lists rulestead, sigra, rindle, chimeway, threadline as design-time anchors.
- The seam pattern is undefined: should a companion live in-tree as `lib/crosswake/companions/rulestead/`, or as a separate `crosswake_rulestead` package on hex.pm?
- Capability registry pattern exists (`lib/crosswake/bridge/registry.ex:186`) and could be extended for companion classification.
- `Crosswake.SupportMatrix` (`lib/crosswake/support_matrix/support_matrix.ex:566`) has a `:companion` classification slot but no companion is registered there.
- Doctor (`lib/crosswake/doctor/doctor.ex:1349`) has 7 phase-gated check categories; would need an 8th for companion state surfaces.

The wedge: until the seam pattern is locked, every subsequent companion (sigra auth, rindle media, chimeway notifications, threadline audit) will retread the same design question. Rulestead first lets us choose the pattern under low-risk pressure (read-only flag lookups + kill-switch checks) before committing it under high-risk pressure (auth, media, payments-adjacent webhooks).

## References

- `/Users/jon/projects/crosswake/prompts/crosswake-integrations-and-companions.md` — companion classification matrix, integration value triage
- `/Users/jon/projects/crosswake/.planning/MILESTONE-ARC.md` § Candidate: v3.3 First-Party Companions — rulestead → sigra → rindle → chimeway → threadline ordering
- `/Users/jon/projects/crosswake/lib/crosswake/bridge/registry.ex` — existing allowlist + classification model that companion seam can mirror
- `/Users/jon/projects/crosswake/lib/crosswake/support_matrix/support_matrix.ex` — companion classification slot already reserved
- `/Users/jon/projects/crosswake/lib/crosswake/doctor/doctor.ex` — needs a companion check category

## Resolution

Closed by v3.5 First-Party Companions:

- Phase 38 defined the shared `Crosswake.Companion` behaviour, `Companion.State`, fail-closed dependency diagnostics, and telemetry span.
- Phases 39-43 proved the Rulestead gating seam with route DSL, manifest binding, runtime fail-closed evaluation, doctor/support truth, hermetic/advisory proof, and guide coverage.
- Phases 44-45 proved the Rindle media seam as the non-flag generalization, including backend-owned reconciliation and pure-Elixir mock media proof.
- Phase 46 added the Sigra contract-only auth surface with route auth predicates and fail-closed `:step_up_required` truth.
- Phase 47 locked the companion arc in `guides/companions.md` with semantic docs-contract parity and aggregate hermetic proof.

Separate-package extraction, Chimeway, full Sigra machinery, and Threadline remain deferred future work, not open questions for this thread.

## Original Next Steps

- Decide packaging: in-tree (`lib/crosswake/companions/`) vs separate hex package (`crosswake_rulestead`). szTheory house-style typically prefers separate companion packages (per `prompts/crosswake-elixir-oss-dna.md`).
- Define companion behaviour contract: what callbacks does a companion implement? (e.g., `route_enabled?/2`, `capability_gated?/2`, `kill_switch_active?/1`, `report_state/0` for doctor).
- Add rulestead-specific implementation: route enable flag, kill switch check, capability allowlist override.
- Add example route in `examples/phoenix_host` that consults rulestead for enable + kill-switch.
- Add doctor check category for companion state surfaces.
- Update `Crosswake.SupportMatrix` to register rulestead with proper classification, proof_class, prerequisite metadata.
- Add merge-blocking proof lane that exercises the rulestead seam end-to-end.
- Document the pattern in `guides/companions.md` (new) so future companions follow it.
- Status: blocked until v3.3 and v3.4 ship.
