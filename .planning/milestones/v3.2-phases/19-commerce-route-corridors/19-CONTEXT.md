# Phase 19: Commerce Route Corridors - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Declare and validate commerce-sensitive route ownership corridors so Phoenix-owned paywall/account surfaces are explicit, native-screen or companion storefront loops are explicit, manifest/support truth is provider-neutral, and unsupported or undeclared corridors fail closed with actionable reasons.

</domain>

<decisions>
## Implementation Decisions

### Corridor Declaration Shape
- **D-01:** Adopt a named corridor profile model plus explicit per-route binding (`commerce: [corridor: ...]`) as the primary DSL shape.
- **D-02:** Keep inline route-local commerce declarations supported for small/simple cases, but corridor profiles are the default recommendation for consistency and drift control.
- **D-03:** Preserve route-local ownership visibility at the route site even when using shared corridor profiles (principle of least surprise).
- **D-04:** Keep provider/storefront-specific vocabulary out of corridor DSL; corridor semantics remain normalized and Crosswake-owned.

### Manifest Corridor Truth Surface
- **D-05:** Add a root-level `commerce_corridors` registry in manifest output and route-level references (`corridor_ref` + role), following existing registry-plus-reference patterns used for capabilities and packs.
- **D-06:** Corridor entries must include explicit ownership posture per commerce moment and explicit denial/fallback posture.
- **D-07:** Validation must enforce corridor completeness (declared corridor exists, required fields present, provider-neutral vocabulary, explicit fallback/denial).

### Fail-Closed Denial And Fallback Semantics
- **D-08:** Use a two-layer denial taxonomy: stable high-level reason family plus stable canonical commerce denial code IDs.
- **D-09:** Canonical denial codes for this phase are:
  - `commerce.corridor.undeclared`
  - `commerce.corridor.unsupported`
  - `commerce.corridor.prerequisite_missing`
  - `commerce.corridor.runtime_incompatible`
  - `commerce.corridor.entry_denied`
  - `commerce.corridor.origin_denied`
  - `commerce.corridor.policy_blocked`
  - `commerce.corridor.pack_incompatible`
- **D-10:** Every corridor denial must carry explicit safe fallback guidance; implicit fallback behavior is disallowed.

### Public Guidance And DX Posture
- **D-11:** Documentation structure should be matrix-first (ownership/support truth first), then scenario walkthroughs, then policy invariants.
- **D-12:** Docs, doctor, support-matrix, validator, and manifest output must use the same normalized corridor/denial language to avoid support drift.

### Claude's Discretion
- Field-level naming details and exact struct layout for corridor manifest types, as long as they preserve the decisions above.
- Exact compiler hint phrasing, as long as errors are actionable and fail-closed behavior remains explicit.
- Whether to expose corridor role vocab as atoms internally and strings at manifest boundary, preserving stable external contracts.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Scope And Contract Guardrails
- `.planning/ROADMAP.md` — Phase 19 goal, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` — COMM-04/05/06 plus commerce scope guard and support/proof gates.
- `.planning/PROJECT.md` — core thesis, out-of-scope constraints, and backend-owned entitlement truth.
- `.planning/MILESTONE-ARC.md` — arc-level guardrails and v3.2 sequencing constraints.

### Existing Commerce And Capability Semantics
- `guides/commerce.md` — normalized commerce vocabulary and authority-vs-evidence stance.
- `guides/capabilities.md` — capability taxonomy, ownership rubric, packaging ledger, commerce boundaries.
- `guides/support_matrix.md` — support truth posture and classification language.

### Existing Policy And Manifest Surfaces
- `lib/crosswake/policy/schema.ex` — route policy schema and extension point for corridor declarations.
- `lib/crosswake/policy/route.ex` — normalized route struct and semantic validations.
- `lib/crosswake/policy/compiler.ex` — route metadata compilation and error surfacing patterns.
- `lib/crosswake/policy/validator.ex` — semantic invariant patterns and fail-closed checks.
- `lib/crosswake/manifest/builder.ex` — capability registry patterns and manifest assembly.
- `lib/crosswake/manifest/validator.ex` — layered manifest validation posture.
- `lib/crosswake/support_matrix/support_matrix.ex` — canonical support truth rendering model.
- `lib/crosswake/shell/denial.ex` — denial payload shape/behavior.
- `lib/crosswake/doctor/doctor.ex` — diagnostic pipeline extension point.
- `lib/crosswake/doctor/formatter.ex` — operator-facing messaging format.
- `lib/crosswake/commerce/contracts.ex` — typed commerce contract structs and vocabulary baseline.

### Prompt And Research Inputs Used For Recommendations
- `prompts/crosswake-integrations-and-companions.md` — companion boundary and integration posture.
- `prompts/crosswake-elixir-oss-dna.md` — install truth and OSS ergonomics principles.
- `prompts/crosswake-research-synthesis.md` — prior synthesis constraints and strategic direction.
- `prompts/crosswake-gsd-project-brief.md` — project positioning constraints and tone.
- `prompts/crosswake-brand-book.md` — communication clarity and consistency expectations.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` — architecture tradeoff research.
- `prompts/elixir-mobile-apptypes-design-stresstest-deep-research.md` — app-type ownership and UX pressures.
- `prompts/elixir-mobile-offlinesupport-flashcard-app-stresstest-deep-research.md` — local-first caution patterns.
- `prompts/elixir-mobile-offlinesupport-stresstest-deep-research.md` — offline contract and failure-mode lessons.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` — sequencing and support honesty guidance.
- `prompts/elixir-mobile-oss-lib-deep-research.md` — ecosystem-level library design patterns.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Policy.Schema` + `Crosswake.Policy.Route`: existing normalized route DSL contract where corridor declarations should be added.
- `Crosswake.Policy.Compiler` + `Crosswake.Policy.Validator`: established compile/semantic validation layers suitable for fail-closed corridor checks.
- `Crosswake.Manifest.Builder`: existing registry + route-reference manifest shape pattern reusable for `commerce_corridors`.
- `Crosswake.Manifest.Validator`: canonical place to enforce manifest corridor completeness and provider-neutral vocabulary.
- `Crosswake.SupportMatrix`: canonical support truth renderer to extend with corridor-level support posture.
- `Crosswake.Commerce.Contracts`: typed normalized commerce vocabulary substrate to keep as source terms.

### Established Patterns
- Route declarations are typed and validated early, with actionable compile errors.
- Manifest output uses normalized, typed registries with explicit route linkage.
- Support and doctor truth are part of product contract, not optional diagnostics.
- Capability semantics use ownership/package/proof/rebuild dimensions; corridor semantics should align with this style.

### Integration Points
- Route DSL extensions in policy schema/route/validator/compiler.
- Manifest root/type/validator updates for corridor registry and route references.
- Doctor/support output updates for corridor prerequisite and denial/fallback truth.
- Documentation updates in commerce/capabilities/support guides for ownership and failure-mode clarity.

</code_context>

<specifics>
## Specific Ideas

- One-shot cohesive recommendation bundle should optimize for great developer ergonomics, least surprise behavior, and fail-closed correctness.
- Emphasize idiomatic Elixir/Phoenix library design: explicit typed contracts, layered validation, actionable diagnostics, and additive evolution.
- Incorporate cross-ecosystem lessons from successful route/capability/policy systems while preserving Crosswake's Phoenix-first thesis.

</specifics>

<deferred>
## Deferred Ideas

None — discussion remained within Phase 19 scope.

</deferred>

---

*Phase: 19-commerce-route-corridors*
*Context gathered: 2026-05-27*
