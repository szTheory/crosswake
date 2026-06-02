# Phase 58 Research

## Implementation Targets

Phase 58 should close the v3.8 Sigra arc by making shipped auth/session machinery inspectable, proof-backed, and security-reviewed. It should not add new route authority mechanisms or provider/device support claims.

Primary requirement coverage:

- **DIAG-02:** Lock stable `[:crosswake, :auth, ...]` telemetry names, low-cardinality metadata keys, forbidden metadata keys, and diagnostic-evidence-only posture.
- **DIAG-03:** Align doctor, publish readiness, support matrix, operator inspection, guides, and docs-contract tests around full provider-neutral Sigra machinery versus host/provider/device readiness.
- **PROOF-01:** Keep hermetic merge-blocking proof focused on deterministic contracts, route gates, replay/expiry/revocation, step-up returns, auth-return validation, denial sanitization, telemetry/docs parity, and security-sensitive non-claims. Keep provider/device proof advisory.

Implementation should preserve the locked decisions in `58-CONTEXT.md`:

- `Crosswake.Companions.Sigra.Telemetry` is the canonical telemetry registry.
- Telemetry is diagnostic evidence only, never audit/session/route authority.
- Support truth uses two axes: shipped contract proof versus host/provider/device readiness.
- Security closeout is a bounded adversarial STRIDE review plus findings ledger.
- Provider OAuth templates, passkey SDK wrappers, native auth UI, refresh-token helpers, direct shell/WebView token authority, and provider/device proof promotion remain out of scope.

The practical implementation target is likely a small number of hardening slices:

1. Finish telemetry contract parity and documentation locks.
2. Finish support/doctor/operator/publish-readiness wording and structured fields.
3. Strengthen `58-SECURITY.md` from checklist prose into an evidence-backed STRIDE ledger.
4. Harden closeout verification and CI parity around `phase58-proof.yml`.
5. Run the Phase 54-58 proof lane and full diagnostics/docs parity tests.

## Existing Assets

The repo already contains substantial Phase 58 implementation surface.

Telemetry:

- `lib/crosswake/companions/sigra/telemetry.ex` already defines the locked event families:
  - session evaluate start/stop/exception
  - denial
  - handoff issue/redeem/deny
  - step-up issue/challenge/consume/deny
  - return validate/consume/deny
- It exposes `event_names/0`, `metadata_keys/0`, `forbidden_metadata_keys/0`, flow/return-kind/outcome/freshness/proof registries, `new_event/1`, `metadata/1`, `to_map/1`, and `execute/3`.
- The sanitizer drops forbidden keys and unknown/high-cardinality values, with tests in `test/crosswake/companions/sigra/telemetry_test.exs`.

Support truth and diagnostics:

- `Crosswake.SupportMatrix.auth_contract_truth/0` already carries full Phase 58 fields: `contract_surface: :full_sigra_machinery`, `contract_proof_class: :merge_blocking`, `route_authority_source: :session_authority_lane`, `host_readiness: :verification_required`, `provider_device_proof: :advisory`, telemetry registry, security closeout, evidence-authority map, denial codes, safe detail keys, and deferred surfaces.
- `Crosswake.OperatorInspection` already projects per-route auth truth for predicated routes, including shipped contracts, evidence authority, telemetry, security closeout, denial codes, safe detail keys, and non-goals.
- `Crosswake.Doctor` already emits `auth.step_up_required_contract` findings that include Phase 55 handoff, Phase 56 step-up, Phase 57 auth-return, Phase 58 telemetry, security closeout, and deferred provider/device non-claims.
- `Crosswake.Doctor.PublishReadiness` already includes `diag.auth.sigra_session_authority` and promotion-rule details for `auth.sigra.session_authority`.
- `guides/support_matrix.md`, `guides/companions.md`, and `guides/native_shell.md` are already proof targets for public wording.

Proof:

- `.github/workflows/phase58-proof.yml` already has the desired lane split:
  - merge-blocking hermetic auth closeout proof on PR/push/selected workflow dispatch
  - advisory provider/device proof on schedule or explicit dispatch, `continue-on-error: true`
