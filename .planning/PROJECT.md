# Crosswake

## What This Is

Crosswake is a Phoenix-native open-source library for shipping iOS and Android apps from Phoenix applications without pretending one runtime should own every screen. It lets Phoenix teams declare per-route runtime ownership so server-centric screens can stay LiveView, local-first workflows can live in offline islands, and device-heavy flows can move into disciplined native screens or adapters.

## Core Value

Get one real Phoenix application onto one physical iPhone with explicit per-route ownership, one
honest offline mutation island, bounded native affordances, and enough self-service proof to keep a
team of one out of framework-debugging purgatory.

## Verification Posture

Default GSD verification to zero-human, shift-left evidence. Automate unit, integration, end-to-end,
smoke, seam, artifact, and device checks whenever the environment can run them; record executable
results in phase UAT/verification artifacts instead of handing reproducible checks to the operator.
When every deliverable has passing automated coverage, record the UAT result as passed without a
confirmatory human checkpoint. Present only behavior that remains genuinely unautomatable.
Promote a check into CI only when it protects a recurring contract and gives stable, actionable
feedback. Reserve human verification for judgment automation cannot make, unavoidable credentials,
external approvals, or physical setup; automate the assertions and evidence evaluation around those
exceptions.

Complete local automation, evidence checks, and setup preparation before handing work back. Make
unavoidable human work a precise last-mile action with a prefilled form or command and a secure
credential path; never ask for secrets in chat. Remove unnecessary credential dependencies when a
scoped anonymous path is supported. At each GSD handoff, use the active workstream's STATE.md and
ROADMAP.md for the exact next command. Do not repeat a completed discuss, plan, execute, or verify
stage. A consumed one-time attempt ends there; any new attempt requires a fresh plan and
authorization, recorded with its terminal outcome so the workflow does not loop.

## Last Completed Milestone: v27.0 Land and Clean Up (shipped 2026-10-24)

All 18 requirements (INV, FIX, LAND, CLEAN) are satisfied across five verified phases (189–193) and 55 plans. Every copy of the work outside GitHub `main` was inventoried by content and backed up with passing restore tests. The seven carried v26 warnings were fixed. One integration branch from current `main` carried the v25/v26 candidate commits, the FIX commits and the v24–v27 planning records, and it merged through PR #242 (`d12aed75`) with CI green after the user's `allow`. Phase 193 retired the recovery checkout for a clean `main` checkout, removed 300 of 306 listed local copies after hash-matched backups (6 kept with reasons), and replaced the freeze rules with AGENTS.md "How changes land".

The audit is `tech_debt` with no blocker. The v25/v26 product code is now on `main`. Simulator proof still does not promote a physical-iPhone or adopter claim. Release PR #236 is on hold and nothing was published. See the [closeout](workstreams/quality-ratchet-release/milestones/v27.0-closeout/CLOSEOUT.md) and [debt disposition](workstreams/quality-ratchet-release/milestones/v27.0-closeout/debt-disposition.md). No tag or release.

## Earlier Completed Milestone: v26.0 Harden Before Trust (planning closeout 2026-10-16)

All 18 requirements (PROBE, GUARD, SEAM-07..09, LOOP-06..07, DOCTOR, TWIN-07..08) are satisfied across five verified phases (184–188) and 37 plans. v26 removed the v25 checks that could pass while checking nothing: the twin's clean-tree probe now goes through one pinned git funnel that index flags and config cannot fool, a read-only `twin_preflight` answers whether a run would be allowed without using up a run root, empty scopes fail, the legacy host-command path denies, doctor reports real details and redacted paths, and proof evidence carries real provenance. All changes were frozen at candidate `a53fbef`, and twin-05 ran exactly once and passed (10/10 groups, 7/7 identity joins).

The audit is `tech_debt` with no blocker. Product code exists only in the candidate `/private/tmp/crosswake-phase180-impl`; delivery needs separate authorization. Simulator proof does not promote a physical-iPhone or adopter claim. Several review warnings in the run tooling and probes should be fixed before the next twin run; 186 WR-01 (the LOOP-07 loopback residual) needs an owner decision. See the [closeout](workstreams/quality-ratchet-release/milestones/v26.0-closeout/CLOSEOUT.md) and [debt disposition](workstreams/quality-ratchet-release/milestones/v26.0-closeout/debt-disposition.md). No commit, tag or release.

## Earlier Completed Milestone: v25.0 iOS Host Setup & Digital Twin Proof (planning closeout 2026-10-15)

All 20 requirements (IOS, SEAM, LOOP, TWIN) are satisfied across five verified phases (179–183) and 32 plans. A compile-only `:ios_host` declaration generates the iOS host without hand patches; routes declare versioned `host.*` commands that the manifest (schema 1.2.0) carries to the native session and the bounded-shell offline island; an explicit local mode allows an http loopback origin while production stays HTTPS-only; and `mix crosswake.proof_lane.verify_twin ios` runs the bounded T01–T10 reference twin into a privacy-safe receipt. Run twin-04 passed 49/49 against the committed fix `50fcd57`, and the twin now refuses an uncommitted candidate (`source_dirty`).

The re-audit is `tech_debt` with no blocker. Product code exists only in the candidate `/private/tmp/crosswake-phase180-impl`; delivery needs separate authorization. Simulator proof does not promote a physical-iPhone or adopter claim. Two review warnings can let a future twin run pass on a hidden change (git index flags; unpinned `core.filemode`) and belong in the next twin-touching change. See the [closeout](workstreams/quality-ratchet-release/milestones/v25.0-closeout/CLOSEOUT.md) and [debt disposition](workstreams/quality-ratchet-release/milestones/v25.0-closeout/debt-disposition.md). No commit, tag or release.

## Earlier Completed Milestone: v24.0 Repository Cleanup & Maintenance (planning closeout 2026-10-12)

All eight maintenance requirements are validated across three verified phases (176–178), fifteen plans and twenty-eight CLI-counted tasks. Captured work is recoverable; supported maintenance paths and instructions are verified; the audit queue accounts for 20 issues and 4 PRs. Local nine-stage proof and 48 required hosted checks bind to governed merge `f2d8875ee52d9679157c73b4a701b510ee612cb8`. PR #238 remains open and unmerged.

Planning archives are complete with [six retained debt records](workstreams/quality-ratchet-release/milestones/v24.0-closeout/debt-disposition.md). All 1,677 protected historical files remain at their original paths. Six v23 acknowledgements carry forward; no new acknowledgement or phase override. No v24 commit/tag or package release is selected. See [milestone record](workstreams/quality-ratchet-release/MILESTONES.md).

## Earlier Shipped Milestone: v23.0 Release Pipeline Repair & Proof-Lane Truth (archived 2026-10-11)

Archived as `override_closeout`: 42/43 requirements satisfied; Phase 175 retains 8/9 because the first publish omitted the incident-response runbook (REL-10 / SC-1). Later successful releases do not repair that historical timing.

Crosswake 0.2.11 passed ordinary three-registry publication, generated iOS/Android consumer builds, exact-public proof and the six-child COMPLETE rollup. Chimeway 0.1.2 passed its separate guarded publication and public-host doctor. PR #237 passed all 49 CI jobs and ten real installer-before-doctor pairs. These close the forward release/proof defects recorded at v22 close; the old 0.2.1 proof gap remains historical.

Seven phases (169–175), 163 active plans / 193 tasks in the CLI inventory; historical superseded and stopped plans are retained. Six open artifact records were acknowledged without changing their verdicts; originals are preserved. Six accepted historical high limitations and twelve open lower findings remain, with zero current blocking high findings. Nyquist coverage is partial.

Archive: `.planning/workstreams/quality-ratchet-release/milestones/v23.0-ROADMAP.md`, `v23.0-REQUIREMENTS.md`, `v23.0-MILESTONE-AUDIT.md` and `v23.0-phases/`.

## Current Milestone Goals

v28.0 Truth and Release Train (phases 194–199, started 2026-10-24): land the bearings and ADR amendments, make `main` and the release pipeline trustworthy, harden the sensitive specs, correct the public docs, prove Android from a foreign host, and cut one real release behind per-publish `allow`. Carried v27 debt is in the [debt disposition](workstreams/quality-ratchet-release/milestones/v27.0-closeout/debt-disposition.md).

**Archive:** `.planning/milestones/v19.0-ROADMAP.md`, `.planning/milestones/v19.0-REQUIREMENTS.md`, and `.planning/milestones/v19.0-MILESTONE-AUDIT.md`.

## Active Workstreams

### v28.0 Truth and Release Train (active)

Workstream: Quality Ratchet & Release. Phases 194–199; 30 requirements. [Roadmap](workstreams/quality-ratchet-release/ROADMAP.md), [requirements](workstreams/quality-ratchet-release/REQUIREMENTS.md), [scope](workstreams/quality-ratchet-release/v28.0-SCOPE.md).

### v27.0 Land and Clean Up (Phases 189–193) — shipped 2026-10-24

Workstream: Quality Ratchet & Release.

**Last goal (v27.0, closed 2026-10-24):** Land the v25 and v26 work on GitHub `main` with CI green, then clean up the local repository so no copy of the work can be lost.

**Current stage:** Last completed phase 193; v27.0 archived; no milestone active. Changes land through PRs branched from `main` (AGENTS.md "How changes land"). Next: `$gsd-new-milestone --ws quality-ratchet-release`. See [STATE](workstreams/quality-ratchet-release/STATE.md).

**Planning:** `.planning/workstreams/quality-ratchet-release/` — [v27.0 archive](workstreams/quality-ratchet-release/milestones/v27.0-ROADMAP.md), [requirements archive](workstreams/quality-ratchet-release/milestones/v27.0-REQUIREMENTS.md), and [roadmap](workstreams/quality-ratchet-release/ROADMAP.md).

### v23.0 Release Pipeline Repair & Proof-Lane Truth (archived with exceptions)

**Goal:** Repair the release pipeline's three derived-fact regressions and make every proof lane
report a fact about the thing it names — no check stays green while asserting nothing.

**Thesis:** All three defects share one root habit: *a fact that should have been derived got
hardcoded, and nothing was built to catch it drifting.* Every requirement generalizes an existing
mechanism; none loosens what it proves.

**Planning:** `.planning/workstreams/quality-ratchet-release/` (phases 169-175)

### v22.0 Quality Ratchet & Release Readiness (shipped)

**Goal:** Make Crosswake safe to change, inexpensive to verify, pleasant to review, and ready for
an exact approval-gated 0.2.1 release candidate without reopening product or mobile breadth.

**Shipped:** 2026-09-15 as `override_closeout`. See the milestone section above for what it did
and did not establish.

**Planning:** `.planning/workstreams/quality-ratchet-release/`
**Archive:** `.planning/workstreams/quality-ratchet-release/milestones/v22.0-ROADMAP.md` and
`v22.0-REQUIREMENTS.md` (workstream-scoped, not the root `.planning/milestones/`).

### v21.0 First B2C Adopter Readiness (parked)

**Goal:** Prove one real Phoenix application's offline study flow on one physical iPhone without
widening Crosswake into a generic sync, storage, native-control, or multi-platform framework.

**Target features:**

- A one-day adopter route inventory with explicit runtime owners, auth posture, offline semantics,
  fallbacks, media requirements, and server-side disablement.
- A host-reusable proof-lane generator that preserves existing browser tests and adds the three
  device flows browser automation cannot cover.
- Privacy-safe scoped replay that prevents cross-account leakage and excludes raw mutation payloads
  from diagnostics and evidence.
- A host-supplied foreground iOS pack adapter that installs one real pronunciation archive only
  after size/hash verification and atomic placement.
- A bounded first-adopter iOS navigation shell with native root tabs, pushed-detail/back behavior,
  typed stack synchronization, live safe-area values, and a declarative document-root marker.
- A dated, redacted physical-iPhone proof of offline answers, offline audio, kill/relaunch
  persistence, exactly-once replay, conflict recovery, account isolation, and remote disablement.

**Key context:** Crosswake is infrastructure for the **First B2C Adopter**, not a separate business
line. A web-only customer Alpha has no Crosswake deliverable; mobile work serves public v1.
Native-menu breadth, new companion packages, brand/showcase polish, and generic
sync/storage productization are frozen; Android is unfrozen only for proof and parity of
existing contracts (ADR amendment A1). Reversal requires two independent active adopters or a
separately funded business-line mandate. Durable reasoning is in
`.planning/ADR-FIRST-B2C-ADOPTER.md`; the complete retrieval-oriented game plan is in
`.planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md`.

## Current State
- **v27.0 — SHIPPED WITH TECH DEBT 2026-10-24.** 18/18 requirements across Phases 189–193; the v25/v26 work merged to `main` via PR #242 (`d12aed75`) with CI green; recovery checkout retired, clean `main` checkout in place, branch-and-PR working rules in AGENTS.md. No release, tag or physical/adopter promotion.
- **v26.0 — PLANNING CLOSEOUT COMPLETE WITH TECH DEBT 2026-10-16.** 18/18 requirements across Phases 184–188; twin-05 passed (10/10 groups, 7/7 joins) against frozen candidate `a53fbef`. Product code is candidate-only pending authorized delivery; recovery source/index unchanged; no release or physical/adopter promotion.
- **v25.0 — PLANNING CLOSEOUT COMPLETE WITH TECH DEBT 2026-10-15.** 20/20 requirements across Phases 179–183; twin-04 passed 49/49 against committed fix `50fcd57`. Product code is candidate-only pending authorized delivery; recovery source/index unchanged; no release or physical/adopter promotion.
- **v24.0 — PLANNING CLOSEOUT COMPLETE WITH RETAINED DEBT 2026-10-12.** All eight requirements and three phases verified; archives copied, historical paths preserved, six debt records retained. PR #238 remains open/unmerged. The v25 scoped roadmap owns current work; no package release or adopter promotion.
- **v23.0 — ARCHIVED WITH EXCEPTIONS 2026-10-11.** Crosswake 0.2.11 and Chimeway 0.1.2 are published and verified; installer repair #237 is merged. Phase 175 retains its first-publish ancestry breach at 8/9, and REL-10 remains unchecked.
- **v22.0 Quality Ratchet & Release Readiness — PHASE 167 COMPLETE 2026-09-12.** Dependency
  security, authoritative and efficient CI, deterministic clean-checkout repository proof,
  documentation truth, parked-lane isolation, and explicit pull-request dispositions are verified.
  Phase 168 now owns the exact, approval-gated 0.2.1 release candidate.
