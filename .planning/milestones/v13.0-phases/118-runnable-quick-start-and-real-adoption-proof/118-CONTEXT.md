# Phase 118: Runnable Quick Start And Real Adoption Proof - Context

**Gathered:** 2026-06-19T14:51:03Z
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 118 turns Crosswake's first hands-on adopter path into a command-verified proof of current v11/v12 truth. It owns the full `examples/QUICK_START.md` rewrite, the full `guides/adoption.md` rewrite around the real app-owned IndexedDB outbox/reconnect/Ecto proof, and a DRIFT-02 guard that prevents stale commands, paths, ports, and fictional offline authority from returning.

This phase is a runnable proof-path and guide-truth phase. It is not native evidence classification, not simulator/emulator collateral capture, not troubleshooting/rough-edge guide completion, not a new offline engine, and not new capability breadth. Native steps may be path-exact and advisory, but checked-in native hosts must not be presented as published-coordinate adopter proof until Phase 119 settles that evidence class.

</domain>

<decisions>
## Implementation Decisions

### Quick Start Command Path

- **D-01:** Add Phoenix-style `setup`, `ecto.setup`, and `ecto.reset` aliases to `examples/phoenix_host/mix.exs` before documenting `mix setup` as the clean-checkout path. The alias should be small and transparent: fetch deps, create/migrate/seed the SQLite database, and provide a repeatable reset. Do not hide proof commands behind a single opaque script as the primary quick-start path.
- **D-02:** Rewrite `examples/QUICK_START.md` as "walkthrough first, proof second." The walkthrough should get the Phoenix host running at `http://localhost:4002`, show the reader the relevant routes, and state expected output. The proof section should then run deterministic commands that prove the architecture.
- **D-03:** Keep Node/Playwright setup explicit in the proof section. Recommended shape from `examples/phoenix_host`: `npm ci`, `npx playwright install chromium`, then `npx playwright test e2e/offline_sync.spec.ts`.
- **D-04:** The quick start must warn users to stop the dev server before running the Playwright offline proof. `examples/phoenix_host/playwright.config.ts` starts its own `MIX_ENV=test` Phoenix server on port `4002` and exposes the gated `/_e2e` route; reusing a dev server would be misleading and can cause port conflicts.
- **D-05:** Document exact current paths: Phoenix host `examples/phoenix_host`, iOS project `examples/ios_shell_host/CrosswakeShell.xcodeproj`, Android project `examples/android_shell_host`, offline route `/offline`, bridge route `/bridge-proof`, and sync endpoint `/study/sync`.
- **D-06:** Native iOS/Android run instructions may remain in the quick start only under explicit advisory/local-development wording. Phase 118 must not describe the checked-in native hosts as published-coordinate proof because iOS currently uses `XCLocalSwiftPackageReference` and Android still references `dev.crosswake:shell-core-android:0.1.0`.

### Proof Coverage

- **D-07:** Use a tiered proof ladder instead of smoke-only, CI-only, or native-first quick start. The recommended order is:
  1. Phoenix smoke: `mix setup`, `PORT=4002 mix phx.server`, then inspect `/`, `/offline`, and `/bridge-proof`.
  2. Required correctness proof: Playwright offline E2E for IndexedDB queue, reconnect-triggered app flush, Ecto row assertion, idempotent duplicate, and accepted outbox deletion.
  3. Bounded bridge proof: `bash script/verify_bounded_bridge_proof.sh` from the repo root. This is backend/docs proof; native share-sheet UI remains advisory.
  4. Native-owned/route-unavailable contract proof: `CROSSWAKE_PHASE5_NATIVE_PROOFS=0 bash script/verify_phase5_example_hosts.sh` from the repo root. This proves manifest/example-host contract truth without claiming simulator/device support.
  5. Optional native UI steps: Xcode/Android Studio walkthroughs labeled advisory until Phase 119.
- **D-08:** Make Playwright offline proof the first required correctness proof after the Phoenix smoke. The current E2E asserts the actual app-owned mutation path: UI click -> IndexedDB mutation -> explicit reconnect event -> `/study/sync` -> Ecto state -> outbox deletion.
- **D-09:** Do not make native simulator/emulator/device evidence merge-blocking or first-run required in Phase 118. Phase 119 owns native evidence labels; Phase 120 owns collateral capture.
- **D-10:** Do not replace the tiered ladder with a smoke-only guide. A smoke-only guide would let readers see pages but would not prove v12's real IndexedDB outbox/reconnect/Ecto loop.

