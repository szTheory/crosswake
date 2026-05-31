# Phase 49: Operator Inspection Contract - Context

**Gathered:** 2026-05-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Define the operator-facing inspection contract that maintainers, support, and CI use to understand Crosswake route/runtime readiness without reading source code or scraping prose.

**Delivers:**
- A first-class inspection surface for route ownership, runtime mode, capability declarations, commerce corridors, companion bindings, auth predicates, notification readiness, and rebuild requirements.
- A stable machine-readable contract for CI/support tooling.
- A concise human-facing output that summarizes readiness without collapsing route ownership, support status, proof posture, severity, and rebuild truth into one misleading "green" state.
- Inspection semantics that reuse existing manifest, support-matrix, doctor, denial, companion, commerce, auth, notification, and rebuild truth instead of inventing parallel authority.

**Satisfies:** OPER-01 and OPER-02.

**In scope:**
- Define and implement a `mix crosswake.inspect` operator command and a reusable `Crosswake.OperatorInspection` core module.
- Build the inspection document from compiled route policy/manifest/support truth and existing doctor finding data where appropriate.
- Add JSON and human renderers with stable machine fields and concise route-centric human output.
- Add hermetic tests for JSON shape, route coverage, vocabulary stability, fail-closed/deferred claims, and formatter behavior.

**Out of scope:**
- `mix crosswake.doctor --check-publish` release readiness. That belongs to Phase 50.
- Support-matrix expansion and native rebuild public guidance. That belongs to Phase 51, though Phase 49 should expose the data shape Phase 51 will consume.
- Hermetic proof lanes and docs-contract locks for the whole v3.6 operator surface. That belongs to Phase 52.
- StoreKit, Play Billing, full Sigra session machinery, Chimeway delivery, standalone shell packages, or any claim that deferred provider/native breadth has shipped.

</domain>

<decisions>
## Implementation Decisions

### 1. Inspection Surface Boundary - LOCKED
- **D-01:** Use a hybrid boundary: add a first-class `mix crosswake.inspect` task backed by a reusable `Crosswake.OperatorInspection` module. Do not make operators use `doctor` or raw manifest/support-matrix APIs as the primary inspection interface.
- **D-02:** `doctor` remains findings-first diagnostics. Inspection is inventory/readiness-first. Future doctor readiness work may consume `Crosswake.OperatorInspection`, but Phase 49 should not bury the inspection contract behind `mix crosswake.doctor --inspect`.
- **D-03:** The inspector must source truth from existing compiled route policy, `Crosswake.Manifest`, `Crosswake.SupportMatrix`, companion registry state, doctor finding semantics, and `Crosswake.Shell.Denial` vocabulary. It must not duplicate canonical support, denial, or capability truth by hand.
- **D-04:** The command shape should be boring and discoverable: `mix crosswake.inspect --router Elixir.YourAppWeb.Router --format human|json`. Human format is the default; JSON is the CI/support contract.
- **D-05:** The public module should expose a stable programmatic API such as `Crosswake.OperatorInspection.inspect/1` or `from_manifest/2`. Exact function names are planner discretion, but the module owns the inspection contract and renderers call into it.
- **D-06:** Keep the command separate from `crosswake.doctor` because ecosystem precedent strongly separates inventory/inspection from diagnostics: `kubectl get/describe` vs health events, Terraform human plan vs JSON output, Rails route inspection vs runtime checks. This avoids making CI infer support truth from a diagnostic stream.

### 2. Machine-Readable Schema - LOCKED
- **D-07:** Use a versioned, route-centric inspection document. The route entry is the authority for ownership, runtime, capability, commerce, companion, auth, notification, support, denial, and rebuild truth.
- **D-08:** Add derived indexes and findings sidecars only as views over route entries. Indexes and findings must never become independent authority that can contradict `routes`.
- **D-09:** Recommended top-level JSON fields:
  - `schema_version` - inspection schema version, semver string.
  - `generated_at` - ISO8601 UTC timestamp.
  - `crosswake_version`.
  - `source` - manifest/support source versions, including `manifest_schema_version`, `bridge_protocol_version`, and `native_runtime_version`.
  - `summary` - counts and high-level posture, including route count, verification-required count, rebuild-required count, and blocking/error count.
  - `routes` - map keyed by route id; canonical route inspection truth.
  - `indexes` - derived query accelerators such as `by_runtime`, `by_capability`, `by_companion`, `by_auth_predicate`, `by_rebuild_requirement`, and `by_support_status`.
  - `findings` - typed check records for operator-relevant warnings/errors/advisories.
  - `provenance` - generator and input metadata; `git_sha` may be included when cheaply available.
