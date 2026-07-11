# Phase 151: Subscription Learning Showcase - Research

**Researched:** 2026-07-11
**Domain:** Phoenix showcase lane, LiveView route ownership, socketless IndexedDB offline island, append-only sync evidence, backend-owned entitlement projection
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

All content in this section is copied from `.planning/phases/151-subscription-learning-showcase/151-CONTEXT.md`; bullet text is intentionally unmodified so the planner can treat it as the locked upstream phase context. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md]

### Locked Decisions
## Implementation Decisions

### Product Workflow
- **D-01:** Use a blended LearnLoop workflow as the primary lane: LearnLoop dashboard -> course or pack detail -> gated lesson/paywall pressure -> offline study session -> synced progress/history.
- **D-02:** Start the experience with learner progress and course momentum, not monetization and not diagnostics. Subscription pressure appears at the point where a gated lesson or pack makes it relevant.
- **D-03:** Keep the lane focused on one representative journey. Do not turn LearnLoop into a generic course marketplace, LMS, course-authoring console, coach/admin suite, or analytics dashboard.
- **D-04:** The recommended primary route shape is `/learnloop`, `/learnloop/courses/:id`, `/learnloop/packs/:id`, `/learnloop/study/session`, `/learnloop/history`, and `/learnloop/subscription` or an equivalent compact set if the planner finds a cleaner Phoenix route grouping.
- **D-05:** Existing `/offline`, `/study/session`, `/study/history`, `/decks`, `/library`, and `/commerce/paywall` routes may remain reachable proof routes, but the showcase CTA should move to product-first LearnLoop routes.
- **D-06:** Treat `/offline` as the proven socketless offline-study implementation to preserve or wrap, not as the final product-facing lane name.
- **D-07:** Do not promote current `/study/session` as the canonical offline proof unless it is converted away from its current LiveView simulation. A route declared as `runtime: :offline_island` must not depend on `phx-click` for the core study mutation.

### Route Ownership and Offline Integration
- **D-08:** LiveView owns the LearnLoop dashboard, course/pack detail, subscription status, and server-confirmed progress/history surfaces. These routes should default to `offline: :cached_read_only` unless a real route-local local-first contract exists.
- **D-09:** The study session must be a real socketless offline island using the existing IndexedDB/outbox pattern from `offline_study.js`, not a LiveView event loop. The browser route tour must prove `window.liveSocket` is absent for the island.
- **D-10:** The canonical study island should declare `runtime: :offline_island`, `offline: :local_first`, and a content pack such as `daily_study` or `learnloop_daily_pack`. The implementation may reuse the existing `POST /study/sync` seam or add a `/learnloop/sync` alias that delegates to the same controller.
- **D-11:** Preserve browser-owned state truth. `Showcase.Reset.reset!/0` must continue to report `browser_state_reset: false`; only Playwright/browser helpers may clear IndexedDB/outbox state.
- **D-12:** Use append-only review events as the sync model. Offline answers should queue client-generated review events, server sync should accept/reject idempotently, and progress/history should be a projection of reconciled evidence.
- **D-13:** The UI must distinguish `cached read-only`, `saved locally`, `queued for replay`, `syncing`, `synced`, and `server rejected` states. Cached read-only surfaces must not imply local mutation.
- **D-14:** Show reconciliation visibility without claiming a generic sync engine. Good visible states include `Saved locally`, `Queued for replay`, `Syncing`, `Synced N - queued M`, and `Rejected by server - review needed`.
- **D-15:** The study island may demonstrate local-first flashcard review, but broader offline capabilities such as background sync, multi-device conflict UI, native storage, content eviction policy, media download management, or generated sync helpers remain deferred.

### Entitlement and Paywall Pressure
- **D-16:** Use a blended gated-lesson/paywall moment plus compact backend-owned entitlement diagnostics. This satisfies LEARN-03 without making subscription state the first impression.
- **D-17:** Reuse the existing commerce/paywall projection vocabulary and helpers where they reduce risk, but keep the LearnLoop copy product-focused. The user should see learning access status first, then backend projection details in compact support truth.
- **D-18:** Entitlement authority remains backend-owned or mocked backend-owned. Device/storefront evidence never grants access by itself.
- **D-19:** Primary learner-visible entitlement states should stay small: `granted`, `pending`, `stale`, and `denied`. Deeper states such as `grace`, `billing_retry`, `revoked`, `refunded`, `expired`, `awaiting_verification`, and `stale_authority` belong in diagnostics or future commerce work.
- **D-20:** Use fail-closed copy for stale or pending access: "Access stays closed until backend projection refreshes", "Backend projection required", "Mock storefront evidence received", and "No live StoreKit, Play Billing, or RevenueCat adapter in this demo."
- **D-21:** Avoid overclaiming copy: do not say "purchase succeeded", "subscribed", "unlocked", "subscription verified on device", or "storefront support shipped" unless the projected backend state is `granted` and the UI still labels the storefront evidence as mocked.
- **D-22:** Any purchase/restore UI in Phase 151 is demo pressure only. Production native purchase/restore screens, provider SDK integration, App Store/Play policy flows, account-management billing UI, live webhooks, and provider-specific recovery remain deferred.

### Data and Persistence
- **D-23:** Follow the Phase 149/150 data pattern: deterministic fixture/read-context breadth plus narrow persisted workflow evidence.
- **D-24:** Keep courses, lessons, packs, learners, coach/admin context, route posture, support findings, and fixture previews as deterministic lane-local read data unless the planner finds an existing low-cost persisted shape.
- **D-25:** Persist only evidence that proves runtime claims: existing `review_events`, existing or projected flashcard progress, and at most a narrow mocked/backend-owned entitlement snapshot or event record if needed for refresh-proof subscription pressure.
- **D-26:** Do not add broad Ecto schemas for the full LMS catalog in Phase 151. Broad catalog persistence would pull the phase away from route ownership, offline truth, and entitlement pressure.
- **D-27:** Put business logic in a lane-local Phoenix context such as `CrosswakeExample.LearnLoop` or a carefully named wrapper over `Flashcards`, `LocalFirst`, and commerce helpers. LiveViews/controllers render and dispatch; context functions own data access, projection, and state transitions.
- **D-28:** Use Ecto changesets and `Ecto.Multi` only where a workflow changes multiple persisted facts, such as recording sync evidence and updating a progress/subscription projection. Static fixture breadth should not be persisted for realism alone.
- **D-29:** Reset must stay deterministic. `Showcase.Reset.reset!/0` should delegate to LearnLoop/Flashcards helpers, delete/reseed server-owned learning evidence idempotently, include stable counts/digest components, and preserve browser-state honesty.

### UI, UX, and Creative Direction
- **D-30:** Build a product-first LearnLoop shell, not a marketing page and not a manifest inspector. The lane should feel like a credible subscription learning app before it explains Crosswake.
- **D-31:** Use the locked Phase 148 LearnLoop brand: polished course progress and offline study with the violet-teal learning identity, while still clearly living inside the Crosswake showcase.
- **D-32:** The main JTBD is: a learner sees what to study next, understands which pack is available, starts an offline study session, sees local progress queued/synced, and understands when subscription access is pending or gated.
- **D-33:** Secondary personas are a coach/admin who wants progress/support truth and a maintainer evaluating Crosswake's route ownership, offline, entitlement, and diagnostics posture. The first viewport should still prioritize the learner.
- **D-34:** Use a "course path + pack manifest + sync ledger" motif. Preferred UI pieces: learner progress header, active course/pack card, next lesson panel, offline study CTA, sync status strip, compact entitlement badge, recent review history, and route/support diagnostics disclosure.
- **D-35:** Desktop can use a dense two-column cockpit with course/progress content and a diagnostics/status rail. Mobile should be a single-column task flow with persistent route/support badges and no desktop table parity if it hurts scanability.
- **D-36:** Keep backend implementation details out of the first impression. Users see LearnLoop language first; Crosswake route policy appears as compact badges, support notes, and optional diagnostics.
- **D-37:** Use conventional accessible affordances: text-labeled status badges, clear primary/secondary actions, details/summary for diagnostics, lists for course/lesson rows, progress bars with text labels, and status regions for sync/entitlement updates.
- **D-38:** Accessibility is in scope: visible focus rings, 44px preferred mobile actions, no color-only statuses, readable contrast in light/dark/system themes, reduced-motion-safe interactions, no horizontal overflow, and no clipped badge/action text.
- **D-39:** Microcopy should be calm and status-oriented. Prefer "Connect once to load today's pack", "Saved locally", "Queued for replay", "Backend projection required", and "Server reset does not clear this device's offline state" over internal denial codes.
- **D-40:** Avoid a one-note purple/blue learning palette. Use the locked LearnLoop violet-teal identity, but balance it with neutral surfaces, status colors, and Crosswake token discipline so the lane does not read as generic edtech gradient UI.

