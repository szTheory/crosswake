# Phase 160: Scoped Replay and Auth Safety - Research

**Researched:** 2026-08-02  
**Domain:** Scope-partitioned offline replay, Phoenix authorization, and privacy-safe observations  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- `scope_ref` is a required, versioned, opaque host-issued sensitive value on every journal entry and replay request. Core validates only a bounded transport shape and equality; it must not derive, decode, log, hash, enumerate, or map account data.
- Use one outbox with scoped compound keys/indexes for entries, checkpoints, conflicts, and leases. There is no unscoped/all drain.
- Retained partitions start inert. Logout/account switch fences first: leave active, increment epoch, stop new sends/reads, cancel or await the worker, then activate another scope. Stale completions affect neither the new UI nor scope.
- Missing/malformed/inactive/mismatched scope visibly blocks and preserves data; it never falls back to default scope, cookies, or the newly active account.
- Drain one active scope serially in journal order and re-check admission before every event. The host endpoint enforces bounded closed input, current backend session and mapped scope, route, `gated_by`, Sigra evidence, host route/domain authorization, then applies one event transactionally with idempotency.
- Accepted/rejected/conflict remain explicit; add `blocked`. Duplicate accepted events return accepted; rejected/conflict/blocked entries remain. A blocked event halts the batch without hot retry.
- `gated_by` is checked both at route entry and replay. Disablement pauses visibly and retains data.
- Wire/domain data and safe observations are distinct planes. Only a closed versioned observation vocabulary can enter telemetry, Logger, doctor, inspection, aggregates, and retained evidence. It excludes scopes, payloads, event/checkpoint/idempotency/correlation refs, identities, tokens, exact auth ages, endpoints, flags, and media; stable hashes are excluded too.
- `crosswake_sigra` converts host/backend session-authority evidence to closed allow/deny only. It is never a credential, provider/device identity, token, or account authority. Missing/incompatible Sigra explicitly denies.
- Extend the existing Phase 159 ExUnit, Playwright, XCTest/XCUITest, and evidence lanes; do not create a proof system. Prove two scopes, switching before/during send, inactive relaunch, Nth-event disablement/revocation, endpoint mismatch, rollback/lost response retry, duplicate idempotency, retained rejection/conflict, and blocked proof failure.

### the agent's Discretion

The user delegated exact private module/function names, conservative scope-ref syntax/length, IndexedDB migration mechanics, bounded batch ceiling, retry/backoff timings, safe rule IDs, and test-file organization. These choices must not weaken required scoped access, fence-before-switch, per-event admission, atomic idempotency, queue retention, Sigra's adapter boundary, allowlisted observations, or non-echoing evidence.

### Deferred Ideas (OUT OF SCOPE)

None — generic sync/storage, background replay, transactional host-flag infrastructure, dashboards, Android work, new authentication-provider features, and broader UI remain outside v21 unless the ADR reversal condition is met.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| SCOPE-01 | Opaque `scope_ref` on journal/replay envelopes and partitioned outbox | Versioned core structs plus compound IndexedDB keys/indexes and scoped request construction. |
| SCOPE-02 | Logout/switch stops replay; cross-scope replay fails closed | Lifecycle fence state + epoch and no unscoped APIs; Playwright stale-completion regressions. |
| SCOPE-03 | Per-event backend session, route, and feature reauthorization | Narrow host replay-admission adapter, existing RouteGate/Sigra, per-event `Ecto.Multi`. |
| SCOPE-04 | No raw answers in telemetry/doctor/inspection/logs/aggregates/evidence | Closed `SafeObservation` allowlist, egress-only constructors, canary-byte property tests and Phase 159 scanner. |
| SCOPE-05 | Sigra is backend-authority adapter only | Existing optional companion behavior; add closed replay result projection and missing-companion denial tests. |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Keep Crosswake Phoenix-first and route-policy/runtime-contract focused; do not become a generic UI or sync framework. [VERIFIED: AGENTS.md]
- Keep bridge contracts typed, versioned, semantic, and low-frequency; client continuous authority stays in the offline island or native screen. [VERIFIED: AGENTS.md]
- Preserve explicit fail-closed denials and honest offline claims. [VERIFIED: AGENTS.md]
- Do not emit raw answers, media, transcripts, credentials, identities, tokens, or stable device IDs in any observability/proof surface. [VERIFIED: AGENTS.md]
- Android is frozen; avoid new Android work, generic storage/sync, background replay, dashboards, or unrelated native breadth. [VERIFIED: AGENTS.md]
- Verification is automated by default; do not add human checkpoints for automatable contracts. [VERIFIED: AGENTS.md]