- **D-10:** Recommended per-route field categories:
  - `id`, `path`, `runtime`, and `entry`.
  - `ownership` with `owner_plane` and fail-closed posture.
  - `offline` with mode plus cache/island contract presence.
  - `capabilities` as declared capability ids plus support metadata when available.
  - `commerce` with corridor reference, role, owner posture, prerequisites, proof class, and rebuild posture.
  - `companion` with `gated_by`, `on_unavailable`, dependency/readiness status, and runtime gate state when available.
  - `auth` with `auth_min_level`, `requires_recent_auth`, contract-only readiness, and `:step_up_required` fallback.
  - `notifications` with token capability declaration and provider-snapshot readiness only. Do not imply delivery support.
  - `support` with support status, proof class, advisory flag, and blocking reasons.
  - `rebuild` with native/companion rebuild booleans and reasons.
  - `denials` with possible fail-closed denial codes for the route.
  - `conditions` as condition-like records derived from the above axes.
- **D-11:** Versioning rule: tools may ignore unknown fields in compatible minor versions; unsupported major versions must fail closed. Do not ship unversioned JSON or rely on prose keys from human output.
- **D-12:** Serialize public enums as strings in JSON. Keep Elixir internals as closed atoms/structs where existing code already does so, and use the established `Types.to_map/1` style rather than ad hoc string manipulation.
- **D-13:** Do not use Ecto schemas/changesets for the inspection contract. This is not persistence or form validation; use plain structs, closed vocabularies, constructors, validators, and renderers consistent with existing Crosswake contracts.

### 3. Readiness Vocabulary - LOCKED
- **D-14:** Preserve Crosswake's existing split vocabularies instead of replacing them with one custom route readiness state. Support status, diagnostic severity, proof posture, rebuild class, denial reason, route gate state, and condition status are separate axes.
- **D-15:** Use current support statuses from `Crosswake.SupportMatrix.statuses/0`: `supported`, `verification_required`, and `unsupported`.
- **D-16:** Use doctor-style finding severities for findings: `error`, `warning`, and `advisory`. Severity is triage urgency, not support truth.
- **D-17:** Use current proof classes: `merge_blocking` and `advisory`. Advisory proof must stay visible and must not be rendered as supported.
- **D-18:** Use existing rebuild/change-class language from support truth: `docs-only`, `core-only/no native rebuild`, `compatibility-bump only`, and `native or companion rebuild required`. Route-level JSON may also include normalized booleans such as `native_required` and `companion_required`.
- **D-19:** Use current denial reasons from `Crosswake.Shell.Denial.reasons/0`, especially `gate_denied`, `kill_switch_active`, `step_up_required`, `unavailable_capability`, `undeclared_capability`, and commerce corridor denial codes.
- **D-20:** Use condition-like records as an additive machine-readable wrapper, not a vocabulary replacement. Recommended condition fields: `type`, `status` (`true | false | unknown`), `reason`, `severity`, `message`, `route_id`, and `details`. Conditions help CI/tooling, but raw support/proof/rebuild/denial fields remain canonical.
- **D-21:** Never collapse inspection into `ready | degraded | blocked | unknown` without exposing raw axes. A single readiness column is acceptable only as a human summary if it is clearly derived and cannot hide provider/auth/notification/rebuild caveats.

### 4. Deferred Claim Guardrails - LOCKED
- **D-22:** Provider adapter readiness must be represented as deferred or verification-required support truth, not as shipped StoreKit/Play Billing support.
- **D-23:** Notification readiness in Phase 49 means route/capability/provider-token snapshot visibility only. It must not imply Chimeway delivery, push delivery guarantees, notification-open routing, or provider delivery proof.
- **D-24:** Auth readiness in Phase 49 means Sigra contract-only route predicates and fail-closed `:step_up_required` semantics. It must not imply handoff, ceremony, passkey, OAuth, refresh-token, or native auth UI machinery.
- **D-25:** Companion readiness may report binding, dependency health, gate state, and rebuild posture. It must not create a generic plugin bus or collapse first-party typed companion seams into arbitrary extension behavior.
- **D-26:** Rebuild requirements must be visible wherever native shell, generated shell, native dependency, entitlement/permission, companion-native, provider, or compatibility-axis changes affect support posture.

