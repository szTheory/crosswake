# Phase 55: Session Handoff Tickets And Authority Projection - Context

**Gathered:** 2026-06-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Add short-lived, signed, single-use Sigra handoff tickets that can upgrade session authority only through backend redemption.

**Delivers:**
- A typed handoff ticket contract with a signed client envelope and an authoritative server-side one-time ticket record.
- Atomic redemption semantics that consume the server-side ticket record, write audit evidence, project a refreshed `SessionAuthorityLane`, and expose host-owned Phoenix session renewal instructions.
- Stable handoff denial codes and sanitized shell-safe details while preserving `:step_up_required` as the public shell denial reason.
- Hermetic proof for issue, redeem, revoke, expire, replay, binding mismatch, route mismatch, intent mismatch, and audit metadata without requiring provider/device services.

**Satisfies:** HAND-01, HAND-02, HAND-03.

**In scope:**
- Pure Sigra handoff structs, closed vocabularies, constructors, validators, and denial-code registry expansion.
- Signed envelope shape, server-side ticket record shape, binding model, lifecycle states, replay/revocation/expiry checks, and audit event contracts.
- Host callback/contract boundary for redemption and Phoenix session renewal, plus a concrete example-host proof flow.
- Support/doctor/operator truth that says handoff contract machinery is shipped and remains backend-owned.

**Out of scope:**
- Full step-up intent lifecycle, challenge UX, Plug redirect orchestration, LiveView `on_mount` ceremony, CSRF rotation policy beyond renewal instructions, and return flow UX. Those belong to Phase 56.
- OAuth, passkey, native deep-link, shell bridge return validation, provider templates, or native auth UI. Those belong to Phase 57 or later.
- Full auth telemetry taxonomy, metrics cardinality policy, audit export adapters, and dedicated security closeout. Those belong to Phase 58.
- Refresh-token rotation helpers and direct shell/WebView token authority.

</domain>

<decisions>
## Implementation Decisions

### 1. Ticket Record And Envelope Shape - LOCKED
- **D-01:** Use a hybrid handoff shape: a short-lived signed client envelope plus an authoritative server-side one-time record. The envelope is only a redemption credential and locator; the server record is the replay, revocation, expiry, binding, audit, and authority-projection source of truth.
- **D-02:** Reject self-contained signed tickets that carry authority claims. Signing gives integrity, not confidentiality or revocation. Route gates must never trust handoff envelope claims directly; only a backend redemption that projects `SessionAuthorityLane` may affect route authority.
- **D-03:** The signed envelope should include only bounded, low-sensitivity claims: `typ`, `jti` or `ticket_ref`, `version`, `iss`, `aud`, `iat`, `exp`, `intent`, `route_id`, binding mode, and hashes/digests for correlation. Do not include raw actor IDs, session IDs, org IDs, device IDs, credential IDs, OAuth artifacts, provider payloads, CSRF tokens, nonces, PKCE verifiers, or PII.
- **D-04:** The server-side record should carry authoritative fields: `ticket_ref`, `ticket_digest` or `token_hash`, lifecycle `state`, `subject_ref`, `org_id`, source session ref/version, optional device ref, binding mode, intent kind/ref, source and target route IDs, required assurance/freshness/posture, issued/expires/consumed/revoked timestamps, revocation reason, audit correlation ref, and projection data used to build a refreshed `SessionAuthorityLane`.
- **D-05:** Lifecycle states should be closed and boring: `:issued`, `:redeemed`, `:expired`, `:revoked`. Expiry denial must work from `expires_at` even before cleanup marks a row `:expired`.
- **D-06:** Bind strongly to backend-known facts: subject, org/tenant, source session ref/version, target route, intent, audience, and required assurance/freshness. Device binding is opt-in only when the host has a backend-registered device identity. IP address, user-agent, shell instance, WebView hints, and platform metadata are audit/risk facts, not default hard bindings.
- **D-07:** Ticket TTL should be minutes, not hours. Planners may choose exact defaults, but the public guidance must frame handoff tickets as short-lived single-use artifacts.

