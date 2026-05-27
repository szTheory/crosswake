# Crosswake Example Host Lanes

This checked-in host is a `supported example` artifact class. It is proof-backed and
important product surface area, but it is not a separate supported runtime package.

Read [guides/adopter_profiles.md](/Users/jon/projects/crosswake/guides/adopter_profiles.md)
for adopter-fit framing and
[guides/support_matrix.md](/Users/jon/projects/crosswake/guides/support_matrix.md)
for the canonical package and support posture.

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

## Graduation Rule

Runnable docs-only lanes are not allowed here. Any reclassification from docs-only
guidance into a runnable lane requires reclassification plus proof and support-matrix updates.
The shared example host remains reserved for proof-backed lanes only.
