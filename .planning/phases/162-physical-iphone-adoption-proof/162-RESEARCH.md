# Phase 162: Physical-iPhone Adoption Proof - Research

**Researched:** 2026-08-04  
**Domain:** Privacy-safe physical-iPhone acceptance evidence for a Phoenix offline study island  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Extend the Phase 159 generated proof lane with one sequential, rerunnable, host-owned physical-iPhone driver. Its run is: fail-closed preflight; verified pack install; authorized study entry; selected and free-form offline mutations; offline audio; app terminate/relaunch without clearing storage; reconnect; backend-confirmed exactly-once drain; separately controlled rejection/conflict recovery; logout/account-switch fencing; and route-entry plus replay disablement. Reset isolated fixtures only between independent cases, never between offline submission, relaunch, and replay.
- **D-02:** XCUITest/XCTest owns device-local lifecycle, audio, and observable recovery assertions. The Phoenix host independently proves replay admission, idempotent domain application, conflict outcomes, scope isolation, and feature-gate behavior. Shell, WebView, test driver, and Sigra remain evidence inputs rather than authority.
- **D-03:** Crosswake provides closed contracts, generator hooks, safe observations, and stable denials; Plug/Phoenix derives current authority per request; Ecto applies one accepted event with scoped idempotency and its domain effect in a transaction; the host owns domain fixtures, conflict policy, account mapping, and retention. Do not introduce generic replication, a generic conflict resolver, or a new sync product.
- **D-04:** Start a device run only after a validated sanitized TODO-002 route row, current generated proof lane, runnable signed host, selected physical iPhone, configured host-only fixture/adapter, valid media requirements, and backend controls for replay, rejection/conflict, scoped session, and feature gating are present. A missing prerequisite returns one stable `blocked` outcome and cannot create a partial promotion artifact.
- **D-05:** Add a versioned `physical_iphone` device class, low-cardinality iOS runtime line, and a complete fixed set of per-assertion outcomes to the existing proof evidence contract. A promotion verifier reparses canonical JSON, rejects simulator/unknown classes, requires every DEVICE assertion to pass, verifies approved hashes, rescans the final directory, and publishes atomically without replacement.
- **D-06:** Retain only capture UTC, approved Crosswake/template/runtime/contract versions and commit reference, opaque route ID, device class, iOS runtime line, fixed assertion IDs with closed outcomes, retention label, and hashes of explicitly approved sanitized run-contract bytes. `.xcresult`, screenshots, video, raw test output, logs, server responses, endpoint values, device identifiers, fixtures, payloads, account identifiers, tokens, media, paths, artifacts, and binary hashes are ephemeral and forbidden from the dated artifact.
- **D-07:** The host renders one task-oriented study status/recovery surface with the semantic states `saved_locally`, `syncing`, `needs_attention`, and `sync_paused`. Learner copy separates local saving from server acceptance and never exposes scope references, mutation IDs, flags, backend reasons, paths, hashes, provider details, or transaction mechanics.
- **D-08:** Rejected/conflicted events remain visible and retained for an explicit host recovery destination when validated route inputs establish one; until then, prove only the closed visible outcome and retained queue. Never use silent last-write-wins, queue deletion, an automatic retry loop, or a generic “sync failed” state. Logout/account switch fences first and retains the old partition; remote disablement blocks entry and replay while preserving queued work.
- **D-09:** Use an in-flow contextual status row/banner rather than routine alerts, toasts, or blocking modals. Follow system iOS conventions: semantic text + icon + color, Dynamic Type, 44pt targets, standard light/dark/system appearance, Reduce Motion, and one meaningful VoiceOver announcement/focus handoff per state transition. Phoenix-owned confirmation remains the fallback; Phase 162 adds no native alert/confirm.

### the agent's Discretion

Planning may choose exact module names, Mix task names, assertion IDs, stable blocked IDs, fixture adapters, test launch arguments, evidence-schema version, and host-facing accessibility identifiers. It may not weaken the TODO-002 gate, retain sensitive data, treat UI observation as backend proof, create a generic sync/device infrastructure product, claim simulator evidence as device proof, or add Android work.

### Deferred Ideas (OUT OF SCOPE)

