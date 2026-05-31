# Phase 44: Rindle Media Seam Contracts And Reconciliation Vocabulary - Context

**Gathered:** 2026-05-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Define the typed Rindle media seam contracts and backend-owned reconciliation
vocabulary that prove the companion pattern generalizes beyond feature flags.

**Delivers:**
- `Crosswake.Companions.Rindle.Contracts` with documented structs and
  `validate_*/1 :: :ok | {:error, keyword()}` validators:
  - `UploadGrant`
  - `CaptureEvidence`
  - `MediaObject`
- `Crosswake.Companions.Rindle.Reconciliation` with a media-specific vocabulary
  that structurally mirrors `Crosswake.Commerce.Reconciliation`.
- Contract-level proof that device upload success is evidence only and cannot
  advance a media object to `:available`.

**Satisfies:** MEDIA-01, MEDIA-02.

**In scope:**
- Contract structs, closed vocabularies, validators, and unit/proof tests.
- Backend-owned media reconciliation result/attempt structs and helper
  functions.
- Grant-anchored evidence identity: server-issued grant/idempotency values must
  be echoed by capture evidence.
- Narrow state lane: `:queued | :uploaded | :scanning | :available | :rejected`.
- Explicit handoff notes for Phase 45's pure-Elixir mock upload/verify flow.

**Out of scope:**
- A working `Crosswake.Companions.Rindle` behaviour implementation. Phase 45.
- Pure-Elixir mock upload/verify example in `examples/phoenix_host`. Phase 45.
- External `rindle` optional dependency wiring and hermetic/advisory CI proof.
  Phase 45.
- Tus, multipart, resumable upload, storage-provider, virus-scan, and variant
  processing adapters. These remain future transport/provider layers, not the
  Phase 44 core contract.
- Threadline-grade append-only provenance or audit storage. Deferred until the
  audit capstone consumes stable MEDIA/AUTH/GATE contracts.

</domain>

<decisions>
## Implementation Decisions

### 1. Contract Shape - LOCKED
- **D-01:** Use the commerce-lane mirror, not a flat upload object and not a
  transport-first Tus/S3 abstraction. `Crosswake.Companions.Rindle.Contracts`
  should define typed structs and vocabulary helpers in the same spirit as
  `Crosswake.Commerce.Contracts`.
- **D-02:** `UploadGrant` is server-issued authority for upload permission. It
  should carry at minimum:
  `grant_id`, `idempotency_key`, `expires_at`, `max_bytes`, `accepted_types`,
  `key_prefix`, and a provider-neutral `storage_target` or equivalent lane.
  Planner may add `integrity_algorithms` when it stays provider-neutral.
- **D-03:** `CaptureEvidence` is evidence only. It should echo `grant_id` and
  `idempotency_key`, and carry device/upload observations such as
  `client_upload_ref`, `storage_key` or object key, `mime`, `bytes`,
  optional `content_hash`, optional multipart metadata, `captured_at`, and
  `correlation_id` as trace-only metadata.
- **D-04:** `MediaObject` carries backend-owned identity and availability state:
  `media_object_id`, stable `subject_key` or owner reference, `storage_key`,
  `state`, `verification_ref`, `rejection_reason`, `authoritative_at`, and
  `trace_metadata` or evidence lane. Exact struct nesting is planner discretion,
  but the authority/evidence split must be visible in the type shape.
- **D-05:** Validators follow existing Crosswake contract style:
  `validate_upload_grant/1`, `validate_capture_evidence/1`,
  `validate_media_object/1 :: :ok | {:error, keyword()}`. Unknown state,
  source, MIME/type, expiry, size, or grant/idempotency shape errors fail closed
  with structured keyword errors, not booleans or raised exceptions.

### 2. Media State Lane - LOCKED
- **D-06:** Keep the public media object state lane exactly:
  `:queued | :uploaded | :scanning | :available | :rejected`.
