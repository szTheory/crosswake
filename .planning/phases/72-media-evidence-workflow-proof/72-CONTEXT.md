# Phase 72: Media/Evidence Workflow Proof - Context

**Gathered:** 2026-06-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove a production-shaped media/evidence recovery workflow over the real Rindle contracts and example-host media modules: a server-issued upload grant leads to local capture during simulated network degradation, a failed upload attempt is retained as proof-only queued evidence, recovery replays that evidence into Rindle reconciliation, and backend verification remains the only path to `:available` media.

This phase is an archetype proof lane, not a generic sync engine, not a durable outbox framework, not a native camera/background-upload implementation, not a real storage-provider integration, and not a claim that LiveView owns offline mutation semantics. The merge-blocking output should be deterministic and CI-hermetic while proving MED-01 and MED-02: Rindle reconciliation can recover a degraded media/evidence workflow, and local/device capture signals remain non-authoritative until backend verification completes.

</domain>

<decisions>
## Implementation Decisions

### Degradation And Recovery Model
- **D-01:** Model Phase 72 as a hybrid: route/workflow-level degradation plus a narrow proof-only local queue fixture and backend verification gate.
- **D-02:** Use terms such as `QueuedCapture`, `LocalUploadQueue`, `degraded_capture_recorded`, `queued_capture`, `upload_attempt_failed`, `awaiting_verification`, and `backend_verified_available`. Avoid generic `Outbox` or broad sync-engine vocabulary unless the implementation needs an internal helper name that is clearly proof-only.
- **D-03:** The proof story should be: upload grant issued -> capture occurs while route/network is degraded -> queued capture is stored locally with stable grant/idempotency/storage identity -> initial upload attempt fails or remains queued -> recovery drains the queued capture into `ReconciliationInbox` -> `MediaProjection` reaches `:uploaded` or `:scanning`, not `:available` -> explicit backend verification promotes to `:available`.
- **D-04:** Keep local recovery state in the test or example-host media namespace. Do not add Ecto schemas, migrations, a production media outbox, background workers, native upload APIs, or Crosswake core sync primitives in Phase 72.
- **D-05:** Production guidance may mention that a host app would normally persist this with Phoenix contexts, unique constraints/upserts, and `Ecto.Multi` around inbox/projector work, but the merge-blocking proof stays pure and hermetic.

### Proof Spine
- **D-06:** Build a new targeted merge-blocking proof file, likely `test/crosswake/proof/phase72_media_evidence_workflow_proof_test.exs`.
- **D-07:** The primary proof layer should be pure ExUnit over Rindle contracts and example-host media modules, adding deterministic degraded-network/recovery fixtures that Phase 45 does not cover. It must not start Endpoint, Repo, PubSub, browser, real Rindle dependency, storage provider, simulator, emulator, or device lane.
- **D-08:** Add a hermeticity self-scan guard similar to Phase 70/71 so the proof cannot quietly require runtime/server/provider paths.
- **D-09:** Include a secondary direct `MediaLaneLive` render/`handle_event` proof layer only to keep the Phoenix-owned proof surface honest about queued, failed/stored, recovered, scanning, rejected, and available states. Do not make full endpoint/router/browser LiveView integration the default merge gate.
- **D-10:** Add a targeted CI workflow, likely `.github/workflows/phase72-proof.yml`, following the Phase 70/71 shape: pinned actions, `permissions: contents: read`, compile with warnings as errors, a named merge-blocking job for the Phase 72 proof, and advisory-only messaging for real device/storage/provider work if needed.

