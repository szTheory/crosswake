# Phase 52: Operator Proof and Docs-Contract Locks - Context

**Gathered:** 2026-06-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the v3.6 operator truth mechanically durable.

**Delivers:**
- A merge-blocking hermetic proof lane that locks `mix crosswake.inspect`,
  `mix crosswake.doctor --check-publish`, support-matrix truth, denial/rebuild
  vocabulary, and docs-contract parity.
- Docs-contract tests that keep generated support truth, authored guides,
  operator JSON, doctor readiness findings, and public non-claims synchronized
  with live code.
- Failure output that points maintainers to actionable support-truth drift
  rather than generic assertion failures.
- CI topology that keeps environment-sensitive native/device/provider evidence
  visible but advisory unless explicit promotion rules make it merge-blocking.

**Satisfies:** PROOF-01 and PROOF-02.

**In scope:**
- Phase 52 proof and docs-contract locks for the v3.6 operator surface shipped
  across Phases 49-51.
- Requirement-mapped selective rollup of only the historical proof dependencies
  needed by PROOF-01/PROOF-02, such as denial vocabulary, companion/auth
  contract-only posture, commerce provider non-claims, support rows, and docs
  anchors.
- Local deterministic ExUnit/Mix proof by default.
- Advisory workflow visibility for native/device/provider proof surfaces that
  remain environment-sensitive.

**Out of scope:**
- Reopening the Phase 49 inspection contract, Phase 50 readiness model, or Phase
  51 support/rebuild/promotion vocabulary.
- StoreKit or Play Billing adapter implementation.
- Full Sigra handoff, passkey/OAuth/ceremony/refresh-token/native auth UI.
- Chimeway delivery, notification-open routing, or push delivery proof.
- Standalone public shell package release choreography.
- A mega proof lane that re-homes every historical phase proof.

</domain>

<decisions>
## Implementation Decisions

### 1. Proof Lane Topology - LOCKED
- **D-01:** Add a dedicated Phase 52 proof workflow rather than scattering the
  new proof across earlier workflows or relying on Mix aliases alone.
- **D-02:** The workflow should be layered: one required hermetic
  merge-blocking operator-proof job plus separate advisory visibility for
  native/device/provider lanes when present.
- **D-03:** The merge-blocking job should cover deterministic local truth:
  inspection output, doctor publish-readiness findings, support matrix rows,
  docs-contract parity, denial vocabulary, rebuild/action classes, promotion
  rules, and public non-claims.
- **D-04:** Advisory jobs must be labeled as advisory and must not imply
  StoreKit, Play Billing, Chimeway delivery, full Sigra machinery, or standalone
  shell packages have shipped.
- **D-05:** Prefer boring Mix/ExUnit commands behind the workflow, such as a
  focused `mix test` path or small proof alias, so the same contract is easy to
  run locally.

### 2. Docs-Contract Lock Shape - LOCKED
- **D-06:** Use a hybrid docs-contract strategy. Do not make all prose
  byte-identical, and do not rely only on loose substring assertions.
- **D-07:** Keep byte-identical checks for generated canonical data projections,
  especially `guides/support_matrix.md` versus
  `Crosswake.SupportMatrix.Renderer.render/1`.
- **D-08:** Add live-code parity assertions for stable vocabularies and ids:
  support statuses, proof classes, denial reasons, rebuild/change/action
  classes, promotion rule ids, doctor readiness categories/codes, and guide
  anchors.
- **D-09:** Add normalized JSON/golden contract checks for
  `Crosswake.OperatorInspection` and doctor publish-readiness output. Normalize
  volatile fields such as timestamps and ordering before comparison.
- **D-10:** Use authored-guide assertions for public non-claims and rough edges:
  StoreKit/Play Billing not shipped, Sigra contract-only, notification-token
  provider-snapshot only, Chimeway delivery deferred, standalone shell packages
  deferred, and compatibility-window narrowing distinct from native rebuild.
- **D-11:** If guide sections mix generated data and authored prose, make the
  boundary explicit in tests or section markers so future maintainers know
  whether to edit the renderer or the prose.

### 3. Drift Failure Ergonomics - LOCKED
- **D-12:** Phase 52 proof failures should use domain-specific helper
  assertions with stable proof/check ids, not raw `assert actual == expected`
  failures alone.
- **D-13:** Failure messages should include: stable id, subject, expected live
  source, observed drift, guide or module path, remediation hint, and whether
  the drift affects merge-blocking or advisory support truth.
