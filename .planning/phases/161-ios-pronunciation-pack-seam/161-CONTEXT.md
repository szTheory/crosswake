# Phase 161: iOS Pronunciation Pack Seam - Context

**Gathered:** 2026-08-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace the iOS shell's simulated `PackStore` success transitions with one requirement-bound,
host-supplied foreground `PackProvider`. Crosswake owns the closed lifecycle, reconciled installed
inventory, activation denial, diagnostics, and proof contract. The host owns archive discovery,
URL/auth/CDN behavior, bytes, staging and storage, size/hash verification, atomic file operations,
archive and lesson layout, codecs, retention, download UI, and final learner copy.

The smallest shippable result supports asynchronous status, install, and invalidate for one
immutable pronunciation archive. Availability follows real expected-size and SHA-256 verification,
same-volume atomic promotion, persisted inventory, and relaunch reconciliation. Phase 161 plugs
deterministic real-byte pack/audio assertions into the existing Phase 159 proof lane; Phase 162
alone promotes the same lane through a physical-iPhone run.

This phase does not add background transfer, delta updates, generic eviction, generic asset lookup,
generic archive storage or distribution, Android work, microphone capture, pronunciation scoring,
a device farm, or a new support taxonomy. TODO-002 and adopter-instance completeness remain
`unknown_blocking`. Phase 160's security report is reconciled with no blocking threats remaining.

</domain>

<decisions>
## Implementation Decisions

### Provider trust boundary

- **D-01:** Add one narrow, versioned Swift `PackProvider` contract with asynchronous
  `status(for:)`, `install(_:)`, and `invalidate(_:)` operations. Each operation consumes an
  immutable `PackRequirement` and returns a closed typed result; arbitrary thrown provider details
  never become lifecycle, diagnostics, or proof data. — **Reversibility:** costly — once external
  iOS hosts implement the protocol, changing callback semantics or result cases requires a native
  compatibility migration.

- **D-02:** `PackRequirement` contains only opaque pack ID, exact required version, expected byte
  count, and expected SHA-256. Exact integrity values live in host-private native configuration,
  not the durable route inventory, public guides, diagnostics, or evidence. URLs, credentials,
  paths, archive names, content layout, codecs, and retention do not cross the provider seam.

- **D-03:** Treat the provider as trusted in-process host code. Crosswake validates that a returned
  installed record exactly binds to the requested ID, version, and size and attests verified
  integrity plus completed atomic promotion. Crosswake does not accept a filesystem URL and
  independently become the archive store. Nil providers, malformed/unknown results, cancellation,
  and operation failures remain non-available.

- **D-04:** The host provider stages a uniquely named artifact in Application Support on the final
  volume, streams SHA-256 off the main actor, compares exact size and digest, atomically
  replaces/promotes only verified bytes, and persists inventory only after commit. Heavy download,
  hashing, and file I/O never run on `@MainActor`.

- **D-05:** Provider operations are serialized per pack. `status` is side-effect-free; `install`
  and `invalidate` are idempotent for the same requirement. Staging files and an install command's
  return alone never grant availability.

### Restart, inventory, and invalidation truth

- **D-06:** On cold launch every required pack starts as `checking`. Crosswake reconciles provider
  storage into its closed inventory before activation. A prior `installing` or `invalidating`
  display state is never resumed optimistically after process death; staged debris is not
  inventory.

- **D-07:** Installation success must be followed by fresh provider status reconciliation before
  Crosswake records `available`. Route resolution within the running process consumes the current
  reconciled inventory rather than synchronously rehashing an archive on every navigation.

- **D-08:** Preserve a committed last-known-good artifact until its replacement is fully verified
  and atomically promoted. A failed update cannot destroy it. If the current declaration requires a
  newer version, retained old bytes are `stale` and route-blocking, not a fallback that silently
  activates.

- **D-09:** Invalidation is a trust-revocation operation, not merely best-effort deletion.
  Crosswake revokes availability before calling the provider, persists pending invalidation across
  relaunch, maps success to `not_installed`, and keeps `invalidation_failed` blocked even when bytes
  remain. Only successful invalidation or a later fully verified reinstall clears the revocation.

