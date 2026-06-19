# Phase 118: Runnable Quick Start And Real Adoption Proof - Research

**Researched:** 2026-06-19  
**Domain:** Phoenix example quick start, app-owned offline island adoption guide, ExUnit docs-contract drift guard  
**Confidence:** HIGH for repo-truth recommendations; MEDIUM for official-doc cross-checks because Context7 was unavailable and official docs were reached through web search.

## User Constraints (from CONTEXT.md)

All constraints in this section are copied from `.planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md`. [VERIFIED: .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md]

### Locked Decisions

#### Quick Start Command Path

- **D-01:** Add Phoenix-style `setup`, `ecto.setup`, and `ecto.reset` aliases to `examples/phoenix_host/mix.exs` before documenting `mix setup` as the clean-checkout path. The alias should be small and transparent: fetch deps, create/migrate/seed the SQLite database, and provide a repeatable reset. Do not hide proof commands behind a single opaque script as the primary quick-start path.
- **D-02:** Rewrite `examples/QUICK_START.md` as "walkthrough first, proof second." The walkthrough should get the Phoenix host running at `http://localhost:4002`, show the reader the relevant routes, and state expected output. The proof section should then run deterministic commands that prove the architecture.
- **D-03:** Keep Node/Playwright setup explicit in the proof section. Recommended shape from `examples/phoenix_host`: `npm ci`, `npx playwright install chromium`, then `npx playwright test e2e/offline_sync.spec.ts`.
- **D-04:** The quick start must warn users to stop the dev server before running the Playwright offline proof. `examples/phoenix_host/playwright.config.ts` starts its own `MIX_ENV=test` Phoenix server on port `4002` and exposes the gated `/_e2e` route; reusing a dev server would be misleading and can cause port conflicts.
- **D-05:** Document exact current paths: Phoenix host `examples/phoenix_host`, iOS project `examples/ios_shell_host/CrosswakeShell.xcodeproj`, Android project `examples/android_shell_host`, offline route `/offline`, bridge route `/bridge-proof`, and sync endpoint `/study/sync`.
- **D-06:** Native iOS/Android run instructions may remain in the quick start only under explicit advisory/local-development wording. Phase 118 must not describe the checked-in native hosts as published-coordinate proof because iOS currently uses `XCLocalSwiftPackageReference` and Android still references `dev.crosswake:shell-core-android:0.1.0`.

#### Proof Coverage

- **D-07:** Use a tiered proof ladder instead of smoke-only, CI-only, or native-first quick start. The recommended order is:
  1. Phoenix smoke: `mix setup`, `PORT=4002 mix phx.server`, then inspect `/`, `/offline`, and `/bridge-proof`.
  2. Required correctness proof: Playwright offline E2E for IndexedDB queue, reconnect-triggered app flush, Ecto row assertion, idempotent duplicate, and accepted outbox deletion.
  3. Bounded bridge proof: `bash script/verify_bounded_bridge_proof.sh` from the repo root. This is backend/docs proof; native share-sheet UI remains advisory.
  4. Native-owned/route-unavailable contract proof: `CROSSWAKE_PHASE5_NATIVE_PROOFS=0 bash script/verify_phase5_example_hosts.sh` from the repo root. This proves manifest/example-host contract truth without claiming simulator/device support.
  5. Optional native UI steps: Xcode/Android Studio walkthroughs labeled advisory until Phase 119.
- **D-08:** Make Playwright offline proof the first required correctness proof after the Phoenix smoke. The current E2E asserts the actual app-owned mutation path: UI click -> IndexedDB mutation -> explicit reconnect event -> `/study/sync` -> Ecto state -> outbox deletion.
- **D-09:** Do not make native simulator/emulator/device evidence merge-blocking or first-run required in Phase 118. Phase 119 owns native evidence labels; Phase 120 owns collateral capture.
- **D-10:** Do not replace the tiered ladder with a smoke-only guide. A smoke-only guide would let readers see pages but would not prove v12's real IndexedDB outbox/reconnect/Ecto loop.

#### Adoption Guide Story

- **D-11:** Rewrite `guides/adoption.md` as both a real proof walkthrough and a reusable recipe. It should first teach the shipped flashcard flow, then extract the route-local offline-island pattern an adopter can copy conceptually.
- **D-12:** The guide must teach the v12 truth explicitly: app-owned island JavaScript stores semantic review events in IndexedDB; `window` `online` triggers `flushOutbox`; the client posts batched events to `/study/sync`; Phoenix routes that through an API controller; Ecto changesets validate payloads; `insert_all` with `on_conflict: :nothing` and `client_mutation_id` makes duplicate replay idempotent; accepted records are deleted from the local outbox; rejected records stay visible for user/operator handling.
- **D-13:** Use current implementation names where they matter: `examples/phoenix_host/priv/static/offline_study.js`, `CrosswakeExample.LocalFirst.SyncController`, `CrosswakeExample.LocalFirst.Study.sync_events/1`, and `CrosswakeExample.LocalFirst.ReviewEvent`.
- **D-14:** Be precise about outcome vocabulary. The current demo proves accepted records, rejected validation records, idempotent duplicate replay, and outbox deletion. "Conflict" is canonical Crosswake replay vocabulary and should be explained as an expected offline outcome class, but do not imply the current `/study/sync` endpoint ships a full conflict-resolution UI.
- **D-15:** Remove and forbid bridge-owned offline mutation language. `Crosswake.mutate`, "Sync Engine (Bridge)", generic bridge mutation queues, app-wide local-first claims, and broad background sync claims are stale or wrong for current Crosswake. The bridge is not the offline mutation authority.
- **D-16:** Frame the reusable recipe from the consumer's perspective: declare the route owner, build the island, persist small semantic events, flush on reconnect or explicit sync, reconcile on the Phoenix/Ecto side, and test the whole loop. Do not write the guide from the provider's internal architecture perspective.
- **D-17:** Use a skeptical Phoenix SaaS maintainer as the primary reader. They want to know who owns the route, where data enters, where it is stored, what command proves it, what happens on reconnect, and what they get back when replay succeeds or fails.

#### DRIFT-02 Guard

- **D-18:** Add an idiomatic ExUnit docs-contract scanner as the DRIFT-02 guard, likely `test/crosswake/guides/quick_start_adoption_drift_test.exs`. Keep it in the normal `mix test` surface rather than adding a standalone Node/Bash scanner as the primary guard.
- **D-19:** Derive facts from repo sources instead of duplicating literals where practical: current Crosswake version from `Application.spec(:crosswake, :vsn)`, Phoenix host port from `examples/phoenix_host/config/config.exs` and `examples/phoenix_host/playwright.config.ts`, setup alias truth from `examples/phoenix_host/mix.exs`, and path truth from actual files/directories.
- **D-20:** Make the guard strict on structural proof truth and loose on prose. It should fail on wrong port/path claims, missing setup/proof commands, missing advisory native labels, forbidden offline-authority language, missing `IndexedDB`/`flushOutbox`/`/study/sync`/Ecto idempotency/outbox-deletion teaching, and missing accepted/rejected/conflict semantics. It should not fail because a paragraph was reworded.
- **D-21:** Include synthetic regression tests for the scanner itself. At minimum: wrong port, missing setup alias command, missing existing path, `Crosswake.mutate`, "Sync Engine (Bridge)", bridge-owned mutation queue language, and missing advisory native labels.
- **D-22:** Do not use executable markdown or a command-runner harness as DRIFT-02's default. That belongs to proof/UAT lanes because it is slower, more brittle, and more likely to collide with server ports or native tooling.
- **D-23:** Keep clear failure messages with file, line, category, and actionable detail, following the Phase 116 `release_boundaries_test.exs` style.

