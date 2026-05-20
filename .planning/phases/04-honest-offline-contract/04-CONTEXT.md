# Phase 4: Honest Offline Contract - Context

**Gathered:** 2026-05-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 4 proves one credible local-first route class without collapsing Crosswake into a generic sync framework or a fake offline WebView story. This phase must separately prove cached read-only behavior for a LiveView-backed route, one real offline island with durable local mutation and replay, explicit reconciliation back to Phoenix truth, and inspectable failure visibility for adopters and operators.

It does not broaden into pack lifecycle breadth, media-heavy transfer workflows, capability-heavy field apps, mounted diagnostics dashboards, or generic collaboration/sync abstractions. Those remain later-phase work.

</domain>

<decisions>
## Implementation Decisions

### Reference workflow and proof shape
- **D-01:** Phase 4 should use a study/session review loop as the single named offline-island exemplar.
- **D-02:** The exemplar should pair an offline-owned study/session route with a neighboring LiveView-backed cached read-only lesson or library route so Crosswake visibly proves the difference between degraded reads and true local-first mutation.
- **D-03:** Phase 4 should not center on inspection forms, task queues, or media upload flows because they either under-prove the offline contract or prematurely pull in Phase 5 native/media scope.
- **D-04:** The offline island should stay focused on semantic review/session actions with low bridge chatter, not on capability-heavy native behavior.

### Public offline contract shape
- **D-05:** Keep `runtime` as the ownership axis and keep `offline` as the coarse public summary class.
- **D-06:** Do not rely on `offline: :local_first` as a docs-only promise. Phase 4 should add separate named offline subcontracts for the concrete mechanism behind cached routes and offline islands.
- **D-07:** Cached read-only routes and mutating offline islands must not share one indistinct contract surface.
- **D-08:** The route DSL should stay small and Phoenix-native: simple top-level route options, with richer cache/island behavior referenced through named contracts rather than a giant offline enum.
- **D-09:** Exact public field names for the new subcontracts are flexible during planning, but the direction is locked: additive typed cache and island contracts, not inferred behavior from `sync`, `packs`, or rule ordering.

### Mutation, journal, and reconciliation model
- **D-10:** Phase 4 should use a hybrid local-first model: local draft state for in-progress UI plus an append-only mutation journal/outbox for committed offline actions.
- **D-11:** Phoenix and Ecto remain server-authoritative. Offline islands may project local optimistic state, but canonical server truth is reconciled explicitly on replay.
- **D-12:** Committed offline actions should be represented as immutable journal entries with explicit identity and replay metadata such as client mutation id, idempotency key, sync seam, resource identity, operation, payload, base version or checkpoint, timestamps, and status.
- **D-13:** Replay should return explicit accepted, rejected, or conflict outcomes plus updated authoritative state or checkpoint information. Crosswake should not use silent last-write-wins as the default contract.
- **D-14:** Direct local mutation of canonical rows is out. It hides pending/conflict truth, weakens auditability, and pushes Crosswake toward magical sync behavior.
- **D-15:** Phase 4 should prove one narrow replay and reconciliation seam, not a generic collaborative sync platform.

### Local storage and platform posture
- **D-16:** Offline island durability should be designed around SQLite-backed native stores on iOS and Android, not browser storage as the primary truth substrate.
- **D-17:** Background replay posture must stay honest: persistence, retry hooks, and eventual replay are part of the contract; immediate or guaranteed background sync timing is not.
- **D-18:** Phase 4 may define contract seams that future pack work will use, but it should not require full pack lifecycle breadth to validate the exemplar.

### Failure visibility and product surfaces
- **D-19:** Phase 4 should ship a balanced minimum slice of user-facing route-local truth plus structured developer/operator diagnostics.
- **D-20:** User-facing offline states must be explicit and route-local, not a generic app-wide “offline” badge. At minimum, distinguish cached read-only/stale, saved locally draft state, queued for replay, replay failure, and conflict-required resolution.
- **D-21:** Conflicts and data-loss-risk states may interrupt the user; stale reads and queued replay should stay inline or lightly interrupting by default.
- **D-22:** Developer-facing support should extend the existing `mix crosswake.doctor` and JSON report posture with offline checks, rough-edge truth, and machine-readable findings rather than introducing a mounted diagnostics UI in Phase 4.
- **D-23:** Operator support should come from stable structured telemetry and logs keyed by route id, runtime, offline mode, sync seam, journal entry id, manifest/runtime versions, correlation id, and terminal outcome.
- **D-24:** Telemetry should favor state transitions and terminal outcomes over noisy low-level event streams.

