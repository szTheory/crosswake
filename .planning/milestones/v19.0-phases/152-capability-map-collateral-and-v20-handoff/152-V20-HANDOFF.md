# Phase 152 v20 Native Controls Pack 1 Handoff

This is a planning-only handoff from v19 showcase evidence to v20 scope. It does
not define implementation files, public APIs, package releases, provider SDK
work, schema changes, or dashboard work.

## Decision Summary

v20 Native Controls Pack 1 should stay small: bounded, low-frequency,
route-local controls that fit Crosswake's Phoenix-first route-policy thesis.
The pack should harden the controls that v19 evidence made easy to reason about
without turning Crosswake into a generic native plugin catalog.

Primary decision:

- Build Pack 1 around route-declared alert/confirm, menu/action-button,
  haptics, share, and toast/review prompt affordances.
- Treat `permissions.status` and `notification_token` as read-only snapshot or
  evidence surfaces only.
- Defer capture/device controls, production commerce, reusable sync/native
  storage, and operator dashboard work to named later packs.

## Pack 1 Candidates

| Candidate | Pack 1 posture | v19 evidence | Boundary |
|-----------|----------------|--------------|----------|
| Alert/confirm | Candidate | Capability map next-pack row | Route-local confirmation only; Phoenix-owned flows remain authoritative. |
| Menu/action-button affordances | Candidate | AdminPilot and Fieldserv pressure | Route policy must declare allowed actions and fallback behavior. |
| Haptics | Candidate | AdminPilot approval haptics proof | Optional post-success feedback; server mutation must complete first. |
| Share | Candidate | `bridge-proof` advisory route | Low-frequency bounded bridge command with explicit platform support truth. |
| Toast/review prompt | Candidate | Showcase feedback pressure | Optional UX evidence; never navigation or backend authority. |
| `permissions.status` | Read-only surface | Capability map shipped row | Snapshot only; permission request UX is outside Pack 1. |
| `notification_token` | Evidence surface | Chimeway/capability map advisory row | Provider-tagged evidence only; delivery assurance stays outside core. |

## Candidate Contract Requirements

Every Pack 1 control needs the same contract shape before implementation starts:

1. Route policy declares the capability explicitly for the route.
2. The command is semantic, typed, versioned, and low-frequency.
3. Payloads include route id, active route id, capability, command, protocol
   version, origin, and correlation id where relevant.
4. Missing or incompatible capabilities fail closed into explicit fallback copy.
5. Browser route-tour proof asserts route ownership and fallback behavior before
   screenshots are captured as collateral.
6. Support truth names package owner, proof posture, route runtime owner,
   fallback behavior, and rebuild requirement.
7. Native shell participation remains explicit; no control is available through
   undeclared generic WebView behavior.

## Explicit Exclusions

Pack 1 does not include:

- Camera capture.
- Scanner or QR scan.
- Document scan.
- Media upload or evidence availability authority.
- Native storage for content packs.
- Reusable offline sync helpers.
- Commerce provider integration or storefront authority.
- APNs/FCM delivery assurance or universal notification routing.
- Operator dashboard routes.
- Generic plugin catalog registration.

Backend projection remains entitlement authority. Device or storefront evidence
can inform reconciliation, but it does not grant access.

## Named Later Packs

| Later pack | Includes | Promotion signal |
|------------|----------|------------------|
| Capture & Device Controls | Camera, scanner, document scan, media upload, permissions request UX, evidence availability | Fieldserv-style native-screen proof with backend verification and explicit device limitations. |
| Commerce/Paywall Productionization | Storefront adapters, entitlement refresh, purchase evidence ingestion, provider reconciliation | Backend projection and reconciliation contracts proven against provider evidence without device-local authority. |
| Offline Sync/Native Storage Productization | Native storage budgets, durable journals, outboxes, retry, conflict handling, reconciliation | LearnLoop-style local-first proof promoted from example-specific IndexedDB to explicit package boundaries. |
| Operator Dashboard | Route/support posture, diagnostics, telemetry, audit, release, and proof visibility | Maintainer need for a self-contained inspection surface after support truth stabilizes. |

## Promotion Criteria

A candidate can move from handoff to implementation planning only when all of the
following are true:

- It has a named route owner and package owner.
- It is low-frequency enough for the bounded bridge or explicitly belongs to a
  native screen.
- The fallback path is visible to the user and testable without native success.
- The support matrix can state proof posture without relying on screenshots.
- The route-tour or native proof lane can fail if the control is missing,
  overclaimed, or silently degraded.
- It does not require a deferred later pack to be true first.

## Evidence Sources

| Source | Evidence used |
|--------|---------------|
| `guides/capability_map.md` | Canonical capability rows, package owner, proof posture, fallback behavior, and v20 implications. |
| `examples/phoenix_host/evidence/evidence-manifest.example.json` | Generalized v19 route-tour evidence rows and unavailable pressure rows. |
| `.planning/phases/149-saas-admin-showcase/149-VERIFICATION.md` | AdminPilot LiveView-first route ownership, approval authority, diagnostics, and optional haptics proof. |
| `.planning/phases/150-field-service-showcase/150-07-SUMMARY.md` | Fieldserv native capture pressure, backend evidence authority, and deferred scanner/document/media/offline gaps. |
| `.planning/phases/151-subscription-learning-showcase/151-VERIFICATION.md` | LearnLoop offline island proof, sync visibility, backend-projection entitlement pressure, and deferred native storage/sync/productization. |
| `.github/workflows/offline-sync-e2e-gate.yml` | CI route-tour artifact checks and support-truth summary language. |

## Support-Truth Constraints

- Public copy must keep `Available today`, `Proof-backed example`,
  `Demo pressure`, `Advisory evidence`, `Future gap`, and
  `Next-pack candidate` distinct.
- `merge-blocking`, `advisory`, `not-yet-proven`, and `unsupported` remain proof
  posture labels; screenshots are collateral after route-tour assertions.
- Cached read-only routes are not local-first mutation.
- Backend projection remains the authority for entitlement state.
- Native-shell or first-party companion ownership must be named before a control
  appears as anything stronger than advisory evidence.
- Deferred later-pack work should stay visible as exclusions, not hidden behind
  broad native support language.

## Open Decisions For v20 Planning

1. Decide whether Pack 1 ships as core-only bounded bridge hardening, a native
   shell increment, or a split between core declarations and shell behavior.
2. Choose the first two controls for implementation order; haptics and share have
   the clearest v19 evidence, while alert/confirm and menu/action-button affordances
   may have stronger adopter value.
3. Define platform policy language for toast/review prompt behavior before it is
   promoted beyond `Next-pack candidate`.
4. Decide how read-only permission status and notification token evidence are
   documented so they do not imply permission request or delivery authority.
5. Choose the proof lane for v20: browser fallback proof only, native simulator
   advisory proof, or a stricter merge-blocking native lane if CI can support it.

