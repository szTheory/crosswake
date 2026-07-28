# Crosswake Milestone Arc

## Arc Thesis

Crosswake has moved from proving the Phoenix-first route-policy substrate to making that substrate credible for production mobile SaaS apps. The next arc should reduce bespoke native, commerce, auth, notification, and operator work without turning Crosswake into a universal UI framework, generic WebView wrapper, or plugin bus.

The planning bias remains **contracts first, proof always**. New breadth should land only when route ownership, typed contracts, support truth, proof lanes, and rough-edge docs land with it.

Strategic planning artifacts follow the same Phoenix/Plug contract posture as runtime seams: required fields are explicit, composable across artifacts, boringly named, and fail closed when required evidence is absent. A missing closeout artifact or vague exception is not treated as success.

The current product-DX arc is **showcase first, controls next**. v19.0 should turn the existing proof-backed substrate into a polished, seeded, click-around showcase across realistic app domains; v20.0 should then ship Native Controls Pack 1 from the capability gaps the showcase exposes. Later milestones should expand into capture/device controls, commerce/paywall productionization, operator dashboard, and offline-sync/native-storage productization in that order unless v19 evidence changes the priority.

## Locked Guardrails

- Per-route runtime ownership remains authoritative.
- Bridge contracts stay semantic, typed, versioned, and low-frequency.
- Capability access stays allowlisted, active-route checked, and fail-closed by default.
- Native screens remain explicit escape hatches rather than silent fallback behavior.
- Offline claims remain narrow and typed; cached read-only behavior is not local-first mutation.
- Entitlement truth remains backend- and Phoenix-owned; device purchase events are reconciliation evidence, not authority.
- Companion integrations remain explicit seams; Crosswake does not become a generic plugin bus.
- Diagnostics, support matrices, proof lanes, release truth, and rough-edge docs are product surface, not cleanup work.

## Durable Lessons

- **Install truth is product truth.** Public value is limited until the Hex package, HexDocs, changelog, and release automation reflect the shipped surface.
- **Showcase truth is product truth.** A production-ready framework needs click-around examples with believable data, not only proof lanes and guides.
- **Mock the provider boundary before shipping provider SDK code.** v3.4 proved a paywall corridor by mocking only the storefront edge while keeping the real reconciliation/projection path.
- **Backend authority must be explicit.** Commerce, Rindle media, and Sigra auth all treat device/client signals as evidence until backend contracts promote them.
- **Hermetic and advisory proof lanes must stay separate.** Merge-blocking proof should be deterministic; device, storefront, simulator, and provider checks stay advisory until promotion criteria are explicit and repeatable.
- **Docs-contract parity is a product guarantee.** Guides that describe doctor/support/denial truth must be mechanically checked against live code.
- **Artifact parity is completion truth.** Verification reports, roadmap status, thread closure, validation ledgers, and archived requirements must be current before a milestone is considered closed.

## Capability Taxonomy

### Core

- Route policy, manifest, compatibility, and support truth
- Capability registry metadata and versioning
- Bounded bridge envelope and command vocabulary rules
- Native screen declaration and activation contract
- Shell diagnostics, doctor checks, proof-lane expectations, and release/support inspection

### Companion

- Commerce and entitlement adapters
- Push and notification delivery integrations
- Media capture, upload, and pack-heavy flows
- Auth and account-security integrations
- Rollout, remote-config, and kill-switch integrations
- Auditability and operator observability integrations

### Example/Docs-Only

- Vendor-specific billing walkthroughs that should not shape core APIs
- Identity-provider-specific examples
- Reviewer/test-account playbooks tied to one provider or storefront
- Mocked adopter lanes that prove the real Crosswake contract path without claiming provider support

### Defer

- Broad real-time media or call SDK integration
- Generic high-frequency bridge surfaces
- Desktop packaging as a near-term arc driver
- Generic sync engine or universal local-first framework claims

## Shipped Milestones

