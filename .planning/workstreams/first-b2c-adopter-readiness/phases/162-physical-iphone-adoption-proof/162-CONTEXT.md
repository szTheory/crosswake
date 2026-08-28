# Phase 162: Physical-iPhone Adoption Proof - Context

**Gathered:** 2026-08-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Produce one dated, redacted, physical-iPhone proof artifact for one First B2C Adopter offline
study flow. The proof exercises verified offline pronunciation audio, selected and free-form
offline answers, kill/relaunch persistence, backend-authorized exactly-once replay, explicit
rejection/conflict recovery, account isolation, and server-side disablement.

It must extend the existing generated host-owned proof lane and iOS host rather than introduce a
parallel harness, generic sync service, device farm, permanent device CI lane, Android work, or a
broader support claim. TODO-002 remains a fail-closed prerequisite: no concrete route, device, or
adopter-instance promotion may be inferred until sanitized route rows validate.

</domain>

<decisions>
## Implementation Decisions

### Sequential host-owned exit test

- **D-01:** Extend the Phase 159 generated proof lane with one sequential, rerunnable,
  host-owned physical-iPhone driver. Its run is: fail-closed preflight; verified pack install;
  authorized study entry; selected and free-form offline mutations; offline audio; app
  terminate/relaunch without clearing storage; reconnect; backend-confirmed exactly-once drain;
  separately controlled rejection/conflict recovery; logout/account-switch fencing; and
  route-entry plus replay disablement. Reset isolated fixtures only between independent cases,
  never between offline submission, relaunch, and replay. — **Reversibility:** costly — proof-lane
  templates, iOS test targets, Phoenix host adapters, evidence validation, and host fixtures
  consume the sequence and its stable assertion IDs.
- **D-02:** XCUITest/XCTest owns device-local lifecycle, audio, and observable recovery assertions.
  The Phoenix host independently proves replay admission, idempotent domain application, conflict
  outcomes, scope isolation, and feature-gate behavior. Shell, WebView, test driver, and Sigra
  remain evidence inputs rather than authority.
- **D-03:** Keep the library/host boundary idiomatic: Crosswake provides closed contracts,
  generator hooks, safe observations, and stable denials; Plug/Phoenix derives current authority
  per request; Ecto applies one accepted event with scoped idempotency and its domain effect in a
  transaction; the host owns domain fixtures, conflict policy, account mapping, and retention.
  Do not introduce generic replication, a generic conflict resolver, or a new sync product.

### Fail-closed promotion and evidence

- **D-04:** Start a device run only after a validated sanitized TODO-002 route row, current
  generated proof lane, runnable signed host, selected physical iPhone, configured host-only
  fixture/adapter, valid media requirements, and backend controls for replay, rejection/conflict,
  scoped session, and feature gating are present. A missing prerequisite returns one stable
  `blocked` outcome and cannot create a partial promotion artifact.
- **D-05:** Add a versioned `physical_iphone` device class, low-cardinality iOS runtime line, and
  a complete fixed set of per-assertion outcomes to the existing proof evidence contract. A
  promotion verifier reparses canonical JSON, rejects simulator/unknown classes, requires every
  DEVICE assertion to pass, verifies approved hashes, rescans the final directory, and publishes
  atomically without replacement. — **Reversibility:** costly — retained evidence schemas,
  generator templates, host adapters, verification commands, and support truth consume the
  device-class and assertion vocabulary.
- **D-06:** Retain only capture UTC, approved Crosswake/template/runtime/contract versions and
  commit reference, opaque route ID, device class, iOS runtime line, fixed assertion IDs with
  closed outcomes, retention label, and hashes of explicitly approved sanitized run-contract
  bytes. `.xcresult`, screenshots, video, raw test output, logs, server responses, endpoint
  values, device identifiers, fixtures, payloads, account identifiers, tokens, media, paths,
  artifacts, and binary hashes are ephemeral and forbidden from the dated artifact.

### Recovery, learner experience, and accessibility

