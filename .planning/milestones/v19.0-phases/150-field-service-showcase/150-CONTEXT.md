# Phase 150: Field-Service Showcase - Context

**Gathered:** 2026-07-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 150 builds the Fieldserv field-service lane as a polished, click-around device-pressure showcase. It should feel like a realistic dispatch, inspection, and evidence workflow first, while making Crosswake route ownership, capture/scanning pressure, media/evidence authority, cached/degraded behavior, and future native-control gaps visible and honest.

This phase does not implement production camera, scanner, document-scan, location, signature, or permission APIs. It does not add a true local-first field inspection island unless a real route-local journal/outbox/reconciliation path is implemented in the phase. It does not create a generic field-service CRUD app, a generic sync engine, a generic permission dashboard, or a broad native-control catalog. Those remain future capability-map, v20 native-controls, capture/device, or offline-sync/native-storage work.

</domain>

<decisions>
## Implementation Decisions

### Primary Fieldserv Workflow
- **D-01:** Make Fieldserv a product-first field-service lane, not a renamed `/native/claims` proof route and not a diagnostics-first matrix. The first impression should be dispatch/inspection/evidence work under jobsite pressure.
- **D-02:** Use the representative click path `jobs list -> job detail -> inspection workspace -> capture handoff -> evidence review`. Recommended route shape: `/fieldserv/jobs`, `/fieldserv/jobs/:id`, `/fieldserv/jobs/:id/inspection`, `/fieldserv/jobs/:id/capture`, and `/fieldserv/jobs/:id/evidence/:evidence_id/review`.
- **D-03:** Reuse or wrap the existing `SelectiveNative` claim/capture code where it saves scope, but hide implementation-first `/native` naming from the primary Fieldserv UX. Legacy `/native/claims` routes may remain reachable as proof routes.
- **D-04:** FIELD-01 breadth should come from realistic, scan-friendly records: jobs, assets, inspection steps, notes, media/evidence records, technician state, dispatcher/adjuster context, and route/support posture.
- **D-05:** Recommended domain nouns: `job`, `claim`, `asset`, `inspection`, `checklist_item`, `technician`, `dispatcher`, `adjuster`, `evidence_item`, `upload_grant`, `capture_evidence`, `media_object`, `permission_rationale`, `route_posture`, and `support_finding`.
- **D-06:** Recommended domain events: `job_assigned`, `inspection_started`, `inspection_step_completed`, `note_recorded_online`, `capture_intent_requested`, `scanner_unavailable`, `device_evidence_recorded`, `upload_prepare_requested`, `backend_verification_started`, `backend_verified_available`, `backend_rejected`, and `offline_degraded_detected`.
- **D-07:** Keep the Fieldserv lane focused on one representative workflow. Do not turn it into broad scheduling, routing, maps, background location, inventory, or technician workforce management.

### Field Data and Persistence
- **D-08:** Use the same proven pattern as Phase 149: deterministic fixture/read-context breadth plus narrow persisted workflow/evidence state. Broad domain depth can be static; only representative workflow evidence needs refresh-proof persistence.
- **D-09:** Prefer a lane-local Phoenix context such as `CrosswakeExample.FieldService` or a carefully renamed/wrapped `SelectiveNative` boundary. LiveViews should load, dispatch events, and render outcomes; business state changes should live in context functions.
- **D-10:** Static fixture/read-context data should cover jobs, assets, technicians, inspection templates/checklist items, notes, route posture rows, support findings, and permission/capability pressure.
- **D-11:** Persist only narrow evidence needed to prove real server-side workflow behavior, such as `inspection_event`, `evidence_event`, or `technician_job_state`. Avoid full Ecto schemas for every job, asset, route stop, and inspection template unless the planner finds an existing low-cost path.
- **D-12:** Use Ecto changesets and `Ecto.Multi` where an action changes multiple persisted facts, such as recording evidence plus advancing job/evidence status. The persisted state remains server-authoritative; it is not an offline journal.
- **D-13:** Reset must remain deterministic. `Showcase.Reset.reset!/0` should delegate to Fieldserv-owned reset helpers, delete/reseed persisted evidence state idempotently, include stable counts/digest components, and continue to report `browser_state_reset: false`.
- **D-14:** Do not introduce a true offline journal/outbox in Phase 150 unless the implementation also includes route-local local storage, idempotent replay, rejection/conflict states, browser/device reset proof, and route-tour verification.

