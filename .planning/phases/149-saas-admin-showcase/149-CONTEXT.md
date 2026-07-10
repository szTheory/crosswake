# Phase 149: SaaS/Admin Showcase - Context

**Gathered:** 2026-07-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 149 builds the AdminPilot SaaS/admin lane as a polished, click-around LiveView-first product surface. It should demonstrate that ordinary SaaS/admin routes remain Phoenix-owned on mobile, while route policy, cached-read-only limits, auth/admin pressure, bounded native affordances, diagnostics, and support truth stay visible and honest.

This phase does not build a generic admin framework, a broad CRUD console, a standalone `crosswake_dashboard`, new native-control APIs, real local-first admin mutation, or production MFA/provider auth. It consumes the Phase 148 AdminPilot brand and fixture brief, deepens the existing SaaS portal code, and prepares evidence for the Phase 152 capability map.

</domain>

<decisions>
## Implementation Decisions

### AdminPilot Lane Shape
- **D-01:** Make AdminPilot a focused approvals workspace, not a broad admin-console clone and not a diagnostics-first operator console.
- **D-02:** The primary click path should be `dashboard -> approvals queue -> approval detail -> approve`, surrounded by believable account, team, role, settings, activity, and admin-pressure context.
- **D-03:** Cover SAAS-01 breadth through dense seeded context, not CRUD sprawl. The lane should show accounts, teams, roles, settings, operational records, and activity, but only the representative approval workflow needs to be interactive.
- **D-04:** Keep Crosswake's route-policy and runtime-contract story as the product substrate behind AdminPilot. The first impression should feel like a real SaaS/admin app, not a manifest inspector.
- **D-05:** Do not introduce a framework-like admin DSL or generic resource/table builder. Use normal Phoenix contexts, LiveViews, HEEx components, and route metadata.

### Representative Admin Workflow
- **D-06:** Use approval review/approval as the representative admin workflow. It is the strongest existing fit for Phoenix-owned server authority plus one low-frequency bounded native confirmation signal.
- **D-07:** The approval action must remain server-authoritative. Haptics, if present, is a secondary confirmation after a successful Phoenix-owned action, never mutation authority.
- **D-08:** If Phase 149 needs refresh-proof mutation evidence, persist only the mutable approval/activity trail. Keep broader account/team/member/settings fixture records deterministic unless planner finds existing persistence that makes this cheaper.
- **D-09:** Prefer an idiomatic Phoenix context boundary for SaaS operations, such as enriching `CrosswakeExample.SaaSPortal` with functions that accept current user/account or an explicit scope-like struct. Do not scatter authorization or mutation logic into LiveView templates.
- **D-10:** If persistence is added, use Ecto only where it proves real mutation/audit behavior. Static showcase breadth can remain deterministic fixture maps.
- **D-11:** The workflow should include normal LiveView loading/disabled/success states and be testable with LiveViewTest and Playwright route-tour coverage.
- **D-12:** The approval happy path should still complete without native haptics. Missing haptics must be shown as degradable support truth, not a failed approval.

### Auth and Admin Posture
- **D-13:** Show auth/admin posture as a guided story: normal authenticated SaaS work first, then adjacent admin/security pressure that explains why fresh backend authority matters.
- **D-14:** Use subtle posture badges as persistent landmarks, not as the only explanation. Badges should say user-facing truths such as `LiveView route`, `Cached read-only`, `Sensitive route`, `MFA required`, and `Server authority`.
- **D-15:** Keep the existing blocked/admin member-access route as the explicit denial/proof state. It should demonstrate that a persistent native shell session or device evidence does not grant admin authority.
- **D-16:** Do not fake a full provider MFA flow or claim native auth UI. If a step-up challenge is shown, frame it as backend-owned example-host pressure and keep proof limitations explicit.
- **D-17:** Copy should be calm and short: name what happened, what owns the decision, and what the user can do next. Avoid raw denial-code dumps in user-facing UI.
- **D-18:** The implementation should preserve Plug/session/on_mount boundaries. Session assignment and recent-auth checks belong in pipeline/on_mount/auth helpers, while LiveViews render posture and handle product events.

