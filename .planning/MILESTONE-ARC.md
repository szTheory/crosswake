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
- **v5.0 Standalone Publishable Shell Packages** — shipped 2026-06-06. Extracted `ActivationCoordinator`/`BridgeChannel` into standalone SPM/Maven dependencies with a binary Core + hosted-glue strategy and reactive state APIs, solving the "eject trap".
- **v5.1 Adoption Evidence Demo App** — shipped 2026-06-09. Transitioned iOS/Android demo hosts onto the standalone deps with reactive flow/publisher architectures, `RouteDelegate` + capability handshake, and a bounded-bridge proof.
- **v6.0 Adoption Evidence Demo App (Flashcard Cohort)** — shipped 2026-06-09. Flashcard language-learning demo exercising `Crosswake.Offline` end-to-end: `Crosswake.Offline.ContentPack`, `Crosswake.Sync.EventLog` + `mix crosswake.gen.sync`, online LiveView + vanilla-JS offline island over IndexedDB, network-toggling Playwright E2E (closeout used a mocked E2E that hid a compile break — real-network run deferred; see RETROSPECTIVE).
- **v7.0 Threadline Audit Capstone** — shipped 2026-06-09 (Phases 91-98). Cross-boundary `thread_id` propagation (Plug/LiveView/bridge telemetry, zero new deps), opt-in host-owned PII-free append-only Ecto audit ledger (`mix crosswake.gen.audit`), text-only operator surface (`mix crosswake.threadline`), and docs-contract parity. LiveDashboard timeline deferred to a future `crosswake_dashboard` package.
- **v8.0 Offline Sync Hardening and UI Polish** — shipped 2026-06-11 (Phases 99-101). Real network-toggling E2E, advisory runtime storage budgets via `navigator.storage.estimate()`, consolidated brand-aligned `OfflineController` UI.
- **v9.0 Brand System & Visual Identity** — shipped 2026-06-13 (Phases 102-106). Brand audit + WCAG matrix, frozen DTCG design tokens, path-only logo suite, standalone HTML brand book + `BRAND-SPEC.md`, collateral wired into README/ExDoc (brandbook hex-excluded), and shift-left brand UAT into a Playwright CI suite (`brand-structural` required / `brand-visual` advisory).
- **v10.0 Brand Normalization** — shipped 2026-06-14 (Phases 107-109). Made `tokens.css` the single generated source of truth (font + dimension + color) with a packaged mirror and one documented distribution path; rewired the example host + `offline_ui` generator onto semantic `--cw-*` tokens; browser-free `brand-structural` drift gate fails the build on reintroduced brand hex / dropped token refs.

## Strategic Queue

### Shipped: Adoption Evidence Demo App (v5.1 → v6.0)

**Status:** SHIPPED — v5.1 (2026-06-09) transitioned demo hosts onto standalone deps; v6.0 (2026-06-09) shipped the Flashcard offline cohort. The demo-app wedge is closed.

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

### Shipped: Threadline Audit Capstone (v7.0)

**Status:** SHIPPED — 2026-06-09 (Phases 91-98). Cross-boundary `thread_id` propagation (Plug/telemetry, zero new deps), opt-in host-owned PII-free append-only audit ledger with ProvenanceLane (`mix crosswake.gen.audit`), and a text-only operator surface (`mix crosswake.threadline`). LiveDashboard timeline deferred to a future `crosswake_dashboard` package. Canonical definition in `.planning/threads/threadline-audit.md`.

### Active: Release & Distribution Truth

**Status:** ACTIVE v11.0 milestone (2026-06-14). Full scope, research, and verified evidence in `.planning/threads/release-distribution-truth.md`.

**Objective**
- Make the v5.0 standalone-package thesis actually consumable: publish the iOS SPM core (subtree-mirror to its own repo, Apollo pattern) and the Android core to Maven Central (Vanniktech + Central Portal), lockstep-version them with the Hex package (release-please manifest `linked-versions`), rewire `mix crosswake.gen.shell` to inject the published version into generated dep coordinates, and cut Hex `0.1.2`.

**Why now**
- Crosswake is a mature codebase (~88% for scope) but a partial installable product (~70%). Hex publishes only `0.1.0`; ~4 months of shipped work (v3.4→v10.0) is uninstallable, and the headline "no eject trap" promise is vaporware in the default `gen.shell` path — generated projects reference deps that don't exist, so an external adopter can't build. This is the keystone that unblocks every downstream wedge and repairs thesis credibility. Build nothing new until an outsider can `mix deps.get` + `gen.shell` + build.

**Depends on**
- The shipped, hardened native cores (v5.0) and the release-please/`hex-publish` automation already wired for the Elixir package.

**Risk tags**
- `distribution`
- `release-truth`
- `adoption`

**Key outputs**
- iOS core auto-mirrored to `github.com/szTheory/crosswake-shell-core-ios` with semver tags; Android core on Maven Central under verified `io.github.sztheory`.
- `gen.shell` templates referencing published, version-matched deps (no monorepo paths); version injected from `Application.spec(:crosswake)[:vsn]`.
- A clean-room CI lane that scaffolds a host **outside the monorepo** and proves `swift build` / `gradle build` resolve published deps and compile.
- Graduation candidate: a permanent `doctor`/closeout "published-dep parity" check.

### Shipped: Standalone Publishable Shell Packages (v5.0)

**Status:** SHIPPED — v5.0 (2026-06-06) extracted the shell into standalone SPM/Maven dependencies and solved the "eject trap".

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
- **2026-06-09:** v5.0 (standalone packages), v5.1 + v6.0 (adoption-evidence demo apps) all shipped. With those wedges closed, the Threadline Audit Capstone (v7.0) becomes the active strategic milestone — the day-2 operational viability layer the arc always positioned last because it consumes the now-stable commerce, auth, notification, media, and offline surfaces. Scope locked narrow and honest: bespoke `thread_id` correlation (no OTel dep), opt-in PII-free append-only ledger with ProvenanceLane, text-only operator surface; LiveDashboard UI deferred to a separate `crosswake_dashboard` package.
- **2026-06-14:** Milestone next-step assessment after v10.0 (this doc was stale — still marked v7.0 "Active"; reconciled here with v7.0→v10.0 shipped). Verdict: Crosswake is feature-mature for its scope but distribution-incomplete. The single highest-leverage next wedge is **Release & Distribution Truth** — the v5.0 standalone-package thesis is built but undistributed (Hex stuck at `0.1.0`; `gen.shell` default emits nonexistent deps; native cores unpublished, no publish CI), so the "no eject trap" claim only holds inside the monorepo. Recommendation: ship what's built (publish native packages, lockstep versioning, rewire `gen.shell`, clean-room build proof) before any new feature/companion/capability breadth, which would be overbuilding on an undistributed base. Ordering after: CI-honesty/real-E2E sweep, then onboarding/docs once the install path is real. Detail in `.planning/threads/release-distribution-truth.md`.

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
- Whether the deferred Threadline operator timeline should live in a separate `crosswake_dashboard` package (LiveDashboard plugin) and when the opt-in audit ledger has enough adoption to justify the visual surface.

---
*Last updated: 2026-06-14 — v11.0 Release & Distribution Truth marked active with strategic contract heading restored.*
