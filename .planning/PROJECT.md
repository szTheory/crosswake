# Crosswake

## What This Is

Crosswake is a Phoenix-native open-source library for shipping iOS and Android apps from Phoenix applications without pretending one runtime should own every screen. It lets Phoenix teams declare per-route runtime ownership so server-centric screens can stay LiveView, local-first workflows can live in offline islands, and device-heavy flows can move into disciplined native screens or adapters.

## Core Value

Replace host-owned generated shell code (`ActivationCoordinator`, `BridgeChannel`) with standalone SPM/Maven dependencies, enforcing strict delegate-based customization to eliminate the "eject trap" and boilerplate for adopters.

## Current State
- **v12.0 CI Honesty & Real-E2E Sweep — SHIPPED + archived 2026-06-18.** The offline-sync proof now exercises the real IndexedDB outbox and reconnect flush path, the E2E proof lane is merge-blocking with structural honesty guards, the closeout verifier fails closed on invalid phase contracts and bare ledger evidence, the historical validation-ledger debt is represented by evidence-backed ledgers or an accepted exception, and v8.0 document truth is reconciled. Full detail in `.planning/milestones/v12.0-ROADMAP.md`.
- **v11.0 Release & Distribution Truth — SHIPPED + archived 2026-06-17.** The v5.0 standalone-package thesis is now genuinely consumable: `crosswake 0.1.2` is live on Hex, Maven Central, and the SwiftPM mirror from a single lockstep release-please run; `gen.shell` emits resolvable version-matched coordinates, proven by a clean-room CI lane and guarded by a permanent parity check. Full detail in `.planning/milestones/v11.0-ROADMAP.md`.
- **Active:** **v13.0 Adopter Confidence & Native Evidence** — Phase 118 completed command-verified quick start/adoption truth and the DRIFT-02 guard. Remaining work starts at Phase 119: native evidence classification, then durable collateral/troubleshooting.

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

## Latest Completed Milestone: v12.0 CI Honesty & Real-E2E Sweep

**Goal:** Make Crosswake's offline-sync proof and closeout gates genuinely honest — the offline-sync E2E exercises the app's real reconnect→flush path against Ecto (not a test-injected scratch variable), that lane actually gates merges, and the validation-ledger closeout passes on real artifacts rather than vacuous globs.

**Why now:** The install path is real (v11.0), but a repo-truth sweep found that several "green" proof surfaces don't prove what they claim. v6.0 shipped a mocked Playwright E2E that hid a compile break; v8.0 added real `setOffline()` toggling but the test still injects a mutation into a test-only `window['crosswake_offline_mutations']` and manually fires the sync — the app's own IndexedDB outbox and reconnect flush (`study_session_live.ex:31`: "here we mock it") are never exercised. The E2E lane runs on PRs but is not declared merge-blocking. Separately, the closeout verifier was tightened (quick task done) but the backlog it now flags — missing `VALIDATION.md` files for archived phases — was never cleaned up. And the docs disagree with themselves about v8.0.

**Target features:**
- **Real reconnect-driven offline-sync E2E** — replace the `window[]` scratch-var fabrication and the app-level sync mock with a genuine flow: mutate while offline → persist to IndexedDB → app itself flushes the outbox on reconnect → assert against the real Ecto backend (with idempotency-key correctness).
- **Merge-blocking E2E lane** — make the offline-sync E2E a genuine required status check (`merge-blocking-*` naming + branch-protection), so a fake-green or failing E2E can no longer merge.
- **Validation-ledger closeout cleanup (LEDG-01)** — create the missing `VALIDATION.md` files the now-strict gate flags (v3.6 48/49/52/53, v3.8 54-58, v3.9 62/63), flip stale deferrals to resolved, and reconcile STATE.md so `mix closeout.verify` passes honestly.
- **v8.0 doc-truth reconciliation** — reconcile `v1.0-MILESTONE-AUDIT.md` (scores v8.0 0/10) and the missing MILESTONES.md v8.0 entry against PROJECT.md's SYNC-01/02/03 ✓ claims; establish a single authoritative truth.