### Proof and Verification
- **D-41:** Add focused ExUnit coverage for LearnLoop fixture density, reset idempotency/digest truth, persisted evidence counts, route metadata drift, support-label allowlists, entitlement-state copy, and no unsupported storefront/native-storage claims.
- **D-42:** LiveView tests should cover the product shell click path where LiveView owns the route. Use Playwright for the real offline island because the proof must inspect IndexedDB, network toggling, socket absence, and outbox deletion.
- **D-43:** Extend browser route-tour coverage to exercise: showcase hub -> LearnLoop dashboard -> course/pack detail -> gated lesson/paywall pressure -> offline study -> reconnect sync -> progress/history -> diagnostics/support truth.
- **D-44:** Route-tour screenshots remain collateral after semantic assertions pass. Assertions must prove route owner, socketless island behavior, IndexedDB queueing, app-generated mutation IDs, exactly-one Ecto review row, duplicate replay idempotency, entitlement fail-closed copy, and support labels before screenshots.
- **D-45:** Add guardrails against proof drift: no `LiveView works offline` copy, no background-sync claim, no `server reset cleared offline state` claim, no live StoreKit/Play Billing/RevenueCat support claim, and no broad native storage support claim.
- **D-46:** Preserve capability-map evidence for Phase 152 by making content packs, offline study, sync/reconciliation, entitlement projection, native storage pressure, and commerce/paywall pressure visible and honestly labeled.

### Research-Backed Recommendation Summary
- **D-47:** The coherent recommendation across all gray areas is: product-first `/learnloop/*` lane, LiveView learning shell, socketless IndexedDB-backed study island, append-only review-event sync, backend-owned mocked entitlement projection, deterministic fixture breadth, narrow persisted evidence, and semantic-first proof.
- **D-48:** This aligns with Phoenix idioms: contexts own data access and validation, LiveViews/controllers are web interfaces into the Elixir application, and Ecto persistence is added where it represents real state rather than display realism.
- **D-49:** This aligns with offline-first ecosystem guidance: true offline behavior requires local data, local writes/events, and reconciliation visibility. Cached read-only pages and LiveView simulations must not be presented as local-first mutation.
- **D-50:** This aligns with commerce ecosystem guidance: Apple, Google, Stripe-style, and RevenueCat-style systems all reinforce that storefront/device events are evidence, while entitlement access should be verified and projected by backend authority before granting benefits.

### the agent's Discretion
- The planner may choose exact module names, whether `/learnloop/study/session` wraps `/offline` or refactors it into a LearnLoop controller/template, whether to add a `/learnloop/sync` alias, and whether a narrow entitlement snapshot needs a new table or can stay as deterministic/backend-mocked projection.
- The planner may refine exact route paths and copy as long as the primary UX is product-first and the offline/entitlement/support truth decisions above are preserved.
- The planner may decide whether diagnostics are inline cards, a right rail, or a details disclosure, as long as route/support truth remains mechanically testable and does not become `crosswake_dashboard`.

### Deferred Ideas (OUT OF SCOPE)
## Deferred Ideas

- Broad LMS schemas, course authoring/admin tools, coach dashboards, adaptive scheduling algorithms, and generic course marketplace behavior.
- Native SQLite or native file-cache implementation for content packs, native study screen, native media/audio/video downloads, background/resumable sync, and storage-budget productization.
- Production StoreKit, Play Billing, RevenueCat, Accrue, or other live commerce/paywall adapters.
- Native purchase/restore screens, App Store/Play policy flows, account-management billing UI, live provider webhooks, and provider-specific recovery workflows.
- Device-local entitlement authority and offline purchase replay.
- Multi-device conflict review beyond append-only/idempotent review-event proof.
- Generic offline sync/native storage helpers and SYNCP-01 productization.
- `crosswake_dashboard`, URL-addressable global route inspector, and broader operator dashboard surfaces.
- Phase 152 capability map, proof/collateral surface, and v20 Native Controls Pack 1 selection.
</user_constraints>

## Summary

Phase 151 should be planned as a product-shaped LearnLoop showcase lane, not as a new framework surface or a broad LMS implementation. The strongest plan keeps Phoenix/LiveView responsible for the online learning shell, keeps the offline study loop in a socketless browser-owned island, and keeps entitlement truth in backend-owned or mocked-backend projection state. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md] [VERIFIED: guides/route_policy.md] [VERIFIED: guides/offline.md] [VERIFIED: guides/commerce.md]

The existing Phoenix host already has the main proof primitives Phase 151 needs: `/offline` is a socketless IndexedDB study island; `offline_study.js` queues browser mutations and flushes them to `/study/sync`; `LocalFirst.Study.sync_events/1` inserts append-only review events idempotently; `/study/history` exposes server-confirmed history; and commerce helpers already model mocked storefront evidence versus backend entitlement projection. [VERIFIED: examples/phoenix_host/lib/crosswake_example_web/controllers/offline_controller.ex] [VERIFIED: examples/phoenix_host/priv/static/offline_study.js] [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/study.ex] [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/study_history_live.ex] [VERIFIED: examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex]

The main planning risk is proof drift: a route can look like a learning app while quietly implying LiveView offline mutation, a generic sync engine, native storage support, or live StoreKit/Play Billing support. The plan should add LearnLoop product routes and fixture breadth, but reuse the existing offline and commerce proof seams and add tests that mechanically assert route metadata, socket absence, IndexedDB queueing, idempotent replay, fail-closed entitlement copy, and support labels. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md] [VERIFIED: examples/phoenix_host/e2e/offline_sync.spec.ts] [VERIFIED: examples/phoenix_host/e2e/route_tour.spec.ts] [VERIFIED: guides/support_matrix.md]