### Product honesty and scope guardrails
- **D-25:** Crosswake should make an explicit product distinction between cached read-only degradation and true local-first mutation. “Offline” must never mean both without qualification.
- **D-26:** The bridge must not become a high-frequency state bus for the offline island. Local interaction and queueing belong inside the island runtime and local store.
- **D-27:** Phase 4 support claims should stay narrow and proof-oriented. The contract is “one honest local-first workflow with explicit replay and reconciliation,” not “Crosswake generically solves offline sync.”
- **D-28:** Mounted Phoenix diagnostics UI, inspection/media-heavy offline workflows, broad offline taxonomies, and generic sync-framework APIs are deferred.

### Decision delegation posture
- **D-29:** Shift normal implementation choices left within GSD. Researcher, planner, and implementer agents should make principled decisions without re-asking unless a choice would materially change the public route contract, offline taxonomy, reconciliation semantics, support claims, or user-visible offline vocabulary.

### the agent's Discretion
- Exact names for the typed cache-contract and island-contract fields, modules, and manifest sections.
- Exact local projection structure, as long as the append-only replay contract and server-authoritative reconciliation posture stay intact.
- Exact telemetry event names and doctor report layout, as long as the metadata shape and offline vocabulary stay stable.
- Exact UX copy, visual treatment, and severity mapping for offline states, as long as cached, queued, failed, and conflict states remain visibly distinct.

</decisions>

<specifics>
## Specific Ideas

- The strongest Phase 4 shape is: LiveView for surrounding lesson/library surfaces, offline island for the active study/session loop, Phoenix/Ecto for authoritative reconciliation.
- Hotwire Native is a useful positive reference for explicit runtime boundaries and bounded native seams, but Crosswake should stay route-first rather than adopting rule-order configuration semantics.
- Android’s offline-first guidance is the right mental model for the island: local data source as the read truth, explicit queued writes, explicit replay, and explicit conflict handling.
- Oban-style idempotency and Phoenix/Ecto optimistic-locking posture are good server-side reference patterns for replay and conflict handling.
- User trust should come from precise vocabulary. “Cached read-only,” “saved locally,” “queued for sync,” “sync failed,” and “conflict requires attention” are better product states than a generic “offline.”
- The public DSL should likely evolve toward a shape like `runtime + offline + named cache/island contract`, but the exact field names should be finalized in planning.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Core planning context
- `.planning/PROJECT.md` — project thesis, constraints, non-goals, and OSS posture
- `.planning/REQUIREMENTS.md` — Phase 4 requirement mapping and v1 scope boundaries
- `.planning/ROADMAP.md` — Phase 4 goal and success criteria
- `.planning/STATE.md` — current project position and explicit warning that Phase 4 needs one named offline-island reference workflow

### Prior phase decisions
- `.planning/phases/01-route-policy-foundation/01-CONTEXT.md` — locked route DSL, runtime taxonomy, and host-owned contract posture
- `.planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md` — locked manifest, compatibility, fail-closed, and support-truth posture
- `.planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md` — locked shell, bridge, denial, and diagnostics decisions that Phase 4 must build on

### Stable project research
- `.planning/research/SUMMARY.md` — overall architecture and roadmap rationale
- `.planning/research/ARCHITECTURE.md` — offline island, journal, sync engine, and pack-store system shape
- `.planning/research/STACK.md` — SQLite-backed native store posture, Telemetry, and platform stack guidance
- `.planning/research/FEATURES.md` — explicit offline policy expectations and differentiator framing
- `.planning/research/PITFALLS.md` — fake-offline and support-honesty pitfalls to avoid

