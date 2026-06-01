# Phase 51: Support Matrix and Native Rebuild Truth - Context

**Gathered:** 2026-06-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Make Crosswake's public support truth match the widened v3.6 operator surface.

**Delivers:**
- A support-matrix contract that distinguishes support status, proof class,
  diagnostic severity, rebuild/action requirements, and derived conditions
  without collapsing them into one misleading readiness state.
- Native rebuild and adopter/operator action truth for native shell,
  companion-native, provider adapter, route/manifest, compatibility, and
  docs-only changes.
- Public guidance that explains advisory-to-merge-blocking promotion criteria,
  rebuild requirements, rough edges, and explicit non-claims.
- Support truth that remains coherent with Phase 49 `mix crosswake.inspect` and
  Phase 50 `mix crosswake.doctor --check-publish`.

**Satisfies:** SUPP-01 and SUPP-02.

**In scope:**
- Expand `Crosswake.SupportMatrix` as the canonical vocabulary source for
  support, proof, rebuild/change/action, promotion, deferred scopes, and guide
  anchors.
- Render the support matrix guide from canonical truth rather than prose-only
  tables.
- Feed support/rebuild/promotion truth through operator inspection and doctor
  readiness where Phase 51 needs hooks.
- Document native rebuild requirements and advisory promotion criteria clearly.

**Out of scope:**
- StoreKit or Play Billing adapter implementation.
- Full Sigra handoff, ceremony, passkey, OAuth, refresh-token, or native auth UI
  machinery.
- Chimeway delivery integration, notification-open routing, or push delivery
  proof.
- Standalone public shell packages.
- Phase 52 full proof/docs-contract lane, except focused tests needed to make
  Phase 51 truth credible.

</domain>

<decisions>
## Implementation Decisions

### 1. Support Vocabulary - LOCKED
- **D-01:** Keep split canonical axes. Do not introduce one global
  `ready | degraded | blocked | deferred` lifecycle status as canonical support
  truth.
- **D-02:** Preserve these axes as independent machine-visible concepts:
  support status, proof class, diagnostic severity, rebuild/change/action
  requirement, denial reason, claim scope, and derived condition status.
- **D-03:** Support status remains narrow:
  `supported | verification_required | unsupported`.
- **D-04:** Proof class remains separate from support status:
  `merge_blocking | advisory | not_applicable` where needed for readiness
  checks.
- **D-05:** Diagnostic severity remains separate from both support and proof:
  `error | warning | advisory`. Severity is triage urgency, not a support claim.
- **D-06:** Operator conditions may exist only as derived wrappers over the raw
  axes. They are useful for CI/support querying, but they must never become a
  second source of truth.
- **D-07:** Internal Elixir should use closed atoms/structs where the codebase
  already does. JSON and rendered docs must expose stable string labels.
- **D-08:** Public docs must not invent synonyms such as "healthy",
  "production-ready", "green", or "degraded" unless they are explicitly derived
  human prose and the raw axes remain adjacent.

### 2. Rebuild And Actionability - LOCKED
- **D-09:** Use a two-axis rebuild contract: `change_class` answers what
  changed, and `action_class` answers who must do what before the claim is safe.
- **D-10:** Keep current change classes as machine-stable labels unless the
  planner finds an unavoidable naming gap:
  `docs-only`, `core-only/no native rebuild`, `compatibility-bump only`, and
  `native or companion rebuild required`.
- **D-11:** Add explicit action classes or equivalent machine fields for these
  subjects:
  `native_shell`, `companion_native`, `provider_adapter`, `route_manifest`,
  `compatibility`, and `docs_only`.
- **D-12:** Route-derived rebuild truth is necessary but insufficient. Phase 51
  must also cover non-route release surfaces: shell templates, native
  dependencies, entitlements/permissions, companion-native code, provider SDKs,
  compatibility windows, and docs-only support claims.
- **D-13:** A route/manifest or Phoenix-owned change can be core-only when
  compatibility axes and capability majors stay in range. Native code,
  generated shell projects, entitlements, permissions, platform config,
  provider SDKs, and companion-native integration require native or companion
  rebuild truth.
- **D-14:** Compatibility-window narrowing must be distinct from native rebuild:
  it may fail closed for unsupported combinations without requiring every
  already-compatible adopter to rebuild.
