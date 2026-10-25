# Phase 181: Core Host-Command Seam - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-14
**Phase:** 181-core-host-command-seam
**Areas discussed:** How routes declare commands, Per-route authority at runtime, Offline-island admission, Versioning and old hosts

**User's instruction:** The user selected all four areas and pasted their standard fan-out instructions. Each decision was to be researched through every relevant lens with subagents, using primary sources and the `prompts/` corpus, with an adversarial pass. The user asked for a coherent set of one-shot recommendations that are followed automatically, and stated a preference for copy-and-paste over adding dependencies. Advisor mode used the minimal_decisive calibration tier.

**Method:** Five parallel research lenses (four areas plus a cross-cutting host-author DX and `prompts/` corpus lens), then an orchestrator adversarial pass against candidate source at `96e5a63`.

---

## How routes declare commands

| Option | Description | Selected |
|--------|-------------|----------|
| Grammar-only | Accept any well-formed `host.<ns>.<verb>` | |
| Central versioned registry on `use Crosswake.Router`, routes reference by name in `capabilities:` | Typos are compile errors and the version has one source | ✓ |
| Inline per-route `host_commands:` (DX lens) | Declared next to the route, but has no single version source | |
| App config | Compile-env coupling, far from the routes | |

**Notes:** The DX lens and the gate/handoff contract both pointed at keeping route references in `capabilities:`. The adversarial pass rejected the proposal to limit `host.*` to islands, because LiveView sessions already use `host.*`.

## Per-route authority at runtime

| Option | Description | Selected |
|--------|-------------|----------|
| Entry-only activation projection | Navigation reuses the baseline, so commands leak or go missing | |
| Manifest per-route declaration ∩ host-registered ∩ version-compatible, resolved on each navigation | Single authority | ✓ |
| Per-route map in the activation fixture | Second authority that can drift | |

**Notes:** The adversarial pass replaced the proposed `capabilities` object shape with a separate additive `host_commands` field, so older shells can still decode the manifest.

## Offline-island admission

| Option | Description | Selected |
|--------|-------------|----------|
| Widen the guard and reuse `.liveView` | Hides ownership | |
| Explicit `.offlineIsland` presentation plus `WebRuntime` on the shared session, closed allowlist | Ownership stays explicit | ✓ |

**Notes:** The DX lens proposed a shell admission config switch. It was not adopted because it duplicates the route's own runtime declaration. A proposal to deny transfers on islands was deferred.

## Versioning and old hosts

| Option | Description | Selected |
|--------|-------------|----------|
| Additive manifest 1.2.0, bridge stays 1.1.0 | SemVer minor | ✓ |
| Bridge protocol bump | Would touch frozen Android vectors | |
| Major / both | Overstates the break | |

**Notes:** Adversarial finding: the existing native-runtime "floor" compares two generated data files and never the compiled binary. A compiled-in constant, a fail-closed generation gate and a documented residual were added. New wire reason codes were rejected because the reason vocabulary is pinned. Requirements SEAM-01..06 were added.

## Claude's Discretion

Naming, where the constant lives, how the package version is resolved, did-you-mean thresholds, the diagnostic record format, test layout and plan split.

## Deferred Ideas

- A generated Swift command constants file and a static Swift scan.
- Island-specific restrictions such as denying transfers.
- Island offline cold start and durability guarantees.
- Android support.
- Phase 180 demonstration work.
- Release, merge and publication.
