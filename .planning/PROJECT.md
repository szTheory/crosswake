# Crosswake

## What This Is

Crosswake is a Phoenix-native open-source library for shipping iOS and Android apps from Phoenix applications without pretending one runtime should own every screen. It lets Phoenix teams declare per-route runtime ownership so server-centric screens can stay LiveView, local-first workflows can live in offline islands, and device-heavy flows can move into disciplined native screens or adapters.

## Core Value

Make runtime boundaries explicit so Phoenix teams can ship credible mobile apps without hiding the tradeoffs between LiveView, offline, and native ownership.

## Current State

**Phase 46 (Sigra Auth Contract-Only Slice) complete — `2026-05-31`.** Crosswake now has contract-only Sigra auth truth without shipping handoff, ceremony, passkey, OAuth, or refresh-token machinery. `Crosswake.Companions.Sigra.Contracts` defines typed `AuthContext`, backend-only `SessionAuthorityLane`, `StepUpChallenge`, closed MFA vocabulary, auth-age normalization, and evidence rejection for authority-smuggling keys. Route policy accepts `auth_min_level` and `requires_recent_auth`, manifests serialize those predicates, `RouteGate.evaluate/4` fails closed with sanitized `:step_up_required` denials when backend auth context is absent, weak, or stale, and doctor/support-matrix surfaces report contract-only auth posture. Verification passed 20/20 must-haves; full suite green at 494 tests after code-review remediation.

**Phase 45 (Rindle In-Tree Companion, Mock Example, And Proof) complete — `2026-05-31`.** `Crosswake.Companions.Rindle` is the second concrete in-tree companion and proves the companion seam generalizes beyond route gating: it satisfies all six `Crosswake.Companion` callbacks, fails closed via `Code.ensure_loaded?(Rindle)` when the optional dependency is absent, and reports media contract-only state without inventing route-gating authority. `examples/phoenix_host` now includes a pure-Elixir `/media/proof` lane (`MockCapture` → `ReconciliationInbox` → `MediaProjection` → `MediaLaneLive`) that enforces stable idempotency, replay detection that ignores transient correlation IDs, and backend-owned availability (`:queued`/`:uploaded`/`:scanning` remain non-authoritative; only explicit backend verification produces `:available`). Phase 45 adds `phase45-proof.yml` with hermetic merge-blocking proof and advisory `MIX_INCLUDE_RINDLE=1` dependency-present proof. Verification passed 6/6 must-haves; 431 hermetic tests green after code review remediation.