- **D-14:** Stable ids should follow a compact grouped convention such as
  `proof.operator.*`, `proof.docs.*`, `proof.denial.*`, `proof.rebuild.*`, and
  `proof.readiness.*`. Exact ids are planner discretion, but uniqueness and
  grouping must be tested.
- **D-15:** Generated drift reports, GitHub summaries, or annotations are useful
  presentation layers, but they must be derived from the same canonical proof
  checks. They must not become a second contract.
- **D-16:** Snapshot-style diffs are acceptable for normalized JSON and rendered
  docs, but accepting a snapshot update must never be the only remediation when
  support-truth semantics changed.

### 4. Coverage Boundary - LOCKED
- **D-17:** Use requirement-mapped selective rollup. Phase 52 is centered on
  v3.6 operator surfaces and pulls only the historical proof dependencies that
  PROOF-01/PROOF-02 actually rely on.
- **D-18:** Do not aggregate every historical proof into a single mega lane.
  Existing phase proofs remain their own canonical deep checks.
- **D-19:** Historical dependencies should be referenced only where they protect
  live v3.6 operator truth, for example commerce provider non-claims,
  companion/auth contract-only posture, `:step_up_required`, route/denial
  vocabulary, support-matrix rows, and docs anchors.
- **D-20:** A small cross-milestone smoke sentinel is acceptable only as an
  additive early-warning signal. It must not replace the requirement-mapped
  Phase 52 proof depth.
- **D-21:** Map proof modules or helper assertions back to PROOF-01 and
  PROOF-02 so Phase 53 release continuity can audit requirement coverage without
  reading every test by hand.

### 5. Ecosystem Lessons To Preserve - LOCKED
- **D-22:** Import the Phoenix/Plug/Ecto lesson: explicit structs, closed
  vocabularies, deterministic validation, and local Mix commands are better DX
  than hidden inference or shell-only policy.
- **D-23:** Import the Django checks lesson: stable ids, severity/posture,
  object references, hints, and docs links make diagnostics actionable.
- **D-24:** Import the Terraform lesson: versioned machine output and human
  output are separate contracts. Human prose is not the automation API.
- **D-25:** Import the Kubernetes lesson carefully: condition-like summaries are
  useful, but they must not replace raw support, proof, rebuild, provider,
  auth, notification, and denial axes.
- **D-26:** Import the npm audit lesson: thresholding helps CI, but noisy
  advisory failures erode trust. Advisory proof should stay visible without
  blocking by default.
- **D-27:** Import the Rails route-inspection lesson: the operator surface should
  be easy to run locally, deterministic, and tied to named routes/surfaces.

### the agent's Discretion
- Exact file layout is planner discretion. Strong default: a focused
  `test/crosswake/proof/phase52_operator_truth_test.exs` plus small helper
  modules under `test/support` if the assertions would otherwise duplicate.
- Exact Mix alias names are planner discretion. Bias toward obvious local DX,
  such as `mix test test/crosswake/proof/phase52_operator_truth_test.exs`.
- Exact GitHub Actions job names are planner discretion if they preserve
  required hermetic versus advisory semantics in the name.
- Exact normalized JSON fixture format is planner discretion. Avoid introducing
  a new dependency unless it clearly improves schema validation.
- Exact stable proof id names are planner discretion if they are grouped,
  unique, and point to actionable remediation.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and active requirements
- `.planning/ROADMAP.md` section "Phase 52: Operator Proof and Docs-Contract
  Locks" - authoritative phase goal and success criteria.
- `.planning/REQUIREMENTS.md` section "Proof and Release Continuity" -
  PROOF-01 and PROOF-02.
- `.planning/PROJECT.md` - Crosswake thesis, v3.6 scope, deferred provider/auth/
  notification/shell claims, and proof/support guardrails.
- `.planning/STATE.md` - current position, blockers, and deferred items.
- `.planning/MILESTONE-ARC.md` - strategic rationale for operator truth before
  provider/native breadth.

### Prior phase decisions
- `.planning/phases/51-support-matrix-and-native-rebuild-truth/51-CONTEXT.md`
  - split support axes, action classes, promotion rules, public non-claims, and
  support/rebuild guide posture.
- `.planning/phases/50-doctor-publish-and-readiness-checks/50-CONTEXT.md` -
  `doctor --check-publish` boundary, readiness categories, stable diagnostic
  ids, severity semantics, and deferred claim guardrails.
- `.planning/phases/49-operator-inspection-contract/49-CONTEXT.md` -
  route-authoritative inspection contract, JSON/human boundary, split
  vocabulary, derived conditions, and deferred claim guardrails.
