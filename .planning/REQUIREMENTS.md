# Requirements: Crosswake

**Defined:** 2026-06-02
**Milestone:** v3.9 Chimeway Notification Seam
**Core Value:** Make runtime boundaries explicit so Phoenix teams can ship credible mobile apps without hiding the tradeoffs between LiveView, offline, and native ownership.

## v3.9 Requirements

Requirements for the current milestone. Each requirement maps to exactly one roadmap phase.

### Token Binding

- [x] **TOKN-01**: A Phoenix host can register APNs/FCM token evidence from the existing bounded bridge into a backend-owned Chimeway token binding record.
- [x] **TOKN-02**: Token binding distinguishes active, rotated, revoked, stale, invalid, permission-denied, environment-mismatched, and app-identity-mismatched states.
- [x] **TOKN-03**: Token rotation, logout/session revocation, permission loss, provider invalidation, and staleness pruning revoke or supersede bindings without deleting safe audit truth.

### Notification Opens

- [x] **OPEN-01**: Notification-open evidence resolves only through manifest-known route ids and route policy with `activation_source: :notification`.
- [ ] **OPEN-02**: Notification opens for auth-sensitive routes reuse Sigra session authority and step-up semantics before allowing route activation.
- [x] **OPEN-03**: Expired, replayed, revoked, route-mismatched, binding-mismatched, unsupported-action, and policy-denied opens fail closed with stable notification denial codes.

### Diagnostics

- [ ] **DIAG-01**: Doctor, operator inspection, support matrix, and guides distinguish token binding/open-routing readiness from APNs/FCM delivery support.
- [ ] **DIAG-02**: Notification telemetry uses stable low-cardinality events and forbids raw tokens, raw payloads, PII, route params, and provider payload bodies.

### Proof

- [ ] **PROOF-01**: Merge-blocking hermetic proof covers token contracts, binding/revocation lifecycle, open resolution, Sigra route gating, denial sanitization, support/docs parity, and telemetry redaction.
- [ ] **PROOF-02**: APNs/FCM device delivery, real token issuance, provider credentials, notification-tray behavior, and provider console metrics remain advisory with explicit promotion criteria.

## Future Requirements

Deferred to later milestones. Tracked but not in the current roadmap.

### Delivery Providers

- **DLVR-01**: Crosswake can promote real APNs delivery proof after repeatable iOS device or simulator evidence meets explicit criteria.
- **DLVR-02**: Crosswake can promote real FCM delivery proof after repeatable Android device or simulator evidence meets explicit criteria.
- **DLVR-03**: Crosswake can define provider-specific Chimeway push adapter examples after token/open contracts prove stable.

### Notification Actions

- **ACTN-01**: Crosswake can support richer notification action declarations after route-open resolution proves stable and does not become a generic plugin bus.
- **ACTN-02**: Crosswake can support background action workflows only after backend authorization, replay, audit, and platform proof are scoped in a later milestone.

## Out of Scope

Explicitly excluded for v3.9. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| First-party push delivery platform | v3.9 ships token binding and open-routing readiness, not APNs/FCM delivery guarantees. |
| Merge-blocking APNs/FCM device delivery proof | Provider/device behavior stays advisory until explicit promotion criteria pass. |
| Raw token logging or telemetry | Push tokens are sensitive provider credentials and must not leak through diagnostics or fixtures. |
| Notification opens as route authority | Notification payloads carry evidence refs; RouteGate and backend auth decide activation. |
| Silent fallback to dashboard/home | Fallbacks hide route-policy failures and weaken support truth. |
| Generic notification action registry | Broad action registries risk plugin-bus semantics and route-policy bypass. |
| Mutating background notification actions | v3.9 opens routes; Phoenix-owned server logic remains responsible for mutations and authorization. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| TOKN-01 | Phase 59 | Complete |
| TOKN-02 | Phase 59 | Complete |
| TOKN-03 | Phase 60 | Complete |
| OPEN-01 | Phase 61 | Complete |
| OPEN-02 | Phase 61 | Pending |
| OPEN-03 | Phase 61 | Complete |
| DIAG-01 | Phase 62 | Pending |
| DIAG-02 | Phase 62 | Pending |
| PROOF-01 | Phase 63 | Pending |
| PROOF-02 | Phase 63 | Pending |

**Coverage:**
- v3.9 requirements: 10 total
- Mapped to phases: 10
- Unmapped: 0

---
*Requirements defined: 2026-06-02 from v3.9 research synthesis.*
*Last updated: 2026-06-02 after milestone initialization.*
