# Companion Integrations

Crosswake companions are first-party, typed integration seams. They are not a generic plugin bus, and they do not override route ownership. Route policy remains authoritative per route; companions can only add fail-closed restrictions.

This guide is the single canonical v3.5 companion guide. It explains the shared `Crosswake.Companion` contract first, then the shipped companion surfaces (Rulestead, Rindle, Sigra), then proof posture and explicit non-goals.

## Core Contract First

Every companion implements `Crosswake.Companion` and lives in-tree under `lib/crosswake/companions/<name>/` in v3.5.

Required callbacks:

- `companion_id/0`
- `enabled?/1`
- `route_gated?/2`
- `kill_switch_active?/1`
- `validate_dependency/0`
- `report_state/0`

Registration is host-owned:

```elixir
config :crosswake, :companions, [
  Crosswake.Companions.Rulestead,
  Crosswake.Companions.Rindle
]
```

`validate_dependency/0` is wrapped by doctor telemetry under `[:crosswake, :companion, :validate_dependency]`. When a companion is enabled but its optional dependency is missing, doctor emits `companion.dependency_missing` as an `:error`. This is fail-closed posture for support truth and release readiness.

## Route Ownership And Fail-Closed Semantics

Companions are bounded seams around policy decisions. They never create a hidden authority path.

- A companion can deny (`:gate_denied`, `:kill_switch_active`, `:step_up_required`) but cannot silently allow a route that core policy denied.
- `kill_switch_active?/1` short-circuits ahead of route-level gate decisions.
- Missing optional dependency is never treated as healthy support.
- High-frequency or arbitrary cross-runtime messaging is out of scope.

Companion guidance in this file is contract truth, not marketing surface.

## Rulestead Surface (GATE)

Companion id: `:rulestead`.

Rulestead is the shipped feature-gating companion. Route policy binds a route to a gate key using `gated_by`, and unavailable handling uses `on_unavailable`.

```elixir
live "/beta-feature", BetaFeatureLive,
  crosswake: [
    id: "beta-feature",
    gated_by: :rulestead,
    on_unavailable: :deny
  ]
```

Runtime denial vocabulary includes:

- `:gate_denied`
- `:kill_switch_active`

The in-tree mock source for deterministic local and hermetic proof is `Crosswake.Companions.Rulestead.MockFlagSource` with `set_flag/2`.

```elixir
Crosswake.Companions.Rulestead.MockFlagSource.set_flag(:rulestead, :gated)
Crosswake.Companions.Rulestead.MockFlagSource.set_flag(:rulestead, {:rolling_out, 50})
Crosswake.Companions.Rulestead.MockFlagSource.set_flag(:rulestead, :killed)
```

Support truth for runtime gate state is exported from `Crosswake.SupportMatrix.gating_truth/0`, with label `Crosswake.SupportMatrix.gating_truth_label/0`.

## Rindle Surface (MEDIA)

Companion id: `:rindle`.

Rindle is the shipped media companion seam. It keeps media authority backend-owned and typed:

- `UploadGrant` constrains presign authority (expiry, limits, accepted types, idempotency key).
- `CaptureEvidence` is evidence from device-side capture/upload, not authority.
- `MediaObject` state is explicit (`:queued`, `:uploaded`, `:scanning`, `:available`, `:rejected`).

Critical posture:

- Direct upload success is not committed media.
- Only backend verification advances media to `:available`.
- `:queued` is not equivalent to committed or durable media availability.

This mirrors Crosswake’s reconciliation stance: evidence can move workflow, but authority stays backend-owned.

## Sigra Surface (AUTH, Session Authority)

Sigra now ships the backend-owned session-authority route evaluator, Phase 55 handoff ticket contract machinery, Phase 56 server-owned step-up intent plus shared Plug/LiveView ceremony, Phase 57 OAuth/passkey/native auth-return boundary contracts, and Phase 58 auth telemetry plus security closeout. It defines typed auth contract surfaces, explicit route-local auth posture, route-local `auth_return` seams, short-lived handoff envelopes, authoritative server-side ticket records, server-owned step-up intent records, host-owned auth-return attempt records, low-cardinality telemetry metadata, and fail-closed route checks without shipping provider-specific OAuth templates, passkey SDK wrappers, refresh-token orchestration, or native auth UI.
It intentionally has no runtime `Companion id:` marker yet because it is not a `Crosswake.Companion` optional dependency surface.

