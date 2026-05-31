# Companion Integrations

Crosswake companions are first-party, typed integration seams. They are not a generic plugin bus, and they do not override route ownership. Route policy remains authoritative per route; companions can only add fail-closed restrictions.

This guide is the single canonical v3.5 companion guide. It explains the shared `Crosswake.Companion` contract first, then the shipped companion surfaces (Rulestead, Rindle, Sigra), then proof posture and explicit non-goals.

## Core Contract First

Every companion implements `Crosswake.Companion` and lives in-tree under `lib/crosswake/companions/<name>/` in v3.5.

Required callbacks:

- `companion_id/0`
- `enabled?/1`
- `route_gated?/2`
- `kill_switch_active?/1`
- `validate_dependency/0`
- `report_state/0`

Registration is host-owned:

```elixir
config :crosswake, :companions, [
  Crosswake.Companions.Rulestead,
  Crosswake.Companions.Rindle
]
```

`validate_dependency/0` is wrapped by doctor telemetry under `[:crosswake, :companion, :validate_dependency]`. When a companion is enabled but its optional dependency is missing, doctor emits `companion.dependency_missing` as an `:error`. This is fail-closed posture for support truth and release readiness.

## Route Ownership And Fail-Closed Semantics

Companions are bounded seams around policy decisions. They never create a hidden authority path.

- A companion can deny (`:gate_denied`, `:kill_switch_active`, `:step_up_required`) but cannot silently allow a route that core policy denied.
- `kill_switch_active?/1` short-circuits ahead of route-level gate decisions.
- Missing optional dependency is never treated as healthy support.
- High-frequency or arbitrary cross-runtime messaging is out of scope.

Companion guidance in this file is contract truth, not marketing surface.

## Rulestead Surface (GATE)

Companion id: `:rulestead`.

Rulestead is the shipped feature-gating companion. Route policy binds a route to a gate key using `gated_by`, and unavailable handling uses `on_unavailable`.

```elixir
live "/beta-feature", BetaFeatureLive,
  crosswake: [
    id: "beta-feature",
    gated_by: :rulestead,
    on_unavailable: :deny
  ]
```

Runtime denial vocabulary includes:

- `:gate_denied`
- `:kill_switch_active`

The in-tree mock source for deterministic local and hermetic proof is `Crosswake.Companions.Rulestead.MockFlagSource` with `set_flag/2`.

```elixir
Crosswake.Companions.Rulestead.MockFlagSource.set_flag(:rulestead, :gated)
Crosswake.Companions.Rulestead.MockFlagSource.set_flag(:rulestead, {:rolling_out, 50})
Crosswake.Companions.Rulestead.MockFlagSource.set_flag(:rulestead, :killed)
```

Support truth for runtime gate state is exported from `Crosswake.SupportMatrix.gating_truth/0`, with label `Crosswake.SupportMatrix.gating_truth_label/0`.

## Rindle Surface (MEDIA)

Companion id: `:rindle`.

Rindle is the shipped media companion seam. It keeps media authority backend-owned and typed:

- `UploadGrant` constrains presign authority (expiry, limits, accepted types, idempotency key).
- `CaptureEvidence` is evidence from device-side capture/upload, not authority.
- `MediaObject` state is explicit (`:queued`, `:uploaded`, `:scanning`, `:available`, `:rejected`).

Critical posture:

- Direct upload success is not committed media.
- Only backend verification advances media to `:available`.
- `:queued` is not equivalent to committed or durable media availability.

This mirrors Crosswake’s reconciliation stance: evidence can move workflow, but authority stays backend-owned.

## Sigra Surface (AUTH, Contract-Only)

Sigra in v3.5 is contract-only. It defines typed auth contract surfaces and fail-closed route checks without shipping full auth ceremonies.
It intentionally has no runtime `Companion id:` marker yet because it is not a `Crosswake.Companion` optional dependency surface in v3.5.

- `AuthContext`
- `SessionAuthorityLane`
- Route predicates: `auth_min_level`, `requires_recent_auth`
- Denial vocabulary: `:step_up_required`

Doctor and support truth use stable contract signals, including:

- `auth.route_predicated`
- `auth.step_up_required_contract`

Support truth accessor:

- `Crosswake.SupportMatrix.auth_contract_truth/0`

Contract-only means this guide intentionally does not claim handoff ticket machinery, step-up ceremony UX, passkey delivery, OAuth delivery, or refresh-token orchestration.

## Support Truth Surfaces

Do not treat guide prose as independent truth. Operators and tests should anchor on exported runtime surfaces:

- `Crosswake.SupportMatrix.gating_truth/0`
- `Crosswake.SupportMatrix.auth_contract_truth/0`
- `Crosswake.Shell.Denial.reasons/0`
- `Crosswake.Doctor.run/1` findings

For denial vocabulary, `Crosswake.Shell.Denial.reasons/0` is canonical and includes `:gate_denied`, `:kill_switch_active`, and `:step_up_required`.

## Proof Posture

Companion claims are split by proof class.

- Hermetic merge-blocking proof: must pass without optional dependency present.
- Advisory dependency-present proof: validates optional dependency wiring in controlled lanes.

Advisory checks are evidence, not promotion. A green advisory lane does not widen support claims by itself.

## Deferred Non-Goals (Explicit)

These are deferred by design and are not shipped in v3.5:

- Chimeway delivery implementation. Chimeway is seam-only sequencing context, not first-party notification delivery in this milestone.
- Full Sigra machinery: handoff ticket issuance, full step-up ceremony flow, passkey delivery stack, OAuth choreography, and refresh-token machinery.
- Threadline audit capstone.
- Separate-package extraction of companions. v3.5 keeps companions in-tree under `lib/crosswake/companions/<name>/`.

## What This Guide Does Not Claim

- Not a plugin bus.
- Not a fail-open optional-dependency model.
- Not provider-delivery claims for deferred surfaces.
- Not device-authority claims for media or auth.
- Not route ownership override through companion code.

## Reader Checklist

Use this checklist before claiming companion support:

1. Companion module implements all six callbacks from `Crosswake.Companion`.
2. Module is registered in host `:companions` config intentionally.
3. `validate_dependency/0` emits expected outcome under doctor with telemetry span `[:crosswake, :companion, :validate_dependency]`.
4. Route policy usage is explicit (`gated_by`, `on_unavailable`, `auth_min_level`, `requires_recent_auth`) and denial vocabulary is fail-closed.
5. Support truth from `Crosswake.SupportMatrix.gating_truth/0` and `Crosswake.SupportMatrix.auth_contract_truth/0` matches guide language.
6. Hermetic proof lane passes without optional deps; advisory lane behavior stays advisory.

## Cross-Guide Boundary

For commerce-specific reconciliation vocabulary and storefront posture, see [`guides/commerce.md`](commerce.md). This companion guide remains companion-contract scoped.