### Diagnostics and Support Truth
- **D-19:** Add a lane-local diagnostics/support panel as the primary inspection surface for Phase 149. It should be constrained to AdminPilot routes and must not become `crosswake_dashboard`.
- **D-20:** Use compact inline badges on each AdminPilot page for point-of-use runtime/offline/security/capability truth. The panel provides the deeper comparison table and docs links.
- **D-21:** Diagnostics must derive from existing router metadata, showcase catalog metadata, or a small SaaS-lane route catalog that is mechanically tested against compiled route policy. Avoid a prose-only shadow source of truth.
- **D-22:** The diagnostics panel should compare each AdminPilot route's path, route id, runtime owner, offline posture, entry posture, security/auth posture, capability declarations, support label, and rough edge.
- **D-23:** Include canonical guide/support links from the panel, but do not make docs linkout the only way to inspect support truth from the lane.
- **D-24:** Do not add a dedicated inspector route in Phase 149. If a URL-addressable inspector is useful later, defer it to Phase 152 capability-map work or future DASH-01.

### UI and UX Direction
- **D-25:** AdminPilot should use its locked Phase 148 brand direction: "refined enterprise control room" with ledger-green ops styling, while remaining clearly inside the Crosswake showcase.
- **D-26:** The lane should be an operational SaaS UI: dense but scan-friendly, restrained, responsive, and task-first. Avoid hero marketing sections, oversized decorative cards, generic blue/purple SaaS gradients, and internal implementation copy as the first impression.
- **D-27:** Use conventional admin affordances: KPI/status strip, resource list/table or responsive list for approvals, detail view with action footer, role/member summary, activity feed, route badges, and disclosure/details for diagnostics.
- **D-28:** Mobile should prioritize a single-column task flow and readable records over desktop table parity. Do not hide essential actions or support truth on mobile.
- **D-29:** Accessibility is part of scope: visible focus rings, 44px preferred tap targets, text labels on badges, no color-only status, reduced-motion-safe interactions, and readable contrast in light/dark/system themes.
- **D-30:** Microcopy should be JTBD-focused. Users see account/admin language first; Crosswake route-policy language appears as supporting status or diagnostics, not as backend exposition.

### Data and Fixture Direction
- **D-31:** Expand SaaS/admin fixture density to meet the Phase 148 brief: at least one credible organization, at least three people/roles, at least three operational records, at least two activity items, and explicit admin/security pressure.
- **D-32:** Recommended domain nouns: workspace/account, team, member, role, approval, approval policy, setting, activity event, route posture, support finding.
- **D-33:** Recommended verbs/events: open lane, review queue, inspect account, approve request, stage/review member access, view route posture, inspect support truth.
- **D-34:** Keep reset deterministic. If persistent approval/activity rows are introduced, `Showcase.Reset.reset!()` should delete/reseed them idempotently and include stable counts/digest components.

### Proof and Verification
- **D-35:** Extend ExUnit tests around fixture density, route metadata drift, LiveView approval behavior, auth/admin denial posture, diagnostics derivation, and reset idempotency.
- **D-36:** Extend Playwright route-tour coverage to exercise the AdminPilot happy path, not just the dashboard heading. The route tour should prove semantic route ownership before relying on screenshots.
- **D-37:** Verify UI in desktop and mobile, light and dark/system, with focus and reduced-motion checks. The lane must have no horizontal overflow and no badge/action text clipping.

### Claude's Discretion
- The planner may choose exact module/component names, whether approval/activity persistence is worth the added Ecto surface, and whether diagnostics live in a reusable component or a lane-specific helper.
- The planner may keep deterministic maps for static data if tests prove realistic density and reset truth.
- The planner may refine copy and layout as long as it preserves the decisions above and the brandbook constraints.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and Milestone Scope
- `.planning/PROJECT.md` — Current Crosswake thesis, v19/v20 arc, constraints, and Phase 149 active requirement.
- `.planning/REQUIREMENTS.md` — Phase 149 requirements SAAS-01..04 and v19 proof/collateral boundaries.
- `.planning/ROADMAP.md` — Phase 149 goal and success criteria.
- `.planning/STATE.md` — Current milestone state, locked v19 roadmap decisions, and anti-scope reminders.
- `.planning/phases/147-arc-fixture-and-showcase-foundation/147-CONTEXT.md` — Foundation decisions for showcase hub, reset ownership, route/support labels, first-run discovery, and support-truth posture.
- `.planning/phases/148-demo-app-brand-fixture-direction/148-VERIFICATION.md` — Locked AdminPilot brand/fixture direction and verification evidence.

