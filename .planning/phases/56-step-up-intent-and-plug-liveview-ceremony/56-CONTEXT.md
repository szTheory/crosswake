# Phase 56: Step-Up Intent And Plug/LiveView Ceremony - Context

**Gathered:** 2026-06-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Provide a server-owned Sigra step-up intent and one shared challenge/return ceremony for routes requiring stronger or fresher backend authentication.

**Delivers:**
- A typed `StepUpIntent` contract with bounded lifecycle, required assurance/freshness, source/return route binding, expiry, cancellation/consumption state, and audit correlation.
- A shared Sigra ceremony core that turns the existing route-auth evaluator result into `:allow`, `:challenge`, or `:deny` outcomes for both Plug/controller and LiveView entry points.
- Thin Plug/controller and LiveView `on_mount` adapters that use the same ceremony semantics while handling transport-specific redirect/halt mechanics.
- Successful step-up return semantics that consume the intent, refresh backend `SessionAuthorityLane`, return host-owned session/CSRF renewal instructions, and navigate only to a manifest-known Crosswake route.
- Safe intent denial/fallback behavior for invalid, expired, canceled, consumed/replayed, route-mismatched, and projection-failed step-up attempts.

**Satisfies:** STEP-01, STEP-02, STEP-03.

**In scope:**
- Pure Sigra step-up structs, validators, lifecycle vocabularies, denial-code expansion, and safe detail allowlist additions.
- Example-host Ecto-backed step-up intent storage, issue/challenge/consume/cancel/audit flow, and hermetic proof.
- Shared ceremony core plus Plug and LiveView adapters that call the same decision path.
- Route-id return target validation against the compiled Crosswake manifest.
- Host-owned session renewal and CSRF rotation instructions after backend validation succeeds.

**Out of scope:**
- OAuth, passkey, native deep-link, shell bridge return envelope validation, provider templates, or native auth UI. Those belong to Phase 57 or later.
- Stable full auth telemetry taxonomy, metrics cardinality policy, audit export adapters, and final security closeout. Those belong to Phase 58.
- Refresh-token rotation helpers, direct shell/WebView token authority, generic auth UI framework behavior, and high-frequency bridge auth state streaming.

</domain>

<decisions>
## Implementation Decisions

### 1. Step-Up Intent Lifecycle And Authority Shape - LOCKED
- **D-01:** Add a Sigra-scoped `StepUpIntent` contract separate from Phase 55 `HandoffTicket`. Reuse the Phase 55 hybrid pattern, not the same record: an opaque/signed client locator plus an authoritative server-side intent record.
- **D-02:** The client-presented locator is only a bounded locator/correlation artifact. It may carry `typ`, `intent_ref`, version, issuer/audience, issued/expires timestamps, route id, challenge kind, and low-sensitivity digests. It must not carry identity, session, credential, provider, CSRF, nonce, PKCE, or authority-setting claims.
- **D-03:** The server-side intent record is the source of truth for replay, cancellation, expiry, route binding, required assurance/freshness, audit, and backend authority projection. Do not let signed token claims become route authority.
- **D-04:** Lifecycle states should be closed and boring: `:issued`, `:challenged`, `:consumed`, `:expired`, `:canceled`, `:revoked`. Expiry must be enforced from `expires_at` even before cleanup marks a row `:expired`.
- **D-05:** Required record fields should include `intent_ref`, locator/token digest, lifecycle `state`, `subject_ref`, `org_id`, `source_session_ref`, `expected_session_version`, optional device ref, source route id, return route id, required assurance level, required auth posture, max auth age, challenge kind, issued/expires/consumed/canceled/revoked timestamps, cancellation/revocation reason, audit correlation ref, and projection inputs for the refreshed `SessionAuthorityLane`.
- **D-06:** Store step-up intent rows in the host/example app with Ecto-backed persistence. Core Crosswake owns pure contracts, validation, denial codes, safe details, and proof fixtures; the Phoenix host owns Repo, schemas, account/session lookup, and transaction execution.
- **D-07:** Consumption must be atomic and one-time, using an Ecto.Multi-style transaction that conditionally consumes only issued, unconsumed, uncanceled, unrevoked, unexpired intents before audit/projection. Avoid check-then-update races.
- **D-08:** Reject session-only `return_to` state and self-contained signed step-up tokens as authority. Session state may hold transient UI hints after a server intent exists, but it is not the lifecycle source of truth.

