# Phase 150: Field-Service Showcase - Research

**Researched:** 2026-07-11
**Domain:** Phoenix LiveView field-service showcase, native capture pressure, media evidence authority, cached/degraded route truth
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

Provenance for this copied section: [VERIFIED: .planning/phases/150-field-service-showcase/150-CONTEXT.md]

### Locked Decisions

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

### the agent's Discretion

### Claude's Discretion
- The planner may choose exact module names, whether to wrap or rename `SelectiveNative`, whether to add one narrow migration or reuse existing `selective_native_*` tables, and exact Fieldserv copy/layout details.
- The planner may decide whether Fieldserv diagnostics are a lane-local panel, inline route matrix, or reusable component, as long as route/support truth remains mechanically testable and does not become `crosswake_dashboard`.
- The planner may refine exact route paths if existing Phoenix routing constraints make the recommended shape awkward, but the product-first Fieldserv path must remain the primary UX.

### Deferred Ideas (OUT OF SCOPE)

## Deferred Ideas

- Production camera capture, scanner, document scan, signature, foreground/background location, route maps, NFC, and native permission aliases remain future capture/device or v20+ native-control work.
- A true Fieldserv offline inspection island with local drafts, journal/outbox, replay, conflict review, and reconciliation proof remains deferred unless explicitly pulled into a later phase.
- Generic offline sync/native storage productization remains SYNCP-01/future milestone scope.
- Rindle-backed production media capture/upload, background transfer, storage provider integration, and backend verification workflows remain companion/productization work beyond this showcase lane.
- A generic Fieldserv CRUD app, scheduling system, workforce management surface, or maps/routing product is out of scope.
- A generic permission dashboard is out of scope. `permissions.status` remains narrow and must not be broadened by Fieldserv copy.
- `crosswake_dashboard` or a URL-addressable global route inspector remains future DASH-01 or Phase 152+ work.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FIELD-01 | User can click through a field-service domain with realistic jobs, assets, inspections, notes, media/evidence, and technician state. | Plan a product-first `/fieldserv/*` route chain backed by deterministic Fieldserv fixtures plus a lane-local context; Phase 149 proves the static breadth plus narrow persistence pattern in `SaaSPortal.Fixtures` and `SaaSPortal.Approvals`. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal] |
| FIELD-02 | User can see device-pressure flows such as scanning/capture intent, evidence upload, permissions, and native-control gaps represented honestly. | Mirror the existing native-screen capture metadata shape while exposing scanner/document-scan/permission pressure as unavailable or future native-control gaps, not bridge commands or runnable web support. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] [VERIFIED: guides/capabilities.md] |
| FIELD-03 | User can see offline/degraded posture in the field-service lane without implying local-first mutation unless a real journal/outbox path is present. | Use cached read-only/degraded copy by default and add explicit no-overclaiming tests for local-first, journal, outbox, replay, saved locally, and queued for sync terms. [VERIFIED: guides/offline.md] [VERIFIED: .planning/phases/150-field-service-showcase/150-CONTEXT.md] |
| FIELD-04 | User can trace route ownership and support labels for field-service flows that should remain LiveView, become offline islands, or become future native screens. | Derive diagnostics and support truth from compiled router metadata, as Phase 149 does for AdminPilot diagnostics, and assert route id/runtime/offline/security/capability rows in ExUnit and Playwright. [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/diagnostics.ex] [VERIFIED: examples/phoenix_host/test/crosswake_example/saas_portal/diagnostics_test.exs] |

</phase_requirements>

## Project Constraints (from AGENTS.md)

- Read `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` before planning or implementation work. [VERIFIED: AGENTS.md]
- Preserve the thesis that Crosswake is a Phoenix-first route-policy and runtime-contract system, not a universal UI framework. [VERIFIED: AGENTS.md]
- Keep runtime ownership explicit per route; do not collapse plans into generic WebView wrapper behavior or LiveView-driven native rendering. [VERIFIED: AGENTS.md]
- Treat bridge contracts as semantic, typed, versioned, and low-frequency; continuous client authority belongs in an offline island or native screen. [VERIFIED: AGENTS.md]
- Keep offline claims honest by distinguishing cached read-only behavior from true local-first mutation with journals, outboxes, and reconciliation. [VERIFIED: AGENTS.md]
- Treat diagnostics, support matrices, proof lanes, and rough-edge documentation as product surface. [VERIFIED: AGENTS.md]
- Respect v1 scope boundaries before adding integrations or wider native breadth. [VERIFIED: AGENTS.md]

## Summary

Plan Phase 150 as a new product-first Fieldserv lane, not as a cosmetic rename of `/native/claims`. The primary route chain should be `/fieldserv/jobs -> /fieldserv/jobs/:id -> /fieldserv/jobs/:id/inspection -> /fieldserv/jobs/:id/capture -> /fieldserv/jobs/:id/evidence/:evidence_id/review`, with job/asset/inspection/evidence language dominating the first impression and Crosswake route-policy truth appearing as compact support labels and diagnostics. [VERIFIED: .planning/phases/150-field-service-showcase/150-CONTEXT.md]

The strongest implementation pattern is the Phase 149 hybrid: deterministic fixture/read-context breadth for realistic domain density plus optional narrow persisted workflow/evidence state for refresh-proof transitions. Put state changes in a lane-local Phoenix context, use Ecto changesets and `Ecto.Multi` only where multiple persisted facts must change together, and keep LiveViews focused on loading, dispatching events, and rendering outcomes. [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal] [CITED: https://phoenix.hexdocs.pm/contexts.html] [CITED: https://ecto.hexdocs.pm/Ecto.Multi.html]

Native capture, scanner, document-scan, permission, media upload, and offline behavior are the risk centers. Capture should remain an explicit `:native_screen` route that mirrors the existing camera/media pack and `transfer.upload.prepare` metadata; scanner/document scan should be future native-control pressure; permission truth must stay narrow because `permissions.status` is notifications-only in the current guide; and offline posture must be cached read-only/degraded unless a full Fieldserv offline island ships with local storage, journal/outbox, replay, conflict/rejection, reconciliation, browser reset proof, and route-tour evidence. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] [VERIFIED: guides/bridge.md] [VERIFIED: guides/offline.md] [VERIFIED: guides/native_shell.md]