- `AuthContext`
- `SessionAuthorityLane`
- `Crosswake.Companions.Sigra.Handoff`
- `Crosswake.Companions.Sigra.StepUp`
- `Crosswake.Companions.Sigra.AuthReturn`
- `Crosswake.Companions.Sigra.Telemetry`
- `Crosswake.Companions.Sigra.StepUpCeremony.evaluate_or_issue/3`
- `Crosswake.Companions.Sigra.Evaluator.evaluate_route_auth/3`
- Route predicates: `auth_min_level`, `requires_recent_auth`, `auth_posture`
- Auth return route seam: `auth_return`
- Auth posture vocabulary: `:strict_recent`, `:remembered_ok`, `:cached_read_only_ok`
- Denial vocabulary: `:step_up_required`
- Canonical subcodes: `auth.step_up.missing_context`, `auth.step_up.invalid_context`, `auth.step_up.non_active`, `auth.step_up.idle_expired`, `auth.step_up.absolute_expired`, `auth.step_up.revoked`, `auth.step_up.version_mismatch`, `auth.step_up.insufficient_assurance`, `auth.step_up.stale_auth`, `auth.step_up.remembered_not_allowed`, `auth.step_up.cached_not_allowed`, `auth.handoff.missing_ticket`, `auth.handoff.invalid_ticket`, `auth.handoff.expired_ticket`, `auth.handoff.replayed_ticket`, `auth.handoff.revoked_ticket`, `auth.handoff.binding_mismatch`, `auth.handoff.intent_mismatch`, `auth.handoff.route_mismatch`, `auth.handoff.projection_failed`, `auth.step_up_intent.missing_intent`, `auth.step_up_intent.invalid_intent`, `auth.step_up_intent.expired_intent`, `auth.step_up_intent.consumed_intent`, `auth.step_up_intent.canceled_intent`, `auth.step_up_intent.revoked_intent`, `auth.step_up_intent.route_mismatch`, `auth.step_up_intent.binding_mismatch`, `auth.step_up_intent.challenge_failed`, `auth.step_up_intent.projection_failed`, `auth.return.oauth.missing_return`, `auth.return.oauth.invalid_return`, `auth.return.oauth.expired_return`, `auth.return.oauth.replayed_return`, `auth.return.oauth.state_mismatch`, `auth.return.oauth.nonce_mismatch`, `auth.return.oauth.pkce_missing`, `auth.return.oauth.redirect_mismatch`, `auth.return.passkey.missing_return`, `auth.return.passkey.invalid_return`, `auth.return.passkey.expired_return`, `auth.return.passkey.replayed_return`, `auth.return.passkey.challenge_mismatch`, `auth.return.passkey.origin_mismatch`, `auth.return.passkey.rp_id_mismatch`, `auth.return.passkey.user_verification_missing`, `auth.return.native_auth.missing_return`, `auth.return.native_auth.invalid_return`, `auth.return.native_auth.expired_return`, `auth.return.native_auth.replayed_return`, `auth.return.native_auth.link_unverified`, `auth.return.native_auth.callback_mismatch`, `auth.return.native_auth.projection_failed`

Route authority comes from backend projection into `SessionAuthorityLane`. Handoff envelopes, step-up locators, auth-return envelopes, deep links, bridge events, provider payloads, and telemetry events are signed, typed, or diagnostic evidence only; the server-side ticket, intent, or auth-return attempt record remains the source of truth for replay, cancellation/revocation, expiry, route binding, intent binding, audit evidence, Phoenix session-renewal instructions, CSRF rotation posture, LiveView invalidation posture, and refreshed authority projection. Shell bridge state, mobile cache state, OAuth/passkey returns, native deep links, and provider payloads are evidence only until backend validation updates that projection.