### 5. Human Output And DX - LOCKED
- **D-27:** Human output should be concise, route-centric, and actionable: one summary section plus route rows grouped or filterable by route id/runtime/readiness. Avoid dumping the entire manifest in human mode.
- **D-28:** JSON output is the stable contract; human output may evolve for readability but must be covered enough to prevent accidental support-claim drift.
- **D-29:** Prefer obvious filters only if implementation remains scoped: `--route`, `--format`, and possibly `--only-errors` or `--check` are acceptable planner discretion. Avoid building a query language in Phase 49.
- **D-30:** Error messages should point to route ids, policy keys, denial codes, and guide paths rather than generic prose. This matches Phoenix/Plug/Ecto ecosystem expectations: explicit contracts, deterministic checks, and actionable errors.

### 6. Ecosystem Lessons To Preserve - LOCKED
- **D-31:** Import the Phoenix/Plug lesson: public contracts should be explicit, composable, deterministic, and fail closed. The inspector should read like route pipeline truth, not hidden magic.
- **D-32:** Import the Ecto lesson: plain structs and explicit changes/validation beat implicit state. The inspection schema should be versioned and typed rather than inferred from presentation.
- **D-33:** Import the Kubernetes lesson carefully: condition records are useful for operators, but boolean condition status can be misread as global health. Crosswake should keep independent support/proof/rebuild axes visible.
- **D-34:** Import the Terraform lesson: machine JSON must be intentionally versioned and separate from human output. Human wording is not an API.
- **D-35:** Import Rails route/Django check lessons: route inventory and check messages should be easy to run locally, deterministic, and tied to stable ids/codes.
- **D-36:** Import npm audit and CI annotation lessons: severity thresholds are useful for automation, but severity alone is not support truth and can cause alert fatigue if every advisory becomes a blocker.

### the agent's Discretion
- Exact file layout is planner discretion. Strong default: `lib/crosswake/operator_inspection.ex`, `lib/crosswake/operator_inspection/types.ex`, `lib/crosswake/operator_inspection/formatter.ex`, `lib/crosswake/operator_inspection/json_formatter.ex`, and `lib/mix/tasks/crosswake.inspect.ex`.
- Exact internal struct/module names are planner discretion if the public JSON fields remain route-centric, versioned, and machine-stable.
- Exact derived index set is planner discretion if route entries remain authoritative and the indexes most useful to CI/support are covered.
- Exact human table layout is planner discretion if output remains concise and route-centric.
- Exact doctor integration is planner discretion. Bias toward sharing the core inspection module and leaving richer `doctor --check-publish` composition to Phase 50.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and active requirements
- `.planning/ROADMAP.md` section "Phase 49: Operator Inspection Contract" - authoritative phase goal and success criteria.
- `.planning/REQUIREMENTS.md` section "Operator Inspection" - OPER-01 and OPER-02.
- `.planning/PROJECT.md` - Crosswake thesis, v3.6 scope, out-of-scope provider/native breadth, and support-truth guardrails.
- `.planning/STATE.md` - current position, blockers, and deferred items.
- `.planning/MILESTONE-ARC.md` - v3.6 operator truth rationale, future dependency queue, and support/rebuild/proof guardrails.
- `.planning/phases/48-strategic-signal-and-milestone-memory/48-CONTEXT.md` - strategic-memory and v3.6 sequencing decisions.

### Prior phase decisions
- `.planning/milestones/v3.5-phases/47-companion-arc-guide-and-milestone-proof/47-CONTEXT.md` - companion guide, docs-contract parity, and milestone proof decisions.
- `.planning/milestones/v3.5-phases/46-sigra-auth-contract-only-slice/46-CONTEXT.md` - contract-only auth predicates, `:step_up_required`, and deferred full Sigra machinery.
- `.planning/milestones/v3.5-phases/41-gating-doctor-and-support-matrix-truth/41-CONTEXT.md` - route gating doctor/support truth and runtime gate-state labeling, if available in archived phase context.
- `.planning/milestones/v3.2-phases/23-commerce-support-and-proof-closure/23-CONTEXT.md` - commerce support/proof/rebuild posture, if available in archived phase context.

