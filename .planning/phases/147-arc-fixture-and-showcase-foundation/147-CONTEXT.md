# Phase 147: Arc, Fixture, and Showcase Foundation - Context

**Gathered:** 2026-07-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 147 establishes the v19 showcase foundation: a first-screen example-host hub, deterministic/resettable showcase data, visible route-owner/support truth, and first-run discovery that points users at the showcase without weakening the existing proof lanes.

This phase does not implement the full SaaS/admin, field-service, or learning/training lane depth. It creates the foundation those later phases extend.

</domain>

<decisions>
## Implementation Decisions

### Showcase Hub Shape
- **D-01:** Make `/` the polished Crosswake showcase hub. Do not make `/showcase` the primary entrypoint. The current first-run path already probes and opens `/`, and phase 147's job is to make the first screen explain Crosswake without requiring docs first.
- **D-02:** Replace the minimal `PageController` home with a product-shaped hub surface, preferably a Phoenix-owned LiveView such as `CrosswakeExample.Showcase.HubLive`, declared as `runtime: :live_view`, `offline: :cached_read_only`, and `security: :standard`.
- **D-03:** The first viewport must show all three v19 domain lanes: SaaS/admin, field-service, and subscription learning/training. Each lane card should show what the user can click, what runtime ownership it demonstrates, and what is intentionally future pressure.
- **D-04:** Keep diagnostics, raw manifest/support detail, and legacy proof routes one click deeper. The hub should not expose backend implementation guts or read like a manifest inspector.
- **D-05:** Preserve old proof/demo routes (`/offline`, `/bridge-proof`, `/native/claims`, etc.) as reachable proof surfaces, but stop making them the main newcomer mental model.

### Fixture and Reset Ownership
- **D-06:** Add an example-host-local showcase fixture/reset orchestrator, not a Crosswake core abstraction. A shape like `CrosswakeExample.Showcase.Fixtures` plus `CrosswakeExample.Showcase.Reset` is preferred.
- **D-07:** Keep lane data ownership lane-local. SaaS/admin data stays with `SaaSPortal`, future field-service data should live with a field-service context/fixture module, and learning/training data should build on Flashcards/offline-study ownership. The showcase reset module orchestrates; it must not become a generic fixture engine.
- **D-08:** `priv/repo/seeds.exs`, a local Mix alias/task, and any `_e2e` reset endpoint should delegate to the same reset contract so local DX and CI reset the same server-side state.
- **D-09:** The reset endpoint, if added, must be gated to `:test`/`:e2e` or explicitly local/dev-only. It should return structured counts and/or a deterministic digest so tests can prove reset truth without depending on screenshots.
- **D-10:** Browser-owned offline state remains browser-owned. IndexedDB/outbox reset should continue through Playwright/browser helpers; the server-side showcase reset must not imply it reset local-first browser state.
- **D-11:** Do not model full Ecto schemas for every future domain in phase 147. Add schemas only where the lane needs server-authoritative mutation now. Static/read-only showcase records may remain deterministic maps until a later phase needs persistence.
- **D-12:** Avoid random/Faker-style records for the showcase baseline. Use stable IDs, names, counts, and timestamps where possible so screenshots, route tours, docs, and support labels remain repeatable.

### Route-Owner and Support Labels
- **D-13:** Use a hybrid label strategy: curated product-facing metadata rendered by the hub, mechanically verified against route policy/manifest/support truth where possible.
- **D-14:** Introduce a small shared metadata helper/catalog for showcase cards. It should own clear UI copy, allowed label vocabulary, lane grouping, route IDs, and v20 pressure notes, but it must not duplicate the entire route-policy DSL.
- **D-15:** Add tests that verify each showcased route ID/path exists and that expected runtime/offline/capability posture matches the compiled router/manifest or route policy source. This prevents the hub from becoming a shadow source of truth.
- **D-16:** Labels should be visible text badges, not color-only signals. Use brand microcopy such as "LiveView route", "Cached read-only", "Offline island", "Native screen", "Requires native runtime", "Demo pressure", and "Future native-control candidate".
- **D-17:** Be careful with support claims. Prefer "available today", "proof-backed example", "demo pressure", "advisory evidence", "future gap", or "next-pack candidate" over broad "supported" claims unless support-matrix proof already backs the claim.
- **D-18:** Save raw derivation and full capability-map classification for Phase 151. Phase 147 should make support truth visible, not build the complete capability map early.