- **D-07:** Use a two-lane model: `MediaObject.state` is the user-facing
  availability/state lane; `Crosswake.Companions.Rindle.Reconciliation` owns
  the backend workflow outcomes. Do not collapse reconciliation outcomes into
  the media state enum.
- **D-08:** Evidence-only transitions:
  - `nil -> :queued` for local/offline capture intent or backend-created pending
    object.
  - `:queued -> :uploaded` when the device reports upload completion as
    evidence.
- **D-09:** Backend-authoritative transitions:
  - `:uploaded -> :scanning` when the backend has acknowledged/verifier-owned
    work.
  - `:scanning -> :available` only after backend verification succeeds.
  - `:uploaded` or `:scanning -> :rejected` when verification, policy, expiry,
    key-prefix, type, size, hash, or scanning checks fail.
- **D-10:** Treat `:available` and `:rejected` as terminal for the current
  media object version. Retry/replacement should produce a new grant/object or
  explicitly new version, not reverse the terminal state in place.

### 3. Reconciliation Vocabulary - LOCKED
- **D-11:** Add `Crosswake.Companions.Rindle.Reconciliation`, structurally
  mirroring `Crosswake.Commerce.Reconciliation`: closed outcome vocabulary,
  `Attempt`, `IdempotencyKey`, evidence result struct, outcome predicates, and
  an evidence-ingestion function.
- **D-12:** Preferred function names:
  - `outcome_vocabulary/0`
  - `reconciliation_outcome?/1`
  - `unresolved_outcome?/1`
  - `workflow_reporting_outcome?/1`
  - `outcome_implies_availability?/1`
  - `availability_mutation_allowed_from_evidence?/1`
  - `ingest_capture_evidence/2`
- **D-13:** Outcome vocabulary should be media-specific while staying
  commerce-recognizable. Recommended set:
  `:queued_capture`, `:upload_recorded`, `:awaiting_verification`,
  `:verification_in_progress`, `:projection_refreshed`,
  `:verification_failed`, `:rejected`, `:conflict`, `:stale_authority`.
  Planner may trim duplicate states if tests preserve the invariant and the
  mapping to `MediaObject.state` remains obvious.
- **D-14:** All reconciliation outcomes imply neither authority nor availability
  by themselves. `outcome_implies_availability?/1` should return false for the
  whole vocabulary. The only path to `MediaObject.state == :available` is an
  explicit backend verification/projection helper, not evidence ingestion.
- **D-15:** `ingest_capture_evidence/2` must reject attempts to mutate
  authority/availability directly, mirroring commerce:
  passing `availability_state: :available`, `authority_state: :available`, or
  equivalent override should return `{:error, :authority_lane_mutation_forbidden}`
  or the closest existing error convention.

### 4. Idempotency And Evidence Identity - LOCKED
- **D-16:** Use grant-anchored identity. `UploadGrant` carries server-issued
  `grant_id` and `idempotency_key`; `CaptureEvidence` must echo both. Evidence
  without a matching grant/idempotency pair is invalid or unverifiable.
- **D-17:** Do not derive idempotency from storage key alone, raw ETag, local
  queue ID, or device correlation ID. Those are trace or storage observations,
  not authority identity.
- **D-18:** Reconciliation `IdempotencyKey` should be derived from stable backend
  fields such as storage target/provider, `grant_id`, `idempotency_key`, and
  event kind. `correlation_id`, local queue IDs, progress events, and device
  success booleans are trace-only metadata.
- **D-19:** Replays should be marked with `replay?: true` and must not promote
  availability. This mirrors the commerce proof where duplicate evidence is
  observable but non-authoritative.

### 5. Phase 45 Handoff - LOCKED
- **D-20:** Phase 45 mock must prove deterministic `event_key` under retry,
  replay detection with changed correlation IDs, and mandatory idempotency.
- **D-21:** Phase 45 mock must prove `:queued` is never rendered or treated as
  committed media, and `:uploaded`/`:scanning` never auto-promote to
  `:available` without an explicit backend verify step.
