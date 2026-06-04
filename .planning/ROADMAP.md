# Roadmap: Crosswake

## Milestones

- ✅ **v1.0 Route-Policy Substrate** — Phases 1-5 shipped on 2026-05-17.
- ✅ **v2.0 Adopter Stress Profiles** — Phases 6-10 shipped on 2026-05-19. Full archive: [v2.0-ROADMAP.md](milestones/v2.0-ROADMAP.md)
- ✅ **v3.0 Capability Contract And Packaging** — Phases 11-14 shipped on 2026-05-20. Full archive: [v3.0-ROADMAP.md](milestones/v3.0-ROADMAP.md)
- ✅ **v3.1 Native Capabilities and Bridge Expansion** — Phases 15-18 shipped on 2026-05-27. Full archive: [v3.1-ROADMAP.md](milestones/v3.1-ROADMAP.md)
- ✅ **v3.2 Commerce And Entitlement Seams** — Phases 19-25 shipped on 2026-05-27. Full archive: [v3.2-ROADMAP.md](milestones/v3.2-ROADMAP.md)
- ✅ **v3.3 Release Readiness** — Phases 26-32 shipped on 2026-05-29 (`crosswake 0.1.0` live on hex.pm). Full archive: [v3.3-ROADMAP.md](milestones/v3.3-ROADMAP.md)
- ✅ **v3.4 Commerce Archetype Proof** — Phases 33-37 shipped on 2026-05-29. Full archive: [v3.4-ROADMAP.md](milestones/v3.4-ROADMAP.md)
- ✅ **v3.5 First-Party Companions** — Phases 38-47 shipped on 2026-05-31. Full archive: [v3.5-ROADMAP.md](milestones/v3.5-ROADMAP.md)
- ✅ **v3.6 Operator Truth and Production Diagnostics** — Phases 48-53 shipped on 2026-06-01. Full archive: [v3.6-ROADMAP.md](milestones/v3.6-ROADMAP.md)
- ✅ **v3.7 Commerce Provider Adapters** — Phases 48 and 48.1 shipped on 2026-06-01. Full archive: [v3.7-ROADMAP.md](milestones/v3.7-ROADMAP.md)
- ✅ **v3.8 Full Sigra Auth and Session Machinery** — Phases 54-58 shipped on 2026-06-02. Full archive: [v3.8-ROADMAP.md](milestones/v3.8-ROADMAP.md)
- ✅ **v3.9 Chimeway Notification Seam** — Phases 59-63 shipped on 2026-06-03. Full archive: [v3.9-ROADMAP.md](milestones/v3.9-ROADMAP.md)
- 🚧 **v4.0 Production Shell Runtime Line** — Phases 64-69 (in progress).

## Overview

v4.0 hardens Crosswake's existing checked-in iOS/Android shells into a documented, proof-backed production runtime line. It is not new product surface — it is honest contracts, host-owned generated templates, a diagnostics export seam, and CI/verification closure layered onto surfaces that already exist (route policy, manifest/compatibility contract, bounded bridge, capability registry, `mix crosswake.doctor`, `SupportMatrix`, operator inspection, Sigra auth, Chimeway notification seam). The build order is contracts-and-support-truth first, then the diagnostics seam, then generator templates plus the Apple Xcode 26 CI fix, then native shell implementation with hermetic JVM proof, then Android verification closure and device-UAT, and finally the docs-contract parity gate plus Android support promotion and closeout. No new hex dependencies, no manifest schema bump (rebuild policy derives from the existing `native_runtime_version` axis), no bridge vocabulary expansion (diagnostics is a fire-and-forget HTTP seam). Hermetic proof is merge-blocking; emulator/device/provider proof stays advisory with explicit promotion criteria; Android stays `:verification_required` until the final gate and promotion criteria pass.

## Phases

<details>
<summary>✅ v3.3 Release Readiness (Phases 26-32) — SHIPPED 2026-05-29</summary>

- [x] Phase 26: Package Metadata Audit (4/4 plans) — completed 2026-05-28
- [x] Phase 27: Versioning Decision And CHANGELOG Synthesis (2/2 plans) — completed 2026-05-28
- [x] Phase 28: release-please Configuration Files (1/1 plan) — completed 2026-05-28
- [x] Phase 29: Release Workflows And Supply-Chain Hardening (1/1 plan) — completed 2026-05-28
- [x] Phase 30: Hex Page Polish And Tarball Dry-Run (2/2 plans) — completed 2026-05-29
- [x] Phase 31: First Hex Publish (Human-Gated) — completed 2026-05-29 (`crosswake 0.1.0` live)
- [x] Phase 32: Post-Publish Cleanup — completed 2026-05-29

