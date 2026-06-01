# Phase 53: Release Continuity and Closeout Hardening - Context

**Gathered:** 2026-06-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Make v3.6 release continuity deterministic enough to survive context clears.

**Delivers:**
- Public changelog/release guidance that distinguishes published Hex truth
  (`0.1.0`) from unreleased v3.6 support claims.
- A fail-closed closeout verifier for roadmap parity, requirements
  traceability, state frontmatter, phase verification, validation ledgers,
  summary frontmatter, thread/seed status, release continuity, and public
  support-claim changes.
- A disciplined milestone handoff that archives/resets the v3.6 planning
  boundary and routes the next milestone to `$gsd-discuss-phase 48` without
  creating duplicate sources of truth.

**Satisfies:** REL-01.

**In scope:**
- `CHANGELOG.md` and publish-readiness checks for unreleased-vs-published
  support truth.
- `mix closeout.verify` or equivalent deterministic wrapper backed by ExUnit.
- Closeout ledger enforcement for `.planning/milestones/v3.6-CLOSEOUT.md`.
- Final v3.6 planning artifact parity and next-milestone routing.

**Out of scope:**
- StoreKit or Play Billing adapters.
- Full Sigra handoff, ceremony, passkey, OAuth, refresh-token, or native auth UI
  machinery.
- Chimeway delivery, notification-open routing, or push delivery proof.
- Standalone public shell packages.
- Reopening Phase 49-52 operator/support/proof contracts except where Phase 53
  audits their release continuity.

</domain>

<decisions>
## Implementation Decisions

### 1. Release And Changelog Truth - LOCKED
- **D-01:** Keep `CHANGELOG.md` as the canonical public release-history
  surface. Do not introduce a separate release-support ledger as a second
  primary truth source.
- **D-02:** Add a richer `[Unreleased]` structure that explicitly separates:
  public support claims not yet published to Hex, verification-required or
  advisory surfaces, deferred/non-shipped claims, and the last published Hex
  truth (`0.1.0`).
- **D-03:** Use a changelog-first public UX with doctor/check-derived
  validation. The changelog remains human-authored; deterministic checks catch
  missing `[Unreleased]`, missing current package version sections, false
  shipped language, and drift from support-matrix/readiness non-claims.
- **D-04:** Do not generate the whole changelog from code. Generated/checkable
  claim truth should enforce bounded vocabulary and known non-claims while
  preserving maintainable release prose.
- **D-05:** Public language must keep planning milestones (`v3.6`) distinct from
  installable Hex SemVer releases (`0.1.0`, future `0.2.0`, etc.).
- **D-06:** Phase 53 should extend existing publish-readiness/doc-contract
  checks rather than inventing a parallel release command.

### 2. Closeout Verification Shape - LOCKED
- **D-07:** Implement a shared Elixir closeout validator with a thin
  `mix closeout.verify` task or alias wrapper. The Mix task is the maintainer
  DX; the validator module is the single source of truth.
- **D-08:** Back the validator with ExUnit tests under `test/crosswake/planning`
  so CI and local `mix test` exercise the same checks as the operator command.
- **D-09:** The verifier must fail closed on the Phase 48 closeout contract:
  stale roadmap parity, unchecked/unarchived requirements state, stale
  `.planning/STATE.md`, missing phase verification, malformed or missing
  `requirements-completed:` frontmatter, validation-ledger drift without a
  structured exception, unresolved thread/seed status, public support-claim
  changes without release/changelog continuity, malformed
  `deferred_with_reason`, and stale strategic queue refresh.
- **D-10:** Use stable check ids and actionable failure messages. Each failure
  should include the subject, source artifact, observed drift, expected shape or
  command, remediation hint, and whether the issue is merge-blocking closeout
  truth or human-review guidance.
- **D-11:** Preserve human judgment for release prose, durable lessons wording,
  and strategic narrative. Artifact existence, frontmatter shape, traceability,
  exception shape, and public-claim parity are deterministic and must be checked
  mechanically.