- **D-15:** Human guidance should answer "Do I need to rebuild?" directly, but
  machine output must expose the underlying subject, change class, action class,
  compatibility signal, required proof, and reasons.

### 3. Promotion And Advisory Proof - LOCKED
- **D-16:** Use criteria-as-code promotion rules for any support claim that can
  move from advisory/verification-required to merge-blocking/supported.
- **D-17:** A promotion rule should include at least: `claim_id`, evidence class,
  required evidence set, minimum consecutive passes or equivalent repeatability
  threshold, freshness window, failure budget, required platforms/providers,
  required docs anchors, rebuild class, check ids, and demotion trigger.
- **D-18:** Environment-sensitive proof remains advisory until its promotion
  rule is satisfied. Provider, storefront, simulator, physical-device, and
  delivery proof must not become merge-blocking by implication.
- **D-19:** Promotion and demotion must be auditable. If a formerly
  merge-blocking lane becomes flaky, stale, or unsupported by current
  compatibility windows, the rule should define how it falls back to advisory or
  verification-required.
- **D-20:** Examples in docs should use contract-shaped examples, such as a
  future `purchase_intent.provider.storekit` claim promoting only after named
  StoreKit lanes, docs/support/doctor parity, rebuild guidance, and changelog
  truth are all present.
- **D-21:** Do not use governance-only checklists as the primary promotion
  mechanism. Human review can approve intent, but machine-readable criteria must
  carry the support claim.

### 4. Public Non-Claims And Rough Edges - LOCKED
- **D-22:** Public guidance must explicitly state that StoreKit and Play Billing
  adapters are not shipped in v3.6.
- **D-23:** Public guidance must explicitly state that Sigra remains
  contract-only for route predicates and `:step_up_required`; full handoff,
  ceremony, passkey, OAuth, refresh-token, and native auth UI are deferred.
- **D-24:** Public guidance must explicitly state that notification-token
  readiness is provider-snapshot readiness only; Chimeway delivery,
  notification-open routing, and push delivery guarantees are deferred.
- **D-25:** Public guidance must explicitly state that standalone public shell
  packages are deferred until the production shell runtime-line milestone.
- **D-26:** Advisory proof must remain visible in support matrix, doctor
  readiness, and operator inspection. It must not be rendered as supported by
  omission.
- **D-27:** Missing readiness must never silently pass as supported. A missing
  row, missing promotion rule, missing docs anchor, or missing rebuild reason
  should produce a warning/error/advisory finding according to the risk.

### 5. Ecosystem Lessons To Preserve - LOCKED
- **D-28:** Import the Phoenix/Plug/Ecto lesson: explicit structs, closed
  vocabularies, deterministic validation, and fail-closed contracts are better
  DX than magical inference.
- **D-29:** Import the Django checks lesson: stable ids, severity, hints, object
  references, and docs links make diagnostics actionable.
- **D-30:** Import the Terraform lesson: human output and versioned JSON serve
  different users. Human wording is not an API.
- **D-31:** Import the Kubernetes lesson carefully: condition-like records help
  operators, but a boolean condition or single health field must not hide raw
  support/proof/rebuild/provider/auth/notification truth.
- **D-32:** Import the npm audit lesson: thresholding is useful, but severity is
  not support truth and noisy advisory failures erode trust.
- **D-33:** Import the Expo/React Native lesson: native runtime compatibility
  boundaries must be explicit before any OTA-like or package-only update can be
  treated as safe.
- **D-34:** Import the Capacitor and mobile SDK lesson: native permissions,
  entitlements, platform config, and SDK dependencies create rebuild-sensitive
  support surfaces even when the Phoenix route code did not change.
- **D-35:** Import the Hotwire Native lesson: path/route config, bridge
  components, and native screens are separate mechanisms; support docs should
  not imply generic fallback behavior across those boundaries.

### the agent's Discretion
- Exact struct/module names are planner discretion. Strong default: extend
  `Crosswake.SupportMatrix` with typed rows/accessors instead of introducing an
  unrelated policy module.
- Exact `action_class` names are planner discretion if the subject/action split
  remains machine-visible and docs-rendered.
- Exact promotion thresholds are planner discretion per claim, but thresholds
  must be explicit and conservative. Prefer no promotion over weak promotion.
- Exact guide layout is planner discretion. Bias toward generated tables plus
  short explanatory prose and anchored examples.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and active requirements
