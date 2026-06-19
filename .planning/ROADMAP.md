# Roadmap: Crosswake

## Milestones

- ✅ **v8.0 Offline Sync Hardening and UI Polish** — Phases 99-101 (shipped 2026-06-11)
- ✅ **v9.0 Brand System & Visual Identity** — Phases 102-106 (shipped 2026-06-13)
- ✅ **v10.0 Brand Normalization** — Phases 107-109 (shipped 2026-06-14)
- ✅ **v11.0 Release & Distribution Truth** — Phases 110-111 (shipped 2026-06-17)
- ✅ **v12.0 CI Honesty & Real-E2E Sweep** — Phases 112-115 (shipped 2026-06-18)
- 🔄 **v13.0 Adopter Confidence & Native Evidence** — Phases 116-120 (active 2026-06-18)

## Phases

<details>
<summary>✅ v8.0 Offline Sync Hardening and UI Polish (Phases 99-101) — SHIPPED 2026-06-11</summary>

- [x] Phase 99: Real Network-Toggling E2E Tests (2/2 plans) — completed 2026-06-11
- [x] Phase 100: Storage Budget Enforcement (2/2 plans) — completed 2026-06-11
- [x] Phase 101: Offline UI Consolidation & Polish (2/2 plans) — completed 2026-06-11

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

First lockstep release: `crosswake 0.1.2` live on Hex + Maven Central + SwiftPM mirror from one release-please run. All 11 v1 requirements complete (PUB-01..03, LOCK-01/02, GEN-01/02, PROOF-01/02, DOCS-01, REL-01).

