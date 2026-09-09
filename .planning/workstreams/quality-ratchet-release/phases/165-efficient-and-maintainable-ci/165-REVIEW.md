---
phase: 165-efficient-and-maintainable-ci
reviewed: 2026-09-09T02:17:19Z
depth: standard
files_reviewed: 58
files_reviewed_list:
  - .github/actions/setup-android-jvm/action.yml
  - .github/actions/setup-elixir-cache/action.yml
  - .github/workflows/cancel-obsolete-crosswake-ci.yml
  - .github/workflows/crosswake-ci.yml
  - .github/workflows/phase130-proof.yml
  - .github/workflows/phase132-proof.yml
  - .github/workflows/phase23-proof.yml
  - .github/workflows/phase34-proof.yml
  - .github/workflows/phase43-proof.yml
  - .github/workflows/phase45-proof.yml
  - .github/workflows/phase48-proof.yml
  - .github/workflows/phase52-proof.yml
  - .github/workflows/phase58-proof.yml
  - .github/workflows/phase68-proof.yml
  - .github/workflows/phase70-proof.yml
  - .github/workflows/phase71-proof.yml
  - .github/workflows/phase73-proof.yml
  - .github/workflows/phase74-proof.yml
  - .github/workflows/release-please.yml
  - .github/workflows/required-checks-audit.yml
  - lib/crosswake/release_status.ex
  - script/check_aggregator_result_semantics.py
  - script/check_ci_leaf_manifest.py
  - script/check_example_host_isolation.sh
  - script/check_exunit_ownership.exs
  - script/check_phase165_efficient_ci.sh
  - script/check_release_workflow_integrity.exs
  - script/check_required_checks_registered.sh
  - script/ci_docs_allowlist.json
  - script/ci_leaf_manifest.json
  - script/classify_ci_change.py
  - script/list_merge_blocking_checks.py
  - script/register_required_checks.sh
  - script/required_check_policy.json
  - script/select_obsolete_ci_runs.py
  - script/verify_generated_android_shell.sh
  - script/verify_hex_publish_dry_run.sh
  - scripts/ci_monitor.cjs
  - test/crosswake/planning/closeout_ci_parity_test.exs
  - test/crosswake/proof/phase134_native_gate_blocking_proof_test.exs
  - test/crosswake/proof/phase135_ci_ops_proof_test.exs
  - test/crosswake/proof/phase142_release_integrity_test.exs
  - test/crosswake/proof/phase153_1_cache_integrity_test.exs
  - test/crosswake/proof/phase153_1_gate_integrity_test.exs
  - test/crosswake/proof/phase153_ios_mirror_unblock_test.exs
  - test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs
  - test/crosswake/proof/phase164_example_host_isolation_test.exs
  - test/crosswake/proof/phase164_exunit_ownership_test.exs
  - test/crosswake/proof/phase165_ci_integrity_test.exs
  - test/crosswake/proof/phase165_ci_policy_test.exs
  - test/crosswake/proof/phase165_evidence_test.exs
  - test/crosswake/proof/phase5_proof_lane_test.exs
  - test/fixtures/ci/cancellation/cases.json
  - test/fixtures/ci/classifier/cases.json
  - test/fixtures/ci/maximum-shape-crosswake-ci.yml
  - test/fixtures/ci/maximum-shape-needs.json
  - test/mix/tasks/crosswake_adoption_context_scan_test.exs
  - test/test_helper.exs
findings:
  critical: 3
  warning: 1
  info: 0
  total: 4
status: issues_found
---

# Phase 165: Code Review Report

**Reviewed:** 2026-09-09T02:17:19Z
**Depth:** standard
**Files Reviewed:** 58
**Status:** issues_found

## Summary

The consolidated CI graph is not ready to ship. Public-documentation changes silently skip proof that Phase 165 explicitly moved under affected-family scheduling, the live cancellation evidence can claim controller timing and bounded behavior without correlating an observed controller run, and the sole required-context verifier ignores the GitHub App identity that prevents same-name status spoofing. The new required graph also retains numerous mutable action tags.

The review used the committed `93c23c1223b24b49cd139c2b5a322dc834abbb3d..HEAD` scope, excluded deleted files, and did not inspect user-owned unstaged contents as Phase 165 changes. The classifier, manifest, cancellation, and evidence self-tests pass, but they do not exercise the failures below. Live protection was also observed as strict with `Crosswake CI` currently bound to GitHub Actions app ID `15368`; CR-03 concerns the verifier's inability to preserve that property under later drift.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Public-documentation changes skip their migrated affected-family proof

**Classification:** BLOCKER

**File:** `/Users/jon/projects/crosswake/script/classify_ci_change.py:28-30`

