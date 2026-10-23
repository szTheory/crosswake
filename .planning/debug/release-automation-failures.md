---
status: fixing
trigger: "Unblock automated integration, E2E, smoke, and seam validation so the release path requires zero human verification where automation is feasible."
created: 2026-09-23
updated: 2026-09-25T11:47:10-04:00
audit_acknowledged:
  milestone: v23.0
  at: 2026-10-11
  status: fixing
---

# Release Automation Failures

## Symptoms

- expected_behavior: The protected merge-bound core release should automatically publish Hex, mirror iOS, deploy Maven, and then run all downstream smoke, integration, E2E, and exact-public-proof checks without human UAT.
- actual_behavior: Release Please run 35898407350 published Hex 0.2.3 but the iOS mirror and Maven Central jobs failed; downstream rollups failed and cleanroom/exact-public-proof jobs were skipped.
- error_messages: The initial CI-monitor request could not reach api.github.com from the sandbox. Direct post-run observations recorded Maven POM HTTP 404 and no iOS v0.2.3 mirror tag.
- timeline: Began on the merge-bound ordinary release after protected merge 4df029d3799d2db18003471019c42126878572f8 on 2026-09-23; the historical Gate 1 / REL-10 breach remains separate.
- reproduction: Merge an approved fresh release candidate through the protected path and observe the ordinary Release Please workflow graph.

## Current Focus

- bug_class: bohrbug
- reasoning_checkpoint:
    hypothesis: The linked-release-rollup job fails before writing linked-release-status.json because its clean GitHub runner invokes project code through `mix run --no-start` without first fetching the locked Mix dependencies.
    confirming_evidence:
      - Run 35898407350 explicitly reported unavailable Phoenix/Jason/Telemetry dependencies and instructed `mix deps.get` immediately before the rollup evaluator failed.
      - The complete job block contains checkout and setup-beam followed directly by `Crosswake.ReleaseCandidate.Workflow.evaluate_cli!()`; it contains no dependency-fetch step.
    falsification_test: A clean-job reproduction or workflow inspection showing locked dependencies are fetched before the evaluator, or showing the evaluator succeeds and writes the artifact with project dependencies absent, would disprove the hypothesis.
    fix_rationale: Add the same locked dependency-resolution command already used by the trusted rehearsal workflow before the evaluator, and assert its existence and order so the evaluator can load project modules without changing rollup semantics.
    blind_spots: The full hosted-run environment will not be republished or rerun under this task; Maven and iOS publication failures are separate and remain unresolved until exact existing-run logs identify them.
    candidate_causes:
      - config: the linked-release-rollup workflow omits `mix deps.get --check-locked` before invoking project code.
      - environment: GitHub-hosted jobs start from a clean checkout with no repository `deps/`, exposing the omitted setup; a developer checkout may mask it.
      - code: the evaluator itself could have loaded only standard-library modules, but the observed missing application list and project dependency graph refute that alternative.
    and_gate: No for the linked-rollup crash; the omitted dependency fetch on a clean runner is sufficient. The overall release has independent Maven and iOS publication failures, but neither is required for this evaluator/bootstrap failure.
- hypothesis: Confirmed for the linked-release-rollup dependency-order defect; Maven and iOS remain separate unresolved contributors.
- test: Linked-rollup fix check — workflow-contract regression requires locked dependency resolution before evaluator invocation; verified green on 2026-09-25.
- expecting: The test passes because `mix deps.get --check-locked` precedes `evaluate_cli!()`.
- next_action: Retrieve the Maven and iOS publish-job logs for existing run 35898407350 using narrow per-job queries; keep those publication failures separate from the fixed linked-rollup dependency-order defect. Do not republish or dispatch a release.

## Evidence

- timestamp: 2026-09-23T16:00:00-04:00
  checked: Phase 0 durable debug knowledge base
  found: .planning/debug/knowledge-base.md does not exist, so no prior resolved-session candidate is available.
  implication: Proceed with fresh initial evidence gathering; no known-pattern hypothesis receives priority.
- timestamp: 2026-09-23T16:00:00-04:00
  checked: Release-automation source inventory
  found: The repository has a primary .github/workflows/release-please.yml, dedicated iOS backfill and Maven fire-drill workflows, scripts/ci_monitor.cjs, release-candidate evaluator modules, and focused workflow/proof tests.
  implication: The failure can be investigated from repository-owned workflow contracts and captured CI logs without dispatching any publication action.