Full phase detail archived in `.planning/milestones/v11.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v12.0 CI Honesty & Real-E2E Sweep (Phases 112-115) — SHIPPED 2026-06-18</summary>

- [x] Phase 112: Real Offline Outbox Flush (2/2 plans) — completed 2026-06-17
- [x] Phase 113: Honest E2E Rewrite + Compile Gate (3/3 plans) — completed 2026-06-18
- [x] Phase 114: Merge-Blocking CI Gate + Permanent Honesty Guard (5/5 plans) — completed 2026-06-18
- [x] Phase 115: Closeout-Verifier Honesty + Ledger Backlog + Doc Truth (3/3 plans) — completed 2026-06-18

All 10 v1 requirements complete (E2E-01/02/03/04, GATE-01/02, GUARD-01/02, DEBT-01, DOC-01). The milestone replaced fabricated offline-sync proof with a real IndexedDB outbox/reconnect/Ecto loop, promoted the E2E lane behind structural guards, hardened closeout verification, closed historical validation-ledger debt, and reconciled v8.0 document truth.

Full phase detail archived in `.planning/milestones/v12.0-ROADMAP.md`.

</details>

### v13.0 Adopter Confidence & Native Evidence (Phases 116-120) — ACTIVE

- [x] **Phase 116: Proof Debt And Release Truth** - Make the public proof path clean and current before it becomes adopter evidence (3/3 plans)
- [x] **Phase 117: Route-Policy And Support-Truth Guide Foundation** - Make the route-owner mental model and proof-label vocabulary the first-read frame (3/3 plans)
- [x] **Phase 118: Runnable Quick Start And Real Adoption Proof** - Turn the first hands-on path into a command-verified proof of v11/v12 truth (3/3 plans) (completed 2026-06-19)
- [ ] **Phase 119: Native Evidence Classification** - Decide and label whether native evidence is published-coordinate proof, local-dev proof, or advisory collateral (0/3 plans)
- [ ] **Phase 120: Collateral, Artifact CI, And Troubleshooting** - Package durable route-ownership evidence with honest artifact labels and recovery docs (0/4 plans)

## Phase Details

### Phase 116: Proof Debt And Release Truth

**Goal**: Public proof starts from clean local debt and current release truth, so adopters are not sent through known failing tests, stale version claims, or deferred-shell prose.
**Depends on**: Phase 115 (v12.0 complete)
**Requirements**: PROOF-01, REL-TRUTH-01, DRIFT-01
**Success Criteria** (what must be TRUE):

  1. A user following public proof commands is not routed through known failing or flaky example-host tests; `TODO-001` is fixed or explicitly excluded from public proof with a narrow reason.
  2. A reader of README, CHANGELOG, install/native/compatibility guides, support matrix references, ExDoc extras, and example manifests sees `crosswake 0.1.2` as current release truth, or old fixture truth is clearly labeled.
  3. Public prose no longer says standalone public shell packages are deferred, latest Hex is `0.1.0`, or `0.1.2` is pending except in explicitly historical context.
  4. A cheap local/CI drift check fails if stale current-version claims, unlabelled `0.1.0` baseline claims, or deferred-standalone-shell prose return.

**Plans**: 3 planned plans (2 waves)
Plans:

**Wave 1**

- [x] 116-01-PLAN.md — Resolve or explicitly exclude `TODO-001` from public proof commands and reconcile STATE/TODO truth.
- [x] 116-02-PLAN.md — Reconcile README, CHANGELOG, ExDoc extras, guides, support references, and example manifest wording to `0.1.2` release truth.

**Wave 2** *(blocked on Wave 1 public-truth baseline)*

- [x] 116-03-PLAN.md — Add deterministic release-truth drift guard for stale versions and deferred-shell claims.

### Phase 117: Route-Policy And Support-Truth Guide Foundation

**Goal**: Users understand Crosswake as route policy for Phoenix apps that go mobile before they follow commands or interpret evidence.
**Depends on**: Phase 116
**Requirements**: GUIDE-01, MIGRATE-01, TRUTH-01
**Success Criteria** (what must be TRUE):

  1. A new reader can start from README or ExDoc and identify Crosswake's one job: declare, enforce, and diagnose route ownership for Phoenix apps crossing into mobile.
  2. The route-policy guide explains owner decisions for `:live_view`, bounded bridge, cached read-only, `:offline_island`, native-owned routes, backend/provider seams, and deferrals, with current examples and links to manifest, doctor, and support truth.
  3. An existing Phoenix SaaS team can use the migration guide to inventory routes by user job and decide what stays LiveView, gets one bounded native affordance, becomes cached read-only, becomes an offline island, becomes native-owned, or stays deferred.
  4. README, ExDoc guide groups, support matrix entry points, and guide maps use one support-truth vocabulary, with a friendly legend before the dense canonical support matrix.

**Plans**: 3 planned plans (2 waves)
Plans:

**Wave 1**

- [x] 117-01-PLAN.md — Add/promote the route-policy start-here guide and route-owner decision examples.
- [x] 117-02-PLAN.md — Add the web-to-mobile migration guide for existing Phoenix SaaS adopters.

**Wave 2** *(blocked on Wave 1 guide vocabulary)*

- [x] 117-03-PLAN.md — Reconcile support-truth labels, README/ExDoc guide grouping, and support matrix entry points.

### Phase 118: Runnable Quick Start And Real Adoption Proof

**Goal**: A skeptical adopter can follow the first hands-on path from a clean checkout and see the current v11/v12 architecture without stale commands or fictional offline authority.
**Depends on**: Phase 117
**Requirements**: QUICK-01, ADOPT-01, DRIFT-02
**Success Criteria** (what must be TRUE):

  1. `examples/QUICK_START.md` works from a clean checkout and names exact setup, server, proof, iOS, and Android commands, including the correct default Phoenix host port (`4002`) and current project paths.
  2. The adoption guide teaches app-owned offline island JavaScript, IndexedDB outbox, reconnect-triggered `flushOutbox`, `/study/sync`, Ecto idempotency, outbox deletion, accepted/rejected/conflict semantics, and no broad background sync.
  3. The quick start points to current proof for a Phoenix-owned route, bounded bridge affordance, offline island, and native-owned/advisory path without implying broad device support or bridge-owned mutation authority.
  4. A drift guard catches missing setup aliases, wrong port/path claims, forbidden `Crosswake.mutate` examples, and bridge-owned offline mutation language.

**Plans**: 3 planned plans (2 waves)
Plans:

**Wave 1**

- [x] 118-01-PLAN.md — Rewrite and command-verify `examples/QUICK_START.md` against current repo paths, port, setup, proof commands, and advisory native steps.
- [x] 118-02-PLAN.md — Rewrite `guides/adoption.md` around the v12 app-owned IndexedDB outbox/reconnect/Ecto proof.

**Wave 2** *(blocked on Wave 1 docs text)*

- [x] 118-03-PLAN.md — Add quick-start/adoption drift guard for command, path, port, and forbidden offline-authority language.

### Phase 119: Native Evidence Classification

**Goal**: Users can tell exactly whether native evidence proves published coordinates, local-development hosts, or advisory simulator/emulator collateral.
**Depends on**: Phase 118
**Requirements**: NATIVE-01, NATIVE-02, DRIFT-03
**Success Criteria** (what must be TRUE):

  1. A v13 evidence-label decision records valid native evidence classes and the chosen checked-in host strategy: preferred published-coordinate defaults, or explicit local-development fallback.
  2. Native host READMEs, quick start, README, native shell guide, support matrix, Android UAT guide, generator docs, and artifact captions consistently distinguish published-coordinate proof from local-dev proof.
  3. Public proof never presents stale `dev.crosswake:shell-core-android:0.1.0` or a silent `XCLocalSwiftPackageReference` as adopter install proof.
  4. A native drift guard fails on stale Android coordinates, unlabelled local iOS package references, or missing advisory/local-dev labels for checked-in host evidence.

**Plans**: 3 planned plans (2 waves)
Plans:

**Wave 1**

- [ ] 119-01-PLAN.md — Record the evidence-label decision and settle checked-in host strategy: published-coordinate default or explicit local-development proof.
- [ ] 119-02-PLAN.md — Reconcile native READMEs, quick start, support matrix, native shell guide, Android UAT guide, generator docs, and captions to the chosen evidence class.

**Wave 2** *(blocked on Wave 1 classification)*

- [ ] 119-03-PLAN.md — Add native evidence drift guard for stale coordinates and missing local-dev/advisory labels.

### Phase 120: Collateral, Artifact CI, And Troubleshooting

**Goal**: Users can see durable route-ownership evidence and recover from common route/diagnostic failures while every artifact stays honestly labeled.
**Depends on**: Phase 119
**Requirements**: COLL-01, COLL-02, NATIVE-COLL-01, TROUBLE-01
**Success Criteria** (what must be TRUE):

  1. A required browser route-tour proof runs in CI, uses semantic assertions for correctness, and captures/links evidence for a Phoenix-owned LiveView route, bounded bridge affordance, offline-island queued/replayed state, and native-owned or route-unavailable path.
  2. Evidence bundles include a manifest with Crosswake version, commit SHA, route id, runtime owner, platform, command, proof class, source job, captured-at timestamp, and known limitations; missing expected artifacts fail packaging.
  3. iOS simulator and Android emulator screenshots or recordings are captured where available and labeled advisory with coordinate mode, version, command, route/flow, platform/runtime, and support label.
  4. No native collateral implies physical-device support, camera support, media-upload support, provider authority, or merge-blocking support unless explicit promotion criteria are added and satisfied.
  5. Troubleshooting and rough-edge docs map doctor findings, denials, route-unavailable states, native evidence labels, offline replay/conflict outcomes, and route-owner next actions for adopters.

**Plans**: 4 planned plans (3 waves)
Plans:

**Wave 1**

- [ ] 120-01-PLAN.md — Add deterministic browser route-tour proof, semantic assertions, screenshots, and artifact upload.

**Wave 2** *(blocked on 120-01 artifact shape)*

- [ ] 120-02-PLAN.md — Add artifact manifest schema/validator, bounded committed asset set, retention labels, and proof-class checks.
- [ ] 120-03-PLAN.md — Add advisory iOS simulator and Android emulator capture where available, with coordinate mode and support labels.

**Wave 3** *(blocked on corrected evidence labels and artifact vocabulary)*

- [ ] 120-04-PLAN.md — Add troubleshooting and rough-edge docs for doctor findings, denials, route-unavailable states, offline outcomes, and native evidence caveats.

**UI hint**: yes

## Requirement Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PROOF-01 | Phase 116 | Complete |
| REL-TRUTH-01 | Phase 116 | Complete |
| DRIFT-01 | Phase 116 | Complete |
| GUIDE-01 | Phase 117 | Complete |
| MIGRATE-01 | Phase 117 | Complete |
| TRUTH-01 | Phase 117 | Complete |
| QUICK-01 | Phase 118 | Complete |
| ADOPT-01 | Phase 118 | Complete |
| DRIFT-02 | Phase 118 | Complete |
| NATIVE-01 | Phase 119 | Planned |
| NATIVE-02 | Phase 119 | Planned |
| DRIFT-03 | Phase 119 | Planned |
| COLL-01 | Phase 120 | Planned |
| COLL-02 | Phase 120 | Planned |
| NATIVE-COLL-01 | Phase 120 | Planned |
| TROUBLE-01 | Phase 120 | Planned |

Coverage: 16/16 v13.0 v1 requirements mapped exactly once.

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
| 112. Real Offline Outbox Flush | v12.0 | 2/2 | Complete   | 2026-06-17 |
| 113. Honest E2E Rewrite + Compile Gate | v12.0 | 3/3 | Complete    | 2026-06-18 |
| 114. Merge-Blocking CI Gate + Permanent Honesty Guard | v12.0 | 5/5 | Complete    | 2026-06-18 |
| 115. Closeout-Verifier Honesty + Ledger Backlog + Doc Truth | v12.0 | 3/3 | Complete    | 2026-06-18 |
| 116. Proof Debt And Release Truth | v13.0 | 3/3 | Complete    | 2026-06-18 |
| 117. Route-Policy And Support-Truth Guide Foundation | v13.0 | 3/3 | Complete | 2026-06-19 |
| 118. Runnable Quick Start And Real Adoption Proof | v13.0 | 3/3 | Complete   | 2026-06-19 |
| 119. Native Evidence Classification | v13.0 | 0/3 | Not started | - |
| 120. Collateral, Artifact CI, And Troubleshooting | v13.0 | 0/4 | Not started | - |
