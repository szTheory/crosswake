# Phase 46: Sigra Auth Contract-Only Slice - Context

**Gathered:** 2026-05-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Define the typed Sigra auth contract surface and route-auth predicate wiring
that let Crosswake fail closed when a route needs stronger or fresher backend
auth authority.

**Delivers:**
- `Crosswake.Companions.Sigra.Contracts` or equivalent in-tree contract module
  with typed `AuthContext`, `SessionAuthorityLane`, `StepUpChallenge`, and an
  explicit evidence lane or evidence fields.
- Route-policy DSL keys `auth_min_level` and `requires_recent_auth`, carried
  into manifest `RouteEntry` truth.
- `RouteGate.evaluate/4` auth predicate checks that emit fail-closed
  `:step_up_required` denials when the backend-owned auth context is missing,
  stale, or below the route's required level.
- Doctor and support-matrix truth for auth-predicated routes and the
  contract-only Sigra surface.

**Satisfies:** AUTH-01 and AUTH-02.

**In scope:**
- Pure contract structs, closed vocabularies, constructors, and validators.
- Backend-authoritative session lane modeling.
- Device/client auth signals accepted only as evidence, never authority.
- Route-policy schema, route struct, manifest type, manifest builder, shell
  denial, and RouteGate integration for auth predicates.
- Hermetic proof tests for contract validation, authority-lane rejection, route
  policy/manifest serialization, fail-closed `:step_up_required`, and
  doctor/support truth.

**Out of scope:**
- Real Sigra optional dependency integration or adapter behavior.
- Session handoff tickets, step-up ceremony execution, OAuth/PKCE flow,
  passkeys, refresh-token rotation, or native auth UI.
- Any claim that Crosswake can perform re-auth in v3.5. This phase only
  declares the route contract and fail-closed denial surface.
- Client/device authority over auth state.

</domain>

<decisions>
## Implementation Decisions

### 1. Contract Shape - LOCKED
- **D-01:** Use layered typed contracts under `Crosswake.Companions.Sigra.Contracts`
  or an equivalent Sigra namespace. Mirror `Crosswake.Commerce.Contracts` and
  `Crosswake.Companions.Rindle.Contracts`: plain structs, closed vocabularies,
  `new_*` constructors, and `validate_* :: :ok | {:error, keyword()}`.
- **D-02:** Do not use Ecto schemas or changesets for the core contract. Ecto is
  idiomatic for persistence and form validation, but this seam is a pure runtime
  contract layer and should stay dependency-light and consistent with existing
  Crosswake contracts.
- **D-03:** Recommended public structs:
  - `AuthContext` - backend-projected auth context for route evaluation.
  - `SessionAuthorityLane` - backend-set authority state and freshness.
  - `StepUpChallenge` - structured challenge requirement/reference, not an
    executable ceremony.
  - `EvidenceLane` or explicit evidence fields - device/client observations
    that may inform backend projection but cannot set authority.
- **D-04:** `AuthContext` must carry at minimum `actor_id`, `org_id`,
  `mfa_level`, and `auth_age` as required by the roadmap. Planner may add
  `session_id`, `issued_at`, `authenticated_at`, `authority`, `evidence`, and
  `as_of` when they make the backend/evidence split clearer.
- **D-05:** Keep vocabularies closed and boring. Recommended `mfa_level` order:
  `:none | :password | :mfa | :phishing_resistant`. Planner may choose exact
  names, but ordering must be mechanically comparable for `auth_min_level`.
- **D-06:** `auth_age` should normalize to seconds for route evaluation.
  Accepting an age struct/map is planner discretion, but the route predicate
  should compare a numeric `auth_age_seconds` against a numeric
  `requires_recent_auth` limit.
- **D-07:** `StepUpChallenge` is contract state only. It may carry
  `challenge_id`, `required_mfa_level`, `max_auth_age_seconds`, `reason`, and
  `issued_at` or `expires_at`; it must not imply that Crosswake can create,
  run, complete, or verify the step-up flow in v3.5.

### 2. Authority And Evidence Boundary - LOCKED
- **D-08:** `SessionAuthorityLane` is backend-set only. Device/client auth
  observations can be evidence, but cannot directly set `mfa_level`, session
  authority, freshness, or access decision.