- **v21.0 Adopter Readiness — PARKED AT PHASE 163.1 2026-08-28.** Plans 163.1-08 through
  163.1-10 remain blocked on the validated private adopter handoff and source-bound physical-device
  authority. The completed substrate and exact resume context live in
  `.planning/workstreams/first-b2c-adopter-readiness/`; no adopter facts are inferred.
- **v21.0 Phase 163 First B2C Adopter Reference Host Integration — COMPLETE 2026-08-27.** The
  generated Phoenix/iOS host, exact foreground learning bundle, scoped replay authority, and
  physical report/evidence producers are verified against the current tree.
- **v21.0 Phase 162 Physical-iPhone Adoption Proof — COMPLETE 2026-08-27.** The retained physical
  record and corrected provenance topology independently verify the bounded offline study flow,
  offline pronunciation media, replay, recovery, account isolation, and remote disablement.
- **v21.0 Phase 161 iOS Pronunciation Pack Seam — COMPLETE 2026-08-04.** Gap closure repaired and
  re-verified crash recovery, atomic replacement, retained-byte rollback, and foreground provider
  authority without widening into generic native storage.
- **v21.0 Phase 161.1 First-Adopter iOS Navigation Shell — INSERTED/URGENT 2026-08-03.** SEED-006
  is triggered for a bounded iOS slice: native root tabs, pushed details and edge-swipe back,
  typed patch/navigate synchronization, live safe-area and separate keyboard values, a synchronous
  shell marker, and automated proof. Android implementation and parity remain frozen.
- **v21.0 Phase 161.1 First-Adopter iOS Navigation Shell — COMPLETE 2026-08-04.** The bounded
  iOS root-tab/detail shell, typed stack synchronization, safe-area and shell-marker seams, and
  provenance-backed advisory simulator proof are verified. TODO-002 remains `unknown_blocking`;
  Phoenix confirmation remains required; Android remains frozen; Phase 162 alone owns
  physical-iPhone promotion.
- **v21.0 Phase 160 Scoped Replay and Auth Safety — COMPLETE 2026-08-02.** Opaque scoped replay,
  scope-partitioned browser storage, account-switch fencing, request-bound backend authority,
  scope-safe idempotency, and privacy-safe operational evidence are verified 39/39 by a fresh
  automated gate. The pre-repair security report must be rerun before Phase 161 advances; code
  review WR-01 remains a non-blocking browser lifecycle finding.
- **v21.0 Phase 159 Host-Reusable Proof Lane — COMPLETE 2026-08-02.** The configurable,
  missing-only Phoenix proof-lane generator, additive generated browser proof, explicit non-passing
  iOS host-adapter boundary, and privacy-safe descriptor-pinned retained evidence are verified.
  Phase 160 scoped replay and auth safety followed; TODO-002 and adopter-instance completeness remain
  `unknown_blocking`.
- **v21.0 Phase 158 Adoption Reset and Route Map — COMPLETE 2026-07-31.** GET-6, the Alpha/public-v1
  split, stopped-v20 truth, route-local ownership contract, repository-wide privacy scanning, and
  automated verification posture are durable and verified. TODO-002 remains the fail-closed
  sanitized adopter-input gate.
- **v20.0 Native Controls Pack 1 — STOPPED/PARTIAL 2026-07-30.** Phases 153-155 delivered useful
  release, CI, bridge, and fallback substrate. Phases 156-157 are dropped from active scope because
  native menu breadth does not unblock the first adopter. No v20.0 shipped claim or completion tag.
- **v20.0 Phase 153 iOS Mirror Unblock — COMPLETE 2026-07-30.** The SwiftPM mirror now carries `v0.2.0` at the reproducible split SHA while preserving `v0.1.2`; mirror `main` is re-baselined; the release and backfill lanes use the deploy-key path with hard failure surfacing; and the live parity gate is registered as required. MIRROR-01 and MIRROR-02 verified 31/31. This substrate carries into v21.
- **v19.0 Showcase Apps & Capability Map — SHIPPED 2026-07-12.** Crosswake now has a product-shaped showcase hub and three realistic lanes: AdminPilot (SaaS/admin), Fieldserv (field service), and LearnLoop (subscription learning/training). The milestone also shipped deterministic fixture reset/proof, generalized route-tour evidence, public capability-map collateral, and a planning-only v20 Native Controls Pack 1 handoff. Full detail in `.planning/milestones/v19.0-ROADMAP.md`.
- **v19.0 Phase 152.1 Support-Truth and Verification Closeout — COMPLETE 2026-07-12.** Scanner/document-scan support truth now renders unsupported/deferred across canonical source, generated guides, and tests; Phase 150 and 152 verification ledgers were reconstructed from fresh reruns; Phase 149/150/151 validation metadata is current; Phase 148's missing-summary exception is documented honestly; and the v19 milestone audit rerun passed.
- **v19.0 Phase 151 Subscription Learning Showcase — COMPLETE 2026-07-11.** LearnLoop is now a product-first subscription learning/training lane with realistic courses, lessons, content packs, learners, progress, subscription states, route-derived diagnostics, a socketless offline study island, visible sync/reconciliation states, backend-owned mocked entitlement pressure, and route-tour screenshots after semantic assertions. LEARN-01 through LEARN-04 verified. Next active work is Phase 152: Capability Map, Collateral, and v20 Handoff.
- **v19.0 Phase 150 Field-Service Showcase — COMPLETE 2026-07-11.** Fieldserv is now a product-first field-service lane with realistic jobs/assets/technicians/inspection/evidence data, route-derived diagnostics, server-recorded inspection and evidence state, native-screen capture handoff, backend-authoritative evidence review, cached read-only offline posture, and route-tour screenshots after semantic assertions. FIELD-01 through FIELD-04 verified. Phase 151 followed and is now complete.
- **v19.0 Phase 149 SaaS/Admin Showcase — COMPLETE 2026-07-11.** AdminPilot is now a styled, LiveView-first SaaS/admin lane with realistic account/team/role/settings/operational data, lane-local compiled-router diagnostics, server-authoritative approval persistence/activity evidence, gated browser session proof, and route-tour screenshots after semantic assertions. SAAS-01 through SAAS-04 verified 11/11. Phase 150 Field-Service Showcase followed and is now complete.
- **v19.0 Phase 148 Demo App Brand & Fixture Direction — COMPLETE 2026-07-09.** The root showcase is Crosswake-branded with the real lockup, the old "example host" product copy is gone, AdminPilot/Fieldserv/LearnLoop are fixed as distinct fictional app brands, and fixture briefs define realistic org/person/record/activity/pressure data for the lane phases. Browser route-tour and visual UAT passed.
- **v19.0 Phase 147 Arc, Fixture, and Showcase Foundation — COMPLETE 2026-07-09.** The v19/v20 arc is locked, deterministic showcase reset data exists across the three lanes, the example-host root route is a Phoenix-owned showcase hub, and first-run docs/banner now lead with the showcase while keeping proof routes one click deeper. Browser UAT passed across desktop/mobile, light/dark, reduced motion, focus, and overflow checks.
- **v18.0 Release Integrity & Automated Package Operations — SHIPPED 2026-07-09.** The package-family release path is now automated, path-specific, and operator-visible: Release Please publish/proof jobs key off exact release identity and component paths instead of aggregate release outputs; release concurrency preserves in-flight publishes; Hex publishing runs through a guarded CI helper with exact already-live preflight and package-scoped recovery refs; companion clean-room proof installs the exact published companion version and derives its real `crosswake` floor from Hex metadata; doctor owns fresh-router loading; iOS mirror publishing fails fast on missing/invalid `MIRROR_PUSH_TOKEN`; native clean-room proofs are decoupled with rollup evidence; maintainers have a verify-first path to backfill the missing SwiftPM `v0.2.0` tag; and `mix crosswake.release.status [--json] [--live]` surfaces lockstep, compatibility floors, stale pins, workflow guard posture, and optional advisory registry truth. 15/15 v1 requirements satisfied; audit passed. Residual external risks are intentionally outside local automation: real iOS mirror mutation still needs the maintainer token, and live registry probes remain advisory. Full detail in `.planning/milestones/v18.0-ROADMAP.md`.
- **v17.0 Companion Family Completion — SHIPPED 2026-07-04.** The companion family is complete and LIVE on Hex: **`crosswake` 0.2.0** (core; +hexdocs +Android Maven) · **`crosswake_sigra` 0.1.1** (auth) · **`crosswake_chimeway` 0.1.0** (notifications) · **`crosswake_threadline` 0.1.0** (audit observer). Core was decoupled from all companions first — the four compile-time core→companion coupling sites (telemetry, route_gate, support_matrix, doctor) inverted onto a runtime `:companions` registry seam (optional `@behaviour` callbacks + `function_exported?/3`), so core compiles `--warnings-as-errors` with no companion present and auth-predicated routes fail **closed** (`:dependency_missing`). The three remaining in-tree companions then extracted to standalone independently-versioned `crosswake_*` Hex packages with module names preserved (non-breaking): sigra emits `Crosswake.Compatibility.Finding` at its boundary; chimeway proven sigra-free (the "chimeway→sigra" dep was a myth — `auth_context: map()`); threadline observes purely by telemetry event-name. Family discipline: O(N) drift-tested compat matrix, per-package Side-A telemetry contract tests, a hardened extraction recipe. Published in strict dependency order — **core `0.2.0` first**, companion floors bumped `~> 0.1`→`~> 0.2`, then sequential `sigra→chimeway→threadline` (each resolved against published core, never batched). 20/20 v1 requirements satisfied; `override_closeout` (empirical — all four proven live on Hex). Carried non-blocking: **SEED-003** (iOS mirror push token — core iOS SwiftPM 0.2.0 not yet mirrored), **SEED-004** (clean-room proof harness). Full detail in `.planning/milestones/v17.0-ROADMAP.md`.
- **v16.0 Companion Extraction & Package-Family Discipline — SHIPPED 2026-06-30.** The in-tree companion seams are now real, independently-versioned, fail-closed first-party Hex packages: `rulestead` and `rindle` extracted to standalone `packages/crosswake_*` projects with their module names preserved (`Crosswake.Companions.Rulestead`/`.Rindle`) so extraction is non-breaking; a parameterized extraction recipe + stdlib-only AST guards (core never compile-depends on a companion; `Code.ensure_loaded?` stays runtime-only) make the seam merge-blocking; RouteGate denies (not crashes) on an absent companion via a fail-closed `:dependency_missing` reason; companions carry independent release-please components (not the core lockstep) with a drift-tested cross-package compatibility matrix; `Crosswake.Telemetry` ships as a semver-governed public-API event contract with an opt-in PII-safe logger (core never auto-attaches); generated-shell lifecycle gained `@template_version` stamping + `mix crosswake.shell.status` + non-destructive `gen.shell --diff` + an upgrade guide; and PROOF-03 CI-ops automation makes companion release ops 0-human on the success path. All 27 v1 requirements satisfied; audit passed. Full detail in `.planning/milestones/v16.0-ROADMAP.md`.
- **v15.0 See It Run — Experiential First-Run DX — SHIPPED 2026-06-24.** A newcomer can boot the web, iOS-simulator, and Android-emulator views against one Dockerized backend at `localhost:4700` and compare them, via additive native dev-wiring (proof fixtures untouched), a brand-voiced launch banner, and a reader-empathy guide. 16/18 v1 requirements satisfied (COLL-01 native screenshots advisory-deferred). Full detail in `.planning/milestones/v15.0-ROADMAP.md`.
- **v14.0 Runtime Contract Confidence — SHIPPED 2026-06-21.** The bridge/runtime contract is now canonical and drift-proof: one Elixir source (`Crosswake.Bridge.Contract`) declares the bridge protocol version and every derived surface (manifest types, shell fixtures, native conformance vectors, docs snippet) regenerates from it via `mix crosswake.contract.gen`; the `1.1.0` vs `1.0.0` drift is resolved and the silent Kotlin fallback removed; merge-blocking drift guards (ExUnit + generate-and-diff CI + `contract_version_parity` doctor check) fail on any divergence; the reusable iOS (XCTest) and Android (JUnit) packages carry real behavioral tests driven by a single committed vector file; and compatibility is reconciled to one `>=` min-version-floor across Elixir and native, with adopter-facing rebuild-class decision tables, doctor guidance, and changelog upgrade-impact labels. Full detail in `.planning/milestones/v14.0-ROADMAP.md`.
- **v13.0 Adopter Confidence & Native Evidence — SHIPPED + archived 2026-06-19.** The public proof path now has current release truth, route-owner guides, checked-in public-coordinate native host labels, merge-blocking browser route-tour evidence, bounded evidence manifests, advisory native collateral capture, and route-owner troubleshooting. Full detail in `.planning/milestones/v13.0-ROADMAP.md`.
- **v12.0 CI Honesty & Real-E2E Sweep — SHIPPED + archived 2026-06-18.** The offline-sync proof now exercises the real IndexedDB outbox and reconnect flush path, the E2E proof lane is merge-blocking with structural honesty guards, the closeout verifier fails closed on invalid phase contracts and bare ledger evidence, the historical validation-ledger debt is represented by evidence-backed ledgers or an accepted exception, and v8.0 document truth is reconciled. Full detail in `.planning/milestones/v12.0-ROADMAP.md`.
- **v11.0 Release & Distribution Truth — SHIPPED + archived 2026-06-17.** The v5.0 standalone-package thesis is now genuinely consumable: `crosswake 0.1.2` is live on Hex, Maven Central, and the SwiftPM mirror from a single lockstep release-please run; `gen.shell` emits resolvable version-matched coordinates, proven by a clean-room CI lane and guarded by a permanent parity check. Full detail in `.planning/milestones/v11.0-ROADMAP.md`.