- **D-22:** The bridge/native side may carry grant request and semantic state
  transitions. It must not carry chunk-by-chunk progress through Crosswake's
  semantic bridge; upload progress remains native/local transport UI.

### the agent's Discretion
- Exact struct nesting inside `MediaObject` (flat fields vs nested
  `UploadLane`/`EvidenceLane`/`VerificationLane`) is planner discretion, as
  long as D-01 through D-19 stay mechanically enforceable.
- Exact outcome names may be refined for least surprise, but they must stay
  media-specific, closed, documented, and structurally recognizable from
  `Crosswake.Commerce.Reconciliation`.
- Exact test file names are planner discretion. Strong default:
  `test/crosswake/companions/rindle/contracts_test.exs` and
  `test/crosswake/companions/rindle/reconciliation_test.exs`, plus a proof test
  if the planner wants the Phase 44 invariant merge-blocking under the proof
  namespace.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` section "Phase 44: Rindle Media Seam Contracts And Reconciliation Vocabulary" - authoritative goal and success criteria.
- `.planning/REQUIREMENTS.md` section "MEDIA - Rindle Media Seam (generalization proof)" - MEDIA-01 and MEDIA-02.
- `.planning/ROADMAP.md` section "Phase 45: Rindle In-Tree Companion, Mock Example, And Proof" - handoff constraints for the mock/proof phase.

### Strategic guardrails and prompt research
- `.planning/PROJECT.md` - Crosswake thesis, v3.5 scope, and Rindle media seam target.
- `.planning/MILESTONE-ARC.md` - contracts-first guardrails, companion classification, offline and bridge boundaries.
- `.planning/research/v3.5-companions-SUMMARY.md` - Rindle seam research synthesis and cross-ecosystem footguns.
- `prompts/crosswake-elixir-oss-dna.md` - maintainer house style: install truth, support honesty, proof lanes, optional-dep diagnostics.
- `prompts/crosswake-integrations-and-companions.md` - Rindle companion classification and intended value.
- `prompts/crosswake-research-synthesis.md` - architecture thesis: route ownership, low-frequency bridge, honest offline/media boundaries.
- `prompts/elixir-mobile-offlinesupport-stresstest-deep-research.md` - offline and mobile media pressure context.
- `prompts/elixir-mobile-offlinesupport-flashcard-app-stresstest-deep-research.md` - narrow offline queue semantics and mobile UX constraints.

### Commerce precedent to mirror
- `lib/crosswake/commerce/contracts.ex` - typed structs, lane vocabulary, and validator style precedent.
- `lib/crosswake/commerce/reconciliation.ex` - backend-owned reconciliation vocabulary and non-authoritative evidence fence.
- `test/crosswake/commerce/contracts_test.exs` - contract/vocabulary test shape.
- `test/crosswake/commerce/reconciliation_test.exs` - proof assertions for evidence ingestion, replay, invalid source, and authority mutation rejection.
- `.planning/phases/34-mockstorefront-and-idempotency-invariants/34-CONTEXT.md` - idempotency and mock evidence decisions from commerce archetype work.
- `.planning/phases/35-reconciliation-wiring-and-four-state-liveview/35-CONTEXT.md` - projection and derived-state precedent.
- `.planning/phases/40-runtime-gate-evaluation-and-fail-closed-denial/40-CONTEXT.md` - companion dispatch and fail-closed denial precedent.

### Example-host reconciliation precedent
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex` - append-only evidence ingestion example, non-authoritative by design.
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex` - stable event/subject key pattern and trace-only correlation metadata.
- `examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex` - pure-Elixir evidence emitter pattern for Phase 45's mock upload target.
- `test/crosswake/proof/phase34_mock_storefront_test.exs` - idempotency, replay, and mock-boundary proof patterns.

### Companion convention
- `lib/crosswake/companion.ex` - companion behaviour and callback contracts.
- `lib/crosswake/companion/state.ex` - typed companion state struct.
- `lib/crosswake/companions/rulestead.ex` - first concrete in-tree companion precedent.
- `.planning/phases/42-rulestead-in-tree-companion-and-mock-example/42-CONTEXT.md` - in-tree companion and mock-source decisions.
- `.planning/phases/43-rulestead-hermetic-advisory-proof-and-guide/43-CONTEXT.md` - companion proof/docs posture and optional dependency handling.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Commerce.Contracts` - closest API template for typed contract
  structs, closed vocabularies, and `validate_*/1` functions.
