# Phase 56: Step-Up Intent And Plug/LiveView Ceremony - Research

**Researched:** 2026-06-02
**Domain:** Phoenix-owned step-up intent lifecycle, shared Plug/LiveView challenge ceremony, backend-owned session authority projection
**Confidence:** HIGH

<user_constraints>
## User Constraints

- Phase 56 must provide a server-owned step-up intent and one shared challenge/return flow for routes requiring stronger or fresher backend auth. It must satisfy STEP-01, STEP-02, and STEP-03.
- Core Crosswake owns pure Sigra contracts, validation, denial codes, safe detail allowlists, and fixtures. The Phoenix host owns Repo schemas, challenge UI, Plug.Conn mutation, session renewal, and CSRF behavior.
- `Crosswake.Companions.Sigra.Evaluator` remains pure and transport-agnostic. It can supply the route-auth result that triggers ceremony, but it must not issue intents, redirect controllers, halt LiveViews, renew sessions, or rotate CSRF tokens.
- `RouteGate.evaluate/4` remains the route activation surface. Phase 56 should not turn RouteGate into a challenge issuer or generic policy framework.
- Public shell denial reason remains `:step_up_required`; Phase 56 should add narrow `auth.step_up_intent.*` subcodes and safe details under the existing Sigra denial-code registry.
- Return targets must be manifest-known Crosswake route IDs with typed params, not arbitrary `return_to` URLs.
- Successful step-up must consume the server intent before renewal, project or refresh a backend-owned `SessionAuthorityLane`, return host-owned renewal/CSRF/socket invalidation instructions, and re-prove return-route authority.
- OAuth, passkey, native deep-link, shell bridge return envelopes, provider templates, refresh-token helpers, native auth UI, and final auth telemetry/security closeout stay out of Phase 56.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Planning Implication |
|----|-------------|----------------------|
| STEP-01 | Hosts can create server-owned step-up intents for stronger or fresher auth, with bounded lifecycle states and manifest-known return targets. | Plan pure `StepUpIntent`/locator/challenge/audit contracts plus example-host Ecto issue/cancel/consume proof. |
| STEP-02 | Plug/controller routes and LiveView `on_mount` entry points share one step-up evaluator and fail closed into the same challenge/intent flow. | Plan one Sigra ceremony core and two thin transport adapters with no duplicated auth checks. |
| STEP-03 | Successful step-up consumes the intent, renews session/CSRF posture, refreshes backend authority, and returns only to a validated Crosswake route target. | Plan atomic consume + projection + audit, host renewal instructions, route-target validation, and re-evaluation proof. |
</phase_requirements>

## Summary

Phase 56 should extend Sigra with a step-up ceremony layer, not a provider auth layer. The architecture should mirror the Phase 55 handoff pattern: a low-sensitivity signed/opaque locator plus an authoritative server-side Ecto record in the example host. The record is the only source of truth for lifecycle, expiry, replay, cancellation, route binding, required assurance/freshness, and authority projection.

The right core split is:

- `Crosswake.Companions.Sigra.StepUp` for pure step-up intent, locator, challenge, consume result, audit event, and session renewal instruction contracts.
- `Crosswake.Companions.Sigra.StepUpCeremony` for pure `evaluate_or_issue/3` semantics over route/auth/evaluator output and host callback results.
- Thin `Plug` and `LiveView` adapter modules, likely in the example host first, that call the same ceremony core and handle only redirect/halt mechanics.
- Example-host persistence and challenge flow proving issue, challenge, cancel, consume, replay, expiry, route mismatch, projection failure, session renewal, CSRF rotation instruction, and LiveView remount/socket invalidation hint.

The most important design constraint is that successful challenge evidence is still not authority. It can only cause a backend transaction to consume a valid intent and project a refreshed `SessionAuthorityLane`. After projection, the return route must be validated through Crosswake route/manifest truth again.

## Existing Integration Points

### Core Sigra

