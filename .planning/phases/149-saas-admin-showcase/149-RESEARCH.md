# Phase 149: SaaS/Admin Showcase - Research

**Researched:** 2026-07-10
**Domain:** Phoenix LiveView SaaS/admin showcase, route-policy diagnostics, server-authoritative admin workflow
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### the agent's Discretion
- The planner may choose exact module/component names, whether approval/activity persistence is worth the added Ecto surface, and whether diagnostics live in a reusable component or a lane-specific helper.
- The planner may keep deterministic maps for static data if tests prove realistic density and reset truth.
- The planner may refine copy and layout as long as it preserves the decisions above and the brandbook constraints.

### Deferred Ideas (OUT OF SCOPE)

## Deferred Ideas

- A generic AdminPilot admin framework, resource DSL, or broad CRUD console belongs outside Phase 149.
- A dedicated URL-addressable route inspector or `crosswake_dashboard`-like surface remains deferred to Phase 152 capability-map work or future DASH-01.
- Production MFA, passkeys, SSO/OIDC, native auth UI, or provider-specific authentication flows remain outside Phase 149; use existing example-host Sigra pressure only as honest context.
- New native controls such as menus, alerts, share sheet, scanner, permissions UX, or native action bars remain v20+ unless already shipped and route-declared.
- Full local-first admin mutation, outboxes, journals, reconciliation, or offline approval writes are out of scope; cached read-only must stay visibly read-only.
- Field-service and learning/training lane depth remains Phases 150 and 151.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SAAS-01 | User can click through a SaaS/admin domain with realistic accounts, teams, roles, settings, and operational records. | Expand `SaaSPortal.Fixtures` density and render account/team/role/settings/activity context around the approval path. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/fixtures.ex] |
| SAAS-02 | User can see LiveView-first route ownership and auth-sensitive/admin posture represented clearly in the SaaS lane. | Reuse the existing `/saas` route metadata, `Auth`, and `OnMount` boundaries; add persistent badges and admin-pressure UI without moving authority to native. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex] |
| SAAS-03 | User can inspect route policy, diagnostics, and support truth from the SaaS lane without leaving ambiguity about native ownership. | Build a lane-local diagnostics/support panel from compiled `RouterMetadata` plus a small tested SaaS route catalog. [VERIFIED: lib/crosswake/policy/router_metadata.ex] [VERIFIED: examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs] |
| SAAS-04 | User can complete a representative admin workflow that demonstrates Crosswake's Phoenix-first value without requiring new native-control APIs. | Make approval review/approve the only required mutation path; optional haptics must happen after server success and be degradable. [VERIFIED: .planning/phases/149-saas-admin-showcase/149-CONTEXT.md] [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Preserve Crosswake as a Phoenix-first route-policy and runtime-contract system, not a universal UI framework. [VERIFIED: AGENTS.md]
- Keep runtime ownership explicit per route; do not collapse the design into generic WebView wrapper behavior or LiveView-driven native rendering. [VERIFIED: AGENTS.md]
- Treat bridge contracts as semantic, typed, versioned, and low-frequency; flows needing continuous client authority should move toward offline islands or native screens. [VERIFIED: AGENTS.md]
- Keep offline claims honest by distinguishing cached read-only behavior from true local-first mutation with journals, outboxes, and reconciliation. [VERIFIED: AGENTS.md]
- Treat diagnostics, support matrices, proof lanes, and rough-edge documentation as product surface. [VERIFIED: AGENTS.md]
- Respect v1 scope boundaries from `.planning/PROJECT.md` and `.planning/REQUIREMENTS.md` before adding integrations or wider native breadth. [VERIFIED: AGENTS.md]
- No local `CLAUDE.md`, `.claude/CLAUDE.md`, `.claude/skills`, or `.agents/skills` files were found for additional project directives. [VERIFIED: filesystem]

## Summary

Phase 149 should be planned as a normal Phoenix product slice inside the existing example host: enrich the `CrosswakeExample.SaaSPortal` context, fixtures, LiveViews, HEEx components, CSS, tests, and Playwright route tour; do not add an admin framework, native-control API, or route inspector. [VERIFIED: .planning/phases/149-saas-admin-showcase/149-CONTEXT.md] [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal]

The current `/saas` router already has the core route-policy proof surface: six SaaS routes, all `:live_view`; five are `:cached_read_only`; `/saas/admin/member-access` is `:sensitive` and `:unavailable`; `/saas/approvals/:id` declares `haptics.impact`. [VERIFIED: `mix run --no-start` route metadata extraction] The main implementation gap is product depth and proof: richer fixture data, an approval workflow that survives refresh if persistence is chosen, route-derived diagnostics, and focused tests. [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/fixtures.ex] [VERIFIED: examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs]