- **D-10:** Verification timestamps and last-known version are diagnostic context only. They never
  substitute for exact current requirement reconciliation or create authority.

### Failure and recovery contract

- **D-11:** Preserve the existing high-level lifecycle states: `checking`, `not_installed`,
  `installing`, `available`, `stale`, `invalidating`, and `failed`. Add a closed reason vocabulary:
  `provider_unavailable`, `transfer_interrupted`, `insufficient_storage`, `size_mismatch`,
  `digest_mismatch`, `version_mismatch`, `atomic_install_failed`,
  `inventory_persistence_failed`, `invalidation_failed`, `malformed_provider_result`, and
  `provider_failed`. — **Reversibility:** costly — these values feed host UI, diagnostics, tests,
  and retained low-cardinality proof, so renaming them requires a contract-version migration.

- **D-12:** Provider SDK errors are caught and mapped to the closed reasons. Raw errors, paths,
  URLs, response bodies, archive details, digest values, and file contents never reach telemetry,
  doctor output, inspection, logs, UI defaults, or evidence. Unknown bounded failures map to
  `provider_failed` without echoing input.

- **D-13:** Recovery is explicit and foreground-only: `not_installed` offers Install, `stale`
  offers Update, retryable failure offers Retry, and corrupt/revoked state offers the appropriate
  Invalidate-then-Install path. There is no automatic retry loop, background continuation, or
  silent downgrade to online-only mutation behavior.

- **D-14:** Crosswake exposes semantic state, permitted actions, owning layer, stable reason IDs,
  and stable accessibility identifiers. The host owns final learner copy and presentation. The
  reference/example view uses one primary action per state, text in addition to color, Dynamic
  Type-safe controls, accessible progress/status announcements, stable focus, reduced-motion-safe
  transitions, and system light/dark colors.

- **D-15:** Keep learner copy task-oriented and hide backend mechanics. Example learner failure:
  “Offline audio could not be verified. Try the download again while connected.” Developer
  diagnostics may name the stable rule and owner, for example `PACK-DIGEST-MISMATCH`, host pack
  provider, and the safe remediation. Success copy is brief: “Pronunciation audio is ready for
  offline use.”

### Phase 159 proof hookup and Phase 162 readiness

- **D-16:** Extend the existing generated proof lane rather than creating a new harness. A real
  local immutable fixture archive and a reference host provider are required acceptance evidence;
  fakes remain useful for exhaustive closed-result and failure injection tests but cannot replace
  genuine byte, hash, persistence, and atomic-promotion proof.

- **D-17:** XCTest owns deterministic provider and storage contracts: success from real fixture
  bytes; wrong size/digest/version; interruption; insufficient-storage, write, promotion, and
  persistence failures; same-volume atomic replacement; last-known-good preservation; explicit and
  failed invalidation; per-pack operation serialization; nil/malformed providers; and a newly
  instantiated provider/store proving relaunch reconciliation.

- **D-18:** XCUITest owns only user-observable behavior through stable accessibility identifiers:
  missing-provider denial, foreground installation to ready, terminate/relaunch persistence, and
  installed pronunciation audio playback with networking disabled. It does not inspect Swift
  internals, filesystem paths, archive layout, credentials, or hidden test authority.

- **D-19:** Do not add asset resolution to the public `PackProvider`. Offline-island audio
  consumption remains host-owned. The Phase 159 proof adapter gains only a narrow host-supplied
  operation that exercises installed pronunciation audio and reports the existing closed proof
  outcome; it does not expose archive paths or layout.

- **D-20:** Phase 161 makes deterministic `pack_audio_prerequisite` assertions capable of passing
  with real local bytes. Simulator/native-toolchain execution remains advisory and non-promoting.
  Phase 162 runs the same generated command on a physical iPhone and owns dated promotion.

- **D-21:** Recurring CI may protect Swift contract/fixture behavior, generator drift, failure
  mapping, accessibility identifiers, and privacy scanning. It does not gain a permanent physical
  device lane. Retained evidence contains only approved assertion IDs and closed outcomes—never
  archive bytes, digest values, URLs, paths, media, `.xcresult`, screenshots, logs, or raw output.

