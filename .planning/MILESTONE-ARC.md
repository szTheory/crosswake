# Crosswake Milestone Arc

## Arc Thesis

After `v2.0 Adopter Stress Profiles`, Crosswake should shift from proving the substrate to reducing bespoke native and commerce work for Phoenix teams. The next arc is about widening official native capability and commerce support without collapsing the project into a universal app framework, generic plugin bus, or vague WebView wrapper.

The planning bias for this arc is **contracts first**. Crosswake should lock capability taxonomy, package boundaries, support truth, and commerce seams before widening feature breadth.

## Locked Guardrails

- Per-route runtime ownership remains authoritative.
- Bridge contracts stay semantic, typed, versioned, and low-frequency.
- Capability access stays allowlisted, active-route checked, and fail-closed by default.
- Native screens remain explicit escape hatches rather than silent fallback behavior.
- Offline claims remain narrow and typed; cached read-only behavior is not local-first mutation.
- Entitlement truth remains backend- and Phoenix-owned; device purchase events are not sufficient by themselves.
- Companion integrations remain explicit seams; Crosswake does not become a generic plugin bus.
- Diagnostics, proof lanes, support matrices, and rough-edge docs remain product surface, not cleanup work.

## Capability Taxonomy

### Core

- Route policy, manifest, compatibility, and support truth
- Capability registry metadata and versioning
- Bounded bridge envelope and command vocabulary rules
- Native screen declaration and activation contract
- Shell diagnostics, doctor checks, and proof-lane expectations

### Companion

- Commerce and entitlement adapters
- Push and notification delivery integrations
- Media capture, upload, and pack-heavy flows
- Auth and account-security integrations
- Rollout, remote-config, and kill-switch integrations
- Auditability and operator observability integrations

### Example/Docs-Only

- Vendor-specific billing walkthroughs that should not shape core APIs
- Identity-provider-specific examples
- Reviewer/test-account playbooks tied to one provider or storefront

### Defer

- Broad real-time media or call SDK integration
- Generic high-frequency bridge surfaces
- Desktop packaging as a near-term arc driver

## Milestone Sequence

### Active: v3.0 Capability Contract And Packaging

**Status:** active on 2026-05-19

**Objective**
- Freeze capability-family taxonomy, package boundary policy, manifest extensions, bridge command rules, and multi-package release constraints.

**Why now**
- `v2.0` proved the substrate under realistic app pressure. The next risk is scope drift: adding feature breadth before locking what belongs in core, companion packages, and support claims.

**Key outputs**
- Capability selection rubric
- Packaging ledger (`core`, `companion`, `example/docs-only`, `defer`)
- Manifest/support-matrix expansion rules
- Native rebuild and compatibility guidance
- Release/versioning policy for companion-ready future

**Non-goals**
- Shipping a broad capability catalog
- Store-specific billing implementation
- Reopening the route-policy thesis

**Proof required**
- Public docs for package boundary policy
- Doctor/support-matrix guidance for newly formalized capability metadata
- Example classification of first target capability families

### Candidate: v3.1 Native Affordance Families

**Status:** next candidate after `v3.0`

**Objective**
- Ship the first low-frequency, high-DX capability families that fit the existing bridge thesis.

**Recommended first families**
- `haptics`
- `share`
- `app_info`
- `deep_link`
- `permissions.status`
- `notification_token`
- `file_picker`

**Why now**
- These capabilities reduce bespoke native glue for adopters without forcing continuous native authority or deep store-policy complexity.

**Non-goals**
- Real-time sensor/control bridges
- Broad scanning/media workflows if they want native-screen ownership instead

**Proof required**
- Route-local allowlist tests
- Platform support matrix by shell version
- Doctor output for missing permissions/prerequisites

### Candidate: v3.2 Commerce And Entitlement Seams

**Status:** candidate

