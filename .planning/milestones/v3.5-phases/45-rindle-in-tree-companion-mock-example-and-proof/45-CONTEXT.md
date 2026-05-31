# Phase 45: Rindle In-Tree Companion, Mock Example, And Proof - Context

**Gathered:** 2026-05-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the working Rindle companion implementation, the pure-Elixir
`phoenix_host` mock upload/verify lane, and the hermetic/advisory proof posture
that demonstrates the companion seam generalizes beyond feature flags.

**Delivers:**
- `Crosswake.Companions.Rindle` satisfying `Crosswake.Companion` with
  `companion_id: :rindle` and fail-closed optional-dependency validation.
- A narrow core helper surface for invariant media identity and authority-lane
  fences, if needed by the planner, while keeping app workflow orchestration in
  `examples/phoenix_host`.
- A pure-Elixir example-host media lane that drives a `MediaObject` through
  `:queued -> :uploaded -> :scanning -> :available` with no external SDK.
- Proof that stable grant/idempotency identity, replay detection, and
  non-authoritative device evidence hold under retry.
- Hermetic CI that passes without the optional `rindle` dependency and advisory
  CI that checks dependency-present behavior without becoming merge-blocking.

**Satisfies:** MEDIA-03 and the Phase 45 share of PROOF-01.

**In scope:**
- `lib/crosswake/companions/rindle.ex` or equivalent in-tree companion module.
- `mix.exs` conditional optional dependency wiring for `rindle`.
- Example-host mock modules under `examples/phoenix_host/lib/crosswake_example/media/`.
- A LiveView proof route in `examples/phoenix_host` that shows the honest media
  lane states.
- Hermetic proof tests for companion fail-closed behavior and media lane
  invariants.
- Advisory-only proof that `validate_dependency/0 == :ok` when `rindle` is
  present.

**Out of scope:**
- Real Rindle upload/storage/variant adapter behavior. Phase 45 proves the seam
  and optional dependency boundary, not production media processing.
- Tus, multipart, S3/GCS/Azure SDKs, resumable transport, virus scanning,
  thumbnails, variants, CDN delivery, or native capture implementation.
- High-frequency upload progress over the Crosswake semantic bridge.
- Claiming queued media is committed, visible as authoritative, or available.
- Full companion guide expansion; Phase 47 owns the cross-companion guide.

</domain>

<decisions>
## Implementation Decisions

### 1. Mock Surface And API Boundary - LOCKED
- **D-01:** Use a split design: core owns invariant primitives and the companion
  contract; `examples/phoenix_host` owns the mock upload/verify workflow. Do not
  ship a full public mock workflow as library API.
- **D-02:** The planner may add a narrow core helper module under
  `Crosswake.Companions.Rindle` only for invariant logic that belongs near the
  contracts, such as stable idempotency/event-key derivation or authority-lane
  guard helpers. It must not become a generic upload framework.
- **D-03:** Example-host orchestration lives under
  `examples/phoenix_host/lib/crosswake_example/media/`, following the commerce
  archetype pattern where mock evidence is pure Elixir and provider-neutral.
- **D-04:** Recommended example modules:
  `CrosswakeExample.Media.MockCapture`,
  `CrosswakeExample.Media.ReconciliationInbox`,
  `CrosswakeExample.Media.MediaProjection`, and
  `CrosswakeExample.Media.ProofLive` or `MediaLaneLive`. Planner may adjust names
  for local consistency, but keep the mock/projection/LiveView responsibilities
  separate.
- **D-05:** The mock capture API should be function-level and deterministic:
  grant creation, upload evidence emission, backend verify/projection, and
  derived state are separate steps. Avoid one `upload_and_verify/1` shortcut that
  hides the authority boundary.
- **D-06:** Stable identity derives from backend-issued `grant_id` and
  `idempotency_key` plus event kind/storage target. `correlation_id`, local queue
  IDs, progress events, timestamps, and storage ETags are trace metadata only.
- **D-07:** Replay proof must show that the same grant/idempotency pair with a
  changed `correlation_id` yields the same event/idempotency key and is marked
  `replay?: true`, never promoted to availability.

### 2. Example-Host Flow - LOCKED
- **D-08:** Use a LiveView-first proof route backed by explicit media modules.
  This is the most idiomatic Phoenix teaching surface for the existing
  `phoenix_host`, and it mirrors the Phase 34/35 commerce walkthrough shape.