### 2. Shared Plug/LiveView Ceremony - LOCKED
- **D-09:** Keep `Crosswake.Companions.Sigra.Evaluator` pure and transport-agnostic. It decides route auth. It must not issue intents, redirect controllers, halt LiveViews, renew sessions, or rotate CSRF tokens.
- **D-10:** Add a Sigra-scoped ceremony core, not a generic policy engine. Recommended shape:
  ```elixir
  Crosswake.Companions.Sigra.StepUp.evaluate_or_issue(route, auth_context, opts)
  #=> {:allow, facts}
  #=> {:challenge, %StepUpIntent{}, %StepUpChallenge{}}
  #=> {:deny, %Crosswake.Shell.Denial{}}
  ```
- **D-11:** Plug/controller and LiveView `on_mount` adapters should be thin transport adapters over the same ceremony core. Plug handles `redirect(conn, ...) |> halt()`. LiveView handles `redirect(socket, ...)` and returns `{:halt, socket}`.
- **D-12:** Do not duplicate assurance/freshness/session-version logic in separate Plug and LiveView paths. The LiveView security model requires both HTTP and LiveView entry points to validate auth, but they should share one decision core.
- **D-13:** Do not create a broad middleware/policy framework. Bodyguard/Ash/Spring-style policy systems are useful prior art for shared decision cores, but Crosswake should stay route-policy and Sigra ceremony focused.
- **D-14:** `RouteGate.evaluate/4` remains the route activation decision surface. Step-up ceremony may use its denial/evaluator output as input, but `RouteGate` itself should not become a challenge issuer or session mutator.
- **D-15:** Public shell denial reason remains `:step_up_required`. Add stable intent-specific subcodes under a narrow namespace such as `auth.step_up_intent.*`; do not add a new broad shell reason like `:step_up_intent_denied`.

### 3. Return Target, Session Renewal, And CSRF Posture - LOCKED
- **D-16:** Return targets must be manifest-known Crosswake route IDs, optionally with typed allowlisted params. Never store or trust arbitrary raw `return_to` URLs as intent authority.
- **D-17:** Hosts may map a web-style `return_to` path into a manifest route id before intent creation, but the stored contract should be `return_route_id` plus typed params. If the target cannot be resolved against the compiled manifest, deny fail-closed.
- **D-18:** Signed redirect/return tokens are acceptable only as locators for server-side step-up intent rows. They are not redirect authority and do not replace route-id validation.
- **D-19:** Successful step-up must consume the intent before session renewal, project or refresh a backend-owned `SessionAuthorityLane`, and then re-run or prove route authority for the return route using `RouteGate.evaluate/4`.
- **D-20:** Crosswake should return typed host-owned renewal instructions instead of mutating `Plug.Conn`. Recommended extension to the existing Phase 55 `SessionRenewalInstructions` shape:
  ```elixir
  %SessionRenewalInstructions{
    renew_session?: true,
    rotate_csrf?: true,
    put_session: %{"crosswake_session_ref" => "..."},
    delete_session: ["step_up_intent_ref"],
    projected_session_ref: "...",
    projected_session_version: 44,
    live_socket_invalidation: %{reason: :step_up_completed}
  }
  ```
- **D-21:** The host applies `configure_session(conn, renew: true)`, rotates/deletes CSRF posture as appropriate, copies only explicit `put_session` keys, deletes transient step-up keys, and redirects to the validated route target.
- **D-22:** LiveView step-up completion should force remount/re-evaluation or equivalent socket invalidation. Do not leave stale LiveView socket state after a privilege/freshness change.
- **D-23:** Raw tokens, intent refs, session refs, actor/org/device identifiers, provider payloads, passkey credential IDs, nonces, PKCE material, CSRF tokens, IPs, and user agents must not appear in shell-safe denial details.

### 4. Denial Codes, Audit, And Support Truth - LOCKED
- **D-24:** Add canonical intent denial codes for at least missing, invalid, expired, consumed/replayed, canceled, revoked, route mismatch, binding mismatch, challenge failed, and projection failed cases. Keep codes low-cardinality and docs-contractable.
- **D-25:** Safe details should be allowlisted and support-oriented, such as `step_up_intent_ref` only when it is a generated support ref, `intent_state`, `challenge_kind`, `required_assurance_level`, `max_auth_age_seconds`, `auth_posture`, `route_binding`, `intent_expires_at`, `intent_age_seconds`, and `evaluated_at`.
- **D-26:** Add a typed step-up audit event contract for `:issue`, `:challenge`, `:consume`, `:cancel`, `:expire`, `:revoke`, and `:deny` outcomes. Mandatory facts should include event id, event type, safe intent/support ref, state before/after, outcome, denial code, route id, challenge kind, source/projected session refs, session versions, assurance after, auth methods after, binding result, request ref, actor kind, and occurred_at.
- **D-27:** Doctor, support matrix, operator inspection, guides, docs-contract tests, and proof fixtures should promote Phase 56 ceremony truth while continuing to state that OAuth/passkey/native return validation, refresh-token helpers, provider/device proof, and native auth UI remain deferred.

