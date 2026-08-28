# Phase 152: Capability Map, Collateral, and v20 Handoff - Context

**Gathered:** 2026-07-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 152 is a v19 closeout and v20 handoff phase. It converts the three v19 showcase lanes into durable capability truth, proof/collateral surfaces, and a decision-ready v20 Native Controls Pack 1 brief.

This phase should not implement new native controls, production commerce providers, true field-service offline mutation, native storage productization, a generic plugin catalog, or a new operator dashboard. Its job is to make support posture, evidence posture, package ownership, and v20 scope obvious and hard to overclaim.

</domain>

<decisions>
## Implementation Decisions

### Capability Map Shape
- **D-01:** Build a narrow, typed v19 capability-map projection as the recommended source of truth. It should sit next to the existing support-truth system, likely as `Crosswake.CapabilityMap` or an equivalent module, rather than living only as prose.
- **D-02:** The projection should classify each capability as `shipped`, `demoed`, `missing`, `deferred`, or `next-pack candidate`, using phase-appropriate display labels that match the existing showcase vocabulary: `Available today`, `Proof-backed example`, `Demo pressure`, `Advisory evidence`, `Future gap`, and `Next-pack candidate`.
- **D-03:** Each row should carry capability/surface, route/evidence source, current category, route runtime owner, package owner, proof posture, denial/fallback behavior, and v20 implication.
- **D-04:** Package ownership should stay explicit and conservative. Recommended ownership classes: `core`, `native shell`, `first-party companion`, `example/docs-only`, and `deferred`.
- **D-05:** Proof posture should use the existing product language where possible: `merge-blocking`, `advisory`, `not-yet-proven`, and `unsupported`. Screenshots are not a proof posture.
- **D-06:** Render an adopter-readable guide from the projection, likely `guides/capability_map.md`. The guide should answer: what is supported today, what has example proof, what is demo pressure, what is deferred, and what v20 intends to pick up.
- **D-07:** Avoid a dashboard, generic plugin registry, or generated-docs system in this phase. A small Mix task or renderer is acceptable only if it reduces drift and keeps the canonical data small.

### v20 Native Controls Pack 1
- **D-08:** v20 Pack 1 should be bounded, low-frequency, route-local native controls. Recommended primary candidates: alert/confirm, menu or action-button affordances, haptics, share, and toast/review prompt if support truth and policy checks are explicit.
- **D-09:** `permissions.status` and `notification_token` may be included only as read-only/provider-snapshot/evidence surfaces. They must not imply permission-request sprawl, token delivery truth, backend registration truth, APNs/FCM delivery support, or universal notification handling.
- **D-10:** Defer camera, scanner, document scan, media upload, native storage, offline sync helpers, and commerce provider integration to named later packs with promotion criteria.
- **D-11:** Recommended later pack names: Capture & Device Controls, Commerce/Paywall Productionization, Offline Sync/Native Storage Productization, and Operator Dashboard. These should be handoff items, not Phase 152 build work.
- **D-12:** Commerce/paywall production provider work remains future scope. Backend entitlement projection is the authority; device or storefront evidence must not be rendered as subscriber truth.
- **D-13:** The v20 brief should be planning-only and decision-ready, likely `.planning/phases/152-capability-map-collateral-and-v20-handoff/152-V20-HANDOFF.md`, with links from public docs where useful. It should not reopen the whole strategic arc.

### Proof And Collateral
- **D-14:** Keep route-tour proof semantic-first. Playwright assertions and route-tour evidence establish behavior; screenshots are collateral captured after those assertions pass.
- **D-15:** Generalize `examples/phoenix_host/e2e/support/evidence_manifest.ts` beyond Fieldserv so it covers the showcase hub, AdminPilot, Fieldserv, LearnLoop, bridge behavior, offline study behavior, native fallback, and capability pressure entries.
- **D-16:** Evidence manifest rows should include known limitations and retention labels. They should distinguish product-surface proof, advisory evidence, demo pressure, future gap, and next-pack candidate posture.
- **D-17:** Public docs should add a light capability-map entry point from `README.md` and `examples/phoenix_host/README.md`, without turning either README into a full support database.
- **D-18:** Optional screenshot/collateral bundles are acceptable only if their labels are honest and guard-tested. Good labels: `Web proof`, `Advisory evidence`, `Demo pressure`, `Future gap`, and `Next-pack candidate`.
- **D-19:** Fixture reset proof must remain explicit. Server reset does not clear browser-owned IndexedDB, local outboxes, or other browser state; route-tour/browser helpers own browser-state reset.

