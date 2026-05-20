# Crosswake Capability Families

Crosswake does not present capabilities as a generic plugin catalog. It classifies
candidate native affordances by who should own the route interaction loop, then
states the support posture honestly.

## Ownership-First Rubric

Start with the route owner, not the API shape.

- `bounded_bridge` = Phoenix-owned route, low-frequency semantic request/reply action, no native authority over the interaction loop
- `native_screen` = native code owns permission choreography, capture or scan session, or policy-sensitive UI loop
- `backend_seam` = Phoenix/backend remains the control plane and route-local bridge calls do not own truth
- `defer` = outside current thesis, support posture, or proof budget

Use `bounded_bridge` only when the route stays Phoenix-owned and the native side is
answering one narrow semantic request. Use `native_screen` when native code must
run the session. Use `backend_seam` when backend truth or provider coupling is the
real seam. Use `defer` when Crosswake would have to widen its thesis or support
claims to act like a generic mobile framework.

## Capability Families

Capability families are public vocabulary. Bridge commands are subordinate protocol
details.

The first Phase 11 inventory is:

- `deep_link`
- `app_info`
- `haptics`
- `share`
- `permissions.status`
- `notification_token`
- `media_capture`
- `scanner`
- `document_scan`
- `paywall`
- `purchase`
- `restore`
- `entitlement_snapshot`

`deep_link` remains manifest-first shell activation truth, not route-local bridge or navigation authority.

## Bounded Bridge

`bounded_bridge` families keep the route Phoenix-owned. Crosswake may expose one
typed request/reply seam, but the shell does not become navigation authority,
session authority, or backend truth.

Representative bounded-bridge families:

- `app_info`
- `haptics`
- `share`
- `permissions.status` when treated as a read-only snapshot
- `notification_token` when treated as evidence rather than delivery truth

## Native Screen

`native_screen` families move the interaction loop into native ownership because the
route needs native session control, permission choreography, or platform-sensitive
UI fidelity.

Representative native-screen-first families:

- `media_capture`
- `scanner`
- `document_scan`

## Backend Seams And Deferred Surfaces

Some surfaces are valid capability-family vocabulary without being honest Phase 11
core support claims.

- `paywall`, `purchase`, `restore`, and `entitlement_snapshot` are meaningful
  taxonomy entries, but entitlement truth remains backend-owned and provider/store
  boundaries stay explicit.
- Control-plane or provider-heavy surfaces belong in `backend_seam` posture rather
  than route-local bridge authority.
- Families that would force broad scanner, storefront, or review-heavy support
  claims stay deferred until Crosswake can prove them honestly.

## Family Naming Rules

- Use stable semantic family names, not generic buckets like `device`, `media`, or `plugins`.
- Keep family ids public and small.
- Keep bridge commands lower-level and operation-shaped.
- Do not let package class override route ownership.

## Package Boundary Rules

- `core` = semantic family is low-frequency, typed, route-local, and supportable without provider-specific native package sprawl
- `companion` = family needs extra native/package choreography, backend/operator coupling, or release-boundary pressure beyond core
- `example/docs-only` = family is useful for guidance and classification, but Crosswake is not claiming first-class shipped support yet
- `defer` = family is outside the current thesis, proof budget, or honest support posture

Package class does not override runtime ownership. A family can still be
`native_screen` and `companion`, or `backend_seam` and `example/docs-only`.

## Packaging Ledger

Crosswake keeps one primary public package: `crosswake`. Package class explains
release burden and support posture; it does not override route ownership.

- `core` = the default `crosswake` package and its bounded contract surfaces
- `companion` = explicit first-party extensions when native churn or provider coupling exceeds core
- `example/docs-only` = guidance surfaces that teach boundaries without becoming runtime packages
- `defer` = surfaces intentionally withheld until release choreography and proof stay honest

Read [guides/support_matrix.md](/Users/jon/projects/crosswake/guides/support_matrix.md)
for the generated packaging ledger rendered from canonical support truth.

## Documentation Strength

Crosswake distinguishes three public documentation strengths:

- `supported example`
- `companion guidance`
- `docs-only classification`

Use these labels literally. They tell adopters whether they are reading proof-backed
artifact guidance, future companion boundary guidance, or classification material
that is not first-class shipped support.

## Docs-Only Boundary

Docs-only surfaces are `not first-class supported`. They are useful because they make
route ownership, denial behavior, fallback behavior, prerequisites, and rebuild
pressure explicit before Crosswake widens support claims.

- Checked-in example hosts and install walkthroughs are product surfaces, but they are not runtime package boundaries.
- Docs-only material must link back to [guides/support_matrix.md](/Users/jon/projects/crosswake/guides/support_matrix.md).
- Runnable docs-only lanes are disallowed. Promotion requires reclassification plus proof and support-matrix updates.
- Graduation criteria must say what proof, release policy, and rebuild posture would be required before support expands.

### Route owner

`paywall`, `purchase`, `restore`, and `entitlement_snapshot` remain Phoenix/backend-owned seams. A docs-only classification does not authorize the device to own entitlement truth.

### Why not core/companion

These surfaces are meaningful vocabulary now, but provider/storefront churn, reviewer guidance, and backend reconciliation burden are still too high to market as first-class runtime support.

### Host-owned responsibilities

The host owns storefront/provider selection, backend reconciliation, receipt or event ingestion, and explicit native-screen decisions when policy-sensitive purchase UI cannot stay Phoenix-owned.

### Prerequisites

Backend entitlement authority, provider-specific adapter design, storefront guidance, and explicit support-matrix classification must exist before promotion.

### Denial behavior

If the seam is undeclared or unsupported, Crosswake fails closed with explicit unavailable posture instead of pretending the bridge or shell can complete a purchase flow safely.

### Fallback behavior

Fallback remains Phoenix-owned guidance or a deliberate native-screen requirement. Crosswake does not imply a runnable supported host recipe from docs-only examples.

### Native rebuild required

Usually yes once a real storefront adapter or native provider SDK enters the picture. Docs-only classification by itself does not require a rebuild because it is guidance, not shipped runtime support.

## First Public Example Set

Crosswake keeps the first example set narrow and exemplar-aligned:

- `deep_link`, `app_info`, `haptics`, and `share` are the first canonical `core` examples.
- `media_capture`, `notification_token`, `rollout`, and `audit` are `companion`-leaning or boundary-heavy examples.
- `permissions.status`, `auth`, `paywall`, `purchase`, `restore`, and `entitlement_snapshot` are `example/docs-only` guidance in Phase 11.
- `scanner` and `document_scan` are explicit `defer` examples for now.

## Package Class Examples

- `core`: `deep_link`, `app_info`, `haptics`, `share`
- `companion`: `media_capture`, `notification_token`, `rollout`, `audit`
- `example/docs-only`: `permissions.status`, `auth`, `paywall`, `purchase`, `restore`, `entitlement_snapshot`
- `defer`: `scanner`, `document_scan`

## Explicit Defers

`scanner` and `document_scan` stay deferred because they imply heavier native
ownership, policy burden, and broader proof/support-matrix breadth than Crosswake
can honestly claim today.
