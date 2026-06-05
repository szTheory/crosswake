# Requirements: Crosswake — v4.1 Multi-SaaS Archetype Proof Lanes

**Defined:** 2026-06-04
**Core Value:** Prove the shipped capabilities (commerce, auth, notifications, offline, media) work coherently together in production-shaped E2E archetype lanes without introducing generic sync abstractions.

## v1 Requirements

### Subscription SaaS Archetype (SAAS)

- [x] **SAAS-01**: The system must prove an end-to-end subscription SaaS commerce corridor using mock storefront adapters that simulate StoreKit/Play Billing.
- [x] **SAAS-02**: Entitlement projections must rely strictly on backend promotion (via provider-backed purchase/restore), never mutating state purely from client-side device evidence.

### Notification Workflow Archetype (NOTF)

- [x] **NOTF-01**: The system must prove an end-to-end notification-driven workflow, verifying Chimeway push-token binding connects cleanly with Sigra session state.
- [x] **NOTF-02**: Notification re-entry and deep-linking must respect route policies, enforcing RouteGate auth checks and preventing unauthenticated route bypasses or silent dashboard fallbacks.

### Media/Evidence Workflow Archetype (MED)

- [x] **MED-01**: The system must prove an end-to-end media/evidence capture workflow, integrating Rindle reconciliation to recover from degraded network failures.
- [x] **MED-02**: Local capture signals (pack-heavy media uploads) must remain non-authoritative until backend verification completes.

### Auth-Sensitive Admin Workflow Archetype (ADM)

- [x] **ADM-01**: The system must prove an auth-sensitive admin workflow, successfully triggering and verifying Sigra step-up ceremonies (e.g. strict auth posturing).
- [x] **ADM-02**: The workflow must enforce that native shell session persistence does not implicitly grant administrative route access, requiring handoff tickets and audit trails.

### Offline/Draft Recovery Archetype (OFF)

- [x] **OFF-01**: The system must prove an offline/draft recovery workflow, enforcing explicit `:cached_read_only` and `:local_first` offline policies.
- [x] **OFF-02**: The workflow must stay honest about local-first limits, rejecting generic universal sync engine claims and verifying degraded caching behavior.

### Proof & Closeout (PROOF)

- [ ] **PROOF-01**: All v4.1 archetype proofs must run hermetically in CI without requiring manual device verification.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SAAS-01 | Phase 70 | Complete |
| SAAS-02 | Phase 70 | Complete |
| NOTF-01 | Phase 71 | Complete |
| NOTF-02 | Phase 71 | Complete |
| MED-01 | Phase 72 | Complete |
| MED-02 | Phase 72 | Complete |
| ADM-01 | Phase 73 | Complete |
| ADM-02 | Phase 73 | Complete |
| OFF-01 | Phase 74 | Complete |
| OFF-02 | Phase 74 | Complete |
| PROOF-01 | Phase 75 | Pending |

**Coverage:**
- v1 requirements: 11 total
- Mapped to phases: 11 ✓
- Unmapped: 0