### Capture, Scanning, Media, and Permission Truth
- **D-15:** Keep capture as an explicit `:native_screen` route. Native code owns the capture session loop, permission choreography, and platform-sensitive UI. Crosswake should not silently degrade native capture into a web upload flow.
- **D-16:** The existing `/native/claims/:id/capture` metadata is the right contract shape to preserve or mirror: `runtime: :native_screen`, `capabilities: [:camera]`, a media pack, `transfer.upload.prepare`, `source: :native_capture`, `verification: :required`, `offline: :cached_read_only`, and `security: :sensitive`.
- **D-17:** Fieldserv may show capture/scanning intent and disabled or unavailable states, but it must not add production camera, scanner, document-scan, or location APIs in this phase.
- **D-18:** Do not add camera/scanner bridge commands. Camera capture, scanner, and document scan remain native-screen or deferred capability families, not bounded bridge request/reply commands.
- **D-19:** Reuse the media proof lesson in Fieldserv copy and state: local/device capture evidence does not make media available; backend verification owns availability. Good statuses include `Device evidence recorded`, `Backend verification pending`, `Backend verified`, and `Backend rejected`.
- **D-20:** Scanner and document scan should be visible as future native-control pressure, not runnable support. Recommended labels: `Future gap`, `Next-pack candidate`, `Requires native runtime`, and `Permission needed`.
- **D-21:** Keep permission truth narrow. `permissions.status` currently supports the notifications alias only; do not use it to imply camera, scanner, or location permission support. For Fieldserv, camera permission belongs inside the native capture screen and native host, not a generic LiveView permission dashboard.
- **D-22:** User-facing copy should be short and status-oriented: "Camera capture requires the native app runtime.", "Scanner support is a future native-control candidate.", "Device evidence is pending backend verification.", and "This cached job snapshot cannot be edited offline."

### Offline and Route Ownership
- **D-23:** The coherent Phase 150 default is cached read-only/degraded Fieldserv plus explicit future offline-island pressure. This satisfies FIELD-03 honestly without widening scope into local-first mutation.
- **D-24:** No Fieldserv route should present itself as shipped `local-first`, a shipped `Offline island`, or a working `journal`, `outbox`, `replay`, `saved locally`, or `queued for sync` flow unless a real route-local offline island and sync proof ship in the same phase. Future-candidate copy is allowed only when it is explicit that the capability is not implemented in Phase 150.
- **D-25:** Fieldserv route labels should distinguish current owners: LiveView routes for job lists/details/inspection context, native screen for capture, LiveView/backend for evidence review, and future offline island for inspection drafts if later implemented.
- **D-26:** Inspection can be shown as a future offline-island candidate, but not as a runnable offline CTA. The future row should explain what would be required: local draft storage, journal/outbox, replay outcomes, conflict review, and reconciliation proof.
- **D-27:** Cached read-only means stale/read-only snapshots only. It may show last-updated state, unavailable actions, and degraded notices; it must not imply local mutation.
- **D-28:** The existing LearnLoop offline route is a useful pattern reference for true offline proof, but it must not be reused or relabeled as Fieldserv. If a future Fieldserv offline island exists, it needs its own domain contract and proof.

### UI, UX, and Brand Direction
- **D-29:** Fieldserv should use the locked Phase 148 brand direction: high-visibility dispatch and device pressure with the signal-orange field identity, while remaining clearly inside the Crosswake showcase.
- **D-30:** Build an operational app UI, not a marketing page. Use dense but readable job lists, status strips, route badges, inspection progress, asset/evidence summaries, activity timelines, and clear action affordances.
- **D-31:** Primary personas/JTBD:
  - Dispatcher: see assigned jobs, technician state, and evidence blockers.
  - Technician: inspect a job, review asset context, record notes online, and attempt native capture when available.
  - Adjuster/reviewer: inspect evidence status and see backend verification authority.
- **D-32:** Keep backend implementation details out of the first impression. Users see Fieldserv job language first; Crosswake route-policy terms appear as compact badges, inline support truth, and an optional diagnostics/support panel.
- **D-33:** Use conventional UI components: list/detail layout on desktop, stacked single-column task flow on mobile, status badges with text labels, action footer, timeline/activity rail, checklist rows, and disclosure for diagnostics.
- **D-34:** Mobile must keep essential actions and support truth visible without horizontal overflow. Avoid desktop-table parity if it hurts scanability.
- **D-35:** Accessibility is in scope: visible focus rings, 44px preferred mobile actions, no color-only statuses, readable contrast in light/dark/system themes, reduced-motion-safe interactions, and no badge/action text clipping.
- **D-36:** Microcopy should follow the brandbook: calm, explicit, status-oriented, and honest. Prefer "Requires native runtime", "Cached read-only", "Permission needed", "Pending server confirmation", and "Capability unavailable" over internal denial-code dumps.