**Key context:** This is internal CI/test-honesty hardening, not new product features — but the reconnect-flush fix touches real demo-app code (`offline_study.js`, `study_session_live.ex`), not just the test. The branch-protection toggle has historically been harness-blocked in this environment (a human step), so the milestone ships the workflow/naming + a scripted/documented protection path even if the final toggle needs the maintainer. `LEDG-01` here is the GSD closeout-verifier debt (distinct from the v7.0 Threadline `LEDG-*` product requirements, which shipped). Phase numbering continues from v11.0 (last phase 111).

## Current Milestone: v13.0 Adopter Confidence & Native Evidence

**Goal:** Make Crosswake visibly trustworthy to a skeptical Phoenix SaaS developer by turning the now-real install, release, offline, and native proof into a runnable, current, visual, honestly labeled adopter-confidence path.

**Why now:** v11.0 made the standalone native packages actually consumable, and v12.0 made the offline-sync proof honest. The remaining trust gap is adopter-facing: docs and quick-starts drift from current release truth, checked-in native hosts do not yet tell a clean published-coordinate story, and there is no durable screenshot/video/simulator collateral that lets a maintainer or prospective adopter see Crosswake working end-to-end.

**Target features:**
- **Proof-path drift cleanup** — resolve or explicitly route `TODO-001`; fix README/CHANGELOG/quick-start/adoption drift; make the public quick start runnable against current `0.1.2` package/version truth and v12's real IndexedDB outbox/reconnect behavior.
- **Native evidence truth** — reconcile checked-in iOS/Android hosts with the published-coordinate story, or clearly label them as local-development proof; do not let stale local package references masquerade as adopter install truth.
- **Seeing-is-believing collateral** — capture screenshots, recordings, and durable artifacts for the Phoenix host plus iOS/Android shells exercising at least one LiveView, bounded bridge, offline-island, and native-screen path.
- **Support-truth guide set** — tighten route-policy guidance, troubleshooting/rough edges, web-to-mobile migration docs, ExDoc/README guide maps, and support matrices so adopters can tell what is proven, advisory, deferred, or out of scope.

**Done enough:** `TODO-001` is resolved or explicitly removed from the public proof path; README/CHANGELOG/quick-start/adoption docs match the `0.1.2` published truth and v12 IndexedDB-outbox reality; checked-in native hosts either prove published coordinates or are clearly labeled local-development proof; screenshots/recordings and CI artifacts show the Phoenix host plus iOS/Android shells exercising at least one LiveView, bridge, offline-island, and native-screen path; simulator/device evidence is labeled advisory unless explicitly promoted.

**Key constraints:** This milestone is proof-path consolidation, not new capability breadth. Simulator/device/native evidence is valuable collateral, but remains advisory unless this milestone creates a repeatable support contract strong enough to promote it. DASH-01 and NTV-01 stay deferred unless the v13 proof path proves they are necessary for adopter confidence.

**Deferred candidates carried forward:** DASH-01 (surface offline adoption/eviction metrics to the deferred `crosswake_dashboard`) and NTV-01 (native iOS/Android disk-space budgets) remain tracked but unscheduled. Companion package extraction and new capability breadth remain tempting, but should not outrun the adopter-confidence proof path.

**Open follow-up:** `MIRROR_PUSH_TOKEN` `Contents: write` scope is unexercised (the 0.1.2 iOS mirror was completed out-of-band); it is validated by the first iOS mirror on the next release.

## Requirements

### Validated

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

### Active

- [ ] NATIVE-01: Checked-in iOS and Android hosts either prove published `0.1.2` coordinates or are explicitly labeled local-development proof with no stale coordinate claims.
- [ ] NATIVE-02: Native docs and support surfaces distinguish published-coordinate proof from local-dev proof and do not overstate JVM, emulator, or device evidence.
- [ ] DRIFT-03: Native evidence drift is mechanically guarded.
- [ ] COLL-01: Durable browser route-tour evidence captures Phoenix-owned, bounded bridge, offline-island, and native-screen/route-unavailable paths.
- [ ] COLL-02: Evidence bundles carry explicit manifests, proof classes, source jobs, timestamps, and known limitations.
- [ ] NATIVE-COLL-01: iOS simulator and Android emulator screenshots/recordings are advisory and honestly labeled where available.
- [ ] TROUBLE-01: Troubleshooting and rough-edge docs map doctor findings, denials, route-unavailable states, offline outcomes, and route-owner next actions.

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

