# Phase 147: arc-fixture-and-showcase-foundation - Research

**Researched:** 2026-07-09  
**Domain:** Phoenix LiveView example-host showcase, deterministic fixtures/reset, route-policy support labels, first-run DX  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### the agent's Discretion
- The planner may choose exact module names, component boundaries, and task/alias names, as long as they preserve the decisions above.
- The planner may decide whether the initial hub route is a LiveView or controller-backed HEEx page if implementation constraints demand it, but dynamic reset state and Phoenix route navigation strongly favor LiveView.

### Deferred Ideas (OUT OF SCOPE)
- Full capability map, proof classification, and v20 Native Controls Pack 1 handoff remain Phase 151 scope.
- Production native controls such as alert/confirm, menus, haptics expansion, share sheet expansion, permission UX, scanner, document capture, biometrics, NFC, and location APIs remain v20+ or later scope unless existing contracts already cover them.
- Full field-service and learning/training domain modeling belongs to Phases 149 and 150.
- `crosswake_dashboard`, offline-sync/native-storage productization, and commerce/paywall productionization remain future milestones.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ARC-01 | Maintainer can read the planning docs and see the durable multi-milestone thread: v19 showcase, v20 Native Controls Pack 1, then capture/device, commerce/paywall, operator dashboard, and offline-sync/native-storage follow-ons. | `.planning/MILESTONE-ARC.md`, `.planning/PROJECT.md`, `.planning/STATE.md`, `.planning/ROADMAP.md`, and `.planning/REQUIREMENTS.md` already encode the showcase-first, controls-next arc, so the plan should update only the active v19/v20 wording and avoid new product breadth. [VERIFIED: codebase grep] |
| ARC-02 | Maintainer can see SEED-002 reflected as strategic input for capability breadth without treating v19 as the broad native-controls implementation milestone. | `.planning/STATE.md` classifies SEED-002 as active strategic input for v19 capability map and v20 handoff, not as Phase 147 implementation scope. [VERIFIED: codebase grep] |
| ARC-03 | Maintainer can see SEED-003 and SEED-004 classified as release-infrastructure carryovers rather than v19 headline scope. | `.planning/STATE.md` carries mirror-token and clean-room proof risks as release-infrastructure concerns, and Phase 147 should preserve that classification in docs edits. [VERIFIED: codebase grep] |
| SHOW-01 | User can open a first-screen showcase hub from the example host and understand the three domain lanes without reading implementation docs first. | `/` currently renders a minimal inline controller page from `examples/phoenix_host/lib/crosswake_example/router.ex:1-27` and is routed at `router.ex:163-168`, so the implementation should replace root with `CrosswakeExample.Showcase.HubLive` or an equivalent Phoenix-owned hub. [VERIFIED: codebase grep] |
| SHOW-02 | User can reset or reseed deterministic showcase data so every demo lane starts from a believable, repeatable state. | Current seeds delete Flashcard child rows before parent rows and insert fixed learning data in `priv/repo/seeds.exs:23-58`; SaaS data is deterministic in-memory maps in `saas_portal/fixtures.ex:6-60`; selective-native fixtures insert rows without clearing in `selective_native/fixtures.ex:4-7`, so the reset plan must centralize orchestration and make counts/digests observable. [VERIFIED: codebase grep] |
| SHOW-03 | User can see explicit route-owner/support labels in the showcase so LiveView, offline island, native-pressure, and unsupported-gap surfaces are not blurred together. | Crosswake route metadata is attached to Phoenix route metadata at compile time through `Crosswake.Policy.RouterMetadata`, and `CrosswakeExample.Crosswake.Policy.compile/1` normalizes route policy, so curated hub labels can be mechanically verified against compiled route truth. [VERIFIED: codebase grep] |
| SHOW-04 | User can run the existing first-run path and discover the showcase as the product-shaped Crosswake entrypoint. | `bin/see-it-run.sh` already opens/probes `http://localhost:4700/`, but its banner still describes `/` as "Phoenix-owned home" and foregrounds `/offline` plus `/bridge-proof`; README, `guides/see_it_run.md`, and `examples/QUICK_START.md` still frame the first run around three route-owner links. [VERIFIED: codebase grep] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Read `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` before planning or implementation work. [VERIFIED: AGENTS.md]
- Preserve the thesis that Crosswake is a Phoenix-first route-policy and runtime-contract system, not a universal UI framework. [VERIFIED: AGENTS.md]
- Keep runtime ownership explicit per route and avoid generic WebView wrapper behavior or LiveView-driven native rendering. [VERIFIED: AGENTS.md]
- Treat bridge contracts as semantic, typed, versioned, and low-frequency; flows needing continuous client authority should move toward offline islands or native screens. [VERIFIED: AGENTS.md]
- Keep offline claims honest by separating cached read-only behavior from local-first mutation with journals, outboxes, and reconciliation. [VERIFIED: AGENTS.md]
- Treat diagnostics, support matrices, proof lanes, and rough-edge documentation as product surface. [VERIFIED: AGENTS.md]
- Respect v1 scope boundaries before adding integrations or wider native breadth. [VERIFIED: AGENTS.md]
- No `CLAUDE.md`, `.claude/CLAUDE.md`, `.codex/skills`, `.agents/skills`, or `.claude/skills` files exist in this checkout, so there are no additional local skill directives to apply. [VERIFIED: codebase grep]

