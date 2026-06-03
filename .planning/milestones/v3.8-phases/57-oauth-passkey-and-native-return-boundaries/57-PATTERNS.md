# Phase 57 Pattern Mapping: OAuth, Passkey, And Native Return Boundaries

## Pattern Summary

Phase 57 is a boundary-hardening phase around an already-present Sigra shape:

- `auth_return` is a route-local policy declaration and manifest seam. It is not provider configuration, callback URL authority, bridge authority, or session authority.
- `Crosswake.Companions.Sigra.AuthReturn` is the pure core contract layer. It carries provider-neutral evidence, bounded envelopes, validation requests, host-owned attempt records, completions, and audit events.
- Host/example code owns Ecto rows, Repo transactions, provider/WebAuthn/OIDC library checks, Phoenix session mutation, CSRF/session renewal, and redirects.
- Denials keep the public shell reason as `:step_up_required`; stable operator subcodes live under `auth.return.*`.
- Support, doctor, docs, and proof surfaces must describe shipped provider-neutral boundary contracts without claiming provider templates, passkey SDK wrappers, native auth UI, refresh-token orchestration, AppAuth/device proof, or bridge authority.

Closest existing pattern family: Phase 55 handoff and Phase 56 step-up. Both use bounded client-presented locator/envelope structs, host-owned server records, request structs for backend validation, completion structs requiring `SessionAuthorityLane`, renewal instructions, append-only audit events, low-cardinality denial codes, and support truth rows.

## File Map

Files likely created or modified from `57-CONTEXT.md` and `57-RESEARCH.md`:

| File | Role | Data flow position | Pattern observations |
| --- | --- | --- | --- |
| `lib/crosswake/policy/schema.ex` | Route policy schema | Host route declaration input | Closed `auth_return` vocabulary for `kind`, `transport`, and `validates`; rejects provider-specific terms at schema normalization. |
| `lib/crosswake/policy/route.ex` | Route policy semantic validator | Validated route policy | Requires `kind`, `transport`, `return_route_id`; enforces kind-specific validation sets; defaults auth-return routes to sensitive `:strict_recent`; rejects sensitive `:custom_scheme`. |
| `lib/crosswake/manifest/types.ex` | Manifest type contract | Shell/operator-visible route truth | `RouteAuthReturn` mirrors route-local declaration exactly: `kind`, `transport`, `return_route_id`, `validates`. |
| `lib/crosswake/manifest/builder.ex` | Manifest serialization | Policy-to-manifest projection | `route_auth_return/1` copies only validated route policy fields into manifest route entries. |
| `lib/crosswake/companions/sigra/auth_return.ex` | Pure Sigra contracts | Evidence, attempt, completion, audit contract layer | Defines OAuth/passkey/native evidence, envelope, attempt record, validation request, completion, and audit event; rejects forbidden envelope smuggling. |
| `lib/crosswake/companions/sigra/denial_codes.ex` | Denial taxonomy and detail sanitizer | Shell/operator denial metadata | Contains canonical `auth.return.*` subcodes and allowlisted safe detail keys; leaves public reason outside this module as `:step_up_required`. |
| `lib/crosswake/companions/sigra/handoff.ex` | Closest prior analog | Existing server-record redemption pattern | `HandoffEnvelope`, `HandoffTicketRecord`, redemption request, renewal instructions, redemption, and audit event provide the strongest structural model for auth-return. |
| `lib/crosswake/companions/sigra/step_up.ex` | Closest prior analog | Existing server-owned intent pattern | Step-up locator/record/request/completion/audit pattern confirms lifecycle, route binding, and renewal instruction conventions. |
| `lib/crosswake/support_matrix/support_matrix.ex` | Canonical public support truth | Manifest/docs/doctor support metadata | `auth_contract_truth/0` already lists auth-return boundary and attempt as shipped, server-record authoritative, envelope not authoritative, and provider/device/native UI deferred. |
| `lib/crosswake/doctor/doctor.ex` | Diagnostic truth | Operator findings | `phase_46_auth_findings/1` surfaces Sigra contract posture, denial codes, safe detail keys, and deferred auth-return non-claims. |
| `lib/crosswake/doctor/publish_readiness.ex` | Publish support parity | Release-readiness diagnostics | Research calls this a parity target if shipped/deferred wording diverges. |
| `lib/crosswake/operator_inspection.ex` | Operator surface parity | Runtime/operator inspection | Research flags it if explicit `auth_return` fields need parity with doctor/support truth. |
| `lib/crosswake/operator_inspection/types.ex` | Operator type parity | Structured inspection metadata | Same parity role as `operator_inspection.ex`; should expose typed auth-return posture only if needed. |
| `examples/phoenix_host/lib/crosswake_example/saas_portal/auth_return_attempt.ex` | Example-host Ecto attempt schema | Host-owned replay/expiry/binding/promotion source | Ecto schema stores attempt digest, lifecycle state, route ids, transport, link verification, digests, expected callback, expiry, audit ref, and projected authority. |
| `examples/phoenix_host/lib/crosswake_example/saas_portal/auth_return_audit_event.ex` | Example-host audit schema | Append-only host audit evidence | Ecto schema stores lifecycle event, outcome, denial code, route/kind, session projection facts, binding result, request ref, and metadata. |
| `examples/phoenix_host/priv/repo/migrations/20260602080000_create_sigra_auth_return_attempts.exs` | Example-host migration | Durable attempt storage | Proof expects this migration to exist alongside the schema. |
| `examples/phoenix_host/priv/repo/migrations/20260602080100_create_sigra_auth_return_audit_events.exs` | Example-host migration | Durable audit storage | Proof expects this migration to exist alongside the schema. |
| `guides/companions.md` | Public guide truth | Adopter-facing documentation | Must use provider-neutral boundary language and backend authority language. |
| `guides/support_matrix.md` | Public support matrix docs | Adopter/operator support truth | Must match `SupportMatrix.auth_contract_truth/0`. |
| `guides/native_shell.md` | Native/shell posture docs | Native transport non-claims | Research notes possible drift: it may still say OAuth/passkey/native auth-return validation is deferred while support truth says boundary contracts are shipped. |
| `test/crosswake/proof/phase57_auth_return_boundaries_test.exs` | Phase proof lane | Merge-blocking contract proof | Already asserts denial vocabulary, safe details, route policy, manifest serialization, no-smuggling, completion authority, support truth, and example-host schemas/migrations. |
| `test/crosswake/doctor/doctor_test.exs` | Diagnostic parity test | Doctor truth proof | Adjacent parity target. |
| `test/crosswake/doctor/publish_readiness_test.exs` | Publish-readiness parity test | Release truth proof | Adjacent parity target. |
| `test/crosswake/support_matrix/support_matrix_test.exs` | Support truth test | Canonical support proof | Adjacent parity target. |
| `test/crosswake/support_matrix/renderer_test.exs` | Rendered support docs test | Public support proof | Adjacent parity target. |
| `test/crosswake/guides/companions_test.exs` | Guide parity test | Docs proof | Adjacent parity target. |