**Primary recommendation:** Build `/learnloop/*` as a lane-local Phoenix context plus LiveView shell, wrap or refactor the proven `/offline` island into `/learnloop/study/session`, delegate sync to the existing append-only review-event seam, reuse commerce projection vocabulary for paywall pressure, and extend ExUnit/Playwright proof before adding polish. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md] [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| LearnLoop dashboard, course detail, pack detail, subscription status, and progress/history shell | Frontend Server (Phoenix LiveView) | API / Backend | Context decisions assign these online surfaces to LiveView with `offline: :cached_read_only` unless a route-local local-first contract exists. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md] |
| Deterministic courses, lessons, packs, learners, support findings, and route posture data | API / Backend (lane-local Phoenix context) | Frontend Server | Phoenix contexts are the project-standard place for data access and domain functions; the context explicitly asks for `CrosswakeExample.LearnLoop` or a wrapper over existing helpers. [CITED: https://phoenix.hexdocs.pm/contexts.html] [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md] |
| Offline study session | Browser / Client | API / Backend | The study loop must be a socketless IndexedDB/outbox island, and the backend only accepts/rejects replayed review events. [VERIFIED: examples/phoenix_host/priv/static/offline_study.js] [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/study.ex] |
| Review-event sync and reconciliation | API / Backend | Database / Storage | `LocalFirst.Study.sync_events/1` validates events and performs idempotent `insert_all` into `review_events`; the database unique index enforces duplicate replay safety. [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/study.ex] [VERIFIED: examples/phoenix_host/priv/repo/migrations] |
| Browser outbox and content-pack cache | Browser / Client | Database / Storage (IndexedDB) | `offline_study.js` stores cards and mutations in IndexedDB and reports browser-owned queue/sync status. [VERIFIED: examples/phoenix_host/priv/static/offline_study.js] [CITED: https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API] |
| Entitlement and paywall pressure | API / Backend | Frontend Server | Commerce guides and existing helpers treat storefront/device evidence as non-authoritative and gate access through backend projection state. [VERIFIED: guides/commerce.md] [VERIFIED: examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex] |
| Showcase entry, reset digest, and support labels | API / Backend | Frontend Server | `Showcase.Catalog`, `Showcase.Reset`, and hub tests are existing central seams for lane card metadata, reset counts, route support labels, and root CTA targets. [VERIFIED: examples/phoenix_host/lib/crosswake_example/showcase/catalog.ex] [VERIFIED: examples/phoenix_host/lib/crosswake_example/showcase/reset.ex] [VERIFIED: examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs] |
| Route-tour proof and offline browser assertions | Browser / Client test runtime | API / Backend test runtime | Existing Playwright specs inspect socket absence, IndexedDB queueing, API sync, duplicate replay, and screenshots after semantic assertions. [VERIFIED: examples/phoenix_host/e2e/offline_sync.spec.ts] [VERIFIED: examples/phoenix_host/e2e/support/offline_route_proof.ts] |

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LEARN-01 | User can click through a subscription learning/training domain with realistic courses, lessons, packs, learners, progress, and subscription state. [VERIFIED: .planning/REQUIREMENTS.md] | Use deterministic lane-local fixture/read data in a `LearnLoop` context, product-first `/learnloop/*` LiveViews, and the locked LearnLoop brand. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md] [VERIFIED: examples/phoenix_host/lib/crosswake_example/showcase/branding.ex] |
| LEARN-02 | User can see content-pack and offline-study behavior demonstrated with honest sync/reconciliation visibility. [VERIFIED: .planning/REQUIREMENTS.md] | Wrap or refactor the existing socketless IndexedDB offline route, keep visible queue/sync/rejected states, and delegate replay to existing review-event sync. [VERIFIED: examples/phoenix_host/priv/static/offline_study.js] [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/study.ex] |
| LEARN-03 | User can see entitlement/paywall pressure represented as backend-owned or mocked state without claiming live storefront support. [VERIFIED: .planning/REQUIREMENTS.md] | Reuse commerce projection helpers and fail-closed copy; do not add live StoreKit, Play Billing, RevenueCat, or device-authoritative claims. [VERIFIED: guides/commerce.md] [VERIFIED: examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex] |
| LEARN-04 | User can complete a representative learning workflow that connects online LiveView, offline island, and support truth. [VERIFIED: .planning/REQUIREMENTS.md] | Extend route tour from hub to LearnLoop dashboard/detail/paywall/offline study/reconnect/history/diagnostics with semantic assertions before screenshots. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md] [VERIFIED: examples/phoenix_host/e2e/route_tour.spec.ts] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Read `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` before planning or implementation work. [VERIFIED: AGENTS.md]
- Preserve the core thesis: Crosswake is a Phoenix-first route-policy and runtime-contract system, not a universal UI framework. [VERIFIED: AGENTS.md] [VERIFIED: .planning/PROJECT.md]
- Keep runtime ownership explicit per route. [VERIFIED: AGENTS.md] [VERIFIED: guides/route_policy.md]
- Do not collapse designs into generic WebView wrapper behavior or LiveView-driven native rendering. [VERIFIED: AGENTS.md]
- Treat bridge contracts as semantic, typed, versioned, and low-frequency. [VERIFIED: AGENTS.md] [VERIFIED: guides/bridge.md]
- Move any flow that needs continuous client authority toward an offline island or native screen. [VERIFIED: AGENTS.md] [VERIFIED: guides/route_policy.md]
- Keep offline claims honest by distinguishing cached read-only behavior from true local-first mutation with journals, outboxes, and reconciliation. [VERIFIED: AGENTS.md] [VERIFIED: guides/offline.md]
- Treat diagnostics, support matrices, proof lanes, and rough-edge documentation as product surface. [VERIFIED: AGENTS.md] [VERIFIED: guides/support_matrix.md]
- Respect v1/v19 scope boundaries before adding integrations or wider native breadth. [VERIFIED: AGENTS.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/STATE.md]
- Preserve v19 scope: Phase 151 creates LearnLoop lane evidence, while Phase 152 owns the capability map and v20 handoff. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/STATE.md]

## Standard Stack

### Core

| Library / Runtime | Version | Purpose | Why Standard |
|-------------------|---------|---------|--------------|
| Elixir / Erlang OTP | Elixir 1.19.5, Erlang/OTP 28 | Host language and runtime for Crosswake and the Phoenix example app. | Existing repo runtime and local environment match the current project configuration. [VERIFIED: local `elixir --version`] [VERIFIED: mix.exs] |
| Phoenix | Locked 1.8.7; latest observed 1.8.9 published 2026-07-07 | Web framework, router, controllers, and LiveView host integration. | The example host already depends on Phoenix and all LearnLoop web routes should stay in that host rather than adding another web stack. [VERIFIED: examples/phoenix_host/mix.exs] [VERIFIED: examples/phoenix_host/mix.lock] [VERIFIED: Hex registry] |
| Phoenix LiveView | Locked 1.1.30; latest observed 1.2.6 published 2026-07-07 | Online dashboard, course, pack, subscription, and history UI. | Existing host uses LiveView, and official testing tools support process-level interaction tests for LiveView-owned routes. [VERIFIED: examples/phoenix_host/mix.exs] [VERIFIED: examples/phoenix_host/mix.lock] [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveViewTest.html] |
| Crosswake route metadata | Local path package | Route policy/runtime-contract metadata. | Phase 151 must preserve explicit route ownership and support truth; the router already stores Crosswake metadata for `/offline`, `/study/*`, `/commerce/*`, and other proof lanes. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] |
| Ecto / Ecto SQL / ecto_sqlite3 | Ecto 3.13.6, Ecto SQL 3.13.5, ecto_sqlite3 0.23.0 | Review-event persistence, progress data, reset counts, and idempotent replay evidence. | Existing local-first sync already uses Ecto changesets, `Ecto.Multi`, `insert_all`, and SQLite-backed tests; no alternate database stack is needed. [VERIFIED: examples/phoenix_host/mix.lock] [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/study.ex] |
| IndexedDB via `offline_study.js` | Browser API plus local project JS | Browser-owned card cache and outbox mutations. | The existing offline island already uses IndexedDB and local mutation queues; MDN documents IndexedDB as browser-side structured storage. [VERIFIED: examples/phoenix_host/priv/static/offline_study.js] [CITED: https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API] |
| Playwright | Locked `@playwright/test` 1.60.0; latest observed 1.61.1 on 2026-07-11 | Browser proof for socket absence, offline mode, IndexedDB, API sync, and route-tour screenshots. | Existing e2e specs already use Playwright, and the local Phoenix host has a Playwright binary at 1.60.0. [VERIFIED: examples/phoenix_host/package-lock.json] [VERIFIED: local `examples/phoenix_host/node_modules/.bin/playwright --version`] [CITED: https://playwright.dev/docs/api/class-browsercontext] |

### Supporting

| Library / Runtime | Version | Purpose | When to Use |
|-------------------|---------|---------|-------------|
| Bandit | Locked 1.12.0; latest observed 1.12.0 published 2026-06-06 | Phoenix endpoint server in the example app. | Keep existing Phoenix host server; do not add a separate service for LearnLoop. [VERIFIED: examples/phoenix_host/mix.lock] [VERIFIED: Hex registry] |
| Jason | Locked 1.4.5 | JSON encode/decode for API payloads and route contracts. | Use for existing `/study/sync` or `/learnloop/sync` JSON payloads through existing Phoenix conventions. [VERIFIED: examples/phoenix_host/mix.lock] [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex] |
| Phoenix.LiveViewTest | From `phoenix_live_view` 1.1.30 | LiveView shell tests. | Use for dashboard/detail/subscription/history routes where LiveView owns events and rendering. [VERIFIED: examples/phoenix_host/mix.lock] [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveViewTest.html] |
| ExUnit | Bundled with Elixir 1.19.5 | Unit and integration tests. | Use for context fixtures, reset digest, route metadata, copy guardrails, and commerce projection behavior. [VERIFIED: local `elixir --version`] [VERIFIED: examples/phoenix_host/test] |
| TypeScript | Locked 5.9.3 | Playwright spec type checking and e2e helper code. | Keep current e2e test tooling; no new frontend build stack is needed. [VERIFIED: examples/phoenix_host/package-lock.json] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Lane-local deterministic fixture context | Full persisted LMS catalog schemas | Full LMS persistence would add unrelated migration, CRUD, and authoring scope; Phase 151 only needs realistic read breadth and narrow persisted evidence. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md] |
| Existing `offline_study.js` + IndexedDB outbox | New generic sync engine or service worker/background sync | A generic sync engine is explicitly deferred; the phase only needs one route-local local-first island with visible reconciliation. [VERIFIED: guides/offline.md] [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md] |
| Existing commerce projection helpers | StoreKit, Play Billing, RevenueCat, or provider SDK adapter | Live provider/storefront support is out of scope; backend-owned mocked projection is enough for LEARN-03. [VERIFIED: guides/commerce.md] [VERIFIED: .planning/REQUIREMENTS.md] |
| `/learnloop/sync` alias delegating to current sync | Separate LearnLoop sync implementation | A second implementation would raise reconciliation drift risk; an alias can improve product route naming while preserving the existing proof seam. [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/study.ex] [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex] |