**Shipped `v14.0 Runtime Contract Confidence` on `2026-06-21`** (Phases 121-124, 17 plans). v14.0 was coherence work, not feature breadth: it made the bridge/runtime contract boringly canonical and hard to drift. A single canonical Elixir constant (`Crosswake.Bridge.Contract.version/0`) is the sole declared bridge-protocol literal; `mix crosswake.contract.gen` renders it into JSON fixtures, generated shell templates, native conformance vectors, and a docs snippet, and the `1.1.0`/`1.0.0` divergence was resolved without breaking the published `crosswake 0.1.x` contract (the silent Kotlin `?: "1.0.0"` fallback was removed). Drift is now caught mechanically: a browser-free merge-blocking ExUnit drift test (reads every surface via `Jason.decode`, names the one file + regenerate command on failure), a generate-and-diff CI check, a `contract_version_parity` doctor sibling check, and a required-vs-advisory aggregator split. The reusable iOS `crosswake-shell-core-ios` (XCTest, no simulator) and Android `crosswake-shell-core-android` (JUnit, no emulator) packages gained real behavioral tests for activation, bridge denial, capability allowlist, active-route, pack-version, and delegate/escape-hatch — all driven from one committed `bridge_contract_vectors.json` so a single version bump fails all three suites. Compatibility was reconciled to a single `>=` min-version-floor across Elixir and native (the native exact-equality footgun is gone), proven by the discriminating vec-014 (request `1.1.0` > session `1.0.0`); each version axis maps to a rebuild class (core-only / compat-bump / native-rebuild-required) surfaced through a decision-table-first compatibility guide, support matrix, a doctor rebuild-guidance check naming the full regenerate→rebuild→resubmit→deploy sequence, and changelog upgrade-impact labels. All 18 v1 requirements satisfied; audit passed (tech_debt — non-blocking carried items only).

**Shipped `v13.0 Adopter Confidence & Native Evidence` on `2026-06-19`** (Phases 116-120, 16 plans). v13.0 made the adopter-facing proof path current and visible: public docs and quick-starts reflect `crosswake 0.1.2`, route-owner and web-to-mobile guides frame the Phoenix-first mental model, checked-in iOS/Android hosts default to published coordinates with explicit evidence labels, browser route-tour proof captures bounded artifacts behind CI wiring, advisory native collateral records captured/unavailable outcomes honestly, and troubleshooting maps common failures back to route ownership. All 16 v13 requirements satisfied; audit passed.

**Shipped `v12.0 CI Honesty & Real-E2E Sweep` on `2026-06-18`** (Phases 112-115, 13 plans). v12.0 made the offline-sync and closeout proof surfaces honest: the demo app now queues real IndexedDB mutations and flushes them on reconnect; the Playwright E2E asserts app-generated mutation IDs against Ecto and runs behind a compile gate; the merge-blocking E2E aggregator, structural honesty scanner, and test-only route assertions prevent regression to fabricated proof. Phase 115 tightened `CloseoutVerifier` with the `closeout.expected_phases` fail-closed contract, evidence-backed validation ledgers, accepted v3.6 exception handling, and source-contract doc truth tests that establish `MILESTONES.md` > `PROJECT.md` Requirements marks > `v*-MILESTONE-AUDIT.md`.

**Shipped `v11.0 Release & Distribution Truth` on `2026-06-17`** (Phases 110-111, 8 plans). v11.0 turned the built-but-undistributed v5.0 thesis into a real install path. It published the iOS SPM core via splitsh-lite subtree mirror to `github.com/szTheory/crosswake-shell-core-ios` (annotated semver tags) and the Android core to Maven Central under verified `io.github.sztheory` (signed POM via Vanniktech → Central Portal), with release-please `linked-versions` advancing all three registries to one version per release and native publish jobs gated on `needs: release-please` + `if: releases_created`. It rewired `mix crosswake.gen.shell` to inject the live `Application.spec(:crosswake)[:vsn]` into published dep coordinates at generate-time (no version literal), proved the thesis outside the monorepo with a `$RUNNER_TEMP` clean-room CI lane (`swift build` / `gradle build` against the just-published deps), and made the guarantee permanent with a merge-blocking `generator_coordinate_parity` readiness check. A footgun-aware SETUP runbook plus a dispatch-only validated-upload→DROP fire-drill and a lockstep-truth assertion de-risked the irreversible first publish. Docs were reconciled to published truth, and `crosswake 0.1.2` was cut (REL-01) — the first live run surfaced and fixed latent pipeline bugs (fire-drill artifact assertion, Android auto-publish flag, Central Portal poll auth/endpoint, splitsh-lite version). All 11 v1 requirements satisfied.

**Shipped `v10.0 Brand Normalization` on `2026-06-14`** (Phases 107-109, 10 plans). v10.0 made `tokens.css` the genuine single source of truth for the brand system. The compiler (`compile-tokens.js`) now emits the full token set — `font.*` and `dimension.*` (type/display scale, radius) alongside color — into `tokens.css` with a byte-identical packaged mirror at `priv/static/crosswake/tokens.css`, distributed through one documented path (verbatim copy + `<link>`, `guides/tokens.md`). Both drifted consumers were rewired onto the semantic `--cw-*` tier: the example host's served `app.css` + standalone offline page (flat palettes, primitives, inline font stacks, and the duplicate `assets/css/app.css` all removed; D-12) and the `offline_ui` generator (Tailwind-free templates + vendored `offline.css`, with the stale legacy theme retired from `crosswake.gen.offline_ui.ex`). The generator test now pins the token-backed contract, and a D-13 Playwright render-verify gate measured all surfaces in light + dark (every text element ≥4.5:1, status affordances ≥3:1; two real AA failures caught and fixed; human sign-off approved). A browser-free `brand-structural` drift gate (`check-consumer-drift.mjs` + contract tests + CI wiring) now fails the build on any reintroduced brand hex or dropped token reference. TOKN-04/05, NORM-01/02/03/04, PROOF-01 all satisfied.

**Shipped `v9.0 Brand System & Visual Identity` on `2026-06-13`** (Phases 102-106, 16 plans). v9.0 pressure-tested and shipped the full brand system self-contained in `brandbook/`: a 14-section audit + WCAG contrast matrix, a W3C DTCG design-token system, a user-selected path-only logo suite, a zero-build standalone HTML brand book + `BRAND-SPEC.md` v1.0, and launch collateral wired into README/ExDoc with the brandbook excluded from the Hex package (committed size < 1 MB). It also shifted brand UAT left into a self-contained Playwright suite gated in CI (`brand-structural` required / `brand-visual` advisory) — which caught and fixed a real mobile-overflow defect — and added the pending CHANGELOG `[0.1.2]` entry, flipping `doctor --check-publish` to `ready`.

<details>
<summary>Earlier milestone history (v3.9 to v8.0)</summary>

**Shipped `v8.0 Offline Sync Hardening and UI Polish` on `2026-06-11`** (Phases 99-101, 6 plans). v8.0 hardened the offline sync capabilities by enforcing real network-toggling E2E tests, implementing advisory runtime storage budgets using standard Web APIs, and delivering a consolidated, brand-aligned `OfflineController` UI.

**Shipped `Phase 96 docs-contract-proof` on `2026-06-10`** (3 plans, verified 5/5). Phase 96 completed the v7.0 Threadline Audit Capstone by shipping the docs-as-contract artifact and hermetic parity proof: restructured `guides/threadline.md` into a 10-section D-07 contract-first guide with all verbatim contract strings (15 LEDG-02 columns, both forbidden-key lists, anti-scope section, honest limitations); a merge-blocking CI lane (`merge-blocking-threadline-docs-contract-proof`) with a 21-assertion hermetic parity test; and an advisory example-host PROOF-02 lane proving end-to-end Ecto-backed `record_in_multi/3` persistence yields durable posture. DOCS-01/02/03 and PROOF-01/02 satisfied.

**Shipped `Phase 95 Operator Surface` on `2026-06-10`** (5 plans, verified 4/4). Phase 95 shipped the text-only operator surface for Threadline: the `mix crosswake.threadline` task (ordered Native → Bridge → Phoenix event table with explicit ephemeral/durable posture), doctor Threadline findings including the fail-closed `threadline.pii_forbidden_field_present` error, and the `@audit_ledger_support_truth` support-matrix row. OPER-01/02/03 satisfied.

**Shipped `Phase 094 audit-ledger-contract-generator` on `2026-06-09`** (3 plans). Phase 094 implemented the Crosswake.Audit.Ledger struct and HMAC helper, and the `mix crosswake.gen.audit` task to scaffold the schema and migration templates.

**Shipped `Phase 93 Native Shell Propagation` on `2026-06-09`** (2 plans). Phase 93 updated the iOS and Android native shells to propagate `thread_id` across activation via header and JS injection, ensuring deterministic Native → Bridge → Phoenix correlation.

**Shipped `v6.0 Adoption Evidence Demo App (Flashcard Cohort)` on `2026-06-09`** (Phases 84-90, 9 plans). v6.0 delivered a flashcard language-learning demo app that exercises the full `Crosswake.Offline` island philosophy end-to-end. It shipped `Crosswake.Offline.ContentPack` (strongly-typed packs enforced at the route-policy boundary and compiled into the manifest) and `Crosswake.Sync.EventLog` (durable event log + `mix crosswake.gen.sync` scaffolding for host-owned Ecto schema and reconciliation controller with idempotency keys). The demo app pairs an online LiveView dashboard with a vanilla-JS offline study island over IndexedDB, connected to the native shell and aligned to the Brand Book, with network-toggling Playwright E2E tests proving the offline study loop and asserting Ecto sync state on reconnect.

**Shipped `v5.1 Adoption Evidence Demo App` on `2026-06-09`** (Phases 80-83, 7 plans). v5.1 transitioned the iOS and Android demo host projects to use the standalone SPM and Maven dependencies published in v5.0. It introduced reactive flow/publisher architectures (`StateFlow`, `SharedFlow`, `Combine`) for the bridge, implemented the `RouteDelegate` and capability handshake to support native escape hatches cleanly without coupling, and provided an automated `verify_bounded_bridge_proof.sh` and `QUICK_START.md` guide to prove the architecture end-to-end.

**Shipped `v5.0 Standalone Publishable Shell Packages` on `2026-06-06`** (Phases 76-79, 11 plans). v5.0 completed a major architectural shift to a binary Core + hosted glue strategy. It extracted generated logic into standalone SPM (iOS) and Maven Central (Android) dependencies, replaced raw object generation with a unified builder and reactive state APIs, and updated generator tooling to output thin dependency-driven host projects. Hermetic CI pipelines were updated to verify these standalone dependencies, ensuring existing E2E and archetype proof lanes continue to pass.

</details>

<details>
<summary>Earlier milestone history (v3.9, v3.8, v3.7, v3.6, v3.5, v3.4, v3.3, v3.2, v3.1, v5.0)</summary>

**Shipped `Phase 83` on `2026-06-08`**. Phase 83 completed the bounded bridge proof and finalize phase polish. It demonstrated native capabilities triggered from LiveView, verified end-to-end integration via the `QUICK_START.md` guide and automated tests, and ensured the backend capability payload and router configuration were accurate.

**Shipped `v3.9 Chimeway Notification Seam` on `2026-06-03`** (Phases 59-63, 17 plans, 12 tasks). v3.9 made notification registration and notification-open routing trustworthy without claiming Crosswake is a push delivery platform.

**Shipped `v3.8 Full Sigra Auth and Session Machinery` on `2026-06-02`** (Phases 54-58, 19 plans, 42 tasks). v3.8 expands Sigra from v3.5's contract-only auth slice into production account-security machinery while keeping authority backend-owned.

**Shipped `v3.7 Commerce Provider Adapters` on `2026-06-01`** (Phases 48 and 48.1, 7 plans). v3.7 added first-party StoreKit and Play Billing adapter seams.

**Shipped `v3.6 Operator Truth and Production Diagnostics` on `2026-06-01`** (Phases 48-53, 15 plans). v3.6 refreshed the strategic arc and turned route/capability readiness into production-facing operator surface.

**Shipped `v3.5 First-Party Companions` on `2026-05-31`** (Phases 38-47, 22 plans, 40 tasks). v3.5 locked Crosswake's first reusable companion seam and proved it across three bounded companion surfaces.

**Shipped `v3.4 Commerce Archetype Proof` on `2026-05-29`** (Phases 33-37, 8 plans, 8 tasks). v3.4 turned v3.2's commerce vocabulary into a copy-able adopter lane.

Crosswake shipped `v3.3 Release Readiness` on `2026-05-29` (`crosswake 0.1.0` live on hex.pm via the release-please pipeline).