### 2. Atomic Redemption And Session Renewal Boundary - LOCKED
- **D-08:** Phase 55 should define a host callback/contract plus a concrete example-host implementation. Crosswake owns typed contracts, validation, denial vocabulary, safe detail sanitization, and proof posture. The Phoenix host owns persistence, Repo, session keys, CSRF/session policy, and actual `Plug.Conn` mutation.
- **D-09:** Redemption atomicity means one backend transaction verifies the server-side record, consumes it once, records audit evidence, creates or updates the host session-authority record, and returns a fresh `SessionAuthorityLane`. The signed envelope can be verified before lookup for tamper/expiry fast-fail, but it cannot grant authority without the server row.
- **D-10:** Use an idiomatic transaction shape suitable for Ecto-backed hosts: `Ecto.Multi` or an equivalent `Repo.transaction` that conditionally consumes only when `state == :issued`, `consumed_at == nil`, not expired, not revoked, and all route/intent/binding checks pass. Avoid check-then-update races.
- **D-11:** Mutate `Plug.Conn` only after the backend transaction succeeds. The host renewal boundary should expose explicit instructions such as `renew_session?: true`, session keys to put/delete, projected session ref/version, and optional LiveView socket/session invalidation hints.
- **D-12:** The example-host should prove the copyable path: redeem ticket, call `configure_session(conn, renew: true)`, put host-owned session keys, project `SessionAuthorityLane`, validate the return route against manifest-known Crosswake route IDs, and deny arbitrary `return_to` URLs.
- **D-13:** Keep Phase 55 transport-neutral enough for Phase 56 Plug/controller and LiveView ceremony to reuse. Do not implement challenge creation, redirect UX, `on_mount` halting, or step-up intent lifecycle in this phase.

### 3. Handoff Denial Codes And Safe Details - LOCKED
- **D-14:** Preserve `:step_up_required` as the public shell denial reason. Add ticket-specific canonical subcodes under `auth.handoff.*`; do not overload Phase 54 `auth.step_up.*` route-authority codes.
- **D-15:** Initial handoff denial code taxonomy:
  - `auth.handoff.missing_ticket`
  - `auth.handoff.invalid_ticket`
  - `auth.handoff.expired_ticket`
  - `auth.handoff.replayed_ticket`
  - `auth.handoff.revoked_ticket`
  - `auth.handoff.binding_mismatch`
  - `auth.handoff.intent_mismatch`
  - `auth.handoff.route_mismatch`
  - `auth.handoff.projection_failed`
- **D-16:** Collapse malformed envelope, bad signature, unsupported version, unknown server record, and tamper failures into `auth.handoff.invalid_ticket` for shell/operator surfaces. More precise internals may exist in audit logs, but public diagnostic codes should not teach attackers which part failed.
- **D-17:** Add only low-cardinality, non-secret safe detail keys, such as `handoff_state`, `handoff_kind`, `handoff_version`, `handoff_transport`, `binding_kind`, `intent_kind`, `route_binding`, `ticket_expires_at`, `ticket_age_seconds`, `handoff_ref`, and `evaluated_at`.
- **D-18:** `handoff_ref` must be a generated support/correlation reference, not the raw ticket ID, signed envelope, token digest, server record primary key, session ref, actor ref, org ID, nonce, or credential identifier.
- **D-19:** Route mismatch and intent mismatch are denials, not redirect hints. Redemption must return only to server-validated, manifest-known route targets.