- `Crosswake.Commerce.Reconciliation` - exact semantic template for
  evidence-only ingestion, replay marking, backend verification markers, and
  authority mutation rejection.
- `CrosswakeExample.Commerce.ReconciliationKeys` - stable event/subject key
  composition; Rindle should use the same idea for grant/idempotency-backed
  media event keys.
- `phase34_mock_storefront_test.exs` and `phase34_paywall_corridor_proof_test.exs`
  - proof language for "evidence does not grant authority"; Rindle tests should
  be nearly isomorphic.

### Established Patterns
- Crosswake contract modules use closed atom vocabularies and helper predicates
  rather than open strings or provider enums.
- Evidence source normalization fails closed before creating result structs.
- Reconciliation helpers return typed result structs with `replay?`, `attempt`,
  and `idempotency_key`; replay is observable but not authoritative.
- Planning and docs treat proof lanes, support truth, and rough-edge language as
  product surface. Rindle should ship with invariant tests, not only comments.

### Integration Points
- New code should live under `lib/crosswake/companions/rindle/` or a sibling
  module namespace chosen consistently with `lib/crosswake/companions/rulestead.ex`.
- New tests should live under `test/crosswake/companions/rindle/` or
  `test/crosswake/proof/` following existing proof naming conventions.
- Phase 45 will connect these contracts to `examples/phoenix_host` and a
  `Crosswake.Companions.Rindle` implementation; Phase 44 should leave clean
  public functions for that mock to call.

</code_context>

<specifics>
## Specific Ideas

- The "perfect" recommendation set from discussion and subagent research is a
  single coherent direction: commerce-shaped contracts, two-lane media state
  plus reconciliation outcomes, and grant-anchored identity.
- Lessons imported from successful ecosystems:
  - ActiveStorage: direct upload pre-registration/signed blob identity is useful,
    but Crosswake should not treat the client direct upload as attached/available
    until backend analysis/verification.
  - Shrine: cache-to-store promotion is a useful model; promotion is backend
    authority, not upload callback authority.
  - Stripe: idempotency keys must be stable and backend-recognized; transient
    correlation IDs are trace only.
  - S3 presign/multipart: object keys and ETags are storage facts with footguns;
    they are not enough for authority identity in a mobile retry storm.
  - Tus/Uppy: resumability is valuable for future transport adapters, but Phase
    44 should not make chunk/progress semantics part of Crosswake's low-frequency
    semantic bridge.
- DX principle: adopters should be able to read the commerce reconciliation
  tests and predict the Rindle reconciliation tests. That is the generalization
  proof.

</specifics>

<deferred>
## Deferred Ideas

- **Transport adapters** - Tus, S3 multipart, provider-specific checksum/HEAD
  verification, virus scanning, EXIF stripping, and media variant generation are
  adapter/mock-example concerns after the core seam is stable.
- **Append-only provenance/event store** - useful later for Threadline, support,
  and forensic debugging, but too heavy for Phase 44.
- **Upload progress bridge surface** - progress belongs in native/local upload
  UI or future adapter-specific APIs, not the Crosswake semantic bridge.
- **Real Rindle optional dependency wiring** - Phase 45.
- **Support-matrix/doctor rows for Rindle runtime state** - Phase 45 or Phase 47
  once the in-tree companion exists.

</deferred>

---

*Phase: 44-rindle-media-seam-contracts-and-reconciliation-vocabulary*
*Context gathered: 2026-05-31*