**Installation:**

No new external packages are recommended for Phase 151. Use the existing project dependencies and install commands only if the local environment is missing deps. [VERIFIED: examples/phoenix_host/mix.exs] [VERIFIED: examples/phoenix_host/package-lock.json]

```bash
cd examples/phoenix_host
mix deps.get
npm ci
```

**Version verification:** Existing versions were verified from `examples/phoenix_host/mix.lock`, `examples/phoenix_host/package-lock.json`, local runtime commands, Hex registry lookups, and npm registry lookups during research. Phoenix, LiveView, Ecto, and Playwright have newer registry releases than the locked versions, but this phase should not upgrade dependencies because the user requested a showcase lane, not dependency modernization. [VERIFIED: examples/phoenix_host/mix.lock] [VERIFIED: examples/phoenix_host/package-lock.json] [VERIFIED: Hex registry] [VERIFIED: npm registry]

## Package Legitimacy Audit

Phase 151 does not require installing new external packages; it should use existing locked Elixir and npm dependencies. [VERIFIED: examples/phoenix_host/mix.exs] [VERIFIED: examples/phoenix_host/package.json] Because no new package is recommended, the package legitimacy gate has no new install candidates to approve, flag, or remove. [VERIFIED: examples/phoenix_host/mix.lock] [VERIFIED: examples/phoenix_host/package-lock.json]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none new | none | n/a | n/a | n/a | n/a | No new package installs recommended. [VERIFIED: examples/phoenix_host/mix.exs] [VERIFIED: examples/phoenix_host/package.json] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: no new external package recommendations in this research]
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: no new external package recommendations in this research]

## Architecture Patterns

### System Architecture Diagram

```text
Showcase hub
  -> LearnLoop catalog card / CTA
  -> /learnloop LiveView dashboard
       -> LearnLoop context
            -> deterministic learner/course/lesson/pack fixtures
            -> Flashcards reset/digest helpers
            -> Commerce entitlement projection helpers
            -> Router metadata/support diagnostics
       -> /learnloop/courses/:id and /learnloop/packs/:id LiveViews
       -> gated lesson / subscription pressure LiveView
            -> mocked storefront evidence
            -> backend-owned entitlement projection
            -> fail-closed status copy
       -> /learnloop/study/session socketless controller/html island
            -> offline_study.js
            -> IndexedDB cards + mutations
            -> saved locally / queued / syncing / synced / rejected UI
            -> POST /study/sync or /learnloop/sync alias
                 -> LocalFirst.SyncController
                 -> LocalFirst.Study.sync_events/1
                 -> review_events unique client_mutation_id
       -> /learnloop/history LiveView
            -> server-confirmed review/progress projection
       -> compact route/support diagnostics

Showcase.Reset.reset!/0
  -> LearnLoop/Flashcards reset helpers
  -> server-owned data reset
  -> browser_state_reset: false
```

This diagram follows current code ownership: LiveView owns online surfaces, the browser owns the socketless island mutation queue, and backend/database code owns reconciliation and entitlement projection. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] [VERIFIED: examples/phoenix_host/priv/static/offline_study.js] [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/study.ex] [VERIFIED: guides/commerce.md]

### Recommended Project Structure

```text
examples/phoenix_host/lib/crosswake_example/
+-- learn_loop.ex                         # Lane-local context facade over fixtures, Flashcards, LocalFirst, commerce, and diagnostics
+-- learn_loop/
|   +-- fixtures.ex                       # Deterministic learner/course/lesson/pack data
|   +-- diagnostics.ex                    # Route metadata/support truth helpers
|   +-- entitlement.ex                    # Thin product vocabulary wrapper around commerce projection helpers
|   +-- components.ex                     # LearnLoop shell/status/diagnostics components
+-- learn_loop/dashboard_live.ex          # /learnloop
+-- learn_loop/course_live.ex             # /learnloop/courses/:id
+-- learn_loop/pack_live.ex               # /learnloop/packs/:id
+-- learn_loop/history_live.ex            # /learnloop/history
+-- learn_loop/subscription_live.ex       # /learnloop/subscription
+-- learn_loop/study_controller.ex        # /learnloop/study/session socketless island wrapper

examples/phoenix_host/lib/crosswake_example_web/controllers/learn_loop_study_html/
+-- index.html.heex                       # Socketless offline island template, adapted from current offline HTML
```

The structure keeps LearnLoop lane logic out of templates and mirrors existing Fieldserv/AdminPilot lane-local module patterns. [VERIFIED: examples/phoenix_host/lib/crosswake_example/field_service/fixtures.ex] [VERIFIED: examples/phoenix_host/lib/crosswake_example/field_service/diagnostics.ex] [VERIFIED: examples/phoenix_host/lib/crosswake_example/field_service/components.ex]

### Pattern 1: Lane-Local Context Owns Read Models and Projection

**What:** Put LearnLoop data assembly behind a context facade that returns deterministic course/pack/learner/progress/subscription view models. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md] [CITED: https://phoenix.hexdocs.pm/contexts.html]

**When to use:** Use this for dashboard, detail, subscription, history, reset digest, and tests so LiveViews remain web interfaces rather than business logic containers. [VERIFIED: examples/phoenix_host/lib/crosswake_example/field_service/jobs.ex] [VERIFIED: examples/phoenix_host/lib/crosswake_example/field_service/fixtures.ex]

**Example:**

```elixir
# Source: Phoenix contexts guidance and existing FieldService lane context patterns.
defmodule CrosswakeExample.LearnLoop do
  alias CrosswakeExample.{Flashcards, LocalFirst}
  alias CrosswakeExample.LearnLoop.{Diagnostics, Fixtures, Entitlement}

  def dashboard_context(learner_id \\ "iris") do
    learner = Fixtures.learner!(learner_id)

    %{
      learner: learner,
      courses: Fixtures.courses_for(learner),
      active_pack: Fixtures.active_pack_for(learner),
      entitlement: Entitlement.snapshot_for(learner),
      recent_reviews: LocalFirst.Study.list_events(limit: 6),
      route_posture: Diagnostics.for_path("/learnloop")
    }
  end

  def reset_seed! do
    Flashcards.reset_seed!()
    |> Map.put(:learnloop_courses, length(Fixtures.courses()))
    |> Map.put(:browser_state_reset, false)
  end
end
```

### Pattern 2: Product Route Wraps the Existing Socketless Island

**What:** Expose `/learnloop/study/session` as the product-facing offline island while preserving controller-rendered HTML, `window.liveSocket` absence, IndexedDB storage, and existing replay behavior. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md] [VERIFIED: examples/phoenix_host/lib/crosswake_example_web/controllers/offline_controller.ex] [VERIFIED: examples/phoenix_host/priv/static/offline_study.js]

