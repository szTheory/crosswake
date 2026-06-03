# Phase 61: Notification-Open Resolver And Route Policy - Research

**Researched:** 2026-06-03
**Domain:** Notification-Open Route Activation & Companion Integration
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### 1. Anti-Replay / Expiry Model — LOCKED (server-side open-intent record)
- **D-01:** Notification opens are validated against a **host-owned, one-time-consumable open-intent record** in `examples/phoenix_host`, NOT a stateless signed envelope. This directly mirrors the repo's existing `sigra_handoff_tickets` / `sigra_step_up_intents` one-time-consume-via-`Ecto.Multi` prior art.
- **D-02:** Add one new example-host table `chimeway_notification_open_intents` (name is planner discretion; prefer this for contract alignment) with at least: `open_ref`, `binding_ref`, `route_id`, `action_ref`, `subject/session/installation scope` (as needed for binding-mismatch checks), `state`, `expires_at`, `consumed_at`, timestamps, and sanitized `metadata`. Add an append-only audit row in the same transaction, consistent with the Phase 60 registry pattern.
- **D-03:** The server **issues** the open-intent when it sends the push; the notification open **consumes** it. Consume is a guarded `Ecto.Multi` flow: load intent → validate → mark consumed → audit → (on success) telemetry after commit.
- **D-04:** Detection falls out of the record as column compares:
  - **expired** = `expires_at < now`
  - **replayed** = `state == :consumed` (or otherwise non-pending)
  - **binding-mismatch** = stored `binding_ref`/`route_id`/scope ≠ envelope, OR the referenced Chimeway binding is no longer `:active`
  - **revoked** = referenced binding `state` is `:revoked`/`:superseded`/`:stale`/`:invalid` (Phase 59 vocabulary)
- **D-05:** Real push delivery stays **advisory**. The intent issue + consume cycle is fully hermetic/in-tree provable without any APNs/FCM dependency. Do not treat provider delivery acceptance as proof an open is valid.
- **D-06:** Raw tokens, provider payloads, notification title/body, route params, and PII must never enter the open-intent row, audit, denials, or telemetry (carry Phase 59/60 redaction posture).

### 2. Resolver Placement + RouteGate Integration — LOCKED (Chimeway resolver delegates to core RouteGate)
- **D-07:** Notification-open **resolver evaluation lives in the Chimeway companion** — `Crosswake.Companions.Chimeway.Resolver` (module name is planner discretion but strongly preferred). Core stays provider-neutral; this matches the StoreKit/PlayBilling/Sigra precedent of companions normalizing/orchestrating and feeding core.
- **D-08:** **Core `RouteGate` requires zero changes** beyond already accepting `activation_source: :notification`. Do NOT add a notification-specific branch inside `RouteGate` — that would leak notification vocabulary into core.
- **D-09:** Resolver public shape (planner discretion on exact spec, preserve intent):
  ```elixir
  @spec resolve(Root.t(), OpenEnvelope.t()) ::
          {:ok, RouteGate.Decision.t()} | {:error, Shell.Denial.t()}
  ```
  where `OpenEnvelope` / `NotificationOpenEvidence` is a Chimeway-namespaced struct holding `route_id`, `notification_ref`/`open_ref`, `action_ref`, `binding_ref`, `provider`, `source`, `opened_at`, `correlation_ref`, `auth_context`, and bounded evidence metadata.
- **D-10:** Resolver pre-flight (companion-owned, BEFORE delegating): (1) `route_id` present in `manifest.routes`; (2) consume the open-intent → expiry/replay/binding-mismatch/revoked checks; (3) route declares notification-open eligibility and the `action_ref` is permitted (see Decision 3).
- **D-11:** After pre-flight passes, the resolver calls `RouteGate.evaluate(manifest, route_id, target, activation_source: :notification, auth_context: envelope.auth_context, ...)` and returns the `Decision.t()` directly. RouteGate already runs kill-switch → gate → Sigra auth → compatibility → commerce, so **Sigra session-authority + step-up reuse is automatic (OPEN-02)** with no duplicated auth logic.
- **D-12:** A `:deny` decision carrying `reason: :step_up_required` is the step-up signal — surfaced to the caller as-is, never re-wrapped.
- **D-13:** Flip `Chimeway.report_state` detail `open_routing: :not_shipped` → `:active` once the resolver ships. Update the matching support-matrix/companion non-claim only as narrowly as Phase 61 requires (broad docs are Phase 62).

