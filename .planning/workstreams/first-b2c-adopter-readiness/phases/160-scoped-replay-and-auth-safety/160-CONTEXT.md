# Phase 160: Scoped Replay and Auth Safety - Context

**Gathered:** 2026-08-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the existing single study-island journal and replay path safe for real account authority.
Every local journal entry and replay request carries a sensitive opaque scope reference; local
outbox access is mechanically partitioned by that scope; logout and account switching fence replay
before authority changes; and the Phoenix endpoint re-checks current scope, route policy, backend
session authority, host authorization, and host-owned feature state before each mutation is applied.

The same work must ensure raw answer payloads and identity-bearing replay/auth data cannot escape
through telemetry, Logger, doctor, operator inspection, aggregates, or retained proof evidence.
`crosswake_sigra` remains an optional adapter from backend session authority to a closed replay
decision, never a credential, token, provider, device-identity, or account authority.

This phase extends the Phase 159 host-owned proof lane with scoped replay/auth assertions. It does
not supply missing adopter route rows, invent host account or flag values, implement a generic sync
engine, add background replay, create a Crosswake flag service, own host retention/encryption, add
Android scope, or promote a physical-device claim. TODO-002 and adopter-instance completeness remain
`unknown_blocking`.

</domain>

<decisions>
## Implementation Decisions

### Scope lifecycle and account switching

- **D-01:** `scope_ref` is a required, versioned, opaque host-issued value on every
  `Journal.Entry` and `Replay.Request`. It has no embedded account, route, token, provider, device,
  or payload meaning. Crosswake validates only a conservative bounded transport shape and equality;
  the host maps it to current backend authority and owns issuance, stability/rotation, and
  revocation. Treat the value itself as sensitive even though it is opaque. — **Reversibility:
  one-way** — once generated clients persist scoped entries and endpoints accept the envelope,
  removing or changing the field requires a storage and wire migration.

- **D-02:** Use one outbox store with scope in the key/index boundary, not a deterministic account
  digest and not a Crosswake-managed database per account. Entries, checkpoints, conflicts, and any
  replay lease are addressed through compound `(scope_ref, local_ref)` keys or equivalent scoped
  indexes. The replay API requires a scope and offers no production path that loads or drains an
  unscoped `all` outbox.

- **D-03:** Persist a small lifecycle fence alongside the store with closed states equivalent to
  `inactive`, `active`, and `stopping`, plus a monotonic epoch. On cold launch or relaunch, retained
  partitions are inert: no payload is displayed and no replay starts until the host establishes a
  backend-authorized active scope.

- **D-04:** Logout/account switch is a fence-first transition: transactionally leave `active`,
  increment the epoch, prevent new reads/sends, cancel or await the scoped worker, and only then
  permit a newly authenticated scope to activate. A completion from an older epoch may affect
  neither the current UI nor a new scope. Preserve ambiguous old entries for later idempotent
  resolution rather than deleting them from a stale callback.

- **D-05:** Missing, malformed, inactive, or mismatched scope fails closed as a visible blocked
  state with the queue preserved. There is no fallback to an unscoped/default partition, current
  cookies alone, or a newly active account. An in-flight request cannot be unsent, so the server
  independently derives current authority and rejects cross-scope application.

- **D-06:** Crosswake supplies scope-targeted lifecycle primitives and tests only. The host owns
  account mapping, local encryption choice, retention duration, logout cleanup/deletion policy,
  and any recovery flow that reauthorizes a retained partition. Core never enumerates account
  identities or derives scope from account data.

### Replay authorization and disablement

- **D-07:** Replay sends a bounded batch for exactly one active scope and drains it serially in
  journal order. Re-check dynamic admission immediately before every event rather than taking one
  batch-long authorization/flag snapshot. This intentionally favors a small, bounded authority
  window and simple recovery over high-throughput generic sync.

