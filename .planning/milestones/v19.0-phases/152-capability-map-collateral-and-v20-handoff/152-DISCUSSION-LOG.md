# Phase 152: Capability Map, Collateral, and v20 Handoff - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-07-12
**Phase:** 152-Capability Map, Collateral, and v20 Handoff
**Areas discussed:** Capability map shape, v20 Native Controls Pack 1, proof and collateral, support-truth guardrails, UI/UX and brand surface

---

## Capability Map Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Prose-only capability map | Fast editorial guide built from the existing support matrix and showcase notes. | |
| Typed v19 capability-map projection plus rendered guide | Add a small typed projection that normalizes support matrix, catalog, evidence, package ownership, proof posture, and v20 implications. | yes |
| Full generated dashboard or operator UI | Build a larger browsable UI for capability status, proof, and v20 package planning. | |

**User's choice:** Discuss and consider all; provide the best one-shot recommendation.
**Notes:** Subagent research recommended the typed projection plus rendered guide. It matches Phoenix context/module idioms and the repo's existing support-matrix renderer/tests without creating a parallel truth source or premature dashboard.

---

## v20 Native Controls Pack 1

| Option | Description | Selected |
|--------|-------------|----------|
| Ship capture/scanner/media/native storage first | Choose the highest-pressure Fieldserv device capabilities for v20 Pack 1. | |
| Bounded low-frequency route-local controls | Choose alert/confirm, menus/action buttons, haptics, share, and possibly toast/review prompt, with strict support truth. | yes |
| Include permissions/notifications as production features | Treat permission status and notification token work as full v20 features. | |
| Reopen the whole native roadmap | Use Phase 152 to redesign all future native companion packs. | |

**User's choice:** Discuss and consider all; provide the best one-shot recommendation.
**Notes:** Subagent research recommended a split posture. Bounded controls are the v20 Pack 1 default. `permissions.status` and `notification_token` can be evidence/provider snapshots only. Capture, scanner, document scan, media upload, commerce providers, native storage, and sync helpers move to named later packs.

---

## Proof And Collateral

| Option | Description | Selected |
|--------|-------------|----------|
| Screenshot-first collateral | Treat route screenshots as the main proof and showcase artifact. | |
| Semantic route-tour proof plus collateral | Keep Playwright assertions and evidence manifests as proof; screenshots are labeled collateral after assertions pass. | yes |
| Planning-only summary | Write a handoff brief without public docs, evidence manifest updates, or collateral updates. | |

**User's choice:** Discuss and consider all; provide the best one-shot recommendation.
**Notes:** Subagent research recommended a cohesive evidence-backed v19 handoff: capability map, v20 brief, docs links, generalized route-tour manifest, and optional labeled screenshots. Screenshot output must not claim device support, production camera/scanner/media upload, live StoreKit/Play Billing/RevenueCat support, generic sync, native storage, or backend authority.

---

## Support-Truth Guardrails

| Option | Description | Selected |
|--------|-------------|----------|
| Lightweight prose/docs review only | Low friction but subjective and drift-prone. | |
| Structural tests for labels and forbidden phrases | Fast safety net for broad overclaim categories. | |
| Canonical typed support/capability data plus renderer tests and narrow forbidden-claim scanner | Strong drift prevention while staying aligned with existing support-matrix patterns. | yes |
| Full generated support-matrix/capability-map truth with fail-closed CI | Maximum consistency but too heavy for v19 closeout. | |

**User's choice:** Discuss and consider all; provide the best one-shot recommendation.
**Notes:** Subagent research recommended typed canonical data with drift tests as the default and a narrow phrase/category scanner as the floor. Merge-blocking categories include broad native/plugin claims, offline/local-first overclaims, storefront/live-provider authority claims, device/emulator/JVM evidence laundering, and screenshot-as-proof language.

---

## UI/UX And Brand Surface

| Option | Description | Selected |
|--------|-------------|----------|
| Backend-structured docs | Organize docs by implementation modules, tests, and internal package boundaries. | |
| Reader-first capability guide | Organize docs by adopter questions: supported today, example proof, demo pressure, future gap, and v20 next pack. | yes |
| Marketing-style showcase | Emphasize screenshots, narrative, and broad claims over exact support posture. | |

**User's choice:** Discuss and consider all; provide the best one-shot recommendation.
**Notes:** The recommendation is to follow the current `brandbook/BRAND-SPEC.md`: calm technical presentation, route cards, runtime badges, capability chips, explicit support posture, accessible light/dark/system behavior, and status-oriented microcopy. Backend details should appear only where needed to preserve support truth.

---

## Claude's Discretion

- User delegated synthesis and recommendations across all gray areas.
- Recommendation set should be internally coherent and favor Phoenix-first route-policy/runtime-contract architecture.
- Newer `brandbook/BRAND-SPEC.md` overrides older prompt-era brand guidance when they conflict.

## Deferred Ideas

- Capture/scanner/document scan/media upload production capability pack.
- Production StoreKit, Play Billing, RevenueCat, and entitlement provider adapters.
- Native storage and reusable offline sync productization.
- Operator dashboard or support-truth UI.
- Broad native plugin catalog.