### 3. Route-Policy Notification-Open Opt-In — LOCKED (new additive `notification_open:` DSL attribute)
- **D-14:** Add a **new optional per-route DSL attribute** `notification_open:` to the route policy. Default **absent = fail-closed**: routes that do not declare it cannot be activated from a notification.
- **D-15:** Shape: `notification_open: true | [actions: [atom()]]`. `true` opts the route in without action constraint; the `[actions: [...]]` allowlist constrains which named `action_ref`s the route accepts and is what makes the OPEN-03 **"unsupported-action"** denial mechanically expressible.
- **D-16:** Mirror the existing `entry: :external` + `allowlisted_origins` precedent — push-sourced entry is a **distinct threat vector** from deep-link entry and must not be collapsed into it. Do NOT make any manifest-known route implicitly notification-openable.
- **D-17:** Additive/backward-compatible public API: new optional keyword on an existing `route/0` call; no existing call signatures change. Materialize into the manifest `RouteEntry` + builder, validate in `policy/schema.ex` (mirror `validate_external_entry`-style validation), and surface in compatibility findings.

### 4. Notification Denial Vocabulary — LOCKED (new core reason + Chimeway subcodes)
- **D-18:** Add **one new core reason atom** `:notification_open_denied` to `Shell.Denial @reasons` (and its `@type reason`).
- **D-19:** Add a **`Crosswake.Companions.Chimeway.DenialCodes`** module mirroring `sigra/denial_codes.ex` (canonical string subcodes + `sanitize_details/1` allowlist). Canonical subcodes: `notification.open.expired`, `notification.open.replayed`, `notification.open.binding_revoked`, `notification.open.route_mismatch`, `notification.open.binding_mismatch`, `notification.open.unsupported_action`, `notification.open.policy_denied`.
- **D-20:** **Pass RouteGate/Sigra denials through UNCHANGED.** `:step_up_required`, `:gate_denied`, etc. retain their original reason/code.
- **D-21:** Sanitized detail-key allowlist mirrors the locked Chimeway forbidden-key posture (Phase 59 telemetry `@forbidden_metadata_keys`).

### Claude's Discretion
- Exact module names (`Resolver`, `OpenEnvelope`/`NotificationOpenEvidence`, `OpenResolution`, `DenialCodes`), struct keys, and the open-intent table/migration names — preserve the locked semantics above.
- Exact `notification_open:` keyword spelling and whether action allowlist is `[actions: [...]]` vs a flatter form — preserve explicit opt-in + fail-closed default + action allowlisting.
- Exact denial subcode strings, telemetry event names, and idempotency/consume-key shape — preserve stability, low cardinality, and sanitization.
- Test file placement (`test/crosswake/companions/chimeway/`, `test/crosswake/proof/phase61_*`, and/or example-host tests), following existing phase-proof conventions.

### Deferred Ideas (OUT OF SCOPE)
- Broad doctor, operator inspection, support-matrix, docs-contract parity, and telemetry rollout for notification token/open readiness — Phase 62 (DIAG-01/DIAG-02).
- Merge-blocking proof-lane consolidation and APNs/FCM advisory promotion criteria — Phase 63 (PROOF-01/PROOF-02).
- Real APNs/FCM token issuance/rotation, real push delivery + notification-open behavior on devices/simulators, provider credentials, project/package/topic mismatch checks, notification-tray/Focus/Doze/background/action-button behavior, and provider console metrics — advisory/future work.
- Production-normalized token/device/installation/subject model and bundled Chimeway/Oban/Quantum/Broadway workers — carried from Phase 60 deferred.
- Stateless signed notification-open envelope (exp+nonce, no DB) — considered and rejected for Phase 61.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OPEN-01 | Notification opens require explicit route opt-in. | `notification_open` attribute added to `Crosswake.Policy.Schema`, materialized in `RouteEntry`. Pre-flight in `Resolver` fails closed. |
| OPEN-02 | Step-up reuse. Notification open activation automatically triggers Sigra step-up if session is insufficient. | Core `RouteGate.evaluate` handles auth correctly. Resolver calls it via `activation_source: :notification` without duplicating auth checks. |
| OPEN-03 | Unsupported-action denial. | Action constraint represented as `[actions: [atom()]]` in policy schema. Resolver verifies `action_ref` against the list and returns `notification.open.unsupported_action`. |
</phase_requirements>