**Primary recommendation:** Build a focused AdminPilot approvals workspace with lane-local components and diagnostics derived from compiled route metadata; persist only approval/activity rows if the planner wants refresh-proof mutation evidence. [VERIFIED: .planning/phases/149-saas-admin-showcase/149-CONTEXT.md] [CITED: https://phoenix.hexdocs.pm/contexts.html] [CITED: https://ecto.hexdocs.pm/Ecto.Multi.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| AdminPilot navigation and page rendering | Frontend Server (Phoenix LiveView) | Browser / Client | Existing SaaS routes are Phoenix LiveViews and should remain server-rendered with normal links/events. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] |
| Approval review and approval mutation | API / Backend (Phoenix context + Ecto if persisted) | Frontend Server (LiveView event dispatch) | Phoenix owns the approval decision; LiveView handles `phx-click`, but context functions own authorization and mutation. [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/approvals.ex] [CITED: https://phoenix.hexdocs.pm/contexts.html] |
| Optional haptics confirmation | Native Shell bounded bridge | Frontend Server (post-success request emission) | The route declares `haptics.impact`, and bridge docs define low-frequency request/reply semantics; haptics cannot own mutation authority. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] [VERIFIED: guides/bridge.md] |
| Auth/admin posture | API / Backend + Frontend Server on_mount | Browser / Client display only | `Auth` and `OnMount` assign user/account state; UI renders posture badges and denial proof. [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex] [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/on_mount.ex] |
| Route policy diagnostics/support truth | Frontend Server (compiled router metadata) | Docs/support links | `RouterMetadata.fetch/1` exposes normalized route policy; diagnostics must not be prose-only. [VERIFIED: lib/crosswake/policy/router_metadata.ex] [VERIFIED: examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs] |
| Deterministic reset/digest | API / Backend | Database / Storage if mutable rows added | Existing reset delegates lane counts/digest; any SaaS persistent rows must be reseeded idempotently. [VERIFIED: examples/phoenix_host/lib/crosswake_example/showcase/reset.ex] [VERIFIED: examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs] |
| Responsive admin UI and accessibility | Browser / Client CSS + semantic HTML | Frontend Server markup | Existing `tokens.css`/`app.css` provide tokens, badges, focus, dark mode, and responsive patterns; WAI APG recommends native tables where possible for static tabular data. [VERIFIED: examples/phoenix_host/priv/static/css/app.css] [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/table/] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `crosswake` and first-party companions | `crosswake` 0.2.0 path dep; companions 0.1.x path deps | Route policy, bridge/support truth, Sigra auth pressure, Threadline/Chimeway/Rulestead/Rindle companion seams already adopted by the example host | Reuse existing Crosswake package-family proof surface; do not add a new dashboard or plugin system. [VERIFIED: `mix deps`] [VERIFIED: examples/phoenix_host/mix.exs] |
| `phoenix` | Locked 1.8.7; recent Hex release 1.8.9 on 2026-07-07 | Phoenix router, endpoint, LiveView host app | The phase is explicitly Phoenix-first; current code is Phoenix-native. [VERIFIED: `mix deps`] [VERIFIED: `mix hex.info phoenix`] |
| `phoenix_live_view` | Locked 1.1.30; docs/current release 1.2.6 | Server-rendered interactive SaaS pages and LiveView events | Existing `/saas` lane is LiveView; LiveView docs support server events, assigns, JS push loading, and LiveViewTest. [VERIFIED: `mix deps`] [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html] |
| `ecto_sql` + `ecto_sqlite3` | `ecto` 3.13.6, `ecto_sql` 3.13.5, `ecto_sqlite3` 0.23.0 | Optional persisted approval/activity rows and reset-proof mutation evidence | Existing example host already uses SQLite-backed Ecto for proof lanes; use it only if refresh-proof mutation evidence is worth the surface. [VERIFIED: `mix deps`] [VERIFIED: examples/phoenix_host/priv/repo/migrations] |
| `bandit` | 1.12.0 | Local Phoenix HTTP server | Existing endpoint runtime; no phase-specific change needed. [VERIFIED: `mix deps`] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `jason` | 1.4.5 | Encode bridge payloads, reset responses, and test diagnostics | Reuse for haptics payload and route-diagnostics JSON assertions if needed. [VERIFIED: `mix deps`] [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex] |
| `Phoenix.LiveViewTest` | From local `phoenix_live_view` 1.1.30 | Focused LiveView workflow tests | Add Wave 0/implementation tests for clicking approval actions and rendering success/error states. [VERIFIED: `mix deps`] [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveViewTest.html] |
| `@playwright/test` | Installed 1.60.0; npm latest 1.61.1 | Browser route tour and mobile/focus/overflow checks | Extend existing route tour for AdminPilot happy path and diagnostics visibility; do not upgrade during this phase. [VERIFIED: `npm list @playwright/test`] [VERIFIED: examples/phoenix_host/e2e/route_tour.spec.ts] |
| `typescript` | Installed 5.9.3; npm latest 7.0.2 | TypeScript support for Playwright tests | Reuse existing E2E tooling; no new TS dependency work is needed. [VERIFIED: `npm list typescript`] [VERIFIED: examples/phoenix_host/package.json] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Normal Phoenix contexts and LiveViews | A generic admin DSL/resource builder | Rejected by D-05; it would make the demo look like an admin framework instead of Crosswake route-policy proof. [VERIFIED: .planning/phases/149-saas-admin-showcase/149-CONTEXT.md] |
| Lane-local diagnostics component | Dedicated inspector route or `crosswake_dashboard` | Rejected by D-19/D-24; Phase 149 needs an inline AdminPilot panel, while dashboard/inspector work is deferred. [VERIFIED: .planning/phases/149-saas-admin-showcase/149-CONTEXT.md] |
| Optional post-success haptics | New native controls such as alerts, action bars, menus, share sheets, or scanner | Rejected by D-07/D-12 and deferred scope; existing haptics declaration is enough for SAAS-04. [VERIFIED: .planning/phases/149-saas-admin-showcase/149-CONTEXT.md] [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] |
| Deterministic fixture maps for static breadth | Persist every account/team/role/settings record | Use persistence only for approval/activity mutation proof; deterministic maps keep reset simple and align with D-08/D-10. [VERIFIED: .planning/phases/149-saas-admin-showcase/149-CONTEXT.md] |

**Installation:**

```bash
# No new package installation is recommended for Phase 149.
cd examples/phoenix_host
mix deps
npm list @playwright/test typescript --depth=0
```

**Version verification:** Local versions above were verified with `mix deps`, `mix hex.info phoenix`, `mix hex.info phoenix_live_view`, `mix hex.info ecto`, `npm list`, and `npm view`. [VERIFIED: terminal commands]

## Package Legitimacy Audit

Phase 149 should not install new external packages. [VERIFIED: .planning/phases/149-saas-admin-showcase/149-CONTEXT.md] Existing Node proof packages were checked because they appear in validation commands. [VERIFIED: package-legitimacy seam]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `@playwright/test` | npm | Created 2020-09-24; local installed 1.60.0 | 43.8M/week for latest package query | github.com/microsoft/playwright | SUS for latest only (`too-new`); no postinstall script | Reuse lockfile; do not upgrade during Phase 149. [VERIFIED: `npm view`] [VERIFIED: package-legitimacy seam] |
| `typescript` | npm | Created 2012-10-01; local installed 5.9.3 | 216.4M/week for latest package query | github.com/microsoft/TypeScript | SUS for latest only (`too-new`); no postinstall script | Reuse lockfile; do not upgrade during Phase 149. [VERIFIED: `npm view`] [VERIFIED: package-legitimacy seam] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: package-legitimacy seam]
**Packages flagged as suspicious [SUS]:** latest `@playwright/test` and latest `typescript` only; planner should not add upgrade/install tasks for them. [VERIFIED: package-legitimacy seam]

