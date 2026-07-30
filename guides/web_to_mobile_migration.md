# Crosswake Web-To-Mobile Migration Guide

This is an operational route inventory guide for existing Phoenix SaaS teams. It is
not a mobile rewrite essay. The working rule is simple: default most routes to Phoenix/LiveView, then promote only when a route has a concrete owner reason.

Use this guide after [guides/user_flows.md](user_flows.md) and
[guides/route_policy.md](route_policy.md). Those guides explain the route-owner
mental model; this one turns it into a migration pass you can run against a real
Phoenix product.

## Default

Default most routes to `:live_view`.

That is not a compromise. It is the expected outcome for dashboards, accounts,
settings, approval queues, billing history, admin screens, and normal SaaS forms.
Phoenix already owns the data, auth, rendering, and validation loop for those
routes. Crosswake makes that ownership explicit when the product crosses into a
mobile shell.

Promote only for one of these reasons:

- degradable bounded native affordance
- cached read-only
- true local mutation/replay
- native-owned device session
- backend/provider authority
- explicit defer

## Migration Passes

### Pass 1: Inventory routes by user job

List routes by what the user is trying to do, not by controller, LiveView module, or
navigation location. Start with the three adopter profiles:

- **Phoenix SaaS Portal:** mostly LiveView product routes with one narrow native
  affordance.
- **Selective Native Flow:** mostly Phoenix-owned routes with one native-owned
  device-heavy corridor.
- **Local-First Study Flow:** cached read-only neighbors plus one offline island
  with local mutation and replay.

### Pass 2: Assign the initial owner

Give every route an initial owner before adding seams:

- `:live_view` for ordinary Phoenix product routes.
- `:live_view` plus one bounded bridge affordance when native help is low-frequency
  and degradable.
- `:live_view` plus cached read-only posture when stale reads are useful and safe.
- `:offline_island` only when the route truly owns local mutation/replay.
- `:native_screen` only when native code owns the session loop.
- backend/provider seam when device or provider evidence feeds Phoenix/backend
  authority.
- explicit defer when support would outpace proof.

### Pass 3: Add only required seams

After owner assignment, add the smallest route-local contract that owner needs:

- bounded bridge capabilities for one-shot actions such as haptics, app info, or a
  transfer-backed file picker
- `cache_contract` for cached read-only routes
- `island_contract`, `packs`, and `sync` for true offline islands
- `packs` and `transfers` for native-owned capture or transfer corridors
- `auth_min_level`, `requires_recent_auth`, `auth_posture`, and `auth_return` for
  backend-owned auth posture
- commerce and notification-open declarations only as provider-neutral evidence or
  activation seams
- `gated_by` and `on_unavailable` for explicit defers or rollout gates

### Pass 4: Run doctor and support checks

Run the route through manifest and support truth before turning it into public proof:

```sh
mix crosswake.doctor --router Elixir.YourAppWeb.Router
mix crosswake.doctor --router Elixir.YourAppWeb.Router --native-checks
```

Use [guides/support_matrix.md](support_matrix.md) for proof classes and
[guides/compatibility.md](compatibility.md) for runtime-line and rebuild guidance.
The support matrix is the canonical dense reference; this guide is only the
inventory workflow.

### Pass 5: Capture evidence for owner classes you use

Do not try to prove every possible mobile path. Capture evidence only for the owner
classes your app actually uses:

- Phoenix-owned LiveView route activation
- one bounded bridge affordance, if declared
- cached read-only degradation, if declared
- one offline island replay path, if declared
- one native-owned route-unavailable or native-screen path, if declared
- backend/provider reconciliation posture, if declared

Phase 118 owns the command-verified quick start and adoption rewrite. Treat
`examples/QUICK_START.md` and [guides/adoption.md](adoption.md) as hands-on
follow-up surfaces, not as the source of this route-inventory contract.

## Worksheet

| Route | User job | Initial owner | Promotion reason | Required seams | Evidence |
|-------|----------|---------------|------------------|----------------|----------|
| `/saas/dashboard` | check current work | `:live_view` | none | manifest route, auth posture | Phoenix-owned route activation |
| `/saas/approvals/:id` | approve one item | `:live_view` | degradable bounded native affordance | `capabilities: ["haptics.impact"]`, `entry` | approval still succeeds without haptics |
| `/study/history` | review previous work | `:live_view` | cached read-only | `offline: :cached_read_only`, `cache_contract` | stale read is labeled, no mutation |
| `/study/session` | keep studying offline | `:offline_island` | true local mutation/replay | `island_contract`, `packs`, `sync` | queued/replayed outbox with explicit outcome |
| `/native/claims/:id/capture` | capture claim evidence | `:native_screen` | native-owned device session | media pack, native-capture `transfers`, `security` | fail-closed route or native capture evidence |
| `/commerce/purchase` | start purchase intent | backend/provider seam | backend/provider authority | commerce corridor and backend reconciliation | device/provider event remains evidence |
| `/scan/document` | policy-heavy scanner | `:native_screen` | explicit defer | `gated_by`, `on_unavailable` | unavailable posture until proof exists |

