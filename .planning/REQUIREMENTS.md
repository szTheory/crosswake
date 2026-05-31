# Requirements — v3.5 First-Party Companions

**Milestone goal:** Lock a reusable Phoenix-native companion-seam pattern, prove it generalizes across two real companions (rulestead gating + rindle media), and ship the auth-context contract that unblocks the rest — all in-tree, all fail-closed, all proven by the established hermetic+advisory + docs-contract template.

**Scope:** Wedge + first generalization. Integration *seams* to existing szTheory libraries (`rulestead`, `rindle`, `sigra`), not features built from scratch. Companions live in-tree under `lib/crosswake/companions/<name>/`; separate-package extraction deferred.

Research: `.planning/research/v3.5-companions-SUMMARY.md`. Plan: `~/.claude/plans/candidate-v3-5-first-party-companions-glimmering-kite.md`.

## v3.5 Requirements

### COMP — Companion Seam Contract

- [x] **COMP-01**: A maintainer can register a first-party companion through a `Crosswake.Companion` behaviour with declared callbacks (`companion_id/0`, `enabled?/1`, `route_gated?/2`, `kill_switch_active?/1`, `validate_dependency/0`, `report_state/0`), generalized from the commerce seam.
- [x] **COMP-02**: A companion that is enabled in host config but whose underlying optional library is missing fails closed with an explicit `mix crosswake.doctor` error naming the missing dependency — never a silent no-op or fail-open.
- [x] **COMP-03**: Companions follow a documented in-tree convention (`lib/crosswake/companions/<name>/`) and emit `[:crosswake, :companion, …]` telemetry from core with static event names differentiated by `companion_id` metadata.

### GATE — Rulestead Gating, Kill Switches, Explainability

- [x] **GATE-01**: A Phoenix team can declare that a route or capability is gated by a named flag (`gated_by`) in the route-policy DSL, validated at compile time as a typed identifier.
- [x] **GATE-02**: A gated route's flag *binding* is recorded in the runtime manifest at build time, while the flag *value* is evaluated at runtime from a local snapshot with no network call in the activation decision path.
- [x] **GATE-03**: When a gate denies, route activation fails closed with a structured `:gate_denied` denial carrying an explainable, OpenFeature-shaped reason (`flag_key`, `reason`, `variant`, `evaluated_at`).
- [x] **GATE-04**: Kill switches short-circuit ahead of all other gating and always fail closed (`:kill_switch_active`); the only fail-open path is an explicit, doctor-audited `on_unavailable: :fallback_phoenix` to a fully-owned Phoenix route, never the default.
- [x] **GATE-05**: `mix crosswake.doctor` lists gated routes, flags unknown-referenced flags, and reports each gate's unavailable-posture; support-matrix output surfaces runtime gate state (`gated` / `rolling_out (N%)` / `killed`) labeled distinct from build-proof state.

### MEDIA — Rindle Media Seam (generalization proof)

- [x] **MEDIA-01**: A Phoenix team can model a media upload lane with a typed `UploadGrant` (constrained presign: expiry, max_bytes, accepted_types, key_prefix, idempotency_key), a device-reported `CaptureEvidence` (evidence only), and a `MediaObject` state lane (`:queued | :uploaded | :scanning | :available | :rejected`).
- [x] **MEDIA-02**: Device-reported upload success is non-authoritative; only backend verification advances a media object to `:available`, via a reconciliation vocabulary mirroring `Crosswake.Commerce.Reconciliation`.
- [x] **MEDIA-03**: A runnable pure-Elixir mock upload/verify example proves the media lane end-to-end with no external SDK, enforcing mandatory idempotency and narrow offline-`:queued` semantics (queued media is never presented as committed).

### AUTH — Sigra Auth Contract (contract-only slice)

- [ ] **AUTH-01**: A Phoenix team can model an `AuthContext` (actor_id, org_id, mfa_level, auth_age) and a backend-set-only `SessionAuthorityLane`, with device/client auth signals treated as evidence and never as authority.
- [x] **AUTH-02**: A Phoenix team can declare route auth predicates (`auth_min_level` / `requires_recent_auth`) that fail closed with a `:step_up_required` denial when unmet, surfaced in doctor and support-matrix truth.