- `.planning/ROADMAP.md` section "Phase 51: Support Matrix and Native Rebuild Truth" - authoritative phase goal and success criteria.
- `.planning/REQUIREMENTS.md` section "Support Truth" - SUPP-01 and SUPP-02.
- `.planning/PROJECT.md` - Crosswake thesis, v3.6 scope, current deferred provider/auth/notification/shell claims, and support-truth guardrails.
- `.planning/STATE.md` - current position, blockers, and deferred items.
- `.planning/MILESTONE-ARC.md` - strategic rationale for operator truth before provider/native breadth.

### Prior phase decisions
- `.planning/phases/50-doctor-publish-and-readiness-checks/50-CONTEXT.md` - `doctor --check-publish` boundary, readiness finding categories, stable check ids, severity semantics, and no-false-support rules.
- `.planning/phases/49-operator-inspection-contract/49-CONTEXT.md` - route-authoritative inspection contract, split vocabulary, derived conditions, JSON/human output boundary, and deferred claim guardrails.
- `.planning/phases/48-strategic-signal-and-milestone-memory/48-CONTEXT.md` - release/support truth as product surface and closeout continuity.
- `.planning/milestones/v3.5-phases/47-companion-arc-guide-and-milestone-proof/47-CONTEXT.md` - companion guide parity and first-party companion proof posture.
- `.planning/milestones/v3.5-phases/46-sigra-auth-contract-only-slice/46-CONTEXT.md` - Sigra contract-only auth predicates and full-machinery defers.
- `.planning/milestones/v3.2-phases/23-commerce-support-and-proof-closure/23-CONTEXT.md` - commerce support/proof/rebuild posture and advisory provider proof split.

### Existing code surfaces
- `lib/crosswake/support_matrix/support_matrix.ex` - canonical support statuses, support rows, commerce corridor proof/rebuild truth, auth contract truth, release boundaries, and change classes.
- `lib/crosswake/support_matrix/renderer.ex` - deterministic support guide renderer and current table vocabulary.
- `lib/crosswake/operator_inspection.ex` - route-authoritative support, rebuild, proof, denial, auth, notification, companion, and condition derivation.
- `lib/crosswake/operator_inspection/types.ex` - versioned inspection document, route, and condition structs plus stable JSON serialization.
- `lib/crosswake/doctor/publish_readiness.ex` - Phase 50 readiness sidecar, check ids, severity/result/proof/rebuild fields, and deferred claim findings.
- `lib/crosswake/doctor/check.ex` - diagnostic finding severity/check/hint/details contract.
- `lib/crosswake/manifest/types.ex` - existing support, capability, package, release, and change-class typed entries.
- `lib/crosswake/manifest/builder.ex` - manifest support matrix and capability registry assembly.
- `lib/crosswake/shell/denial.ex` - canonical denial vocabulary.
- `lib/crosswake/bridge/commands/notification_token.ex` - notification-token provider snapshot contract.

### Guides and public support language
- `guides/support_matrix.md` - current support, proof, package, release, commerce, capability, and change-class guide.
- `guides/native_shell.md` - native shell runtime and rebuild guidance.
- `guides/compatibility.md` - compatibility axes, runtime-line, and companion compatibility language.
- `guides/companions.md` - first-party companion scope, optional dependencies, Rulestead/Rindle/Sigra boundaries, and proof posture.
- `guides/commerce.md` - provider-neutral commerce, backend-owned reconciliation, proof posture, and provider-adapter defers.
- `guides/capabilities.md` - capability family posture, notification-token provider snapshot, backend seams, and explicit defers.
- `guides/install.md` - install/doctor/package surface and rebuild guidance.
- `CHANGELOG.md` - unreleased versus published Hex truth.

### Prompt corpus and research memory
- `prompts/crosswake-brand-book.md` - boundary language and anti-hype support-claim guardrails.
- `prompts/crosswake-elixir-oss-dna.md` - install truth, support matrices, docs-contract checks, proof lanes, and diagnostics as product surface.
- `prompts/crosswake-integrations-and-companions.md` - companion classification, route/runtime decision observability, support incidents, and deferred integration sequencing.
- `prompts/crosswake-research-synthesis.md` - route ownership, runtime ladder, native shell, and support-claim constraints.
- `prompts/elixir-mobile-oss-lib-deep-research.md` - OSS library release, proof, compatibility, and DX posture.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` - native runtime versioning, bridge/capability plane, mobile DX, and support/debug lessons.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` - Hotwire Native, Capacitor, Expo/React Native, provider, runtime, and app-type lessons.

