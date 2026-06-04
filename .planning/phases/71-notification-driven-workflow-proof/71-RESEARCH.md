# Phase 71: Notification-Driven Workflow Proof - Research

**Researched:** 2026-06-04
**Domain:** Chimeway notification-open re-entry, RouteGate activation, Sigra recent-auth authority, denial/redaction truth, hermetic proof lanes
**Confidence:** HIGH - based on Phase 71 context, v4.1 requirements/state/roadmap, Phase 70 plan pattern, Phase 63 notification seam proof, Chimeway/Sigra/RouteGate modules, support/docs/operator truth, and current tests.

## Summary

Phase 71 should be planned as a narrow archetype proof over existing contracts, not as a notification platform. The core deliverable is a deterministic ExUnit proof that simulates a notification tap as typed Chimeway `NotificationOpenEvidence`, resolves it through the real `Crosswake.Companions.Chimeway.Resolver`, and proves `Crosswake.Compatibility.RouteGate` enforces Sigra route auth, especially `requires_recent_auth`, before route activation.

The phase should answer NOTF-01 and NOTF-02 by proving that backend-owned token/binding/open-intent context can be connected to backend-projected Sigra session state and that notification re-entry cannot silently bypass route policy. The merge gate should be hermetic and fast: inline manifest, inline stateful `IntentConsumer`, real Chimeway resolver, real RouteGate, real Sigra contracts/evaluator, fixed timestamps, and no Endpoint/Repo/PubSub/APNs/FCM/device/native delivery dependency.

Recommended plan shape mirrors Phase 70:

1. Wave 0 adds a red proof contract at `test/crosswake/proof/phase71_notification_workflow_proof_test.exs`.
2. Wave 1 closes resolver, denial vocabulary, action-match, redaction, and RouteGate notification-halt behavior until the proof passes.
3. Wave 2 adds targeted CI and any small support/docs/operator truth corrections that prevent delivery or auth overclaims.

Keep the phase boundary narrow: hermetic route-activation proof over Chimeway resolver, RouteGate, and Sigra. Do not add APNs/FCM delivery, a notification center, a generic `NotificationWorkflow`, a generic notification action registry, native tray simulation, endpoint-backed E2E, or a step-up continuation/resume flow.

## Requirement Coverage

| Requirement | Planning Implication |
|-------------|----------------------|
| NOTF-01 | Prove token/binding/open-intent context connects to Sigra session state by modeling backend-owned active/revoked binding state and one-time open intent state before RouteGate evaluates backend-projected `AuthContext`. |
| NOTF-02 | Prove notification re-entry cannot bypass route policy: route id must be manifest-known, `notification_open` must be declared, action must be route-allowed and intent-matched, intent must be valid and one-time, and Sigra recent-auth must allow before activation. |
| PROOF-01 context | Keep the merge-blocking evidence CI-hermetic. Real APNs/FCM delivery remains advisory/non-claim and should not be required for Phase 71 success. |

## Validation Architecture

Phase 71 needs validation architecture before task planning because the risk is not one happy-path route open; it is false confidence from proving the wrong authority boundary. The validation strategy should separate independent dimensions so each failure mode has a clear owner and a falsifiable proof.

### Independent Validation Dimensions