- `lib/crosswake/companions/sigra/contracts.ex` already owns `AuthContext`, `SessionAuthorityLane`, `StepUpChallenge`, validation helpers, timestamp comparison, and assurance vocabulary. Phase 56 can reuse the assurance vocabulary and either keep `StepUpChallenge` as reference state or replace it with a richer step-up challenge contract in a sibling module.
- `lib/crosswake/companions/sigra/evaluator.ex` already denies predicated routes for missing context, non-active state, idle/absolute expiry, version mismatch, weak assurance, stale auth, remembered state, and cached state. It explicitly says it does not issue step-up intents or mutate transports. Phase 56 should preserve that boundary and consume its `{:deny, %Denial{reason: :step_up_required}}` result.
- `lib/crosswake/companions/sigra/handoff.ex` is the closest pure-contract analog. It models bounded locators, server records, audit events, redemption results, and `SessionRenewalInstructions` without Ecto or Plug.Conn mutation.
- `lib/crosswake/companions/sigra/denial_codes.ex` is the canonical registry for low-cardinality auth codes and shell-safe details. Extend it with `auth.step_up_intent.*`; do not create a parallel denial registry.
- `lib/crosswake/compatibility/route_gate.ex` is the route activation pipeline. Phase 56 should use it before challenge issuance and after authority projection, but not insert Ecto/Phoenix session logic into it.
- `lib/crosswake/shell/denial.ex` already exposes `:step_up_required`. Keep that public reason stable.

### Example Host

- `examples/phoenix_host/lib/crosswake_example/saas_portal/handoff.ex` proves the Phase 55 host pattern: Phoenix.Token locator, Ecto.Multi issue/redeem/revoke/audit, conditional `update_all` consume, manifest-known route validation, and `SessionAuthorityLane` projection.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex` already applies renewal instructions with `configure_session(conn, renew: true)` after successful handoff redemption. Phase 56 should extend this host-owned boundary with CSRF rotation/delete-session instructions instead of core mutation.
- `examples/phoenix_host/lib/crosswake_example/selective_native/on_mount.ex` is a LiveView hook analog for host-owned mount behavior. Phase 56 should add a Sigra-specific LiveView adapter that redirects and halts, but delegates all decision semantics to the shared ceremony core.
- Existing proof style favors root ExUnit tests that drive example-host code through `test/support/example_host.ex`, avoiding new core dependencies on Phoenix/Ecto.

### Truth Surfaces

- `lib/crosswake/support_matrix/support_matrix.ex`, `lib/crosswake/doctor/doctor.ex`, `lib/crosswake/doctor/publish_readiness.ex`, `lib/crosswake/operator_inspection.ex`, `guides/companions.md`, `guides/support_matrix.md`, and `guides/native_shell.md` currently say Phase 55 handoff ticket/server-record machinery is shipped and Phase 56 ceremony remains deferred. Phase 56 must update that truth while still deferring Phase 57/58 claims.
- Existing docs/proof tests assert support truth and non-claims. Phase 56 should add merge-blocking proof for ceremony support without claiming OAuth/passkey/native auth returns, refresh-token helpers, provider/device proof, or native auth UI.

## Architecture Recommendation

### Core Contract Shape

Add a Sigra-scoped step-up module:

```text
lib/crosswake/companions/sigra/
|-- contracts.ex
|-- denial_codes.ex
|-- evaluator.ex
|-- handoff.ex
|-- step_up.ex
`-- step_up_ceremony.ex
```

Recommended pure structs/functions:

- `StepUpIntentLocator`: low-sensitivity client-presented locator with `typ`, `intent_ref`, `version`, `issuer`, `audience`, `issued_at`, `expires_at`, `source_route_id`, `return_route_id`, `challenge_kind`, and optional digest/correlation fields. It must reject identity/session/provider/credential/CSRF/nonce/PKCE/authority claims.
- `StepUpIntentRecord`: authoritative host record contract with `intent_ref`, `locator_digest`, `state`, `subject_ref`, `org_id`, `source_session_ref`, `expected_session_version`, `source_route_id`, `return_route_id`, typed `return_params`, `required_assurance_level`, `required_auth_posture`, `max_auth_age_seconds`, `challenge_kind`, lifecycle timestamps, `audit_correlation_ref`, and projected authority inputs.
- `StepUpChallenge`: host challenge descriptor with `challenge_ref`, `intent_ref`, `challenge_kind`, `challenge_route_id`, `return_route_id`, `required_assurance_level`, `max_auth_age_seconds`, `expires_at`, safe message, and support ref.
- `StepUpConsumeRequest`: verified locator plus challenge evidence facts, expected route/session/version facts, request ref, and evaluated_at.
- `StepUpCompletion`: success result with consumed intent, projected `SessionAuthorityLane`, route target, audit event, renewal instructions, `rotate_csrf?: true`, and `live_socket_invalidation`.
- `StepUpAuditEvent`: lifecycle evidence for `:issue`, `:challenge`, `:consume`, `:cancel`, `:expire`, `:revoke`, and `:deny`.

