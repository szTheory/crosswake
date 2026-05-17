# Requirements: Crosswake

**Defined:** 2026-05-12
**Core Value:** Make runtime boundaries explicit so Phoenix teams can ship credible mobile apps without hiding the tradeoffs between LiveView, offline, and native ownership.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Route Policy

- [x] **ROUTE-01**: Phoenix developers can declare runtime ownership per route as LiveView, offline island, native screen, or adapter.
- [x] **ROUTE-02**: Phoenix developers can declare per-route offline policy, including unavailable, cached read-only, and local-first modes.
- [x] **ROUTE-03**: Phoenix developers can declare required capabilities, pack dependencies, sync resources, and security sensitivity per route.
- [x] **ROUTE-04**: Crosswake rejects invalid or internally inconsistent route policy declarations at compile time with actionable error messages.

### Manifest And Compatibility

- [x] **MANI-01**: Crosswake compiles declared route policy into a versioned runtime manifest consumable by Phoenix hosts and native shells.
- [x] **MANI-02**: Crosswake validates manifest schema, compatibility versions, and support matrix rules before release artifacts are produced.
- [x] **MANI-03**: Native shells refuse to activate routes when manifest, bridge, capability, or pack compatibility checks fail.
- [x] **MANI-04**: Crosswake publishes an explicit support and compatibility matrix covering supported Phoenix, LiveView, iOS, and Android baselines.

### Native Shell

- [x] **SHELL-01**: Crosswake provides an iOS shell that can boot from a Crosswake manifest, resolve route ownership, and host LiveView routes in a bounded WebKit container.
- [x] **SHELL-02**: Crosswake provides an Android shell that can boot from a Crosswake manifest, resolve route ownership, and host LiveView routes in a bounded WebView container.
- [x] **SHELL-03**: Crosswake supports deep-link and app-entry handoff so mobile routes open in the runtime declared by route policy.

### Bridge And Capabilities

- [x] **BRDG-01**: Crosswake provides a typed, versioned, request/reply bridge for bounded native capability calls instead of ad hoc message passing.
- [x] **BRDG-02**: Crosswake exposes a capability registry that allowlists capabilities by route and blocks unavailable or undeclared capability access.
- [x] **BRDG-03**: Crosswake verifies active-route, origin, and compatibility constraints before any bridge call is executed.

### Offline And Sync

- [x] **OFFL-01**: Crosswake can mark a LiveView-backed route as cached read-only with explicit staleness policy and cache restrictions.
- [x] **OFFL-02**: Crosswake provides one production-grade offline island contract for a local-first workflow that can execute without LiveView round-trips.
- [x] **OFFL-03**: Offline islands support local drafts or append-only journals/outboxes and expose explicit reconciliation hooks for server-authoritative sync.
- [x] **OFFL-04**: Crosswake exposes route-class telemetry and diagnostics for offline replay, sync, and reconciliation failures.

### Packs And Native Escapes

- [x] **PACK-01**: Crosswake supports versioned content pack or media pack declarations in route policy and manifest output.
- [x] **PACK-02**: Crosswake provides a pack lifecycle contract covering install, availability checks, and invalidation for declared packs.
- [x] **PACK-03**: Crosswake provides one documented native screen or adapter escape hatch for a device-heavy flow such as camera or media capture.
- [x] **PACK-04**: Crosswake provides explicit media transfer seams for upload/download flows rather than treating them as generic WebView behavior.

### Developer Experience And Proof

- [x] **DX-01**: Crosswake provides generators or installers for host Phoenix setup and native shell bootstrap with clear ownership boundaries.
- [x] **DX-02**: Crosswake provides doctor or diagnostics tooling that detects setup, compatibility, capability, and route-policy problems.
- [x] **DX-03**: Crosswake ships example-host proof lanes and deterministic CI that verify the public install path across Phoenix, iOS, and Android surfaces.
- [x] **DX-04**: Crosswake documentation clearly states supported runtime modes, non-goals, prerequisites, and rough-edge truth for adopters.

## v2 Requirements

Current milestone requirements for the next release cycle. Each maps to roadmap phases 6-10.

### Adopter Profile Matrix

- [x] **PROF-01**: Phoenix teams can inspect a published adopter-profile matrix that maps the three target app shapes to Crosswake runtime modes, required seams, and explicit non-goals.
- [x] **PROF-02**: Phoenix teams can tell which Crosswake surfaces each profile is meant to pressure before they run the exemplars.

### Phoenix SaaS Portal Exemplar

- [x] **SAAS-01**: Phoenix teams can run a SaaS-portal exemplar route set that keeps the majority of authenticated product flows in LiveView while exercising at least one bounded native affordance without shell forking.
- [x] **SAAS-02**: Phoenix teams can verify from guides and proof lanes which server-centric mobile-shell boundaries are supported for the SaaS profile and which remain intentionally unsupported.

### Selective Native Flow Exemplar