### Adoption Guide Story

- **D-11:** Rewrite `guides/adoption.md` as both a real proof walkthrough and a reusable recipe. It should first teach the shipped flashcard flow, then extract the route-local offline-island pattern an adopter can copy conceptually.
- **D-12:** The guide must teach the v12 truth explicitly: app-owned island JavaScript stores semantic review events in IndexedDB; `window` `online` triggers `flushOutbox`; the client posts batched events to `/study/sync`; Phoenix routes that through an API controller; Ecto changesets validate payloads; `insert_all` with `on_conflict: :nothing` and `client_mutation_id` makes duplicate replay idempotent; accepted records are deleted from the local outbox; rejected records stay visible for user/operator handling.
- **D-13:** Use current implementation names where they matter: `examples/phoenix_host/priv/static/offline_study.js`, `CrosswakeExample.LocalFirst.SyncController`, `CrosswakeExample.LocalFirst.Study.sync_events/1`, and `CrosswakeExample.LocalFirst.ReviewEvent`.
- **D-14:** Be precise about outcome vocabulary. The current demo proves accepted records, rejected validation records, idempotent duplicate replay, and outbox deletion. "Conflict" is canonical Crosswake replay vocabulary and should be explained as an expected offline outcome class, but do not imply the current `/study/sync` endpoint ships a full conflict-resolution UI.
- **D-15:** Remove and forbid bridge-owned offline mutation language. `Crosswake.mutate`, "Sync Engine (Bridge)", generic bridge mutation queues, app-wide local-first claims, and broad background sync claims are stale or wrong for current Crosswake. The bridge is not the offline mutation authority.
- **D-16:** Frame the reusable recipe from the consumer's perspective: declare the route owner, build the island, persist small semantic events, flush on reconnect or explicit sync, reconcile on the Phoenix/Ecto side, and test the whole loop. Do not write the guide from the provider's internal architecture perspective.
- **D-17:** Use a skeptical Phoenix SaaS maintainer as the primary reader. They want to know who owns the route, where data enters, where it is stored, what command proves it, what happens on reconnect, and what they get back when replay succeeds or fails.

### DRIFT-02 Guard

- **D-18:** Add an idiomatic ExUnit docs-contract scanner as the DRIFT-02 guard, likely `test/crosswake/guides/quick_start_adoption_drift_test.exs`. Keep it in the normal `mix test` surface rather than adding a standalone Node/Bash scanner as the primary guard.
- **D-19:** Derive facts from repo sources instead of duplicating literals where practical: current Crosswake version from `Application.spec(:crosswake, :vsn)`, Phoenix host port from `examples/phoenix_host/config/config.exs` and `examples/phoenix_host/playwright.config.ts`, setup alias truth from `examples/phoenix_host/mix.exs`, and path truth from actual files/directories.
- **D-20:** Make the guard strict on structural proof truth and loose on prose. It should fail on wrong port/path claims, missing setup/proof commands, missing advisory native labels, forbidden offline-authority language, missing `IndexedDB`/`flushOutbox`/`/study/sync`/Ecto idempotency/outbox-deletion teaching, and missing accepted/rejected/conflict semantics. It should not fail because a paragraph was reworded.
- **D-21:** Include synthetic regression tests for the scanner itself. At minimum: wrong port, missing setup alias command, missing existing path, `Crosswake.mutate`, "Sync Engine (Bridge)", bridge-owned mutation queue language, and missing advisory native labels.
- **D-22:** Do not use executable markdown or a command-runner harness as DRIFT-02's default. That belongs to proof/UAT lanes because it is slower, more brittle, and more likely to collide with server ports or native tooling.
- **D-23:** Keep clear failure messages with file, line, category, and actionable detail, following the Phase 116 `release_boundaries_test.exs` style.

### UX, Voice, And Documentation Shape

