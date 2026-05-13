# Requirements: Crosswake

**Defined:** 2026-05-12
**Core Value:** Make runtime boundaries explicit so Phoenix teams can ship credible mobile apps without hiding the tradeoffs between LiveView, offline, and native ownership.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Route Policy

- [ ] **ROUTE-01**: Phoenix developers can declare runtime ownership per route as LiveView, offline island, native screen, or adapter.
- [ ] **ROUTE-02**: Phoenix developers can declare per-route offline policy, including unavailable, cached read-only, and local-first modes.
- [ ] **ROUTE-03**: Phoenix developers can declare required capabilities, pack dependencies, sync resources, and security sensitivity per route.
- [ ] **ROUTE-04**: Crosswake rejects invalid or internally inconsistent route policy declarations at compile time with actionable error messages.

### Manifest And Compatibility

- [ ] **MANI-01**: Crosswake compiles declared route policy into a versioned runtime manifest consumable by Phoenix hosts and native shells.
- [ ] **MANI-02**: Crosswake validates manifest schema, compatibility versions, and support matrix rules before release artifacts are produced.
- [ ] **MANI-03**: Native shells refuse to activate routes when manifest, bridge, capability, or pack compatibility checks fail.
- [ ] **MANI-04**: Crosswake publishes an explicit support and compatibility matrix covering supported Phoenix, LiveView, iOS, and Android baselines.

### Native Shell

- [ ] **SHELL-01**: Crosswake provides an iOS shell that can boot from a Crosswake manifest, resolve route ownership, and host LiveView routes in a bounded WebKit container.
- [ ] **SHELL-02**: Crosswake provides an Android shell that can boot from a Crosswake manifest, resolve route ownership, and host LiveView routes in a bounded WebView container.
- [ ] **SHELL-03**: Crosswake supports deep-link and app-entry handoff so mobile routes open in the runtime declared by route policy.

### Bridge And Capabilities

- [ ] **BRDG-01**: Crosswake provides a typed, versioned, request/reply bridge for bounded native capability calls instead of ad hoc message passing.
- [ ] **BRDG-02**: Crosswake exposes a capability registry that allowlists capabilities by route and blocks unavailable or undeclared capability access.
- [ ] **BRDG-03**: Crosswake verifies active-route, origin, and compatibility constraints before any bridge call is executed.

### Offline And Sync

- [ ] **OFFL-01**: Crosswake can mark a LiveView-backed route as cached read-only with explicit staleness policy and cache restrictions.
- [ ] **OFFL-02**: Crosswake provides one production-grade offline island contract for a local-first workflow that can execute without LiveView round-trips.
- [ ] **OFFL-03**: Offline islands support local drafts or append-only journals/outboxes and expose explicit reconciliation hooks for server-authoritative sync.
- [ ] **OFFL-04**: Crosswake exposes route-class telemetry and diagnostics for offline replay, sync, and reconciliation failures.

### Packs And Native Escapes

- [ ] **PACK-01**: Crosswake supports versioned content pack or media pack declarations in route policy and manifest output.
- [ ] **PACK-02**: Crosswake provides a pack lifecycle contract covering install, availability checks, and invalidation for declared packs.
- [ ] **PACK-03**: Crosswake provides one documented native screen or adapter escape hatch for a device-heavy flow such as camera or media capture.
- [ ] **PACK-04**: Crosswake provides explicit media transfer seams for upload/download flows rather than treating them as generic WebView behavior.

### Developer Experience And Proof

- [ ] **DX-01**: Crosswake provides generators or installers for host Phoenix setup and native shell bootstrap with clear ownership boundaries.
- [ ] **DX-02**: Crosswake provides doctor or diagnostics tooling that detects setup, compatibility, capability, and route-policy problems.
- [ ] **DX-03**: Crosswake ships example-host proof lanes and deterministic CI that verify the public install path across Phoenix, iOS, and Android surfaces.
- [ ] **DX-04**: Crosswake documentation clearly states supported runtime modes, non-goals, prerequisites, and rough-edge truth for adopters.

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

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

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| ROUTE-01 | Phase 1 | Pending |
| ROUTE-02 | Phase 1 | Pending |
| ROUTE-03 | Phase 1 | Pending |
| ROUTE-04 | Phase 1 | Pending |
| MANI-01 | Phase 2 | Pending |
| MANI-02 | Phase 2 | Pending |
| MANI-03 | Phase 3 | Pending |
| MANI-04 | Phase 2 | Pending |
| SHELL-01 | Phase 3 | Pending |
| SHELL-02 | Phase 3 | Pending |
| SHELL-03 | Phase 3 | Pending |
| BRDG-01 | Phase 3 | Pending |
| BRDG-02 | Phase 3 | Pending |
| BRDG-03 | Phase 3 | Pending |
| OFFL-01 | Phase 4 | Pending |
| OFFL-02 | Phase 4 | Pending |
| OFFL-03 | Phase 4 | Pending |
| OFFL-04 | Phase 4 | Pending |
| PACK-01 | Phase 5 | Pending |
| PACK-02 | Phase 5 | Pending |
| PACK-03 | Phase 5 | Pending |
| PACK-04 | Phase 5 | Pending |
| DX-01 | Phase 1 | Pending |
| DX-02 | Phase 2 | Pending |
| DX-03 | Phase 5 | Pending |
| DX-04 | Phase 2 | Pending |

**Coverage:**
- v1 requirements: 26 total
- Mapped to phases: 26
- Unmapped: 0

---
*Requirements defined: 2026-05-12*
*Last updated: 2026-05-12 after roadmap creation*
