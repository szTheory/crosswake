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
- ◆ **v18.0 Release Integrity & Automated Package Operations** — Phases 142-146 (active)

## Phases

<details open>
<summary>◆ v18.0 Release Integrity & Automated Package Operations (Phases 142-146) — ACTIVE</summary>

Goal: make Crosswake's package-family release path automated, path-specific, and honest before adding new product breadth. v18 harvests SEED-003 and SEED-004, finishes release-gate discipline, and keeps dashboard/offline/capability breadth deferred.

- [x] Phase 142: Release Graph & Governance Contract — encode and test the release DAG so core/native/companion publish jobs cannot be triggered by the wrong Release Please output. Requirements: RELG-01, RELG-02, RELG-03. (completed 2026-07-07)
- [x] Phase 143: Guarded Auto-Publish Train — make package publishes hands-free on the happy path while preserving exact-ref recovery and independent companion versioning. Requirements: AUTO-01, AUTO-02, AUTO-03. (completed 2026-07-07)
- [ ] Phase 144: Published-Core Compatibility & Clean-Room Proof — repair the clean-room harness, use exact companion versions and derived core floors, and prove doctor can load fresh routers. Requirements: PREF-01, PREF-02, PREF-03.
- [ ] Phase 145: Native Registry & Mirror Parity — harden the iOS mirror token path, decouple native clean-room proofs, and document/backfill the missing `v0.2.0` SwiftPM tag. Requirements: MIRR-01, MIRR-02, MIRR-03.
- [ ] Phase 146: Release Status DX & Docs Truth — ship `mix crosswake.release.status`, JSON output, optional live probes, and reconcile stale release docs. Requirements: STAT-01, STAT-02, STAT-03.

Success criteria:

1. Companion-only releases cannot publish core Hex, iOS mirror, or Android Maven artifacts.
2. The clean-room harness resolves the exact package under test against its real published-core floor.
3. Maintainers can run one local command for package-family release status and a machine-readable JSON variant.
4. Missing or invalid iOS mirror credentials fail with a clear action instead of leaving SwiftPM silently behind.
5. Deferred product-breadth seeds remain out of scope until release integrity is trustworthy.

## Phase Details

### Phase 142: Release Graph & Governance Contract

**Goal:** Encode and test the release DAG so core/native/companion publish jobs cannot be triggered by the wrong Release Please output.
**Requirements:** RELG-01, RELG-02, RELG-03
**Plans:** 3/3 plans complete

### Phase 143: Guarded Auto-Publish Train

**Goal:** Make package publishes hands-free on the happy path while preserving exact-ref recovery and independent companion versioning.
**Requirements:** AUTO-01, AUTO-02, AUTO-03
**Plans:** 3/3 plans complete

Plans:
**Wave 1**

- [x] 143-01-PLAN.md — Shared guarded Hex publish helper and automatic Release Please workflow integration.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 143-02-PLAN.md — Component-aware exact-ref manual Hex recovery workflow.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 143-03-PLAN.md — Semantic proof, version-graph/floor guardrails, and runbook reconciliation.

### Phase 144: Published-Core Compatibility & Clean-Room Proof

**Goal:** Repair the clean-room harness, use exact companion versions and derived core floors, and prove doctor can load fresh routers.
**Requirements:** PREF-01, PREF-02, PREF-03
**Plans:** 3/3 plans created

Plans:
**Wave 1**

- [x] 144-01-PLAN.md — Published Hex metadata floor, exact companion pin, lockfile postconditions, and package-profile preservation for clean-room proof.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 144-02-PLAN.md — Doctor-owned fresh-router loading, app config readiness, and removal of harness-side router preload masking.

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 144-03-PLAN.md — Merge-blocking static scanner and ExUnit fixtures for PREF-03 release-integrity regressions.

### Phase 145: Native Registry & Mirror Parity

**Goal:** Harden the iOS mirror token path, decouple native clean-room proofs, and document/backfill the missing `v0.2.0` SwiftPM tag.
**Requirements:** MIRR-01, MIRR-02, MIRR-03
**Plans:** 0/3

### Phase 146: Release Status DX & Docs Truth

**Goal:** Ship `mix crosswake.release.status`, JSON output, optional live probes, and reconcile stale release docs.
**Requirements:** STAT-01, STAT-02, STAT-03
**Plans:** 0/3

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
| 144. Published-Core Compatibility & Clean-Room Proof | v18.0 | 2/3 | In Progress|  |
| 145. Native Registry & Mirror Parity | v18.0 | 0/3 | Pending | — |
| 146. Release Status DX & Docs Truth | v18.0 | 0/3 | Pending | — |
