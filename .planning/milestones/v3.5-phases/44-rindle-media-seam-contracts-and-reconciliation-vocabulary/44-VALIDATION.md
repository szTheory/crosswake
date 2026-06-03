---
phase: 44
slug: rindle-media-seam-contracts-and-reconciliation-vocabulary
status: draft
created: 2026-05-31
---

# Phase 44 Validation Strategy

## Validation Architecture

Phase 44 is a library contract slice. Validation is hermetic ExUnit coverage for:

- typed media contract structs and validators
- closed media state and reconciliation vocabularies
- backend-owned availability invariant
- replay/idempotency behavior
- evidence-only ingestion fences

No external `rindle` dependency, native shell, Phoenix example-host route, storage backend, scanner, or CI advisory lane is required for Phase 44.

## Required Checks

| Check | Command | Purpose |
|-------|---------|---------|
| Contracts tests | `mix test test/crosswake/companions/rindle/contracts_test.exs` | Proves `UploadGrant`, `CaptureEvidence`, and `MediaObject` shape and validation |
| Reconciliation tests | `mix test test/crosswake/companions/rindle/reconciliation_test.exs` | Proves evidence ingestion, replay, vocabulary, and availability fence |
| Rindle contract slice | `mix test test/crosswake/companions/rindle` | Proves all Phase 44 Rindle tests together |
| Compile warnings | `mix compile --warnings-as-errors` | Proves public contract code compiles cleanly |

## Must-Have Assertions

- `Contracts.media_state_vocabulary()` returns exactly `[:queued, :uploaded, :scanning, :available, :rejected]`.
- `validate_upload_grant/1`, `validate_capture_evidence/1`, and `validate_media_object/1` return `:ok | {:error, keyword()}`.
- `CaptureEvidence` echoes `grant_id` and `idempotency_key`.
- Invalid or missing grant/idempotency identity fails validation.
- `MediaObject.state == :available` requires explicit backend verification fields.
- `Reconciliation.outcome_implies_availability?/1` returns false for every outcome.
- `Reconciliation.availability_mutation_allowed_from_evidence?/1` returns false for capture evidence.
- `Reconciliation.ingest_capture_evidence/2` rejects direct availability or authority override opts.
- Replay detection is based on stable idempotency fields, not `correlation_id`.

## Coverage Boundaries

Phase 44 does not validate:

- optional dependency loading
- `Crosswake.Companions.Rindle` behaviour implementation
- example-host upload/verify UX
- storage provider calls
- scanner or media processing adapters
- native shell upload progress

Those belong to Phase 45 or later provider/advisory phases.

