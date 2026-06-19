# Phase 120: Collateral, Artifact CI, And Troubleshooting - Context

**Gathered:** 2026-06-19T22:10:00Z
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 120 packages durable route-ownership evidence and recovery guidance for Crosswake's adopter-confidence path. It owns the required browser route-tour proof, evidence bundle manifest/CI artifact contract, advisory iOS simulator and Android emulator collateral where available, and troubleshooting/rough-edge docs for route-owner failures.

This phase does not add new runtime capabilities, widen native support, promote simulator/emulator evidence to merge-blocking support, prove physical devices, prove camera/media/provider authority, implement DASH-01 or NTV-01, or reopen Phase 119's native evidence classification.

</domain>

<decisions>
## Implementation Decisions

### Browser Route-Tour Proof

- **D-01:** Add a dedicated required browser route-tour proof instead of folding broad route-owner collateral into `examples/phoenix_host/e2e/offline_sync.spec.ts`. The existing offline-sync proof should stay focused on real IndexedDB outbox/reconnect/Ecto correctness; the route tour should prove the broader route-owner story.
- **D-02:** Use semantic Playwright assertions as the correctness gate. Screenshots, videos, HTML reports, and traces are evidence/collateral only; they must never be the sole proof that behavior is correct.
- **D-03:** Prefer a split implementation shape: one required route-tour spec/helper layer for semantic assertions plus artifact/manifest packaging around the run. This keeps correctness, visual evidence, and support labels separable while still producing one coherent adopter-facing evidence bundle.
- **D-04:** The route-tour should cover these owner classes at minimum:
  - Phoenix-owned LiveView route: `/library` with route id `library`, or an equivalent stable Phoenix-owned route if planning finds `/library` unsuitable.
  - Bounded bridge route: `/bridge-proof`, proving the Share affordance and bridge semantics without making the native share sheet a required correctness gate.
  - Offline island: `/offline`, reusing or extracting the existing queue/reconnect `/study/sync`/Ecto assertions so the route tour proves real replay behavior without duplicating fragile IndexedDB plumbing.
  - Native-owned or route-unavailable path: `/native/claims/:id/capture` or an equivalent deterministic fixture that proves native-screen ownership/fail-closed route-unavailable posture without requiring a simulator/device.
- **D-05:** Make the browser route-tour proof merge-blocking through the existing E2E gate or a sibling aggregator with `merge-blocking-*` naming. Do not make native simulator/emulator collateral merge-blocking in this phase.
- **D-06:** If the native-screen/route-unavailable route needs fixture setup, add the smallest deterministic E2E fixture rather than weakening the assertion. The planner should avoid brittle auth/session setup in the route tour unless it is directly proving the owner boundary.

### Evidence Bundle And Artifact Contract

- **D-07:** Use a narrow hybrid evidence contract: one run-level `evidence-manifest.json` per CI route-tour run, with route-level entries inside it. Do not use separate per-route manifest files as the primary contract unless later growth proves the run-level manifest is too coarse.
- **D-08:** Each manifest route entry must include at least: Crosswake version, commit SHA, route id, runtime owner, platform/runtime, command, proof class, support label, coordinate mode when native-relevant, source job, captured-at timestamp, artifacts, retention label, and known limitations.
- **D-09:** The manifest should model required, advisory, and unavailable evidence explicitly. Missing required browser route-tour artifacts fail packaging. Optional native simulator/emulator artifacts may be absent only when the manifest records an advisory unavailable status with a concrete reason.
- **D-10:** Keep rich Playwright outputs as CI artifacts with bounded retention: HTML report, traces, videos, screenshots, and logs where useful. Use artifact upload settings that fail on missing expected files for required evidence.
- **D-11:** Commit only a small curated screenshot set plus manifest when docs need durable public collateral. Do not commit generated reports, traces, videos, native build products, simulator devices, emulator logs, or full Playwright output.
- **D-12:** Add an idiomatic ExUnit schema/contract validator for evidence manifests and captions. It should verify required keys, allowed proof/support labels, route ids, known-limitations presence, and missing-artifact failure semantics. Keep the schema tight so it does not become a generic artifact archive format.
- **D-13:** Job summaries should link the manifest and uploaded artifacts in adopter-readable terms: what was proven, what was captured, what remains advisory, and what is not claimed.

