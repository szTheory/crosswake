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

## Layered inventory contract

The default table above is a compact discovery aid. It is not permission for a product-surface
default to supply route-local safety posture. A concrete route enters host proof only after one
sanitized row validates through `Crosswake.Adoption.RouteInventory`.

### Closed row status vocabulary

Every route-local posture uses exactly one of these statuses:

| Status | Meaning | Promotion effect |
| --- | --- | --- |
| `confirmed_sanitized` | A supplied value is represented by a closed, non-identifying vocabulary. | Eligible when every required field is explicit. |
| `known_default` | A non-sensitive discovery default is recorded explicitly on the row. | Eligible only when it is not standing in for a safety field. |
| `unknown_blocking` | The adopter has not supplied the required value. | Blocks host-proof and physical-device promotion. |
| `not_applicable` | The closed contract proves the field does not apply to this route. | Does not create an optimistic fallback. |

Blank, nil, omitted, or inferred values are not confirmation. The validator rejects them with a
field-specific safe error. `unknown_blocking` is the only honest representation of missing
adopter-supplied safety posture.

### Concrete-route allowlist

Each sanitized row contains only an opaque route ID, a sanitized Phoenix path pattern, and these
explicit route-local fields:

- runtime owner and offline posture;
- low-cardinality mutation categories and staleness class;
- auth level and recent-auth requirement;
- opaque scope, logout, and account-switch posture;
- media requirement, closed size band, codec family, and integrity posture;
- online, offline, denied, corrupt-pack, and disabled fallback classes;
- entry and replay disablement posture; and
- queued-data retention posture.

Auth, recent-auth, scope, mutation, media, every fallback, disablement, and queued-data retention
are route-local. They never inherit silently from a product-surface default.

The durable row excludes raw answers, media, transcripts, credentials, account or device
identifiers, tokens, proprietary taxonomy, exact byte counts, digests, archive names, URLs,
endpoints, and host flag names. Those host-private values belong in host configuration or secret
storage when integration begins, never in this inventory.

### Concrete-route inventory state

No sanitized adopter-supplied concrete route rows are available in this repository. The contract is
policy-contract complete, while adopter-instance completeness is blocked. TODO-002 remains open
until sanitized rows arrive; no guessed row, route path, mutation, media value, fallback, or
authority fact may be added here.

`Crosswake.Adoption.RouteInventory.validate/1`, `validate!/1`, and `validate_inventory/1` reject
unknown or forbidden fields and route-ID/path collisions. `promotion_status/1` blocks any row with
`unknown_blocking`, and it also blocks an empty inventory. This D-03 boundary prevents host-proof
or physical-device promotion until all required rows validate.

If customer Alpha is web-only, complete this bounded contract and pause Crosswake work until the
public-v1 mobile path is active.

### Concrete-route promotion invariants

`known_default` never supplies a concrete-route safety field. A row can be eligible only after
every safety posture is `confirmed_sanitized`; `unknown_blocking` remains blocked, and
`not_applicable` is valid only where the normalized route semantics prove the field irrelevant.

| Route condition | Required coherent posture before eligibility | Fail-closed result |
| --- | --- | --- |
| `local_first` offline posture | `offline_island` owner; a non-`none` mutation category; opaque partitioned scope with logout and account-switch replay stops | Reject a contradictory or `not_applicable` route-local posture. |
| `local_first` failure handling | `queue_local` offline fallback; `retain_and_block` disabled fallback; server-enforced entry and replay reauthorization; `retain_until_resolution` queued-data posture | Reject incomplete scope, fallback, disablement, or retention authority. |
| Recent-auth authority | `auth: recent_auth` exactly when `recent_auth: required` | Reject either direction of disagreement. |

These rules are executable in `Crosswake.Adoption.RouteInventory` before promotion. They do not
add a concrete adopter row or infer host-private scope, fallback, retention, mutation, or auth
facts; TODO-002 stays open.

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

The ten-step result must be driven and evaluated by an executable device harness. Human assistance
may connect the device or satisfy an external credential gate, but conversational approval and
manual UAT are not completion evidence. The harness owns assertions, failure reporting, and the
redacted artifact.

Passing this test proves one adopter flow on one iOS runtime line. It does not prove generic sync,
background sync, generic pack storage, multiple islands, Android, or all-device support.

## One-day route-inventory time box

The route map takes one focused day once the adopter provides the inventory fields above:

- morning: enumerate and classify routes, mutations, authority, and staleness;
- afternoon: walk the study payload, identity scope, media budget, fallbacks, and kill switch;
- end of day: freeze the first implementation slice and list unresolved risks.

If the customer Alpha is web-only, stop Crosswake work after this inventory until the public v1
path becomes active.