Crosswake shipped `v3.2 Commerce And Entitlement Seams` on `2026-05-27`.

`v3.1 Native Capabilities and Bridge Expansion` shipped on `2026-05-27`, delivering the first official low-frequency native capability families.
</details>

## Earlier Milestone: v14.0 Runtime Contract Confidence

**Goal:** Make Crosswake's bridge/runtime contract boringly canonical and hard to drift — one source of truth across Elixir, manifest compatibility, generated shells, reusable native packages, examples, proof lanes, and docs — then prove it directly in the native packages rather than only in checked-in example hosts. Coherence work, not feature breadth.

**Delivered:** A single canonical Elixir bridge-protocol source feeding all derived surfaces via `mix crosswake.contract.gen` (the `1.1.0`/`1.0.0` drift resolved, Kotlin silent fallback removed); merge-blocking browser-free drift guards (ExUnit drift test + generate-and-diff CI + `contract_version_parity` doctor check + required-vs-advisory aggregator); real behavioral tests in the reusable iOS XCTest and Android JUnit shell-core packages driven from one committed conformance-vector file; and a `>=` min-version-floor compatibility reconciliation across Elixir and native with rebuild-class decision tables, a decision-table-first compatibility guide, doctor rebuild-guidance, and changelog upgrade-impact labels.

**Outcome:** All 18 v1 requirements satisfied (CANON-01..05, GUARD-01..04, NTEST-01..04, COMPAT-01..05); audit passed with `tech_debt` status (no blockers; non-blocking carried items only — WR-01 Elixir capability-axis test-coverage caveat, two human-gated branch-protection PATCHes, pre-existing docs-debt test failures). Nyquist coverage full (4/4 phases).

**Archive:** `.planning/milestones/v14.0-ROADMAP.md`, `.planning/milestones/v14.0-REQUIREMENTS.md`, and `.planning/milestones/v14.0-MILESTONE-AUDIT.md`.

## Previous Milestone: v15.0 See It Run — Experiential First-Run DX (shipped 2026-06-24)

**Goal:** Make it trivial and delightful for a newcomer to boot the web, iOS-simulator, and Android-emulator versions of Crosswake against one shared backend and compare them side by side — with a one-command Dockerized backend, no micro-dep management, no port collisions with other OSS lib demos, fast rebuilds (no dep re-downloads on style changes), additive native dev-wiring that leaves the public-coordinate proof artifacts intact, committed visual collateral, a printed URL/route launch banner, and a reader-empathy guide.

**Target features:**
- One-command containerized shared backend (`docker compose up`) with cached deps, polling live-reload, and SQLite in a named volume; native `mix` path still supported.
- A static per-lib port convention (Crosswake = 4700) reachable by all three runtimes, plus a reusable PORT-REGISTRY for the maintainer's other libs.
- Additive iOS `Dev` scheme + Android `dev` flavor pointing at the local backend without modifying the checked-in proof fixtures/assets.
- A friendly launch entrypoint (`bin/see-it-run.sh`) that boots the backend, advisorily boots sim/emulator when tooling is present, and prints a brand-voiced URL/route/next-command banner with an honest "what's proven / what needs a native build" block.
- Committed three-runtime screenshots + a short screen recording (honestly labeled advisory native evidence).
- A new `guides/see_it_run.md` (gameplan-at-top, JTBD-driven), routed from README/QUICK_START and guarded by doc-contract tests.

**Key context:** Deferred behind the v15.0 DX wedge — native runtime evidence & generated-shell lifecycle hardening (LIFE-01/02), offline-sync productization (SYNCP-01), DASH-01 operator metrics, NTV-01 native disk budgets, companion package extraction, future capability/commerce breadth. Brand source of truth is `brandbook/BRAND-SPEC.md` (v9.0) + `priv/static/crosswake/tokens.css`. Phase numbering continues from v14.0 (phases 125+).

**Progress:** SHIPPED 2026-06-24. All 4 phases (125-128) complete + verified, 12/12 plans; merged to origin/main. DOCKER/PORT/NDEV/LAUNCH/DOCS all validated; COLL-02 (see-it-run.gif) shipped. COLL-01 native screenshot binaries accepted as advisory-deferred (non-proof advisory native evidence — CI Android-emulator-on-macOS capture hangs, local capture blocked by the Xcode-26-vs-published-package wall; capture infra shipped for opportunistic future runs). Full detail archived in `.planning/milestones/v15.0-*`.

## Earlier Shipped Milestone: v16.0 Companion Extraction & Package-Family Discipline (shipped 2026-06-30)

**Goal:** Turn the in-tree companion seams into real, independently-versioned, fail-closed first-party Hex packages — proving the extraction pattern end-to-end on `rulestead` then `rindle` — and ship the lifecycle (generated-shell upgrade runbook + native UAT), compatibility-matrix, and telemetry-as-public-API discipline a package family requires. Coherence/packaging work, not feature breadth.

**Delivered:** `rulestead` then `rindle` extracted to standalone `packages/crosswake_*` Hex projects (own `mix.exs`/`@version`, source + tests moved out of core, module names preserved → non-breaking); stdlib-only AST guards making EXTRACT-03/04 merge-blocking and non-vacuous; RouteGate `:dependency_missing` fail-closed denial; independent release-please components (not core lockstep) + a drift-tested compatibility matrix; a clean-room install lane gated by `hex.publish --dry-run`; `Crosswake.Telemetry` public-API event contract + opt-in PII-safe logger; generated-shell `@template_version` stamping + `shell.status` + non-destructive `gen.shell --diff` + upgrade guide; and PROOF-03 0-human release-as automation (staleness guard, auto-cleanup PR, failure alerts, parametric required-check registration).

**Outcome:** All 27 v1 requirements satisfied (SEAM-01..05, EXTRACT-01..07, COMPAT-01..03, PROOF-01..03, TELEM-01..04, LIFE-01a/01b/02a/02b/02c); audit `passed` (integration CLEAN, 0 blockers, 5/5 E2E flows). Non-blocking tech debt carried: TELEM-04 Side B vacuity (assessed, deferred — structurally near-impossible divergence) and compat-prose (not-a-bug). One human ship-gate remains: register the 18 unregistered `merge-blocking-*` lanes (admin-gated; provision `BRANCH_PROTECTION_READ_TOKEN` + run `register_required_checks.sh`).

**Archive:** `.planning/milestones/v16.0-ROADMAP.md`, `.planning/milestones/v16.0-REQUIREMENTS.md`, and `.planning/milestones/v16.0-MILESTONE-AUDIT.md`.

## Earlier Shipped Milestone: v17.0 Companion Family Completion (shipped 2026-07-04)

**Goal:** Extract the remaining three first-party companions — `sigra` (auth), `chimeway` (notifications), `threadline` (audit) — into standalone, independently-versioned, fail-closed Hex packages, completing the companion family. Module names preserved (`Crosswake.Companions.Sigra.*` etc.) so the sole adopter touch-point (`config :crosswake, :companions, [...]`) is unchanged and extraction is non-breaking.

**Delivered:** Core decoupled from all companions first — the four compile-time core→companion coupling sites (telemetry, route_gate, support_matrix, doctor) inverted onto a runtime `:companions` registry seam (optional `@behaviour` callbacks + `function_exported?/3`), so core compiles `--warnings-as-errors` with no companion present and auth-predicated routes fail closed (`:dependency_missing`). The three companions then extracted to standalone `packages/crosswake_*` projects (own `mix.exs`/`@version`, module names preserved → non-breaking): sigra emits `Compatibility.Finding` at its boundary (core keeps `Denial` private); chimeway proven sigra-free by a vacuity-safe clean-room lane (`auth_context: map()`, the inter-companion dep was a myth); threadline observes purely via `:telemetry.attach_many` by event-name (zero sibling compile deps). Family discipline: O(N) drift-tested compat matrix, per-package Side-A telemetry contract tests, a hardened extraction recipe (Step 0 core-decoupling gate). Published in strict dependency order — **core `0.2.0` first**, companion floors bumped `~> 0.1`→`~> 0.2`, then sequential sigra→chimeway→threadline (each resolved against published core, one Release PR each, never batched).

**Outcome:** All 20 v1 requirements satisfied (DECOUPLE-01..06, SIGRA-01..03, CHIME-01..03, THREAD-01..03, FAMILY-01..05); `override_closeout` (empirical — all four packages proven LIVE on Hex: `crosswake` 0.2.0 + `crosswake_sigra` 0.1.1 + `crosswake_chimeway` 0.1.0 + `crosswake_threadline` 0.1.0). Non-blocking follow-ups carried: SEED-003 (iOS SwiftPM mirror push token — core `0.2.0` published to Hex + Android Maven but not yet mirrored to the iOS split repo) and SEED-004 (clean-room proof harness doctor-router bug, advisory).

**Archive:** `.planning/milestones/v17.0-ROADMAP.md` and `.planning/milestones/v17.0-REQUIREMENTS.md`.

**v18 outcome:** release integrity and package-family operations are now trustworthy enough to choose the next product-breadth milestone deliberately. DASH-01 `crosswake_dashboard`, SYNCP-01 offline-sync productization, NTV-01 native disk budgets, and SEED-002 capability/commerce breadth remain deferred until selected via `/gsd-new-milestone`.

## Requirements

### Validated

- ✓ **INV-01..03** Every copy of the work outside GitHub `main` is inventoried by content, backed up outside the temp folder with passing restore tests, and every open PR has a recorded disposition. — v27.0 Phase189.
- ✓ **FIX-01..07** The seven carried v26 warnings are fixed: empty privacy scopes fail, every gate label has a failing self-test, the gate git helper is pinned, registry timeouts are reported, nested-host provenance is honest, the guard pin equals the real count, and the physical-iPhone preflight refuses unreadable or malformed input. FIX-01..03 successors live in the Phase 190 folder. — v27.0 Phase190.
- ✓ **LAND-01..04** One integration branch from current `main` with a clean privacy scan and passing local suite; PR #242 merged after a plain `allow`, with CI green on the head and on the merge commit. — v27.0 Phases191–192.
- ✓ **CLEAN-01..04** Recovery checkout retired for a clean `main` checkout; landed or obsolete local copies removed with a ledger; branch-and-PR working rules in AGENTS.md. — v27.0 Phase193.
- ✓ **PROBE-01..04** The twin blocks `source_dirty` for any tracked difference from HEAD however git hides it, every twin git call uses one pinned configuration, real-repo fixtures cover each hiding mechanism, and a read-only preflight never consumes a run root. — v26.0 Phase184.
- ✓ **GUARD-01..03** The absence checker fails on a missing root, empty scope or below-pin scope; uncovered v25 loops assert non-empty; twin runtime helpers fail closed. — v26.0 Phase185.
- ✓ **SEAM-07..09, LOOP-06..07** The legacy host-command path no longer grants every command, doctor's stale check errors on unreadable input, path messages are project-relative, the loopback harness reports its own failures, and physical-iPhone preparation cannot reach a loopback host (tested cases; 186 WR-01 residual). — v26.0 Phase186.
- ✓ **DOCTOR-01..04** Doctor JSON carries unmanaged-route details, unbacked offline islands are flagged, proof provenance is real or an explicit sentinel, and the CW-REQ-A/D deferrals are recorded. — v26.0 Phase187.
- ✓ **TWIN-07..08** One frozen candidate commit, a scripted go/no-go, and exactly one twin-05 run that passed and is byte-copied into planning. — v26.0 Phase188.
- ✓ **SEAM-01..06** Routes declare versioned `host.*` commands once on the router; the manifest (schema 1.2.0, additive) is the sole per-route authority; the native session grants only declared, registered, compatible commands; the bounded iOS shell admits `offline_island` routes; seam handoff written. — v25.0 Phase181.
- ✓ **LOOP-01..05** An explicit `origin_mode: :local_loopback` allows only `http://127.0.0.1`/`localhost` with ATS `NSAllowsLocalNetworking`; production output is byte-identical and HTTPS-only; doctor warns and the physical proof lane refuses local mode. — v25.0 Phase182.
- ✓ **TWIN-01..06** One automated reference twin binds the actual generated candidate, visible island action, host-native media, durable offline work, authorized replay, independent Ecto effects and controlled fault cases into a closed, source-bound, privacy-safe receipt with ten group outcomes and fidelity limits. — v25.0 Phase180, re-attested by Phase183 (twin-04, committed source).
- ✓ **IOS-01** One ordinary compile-only Phoenix/Mix host declaration supports generation, host-edit preservation and nonwriting conflict inspection. — v25.0 Phase179, independent candidate `96e5a63`.
- ✓ **IOS-02** Shared app/proof identity and signing projections match independently derived effective Xcode settings across simulator/device classes; no signed-install claim. — v25.0 Phase179.
- ✓ **IOS-03** Selected-router canonical manifest/static activation fails closed for invalid or interrupted inputs and grants no runtime auth/replay authority. — v25.0 Phase179.

- ✓ **MAINT-01** Maintainer can inspect an inventory of every local change against merged code, with the compared source commits named. — v24.0 (Phase 176).
- ✓ **MAINT-02** Maintainer can see a disposition for each inventoried change and recover unique work before any removal. — v24.0 (Phase 176).
- ✓ **MAINT-03** Maintainer can use supported release entry points after obsolete release code is removed only where its replacement and callers have been verified. — v24.0 (Phase 177).
- ✓ **MAINT-04** Maintainer can distinguish tracked contracts, ignored transient files and forbidden residue using the existing repository artifact policy. — v24.0 (Phase 176).
- ✓ **MAINT-05** Maintainer can see a concrete next action for every open PR and issue in a dated inventory; maintenance triage does not authorize release publication. — v24.0 (Phase 177).
- ✓ **MAINT-06** Maintainer can follow corrected maintenance instructions without stale paths or commands, while historical failure records retain their original verdicts. — v24.0 (Phase 177).
- ✓ **MAINT-07** Maintainer can run the existing repository verification command from an exact clean checkout and inspect its results and before/after Git status. — v24.0 (Phase 178).
- ✓ **MAINT-08** Maintainer can inspect green CI bound to the final source commit; results from an older or different commit do not satisfy this requirement. — v24.0 (Phase 178).

