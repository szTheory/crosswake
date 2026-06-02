# Phase 57 Research: OAuth, Passkey, And Native Return Boundaries

## Research Summary

Phase 57 should be planned as a boundary-hardening and parity phase, not a broad provider-auth implementation. The core thesis is already locked by prior Sigra work: route authority is backend-owned `SessionAuthorityLane` projection; OAuth callbacks, passkey assertions, native links, and bridge events are evidence only until a host-owned backend flow validates and promotes them.

The repo already contains substantial Phase 57-shaped work:

- Route-local `auth_return` policy vocabulary in `Crosswake.Policy.Schema` and `Crosswake.Policy.Route`.
- Manifest serialization through `RouteAuthReturn` and `Manifest.Builder.route_auth_return/1`.
- Pure Sigra contracts in `Crosswake.Companions.Sigra.AuthReturn`.
- `auth.return.*` denial codes and safe detail allowlist in `Crosswake.Companions.Sigra.DenialCodes`.
- Support, doctor, docs, and proof surfaces that already say auth-return boundaries are shipped.
- Example-host Ecto schemas and migrations for auth-return attempt and audit rows.

The implementation plan should therefore start with an audit of what is already present, then close gaps around exact validation semantics, route-id binding, host transaction examples, denial sanitization, docs/support parity, and proof quality. The plan must avoid widening into Google/GitHub/Apple/Okta/Auth0 templates, passkey SDK wrappers, native auth UI, refresh-token orchestration, AppAuth device proof, or bridge authority.

Primary external standards lessons to preserve:

- RFC 8252 treats native OAuth as external-user-agent-first and calls out private schemes, claimed HTTPS redirects, and security considerations for native apps: https://www.rfc-editor.org/rfc/rfc8252
- RFC 9700 reinforces exact redirect and OAuth security posture: https://www.rfc-editor.org/rfc/rfc9700
- RFC 7636 makes PKCE the public-client interception mitigation: https://www.rfc-editor.org/rfc/rfc7636
- OIDC Core supplies nonce, issuer/audience, `auth_time`, and `acr` evidence concepts: https://openid.net/specs/openid-connect-core-1_0-18.html
- WebAuthn Level 3 centers server validation around challenge, origin/RP ID, user verification, and assertion facts: https://www.w3.org/TR/webauthn-3/
- Plug and Ecto keep the session mutation and consume/audit/project transaction host-owned: https://plug.hexdocs.pm/Plug.Conn.html and https://ecto.hexdocs.pm/Ecto.Multi.html

## Existing Code Map

Route policy:

- `lib/crosswake/policy/schema.ex` defines closed `auth_return` kinds `:oauth`, `:passkey`, `:native_auth`; transports `:http_callback`, `:verified_https_link`, `:custom_scheme`, `:bridge_event`; and validations such as `:state`, `:nonce`, `:pkce`, `:redirect_uri`, `:link_verification`, `:challenge`, `:origin`, `:rp_id`, `:user_verification`, `:callback_binding`, `:expiry`, and `:replay`.
- `lib/crosswake/policy/route.ex` requires `kind`, `transport`, and `return_route_id`, applies required validation sets per kind, defaults auth-return routes to `security: :sensitive` and `auth_posture: :strict_recent`, and rejects `:custom_scheme` for sensitive auth-return routes.
- Important planning gap: the route validator requires a `return_route_id` string but does not itself prove the id exists in the compiled manifest. The manifest/compiler or a proof fixture must cover manifest-known binding.

Manifest:

- `lib/crosswake/manifest/types.ex` defines `RouteAuthReturn`.
- `lib/crosswake/manifest/builder.ex` serializes `route.auth_return` into each manifest route entry.

Sigra auth-return contracts:

- `lib/crosswake/companions/sigra/auth_return.ex` defines `OAuthEvidence`, `PasskeyEvidence`, `NativeEvidence`, `Envelope`, `AttemptRecord`, `ValidationRequest`, `Completion`, and `AuditEvent`.
- `new_envelope/1` rejects explicit smuggling keys such as raw access/refresh/ID tokens, authorization codes, credential IDs, authenticator data, client data JSON, PKCE verifiers, CSRF tokens, raw nonce, raw `return_to`, session/subject/org/device refs, and authority-setting fields.
- Current validators check shape, closed vocabulary, timestamp parseability, nested evidence type, and some transport/link verification posture. They do not appear to perform full semantic comparison between envelope facts, validation request expectations, and attempt-record facts. Plan this explicitly as host/backend validation, not envelope self-authority.

