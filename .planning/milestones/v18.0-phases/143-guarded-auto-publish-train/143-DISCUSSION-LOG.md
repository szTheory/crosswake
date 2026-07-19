# Phase 143: Guarded Auto-Publish Train - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-07-07
**Phase:** 143-Guarded Auto-Publish Train
**Areas discussed:** Publish Authority Boundary, Already-Live Retry Behavior, Recovery Surface, Package Eligibility And Floors

---

## Publish Authority Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Fully hands-free after Release PR merge | Release PR merge is the approval boundary; CI publishes released artifacts from Release Please outputs. | yes |
| Manual dispatch for publish jobs | Maintainer manually triggers publish jobs after Release Please creates tags/releases. | |
| Hybrid by package class | Some package classes publish automatically while others require manual dispatch. | |

**User's choice:** The user selected all gray areas and asked for researched, one-shot recommendations rather than iterative questioning.

**Notes:** Subagent research recommended the fully hands-free steady state. Manual dispatch remains only for exact-ref recovery and fire-drills. This best satisfies AUTO-01 while preserving the existing human gate at Release PR merge.

---

## Already-Live Retry Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Already-live exact version = success and proof continues | If the expected package/version is already present, report it, skip publish, and continue proof. | yes |
| Already-live = warning/stop | Stop for investigation whenever the registry already has the version. | |
| Already-live success only in manual recovery | Automatic publish remains strict; manual recovery gets idempotent already-live behavior. | |

**User's choice:** The user asked Claude to choose after considering tradeoffs.

**Notes:** Subagent and local research recommended exact already-live success only when identity is proven. If identity cannot be tied to the expected package/version/ref, the workflow should fail closed with an explicit next action.

---

## Recovery Surface

| Option | Description | Selected |
|--------|-------------|----------|
| Broaden `hex-publish.yml` to component-aware root + companion recovery | One exact-ref manual recovery surface for all Hex packages. | yes |
| Separate recovery workflows per package class | Different workflows for Hex/native/package families. | |
| No new recovery workflow | Rely on GitHub rerun and docs. | |

**User's choice:** The user asked for the coherent recommendation.

**Notes:** Research recommended broadening only Hex recovery in Phase 143. Native mirror/Maven recovery and iOS backfill stay Phase 145. Recovery should accept package/ref/version, reject branch names, resolve the checked-out SHA, preflight Hex, and use the same idempotency policy as the automatic train.

---

## Package Eligibility And Floors

| Option | Description | Selected |
|--------|-------------|----------|
| Train covers all configured packages with honest current floors | Every configured Release Please component has train coverage; floors stay package-specific. | yes |
| Train covers only core/native + sigra/chimeway/threadline | Exclude older `rulestead`/`rindle` for now. | |
| Bump all companion floors to `~> 0.2` | Uniform compatibility floor for every companion. | |

**User's choice:** The user asked for the coherent recommendation.

**Notes:** Research recommended all configured packages with honest mixed floors. `rulestead`/`rindle` should not be artificially bumped from `~> 0.1` to `~> 0.2`; `sigra`/`chimeway`/`threadline` keep `~> 0.2`. Mixed floors should be surfaced in docs/status output rather than hidden.

---

## Research Lenses Used

- GSD advisor subagent: publish authority boundary.
- GSD advisor subagent: already-live/idempotency semantics.
- GSD advisor subagent: recovery surface.
- GSD advisor subagent: package eligibility/floors.
- Local official-doc check: GitHub Actions workflow syntax, concurrency, expressions, contexts.
- Local official-doc check: Release Please outputs.
- Local official-doc check: Hex publish/FAQ behavior.
- Local official-doc check: Maven Central immutability.
- Local ecosystem check: Lerna, Nx, and Changesets monorepo release patterns.
- Local prompt synthesis: Crosswake OSS DNA, project brief, integrations/companions, research synthesis, release-specific prompt excerpts, and current Brand Spec.

## Claude's Discretion

- Exact helper script names, exact workflow input names, YAML factoring, and ExUnit fixture shape are left to the planner/executor.
- The policy choices in `143-CONTEXT.md` should be treated as locked unless live official registry or GitHub behavior contradicts them.

## Deferred Ideas

- Native mirror/Maven recovery and iOS `v0.2.0` backfill: Phase 145.
- Clean-room proof exactness: Phase 144.
- Release status DX completion: Phase 146.
- Graphical dashboard/operator UI: DASH-01, out of scope for Phase 143.
