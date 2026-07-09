# Phase 143: Guarded Auto-Publish Train - Context

**Gathered:** 2026-07-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 143 turns the v18 release graph into a guarded auto-publish train. It owns the happy-path publishing policy and exact-ref Hex recovery posture for Crosswake's package family:

1. Release Please outputs decide which package artifacts are released.
2. CI publishes released artifacts after the Release PR merge without maintainer-run `mix hex.publish` commands.
3. Core Hex, iOS core, and Android core remain lockstep.
4. `crosswake_*` companions remain independently versioned and independently gated.
5. Retry/recovery paths are exact-ref and idempotent: already-live exact versions are reported and proof continues instead of trying to re-publish.

This is release-ops product surface, not new runtime/product breadth. Phase 143 may validate already-present spillover in `.github/workflows/release-please.yml`, but it must not claim downstream PREF/MIRR/STAT requirements. Companion clean-room exactness remains Phase 144; native mirror/backfill parity remains Phase 145; release-status completion remains Phase 146.

</domain>

<decisions>
## Implementation Decisions

### Publish Authority Boundary
- **D-01:** Treat the Release Please Release PR merge as the human approval boundary. After that merge, CI owns package publishing for the artifacts Release Please says were released.
- **D-02:** The happy path must not require a maintainer to run `mix hex.publish` locally or dispatch a manual publish workflow.
- **D-03:** Do not use a permanent hybrid model where some package classes publish automatically and others require manual approval. It creates split-brain release truth and contradicts AUTO-01.
- **D-04:** Manual dispatch remains valid only for exact-ref recovery and fire-drills. It is not the normal publish path.
- **D-05:** First-publish caution is already past for the current published family. Future first-publish canaries may be human-gated in their own phases, but Phase 143 should make the current family train automatic.

### Idempotent Already-Live Semantics
- **D-06:** If the exact package/version/tag/coordinate expected by Release Please is already live, treat that as a successful publish state, print a clear `[crosswake] OK: ... already live` message, skip the irreversible publish command, and continue to the appropriate proof job.
- **D-07:** "Already live" is success only when identity is proven against the expected package and version. If the workflow cannot tie the live artifact to the expected Release Please output/ref, fail closed with a clear next action.
- **D-08:** Do not use `mix hex.publish --replace` as the normal recovery behavior. Hex replacement belongs only inside the narrow registry grace window after deliberate operator review.
- **D-09:** Registry immutability should be modeled as state, not as a scary error. A rerun after partial success should converge: already-published artifact -> proof -> cleanup/status, not duplicate publish failure.
- **D-10:** Publish job output should say what happened, what was skipped, and what proof or command establishes truth. Hide backend mechanics unless they change the operator's next action.

### Exact-Ref Recovery Surface
- **D-11:** Broaden `.github/workflows/hex-publish.yml` from root-only recovery to component-aware Hex recovery for `crosswake`, `crosswake_rulestead`, `crosswake_rindle`, `crosswake_sigra`, `crosswake_chimeway`, and `crosswake_threadline`.
- **D-12:** Keep Phase 143 recovery scoped to Hex packages only. SwiftPM mirror recovery, Maven Central recovery, and the missing iOS `v0.2.0` mirror backfill belong to Phase 145.
- **D-13:** Recovery workflow inputs should be explicit and hard to misuse: package/component, exact ref, and expected release version. Reject branch names; accept tags or full commit SHAs; resolve and print the checked-out SHA before publishing.
- **D-14:** Recovery must reuse the same idempotency policy as the automatic train: preflight registry presence, report already-live exact versions as success, otherwise dry-run then publish, then poll/verify registry presence.
- **D-15:** Map each Hex package to its working directory, version file, dependency-release env, test command, and publish command in one maintained package map or helper. Avoid copy/paste divergence between root and companion recovery logic.

### Package Eligibility And Compatibility Floors
- **D-16:** The train covers every configured package in the current release graph: root Hex, iOS core, Android core, and all five `crosswake_*` companions.
- **D-17:** Preserve the current versioning model: root Hex + iOS core + Android core are the only lockstep linked group; all companions remain independently versioned Release Please components.
- **D-18:** Preserve honest companion floors. `rulestead` and `rindle` may keep publishing against `~> 0.1`; `sigra`, `chimeway`, and `threadline` require `~> 0.2`. Do not bump older companion floors to `~> 0.2` for automation convenience.
- **D-19:** Mixed floors are not a problem to hide; they are release truth. Surface them in docs/status output so maintainers and adopters can see why each package requires its floor.
- **D-20:** If a companion later uses a `0.2`-only core API, bump that package's floor in the package's own release. Do not preemptively constrain adopters of older-compatible companions.