### Brand, UI, and UX
- `brandbook/BRAND-SPEC.md` — Current canonical Crosswake brand, voice, accessibility, badge, layout, light/dark, and microcopy rules. Supersedes older prompt-era brand notes.
- `examples/phoenix_host/priv/static/css/tokens.css` — Example-host token copy consumed by the showcase UI.
- `examples/phoenix_host/priv/static/css/app.css` — Existing shared CSS surface and route-card/badge/showcase classes to reuse or extend.

### Existing SaaS/Admin Code
- `examples/phoenix_host/lib/crosswake_example/router.ex` — Existing `/saas` route policies, runtime/offline/security/auth posture, and route ids.
- `examples/phoenix_host/lib/crosswake_example/showcase/branding.ex` — AdminPilot brand and fixture brief.
- `examples/phoenix_host/lib/crosswake_example/showcase/catalog.ex` — Existing lane metadata, support labels, and route metadata drift-test pattern.
- `examples/phoenix_host/lib/crosswake_example/showcase/fixtures.ex` — Current SaaS reset/digest integration.
- `examples/phoenix_host/lib/crosswake_example/showcase/reset.ex` — Server-side deterministic reset orchestrator.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/fixtures.ex` — Current SaaS account/user/approval fixture baseline.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/dashboard_live.ex` — Current AdminPilot entry route.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/approvals_live.ex` — Current approval queue route.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex` — Current approval detail and haptics bridge request.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/account_live.ex` — Current account health route.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/settings_live.ex` — Current profile/settings route.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/admin_access_live.ex` — Existing blocked admin/member-access proof state.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex` — Host-owned SaaS session and role helpers.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/on_mount.ex` — LiveView auth assignment boundary.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up*.ex` and `examples/phoenix_host/lib/crosswake_example/saas_portal/handoff*.ex` — Existing Sigra/auth-pressure helpers to reuse carefully without overclaiming provider/native MFA.

### Existing Tests and Proof Patterns
- `examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs` — Route metadata drift, support-label allowlist, and compiled router truth tests.
- `examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs` — Reset idempotency and deterministic count/digest proof pattern.
- `examples/phoenix_host/test/crosswake_example/showcase/hub_live_test.exs` — Showcase rendering and visible support-label pattern.
- `examples/phoenix_host/test/crosswake_example/e2e/showcase_reset_controller_test.exs` — Reset endpoint proof pattern.
- `examples/phoenix_host/e2e/route_tour.spec.ts` — Browser route-tour semantic proof and screenshot evidence pattern.
- `examples/phoenix_host/test/crosswake_example/page_title_test.exs` — AdminPilot page-title expectations.

### Crosswake Concept Guides
- `guides/adopter_profiles.md` — Phoenix SaaS Portal profile and explicit non-goals.
- `guides/user_flows.md` — Canonical Phoenix SaaS job: keep the main product Phoenix-owned on mobile.
- `guides/web_to_mobile_migration.md` — Route inventory guidance: default SaaS routes to LiveView, promote only for explicit owner reasons.
- `guides/route_policy.md` — Route owner decisions and LiveView/bridge/auth/cache examples.
- `guides/bridge.md` — Bounded bridge envelope, low-frequency semantics, and denial reasons.
- `guides/capabilities.md` — Ownership-first capability-family rubric and no plugin-catalog rule.
- `guides/support_matrix.md` — Canonical support truth labels and proof classes.
- `guides/native_shell.md` — Manifest-first activation, route-unavailable posture, and native-shell boundaries.
- `guides/compatibility.md` — Runtime-line/rebuild guidance to link from support truth if needed.