#### UX, Voice, And Documentation Shape

- **D-24:** Quick-start and adoption microcopy should follow the current brand spec: precise, short, example-heavy, and candid. Prefer "Queued locally", "Synced N - queued M", "advisory native evidence", and "app-owned outbox" over hype or vague support claims.
- **D-25:** Use headings that match user jobs: First run, See the route owners, Prove offline replay, Prove bounded bridge, Native steps are advisory, Troubleshooting quick checks, and What this does not prove. Exact heading names can vary, but the reading order should stay first-run -> proof -> caveats.
- **D-26:** Keep UI/visual work out of Phase 118 unless implementation discovers a small copy/status mismatch directly blocking the guide. Broader screenshots, recordings, visual collateral, artifact manifests, and troubleshooting UX remain Phase 120.
- **D-27:** Preserve Crosswake's route-owner thesis in every public claim. The quick start should never sound like a generic WebView wrapper, React Native clone, LiveView-to-native renderer, plugin platform, or "everything works offline" promise.

### the agent's Discretion

The user selected all gray areas and asked for a one-shot, research-backed recommendation set. Downstream agents may choose exact test helper names, heading text, and assertion implementation details as long as they preserve the locked decisions above. The recommended file for the new guard is `test/crosswake/guides/quick_start_adoption_drift_test.exs`, but planners may split helpers if that keeps the test readable.

### Deferred Ideas (OUT OF SCOPE)

- Checked-in iOS/Android host evidence classification remains Phase 119.
- Native docs/support matrix/native shell guide reconciliation to the chosen evidence class remains Phase 119.
- Native coordinate drift guard for stale `dev.crosswake:shell-core-android:0.1.0` and unlabeled `XCLocalSwiftPackageReference` remains Phase 119.
- Browser/native screenshots, recordings, artifact manifests, advisory native capture, and visual collateral remain Phase 120.
- Full troubleshooting and rough-edge examples for doctor findings, denials, route-unavailable states, offline outcomes, and native evidence caveats remain Phase 120.
- A standalone `script/verify_quick_start.sh` may be useful later, but it should not replace visible Mix/Playwright commands as Phase 118's primary quick-start path.
- Executable markdown command-running belongs in later proof/UAT work, not DRIFT-02's cheap docs-contract guard.
- Full conflict-resolution UI or a richer sync engine is out of Phase 118. Adoption docs can explain conflict as a canonical outcome class, but should not imply the current demo endpoint handles every conflict workflow.

## Project Constraints (from AGENTS.md)

- Preserve Crosswake as a Phoenix-first route-policy and runtime-contract system, not a universal UI framework. [VERIFIED: AGENTS.md]
- Keep runtime ownership explicit per route; do not collapse designs into generic WebView wrapper behavior or LiveView-driven native rendering. [VERIFIED: AGENTS.md]
- Treat bridge contracts as semantic, typed, versioned, and low-frequency; flows needing continuous client authority should move toward an offline island or native screen. [VERIFIED: AGENTS.md]
- Keep offline claims honest by distinguishing cached read-only behavior from true local-first mutation with journals, outboxes, and reconciliation. [VERIFIED: AGENTS.md]
- Treat diagnostics, support matrices, proof lanes, and rough-edge documentation as product surface. [VERIFIED: AGENTS.md]
- Respect v1 scope boundaries before adding integrations or wider native breadth. [VERIFIED: AGENTS.md]

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| QUICK-01 | `examples/QUICK_START.md` is runnable from a clean checkout and names exact setup/server/native commands, paths, expected output, proof commands, and advisory native steps. | Add small Phoenix aliases first, document port `4002`, exact routes, proof commands, and advisory native caveats. [VERIFIED: .planning/REQUIREMENTS.md; examples/phoenix_host/mix.exs; examples/phoenix_host/config/config.exs; examples/phoenix_host/playwright.config.ts] |
| ADOPT-01 | `guides/adoption.md` teaches v12 app-owned IndexedDB outbox/reconnect/Ecto truth and removes bridge-owned offline mutation language. | Current implementation proves app-owned `offline_study.js` -> `/study/sync` -> Ecto validation/idempotency -> accepted deletion, so the guide should teach that path directly. [VERIFIED: guides/adoption.md; examples/phoenix_host/priv/static/offline_study.js; examples/phoenix_host/lib/crosswake_example/local_first/study.ex] |
| DRIFT-02 | Quick-start and adoption guide drift is mechanically guarded. | Existing guide tests use ExUnit docs-contract scanning with repo-derived facts, synthetic stale cases, and location-rich failures; copy that shape for quick start/adoption truth. [VERIFIED: test/crosswake/guides/release_boundaries_test.exs; test/crosswake/guides/route_policy_test.exs] |

## Executive Summary

Phase 118 should not add new runtime capability. It should make the current v11/v12 substrate legible and runnable: a clean Phoenix host setup, a browser-visible route-owner walkthrough, a required Playwright proof of the real app-owned offline loop, a deterministic bounded-bridge proof, and native instructions labeled advisory/local-development until Phase 119 settles native evidence classification. [VERIFIED: .planning/ROADMAP.md; .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md]

The current repo already has the important proof implementation: `/offline` is a socketless controller-rendered island, `offline_study.js` queues app-generated review mutations in IndexedDB, `window` `online` triggers `flushOutbox`, the client posts to `/study/sync`, and `Study.sync_events/1` validates and idempotently inserts rows with `on_conflict: :nothing`. The docs lag behind that proof and still read like temporary safety notes. [VERIFIED: examples/phoenix_host/lib/crosswake_example_web/controllers/offline_controller.ex; examples/phoenix_host/priv/static/offline_study.js; examples/phoenix_host/lib/crosswake_example/local_first/study.ex; examples/QUICK_START.md; guides/adoption.md]

The primary recommendation is: implement the three planned plans as docs-contract work around existing proof, not as new architecture: add aliases, rewrite quick start, rewrite adoption, then add `test/crosswake/guides/quick_start_adoption_drift_test.exs` with source-derived facts and synthetic regression cases. [VERIFIED: .planning/ROADMAP.md; test/crosswake/guides/release_boundaries_test.exs]

## Current Repo Truth

