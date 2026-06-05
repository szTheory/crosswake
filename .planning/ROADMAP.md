# Roadmap: Crosswake — v4.1 Multi-SaaS Archetype Proof Lanes

## Phases

- [x] **Phase 70: Subscription SaaS Commerce Proof** - Validate commerce corridors and backend entitlement projections (completed 2026-06-04)
- [x] **Phase 71: Notification-Driven Workflow Proof** - Prove secure, route-policy aware deep-linking and notification re-entry (completed 2026-06-04)
- [ ] **Phase 72: Media/Evidence Workflow Proof** - Validate Rindle reconciliation and failure recovery for media uploads
- [ ] **Phase 73: Auth-Sensitive Admin Workflow Proof** - Stress-test Sigra step-up ceremonies and strict auth posturing
- [ ] **Phase 74: Offline/Draft Recovery Proof** - Prove degraded read-only caching and offline-island limits
- [ ] **Phase 75: Multi-SaaS Archetype Closeout Gate** - Verify all archetype proofs are CI-hermetic and requirements are met

## Phase Details

### Phase 70: Subscription SaaS Commerce Proof
**Goal**: Validate E2E commerce corridors and backend entitlement projections.
**Depends on**: Nothing
**Requirements**: SAAS-01, SAAS-02
**Success Criteria** (what must be TRUE):
  1. Developer can run a CI test that simulates a purchase using mock storefront adapters.
  2. The entitlement projection changes only after backend verification, ignoring client-side mocks of success.
  3. Restore flow correctly pulls state from the provider facade without trusting client evidence.
**Plans**: 3 plans — Wave 0 commerce proof, Wave 1 verifier/provider closure, Wave 2 CI/paywall polish
**UI hint**: yes

### Phase 71: Notification-Driven Workflow Proof
**Goal**: Prove secure, route-policy aware deep-linking and notification re-entry.
**Depends on**: Phase 70
**Requirements**: NOTF-01, NOTF-02
**Success Criteria** (what must be TRUE):
  1. A notification tap simulates a push-token opening a specific deep-linked route.
  2. RouteGate intercepts the intent, enforcing a `requires_recent_auth` Sigra check.
  3. The system correctly rejects unauthenticated attempts, proving no silent route bypasses.
**Plans**: 3 plans — Wave 0 red proof, Wave 1 resolver/auth closure, Wave 2 CI/support truth

### Phase 72: Media/Evidence Workflow Proof
**Goal**: Validate Rindle reconciliation and failure recovery for media uploads.
**Depends on**: Phase 71
**Requirements**: MED-01, MED-02
**Success Criteria** (what must be TRUE):
  1. A media pack capture event is recorded locally during simulated network degradation.
  2. The upload fails, is stored locally, and Rindle reconciles upon simulated network recovery.
  3. Backend authority correctly denies completion until the full payload is reconciled.
**Plans**: 3 plans — Wave 0 media recovery proof contract, Wave 1 Rindle/example-host closure, Wave 2 CI/support truth

### Phase 73: Auth-Sensitive Admin Workflow Proof
**Goal**: Stress-test Sigra step-up ceremonies and strict auth posturing.
**Depends on**: Phase 72
**Requirements**: ADM-01, ADM-02
**Success Criteria** (what must be TRUE):
  1. A user with a persistent native session attempts to access an admin route and is blocked.
  2. The system triggers a step-up ceremony, producing an audit-trailed handoff ticket.
  3. Only upon successful step-up is the admin route unlocked.
**Plans**: TBD
**UI hint**: yes

### Phase 74: Offline/Draft Recovery Proof
**Goal**: Prove degraded read-only caching and offline-island limits.
**Depends on**: Phase 73
**Requirements**: OFF-01, OFF-02
**Success Criteria** (what must be TRUE):
  1. An offline-island mutation is performed locally.
  2. The application enforces its `:local_first` bounds, showing cached read-only data for other routes.
  3. The system does not attempt universal sync, strictly respecting the declared offline policy.
**Plans**: TBD

### Phase 75: Multi-SaaS Archetype Closeout Gate
**Goal**: Verify all archetype proofs are CI-hermetic and requirements are met.
**Depends on**: Phase 74
**Requirements**: PROOF-01
**Success Criteria** (what must be TRUE):
  1. `mix closeout.verify` passes for v4.1.
  2. All archetype proofs execute deterministically in CI (iOS simulator / Android JVM).
  3. All v4.1 requirements are correctly mapped and closed.
**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 70. Subscription SaaS Commerce Proof | 3/3 | Complete    | 2026-06-04 |
| 71. Notification-Driven Workflow Proof | 3/3 | Complete    | 2026-06-04 |
| 72. Media/Evidence Workflow Proof | 0/3 | Planned | - |
| 73. Auth-Sensitive Admin Workflow Proof | 0/0 | Not started | - |
| 74. Offline/Draft Recovery Proof | 0/0 | Not started | - |
| 75. Multi-SaaS Archetype Closeout Gate | 0/0 | Not started | - |