Do not place Ecto schemas, Repo operations, Phoenix.Token verification, Plug.Conn mutation, or LiveView redirects in core.

### Shared Ceremony Shape

The ceremony core should be deterministic and host-callback driven:

```elixir
Crosswake.Companions.Sigra.StepUpCeremony.evaluate_or_issue(route, auth_context, opts)
#=> {:allow, facts}
#=> {:challenge, %StepUpIntent{}, %StepUpChallenge{}}
#=> {:deny, %Crosswake.Shell.Denial{}}
```

It should:

1. Call or accept the result of `Sigra.Evaluator.evaluate_route_auth/3`.
2. Return `{:allow, facts}` when route authority is already sufficient.
3. For step-up-required denials that are challengeable, call a host-provided intent issuer callback.
4. Return a typed challenge with route/manifest-known challenge and return targets.
5. Preserve non-challengeable denials as `{:deny, %Denial{}}`.

The core should not know how to redirect a controller or LiveView. Plug and LiveView adapters should receive `{:challenge, intent, challenge}` and perform transport-specific redirect/halt behavior.

### Example-Host Persistence Shape

Add example-host modules analogous to Phase 55 handoff:

```text
examples/phoenix_host/lib/crosswake_example/saas_portal/
|-- step_up.ex
|-- step_up_intent.ex
|-- step_up_audit_event.ex
|-- step_up_plug.ex
`-- step_up_on_mount.ex
```

Add migrations for `sigra_step_up_intents` and `sigra_step_up_audit_events`. Useful indexes:

- unique `intent_ref`
- unique `locator_digest`
- index `state`
- index `expires_at`
- index `source_session_ref`
- index `audit_correlation_ref`

Use conditional `update_all` consume/cancel/revoke queries, not check-then-update Elixir branching. Expiry must be enforced from `expires_at` even when state is still `"issued"` or `"challenged"`.

### Return Target And Renewal

Store `return_route_id` and typed allowlisted params. Hosts may translate a web path into a route id before issuing an intent, but the persisted source of truth should not be an arbitrary URL.

On completion:

1. Verify locator and fetch matching server intent.
2. Validate lifecycle, expiry, route binding, session binding, challenge kind, and evidence posture.
3. Atomically consume the intent, append audit evidence, and build a refreshed `SessionAuthorityLane`.
4. Re-run `RouteGate.evaluate/4` or equivalent proof for `return_route_id` with the projected lane.
5. Return host-owned renewal instructions: renew Phoenix session, rotate/delete CSRF posture, put explicit Crosswake session keys, delete transient step-up keys, and invalidate/remount LiveView sockets.

## Recommended Denial Codes And Safe Details

Add at least:

- `auth.step_up_intent.missing_intent`
- `auth.step_up_intent.invalid_intent`
- `auth.step_up_intent.expired_intent`
- `auth.step_up_intent.consumed_intent`
- `auth.step_up_intent.canceled_intent`
- `auth.step_up_intent.revoked_intent`
- `auth.step_up_intent.route_mismatch`
- `auth.step_up_intent.binding_mismatch`
- `auth.step_up_intent.challenge_failed`
- `auth.step_up_intent.projection_failed`

Public invalid/tamper/unknown/malformed/bad-signature causes should collapse to `auth.step_up_intent.invalid_intent`.

Safe details should be support-oriented and low-cardinality:

- `step_up_intent_ref` only if it is a generated support ref
- `intent_state`
- `challenge_kind`
- `required_assurance_level`
- `max_auth_age_seconds`
- `auth_posture`
- `route_binding`
- `intent_expires_at`
- `intent_age_seconds`
- `evaluated_at`

Drop raw locator tokens, intent refs, session refs, actor/org/device identifiers, provider payloads, passkey credential IDs, OAuth artifacts, nonces, PKCE material, CSRF tokens, IPs, and user agents from shell-safe details.

## Validation Architecture

Validation should be layered and fail closed:

1. Route auth evaluation: `Sigra.Evaluator` determines whether the route is already allowed or needs step-up.
2. Intent issue validation: source route and return route exist in the compiled Crosswake manifest; required assurance/freshness and challenge kind are closed-vocabulary values.
3. Locator validation: client-presented locator has supported type/version/audience and contains only low-sensitivity locator/correlation fields.
4. Server record validation: authoritative intent row exists, digest matches, lifecycle state is issueable/challengeable/consumable, and `expires_at` is still in the future.
5. Binding validation: subject/org/session/version/device-if-backend-bound, source route, return route, challenge kind, and required posture match backend-known facts.
6. Challenge evidence validation: evidence is host-owned and challenge-kind scoped; evidence alone does not set authority.
7. Atomic consume: conditional update consumes one valid unconsumed intent, appends audit, and projects `SessionAuthorityLane`.
8. Return route validation: projected authority satisfies `RouteGate.evaluate/4` for the stored return route id.
9. Host renewal boundary: successful completion returns instructions for session renew, CSRF rotation/deletion, transient key cleanup, and LiveView remount/socket invalidation.
10. Truth-surface validation: support matrix, doctor, operator inspection, guides, fixtures, and proof distinguish shipped Phase 56 ceremony from Phase 57/58 deferred work.

## Proof Strategy

Plan proof in four layers:

1. Core contract tests:
   - Step-up intent lifecycle vocabulary is closed: `:issued`, `:challenged`, `:consumed`, `:expired`, `:canceled`, `:revoked`.
   - Locator rejects authority, identity, credential, provider, nonce, PKCE, CSRF, and raw session fields.
   - Completion requires `%SessionAuthorityLane{}` and host-owned renewal instructions.
   - Denial registry includes exact `auth.step_up_intent.*` codes and sanitizes details.

2. Example-host lifecycle tests:
   - Issue creates a server record, signed/opaque locator, and audit event.
   - Shared ceremony issues a challenge for an insufficient/stale auth route.
   - Cancel/expire/revoke/consume/replay paths produce stable denial codes.
   - Challenge success consumes once, projects a refreshed lane, writes audit, and returns renewal/CSRF/socket instructions.
   - Projection failure does not renew session or redirect to arbitrary targets.

3. Plug/LiveView adapter tests:
   - Plug adapter redirects and halts to the same challenge target returned by the core ceremony.
   - LiveView `on_mount` adapter redirects and returns `{:halt, socket}` for the same challenge decision.
   - Both paths use the same shared ceremony module and do not duplicate assurance/freshness/version logic.

4. Support/docs proof:
   - Support matrix and doctor show step-up intent/ceremony as shipped.
   - Guides remove obsolete "ceremony deferred" language.
   - Proof asserts no Phase 57/58 overclaims: no OAuth/passkey/native return validation, refresh-token helper, provider/device proof, or native auth UI claim.

## Risk And Footgun List

- **Open redirect:** Raw `return_to` values must not survive into persisted intent authority.
- **Self-contained token authority:** Signed locators must not carry session/assurance claims that route gates trust.
- **Replay race:** Consume must use a conditional transaction/update that succeeds for exactly one issued/challenged, unconsumed, unexpired row.
- **Expiry cleanup confusion:** Cleanup jobs can lag; consume must deny from `expires_at`.
- **Divergent Plug/LiveView logic:** Separate auth logic for controllers and LiveView would produce inconsistent route security. Share one core.
- **Stale LiveView sockets:** Session renewal after step-up must remount/invalidate or force re-evaluation; do not keep privileged stale assigns.
- **Session mutation in core:** Crosswake core should return instructions, not mutate host connections.
- **CSRF posture drift:** Completion should explicitly instruct CSRF rotation/deletion so sensitive action freshness is not tied to stale tokens.
- **Overclaiming support:** Phase 56 ships ceremony contracts and example proof, not OAuth/passkey/provider/native auth returns.
- **Leaky denials:** Public detail fields must not reveal raw intent/session/actor/org/device/provider/credential/token material.

## Planning Notes

- A good plan split is: core step-up contracts and denial codes; example-host persistence/consume/renewal proof; shared ceremony plus Plug/LiveView adapters; support/docs/proof promotion.
- Keep the first plan pure and low-risk so later host flows depend on stable contracts.
- Give the consume/projection plan enough room for race/replay/expiry proof; that is the highest-risk implementation point.
- Keep diagnostics/support promotion in this phase narrow. Stable auth telemetry taxonomy and final security closeout belong to Phase 58, but proof should still ensure Phase 56 does not leak sensitive details.

## RESEARCH COMPLETE
