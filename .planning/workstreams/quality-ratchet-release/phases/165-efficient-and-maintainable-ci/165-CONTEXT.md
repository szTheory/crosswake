# Phase 165: Efficient and Maintainable CI - Context

**Gathered:** 2026-08-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Reduce Crosswake's pull-request runner cost, queueing, duplicate execution, and workflow maintenance
burden while preserving the named proof evidence and fail-closed authority established in Phase 164.
This phase owns PR/main trigger separation, safe cancellation, runner placement, cache identity,
documentation-only scheduling, reusable CI contracts, and reproducible before/after evidence. It
does not reopen product or mobile breadth, build a CI dashboard, perform Phase 166's clean-checkout
quality sweep, reconcile Phase 167 documentation/PR truth, or prepare/publish Phase 168's release
candidate.

</domain>

<decisions>
## Implementation Decisions

### Trigger and merge authority
- **D-01:** Make `pull_request` the sole authoritative event for recurring product proof. A PR run
  proves GitHub's synthetic merge result; equivalent full proof must not run again for every branch
  push or landed `main` commit.
- **D-02:** Keep `push: main` only for work that is genuinely main-bound: release automation,
  policy/audit sentinels, explicitly justified cache warming, and at most a slim post-merge canary.
  Do not run a second copy of the complete PR proof set. Retire full main duplication only after the
  existing branch-protection audit verifies strict required-check authority and no unproven bypass.
- **D-03:** Defer `merge_group`. The current user-owned GitHub repository cannot use GitHub merge
  queue, and repository transfer is outside this phase. Reconsider only after organization
  ownership and sustained multi-contributor merge pressure make that governance change worthwhile.
- **D-04:** Scope ordinary PR concurrency by PR number rather than `head_ref`, so same-named fork
  branches cannot collide. Never cancel `main`, release, scheduled-audit, manual-recovery, or future
  merge-queue authority.
- **D-05:** `cancel-in-progress` alone is not sufficient evidence for CIP-04 because ordering is not
  guaranteed. Cancellation must be monotonic: it may cancel only a lower run ID for the same PR and
  workflow. Missing or ambiguous direction performs no cancellation, and executable negative
  controls prove that an older cycle cannot cancel a newer authoritative run.
- **D-06:** Do not use `pull_request_target` to execute, check out, classify, or otherwise consume
  untrusted pull-request code. Any trusted default-branch cancellation controller must be isolated
  from PR code and hold only the minimum Actions permission it needs.

### Proof and required-gate consolidation
- **D-07:** Converge on one stable required context over the PR proof graph (working name
  `merge-blocking-crosswake-ci`). Keep every meaningful proof as a literal, purpose-named leaf job
  with its own logs, summary, and retained artifacts. The contributor-facing required result is
  simple; proof detail remains one click below it. — **Reversibility: costly** — changing this later
  requires another green-first branch-protection and producer-authority migration.
- **D-08:** The umbrella aggregator uses `if: always()` and a closed result vocabulary, but it does
  no checkout or other fallible setup. It passes only when every expected leaf either succeeds or
  carries an exact classifier-issued irrelevance decision. Missing, failed, cancelled, timed-out,
  stale, action-required, unknown, or unexplained skipped leaves fail closed.
- **D-09:** Maintain one exact machine-checked leaf manifest and bidirectional workflow parity:
  every expected leaf must appear in the aggregator's static `needs`, every `needs` leaf must be
  declared, and every merge-blocking producer must remain unique. Extend Phase 164's detector and
  negative controls instead of creating a parallel governance convention.
- **D-10:** Migrate required-check authority in two stages: land and observe the new umbrella while
  old contexts remain required; register the green umbrella additively; verify both authorities;
  then remove old contexts through an exact dry-run diff and explicit trust approval before
  deleting old producers. Never combine registration and retirement into an unobserved cutover.
- **D-11:** Consolidate phase-numbered PR workflow files into one readable PR orchestration
  workflow. Keep release, publish/recovery, scheduled-audit, and advisory-native workflows separate
  where their triggers, permissions, secrets, cancellation, or trust boundaries differ.
- **D-12:** Use composite actions for repeated setup mechanics and named repository scripts for
  proof commands. Do not hide heterogeneous proofs behind an arbitrary-command abstraction.
  Reusable workflows are allowed only after their qualified check-name, permission, output, and
  concurrency behavior is proven not to weaken literal leaf evidence.
- **D-13:** Use matrices only for genuinely homogeneous compatibility axes such as supported
  OTP/Elixir pairs. Do not turn heterogeneous historic proof lanes into a dynamic matrix whose
  absent cells or generated names cannot be governed reliably.