## Summary

This phase implements the backend and policy foundation for notification-open route activation. It introduces a `notification_open:` attribute to the route DSL to allow explicit, fail-closed opt-ins (and action allowlists) for push-activated routes. It implements the resolution lifecycle via a Chimeway companion `Resolver`, which consumes a one-time host-owned `Ecto.Multi` intent record to deterministically handle expiry and anti-replay.

Because the resolver delegates to the existing `RouteGate.evaluate/4` API using `activation_source: :notification`, all core auth, step-up routing (OPEN-02), compatibility, and commerce gating logic is automatically preserved without requiring changes to core logic. A new denial reason `:notification_open_denied` is introduced to the core shell alongside Chimeway-specific subcodes to clearly delineate pre-gate notification evaluation failures from core route-gate failures.

**Primary recommendation:** Implement `Crosswake.Companions.Chimeway.Resolver` to perform pre-flight checks (route explicitly opted-in, intent successfully consumed, action allowlisted) before delegating blindly to `RouteGate.evaluate/4`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Route-Policy DSL `notification_open:` | API / Backend | — | Opt-in must be declared in route definitions and materialized into the immutable manifest. |
| Open Envelope & Resolver | API / Backend | — | Elixir companion normalizes the request, checks intent state, and invokes core RouteGate. |
| Anti-Replay & Expiry (Open-intent record) | Database / Storage | API / Backend | Server-side record is consumed transactionally via `Ecto.Multi` to prevent race conditions and replay. |
| Denial Vocabulary | API / Backend | Browser / Client | Canonical denial reason added to core, Chimeway subcodes enforce a safe output boundary. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Ecto | existing | Ecto.Multi transaction flow | Proven pattern for one-time consumed records in the repository (e.g. handoff tickets). |
| NimbleOptions | existing | DSL validation | Existing library for route policy schemas. |

## Architecture Patterns

### Recommended Project Structure
```
lib/
├── crosswake/
│   ├── companions/
│   │   ├── chimeway/
│   │   │   ├── contracts.ex      # (Add NotificationOpenEvidence, OpenResolution)
│   │   │   ├── resolver.ex       # New: Pre-flight + RouteGate delegation
│   │   │   └── denial_codes.ex   # New: Canonical subcodes & detail sanitization
│   └── shell/
│       └── denial.ex             # (Add :notification_open_denied reason)
├── crosswake/policy/
│   └── schema.ex                 # (Add notification_open keyword to NimbleOptions)
examples/phoenix_host/lib/crosswake_example/chimeway/
├── notification_open_intent.ex       # New: Ecto Schema for the one-time record
├── notification_open_intent_event.ex # New: Audit event for the record
└── registry.ex                       # (Add issue/consume multi flows)
```

### Pattern 1: Companion Orchestration and Core Delegation
**What:** The Chimeway Resolver validates notification-specific pre-flight requirements (expiry, replay, mismatch) before delegating to the provider-neutral core `RouteGate`.
**When to use:** Whenever a companion orchestrates entry via a new modality (like push notifications) that ultimately leads to route activation.
**Example:**
```elixir
def resolve(%Root{} = manifest, %NotificationOpenEvidence{} = env) do
  with :ok <- manifest_known_route(manifest, env.route_id),
       {:ok, intent} <- consume_open_intent(env),
       :ok <- action_allowed?(manifest, env.route_id, env.action_ref) do
    RouteGate.evaluate(
      manifest,
      env.route_id,
      target_from(env),
      activation_source: :notification,
      auth_context: env.auth_context
    )
    |> wrap_decision()
  else
    {:error, %Shell.Denial{}} = denial -> denial
  end
end
```

### Anti-Patterns to Avoid
- **Branching in `RouteGate`:** Do not add notification-specific logic inside `RouteGate.evaluate/4`. Let `RouteGate` handle `:notification` as a standard activation source, relying on the companion to do pre-flight.
- **Implicit Opt-In:** Do not allow a route to activate via push if `notification_open` is absent. It must be explicit and default fail-closed.
- **Leaking PII:** Do not allow raw provider tokens or notification content to enter the `Denial` details or telemetry events.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Stateful Anti-Replay | Signed stateless envelopes with nonce caches | `Ecto.Multi` one-time record | Project requires determinism and DB is already present for bindings. Matches existing `sigra_handoff_tickets` pattern. |

