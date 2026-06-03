# Phase 59: Chimeway Contract And Token Binding Semantics - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-02
**Phase:** 59-Chimeway Contract And Token Binding Semantics
**Areas discussed:** Contract surface shape, Authority boundary, Lifecycle and provider vocabulary, Raw-token redaction and DX

---

## Contract Surface Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal bridge response wrapper | Wrap `notifications.token.get` response directly. Lowest effort but keeps raw token too close to public contract and misses binding lifecycle. | |
| Provider evidence only | Normalize APNs/FCM facts into evidence structs. Good evidence posture but no backend authority projection. | |
| Backend binding only | Model backend binding projection. Strong authority posture but loses evidence provenance. | |
| Combined evidence + binding family | Use `TokenEvidence`, `TokenBinding`, `ProviderFeedback`, and `BindingEvent`/`AuditEvent`. Separates evidence from authority while staying compact. | ✓ |

**User's choice:** Discuss all areas with sub-agent research and produce one coherent recommendation.
**Notes:** Research recommended the combined family because it matches v3.7 commerce evidence normalization and v3.8 Sigra backend-authority patterns.

---

## Authority Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Token possession as registration authority | Shell obtains APNs/FCM token and server stores it directly under claimed identity. Simple but violates Crosswake authority rules. | |
| Evidence requires authenticated backend context | Token evidence is redacted/fingerprinted and bound only after backend auth/session context exists. | ✓ |
| Subject + session + installation scope | Binding carries subject/session/install facts for auth-sensitive revocation and audit. | ✓ |
| Installation-only association | Store token by installation first, then associate after login. Useful for readiness but dangerous if promoted implicitly. | Partial |
| Self-contained signed binding artifact | Use signed artifacts as locators/correlation. Useful but not authority. | Partial |
| Provider-owned identity mapping | Lean on provider external ids/token registries. Familiar but not Phoenix authority. | |

**User's choice:** Discuss all areas with sub-agent research and produce one coherent recommendation.
**Notes:** Locked boundary: `notifications.token.get` is evidence only; backend-owned binding requires authenticated context. Installation-only records can exist as unassociated evidence/readiness, not user delivery authority.

---

## Lifecycle And Provider Vocabulary

| Option | Description | Selected |
|--------|-------------|----------|
| Provider-native enums | Expose APNs/FCM/Expo terms directly. Precise but leaks provider trivia into Crosswake contracts. | |
| Flat canonical state set | Use `:active`, `:rotated`, `:revoked`, `:stale`, `:invalid`, etc. Simple but mixes lifecycle and cause. | |
| Lifecycle state + reason split | Use small binding states plus lifecycle reasons to distinguish TOKN-02 cases. | ✓ |
| Status-only plus diagnostics | Keep binding simple and push detail into findings. Weak for lifecycle logic and audit. | |
| Provider feedback event taxonomy | Use separate provider feedback events for APNs/FCM facts. Useful evidence lane, not binding authority. | ✓ |

**User's choice:** Discuss all areas with sub-agent research and produce one coherent recommendation.
**Notes:** Locked states: `:active`, `:superseded`, `:revoked`, `:stale`, `:invalid`. Locked reasons include token rotation, logout/session revocation, permission denied, provider invalid/unregistered, environment mismatch, app identity mismatch, staleness prune, and manual revocation.

---

## Raw-Token Redaction And DX

| Option | Description | Selected |
|--------|-------------|----------|
| Raw token in public struct | Easiest to bind but too easy to inspect/log/fixture/telemetry leak. | |
| Opaque token ref only | Strong redaction but poor dedupe and invalidation matching. | Partial |
| Token fingerprint/digest | Supports dedupe/rotation/audit without raw token material. | ✓ |
| Host-secret boundary plus redaction helpers | Raw token stays host-owned; Crosswake defines safe evidence output and helper behavior. | ✓ |
| Safe audit event contract | Durable lifecycle truth with support-safe refs/states/reasons. | ✓ |
| Safe telemetry only | Useful instrumentation, but not durable audit or authority. | Partial |

**User's choice:** Discuss all areas with sub-agent research and produce one coherent recommendation.
**Notes:** Locked posture: public Chimeway structs should not have a normal raw `token` field. Use `token_ref`, `token_fingerprint`, safe audit fields, forbidden metadata lists, and Sigra-style telemetry sanitizers.

---

## the agent's Discretion

- Exact module and helper names.
- Exact required key list after preserving evidence/binding separation, backend authority, lifecycle coverage, and redaction.
- Exact HMAC/fingerprint helper implementation and fixture digest strategy.
- Exact telemetry event names and guide wording.

## Deferred Ideas

- Example-host registry and worker recipes -> Phase 60.
- Notification-open resolver and RouteGate/Sigra integration -> Phase 61.
- Doctor/support/operator/docs/telemetry expansion -> Phase 62.
- APNs/FCM real delivery proof and provider/device promotion -> Phase 63 or later.
