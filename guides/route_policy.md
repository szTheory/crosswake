# Crosswake Route Policy Guide

Crosswake's one job is to declare, enforce, and diagnose which runtime owns each route as a Phoenix app crosses into mobile.

Owner selection comes before syntax. Start with the product question from
[guides/user_flows.md](user_flows.md): **Who should own this route?** Then write
the smallest route policy that makes that owner, its prerequisites, and its failure
behavior explicit.

Route owner first, capability second. Capabilities, packs, sync seams, transfers,
auth posture, commerce posture, and notification-open handling all hang off the
route owner. They are not a separate catalog that lets the shell take over the app.

Use this guide as the start-here owner map. The detailed contracts stay in
[guides/bridge.md](bridge.md), [guides/offline.md](offline.md),
[guides/native_shell.md](native_shell.md), [guides/capabilities.md](capabilities.md),
and [guides/support_matrix.md](support_matrix.md).

## Owner Decisions

| Owner decision | Use it when | Do not use it for |
|----------------|-------------|-------------------|
| plain `:live_view` | Phoenix owns data, rendering, auth, and the interaction loop | device session control or local mutation |
| `:live_view` with one bounded bridge affordance | Phoenix still owns the route, and native helps with one low-frequency semantic action | navigation authority, high-frequency event streams, or mutation authority |
| cached read-only | the route may show a stale snapshot but cannot mutate server truth | local drafts, replay, or optimistic writes |
| `:offline_island` | one route owns local-first work with outbox or journal replay | app-wide offline claims |
| `:native_screen` | native code owns a device-heavy or policy-sensitive session loop | ordinary SaaS forms that already work as LiveView |
| backend/provider seam | Phoenix/backend remains authority while device or provider events become evidence | device-owned entitlement, auth, or commerce truth |
| explicit defer | the route needs support Crosswake has not proven honestly yet | silent fallback into a weaker owner |

Every owner choice should make four downstream truths inspectable:

- **Manifest truth:** what the generated manifest says about `runtime`, `offline`,
  `entry`, capabilities, packs, sync, transfers, auth, commerce, and route
  availability.
- **Doctor/support posture:** what `mix crosswake.doctor` and the support matrix can
  prove, warn about, or leave advisory.
- **Denial/fallback behavior:** what happens when route activation, bridge
  authorization, packs, gates, auth, or capability prerequisites fail.
- **Rough edge:** the limitation Crosswake keeps visible instead of hiding behind a
  broad mobile claim.

## plain `:live_view`

Use a plain LiveView route when Phoenix owns the whole user job. Most SaaS routes
belong here: dashboard, account detail, approval list, settings, billing history,
admin review, and routine forms.

```elixir
live("/dashboard", DashboardLive,
  crosswake: [
    id: "saas-dashboard",
    runtime: :live_view,
    offline: :unavailable,
    entry: :internal_only,
    security: :standard
  ]
)
```

- **Manifest truth:** the route declares `runtime: :live_view`, `offline:
  :unavailable`, route-local `entry`, and `security` without native prerequisites.
- **Doctor/support posture:** doctor can validate manifest-first activation and
  support posture without implying native ownership.
- **Denial/fallback behavior:** activation still fails closed to `route unavailable`
  when the shell cannot honestly activate the route.
- **Rough edge:** this is still Phoenix UI inside a shell. Crosswake is not turning
  the route into native widgets.

## `:live_view` with one bounded bridge affordance

Use this when Phoenix owns the route but one low-frequency native action improves
the experience. The native side answers a typed request/reply command; it does not
drive navigation, rendering, or data authority.

```elixir
live("/approvals/:id", ApprovalLive,
  crosswake: [
    id: "saas-approval",
    runtime: :live_view,
    entry: :external,
    capabilities: ["haptics"],
    offline: :cached_read_only,
    cache_contract: :approval_snapshot_v1,
    security: :standard
  ]
)
```

- **Manifest truth:** the route declares `runtime`, `entry`, `capabilities`,
  `offline`, `cache_contract`, and `security`. The manifest capability registry must
  know the capability family before the bridge can execute it.