**When to use:** Use this for LEARN-02 and LEARN-04 because LiveView cannot prove socketless offline mutation by itself. [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/study_session_live.ex] [VERIFIED: examples/phoenix_host/e2e/offline_sync.spec.ts]

**Example:**

```elixir
# Source: existing router metadata pattern for /offline and /study/sync.
scope "/", CrosswakeExampleWeb do
  pipe_through :browser

  get "/learnloop/study/session", LearnLoopStudyController, :show,
    crosswake: [
      id: "learnloop-study-session",
      runtime: :offline_island,
      offline: :local_first,
      bridge: :none,
      packs: [
        %{
          id: :learnloop_daily_pack,
          version: "2026-07-11",
          storage: :indexed_db,
          sync: :review_event_outbox
        }
      ]
    ]
end
```

### Pattern 3: Sync Alias Delegates to the Existing Review-Event Seam

**What:** If a product-named sync path is useful, add `/learnloop/sync` as an alias or wrapper that calls the same `LocalFirst.Study.sync_events/1` path as `/study/sync`. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md] [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex]

**When to use:** Use this only to make the product route tour coherent; do not create a second sync model. [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/study.ex] [VERIFIED: examples/phoenix_host/priv/static/offline_study.js]

**Example:**

```elixir
# Source: existing LocalFirst.SyncController and LocalFirst.Study.sync_events/1.
scope "/", CrosswakeExample do
  pipe_through :api

  post "/study/sync", LocalFirst.SyncController, :sync
  post "/learnloop/sync", LocalFirst.SyncController, :sync
end
```

### Pattern 4: Idempotent Append-Only Replay

**What:** Continue using client mutation IDs, changesets, `insert_all`, and `on_conflict: :nothing` so duplicate replay does not create duplicate review evidence. [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/study.ex] [CITED: https://ecto.hexdocs.pm/Ecto.Repo.html] [CITED: https://ecto.hexdocs.pm/constraints-and-upserts.html]

**When to use:** Use this for offline review answers and any narrow server-owned learning progress projection. [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex] [VERIFIED: examples/phoenix_host/priv/repo/migrations]

**Example:**

```elixir
# Source: Ecto insert_all/on_conflict docs and current LocalFirst.Study implementation.
Repo.insert_all(ReviewEvent, rows,
  on_conflict: :nothing,
  conflict_target: :client_mutation_id,
  returning: true
)
```

### Pattern 5: Entitlement Copy Uses Backend Projection State

**What:** Reuse existing commerce projection states and show storefront evidence as mock evidence, not as access authority. [VERIFIED: examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex] [VERIFIED: examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex] [VERIFIED: guides/commerce.md]

**When to use:** Use this in gated lesson and subscription routes to satisfy LEARN-03 without adding live provider support. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md]

**Example:**

```elixir
# Source: existing commerce projection helper behavior.
case EntitlementProjection.derived_state(snapshot) do
  :granted -> "Access active from backend projection"
  :pending -> "Access stays closed until backend projection refreshes"
  :stale -> "Backend projection required"
  :denied -> "No active learning access"
end
```

### Anti-Patterns to Avoid

- **LiveView offline mutation:** Do not use `phx-click` as the core mutation path for a route declared `runtime: :offline_island`; current `/study/session` is explicitly not canonical unless converted. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md] [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/study_session_live.ex]
- **Broad LMS persistence:** Do not add course-authoring, coach dashboard, marketplace, or full catalog Ecto schemas for realism. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md]
- **Second sync engine:** Do not create generated sync helpers or a new reconciliation model when the existing review-event seam already proves the route claim. [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/study.ex] [VERIFIED: guides/offline.md]
- **Device-authoritative entitlement:** Do not let mocked storefront/device evidence unlock content by itself. [VERIFIED: guides/commerce.md] [CITED: https://developer.android.com/google/play/billing/integrate]
- **Support-truth prose only:** Do not rely on copy alone for support labels; test route metadata, catalog labels, and unsupported-claim copy. [VERIFIED: examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs] [VERIFIED: guides/support_matrix.md]
- **Capability-map ownership creep:** Do not build Phase 152's durable capability map in this phase; create evidence that Phase 152 can consume. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/STATE.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Browser offline study storage | New local storage abstraction, service worker sync, native SQLite, or generic storage helper | Existing `offline_study.js` with IndexedDB cards and mutations | The existing route already proves browser-owned storage and outbox behavior; broader native/offline helpers are deferred. [VERIFIED: examples/phoenix_host/priv/static/offline_study.js] [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md] |
| Idempotent review replay | Custom dedupe tables or in-memory duplicate filters | `review_events.client_mutation_id` unique constraint plus `Repo.insert_all(..., on_conflict: :nothing)` | Database-backed uniqueness is the current proof seam and avoids duplicate replay rows. [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex] [CITED: https://ecto.hexdocs.pm/Ecto.Repo.html] |
| LiveView interaction testing | Browser-only tests for every LiveView route | Phoenix.LiveViewTest for LiveView-owned routes | LiveViewTest can exercise rendered LiveView events quickly; reserve Playwright for browser storage and socketless proof. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveViewTest.html] [VERIFIED: examples/phoenix_host/test] |
| Offline browser proof | Manual QA or screenshot-only checks | Existing Playwright route-tour/offline helpers | Existing specs already inspect IndexedDB, network toggling, API sync, and screenshots after semantic assertions. [VERIFIED: examples/phoenix_host/e2e/offline_sync.spec.ts] [VERIFIED: examples/phoenix_host/e2e/support/offline_route_proof.ts] |
| Entitlement/paywall model | New billing SDK wrapper or live provider adapter | Existing commerce contracts, mock storefront, reconciliation inbox, and entitlement projection | Phase 151 requires mocked/backend-owned pressure, not production billing support. [VERIFIED: examples/phoenix_host/lib/crosswake_example/commerce] [VERIFIED: guides/commerce.md] |
| Route/support diagnostics | Freeform manifest inspector or global dashboard | Lane-local diagnostics from compiled router metadata and support labels | `crosswake_dashboard` is deferred; lane diagnostics should stay compact and mechanically testable. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md] [VERIFIED: examples/phoenix_host/lib/crosswake_example/field_service/diagnostics.ex] |

**Key insight:** Phase 151 should compose existing proof seams into a credible product lane; custom LMS, sync, storage, and storefront systems would create more claims than the phase can honestly prove. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md] [VERIFIED: guides/offline.md] [VERIFIED: guides/commerce.md]

## Common Pitfalls

### Pitfall 1: Declaring an Offline Island While Rendering a LiveView Mutation Loop

**What goes wrong:** The route metadata says `runtime: :offline_island`, but the user's primary study action depends on LiveView events. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/study_session_live.ex]

**Why it happens:** The existing `/study/session` has learning UI, but its core mutation path is `phx-click`; the proven socketless implementation is `/offline`. [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/study_session_live.ex] [VERIFIED: examples/phoenix_host/lib/crosswake_example_web/controllers/offline_controller.ex]

**How to avoid:** Make `/learnloop/study/session` controller-rendered/socketless or wrap `/offline` without LiveView. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md]

**Warning signs:** `window.liveSocket` exists in the study route, core buttons have `phx-click`, or Playwright can mutate study progress while only testing LiveView. [VERIFIED: examples/phoenix_host/e2e/offline_sync.spec.ts]

