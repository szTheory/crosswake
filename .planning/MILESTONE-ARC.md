# Crosswake Milestone Arc

## Arc Thesis

Crosswake has moved from proving the Phoenix-first route-policy substrate to making that substrate credible for production mobile SaaS apps. The next arc should reduce bespoke native, commerce, auth, notification, and operator work without turning Crosswake into a universal UI framework, generic WebView wrapper, or plugin bus.

The planning bias remains **contracts first, proof always**. New breadth should land only when route ownership, typed contracts, support truth, proof lanes, and rough-edge docs land with it.

Strategic planning artifacts follow the same Phoenix/Plug contract posture as runtime seams: required fields are explicit, composable across artifacts, boringly named, and fail closed when required evidence is absent. A missing closeout artifact or vague exception is not treated as success.

## Locked Guardrails

- Per-route runtime ownership remains authoritative.
- Bridge contracts stay semantic, typed, versioned, and low-frequency.
- Capability access stays allowlisted, active-route checked, and fail-closed by default.
- Native screens remain explicit escape hatches rather than silent fallback behavior.
- Offline claims remain narrow and typed; cached read-only behavior is not local-first mutation.
- Entitlement truth remains backend- and Phoenix-owned; device purchase events are reconciliation evidence, not authority.
- Companion integrations remain explicit seams; Crosswake does not become a generic plugin bus.
- Diagnostics, support matrices, proof lanes, release truth, and rough-edge docs are product surface, not cleanup work.

## Durable Lessons

- **Install truth is product truth.** Public value is limited until the Hex package, HexDocs, changelog, and release automation reflect the shipped surface.
- **Mock the provider boundary before shipping provider SDK code.** v3.4 proved a paywall corridor by mocking only the storefront edge while keeping the real reconciliation/projection path.
- **Backend authority must be explicit.** Commerce, Rindle media, and Sigra auth all treat device/client signals as evidence until backend contracts promote them.
- **Hermetic and advisory proof lanes must stay separate.** Merge-blocking proof should be deterministic; device, storefront, simulator, and provider checks stay advisory until promotion criteria are explicit and repeatable.
- **Docs-contract parity is a product guarantee.** Guides that describe doctor/support/denial truth must be mechanically checked against live code.
- **Artifact parity is completion truth.** Verification reports, roadmap status, thread closure, validation ledgers, and archived requirements must be current before a milestone is considered closed.

## Capability Taxonomy

### Core

- Route policy, manifest, compatibility, and support truth
- Capability registry metadata and versioning
- Bounded bridge envelope and command vocabulary rules
- Native screen declaration and activation contract
- Shell diagnostics, doctor checks, proof-lane expectations, and release/support inspection

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
- Mocked adopter lanes that prove the real Crosswake contract path without claiming provider support

### Defer

- Broad real-time media or call SDK integration
- Generic high-frequency bridge surfaces
- Desktop packaging as a near-term arc driver
- Generic sync engine or universal local-first framework claims

## Shipped Milestones