Generic replication or sync, generic conflict resolution UI, background replay, a device farm, permanent physical-device CI, screenshots/video as support proof, native alert/confirm, Android device/parity work, and broader multi-island support remain outside Phase 162.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| DEVICE-01 | Physical iPhone installs verified pack and plays audio offline. | Extend PackProvider/XCUITest sequence; physical-only evidence assertion. |
| DEVICE-02 | Offline selected/free-form answers survive relaunch and replay exactly once. | Sequential driver plus Phoenix transaction/idempotency authority check. |
| DEVICE-03 | Rejection/conflict is visible and recoverable; no silent LWW. | Controlled host fixtures and semantic recovery-state assertions. |
| DEVICE-04 | Logout/account switching produces no cross-scope replay. | Scope fence and backend admission test before/after session change. |
| DEVICE-05 | Host flag blocks entry and replay without data loss/new binary. | Two independently verified server-side denial cases. |
| DEVICE-06 | Artifact retains only allowed fields and redacted hashes. | Versioned closed evidence schema, final scan, atomic no-replace promotion. |
| DEVICE-07 | Support claim stays one flow/one iOS runtime with explicit exclusions. | Support-matrix wording sourced only from promoted `physical_iphone` record. |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Preserve Phoenix-first explicit route/runtime ownership; never turn this work into a generic WebView wrapper or universal UI framework. [VERIFIED: AGENTS.md]
- Keep bridges semantic, typed, versioned, and low-frequency; continuous authority remains route-local/native. [VERIFIED: AGENTS.md]
- Keep offline claims honest; preserve explicit fail-closed denials and treat diagnostics/proof as product surface. [VERIFIED: AGENTS.md]
- Do no Android feature, template, device, parity, or release work in v21. [VERIFIED: AGENTS.md]
- Do not add generic sync/background sync/native storage, a device farm, dashboard, new native-control breadth, or other stopped business-line work. [VERIFIED: AGENTS.md]
- Never retain identifiers, answers, media, transcripts, credentials, account data, tokens, or stable device IDs in proof/diagnostics; enforce opaque scopes, partitioned outboxes, replay authorization, and logout/account-switch fencing. [VERIFIED: AGENTS.md]
- Prefer automated evidence. A physical-device connection may need setup, but evaluation of its assertions and artifact must remain automated; do not create human-verification/UAT checkpoints. [VERIFIED: AGENTS.md]

## Summary

Phase 162 should be planned as one host-owned, sequential device exit test that composes already-delivered seams rather than a new test platform: Phase 159’s proof-lane generator/evidence publisher, Phase 160’s scope and replay authorization, Phase 161’s exact-byte pack/audio seam, and Phase 161.1’s iOS shell/accessibility contract. The physical phone is the unique evidence producer; Phoenix remains the authority for replay admission, idempotency, conflict, session scope, and feature-gate outcomes. [VERIFIED: 162-CONTEXT.md; VERIFIED: lib/crosswake/proof_lane/evidence.ex]

The first task must implement a hard preflight because this repository has no sanitized TODO-002 row and the local Xcode device inventory currently lists only the Mac and simulators. A preflight failure must emit one closed `blocked` result and must not stage, promote, or alter any dated evidence. [VERIFIED: TODO-002-first-b2c-adopter-route-inputs.md; VERIFIED: local `xcrun xctrace list devices`]

