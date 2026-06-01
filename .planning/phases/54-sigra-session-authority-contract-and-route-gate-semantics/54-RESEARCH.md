# Phase 54: Sigra Session Authority Contract And Route-Gate Semantics - Research

**Researched:** 2026-06-01
**Domain:** Phoenix/Elixir backend-owned auth session authority and route-gate evaluation
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Use a hybrid backend-projection model: `SessionAuthorityLane` is the authoritative backend projection consumed by route gates, while handoff tickets, step-up intents, OAuth returns, passkey assertions, and native events remain bounded evidence/envelopes until a backend flow promotes them. Do not make token claims, bridge payloads, provider returns, or cached client state route authority.
- **D-02:** Evolve `SessionAuthorityLane` from the Phase 46 minimal shape into an explicit lifecycle contract. Required fields should cover: `session_id` or opaque reference, `subject_id`/actor reference, `org_id`, `state`, `assurance_level`, `authn_methods`, `authenticated_at`, `last_seen_at`, `idle_expires_at`, `absolute_expires_at`, `renew_after` or renewal horizon, remembered-session posture, `session_version`, `revoked_at`, and `as_of`.
- **D-03:** Keep vocabularies closed and comparable. Recommended authority states: `:active`, `:step_up_required`, `:expired`, `:revoked`, `:suspended`. Recommended assurance levels preserve Phase 46 ordering: `:none`, `:password`, `:mfa`, `:phishing_resistant`.
- **D-04:** `AuthContext` should remain the route-evaluation input wrapper, but it should derive freshness and assurance from the backend-owned `SessionAuthorityLane` rather than duplicating authority in loosely related fields. Backward-compatible aliases from Phase 46 (`mfa_level`, `auth_age`) may remain temporarily if tests prove they map into the new lane without ambiguity.
- **D-05:** Validators must reject evidence or client-provided attrs that try to set authority fields (`state`, `assurance_level`, `mfa_level`, `authn_methods`, `authenticated_at`, expiry fields, `session_version`, revocation fields, access grants). Follow the Rindle and Phase 46 authority-fence pattern.
- **D-06:** Use `DateTime` or ISO8601-normalized timestamps at the contract boundary, but route evaluation should compare normalized seconds/timestamps through helper functions so manifest JSON and tests remain deterministic.
- **D-07:** Preserve `:step_up_required` as the single public shell denial reason for auth route activation failures in Phase 54. Do not add broad shell-level reasons such as `:auth_missing`, `:auth_revoked`, or `:auth_stale` yet; that would churn shell fixtures and support truth before handoff, ceremony, and return boundaries have landed.
- **D-08:** Add a stable auth code namespace underneath the shell reason. Recommended initial codes:
  - `auth.step_up.missing_context`
  - `auth.step_up.invalid_context`
  - `auth.step_up.non_active`
  - `auth.step_up.idle_expired`
  - `auth.step_up.absolute_expired`
  - `auth.step_up.revoked`
  - `auth.step_up.version_mismatch`
  - `auth.step_up.insufficient_assurance`
  - `auth.step_up.stale_auth`
  - `auth.step_up.remembered_not_allowed`
  - `auth.step_up.cached_not_allowed`
- **D-09:** Shell-facing denial messages stay generic and user-safe. Operator/developer surfaces may show stable auth codes and low-cardinality metadata, but must not expose raw tokens, OAuth artifacts, passkey credential IDs, session IDs, actor IDs, provider payloads, or PII.
- **D-10:** Canonical shell-safe denial details should be allowlisted, not filtered opportunistically. Allowed examples: `required_assurance_level`, `current_assurance_level`, `max_auth_age_seconds`, `auth_age_seconds`, `auth_posture`, `authority_state`, `evaluated_at`, and sanitized `challenge_ref`/`step_up_token_ref` references with strict length/format checks.
- **D-11:** RouteGate failure ordering remains security-specific and fail-closed: kill switch, companion gate, Sigra auth evaluator, then compatibility/commerce findings. Auth predicates can only deny; they cannot allow a route denied by another layer.
- **D-12:** Doctor, support matrix, operator inspection, guide text, fixture proof, and docs-contract tests must source codes/details from one canonical registry or accessor. Avoid parallel lists in prose, tests, and formatters.
- **D-13:** Introduce an explicit route-local auth posture enum instead of split booleans. Recommended values:
  - `:strict_recent`
  - `:remembered_ok`
  - `:cached_read_only_ok`