- **D-09:** Validators must reject evidence payloads that attempt to carry
  authority fields such as `authority_state`, `mfa_level`, `auth_level`,
  `session_authority`, or `access_granted`, following the Rindle
  `reject_trace_authority_lane/2` pattern.
- **D-10:** Missing or invalid backend auth context fails closed for routes with
  auth predicates. No route with `auth_min_level` or `requires_recent_auth`
  should silently pass when the auth context is absent.
- **D-11:** Device/native auth signals are trace/evidence for a future backend
  projection. They are not route activation authority and must not be accepted
  as a substitute for backend session authority.

### 3. Route Predicate Semantics - LOCKED
- **D-12:** Add route-policy DSL keys `auth_min_level` and
  `requires_recent_auth`. They are route-local policy declarations, not
  companion-private configuration.
- **D-13:** `auth_min_level` validates against the closed MFA/auth-level
  vocabulary. `requires_recent_auth` validates as a positive integer number of
  seconds or a tightly normalized duration form chosen by the planner.
- **D-14:** Carry both predicates into `Crosswake.Policy.Route`,
  `Crosswake.Manifest.Types.RouteEntry`, manifest serialization, and checked-in
  shell fixture manifests as part of manifest truth.
- **D-15:** Evaluate auth predicates in `RouteGate.evaluate/4` using a typed,
  backend-owned auth context passed in `opts`, e.g. `auth_context:
  %AuthContext{}`. Exact option key is planner discretion, but it must be
  explicit and test-covered.
- **D-16:** Evaluation order should be:
  1. kill-switch denials
  2. companion gate denials
  3. auth predicate denials
  4. existing compatibility and commerce findings

  This preserves security-first fail-closed behavior while keeping auth denial
  more specific than generic compatibility failures.
- **D-17:** Route auth predicates can only further restrict activation. They
  cannot open a route that policy, compatibility, commerce, pack, capability, or
  companion checks already denied.
- **D-18:** RouteGate should emit exactly `:step_up_required` for unmet auth
  predicates. Do not reuse `:gate_denied`, `:unavailable_capability`, or
  commerce denial vocabulary for auth.

### 4. Step-Up Denial Payload - LOCKED
- **D-19:** Add `:step_up_required` as a first-class
  `Crosswake.Shell.Denial` reason and code.
- **D-20:** The denial details should be minimal, typed, and non-sensitive:
  `required_mfa_level`, `current_mfa_level`, `max_auth_age_seconds`,
  `auth_age_seconds`, `evaluated_at`, and optional `challenge_ref` or
  `step_up_token_ref` when supplied by backend contract state.
- **D-21:** Do not include raw session tokens, bearer tokens, passkey material,
  OAuth artifacts, PII-heavy actor metadata, or unredacted provider payloads in
  denial details, doctor output, support matrix output, or fixtures.
- **D-22:** Denial copy should say that step-up is required, not that Crosswake
  can perform it. Recovery metadata may point to future/host-owned step-up
  guidance but must not imply v3.5 shipped handoff or passkey machinery.

### 5. Doctor, Support Matrix, And Proof - LOCKED
- **D-23:** Add a dedicated auth doctor category for routes with auth
  predicates. At minimum, emit an advisory finding per predicated route with
  exact route id, `auth_min_level`, and `requires_recent_auth`.
- **D-24:** Recommended doctor codes:
  - `auth.route_predicated` - route declares auth predicates.
  - `auth.step_up_required_contract` - auth predicates are evaluated as a
    contract-only fail-closed route gate.
  - `auth.unsupported_machinery` or equivalent - explicit non-goal signal when
    output/documentation needs to distinguish contract truth from full Sigra
    machinery.
- **D-25:** Add support-matrix truth for the Sigra auth contract surface without
  claiming full auth machinery. Recommended shape is an
  `auth_contract_truth/0` row family or equivalent canonical function with
  owner `backend_seam`, package class `companion`, proof class
  `merge_blocking`, and fallback `:step_up_required`.
- **D-26:** Do not add a full `auth_summary` runtime surface in Phase 46.
  Borrow its strict non-goal labeling for docs/proof, but avoid designing
  operational machinery before v3.6.