| Dimension | What must be independently proven | Primary evidence |
|-----------|-----------------------------------|------------------|
| Chimeway manifest policy | Unknown routes, routes without `notification_open`, and unsupported actions fail before intent consumption or route activation. | Resolver proof cases plus resolver unit regressions. |
| Backend open-intent lifecycle | Valid, expired, replayed, revoked-binding, binding-mismatch, route-mismatch, and action-mismatch intent states produce canonical Chimeway denials. | Inline stateful `IntentConsumer`; optional example-host registry tests only if registry behavior is changed. |
| RouteGate/Sigra authority | Notification evidence possession never grants auth; missing/stale/weak/revoked/cached/remembered auth contexts deny with `:step_up_required`; fresh MFA/recent backend context activates. | Real `RouteGate.evaluate/4` and real Sigra `AuthContext`/`SessionAuthorityLane` fixtures. |
| Notification-source transition semantics | Notification-source auth denials halt and never redirect to dashboard/home through `on_unavailable` fallback. | RouteGate or resolver proof route with fallback configured. |
| Denial vocabulary and pass-through | Chimeway denials stay in canonical `notification.open.*`; Sigra denials pass through as `auth.step_up.*` instead of being translated to Chimeway codes. | Exact-code assertions in proof and unit tests. |
| Redaction and support safety | Denials, details, telemetry metadata, proof output, and support/operator truth do not leak raw tokens, provider payloads, route params, actor/session refs, device IDs, IPs, emails, or user agents. | Hostile metadata proof plus Chimeway/Sigra sanitizer regressions. |
| Hermeticity and support posture | Merge-blocking proof requires no provider/device/server runtime and makes no APNs/FCM delivery claim. | Source self-scan, targeted CI workflow, support/docs copy checks where touched. |

These dimensions should be sampled independently rather than collapsed into one long scenario. A single integrated happy path should prove the route-activation story, while focused adversarial cases prove each boundary fails closed.

### Proof Sampling Strategy

Use one secure SaaS workflow route as the main positive path, for example `saas_approval` with `entry: :external`, `notification_open: [actions: ["tap", "approve"]]`, `auth_min_level: :mfa`, `requires_recent_auth: 300`, and `auth_posture: :strict_recent`. The positive sample should use:

- active binding;
- issued one-time open intent;
- route/action/binding/open refs that all match;
- backend-projected Sigra `AuthContext`;
- active `SessionAuthorityLane`;
- MFA assurance;
- auth age below 300 seconds.

Then sample adversarial cases by changing exactly one axis per test:

- route policy axis: unknown route, disabled `notification_open`, unsupported action;
- intent axis: expired, replayed, binding revoked, binding mismatch, route mismatch, action mismatch;
- auth axis: missing context, invalid context, insufficient assurance, stale recent auth, revoked lane, remembered lane on strict route, cached lane on strict route, version mismatch if opts expose expected version;
- transition axis: same stale/missing-auth denial on a route with `on_unavailable: {:fallback_phoenix, :dashboard}` must still halt for `activation_source: :notification`;
- redaction axis: hostile metadata added to denied evidence must not leak through public denial details, telemetry metadata, or inspected proof output.

Do not sample APNs/FCM delivery, tray display, Focus/Doze/background behavior, provider credentials, push metrics, read receipts, notification inbox behavior, or native device opens in the merge-blocking proof. Those are different evidence classes.

### Adversarial Cases

Minimum cases for the Phase 71 proof contract:

| Case | Expected public result |
|------|------------------------|
| valid notification open + fresh MFA auth | `{:allow, decision}`, `decision.status == :allow`, `decision.transition == :activate` |
| unknown route id | `:notification_open_denied`, `notification.open.route_mismatch` |
| route lacks notification-open policy | `:notification_open_denied`, `notification.open.policy_denied` |
| unsupported action for route | `:notification_open_denied`, `notification.open.unsupported_action` |
| expired intent | `:notification_open_denied`, `notification.open.expired` |
| replayed intent | `:notification_open_denied`, `notification.open.replayed` |
| revoked/non-active binding | `:notification_open_denied`, `notification.open.binding_revoked` |
| binding mismatch | `:notification_open_denied`, `notification.open.binding_mismatch` |
| route mismatch | `:notification_open_denied`, `notification.open.route_mismatch` |
| action mismatch | `:notification_open_denied`, preferably `notification.open.action_mismatch` |
| missing auth context | `:step_up_required`, `auth.step_up.missing_context`, halt |
| invalid auth context | `:step_up_required`, `auth.step_up.invalid_context`, halt |
| weak assurance | `:step_up_required`, `auth.step_up.insufficient_assurance`, halt |
| stale recent auth | `:step_up_required`, `auth.step_up.stale_auth`, halt |
| revoked authority lane | `:step_up_required`, `auth.step_up.revoked`, halt |
| remembered/cached authority on strict route | existing Sigra remembered/cached denial code, halt |
| fallback route configured | notification-source denial remains `:halt`, not `{:redirect, :dashboard}` |
| hostile metadata in denied evidence | no raw token/payload/PII/route param/session/device values in denial details or telemetry metadata |