## Context

Crosswake is a published Elixir/Phoenix OSS library (`crosswake 0.1.2` live on hex.pm; first published 0.1.0 on 2026-05-29) with iOS and Android as first-class targets and web remaining part of the architecture. As of v11.0 the native shell cores are also published — iOS via the SwiftPM mirror `szTheory/crosswake-shell-core-ios` and Android via Maven Central (`io.github.sztheory:crosswake-shell-core-android`) — all three registries lockstep-versioned, so a generated shell resolves and builds outside the monorepo. The authoritative architecture stance is route policy plus a capability ladder: plain Phoenix/LiveView, LiveView inside a native shell, bounded bridge components, cached/degraded routes, offline islands, native screens, and specialized native SDK adapters. Supporting research emphasizes that the project should not market itself as React Native for Phoenix, Flutter for Phoenix, a generic WebView wrapper, or a "write once, run anywhere" platform.

The maintainer's OSS house style materially constrains the project. Install truth matters as much as the happy path. Public support claims must be narrow and documented. Proof lanes, docs-contract checks, release automation, and recovery-conscious publishing are part of the product. Generated host code, optional dependencies, and operator-facing diagnostics should be intentional and honest.

The strategic source of truth for the current sequence is `.planning/MILESTONE-ARC.md`. `v3.2` activated commerce, `v3.4` proved the mocked commerce archetype, `v3.5` locked the companion pattern, `v3.6` made the surface inspectable by operators, `v3.7` added StoreKit/Play Billing adapter seams, `v3.8` expanded Sigra into auth/session machinery, `v3.9` added the Chimeway notification seam, and `v5.0` shifted the architecture to standalone publishable shell packages to solve the "eject trap".

## Constraints

- **Tech stack**: Phoenix-native Elixir library with mobile shell integration seams — the product must extend Phoenix instead of replacing it with a JS-framework-first abstraction.
- **Platform**: iOS and Android are first-class targets.
- **Architecture**: Per-route runtime ownership is authoritative — solution design cannot collapse into single-runtime ideology.
- **Security**: Route allowlists, origin allowlists, capability allowlists, active-route checks, and cache sensitivity need explicit defaults.
- **Proof posture**: Deterministic CI, example-host verification, docs integrity, and release discipline are required early.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Center the product on route policy and runtime ownership | The strongest research convergence is that explicit boundaries are the core differentiator | Validated in Phase 1 |
| Use a capability ladder instead of a single runtime model | Different route classes need different ownership and honesty about tradeoffs | Validated in Phase 2 via manifest/runtime/support contract layering |
| Treat bridge contracts as bounded, semantic, and versioned | High-frequency or ad hoc cross-runtime messaging would make the system fragile and misleading | Validated in Phase 3 via typed bridge envelopes, manifest-backed allowlists, and fail-closed native channels |
| Keep offline claims route-local, typed, and narrow | Cached read-only degradation and local-first mutation need visibly different contracts and proof posture | Validated in Phase 4 via cache/island contracts, replay outcomes, doctor posture, and the hermetic offline proof lane |
| Keep deep desktop packaging and broad adapters out of v1 core | Early scope should validate the contract surface before expanding platform breadth | — Pending |
| Make diagnostics, proof lanes, and docs part of the public contract | This matches the maintainer's proven OSS style and reduces support ambiguity | Further validated in Phase 2 |
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
| Treat v13.0 as adopter-confidence proof before feature breadth | Repo truth after v12.0 shows strong substrate and real offline proof, but the public proof path still has stale docs, quick-start drift, checked-in native host drift, and no screenshot/video/simulator collateral | Phase 118 resolved proof-path drift; native evidence and collateral remain active in v13.0 |

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
*Last updated: 2026-06-19 — Phase 118 complete; ready for Phase 119 native evidence classification*