### Proof And Guardrails
- **D-21:** Extend the Phase 142 semantic workflow proof rather than relying on code review. The proof should lock idempotent publish preflight/reporting, component-aware Hex recovery, exact-ref checkout, and continued proof after already-live detection.
- **D-22:** Keep exact Release Please path/component gates from Phase 142. Aggregate `releases_created` remains allowed only for summaries/logging, never for publish, proof, cleanup, mirror, or recovery behavior.
- **D-23:** Cleanup after companion release remains publish+proof gated. A publish job that reports exact already-live success counts as publish success only when proof still runs and passes.
- **D-24:** Keep GitHub Actions release concurrency non-canceling with `queue: max`; release runs should not disappear when multiple Release PRs land close together.
- **D-25:** Use small named scripts/helpers and ExUnit assertions where they improve readability. The planner may choose exact factoring, but the final operator path must be easier to reason about than duplicated YAML shell fragments.

### Developer Experience And Operator UX
- **D-26:** The user-facing surface is CI logs, workflow names, recovery workflow inputs, docs/runbook copy, and release-status output. There is no graphical UI requirement in this phase.
- **D-27:** Follow the current Brand Spec: calm, explicit, technical, and honest. Prefix release logs with `[crosswake]`; avoid "magic", "seamless", or vague success language.
- **D-28:** Use nouns/operators that match the domain: package, component, release ref, version, registry, live artifact, proof, cleanup PR, recovery.
- **D-29:** Favor the operator's JTBD: "Did this package publish? If not, is the exact version already live? What proof ran? What is the next safe command?" Do not expose low-level Release Please internals unless needed to choose the next action.
- **D-30:** JSON/status consumers should receive structured state, not prose scraping. Phase 146 owns the full release-status DX, but Phase 143 should not introduce log shapes that make STAT harder.

### Ecosystem Lessons Applied
- **D-31:** Hex and Maven Central both reward immutable-release thinking. Normal recovery is roll-forward or exact already-live detection, not overwrite attempts.
- **D-32:** Release Please, Lerna, Nx, and Changesets all reinforce package identity as first-class in monorepos. Crosswake should keep exact package membership visible instead of using a broad "something released" flag.
- **D-33:** GitHub Actions `queue: max` now supports queued release/deploy runs. This is appropriate for release workflows where older pending release runs must not be replaced.
- **D-34:** SwiftPM tags and Maven artifacts have different recovery semantics from Hex. Do not generalize Hex recovery into native registry behavior in Phase 143.

### Claude's Discretion
The user asked for all gray areas to be researched and a one-shot recommendation set. Downstream agents may choose implementation mechanics such as helper script names, exact workflow input names, or test factoring, but should not revisit the policy choices above unless official registry/API behavior contradicts them.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning And Prior Decisions
- `.planning/PROJECT.md` - v18 release-integrity thesis, constraints, and no-product-breadth boundary.
- `.planning/REQUIREMENTS.md` - AUTO-01, AUTO-02, AUTO-03 scope and traceability.
- `.planning/ROADMAP.md` - Phase 143 ordering relative to PREF, MIRR, and STAT phases.
- `.planning/STATE.md` - current position and already-present implementation spillover notes.
- `.planning/MILESTONE-ARC.md` - v18 key output: guarded auto-publish train with exact-ref/idempotent recovery.
- `.planning/phases/142-release-graph-governance-contract/142-CONTEXT.md` - exact gates, concurrency, cleanup-after-proof, and proof posture.
- `.planning/phases/141-core-first-publish-family-release/141-CONTEXT.md` - core-first publish failure root cause and companion floor decisions.
- `.planning/phases/140-family-discipline-close/140-CONTEXT.md` - family release discipline, release-as cleanup, and independent companion versioning.

