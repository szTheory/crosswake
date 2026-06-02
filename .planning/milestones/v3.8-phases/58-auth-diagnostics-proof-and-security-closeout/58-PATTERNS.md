# Phase 58 Pattern Map

## Closest Analogs

- `lib/crosswake/companions/sigra/telemetry.ex` is the canonical registry pattern for Phase 58: module-level locked lists, small accessor functions, strict event validation, sanitizer-first metadata, and `:telemetry.execute/3` wrapping only safe metadata.
- `lib/crosswake/companions/sigra/denial_codes.ex` is the closest sanitizer analog: canonical vocabulary, low-cardinality allowed detail keys, explicit safe reference regex, and silent dropping of unsafe or unknown values.
- `lib/crosswake/support_matrix/support_matrix.ex` is the source-of-truth analog for support claims. Reuse its `auth_contract_truth/0` shape instead of inventing per-surface truth: `contract_surface`, `contract_proof_class`, `route_authority_source`, `host_readiness`, `provider_device_proof`, `telemetry`, `security_closeout`, `evidence_authority`, `deferred`.
- `lib/crosswake/operator_inspection.ex` is the projection analog: route-local auth truth is copied from support matrix into inspection output only for predicated routes, preserving `:verification_required` host readiness and advisory provider/device proof.
- `lib/crosswake/doctor/doctor.ex` and `lib/crosswake/doctor/publish_readiness.ex` are diagnostic wording analogs: findings carry compact human messages plus structured details, and publish readiness treats auth route readiness as verification-required/advisory rather than provider/device support.
- `lib/crosswake/planning/closeout_verifier.ex` is the verifier analog: deterministic presence/section/status checks, merge-blocking failures, no editorial judgment. Phase 58 should add only bounded machine-checkable guarantees here.
- `.github/workflows/phase58-proof.yml` is the proof-lane analog: hermetic merge-blocking auth closeout proof on PR/push/manual merge-blocking dispatch; provider/device lane is scheduled/manual, `continue-on-error`, and non-promoting.
- `test/crosswake/proof/phase54_sigra_session_authority_test.exs`, `phase55_session_handoff_tickets_test.exs`, `phase56_step_up_ceremony_test.exs`, and `phase57_auth_return_boundaries_test.exs` are the prior-layer proof analogs. Phase 58 should compose them rather than restating all lower-level behavior.
- `test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs` is the primary closeout proof analog: lock registry names, secret exclusions, support truth, doctor/operator truth, guide wording, security section presence, and denial-detail bans in one docs-contract proof.
- `test/crosswake/companions/sigra/telemetry_test.exs` is the targeted unit proof analog for event registry, sanitizer behavior, and serialization.
- `test/mix/tasks/closeout_verify_test.exs` is the CLI proof analog for `mix closeout.verify --security-only --security-closeout ...`.
- `test/crosswake/planning/closeout_ci_parity_test.exs` is the drift warning analog, but it is still Phase-52-oriented and should be rewritten to inspect `.github/workflows/phase58-proof.yml`.
- `guides/companions.md`, `guides/support_matrix.md`, and `guides/native_shell.md` are docs-contract analogs: public wording must preserve shipped provider-neutral Sigra machinery while keeping provider/device auth proof, passkey SDK wrappers, native auth UI, refresh-token helpers, and direct shell/WebView token authority deferred.
- `.planning/phases/58-auth-diagnostics-proof-and-security-closeout/58-SECURITY.md` is the closeout artifact target. It already has required sections; the closest planned pattern is a compact STRIDE ledger with evidence refs and findings disposition.

## Planned File Roles