### Change classification and documentation-only behavior
- **D-14:** Implement a first-party change classifier with a narrow documentation-only allowlist
  and a full-proof default. This phase does not attempt fine-grained Elixir/browser/Android/Apple
  impact inference.
- **D-15:** Parse a validated full-history diff using NUL-safe name/status handling with rename/copy
  detection. Evaluate both old and new names for renames/copies and include deleted paths. Treat
  filenames as untrusted input; do not interpolate them into shell expressions or print file
  contents.
- **D-16:** Missing/zero/unresolvable base SHAs, shallow history, malformed or empty classifier
  output, unknown statuses, mixed documentation/executable changes, and every unallowlisted path
  run the complete proof set. Workflow, action, classifier, proof-script, dependency, lockfile, and
  generated-contract changes are never documentation-only.
- **D-17:** Do not apply workflow-level `paths` or `paths-ignore` to required proof. One PR workflow
  always starts; literal leaf jobs use job-level conditions; the umbrella decides whether a skipped
  leaf was explicitly irrelevant. Workflow-level filters remain acceptable only for independently
  advisory automation that can never become required.
- **D-18:** A documentation-only PR still runs a bounded relevant contract: classification and
  aggregation; adopter codename/privacy checks for affected planning content; focused ExDoc,
  guide/support/capability parity for affected public docs; and applicable planning closeout
  checks. It does not schedule the full root suite, Playwright, Android, Apple, or unrelated
  packaging proof.

### Runner, cache, and timeout posture
- **D-19:** Run all pure Elixir and Android/JVM work on Linux. Make existing Android verification
  helpers portable when a shell-level macOS assumption is the only reason a JVM job uses macOS.
  Android's generator, Maven, JVM, and vector behavior stays frozen; moving proof does not authorize
  feature, emulator/device, template, or parity work.
- **D-20:** Reserve macOS for jobs that actually invoke Swift, Xcode, code signing, a simulator, or
  another Apple tool. Do not retain `DEVELOPER_DIR` or a macOS runner as cargo-cult configuration.
- **D-21:** Reuse and extend `.github/actions/setup-elixir-cache/action.yml`. Compiled `deps` and
  `_build` caches remain partitioned by compatible dependency topology and complete
  OS/architecture/OTP/Elixir/MIX_ENV/lock identity; never loosen scope across dependency-present
  and hermetic dependency-absent proofs. Downloaded Hex tarballs may retain their safe shared cache.
- **D-22:** Use official Gradle setup/cache support with explicit JDK, wrapper, Gradle, OS, and
  relevant lock/config identity. Swift caches include platform, architecture, Swift/Xcode identity,
  and resolved package state rather than only `Package.swift`. An incompatible toolchain or lock
  state must miss rather than restore optimistically.
- **D-23:** Every long-running job has a bounded job timeout. Cancellation and timeout audits cover
  each job, not merely the presence of one timeout somewhere in a workflow file. Test/proof retries
  remain prohibited; bounded dependency-fetch retry does not authorize retrying assertions.
- **D-24:** Preserve Release Please and recovery/publish workflows' non-cancelling, approval-aware
  posture. CI cost optimization is not authority to modify release trust semantics.

### Reproducible efficiency evidence
- **D-25:** Keep SEED-007 as labeled historical provenance, then capture a fresh pre-change
  current-`main` baseline and matched representative before/after cohorts for documentation-only
  PR, full-proof executable PR, and main-bound automation. If a comparable cohort cannot be
  obtained, record `not measured`; do not substitute an unmatched value silently.
- **D-26:** Store sanitized canonical JSON plus generated Markdown in phase-local evidence. Record
  schema version, repository commit, run ID, attempt, event, workflow/job identity, runner labels,
  explicit cohort criteria, sample count, and source commands so another maintainer can reproduce
  the comparison.
- **D-27:** Report workflow/job/check counts, runner selection, workflow start delay, job execution
  duration, critical-path duration, aggregate runner-seconds, and structured cache hit/miss results.
  Use sample counts and median/range. GitHub does not expose an exact per-job queued timestamp via
  the jobs API, so label that metric `not exposed` rather than presenting dependency wait or
  workflow start delay as job queue time.
- **D-28:** Extend `scripts/ci_monitor.cjs` or a similarly narrow existing monitor boundary rather
  than creating a dashboard or unrelated telemetry system. Keep measurement collection phase-local;
  promote only recurring classifier, leaf-manifest, runner-placement, cache-identity, cancellation,
  and evidence-schema contracts into CI.
- **D-29:** Keep timing results descriptive rather than threshold-gated until stable multi-run
  history exists. Do not turn GitHub-hosted queue variance into a flaky merge gate or unsupported
  performance claim.