- **v1.0 Route-Policy Substrate** — shipped 2026-05-17. Established route policy, manifest truth, bounded bridge, offline contracts, packs/transfers, checked-in proof lanes, and public guides.
- **v2.0 Adopter Stress Profiles** — shipped 2026-05-19. Validated the substrate against Phoenix SaaS, selective-native, and local-first study/content lanes.
- **v3.0 Capability Contract And Packaging** — shipped 2026-05-20. Froze capability taxonomy, package boundary policy, commerce seam vocabulary, and proof/support rules.
- **v3.1 Native Capabilities and Bridge Expansion** — shipped 2026-05-27. Added low-frequency bounded bridge families: `haptics`, `share`, `app_info`, `deep_link`, `permissions.status`, `notification_token`, and `file_picker`.
- **v3.2 Commerce And Entitlement Seams** — shipped 2026-05-27. Added provider-neutral commerce corridors, entitlement lifecycle contracts, reconciliation example, doctor/support truth, reviewer guidance, and hermetic/advisory proof split.
- **v3.3 Release Readiness** — shipped 2026-05-29. Published `crosswake 0.1.0` to Hex with release-please, package metadata, changelog, and HexDocs path.
- **v3.4 Commerce Archetype Proof** — shipped 2026-05-29. Proved a copy-able mocked paywall corridor through purchase, reconciliation, entitlement projection, UI state, hermetic proof, and docs-contract lock.
- **v3.5 First-Party Companions** — shipped 2026-05-31. Locked `Crosswake.Companion`, Rulestead gating, Rindle media evidence, Sigra contract-only auth predicates, and canonical companion docs/proof parity.
- **v3.6 Operator Truth and Production Diagnostics** — shipped 2026-06-01. Added route/capability/companion/provider/auth/notification readiness inspection, publish-readiness diagnostics, native rebuild/support truth, docs-contract proof, closeout verification, and release/changelog parity without promoting deferred provider/native claims.
- **v3.7 Commerce Provider Adapters** — shipped 2026-06-01. Added first-party StoreKit and Play Billing evidence adapter seams, example-host provider facade swap targets, backend-owned reconciliation proof, and advisory provider-proof promotion criteria.
- **v3.8 Full Sigra Auth and Session Machinery** — shipped 2026-06-02. Added backend-owned session authority, one-time handoff tickets, server-owned step-up ceremony, OAuth/passkey/native auth-return boundaries, sanitized auth telemetry, support/operator truth, and security closeout while keeping provider/device auth proof advisory.
- **v3.9 Chimeway Notification Seam** — shipped 2026-06-03. Added notification seam for token lifecycle, backend token binding, notification-open routing, revocation, and provider diagnostics.
- **v4.0 Production Shell Runtime Line** — shipped 2026-06-04. Hardened generated iOS and Android shells into a documented production runtime line.
- **v4.1 Multi-SaaS Archetype Proof Lanes** — shipped 2026-06-05. Proved subscription commerce, notification re-entry, media/evidence, auth-sensitive admin, and offline/draft workflows via end-to-end hermetic lanes.
- **v5.0 Standalone Publishable Shell Packages** — shipped 2026-06-06. Extracted `ActivationCoordinator`/`BridgeChannel` into standalone SPM/Maven dependencies with a binary Core + hosted-glue strategy and reactive state APIs, solving the "eject trap".
- **v5.1 Adoption Evidence Demo App** — shipped 2026-06-09. Transitioned iOS/Android demo hosts onto the standalone deps with reactive flow/publisher architectures, `RouteDelegate` + capability handshake, and a bounded-bridge proof.
- **v6.0 Adoption Evidence Demo App (Flashcard Cohort)** — shipped 2026-06-09. Flashcard language-learning demo exercising `Crosswake.Offline` end-to-end: `Crosswake.Offline.ContentPack`, `Crosswake.Sync.EventLog` + `mix crosswake.gen.sync`, online LiveView + vanilla-JS offline island over IndexedDB, network-toggling Playwright E2E (closeout used a mocked E2E that hid a compile break — real-network run deferred; see RETROSPECTIVE).
- **v7.0 Threadline Audit Capstone** — shipped 2026-06-09 (Phases 91-98). Cross-boundary `thread_id` propagation (Plug/LiveView/bridge telemetry, zero new deps), opt-in host-owned PII-free append-only Ecto audit ledger (`mix crosswake.gen.audit`), text-only operator surface (`mix crosswake.threadline`), and docs-contract parity. LiveDashboard timeline deferred to a future `crosswake_dashboard` package.
- **v8.0 Offline Sync Hardening and UI Polish** — shipped 2026-06-11 (Phases 99-101). Real network-toggling E2E, advisory runtime storage budgets via `navigator.storage.estimate()`, consolidated brand-aligned `OfflineController` UI.
- **v9.0 Brand System & Visual Identity** — shipped 2026-06-13 (Phases 102-106). Brand audit + WCAG matrix, frozen DTCG design tokens, path-only logo suite, standalone HTML brand book + `BRAND-SPEC.md`, collateral wired into README/ExDoc (brandbook hex-excluded), and shift-left brand UAT into a Playwright CI suite (`brand-structural` required / `brand-visual` advisory).
- **v10.0 Brand Normalization** — shipped 2026-06-14 (Phases 107-109). Made `tokens.css` the single generated source of truth (font + dimension + color) with a packaged mirror and one documented distribution path; rewired the example host + `offline_ui` generator onto semantic `--cw-*` tokens; browser-free `brand-structural` drift gate fails the build on reintroduced brand hex / dropped token refs.