- **Doctor/support posture:** bounded bridge diagnostics report declared
  capabilities, supported command families, denial reasons, and advisory versus
  merge-blocking proof posture.
- **Denial/fallback behavior:** undeclared, unavailable, origin-denied, inactive,
  or pack-incompatible bridge calls return typed denial replies. The Phoenix-owned
  approval still owns the product action.
- **Rough edge:** if a flow needs continuous client authority, it is not a bounded
  bridge flow. Move it toward an offline island or native screen.

Route policy declares the capability **family** (`"haptics"`); the bridge dispatches
the wire **command** (`"haptics.impact"`). These are two vocabularies on purpose, not
a naming inconsistency — see [guides/bridge.md](bridge.md) for the full
family-versus-command split.

If a route still declares the older dotted form (`capabilities: ["haptics.impact"]`),
it keeps authorizing indefinitely — the dotted form is accepted permanently and is
not going away. No compile-time warning is emitted. Run `mix crosswake.doctor` to
find any route still declaring a legacy id; it names the route and the family id to
write instead.

## cached read-only

Use cached read-only when a route can degrade to a stale snapshot and remain
honest because it does not mutate canonical rows.

```elixir
live("/study/history", StudyHistoryLive,
  crosswake: [
    id: "local-first-study-history",
    runtime: :live_view,
    offline: :cached_read_only,
    cache_contract: :study_history_v1,
    auth_posture: :cached_read_only_ok,
    security: :standard
  ]
)
```

- **Manifest truth:** `cache_contract` belongs only on `offline: :cached_read_only`
  routes. It is not local-first mutation.
- **Doctor/support posture:** offline doctor output can show cached-route posture,
  route-local states, and typed telemetry without promoting the route to an
  offline island.
- **Denial/fallback behavior:** if the cache contract or compatibility posture is
  missing, the route should stay explicit about stale or unavailable state.
- **Rough edge:** cached read-only is a degraded read. It does not grant draft,
  journal, outbox, replay, or reconciliation authority.

## `:offline_island`

Use an offline island for one route with true local-first work: local state,
semantic mutation records, an outbox or journal, and explicit replay outcomes.

```elixir
live("/study/session", StudySessionLive,
  crosswake: [
    id: "local-first-study-session",
    runtime: :offline_island,
    offline: :local_first,
    island_contract: :study_session_v1,
    packs: [[id: :daily_study, version: "1.0.0", kind: :content]],
    sync: [:study_reviews],
    security: :standard
  ]
)
```

- **Manifest truth:** `island_contract` requires `runtime: :offline_island` with
  `offline: :local_first`. `packs` and `sync` stay route-local.
- **Doctor/support posture:** doctor can distinguish cached neighbors from the
  island and report saved-locally, queued-for-replay, replay-failed, accepted,
  rejected, and conflict outcomes.
- **Denial/fallback behavior:** replay can be accepted, rejected, or conflict. A
  conflict requires attention rather than silent overwrite.
- **Rough edge:** Crosswake proves one honest offline owner. It does not claim broad
  background sync or app-wide local-first behavior.

## `:native_screen`

Use a native screen when native code owns the session loop: capture, scan,
policy-sensitive native UI, or permission choreography that should not be forced
through a bounded web container.

```elixir
live("/claims/:id/capture", ClaimCaptureLive,
  crosswake: [
    id: "selective-native-claim-capture",
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
)
```

- **Manifest truth:** a `transfers` seam with `source: :native_capture` requires
  `runtime: :native_screen`. Route-local packs and sensitivity are part of the
  same manifest entry.
- **Doctor/support posture:** native shell and support-matrix labels must say what
  is merge-blocking proof, advisory evidence, or verification-required.
- **Denial/fallback behavior:** missing capture packs or native prerequisites fail
  closed with explicit route-unavailable or `pack_incompatible` posture.
- **Rough edge:** Crosswake does not silently degrade a native capture route into a
  web upload flow and pretend that the owner is unchanged.

## backend/provider seam

Use a backend or provider seam when the device or provider can provide evidence,
but Phoenix/backend remains authority. Commerce, entitlement, auth-return, and
notification-open flows belong here unless a later milestone proves a stronger
native owner.