- **D-08:** The host endpoint follows one explicit fail-closed order: enforce transport/body/batch
  limits and closed envelope shape without echoing values; resolve the current backend session;
  derive and compare its host-mapped scope; resolve the declared route; evaluate dependency and
  existing `gated_by`/kill-switch state; evaluate current `crosswake_sigra` route/session evidence;
  run host route/domain authorization; then apply the event. Missing adapters, unknown results,
  exceptions, timeouts, or malformed results deny rather than skip a layer.

- **D-09:** Apply one event in one host-owned `Ecto.Multi`/`Repo.transaction` boundary that records
  the idempotency decision and domain effect atomically. A retry after a lost response returns the
  already-recorded closed outcome and never repeats the effect. Do not parallelize a scope's drain.
  Crosswake defines the semantic callback/result contract but does not own the host Repo, schema,
  mutation changeset, or domain reconciliation.

- **D-10:** The guarantee is precise: after disablement, revocation, logout, or a scope change is
  observed, no new event begins application. An event already committed remains committed; stronger
  serialization against host auth/flag state is host-owned and is not a Crosswake control plane.
  If physical-device evidence proves that boundary insufficient, the governing ADR must be
  revisited rather than quietly adding flag tables or locks.

- **D-11:** Preserve explicit event outcomes: `accepted`, `rejected`, and `conflict`, and add a
  closed `blocked` admission state. An idempotent duplicate of a previously accepted event is
  returned as accepted so the client can remove it. Rejected and conflict entries remain available
  for host-owned recovery. A blocked result halts the remaining drain and retains every unaccepted
  entry without a hot retry loop.

- **D-12:** Separate request admission from event results using conventional Phoenix HTTP
  semantics. Unauthenticated or wholly denied requests use an appropriate non-success status with
  a typed, non-echoing blocked body. A valid request that applied earlier events before a later gate
  changed returns a successful typed batch envelope containing the accepted outcomes and the closed
  halt reason. Do not use `207 Multi-Status` or encode domain outcomes as free-form HTTP errors.

- **D-13:** The existing host-owned `gated_by` source is evaluated at both route entry and replay.
  Feature disablement preserves the scoped queue and exposes a host-rendered paused state; it never
  deletes data, silently changes the route to online-only, continues replay, or creates a Crosswake
  remote-config service.

- **D-14:** Extend the Phase 159 generated ExUnit, Playwright, XCTest/XCUITest, and evidence seams,
  rather than creating another proof system. Required cases include two scopes, logout/account
  switch before send and during an in-flight request, relaunch without authority, Nth-event
  disable/revocation, cross-scope endpoint mismatch, transaction rollback plus lost-response retry,
  duplicate idempotency, rejection/conflict retention, and blocked-as-non-passing native proof.

### Privacy-safe auth and observability surfaces

- **D-15:** Maintain two deliberately different data planes. Sensitive wire/domain structures may
  contain `scope_ref`, payload, event/idempotency/checkpoint references, and host reconciliation
  data because replay needs them. They are never directly inspectable or loggable. A separate
  versioned safe-observation type is the only input accepted by Crosswake telemetry, default
  logging, doctor, inspection, aggregates, and retained evidence.

- **D-16:** Define one closed observation vocabulary, then project an exact smaller allowlist for
  each surface. The shared vocabulary may include declared opaque route ID, contract/schema/runtime
  versions, a closed replay lifecycle/outcome, a coarse denial class such as `auth_required`,
  `authorization_denied`, `feature_disabled`, `scope_inactive`, or `transport_unavailable`, plus
  bounded counts/durations where that surface genuinely needs them. Unknown keys or values fail
  before serialization with only a stable rule ID and safe key/path. — **Reversibility: costly** —
  the vocabulary becomes a public telemetry and proof contract whose incompatible changes require
  explicit schema/version adapters.

- **D-17:** Never place scope references, raw/selected/free-form answers, mutation payloads,
  journal/event/idempotency/correlation references, checkpoints, authoritative response maps, raw
  rejection reasons, account/session/provider/device identity, credentials, tokens, exact auth
  ages, Sigra challenge/handoff/return references, endpoints, flag names, or media into an
  observable projection. Do not hash those values; a stable digest is still a correlating
  identifier.

