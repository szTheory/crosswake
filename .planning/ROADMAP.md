# Roadmap: Crosswake

## Milestones

- ✅ **v8.0 Offline Sync Hardening and UI Polish** — Phases 99-101 (shipped 2026-06-11)
- ✅ **v9.0 Brand System & Visual Identity** — Phases 102-106 (shipped 2026-06-13)
- ✅ **v10.0 Brand Normalization** — Phases 107-109 (shipped 2026-06-14)
- ✅ **v11.0 Release & Distribution Truth** — Phases 110-111 (shipped 2026-06-17)
- ✅ **v12.0 CI Honesty & Real-E2E Sweep** — Phases 112-115 (shipped 2026-06-18)
- ✅ **v13.0 Adopter Confidence & Native Evidence** — Phases 116-120 (shipped 2026-06-19)
- ✅ **v14.0 Runtime Contract Confidence** — Phases 121-124 (shipped 2026-06-21)
- ✅ **v15.0 See It Run — Experiential First-Run DX** — Phases 125-128 (shipped 2026-06-24)
- ✅ **v16.0 Companion Extraction & Package-Family Discipline** — Phases 129-135 (shipped 2026-06-30)
- ✅ **v17.0 Companion Family Completion** — Phases 136-141 (shipped 2026-07-04)
- ✅ **v18.0 Release Integrity & Automated Package Operations** — Phases 142-146 (shipped 2026-07-09)
- ◆ **v19.0 Showcase Apps & Capability Map** — Phases 147-152 (active)

## Phases

## v19.0 Showcase Apps & Capability Map

**Goal:** Turn Crosswake into a product-shaped, click-around DX showcase across realistic app domains, then use that evidence to define v20.0 Native Controls Pack 1.

**Phase count:** 6
**Requirements covered:** 31/31
**Starting phase:** 147

### Phase 147: Arc, Fixture, and Showcase Foundation

**Goal:** Establish the durable v19/v20 arc, deterministic data foundation, and first-screen showcase hub.

**Requirements:** ARC-01, ARC-02, ARC-03, SHOW-01, SHOW-02, SHOW-03, SHOW-04

**Success criteria:**

1. Planning docs preserve the v19 showcase -> v20 Native Controls Pack 1 -> later capture/device, commerce/paywall, operator dashboard, and offline-sync/native-storage thread, with SEED-002 as strategic input and SEED-003/004 as release-infrastructure carryovers.
2. The example host has a first-screen showcase hub with SaaS/admin, field-service, and learning/training lanes visible.
3. Showcase data has a deterministic reset/reseed path with believable records for all three lanes.
4. Route-owner/support labels are present in the hub foundation and avoid blurring shipped support with future gaps.
5. The existing first-run path points users toward the showcase as the product-shaped entrypoint.

**Plans:** 5/5 plans complete

Plans:
**Wave 1**

- [x] 147-01-PLAN.md — Preserve the v19/v20 arc and SEED-002/003/004 classifications.
- [x] 147-02-PLAN.md — Create the showcase catalog and route-owner/support label verification.
- [x] 147-03-PLAN.md — Build deterministic fixture/reset orchestration and seed/CLI delegation.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 147-04-PLAN.md — Wire the root showcase hub and gated reset endpoint.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 147-05-PLAN.md — Repoint first-run banner/docs and add a narrow hub route-tour smoke.

### Phase 148: Demo App Brand & Fixture Direction

**Goal:** Establish Crosswake-branded showcase framing, three distinct demo-app micro-brands, realistic fixture-density standards, and the root-hub visual upgrade consumed by later lane phases.

**Requirements:** BRAND-01, BRAND-02, BRAND-03, BRAND-04

**Completed:** 2026-07-09

**Success criteria:**

1. Root showcase is clearly Crosswake-branded with the Crosswake logo/lockup and no "example host" product copy.
2. AdminPilot, Fieldserv, and LearnLoop are fixed as distinct fictional demo-app identities with non-Crosswake visual systems and category-forward names.
3. Each demo app has a fixture brief defining realistic org/person/record/activity/pressure data requirements for later lane phases.
4. Root hub renders the three micro-brands as polished product previews while preserving route-owner/support truth.
5. Tests/UAT guard brand distinctness, fixture density, root logo/copy, mobile overflow, focus, and support-label honesty.