### Advisory Native Collateral

- **D-14:** Treat iOS simulator and Android emulator screenshots/recordings as advisory evidence only. They may increase confidence and improve visual collateral, but they do not imply physical-device support, camera support, media-upload support, provider authority, app-store readiness, or merge-blocking native support.
- **D-15:** Use a hybrid native capture posture:
  - Browser route-tour correctness remains merge-blocking.
  - Native simulator/emulator capture is best-effort advisory, preferably manual-dispatch or non-blocking at first.
  - Every native capture attempt, success, skip, or unavailable result must be represented in the evidence manifest with command, coordinate mode, platform/runtime, proof class, support label, captured-at timestamp, commit SHA, known limitations, and unavailable reason when skipped.
- **D-16:** Prefer checked-in public-coordinate host paths for native collateral captions, carrying forward Phase 119. Captions must say `checked-in public-coordinate proof` for coordinate mode and separately say `simulator evidence` or `emulator evidence` only when such a run actually occurred.
- **D-17:** If local tooling is unavailable, skipped native capture is acceptable only when honest: record `advisory evidence unavailable` or equivalent explicit status and explain the runner/tooling limitation. Do not silently skip and still present the route as visually proven.
- **D-18:** Do not introduce managed mobile test services, self-hosted runners, or vendor artifact systems in Phase 120. Those are future promotion options if a later milestone makes recurring native visual evidence more important.
- **D-19:** Native collateral should use the same manifest/caption vocabulary as browser collateral so adopters do not have to learn a second evidence language.

### Troubleshooting And Rough-Edge Docs

- **D-20:** Add a route-owner-first troubleshooting guide, likely `guides/troubleshooting.md`, with a symptom/finding index at the top. This preserves Crosswake's route-owner thesis while letting users search for copied error strings.
- **D-21:** Organize the main guide by owner: Phoenix/LiveView, bounded bridge, cached read-only, offline island, native screen, and backend/provider seam. Use the symptom index to route exact findings and denial codes to the right owner section.
- **D-22:** Each troubleshooting entry should follow the same compact contract:
  - What you see.
  - Who owns the fix.
  - Run this.
  - Change this route policy, host setup, or proof command.
  - What this does not prove.
- **D-23:** Required examples include at least: `undeclared_capability`, `unavailable_capability`, `compatibility_mismatch`, `pack_incompatible`, `external_entry_denied`, `gate_denied`, `step_up_required`, route-unavailable states, native evidence label confusion, rejected offline replay, and conflict/replay outcomes.
- **D-24:** Keep the guide user/JTBD-focused. Do not expose backend internals, support-matrix data structures, or doctor formatter implementation unless needed to explain a fundamental route-owner constraint. The user should learn which owner must change and what command proves recovery.
- **D-25:** Use the ratified brand voice from `brandbook/BRAND-SPEC.md`: calm, precise, candid, short, and example-heavy. Avoid "magic", "just works", "native support" without proof class, "everything offline", generic WebView-wrapper framing, and screenshot-as-proof language.
- **D-26:** Add an ExUnit docs-contract scanner for troubleshooting coverage. It should verify that canonical findings/denials have an owner, remediation, proof label, limitation, and link back to the support matrix or doctor truth. It should check structure and required concepts without freezing prose unnecessarily.
- **D-27:** Update README/ExDoc guide maps only enough to expose the troubleshooting guide and evidence collateral path. Do not bloat README into the troubleshooting manual.

### Coherent UX/DX Direction

- **D-28:** The Phase 120 reader is a skeptical Phoenix SaaS adopter or maintainer asking: "Can I see Crosswake working, what exactly did this prove, and what do I do when it fails?" The evidence path should answer that in order.
- **D-29:** Use one visual/caption language across browser and native artifacts: route id, runtime owner, proof class, support label, command, result, and limitation. This is the UX layer for evidence; it should hide CI plumbing unless the reader clicks into the manifest.
- **D-30:** Preserve least surprise for Phoenix/Elixir users: Mix/ExUnit owns structural docs/evidence validation, Playwright owns browser behavior and screenshots, GitHub Actions owns artifact retention/upload, and native tools remain optional/advisory unless explicitly promoted.
- **D-31:** Accessibility and visual quality matter for committed screenshots and docs surfaces: captions must be readable, dark/light/system-safe where applicable, and use existing Crosswake tokens/assets instead of inventing a new visual language. Visual collateral should reveal actual route state, not abstract marketing art.
- **D-32:** Downstream implementation should optimize for debuggability: route-tour failures should name the route id and owner class, manifest validation failures should name the missing field/artifact, and troubleshooting entries should map symptoms to commands and route-owner next actions.