- `test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs` already locks telemetry names, secret exclusions, support truth, doctor/operator truth, guide wording, required security sections, and denial detail secret bans.
- Phase 54-57 proof baselines already cover session authority, handoff ticket replay/revocation/expiry, step-up ceremony, and OAuth/passkey/native auth-return boundaries.
- `mix closeout.verify --security-only --security-closeout ...` already validates Phase 58 security artifacts for required sections and unresolved high/critical findings.

Security artifact:

- `58-SECURITY.md` exists and has the required section set.
- Current content is terse and section-based. It satisfies the existing minimal verifier shape, but it does not yet read like the bounded adversarial STRIDE ledger required by `58-CONTEXT.md`.

Planning caveat:

- `test/crosswake/planning/closeout_ci_parity_test.exs` still targets `.github/workflows/phase52-proof.yml` and Phase 52 job names. Phase 58 planning should schedule CI parity hardening so the parity test checks `phase58-proof.yml`, `merge-blocking-auth-closeout-proof`, advisory non-promotion, `mix closeout.verify --security-only`, and the Phase 54-58 proof set.

## Recommended Plan Shape

Recommended plan breakdown:

1. **Telemetry contract lock**
   - Confirm `Sigra.Telemetry` event names match the locked `58-CONTEXT.md` list exactly.
   - Confirm metadata allowlist and forbidden metadata cover session evaluation, denial, handoff, step-up, OAuth return, passkey return, and native auth return.
   - Add or keep tests for unknown keys, forbidden keys, string keys, nil values, long values, and serialized event maps.
   - Do not emit telemetry from pure constructors. Planner should only request `execute/3` or `span` usage around real lifecycle facts if implementation needs runtime instrumentation beyond the registry.

2. **Truth surface parity**
   - Keep support matrix as the canonical source for auth contract truth.
   - Ensure doctor, publish readiness, operator inspection, rendered support matrix, and guides all distinguish:
     - full provider-neutral Sigra machinery shipped,
     - host route readiness verification required,
     - provider/device proof advisory,
     - direct shell/WebView token authority not shipped,
     - provider templates/passkey SDK/native auth UI/refresh-token helpers deferred.
   - Avoid reducing route auth posture to a boolean supported/unsupported label.

3. **Security closeout ledger**
   - Rewrite or strengthen `58-SECURITY.md` into compact STRIDE tables under the required sections.
   - Each row should include surface, STRIDE category, adversarial scenario, existing control, evidence reference, residual risk, and disposition.
   - Keep high/critical unresolved findings blocking. Medium residual uncertainty can be mitigated/advisory when it maps to provider/device non-claims.

4. **Closeout verifier and workflow parity**
   - Keep `CloseoutVerifier` minimal but ensure Phase 58 security-only invocation remains deterministic.
   - Harden CI parity tests to verify Phase 58 workflow semantics rather than Phase 52 semantics.
   - Keep advisory provider/device lane non-promotional and out of merge-blocking support truth.

5. **Proof lane finalization**
   - Run the Phase 58 workflow-equivalent tests locally where possible.
   - Include Phase 54-58 proof tests plus telemetry, support matrix, operator inspection, doctor, publish readiness, guide, and closeout verifier tests.
   - Treat Android JVM/device proof as advisory unless CI evidence and promotion criteria explicitly change.

## Validation Architecture

The validation architecture should be layered.

Hermetic merge-blocking lane:

- `mix compile --warnings-as-errors`
- `mix closeout.verify --security-only --security-closeout .planning/phases/58-auth-diagnostics-proof-and-security-closeout/58-SECURITY.md`
- Phase 54-58 proof files:
  - `phase54_sigra_session_authority_test.exs`
  - `phase55_session_handoff_tickets_test.exs`
  - `phase56_step_up_ceremony_test.exs`
  - `phase57_auth_return_boundaries_test.exs`
  - `phase58_auth_diagnostics_closeout_test.exs`
- Diagnostics parity tests:
  - `test/crosswake/companions/sigra/telemetry_test.exs`
  - `test/crosswake/support_matrix/support_matrix_test.exs`
  - `test/crosswake/operator_inspection/operator_inspection_test.exs`
  - `test/crosswake/doctor/doctor_test.exs`
  - `test/crosswake/doctor/publish_readiness_test.exs`
  - `test/crosswake/guides/companions_test.exs`
  - `test/mix/tasks/closeout_verify_test.exs`

