# Phase 44: Rindle Media Seam Contracts And Reconciliation Vocabulary - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-05-31
**Phase:** 44-rindle-media-seam-contracts-and-reconciliation-vocabulary
**Areas discussed:** Contract shape, MediaObject state lane, Backend-owned reconciliation vocabulary, Idempotency and evidence identity

---

## Contract Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Commerce-lane mirror | Typed Rindle contracts plus separate reconciliation module, structurally familiar from `Crosswake.Commerce.Contracts` and `Crosswake.Commerce.Reconciliation`. | yes |
| Flat MediaObject struct | Smaller surface with helper predicates; fast but weak authority/evidence separation. | |
| Transport-first contract | Presign/Tus/S3 session object; richer upload mechanics but overfits transport into the core seam. | |

**User's choice:** Discuss all areas with subagent research and produce one cohesive recommendation set.

**Notes:** Research strongly favored the commerce-lane mirror. This preserves Crosswake's existing mental model, makes the device-evidence authority fence mechanically testable, and avoids coupling the first contract to Tus/S3/multipart details.

---

## MediaObject State Lane

| Option | Description | Selected |
|--------|-------------|----------|
| `MediaObject.state` only | Minimal `:queued | :uploaded | :scanning | :available | :rejected` state with guarded transition helpers. | |
| Two-lane model | Keep the simple media state lane and add commerce-shaped backend reconciliation outcomes. | yes |
| Append-only attempt log | Event-sourced flavor with attempts/projections first. Strong auditability but too heavy for Phase 44. | |

**User's choice:** Discuss all areas with ecosystem lessons and DX tradeoffs.

**Notes:** Research favored the two-lane model. It keeps adopter-facing media state simple while making backend verification and non-authoritative evidence explicit. Append-only provenance is useful later for Threadline but is not this phase.

---

## Backend-Owned Reconciliation Vocabulary

| Option | Description | Selected |
|--------|-------------|----------|
| `Crosswake.Companions.Rindle.Reconciliation` mirror | Closed outcomes, `ingest_capture_evidence/2`, idempotency key/result structs, and authority guard. | yes |
| Async verification pipeline first | Operationally realistic but pulls Phase 45 mock/backend work into Phase 44. | |
| Minimal structs only | Lowest churn but leaves MEDIA-02 as convention rather than contract. | |

**User's choice:** Use subagent-backed research and one-shot recommendations.

**Notes:** Recommendation is a media-specific reconciliation module that mirrors commerce. Tests should prove device evidence lands in reconciliation outcomes only, replay is non-authoritative, direct availability mutation is rejected, and backend verification is the only path to `:available`.

---

## Idempotency And Evidence Identity

| Option | Description | Selected |
|--------|-------------|----------|
| Grant-anchored identity | Server-issued `UploadGrant` carries `grant_id` and `idempotency_key`; evidence must echo both. | yes |
| Object-key-anchored identity | Simple, but storage keys can collide, be overwritten, or hide retry semantics. | |
| Upload-session-anchored identity | Best for resumable/chunked protocols, but too heavy for v3.5 contract slice. | |

**User's choice:** Consider all tradeoffs and recommend a cohesive architecture.

**Notes:** Recommendation is grant-anchored identity. `correlation_id`, local queue IDs, progress, raw ETags, and device success flags remain trace-only. Phase 45 should prove deterministic event keys, replay detection under changed correlation IDs, mandatory idempotency, and no auto-promotion to `:available`.

---

## the agent's Discretion

- Exact Rindle module file split and struct nesting.
- Exact reconciliation outcome names, provided they stay closed, media-specific, and commerce-recognizable.
- Exact test file placement and whether the Phase 44 invariant is covered under `test/crosswake/companions/rindle/` only or also in `test/crosswake/proof/`.

## Deferred Ideas

- Tus, multipart, S3-specific, scan, variant, and EXIF/PII processing adapters.
- Threadline-grade append-only provenance.
- Upload progress over the Crosswake bridge.
- Real Rindle optional dependency wiring and pure-Elixir mock upload/verify flow.
