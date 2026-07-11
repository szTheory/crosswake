# Requirements: Crosswake v19.0 Showcase Apps & Capability Map

**Defined:** 2026-07-09
**Core Value:** Replace host-owned generated shell code (`ActivationCoordinator`, `BridgeChannel`) with standalone SPM/Maven dependencies, enforcing strict delegate-based customization to eliminate the "eject trap" and boilerplate for adopters.

## v19.0 Requirements

Requirements for the current milestone. Each maps to exactly one roadmap phase.

### Arc

- [x] **ARC-01**: Maintainer can read the planning docs and see the durable multi-milestone thread: v19 showcase, v20 Native Controls Pack 1, then capture/device, commerce/paywall, operator dashboard, and offline-sync/native-storage follow-ons.
- [x] **ARC-02**: Maintainer can see SEED-002 reflected as strategic input for capability breadth without treating v19 as the broad native-controls implementation milestone.
- [x] **ARC-03**: Maintainer can see SEED-003 and SEED-004 classified as release-infrastructure carryovers rather than v19 headline scope.

### Showcase Foundation

- [x] **SHOW-01**: User can open a first-screen showcase hub from the example host and understand the three domain lanes without reading implementation docs first.
- [x] **SHOW-02**: User can reset or reseed deterministic showcase data so every demo lane starts from a believable, repeatable state.
- [x] **SHOW-03**: User can see explicit route-owner/support labels in the showcase so LiveView, offline island, native-pressure, and unsupported-gap surfaces are not blurred together.
- [x] **SHOW-04**: User can run the existing first-run path and discover the showcase as the product-shaped Crosswake entrypoint.

### Demo App Brand System

- [x] **BRAND-01**: User can recognize the root showcase as Crosswake-owned through Crosswake logo/lockup and parent-brand copy, without confusing Crosswake with demo app brands.
- [x] **BRAND-02**: User can distinguish AdminPilot, Fieldserv, and LearnLoop as three fictional, category-forward demo app brands with separate visual systems.
- [x] **BRAND-03**: Maintainer can read fixture briefs that require each lane to ship realistic org/person/record/activity/pressure data instead of blank/demo-only pages.
- [x] **BRAND-04**: Verification can prove root-hub brand rendering, brand distinctness, fixture-density contracts, mobile containment, focus, and support-label honesty.

### SaaS/Admin Lane

- [x] **SAAS-01**: User can click through a SaaS/admin domain with realistic accounts, teams, roles, settings, and operational records.
- [x] **SAAS-02**: User can see LiveView-first route ownership and auth-sensitive/admin posture represented clearly in the SaaS lane.
- [x] **SAAS-03**: User can inspect route policy, diagnostics, and support truth from the SaaS lane without leaving ambiguity about native ownership.
- [ ] **SAAS-04**: User can complete a representative admin workflow that demonstrates Crosswake's Phoenix-first value without requiring new native-control APIs.

### Field-Service Lane

- [ ] **FIELD-01**: User can click through a field-service domain with realistic jobs, assets, inspections, notes, media/evidence, and technician state.
- [ ] **FIELD-02**: User can see device-pressure flows such as scanning/capture intent, evidence upload, permissions, and native-control gaps represented honestly.
- [ ] **FIELD-03**: User can see offline/degraded posture in the field-service lane without implying local-first mutation unless a real journal/outbox path is present.
- [ ] **FIELD-04**: User can trace route ownership and support labels for field-service flows that should remain LiveView, become offline islands, or become future native screens.

### Learning/Training Lane

- [ ] **LEARN-01**: User can click through a subscription learning/training domain with realistic courses, lessons, packs, learners, progress, and subscription state.
- [ ] **LEARN-02**: User can see content-pack and offline-study behavior demonstrated with honest sync/reconciliation visibility.
- [ ] **LEARN-03**: User can see entitlement/paywall pressure represented as backend-owned or mocked state without claiming live storefront support.
- [ ] **LEARN-04**: User can complete a representative learning workflow that connects online LiveView, offline island, and support truth.

### Capability Map

- [ ] **CAPMAP-01**: User can read a capability map that classifies each relevant native capability as shipped, demoed, missing, deferred, or next-pack candidate.
- [ ] **CAPMAP-02**: User can see intended package ownership for each capability: core, first-party companion, native shell, example/docs-only, or deferred.
- [ ] **CAPMAP-03**: User can see proof posture for each capability, including merge-blocking, advisory, not-yet-proven, and unsupported states.
- [ ] **CAPMAP-04**: Maintainer can use the capability map to define v20 Native Controls Pack 1 without re-litigating the whole strategic arc.

### Proof and Collateral

