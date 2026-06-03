# Phase 58 Security Closeout

**Phase:** 58 - Auth Diagnostics, Proof, And Security Closeout
**Status:** closed
**Review model:** STRIDE-style surface review

## Token And Locator Handling

| Surface | STRIDE | Adversarial scenario | Control | Evidence | Residual risk | Disposition |
|---------|--------|----------------------|---------|----------|---------------|-------------|
| Handoff envelopes, step-up locators, auth-return envelopes, deep links, bridge events, provider payloads, and telemetry events | Spoofing/Tampering/Elevation of privilege | A client presents a locator, deep link, bridge event, provider payload, or telemetry event as authority to set `SessionAuthorityLane`. | Locators and evidence are dereferenced against host-owned server records; only backend validation, audit evidence, and refreshed session authority projection may update route authority. | `lib/crosswake/companions/sigra/handoff.ex`, `lib/crosswake/companions/sigra/step_up.ex`, `lib/crosswake/companions/sigra/auth_return.ex`, `lib/crosswake/support_matrix/support_matrix.ex`, `test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs` | Provider/device proof remains advisory. | Closed |

## Handoff Tickets

| Surface | STRIDE | Adversarial scenario | Control | Evidence | Residual risk | Disposition |
|---------|--------|----------------------|---------|----------|---------------|-------------|
| Short-lived handoff ticket redemption | Spoofing/Tampering/Repudiation | Replay, double-consume, expiry bypass, revocation bypass, route mismatch, or session mismatch attempts mint authority from a stale handoff envelope. | Server-record redemption owns lifecycle, binding, audit fields, and consume semantics before any Phoenix session renewal instruction is emitted. | `lib/crosswake/companions/sigra/handoff.ex`, `test/crosswake/proof/phase55_session_handoff_tickets_test.exs`, `test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs` | Host must persist and consume records correctly in its own storage layer. | Mitigated |

## Step-Up Ceremony

| Surface | STRIDE | Adversarial scenario | Control | Evidence | Residual risk | Disposition |
|---------|--------|----------------------|---------|----------|---------------|-------------|
| Step-up intent and Plug/LiveView ceremony | Spoofing/Tampering/Elevation of privilege | A stale locator, LiveView-only path, or controller-only path bypasses shared auth semantics and updates authority without host validation. | Step-up locators are non-authoritative; route binding, lifecycle state, challenge outcome, and refreshed `SessionAuthorityLane` projection stay server-record owned across Plug and LiveView flows. | `lib/crosswake/companions/sigra/step_up.ex`, `lib/crosswake/companions/sigra/step_up_ceremony.ex`, `test/crosswake/proof/phase56_step_up_ceremony_test.exs` | Host-specific password/MFA UI remains outside Crosswake. | Mitigated |

## Auth Return Boundaries

| Surface | STRIDE | Adversarial scenario | Control | Evidence | Residual risk | Disposition |
|---------|--------|----------------------|---------|----------|---------------|-------------|
| OAuth, passkey, native auth return envelopes | Spoofing/Tampering/Information disclosure | A forged callback, custom scheme event, verified link, passkey challenge, provider payload, route mismatch, replay, expiry, revocation, or session mismatch tries to project authority. | Auth-return envelopes are route-local evidence; backend validation owns state, nonce, PKCE posture, redirect binding, link verification, origin/RP checks, expiry, replay posture, and final authority projection. | `lib/crosswake/companions/sigra/auth_return.ex`, `test/crosswake/proof/phase57_auth_return_boundaries_test.exs`, `guides/companions.md` | Real provider SDK/device evidence is advisory until promotion criteria ship. | Mitigated |

## Telemetry And Diagnostics

| Surface | STRIDE | Adversarial scenario | Control | Evidence | Residual risk | Disposition |
|---------|--------|----------------------|---------|----------|---------------|-------------|
| `[:crosswake, :auth, ...]` telemetry events | Information disclosure/Tampering | A caller emits raw tokens, authorization codes, refresh tokens, credential IDs, raw nonces, PKCE verifiers, session refs, actor/org/device identifiers, IPs, user agents, provider payloads, emails, raw `return_to`, or authority-changing facts. | Telemetry is diagnostic evidence only; event names are stable, metadata is allowlisted and low-cardinality, and forbidden secret/identity/high-cardinality keys are dropped before `:telemetry.execute/3`. | `lib/crosswake/companions/sigra/telemetry.ex`, `test/crosswake/companions/sigra/telemetry_test.exs`, `test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs` | Future OpenTelemetry adapter mapping needs separate attribute guidance. | Mitigated |

## Denial Sanitization