### First-Run Discovery and Proof Path
- **D-19:** Update `bin/see-it-run.sh`, README, and first-run docs so the primary user-facing path is the showcase hub at `http://localhost:4700/`.
- **D-20:** Keep maintainer proof commands and route-tour evidence explicit but secondary. The banner/docs should distinguish "open the showcase" from "run the proof lane".
- **D-21:** Do not broaden the existing Playwright route-tour into a full v19 proof in this phase. Phase 151 owns route-tour coverage for the hub plus one happy path per domain lane.
- **D-22:** If collateral labels are updated in this phase, name them honestly: showcase screenshots explain the product surface; route-tour screenshots prove route-owner semantics. Do not let marketing screenshots become correctness evidence.

### UI, UX, and Brand Direction
- **D-23:** Follow `brandbook/BRAND-SPEC.md` as the current brand source of truth. Treat `prompts/crosswake-brand-book.md` as historical seed material only.
- **D-24:** The hub should use Crosswake's route-card and runtime-lane motif: route path in monospace, runtime badge, offline/support status, capability chips, and a short boundary warning where relevant.
- **D-25:** Use current tokens from `priv/static/crosswake/tokens.css` / `examples/phoenix_host/priv/static/css/tokens.css`. Support light/dark/system behavior, visible focus rings, reduced-motion fallbacks, and accessible contrast.
- **D-26:** Keep copy user/JTBD-focused. A newcomer should understand what they can click and what Crosswake is proving. Backend/internal details should appear only when needed to explain an ownership boundary.
- **D-27:** The first screen should feel like a working product showcase, not a landing page or docs index. No oversized marketing-only hero, no generic SaaS card wall, no unsupported native-control hype.

### Claude's Discretion
- The planner may choose exact module names, component boundaries, and task/alias names, as long as they preserve the decisions above.
- The planner may decide whether the initial hub route is a LiveView or controller-backed HEEx page if implementation constraints demand it, but dynamic reset state and Phoenix route navigation strongly favor LiveView.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and Arc Scope
- `.planning/PROJECT.md` — Current Crosswake thesis, v19/v20 arc, constraints, and key decisions.
- `.planning/REQUIREMENTS.md` — Phase 147 requirements: ARC-01..03 and SHOW-01..04.
- `.planning/ROADMAP.md` — Phase 147 goal and success criteria.
- `.planning/STATE.md` — Current milestone state and locked v19 roadmap decisions.
- `.planning/MILESTONE-ARC.md` — Strategic source of truth for showcase-first, controls-next sequencing.

### Brand and UI Contract
- `brandbook/BRAND-SPEC.md` — Current brand, UI, badge, accessibility, motion, and microcopy rules; supersedes prompt-era brand notes.
- `priv/static/crosswake/tokens.css` — Packaged token surface.
- `examples/phoenix_host/priv/static/css/tokens.css` — Example-host token copy currently consumed by showcase/example UI.
- `examples/phoenix_host/priv/static/css/app.css` — Existing shared example-host structural classes, cards, buttons, badges, grid, and token usage.