## Closest Analogs

### Route Policy And Manifest

- Commerce and transfer route declarations are the local style precedent: schema normalizes declarations, `Route.new/1` applies semantic validation, and `Manifest.Builder` serializes typed route-local seams.
- `auth_return` follows this pattern without adding global registries. `schema.ex` owns vocabulary and normalization; `route.ex` owns cross-field semantics; `types.ex` owns manifest structs; `builder.ex` owns projection.
- `Route.new/1` validates route-local completeness but does not prove `return_route_id` exists in the compiled manifest. Existing fallback route diagnostics in `Doctor` show the pattern for manifest-known route-id checks.

### Sigra Handoff

- `Handoff.HandoffEnvelope` is the closest envelope analog: bounded locator/correlation data only, no identity/session/authority smuggling.
- `Handoff.HandoffTicketRecord` is the closest attempt-record analog: host-owned lifecycle, replay, expiry, binding, audit correlation, and projected `SessionAuthorityLane`.
- `Handoff.HandoffRedemptionRequest` maps to `AuthReturn.ValidationRequest`; both carry expected route/kind facts for backend comparison.
- `Handoff.SessionRenewalInstructions` is reused by `AuthReturn.Completion`, keeping Plug/Phoenix session mutation host-owned.

### Sigra Step-Up

- `StepUp.StepUpIntentLocator` and `StepUp.StepUpIntentRecord` provide the server-owned intent lifecycle precedent.
- Step-up uses closed lifecycle and event vocabularies, explicit route-id return targets, challenge evidence as evidence-only, and completion requiring projected authority.
- Auth-return should keep the same mental model: evidence is collected, but authority changes only through backend projection.

### Denials And Support Truth

- `DenialCodes` already centralizes stable subcodes and safe details for step-up, handoff, step-up intent, and auth-return.
- `SupportMatrix.auth_contract_truth/0` is the canonical row that doctor, manifest support truth, support docs, and proof tests should align to.
- `Doctor.phase_46_auth_findings/1` already pulls `shipped_contracts`, `auth_return`, `denial_codes`, `safe_detail_keys`, and `deferred` directly from support truth, which is the preferred parity pattern.

### Example Host

- `AuthReturnAttempt` and `AuthReturnAuditEvent` intentionally live in the Phoenix example host, not core. They demonstrate the host-owned Ecto boundary without making Crosswake depend on Repo, provider SDKs, or Plug.Conn mutation.
- The attempt schema mirrors the pure `AuthReturn.AttemptRecord` fields but stores projected authority as a map, suitable for example persistence.
- The audit schema mirrors `AuthReturn.AuditEvent` and keeps event rows append-only by shape, with `event_id` uniqueness.