### Existing code surfaces
- `lib/mix/tasks/crosswake.doctor.ex` - current Mix task pattern for router/format options.
- `lib/crosswake/doctor/doctor.ex` - existing diagnostics report, findings, companion/gating/auth/commerce summaries.
- `lib/crosswake/doctor/formatter.ex` - current human formatter style and pitfalls.
- `lib/crosswake/doctor/json_formatter.ex` - current stable JSON formatter patterns and detail handling.
- `lib/crosswake/doctor/check.ex` - finding struct and severity vocabulary.
- `lib/crosswake/manifest/types.ex` - typed manifest structs, route entries, capability support entries, and serialization contract.
- `lib/crosswake/manifest/builder.ex` - route/capability/commerce/support matrix assembly.
- `lib/crosswake/manifest/serializer.ex` - deterministic manifest serialization.
- `lib/crosswake/policy/route.ex` - normalized route policy contract.
- `lib/crosswake/support_matrix/support_matrix.ex` - canonical support, capability, commerce, auth, package, release, change-class, and gate truth.
- `lib/crosswake/support_matrix/renderer.ex` - support matrix human rendering and rebuild formatting.
- `lib/crosswake/shell/denial.ex` - stable denial vocabulary.
- `lib/crosswake/bridge/commands/notification_token.ex` - notification-token provider snapshot contract.
- `examples/ios_shell_host/Fixtures/crosswake_manifest.json` - large manifest fixture with route, support-matrix, commerce, auth, and notification-token truth.

### Tests and proof precedents
- `test/crosswake/doctor/formatter_test.exs` - formatter coverage and detail lookup footgun fixes.
- `test/crosswake/doctor/doctor_test.exs` - existing doctor report behavior.
- `test/crosswake/support_matrix/support_matrix_test.exs` - canonical support vocabulary and support-matrix stability.
- `test/crosswake/support_matrix/renderer_test.exs` - support guide renderer behavior.
- `test/crosswake/manifest/manifest_test.exs` - manifest build/serialization behavior.
- `test/crosswake/manifest/validator_test.exs` - manifest contract validation.
- `test/crosswake/proof/phase23_commerce_support_proof_test.exs` - commerce support/proof/rebuild semantics and provider-neutral guardrails.
- `test/crosswake/proof/phase41_gating_doctor_test.exs` - gate-state truth and doctor findings.
- `test/crosswake/proof/phase46_sigra_auth_contract_test.exs` - auth contract-only proof.
- `test/crosswake/proof/phase47_companion_arc_test.exs` - companion arc aggregate proof.

### Guides and public support language
- `guides/support_matrix.md` - current support, proof, package, release, and rebuild language.
- `guides/companions.md` - companion contract, optional dependency, Rulestead, Rindle, Sigra, proof, and non-goal language.
- `guides/native_shell.md` - native shell route/runtime and rebuild language.
- `guides/capabilities.md` - capability family, notification-token, and deferred support language.
- `guides/commerce.md` - commerce corridor, backend-owned reconciliation, proof posture, and provider-neutral guidance.
- `guides/compatibility.md` - compatibility axes and runtime-line language.

### Prompt corpus
- `prompts/crosswake-brand-book.md` - boundary and support-claim language.
- `prompts/crosswake-elixir-oss-dna.md` - install truth, docs-contracts, proof lanes, release truth, and DX posture.
- `prompts/crosswake-gsd-project-brief.md` - Phoenix-first route ownership and app/runtime boundaries.
- `prompts/crosswake-integrations-and-companions.md` - companion classification and sequencing.
- `prompts/crosswake-research-synthesis.md` - stable route ownership and bounded bridge conclusions.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` - runtime ladder and cross-ecosystem lessons.
- `prompts/elixir-mobile-oss-lib-deep-research.md` - OSS library release, CI, packaging, and support posture.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` - Hotwire Native lessons, bridge/capability plane, and proof posture.
- `prompts/new elixir oss lib prompt.txt` - maintainer preference for deep research, DX, CI/CD, ecosystem lessons, and cohesive recommendation-first planning.