| Fact | Evidence | Planning Implication |
|------|----------|----------------------|
| The example host currently exposes only a `test` alias; it does not expose `setup`, `ecto.setup`, or `ecto.reset`. | `aliases()` contains only `test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]`. [VERIFIED: examples/phoenix_host/mix.exs:26] | Plan 118-01 must add aliases before the quick start can honestly say `mix setup`. |
| The default Phoenix host HTTP port is `4002`. | Endpoint config uses `System.get_env("PORT") || "4002"`. [VERIFIED: examples/phoenix_host/config/config.exs:8] | Quick start and drift guard should reject `4000` as current proof truth. |
| Playwright uses `http://localhost:4002`, starts `MIX_ENV=test mix do ecto.drop + ecto.create + ecto.migrate + phx.server`, blocks service workers, and uses one worker. | Config lines show `baseURL`, `webServer.command`, `port: 4002`, `serviceWorkers: 'block'`, and `workers: 1`. [VERIFIED: examples/phoenix_host/playwright.config.ts:3] | Quick start must tell users to stop the dev server before running the E2E proof because the proof starts its own test server. |
| The offline E2E drives the real UI path, not a scratch global. | The spec clicks `#btn-flip` and `#btn-good`, reads IndexedDB observation-only, dispatches `window` `online`, waits for `/study/sync`, checks Ecto state, checks empty outbox, and posts a duplicate for idempotency. [VERIFIED: examples/phoenix_host/e2e/offline_sync.spec.ts:12] | The quick start's first required correctness proof should be `npx playwright test e2e/offline_sync.spec.ts`. |
| The offline island has separate IndexedDB stores for cards and mutations. | `STORE_CARDS = 'flashcards'`, `STORE_MUTATIONS = 'mutations'`, and `initDB()` creates both stores. [VERIFIED: examples/phoenix_host/priv/static/offline_study.js:3] | Adoption guide should teach an app-owned outbox, not bridge-owned mutation authority. |
| The app queues semantic review events with app-generated `client_mutation_id`, `card_id`, and `rating`. | `handleReview/1` builds the mutation with `crypto.randomUUID()`, parsed card id, and rating before calling `queueMutation`. [VERIFIED: examples/phoenix_host/priv/static/offline_study.js:290] | Adoption guide should name semantic event fields rather than generic sync engine payloads. |
| `flushOutbox` posts batched records to `/study/sync` and deletes only accepted records from IndexedDB. | `flushOutbox` posts `events`, reads `accepted_records` and `rejected`, calls `deleteAcceptedMutations`, and updates `Synced N · queued M`. [VERIFIED: examples/phoenix_host/priv/static/offline_study.js:174; examples/phoenix_host/priv/static/offline_study.js:208] | The guide should state accepted records leave the outbox; rejected records remain visible/queued for handling. |
| The reconnect trigger is the browser `online` event plus an eager flush when already online. | `setupEventListeners()` registers `window.addEventListener('online', flushOutbox)` and `handleReview` calls `flushOutbox()` when `navigator.onLine`. [VERIFIED: examples/phoenix_host/priv/static/offline_study.js:265; examples/phoenix_host/priv/static/offline_study.js:307] | The guide must not claim broad background sync; it should say reconnect/foreground route activity triggers this demo path. |
| `/study/sync` is an API route owned by `CrosswakeExample.LocalFirst.SyncController`. | Router maps `post("/sync", SyncController, :sync)` in the `/study` API scope. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex:63] | Adoption guide should trace Browser -> API controller -> context -> schema. |
| `Study.sync_events/1` validates with `ReviewEvent.changeset/2` and persists valid rows through `Ecto.Multi.insert_all` using `on_conflict: :nothing`, `conflict_target: :client_mutation_id`, and `returning: true`. | Context code and schema changeset show validation and idempotent insert details. [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/study.ex:9; examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex:15] | Adoption guide can claim accepted, rejected, duplicate-idempotent, and outbox-deletion semantics; conflict should be explained as canonical vocabulary, not as a full UI shipped here. |
| The checked-in iOS host currently uses a local Swift package reference. | Project file uses `isa = XCLocalSwiftPackageReference` and `relativePath = "../../packages/crosswake-shell-core-ios"`. [VERIFIED: examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj:53] | Quick start native iOS steps must be advisory/local-development, not published-coordinate proof. |
| The checked-in Android host currently uses stale local-era coordinate `dev.crosswake:shell-core-android:0.1.0`. | Gradle dependency line uses that coordinate. [VERIFIED: examples/android_shell_host/app/build.gradle:62] | Quick start native Android steps must be advisory/local-development, not published-coordinate proof. |
| The generator templates support non-local published coordinates for future/adopter scaffolds. | iOS template has remote `https://github.com/szTheory/crosswake-shell-core-ios.git`; Android template has `io.github.sztheory:crosswake-shell-core-android:<%= @version %>`. [VERIFIED: priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex:53; priv/templates/crosswake/shell/android/app/build.gradle.eex:50] | Phase 118 may mention generated public-coordinate proof as release truth, but checked-in hosts stay advisory until Phase 119. |
| Current quick start is a temporary Phase 116 note with manual setup commands and no required offline E2E proof ladder. | Quick start says Phase 118 owns the full rewrite and currently documents `mix deps.get`, `mix ecto.create`, `mix ecto.migrate`, `mix phx.server`. [VERIFIED: examples/QUICK_START.md:1] | Replace it completely; do not patch around the temporary structure. |
| Current adoption guide is a temporary stub that names v12 truth but does not yet teach the flow deeply. | Adoption guide says the full adoption rewrite is owned by Phase 118. [VERIFIED: guides/adoption.md:25] | Replace it with proof walkthrough first, reusable recipe second. |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Elixir / Mix | Elixir 1.19.5, Mix 1.19.5 in local environment | Runs root tests and the Phoenix host. | Current repo declares Elixir `~> 1.19`; local toolchain matches the declared baseline. [VERIFIED: local command `elixir --version`; mix.exs:7] |
| Phoenix | Locked 1.8.7; Hex latest observed 1.8.8 | Example host routing, controller, endpoint, and server. | Existing repo is Phoenix-first and already locked; no dependency churn is needed for docs/alias work. [VERIFIED: examples/phoenix_host/mix.lock; mix hex.info phoenix] |
| Phoenix LiveView | Locked 1.1.30 | Existing browser routes and bridge proof route. | Crosswake's route-owner docs preserve LiveView as the default owner for server-centric routes. [VERIFIED: examples/phoenix_host/mix.lock; guides/route_policy.md] |
| Ecto / Ecto SQL / Ecto SQLite3 | Ecto 3.13.6, Ecto SQL 3.13.5, Ecto SQLite3 0.23.0 locked in example host | SQLite persistence, migrations, changesets, and idempotent sync insertion. | Existing host uses SQLite proof state; official Ecto docs support changesets, migrations, transactions, and `insert_all` upserts. [VERIFIED: examples/phoenix_host/mix.lock; CITED: https://ecto.hexdocs.pm/Ecto.Repo.html; CITED: https://ecto.hexdocs.pm/constraints-and-upserts.html] |
| Playwright Test | 1.60.0 installed from lockfile; package.json range `^1.40.0` | Required offline replay correctness proof. | Existing spec already validates the real IndexedDB/reconnect/Ecto path, and Playwright officially supports local web servers and offline network emulation. [VERIFIED: examples/phoenix_host/package-lock.json; CITED: https://playwright.dev/docs/test-webserver; CITED: https://playwright.dev/docs/api/class-browsercontext] |
| IndexedDB Web API | Browser API | App-owned outbox and flashcard card store. | IndexedDB is official browser storage for significant structured client data with transactions and same-origin scope. [VERIFIED: examples/phoenix_host/priv/static/offline_study.js; CITED: https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API] |

### Supporting

| Tool | Version / Status | Purpose | When to Use |
|------|------------------|---------|-------------|
| Node / npm | Node v22.14.0, npm 11.1.0 locally | Runs `npm ci`, Playwright CLI, and TypeScript-based E2E honesty guard. | Required for Playwright proof and `node script/check-e2e-honesty.mjs`. [VERIFIED: local command `node --version`; local command `npm --version`] |
| TypeScript | 5.9.3 installed from lockfile | Enables `script/check-e2e-honesty.mjs` to parse the E2E spec through the TypeScript compiler API. | Use existing lockfile dependency; do not upgrade in Phase 118. [VERIFIED: examples/phoenix_host/package-lock.json; script/check-e2e-honesty.mjs] |
| Xcode / xcodebuild | Xcode 26.5 locally | Advisory iOS local-development walkthrough. | Optional only; do not make native simulator evidence required in Phase 118. [VERIFIED: local command `xcodebuild -version`; .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md] |
| Android Gradle wrapper | Present under `examples/android_shell_host`; Java runtime missing locally | Advisory Android local-development walkthrough. | Optional only; local Java absence reinforces that Android UI steps must remain advisory here. [VERIFIED: examples/android_shell_host/gradlew; local command `java -version`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| ExUnit docs-contract scanner | Shell/Node scanner | ExUnit matches existing guide guard style, can derive `Application.spec(:crosswake, :vsn)`, and stays in normal `mix test`; Node/Bash adds another proof surface without need. [VERIFIED: test/crosswake/guides/release_boundaries_test.exs; .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md] |
| Tiered proof ladder | Smoke-only quick start | Smoke-only shows pages but does not prove the v12 offline path; the locked phase decision rejects it. [VERIFIED: .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md] |
| Bridge-owned offline mutation examples | App-owned offline island recipe | Bridge mutation authority contradicts current implementation and project thesis; the app-owned island is the proven path. [VERIFIED: examples/phoenix_host/priv/static/offline_study.js; guides/bridge.md; guides/offline.md] |

**Installation / setup:** Use existing dependencies only; do not add packages in Phase 118. [VERIFIED: examples/phoenix_host/package.json; examples/phoenix_host/package-lock.json]

```bash
cd examples/phoenix_host
mix deps.get
npm ci
npx playwright install chromium
```

## Package Legitimacy Audit

Phase 118 should not add new packages; it should use the existing `examples/phoenix_host/package-lock.json`. The audit below covers existing Node proof dependencies because the quick start will ask adopters to run `npm ci`. [VERIFIED: examples/phoenix_host/package-lock.json]

| Package | Registry | Age / Currency | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|----------------|-----------|-------------|---------|-------------|
| `@playwright/test` | npm | Latest `1.61.0` modified 2026-06-19; lockfile has `1.60.0`. [VERIFIED: npm registry; examples/phoenix_host/package-lock.json] | 42,613,659/wk. [VERIFIED: package-legitimacy seam] | `github.com/microsoft/playwright`. [VERIFIED: npm registry] | SUS from seam for latest package freshness (`too-new`). [VERIFIED: package-legitimacy seam] | Approved only as existing lockfile install; planner must not upgrade without a human/checkpoint. |
| `typescript` | npm | Latest `6.0.3` modified 2026-06-18; lockfile has `5.9.3`. [VERIFIED: npm registry; examples/phoenix_host/package-lock.json] | 219,577,663/wk. [VERIFIED: package-legitimacy seam] | `github.com/microsoft/TypeScript`. [VERIFIED: npm registry] | OK. [VERIFIED: package-legitimacy seam] | Approved as existing lockfile install. |

**Packages removed due to SLOP verdict:** none. [VERIFIED: package-legitimacy seam]  
**Packages flagged as suspicious SUS:** `@playwright/test` latest only; use locked `1.60.0` and do not upgrade in Phase 118. [VERIFIED: package-legitimacy seam; examples/phoenix_host/package-lock.json]

## Architecture Patterns

### Pattern 1: Walkthrough First, Proof Second

**What:** The quick start should first get the Phoenix host running at `http://localhost:4002`, point the reader to `/`, `/offline`, and `/bridge-proof`, then run the proof ladder. [VERIFIED: .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md; examples/phoenix_host/config/config.exs]

**When to use:** Use for adopter-facing first-run docs because the reader needs to see the route-owner architecture before interpreting proof commands. [VERIFIED: .planning/REQUIREMENTS.md; brandbook/BRAND-SPEC.md]

**Example command shape:**

```bash
cd examples/phoenix_host
mix setup
PORT=4002 mix phx.server
```

### Pattern 2: App-Owned Offline Island Recipe

**What:** The offline route owns client-side IndexedDB state and semantic event replay; Phoenix/Ecto owns validation and canonical persistence. [VERIFIED: examples/phoenix_host/priv/static/offline_study.js; examples/phoenix_host/lib/crosswake_example/local_first/study.ex]

**When to use:** Use for `:offline_island` routes that need true local mutation, not cached read-only routes or bridge affordances. [VERIFIED: guides/route_policy.md; guides/offline.md]

**Implementation trace:**

```text
User click on /offline
  -> offline_study.js handleReview()
  -> IndexedDB mutations store
  -> window online event or navigator.onLine flush
  -> POST /study/sync
  -> SyncController.sync/2
  -> Study.sync_events/1
  -> ReviewEvent.changeset/2
  -> Ecto.Multi.insert_all(... on_conflict: :nothing ...)
  -> accepted_records deleted from local outbox
```

All nodes in this trace are current repo code. [VERIFIED: examples/phoenix_host/e2e/offline_sync.spec.ts; examples/phoenix_host/priv/static/offline_study.js; examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex; examples/phoenix_host/lib/crosswake_example/local_first/study.ex]

### Pattern 3: Source-Derived Docs Contract

**What:** The DRIFT-02 guard should derive facts from repo sources and scan docs for structural truth, not compare full prose snapshots. [VERIFIED: test/crosswake/guides/release_boundaries_test.exs; .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md]

**When to use:** Use for public proof docs where stale commands, paths, ports, or authority claims can silently mislead adopters. [VERIFIED: .planning/REQUIREMENTS.md; prompts/crosswake-elixir-oss-dna.md]

### Anti-Patterns to Avoid

- **Documenting `mix setup` before adding aliases:** The current example host has no setup alias, so that would create a false clean-checkout path. [VERIFIED: examples/phoenix_host/mix.exs]
- **Running Playwright against the dev server:** The Playwright config starts its own `MIX_ENV=test` server and exposes `/_e2e`; reusing a dev server can hide wrong environment assumptions and cause port conflicts. [VERIFIED: examples/phoenix_host/playwright.config.ts]
- **Bridge-owned mutation queues:** The bridge guide says the bridge is not navigation/render/high-frequency authority, and the offline proof uses app-owned JS plus Phoenix/Ecto. [VERIFIED: guides/bridge.md; examples/phoenix_host/priv/static/offline_study.js]
- **Native-first quick start:** Checked-in native hosts have local/stale coordinates, so native UI should stay advisory/local-development until Phase 119. [VERIFIED: examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj; examples/android_shell_host/app/build.gradle]
- **Conflict overclaim:** Current `/study/sync` proves validation rejections and duplicate idempotency; it does not ship a full conflict-resolution UI. [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/study.ex; .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md]

## Implementation Strategy

### Plan 118-01: Quick Start And Aliases

1. Add aliases to `examples/phoenix_host/mix.exs`: `setup: ["deps.get", "ecto.setup"]`, `ecto.setup: ["ecto.create --quiet", "ecto.migrate --quiet", "run priv/repo/seeds.exs"]` only if seed file exists, and `ecto.reset: ["ecto.drop --quiet", "ecto.setup"]`; if no seed file exists, omit or guard the seed step transparently. [VERIFIED: examples/phoenix_host/mix.exs; examples/phoenix_host/priv]
2. Preserve the existing `test` alias behavior and avoid broad dependency/version changes. [VERIFIED: examples/phoenix_host/mix.exs; examples/phoenix_host/mix.lock]
3. Rewrite `examples/QUICK_START.md` around headings like First run, See route owners, Prove offline replay, Prove bounded bridge, Native steps are advisory, and What this does not prove. [VERIFIED: .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md; brandbook/BRAND-SPEC.md]
4. Document exact routes and expected observations: `/` loads the host, `/offline` shows Offline Study Island and no LiveView socket dependency is asserted by E2E, `/bridge-proof` exposes the bridge proof route. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex; examples/phoenix_host/e2e/offline_sync.spec.ts]
5. Keep native steps under advisory/local-development labels and explain that Phase 119 owns published-coordinate classification. [VERIFIED: .planning/STATE.md; examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj; examples/android_shell_host/app/build.gradle]

### Plan 118-02: Adoption Guide Rewrite

1. Replace the Phase 116 stub with a proof walkthrough first: route owner, local store, queued event, reconnect flush, `/study/sync`, Ecto validation, accepted/rejected response, idempotent duplicate, and local outbox deletion. [VERIFIED: guides/adoption.md; examples/phoenix_host/e2e/offline_sync.spec.ts]
2. Then extract a reusable adopter recipe: declare route owner, build the island, persist semantic events, flush on reconnect/explicit sync, reconcile in Phoenix/Ecto, test the whole loop. [VERIFIED: .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md; prompts/elixir-mobile-offlinesupport-flashcard-app-stresstest-deep-research.md]
3. Use exact implementation names where useful: `offline_study.js`, `SyncController`, `Study.sync_events/1`, and `ReviewEvent`. [VERIFIED: examples/phoenix_host/priv/static/offline_study.js; examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex; examples/phoenix_host/lib/crosswake_example/local_first/study.ex; examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex]
4. Ban stale authority wording: `Crosswake.mutate`, "Sync Engine (Bridge)", bridge-owned mutation queue, app-wide local-first, and broad background sync. [VERIFIED: .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md; guides/bridge.md; guides/offline.md]

### Plan 118-03: DRIFT-02 Guard

1. Add `test/crosswake/guides/quick_start_adoption_drift_test.exs` using the Phase 116 scanner style. [VERIFIED: test/crosswake/guides/release_boundaries_test.exs]
2. Implement repo-derived facts: current version, host port, Playwright port/base URL, alias names, required file paths, and required route strings. [VERIFIED: mix.exs; examples/phoenix_host/config/config.exs; examples/phoenix_host/playwright.config.ts; examples/phoenix_host/mix.exs]
3. Scan `examples/QUICK_START.md` and `guides/adoption.md` for required positive terms and forbidden negative patterns. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md]
4. Add synthetic regression tests for wrong port, missing setup alias command, missing path, forbidden `Crosswake.mutate`, forbidden "Sync Engine (Bridge)", bridge-owned mutation queue language, and missing advisory native label. [VERIFIED: .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md; test/crosswake/guides/release_boundaries_test.exs]

## File-Level Recommendations

| File | Recommendation | Notes |
|------|----------------|-------|
| `examples/phoenix_host/mix.exs` | Add `setup`, `ecto.setup`, and `ecto.reset` aliases. | Keep aliases transparent and small; preserve existing `test` alias. [VERIFIED: examples/phoenix_host/mix.exs] |
| `examples/QUICK_START.md` | Full rewrite, not incremental patch. | Current file explicitly says Phase 118 owns the rewrite. [VERIFIED: examples/QUICK_START.md] |
| `guides/adoption.md` | Full rewrite around real app-owned offline proof. | Current file is a temporary note with only high-level truth. [VERIFIED: guides/adoption.md] |
| `test/crosswake/guides/quick_start_adoption_drift_test.exs` | New ExUnit scanner with synthetic regression cases. | Follow `ReleaseBoundariesTest` structure for scanners and failure formatting. [VERIFIED: test/crosswake/guides/release_boundaries_test.exs] |
| `script/verify_bounded_bridge_proof.sh` | Keep passing after quick-start rewrite. | Script currently requires `/bridge-proof` and "Share" in `examples/QUICK_START.md`. [VERIFIED: script/verify_bounded_bridge_proof.sh] |
| `examples/phoenix_host/playwright.config.ts` | Do not change unless implementation discovers a proof blocker. | It already has the correct local test server shape for Phase 118. [VERIFIED: examples/phoenix_host/playwright.config.ts] |
| `examples/phoenix_host/e2e/offline_sync.spec.ts` | Do not rewrite for docs work. | It already exercises the required v12 proof path. [VERIFIED: examples/phoenix_host/e2e/offline_sync.spec.ts] |
| Native host project files | Do not fix classification in Phase 118. | iOS/Android coordinate truth is Phase 119 scope. [VERIFIED: .planning/ROADMAP.md; .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md] |

## Proof And Command Strategy

Use this proof ladder in the quick start and PLAN.md tasks. [VERIFIED: .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md]

```bash
# First run, from repo root
cd examples/phoenix_host
mix setup
PORT=4002 mix phx.server
```

Expected reader checks: open `http://localhost:4002/`, `http://localhost:4002/offline`, and `http://localhost:4002/bridge-proof`. [VERIFIED: examples/phoenix_host/config/config.exs; examples/phoenix_host/lib/crosswake_example/router.ex]

```bash
# Required offline correctness proof; stop the dev server first
cd examples/phoenix_host
npm ci
npx playwright install chromium
npx playwright test e2e/offline_sync.spec.ts
```

This proof starts its own `MIX_ENV=test` server on port `4002`, drives a real UI mutation into IndexedDB, dispatches `window` `online`, waits for `/study/sync`, asserts Ecto state, verifies accepted outbox deletion, and checks duplicate idempotency. [VERIFIED: examples/phoenix_host/playwright.config.ts; examples/phoenix_host/e2e/offline_sync.spec.ts]

```bash
# Required bounded bridge backend/docs proof, from repo root
bash script/verify_bounded_bridge_proof.sh
```

This proof currently asserts quick-start bridge wording and runs the backend bridge proof test. [VERIFIED: script/verify_bounded_bridge_proof.sh]

```bash
# Required contract proof without native overclaim, from repo root
CROSSWAKE_PHASE5_NATIVE_PROOFS=0 bash script/verify_phase5_example_hosts.sh
```

This skips native verification hooks and proves the manifest/example-host contract lane without simulator, emulator, or device claims. [VERIFIED: script/verify_phase5_example_hosts.sh]

```bash
# Structural honesty guard for the existing E2E, after npm ci
node script/check-e2e-honesty.mjs
```

This guard bans known fabricated E2E shapes such as injected globals, fetch inside `page.evaluate`, and spec-minted UUIDs. [VERIFIED: script/check-e2e-honesty.mjs]

## Drift Guard Strategy

### Scanner Inputs

| Input | Why |
|-------|-----|
| `Application.spec(:crosswake, :vsn)` | Derive current package version instead of freezing `0.1.2` in scanner logic. [VERIFIED: test/crosswake/guides/release_boundaries_test.exs; mix.exs] |
| `examples/phoenix_host/config/config.exs` | Derive default Phoenix port `4002`. [VERIFIED: examples/phoenix_host/config/config.exs] |
| `examples/phoenix_host/playwright.config.ts` | Cross-check Playwright base URL/webServer port and proof server behavior. [VERIFIED: examples/phoenix_host/playwright.config.ts] |
| `examples/phoenix_host/mix.exs` | Confirm `setup`, `ecto.setup`, and `ecto.reset` aliases exist before docs claim them. [VERIFIED: examples/phoenix_host/mix.exs] |
| File paths and route strings | Confirm documented paths exist and route/proof paths are current. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex; local repo paths] |