## Promotion Reasons

### degradable bounded native affordance

Use this when Phoenix owns the route and the shell can help with one low-frequency
semantic action. Read [guides/bridge.md](bridge.md) for the request/reply bridge
contract and denial reasons.

#### Migrating an existing hand-rolled bridge call

If your app already talks to a shell, you almost certainly do it by rendering a
server-built payload into an inline `<script>` tag. That is how everyone starts, including
this project's own showcase, and Crosswake's reference host walked exactly this migration.
It is worth doing for one reason above all the others: **it is CSP hardening**. A payload
interpolated into inline script is a script-injection surface that a strict
`script-src` policy cannot cover, and every server value you interpolate is a value you
now have to prove is safe to interpolate.

Before — the server builds markup that builds a message:

```elixir
# Do not do this any more.
~s(<script type="module">window.webkit?.messageHandlers?.crosswake?.postMessage\(#{Jason.encode!(payload)}\)</script>)
```

After — the server calls the seam and the library-owned hook does the talking:

```elixir
socket = Crosswake.Bridge.push(socket, "haptics", payload: %{"style" => "light"})
```

The migration is four steps:

1. Wire the library-owned hook once. `mix crosswake.install` patches your endpoint's static
   plug and prints the layout fragments; `mix crosswake.gen.bridge_hook` prints them on
   demand. See [guides/install.md](install.md#step-1b-wire-the-bridge-hook).
2. Call `Crosswake.Bridge.attach/1` at `mount/3` on every route that will push. The first
   push on a socket that never attached raises a named error, so you find this immediately
   rather than in a shell build.
3. Replace each hand-rolled dispatch with one `Crosswake.Bridge.push/3` call. Delete the
   payload-building code — the envelope is built from the manifest the route already
   declares, and `Crosswake.Bridge.dispatched/2` reads it back if you need to render it.
4. If the control expects an answer, add one `handle_info/2` clause. Fire-and-forget
   controls such as haptics need no clause at all.

What you gain beyond the CSP win: the hand-rolled version had no answer for "what happens
in a desktop browser with no shell". The seam does — exactly one typed denial, in the same
clause that handles success. What you should not do is keep the old path as a fallback
around the new one; that reintroduces the branch the seam exists to collapse.

### cached read-only

Use this when a stale snapshot is useful but mutation would be dishonest. Read
[guides/offline.md](offline.md) for the difference between cached read-only and an
offline island.

### true local mutation/replay

Use this only when the route owns local writes, durable outbox or journal entries,
and explicit replay/reconciliation outcomes. Nearby routes can still stay
Phoenix-owned cached reads.

### native-owned device session

Use this when native code owns a capture, scan, or device-heavy session loop. Read
[guides/native_shell.md](native_shell.md) for manifest-first activation,
route-unavailable behavior, and native-owned routes.

### backend/provider authority

Use this when device, storefront, webhook, notification, or provider data is
evidence for Phoenix/backend authority. Read [guides/capabilities.md](capabilities.md)
for backend seam vocabulary and [guides/compatibility.md](compatibility.md) for
rebuild and compatibility truth.

### explicit defer

Use this when the route is real but the proof or support contract is not. A defer
with `gated_by` and `on_unavailable` is clearer than a silent fallback.

## Do Not Migrate This

- Do not move normal SaaS forms native just because the app is mobile.
- Do not push high-frequency client authority through the bridge.
- Do not call cached read-only pages offline mutation.
- Do not treat device or provider events as authority without backend reconciliation.
- Do not present local native hosts as generated public-coordinate proof.

## Reference Map

- [guides/route_policy.md](route_policy.md) - owner decisions and current route DSL examples
- [guides/bridge.md](bridge.md) - bounded bridge envelope, command families, and denials
- [guides/offline.md](offline.md) - cached read-only versus offline-island contracts
- [guides/native_shell.md](native_shell.md) - native shell activation and route-unavailable posture
- [guides/capabilities.md](capabilities.md) - capability family ownership vocabulary
- [guides/compatibility.md](compatibility.md) - compatibility axes and rebuild classes
- [guides/support_matrix.md](support_matrix.md) - canonical proof and support status