- **D-09:** Add a route under `/media`, recommended path `/media/proof`, with
  route policy `runtime: :live_view`, `offline: :unavailable` or the existing
  conservative default, and no claim that the LiveView itself is an offline
  capture runtime.
- **D-10:** The proof route should expose the lane as user-visible states:
  `queued`, `uploaded`, `scanning`, `available`, and rejected/failure where
  useful. The copy must make clear:
  - `queued` means local/server-pending intent only, not committed media.
  - `uploaded` means device evidence was recorded, not availability.
  - `scanning` means backend-owned verification is in progress.
  - `available` appears only after explicit backend verification/projection.
- **D-11:** The LiveView may use buttons or deterministic test messages to drive
  transitions, but the important proof path is module-based:
  `MockCapture` -> `ReconciliationInbox.ingest_capture_evidence/2` ->
  `MediaProjection.project_object/2` or equivalent -> derived display state.
- **D-12:** Do not add controller/API endpoints unless the planner needs a small
  route for proof ergonomics. A controller-first implementation is more
  realistic for uploads but less useful for this phase than a clear LiveView
  walkthrough.
- **D-13:** Do not add native shell, bridge, simulator, or actual file upload
  code in Phase 45. Native capture simulation is deferred so this phase stays
  hermetic and does not imply SDK support.

### 3. Rindle Companion Implementation - LOCKED
- **D-14:** Add `Crosswake.Companions.Rindle` as the second concrete in-tree
  companion. It must satisfy all six `Crosswake.Companion` callbacks and return
  `companion_id: :rindle`.
- **D-15:** `validate_dependency/0` checks only `Code.ensure_loaded?(Rindle)` and
  returns `:ok` when the optional library is present or `{:error, [Rindle]}` when
  absent, matching the Phase 38/42 Swoosh-style missing-module pattern.
- **D-16:** Because the media seam is not a route gate in this phase,
  `route_gated?/2` should return `:pass` and `kill_switch_active?/1` should
  return `false` unless the planner finds an already-shipped route-policy hook
  requiring a stricter posture. Do not invent a new Rindle route-policy DSL in
  Phase 45.
- **D-17:** `report_state/0` should return a `Crosswake.Companion.State` with
  `companion_id: :rindle`, config-derived `enabled`, dependency status, and
  non-gating statuses such as `:unconfigured`/`:inactive` consistent with the
  existing `State` fields.
- **D-18:** Avoid compile-time references to optional `Rindle` APIs outside
  `Code.ensure_loaded?/1` checks. Any real adapter calls are future work and must
  not leak into the hermetic lane.

### 4. Proof And CI Posture - LOCKED
- **D-19:** Mirror the Phase 43 proof split for Rindle:
  `MIX_INCLUDE_RINDLE=1` includes the optional dep in advisory CI; the hermetic
  lane runs without it.
- **D-20:** Add a dedicated Phase 45 proof workflow, recommended
  `.github/workflows/phase45-proof.yml`, with:
  - merge-blocking hermetic job running without `rindle`
  - advisory job with `continue-on-error: true`, schedule + workflow_dispatch,
    and `MIX_INCLUDE_RINDLE=1`
  - promotion-path comments modeled on `phase34-proof.yml`/`phase43-proof.yml`
- **D-21:** Keep advisory assertions in a separate `@moduletag :advisory_only`
  test file, e.g. `test/crosswake/proof/phase45_rindle_advisory_test.exs`, so
  absent-vs-present dependency assertions never fight in the same test file.
- **D-22:** Hermetic proof should include:
  - `Crosswake.Companions.Rindle.validate_dependency/0` fails closed when absent.
  - `mix crosswake.doctor` emits `companion.dependency_missing` when Rindle is
    enabled but missing.
  - The mock lane creates valid grants/evidence/media objects via Phase 44
    contracts.
  - Mandatory idempotency is enforced; missing or mismatched grant/idempotency
    identity fails.
  - Device evidence can produce `:uploaded`/`:scanning` but cannot produce
    `:available` without explicit backend verification.
  - `:queued` is never rendered or treated as committed media.
- **D-23:** Do not use fake `Rindle` fixture modules as the advisory signal if
  the real optional dependency can be included. Fake modules create false
  confidence and module-name collision risk.

### 5. Ecosystem Lessons To Preserve - LOCKED
- **D-24:** Import the useful Active Storage lesson: direct upload identity and
  blob/upload records are useful, but upload completion is not the same as
  attached/available application authority.
