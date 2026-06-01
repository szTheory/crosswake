# Phase 54: Sigra Session Authority Contract And Route-Gate Semantics - Context

**Gathered:** 2026-06-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Expand the v3.5 Sigra contract-only auth lane into a full backend-owned session authority projection and fail-closed route-auth evaluator.

**Delivers:**
- Richer `SessionAuthorityLane` and `AuthContext` contracts with explicit authority state, assurance level, auth methods, freshness, idle expiry, absolute expiry, renewal horizon, remembered-session posture, and revocation/version fields.
- Route-gate semantics that deny missing, invalid, non-active, expired, revoked/version-mismatched, weak-assurance, stale, remembered, or cached authority before sensitive route activation.
- A canonical auth denial code taxonomy and shell-safe detail allowlist while preserving the public `:step_up_required` shell denial reason.
- A thin, transport-agnostic Sigra route-auth evaluator seam that Plug/controller and LiveView ceremony work can reuse later without implementing Phase 56 step-up ceremony in Phase 54.

**Satisfies:** SESS-01, SESS-02, SESS-03, DIAG-01.

**In scope:**
- Pure contract structs, closed vocabularies, constructors, validators, and comparison helpers.
- Backend-authoritative session projection and evidence-vs-authority fences.
- Route policy/manifest additions needed for explicit auth posture.
- RouteGate and shared evaluator fail-closed semantics.
- Denial code/detail sanitization, doctor/support/operator truth updates, docs-contract parity, and hermetic proof.

**Out of scope:**
- Session handoff ticket issuance/redemption. That belongs to Phase 55.
- Full step-up intent lifecycle, challenge UX, Plug redirects, LiveView `on_mount` returns, Phoenix session renewal, or CSRF renewal. Those belong to Phase 56.
- OAuth/passkey/native return envelope validation. That belongs to Phase 57.
- Provider-specific identity templates, native auth UI framework, refresh-token orchestration, or device/client auth authority.

</domain>

<decisions>
## Implementation Decisions

### 1. Session Authority Shape - LOCKED
- **D-01:** Use a hybrid backend-projection model: `SessionAuthorityLane` is the authoritative backend projection consumed by route gates, while handoff tickets, step-up intents, OAuth returns, passkey assertions, and native events remain bounded evidence/envelopes until a backend flow promotes them. Do not make token claims, bridge payloads, provider returns, or cached client state route authority.
- **D-02:** Evolve `SessionAuthorityLane` from the Phase 46 minimal shape into an explicit lifecycle contract. Required fields should cover: `session_id` or opaque reference, `subject_id`/actor reference, `org_id`, `state`, `assurance_level`, `authn_methods`, `authenticated_at`, `last_seen_at`, `idle_expires_at`, `absolute_expires_at`, `renew_after` or renewal horizon, remembered-session posture, `session_version`, `revoked_at`, and `as_of`.
- **D-03:** Keep vocabularies closed and comparable. Recommended authority states: `:active`, `:step_up_required`, `:expired`, `:revoked`, `:suspended`. Recommended assurance levels preserve Phase 46 ordering: `:none`, `:password`, `:mfa`, `:phishing_resistant`.
- **D-04:** `AuthContext` should remain the route-evaluation input wrapper, but it should derive freshness and assurance from the backend-owned `SessionAuthorityLane` rather than duplicating authority in loosely related fields. Backward-compatible aliases from Phase 46 (`mfa_level`, `auth_age`) may remain temporarily if tests prove they map into the new lane without ambiguity.
- **D-05:** Validators must reject evidence or client-provided attrs that try to set authority fields (`state`, `assurance_level`, `mfa_level`, `authn_methods`, `authenticated_at`, expiry fields, `session_version`, revocation fields, access grants). Follow the Rindle and Phase 46 authority-fence pattern.
- **D-06:** Use `DateTime` or ISO8601-normalized timestamps at the contract boundary, but route evaluation should compare normalized seconds/timestamps through helper functions so manifest JSON and tests remain deterministic.

### 2. Route-Gate Failure Semantics And Denial Taxonomy - LOCKED
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

### 3. Remembered And Cached Auth Posture - LOCKED
- **D-13:** Introduce an explicit route-local auth posture enum instead of split booleans. Recommended values:
  - `:strict_recent` - default for sensitive routes and routes with `requires_recent_auth`; remembered/cached authority cannot satisfy the route.
  - `:remembered_ok` - remembered backend authority may satisfy route access only when assurance and expiry checks pass and no recent-auth predicate is present.
  - `:cached_read_only_ok` - cached authority may satisfy read-only/degraded access only when the route is explicitly read-only/degraded and no sensitive mutation or recent-auth predicate is present.