### Proof and Verification
- **D-37:** Add focused ExUnit coverage for Fieldserv fixture density, context/state transitions, reset idempotency/digest truth, route metadata drift, support-label allowlists, and no overclaiming of offline/native-control support.
- **D-38:** Extend Playwright route-tour coverage to exercise the Fieldserv happy path: jobs list, job detail, inspection context, native capture unavailable/fallback posture, evidence review, and support/route-owner truth.
- **D-39:** Browser route-tour proof should remain semantic-first: assert route owner, capability/support labels, backend verification copy, and no unsupported offline/local-first claims before screenshots.
- **D-40:** Verify desktop and mobile layouts, light/dark/system themes, reduced motion, focus visibility, no horizontal overflow, and no overlap/clipping in action/status areas.
- **D-41:** Phase 150 should generate capability-map evidence for Phase 152 by making capture, scanner, document scan, permissions, media upload, offline inspection, and native rebuild pressure visible without presenting them as shipped support.

### Claude's Discretion
- The planner may choose exact module names, whether to wrap or rename `SelectiveNative`, whether to add one narrow migration or reuse existing `selective_native_*` tables, and exact Fieldserv copy/layout details.
- The planner may decide whether Fieldserv diagnostics are a lane-local panel, inline route matrix, or reusable component, as long as route/support truth remains mechanically testable and does not become `crosswake_dashboard`.
- The planner may refine exact route paths if existing Phoenix routing constraints make the recommended shape awkward, but the product-first Fieldserv path must remain the primary UX.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and Milestone Scope
- `.planning/PROJECT.md` - Crosswake thesis, current v19 state, constraints, and key decisions.
- `.planning/REQUIREMENTS.md` - Phase 150 requirements FIELD-01..04 and v19 proof/collateral boundaries.
- `.planning/ROADMAP.md` - Phase 150 goal and success criteria.
- `.planning/STATE.md` - Current phase state, locked v19 roadmap decisions, anti-scope reminders, and Phase 149 completion notes.
- `.planning/phases/147-arc-fixture-and-showcase-foundation/147-CONTEXT.md` - Foundation decisions for showcase hub, lane-local data, reset ownership, route/support labels, and first-run discovery.
- `.planning/phases/149-saas-admin-showcase/149-CONTEXT.md` - Proven lane pattern for product-first UI, hybrid fixture/persistence, diagnostics, support truth, and route-tour proof.

### Brand, UI, and UX
- `brandbook/BRAND-SPEC.md` - Current Crosswake brand, Fieldserv-adjacent route-card/status vocabulary, accessibility, color, badge, microcopy, and dark/light rules.
- `examples/phoenix_host/priv/static/css/tokens.css` - Example-host token copy consumed by showcase UI.
- `examples/phoenix_host/priv/static/css/app.css` - Existing shared CSS, showcase cards, badges, buttons, and lane styling to reuse or extend.

### Existing Fieldserv and Native-Pressure Code
- `examples/phoenix_host/lib/crosswake_example/router.ex` - Existing `/native` route metadata, including `selective-native-claim-capture` native-screen contract.
- `examples/phoenix_host/lib/crosswake_example/showcase/branding.ex` - Locked Fieldserv brand and fixture brief.
- `examples/phoenix_host/lib/crosswake_example/showcase/catalog.ex` - Current Field Service card metadata, support labels, and route posture.
- `examples/phoenix_host/lib/crosswake_example/showcase/reset.ex` - Reset orchestrator that already delegates to native-pressure fixtures and preserves `browser_state_reset: false`.
- `examples/phoenix_host/lib/crosswake_example/showcase/fixtures.ex` - Existing lane reset integration pattern.
- `examples/phoenix_host/lib/crosswake_example/selective_native/fixtures.ex` - Current claim/submission seed and digest shape.
- `examples/phoenix_host/lib/crosswake_example/selective_native/claims.ex` - Current claim context functions.
- `examples/phoenix_host/lib/crosswake_example/selective_native/submissions.ex` - Current submission context functions.
- `examples/phoenix_host/lib/crosswake_example/selective_native/claim.ex` - Existing persisted claim schema.
- `examples/phoenix_host/lib/crosswake_example/selective_native/submission.ex` - Existing persisted submission schema.
- `examples/phoenix_host/lib/crosswake_example/selective_native/claims_live.ex` - Current thin claims list route.
- `examples/phoenix_host/lib/crosswake_example/selective_native/claim_live.ex` - Current claim detail route.
- `examples/phoenix_host/lib/crosswake_example/selective_native/claim_capture_live.ex` - Current native capture fallback route.
- `examples/phoenix_host/lib/crosswake_example/selective_native/submission_review_live.ex` - Current evidence review/upload-prep route.
- `examples/phoenix_host/priv/repo/migrations/20260518164505_create_selective_native_claims_and_submissions.exs` - Existing claim/submission persistence.