## Strategic Queue

### Active: Showcase Apps & Capability Map (v19.0)

**Status:** ACTIVE — v19.0 starts after v18.0 release integrity made package-family operations trustworthy enough to return to product-shaped DX.

**Objective**
- Build a polished first-screen Crosswake showcase hub with deterministic seeded/fixture data across three domains: SaaS/admin, field-service, and subscription learning/training.
- Give each domain a distinct fictional demo-app identity, AdminPilot, Fieldserv, and LearnLoop, so examples feel product-real without making Crosswake itself look like one vertical app.
- Use the examples to make route ownership, LiveView-first flows, offline/degraded behavior, device-pressure flows, entitlement/paywall pressure, diagnostics, and support truth visible without reading implementation docs first.
- Produce a capability map and v20 handoff that classify current, demoed, missing, and next-pack native controls using Crosswake's route-policy and proof-lane posture.

**Why now**
- v18.0 closed the release-ops trust gap, and v17.0 completed the package family. The highest-impact remaining DX gap is that Crosswake's value is still distributed across proof lanes, guides, and archived milestones instead of obvious, product-shaped examples.
- SEED-002 should now become a sequenced multi-milestone arc: first expose capability pressure through examples, then implement the first native controls pack.
- SEED-003 and SEED-004 remain release-infrastructure carryovers from the package-family arc; they should stay visible for release integrity but must not become v19 showcase headline scope.

**Depends on**
- v18.0 Release Integrity & Automated Package Operations
- v15.0 See It Run
- v16.0/v17.0 companion package-family completion
- SEED-002 Phoenix-first native capability and commerce breadth

**Risk tags**
- `dx-ux`
- `adoption`
- `examples`
- `native-capabilities`
- `proof-truth`

**Key outputs**
- Crosswake-branded showcase hub and three micro-branded domain lanes.
- Resettable, deterministic seeded/fixture data.
- Route-tour and fixture-reset proof.
- Capability map with v20 Native Controls Pack 1 handoff.

### Next: Native Controls Pack 1 (v20.0)

**Status:** NEXT — should follow v19.0 unless the showcase evidence points to a higher-impact wedge.

**Objective**
- Ship the first official Crosswake native-control pack for common low-frequency affordances, likely alert/confirm, menu/action buttons, haptics, share, toast/review prompt, permission status, and notification-token UX integration.
- Keep every control typed, route-local, allowlisted, support-matrix-backed, and proof-lane-classified.

**Why now**
- The user-facing goal is a polished production-ready framework with native controls for common use cases, similar in category coverage to Hotwire Native Bridge Components but expressed through Crosswake's Phoenix-first architecture. v19.0 should provide the evidence and prioritization so v20.0 can implement the controls without becoming a generic plugin bus.

**Depends on**
- v19.0 capability map and showcase evidence
- v14.0 runtime contract confidence
- v16.0/v17.0 package-family seams

**Risk tags**
- `native-capabilities`
- `contract-design`
- `support-truth`
- `ios-android`

### Later: Native Controls Pack 2 — Themable Web Control Equivalents (v21.0)

**Status:** LATER — planted as [SEED-005](seeds/SEED-005-themable-web-control-equivalents.md). Not scheduled; the web-side generalization of v20's host-owned fallback family, to sequence after v20.0 Native Controls Pack 1 lands the control-contract seam and the fallback generator.

**Objective**
- For every control Crosswake delegates to native, also ship a brand-themable, host-owned, generator-emitted WEB equivalent — themable across every design dimension, escape-hatchable to fully custom — generalizing v20's FALL-01/02 from a few CUT controls into a first-class tier.
- Extend the DTCG token system by the five dimensions overlay controls need but the system lacks: elevation/shadow (tint+shadow paired), z-index scale, motion (duration/easing), border-width, and a named padding/gap ramp.
- Build controls on native platform primitives (`<dialog>`, Popover API, `@starting-style`) with non-negotiable WAI-ARIA accessibility as fixed structure and only tokens themable.