- `lib/crosswake/companions/sigra/telemetry.ex`: keep as the only auth telemetry registry. Reuse existing `@event_names`, `@metadata_keys`, `@forbidden_metadata_keys`, registry accessors, `metadata/1`, `to_map/1`, and `execute/3` patterns. Do not add provider-specific events or authority semantics.
- `test/crosswake/companions/sigra/telemetry_test.exs`: keep as focused sanitizer/serialization proof. Add cases only for concrete gaps: unknown keys, forbidden string keys, nil values, long strings, and safe correlation ids.
- `lib/crosswake/support_matrix/support_matrix.ex`: keep `auth_contract_truth/0` as canonical support truth. Any Phase 58 wording or field additions should be sourced here first, then projected into doctor, publish readiness, operator inspection, renderer, and guides.
- `lib/crosswake/support_matrix/renderer.ex` and `guides/support_matrix.md`: reuse rendered matrix language that separates `contract_proof_class: :merge_blocking` from `host_readiness: :verification_required` and `provider_device_proof: :advisory`.
- `lib/crosswake/doctor/doctor.ex`: preserve `auth.route_predicated` plus `auth.step_up_required_contract` pattern. Messages should remain actionable and safe; structured details should continue to carry telemetry/security closeout fields from support truth.
- `lib/crosswake/doctor/publish_readiness.ex`: preserve `diag.auth.sigra_session_authority` pattern. Result may be `:verification_required` for inspected auth routes, but must not promote provider/device support.
- `lib/crosswake/operator_inspection.ex` and `lib/crosswake/operator_inspection/types.ex`: keep route-auth projection per route. Reuse `auth_entry/1` pattern: predicated routes get full Sigra truth; non-predicated routes stay `:not_applicable` or empty.
- `lib/crosswake/planning/closeout_verifier.ex`: keep deterministic and narrow. Reuse `security_closeout_check/1` required-section and unresolved high/critical pattern; avoid free-form STRIDE quality scoring unless it can be expressed as stable structural checks.
- `.planning/phases/58-auth-diagnostics-proof-and-security-closeout/58-SECURITY.md`: strengthen content, not mechanics. Use required headings and compact rows with surface, STRIDE category, adversarial scenario, existing control, evidence refs, residual risk, and disposition.
- `.github/workflows/phase58-proof.yml`: keep the existing two-lane structure. Merge-blocking lane runs compile, security closeout verify, Phase 54-58 proof tests, and diagnostics parity tests. Advisory lane reports provider/device posture only.
- `test/crosswake/planning/closeout_ci_parity_test.exs`: planned hardening target. Rewrite from Phase 52 workflow/job assertions to Phase 58 assertions: workflow path, `merge-blocking-auth-closeout-proof`, `mix closeout.verify --security-only`, Phase 54-58 proof set, `advisory-auth-provider-device-proof`, and `continue-on-error: true`.
- `test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs`: keep as top-level DIAG-02/DIAG-03/PROOF-01 proof. Add assertions for parity drift only when they protect public claims or secret bans.
- `guides/companions.md`, `guides/support_matrix.md`, `guides/native_shell.md`: reuse one consistent two-axis wording: full provider-neutral Sigra contract machinery is shipped and merge-blocking proven; host route readiness requires verification; provider/device proof remains advisory.

## Data Flow

1. Route manifests declare auth predicates (`auth_min_level`, `requires_recent_auth`, `auth_posture`) and route-local auth-return seams.
2. `Crosswake.Companions.Sigra.Evaluator` and `Crosswake.Compatibility.RouteGate` evaluate backend-owned `SessionAuthorityLane` facts and fail closed with public `:step_up_required` when predicates are not satisfied.
3. Handoff, step-up, and auth-return modules produce typed envelopes or locators, but host-owned records remain authoritative for replay, expiry, revocation, binding, audit, session-renewal instructions, CSRF posture, LiveView invalidation posture, and projection.
4. `Crosswake.Companions.Sigra.DenialCodes` turns rich denial facts into canonical subcodes plus safe detail maps; `Crosswake.Shell.Denial` keeps public shell reasons compact.
5. `Crosswake.Companions.Sigra.Telemetry` emits or serializes diagnostic evidence with stable event names and allowlisted metadata only. Telemetry never feeds route authority, session authority, audit, replay, lifecycle, or support promotion.
6. `Crosswake.SupportMatrix.auth_contract_truth/0` centralizes support truth, including telemetry registry, security closeout posture, evidence-authority map, proof class, host readiness, advisory provider/device proof, deferred surfaces, denial codes, and safe detail keys.
7. Doctor, publish readiness, operator inspection, renderer, and guides project support-matrix truth outward. They should not independently decide shipped auth support.
8. Closeout verifier and proof tests sample the same surfaces to prevent drift between code, docs, workflow, and security artifact.