- **D-18:** Surface-specific ceilings stay narrow: telemetry/logging receive route plus closed
  lifecycle/outcome/denial and measurements; doctor reports static configuration and adapter
  readiness only; operator inspection reports route-policy/contract readiness and never enumerates
  outbox content or active scopes; retained evidence keeps Phase 159's exact schema and adds only
  named Phase 160 assertion IDs with closed results. No surface gains a free-form metadata/details
  bag.

- **D-19:** Build safe output by allowlist before serialization and retain Phase 159's final-byte
  scan before evidence promotion. Existing forbidden-key denylists remain defense in depth for
  host-supplied telemetry, not the primary privacy boundary. Any helper capable of serializing a
  wire request/outcome must be clearly separated from safe projection helpers so library consumers
  cannot confuse operational transport with diagnostics.

- **D-20:** `crosswake_sigra` consumes host/backend session-authority evidence through the existing
  optional companion boundary and returns only `allow` or `deny` with a closed safe class to core.
  Exact session records and denial details stay inside the host/Sigra authorization path. Core does
  not gain credentials, provider adapters, MFA challenges, token refresh, device identity, or
  account lookup authority; an absent or incompatible companion is an explicit denial.

- **D-21:** Errors have two audiences. User-facing host copy is calm and task-oriented—e.g.
  **“Sync is paused. Your saved changes remain on this device. Sign in again or try later.”** It
  does not expose flags, scopes, tokens, transactions, or backend internals. Developer/operator
  output names a stable rule, owning layer, and safe remediation without echoing rejected input.

- **D-22:** Privacy proof uses positive schema tests plus negative/property-style injection of
  forbidden keys, aliases, nested values, printable payload canaries, and opaque identifiers
  through every egress. Tests assert the forbidden bytes never appear in telemetry callbacks,
  Logger output, doctor, inspection, aggregates, generated artifacts, or final retained evidence;
  deletion/omission of a protected path must make the lane fail.

- **D-23:** This phase does not create a new visual system. Where the generated host exposes replay
  state, optimize the learner JTBD—know whether work is saved, syncing, needs attention, or is
  safely paused—using a closed state model, brief host-owned copy, `role="status"`/appropriate live
  regions, text plus semantic status rather than color alone, stable focus, and the existing
  light/dark/system tokens from `brandbook/BRAND-SPEC.md`. Avoid spinners that imply progress while
  blocked and avoid exposing backend implementation vocabulary.

### the agent's Discretion

The user selected every area and delegated a one-shot, research-backed recommendation. Planning
may choose exact private module/function names, conservative scope-ref syntax/length, IndexedDB
schema-migration mechanics, bounded batch ceiling, retry/backoff timings, precise safe rule IDs,
and test-file organization. It may not weaken scope-required storage access, fence-before-switch
ordering, per-event backend admission, one-event idempotent transactions, retained blocked data,
Sigra's non-authoritative adapter boundary, per-surface allowlists, or non-echoing evidence safety.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Governing first-adopter decisions

- `AGENTS.md` — repository priority, workflow, privacy rules, Android freeze, and stop list.
- `.planning/ADR-FIRST-B2C-ADOPTER.md` — scope-bound sensitive payload decision, host replay/auth
  authority, host-owned disablement, executable verification, non-goals, and reversal conditions.
- `.planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md` — full replay/privacy/auth ownership model,
  stakeholder lenses, proof seam, and dated sequence.
- `.planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md` — route-local scope/logout/account-switch,
  replay, disablement, retention, evidence, and physical-iPhone invariants.
- `.planning/todos/TODO-002-first-b2c-adopter-route-inputs.md` — unresolved sanitized host inputs;
  remains `unknown_blocking` and must not be inferred during Phase 160.

### Active milestone and prior-phase contracts