### Required Positive Assertions

- `examples/QUICK_START.md` contains `mix setup`, `PORT=4002 mix phx.server`, `npm ci`, `npx playwright install chromium`, `npx playwright test e2e/offline_sync.spec.ts`, `bash script/verify_bounded_bridge_proof.sh`, and `CROSSWAKE_PHASE5_NATIVE_PROOFS=0 bash script/verify_phase5_example_hosts.sh`. [VERIFIED: .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md]
- `examples/QUICK_START.md` names `examples/phoenix_host`, `examples/ios_shell_host/CrosswakeShell.xcodeproj`, `examples/android_shell_host`, `/offline`, `/bridge-proof`, and `/study/sync`. [VERIFIED: .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md]
- `examples/QUICK_START.md` includes advisory/local-development wording around native iOS/Android steps. [VERIFIED: .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md; examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj; examples/android_shell_host/app/build.gradle]
- `guides/adoption.md` contains `IndexedDB`, `flushOutbox`, `/study/sync`, `client_mutation_id`, `on_conflict: :nothing`, `accepted`, `rejected`, `conflict`, and outbox deletion language. [VERIFIED: .planning/REQUIREMENTS.md; examples/phoenix_host/priv/static/offline_study.js; examples/phoenix_host/lib/crosswake_example/local_first/study.ex]