### Recovery And Authority Matrix
- **D-11:** Use one integrated product-shaped positive path: `degraded_capture_reconciles_after_recovery`.
- **D-12:** Positive path details: server grant issued -> device capture recorded locally during simulated offline/degraded upload -> initial upload attempt fails or remains queued -> no available media -> recovery replays the same grant/idempotency/storage identity -> Rindle ingests evidence as `:awaiting_verification` or `:verification_in_progress` -> backend verification with `verification_ref` and `authoritative_at` promotes to `:available`.
- **D-13:** Include `multipart_completion_requires_full_payload`: partial multipart evidence may be recorded, but only later full-payload or `multipart_complete` evidence with expected bytes/hash can move to scanning/verification; backend verification still gates availability.
- **D-14:** Include `idempotent_replay_ignores_trace_correlation`: the same grant/idempotency/storage/event replay with a different `correlation_id` is marked replay and must not create duplicate availability or a second media object.
- **D-15:** Include `scan_started_then_verified`: upload evidence can project `:scanning`, but availability waits for explicit backend verification fields.
- **D-16:** Negative cases should include stale/expired grant, missing payload identity, partial multipart treated as completion, corrupt hash or unsupported integrity algorithm, backend scan failure, direct availability/authority override, invalid or spoofed evidence source, public redaction leaks, and `MediaObject{state: :available}` without backend fields.
- **D-17:** Denials/rejections should stay in the Rindle/media vocabulary where possible: `:queued_capture`, `:upload_recorded`, `:awaiting_verification`, `:verification_in_progress`, `:verification_failed`, `:rejected`, `:conflict`, and `:stale_authority`. Do not invent provider-storage denial codes unless the implementation exposes a real missing vocabulary gap.
- **D-18:** Redaction proof should include hostile metadata such as raw payload, local file path, route params, actor/session refs, device IDs, email, IP, user agent, raw storage credentials, and authority/availability hints. Public proof/support/telemetry output must not leak these values.

### UI, UX, Support Truth, And DX
- **D-19:** If `MediaLaneLive` is touched, keep it a compact Phoenix LiveView proof surface, not a production upload dashboard or native capture simulator.
- **D-20:** The visible state sequence should be legible to adopters: local capture recorded, upload failed during simulated degradation, evidence queued, network recovered/retry possible, device evidence recorded, backend verification in progress, backend verified available, or backend rejected.
- **D-21:** Use semantic headings, real buttons, visible disabled/loading states where applicable, and a polite status region such as `role="status"` for state changes.
- **D-22:** Support light/dark/system behavior using existing app styles or CSS variables. Do not add a theme switcher, component library, decorative redesign, or one-off dark-mode hacks.
- **D-23:** Secondary DX/status labels may show: `Route owner: Phoenix LiveView`, `Capture: native-screen/companion seam`, `Evidence: local/device`, `Authority: backend verification`, and `Storage proof: hermetic mock`.
- **D-24:** Preferred microcopy: "Capture recorded locally; media is not available yet", "Upload failed during simulated network degradation", "Evidence is queued for reconciliation", "Network recovered. Reconciliation can retry", "Device evidence recorded; backend verification still required", "Backend verification in progress", "Backend verified media is available", "Backend rejected this media object", "This proof does not use a real storage provider", and "Local capture evidence does not grant media availability".
- **D-25:** Avoid copy such as "offline uploads work", "background upload guaranteed", "Rindle storage is supported", "media available from device upload", "real S3/GCS upload", "native camera captured", or "local-first sync".
- **D-26:** Update docs/support/operator truth only where Phase 72 changes public proof posture or prevents adopter confusion. The message should be "simulated degradation plus Rindle reconciliation proof", not storage-provider, native-device, or app-wide offline support.