### PROOF — Proof Lanes & Docs Contract

- [x] **PROOF-01**: Each shipped companion has a hermetic merge-blocking proof lane that compiles and passes **without** the optional dependency present (proving fail-closed), plus an advisory lane that exercises it with the dependency present.
- [ ] **PROOF-02**: A `guides/companions.md` guide documents the companion-seam pattern and the rulestead/rindle/sigra surfaces, records the deferred sequencing (chimeway seam-only not delivery, full sigra machinery, threadline capstone) as explicit non-goals, and is locked to support-matrix/doctor truth by a docs-contract test.

## Future Requirements (deferred — sequenced for v3.6+)

- **chimeway seam** — push-token lifecycle + deep-link-to-route resolver (fail-closed on route mismatch, never silent-to-home); **NOT** first-party notification delivery (commoditized; provider lock-in). Depends on AUTH `AuthContext`.
- **sigra machinery** — single-use session-handoff tickets, step-up ceremony, native passkey escape hatch (OAuth Auth-Code + PKCE, ~30s refresh-rotation grace window). Requires dedicated security attention outside a pattern-proving milestone.
- **threadline audit capstone** — route/runtime *decision* observability + `ProvenanceLane` (device_claimed evidence vs backend_accepted authority) for offline-replay attribution; PII-masked, append-only with hash-chaining, `Ecto.Multi`-atomic. Consumes COMP/GATE/MEDIA/AUTH contracts → build last.
- **Separate-package extraction** — extract `lib/crosswake/companions/<name>/` to standalone `crosswake_<name>` hex packages (release-please per package, explicit min-compatible core range, cross-package docs-contract test).
- **`mix crosswake.gen.companion` generator** — scaffold a companion impl module + host config once the second companion validates the convention.
- **`crosswake_openfeature` companion** — vendor-neutral flag provider satisfying the same `Crosswake.Companion` behaviour (the OpenFeature-shaped data contract from GATE-03 makes this a drop-in).

## Out of Scope (explicit exclusions)

- **All five companions in one milestone** — auth machinery and push delivery are the highest-blast-radius surfaces (security-incident class); threadline needs the other three stable first. Shipping them now would test the pattern under maximum pressure, contradicting the rulestead-first locking thesis.
- **First-party notification delivery (chimeway)** — commoditized (Knock/Courier/Novu/Pigeon); reimplementing it imports provider lock-in for no seam-pattern gain. Crosswake's value is per-route ownership of deep-link targets, not delivery.
- **Generic plugin-bus / high-frequency companion messaging** — companions stay explicit, bounded, typed, route-local seams. The bridge carries grant requests and state transitions, never chunk-by-chunk progress or arbitrary messages.
- **Companions overriding route ownership** — a companion can only *further restrict* (gate/kill); it can never open a capability that route policy already denied. Per-route runtime ownership stays authoritative.
- **Hard dependency on the OpenFeature `0.x` Elixir SDK** — too early to anchor the first seam; adopt the data shape, not the SDK.
- **Live-provider / device-only proof as the sole proof path** — hermetic merge-blocking lanes must pass with the optional dependency absent; provider/device checks stay advisory.

## Traceability

| REQ-ID | Phase | Status |
|--------|-------|--------|
| COMP-01 | Phase 38 | Complete |
| COMP-02 | Phase 38 | Complete |
| COMP-03 | Phase 38 | Complete |
| GATE-01 | Phase 39 | Complete |
| GATE-02 | Phase 39 | Complete |
| GATE-03 | Phase 40 | Complete |
| GATE-04 | Phase 40 | Complete |
| GATE-05 | Phase 41 | Complete |
| MEDIA-01 | Phase 44 | Complete |
| MEDIA-02 | Phase 44 | Complete |
| MEDIA-03 | Phase 45 | Complete |
| AUTH-01 | Phase 46 | Pending |
| AUTH-02 | Phase 46 | Complete |
| PROOF-01 | Phase 43 + Phase 45 | Complete |
| PROOF-02 | Phase 47 | Pending |