**Primary recommendation:** Build `CrosswakeExample.FieldService` as a lane-local wrapper/context, add product-first `/fieldserv/*` routes with mechanically tested metadata, reuse existing media/native lessons for vocabulary, and avoid new packages or broad schemas. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Fieldserv job queue/detail/inspection context | Frontend Server (Phoenix LiveView) | API / Backend context | LiveView already owns product-shaped showcase routes while context modules should own data access and validation. [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal] [CITED: https://phoenix.hexdocs.pm/contexts.html] |
| Static field-service breadth | API / Backend context | Database / Storage only if needed | Fixtures can cover jobs, assets, technicians, notes, support findings, and posture without schema sprawl. [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/fixtures.ex] |
| Narrow workflow/evidence state | API / Backend | Database / Storage | Persist only representative state that must survive refresh or reset, such as evidence events and technician job status. [VERIFIED: .planning/phases/150-field-service-showcase/150-CONTEXT.md] |
| Capture handoff | Native Screen | Frontend Server fallback surface | Existing route policy models camera capture as `runtime: :native_screen`, not as a LiveView web upload fallback. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] |
| Scanner/document-scan pressure | Native Screen (future) | Diagnostics/support surface | Capability guides classify scanner and document scan as native-screen/deferred pressure rather than bounded bridge commands. [VERIFIED: guides/capabilities.md] |
| Evidence availability authority | API / Backend | Frontend Server display | Existing media proof separates device/local evidence from backend verification before media availability. [VERIFIED: examples/phoenix_host/lib/crosswake_example/media/media_lane_live.ex] |
| Cached/degraded offline posture | Frontend Server display | Browser only for rendering state | Cached read-only means stale/read-only snapshots and disabled mutation; true local-first requires a separate offline island proof. [VERIFIED: guides/offline.md] |
| Route ownership/support diagnostics | Frontend Server | Crosswake router metadata | Phase 149 derives diagnostics from compiled router metadata and tests drift mechanically. [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/diagnostics.ex] |
| Reset/digest truth | API / Backend | Database / Storage | `Showcase.Reset.reset!/0` already delegates lane resets and keeps `browser_state_reset: false`. [VERIFIED: examples/phoenix_host/lib/crosswake_example/showcase/reset.ex] |
| Responsive app UI/accessibility | Browser / Client | Frontend Server markup | CSS and route-tour checks must prove focus, overflow, dark/light, reduced motion, and badge/action fit. [VERIFIED: examples/phoenix_host/e2e/route_tour.spec.ts] [VERIFIED: brandbook/BRAND-SPEC.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `crosswake` path dependency | 0.2.0 | Route policy/runtime contract library for the Phoenix example host | Existing project package and route metadata source of truth. [VERIFIED: mix.exs] |
| `crosswake_rulestead`, `crosswake_rindle`, `crosswake_sigra`, `crosswake_chimeway`, `crosswake_threadline` path dependencies | local path packages | Existing companion package declarations for gate/media/auth/notification/audit surfaces | Example host already declares them; Phase 150 should reuse current companion posture without adding integrations. [VERIFIED: examples/phoenix_host/mix.exs] |
| `phoenix` | locked 1.8.7, latest observed 1.8.9 | Phoenix router, endpoint, controller, and LiveView host | Existing example-host framework; route policy lives in Phoenix routes. [VERIFIED: mix deps] [VERIFIED: mix hex.info phoenix] |
| `phoenix_live_view` | locked 1.1.30, latest observed 1.2.6 | Interactive server-rendered Fieldserv routes and LiveView tests | Existing lane UI pattern and test helpers. [VERIFIED: mix deps] [VERIFIED: mix hex.info phoenix_live_view] |
| `ecto_sql` / `ecto_sqlite3` | locked `ecto_sql` 3.13.5, `ecto_sqlite3` 0.23.0 | Narrow persisted workflow/evidence state and reset idempotency | Existing Phase 149 persistence pattern and SQLite test setup. [VERIFIED: mix deps] |
| `bandit` | locked 1.12.0 | Phoenix example-host web server | Existing Phoenix endpoint server. [VERIFIED: mix deps] |
| `@playwright/test` | installed 1.60.0 | Browser route-tour proof with semantic assertions and screenshots | Existing e2e harness under `examples/phoenix_host/e2e`. [VERIFIED: npm list] [CITED: https://playwright.dev/docs/test-assertions] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `jason` | locked 1.4.5 | JSON digest/output encoding in reset/test surfaces | Keep using existing reset/output helpers; no new JSON library. [VERIFIED: mix deps] |
| `Phoenix.LiveViewTest` | bundled with LiveView 1.1.30 | Render Fieldserv LiveViews and event flows in ExUnit | Use for rendered HTML and phx event assertions before Playwright. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveViewTest.html] |
| `Ecto.Multi` | bundled with Ecto 3.13.6 | Transactional multi-fact state changes | Use only when evidence plus job/status facts must change together. [VERIFIED: mix deps] [CITED: https://ecto.hexdocs.pm/Ecto.Multi.html] |
| Existing `CrosswakeExample.Media.*` helpers | local modules | Vocabulary and proof pattern for device evidence versus backend verification | Reuse lessons or small pure helpers, but do not imply production Rindle/media provider support. [VERIFIED: examples/phoenix_host/lib/crosswake_example/media] |
| Existing `app.css` and `tokens.css` | local static CSS | Fieldserv shell, badges, responsive layouts, theme/focus states | Extend with scoped `.fieldserv-*` rules rather than a new styling system. [VERIFIED: examples/phoenix_host/priv/static/css/app.css] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| New product-first `CrosswakeExample.FieldService` lane | Keep `/native/claims` as the primary UX | Rejected by D-01/D-03 because it makes Fieldserv feel like a route-policy proof route rather than a field-service product lane. [VERIFIED: .planning/phases/150-field-service-showcase/150-CONTEXT.md] |
| Deterministic fixture breadth plus narrow persistence | Full schema model for every job, asset, checklist, technician, route, and note | Full schemas increase migration/test/reset scope without improving the Phase 150 proof. [VERIFIED: .planning/phases/150-field-service-showcase/150-CONTEXT.md] |
| Native-screen capture route | Web upload fallback or camera bridge command | Rejected because current route policy and native shell docs require native capture to stay native-owned and fail closed. [VERIFIED: guides/native_shell.md] [VERIFIED: guides/bridge.md] |
| Cached read-only/degraded offline posture | True Fieldserv offline island | Deferred unless the phase builds local storage, journal/outbox, replay, conflict/rejection, reconciliation, browser reset proof, and route-tour proof. [VERIFIED: guides/offline.md] |
| Existing dependencies | New UI/test/state packages | No new package is needed for this showcase; adding packages expands verification surface without solving the hard route-truth problems. [VERIFIED: package.json] [VERIFIED: mix.exs] |

**Installation:**

```bash
# No new package installation is recommended for Phase 150.
cd examples/phoenix_host
mix deps
npm list @playwright/test typescript
```

**Version verification performed:**

```bash
cd examples/phoenix_host
mix deps
mix hex.info phoenix
mix hex.info phoenix_live_view
npm list @playwright/test typescript
npx playwright --version
```

## Package Legitimacy Audit

> Phase 150 should not install new external packages. Existing project packages were inspected only to document the current verification surface. [VERIFIED: package.json] [VERIFIED: mix.exs]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `@playwright/test` | npm | created 2020-09-24; latest modified 2026-07-11 | 44.7M/week observed by seam | github.com/microsoft/playwright | SUS latest flagged as too-new by seam | Reuse installed 1.60.0 from lockfile; do not upgrade in Phase 150. [VERIFIED: npm view] [VERIFIED: package-legitimacy seam] |
| `typescript` | npm | created 2012-10-01; latest modified 2026-07-11 | 223.6M/week observed by seam | github.com/microsoft/TypeScript | SUS latest flagged as too-new by seam | Reuse installed 5.9.3 from lockfile; do not upgrade in Phase 150. [VERIFIED: npm view] [VERIFIED: package-legitimacy seam] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: package-legitimacy seam]
**Packages flagged as suspicious [SUS]:** no new install is planned; latest registry versions of existing `@playwright/test` and `typescript` were seam-flagged as too-new, so the planner should not add upgrade tasks. [VERIFIED: package-legitimacy seam]

## Architecture Patterns

### System Architecture Diagram

```text
User opens /fieldserv/jobs
  -> Phoenix Router route metadata declares runtime/offline/security/capabilities
  -> FieldService LiveView loads deterministic jobs/assets/technicians/evidence fixtures
  -> User selects a job
      -> /fieldserv/jobs/:id shows asset, notes, technician state, evidence blockers
      -> /fieldserv/jobs/:id/inspection shows checklist and online-only note/step actions
          -> if action changes persisted facts:
              FieldService context validates input
                -> optional Ecto.Multi writes narrow evidence/workflow event rows
                -> reset digest includes deterministic state components
          -> if user requests capture:
              /fieldserv/jobs/:id/capture route declares runtime :native_screen
                -> native app owns camera/session/permission choreography
                -> LiveView fallback explains native runtime requirement
                -> simulated device evidence leads to review route only as proof state
          -> /fieldserv/jobs/:id/evidence/:evidence_id/review
              -> LiveView/backend displays device evidence and backend verification status
              -> no uploaded=available copy until Backend verified
  -> Diagnostics/support panel derives route truth from compiled router metadata
  -> Playwright route tour asserts route owner/support/offline truth before screenshots
```

### Recommended Project Structure

```text
examples/phoenix_host/lib/crosswake_example/field_service/
├── fixtures.ex              # deterministic jobs, assets, people, notes, posture, support findings
├── jobs.ex                  # lane-local context/read API and workflow entry points
├── evidence.ex              # narrow persisted evidence/status transitions if a migration is used
├── diagnostics.ex           # route metadata/support rows derived from compiled router metadata
├── components.ex            # Fieldserv shell, badges, panels, timelines, checklist rows
├── jobs_live.ex             # /fieldserv/jobs
├── job_live.ex              # /fieldserv/jobs/:id
├── inspection_live.ex       # /fieldserv/jobs/:id/inspection
├── capture_live.ex          # /fieldserv/jobs/:id/capture fallback/handoff surface
└── evidence_review_live.ex  # /fieldserv/jobs/:id/evidence/:evidence_id/review

examples/phoenix_host/test/crosswake_example/field_service/
├── fixtures_test.exs
├── jobs_test.exs
├── evidence_test.exs
├── diagnostics_test.exs
├── components_test.exs
└── *_live_test.exs
```

### Pattern 1: Hybrid Fixture Breadth Plus Narrow Persistence

**What:** Keep realistic domain density in deterministic fixture maps, and persist only refresh-proof workflow/evidence events. [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/fixtures.ex] [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/approvals.ex]

**When to use:** Use this for FIELD-01 breadth and any evidence/review transition that must survive refresh and reset idempotently. [VERIFIED: .planning/phases/150-field-service-showcase/150-CONTEXT.md]

**Example:**

```elixir
# Source: examples/phoenix_host/lib/crosswake_example/saas_portal/approvals.ex
# Source: https://ecto.hexdocs.pm/Ecto.Multi.html
def record_device_evidence(job_id, attrs) do
  job = get_job!(job_id)
  evidence_changeset = EvidenceEvent.device_evidence_changeset(job, attrs)
  state_changeset = TechnicianJobState.capture_recorded_changeset(job)

  Ecto.Multi.new()
  |> Ecto.Multi.insert(:evidence_event, evidence_changeset)
  |> Ecto.Multi.update(:technician_state, state_changeset)
  |> Repo.transaction()
end
```

### Pattern 2: Diagnostics From Compiled Route Metadata

**What:** Build Fieldserv support rows from `Phoenix.Router.routes/1` and `Crosswake.Policy.RouterMetadata.fetch/1`, then enrich with lane-local labels or rough edges. [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/diagnostics.ex]

**When to use:** Use for FIELD-04 and for catalog/support matrix drift tests. [VERIFIED: examples/phoenix_host/test/crosswake_example/saas_portal/diagnostics_test.exs]

**Example:**

```elixir
# Source: examples/phoenix_host/lib/crosswake_example/saas_portal/diagnostics.ex
def route_policy_rows(router \\ CrosswakeExample.Router) do
  router
  |> Phoenix.Router.routes()
  |> Enum.filter(&String.starts_with?(&1.path, "/fieldserv"))
  |> Enum.map(fn route ->
    metadata = Crosswake.Policy.RouterMetadata.fetch(route)

    %{
      path: route.path,
      route_id: metadata[:id],
      runtime: metadata[:runtime],
      offline: metadata[:offline],
      security: metadata[:security],
      capabilities: metadata[:capabilities] || [],
      transfers: metadata[:transfers] || []
    }
  end)
end
```

### Pattern 3: Native-Screen Capture Handoff

**What:** Add Fieldserv capture as a native-screen route with camera capability, media pack, upload-prepare transfer, verification required, cached read-only offline posture, and sensitive security posture. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex]