### Prompt lineage and offline product guidance
- `prompts/crosswake-gsd-project-brief.md` — authoritative product brief and route/runtime positioning
- `prompts/crosswake-research-synthesis.md` — synthesized project direction and architectural guardrails
- `prompts/crosswake-brand-book.md` — terminology and anti-drift messaging constraints
- `prompts/crosswake-elixir-oss-dna.md` — install truth, proof-lane expectations, and support posture
- `prompts/elixir-mobile-offlinesupport-stresstest-deep-research.md` — offline policy distinctions, cautions, and route-boundary lessons
- `prompts/elixir-mobile-offlinesupport-flashcard-app-stresstest-deep-research.md` — concrete study-loop offline-island guidance, journal shape, and reconciliation footguns
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` — runtime classification and app archetype lessons that support the chosen exemplar

### Current implementation anchors
- `lib/crosswake/policy/schema.ex` — current route-policy offline taxonomy and validation surface
- `lib/crosswake/policy/route.ex` — normalized route contract that Phase 4 will extend
- `lib/crosswake/manifest/types.ex` — current typed manifest contract that should gain explicit offline subcontracts
- `lib/crosswake/manifest/builder.ex` — route-entry manifest assembly point for Phase 4 additions
- `lib/crosswake/doctor/doctor.ex` — existing doctor surface to extend for offline truth
- `lib/crosswake/doctor/check.ex` — structured finding model to reuse for offline diagnostics
- `lib/crosswake/doctor/formatter.ex` — human-readable diagnostics baseline
- `lib/crosswake/doctor/json_formatter.ex` — machine-readable diagnostics baseline
- `guides/native_shell.md` — shell contract and support boundary that offline work must preserve
- `guides/compatibility.md` — compatibility and fail-closed posture that offline work must extend
- `test/support/router_fixtures.ex` — current managed-route examples already carrying cached-read-only and local-first policy hints

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Policy.Schema` — already defines `:cached_read_only` and `:local_first`, giving Phase 4 an additive extension point rather than a blank slate.
- `Crosswake.Policy.Route` — normalized route struct that can grow explicit cache/island contract references.
- `Crosswake.Manifest.Types` — central manifest type layer where offline subcontracts can be added without abandoning the existing route-first contract.
- `Crosswake.Manifest.Builder` — current route-entry assembly point that can compile new offline contract data from route policy into manifest truth.
- `Crosswake.Doctor` plus formatter modules — existing product surface for structured findings and support truth, suitable for offline diagnostics expansion.
- `Crosswake.TestSupport.RouterFixtures` — already includes representative `:cached_read_only` and `:offline_island` examples that Phase 4 can sharpen into explicit contracts.

### Established Patterns
- Route-local policy remains the authoritative Phoenix-side source of truth.
- Crosswake prefers small typed option surfaces validated early, then compiled into machine-readable contracts.
- Support claims, diagnostics, and rough-edge truth are product surface rather than cleanup work.
- Compatibility, runtime activation, and bridge execution are fail closed and route specific.

### Integration Points
- Phase 4 should extend route policy and manifest compilation rather than inventing a separate offline configuration system.
- Offline diagnostics should integrate into existing doctor and JSON formatter flows.
- Offline vocabulary and telemetry should align with the current shell denial and support-posture guidance rather than creating a disconnected ops layer.
- The chosen study/session exemplar should connect future pack and native-escape work without requiring Phase 5 breadth now.

</code_context>

<deferred>
## Deferred Ideas

- Inspection-form exemplars with camera, location, signature, or attachment pressure — defer to later phase or a narrower future proof lane.
- Media capture/upload queues and other transfer-heavy offline workflows — Phase 5 scope.
- Mounted Phoenix diagnostics UI or dashboard for offline introspection — later product surface after the event schema and multiple offline flows are proven.
- Broad offline enum expansion that tries to encode every offline mode directly in one field — defer unless a later phase proves it is necessary.
- Generic sync-framework APIs, collaborative editing semantics, CRDT-style ambitions, and implicit last-write-wins merge behavior — explicitly out of Phase 4 scope.

</deferred>

---

*Phase: 04-honest-offline-contract*
*Context gathered: 2026-05-16*