- **v1.0 Route-Policy Substrate** — shipped 2026-05-17. Established route policy, manifest truth, bounded bridge, offline contracts, packs/transfers, checked-in proof lanes, and public guides.
- **v2.0 Adopter Stress Profiles** — shipped 2026-05-19. Validated the substrate against Phoenix SaaS, selective-native, and local-first study/content lanes.
- **v3.0 Capability Contract And Packaging** — shipped 2026-05-20. Froze capability taxonomy, package boundary policy, commerce seam vocabulary, and proof/support rules.
- **v3.1 Native Capabilities and Bridge Expansion** — shipped 2026-05-27. Added low-frequency bounded bridge families: `haptics`, `share`, `app_info`, `deep_link`, `permissions.status`, `notification_token`, and `file_picker`.
- **v3.2 Commerce And Entitlement Seams** — shipped 2026-05-27. Added provider-neutral commerce corridors, entitlement lifecycle contracts, reconciliation example, doctor/support truth, reviewer guidance, and hermetic/advisory proof split.
- **v3.3 Release Readiness** — shipped 2026-05-29. Published `crosswake 0.1.0` to Hex with release-please, package metadata, changelog, and HexDocs path.
- **v3.4 Commerce Archetype Proof** — shipped 2026-05-29. Proved a copy-able mocked paywall corridor through purchase, reconciliation, entitlement projection, UI state, hermetic proof, and docs-contract lock.
- **v3.5 First-Party Companions** — shipped 2026-05-31. Locked `Crosswake.Companion`, Rulestead gating, Rindle media evidence, Sigra contract-only auth predicates, and canonical companion docs/proof parity.
- **v3.6 Operator Truth and Production Diagnostics** — shipped 2026-06-01. Added route/capability/companion/provider/auth/notification readiness inspection, publish-readiness diagnostics, native rebuild/support truth, docs-contract proof, closeout verification, and release/changelog parity without promoting deferred provider/native claims.
- **v3.7 Commerce Provider Adapters** — shipped 2026-06-01. Added first-party StoreKit and Play Billing evidence adapter seams, example-host provider facade swap targets, backend-owned reconciliation proof, and advisory provider-proof promotion criteria.
- **v3.8 Full Sigra Auth and Session Machinery** — shipped 2026-06-02. Added backend-owned session authority, one-time handoff tickets, server-owned step-up ceremony, OAuth/passkey/native auth-return boundaries, sanitized auth telemetry, support/operator truth, and security closeout while keeping provider/device auth proof advisory.
- **v3.9 Chimeway Notification Seam** — shipped 2026-06-03. Added notification seam for token lifecycle, backend token binding, notification-open routing, revocation, and provider diagnostics.
- **v4.0 Production Shell Runtime Line** — shipped 2026-06-04. Hardened generated iOS and Android shells into a documented production runtime line.
- **v4.1 Multi-SaaS Archetype Proof Lanes** — shipped 2026-06-05. Proved subscription commerce, notification re-entry, media/evidence, auth-sensitive admin, and offline/draft workflows via end-to-end hermetic lanes.

## Strategic Queue

### Active: Adoption Evidence Demo App (v5.1)

**Objective**
- Build a realistic demo app in a representative cohort domain (e.g., field service, health/fitness, or study) with rich seeds, fixtures, and a click-around UI. 
- Automate E2E shift-left CI/CD testing across install, onboarding, and happy-path JTBDs to prove the DX/UX and integration of the v1-v5 substrate.

**Why now**
- The library has a massive amount of core functionality (up to v5.0 standalone shells) but lacks a cohesive, product-shaped proof point. `examples/phoenix_host` is a test harness, not a showcase. We need adoption evidence before seeking real adopters.

**Depends on**
- v5.0 Standalone Publishable Shell Packages

**Risk tags**
- `adoption`
- `dx-ux`
- `e2e-testing`

### Next: Threadline Audit Capstone

**Objective**
- Add auditability and distributed state tracking around sensitive route/runtime decisions, commerce events, auth step-up, media evidence, notification-triggered actions, and backend authority promotion.

**Why now**
- Following v4.1's delivery of multi-SaaS E2E archetype proof lanes, Crosswake now manages distributed state across Elixir and mobile boundaries (e.g., commerce, auth, notifications). A unified Threadline is the foundational day-2 requirement to make this split-brain architecture operationally supportable in production without database bloat.

**Depends on**
- Stable commerce, auth, notification, media, shell, and sensitive route-decision surfaces (provided by v3.x and v4.1).

**Risk tags**
- `auditability`
- `observability`
- `distributed-state`

**Key outputs**
- Telemetry-backed `X-Crosswake-Thread-Id` correlation across Plug, Bridge, and Shell.
- Opt-in `mix crosswake.gen.audit` Ecto ledger for terminal critical events (e.g., receipt validations, auth handoffs).
- Unified logger metadata for Phoenix console tracing.

### Next: Standalone Publishable Shell Packages (v4.2 / v5.0)

**Objective**
- Replace host-owned generated shell code (`ActivationCoordinator`, `BridgeChannel`) with standalone SPM/Maven dependencies, enforcing strict delegate-based customization.

**Why now**
- The native seams established in v4.1 are now hard enough to be packaged. To prevent ecosystem fragmentation and the "eject trap", adopters must consume core shell logic as a versioned dependency.

## Dependency Graph

