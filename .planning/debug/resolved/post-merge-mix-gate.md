---
status: resolved
trigger: "Investigate and fix the post-merge mix test gate failures after quality-ratchet-release Plan 175-54 (2,048 tests, 25 failures, 4 invalidated setups); preserve unrelated dirty workspace changes and do not replay Plan 175-54 or any source/tag attempt."
created: 2026-09-30
updated: 2026-09-30
---

# Post-merge Mix Test Gate Failures

## Symptoms

- expected_behavior: The post-merge Mix test gate completes successfully, with no failures or invalidated setups.
- actual_behavior: After quality-ratchet-release Plan 175-54 merged, the Mix test gate reported 2,048 tests, 25 failures, and 4 invalidated setups.
- error_messages: The aggregate counts are available; individual failure and invalidated-setup diagnostics have not yet been located. Reproduce and capture them before selecting a cause.
- timeline: Began after the merge containing Plan 175-54 on 2026-09-30. The Plan 175-54 summary records its own focused classifier tests passing and a terminal SOURCE result; it does not include this later full-suite output.
- reproduction: Run the post-merge Mix test gate against the current checkout and capture complete failure/setup output. Do not replay Plan 175-54 or perform any source, tag, dry-run, or release attempt.

## Current Focus

- bug_class: Mixed deterministic contract drift, test fixture drift, and a concurrent Mix global-state race.
- hypothesis: Confirmed. Unnecessary Mix.Task.clear calls in async direct-run tests re-entered Mix compile; dependency loading temporarily moved VM CWD through deps/telemetry while unrelated tests read repository-relative paths. Independent stale assertions and metadata also caused deterministic failures.
- test: The exact seeded full Mix gate with writable task-local HEX_HOME after removing those resets and reversing path and serialization workarounds.
- expecting: Achieved: 2,049 tests, 0 failures, 0 invalid, 74 excluded.
- next_action: Session manager reviews the unstaged fix and archived record. The release version hold remains separate and no release action is authorized.
- reasoning_checkpoint:
    hypothesis: Async direct-run tests clear process-global Mix task completion state, causing compiler re-entry and a VM-global CWD excursion during other async tests.
    confirming_evidence:
      - CWD trace attributes Mix.Task.clear, Compile.run, and :file.set_cwd(deps/telemetry) to the same EvidenceGateTest PID.
      - Before reset removal, seeded full runs failed different existing relative repository probes; after removal and reversal of path workarounds, the same seeded gate passed.
      - Direct-run affected suites passed without any Mix.Task.clear calls.
    falsification_test: Relative path failures would persist on the seeded full gate after reset removal and workaround reversal, or direct-run assertions would fail without clearing.
    fix_rationale: Remove unnecessary global resets while preserving direct task calls and their assertions, so cached prerequisites stay loaded without changing unrelated readers.
    blind_spots: The real repository still has declared 0.2.1 versions behind visible 0.2.5 tags; its release guard correctly fails and requires separate release authority.
    candidate_causes:
      - code: Test-level global Mix task reset plus stale contract assertions and fixtures.
      - environment: Mix compiler dependency loading changes VM CWD; default Hex cache was unwritable in this sandbox.
    and_gate: yes for the cross-test path failures, which require both the reset-driven compile excursion and concurrent relative readers; independent deterministic failures have their own causes.

## Constraints

- Preserve all pre-existing dirty and untracked workspace changes; inspect before editing and limit changes to the demonstrated fix and this debug record.
- Do not replay Plan 175-54, create another source clone/split, run a tag dry-run, create or push a tag, or perform any release/publication action.
- Do not alter or overwrite other active debug sessions.

## Eliminated

## Evidence

- timestamp: 2026-09-30
  checked: Working tree before investigation.
  found: Many planning and release-related files are already dirty or untracked; this debug record is untracked, and no implementation file has been edited by this investigator.
  implication: Any fix must preserve pre-existing changes and target only the demonstrated cause.

- timestamp: 2026-09-30
  checked: `.planning/debug/knowledge-base.md`.
  found: Prior `pr-214-example-host-seed17` session traced parallel full-suite failures to an async test calling `Mix.Task.clear()` and `app.config` during test loading; its fix made that test synchronous.
  implication: This is a testable candidate, not a diagnosis; capture current first failures before comparing mechanisms.

