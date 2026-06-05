# Phase 72: Media/Evidence Workflow Proof - Research

**Researched:** 2026-06-05
**Status:** Complete
**Requirement IDs:** MED-01, MED-02

## Research Question

What needs to be true to plan a deterministic, product-shaped Rindle media/evidence recovery proof without widening Crosswake into a generic sync, storage, or native upload framework?

## Findings

### Existing Rindle Contracts Are The Right Spine

`Crosswake.Companions.Rindle.Contracts` already separates server-issued `UploadGrant`, device/native `CaptureEvidence`, and backend-owned `MediaObject`. The important invariant is already encoded: `CaptureEvidence` can record upload observations, but only `verified_media_object/2` may promote `:uploaded` or `:scanning` media to `:available`, and that requires `verification_ref` plus `authoritative_at`.

`Crosswake.Companions.Rindle.Reconciliation.ingest_capture_evidence/2` already exposes the reconciliation vocabulary needed for the proof: `:queued_capture`, `:upload_recorded`, `:awaiting_verification`, `:verification_in_progress`, `:verification_failed`, `:rejected`, `:conflict`, and `:stale_authority`. It also rejects `:authority_state` and `:availability_state` overrides in reconciliation options.

### Example-Host Media Modules Are Sufficient For A Hermetic Lane

The Phase 45 example-host modules provide a pure-Elixir proof spine:

- `CrosswakeExample.Media.MockCapture` issues upload grants and emits device evidence.
- `CrosswakeExample.Media.ReconciliationKeys` builds stable event and subject identity while keeping `correlation_id` trace-only.
- `CrosswakeExample.Media.ReconciliationInbox` wraps Rindle ingestion and replay metadata.
- `CrosswakeExample.Media.MediaProjection` projects evidence into `:uploaded` or `:scanning`, then requires backend verification for `:available`.
- `CrosswakeExample.Media.MediaLaneLive` provides a compact Phoenix-owned proof surface for queued/uploaded/scanning/available states.

The plan should reuse these modules instead of creating a new runtime abstraction. If a queue/degradation helper is needed, it should be proof-only and named narrowly, for example `QueuedCapture` or `LocalUploadQueue`, not `Outbox`.

### Phase 72 Gap Versus Phase 45

Phase 45 proved the Rindle seam and mock media lane. Phase 72 should prove an adopter-shaped failure/recovery workflow:

1. Backend issues upload grant.
2. Local capture is recorded during simulated degradation.
3. Initial upload attempt fails or stays queued.
4. Queued evidence is retained with grant/idempotency/storage identity.
5. Recovery drains the same evidence into Rindle reconciliation.
6. Projection reaches `:uploaded` or `:scanning`, never `:available`.
7. Explicit backend verification promotes to `:available`.

This is a proof lane over existing contracts, not a production queue, Ecto schema, background worker, native uploader, or storage-provider integration.

### Proof Shape From Phases 70 And 71

Phase 70 and Phase 71 established the current v4.1 pattern:

- One targeted hermetic ExUnit proof file under `test/crosswake/proof/`.
- Inline fixtures are acceptable when they model the outside world while exercising real Crosswake contracts.
- The proof should include positive product flow, adversarial authority-fence cases, idempotency/replay cases, redaction/support-safety cases, and hermeticity self-scan guards.
- Targeted GitHub Actions workflows use pinned checkout/setup-beam actions, `permissions: contents: read`, compile with warnings as errors, a merge-blocking proof job, and advisory-only notices for provider/device/storage behavior.

### Likely Implementation Work

Wave 0 should create `test/crosswake/proof/phase72_media_evidence_workflow_proof_test.exs` with a proof-only degradation/queue fixture and red assertions for missing recovery behavior. The proof should require only pure Rindle and example-host media files.

Wave 1 should close any implementation gaps in the example-host media helpers and `MediaLaneLive`: deterministic queue states, partial multipart rejection, integrity checks if missing, replay behavior, redaction of hostile metadata, and state copy that says local evidence is not authority.

Wave 2 should add `.github/workflows/phase72-proof.yml` and narrow docs/support/operator truth only where needed. Public copy must say simulated degradation plus Rindle reconciliation proof, not real storage, native camera, background upload, or local-first sync support.

## Validation Architecture

Phase 72 should be validated through fast deterministic commands:

- `mix test test/crosswake/proof/phase72_media_evidence_workflow_proof_test.exs`
- `mix test test/crosswake/proof/phase45_rindle_mock_media_test.exs test/crosswake/proof/phase45_rindle_live_test.exs`
- `mix test test/crosswake/companions/rindle/contracts_test.exs test/crosswake/companions/rindle/reconciliation_test.exs`
- `mix compile --warnings-as-errors`
- `git diff --check -- .planning/phases/72-media-evidence-workflow-proof .github/workflows/phase72-proof.yml guides/support_matrix.md guides/companions.md guides/user_flows.md examples/phoenix_host/lib/crosswake_example/media test/crosswake/proof/phase72_media_evidence_workflow_proof_test.exs`

No validation should require Endpoint, Repo, PubSub, browser automation, native device, simulator, storage provider, real network toggling, credentials, or provider SDKs.

## Planning Recommendations

- Use three plans: red proof contract, implementation/projection/UI closure, and CI/support truth.
- Keep MED-01 and MED-02 on every plan unless a plan is purely CI/docs and still supports the same proof.
- Include a threat model in each plan. The main high-severity threat is elevation of privilege from local/device evidence into media availability.
- Make the executor read Phase 72 context and Phase 45/70/71 proof precedents before touching code.
- Do not add Ecto migrations, schemas, generic outbox APIs, storage credentials, or native upload features.

## RESEARCH COMPLETE