### False-Positive Risks

- A proof that constructs `NotificationOpenEvidence.auth_context` can accidentally imply the notification payload grants auth. Test helper names and comments should frame it as backend-projected fixture state.
- Manifest action allowlist alone can hide action laundering. The one-time intent must also be bound to the same `action_ref` as the evidence.
- A valid Chimeway open followed by RouteGate redirect can look like a safe denial while still opening a fallback route. Notification-source denials must halt.
- Interpolated denial codes such as `notification.open.revoked` can pass tests while drifting from canonical public vocabulary `notification.open.binding_revoked`.
- Reusing the example-host registry as the only proof spine can make the merge gate slower and less adversarial, and can obscure resolver/RouteGate behavior behind Repo setup.
- Redaction tests that only check map keys can miss raw values in `inspect(denial)`, telemetry maps, or proof output.
- Advisory APNs/FCM or device checks can be mistaken for shipped delivery support unless CI and docs explicitly state they do not gate merge or promote support posture.
- A step-up continuation flow would be easy to overclaim. Current resolver consumes the open intent before RouteGate auth succeeds, so preserving/resuming intents through step-up has double-consume and lost-continuation risk. Defer it.

### Verification Commands For Phase 71

Primary merge-blocking commands:

```bash
mix test test/crosswake/proof/phase71_notification_workflow_proof_test.exs
mix compile --warnings-as-errors
```

Targeted regressions to include when implementation touches the corresponding surface:

```bash
mix test test/crosswake/companions/chimeway/resolver_test.exs
mix test test/crosswake/companions/chimeway/denial_codes_test.exs
mix test test/crosswake/compatibility/route_gate_test.exs
mix test test/crosswake/proof/phase46_sigra_auth_contract_test.exs
mix test test/crosswake/proof/phase63_notification_seam_proof_test.exs --include requires_example_host
```

If example-host registry action matching or revoked-binding vocabulary is changed, run its registry tests from the repository context the project already uses:

```bash
mix test examples/phoenix_host/test/crosswake_example/chimeway/registry_notification_open_test.exs
```

CI should add `.github/workflows/phase71-proof.yml` with a merge-blocking job that runs compile plus the targeted Phase 71 proof. Any APNs/FCM/provider/device lane should be advisory, `continue-on-error: true`, and explicit that delivery proof is outside Phase 71.

## Existing Contract Spine

### Chimeway Open Evidence

`lib/crosswake/companions/chimeway/contracts.ex` defines:

- `NotificationOpenEvidence` with `route_id`, `open_ref`, `binding_ref`, `provider`, `action_ref`, `auth_context`, `action_kind`, `evaluated_at`, and metadata;
- `OpenResolution` with `open_ref`, `state`, `reason`, `resolved_at`, and metadata;
- token/binding contracts and forbidden public token keys;
- constructors and validation helpers for typed Chimeway records.

Planning implication: the proof can simulate a notification tap without raw APNs/FCM payloads by constructing `NotificationOpenEvidence` directly. Treat `auth_context` as backend-projected test state passed into the resolver API, not as trusted notification payload content.

### Resolver Flow

`lib/crosswake/companions/chimeway/resolver.ex` currently:

1. looks up `evidence.route_id` in the manifest;
2. denies unknown route as `notification.open.route_mismatch`;
3. denies routes without `notification_open`;
4. enforces route-local action allowlist;
5. calls `intent_consumer.consume_intent(evidence)`;
6. delegates valid opens to `RouteGate.evaluate/4` with `activation_source: :notification` and `auth_context: evidence.auth_context`;
7. returns `{:allow, decision}` only when RouteGate allows, otherwise returns RouteGate's denial.

Planning implication: this is the correct proof spine. Do not create a new workflow abstraction. The proof should pressure this exact resolver path and add focused fixes where it currently interpolates arbitrary intent states into public denial codes.

### RouteGate and Sigra