### the agent's Discretion

The user selected all four gray areas and delegated a coherent one-shot recommendation after
parallel expert research. Planning may choose exact Swift type and method names, internal actor or
serialization mechanics, private inventory encoding, test-fixture bytes, accessibility identifier
names, and the host-owned proof callback name. It may not weaken the requirement-bound provider,
closed results, relaunch reconciliation, revocation semantics, real-byte proof, host/core ownership,
privacy exclusions, explicit non-passing states, or Phase 161/162 evidence boundary.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Governing first-adopter decisions

- `AGENTS.md` — current priority, workflow, privacy rules, Android freeze, verification posture,
  and stop list.
- `.planning/ADR-FIRST-B2C-ADOPTER.md` — accepted provider ownership, verified atomic install,
  infrastructure framing, iOS-only scope, privacy boundary, and reversal condition.
- `.planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md` — pronunciation-media gap, ownership split,
  testing seam, physical-device sequence, and dated stop rule.
- `.planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md` — pack invariants, unknown-blocking route state,
  study-island boundary, and physical-iPhone exit test.
- `.planning/todos/TODO-002-first-b2c-adopter-route-inputs.md` — unresolved sanitized host input;
  remains blocking for adopter-instance and device-proof promotion.

### Active milestone and prior-phase contracts

- `.planning/PROJECT.md` — Phoenix-first route-policy thesis, first-adopter forcing function, and
  current project truth.
- `.planning/REQUIREMENTS.md` — PACK-01 through PACK-05 and adjacent DEVICE requirements.
- `.planning/ROADMAP.md` — Phase 161 boundary, smallest shippable version, success criteria, target,
  Phase 162 handoff, and stop date.
- `.planning/STATE.md` — current phase, Phase 160 security-report gate, TODO-002, and deferred items.
- `.planning/phases/158-adoption-reset-and-route-map/158-CONTEXT.md` — privacy routing,
  unknown-blocking promotion gate, route-local media posture, and solo-maintainer rule.
- `.planning/phases/159-host-reusable-proof-lane/159-CONTEXT.md` — real XCTest/XCUITest wiring,
  closed prerequisite outcomes, evidence allowlist, process-lifecycle proof, and Phase 161 hookup.
- `.planning/phases/160-scoped-replay-and-auth-safety/160-CONTEXT.md` — scoped replay, backend
  authority, non-echoing operational data, and the adjacent proof-lane contract.

### Current implementation seams

- `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/PackStore.swift` — current lifecycle
  vocabulary, bundled inventory, and simulated timed-success behavior to replace.
- `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift` — pack
  activation gate and install/retry/invalidate integration point.
- `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/ActivationConformanceTests.swift`
  — reusable activation-denial and Swift package test baseline.
- `examples/ios_shell_host/CrosswakeShell/RequiredPackView.swift` — current reference pack UI and
  action surface; host-owned copy and accessibility behavior must remain explicit.
- `lib/crosswake/packs/contracts.ex` — canonical Elixir lifecycle vocabulary and closed failure
  precedent.
- `lib/crosswake/packs/inventory.ex` — installed-inventory truth consumed by activation and shell UI.
- `lib/crosswake/proof_lane/evidence.ex` — existing assertion vocabulary and typed privacy-safe
  retained-evidence boundary.
- `priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex` — generated closed-outcome
  driver and `packAudio` prerequisite seam.
- `priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex`
  — generated XCTest host-adapter contract.
- `priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex` —
  accessibility-driven process and UI proof surface.

### Project research and design DNA

