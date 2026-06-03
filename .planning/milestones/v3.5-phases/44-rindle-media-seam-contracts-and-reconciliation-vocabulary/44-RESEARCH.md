# Phase 44 Research: Rindle Media Seam Contracts And Reconciliation Vocabulary

## RESEARCH COMPLETE

**Phase:** 44 - Rindle Media Seam Contracts And Reconciliation Vocabulary
**Date:** 2026-05-31
**Requirements:** MEDIA-01, MEDIA-02

## Executive Summary

Phase 44 should copy the successful commerce seam shape rather than inventing a transport-first upload abstraction. The right implementation path is:

1. Add `Crosswake.Companions.Rindle.Contracts` under `lib/crosswake/companions/rindle/contracts.ex`.
2. Define documented typed structs for `UploadGrant`, `CaptureEvidence`, and `MediaObject`.
3. Keep media availability as a closed state lane: `:queued | :uploaded | :scanning | :available | :rejected`.
4. Add `Crosswake.Companions.Rindle.Reconciliation` under `lib/crosswake/companions/rindle/reconciliation.ex`.
5. Mirror `Crosswake.Commerce.Reconciliation` structurally: closed outcome vocabulary, `Attempt`, `IdempotencyKey`, `EvidenceResult`, predicates, and evidence ingestion.
6. Enforce the key invariant mechanically: device evidence can record `:uploaded` or reconciliation work, but cannot directly promote a media object to `:available`.

## Verified Code Anchors

### Commerce Contracts Precedent

`lib/crosswake/commerce/contracts.ex` provides the closest local template:

- Nested structs use `@enforce_keys`, `defstruct`, and `@type t`.
- Closed vocabularies are exposed through functions such as `reconciliation_vocabulary/0`.
- Validation returns `:ok | {:error, keyword()}` through `validate_entitlement_snapshot/1`.
- Source normalization is explicit and fail-closed through `canonical_reconciliation_evidence_source/1`.

Important pattern to reuse: validation accumulates keyword errors and returns `{:error, Enum.reverse(errors)}` only at the edge. This keeps callers from relying on exceptions or booleans.

### Commerce Reconciliation Precedent

`lib/crosswake/commerce/reconciliation.ex` provides the semantic template:

- `outcome_vocabulary/0`
- `reconciliation_outcome?/1`
- `unresolved_outcome?/1`
- `workflow_reporting_outcome?/1`
- outcome predicates that always return false for authority/access grants
- `Attempt`, `IdempotencyKey`, and `EvidenceResult` structs
- `ingest_evidence/2`
- `authority_mutation_allowed_from_evidence?/1`

The media version should rename the authority predicate to availability semantics, but keep the behavioral fence:

- `outcome_implies_availability?/1` returns false for every outcome.
- `availability_mutation_allowed_from_evidence?/1` returns false for capture evidence.
- `ingest_capture_evidence/2` rejects direct availability or authority override opts before creating an evidence result.

### Test Precedent

`test/crosswake/commerce/contracts_test.exs` and `test/crosswake/commerce/reconciliation_test.exs` are the primary test templates. The Phase 44 tests should be nearly isomorphic:

- Assert exact vocabulary lists.
- Assert invalid lane/source/state values fail closed with structured keyword errors.
- Assert evidence ingestion maps success-like device upload evidence to an unresolved outcome, not availability.
- Assert replay detection is based on stable idempotency fields, not a device correlation id.
- Assert direct authority/availability override opts are rejected.

## Recommended Contract Shape

### `UploadGrant`

Server-issued permission to upload. Required fields:

- `grant_id`
- `idempotency_key`
- `expires_at`
- `max_bytes`
- `accepted_types`
- `key_prefix`
- `storage_target`

Recommended optional field:

- `integrity_algorithms`

Validation must reject:

- missing or empty string fields
- expired/invalid `expires_at` shape
- non-positive `max_bytes`
- empty or non-list `accepted_types`
- accepted types that are not strings
- empty `key_prefix`

### `CaptureEvidence`

Device-reported evidence only. Required fields:

- `grant_id`
- `idempotency_key`
- `storage_key`
- `mime`
- `bytes`
- `captured_at`

Recommended optional fields:

- `client_upload_ref`
- `content_hash`
- `multipart`
- `correlation_id`
- `trace_metadata`

Validation must reject:

- missing grant or idempotency identity
- non-positive `bytes`
- invalid `mime`
- missing `storage_key`
- evidence that carries direct authority or availability fields

### `MediaObject`

