# Phase 72: Media/Evidence Workflow Proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-05
**Phase:** 72-media-evidence-workflow-proof
**Areas discussed:** Degradation model, Proof spine, Recovery/authority matrix, Support truth and UI/DX

---

## Degradation Model

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit local queue/outbox fixture | Store queued capture locally with stable idempotency/replay identity, then drain it after simulated recovery. | |
| Failed upload attempt result only | Represent degradation only as a failed upload attempt. | |
| Route-level degraded state | Represent degradation as a route/workflow posture without modeling queued evidence. | |
| Hybrid | Route/workflow-level degraded state plus proof-only local queue fixture plus failed attempt plus backend verification gate. | ✓ |

**User's choice:** Discuss and consider all; produce one-shot recommendations using subagent research, ecosystem lessons, DX/UX, and project vision.
**Notes:** Four subagents researched the gray areas. The degradation research recommended the hybrid because it satisfies the Phase 72 success criteria without widening Crosswake into a generic sync engine. It also maps to idiomatic Phoenix/Ecto production guidance while keeping Phase 72 pure and hermetic.

---

## Proof Spine

| Option | Description | Selected |
|--------|-------------|----------|
| Pure ExUnit over Rindle/example-host modules | Fast hermetic contract/workflow proof with no Endpoint, Repo, PubSub, browser, provider, device, or optional Rindle dependency. | |
| Include `MediaLaneLive` direct render/event proof | Keep adopter-facing state/copy honest without full endpoint overhead. | |
| Endpoint/router LiveView integration | Prove full mounted route behavior through Phoenix test connection and DOM events. | |
| Layered hybrid | Pure ExUnit spine plus compact direct `MediaLaneLive` status/copy proof; endpoint/browser E2E only if a routing bug appears. | ✓ |

**User's choice:** Discuss and consider all; produce coherent recommendations.
**Notes:** The proof-spine research recommended a layered hybrid. Phase 70/71 precedent favors targeted hermetic proof files, while existing Phase 45 `MediaLaneLive` proof makes a small Phoenix-owned status layer cheap and useful. Full endpoint/router proof was deferred because Phase 72's core claim is reconciliation and backend authority, not routing.

---

## Recovery/Authority Matrix

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal happy path + one negative | Prove recovery superficially with very small CI cost. | |
| Broad adversarial authority matrix | Lock evidence/authority boundaries across many edge cases. | |
| Exhaustive storage/network simulation | Simulate realistic upload/storage/network behavior. | |
| Focused matrix | One integrated recovery story plus targeted authority, replay, integrity, payload-completeness, source, and redaction negatives. | ✓ |

**User's choice:** Discuss and consider all; produce coherent recommendations.
**Notes:** The recovery-matrix research recommended the focused matrix. It covers MED-01/MED-02 without duplicating every Rindle unit test or drifting into provider/device/storage simulation. Exact recommended cases were captured in `72-CONTEXT.md`.

---

## Support Truth And UI/DX

| Option | Description | Selected |
|--------|-------------|----------|
| Proof-only, no UI/docs changes | Keep implementation narrowly on tests. | |
| Small status-panel polish in `MediaLaneLive` | Make local capture, failed upload, queued evidence, recovery, backend verification, and availability legible. | |
| Docs/support/operator updates only | Strengthen support truth without touching UI. | |
| Hybrid | Hermetic proof plus compact accessible status polish plus narrow docs/support/operator truth where needed. | ✓ |

**User's choice:** Discuss and consider all; produce coherent recommendations, including UI/UX and microcopy where applicable.
**Notes:** The UI/DX research recommended the hybrid. Existing `MediaLaneLive` lacks explicit recovery/degradation posture, so a compact status panel and microcopy updates are useful, but the phase must not become a production upload dashboard, storage provider integration, or native capture simulator.

---

## The Agent's Discretion

- Exact helper/module names for proof-only queue/degradation fixtures.
- Whether the proof-only queue fixture lives inline in the proof file or in example-host media modules.
- Exact `MediaLaneLive` layout and CSS details within the compact/accessibility/support-safe constraints.
- Exact support/docs/operator files to update, if any, based on implementation needs.
- Exact CI job names, as long as Phase 72 has a named targeted merge-blocking proof lane.

## Deferred Ideas

- Real Rindle adapter, real storage providers, native capture, background transfer, durable Ecto outbox tables, generic sync engine, broad offline/local-first semantics, full endpoint/browser E2E, media dashboard, processing/scanning/CDN work, and Threadline audit trail.