### Pitfall 2: Conflating Cached Read-Only with Local-First Mutation

**What goes wrong:** Dashboard/history/detail pages imply users can keep mutating learning state offline when they only have a cached read-only snapshot. [VERIFIED: guides/offline.md] [VERIFIED: guides/route_policy.md]

**Why it happens:** LiveView pages can be polished and cached, but they do not own browser-side journals unless explicitly built as an offline island. [VERIFIED: guides/offline.md]

**How to avoid:** Label online LiveView routes as `offline: :cached_read_only` and reserve `offline: :local_first` for the study island. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md]

**Warning signs:** Copy such as "LiveView works offline", "all progress saves offline", or "server reset cleared offline state". [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md]

### Pitfall 3: Duplicating the Sync/Reconciliation Seam

**What goes wrong:** LearnLoop adds a parallel sync controller or schema with slightly different accepted/rejected/idempotency rules. [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/study.ex]

**Why it happens:** Product route naming may tempt a new `/learnloop/sync` implementation instead of an alias. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md]

**How to avoid:** Delegate any product-named sync alias to `LocalFirst.SyncController` and `LocalFirst.Study.sync_events/1`. [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex] [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/study.ex]

**Warning signs:** Two code paths insert review events, accepted-count semantics differ between routes, or duplicate replay tests cover only one path. [VERIFIED: examples/phoenix_host/e2e/offline_sync.spec.ts]

### Pitfall 4: Paywall Copy Grants More Than the Backend Projection Grants

**What goes wrong:** UI says "subscribed", "unlocked", or "purchase succeeded" before backend projection says `granted`. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md] [VERIFIED: guides/commerce.md]

**Why it happens:** Mock storefront evidence can look like a successful purchase event even though Crosswake treats it as evidence only. [VERIFIED: examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex] [VERIFIED: examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex]

**How to avoid:** Use fail-closed copy and compact diagnostics that separate storefront evidence from backend authority. [VERIFIED: examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex] [VERIFIED: guides/commerce.md]

**Warning signs:** Storefront mock controls directly reveal gated content or route-tour assertions do not check no live-provider claims. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md]

### Pitfall 5: Persisting Fixture Breadth Instead of Evidence

**What goes wrong:** Course catalogs, lessons, personas, support findings, and pack manifests become migrations and schemas. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md]

**Why it happens:** Realistic product lanes need breadth, but Phase 149/150 established deterministic read breadth plus narrow persistence as the v19 pattern. [VERIFIED: .planning/STATE.md] [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md]

**How to avoid:** Persist only review events, existing/projected progress, and maybe a narrow entitlement snapshot if refresh-proof state requires it. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md]

**Warning signs:** The plan creates tables for courses, lessons, subscriptions, coaches, catalogs, or analytics before proving the offline/entitlement workflow. [VERIFIED: .planning/REQUIREMENTS.md]

### Pitfall 6: Letting Reset/Digest Hide Browser-Owned State

**What goes wrong:** Showcase reset appears to clear local offline state even though IndexedDB remains browser-owned. [VERIFIED: examples/phoenix_host/lib/crosswake_example/showcase/reset.ex] [VERIFIED: examples/phoenix_host/priv/static/offline_study.js]

**Why it happens:** Server reset can delete SQLite rows, but it cannot clear every user's browser database. [VERIFIED: examples/phoenix_host/lib/crosswake_example/showcase/reset.ex] [CITED: https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API]

**How to avoid:** Keep `browser_state_reset: false` in reset output and let Playwright helper code explicitly clear IndexedDB during browser tests. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md] [VERIFIED: examples/phoenix_host/e2e/support/offline_route_proof.ts]

**Warning signs:** Reset tests expect browser queues to be cleared by server reset or UI copy says "server reset cleared this device". [VERIFIED: examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs]

## Code Examples

Verified patterns from official sources and local code:

### Phoenix Context Boundary for LearnLoop

```elixir
# Source: Phoenix contexts docs plus FieldService lane-local context pattern.
defmodule CrosswakeExample.LearnLoop.Fixtures do
  def learner!("iris") do
    %{
      id: "iris",
      name: "Iris Learner",
      cohort: "Brightpath Academy",
      current_course_id: "elixir-routing-foundations"
    }
  end

  def active_pack_for(_learner) do
    %{
      id: "learnloop_daily_pack",
      label: "Daily Elixir Pack",
      offline: :local_first,
      storage: :indexed_db,
      sync_model: :append_only_review_events
    }
  end
end
```

### Ecto Idempotent Replay

```elixir
# Source: current LocalFirst.Study sync path and Ecto insert_all/on_conflict docs.
valid_rows =
  events
  |> Enum.map(&ReviewEvent.changeset(%ReviewEvent{}, &1))
  |> Enum.filter(& &1.valid?)
  |> Enum.map(&Ecto.Changeset.apply_changes/1)
  |> Enum.map(&Map.from_struct/1)

Repo.insert_all(ReviewEvent, valid_rows,
  on_conflict: :nothing,
  conflict_target: :client_mutation_id,
  returning: true
)
```

### LiveViewTest for LiveView-Owned Shell Routes

```elixir
# Source: Phoenix.LiveViewTest docs.
test "learner opens a gated LearnLoop lesson", %{conn: conn} do
  {:ok, view, _html} = live(conn, ~p"/learnloop")

  view
  |> element("a", "Continue course")
  |> render_click()

  assert render(view) =~ "Backend projection required"
  refute render(view) =~ "StoreKit support shipped"
end
```

### Playwright Proof for Socketless Offline Island

```typescript
// Source: existing offline route proof helpers and Playwright BrowserContext offline API.
await page.goto('/learnloop/study/session');
await expect(page.getByText('Saved locally')).toBeVisible();

const hasLiveSocket = await page.evaluate(() => Boolean((window as any).liveSocket));
expect(hasLiveSocket).toBe(false);

await context.setOffline(true);
await page.getByRole('button', { name: /good/i }).click();
await expect(page.getByText(/Queued for replay/)).toBeVisible();
```

### Entitlement Projection Copy