### Phase 149: SaaS/Admin Showcase

**Goal:** Build the LiveView-first SaaS/admin lane that demonstrates Phoenix-native route ownership, auth/admin pressure, diagnostics, and support truth.

**Requirements:** SAAS-01, SAAS-02, SAAS-03, SAAS-04

**Success criteria:**

1. A user can click through realistic SaaS/admin records such as accounts, teams, roles, settings, and operational events.
2. The lane makes LiveView-first ownership and auth-sensitive/admin posture visible without implying native rendering.
3. Diagnostics, support truth, and route policy are reachable from the lane.
4. A representative admin workflow completes without requiring new native-control APIs.

**Plans:** 7 plans

Plans:
**Wave 0**

- [x] 149-01-PLAN.md — Create Wave 0 AdminPilot ExUnit and route-tour contracts.

**Wave 1** *(blocked on Wave 0 test contracts)*

- [x] 149-02-PLAN.md — Expand deterministic SaaS/admin fixture breadth and read contexts.
- [x] 149-03-PLAN.md — Add lane-local route-policy diagnostics derived from compiled router metadata.

**Wave 2** *(blocked on fixture breadth)*

- [x] 149-04-PLAN.md — Persist only mutable approval/activity evidence and wire reset/digest truth.

**Wave 3** *(blocked on fixture breadth, diagnostics, and approval context)*

- [x] 149-05-PLAN.md — Build AdminPilot shell, context pages, diagnostics panel, and responsive styling.

**Wave 4** *(blocked on approval context and shared UI)*

- [x] 149-06-PLAN.md — Complete approval queue/detail LiveViews with server-authoritative approve action.

**Wave 5** *(blocked on AdminPilot UI and approval workflow)*

- [x] 149-07-PLAN.md — Add gated e2e approver session helper and run full ExUnit plus Playwright proof.

### Phase 150: Field-Service Showcase

**Goal:** Build the device-pressure field-service lane that demonstrates capture/scanning intent, media/evidence pressure, offline/degraded posture, and explicit future native gaps.

**Requirements:** FIELD-01, FIELD-02, FIELD-03, FIELD-04

**Success criteria:**

1. A user can click through realistic field-service jobs, assets, inspections, notes, technician state, and evidence records.
2. Device-pressure flows clearly distinguish shipped support from capture/scanning/permission gaps.
3. Offline or degraded states are represented honestly without claiming local-first mutation unless a real journal/outbox path exists.
4. Route-owner labels show which flows stay LiveView, become offline islands, or should become future native screens.

**Plans:** 7 plans

Plans:
**Wave 0**

- [x] 150-01-PLAN.md — Create Wave 0 Fieldserv ExUnit, LiveView, route-tour, and evidence-manifest contracts.

**Wave 1** *(blocked on Wave 0 test contracts)*

- [x] 150-02-PLAN.md — Build deterministic Fieldserv fixture breadth and read contexts.
- [x] 150-03-PLAN.md — Declare Fieldserv route ownership and lane-local diagnostics from compiled router metadata.

**Wave 2** *(blocked on Wave 0 test contracts and fixture breadth)*

- [x] 150-04-PLAN.md — Add narrow Fieldserv evidence/workflow persistence and deterministic reset truth.

**Wave 3** *(blocked on fixture breadth, route diagnostics, and evidence state)*

- [x] 150-05-PLAN.md — Build the Fieldserv product shell, responsive styles, jobs list, job detail, and inspection workspace.

**Wave 4** *(blocked on evidence state and Fieldserv UI)*

- [x] 150-06-PLAN.md — Complete native capture handoff and backend-authoritative evidence review.

**Wave 5** *(blocked on Fieldserv UI, capture handoff, and evidence review)*