MAINT-03 validates supported paths with uncertain sources retained; neither historical reader comparison is proven. MAINT-05 uses the dated 23-item Phase177 inventory and 24-item audit supplement. Final-source proof is warm-cache, bound to the exact governed merge object; the two earlier failures lack assertion output and remain undiagnosed. PR #238 is open/unmerged.

- [x] **v23.0 release and proof repair** — 42/43 requirements satisfied: manifest-derived identity, independent package refs, honest diagnostic exits, nonempty assertion inventory, real generated-host installer proof, ordinary core/companion publication and exact-public rollup. Full IDs/outcomes are in the workstream requirements archive. REL-10 is excluded and remains historically breached.

- [x] **PROOF-01** `mix crosswake.gen.proof_lane ios` creates missing-only host-owned ExUnit,
  Playwright, shell, and physical-device proof scaffolding. Validated in Phase 159: Host-Reusable
  Proof Lane.
- [x] **PROOF-02** The scaffold accepts the closed route, IndexedDB, mutation, endpoint, router,
  and iOS-shell configuration contract. Validated in Phase 159: Host-Reusable Proof Lane.
- [x] **PROOF-03** The generated browser proof remains additive to the host's primary browser,
  unit, and fixture corpus. Validated in Phase 159: Host-Reusable Proof Lane.
- [x] **PROOF-04** Retained proof evidence excludes sensitive payload, identity, credential, media,
  token, and stable-device data. Validated in Phase 159: Host-Reusable Proof Lane.
- [x] **MIRROR-01** The `crosswake-shell-core-ios` SwiftPM mirror carries `v0.2.0` at the verified split SHA while preserving `v0.1.2`. Validated in Phase 153: iOS Mirror Unblock.
- [x] **MIRROR-02** Native shell-core releases coordinate Hex, Maven, and the iOS mirror, with mirror failures surfaced as hard named CI failures. Validated in Phase 153: iOS Mirror Unblock.
- [x] Provide a Phoenix-native route policy DSL that declares runtime mode, offline policy, required capabilities, pack needs, sync seams, and security sensitivity per route. Validated in Phase 1: Route Policy Foundation.
- [x] Provide additive generators/installers for host Phoenix setup and native shell bootstrap that keep ownership boundaries explicit. Validated in Phase 1: Route Policy Foundation.
- [x] Generate and validate a runtime manifest and compatibility contract that native shells, bridges, and host Phoenix apps can trust. Validated in Phase 2: Manifest Truth And Compatibility.
- [x] Ship developer-facing doctor diagnostics plus honest compatibility and support documentation as part of the public product contract. Validated in Phase 2: Manifest Truth And Compatibility.
- [x] Treat diagnostics, compatibility truth, and failure-mode visibility as first-class product surfaces. Validated in Phase 2: Manifest Truth And Compatibility.
- [x] Support offline semantics that clearly separate cached read-only routes, local drafts, append-only journals, reconciliation, and server-authoritative commits. Validated in Phase 4: Honest Offline Contract.
- [x] Create disciplined contracts for offline islands and sync journals/outboxes without widening into generic sync claims. Validated in Phase 4: Honest Offline Contract.
- [x] Define a versioned bridge contract for bounded native affordances instead of ad hoc messaging. Validated in Phase 3: Native Shell Boot And Bounded Bridge.
- [x] Establish a capability registry with explicit allowlists, versioning, and active-route checks. Validated in Phase 3: Native Shell Boot And Bounded Bridge.
- [x] Ship example-host proof lanes and deterministic CI that verify the public install path across Phoenix, iOS, and Android surfaces. Validated in Phase 5: Packs, Native Escape, And Proof Lanes.
- [x] Validate the v1 substrate against three adopter-shaped exemplar lanes: Phoenix-backed SaaS portal, selective-native mobile flow, and local-first study or content flow. Validated across Phases 7-10.
- [x] Harden route-policy, manifest, shell, bridge, pack, transfer, and offline contracts where exemplar pressure exposes adopter-facing gaps. Validated in Phase 10: Cross-Profile Hardening, Proof, And Guidance.
- [x] Publish proof, diagnostics, and guidance that make exemplar support and rough-edge truth part of the public product contract. Validated in Phase 10: Cross-Profile Hardening, Proof, And Guidance.
- [x] Freeze capability-family taxonomy and route-owner decision rules before shipping new capability families. Validated in Phase 11: Capability Taxonomy And Contract Rubric.
- [x] Classify `core`, `companion`, `example/docs-only`, and deferred surfaces with explicit release and rebuild rules. Validated in Phase 12: Packaging Ledger And Release Boundaries.
- [x] Define Phoenix-facing commerce and entitlement seams that keep entitlement truth backend-owned. Validated in Phase 13: Commerce And Entitlement Contract.
- [x] Extend doctor, support-matrix, and proof-lane posture so future capability claims remain honest. Validated in Phase 14: Proof, Doctor, And Support Truth.
- [x] Ship the first low-frequency bounded native capability families (`haptics`, `share`, `app_info`, `deep_link`, `permissions.status`, `notification_token`, and `file_picker`) without widening into high-frequency bridge authority. Validated across Phases 15-17.
- [x] Enforce v3.1 capability declarations route-locally and keep missing prerequisites fail-closed with explicit doctor and support-matrix truth. Validated in Phase 18.
- [x] Prove the v3.1 capability surface through layered Elixir, checked-in iOS shell, and Android JVM CI proof lanes. Validated by Phase 18 Proof run `26498172516`.
- [x] **COMM-04** Phoenix teams can declare commerce-sensitive routes that distinguish Phoenix-owned paywall/account surfaces from native-screen or companion-owned storefront loops. Validated in v3.2 (Phase 19).
- [x] **COMM-05** Crosswake can render commerce route/corridor declarations into manifest and support truth without exposing provider-specific route-policy vocabulary. Validated in v3.2 (Phase 19).
- [x] **COMM-06** Unsupported or undeclared commerce corridors fail closed with explicit denial/fallback reasons instead of silent WebView or bridge fallback. Validated in v3.2 (Phase 19).
- [x] **ENTL-01** Phoenix teams can model entitlement snapshots with authority state, access state, reconciliation state, freshness, effective dates, and bounded evidence metadata. Validated in v3.2 (Phase 20).
- [x] **ENTL-02** Crosswake distinguishes pending purchase, pending restore, awaiting verification, grace/billing retry, canceled scheduled end, revoked/refunded, expired, and stale snapshot states without leaking raw provider enums. Validated in v3.2 (Phase 20).
- [x] **ENTL-03** Device, storefront, webhook, and support evidence can feed reconciliation but cannot directly grant entitlement authority in core contracts. Validated in v3.2 (Phase 20).
- [x] **RECN-01** Host apps can follow a minimal Phoenix-owned reconciliation inbox example for purchase, restore, webhook, and support evidence. Validated in v3.2 (Phase 21).
- [x] **RECN-02** Host apps can follow idempotency guidance that uses provider-aware identity rather than transient device correlation IDs. Validated in v3.2 (Phase 21).
- [x] **RECN-03** Host apps can project one authoritative entitlement snapshot from verified evidence and expose stale, pending, denied, and granted states clearly. Validated in v3.2 (Phase 21).
- [x] **SUPP-04** Doctor and support-matrix output identify missing commerce prerequisites, unsupported native corridors, stale entitlement snapshots, and native rebuild requirements. Validated in v3.2 (Phase 23).
- [x] **SUPP-05** Public commerce guidance explains reviewer/storefront sandbox setup, restore expectations, fallback behavior, and rough edges without implying provider adapters have shipped. Validated in v3.2 (Phase 23).
- [x] **SUPP-06** Maintainers can run merge-blocking hermetic commerce proof while treating StoreKit/Play Billing simulator, device, or storefront checks as advisory until adapter milestones ship. Validated in v3.2 (Phase 23).
- [x] **PROOF-01 / REL-TRUTH-01 / DRIFT-01** v13 public proof debt and release truth are clean before adopter evidence builds on them. Validated in Phase 116.
- [x] **GUIDE-01** v13 route-policy/start-here guide explains Crosswake's route-owner job, owner classes, current examples, and manifest/doctor/support truth links. Validated in Phase 117.
- [x] **MIGRATE-01** v13 web-to-mobile migration guide inventories existing Phoenix SaaS routes and defaults most routes to LiveView before explicit promotion. Validated in Phase 117.
- [x] **TRUTH-01** v13 README, ExDoc groups, support matrix, and guide maps share one support-truth label vocabulary. Validated in Phase 117.
- [x] **QUICK-01** v13 quick start is runnable from a clean checkout with exact setup/server/native/proof commands, paths, expected output, and advisory native labels. Validated in Phase 118.
- [x] **ADOPT-01** v13 adoption guide teaches the app-owned IndexedDB outbox/reconnect/Ecto proof and removes bridge-owned offline mutation language. Validated in Phase 118.
- [x] **DRIFT-02** v13 quick-start/adoption guide drift is guarded by source-derived ExUnit docs-contract tests. Validated in Phase 118.
- [x] **NATIVE-01 / NATIVE-02 / DRIFT-03** v13 checked-in native hosts default to published coordinates, public native docs use consistent evidence labels, and drift is guarded mechanically. Validated in Phase 119.
- [x] **COLL-01 / COLL-02 / NATIVE-COLL-01 / TROUBLE-01** v13 route-tour evidence, bounded evidence manifests, advisory native collateral, and route-owner troubleshooting are durable and honestly labeled. Validated in Phase 120.
- ✓ **v3.3 Release Readiness** (all 28 requirements: META-*, VER-01, LOG-*, REL-*, HEX-*, PRF-*) — `crosswake 0.1.0` published to hex.pm.
- ✓ **v3.4 Commerce Archetype Proof** (all 14 requirements: PWAL-01/02, MOCK-01/02/03, WIRE-01/02/03, STATE-01, PROOF-01/02/03, DOCS-01/02) — runnable mocked paywall corridor.
- ✓ **v3.5 First-Party Companions** (all 15 requirements: COMP-*, GATE-*, MEDIA-*, AUTH-*, PROOF-*) — reusable in-tree companion seam.
- ✓ **v3.6 Operator Truth and Production Diagnostics** (all 11 requirements: STRAT-*, OPER-*, DIAG-*, SUPP-*, PROOF-*, REL-01) — operator inspection, publish/readiness doctor checks.
- ✓ **v3.7 Commerce Provider Adapters** (all 3 requirements: ADPT-01/02/03) — first-party StoreKit and Play Billing evidence adapter seams.
- ✓ **v3.8 Full Sigra Auth and Session Machinery** (all 16 requirements: SESS-*, HAND-*, STEP-*, RETN-*, DIAG-*, PROOF-01) — backend-owned session authority projection.
- ✓ **v3.9 Chimeway Notification Seam** (all 11 requirements: TOKN-01/02/03, OPEN-01/02/03, DIAG-01/02, PROOF-01/02, plus REL-01 closeout gate) — first-party in-tree Chimeway companion seam.
- ✓ **v5.0 Standalone Publishable Shell Packages** (all 10 requirements: CORE-*, API-*, GEN-*, PROOF-01) — extracted iOS/Android core logic into standalone dependencies, standardized reactive APIs, generated thin dependency-driven host projects, and verified hermetic closeout lanes. Verification gaps accepted as tech debt. Validated across Phases 76–79; full detail in `.planning/milestones/v5.0-REQUIREMENTS.md`.
- ✓ **v6.0 Adoption Evidence Demo App (Flashcard Cohort)** (all 9 requirements: OFF-01/02, SYNC-01/02, DEMO-01/02/03, PROOF-01/02) — shipped `Crosswake.Offline.ContentPack` and `Crosswake.Sync.EventLog`, a flashcard demo app pairing online LiveView with a vanilla-JS offline study island over IndexedDB, native-shell integration + Brand Book alignment, and network-toggling Playwright E2E proof of the offline loop with DB-level sync verification. PROOF-01/02 validated via a mocked E2E flow (real network-toggling run deferred); OFF-02 shipped as contract with thin runtime enforcement. Validated across Phases 84-90; full detail in `.planning/milestones/v6.0-REQUIREMENTS.md`.

- ✓ **v7.0 Threadline Audit Capstone** (all 19 requirements: PROP-*, LEDG-*, OPER-*, DOCS-*, PROOF-*) — cross-boundary thread correlation, PII-free append-only Ecto audit ledger, text-only operator UI, and docs-contract parity. Validated across Phases 91-98; full detail in `.planning/milestones/v7.0-ROADMAP.md`.

