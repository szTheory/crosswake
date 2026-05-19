# Requirements: Crosswake

**Defined:** 2026-05-19
**Core Value:** Make runtime boundaries explicit so Phoenix teams can ship credible mobile apps without hiding the tradeoffs between LiveView, offline, and native ownership.
**Milestone:** v3.0 Capability Contract And Packaging

## Milestone Gates

### Capability Selection Rubric

| Capability family | Route-owner expectation | Bridge frequency | Permission / policy sensitivity | Support-matrix impact | Proof required | Package classification |
|-------------------|-------------------------|------------------|---------------------------------|-----------------------|----------------|------------------------|
| `haptics`, `share`, `app_info`, `deep_link` | Bounded bridge on Phoenix-owned routes | Low-frequency semantic | Low to medium | Shell-version capability availability | Merge-blocking allowlist and denial tests | `core` candidate |
| `permissions.status`, `notification_token` | Bounded bridge with explicit prerequisite truth | Low-frequency semantic | Medium to high | Platform permission and entitlement posture | Merge-blocking doctor and support-matrix proof | `core` candidate |
| `paywall`, `purchase`, `restore`, `entitlement_snapshot` | Phoenix-owned route flow with explicit commerce seams; native screens where storefront or policy pressure requires | Low-frequency semantic plus explicit native-screen escape hatches | High | Storefront and provider behavior must stay explicit | Merge-blocking contract docs plus advisory provider/storefront guidance | `core` seam plus `companion` adapters |
| `media_capture`, `scanner`, `document_scan`, pack-heavy import/export | Native-screen first unless a narrower bounded seam is proven | Mixed; often too stateful for bridge ownership | High | Device, permission, and pack/rebuild posture | Merge-blocking activation and denial proof; advisory device-lane proof | `companion` or `defer` by default |
| `rollout`, `auth`, `audit`, notification delivery providers | Explicit Phoenix/backend seam, not route-local bridge authority | Low-frequency control plane | High | Operator and support posture | Advisory proof until package boundaries and release choreography mature | `companion` |

### Packaging Ledger

| Surface | Classification | Scope note |
|---------|----------------|------------|
| Capability taxonomy, manifest metadata, support-matrix expansion rules | `core` | Core owns vocabulary, validation rules, and compatibility truth. |
| Package classification ledger and multi-package release policy | `core` | Core owns the rules that companion packages must satisfy. |
| Phoenix-facing commerce contract and entitlement seam vocabulary | `core` | Core defines normalized semantics without embedding a billing provider. |
| Provider-specific billing adapters and paywall implementations | `companion` | Provider logic stays outside core once the seam is stable. |
| Vendor-specific walkthroughs, reviewer guidance, and test-account playbooks | `example/docs-only` | Helpful, but must not shape core APIs. |
| Generic high-frequency bridge families, broad real-time media, desktop packaging | `defer` | Outside the contract-first scope of `v3.0`. |

### Commerce Scope Guard

- Crosswake core normalizes Phoenix-facing vocabulary for paywall entry, purchase intent, restore intent, entitlement snapshot, and reconciliation hooks.
- StoreKit, Play Billing, and provider-specific state machines remain adapter- or provider-specific.
- Entitlement truth lives in Phoenix/backend systems; device-side purchase events are evidence, not source of truth.
- Reviewer/storefront-specific flows, policy-sensitive purchase UI, and native-only commerce surfaces must remain explicit about when a native screen is required.

### Proof Posture Gate

| Claim class | Merge-blocking proof | Advisory proof |
|-------------|----------------------|----------------|
| Capability taxonomy and route-owner rules | Manifest, validator, and guide tests proving each family resolves to bounded bridge, native screen, or defer | Example classifications for candidate families |
| Packaging ledger and release policy | Docs integrity and policy-validation checks | Multi-package release rehearsal notes |
| Commerce seam vocabulary | Contract tests and docs examples proving backend-truth posture | Provider/storefront integration sketches |
| Support matrix, doctor posture, rebuild rules | Doctor, support-matrix, and denial-behavior tests | Simulator/device or storefront notes where environment-sensitive |

### Support Truth Gate

| Surface | Denial / fallback behavior | Missing prerequisite behavior | Native rebuild required? | Rough-edge docs required |
|---------|----------------------------|-------------------------------|--------------------------|--------------------------|
| Bounded bridge capability family | Fail closed with explicit undeclared/unavailable reason | Doctor and support matrix must name the missing permission, shell version, or package | Sometimes; must be declared per family | Yes |
| Commerce seam | Fall back to Phoenix-owned denial or explicit native-screen requirement; never imply entitlement success | Explain missing storefront, adapter, or backend reconciliation prerequisite | Often; must be explicit before support claims | Yes |
| Companion package | Fail closed with package or compatibility guidance, not silent downgrade | Explain install, release, and compatibility requirements | Yes when companion binary or shell integration changes | Yes |

## Milestone v3.0 Requirements

### Capability Taxonomy And Contract Rubric (`core`)

