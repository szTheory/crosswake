# Phase 23: Commerce Support And Proof Closure - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the remaining v3.2 commerce support/proof gaps by making doctor and support-matrix commerce truth explicit, publishing reviewer/storefront guidance with clear non-claims, and formalizing merge-blocking versus advisory proof posture.

This phase does not ship provider adapters, does not move entitlement authority to device/storefront callbacks, and does not widen core vocabulary beyond provider-neutral contract terms.

</domain>

<decisions>
## Implementation Decisions

### Doctor Diagnostics Contract
- **D-01:** Add a typed doctor `commerce` summary surface (`corridors`, `prerequisites`, `snapshot_freshness`, `proof_posture`, `rebuild_requirements`) while keeping `findings` as the canonical enforcement stream.
- **D-02:** Every commerce diagnostic must emit stable `commerce.*` codes with explicit `fallback_hint`; no freeform or provider-specific denial taxonomy is allowed.
- **D-03:** Doctor JSON output must carry explicit `proof_class` (`merge_blocking` or `advisory`) for commerce support/proof findings.
- **D-04:** Entitlement freshness `stale` or `unknown` is fail-closed and treated as merge-blocking support truth (never informational-only).
- **D-05:** `native_rebuild_required` guidance for commerce corridors must be derived from canonical support/corridor metadata and emitted in both human and JSON formatter output.

### Support Matrix Canonical Truth
- **D-06:** `Crosswake.SupportMatrix` remains the single typed source of support truth; guides are rendered artifacts, not independent sources.
- **D-07:** Commerce support granularity stays contract-surface-level (corridor role and commerce capability family), not per-route matrix expansion.
- **D-08:** Each commerce support row must include owner posture, prerequisite classes, canonical denial codes, fallback behavior, rebuild requirement, and proof class.
- **D-09:** Provider/storefront checks remain advisory in v3.2 support truth until adapter milestones are explicitly promoted.
- **D-10:** Taxonomy parity across support matrix, doctor, guides, and tests is mandatory and enforced by deterministic parity tests.

### Proof Lane Boundaries
- **D-11:** Split proof posture into deterministic hermetic merge-blocking lanes and provider/storefront/simulator/device advisory lanes.
- **D-12:** Required branch checks must include only deterministic hermetic commerce contract/support/docs lanes.
- **D-13:** Advisory lanes must still run on schedule and on demand, and publish explicit artifacts/results and rough-edge notes.
- **D-14:** Advisory failures cannot silently redefine core support claims; only merge-blocking lane results can assert core support truth.
- **D-15:** Advisory-to-merge-blocking promotion requires explicit requirement/roadmap scope change plus sustained stability evidence.

### Reviewer And Storefront Guidance UX
- **D-16:** Use a layered matrix-first docs structure: support/proof truth first, storefront reviewer playbooks second, rough-edge/non-claims section third.
- **D-17:** Keep core contract sections provider-neutral; provider-specific reviewer instructions are allowed only in clearly labeled advisory playbook sections.
- **D-18:** Publish standardized reviewer notes templates (setup accounts, purchase/restore steps, fallback expectations, backend availability assumptions).
- **D-19:** Every reviewer/storefront checklist row must declare owner, proof class, failure posture, and rebuild requirement.
- **D-20:** Fallback language in docs must reuse canonical corridor denial/fallback terms and explicitly reject fail-open behavior.

### Claude's Discretion
- Exact naming/layout of the typed doctor `commerce` summary keys, so long as contracts remain stable and explicit.
- Exact shape of CI workflow job names and artifact naming for advisory proof publication.
- Exact subsection ordering and table formatting in reviewer playbooks, so long as required truth labels and non-claims remain explicit.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Scope And Locked Prior Decisions
- `.planning/PROJECT.md` — project thesis, scope boundaries, and backend-owned entitlement authority.
- `.planning/REQUIREMENTS.md` — `SUPP-04`, `SUPP-05`, `SUPP-06` requirements and support/proof gate language.
- `.planning/ROADMAP.md` — Phase 23 goal and success criteria.
- `.planning/STATE.md` — current milestone posture and blockers.
- `.planning/v3.2-MILESTONE-AUDIT.md` — concrete support/proof gaps that Phase 23 must close.
- `.planning/phases/19-commerce-route-corridors/19-CONTEXT.md` — corridor taxonomy and denial/fallback vocabulary.
- `.planning/phases/20-entitlement-lifecycle-semantics/20-CONTEXT.md` — authority/evidence/freshness semantics.
- `.planning/phases/21-reconciliation-example/21-CONTEXT.md` — reconciliation and projection truth posture.