- ✓ **SYNC-01**: Playwright E2E tests for the offline study island use actual network toggling — v8.0
- ✓ **SYNC-02**: The E2E tests assert the complete reconciliation loop — v8.0
- ✓ **SYNC-03**: The E2E Playwright configuration handles `localhost` explicitly — v8.0
- ✓ **OFFC-01**: A `mix crosswake.gen.offline_ui` generator scaffolds a host-owned `OfflineController` — v8.0
- ✓ **OFFC-02**: The generated Offline UI explicitly disconnects from the LiveView websocket lifecycle — v8.0
- ✓ **BDGT-01**: `Crosswake.Offline.Contracts.StudySessionIsland` exposes an explicit `:storage_budget` attribute — v8.0
- ✓ **BDGT-02**: Runtime JavaScript checks `navigator.storage.estimate()` — v8.0
- ✓ **BDGT-03**: JS IndexedDB `put()` operations are wrapped in `try/catch` — v8.0
- ✓ **BRND-01**: The generated offline UI applies the Crosswake Brand Book design tokens — v8.0
- ✓ **BRND-02**: The offline UI implements explicit, honest microcopy — v8.0
- ✓ **v9.0 Brand System & Visual Identity** (all 21 v1 requirements: AUDT-*, TOKN-*, LOGO-*, BOOK-*, COLL-01..05) — shipped the brand audit + WCAG matrix + frozen DTCG tokens, the path-only logo suite, the standalone HTML brand book + `BRAND-SPEC.md` v1.0, launch collateral wired into README/ExDoc (brandbook hex-excluded), and (COLL-05) an automated Playwright brand-verification suite gated in CI that replaces manual brand UAT. Validated across Phases 102-106; full detail in `.planning/milestones/v9.0-REQUIREMENTS.md`.

- ✓ **v10.0 Brand Normalization** (all 7 v1 requirements: TOKN-04/05, NORM-01/02/03/04, PROOF-01) — made `tokens.css` the genuine single source of truth: compiler emits font + dimension tokens (not just color) with a packaged mirror and one documented distribution path; the example host CSS and the `offline_ui` generator (templates + vendored `offline.css`, stale legacy theme retired) rewired onto the semantic `--cw-*` tier with no duplicated palettes, inline font stacks, or Tailwind; generator test pins the token contract; and a browser-free `brand-structural` drift gate fails the build on reintroduced brand hex or dropped token references. Validated across Phases 107-109; full detail in `.planning/milestones/v10.0-REQUIREMENTS.md`.

- ✓ **v11.0 Release & Distribution Truth** (all 11 v1 requirements: PUB-01/02/03, LOCK-01/02, GEN-01/02, PROOF-01/02, DOCS-01, REL-01) — made the v5.0 standalone-package thesis actually consumable. Published the iOS SPM core (splitsh-lite subtree mirror, semver tags) and Android core (Maven Central, verified `io.github.sztheory`, signed POM) with release-please `linked-versions` lockstep; rewired `gen.shell` to inject the live Hex version into published coordinates at generate-time; proved an outside-the-monorepo clean-room `swift build`/`gradle build` resolves and compiles; added a permanent merge-blocking `generator_coordinate_parity` guard; reconciled install docs to published truth; and cut `crosswake 0.1.2` live to all three registries from one release-please run. Validated across Phases 110-111; full detail in `.planning/milestones/v11.0-REQUIREMENTS.md`.

- ✓ **v12.0 CI Honesty & Real-E2E Sweep** (all 10 v1 requirements: E2E-01/02/03/04, GATE-01/02, GUARD-01/02, DEBT-01, DOC-01) — replaced fabricated offline-sync proof with a real IndexedDB outbox/reconnect/Ecto loop, made the E2E lane merge-blocking with structural honesty guards, hardened closeout verification against vacuous phase and ledger checks, resolved historical validation-ledger debt with evidence-backed ledgers or an accepted exception, and reconciled v8.0 document truth. Validated across Phases 112-115; full detail in `.planning/milestones/v12.0-REQUIREMENTS.md` and `.planning/milestones/v12.0-phases/115-closeout-verifier-honesty-ledger-backlog-doc-truth/115-VERIFICATION.md`.

- ✓ **v14.0 Runtime Contract Confidence** (all 18 v1 requirements: CANON-01..05, GUARD-01..04, NTEST-01..04, COMPAT-01..05) — made the bridge/runtime contract canonical and drift-proof. Single canonical Elixir source (`Crosswake.Bridge.Contract`) feeds manifest types, shell fixtures, native conformance vectors, and a docs snippet via `mix crosswake.contract.gen`; `1.1.0`/`1.0.0` drift resolved and Kotlin silent fallback removed; merge-blocking ExUnit drift test + generate-and-diff CI + `contract_version_parity` doctor check + required-vs-advisory aggregator; real iOS XCTest + Android JUnit behavioral tests driven from one committed `bridge_contract_vectors.json`; and a `>=` min-version-floor compatibility reconciliation across Elixir and native (native exact-equality footgun removed, proven by discriminating vec-014) with rebuild-class decision tables, a decision-table-first compatibility guide, doctor rebuild-guidance, and changelog upgrade-impact labels. Validated across Phases 121-124; full detail in `.planning/milestones/v14.0-REQUIREMENTS.md`.

- ✓ **v15.0 See It Run — Experiential First-Run DX** (16/18 v1 requirements: DOCKER-01..05, PORT-01..03, NDEV-01..03, LAUNCH-01..02, DOCS-01..03, COLL-02; COLL-01 advisory-deferred) — one-command Dockerized shared backend at `localhost:4700`, static per-lib port convention, additive iOS `Dev` scheme + Android `dev` flavor (proof fixtures untouched), a brand-voiced `bin/see-it-run.sh` launch banner, a screen recording, and `guides/see_it_run.md`. COLL-01 native screenshot binaries accepted as advisory-deferred (CI Android-emulator-on-macOS capture hangs; local capture blocked by the Xcode-26-vs-published-package wall). Validated across Phases 125-128; full detail in `.planning/milestones/v15.0-REQUIREMENTS.md`.

- ✓ **v16.0 Companion Extraction & Package-Family Discipline** (all 27 v1 requirements: SEAM-01..05, EXTRACT-01..07, COMPAT-01..03, PROOF-01..03, TELEM-01..04, LIFE-01a/01b/02a/02b/02c) — turned the in-tree companion seams into real, independently-versioned, fail-closed first-party Hex packages. `rulestead` then `rindle` extracted to standalone `packages/crosswake_*` projects with module names preserved (non-breaking); stdlib-only AST guards keep core compile-decoupled from companions and `Code.ensure_loaded?` runtime-only (EXTRACT-03/04 merge-blocking, non-vacuous); RouteGate `:dependency_missing` fail-closed denial; independent release-please components + drift-tested cross-package compatibility matrix; a clean-room install lane gated by `hex.publish --dry-run`; `Crosswake.Telemetry` semver-governed public-API event contract + opt-in PII-safe logger (core never auto-attaches); generated-shell `@template_version` stamping + `shell.status` + non-destructive `gen.shell --diff` + upgrade guide; and PROOF-03 0-human release-as automation. Non-blocking debt: TELEM-04 Side B vacuity (deferred), compat-prose (not-a-bug). Validated across Phases 129-135; full detail in `.planning/milestones/v16.0-REQUIREMENTS.md`.
- ✓ **v17.0 Companion Family Completion** (all 20 v1 requirements: DECOUPLE-01..06, SIGRA-01..03, CHIME-01..03, THREAD-01..03, FAMILY-01..05) — completed the package family by decoupling core from all companion compile references, extracting `sigra`, `chimeway`, and `threadline` into standalone independently-versioned Hex packages, proving chimeway sigra-free and threadline telemetry-only, adding family drift/telemetry discipline, and publishing core-first to live Hex packages with companion floors bumped to `~> 0.2`. Validated across Phases 136-141; full detail in `.planning/milestones/v17.0-REQUIREMENTS.md`.
- ✓ **v18.0 Release Integrity & Automated Package Operations** (all 15 v1 requirements: RELG-01..03, AUTO-01..03, PREF-01..03, MIRR-01..03, STAT-01..03) — made release infrastructure a first-class product surface: path-specific Release Please gates, non-canceling publish/proof workflow semantics, guarded CI Hex publishing with exact-ref recovery, exact-version published-core clean-room proof, doctor-owned fresh-router loading, iOS mirror-token preflight/backfill guardrails, decoupled native proofs, and text/JSON/live release-status DX. Validated across Phases 142-146; audit passed; full detail in `.planning/milestones/v18.0-REQUIREMENTS.md`.
- ✓ **Phase 147 Arc, Fixture, and Showcase Foundation** (ARC-01..03, SHOW-01..04) — preserved the v19 showcase → v20 Native Controls Pack 1 → later capture/device, commerce/paywall, operator dashboard, and offline-sync/native-storage thread; classified SEED-002 as strategic capability breadth input and SEED-003/004 as release-infrastructure carryovers; shipped a deterministic reset foundation and first-screen showcase hub with route-owner/support labels and honest offline/native proof boundaries. Validated in Phase 147; full detail in `.planning/phases/147-arc-fixture-and-showcase-foundation/147-VERIFICATION.md`.
- ✓ **Phase 148 Demo App Brand & Fixture Direction** (BRAND-01..04) — locked Crosswake-owned showcase framing, served the real Crosswake lockup from the example host, fixed AdminPilot/Fieldserv/LearnLoop as distinct fictional app brands, encoded fixture-density briefs, and verified root brand rendering, distinct styling, mobile containment, focus, and support-label honesty. Validated in Phase 148; full detail in `.planning/phases/148-demo-app-brand-fixture-direction/148-VERIFICATION.md`.
- ✓ **v19.0 Showcase Apps & Capability Map** (all 31 v19 requirements: ARC-01..03, SHOW-01..04, BRAND-01..04, SAAS-01..04, FIELD-01..04, LEARN-01..04, CAPMAP-01..04, PROOF-01..04) — shipped the Crosswake-owned showcase hub, AdminPilot/Fieldserv/LearnLoop product lanes, deterministic reset/proof, generalized route-tour collateral, support-truth claim guards, capability map, and v20 Native Controls Pack 1 handoff. Validated across Phases 147-152.1; audit passed; full detail in `.planning/milestones/v19.0-REQUIREMENTS.md`.
- ✓ **v22.0 Phase 167 Documentation and Pull-Request Reconciliation** (DOC-01..03) — aligned
  public documentation with executable owners, preserved the parked first-adopter lane without
  transferring authority, and gave every retained pull request an explicit verified disposition.
  Exact adoption-authority tuples and blob-bound closeout receipts fail closed. Validated in Phase
  167; full detail in the quality-ratchet-release workstream verification.

- ✓ **v23.0 Phase 169 Diagnostic Legibility** (MSG-01..03, MSG-06, FID-02) — a failing release
  scanner check's own verbatim `detail` now reaches the maintainer instead of a generic "missing
  check IDs" list; `:unverifiable` became a first-class status with OS exit 3, distinguishing
  "never ran" and "terminated early" from "never defined"; duplicate-display-name detection was
  widened to every job producer and six version-welded names retired; the exit-code contract is
  pinned against doc drift across six entry points. Validated in Phase 169 (4/4 must-haves, run
  live, not from SUMMARY claims); one non-blocking dead-code/vacuous-test warning (WR-01) carried
  forward. Full detail in the quality-ratchet-release workstream verification.

### Active

None selected. The next milestone's scope is chosen by `$gsd-new-milestone --ws quality-ratchet-release`. Carried-forward v27 debt is in the [debt disposition](workstreams/quality-ratchet-release/milestones/v27.0-closeout/debt-disposition.md); the v26 debt was closed by FIX-01..07. Parked adopter and historical release limits remain unchanged.

<details>
<summary>Earlier v20 candidate scope — frozen by the first-adopter ADR</summary>


- [ ] **v20.0 Native Controls Pack 1** — ship the typed control-contract seam (`Bridge.push/3`, one typed denial, generated host-owned fallbacks, closed-vocabulary guard), prove it with menu/action-button as the first genuinely-new native control, migrate haptics onto the seam, promote share/notification_token proof, and land the SEED-003 iOS mirror fix that gates every future native release.
- [ ] **Native-control support truth** — expose platform, route mode, shell-version, proof-posture, package-ownership, and rebuild-requirement truth for every v20 capability.
- [ ] **Proof posture for v20 controls** — keep deterministic source/contract tests merge-blocking and reserve simulator/device evidence for advisory lanes unless it becomes repeatable in CI.

</details>

### Out of Scope

- Universal UI abstraction across all screens — it conflicts with the project thesis that runtime ownership should be explicit and per-route.
- LiveView rendering native widgets directly — it would over-couple the library to unstable or private rendering internals.
- Generic "wrap your app in a WebView" positioning — it hides the architecture boundaries Crosswake is supposed to clarify.
- Shipping a broad capability catalog in `v3.0` — this milestone should decide what belongs where before implementing many new families.
- RevenueCat adapter — StoreKit and Play Billing established the first-party provider-adapter shape in v3.7; third-party aggregation remains deferred until first-party seams harden.
- Generic plugin-bus semantics for native or companion integrations — Crosswake must preserve typed, bounded, route-local seams.
- Desktop packaging as a near-term arc driver — it remains a later extension after the mobile-first companion posture is mature.
- Magical offline guarantees — offline behavior must stay explicit about cacheability, local ownership, and reconciliation.
- First-party push delivery guarantees in v3.9 — this milestone ships token binding and open-routing readiness.
- Notification action registries that bypass route policy — notification actions may carry typed refs, but route activation still flows through manifest-known routes, RouteGate, and backend auth.
- **(v7.0 Threadline anti-scope)** Threadline as an APM/observability platform, an OpenTelemetry replacement or generic distributed tracer, a logging framework, or a generic plugin/event bus — it emits `:telemetry`, sets Logger metadata, and coexists with OTel; it does not replace them.
- **(v7.0 Threadline anti-scope)** PII in the audit ledger, library-owned audit tables, async-telemetry-driven durable writes, full-session replay, cross-service thread propagation, actor-identity reverse lookup, and a LiveDashboard UI in v1 (deferred to a separate `crosswake_dashboard` package).
- **(v20.0 anti-scope)** A native `toast` capability — iOS ships no toast primitive, so a cross-platform native toast overclaims by construction; toasts are LiveView-owned UI.
- **(v20.0 stopped candidate)** A native `alert`/`confirm` bridge family — the branded,
  focus-trapped, route-tour-provable LiveView modal remains the current required fallback. Reversal
  requires physical-iPhone proof, a demonstrated blocker on an active adopter route, and an
  explicit maintainer roadmap decision.
