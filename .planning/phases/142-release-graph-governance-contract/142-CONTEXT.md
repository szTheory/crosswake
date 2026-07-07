# Phase 142: Release Graph & Governance Contract - Context

**Gathered:** 2026-07-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 142 defines the release graph governance contract for v18: exact release identity, non-canceling publish/proof behavior, and merge-blocking proof that the workflow cannot reintroduce the v17 release footguns.

The current worktree already contains implementation spillover for later v18 phases: companion clean-room precision, iOS mirror preflight, release status CLI, and doctor/router loading. Do not perform git surgery just to recreate a narrow phase boundary. Treat Phase 142 as the governance entry point for the broader v18 release-integrity slice, while keeping requirement ownership honest:

- Phase 142 may lock RELG-01..03 and document the current release-ops surface.
- Phase 144, 145, and 146 must still verify/reconcile their own requirements before being claimed complete.
- Planning must call out already-present implementation as "existing work to validate", not as automatically finished downstream scope.

</domain>

<decisions>
## Implementation Decisions

### Phase Boundary And Traceability
- **D-01:** Keep the current bundled v18 release-integrity worktree intact. Reverting or splitting it would add risk without improving runtime correctness.
- **D-02:** Downstream plans must map each file/test to its owning requirement: RELG for graph/proof governance, PREF for clean-room dependency precision, MIRR for native mirror/decoupling, and STAT for operator status.
- **D-03:** Phase 142 should not claim UI/product breadth. The product surface here is release automation, proofs, docs, CLI/status output, and failure microcopy.

### Release Identity And Gates
- **D-04:** Use exact gates for every behavioral job. Behavioral means publish, proof, cleanup, recovery, mirror, or any job that mutates state or creates an operator signal.
- **D-05:** Allow aggregate `releases_created` only for non-destructive summaries, high-level alerts, or logging. It must not gate `publish-*`, `clean-room-proof-*`, `release-as-cleanup`, recovery, or mirror jobs.
- **D-06:** Root Hex and native core jobs gate on `paths_released` parsed with `fromJSON`. Root uses `.`, iOS uses `packages/crosswake-shell-core-ios`, and Android uses `packages/crosswake-shell-core-android`.
- **D-07:** Companion/observer jobs gate on per-component aliases such as `rulestead_release_created == 'true'`. Slash-containing Release Please path outputs should be aliased in the release job outputs and consumed with dot notation downstream.
- **D-08:** Treat GitHub Actions outputs as strings unless explicitly parsed. Avoid substring checks on JSON strings; `contains(fromJSON(paths_released), item)` is the intended form for path identity.
- **D-09:** Preserve the root/native lockstep group only for root Hex, iOS core, and Android core. Rulestead, Rindle, Sigra, Chimeway, and Threadline stay independently versioned and independently gated.

### Concurrency And Run Replacement
- **D-10:** `cancel-in-progress: false` is necessary but not sufficient for "no release run disappears." GitHub Actions currently replaces an older pending run in the same concurrency group unless `queue: max` is set.
- **D-11:** Phase 142 planning should add or explicitly justify `queue: max` for the Release Please workflow if RELG-02 means both running and pending release work must not be replaced.
- **D-12:** Keep release/proof concurrency workflow-level, narrow to the release workflow/ref, and avoid cross-run `needs`. Release ordering between runs stays a runbook/operator concern until a later automation phase owns it.

### Release-As Cleanup
- **D-13:** `release-as-cleanup` should open only after the released companion's Hex publish and post-publish clean-room proof both succeed. In Crosswake, clean-room proof is release truth, not advisory noise.
- **D-14:** The cleanup job should keep `always()` so it can evaluate after skipped/failed needs, but its condition must use per-component implications: unreleased companions may be `skipped`; a released companion must have both publish and proof `success`.
- **D-15:** Do not use a blanket "no skipped needs" guard for cleanup. Skips are expected for components not released in the current run.
- **D-16:** Cleanup must open a PR only. It must not mutate protected `main` directly. On publish/proof failure, rely on `release-failure-alert`, exact-ref/idempotent rerun, or deliberate manual cleanup after proof recovery.
- **D-17:** The current workflow only waits for companion publish jobs before cleanup. Treat this as an implementation gap to reconcile during Phase 142 planning/execution.

### Proof Surface
- **D-18:** Keep `script/check_release_workflow_integrity.exs` plus ExUnit as the primary Phase 142 proof. This is idiomatic for this repo: fast, deterministic, no new dependency, and close to Mix/ExUnit operator workflows.
- **D-19:** Harden the scanner around named semantic invariants instead of replacing it with a YAML dependency. Required invariants include exact gates, `queue: max`/non-canceling concurrency, native proof decoupling, mirror preflight, cleanup-after-proof, and aggregate-gate negative controls.
- **D-20:** Add adversarial fixture or helper coverage before broadening the scanner: comment-only false passes, aggregate `releases_created` in proof/cleanup jobs, native cross-dependency regressions, missing `queue: max`, and cleanup that ignores proof results.
- **D-21:** `actionlint` is a useful pinned additive lane for syntax/expression mistakes, ShellCheck/Pyflakes integration, and `needs` errors. It must not replace the Crosswake semantic proof because it cannot know Release Please identity policy.
- **D-22:** Do not add a structured YAML parser unless the workflow integrity proof becomes broad workflow inventory. Generic YAML parsing still will not understand GitHub Actions expression semantics, and a new dependency is not worth it for the current targeted contract.