- timestamp: 2026-09-23T16:00:00-04:00
  checked: Worktree and monitor capabilities
  found: The worktree already contains unrelated planning edits; the debug file is untracked. scripts/ci_monitor.cjs provides read-only log-failed, grep, test-summary, and run-inspection commands for an existing run.
  implication: Preserve all pre-existing planning changes and use the repository monitor against run 35898407350 rather than calling publication workflows.
- timestamp: 2026-09-23T16:00:00-04:00
  checked: Complete implicated workflow jobs in .github/workflows/release-please.yml
  found: linked-release-rollup checks out the merge and sets up Beam, then immediately runs `mix run --no-start -e 'Crosswake.ReleaseCandidate.Workflow.evaluate_cli!()'`; it has no Hex/Rebar installation or `mix deps.get`. Its always-run upload requires linked-release-status.json. The clean-room jobs depend directly on their respective publication jobs, and exact-public-proof depends on both publication and both clean-room jobs.
  implication: A missing dependency can make the evaluator fail before it writes linked-release-status.json, which independently makes the upload fail and prevents the diagnostic artifact; publication failures also force clean-room and exact-public proof skips by graph dependency.
- timestamp: 2026-09-23T16:00:00-04:00
  checked: Existing run 35898407350 through scripts/ci_monitor.cjs
  found: The run had 23 jobs: 4 success, 4 failure, 15 skipped. The failures were Android Maven publish, iOS mirror publish, native release rollup, and linked release rollup. The linked rollup log explicitly reports unavailable `phoenix_live_view`, `nimble_options`, `ex_doc`, `telemetry`, `jason`, and `phoenix`, instructs `mix deps.get`, then fails; the artifact upload separately fails because linked-release-status.json was never created.
  implication: The dependency-order root cause for linked-release-rollup is directly confirmed, and the absent status artifact is a consequence of that evaluator failure. The two platform publications remain separate contributing failures whose exact mechanisms must be extracted.
- timestamp: 2026-09-23T16:00:00-04:00
  checked: Broad repository-monitor grep over run 35898407350
  found: scripts/ci_monitor.cjs failed with `spawnSync gh ENOBUFS` while collecting the complete run log before filtering.
  implication: The monitor's grep implementation cannot safely process this large run with a broad query; continue with narrower queries or per-job log retrieval while retaining the successful monitor summary/log-failed evidence.
- timestamp: 2026-09-23T15:27:33-04:00
  checked: Complete linked-release-rollup job and focused release workflow tests
  found: The job performs checkout and setup-beam, then invokes the evaluator without dependency resolution. `Crosswake.ReleaseCandidate.WorkflowTest` already isolates this job with `job_block/2`, and the trusted Hex rehearsal establishes `mix deps.get --check-locked` as the repository's locked dependency-resolution pattern.
  implication: A minimal structural regression can require that exact command before the evaluator, then the workflow can add one scoped setup step without changing publication behavior or rollup semantics.
- timestamp: 2026-09-25T11:47:10-04:00
  checked: `MIX_ENV=test mix test test/crosswake/release_candidate/workflow_test.exs:242 --max-cases 1`
  found: The linked-rollup dependency-order regression passes (1 test, 0 failures) against the current working tree.
  implication: The linked-rollup issue is fixed and verified locally; Maven and iOS publication failures remain unresolved and require existing-run evidence only.

## Eliminated

## Resolution

- root_cause: Confirmed linked-release-rollup cause — the workflow invokes the Mix evaluator on a clean runner before fetching locked project dependencies, so compilation/load fails and linked-release-status.json is never written. Maven and iOS publication causes remain unresolved independent contributors.
- oracle_type: specified — the workflow contract requires dependency resolution before invoking project code, using the repository's locked `mix deps.get --check-locked` command.
- fix: Resolve locked Mix dependencies in the applicable linked-release-rollup path before invoking the evaluator, with a regression test that asserts the ordering.
- verification: `MIX_ENV=test mix test test/crosswake/release_candidate/workflow_test.exs:242 --max-cases 1` — 1 test, 0 failures.
- files_changed: .github/workflows/release-please.yml; test/crosswake/release_candidate/workflow_test.exs