### Existing Example Host Surfaces
- `examples/phoenix_host/lib/crosswake_example/router.ex` — Current root route, route policies, lane routes, and `_e2e` namespace pattern.
- `examples/phoenix_host/README.md` — Shared example-host artifact rules and proof-backed lane boundary.
- `examples/phoenix_host/priv/repo/seeds.exs` — Current server-side seed path and idempotency pattern.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/fixtures.ex` — Existing in-memory SaaS/admin fixture shape.
- `examples/phoenix_host/lib/crosswake_example/selective_native/fixtures.ex` — Existing selective-native seed helper; currently can duplicate rows if called repeatedly.
- `examples/phoenix_host/lib/crosswake_example/flashcards.ex` — Existing learning/training data context.
- `examples/phoenix_host/priv/static/offline_study.js` — Browser-owned offline-study seed/outbox behavior.
- `examples/phoenix_host/e2e/route_tour.spec.ts` — Existing route-owner semantic proof before screenshots.
- `examples/phoenix_host/e2e/support/offline_route_proof.ts` — Existing IndexedDB reset/proof helpers; keep browser state reset here.

### First-Run and Proof Docs
- `bin/see-it-run.sh` — First-run launcher and banner that should point primarily to `/`.
- `README.md` — Public repo first-run entrypoint.
- `guides/see_it_run.md` — Existing first-run guide and native evidence framing.
- `examples/QUICK_START.md` — Proof command reference.
- `guides/route_policy.md` — Route-owner mental model.
- `guides/support_matrix.md` — Canonical support labels, proof classes, advisory-vs-required posture.

### Prompt Research to Apply
- `prompts/crosswake-research-synthesis.md` — Compressed architecture thesis and anti-patterns.
- `prompts/crosswake-elixir-oss-dna.md` — Maintainer OSS style: install truth, support honesty, proof lanes, release truth.
- `prompts/crosswake-gsd-project-brief.md` — Crosswake initialization brief and product boundaries.
- `prompts/crosswake-integrations-and-companions.md` — Core/companion/example/defer classification heuristics.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` — App archetype and capability-ladder research, including SaaS, field service, learning/training, and native-control pressure.
- `prompts/elixir-mobile-offlinesupport-flashcard-app-stresstest-deep-research.md` — Offline island/content-pack lessons for learning/training flows.
- `prompts/elixir-mobile-oss-lib-deep-research.md` — Cross-ecosystem footguns and DX lessons.
- `prompts/crosswake-brand-book.md` — Historical brand seed only; use `brandbook/BRAND-SPEC.md` when conflicts exist.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `examples/phoenix_host/lib/crosswake_example/router.ex`: already declares route owner/runtime/offline/capability metadata for root, SaaS, native-pressure, commerce, media, and deck routes.
- `examples/phoenix_host/priv/static/css/app.css`: provides token-backed `.page-container`, `.card`, `.btn-*`, `.badge`, and grid classes suitable for a first pass.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/*`: existing SaaS/admin lane data and LiveViews can seed the SaaS card and later deep lane.
- `examples/phoenix_host/lib/crosswake_example/selective_native/*`: existing native-pressure claim flow can inform the field-service lane while avoiding overclaiming capture/scanning support.
- `examples/phoenix_host/lib/crosswake_example/flashcards/*` plus `priv/static/offline_study.js`: existing learning/offline-study proof can seed the learning/training lane.
- `examples/phoenix_host/e2e/route_tour.spec.ts`: established pattern of semantic route-owner assertions before screenshots.

### Established Patterns
- Phoenix seeds convention is already used through `priv/repo/seeds.exs`; keep that as the human-known entrypoint.
- Example-host routes are proof artifacts, not core Crosswake product APIs.
- Existing proof posture separates deterministic web/ExUnit proof from advisory native/device evidence.
- Crosswake docs and support matrix prefer explicit support labels over broad claims.
- Current route-tour proof reads source/router truth before taking screenshots; preserve that ordering.

### Integration Points
- Root route `/` should be rewired from the minimal `PageController` output to the showcase hub.
- `bin/see-it-run.sh` banner should advertise the showcase first, then proof commands.
- README, `guides/see_it_run.md`, and `examples/QUICK_START.md` need wording updates once the hub exists.
- A local reset task/alias and optional `_e2e` endpoint should delegate to the shared showcase reset contract.

</code_context>

<specifics>
## Specific Ideas

- Recommended hub narrative: "Phoenix routes, native where it matters" with three lane cards and route-owner badges.
- Recommended lane card structure: lane name, who/JTBD, primary route, runtime owner badges, offline/support status, future pressure note, and one clear CTA.
- Recommended first-run split: "Open the showcase" for newcomers; "Run route-owner proof" for maintainers.
- External ecosystem lessons considered:
  - Phoenix favors explicit tests, support files, and `priv/repo/seeds.exs` for seed data.
  - Laravel's seeder classes and call ordering reinforce a modular seed orchestrator pattern.
  - Rails/Django fixtures show the value of consistent data and the footgun of raw fixtures becoming too broad or test-only.
  - Hotwire Native's path configuration, bridge components, and native screens validate route/path ownership as a mobile-web pattern, but Crosswake should keep Phoenix route policy as the center.
  - Expo runtime-version guidance reinforces Crosswake's existing compatibility-gate posture: server/web updates must not assume unavailable native code.

</specifics>

<deferred>
## Deferred Ideas

- Full capability map, proof classification, and v20 Native Controls Pack 1 handoff remain Phase 151 scope.
- Production native controls such as alert/confirm, menus, haptics expansion, share sheet expansion, permission UX, scanner, document capture, biometrics, NFC, and location APIs remain v20+ or later scope unless existing contracts already cover them.
- Full field-service and learning/training domain modeling belongs to Phases 149 and 150.
- `crosswake_dashboard`, offline-sync/native-storage productization, and commerce/paywall productionization remain future milestones.

</deferred>

---

*Phase: 147-Arc, Fixture, and Showcase Foundation*
*Context gathered: 2026-07-09*