- **D-24:** Quick-start and adoption microcopy should follow the current brand spec: precise, short, example-heavy, and candid. Prefer "Queued locally", "Synced N - queued M", "advisory native evidence", and "app-owned outbox" over hype or vague support claims.
- **D-25:** Use headings that match user jobs: First run, See the route owners, Prove offline replay, Prove bounded bridge, Native steps are advisory, Troubleshooting quick checks, and What this does not prove. Exact heading names can vary, but the reading order should stay first-run -> proof -> caveats.
- **D-26:** Keep UI/visual work out of Phase 118 unless implementation discovers a small copy/status mismatch directly blocking the guide. Broader screenshots, recordings, visual collateral, artifact manifests, and troubleshooting UX remain Phase 120.
- **D-27:** Preserve Crosswake's route-owner thesis in every public claim. The quick start should never sound like a generic WebView wrapper, React Native clone, LiveView-to-native renderer, plugin platform, or "everything works offline" promise.

### Claude's Discretion

The user selected all gray areas and asked for a one-shot, research-backed recommendation set. Downstream agents may choose exact test helper names, heading text, and assertion implementation details as long as they preserve the locked decisions above. The recommended file for the new guard is `test/crosswake/guides/quick_start_adoption_drift_test.exs`, but planners may split helpers if that keeps the test readable.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Carry-Forward Decisions

- `.planning/PROJECT.md` - v13 thesis, proof-path constraints, key project decisions, and non-goals.
- `.planning/REQUIREMENTS.md` - Phase 118 requirements: QUICK-01, ADOPT-01, DRIFT-02.
- `.planning/ROADMAP.md` - Phase 118 success criteria and 118-01/118-02/118-03 plan split.
- `.planning/STATE.md` - Current position, Phase 118 focus, native-host drift caveat, and operator next steps.
- `.planning/phases/116-proof-debt-and-release-truth/116-CONTEXT.md` - Prior release/proof truth decisions and Phase 118 boundary.
- `.planning/phases/117-route-policy-and-support-truth-guide-foundation/117-CONTEXT.md` - Support-label vocabulary, route-policy guide foundation, and Phase 118 deferrals.

### Prompt And Product Context

- `brandbook/BRAND-SPEC.md` - Current brand, docs voice, support-label tone, and visual/microcopy rules; supersedes the older brand prompt where they conflict.
- `prompts/crosswake-elixir-oss-dna.md` - Maintainer house style: install truth, proof lanes, docs contracts, support matrices, and release truth.
- `prompts/crosswake-gsd-project-brief.md` - Project thesis, explicit runtime ownership, and delivery/quality expectations.
- `prompts/crosswake-research-synthesis.md` - Stable architecture story and anti-patterns.
- `prompts/crosswake-integrations-and-companions.md` - Companion/integration boundaries; prevents Phase 118 from drifting into new capability work.
- `prompts/elixir-mobile-offlinesupport-flashcard-app-stresstest-deep-research.md` - Flashcard offline-island model, append-only review events, content-pack/offline lessons.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` - DX, troubleshooting, proof, and anti-pattern guidance for Phoenix-native mobile support.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` - Capability ladder, Hotwire/Capacitor/Expo lessons, and app-archetype stress tests.

### Public Docs And Guide Surfaces

- `README.md` - Public first-read map, current support-label vocabulary, and proof entry points.
- `examples/QUICK_START.md` - Primary Phase 118 rewrite target.
- `guides/adoption.md` - Primary Phase 118 rewrite target for v12 app-owned offline truth.
- `guides/install.md` - Install/proof path that should link coherently into quick start and adoption.
- `guides/route_policy.md` - Route-owner mental model from Phase 117 that quick start/adoption should reuse.
- `guides/web_to_mobile_migration.md` - Migration/JTBD framing to align adopter language.
- `guides/offline.md` - Cached read-only versus offline-island boundaries.
- `guides/bridge.md` - Bounded bridge vocabulary and denial posture.
- `guides/native_shell.md` - Native shell caveats and route-unavailable posture.
- `guides/support_matrix.md` - Canonical support-truth labels and proof-class vocabulary.
- `mix.exs` - ExDoc extras/groups and package docs wiring.

### Quick-Start Commands And Proof Lanes

