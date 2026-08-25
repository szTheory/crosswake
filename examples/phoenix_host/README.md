# Crosswake Example Host Lanes

This checked-in host is a `supported example` artifact class. It is proof-backed and
important product surface area, but it is not a separate supported runtime package.

Read [guides/adopter_profiles.md](../../guides/adopter_profiles.md)
for adopter-fit framing and
[guides/support_matrix.md](../../guides/support_matrix.md)
for the canonical package and support posture.

Open the showcase hub at `http://localhost:4700/` first. It is the
product-shaped entrypoint for the SaaS/Admin, Field Service, and
Learning/Training lanes; proof routes stay one click deeper and are secondary to
the showcase-first path.

Support-truth labels stay literal in this host: `Available today`,
`Proof-backed example`, `Demo pressure`, and `Future gap` separate proof-backed
behavior from future native-control pressure. Showcase screenshots explain the
product surface; route-tour assertions prove route-owner semantics before
screenshots are treated as collateral.

**Read Capability Map:** [../../guides/capability_map.md](../../guides/capability_map.md)
keeps available support, proof-backed examples, demo pressure, future gaps, and
v20 next-pack candidates separate from the example host boundary.

## Shared Artifact Rules

- Keep one shared Phoenix host under `examples/phoenix_host`.
- Keep the checked-in paired iOS and Android example hosts as proof artifacts of that same shared host.
- Extend profile-specific routes, modules, fixtures, and proof checks inside the shared host for the 3 locked lanes: Phoenix SaaS Portal (4-6 routes), Selective Native Flow (3-4 routes), and Local-First Study Flow. They use the runtimes `:live_view`, `:native_screen`, and `:offline_island`.
- Do not turn the example host into a runtime package or kitchen-sink demo.

## Reconciliation Example Surface

The reconciliation example lives in `CrosswakeExample.Commerce.ReconciliationKeys`,
`CrosswakeExample.Commerce.ReconciliationInbox`, and
`CrosswakeExample.Commerce.EntitlementProjection`.

These modules are a supportable reconciliation example surface for host teams. They
show backend-owned authority and non-authoritative evidence handling, but they are
not a core billing engine and they do not ship provider adapter implementations.

## Example Boundary

This README describes a proof-backed example host boundary. It is not a separate
runtime package, and it should not be mistaken for a docs-only lane that can graduate
without review.

### Route owner

Routes inside the example host still obey the same runtime ownership rules as the product: Phoenix-owned routes stay Phoenix-owned unless route policy declares a native screen or local-first boundary.

### Why not core/companion

The example host proves the public install and support story, but it is not the `crosswake` package and it is not a first-party companion package.

### Host-owned responsibilities

Maintainers own example routes, fixtures, proof-lane checks, and README wording that keeps support promises narrow and honest.

### Prerequisites

The shared example host, paired iOS and Android proof artifacts, and the scripts referenced by the support matrix.

### Denial behavior

If an example lane is unsupported or a proof lane fails, Crosswake treats that as explicit support posture, not as a silent fallback into a generic wrapper. It opens an explicit `route unavailable` surface and asserts the `pack_incompatible` and `conflict requires attention` denials.

### Fallback behavior

The example host may teach degraded behavior, but it does not become a generic runtime fallback or a substitute for explicit package classification.

### Supported behavior
Supported behavior is strictly bound to the typed boundaries.

### Degraded behavior
Degraded behavior is explicit and fail-closed.

### Deferred behavior
Deferred behavior is omitted entirely until it can be proven.

### Proof Posture
This lane is backed by `script/verify_phase5_example_hosts.sh` to keep the proof posture alive.

### Native rebuild required

Only when the changed work falls into `native or companion rebuild required`. README edits and docs-only wording do not imply a rebuild by themselves.

## Optional Chimeway background jobs

Crosswake ships synchronous registry APIs only. Background jobs remain host-owned optional
recipes that call those synchronous registry functions. No Oban, Quantum, Broadway, or
scheduler dependency is included in `crosswake` or in this example host.

Workers are host-owned. Crosswake does not claim APNs/FCM delivery assurance,
route-open authority from notification taps, or managed job scheduling through these APIs.

### Primary: Oban (recommended for durable jobs)

Oban is the idiomatic durable Phoenix background job library. A host team can insert Oban
jobs inside an `Ecto.Multi` so the job enqueue is atomic with any application write. The
worker calls the synchronous registry function directly.

Staleness pruning example:

```elixir
defmodule MyApp.Workers.ChimewayPruneStaleWorker do
  use Oban.Worker, queue: :chimeway_maintenance

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    stale_before = DateTime.add(DateTime.utc_now(), -7 * 24 * 3600, :second)
    CrosswakeExample.Chimeway.Registry.prune_stale(stale_before: stale_before)
    :ok
  end
end
```

Provider feedback handling example:

```elixir
defmodule MyApp.Workers.ChimewayProviderFeedbackWorker do
  use Oban.Worker, queue: :chimeway_provider

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"feedback" => feedback_attrs}}) do
    feedback = Crosswake.Companions.Chimeway.Contracts.ProviderFeedback.from_attrs(feedback_attrs)

    # Resolve this from authenticated host-owned delivery/binding state. Provider
    # token fields corroborate the event; they never authenticate a revocation.
    scope = MyApp.Notifications.resolve_authenticated_binding_scope!(feedback)
    CrosswakeExample.Chimeway.Registry.apply_provider_feedback(feedback, scope)
    :ok
  end
end
```

These workers are host-owned. They call `CrosswakeExample.Chimeway.Registry.prune_stale/1`
and `CrosswakeExample.Chimeway.Registry.apply_provider_feedback/2` and do not duplicate
lifecycle writes or claim delivery authority. Invalidating provider feedback requires
`authenticated_context`, the exact `binding_ref`, `app_identity_ref`, installation, and current
session/version scope; a token reference or fingerprint is corroborating evidence only.

### Secondary: Quantum or cron scheduling (for pruning)

For simple scheduled pruning without Oban, a host team can use Quantum or a cron trigger
to call `CrosswakeExample.Chimeway.Registry.prune_stale/1` on a schedule. Quantum and cron
are secondary scheduling alternatives for pruning. They are not recommended for durable
provider feedback handling because they lack Oban's transactional job enqueue and retry
guarantees.

### Not recommended in Phase 60: Broadway

Broadway belongs only to future high-volume provider feedback queue ingestion scenarios
(Kafka, SQS, PubSub, RabbitMQ). Phase 60 ships synchronous registry APIs for typical
per-request feedback handling. Broadway is out of scope for Phase 60 and this example host.

## Graduation Rule

Runnable docs-only lanes are not allowed here. Any reclassification from docs-only
guidance into a runnable lane requires reclassification plus proof and support-matrix updates.
The shared example host remains reserved for proof-backed lanes only.