Full phase details: [v3.3-ROADMAP.md](milestones/v3.3-ROADMAP.md)

</details>

<details>
<summary>✅ v3.4 Commerce Archetype Proof (Phases 33-37) — SHIPPED 2026-05-29</summary>

- [x] Phase 33: Corridor Routes And CI Infrastructure (2/2 plans) — completed 2026-05-29
- [x] Phase 34: MockStorefront And Idempotency Invariants (2/2 plans) — completed 2026-05-29
- [x] Phase 35: Reconciliation Wiring And Four-State LiveView (2/2 plans) — completed 2026-05-29
- [x] Phase 36: Hermetic Proof Lane (1/1 plan) — completed 2026-05-29
- [x] Phase 37: Guides Walkthrough And Docs-Contract Lock (1/1 plan) — completed 2026-05-29

Full phase details: [v3.4-ROADMAP.md](milestones/v3.4-ROADMAP.md)

</details>

<details>
<summary>✅ v3.5 First-Party Companions (Phases 38-47) — SHIPPED 2026-05-31</summary>

- [x] Phase 38: Companion Seam Contract (2/2 plans) — completed 2026-05-30
- [x] Phase 39: Route-Policy Gating DSL And Manifest Binding (2/2 plans) — completed 2026-05-30
- [x] Phase 40: Runtime Gate Evaluation And Fail-Closed Denial (1/1 plan) — completed 2026-05-30
- [x] Phase 41: Gating Doctor And Support-Matrix Truth (2/2 plans) — completed 2026-05-30
- [x] Phase 42: Rulestead In-Tree Companion And Mock Example (2/2 plans) — completed 2026-05-30
- [x] Phase 43: Rulestead Hermetic+Advisory Proof And Guide (2/2 plans) — completed 2026-05-30
- [x] Phase 44: Rindle Media Seam Contracts And Reconciliation Vocabulary (2/2 plans) — completed 2026-05-31
- [x] Phase 45: Rindle In-Tree Companion, Mock Example, And Proof (3/3 plans) — completed 2026-05-31
- [x] Phase 46: Sigra Auth Contract-Only Slice (4/4 plans) — completed 2026-05-31
- [x] Phase 47: Companion Arc Guide And Milestone Proof (2/2 plans) — completed 2026-05-31

Full phase details: [v3.5-ROADMAP.md](milestones/v3.5-ROADMAP.md)

</details>

<details>
<summary>✅ v3.6 Operator Truth and Production Diagnostics (Phases 48-53) — SHIPPED 2026-06-01</summary>

- [x] Phase 48: Strategic Signal and Milestone Memory (3/3 plans) — completed 2026-05-31
- [x] Phase 49: Operator Inspection Contract (2/2 plans) — completed 2026-05-31
- [x] Phase 50: Doctor Publish and Readiness Checks (2/2 plans) — completed 2026-06-01
- [x] Phase 51: Support Matrix and Native Rebuild Truth (3/3 plans) — completed 2026-06-01
- [x] Phase 52: Operator Proof and Docs-Contract Locks (2/2 plans) — completed 2026-06-01
- [x] Phase 53: Release Continuity and Closeout Hardening (3/3 plans) — completed 2026-06-01

Full phase details: [v3.6-ROADMAP.md](milestones/v3.6-ROADMAP.md)

</details>

<details>
<summary>✅ v3.7 Commerce Provider Adapters (Phases 48 and 48.1) — SHIPPED 2026-06-01</summary>

- [x] Phase 48: Commerce Provider Adapter Context (6/6 plans) — completed 2026-06-01
- [x] Phase 48.1: Close gap: ADPT-01/ADPT-02 provider facade paywall swap-target contract (1/1 plan) — completed 2026-06-01

Full phase details: [v3.7-ROADMAP.md](milestones/v3.7-ROADMAP.md)
Phase archive: [v3.7-phases/](milestones/v3.7-phases/)

</details>

<details>
<summary>✅ v3.8 Full Sigra Auth and Session Machinery (Phases 54-58) — SHIPPED 2026-06-02</summary>

- [x] Phase 54: Sigra Session Authority Contract And Route-Gate Semantics (5/5 plans) — completed 2026-06-02
- [x] Phase 55: Session Handoff Tickets And Authority Projection (3/3 plans) — completed 2026-06-02
- [x] Phase 56: Step-Up Intent And Plug/LiveView Ceremony (4/4 plans) — completed 2026-06-02
- [x] Phase 57: OAuth, Passkey, And Native Return Boundaries (4/4 plans) — completed 2026-06-02
- [x] Phase 58: Auth Diagnostics, Proof, And Security Closeout (3/3 plans) — completed 2026-06-02