### Support-Truth Guardrails
- **D-20:** Use canonical typed support/capability data with renderer and drift tests as the default guardrail level. Add a narrow forbidden-claim scanner as a second layer.
- **D-21:** Merge-block canonical label allowlists, catalog/support-matrix/capability-map parity, evidence-manifest schema validity, and docs/support-matrix render parity.
- **D-22:** Merge-block `example/docs-only`, `deferred`, or advisory capability rows if they render as broad `supported` claims without explicit future/deferred/demo posture.
- **D-23:** Merge-block screenshot metadata or docs that present screenshots as correctness proof. Screenshots can show product surface; they cannot certify native/device/provider behavior.
- **D-24:** Merge-block broad native/plugin support claims, device/emulator/JVM evidence laundering, `works offline` or local-first copy without journal/outbox/reconciliation proof, live StoreKit/Play Billing/RevenueCat support claims, and purchase/subscriber/unlock claims before backend-granted projection.
- **D-25:** Keep visual screenshot quality, emulator/device freshness, live provider freshness, and prose style warnings advisory unless they affect support truth.

### UI, UX, And Brand Surface
- **D-26:** The capability guide and collateral should be reader-first. Start with `what works today`, `what evidence exists`, and `what v20 will do`; keep backend mechanics behind deeper sections unless support truth requires them.
- **D-27:** Use the current `brandbook/BRAND-SPEC.md` as brand authority when prompt-era brand guidance conflicts. Favor calm technical presentation, route cards, runtime badges, capability chips, text labels in addition to color, visible focus, light/dark/system support, and WCAG AA contrast.
- **D-28:** Microcopy should be status-oriented and specific. Preferred phrasing includes `Demo pressure`, `Future gap`, `Backend projection required`, `The host app owns this native screen`, and `Screenshots are collateral after route-tour assertions`.
- **D-29:** Avoid copy such as `magic bridge`, `everything works offline`, `native mobile with no native work`, `generic plugin support`, or any wording that hides runtime ownership.

### Ecosystem Lessons Applied
- **D-30:** Follow Phoenix idiom by putting support and capability truth behind explicit Elixir module APIs with ExUnit coverage, similar to existing context-boundary practice, instead of scattering truth through markdown tables.
- **D-31:** Learn from Hotwire Native: route/path configuration, web-first screens, and bridge/native components work when boundaries are explicit. The footgun is letting bridge components become a broad plugin surface.
- **D-32:** Learn from Capacitor, Expo config plugins, and Flutter platform channels: native capability support needs permission, platform, version, and failure-mode truth. The footgun is advertising capability presence without install/config/runtime support details.
- **D-33:** Learn from Android offline-first architecture: true offline behavior starts in the data layer with local sources, write queues, conflict/retry behavior, and reconciliation. Cached read-only pages are not local-first mutation.
- **D-34:** Learn from Apple and Google billing guidance: backend verification/projection is the stable entitlement authority. Native purchase events are evidence, not product authorization truth.

### Claude's Discretion
The user asked for a one-shot, cohesive recommendation set across all gray areas. Downstream agents should treat the decisions above as the recommended path unless implementation discovery finds a concrete contradiction in the codebase.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning And Phase Scope
- `.planning/PROJECT.md` - project thesis, v19/v20 direction, constraints, non-goals, and current decisions.
- `.planning/REQUIREMENTS.md` - CAPMAP and PROOF requirements plus v1/v2 scope boundaries.
- `.planning/ROADMAP.md` - Phase 152 goal, success criteria, and phase sequencing.
- `.planning/STATE.md` - current project state and deferred items.
- `.planning/phases/149-saas-admin-showcase/149-CONTEXT.md` - AdminPilot lane decisions and proof posture.
- `.planning/phases/150-field-service-showcase/150-CONTEXT.md` - Fieldserv native-control pressure, capture, scanner, permission, and offline boundaries.
- `.planning/phases/151-subscription-learning-showcase/151-CONTEXT.md` - LearnLoop learning/paywall/offline-island decisions.
- `.planning/phases/149-saas-admin-showcase/149-VERIFICATION.md` - AdminPilot verification evidence and limits.
- `.planning/phases/151-subscription-learning-showcase/151-VERIFICATION.md` - LearnLoop verification evidence and limits.