- **D-12:** Do not rely on docs-only checklists or `gsd-sdk`-only scripts as the
  primary enforcement path. They may feed the validator, but the project-facing
  command should be idiomatic Mix/Elixir.

### 3. Next-Milestone Handoff - LOCKED
- **D-13:** Close v3.6 with an explicit archive/reset boundary rather than only
  updating `PROJECT.md`, `MILESTONE-ARC.md`, and `STATE.md`.
- **D-14:** Archive v3.6 requirements/roadmap/closeout evidence before resetting
  active planning state for v3.7. The reset must make `$gsd-discuss-phase 48`
  the clear next execution step.
- **D-15:** If a handoff artifact is added, it must be pointer-first and thin:
  link to `PROJECT.md`, `MILESTONE-ARC.md`, archived v3.6 requirements/roadmap,
  `v3.6-CLOSEOUT.md`, `CHANGELOG.md`, and `STATE.md` instead of duplicating
  release/support truth.
- **D-16:** `PROJECT.md` and `.planning/MILESTONE-ARC.md` remain the durable
  strategic queue surfaces. Any short handoff doc is transitional continuity,
  not a new queue.
- **D-17:** The next-milestone queue must preserve the current sequencing:
  v3.7 commerce provider adapters, v3.8 full Sigra machinery, v3.9 Chimeway
  notification seam, v4.0 production shell runtime line, v4.1 multi-SaaS
  archetype proof, then Threadline audit capstone unless closeout explicitly
  records a changed rationale.

### 4. Ecosystem Lessons To Preserve - LOCKED
- **D-18:** Import the Hex/ExDoc lesson: package metadata, package file
  allowlists, changelog sections, and docs generation are release truth, not
  incidental paperwork.
- **D-19:** Import the Phoenix/Mix lesson: project-specific operational checks
  should be boring local commands with clear output and standard `mix help`
  discoverability.
- **D-20:** Import the Django checks lesson: stable ids, severity/posture,
  object references, hints, and deploy-oriented checks make closeout failures
  actionable.
- **D-21:** Import the Terraform lesson: human output and machine-readable truth
  serve different users. Human prose may improve; validator data and check ids
  must remain stable.
- **D-22:** Import the Ecto migration lesson: milestone boundaries should be
  explicit, ordered, and auditable rather than implicit tool state.
- **D-23:** Import the Kubernetes/Rails/Django release lifecycle lesson:
  release notes, deprecation/support claims, and upgrade/next-step routing must
  be synchronized before widening support.
- **D-24:** Import the npm audit lesson: thresholding is useful, but noisy
  advisory failures erode trust. Phase 53 should block on false support truth
  and malformed closeout evidence, while keeping advisory/provider/device
  signals visible but not overpromoted.

### the agent's Discretion
- Exact module names are planner discretion. Strong default:
  `Crosswake.Planning.CloseoutVerifier` plus `Mix.Tasks.Closeout.Verify`.
- Exact command spelling is planner discretion if it preserves the roadmap
  target `closeout.verify`. Prefer `mix closeout.verify` over a shell script.
- Exact check id names are planner discretion if they are stable, grouped, and
  tested. Good prefixes: `closeout.roadmap.*`, `closeout.requirements.*`,
  `closeout.state.*`, `closeout.verification.*`, `closeout.validation.*`,
  `closeout.release.*`, and `closeout.handoff.*`.
- Exact `[Unreleased]` subsection headings are planner discretion if published
  Hex truth, unreleased support truth, advisory/verification-required posture,
  and deferred non-claims remain visibly separate.
- Exact handoff artifact shape is planner discretion. Bias toward no new
  artifact unless it materially improves continuity; if added, make it a
  pointer index and parity-check it.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and active requirement
- `.planning/ROADMAP.md` section "Phase 53: Release Continuity and Closeout
  Hardening" - authoritative phase goal and success criteria.
- `.planning/REQUIREMENTS.md` section "Proof and Release Continuity" - REL-01.
- `.planning/PROJECT.md` - Crosswake thesis, v3.6 current state, deferred
  provider/auth/notification/shell claims, and next milestone queue.
