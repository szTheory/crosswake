# Phase 150: Field-Service Showcase - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-07-11
**Phase:** 150-field-service-showcase
**Areas discussed:** Primary Fieldserv Workflow, Field Data and Persistence, Capture/Scanning/Permission Truth, Offline/Route Ownership Labels

---

## Primary Fieldserv Workflow

| Option | Description | Selected |
|--------|-------------|----------|
| Product-first dispatch -> job -> inspection -> capture handoff -> evidence review | Satisfies FIELD-01 breadth, hides `/native` implementation detail, reuses selective-native/media vocabulary, and shows LiveView vs future native/offline ownership clearly. | yes |
| Capture-first `/native/claims` path | Lowest change surface and already has native-screen/camera route metadata, but too thin for jobs/assets/technicians/inspections. | |
| Offline-inspection island first | Strategically strong future field-service shape, but too large unless a real journal/outbox/media queue ships now. | |
| Diagnostics/capability-first matrix | Excellent support honesty and capability-map input, but not a representative field workflow. | |

**User's choice:** User selected all areas and delegated final recommendations to researched subagents plus Claude discretion.

**Notes:** Advisor research recommended a product-first Fieldserv path: `/fieldserv/jobs` -> `/fieldserv/jobs/:id` -> `/fieldserv/jobs/:id/inspection` -> `/fieldserv/jobs/:id/capture` -> `/fieldserv/jobs/:id/evidence/:id/review`. The old `/native/claims` route should remain a proof or implementation substrate, not the primary user-facing lane.

---

## Field Data and Persistence

| Option | Description | Selected |
|--------|-------------|----------|
| Mostly fixture maps | Fastest deterministic breadth, but weak refresh-proof mutation evidence and easy to overclaim. | |
| Broader Ecto schema persistence | Real relational model, but risks schema sprawl and turning Fieldserv into CRUD. | |
| Hybrid static read-context plus narrow persisted workflow/evidence state | Matches Phase 149 precedent: deterministic breadth plus only representative persisted evidence/workflow state. | yes |
| True offline journal/outbox | Honest local-first story, but too large unless real local storage, replay, idempotency, conflict, and reset proof ship now. | |

**User's choice:** User delegated final recommendation.

**Notes:** Advisor research recommended static `FieldService.Fixtures` breadth for jobs/assets/technicians/inspection templates plus narrow persisted events such as `inspection_event`, `evidence_event`, or `technician_job_state`. Reset must remain deterministic and preserve `browser_state_reset: false`.

---

## Capture, Scanning, Media/Evidence, and Permission Truth

| Option | Description | Selected |
|--------|-------------|----------|
| Honest native-screen fallback | Reuses existing native capture route metadata and keeps capture support truth explicit. | yes |
| Bounded bridge/control simulation | Useful only as labeled demo pressure; dangerous if it implies camera/scanner bridge support. | limited |
| Reuse media proof lane inline | Reuses existing evidence-authority proof: device evidence is not media availability. | yes |
| Production-like capture API implementation | Highest fidelity, but violates Phase 150/v19 anti-scope and triggers native proof/rebuild burden. | |
| Permission status surface | Useful if narrow; camera/scanner permissions must remain native-screen owned/future gap. | yes |

**User's choice:** User delegated final recommendation.

**Notes:** Advisor research recommended combining native-screen fallback, media/evidence authority copy, and a narrow permission-truth surface. Do not add camera/scanner bridge commands, camera/scanner permission aliases, or production capture/scanner APIs in Phase 150.

---

## Offline/Degraded Posture and Route Ownership Labels

| Option | Description | Selected |
|--------|-------------|----------|
| Keep Fieldserv cached read-only/degraded only | Coherent with current routes and honest for Phase 150. | yes |
| Add a true field inspection offline island | Real field-service fit, but expands v19 scope substantially and requires full journal/outbox/reconciliation proof. | |
| Show offline-island pressure without implementation | Preserves honesty and feeds Phase 152/v20 decisions without overclaiming. | yes |
| Reuse LearnLoop offline island pattern | Useful as an implementation reference only; relabeling LearnLoop or sharing its route would blur brands and truth. | limited |

**User's choice:** User delegated final recommendation.

**Notes:** Advisor research recommended cached read-only/degraded Fieldserv plus explicit future offline-island pressure. No Fieldserv route should use local-first/outbox/journal/replay wording unless a real Fieldserv-specific offline island ships.

---

## Claude's Discretion

- User explicitly requested a one-shot researched recommendation set, so Claude selected the internally coherent option set instead of asking per-area questions.
- Four subagents researched the gray areas independently: workflow, data/persistence, capture/permission truth, and offline/route ownership.
- Claude synthesized their recommendations with local prompt research, project planning docs, brandbook guidance, route-policy/support guides, existing Fieldserv/native-pressure code, and official primary-source ecosystem docs.

## Deferred Ideas

- Production scanner, document scan, camera capture, location, signature, and permission APIs.
- True Fieldserv offline inspection island with journal/outbox/replay/conflict proof.
- Generic field-service CRUD/workforce/maps/routing product.
- Generic permission dashboard or broad permission aliases.
- Rindle-backed production media upload/capture productization.
- `crosswake_dashboard` or global route inspector.