**Why now**
- v20 builds the load-bearing primitives — `Bridge.push/3`, the one typed `Shell.Denial` fallback branch, and the `mix crosswake.gen.native_controls_ui` host-owned generator — and already CUT toast/alert as native families precisely because iOS can't brand them. The web equivalent is often the ONLY on-brand surface, and adopters currently hand-roll it (the exact gap Capacitor's unthemable `pwa-toast`/`window.confirm` fallbacks leave open).
- Coherent with the "no importable component tier" brand pillar as long as it stays a generator (host-owned copies) with a versioned, render-agnostic behavior/contract core — not an importable `Crosswake.UI.*`.

**Depends on**
- v20.0 Native Controls Pack 1 (`Bridge.push/3` control-contract seam + FALL host-owned fallback generator)
- v9.0/v10.0 brand token system and the `brand-structural` drift gate
- v19.0 capability map

**Risk tags**
- `native-capabilities`
- `dx-ux`
- `design-tokens`
- `accessibility`
- `scope-discipline`
- `oss-maintenance`

**Key outputs (pre-staged; see SEED-005 for the full research-backed shape)**
- Five new role-named token dimensions (elevation/z/motion/border-width/padding), light/dark-validated.
- A contract-core (versioned, imported) + generated-shell (host-owned) split, with a `mix crosswake.ui.diff` / version-stamped upgrade verb — the answer to the shadcn copy-in upgrade problem.
- The un-brandable trio first — toast, alert/confirm, action-sheet/menu — on platform primitives, APG-accessible, proven in both native-shell and web-fallback paths.
- A two-typed-denial (`unavailable` vs `unimplemented`) + `canX()` capability-probe degradation contract; honesty invariant (web controls must not impersonate native OS chrome).

### Later: Native Navigation Shell (v21.0-or-later)

**Status:** LATER — planted as [SEED-006](seeds/SEED-006-native-navigation-shell.md). Not scheduled; its own milestone (a distinct axis — native app-shell chrome + nav graph, vs the in-page controls of Pack 1/2). Carries an explicit **positioning north-star shift** toward consumer-grade "feels-native."

**Objective**
- Give Phoenix apps a real native tab bar + navigation stack on iOS/Android that hosts Crosswake routes — the route/nav graph declared ONCE in the manifest, rendered per-platform (native = `UITabBar`+nav stack; web = its own idiom, e.g. hamburger) — so apps feel native at the navigation seams, à la Hotwire Native, with content staying server-driven LiveView.
- Ship it as an additive `nav_graph` manifest section + route-level `nav:` hint (modeled on `commerce_corridors`), native chrome in the host-owned generated shell, and a web↔native back-stack sync subsystem.

**Why now**
- Web-rendered nav (esp. hamburger) is the #1 tell that reads as "a website in an app." The native shell today is a thin single-screen host; native nav chrome is the highest-leverage step toward consumer-grade feel. Feasibility is favorable: the library is a pure resolver, rendering is host-owned, and there is zero existing nav container to conflict with — a bounded additive extension.
- Records an explicit positioning shift: **native shell fidelity, not app parity** — "feels native, ships from Phoenix," earned via a new native-shell-proven support tier (never "indistinguishable").

**Depends on**
- v20.0 Native Controls Pack 1 (`Bridge.push/3` seam, shell maturity)
- v9.0/v10.0 manifest + drift-gate machinery
- the host-owned `gen.shell --diff` upgrade rail

**Risk tags**
- `native-capabilities`
- `navigation`
- `positioning`
- `web-native-sync`
- `accessibility`
- `fidelity-ceiling`

**Key outputs (pre-staged; see SEED-006 for the full research-backed shape)**
- Additive ordered `nav_graph` manifest section + route-level `nav:` hint + `validate_nav_graph/2` (compiled + drift-gated, not remotely served).
- Native nav chrome in host-owned generated shell: UIKit `UITabBarController`+per-tab `UINavigationController` (iOS) / single-Activity Jetpack Navigation + `NavigationBarView` (Android); a container-level `ShellNavigation` value alongside the per-screen `ShellPresentation` leaf.
- The web↔native back-stack sync subsystem (native stack authoritative; `push_patch` = native no-op; `navigateUp`/`popBackStack` correctness; deep-link parent-stack synthesis).
- A four-tier honest proof strategy (hermetic-proven → bridge-message-boundary-proven → emulator-evidence → device-only-unprovable) + a native-shell-proven support tier; the positioning brand-doc edits ratified at activation.