### Developer Experience And Operator UX
- **D-23:** Treat Mix tasks and scripts as user-facing product surface. Public tasks should follow Mix conventions: `Mix.Tasks.*`, `use Mix.Task`, helpful `@shortdoc`, actionable `@moduledoc`, and clear `run/1` parsing.
- **D-24:** CLI and CI output should use the brand voice from `brandbook/BRAND-SPEC.md`: calm, specific, actionable, and prefixed with `[crosswake]` where appropriate.
- **D-25:** Prefer named verification commands over opaque shell chains. Good examples are `mix crosswake.release.status`, `mix crosswake.doctor --router`, and `elixir script/check_release_workflow_integrity.exs`.
- **D-26:** Hide backend mechanics from operators unless the detail changes the next action. Report release state as "what happened", "what is safe to do next", and "what command/source proves it".
- **D-27:** For this phase there is no graphical UI requirement. UI/UX applies to CLI text, GitHub issue/PR copy, docs/runbooks, and machine-readable JSON output.

### Ecosystem Lessons
- **D-28:** Hex publish is effectively irreversible after a short update/revert window. Clean-room install/compile proof belongs after publish and before "done" operator signals.
- **D-29:** Successful monorepo release tools treat package/project identity as first-class. Changesets linked packages, Lerna independent mode, Nx independent release groups, and Release Please path outputs all reinforce the same lesson: do not infer exact package identity from an aggregate "something released" flag.
- **D-30:** Keep Release Please pinned output behavior explicit. The workflow currently pins `googleapis/release-please-action` v4.1.3; any upgrade to the current major must revalidate output names, path aliases, and manifest behavior before landing.

### Claude's Discretion
The user asked for one-shot recommendations across all gray areas. Downstream agents may choose implementation mechanics, but should not revisit the core policy choices above unless live docs or CI behavior contradict them.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning And Requirements
- `.planning/PROJECT.md` - v18 thesis, constraints, non-goals, and release integrity direction.
- `.planning/REQUIREMENTS.md` - RELG-01..03, AUTO-01..03, PREF-01..03, MIRR-01..03, and STAT-01..03 traceability.
- `.planning/ROADMAP.md` - Phase 142 through 146 ordering and success criteria.
- `.planning/STATE.md` - current position and already-started implementation notes.
- `.planning/phases/141-core-first-publish-family-release/141-CONTEXT.md` - prior release family contract and proof posture.
- `.planning/phases/140-family-discipline-close/140-CONTEXT.md` - family discipline and release-as cleanup history.
- `.planning/phases/139-crosswake-threadline-extraction/139-CONTEXT.md` - Threadline package boundary and zero-sibling-dep posture.