Denials:

- `lib/crosswake/companions/sigra/denial_codes.ex` already contains the required `auth.return.*` taxonomy and safe detail keys.
- Public shell reason remains `:step_up_required`; there is no broad `:auth_return_denied`.

Support/diagnostics/docs:

- `lib/crosswake/support_matrix/support_matrix.ex`, `lib/crosswake/doctor/doctor.ex`, `lib/crosswake/doctor/publish_readiness.ex`, `guides/companions.md`, `guides/support_matrix.md`, and `guides/native_shell.md` already mention Phase 57 shipped posture in places.
- `guides/native_shell.md` still says OAuth/passkey/native auth-return validation is deferred while other surfaces say shipped. Planning should include a parity pass so public truth is coherent after implementation.

Proof:

- `test/crosswake/proof/phase57_auth_return_boundaries_test.exs` is the main proof anchor for denial codes, safe details, route policy, manifest serialization, no-smuggling, backend promotion contract, support truth, and example-host Ecto records.
- Adjacent parity targets include doctor, publish readiness, support matrix renderer/tests, and companions/native-shell guide tests.

## Implementation Approach

Plan Phase 57 in tight vertical slices:

1. Route policy and manifest truth

   Verify `auth_return` accepts only the locked provider-neutral kinds/transports, rejects provider-specific vocabulary, rejects missing required validations, defaults to strict sensitive posture, and serializes into manifest route entries. Add proof for all three kinds and all transports where appropriate, including explicit rejection of sensitive `:custom_scheme`.

2. Pure contract closure

   Treat `Crosswake.Companions.Sigra.AuthReturn` as the core module. Ensure constructors and validators cover:

   - OAuth evidence: state, nonce when present, PKCE posture, redirect/callback posture, issuer/audience/auth-time/acr evidence, replay posture.
   - Passkey evidence: challenge, origin, RP ID, user verification, replay posture, sign-count/risk posture.
   - Native evidence: transport, platform, link verification, callback binding, replay posture.
   - Envelope: kind/transport/route/return-route binding, expected/received callback facts, timestamps, replay/link/validation posture, safe refs/digests only.
   - Attempt record: lifecycle, expiry, replay, binding facts, digests, projected authority, return params.
   - Completion: only valid with `SessionAuthorityLane` plus host-owned `SessionRenewalInstructions`.

3. Backend validation boundary

   Do not make envelope validation equivalent to promotion. Plan a host-owned validation flow shaped like:

   - parse transport-specific return evidence;
   - build/validate `AuthReturn.Envelope`;
   - build `ValidationRequest` with expected route id, return route id, kind, source session/version, request ref;
   - lookup host attempt row by ref/digest;
   - compare route id, return route id, kind, transport, callback, state/nonce/PKCE/challenge digests, link verification, expiry, lifecycle state, and replay posture;
   - inside one Ecto-style transaction, consume an issued/unexpired/unrevoked row, write audit, project `SessionAuthorityLane`, and return renewal instructions.

   Core Crosswake should expose contracts and examples. Host code owns Repo, provider libraries, WebAuthn/OIDC libraries, Phoenix session keys, CSRF/session renewal, and redirects.

4. Support truth and docs parity

   Update support matrix, doctor, publish readiness, operator inspection if needed, and guides so they all say the same thing: provider-neutral auth-return boundaries and host-owned attempt posture are shipped; provider templates, passkey SDK wrappers, refresh-token helpers, native auth UI, and provider/device proof are not shipped.

5. Proof closure

   Use `test/crosswake/proof/phase57_auth_return_boundaries_test.exs` as the phase-level proof lane. Add narrower unit tests if semantic validators grow, then update docs/support parity tests.

Likely files touched during implementation:

