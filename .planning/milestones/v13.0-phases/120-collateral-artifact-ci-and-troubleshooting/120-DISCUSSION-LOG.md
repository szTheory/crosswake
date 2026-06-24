# Phase 120: Collateral, Artifact CI, And Troubleshooting - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-19T22:10:00Z
**Phase:** 120-Collateral, Artifact CI, And Troubleshooting
**Areas discussed:** Browser route-tour proof shape, Evidence bundle contract, Advisory native collateral, Troubleshooting doc shape

---

## Browser Route-Tour Proof Shape

| Option | Description | Selected |
|--------|-------------|----------|
| One required `route_tour.spec.ts` with all semantic assertions and collateral capture | Clear COLL-01 ownership, keeps existing offline proof intact, one CI artifact story, easiest for docs to link; risk is a long spec and oversized artifact bundle. | |
| Layer route-tour assertions into existing `offline_sync.spec.ts` | Reuses existing harness, but blurs offline correctness with broader route-owner collateral and makes honesty guards harder to reason about. | |
| Split required semantic proof from collateral capture lane | Semantic assertions gate correctness while screenshots/manifests are evidence packaging; more files but best support-truth separation. | ✓ |
| Advisory-only route tour with screenshots/videos | Fast visual collateral, but fails COLL-01 because route-tour proof must be required and semantic. | |

**User's choice:** User requested all areas be discussed through subagent research and delegated final recommendations to Claude.
**Notes:** Recommendation: required browser route-tour semantic assertions plus separate evidence/collateral packaging. Suggested routes: `/library`, `/bridge-proof`, `/offline`, and `/native/claims/:id/capture` or an equivalent route-unavailable fixture. Keep native simulator/emulator capture advisory.

---

## Evidence Bundle Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Run-level evidence bundle manifest per CI run | One authoritative index and simple artifact UX, but can be too coarse without route-level entries. | |
| Per-route manifests | Strong route traceability, but fragmented and duplicative. | |
| Committed curated screenshot set plus manifest | Durable docs collateral, but screenshots can go stale and be mistaken for correctness proof. | |
| CI-only rich artifacts | Good for debugging and avoids repo bloat, but public links expire and do not provide durable collateral. | |
| Hybrid contract | Run-level manifest with route entries, optional curated docs screenshots, and CI-only rich artifacts with bounded retention. | ✓ |

**User's choice:** User requested research-backed recommendation.
**Notes:** Recommendation: one run-level `evidence-manifest.json` with route entries and strict ExUnit validation. Required artifacts fail closed; optional native advisory artifacts can be unavailable only with explicit manifest status and reason.

---

## Advisory Native Collateral

| Option | Description | Selected |
|--------|-------------|----------|
| Best-effort CI capture, non-blocking artifacts | Fresh per-commit evidence but runner/tooling drift can be flaky and expensive. | |
| Maintainer-run/manual captures with checked-in manifests and curated assets | Stable docs collateral and low CI flake exposure, but can go stale. | |
| Skipped/unavailable capture hooks with explicit manifest rows | Honest when native tooling is absent, but less visually satisfying. | |
| Managed mobile test service or self-hosted runner later | Stronger environment control, but wider operational surface than v13 scope. | |
| Hybrid advisory posture | Browser proof is merge-blocking; native capture is best-effort advisory; manifest records success, skip, or unavailable state. | ✓ |

**User's choice:** User requested research-backed recommendation.
**Notes:** Recommendation: native simulator/emulator collateral remains advisory and non-blocking. Captions must separate `checked-in public-coordinate proof` from `simulator evidence`/`emulator evidence`, and must not imply physical-device or provider authority.

---

## Troubleshooting Doc Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Route-owner-first guide with symptom index and diagnostic appendix | Preserves Crosswake thesis while still helping users find copied error strings quickly. | ✓ |
| Symptom-first cookbook | Fast for search, but can flatten Crosswake into generic error recipes and obscure ownership. | |
| Diagnostic-surface-first generated reference | Strong drift resistance, but poor first-read DX and too much internal machinery upfront. | |

**User's choice:** User requested research-backed recommendation.
**Notes:** Recommendation: add `guides/troubleshooting.md` organized by route owner with a top symptom index. Each entry should state what you see, who owns the fix, what to run, what to change, and what the fix does not prove.

---

## Claude's Discretion

- User delegated final coherent recommendation set after requesting all gray areas be considered with subagent research, project prompt context, ecosystem lessons, JTBD, UX/DX, and architecture lenses.
- Exact implementation names, helper names, manifest module names, and workflow layout are left to downstream planning as long as the locked decisions in CONTEXT.md are preserved.

## Deferred Ideas

- Managed native test services or self-hosted native runners.
- Promotion of simulator/emulator/device evidence to merge-blocking support.
- Physical-device, camera, media-upload, provider-authority, or app-store claims.
- DASH-01 and NTV-01.