### 4. Audit And Replay Source Of Truth - LOCKED
- **D-20:** Use the ticket record as current lifecycle state and append audit events for lifecycle evidence. Do not make telemetry, signed envelopes, or cleanup jobs the source of truth for replay/revocation/expiry.
- **D-21:** Add a typed handoff audit event contract for `:issue`, `:redeem`, `:revoke`, `:expire`, and denied redemption attempts. Mandatory fields should include event id, event type, ticket ref/correlation ref, state before/after, outcome, denial code, occurred_at, route id, intent kind/ref, source session ref, projected session ref, session version before/after, assurance after, auth methods after, binding result, request ref, and actor kind.
- **D-22:** Audit metadata may store backend opaque refs needed for host audit, but shell-safe details, telemetry labels, fixtures, docs, and support truth must not expose raw ticket values, session IDs, actor IDs, provider payloads, passkey credential IDs, emails, IP addresses, or device identifiers.
- **D-23:** Doctor, support matrix, and operator inspection should expose now: shipped handoff contract, server-record authority, stable `auth.handoff.*` denial codes, required audit fields, hermetic proof class, and explicit non-claims for Phase 56 ceremony and Phase 57 OAuth/passkey returns.
- **D-24:** Defer stable `[:crosswake, :auth, ...]` telemetry event names, metrics cardinality policy, audit export adapters, OpenTelemetry/Threadline mapping, and security closeout assertions to Phase 58.

### 5. Ecosystem Lessons To Preserve - LOCKED
- **D-25:** Phoenix/Plug lesson: privilege changes and auth handoffs should renew the session ID with host-owned `configure_session(conn, renew: true)` behavior after backend validation succeeds.
- **D-26:** Ecto lesson: multi-step redeem flows need transaction composition and rollback semantics (`Ecto.Multi` or equivalent), especially for consume + audit + projection.
- **D-27:** Phoenix `phx.gen.auth` lesson: host-owned session/token tables are ordinary, unsurprising Phoenix architecture. Crosswake should provide contracts and example-host proof, not a hidden auth framework that takes over host accounts.
- **D-28:** OWASP/NIST/mature-framework lesson: session artifacts become sensitive authority once authenticated; renewal, timeout, revocation, generic user-facing failures, and durable server-side audit are not optional.
- **D-29:** Django/Spring/Guardian lesson: signed or tokenized session artifacts are useful, but revocation/replay truth requires server-side state when security-sensitive handoff is involved.
- **D-30:** Crosswake prompt-corpus lesson: the bridge is not an auth boundary, route ownership must stay explicit, and support claims must distinguish shipped contract machinery from provider/device/ceremony claims.