- **D-27:** Phase 46 proof should be hermetic and core-only. Required assertions:
  contract constructors/validators work; evidence cannot set authority;
  route-policy DSL accepts valid predicates and rejects invalid ones; manifest
  entries serialize predicates; `RouteGate.evaluate/4` fails closed with
  `:step_up_required` when auth is absent, too weak, or stale; doctor/support
  truth lists auth-predicated routes.
- **D-28:** Phase 47 docs-contract tests should lock exact vocabulary across
  guide, doctor, support matrix, and code: `auth_min_level`,
  `requires_recent_auth`, `:step_up_required`, `AuthContext`,
  `SessionAuthorityLane`, and the explicit non-goals.

### 6. Ecosystem Lessons To Preserve - LOCKED
- **D-29:** Import the Phoenix/Plug lesson: auth gates should be explicit,
  deterministic, and halt/fail closed when requirements are unmet. Crosswake
  should keep that shape, but express it in route-policy/manifest truth so shell
  activation gets the same contract.
- **D-30:** Import the phx.gen.auth/Phoenix session lesson: server-side session
  authority is the durable truth; client session material is a lookup/transport
  handle, not independent authority.
- **D-31:** Import the Guardian/JWT ecosystem lesson: bearer/token presence is
  not enough for high-risk route activation. Route requirements must check
  level and recency, not only whether any user exists.
- **D-32:** Import OAuth native-app guidance: future machinery should use
  external-user-agent/PKCE style separation and must not put credentials into an
  embedded WebView or bridge channel. Phase 46 should only leave contract hooks
  for that future work.
- **D-33:** Import the Auth0/Lucid-style mobile refresh lesson from milestone
  research: future token refresh/rotation needs grace-window design to avoid
  false positives on background/resume. Do not build that in Phase 46, but avoid
  contract names that would preclude it.
- **D-34:** Import OWASP step-up/re-auth guidance at the level of vocabulary:
  high-risk routes may require stronger or fresher authentication, but the
  machinery must be carefully designed and not smuggled into this slice.

### the agent's Discretion
- Exact module names under `Crosswake.Companions.Sigra` are planner discretion
  if the layered contract responsibilities remain explicit.
- Exact auth-level vocabulary names are planner discretion if ordering is
  closed, documented, and mechanically comparable.
- Exact `requires_recent_auth` input syntax is planner discretion. Bias toward
  integer seconds for least surprise in manifest JSON.
- Exact doctor code names may be refined, but they must remain stable,
  auth-specific, and docs-contractable.
