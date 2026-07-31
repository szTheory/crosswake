# First B2C Adopter Route-Policy Map

## Purpose

This is the one-day route-inventory contract for the First B2C Adopter. Its reader should be able
to classify every adopter route before implementation starts, identify offline payload and media
risks, and keep most changeable product behavior server-owned.

This document records product shape, not identity. Do not add real business names, customer data,
pricing, geography, founder details, proprietary lesson taxonomies, or revealing links.

## Default route ownership

| Product surface | Runtime owner | Offline posture | Authority and fallback |
| --- | --- | --- | --- |
| Study session | `:offline_island` | Local mutation with journal, scoped outbox, replay, rejection, and conflict handling | Host backend reauthorizes every replay; route visibly blocks when account or feature state is invalid |
| Learning path | `:live_view` with cached read-only neighbor | Cached read-only | Server remains progress authority; stale cache is labeled |
| Dashboard | `:live_view` with cached read-only neighbor | Cached read-only | Server-owned; shell cache never grants access |
| History | `:live_view` with cached read-only neighbor | Cached read-only | Server-owned; cached rows are informational |
| Authentication | `:live_view` | Unavailable offline except bounded remembered evidence | Backend session authority through `crosswake_sigra`; shell evidence never becomes credential authority |
| Settings | `:live_view` | Unavailable offline | Server-owned and hotfixable |
| Billing | `:live_view` | Unavailable offline | Backend and billing provider remain authoritative |
| Pronunciation audio playback | Asset consumption inside `:offline_island` | Required pack must be installed before offline entry | Host-supplied iOS pack provider; fail closed when missing, stale, corrupt, or unverifiable |
| Microphone capture or pronunciation scoring | Deferred | Not claimed | Revisit only after playback and study replay pass on a physical iPhone |
| Emergency native-path disablement | Route policy plus host flag source | Evaluated at entry and replay | Existing `gated_by`; retain queued data and show blocked state |

## Inventory fields

The adopter supplies one row per concrete route with:

- route ID and path;
- current product owner;
- proposed runtime owner;
- mutation actions and payload shape;
- cache staleness tolerance;
- authentication and recent-auth requirements;
- account-switch and logout behavior;
- required media packs, expected compressed size, and codec;
- online, offline, denied, and corrupt-pack fallback;
- whether the route can be disabled server-side without shipping a binary.

## Study-island invariants

- Every journal and replay envelope carries an opaque `scope_ref`.
- Free-form and selected-option answers are payload, never telemetry metadata.
- The outbox is partitioned by scope.
- Logout and account switching stop replay before a different scope can become active.
- The replay endpoint re-checks session authority, route policy, and feature state.
- Accepted, rejected, and conflict outcomes are explicit. No silent last-write-wins.
- Evidence artifacts contain versions, route IDs, low-cardinality outcomes, and redacted hashes
  only.

## Pronunciation-pack invariants

- A pack is never `available` merely because an install request was made.
- A provider must download into application support storage, verify expected size and SHA-256, and
  atomically rename the verified result into place.
- Missing provider, missing pack, wrong version, checksum failure, interrupted download, and
  insufficient storage all remain explicit non-available states.
- Crosswake does not choose CDN, archive layout, lesson grouping, codecs, retention, storage
  budget, or user-facing download policy.
- Background transfer, delta updates, eviction algorithms, Android storage, offline scoring, and
  microphone capture are not part of the first proof.

## Physical-iPhone exit test

The public v1 adoption milestone is complete only when one physical iPhone can:

1. install one pronunciation pack while online;
2. start a study session;
3. submit both selected and free-form answers while offline;
4. play pronunciation audio while offline;
5. preserve the session and outbox across kill and relaunch;
6. reconnect and reconcile exactly once until the outbox is empty;
7. show recoverable rejection and conflict outcomes;
8. switch account or log out without cross-scope replay;
9. honor a server-side disablement at route entry and replay without losing queued data; and
10. produce a redacted artifact containing versions, device class, outcomes, and hashes only.

Passing this test proves one adopter flow on one iOS runtime line. It does not prove generic sync,
background sync, generic pack storage, multiple islands, Android, or all-device support.

## One-day route-inventory time box

The route map takes one focused day once the adopter provides the inventory fields above:

- morning: enumerate and classify routes, mutations, authority, and staleness;
- afternoon: walk the study payload, identity scope, media budget, fallbacks, and kill switch;
- end of day: freeze the first implementation slice and list unresolved risks.

If the customer Alpha is web-only, stop Crosswake work after this inventory until the public v1
path becomes active.