### the agent's Discretion
- Exact module names are planner discretion if they remain clearly Sigra-scoped. Strong defaults: `Crosswake.Companions.Sigra.Handoff`, `HandoffTicket`, `HandoffEnvelope`, `HandoffRedemption`, and `HandoffAuditEvent`.
- Exact Ecto schema/module names in the example host are planner discretion. Keep core contracts pure Elixir; example-host persistence can use Ecto.
- Exact TTL defaults, digest algorithm helpers, and envelope signing helper shape are planner discretion. Bias toward Phoenix-native primitives and narrow public API.
- Exact safe detail names may be refined, but the `auth.handoff.*` namespace, public `:step_up_required` reason, and no-secret allowlist semantics are locked.
- Exact support/doctor wording is planner discretion, but it must not claim Phase 56 step-up ceremony, Phase 57 return boundaries, refresh-token rotation, or provider/device proof.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/PROJECT.md` - Crosswake thesis, v3.8 milestone goal, constraints, current decisions, and non-goals.
- `.planning/REQUIREMENTS.md` - HAND-01/02/03 requirements for Phase 55 and later Phase 56-58 boundaries.
- `.planning/ROADMAP.md` - Phase 55 goal and success criteria; adjacent phase boundaries.
- `.planning/STATE.md` - current workflow position, known test caveat, and Phase 54 decisions.

### Prior Sigra decisions
- `.planning/phases/54-sigra-session-authority-contract-and-route-gate-semantics/54-CONTEXT.md` - locked backend authority, `SessionAuthorityLane`, evaluator boundary, `auth_posture`, denial code/detail sanitization, and deferred handoff scope.
- `.planning/phases/54-sigra-session-authority-contract-and-route-gate-semantics/54-RESEARCH.md` - Phase 54 ecosystem lessons around Phoenix sessions, LiveView security, OWASP/NIST, and auth evidence.
- `.planning/phases/54-sigra-session-authority-contract-and-route-gate-semantics/54-PATTERNS.md` - established implementation patterns and analogs for Sigra contracts and proof.
- `.planning/milestones/v3.5-phases/46-sigra-auth-contract-only-slice/46-CONTEXT.md` - original Sigra contract-only scope and route-auth denial posture.

### Prompt corpus and project research
- `prompts/crosswake-brand-book.md` - boundary-aware route/runtime language and support-claim guardrails.
- `prompts/crosswake-research-synthesis.md` - canonical architecture thesis: explicit runtime boundaries, route policy, bounded bridge, honest offline.
- `prompts/crosswake-integrations-and-companions.md` - Sigra companion classification and integration heuristics.
- `prompts/crosswake-elixir-oss-dna.md` - maintainer house style: install truth, support matrices, proof lanes, narrow public APIs, optional-dependency honesty.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` - enterprise auth/session handoff, mobile SSO, bridge security, and sensitive-route footguns.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` - Phoenix-native session defaults, bridge security, sensitive route flags, and DX/operator inspection lessons.
- `prompts/elixir-mobile-oss-lib-deep-research.md` - Sigra as auth/session companion, mobile session drift risks, audit/security proof posture, and bridge constraints.
- `prompts/crosswake-gsd-project-brief.md` - product brief and companion queue context.

### Existing Crosswake code
- `lib/crosswake/companions/sigra/contracts.ex` - current `AuthContext`, `SessionAuthorityLane`, `StepUpChallenge`, validation, and authority-fence implementation.
- `lib/crosswake/companions/sigra/evaluator.ex` - pure route-auth evaluator that Phase 55 must not turn into ceremony transport code.
- `lib/crosswake/companions/sigra/denial_codes.ex` - current canonical auth denial subcodes and shell-safe detail sanitizer to extend.
- `lib/crosswake/compatibility/route_gate.ex` - route activation pipeline and `:step_up_required` shell denial integration.
- `lib/crosswake/shell/denial.ex` - public shell denial vocabulary; do not add `:handoff_denied` in Phase 55.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex` - example-host auth pattern and likely analog for host-owned renewal proof.
- `lib/crosswake/doctor/doctor.ex` - doctor checks that should surface handoff readiness without provider/device claims.
- `lib/crosswake/doctor/publish_readiness.ex` - publish/readiness truth to distinguish handoff from deferred ceremony/return flows.
- `lib/crosswake/operator_inspection.ex` and `lib/crosswake/operator_inspection/types.ex` - operator truth surfaces for handoff support/audit posture.
- `lib/crosswake/support_matrix/support_matrix.ex` - canonical support truth and promotion/non-claim rows.

### Existing docs and proof
- `guides/companions.md` - current Sigra session-authority guide and non-claims that Phase 55 should update.
- `guides/support_matrix.md` - support truth and promotion/non-claim language for Sigra.
- `guides/native_shell.md` - shell/runtime support-claim language; handoff must not imply shell auth authority.
- `test/crosswake/proof/phase54_sigra_session_authority_test.exs` - current Sigra proof anchors and no-claim assertions.
- `test/crosswake/companions/sigra/contracts_test.exs` - contract constructor/validator analogs.
- `test/crosswake/guides/companions_test.exs` - docs-contract parity target.
- `test/crosswake/support_matrix/support_matrix_test.exs` and `test/crosswake/support_matrix/renderer_test.exs` - support truth parity targets.
- `test/crosswake/operator_inspection/operator_inspection_test.exs` and `test/crosswake/operator_inspection/json_formatter_test.exs` - operator surface parity targets.
- `test/crosswake/doctor/doctor_test.exs` and `test/crosswake/doctor/publish_readiness_test.exs` - doctor/readiness proof targets.

