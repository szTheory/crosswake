# Requirements: Crosswake v3.7 Commerce Provider Adapters

**Defined:** 2026-06-01
**Core Value:** Make runtime boundaries explicit so Phoenix teams can ship credible mobile apps without hiding the tradeoffs between LiveView, offline, and native ownership.

## v3.6 Requirements

### Strategic Memory

- [x] **STRAT-01**: Maintainers can read one current strategic arc that marks shipped milestones accurately and lists the next 4-6 milestone bets with dependencies and why-now rationale.
- [x] **STRAT-02**: Maintainers have a milestone closeout checklist that preserves durable lessons, thread/seed status, roadmap parity, requirements state, validation ledgers, and release continuity before context clears.

### Operator Inspection

- [x] **OPER-01**: Maintainers can inspect route ownership, runtime mode, capability declarations, commerce corridors, companion bindings, auth predicates, and rebuild requirements from a single operator-facing output.
- [x] **OPER-02**: CI or support tooling can consume machine-readable inspection output without scraping prose docs.

### Doctor Readiness

- [x] **DIAG-01**: `mix crosswake.doctor --check-publish` reports actionable release/support readiness across Hex metadata, changelog status, docs/support parity, proof posture, and known verification-required surfaces.
- [x] **DIAG-02**: Doctor output identifies companion dependency health, provider-adapter readiness, notification-token readiness, auth/session predicate readiness, and native shell verification gaps with explicit severity and remediation.

### Support Truth

- [x] **SUPP-01**: Support matrix truth distinguishes supported, verification-required, advisory, merge-blocking, rebuild-required, and unsupported states across routes, capabilities, companions, commerce, auth, notifications, and shell artifacts.
- [x] **SUPP-02**: Public guidance explains native rebuild requirements, advisory-to-merge-blocking promotion criteria, and rough edges without implying StoreKit, Play Billing, full Sigra machinery, Chimeway delivery, or standalone shell packages have shipped.

### Proof and Release Continuity

- [x] **PROOF-01**: Hermetic tests lock inspection output, doctor findings, and support matrix rows for the v3.6 operator surface.
- [x] **PROOF-02**: Docs-contract tests keep operator guidance synchronized with live doctor/support/denial/rebuild truth.
- [x] **REL-01**: Release/changelog guidance reflects all public support claims shipped after `0.1.0` and makes unreleased versus published Hex truth clear.

## v3.7 Requirements

### Commerce Provider Adapters

- [x] **ADPT-01**: Host apps can use a StoreKit adapter seam that emits provider evidence into Crosswake's backend-owned reconciliation contracts.
- [ ] **ADPT-02**: Host apps can use a Play Billing adapter seam that emits provider evidence into Crosswake's backend-owned reconciliation contracts.
- [x] **ADPT-03**: Maintainers can promote storefront/provider proof from advisory to merge-blocking only when explicit environment and repeatability criteria are met.

## Future Requirements

### Auth and Notifications

- **SIGRA-01**: Host apps can use Sigra-backed session handoff, step-up ceremony, and auth freshness flows without leaking authority into the client.
- **CHIME-01**: Host apps can bind push-token evidence to backend state and resolve notification opens through route policy and auth checks.

### Production Shells and Archetypes

- **SHELL-01**: Maintainers can publish a production native runtime line with compatibility windows, rebuild rules, permission templates, and device-UAT expectations.
- **ARCH-01**: Maintainers can verify Crosswake against multi-SaaS production archetype lanes that combine commerce, auth, notifications, media, offline, and shell support truth.

## Out of Scope

| Feature | Reason |
|---------|--------|
| StoreKit or Play Billing adapter implementation | Deferred to v3.7 so v3.6 can sharpen support truth before widening provider claims. |
| RevenueCat adapter | StoreKit and Play Billing should establish first-party provider-adapter shape first. |
| Full Sigra handoff/passkey/OAuth/refresh-token machinery | Deferred to v3.8 because account-security flows need dedicated security planning. |
| Chimeway delivery integration | Deferred to v3.9; v3.6 may report notification-token readiness but should not claim delivery support. |
| Standalone public shell packages | Deferred until the native runtime-line milestone establishes release choreography and compatibility policy. |
| Generic sync engine or broad local-first framework | Crosswake should preserve narrow offline contracts and explicit reconciliation instead of claiming universal sync. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| STRAT-01 | Phase 48 | Complete |
| STRAT-02 | Phase 48 | Complete |
| OPER-01 | Phase 49 | Complete |
| OPER-02 | Phase 49 | Complete |
| DIAG-01 | Phase 50 | Complete |
| DIAG-02 | Phase 50 | Complete |
| SUPP-01 | Phase 51 | Complete |
| SUPP-02 | Phase 51 | Complete |
| PROOF-01 | Phase 52 | Complete |
| PROOF-02 | Phase 52 | Complete |
| REL-01 | Phase 53 | Complete |
| ADPT-01 | Phase 48 | Complete |
| ADPT-02 | Phase 48 | Pending |
| ADPT-03 | Phase 48 | Complete |

**Coverage:**
- v3.7 requirements: 3 total
- Mapped to phases: 3
- Unmapped: 0

---
*Requirements reset: 2026-06-01 after v3.6 closeout*