| Surface | STRIDE | Adversarial scenario | Control | Evidence | Residual risk | Disposition |
|---------|--------|----------------------|---------|----------|---------------|-------------|
| Public denials and Sigra denial details | Information disclosure/Repudiation | Denial details leak raw tokens, codes, nonces, PKCE verifiers, credentials, session refs, actor/org/device IDs, email, IP, user-agent, provider payload, or raw return targets. | Public shell reason remains `:step_up_required`; richer subcodes and details are low-cardinality and allowlisted by `Crosswake.Companions.Sigra.DenialCodes`. | `lib/crosswake/companions/sigra/denial_codes.ex`, `test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs` | Host-specific logging outside Crosswake still needs local review. | Closed |

## Session Renewal And LiveView Invalidation

| Surface | STRIDE | Adversarial scenario | Control | Evidence | Residual risk | Disposition |
|---------|--------|----------------------|---------|----------|---------------|-------------|
| Phoenix session renewal, CSRF rotation, and LiveView invalidation | Elevation of privilege/Tampering | A host mutates `Plug.Conn` or LiveView session state before backend validation, or lets stale LiveViews keep old authority. | Crosswake returns typed host-owned instructions only after validation; hosts own `configure_session(conn, renew: true)`, CSRF rotation posture, and LiveView invalidation after successful validation. | `lib/crosswake/companions/sigra/step_up_ceremony.ex`, `guides/companions.md`, `test/crosswake/proof/phase56_step_up_ceremony_test.exs` | Host implementation must follow the instructions. | Mitigated |

## Doctor Support Operator And Docs Truth

| Surface | STRIDE | Adversarial scenario | Control | Evidence | Residual risk | Disposition |
|---------|--------|----------------------|---------|----------|---------------|-------------|
| Support matrix, doctor, publish readiness, operator inspection, and guides | Repudiation/Information disclosure | Public or operator surfaces overclaim provider/device proof, provider templates, passkey SDK wrappers, refresh-token helpers, direct shell/WebView token authority, or native auth UI. | Two-axis truth distinguishes shipped full Sigra contract machinery from host verification-required readiness and advisory provider/device proof; non-shipped surfaces remain explicit. | `lib/crosswake/support_matrix/support_matrix.ex`, `lib/crosswake/doctor/doctor.ex`, `lib/crosswake/doctor/publish_readiness.ex`, `lib/crosswake/operator_inspection.ex`, `guides/support_matrix.md`, `guides/companions.md` | Provider/device proof remains advisory. | Closed |

## Proof And Non-Claims

| Surface | STRIDE | Adversarial scenario | Control | Evidence | Residual risk | Disposition |
|---------|--------|----------------------|---------|----------|---------------|-------------|
| Merge-blocking and advisory proof lanes | Repudiation/Tampering | Closeout becomes manual-only, provider/device proof is promoted without criteria, or a giant environment-sensitive provider suite blocks every merge. | Hermetic Sigra contracts, denial sanitization, telemetry/docs parity, route gates, and closeout verifier are merge-blocking; provider/device proof remains advisory until explicit promotion criteria ship. | `.github/workflows/phase58-proof.yml`, `test/crosswake/proof/phase54_sigra_session_authority_test.exs`, `test/crosswake/proof/phase55_session_handoff_tickets_test.exs`, `test/crosswake/proof/phase56_step_up_ceremony_test.exs`, `test/crosswake/proof/phase57_auth_return_boundaries_test.exs`, `test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs` | Advisory provider/device proof requires future promotion work. | Mitigated |

## Findings Disposition

| Surface | STRIDE | Adversarial scenario | Control | Evidence | Residual risk | Disposition |
|---------|--------|----------------------|---------|----------|---------------|-------------|
| High - evidence channels setting authority | Elevation of privilege | Handoff envelopes, step-up locators, auth-return envelopes, deep links, bridge events, provider payloads, or telemetry events set `SessionAuthorityLane`. | Backend-owned server records and validation project authority; evidence channels cannot set it. | `lib/crosswake/support_matrix/support_matrix.ex`, `test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs` | None known in Crosswake contracts. | Closed |
| High - denial or telemetry secret leak | Information disclosure | Tokens, credentials, nonces, PKCE material, session refs, identity fields, provider payloads, IPs, user agents, or raw return targets leak through public denial or telemetry details. | Denial detail and telemetry metadata allowlists exclude secret, identity, and high-cardinality keys. | `lib/crosswake/companions/sigra/denial_codes.ex`, `lib/crosswake/companions/sigra/telemetry.ex`, `test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs` | Host logs outside Crosswake remain host-owned. | Mitigated |
| Medium - provider/device auth proof | Spoofing/Tampering | Real device/provider behavior diverges from hermetic contracts. | Provider/device proof remains advisory and non-promotional until explicit promotion criteria ship. | `guides/support_matrix.md`, `.github/workflows/phase58-proof.yml` | Environment-sensitive validation remains future work. | Advisory |