### The Agent's Discretion
- Exact helper/module names for the proof-only queue fixture, deterministic network/degradation fixture, and proof case names, as long as the names do not imply production sync ownership.
- Whether to extend existing example-host media helpers or keep the recovery fixture entirely inside the Phase 72 proof file, as long as the merge gate remains hermetic and product-shaped.
- Exact UI layout and CSS details if `MediaLaneLive` is polished, as long as it stays compact, accessible, support-safe, and consistent with existing Phoenix/LiveView example-host style.
- Exact support/docs/operator files to touch, as long as public truth remains narrow and no provider/device/storage claims are promoted.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and milestone posture
- `.planning/PROJECT.md` - Crosswake thesis, v4.1 milestone posture, backend-owned authority, and media/offline non-claims.
- `.planning/REQUIREMENTS.md` - MED-01, MED-02, and PROOF-01 traceability.
- `.planning/ROADMAP.md` - Phase 72 goal, success criteria, dependency on Phase 71, and phase boundary.
- `.planning/STATE.md` - current v4.1 position and pending concern about deterministic Rindle degradation simulation.
- `.planning/MILESTONE-ARC.md` - multi-SaaS archetype proof goal, Rindle media posture, and non-goals for starter apps/new abstractions.
- `.planning/phases/70-subscription-saas-commerce-proof/70-CONTEXT.md` - immediately relevant archetype-proof precedent: product-shaped hermetic proof, backend authority, adversarial negatives, and CI shape.
- `.planning/phases/71-notification-driven-workflow-proof/71-CONTEXT.md` - immediately prior proof-lane precedent: route/runtime authority, support-safe denials, redaction, hermetic CI, and no provider/device overclaims.

### Rindle media contracts and example-host media lane
- `lib/crosswake/companions/rindle/contracts.ex` - `UploadGrant`, `CaptureEvidence`, `MediaObject`, source vocabulary, backend-verification promotion, and authority/availability metadata rejection.
- `lib/crosswake/companions/rindle/reconciliation.ex` - Rindle reconciliation outcome vocabulary, evidence-only ingestion, replay/idempotency shape, and direct mutation override rejection.
- `lib/crosswake/companions/rindle.ex` - companion state, optional dependency posture, and Rindle surface identity.
- `examples/phoenix_host/lib/crosswake_example/media/mock_capture.ex` - pure-Elixir upload grant and capture evidence emitter.
- `examples/phoenix_host/lib/crosswake_example/media/reconciliation_inbox.ex` - example-host wrapper around Rindle evidence ingestion with replay metadata.
- `examples/phoenix_host/lib/crosswake_example/media/reconciliation_keys.ex` - stable event/subject identity and trace metadata shape; `correlation_id` remains trace-only.
- `examples/phoenix_host/lib/crosswake_example/media/media_projection.ex` - backend-owned media projection and `:available` promotion path.
- `examples/phoenix_host/lib/crosswake_example/media/media_lane_live.ex` - existing compact Phoenix LiveView media proof surface.

### Existing tests and proof-lane patterns
- `test/crosswake/companions/rindle/contracts_test.exs` - contract validation, source vocabulary, backend verification requirements, and trace metadata authority-key rejection.
- `test/crosswake/companions/rindle/reconciliation_test.exs` - reconciliation outcomes, evidence-only ingestion, replay, invalid source, and direct authority/availability override tests.
- `test/crosswake/proof/phase45_rindle_companion_test.exs` - Rindle companion proof posture and optional dependency fail-closed behavior.
- `test/crosswake/proof/phase45_rindle_mock_media_test.exs` - mock media grant/evidence/inbox/projection proof precedent.
- `test/crosswake/proof/phase45_rindle_live_test.exs` - direct `MediaLaneLive` render/`handle_event` proof precedent.
- `test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs` - current archetype proof style, authority matrix, hermeticity self-scan, and example-host module spine.
- `test/crosswake/proof/phase71_notification_workflow_proof_test.exs` - current archetype proof style, redaction guard, inline fixture, and support-safe denial matrix.
- `.github/workflows/phase45-proof.yml` - Rindle hermetic/advisory CI split and promotion guard language.
- `.github/workflows/phase70-proof.yml` - targeted v4.1 proof workflow precedent.
- `.github/workflows/phase71-proof.yml` - targeted v4.1 proof workflow precedent with pinned actions and advisory lane messaging.
- `test/support/proof_assertions.ex` - shared proof assertion helpers.