### Project Voice And Research Prompts
- `brandbook/BRAND-SPEC.md` - current brand voice; supersedes `prompts/crosswake-brand-book.md`.
- `prompts/crosswake-elixir-oss-dna.md` - release truth, proof lanes, recovery-conscious publishing, and operator-surface principles.
- `prompts/crosswake-gsd-project-brief.md` - CI/CD, release discipline, proof posture, and recovery-conscious release flow as product features.
- `prompts/crosswake-integrations-and-companions.md` - companion classification and first-party package-family posture.
- `prompts/crosswake-research-synthesis.md` - route/runtime thesis and anti-scope guardrails.
- `prompts/elixir-mobile-oss-lib-deep-research.md` - monorepo release targets, Hex/SPM/Maven release orchestration, and roll-forward posture.
- `prompts/elixir-mobile-apptypes-design-stresstest-deep-research.md` - package-family and version-negotiation lessons.

### Local Release Code
- `.github/workflows/release-please.yml` - automatic release graph, exact gates, publish jobs, clean-room proof jobs, cleanup, and failure alert.
- `.github/workflows/hex-publish.yml` - current root-only manual Hex recovery workflow to broaden.
- `release-please-config.json` - linked root/native group and independent companion components.
- `.release-please-manifest.json` - current package versions used by release status and Release Please.
- `script/check_release_workflow_integrity.exs` - semantic workflow proof to extend.
- `test/crosswake/proof/phase142_release_integrity_test.exs` - ExUnit wrapper and negative fixtures for release workflow integrity.
- `script/check_release_as_staleness.sh` - stale `release-as` guard.
- `script/strip_release_as.py` - idempotent cleanup helper.
- `script/verify_companion_cleanroom.sh` - companion proof path; Phase 144 owns deeper PREF validation.
- `lib/crosswake/release_status.ex` - local release graph/status model; Phase 146 owns final status DX.
- `lib/mix/tasks/crosswake.release.status.ex` - operator-facing status task.
- `docs/COMPANION-PUBLISH-RUNBOOK.md` - older human-gated runbook that Phase 143 planning should reconcile with the automated train.
- `guides/companion_compatibility.md` - companion version/floor truth.
- `packages/crosswake_rulestead/mix.exs` - older companion floor `~> 0.1`.
- `packages/crosswake_rindle/mix.exs` - older companion floor `~> 0.1`.
- `packages/crosswake_sigra/mix.exs` - newer companion floor `~> 0.2`.
- `packages/crosswake_chimeway/mix.exs` - newer companion floor `~> 0.2`.
- `packages/crosswake_threadline/mix.exs` - newer observer package floor `~> 0.2`.