### Prompt Research to Apply
- `prompts/crosswake-research-synthesis.md` — Current architecture thesis and anti-patterns.
- `prompts/crosswake-elixir-oss-dna.md` — Maintainer OSS style: install truth, support honesty, proof lanes, operator surfaces, and release truth.
- `prompts/crosswake-integrations-and-companions.md` — Sigra/Threadline/companion classification and example/docs-only boundaries.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` — B2B SaaS/admin fit, sensitive-cache footguns, and validation-example rationale.
- `prompts/elixir-mobile-oss-lib-deep-research.md` — Elixir/Phoenix architecture lessons, LiveView mobile-awareness restraint, bridge/offline/testing/DX footguns, and final restraint recommendation.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `CrosswakeExample.SaaSPortal.*` already provides the initial dashboard, account, approvals, approval detail, settings, admin access, auth, step-up, and handoff modules.
- `CrosswakeExample.Showcase.Branding` already locks AdminPilot as the SaaS/Admin app identity with a fixture brief.
- `CrosswakeExample.Showcase.Catalog` already owns product-facing route-card metadata and tests it against compiled router metadata.
- `CrosswakeExample.Showcase.Reset` already orchestrates deterministic lane reset and digest truth.
- `examples/phoenix_host/e2e/route_tour.spec.ts` already proves route-owner semantics before screenshots.
- `brandbook/BRAND-SPEC.md` plus token CSS already provide badge, route-card, microcopy, color, dark-mode, and accessibility constraints.

### Established Patterns
- Example-host lanes are proof artifacts and product-shaped demos, not core Crosswake APIs.
- Route metadata and support labels should be mechanically tested against compiled route policy where possible.
- SaaS/admin routes already default to `runtime: :live_view`, mostly `offline: :cached_read_only`, and Phoenix-owned auth via `:saas_portal` pipeline and LiveView `on_mount`.
- Sensitive/admin route posture already exists through `saas-admin-member-access` with `offline: :unavailable`, `security: :sensitive`, `auth_min_level: :mfa`, and `requires_recent_auth: 300`.
- The approval detail route already declares `capabilities: ["haptics.impact"]`, making it the right bounded-bridge example if the planner keeps haptics secondary to server success.

### Integration Points
- Expand `SaaSPortal.Fixtures` or add lane-local fixture modules for teams/roles/activity/settings.
- Add shared AdminPilot layout/components for app chrome, route badges, workflow actions, records, activity, and diagnostics.
- Add or refine `SaaSPortal` context functions for scoped approval listing/approval mutation and activity/audit records.
- Extend `Showcase.Reset` counts/digest if new persistent approval/activity state is added.
- Extend `Catalog`/route metadata tests or add a SaaS lane catalog so diagnostics cannot drift from router truth.
- Extend LiveView tests and Playwright route tour to cover the actual approval workflow and diagnostics/support inspection.

</code_context>

<specifics>
## Specific Ideas

- Recommended lane narrative: "AdminPilot keeps daily admin work Phoenix-owned; Crosswake makes the mobile route owner, cache posture, and native boundary inspectable."
- Recommended dashboard sections: account health, pending approvals, team/member role snapshot, recent activity, security/admin pressure card, and route/support diagnostics entry.
- Recommended approval queue: resource list/table on desktop, stacked list on mobile, status labels, requested-by/reviewer metadata, and clear links to approval detail.
- Recommended approval detail: record summary, server-authoritative action, disabled/loading state, success status, optional haptics confirmation payload disclosure, and route/support badges.
- Recommended admin pressure: member-access route or card that shows "MFA required / recent auth required / server authority" and a blocked state when the session lacks step-up.
- Recommended diagnostics panel: per-route matrix with route path/id, owner, offline posture, security/auth posture, capability, support label, failure/fallback, and guide links.
- External ecosystem lessons considered:
  - Phoenix contexts group data access/validation and keep LiveViews/controllers from owning business logic; Phoenix scopes emphasize current user/org/permissions as security-critical request/session context.
  - LiveView form/event docs and LiveViewTest favor server-handled events, `handle_event/3`, `phx-submit`/`phx-click`, and fast process-level tests before heavy browser proof.
  - Django admin and Shopify Polaris reinforce list/detail/action workflows for admin jobs; broad resource consoles are useful but can become product-defining if allowed to sprawl.
  - Hotwire Native path configuration reinforces route/path behavior as a first-class configuration surface, but Crosswake should keep Phoenix route policy as the authoritative source.
  - Design systems such as Polaris and Atlassian separate status labels/actions from implementation details; Crosswake should do the same with text badges and lane diagnostics.

</specifics>

<deferred>
## Deferred Ideas

- A generic AdminPilot admin framework, resource DSL, or broad CRUD console belongs outside Phase 149.
- A dedicated URL-addressable route inspector or `crosswake_dashboard`-like surface remains deferred to Phase 152 capability-map work or future DASH-01.
- Production MFA, passkeys, SSO/OIDC, native auth UI, or provider-specific authentication flows remain outside Phase 149; use existing example-host Sigra pressure only as honest context.
- New native controls such as menus, alerts, share sheet, scanner, permissions UX, or native action bars remain v20+ unless already shipped and route-declared.
- Full local-first admin mutation, outboxes, journals, reconciliation, or offline approval writes are out of scope; cached read-only must stay visibly read-only.
- Field-service and learning/training lane depth remains Phases 150 and 151.

</deferred>

---

*Phase: 149-SaaS/Admin Showcase*
*Context gathered: 2026-07-10*