### Support, docs, and operator truth
- `guides/support_matrix.md` - current media capture, reconciliation, provider/advisory support posture, and support truth language.
- `guides/companions.md` - Rindle companion guide truth and companion positioning.
- `guides/user_flows.md` - user-flow language if Phase 72 updates adopter-facing workflow docs.
- `lib/crosswake/support_matrix/support_matrix.ex` - canonical support truth accessor/data shape if Phase 72 needs support-matrix updates.
- `lib/crosswake/operator_inspection.ex` - operator truth surface if media proof posture becomes inspectable.
- `lib/crosswake/doctor/doctor.ex` and `lib/mix/tasks/crosswake.doctor.ex` - doctor readiness posture if Phase 72 exposes proof truth.

### Prompt corpus and project vision
- `prompts/crosswake-brand-book.md` - boundary-aware brand voice, anti-hype, support-safe microcopy, offline/local-first warnings, and accessible UI posture.
- `prompts/crosswake-elixir-oss-dna.md` - maintainer house style: proof lanes as product, deterministic example-host proof, diagnostics, and public-contract honesty.
- `prompts/crosswake-integrations-and-companions.md` - Rindle media lifecycle, upload/verification path, offline-aware queued media examples, and companion positioning.
- `prompts/crosswake-research-synthesis.md` - runtime-boundary thesis, offline/native/media ladder, and anti-patterns.
- `prompts/elixir-mobile-offlinesupport-stresstest-deep-research.md` - explicit offline boundary, local queue/journal cautions, Phoenix/Ecto reconciliation posture, and no arbitrary offline LiveView.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` - SaaS/media app fit, media pack/upload queue patterns, and native ownership boundaries.
- `prompts/elixir-mobile-apptypes-design-stresstest-deep-research.md` - user-flow and app archetype considerations for media-heavy mobile workflows.
- `prompts/elixir-mobile-oss-lib-deep-research.md` - Elixir/Phoenix OSS library DX and ecosystem posture.

### External ecosystem references considered during discussion
- Ecto `Multi` and `Repo` upsert/transaction documentation - production guidance precedent for host-owned persisted inbox/projector work; not implementation scope for Phase 72.
- Phoenix LiveView and `Phoenix.LiveViewTest` documentation - direct render/event proof and status/loading affordance precedent.
- Android offline-first data-layer guidance - queued write and local-state lessons; Phase 72 borrows the explicitness, not a full mobile sync engine.
- Apple `URLSession` background upload documentation - useful future reference for native/background transfer boundaries; advisory/deferred for Phase 72.
- WAI-ARIA `status` role guidance - accessible polite status-region precedent for `MediaLaneLive` copy changes.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Companions.Rindle.Contracts.UploadGrant` - server-issued permission to upload one media object.
- `Crosswake.Companions.Rindle.Contracts.CaptureEvidence` - typed evidence reported after device/native upload attempts; echoes grant identity and remains non-authoritative.
- `Crosswake.Companions.Rindle.Contracts.MediaObject` - backend-owned media projection with explicit `:queued`, `:uploaded`, `:scanning`, `:available`, and `:rejected` states.
- `Crosswake.Companions.Rindle.Contracts.verified_media_object/2` - only supported promotion path to `:available`; requires `verification_ref` and `authoritative_at`.
- `Crosswake.Companions.Rindle.Reconciliation.ingest_capture_evidence/2` - evidence-only ingestion with outcome vocabulary and idempotency/replay behavior.
- `CrosswakeExample.Media.MockCapture` - pure-Elixir grant/evidence emitter suitable for hermetic Phase 72 fixtures.
- `CrosswakeExample.Media.ReconciliationInbox` - example-host ingestion wrapper that combines Rindle result, stable event key, subject key, replay metadata, and trace metadata.
- `CrosswakeExample.Media.ReconciliationKeys` - stable event identity and trace metadata helper; `correlation_id` stays out of replay identity.
- `CrosswakeExample.Media.MediaProjection` - example-host backend-owned projection and verification path.
- `CrosswakeExample.Media.MediaLaneLive` - existing compact proof surface that can be polished for recovery states.