- **D-14:** Default posture should be strict and resolved visibly. Sensitive routes and routes with `requires_recent_auth` resolve to `:strict_recent` unless a future, explicit, auditable exception exists. Do not infer weaker posture from remembered cookies, mobile cache presence, or native session continuity.
- **D-15:** Keep weakening explicit at the route policy layer and serialized into manifest/operator truth.
- **D-16:** `:cached_read_only_ok` requires cross-field validation against route offline/runtime/security metadata so mutation-capable, sensitive, billing, admin, auth, commerce purchase/restore, and native authority-promotion routes cannot accidentally use cached auth. If the validator cannot prove read-only/degraded posture, fail closed.
- **D-17:** Remembered and cached auth failures should deny with `:step_up_required` plus code (`auth.step_up.remembered_not_allowed` or `auth.step_up.cached_not_allowed`), not silently downgrade to compatibility or cache fallback.
- **D-18:** Add a thin reusable Sigra route-auth evaluator seam in Phase 54, but do not implement step-up ceremony.
- **D-19:** `RouteGate.evaluate/4` remains the canonical route activation decision, but it should call the shared evaluator rather than embedding all Sigra checks directly.
- **D-20:** The evaluator result should carry normalized denial code, safe details, and low-cardinality facts. It must not know how to issue step-up intents, redirect controllers, halt LiveView mounts, renew Phoenix sessions, or rotate CSRF tokens.
- **D-21:** Design the evaluator so Phase 56 Plug/controller and LiveView `on_mount` wrappers can share one decision core.
- **D-22:** Avoid a generic policy engine abstraction. This seam is Sigra-specific and route-auth-specific.
- **D-23:** Phoenix/Plug lesson: server-side session state and `configure_session(conn, renew: true)` belong at the host boundary after successful auth/step-up/handoff. Phase 54 should model the requirement and leave renewal execution to Phase 56.
- **D-24:** Phoenix LiveView lesson: controller plugs and LiveView `on_mount` need shared decisions but different transport handling. The evaluator seam should prevent duplicate auth semantics across those entry points.
- **D-25:** OWASP/NIST lesson: user-facing auth failures should stay generic, but server/operator diagnostics need enough stable detail to debug expiry, revocation, version mismatch, assurance, and freshness failures.
- **D-26:** OIDC/OAuth/passkey lesson: `auth_time`, `acr`, provider assertions, PKCE posture, and native returns are evidence inputs, not route authority. Backend validation must promote them into `SessionAuthorityLane` before RouteGate trusts them.
- **D-27:** Mature framework lesson from Django, Spring Security, Devise, Guardian, Bodyguard/Ash-style policy seams: keep decision logic small, explicit, reusable, and testable; avoid scattering auth checks across controllers, sockets, shell bridge code, and docs.
- **D-28:** Crosswake prompt-corpus lesson: sensitive routes must not be cached casually, the bridge is not an auth boundary, and mobile debug/operator surfaces should make invisible session/route state inspectable without leaking secrets.

### the agent's Discretion
- Exact module names are planner discretion if Sigra remains clearly namespaced and the evaluator is not a generic policy engine.
- Exact struct names are planner discretion. Strong defaults: keep `AuthContext` and `SessionAuthorityLane`; add `Evaluator` and a typed evaluator denial/result struct if helpful.
- Exact auth posture enum names may be refined, but the semantics must remain explicit, route-local, manifest-visible, and fail-closed.
- Exact denial code names may be refined, but they must stay stable, low-cardinality, docs-contractable, and sourced from one canonical registry.
- Exact migration path for Phase 46 fields is planner discretion. Bias toward backward-compatible helpers and tests rather than breaking the contract abruptly.

### Deferred Ideas (OUT OF SCOPE)
- Session handoff ticket records, atomic redemption, and Phoenix session renewal are deferred to Phase 55.
- Step-up intent lifecycle, Plug/controller redirect flow, LiveView `on_mount` halt/return flow, CSRF/session renewal, and challenge UX are deferred to Phase 56.
- OAuth, passkey, native deep-link, and shell bridge return envelope validation are deferred to Phase 57.
- Full auth telemetry taxonomy, docs-contract closeout, and dedicated security review are deferred to Phase 58 except for Phase 54 denial-code groundwork.
- Provider-specific identity templates, native auth UI, refresh-token rotation helpers, and offline sensitive mutation remain out of scope for v3.8 unless later roadmap work explicitly adds them.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SESS-01 | Backend-owned session authority model with explicit lifecycle and assurance fields | Standard Stack + Architecture Patterns + Security Domain |
| SESS-02 | Fail-closed route gate for missing/expired/revoked/weak/stale authority | Architecture Patterns + Common Pitfalls + Code Examples |
| SESS-03 | Remembered/cached auth blocked unless explicit weaker route posture | Pattern: explicit `auth_posture` + validator cross-checks |
| DIAG-01 | Canonical auth denial taxonomy with safe user messaging and rich sanitized operator detail | Don’t Hand-Roll + Security Domain + Code Examples |
</phase_requirements>