Full phase details: [v3.8-ROADMAP.md](milestones/v3.8-ROADMAP.md)
Phase archive: [v3.8-phases/](milestones/v3.8-phases/)

</details>

<details>
<summary>✅ v3.9 Chimeway Notification Seam (Phases 59-63) — SHIPPED 2026-06-03</summary>

- [x] Phase 59: Chimeway Contract And Token Binding Semantics (3/3 plans) — completed 2026-06-02
- [x] Phase 60: Example Host Registry And Phoenix Wiring (3/3 plans) — completed 2026-06-02
- [x] Phase 61: Notification-Open Resolver And Route Policy (4/4 plans) — completed 2026-06-03
- [x] Phase 62: Diagnostics, Support Truth, And Docs (4/4 plans) — completed 2026-06-03
- [x] Phase 63: Hermetic Proof And Advisory Promotion Criteria (3/3 plans) — completed 2026-06-03

Full phase details: [v3.9-ROADMAP.md](milestones/v3.9-ROADMAP.md)
Closeout contract: [v3.9-CLOSEOUT.md](milestones/v3.9-CLOSEOUT.md)
Phase archive: [v3.9-phases/](milestones/v3.9-phases/)

</details>

### 🚧 v4.0 Production Shell Runtime Line (In Progress)

**Milestone Goal:** Harden Crosswake's checked-in iOS/Android shells into a documented, proof-backed production runtime line so adopters can ship and maintain real mobile apps without guessing at compatibility, rebuilds, permissions, or diagnostics.

- [x] **Phase 64: Runtime-Line Policy Contract & Support-Truth Taxonomy** - Lock the OTA-safe vs. rebuild change classification, the `:jvm_hermetic` vs. `:device_verified` evidence taxonomy, the compatibility matrix, and Android promotion criteria — derived from the existing `native_runtime_version` axis, no native code. (completed 2026-06-04)
- [ ] **Phase 65: Diagnostic Export Seam (Elixir)** - Define the redaction allowlist and typed envelope schema for a fire-and-forget HTTP diagnostics seam before any native export code exists.
- [ ] **Phase 66: Generator Templates & Xcode 26 CI Fix** - Emit host-owned iOS/Android permission/entitlement and runtime-line templates from the locked contracts, with placeholder/drift doctor checks, and move iOS CI onto the Xcode 26 SDK.
- [ ] **Phase 67: Native Shell Implementation & Android JVM Hermetic Proof** - Mirror the contracts/templates in the iOS and Android shells, bump Android toolchain floors, and close the JVM-hermetic evidence gap with merge-blocking proof.
- [ ] **Phase 68: Android Verification Closure & Device-UAT** - Add the advisory emulator lane and a capability-parity-locked device-UAT checklist with explicit promotion criteria.
- [ ] **Phase 69: Docs-Contract Parity Gate, Android Promotion & Closeout** - Ship the merge-blocking manifest↔shell↔guide↔doctor parity gate, promote Android support truth only if criteria pass, and run milestone closeout.

## Phase Details

### Phase 64: Runtime-Line Policy Contract & Support-Truth Taxonomy

**Goal**: Lock the runtime-line policy and support-truth taxonomy in Elixir — the OTA-safe vs. rebuild-required change classification, the `:jvm_hermetic` vs. `:device_verified` evidence distinction, the rebuild/compatibility matrix projection, and Android promotion criteria — so no downstream surface can overclaim. Rebuild policy is derived from the existing manifest `native_runtime_version` axis with no new manifest schema field.
**Depends on**: Nothing (first v4.0 phase; builds on shipped Compatibility/SupportMatrix/Doctor surfaces)
**Requirements**: RLINE-01, RLINE-02, RLINE-03, RLINE-04, RLINE-05
**Success Criteria** (what must be TRUE):

  1. For any manifest/capability/shell change, the policy classifies it as OTA-safe or rebuild-required per change class (bridge schema change, capability family add, permission add, entitlement add, SDK floor bump, privacy-manifest entry, push capability change, URL-scheme change) — verifiable via `Crosswake.RuntimeLine`/`RebuildPolicy` and hermetic proof.
  2. The rebuild/OTA decision derives entirely from the existing `compatibility.native_runtime_version` axis, with no new manifest JSON field and no `manifest_schema_version` bump (asserted by a proof test).
  3. An operator running `mix crosswake.doctor` and reading `SupportMatrix` sees a rebuild & compatibility matrix mapping shell/runtime-line version to supported manifest/capability surface.
  4. Support truth reports `:jvm_hermetic` distinctly from `:device_verified` and never labels CI-only evidence as device-verified.
  5. Android support state carries explicit, documented promotion criteria (required evidence, minimum consecutive passes, demotion trigger) for moving from `:verification_required` to `:supported`.