### Existing Media/Evidence Proof
- `examples/phoenix_host/lib/crosswake_example/media/media_lane_live.ex` - Existing proof that local/device capture evidence is not media availability until backend verification.
- `examples/phoenix_host/lib/crosswake_example/media/mock_capture.ex` - Mock capture evidence/grant helper.
- `examples/phoenix_host/lib/crosswake_example/media/reconciliation_inbox.ex` - Capture evidence ingestion and reconciliation helper.
- `examples/phoenix_host/lib/crosswake_example/media/media_projection.ex` - Media object projection and derived-state helper.
- `examples/phoenix_host/lib/crosswake_example/media/reconciliation_keys.ex` - Reconciliation key helpers.

### Existing Tests and Proof Patterns
- `examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs` - Route metadata drift, support-label allowlist, and compiled router truth pattern.
- `examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs` - Reset idempotency, deterministic digest, and `browser_state_reset: false` proof.
- `examples/phoenix_host/test/crosswake_example/showcase/hub_live_test.exs` - Showcase rendering, lane labels, and Fieldserv fixture preview expectations.
- `examples/phoenix_host/test/crosswake_example/e2e/showcase_reset_controller_test.exs` - Reset endpoint proof pattern.
- `examples/phoenix_host/test/crosswake_example/selective_native/claim_capture_live_test.exs` - Existing capture fallback behavior test.
- `examples/phoenix_host/e2e/route_tour.spec.ts` - Browser route-tour semantic assertions and screenshot collateral pattern.
- `examples/phoenix_host/e2e/support/offline_route_proof.ts` - Existing browser-owned offline reset/proof helper; do not confuse with Fieldserv server reset.

### Crosswake Concept Guides
- `guides/route_policy.md` - Route owner decisions, cached read-only vs offline island, native screen, explicit defer, and field checklist.
- `guides/capabilities.md` - Ownership-first capability rubric, media capture/scanner/document-scan classification, package boundary rules, and fallback behavior.
- `guides/support_matrix.md` - Support-truth labels, proof classes, and capability-family posture.
- `guides/native_shell.md` - Native capture escape hatch, no silent fallback, permission/entitlement templates, and rebuild expectations.
- `guides/bridge.md` - Bounded bridge allowlist, transfer semantics, denial reasons, and bridge non-authority.
- `guides/offline.md` - Cached read-only versus local-first offline behavior. Read before adding any offline wording.
- `guides/compatibility.md` - Native runtime, bridge, manifest, capability version, and rebuild guidance if Fieldserv exposes future native-control pressure.