- [ ] **CAPA-01**: Phoenix teams can classify candidate native affordances into bounded bridge, explicit native screen, or deferred categories using one published rubric.
- [ ] **CAPA-02**: Crosswake can express capability-family metadata, route-owner expectations, and support posture in manifest and support-matrix truth without widening runtime authority.
- [ ] **CAPA-03**: Adopters can read explicit rules for when a capability family belongs in `core`, requires a `companion`, or stays deferred.

### Packaging And Release Boundaries (`core` policy + `companion` boundary)

- [ ] **PKG-01**: Phoenix teams can see a published packaging ledger that classifies major Crosswake surfaces as `core`, `companion`, `example/docs-only`, or `defer`.
- [ ] **PKG-02**: Maintainers can follow one documented release and versioning policy for companion-ready future work without breaking manifest, shell, or support truth.
- [ ] **PKG-03**: Adopters can tell when a capability or companion change requires a native rebuild, compatibility bump, or docs-only update.

### Commerce And Entitlement Seams (`core` seam, provider-specific work deferred)

- [ ] **COMM-01**: Phoenix teams can model paywall entry, purchase intent, restore intent, entitlement snapshot, and reconciliation hooks through a Phoenix-facing Crosswake contract.
- [ ] **COMM-02**: Crosswake documents that entitlement truth remains backend-owned and that device purchase events are inputs to reconciliation rather than final authority.
- [ ] **COMM-03**: Adopters can tell which commerce behavior belongs in core contracts, which belongs in companion adapters, and which flows require explicit native screens or storefront guidance.

### Proof And Support Truth (`core`)

- [ ] **SUPP-01**: Crosswake extends doctor and support-matrix guidance so capability-family, package-boundary, and commerce-seam claims expose denial behavior and prerequisites explicitly.
- [ ] **SUPP-02**: Maintainers can distinguish merge-blocking proof from advisory environment-sensitive proof for new capability and commerce claims.
- [ ] **SUPP-03**: Public guides explain rough edges, rebuild expectations, and fallback behavior for capability, companion, and commerce surfaces before future breadth lands.

## Future Requirements

### Native Affordance Delivery

- **AFFD-01**: Crosswake ships the first low-frequency capability families such as `haptics`, `share`, `app_info`, `deep_link`, `permissions.status`, `notification_token`, or `file_picker` through the bounded contract defined in `v3.0`.
- **AFFD-02**: Crosswake proves route-local allowlist, denial, and prerequisite behavior for each officially supported capability family across iOS and Android.

### Integrations And Operations

- **COMP-01**: Crosswake ships first-party companion integrations for `sigra`, `rulestead`, `rindle`, `chimeway`, or `threadline` where the boundary is proven and stable.
- **COMP-02**: Crosswake provides a Phoenix-mounted diagnostics UI for manifest inspection, route truth, and operator debugging.
- **COMP-03**: Crosswake provides staged rollout and kill-switch integration seams for runtime-mode experiments and emergency route policy changes.
- **COMP-04**: Crosswake publishes separately versioned native shell artifacts when release choreography and compatibility policy are mature enough.

### Broader Commerce And Proof

- **COMMF-01**: Crosswake or its first-party companions provide storefront-aware paywall and billing adapters once the core commerce seam is validated.
- **ARCH-01**: Crosswake re-runs adopter-shaped proof lanes for subscription, notification-driven, and richer media workflows after new capability and commerce surfaces ship.

### Platform Expansion

- **PLAT-01**: Crosswake adds broader native adapter coverage beyond the initial proof flows.
- **PLAT-02**: Crosswake adds desktop packaging support that reuses the runtime contract without distorting the mobile-first core.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Shipping a broad capability catalog in `v3.0` | This milestone is for taxonomy, package-boundary, and support truth first |
| Store-specific billing implementation | Provider logic should follow the normalized Phoenix-facing seam, not precede it |
| Generic plugin-bus semantics for companions or native APIs | Conflicts with typed, route-local, fail-closed Crosswake boundaries |
| High-frequency bridge-driven state or rendering loops | Would erode the bounded bridge thesis and make support truth dishonest |
| Broad real-time media or call SDK integration | Too stateful and runtime-heavy for this contract-first milestone |
| Desktop-first packaging work | Remains deferred behind mobile-first companion and support truth maturity |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CAPA-01 | Phase 11 | Pending |
| CAPA-02 | Phase 11 | Pending |
| CAPA-03 | Phase 11 | Pending |
| PKG-01 | Phase 12 | Pending |
| PKG-02 | Phase 12 | Pending |
| PKG-03 | Phase 12 | Pending |
| COMM-01 | Phase 13 | Pending |
| COMM-02 | Phase 13 | Pending |
| COMM-03 | Phase 13 | Pending |
| SUPP-01 | Phase 14 | Pending |
| SUPP-02 | Phase 14 | Pending |
| SUPP-03 | Phase 14 | Pending |

**Coverage:**
- v3.0 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0

---
*Requirements defined: 2026-05-19*
*Last updated: 2026-05-19 after initializing milestone v3.0 Capability Contract And Packaging*
