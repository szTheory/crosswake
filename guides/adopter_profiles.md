# Crosswake Adopter Profiles

Crosswake fits teams that want explicit runtime ownership per route instead of one
runtime pretending to own every mobile surface. This guide helps you pick the
product shape that best matches your app pressure, then routes you to the existing
support and contract guides for exact proof and behavior details.

If you want the quickest narrative ramp-up before reading the matrix, start with
[guides/user_flows.md](user_flows.md).

Read [guides/install.md](install.md) for the
checked-in example-host install path, [guides/commerce.md](commerce.md) for the commerce boundaries, and
[guides/support_matrix.md](support_matrix.md)
for the canonical support-status surface.

## Adopter Profile Matrix

| Profile | Product shape | Primary route classes | Runtime ownership expectation | Required seams | What it pressures | Explicit non-goals |
|---------|---------------|-----------------------|-------------------------------|----------------|-------------------|--------------------|
| Phoenix SaaS Portal | Server-centric authenticated product surface | Mostly `:live_view` routes inside the shell | Phoenix stays server-owned for the main product flow, with one narrow native affordance | Manifest-first activation, denial UI, bounded bridge capability | Shell truth, route activation honesty, authenticated LiveView behavior, support clarity for server-centric mobile surfaces | Packs as the main story, offline islands, native capture, broad transfers, billing abstractions, plugin-style capability breadth |
| Selective Native Flow | Mostly Phoenix-owned app with one narrow device-heavy route | `:live_view` surrounding routes plus one `:native_screen` route | One route moves into explicit native ownership while surrounding routes stay manifest-driven | Required packs, route-local transfer seams, native capture handoff, route-local sensitivity | Fail-closed native ownership, pack availability, transfer preparation, route-local security posture | Billing systems, entitlement platforms, multiple native-screen categories, generic upload fallback, broad permission brokers |
| Local-First Study Flow | Study or training flow with meaningful offline work | Cached `:live_view` neighbors plus one `:offline_island` | One route owns local-first work while nearby reads stay explicitly cached and server-authoritative | Journal and outbox durability, replay outcomes, cached read-only route posture, route-local offline states | Cached-versus-local-first truth, replay vocabulary, conflict handling, rough-edge honesty for offline work | Broad CRUD sync, collaborative sync, background-sync guarantees, media-heavy offline transfer, multiple offline-island stories |

## The Attach Requirement

Read this before picking a profile. It is the one install-time failure every adopter who
uses the bounded bridge hits exactly once, on their first push, in whichever profile they
chose.

Any LiveView that calls `Crosswake.Bridge.push/3` must first have called
`Crosswake.Bridge.attach/1` on its socket, with `:crosswake_manifest` and
`:crosswake_route_id` already assigned. A socket that never attached raises a named
`Crosswake.Bridge.NotMountedError` on the first push — loudly, in every environment,
rather than silently doing nothing. Crosswake never guesses a route id, so the alternative
would be a no-op that looks like a working bridge until someone runs the app in a real
shell.

Fix it once at `mount/3` and it stays fixed:

```elixir
socket
|> assign(crosswake_manifest: MyAppWeb.Crosswake.Policy.manifest(), crosswake_route_id: "saas-approval")
|> Crosswake.Bridge.attach()
```