- `.planning/phases/48-strategic-signal-and-milestone-memory/48-CONTEXT.md` -
  release/support truth as product surface and closeout continuity.
- `.planning/milestones/v3.5-phases/47-companion-arc-guide-and-milestone-proof/47-CONTEXT.md`
  - companion guide parity, first-party companion proof posture, and
  contract-only Sigra milestone proof.
- `.planning/milestones/v3.5-phases/46-sigra-auth-contract-only-slice/46-CONTEXT.md`
  - Sigra auth predicates, `:step_up_required`, and full-machinery defers.
- `.planning/milestones/v3.2-phases/23-commerce-support-and-proof-closure/23-CONTEXT.md`
  - commerce support/proof/rebuild posture and hermetic/advisory provider proof
  split.

### Existing code surfaces
- `lib/crosswake/operator_inspection.ex` - route-authoritative operator
  inspection assembly.
- `lib/crosswake/operator_inspection/types.ex` - versioned inspection document,
  route, condition, support, rebuild, and JSON serialization structs.
- `lib/crosswake/operator_inspection/json_formatter.ex` - machine-readable
  inspection renderer.
- `lib/crosswake/operator_inspection/formatter.ex` - human inspection renderer.
- `lib/crosswake/doctor/publish_readiness.ex` - readiness checks, categories,
  codes, proof/rebuild fields, and deferred claim findings.
- `lib/crosswake/doctor/check.ex` - diagnostic finding severity/check/hint/
  details contract.
- `lib/crosswake/doctor/json_formatter.ex` - doctor JSON output and formatting
  precedent.
- `lib/crosswake/support_matrix/support_matrix.ex` - canonical support,
  proof, rebuild, action, promotion, package, auth, commerce, and non-claim
  truth.
- `lib/crosswake/support_matrix/renderer.ex` - deterministic support guide
  renderer.
- `lib/crosswake/shell/denial.ex` - canonical denial vocabulary.
- `lib/crosswake/manifest/types.ex` - manifest support matrix, change class,
  action class, and promotion rule serialization.

### Existing tests and proof precedents
- `test/crosswake/operator_inspection/operator_inspection_test.exs` -
  route-authoritative inspection and rebuild/promotion assertions.
- `test/crosswake/operator_inspection/json_formatter_test.exs` - inspection
  JSON contract precedent.
- `test/crosswake/operator_inspection/formatter_test.exs` - human inspection
  output precedent.
- `test/crosswake/doctor/publish_readiness_test.exs` - readiness category,
  stable code, deferred claim, and blocking behavior tests.
- `test/crosswake/support_matrix/support_matrix_test.exs` - support vocabulary
  and support-matrix stability.
- `test/crosswake/support_matrix/renderer_test.exs` - generated guide parity
  and deterministic renderer checks.
- `test/crosswake/guides/companions_test.exs` - live-code/docs parity for
  companion and auth guidance.
- `test/crosswake/guides/release_boundaries_test.exs` - rebuild and promotion
  guide parity.
- `test/crosswake/proof/phase23_commerce_support_proof_test.exs` - commerce
  support/proof/rebuild and provider-neutral guardrails.
- `test/crosswake/proof/phase41_gating_doctor_test.exs` - gate-state truth and
  doctor findings.
- `test/crosswake/proof/phase46_sigra_auth_contract_test.exs` - Sigra
  contract-only proof.
- `test/crosswake/proof/phase47_companion_arc_test.exs` - companion arc
  aggregate proof.

### Guides and public support language
- `guides/support_matrix.md` - generated support, proof, package, release,
  action class, promotion rule, and non-claim truth.
- `guides/install.md` - install/doctor/package and rebuild guidance.
- `guides/native_shell.md` - native shell runtime and rebuild guidance.
- `guides/compatibility.md` - compatibility axes, runtime-line, and
  compatibility-window guidance.
- `guides/companions.md` - first-party companion scope, optional dependencies,
  Rulestead/Rindle/Sigra boundaries, and proof posture.
- `guides/commerce.md` - provider-neutral commerce, backend-owned
  reconciliation, proof posture, and provider-adapter defers.
- `guides/capabilities.md` - capability family posture, notification-token
  provider snapshot, backend seams, and explicit defers.
- `CHANGELOG.md` - unreleased versus published Hex truth.

### Prompt corpus and research memory
- `prompts/crosswake-brand-book.md` - boundary language, no-magic positioning,
  and support-claim guardrails.
