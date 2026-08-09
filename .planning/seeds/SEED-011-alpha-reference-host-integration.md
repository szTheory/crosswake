---
id: SEED-011
status: ready_for_promotion
planted: 2026-08-08
planted_during: v21.0 / Phase 162 external gate
trigger_when: when selecting the next Crosswake implementation milestone for physical-iPhone adoption proof
scope: large
---

# SEED-011: Alpha reference-host integration slice

## Why This Matters

Build one deliberately small, anonymous **Alpha** reference host: a digital twin that exercises
the Crosswake integration path without duplicating or exposing the adopter product. It should
make the physical-iPhone proof runnable against a real Phoenix host and a narrowly chosen study
flow, including a versioned offline learning bundle of card JSON, images, and pronunciation audio,
while preserving the distinction between a reference integration and a feature-complete consumer
application.

## When to Surface

**Trigger:** when selecting the next Crosswake implementation milestone for physical-iPhone
adoption proof.

Promote before asking for a device run if no separate eligible host can supply the required
route-policy, backend authority, replay, and foreground media callbacks. Keep it as a bounded
single-flow integration—not generic storage, synchronization, product UI, commerce, or a new
showcase program.

## Scope Estimate

**Large** — requires a dedicated milestone because it crosses route policy, backend authority,
offline replay, foreground iOS pack/audio adaptation, generated proof-lane host callbacks, and
physical-device automation.

## Intended Slice

- Reuse the checked-in Phoenix reference host and its existing browser-owned offline-study island
  rather than create a second product or a fictitious backend.
- Derive a sanitized route-policy row from the generic study flow: one opaque account scope, one
  rating/review mutation, one idempotent replay endpoint, a safe offline fallback, and one
  required foreground learning bundle.
- Define the bundle as a signed/versioned card manifest plus its exact image and pronunciation
  audio assets. Verify all bytes before atomic foreground installation; render only from the
  installed bundle while offline.
- Prove a bounded lifecycle: install bundle online, enter offline study, kill/relaunch, submit
  ordered local review mutations, reconnect, replay exactly once, and refresh/revoke the bundle
  only through host-authorized foreground operations.
- Add real host-owned session validation, account-switch denial, replay authorization, and
  server-side disablement; never grant authority from return payloads, client input, mock tokens,
  or synthetic organization scope.
- Implement the generated physical-proof host callbacks with deterministic local test authority
  only where the proof contract explicitly permits it. The device run must still be a real,
  signed, connected iPhone and the report must remain redacted.
- Preserve and extend executable browser/iOS evidence. Simulator success remains advisory;
  only the physical-proof driver can promote physical-device evidence.

## Breadcrumbs

- `examples/phoenix_host/` already provides the narrow Phoenix host and offline study surface.
- `examples/phoenix_host/e2e/support/offline_route_proof.ts` proves offline enqueue, idempotent
  replay, and server-confirmed history for the reference route.
- `examples/phoenix_host/priv/static/offline_study.js` owns browser-side outbox behavior.
- `lib/crosswake/proof_lane/physical_iphone_preflight.ex` and
  `guides/physical_iphone_handoff.md` define the fail-closed device-proof handoff.
- `examples/ios_shell_host/` and the existing pack-provider seam supply the bounded iOS adapter
  pattern; the new work must extend that contract to card/image/audio bundle integrity rather
  than introduce generic native storage.
- `.planning/ADR-FIRST-B2C-ADOPTER.md` preserves the non-goals and physical-proof boundary.

## Guardrails

- Do not use or record the adopter's real name, source repository, data, routes, credentials,
  tokens, account identifiers, or content.
- Do not call the host a production app or use it to claim product readiness.
- Do not bypass physical-device signing, authority validation, or media-byte verification with a
  fake green callback.
- Do not turn bundle refresh into generic background synchronization. Content availability is
  foreground, versioned, and host-authorized; only the selected study-review mutation uses the
  scoped replay path.
- Android remains frozen.
