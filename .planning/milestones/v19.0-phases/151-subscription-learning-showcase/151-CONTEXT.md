# Phase 151: Subscription Learning Showcase - Context

**Gathered:** 2026-07-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 151 builds the LearnLoop subscription learning/training lane as a polished, click-around product showcase. It should make a learner-facing course, lesson, content-pack, offline-study, progress, and subscription-pressure journey feel coherent while preserving Crosswake's route-policy thesis: LiveView owns the online learning shell, a real offline island owns the study loop, and backend-owned or mocked entitlement projection owns access truth.

This phase does not implement a broad LMS, course authoring system, adaptive learning engine, native SQLite storage layer, native study screen, production StoreKit/Play Billing/RevenueCat support, production commerce/paywall adapters, native media/audio/video downloads, generic sync helpers, `crosswake_dashboard`, or the Phase 152 capability map. Phase 151 should produce capability-map evidence, but Phase 152 owns the durable map and v20 handoff.

</domain>

<decisions>
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

### Claude's Discretion
- The planner may choose exact module names, whether `/learnloop/study/session` wraps `/offline` or refactors it into a LearnLoop controller/template, whether to add a `/learnloop/sync` alias, and whether a narrow entitlement snapshot needs a new table or can stay as deterministic/backend-mocked projection.
- The planner may refine exact route paths and copy as long as the primary UX is product-first and the offline/entitlement/support truth decisions above are preserved.
- The planner may decide whether diagnostics are inline cards, a right rail, or a details disclosure, as long as route/support truth remains mechanically testable and does not become `crosswake_dashboard`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and Milestone Scope
- `.planning/PROJECT.md` - Crosswake thesis, v19/v20 arc, constraints, and project-level decisions.
- `.planning/REQUIREMENTS.md` - Phase 151 requirements LEARN-01..04 and v19 anti-scope/proof boundaries.
- `.planning/ROADMAP.md` - Phase 151 goal and success criteria. Phase 152, not Phase 151, owns the capability map.
- `.planning/STATE.md` - Current phase state, locked v19 roadmap decisions, Phase 149/150 completion decisions, and anti-scope reminders.
- `.planning/phases/147-arc-fixture-and-showcase-foundation/147-CONTEXT.md` - Showcase hub, reset ownership, route/support labels, and first-run discovery decisions.
- `.planning/phases/149-saas-admin-showcase/149-CONTEXT.md` - Product-first lane, deterministic breadth plus narrow persistence, diagnostics, support truth, and route-tour proof pattern.
- `.planning/phases/150-field-service-showcase/150-CONTEXT.md` - Product-first lane, native-pressure truth, cached read-only honesty, backend-authority evidence pattern, and route-tour proof pattern.
- `.planning/phases/148-demo-app-brand-fixture-direction/148-VERIFICATION.md` - Locked LearnLoop micro-brand and fixture direction evidence.

### Brand, UI, and UX
- `brandbook/BRAND-SPEC.md` - Current canonical brand, accessibility, badge, layout, light/dark, motion, and microcopy rules. Use this over older prompt-era brand notes.
- `examples/phoenix_host/priv/static/css/tokens.css` - Example-host token copy consumed by showcase UI.
- `examples/phoenix_host/priv/static/css/app.css` - Existing shared CSS plus AdminPilot, Fieldserv, and LearnLoop brand/lane styling conventions.
- `examples/phoenix_host/lib/crosswake_example/showcase/branding.ex` - LearnLoop brand, fixture brief, personas, records, activity, and pressure note.
- `examples/phoenix_host/lib/crosswake_example/showcase/catalog.ex` - Current LearnLoop card metadata, route labels, and support-label vocabulary.
- `examples/phoenix_host/lib/crosswake_example/showcase/hub_live.ex` - Root showcase rendering that should point to the product-first LearnLoop lane after Phase 151.