### Forbidden Patterns

- `Crosswake.mutate`. [VERIFIED: .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md]
- `Sync Engine (Bridge)`. [VERIFIED: .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md]
- Bridge-owned mutation queues or bridge as offline mutation authority. [VERIFIED: guides/bridge.md; guides/adoption.md]
- Port `4000` as the current Phoenix host proof path. [VERIFIED: examples/phoenix_host/config/config.exs]
- Native simulator/emulator/device steps without advisory/local-development proof labels. [VERIFIED: .planning/STATE.md; .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md]
- App-wide local-first or broad background sync claims. [VERIFIED: guides/offline.md; guides/route_policy.md]

### Failure Format

Use maps like `%{path:, category:, line:, claim:, detail:}` and format failures as `- path:line [category] detail -- claim`, following `ReleaseBoundariesTest`. [VERIFIED: test/crosswake/guides/release_boundaries_test.exs]

## Architectural Responsibility Map

| Capability | Primary Owner / Tier | Secondary Owner / Tier | Rationale |
|------------|----------------------|------------------------|-----------|
| Quick-start docs | Public docs / docs-contract tier | Phoenix host proof scripts | Docs own the adopter path, but every command must map to existing host/proof behavior. [VERIFIED: examples/QUICK_START.md; script/verify_bounded_bridge_proof.sh] |
| Adoption guide | Public docs / route-owner education tier | Browser island and Phoenix/Ecto implementation | The guide should explain the shipped flow and reusable pattern without becoming provider-internal architecture prose. [VERIFIED: guides/adoption.md; examples/phoenix_host/priv/static/offline_study.js; examples/phoenix_host/lib/crosswake_example/local_first/study.ex] |
| Phoenix host aliases | Phoenix example host / Mix tier | Docs-contract scanner | Aliases must exist in `examples/phoenix_host/mix.exs` before docs claim clean-checkout setup. [VERIFIED: examples/phoenix_host/mix.exs] |
| Offline island JavaScript | Browser / client storage tier | Phoenix API for reconciliation | The island owns local event capture, IndexedDB outbox, reconnect flush, and accepted-record deletion. [VERIFIED: examples/phoenix_host/priv/static/offline_study.js] |
| Phoenix sync controller | API / Backend tier | Browser island | `/study/sync` receives batched events and delegates to `Study.sync_events/1`. [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex] |
| Ecto context/schema | Database / persistence tier | API controller | Changesets validate event payloads and `insert_all` enforces idempotent duplicate replay by `client_mutation_id`. [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/study.ex; examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex] |
| Playwright offline proof | E2E harness / Browser automation tier | Phoenix test server | Playwright owns network emulation and user-flow proof; the config owns the test server and `/_e2e` route availability. [VERIFIED: examples/phoenix_host/playwright.config.ts; examples/phoenix_host/e2e/offline_sync.spec.ts] |
| Bridge proof | Proof script / backend test tier | Quick-start docs | The script verifies quick-start bridge mentions and backend bridge behavior; native share-sheet UI remains advisory. [VERIFIED: script/verify_bounded_bridge_proof.sh] |
| Native evidence caveats | Public docs / support-truth vocabulary tier | Native host/template files | Phase 118 may document paths but must not classify checked-in hosts as published-coordinate proof. [VERIFIED: examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj; examples/android_shell_host/app/build.gradle; .planning/ROADMAP.md] |
| ExUnit scanner | Test / docs-contract tier | Public docs | The scanner owns durable DRIFT-02 enforcement and should derive facts from repo sources. [VERIFIED: test/crosswake/guides/release_boundaries_test.exs; .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md] |

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Elixir framework | ExUnit via Mix 1.19.5. [VERIFIED: local command `mix --version`] |
| Browser framework | Playwright Test 1.60.0 from `examples/phoenix_host/package-lock.json`. [VERIFIED: examples/phoenix_host/package-lock.json] |
| Existing docs-contract tests | `test/crosswake/guides/release_boundaries_test.exs`, `route_policy_test.exs`, `web_to_mobile_migration_test.exs`. [VERIFIED: test/crosswake/guides/release_boundaries_test.exs; test/crosswake/guides/route_policy_test.exs; test/crosswake/guides/web_to_mobile_migration_test.exs] |
| New guard file | `test/crosswake/guides/quick_start_adoption_drift_test.exs`. [VERIFIED: .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| QUICK-01 | Quick start contains correct setup aliases, port, paths, proof commands, expected caveats. | ExUnit docs-contract plus targeted command smoke. | `mix test test/crosswake/guides/quick_start_adoption_drift_test.exs` and `cd examples/phoenix_host && mix setup`. | New guard missing; alias missing. [VERIFIED: examples/phoenix_host/mix.exs] |
| ADOPT-01 | Adoption guide teaches app-owned IndexedDB/reconnect/Ecto proof and forbids bridge-owned mutation authority. | ExUnit docs-contract plus existing Playwright proof. | `mix test test/crosswake/guides/quick_start_adoption_drift_test.exs` and `cd examples/phoenix_host && npx playwright test e2e/offline_sync.spec.ts`. | New guard missing; E2E exists. [VERIFIED: examples/phoenix_host/e2e/offline_sync.spec.ts] |
| DRIFT-02 | Scanner catches wrong port/path claims, missing setup aliases, forbidden mutation language, and missing advisory native labels. | Unit-level synthetic scanner cases. | `mix test test/crosswake/guides/quick_start_adoption_drift_test.exs`. | Missing; must be Wave 2. [VERIFIED: .planning/ROADMAP.md] |

### Concrete Validation Commands

```bash
# New docs-contract guard
mix test test/crosswake/guides/quick_start_adoption_drift_test.exs

# Neighbor guide/support-truth guards
mix test \
  test/crosswake/guides/release_boundaries_test.exs \
  test/crosswake/guides/route_policy_test.exs \
  test/crosswake/guides/web_to_mobile_migration_test.exs \
  test/crosswake/support_matrix/renderer_test.exs \
  test/crosswake/support_matrix/support_matrix_test.exs

# Clean-checkout Phoenix host path after alias work
cd examples/phoenix_host
mix setup
PORT=4002 mix phx.server

# Offline E2E proof after stopping the dev server
cd examples/phoenix_host
npm ci
npx playwright install chromium
npx playwright test e2e/offline_sync.spec.ts

# Existing proof lanes from repo root
bash script/verify_bounded_bridge_proof.sh
CROSSWAKE_PHASE5_NATIVE_PROOFS=0 bash script/verify_phase5_example_hosts.sh
node script/check-e2e-honesty.mjs
```

### Sampling Rate

- Per task commit: run the new guard or the narrow command touched by the task. [VERIFIED: .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md]
- Per wave merge: run all docs-contract tests plus the relevant proof command for that wave. [VERIFIED: .planning/ROADMAP.md]
- Phase gate: run new guard, neighbor guide tests, Playwright offline E2E, bounded bridge proof, native-skipped phase5 proof, and E2E honesty guard. [VERIFIED: .planning/REQUIREMENTS.md; examples/phoenix_host/e2e/offline_sync.spec.ts; script/verify_bounded_bridge_proof.sh; script/verify_phase5_example_hosts.sh; script/check-e2e-honesty.mjs]

### Wave 0 Gaps

- [ ] `examples/phoenix_host/mix.exs` lacks `setup`, `ecto.setup`, and `ecto.reset`. [VERIFIED: examples/phoenix_host/mix.exs]
- [ ] `test/crosswake/guides/quick_start_adoption_drift_test.exs` does not exist yet. [VERIFIED: local repo file check]
- [ ] `examples/QUICK_START.md` and `guides/adoption.md` are temporary Phase 116 safety notes. [VERIFIED: examples/QUICK_START.md; guides/adoption.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Mix | Phoenix aliases and ExUnit tests | yes | Elixir 1.19.5 / Mix 1.19.5 | none needed. [VERIFIED: local command] |
| Node / npm | Playwright proof and E2E honesty guard | yes | Node v22.14.0 / npm 11.1.0 | none needed. [VERIFIED: local command] |
| Playwright package | Offline E2E proof | yes | 1.60.0 installed from lockfile | Run `npm ci` if absent. [VERIFIED: local command `npx playwright --version`; examples/phoenix_host/package-lock.json] |
| Xcode | Advisory iOS local-development walkthrough | yes | Xcode 26.5 | Keep advisory; not required for Phase 118. [VERIFIED: local command `xcodebuild -version`] |
| Java runtime | Advisory Android Gradle run | no | unavailable locally | Keep Android native run advisory; do not gate Phase 118 on it. [VERIFIED: local command `java -version`] |
| Android Gradle wrapper | Advisory Android local-development walkthrough | yes | wrapper present | Requires Java/Android tooling; not required for Phase 118. [VERIFIED: examples/android_shell_host/gradlew] |

**Missing dependencies with no fallback:** none for required Phase 118 validation. [VERIFIED: local command audit]  
**Missing dependencies with fallback:** Java runtime for advisory Android native steps; fallback is docs-only advisory wording and `CROSSWAKE_PHASE5_NATIVE_PROOFS=0` contract proof. [VERIFIED: local command audit; script/verify_phase5_example_hosts.sh]

## Risks And Mitigations

| Risk | Mitigation |
|------|------------|
| Quick start claims `mix setup` before aliases exist. | Implement aliases first and add scanner assertion for alias existence. [VERIFIED: examples/phoenix_host/mix.exs] |
| Playwright proof collides with a running dev server. | Quick start must instruct users to stop `mix phx.server` before the E2E proof; scanner should require this caveat. [VERIFIED: examples/phoenix_host/playwright.config.ts; .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md] |
| Adoption guide implies broad background sync or bridge mutation authority. | Use explicit "app-owned outbox", "reconnect-triggered flush", and "bridge is not mutation authority" language; scanner should ban stale phrases. [VERIFIED: guides/offline.md; guides/bridge.md; examples/phoenix_host/priv/static/offline_study.js] |
| Conflict semantics are overstated. | Explain `conflict` as canonical Crosswake outcome vocabulary while stating the current endpoint proves accepted/rejected/duplicate-idempotent/outbox-deletion behavior. [VERIFIED: .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md; examples/phoenix_host/lib/crosswake_example/local_first/study.ex] |
| Native evidence labels outrun Phase 119. | Keep checked-in iOS/Android steps advisory/local-development and avoid published-coordinate claims for those hosts. [VERIFIED: examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj; examples/android_shell_host/app/build.gradle] |
| Scanner becomes brittle against prose edits. | Scan for structural commands, paths, ports, required vocabulary, and forbidden patterns; avoid paragraph snapshots. [VERIFIED: test/crosswake/guides/release_boundaries_test.exs; .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md] |
| Node proof dependency gets upgraded during docs work. | Use `npm ci` from the lockfile; do not change `package.json` or `package-lock.json` in Phase 118. [VERIFIED: examples/phoenix_host/package-lock.json; package-legitimacy seam] |

## Planner Guidance

- Keep Wave 1 as two independent docs/code slices: 118-01 adds aliases and rewrites quick start; 118-02 rewrites adoption around the existing v12 proof. [VERIFIED: .planning/ROADMAP.md]
- Gate Wave 2 on Wave 1 docs text so the scanner can assert the final public contract rather than temporary wording. [VERIFIED: .planning/ROADMAP.md]
- Do not plan native coordinate fixes, screenshots, recordings, artifact manifests, or troubleshooting expansion in Phase 118. [VERIFIED: .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md]
- Treat `script/verify_bounded_bridge_proof.sh` as an integration point: if quick-start wording changes, keep `/bridge-proof` and "Share" present or update the script intentionally. [VERIFIED: script/verify_bounded_bridge_proof.sh]
- Treat `examples/phoenix_host/playwright.config.ts` as current proof truth; avoid "cleaning up" the E2E harness unless a real blocker appears. [VERIFIED: examples/phoenix_host/playwright.config.ts]
- Use current support-truth vocabulary from Phase 117: merge-blocking proof, advisory evidence, local-dev proof, generated public-coordinate proof, JVM hermetic proof, emulator evidence, device evidence, verification-required, and rebuild-required. [VERIFIED: guides/support_matrix.md; test/crosswake/support_matrix/renderer_test.exs]

## Security Domain

Security enforcement is enabled by default because `.planning/config.json` does not set `security_enforcement: false`. [VERIFIED: .planning/config.json]

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no direct new auth behavior | Phase 118 changes docs/tests only; keep existing route-owner/auth posture untouched. [VERIFIED: .planning/ROADMAP.md] |
| V3 Session Management | no direct new session behavior | Do not change LiveView/session handling in the quick-start docs work. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] |
| V4 Access Control | yes, as docs truth | Preserve route policy and bridge denial boundaries; do not describe bridge as authority. [VERIFIED: guides/bridge.md; guides/route_policy.md] |
| V5 Input Validation | yes | Adoption guide should name Phoenix/Ecto validation via `ReviewEvent.changeset/2`. [VERIFIED: examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex] |
| V6 Cryptography | no new crypto | No new crypto or signing behavior belongs in Phase 118. [VERIFIED: .planning/REQUIREMENTS.md] |

Known threat patterns for this phase are documentation-induced overclaiming, stale proof commands, and authority confusion; the standard mitigation is docs-contract scanning plus required proof commands. [VERIFIED: test/crosswake/guides/release_boundaries_test.exs; script/check-e2e-honesty.mjs]

## Sources

### Primary (HIGH confidence)

- `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` - milestone thesis, Phase 118 scope, active requirements, blockers, and proof boundaries. [VERIFIED: local file reads]
- `.planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md` - locked decisions and deferred scope. [VERIFIED: local file read]
- `examples/phoenix_host/*`, `examples/QUICK_START.md`, `guides/adoption.md`, `script/*`, and guide tests - current implementation and proof-lane truth. [VERIFIED: local file reads]
- `brandbook/BRAND-SPEC.md` and prompt lineage files - voice, product thesis, offline-island, and proof-posture constraints. [VERIFIED: local file reads]

### Secondary (MEDIUM confidence)

- Phoenix Ecto guide - migration and Ecto setup behavior. [CITED: https://phoenix.hexdocs.pm/ecto.html]
- Ecto Repo and upsert docs - `insert_all`, `:on_conflict`, `:conflict_target`, `:returning`, transactions, and idempotent inserts. [CITED: https://ecto.hexdocs.pm/Ecto.Repo.html; CITED: https://ecto.hexdocs.pm/constraints-and-upserts.html]
- Playwright webServer and BrowserContext docs - local server launch and offline network emulation. [CITED: https://playwright.dev/docs/test-webserver; CITED: https://playwright.dev/docs/api/class-browsercontext]
- MDN IndexedDB and web.dev IndexedDB articles - structured client-side storage, object stores, transactions, same-origin scope, and quota/eviction caveats. [CITED: https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API; CITED: https://web.dev/articles/indexeddb]

### Tooling Notes

- GSD init/query tooling worked through `/Users/jon/.claude/gsd-core/bin/gsd-tools.cjs`; the global Codex shim failed on a missing `package.json` require. [VERIFIED: local command]
- Graphify is disabled for this repo, so no graph context influenced this research. [VERIFIED: local command `gsd-tools graphify status`]
- Context7 MCP and `ctx7` CLI were unavailable, so official docs were retrieved through web search/open and stored through the GSD research cache as MEDIUM-confidence official-doc digests. [VERIFIED: local command; research-store seam]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | No seed file exists in `examples/phoenix_host/priv/repo/seeds.exs`, so the setup alias should either omit seeds or guard that step. | Implementation Strategy | A planner might add an alias that references a missing seed file unless it verifies before editing. [VERIFIED: local repo path check] |

## Open Questions

1. **Should aliases run seeds if a seed file is added during implementation?**  
   What we know: no seed file was found during research, and current setup only needs create/migrate for SQLite. [VERIFIED: examples/phoenix_host/mix.exs; local repo path check]  
   What's unclear: whether implementers want to add a tiny seed file for clearer demo data. [ASSUMED]  
   Recommendation: do not add seed scope unless the quick-start path actually needs it; if no seed file exists, keep `ecto.setup` to create/migrate only. [VERIFIED: examples/phoenix_host/priv/static/offline_study.js]

2. **Should the Playwright config move from `port` to `url`?**  
   What we know: Playwright docs mark `port` deprecated in favor of `url`, but the current config works and Phase 118 is docs/proof-truth work. [CITED: https://playwright.dev/docs/test-webserver; VERIFIED: examples/phoenix_host/playwright.config.ts]  
   What's unclear: whether maintainers want a harness cleanup now. [ASSUMED]  
   Recommendation: leave it alone unless a test failure proves it blocks Phase 118; do not widen the phase. [VERIFIED: .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH for repo-locked versions, MEDIUM for official-doc cross-checks. [VERIFIED: examples/phoenix_host/mix.lock; examples/phoenix_host/package-lock.json; CITED: https://playwright.dev/docs/test-webserver]
- Architecture: HIGH because the locked context and current code agree on app-owned offline island and route-owner proof posture. [VERIFIED: .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md; examples/phoenix_host/priv/static/offline_study.js]
- Pitfalls: HIGH for repo-specific pitfalls, MEDIUM for official-doc caveats. [VERIFIED: examples/phoenix_host/playwright.config.ts; examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj; CITED: https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API]

**Research date:** 2026-06-19  
**Valid until:** 2026-07-19 for local repo-truth recommendations, or earlier if Phase 119 changes native evidence classification. [VERIFIED: .planning/ROADMAP.md]