- `v3.6 Operator Truth` precedes broad provider/native claims because it sharpens support truth and proof classification.
- `v3.7 Commerce Provider Adapters` depends on v3.2/v3.4 commerce contracts and benefits from v3.6 diagnostics.
- `v3.8 Sigra Full Auth` depends on v3.5 Sigra contracts and should precede notification-open and audit-heavy flows.
- `v3.9 Chimeway` depends on auth route truth and benefits from v3.6 readiness diagnostics.
- `v4.0 Production Shell Runtime Line` consolidates native runtime truth before broad production archetype proof.
- `v4.1 Archetype Proof Lanes` validates shipped surfaces together.
- `Threadline Audit Capstone` follows the sensitive event surfaces it will audit.

## Decision Notes

- **2026-05-31:** After v3.5, v3.6 was locked as the operator-truth milestone before provider/native breadth. Provider adapters moved to v3.7 so support, rebuild, proof, and release truth are inspectable first.
- **2026-05-31:** Future queue planning uses `Depends on` and `Risk tags` as planning signals, not marketing labels. These fields make provider, authority, notification, shell-runtime, archetype-proof, and auditability risk visible before planning starts.
- **2026-05-31:** The active milestone closeout contract lives in `.planning/milestones/v3.6-CLOSEOUT.md`; milestone audits remain append-only evidence rather than the live checklist.
- **2026-06-01:** v3.6 closeout archived the roadmap and requirements snapshots in `.planning/milestones/`, promoted `mix closeout.verify` to deterministic closeout truth, and made v3.7 Commerce Provider Adapters the active strategic milestone.
- **2026-06-01:** v3.7 closeout archived provider-adapter roadmap, requirements, audit, and phase evidence; v3.8 Full Sigra Auth and Session Machinery is now the active strategic candidate.
- **2026-06-02:** Milestone-next-step assessment after v3.8 selected v3.9 Chimeway as the highest-leverage next wedge. The shipped reality already has notification-token and permission snapshots, support/operator truth, and Sigra route auth; the missing adopter job is backend token binding, revocation, and notification-open route resolution that still respects route policy and auth. Production shell runtime hardening stays next after Chimeway because it is important support truth but unlocks less new adopter value than notification re-entry.
- **2026-06-05:** Following the completion of v4.1, the strategic priority shifted to v5.0 "Standalone Publishable Shell Packages" to address the "eject trap" and lock down the native shell runtime interfaces via SPM and Maven before expanding broader day-2 operational features.

## Support Truth Requirements

Any milestone in this arc that widens Crosswake's public surface must define:

- capability support matrix updates by route mode, platform, shell version, and companion/provider readiness
- explicit denial and fallback behavior
- doctor coverage for missing permissions, unsupported capabilities, stale provider state, and compatibility mismatches
- whether a native rebuild is required
- whether each proof lane is merge-blocking or advisory
- promotion criteria for advisory provider/device proof
- rough-edge and reviewer/storefront guidance when policy-sensitive

## Milestone Closeout Checklist

Every milestone close must update or verify:

- `PROJECT.md` current state, active/validated requirements, and key decisions.
- `MILESTONE-ARC.md` strategic queue, dependencies, open research flags, and durable lessons.
- `ROADMAP.md` phase status parity.
- `REQUIREMENTS.md` archived or reset state.
- `STATE.md` milestone/frontmatter consistency.
- Threads/seeds: close shipped threads, create new threads for unresolved strategic signals.
- Verification reports: every completed phase has an explicit verification artifact or an intentional documented exception.
- Validation ledgers: Nyquist/validation state is final or explicitly deferred.
- Changelog/release continuity when public support claims changed.
- Active milestone closeout ledger: `.planning/milestones/<milestone>-CLOSEOUT.md` is current, with missing artifacts recorded only through explicit `deferred_with_reason` exceptions.

## Open Research Flags

- Exact package/versioning posture for future separate companion packages.
- Whether RevenueCat belongs as a future adapter after the first-party StoreKit and Play Billing seam hardens.
- Whether Chimeway should stay token/open-action seam-only for one milestone or include a first provider delivery lane; default to seam-only unless provider/device delivery proof can be kept advisory and clearly separated from backend binding/open-action readiness.
- Which scanning/capture flows belong in Rindle/native-screen lanes versus bounded bridge families.
- What minimum Android evidence is required to move shell support from "verification required" to fully verified.

---
*Last updated: 2026-06-02 — v3.8 closed and v3.9 Chimeway Notification Seam selected as the recommended next milestone.*
eway Notification Seam selected as the recommended next milestone.*