```elixir
# Source: existing commerce projection helper and commerce guide fail-closed posture.
def access_message(:granted), do: "Access active from backend projection"
def access_message(:pending), do: "Access stays closed until backend projection refreshes"
def access_message(:stale), do: "Backend projection required"
def access_message(:denied), do: "No active learning access"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Generic WebView wrapper framing | Phoenix route-policy/runtime-contract framing | Current project thesis | Phase 151 must make runtime owner explicit per route. [VERIFIED: .planning/PROJECT.md] [VERIFIED: AGENTS.md] |
| "Offline app" marketing | Explicit split between cached read-only routes and one route-local offline island | Current Crosswake guides and v19 context | Copy, route metadata, and tests must avoid implying broad offline mutation. [VERIFIED: guides/offline.md] [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md] |
| LiveView study interaction as offline proof | Socketless IndexedDB/offline HTML island with browser outbox | Existing `/offline` proof route | `/learnloop/study/session` should wrap or refactor `/offline`, not promote current LiveView simulation. [VERIFIED: examples/phoenix_host/lib/crosswake_example_web/controllers/offline_controller.ex] [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/study_session_live.ex] |
| Device/storefront evidence grants subscription access | Backend-owned entitlement projection grants access; storefront evidence remains evidence | Existing commerce lane and commerce guide | LearnLoop paywall pressure must fail closed unless backend projection is `granted`. [VERIFIED: guides/commerce.md] [VERIFIED: examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex] |
| Screenshot-first showcase proof | Semantic assertions first, screenshots as collateral | Existing v19 route-tour pattern | Route tour should prove route owner, socket absence, IndexedDB queueing, idempotency, entitlement copy, and support labels before screenshots. [VERIFIED: examples/phoenix_host/e2e/route_tour.spec.ts] |

**Deprecated/outdated:**

- Treating `/study/session` as canonical offline proof is outdated for Phase 151 because the current implementation is LiveView-driven. [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/study_session_live.ex] [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md]
- Claiming native storage, broad background sync, StoreKit, Play Billing, or RevenueCat support is out of scope for Phase 151. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md]
- Building a global `crosswake_dashboard` is deferred; lane-local diagnostics are sufficient for this phase. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Exact module names in the recommended project structure are planner-discretion examples, not locked decisions. [ASSUMED] | Architecture Patterns | Planner may choose different names; risk is low if ownership boundaries remain intact. |

## Open Questions

1. **Should entitlement state get narrow persistence or stay deterministic/mocked?**
   - What we know: Context allows at most a narrow mocked/backend-owned entitlement snapshot or event record if needed. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md]
   - What's unclear: The phase can likely satisfy LEARN-03 with existing commerce projection state and deterministic fixtures, but refresh-proof subscription pressure may benefit from one narrow persisted record. [VERIFIED: examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex] [ASSUMED]
   - Recommendation: Start with existing commerce projection helpers; add persistence only if tests need state to survive reset/reconnect paths. [VERIFIED: guides/commerce.md] [ASSUMED]

2. **Should `/learnloop/study/session` wrap `/offline` or refactor it into a LearnLoop controller/template?**
   - What we know: `/offline` is the proven socketless route, and `/study/session` is not acceptable as canonical offline proof while it uses LiveView events. [VERIFIED: examples/phoenix_host/lib/crosswake_example_web/controllers/offline_controller.ex] [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/study_session_live.ex]
   - What's unclear: Whether duplicating/adapting the template or routing both paths through one controller best fits current Phoenix host organization. [ASSUMED]
   - Recommendation: Prefer a LearnLoop-named controller/template that reuses the existing JS and proof semantics, leaving `/offline` as a reachable proof route. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md] [ASSUMED]

3. **Should `/learnloop/sync` exist?**
   - What we know: Context allows reusing `/study/sync` or adding `/learnloop/sync` as a delegating alias. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md]
   - What's unclear: Product copy and route-tour flow may or may not need the product-named endpoint. [ASSUMED]
   - Recommendation: Add the alias only if it improves route-tour coherence; it must delegate to the same controller/path. [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Phoenix host, tests, Mix tasks | yes | 1.19.5 | none needed. [VERIFIED: local `elixir --version`] |
| Erlang/OTP | Elixir runtime | yes | 28 | none needed. [VERIFIED: local `elixir --version`] |
| Mix | Dependency management and test commands | yes | 1.19.5 | none needed. [VERIFIED: local `mix --version`] |
| Node.js | Playwright and npm scripts | yes | 22.14.0 | none needed. [VERIFIED: local `node --version`] |
| npm | Playwright dependency install if needed | yes | 11.1.0 | none needed. [VERIFIED: local `npm --version`] |
| SQLite CLI | Local database inspection/support | yes | 3.51.0 | Ecto tasks can still manage DB without CLI for many flows. [VERIFIED: local `sqlite3 --version`] |
| Playwright local binary | Browser proof | yes | 1.60.0 | If missing in another checkout, run `npm ci` in `examples/phoenix_host`. [VERIFIED: local `examples/phoenix_host/node_modules/.bin/playwright --version`] |

**Missing dependencies with no fallback:** none observed for Phase 151 research. [VERIFIED: local environment probes]

**Missing dependencies with fallback:** none observed. [VERIFIED: local environment probes]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit, Phoenix.LiveViewTest, and Playwright. [VERIFIED: examples/phoenix_host/test] [VERIFIED: examples/phoenix_host/package-lock.json] |
| Config file | `examples/phoenix_host/test/test_helper.exs` and `examples/phoenix_host/playwright.config.ts`. [VERIFIED: examples/phoenix_host/test/test_helper.exs] [VERIFIED: examples/phoenix_host/playwright.config.ts] |
| Quick run command | `cd examples/phoenix_host && mix test test/crosswake_example/showcase/catalog_test.exs test/crosswake_example/showcase/reset_test.exs test/crosswake_example/showcase/hub_live_test.exs` [VERIFIED: examples/phoenix_host/test/crosswake_example/showcase] |
| Full suite command | `cd examples/phoenix_host && mix test && npx playwright test e2e/route_tour.spec.ts e2e/offline_sync.spec.ts` [VERIFIED: examples/phoenix_host/mix.exs] [VERIFIED: examples/phoenix_host/e2e] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| LEARN-01 | Product-first courses, lessons, packs, learner progress, and subscription state render and click through. [VERIFIED: .planning/REQUIREMENTS.md] | unit + LiveView | `cd examples/phoenix_host && mix test test/crosswake_example/learn_loop` | no, Wave 0 should add. [VERIFIED: examples/phoenix_host/test] |
| LEARN-02 | Offline study uses IndexedDB/outbox, visible queue/sync/rejected states, and honest content-pack posture. [VERIFIED: .planning/REQUIREMENTS.md] | Playwright + unit | `cd examples/phoenix_host && npx playwright test e2e/learnloop_offline.spec.ts` | no, Wave 0 should add or extend `offline_sync.spec.ts`. [VERIFIED: examples/phoenix_host/e2e/offline_sync.spec.ts] |
| LEARN-03 | Paywall/entitlement pressure is backend-owned or mocked and does not claim live provider support. [VERIFIED: .planning/REQUIREMENTS.md] | unit + LiveView + copy guardrail | `cd examples/phoenix_host && mix test test/crosswake_example/learn_loop/subscription_live_test.exs` | no, Wave 0 should add. [VERIFIED: examples/phoenix_host/test] |
| LEARN-04 | Representative workflow connects hub, LearnLoop LiveView shell, offline island, reconnect sync, history/progress, and diagnostics. [VERIFIED: .planning/REQUIREMENTS.md] | Playwright route tour | `cd examples/phoenix_host && npx playwright test e2e/route_tour.spec.ts` | yes, update required. [VERIFIED: examples/phoenix_host/e2e/route_tour.spec.ts] |

### Sampling Rate

- **Per task commit:** Run the affected LearnLoop ExUnit file plus existing showcase catalog/reset tests. [VERIFIED: examples/phoenix_host/test/crosswake_example/showcase]
- **Per wave merge:** Run `cd examples/phoenix_host && mix test` plus focused Playwright specs for route tour and offline sync. [VERIFIED: examples/phoenix_host/mix.exs] [VERIFIED: examples/phoenix_host/e2e]
- **Phase gate:** Full example-host ExUnit suite and Playwright LearnLoop route-tour/offline proof green before `$gsd-verify-work`. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md]

### Wave 0 Gaps

- [ ] `examples/phoenix_host/test/crosswake_example/learn_loop/fixtures_test.exs` - covers LEARN-01 fixture density and deterministic read models. [ASSUMED]
- [ ] `examples/phoenix_host/test/crosswake_example/learn_loop/diagnostics_test.exs` - covers route metadata/support truth for LEARN-04. [ASSUMED]
- [ ] `examples/phoenix_host/test/crosswake_example/learn_loop/dashboard_live_test.exs` - covers LearnLoop dashboard/product click path for LEARN-01. [ASSUMED]
- [ ] `examples/phoenix_host/test/crosswake_example/learn_loop/subscription_live_test.exs` - covers fail-closed entitlement copy and unsupported-claim guardrails for LEARN-03. [ASSUMED]
- [ ] Update `examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs`, `reset_test.exs`, and `hub_live_test.exs` for `/learnloop` CTA and reset digest truth. [VERIFIED: examples/phoenix_host/test/crosswake_example/showcase]
- [ ] Add `examples/phoenix_host/e2e/learnloop_offline.spec.ts` or extend `offline_sync.spec.ts` so `/learnloop/study/session` proves the same IndexedDB/outbox/socketless behavior. [VERIFIED: examples/phoenix_host/e2e/offline_sync.spec.ts] [ASSUMED]
- [ ] Update `examples/phoenix_host/e2e/route_tour.spec.ts` for the hub -> LearnLoop -> detail -> paywall -> offline -> history -> diagnostics path. [VERIFIED: examples/phoenix_host/e2e/route_tour.spec.ts]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Phase 151 uses deterministic learner fixtures and does not add real login/account identity. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md] |
| V3 Session Management | no | No new production session mechanism is in scope; existing Phoenix session behavior remains host-owned. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] [VERIFIED: .planning/REQUIREMENTS.md] |
| V4 Access Control | yes | Gated lesson/paywall state must fail closed unless backend projection is `granted`; storefront evidence alone does not authorize access. [VERIFIED: guides/commerce.md] [VERIFIED: examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex] |
| V5 Input Validation | yes | Sync payloads must keep using changesets and route params must resolve against deterministic fixture IDs. [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/study.ex] [CITED: https://ecto.hexdocs.pm/Ecto.Changeset.html] |
| V6 Cryptography | yes, by avoidance | Do not hand-roll purchase verification or cryptographic entitlement validation; live provider verification is out of scope. [VERIFIED: guides/commerce.md] [CITED: https://developer.apple.com/documentation/appstoreserverapi] [CITED: https://developer.android.com/google/play/billing/integrate] |
| V8 Data Protection | yes | Browser-owned IndexedDB/offline state must be labeled as device-local and not cleared by server reset; do not store secrets in the offline pack. [VERIFIED: examples/phoenix_host/priv/static/offline_study.js] [VERIFIED: examples/phoenix_host/lib/crosswake_example/showcase/reset.ex] |
| V10 Server-Side Request Forgery | no | Phase 151 does not introduce outbound URL fetching or provider webhooks. [VERIFIED: .planning/REQUIREMENTS.md] |

### Known Threat Patterns for Phoenix/LiveView + Offline Island + Entitlements

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Spoofed or malformed review event payload | Tampering | Validate event payloads with Ecto changesets and reject invalid rows. [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/study.ex] |
| Duplicate offline replay | Tampering / Repudiation | Keep `client_mutation_id` unique index and `on_conflict: :nothing`; route-tour should assert duplicate replay does not create a second row. [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex] [VERIFIED: examples/phoenix_host/e2e/offline_sync.spec.ts] |
| Device or mocked storefront evidence grants access | Elevation of Privilege | Gate learning access through backend entitlement projection and fail closed for pending/stale/denied. [VERIFIED: guides/commerce.md] [VERIFIED: examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex] |
| XSS through course/lesson fixture content | Tampering / Information Disclosure | Render fixture content through HEEx escaping and avoid raw HTML for lesson copy. [VERIFIED: Phoenix/HEEx project conventions in examples/phoenix_host/lib] [CITED: https://phoenix.hexdocs.pm/contexts.html] |
| Offline status overclaiming | Spoofing / Product safety risk | Mechanically test unsupported-claim copy and support labels; keep cached read-only and local-first labels distinct. [VERIFIED: guides/offline.md] [VERIFIED: guides/support_matrix.md] |
| Browser database privacy mode or quota behavior | Denial of Service | Preserve `navigator.storage.estimate()` reserve checks and graceful quota/offline status messages. [VERIFIED: examples/phoenix_host/priv/static/offline_study.js] [CITED: https://developer.mozilla.org/en-US/docs/Web/API/StorageManager/estimate] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/151-subscription-learning-showcase/151-CONTEXT.md` - locked Phase 151 scope, route ownership, data, UI, proof, discretion, and deferred ideas. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md]
- `.planning/REQUIREMENTS.md` - LEARN-01 through LEARN-04 and v19 anti-scope. [VERIFIED: .planning/REQUIREMENTS.md]
- `.planning/STATE.md` - current phase, v19 state, Phase 149/150 precedent, and anti-scope reminders. [VERIFIED: .planning/STATE.md]
- `.planning/ROADMAP.md` - Phase 151 success criteria and Phase 152 capability-map ownership. [VERIFIED: .planning/ROADMAP.md]
- `AGENTS.md` - project-specific constraints and working rules. [VERIFIED: AGENTS.md]
- `guides/route_policy.md` - route owner decisions and offline island/cached read-only semantics. [VERIFIED: guides/route_policy.md]
- `guides/offline.md` - cached read-only versus local-first behavior and no generic sync claim. [VERIFIED: guides/offline.md]
- `guides/commerce.md` - backend-owned commerce/paywall corridor and provider-adapter boundaries. [VERIFIED: guides/commerce.md]
- `guides/support_matrix.md` - support labels and capability-family truth. [VERIFIED: guides/support_matrix.md]
- `examples/phoenix_host/lib/crosswake_example/router.ex` - existing route metadata and sync/paywall routes. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex]
- `examples/phoenix_host/priv/static/offline_study.js` - existing IndexedDB/outbox/reconnect implementation. [VERIFIED: examples/phoenix_host/priv/static/offline_study.js]
- `examples/phoenix_host/lib/crosswake_example/local_first/study.ex` - append-only idempotent review-event sync. [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/study.ex]
- `examples/phoenix_host/e2e/offline_sync.spec.ts` and `examples/phoenix_host/e2e/route_tour.spec.ts` - current browser proof patterns. [VERIFIED: examples/phoenix_host/e2e]