### Shipped: Adoption Evidence Demo App (v5.1 → v6.0)

**Status:** SHIPPED — v5.1 (2026-06-09) transitioned demo hosts onto standalone deps; v6.0 (2026-06-09) shipped the Flashcard offline cohort. The demo-app wedge is closed.

**Objective**
- Build a realistic demo app in a representative cohort domain (e.g., field service, health/fitness, or study) with rich seeds, fixtures, and a click-around UI. 
- Automate E2E shift-left CI/CD testing across install, onboarding, and happy-path JTBDs to prove the DX/UX and integration of the v1-v5 substrate.

**Why now**
- The library has a massive amount of core functionality (up to v5.0 standalone shells) but lacks a cohesive, product-shaped proof point. `examples/phoenix_host` is a test harness, not a showcase. We need adoption evidence before seeking real adopters.

**Depends on**
- v5.0 Standalone Publishable Shell Packages

**Risk tags**
- `adoption`
- `dx-ux`
- `e2e-testing`

### Later: CI/CD Performance & Gate Integrity (v21.0-or-later)

**Status:** LATER — planted as [SEED-007](seeds/SEED-007-ci-cd-performance.md). Not scheduled; infrastructure, not product. The `GATE-*` category is **severable and could be pulled forward on its own** — it is a correctness fix, not an optimization.

**Objective**
- Cut CI from ~25,500 runner-seconds (~7 h) per push toward ~2,000–3,000 **with the full proof set intact**, and close three gate-integrity holes the waste is currently hiding.
- Preserve per-phase proof job names, logs, and artifacts — evidence is a product feature here. What consolidates is workflow *files* (39 → ~4) and required *contexts* (22 → few), never the proof jobs themselves.

**Why now**
- Measured 2026-07-28: 75 checks/PR against a peer-median of 9 (plug ships 2); the entire Elixir suite is 1,093 tests in ~43–88 s, so the spend is setup/compile/native, not testing.
- **The cost is queue, not compute.** `phase43`'s merge-blocking proof measured **2,230 s queued / 180 s executed** on `macos-15`; ubuntu peers queue in 4–8 s. **14 of 18 macOS PR jobs never touch an Apple toolchain** — moving them to ubuntu is ~82% of the win.
- Three correctness holes found while measuring: (1) three required check *names* are each emitted by two different workflows, and branch protection matches by string — a red run can be masked by a green one wearing the same name; (2) 20 `:requires_example_host` test files run **only on laptops** (no CI lane runs them), which is how the red gate fixed in #89 sat on `main` unnoticed; (3) leaked `Application.put_env` global state made those same tests pass in a full suite and fail in isolation.
- `strict: true` + 22 required contexts + ~7 h/push taxes every future milestone: draining 6 individually-green PRs took ~2 h of wall-clock.

**Key outputs (pre-staged; see SEED-007 for the full research-backed shape)**
- `OBS-*` baseline instrumentation FIRST (queue-vs-exec timing, cache hit rate, runner-class split) so every later claim cites a before/after.
- `GATE-*` de-duplicate colliding check names; assert **uniqueness** in `check_required_checks_registered.sh`; give `:requires_example_host` a real CI lane and align the local default exclude.
- `RUNNER-*` non-Apple macOS jobs → ubuntu; `timeout-minutes` everywhere (`phase79` runs `xcodebuild` with none — a hang holds a scarce macOS runner for 6 h).
- `CACHE-*` `deps`+`_build` keyed `os|arch|otp|elixir|MIX_ENV|hash(mix.lock)`; Gradle/SPM/Xcode caching. Only 6 of 39 workflows cache anything today and **none cache `deps/`**.
- `CONSOL-*` a `setup-elixir` composite (the setup block is copy-pasted ~40×) + required-check topology.
- `FLAKE-*` `example_host.ex` global-state isolation; delete the nested `mix test` inside an `async: true` module.

**Explicit non-goals**
- Do **not** shard the Elixir suite. At ~12 ms/test, per-shard setup exceeds the execution saved; Ecto measured a 31% regression and zero of 15 surveyed Elixir projects partition.
- Do **not** workflow-level `paths:`-filter a required context — a skipped required check hangs the PR on "Expected — Waiting for status" forever.

**Depends on**
- Nothing. This is infrastructure, not product, and can run in parallel with any product milestone. `GATE-*` is severable and pullable forward on its own.
- Soft prerequisite *for* any milestone expected to land many PRs — `strict: true` + 22 required contexts + ~7 h/push serializes concurrent work into hours.