### 5. Ecosystem Lessons To Preserve - LOCKED
- **D-28:** Phoenix/Plug lesson: session and CSRF mutation belong at the host boundary after backend validation succeeds. Crosswake should expose instructions and examples, not mutate the host connection in core.
- **D-29:** Phoenix LiveView lesson: controller plugs and LiveView `on_mount` need shared auth semantics but different transport behavior. Halting after LiveView redirects is required.
- **D-30:** Ecto lesson: intent consume + audit + projection should be one transaction. `Ecto.Multi` is the idiomatic host example shape.
- **D-31:** OWASP/NIST/mature-framework lesson: step-up and privilege/freshness changes require server-side lifecycle truth, generic user-facing failures, session id renewal, replay/cancel/expiry handling, and audit. Django/Devise-style raw redirect parameters are familiar but become footguns without strict allowlists; Crosswake has a stronger primitive in manifest route ids.
- **D-32:** Guardian.DB/Spring/Django lesson: signed/session/token artifacts are useful, but revocation, replay, and session-fixation safety require server-side state for sensitive auth flows.
- **D-33:** Crosswake prompt-corpus lesson: the bridge is not an auth boundary, route ownership must stay explicit, bridge messages stay semantic/low-frequency, and support claims must distinguish shipped ceremony contracts from provider/device/native auth UI claims.