- `.planning/STATE.md` - current position and closeout/session continuity.
- `.planning/MILESTONE-ARC.md` - durable strategic queue and next milestone
  rationale.
- `.planning/milestones/v3.6-CLOSEOUT.md` - closeout contract and Phase 53
  enforcement target.

### Prior phase decisions
- `.planning/phases/52-operator-proof-and-docs/52-CONTEXT.md` - proof topology,
  stable-id drift helpers, docs-contract locks, and requirement-mapped proof
  rollup.
- `.planning/phases/51-support-matrix-and-native-rebuild-truth/51-CONTEXT.md`
  - support/proof/rebuild/action axes, promotion rules, public non-claims, and
  rough-edge guidance.
- `.planning/phases/50-doctor-publish-and-readiness-checks/50-CONTEXT.md` -
  `doctor --check-publish`, readiness categories, severity semantics, and
  changelog/published truth.
- `.planning/phases/49-operator-inspection-contract/49-CONTEXT.md` -
  route-authoritative inspection, JSON/human boundary, support axes, and
  deferred claim guardrails.
- `.planning/phases/48-strategic-signal-and-milestone-memory/48-CONTEXT.md` -
  strategic arc refresh, closeout checklist, release/support truth as product
  surface, and Phase 53 enforcement target.

### Existing code and test surfaces
- `CHANGELOG.md` - public release history and published-vs-unreleased boundary.
- `mix.exs` - package version, Hex metadata, docs extras, and package allowlist.
- `lib/crosswake/doctor/publish_readiness.ex` - publish readiness checks,
  changelog parity, support/readiness categories, and JSON sidecar contract.
- `lib/mix/tasks/crosswake.doctor.ex` - existing Mix task option parsing and
  failure behavior precedent.
- `test/crosswake/doctor/publish_readiness_test.exs` - publish readiness and
  deferred support claim tests.
- `test/crosswake/hex_page_test.exs` - package/docs/changelog Hex readiness
  precedent.
- `test/crosswake/proof/phase52_operator_truth_test.exs` - stable-id proof and
  docs-contract drift precedent.
- `test/support/proof_assertions.ex` - reusable stable-id failure message and
  normalized fixture assertions.
- `test/crosswake/planning/milestone_arc_closeout_parity_test.exs` - current
  v3.6 closeout contract parity checks.
- `test/crosswake/planning/summary_frontmatter_test.exs` - SUMMARY frontmatter
  traceability precedent and current archived-phase limitation.
- `.github/workflows/phase52-proof.yml` - merge-blocking/advisory proof split
  and explicit non-claim language.
- `.github/workflows/hex-publish.yml` - publish/recovery posture.
- `.github/workflows/release-please.yml` - release automation posture.

### Prompt corpus and research memory
- `prompts/crosswake-brand-book.md` - operational truth over hype and
  changelog-first release tone.
- `prompts/crosswake-elixir-oss-dna.md` - install truth, support matrices,
  proof lanes, release automation, diagnostics, and release truth as product
  surface.
- `prompts/crosswake-gsd-project-brief.md` - docs/examples/release automation as
  product contract and public support claims as narrow truth.
- `prompts/crosswake-integrations-and-companions.md` - companion/provider
  sequencing and operator visibility constraints.
- `prompts/crosswake-research-synthesis.md` - CI/DX/release automation and
  broad-claim footguns.
- `prompts/elixir-mobile-oss-lib-deep-research.md` - Hex/HexDocs release
  choreography, separate artifact release discipline, and package support DX.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` - contract tests,
  operator diagnostics, and troubleshooting as DX.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` -
  mobile provider/runtime support sensitivity and platform policy lessons.

### External precedent used during advisor research
- `https://hex.pm/docs/publish` - Hex package metadata, SemVer, package file
  allowlist, docs publishing, dry-run/revert/recovery guidance, and CI caution.