- **(v20.0 anti-scope)** A review-prompt control — both Apple and Google forbid CTA-triggered prompts and provide no completion signal, so any API reporting success would be a lie. Deferred until it can ship as a `requested`-only reply with no button.
- **(v20.0 anti-scope)** An importable `Crosswake.UI.*` component tier — fallbacks are generated, host-owned, verbatim-copy files (the `gen.offline_ui` precedent). Crosswake ships no component library.
- **(v20.0 anti-scope)** A `crosswake_controls` companion package — controls have no external SDK or optional dependency to gate, which is what defines a companion; they stay in core alongside the v3.1 command families.
- **(v20.0 anti-scope)** Host-registrable, dynamic, or high-frequency bridge commands — the command vocabulary stays closed and named, enforced by a merge-blocking structural guard.

## Context

Crosswake is a published Elixir/Phoenix OSS library (`crosswake 0.2.11` verified on Hex, iOS and Maven at v23 close; first published as 0.1.0 on 2026-05-29) with iOS and Android as first-class targets and web remaining part of the architecture. As of v11.0 the native shell cores are also published — iOS via the SwiftPM mirror `szTheory/crosswake-shell-core-ios` and Android via Maven Central (`io.github.sztheory:crosswake-shell-core-android`) — all three registries lockstep-versioned, so a generated shell resolves and builds outside the monorepo. As of v17.0 the project is a **package family**: `rulestead`, `rindle`, `sigra`, `chimeway`, and `threadline` are extracted to standalone, independently-versioned `crosswake_*` Hex projects on explicit seams — `sigra`, `chimeway`, and `threadline` are live on Hex; at the v17 boundary `rulestead` and `rindle` were unpublished; v23 later verified `crosswake_rulestead 0.1.1` and `crosswake_chimeway 0.1.2` directly — (core never compile-depends on a companion; module names preserved so adoption is unchanged), with a drift-tested cross-package compatibility matrix and `Crosswake.Telemetry` published as a stable, semver-governed event contract. As of v18.0 the package-family release path is guarded and inspectable: core/native publish gates are path-specific, Hex publish/recovery is exact-ref and CI-owned, companion clean-room proof derives real floors from Hex, the iOS `v0.2.0` mirror gap has a verify-first guarded backfill path, and `mix crosswake.release.status` exposes local/JSON/live release truth without making live registry checks mandatory. The authoritative architecture stance is route policy plus a capability ladder: plain Phoenix/LiveView, LiveView inside a native shell, bounded bridge components, cached/degraded routes, offline islands, native screens, and specialized native SDK adapters. Supporting research emphasizes that the project should not market itself as React Native for Phoenix, Flutter for Phoenix, a generic WebView wrapper, or a "write once, run anywhere" platform.

The maintainer's OSS house style materially constrains the project. Install truth matters as much as the happy path. Public support claims must be narrow and documented. Proof lanes, docs-contract checks, release automation, and recovery-conscious publishing are part of the product. Generated host code, optional dependencies, and operator-facing diagnostics should be intentional and honest.

The strategic source of truth for the current sequence is `.planning/MILESTONE-ARC.md`. `v3.2` activated commerce, `v3.4` proved the mocked commerce archetype, `v3.5` locked the companion pattern, `v3.6` made the surface inspectable by operators, `v3.7` added StoreKit/Play Billing adapter seams, `v3.8` expanded Sigra into auth/session machinery, `v3.9` added the Chimeway notification seam, and `v5.0` shifted the architecture to standalone publishable shell packages to solve the "eject trap".

After v19.0, Crosswake has a product-shaped proof surface with three fictional showcase lanes. Its earlier native-controls/breadth sequence was stopped by the first-adopter ADR. The governing priority remains one real Phoenix application on one physical iPhone, with explicit route ownership and one honest offline mutation island. Adopter execution remains parked on its recorded external gate; Android breadth, new controls/companions, dashboard and generic sync/storage remain frozen.