**Phase 38 (Companion Seam Contract) complete — `2026-05-30`.** v3.5's foundation: the `Crosswake.Companion` behaviour (6 locked callbacks, D-05), the typed `Crosswake.Companion.State` struct (D-09), and a direct `{:telemetry, "~> 1.0"}` runtime dep, generalized *conceptually* from `Crosswake.Commerce` (commerce untouched, D-12). `mix crosswake.doctor` now runs each enabled companion's `validate_dependency/0` inside the `[:crosswake, :companion, :validate_dependency]` telemetry span and emits the fail-closed `:error` finding `companion.dependency_missing` (D-04). Proven by a hermetic `phase38_companion_contract_test.exs` (SC#1/SC#2/SC#4). 356 full-suite tests green.

**Shipped `v3.4 Commerce Archetype Proof` on `2026-05-29`** (Phases 33-37, 8 plans, 8 tasks). v3.4 turned v3.2's commerce vocabulary into a copy-able adopter lane: a runnable mocked paywall corridor in `examples/phoenix_host` that proves purchase → reconciliation → entitlement → UI end-to-end with **zero provider-SDK code**, reusing the shipped `Crosswake.Commerce.Contracts`/`Reconciliation` and the Phase-21 reconciliation modules. Three `:subscription_default` corridor routes are declared with canonical `crosswake.commerce` DSL; `CrosswakeExample.Commerce.MockStorefront` is a pure-Elixir, provider-neutral evidence emitter documented as the StoreKit/Play Billing swap target; mock evidence flows through `ingest_evidence/2` → `project_snapshot/2` → `derived_state/1` into a four-state `PaywallEntryLive` (fail-closed `:stale` mount); a merge-blocking hermetic proof (`phase34_paywall_corridor_proof_test.exs`) drives all four states, the `:pending` → `:granted` transition, and the mock-boundary fence (`authority_mutation_allowed_from_evidence?/1 == false`); and `guides/commerce.md` gained a Paywall Corridor Walkthrough locked to the shipped example via a hybrid string-presence + `function_exported?/3` docs-contract test. All 14 requirements validated; milestone audit PASSED (14/14 req · 5/5 phase · 7/7 integration · 2/2 E2E). 352 full-suite tests green.

<details>
<summary>Earlier milestone history (v3.3, v3.2, v3.1)</summary>

Crosswake shipped `v3.3 Release Readiness` on `2026-05-29` (`crosswake 0.1.0` live on hex.pm via the release-please pipeline).

Crosswake shipped `v3.2 Commerce And Entitlement Seams` on `2026-05-27`.

`v3.2` delivered provider-neutral commerce route/corridor declarations with canonical `commerce.corridor.*` denial vocabulary, explicit entitlement lifecycle lane semantics that keep device/storefront evidence non-authoritative, a runnable Phoenix-owned reconciliation inbox/projection example, merge-blocking-vs-advisory commerce support truth wired into doctor diagnostics, layered reviewer/storefront guides anchored to canonical `SupportMatrix` accessors, a hermetic 14-test CI proof lane separated from a scheduled-only advisory provider lane, and machine-enforced SUMMARY frontmatter parity (`requirements-completed:`) backed by an ExUnit merge-blocking test. Tech-debt closure (Phase 25) hardened the parity test with presence assertion (WR-01) and loud-fail malformed-shape detection (WR-02).

`v3.1 Native Capabilities and Bridge Expansion` shipped on `2026-05-27`, delivering the first official low-frequency native capability families (`haptics`, `share`, `app_info`, `deep_link`, `permissions.status`, `notification_token`, and `file_picker`) through the bounded bridge thesis, with route-local enforcement, doctor/support truth, and CI-backed proof across Elixir, checked-in iOS shell code, and Android JVM bridge tests.

</details>

## Current Milestone: v3.5 First-Party Companions

**Goal:** Lock a reusable Phoenix-native companion-seam pattern, prove it generalizes across two real companions (rulestead gating + rindle media), and ship the auth-context contract that unblocks the rest — all in-tree, all fail-closed, all proven by the established hermetic+advisory + docs-contract template.

**Scope:** Wedge + first generalization. Builds explicit integration *seams* to existing szTheory libraries — not features from scratch.

**Target features:**
- **`Crosswake.Companion` behaviour** generalized from the commerce seam (behaviour + typed contracts + optional-dep `validate_dependency/0` fail-closed handling + `[:crosswake, :companion, …]` telemetry); companions live in-tree under `lib/crosswake/companions/<name>/` for v3.5 (separate-package extraction deferred).
- **Rulestead gating seam (full):** route-policy `gated_by` DSL + build-time manifest binding / runtime local-snapshot value split; `:gate_denied`/`:kill_switch_active` fail-closed denials injected into `RouteGate` (kill switches short-circuit first); OpenFeature-shaped explainability; doctor category + runtime gate-state support-matrix truth (`gated`/`rolling_out`/`killed`).
- **Rindle media seam (full):** `UploadGrant`/`CaptureEvidence`/`MediaObject` contracts + a backend-owned non-authoritative reconciliation vocabulary mirroring commerce (device evidence → backend verify → `:available`); pure-Elixir mock swap-target; the generalization proof that the pattern isn't flag-specific.
- **Sigra auth contract-only slice:** `AuthContext` + `SessionAuthorityLane` (backend-set only) + route auth predicates (`auth_min_level`/`requires_recent_auth` → fail-closed `:step_up_required`). Contract + route gate only; handoff/step-up/passkey machinery deferred to v3.6.
- **Proof & docs:** hermetic merge-blocking lanes that compile *without* the optional dep and assert fail-closed + advisory lanes with it present; `guides/companions.md` locked by docs-contract tests.

Research synthesis: `.planning/research/v3.5-companions-SUMMARY.md`. Strategic source of truth: `.planning/MILESTONE-ARC.md` (v3.5).

**Deferred to v3.6+ (sequenced, not built in v3.5):** chimeway seam (token + deep-link-to-route resolver, *not* first-party delivery), full sigra machinery (handoff/step-up/passkey), threadline audit capstone. Cross-dependency DAG: sigra-contract unblocks all → rindle leads → chimeway needs sigra → threadline needs all three.

Other strategic-arc candidates, per `MILESTONE-ARC.md`:

- **Operator truth and diagnostics expansion (v3.6)** — richer route/capability inspection, doctor checks, support matrices, and advisory device lanes for the widened surface.
- **Provider adapters (ADPT-01/02/03)** — first-party StoreKit and Play Billing adapters that consume the v3.2 commerce contracts as canonical input and can graduate the v3.4 advisory `purchase_intent`/`restore_intent` proof lane to merge-blocking via the 4-condition `promotion_path` in `phase23-proof.yml`.
- **Archetype proof lanes (v3.7)** — re-run adopter-shaped pressure (subscription/paywall, notification-driven companion workflows, richer media/scanning) against the new surfaces.

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
- [x] **RECN-01** Host apps can follow a minimal Phoenix-owned reconciliation inbox example for purchase, restore, webhook, and support evidence. Validated in v3.2 (Phase 21; traceability normalized in Phase 24).
- [x] **RECN-02** Host apps can follow idempotency guidance that uses provider-aware identity rather than transient device correlation IDs. Validated in v3.2 (Phase 21; traceability normalized in Phase 24).
- [x] **RECN-03** Host apps can project one authoritative entitlement snapshot from verified evidence and expose stale, pending, denied, and granted states clearly. Validated in v3.2 (Phase 21; traceability normalized in Phase 24).
- [x] **SUPP-04** Doctor and support-matrix output identify missing commerce prerequisites, unsupported native corridors, stale entitlement snapshots, and native rebuild requirements. Validated in v3.2 (Phase 23).
- [x] **SUPP-05** Public commerce guidance explains reviewer/storefront sandbox setup, restore expectations, fallback behavior, and rough edges without implying provider adapters have shipped. Validated in v3.2 (Phase 23).
- [x] **SUPP-06** Maintainers can run merge-blocking hermetic commerce proof while treating StoreKit/Play Billing simulator, device, or storefront checks as advisory until adapter milestones ship. Validated in v3.2 (Phase 23).
- ✓ **v3.3 Release Readiness** (all 28 requirements: META-*, VER-01, LOG-*, REL-*, HEX-*, PRF-*) — `crosswake 0.1.0` published to hex.pm + HexDocs via the release-please pipeline. Validated across Phases 26–32; full detail in `.planning/milestones/v3.3-REQUIREMENTS.md`.
- ✓ **v3.4 Commerce Archetype Proof** (all 14 requirements: PWAL-01/02, MOCK-01/02/03, WIRE-01/02/03, STATE-01, PROOF-01/02/03, DOCS-01/02) — a runnable mocked paywall corridor in `examples/phoenix_host` proving purchase → reconciliation → entitlement → UI end-to-end with zero provider-SDK code, plus a merge-blocking hermetic proof and a docs-contract-locked walkthrough. Validated across Phases 33–37; full detail in `.planning/milestones/v3.4-REQUIREMENTS.md`.

### Active

**v3.5 First-Party Companions** — scoped requirements in `.planning/REQUIREMENTS.md` across five categories: **COMP** (companion seam contract + optional-dep + in-tree convention), **GATE** (rulestead gating, kill switches, fail-closed denial, explainability, gate-state truth), **MEDIA** (rindle upload-grant/reconciliation seam), **AUTH** (sigra contract + route auth predicates), **PROOF/DOCS** (hermetic+advisory lanes, docs-contract parity, companions guide). Prior per-milestone requirements are archived under `.planning/milestones/v*-REQUIREMENTS.md`.

### Out of Scope

- Universal UI abstraction across all screens — it conflicts with the project thesis that runtime ownership should be explicit and per-route.
- LiveView rendering native widgets directly — it would over-couple the library to unstable or private rendering internals.
- Generic "wrap your app in a WebView" positioning — it hides the architecture boundaries Crosswake is supposed to clarify.
- Shipping a broad capability catalog in `v3.0` — this milestone should decide what belongs where before implementing many new families.
- Store-specific billing implementation in `v3.2`/`v3.4` — these milestones operationalize the core seam and prove the mocked archetype, while provider adapters and storefront SDK code remain deferred to v3.6 (ADPT-01/02/03).
- Generic plugin-bus semantics for native or companion integrations — Crosswake must preserve typed, bounded, route-local seams.
- Desktop packaging as a near-term arc driver — it remains a later extension after the mobile-first companion posture is mature.
- Magical offline guarantees — offline behavior must stay explicit about cacheability, local ownership, and reconciliation.

## Context

Crosswake is a published Elixir/Phoenix OSS library (`crosswake 0.1.0` live on hex.pm since 2026-05-29) with iOS and Android as first-class targets and web remaining part of the architecture. The authoritative architecture stance is route policy plus a capability ladder: plain Phoenix/LiveView, LiveView inside a native shell, bounded bridge components, cached/degraded routes, offline islands, native screens, and specialized native SDK adapters. Supporting research emphasizes that the project should not market itself as React Native for Phoenix, Flutter for Phoenix, a generic WebView wrapper, or a "write once, run anywhere" platform.

The strongest early app archetypes are Phoenix-backed SaaS portals, subscription apps with selective native flows, and local-first study/training/content apps. As of v3.4 the subscription/paywall archetype now has a runnable, copy-able mocked corridor in `examples/phoenix_host` (no provider SDK). The initial value should come from route policy, shell/runtime contracts, offline/native boundary design, and honest support claims rather than wide native capability breadth. Companion integrations are relevant context: `sigra`, `rulestead`, `rindle`, `chimeway`, and `threadline` are plausible first-party companions; billing, identity-provider, and other vendor-heavy integrations should stay deferred or example-only until the core contract is stable.

The maintainer's OSS house style materially constrains the project. Install truth matters as much as the happy path. Public support claims must be narrow and documented. Proof lanes, docs-contract checks, release automation, and recovery-conscious publishing are part of the product. Generated host code, optional dependencies, and operator-facing diagnostics should be intentional and honest.

The strategic source of truth for the current sequence is `.planning/MILESTONE-ARC.md`. `v3.2` activated commerce as operational seam work; `v3.4` proved the mocked commerce archetype lane end-to-end. The next arc candidates are first-party companions (v3.5), operator/diagnostics expansion (v3.6), and provider adapters (v3.6).

## Constraints

- **Tech stack**: Phoenix-native Elixir library with mobile shell integration seams — the product must extend Phoenix instead of replacing it with a JS-framework-first abstraction.
- **Platform**: iOS and Android are first-class in v1 — runtime contracts must respect app review, permission, billing, and OTA compatibility realities.
- **Architecture**: Per-route runtime ownership is authoritative — solution design cannot collapse into single-runtime ideology.
- **Security**: Route allowlists, origin allowlists, capability allowlists, active-route checks, and cache sensitivity need explicit defaults — mobile/runtime boundaries increase the blast radius of vague trust assumptions.
- **Proof posture**: Deterministic CI, example-host verification, docs integrity, and release discipline are required early — support claims must be proven, not aspirational.
- **Scope**: Native capability breadth must be phased — `v3.0` should lock contract and packaging truth before wider capability delivery.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Center the product on route policy and runtime ownership | The strongest research convergence is that explicit boundaries are the core differentiator | Validated in Phase 1 |
| Use a capability ladder instead of a single runtime model | Different route classes need different ownership and honesty about tradeoffs | Validated in Phase 2 via manifest/runtime/support contract layering |
| Treat bridge contracts as bounded, semantic, and versioned | High-frequency or ad hoc cross-runtime messaging would make the system fragile and misleading | Validated in Phase 3 via typed bridge envelopes, manifest-backed allowlists, and fail-closed native channels |
| Keep offline claims route-local, typed, and narrow | Cached read-only degradation and local-first mutation need visibly different contracts and proof posture | Validated in Phase 4 via cache/island contracts, replay outcomes, doctor posture, and the hermetic offline proof lane |
| Plan iOS and Android as first-class, web-inclusive targets | Mobile credibility is the project goal, while Phoenix web remains part of the architecture | Validated in Phase 2 via explicit support matrix and compatibility baselines |
| Keep deep desktop packaging and broad adapters out of v1 core | Early scope should validate the contract surface before expanding platform breadth | — Pending |
| Make diagnostics, proof lanes, and docs part of the public contract | This matches the maintainer's proven OSS style and reduces support ambiguity | Further validated in Phase 2 via `mix crosswake.doctor`, generated support docs, and compatibility guidance |
| Treat checked-in example hosts as the public proof artifact class and generated hosts as secondary verification | Proof-backed support needed a stable adopter-facing install path rather than host-local scaffolding alone | Validated in Phase 5 |
| Use adopter-shaped stress profiles as the first v2 milestone | Realistic product pressure should reveal the next core fixes before Crosswake expands official native capability breadth | Validated in Milestone v2.0 |
| Treat exemplars as proof artifacts, not product templates | The milestone should validate architectural fit without turning Crosswake into a starter-app bundle | Validated in Milestone v2.0 |
| Publish one adopter-profile matrix plus a shared example-host lane contract before exemplar implementation | Locking profile vocabulary, non-goals, and artifact boundaries first reduces scope drift in Phases 7-10 | Validated in Phase 6 |
| Prove the Phoenix SaaS lane as one authenticated LiveView-first approvals slice with one bounded haptics seam | The first exemplar needed credible product pressure without drifting into offline, transfer-first, or native-screen breadth | Validated in Phase 7 |
| Route-pattern deep links in checked-in shells must match manifest paths with dynamic segments | The SaaS approval route exposed that exact-path matching denied valid `/saas/.../:id` deep links and broke proof-backed shell activation | Validated in Phase 7 |
| Sequence post-v2 capability expansion as contracts-first milestone work | Locking taxonomy, packaging, commerce seams, and support truth before feature breadth reduces plugin-sprawl and support dishonesty risk | Validated through Phases 11-18 |
| Ship native capabilities only when they remain low-frequency, typed, and route-local | v3.1 proved value in bounded affordances while avoiding continuous client authority | Validated in Milestone v3.1 |
| Split proof lanes by evidence class when emulator/device proof slows iteration | Android JVM bridge truth closed quickly in CI once separated from emulator-backed connected tests | Validated in Phase 18 closeout |
| Operationalize commerce as a backend-owned seam before provider adapters | Apple and Google purchase ecosystems both require native storefront evidence plus backend verification/lifecycle truth, matching Crosswake's Phase 13 contract posture | Validated in Milestone v3.2 — provider-neutral corridors, lifecycle lane vocabulary, and reconciliation example all shipped without any provider adapter code |
| Use canonical `commerce.corridor.*` denial vocabulary as the single source of truth across route policy, manifest, doctor, support matrix, and guides | Provider-specific denial codes would force every consumer of support truth to know provider trivia; a canonical taxonomy lets the same data stitch through `SupportMatrix.commerce_corridors/0`, doctor `commerce_summary`, and merge-blocking docs tests | Validated in v3.2 (Phases 19+23) — parity tests lock taxonomy across all surfaces |
| Split commerce CI proof into hermetic merge-blocking and scheduled-only advisory lanes | Provider simulator/device/storefront proof is environment-sensitive and would block PRs unfairly; the hermetic lane stays fast and required while advisory proof remains visible at runtime via the doctor `promotion_path` detail | Validated in v3.2 (Phase 23) — `phase23-proof.yml` two-job split with `continue-on-error: true` on the advisory job |
| Decompose audit-flagged phases before execution rather than executing oversized phases | The v3.2 milestone-audit flagged Phase 22 as the original "support + review + proof" container; splitting into Phase 23 (runtime closure) and Phase 24 (traceability hardening) before execution kept verification scopes sharp and avoided cross-stream drift | Validated in v3.2 — both decomposed phases shipped clean verification |
| Treat SUMMARY-frontmatter traceability automation as merge-blocking infrastructure | RECN-01/02/03 were initially flagged `partial` purely because of artifact-shape inconsistency (`requirements:` vs canonical `requirements-completed:`); the gap closed by adding a parity ExUnit test wired into the merge-blocking CI job, not by changing behavior | Validated in v3.2 (Phase 24; hardened in Phase 25) — parity test now asserts presence (WR-01) and fails loudly on malformed shapes (WR-02) |
| Adopt machine-enforced SUMMARY-frontmatter parity as the default automation level for adopter-facing traceability across future milestones | Phase 24/25 demonstrated that `requirements-completed:` parity (parser + presence + malformed-shape detection) is the right level of automation — heavier than a docs convention, lighter than a full traceability matrix tool. Graduation candidate surfaced 2026-05-27 from Phase 24/25 LEARNINGS | — Default for v3.3+ |
| Adopt hermetic-vs-advisory CI split as the default pattern for environment-sensitive proof surfaces | Phase 23's two-job split (hermetic merge-blocking + advisory provider/storefront/device lane with documented 4-condition `promotion_path`) keeps PRs fast and required without dishonest claims about environment-sensitive proof. Should be the default for future provider/device/storefront-sensitive surfaces (StoreKit adapter, Play Billing adapter, push delivery integration, etc.). Graduation candidate surfaced 2026-05-27 | — Default for v3.3+; reused in v3.4 `phase34-proof.yml` |
| Verify release-surface deliverables with hermetic ExUnit tests + a per-concern CI proof lane rather than manual UAT | Phase 30's hex-page checks (README/guide link hygiene, docs grouping, package allowlist, tarball contents, publish dry-run) are all mechanically checkable; automating them caught 3 real bugs manual review missed and made the checks repeatable on every PR. Reading config via `Mix.Project.config()` keeps tests in sync with `mix.exs`. Graduation candidate for release/packaging surfaces | Validated in Phase 30 — `hex_page_test.exs` + `hex-page-proof.yml`, PR #1 |
| Prove a new product archetype as a mocked, hermetic, copy-able adopter lane before any provider-SDK code | v3.4 needed to make the v3.2 commerce vocabulary genuinely copy-able without taking on StoreKit/Play Billing integration risk; a pure-Elixir `MockStorefront` + four-state LiveView + merge-blocking hermetic proof + docs-contract-locked walkthrough proves the full purchase → reconciliation → entitlement → UI lane end-to-end and leaves a labeled swap target for real adapters | Validated in Milestone v3.4 — 14/14 requirements, audit PASSED (7/7 integration, 2/2 E2E), zero provider-SDK code |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `$gsd-transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `$gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check -> still the right priority?
3. Audit Out of Scope -> reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-31 — Phase 46 complete: Sigra contract-only auth context, route predicates, fail-closed `:step_up_required` RouteGate enforcement, and doctor/support truth satisfy AUTH-01 and AUTH-02 without claiming deferred Sigra machinery.*