- `prompts/crosswake-elixir-oss-dna.md` - install truth, proof lanes,
  docs-contracts, release truth, support matrices, and diagnostics as product
  surface.
- `prompts/crosswake-research-synthesis.md` - route ownership, capability
  ladder, bounded bridge, and anti-patterns.
- `prompts/elixir-mobile-oss-lib-deep-research.md` - Phoenix-native mobile
  shell/library ecosystem lessons and CI/release proof posture.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` - Hotwire Native,
  bridge/capability plane, and proof posture lessons.

### External precedent considered during discussion
- `https://docs.djangoproject.com/en/6.0/ref/checks/` - stable check ids,
  severity, hints, and object references.
- `https://developer.hashicorp.com/terraform/internals/json-format` -
  versioned machine-readable JSON precedent.
- `https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/` -
  conditions/status semantics and footguns.
- `https://docs.npmjs.com/about-audit-reports` - thresholding and advisory
  severity lessons.
- `https://guides.rubyonrails.org/command_line.html` - route inspection and
  local command ergonomics.
- `https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands`
  - GitHub Actions annotation/summary presentation layer.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.OperatorInspection.inspect/1` already builds the versioned,
  route-authoritative document Phase 52 should lock.
- `Crosswake.OperatorInspection.Types.to_map/1` already provides stable map
  conversion patterns for normalized JSON checks.
- `Crosswake.Doctor.PublishReadiness.run/1` already exposes check ids,
  categories, severity, proof class, rebuild requirement, claim scope, docs
  references, and deferred claim details.
- `Crosswake.SupportMatrix.canonical/1` is the canonical source for support,
  proof, action, promotion, and non-claim truth.
- `Crosswake.SupportMatrix.Renderer.render/1` already makes
  `guides/support_matrix.md` byte-identical to live support truth.
- `Crosswake.Shell.Denial.reasons/0` exposes stable denial vocabulary that
  docs and inspection output should remain parity-locked to.
- Existing guide tests already prove the pattern for live-code/docs parity;
  Phase 52 should consolidate and sharpen it rather than inventing a second
  docs framework.

### Established Patterns
- Crosswake uses deterministic ExUnit proof lanes as product surface, with
  environment-sensitive provider/device proof separated as advisory.
- JSON machine output and human output are separate contracts; JSON shape is
  versioned and should be tested after normalizing volatile fields.
- Public support claims are intentionally narrow. Missing support truth should
  fail closed or produce explicit verification/advisory findings.
- Generated docs and authored prose have different stability needs: generated
  tables can be byte-locked; prose should be semantically parity-locked.
- The repo already prefers phase-specific proof tests such as Phase 23, 41, 46,
  and 47 rather than one global historical mega-test.

### Integration Points
- Add or extend proof tests under `test/crosswake/proof/` for the Phase 52
  requirement-mapped operator-truth rollup.
- Add helper assertions under `test/support/` only if they remove meaningful
  duplication and improve failure messages.
- Add a dedicated `.github/workflows/phase52-proof.yml` with clear required
  hermetic and advisory job naming.
- Reuse existing guide/support/operator/doctor tests where possible, but make
  Phase 52 the requirement-mapped contract that ties the v3.6 operator surface
  together.

</code_context>

<specifics>
## Specific Ideas

- The desired discussion style was recommendation-first: research serious
  alternatives, compare pros/cons/tradeoffs and ecosystem lessons, then lock a
  cohesive recommendation set so the maintainer does not have to choose routine
  implementation-shaping details.
- Four gray areas were researched with subagents: proof lane topology,
  docs-contract lock shape, drift failure ergonomics, and coverage boundary.
- The coherent recommendation set is:
  1. dedicated layered Phase 52 proof workflow;
  2. hybrid docs-contract locks;
  3. stable id/domain helper assertions for drift failures;
  4. requirement-mapped selective rollup.
- Great DX means local Mix/ExUnit commands, stable failure ids, guide/module
  paths in failure messages, and no hidden reliance on provider/device state in
  the merge-blocking lane.

</specifics>

<deferred>
## Deferred Ideas

- Full provider/device/storefront proof promotion remains deferred to future
  provider adapter milestones and must follow explicit promotion rules.
- Full Sigra session machinery, Chimeway delivery, and standalone shell package
  release choreography remain deferred to their planned milestones.

</deferred>

---

*Phase: 52-Operator Proof and Docs-Contract Locks*
*Context gathered: 2026-06-01*