## Code Examples

Verified patterns from existing Crosswake codebase:

### Ecto.Multi Consume Flow (Analogy from `handoff.ex`)
```elixir
def consume_notification_open_intent(%NotificationOpenEvidence{} = env) do
  Ecto.Multi.new()
  |> Ecto.Multi.run(:intent, fn repo, _ -> load_and_lock_intent(repo, env.open_ref) end)
  |> Ecto.Multi.run(:validation, fn _repo, %{intent: intent} -> validate_intent(intent, env) end)
  |> Ecto.Multi.update(:consume, fn %{intent: intent} -> mark_consumed(intent) end)
  |> Ecto.Multi.insert(:audit, fn %{consume: consumed} -> build_audit(consumed) end)
  |> Repo.transaction()
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `open_routing: :not_shipped` | `open_routing: :active` | Phase 61 | Chimeway now officially handles route activation via push, enabling testing and client consumption. |

## Assumptions Log

All claims and patterns are directly validated from the Elixir implementation in `lib/crosswake/` and the explicitly locked decisions in the provided `CONTEXT.md` / `DISCUSSION-LOG.md`.

### Open Questions (RESOLVED)

None. The boundaries are firmly locked by the existing architecture and the phase requirements.

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified outside standard Elixir/Phoenix stack).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OPEN-01 | Opt-in policy enforcement & fail-closed default | unit | `mix test test/crosswake/policy/schema_test.exs` | ✅ Wave 0 |
| OPEN-01 | Resolver pre-flight fails when route not in manifest | unit | `mix test test/crosswake/companions/chimeway/resolver_test.exs` | ❌ Wave 0 |
| OPEN-02 | Step-up reuse correctly propagated back to caller | unit | `mix test test/crosswake/companions/chimeway/resolver_test.exs` | ❌ Wave 0 |
| OPEN-03 | Unsupported-action denial enforces allowlist | unit | `mix test test/crosswake/companions/chimeway/resolver_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/crosswake/companions/chimeway/resolver_test.exs` — covers OPEN-01, OPEN-02, OPEN-03
- [ ] `test/crosswake/companions/chimeway/denial_codes_test.exs` — covers sanitization boundaries (D-21)
- [ ] `examples/phoenix_host/test/crosswake_example/chimeway/notification_open_intent_test.exs` — schema unit tests
- [ ] `examples/phoenix_host/test/crosswake_example/chimeway/registry_notification_open_test.exs` — integration tests for intent consumption

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Delegated to RouteGate / Sigra (`:step_up_required`) |
| V3 Session Management | yes | Host-owned bound session references via intent records |
| V4 Access Control | yes | Explicit route-level `notification_open` attribute |
| V5 Input Validation | yes | `Crosswake.Policy.Schema` (NimbleOptions) |
| V6 Cryptography | no | Relies on existing HTTPS boundary |

### Known Threat Patterns for Elixir/Crosswake

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Replay attacks | Tampering | Server-side one-time intent records via Ecto.Multi |
| Session impersonation | Spoofing | Binding-mismatch checks against the open intent |
| PII Leakage in logs/telemetry | Information Disclosure | `Chimeway.DenialCodes.sanitize_details/1` mirroring Sigra pattern |
| Bypass Auth Gate | Elevation of Privilege | Delegate entirely to `RouteGate.evaluate` |

## Sources

### Primary (HIGH confidence)
- `lib/crosswake/compatibility/route_gate.ex` - Verified RouteGate signature and evaluation chain.
- `lib/crosswake/shell/denial.ex` - Verified `@reasons` schema for appending `:notification_open_denied`.
- `lib/crosswake/policy/schema.ex` - Verified `NimbleOptions` schema for adding new DSL attribute.
- `.planning/phases/61-notification-open-resolver-and-route-policy/61-CONTEXT.md` - Verified all locked implementation decisions.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Directly follows repo precedents.
- Architecture: HIGH - Dictated explicitly by CONTEXT.md.
- Pitfalls: HIGH - Documented anti-patterns map to repo DNA.

**Research date:** 2026-06-03
**Valid until:** 30 days