`lib/crosswake/compatibility/route_gate.ex` delegates auth-predicated routes to `Crosswake.Companions.Sigra.Evaluator`, returns `:activate` on allow, and normally halts denied notification/deep-link activations. Current code, however, checks `on_unavailable: {:fallback_phoenix, id}` before checking `activation_source`, so a denied notification-source route with fallback can redirect instead of halt.

`lib/crosswake/companions/sigra/evaluator.ex` denies missing/invalid auth context and revoked, non-active, expired, version-mismatched, remembered, cached, weak-assurance, and stale-auth authority with public shell reason `:step_up_required` and canonical `auth.step_up.*` codes.

Planning implication: use `auth_min_level: :mfa`, `requires_recent_auth: 300`, and `auth_posture: :strict_recent` in the proof route. Missing/stale/weak auth should be Sigra step-up denials, and fresh backend authority should activate.

## Current Gaps To Plan Around

### 1. Revoked Binding Vocabulary Mismatch

Canonical Chimeway vocabulary includes `notification.open.binding_revoked` in `lib/crosswake/companions/chimeway/denial_codes.ex`.

The example-host registry returns `%OpenResolution{state: :revoked}` when a token binding is not active. The resolver currently maps arbitrary states as `"notification.open.#{state}"`, producing `notification.open.revoked`.

Planning implication: lock `notification.open.binding_revoked` as canonical. Either normalize `:revoked` and `:binding_revoked` in the resolver, or have all intent consumers return `:binding_revoked` and update registry/tests accordingly. The resolver should not emit unlisted public codes for known states.

### 2. Action-Ref Mismatch Is Not Checked In Registry

`examples/phoenix_host/lib/crosswake_example/chimeway/notification_open_intent.ex` stores `action_ref`, but `Registry.consume_intent/1` validates state, expiry, binding ref, and route id. It does not compare stored `intent.action_ref` to `evidence.action_ref`.

The resolver enforces the manifest action allowlist, but that only proves the incoming action is allowed for the route. It does not prove the one-time backend intent was issued for that same action.

Planning implication: include an `action_mismatch` negative case in the primary proof. The inline stateful consumer should model it. If the plan claims real example-host precedent alignment, add a small registry fix/test too. Prefer a canonical code `notification.open.action_mismatch`.

### 3. Notification Denials Can Be Redirected By Fallback Routes

`RouteGate.transition_for/3` currently redirects denied routes with `on_unavailable: {:fallback_phoenix, id}` before considering `activation_source`. Phase 71 context requires denied notification activation to halt and not silently fall back to dashboard/home.

Planning implication: add a red proof route with fallback configured and missing/stale auth. Expected behavior should be `transition: :halt` for notification-source auth denials. If current behavior redirects, plan a RouteGate fix and focused unit test.

### 4. Chimeway Denial Vocabulary Lacks Action Mismatch

`lib/crosswake/companions/chimeway/denial_codes.ex` exposes expired, replayed, binding-revoked, route-mismatch, binding-mismatch, unsupported-action, and policy-denied functions, but not action-mismatch.

Planning implication: add `notification_open_action_mismatch/0` if Phase 71 locks this code. Keep detail allowlists narrow; `:action_ref`, `:route_id`, `:binding_ref`, `:open_ref`, `:action_kind`, and `:evaluated_at` are enough.

### 5. Docs May Need Truth Correction

`guides/support_matrix.md` already distinguishes token binding/open routing from APNs/FCM delivery. Prior research observed stale companion-guide language around notification-open routing. The exact docs touched should depend on implementation changes, but support truth must not imply push delivery.

Planning implication: include a small docs/support/operator truth task only if public prose would otherwise contradict the proof. Use language like "notification-open workflow proof is hermetic route activation proof", not "push delivered".

## Recommended Implementation Approach

### 1. Create A Hermetic Phase 71 Proof

Add `test/crosswake/proof/phase71_notification_workflow_proof_test.exs`.

Use:

- `use ExUnit.Case, async: false` for proof-lane predictability, matching Phase 70;
- inline manifest with one secure notification route and focused denial routes;
- inline stateful `IntentConsumer` implementing `Crosswake.Companions.Chimeway.IntentConsumer`;
- fixed timestamps and stable IDs;
- real `Resolver.resolve/3`, `RouteGate.evaluate/4`, and Sigra contract constructors;
- no Endpoint, Repo, PubSub, APNs, FCM, devices, simulators, network, or example-host startup.

Recommended route fixture:

- route id: `"saas_approval"`;
- path: `"/saas/approvals/:approval_id"` or a static route if dynamic params add noise;
- runtime: `:live_view`;
- entry: `:external`;
- `notification_open: [actions: ["tap", "approve"]]`;
- `auth_min_level: :mfa`;
- `requires_recent_auth: 300`;
- `auth_posture: :strict_recent`.

Recommended happy path:

1. Inline consumer has active binding and issued open intent for `"saas_approval"`, `"open_valid"`, and action `"approve"`.
2. Evidence has matching route, open ref, binding ref, provider, and action.
3. Evidence receives backend-projected Sigra `AuthContext` with active `SessionAuthorityLane`, MFA assurance, recent auth age, and non-cached/non-remembered state.
4. Resolver returns `{:allow, decision}`.
5. `decision.status == :allow`.
6. `decision.transition == :activate`.

### 2. Cover The Denial Matrix

Chimeway/open-intent denials:

| Scenario | Expected |
|----------|----------|
| unknown route id | `:notification_open_denied`, `notification.open.route_mismatch` |
| route has no `notification_open` | `:notification_open_denied`, `notification.open.policy_denied` |
| unsupported manifest action | `:notification_open_denied`, `notification.open.unsupported_action` |
| expired intent | `:notification_open_denied`, `notification.open.expired` |
| replayed intent | `:notification_open_denied`, `notification.open.replayed` |
| revoked binding | `:notification_open_denied`, `notification.open.binding_revoked` |
| binding mismatch | `:notification_open_denied`, `notification.open.binding_mismatch` |
| route mismatch | `:notification_open_denied`, `notification.open.route_mismatch` |
| action mismatch | `:notification_open_denied`, `notification.open.action_mismatch` |

Sigra/RouteGate denials:

| Scenario | Expected |
|----------|----------|
| missing auth context | `:step_up_required`, `auth.step_up.missing_context`, halt |
| invalid auth context | `:step_up_required`, `auth.step_up.invalid_context`, halt |
| weak assurance | `:step_up_required`, `auth.step_up.insufficient_assurance`, halt |
| stale recent auth | `:step_up_required`, `auth.step_up.stale_auth`, halt |
| revoked authority lane | `:step_up_required`, `auth.step_up.revoked`, halt |
| remembered authority on strict route | `:step_up_required`, `auth.step_up.remembered_not_allowed`, halt |
| cached authority on strict route | `:step_up_required`, `auth.step_up.cached_not_allowed`, halt |
| fallback route configured | notification-source denial remains halt, not dashboard/home redirect |

Security/redaction denials should include hostile metadata values for raw token keys, raw provider payloads, notification title/body, route params, actor/session refs, device IDs, email, IP, and user agent. Assert those values are absent from denial details, telemetry metadata, and `inspect(denial)`.

### 3. Fix Or Lock Denial Vocabulary

Likely code touch points:

- `lib/crosswake/companions/chimeway/denial_codes.ex`;
- `lib/crosswake/companions/chimeway/resolver.ex`;
- `test/crosswake/companions/chimeway/denial_codes_test.exs`;
- `test/crosswake/companions/chimeway/resolver_test.exs`;
- `examples/phoenix_host/test/crosswake_example/chimeway/registry_notification_open_test.exs`, only if registry behavior is changed.

Preferred resolver mapping:

- `:expired` -> `notification.open.expired`;
- `:replayed` -> `notification.open.replayed`;
- `:revoked` and `:binding_revoked` -> `notification.open.binding_revoked`;
- `:binding_mismatch` -> `notification.open.binding_mismatch`;
- `:route_mismatch` -> `notification.open.route_mismatch`;
- `:action_mismatch` -> `notification.open.action_mismatch`;
- unknown/invalid states -> conservative policy denial or an explicit stable invalid-intent code only if public vocabulary is extended deliberately.

