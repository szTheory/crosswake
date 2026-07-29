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
- ✅ **v19.0 Showcase Apps & Capability Map** — Phases 147-152.1 (shipped 2026-07-12)
- 🚧 **v20.0 Native Controls Pack 1** — Phases 153-157 (in progress)

## Phases

**Phase Numbering:**

- Integer phases (153, 154, ...): Planned milestone work
- Decimal phases (153.1, 153.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

### 🚧 v20.0 Native Controls Pack 1 (In Progress)

**Milestone Goal:** Ship the typed control-contract seam that every native-controls pack rides on, and prove it with the one control that genuinely needs to be native — replacing the ad-hoc `<script>` escape hatch adopters use today with a bounded, fail-closed, route-declared affordance.

- [ ] **Phase 153: iOS Mirror Unblock** - Fix the stale iOS SwiftPM shell-core mirror so a native release can reach iOS adopters again.
- [x] **Phase 153.1: CI Gate Integrity & Runner Cost** *(INSERTED)* - Close three gate-integrity holes that let a red check report green, and cut the per-PR CI tax before the milestone's largest phase starts landing PRs.
- [ ] **Phase 154: The Control-Contract Seam** - Ship `Bridge.push/3`, the single typed `Shell.Denial`, the closed-vocabulary structural guard, and migrate haptics onto it as proof.
- [ ] **Phase 155: Host-Owned Fallback Components** - Generate brand-tokenized, host-owned confirm-modal/action-menu fallbacks with route-tour proof that they render and fail closed.
- [ ] **Phase 156: Native Menu & Action-Button Control** - Ship the first genuinely-new native control on both iOS and Android, proven via committed contract vectors.
- [ ] **Phase 157: Harden, Promote & Prove Support Truth** - Harden haptics/share footguns, promote share/notification_token to merge-blocking proof, and land the permissions/notification-token honesty pass.

<details>
<summary>✅ v19.0 Showcase Apps & Capability Map (Phases 147-152.1) — SHIPPED 2026-07-12</summary>

- [x] Phase 147: Arc, Fixture, and Showcase Foundation (5/5 plans) — completed 2026-07-09
- [x] Phase 148: Demo App Brand & Fixture Direction (0/0 plans; retroactive summary exception accepted) — completed 2026-07-09
- [x] Phase 149: SaaS/Admin Showcase (7/7 plans) — completed 2026-07-11
- [x] Phase 150: Field-Service Showcase (7/7 plans) — completed 2026-07-11
- [x] Phase 151: Subscription Learning Showcase (7/7 plans) — completed 2026-07-11
- [x] Phase 152: Capability Map, Collateral, and v20 Handoff (4/4 plans) — completed 2026-07-12
- [x] Phase 152.1: Close gap: v19 support-truth and verification closeout (3/3 plans) — completed 2026-07-12

Full phase detail archived in `.planning/milestones/v19.0-ROADMAP.md`.

</details>

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
<summary>✅ v17.0 Companion Family Completion (Phases 136-141) — SHIPPED 2026-07-04</summary>

- [x] Phase 136: Core Decoupling (6/6 plans) — completed 2026-07-01
- [x] Phase 137: crosswake_sigra Extraction (5/5 plans) — completed 2026-07-04
- [x] Phase 138: crosswake_chimeway Extraction (4/4 plans) — completed 2026-07-04
- [x] Phase 139: crosswake_threadline Extraction (4/4 plans) — completed 2026-07-04
- [x] Phase 140: Family Discipline & Close (5/5 plans) — completed 2026-07-04
- [x] Phase 141: Core-First Publish & Family Release (5/5 plans) — completed 2026-07-04

Full phase detail archived in `.planning/milestones/v17.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v16.0 Companion Extraction & Package-Family Discipline (Phases 129-135) — SHIPPED 2026-06-30</summary>

- [x] Phase 129: Stable Companion Contract Surface (2/2 plans) — completed 2026-06-25
- [x] Phase 130: Extraction Mechanics & Footgun Guards (5/5 plans) — completed 2026-06-26
- [x] Phase 131: Publish Pipeline & Clean-Room Lane (rulestead) (3/3 plans) — completed 2026-06-26
- [x] Phase 132: Generalization Proof (rindle) + Compat Matrix (4/4 plans) — completed 2026-06-26
- [x] Phase 133: Telemetry Public API (4/4 plans) — completed 2026-06-28
- [x] Phase 134: Shell Lifecycle + Native UAT Promotion (5/5 plans) — completed 2026-06-29
- [x] Phase 135: CI-Ops Hardening — Release-As Automation (1/1 plan) — completed 2026-06-28

Full phase detail archived in `.planning/milestones/v16.0-ROADMAP.md`.

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
<summary>✅ v14.0 Runtime Contract Confidence (Phases 121-124) — SHIPPED 2026-06-21</summary>

- [x] Phase 121: Canonical Contract Source (4/4 plans) — completed 2026-06-20
- [x] Phase 122: Drift Guards (3/3 plans) — completed 2026-06-20
- [x] Phase 123: Native Package Behavioral Proof (4/4 plans) — completed 2026-06-20
- [x] Phase 124: Compatibility Semantics & Adopter Truth (6/6 plans) — completed 2026-06-21

Full phase detail archived in `.planning/milestones/v14.0-ROADMAP.md`.

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
<summary>✅ v12.0 CI Honesty & Real-E2E Sweep (Phases 112-115) — SHIPPED 2026-06-18</summary>

- [x] Phase 112: Real Offline Outbox Flush (2/2 plans) — completed 2026-06-17
- [x] Phase 113: Honest E2E Rewrite + Compile Gate (3/3 plans) — completed 2026-06-18
- [x] Phase 114: Merge-Blocking CI Gate + Permanent Honesty Guard (5/5 plans) — completed 2026-06-18
- [x] Phase 115: Closeout-Verifier Honesty + Ledger Backlog + Doc Truth (3/3 plans) — completed 2026-06-18

Full phase detail archived in `.planning/milestones/v12.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v11.0 Release & Distribution Truth (Phases 110-111) — SHIPPED 2026-06-17</summary>

- [x] Phase 110: Native Publish & Lockstep Infrastructure (3/3 plans) — completed 2026-06-14
- [x] Phase 111: Generator Rewire, Clean-Room Proof & Release (5/5 plans) — completed 2026-06-17

Full phase detail archived in `.planning/milestones/v11.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v10.0 Brand Normalization (Phases 107-109) — SHIPPED 2026-06-14</summary>

- [x] Phase 107: Token Source & Distribution (3/3 plans) — completed 2026-06-13
- [x] Phase 108: Consumer Normalization (4/4 plans) — completed 2026-06-14
- [x] Phase 109: Drift-Prevention Gate (3/3 plans) — completed 2026-06-14

Full phase detail archived in `.planning/milestones/v10.0-ROADMAP.md`.

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
<summary>✅ v8.0 Offline Sync Hardening and UI Polish (Phases 99-101) — SHIPPED 2026-06-11</summary>

- [x] Phase 99: Real Network-Toggling E2E Tests (2/2 plans) — completed 2026-06-11
- [x] Phase 100: Storage Budget Enforcement (2/2 plans) — completed 2026-06-11
- [x] Phase 101: Offline UI Consolidation & Polish (2/2 plans) — completed 2026-06-11

Full phase detail archived in `.planning/milestones/v8.0-ROADMAP.md`.

</details>

## Phase Details

### Phase 153: iOS Mirror Unblock

**Goal**: The iOS SwiftPM shell-core mirror can receive `0.2.0`+ releases again, so this milestone's (and every future) native release can actually reach iOS adopters. Native bridge dispatch is a closed switch compiled into the shipped binaries — until the mirror is current, no new capability can ship to iOS at all.
**Depends on**: Nothing (first phase; release-infrastructure prerequisite for the whole milestone)
**Requirements**: MIRROR-01, MIRROR-02
**Success Criteria** (what must be TRUE):

  1. The `crosswake-shell-core-ios` mirror repo carries a `v0.2.0` tag matching the live Hex/Maven `0.2.0` core, confirmed via `mix crosswake.release.status --live`.
  2. A single native shell-core release run publishes Hex, Maven, and the iOS mirror together in one coordinated pass.
  3. A missing or invalid mirror push credential (`MIRROR_DEPLOY_KEY`) fails CI with a hard, named error instead of a silent 403.

**Plans**: 2/4 plans executed

Plans:
**Wave 1**

- [x] 153-01-PLAN.md — Backfill lane: SSH deploy-key transport, `apply=false` write-scope fire drill, atomic explicit-lease push (defuses the `actions/checkout` credential hijack)

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 153-02-PLAN.md — Human-gated: mint the deploy key, fire-drill CI's push credential, backfill `v0.2.0`, re-baseline mirror `main` (MIRROR-01)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 153-03-PLAN.md — Release job: tag-pinned checkout, Hex-only gate, atomic leased push, native failure alerting, rollup fails closed

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 153-04-PLAN.md — Durable guards: merge-blocking mirror parity gate + honest `release.status --live` (`:missing` vs `:unavailable`)

### Phase 153.1: CI Gate Integrity & Runner Cost *(INSERTED)*

**Goal**: The merge gate cannot report green while something is red, and the CI tax paid per-PR is
cut before Phase 154 — the milestone's largest phase — starts landing PRs against it. Three required
check *names* are each emitted by two workflows, and branch protection matches by string, so a red
run can be masked by a green one; 20 test files are excluded by every CI lane and by no local
default, so they run only on laptops (this is how a genuinely red gate sat on `main` unnoticed until
found by hand, fixed in #89). Separately, CI spends ~25,500 runner-seconds (~7 h) per push to run an
88-second suite, and the spend is mostly macOS *queue* time for jobs that never invoke an Apple
toolchain.
**Depends on**: Nothing functionally — this is infrastructure and shares no code with Phase 153.
Sequenced after it only because seven in-flight PRs are validating against the workflow files this
phase rewrites. It is **not** blocked on the human-gated `v0.2.0` mirror tag push (153-02).
**Requirements**: GATE-01, GATE-02, GATE-03, RUNNER-01, RUNNER-02, CACHE-01, CACHE-02
**Success Criteria** (what must be TRUE):

  1. No two workflow jobs emit the same `merge-blocking` check name, and `check_required_checks_registered.sh` fails if that ever stops being true — asserting uniqueness, not just presence.
  2. The 20 `:requires_example_host` test files run on a named CI lane, and `mix test` locally excludes the same tag set CI does, so local and CI agree on what "the suite passed" means.
  3. Every job on `macos-*` is there because it demonstrably invokes an Apple toolchain, justified per job by following each `run:` into the scripts it calls — never by grepping the workflow file.
  4. Every workflow declares `timeout-minutes`, so a hang cannot hold a scarce macOS runner for the 6-hour default while other jobs queue behind it.
  5. Elixir lanes restore `deps/` and `_build` from caches keyed on `os|arch|otp|elixir|MIX_ENV|hash(mix.lock)`, and a structural test rejects any key missing a dimension.
  6. Before/after runner-seconds are measured with re-derivable commands and reported honestly, including what remains attributable to the out-of-scope `CONSOL-*` work.
  7. **Wall-clock time-to-green for a single push is measured before and after, and is the headline number.** Measured baseline 2026-07-28: **34.9 minutes across 41 workflow runs** for the final commit of docs-only PR #90. Runner-seconds is a billing metric; wall-clock is the one a human waits through, and the two move independently — parallel lanes cut latency without cutting spend, and queue time costs latency while billing nothing. Target for this phase: **under 15 minutes**, achieved by removing macOS queue time rather than by removing proofs.

**Scope note**: A deliberately narrow slice of SEED-007. `CONSOL-*` (39 workflow files → ~4, change
detection, required-context topology), the merge-queue decision, `FLAKE-*`, and `DX-*` stay planted.
Test sharding is an explicit **non-goal** — 1,093 tests at ~12 ms each means per-shard setup exceeds
the execution saved.

**Plans**: 3/3 plans executed

Plans:
**Wave 1**

- [x] 153.1-01-PLAN.md — GATE: de-duplicate the three colliding check names, assert uniqueness, give `:requires_example_host` a real lane, correct the stale audit header (GATE-01..03)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 153.1-02-PLAN.md — RUNNER: per-job Apple-toolchain audit, move non-Apple jobs to ubuntu, `timeout-minutes` everywhere, structural guard (RUNNER-01, RUNNER-02)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 153.1-03-PLAN.md — CACHE: repair the dead/unsafe caches, one composite setup action, correct key dimensions, measured hit rate (CACHE-01, CACHE-02)

*Waves are serial by necessity: all three plans edit `.github/workflows/`, so parallel execution
would conflict and, under `strict: true`, re-invalidate each other's in-flight runs.*

### Phase 154: The Control-Contract Seam

**Goal**: A LiveView can invoke a bounded native control through one typed seam and get a correlated reply; every shell-absent/old-shell/undeclared failure mode collapses into one denial; the command vocabulary is structurally closed against drift; and the already-shipped haptics capability proves the seam end-to-end with zero native-side risk.
**Depends on**: Phase 153 (native releases must be able to reach iOS before any control machinery is built against the release pipeline)
**Requirements**: CTRL-01, CTRL-02, CTRL-03, CTRL-04, CTRL-05, PROOF-04, HRDN-01
**Success Criteria** (what must be TRUE):

  1. A LiveView can call `Crosswake.Bridge.push/3` for a declared capability and receive a correlated typed reply.
  2. No-shell, too-old-shell, and undeclared-capability all produce the identical `Crosswake.Shell.Denial` shape, so an adopter writes one `handle_event` branch, not three.
  3. Invoking a capability that was never declared in route policy fails loudly and names the missing declaration, instead of silently doing nothing.
  4. A proposed control that is host-registrable, dynamic, or otherwise violates the catalog line fails a merge-blocking structural CI test, and every control's rebuild class is visible in the changelog, support matrix, and doctor guidance.
  5. The AdminPilot haptics call runs through `Bridge.push/3` with the old hand-rolled `<script>` IIFE deleted, proving the seam against an already-native, zero-risk capability.

**Plans**: TBD

### Phase 155: Host-Owned Fallback Components

**Goal**: Adopters get generated, brand-tokenized fallback UI for bounded controls that they own outright — never an importable component tier — and CI proves those fallbacks actually render and fail closed rather than silently degrading.
**Depends on**: Phase 154 (the seam and its degradation/denial contract must exist before fallback UI can be proven against it)
**Requirements**: FALL-01, FALL-02, PROOF-01
**Success Criteria** (what must be TRUE):

  1. Running `mix crosswake.gen.native_controls_ui` copies confirm-modal and action-menu fallback files directly into the host app as files the adopter owns and can edit — no importable `Crosswake.UI.*` module exists.
  2. The generated fallbacks render correctly in both light and dark themes, trap focus, and meet the existing contrast gates.
  3. A merge-blocking browser route-tour test proves a fallback renders when a control is unavailable, fails closed (an explicit denial, not silent success) when a capability is undeclared, and never silently degrades.

**Plans**: TBD
**UI hint**: yes

### Phase 156: Native Menu & Action-Button Control

**Goal**: A route can declare a native menu/action-button affordance and get a real native menu with a typed reply on both iOS and Android — the first genuinely-new control, proving the whole seam end-to-end — provable without a simulator or emulator.
**Depends on**: Phase 153 (native release must reach iOS), Phase 154 (the seam), Phase 155 (the fallback path menu degrades into when undeclared)
**Requirements**: MENU-01, MENU-02, MENU-03, PROOF-03
**Success Criteria** (what must be TRUE):

  1. A route author can declare menu/action-button affordances — allowed actions and fallback behavior — in route policy.
  2. On both iOS and Android, invoking the control renders a real native menu, and the user's chosen action returns as a typed reply through the seam.
  3. The native menu carries VoiceOver/TalkBack semantics and responds to native dismiss gestures.
  4. Committed `bridge_contract_vectors.json` vectors prove menu dispatch and denial behavior on both native platforms in CI, with no simulator or emulator required.

**Plans**: TBD
**UI hint**: yes

### Phase 157: Harden, Promote & Prove Support Truth

**Goal**: Haptics and share are hardened against their known footguns, `share` and `notification_token` earn merge-blocking proof instead of advisory, and the read-only surfaces (`permissions.status`, `notification_token`) are documented so neither can ever be mistaken for request authority or delivery assurance.
**Depends on**: Phase 154 (the seam these capabilities run through)
**Requirements**: HRDN-02, HRDN-03, EVID-01, EVID-02, PROOF-02
**Success Criteria** (what must be TRUE):

  1. Haptics silently respects the OS reduce-motion/haptics accessibility setting instead of firing regardless of it.
  2. Triggering share on an iPad without a valid popover anchor degrades safely instead of crashing.
  3. `share` and `notification_token` both carry merge-blocking (not advisory) CI proof.
  4. Reading the `permissions.status` and `notification_token` docs and support-matrix rows, a developer cannot conclude that Crosswake grants permission-request authority or delivery assurance.

**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 153 → 154 → 155 → 156 → 157

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 147. Arc, Fixture, and Showcase Foundation | v19.0 | 5/5 | Complete | 2026-07-09 |
| 148. Demo App Brand & Fixture Direction | v19.0 | 0/0 | Complete | 2026-07-09 |
| 149. SaaS/Admin Showcase | v19.0 | 7/7 | Complete | 2026-07-11 |
| 150. Field-Service Showcase | v19.0 | 7/7 | Complete | 2026-07-11 |
| 151. Subscription Learning Showcase | v19.0 | 7/7 | Complete | 2026-07-11 |
| 152. Capability Map, Collateral, and v20 Handoff | v19.0 | 4/4 | Complete | 2026-07-12 |
| 152.1. Close gap: v19 support-truth and verification closeout | v19.0 | 3/3 | Complete | 2026-07-12 |
| 153. iOS Mirror Unblock | v20.0 | 3/4 | In Progress| 153-02 human-gated (one-way-door v0.2.0 mirror tag push) |
| 153.1 CI Gate Integrity & Runner Cost *(INSERTED)* | v20.0 | 3/3 | Complete | 34.9 -> 5.8 min time-to-green; see 153.1-RESULTS.md |
| 154. The Control-Contract Seam | v20.0 | 0/TBD | Not started | - |
| 155. Host-Owned Fallback Components | v20.0 | 0/TBD | Not started | - |
| 156. Native Menu & Action-Button Control | v20.0 | 0/TBD | Not started | - |
| 157. Harden, Promote & Prove Support Truth | v20.0 | 0/TBD | Not started | - |

---

For older detailed phase history, see `.planning/milestones/`.