## Summary

Phase 147 should be planned as an example-host foundation phase, not as core Crosswake framework expansion. The root `/` route is currently a minimal inline `PageController` defined in `router.ex`, while the router already has rich route-policy metadata for SaaS/admin, selective-native, commerce, media, study, and deck routes. [VERIFIED: codebase grep]

The strongest plan shape is: add `CrosswakeExample.Showcase` modules under `examples/phoenix_host/lib/crosswake_example/showcase/`, replace the root route with a Phoenix-owned hub LiveView, add a small product-facing route-card catalog, verify catalog entries against compiled route metadata, and add a reset orchestrator that delegates to lane-owned fixture modules. [VERIFIED: codebase grep] Phoenix LiveView docs support direct `live` route declarations in the main router, and Phoenix Router docs support using router metadata/introspection rather than duplicating route truth. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html] [CITED: https://hexdocs.pm/phoenix/Phoenix.Router.html]

The reset path should be deterministic and server-side only: `priv/repo/seeds.exs`, a local Mix alias/task, and any `_e2e` reset endpoint should call one reset contract that returns counts and a digest. [VERIFIED: 147-CONTEXT.md] Browser-owned IndexedDB state is already reset through Playwright helpers and must stay out of the server reset claim. [VERIFIED: codebase grep]

**Primary recommendation:** Use the existing Phoenix/LiveView/Ecto/Playwright stack, create a small showcase hub/catalog/reset namespace in the example host, and verify route labels against compiled Crosswake route metadata instead of hand-maintaining support truth. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Root showcase hub at `/` | Frontend Server (SSR/LiveView) | Browser / Client | The existing example host is Phoenix-owned, and LiveView route docs support declaring a root LiveView directly in the router; client behavior should be limited to normal navigation and progressive UI. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html] |
| Route-owner/support labels | Frontend Server (SSR/LiveView) | API / Backend | Product copy belongs in the hub catalog, while truth should be checked against compiled router metadata and Crosswake policy compilation. [VERIFIED: codebase grep] |
| Deterministic server reset/reseed | API / Backend | Database / Storage | Ecto tables, in-memory lane fixtures, seeds, and optional `_e2e` reset endpoints are server-owned; Ecto docs support `delete_all`, inserts, and transactions for reset work. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] |
| Browser offline reset | Browser / Client | API / Backend | Offline study cards and outbox live in IndexedDB, and existing Playwright helpers reset that browser database before page scripts open it. [VERIFIED: codebase grep] |
| First-run discovery | CDN / Static and Shell Script | Frontend Server (SSR/LiveView) | `bin/see-it-run.sh`, README, and guides point users at `http://localhost:4700/`; the hub route must become the product-shaped destination those docs already open. [VERIFIED: codebase grep] |
| Planning arc preservation | Documentation / Planning | API / Backend | ARC requirements are planning-artifact requirements; implementation should not add native-control breadth while documenting the v19 to v20 sequence. [VERIFIED: .planning/REQUIREMENTS.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `elixir` / `mix` | Elixir `~> 1.19`; local Mix `1.19.5` | Compile and test the Phoenix example host. | The example host `mix.exs` pins Elixir `~> 1.19`, and the local environment reports Mix `1.19.5`. [VERIFIED: mix.exs] [VERIFIED: local command] |
| `phoenix` | `1.8.7` in `examples/phoenix_host/mix.lock` | Router, controllers, endpoint, static serving. | The project already uses Phoenix for route ownership, endpoint boot, and first-run host serving. [VERIFIED: mix.lock] |
| `phoenix_live_view` | `1.1.30` in `examples/phoenix_host/mix.lock` | Root showcase hub and existing route lanes. | LiveView is already used for SaaS, decks, bridge proof, native-pressure, and local-first routes. [VERIFIED: mix.lock] [VERIFIED: codebase grep] |
| `ecto_sql` / `ecto_sqlite3` | `ecto_sql 3.13.5`; `ecto_sqlite3 0.23.0` | Deterministic persisted demo data and reset counts. | The example host uses SQLite through `CrosswakeExample.Repo`, migrations, and `priv/repo/seeds.exs`. [VERIFIED: mix.lock] [VERIFIED: codebase grep] |
| `bandit` | `1.12.0` | Phoenix endpoint HTTP server. | The example endpoint is configured with `Bandit.PhoenixAdapter` and local boot logs report Bandit `1.12.0`. [VERIFIED: mix.lock] [VERIFIED: local command] |
| `jason` | `1.4.5` | JSON responses for `_e2e` and sync/reset endpoints. | Existing sync and E2E controllers return JSON through Phoenix/Jason. [VERIFIED: mix.lock] [VERIFIED: codebase grep] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `@playwright/test` | `1.60.0` in `package-lock.json` | Route-tour and reset endpoint proof. | Use for browser-visible hub smoke and IndexedDB reset proof; keep `workers: 1` because the existing config serializes tests to avoid SQLite locks. [VERIFIED: package-lock.json] [VERIFIED: codebase grep] |
| `typescript` | `5.9.3` in `package-lock.json` | E2E test authoring. | Use only for Playwright support code and route-tour extensions. [VERIFIED: package-lock.json] |
| `Crosswake.Policy.RouterMetadata` | local module | Extract compiled route policy from Phoenix route metadata. | Use in ExUnit tests to verify catalog route IDs, paths, runtime, offline posture, capabilities, and security against compiled truth. [VERIFIED: codebase grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Root `HubLive` | Controller-backed HEEx | Context allows controller-backed HEEx if constraints demand it, but LiveView better matches dynamic reset state and Phoenix route navigation. [VERIFIED: 147-CONTEXT.md] |
| Lane-local fixtures plus orchestrator | Generic fixture engine | A generic fixture engine would blur ownership; the phase context explicitly requires lane-local data ownership with orchestration only in showcase reset. [VERIFIED: 147-CONTEXT.md] |
| Deterministic hand-written records | Faker/random fixture generation | Random records would make screenshots, route tours, digests, and docs unstable; the phase context forbids Faker-style baseline records. [VERIFIED: 147-CONTEXT.md] |
| Router metadata verification | Source string matching | Existing `route_tour.spec.ts` uses string checks, but compiled route metadata is already available and avoids shadow-router drift. [VERIFIED: codebase grep] |

**Installation:**

```bash
# No new external packages are recommended for Phase 147.
cd examples/phoenix_host
mix deps.get
npm ci
```

**Version verification:** Versions above were verified from `examples/phoenix_host/mix.lock`, `examples/phoenix_host/package-lock.json`, and local runtime commands. [VERIFIED: mix.lock] [VERIFIED: package-lock.json] [VERIFIED: local command]

## Package Legitimacy Audit

Phase 147 should not install new external packages; use the dependencies already present in `examples/phoenix_host/mix.exs` and `package-lock.json`. [VERIFIED: codebase grep]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none new | n/a | n/a | n/a | n/a | n/a | No new package installation recommended. [VERIFIED: codebase grep] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: codebase grep]  
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
First-run command/docs
  -> http://localhost:4700/
  -> Phoenix Router root route
  -> Showcase.HubLive
      -> Showcase.Catalog lane cards
          -> compiled route metadata verification in tests
          -> CTA links to existing proof routes and future lane routes
      -> Showcase.Reset status or reset CTA only when gated
          -> Showcase.Reset.reset!()
              -> SaaSPortal.Fixtures deterministic maps
              -> SelectiveNative fixture/context reset for persisted claims
              -> Flashcards fixture/reset for decks/cards/progress
              -> LocalFirst review_events cleanup
          -> structured counts + digest
  -> Playwright route-tour
      -> semantic assertions first
      -> screenshots/collateral after assertions
```

The main data flow is user or test entry at `/`, then Phoenix-owned rendering from a small catalog, then optional reset orchestration through lane-owned data modules, then semantic proof through compiled router metadata and Playwright assertions. [VERIFIED: codebase grep]

### Recommended Project Structure

```text
examples/phoenix_host/lib/crosswake_example/
├── showcase/
│   ├── hub_live.ex          # Root product-shaped hub LiveView.
│   ├── catalog.ex           # Curated lane cards, allowed labels, route IDs, v20 pressure notes.
│   ├── fixtures.ex          # Deterministic static records for foundation-only lanes.
│   └── reset.ex             # Server-side reset orchestrator returning counts/digest.
├── e2e/
│   └── showcase_reset_controller.ex  # Optional test/e2e-gated reset endpoint.
└── router.ex                # Replace get "/" PageController route with live "/" HubLive.

examples/phoenix_host/test/crosswake_example/showcase/
├── catalog_test.exs         # Route IDs/labels match compiled router metadata.
├── reset_test.exs           # Reset is idempotent and returns stable counts/digest.
└── hub_live_test.exs        # Render includes three lanes and visible text labels.
```

This structure keeps Phase 147 work inside the example host and preserves Crosswake core boundaries. [VERIFIED: 147-CONTEXT.md]

### Component Responsibilities

| Component | Responsibility | Notes |
|-----------|----------------|-------|
| `CrosswakeExample.Showcase.HubLive` | Render first-screen three-lane hub with route cards, badges, and CTAs. | Declare root route as `runtime: :live_view`, `offline: :cached_read_only`, `security: :standard`. [VERIFIED: 147-CONTEXT.md] |
| `CrosswakeExample.Showcase.Catalog` | Own product-facing lane metadata, route IDs, allowed support labels, and v20 pressure notes. | Must not duplicate full route-policy DSL. [VERIFIED: 147-CONTEXT.md] |
| `CrosswakeExample.Showcase.Reset` | Orchestrate server-side reset, call lane-owned fixture/context functions, return counts/digest. | Must not reset IndexedDB or claim browser state reset. [VERIFIED: 147-CONTEXT.md] |
| `CrosswakeExample.SaaSPortal.Fixtures` | Continue owning SaaS/admin deterministic maps until Phase 148 expands lane depth. | Existing data has stable IDs and names. [VERIFIED: codebase grep] |
| `CrosswakeExample.SelectiveNative.Fixtures` or future field-service fixture module | Own persisted native-pressure/field-service seed records. | Existing selective-native fixture inserts without clearing, so planner should include a reset-safe fix. [VERIFIED: codebase grep] |
| `CrosswakeExample.Flashcards` / learning fixture module | Own persisted learning/training decks/cards/progress and reuse offline-study boundaries. | Existing seeds already delete cards then decks and insert fixed learning records. [VERIFIED: codebase grep] |
| `bin/see-it-run.sh` and docs | Point newcomers to the showcase first and proof lanes second. | Current text still foregrounds route-owner proof links. [VERIFIED: codebase grep] |

### Pattern 1: Root LiveView Hub With Curated Catalog

**What:** Replace the inline controller-backed `/` page with a LiveView that renders lane cards from a small catalog. [VERIFIED: codebase grep]  
**When to use:** Use when route-card content needs stable server-rendered metadata, reset status, or normal Phoenix navigation. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html]  
**Example:**

```elixir
# Source: Phoenix LiveView Router docs plus Crosswake router DSL in examples/phoenix_host/lib/crosswake_example/router.ex
scope "/" do
  pipe_through([:browser])

  crosswake_defaults runtime: :live_view, offline: :cached_read_only, security: :standard do
    live("/", CrosswakeExample.Showcase.HubLive,
      crosswake: [
        id: "showcase-hub",
        runtime: :live_view,
        offline: :cached_read_only,
        security: :standard
      ]
    )
  end
end
```

### Pattern 2: Reset Orchestrator Delegates To Lane Owners

**What:** `Showcase.Reset.reset!/0` calls lane-specific seed/reset functions and returns a stable `%{counts: ..., digest: ...}` map. [VERIFIED: 147-CONTEXT.md]  
**When to use:** Use for `priv/repo/seeds.exs`, local Mix alias/task, and optional `_e2e` reset endpoint. [VERIFIED: 147-CONTEXT.md]  
**Example:**

```elixir
# Source: Ecto Repo docs for delete_all/2 return values and existing seeds.exs ordering.
def reset! do
  counts = %{
    flashcards: CrosswakeExample.Showcase.Fixtures.reset_flashcards!(),
    field_service: CrosswakeExample.Showcase.Fixtures.reset_field_service!(),
    saas: CrosswakeExample.SaaSPortal.Fixtures.seed() |> count_static_records()
  }

  %{counts: counts, digest: stable_digest(counts)}
end
```

### Pattern 3: Catalog Verification Against Compiled Route Metadata

**What:** Tests should assert each catalog route ID/path exists and matches runtime/offline/security/capability posture from compiled router metadata. [VERIFIED: codebase grep]  
**When to use:** Use for SHOW-03 and to prevent curated copy from becoming a shadow source of truth. [VERIFIED: 147-CONTEXT.md]  
**Example:**

```elixir
# Source: Crosswake.Policy.RouterMetadata and Phoenix.Router route introspection.
routes =
  CrosswakeExample.Router.__routes__()
  |> Map.new(fn route ->
    {:ok, policy} = Crosswake.Policy.RouterMetadata.fetch(route.metadata)
    {policy.id, {route.path, policy}}
  end)

for card <- CrosswakeExample.Showcase.Catalog.cards() do
  assert {path, policy} = routes[card.route_id]
  assert path == card.path
  assert policy.runtime == card.runtime
  assert policy.offline == card.offline
end
```

### Pattern 4: E2E Reset Endpoint Gated Out Of Prod

**What:** Add any reset endpoint only under the existing `/_e2e` namespace and compile it only in `:test`/`:e2e`, or gate explicitly to local/dev-only if planner chooses a dev endpoint. [VERIFIED: codebase grep] [VERIFIED: 147-CONTEXT.md]  
**When to use:** Use only for deterministic tests that need server state reset between tours. [VERIFIED: 147-CONTEXT.md]  
**Example:**

```elixir
# Source: existing router.ex /_e2e namespace pattern at lines 448-454.
if Mix.env() in [:test, :e2e] do
  scope "/_e2e", CrosswakeExample.E2E do
    pipe_through([:api])
    post("/showcase-reset", ShowcaseResetController, :create)
  end
end
```

### Anti-Patterns to Avoid

- **Root route as docs index:** The current `/` is a basic link list, and Phase 147 requires a product-shaped first-screen showcase. [VERIFIED: codebase grep] [VERIFIED: 147-CONTEXT.md]
- **Catalog as route-policy duplicate:** The catalog may own copy and labels, but runtime/offline/capability truth must be verified against route metadata. [VERIFIED: 147-CONTEXT.md]
- **Server reset claiming browser reset:** IndexedDB reset belongs in Playwright helpers, and the server reset must explicitly scope itself to server-side state. [VERIFIED: codebase grep] [VERIFIED: 147-CONTEXT.md]
- **Expanding native controls:** Phase 147 must not implement full native-control breadth or Phase 151 capability-map derivation. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: 147-CONTEXT.md]
- **Screenshots as correctness proof:** Existing route-tour semantics assert route behavior before screenshots, and Phase 147 should preserve that ordering. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Route existence and route posture checks | Regex-only parser over `router.ex` | `Phoenix.Router.__routes__()` plus `Crosswake.Policy.RouterMetadata.fetch/1` | Compiled metadata already contains normalized Crosswake route policy. [VERIFIED: codebase grep] |
| Reset transactions and count reporting | Ad hoc SQL strings | Ecto `Repo.delete_all`, context inserts, and optionally `Ecto.Multi` or `Repo.transact` | Ecto docs define count return values and transaction APIs, and existing seeds already use Ecto context calls. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Browser offline reset | Server endpoint deleting local state | Existing Playwright `resetOfflineStudyDatabase(page)` helper | IndexedDB is browser-owned and reset through `page.addInitScript`. [VERIFIED: codebase grep] |
| Fake business data | Faker/random generator | Stable hand-authored records with fixed IDs, names, and timestamps | Phase context requires repeatable data for screenshots, route tours, docs, and labels. [VERIFIED: 147-CONTEXT.md] |
| Native/support label taxonomy | Broad "supported" badges | Literal labels from context and support matrix such as "available today", "proof-backed example", "demo pressure", "advisory evidence", "future gap" | Support matrix warns that advisory evidence and visual collateral do not widen support truth. [VERIFIED: guides/support_matrix.md] |

**Key insight:** The hard part is not rendering cards; it is keeping cards, reset state, first-run docs, and proof labels aligned with existing route-policy truth without broadening Crosswake's support claims. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Leaving `/` As A Controller Mental Model

**What goes wrong:** The first-run path keeps showing a minimal host page while docs say "showcase." [VERIFIED: codebase grep]  
**Why it happens:** The root page is an inline `PageController` at the top of `router.ex`, not a standalone controller file, so it is easy to miss during planning. [VERIFIED: codebase grep]  
**How to avoid:** Replace the root route in `router.ex` and remove or retire the inline controller module after tests are updated. [VERIFIED: codebase grep]  
**Warning signs:** `/` still has route id `"home"` or the first heading remains "Crosswake Phoenix Host." [VERIFIED: codebase grep]

### Pitfall 2: Reset Endpoint Becomes A Production Mutation Surface

**What goes wrong:** A convenient reset endpoint is compiled into prod or is reachable outside local/test usage. [VERIFIED: 147-CONTEXT.md]  
**Why it happens:** The project already has a `/_e2e` namespace, and adding one more route is simple. [VERIFIED: codebase grep]  
**How to avoid:** Gate reset routes to `Mix.env() in [:test, :e2e]` or add explicit local/dev-only checks; return structured counts/digest only. [VERIFIED: 147-CONTEXT.md]  
**Warning signs:** Reset route appears outside the `if Mix.env() in [:test, :e2e]` block or accepts arbitrary reset scopes. [VERIFIED: codebase grep]

### Pitfall 3: Duplicate Seed Rows

**What goes wrong:** Route-tour or local demos accumulate persisted claims/submissions every reset. [VERIFIED: codebase grep]  
**Why it happens:** `SelectiveNative.Fixtures.seed/0` calls `Claims.create_claim/1` twice without clearing or using stable keys. [VERIFIED: codebase grep]  
**How to avoid:** Add deterministic reset behavior for persisted field-service/native-pressure records, clearing dependent tables before parent tables and returning counts. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]  
**Warning signs:** Calling seed twice changes counts or digest. [VERIFIED: codebase grep]

### Pitfall 4: Blurring Cached Read-Only With Local-First Mutation

**What goes wrong:** Hub labels imply that cached LiveView routes support offline mutation. [VERIFIED: guides/route_policy.md]  
**Why it happens:** Both cached read-only and offline island labels are "offline" adjacent. [VERIFIED: guides/route_policy.md]  
**How to avoid:** Use visible text badges such as "Cached read-only" and "Offline island"; reserve "local-first" only for routes with real outbox/journal behavior. [VERIFIED: 147-CONTEXT.md]  
**Warning signs:** SaaS/admin card claims offline edits, or reset copy says server reset clears the offline outbox. [VERIFIED: 147-CONTEXT.md]

### Pitfall 5: Treating Showcase Collateral As Proof

**What goes wrong:** Screenshots or hub copy become evidence for route-owner semantics. [VERIFIED: 147-CONTEXT.md]  
**Why it happens:** The hub is a more polished product surface than older proof routes. [VERIFIED: .planning/ROADMAP.md]  
**How to avoid:** Keep Playwright route-tour semantics and metadata tests as correctness proof; treat screenshots as collateral after semantic assertions. [VERIFIED: codebase grep]  
**Warning signs:** A test only checks PNG existence or visual text without verifying route policy metadata. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from official sources and local code:

### Route Metadata Test

```elixir
# Source: Crosswake.Policy.RouterMetadata.fetch/1 and Phoenix router route metadata.
def compiled_route_map do
  CrosswakeExample.Router.__routes__()
  |> Enum.reduce(%{}, fn route, acc ->
    case Crosswake.Policy.RouterMetadata.fetch(Map.get(route, :metadata, %{})) do
      {:ok, policy} -> Map.put(acc, policy.id, %{path: route.path, policy: policy})
      :error -> acc
    end
  end)
end
```

### Reset Return Shape

```elixir
# Source: Ecto Repo docs for delete_all/2 count returns; existing seeds.exs uses child-before-parent deletes.
%{
  counts: %{
    flashcard_cards: 9,
    flashcard_decks: 3,
    field_service_jobs: 3,
    saas_records: 6
  },
  digest: "sha256:...",
  browser_state_reset: false
}
```

### First-Run Banner Copy Direction

```text
# Source: bin/see-it-run.sh banner lines 150-181.
Open the showcase:
  http://localhost:4700/

Proof lanes:
  /offline       Offline island proof
  /bridge-proof  Bounded bridge proof
  /native/claims Native-pressure route owner proof
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Minimal example-host link list at `/` | Product-shaped showcase hub at `/` | Phase 147 target | First-run users should see the three domain lanes without reading docs first. [VERIFIED: .planning/ROADMAP.md] |
| Isolated `priv/repo/seeds.exs` plus lane fixtures | Shared reset contract delegated from seeds, Mix task/alias, and optional `_e2e` endpoint | Phase 147 target | Local DX and CI should reset the same server-side state. [VERIFIED: 147-CONTEXT.md] |
| Source-string checks in route tour | Compiled route metadata checks for hub catalog plus semantic Playwright assertions | Phase 147 recommendation | Prevents support-label drift while retaining existing route-tour proof posture. [VERIFIED: codebase grep] |
| Route-owner proof routes as newcomer mental model | Showcase first, proof lanes one click deeper | Phase 147 target | Keeps diagnostics and proof explicit but secondary. [VERIFIED: 147-CONTEXT.md] |

**Deprecated/outdated:**
- The root "Phoenix Host" page is outdated for v19 because Phase 147 requires `/` to become the showcase hub. [VERIFIED: codebase grep] [VERIFIED: .planning/ROADMAP.md]
- The old three-route first-run framing is outdated for v19 because README and guides still foreground `/`, `/offline`, and `/bridge-proof` instead of the three v19 showcase lanes. [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| none | All research claims are verified from local code/planning docs or cited official documentation. | n/a | n/a |

## Open Questions (RESOLVED)

1. **Reset endpoint scope: chosen answer**
   - Use one fixed server-side reset contract for Phase 147 foundation data. `priv/repo/seeds.exs` and a local `mix showcase.reset` entrypoint are the dev/local human reset path, while the browser-callable endpoint is limited to `POST /_e2e/showcase-reset` compiled only under `Mix.env() in [:test, :e2e]`. [VERIFIED: 147-CONTEXT.md] [VERIFIED: 147-PATTERNS.md]
   - Do not add a production reset endpoint, a general browser dev reset route, or any arbitrary reset scope/table parameters. The endpoint returns structured counts and a deterministic digest from the fixed contract only. [VERIFIED: 147-CONTEXT.md]
   - Browser-owned offline state remains out of scope for server reset: the reset result must state `browser_state_reset: false`, and IndexedDB/outbox cleanup stays in Playwright/browser helpers. This is not a true offline or IndexedDB reset claim. [VERIFIED: 147-CONTEXT.md] [VERIFIED: codebase grep]

2. **Field-service fixture strategy: chosen answer**
   - Phase 147 creates only the deterministic field-service fixture skeleton/data foundation needed for the hub card and reset digest. Use stable maps or a thin example-host fixture module, and optionally reuse/reset existing selective-native claim data as native-pressure evidence. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: 147-CONTEXT.md]
   - Do not add full field-service Ecto schemas, complete technician workflows, scanner/capture production APIs, permission flows, or local-first field-service mutation in Phase 147. [VERIFIED: 147-CONTEXT.md] [VERIFIED: .planning/REQUIREMENTS.md]
   - Full field-service lane workflows, deeper job/asset/inspection state, and device-pressure walkthroughs remain Phase 149 scope. [VERIFIED: .planning/ROADMAP.md]

## Existing App Structure And Likely Files

| File | Current Role | Phase 147 Planning Note |
|------|--------------|-------------------------|
| `examples/phoenix_host/lib/crosswake_example/router.ex` | Defines inline `PageController`, root route, route-policy metadata, lane routes, and `/_e2e` namespace. [VERIFIED: codebase grep] | Replace `get "/"` with root hub route, add optional gated reset endpoint, and keep existing proof routes reachable. [VERIFIED: 147-CONTEXT.md] |
| `examples/phoenix_host/lib/crosswake_example/showcase/*` | Does not exist. [VERIFIED: codebase grep] | Create hub/catalog/reset/fixture modules here to keep foundation example-host-local. [VERIFIED: 147-CONTEXT.md] |
| `examples/phoenix_host/priv/repo/seeds.exs` | Deletes Flashcard cards/decks and inserts one fixed deck with three cards. [VERIFIED: codebase grep] | Delegate to `Showcase.Reset.reset!/0` or lane-specific reset helpers. [VERIFIED: 147-CONTEXT.md] |
| `examples/phoenix_host/lib/crosswake_example/saas_portal/fixtures.ex` | Owns deterministic SaaS account, users, and approvals as maps. [VERIFIED: codebase grep] | Keep SaaS ownership lane-local and use it for hub card counts. [VERIFIED: 147-CONTEXT.md] |
| `examples/phoenix_host/lib/crosswake_example/selective_native/fixtures.ex` | Inserts two claims without clearing. [VERIFIED: codebase grep] | Make persisted native-pressure/field-service records reset-safe or wrap with a new deterministic field-service fixture owner. [VERIFIED: codebase grep] |
| `examples/phoenix_host/lib/crosswake_example/flashcards.ex` | Owns decks, cards, and progress context functions. [VERIFIED: codebase grep] | Build learning/training reset on this context and preserve offline-study browser ownership. [VERIFIED: 147-CONTEXT.md] |
| `examples/phoenix_host/e2e/route_tour.spec.ts` | Proves route-owner semantics before screenshots. [VERIFIED: codebase grep] | Add only hub smoke/metadata visibility now; defer one happy path per lane to Phase 151. [VERIFIED: 147-CONTEXT.md] |
| `examples/phoenix_host/e2e/support/offline_route_proof.ts` | Deletes `crosswake_offline_study` IndexedDB before route scripts run. [VERIFIED: codebase grep] | Keep browser reset here, not in server reset. [VERIFIED: 147-CONTEXT.md] |
| `bin/see-it-run.sh` | Boots/reuses backend, opens `/`, and prints proof-oriented banner. [VERIFIED: codebase grep] | Update banner to "open showcase" first and proof lanes second. [VERIFIED: 147-CONTEXT.md] |
| `README.md`, `guides/see_it_run.md`, `examples/QUICK_START.md` | First-run docs still describe three route-owner links. [VERIFIED: codebase grep] | Update first-run copy to showcase hub while retaining proof commands. [VERIFIED: 147-CONTEXT.md] |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir/Mix | Phoenix compile/test and seeds/reset task | yes | Mix `1.19.5`, Erlang/OTP `28` | Docker backend for newcomer first-run. [VERIFIED: local command] |
| Node.js | Playwright tests and package-lock scripts | yes | `v22.14.0` | Docker first-run for non-test browsing. [VERIFIED: local command] |
| npm | Playwright dependency install | yes | `11.1.0` | None for E2E. [VERIFIED: local command] |
| Docker | `bin/see-it-run.sh` zero-toolchain path | yes | `29.5.2` | Native `PORT=4700 mix phx.server`. [VERIFIED: local command] [VERIFIED: codebase grep] |
| Context7 CLI | External docs lookup fallback | no | n/a | Official docs via web search were used. [VERIFIED: local command] |

**Missing dependencies with no fallback:**
- None for planning research. [VERIFIED: local command]

**Missing dependencies with fallback:**
- Context7 CLI is not installed; official HexDocs, Playwright docs, and OWASP docs were used as fallback sources. [VERIFIED: local command] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit through Mix, plus Playwright Test `1.60.0`. [VERIFIED: mix.exs] [VERIFIED: package-lock.json] |
| Config file | `examples/phoenix_host/playwright.config.ts`; ExUnit uses `examples/phoenix_host/test/test_helper.exs`. [VERIFIED: codebase grep] |
| Quick run command | `cd examples/phoenix_host && mix test test/crosswake_example/showcase` after Wave 0 creates showcase tests. [VERIFIED: codebase grep] |
| Full suite command | `cd examples/phoenix_host && mix test && npx playwright test e2e/route_tour.spec.ts` after `npm ci`. [VERIFIED: codebase grep] |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| ARC-01 | Planning docs preserve v19 showcase to v20 controls to later follow-ons. | docs/structural | `rg "showcase first|controls next|Native Controls Pack 1" .planning/PROJECT.md .planning/MILESTONE-ARC.md .planning/STATE.md` | Existing docs yes; dedicated test no, Wave 0 optional. [VERIFIED: codebase grep] |
| ARC-02 | SEED-002 is strategic input, not v19 implementation breadth. | docs/structural | `rg "SEED-002" .planning/STATE.md .planning/PROJECT.md .planning/REQUIREMENTS.md` | Existing docs yes; dedicated test no, Wave 0 optional. [VERIFIED: codebase grep] |
| ARC-03 | SEED-003/004 remain release-infrastructure carryovers. | docs/structural | `rg "SEED-003|SEED-004|MIRROR_PUSH_TOKEN|clean-room" .planning/STATE.md .planning/PROJECT.md` | Existing docs yes; dedicated test no, Wave 0 optional. [VERIFIED: codebase grep] |
| SHOW-01 | `/` renders three lane cards on first screen. | LiveView render + Playwright smoke | `cd examples/phoenix_host && mix test test/crosswake_example/showcase/hub_live_test.exs` | No, Wave 0 gap. [VERIFIED: codebase grep] |
| SHOW-02 | Server reset is idempotent and returns stable counts/digest. | ExUnit integration | `cd examples/phoenix_host && mix test test/crosswake_example/showcase/reset_test.exs` | No, Wave 0 gap. [VERIFIED: codebase grep] |
| SHOW-03 | Hub labels match compiled route policy and use allowed visible labels. | ExUnit structural | `cd examples/phoenix_host && mix test test/crosswake_example/showcase/catalog_test.exs` | No, Wave 0 gap. [VERIFIED: codebase grep] |
| SHOW-04 | First-run banner/docs point to showcase first and proof lanes second. | docs/shell text test or rg check | `rg "showcase" bin/see-it-run.sh README.md guides/see_it_run.md examples/QUICK_START.md` | Existing files yes; dedicated test no, Wave 0 optional. [VERIFIED: codebase grep] |

### Sampling Rate

- **Per task commit:** `cd examples/phoenix_host && mix test test/crosswake_example/showcase` once showcase tests exist. [VERIFIED: codebase grep]
- **Per wave merge:** `cd examples/phoenix_host && mix test && npx playwright test e2e/route_tour.spec.ts` after `npm ci`. [VERIFIED: codebase grep]
- **Phase gate:** Full example-host ExUnit suite plus targeted route-tour/hub Playwright proof should be green before `$gsd-verify-work`. [VERIFIED: codebase grep]

### Wave 0 Gaps

- [ ] `examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs` covers SHOW-03 and route metadata label drift. [VERIFIED: codebase grep]
- [ ] `examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs` covers SHOW-02 and duplicate/digest proof. [VERIFIED: codebase grep]
- [ ] `examples/phoenix_host/test/crosswake_example/showcase/hub_live_test.exs` covers SHOW-01. [VERIFIED: codebase grep]
- [ ] Optional docs/banner text guard for SHOW-04 if planner wants automated doc checks this phase. [VERIFIED: codebase grep]

## Security Domain

Security enforcement is enabled because `.planning/config.json` does not set `security_enforcement` to `false`. [VERIFIED: .planning/config.json]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | partially | SaaS/admin existing routes use LiveView `on_mount` authentication, but the public hub itself should not add auth. [VERIFIED: codebase grep] |
| V3 Session Management | partially | Existing browser pipeline fetches session, and LiveView auth-sensitive routes keep session checks in lane-specific mounts. [VERIFIED: codebase grep] |
| V4 Access Control | yes | Reset endpoint must be gated to `:test`/`:e2e` or explicitly local/dev-only, and sensitive SaaS/admin routes must keep existing auth posture. [VERIFIED: 147-CONTEXT.md] |
| V5 Input Validation | yes | Any reset endpoint should accept no arbitrary table names or scopes; use a fixed server contract and return counts/digest. [VERIFIED: 147-CONTEXT.md] |
| V6 Cryptography | no new crypto | Phase 147 does not add cryptographic functions; use existing hashing only for deterministic digest if needed, not security authority. [VERIFIED: 147-CONTEXT.md] |

OWASP ASVS is a web application security verification standard and the current stable release is 5.0.0 dated May 2025. [CITED: https://owasp.org/www-project-application-security-verification-standard/] [CITED: https://github.com/OWASP/ASVS]

### Known Threat Patterns for Phoenix Showcase/Reset

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Public reset endpoint mutates server data | Elevation of Privilege / Tampering | Compile under `Mix.env() in [:test, :e2e]` or guard to local/dev-only; do not expose in prod. [VERIFIED: 147-CONTEXT.md] |
| Catalog claims unsupported native capability as shipped | Spoofing / Information Disclosure | Use allowed support labels and verify route IDs/runtime/offline/capabilities against compiled metadata. [VERIFIED: 147-CONTEXT.md] |
| SQL injection or arbitrary table reset through params | Tampering | Do not accept table names; use fixed Ecto context functions and deterministic reset steps. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] |
| XSS in hub labels or route copy | Tampering | Store labels as static server-side data rendered by HEEx escaping; avoid raw HTML in catalog fields. [VERIFIED: codebase grep] |
| Browser offline state falsely reset by server | Repudiation / Tampering | Keep IndexedDB reset in Playwright/browser helpers and report `browser_state_reset: false` from server reset. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/147-arc-fixture-and-showcase-foundation/147-CONTEXT.md` - locked phase decisions, deferred scope, code context, and canonical refs. [VERIFIED: codebase grep]
- `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/MILESTONE-ARC.md` - v19/v20 arc, requirements, phase success criteria, seed classification, and scope fences. [VERIFIED: codebase grep]
- `examples/phoenix_host/lib/crosswake_example/router.ex` - current root route, Crosswake metadata, lane routes, and `_e2e` namespace. [VERIFIED: codebase grep]
- `examples/phoenix_host/priv/repo/seeds.exs`, `saas_portal/fixtures.ex`, `selective_native/fixtures.ex`, `flashcards.ex`, `priv/static/offline_study.js` - fixture/reset ownership and browser/server data boundaries. [VERIFIED: codebase grep]
- `examples/phoenix_host/e2e/route_tour.spec.ts`, `e2e/support/offline_route_proof.ts`, `playwright.config.ts` - semantic proof-first route tour, IndexedDB reset helper, and serial Playwright setup. [VERIFIED: codebase grep]
- `brandbook/BRAND-SPEC.md`, `priv/static/crosswake/tokens.css`, `examples/phoenix_host/priv/static/css/tokens.css`, `examples/phoenix_host/priv/static/css/app.css` - current brand, token, and shared CSS surface. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- Phoenix LiveView Router docs - `live/4`, `live_session/3`, direct router-declared LiveView route guidance. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html]
- Phoenix Router docs - router role, route metadata, verified routes, and introspection guidance. [CITED: https://hexdocs.pm/phoenix/Phoenix.Router.html]
- Ecto Repo docs - `delete_all`, `insert`, `insert_all`, transactions, and count returns. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]
- Ecto Multi docs - ordered transactional grouping and introspection. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]
- Playwright Test configuration and webServer docs - `baseURL`, `workers`, `webServer`, and config placement. [CITED: https://playwright.dev/docs/test-configuration] [CITED: https://playwright.dev/docs/test-webserver]
- OWASP ASVS project and repository - ASVS purpose and latest stable version. [CITED: https://owasp.org/www-project-application-security-verification-standard/] [CITED: https://github.com/OWASP/ASVS]

### Tertiary (LOW confidence)

- None used for recommendations. [VERIFIED: local research log]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions are from lockfiles and local commands, and no new package installation is recommended. [VERIFIED: mix.lock] [VERIFIED: package-lock.json] [VERIFIED: local command]
- Architecture: HIGH - route, fixture, reset, docs, and proof touchpoints are verified from existing project files and locked phase context. [VERIFIED: codebase grep] [VERIFIED: 147-CONTEXT.md]
- Pitfalls: HIGH - each listed pitfall maps to an observed current file shape or an explicit phase decision. [VERIFIED: codebase grep] [VERIFIED: 147-CONTEXT.md]

**Research date:** 2026-07-09  
**Valid until:** 2026-08-08 for local codebase structure; 2026-07-16 for external docs/version-sensitive references.