- `https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html` - `mix hex.publish`
  behavior, docs publishing, `--dry-run`, and package update/revert windows.
- `https://keepachangelog.com/en/1.1.0/` - `[Unreleased]` changelog convention.
- `https://hexdocs.pm/mix/Mix.Task.html` - idiomatic custom Mix task contract.
- `https://hexdocs.pm/phoenix/1.7.7/mix_tasks.html` - Phoenix precedent for
  application/framework-specific Mix tasks.
- `https://docs.djangoproject.com/en/stable/topics/checks/` - stable check ids,
  severity, hints, object references, and deploy checks.
- `https://developer.hashicorp.com/terraform/cli/commands/validate` -
  deterministic validation command precedent.
- `https://developer.hashicorp.com/terraform/cli/commands/plan` - explicit
  review-before-apply lifecycle precedent.
- `https://developer.hashicorp.com/terraform/cli/commands/output` - human versus
  machine-readable output split.
- `https://hexdocs.pm/ecto_sql/Ecto.Migration.html` - explicit ordered migration
  ledger as analogy for milestone boundary discipline.
- `https://guides.rubyonrails.org/upgrading_ruby_on_rails.html` - explicit
  upgrade/release continuity guidance.
- `https://docs.djangoproject.com/en/stable/internals/release-process/` -
  release lifecycle and support-window precedent.
- `https://kubernetes.io/docs/reference/using-api/deprecation-policy/` -
  deprecation/support choreography and release-note discipline.
- `https://docs.npmjs.com/cli/v9/commands/npm-audit/` - severity thresholding
  and advisory-noise footguns.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Doctor.PublishReadiness` already checks package metadata,
  `[Unreleased]`, current package version, docs references, proof posture, and
  deferred claim language.
- `Crosswake.TestSupport.ProofAssertions` already provides stable-id assertion
  messages and normalized fixture checks suitable for closeout drift failures.
- `test/crosswake/planning/milestone_arc_closeout_parity_test.exs` already
  validates the v3.6 closeout ledger shape and Phase 53 enforcement target.
- `test/crosswake/planning/summary_frontmatter_test.exs` already parses
  `requirements-completed:` frontmatter, but is currently scoped to archived
  v3.3 summaries and should be generalized or mirrored for v3.6 closeout.

### Established Patterns
- Crosswake favors deterministic ExUnit proof over manual UAT for release and
  support surfaces.
- Public support truth uses split axes: support status, proof class, diagnostic
  severity, rebuild/action requirement, claim scope, and derived conditions.
- Human output and JSON/check contracts are separate; prose should not become
  the automation API.
- Environment-sensitive provider/device evidence stays advisory unless explicit
  promotion rules make it merge-blocking.

### Integration Points
- Add or extend a Mix task under `lib/mix/tasks/` for `mix closeout.verify`.
- Add a shared validator module under `lib/crosswake/planning/` or an adjacent
  internal namespace if the planner prefers not to expose planning modules as
  public API.
- Add focused tests under `test/crosswake/planning/`.
- Extend publish-readiness/doc-contract tests where release/changelog support
  truth needs enforcement.
- Wire the closeout verifier into a merge-blocking proof lane or existing
  phase proof command, while preserving Phase 52 advisory lane semantics.

</code_context>

<specifics>
## Specific Ideas

- The selected path is intentionally recommendation-first: no further user
  choice is needed unless planning uncovers a hard conflict.
- Preferred architecture is cohesive:
  1. `CHANGELOG.md` remains the public release artifact.
  2. `doctor --check-publish` and docs-contract tests enforce release/support
     claim honesty.
  3. `mix closeout.verify` enforces milestone closeout mechanics.
  4. Archive/reset establishes the next milestone boundary.
  5. `$gsd-discuss-phase 48` becomes the next clear command.
- Avoid "green", "healthy", "production-ready", or similar casual status terms
  unless raw support/proof/rebuild axes are adjacent.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 53-Release Continuity and Closeout Hardening*
*Context gathered: 2026-06-01*