### Secondary (MEDIUM confidence)

- Phoenix contexts official docs - context modules centralize application data and operations for web interfaces. [CITED: https://phoenix.hexdocs.pm/contexts.html]
- Ecto.Multi official docs - use transactions for grouped Repo operations; use simpler control flow otherwise. [CITED: https://ecto.hexdocs.pm/Ecto.Multi.html]
- Ecto constraints/upserts and Repo docs - unique indexes, `insert_all`, and `on_conflict: :nothing` support idempotent replay patterns. [CITED: https://ecto.hexdocs.pm/constraints-and-upserts.html] [CITED: https://ecto.hexdocs.pm/Ecto.Repo.html]
- Phoenix.LiveViewTest official docs - `live/2`, element selection, and `render_click` support LiveView route tests. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveViewTest.html]
- Playwright BrowserContext docs - isolated browser contexts and offline emulation support browser proof. [CITED: https://playwright.dev/docs/api/class-browsercontext]
- Playwright APIRequestContext docs - page request context can share browser context for API checks. [CITED: https://playwright.dev/docs/api/class-apirequestcontext]
- MDN IndexedDB and StorageManager docs - browser structured storage and quota/usage estimates. [CITED: https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API] [CITED: https://developer.mozilla.org/en-US/docs/Web/API/StorageManager/estimate]
- Google Play Billing docs - purchases must be verified securely before granting entitlements; pending purchases should not grant benefits. [CITED: https://developer.android.com/google/play/billing/integrate]
- Apple App Store Server API docs - server-side subscription status and signed transaction surfaces are the relevant production path, which Phase 151 defers. [CITED: https://developer.apple.com/documentation/appstoreserverapi]

### Tertiary (LOW confidence)

- No web-search-only non-authoritative sources were used for recommendations. [VERIFIED: research notes]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - versions were read from lockfiles, local runtime commands, and registries; no new package installs are recommended. [VERIFIED: examples/phoenix_host/mix.lock] [VERIFIED: examples/phoenix_host/package-lock.json] [VERIFIED: local environment probes]
- Architecture: HIGH - route ownership, data posture, offline proof, and entitlement boundaries are locked in phase context and supported by existing code. [VERIFIED: .planning/phases/151-subscription-learning-showcase/151-CONTEXT.md] [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex]
- Pitfalls: HIGH - pitfalls come from explicit phase decisions, current `/study/session` versus `/offline` implementation differences, and existing proof tests. [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/study_session_live.ex] [VERIFIED: examples/phoenix_host/lib/crosswake_example_web/controllers/offline_controller.ex] [VERIFIED: examples/phoenix_host/e2e/offline_sync.spec.ts]

**Research date:** 2026-07-11
**Valid until:** 2026-08-10 for project-local architecture; 2026-07-18 for package/version freshness and external storefront guidance. [ASSUMED]