### Doctor, Support Matrix, And Proof Surfaces
- `lib/crosswake/doctor/doctor.ex` — doctor finding pipeline and commerce corridor posture checks.
- `lib/crosswake/doctor/formatter.ex` — human support-truth rendering.
- `lib/crosswake/doctor/json_formatter.ex` — machine-readable support-truth rendering.
- `lib/crosswake/support_matrix/support_matrix.ex` — canonical typed support truth source.
- `lib/crosswake/support_matrix/renderer.ex` — deterministic support matrix guide renderer.
- `test/crosswake/doctor/doctor_test.exs` — doctor contract and commerce denial taxonomy tests.
- `test/crosswake/support_matrix/support_matrix_test.exs` — support matrix canonical shape and vocabulary tests.
- `test/crosswake/support_matrix/renderer_test.exs` — deterministic docs rendering/parity tests.
- `test/crosswake/proof/phase21_reconciliation_example_test.exs` — existing hermetic commerce/reconciliation proof posture.

### Commerce And Support Guides
- `guides/commerce.md` — normalized commerce semantics and reviewer/storefront baseline sections.
- `guides/support_matrix.md` — support truth publication artifact.
- `guides/capabilities.md` — capability/package/support posture constraints.
- `guides/compatibility.md` — compatibility axis and rebuild truth language.
- `examples/phoenix_host/README.md` — example-host guidance surface for adopter flows.
- `test/crosswake/guides/commerce_test.exs` — docs-contract lock for commerce language.

### Prompt Research Corpus (Required For Planning Alignment)
- `prompts/crosswake-integrations-and-companions.md`
- `prompts/crosswake-elixir-oss-dna.md`
- `prompts/crosswake-research-synthesis.md`
- `prompts/crosswake-gsd-project-brief.md`
- `prompts/crosswake-brand-book.md`
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md`
- `prompts/elixir-mobile-apptypes-design-stresstest-deep-research.md`
- `prompts/elixir-mobile-offlinesupport-flashcard-app-stresstest-deep-research.md`
- `prompts/elixir-mobile-offlinesupport-stresstest-deep-research.md`
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md`
- `prompts/elixir-mobile-oss-lib-deep-research.md`

### Ecosystem References (Advisory Design Input)
- `https://hexdocs.pm/ecto/Ecto.Changeset.html` — structured validation/reporting patterns.
- `https://hexdocs.pm/ecto/Ecto.Multi.html` — deterministic operation composition patterns.
- `https://hexdocs.pm/oban/ready_for_production.html` — Elixir operator-facing production guidance posture.
- `https://v2.tauri.app/security/capabilities/` — capability allowlist and least-privilege contract design.
- `https://native.hotwired.dev/overview/path-configuration` — runtime/config truth partitioning patterns.
- `https://docs.github.com/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches` — required check semantics for merge gates.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Doctor` pipeline + formatters: already supports stable finding codes, severity taxonomy, and commerce corridor checks.
- `Crosswake.SupportMatrix` + renderer: typed canonical support truth with deterministic guide rendering and parity tests.
- Existing docs contract tests (`guides/commerce`, `guides/support_matrix`) already enforce vocabulary integrity and provider-neutral boundaries.
- Existing hermetic proof coverage in `test/crosswake/proof/phase21_reconciliation_example_test.exs` provides baseline lane patterns for deterministic merge gates.

### Established Patterns
- Canonical truth lives in typed Elixir modules, then is rendered into guides and JSON/human output.
- Vocabulary lock and parity are enforced through tests, not manual discipline only.
- Commerce semantics are fail-closed, provider-neutral, and explicit about authority versus evidence.
- Support/proof posture already distinguishes `merge-blocking` versus `advisory` classes in support surfaces.

### Integration Points
- Extend doctor payload/findings in `lib/crosswake/doctor/*` and matching tests.
- Extend canonical commerce support rows and renderer output in `lib/crosswake/support_matrix/*` and matching tests.
- Update guide structure/content in `guides/commerce.md` and `guides/support_matrix.md` with docs-contract tests.
- Add/adjust proof lane tests and CI wiring for explicit merge-blocking/advisory separation.

</code_context>

<specifics>
## Specific Ideas

- Recommendations are intentionally one-shot and cohesive: each area selects the strongest option with no decision churn requested from the maintainer.
- Prioritize great maintainer ergonomics and adopter clarity: explicit proof classes, explicit fallbacks, explicit non-claims, deterministic gates.
- Preserve least-surprise behavior: what blocks merge, what is advisory, and what is unsupported should be obvious and mechanically enforced.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within Phase 23 scope.

</deferred>

---

*Phase: 23-commerce-support-and-proof-closure*
*Context gathered: 2026-05-27*
