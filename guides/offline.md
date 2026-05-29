# Crosswake Offline Guide

Crosswake Phase 4 proves one narrow offline story on purpose:

- one cached read-only route class for degraded reads
- one study-session offline island for local-first mutation

If you need help deciding whether your app should stay cached read-only or move one
route into a true offline island, start with
[guides/adopter_profiles.md](adopter_profiles.md)
and then return here for the exact offline contract.

Everything else remains out of scope until later phases prove it explicitly.
Crosswake is not a generic sync framework, and it does not claim magical
app-wide offline behavior.

## The Two Supported Shapes

### Cached Read-Only

Use cached read-only for neighboring lesson or library surfaces where the route
can degrade to a stale snapshot but cannot mutate canonical server rows.

- data is hydrated from a SQLite-backed cached snapshot
- the route remains read-only
- Phoenix stays server-authoritative
- stale reads stay explicit rather than being marketed as full offline support

This is the user-facing posture behind statuses such as `cached read-only` and
`stale`.

### Study Session Offline Island

Use the offline island only for the named study-session exemplar.

- draft state is saved locally
- committed semantic actions append immutable journal entries
- replay is route-scoped and explicit
- conflict requires attention instead of silently overwriting server truth

This is the user-facing posture behind statuses such as `saved locally`,
`queued for replay`, `replay failed`, and `conflict requires attention`.

## Replay And Reconciliation

Crosswake Phase 4 only claims one replay seam: the study-session
`study_reviews` sync seam.

- journal entries carry route id, client mutation id, idempotency key, and base checkpoint
- replay outcomes are explicit: `accepted`, `rejected`, or `conflict`
- Phoenix and Ecto remain authoritative after replay

Crosswake does not claim broad background sync guarantees, collaborative merge
behavior, or silent last-write-wins semantics.

## Shell And Doctor Surfaces

`mix crosswake.doctor` now exposes:

- the stable route-local offline vocabulary
- typed offline telemetry metadata
- the explicit cached-route and study-session island posture

Doctor support language is generated from the same contract truth as the
manifest. It does not infer offline support from generic `sync` strings or route
ordering.

## Support Boundary

Supported in Phase 4:

- cached read-only route hydration from explicit contract truth
- one study session local-first mutation workflow
- append-only journal durability
- explicit replay and conflict visibility
- hermetic proof of those repo-local surfaces

Not supported in Phase 4:

- generic sync framework claims
- media-heavy or camera-heavy offline workflows
- app-wide offline badges as the primary truth
- generated shell runtime support beyond the current `verification required` shell posture

Generated iOS and Android shell runtime support still depends on:

- `script/verify_generated_ios_shell.sh`
- `script/verify_generated_android_shell.sh`

Until those native proof hooks pass on the real generated projects, shell support
stays `verification required` even though the repo-local offline contract itself
is hermetically proven.

## Boundary Warnings & Rough Edges

Crosswake's offline support is intentionally narrow. Adopters should be aware of these boundaries:

- **No Background Sync:** True background synchronization (syncing when the app is not in the foreground) is currently unsupported. Sync only occurs while the app is active and the user is on the relevant route.
- **Manual Reconciliation:** Fallback to manual reconciliation hooks upon resume is required if automatic replay fails or encounters conflicts.
- **Limited Scope:** Offline support is only proven for specific "Offline Island" routes. App-wide offline state is not a goal.
- **No Conflict Magic:** Conflict resolution requires explicit user attention; silent "last-write-wins" is not supported.