Auth telemetry uses stable `[:crosswake, :auth, ...]` event names with low-cardinality metadata. It may expose route ids, flow, outcome, denial code, shell reason, auth posture, freshness bucket, lifecycle state, binding result, link verification, validation posture, proof class, and support-safe correlation refs. It must not expose raw tokens, authorization codes, refresh tokens, credential ids, raw nonces, PKCE verifiers, session refs, actor/org/device identifiers, IPs, user agents, provider payloads, emails, or raw `return_to` values.

`auth_posture` makes weakening explicit:

- `:strict_recent` is the default for auth-predicated and sensitive routes. Remembered or cached authority cannot satisfy routes that require recent auth.
- `:remembered_ok` permits remembered backend authority only when assurance, expiry, revocation, and freshness checks pass and no recent-auth predicate is present.
- `:cached_read_only_ok` is limited to explicitly read-only/degraded cached routes; sensitive, mutation-capable, billing, admin, commerce purchase/restore, and native authority-promotion routes fail closed.

Doctor and support truth use stable contract signals, including:

- `auth.route_predicated`
- `auth.step_up_required_contract`
- `diag.auth.sigra_session_authority`

Support truth accessor:

- `Crosswake.SupportMatrix.auth_contract_truth/0`

Session-authority support now includes Phase 55 handoff ticket contracts and server-record redemption proof, Phase 56 step-up intent and Plug/LiveView ceremony proof, Phase 57 OAuth/passkey/native auth-return boundary contracts with host-owned replay source posture, and Phase 58 stable auth telemetry plus STRIDE-style security closeout. It intentionally does not claim provider-specific OAuth templates, passkey SDK wrappers, refresh-token orchestration, provider/device proof, direct shell/WebView token authority, or native auth UI.

## Support Truth Surfaces

Do not treat guide prose as independent truth. Operators and tests should anchor on exported runtime surfaces:

- `Crosswake.SupportMatrix.gating_truth/0`
- `Crosswake.SupportMatrix.auth_contract_truth/0`
- `Crosswake.Shell.Denial.reasons/0`
- `Crosswake.Doctor.run/1` findings

For denial vocabulary, `Crosswake.Shell.Denial.reasons/0` is canonical and includes `:gate_denied`, `:kill_switch_active`, and `:step_up_required`.

## Proof Posture

Companion claims are split by proof class.

- Hermetic merge-blocking proof: must pass without optional dependency present.
- Advisory dependency-present proof: validates optional dependency wiring in controlled lanes.

Advisory checks are evidence, not promotion. A green advisory lane does not widen support claims by itself.

## Deferred Non-Goals (Explicit)

These are deferred by design and are not shipped by the current companion/auth surface:

- Chimeway delivery implementation. Chimeway is seam-only sequencing context, not first-party notification delivery in this milestone.
- Later Sigra machinery: provider-specific OAuth templates, passkey SDK wrappers, refresh-token machinery, provider/device auth proof, direct shell/WebView token authority, and native auth UI. Phase 58 ships telemetry/security closeout for provider-neutral Sigra contracts, not provider/device authority.
- Threadline audit capstone.
- Separate-package extraction of companions. v3.5 keeps companions in-tree under `lib/crosswake/companions/<name>/`.

## What This Guide Does Not Claim

- Not a plugin bus.
- Not a fail-open optional-dependency model.
- Not provider-delivery claims for deferred surfaces.
- Not device-authority claims for media or auth.
- Not route ownership override through companion code.

## Reader Checklist

Use this checklist before claiming companion support:

1. Companion module implements all six callbacks from `Crosswake.Companion`.
2. Module is registered in host `:companions` config intentionally.
3. `validate_dependency/0` emits expected outcome under doctor with telemetry span `[:crosswake, :companion, :validate_dependency]`.
4. Route policy usage is explicit (`gated_by`, `on_unavailable`, `auth_min_level`, `requires_recent_auth`, `auth_posture`) and denial vocabulary is fail-closed.
5. Support truth from `Crosswake.SupportMatrix.gating_truth/0` and `Crosswake.SupportMatrix.auth_contract_truth/0` matches guide language.
6. Hermetic proof lane passes without optional deps; advisory lane behavior stays advisory.

## Cross-Guide Boundary

For commerce-specific reconciliation vocabulary and storefront posture, see [`guides/commerce.md`](commerce.md). This companion guide remains companion-contract scoped.