**Objective**
- Define Crosswake's Phoenix-facing commerce seam: paywall route mode, purchase intent, restore intent, entitlement snapshot, and reconciliation hooks.

**Why now**
- Subscription and companion-app adopters expect a coherent mobile commerce story, but Crosswake must avoid store-specific core sprawl.

**Non-goals**
- A universal billing engine in core
- Device-local entitlement truth
- Provider lock-in disguised as generic architecture

**Proof required**
- Explicit core-vs-companion boundary for commerce
- Support guidance for storefront, reviewer, and restore flows
- Backend reconciliation contract examples

### Candidate: v3.3 First-Party Companions

**Status:** candidate

**Objective**
- Add the highest-leverage optional integrations in an order that improves rollout safety before feature breadth.

**Recommended sequence**
1. `rulestead`
2. `sigra`
3. `rindle`
4. `chimeway`
5. `threadline`

**Why now**
- Capability breadth becomes materially safer and more useful once rollout controls, auth boundaries, media seams, notification flows, and auditability are available through explicit integrations.

**Non-goals**
- Silent hard dependencies
- Companion packages that bypass manifest or route-policy truth

**Proof required**
- Companion classification and dependency docs
- Example-host integration lanes for each shipped companion

### Candidate: v3.4 Operator Truth And Diagnostics Expansion

**Status:** candidate

**Objective**
- Harden support truth for the widened surface: route/capability inspection, richer doctor checks, support matrices, advisory device lanes, and release guidance.

**Why now**
- More capability and commerce breadth raises the support-cost ceiling unless the operator surface becomes sharper first.

**Non-goals**
- Polished UI for its own sake
- Broad admin surface unrelated to install/debugging/support truth

**Proof required**
- Capability inspection outputs
- Advisory vs merge-blocking CI lane split
- Native rebuild matrix and compatibility notes

### Candidate: v3.5 Archetype Proof Lanes

**Status:** candidate

**Objective**
- Re-run adopter-shaped pressure using the new surfaces: subscription/paywall, notification-driven companion workflows, and richer media or scanning lanes.

**Why now**
- Feature breadth should be validated under real product pressure before future expansion.

**Non-goals**
- Shipping starter apps as product templates
- Widening scope beyond the new surfaces being proven

**Proof required**
- Example-host lanes for each target archetype
- Updated public guidance and rough-edge documentation

## Dependency Graph

- `v3.0 Capability Contract And Packaging`
  must land before `v3.1`, `v3.2`, or `v3.3`.
- `v3.1 Native Affordance Families`
  should precede deeper media/scanning or heavy native-screen expansion.
- `v3.2 Commerce And Entitlement Seams`
  should precede commerce-focused companions or storefront-specific examples.
- `v3.3 First-Party Companions`
  depends on `v3.0`, and `rulestead` should precede wider risky feature rollout when possible.
- `v3.4 Operator Truth And Diagnostics Expansion`
  should track alongside widening support claims and complete before claiming broad readiness.
- `v3.5 Archetype Proof Lanes`
  should validate what the earlier milestones shipped rather than inventing a disconnected new surface.

## Support Truth Requirements

Any milestone in this arc that widens Crosswake's public surface must define:

- capability support matrix updates by route mode, platform, and shell version
- explicit denial and fallback behavior
- doctor coverage for missing permissions, unsupported capabilities, and compatibility mismatches
- whether a native rebuild is required
- whether the proof lane is merge-blocking or advisory
- rough-edge and reviewer/storefront guidance when policy-sensitive

## Open Research Flags

- Exact multi-package release/versioning posture if companion packages live in the same repo family
- Whether notifications should begin as a token/deep-link seam only or include first-party delivery integration immediately
- Which scanning or capture flows truly belong in bounded bridge families versus explicit native screens
- Whether `accrue` should be the first commerce companion anchor or remain an example/docs-only reference at first

---
*Last updated: 2026-05-19 after activating milestone v3.0 Capability Contract And Packaging*
