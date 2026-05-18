# Crosswake Example Host Lanes

The checked-in Phoenix host is the primary exemplar artifact class for Crosswake.
Phases 7-10 extend this host, plus the paired iOS and Android example hosts, instead
of creating three separate sample applications. Route, module, fixture, and proof-lane
boundaries carry profile isolation inside one shared artifact class.

Read [guides/adopter_profiles.md](/Users/jon/projects/crosswake/guides/adopter_profiles.md)
for the public adopter-fit matrix. This README locks the host-local execution
contract that downstream exemplar phases must extend.

## Shared Artifact Rules

- Keep one shared Phoenix host under `examples/phoenix_host`.
- Keep the checked-in iOS and Android hosts as paired proof artifacts of that same
  shared host.
- Add profile-specific routes, modules, fixtures, and proof checks inside the shared
  host instead of multiplying into separate sample apps.
- Use small secondary fixtures only if a later proof lane genuinely needs tighter
  hermetic isolation.
- Do not turn the example host into a kitchen-sink demo or a copy-paste product surface.

## Profile Lane Contract

| Profile | Job to be done | Route budget | Primary route classes | Route and module boundary | Fixture boundary | Primary failure vocabulary focus | Explicit non-goals |
|---------|----------------|--------------|-----------------------|---------------------------|------------------|----------------------------------|--------------------|
| Phoenix SaaS Portal | Review account health and approve routine work from a mobile shell without leaving Phoenix ownership | 4-6 routes | Mostly `:live_view` | `CrosswakeExample.SaaSPortal.*` routes stay shell-hosted, authenticated, and Phoenix-owned | Reuse one account, two host-owned auth users, and a small approvals queue; no pack-heavy media fixture | `route unavailable` | No packs as the main pressure, no offline island lane, no native capture lane, no billing abstraction |
| Selective Native Flow | Capture one device-heavy artifact while the surrounding product remains Phoenix-owned | 4-6 routes | `:live_view` plus one `:native_screen` | `CrosswakeExample.SelectiveNative.*` isolates the capture route, handoff route, and review route | Keep capture fixtures route-local and generic; no entitlement or vendor fixtures | `pack_incompatible` | No billing or entitlement system, no multiple native-screen families, no generic upload fallback |
| Local-First Study Flow | Complete one study session offline, then replay explicitly when connectivity returns | 5-8 routes | Cached `:live_view` plus one `:offline_island` | `CrosswakeExample.LocalFirstStudy.*` isolates study-session and replay-adjacent routes | Keep lesson and review fixtures generic; no collaborative sync dataset | `conflict requires attention` | No broad CRUD sync, no background-sync promise, no media-heavy offline transfer, no second offline-island story |

## Lane Details

### Phoenix SaaS Portal

Representative routes:

- `/saas/dashboard`
- `/saas/accounts/:id`
- `/saas/approvals`
- `/saas/approvals/:id`
- `/saas/settings/profile`

Required seams:

- manifest-first activation
- denial UI for fail-closed route handling
- one low-frequency bounded bridge affordance on the approval-detail route

This lane exists to pressure shell activation honesty and authenticated
`:live_view` behavior without turning the example host into a generic wrapper.
Auth stays host-owned example code. Crosswake does not provide a SaaS auth surface.

Supported behavior:

- authenticated `:live_view` routes stay Phoenix-owned inside the shell
- one bounded approval confirmation signal reaches the shell through the declared
  haptics seam
- denial stays explicit through `route unavailable` rather than a silent fallback

Degraded behavior:

- if activation or compatibility checks fail, the shell denies the route instead of
  opening a generic container
- if the shell cannot honor the bounded haptics request, the approval still completes
  on the Phoenix side without turning the bridge into a control surface

Deferred behavior:

- identity-provider integrations, SSO, MFA, passkeys, and token choreography
- offline writes, queued approvals, or local-first mutation semantics
- packs, transfer-first flows, and native-screen ownership as the main SaaS story

Read [guides/adopter_profiles.md](/Users/jon/projects/crosswake/guides/adopter_profiles.md)
for the public profile framing, [guides/native_shell.md](/Users/jon/projects/crosswake/guides/native_shell.md)
for shell denial and bridge behavior, and keep
[guides/support_matrix.md](/Users/jon/projects/crosswake/guides/support_matrix.md)
plus [guides/install.md](/Users/jon/projects/crosswake/guides/install.md) as the
canonical support and proof surfaces.

### Selective Native Flow

Representative routes:

- `/native/claims`
- `/native/claims/:id`
- `/native/claims/:id/capture`
- `/native/submissions/:id/review`

Required seams:

- one explicit `:native_screen` route for capture
- route-local required packs
- route-local explicit `:camera` capability
- route-local `transfer.upload.prepare` seam
- explicit sensitive-route handling for the capture corridor

This lane exists to pressure fail-closed native ownership, pack-gating, and transfer handoff
without widening into a broad native capability surface. The surrounding workflow stays Phoenix-owned.

Supported behavior:

- native capture remains bounded to one specific route inside the claims-evidence corridor
- media stays staged and captured locally until explicit Phoenix review before upload triggers the transfer seam
- surrounding `/native` routes do not inherit capability or pack requirements

Degraded behavior:

- if the shell lacks the requested camera media pack, the capture route denies activation with `pack_incompatible`
- non-capture routes stay fully usable even if the capture pack is absent or incompatible

Deferred behavior:

- background uploads without user confirmation, silent retries, or implicit submission
- generic capability-bus or workflow-bus semantics where the shell drives the interaction
- generic file pickers or cross-app sharing as the primary media path

### Local-First Study Flow

Representative routes:

- `/study/library`
- `/study/lesson/:id`
- `/study/session`
- `/study/session/history`
- `/study/sync-status`

Required seams:

- one explicit `:offline_island`
- cached read-only neighboring routes
- durable journal and outbox replay
- explicit replay outcomes

This lane exists to pressure the difference between cached read-only behavior and
true local-first ownership without widening into a generic sync framework.

## Proof Extension Rules

- Extend the checked-in example-host proof posture instead of replacing it.
- Keep `script/verify_phase5_example_hosts.sh` as the base example-host proof entrypoint.
- Add later profile checks as lane-boundary assertions, route assertions, and doc-alignment
  assertions that layer on top of the existing proof system.
- Keep public support and proof status in the existing guides, especially
  [guides/support_matrix.md](/Users/jon/projects/crosswake/guides/support_matrix.md)
  and [guides/install.md](/Users/jon/projects/crosswake/guides/install.md).