**Primary recommendation:** Extend the generated proof lane with a physical-only sequential driver and a narrow `physical_iphone` evidence promotion verifier; retain one canonical JSON record only after every DEVICE assertion has independently passed.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Device install/audio, terminate/relaunch, accessible status | iOS client | Host test target | XCUITest observes real app lifecycle and user-visible behavior. [VERIFIED: 162-CONTEXT.md] |
| Offline mutation persistence/outbox | Browser / offline island | iOS client | The existing island owns local mutation state; the shell must not become sync authority. [VERIFIED: AGENTS.md; VERIFIED: offline_route_proof.ts] |
| Replay admission, idempotency, conflict, scope and flag checks | API / Backend | Database / Storage | Plug derives request authority; Ecto durably accepts one scoped event and host effect. [VERIFIED: 162-CONTEXT.md; CITED: https://ecto.hexdocs.pm/Ecto.Multi.html] |
| Dated artifact validation/publication | API / Backend | Static storage | Library-owned validator scans canonical JSON and atomically publishes only a completed artifact. [VERIFIED: lib/crosswake/proof_lane/evidence.ex; VERIFIED: lib/crosswake/proof_lane/native_promotion.ex] |
| Support wording | Static/docs | API / Backend | Promotion can support only one approved device class/runtime record, never broader capability inference. [VERIFIED: guides/support_matrix.md] |

## Standard Stack

### Core

| Library / seam | Version | Purpose | Why Standard |
|---|---|---|---|
| XCTest + XCUIAutomation | Xcode 26.6 installed | Physical-iPhone UI/lifecycle assertions. | Apple documents XCTest with XCUIAutomation for user interaction flows. [CITED: https://developer.apple.com/documentation/xctest] |
| Plug/Phoenix host pipeline | existing host dependency | Per-request session/scope/route/flag admission. | `Plug.Conn` distinguishes current-request assigns from session persistence and supports explicit `halt/1`. [CITED: https://plug.hexdocs.pm/Plug.Conn.html] |
| Ecto.Multi + scoped idempotency schema | existing host dependency | Commit accepted idempotency record and domain effect atomically. | Ecto documents ordered transaction operations and identifiable failure results. [CITED: https://ecto.hexdocs.pm/Ecto.Multi.html] |
| `Crosswake.ProofLane.Evidence` / `NativePromotion` | in repository | Closed record validation, source hashing, final scan, no-replace publication. | Existing exact-key, privacy scan, completion marker, and atomic publication pattern is directly reusable. [VERIFIED: lib/crosswake/proof_lane/evidence.ex; VERIFIED: lib/crosswake/proof_lane/native_promotion.ex] |

### Supporting

| Library / seam | Version | Purpose | When to Use |
|---|---|---|---|
| Playwright proof lane | existing host dependency | Retain browser corpus and verify app-owned IndexedDB/reconnect behavior. | Keep as regression proof beside—not instead of—the device test. [VERIFIED: examples/phoenix_host/e2e/crosswake_proof_lane/proof_lane.spec.ts] |
| `CrosswakeShellCore` PackProvider | existing host seam | Verify installed bytes and offline playback on the actual app. | Use for DEVICE-01 only; no generic pack/storage expansion. [VERIFIED: 162-CONTEXT.md] |
| Accessibility identifiers | platform API | Drive stable UI assertions without implementation/DOM coupling. | Apple identifies them as unique element IDs often used in automated testing. [CITED: https://developer.apple.com/documentation/appkit/nsaccessibility-c.protocol/accessibilityidentifier] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| One rerunnable XCUITest/Phoenix exit driver | screenshots, video, manual UAT | Collateral cannot prove backend authority and is prohibited from retention. [VERIFIED: 162-CONTEXT.md] |
| Physical `physical_iphone` record | simulator advisory evidence | Simulator is explicitly non-promoting and cannot meet DEVICE requirements. [VERIFIED: guides/support_matrix.md] |
| Host controlled rejection/conflict fixtures | generic conflict resolver | The latter breaches host domain ownership and Phase boundary. [VERIFIED: 162-CONTEXT.md] |

**Installation:** No new external package is justified or recommended. Reuse repository/Xcode/Phoenix dependencies. [VERIFIED: 162-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
validated TODO-002 row + signed host + physical iPhone + host fixtures
                              |
                              v
                  fail-closed preflight ----missing----> closed `blocked`; no artifact
                              |
                              v
XCUITest: pack -> study -> offline answers/audio -> terminate/relaunch -> reconnect
                              |                                       |
                              |                                       v
                              |                         Plug: session/scope/route/flag check
                              |                                       |
                              |                    deny -> closed visible state + queue retained
                              |                                       |
                              v                                       v
                 accessibility/status assertions          Ecto transaction: idempotency + effect
                              |                                       |
                              +------------------- per-assertion closed outcomes
                                                      |
                                                      v
        canonical allowlist JSON -> reparse/hash/scan -> atomic no-replace retained evidence
                                                      |
                                                      v
          narrow support truth: one opaque route, `physical_iphone`, one iOS runtime line
```

### Recommended Project Structure

```text
lib/crosswake/proof_lane/             # closed preflight, DEVICE vocabulary, promotion verifier
priv/templates/crosswake/proof_lane/  # generated host-owned iOS driver/tests and Phoenix adapter hooks
examples/phoenix_host/e2e/            # preserved browser regression proof only
examples/ios_shell_host/              # reference composition/accessibility precedent
guides/                               # narrow support wording and invocation guidance
```

### Pattern 1: Closed preflight before side effects

**What:** Normalize every required host/device capability into a complete prerequisite report, then short-circuit on the first missing category with a stable blocked ID. Do not reset data, start capture, or create a destination directory before it passes. [VERIFIED: 162-CONTEXT.md]

**When to use:** At the entry point for the physical driver and again immediately before promotion. [VERIFIED: 162-CONTEXT.md]

### Pattern 2: Dual-authority proof

**What:** XCUITest asserts device-local facts through stable accessibility identifiers; a separate Phoenix evidence endpoint asserts only backend-authoritative outcomes. No UI label can count as replay, idempotency, conflict, scope, or feature-gate proof. [VERIFIED: 162-CONTEXT.md; CITED: https://developer.apple.com/documentation/xctest]

### Pattern 3: One transaction per accepted replay event

**What:** In the host adapter, authorize the request first; then use an Ecto transaction to create/read the scoped idempotency record and apply exactly one domain effect. Return a closed accepted/duplicate/rejected/conflict result without echoing payloads. [CITED: https://ecto.hexdocs.pm/Ecto.Multi.html; VERIFIED: 162-CONTEXT.md]

### Anti-Patterns to Avoid

- **Reset between offline submit and replay:** destroys the persistence property under test. [VERIFIED: 162-CONTEXT.md]
- **UI-only success:** cannot prove backend authorization/idempotency. [VERIFIED: 162-CONTEXT.md]
- **Simulator class relabelled as a phone:** invalidates promotion; reject simulator and unknown classes. [VERIFIED: 162-CONTEXT.md]
- **Artifact as a diagnostic bundle:** `.xcresult`, logs, screenshots, identifiers, payloads, and media are forbidden retained data. [VERIFIED: 162-CONTEXT.md]
- **Automatic conflict retry/LWW:** hides learner work and violates the explicitly retained recovery queue. [VERIFIED: 162-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Device orchestration | Device farm/permanent CI lane | One signed physical-device XCUITest invocation plus ephemeral outputs | The milestone requires one repeatable proof, not a platform. [VERIFIED: 162-CONTEXT.md] |
| Evidence publication | Ad-hoc JSON/copy command | Existing typed evidence builder + `NativePromotion` | It already enforces allowlist scanning, digest-bound completion, and collision-safe publish. [VERIFIED: lib/crosswake/proof_lane/evidence.ex] |
| Replay semantics | Generic sync/conflict engine | Host Plug + Ecto adapter and existing scoped journal contract | Conflict/domain retention are host-owned. [VERIFIED: 162-CONTEXT.md] |
| Device test selectors | WebView/DOM implementation hooks | Accessibility identifiers and visible semantic status | This tests the user-visible native boundary safely. [CITED: https://developer.apple.com/documentation/appkit/nsaccessibility-c.protocol/accessibilityidentifier] |

## Common Pitfalls

### Pitfall 1: Attempting promotion before sanitized route validation

**What goes wrong:** A concrete route/device claim is fabricated from example-host facts.  
**How to avoid:** Make TODO-002 validation a mandatory preflight input and return `blocked` when inventory is empty or `unknown_blocking`. [VERIFIED: TODO-002-first-b2c-adopter-route-inputs.md; VERIFIED: FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md]

### Pitfall 2: Treating a `passed` XCUITest line as authority proof

**What goes wrong:** Device presentation can be correct while the server admits duplicate/cross-scope/disabled replay.  
**How to avoid:** Require a backend evidence assertion for every authority claim and map it to the fixed DEVICE IDs. [VERIFIED: 162-CONTEXT.md]

### Pitfall 3: Retaining a convenient but unsafe artifact

**What goes wrong:** Test bundles and hashes can carry screenshots, paths, device IDs, server responses, or correlating bytes.  
**How to avoid:** Start from the existing exact allowlist, permit hashes only for reviewed sanitized run-contract bytes, reparse canonical JSON, scan final bytes, and publish only an empty destination. [VERIFIED: 162-CONTEXT.md; VERIFIED: lib/crosswake/proof_lane/evidence.ex]

### Pitfall 4: Losing queued learner work during recovery testing

**What goes wrong:** Fixture resets, logout cleanup, or remote disablement delete an old scope rather than fence it.  
**How to avoid:** Isolate only independent test cases; preserve the partition across app relaunch, recovery, and server denial. Assert no cross-scope replay separately. [VERIFIED: 162-CONTEXT.md]

### Pitfall 5: Scope creep after obtaining a device

**What goes wrong:** The physical device becomes rationale for Android parity, device farms, native alert/confirm, or generic sync.  
**How to avoid:** Treat every non-DEVICE behavior as out of scope; update support truth with narrow iOS-only wording only. [VERIFIED: AGENTS.md; VERIFIED: 162-CONTEXT.md]

## Code Examples

### Phoenix accepted-event transaction shape

```elixir
# Host-owned adapter; payload fields intentionally omitted.
with :ok <- authorize_replay(conn, scope_ref, route_id, feature_state) do
  Ecto.Multi.new()
  |> Ecto.Multi.run(:idempotency, &claim_scoped_event(&1, scope_ref, mutation_id))
  |> Ecto.Multi.run(:domain_effect, &apply_once(&1, scope_ref, mutation_id))
  |> Repo.transaction()
end
```

This preserves the required boundary: Plug/Phoenix authorizes per request, while Ecto commits the accepted event and its effect together. [CITED: https://plug.hexdocs.pm/Plug.Conn.html; CITED: https://ecto.hexdocs.pm/Ecto.Multi.html]

### Physical-device test boundary

```swift
let app = XCUIApplication()
app.launch()
// Assert only accessibility-addressable learner-visible state here.
app.terminate()
app.launch()
// Ask the Phoenix host adapter for closed authority outcomes separately.
```

Use the existing generated test’s launch/terminate precedent, but replace its reference-adapter/simulator advisory status with physical-only preflight and DEVICE assertion output. [VERIFIED: priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex]

## State of the Art

| Old Approach | Current Approach | Impact |
|---|---|---|
| Simulator/reference pack evidence | Simulator remains advisory; only Phase 162 can promote physical-iPhone evidence. | Keep simulator checks as regression signals, never a DEVICE pass. [VERIFIED: STATE.md] |
| Broad device evidence payload | Exact allowlist plus final artifact scan and no-replace publish. | A dated record can be retained without retaining raw diagnostic material. [VERIFIED: lib/crosswake/proof_lane/evidence.ex] |
| Browser-only offline proof | Browser proof remains primary regression coverage plus a physical iOS boundary test. | Avoid rewriting the host browser corpus while covering device-only lifecycle/audio. [VERIFIED: 159-CONTEXT.md] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | None. | — | All recommendations are constrained by repository contracts or official docs fetched this session. |

## Open Questions

1. **When will sanitized TODO-002 rows validate?**
   - What we know: none are present; promotion is currently `unknown_blocking`. [VERIFIED: TODO-002-first-b2c-adopter-route-inputs.md]
   - Recommendation: implement and test the stable blocked preflight first; do not infer a route, path, fixture, device, or runtime value.

2. **Which signed physical iPhone and host backend will run the lane?**
   - What we know: no physical phone is currently listed by local Xcode tooling. [VERIFIED: local `xcrun xctrace list devices`]
   - Recommendation: retain only a low-cardinality runtime line after the actual device run; connection/signing is a bounded setup prerequisite, not manual evidence evaluation.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| Xcode / XCTest | iOS build and UI runner | ✓ | Xcode 26.6 (17F113) | — |
| Physical iPhone destination | DEVICE promotion | ✗ | — | Stable blocked preflight; no simulator fallback for promotion |
| Node/npm | existing Playwright proof lane | ✓ | Node 22.14.0 / npm 11.1.0 | — |
| Elixir/Erlang | Mix/Phoenix evidence and host tests | ✓ | Erlang/OTP 28 | — |
| Runnable adopter host/backend | replay/conflict/scope/flag authority | ✗ | — | Stable blocked preflight |

**Missing dependencies with no fallback:** validated TODO-002 rows, a signed physical iPhone, and a runnable adopter host/backend. [VERIFIED: STATE.md; VERIFIED: local `xcrun xctrace list devices`]

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit/Mix, Playwright, XCTest/XCUITest [VERIFIED: repository proof-lane sources] |
| Config file | existing host test configuration and generated iOS Xcode target [VERIFIED: 159-CONTEXT.md] |
| Quick run command | Existing Mix/Playwright unit slice plus generated iOS test target; exact host command is a planning decision. [VERIFIED: 162-CONTEXT.md] |
| Full suite command | Existing host browser corpus, Mix suite, package tests, and signed physical-XCUITest invocation. [VERIFIED: 162-CONTEXT.md] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| DEVICE-01 | Pack install + offline audio | XCUITest + host pack observation | Generated physical driver command | ❌ Wave 0 |
| DEVICE-02 | offline queue, relaunch, exact-once drain | XCUITest + Phoenix integration | Generated physical driver + Phoenix assertion | ❌ Wave 0 |
| DEVICE-03 | rejected/conflict visible and retained | XCUITest + Phoenix integration | Controlled fixture case | ❌ Wave 0 |
| DEVICE-04 | logout/switch fences replay | Phoenix integration + XCUITest observable state | Controlled scoped-session case | ❌ Wave 0 |
| DEVICE-05 | route/replay feature gate preserves queue | Phoenix integration + XCUITest | Controlled gate case | ❌ Wave 0 |
| DEVICE-06 | canonical redacted artifact | ExUnit | evidence verifier test | ❌ Wave 0 |
| DEVICE-07 | narrow support truth | docs contract / ExUnit | support-matrix contract check | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** relevant ExUnit/Swift/Playwright slice. [VERIFIED: AGENTS.md]
- **Per wave merge:** existing fast suite plus generated proof-lane check. [VERIFIED: AGENTS.md]
- **Phase gate:** a fresh signed physical run passes every fixed assertion, promotion verifier succeeds, and final output scan is clean. [VERIFIED: 162-CONTEXT.md]

### Wave 0 Gaps

- [ ] Physical-only preflight and stable blocked outcome.
- [ ] Fixed DEVICE assertion enum/outcome manifest and `physical_iphone` evidence class/verifier.
- [ ] Host fixture adapter for reject, conflict, logout/switch, and feature-gate cases.
- [ ] Sequential XCUITest driver that preserves state across terminate/relaunch.
- [ ] Phoenix authority evidence endpoint/adapter returning closed, non-sensitive outcomes.
- [ ] Evidence final-directory/privacy/atomicity tests and support-matrix contract update.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | yes | Backend re-derives session authority for every replay; shell/test driver has no credential authority. [VERIFIED: 162-CONTEXT.md] |
| V3 Session Management | yes | Logout/account switch fences before scope change; retained old partition cannot replay under a new session. [VERIFIED: 162-CONTEXT.md] |
| V4 Access Control | yes | Route entry and replay both independently enforce host feature and route policy. [VERIFIED: 162-CONTEXT.md] |
| V5 Input Validation | yes | Closed evidence keys/outcomes/IDs and non-echoing validation failures. [VERIFIED: lib/crosswake/proof_lane/evidence.ex] |
| V6 Cryptography | yes | Reuse SHA-256 only for explicitly approved sanitized canonical bytes; never hash sensitive payload/device/account bytes. [VERIFIED: 162-CONTEXT.md] |

### Known Threat Patterns for this phase

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Cross-account replay | Elevation / Information disclosure | Scope-partitioned outbox plus per-request session/scope authorization. [VERIFIED: 162-CONTEXT.md] |
| Duplicate accepted mutation | Tampering | Scoped idempotency record and domain effect in one transaction. [CITED: https://ecto.hexdocs.pm/Ecto.Multi.html] |
| Feature flag bypass after queueing | Elevation | Check flag at route entry and replay; retain queue on denial. [VERIFIED: 162-CONTEXT.md] |
| Sensitive proof exfiltration | Information disclosure | Allowlist, source-kind restriction, final scan, only canonical record retained. [VERIFIED: lib/crosswake/proof_lane/evidence.ex] |
| Simulator/device-class spoof | Spoofing | Promotion verifier rejects simulator/unknown and requires physical-only class. [VERIFIED: 162-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- Repository contracts and implementations: `162-CONTEXT.md`, `AGENTS.md`, TODO-002, `Evidence`, `NativePromotion`, existing proof lane, support matrix. [VERIFIED: codebase]

### Secondary (MEDIUM confidence)

- [Apple XCTest documentation](https://developer.apple.com/documentation/xctest) — XCTest/XCUIAutomation UI-test role.
- [Apple accessibility identifier documentation](https://developer.apple.com/documentation/appkit/nsaccessibility-c.protocol/accessibilityidentifier) — stable automated-test selectors.
- [Ecto.Multi documentation](https://ecto.hexdocs.pm/Ecto.Multi.html) — transactional operation ordering/failure results.
- [Plug.Conn documentation](https://plug.hexdocs.pm/Plug.Conn.html) — request assigns, sessions, and halted pipeline behavior.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — repository seams plus Apple/Ecto/Plug documentation.
- Architecture: HIGH — locked Context decisions and existing Phase 159–161.1 interfaces.
- Pitfalls: HIGH — explicit privacy, TODO-002, simulator, and scope-fence constraints.

**Research date:** 2026-08-04  
**Valid until:** 2026-08-11 (device/toolchain context and host availability are fast-moving).