### the agent's Discretion
- Exact module names are planner discretion if they remain clearly Sigra-scoped. Strong defaults: `Crosswake.Companions.Sigra.StepUp`, `StepUpIntent`, `StepUpIntentEnvelope`, `StepUpCeremony`, and transport adapters under Sigra-specific Plug/LiveView namespaces.
- Exact Ecto schema/module names in the example host are planner discretion. Core contracts should remain pure Elixir; example-host persistence can use Ecto.
- Exact TTL defaults are planner discretion. Bias toward minutes, not hours, and document step-up intents as short-lived single-use artifacts.
- Exact subcode names may be refined, but they must preserve `:step_up_required` as public shell reason and stay stable, low-cardinality, and sourced from one registry.
- Exact challenge UI is planner discretion. Keep it host-owned and boring: the example can prove a password/MFA-style confirmation without claiming provider-specific OAuth/passkey/native auth support.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/PROJECT.md` - Crosswake thesis, v3.8 milestone goal, constraints, current decisions, and non-goals.
- `.planning/REQUIREMENTS.md` - STEP-01/02/03 requirements for Phase 56 and adjacent Phase 57/58 boundaries.
- `.planning/ROADMAP.md` - Phase 56 goal and success criteria; adjacent phase boundaries.
- `.planning/STATE.md` - current workflow position, known caveats, and recent Phase 54/55 decisions.

### Prior Sigra decisions
- `.planning/phases/54-sigra-session-authority-contract-and-route-gate-semantics/54-CONTEXT.md` - locked backend authority, `SessionAuthorityLane`, evaluator boundary, `auth_posture`, denial code/detail sanitization, and deferred ceremony scope.
- `.planning/phases/55-session-handoff-tickets-and-authority-projection/55-CONTEXT.md` - locked hybrid envelope/server-record pattern, host-owned renewal instructions, route-target validation, and handoff non-claims.
- `.planning/milestones/v3.5-phases/46-sigra-auth-contract-only-slice/46-CONTEXT.md` - original Sigra contract-only scope and route-auth denial posture.

### Prompt corpus and project research
- `prompts/crosswake-brand-book.md` - boundary-aware route/runtime language and support-claim guardrails.
- `prompts/crosswake-research-synthesis.md` - canonical architecture thesis: explicit runtime boundaries, route policy, bounded bridge, honest offline.
- `prompts/crosswake-integrations-and-companions.md` - Sigra companion classification and integration heuristics.
- `prompts/crosswake-elixir-oss-dna.md` - maintainer house style: install truth, support matrices, proof lanes, narrow public APIs, optional-dependency honesty.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` - sensitive route/cache/auth footguns and bridge-security lessons.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` - Phoenix-native session defaults, bridge security, route manifest, sensitive route flags, and DX/operator inspection lessons.
- `prompts/elixir-mobile-oss-lib-deep-research.md` - route-policy/bridge/security proof posture and ecosystem anti-patterns.
- `prompts/crosswake-gsd-project-brief.md` - project brief and companion queue context.

### Existing Crosswake code
- `lib/crosswake/companions/sigra/contracts.ex` - current `AuthContext`, `SessionAuthorityLane`, `StepUpChallenge`, validation, and authority-fence implementation.
- `lib/crosswake/companions/sigra/evaluator.ex` - pure route-auth evaluator that Phase 56 should reuse without turning it into transport ceremony.
- `lib/crosswake/companions/sigra/handoff.ex` - Phase 55 hybrid locator/server-record and renewal-instruction pattern to mirror for step-up.
- `lib/crosswake/companions/sigra/denial_codes.ex` - canonical auth denial subcodes and shell-safe detail sanitizer to extend.
- `lib/crosswake/compatibility/route_gate.ex` - route activation pipeline and `:step_up_required` shell denial integration.
- `lib/crosswake/shell/denial.ex` - public shell denial vocabulary; do not add a broad step-up-intent shell reason.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/handoff.ex` - Ecto-backed issue/redeem/revoke proof path, manifest route validation, and no raw `return_to` pattern.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex` - host-owned session application using `configure_session(conn, renew: true)`.
- `examples/phoenix_host/lib/crosswake_example/selective_native/on_mount.ex` - existing LiveView hook analog for host-owned mount behavior.
- `lib/crosswake/doctor/doctor.ex`, `lib/crosswake/doctor/publish_readiness.ex`, `lib/crosswake/operator_inspection.ex`, `lib/crosswake/operator_inspection/types.ex`, and `lib/crosswake/support_matrix/support_matrix.ex` - operator/support truth surfaces to update.

### Existing docs and proof
- `guides/companions.md` - current Sigra guide and non-claims that Phase 56 should update.
- `guides/support_matrix.md` - support truth and promotion/non-claim language for Sigra.
- `guides/native_shell.md` - shell/runtime support-claim language; ceremony must not imply shell auth authority.
- `test/crosswake/proof/phase54_sigra_session_authority_test.exs` - current Sigra route-authority proof anchors.
- `test/crosswake/proof/phase55_session_handoff_tickets_test.exs` - handoff lifecycle, renewal instruction, and support-truth proof analog.
- `test/crosswake/companions/sigra/contracts_test.exs` - contract constructor/validator analogs.
- `test/crosswake/compatibility/route_gate_test.exs` - route gate auth denial ordering and code proof.
- `test/crosswake/guides/companions_test.exs`, `test/crosswake/support_matrix/support_matrix_test.exs`, `test/crosswake/support_matrix/renderer_test.exs`, `test/crosswake/operator_inspection/operator_inspection_test.exs`, `test/crosswake/operator_inspection/json_formatter_test.exs`, `test/crosswake/doctor/doctor_test.exs`, and `test/crosswake/doctor/publish_readiness_test.exs` - docs/support/operator/doctor parity targets.

### External ecosystem references considered during discussion
- `https://plug.hexdocs.pm/Plug.Conn.html#configure_session/2` - Phoenix/Plug session renewal and drop semantics.
- `https://hexdocs.pm/phoenix/Phoenix.Controller.html` - redirect and CSRF helper behavior for host-owned return handling.
- `https://phoenix-live-view.hexdocs.pm/security-model.html` - LiveView security model and need for HTTP + LiveView validation.
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#on_mount/1` - idiomatic LiveView `on_mount` hook and halt/redirect shape.
- `https://phoenix.hexdocs.pm/mix_phx_gen_auth.html` - Phoenix-generated auth posture and sudo-mode/sensitive-action precedent.
- `https://hexdocs.pm/ecto/Ecto.Multi.html` - idiomatic consume + audit + projection transaction composition.
- `https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html` - session id renewal after privilege changes, timeout, and server-side lifecycle guidance.
- `https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html` - reauthentication, generic failures, and sensitive-action posture.
- `https://pages.nist.gov/800-63-4/sp800-63b.html` - authenticator/session lifecycle, replay, and reauthentication considerations.
- `https://hexdocs.pm/guardian_db/Guardian.DB.html` - Elixir server-side token tracking/revocation lessons.
- `https://docs.djangoproject.com/en/4.2/topics/http/sessions/` - mature framework session lifecycle and signed-cookie caveats.
- `https://docs.spring.io/spring-security/reference/6.5-SNAPSHOT/servlet/authentication/session-management.html` - session fixation and session registry lessons.
- `https://github.com/heartcombo/devise` - mature Rails auth lessons around redirect hooks, filter ordering, and CSRF/session footguns.
- `https://hexdocs.pm/bodyguard/Bodyguard.Plug.Authorize.html` and `https://hexdocs.pm/ash/policies.html` - shared policy-core prior art; useful lesson but too broad for Phase 56 core.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Companions.Sigra.Contracts` already provides pure struct/constructor/validator style, closed vocabularies, `StepUpChallenge`, and authority-fence helpers.
- `Crosswake.Companions.Sigra.Evaluator` already produces fail-closed route-auth denials under `:step_up_required`; Phase 56 should reuse it as the decision input.
- `Crosswake.Companions.Sigra.Handoff` already proves the hybrid locator/server-record pattern, `SessionRenewalInstructions`, audit event shape, and no-self-contained-authority posture.
- `Crosswake.Companions.Sigra.DenialCodes` is the canonical registry/sanitizer to extend with intent-specific subcodes and safe details.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/handoff.ex` provides the closest implementation analog for Ecto.Multi issue/redeem/revoke/audit and manifest route validation.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex` already applies renewal instructions with `configure_session(conn, renew: true)`.

### Established Patterns
- Core Crosswake companion contracts stay pure Elixir; host/example persistence and `Plug.Conn` mutation stay host-owned.
- Support claims are backed by support-matrix accessors, doctor checks, operator inspection, guide text, docs-contract tests, and proof fixtures.
- Public shell reason lists stay stable while operator/developer subcodes carry richer low-cardinality detail.
- Sensitive route weakening is route-local, explicit, manifest-visible, and fail-closed through `auth_posture`.
- Provider/native/device inputs are evidence-only until backend validation projects a refreshed `SessionAuthorityLane`.

### Integration Points
- Add or evolve Sigra step-up contracts under `lib/crosswake/companions/sigra/`.
- Extend `DenialCodes` with `auth.step_up_intent.*` codes and safe detail keys.
- Add example-host Ecto schema/migration/module for step-up intents and audit events, likely mirroring handoff ticket/audit structure without reusing the handoff table.
- Add Plug and LiveView adapter modules that call the shared ceremony core.
- Update support matrix, doctor, publish readiness, operator inspection, guides, fixtures, and phase proof tests from "ceremony deferred" to "ceremony contract shipped" while preserving Phase 57/58 non-claims.

</code_context>

<specifics>
## Specific Ideas

- Recommended coherent architecture: server-side `StepUpIntent` record + opaque/signed locator; pure Sigra ceremony core; thin Plug and LiveView adapters; route-id return targets; host-owned `configure_session(conn, renew: true)` and CSRF rotation; no raw `return_to`; no generic policy framework.
- Example intent shape:
  ```elixir
  %StepUpIntent{
    intent_ref: "sup_01J...",
    state: :issued,
    subject_ref: "sub_opaque",
    org_id: "org_opaque",
    source_session_ref: "sess_123",
    expected_session_version: 42,
    source_route_id: "account-home",
    return_route_id: "billing-settings",
    return_params: %{"tab" => "payment_methods"},
    required_assurance_level: :mfa,
    required_auth_posture: :strict_recent,
    max_auth_age_seconds: 300,
    challenge_kind: :host_confirm_password,
    issued_at: "2026-06-02T15:00:00Z",
    expires_at: "2026-06-02T15:05:00Z",
    audit_correlation_ref: "support:sup_..."
  }
  ```
- Example shared ceremony shape:
  ```elixir
  Crosswake.Companions.Sigra.StepUp.evaluate_or_issue(route, auth_context, opts)
  #=> {:allow, facts}
  #=> {:challenge, %StepUpIntent{}, %StepUpChallenge{}}
  #=> {:deny, %Crosswake.Shell.Denial{}}
  ```
- Example host renewal application:
  ```elixir
  conn
  |> Phoenix.Controller.delete_csrf_token()
  |> MyAppWeb.UserAuth.apply_step_up_renewal(result)
  |> redirect(to: result.route_target.path)
  ```

</specifics>

<deferred>
## Deferred Ideas

- OAuth, passkey, native deep-link, and shell bridge auth-return validation stay Phase 57.
- Stable full `[:crosswake, :auth, ...]` telemetry names, cardinality policy, security closeout assertions, and final proof/support closeout stay Phase 58.
- Refresh-token rotation helpers, provider-specific identity templates, first-party passkey SDK wrappers, and native auth UI examples remain future requirements.

</deferred>

---

*Phase: 56-Step-Up Intent And Plug/LiveView Ceremony*
*Context gathered: 2026-06-02*
