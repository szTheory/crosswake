# Phase 61: Notification-Open Resolver And Route Policy - Context

**Gathered:** 2026-06-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Resolve notification-open evidence (notification/open/action refs + route id) into a validated, gated route activation through manifest-known routes, core RouteGate (`activation_source: :notification`), and Sigra session authority — failing closed with stable notification denial codes and no silent dashboard/home fallback.

**Delivers (OPEN-01, OPEN-02, OPEN-03):**
- A Chimeway-owned notification-open envelope contract (`NotificationOpenEvidence` + `OpenResolution`) and a `Crosswake.Companions.Chimeway.Resolver` that validates the open and delegates route activation to core RouteGate.
- A one-time-consumable, host-owned notification-open-intent record in `examples/phoenix_host` that makes expired/replayed/binding-mismatched detection deterministic and hermetic-provable.
- A new additive route-policy DSL attribute (`notification_open:`) that declares per-route notification-open eligibility (and an optional action-ref allowlist), default fail-closed.
- A notification denial vocabulary: a new core `Shell.Denial` reason `:notification_open_denied` plus a `Crosswake.Companions.Chimeway.DenialCodes` subcode module, with RouteGate/Sigra denials (`:step_up_required`, `:gate_denied`, etc.) passed through unchanged.

**In scope:**
- Chimeway notification-open contracts, resolver orchestration, and the open-intent consume flow (example-host `Ecto.Multi`).
- Route-DSL `notification_open:` attribute (schema validation → manifest materialization → support/compatibility surfacing).
- Core `Shell.Denial` reason atom addition + Chimeway denial subcodes and sanitizer.
- Flipping `Chimeway.report_state` `open_routing: :not_shipped` → `:active`.
- Hermetic contract/proof tests for resolution, expiry, replay, route/binding mismatch, unsupported action, policy/auth denial, and Sigra step-up reuse.

**Out of scope:**
- Broad doctor/operator/support-matrix/docs-contract expansion and telemetry rollout — Phase 62 (DIAG-01/DIAG-02), except the minimal denial/telemetry hooks Phase 61 needs to fail closed.
- Merge-blocking proof lane consolidation and advisory promotion criteria — Phase 63 (PROOF-01/PROOF-02).
- Real APNs/FCM delivery, real push open behavior, provider credentials, notification-tray/Focus/Doze behavior, action-button delivery — advisory/deferred.
- Production-normalized token/device/installation model and bundled workers (carried from Phase 60 deferred).

</domain>

<decisions>
## Implementation Decisions

### 1. Anti-Replay / Expiry Model — LOCKED (server-side open-intent record)
- **D-01:** Notification opens are validated against a **host-owned, one-time-consumable open-intent record** in `examples/phoenix_host`, NOT a stateless signed envelope. This directly mirrors the repo's existing `sigra_handoff_tickets` / `sigra_step_up_intents` one-time-consume-via-`Ecto.Multi` prior art.
- **D-02:** Add one new example-host table `chimeway_notification_open_intents` (name is planner discretion; prefer this for contract alignment) with at least: `open_ref`, `binding_ref`, `route_id`, `action_ref`, `subject/session/installation scope` (as needed for binding-mismatch checks), `state`, `expires_at`, `consumed_at`, timestamps, and sanitized `metadata`. Add an append-only audit row in the same transaction, consistent with the Phase 60 registry pattern.
- **D-03:** The server **issues** the open-intent when it sends the push; the notification open **consumes** it. Consume is a guarded `Ecto.Multi` flow: load intent → validate → mark consumed → audit → (on success) telemetry after commit.
- **D-04:** Detection falls out of the record as column compares:
  - **expired** = `expires_at < now`
  - **replayed** = `state == :consumed` (or otherwise non-pending)
  - **binding-mismatch** = stored `binding_ref`/`route_id`/scope ≠ envelope, OR the referenced Chimeway binding is no longer `:active`
  - **revoked** = referenced binding `state` is `:revoked`/`:superseded`/`:stale`/`:invalid` (Phase 59 vocabulary)
- **D-05:** Real push delivery stays **advisory**. The intent issue + consume cycle is fully hermetic/in-tree provable without any APNs/FCM dependency. Do not treat provider delivery acceptance as proof an open is valid.
- **D-06:** Raw tokens, provider payloads, notification title/body, route params, and PII must never enter the open-intent row, audit, denials, or telemetry (carry Phase 59/60 redaction posture).