- [x] 150-07-PLAN.md — Run full ExUnit plus Playwright proof and preserve capability-map evidence for Phase 152.

### Phase 151: Subscription Learning Showcase

**Goal:** Build the subscription learning/training lane that demonstrates content packs, offline study/training, sync/reconciliation visibility, and entitlement/paywall pressure.

**Requirements:** LEARN-01, LEARN-02, LEARN-03, LEARN-04

**Success criteria:**

1. A user can click through realistic courses, lessons, packs, learners, progress, and subscription state.
2. Content-pack and offline-study behavior is visible and connected to existing Crosswake offline posture.
3. Sync/reconciliation state is shown honestly and does not imply a generic sync engine.
4. Entitlement/paywall pressure is represented as backend-owned or mocked state without claiming live storefront support.

**Plans:** 7 plans

Plans:
**Wave 0**

- [x] 151-01-PLAN.md — Create Wave 0 LearnLoop ExUnit, LiveView, reset, entitlement, and Playwright contracts.

**Wave 1** *(blocked on Wave 0 test contracts)*

- [x] 151-02-PLAN.md — Build deterministic LearnLoop fixture/read-context breadth and reset digest truth.

**Wave 2** *(blocked on fixture breadth)*

- [x] 151-03-PLAN.md — Declare product-first LearnLoop routes and compiled-router diagnostics.

**Wave 3** *(blocked on routes and diagnostics)*

- [x] 151-04-PLAN.md — Convert the proven socketless offline island into `/learnloop/study/session`.
- [x] 151-05-PLAN.md — Build the LearnLoop product shell, dashboard, course, pack, and history LiveViews.

**Wave 4** *(blocked on LearnLoop UI shell)*

- [ ] 151-06-PLAN.md — Add backend-owned mocked entitlement pressure and subscription LiveView.

**Wave 5** *(blocked on complete LearnLoop workflow)*

- [ ] 151-07-PLAN.md — Run full ExUnit plus semantic-first Playwright proof.

### Phase 152: Capability Map, Collateral, and v20 Handoff

**Goal:** Convert showcase evidence into a durable capability map, proof/collateral surface, and decision-ready v20 Native Controls Pack 1 brief.

**Requirements:** CAPMAP-01, CAPMAP-02, CAPMAP-03, CAPMAP-04, PROOF-01, PROOF-02, PROOF-03, PROOF-04

**Success criteria:**

1. Capability map classifies shipped, demoed, missing, deferred, and next-pack capabilities with package ownership and proof posture.
2. v20 Native Controls Pack 1 is scoped from v19 evidence without re-opening the whole product arc.
3. Fixture reset and route-tour coverage prove deterministic data plus one happy path per lane.
4. Docs/support checks prevent unsupported native controls from being presented as shipped.
5. Showcase collateral explains what Crosswake supports today, what is demo pressure, and what is planned for v20+.

<details>
<summary>✅ v18.0 Release Integrity & Automated Package Operations (Phases 142-146) — SHIPPED 2026-07-09</summary>

- [x] Phase 142: Release Graph & Governance Contract (3/3 plans) — completed 2026-07-07
- [x] Phase 143: Guarded Auto-Publish Train (3/3 plans) — completed 2026-07-07
- [x] Phase 144: Published-Core Compatibility & Clean-Room Proof (3/3 plans) — completed 2026-07-08
- [x] Phase 145: Native Registry & Mirror Parity (3/3 plans) — completed 2026-07-08
- [x] Phase 146: Release Status DX & Docs Truth (3/3 plans) — completed 2026-07-09

Full phase detail archived in `.planning/milestones/v18.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v8.0 Offline Sync Hardening and UI Polish (Phases 99-101) — SHIPPED 2026-06-11</summary>

- [x] Phase 99: Real Network-Toggling E2E Tests (2/2 plans) — completed 2026-06-11
- [x] Phase 100: Storage Budget Enforcement (2/2 plans) — completed 2026-06-11
- [x] Phase 101: Offline UI Consolidation & Polish (2/2 plans) — completed 2026-06-11

Full phase detail archived in `.planning/milestones/v8.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v9.0 Brand System & Visual Identity (Phases 102-106) — SHIPPED 2026-06-13</summary>