Do not translate Sigra `auth.step_up.*` denial codes into Chimeway codes. When RouteGate denies auth, `Resolver.resolve/3` should preserve the `:step_up_required` reason and Sigra code.

### 4. Wire A Targeted CI Proof Lane

Add `.github/workflows/phase71-proof.yml` based on the Phase 70/48 pattern.

Recommended properties:

- name: `Phase 71 Proof`;
- `permissions: contents: read`;
- pinned `actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd`;
- pinned `erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93`;
- Elixir `1.19.5`, OTP `27.3`;
- PR, push to main, workflow_dispatch with lane input, and weekly schedule;
- merge-blocking job:
  - `mix deps.get`;
  - `mix compile --warnings-as-errors`;
  - `mix test test/crosswake/proof/phase71_notification_workflow_proof_test.exs`;
- advisory provider/device job:
  - `continue-on-error: true`;
  - prints notices that APNs/FCM delivery, tray behavior, Focus/Doze/background delivery, and real devices do not gate merge or auto-promote support posture.

## Existing Files And Patterns To Reuse

### Core Modules

| File | Key Planning Use |
|------|------------------|
| `lib/crosswake/companions/chimeway/contracts.ex` | Build `NotificationOpenEvidence` and `OpenResolution` fixtures. |
| `lib/crosswake/companions/chimeway/resolver.ex` | Main proof spine from evidence to manifest policy to RouteGate. |
| `lib/crosswake/companions/chimeway/intent_consumer.ex` | Behaviour for inline test consumer. |
| `lib/crosswake/companions/chimeway/denial_codes.ex` | Canonical Chimeway open denial codes and details sanitizer. |
| `lib/crosswake/companions/chimeway/telemetry.ex` | Forbidden notification metadata and low-cardinality telemetry contract. |
| `lib/crosswake/compatibility/route_gate.ex` | Activation decision, auth delegation, and transition behavior. |
| `lib/crosswake/companions/sigra/contracts.ex` | Construct backend-owned `AuthContext` and `SessionAuthorityLane`. |
| `lib/crosswake/companions/sigra/evaluator.ex` | Canonical Sigra route-auth denial behavior. |
| `lib/crosswake/companions/sigra/denial_codes.ex` | Sanitized `auth.step_up.*` detail vocabulary. |
| `lib/crosswake/manifest/types.ex` | Inline manifest and `RouteEntry` structs. |
| `lib/crosswake/shell/denial.ex` | Public denial reason envelope. |

### Example-Host Precedent

| File | Key Planning Use |
|------|------------------|
| `examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex` | Ecto-backed one-time intent lifecycle precedent; useful for optional registry gap fixes, not merge-gate spine. |
| `examples/phoenix_host/lib/crosswake_example/chimeway/notification_open_intent.ex` | Stored `action_ref` exists and should be compared during consume. |
| `examples/phoenix_host/lib/crosswake_example/chimeway/token_binding.ex` | Binding state precedent. |
| `examples/phoenix_host/lib/crosswake_example/chimeway/metadata_sanitizer.ex` | Host metadata allowlist precedent. |

### Existing Tests And Proofs

| File | Reuse Pattern |
|------|---------------|
| `test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs` | Immediate prior archetype proof shape: product story, adversarial matrix, hermetic self-scan, CI-targeted lane. |
| `test/crosswake/proof/phase63_notification_seam_proof_test.exs` | Prior Chimeway seam proof with example-host registry; use as context, not primary merge gate. |
| `test/crosswake/companions/chimeway/resolver_test.exs` | Existing resolver unit coverage for route, policy, action, intent state, and Sigra pass-through. |
| `examples/phoenix_host/test/crosswake_example/chimeway/registry_notification_open_test.exs` | Registry lifecycle coverage; extend if fixing action mismatch/revoked binding. |
| `test/crosswake/compatibility/route_gate_test.exs` | Sigra denial matrix and RouteGate precedence. |
| `test/crosswake/proof/phase46_sigra_auth_contract_test.exs` | Hermetic auth proof style and detail sanitization assertions. |
| `test/support/proof_assertions.ex` | Stable proof assertion helpers if docs/support parity is touched. |