- Exact proof file names are planner discretion. Strong default:
  `test/crosswake/companions/sigra/contracts_test.exs` plus
  `test/crosswake/proof/phase46_sigra_auth_contract_test.exs`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` section "Phase 46: Sigra Auth Contract-Only Slice" -
  authoritative goal and success criteria.
- `.planning/REQUIREMENTS.md` section "AUTH - Sigra Auth Contract
  (contract-only slice)" - AUTH-01 and AUTH-02.
- `.planning/ROADMAP.md` section "Phase 47: Companion Arc Guide And Milestone
  Proof" - docs-contract and milestone-proof handoff.
- `.planning/PROJECT.md` - Crosswake thesis, v3.5 scope, companion guardrails,
  and deferred Sigra machinery.
- `.planning/MILESTONE-ARC.md` - contracts-first guardrails and companion
  classification.
- `.planning/research/v3.5-companions-SUMMARY.md` - Sigra contract-only
  research, security footguns, and v3.6 sequencing.

### Existing Crosswake contract precedents
- `lib/crosswake/commerce/contracts.ex` - typed struct, lane, vocabulary, and
  validator style to mirror.
- `lib/crosswake/commerce/reconciliation.ex` - evidence-vs-authority precedent
  for backend-owned state transitions.
- `lib/crosswake/companions/rindle/contracts.ex` - newest companion contract
  style, including authority-lane rejection from trace/evidence metadata.
- `lib/crosswake/companions/rindle/reconciliation.ex` - evidence-only ingestion
  and mutation-fence precedent.
- `test/crosswake/commerce/contracts_test.exs` - contract test shape.
- `test/crosswake/companions/rindle/contracts_test.exs` - companion contract
  test shape.

### Route policy and RouteGate integration points
- `lib/crosswake/policy/schema.ex` - add DSL validation for `auth_min_level`
  and `requires_recent_auth`.
- `lib/crosswake/policy/route.ex` - normalized route struct and cross-field
  validation target.
- `lib/crosswake/manifest/types.ex` - `RouteEntry` manifest type target.
- `lib/crosswake/manifest/builder.ex` - route policy to manifest serialization
  target and capability catalog support target.
- `lib/crosswake/manifest/serializer.ex` - deterministic manifest JSON output.
- `lib/crosswake/compatibility/route_gate.ex` - fail-closed route activation
  decision pipeline and denial ordering target.
- `lib/crosswake/shell/denial.ex` - add `:step_up_required` denial reason.
- `test/crosswake/proof/phase40_gate_evaluation_test.exs` - RouteGate proof
  style and ordering precedent.
- `test/crosswake/policy/schema_test.exs` and
  `test/crosswake/policy/route_test.exs` - route-policy validation test style.

### Doctor, support matrix, and docs-contract targets
- `lib/crosswake/doctor/doctor.ex` - add auth doctor findings after manifest
  compilation.
- `lib/crosswake/doctor/formatter.ex` - human output parity target if auth gets
  formatted sections.
- `lib/crosswake/doctor/json_formatter.ex` - JSON output parity target.
- `lib/crosswake/support_matrix/support_matrix.ex` - add auth contract truth
  canonical function/row.
- `test/crosswake/doctor/doctor_test.exs` - doctor output and JSON parity test
  style.
- `test/crosswake/proof/phase41_gating_doctor_test.exs` - closest doctor and
  support-matrix proof precedent for route-local predicate visibility.
- `guides/companions.md` - Phase 47 expansion target for Sigra docs.
- `test/crosswake/guides/companions_test.exs` - docs-contract anchor target.

### Prompt research and project-specific constraints
- `prompts/crosswake-elixir-oss-dna.md` - install truth, support matrices,
  proof lanes, and narrow public entrypoints.
- `prompts/crosswake-integrations-and-companions.md` - companion classification
  and first-party integration posture.
- `prompts/crosswake-research-synthesis.md` - route ownership and bounded
  bridge thesis.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` -
  route-policy and runtime ownership pressure.
- `prompts/elixir-mobile-oss-lib-deep-research.md` - bridge/security footguns,
  support matrices, and library DX lessons.
- `prompts/elixir-mobile-offlinesupport-stresstest-deep-research.md` and
  `prompts/elixir-mobile-offlinesupport-flashcard-app-stresstest-deep-research.md`
  - client evidence vs backend authority and offline-claim constraints.

### External ecosystem references used for decision calibration
- `https://hexdocs.pm/phoenix/authn_authz.html` - Phoenix auth/authz guidance
  and server-owned auth posture.
- `https://hexdocs.pm/phoenix/Mix.Tasks.Phx.Gen.Auth.html` - Phoenix generated
  auth precedent for explicit server-side session handling.
- `https://hexdocs.pm/Phoenix.Router.html` - route pipelines and explicit
  routing/policy posture.
- `https://hexdocs.pm/plug/Plug.Conn.html#configure_session/2` - Plug session
  renewal/configuration semantics relevant to future step-up/session rotation.
- `https://hexdocs.pm/guardian/Guardian.Plug.EnsureAuthenticated.html` -
  ecosystem precedent for explicit auth plugs that halt when requirements are
  unmet.
- `https://www.rfc-editor.org/rfc/rfc8252` - OAuth 2.0 for Native Apps; informs
  deferred v3.6 native auth machinery and external-user-agent separation.
- `https://www.rfc-editor.org/rfc/rfc9700` - OAuth 2.0 Security Best Current
  Practice; informs future machinery constraints.
- `https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html`
  - re-auth/step-up vocabulary and security posture.
