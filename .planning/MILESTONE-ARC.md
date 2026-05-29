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

## Release Readiness Baseline

Before any v3.3+ strategic-arc milestone ships, Crosswake must be installable from hex.pm with honest release metadata, CHANGELOG, and `source_url`. This baseline was missing from the original arc; flagged 2026-05-27 during `$gsd-new-milestone` assessment. See `.planning/threads/release-readiness.md`.

Concretely required:

- `mix.exs` `version` reflects honest contract maturity (not the placeholder `0.1.0`).
- `mix.exs` `source_url` points to the real GitHub repository (not `github.com/example/crosswake`).
- `CHANGELOG.md` exists at repo root and covers v1.0 → current.
- Release pipeline (release-please or equivalent) wired and green.
- Hex publish workflow exists and produces a publishable package.
- Package metadata (`:licenses`, `:links`, `:maintainers`, `:description`, `:files`) audited for hex-page rendering.

Rationale: a Phoenix OSS library that is not installable via `{:crosswake, "~> X"}` from hex.pm is invisible to its target community. szTheory house-style anchors ("install truth is product truth", "release truth matters" — see `prompts/crosswake-elixir-oss-dna.md:103-137`) make this baseline load-bearing rather than optional polish.

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

### Shipped: v3.0 Capability Contract And Packaging

**Status:** shipped on 2026-05-20

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

### Shipped: v3.1 Native Affordance Families

**Status:** shipped on 2026-05-27

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

**Outcome**
- Shipped the first low-frequency bounded capability families: `haptics`, `share`, `app_info`, `deep_link`, `permissions.status`, `notification_token`, and `file_picker`.
- Closed route-local enforcement, doctor/support posture, and support-matrix truth for the new families.
- Added a dedicated Phase 18 proof lane that passes Elixir proof slices, checked-in iOS shell proof, and Android JVM BridgeChannel proof.

### Active: v3.2 Commerce And Entitlement Seams

**Status:** active on 2026-05-27

**Objective**
- Operationalize Crosswake's Phoenix-facing commerce seam: route/corridor declarations, purchase intent, restore intent, entitlement snapshot lifecycle truth, reconciliation hooks, support posture, and proof guidance.

**Why now**
- `v3.0` defined the core commerce vocabulary and package boundary, and `v3.1` proved low-frequency capability delivery. Subscription and companion-app adopters now need the seam to become usable and provable without store-specific core sprawl.

**Key outputs**
- Commerce route/corridor declarations
- Normalized lifecycle semantics for purchase, restore, reconciliation, and entitlement snapshots
- Minimal Phoenix-owned reconciliation inbox and entitlement projection example
- Doctor/support-matrix/reviewer guidance for commerce prerequisites and fallbacks
- Merge-blocking contract proof plus advisory storefront/provider proof posture

**Non-goals**
- A universal billing engine in core
- Device-local entitlement truth
- Provider lock-in disguised as generic architecture
- StoreKit, Play Billing, or provider SDK implementation in core

**Proof required**
- Explicit core-vs-companion boundary for commerce
- Support guidance for storefront, reviewer, and restore flows
- Backend reconciliation contract examples
- Denial/fallback tests proving device evidence cannot directly grant entitlement authority

### Candidate: v3.3 Release Readiness

**Status:** candidate (recommended next; flagged 2026-05-27 during post-v3.2 assessment)

**Objective**
- Publish Crosswake to hex.pm with honest release metadata, CHANGELOG, and real `source_url`. Establish the release infrastructure (release-please, hex publish workflow) that every subsequent milestone will depend on.

**Why now**
- `v3.2` shipped the commerce seam and brings the substrate to ~82% done by adopter-coverage rubric. The lib's biggest remaining gap is not contract surface — it is *discoverability*. Without hex.pm presence the lib is invisible to the Phoenix community and no further milestone gains real-world adopter pressure.

**Key outputs**
- `mix.exs` version, `source_url`, package metadata audited for hex
- `CHANGELOG.md` covering v1.0 → v3.2 history
- Release-please (or equivalent) pipeline wired
- `.github/workflows/release.yml` for hex publish on tag
- hexdocs render verified
- `bootstrap-elixir-hex-lib` skill used as paved path

**Non-goals**
- New capability families
- Provider adapters
- Companion integrations
- API changes that would require a major version bump for purely cosmetic reasons

**Proof required**
- First hex release lands cleanly
- hexdocs.pm renders README + guides
- Tag → CI → hex publish chain green

### Candidate: v3.4 Commerce Archetype Proof (ARCH-02)

**Status:** candidate (sequenced after v3.3)

**Objective**
- Turn the v3.2 commerce vocabulary into a copy-able adopter lane. Wire a runnable `paywall_entry` + `purchase_intent` + `restore_intent` + `reconciliation_inbox` example in `examples/phoenix_host` using a mocked storefront corridor.

**Why now**
- v3.2 shipped contract vocabulary but no live paywall route exists in the example host. Adopters can read the contracts but cannot copy a working corridor. Mocking is sufficient to prove the lane end-to-end; real provider adapters wait for the dedicated provider milestone.

**Key outputs**
- `paywall_entry` route in example host
- `MockStorefront` adapter consuming v3.2 commerce contracts
- End-to-end merge-blocking proof: mock purchase → reconciliation evidence → entitlement snapshot → LiveView reflects state
- `guides/commerce.md` walkthrough updated and docs-contract-locked

**Non-goals**
- StoreKit or Play Billing implementation
- Provider-specific code in core

**Proof required**
- Merge-blocking hermetic lane drives the full corridor
- Reviewer playbook docs-contract test stays green

### Candidate: v3.5 First-Party Companions

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

### Candidate: v3.6 Operator Truth And Diagnostics Expansion

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

### Candidate: v3.7 Archetype Proof Lanes

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
  must land before `v3.1`, `v3.2`, or later capability work.
- `v3.1 Native Affordance Families`
  should precede deeper media/scanning or heavy native-screen expansion.
- `v3.2 Commerce And Entitlement Seams`
  should precede commerce-focused companions or storefront-specific examples.
- `v3.3 Release Readiness`
  is the baseline for adopter discoverability; should precede any milestone whose value depends on adopter pickup.
- `v3.4 Commerce Archetype Proof`
  depends on `v3.2` and benefits from being adopter-visible, so it sequences after `v3.3`.
- `v3.5 First-Party Companions`
  depends on `v3.0` and on `v3.3` for adopter discoverability; `rulestead` should precede wider risky feature rollout when possible.
- `v3.6 Operator Truth And Diagnostics Expansion`
  should track alongside widening support claims and complete before claiming broad readiness.
- `v3.7 Archetype Proof Lanes`
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
*Last updated: 2026-05-27 after v3.2 milestone completion + post-v3.2 next-step assessment (added Release Readiness Baseline, inserted v3.3 Release Readiness and v3.4 Commerce Archetype Proof as candidates, renumbered companion/operator/archetype milestones to v3.5/v3.6/v3.7)*