### External precedent for ecosystem lessons
- `https://developer.hashicorp.com/terraform/internals/json-format` - Terraform machine-readable JSON versioning.
- `https://developer.hashicorp.com/terraform/cli/commands/show` - Terraform `show -json` human/machine split and caveats.
- `https://developer.hashicorp.com/terraform/internals/machine-readable-ui` - Terraform machine-readable UI stream precedent.
- `https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/` - Kubernetes Conditions and status semantics.
- `https://kubernetes.io/docs/concepts/workloads/pods/probes/` - readiness/liveness/startup probe semantics and footguns.
- `https://docs.djangoproject.com/en/6.0/ref/checks/` - Django system check message ids/severity precedent.
- `https://docs.npmjs.com/about-audit-reports` - npm audit severity/reporting precedent and threshold lessons.
- `https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands?apiVersion=2022-11-28&tool=bash` - GitHub Actions annotation shape for CI output.
- `https://spec.openapis.org/oas/v3.1.0.html` - versioned schema/document contract precedent.
- `https://guides.rubyonrails.org/command_line.html` - Rails route inspection ergonomics.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Manifest.Types.RouteEntry` already carries route id, path, runtime, offline, entry, commerce, capabilities, packs, transfers, security, origins, gate binding, fallback, auth min level, and recent-auth predicate.
- `Crosswake.Manifest.Builder` already assembles route entries, capability registry, commerce corridor registry, support matrix, pack registry, and compatibility versions.
- `Crosswake.SupportMatrix` is the canonical source for support statuses, capability family support rows, commerce corridor proof/rebuild metadata, auth contract truth, gate state labels, package surfaces, release boundaries, and change classes.
- `Crosswake.Doctor` already compiles policy/manifest truth and emits route-level gating, auth, commerce, shell, bridge, offline, and support findings.
- `Crosswake.Doctor.JSONFormatter` provides a precedent for JSON output, atom-to-string conversion, nil-safe detail lookup, and preserving false values.
- `Crosswake.SupportMatrix.Renderer` provides deterministic markdown/table rendering patterns that can inform the human inspection output without making prose the contract.
- Existing proof tests for Phases 23, 41, 46, and 47 already lock many vocabularies Phase 49 should reuse.

### Established Patterns
- Crosswake uses plain structs, constructors, validators, and deterministic serializers for runtime contracts. Follow that pattern for operator inspection.
- Crosswake separates human docs/rendering from machine truth and then locks parity with tests. Phase 49 should use the same shape.
- Merge-blocking hermetic truth stays separate from advisory provider/device proof. Inspection must preserve that split.
- Optional dependency and companion truth is fail-closed and read from runtime registration where needed.
- Route ownership remains the primary mental model. Cross-cutting summaries are derived from routes, not independent authority.

### Integration Points
- New `mix crosswake.inspect` should mirror doctor task ergonomics: require `--router`, support `--format human|json`, and compile route policy from the host router.
- `Crosswake.OperatorInspection` should consume manifest/support truth and likely share some doctor finding generation rather than copy/paste logic.
- JSON output should be tested directly, including exact top-level keys, route field categories, enum serialization, and no provider/full-auth/delivery overclaims.
- Human output should be concise enough for support but not treated as the automation API.
- Phase 50 can consume the inspection core when adding `doctor --check-publish`; Phase 51 can add richer support/rebuild truth that flows through the same inspection schema; Phase 52 can lock docs-contract/proof parity.

</code_context>

<specifics>
## Specific Ideas

- The user explicitly asked to consider all identified gray areas with subagent research and return one cohesive recommendation set so they do not have to choose routine architecture details.
- Three advisor researchers were used:
  - Surface boundary research recommended the hybrid `mix crosswake.inspect` plus shared core module.
  - Schema research recommended route-centric JSON with derived indexes and findings sidecars.
  - Vocabulary research recommended preserving current split Crosswake vocabularies with additive condition-like records.
- The coherent recommendation is: standalone inspector command, route-centric versioned schema, existing support/proof/rebuild/denial/severity vocabularies, condition-like records as derived machine wrappers, no collapsed global readiness state, and no deferred provider/auth/notification overclaims.
- The most important footguns to avoid are duplicate support truth, prose scraping, "no finding means supported", advisory proof rendered as healthy, provider delivery implied by notification-token readiness, and full Sigra machinery implied by route auth predicates.

</specifics>

<deferred>
## Deferred Ideas

- `mix crosswake.doctor --check-publish` should consume the inspection core in Phase 50, but publish/release readiness findings are not part of Phase 49.
- Expanding public support-matrix guidance for native rebuild classes belongs to Phase 51.
- Full docs-contract and hermetic proof lane locking for the entire v3.6 operator surface belongs to Phase 52.
- StoreKit, Play Billing, full Sigra machinery, Chimeway delivery, and standalone shell package support remain deferred to later milestones as already captured in project requirements.

</deferred>

---

*Phase: 49-Operator Inspection Contract*
*Context gathered: 2026-05-31*