### Existing Learning and Offline Code
- `examples/phoenix_host/lib/crosswake_example/router.ex` - Current `/study`, `/offline`, `/library`, `/decks`, `/commerce`, and route metadata declarations.
- `examples/phoenix_host/lib/crosswake_example/flashcards.ex` - Current flashcards context, seed reset, and digest components.
- `examples/phoenix_host/lib/crosswake_example/flashcards/deck.ex` - Existing deck schema.
- `examples/phoenix_host/lib/crosswake_example/flashcards/card.ex` - Existing card schema.
- `examples/phoenix_host/lib/crosswake_example/flashcards/progress.ex` - Existing progress schema.
- `examples/phoenix_host/lib/crosswake_example/local_first/study.ex` - Server-side sync context and idempotent review-event insertion.
- `examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex` - Existing append-only review event schema.
- `examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex` - Existing `/study/sync` API seam.
- `examples/phoenix_host/lib/crosswake_example/local_first/study_session_live.ex` - Current LiveView simulation; do not treat as canonical offline proof unless converted.
- `examples/phoenix_host/lib/crosswake_example/local_first/study_history_live.ex` - Current cached read-only server-confirmed history surface.
- `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_controller.ex` - Existing socketless offline study controller.
- `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex` - Existing offline island HTML and token-backed inline styling.
- `examples/phoenix_host/priv/static/offline_study.js` - Existing IndexedDB/outbox implementation and reconnect flush behavior.