### External Primary References Consulted
- `https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax` - concurrency `queue: max`, `cancel-in-progress`, `needs`, and workflow dispatch syntax.
- `https://docs.github.com/en/actions/reference/workflows-and-actions/expressions` - `fromJSON` and expression behavior used for exact path gates.
- `https://docs.github.com/en/actions/reference/workflows-and-actions/contexts` - `needs`, `github`, `inputs`, and workflow context references.
- `https://github.com/googleapis/release-please-action#outputs` - Release Please outputs, path-prefixed outputs, `paths_released`, and release-created semantics.
- `https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html` - Hex publish, dry-run, replace, revert, and docs publishing behavior.
- `https://hex.pm/docs/publish` - Hex package metadata and pre-1.0 SemVer guidance.
- `https://hex.pm/docs/faq` - Hex immutability, 60-minute package-version exception, retire guidance, and checksum implications.
- `https://central.sonatype.org/publish/requirements/immutability/` - Maven Central immutability and roll-forward recommendation.
- `https://lerna.js.org/docs/features/version-and-publish` - fixed vs independent monorepo release modes and `from-package` publish identity.
- `https://nx.dev/docs/guides/nx-release/release-projects-independently` - independent project releases, per-project tags, and filtering.
- `https://nx.dev/docs/features/manage-releases` - release phases: versioning, changelog, publishing, and custom release workflows.
- `https://changesets-docs.vercel.app/detailed-explanation.html` - multi-package versioning, changeset intent, and package interdependency lessons.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.github/workflows/release-please.yml`: already contains exact path/component gates, publish jobs for root/native/all companions, clean-room proof jobs, `queue: max`, cleanup-after-proof, and failure alert. Main gap: Hex publish jobs do not preflight/report already-live versions before `mix hex.publish`.
- `.github/workflows/hex-publish.yml`: existing manual recovery workflow with exact ref + expected version inputs for root Hex. It is the natural surface to broaden to component-aware root+companion Hex recovery.
- `script/check_release_workflow_integrity.exs`: right place to add semantic checks for idempotent publish behavior and component-aware recovery.
- `script/check_release_as_staleness.sh` and `script/strip_release_as.py`: existing idempotent tooling pattern for release maintenance.
- `lib/crosswake/release_status.ex`: already models lockstep core/native, independent companions, release-as staleness, live registry probes, and downstream phase warnings.
- `script/verify_companion_cleanroom.sh`: already derives exact package/floor information, but Phase 144 owns clean-room proof exactness.

### Established Patterns
- Release safety is expressed through named jobs, small scripts, and ExUnit proof, not only comments or manual checklist discipline.
- Behavioral jobs gate on exact Release Please identity: `paths_released` for root/native and per-component aliases for companions.
- Registry proof is part of release truth. Publishing and clean-room proof should converge to a verified external artifact.
- Operator copy uses `[crosswake]` and names the failure plus next action.
- Core/native lockstep and companion independence are both intentional; neither should erase the other.

### Integration Points
- Automatic Hex idempotency connects to every `publish-hex*` job in `.github/workflows/release-please.yml`.
- Recovery idempotency connects to `.github/workflows/hex-publish.yml`.
- Proof expansion connects to `script/check_release_workflow_integrity.exs` and `test/crosswake/proof/phase142_release_integrity_test.exs`.
- Floor truth connects to `packages/crosswake_*/mix.exs`, `guides/companion_compatibility.md`, `release-please-config.json`, and `.release-please-manifest.json`.
- Later release-status presentation connects to `lib/crosswake/release_status.ex` and `lib/mix/tasks/crosswake.release.status.ex`, but final STAT behavior remains Phase 146.

</code_context>

<specifics>
## Specific Ideas

Recommended `hex-publish.yml` recovery input shape:

- `package`: enum-like package choice, one of `crosswake`, `crosswake_rulestead`, `crosswake_rindle`, `crosswake_sigra`, `crosswake_chimeway`, `crosswake_threadline`.
- `ref`: exact release tag or full commit SHA. Reject plain branch names.
- `release_version`: expected version in the target package's `mix.exs`.

Recommended Hex idempotency flow:

1. Resolve checkout ref and print the SHA.
2. Verify package/version in the correct `mix.exs`.
3. Query `https://hex.pm/api/packages/{package}/releases/{version}`.
4. If present, print `[crosswake] OK: {package} {version} is already live on Hex.pm; no publish attempted.` and exit the publish step successfully.
5. If absent, run the existing compile/test/dry-run/publish sequence.
6. Poll Hex until the exact version appears.
7. Continue clean-room proof or recovery verification.

Recommended proof additions:

- Check every Hex publish path has an already-live preflight before `mix hex.publish --yes`.
- Check the manual Hex recovery workflow accepts package/ref/version and rejects branch-shaped refs.
- Check recovery has a maintained package map for package -> working directory/version file/env/test command.
- Check no normal path uses `--replace`.
- Add negative fixtures for duplicate-publish-only behavior and root-only recovery.

Recommended copy style:

- Success: `[crosswake] OK: crosswake_sigra 0.1.1 is already live on Hex.pm; no publish attempted. Continuing to clean-room proof.`
- Failure: `[crosswake] FAIL: crosswake_sigra 0.1.1 is live, but this run cannot prove it matches the expected release ref. Stop and inspect the GitHub release/tag before retrying.`

</specifics>

<deferred>
## Deferred Ideas

- Native registry recovery/backfill for SwiftPM and Maven Central belongs to Phase 145.
- The missing iOS `v0.2.0` mirror tag backfill belongs to Phase 145.
- Clean-room exact companion install/floor derivation is validated in Phase 144.
- Full release-status text/JSON/live-probe completion belongs to Phase 146.
- A graphical dashboard/operator UI remains DASH-01 and is out of scope for v18 Phase 143.
- Broad YAML parsing or a new workflow parser dependency remains deferred unless the semantic checker becomes broad workflow inventory.
- New product integrations, native capability breadth, offline-sync productization, and `crosswake_dashboard` remain deferred behind v18 release integrity.

</deferred>

---

*Phase: 143-Guarded Auto-Publish Train*
*Context gathered: 2026-07-07*