**Risk tags**
- `ci-ops`
- `dx-ux`
- `release-safety`

### Shipped: Threadline Audit Capstone (v7.0)

**Status:** SHIPPED — 2026-06-09 (Phases 91-98). Cross-boundary `thread_id` propagation (Plug/telemetry, zero new deps), opt-in host-owned PII-free append-only audit ledger with ProvenanceLane (`mix crosswake.gen.audit`), and a text-only operator surface (`mix crosswake.threadline`). LiveDashboard timeline deferred to a future `crosswake_dashboard` package. Canonical definition in `.planning/threads/threadline-audit.md`.

### Shipped: Release Integrity & Automated Package Operations (v18.0)

**Status:** SHIPPED — 2026-07-09 (Phases 142-146). Full scope and archive in `.planning/milestones/v18.0-REQUIREMENTS.md` and `.planning/milestones/v18.0-ROADMAP.md`.

**Objective**
- Make Crosswake's package-family release path automated, path-specific, and honest before new product breadth: core/native lockstep, independent companion releases, published-core clean-room proof, iOS mirror parity, release-as hygiene, and text/JSON release-status diagnostics.

**Why now**
- v17.0 completed the companion family but exposed release-ops truth gaps: the iOS SwiftPM mirror missed `v0.2.0` because the mirror token lacked push scope, the companion clean-room harness stayed advisory-red, and aggregate release gates could make unrelated component releases trigger core/native publish jobs. CI/CD is product surface; these should be fixed before DASH/SYNCP/NTV/capability breadth.

**Depends on**
- v17.0 package-family completion, v16.0 companion release discipline, and v11.0 multi-registry publishing.

**Risk tags**
- `release-integrity`
- `ci-cd`
- `devops`
- `adoption`

**Key outputs**
- Path-specific Release Please gates and static workflow integrity proof.
- Guarded auto-publish train with exact-ref/idempotent recovery.
- Clean-room proof that installs the exact companion under test against its real published-core floor.
- iOS mirror-token preflight and `v0.2.0` backfill path.
- `mix crosswake.release.status [--json] [--live]`.

### Shipped: Standalone Publishable Shell Packages (v5.0)

**Status:** SHIPPED — v5.0 (2026-06-06) extracted the shell into standalone SPM/Maven dependencies and solved the "eject trap".

**Objective**
- Replace host-owned generated shell code (`ActivationCoordinator`, `BridgeChannel`) with standalone SPM/Maven dependencies, enforcing strict delegate-based customization.

**Why now**
- The native seams established in v4.1 are now hard enough to be packaged. To prevent ecosystem fragmentation and the "eject trap", adopters must consume core shell logic as a versioned dependency.

## Dependency Graph

- `v3.6 Operator Truth` precedes broad provider/native claims because it sharpens support truth and proof classification.
- `v3.7 Commerce Provider Adapters` depends on v3.2/v3.4 commerce contracts and benefits from v3.6 diagnostics.
- `v3.8 Sigra Full Auth` depends on v3.5 Sigra contracts and should precede notification-open and audit-heavy flows.
- `v3.9 Chimeway` depends on auth route truth and benefits from v3.6 readiness diagnostics.
- `v4.0 Production Shell Runtime Line` consolidates native runtime truth before broad production archetype proof.
- `v4.1 Archetype Proof Lanes` validates shipped surfaces together.
- `Threadline Audit Capstone` follows the sensitive event surfaces it will audit.
- `v19.0 Showcase Apps & Capability Map` precedes `v20.0 Native Controls Pack 1` because examples should expose the real capability gaps before Crosswake widens official native-control APIs.
- `v20.0 Native Controls Pack 1` precedes capture/device controls, commerce/paywall productionization, operator dashboard, and offline-sync/native-storage productization unless v19 evidence reprioritizes the sequence.
- `Native Controls Pack 2 — Themable Web Control Equivalents` (SEED-005) depends on v20's `Bridge.push/3` control-contract seam and the `gen.native_controls_ui` host-owned fallback generator; it is the web-side generalization of v20's FALL family and can sequence after Pack 1 or interleave with capture/device controls as adopter evidence dictates.
- `CI/CD Performance & Gate Integrity` (SEED-007) depends on nothing — it is infrastructure and can run in parallel with any product milestone. Its `GATE-*` category is severable and could be pulled forward independently (correctness, not optimization). It is a *soft prerequisite* for any milestone expected to land many PRs, since `strict: true` + 22 required contexts + ~7 h/push serializes concurrent work into hours.
- `Native Navigation Shell` (SEED-006) depends on v20 shell maturity + the manifest/drift-gate machinery; it is a DISTINCT axis from the controls packs (native app-shell chrome + `nav_graph`, not in-page controls) and carries an explicit consumer-grade positioning shift. Sequence after v20 Pack 1; independent of SEED-005 (they can proceed in either order).