### 2. Resolver Placement + RouteGate Integration — LOCKED (Chimeway resolver delegates to core RouteGate)
- **D-07:** Notification-open **resolver evaluation lives in the Chimeway companion** — `Crosswake.Companions.Chimeway.Resolver` (module name is planner discretion but strongly preferred). Core stays provider-neutral; this matches the StoreKit/PlayBilling/Sigra precedent of companions normalizing/orchestrating and feeding core.
- **D-08:** **Core `RouteGate` requires zero changes** beyond already accepting `activation_source: :notification`. Do NOT add a notification-specific branch inside `RouteGate` — that would leak notification vocabulary into core.
- **D-09:** Resolver public shape (planner discretion on exact spec, preserve intent):
  ```elixir
  @spec resolve(Root.t(), OpenEnvelope.t()) ::
          {:ok, RouteGate.Decision.t()} | {:error, Shell.Denial.t()}
  ```
  where `OpenEnvelope` / `NotificationOpenEvidence` is a Chimeway-namespaced struct holding `route_id`, `notification_ref`/`open_ref`, `action_ref`, `binding_ref`, `provider`, `source`, `opened_at`, `correlation_ref`, `auth_context`, and bounded evidence metadata.
- **D-10:** Resolver pre-flight (companion-owned, BEFORE delegating): (1) `route_id` present in `manifest.routes`; (2) consume the open-intent → expiry/replay/binding-mismatch/revoked checks; (3) route declares notification-open eligibility and the `action_ref` is permitted (see Decision 3).
- **D-11:** After pre-flight passes, the resolver calls `RouteGate.evaluate(manifest, route_id, target, activation_source: :notification, auth_context: envelope.auth_context, ...)` and returns the `Decision.t()` directly. RouteGate already runs kill-switch → gate → Sigra auth → compatibility → commerce, so **Sigra session-authority + step-up reuse is automatic (OPEN-02)** with no duplicated auth logic.
- **D-12:** A `:deny` decision carrying `reason: :step_up_required` is the step-up signal — surfaced to the caller as-is, never re-wrapped.
- **D-13:** Flip `Chimeway.report_state` detail `open_routing: :not_shipped` → `:active` once the resolver ships. Update the matching support-matrix/companion non-claim only as narrowly as Phase 61 requires (broad docs are Phase 62).

### 3. Route-Policy Notification-Open Opt-In — LOCKED (new additive `notification_open:` DSL attribute) ⚠️ public API
- **D-14:** Add a **new optional per-route DSL attribute** `notification_open:` to the route policy. Default **absent = fail-closed**: routes that do not declare it cannot be activated from a notification.
- **D-15:** Shape: `notification_open: true | [actions: [atom()]]`. `true` opts the route in without action constraint; the `[actions: [...]]` allowlist constrains which named `action_ref`s the route accepts and is what makes the OPEN-03 **"unsupported-action"** denial mechanically expressible. (Final keyword/shape is planner discretion if it preserves: explicit opt-in, fail-closed default, and action-level allowlisting capability.)
- **D-16:** Mirror the existing `entry: :external` + `allowlisted_origins` precedent — push-sourced entry is a **distinct threat vector** from deep-link entry and must not be collapsed into it. Do NOT make any manifest-known route implicitly notification-openable.
- **D-17:** Additive/backward-compatible public API: new optional keyword on an existing `route/0` call; no existing call signatures change. Materialize into the manifest `RouteEntry` + builder, validate in `policy/schema.ex` (mirror `validate_external_entry`-style validation), and surface in compatibility findings. Manifest schema version bump may be required if the field is materialized — planner to confirm.

### 4. Notification Denial Vocabulary — LOCKED (new core reason + Chimeway subcodes) ⚠️ public API
- **D-18:** Add **one new core reason atom** `:notification_open_denied` to `Shell.Denial @reasons` (and its `@type reason`). Rationale: discrete failure classes get their own reason in this repo (e.g. `:step_up_required` is its own reason, not buried under `:gate_denied`) so operator/support/telemetry tooling can pattern-match cleanly without inspecting `.code`.
- **D-19:** Add a **`Crosswake.Companions.Chimeway.DenialCodes`** module mirroring `sigra/denial_codes.ex` (canonical string subcodes + `sanitize_details/1` allowlist). Canonical subcodes (under `reason: :notification_open_denied`; exact strings planner discretion, preserve coverage):
  - `notification.open.expired`
  - `notification.open.replayed`
  - `notification.open.binding_revoked`
  - `notification.open.route_mismatch`
  - `notification.open.binding_mismatch`
  - `notification.open.unsupported_action`
  - `notification.open.policy_denied` (generic catch-all per OPEN-03 wording)