- **D-25:** Import the useful Shrine lesson: cache-to-store/promotion is a
  backend-owned step; background promotion must be distinguishable from finished
  storage.
- **D-26:** Import the useful Stripe lesson: idempotency keys must be stable and
  backend-recognized, and retry identity must not be derived from transient
  request/correlation data.
- **D-27:** Import the Elixir optional-integration lesson from Mix/Swoosh/Tesla
  style libraries: optional dependency surfaces must compile without the
  optional dep, document what is needed, and fail clearly when enabled but
  missing.

### the agent's Discretion
- Exact names of the media example modules and LiveView route are planner
  discretion if the responsibilities above remain distinct.
- Whether invariant idempotency/event-key helpers live in a small core module or
  entirely inside example-host modules is planner discretion. Bias toward core
  only when the helper protects a reusable Crosswake contract invariant.
- Exact `phase45-proof.yml` runner, timeout, and cron timing should follow the
  nearest existing workflow pattern.
- Exact rejected/failure state coverage is planner discretion, but the happy path
  and non-authoritative evidence fence are mandatory.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` section "Phase 45: Rindle In-Tree Companion, Mock
  Example, And Proof" - authoritative goal and success criteria.
- `.planning/REQUIREMENTS.md` section "MEDIA - Rindle Media Seam
  (generalization proof)" - MEDIA-03.
- `.planning/REQUIREMENTS.md` section "PROOF - Proof Lanes & Docs Contract" -
  PROOF-01 posture shared with Phase 45.
- `.planning/PROJECT.md` - Crosswake thesis, v3.5 scope, companion guardrails,
  and non-goals.
- `.planning/MILESTONE-ARC.md` - strategic companion sequencing and bounded seam
  posture.

### Locked Rindle contracts from Phase 44
- `.planning/phases/44-rindle-media-seam-contracts-and-reconciliation-vocabulary/44-CONTEXT.md`
  - D-20 through D-22 are direct handoff requirements for Phase 45.
- `lib/crosswake/companions/rindle/contracts.ex` - `UploadGrant`,
  `CaptureEvidence`, `MediaObject`, validators, and backend verification helper.
- `lib/crosswake/companions/rindle/reconciliation.ex` - outcome vocabulary,
  `ingest_capture_evidence/2`, replay marking, and availability mutation fence.
- `test/crosswake/companions/rindle/contracts_test.exs` - Phase 44 contract proof
  shape.
- `test/crosswake/companions/rindle/reconciliation_test.exs` - Phase 44
  reconciliation proof shape.

### Companion and optional-dependency precedent
- `lib/crosswake/companion.ex` - required companion callbacks.
- `lib/crosswake/companion/state.ex` - state struct returned by `report_state/0`.
- `lib/crosswake/companions/rulestead.ex` - first concrete companion and
  `Code.ensure_loaded?/1` pattern.
- `.planning/phases/42-rulestead-in-tree-companion-and-mock-example/42-CONTEXT.md`
  - in-tree companion + mock-source decisions.
- `.planning/phases/43-rulestead-hermetic-advisory-proof-and-guide/43-CONTEXT.md`
  - optional-dep isolation, advisory proof, and docs posture.
- `test/crosswake/proof/phase42_rulestead_companion_test.exs` - hermetic
  companion proof style.
- `test/crosswake/proof/phase43_rulestead_advisory_test.exs` - advisory-only
  dependency-present assertion pattern.

### Commerce mock and projection precedent
- `examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex` -
  pure-Elixir mock evidence emitter pattern.
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex`
  - evidence-only ingestion and replay detection shape.
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex`
  - stable event/subject key derivation with trace-only correlation metadata.
- `examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex` -
  explicit backend verification/projection bridge.
- `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex`
  - authoritative projection and derived display state precedent.
- `test/crosswake/proof/phase34_mock_storefront_test.exs` - idempotency/replay
  proof pattern.
- `test/crosswake/proof/phase35_paywall_live_test.exs` - LiveView state proof
  pattern.

### CI proof patterns
- `.github/workflows/phase34-proof.yml` - hermetic + advisory split and
  promotion path template.
- `.github/workflows/phase43-proof.yml` - direct optional-dep proof template for
  a first-party companion.
- `mix.exs` - conditional optional dependency wiring target.

### Prompt research and project-specific constraints
- `prompts/crosswake-elixir-oss-dna.md` - install truth, proof lanes, optional
  dependency honesty, and OSS house style.
- `prompts/crosswake-integrations-and-companions.md` - Rindle companion
  classification and intended value.
- `prompts/crosswake-research-synthesis.md` - route ownership and bounded bridge
  thesis.
- `prompts/elixir-mobile-offlinesupport-stresstest-deep-research.md` - offline
  claims and reconciliation boundaries.
- `prompts/elixir-mobile-offlinesupport-flashcard-app-stresstest-deep-research.md`
  - queued media/content pack/offline island lessons.

### External ecosystem references used for decision calibration
- `https://guides.rubyonrails.org/active_storage_overview.html` - Active Storage
  direct upload/analyze/attach lessons.