## Data Flow

1. Host declares a route-local `auth_return` policy with provider-neutral `kind`, semantic `transport`, manifest route id `return_route_id`, and required `validates`.
2. `Crosswake.Policy.Schema` normalizes the declaration and rejects unsupported/provider-specific vocabulary.
3. `Crosswake.Policy.Route` enforces required auth-return fields, kind-specific validation sets, sensitive defaults, strict auth posture, and sensitive custom-scheme rejection.
4. `Crosswake.Manifest.Builder` serializes the validated route seam into `RouteEntry.auth_return` as `RouteAuthReturn`.
5. OAuth/passkey/native return evidence is parsed by host/provider-specific code, then represented as `AuthReturn.OAuthEvidence`, `PasskeyEvidence`, or `NativeEvidence`.
6. The host builds an `AuthReturn.Envelope` containing bounded route binding, callback, timestamp, replay/link/validation posture, refs/digests, and nested evidence. Forbidden raw secrets, raw provider payloads, raw identifiers, raw redirects, and authority-setting fields are rejected.
7. The host builds `AuthReturn.ValidationRequest` with expected route id, return route id, kind, session/version facts, request ref, and evaluation timestamp.
8. The host looks up the durable attempt row by ref/digest and compares envelope/request/attempt/provider-verifier facts: route id, return route id, kind, transport, callback binding, state/nonce/PKCE or challenge/origin/RP/user-verification, link verification, lifecycle, expiry, revocation, and replay.
9. Inside one host-owned transaction, the host conditionally consumes an issued, unexpired, unreplayed attempt row; writes audit evidence; projects a fresh `SessionAuthorityLane`; and returns `AuthReturn.Completion`.
10. `AuthReturn.Completion` requires a real `SessionAuthorityLane` plus `Handoff.SessionRenewalInstructions`; Crosswake core still does not mutate `Plug.Conn`.
11. Denied flows use shell reason `:step_up_required` with safe `auth.return.*` subcodes/details. Support, doctor, operator, and docs truth expose the boundary and non-claims.

## Implementation Notes

- Keep route policy vocabulary closed: `:oauth`, `:passkey`, `:native_auth`; `:http_callback`, `:verified_https_link`, `:custom_scheme`, `:bridge_event`; and the locked validation atoms.
- Keep provider labels out of route policy. If host evidence needs provider posture, store it as provider-neutral evidence facts or safe refs/digests, not as route authority.
- `return_route_id` should remain a Crosswake route id, not a URL. Add or preserve manifest-known route-id proof outside schema-level validation because `Route.new/1` does not have the full manifest.
- Use `:verified_https_link` or `:http_callback` for sensitive auth-return routes. `:custom_scheme` should remain advisory; `:bridge_event` should remain shell evidence after manifest-first activation.
- Treat `AuthReturn.validate_envelope/1` as shape/posture validation only. Do not let envelope validation imply promotion or route authority.
- Semantic validation belongs in host/backend comparison against the attempt row and provider/WebAuthn/OIDC verifier outputs.
- Keep completion strict: no plain maps in place of `SessionAuthorityLane` or `SessionRenewalInstructions`.
- Keep denial details small and low sensitivity. `DenialCodes.sanitize_details/1` allowlists keys and simple value shapes, but upstream code still must avoid passing raw tokens, nonces, session refs, identity refs, IPs, user agents, and provider payloads.
- Preserve docs wording that boundary contracts are shipped while provider templates, passkey SDK wrappers, native auth UI, refresh-token orchestration, and device/provider proof are deferred or advisory.
- If adding host transaction examples, follow the Phase 55/56 server-record model: atomic conditional consume plus audit plus projection, not check-then-update.

## Risks

- `return_route_id` can become decorative if no manifest-known route-id check or proof verifies it.
- `AuthReturn.normalize_key/1` uses `String.to_atom/1` for string keys. If constructors receive arbitrary untrusted payloads directly, atom creation is a footgun; hardening should use bounded known-key normalization.
- Envelope validators can create false confidence if tests only assert shape. Proof should include semantic mismatch scenarios against request/attempt facts.
- Sensitive custom schemes must stay rejected. Docs and examples should not accidentally make custom schemes look like the recommended OAuth/passkey/native return posture.
- `:bridge_event` can drift into a generic auth event bus unless docs/tests keep it as evidence-only, not redirect receiver or passkey authority.
- Current support truth already says Phase 57 auth-return boundaries are shipped. Any incomplete behavior or guide drift, especially in `guides/native_shell.md`, creates public support inconsistency.
- Safe detail sanitization allows short strings for many allowed keys. That is only safe if call sites pass refs, digests, postures, and timestamps rather than raw secret or identity-bearing values.
- Example-host schemas prove record posture, not provider cryptography or device behavior. Keep merge-blocking proof hermetic and label provider/device runs advisory or deferred.