### External ecosystem references considered during discussion
- `https://hexdocs.pm/phoenix/Phoenix.Token.html` - Phoenix signed token verification and `max_age` pattern; useful for envelope integrity, not backend authority.
- `https://hexdocs.pm/plug/Plug.Conn.html` - `configure_session(conn, renew: true)` and request-scoped session mutation boundary.
- `https://hexdocs.pm/ecto/Ecto.Multi.html` - idiomatic multi-step transaction composition for consume + audit + projection.
- `https://hexdocs.pm/phoenix/mix_phx_gen_auth.html` - Phoenix-generated host-owned auth/session posture and sensitive-action lessons.
- `https://hexdocs.pm/phoenix_live_view/security-model.html` - LiveView security model and the need for shared auth decisions across HTTP and LiveView paths.
- `https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html` - session ID renewal after privilege changes, timeout, and server-side lifecycle guidance.
- `https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html` - generic user-facing auth errors and reauthentication posture.
- `https://pages.nist.gov/800-63-4/sp800-63b.html` - authenticator/session lifecycle guidance and replay/freshness considerations.
- `https://hexdocs.pm/guardian_db/Guardian.DB.html` - Elixir server-side token tracking/revocation lessons.
- `https://docs.djangoproject.com/en/4.2/topics/http/sessions/` - mature framework lessons around session cycling/flushing and signed-cookie caveats.
- `https://docs.spring.io/spring-security/reference/6.5-SNAPSHOT/servlet/authentication/session-management.html` - session fixation, invalidation, and registry lessons.
- `https://www.rfc-editor.org/rfc/rfc8252` - native OAuth external-user-agent guidance and why embedded shell authority is risky.
- `https://www.rfc-editor.org/rfc/rfc9700` - OAuth security BCP lessons around replay, redirect, and bearer-token risks.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Companions.Sigra.Contracts` already provides the namespace and contract style for pure structs, constructors, closed vocabularies, and evidence-authority fences.
- `SessionAuthorityLane` is the authority projection Phase 55 should produce after redemption. Handoff ticket/envelope claims must not bypass it.
- `Crosswake.Companions.Sigra.DenialCodes` centralizes denial subcodes and detail sanitization. Phase 55 should extend it or add a closely related Sigra handoff registry sourced by docs/tests.
- `Crosswake.Companions.Sigra.Evaluator` is intentionally transport-agnostic and should remain focused on route auth, not ticket redemption or session renewal.
- Example-host auth code provides the right ownership pattern: host app owns session keys and account/session persistence.
- Support matrix, doctor, publish readiness, and operator inspection already have Sigra session-authority rows that Phase 55 can promote from "no handoff" to "handoff contract shipped" without claiming later flows.

### Established Patterns
- Core Crosswake contracts are plain Elixir data contracts rather than Ecto schemas; adopter/example persistence can use Ecto.
- Support claims must be backed by canonical accessors, docs-contract tests, proof fixtures, and explicit non-claims.
- Public shell denial vocabulary stays stable while operator/developer subcodes carry richer low-cardinality detail.
- Evidence-only companion/provider inputs cannot mutate authority directly; backend projection is the authority boundary.
- Environment-sensitive provider/device proof remains advisory unless promotion criteria explicitly pass.

### Integration Points
- Add handoff contracts under `lib/crosswake/companions/sigra/`.
- Extend or supplement `lib/crosswake/companions/sigra/denial_codes.ex` with `auth.handoff.*` codes and safe detail keys.
- Add example-host handoff issue/redeem flow using Ecto-backed one-time records and host-owned `Plug.Conn` renewal.
- Update doctor/support/operator/docs truth to reflect shipped handoff contract and deferred ceremony/return/telemetry proof.
- Add hermetic proof covering issue, redeem, replay, expire, revoke, mismatch, projection failure, sanitization, docs/support parity, and no-claim assertions.

</code_context>

<specifics>
## Specific Ideas

### Recommended ticket envelope example

```elixir
%{
  "typ" => "crosswake.sigra.handoff.v1",
  "jti" => "hnd_01J...",
  "iss" => "crosswake_example",
  "aud" => "crosswake.sigra.handoff",
  "iat" => 1_780_389_000,
  "exp" => 1_780_389_180,
  "intent" => "session_handoff",
  "route_id" => "billing-settings",
  "binding_mode" => "session_route_intent",
  "subject_ref_hash" => "sha256:...",
  "session_ref_hash" => "sha256:...",
  "org_ref_hash" => "sha256:...",
  "record_digest" => "sha256:..."
}
```

### Recommended server record example

```elixir
%HandoffTicketRecord{
  ticket_ref: "hnd_01J...",
  ticket_digest: "sha256-of-full-signed-ticket",
  state: :issued,
  subject_ref: "sub_opaque",
  org_id: "org_opaque",
  source_session_ref: "sess_old",
  expected_session_version: 42,
  device_ref: nil,
  binding_mode: :session_route_intent,
  intent_kind: :session_handoff,
  source_route_id: "login-return",
  target_route_id: "billing-settings",
  required_assurance_level: :mfa,
  required_auth_posture: :strict_recent,
  issued_at: ~U[2026-06-02 12:00:00Z],
  expires_at: ~U[2026-06-02 12:03:00Z],
  consumed_at: nil,
  revoked_at: nil,
  audit_correlation_id: "req_opaque",
  projected_authority: %{
    state: :active,
    assurance_level: :mfa,
    authn_methods: [:password, :totp],
    authenticated_at: "2026-06-02T12:00:00Z",
    idle_expires_at: "2026-06-02T12:30:00Z",
    absolute_expires_at: "2026-06-03T00:00:00Z",
    session_version: 43
  }
}
```

### Recommended redemption result example

```elixir
{:ok,
 %HandoffRedemption{
   handoff_ref: "support_hnd_...",
   consumed_at: "2026-06-02T12:01:00Z",
   session_authority_lane: %SessionAuthorityLane{},
   session_projection: %{
     session_ref: "sess_new",
     session_version: 43
   },
   route_target: %{
     route_id: "billing-settings",
     path: "/billing/settings"
   },
   conn_instructions: %{
     renew_session?: true,
     put_session: %{"session_ref" => "sess_new"},
     delete_session: ["handoff_ticket"]
   }
 }}
