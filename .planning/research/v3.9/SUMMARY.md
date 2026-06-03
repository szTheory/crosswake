# v3.9 Research Summary: Chimeway Notification Seam

**Defined:** 2026-06-02
**Milestone:** v3.9 Chimeway Notification Seam

## Recommendation

Build v3.9 as an in-tree first-party Chimeway companion seam with a narrow core route-policy hook, not as a Crosswake push-delivery platform.

Core should expose route-policy/manifest truth, denials, support matrix, doctor/operator output, and proof posture. `Crosswake.Companions.Chimeway` should own provider-neutral token evidence, backend token binding contracts, revocation semantics, notification-open envelopes, resolver evaluation, telemetry, and provider diagnostics. Separate package extraction remains deferred until compatibility ranges justify it.

## Decision Points

| Decision | Recommendation | Tradeoff |
|----------|----------------|----------|
| Core vs companion | Companion-first with a tiny core hook | Keeps notification/provider/native complexity out of core while preserving route policy as the authority boundary. |
| Token snapshot vs backend binding | Existing `notifications.token.get` is evidence only; backend binding is authority | Requires host registry plumbing, but prevents token possession from becoming auth or deliverability truth. |
| Provider-specific vs provider-neutral contracts | APNs/FCM normalize into canonical Chimeway evidence and feedback | Keeps provider quirks useful without leaking provider vocabulary into route policy. |
| Open URL vs route resolver | Resolve `notification_ref/open_ref + route_id + action_ref` through manifest-known routes | Less magical than raw URLs; avoids route-policy bypass and silent home fallback. |
| Delivery proof | Hermetic token/open proof is merge-blocking; APNs/FCM device delivery remains advisory | Honest support truth over brittle provider/device CI. |

## Recommended Contract Shape

- `TokenEvidence`: provider, platform, environment, token or token ref, notification status, shell/app metadata, observed_at, correlation ref.
- `TokenBinding`: backend-owned projection with subject/org/session scope, installation ref, token fingerprint, provider, state, timestamps, and revocation reason.
- `ProviderFeedback`: normalized provider invalidation and delivery feedback that can revoke or prune bindings without proving delivery.
- `NotificationOpenEvidence`: notification/open ref, route id, action ref, provider, source, opened_at, correlation ref, and bounded evidence metadata.
- `OpenResolution`: allowed route activation or fail-closed denial.

## Architecture Notes

- Bind only after backend auth/session context exists; shell token evidence is never identity.
- Allow many active tokens per actor, but only one active binding per provider/environment/token fingerprint.
- Revoke displaced bindings in the same transaction as new binding upsert.
- Preserve safe audit truth after revocation; raw token material is host-owned and must be encrypted or referenced through a host secret boundary.
- Use `Ecto.Multi` for example-host bind/rotate/revoke flows.
- Do not make Oban a Crosswake dependency; provide optional Chimeway/host worker recipes only.
- Notification opens call RouteGate with `activation_source: :notification` and reuse Sigra session authority for auth-sensitive routes.

## Failure Modes To Design Against

- Token snapshot becomes user, session, or delivery authority.
- Token rotation, logout, restore, reinstall, or provider invalidation leaves stale active bindings.
- Raw tokens, provider payloads, notification body data, route params, or PII leak into telemetry, fixtures, logs, denials, or docs.
- Notification payload opens a sensitive route directly.
- Auth-sensitive notification opens bypass Sigra step-up.
- Replayed or forwarded notification opens remain valid indefinitely.
- Bad notification refs silently fall back to dashboard/home.
- Provider/device behavior is presented as merge-blocking proof before it is repeatable.

## Proof Posture

Merge-blocking:

- Token evidence, binding, rotation, revocation, stale/invalid state contracts.
- Example-host lifecycle proof for bind, rotate, revoke, prune, and provider invalidation.
- Notification-open intent validation, expiry, replay, route mismatch, policy denial, and Sigra step-up.
- Doctor/support/operator/docs parity.
- Telemetry forbidden-key checks.

Advisory:

- Real APNs/FCM token issuance and rotation.
- Real push delivery and notification-open behavior on devices or simulators.
- Provider credentials, project/package/topic mismatch checks, and console metrics.
- OS-specific notification-tray, background, Focus, Doze, and action-button behavior.

## Sources Consulted

- Local Crosswake prompts and milestone arc.
- Local Chimeway host integration seam, adapter contract, rendering channel, and telemetry guidance.
- Firebase Cloud Messaging token management guidance.
- Apple APNs registration and notification-response guidance.
- Android notification and FCM receive/open behavior guidance.
- Phoenix/Ecto idioms for token signing, changesets, transactions, and upserts.