- [ ] **PROOF-01**: CI or local verification can reset fixtures and prove deterministic showcase data does not duplicate or drift.
- [ ] **PROOF-02**: Browser route-tour coverage exercises the showcase hub and one happy path per domain lane.
- [ ] **PROOF-03**: Structural docs/support tests prevent unsupported native controls from being presented as shipped.
- [ ] **PROOF-04**: Showcase collateral and docs describe what Crosswake supports today, what is demo pressure, and what is planned for v20+.

## Future Requirements

Deferred to future milestones. Tracked but not in the current roadmap.

### Native Controls Pack 1

- **NCTRL-01**: User can invoke typed, allowlisted alert/confirm controls from eligible routes.
- **NCTRL-02**: User can invoke typed native menu/action-button affordances without generic plugin-bus semantics.
- **NCTRL-03**: User can invoke haptics, share sheet, toast/review prompt, permission status, and notification-token UX affordances through Crosswake-owned contracts where v19 evidence justifies them.
- **NCTRL-04**: User can see native-control support truth by platform, route mode, shell version, proof posture, and rebuild requirement.

### Capture and Device Controls

- **CAPDEV-01**: User can invoke scanner/QR/document-capture flows through explicit route ownership and typed contracts.
- **CAPDEV-02**: User can represent biometrics, location, NFC, and other policy-sensitive capabilities with fail-closed diagnostics and support truth.

### Commerce and Paywall

- **COMM-01**: User can model paywall presentation, purchase initiation, entitlement refresh, and subscription-state callbacks with Phoenix-owned authority.
- **COMM-02**: User can integrate future Accrue-style billing or entitlement packages through explicit companion seams rather than core billing abstraction.

### Operator and Offline Productization

- **DASH-01**: User can inspect Crosswake route, telemetry, audit, release, and support posture in a self-contained `crosswake_dashboard` package.
- **SYNCP-01**: User can generate or reuse offline-sync helpers for idempotent replay, journals, outboxes, and reconciliation without Crosswake claiming to be a universal sync engine.
- **NTV-01**: User can inspect native disk budgets for offline packs and storage-sensitive routes.

## Out of Scope

Explicitly excluded from v19.0. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Implementing the full native controls catalog | v19 is the showcase and capability-map milestone; v20 should implement Native Controls Pack 1 from v19 evidence. |
| Scanner/document scan/biometrics/location/NFC production APIs | These are capture/device-pack candidates after the first native-controls pack unless v19 evidence reprioritizes them. |
| Live storefront, RevenueCat, StoreKit, or Play Billing production support | v19 may show entitlement/paywall pressure, but production commerce belongs in a later Phoenix-owned commerce/paywall milestone. |
| `crosswake_dashboard` implementation | Operator dashboard remains DASH-01 and should follow once showcase and native-control priorities are clearer. |
| Generic sync engine or universal local-first framework | Offline behavior must stay route-local and honest; SYNCP-01 is future productization, not v19 scope. |
| Generic WebView plugin catalog | Capability work must remain route-owned, typed, versioned, low-frequency, support-matrix-backed, and fail-closed. |
| Native simulator/emulator proof as a required gate | Native device evidence remains advisory unless it becomes deterministic and supportable in CI. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| ARC-01 | Phase 147 | Complete |
| ARC-02 | Phase 147 | Complete |
| ARC-03 | Phase 147 | Complete |
| SHOW-01 | Phase 147 | Complete |
| SHOW-02 | Phase 147 | Complete |
| SHOW-03 | Phase 147 | Complete |
| SHOW-04 | Phase 147 | Complete |
| BRAND-01 | Phase 148 | Complete |
| BRAND-02 | Phase 148 | Complete |
| BRAND-03 | Phase 148 | Complete |
| BRAND-04 | Phase 148 | Complete |
| SAAS-01 | Phase 149 | Complete |
| SAAS-02 | Phase 149 | Complete |
| SAAS-03 | Phase 149 | Complete |
| SAAS-04 | Phase 149 | Pending |
| FIELD-01 | Phase 150 | Pending |
| FIELD-02 | Phase 150 | Pending |
| FIELD-03 | Phase 150 | Pending |
| FIELD-04 | Phase 150 | Pending |
| LEARN-01 | Phase 151 | Pending |
| LEARN-02 | Phase 151 | Pending |
| LEARN-03 | Phase 151 | Pending |
| LEARN-04 | Phase 151 | Pending |
| CAPMAP-01 | Phase 152 | Pending |
| CAPMAP-02 | Phase 152 | Pending |
| CAPMAP-03 | Phase 152 | Pending |
| CAPMAP-04 | Phase 152 | Pending |
| PROOF-01 | Phase 152 | Pending |
| PROOF-02 | Phase 152 | Pending |
| PROOF-03 | Phase 152 | Pending |
| PROOF-04 | Phase 152 | Pending |

**Coverage:**

- v19.0 requirements: 31 total
- Mapped to phases: 31
- Unmapped: 0

---
*Requirements defined: 2026-07-09*
*Last updated: 2026-07-09 after completing Phase 148 demo-app brand direction*