- timestamp: 2026-09-30
  checked: Partial output of in-progress root `mix test` (seed 212397, max_cases 36) in `/private/tmp/crosswake-post-merge-mix-gate-20260930.log`.
  found: The first 20 failures include a planning breadcrumb assertion, four guard-expression mismatches, missing Phase 175 taxonomy, seven stale ledger rows, current release-status `:error`, declared 0.2.1 behind visible 0.2.5 tags, stale workflow assertions, one mirror operation mismatch, and path/module lookup errors.
  implication: The known async Mix-task pattern may account for path errors but cannot alone explain deterministic repository-content drift or published-version truth; do not apply a single speculative fix.

- timestamp: 2026-09-30
  checked: Completed root `mix test` with seed 212397 and max_cases 36; exact command `mix test > /private/tmp/crosswake-post-merge-mix-gate-20260930.log 2>&1`.
  found: Exit 2 after 294.5 seconds: 2,048 tests, 24 failures, 4 invalid, 74 excluded. Four invalidated `DoctorRouterTest` cases share one `setup_all` failure: nested Hex dependency resolution could not persist `<home>/.hex/cache.ets` (`{:error, :eaccess}`). A bridge reply concurrency case also failed (`ref-4` expected `:ok`, got `:deny`).
  implication: The 25-failure historical count is seed-sensitive; setup invalidation is a sandbox/cache write failure, separate from release-status and source-content failures. A single shared root cause for the entire gate is disproven.

- timestamp: 2026-09-30
  checked: Standalone `Crosswake.ReleaseStatus.build()` and focused `mix test test/mix/tasks/crosswake_release_status_test.exs --seed 212397 --max-cases 1`.
  found: The only status check in error is `release.governance_behavioral_identity_gates`, despite all scanner IDs passing. Focused suite: 19 tests, 5 failures. Current companion publish `if` clauses include REL-17 operation and package restrictions, whereas the local predicate compares against the old exact release-created-only expression.
  implication: The release-status cluster has a deterministic code cause, independent of parallel Mix task behavior and the other full-suite failures.

- timestamp: 2026-09-30
  checked: Focused release-status suite after changing only `component_publish_gates?/1`.
  found: `mix test test/mix/tasks/crosswake_release_status_test.exs --seed 212397 --max-cases 1` passed 19 tests, 0 failures (pre-fix: 19 tests, 5 failures). The local check now requires the release-created, REL-17 operation/package, and approved-guard dependency clauses.
  implication: The targeted change fixes the reproduced release-status cluster; remaining full-gate failures need separate investigation.

- timestamp: 2026-09-30
  checked: Focused path-sensitive modules with seed 212397 and max_cases 1.
  found: `phase161_1_navigation_gate_integrity_test.exs` and `phase165_ci_integrity_test.exs` pass together: 30 tests, 0 failures. Full-suite failures were missing a repository test file and Python `ModuleNotFoundError: script`.
  implication: Those path errors depend on concurrent suite activity rather than missing repository files; `crosswake_release_status_test.exs` is async and invokes global `Mix.Task.clear()` three times, matching the prior KB mechanism as a candidate.

- timestamp: 2026-09-30
  checked: Combined release-status and two path-sensitive modules with seed 212397 and max_cases 36.
  found: All 49 tests passed; the full-suite path error did not reproduce in this smaller concurrent set.
  implication: A further test module or scheduling condition is needed; the async Mix-task candidate remains unconfirmed and no concurrency fix has been applied.

- timestamp: 2026-09-30
  checked: Fresh Phase 170 snapshot and frozen remediation manifest against current release-status test source.
  found: Only seven ledger rows and four frozen remediation `display` locations had stale line numbers; keys, shapes, expressions, and non-emptiness guards were unchanged. After targeted metadata edits, inventory `--check` passed 230 classified sites and both Phase 170 test modules passed 24 tests, 0 failures.
  implication: Those three full-suite failures were metadata drift, not vacuous assertions. Existing dirty ledger content was preserved outside the seven changed rows.