- **D-07:** The host renders one task-oriented study status/recovery surface with the semantic
  states `saved_locally`, `syncing`, `needs_attention`, and `sync_paused`. Learner copy separates
  local saving from server acceptance: “Saved on this iPhone. It will sync when you’re back
  online.”, “Syncing saved answers…”, “Some saved answers need review.”, and “Your saved answers
  remain on this iPhone.” Never expose scope references, mutation IDs, flags, backend reasons,
  paths, hashes, provider details, or transaction mechanics.
- **D-08:** Rejected/conflicted events remain visible and retained for an explicit host recovery
  destination when validated route inputs establish one; until then, prove only the closed visible
  outcome and retained queue. Never use silent last-write-wins, queue deletion, an automatic retry
  loop, or a generic “sync failed” state. Logout/account switch fences first and retains the old
  partition; remote disablement blocks entry and replay while preserving queued work, without
  downgrading to online-only or offering a futile retry.
- **D-09:** Use an in-flow contextual status row/banner rather than routine alerts, toasts, or
  blocking modals. Follow system iOS conventions: semantic text + icon + color, Dynamic Type,
  44pt targets, standard light/dark/system appearance, Reduce Motion, and one meaningful
  VoiceOver announcement/focus handoff per state transition. Pack progress is determinate only
  when the host has real byte progress; otherwise it is transient and indeterminate only while an
  operation is active. Phoenix-owned confirmation remains the fallback; Phase 162 adds no native
  alert/confirm.

### the agent's Discretion

The user asked for one coherent expert recommendation and locked it. Planning may choose exact
module names, Mix task names, assertion IDs, stable blocked IDs, fixture adapters, test launch
arguments, evidence-schema version, and host-facing accessibility identifiers. It may not weaken
the TODO-002 gate, retain sensitive data, treat UI observation as backend proof, create a generic
sync/device infrastructure product, claim simulator evidence as device proof, or add Android work.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Governing first-adopter boundary

- `AGENTS.md` — current priority, privacy restrictions, workflow, Android freeze, and stop list.
- `.planning/ADR-FIRST-B2C-ADOPTER.md` — infrastructure framing, physical-iPhone promotion
  boundary, privacy rules, reversal condition, and non-goals.
- `.planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md` — intended proof sequence, host/core ownership,
  proof-lane purpose, offline/media/auth boundaries, and acceptance posture.
- `.planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md` — ten-step exit test, route ownership,
  fail-closed behavior, and sensitive-data exclusions.
- `.planning/todos/TODO-002-first-b2c-adopter-route-inputs.md` — required sanitized host input;
  it remains the explicit preflight and promotion gate.

### Milestone contracts and prior phase decisions

- `.planning/PROJECT.md` — Phoenix-first route-policy thesis and executable-proof posture.
- `.planning/REQUIREMENTS.md` — DEVICE-01 through DEVICE-07 acceptance requirements and scope
  exclusions.
- `.planning/ROADMAP.md` — Phase 162 target, dependency, smallest shippable version, success
  criteria, and stop date.
- `.planning/STATE.md` — current blockers and the active physical-device objective.
- `.planning/phases/159-host-reusable-proof-lane/159-CONTEXT.md` — host-owned proof scaffolding,
  closed proof outcomes, existing evidence allowlist, and browser-proof preservation.
- `.planning/phases/160-scoped-replay-and-auth-safety/160-CONTEXT.md` — scope leases, replay-time
  authority, accepted/rejected outcomes, privacy redaction, and server-side disablement.
- `.planning/phases/161-ios-pronunciation-pack-seam/161-CONTEXT.md` — verified installed-byte
  prerequisite, foreground recovery, host PackProvider ownership, and advisory simulator boundary.
- `.planning/phases/161.1-first-adopter-ios-navigation-shell/161.1-CONTEXT.md` — physical-device
  promotion ownership, iOS host composition, accessibility precedent, and Android freeze.

### Current proof and presentation seams