- `examples/phoenix_host/mix.exs` - Existing aliases; Phase 118 should add `setup`, `ecto.setup`, and `ecto.reset`.
- `examples/phoenix_host/config/config.exs` - Default Phoenix host port `4002`.
- `examples/phoenix_host/playwright.config.ts` - Playwright base URL, `MIX_ENV=test` webServer, port `4002`, service-worker blocking, and one-worker posture.
- `examples/phoenix_host/package.json` - Playwright dependency/script surface for `npm ci` and `npx playwright test`.
- `examples/phoenix_host/e2e/offline_sync.spec.ts` - Required v12 offline correctness proof.
- `script/verify_bounded_bridge_proof.sh` - Deterministic bounded bridge proof command and current quick-start assertions.
- `script/verify_phase5_example_hosts.sh` - Existing manifest/example-host proof lane; use `CROSSWAKE_PHASE5_NATIVE_PROOFS=0` for Phase 118 contract proof without native overclaim.
- `script/check-e2e-honesty.mjs` - Existing structural honesty guard for offline E2E; useful pattern for proof-truth thinking.

### Offline App-Owned Proof Implementation

- `examples/phoenix_host/priv/static/offline_study.js` - IndexedDB stores, `queueMutation`, `flushOutbox`, accepted outbox deletion, status microcopy, and `window` `online` listener.
- `examples/phoenix_host/lib/crosswake_example/router.ex` - `/offline`, `/bridge-proof`, `/study/sync`, route-policy metadata, and API/browser pipelines.
- `examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex` - JSON endpoint for `/study/sync`.
- `examples/phoenix_host/lib/crosswake_example/local_first/study.ex` - Ecto validation, `insert_all`, idempotency via `on_conflict: :nothing`, accepted/rejected response shape.
- `examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex` - Review event schema and changeset source for adoption-guide semantics.
- `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_controller.ex` - Socketless `/offline` island entry point.
- `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex` - Offline island HTML and script loading.

### Drift-Guard Patterns

- `test/crosswake/guides/release_boundaries_test.exs` - Phase 116 docs-contract scanner pattern, synthetic stale-claim tests, and failure formatting.
- `test/crosswake/guides/route_policy_test.exs` - Existing route-policy guide docs-contract style.
- `test/crosswake/guides/web_to_mobile_migration_test.exs` - Existing migration guide docs-contract style.
- `test/crosswake/support_matrix/renderer_test.exs` - Generated support-matrix parity pattern.
- `test/crosswake/support_matrix/support_matrix_test.exs` - Support-label truth tests.

### Native Evidence Caveats

- `examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj` - Checked-in iOS host currently uses local package reference; do not call it published-coordinate proof.
- `examples/android_shell_host/app/build.gradle` - Checked-in Android host currently references stale local-era coordinate; do not call it published-coordinate proof.
- `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex` - Generator template includes public SwiftPM path for non-local scaffolding.
- `priv/templates/crosswake/shell/android/app/build.gradle.eex` - Generator template includes Maven Central coordinate for non-local scaffolding.
- `priv/templates/crosswake/shell/ios/README.md.eex` - Generated iOS README wording to keep aligned with evidence labels.
- `priv/templates/crosswake/shell/android/README.md.eex` - Generated Android README wording to keep aligned with evidence labels.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `examples/phoenix_host/playwright.config.ts`: Already provides the right proof harness shape: local webServer, `MIX_ENV=test`, port `4002`, one worker, retries in CI, service workers blocked, and DB reset before server start.
- `examples/phoenix_host/e2e/offline_sync.spec.ts`: Already proves the high-value v12 path: real UI mutation, IndexedDB observation, reconnect dispatch, `/study/sync` response, Ecto row assertion, outbox deletion, and duplicate idempotency.
- `script/verify_bounded_bridge_proof.sh`: Existing deterministic bridge proof command that checks `examples/QUICK_START.md` for `/bridge-proof` and runs backend bridge tests.
- `script/verify_phase5_example_hosts.sh`: Existing example-host proof lane can be used with `CROSSWAKE_PHASE5_NATIVE_PROOFS=0` to prove manifest/example-host contract truth while leaving native build/device evidence out of Phase 118.
- `test/crosswake/guides/release_boundaries_test.exs`: Strong local pattern for a docs-contract scanner that derives facts, scans public docs/manifests, includes synthetic cases, and formats actionable failures.

### Established Patterns

- Crosswake treats docs, support matrices, proof lanes, and drift guards as product surface. Phase 118 should add tests for guide truth rather than rely on review.
- The project already uses required-versus-advisory proof labels. Phase 118 should apply them exactly: browser/Playwright proof can be required correctness proof; checked-in native UI walkthroughs remain advisory/local-development proof until Phase 119.
- Existing v12 proof intentionally distinguishes observation-only test reads from app-owned state changes. The quick start and adoption guide should preserve that distinction.
- Phoenix/Ecto idiom favors explicit Mix commands, small aliases, and server-side validation/reconciliation. The guide should show the Phoenix side as a controller/context/schema flow, not as a generic sync engine.

