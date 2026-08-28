# Phase 165: Efficient and Maintainable CI - Research

**Researched:** 2026-08-28
**Domain:** GitHub Actions CI topology, trusted cancellation, proof aggregation, and reproducible efficiency evidence
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

The following constraints are copied verbatim from `165-CONTEXT.md`. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/165-CONTEXT.md:20-166,296-308]

### Locked Decisions

#### Trigger and merge authority
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

#### Proof and required-gate consolidation
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

#### Change classification and documentation-only behavior
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

#### Runner, cache, and timeout posture
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

#### Reproducible efficiency evidence
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

#### Maintainer-facing experience
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

### Deferred Ideas (OUT OF SCOPE)
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
</user_constraints>

## Summary

Phase 165 should be planned as a controlled CI authority migration, not a workflow cleanup. The repository currently has 41 workflow files, 34 workflows responding to pull requests, 58 pull-request jobs, and 27 live required contexts on strict `main` branch protection; the live repository had zero queued and zero in-progress runs at the research snapshot. [VERIFIED: repository inventory via parsed .github/workflows/*.yml and `gh api`, 2026-08-28] The target is one authoritative PR workflow with literal static proof leaves and one required umbrella, while release, publish/recovery, scheduled-audit, advisory-native, and narrowly justified main-bound workflows retain separate trust and trigger boundaries. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/165-CONTEXT.md:22-71]

The highest-risk work is authority, not syntax: monotonic cancellation must be implemented from trusted default-branch code; the documentation classifier must fail closed over NUL-delimited Git data; the umbrella must prove exact manifest parity; and branch protection must move green-first in two observable stages. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/165-CONTEXT.md:22-93] Runner moves are comparatively mechanical, but the existing generated-Android helper hard-codes macOS downloads and Homebrew paths, and three phase-era macOS jobs combine Apple and non-Apple proof that must be split or moved deliberately. [VERIFIED: script/verify_generated_android_shell.sh:10-135 and parsed .github/workflows/*.yml inventory]

Efficiency claims need a reproducible evidence product before the topology changes. GitHub exposes workflow creation/start timestamps and job start/completion timestamps, but its jobs response does not expose an exact job `queued_at`; therefore the report must distinguish workflow start delay from job execution and mark exact job queue time `not exposed`. [CITED: https://docs.github.com/en/rest/actions/workflow-runs] [CITED: https://docs.github.com/en/rest/actions/workflow-jobs] The phase should capture sanitized before/after matched cohorts and descriptive median/range results, while keeping recurring invariants—not timing thresholds—as merge-blocking contracts. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/165-CONTEXT.md:116-140]

**Primary recommendation:** Execute five ordered plan waves: baseline evidence; classifier/manifest/aggregator/cancellation contracts; runner/cache portability; PR orchestration consolidation; then green-first branch-protection migration and live cohort acceptance. [ASSUMED]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| PR proof orchestration | GitHub Actions control plane | Repository scripts | GitHub owns event/job scheduling; repository code owns deterministic proof commands. [VERIFIED: .github/workflows/*.yml and script/* inventory] |
| Documentation-only classification | Repository script | PR workflow | A first-party script parses the trusted Git object graph; the workflow only supplies validated event metadata and consumes closed outputs. [VERIFIED: D-14 through D-18 in 165-CONTEXT.md] |
| Obsolete-run cancellation | Trusted default-branch workflow | GitHub Actions REST API | Cancellation needs `actions: write` but must never consume PR code. [VERIFIED: D-04 through D-06 in 165-CONTEXT.md] |
| Leaf proof execution | Linux/macOS hosted runners | Repository scripts/composite actions | Runner choice follows actual tool ownership; leaf names and logs remain literal. [VERIFIED: D-07, D-12, D-19, D-20 in 165-CONTEXT.md] |
| Required-result authority | Umbrella job | Leaf manifest and branch protection | The umbrella concludes over static `needs`; the manifest and protection audit prevent omitted or duplicate producers. [VERIFIED: D-07 through D-10 in 165-CONTEXT.md] |
| Efficiency evidence | `scripts/ci_monitor.cjs` | Phase-local evidence files | The existing monitor is the narrow API boundary; canonical JSON drives generated Markdown. [VERIFIED: scripts/ci_monitor.cjs and D-25 through D-30 in 165-CONTEXT.md] |
| Required-check registration | GitHub branch protection | Repository audit/register scripts | Required contexts are live service configuration and need a staged exact-diff migration. [VERIFIED: script/check_required_checks_registered.sh:20-102; script/register_required_checks.sh:22-118] |

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| CIP-01 | Pure Elixir and Android/JVM proof runs use Linux runners; macOS runners are reserved for work that actually invokes Apple tooling. | Runner inventory identifies five PR macOS jobs and the macOS-only Android helper seam; the recommended split keeps only Swift/Xcode work on macOS. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:39-41; .github/workflows/*.yml; script/verify_generated_android_shell.sh:10-135] |
| CIP-02 | Pull-request workflows do not duplicate equivalent work through overlapping push triggers or superseded cycles. | Trigger inventory plus the PR-only topology and trusted monotonic controller address push duplication and superseded runs. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:42-43; parsed .github/workflows/*.yml inventory] |
| CIP-03 | Dependency and build caches are keyed by the relevant lockfiles and complete OTP/Elixir/JDK/Gradle toolchain identity, and cannot restore incompatible artifacts. | Existing Elixir cache dimensions are the base; Gradle and Swift identities need explicit contract tests. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:45-46; .github/actions/setup-elixir-cache/action.yml:9-55] |
| CIP-04 | Long-running jobs have bounded timeouts and concurrency rules that cancel obsolete work without cancelling a newer authoritative run. | All 88 current jobs have a timeout; executable cancellation fixtures must prove lower-ID-only behavior and no-op ambiguity. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:48-49; parsed .github/workflows/*.yml inventory] |
| CIP-05 | A documentation-only pull request completes an always-visible merge gate without scheduling unrelated build, browser, Android, or Apple proof jobs. | A NUL-safe fail-closed classifier plus job-level conditions and an `always()` umbrella preserves a visible result. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:51-52; D-14 through D-18 in 165-CONTEXT.md] |
| CIP-06 | Before/after evidence records workflow count, runner selection, queue time, and execution time so each optimization claim is reproducible. | Evidence schema distinguishes exposed timestamps from exact queue time and requires matched cohorts with sample counts. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:54-55; D-25 through D-30 in 165-CONTEXT.md] |
| CIP-07 | Repeated setup and proof orchestration is consolidated behind a small, readable set of reusable workflow or composite-action contracts without erasing named proof evidence. | One PR orchestration workflow, named scripts, selective setup composites, and exact manifest parity preserve literal leaves. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:57-59; D-07 through D-13 in 165-CONTEXT.md] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Preserve Crosswake as a Phoenix-first route-policy and runtime-contract system; this phase must not expand into a universal UI framework or new product/mobile breadth. [VERIFIED: AGENTS.md:39-56]
- Keep offline and fail-closed claims honest; CI optimizations may not silently weaken explicit denials or proof authority. [VERIFIED: AGENTS.md:45-51]
- Android is frozen at its current generator, Maven, JVM, and vector posture; moving existing proof to Linux does not authorize Android feature, template, device, parity, or release work. [VERIFIED: AGENTS.md:52-56]
- Never record or infer adopter identity or other revealing facts, and never put raw payloads, media, transcripts, credentials, account identifiers, tokens, or stable device identifiers in logs, telemetry, or proof artifacts. [VERIFIED: AGENTS.md:58-69]
- Use the explicit `quality-ratchet-release` workstream; do not infer state from a removed flat `.planning/STATE.md`. [VERIFIED: AGENTS.md:71-81]
- Default to automated verification. Human action is reserved for unavoidable credentials, external approvals, or irreversible trust actions; the Phase 165 branch-protection retirement approval is the one expected trust checkpoint. [VERIFIED: AGENTS.md:82-87; D-10 in 165-CONTEXT.md]
- Promote only recurring stable contracts into CI; keep one-time reconciliation and cohort collection in phase evidence. [VERIFIED: AGENTS.md:88-90]

## Standard Stack

### Core

| Library / facility | Version | Purpose | Why Standard Here |
|---|---|---|---|
| GitHub Actions workflow syntax and REST API | Repository-hosted service/API version | Event orchestration, jobs, cancellation, evidence collection | This is the existing CI platform and branch-protection authority; no platform migration is in scope. [VERIFIED: .github/workflows/*.yml and script/check_required_checks_registered.sh:58-102] |
| First-party Python standard-library scripts | Python 3; no third-party package | NUL-safe classifier, manifest validation, cancellation policy fixtures, evidence normalization | The repository already uses first-party Python governance scripts, including `list_merge_blocking_checks.py` and `check_aggregator_result_semantics.py`. [VERIFIED: script/list_merge_blocking_checks.py:1-224; script/check_aggregator_result_semantics.py:1-156] |
| Existing Node monitor boundary | Node.js; current local runtime `v24.19.0` | GitHub run/job/check collection and cohort report generation | `scripts/ci_monitor.cjs` already owns CI observation commands; extending it avoids a dashboard or parallel telemetry stack. [VERIFIED: scripts/ci_monitor.cjs and local environment probe, 2026-08-28] |
| `.github/actions/setup-elixir-cache` | Repository-local composite action | Beam setup plus compatible `deps`, `_build`, and Hex caches | It already centralizes strict tool-version and cache identity mechanics used by 14 workflows. [VERIFIED: .github/actions/setup-elixir-cache/action.yml:1-162 and parsed workflow inventory] |
| Official Gradle setup action | Literal repository use: `gradle/actions/setup-gradle@v6` | Gradle User Home caching and wrapper execution support | Use the existing official Gradle action; do not layer a second Gradle cache over it. [VERIFIED: .github/workflows/native-behavioral-proof-gate.yml:58-73] [CITED: https://github.com/gradle/actions/blob/main/docs/setup-gradle.md] |

### Supporting

| Facility | Version / identity | Purpose | When to Use |
|---|---|---|---|
| `actions/cache` | Literal pin comment says `v6.1.0`; action uses a full SHA | Elixir compiled/download cache layers and structured cache-hit output | Retain only behind the repository composite with full compatibility dimensions. [VERIFIED: .github/actions/setup-elixir-cache/action.yml:84-139] |
| Erlang/Elixir | Exact repository values: `"erlang 27.3"` and `"elixir 1.19.5-otp-27"` | Pure Elixir proof on Linux | Resolve from `.tool-versions`; do not infer from the research host. [VERIFIED: .tool-versions:1-2] |
| Gradle wrapper / Java | Exact wrapper value: `"distributionUrl=https\://services.gradle.org/distributions/gradle-8.7-bin.zip"`; exact source/target values: `"JavaVersion.VERSION_17"` | Existing Android/JVM proof on Linux | Use wrapper validation and explicit JDK 17 setup; do not add Android behavior. [VERIFIED: packages/crosswake-shell-core-android/gradle/wrapper/gradle-wrapper.properties:3; packages/crosswake-shell-core-android/build.gradle:25-26] |
| Swift Package Manager | Exact tools declaration: `"// swift-tools-version: 5.9"` | Existing iOS package proof on macOS | Cache identity must include platform, architecture, Swift/Xcode, and resolved state when present. [VERIFIED: packages/crosswake-shell-core-ios/Package.swift:1] [CITED: https://developer.apple.com/documentation/xcode/building-swift-packages-or-apps-that-use-them-in-continuous-integration-workflows] |
| Phase 164 producer and aggregator governance | Repository-local scripts and ExUnit proof tests | Unique producers, required-check parity, closed result semantics | Extend these boundaries instead of creating another check taxonomy. [VERIFIED: script/list_merge_blocking_checks.py:1-224; script/check_aggregator_result_semantics.py:50-79] |
| Existing adopter-context scanner | Repository-local Mix task/module | Privacy-safe planning/documentation checks | Schedule the existing scanner for affected documentation-only content instead of building a second codename/privacy taxonomy. [VERIFIED: lib/mix/tasks/crosswake.adoption_context.scan.ex:1-31; lib/crosswake/planning/first_adopter_context.ex:29-70,301-359] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| First-party binary documentation classifier | Marketplace path-filter action | Rejected by locked decision: a first-party fail-closed full-history classifier is required, and adding a dependency would widen the supply-chain and trust surface. [VERIFIED: D-14 through D-17 in 165-CONTEXT.md] |
| Trusted `workflow_run` cancellation controller | Built-in `cancel-in-progress: true` alone | Rejected as sole authority because concurrency ordering cannot establish the required lower-run-ID monotonic invariant. [VERIFIED: D-05 in 165-CONTEXT.md] [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency?apiVersion=2022-11-28] |
| Literal leaf jobs plus one umbrella | Dynamic heterogeneous matrix | Rejected because generated/absent cells weaken static name and manifest governance. [VERIFIED: D-07 through D-13 in 165-CONTEXT.md] |
| Phase-local JSON/Markdown evidence | Permanent dashboard/SLO | Rejected as out of scope and premature until stable multi-run history exists. [VERIFIED: D-25 through D-30 and Deferred Ideas in 165-CONTEXT.md] |

**Installation:** No external package installation is recommended. [VERIFIED: research stack inventory, 2026-08-28]

## Package Legitimacy Audit

Not applicable: Phase 165 should use existing pinned GitHub Actions, repository-local scripts/composites, and language standard libraries; it should not add an npm, PyPI, or crates dependency. [VERIFIED: Standard Stack recommendation above]

## Architecture Patterns

### System Architecture Diagram

```text
pull_request event (synthetic merge result)
        |
        v
one PR workflow -------------------------------------------------------+
        |                                                             |
        v                                                             |
validated full-history classifier                                     |
        |                                                             |
        +-- documentation_only --> focused privacy/docs/planning leaves
        |                                                             |
        +-- full_proof ---------> literal Linux leaves + Apple leaves |
                                                                      |
        +---------------- all declared results -----------------------+
                                |
                                v
                  checkout-free `if: always()` umbrella
                                |
                  manifest/result/irrelevance parity
                                |
                                v
                 one required `Crosswake CI` check
                                |
                                v
                  strict `main` branch protection

new PR workflow `workflow_run: requested` event --> trusted default-branch cancellation controller
                                      | validate workflow + PR + run IDs
                                      + cancel only lower ID for same PR/workflow

GitHub run/job/check APIs --> `scripts/ci_monitor.cjs` --> sanitized canonical JSON
                                                        --> generated Markdown evidence
```

The PR workflow must not receive `actions: write`; the separate trusted controller is the only component that needs that permission. [VERIFIED: D-06 in 165-CONTEXT.md]

### Recommended Project Structure

```text
.github/
├── workflows/
│   ├── crosswake-ci.yml                         # sole recurring PR proof entry
│   ├── cancel-obsolete-crosswake-ci.yml         # trusted default-branch controller
│   └── ...                                      # release/main/schedule/advisory boundaries
└── actions/
    └── setup-elixir-cache/action.yml            # extended compatible cache contract
script/
├── classify_ci_change.py                        # NUL-safe, fail-closed binary classifier
├── ci_leaf_manifest.json                        # exact literal PR leaf authority
├── check_ci_leaf_manifest.py                    # workflow/needs/producer parity
├── select_obsolete_ci_runs.py                   # pure lower-ID cancellation policy
├── check_phase165_efficient_ci.sh                # focused recurring phase gate
├── list_merge_blocking_checks.py                 # extended Phase 164 producer audit
└── check_aggregator_result_semantics.py          # extended closed-vocabulary fixtures
scripts/
└── ci_monitor.cjs                               # cohort/evidence subcommands
.planning/workstreams/quality-ratchet-release/phases/
└── 165-efficient-and-maintainable-ci/evidence/
    ├── baseline.json
    ├── after.json
    └── comparison.md
```

The exact filenames are discretionary, but responsibilities should remain separated as shown: pure policy logic must be locally testable, workflow YAML should orchestrate, and the monitor should normalize API data without becoming a dashboard. [ASSUMED]

### Component Responsibilities and Integration Seams

| Existing component | Phase 165 responsibility |
|---|---|
| `.github/actions/setup-elixir-cache/action.yml` | Preserve strict `.tool-versions`, bounded dependency-fetch retry, and current compatibility dimensions; expose/cache-report only safe closed outcomes needed by evidence. [VERIFIED: .github/actions/setup-elixir-cache/action.yml:9-162] |
| `.github/workflows/native-behavioral-proof-gate.yml` | Keep iOS package proof on macOS; keep Android package proof on Linux; move generated-shell JVM-only behavior off macOS after helper separation. [VERIFIED: .github/workflows/native-behavioral-proof-gate.yml:58-143] |
| `script/verify_generated_android_shell.sh` | Split portable package/JVM proof from optional macOS emulator/tool setup; do not expand Android scope. [VERIFIED: script/verify_generated_android_shell.sh:10-135; D-19 in 165-CONTEXT.md] |
| `script/list_merge_blocking_checks.py` | Extend its stable YAML producer inventory to enforce exact manifest/display-name/static-needs uniqueness and parity. [VERIFIED: script/list_merge_blocking_checks.py:1-224] |
| `script/check_aggregator_result_semantics.py` and negative-control workflow | Add manifest-issued irrelevance, missing leaf, and every closed result arm to the existing fail-closed model. [VERIFIED: script/check_aggregator_result_semantics.py:50-79] |
| `script/check_required_checks_registered.sh` | Preserve local-first and bidirectional live audit; validate the staged umbrella-plus-legacy state and then exact umbrella-only state. [VERIFIED: script/check_required_checks_registered.sh:20-102] |
| `script/register_required_checks.sh` | Evolve additive discovery into explicit add/retire manifests and exact dry-run diff; retain green-first refusal and dry-run/apply split. [VERIFIED: script/register_required_checks.sh:22-118] |
| `scripts/ci_monitor.cjs` | Add cohort capture, canonical schema validation, aggregate metric calculation, and Markdown generation; do not retain raw API payloads. [VERIFIED: scripts/ci_monitor.cjs; D-25 through D-30 in 165-CONTEXT.md] |
| Phase 69 / Phase 75 inline classifiers | Remove newline/grep classification and route through the central binary classifier before PR workflow consolidation. [VERIFIED: .github/workflows/phase69-proof.yml; .github/workflows/phase75-closeout-gate.yml] |
| `Mix.Tasks.Crosswake.AdoptionContext.Scan` / `Crosswake.Planning.FirstAdopterContext` | Reuse as the docs-only privacy/codename owner for affected planning content. Its path discovery already invokes `git ls-files --cached --others --exclude-standard -z`. [VERIFIED: lib/mix/tasks/crosswake.adoption_context.scan.ex:1-31; lib/crosswake/planning/first_adopter_context.ex:301-309] |
| Phase 5 / 18 / 79 workflows | Move the non-native Phase 5 job to Linux and split mixed Apple/Android proof in Phases 18 and 79 before consolidating their leaves. [VERIFIED: .github/workflows/phase5-proof.yml:43; .github/workflows/phase18-proof.yml:19-64; .github/workflows/phase79-proof.yml:18-47] |

### Pattern 1: Trusted Monotonic Cancellation Controller

**What:** Use a default-branch `workflow_run` controller on `requested` with only `actions: write` (and `contents: read` only if checking out trusted default-branch policy code). GitHub documents `requested`, `in_progress`, and `completed` activity types, notes that `requested` does not fire for re-runs, and executes the controller from the default branch. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows] The recommended inference is that `requested` gives the controller the earliest trusted opportunity to cancel an older running cycle before the new cycle consumes material runner time; this event timing must be proven in the live cancellation probe. [ASSUMED] Configure the PR workflow's built-in concurrency by PR number with `cancel-in-progress: false`; the trusted controller, not GitHub's non-directional cancellation, owns the cancellation decision. [VERIFIED: D-04 and D-05 in 165-CONTEXT.md] The controller validates the requested run's workflow identity, event, exactly one PR number, and integer ID; it lists same-workflow candidates and selects only rows satisfying the exact relation `candidate.workflow == current.workflow && candidate.pr == current.pr && candidate.id < current.id`. Missing, malformed, equal, greater, or ambiguous values select nothing. [VERIFIED: D-04 through D-06 in 165-CONTEXT.md]

**When to use:** Only for recurring PR workflow runs; never for `main`, release, scheduled, recovery, or merge-queue runs. [VERIFIED: D-04 in 165-CONTEXT.md]

**Operational sequence:** Request ordinary cancellation first, poll for a bounded interval, and use force-cancel only if ordinary cancellation does not respond. [CITED: https://docs.github.com/en/rest/actions/workflow-runs]

**Required negative controls:** lower ID selects; equal and greater IDs do not; mismatched workflow or PR does not; missing PR, multiple PRs, malformed ID, and API truncation/ambiguity do not. [ASSUMED]

### Pattern 2: NUL-Safe Fail-Closed Classifier

**What:** Validate base/head/merge SHAs as resolvable Git objects, fetch full history, and parse `git diff --name-status -z -M -C` without line splitting. Rename/copy records consume old and new paths; deletion records retain the deleted path. Filenames remain data and are never interpolated into shell expressions or printed with contents. [VERIFIED: D-14 through D-16 in 165-CONTEXT.md]

**Comparison tree:** On `pull_request`, GitHub's default checkout represents the synthetic merge result, so classify the validated base-to-checked-out merge result that the proof jobs actually execute. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows]

**Closed output contract:** Emit versioned JSON with `classification`, `reason`, scheduled proof families, and explicitly irrelevant leaves. The only classification values should be quoted exactly as `"documentation_only"` and `"full_proof"`; any other/missing output maps to `"full_proof"`. [ASSUMED]

**Allowlist recommendation:** Keep an explicit inventory of textual documentation roots and root documentation files. Treat `.github/**`, actions, scripts, source, tests, dependency manifests, lockfiles, generated contracts, release inputs, and mixed changes as full proof. [ASSUMED]

### Pattern 3: Literal Leaves, Exact Manifest, Checkout-Free Umbrella

**What:** Keep each heterogeneous proof as a literal static job. The manifest enumerates every leaf ID, display name, proof family, local remediation command, and allowed classifier irrelevance reason. A structural test enforces manifest ↔ workflow job declarations ↔ umbrella static `needs` ↔ unique producer parity in both directions. [VERIFIED: D-07 through D-13 in 165-CONTEXT.md]

**Aggregator behavior:** The repository's existing exact result vocabulary is quoted as `"failure"`, `"cancelled"`, `"skipped"`, `"timed_out"`, `"action_required"`, and `"stale"`; unknown, empty, and missing results fail. [VERIFIED: script/check_aggregator_result_semantics.py:50-57] Existing expected fixture names are quoted as `"success"`, `"failure"`, `"cancelled"`, `"skipped_disallowed"`, `"skipped_irrelevant"`, `"timed_out"`, `"action_required"`, `"stale"`, `"unknown"`, `"empty"`, and `"missing"`. [VERIFIED: script/check_aggregator_result_semantics.py:66-79]

**Implementation constraint:** The umbrella uses `if: always()` and built-in expression/shell facilities only; no checkout, dependency installation, or repository composite may stand between GitHub's `needs` object and the final conclusion. [VERIFIED: D-08 in 165-CONTEXT.md]

### Pattern 4: Green-First Required-Check Migration

**What:** Stage the irreversible-looking live configuration change so producer and protection authority overlap temporarily. [VERIFIED: D-10 in 165-CONTEXT.md]

1. Land the consolidated workflow and umbrella while every legacy required producer still emits its existing context. [VERIFIED: D-10 in 165-CONTEXT.md]
2. Observe the umbrella green on representative PRs, then register it additively and verify strict protection sees both new and old authorities. [VERIFIED: D-10 in 165-CONTEXT.md]
3. Generate an exact dry-run removal diff, obtain the explicit trust approval, apply the context retirement, and verify protection again before deleting legacy producers. [VERIFIED: D-10 in 165-CONTEXT.md]

The current registration script is additive and discovers contexts by the substring `merge-blocking`; the plan must evolve it to accept an exact manifest/policy rather than assuming every historic leaf remains required forever. [VERIFIED: script/register_required_checks.sh:43-118]

### Pattern 5: Canonical Evidence, Generated Presentation

**What:** Capture sanitized canonical JSON and generate Markdown from it. Include schema version, repository commit, run/attempt/event, stable workflow/job identity, normalized runner class, cohort criteria, sample count, source command, workflow/job/check counts, workflow start delay, job execution, critical path, aggregate runner-seconds, and structured cache outcomes. [VERIFIED: D-25 through D-30 in 165-CONTEXT.md]

**Metric semantics:** Calculate workflow start delay as `run_started_at - created_at` and job execution as `completed_at - started_at`; mark exact job queue time as `not exposed`. [CITED: https://docs.github.com/en/rest/actions/workflow-runs] [CITED: https://docs.github.com/en/rest/actions/workflow-jobs]

**Cache semantics:** For `actions/cache`, exact-key hit is `cache-hit == "true"`, partial restore is `"false"`, and a miss is an empty value. [CITED: https://github.com/actions/cache] The official Gradle setup does not expose an equivalent cache-hit output, so parse only a documented structured job-summary/log signal into closed outcomes or report `not measured`; never retain cache keys or raw logs. [CITED: https://github.com/gradle/actions/blob/main/docs/setup-gradle.md]

### Anti-Patterns to Avoid

- **Workflow-level path filtering on required proof:** a skipped required workflow can remain pending; always start the PR workflow and decide relevance inside it. [CITED: https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks?apiVersion=2022-11-28]
- **`pull_request_target` plus PR checkout:** it combines a privileged trust event with untrusted code. [CITED: https://docs.github.com/en/actions/reference/security/secure-use?learn=getting_started&learnProduct=actions]
- **Branch-name concurrency groups:** fork PRs can share `head_ref`; scope by repository PR number. [VERIFIED: D-04 in 165-CONTEXT.md]
- **Built-in cancellation as proof of ordering:** concurrency ordering is not a sufficient monotonicity guarantee. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency?apiVersion=2022-11-28]
- **Dynamic proof inventories:** generated heterogeneous matrices can hide missing leaves or produce unstable check names. [VERIFIED: D-09 and D-13 in 165-CONTEXT.md]
- **Cache-key loosening for hit rate:** incompatible artifacts must miss; cache outcomes are observations, not a reason to merge identities. [VERIFIED: D-21 and D-22 in 165-CONTEXT.md]
- **Timing thresholds in the merge gate:** GitHub-hosted variance would create unsupported claims and flaky authority. [VERIFIED: D-29 in 165-CONTEXT.md]
- **Retiring contexts before branch-protection verification:** this can create an unproven bypass or a permanently pending required check. [VERIFIED: D-02 and D-10 in 165-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| GitHub run/job/check transport | New HTTP client or telemetry service | Extend `scripts/ci_monitor.cjs` over `gh api` / GitHub REST | The monitor already provides authenticated observation commands and keeps evidence collection phase-local. [VERIFIED: scripts/ci_monitor.cjs; D-28 in 165-CONTEXT.md] |
| Gradle caching | A second generic cache over Gradle User Home | Official `gradle/actions/setup-gradle@v6` with explicit setup inputs | The official action already manages Gradle state; overlapping caches can conflict. [CITED: https://github.com/gradle/actions/blob/main/docs/setup-gradle.md] |
| Elixir setup/cache | Repeated `setup-beam` plus ad hoc cache YAML | Extend `.github/actions/setup-elixir-cache/action.yml` | The composite already partitions compiled caches by OS/architecture/toolchain/environment/lock/workflow-job scope. [VERIFIED: .github/actions/setup-elixir-cache/action.yml:9-55] |
| Required-check discovery | A second parser/convention | Extend `script/list_merge_blocking_checks.py` and branch-protection scripts | Phase 164 already owns producer uniqueness and local/live parity. [VERIFIED: script/list_merge_blocking_checks.py:1-224; script/check_required_checks_registered.sh:20-102] |
| Result semantics | Ad hoc shell truthiness | Extend `script/check_aggregator_result_semantics.py` and its negative-control workflow | It already encodes closed outcomes and fail-closed fixtures. [VERIFIED: script/check_aggregator_result_semantics.py:50-79] |
| CI UI/dashboard | Custom status site | GitHub Checks summaries and phase evidence | The phase explicitly limits its UI to GitHub Checks. [VERIFIED: D-31 through D-33 in 165-CONTEXT.md] |
| Fine-grained domain ownership inference | A large path-to-subsystem rules engine | Binary documentation-only/full-proof classifier | The phase locks the bounded binary optimization and defers per-domain inference. [VERIFIED: D-14 and Deferred Ideas in 165-CONTEXT.md] |

**Key insight:** The hard problems are authority and omission detection. Existing platform APIs and repository seams should transport data; small first-party policy modules should make the security-sensitive decisions and be exhaustively fixture-tested. [ASSUMED]

## Runtime State Inventory

This phase refactors and migrates live CI authority, so repository grep alone is insufficient. [VERIFIED: D-10 and D-25 through D-28 in 165-CONTEXT.md]

| Category | Items Found | Action Required |
|---|---|---|
| Stored data | GitHub retains Actions run/check history and 316 repository caches at the research snapshot; these are external service records, not repo data. [VERIFIED: read-only repository Actions caches API, 2026-08-28] | Do not migrate historical runs. Capture only allowed low-cardinality fields in canonical evidence; allow obsolete cache entries to age out rather than deleting broadly. [VERIFIED: D-25 through D-30 in 165-CONTEXT.md] |
| Live service config | Strict `main` branch protection currently quotes `"strict": true` and has 27 required check contexts; the snapshot had 0 queued and 0 in-progress Actions runs. [VERIFIED: read-only GitHub branch-protection and Actions API snapshot, 2026-08-28] | Treat protection as a two-stage live migration. Re-query active runs immediately before cutover, add the umbrella, verify both authorities, then exact-diff and approve legacy retirement. [VERIFIED: D-10 in 165-CONTEXT.md] |
| OS-registered state | None found: CI runs on GitHub-hosted runners and the repository does not register a Phase 165 daemon, launch agent, scheduled task, or system service. [VERIFIED: .github/workflows/*.yml and repository script inventory] | No OS migration. Keep local verification as ordinary commands. [VERIFIED: repository inventory] |
| Secrets/env vars | Branch-protection audit/registration and release workflows consume existing GitHub authorization/secrets; release semantics and secret names are outside the optimization. The trusted cancellation controller can use the ephemeral `GITHUB_TOKEN` with only Actions write authority. [VERIFIED: script/check_required_checks_registered.sh:58-102; .github/workflows/release-please.yml:24-27; D-06 and D-24 in 165-CONTEXT.md] | Do not rename or print secrets. Add no long-lived cancellation credential. Preserve release/recovery permission and approval boundaries. [VERIFIED: AGENTS.md:58-69; D-06 and D-24 in 165-CONTEXT.md] |
| Build artifacts / installed packages | Renaming workflows/jobs changes cache scope and can make older entries unreachable; 316 GitHub cache entries existed at the snapshot. [VERIFIED: read-only GitHub caches API snapshot, 2026-08-28] | Expect cold misses after compatible identity changes, document them, and let service retention evict old entries. Never weaken a cache key to preserve hit rate. [VERIFIED: D-21, D-22, D-27 in 165-CONTEXT.md] |

## Common Pitfalls

### Pitfall 1: An Older Controller Cancels the Newer Run

**What goes wrong:** Two controller invocations race, and the older invocation cancels the newer authoritative PR proof. [VERIFIED: D-05 in 165-CONTEXT.md]

**Why it happens:** Built-in concurrency and wall-clock observation do not themselves establish the required directional relation. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency?apiVersion=2022-11-28]

**How to avoid:** Make cancellation a pure selection over immutable workflow ID, PR number, and run ID; select only strictly lower IDs and no-op on ambiguity. Keep the controller on trusted default-branch code. [VERIFIED: D-05 and D-06 in 165-CONTEXT.md]

**Warning signs:** Cancellation logic compares timestamps, branch names, or “latest” array positions; tests omit equal/greater/malformed/multi-PR cases. [ASSUMED]

### Pitfall 2: A Documentation Filter Removes the Required Check

**What goes wrong:** GitHub never creates the workflow/check, so branch protection waits indefinitely instead of receiving an explicit neutral or passing umbrella conclusion. [CITED: https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks?apiVersion=2022-11-28]

**Why it happens:** Workflow-level `paths`/`paths-ignore` suppress the entire required producer. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax]

**How to avoid:** Always start one PR workflow, classify inside it, condition literal leaf jobs, and let an `always()` umbrella validate explicit irrelevance. [VERIFIED: D-17 and D-18 in 165-CONTEXT.md]

**Warning signs:** Required workflow YAML gains `paths`, skipped leaves have no classifier-issued reason, or the umbrella itself is conditional on classification. [ASSUMED]

### Pitfall 3: Rename/Copy and Strange Filenames Escape Classification

**What goes wrong:** A rename from executable code to documentation, a deletion, or a filename containing newline/glob characters is misread as documentation-only. [VERIFIED: D-15 and D-16 in 165-CONTEXT.md]

**Why it happens:** Newline-delimited `git diff --name-only | grep` treats path bytes as shell text and does not inspect both paths in rename/copy records. [VERIFIED: .github/workflows/phase69-proof.yml and .github/workflows/phase75-closeout-gate.yml classifier steps]

**How to avoid:** Use NUL-delimited name/status parsing, explicit record arity, full-history SHA validation, and full-proof fallback for every parse anomaly. [VERIFIED: D-15 and D-16 in 165-CONTEXT.md]

**Warning signs:** `for path in $(...)`, `grep` over filename lines, shallow checkout, or output not schema-validated before use. [ASSUMED]

### Pitfall 4: The Umbrella Goes Green After a Leaf Disappears

**What goes wrong:** A job is renamed or removed from `needs`; GitHub no longer reports it, and a partial aggregator passes. [VERIFIED: D-08 and D-09 in 165-CONTEXT.md]

**Why it happens:** Job declarations, aggregator dependencies, irrelevance policy, and required producer inventory drift independently. [VERIFIED: Phase 164 producer/aggregator governance inventory]

**How to avoid:** One exact manifest and bidirectional static tests must reject missing, extra, duplicate, undeclared, and unexplained-skipped leaves. [VERIFIED: D-09 in 165-CONTEXT.md]

**Warning signs:** The manifest is documentation-only, `needs` is assembled dynamically, or unknown result strings are treated as success/neutral. [ASSUMED]

### Pitfall 5: Android “JVM-Only” Proof Still Boots a macOS Toolchain

**What goes wrong:** Moving the YAML runner to Linux fails because the helper downloads macOS command-line tools/JDK or invokes Homebrew even when connected tests are disabled. [VERIFIED: script/verify_generated_android_shell.sh:10-11,24-41,83-93,125-135]

**Why it happens:** Platform setup and proof intent are combined in one script. [VERIFIED: script/verify_generated_android_shell.sh:1-135]

**How to avoid:** Separate portable JVM/package proof from optional device/emulator setup. Use explicit JDK 17 and official Gradle setup on Linux; keep Android feature/device scope frozen. [VERIFIED: D-19 and D-22 in 165-CONTEXT.md]

**Warning signs:** Linux lanes reference `.dmg`, Homebrew, `/Applications`, `DEVELOPER_DIR`, or macOS-only command-line-tools URLs. [VERIFIED: script/verify_generated_android_shell.sh:10-41]

### Pitfall 6: Cache Hits Cross an Incompatible Boundary

**What goes wrong:** Compiled Beam, Gradle, or Swift artifacts restore under a different OS/architecture/language/toolchain/lock topology and produce misleading success or opaque failures. [VERIFIED: D-21 and D-22 in 165-CONTEXT.md]

**Why it happens:** Keys optimize for hit rate, use only `Package.swift`, or omit JDK/Gradle/OTP/Elixir dimensions. [VERIFIED: .github/workflows/native-behavioral-proof-gate.yml:78-95; D-21 and D-22 in 165-CONTEXT.md]

**How to avoid:** Treat compatibility identity as correctness; incompatible state must miss. Add static contract tests for every key dimension and report outcomes descriptively. [VERIFIED: D-21 through D-23 and D-27 in 165-CONTEXT.md]

**Warning signs:** Cache keys shrink during optimization, restore prefixes bridge toolchain majors, or hit rate is presented without exact/partial/miss semantics. [ASSUMED]

### Pitfall 7: Required-Check Cutover Creates a Bypass or Deadlock

**What goes wrong:** Removing old contexts before the umbrella is green and required creates an authority gap; deleting producers while contexts remain required creates permanently pending checks. [VERIFIED: D-10 in 165-CONTEXT.md]

**Why it happens:** Workflow changes and live branch-protection changes are planned as one commit rather than an observed migration. [VERIFIED: current branch-protection state and D-10]

**How to avoid:** Use additive registration, automated parity verification, exact retirement dry run, the one explicit trust approval, post-apply verification, then producer deletion. [VERIFIED: D-10 in 165-CONTEXT.md]

**Warning signs:** A script overwrites the whole checks array without a diff, context retirement and producer deletion share a blind step, or protection strictness is not re-read. [ASSUMED]

### Pitfall 8: Evidence Leaks or Overstates Queue Performance

**What goes wrong:** Raw API/log/cache data retains identities or credentials, or reports dependency wait as exact queue time. [VERIFIED: D-27 and D-30 in 165-CONTEXT.md]

**Why it happens:** API responses are stored wholesale and timestamp semantics are collapsed. [ASSUMED]

**How to avoid:** Normalize through an allowlisted schema, discard raw payloads, label job queue `not exposed`, and use matched cohorts with sample count plus median/range. [VERIFIED: D-25 through D-30 in 165-CONTEXT.md]

**Warning signs:** Evidence contains actor/login, commit message, runner name/ID/group, cache key, log excerpts, raw JSON, or a single unmatched duration described as improvement. [VERIFIED: D-25 through D-30 in 165-CONTEXT.md]

## Code Examples

These examples show the required contract shape. Exact filenames and schema field names remain discretionary unless quoted from an opened source. [ASSUMED]

### Pure Monotonic Candidate Selection

```python
# Source basis: GitHub workflow-run API plus locked D-04..D-06.
def select_obsolete_runs(current, candidates):
    current_id = require_positive_integer(current["id"])
    workflow_id = require_identity(current["workflow_id"])
    pr_number = require_exactly_one_pr(current["pull_requests"])

    selected = []
    for candidate in candidates:
        if (
            candidate.get("workflow_id") == workflow_id
            and require_exactly_one_pr(candidate.get("pull_requests")) == pr_number
            and require_positive_integer(candidate.get("id")) < current_id
        ):
            selected.append(candidate["id"])
    return selected
```

The selector must reject/no-op rather than coerce malformed or ambiguous input, and network mutation must be a separate layer exercised only after the pure selector passes its fixtures. [ASSUMED]

### NUL-Safe Git Name/Status Parsing

```python
# Source basis: locked D-15/D-16. Paths remain bytes/data until validation.
argv = ["git", "diff", "--name-status", "-z", "-M", "-C", base_sha, merge_sha]
raw = subprocess.run(argv, check=True, stdout=subprocess.PIPE).stdout
records = parse_name_status_z(raw)  # R/C consume status + old path + new path
classification = classify_or_full_proof(records, allowlist)
```

Do not decode and interpolate paths into shell commands; the parser must test additions, modifications, deletions, renames, copies, newline bytes, glob characters, mixed changes, unknown statuses, truncated records, zero/unresolvable SHAs, and shallow history. [VERIFIED: D-15 and D-16 in 165-CONTEXT.md]

### Always-Visible Umbrella

```yaml
# Source basis: GitHub `needs`/`always()` syntax and locked D-08/D-09.
merge-blocking-crosswake-ci:
  name: Crosswake CI
  if: ${{ always() }}
  needs:
    - classify
    - dependency-security
    - core-hermetic-proof
    - documentation-contracts
    # ... every literal manifest leaf, statically declared
  runs-on: ubuntu-latest
  timeout-minutes: 5
  steps:
    - name: Conclude exact leaf results
      env:
        NEEDS_JSON: ${{ toJSON(needs) }}
      run: |
        # Inline built-in tooling only; no checkout or setup.
        # Unknown/missing/unexplained skipped outcomes exit non-zero.
        ./path-shown-for-shape-only
```

The final `run` line above is deliberately non-executable shape notation: the implementation should use inline built-in shell/JSON facilities because a repository script would require checkout, contradicting D-08. [ASSUMED]

### Evidence Timing Normalization

```javascript
// Source basis: fields documented by GitHub workflow-run and workflow-job APIs.
const workflowStartDelayMs = Date.parse(run.run_started_at) - Date.parse(run.created_at);
const jobExecutionMs = Date.parse(job.completed_at) - Date.parse(job.started_at);
const exactJobQueueTime = { status: "not_exposed", value: null };
```

Only compute a duration when both timestamps are present and ordered; otherwise output `not measured` with a closed reason code. [ASSUMED]

## Planner Guidance and Work Decomposition

### Wave 1 — Baseline Before Mutation

- Freeze the leaf/workflow/job/required-context inventory and add the versioned sanitized evidence schema before editing trigger topology. [VERIFIED: D-25 through D-28 in 165-CONTEXT.md]
- Extend `scripts/ci_monitor.cjs` with deterministic cohort/evidence commands, JSON-schema fixtures, and Markdown generation; capture fresh current-`main`, documentation-only PR, full executable PR, and main-bound cohorts where comparable data exists. [VERIFIED: D-25 through D-30 in 165-CONTEXT.md]
- Record workflow start delay, job execution, critical path, runner-seconds, counts, runner classes, and cache outcomes; quote exact job queue as `"not exposed"`. [VERIFIED: D-27 in 165-CONTEXT.md]
- Do not begin consolidation before canonical baseline JSON is committed; otherwise CIP-06 cannot reproduce the “before” side. [ASSUMED]

### Wave 2 — Policy Contracts and Negative Controls

- Build the NUL-safe classifier, explicit narrow allowlist, closed output schema, and adversarial fixture corpus. [VERIFIED: D-14 through D-18 in 165-CONTEXT.md]
- Build the exact leaf manifest and extend `list_merge_blocking_checks.py`, aggregator semantics, and negative-control workflow to enforce four-way parity: manifest, job declaration, static `needs`, unique producer. [VERIFIED: D-07 through D-10 in 165-CONTEXT.md]
- Build a pure monotonic cancellation selector plus the trusted default-branch controller, proving lower/equal/greater/mismatch/missing/malformed/ambiguous cases before granting Actions write. [VERIFIED: D-04 through D-06 in 165-CONTEXT.md]
- Keep old PR producers and protection unchanged in this wave. [ASSUMED]

### Wave 3 — Runner Portability, Cache Identity, and Timeouts

- Split portable JVM proof from macOS emulator/toolchain setup in `verify_generated_android_shell.sh`; move pure Elixir and Android/JVM leaves to Linux. [VERIFIED: D-19 and D-20 in 165-CONTEXT.md; script/verify_generated_android_shell.sh:10-135]
- Move Phase 5 proof to Linux because its exact environment value is `"CROSSWAKE_PHASE5_NATIVE_PROOFS: \"0\""`; split mixed Phase 18 and Phase 79 jobs so only their actual iOS/Swift parts remain on macOS. [VERIFIED: .github/workflows/phase5-proof.yml:43; .github/workflows/phase18-proof.yml:19-64; .github/workflows/phase79-proof.yml:18-47]
- Extend Elixir cache outputs/contract without loosening existing compatibility dimensions; establish explicit JDK/wrapper/Gradle identity; add Swift platform/architecture/toolchain/resolved-state identity. [VERIFIED: D-21 and D-22 in 165-CONTEXT.md]
- Retain an audited timeout on every job and preserve the rule that assertion retries are forbidden. [VERIFIED: D-23 in 165-CONTEXT.md]

### Wave 4 — Consolidated PR Orchestration

- Create the single PR workflow, preserving every literal proof name and local remediation command while retiring overlapping PR/push triggers from full-proof workflows. [VERIFIED: D-01, D-02, D-07, D-11, D-12 in 165-CONTEXT.md]
- Keep release, publish/recovery, scheduled audits, advisory-native, and justified main-bound work separate; preserve the exact release workflow values `"cancel-in-progress: false"` and `"queue: max"`. [VERIFIED: .github/workflows/release-please.yml:24-27]
- Wire documentation-only job conditions and relevant privacy/public-doc/planning leaves; keep the umbrella always visible and checkout-free. [VERIFIED: D-08 and D-14 through D-18 in 165-CONTEXT.md]
- Run actionlint, shellcheck/static scripts, ExUnit integrity tests, and fixture-driven negative controls before live observation. [ASSUMED]

### Wave 5 — Green-First Authority Cutover and Acceptance

- Land and observe the umbrella while all 27 legacy required contexts remain protected. [VERIFIED: branch-protection API snapshot, 2026-08-28; D-10 in 165-CONTEXT.md]
- Add the umbrella required context, verify strict protection and both producer sets automatically, then produce an exact retirement diff. [VERIFIED: D-10 in 165-CONTEXT.md]
- Pause only for the explicit irreversible trust approval to remove legacy required contexts; after approval, apply and re-verify before deleting old producers. [VERIFIED: AGENTS.md:82-87; D-10 in 165-CONTEXT.md]
- Capture matched post-change cohorts, generate the comparison, and keep unavailable comparisons as `not measured`. Timing remains descriptive. [VERIFIED: D-25 through D-30 in 165-CONTEXT.md]

### Plan Boundaries

The planner should create at least five plans matching the waves because Wave 1 must precede topology changes, Wave 5 contains a live-service trust checkpoint, and Waves 2–4 have independently testable deliverables. [ASSUMED]

## State of the Art

| Old / current approach | Phase 165 approach | When changed | Impact |
|---|---|---|---|
| 34 workflows respond to PR events and 34 respond to both PR and push. [VERIFIED: parsed .github/workflows/*.yml inventory] | One PR orchestration workflow; separate main/release/schedule/advisory authority. [VERIFIED: D-01, D-02, D-11 in 165-CONTEXT.md] | Phase 165 | Eliminates equivalent trigger duplication while retaining distinct trust boundaries. [ASSUMED] |
| Concurrency commonly uses exact values `"group: ${{ github.workflow }}-${{ github.head_ref || github.ref }}"` and `"cancel-in-progress: true"`. [VERIFIED: .github/workflows/contract-drift-gate.yml:4-5] | PR-number grouping plus trusted strict-lower-run-ID cancellation; no cancellation on other authorities. [VERIFIED: D-04 through D-06 in 165-CONTEXT.md] | Phase 165 | Prevents fork-name collision and cancellation inversion. [ASSUMED] |
| 27 legacy branch-protection contexts are required individually. [VERIFIED: GitHub branch-protection API snapshot, 2026-08-28] | One umbrella context backed by literal leaves and exact manifest parity. [VERIFIED: D-07 through D-10 in 165-CONTEXT.md] | Phase 165, staged | Simplifies contributor authority without erasing proof detail. [ASSUMED] |
| Phase-era classifiers use newline-oriented `git diff`/`grep` patterns. [VERIFIED: .github/workflows/phase69-proof.yml; .github/workflows/phase75-closeout-gate.yml] | Central NUL-safe first-party binary classifier with full-proof fallback. [VERIFIED: D-14 through D-18 in 165-CONTEXT.md] | Phase 165 | Handles rename/copy/delete and adversarial filename cases. [ASSUMED] |
| iOS cache key includes `Package.swift` but no resolved-state file; repository currently has no `Package.resolved`. [VERIFIED: .github/workflows/native-behavioral-proof-gate.yml:78-95; repository file inventory] | Platform/architecture/Swift/Xcode/resolved-state compatible identity; absent resolved state is explicit. [VERIFIED: D-22 in 165-CONTEXT.md] | Phase 165 | Avoids incompatible optimistic restore. [ASSUMED] |
| Run monitoring reports basic live status. [VERIFIED: scripts/ci_monitor.cjs] | Versioned sanitized cohort JSON plus generated Markdown. [VERIFIED: D-25 through D-30 in 165-CONTEXT.md] | Phase 165 | Makes efficiency claims reproducible without a dashboard. [ASSUMED] |

**Deprecated/outdated:**

- Newline-delimited path classification for required CI is unsafe for Phase 165's filename and rename/copy contract; replace it with the central NUL-safe classifier. [VERIFIED: D-15 and D-16 in 165-CONTEXT.md]
- Full product proof on both PR and generic push/main events is redundant under D-01/D-02 once strict umbrella authority is verified. [VERIFIED: D-01 and D-02 in 165-CONTEXT.md]
- Treating a workflow start delay or dependency wait as exact per-job queue time is unsupported by the exposed job fields. [CITED: https://docs.github.com/en/rest/actions/workflow-jobs]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | The recommended exact filenames and five-plan decomposition are the clearest implementation split. | Recommended Project Structure; Planner Guidance | Planner may choose different names/boundaries, but it must preserve responsibilities and ordering. |
| A2 | The exact classifier values should be `documentation_only` and `full_proof`, with the suggested versioned JSON field set. | Pattern 2 | Workflow and tests could disagree if naming is locked elsewhere during planning. |
| A3 | The documentation allowlist should be a small explicit data file covering textual docs roots/root docs and excluding release/code/generated inputs. | Pattern 2 | A too-wide allowlist can skip proof; inventory and negative fixtures must finalize it. |
| A4 | The trusted controller should use `workflow_run` and ordinary-cancel → bounded-poll → force-cancel sequencing. | Pattern 1 | GitHub permission/event behavior must be validated in a live probe before authority is claimed. |
| A5 | The umbrella can evaluate the closed manifest using only runner-built-in shell/JSON facilities without checkout. | Pattern 3; Code Examples | Runner image changes or expression size could require a different checkout-free encoding. |
| A6 | A comparable before/after cohort size can be obtained during the phase without manufacturing misleading activity. | Wave 1/5 | Unavailable cohorts must remain `not measured`, leaving part of CIP-06 acceptance open until observed. |

## Open Questions

1. **What exact files are documentation-only?**
   - What we know: the allowlist must be narrow, binary, and full-proof by default; workflow/action/script/dependency/lock/generated-contract changes are excluded. [VERIFIED: D-14 through D-18 in 165-CONTEXT.md]
   - What's unclear: whether release-facing files such as `CHANGELOG.md` and every `.planning/**` artifact can safely use the bounded docs path. [ASSUMED]
   - Recommendation: inventory every candidate path family, assign its required privacy/public-doc/planning owner, and lock the allowlist only after adversarial negative fixtures pass. [ASSUMED]

2. **Can the checkout-free umbrella stay within expression/environment limits for all leaves?**
   - What we know: it must statically `need` every expected leaf and perform no checkout/fallible setup. [VERIFIED: D-08 and D-09 in 165-CONTEXT.md]
   - What's unclear: the final serialized `needs` payload size after consolidation. [ASSUMED]
   - Recommendation: prototype the largest static graph early and add a structural size/syntax test; split only presentation data, never authority, if limits are encountered. [ASSUMED]

3. **Which representative live cohorts are available?**
   - What we know: matched documentation-only, full-proof executable, and main-bound before/after cohorts are required, with `not measured` for unavailable comparisons. [VERIFIED: D-25 through D-29 in 165-CONTEXT.md]
   - What's unclear: whether enough recent pre-change examples exist for every cohort. [ASSUMED]
   - Recommendation: capture current API evidence before changes and, if necessary, use sanitized temporary PR probes whose assertions and cleanup are automated; do not invent unmatched baselines. [ASSUMED]

4. **What is the final stable required context display name?**
   - What we know: the locked working context is quoted exactly as `"merge-blocking-crosswake-ci"`, while the contributor summary is `"Crosswake CI"`. [VERIFIED: 165-CONTEXT.md:47-58,142-150]
   - What's unclear: whether GitHub protection will register the job ID-derived or display-name-derived string in the final YAML shape. [ASSUMED]
   - Recommendation: prove the emitted check name on a live non-required run before additive registration; then freeze that exact value in the manifest and protection scripts. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---:|---|---|
| GitHub CLI / authenticated API | Live inventory, cohort capture, branch-protection migration | ✓ | `gh 2.95.0` | Direct GitHub REST with equivalent least-privilege credential. [VERIFIED: local environment probe, 2026-08-28] |
| `jq` | Checkout-free aggregation and evidence normalization prototypes | ✓ | `jq-1.7.1-apple` | Python standard library JSON processing for local scripts; the umbrella must use runner-built-in facilities. [VERIFIED: local environment probe, 2026-08-28] |
| Python | Classifier, manifest, cancellation policy, governance tests | ✓ | `Python 3.14.4` | Keep code compatible with the CI-provided Python 3 version selected in workflow. [VERIFIED: local environment probe, 2026-08-28] |
| Node.js | `scripts/ci_monitor.cjs` evidence extension | ✓ | `v24.19.0` | None needed for research; CI must use the repository's established setup. [VERIFIED: local environment probe, 2026-08-28] |
| `actionlint` | Workflow syntax/static semantics | ✓ | `1.7.12` | Run the repository's CI installation path if a clean host lacks it. [VERIFIED: local environment probe, 2026-08-28] |
| ShellCheck | Portable shell validation | ✓ | `0.11.0` | Existing repository proof may install/use its pinned path in CI. [VERIFIED: local environment probe, 2026-08-28] |
| `yamllint` | YAML style/structure checks | ✓ | `1.38.0` | PyYAML-based repository structural tests remain authoritative for semantic inventory. [VERIFIED: local environment probe, 2026-08-28] |
| Git | Full-history NUL-safe classification | ✓ | `2.41.0` | None; required. [VERIFIED: local environment probe, 2026-08-28] |
| Bash | Existing repository shell scripts | ✓ | Local `5.2.37`; scripts must retain repository-tested Bash 3.2 compatibility | Use POSIX-compatible constructs or existing Bash 3.2 compatibility tests. [VERIFIED: local environment probe and repository shell-test inventory, 2026-08-28] |
| Erlang/Elixir | Focused ExUnit verification | Partial mismatch | Local Mix `1.19.5` is compiled for OTP 28; repository exact values are `"erlang 27.3"`, `"elixir 1.19.5-otp-27"`, and asdf reports Erlang 27.3 not installed. | CI's strict `setup-beam` contract is authoritative; install repository tool versions only if local toolchain parity is required. [VERIFIED: .tool-versions:1-2; local environment probe, 2026-08-28] |
| Java 17 | Local Android/Gradle proof | ✗ | `/usr/bin/java` reports no runtime | CI uses explicit JDK setup; local Android proof is unavailable until JDK 17 is installed. [VERIFIED: local environment probe; packages/crosswake-shell-core-android/build.gradle:25-26] |
| Swift/Xcode | Apple proof research/local package checks | ✓ | Swift `6.3.3`; Xcode `26.6` | GitHub macOS runner with explicitly recorded toolchain identity. [VERIFIED: local environment probe, 2026-08-28] |

**Missing dependencies with no fallback:** None for planning or repository-script development. [VERIFIED: environment audit]

**Missing dependencies with fallback:** Local Java 17 is absent; use explicit CI JDK setup or install JDK 17 before local Gradle execution. [VERIFIED: environment audit]

## Validation Architecture

Nyquist validation is enabled because `.planning/config.json` does not set `workflow.nyquist_validation` to `false`. [VERIFIED: .planning/config.json]

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit plus first-party Python/shell self-tests and actionlint. [VERIFIED: test/test_helper.exs:1; script/check_aggregator_result_semantics.py:1-156] |
| Config file | `test/test_helper.exs` with exact line `"ExUnit.start()"`; workflow checks use repository scripts rather than a separate test runner config. [VERIFIED: test/test_helper.exs:1] |
| Quick run command | `python3 script/check_aggregator_result_semantics.py --self-test && python3 script/list_merge_blocking_checks.py --emitters >/dev/null && script/check_required_checks_registered.sh --local-only && mix test test/crosswake/proof/phase165_ci_policy_test.exs test/crosswake/proof/phase165_ci_integrity_test.exs` [ASSUMED] |
| Full suite command | `script/check_phase165_efficient_ci.sh` [ASSUMED] |

Existing focused foundation verification passed during research: five Python aggregator self-tests passed, the local producer inventory reported 88 producers and 27 merge-blocking candidates, and 32 selected Phase 153.1/164 ExUnit tests passed with zero failures. [VERIFIED: local verification run, 2026-08-28]

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| CIP-01 | Every pure Elixir/Android leaf is Linux; every macOS leaf has an Apple-tool invocation; helper is portable | structural + shell integration | `mix test test/crosswake/proof/phase165_ci_integrity_test.exs --only runner_placement` | ❌ Wave 0 [ASSUMED] |
| CIP-02 | PR proof has one authoritative trigger and no equivalent push duplicate; superseded selection is exact | structural + unit | `python3 script/select_obsolete_ci_runs.py --self-test && mix test test/crosswake/proof/phase165_ci_integrity_test.exs --only triggers` | ❌ Wave 0 [ASSUMED] |
| CIP-03 | Cache keys/inputs include every required compatibility dimension and incompatible fixtures miss | structural + fixture | `mix test test/crosswake/proof/phase165_ci_integrity_test.exs --only cache_identity` | ❌ Wave 0 [ASSUMED] |
| CIP-04 | Every job timeout is bounded; lower run cancels, equal/newer/mismatch/ambiguous never cancels | structural + unit + live smoke | `python3 script/select_obsolete_ci_runs.py --self-test && mix test test/crosswake/proof/phase165_ci_integrity_test.exs --only timeout` | ❌ Wave 0 [ASSUMED] |
| CIP-05 | Adversarial docs classifier produces exact schedules; umbrella stays visible and fails missing/unexplained leaves | unit + structural + live PR probe | `python3 script/classify_ci_change.py --self-test && python3 script/check_aggregator_result_semantics.py --self-test && mix test test/crosswake/proof/phase165_ci_policy_test.exs` | ❌ Wave 0 [ASSUMED] |
| CIP-06 | Evidence schema rejects sensitive/unknown fields and computes exposed metrics reproducibly | unit + artifact inspection | `node scripts/ci_monitor.cjs test-evidence && mix test test/crosswake/proof/phase165_evidence_test.exs` | ❌ Wave 0 [ASSUMED] |
| CIP-07 | Manifest, declared jobs, static `needs`, display names, remediation commands, and producers are bijective | structural + negative fixtures | `python3 script/check_ci_leaf_manifest.py --self-test && python3 script/list_merge_blocking_checks.py --emitters >/dev/null` | ❌ Wave 0 [ASSUMED] |

### Sampling Rate

- **Per task commit:** Run the smallest affected Python self-test or tagged ExUnit case plus `actionlint` on changed workflows. [ASSUMED]
- **Per wave merge:** Run `script/check_phase165_efficient_ci.sh`, the selected Phase 164 foundation tests, actionlint, and any touched shell portability tests. [ASSUMED]
- **Phase gate:** Run the full Phase 165 script, local producer/protection audit, live strict branch-protection audit, documentation-only PR probe, executable PR probe, monotonic cancellation probe, and sanitized evidence validation before `$gsd-verify-work`. [ASSUMED]

### Wave 0 Gaps

- [ ] `test/crosswake/proof/phase165_ci_policy_test.exs` — classifier, cancellation, aggregator, and manifest negative controls. [ASSUMED]
- [ ] `test/crosswake/proof/phase165_ci_integrity_test.exs` — trigger, runner, timeout, cache, permission, and workflow topology invariants. [ASSUMED]
- [ ] `test/crosswake/proof/phase165_evidence_test.exs` — schema allowlist, redaction, cohort, and metric semantics. [ASSUMED]
- [ ] `script/check_phase165_efficient_ci.sh` — one recurring phase gate that composes the stable contracts. [ASSUMED]
- [ ] Python fixture directories for adversarial Git names/statuses, cancellation orderings, manifest omissions, and evidence payloads. [ASSUMED]
- [ ] Live probe harness/cleanup commands for docs-only visibility, lower-ID cancellation, and additive branch-protection verification. [ASSUMED]

## Security Domain

Security enforcement is enabled because `.planning/config.json` does not set `security_enforcement` to `false`. [VERIFIED: .planning/config.json]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---:|---|
| V2 Authentication | No | Phase 165 adds no end-user authentication flow; GitHub authentication remains platform/existing credential authority. [VERIFIED: phase boundary and repository workflow scope] [CITED: https://github.com/OWASP/ASVS/blob/master/4.0/en/0x11-V2-Authentication.md] |
| V3 Session Management | No | Phase 165 adds no application session; workflow run IDs are execution metadata, not user sessions. [VERIFIED: phase boundary] [CITED: https://github.com/OWASP/ASVS/blob/master/4.0/en/0x12-V3-Session-management.md] |
| V4 Access Control | Yes | Isolate `actions: write` in trusted default-branch controller; keep PR proof read-only; preserve strict branch protection and explicit trust approval. [VERIFIED: D-06 and D-10 in 165-CONTEXT.md] [CITED: https://github.com/OWASP/ASVS/blob/master/4.0/en/0x12-V4-Access-Control.md] |
| V5 Input Validation | Yes | Treat Git path bytes, SHAs, workflow IDs, PR numbers, run IDs, job results, and API JSON as untrusted; positive-validate closed schemas and fail to full proof/no cancellation/failure. [VERIFIED: D-05, D-08, D-15, D-16 in 165-CONTEXT.md] [CITED: https://github.com/OWASP/ASVS/blob/master/4.0/en/0x13-V5-Validation-Sanitization-Encoding.md] |
| V6 Cryptography | No new cryptography | Preserve full action SHA pins and GitHub token/secret handling; do not implement cryptography or secret storage in this phase. [VERIFIED: .github/actions/setup-elixir-cache/action.yml:84-98; AGENTS.md:58-69] [CITED: https://github.com/OWASP/ASVS/blob/master/4.0/en/0x14-V6-Cryptography.md] |

### Known Threat Patterns for GitHub Actions CI

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Privileged workflow executes PR code | Elevation of privilege | Never use `pull_request_target` for PR code; isolate trusted controller and minimum permission. [VERIFIED: D-06 in 165-CONTEXT.md] [CITED: https://docs.github.com/en/actions/reference/security/secure-use?learn=getting_started&learnProduct=actions] |
| Same-named fork branch shares cancellation group | Denial of service | Group by PR number, validate repository/workflow/PR identity. [VERIFIED: D-04 in 165-CONTEXT.md] |
| Older run cancels newer authority | Denial of service / Tampering | Strict lower-run-ID selection and executable inversion controls. [VERIFIED: D-05 in 165-CONTEXT.md] |
| Classifier command/path injection | Tampering / Elevation of privilege | NUL-safe argv-based Git invocation, closed status parser, no shell interpolation, full-proof fallback. [VERIFIED: D-15 and D-16 in 165-CONTEXT.md] |
| Omitted leaf silently passes umbrella | Tampering | Exact bidirectional manifest/needs/producer parity and closed fail semantics. [VERIFIED: D-08 and D-09 in 165-CONTEXT.md] |
| Untrusted PR primes privileged cache | Tampering | Complete compatibility identity, branch/cache scope, no privileged controller checkout of PR code. [VERIFIED: D-06, D-21, D-22 in 165-CONTEXT.md] [CITED: https://github.com/actions/cache] |
| Evidence stores identities, tokens, logs, or adopter facts | Information disclosure | Allowlisted normalized schema; discard raw payloads/logs; privacy scan canonical JSON and Markdown. [VERIFIED: AGENTS.md:58-69; D-30 in 165-CONTEXT.md] |
| Required-context migration creates bypass | Elevation of privilege | Additive green-first registration, strict live verification, exact retirement diff, explicit trust approval. [VERIFIED: D-10 in 165-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/165-CONTEXT.md` — all locked scope and implementation decisions. [VERIFIED: opened in full]
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` and `ROADMAP.md` — CIP-01 through CIP-07 and success criteria. [VERIFIED: opened in full]
- `AGENTS.md`, governing adopter ADR/brief/route map, project/workstream state — project, privacy, and workflow constraints. [VERIFIED: opened this session]
- `.github/workflows/*.yml`, `.github/actions/setup-elixir-cache/action.yml`, `script/*` governance/proof scripts, `scripts/ci_monitor.cjs`, and focused ExUnit proof tests — current implementation seams and inventory. [VERIFIED: opened/parsed this session]
- GitHub live APIs — strict branch protection, required contexts, active-run count, and cache count snapshot on 2026-08-28. [VERIFIED: read-only `gh api`]

### Secondary (MEDIUM confidence)

- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency?apiVersion=2022-11-28 — concurrency behavior. [CITED: official GitHub documentation]
- https://docs.github.com/en/rest/actions/workflow-runs — workflow-run fields and cancel/force-cancel operations. [CITED: official GitHub documentation]
- https://docs.github.com/en/rest/actions/workflow-jobs — job timestamp/runner fields and absence of exact queue timestamp. [CITED: official GitHub documentation]
- https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks?apiVersion=2022-11-28 — required-check skip behavior. [CITED: official GitHub documentation]
- https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax — `needs`, `always()`, and path-filter semantics. [CITED: official GitHub documentation]
- https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows — pull-request synthetic merge checkout semantics. [CITED: official GitHub documentation]
- https://docs.github.com/en/actions/reference/security/secure-use?learn=getting_started&learnProduct=actions — untrusted workflow execution boundaries. [CITED: official GitHub documentation]
- https://github.com/actions/cache — cache outputs and scope. [CITED: official action documentation]
- https://github.com/gradle/actions/blob/main/docs/setup-gradle.md — Gradle setup/caching behavior. [CITED: official action documentation]
- https://developer.apple.com/documentation/xcode/building-swift-packages-or-apps-that-use-them-in-continuous-integration-workflows — Swift resolved-package CI behavior. [CITED: official Apple documentation]
- https://owasp.org/www-project-application-security-verification-standard/ and official OWASP ASVS chapter sources — security verification category mapping. [CITED: official OWASP documentation]

### Tertiary (LOW confidence)

- None. Unverified implementation choices are isolated in the Assumptions Log. [VERIFIED: research provenance audit]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — it uses repository-local seams and already-pinned official actions; no new package is proposed. [VERIFIED: repository inventory]
- Architecture: HIGH — trigger, trust, aggregation, classifier, and evidence boundaries are locked by 33 explicit context decisions and align with official GitHub behavior. [VERIFIED: 165-CONTEXT.md and official GitHub docs]
- Pitfalls: HIGH — each critical failure mode is tied to a locked decision, current source pattern, official platform behavior, or executable Phase 164 control. [VERIFIED: cited sources above]
- Exact filenames/decomposition: LOW — intentionally discretionary and recorded as assumptions. [ASSUMED]

**Research date:** 2026-08-28
**Valid until:** 2026-09-04 for GitHub API/action behavior; repository inventory remains valid only until the next CI workflow or branch-protection change. [ASSUMED]