- timestamp: 2026-09-30
  checked: Focused guide release-boundary test file after updating two stale next-action assertions.
  found: 15 tests, 0 failures. The actual read-only blocked and partial next actions require fresh evidence and a new gate, matching `candidate_state/2`; no production behavior changed.
  implication: The two guide failures were assertion drift after the REL-17 hold.

- timestamp: 2026-09-30
  checked: DoctorRouterTest `setup_all` and nested `run_mix` helper.
  found: The setup runs `mix deps.get` in a temporary host; `System.cmd` inherits the parent environment except MIX_ENV. Full-suite setup failed while Hex tried to persist its registry to unwritable `<home>/.hex/cache.ets`.
  implication: A writable task-local `HEX_HOME` is a falsifiable environment fix; no product code edit is indicated for this setup failure.

- timestamp: 2026-09-30
  checked: DoctorRouterTest with `HEX_HOME=/private/tmp/crosswake-hex-home-20260930` and max_cases 1.
  found: All four tests passed (0 invalid, 0 failures) in 47.9 seconds; no `<home>/.hex/cache.ets` write was attempted.
  implication: The four invalidations are resolved by the test-run environment, without changing product code.

- timestamp: 2026-09-30
  checked: Focused Phase 169 diagnostic-legibility suite after adding the actual closed EvidenceGate status to its synthetic render fixture.
  found: 35 tests, 0 failures; the prior `KeyError :authorization_gate` no longer occurs.
  implication: That failure was fixture drift after the REL-17 render contract changed.

- timestamp: 2026-09-30
  checked: Focused WorkflowTest after updating candidate-classification and recovery checkout assertions.
  found: 26 tests, 0 failures. The final assertion had to distinguish a safe `github.ref == refs/heads/main` trigger from an unsafe branch checkout; it now rejects only `ref: refs/heads/`.
  implication: Two full-suite failures were stale workflow assertions; the revised tests retain exact candidate and trusted-tooling/payload boundaries.

- timestamp: 2026-09-30
  checked: Phase 142 aggregate behavioral-gate negative control after changing its mutation target to the current release-created subexpression.
  found: The targeted test passed (1 test, 0 failures); `replace_in_job/4` now performs a real mutation and observes the expected scanner rejection.
  implication: Its full-suite failure was a stale fixture literal, not loss of aggregate-gate detection.

- timestamp: 2026-09-30
  checked: Direct and nested planning tests after editing exactly two dirty STATE lines.
  found: 14 tests, 0 failures. The lines now point to `continue.md` and correctly record Plan 175-54's terminal SOURCE result; no other STATE bytes were edited.
  implication: The two planning full-suite failures were stale shared-state breadcrumbs, not a test bug.

- timestamp: 2026-09-30
  checked: Phase 170 taxonomy selector and Phase 175 verification frontmatter.
  found: Phase 175 reports `status: gaps_found` with four unsatisfied criteria; taxonomy convention assigns its record at phase close. The selector previously treated any VERIFICATION file as closed. After selecting only `status: passed` reports and adding a gaps_found control, its focused suite passed 8 tests, 0 failures.
  implication: Open gap snapshots remain visible evidence without forcing a premature or empty taxonomy record; closed reports and the nonzero findings floor remain checked.

- timestamp: 2026-09-30
  checked: Direct version-truth guard, current manifest, and visible linked-core tags.
  found: Guard exits 1 with three named BEHIND results: declared 0.2.1 versus published 0.2.5. All three 0.2.5 tags are visible. The real-repository test expects exit 0 solely from tag visibility, contrary to guard contract and its fixture tests.
  implication: The test expectation should honor a fail-closed version discrepancy; the release itself remains blocked and no coordinate or tag should be changed in this debugging task.

- timestamp: 2026-09-30
  checked: Focused Phase 168 version-truth suite after changing only the real-repository assertion.
  found: 12 tests, 0 failures. The test independently reads the manifest and visible semantic tags, then asserts the guard's fail-closed verdict and named components; the actual release guard still exits 1 on current repository truth.
  implication: The Mix test can verify correct discrepancy detection while preserving the release hold.