## Decision Notes

- **2026-05-31:** After v3.5, v3.6 was locked as the operator-truth milestone before provider/native breadth. Provider adapters moved to v3.7 so support, rebuild, proof, and release truth are inspectable first.
- **2026-05-31:** Future queue planning uses `Depends on` and `Risk tags` as planning signals, not marketing labels. These fields make provider, authority, notification, shell-runtime, archetype-proof, and auditability risk visible before planning starts.
- **2026-05-31:** The active milestone closeout contract lives in `.planning/milestones/v3.6-CLOSEOUT.md`; milestone audits remain append-only evidence rather than the live checklist.
- **2026-06-01:** v3.6 closeout archived the roadmap and requirements snapshots in `.planning/milestones/`, promoted `mix closeout.verify` to deterministic closeout truth, and made v3.7 Commerce Provider Adapters the active strategic milestone.
- **2026-06-01:** v3.7 closeout archived provider-adapter roadmap, requirements, audit, and phase evidence; v3.8 Full Sigra Auth and Session Machinery is now the active strategic candidate.
- **2026-06-02:** Milestone-next-step assessment after v3.8 selected v3.9 Chimeway as the highest-leverage next wedge. The shipped reality already has notification-token and permission snapshots, support/operator truth, and Sigra route auth; the missing adopter job is backend token binding, revocation, and notification-open route resolution that still respects route policy and auth. Production shell runtime hardening stays next after Chimeway because it is important support truth but unlocks less new adopter value than notification re-entry.
- **2026-06-05:** Following the completion of v4.1, the strategic priority shifted to v5.0 "Standalone Publishable Shell Packages" to address the "eject trap" and lock down the native shell runtime interfaces via SPM and Maven before expanding broader day-2 operational features.
- **2026-06-09:** v5.0 (standalone packages), v5.1 + v6.0 (adoption-evidence demo apps) all shipped. With those wedges closed, the Threadline Audit Capstone (v7.0) becomes the active strategic milestone — the day-2 operational viability layer the arc always positioned last because it consumes the now-stable commerce, auth, notification, media, and offline surfaces. Scope locked narrow and honest: bespoke `thread_id` correlation (no OTel dep), opt-in PII-free append-only ledger with ProvenanceLane, text-only operator surface; LiveDashboard UI deferred to a separate `crosswake_dashboard` package.
- **2026-06-14:** Milestone next-step assessment after v10.0 (this doc was stale — still marked v7.0 "Active"; reconciled here with v7.0→v10.0 shipped). Verdict: Crosswake is feature-mature for its scope but distribution-incomplete. The single highest-leverage next wedge is **Release & Distribution Truth** — the v5.0 standalone-package thesis is built but undistributed (Hex stuck at `0.1.0`; `gen.shell` default emits nonexistent deps; native cores unpublished, no publish CI), so the "no eject trap" claim only holds inside the monorepo. Recommendation: ship what's built (publish native packages, lockstep versioning, rewire `gen.shell`, clean-room build proof) before any new feature/companion/capability breadth, which would be overbuilding on an undistributed base. Ordering after: CI-honesty/real-E2E sweep, then onboarding/docs once the install path is real. Detail in `.planning/threads/release-distribution-truth.md`.
- **2026-07-09:** After v18.0 closed release integrity, the next arc is locked as **Showcase Apps & Capability Map** before native-control breadth. The maintainer's stated goal is a production-ready Phoenix mobile framework with great DX, seeded click-around examples across app/business domains, and common native controls comparable in category coverage to Hotwire Native bridge components while preserving Crosswake's route-policy thesis. v19.0 builds the showcase and capability map; v20.0 should ship Native Controls Pack 1; later milestones should sequence capture/device controls, commerce/paywall productionization, operator dashboard, and offline-sync/native-storage productization.

## Support Truth Requirements

Any milestone in this arc that widens Crosswake's public surface must define:

- capability support matrix updates by route mode, platform, shell version, and companion/provider readiness
- explicit denial and fallback behavior
- doctor coverage for missing permissions, unsupported capabilities, stale provider state, and compatibility mismatches
- whether a native rebuild is required
- whether each proof lane is merge-blocking or advisory
- promotion criteria for advisory provider/device proof
- rough-edge and reviewer/storefront guidance when policy-sensitive