## Architecture Patterns

### System Architecture Diagram

```text
User opens /saas/dashboard
  -> Phoenix Router / :saas_portal pipeline
  -> SaaSPortal.Auth.fetch_current_user + LiveView OnMount assigns user/account
  -> DashboardLive renders AdminPilot shell, KPI strip, posture badges, diagnostics entry
  -> User opens approvals queue
  -> ApprovalsLive asks SaaSPortal context for scoped approvals
  -> User opens approval detail
  -> ApprovalLive renders record, route/support badges, action footer
  -> User clicks Approve
  -> handle_event("approve") calls SaaSPortal context with current user/account scope
       -> if unauthorized: return {:error, :forbidden} and render calm denial state
       -> if authorized: update approval + optional activity audit in one backend step
  -> LiveView renders success and disables/removes action
  -> optional bounded bridge haptics request is emitted after server success
       -> if bridge unavailable: route still shows approved server state and support truth
  -> Diagnostics panel reads compiled route metadata for all AdminPilot routes
       -> compares path/id/runtime/offline/entry/security/auth/capability/support/rough edge
```

### Recommended Project Structure

```text
examples/phoenix_host/lib/crosswake_example/saas_portal/
├── fixtures.ex              # deterministic account/team/member/role/settings/activity breadth
├── accounts.ex              # account/team/settings read context functions
├── approvals.ex             # scoped approval list/get/approve functions; optional Ecto transaction
├── diagnostics.ex           # lane-local route policy matrix derived from RouterMetadata
├── components.ex            # AdminPilot shell, badges, KPI strip, activity feed, diagnostics panel
├── dashboard_live.ex        # entry page: product-first overview and links
├── approvals_live.ex        # queue/list page
├── approval_live.ex         # detail/action page
├── account_live.ex          # account/team/role/settings context
├── settings_live.ex         # auth/admin posture page
└── admin_access_live.ex     # blocked/admin member-access proof state
```

```text
examples/phoenix_host/test/crosswake_example/saas_portal/
├── fixtures_test.exs        # SAAS-01 density, deterministic reset/digest support
├── diagnostics_test.exs     # SAAS-02/03 route metadata drift and support truth
├── approvals_test.exs       # SAAS-04 context-level authorization/mutation
└── approvals_live_test.exs  # SAAS-04 LiveView render/click/success/failure states
```

### Pattern 1: Context Owns Scoped Authorization And Mutation