```elixir
live("/account/security/return", AuthReturnLive,
  crosswake: [
    id: "auth-return",
    runtime: :live_view,
    offline: :unavailable,
    entry: :external,
    security: :sensitive,
    auth_min_level: :mfa,
    requires_recent_auth: 300,
    auth_posture: :strict_recent,
    auth_return: [
      kind: :oauth,
      transport: :verified_https_link,
      return_route_id: "auth-return",
      validates: [:state, :pkce, :redirect_uri, :expiry, :replay]
    ],
    notification_open: [actions: [:resume_step_up]]
  ]
)
```

```elixir
post("/purchase", CorridorController, :purchase,
  crosswake: [
    id: "commerce-purchase-intent",
    runtime: :native_screen,
    commerce: [corridor: :subscription_default, role: :purchase_intent],
    security: :sensitive
  ]
)
```

- **Manifest truth:** provider-neutral `auth_return`, `notification_open`, and
  commerce fields describe return, open, and corridor posture without embedding a
  provider SDK as route-policy vocabulary.
- **Doctor/support posture:** doctor reports session-authority, notification, and
  commerce posture as backend-owned contracts with explicit deferred/provider
  evidence boundaries.
- **Denial/fallback behavior:** stale entitlement snapshots, missing corridor
  prerequisites, unknown auth-return routes, or unsupported notification actions
  fail closed and return to Phoenix-owned guidance.
- **Rough edge:** device, storefront, webhook, notification, or provider evidence
  is not backend/session authority by itself.

## explicit defer

Use an explicit defer when the route would force Crosswake to widen support claims
before proof exists. A defer is better than a weak fallback that teaches adopters the
wrong owner.

```elixir
live("/scan/document", DocumentScanLive,
  crosswake: [
    id: "document-scan",
    runtime: :native_screen,
    capabilities: ["document_scan"],
    gated_by: :document_scan_rollout,
    on_unavailable: :deny,
    offline: :unavailable,
    security: :sensitive
  ]
)
```

- **Manifest truth:** `gated_by` and `on_unavailable` make the route unavailable
  posture explicit.
- **Doctor/support posture:** doctor can surface the gated route and support matrix
  can keep the family advisory or deferred until promotion criteria pass.
- **Denial/fallback behavior:** fail closed with an explicit unavailable surface or
  a declared `{:fallback_phoenix, route_id}` when a real fallback exists.
- **Rough edge:** a deferred owner is not hidden support. It is a visible boundary.

## Field Checklist

Route policies should use the current semantic DSL fields instead of a simplified
shadow vocabulary:

- `runtime`, `offline`, `entry`, `security`
- `capabilities`
- `cache_contract`, `island_contract`
- `packs`, `sync`, `transfers`
- `gated_by`, `on_unavailable`
- `auth_min_level`, `requires_recent_auth`, `auth_posture`, `auth_return`
- `commerce`
- `notification_open`

The schema and route validator enforce important owner boundaries:

- `cache_contract` requires `offline: :cached_read_only`.
- `island_contract` requires `runtime: :offline_island` and `offline: :local_first`.
- native-capture transfers require `runtime: :native_screen`.
- `on_unavailable` requires `gated_by`.
- sensitive or recent-auth routes require strict auth posture.
- provider-specific auth and commerce vocabulary stays out of core route policy.

## What To Read Next

- [guides/user_flows.md](user_flows.md) for the narrative job-to-be-done ramp.
- [guides/web_to_mobile_migration.md](web_to_mobile_migration.md) for the route
  inventory workflow added in v13.
- [guides/bridge.md](bridge.md) for the bounded bridge envelope and denial reasons.
- [guides/offline.md](offline.md) for cached read-only versus offline-island
  contracts.
- [guides/native_shell.md](native_shell.md) for manifest-first activation,
  native-owned routes, and route-unavailable behavior.
- [guides/capabilities.md](capabilities.md) for capability-family ownership
  vocabulary.
- [guides/support_matrix.md](support_matrix.md) for proof classes and current
  support posture.