- [x] Phase 102: Brand Audit & Token Foundation (4/4 plans) — completed 2026-06-12
- [x] Phase 103: Logo Tournament (4/4 plans) — completed 2026-06-12
- [x] Phase 104: Logo Refinement & Production Suite (3/3 plans) — completed 2026-06-12
- [x] Phase 105: HTML Brand Book (3/3 plans) — completed 2026-06-12
- [x] Phase 106: Collateral, Integration & Closeout (2/2 plans) — completed 2026-06-13

Full phase detail archived in `.planning/milestones/v9.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v10.0 Brand Normalization (Phases 107-109) — SHIPPED 2026-06-14</summary>

- [x] Phase 107: Token Source & Distribution (3/3 plans) — completed 2026-06-13
- [x] Phase 108: Consumer Normalization (4/4 plans) — completed 2026-06-14
- [x] Phase 109: Drift-Prevention Gate (3/3 plans) — completed 2026-06-14

Full phase detail archived in `.planning/milestones/v10.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v11.0 Release & Distribution Truth (Phases 110-111) — SHIPPED 2026-06-17</summary>

- [x] Phase 110: Native Publish & Lockstep Infrastructure (3/3 plans) — completed 2026-06-14
- [x] Phase 111: Generator Rewire, Clean-Room Proof & Release (5/5 plans) — completed 2026-06-17

Full phase detail archived in `.planning/milestones/v11.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v12.0 CI Honesty & Real-E2E Sweep (Phases 112-115) — SHIPPED 2026-06-18</summary>

- [x] Phase 112: Real Offline Outbox Flush (2/2 plans) — completed 2026-06-17
- [x] Phase 113: Honest E2E Rewrite + Compile Gate (3/3 plans) — completed 2026-06-18
- [x] Phase 114: Merge-Blocking CI Gate + Permanent Honesty Guard (5/5 plans) — completed 2026-06-18
- [x] Phase 115: Closeout-Verifier Honesty + Ledger Backlog + Doc Truth (3/3 plans) — completed 2026-06-18

Full phase detail archived in `.planning/milestones/v12.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v13.0 Adopter Confidence & Native Evidence (Phases 116-120) — SHIPPED 2026-06-19</summary>

- [x] Phase 116: Proof Debt And Release Truth (3/3 plans) — completed 2026-06-18
- [x] Phase 117: Route-Policy And Support-Truth Guide Foundation (3/3 plans) — completed 2026-06-19
- [x] Phase 118: Runnable Quick Start And Real Adoption Proof (3/3 plans) — completed 2026-06-19
- [x] Phase 119: Native Evidence Classification (3/3 plans) — completed 2026-06-19
- [x] Phase 120: Collateral, Artifact CI, And Troubleshooting (4/4 plans) — completed 2026-06-19

Full phase detail archived in `.planning/milestones/v13.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v14.0 Runtime Contract Confidence (Phases 121-124) — SHIPPED 2026-06-21</summary>

- [x] Phase 121: Canonical Contract Source (4/4 plans) — completed 2026-06-20
- [x] Phase 122: Drift Guards (3/3 plans) — completed 2026-06-20
- [x] Phase 123: Native Package Behavioral Proof (4/4 plans) — completed 2026-06-20
- [x] Phase 124: Compatibility Semantics & Adopter Truth (6/6 plans) — completed 2026-06-21

Full phase detail archived in `.planning/milestones/v14.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v15.0 See It Run — Experiential First-Run DX (Phases 125-128) — SHIPPED 2026-06-24</summary>

- [x] Phase 125: Containerized Shared Backend + Port Convention (3/3 plans) — completed 2026-06-21
- [x] Phase 126: Additive Native Dev Wiring (4/4 plans) — completed 2026-06-22
- [x] Phase 127: Launch Orchestration + Banner (2/2 plans) — completed 2026-06-22
- [x] Phase 128: Collateral + "See It Run" Guide (3/3 plans) — completed 2026-06-22