**What:** Keep approval authorization and mutation in `CrosswakeExample.SaaSPortal.Approvals`, not in HEEx or ad hoc LiveView branches. [CITED: https://phoenix.hexdocs.pm/contexts.html] [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/approvals.ex]

**When to use:** Every list/get/approve function should accept current user/account or a scope struct and return `{:ok, value}` / `{:error, reason}`. [VERIFIED: .planning/phases/149-saas-admin-showcase/149-CONTEXT.md]

**Example:**

```elixir
# Source: Phoenix contexts docs + existing SaaSPortal.Approvals pattern.
def approve_approval(%Scope{user: user, account: account}, approval_id) do
  with true <- Auth.approver?(user),
       approval <- get_approval_for_account!(account.id, approval_id),
       {:ok, approved} <- persist_or_update_fixture_approval(approval, user) do
    {:ok, approved}
  else
    false -> {:error, :forbidden}
  end
end
```

### Pattern 2: Diagnostics Derive From Compiled Router Metadata

**What:** Build a SaaS route matrix by reading `Phoenix.Router.routes()` and `RouterMetadata.fetch/1`, then enrich with product support labels/rough edges from a tiny lane catalog. [VERIFIED: lib/crosswake/policy/router_metadata.ex] [VERIFIED: examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs]

**When to use:** Every diagnostics row and inline posture badge should be backed by route metadata or tested lane catalog data. [VERIFIED: .planning/phases/149-saas-admin-showcase/149-CONTEXT.md]

**Example:**

```elixir
# Source: existing CatalogTest compiled_route_map pattern.
def route_policy_rows(router \\ CrosswakeExample.Router) do
  router
  |> Phoenix.Router.routes()
  |> Enum.filter(&String.starts_with?(&1.path, "/saas"))
  |> Enum.flat_map(fn route ->
    case Crosswake.Policy.RouterMetadata.fetch(route.metadata) do
      {:ok, policy} -> [%{path: route.path, route_id: policy.id, policy: policy}]
      :error -> []
    end
  end)
end
```

### Pattern 3: Persist Only The Mutable Proof Trail If Needed

**What:** If refresh-proof approval matters, persist approval status and activity/audit rows only; keep accounts/teams/roles/settings as deterministic fixture maps. [VERIFIED: .planning/phases/149-saas-admin-showcase/149-CONTEXT.md]

**When to use:** Use Ecto when the user-visible workflow must survive reload/reset proof; otherwise deterministic maps are cheaper and clearer. [VERIFIED: examples/phoenix_host/lib/crosswake_example/showcase/reset.ex] [CITED: https://ecto.hexdocs.pm/Ecto.Multi.html]

**Example:**

```elixir
# Source: Ecto.Multi docs; existing codebase uses Repo.transaction(Ecto.Multi).
Ecto.Multi.new()
|> Ecto.Multi.update(:approval, Approval.changeset(approval, %{status: "approved", reviewed_by: user.id}))
|> Ecto.Multi.insert(:activity, ActivityEvent.approval_approved_changeset(approval, user))
|> Repo.transaction()
```

### Pattern 4: Haptics Is A Post-Success, Degradable Confirmation

**What:** Emit the bridge request only after Phoenix confirms the approval. [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex] [VERIFIED: guides/bridge.md]

**When to use:** Keep the current `haptics.impact` route declaration; do not add native action bars, alerts, or menus for Phase 149. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] [VERIFIED: .planning/phases/149-saas-admin-showcase/149-CONTEXT.md]

**Example:**

```elixir
# Source: existing ApprovalLive handle_event shape.
case Approvals.approve_approval(scope, approval.id) do
  {:ok, approved} ->
    {:noreply,
     assign(socket,
       approval: approved,
       approval_notice: "Approved. Phoenix recorded the decision.",
       bridge_request: haptics_request(approved.id)
     )}

  {:error, :forbidden} ->
    {:noreply, assign(socket, approval_error: "Approver role required.")}
end
```

### Anti-Patterns to Avoid

- **Generic admin DSL/resource builder:** D-05 forbids turning AdminPilot into a framework. Use ordinary modules/components. [VERIFIED: .planning/phases/149-saas-admin-showcase/149-CONTEXT.md]
- **Prose-only support truth:** D-21 requires route-derived diagnostics, not a shadow copy table. [VERIFIED: .planning/phases/149-saas-admin-showcase/149-CONTEXT.md]
- **Approval authority in haptics or native shell:** D-07 and bridge docs make native confirmation secondary. [VERIFIED: .planning/phases/149-saas-admin-showcase/149-CONTEXT.md] [VERIFIED: guides/bridge.md]
- **Offline mutation claims:** `/saas` routes are cached read-only or unavailable; no outbox/journal/reconciliation is in scope. [VERIFIED: route metadata extraction] [VERIFIED: guides/route_policy.md]
- **Adding state-changing controller routes casually:** The example `:browser` pipeline does not show the default Phoenix `:protect_from_forgery`; prefer LiveView events and existing session/on_mount boundaries for this phase. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] [CITED: https://phoenix.hexdocs.pm/security.html]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Route policy diagnostics | Regex/string parser over `router.ex` | `Phoenix.Router.routes()` + `Crosswake.Policy.RouterMetadata.fetch/1` | Compiled metadata is the authoritative route policy surface. [VERIFIED: lib/crosswake/policy/router_metadata.ex] |
| Admin resource framework | Generic CRUD/table/resource DSL | Normal Phoenix contexts, LiveViews, HEEx components | Phase 149 is a focused approvals workspace, not an admin framework. [VERIFIED: .planning/phases/149-saas-admin-showcase/149-CONTEXT.md] |
| Authorization checks in templates | HEEx conditionals as authority | `SaaSPortal.Auth`, `OnMount`, and context return values | Current project keeps user/account assignment in Plug/on_mount; Phoenix docs recommend context centralization. [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex] [CITED: https://phoenix.hexdocs.pm/contexts.html] |
| Bridge/native control surface | New JS bridge protocol or native API | Existing bounded bridge request envelope for `haptics.impact` | Bridge docs already define command/capability/route/origin/version checks and typed denials. [VERIFIED: guides/bridge.md] |
| Full offline admin sync | Local-first approvals, outbox, reconciliation | Cached read-only labels and server-authoritative approval | Phase context defers offline writes; route metadata is cached read-only/unavailable. [VERIFIED: .planning/phases/149-saas-admin-showcase/149-CONTEXT.md] [VERIFIED: route metadata extraction] |
| New visual framework | Tailwind/Polaris/Atlassian package install | Existing `tokens.css`, `app.css`, and AdminPilot brand classes | Phase 148 locked brand direction and local CSS already contains tokens/badges/responsive patterns. [VERIFIED: examples/phoenix_host/priv/static/css/app.css] [VERIFIED: .planning/phases/148-demo-app-brand-fixture-direction/148-VERIFICATION.md] |

**Key insight:** The valuable proof is not CRUD breadth; it is a believable SaaS workflow where Phoenix owns data/auth/approval, route policy is inspectable, and native remains a bounded after-success affordance. [VERIFIED: guides/adopter_profiles.md] [VERIFIED: guides/user_flows.md]

## Common Pitfalls

### Pitfall 1: Making Diagnostics A Shadow Source Of Truth

**What goes wrong:** The lane shows a route/support matrix that silently drifts from `router.ex`. [VERIFIED: examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs]

**Why it happens:** It is easy to hard-code friendly diagnostic copy after the UI is designed. [ASSUMED]

**How to avoid:** Derive route id/path/runtime/offline/entry/security/auth/capabilities from compiled router metadata and test the lane catalog against it. [VERIFIED: lib/crosswake/policy/router_metadata.ex]

**Warning signs:** A diagnostics row contains a path or capability not asserted in a route metadata test. [VERIFIED: examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs]

### Pitfall 2: Treating Haptics As Approval Authority

**What goes wrong:** UI copy or tests imply approval succeeds because the native shell confirmed it. [VERIFIED: .planning/phases/149-saas-admin-showcase/149-CONTEXT.md]

**Why it happens:** Haptics is visually satisfying and can look like the action result. [ASSUMED]

**How to avoid:** Set approved state from the Phoenix context result first; only then emit optional haptics, and show missing haptics as degradable support truth. [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex] [VERIFIED: guides/bridge.md]

**Warning signs:** A test fails when haptics is absent, or UI says "native approved". [VERIFIED: .planning/phases/149-saas-admin-showcase/149-CONTEXT.md]

### Pitfall 3: Socket-Only Mutation Cannot Prove Refresh Truth

**What goes wrong:** Approval appears approved until page reload, then returns to seeded pending data. [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex] [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/fixtures.ex]

**Why it happens:** Current `Approvals.approve/2` returns an updated map and does not persist it. [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/approvals.ex]

**How to avoid:** Either explicitly test that socket-only behavior is acceptable for the showcase, or persist only approval/activity rows and extend `Showcase.Reset.reset!()` digest/counts. [VERIFIED: .planning/phases/149-saas-admin-showcase/149-CONTEXT.md] [VERIFIED: examples/phoenix_host/lib/crosswake_example/showcase/reset.ex]

**Warning signs:** Playwright approves a record but a reload or route revisit shows the original pending fixture with no activity evidence. [ASSUMED]

### Pitfall 4: Cached Read-Only Looks Like Offline Mutation

**What goes wrong:** Users think approvals can be edited offline because badges say cached/offline without "read-only". [VERIFIED: guides/route_policy.md]

**Why it happens:** "Offline" copy is often overloaded in demos. [ASSUMED]

**How to avoid:** Use exact labels such as `Cached read-only` and avoid journal/outbox/replay language in AdminPilot. [VERIFIED: .planning/phases/149-saas-admin-showcase/149-CONTEXT.md] [VERIFIED: guides/support_matrix.md]

**Warning signs:** UI mentions queued approvals, local drafts, or reconciliation in the SaaS lane. [VERIFIED: .planning/phases/149-saas-admin-showcase/149-CONTEXT.md]

### Pitfall 5: Desktop Table Parity Breaks Mobile

**What goes wrong:** Diagnostics and approvals fit desktop but overflow on 390px mobile. [VERIFIED: examples/phoenix_host/e2e/route_tour.spec.ts]

**Why it happens:** Admin data density encourages wide tables. [ASSUMED]

**How to avoid:** Use real tables for static desktop diagnostics when appropriate, but switch to stacked labeled records on mobile and test no horizontal overflow. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/table/] [VERIFIED: examples/phoenix_host/e2e/route_tour.spec.ts]

**Warning signs:** Playwright `expectNoHorizontalOverflow` fails or badge/action text clips. [VERIFIED: examples/phoenix_host/e2e/route_tour.spec.ts]

## Code Examples

Verified patterns from official sources and local code:

### LiveView Event Dispatch To Context

```elixir
# Source: Phoenix.LiveView handle_event docs + existing ApprovalLive.
@impl true
def handle_event("approve", _params, socket) do
  scope = %{user: socket.assigns.current_saas_user, account: socket.assigns.current_saas_account}

  case Approvals.approve_approval(scope, socket.assigns.approval.id) do
    {:ok, approval} ->
      {:noreply, assign(socket, approval: approval, approval_notice: "Approved by Phoenix.")}

    {:error, :forbidden} ->
      {:noreply, assign(socket, approval_error: "Approver role required.")}
  end
end
```

### Route Metadata Diagnostics Row

```elixir
# Source: Crosswake.Policy.RouterMetadata and Showcase.CatalogTest.
def saas_route_rows(router \\ CrosswakeExample.Router) do
  router
  |> Phoenix.Router.routes()
  |> Enum.filter(&String.starts_with?(&1.path, "/saas"))
  |> Enum.map(fn route ->
    policy = Crosswake.Policy.RouterMetadata.fetch!(route.metadata)

    %{
      path: route.path,
      route_id: policy.id,
      runtime: policy.runtime,
      offline: policy.offline,
      entry: policy.entry,
      security: policy.security,
      auth_min_level: policy.auth_min_level,
      requires_recent_auth: policy.requires_recent_auth,
      capabilities: policy.capabilities
    }
  end)
end
```

### Deterministic Reset Digest Extension

```elixir
# Source: existing Showcase.Reset digest pattern.
def saas_admin_digest_components do
  [
    static_fixture_digest_components(),
    persisted_activity_digest_components()
  ]
  |> List.flatten()
  |> Enum.sort()
end
```

### Playwright Route-Tour Shape

```typescript
// Source: existing e2e/route_tour.spec.ts ownerMessage pattern.
async function proveAdminPilotApproval(page: Page) {
  await page.goto('/saas/approvals');
  await expect(page.getByRole('heading', { name: /Approvals/i })).toBeVisible();
  await page.getByRole('link', { name: /Quarterly spend increase/i }).click();
  await expect(page).toHaveTitle(/AdminPilot/);
  await page.getByRole('button', { name: /Approve request/i }).click();
  await expect(page.getByRole('status')).toContainText('Phoenix');
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Generic WebView/native wrapper framing | Route-by-route owner policy with LiveView/offline/native distinctions | Locked across Crosswake project docs before Phase 149 | SaaS/admin should prove Phoenix-owned LiveView routes, not native rendering. [VERIFIED: .planning/PROJECT.md] [VERIFIED: guides/route_policy.md] |
| Broad admin consoles as demo breadth | Focused approval workspace with dense contextual records | Phase 149 context gathered 2026-07-10 | Planner should deepen fixture context and one workflow, not build CRUD sprawl. [VERIFIED: .planning/phases/149-saas-admin-showcase/149-CONTEXT.md] |
| Prose support labels | Mechanically tested support labels and compiled route policy checks | Phase 147/148 foundation | SaaS diagnostics should follow `CatalogTest` drift-proof pattern. [VERIFIED: examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs] |
| Screenshot-first proof | Semantic route assertions before screenshots | Existing route tour | AdminPilot browser proof should assert route IDs/owners/happy path before visual collateral. [VERIFIED: examples/phoenix_host/e2e/route_tour.spec.ts] |
| `Repo.transaction/2` in current codebase | Ecto 3.14 docs now prefer `Repo.transact/2`, while local locked Ecto is 3.13.6 and code uses `Repo.transaction/1` | Ecto docs current as of 2026-07-10 | Preserve local `Repo.transaction(Ecto.Multi)` pattern unless a separate dependency update is planned. [VERIFIED: `mix deps`] [CITED: https://ecto.hexdocs.pm/Ecto.Repo.html] |

**Deprecated/outdated:**
- The SaaS fixture moduledocs still refer to a "Phase 7" example lane; planner should update stale comments while expanding the lane. [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/fixtures.ex] [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/approvals.ex]
- Current SaaS pages are plain markup and do not yet consume the locked AdminPilot brand depth beyond page titles; planner should add AdminPilot components/CSS without changing the Phase 148 brand direction. [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/dashboard_live.ex] [VERIFIED: .planning/phases/148-demo-app-brand-fixture-direction/148-VERIFICATION.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Some pitfall root causes are marked as inferred human/demo failure modes rather than tool-verified facts. | Common Pitfalls | Low; the mitigations are still verified against project constraints and code. |

## Open Questions

1. **Should approval/activity be persisted?**
   - What we know: D-08 allows persistence only for mutable approval/activity evidence, and current approval mutation is socket-only. [VERIFIED: .planning/phases/149-saas-admin-showcase/149-CONTEXT.md] [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/approvals.ex]
   - What's unclear: Whether refresh-proof mutation evidence is worth adding migrations/schemas in Phase 149. [VERIFIED: .planning/phases/149-saas-admin-showcase/149-CONTEXT.md]
   - Recommendation: Plan this as an explicit decision task; if Playwright reload proof is required, add minimal Ecto rows and reset integration. [CITED: https://ecto.hexdocs.pm/Ecto.Multi.html]
2. **Should diagnostics be lane-specific or reusable?**
   - What we know: D-19 constrains diagnostics to AdminPilot routes and D-24 forbids a dedicated inspector route. [VERIFIED: .planning/phases/149-saas-admin-showcase/149-CONTEXT.md]
   - What's unclear: Whether a reusable component will help Phases 150/151 without becoming `crosswake_dashboard`. [ASSUMED]
   - Recommendation: Use a lane-local module/component first; extract only shared badge/table helpers if Phase 150 repeats the exact need. [VERIFIED: .planning/phases/149-saas-admin-showcase/149-CONTEXT.md]
3. **Should LiveViewTest infrastructure be formalized?**
   - What we know: Existing tests use `ExUnit.Case` and direct ConnTest/renderer patterns; no `ConnCase` or LiveViewTest case template exists. [VERIFIED: examples/phoenix_host/test/test_helper.exs] [VERIFIED: examples/phoenix_host/test/crosswake_example]
   - What's unclear: Whether to add a reusable `ConnCase`/LiveCase now or keep tests local. [ASSUMED]
   - Recommendation: Add the smallest support needed for focused SaaS LiveView tests; avoid a broad test harness refactor. [VERIFIED: existing test structure]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Phoenix app/tests | Yes | 1.19.5 / OTP 28 | None needed. [VERIFIED: `elixir --version`] |
| Mix | Dependency/test commands | Yes | 1.19.5 / OTP 28 | None needed. [VERIFIED: `mix --version`] |
| SQLite | Ecto SQLite proof data | Yes | 3.51.0 | Use deterministic maps if persistence is skipped. [VERIFIED: `sqlite3 --version`] |
| Node.js | Playwright route tour | Yes | 22.14.0 | None needed. [VERIFIED: `node --version`] |
| npm | Playwright package scripts | Yes | 11.1.0 | None needed. [VERIFIED: `npm --version`] |
| Playwright CLI | E2E/browser proof | Yes | 1.60.0 local | ExUnit-only proof if browser unavailable, but Phase 149 requires route-tour extension. [VERIFIED: `npx playwright --version`] |
| Phoenix dev server port 4700 | Playwright webServer | Occupied during research | Existing process on port 4700 | Playwright config reuses existing server outside CI. [VERIFIED: failed `mix run`; VERIFIED: examples/phoenix_host/playwright.config.ts] |

**Missing dependencies with no fallback:**
- None found. [VERIFIED: environment probes]

**Missing dependencies with fallback:**
- None found. [VERIFIED: environment probes]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix; Playwright 1.60.0 for browser route tour. [VERIFIED: `mix deps`] [VERIFIED: `npm list @playwright/test`] |
| Config file | `examples/phoenix_host/playwright.config.ts`; ExUnit uses `examples/phoenix_host/test/test_helper.exs` and no custom case template. [VERIFIED: filesystem] |
| Quick run command | `cd examples/phoenix_host && mix test test/crosswake_example/saas_portal test/crosswake_example/showcase/catalog_test.exs test/crosswake_example/showcase/reset_test.exs` |
| Full suite command | `cd examples/phoenix_host && mix test` |
| Browser command | `cd examples/phoenix_host && npx playwright test e2e/route_tour.spec.ts` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| SAAS-01 | Fixture density includes accounts, teams, roles/members, settings, operational records, and activity | unit/render | `mix test test/crosswake_example/saas_portal/fixtures_test.exs -x` | No - Wave 0 [VERIFIED: filesystem] |
| SAAS-02 | LiveView route ownership and auth/admin posture badges render on SaaS pages | unit/integration | `mix test test/crosswake_example/saas_portal/diagnostics_test.exs -x` | No - Wave 0 [VERIFIED: filesystem] |
| SAAS-03 | Diagnostics/support panel derives rows from compiled router metadata | unit | `mix test test/crosswake_example/saas_portal/diagnostics_test.exs -x` | No - Wave 0 [VERIFIED: filesystem] |
| SAAS-04 | Approval happy path completes server-authoritatively and haptics is optional | unit + browser | `mix test test/crosswake_example/saas_portal/approvals_test.exs test/crosswake_example/saas_portal/approvals_live_test.exs -x` and `npx playwright test e2e/route_tour.spec.ts` | No SaaS tests yet; route tour exists and needs extension. [VERIFIED: filesystem] |

### Sampling Rate

- **Per task commit:** `cd examples/phoenix_host && mix test <focused SaaS/showcase files>` [VERIFIED: existing Mix test alias]
- **Per wave merge:** `cd examples/phoenix_host && mix test` [VERIFIED: examples/phoenix_host/mix.exs]
- **Phase gate:** `cd examples/phoenix_host && mix test` plus `cd examples/phoenix_host && npx playwright test e2e/route_tour.spec.ts` before `$gsd-verify-work`. [VERIFIED: examples/phoenix_host/playwright.config.ts]

### Wave 0 Gaps

- [ ] `examples/phoenix_host/test/crosswake_example/saas_portal/fixtures_test.exs` - covers SAAS-01 fixture density and reset digest components. [VERIFIED: filesystem]
- [ ] `examples/phoenix_host/test/crosswake_example/saas_portal/approvals_test.exs` - covers SAAS-04 context authorization and optional persistence. [VERIFIED: filesystem]
- [ ] `examples/phoenix_host/test/crosswake_example/saas_portal/approvals_live_test.exs` - covers SAAS-04 LiveView action states. [VERIFIED: filesystem]
- [ ] `examples/phoenix_host/test/crosswake_example/saas_portal/diagnostics_test.exs` - covers SAAS-02/03 route metadata drift and support truth. [VERIFIED: filesystem]
- [ ] `examples/phoenix_host/e2e/route_tour.spec.ts` - extend existing route tour to click `dashboard -> approvals -> detail -> approve -> diagnostics`. [VERIFIED: examples/phoenix_host/e2e/route_tour.spec.ts]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| ASVS v5 V6 Authentication | Yes | Keep auth/session authority backend-owned through existing SaaSPortal/Sigra helpers; do not fake provider MFA/native auth UI. [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex] [CITED: https://cheatsheetseries.owasp.org/IndexASVS.html] |
| ASVS v5 V7 Session Management | Yes | Preserve Plug/session/on_mount boundaries and existing step-up session renewal helpers. [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/on_mount.ex] [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex] |
| ASVS v5 V8 Authorization | Yes | Context functions must authorize with current user/account assigns, not user-supplied params. [CITED: https://phoenix.hexdocs.pm/security.html] [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/approvals.ex] |
| ASVS v5 V1/V2 Encoding, Sanitization, Validation, Business Logic | Yes | Use Ecto changesets for any persisted rows and Phoenix escaped HEEx for rendered fixture data; avoid `raw/1` for user data. [CITED: https://phoenix.hexdocs.pm/security.html] [CITED: https://ecto.hexdocs.pm/Ecto.Multi.html] |
| ASVS v5 V11 Cryptography | Limited | Do not add new crypto; reuse existing Phoenix.Token/Sigra helpers for step-up/handoff proof. [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/step_up.ex] [CITED: https://cheatsheetseries.owasp.org/IndexASVS.html] |
| ASVS v5 V16 Security Logging/Error Handling | Yes | Keep denial copy calm and safe; if adding activity/audit rows, store support refs and low-cardinality outcomes, not sensitive identity secrets. [VERIFIED: guides/support_matrix.md] [VERIFIED: packages/crosswake_sigra/lib/crosswake/companions/sigra/telemetry.ex] |

### Known Threat Patterns For Phoenix LiveView Admin Lane

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Role spoofing through request params | Elevation of privilege | Use `current_saas_user`/account assigns from Plug/on_mount and context-level role checks. [CITED: https://phoenix.hexdocs.pm/security.html] [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex] |
| Approval mutation via GET/controller endpoint | Tampering / CSRF | Keep approval mutation as a LiveView event or, if adding controller POSTs, add explicit CSRF review because current `:browser` pipeline does not show `:protect_from_forgery`. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] [CITED: https://phoenix.hexdocs.pm/security.html] |
| SQL injection in persisted diagnostics/activity | Tampering / information disclosure | Use Ecto queries/changesets and parameterized operations; avoid interpolated raw SQL. [CITED: https://phoenix.hexdocs.pm/security.html] |
| Sensitive admin denial leakage | Information disclosure | Render short user-facing denial text and support refs, not raw denial details. [VERIFIED: .planning/phases/149-saas-admin-showcase/149-CONTEXT.md] [VERIFIED: guides/support_matrix.md] |
| Haptics/native bridge becoming mutation authority | Spoofing / tampering | Emit haptics only after server success and handle missing/denied capability as degradable support truth. [VERIFIED: guides/bridge.md] [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/149-saas-admin-showcase/149-CONTEXT.md` - locked decisions, discretion, deferred scope. [VERIFIED: file read]
- `.planning/REQUIREMENTS.md` - SAAS-01..04 requirement text and v19 scope. [VERIFIED: file read]
- `.planning/PROJECT.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` - Crosswake thesis, v19 roadmap, current state. [VERIFIED: file read]
- `AGENTS.md` - project-specific constraints. [VERIFIED: file read]
- `examples/phoenix_host/lib/crosswake_example/router.ex` - existing SaaS route declarations and route policy. [VERIFIED: codebase grep]
- `examples/phoenix_host/lib/crosswake_example/saas_portal/*` - current SaaS fixtures, auth, contexts, LiveViews, step-up/handoff helpers. [VERIFIED: codebase grep]
- `examples/phoenix_host/lib/crosswake_example/showcase/*` and showcase tests - catalog/reset/brand proof patterns. [VERIFIED: codebase grep]
- `examples/phoenix_host/e2e/route_tour.spec.ts` - browser route-tour proof pattern. [VERIFIED: codebase grep]
- `guides/route_policy.md`, `guides/bridge.md`, `guides/support_matrix.md`, `guides/adopter_profiles.md`, `guides/user_flows.md`, `guides/web_to_mobile_migration.md` - Crosswake route-owner/support truth. [VERIFIED: file read]

### Secondary (MEDIUM confidence)

- Phoenix contexts docs: https://phoenix.hexdocs.pm/contexts.html - context boundaries and centralization. [CITED: official docs]
- Phoenix security docs: https://phoenix.hexdocs.pm/security.html - authorization, CSRF, SQL injection, XSS guidance. [CITED: official docs]
- Phoenix LiveView docs: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html, https://phoenix-live-view.hexdocs.pm/bindings.html, https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.JS.html, https://phoenix-live-view.hexdocs.pm/Phoenix.LiveViewTest.html - events, lifecycle, JS push/loading, testing. [CITED: official docs]
- Ecto docs: https://ecto.hexdocs.pm/Ecto.Multi.html and https://ecto.hexdocs.pm/Ecto.Repo.html - transaction/multi patterns. [CITED: official docs]
- W3C WAI APG table pattern: https://www.w3.org/WAI/ARIA/apg/patterns/table/ - static tables vs grid guidance. [CITED: official docs]
- W3C WCAG target-size guidance: https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html - touch target accessibility context. [CITED: official docs]
- OWASP ASVS index: https://cheatsheetseries.owasp.org/IndexASVS.html - ASVS v5 category mapping. [CITED: OWASP docs]

### Tertiary (LOW confidence)

- Human-factor pitfall causes marked `[ASSUMED]` in Common Pitfalls and Open Questions. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - local versions verified with `mix deps`, `mix hex.info`, `npm list`, and `npm view`; no new packages recommended. [VERIFIED: terminal commands]
- Architecture: HIGH - existing `/saas` route policy, Auth/OnMount boundaries, and showcase proof patterns were inspected directly. [VERIFIED: codebase grep]
- Pitfalls: MEDIUM - most mitigations are code/docs verified; some root-cause explanations are inferred and tagged `[ASSUMED]`. [VERIFIED: codebase grep] [ASSUMED]

**Research date:** 2026-07-10
**Valid until:** 2026-08-09 for codebase-specific findings; 2026-07-17 for package/latest-version facts because Phoenix/LiveView/Ecto and Node packages are actively moving. [VERIFIED: `mix hex.info`; VERIFIED: `npm view`]