- **D-20:** **Pass RouteGate/Sigra denials through UNCHANGED.** `:step_up_required` (with `auth.step_up.*` codes), `:gate_denied`, `:kill_switch_active`, compatibility, and commerce denials retain their original reason/code — the resolver does NOT re-wrap them. The new `:notification_open_denied` codes cover only the resolver-level **pre-gate** failures (expired/replayed/revoked/route-mismatch/binding-mismatch/unsupported-action).
- **D-21:** Sanitized detail-key allowlist mirrors the locked Chimeway forbidden-key posture (Phase 59 telemetry `@forbidden_metadata_keys`). Safe keys: `open_ref`, `binding_ref`, `binding_state`, `action_kind`, `provider`, `platform`, `environment`, `evaluated_at`/`occurred_at`, `correlation_id`/`correlation_ref`. Forbidden: raw/device/apns/fcm tokens, provider payloads/response bodies, notification title/body, route params, actor/subject/session/device identifiers (where unsafe for support output), IP, user agent, email.

### Claude's Discretion
- Exact module names (`Resolver`, `OpenEnvelope`/`NotificationOpenEvidence`, `OpenResolution`, `DenialCodes`), struct keys, and the open-intent table/migration names — preserve the locked semantics above.
- Exact `notification_open:` keyword spelling and whether action allowlist is `[actions: [...]]` vs a flatter form — preserve explicit opt-in + fail-closed default + action allowlisting.
- Exact denial subcode strings, telemetry event names, and idempotency/consume-key shape — preserve stability, low cardinality, and sanitization.
- Test file placement (`test/crosswake/companions/chimeway/`, `test/crosswake/proof/phase61_*`, and/or example-host tests), following existing phase-proof conventions.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/PROJECT.md` — Crosswake thesis, v3.9 goal, constraints, non-goals, Chimeway companion-first decision, and the "no first-party push delivery guarantee in v3.9" boundary.
- `.planning/REQUIREMENTS.md` — OPEN-01/OPEN-02/OPEN-03 active requirements and v3.9 out-of-scope delivery/action boundaries.
- `.planning/ROADMAP.md` — Phase 61 goal + success criteria, and adjacent Phase 59/60/62/63 boundaries.
- `.planning/STATE.md` — current workflow position and deferred provider/device proof posture.
- `.planning/research/v3.9/SUMMARY.md` — v3.9 Chimeway research: `NotificationOpenEvidence`/`OpenResolution` shape, RouteGate+Sigra reuse, open-resolver decision points, failure modes, and merge-blocking-vs-advisory proof posture.

### Prior Crosswake decisions (this milestone)
- `.planning/phases/59-chimeway-contract-and-token-binding-semantics/59-CONTEXT.md` — Chimeway contract family, lifecycle states/reasons, evidence/authority boundary, raw-token redaction, forbidden-key posture.
- `.planning/phases/60-example-host-registry-and-phoenix-wiring/60-CONTEXT.md` — host registry shape, `Ecto.Multi` lifecycle, append-only audit rows, post-commit telemetry, idempotency, and optional-worker boundary.

### Prior Crosswake decisions (Sigra one-time-record + auth prior art)
- `.planning/milestones/v3.8-phases/55-session-handoff-tickets-and-authority-projection/55-CONTEXT.md` — one-time handoff ticket server-record + host projection pattern (the anti-replay analog).
- `.planning/milestones/v3.8-phases/56-step-up-intent-and-plug-liveview-ceremony/56-CONTEXT.md` — `Ecto.Multi` consume/audit/projection + session-scope lessons (the open-intent consume analog).
- `.planning/milestones/v3.8-phases/54-sigra-session-authority-contract-and-route-gate-semantics/54-CONTEXT.md` — backend-owned session authority and shell/client non-authority.
- `.planning/milestones/v3.8-phases/58-auth-diagnostics-proof-and-security-closeout/58-CONTEXT.md` — telemetry registry, forbidden metadata, denial-code/sanitizer posture.

### Existing Crosswake code — integration surface (confirmed during scout)
- `lib/crosswake/compatibility/route_gate.ex` — `evaluate(%Root{}, route_id, %Target{}, opts) :: Decision.t()`; already accepts `activation_source` (incl. `:notification`); fail-closed pipeline kill-switch → gate → Sigra auth → compatibility → commerce. **No changes needed.**
- `lib/crosswake/shell/activation.ex` — `Request.source` already includes `:notification`; route-id resolution + `manifest.routes` lookup.
- `lib/crosswake/shell/denial.ex` — `Shell.Denial` struct + fixed `@reasons` list (add `:notification_open_denied`).
- `lib/crosswake/companions/sigra/evaluator.ex` — `evaluate_route_auth/3` → `{:allow, Result} | {:deny, Denial(reason: :step_up_required)}`; the reuse path for OPEN-02.
- `lib/crosswake/companions/sigra/denial_codes.ex` — canonical subcode + `sanitize_details/1` pattern to mirror for `Chimeway.DenialCodes`.
- `lib/crosswake/companions/sigra/{handoff,step_up}.ex` — one-time server-record consume-via-`Ecto.Multi` prior art for the open-intent record.
- `lib/crosswake/companions/chimeway/contracts.ex` — Phase 59 `TokenEvidence`/`TokenBinding`/`ProviderFeedback`/`BindingEvent`/`BindingResult`; add `NotificationOpenEvidence`/`OpenResolution`.
- `lib/crosswake/companions/chimeway/{redaction,telemetry}.ex` — raw-token boundary + stable events + forbidden-key sanitizer to reuse.
- `lib/crosswake/companions/chimeway.ex` — companion entrypoint; flip `report_state` `open_routing: :not_shipped` → `:active`.
- `lib/crosswake/policy/route.ex` + `lib/crosswake/policy/schema.ex` — route DSL + validation (add `notification_open:`); mirror `validate_external_entry`.
- `lib/crosswake/manifest/types.ex` (`Root`, `RouteEntry`) + `lib/crosswake/manifest/builder.ex` — materialize the new attribute; `manifest.routes` is the manifest-known route source of truth.
- `lib/crosswake/compatibility/compatibility.ex` — `route_findings/4`; mirror external-entry validation for notification-open eligibility/unsupported-action.
- `lib/crosswake/support_matrix/support_matrix.ex` — `notification_open_routing` deferred feature + non-claim message to flip narrowly (broad update is Phase 62).
- Example-host analogs for the open-intent table: `examples/phoenix_host/lib/crosswake_example/saas_portal/handoff.ex` (Multi issue/redeem/revoke), `handoff_ticket.ex` (lifecycle schema), `auth_return_attempt.ex` (`Ecto.Enum` style), and `examples/phoenix_host/priv/repo/migrations/2026060206*_create_sigra_handoff_*.exs` (lifecycle + audit migration analogs); plus Phase 60 Chimeway registry/migrations once landed.

### Prompt corpus
- `prompts/crosswake-brand-book.md` — boundary-aware, anti-hype positioning.
- `prompts/crosswake-elixir-oss-dna.md` — maintainer house style: install/support truth, proof lanes, narrow public APIs.
- `prompts/crosswake-integrations-and-companions.md` — Chimeway companion classification + notification-journey visibility goals.
- `prompts/crosswake-research-synthesis.md` — route-policy/runtime-boundary thesis.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` — notification/deep-link boundary and mobile archetype pressure.
- `prompts/elixir-mobile-oss-lib-deep-research.md` / `prompts/elixir-mobile-oss-refined-plan-deep-research.md` — bridge command/event plane, push/deep-link boundary, support-truth/DX lessons.