- [ ] **NATIVE-01**: Phoenix teams can run a selective-native exemplar flow that moves one device-heavy or entitlement-adjacent route into explicit native ownership while surrounding routes remain Phoenix-owned.
- [ ] **NATIVE-02**: The selective-native exemplar uses declared pack, transfer, and capability seams rather than ad hoc container behavior.

### Local-First Content Flow Exemplar

- [ ] **LOCAL-01**: Phoenix teams can run a local-first exemplar flow that completes meaningful work offline using Crosswake's journal, outbox, and reconciliation contract.
- [ ] **LOCAL-02**: The local-first exemplar proves cached read-only degradation and explicit replay outcomes alongside the offline-island workflow.

### Hardening And Proof

- [ ] **HARD-01**: Phoenix teams can express the exemplar flows without app-local shell forks, undocumented bridge behavior, or generic plugin-bus patterns.
- [ ] **HARD-02**: Contributors can run deterministic proof lanes that validate each exemplar's declared support posture across docs, host code, and runtime hooks.
- [ ] **HARD-03**: Adopters can read guidance and diagnostics that explain which profile pressures are first-class, which are rough edges, and where future capability expansion begins.

## Future Requirements

Deferred beyond the current milestone.

### Integrations And Operations

- **COMP-01**: Crosswake ships first-party companion integrations for `sigra`, `rulestead`, `rindle`, `chimeway`, or `threadline` where the boundary is proven and stable.
- **COMP-02**: Crosswake provides a Phoenix-mounted diagnostics UI for manifest inspection, route truth, and operator debugging.
- **COMP-03**: Crosswake provides staged rollout and kill-switch integration seams for runtime-mode experiments and emergency route policy changes.
- **COMP-04**: Crosswake publishes separately versioned native shell artifacts when release choreography and compatibility policy are mature enough.

### Platform Expansion

- **PLAT-01**: Crosswake adds broader native adapter coverage beyond the initial proof flows.
- **PLAT-02**: Crosswake adds desktop packaging support that reuses the runtime contract without distorting the mobile-first core.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Universal shared UI abstraction | Conflicts with the explicit per-route runtime ownership thesis |
| LiveView-driven native widget rendering | Depends on unstable rendering internals and hides boundary truth |
| Generic WebView-wrapper positioning | Reduces Crosswake to an architecture the project explicitly rejects |
| High-frequency bridge-driven state/render loops | Would turn the bridge into an untestable message bus |
| Broad billing or identity-provider abstractions in core | Important for some adopters, but too vendor-heavy for v1 substrate scope |
| Desktop-first architecture work | Desktop is a later extension, not a first-release driver |
| Claims of seamless or magical offline support | Offline behavior must remain explicit about what is cached, local, or server-authoritative |
| Turn exemplar lanes into full starter apps or polished templates | This milestone is for architectural pressure and proof, not template-productization |
| Broad commerce abstraction or paywall infrastructure in this milestone | Capability and commerce expansion should follow validated exemplar pressure, not precede it |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| ROUTE-01 | Phase 1 | Complete |
| ROUTE-02 | Phase 1 | Complete |
| ROUTE-03 | Phase 1 | Complete |
| ROUTE-04 | Phase 1 | Complete |
| MANI-01 | Phase 2 | Complete |
| MANI-02 | Phase 2 | Complete |
| MANI-03 | Phase 3 | Complete |
| MANI-04 | Phase 2 | Complete |
| SHELL-01 | Phase 3 | Complete |
| SHELL-02 | Phase 3 | Complete |
| SHELL-03 | Phase 3 | Complete |
| BRDG-01 | Phase 3 | Complete |
| BRDG-02 | Phase 3 | Complete |
| BRDG-03 | Phase 3 | Complete |
| OFFL-01 | Phase 4 | Complete |
| OFFL-02 | Phase 4 | Complete |
| OFFL-03 | Phase 4 | Complete |
| OFFL-04 | Phase 4 | Complete |
| PACK-01 | Phase 5 | Complete |
| PACK-02 | Phase 5 | Complete |
| PACK-03 | Phase 5 | Complete |
| PACK-04 | Phase 5 | Complete |
| DX-01 | Phase 1 | Complete |
| DX-02 | Phase 2 | Complete |
| DX-03 | Phase 5 | Complete |
| DX-04 | Phase 2 | Complete |
| PROF-01 | Phase 6 | Complete |
| PROF-02 | Phase 6 | Complete |
| SAAS-01 | Phase 7 | Complete |
| SAAS-02 | Phase 7 | Complete |
| NATIVE-01 | Phase 8 | Planned |
| NATIVE-02 | Phase 8 | Planned |
| LOCAL-01 | Phase 9 | Planned |
| LOCAL-02 | Phase 9 | Planned |
| HARD-01 | Phase 10 | Planned |
| HARD-02 | Phase 10 | Planned |
| HARD-03 | Phase 10 | Planned |

**Coverage:**
- v1 requirements: 26 total
- v2.0 requirements: 11 total
- Mapped to phases: 37
- Unmapped: 0

---
*Requirements defined: 2026-05-12*
*Last updated: 2026-05-18 after Phase 7 completion*