- `examples/phoenix_host/e2e/crosswake_proof_lane/support/proof_lane.ts` — existing sequential
  browser proof adapter and opaque mutation-ID contract.
- `examples/phoenix_host/e2e/crosswake_proof_lane/proof_lane.spec.ts` — Phoenix-host replay and
  exactly-once proof precedent.
- `examples/phoenix_host/e2e/support/offline_route_proof.ts` — IndexedDB, backend confirmation,
  and outbox inspection helper seams.
- `examples/ios_shell_host/CrosswakeShell/CrosswakeShellApp.swift` — iOS host composition and
  XCUITest-only probe precedent.
- `guides/support_matrix.md` — support-evidence vocabulary and physical-device promotion limits.
- `brandbook/BRAND-SPEC.md` — current visual and voice authority; supersedes
  `prompts/crosswake-brand-book.md`.
- `prompts/crosswake-research-synthesis.md` — route-owner architecture research.
- `prompts/elixir-mobile-offlinesupport-flashcard-app-stresstest-deep-research.md` — offline study
  flow risks, reconciliation, and user-facing honesty research.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` — host-owned adapters
  and app-type boundary research.
- `prompts/elixir-mobile-apptypes-design-stresstest-deep-research.md` — design, accessibility, and
  platform-convention research.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- Phase 159 proof lane (`examples/phoenix_host/e2e/crosswake_proof_lane/`): typed host adapter,
  browser offline/reconnect sequence, opaque mutation-id validation, backend confirmation, and
  duplicate-idempotency assertions.
- `examples/phoenix_host/e2e/support/offline_route_proof.ts`: host-side IndexedDB setup/readback,
  offline mutation inspection, outbox-empty checks, and replay confirmation helpers.
- `examples/ios_shell_host/CrosswakeShell/CrosswakeShellApp.swift`: host app composition plus
  guarded synthetic probes for executable XCTest/XCUITest contracts.
- Phase 161 PackProvider/pack-audio proof: exact installed-byte lifecycle, explicit foreground
  recovery, and simulator-advisory evidence vocabulary that Phase 162 must promote only through a
  physical device.

### Established Patterns

- Proof is host-owned and configurable; the existing browser corpus stays primary while generated
  native/device hooks cover boundaries browser automation cannot reach.
- Existing evidence promotion is closed, allowlisted, and atomic; raw artifacts are not retained.
- Route activation and replay both re-check backend/session/route/feature authority; scoped work
  is fenced before account changes.
- Native shell state is not Phoenix authority, and simulator evidence is not device evidence.

### Integration Points

- Extend the proof-lane generator/templates, host iOS test target, and Phoenix host adapter with a
  physical-run preflight and per-assertion report.
- Extend the current evidence validator/promotion and support truth with the closed
  `physical_iphone` class and DEVICE assertion vocabulary.
- Reuse the existing scoped replay route and PackProvider seams; add only host-controlled fixtures
  needed to make reject/conflict/session/gate conditions executable on a real iPhone.

</code_context>

<specifics>
## Specific Ideas

- The user requested a one-shot, research-backed recommendation through software architecture,
  Phoenix/Ecto/Plug conventions, SRE/DevOps, privacy, DX, successful offline/mobile precedents,
  user JTBD, accessibility, and iOS/brand-design lenses.
- The accepted recommendation favors one host-owned sequential exit test and a strict promotion
  record over UI-only evidence, generic replication, device farms, screenshots, or retained device
  logs.
- Crosswake communicates calm operational truth. Learner-facing recovery uses task language and
  hides backend mechanics; diagnostics retain only closed semantic outcomes.

</specifics>

<deferred>
## Deferred Ideas

- Generic replication or sync, generic conflict resolution UI, background replay, a device farm,
  permanent physical-device CI, screenshots/video as support proof, native alert/confirm, Android
  device/parity work, and broader multi-island support remain outside Phase 162 and require the
  governing ADR reversal condition or a future explicit roadmap decision.

</deferred>

---

*Phase: 162-physical-iphone-adoption-proof*
*Context gathered: 2026-08-04*
