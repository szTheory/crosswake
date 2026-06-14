# Crosswake

## What This Is

Crosswake is a Phoenix-native open-source library for shipping iOS and Android apps from Phoenix applications without pretending one runtime should own every screen. It lets Phoenix teams declare per-route runtime ownership so server-centric screens can stay LiveView, local-first workflows can live in offline islands, and device-heavy flows can move into disciplined native screens or adapters.

## Core Value

Replace host-owned generated shell code (`ActivationCoordinator`, `BridgeChannel`) with standalone SPM/Maven dependencies, enforcing strict delegate-based customization to eliminate the "eject trap" and boilerplate for adopters.

## Current State
- Milestone v10.0 active — Brand Normalization; v9.0 Brand System & Visual Identity shipped + archived
- Phase 108 Consumer Normalization complete (2026-06-14): the example host's SERVED `app.css` + standalone offline page and the `offline_ui` generator (templates + vendored `offline.css`) are rewired onto the semantic `--cw-*` token tier — zero flat palettes, zero primitives, zero `var()` fallbacks, zero hand-declared hex/rgba/font-stacks, no Tailwind in the generated host; the duplicate `assets/css/app.css` was deleted (D-12) and the generator test now pins the token-backed contract. The D-13 render-verify release gate browser-rendered all surfaces in light + dark (Playwright, 9 screenshots in the phase `render/` dir): every text element ≥4.5:1 and every status affordance ≥3:1, with two real AA failures caught and fixed (danger button 3.10:1 → D-06 outlined treatment; offline status-label 4.11:1 → text-default) plus a code-review pass that made card elevation theme-adaptive (`color-mix`). NORM-01/02/04 satisfied (verified 19/19, human sign-off approved). Next: Phase 109 Drift-Prevention Gate.
- Phase 107 Token Source & Distribution complete (2026-06-13): `compile-tokens.js` emits the full token set (font + dimension + color) into `tokens.css` with a byte-identical packaged mirror at `priv/static/crosswake/tokens.css`; one documented distribution mechanism (verbatim copy + `<link>`, `guides/tokens.md`) wired into the `crosswake.gen.offline_ui` generator and the example host. TOKN-04/TOKN-05/NORM-03 satisfied (verified 13/13).

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

## Current Milestone: v10.0 Brand Normalization

**Goal:** Make `brandbook/tokens/tokens.css` the genuine single source of truth for the brand system — consumed by the generator templates and the example host via semantic CSS custom properties — and mechanically forbid drift.

**Target features:**
- Extend the token compiler (`brandbook/tools/compile-tokens.js`) to emit `font.*` and needed `dimension.*` tokens, not just colors, so typography stops being a second source of truth.
- Rewire `examples/phoenix_host` CSS off its duplicated flat palette + inline font stacks onto the semantic token tier (`var(--cw-action-bg)`, `var(--cw-text-default)`…), inheriting dark mode for free.
- Rewire the `priv/templates/crosswake/offline_ui/*.eex` generator templates off Tailwind utility classes (the host carries no Tailwind dependency) onto token-backed CSS referencing the semantic tier; update the generator test contract.
- Add a deterministic drift-prevention structural check (extending the v9.0 `brand-structural` gate) asserting consumers reference tokens and carry no stray hardcoded brand hex.

**Out of milestone:** DASH-01 (dashboard metrics) and NTV-01 (native disk-space budgets) remain deferred siblings, not v10.0 scope.

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

### Active

- [ ] DASH-01: Surfacing offline adoption and eviction metrics to the deferred `crosswake_dashboard`.
- [ ] NTV-01: Extend storage budgets to utilize native iOS/Android bridge commands to calculate available physical disk space.
- [ ] NORM-01: Wire generator templates (`priv/templates/crosswake/offline_ui/*.eex`) and `examples/phoenix_host` CSS onto `brandbook/tokens/tokens.css` as the single source of truth (deferred from v9.0 → v10.0 candidate).

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

Crosswake is a published Elixir/Phoenix OSS library (`crosswake 0.1.0` live on hex.pm since 2026-05-29) with iOS and Android as first-class targets and web remaining part of the architecture. The authoritative architecture stance is route policy plus a capability ladder: plain Phoenix/LiveView, LiveView inside a native shell, bounded bridge components, cached/degraded routes, offline islands, native screens, and specialized native SDK adapters. Supporting research emphasizes that the project should not market itself as React Native for Phoenix, Flutter for Phoenix, a generic WebView wrapper, or a "write once, run anywhere" platform.

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
| Stub a mocked Playwright E2E offline-sync flow for the v6.0 closeout gate | Allowed the CI workflow to execute without a full network-toggling harness | ⚠️ Revisit — mock hid a demo-app compile break; replace with a real run |
| Keep the brand system self-contained in `brandbook/` and excluded from the Hex package | Brand assets are repo/docs concerns, not installable library code; exclusion keeps the published package lean | Validated in v9.0 (Phase 106) |
| Shift brand UAT left into an automated suite instead of manual checkpoints | Manual brand verification doesn't scale and tolerated a real overflow defect; automation catches regressions deterministically | Validated in v9.0 (COLL-05) — caught + fixed a mobile-overflow bug |
| Split brand CI into a required deterministic gate + an advisory render tier | Pixel/font-level checks differ across Linux-CI vs macOS; only deterministic checks should block merges | Validated in v9.0 — `brand-structural` required, `brand-visual` advisory |
| Treat planning-milestone version tags (vN.0) as distinct from the Hex 0.x release axis | The repo ships on Hex at 0.x; planning milestones track work tranches, not installable versions | ✓ Good — CHANGELOG + MILESTONE-ARC.md document the distinction |

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
*Last updated: 2026-06-13 — v10.0 Brand Normalization: Phase 107 Token Source & Distribution complete*