- `.planning/PROJECT.md` — Phoenix-first thesis, bounded offline claim, auth ownership, and current
  milestone truth.
- `.planning/REQUIREMENTS.md` — SCOPE-01 through SCOPE-05 and v21 non-goals.
- `.planning/ROADMAP.md` — Phase 160 smallest shippable version, success criteria, two-day boundary,
  downstream dependencies, and stop date.
- `.planning/STATE.md` — current position, blockers, settled Phase 158/159 decisions, and unrelated
  `.planning/config.json` working-tree warning.
- `.planning/phases/158-adoption-reset-and-route-map/158-CONTEXT.md` — route-local safety fields,
  explicit unknowns, privacy routing, promotion gate, and non-echoing validation.
- `.planning/phases/159-host-reusable-proof-lane/159-CONTEXT.md` — generated host proof boundary,
  device driver seam, exact retained-evidence schema, allowlist/scanner rules, and later-phase
  blocked states.

### Current architecture and design research

- `prompts/crosswake-research-synthesis.md` — current route-owner architecture and bounded offline
  and bridge conclusions.
- `prompts/crosswake-elixir-oss-dna.md` — Phoenix library DX, host/library ownership, optional
  companions, doctor, proof lanes, and public-contract honesty.
- `prompts/crosswake-gsd-project-brief.md` — Phoenix/Ecto authority, offline-island semantics,
  failure visibility, and consumer-facing public API priorities.
- `prompts/ARCHITECTURE-CODE-WALKTHROUGH-DNA.md` — ownership-first conceptual spine and explicit
  fail-closed boundary guidance.
- `prompts/elixir-mobile-offlinesupport-flashcard-app-stresstest-deep-research.md` — append-only
  study events, idempotent reconciliation, scoped local state, and learner sync JTBD.
- `prompts/elixir-mobile-offlinesupport-stresstest-deep-research.md` — Phoenix endpoint/Ecto
  authority, outbox design alternatives, recovery states, proof strategy, and sync footguns.
- `prompts/elixir-mobile-apptypes-design-stresstest-deep-research.md` — lessons from scoped
  offline systems, auth-expiration pauses, and explicit local-first/non-claim boundaries.
- `brandbook/BRAND-SPEC.md` — current voice, status microcopy, accessibility, semantic tokens, and
  light/dark/system behavior; supersedes the old brand prompt.

### Existing runtime, auth, and proof seams

- `lib/crosswake/offline/journal.ex` — currently unscoped journal entry and sensitive payload
  serializer requiring migration.
- `lib/crosswake/offline/replay.ex` — currently unscoped request/outcome wire contract and broad
  `authoritative_state`/`reason` serialization boundary.
- `lib/crosswake/offline/runtime.ex` — study-session runtime and queue-entry seam.
- `examples/phoenix_host/priv/static/offline_study.js` — current single-store unscoped browser
  outbox, batch flush, status copy, and accepted-entry deletion behavior.
- `examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex` — current Phoenix
  replay controller without explicit session/scope/route/flag admission.
- `examples/phoenix_host/lib/crosswake_example/local_first/study.ex` — current Ecto changeset,
  `insert_all`, idempotency, and response shape to replace with per-event authority boundaries.
- `packages/crosswake_sigra/lib/crosswake/companions/sigra.ex` — optional companion boundary and
  current backend session-authority projection entrypoints.
- `lib/crosswake/telemetry.ex` — current documented metadata schemas, default logger, and denylist
  scrubbing that Phase 160 must harden with safe projections.
- `lib/crosswake/shell/diagnostic_export.ex` — allowlist-by-construction and forbidden-key precedent.
- `examples/phoenix_host/e2e/support/offline_route_proof.ts` — primary browser proof and current
  unscoped outbox/backend/idempotency assertions.
- `examples/phoenix_host/e2e/crosswake_proof_lane/proof_lane.spec.ts` — generated host-owned proof
  integration point from Phase 159.
