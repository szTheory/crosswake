# Phase 72: Pattern Map

**Generated:** 2026-06-05
**Status:** Ready for planning

## Files To Create

### `test/crosswake/proof/phase72_media_evidence_workflow_proof_test.exs`

Role: Hermetic product-shaped Phase 72 proof lane.

Closest analogs:

- `test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs` - v4.1 archetype proof shape, authority matrix, hermetic self-scan.
- `test/crosswake/proof/phase71_notification_workflow_proof_test.exs` - targeted proof lane with inline fixture and redaction guard.
- `test/crosswake/proof/phase45_rindle_mock_media_test.exs` - Rindle example-host media spine.

Required data flow:

`MockCapture.issue_upload_grant/2` -> proof-only local queued capture fixture -> `MockCapture.emit_capture_evidence/2` -> `ReconciliationInbox.ingest_capture_evidence/2` -> `MediaProjection.project_object/2` -> `MediaProjection.project_object/2` with `backend_verified: true`.

Must not require Endpoint, Repo, PubSub, browser, storage provider, native device, simulator, real network toggling, or provider SDKs.

## Files Likely To Modify

### `examples/phoenix_host/lib/crosswake_example/media/mock_capture.ex`

Role: Pure evidence emitter. Keep grant/evidence separate. If adding support for multipart/integrity/degradation fixture values, keep them deterministic keyword options on `emit_capture_evidence/2`.

Avoid: production upload methods, storage provider names, `upload_and_verify`, background upload, camera APIs.

### `examples/phoenix_host/lib/crosswake_example/media/reconciliation_inbox.ex`

Role: Example-host wrapper around Rindle ingestion. It may need narrow option pass-through for queued/degraded upload status, scan failure, replay, or integrity metadata.

Preserve: `correlation_id` is trace-only; replay identity is stable event/idempotency data.

### `examples/phoenix_host/lib/crosswake_example/media/media_projection.ex`

Role: Backend-owned projection. It may need explicit rejection/scanning states for Phase 72 proof. Do not let evidence alone produce `:available`.

Critical invariant: `Contracts.verified_media_object/2` is the only positive availability path.

### `examples/phoenix_host/lib/crosswake_example/media/media_lane_live.ex`

Role: Compact Phoenix-owned proof surface. It may need state/copy/actions for local capture recorded, degraded upload failed, queued evidence, recovered retry, scanning, available, and rejected.

Keep direct `handle_event` proof compatible with `test/crosswake/proof/phase45_rindle_live_test.exs`.

### `.github/workflows/phase72-proof.yml`

Role: Targeted merge-blocking CI lane.

Closest analogs: `.github/workflows/phase70-proof.yml`, `.github/workflows/phase71-proof.yml`, `.github/workflows/phase45-proof.yml`.

Required shape: pinned actions, `permissions: contents: read`, `mix compile --warnings-as-errors`, targeted Phase 72 proof command, advisory storage/native/device notice job.

### Support/docs/operator files

Candidate files:

- `guides/support_matrix.md`
- `guides/companions.md`
- `guides/user_flows.md`
- `lib/crosswake/support_matrix/support_matrix.ex`
- `lib/crosswake/operator_inspection.ex`
- related tests under `test/crosswake/support_matrix/` and `test/crosswake/operator_inspection/`

Touch only if implementation creates new public truth. Wording must distinguish simulated degradation plus Rindle reconciliation from real storage/native/offline support.

## Implementation Constraints

- Use Rindle vocabulary wherever possible: `:queued_capture`, `:upload_recorded`, `:awaiting_verification`, `:verification_in_progress`, `:verification_failed`, `:rejected`, `:conflict`, `:stale_authority`.
- Name local fixture state narrowly: `QueuedCapture`, `LocalUploadQueue`, `degraded_capture_recorded`, `upload_attempt_failed`, `backend_verified_available`.
- Do not introduce `Outbox`, generic sync, CRDT, background worker, Ecto schema, migration, storage provider, or native upload abstraction.
- Do not make `CaptureEvidence`, replay metadata, `trace_metadata`, or UI state an authority lane.