- timestamp: 2026-09-30
  checked: Second seeded full Mix gate with writable `HEX_HOME` and complete log `/private/tmp/crosswake-post-fix-mix-gate-20260930.log`.
  found: Exit 2 after 431.8s: 2,049 tests, 6 failures, 0 invalid, 74 excluded. Remaining failures are three Phase 170 metadata assertions from four source-line shifts, two path/CWD probes, and one 20-ref bridge case where the 25 ms deadline expired before replies.
  implication: All earlier release/status/guide/workflow/planning/taxonomy/version/mirror failures are absent; the environmental Hex setup issue is resolved.

- timestamp: 2026-09-30
  checked: Controlled concurrent `File.cd!/2` experiment outside the repository tree.
  found: While another BEAM task held the global CWD in the temp directory, relative `test/mix/tasks/crosswake_gen_shell_diff_test.exs` was absent and `python3 -c 'import script'` failed with the same `ModuleNotFoundError`. In the same condition, a path anchored to the original repository root existed and Python with `cd: root` imported `script` successfully.
  implication: Mutable CWD plus relative probes reproduces both full-suite symptoms. The two affected tests now derive the checkout root from `__DIR__`; the exact test causing the broad-suite transient CWD switch remains unlocated.

- timestamp: 2026-09-30
  checked: Fresh inventory after source edits and five targeted metadata-row updates.
  found: `elixir script/inventory_collection_assertions.exs --check` passed with 230 classified sites and no drift. Only row locations/guard-line rationales changed; row keys, expressions, shapes, and buckets stayed the same.
  implication: Phase 170 metadata now tracks the final test source without weakening its non-vacuity checks.

- timestamp: 2026-09-30
  checked: Focused combined Phase 170 ledger/guard, Phase 161, Phase 165, and Bridge Push suites at seed 212397/max_cases 36.
  found: 103 tests, 0 failures in 23.4s; full log `/private/tmp/crosswake-post-fix-focused-20260930.log`. Both anchored path probes and the 20-ref bridge case pass alongside the refreshed metadata checks.
  implication: The six remaining full-suite failures from the preceding run have targeted focused evidence; broad-suite confirmation is next.

- timestamp: 2026-09-30
  checked: Third seeded full Mix gate with writable HEX_HOME and complete log `/private/tmp/crosswake-final-mix-gate-20260930.log`.
  found: Exit 2 after 378.1s: 2,049 tests, 3 failures, 0 invalid, 74 excluded. All three failures were Phase 165 relative `File.read!` probes for existing workflow/script files; Phase 161, Bridge Push, Phase 170, and all other earlier clusters passed.
  implication: Root anchoring only the Python helper was insufficient; the Phase 165 module's repository reads and negative checks need the same stable root.

- timestamp: 2026-09-30
  checked: Phase 165 module after anchoring repository reads, existence checks, globs, git grep, and Python import to `__DIR__`.
  found: Focused Phase 165 passed 28 tests, 0 failures at seed 212397/max_cases 36; inventory check still matched 230 classified sites; `git diff --check` passed. Relative error labels and async execution remain intact.
  implication: The three full-run Phase 165 failures have a targeted fixture fix that preserves negative controls; the broad suite must confirm it.

- timestamp: 2026-09-30
  checked: Fourth seeded full Mix gate after Phase 165 root anchoring; full log `/private/tmp/crosswake-final-root-anchored-mix-gate-20260930.log`.
  found: Exit 2 after 373.2s: 2,049 tests, 1 failure, 0 invalid, 74 excluded. Only Phase 154 CatalogGuard's positive reference-host seam scan saw zero call sites because it derives source root from ambient `File.cwd!()`; Phase 165 is green.
  implication: The global CWD mutator still affects a different async module. Trace the actual set_cwd caller before adding another dependent-path patch.

- timestamp: 2026-09-30
  checked: Temporary CWD instrumentation setup.
  found: A tracer in `/private/tmp/crosswake-cwd-trace-20260930.exs` was standalone-validated. `test/test_helper.exs` was clean at baseline, backed up byte-for-byte to `/private/tmp/crosswake-test-helper-before-cwd-trace-20260930.exs`, and had SHA-256 `4866a36e86cffc267eb794cf5fdce9287838e2d46812ab9ea7c575742b77f893` before a one-line temporary require hook.
  implication: A seeded diagnostic run can identify the mutator; test_helper must be restored to that hash immediately afterward.