- **D-14:** Default posture should be strict and resolved visibly. Sensitive routes and routes with `requires_recent_auth` resolve to `:strict_recent` unless a future, explicit, auditable exception exists. Do not infer weaker posture from remembered cookies, mobile cache presence, or native session continuity.
- **D-15:** Keep weakening explicit at the route policy layer and serialized into manifest/operator truth. Example:
  ```elixir
  live "/billing/settings", BillingLive,
    crosswake: [
      id: "billing-settings",
      auth_min_level: :mfa,
      requires_recent_auth: 300,
      auth_posture: :strict_recent
    ]

  live "/inbox", InboxLive,
    crosswake: [
      id: "inbox",
      auth_min_level: :password,
      auth_posture: :remembered_ok
    ]
  ```
- **D-16:** `:cached_read_only_ok` requires cross-field validation against route offline/runtime/security metadata so mutation-capable, sensitive, billing, admin, auth, commerce purchase/restore, and native authority-promotion routes cannot accidentally use cached auth. If the validator cannot prove read-only/degraded posture, fail closed.
- **D-17:** Remembered and cached auth failures should deny with `:step_up_required` plus code (`auth.step_up.remembered_not_allowed` or `auth.step_up.cached_not_allowed`), not silently downgrade to compatibility or cache fallback.

### 4. Evaluator Boundary - LOCKED
- **D-18:** Add a thin reusable Sigra route-auth evaluator seam in Phase 54, but do not implement step-up ceremony. The seam should be transport-agnostic and pure enough for hermetic tests.
- **D-19:** `RouteGate.evaluate/4` remains the canonical route activation decision, but it should call the shared evaluator rather than embedding all Sigra checks directly. Recommended shape:
  ```elixir
  Crosswake.Companions.Sigra.Evaluator.evaluate_route_auth(route, auth_context, opts)
  #=> {:allow, facts}
  #=> {:deny, %Crosswake.Companions.Sigra.Evaluator.Denial{}}
  ```
- **D-20:** The evaluator result should carry normalized denial code, safe details, and low-cardinality facts. It must not know how to issue step-up intents, redirect controllers, halt LiveView mounts, renew Phoenix sessions, or rotate CSRF tokens. Those are Phase 56 responsibilities.
- **D-21:** Design the evaluator so Phase 56 Plug/controller and LiveView `on_mount` wrappers can share one decision core. This follows idiomatic Phoenix separation: pure policy/evaluator logic first, transport adapters second.
- **D-22:** Avoid a generic policy engine abstraction. This seam is Sigra-specific and route-auth-specific; broad authorization libraries are useful prior art but Crosswake should keep the contract narrow and product-shaped.