### Claude's Discretion

The user selected all gray areas and requested a one-shot research-backed recommendation set. Downstream agents may choose exact file names, helper function names, manifest module names, workflow job names, and screenshot paths as long as they preserve the decisions above. Recommended defaults are `route_tour.spec.ts`, a run-level `evidence-manifest.json`, `guides/troubleshooting.md`, and an ExUnit evidence/troubleshooting docs-contract test.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Carry-Forward Decisions

- `.planning/PROJECT.md` — v13 thesis, proof-path constraints, core Crosswake decisions, and current Phase 120 focus.
- `.planning/REQUIREMENTS.md` — COLL-01, COLL-02, NATIVE-COLL-01, TROUBLE-01 requirements and v13 scope lock.
- `.planning/ROADMAP.md` — Phase 120 goal, success criteria, and 120-01/120-02/120-03/120-04 plan split.
- `.planning/STATE.md` — Current position, completed Phase 119 decisions, and collateral gap.
- `.planning/phases/117-route-policy-and-support-truth-guide-foundation/117-CONTEXT.md` — Route-policy guide foundation, support-truth vocabulary, and Phase 120 deferrals.
- `.planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md` — Quick-start/adoption proof decisions, existing Playwright proof boundaries, and Phase 120 deferrals.
- `.planning/phases/119-native-evidence-classification/119-CONTEXT.md` — Locked native evidence labels, checked-in public-coordinate proof strategy, and DRIFT-03 decisions.

### Brand, Product, And Research Context

- `brandbook/BRAND-SPEC.md` — Ratified brand, docs voice, proof-label tone, visual principles, and current authority over older prompt brand material.
- `prompts/crosswake-elixir-oss-dna.md` — Maintainer house style: install truth, proof lanes, docs contracts, support matrices, and explicit rough edges.
- `prompts/crosswake-gsd-project-brief.md` — Route-policy thesis, capability ladder, Phoenix-native priorities, and delivery/quality expectations.
- `prompts/crosswake-research-synthesis.md` — Stable architecture story and anti-patterns.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` — Hotwire Native, Capacitor, Expo, Tauri, React Native, and Flutter lessons for route, bridge, and proof boundaries.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` — Capability ladder, app archetype stress tests, native-screen boundaries, and proof pitfalls.
- `prompts/elixir-mobile-offlinesupport-flashcard-app-stresstest-deep-research.md` — Offline-island and append-only replay model used by the current proof path.

### Browser Route-Tour And Offline Proof Surfaces

- `examples/phoenix_host/playwright.config.ts` — Current Playwright server, reporter, port, trace, and one-worker settings.
- `examples/phoenix_host/e2e/offline_sync.spec.ts` — Existing real IndexedDB outbox/reconnect `/study/sync`/Ecto proof to reuse or extract carefully.
- `examples/phoenix_host/lib/crosswake_example/router.ex` — Route ids and owner classes for `/library`, `/bridge-proof`, `/offline`, `/native/claims/:id/capture`, `/study/sync`, and `/_e2e`.
- `examples/phoenix_host/priv/static/offline_study.js` — App-owned IndexedDB outbox, `flushOutbox`, status microcopy, and online-event behavior.
- `examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex` — `/study/sync` endpoint used by the browser proof.
- `examples/phoenix_host/lib/crosswake_example/local_first/study.ex` — Ecto validation, `insert_all`, idempotent replay, and accepted/rejected semantics.
- `examples/QUICK_START.md` — Current adopter proof ladder and Phase 120 caveat.
- `.github/workflows/offline-sync-e2e-gate.yml` — Existing E2E gate to extend or aggregate with the route-tour proof.
- `script/check-e2e-honesty.mjs` — Existing structural honesty guard pattern for preventing fabricated E2E proof.