- `https://cheatsheetseries.owasp.org/cheatsheets/OAuth2_Cheat_Sheet.html` -
  OAuth security posture for future Sigra machinery.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Commerce.Contracts` - closest pattern for layered lane structs,
  closed vocabularies, and validator functions.
- `Crosswake.Companions.Rindle.Contracts` - newest companion contract module and
  direct model for rejecting authority fields from evidence/trace metadata.
- `Crosswake.Compatibility.RouteGate` - existing fail-closed activation
  pipeline where auth predicate denials should be inserted.
- `Crosswake.Shell.Denial` - stable shell denial envelope to extend with
  `:step_up_required`.
- `Crosswake.Policy.Schema` and `Crosswake.Policy.Route` - route-local DSL
  validation and normalized policy struct surfaces.
- `Crosswake.Manifest.Types.RouteEntry` and `Crosswake.Manifest.Builder` -
  manifest truth surfaces that should carry auth predicates.
- `Crosswake.Doctor` and `Crosswake.SupportMatrix` - canonical product truth
  surfaces for route diagnostics and support claims.

### Established Patterns
- Crosswake contracts use plain structs and explicit validators rather than
  Ecto schemas at the core seam boundary.
- Evidence can feed backend reconciliation/projection, but cannot mutate
  authority directly.
- Route policy is the canonical declaration surface; companion/auth inputs can
  further restrict a route but not open it.
- `RouteGate` prepends specialized fail-closed denial classes before generic
  compatibility findings.
- Doctor/support-matrix/docs-contract parity is part of the product, especially
  for newly claimed surfaces.
- Hermetic merge-blocking proof is the default for contract truth; advisory
  lanes are reserved for optional dependencies or environment-sensitive
  provider/device machinery.

### Integration Points
- `lib/crosswake/companions/sigra/contracts.ex` - likely new contract module.
- `lib/crosswake/policy/schema.ex` - add `auth_min_level` and
  `requires_recent_auth` schema entries and validators.
- `lib/crosswake/policy/route.ex` - add fields and route validation.
- `lib/crosswake/manifest/types.ex` - add route entry fields and serialization
  support via existing type mapping.
- `lib/crosswake/manifest/builder.ex` - copy route predicates into manifest and
  likely add auth-related support capability metadata.
- `lib/crosswake/compatibility/route_gate.ex` - add auth predicate evaluation
  after gate checks and before compatibility/commerce findings.
- `lib/crosswake/shell/denial.ex` - add `:step_up_required` to reason
  vocabulary and type.
- `lib/crosswake/doctor/doctor.ex` - add auth route diagnostics.
- `lib/crosswake/support_matrix/support_matrix.ex` - add Sigra auth contract
  truth function/row.
- `test/crosswake/proof/` and `test/crosswake/companions/sigra/` - Phase 46
  proof tests.
- `examples/ios_shell_host/Fixtures/crosswake_manifest.json` and
  `examples/android_shell_host/app/src/main/assets/crosswake_manifest.json` -
  checked-in fixture manifests may need predicate fields once manifest shape
  changes.

</code_context>

<specifics>
## Specific Ideas

- The approved recommendation is one cohesive direction across all three
  researched gray areas:
  1. layered typed contracts,
  2. route-local predicates in policy/manifest,
  3. fail-closed `:step_up_required` in RouteGate,
  4. doctor/support truth that says contract-only, not full machinery.
- Preferred phrase to preserve in docs/proof copy: device/client auth signals
  are evidence, never session authority.
- Preferred phrase to preserve for scope control: Phase 46 ships step-up
  requirement truth, not step-up ceremony.
- The research explicitly rejected:
  - flattened auth context mixing authority and evidence,
  - Ecto changesets as the core seam API,
  - companion-private auth policy outside route policy,
  - Phoenix/Plug-only auth gating outside RouteGate,
  - full `auth_summary` runtime machinery in this phase.

</specifics>

<deferred>
## Deferred Ideas

- Real `Crosswake.Companions.Sigra` optional dependency validation/advisory lane
  if and when the external Sigra library is integrated.
- Session handoff tickets.
- Step-up ceremony execution and UX.
- Native passkey escape hatch.
- OAuth Auth-Code + PKCE implementation details.
- Refresh-token rotation and mobile background/resume grace-window handling.
- Chimeway auth-aware deep-link routing and push-token lifecycle, which depends
  on this contract.
- Threadline audit/provenance capstone consuming stable auth/media/gating
  contract decisions.

</deferred>

---

*Phase: 46-sigra-auth-contract-only-slice*
*Context gathered: 2026-05-31*