## Summary

Phase 54 should be planned as a contract-and-evaluator phase, not a ceremony phase: enrich Sigra authority structs and validators, add a thin shared auth evaluator seam, and wire RouteGate to call it in fail-closed order. [CITED: .planning/phases/54-sigra-session-authority-contract-and-route-gate-semantics/54-CONTEXT.md]  
Current code already has the right anchors (`AuthContext`, `SessionAuthorityLane`, `RouteGate`, `:step_up_required`, support/doctor/operator surfaces), so planning should bias toward extension and migration-safe refactor rather than replacement. [CITED: lib/crosswake/companions/sigra/contracts.ex] [CITED: lib/crosswake/compatibility/route_gate.ex] [CITED: lib/crosswake/shell/denial.ex]  
Security posture should remain backend-authoritative and generic for end users, with richer but sanitized operator detail keyed by stable subcodes. [CITED: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html] [CITED: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html]

**Primary recommendation:** Implement `Crosswake.Companions.Sigra.Evaluator` as the single policy core and keep `RouteGate` as orchestration only. [ASSUMED]

## Project Constraints (from AGENTS.md)

- Preserve Crosswake as a Phoenix-first route-policy/runtime-contract system, not a universal UI framework. [CITED: AGENTS.md]  
- Keep runtime ownership explicit per route; no generic WebView fallback design drift. [CITED: AGENTS.md]  
- Keep bridge contracts semantic, typed, versioned, and low-frequency. [CITED: AGENTS.md]  
- Keep offline claims honest; distinguish cached read-only from local-first mutation. [CITED: AGENTS.md]  
- Treat diagnostics/support/proof/docs as product surface. [CITED: AGENTS.md]  
- Respect v1 scope boundaries from project/requirements docs. [CITED: AGENTS.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Session authority projection contract | API / Backend | Database / Storage | Authority state and revocation/version truth are backend-owned. [CITED: .planning/REQUIREMENTS.md] |
| Route auth evaluation | API / Backend | Frontend Server (SSR) | Plug/LiveView should consume one backend policy decision. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| Public denial reason and subcode envelope | API / Backend | Browser / Client | Backend emits safe envelope; shell/client only renders/acts. [CITED: lib/crosswake/shell/denial.ex] |
| Route policy posture declaration | Frontend Server (SSR) | API / Backend | Route DSL lives in router policy; evaluator enforces it. [CITED: lib/crosswake/policy/schema.ex] |
| Operator/doctor/support truth | API / Backend | CDN / Static | Generated from backend route/support contracts and published docs. [CITED: lib/crosswake/doctor/publish_readiness.ex] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5 | Contract modules and evaluator logic | Existing project baseline and type/spec/test posture. [CITED: mix.exs] [CITED: command output `elixir --version`] |
| Phoenix | ~> 1.8 | Route policy, Plug integration, host auth boundary | Existing project dependency and auth generator reference patterns. [CITED: mix.exs] [CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html] |
| Phoenix LiveView | ~> 1.1 | Shared auth semantics at LiveView mount/on_mount | Official security model requires dedicated LiveView checks. [CITED: mix.exs] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| Plug | v1.19.x | Session renewal boundary (`configure_session`) | Official API defines renew/drop semantics needed by later phases. [CITED: https://hexdocs.pm/plug/Plug.Conn.html] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| NimbleOptions | ~> 1.1 | Route policy schema validation | Add `auth_posture` and cross-field fail-closed checks. [CITED: mix.exs] [CITED: lib/crosswake/policy/schema.ex] |
| telemetry | ~> 1.0 | Low-cardinality auth evaluation events | Emit evaluator decisions/codes without PII. [CITED: mix.exs] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Sigra-specific evaluator seam | Generic policy engine library | Broader abstraction conflicts with locked scope and increases drift risk. [CITED: .planning/phases/54-sigra-session-authority-contract-and-route-gate-semantics/54-CONTEXT.md] |

## Architecture Patterns

### System Architecture Diagram

```text
Route request (Plug or LiveView mount)
  -> RouteGate.evaluate/4
    -> Companion kill-switch check
      -> companion gate check
        -> Sigra.Evaluator.evaluate_route_auth(route, auth_context, opts)
          -> validate AuthContext + SessionAuthorityLane
          -> evaluate posture + assurance + freshness + expiry + revocation/version
          -> {:allow, facts} OR {:deny, subcode + safe details}
    -> if deny => Shell.Denial(reason=:step_up_required, code=subcode, sanitized details)
    -> if allow => continue to compatibility/commerce findings
    -> final decision (allow/deny + transition)
```

### Recommended Project Structure
```text
lib/crosswake/companions/sigra/
├── contracts.ex        # authority/evidence structs and validators
├── evaluator.ex        # pure auth decision seam (new)
└── denial_codes.ex     # canonical subcode registry (new, optional)
```

### Pattern 1: Thin Pure Evaluator
**What:** Keep auth decision logic pure and reusable across Plug/LiveView entry points. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html]  
**When to use:** Any route has `auth_min_level`, `requires_recent_auth`, or `auth_posture`. [CITED: lib/crosswake/policy/schema.ex]  
**Example:**
```elixir
# Source: .planning/phases/.../54-CONTEXT.md (D-19)
def evaluate_route_auth(route, auth_context, opts) do
  # returns {:allow, facts} | {:deny, %Denial{}}
end
```

### Anti-Patterns to Avoid
- **Auth logic duplicated in RouteGate + future plugs/on_mount:** causes drift in denial behavior and docs parity. [CITED: lib/crosswake/compatibility/route_gate.ex]
- **Using client/provider payload as authority fields:** violates evidence-only boundary. [CITED: lib/crosswake/companions/sigra/contracts.ex]
- **Adding new public shell denial reasons now:** breaks locked `:step_up_required` contract. [CITED: .planning/phases/54-sigra-session-authority-contract-and-route-gate-semantics/54-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Session renewal semantics | Custom session-id rotation rules | `Plug.Conn.configure_session(conn, renew: true)` at host boundary | Official behavior already defined and audited in Plug docs. [CITED: https://hexdocs.pm/plug/Plug.Conn.html] |
| Auth failure UX content | Per-error user-specific messages | Generic user-safe message + stable operator code | Prevents account-state leakage/enumeration. [CITED: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html] |
| Expiry policy vocabulary | Ad hoc timeout names | idle/absolute/renewal timeout model | Standard security vocabulary and threat framing. [CITED: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html] |

## Common Pitfalls

### Pitfall 1: Fail-Open on Invalid AuthContext
**What goes wrong:** invalid/missing context silently bypasses auth checks. [CITED: lib/crosswake/compatibility/route_gate.ex]  
**How to avoid:** treat invalid/missing context as deny with explicit subcode. [CITED: .planning/phases/54-sigra-session-authority-contract-and-route-gate-semantics/54-CONTEXT.md]

### Pitfall 2: Route Posture Not Serialized Into Manifest
**What goes wrong:** declared auth posture is invisible to operator/shell diagnostics. [CITED: lib/crosswake/manifest/types.ex]  
**How to avoid:** add posture to policy schema, route struct, manifest type, support/operator renderers together.

### Pitfall 3: Sensitive Details Leak in Denials
**What goes wrong:** token/provider/passkey identifiers leak to shell/operator output. [CITED: .planning/REQUIREMENTS.md]  
**How to avoid:** allowlist safe keys only and sanitize refs by strict format/length. [CITED: test/crosswake/proof/phase46_sigra_auth_contract_test.exs]

## Code Examples

### Session Rotation Primitive (host boundary, later phase)
```elixir
# Source: https://hexdocs.pm/plug/Plug.Conn.html
configure_session(conn, renew: true)
```

### Current Fail-Closed RouteGate Anchor
```elixir
# Source: lib/crosswake/compatibility/route_gate.ex
auth_predicated? = not is_nil(route.auth_min_level) or not is_nil(route.requires_recent_auth)
```

### Evidence/Authority Fence
```elixir
# Source: lib/crosswake/companions/sigra/contracts.ex
@forbidden_evidence_authority_keys [:authority_state, :mfa_level, :auth_level, :session_authority, :access_granted]
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Contract-only Sigra auth predicates | Full backend session authority projection + evaluator seam | v3.8 Phase 54 target (2026-06-01 planning) | Enables strict freshness/expiry/revocation posture before ceremony work. [CITED: .planning/ROADMAP.md] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A dedicated `denial_codes.ex` module is the cleanest canonical registry location | Architecture Patterns | Low; could live in evaluator/contracts instead |
| A2 | Keeping `RouteGate` as orchestration-only is lowest-risk refactor path | Summary | Medium; may need broader edits if hidden couplings exist |

## Open Questions

1. **Should `auth_posture` live as a plain atom or typed sub-struct in manifest route entries?**
   - What we know: current manifest route entry uses atom fields for auth predicates. [CITED: lib/crosswake/manifest/types.ex]
   - What's unclear: whether future phases need posture metadata extensions (e.g., rationale/source).
   - Recommendation: start with atom to minimize churn in Phase 54, revisit in Phase 56 if ceremony metadata needs expansion. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` | ExUnit proof/test execution | ✓ | 1.19.5 | — |
| `elixir` | Contract/evaluator implementation | ✓ | 1.19.5 | — |
| Erlang/OTP | BEAM runtime | ✓ | 28 | — |

**Missing dependencies with no fallback:** none.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/crosswake/companions/sigra/contracts_test.exs test/crosswake/proof/phase46_sigra_auth_contract_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SESS-01 | Rich backend authority contract validation | unit | `mix test test/crosswake/companions/sigra/contracts_test.exs` | ✅ |
| SESS-02 | Route gate fail-closed denial semantics | integration | `mix test test/crosswake/proof/phase46_sigra_auth_contract_test.exs` | ✅ |
| SESS-03 | Remembered/cached posture denial | unit+integration | `mix test test/crosswake/compatibility/route_gate_test.exs` | ❌ Wave 0 |
| DIAG-01 | Canonical safe denial taxonomy parity | proof/docs | `mix test test/crosswake/proof/phase54_sigra_session_authority_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/crosswake/companions/sigra/contracts_test.exs`
- **Per wave merge:** `mix test test/crosswake/proof/phase46_sigra_auth_contract_test.exs`
- **Phase gate:** `mix test`

### Wave 0 Gaps
- [ ] `test/crosswake/proof/phase54_sigra_session_authority_test.exs` — SESS-01/02/03 + DIAG-01 proof contract
- [ ] `test/crosswake/compatibility/route_gate_test.exs` posture coverage for remembered/cached denials

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | backend-owned `SessionAuthorityLane` with explicit assurance/freshness state |
| V3 Session Management | yes | idle/absolute/renewal session semantics and host-bound session renewal |
| V4 Access Control | yes | route-local fail-closed evaluator in RouteGate |
| V5 Input Validation | yes | typed constructors + `NimbleOptions` route schema |
| V6 Cryptography | yes | use platform/session primitives; no custom token crypto in this phase |

### Known Threat Patterns for Elixir/Phoenix auth gating

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Auth context spoofing from client/native payload | Spoofing | Reject authority keys from evidence lane; backend projection only |
| Stale/remembered auth used on sensitive route | Elevation of privilege | explicit strict posture + recent-auth checks |
| Session replay after revocation/version change | Tampering | include and evaluate revocation/version fields fail-closed |
| Sensitive denial detail leakage | Information disclosure | generic shell message + safe detail allowlist |

## Sources

### Primary (HIGH confidence)
- [54-CONTEXT.md](/Users/jon/projects/crosswake/.planning/phases/54-sigra-session-authority-contract-and-route-gate-semantics/54-CONTEXT.md) - locked decisions and boundaries
- [contracts.ex](/Users/jon/projects/crosswake/lib/crosswake/companions/sigra/contracts.ex) - current Sigra contract/evidence fence
- [route_gate.ex](/Users/jon/projects/crosswake/lib/crosswake/compatibility/route_gate.ex) - current fail-closed ordering and denial behavior
- [mix.exs](/Users/jon/projects/crosswake/mix.exs) - stack and versions
- https://hexdocs.pm/plug/Plug.Conn.html - session renew semantics
- https://hexdocs.pm/phoenix_live_view/security-model.html - LiveView-specific security checks and `on_mount`
- https://hexdocs.pm/phoenix/mix_phx_gen_auth.html - Phoenix auth baseline (`require_sudo_mode`)
- https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html - generic error and re-auth posture
- https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html - idle/absolute/renewal timeout model

### Secondary (MEDIUM confidence)
- [phase46_sigra_auth_contract_test.exs](/Users/jon/projects/crosswake/test/crosswake/proof/phase46_sigra_auth_contract_test.exs) - existing proof shape and sanitization expectations

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - directly from `mix.exs` + installed runtime checks + official docs
- Architecture: HIGH - locked in phase context + existing code anchors
- Pitfalls: HIGH - directly observed in current route/auth code + OWASP guidance

**Research date:** 2026-06-01  
**Valid until:** 2026-07-01
