# Phase 149: SaaS/Admin Showcase - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-10
**Phase:** 149-SaaS/Admin Showcase
**Areas discussed:** AdminPilot Lane Shape, Representative Admin Workflow, Auth/Admin Posture Visibility, Diagnostics and Support Truth Placement

---

## AdminPilot Lane Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Focused approvals workspace | Dashboard, queue, approval detail, account/team/role context, and one complete Phoenix-owned admin workflow. | ✓ |
| Broader admin console | Wider accounts/teams/roles/settings CRUD surface with familiar admin-console breadth. | |
| Diagnostics-heavy operator console | Route policy, support truth, and proof posture as the main UI. | |

**User's choice:** User requested a one-shot recommendation after subagent research across all areas.
**Notes:** Research favored a focused approvals workspace because it matches existing `/saas` code, the Phoenix SaaS Portal profile, and SAAS-04 without drifting into a generic admin framework. The breadth needed for SAAS-01 should come from fixture/context density rather than CRUD sprawl.

---

## Representative Admin Workflow

| Option | Description | Selected |
|--------|-------------|----------|
| Approve request with bounded haptics | Complete an approval in LiveView; optional haptics follows successful server authority. | ✓ |
| Review/stage member access with MFA pressure | Make role/member access and step-up pressure the primary workflow. | |
| Inspect account health | Read-only account/workspace inspection. | |
| Route-policy diagnostics walkthrough | Make route/support inspection the workflow. | |

**User's choice:** User requested a one-shot recommendation after subagent research across all areas.
**Notes:** Research favored approval review/approval as the happy path because it is already represented in code, is easy to prove with LiveView tests and Playwright, and naturally demonstrates bounded bridge semantics without native mutation authority. Member-access/step-up remains adjacent security pressure, not the primary workflow.

---

## Auth/Admin Posture Visibility

| Option | Description | Selected |
|--------|-------------|----------|
| Subtle posture badges | Show MFA/recent-auth/server-authority truth mostly through labels. | |
| Explicit blocked-admin route | Use the denied admin/member-access route as the main proof state. | |
| Guided auth-pressure story | Combine normal admin work, badges, and a blocked admin state to explain backend authority. | ✓ |

**User's choice:** User requested a one-shot recommendation after subagent research across all areas.
**Notes:** Research favored a guided auth-pressure story because badge-only UI is too easy to miss and a standalone blocked route feels like a dead end. The lane should show normal authenticated work first, then an adjacent admin/security pressure state that proves shell/device evidence is not backend authority.

---

## Diagnostics and Support Truth Placement

| Option | Description | Selected |
|--------|-------------|----------|
| Inline per-page badges | Compact route/runtime/offline/support labels on each page. | ✓ baseline |
| Lane diagnostics panel | AdminPilot-scoped route/support matrix with guide links and rough-edge notes. | ✓ primary |
| Dedicated inspector route | URL-addressable manifest/route-policy inspector route. | |
| Support-matrix/docs linkout | Rely mostly on docs links for route/support truth. | ✓ secondary |

**User's choice:** User requested a one-shot recommendation after subagent research across all areas.
**Notes:** Research favored a lane-local diagnostics panel as the primary truth surface, with inline badges for point-of-use context and docs links for canonical detail. A dedicated inspector route is deferred because it risks becoming `crosswake_dashboard` or Phase 152 capability-map scope.

---

## Claude's Discretion

- The user explicitly asked the agent to synthesize recommendations so they do not need to choose among options manually.
- The planner may decide exact module/component names and whether approval/activity persistence is worth adding.
- The planner may refine layout and copy under the brandbook and AdminPilot fixture brief.

## Deferred Ideas

- Generic admin framework or broad CRUD console.
- Dedicated route inspector / `crosswake_dashboard` surface.
- Production MFA/passkey/SSO/native-auth provider flow.
- New native-control APIs.
- Local-first admin mutation or offline approval writes.