### Integration Points

- `examples/QUICK_START.md` currently contains a Phase 116 safety note and stale-ish manual setup. Phase 118 should replace it completely.
- `guides/adoption.md` currently contains a Phase 116 temporary note. Phase 118 should replace the stub with the real proof walkthrough plus reusable recipe.
- `examples/phoenix_host/mix.exs` currently has only a `test` alias. Phase 118 should add setup/reset aliases before the quick start references them.
- `script/verify_bounded_bridge_proof.sh` currently scans `examples/QUICK_START.md`; if the quick-start wording changes, keep this script passing or improve the assertions deliberately.
- New DRIFT-02 tests should integrate with the existing ExUnit suite and avoid requiring Xcode, Android Studio, emulator, physical device, or a live server.

</code_context>

<specifics>
## Specific Ideas

- Subagent-backed recommendation for command path: add Phoenix-style setup aliases, then document `mix setup` for clean checkout and explicit Playwright commands for proof.
- Subagent-backed recommendation for proof coverage: use a tiered ladder, with Playwright offline proof as the required correctness proof and native UI steps advisory.
- Subagent-backed recommendation for adoption guide: "proof walkthrough first, reusable recipe second."
- Subagent-backed recommendation for DRIFT-02: ExUnit docs-contract scanner with repo-derived facts, synthetic regression cases, and clear failure messages.
- External ecosystem research consulted:
  - Phoenix/Ecto docs reinforce exact setup, migration, changeset, and persistence explanations: `https://phoenix.hexdocs.pm/ecto.html`, `https://ecto.hexdocs.pm/constraints-and-upserts.html`.
  - Playwright docs support using `webServer` for local proof servers and `browserContext.setOffline(...)` for offline emulation: `https://playwright.dev/docs/test-webserver`, `https://playwright.dev/docs/api/class-browsercontext`.
  - MDN and web.dev reinforce IndexedDB as structured client storage and warn that write failures, stale schemas, user-cleared storage, and large writes must be handled: `https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API`, `https://web.dev/articles/indexeddb-best-practices-app-state`.
  - Hotwire Native docs reinforce the path-config / bridge-component / native-screen separation Crosswake adapts with Phoenix route policy: `https://native.hotwired.dev/android/path-configuration`, `https://native.hotwired.dev/overview/bridge-components`.
  - Capacitor and Expo docs reinforce separating native environment setup and native runtime compatibility from the fastest first-run path: `https://capacitorjs.com/docs/getting-started`, `https://docs.expo.dev/eas-update/runtime-versions/`.
- JTBD lens: the first reader is a skeptical Phoenix SaaS maintainer asking "Can I run it, what does it prove, where does data go, and what does not get claimed?" Phase 118 should answer those questions in that order.
- Brand/UX lens: no hype, no "magic", no "everything offline"; use route-owner labels, proof-class labels, and short status-oriented microcopy.

</specifics>

<deferred>
## Deferred Ideas

- Checked-in iOS/Android host evidence classification remains Phase 119.
- Native docs/support matrix/native shell guide reconciliation to the chosen evidence class remains Phase 119.
- Native coordinate drift guard for stale `dev.crosswake:shell-core-android:0.1.0` and unlabeled `XCLocalSwiftPackageReference` remains Phase 119.
- Browser/native screenshots, recordings, artifact manifests, advisory native capture, and visual collateral remain Phase 120.
- Full troubleshooting and rough-edge examples for doctor findings, denials, route-unavailable states, offline outcomes, and native evidence caveats remain Phase 120.
- A standalone `script/verify_quick_start.sh` may be useful later, but it should not replace visible Mix/Playwright commands as Phase 118's primary quick-start path.
- Executable markdown command-running belongs in later proof/UAT work, not DRIFT-02's cheap docs-contract guard.
- Full conflict-resolution UI or a richer sync engine is out of Phase 118. Adoption docs can explain conflict as a canonical outcome class, but should not imply the current demo endpoint handles every conflict workflow.

</deferred>

---

*Phase: 118-Runnable Quick Start And Real Adoption Proof*
*Context gathered: 2026-06-19T14:51:03Z*