## Summary

Phase 160 is a boundary replacement, not a new synchronization product. The present journal and replay structs carry sensitive identifiers/payloads in `to_map/1`; the browser has one unscoped `mutations` store; and the example endpoint validates then bulk-inserts a batch. These seams cannot meet scope isolation, per-event admission, or safe egress requirements as written. [VERIFIED: codebase grep]

Use a two-plane design: a sensitive transport plane retains scoped entries and applies host-authorized events, while a separately typed safe-observation plane is the only data permitted to cross into diagnostics, telemetry, inspection, aggregates, logs, and evidence. Require a scope at every storage/replay boundary and compose logout/switch as an epoch fence before any new activation. [VERIFIED: 160-CONTEXT.md]

**Primary recommendation:** Extend the existing journal/replay, IndexedDB, Phoenix host, Sigra, and Phase 159 proof seams with a closed `scope_ref` + lifecycle/admission contract; do not introduce packages, a generic worker, a new store per account, or a second evidence pipeline. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Scope-bound local journal and fence | Browser / Client | Native shell | The offline island owns retained device state; the shell may provide lifecycle signals but never authority. [VERIFIED: 160-CONTEXT.md] |
| Current account/scope mapping and replay admission | API / Backend | Frontend Server | The host resolves the active session and maps it to scope immediately before each event. [VERIFIED: 160-CONTEXT.md] |
| Route/feature and Sigra authorization | API / Backend | — | Existing RouteGate and optional Sigra are restrictive backend decisions. [VERIFIED: codebase grep] |
| Atomic idempotency plus domain mutation | Database / Storage | API / Backend | The host transaction must record the idempotency decision with its domain effect. [VERIFIED: 160-CONTEXT.md] |
| Safe status and evidence observation | Browser / Client | API / Backend | UI renders a closed learner state; backend and proof lanes consume only safe projections. [VERIFIED: 160-CONTEXT.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---|---|---|---|
| Phoenix | `~> 1.8` | Existing JSON controller/router and host request boundary | Already the installed host framework; no replacement is needed. [VERIFIED: codebase grep] |
| Ecto SQL | `~> 3.10` | Existing host transaction/idempotency mutation boundary | `Ecto.Multi` is already used by the example host; change its granularity to one event. [VERIFIED: codebase grep] |
| IndexedDB browser API | platform API | Existing offline-island retention | The app already uses it; migrate its schema rather than add browser storage. [VERIFIED: codebase grep] |
| `crosswake_sigra` | workspace optional companion | Backend session-authority evidence evaluator | Its existing companion behavior is fail-closed and backend-oriented. [VERIFIED: codebase grep] |

### Supporting

| Library | Version | Purpose | When to Use |
|---|---|---|---|
| Playwright | installed `1.60.0` | Existing browser/offline proof | Scope switch, inactive launch, batch halt, and no-raw-byte browser/evidence assertions. [VERIFIED: `examples/phoenix_host/package-lock.json`] |
| ExUnit | Mix runtime | Contract and host integration tests | Struct validation, safe projection, controller, transaction, and Sigra boundary tests. [VERIFIED: codebase grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Scoped indexes in one IndexedDB database | One database/store per account | Rejected: requires identity-derived naming and complicates retained partition fencing. [VERIFIED: 160-CONTEXT.md] |
| Serial per-event admission | Parallel/bulk generic sync | Rejected: loses a small authorization window and atomic event-level outcome semantics. [VERIFIED: 160-CONTEXT.md] |
| Typed allowlist observation | Denylist redaction of arbitrary maps | Rejected: arbitrary maps can carry aliases/nested sensitive values; denylists remain defense in depth only. [VERIFIED: 160-CONTEXT.md] |

**Installation:** None. This phase uses existing dependencies and platform APIs. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
host-authorized active scope
          |
          v
[offline island lifecycle fence: inactive|active|stopping + epoch]
          | scope + epoch required
          v
[IndexedDB compound scope/local key + scope indexes] --(serial exact-scope batch)-->
          | sensitive wire envelope
          v
[Phoenix closed request validation]
          -> current backend session -> host mapped scope equality
          -> route resolution -> gated_by/RouteGate -> Sigra -> host authorization
          -> one Ecto.Multi: idempotency decision + domain effect
          v
[accepted | rejected | conflict | blocked]
          |                                  \
          | accepted delete only                 -> blocked halts and retains queue
          v
[SafeObservation allowlist] -> telemetry/logger/doctor/inspection/aggregate/evidence scanner
```

### Recommended Project Structure

```text
lib/crosswake/offline/                 # Versioned journal, replay, lifecycle, safe observation contracts
packages/crosswake_sigra/lib/.../      # Closed backend-session evidence adapter only
examples/phoenix_host/lib/.../         # Host replay admission, transaction, route authorization
examples/phoenix_host/priv/static/     # Scoped IndexedDB migration and learner statuses
examples/phoenix_host/e2e/             # Existing primary proof corpus, extended for scopes
test/crosswake/offline/                # Contract/privacy unit tests
```

### Pattern 1: Fence first, activate second

**What:** Persist `{lifecycle, epoch}` with the outbox. A drain captures both scope and epoch. Before logout/switch it transitions away from active and increments epoch, then stops the worker; any completion checks the captured values before mutating UI/storage. [VERIFIED: 160-CONTEXT.md]

**When to use:** Every launch, logout, switch, reconnect, retry, and asynchronous response callback. [VERIFIED: 160-CONTEXT.md]

```javascript
// Source: 160-CONTEXT.md (contract pattern)
const lease = { scopeRef: active.scopeRef, epoch: active.epoch };
if (!sameActiveScopeAndEpoch(lease)) return blockedAndRetain();
await sendExactlyOneScopedEvent(lease);
if (!sameActiveScopeAndEpoch(lease)) return; // stale completion is inert
```

### Pattern 2: Closed per-event admission

**What:** Validate the whole envelope without echoing it, then immediately before each event resolve current backend authority, compare host-mapped scope, route policy/flag, Sigra, and host domain authorization. Perform idempotency and effect in the same transaction. [VERIFIED: 160-CONTEXT.md]

**When to use:** Every submitted event, including retries and later positions in a batch. [VERIFIED: 160-CONTEXT.md]

```elixir
# Source: 160-CONTEXT.md; use host callbacks, not Crosswake-owned Repo/schema.
with :ok <- Admission.validate_closed(request),
     {:ok, authority} <- HostAuthority.current(conn),
     :ok <- Admission.match_scope(request.scope_ref, authority),
     {:ok, route} <- HostRoutes.fetch(request.route_id),
     :ok <- Admission.allow?(route, authority) do
  HostMutation.apply_one_transactionally(request, authority)
else
  {:blocked, safe_class} -> {:halt, Replay.blocked(request, safe_class)}
end
```

### Pattern 3: Safe output is constructed, never redacted from wire data

**What:** Build a versioned safe struct from closed route/runtime/lifecycle/outcome/denial enums and bounded metrics. Do not expose a public constructor that accepts a replay request, outcome, or arbitrary metadata map. [VERIFIED: 160-CONTEXT.md]

**When to use:** Before every telemetry emit, Logger call, doctor/inspection/aggregate serialization, generated proof assertion, or evidence promotion. [VERIFIED: 160-CONTEXT.md]

### Anti-Patterns to Avoid

- **Current cookies imply local ownership:** Cookies do not authorize an old partition; require a matching host-mapped scope. [VERIFIED: 160-CONTEXT.md]
- **One authorization snapshot for a batch:** A flag/session may change after event one; re-check before each event. [VERIFIED: 160-CONTEXT.md]
- **Bulk `insert_all` outcomes:** Existing host code cannot attach admission and an explicit result to each event. [VERIFIED: codebase grep]
- **Logging `inspect(request)` or warning with rejected payload:** This exposes sensitive transport data. Use stable rule ID, owning layer, and safe class only. [VERIFIED: 160-CONTEXT.md]
- **Delete on blocked/rejected/conflict:** Only accepted entries may be removed; every other terminal state remains for host recovery. [VERIFIED: 160-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Generic synchronization | Parallel, account-general sync engine | Scoped serial journal/replay contract | Phase scope is one mutation island; generic reconciliation is explicitly excluded. [VERIFIED: AGENTS.md] |
| Account identity storage | Account-derived database names/digests | Opaque host-issued `scope_ref` and compound keys | Keeps account mapping and retention policy host-owned. [VERIFIED: 160-CONTEXT.md] |
| Auth provider/session control | Tokens, cookies, provider/device adapters in core | Host backend session authority plus optional Sigra adapter | Backend remains authoritative; core consumes only closed result. [VERIFIED: 160-CONTEXT.md] |
| Sanitization | Recursive arbitrary-map scrubber as primary defense | Typed safe-observation allowlist | It excludes unknown/nested values before serialization. [VERIFIED: 160-CONTEXT.md] |
| New proof pipeline | Separate Phase 160 report/evidence writer | Phase 159 generated scaffold, allowlist scanner, and promotion flow | Prevents a second, weaker retained-evidence surface. [VERIFIED: 160-CONTEXT.md] |

**Key insight:** The difficult work is authority and information-flow containment, not queuing HTTP requests; reuse the existing host and proof seams so each boundary has one owner. [VERIFIED: 160-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: A stale async completion mutates the new account state

**What goes wrong:** A request started under scope A returns after B activates and deletes/updates B's UI.  
**How to avoid:** Capture scope+epoch on dispatch; check both before every storage/UI mutation; tests must switch during an in-flight request. [VERIFIED: 160-CONTEXT.md]

### Pitfall 2: Scope exists in the payload but not in the storage access path

**What goes wrong:** `getAll()` or an unscoped cursor drains data from every retained partition.  
**How to avoid:** Make compound scope/local keys and scope-only indexes the sole API; do not ship an `all` read/drain. [VERIFIED: 160-CONTEXT.md]

### Pitfall 3: Payload leaks through a secondary egress

**What goes wrong:** Main telemetry is scrubbed, but Logger, doctor, a rejected-result warning, aggregate, generated artifact, or final evidence retains a canary.  
**How to avoid:** Positive schema tests plus forbidden-byte injection through every egress and Phase 159 final-byte scan. [VERIFIED: 160-CONTEXT.md]

### Pitfall 4: Disablement is treated as a transport failure

**What goes wrong:** The client hot-retries, deletes work, or shows an online-only fallback after the host disables the route.  
**How to avoid:** Return typed `blocked`, halt the drain, retain entries, and render calm paused copy. [VERIFIED: 160-CONTEXT.md]

## Code Examples

### Exact-scope IndexedDB lookup

```javascript
// Source: 160-CONTEXT.md (pseudocode; migrate existing offline_study.js API)
function entriesForScope(store, scopeRef) {
  return store.index('by_scope_local').getAll(
    IDBKeyRange.bound([scopeRef, ''], [scopeRef, '\uffff'])
  );
}
```

### Safe-observation boundary

```elixir
# Source: 160-CONTEXT.md (pseudocode)
%SafeObservation{
  schema_version: "1",
  route_id: route_id,
  lifecycle: :paused,
  outcome: :blocked,
  denial_class: :auth_required,
  count: 1
}
# No scope_ref, payload, event references, tokens, identities, endpoints, or free map.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Single unscoped browser store and batch bulk insert | Scope-keyed storage, lifecycle fence, and per-event admission/transaction | Phase 160 | Enables explicit account isolation and mid-batch disablement behavior. [VERIFIED: codebase grep] |
| Broad replay/telemetry serializers | Transport vs. safe-observation types | Phase 160 | Makes sensitive data structurally unavailable to diagnostic surfaces. [VERIFIED: 160-CONTEXT.md] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | Exact conservative `scope_ref` grammar/length and batch ceiling can be selected during implementation. | User Constraints | A too-permissive or too-small limit could affect compatibility; keep versioned and test it. |
| A2 | The existing example host is the intended concrete migration target before a real adopter host exists. | Architecture Patterns | Planning could target an incorrect host seam; preserve `unknown_blocking` adopter inputs. |

## Resolved External Inputs

Both items below are **RESOLVED** for Phase 160 planning. Their disposition is intentionally
`unknown_blocking`: they are external host/adopter inputs, not implementation questions. Phase 160
closes on deterministic host seams and synthetic opaque fixtures without inferring either input or
promoting adopter/device completion.

1. **Host-issued scope format, rotation, and retained-data recovery policy**
   - Disposition: **RESOLVED — external `unknown_blocking` input.**
   - What we know: Core receives only opaque scope references and must preserve blocked partitions. [VERIFIED: 160-CONTEXT.md]
   - What's unclear: Host issuance/rotation/recovery choices are intentionally host-owned. [VERIFIED: 160-CONTEXT.md]
   - Phase 160 boundary: Expose only strict opaque transport validation and a deterministic host activation seam; do not infer semantics. [VERIFIED: 160-CONTEXT.md]

2. **Concrete adopter route/flag/session inputs**
   - Disposition: **RESOLVED — external `unknown_blocking` input.**
   - What we know: TODO-002/adopter-instance completeness remains `unknown_blocking`. [VERIFIED: STATE.md]
   - What's unclear: Real route, mutation, and authorization values. [VERIFIED: STATE.md]
   - Phase 160 boundary: Implement deterministic host seams and synthetic fixtures only; do not promote physical-device/adopter claims. [VERIFIED: AGENTS.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| Elixir/Mix | Core and host ExUnit | ✓ | Mix 1.19.5 / OTP 28 | — [VERIFIED: local command] |
| Node/npm | Existing Playwright proof | ✓ | Node 22.14.0 / npm 11.1.0 | — [VERIFIED: local command] |
| Playwright project | Browser proof | ✓ | lockfile 1.60.0 | Existing host script [VERIFIED: codebase grep] |
| Physical iPhone host/auth adapter | Later device evidence | ✗ | — | Keep Phase 160 deterministic proof; Phase 162 remains dependent. [VERIFIED: STATE.md] |

**Missing dependencies with no fallback:** None for Phase 160's deterministic code/proof scope. [VERIFIED: STATE.md]

**Missing dependencies with fallback:** Physical-device/adopter authority is later evidence, not a Phase 160 completion gate. [VERIFIED: STATE.md]

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit; existing Phoenix-host Playwright 1.60.0 [VERIFIED: codebase grep] |
| Config file | `mix.exs`; `examples/phoenix_host/playwright.config.ts` [VERIFIED: codebase grep] |
| Quick run command | `mix test test/crosswake/offline/journal_test.exs test/crosswake/offline/replay_test.exs test/crosswake/offline/telemetry_test.exs` |
| Full suite command | `mix test && (cd examples/phoenix_host && npm test)` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| SCOPE-01 | Required opaque scope on entry/request; no cross-partition reads | unit + Playwright | `mix test test/crosswake/offline/{journal,replay}_test.exs` and host `npm run proof:offline-island` | ❌ Wave 0 extensions |
| SCOPE-02 | Fence before switch; stale completion inert; blocked queue retained | unit + browser integration | host Playwright scoped replay spec | ❌ Wave 0 |
| SCOPE-03 | Reauthorize each event; mismatch/disablement denies; atomic duplicate/retry | Phoenix integration + Playwright | `MIX_ENV=test mix test` in `examples/phoenix_host` plus scoped proof spec | ❌ Wave 0 |
| SCOPE-04 | Canaries absent from every egress and evidence bytes | unit/property-style + artifact | core tests plus existing Phase 159 evidence check | ❌ Wave 0 |
| SCOPE-05 | Sigra allow/deny adapter only; missing/incompatible denies | companion unit + host integration | `cd packages/crosswake_sigra && mix test` | ❌ Wave 0 extension |

### Sampling Rate

- **Per task commit:** focused ExUnit/Playwright command for the modified seam. [VERIFIED: AGENTS.md]
- **Per wave merge:** core and Phoenix-host full suites. [VERIFIED: AGENTS.md]
- **Phase gate:** Run the Phase 159-compatible generated proof/evidence scan; a blocked native/device result is non-passing. [VERIFIED: 160-CONTEXT.md]

### Wave 0 Gaps

- [ ] Extend core offline contract tests for scope-required maps, blocked outcomes, and safe-observation serialization.
- [ ] Add host controller/context integration tests for exact scope mismatch, Nth-event gate change, rollback/lost-response duplicate, and retained outcomes.
- [ ] Extend the existing host Playwright proof adapter/spec for two scopes, relaunch inactive, switch-before-send, switch-in-flight, and no raw canary in reachable proof surfaces.
- [ ] Extend Sigra tests for replay-only closed projection and missing/incompatible adapter denial.
- [ ] Extend Phase 159 evidence schema/scanner assertions with named Phase 160 closed assertion IDs only.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | yes | Backend-resolved session; Sigra closes only to allow/deny. [VERIFIED: 160-CONTEXT.md] |
| V3 Session Management | yes | Fence logout/switch, reject stale/mismatched scopes, no shell token authority. [CITED: https://cornucopia.owasp.org/taxonomy/asvs-5.0/07-session-management/02-fundamental-session-management-security] |
| V4 Access Control | yes | Recheck route/host authorization per event and fail closed. [VERIFIED: 160-CONTEXT.md] |
| V5 Input Validation | yes | Closed bounded envelope shape/keys and non-echoing rejection. [VERIFIED: 160-CONTEXT.md] |
| V6 Cryptography | no | Host owns encryption/retention; core must neither derive nor hash scopes. [VERIFIED: 160-CONTEXT.md] |
| V7 Error Handling and Logging | yes | Allowlisted safe observations; logs retain stable classes/rules only. [CITED: https://cornucopia.owasp.org/taxonomy/asvs-5.0/16-security-logging-and-error-handling/03-security-events] |
| V8 Data Protection | yes | No sensitive references/payloads in diagnostic or proof planes. [VERIFIED: AGENTS.md] |

### Known Threat Patterns for Phoenix + offline island

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Replaying A's entry after B activates | Spoofing / Elevation | Required scope equality, partitioned indexes, lifecycle epoch, server-side reauthorization. [VERIFIED: 160-CONTEXT.md] |
| Stale request applies after logout/revocation | Tampering | Fence client worker plus re-check backend authority immediately before each event. [VERIFIED: 160-CONTEXT.md] |
| Duplicate after lost response | Repudiation / Tampering | One idempotency decision and domain effect in a host transaction. [VERIFIED: 160-CONTEXT.md] |
| Payload/token/scope leak through diagnostics | Information Disclosure | Typed allowlist plane, egress canaries, final-byte evidence scan. [VERIFIED: 160-CONTEXT.md] |
| Disabled route keeps draining | Elevation / Tampering | Existing `gated_by` check at entry and per-event replay, typed blocked halt. [VERIFIED: 160-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `160-CONTEXT.md` — locked Phase 160 lifecycle, admission, privacy, proof, and non-goal decisions. [VERIFIED: codebase grep]
- Existing journal/replay/telemetry, Sigra, Phoenix host, and Phase 159 proof files — concrete migration seams. [VERIFIED: codebase grep]
- `AGENTS.md`, requirements, state, and roadmap — project constraints and active scope. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- [OWASP ASVS session management controls](https://cornucopia.owasp.org/taxonomy/asvs-5.0/07-session-management/02-fundamental-session-management-security) — backend verification of session tokens. [CITED: https://cornucopia.owasp.org/taxonomy/asvs-5.0/07-session-management/02-fundamental-session-management-security]
- [OWASP ASVS security-event controls](https://cornucopia.owasp.org/taxonomy/asvs-5.0/16-security-logging-and-error-handling/03-security-events) — safe security logging coverage. [CITED: https://cornucopia.owasp.org/taxonomy/asvs-5.0/16-security-logging-and-error-handling/03-security-events]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — existing dependencies and exact host seams were inspected. [VERIFIED: codebase grep]
- Architecture: HIGH — locked CONTEXT decisions specify ownership/order. [VERIFIED: 160-CONTEXT.md]
- Pitfalls: HIGH — each follows a stated failure mode and current unscoped/bulk/egress implementation. [VERIFIED: codebase grep]

**Research date:** 2026-08-02  
**Valid until:** 2026-08-09 (active implementation phase)