### External primary references checked during discussion
- `https://hexdocs.pm/ecto/Ecto.Multi.html` — one-time consume + transactional lifecycle for the open-intent record.
- `https://firebase.google.com/docs/cloud-messaging/manage-tokens` / `https://developer.apple.com/documentation/usernotifications` — provider open/delivery behavior that must remain advisory, not authority.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Compatibility.RouteGate.evaluate/4` already accepts `activation_source: :notification` and runs the full fail-closed pipeline including Sigra auth — the resolver delegates here unchanged.
- Sigra `handoff`/`step_up` server-record + `Ecto.Multi` consume flow is a direct template for the notification-open-intent record.
- Sigra `denial_codes.ex` (subcodes + `sanitize_details/1`) is the template for `Chimeway.DenialCodes`.
- Phase 59 Chimeway `contracts`/`redaction`/`telemetry` provide the evidence vocabulary, raw-token boundary, and forbidden-key sanitizer to extend with open evidence.
- Route-DSL `entry: :external` + `allowlisted_origins` + `external_entry_denied` is the precedent the `notification_open:` attribute mirrors.

### Established Patterns
- Core stays provider-neutral; companions orchestrate and feed core. Notification-open vocabulary lives only in Chimeway + the route DSL, never inside RouteGate's branch logic.
- Device/provider/shell facts are evidence only; backend records (binding, open-intent) + RouteGate/Sigra are the authority. Token/open possession never grants route activation.
- Discrete failure classes get their own `Shell.Denial @reasons` atom for clean operator/support pattern-matching.
- One-time server records consumed in `Ecto.Multi`, append-only audit in the same transaction, telemetry only after commit.
- Provider/device proof stays advisory until explicit promotion criteria pass.

### Integration Points
- New: `lib/crosswake/companions/chimeway/resolver.ex` (+ open-evidence/resolution contracts in `contracts.ex`, `chimeway/denial_codes.ex`).
- Core edit: add `:notification_open_denied` to `lib/crosswake/shell/denial.ex` `@reasons`.
- Route DSL: `policy/route.ex` + `policy/schema.ex` → `manifest/types.ex` + `manifest/builder.ex` → `compatibility/compatibility.ex`.
- Example host: new `chimeway_notification_open_intents` schema + migration + consume flow under `examples/phoenix_host`, following Phase 60 registry conventions.
- Phase 62 consumes the resolver/denial/support truth for doctor/operator/docs; Phase 63 consolidates merge-blocking proof + advisory promotion criteria. Keep Phase 61 docs/diagnostics narrow.

</code_context>

<specifics>
## Specific Ideas

- Recommended resolver flow:
  ```elixir
  # Crosswake.Companions.Chimeway.Resolver
  def resolve(%Root{} = manifest, %OpenEnvelope{} = env) do
    with :ok <- manifest_known_route(manifest, env.route_id),
         {:ok, intent} <- consume_open_intent(env),        # expiry / replay / binding-mismatch / revoked
         :ok <- action_allowed?(manifest, env.route_id, env.action_ref) do  # unsupported-action
      RouteGate.evaluate(manifest, env.route_id, target_from(env),
        activation_source: :notification, auth_context: env.auth_context)
      |> wrap_decision()   # :deny step_up_required / gate_denied passed through unchanged
    else
      {:error, %Shell.Denial{}} = denial -> denial   # :notification_open_denied.* subcodes
    end
  end
  ```
- Open-intent issue/consume mirrors `examples/phoenix_host/.../saas_portal/handoff.ex` issue/redeem `Ecto.Multi`, swapping handoff semantics for notification-open semantics.
- Route DSL example: `notification_open: [actions: [:view_order, :open_thread]]` on a route; absent → notification opens fail closed with `notification.open.policy_denied` (or route_mismatch as appropriate).
- Denial reason/code split: resolver pre-gate failures → `reason: :notification_open_denied`, `code: "notification.open.*"`; RouteGate/Sigra failures keep their original `reason`/`code` (`:step_up_required` + `auth.step_up.*`, `:gate_denied`, etc.).

</specifics>

<deferred>
## Deferred Ideas

- Broad doctor, operator inspection, support-matrix, docs-contract parity, and telemetry rollout for notification token/open readiness — Phase 62 (DIAG-01/DIAG-02).
- Merge-blocking proof-lane consolidation and APNs/FCM advisory promotion criteria — Phase 63 (PROOF-01/PROOF-02).
- Real APNs/FCM token issuance/rotation, real push delivery + notification-open behavior on devices/simulators, provider credentials, project/package/topic mismatch checks, notification-tray/Focus/Doze/background/action-button behavior, and provider console metrics — advisory/future work.
- Production-normalized token/device/installation/subject model and bundled Chimeway/Oban/Quantum/Broadway workers — carried from Phase 60 deferred.
- Stateless signed notification-open envelope (exp+nonce, no DB) — considered and rejected for Phase 61 in favor of the server-side open-intent record; revisit only if a future no-DB / offline-open use case appears.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.

</deferred>

---

*Phase: 61-Notification-Open Resolver And Route Policy*
*Context gathered: 2026-06-03*