### External precedent surfaced by advisor research
- `https://docs.djangoproject.com/en/stable/topics/checks/` - stable check ids, severity, hints, and object references.
- `https://developer.hashicorp.com/terraform/internals/json-format` - versioned machine-readable JSON precedent.
- `https://developer.hashicorp.com/terraform/cli/commands/show` - human/machine output split.
- `https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-conditions` - condition records and single-health footguns.
- `https://docs.npmjs.com/about-audit-reports` - severity thresholding and advisory-noise lessons.
- `https://docs.expo.dev/eas-update/runtime-versions/` - native runtime version boundaries for update safety.
- `https://docs.expo.dev/build/updates/` - build/update coupling around native runtime truth.
- `https://capacitorjs.com/docs/apis/camera` - platform permissions and native dependency churn as support surface.
- `https://native.hotwired.dev/overview/path-configuration` - path/route configuration as explicit native behavior.
- `https://native.hotwired.dev/overview/bridge-components` - bridge components as bounded web/native communication.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.SupportMatrix.statuses/0` already locks the narrow support status
  set: `:supported`, `:verification_required`, and `:unsupported`.
- `Crosswake.SupportMatrix.commerce_corridors/0` already exposes corridor
  proof class, advisory provider proof, native rebuild requirement, fallback,
  prerequisites, and denial codes.
- `Crosswake.SupportMatrix.auth_contract_truth/0` already encodes Sigra's
  contract-only posture and deferred full auth machinery.
- `Crosswake.SupportMatrix.change_classes/0` already exposes the seed rebuild
  taxonomy Phase 51 should extend rather than replace.
- `Crosswake.OperatorInspection` already derives route support, rebuild,
  denials, proof class, auth readiness, notification readiness, companion
  binding, and condition records.
- `Crosswake.Doctor.PublishReadiness` already emits readiness checks with
  stable ids/codes, severity, result, docs reference, proof class, rebuild
  requirement, claim scope, and details.
- `Crosswake.SupportMatrix.Renderer` already keeps `guides/support_matrix.md`
  generated from canonical support truth.

### Established Patterns
- Crosswake uses typed structs and deterministic serializers for public
  contracts.
- Human docs and machine JSON are separate outputs over the same canonical
  truth.
- Route entries remain authoritative; summaries, indexes, findings, and
  conditions are derived views.
- Hermetic merge-blocking proof stays separate from advisory provider/device/
  storefront proof.
- Deferred provider/auth/notification/shell breadth is explicitly named in
  doctor and planning docs rather than implied by absence.

### Integration Points
- Extend `SupportMatrix` first, then have renderer, operator inspection, and
  doctor readiness consume those accessors.
- Keep `guides/support_matrix.md` generated or parity-locked to live support
  truth.
- Add focused Phase 51 tests for vocabulary stability, rebuild/action rows,
  promotion rule shape, and no-overclaim language.
- Leave broad proof/docs-contract locks to Phase 52, but make the contract
  machine-readable enough for Phase 52 to enforce.

</code_context>

<specifics>
## Specific Ideas

- The user selected all gray areas and explicitly asked for subagent-backed
  research, pros/cons/tradeoffs, ecosystem lessons, prompt-corpus context, and
  one cohesive recommendation set.
- Three advisor researchers were used:
  - Support vocabulary research recommended split canonical axes with derived
    conditions only as views.
  - Rebuild taxonomy research recommended a two-axis `change_class` plus
    `action_class` contract.
  - Promotion/docs research recommended criteria-as-code promotion rules with
    environment-sensitive advisory proof separated until explicit thresholds
    pass.
- The cohesive recommendation is: canonical split axes; generated support truth;
  route-authoritative inspection as a consumer, not the only source; two-axis
  rebuild/actionability; criteria-as-code promotion; explicit public non-claims;
  and conservative promotion over weak support widening.

</specifics>

<deferred>
## Deferred Ideas

None - discussion stayed within phase scope.

</deferred>

---

*Phase: 51-Support Matrix and Native Rebuild Truth*
*Context gathered: 2026-06-01*