```

### Recommended audit event example

```elixir
%HandoffAuditEvent{
  event_id: "evt_opaque",
  event_type: :redeem,
  ticket_ref: "hnd_01J...",
  ticket_state_before: :issued,
  ticket_state_after: :redeemed,
  outcome: :ok,
  denial_code: nil,
  occurred_at: ~U[2026-06-02 12:01:00Z],
  route_id: "billing-settings",
  intent_kind: :session_handoff,
  source_session_ref: "sess_old",
  projected_session_ref: "sess_new",
  session_version_before: 42,
  session_version_after: 43,
  assurance_level_after: :mfa,
  authn_methods_after: [:password, :totp],
  binding_result: :matched,
  request_ref: "req_opaque",
  actor_kind: :user
}
```

</specifics>

<deferred>
## Deferred Ideas

- Full step-up intent lifecycle, challenge UX, shared Plug/LiveView ceremony, CSRF renewal policy details, and validated return flow are deferred to Phase 56.
- OAuth/passkey/native auth-return boundaries and provider-specific return evidence validation are deferred to Phase 57.
- Stable auth telemetry names, low-cardinality metadata specification, audit export adapters, OpenTelemetry/Threadline mapping, and dedicated security closeout are deferred to Phase 58.
- Provider-specific identity templates, native auth UI, refresh-token rotation helpers, direct shell token authority, and offline sensitive mutation remain out of scope for v3.8 unless later roadmap work explicitly adds them.

</deferred>

---

*Phase: 55-Session Handoff Tickets And Authority Projection*
*Context gathered: 2026-06-02*