### Prompt Research to Apply
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` - Field service, capture/media upload, scanner, permission, runtime ladder, and native-screen lessons.
- `prompts/elixir-mobile-oss-lib-deep-research.md` - Phoenix Hotwire-style architecture, offline honesty, media/capture package guidance, and footguns.
- `prompts/elixir-mobile-offlinesupport-flashcard-app-stresstest-deep-research.md` - What true offline islands require; useful pattern reference only, not reusable Fieldserv truth.
- `prompts/crosswake-elixir-oss-dna.md` - Maintainer house style: support honesty, proof lanes, install truth, and operator surfaces.
- `prompts/crosswake-integrations-and-companions.md` - Rindle/media, Threadline/audit, Chimeway/notification, and companion/docs-only classification heuristics.
- `prompts/crosswake-research-synthesis.md` - Current architecture thesis and anti-patterns.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `CrosswakeExample.SelectiveNative.*` already provides claim, submission, capture fallback, and review routes that can be wrapped or refactored into a Fieldserv product lane.
- `CrosswakeExample.Showcase.Branding` already fixes Fieldserv's brand, fixture brief, people, records, activity, and pressure note.
- `CrosswakeExample.Showcase.Catalog` already owns product-facing support/runtime labels and tests them against compiled router metadata.
- `CrosswakeExample.Showcase.Reset` already integrates field-service/native-pressure reset counts and digest truth.
- `CrosswakeExample.Media.*` already models the core evidence authority lesson: local capture/device evidence remains non-authoritative until backend verification.
- `examples/phoenix_host/e2e/route_tour.spec.ts` already includes native-owned route assertions for `selective-native-claim-capture`.
- Brandbook/token CSS and existing AdminPilot patterns provide usable app-shell, status, badge, diagnostics, and responsive layout precedents.

### Established Patterns
- Example-host lanes are proof artifacts and product-shaped demos, not core Crosswake APIs or starter-app frameworks.
- Route metadata/support truth should be mechanically tested against compiled router metadata where possible.
- Static breadth can remain deterministic fixture maps; representative mutable evidence can be persisted narrowly when it proves a workflow.
- Server reset must not claim browser-owned IndexedDB/outbox reset.
- Route-tour screenshots are collateral only after semantic assertions pass.
- Support labels must avoid broad "supported" wording unless support-matrix proof backs the claim.

### Integration Points
- Add or wrap a Fieldserv context/fixture module for jobs, assets, inspections, technicians, evidence, route posture, and support findings.
- Wire new `/fieldserv/*` routes into `router.ex` with explicit Crosswake route metadata and support labels.
- Update `Showcase.Catalog` so the Field Service CTA points to the product-first Fieldserv lane instead of only the native capture proof path.
- Extend `Showcase.Reset` counts/digest for Fieldserv static breadth and narrow persisted event/evidence state.
- Reuse existing `SelectiveNative` persistence or add a narrow migration only for Fieldserv evidence/workflow events.
- Extend route-tour coverage to the Fieldserv happy path and native capture fallback/unavailable state.

</code_context>

<specifics>
## Specific Ideas

- Recommended lane narrative: "Fieldserv keeps dispatch and inspection context Phoenix-owned, then makes device-heavy capture and scanner gaps explicit instead of pretending the WebView owns them."
- Recommended first screen: job queue with technician state, priority/severity, asset type, last update, evidence blocker, and route-owner badges.
- Recommended job detail: asset summary, inspection checklist, site/contact context, notes/activity, evidence timeline, offline/degraded status, and capture CTA.
- Recommended inspection workspace: readable checklist rows and online-only note action, with a clear "Future offline island candidate" callout that explains the missing journal/outbox/replay requirements.
- Recommended capture handoff: native-screen fallback surface that says the host app owns camera capture, shows `:camera` capability and media pack posture, and offers evidence review only as simulated/fixture-backed proof.
- Recommended evidence review: statuses for device evidence, upload preparation, backend verification pending, verified, and rejected. Avoid "uploaded = available" copy.
- Recommended diagnostics/support panel: route id, path, runtime owner, offline posture, security posture, capability/pack/transfer declarations, support label, fallback/denial state, and v20 pressure note.
- External primary-source lessons considered:
  - Phoenix contexts and Ecto changesets support keeping data access, validation, and workflow mutations in contexts rather than LiveView templates.
  - Hotwire Native path configuration/native-screen concepts validate route/path ownership as a mobile-web pattern, but Crosswake should keep Phoenix route policy authoritative.
  - Android and Apple permission guidance reinforces point-of-use permission UX and clear purpose/rationale copy.
  - Android offline-first guidance and Apple/Android background work guidance reinforce that true offline/media upload requires local stores, queues, background/persistent work, synchronization, and conflict/retry states.
  - Capacitor/Expo camera APIs show why camera/scanner capability support quickly becomes native permission, build, runtime, and version surface, not just a web button.

</specifics>

<deferred>
## Deferred Ideas

- Production camera capture, scanner, document scan, signature, foreground/background location, route maps, NFC, and native permission aliases remain future capture/device or v20+ native-control work.
- A true Fieldserv offline inspection island with local drafts, journal/outbox, replay, conflict review, and reconciliation proof remains deferred unless explicitly pulled into a later phase.
- Generic offline sync/native storage productization remains SYNCP-01/future milestone scope.
- Rindle-backed production media capture/upload, background transfer, storage provider integration, and backend verification workflows remain companion/productization work beyond this showcase lane.
- A generic Fieldserv CRUD app, scheduling system, workforce management surface, or maps/routing product is out of scope.
- A generic permission dashboard is out of scope. `permissions.status` remains narrow and must not be broadened by Fieldserv copy.
- `crosswake_dashboard` or a URL-addressable global route inspector remains future DASH-01 or Phase 152+ work.

</deferred>

---

*Phase: 150-Field-Service Showcase*
*Context gathered: 2026-07-11*