v27.0 landed the v25 and v26 candidate work on GitHub `main` (PR #242, merge `d12aed75`) with CI green, so the "candidate-only, not yet delivered" notes below are historical. The recovery checkout and the `/private/tmp` candidate flow ended; work lands through PRs branched from `main`. One local copy remains by design: the `crosswake-integration-191` clone, whose remote-tracking tips are not yet backed up. The Phase 192 review residue is tracked in SEED-025. Simulator proof still grants no physical-iPhone or adopter claim.

v26.0 hardened the v25 twin, guards, host seam and doctor as a planning closeout: the v26 commits sit on the same `/private/tmp` candidate (HEAD `a53fbef`, over `50fcd57`) and are not yet delivered. twin-05 passed once against the frozen commit; it is still simulator-only and grants no physical-iPhone or adopter claim. About 30 review warnings remain open across 184–188, two hand-offs to Phase 188 (guard pin raise, Swift G4 baseline failure) were not done, and all five Nyquist validation files are drafts.

v25.0 closed the iOS host setup and bounded reference twin as a planning closeout: all product code sits in one `/private/tmp` candidate (eight commits over `da53c54`) and is not yet delivered. The twin is simulator-only with five disclosed fidelity limits; it grants no physical-iPhone or adopter claim. Review findings remain open in 181 (13), 182 (10) and 183 (8); Nyquist validation is partial.

v24.0 closed bounded maintenance work with exact-source proof and retained history. It did not merge PR #238 or publish a package. Its audit preserves six debt records, missing historical-reader inputs, two unknown earlier assertion failures and warm-cache proof limits. Whole-project LOC, whole-milestone commit range and delivery actor attribution were not retained; do not infer them.

## Constraints

- **Tech stack**: Phoenix-native Elixir library with mobile shell integration seams — the product must extend Phoenix instead of replacing it with a JS-framework-first abstraction.
- **Platform**: iOS and Android remain library targets; Android is unfrozen only for proof and parity of existing contracts: generated-shell, Maven, JVM-hermetic and shared-vector evidence. Claims stop at JVM-hermetic proof; no emulator, device or feature-breadth claim is made until a later phase produces that evidence. Android never gates the first adopter's physical-iPhone proof. Re-freeze if Android work delays any iOS gate by more than one milestone.
- **Architecture**: Per-route runtime ownership is authoritative — solution design cannot collapse into single-runtime ideology.
- **Security**: Route allowlists, origin allowlists, capability allowlists, active-route checks, and cache sensitivity need explicit defaults.
- **Proof posture**: Deterministic CI, example-host verification, docs integrity, and release discipline are required early.

## Key Decisions

### v27 decisions

- **✓ Good:** Back up and restore-test every copy before deleting anything; classify by content, not by name (Phase189).
- **✓ Good:** Fix the carried warnings in a durable clone of the candidate before landing, and build the integration branch in a separate durable clone (Phases190–191).
- **✓ Good:** One-use, plain-language `allow`/`hold` gates bound to the displayed PR and head; merge commits only; no admin merge or force push (Phases192–193).
- **✓ Good:** End the recovery-checkout freeze and move to branch-from-`main`-and-PR (AGENTS.md "How changes land") (Phase193).
- **⚠️ Revisit:** FIX-01..03 successors have no recurring gate on `main`; integration-191 clone ref tips are unbacked; the SEED-025 credential-masking gap in CI failure output.
- **— Pending:** Release PR #236 decision; physical signed-iPhone run; first adopter's sanitized route handoff.

### v26 decisions

- **✓ Good:** One pinned git funnel for every twin probe call, plus a read-only preflight that cannot consume a run root (Phase184).
- **✓ Good:** Checks fail on an empty or below-pin scope instead of passing (Phase185).
- **✓ Good:** Freeze at the existing HEAD with no squash; fix no twin-off-path warning before the freeze; one sentinel-guarded run with no retry to green (Phase188 D-01, D-04, D-12..D-20).
- **⚠️ Revisit:** Run tooling: empty-scope privacy scan passes (188 WR-01), gate labels without negative self-tests (WR-08), the unpinned gate `g()` helper; 185 WR-02 timeout read as registry gone; 187 WR-02 provenance on nested hosts; stale guard pin 249 vs 253.
- **— Pending:** 186 WR-01 (LOOP-07 residual) owner decision; CW-REQ-A/D reopen triggers; delivery of candidate commits; physical signed-iPhone run.

### v25 decisions

- **✓ Good:** One compile-only `:ios_host` declaration and managed-output ownership replace hand patches (Phase179).
- **✓ Good:** A central versioned `host_commands:` registry with the per-route manifest as sole authority, additive schema 1.2.0, Android byte-unchanged (Phase181).
- **✓ Good:** Loopback http only behind an explicit local mode with `NSAllowsLocalNetworking`, never `NSAllowsArbitraryLoads`; production stays HTTPS-only (Phase182).
- **✓ Good:** The twin fails closed on a dirty or untracked candidate rather than binding a working-tree digest; one run per run root (Phase183).
- **⚠️ Revisit:** The clean-tree probe ignores git index flags and does not pin `core.filemode` (183 WR-01/02); an edit reverted during a run is undetected (disclosed).
- **— Pending:** Twin join against the Phase179 identity projection (deferred by user decision); delivery of candidate commits; physical signed-iPhone run.

### v24 closeout decisions

- **Validated:** Complete maintenance proof against the exact governed merge object with the existing verifier and actual hosted checkout/policy; keep head-only and source-less evidence distinct.
- **Validated:** Apply one authorized planning closeout, retain original phase/requirements/audit paths, and skip prohibited recovery-checkout Git writes.
- **Retained debt:** Use the independent cross-reference for empty SUMMARY requirement arrays; preserve missing historical-reader comparisons, epoch-specific fixtures and unknown failure causes until their actual inputs become available.
- **Pending:** PR #238 remains open/unmerged; fresh milestone scope is unselected. No package release or adopter promotion follows from planning closeout.

### Phase 177 maintenance decisions

- Maintain the attested merged source in an independent qualified clone; preserve all 119 captured rows privately. Conflicting or textually safe historical overlays do not prove their consumer behavior should be restored.
- Exercise the four current generic release paths and deny all 78 unavailable historical selectors before effects. Keep missing historical reader comparisons unproven; do not claim retirement or equivalence.
- Compare the complete allowlisted queue metadata on a read-only refresh, including PR head/base and failed checks even when timestamps stay equal. Triage records a next action and transfers no release authority.

### v23 closeout decisions

- Derive versions and source refs from approved inputs; retain independent package identities. Validated by ordinary 0.2.11 exact-public proof.
- Require the actual host installer before doctor. Validated by PR #237's ten hosted pairs.
- Preserve irreversible failures and consumed attempts; use fresh candidates and bindings for forward delivery. Validated by separate core and companion releases; REL-10 remains breached.
- Carry scoped authorization through related operations and use plain check/result/cause/next-action updates. Recorded in the retrospective and Phase 175 learnings.
- Archive with six explicit record acknowledgements, stale historical fingerprints and partial Nyquist coverage disclosed. Accepted exception, not a fully passed milestone.


| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Use one ordinary compile-only Mix declaration for iOS build projections; preserve host-owned native edits through managed ownership and explicit repair | Runtime credentials and hand-edited generated settings must not become extra authorities; interrupted or conflicting writes fail closed | Validated in Phase179 candidate `96e5a63`: 3/3 IOS requirements; independent declaration Xcode matrix, three proof leaves and closed audits |
| Keep maintenance acceptance bound to the exact hosted merge object and full current policy | Tree equality or a head-only check cannot prove the governed source; preserve raw index bytes and private capture integrity | Validated in Phase 178: local 9/9, required CI 48/48; one-use delivery remains consumed |
| Center the product on route policy and runtime ownership | The strongest research convergence is that explicit boundaries are the core differentiator | Validated in Phase 1 |
| Use a capability ladder instead of a single runtime model | Different route classes need different ownership and honesty about tradeoffs | Validated in Phase 2 via manifest/runtime/support contract layering |
| Treat bridge contracts as bounded, semantic, and versioned | High-frequency or ad hoc cross-runtime messaging would make the system fragile and misleading | Validated in Phase 3 via typed bridge envelopes, manifest-backed allowlists, and fail-closed native channels |
| Keep offline claims route-local, typed, and narrow | Cached read-only degradation and local-first mutation need visibly different contracts and proof posture | Validated in Phase 4 via cache/island contracts, replay outcomes, doctor posture, and the hermetic offline proof lane |
| Keep deep desktop packaging and broad adapters out of v1 core | Early scope should validate the contract surface before expanding platform breadth | — Pending |
| Make diagnostics, proof lanes, and docs part of the public contract | This matches the maintainer's proven OSS style and reduces support ambiguity | Further validated in Phase 2 |
| Require executable verification instead of manual UAT for automatable claims | Reproducible unit, integration, E2E, device, and artifact checks scale to a solo maintainer and protect future changes; CI is reserved for recurring contract value | Adopted for all active work on 2026-07-31 |
| Treat checked-in example hosts as the public proof artifact class | Proof-backed support needed a stable adopter-facing install path | Validated in Phase 5 |
| Treat exemplars as proof artifacts, not product templates | The milestone should validate architectural fit without turning Crosswake into a starter-app bundle | Validated in Milestone v2.0 |
| Adopt hermetic-vs-advisory CI split as the default pattern for environment-sensitive proof surfaces | Keeps PRs fast and required without dishonest claims about environment-sensitive proof | Validated in v3.3+ |
| Keep companion evidence non-authoritative unless backend contracts explicitly promote it | Device media evidence cannot mark media available, and client auth signals cannot become authority. | Validated in v3.5 |
| Keep Sigra auth authority backend-owned across session, handoff, step-up, and auth-return flows | Prove session authority projection without letting shell/native/provider evidence directly promote authority | Validated in v3.8 |
| Extract `ActivationCoordinator` and `BridgeChannel` into standalone SPM/Maven dependencies | Generating full shell logic resulted in an "eject trap" and significant boilerplate; moving to standalone artifacts ensures clean dependency management | Validated in v5.0 (Phases 76-78) |
| Adopt reactive streams for shell state exposed to host UI | Massive Java-style callbacks create boilerplate traps; reactive APIs improve developer ergonomics | Validated in v5.0 (Phase 77) |
| Use a Language-Learning / Flashcard app as the v6.0 adoption-evidence exemplar | A study loop with offline sessions rigorously stress-tests the `Crosswake.Offline` island philosophy | Validated in v6.0 (Phases 86-90) |
| Enforce `ContentPack` casting at the route-policy boundary | Guarantees manifest builders always interact with struct shapes, not loose maps | Validated in v6.0 (Phase 84) |
| Use `binary_id` primary keys for the demo Flashcard domain | Keeps the schema offline-sync-friendly for reconciliation | Validated in v6.0 (Phase 86) |
| Stub a mocked Playwright E2E offline-sync flow for the v6.0 closeout gate | Allowed the CI workflow to execute without a full network-toggling harness | Resolved in v12.0 — replaced by real UI-driven IndexedDB outbox/reconnect/Ecto proof plus compile gate |
| Keep the brand system self-contained in `brandbook/` and excluded from the Hex package | Brand assets are repo/docs concerns, not installable library code; exclusion keeps the published package lean | Validated in v9.0 (Phase 106) |
| Shift brand UAT left into an automated suite instead of manual checkpoints | Manual brand verification doesn't scale and tolerated a real overflow defect; automation catches regressions deterministically | Validated in v9.0 (COLL-05) — caught + fixed a mobile-overflow bug |
| Split brand CI into a required deterministic gate + an advisory render tier | Pixel/font-level checks differ across Linux-CI vs macOS; only deterministic checks should block merges | Validated in v9.0 — `brand-structural` required, `brand-visual` advisory |
| Treat planning-milestone version tags (vN.0) as distinct from the Hex 0.x release axis | The repo ships on Hex at 0.x; planning milestones track work tranches, not installable versions | ✓ Good — CHANGELOG + MILESTONE-ARC.md document the distinction |
| Make `tokens.css` the single generated source for font + dimension, not just color | Typography and spacing were a second hand-maintained source that could silently drift from the brand contract | Validated in v10.0 (Phase 107) |
| Distribute tokens by verbatim copy + `<link>` rather than a build-step import | Honors the zero-build/no-Tailwind host posture; one documented path with no duplicate palettes to drift | Validated in v10.0 (Phase 107, NORM-03) |
| Enforce drift prevention with a browser-free structural CI check, not a render diff | Deterministic across Linux-CI/macOS and merge-blocking, consistent with the v9.0 required-vs-advisory split | Validated in v10.0 (Phase 109, PROOF-01) |
| Treat the v5.0 standalone-package thesis as built-but-undistributed until external consumption is proven | The native cores are extracted but unpublished; `gen.shell` references nonexistent deps, so the "no eject trap" claim only holds inside the monorepo | ✓ Resolved in v11.0 — 0.1.2 published to all three registries; clean-room proof + parity guard make external consumption real and permanent |
| Lockstep one version across Hex + iOS tag + Maven via release-please `linked-versions`, not independent per-platform versioning | Generated code ties the three coordinates together; a single bump must keep them resolvable and version-matched | Validated in v11.0 (Phase 110, LOCK-01/02) — one release-please run shipped 0.1.2 to all three |
| Distribute iOS via splitsh-lite subtree mirror to a dedicated repo, not a binary target or monorepo subdir | SwiftPM SE-0292 forbids monorepo-subdir consumption; `.binaryTarget` can't declare deps; source mirror with semver tags is the honest path | Validated in v11.0 (Phase 110, PUB-01) |
| Gate the irreversible first publish behind a validated-upload→DROP fire-drill + dry-run + GPG/namespace preflight | Maven Central releases are immutable and SwiftPM tags must not move; a burned version is unrecoverable | Validated in v11.0 (Phase 110, PUB-03) — fire-drill caught real bugs before the live cut |
| Derive every generated native dep version from `Application.spec(:crosswake)[:vsn]` at generate-time, no literal | One source of truth keeps generated coordinates resolvable and version-matched as the package bumps | Validated in v11.0 (Phase 111, GEN-01) |
| Make external consumption a permanent guarantee via a merge-blocking `generator_coordinate_parity` check (sibling to the v10.0 `brand-structural` gate) | A clean-room proof is point-in-time; a structural CI guard keeps the eject-trap thesis honest forever | Validated in v11.0 (Phase 111, PROOF-02) |
| Treat proof-honesty regressions as structural CI problems, not review-only risks | The v6/v8 offline-sync path looked green while bypassing app-owned state; proof lanes need source-contract guards that ban known fabrication shapes | Validated in v12.0 (Phases 113-114) |
| Make closeout verification fail closed on explicit phase contracts and evidence-backed ledgers | Vacuous globs and bare ledger attestations let historical validation debt pass as green | Validated in v12.0 (Phase 115) |
| Treat v13.0 as adopter-confidence proof before feature breadth | Repo truth after v12.0 showed strong substrate and real offline proof, but the public proof path still had stale docs, quick-start drift, checked-in native host drift, and no screenshot/video/simulator collateral | Validated in v13.0 — proof-path drift, native evidence classification, browser route-tour collateral, advisory native collateral, and troubleshooting shipped |
| Prioritize runtime contract confidence before new feature breadth | Post-v13 repo inspection found bridge protocol truth split between `1.1.0` Elixir contract posture and `1.0.0` manifest/example/native proof paths; adopters need one canonical runtime contract before more capability or provider breadth | Validated in v14.0 (shipped 2026-06-21) |
| Reconcile bridge-protocol compatibility to a single `>=` min-version-floor semantics across Elixir and native (change native exact-equality to negotiate by floor) | Elixir already negotiates by `>=` while native demands exact equality — the mismatch is what silently denies valid additive-bump requests; every mature wire protocol (Postgres, TLS 1.3, Phoenix Channels `vsn`) abandoned exact-match | ✓ Validated in v14.0 (COMPAT-01) — native exact-equality eliminated on all axes; discriminating vec-014 (1.1.0 > 1.0.0) proves the floor on iOS + Android |
| Make one canonical Elixir constant the sole bridge-protocol literal, with `mix crosswake.contract.gen` rendering every non-Elixir surface (generate-and-diff, not an IDL/protobuf pipeline) | Three version strings + a small command vocabulary don't justify a codegen/IDL redesign; a committed canonical file + diff-check is the disciplined, proportionate choice that kills the multi-surface drift | ✓ Validated in v14.0 (CANON-01..03) |
| Prove the contract behaviorally inside the reusable native packages from one shared committed vector file, not only in checked-in example hosts | Example-host proof drifts and doesn't exercise the published packages; one `bridge_contract_vectors.json` driving Elixir + Swift + Kotlin makes a single version bump fail all three suites | ✓ Validated in v14.0 (NTEST-01..04) — iOS XCTest (advisory) + Android JUnit (merge-blocking), no simulator/emulator |
| Keep contract drift guards browser-free and deterministic (ExUnit + generate-and-diff + doctor parity check), reserving native-toolchain lanes as advisory | Consistent with the established hermetic-vs-advisory split; deterministic guards block merges while macOS/native lanes stay advisory | ✓ Validated in v14.0 (GUARD-01..04) |
| Establish the companion-extraction pattern on 2 packages (`rulestead`, `rindle`) before propagating to the rest | Prove the irreversible-publish + compatibility surface on the lowest-risk wedge and the cleanest generalization first; sigra is most entangled and threadline consumes the others — a fast follow-on, not the proof | ✓ Validated in v16.0 (EXTRACT-01..07) — recipe captured for sigra/chimeway/threadline |
| Version companions independently (NOT in the core lockstep `linked-versions` group); core never compile-depends on a companion | A package family advances per-package on `@behaviour` seams + optional deps (Ash/Oban/Swoosh/Nerves shape); lockstep would force false coupling | ✓ Validated in v16.0 (EXTRACT-05, COMPAT-03) — drift-tested compatibility matrix instead of lockstep |
| Preserve companion module names on extraction (`Crosswake.Companions.Rulestead`/`.Rindle`) so the sole adopter touch-point (`config :crosswake, :companions, [...]`) is unchanged | Extraction must be non-breaking — adopters get the new package boundary for free without a code migration | ✓ Validated in v16.0 (EXTRACT-02/07) |
| Fail closed on enabled-but-missing companion: doctor `:error` + RouteGate `:dependency_missing` denial, runtime-only `Code.ensure_loaded?` | An absent optional dependency must deny visibly, never crash or silently degrade; module-eval `ensure_loaded?` would reintroduce a stale-recompile footgun | ✓ Validated in v16.0 (COMPAT-01, EXTRACT-03/04) — stdlib-only AST guards keep it merge-blocking |
| Ship `Crosswake.Telemetry` as a semver-governed public event contract with an opt-in PII-safe logger; core never auto-attaches | Telemetry is the operator-dashboard prerequisite and must be a stable, documented surface, not an incidental emission; auto-attach would impose a logging policy on adopters and risk PII | ✓ Validated in v16.0 (TELEM-01..04) — TELEM-04 Side B vacuity deferred (divergence structurally near-impossible) |
| Make companion release ops 0-human on the success path (staleness guard + auto-cleanup PR + failure alert + parametric required-check registration) | A package family multiplies post-publish toil; the only human gate that should remain is merging the Release PR (the irreversible publish go/no-go) | ✓ Validated in v16.0 (PROOF-03) — recipe Step 12f points future companions at the automation |
| Gate release publishing by exact component/path identity, not aggregate Release Please outputs | Companion-only releases must never be able to publish core Hex, iOS mirror, or Android Maven artifacts; aggregate `releases_created` is too broad for a package family | ✓ Validated in v18.0 (RELG-01/PREF-03) — path-specific gates plus scanner fixtures guard the workflow |
| Keep package publishing CI-owned on the happy path, with exact-ref/idempotent recovery only | Maintainer-run `mix hex.publish` does not scale across six packages and makes recovery state ambiguous; immutable registries require exact refs and already-live handling | ✓ Validated in v18.0 (AUTO-01..03) — guarded helper, package-scoped recovery refs, and already-live preflight shipped |
| Treat live registry checks and real mirror mutation as optional/advisory external state | Normal CI should stay deterministic and read-only; registry availability and maintainer secret scope are real-world state, not local graph truth | ✓ Validated in v18.0 (MIRR-01..03, STAT-03) — mirror preflight/backfill path exists; release status live probes are explicit warnings |
| Use v19.0 to build product-shaped showcase apps before v20.0 native-control breadth | The highest-impact DX gap is not only missing controls; Crosswake needs vivid, seeded examples that make route ownership, offline posture, native pressure, diagnostics, and capability gaps obvious before the next controls pack is implemented | ✓ Validated in v19.0 — showcase hub, three product lanes, capability map, route-tour proof, and v20 handoff shipped |
| Give each v19 demo app a separate fictional micro-brand inside the Crosswake showcase | Realistic product identities and dense fixtures make the examples feel credible while keeping Crosswake positioned as the parent route-policy/runtime-contract system, not one demo app | ✓ Validated in v19.0 — AdminPilot, Fieldserv, and LearnLoop are distinct fictional brands under Crosswake-owned framing |
| Treat SEED-002 as a multi-milestone arc, not a single broad feature dump | Native controls, capture/device flows, and commerce/paywall support should be sequenced from examples and capability-map evidence so Crosswake stays Phoenix-first and does not drift into a generic WebView plugin catalog | ✓ Validated in v19.0 — v20 Native Controls Pack 1 is scoped from capability-map evidence; capture/device and commerce breadth remain later arcs |
| Bind complete repository proof to a fixed nine-stage facade and an exact supported-code commit | Maintainers need one deterministic clean-checkout result without widening `mix verify`, hiding independent failures, leaking diagnostic state, or letting evidence commits redefine supported code | ✓ Validated in Phase 166 — all nine stages pass for `d8e7cf3f7f62a88e92bd5f25e7bfa7c77869442b`; recurring CI parity remains contract-tested |
| Keep current support and adoption authority in executable owners with exact tuple membership | Generated prose must not become a second source of truth, and partial field validation can admit impossible support combinations | ✓ Validated in Phase 167 — `Crosswake.CapabilityMap` owns the claim layers and only three canonical seven-field tuples are admitted |
| Keep release-only PRs open and hand Phase 168 a blob-bound, reversible closeout | Phase 167 reconciles ambiguity but cannot exercise the irreversible publication approval reserved for the release-candidate phase | ✓ Validated in Phase 167 — PRs 57, 115, 146, and 147 remain explicitly deferred and Phase 168 owns their exact-candidate gate |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-10-24 after v27.0 milestone; next milestone unselected. v26 debt closed by FIX-01..07; v24/v23 debt and parked adopter gates remain unchanged.*