- `lib/crosswake/policy/schema.ex`
- `lib/crosswake/policy/route.ex`
- `lib/crosswake/manifest/types.ex`
- `lib/crosswake/manifest/builder.ex`
- `lib/crosswake/companions/sigra/auth_return.ex`
- `lib/crosswake/companions/sigra/denial_codes.ex`
- `lib/crosswake/support_matrix/support_matrix.ex`
- `lib/crosswake/doctor/doctor.ex`
- `lib/crosswake/doctor/publish_readiness.ex`
- `lib/crosswake/operator_inspection.ex` and `lib/crosswake/operator_inspection/types.ex` if operator fields need explicit `auth_return` parity
- `examples/phoenix_host/lib/crosswake_example/saas_portal/auth_return_attempt.ex`
- `examples/phoenix_host/lib/crosswake_example/saas_portal/auth_return_audit_event.ex`
- the two auth-return migrations under `examples/phoenix_host/priv/repo/migrations/`
- `guides/companions.md`, `guides/support_matrix.md`, `guides/native_shell.md`
- proof and parity tests under `test/crosswake/proof`, `test/crosswake/doctor`, `test/crosswake/support_matrix`, and `test/crosswake/guides`

## Validation Architecture

Think in three layers:

1. Route-local declaration

   `auth_return` declares the seam: kind, transport, return route id, and validations. It is not provider configuration, not a callback URL registry, not route authority, and not session authority.

2. Evidence-only envelope

   `AuthReturn.Envelope` carries bounded facts and nested provider-neutral evidence. It can prove shape and posture, reject forbidden material, and support backend comparison. It cannot grant route access, set session fields, or choose arbitrary redirects.

3. Host-owned attempt record

   `AuthReturn.AttemptRecord` or the example-host Ecto row is the replay, expiry, lifecycle, binding, audit, and promotion source of truth. Expiry must be enforced from `expires_at` even if cleanup has not updated state. Replay prevention must be an atomic conditional consume, not a check-then-update.

Plan semantic validation checks as explicit comparisons:

- `request.expected_route_id == envelope.route_id == attempt.route_id`
- `request.expected_return_route_id == envelope.return_route_id == attempt.return_route_id`
- `request.expected_kind == envelope.kind == attempt.kind`
- `envelope.transport == attempt.transport`
- `expected_callback == received_callback` for callback transports, and both match the host/provider registered callback posture
- OAuth state, nonce, and PKCE compare by digest/posture against the attempt row
- Passkey challenge, origin, RP ID, user verification, and assertion posture compare against the attempt/provider verifier results
- Native link verification is `:verified` for sensitive verified-link claims; custom scheme and bridge event remain lower-assurance evidence
- attempt state is `:issued`, `consumed_at` is nil, `revoked_at` is nil, and `expires_at` is in the future
- completion contains a fresh `SessionAuthorityLane` plus explicit renewal instructions

Do not require core to implement provider-specific token exchange, WebAuthn cryptographic verification, or app-link device verification. Core should make the host's validation output typed and auditable.

## Security Considerations

The highest-risk mistake is confusing "return received" with "authority granted." Plan tests and docs around this exact distinction:

- OAuth callback received is not user authorization until backend validation, token/provider checks, attempt consumption, audit, and session authority projection succeed.
- Passkey assertion received is not authority until server challenge/origin/RP/user-verification/signature validation and backend projection succeed.
- Native deep link delivered is not auth complete. Verified HTTPS links are stronger than custom schemes, but device verification remains advisory unless a future proof path promotes it.
- Bridge event received is not route authority, not session authority, and not token transport.

No raw secrets or identifiers should appear in envelopes, denial details, fixtures, support truth, or docs examples:

- access tokens, refresh tokens, ID tokens, authorization codes;
- credential IDs, authenticator data, client data JSON;
- PKCE verifiers, raw nonce/state/CSRF material;
- raw `return_to`;
- session, subject, org, actor, device refs;
- provider payloads, IPs, user agents, emails, phone numbers.

Keep stable low-cardinality denials. Public shell reason remains `:step_up_required`; subcodes live under `auth.return.*`.

Use `:verified_https_link` or `:http_callback` for sensitive auth-return routes. `:custom_scheme` is advisory fallback only. `:bridge_event` is evidence only after manifest-first activation and must not act as OAuth redirect receiver or passkey authority.

## Proof And Docs Strategy

Merge-blocking hermetic proof should cover:

- route policy accepts `:oauth`, `:passkey`, and `:native_auth` only;
- provider-specific terms are rejected;
- required validation sets are enforced;
- auth-return routes default to sensitive strict posture;
- sensitive custom-scheme routes fail closed;
- manifest route entries serialize `auth_return`;
- envelope construction rejects raw secrets, identifiers, raw provider payloads, raw `return_to`, and authority-setting fields;
- evidence constructors validate kind-specific posture;
- completion requires `SessionAuthorityLane` and `SessionRenewalInstructions`;
- example-host attempt/audit schemas and migrations expose replay, expiry, lifecycle, binding, projection, and audit fields;
- support matrix, doctor, publish readiness, operator inspection, guides, and tests agree on shipped/deferred claims;
- public non-claims stay explicit.

Suggested command set for the phase plan:

- `mix test test/crosswake/proof/phase57_auth_return_boundaries_test.exs`
- `mix test test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/support_matrix/renderer_test.exs`
- `mix test test/crosswake/doctor/doctor_test.exs test/crosswake/doctor/publish_readiness_test.exs`
- `mix test test/crosswake/guides/companions_test.exs`

Full-suite risk: `.planning/STATE.md` notes known unrelated planning-transition parity failures. Phase planning should record whether focused proof is green separately from full-suite status.

Docs should use the locked wording: Sigra auth-return boundaries are provider-neutral contracts; Crosswake validates OAuth, passkey, and native return envelopes before backend promotion; OAuth providers, passkey SDK wrappers, native auth UI, refresh-token rotation, and provider/device proof remain deferred or advisory; verified HTTPS links are required for sensitive native return claims; custom schemes and bridge events are evidence only; route authority comes only from backend validation into `SessionAuthorityLane`.

## Risks And Footguns

- Existing support/docs already claim Phase 57 is shipped. If implementation is incomplete, the plan must either finish the code or temporarily avoid widening public truth. Do not leave contradictory docs like the current native-shell deferred wording next to support-matrix shipped wording.
- `return_route_id` can become decorative if not validated against manifest-known route ids during compile/host validation. This is the most important route-boundary proof gap to close.
- Envelope validators can create false confidence if they only validate shape. Plan semantic comparison against server attempt records explicitly.
- `String.to_atom/1` in envelope key normalization can atomize arbitrary incoming string keys. If these constructors are ever used directly on untrusted payloads, this is a security footgun. Consider planning a bounded key-normalization hardening step.
- `:custom_scheme` is useful but lower assurance. It must not satisfy sensitive verified-link claims or appear in docs as the recommended posture.
- `:bridge_event` must not become a generic auth event bus. It is evidence after route/manifest activation, not auth transport authority.
- Provider-specific labels can leak into route policy through examples. Keep provider kind evidence generic and route policy provider-neutral.
- Shell-safe detail sanitization currently allows any short string for many allowed keys. That is acceptable only if upstream code passes support refs/digests, not raw secret material. Tests should include negative cases.
- Phase 58 owns stable telemetry and final security closeout. Do not add broad telemetry taxonomy in Phase 57 unless the phase plan intentionally scopes it as provisional or docs-only.

## Planning Recommendations

Plan Phase 57 as three or four small plans:

1. Policy, manifest, and contract audit

   Confirm current implementation against RETN-01/02/03. Add missing tests before changing behavior. Focus on provider-neutral vocabulary, required validation sets, strict sensitive defaults, manifest route serialization, and no provider-specific route-policy terms.

2. AuthReturn semantic validation and no-smuggling hardening

   Strengthen `AuthReturn` constructors/validators where needed. Add tests for all three evidence kinds, forbidden fields, unsupported claims, timestamp expiry posture, callback mismatch posture, verified-link requirements, and completion authority requirements.

3. Host-owned attempt and promotion proof

   Use the example-host Ecto schemas/migrations as proof of the server-backed attempt/audit shape. If there is no host flow module yet, decide whether Phase 57 needs a minimal pure/example transaction sketch or whether schema proof is enough. The safer plan is to add a small example-host module or tests that demonstrate conditional consume + audit + projection without adding provider code.

4. Truth-surface closure

   Align support matrix, doctor, publish readiness, operator inspection, guides, and docs-contract tests. Explicitly correct cross-surface wording around shipped auth-return boundary contracts versus deferred provider/device/native UI claims.

Keep the end-state narrow: Crosswake ships typed adapter seams and validation contracts. The host still owns identity providers, WebAuthn libraries, Repo transactions, Plug/Phoenix session mutation, CSRF policy, and route redirects.