## Milestone Closeout Checklist

Every milestone close must update or verify:

- `PROJECT.md` current state, active/validated requirements, and key decisions.
- `MILESTONE-ARC.md` strategic queue, dependencies, open research flags, and durable lessons.
- `ROADMAP.md` phase status parity.
- `REQUIREMENTS.md` archived or reset state.
- `STATE.md` milestone/frontmatter consistency.
- Threads/seeds: close shipped threads, create new threads for unresolved strategic signals.
- Verification reports: every completed phase has an explicit verification artifact or an intentional documented exception.
- Validation ledgers: Nyquist/validation state is final or explicitly deferred.
- Changelog/release continuity when public support claims changed.
- Active milestone closeout ledger: `.planning/milestones/<milestone>-CLOSEOUT.md` is current, with missing artifacts recorded only through explicit `deferred_with_reason` exceptions.

## Open Research Flags

- Exact package/versioning posture for future separate companion packages.
- Whether RevenueCat belongs as a future adapter after the first-party StoreKit and Play Billing seam hardens.
- Whether Chimeway should stay token/open-action seam-only for one milestone or include a first provider delivery lane; default to seam-only unless provider/device delivery proof can be kept advisory and clearly separated from backend binding/open-action readiness.
- Which scanning/capture flows belong in Rindle/native-screen lanes versus bounded bridge families.
- What minimum Android evidence is required to move shell support from "verification required" to fully verified.
- Whether the deferred Threadline operator timeline should live in a separate `crosswake_dashboard` package (LiveDashboard plugin) and when the opt-in audit ledger has enough adoption to justify the visual surface.
- Which exact Native Controls Pack 1 controls v19.0 evidence should promote into v20.0.
- Whether scanner/document-scan/biometrics/location belong in v20.0 or a later capture/device controls pack.
- How far "themable out of the box" should extend before the adopter drops to fully custom (the 95%/5% seam), and whether the design-token drift gate should police radius/shadow/z drift, not just color — surfaced by SEED-005 (Native Controls Pack 2 — Themable Web Control Equivalents).
- **POSITIONING DECISION (ratify at Native Navigation Shell activation):** whether to formally shift Crosswake's stated positioning toward consumer-grade "feels-native" (native shell fidelity, NOT app parity) — implying enumerated edits to `brandbook/BRAND-SPEC.md`, README "What this is not", and PROJECT.md core-value, plus a new native-shell-proven support tier. Surfaced + scoped by SEED-006 (the north-star shift is recorded there; the brand-doc edits are deliberately deferred to activation).
- **Fidelity ceiling / web↔native back-stack sync** — the acceptable degree of "feels native ~90-95%" and the design of the native-authoritative sync subsystem (the load-bearing OPEN problem in SEED-006).
- **PROOF-CULTURE vs CI COST (decide at CI/CD milestone activation):** whether to adopt a **merge queue** (`on: merge_group:`) so cheap proofs run per-push and the FULL proof set runs once per merge against the real merge commit. It is the highest-leverage option available and also the biggest semantic change to "every proof runs on every change" — nothing lands unproven either way, but the boundary moves from every push to every merge. Related and narrower: how far to consolidate 22 granular required contexts toward one aggregating gate, given the repo's existing `list_merge_blocking_checks.py` → `register_required_checks.sh` auto-discovery machinery is built around the granular model. Surfaced + scoped by SEED-007.

---
*Last updated: 2026-07-28 — recorded SEED-007 (CI/CD Performance & Gate Integrity) as a `Later:` Strategic Queue candidate + Dependency Graph edge + Open Research Flag, from a measured baseline plus a three-lens research fan-out (CI topology/cost, test-suite determinism, external Elixir-OSS practice). Key reframe: the ~7 h/push cost is macOS QUEUE time, not compute, and 14 of 18 macOS PR jobs need no Apple toolchain; three gate-integrity holes (duplicate required-check names, CI-invisible `:requires_example_host` tests, leaked global test state) were found while measuring and are severable from the performance work. Prior entry 2026-07-27: SEED-005 (Native Controls Pack 2) and SEED-006 (Native Navigation Shell) recorded as `Later:` candidates; SEED-006 carries an explicit consumer-grade positioning north-star shift (brand-doc edits deferred to activation). v19.0 Showcase Apps & Capability Map active; v20.0 Native Controls Pack 1 remains the logical follow-on.*