### Public Docs And Brand
- `README.md` - public project positioning and guide entry points.
- `guides/capabilities.md` - current capability ladder and support framing.
- `guides/support_matrix.md` - rendered support matrix and current support truth.
- `guides/route_policy.md` - route ownership and runtime policy framing.
- `guides/offline.md` - offline support boundaries and vocabulary.
- `guides/native_shell.md` - native shell posture and supported shell responsibilities.
- `guides/bridge.md` - bridge contract shape and low-frequency semantic boundary.
- `guides/commerce.md` - commerce/paywall authority and backend projection boundaries.
- `guides/compatibility.md` - compatibility and support-matrix expectations.
- `examples/phoenix_host/README.md` - example app route-tour and showcase usage.
- `brandbook/BRAND-SPEC.md` - current brand, UI, accessibility, and microcopy authority.
- `brandbook/collateral/README.md` - collateral expectations and proof/collateral separation.
- `brandbook/collateral/see-it-run/README.md` - current see-it-run collateral workflow.

### Existing Code And Tests
- `lib/crosswake/support_matrix/support_matrix.ex` - canonical support truth, statuses, proof classes, package surfaces, release boundaries, and validation.
- `lib/crosswake/support_matrix/renderer.ex` - support-matrix renderer and generated-guide path.
- `lib/crosswake/manifest/builder.ex` - manifest builder and private capability catalog source.
- `lib/crosswake/manifest/validator.ex` - support matrix validation inside manifest validation.
- `examples/phoenix_host/lib/crosswake_example/showcase/catalog.ex` - showcase cards, support labels, runtime labels, and v20 pressure descriptions.
- `examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs` - current catalog label and route assertions.
- `examples/phoenix_host/lib/crosswake_example/showcase/reset.ex` - deterministic fixture reset behavior and browser-state boundary.
- `examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs` - reset proof and fixture expectations.
- `examples/phoenix_host/e2e/route_tour.spec.ts` - route-tour semantic proof across showcase lanes.
- `examples/phoenix_host/e2e/learnloop_route_tour.spec.ts` - LearnLoop route tour and offline-island proof path.
- `examples/phoenix_host/e2e/support/offline_route_proof.ts` - offline route proof helper and browser/local-state proof vocabulary.
- `examples/phoenix_host/e2e/support/evidence_manifest.ts` - current evidence manifest, posture vocabulary, and Fieldserv-heavy proof entries to generalize.
- `test/crosswake/support_matrix/support_matrix_test.exs` - support-truth invariants and validation tests.
- `test/crosswake/support_matrix/renderer_test.exs` - support guide render parity.
- `test/crosswake/proof/phase64_runtime_line_policy_test.exs` - runtime line policy, proof-class, and evidence laundering guardrails.
- `test/crosswake/proof/phase69_docs_contract_parity_test.exs` - docs contract parity pattern.
- `test/crosswake/guides/collateral_table_test.exs` - collateral table proof pattern.
- `test/crosswake/guides/see_it_run_collateral_test.exs` - see-it-run collateral guard pattern.
- `script/collateral-guard.sh` - collateral guard script.
- `script/check-collateral-size.sh` - collateral size guard.

### Prompt Research Corpus
- `prompts/crosswake-research-synthesis.md` - synthesized Crosswake direction and ecosystem positioning.
- `prompts/crosswake-elixir-oss-dna.md` - Elixir/Phoenix OSS ergonomics and support-truth expectations.
- `prompts/crosswake-integrations-and-companions.md` - native companion and integration guidance.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` - route/runtime capability ladder stress test.
- `prompts/elixir-mobile-offlinesupport-flashcard-app-stresstest-deep-research.md` - offline-island and learning-flow implications.
- `prompts/elixir-mobile-offlinesupport-stresstest-deep-research.md` - offline support boundaries and fake-offline pitfalls.
- `prompts/elixir-mobile-oss-lib-deep-research.md` - OSS library DX, docs, and verification lessons.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` - refined OSS architecture and package-boundary recommendations.
- `prompts/new elixir oss lib prompt.txt` - original product/library framing and goals.