Full phase detail archived in `.planning/milestones/v15.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v16.0 Companion Extraction & Package-Family Discipline (Phases 129-135) — SHIPPED 2026-06-30</summary>

- [x] Phase 129: Stable Companion Contract Surface (2/2 plans) — completed 2026-06-25
- [x] Phase 130: Extraction Mechanics & Footgun Guards (5/5 plans) — completed 2026-06-26
- [x] Phase 131: Publish Pipeline & Clean-Room Lane (rulestead) (3/3 plans) — completed 2026-06-26
- [x] Phase 132: Generalization Proof (rindle) + Compat Matrix (4/4 plans) — completed 2026-06-26
- [x] Phase 133: Telemetry Public API (4/4 plans) — completed 2026-06-28
- [x] Phase 134: Shell Lifecycle + Native UAT Promotion (5/5 plans) — completed 2026-06-29
- [x] Phase 135: CI-Ops Hardening — Release-As Automation (PROOF-03) (1/1 plan) — completed 2026-06-28

Full phase detail archived in `.planning/milestones/v16.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v17.0 Companion Family Completion (Phases 136-141) — SHIPPED 2026-07-04</summary>

- [x] Phase 136: Core Decoupling (6/6 plans) — completed 2026-07-01
- [x] Phase 137: crosswake_sigra Extraction (5/5 plans) — completed 2026-07-04
- [x] Phase 138: crosswake_chimeway Extraction (4/4 plans) — completed 2026-07-04
- [x] Phase 139: crosswake_threadline Extraction (4/4 plans) — completed 2026-07-04
- [x] Phase 140: Family Discipline & Close (5/5 plans) — completed 2026-07-04
- [x] Phase 141: Core-First Publish & Family Release (5/5 plans) — completed 2026-07-04

Full phase detail archived in `.planning/milestones/v17.0-ROADMAP.md`.