- `prompts/crosswake-research-synthesis.md` — canonical prompt-lineage synthesis: explicit runtime
  ownership, media as a native concern, bounded bridge, and honest proof.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` — host-owned adapters,
  distinct media-pack pressure, semantic boundaries, and compatibility lessons.
- `prompts/elixir-mobile-apptypes-design-stresstest-deep-research.md` — content-pack integrity,
  native file storage, offline-island boundaries, and versioned capability declarations.
- `prompts/elixir-mobile-offlinesupport-flashcard-app-stresstest-deep-research.md` — pronunciation
  media, native storage/playback, restart behavior, and flashcard JTBD pressure.
- `brandbook/BRAND-SPEC.md` — newer canonical brand voice, accessibility/contrast rules, status and
  microcopy guidance, failure-before-customization documentation, and explicit ownership language.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `PackStore`: retain its closed states and observable activation-facing inventory, but replace
  timed simulation and bundled-file authority with provider reconciliation.
- `ActivationCoordinator`: existing `blockingStatus(for:)` and required-pack presentation provide
  the correct fail-closed integration point.
- Elixir pack contracts/inventory: preserve the established state names and typed lifecycle model
  rather than inventing an unrelated Swift vocabulary.
- Phase 159 proof driver, XCTest/XCUITest targets, evidence builder, and generated host adapter:
  extend these seams; do not create a parallel pack test framework.
- `RequiredPackView`: useful as a reference/example for semantic action and accessibility tests,
  but not authority over host copy, archive policy, or download UI.

### Established Patterns

- Canonical contracts are typed, versioned, low-frequency, and fail closed.
- Host integration code is explicit and host-owned; library-owned invariants remain closed and
  drift-tested.
- Phoenix/Elixir-style consumer ergonomics favor one behaviour/protocol, structured inputs, and
  closed `ok/error` outcomes over provider-shaped exceptions or a free-form metadata bag.
- Real state is proven before promotion; a requested action or timed UI transition is not evidence.
- Privacy-safe diagnostics and proof use allowlists, low-cardinality values, stable rule IDs, and
  non-echoing failures.
- XCTest owns deterministic values/contracts while XCUITest owns accessible user-observable process
  behavior. Simulator and device evidence have different promotion authority.

### Integration Points

- Add the provider and requirement/result types in `CrosswakeShellCore`, then inject the provider
  through the existing shell configuration/coordinator construction path.
- Rework `PackStore` bootstrap and operations around provider reconciliation and persisted
  invalidation intent.
- Keep route activation dependent on reconciled Crosswake inventory.
- Extend existing Swift package tests, example iOS host, generated proof adapter/driver, and
  privacy-safe evidence assertion set.
- Preserve existing generated/browser proof and Android hermetic posture unchanged except where a
  shared contract requires cheap regression maintenance.

</code_context>

<specifics>
## Specific Ideas

- Consumer API principle: optimize the public provider for the Phoenix/iOS host maintainer's job—
  report whether an exact declared pack is installed, install it, or invalidate it—not for the
  provider implementer's internal downloader or archive layout.
- Learner JTBD: before connectivity disappears, know whether pronunciation audio is genuinely
  ready; if it is not, receive one understandable action rather than storage or checksum details.
- Follow successful offline/update systems selectively: explicit native runtime compatibility,
  verification before promotion, preserved last-known-good bytes, documented restart limits, and
  host/domain authority. Do not copy generic sync, background media, platform-managed eviction, or
  content-distribution breadth.
- Apple implementation references for research/planning: Application Support storage,
  `URLSessionDownloadTask` temporary-file lifecycle, CryptoKit incremental SHA-256, and
  `FileManager.replaceItemAt` same-volume replacement semantics.
- Apple On-Demand Resources is not the model: it conflicts with authenticated host CDN ownership,
  can be evicted, and is deprecated for new direction.

</specifics>

<deferred>
## Deferred Ideas

- Server-signed pack receipts, shared publisher provenance, generic asset resolution, background or
  resumable transfer, delta updates, storage-budget/eviction policy, and generic archive layout wait
  for the ADR reversal condition or demonstrated physical-device need.
- Phase 162 owns the physical-iPhone run, dated retained artifact, and support-claim promotion.
- Android pack storage, device proof, and parity work remain frozen.
- Microphone capture, offline pronunciation scoring, transcripts, and native audio-player breadth
  remain outside v21.

</deferred>

---

*Phase: 161-ios-pronunciation-pack-seam*
*Context gathered: 2026-08-03*