**When to use:** Use for `/fieldserv/jobs/:id/capture`; do not expose web camera upload or scanner bridge commands. [VERIFIED: guides/native_shell.md] [VERIFIED: guides/bridge.md]

**Example:**

```elixir
# Source: examples/phoenix_host/lib/crosswake_example/router.ex
live "/fieldserv/jobs/:id/capture", FieldService.CaptureLive,
  metadata: [
    id: "fieldserv-job-capture",
    runtime: :native_screen,
    capabilities: [:camera],
    packs: [[id: :camera_capture_assets, version: "1.0.0", kind: :media]],
    transfers: [
      [
        id: :capture_upload,
        intent: :upload,
        source: :native_capture,
        verification: :required,
        media_types: ["image/*"]
      ]
    ],
    offline: :cached_read_only,
    security: :sensitive
  ]
```

### Pattern 4: Evidence Status Ladder

**What:** Separate device evidence from backend availability with a closed status vocabulary: `Device evidence recorded`, `Backend verification pending`, `Backend verified`, and `Backend rejected`. [VERIFIED: examples/phoenix_host/lib/crosswake_example/media/media_lane_live.ex]

**When to use:** Use in evidence review, activity timelines, and no-overclaiming tests. [VERIFIED: guides/support_matrix.md]

**Example:**