- `test/crosswake/offline/journal_test.exs` — journal contract test seam.
- `test/crosswake/offline/replay_test.exs` — replay request/outcome contract test seam.
- `test/crosswake/doctor/doctor_test.exs` — static readiness and non-echoing doctor proof seam.
- `test/crosswake/operator_inspection/json_formatter_test.exs` — inspection serialization and
  forbidden-output proof seam.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Crosswake.Offline.Journal` and `Crosswake.Offline.Replay`: small typed structs already separate
  queue entries, wire requests, and closed outcomes; extend them instead of adding a sync engine.
- Existing route policy, `RouteGate`, and `gated_by`: canonical route entry/disablement seam; do not
  introduce another flag evaluation path.
- `crosswake_sigra` evaluator and optional companion registry: existing backend-authority adapter
  posture with fail-closed dependency behavior.
- `Ecto.Multi`, uniqueness on `client_mutation_id`, and the host context/controller: idiomatic
  Phoenix transaction/idempotency foundation, although the current bulk `insert_all` is too coarse
  for per-event admission.
- Phase 159 generated ExUnit/Playwright/XCTest/XCUITest lane and evidence builder/scanner: the only
  proof system Phase 160 should extend.
- `Crosswake.Shell.DiagnosticExport` and planning privacy scanners: exact allowlist, final-byte
  scanning, stable rule/path-only failure precedents.

### Established Patterns

- Normalize public inputs once, use closed enums, reject unknown keys, and derive every language
  surface from the canonical contract.
- Phoenix and Ecto own current business/session authority; browser, shell, companion, and retained
  evidence are observations, never authority.
- Host-editable integration code is generated and host-owned; security/protocol invariants remain
  library-owned and versioned.
- Accepted/rejected/conflict are explicit; silent last-write-wins and optimistic fallback are
  already rejected project-wide.
- Deterministic contract/privacy checks may be recurring CI gates; physical device/external auth
  remains a later evidence lane whose assertions are still automated.

### Integration Points

- Add scope and safe projection boundaries to journal/replay structs, serialization, and tests.
- Version and migrate the example/generated IndexedDB outbox so every read/write/lease/checkpoint is
  scoped and lifecycle-fenced.
- Add a narrow host replay-authority adapter and generated Phoenix endpoint proof around current
  session, route policy, `gated_by`, Sigra, host authorization, and per-event Ecto transactions.
- Extend generated browser and iOS driver callbacks with account-switch/logout/blocked assertions;
  keep adopter-specific selectors, schemas, accounts, and flags host-owned.
- Register only recurring closed telemetry/privacy contracts in CI and keep retained evidence on
  the Phase 159 exact-schema path.

</code_context>

<specifics>
## Specific Ideas

- **“Fence first, switch second.”** Changing the host session cannot make an old outbox eligible
  under a new account, even for one callback or reconnect tick.
- **“One scope, one ordered drain, one event transaction.”** This is deliberately less clever and
  more auditable than a generic concurrent sync worker.
- **“Opaque is still sensitive.”** A scope or mutation reference is never safe merely because a
  person cannot read it; stable hashes are excluded for the same reason.
- **“Wire data is not observation data.”** Names and constructors should make it difficult for a
  host developer to accidentally pass replay payloads to telemetry or evidence.
- Borrow the successful parts of systems such as Replicache/PowerSync/Firebase—scoped local data,
  explicit push/retry, idempotency, and visible auth pauses—without copying generic sync, automatic
  conflict policy, or client authority.
- Relevant design pillars are clarity, accessibility, privacy, resilience, performance,
  consistency, testability, and operability. For this phase they converge on four learner-visible
  states: saved locally, syncing, needs attention, and safely paused, all with text semantics and
  no backend jargon.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within Phase 160. Generic sync/storage, background replay, transactional
host flag infrastructure, dashboards, Android work, new auth-provider features, and broader UI
remain outside v21 unless the governing ADR reversal condition is met.

</deferred>

---

*Phase: 160-scoped-replay-and-auth-safety*
*Context gathered: 2026-08-02*