- **D-30:** Evidence excludes actors, commit messages, runner identities, cache keys, logs, raw
  payloads, credentials, tokens, adopter facts, account/device identifiers, and revealing links.
  Publicly safe run/attempt IDs, SHAs, stable workflow/job names, runner class, timestamps,
  low-cardinality outcomes, and aggregate durations are allowed.

### Maintainer-facing experience
- **D-31:** Treat GitHub Checks as the only UI in this phase. A contributor sees one calm
  `Crosswake CI` verdict and literal failing proof names beneath it; internal cache keys and
  orchestration mechanics stay out of the primary result.
- **D-32:** Every summary states the classification, why it was chosen, scheduled proof families,
  explicitly irrelevant families, expected/observed leaf counts, and one exact local remediation
  command for a failure. Unknown classification visibly falls back to full proof.
- **D-33:** Status output follows `brandbook/BRAND-SPEC.md`: precise, short, candid, no hype, no
  color-only meaning, explicit units, and `observed`/`not measured` language. GitHub owns light/dark
  rendering; Phase 165 adds no custom visual surface, dashboard, or brand-polish program.

### the agent's Discretion
- Exact workflow, job, script, manifest, evidence, and schema filenames, provided names are literal,
  stable, purpose-oriented, and compatible with the existing producer audit.
- Exact documentation-only allowlist after repository inventory, provided the default remains full
  proof and every affected public/privacy contract still has a bounded owner.
- Exact matched-cohort size and collection commands, provided cohorts are explicit, comparable,
  reproducible, and reported with sample counts plus median/range.
- Exact decomposition between composite actions and named scripts, provided trust boundaries,
  leaf visibility, and local reproducibility remain clear.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project and workstream authority
- `AGENTS.md` — current priority, frozen Android boundary, sensitive-data rules, automated
  verification posture, and workstream routing.
- `.planning/PROJECT.md` — Phoenix-first thesis, active/parked workstream boundary, and current
  quality-ratchet direction.
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` — CIP-01 through CIP-07 acceptance
  scope and exclusions.
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` — Phase 165 goal, success criteria,
  dependencies, and separation from Phases 166-168.
- `.planning/workstreams/quality-ratchet-release/STATE.md` — current active position and carried
  Phase 164 decisions.
- `.planning/workstreams/quality-ratchet-release/phases/164-dependency-security-and-gate-authority/164-CONTEXT.md`
  — required-context uniqueness, closed aggregator vocabulary, test ownership, and deferred CI
  optimization boundary.
- `.planning/seeds/SEED-007-ci-cd-performance.md` — historical measurements, CI topology findings,
  prior experiments, and path-filter/consolidation footguns.

### Governing first-adopter boundary
- `.planning/ADR-FIRST-B2C-ADOPTER.md` — infrastructure framing, Android freeze, privacy boundary,
  automated-proof policy, and stop list.
- `.planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md` — RAG-oriented priority and proof/diagnostics
  principles; no adopter activation is part of Phase 165.
- `.planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md` — codename/privacy rules and physical-proof
  non-claims that CI summaries and evidence must not weaken.
- `.planning/workstreams/first-b2c-adopter-readiness/STATE.md` — parked external gate and exact
  non-inference posture.

### User-requested research and design authority
- `prompts/crosswake-elixir-oss-dna.md` — house style for named behavioral proof, deterministic
  host lanes, release truth, and contributor-facing install/diagnostic quality.
- `prompts/crosswake-research-synthesis.md` — current architectural thesis and prompt precedence.
- `prompts/crosswake-gsd-project-brief.md` — explicit CI/CD, release, DX, and proof-as-product vision.
- `prompts/elixir-mobile-oss-lib-deep-research.md` — ecosystem testing/CI research and cross-runtime
  footguns; current project decisions override legacy names or outdated cache examples.
- `prompts/new elixir oss lib prompt.txt` — originating one-shot, high-confidence CI/DX intent.
- `brandbook/BRAND-SPEC.md` — current voice, microcopy, accessibility, OSS, and operational-truth
  authority; it supersedes the older prompt-era brandbook where they differ.

### Existing CI authority and reusable seams
- `.github/actions/setup-elixir-cache/action.yml` — established complete cache-key dimensions,
  hermetic cache-scope boundary, shared Hex-package cache, and bounded fetch-only retry.
- `.github/workflows/phase69-proof.yml` — existing job-level relevance pattern and explicit skip
  message to replace with centralized classification.
- `.github/workflows/contract-drift-gate.yml` — literal sibling proof plus `if: always()` aggregator
  pattern.
- `.github/workflows/native-behavioral-proof-gate.yml` — Linux/Apple split, Gradle cache pattern,
  current generated-Android macOS portability debt, and native aggregation.
- `.github/workflows/offline-sync-e2e-gate.yml` — browser/example-host named-leaf and aggregation
  topology.