Advisory lane:

- Provider/device OAuth, passkey, verified-link, native auth UI, refresh-token, shell/WebView token-authority posture may be reported.
- It must remain `continue-on-error` and non-promotional.
- A green advisory run must not mutate support truth into provider/device support.

Docs-contract locks should verify:

- Telemetry registry appears in guide/operator/support truth without forbidden metadata.
- `Crosswake.Companions.Sigra.DenialCodes.allowed_detail_keys/0` excludes secrets and PII.
- Public guide wording does not imply Google/Auth0/Okta support, passkey SDK support, native auth UI support, refresh-token orchestration, or shell/WebView token authority.
- Security closeout contains the required section set and no unresolved high/critical findings.

## Security/Threat Model Planning Notes

Use STRIDE as an organizing model, but keep it implementation-specific. The review should directly challenge these questions:

- Can any handoff envelope, step-up locator, auth-return envelope, deep link, bridge event, provider payload, or telemetry event directly set `SessionAuthorityLane`? Required answer: no.
- Can handoff tickets be replayed, double-consumed, redeemed after expiry, redeemed after revocation, used with the wrong route/intent/session binding, or used without audit evidence? Required control: host-owned server record plus atomic consume/audit/projection.
- Can step-up intents be consumed twice, challenged through a bypassing transport, returned to an arbitrary `return_to`, or projected without backend validation? Required control: server-owned intent lifecycle, manifest-known route target, shared Plug/LiveView ceremony semantics.
- Can OAuth/passkey/native auth-return evidence bypass backend validation of state, nonce, PKCE posture, redirect matching, link verification, challenge/origin/RP ID, expiry, or replay posture? Required control: host-owned attempt records and backend promotion only.
- Can telemetry or denial details leak tokens, authorization codes, raw nonces, PKCE verifiers, credential IDs, provider payloads, session refs, actor/org/device IDs, emails, IPs, user agents, or raw `return_to`? Required control: allowlisted low-cardinality metadata and denial detail sanitization.
- Can public wording create a support claim that is broader than proof? Required control: two-axis support truth and docs-contract proof.
- Can HTTP controller/Plug and LiveView paths diverge so one transport bypasses step-up? Required control: shared evaluator/ceremony semantics with transport-specific redirect/halt mechanics.
- Can Phoenix session renewal, CSRF rotation/deletion, or LiveView invalidation appear core-owned? Required answer: no; host owns these actions after backend validation succeeds.

Security closeout rows should cite evidence by surface/module/test name, not by long narrative. High and critical findings should block closeout unless closed or explicitly mitigated. Medium provider/device uncertainty can remain when the support matrix and guides clearly keep it advisory.

## Risks and Footguns

- **Security artifact too shallow:** The current `58-SECURITY.md` has required headings but not the adversarial ledger quality requested in `58-CONTEXT.md`.
- **CI parity drift:** Existing `closeout_ci_parity_test` is Phase-52-oriented. If not updated, Phase 58 workflow regressions can slip while tests still pass against an older workflow.
- **Telemetry overreach:** Adding provider-specific event names or high-cardinality metadata would turn telemetry into a brittle public API and increase leak risk.
- **Telemetry authority confusion:** Telemetry must not become audit, replay, lifecycle, session, or route authority.
- **Provider/device overclaims:** Provider-neutral OAuth/passkey/native seams must not read as Google/Auth0/Okta support, passkey SDK wrappers, native auth UI, verified device-link proof, or refresh-token orchestration.
- **Route truth flattening:** Operator inspection and doctor must preserve per-route auth predicates and host readiness rather than a broad "auth supported" label.
- **Secret bans by omission:** Denial and telemetry secret bans need explicit tests for authorization codes, tokens, raw nonces, PKCE verifiers, credential IDs, provider payloads, subject/session refs, emails, IPs, user agents, and raw return targets.
- **Manual-only closeout:** Human security review is necessary but not sufficient; regression guards must lock vocabulary, metadata, support truth, and non-claims.
- **Verifier false confidence:** `CloseoutVerifier` currently checks required sections and unresolved high/critical rows. It does not judge STRIDE row quality, so tests and planner acceptance criteria should require evidence-backed rows.