**Issue:** `public_docs` paths are detected, but `closed_result/3` emits only `documentation_contracts` and `threadline_docs_contract`. The migrated `brand-structural`, `brand-visual`, `collateral-binaries-guard`, and `hex-page-proof` jobs test `scheduled_families` for `public_docs` at `.github/workflows/crosswake-ci.yml:102`, `:158`, `:181`, and `:203`, so all four are skipped for README, guides, docs, and brandbook Markdown changes. This contradicts the Phase 165 affected-family contract and removes the only recurring PR execution of those checks after their source workflows were deleted. The live probe masks the defect: `scripts/ci_monitor.cjs:776-777` requires every documentation probe to run only `documentation-contracts`, and the probe fixture at `:830` is planning-only rather than public documentation.

**Fix:** Emit the actual affected family and assert separate planning/public schedules. For example:

```python
scheduled_families = ["documentation_contracts"] if docs else ["full_proof"]
if docs and affected_families and "public_docs" in affected_families:
    scheduled_families.extend(["public_docs", "threadline_docs_contract"])
```

Then make workflow conditions parse the JSON consistently with `contains(fromJSON(...), 'public_docs')`, add a public-doc classifier fixture, and change the live probe to exercise both planning-only and public-doc changes with the exact expected active leaves.

### CR-02: Cancellation evidence hard-codes claims that the probe never observes

**Classification:** BLOCKER

**File:** `/Users/jon/projects/crosswake/scripts/ci_monitor.cjs:805-807`

**Issue:** `controllerObserved` returns true for any controller workflow run created after a timestamp. It does not correlate the run to the probed PR, the newer Crosswake CI run, the lower run ID, or even a successful controller conclusion; its `lowerId` parameter is reduced to the already-known fact `lowerId > 0`. The caller then hard-codes `requested_controller_observed`, `bounded_controller_action`, and `newer_run_authoritative` to true at `:859-870`. It never inspects the selected IDs/controller logs or waits for the newer run to reach a terminal non-cancelled result. An unrelated or failed controller run can therefore satisfy the timing claim, and a delayed cancellation can occur after evidence is written. This evidence is subsequently accepted by `register_required_checks.sh:53-59` as authorization to change branch protection.

**Fix:** Locate the exact controller run triggered by the newer Crosswake CI run, wait for that controller run to complete successfully, and inspect a machine-readable controller result containing the source workflow-run ID and selected lower IDs. After the controller completes, wait for the newer run to reach its terminal state and require a non-cancelled conclusion. Derive every evidence boolean from those observations instead of literals, and persist a non-sensitive controller run ID/source run ID so validation can enforce the correlation.

### CR-03: Exact required-check verification drops the required producer app identity

**Classification:** BLOCKER

**File:** `/Users/jon/projects/crosswake/script/check_required_checks_registered.sh:54-64`

**Issue:** The live audit flattens `.checks[].context` and `.contexts[]` to names and compares only that string set. It never verifies `.checks[].app_id`. The retirement writer has the same gap: `register_required_checks.sh:69-90` accepts source state by context names and preserves whatever app ID happens to be attached to `Crosswake CI`. Because Phase 165 leaves `Crosswake CI` as the sole required authority, silently accepting `app_id: null` or a different app weakens the gate: a same-name status from an unintended producer may satisfy protection. The current live value is correctly `15368`, but the recurring and final-source verification would not detect this security-relevant drift.

**Fix:** Define the target as an exact `{context: "Crosswake CI", app_id: 15368}` check record. Compare normalized check records, not just names, in both the live audit and pre/post mutation logic; reject legacy `.contexts` entries or target records with missing/wrong app IDs. Include the exact target check record in the policy and proposal so the approved digest is human-readable and app-bound.

## Warnings

### WR-01: Required CI authority executes mutable third-party action tags

**Classification:** WARNING

**File:** `/Users/jon/projects/crosswake/.github/actions/setup-android-jvm/action.yml:19`

**Issue:** The new composite action uses `actions/setup-java@v5` and `gradle/actions/setup-gradle@v6`, and the consolidated required workflow contains many additional mutable references such as `actions/checkout@v7` and `actions/upload-artifact@v7`. `node scripts/ci_monitor.cjs check-actions .github/workflows/crosswake-ci.yml` reports 43 mutable references but only prints an advisory. Since these actions execute inside the sole required `Crosswake CI` authority, a moved or compromised tag can change proof behavior without a repository commit. This is inconsistent with the already pinned setup/cache references elsewhere in the same graph.

**Fix:** Pin every third-party `uses:` reference in the required workflow and its composite actions to reviewed 40-character commit SHAs, retain the release tag in a comment, and make the mutable-reference check fail for required workflow/action paths.

---

_Reviewed: 2026-09-09T02:17:19Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