</details>

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 99. Real Network-Toggling E2E Tests | v8.0 | 2/2 | Complete | 2026-06-11 |
| 100. Storage Budget Enforcement | v8.0 | 2/2 | Complete | 2026-06-11 |
| 101. Offline UI Consolidation & Polish | v8.0 | 2/2 | Complete | 2026-06-11 |
| 102. Brand Audit & Token Foundation | v9.0 | 4/4 | Complete | 2026-06-12 |
| 103. Logo Tournament | v9.0 | 4/4 | Complete | 2026-06-12 |
| 104. Logo Refinement & Production Suite | v9.0 | 3/3 | Complete | 2026-06-12 |
| 105. HTML Brand Book | v9.0 | 3/3 | Complete | 2026-06-12 |
| 106. Collateral, Integration & Closeout | v9.0 | 2/2 | Complete | 2026-06-13 |
| 107. Token Source & Distribution | v10.0 | 3/3 | Complete | 2026-06-13 |
| 108. Consumer Normalization | v10.0 | 4/4 | Complete | 2026-06-14 |
| 109. Drift-Prevention Gate | v10.0 | 3/3 | Complete | 2026-06-14 |
| 110. Native Publish & Lockstep Infrastructure | v11.0 | 3/3 | Complete | 2026-06-14 |
| 111. Generator Rewire, Clean-Room Proof & Release | v11.0 | 5/5 | Complete | 2026-06-17 |
| 112. Real Offline Outbox Flush | v12.0 | 2/2 | Complete | 2026-06-17 |
| 113. Honest E2E Rewrite + Compile Gate | v12.0 | 3/3 | Complete | 2026-06-18 |
| 114. Merge-Blocking CI Gate + Permanent Honesty Guard | v12.0 | 5/5 | Complete | 2026-06-18 |
| 115. Closeout-Verifier Honesty + Ledger Backlog + Doc Truth | v12.0 | 3/3 | Complete | 2026-06-18 |
| 116. Proof Debt And Release Truth | v13.0 | 3/3 | Complete | 2026-06-18 |
| 117. Route-Policy And Support-Truth Guide Foundation | v13.0 | 3/3 | Complete | 2026-06-19 |
| 118. Runnable Quick Start And Real Adoption Proof | v13.0 | 3/3 | Complete | 2026-06-19 |
| 119. Native Evidence Classification | v13.0 | 3/3 | Complete | 2026-06-19 |
| 120. Collateral, Artifact CI, And Troubleshooting | v13.0 | 4/4 | Complete | 2026-06-19 |
| 121. Canonical Contract Source | v14.0 | 4/4 | Complete | 2026-06-20 |
| 122. Drift Guards | v14.0 | 3/3 | Complete | 2026-06-20 |
| 123. Native Package Behavioral Proof | v14.0 | 4/4 | Complete | 2026-06-20 |
| 124. Compatibility Semantics & Adopter Truth | v14.0 | 6/6 | Complete | 2026-06-21 |
| 125. Containerized Shared Backend + Port Convention | v15.0 | 3/3 | Complete | 2026-06-21 |
| 126. Additive Native Dev Wiring | v15.0 | 4/4 | Complete | 2026-06-22 |
| 127. Launch Orchestration + Banner | v15.0 | 2/2 | Complete | 2026-06-22 |
| 128. Collateral + "See It Run" Guide | v15.0 | 3/3 | Complete | 2026-06-22 |
| 129. Stable Companion Contract Surface | v16.0 | 2/2 | Complete | 2026-06-25 |
| 130. Extraction Mechanics & Footgun Guards | v16.0 | 5/5 | Complete | 2026-06-26 |
| 131. Publish Pipeline & Clean-Room Lane (rulestead) | v16.0 | 3/3 | Complete | 2026-06-26 |
| 132. Generalization Proof (rindle) + Compat Matrix | v16.0 | 4/4 | Complete | 2026-06-26 |
| 133. Telemetry Public API | v16.0 | 4/4 | Complete | 2026-06-28 |
| 134. Shell Lifecycle + Native UAT Promotion | v16.0 | 5/5 | Complete | 2026-06-29 |
| 135. CI-Ops Hardening — Release-As Automation | v16.0 | 1/1 | Complete | 2026-06-28 |
| 136. Core Decoupling | v17.0 | 6/6 | Complete    | 2026-07-01 |
| 137. crosswake_sigra Extraction | v17.0 | 5/5 | Complete | 2026-07-04 |
| 138. crosswake_chimeway Extraction | v17.0 | 4/4 | Complete | 2026-07-04 |
| 139. crosswake_threadline Extraction | v17.0 | 4/4 | Complete | 2026-07-04 |
| 140. Family Discipline & Close | v17.0 | 5/5 | Complete | 2026-07-04 |
| 141. Core-First Publish & Family Release | v17.0 | 5/5 | Complete | 2026-07-04 |
| 142. Release Graph & Governance Contract | v18.0 | 3/3 | Complete    | 2026-07-07 |
| 143. Guarded Auto-Publish Train | v18.0 | 3/3 | Complete    | 2026-07-07 |
| 144. Published-Core Compatibility & Clean-Room Proof | v18.0 | 3/3 | Complete    | 2026-07-08 |
| 145. Native Registry & Mirror Parity | v18.0 | 3/3 | Complete    | 2026-07-08 |
| 146. Release Status DX & Docs Truth | v18.0 | 3/3 | Complete    | 2026-07-09 |
| 147. Arc, Fixture, and Showcase Foundation | v19.0 | 5/5 | Complete    | 2026-07-09 |
| 148. Demo App Brand & Fixture Direction | v19.0 | 0/0 | Complete | 2026-07-09 |
| 149. SaaS/Admin Showcase | v19.0 | 7/7 | Complete    | 2026-07-11 |
| 150. Field-Service Showcase | v19.0 | 7/7 | Complete | 2026-07-11 |
| 151. Subscription Learning Showcase | v19.0 | 5/7 | In Progress|  |
| 152. Capability Map, Collateral, and v20 Handoff | v19.0 | 0/0 | Pending | — |
