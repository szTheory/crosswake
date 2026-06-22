# Roadmap: Crosswake

## Milestones

- ✅ **v8.0 Offline Sync Hardening and UI Polish** — Phases 99-101 (shipped 2026-06-11)
- ✅ **v9.0 Brand System & Visual Identity** — Phases 102-106 (shipped 2026-06-13)
- ✅ **v10.0 Brand Normalization** — Phases 107-109 (shipped 2026-06-14)
- ✅ **v11.0 Release & Distribution Truth** — Phases 110-111 (shipped 2026-06-17)
- ✅ **v12.0 CI Honesty & Real-E2E Sweep** — Phases 112-115 (shipped 2026-06-18)
- ✅ **v13.0 Adopter Confidence & Native Evidence** — Phases 116-120 (shipped 2026-06-19)
- ✅ **v14.0 Runtime Contract Confidence** — Phases 121-124 (shipped 2026-06-21)
- 🔄 **v15.0 See It Run — Experiential First-Run DX** — Phases 125-128 (in progress)

## Phases

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

### v15.0 See It Run — Experiential First-Run DX (Phases 125-128)

- [x] **Phase 125: Containerized Shared Backend + Port Convention** - Docker Compose one-command backend with cached deps, polling live-reload, named-volume SQLite, lean .dockerignore, and committed port 4700 convention (completed 2026-06-21)
- [x] **Phase 126: Additive Native Dev Wiring** - iOS Dev scheme + Android dev flavor pointing at the local backend without touching the checked-in proof fixtures or assets (completed 2026-06-22)
- [ ] **Phase 127: Launch Orchestration + Banner** - bin/see-it-run.sh entrypoint that boots the backend, prints a brand-voiced ASCII banner with honest proof/needs-build block, and advisorily boots sim/emulator
- [ ] **Phase 128: Collateral + "See It Run" Guide** - Committed three-runtime screenshots + screen recording, guides/see_it_run.md, README/QUICK_START routing, and doc-contract tests

## Phase Details

### Phase 125: Containerized Shared Backend + Port Convention

**Goal**: A developer can boot the shared Crosswake demo backend with one command and reach it reliably from all three runtimes, with no port collisions and fast iteration loops
**Depends on**: Nothing (first phase of v15.0)
**Requirements**: DOCKER-01, DOCKER-02, DOCKER-03, DOCKER-04, DOCKER-05, PORT-01, PORT-02, PORT-03
**Success Criteria** (what must be TRUE):

  1. Running `docker compose up` from a clean checkout (no local Elixir/Node/SQLite) boots the demo backend and serves the app at `http://localhost:4700`
  2. Editing application code or styles in the bind-mounted source triggers a live-reload in the container without re-downloading or re-recompiling deps (only dep-layer changes trigger dep rebuild)
  3. The SQLite database persists across container restarts (named volume, not a macOS bind-mount) and is auto-seeded on first boot; `mix phx.server` on port 4700 works as a documented alternative
  4. The Docker build context is lean: a `.dockerignore` excludes `_build`, `deps`, `node_modules`, `priv/static`, `.git`, `.planning`, `.claude`, and evidence artifacts
  5. A committed `examples/phoenix_host/.env` (with `COMPOSE_PROJECT_NAME=crosswake` and `PORT=4700`) and `docs/PORT-REGISTRY.md` mean the port never collides with other concurrently running OSS lib demos, and Android emulator can reach the backend at `10.0.2.2:4700`

**Plans**: 3/3 plans complete

- [x] 125-01-PLAN.md — Config split (config/dev/runtime), 4002→4700 port migration, live_reload dep + endpoint plugs, committed .env, drift-test redirect (Wave 1)
- [x] 125-02-PLAN.md — Multi-stage Dockerfile + idempotent entrypoint, lean .dockerignore, docker-compose with named volumes + 4700 mapping (Wave 2)
- [x] 125-03-PLAN.md — docs/PORT-REGISTRY.md + source-derived drift test + QUICK_START 4700 migration & Docker path (Wave 2)

**UI hint**: yes

### Phase 126: Additive Native Dev Wiring