### Brand, Research, And Prompts
- `brandbook/BRAND-SPEC.md` - current brand voice; supersedes older prompt brandbook notes.
- `prompts/crosswake-elixir-oss-dna.md` - install truth, proof lanes as product, doctor/status ergonomics.
- `prompts/crosswake-integrations-and-companions.md` - optional companions and operator-truth integration posture.
- `prompts/crosswake-research-synthesis.md` - route/runtime boundary and proof-matrix lessons.
- `prompts/crosswake-gsd-project-brief.md` - release discipline, recovery-conscious CI, support matrix expectations.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` - doctor task and troubleshooting UX guidance.
- `prompts/elixir-mobile-oss-lib-deep-research.md` - monorepo/separate artifact release lessons.
- `prompts/elixir-mobile-apptypes-design-stresstest-deep-research.md` - version negotiation and integration footguns.

### Local Release Code
- `.github/workflows/release-please.yml` - release graph, publish/proof/cleanup jobs, gates, and concurrency policy.
- `release-please-config.json` - root/native linked group, independent companion packages, `release-as` pins.
- `.release-please-manifest.json` - manifest source of released package versions.
- `script/check_release_workflow_integrity.exs` - current semantic workflow proof.
- `test/crosswake/proof/phase142_release_integrity_test.exs` - ExUnit proof wrapper and negative checks.
- `script/verify_companion_cleanroom.sh` - companion clean-room dependency derivation and smoke proof.
- `lib/crosswake/release_status.ex` - release status model and local/live probes.
- `lib/mix/tasks/crosswake.release.status.ex` - operator-facing release status task.
- `lib/mix/tasks/crosswake.doctor.ex` - router/loadpaths behavior that later PREF work must validate.
- `guides/companion_compatibility.md` - companion compatibility/operator docs surface.

### External Primary References Consulted
- `https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#concurrency` - `cancel-in-progress`, pending replacement, and `queue: max`.
- `https://docs.github.com/en/actions/reference/workflows-and-actions/expressions` - `contains`, `fromJSON`, `always`, and failure status functions.
- `https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#needs-context` - `needs.<job_id>.result` semantics.
- `https://github.com/googleapis/release-please-action#outputs` - `releases_created`, `paths_released`, root outputs, and path-prefixed outputs.
- `https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md` - manifest mode, monorepo package config, and `release-as`.
- `https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html` - Hex publish, dry-run, update/revert windows, and package dependency behavior.
- `https://hexdocs.pm/mix/Mix.Task.html` - idiomatic Mix task shape, docs, shortdoc, and requirements.
- `https://github.com/rhysd/actionlint` - GitHub Actions lint capabilities and limits.
- `https://github.com/changesets/changesets/blob/main/docs/linked-packages.md` - linked package identity and package-selection lessons.
- `https://lerna.js.org/docs/features/version-and-publish` - fixed vs independent versioning and `from-package` publish identity.
- `https://nx.dev/docs/guides/nx-release/release-projects-independently` - independent release groups and dependent update considerations.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.github/workflows/release-please.yml`: already contains exact root/native path gates and companion per-component gates; needs reconciliation for `queue: max` and cleanup-after-proof.
- `script/check_release_workflow_integrity.exs`: good base for RELG proof; should gain stronger job-block invariants and negative controls.
- `test/crosswake/proof/phase142_release_integrity_test.exs`: correct place to make the proof merge-blocking through ExUnit.
- `script/verify_companion_cleanroom.sh`: already derives the core floor and exact companion package version; later PREF plans should own deeper validation.
- `lib/crosswake/release_status.ex` and `lib/mix/tasks/crosswake.release.status.ex`: already model operator-facing release status; later STAT plans should validate JSON/text/live behavior.
- `lib/mix/tasks/crosswake.doctor.ex`: relevant because clean-room proof invokes doctor after dependency installation.

### Established Patterns
- Release safety is expressed as named ExUnit proof lanes plus small scripts, not as hidden CI-only shell fragments.
- Mix tasks are the idiomatic Elixir UX for operator commands. Keep them documented, deterministic by default, and explicit when they go live/networked.
- Release Please is used in manifest mode with a linked root/native group and independent companion packages. Preserve that mental model.
- Brand guidance favors quiet operational clarity. Avoid "magic" or "seamless" copy; name exact failure causes and next commands.

### Integration Points
- Phase 142 changes connect primarily to `.github/workflows/release-please.yml`, `script/check_release_workflow_integrity.exs`, and `test/crosswake/proof/phase142_release_integrity_test.exs`.
- Cleanup-after-proof changes connect to companion proof jobs and `release-as-cleanup` conditions.
- `queue: max` belongs under top-level workflow `concurrency`.
- Later phases should validate `verify_companion_cleanroom.sh`, iOS mirror behavior, and release status tasks against their own requirements.

</code_context>

<specifics>
## Specific Ideas

Recommended release gate examples:

- Root Hex: `contains(fromJSON(needs.release-please.outputs.paths_released), '.')`
- iOS core: `contains(fromJSON(needs.release-please.outputs.paths_released), 'packages/crosswake-shell-core-ios')`
- Android core: `contains(fromJSON(needs.release-please.outputs.paths_released), 'packages/crosswake-shell-core-android')`
- Companion: `needs.release-please.outputs.<component>_release_created == 'true'`

Recommended cleanup semantics:

- `release-as-cleanup` needs `release-please`, all companion publish jobs, and all companion clean-room proof jobs.
- The condition keeps `always()`.
- For each released component, publish and proof must both be `success`.
- Unreleased components may be `skipped`.
- The job opens a cleanup PR and writes clear `[crosswake]` output when nothing needs stripping.

Recommended proof expansion:

- Add check IDs for `release.concurrency.queue_max`, `release.cleanup.after_publish_and_proof`, and `release.aggregate_gate.behavioral_jobs_absent`.
- Add negative coverage for aggregate `releases_created` in proof/cleanup/recovery/mirror jobs.
- Add a comment-only false-pass fixture or helper if the scanner starts matching explanatory comments.

</specifics>

<deferred>
## Deferred Ideas

- Release Please major upgrade: defer unless explicitly scheduled. The current workflow pins v4.1.3; revalidate output names and manifest behavior before any upgrade.
- Full YAML parsing: defer until the semantic checker becomes broad workflow inventory.
- Live release rehearsal automation beyond current proof lanes: belongs to AUTO phases.
- Companion clean-room exactness, iOS mirror observability, and release status CLI completion: validate in phases 144, 145, and 146 respectively.
- Graphical dashboard/UI: out of scope for Phase 142. CLI text, JSON, GitHub issue copy, and docs are the user-facing surfaces for this phase.
- Product integrations beyond release integrity: out of scope. Preserve Crosswake's Phoenix-first route-policy/runtime-contract thesis.

</deferred>

---

*Phase: 142-Release Graph & Governance Contract*
*Context gathered: 2026-07-07*