- `https://shrinerb.com/docs/plugins/backgrounding` - Shrine cache/promote and
  backgrounding lessons.
- `https://docs.stripe.com/api/idempotent_requests` - stable idempotency key and
  retry semantics.
- `https://hexdocs.pm/mix/Mix.Tasks.Deps.html` - Mix optional dependency
  compilation guidance.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Companions.Rindle.Contracts` - already provides grant, evidence,
  media object structs and validation; Phase 45 should consume, not re-model.
- `Crosswake.Companions.Rindle.Reconciliation` - already provides
  `ingest_capture_evidence/2`, idempotency key struct, replay detection, and the
  authority mutation fence.
- `Crosswake.Companions.Rulestead` - companion implementation and
  optional-dependency pattern to mirror.
- `CrosswakeExample.Commerce.MockStorefront` - pure-Elixir mock emitter pattern
  for example-host lanes.
- `CrosswakeExample.Commerce.MockBackend` and `EntitlementProjection` - explicit
  backend verification/projection pattern for moving from evidence to authority.

### Established Patterns
- First-party companions live in-tree and implement the six-callback
  `Crosswake.Companion` behaviour.
- Optional dependencies are checked by `Code.ensure_loaded?/1`, with doctor
  emitting fail-closed findings when enabled but missing.
- Example-host proof lanes teach adopter-shaped workflows while core code keeps
  the semantic contracts narrow.
- Hermetic lanes stay merge-blocking; advisory provider/optional-dep lanes are
  visible but non-blocking until promotion conditions are met.
- Proof tests avoid example-host runtime boot when pure modules can be
  `Code.require_file`d or called directly.

### Integration Points
- `mix.exs` `deps/0` - add `MIX_INCLUDE_RINDLE` conditional dependency logic
  without disturbing the existing `MIX_INCLUDE_RULESTEAD` path.
- `examples/phoenix_host/lib/crosswake_example/router.ex` - add the `/media`
  scope and proof LiveView route.
- `examples/phoenix_host/lib/crosswake_example/media/` - new example-host media
  lane modules.
- `test/crosswake/proof/` - Phase 45 hermetic/advisory proof files.
- `.github/workflows/` - new phase-specific proof workflow.

</code_context>

<specifics>
## Specific Ideas

- Sub-agent research converged on a single coherent recommendation:
  split invariant helpers in core from host-owned mock orchestration, use a
  LiveView proof route for adopter DX, and mirror Phase 43 for optional-dep
  proof.
- Preferred proof page path: `/media/proof`.
- Preferred example lane shape:
  `MockCapture` emits capture evidence from a grant,
  `ReconciliationInbox` records evidence-only attempts,
  `MediaProjection` performs explicit backend verification,
  `ProofLive` shows the honest derived state.
- The proof page should be clear but not overbuilt. It is a teaching artifact,
  not a product-grade upload UI.
- The phrase to preserve for docs/proof copy: queued media is never committed
  media; uploaded evidence is never available media.

</specifics>

<deferred>
## Deferred Ideas

- Real Rindle adapter that calls actual Rindle APIs for upload, verification,
  variants, storage, or delivery.
- Native capture screen and bridge-level media handoff demonstration.
- Upload progress, resumability, multipart handling, Tus/S3/provider adapters,
  thumbnails, virus scanning, and CDN delivery.
- `Crosswake.Companions.Rindle.MockUpload` as a public reusable mock workflow API.
  Reconsider only if multiple adopter examples need the same workflow and the
  boundary can stay narrow.
- Rindle guide section and cross-companion docs-contract parity. Phase 47 owns
  full guide expansion.

</deferred>

---

*Phase: 45-rindle-in-tree-companion-mock-example-and-proof*
*Context gathered: 2026-05-31*