**Plans**: 5 plans
Plans:
**Wave 1**

- [x] 64-01-PLAN.md — Wave-0 hermetic proof lane scaffold (RLINE-01..05)
- [x] 64-02-PLAN.md — types.ex foundation: RuntimeLineRow + verification_method/required_verification_method + SupportMatrix.rebuild_matrix field
- [x] 64-03-PLAN.md — RebuildPolicy module (classify/2, diff/2, rebuild_required?/1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 64-04-PLAN.md — SupportMatrix rebuild_matrix data, CI-only-never-device validation, two gated Android promotion rows

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 64-05-PLAN.md — Doctor human+JSON rebuild matrix + evidence posture rendering

### Phase 65: Diagnostic Export Seam (Elixir)

**Goal**: Define the diagnostics-export contract in Elixir before any native export code exists — a typed, versioned envelope with layer attribution and an explicit, tested redaction allowlist — delivered as a fire-and-forget HTTP seam, not a bridge command.
**Depends on**: Phase 64 (envelope carries `native_runtime_version` from the runtime-line contract)
**Requirements**: DIAG-01, DIAG-02, DIAG-03, DIAG-04
**Success Criteria** (what must be TRUE):

  1. `Crosswake.Shell.DiagnosticExport` defines a fire-and-forget HTTP POST contract to a host-owned endpoint (the Chimeway pattern), with no bounded-bridge command vocabulary added (asserted by proof).
  2. Diagnostic export payloads carry native/web/bridge layer attribution and a stable, typed, versioned envelope schema with fixtures.
  3. `sanitize/1` applies an explicit, tested redaction allowlist (reusing the v3.9 Chimeway/Sigra posture) that forbids raw tokens, payloads, route params, and PII — verified by a merge-blocking allowlist test.
  4. `mix crosswake.doctor` and support truth report diagnostics-export readiness without implying a first-party crash-reporting service.

**Plans**: 3 plans
Plans:
**Wave 1**

- [ ] 65-01-PLAN.md — DiagnosticExport contract module: behaviour + Envelope/NativeDiagnostic structs + fail-closed sanitize/1 + allowlist accessors (DIAG-01/02/03)

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 65-02-PLAN.md — SupportMatrix diagnostic-export truth + unconditional :advisory doctor finding, non-overclaiming (DIAG-04)

**Wave 3** *(blocked on Waves 1+2 completion)*

- [ ] 65-03-PLAN.md — Six generated fixtures + merge-blocking hermetic proof lane covering DIAG-01..04

### Phase 66: Generator Templates & Xcode 26 CI Fix

**Goal**: Emit host-owned iOS/Android permission/entitlement and runtime-line scaffolds from the locked contracts via `mix crosswake.gen.shell`, parity-locked to declared capability families with placeholder/drift doctor checks, and move iOS CI onto the Xcode 26 SDK in the same phase that introduces template generation so they cannot drift.
**Depends on**: Phase 64, Phase 65 (templates instantiate the runtime-line and diagnostics contract shapes)
**Requirements**: TMPL-01, TMPL-02, TMPL-03, TMPL-04, AVER-05
**Success Criteria** (what must be TRUE):

  1. An adopter can generate host-owned iOS permission/entitlement scaffolds (Info.plist usage strings, Entitlements, `PrivacyInfo.xcprivacy`) via `mix crosswake.gen.shell` with `ADOPT:` markers, and Crosswake never writes real native values.
  2. An adopter can generate host-owned Android permission scaffolds (AndroidManifest permission/feature stubs) via the generator with `ADOPT:` markers and host-owned values.
  3. Generated permission/entitlement templates stay parity-locked to declared capability families — every capability requiring a permission or entitlement is represented (asserted by re-runnable generation + doctor parity check).
  4. `mix crosswake.doctor` flags un-replaced template placeholders and manifest↔shell↔docs permission/entitlement drift.
  5. iOS CI builds against the Xcode 26 SDK so iOS shell proof remains App Store-submittable.

**Plans**: TBD
**UI hint**: yes

### Phase 67: Native Shell Implementation & Android JVM Hermetic Proof

**Goal**: Mirror the locked Elixir contracts and generated templates in the checked-in iOS and Android shells — runtime-line policy readers and diagnostics export (MetricKit / `ApplicationExitInfo`) — bump the Android toolchain floors, and close the JVM-hermetic evidence gap with merge-blocking proof. Hermetic JVM is merge-blocking; emulator/device evidence remains advisory.
**Depends on**: Phase 66 (shells implement the generated template patterns)
**Requirements**: AVER-01, AVER-02
**Success Criteria** (what must be TRUE):

  1. Maintainers can run merge-blocking hermetic JVM proof covering the Android runtime-line policy reader and diagnostics export seam.
  2. The Android shell builds against updated toolchain floors (AGP/Kotlin/Gradle, `minSdk 30`, `compileSdk`/`targetSdk 35`) with hermetic proof.
  3. The iOS and Android shells in `examples/` read `native_runtime_version`, enforce the rebuild check via `ActivationCoordinator`, and emit sanitized diagnostic envelopes over the HTTP seam — mirroring the contracts without adding bridge vocabulary.
  4. Android support truth remains `:verification_required` after this phase (no premature promotion); only the JVM-hermetic evidence axis is satisfied.

**Plans**: TBD
**UI hint**: yes

### Phase 68: Android Verification Closure & Device-UAT

**Goal**: Honestly document what JVM tests cannot cover — add the advisory (non-blocking) Android emulator lane with documented promotion criteria, and a device-UAT checklist that is parity-locked to the capability registry and separates CI-provable, device-advisory, and provider-advisory items.
**Depends on**: Phase 67 (advisory device lane and checklist describe the gap beyond hermetic JVM proof)
**Requirements**: AVER-03, AVER-04
**Success Criteria** (what must be TRUE):

  1. Maintainers can run an advisory (`continue-on-error: true`) Android emulator lane with explicit, documented promotion criteria.
  2. A device-UAT checklist enumerates CI-provable / device-advisory / provider-advisory items (deep-link intent resolution, runtime permission flows, WebView rendering, SDK-version behavior, hardware sensors).
  3. The device-UAT checklist stays parity-locked to the capability registry — every capability family has at least one checklist entry, enforced by a doctor or docs-contract parity check.
  4. The checklist carries an explicit "last verified against" field (Crosswake + OS versions) and doctor warns when it is stale.

**Plans**: TBD

### Phase 69: Docs-Contract Parity Gate, Android Promotion & Closeout

**Goal**: Ship the final merge-blocking docs-contract parity gate so manifest, shell fixture, guides, and doctor agree on runtime-line/rebuild/permission/entitlement/diagnostics truth; update guides parity-locked to live support/doctor truth; promote Android support truth from `:verification_required` only if and when promotion criteria pass; and run milestone closeout.
**Depends on**: Phase 68 (Android promotion gated on hermetic proof + advisory lane + device-UAT criteria)
**Requirements**: PROOF-01, PROOF-02, PROOF-03
**Success Criteria** (what must be TRUE):

  1. A merge-blocking docs-contract test verifies that manifest ↔ shell fixture ↔ guide ↔ doctor agree on runtime-line, rebuild, permission/entitlement, and diagnostics truth.
  2. Public guides document the runtime-line policy, rebuild/compatibility matrix, permission/entitlement templates, diagnostics export, and Android verification posture, parity-locked to live support/doctor truth.
  3. Android `SupportEntry` is promoted past `:verification_required` only if the explicit promotion criteria are met; otherwise it stays `:verification_required` with the gap documented.
  4. Milestone closeout (`mix closeout.verify`, REL-01 gate) verifies all v4.0 requirements are mapped and no surface claims first-party shell packages, device-verified Android without evidence, or first-party crash-reporting/push delivery.

**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 64 → 65 → 66 → 67 → 68 → 69

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 64. Runtime-Line Policy Contract & Support-Truth Taxonomy | v4.0 | 6/6 | Complete    | 2026-06-04 |
| 65. Diagnostic Export Seam (Elixir) | v4.0 | 0/3 | Not started | - |
| 66. Generator Templates & Xcode 26 CI Fix | v4.0 | 0/TBD | Not started | - |
| 67. Native Shell Implementation & Android JVM Hermetic Proof | v4.0 | 0/TBD | Not started | - |
| 68. Android Verification Closure & Device-UAT | v4.0 | 0/TBD | Not started | - |
| 69. Docs-Contract Parity Gate, Android Promotion & Closeout | v4.0 | 0/TBD | Not started | - |