- timestamp: 2026-09-30
  checked: First seeded `--max-failures 1` CWD trace; log `/private/tmp/crosswake-cwd-diagnostic-mix-20260930.log`.
  found: After 7.6s and 1,135 tests, a WorkflowTest relative workflow read failed. Trace captured one process setting CWD to `deps/telemetry` and back; stack at `:file.set_cwd/1` points through `Mix.Tasks.Compile.run/1`, `Mix.Tasks.Deps.Loadpaths.run/1`, and `Mix.Dep.Loader.rebar_dep/4`. `test_helper` was restored byte-for-byte and matched the original SHA-256, with clean git status.
  implication: An async Mix compile re-enters dependency loading and globally changes CWD; trace Compile.run's caller to identify the test that invokes it.

- timestamp: 2026-09-30
  checked: Second seeded `--max-failures 1` trace including Mix.Task.clear and Compile.run entry; log `/private/tmp/crosswake-cwd-caller-diagnostic-20260930.log`.
  found: The same PID executes `Mix.Task.clear/0` in async EvidenceGateTest line 40, then `Mix.Tasks.Compile.run/1`, then globally sets CWD to `deps/telemetry` and back. A concurrent guide test failed during that excursion. The temporary test_helper hook was restored again to its original SHA-256 and clean git status.
  implication: The root mutator is identified; serialize that one module and remove path-workaround edits to test the causal fix.

- timestamp: 2026-09-30
  checked: Root-cause fix and workaround reversal.
  found: EvidenceGateTest is now `async: false` with a comment naming the Mix task/compile global CWD boundary. The Phase 161 file matches HEAD again. All debug-owned Phase 165 path-wrapper and Python changes were reversed; `git diff` for that baseline-dirty file contains only its pre-existing Maven environment assertion hunk. `test_helper` remains clean and hash-verified.
  implication: The pending gate will test the single lifecycle fix instead of relying on widespread path-probe workarounds.

- timestamp: 2026-09-30
  checked: Direct-run Mix task reset necessity and focused neighbor suites.
  found: EvidenceGateTest's `Mix.Task.clear()` and three ReleaseStatusTest clears were removed; direct task `.run/1` assertions still pass with both modules async. No `Mix.Task.clear()` calls remain under `test/`. The combined evidence-gate, release-status, Phase 170 metadata, Phase 154, Phase 161, Phase 165, Workflow, and guide suites passed 158 tests, 0 failures at seed 212397/max_cases 36. Inventory matched 230 sites, and `git diff --check` passed. The previous EvidenceGateTest `async:false` change was reversed.
  implication: Removing unnecessary global resets is a smaller causal fix than serializing or anchoring many readers; full-suite verification remains.

- timestamp: 2026-09-30
  checked: Final seeded full Mix gate with writable task-local HEX_HOME after removing four unnecessary Mix.Task.clear calls and reversing the temporary Phase 161/165 path anchors and EvidenceGateTest serialization.
  found: Command HEX_HOME=/private/tmp/crosswake-hex-home-20260930 mix test --seed 212397 exited 0 after 301.6s: 2,049 tests, 0 failures, 0 invalid, 74 excluded. Complete output: /private/tmp/crosswake-no-mix-clear-full-gate-20260930.log. Combined focused affected suites passed 158/158; inventory check classified 230 sites exactly; git diff --check passed.
  implication: The original post-merge Mix test gate is now green under the same seed and full-suite concurrency. The path-probe workarounds were not needed once the global Mix reset was removed.

- timestamp: 2026-09-30
  checked: Final release-version truth and temporary instrumentation cleanup.
  found: Direct script/check_release_version_truth.exs still exits 1 because core/iOS/Android manifest 0.2.1 trails visible published 0.2.5 tags. No coordinate or tag changed. test/test_helper.exs is clean and its SHA-256 matches the pre-instrumentation backup: 4866a36e86cffc267eb794cf5fdce9287838e2d46812ab9ea7c575742b77f893.
  implication: The Mix test success validates fail-closed detection, not release approval. Temporary diagnostic hooks and path workarounds are absent from the final fix.

## Resolution

