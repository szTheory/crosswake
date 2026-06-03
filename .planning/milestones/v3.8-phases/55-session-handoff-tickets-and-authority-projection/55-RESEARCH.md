# Phase 55: Session Handoff Tickets And Authority Projection - Research

**Researched:** 2026-06-02
**Domain:** Phoenix-owned session handoff, one-time ticket redemption, Sigra authority projection
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Use a hybrid handoff shape: a short-lived signed client envelope plus an authoritative server-side one-time record. The envelope is only a redemption credential and locator; authority comes only from backend redemption and refreshed `SessionAuthorityLane`. [CITED: .planning/phases/55-session-handoff-tickets-and-authority-projection/55-CONTEXT.md]
- Do not put authority claims, raw actor IDs, session IDs, org IDs, device IDs, credential IDs, OAuth artifacts, provider payloads, CSRF tokens, PKCE verifiers, or PII into the client envelope. [CITED: .planning/phases/55-session-handoff-tickets-and-authority-projection/55-CONTEXT.md]
- Server records are the source of truth for replay, revocation, expiry, binding, audit, and authority projection. Lifecycle states are `:issued`, `:redeemed`, `:expired`, and `:revoked`; expiry must deny based on `expires_at` even before cleanup marks state. [CITED: .planning/phases/55-session-handoff-tickets-and-authority-projection/55-CONTEXT.md]
- Redemption must be atomic: verify/consume the issued record once, record audit evidence, create or update host session-authority state, and return a refreshed `SessionAuthorityLane` in one backend transaction. [CITED: .planning/phases/55-session-handoff-tickets-and-authority-projection/55-CONTEXT.md]
- Crosswake owns typed contracts, validation, denial vocabulary, safe detail sanitization, support truth, and proof posture. The Phoenix host owns Repo, persistence schemas, session keys, CSRF/session policy, and `Plug.Conn` mutation. [CITED: .planning/phases/55-session-handoff-tickets-and-authority-projection/55-CONTEXT.md]
- Mutate `Plug.Conn` only after successful backend redemption. Renewal instructions should tell the host to call `configure_session(conn, renew: true)` and put/delete host-owned session keys. [CITED: .planning/phases/55-session-handoff-tickets-and-authority-projection/55-CONTEXT.md]
- Preserve public shell reason `:step_up_required`; add stable subcodes under `auth.handoff.*`. Invalid/tamper/unknown/malformed failures collapse publicly to `auth.handoff.invalid_ticket`. [CITED: .planning/phases/55-session-handoff-tickets-and-authority-projection/55-CONTEXT.md]
- Route mismatch and intent mismatch are denials, not redirect hints. Return targets must be server-validated against manifest-known Crosswake route IDs. [CITED: .planning/phases/55-session-handoff-tickets-and-authority-projection/55-CONTEXT.md]
- Phase 55 must not implement Phase 56 challenge UX, redirect/on_mount ceremony, full CSRF rotation policy, or step-up intent lifecycle. It must also avoid Phase 57 OAuth/passkey/native return work and Phase 58 full telemetry/security closeout. [CITED: .planning/ROADMAP.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Planning Implication |
|----|-------------|----------------------|
| HAND-01 | Hosts can issue signed short-lived handoff envelopes backed by server-side one-time records. | Plan both pure Sigra envelope/record contracts and example-host Ecto record proof. |
| HAND-02 | Hosts can redeem a valid ticket through atomic backend flow that consumes ticket, renews Phoenix session, and projects refreshed `SessionAuthorityLane`. | Plan a host callback/contract returning renewal instructions plus example-host Plug proof; core stays pure. |
| HAND-03 | Missing, invalid, expired, replayed, revoked, binding/intent/route mismatch deny with stable codes and safe details. | Extend `DenialCodes` with `auth.handoff.*`, sanitizer allowlist, tests, docs/support/operator parity. |
</phase_requirements>

## Summary

Phase 55 should be planned as a Sigra handoff contract plus copyable Phoenix host proof, not as a full auth ceremony. Core Crosswake should add pure handoff structs, validators, denial-code vocabulary, and redemption result/session-renewal instruction contracts under the Sigra namespace. The example host should prove the Ecto/Phoenix mechanics: issue a signed envelope, persist a one-time server record, redeem in a transaction that consumes exactly one issued row, append audit evidence, project a refreshed `SessionAuthorityLane`, then renew the Phoenix session with host-owned keys.

The architectural center is "envelope integrity plus server-side authority". `Phoenix.Token` is a good fit for signing/verifying bounded envelope data with `max_age`, but it is not sufficient for replay, revocation, or authority projection. `Ecto.Multi` or an equivalent `Repo.transaction` is the right host implementation shape for consume + audit + projection. `Plug.Conn.configure_session(conn, renew: true)` belongs after the transaction succeeds.

## Existing Integration Points

### Core Sigra
- `lib/crosswake/companions/sigra/contracts.ex` already has the correct contract style: nested structs, `new_*` constructors, validators, closed vocabularies, timestamp normalization, and an evidence-authority fence. Add handoff contracts here only if the file stays readable; otherwise add a sibling `lib/crosswake/companions/sigra/handoff.ex` and keep `Contracts` focused on session authority. [CITED: lib/crosswake/companions/sigra/contracts.ex]
- `SessionAuthorityLane` is the required projection output after redemption. Planners should avoid a parallel "handoff authority" struct that RouteGate might trust directly. [CITED: lib/crosswake/companions/sigra/contracts.ex]
- `lib/crosswake/companions/sigra/evaluator.ex` is intentionally transport-agnostic and should stay that way. Handoff redemption should not move into the route evaluator. The evaluator can consume the projected lane after host redemption, but it should not verify tickets or renew sessions. [CITED: lib/crosswake/companions/sigra/evaluator.ex]
- `lib/crosswake/companions/sigra/denial_codes.ex` is the canonical place for subcodes and shell-safe details. Extend `codes/0`, `valid_code?/1`, `allowed_detail_keys/0`, and sanitizer logic rather than creating unrelated public lists. [CITED: lib/crosswake/companions/sigra/denial_codes.ex]

### Route/Shell Boundary
- `lib/crosswake/compatibility/route_gate.ex` already uses `Sigra.Evaluator` and emits `Denial.t` with public reason `:step_up_required`. Phase 55 does not need to change route gate ordering unless a proof needs to demonstrate that redeemed projection later satisfies the existing evaluator. [CITED: lib/crosswake/compatibility/route_gate.ex]
- `lib/crosswake/shell/denial.ex` already includes `:step_up_required`. Do not add `:handoff_denied`; the locked behavior is subcodes under the existing reason. [CITED: lib/crosswake/shell/denial.ex]

### Example Host
- `examples/phoenix_host` already has Phoenix 1.8, Plug, Ecto SQL, and SQLite dependencies. This is enough for hermetic host-owned persistence and transaction proof. [CITED: examples/phoenix_host/mix.exs]
- `CrosswakeExample.SaaSPortal.Auth` is the right ownership analog: host module owns the session key and calls `put_session/3`. Add handoff renewal helpers near this auth context or a sibling `CrosswakeExample.SaaSPortal.Handoff` module. [CITED: examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex]
- `CrosswakeExample.LocalFirst.Study.sync_events/1` shows the existing example-host Ecto.Multi style. For handoff, use the same project-local Ecto idiom but avoid check-then-update races. [CITED: examples/phoenix_host/lib/crosswake_example/local_first/study.ex]
- `examples/phoenix_host/lib/crosswake_example/router.ex` has a sensitive Sigra route (`saas-profile-settings`) with `auth_min_level`, `requires_recent_auth`, and `auth_posture: :strict_recent`. It is a natural proof target for route-bound handoff projection and return target validation. [CITED: examples/phoenix_host/lib/crosswake_example/router.ex]

### Support Truth
- `SupportMatrix.auth_contract_truth/0` currently says Phase 54 session authority is shipped and handoff is deferred. Phase 55 should update this to mention shipped handoff contract machinery while still deferring ceremony, passkey, OAuth, refresh tokens, and native auth UI. [CITED: lib/crosswake/support_matrix/support_matrix.ex]
- `Doctor.phase_46_auth_findings/1`, `PublishReadiness.auth_session_predicate_readiness_check/2`, and `OperatorInspection.auth_entry/1` all carry Phase 54 "no handoff" wording or deferred lists. Planning should include the wording and parity test updates. [CITED: lib/crosswake/doctor/doctor.ex] [CITED: lib/crosswake/doctor/publish_readiness.ex] [CITED: lib/crosswake/operator_inspection.ex]
- `guides/companions.md` and `guides/support_matrix.md` are docs-contract locked to the support matrix. Update them from "no handoff" to "handoff contract/server-record machinery shipped" without implying Phase 56 ceremony. [CITED: guides/companions.md] [CITED: guides/support_matrix.md]

## Architecture Recommendation

### Recommended Core Shape

Add a Sigra-scoped handoff module with pure structs and validation:

```text
lib/crosswake/companions/sigra/
|-- contracts.ex          # existing AuthContext, SessionAuthorityLane, StepUpChallenge
|-- denial_codes.ex       # extend with auth.handoff.* and allowed detail keys
|-- evaluator.ex          # unchanged route authority evaluator
`-- handoff.ex            # recommended home for new handoff contracts
```

Recommended contract structs:

- `HandoffEnvelope`: bounded signed-envelope payload after verification, with `typ`, `jti` or `ticket_ref`, `version`, `iss`, `aud`, `iat`, `exp`, `intent_kind`, `route_id`, `binding_mode`, and optional digest/correlation hashes.
- `HandoffTicketRecord`: pure host-record contract shape for authoritative fields. This can model the data expected from host persistence without becoming an Ecto schema in core.
- `HandoffRedemptionRequest`: envelope/token plus expected target route, intent, source session facts, request ref, and safe transport label.
- `HandoffRedemption`: success result containing `handoff_ref`, consumed timestamp, projected `SessionAuthorityLane`, session projection, route target, renewal instructions, and audit event.
- `HandoffAuditEvent`: typed append-only lifecycle evidence for issue/redeem/revoke/expire/denied attempts.
- `SessionRenewalInstructions`: host-owned instructions such as `renew_session?: true`, `put_session`, `delete_session`, `projected_session_ref`, `projected_session_version`, and optional socket/session invalidation hints.
- `HandoffDenial`: or a function returning `Shell.Denial.t` with reason `:step_up_required`, code, message, and sanitized details.

Keep the core contracts pure Elixir. Do not add Ecto schemas, Repo calls, or Plug mutation to the core library. That matches existing companion contracts and keeps Crosswake from owning the host auth framework.

### Recommended Host Shape

In `examples/phoenix_host`, add a minimal Ecto-backed proof context:

```text
examples/phoenix_host/lib/crosswake_example/saas_portal/
|-- handoff.ex              # issue/redeem/revoke host context
|-- handoff_ticket.ex       # Ecto schema for server-side one-time record
|-- handoff_audit_event.ex  # Ecto schema for lifecycle evidence
`-- auth.ex                 # renewal helper may live here or call handoff result
```

Add migrations for `sigra_handoff_tickets` and `sigra_handoff_audit_events`. Use string fields for opaque refs/digests and UTC datetimes. Create indexes that support proof and production posture:

- unique `ticket_ref`
- unique `ticket_digest` or token hash
- index on `state`
- index on `expires_at`
- index on `source_session_ref` or `audit_correlation_id` if used in tests

For redemption, prefer a single transaction with a conditional consume operation. The important invariant is that the consume step only succeeds if the record is still `issued`, unconsumed, not revoked, and not expired. In Ecto this can be implemented with either:

- `Ecto.Multi.run` that executes an `update_all` query with all conditions and requires `{1, _}` affected rows, then loads the consumed record, or
- a `Repo.transaction` function that locks/selects the row and updates it, if the adapter supports the chosen lock semantics.

SQLite in the example host may constrain row-lock idioms, so a conditional `update_all` by `ticket_ref`/digest plus state/timestamp conditions is likely the most hermetic proof path. The planner should ensure the implementation does not load a row, branch in Elixir, and then update by primary key without conditions; that is the check-then-update race.

### Envelope Signing

Use `Phoenix.Token` in the example host for the client envelope because it is Phoenix-native, signed, and supports `max_age` verification. Treat it as integrity and freshness for the locator, not as authority. The verified payload should still be matched against the server record:

- envelope `ticket_ref`/`jti` matches record
- envelope version/typ/audience are supported
- record digest matches the presented signed envelope or token hash
- record target route, intent, source session, subject/org, binding mode, assurance/freshness requirements match backend-known facts
- record is not expired, revoked, redeemed, or mismatched

Planner note: `Phoenix.Token.sign/4` signs terms for clients, and `verify/4` supports `max_age`; if confidentiality becomes necessary, `Phoenix.Token.encrypt/4` exists, but Phase 55 decisions prefer low-sensitivity envelope contents rather than encrypted authority claims. [CITED: https://hexdocs.pm/phoenix/Phoenix.Token.html]

## File-Level Implications

Likely core files:

- `lib/crosswake/companions/sigra/handoff.ex` - new pure contracts and helpers.
- `lib/crosswake/companions/sigra/denial_codes.ex` - append handoff code taxonomy and detail allowlist.
- `lib/crosswake/companions/sigra/contracts.ex` - possibly add lifecycle/binding vocabularies or reuse validators; avoid making it too large if `handoff.ex` is cleaner.
- `lib/crosswake/support_matrix/support_matrix.ex` - update auth truth and promotion rule/non-claim wording.
- `lib/crosswake/doctor/doctor.ex` - update auth findings to include handoff contract support and denial codes.
- `lib/crosswake/doctor/publish_readiness.ex` - update Sigra readiness message/details; keep Phase 56/57/58 defers explicit.
- `lib/crosswake/operator_inspection.ex` and maybe `lib/crosswake/operator_inspection/types.ex` - include handoff support posture, `auth.handoff.*` codes, safe detail keys, and deferred non-goals.
- `guides/companions.md`, `guides/support_matrix.md`, maybe `guides/native_shell.md` - update shipped/non-shipped Sigra language.

Likely example-host files:

- `examples/phoenix_host/lib/crosswake_example/saas_portal/handoff.ex`
- `examples/phoenix_host/lib/crosswake_example/saas_portal/handoff_ticket.ex`
- `examples/phoenix_host/lib/crosswake_example/saas_portal/handoff_audit_event.ex`
- `examples/phoenix_host/priv/repo/migrations/*_create_sigra_handoff_tickets.exs`
- `examples/phoenix_host/priv/repo/migrations/*_create_sigra_handoff_audit_events.exs`
- `examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex` for session renewal helper or session key constants.
- Possibly a narrow controller only if needed for `Plug.Conn` renewal proof. Keep it mechanical; do not implement Phase 56 challenge/redirect ceremony.

Likely tests:

- `test/crosswake/companions/sigra/handoff_test.exs`
- `test/crosswake/companions/sigra/contracts_test.exs` updates if vocabularies live there.
- `test/crosswake/proof/phase55_session_handoff_tickets_test.exs`
- support/doctor/operator/docs parity tests already named in Phase 55 context.

## Proof Strategy

Plan proof in layers.

### Core Contract Proof
- Handoff lifecycle vocabulary is closed: `:issued`, `:redeemed`, `:expired`, `:revoked`.
- Envelope contract accepts bounded low-sensitivity claims and rejects unknown/authority-bearing fields.
- Server record contract contains authoritative projection and binding fields.
- Redemption result contract requires `SessionAuthorityLane` and renewal instructions.
- Audit event contract requires issue/redeem/revoke/expire/denied attempt metadata.
- Denial code registry exactly includes:
  - `auth.handoff.missing_ticket`
  - `auth.handoff.invalid_ticket`
  - `auth.handoff.expired_ticket`
  - `auth.handoff.replayed_ticket`
  - `auth.handoff.revoked_ticket`
  - `auth.handoff.binding_mismatch`
  - `auth.handoff.intent_mismatch`
  - `auth.handoff.route_mismatch`
  - `auth.handoff.projection_failed`
- Sanitizer drops raw token, ticket id, ticket digest, session ref, actor id, org id, device id, provider payload, passkey credential id, email, IP, user-agent, nonce, CSRF token, and PKCE fields.

### Example Host Redemption Proof
- Issue creates a server record and signed envelope.
- Redeem succeeds once and returns a valid refreshed `SessionAuthorityLane`.
- Redeem consumes record atomically and writes audit evidence.
- Replay denies with `auth.handoff.replayed_ticket`.
- Expired record denies based on `expires_at` even if state is still `issued`.
- Revoked record denies with `auth.handoff.revoked_ticket`.
- Missing/malformed/bad signature/unknown record/tamper collapse to `auth.handoff.invalid_ticket`.
- Binding mismatch, route mismatch, and intent mismatch deny with their specific stable codes.
- Projection failure denies with `auth.handoff.projection_failed` and does not renew session.
- Success returns renewal instructions and the host proof calls `configure_session(conn, renew: true)` only after transaction success. [CITED: https://hexdocs.pm/plug/Plug.Conn.html]

### Route/Support Proof
- A route that receives the projected `SessionAuthorityLane` can satisfy existing `Sigra.Evaluator` checks for `saas-profile-settings`.
- Shell denial reason remains `:step_up_required`.
- Support matrix, doctor, publish readiness, operator inspection, and guides all source the same denial codes/safe detail keys.
- Docs include "handoff contract shipped" and still explicitly defer Phase 56 ceremony, Phase 57 OAuth/passkey/native returns, refresh-token rotation, and native auth UI.

## Validation Architecture

Validation should be layered and fail closed:

1. Envelope presence and signature validation. Missing ticket maps to `missing_ticket`; malformed/bad signature/unsupported version/tamper maps to public `invalid_ticket`.
2. Server record lookup by safe locator and digest. Unknown record maps to public `invalid_ticket`.
3. Lifecycle validation from record: state, consumed timestamp, revoked timestamp, expires timestamp.
4. Binding validation against backend-known facts: subject/org, source session ref/version, target route, intent, audience, required assurance/freshness, optional backend-registered device ref.
5. Manifest-known route target validation. Do not consume arbitrary `return_to` URLs.
6. Projection validation by building `SessionAuthorityLane` through existing constructors.
7. Atomic consume + audit + projection transaction.
8. Return host renewal instructions. Plug session mutation happens outside the transaction and only after success.

Device, IP, user-agent, shell instance, and WebView hints should be audit/risk metadata unless the host has explicitly established a backend device identity. That preserves the locked decision that weak client hints are not hard bindings by default.

## Risk And Footgun List

- **Self-contained token authority:** If planners let the envelope carry assurance/session claims that route gates trust, Phase 55 violates the core Sigra boundary.
- **Signed means secret misconception:** Phoenix.Token signing gives integrity, not confidentiality. Keep envelope claims low sensitivity.
- **Check-then-update replay race:** Loading a ticket, checking state in Elixir, and then updating without state/expiry conditions can allow double redemption under concurrency.
- **Expiry cleanup as source of truth:** Cleanup jobs can lag. Redemption must deny from `expires_at`.
- **Over-specific public invalid reasons:** Publicly distinguishing bad signature vs unknown record vs malformed payload teaches attackers. Collapse to `invalid_ticket`.
- **Leaking correlation identifiers:** `handoff_ref` must be generated support correlation, not raw ticket ref/digest/session/actor/org/device data.
- **Plug mutation inside transaction:** The database can roll back but `Plug.Conn` mutation cannot. Renew session after successful transaction only.
- **Open redirect through return target:** Route mismatch and arbitrary `return_to` are denials, not redirect instructions.
- **Route evaluator scope creep:** Do not put ticket verification, Ecto calls, or Plug/session behavior into `Sigra.Evaluator`.
- **Doctor/support overclaim:** Updating "no handoff" wording must not imply full step-up ceremony, OAuth/passkey return validation, provider templates, native auth UI, or refresh-token helpers.
- **SQLite proof limitations:** Example-host SQLite may not mirror all production locking semantics. Conditional updates with affected-row assertions are safer for hermetic proof than relying on unavailable row locks.

## Ecosystem Lessons

- Phoenix.Token is appropriate for signed, bounded client envelopes and `max_age` checks, but server-side state is needed for one-time use and revocation. [CITED: https://hexdocs.pm/phoenix/Phoenix.Token.html]
- Plug session renewal is the Phoenix/Plug primitive for privilege changes; use `configure_session(conn, renew: true)` at the host boundary. [CITED: https://hexdocs.pm/plug/Plug.Conn.html]
- Ecto.Multi groups multiple Repo operations in one transaction and supports dependent `run` steps; this maps well to consume + audit + projection. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]
- `phx.gen.auth` is a useful posture reference because it generates host-owned auth/session code rather than a hidden framework that owns accounts for the app. [CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html]
- OWASP recommends renewing session IDs after privilege level changes and recording session lifecycle events, including renewal, destruction, timeout, invalid activity, and privilege changes. [CITED: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html]
- OWASP Authentication guidance supports generic user-facing failures and reauthentication for sensitive features. [CITED: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html]
- NIST SP 800-63B-4 frames replay resistance around freshness/one-time validation and session continuity around verifier-issued session secrets; Phase 55's single-use server record and renewed Phoenix session align with that posture without importing federal assurance machinery wholesale. [CITED: https://pages.nist.gov/800-63-4/sp800-63b.html]
- Spring Security's session fixation posture reinforces the mature-framework lesson: privilege/authentication transitions should change the session id rather than carry the old one forward unchanged. [CITED: https://docs.spring.io/spring-security/reference/servlet/authentication/session-management.html]
- The Crosswake prompt corpus repeatedly says the bridge is not an auth boundary, bridge messages must be low-frequency/semantic, and sensitive/admin/auth routes should stay server-authoritative and inspectable. [CITED: prompts/crosswake-research-synthesis.md] [CITED: prompts/elixir-mobile-oss-refined-plan-deep-research.md] [CITED: prompts/crosswake-integrations-and-companions.md]

## Planning Notes

- Plan this as a small number of vertical slices: core handoff contracts and denial registry, example-host Ecto issue/redeem proof, then support/doctor/operator/docs parity. Avoid splitting by "all schemas first" or "all docs last" if that delays proving the authority boundary.
- The hardest implementation detail is the example-host redemption transaction. Give it enough plan space to prove replay/race semantics with deterministic tests.
- The second-hardest detail is support truth wording. A lot of Phase 54 surfaces explicitly say "No handoff"; planners need to update those strings consistently while preserving non-claims.
- Do not defer denial sanitization proof. It is part of HAND-03, not Phase 58.
- Telemetry event naming should remain minimal or absent unless needed for existing support surfaces; full auth telemetry taxonomy belongs to Phase 58.

## References

- `.planning/phases/55-session-handoff-tickets-and-authority-projection/55-CONTEXT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/PROJECT.md`
- `AGENTS.md`
- `lib/crosswake/companions/sigra/contracts.ex`
- `lib/crosswake/companions/sigra/evaluator.ex`
- `lib/crosswake/companions/sigra/denial_codes.ex`
- `lib/crosswake/compatibility/route_gate.ex`
- `examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex`
- `examples/phoenix_host/lib/crosswake_example/local_first/study.ex`
- `examples/phoenix_host/lib/crosswake_example/router.ex`
- `lib/crosswake/support_matrix/support_matrix.ex`
- `lib/crosswake/doctor/doctor.ex`
- `lib/crosswake/doctor/publish_readiness.ex`
- `lib/crosswake/operator_inspection.ex`
- `guides/companions.md`
- `guides/support_matrix.md`
- Phoenix.Token: https://hexdocs.pm/phoenix/Phoenix.Token.html
- Plug.Conn: https://hexdocs.pm/plug/Plug.Conn.html
- Ecto.Multi: https://hexdocs.pm/ecto/Ecto.Multi.html
- phx.gen.auth: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html
- OWASP Session Management Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html
- OWASP Authentication Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- NIST SP 800-63B-4: https://pages.nist.gov/800-63-4/sp800-63b.html
- Spring Security session management: https://docs.spring.io/spring-security/reference/servlet/authentication/session-management.html