### 5. Ecosystem Lessons To Preserve - LOCKED
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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/PROJECT.md` — Crosswake thesis, v3.8 milestone goal, constraints, current decisions, and non-goals.
- `.planning/REQUIREMENTS.md` — SESS-01/02/03 and DIAG-01 requirements for Phase 54.
- `.planning/ROADMAP.md` — Phase 54 goal and success criteria; Phases 55-58 boundaries to avoid ceremony/return/proof scope creep.
- `.planning/STATE.md` — current workflow position and deferred items.

### Prior Sigra and companion decisions
- `.planning/milestones/v3.5-phases/46-sigra-auth-contract-only-slice/46-CONTEXT.md` — Phase 46 locked contract-only Sigra shape, route predicates, denial ordering, and docs/proof posture.
- `.planning/milestones/v3.5-phases/47-companion-arc-guide-and-milestone-proof/47-CONTEXT.md` — companion guide/proof parity, Sigra contract-only non-claims, and support-truth anchors.
- `.planning/milestones/v3.5-REQUIREMENTS.md` — original AUTH-01/AUTH-02 contract-only scope and deferred full Sigra machinery.
- `.planning/milestones/v3.5-ROADMAP.md` — Phase 46/47 historical goals and sequencing.

### Prompt corpus and project research
- `prompts/crosswake-brand-book.md` — boundary-aware route/runtime language and support-claim guardrails.
- `prompts/crosswake-research-synthesis.md` — canonical architecture thesis: explicit runtime boundaries, route policy, bounded bridge, honest offline.
- `prompts/crosswake-integrations-and-companions.md` — Sigra companion classification and integration heuristics.
- `prompts/crosswake-elixir-oss-dna.md` — maintainer house style: install truth, support matrices, proof lanes, narrow public APIs, optional-dependency honesty.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` — sensitive route/cache/auth footguns and enterprise SSO/mobile auth lessons.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` — Phoenix-native auth/session defaults, bridge security, sensitive route flags, and DX/operator inspection lessons.
- `prompts/elixir-mobile-oss-lib-deep-research.md` — route-policy/bridge/security proof posture and ecosystem anti-patterns.

### Existing Crosswake code
- `lib/crosswake/companions/sigra/contracts.ex` — current `AuthContext`, `SessionAuthorityLane`, `StepUpChallenge`, validation, and authority-fence implementation.
- `lib/crosswake/compatibility/route_gate.ex` — current fail-closed route activation pipeline and `:step_up_required` denial integration.
- `lib/crosswake/policy/schema.ex` — route-policy validation for `auth_min_level` and `requires_recent_auth`; likely target for `auth_posture`.
- `lib/crosswake/policy/route.ex` — normalized route struct; likely target for `auth_posture`.
- `lib/crosswake/manifest/types.ex` — route entry and JSON serialization targets for new posture/authority fields.
- `lib/crosswake/shell/denial.ex` — canonical public shell denial vocabulary.
- `lib/crosswake/doctor/doctor.ex` — auth route and contract findings.
- `lib/crosswake/doctor/publish_readiness.ex` — Sigra readiness/operator checks currently labeled contract-only.
- `lib/crosswake/operator_inspection.ex` and `lib/crosswake/operator_inspection/types.ex` — operator truth surfaces to distinguish full Sigra machinery from contract-only posture.
- `lib/crosswake/support_matrix/support_matrix.ex` — `auth_contract_truth/0`, promotion rules, support posture, and docs-contract source of truth.

### Existing docs and proof
- `guides/companions.md` — current Sigra contract-only guide and non-claims.
- `guides/support_matrix.md` — support truth and promotion rules for `auth.sigra.contract_only`.
- `guides/native_shell.md` — support-claim language around Sigra and shell/runtime truth.
- `guides/compatibility.md` — runtime compatibility and non-claim language.
- `test/crosswake/proof/phase46_sigra_auth_contract_test.exs` — current Sigra contract/RouteGate/doctor/support proof.
- `test/crosswake/proof/phase47_companion_arc_test.exs` — aggregate companion/Sigra proof posture.
- `test/crosswake/guides/companions_test.exs` — docs-contract parity target for Sigra guide claims.
- `test/crosswake/support_matrix/support_matrix_test.exs` and `test/crosswake/support_matrix/renderer_test.exs` — support truth parity targets.
- `test/crosswake/operator_inspection/operator_inspection_test.exs` and `test/crosswake/operator_inspection/json_formatter_test.exs` — operator surface parity targets.

### External ecosystem references considered during discussion
- `https://hexdocs.pm/plug/Plug.Conn.html` — `configure_session/2`, session renewal/drop semantics.
- `https://hexdocs.pm/plug/Plug.Session.html` — Plug session storage and request-scoped session handling.
- `https://hexdocs.pm/phoenix/mix_phx_gen_auth.html` — Phoenix-generated auth posture, remember-me/sensitive-action patterns, and server-side auth defaults.
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html` — `on_mount`/halt behavior and LiveView transport integration.
- `https://hexdocs.pm/phoenix_live_view/security-model.html` — LiveView security model and need to authorize in both HTTP and LiveView paths.
- `https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html` — reauthentication, generic error handling, and auth failure posture.
- `https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html` — idle/absolute timeout, renewal, and session lifecycle recommendations.
- `https://cheatsheetseries.owasp.org/cheatsheets/Error_Handling_Cheat_Sheet.html` — generic user-facing errors and richer server-side diagnostics.
- `https://openid.net/specs/openid-connect-core-1_0-18.html` — `auth_time`/`acr` as evidence concepts, not backend authority by themselves.
- `https://www.rfc-editor.org/rfc/rfc8252` — native OAuth external-user-agent lesson; avoid embedded WebView authority.
- `https://www.rfc-editor.org/rfc/rfc9700` — OAuth 2.0 security best-current-practice lessons around bearer/token risks.
- `https://hexdocs.pm/guardian/Guardian.html` and `https://hexdocs.pm/guardian_db/Guardian.DB.html` — Elixir token/revocation lessons and why storage-backed revocation matters for sensitive sessions.
- `https://docs.djangoproject.com/en/4.2/topics/http/sessions/`, `https://docs.spring.io/spring-security/reference/6.5-SNAPSHOT/servlet/authentication/session-management.html`, and `https://github.com/heartcombo/devise` — mature framework lessons around server-side sessions, session invalidation, and rememberable/freshness footguns.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Companions.Sigra.Contracts` already provides the right namespace, typed struct/constructor/validator style, closed assurance vocabulary, and evidence-authority rejection pattern.
- `Crosswake.Compatibility.RouteGate` already has the correct denial ordering skeleton: companion kill switch and gate checks short-circuit before auth, then compatibility/commerce findings.
- `Crosswake.Shell.Denial` already exposes `:step_up_required` as a stable shell reason; Phase 54 should enrich codes/details without widening this public reason list.
- `Crosswake.SupportMatrix.auth_contract_truth/0` already provides the canonical support truth row that Phase 54 can evolve from contract-only to full session-authority posture.
- `Crosswake.Doctor` and `Crosswake.Doctor.PublishReadiness` already emit auth predicate readiness findings that can be upgraded from contract-only wording.
- Phase 46/47 proof tests already lock the critical anchors: `AuthContext`, `SessionAuthorityLane`, route predicates, `:step_up_required`, doctor findings, support truth, and docs parity.

### Established Patterns
- Crosswake contract modules use plain structs, closed vocabularies, `new_*` constructors, `validate_*` functions, and hermetic tests rather than Ecto schemas for core runtime contracts.
- Support claims are backed by exported support-matrix accessors, doctor checks, operator inspection, guide text, and docs-contract tests.
- Provider/device/native proof stays advisory until promotion criteria pass. Phase 54 should keep all auth provider/native-return evidence non-authoritative until backend projection occurs.
- Shell-facing denial details are intentionally small and sanitized; richer debugging belongs in doctor/operator/telemetry surfaces.
- Route policy is the product surface. Any weakening of auth posture must be route-local, explicit, serialized, and inspectable.

### Integration Points
- Add or evolve Sigra structs and validators in `lib/crosswake/companions/sigra/contracts.ex`.
- Add the pure evaluator seam under the Sigra namespace, likely `lib/crosswake/companions/sigra/evaluator.ex`.
- Update `RouteGate` to delegate auth checks to the evaluator while preserving denial ordering.
- Add `auth_posture` validation and manifest serialization through policy schema, route structs, manifest types, shell fixture manifests, and docs/tests.
- Update doctor/support/operator truth from "contract-only" to "full session authority contract" without claiming handoff, ceremony, OAuth/passkey, or provider/device proof.

</code_context>

<specifics>
## Specific Ideas

- Recommended coherent architecture: backend projection as authority; one public shell reason with stable auth subcodes; explicit route auth posture enum; thin reusable evaluator seam; no Phase 56 ceremony or Phase 57 return validation in Phase 54.
- Recommended example state:
  ```elixir
  %SessionAuthorityLane{
    state: :active,
    assurance_level: :mfa,
    authn_methods: [:password, :totp],
    authenticated_at: ~U[2026-06-01 20:00:00Z],
    last_seen_at: ~U[2026-06-01 20:10:00Z],
    idle_expires_at: ~U[2026-06-01 20:40:00Z],
    absolute_expires_at: ~U[2026-06-02 08:00:00Z],
    renew_after: ~U[2026-06-01 20:30:00Z],
    remembered: false,
    cached: false,
    session_version: 42,
    revoked_at: nil,
    as_of: ~U[2026-06-01 20:10:00Z]
  }
  ```
- Strong DX goal: host developers should be able to inspect one route and know why it allowed or denied: required level, posture, freshness, state, and stable code, without reading provider-specific auth docs.
- Security UX goal: users see safe "step-up required/auth expired" style handling; operators see stable denial codes and sanitized facts.

</specifics>

<deferred>
## Deferred Ideas

- Session handoff ticket records, atomic redemption, and Phoenix session renewal are deferred to Phase 55.
- Step-up intent lifecycle, Plug/controller redirect flow, LiveView `on_mount` halt/return flow, CSRF/session renewal, and challenge UX are deferred to Phase 56.
- OAuth, passkey, native deep-link, and shell bridge return envelope validation are deferred to Phase 57.
- Full auth telemetry taxonomy, docs-contract closeout, and dedicated security review are deferred to Phase 58 except for Phase 54 denial-code groundwork.
- Provider-specific identity templates, native auth UI, refresh-token rotation helpers, and offline sensitive mutation remain out of scope for v3.8 unless later roadmap work explicitly adds them.

</deferred>

---

*Phase: 54-Sigra Session Authority Contract And Route-Gate Semantics*
*Context gathered: 2026-06-01*