```elixir
# Source: examples/phoenix_host/lib/crosswake_example/media/media_lane_live.ex
@evidence_statuses [
  :device_evidence_recorded,
  :backend_verification_pending,
  :backend_verified,
  :backend_rejected
]

def availability_copy(:device_evidence_recorded),
  do: "Device evidence is pending backend verification."

def availability_copy(:backend_verified),
  do: "Backend verified. Media is available to reviewers."
```

### Anti-Patterns to Avoid

- **Renaming `/native/claims` into Fieldserv without a product workflow:** This violates D-01 and leaves FIELD-01 underdeveloped. [VERIFIED: .planning/phases/150-field-service-showcase/150-CONTEXT.md]
- **Web camera/scanner fallback:** Native capture and scanner flows are native-screen/deferred capability families, not LiveView or bridge command features. [VERIFIED: guides/capabilities.md] [VERIFIED: guides/native_shell.md]
- **`uploaded = available` evidence copy:** Existing media proof says local/device capture is not media availability authority until backend verification. [VERIFIED: examples/phoenix_host/lib/crosswake_example/media/media_lane_live.ex]
- **Offline mutation copy without proof:** Terms like local-first, journal, outbox, replay, saved locally, or queued for sync are false unless the full route-local offline island exists. [VERIFIED: guides/offline.md]
- **Broad schema modeling:** Full tables for every Fieldserv noun add migration/reset burden and are not required by the phase scope. [VERIFIED: .planning/phases/150-field-service-showcase/150-CONTEXT.md]
- **Diagnostics disconnected from router metadata:** Static prose can drift; Phase 149 already proves compiled metadata checks. [VERIFIED: examples/phoenix_host/test/crosswake_example/saas_portal/diagnostics_test.exs]
- **Screenshot-first Playwright proof:** Existing route-tour tests assert semantics and then write screenshots; keep that order. [VERIFIED: examples/phoenix_host/e2e/route_tour.spec.ts]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Route metadata truth | String-scanned route tables or hardcoded support matrices | `Phoenix.Router.routes/1` plus `Crosswake.Policy.RouterMetadata.fetch/1` | Compiled route metadata is already the project truth source and is testable. [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/diagnostics.ex] |
| Multi-fact persisted transitions | Independent Repo calls in LiveView handlers | Context function with changesets and `Ecto.Multi` | `Ecto.Multi` names and composes changes in one transaction. [CITED: https://ecto.hexdocs.pm/Ecto.Multi.html] |
| Evidence authority model | New ad hoc uploaded/available flags | Existing media proof status ladder and backend verification copy | The current proof lane already separates device evidence from availability. [VERIFIED: examples/phoenix_host/lib/crosswake_example/media/media_lane_live.ex] |
| Offline sync | Lightweight outbox wording or fake local queue | Cached read-only/degraded posture; defer true offline island | Official mobile offline-first guidance requires local data source, queues, retry, sync, and conflict/reconciliation semantics. [CITED: https://developer.android.com/topic/architecture/data-layer/offline-first] |
| Permission UX | Generic LiveView permission dashboard | Native capture screen permission choreography plus narrow support labels | Android/Apple guidance ties camera access to explicit user action and native permission prompts. [CITED: https://developer.android.com/training/permissions/requesting] [CITED: https://developer.apple.com/design/human-interface-guidelines/privacy] |
| Browser proof helpers | One-off Playwright scripts | Extend `e2e/route_tour.spec.ts` helpers | Existing proof captures route metadata, semantic text, focus, overflow, mobile, dark, and screenshots. [VERIFIED: examples/phoenix_host/e2e/route_tour.spec.ts] |
| Styling system | New framework or global visual reset | Scoped `.fieldserv-*` CSS using existing tokens/app.css | Existing example host uses local CSS tokens and lane classes. [VERIFIED: examples/phoenix_host/priv/static/css/app.css] |

**Key insight:** The hard part is not rendering a field-service screen; it is preserving Crosswake's truth boundaries while making device pressure visible. Use existing router metadata, context boundaries, reset/digest discipline, and evidence vocabulary instead of inventing parallel mechanisms. [VERIFIED: AGENTS.md] [VERIFIED: .planning/phases/150-field-service-showcase/150-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Product UX Leaks Implementation Names
**What goes wrong:** The Fieldserv lane points users to `/native/claims` or uses claim-proof language as the primary UX. [VERIFIED: examples/phoenix_host/lib/crosswake_example/showcase/hub_live.ex]
**Why it happens:** Existing Field Service catalog/hub wiring already points at native-pressure proof routes. [VERIFIED: examples/phoenix_host/lib/crosswake_example/showcase/catalog.ex]
**How to avoid:** Repoint the showcase card and hub lane to `/fieldserv/jobs`, then keep legacy `/native/*` routes reachable only as proof/compatibility routes. [VERIFIED: .planning/phases/150-field-service-showcase/150-CONTEXT.md]
**Warning signs:** `Fieldserv` pages contain `/native`, `claim capture proof`, or route-policy language before job/task language. [VERIFIED: codebase grep]

### Pitfall 2: Native Capture Becomes a Web Upload
**What goes wrong:** The capture route silently degrades to a web upload button or adds camera/scanner bridge commands. [VERIFIED: guides/native_shell.md]
**Why it happens:** Browser file inputs are easier to demo than native permission/session ownership. [ASSUMED]
**How to avoid:** Keep `/fieldserv/jobs/:id/capture` as `runtime: :native_screen` with explicit fallback copy and no production camera/scanner implementation. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex]
**Warning signs:** Tests find `capture from browser`, `scan now`, `camera permission granted`, or new camera/scanner bridge command strings. [VERIFIED: guides/bridge.md]

### Pitfall 3: Evidence Copy Overstates Authority
**What goes wrong:** UI says evidence is uploaded, complete, or available immediately after device capture. [VERIFIED: examples/phoenix_host/lib/crosswake_example/selective_native/submission_review_live.ex]
**Why it happens:** The old `SelectiveNative.SubmissionReviewLive` marks a submission submitted and the claim uploaded, which is too strong for Phase 150 copy. [VERIFIED: examples/phoenix_host/lib/crosswake_example/selective_native/submission_review_live.ex]
**How to avoid:** Use the media proof vocabulary and status ladder, with backend verification owning availability. [VERIFIED: examples/phoenix_host/lib/crosswake_example/media/media_lane_live.ex]
**Warning signs:** UI contains `uploaded successfully` without also asserting backend verification is required. [VERIFIED: codebase grep]

### Pitfall 4: Cached Read-Only Looks Like Local-First
**What goes wrong:** Inspection copy implies drafts can be saved offline or queued for later sync. [VERIFIED: guides/offline.md]
**Why it happens:** Field inspection domains naturally invite offline-first language. [ASSUMED]
**How to avoid:** Use cached read-only/degraded labels, disabled mutation affordances, and future offline-island rows that list missing journal/outbox/replay/conflict/reconciliation proof. [VERIFIED: .planning/phases/150-field-service-showcase/150-CONTEXT.md]
**Warning signs:** Page text includes `saved locally`, `queued for sync`, `outbox`, `journal`, `replay`, or `local-first` outside an explicit future-not-shipped row. [VERIFIED: .planning/phases/150-field-service-showcase/150-CONTEXT.md]

### Pitfall 5: Reset Digest Misses Fieldserv State
**What goes wrong:** Reset is deterministic for static fixtures but misses newly persisted Fieldserv evidence rows. [VERIFIED: examples/phoenix_host/lib/crosswake_example/showcase/reset_test.exs]
**Why it happens:** Phase 150 may add narrow persisted events while `Showcase.Reset` still delegates only to existing native fixtures. [VERIFIED: examples/phoenix_host/lib/crosswake_example/showcase/reset.ex]
**How to avoid:** Add Fieldserv-owned reset and digest components before workflow routes depend on persisted evidence. [VERIFIED: .planning/phases/150-field-service-showcase/150-CONTEXT.md]
**Warning signs:** `mix showcase.reset` counts do not include Fieldserv event/evidence state or second reset changes the digest. [VERIFIED: examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs]

### Pitfall 6: Responsive Support Truth Clips on Mobile
**What goes wrong:** Dense badges, route labels, action footers, or diagnostics tables overflow on 390px mobile. [VERIFIED: .planning/phases/150-field-service-showcase/150-CONTEXT.md]
**Why it happens:** Desktop route matrices do not map cleanly to mobile field-work screens. [VERIFIED: brandbook/BRAND-SPEC.md]
**How to avoid:** Use stacked task flow, wrap badges, avoid wide tables on mobile, and extend Playwright overflow/focus checks. [VERIFIED: examples/phoenix_host/e2e/route_tour.spec.ts]
**Warning signs:** Horizontal scroll, clipped badge text, focus ring outside viewport, or action footer overlap. [VERIFIED: examples/phoenix_host/e2e/route_tour.spec.ts]

## Code Examples

Verified patterns from official or local sources:

### Reset Delegate With Stable Digest

```elixir
# Source: examples/phoenix_host/lib/crosswake_example/showcase/reset.ex
def reset! do
  counts = %{
    saas_admin: Fixtures.reset_saas_admin!(),
    field_service: FieldService.reset!(),
    learning_training: Flashcards.reset_seed!()
  }

  digest =
    [counts, FieldService.digest_components()]
    |> :erlang.term_to_binary()
    |> :crypto.hash(:sha256)
    |> Base.encode16(case: :lower)

  %{counts: counts, digest: digest, browser_state_reset: false}
end
```

### No-Overclaiming Test Pattern

```elixir
# Source: examples/phoenix_host/test/crosswake_example/saas_portal/approvals_live_test.exs
test "fieldserv pages do not claim unsupported offline mutation" do
  html = render_fieldserv_pages()

  refute html =~ ~r/local[- ]first/i
  refute html =~ ~r/\b(journal|outbox|replay)\b/i
  refute html =~ ~r/saved locally|queued for sync/i
  assert html =~ "Cached read-only"
  assert html =~ "This cached job snapshot cannot be edited offline."
end
```

### Playwright Route-Tour Assertions Before Screenshots

```typescript
// Source: examples/phoenix_host/e2e/route_tour.spec.ts
await page.goto("/fieldserv/jobs");
await expect(page.getByRole("heading", { name: /Fieldserv/i })).toBeVisible();
await expect(page.getByText("Cached read-only")).toBeVisible();
await expect(page.getByText("Requires native runtime")).toBeVisible();
await expect(page.getByText("Backend verification pending")).toBeVisible();
await expect(page.getByText(/local-first|outbox|queued for sync/i)).toHaveCount(0);
await expectNoHorizontalOverflow(page);
await expectVisibleFocus(page, page.getByRole("link", { name: /inspection/i }).first());
await page.screenshot({ path: "playwright-artifacts/route-tour/screenshots/fieldserv-jobs.png" });
```

### Closed Evidence Status Vocabulary

```elixir
# Source: examples/phoenix_host/lib/crosswake_example/media/media_lane_live.ex
@allowed_statuses [
  :device_evidence_recorded,
  :backend_verification_pending,
  :backend_verified,
  :backend_rejected
]

def changeset(event, attrs) do
  event
  |> Ecto.Changeset.cast(attrs, [:status, :job_id, :evidence_id])
  |> Ecto.Changeset.validate_inclusion(:status, @allowed_statuses)
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `/native/claims` as the Field Service entry | Product-first `/fieldserv/jobs` lane with legacy `/native/*` proof routes still reachable | Phase 150 context, 2026-07-11 | Planner must add new routes and repoint hub/catalog rather than relying on old native route. [VERIFIED: .planning/phases/150-field-service-showcase/150-CONTEXT.md] |
| Submitted/uploaded means available | Backend verification owns availability after device evidence | Existing media proof lane before Phase 150 | Planner must avoid `uploaded successfully` as final authority copy. [VERIFIED: examples/phoenix_host/lib/crosswake_example/media/media_lane_live.ex] |
| Cached read-only badge alone | Cached/degraded UI plus explicit future offline-island requirements | Phase 150 context and offline guide | Planner must assert absence of local-first/outbox wording unless real offline proof ships. [VERIFIED: guides/offline.md] |
| Static diagnostics prose | Diagnostics rows derived from compiled router metadata | Phase 149 AdminPilot | Planner should make Fieldserv support truth mechanically testable. [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/diagnostics.ex] |
| Screenshot collateral as proof | Semantic assertions first, screenshots second | Existing route-tour pattern | Planner should treat screenshots as artifacts after route-owner/copy/accessibility assertions pass. [VERIFIED: examples/phoenix_host/e2e/route_tour.spec.ts] |

**Deprecated/outdated:**
- Using `/native/claims` as the user-facing Fieldserv first screen is outdated for Phase 150 because D-01 requires a product-first field-service lane. [VERIFIED: .planning/phases/150-field-service-showcase/150-CONTEXT.md]
- Treating `permissions.status` as a generic camera/scanner/location permission API is out of scope; current guidance keeps it to notifications alias truth. [VERIFIED: guides/capabilities.md] [VERIFIED: guides/bridge.md]
- Claiming local-first/offline mutation without route-local storage, journal/outbox, replay outcomes, conflict/rejection, reconciliation, and browser reset proof is disallowed. [VERIFIED: guides/offline.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Browser file inputs are easier to demo than native permission/session ownership. [ASSUMED] | Common Pitfalls | Low implementation risk; this only explains why the pitfall is tempting, not a required plan decision. |
| A2 | Field inspection domains naturally invite offline-first language. [ASSUMED] | Common Pitfalls | Low implementation risk; no plan should rely on this claim. |

## Open Questions (RESOLVED)

1. **RESOLVED: Phase 150 adds a new narrow Fieldserv migration rather than reusing existing `selective_native_*` tables.**
   - What we know: Context gives the planner discretion and recommends narrow persistence only for representative workflow/evidence state. [VERIFIED: .planning/phases/150-field-service-showcase/150-CONTEXT.md]
   - Selected plan decision: Add Fieldserv-owned `field_service_evidence_events` and `field_service_technician_job_states` persistence for representative workflow/evidence state, while keeping broad jobs/assets/templates as deterministic fixture/read-context data. [VERIFIED: .planning/phases/150-field-service-showcase/150-04-PLAN.md]
   - Reason: The planned backend-verification status ladder needs refresh-proof evidence state that is not constrained by old `SelectiveNative` claim/submission semantics. [VERIFIED: examples/phoenix_host/lib/crosswake_example/selective_native]

2. **RESOLVED: Fieldserv evidence review reuses media vocabulary and helper patterns only, not shared `CrosswakeExample.Media.*` helpers.**
   - What we know: Media proof modules already model device evidence and backend verification separation. [VERIFIED: examples/phoenix_host/lib/crosswake_example/media]
   - Selected plan decision: Keep Fieldserv state and review behavior in `CrosswakeExample.FieldService.Evidence` and `CrosswakeExample.FieldService.EvidenceReviewLive`, using the media lesson that device evidence is not available until backend verification. [VERIFIED: .planning/phases/150-field-service-showcase/150-04-PLAN.md] [VERIFIED: .planning/phases/150-field-service-showcase/150-06-PLAN.md]
   - Reason: Sharing production-ish media helpers would blur the Fieldserv showcase lane with Rindle/media proof boundaries; vocabulary reuse keeps the support truth without widening package or capability scope. [VERIFIED: guides/support_matrix.md]

3. **RESOLVED: Diagnostics live as lane-local inline/collapsible Fieldserv panels generated from `FieldService.Diagnostics`.**
   - What we know: Context allows lane-local panel, inline matrix, or reusable component, as long as truth is mechanically testable and not `crosswake_dashboard`. [VERIFIED: .planning/phases/150-field-service-showcase/150-CONTEXT.md]
   - Selected plan decision: Implement lane-local `FieldService.Diagnostics` rows, render compact route/support badges on primary Fieldserv surfaces, and expose route truth through inline `details` panels in `FieldService.Components`. [VERIFIED: .planning/phases/150-field-service-showcase/150-03-PLAN.md] [VERIFIED: .planning/phases/150-field-service-showcase/150-05-PLAN.md]
   - Reason: This preserves mobile scanability, mechanical route-metadata testing, and the no-`crosswake_dashboard` boundary. [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/diagnostics.ex]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir/Mix | ExUnit, Phoenix compile/test | yes | Mix 1.19.5 with Erlang/OTP 28 | none needed. [VERIFIED: local command] |
| SQLite CLI | Inspecting local SQLite state if needed | yes | 3.51.0 | Ecto test alias still provisions DB without direct CLI use. [VERIFIED: local command] |
| Node.js | Playwright e2e | yes | v22.14.0 | none needed. [VERIFIED: local command] |
| npm | Playwright dependency scripts | yes | 11.1.0 | none needed. [VERIFIED: local command] |
| Playwright CLI | Route-tour proof | yes | 1.60.0 | Run ExUnit-only validation if browser proof is temporarily unavailable, but phase gate still needs Playwright. [VERIFIED: local command] |
| Phoenix test server port | Playwright webServer on port 4700 | available at research time | no listener observed on 4700 | Playwright can choose existing configured server behavior; if conflict appears, stop the conflicting server. [VERIFIED: local command] |
| Hex public package metadata | Version checks | partially available | public queries worked; auth warning appeared | Use lockfile versions for planning; do not add dependency upgrade tasks. [VERIFIED: mix hex.info] |

**Missing dependencies with no fallback:**
- None observed during research. [VERIFIED: local command]

**Missing dependencies with fallback:**
- None observed during research. [VERIFIED: local command]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit through Mix plus Playwright 1.60.0 for browser proof. [VERIFIED: examples/phoenix_host/mix.exs] [VERIFIED: npm list] |
| Config file | `examples/phoenix_host/test/test_helper.exs`, `examples/phoenix_host/playwright.config.ts`. [VERIFIED: codebase grep] |
| Quick run command | `cd examples/phoenix_host && mix test test/crosswake_example/field_service test/crosswake_example/showcase/catalog_test.exs test/crosswake_example/showcase/reset_test.exs` |
| Full suite command | `cd examples/phoenix_host && mix test` |
| Browser route-tour command | `cd examples/phoenix_host && npx playwright test e2e/route_tour.spec.ts` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| FIELD-01 | Realistic jobs, assets, inspections, notes, evidence, and technician state render across the click path | unit/render/browser | `cd examples/phoenix_host && mix test test/crosswake_example/field_service/fixtures_test.exs test/crosswake_example/field_service/*_live_test.exs` | no, Wave 0. [VERIFIED: codebase grep] |
| FIELD-02 | Capture/scanning/permission/media pressure is honest and does not imply shipped camera/scanner/permission support | unit/render/browser | `cd examples/phoenix_host && mix test test/crosswake_example/field_service/diagnostics_test.exs test/crosswake_example/field_service/*_live_test.exs` | no, Wave 0. [VERIFIED: codebase grep] |
| FIELD-03 | Offline/degraded state is cached read-only and contains no unsupported local-first mutation claims | unit/render/browser | `cd examples/phoenix_host && mix test test/crosswake_example/field_service/*_live_test.exs && npx playwright test e2e/route_tour.spec.ts --grep Fieldserv` | no, Wave 0. [VERIFIED: codebase grep] |
| FIELD-04 | Route ownership/support labels match compiled route metadata for LiveView, native-screen, and future offline-island pressure | unit/browser | `cd examples/phoenix_host && mix test test/crosswake_example/field_service/diagnostics_test.exs test/crosswake_example/showcase/catalog_test.exs` | no, Wave 0. [VERIFIED: codebase grep] |

### Sampling Rate

- **Per task commit:** Run the focused Fieldserv ExUnit file(s) touched by the task plus `showcase/reset_test.exs` if reset/digest changed. [VERIFIED: examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs]
- **Per wave merge:** Run `cd examples/phoenix_host && mix test` and the Fieldserv grep/no-overclaim assertions. [VERIFIED: examples/phoenix_host/mix.exs]
- **Phase gate:** Run `cd examples/phoenix_host && mix test` and `cd examples/phoenix_host && npx playwright test e2e/route_tour.spec.ts`; save route-tour artifacts only after semantic assertions pass. [VERIFIED: examples/phoenix_host/playwright.config.ts]

### Wave 0 Gaps

- [ ] `test/crosswake_example/field_service/fixtures_test.exs` - covers FIELD-01 fixture density, stable ids, and digest components. [VERIFIED: codebase grep]
- [ ] `test/crosswake_example/field_service/jobs_test.exs` - covers context lookup, transitions, and missing job behavior. [VERIFIED: codebase grep]
- [ ] `test/crosswake_example/field_service/evidence_test.exs` - covers evidence status ladder and optional `Ecto.Multi` transaction behavior. [VERIFIED: codebase grep]
- [ ] `test/crosswake_example/field_service/diagnostics_test.exs` - covers FIELD-02/FIELD-04 route metadata drift and support-label allowlists. [VERIFIED: codebase grep]
- [ ] `test/crosswake_example/field_service/components_test.exs` - covers scoped CSS selectors, focus rules, reduced motion, 44px action targets, and prohibited copy. [VERIFIED: codebase grep]
- [ ] `test/crosswake_example/field_service/*_live_test.exs` - covers page render, click path, no-overclaim copy, and native capture fallback. [VERIFIED: codebase grep]
- [ ] Extend `e2e/route_tour.spec.ts` - covers Fieldserv route tour, mobile, dark, reduced motion, focus, overflow, and screenshots. [VERIFIED: examples/phoenix_host/e2e/route_tour.spec.ts]
- [ ] Update `e2e/support/evidence_manifest.ts` - includes Fieldserv capability-map evidence for Phase 152. [VERIFIED: examples/phoenix_host/e2e/support/evidence_manifest.ts]

## Security Domain

OWASP ASVS 5.0.0 is the current stable ASVS baseline observed during research, and its category names differ from older V2/V3/V4 labels used in some planning templates. [CITED: https://owasp.org/www-project-application-security-verification-standard/] The table below maps the Phase 150 surface to ASVS-style control areas while keeping Crosswake route policy as the project-specific control source. [VERIFIED: guides/route_policy.md]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| Authentication / credential handling | no new auth | Phase 150 does not add login or credential flows; do not add auth package work. [VERIFIED: .planning/REQUIREMENTS.md] |
| Session management | limited | Use existing Phoenix/LiveView session behavior; e2e helper routes must remain test-only. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] |
| Access control / route policy | yes | Route ownership, runtime, offline, security, capabilities, packs, and transfers must be declared in router metadata and tested for drift. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] |
| Validation, encoding, and input handling | yes | Use context functions, Ecto changesets, closed status vocabularies, and stable ids for any persisted Fieldserv events. [CITED: https://phoenix.hexdocs.pm/contexts.html] [CITED: https://ecto.hexdocs.pm/Ecto.Multi.html] |
| Cryptography / secrets | no new crypto | Do not add cryptographic code or secret-bearing metadata; reset digest can keep existing hash style. [VERIFIED: examples/phoenix_host/lib/crosswake_example/showcase/reset.ex] |
| Data protection / privacy | yes | Treat evidence routes as sensitive, avoid raw media/PII storage in route metadata, and keep backend verification authority explicit. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] [VERIFIED: guides/support_matrix.md] |

### Known Threat Patterns for Fieldserv

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Route metadata drift makes capture look browser-owned | Spoofing / Tampering | Derive diagnostics from compiled router metadata and add tests for runtime/offline/security/capability declarations. [VERIFIED: examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs] |
| Evidence status tampering through arbitrary params | Tampering | Use context-level validation and closed status vocabularies before persistence. [CITED: https://phoenix.hexdocs.pm/contexts.html] |
| Media/evidence availability overclaim | Information Disclosure / Repudiation | Use `Device evidence recorded` and backend verification states until review authority is explicit. [VERIFIED: examples/phoenix_host/lib/crosswake_example/media/media_lane_live.ex] |
| Permission support spoofing | Spoofing | Keep camera/scanner/location permission copy inside native-screen/future-gap surfaces; do not broaden `permissions.status`. [VERIFIED: guides/bridge.md] [CITED: https://developer.android.com/training/permissions/requesting] |
| Offline mutation spoofing | Tampering / Repudiation | Forbid local-first/journal/outbox/replay copy unless full offline island proof ships. [VERIFIED: guides/offline.md] |
| E2E helper route exposure | Elevation of Privilege | Keep helper routes under `Mix.env() == :test` style boundaries already used by existing e2e routes. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/150-field-service-showcase/150-CONTEXT.md` - authoritative phase decisions, discretion, and deferred scope. [VERIFIED: codebase grep]
- `AGENTS.md` - project constraints and working rules. [VERIFIED: codebase grep]
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/PROJECT.md` - phase requirements and project thesis/state. [VERIFIED: codebase grep]
- `examples/phoenix_host/lib/crosswake_example/router.ex` - existing native route metadata and e2e helper boundaries. [VERIFIED: codebase grep]
- `examples/phoenix_host/lib/crosswake_example/showcase/*` - catalog, branding, hub, reset, and reset tests. [VERIFIED: codebase grep]
- `examples/phoenix_host/lib/crosswake_example/selective_native/*` - current claim/capture/submission implementation to wrap or avoid leaking. [VERIFIED: codebase grep]
- `examples/phoenix_host/lib/crosswake_example/media/*` - existing media evidence authority proof. [VERIFIED: codebase grep]
- `examples/phoenix_host/lib/crosswake_example/saas_portal/*` and tests - Phase 149 closest analog for fixture breadth, narrow persistence, diagnostics, components, and proof. [VERIFIED: codebase grep]
- `examples/phoenix_host/e2e/route_tour.spec.ts` and Playwright support files - browser proof patterns. [VERIFIED: codebase grep]
- `guides/route_policy.md`, `guides/capabilities.md`, `guides/support_matrix.md`, `guides/native_shell.md`, `guides/bridge.md`, `guides/offline.md` - route ownership, capability, native, bridge, media, and offline truth. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- Phoenix contexts official documentation - context boundaries and encapsulated data access. [CITED: https://phoenix.hexdocs.pm/contexts.html]
- Phoenix LiveViewTest official documentation - live route tests and event helpers. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveViewTest.html]
- Ecto.Multi official documentation - transactional named insert/update/run operations. [CITED: https://ecto.hexdocs.pm/Ecto.Multi.html]
- Playwright official assertions documentation - auto-retrying web assertions, visibility, focus, viewport, and text checks. [CITED: https://playwright.dev/docs/test-assertions]
- Android permissions official documentation - request point-of-use permissions, check grants, rationale, graceful denial. [CITED: https://developer.android.com/training/permissions/requesting]
- Android offline-first data layer documentation - local data source, queued/lazy writes, retry, sync, conflict/reconciliation requirements. [CITED: https://developer.android.com/topic/architecture/data-layer/offline-first]
- Android persistent background work documentation - WorkManager persistence, constraints, retry/backoff, and sync use cases. [CITED: https://developer.android.com/develop/background-work/background-tasks/persistent]
- Apple Human Interface Guidelines privacy page and AVFoundation camera permission page - permission requests require a clear reason and explicit media access authorization. [CITED: https://developer.apple.com/design/human-interface-guidelines/privacy] [CITED: https://developer.apple.com/documentation/avfoundation/avcapturedevice/requestaccess(for:completionhandler:)]
- OWASP ASVS project page - ASVS 5.0.0 current stable baseline observed during research. [CITED: https://owasp.org/www-project-application-security-verification-standard/]

### Tertiary (LOW confidence)

- No tertiary sources are required for implementation planning. [VERIFIED: research plan]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions came from local `mix deps`, `npm list`, `package.json`, `mix.exs`, and Hex/npm inspection; no new packages are recommended. [VERIFIED: local command]
- Architecture: HIGH - route ownership, offline posture, native capture, and media evidence boundaries are locked in phase context and existing Crosswake guides/code. [VERIFIED: .planning/phases/150-field-service-showcase/150-CONTEXT.md]
- Pitfalls: HIGH - most pitfalls are visible in existing code paths or explicitly called out in phase decisions; two explanatory cause claims are marked assumed. [VERIFIED: codebase grep]
- External mobile/platform lessons: MEDIUM - official docs were checked via web fallback because Context7 tooling was unavailable in this session. [CITED: https://developer.android.com/training/permissions/requesting]
- Validation: HIGH - ExUnit and Playwright infrastructure already exists and Phase 149 provides closest proof patterns. [VERIFIED: examples/phoenix_host/test] [VERIFIED: examples/phoenix_host/e2e/route_tour.spec.ts]

**Research date:** 2026-07-11
**Valid until:** 2026-08-10 for stack/official-doc assumptions; re-check package versions and OWASP/platform docs before dependency or security-sensitive changes. [VERIFIED: current date]