### Established Patterns
- v4.1 archetype proof lanes are product-shaped, adversarial, deterministic, and CI-hermetic.
- Provider/device/native/storage lanes stay advisory until explicit promotion criteria pass.
- Client/device/provider evidence is never authority; backend-owned projections, reconciliation, and route gates decide sensitive outcomes.
- Example-host proof should be copy-able and useful, but it must not become a starter app or production framework.
- Denial/support truth should be stable, typed, support-safe, and parity-locked across docs/support/operator surfaces when public truth changes.
- Offline claims must distinguish cached/degraded behavior, local queues, offline islands, and server-authoritative commits.

### Integration Points
- New proof file under `test/crosswake/proof/phase72_media_evidence_workflow_proof_test.exs`.
- Possible proof-only helper either inline in that test or under `examples/phoenix_host/lib/crosswake_example/media/` if reuse by `MediaLaneLive` is needed.
- Possible narrow `MediaLaneLive` state/copy updates in `examples/phoenix_host/lib/crosswake_example/media/media_lane_live.ex`.
- Possible docs/support parity updates in `guides/support_matrix.md`, `guides/companions.md`, `guides/user_flows.md`, `lib/crosswake/support_matrix/support_matrix.ex`, `lib/crosswake/operator_inspection.ex`, and doctor surfaces only if the proof changes public truth.
- New targeted CI workflow `.github/workflows/phase72-proof.yml`.

</code_context>

<specifics>
## Specific Ideas

- Preferred proof story: `MockCapture.issue_upload_grant/2` -> proof-only `QueuedCapture` recorded while degraded -> failed upload remains queued/non-authoritative -> recovery drains queue -> `ReconciliationInbox.ingest_capture_evidence/2` -> `MediaProjection.project_object/2` yields `:uploaded` or `:scanning` -> `MediaProjection.project_object/2` with `backend_verified: true` yields `:available`.
- Preferred positive cases: degraded capture recovery, multipart completion requiring full payload, idempotent replay ignoring trace-only correlation changes, and scanning-to-verified promotion.
- Preferred negative cases: stale/expired grant, missing storage key/bytes/idempotency/payload identity, partial multipart treated as completion, corrupt hash, unsupported integrity algorithm, backend scan failure, direct availability override, invalid evidence source, redaction leak, and missing backend fields on `:available`.
- Preferred UI copy: "Capture recorded locally; media is not available yet", "Upload failed during simulated network degradation", "Evidence is queued for reconciliation", "Network recovered. Reconciliation can retry", "Device evidence recorded; backend verification still required", "Backend verification in progress", "Backend verified media is available", "Backend rejected this media object", "This proof does not use a real storage provider", and "Local capture evidence does not grant media availability".
- Preferred DX posture: name the proof spine explicitly as `MockCapture -> ReconciliationInbox -> MediaProjection -> backend verification`, and show where host-owned persistence/storage would plug in without claiming Crosswake provides it.

</specifics>

<deferred>
## Deferred Ideas

- Real Rindle adapter upload/verify behavior as merge-blocking proof.
- Real S3, GCS, Azure, Tus, multipart/resumable upload transport, storage credentials, CDN delivery, signed delivery URLs, variants, thumbnails, transcoding, scanning providers, moderation workflows, and media management UI.
- Native camera/media picker implementation, camera permissions, native shell upload, background transfer, iOS/Android task APIs, device/emulator proof, and real network toggling.
- Ecto-backed durable media outbox tables, migrations, generic sync journal APIs, CRDT/conflict framework, broad local-first mutation claims, and app-wide offline support. Phase 74 owns the broader offline/draft recovery proof.
- Full Phoenix Endpoint/Repo/PubSub/browser LiveView E2E unless implementation uncovers a concrete routing/session bug.
- Threadline-style durable audit trail for media decisions. This belongs to the later audit capstone, not Phase 72.

</deferred>

---

*Phase: 72-media-evidence-workflow-proof*
*Context gathered: 2026-06-05*