### Native Evidence And Support Labels

- `examples/ios_shell_host/README.md` — Checked-in iOS public-coordinate proof wording and future caption source.
- `examples/android_shell_host/README.md` — Checked-in Android public-coordinate proof wording and future caption source.
- `guides/native_shell.md` — Native shell, route-unavailable, native capture, advisory emulator/device boundaries.
- `guides/android_uat.md` — Android UAT and advisory/native evidence caveats.
- `guides/support_matrix.md` — Canonical support-truth label legend and proof/support vocabulary.
- `guides/install.md` — Package and artifact boundary guidance.
- `guides/compatibility.md` — Runtime-line and artifact compatibility truth.
- `script/verify_phase5_example_hosts.sh` — Existing example-host proof lane and native-proof flag behavior.
- `script/verify_generated_ios_shell.sh` — iOS generated/checked-in project verification surface.
- `script/verify_generated_android_shell.sh` — Android generated/checked-in project verification surface.
- `test/crosswake/guides/native_evidence_drift_test.exs` — Phase 119 native evidence drift scanner and label proximity checks.

### Troubleshooting, Doctor, And Docs-Contract Patterns

- `guides/route_policy.md` — Route-owner mental model troubleshooting must preserve.
- `guides/web_to_mobile_migration.md` — JTBD route-inventory framing and owner selection language.
- `guides/bridge.md` — Bounded bridge denial vocabulary and non-authority boundaries.
- `guides/offline.md` — Cached read-only versus offline-island boundaries.
- `guides/adoption.md` — Current app-owned offline proof story and replay outcome vocabulary.
- `lib/crosswake/doctor/doctor.ex` — Doctor findings and shell/bridge/offline/native diagnostic surfaces.
- `lib/crosswake/doctor/formatter.ex` — Human-facing doctor output shape to keep troubleshooting examples aligned.
- `lib/crosswake/doctor/json_formatter.ex` — JSON diagnostic shape useful for exact finding examples.
- `test/crosswake/doctor/doctor_test.exs` — Canonical doctor finding, denial, route-unavailable, and offline state expectations.
- `test/crosswake/guides/release_boundaries_test.exs` — Docs-contract scanner pattern with source-derived facts and synthetic stale regressions.
- `test/crosswake/guides/quick_start_adoption_drift_test.exs` — Quick-start/adoption docs scanner pattern.
- `test/crosswake/guides/native_evidence_drift_test.exs` — Native evidence docs/source scanner pattern.
- `test/crosswake/support_matrix/renderer_test.exs` — Generated support-matrix parity pattern.
- `test/crosswake/support_matrix/support_matrix_test.exs` — Support label and promotion-rule truth tests.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `examples/phoenix_host/e2e/offline_sync.spec.ts`: Already proves the high-value offline path through real UI, IndexedDB observation, reconnect event, `/study/sync`, Ecto row assertion, outbox deletion, and duplicate idempotency. Phase 120 should reuse/extract this behavior rather than dilute it.
- `examples/phoenix_host/playwright.config.ts`: Existing Playwright harness is already deterministic enough for route-tour expansion: `MIX_ENV=test` server, port `4002`, one worker, CI retries, service workers blocked, and HTML reporter.
- `examples/phoenix_host/lib/crosswake_example/router.ex`: Provides stable route-owner examples spanning Phoenix-owned LiveView, bounded bridge, offline island, native screen, route-unavailable, SaaS auth, commerce, gating, media, and flashcards.
- `guides/support_matrix.md` and `lib/crosswake/support_matrix/renderer.ex`: Canonical support labels should be reused in evidence captions/manifests instead of inventing new label prose.
- `test/crosswake/guides/*_test.exs`: Strong local pattern for docs/source scanners with source-derived facts, synthetic regression cases, and actionable failures.
- `test/crosswake/doctor/doctor_test.exs`: Canonical source for doctor finding/denial examples and expected human/JSON output.

### Established Patterns