## Test/Proof Patterns

- Registry proof: assert exact `[:crosswake, :auth, ...]` event list, metadata allowlist, forbidden metadata list, and `to_map/1` serialization with no nil or forbidden fields.
- Sanitizer proof: feed secret/high-cardinality/unknown fields into telemetry metadata and denial detail sanitizers; assert only low-cardinality allowlisted fields survive.
- Truth parity proof: assert `SupportMatrix.auth_contract_truth/0` exposes full Sigra machinery, merge-blocking contract proof, backend session-authority source, host verification requirement, advisory provider/device proof, shipped telemetry, shipped security closeout, false evidence-authority entries, and deferred provider/native surfaces.
- Projection proof: use an auth-predicated test router and assert doctor findings, publish readiness, and operator inspection all expose Phase 58 telemetry/security closeout while preserving `:step_up_required` and host verification-required posture.
- Docs-contract proof: read guides directly and assert required phrases are present while provider/device overclaims and direct shell/WebView token authority claims are absent.
- Security closeout proof: run `mix closeout.verify --security-only --security-closeout .planning/phases/58-auth-diagnostics-proof-and-security-closeout/58-SECURITY.md`; assert required sections exist and unresolved High/Critical findings block.
- Workflow parity proof: inspect `.github/workflows/phase58-proof.yml` as source text. Assert merge-blocking lane includes compile, security-only closeout verify, Phase 54-58 proof tests, and diagnostics parity tests; assert advisory lane is manual/scheduled, `continue-on-error: true`, and contains non-promotional wording.
- Regression proof: run Phase 54-57 proof files with Phase 58 proof to preserve layered auth behavior instead of duplicating lower-level assertions in Phase 58 tests.

## Planner Notes

- Keep Phase 58 implementation-planning narrow: harden inspectability, docs truth, proof, workflow parity, and security closeout. Do not add provider OAuth templates, passkey SDK wrappers, native auth UI, refresh-token helpers, or direct shell/WebView token authority.
- Treat `SupportMatrix.auth_contract_truth/0` as the canonical public-support source. If wording diverges, fix the canonical row or its projection rather than patching each consumer independently.
- Treat telemetry and bridge/native/provider return facts as evidence only. Any plan that lets telemetry, envelopes, locators, deep links, bridge events, or provider payloads set `SessionAuthorityLane` directly violates the phase.
- Strengthen `58-SECURITY.md` into an adversarial ledger, but keep it bounded. Rows should cite modules/tests/artifacts and make residual risk explicit; unresolved High/Critical findings block closeout.
- Keep provider/device proof advisory until explicit roadmap/requirements promotion, shipped provider/device implementation, sustained evidence, support-matrix/docs updates, and branch-protection/workflow changes all exist.
- The main known drift target is `test/crosswake/planning/closeout_ci_parity_test.exs`, which still points at Phase 52. Plan a small source-text parity rewrite rather than broader workflow refactoring.
- Avoid adding broad verifier intelligence. `CloseoutVerifier` should remain deterministic and stable; use tests and acceptance criteria for editorial/security-quality expectations.

## PATTERN MAPPING COMPLETE

Phase 58 should reuse the existing Sigra registry, support-truth projection, closeout verifier, and layered proof patterns. The planned work is mostly parity hardening plus a stronger security ledger, with provider/device proof explicitly kept non-promotional.