### Existing Commerce and Entitlement Code
- `examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex` - Existing mocked paywall and backend projection states.
- `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex` - Existing derived entitlement state helper.
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex` - Existing purchase/restore evidence ingestion helper.
- `examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex` - Existing mock storefront evidence helper.
- `examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex` - Existing mocked backend verification/broadcast helper.
- `examples/phoenix_host/lib/crosswake_example/commerce/mock_backend_verifier.ex` - Existing backend verifier helper.
- `examples/phoenix_host/lib/crosswake_example/commerce/provider_adapter_storefront.ex` - Existing provider adapter facade.
- `lib/crosswake/commerce.ex` - Public commerce behaviour.
- `lib/crosswake/commerce/contracts.ex` - Public commerce contract structs if present in the current tree.

### Existing Tests and Proof Patterns
- `examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs` - Route metadata drift, support-label allowlist, and compiled router truth pattern.
- `examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs` - Reset idempotency and deterministic count/digest proof pattern.
- `examples/phoenix_host/test/crosswake_example/showcase/hub_live_test.exs` - Showcase rendering, fixture preview, and visible support-label pattern.
- `examples/phoenix_host/test/crosswake_example/e2e/showcase_reset_controller_test.exs` - Reset endpoint proof pattern.
- `examples/phoenix_host/test/crosswake_example/flashcards_test.exs` - Existing flashcards context test baseline.
- `examples/phoenix_host/test/crosswake_example/e2e/sync_state_controller_test.exs` - Existing sync-state inspection proof.
- `examples/phoenix_host/e2e/offline_sync.spec.ts` - Existing real offline IndexedDB/outbox/reconnect/Ecto proof.
- `examples/phoenix_host/e2e/support/offline_route_proof.ts` - Existing browser-owned IndexedDB reset and sync proof helpers.
- `examples/phoenix_host/e2e/route_tour.spec.ts` - Browser route-tour semantic assertions and screenshot collateral pattern.

### Crosswake Concept Guides
- `guides/route_policy.md` - Route owner decisions, offline island, cached read-only, native screen, and explicit defer guidance.
- `guides/offline.md` - Cached read-only versus true local-first offline behavior.
- `guides/capabilities.md` - Ownership-first capability rubric, commerce/backend seams, native pressure, and no plugin-catalog rule.
- `guides/support_matrix.md` - Support-truth labels, proof classes, commerce/paywall posture, and capability-family truth.
- `guides/commerce.md` - Backend-owned commerce/paywall corridor guidance and provider-adapter boundaries.
- `guides/native_shell.md` - Native runtime boundaries, permission/entitlement templates, and rebuild expectations.
- `guides/bridge.md` - Bounded bridge contracts and denial/authority rules.
- `guides/compatibility.md` - Runtime, bridge, manifest, capability, and rebuild guidance.
- `guides/user_flows.md` - Offline study and learner flow guidance.
- `guides/adopter_profiles.md` - Learning/training and subscription app profile context.

### Prompt Research to Apply
- `prompts/crosswake-research-synthesis.md` - Current Crosswake architecture thesis and anti-patterns.
- `prompts/crosswake-elixir-oss-dna.md` - Maintainer house style: install truth, support honesty, proof lanes, docs, and release truth.
- `prompts/crosswake-integrations-and-companions.md` - Commerce/Accrue, Rindle/media, Threadline/audit, and companion/docs-only classification heuristics.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` - Learning/training, subscription, route ladder, content packs, offline islands, commerce, and native-control pressure.
- `prompts/elixir-mobile-offlinesupport-flashcard-app-stresstest-deep-research.md` - Offline flashcard architecture, content packs, append-only review events, sync/reconciliation, and local storage lessons.
- `prompts/elixir-mobile-oss-lib-deep-research.md` - Cross-ecosystem footguns, DX lessons, billing guardrails, offline honesty, native media, and testing posture.
- `prompts/elixir-mobile-apptypes-design-stresstest-deep-research.md` - Use only where it adds app-archetype/design nuance not superseded by current planning docs.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `CrosswakeExample.Flashcards` already owns flashcard seed/reset/digest data and basic deck/card/progress persistence.
- `CrosswakeExample.LocalFirst.Study` and `ReviewEvent` already implement idempotent append-only review-event sync with `insert_all` and `on_conflict: :nothing`.
- `priv/static/offline_study.js` already queues app-generated UUID mutations in IndexedDB, flushes on reconnect, deletes accepted rows, handles quota errors, and exposes clear status text.
- `/offline` already provides the real socketless offline island proof; it should be wrapped or renamed carefully instead of replaced by LiveView simulation.
- `/study/history` already provides a cached read-only server-confirmed review history surface.
- `/commerce/paywall` and commerce helpers already model mocked storefront evidence, backend projection, pending/granted/denied/stale states, and PubSub updates.
- `Showcase.Branding`, `Showcase.Catalog`, and `Showcase.Reset` already provide the lane brand, card metadata, reset orchestration, and digest integration points.
- `route_tour.spec.ts`, `offline_sync.spec.ts`, and `offline_route_proof.ts` already prove semantic route ownership before screenshots and have reusable IndexedDB/offline helpers.
- `app.css` already contains token-backed lane shell patterns for AdminPilot and Fieldserv plus a LearnLoop brand class.

### Established Patterns
- v19 showcase lanes are product-shaped proof artifacts, not core Crosswake APIs and not starter-app frameworks.
- The first impression should be the fictional app workflow; Crosswake route policy and support truth appear as badges, compact panels, and diagnostics.
- Static fixture breadth is acceptable for realistic context; persisted state is added only where it proves workflow authority or refresh-proof evidence.
- Server-side reset never claims browser-owned IndexedDB/outbox reset.
- Support labels and route metadata must be mechanically checked against router/catalog truth where possible.
- Browser route-tour screenshots are collateral after semantic assertions pass.
- Native/provider/device claims stay narrow unless proof-backed by support matrix and deterministic/advisory proof lanes.