## Risks And Footguns

- **Silent bypass via fallback:** RouteGate fallback redirects can hide notification auth denials unless notification-source denials are asserted to halt.
- **Action laundering:** Manifest action allowlist is not enough if a valid one-time intent for action A can be consumed with action B.
- **Denial vocabulary drift:** `notification.open.revoked` vs `notification.open.binding_revoked` will confuse support truth unless normalized.
- **Auth payload trust:** `NotificationOpenEvidence.auth_context` exists in the struct, but Phase 71 must frame it as backend-projected fixture state, never payload-granted auth.
- **Double-consume on step-up:** Current resolver consumes the open intent before RouteGate auth succeeds. A full step-up continuation flow could lose the intent or double-consume. Keep continuation deferred unless explicitly scoped.
- **Overclaiming push delivery:** The phase proves notification-open semantics after simulated evidence, not APNs/FCM delivery, notification tray behavior, delivery metrics, Focus/Doze behavior, or provider credential setup.
- **Leaky denial details:** Raw tokens, payloads, route params, actor/session refs, device IDs, IPs, emails, and user agents must not appear in denial details, telemetry, or proof output.
- **Slow proof path:** Reusing the example-host Repo path as the main proof would make the merge gate slower and less adversarial than necessary.
- **New abstraction creep:** A generic `NotificationWorkflow` or action registry would violate the phase boundary. Route-local manifest policy plus backend intent state is enough.

## Recommended Plan Split

1. **Plan 71-01: Red hermetic proof contract.** Add `phase71_notification_workflow_proof_test.exs` with inline manifest, inline stateful consumer, positive open path, Chimeway denial cases, Sigra denial cases, redaction assertions, and fallback-bypass assertion. Expected red failures should expose resolver vocabulary, action matching, or RouteGate fallback gaps.
2. **Plan 71-02: Resolver, vocabulary, and authority closure.** Normalize Chimeway denial mapping, add/lock action mismatch vocabulary, preserve Sigra pass-through denials, add resolver/unit regressions, and adjust RouteGate notification-source transition logic if the red proof exposes fallback redirect behavior.
3. **Plan 71-03: CI and truth closure.** Add `phase71-proof.yml`, run targeted regressions, and update support/docs/operator copy only where needed to say Phase 71 is hermetic route-activation proof, not APNs/FCM delivery proof.

Optional registry work can be included in Plan 71-02 only if the planner decides example-host precedent should be aligned in the same phase. It should not replace the hermetic inline proof.

## Verification Strategy

Primary:

```bash
mix test test/crosswake/proof/phase71_notification_workflow_proof_test.exs
mix compile --warnings-as-errors
```

Regression commands to include in later plan verification:

```bash
mix test test/crosswake/companions/chimeway/resolver_test.exs
mix test test/crosswake/companions/chimeway/denial_codes_test.exs
mix test test/crosswake/compatibility/route_gate_test.exs
mix test test/crosswake/proof/phase46_sigra_auth_contract_test.exs
mix test test/crosswake/proof/phase63_notification_seam_proof_test.exs --include requires_example_host
```

If registry behavior is changed:

```bash
mix test examples/phoenix_host/test/crosswake_example/chimeway/registry_notification_open_test.exs
```

CI:

- `.github/workflows/phase71-proof.yml` should make the Phase 71 proof merge-blocking.
- Any APNs/FCM or device-delivery job should be advisory, scheduled or manually dispatched, and `continue-on-error: true`.

## Open Questions

None blocking for planning. The remaining planning choices are sequencing choices:

- whether to align example-host registry action matching in the same phase or keep it as supporting precedent;
- whether docs/support truth needs a Phase 71 update after the proof lands;
- the exact plan wave boundary between resolver-denial closure and RouteGate fallback-halt closure.

## RESEARCH COMPLETE