- Crosswake treats docs, support matrices, proof lanes, release truth, and drift guards as product surface.
- Required proof should be semantic and deterministic; advisory evidence can be visual/environment-sensitive but must be labeled honestly.
- ExUnit is the idiomatic guard for docs/contracts/source truth; Playwright is the right tool for browser route behavior and visual collateral.
- Native proof labels must keep proof class, coordinate mode, execution environment, and action status separate.
- The README is a map, not the whole manual; deeper docs carry route-owner explanations and troubleshooting details.

### Integration Points

- Phase 120 likely touches `examples/phoenix_host/e2e/`, `examples/phoenix_host/playwright.config.ts`, `.github/workflows/offline-sync-e2e-gate.yml` or a sibling workflow, a new evidence manifest/schema validator, docs assets if curated screenshots are committed, README/ExDoc guide maps, and a new troubleshooting guide/test.
- Native collateral should connect to checked-in hosts and existing native verification scripts without making their outputs required branch protection.
- Troubleshooting should connect doctor findings, support-matrix labels, route-policy guide language, bridge/offline/native shell docs, and quick-start proof commands.

</code_context>

<specifics>
## Specific Ideas

- Subagent-backed browser recommendation: split route-tour correctness from collateral capture; use semantic Playwright assertions for `/library`, `/bridge-proof`, `/offline`, and a native-screen/route-unavailable fixture.
- Subagent-backed artifact recommendation: use one run-level manifest with route entries, CI-only rich artifacts, and only a curated committed screenshot set when durable docs need it.
- Subagent-backed native recommendation: keep browser route-tour merge-blocking; make native simulator/emulator capture best-effort advisory with manifest rows for success, skip, and unavailable states.
- Subagent-backed troubleshooting recommendation: route-owner-first guide with a symptom index and compact "what you see / owner / run this / change this / what this does not prove" entries.
- Cross-ecosystem lessons applied:
  - Playwright favors semantic assertions and test artifacts; visual comparisons are environment-sensitive and should not be the only correctness proof.
  - Phoenix/Elixir ecosystems favor explicit Mix/ExUnit contracts, source-derived facts, and clear failing messages over opaque shell-only checks.
  - Hotwire Native keeps path configuration, bridge components, and native screens explicit; Crosswake should mirror that clarity in route-tour evidence and troubleshooting.
  - Capacitor/Expo/Maestro show that native CI artifacts are useful but platform-sensitive; keep mobile capture advisory until a later promotion decision.
  - Django/Rails/Expo docs show the value of a human-oriented troubleshooting guide with a fast symptom index and deeper conceptual organization.
- JTBD lens:
  - Skeptical adopter: wants to see Crosswake run, understand exactly what was proven, and avoid hidden native/offline overclaims.
  - Maintainer: wants route-tour failures and artifact packaging failures that are easy to debug.
  - Contributor/reviewer: wants manifest/caption labels that separate proof class, coordinate mode, runtime owner, and known limitations.
- UI/UX/design lens:
  - The evidence UI is captions, screenshots, manifests, CI summaries, and troubleshooting docs. It should be consistent, accessible, actual-state-first, and brand-aligned.
  - Use conventional docs affordances: tables for support labels, short captions for artifacts, route-owner headings, error-code indexes, and command blocks for recovery steps.
  - Do not expose support renderer internals, CI plumbing, or backend implementation details unless the user needs them to act.

Research sources referenced by subagents included official Playwright assertions/CI/reporter/trace/snapshot docs, GitHub Actions artifact and runner docs, Capacitor CI/troubleshooting docs, Expo debugging/runtime docs, Maestro artifacts docs, Hotwire Native bridge/path docs, Django docs organization, and Rails error reporting guidance.

</specifics>

<deferred>
## Deferred Ideas

- Managed mobile test services, self-hosted native runners, and recurring native screenshot/video automation beyond best-effort advisory evidence remain future work.
- Physical-device support, camera support, media-upload support, provider authority, app-store readiness, and required simulator/emulator branch protection remain out of Phase 120.
- DASH-01 and NTV-01 remain deferred unless future adopter-evidence work proves they are necessary.
- A machine-generated diagnostic reference can be added later if the human route-owner troubleshooting guide proves insufficient; Phase 120 should not start with internal-reference-first docs.

</deferred>

---

*Phase: 120-Collateral, Artifact CI, And Troubleshooting*
*Context gathered: 2026-06-19T22:10:00Z*