### Integration Points
- Add a LearnLoop context/module boundary around deterministic courses, lessons, packs, learner/progress fixtures, route posture, entitlement projection, and diagnostics.
- Add product-first `/learnloop/*` routes with explicit Crosswake metadata and update the root showcase card to target LearnLoop rather than `/offline`.
- Refactor or wrap `/offline` into `/learnloop/study/session` without losing socketless behavior, IndexedDB database naming truth, outbox semantics, or Playwright reset helpers.
- Keep or alias `POST /study/sync`; do not invent a second sync implementation unless it delegates to the same `LocalFirst.Study.sync_events/1` path.
- Extend `Showcase.Reset` and digest components to include LearnLoop deterministic breadth and any new narrow persisted evidence.
- Reuse commerce projection helpers for backend-owned subscription pressure; avoid a new live provider/storefront abstraction.
- Extend ExUnit and Playwright route-tour coverage for the LearnLoop happy path and support-truth assertions.

</code_context>

<specifics>
## Specific Ideas

### Recommended Lane Narrative
- "LearnLoop keeps course discovery, progress, and subscription posture Phoenix-owned, then opens a real offline study island for the local-first review loop."
- "Content packs explain what can be studied offline; review events explain what was saved locally; backend projection explains what access is allowed."

### Recommended First Screen
- Learner header with Brightpath Academy / LearnLoop brand, current learner, streak or learning momentum, and next recommended pack.
- Course/progress overview with one active course, one gated lesson, one offline-ready pack, and one server-confirmed progress/history summary.
- Compact route/support badges: `LiveView route`, `Cached read-only`, `Offline island`, `Local-first outbox`, `Backend projection`, and `Mocked storefront evidence`.
- Primary action: start the next study session. Secondary action: inspect subscription/access or route diagnostics.

### Recommended Product Path
- Dashboard: "Today's path", active pack, sync status, entitlement status.
- Course or pack detail: lessons/cards, content-pack metadata, offline-ready status, and route ownership.
- Gated lesson/paywall pressure: backend projection required, mocked storefront evidence, no live provider claim.
- Study session: socketless IndexedDB island with flip/good/hard or equivalent actions, saved locally/queued/syncing/synced statuses.
- History/progress: server-confirmed review events and projection, with stale/read-only posture if offline.
- Diagnostics: route id, path, owner, offline posture, content pack, sync/reconciliation state, entitlement authority, support label, proof posture, and future v20 pressure.

### Domain Language
- Nouns: `learner`, `coach`, `course`, `lesson`, `content_pack`, `deck`, `card`, `offline_session`, `review_event`, `outbox_item`, `sync_batch`, `sync_checkpoint`, `progress_checkpoint`, `subscription_snapshot`, `entitlement_evidence`, `route_posture`, and `support_finding`.
- Verbs/events: `open_dashboard`, `browse_course`, `inspect_pack`, `gate_lesson`, `request_entitlement_refresh`, `start_offline_study`, `answer_card`, `queue_review_event`, `sync_reviews`, `reject_review_event`, `project_progress`, `view_history`, and `inspect_route_posture`.

### External Research Applied
- Phoenix contexts guidance supports keeping LearnLoop business/data functions in context modules and using LiveViews/controllers as web interfaces, not scattering logic in templates.
- Ecto.Multi guidance supports transactions for multi-fact state changes, but ordinary control flow is simpler when only one persisted fact changes.
- LiveViewTest supports fast process-level tests for `phx-` events on LiveView-owned shell routes; Playwright is still needed for socketless offline island/browser storage proof.
- Android offline-first guidance reinforces local data plus local writes/events and reconciliation; at minimum, real offline must read local data without network and should not call the network layer directly from UI.
- Hotwire Native path configuration is a useful precedent for route/path behavior, but Crosswake should keep Phoenix route metadata as the authority.
- Duolingo and Moodle lessons reinforce a path/progress model: show the right next lesson, make progress visible, and avoid forcing users to understand backend mechanics.
- Google Play Billing guidance explicitly verifies purchases on a secure backend before granting entitlements, with pending purchases not granting access. Apple StoreKit/App Store Server API guidance similarly treats signed transaction/subscription status as a backend-visible purchase truth surface.

</specifics>

<deferred>
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

</deferred>

---

*Phase: 151-Subscription Learning Showcase*
*Context gathered: 2026-07-11*