Backend-owned projection state. Required fields:

- `media_object_id`
- `subject_key`
- `storage_key`
- `state`
- `as_of`

Recommended optional fields:

- `verification_ref`
- `rejection_reason`
- `authoritative_at`
- `trace_metadata`

Validation must reject:

- state outside `:queued | :uploaded | :scanning | :available | :rejected`
- `:available` without `verification_ref` and `authoritative_at`
- `:rejected` without `rejection_reason`
- malformed nested lanes if the executor chooses nested structs

## Recommended Reconciliation Vocabulary

Use this closed list unless execution uncovers a stronger simplification:

- `:queued_capture`
- `:upload_recorded`
- `:awaiting_verification`
- `:verification_in_progress`
- `:projection_refreshed`
- `:verification_failed`
- `:rejected`
- `:conflict`
- `:stale_authority`

Classification:

- unresolved: `:queued_capture`, `:upload_recorded`, `:awaiting_verification`, `:verification_in_progress`
- workflow reporting: `:projection_refreshed`, `:verification_failed`, `:rejected`, `:conflict`, `:stale_authority`

All outcomes remain reconciliation outcomes, not availability grants. `:projection_refreshed` means backend workflow has produced a projection; it still does not imply availability by itself. Availability is represented only by a validated `%MediaObject{state: :available}` created through an explicit backend helper.

## Function Surface

### Contracts

`Crosswake.Companions.Rindle.Contracts` should expose:

- `media_state_vocabulary/0`
- `capture_evidence_source_vocabulary/0`
- `canonical_capture_evidence_source/1`
- `new_upload_grant/1`
- `new_capture_evidence/1`
- `new_media_object/1`
- `validate_upload_grant/1`
- `validate_capture_evidence/1`
- `validate_media_object/1`
- `available_from_backend_verification/2` or a similarly named helper that requires backend verification inputs

The executor should avoid a generic `transition/2` API in Phase 44. A broad transition API would invite future code to treat device evidence and backend verification as equivalent.

### Reconciliation

`Crosswake.Companions.Rindle.Reconciliation` should expose:

- `outcome_vocabulary/0`
- `reconciliation_outcome?/1`
- `unresolved_outcome?/1`
- `workflow_reporting_outcome?/1`
- `outcome_implies_availability?/1`
- `availability_mutation_allowed_from_evidence?/1`
- `ingest_capture_evidence/2`

Structs:

- `Attempt`
- `IdempotencyKey`
- `EvidenceResult`

`IdempotencyKey` should be derived from stable backend-owned fields: `storage_target`, `grant_id`, `idempotency_key`, and `event_kind`. `correlation_id`, local queue ids, progress events, and device success booleans are trace-only.

## Phase 45 Handoff

Phase 44 should leave clean seams for Phase 45's mock upload/verify flow:

- A mock can create an `UploadGrant`.
- A mock can create `CaptureEvidence` that echoes grant identity.
- `ingest_capture_evidence/2` returns an evidence result with deterministic idempotency.
- Replays are observable via `replay?: true`.
- No evidence path can create `MediaObject.state == :available`.
- A backend verification helper can create an available media object only with explicit verification data.

## Validation Architecture

Phase 44 validation should use hermetic ExUnit tests only. No external `rindle` package, storage provider, scanner, Phoenix example host, native shell, or CI matrix is required in this phase.

Required proof files:

- `test/crosswake/companions/rindle/contracts_test.exs`
- `test/crosswake/companions/rindle/reconciliation_test.exs`
- optional `test/crosswake/proof/phase44_rindle_contracts_test.exs` if the executor wants a single phase-level invariant proof

Minimum verification commands:

- `mix test test/crosswake/companions/rindle/contracts_test.exs`
- `mix test test/crosswake/companions/rindle/reconciliation_test.exs`
- `mix test test/crosswake/companions/rindle`
- `mix compile --warnings-as-errors`

## Risks And Pitfalls

- Do not add a `Crosswake.Companions.Rindle` behaviour implementation in Phase 44. That is Phase 45.
- Do not add an external `rindle` dependency in Phase 44. Optional dependency posture is Phase 45.
- Do not model upload progress through the semantic bridge. Progress is native/local transport UI, not a Crosswake bridge contract.
- Do not treat `:uploaded`, `:awaiting_verification`, or `:projection_refreshed` as available media.
- Do not derive idempotency from `correlation_id`, local queue id, storage key alone, or ETag alone.
- Do not widen this into Tus, multipart, S3, scanner, or variant-processing adapters.