- `.github/workflows/required-checks-audit.yml` — branch-protection read authority, fail-closed
  credential handling, and human apply boundary.
- `.github/workflows/release-please.yml` — release-sensitive concurrency and permission boundary that
  Phase 165 must preserve.
- `script/list_merge_blocking_checks.py` — current producer inventory and uniqueness seam to extend
  with exact umbrella/leaf parity.
- `script/check_required_checks_registered.sh` — fail-closed registered-context audit.
- `script/register_required_checks.sh` — green-first, explicit administration handoff.
- `script/check_aggregator_result_semantics.py` — existing closed-result negative-control seam.
- `scripts/ci_monitor.cjs` — existing GitHub run/check monitoring CLI to extend for sanitized
  before/after cohort evidence.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.github/actions/setup-elixir-cache/action.yml` already centralizes BEAM setup, correctly
  qualified caches, safe shared Hex tarballs, and bounded dependency-fetch retry; 14 workflows
  already consume it.
- `script/list_merge_blocking_checks.py`, `script/check_required_checks_registered.sh`, and
  `script/register_required_checks.sh` already separate local producer truth, read-only policy
  audit, and explicit branch-protection mutation.
- `script/check_aggregator_result_semantics.py` and the aggregator negative-control workflow already
  exercise closed rollup results and should grow the explicit-irrelevance/missing-leaf cases.
- `scripts/ci_monitor.cjs` already wraps `gh` run/check inspection and is the natural bounded seam
  for evidence collection rather than a new dashboard.
- `phase69-proof.yml` demonstrates job-level change relevance, while contract/native/browser gates
  demonstrate literal proof leaves plus an always-running aggregator.

### Established Patterns
- The current repository has 41 workflow files; 34 listen to both PR and push events. Trigger
  duplication is structural, not a slow-test problem.
- Merge-blocking job names are branch-protection contracts with exactly one producer. Phase 164
  made duplicates and missing producers executable errors.
- Pure Elixir proofs already run successfully on Ubuntu in many lanes; the existing cache
  composite encodes the important dependency-topology distinction that generic cache advice would
  erase.
- Release, publish/recovery, scheduled audit, and native advisory jobs carry different permission,
  secret, cancellation, and promotion semantics from ordinary PR proof.
- Proof evidence is intentionally behavior-named and user-visible. Consolidation removes YAML and
  required-context sprawl, not behavioral identity, logs, or artifacts.

### Integration Points
- Replace scattered PR/push triggers and per-workflow concurrency with one PR orchestration entry
  and explicitly separate main-only workflows.
- Feed the first-party classifier's closed output into every conditional proof leaf and the exact
  umbrella aggregator.
- Extend producer-registration scripts for additive umbrella migration and exact old/new policy
  diffs.
- Move the generated Android JVM verification off macOS by repairing its portability assumption;
  retain Swift/Xcode jobs on macOS.
- Extend existing setup actions and monitor scripts for cache identity/outcomes and evidence rather
  than adding opaque third-party orchestration.

</code_context>

<specifics>
## Specific Ideas

- Preferred contributor summary: `Crosswake CI: documentation-only change. Documentation contracts
  passed; executable proof was explicitly irrelevant.`
- Full-proof success summary: `Crosswake CI: executable change. {observed} of {expected} expected
  proof leaves passed.`
- Safe-classifier fallback: `Crosswake CI could not validate the comparison base. Running the full
  proof set.`
- Failures name the literal proof and exact local command in one screenful; they do not expose cache
  keys, orchestration internals, raw logs, or adopter-sensitive data in the primary verdict.
- Ecosystem lesson: preserve conventional static jobs and use matrices for compatibility versions,
  not as a data-driven substitute for heterogeneous proof identity.
- Cross-ecosystem lesson: one conclusion job is ergonomic only when an exact manifest prevents an
  omitted leaf from disappearing silently.

</specifics>

<deferred>
## Deferred Ideas

- GitHub merge queue and `merge_group`: reconsider only after organization ownership and sustained
  merge pressure; repository transfer is not a Phase 165 deliverable.
- Fine-grained per-domain path selection: reconsider only if retained Phase 165 measurements show
  material waste after the binary documentation-only optimization and executable ownership proof
  can cover every mapping.
- Permanent CI performance SLO, dashboard, or threshold gate: reconsider only after stable
  multi-run history and a named owner. The governing ADR currently stops dashboard work.
- Unified local `mix ci`/clean-checkout command: Phase 166 owns complete repository determinism and
  the contributor-local verification entry point.
- Public documentation reconciliation, presentation polish, and custom CI UI: Phase 167 or a later
  explicitly scoped phase; Phase 165 uses GitHub Checks and current brand microcopy only.

</deferred>

---

*Phase: 165-efficient-and-maintainable-ci*
*Context gathered: 2026-08-28*