`on_mount: Crosswake.Bridge` works too, provided it runs after whatever hook assigns those
two — `on_mount` hooks in a `live_session` run in declared order. Full contract in
[guides/bridge.md](bridge.md#attach-first--push3-raises-on-a-socket-that-never-did).

Per profile:

- **Phoenix SaaS Portal** — attach on the one approval-detail route that requests haptics.
  The surrounding dashboard, accounts, and settings routes push nothing and need nothing.
- **Selective Native Flow** — attach on every `:live_view` route that dispatches a
  transfer-backed seam such as `transfer.upload.prepare`. The `:native_screen` capture
  route does not use the LiveView bridge at all, so it has no attach step.
- **Local-First Study Flow** — no attach step today; this profile declares no bounded
  bridge capability. If you later add one to the cached-read neighbor, the requirement
  applies to that route and to no other.

Do not attach defensively on routes that push nothing. Attach is a declaration that this
route participates in the seam, and a route that declares participation it does not use is
one more thing a reader has to disprove.

## Phoenix SaaS Portal

This profile fits a Phoenix-backed product where most authenticated routes remain
`:live_view` inside the shell and Crosswake adds only one low-frequency native
affordance through a declared seam. The point is to pressure shell activation,
manifest-backed route truth, denial UI, and support honesty without turning the app
into a generic wrapper.

Representative routes:

- `/saas/dashboard`
- `/saas/accounts/:id`
- `/saas/approvals`
- `/saas/approvals/:id`
- `/saas/settings/profile`

Required seams:

- manifest-first activation and deep-link normalization
- explicit denial UI when activation fails closed
- one bounded bridge capability on the approval-detail route
- `Crosswake.Bridge.attach/1` at `mount/3` on that one route

Primary failure vocabulary focus:

- `route unavailable`

Supported behavior:

- authenticated `:live_view` routes stay Phoenix-owned inside the shell
- host-owned auth keeps one signed-in boundary and one lightweight role split
- one low-frequency approval confirmation can request shell haptics without changing
  route ownership
- this lane maps most directly to `app_info`, `haptics`, and `deep_link` rather than
  broad native capability breadth

Degraded behavior:

- route activation still fails closed to `route unavailable` when shell checks reject
  the request
- when the shell cannot satisfy the haptics request, the approval remains
  server-authoritative and the route still completes on the Phoenix side
- in a desktop browser with no shell at all, the push still resolves: the route receives
  exactly one typed `shell_unreachable` denial rather than silence, and the approval
  itself stands
- the approval-detail route declares the same `haptics.impact` capability that the
  exercised shell request path uses

Deferred behavior:

- SSO, OAuth/OIDC, MFA, passkeys, impersonation, and vendor auth guidance
- offline writes, outboxes, replay, or any local-first approval authority
- packs, transfers, native capture, and `:native_screen` ownership as the main SaaS
  lane

Proof posture summary:

Read [guides/native_shell.md](native_shell.md)
for shell activation and denial behavior, and
[guides/support_matrix.md](support_matrix.md)
for supported baselines and proof-backed support status. Keep
[guides/install.md](install.md) as the canonical
checked-in proof entrypoint.

Why this profile exists:

It proves Crosswake can stay Phoenix-first for the majority of a mobile product
surface while still handling one narrow native seam without shell forks.

Explicit non-goals:

- required packs as the main route pressure
- offline islands or queued replay
- native capture ownership
- broad transfer workflows
- billing abstractions or plugin-style capability growth
- hidden storefront loops (account, status, and billing history remain Phoenix-owned surfaces)

### Selective Native Flow

This profile fits a mostly Phoenix-owned product where one route becomes explicitly
`:native_screen` because a device-heavy step should not be forced through a bounded
web container. The surrounding product still stays route-policy-driven and
Phoenix-owned.

Representative routes:

- `/native/claims`
- `/native/claims/:id`
- `/native/claims/:id/capture`
- `/native/submissions/:id/review`

Required seams:

- one declared `:native_screen` route for capture
- route-local packs for native capture assets when required
- route-local explicit `:camera` capability
- route-local transfer seams such as `transfer.upload.prepare`
- `Crosswake.Bridge.attach/1` on each `:live_view` route that dispatches one of those seams
- explicit sensitivity and fail-closed native activation

Primary failure vocabulary focus:

- `pack_incompatible`

Supported behavior:

- native capture remains bounded to one specific route inside the claims-evidence corridor
- media stays staged and captured locally until explicit Phoenix review before upload triggers the transfer seam
- surrounding `/native` routes do not inherit capability or pack requirements
- this lane maps directly to `media_capture` and keeps native ownership explicit on
  that route instead of widening into generic plugin-style support

Degraded behavior:

- if the shell lacks the requested camera media pack, the capture route denies activation with `pack_incompatible`
- non-capture routes stay fully usable even if the capture pack is absent or incompatible

Deferred behavior:

- background uploads without user confirmation, silent retries, or implicit submission
- generic capability-bus or workflow-bus semantics where the shell drives the interaction
- generic file pickers or cross-app sharing as the primary media path

Proof posture summary:

Read [guides/packs.md](packs.md) for required
pack and transfer semantics, plus
[guides/native_shell.md](native_shell.md) for
native ownership and denial behavior. Keep
[guides/support_matrix.md](support_matrix.md)
as the status source.

Why this profile exists:

It proves Crosswake can move one narrow route into native ownership without letting
the rest of the app drift into a broad capability broker or generic fallback
container.

Explicit non-goals:

- billing or entitlement systems (this lane models native commerce corridor boundaries, but Phase 13 still does not ship a billing adapter)
- multiple native-screen categories
- generic upload fallback through the web container
- broad permission-broker scope

## Local-First Study Flow

This profile fits a study-oriented route set where one `:offline_island` keeps
meaningful work moving offline while a neighboring history route stays cached
read-only. The goal is to keep local-first mutation and cached degradation honest
and visibly different.

Representative routes:

- `/study/session`
- `/study/history`
- `/study/sync`

Required seams:

- one declared `:offline_island`
- cached read-only neighboring routes
- durable journal and outbox replay
- explicit replay outcomes and route-local offline states

Primary failure vocabulary focus:

- `conflict requires attention`

Proof posture summary:

Read [guides/offline.md](offline.md) for the
cached read-only and replay contract, and
[guides/support_matrix.md](support_matrix.md)
for the canonical support-status surface. The install and example-host path stays in
[guides/install.md](install.md).

Supported behavior:

- the `:offline_island` session route keeps local progress and outbox state inside the
  example host lane until explicit sync
- the `/study/history` route stays cached read-only and renders replay outcomes without
  taking local mutation authority
- the shared shell fixtures carry the local-first history route so the bounded shell
  still proves the cached neighbor surface
- this lane reinforces backend-truth and bounded-route semantics instead of implying
  broad capability support

Degraded behavior:

- if the shell cannot open the offline-island session route directly, the bounded
  shell still proves the cached read-only history route instead of pretending the
  whole local-first workflow is shell-supported
- replay remains explicit and user-driven; there is no background sync promise

Deferred behavior:

- lesson libraries, multi-route curricula, and collaborative sync datasets
- background-sync guarantees
- media-heavy offline transfer

Why this profile exists:

It proves Crosswake can support one honest local-first story without widening into a
generic sync framework or magical app-wide offline claim.

Explicit non-goals:

- broad CRUD sync
- collaborative sync
- background-sync guarantees
- media-heavy offline transfer
- multiple offline-island stories
- offline purchase replay or device-authoritative entitlement mutation
