# Phase 59: Chimeway Contract And Token Binding Semantics - Pattern Map

**Mapped:** 2026-06-02
**Status:** Ready for planning

## New Files To Plan

| Target file | Role | Closest analog | Pattern to preserve |
|-------------|------|----------------|---------------------|
| `lib/crosswake/companions/chimeway.ex` | First-party companion entrypoint | `lib/crosswake/companions/store_kit.ex`, `lib/crosswake/companions/play_billing.ex`, `lib/crosswake/companions/rindle.ex` | Implement `Crosswake.Companion` callbacks, keep route gating pass-through in Phase 59, report typed companion state without claiming delivery/open support. |
| `lib/crosswake/companions/chimeway/contracts.ex` | Typed token evidence, binding, feedback, audit/result contracts | `lib/crosswake/companions/sigra/contracts.ex`, `lib/crosswake/companions/rindle/contracts.ex` | Nested structs with `@enforce_keys`, `@type t`, constructor helpers, closed vocabulary helpers, validators returning `:ok | {:error, keyword()}`. |
| `lib/crosswake/companions/chimeway/telemetry.ex` | Stable notification telemetry sanitizer | `lib/crosswake/companions/sigra/telemetry.ex` | `event_names/0`, `metadata_keys/0`, `forbidden_metadata_keys/0`, `new_event/1`, `metadata/1`, `to_map/1`, `execute/3`; drop forbidden/unsafe metadata. |
| `lib/crosswake/companions/chimeway/redaction.ex` | Raw-token boundary and fingerprint/ref helpers | `lib/crosswake/companions/sigra/denial_codes.ex`, StoreKit/Play Billing evidence builders | Safe allowlist, bounded refs, deterministic digest/fingerprint helpers, no raw token in public structs or maps. |
| `test/crosswake/companions/chimeway/*_test.exs` | Contract proof | `test/crosswake/companions/sigra/*_test.exs`, `test/crosswake/companions/store_kit/*_test.exs`, `test/crosswake/companions/play_billing/*_test.exs` | ExUnit proof focused on constructors, invalid inputs, redaction, canonical vocabulary, and telemetry forbidden-key behavior. |

## Existing Files To Read Before Editing

- `lib/crosswake/bridge/commands/notification_token.ex` — current raw bridge evidence source.
- `lib/crosswake/bridge/commands/permissions_status.ex` — notification permission status vocabulary.
- `lib/crosswake/companion.ex` — first-party companion behavior and posture.
- `lib/crosswake/companions/store_kit/evidence.ex` — provider evidence struct/constructor analog.
- `lib/crosswake/companions/play_billing/evidence.ex` — provider evidence struct/constructor analog.
- `lib/crosswake/companions/sigra/contracts.ex` — backend-owned authority contract and validator analog.
- `lib/crosswake/companions/sigra/telemetry.ex` — telemetry sanitizer analog.
- `lib/crosswake/companions/sigra/denial_codes.ex` — safe detail allowlist analog.
- `lib/crosswake/support_matrix/support_matrix.ex` — existing notification support truth that should not imply delivery/open support in Phase 59.
- `guides/companions.md` and `guides/support_matrix.md` — current Chimeway non-claim language; only update if the plan explicitly scopes narrow contract anchors.

## Data Flow

1. Native shell emits `Crosswake.Bridge.Commands.NotificationToken.Response` with provider, raw token, notification status, and detail.
2. Chimeway redaction boundary accepts raw token input at the host/provider edge and produces `TokenEvidence` with `token_ref` plus `token_fingerprint`; raw token is discarded.
3. Backend/host context supplies subject/session/org scope for `TokenBinding`; shell evidence never chooses identity.
4. Provider feedback normalizes APNs/FCM-like facts into Chimeway feedback events and lifecycle reasons.
5. Telemetry receives only safe low-cardinality metadata and drops forbidden fields.

## Implementation Notes For Planner

- Prefer one contracts module plus one telemetry/redaction module over many small modules unless file size becomes unwieldy.
- Keep `NotificationToken.Response` unchanged unless a narrow adapter helper needs to accept it.
- Do not modify route policy, notification-open activation, example-host Ecto schemas, doctor output, or rendered support matrix in Phase 59 unless the plan limits the change to contract anchors and tests.
- Include a threat model in every plan because token material is sensitive and the workflow security gate is enabled by default.

## PATTERN MAPPING COMPLETE