## File/Surface Map

Planning and research:

- `.planning/STATE.md` - Phase 57 complete; Phase 58 next.
- `.planning/ROADMAP.md` - Phase 58 goal and success criteria.
- `.planning/REQUIREMENTS.md` - DIAG-02, DIAG-03, PROOF-01.
- `.planning/phases/58-auth-diagnostics-proof-and-security-closeout/58-CONTEXT.md` - locked decisions for telemetry, truth, proof, and security closeout.
- `.planning/phases/58-auth-diagnostics-proof-and-security-closeout/58-SECURITY.md` - security closeout artifact to strengthen.
- `.planning/research/v3.8/SUMMARY.md` and `DENIAL-TELEMETRY-DX.md` - milestone-level architecture and diagnostics guidance.

Telemetry and denial:

- `lib/crosswake/companions/sigra/telemetry.ex`
- `test/crosswake/companions/sigra/telemetry_test.exs`
- `lib/crosswake/companions/sigra/denial_codes.ex`
- `test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs`

Truth surfaces:

- `lib/crosswake/support_matrix/support_matrix.ex`
- `lib/crosswake/support_matrix/renderer.ex`
- `lib/crosswake/operator_inspection.ex`
- `lib/crosswake/operator_inspection/types.ex`
- `lib/crosswake/doctor/doctor.ex`
- `lib/crosswake/doctor/publish_readiness.ex`
- `guides/companions.md`
- `guides/support_matrix.md`
- `guides/native_shell.md`

Auth proof baselines:

- `lib/crosswake/companions/sigra/contracts.ex`
- `lib/crosswake/companions/sigra/evaluator.ex`
- `lib/crosswake/companions/sigra/handoff.ex`
- `lib/crosswake/companions/sigra/step_up.ex`
- `lib/crosswake/companions/sigra/step_up_ceremony.ex`
- `lib/crosswake/companions/sigra/auth_return.ex`
- `lib/crosswake/compatibility/route_gate.ex`
- `test/crosswake/proof/phase54_sigra_session_authority_test.exs`
- `test/crosswake/proof/phase55_session_handoff_tickets_test.exs`
- `test/crosswake/proof/phase56_step_up_ceremony_test.exs`
- `test/crosswake/proof/phase57_auth_return_boundaries_test.exs`

Closeout and CI:

- `lib/crosswake/planning/closeout_verifier.ex`
- `lib/mix/tasks/closeout.verify.ex`
- `test/mix/tasks/closeout_verify_test.exs`
- `test/crosswake/planning/closeout_ci_parity_test.exs`
- `.github/workflows/phase58-proof.yml`

Prompt-corpus guardrails used:

- `prompts/crosswake-gsd-project-brief.md` - deterministic proof lanes, support matrix, doctor diagnostics, Sigra positioning.
- `prompts/crosswake-elixir-oss-dna.md` - OSS DX, named verification commands, proof lanes, security constraints.
- `prompts/crosswake-research-synthesis.md` - route-policy/runtime boundary thesis and support proof guardrails.
- `prompts/crosswake-integrations-and-companions.md` - Sigra as auth/session/mobile account boundary companion.
- `prompts/crosswake-brand-book.md` - boundary-aware language, server-authoritative wording, telemetry as part of product surface.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` - mobile auth/WebView/security footguns.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` - Phoenix-native route manifest, bridge security, telemetry, doctor, DX lessons.
- `prompts/elixir-mobile-oss-lib-deep-research.md` - stable telemetry, security allowlists, hermetic OSS CI, honest provider/device proof.

## RESEARCH COMPLETE

Phase 58 planning can proceed with a narrow closeout plan: harden the existing telemetry/support/proof/security surfaces, repair Phase 58 CI parity checks, strengthen `58-SECURITY.md` into an adversarial evidence ledger, and validate DIAG-02, DIAG-03, and PROOF-01 without expanding provider/device support claims.