- root_cause:
  - The release-status predicate still required the old exact release-created-only expression after REL-17 added authorized companion publish clauses.
  - Multiple proof tests, guide expectations, synthetic fixtures, inventory locations, and two STATE breadcrumbs reflected earlier source and workflow truth.
  - Four Mix.Task.clear calls in async direct-run tests reset global completed-task state; a following app.config prerequisite re-entered compilation, whose dependency loader temporarily set VM CWD to deps/telemetry. Concurrent relative repository probes then failed on existing files or Python imports.
  - The bridge 20-ref matching test shared a 25 ms deadline intended for timeout tests and expired under full-suite scheduling.
  - Hex setup invalidations came from an unwritable default cache path. The real-repository version-truth test expected success based only on tag visibility although declared 0.2.1 trails visible 0.2.5 tags.
- fix:
  - Align the release-status predicate with current REL-17 guarded companion publication.
  - Refresh only demonstrated source/fixture expectations and Phase 170 inventory metadata; keep taxonomy checks for passed phase reports while retaining the findings floor and gaps_found control.
  - Remove the four unnecessary Mix.Task.clear calls from direct task test invocations. Preserve async execution and all assertions; reverse exploratory Phase 161/165 root anchors and EvidenceGateTest serialization.
  - Use the normal 2,000 ms acknowledgement deadline only for the bridge 20-ref matching case.
  - Use task-local writable HEX_HOME for verification and make the version-truth test assert the guard verdict from independently compared manifest and visible tags. No version coordinate, tag, or release action changed.
- verification:
  - original_gate: PASS; HEX_HOME=/private/tmp/crosswake-hex-home-20260930 mix test --seed 212397; 2,049 tests, 0 failures, 0 invalid, 74 excluded; /private/tmp/crosswake-no-mix-clear-full-gate-20260930.log.
  - focused_regression: PASS; affected and adjacent suites 158 tests, 0 failures at seed 212397/max_cases 36; /private/tmp/crosswake-no-mix-clear-focused-20260930.log.
  - inventory_and_diff: PASS; 230 classified sites exactly; git diff --check clean.
  - causal_check: PASS; pre-fix seeded full runs failed relative probes, traced reset and compiler CWD excursion; final full run passed after removing resets with path workarounds reversed. No literal git revert was performed in the shared dirty workspace.
  - mutation_runner: not configured for this Elixir project; targeted negative controls and full regression gate passed.
  - instrumentation_cleanup: PASS; test_helper hash restored and file clean.
  - guardrail_verdict: accepted for the Mix test gate, based on direct trace, focused checks, and complete full-suite reproduction.
- release_hold: Direct version-truth guard still exits 1 for declared 0.2.1 behind visible published 0.2.5 tags; this remains a separate blocked release fact.
- files_changed:
  - lib/crosswake/release_status.ex
  - script/collection_assertion_ledger.json
  - script/collection_assertion_remediation.json
  - test/crosswake/guides/release_boundaries_test.exs
  - test/crosswake/proof/phase142_release_integrity_test.exs
  - test/crosswake/proof/phase168_version_truth_test.exs
  - test/crosswake/proof/phase169_diagnostic_legibility_test.exs
  - test/crosswake/proof/phase170_vacuity_taxonomy_convention_test.exs
  - test/crosswake/bridge/push_test.exs
  - test/crosswake/release_candidate/evidence_gate_test.exs
  - test/crosswake/release_candidate/mirror_test.exs
  - test/crosswake/release_candidate/workflow_test.exs
  - test/mix/tasks/crosswake_release_status_test.exs
  - .planning/workstreams/quality-ratchet-release/STATE.md
  - .planning/debug/resolved/post-merge-mix-gate.md
- ownership: Ledger, WorkflowTest, and STATE were dirty before this debug session; only the recorded targeted hunks are ours. Phase 165 remains baseline-dirty with no debug-owned final edits. All changes remain unstaged and uncommitted.

## Prevention

- why_not_caught: Plan 175-54 focused checks did not exercise the full Mix suite, so broad-suite scheduling exposed the Mix global-state race and stale cross-phase assertions only afterward.
- recurrence_guard: The full Mix gate now exercises the corrected assertions and direct-run task tests; the Phase 170 inventory check enforces all 230 sites; the version-truth test derives the fail-closed verdict from repository truth. There are no Mix.Task.clear calls remaining under test/.