**Goal**: iOS and Android native hosts can load Crosswake routes from the local shared backend without any modification to the checked-in public-coordinate proof fixtures or assets
**Depends on**: Phase 125
**Requirements**: NDEV-01, NDEV-02, NDEV-03
**Success Criteria** (what must be TRUE):

  1. An iOS developer can select the `Dev` scheme in Xcode and run the simulator against `http://localhost:4700`; the `Info-Dev.plist` permits cleartext ATS for localhost; the checked-in `Info.plist` and proof fixture files are untouched
  2. An Android developer can run the `dev` flavor Gradle build and the emulator reaches `http://10.0.2.2:4700`; the network-security config permitting cleartext for `10.0.2.2` is additive; the checked-in prod proof assets are untouched
  3. The repo README or NDEV docs surface exact CLI commands (`xcodebuild -scheme Dev`, `./gradlew installDev`, etc.) a newcomer can copy-paste to launch each native runtime against the local backend

**Plans**: 4/4 plans complete

- [x] 126-01-PLAN.md — Extend `mix crosswake.contract.gen --dev` + commit the two dev fixtures + dev-drift guard (D-11/12/13)
- [x] 126-02-PLAN.md — iOS additive Dev scheme: `Debug-Dev` config + `Info-Dev.plist` + Run Script copy phase + `Dev.xcscheme` (D-01..D-05)
- [x] 126-03-PLAN.md — Android additive `dev` flavor + dev source-set overlay + 10.0.2.2 cleartext config + D-10 lockstep migration (D-06..D-10)
- [x] 126-04-PLAN.md — D-14 proof-posture guard test + D-15 additive QUICK_START dev-wiring section + D-16 honest voice (NDEV-03)

### Phase 127: Launch Orchestration + Banner

**Goal**: A newcomer can run one command that boots the shared backend, reads a human-voiced banner telling them exactly what is running and what to do next, and optionally watches their sim/emulator launch automatically
**Depends on**: Phase 125
**Requirements**: LAUNCH-01, LAUNCH-02
**Success Criteria** (what must be TRUE):

  1. Running `bin/see-it-run.sh` (or `mix crosswake.demo`) from the repo root boots the Docker backend (or uses the already-running container) and prints a plain-ASCII brand-voiced banner listing the served URL, key routes, and the exact next command for each runtime (web, iOS sim, Android emulator)
  2. The banner includes an honest "What's proven / What needs a native build" block — a first-run reader can tell immediately what runs deterministically vs. what requires Xcode/SDK setup
  3. When the iOS/Android toolchain is present, the script advisorily launches the simulator/emulator; when the toolchain is absent, it prints a clear and calm guidance message (not an opaque stack trace or silent skip)

**Plans**: TBD

### Phase 128: Collateral + "See It Run" Guide

**Goal**: A prospective adopter can see all three runtimes running against one shared backend in committed screenshots and a screen recording, and can follow a reader-empathy guide from README through Docker boot to first native comparison
**Depends on**: Phase 125, Phase 126, Phase 127
**Requirements**: COLL-01, COLL-02, DOCS-01, DOCS-02, DOCS-03
**Success Criteria** (what must be TRUE):

  1. The repo contains committed screenshots of the web, iOS simulator, and Android emulator views running against the shared backend — each file is honestly labeled as advisory native evidence (simulator/emulator, not device)
  2. A short screen recording of the three-runtime comparison is captured, committed or linked from the docs, and referenced in the README so a reader landing on the repo can immediately see the DX in action
  3. A new `guides/see_it_run.md` exists with a gameplan summary at the top, JTBD-driven sections, and links to (not duplicates of) `examples/QUICK_START.md`; it is listed in the ExDoc "Start" group after README
  4. README and `examples/QUICK_START.md` both route readers to `guides/see_it_run.md` and the one-command Docker path without overclaiming native support (support labels are honest)
  5. Guide truth (ports, routes, exact commands) is guarded by at least one `test/crosswake/guides/see_it_run_test.exs` doc-contract test derived from source, consistent with the existing guide-test culture

**Plans**: TBD
**UI hint**: yes

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
| 125. Containerized Shared Backend + Port Convention | v15.0 | 3/3 | Complete    | 2026-06-21 |
| 126. Additive Native Dev Wiring | v15.0 | 4/4 | Complete    | 2026-06-22 |
| 127. Launch Orchestration + Banner | v15.0 | 0/TBD | Not started | - |
| 128. Collateral + "See It Run" Guide | v15.0 | 0/TBD | Not started | - |