### External Primary Sources Applied
- `https://phoenix.hexdocs.pm/contexts.html` - Phoenix context boundaries and API-oriented application structure.
- `https://phoenix.hexdocs.pm/Mix.Tasks.Phx.Gen.Context.html` - Phoenix context generator and testable context pattern.
- `https://phoenix.hexdocs.pm/ecto.html` - Phoenix/Ecto data access conventions.
- `https://native.hotwired.dev/` - Hotwire Native web-first shell model.
- `https://native.hotwired.dev/overview/bridge-components` - Hotwire Native bridge component boundaries.
- `https://native.hotwired.dev/reference/path-configuration` - Hotwire Native path configuration and route behavior.
- `https://capacitorjs.com/docs/apis/camera` - native camera permissions/configuration and activity-restore complexity.
- `https://docs.expo.dev/config-plugins/plugins/` - Expo native configuration plugin model.
- `https://docs.flutter.dev/platform-integration/platform-channels` - typed platform channel boundary and failure behavior.
- `https://developer.android.com/topic/architecture/data-layer/offline-first` - offline-first data-layer, queue, and conflict guidance.
- `https://developer.android.com/google/play/billing` - Google Play Billing backend verification guidance.
- `https://developer.apple.com/documentation/appstoreserverapi` - Apple server-side transaction/subscription API and signed data model.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.SupportMatrix`: use as the model for typed support truth, proof classes, package surfaces, release boundaries, validation, and rendered docs.
- `Crosswake.SupportMatrix.Renderer`: use the renderer/test pattern for any generated `guides/capability_map.md` output.
- `Crosswake.Manifest.Builder`: use the existing capability catalog and manifest-builder shape as input or cross-check, but do not depend on private helper shape without making the intended contract explicit.
- `CrosswakeExample.Showcase.Catalog`: use existing support labels and v20 pressure copy as showcase truth to normalize, not duplicate manually.
- `Showcase.Reset`: preserve the server-state/browser-state boundary in capability and proof copy.
- `evidence_manifest.ts`: extend the manifest vocabulary so v19 evidence is cross-lane, not Fieldserv-only.
- Existing docs/proof tests: extend parity-test patterns instead of adding new tooling first.

### Established Patterns
- Support truth is already typed and testable. Phase 152 should extend that pattern rather than create disconnected markdown truth.
- Route ownership is explicit per route. Capability map rows should make runtime ownership visible instead of presenting Crosswake as a universal native renderer.
- Bridge contracts are semantic, typed, versioned, and low-frequency. High-frequency client authority belongs in native screens or offline islands.
- Offline claims must be concrete. Cached read-only behavior, offline-island local work, and local-first mutation are separate support postures.
- Diagnostics, proof lanes, support matrices, collateral, and rough-edge documentation are product surface.

### Integration Points
- New capability-map data should cross-check `guides/support_matrix.md`, `Showcase.Catalog`, `evidence_manifest.ts`, and any rendered capability guide.
- Route-tour proof should run before screenshot/collateral capture in any collateral pipeline.
- README/example README links should lead to the capability map and v20 handoff without widening the public support claim.
- Forbidden-claim scanning should cover docs, catalog copy, evidence metadata, and collateral metadata.

</code_context>

<specifics>
## Specific Ideas

User-requested considerations applied:
- Research all gray areas together, using subagents, local prompt research, official ecosystem docs, and lessons from successful comparable libraries.
- Prefer a one-shot recommendation set that is internally coherent and moves toward Crosswake's Phoenix-first route-policy/runtime-contract vision.
- Optimize for great developer ergonomics, principle of least surprise, support truth, product clarity, and user-friendly docs/collateral.
- Where UI/UX applies, keep the surface job-to-be-done focused: adopters should quickly know what Crosswake supports, what the evidence proves, what the example app demonstrates, and what v20 will intentionally tackle next.
- Use the newer `brandbook/BRAND-SPEC.md` over older prompt-era brand guidance when they conflict.

Recommended Phase 152 deliverables:
- `guides/capability_map.md` rendered from or checked against typed capability data.
- `.planning/phases/152-capability-map-collateral-and-v20-handoff/152-V20-HANDOFF.md` with bounded v20 Pack 1 scope and named later packs.
- Generalized v19 evidence manifest and route-tour coverage for AdminPilot, Fieldserv, LearnLoop, bridge, offline, and fallback lanes.
- README and example README entry points into the capability map.
- Merge-blocking parity/forbidden-claim tests for support truth and overclaim prevention.

</specifics>

<deferred>
## Deferred Ideas

- Native capture/scanner/document-scan/media-upload production pack: defer to Capture & Device Controls.
- Production commerce providers, StoreKit/Play Billing/RevenueCat adapter support, and subscription entitlement automation: defer to Commerce/Paywall Productionization.
- Native storage productization, reusable sync helpers, and true local-first mutation beyond the LearnLoop offline island proof: defer to Offline Sync/Native Storage Productization.
- Crosswake operator dashboard or support-truth UI: defer until support truth becomes too large for docs plus typed projection.
- Broad native plugin ecosystem or Capacitor-style plugin catalog: defer indefinitely unless it can preserve explicit route ownership and proof posture.

</deferred>

---

*Phase: 152-Capability Map, Collateral, and v20 Handoff*
*Context gathered: 2026-07-12*
