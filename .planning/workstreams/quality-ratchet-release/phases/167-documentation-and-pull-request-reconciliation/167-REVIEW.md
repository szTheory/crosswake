---
phase: 167-documentation-and-pull-request-reconciliation
reviewed: 2026-09-12T03:24:54Z
depth: standard
files_reviewed: 52
files_reviewed_list:
  - .github/actions/setup-android-jvm/action.yml
  - .github/workflows/crosswake-ci.yml
  - .github/workflows/phase68-proof.yml
  - .github/workflows/release-please.yml
  - CONTRIBUTING.md
  - README.md
  - docs/COMPANION-PUBLISH-RUNBOOK.md
  - guides/architecture.md
  - guides/capability_map.md
  - guides/code-walkthrough.md
  - guides/companion_compatibility.md
  - guides/compatibility.md
  - guides/install.md
  - guides/physical_iphone_handoff.md
  - guides/support_matrix.md
  - guides/troubleshooting.md
  - lib/crosswake/capability_map.ex
  - lib/crosswake/capability_map/renderer.ex
  - lib/crosswake/support_matrix/renderer.ex
  - lib/mix/tasks/crosswake.docs.sync.ex
  - mix.exs
  - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/PackStoreTests.swift
  - packages/crosswake_rindle/README.md
  - packages/crosswake_rindle/mix.exs
  - packages/crosswake_rulestead/README.md
  - packages/crosswake_rulestead/mix.exs
  - script/check_phase166_ownership_ledger.py
  - script/check_phase167_default_reconciliation.py
  - script/check_phase167_pr_dispositions.py
  - script/check_release_workflow_integrity.exs
  - script/ci_docs_allowlist.json
  - script/ci_leaf_manifest.json
  - script/repository_artifact_policy.json
  - script/repository_verification_stages.json
  - script/verify_repository.mjs
  - test/crosswake/capability_map/capability_map_test.exs
  - test/crosswake/capability_map/renderer_test.exs
  - test/crosswake/guides/architecture_code_walkthrough_test.exs
  - test/crosswake/guides/quick_start_adoption_drift_test.exs
  - test/crosswake/guides/release_boundaries_test.exs
  - test/crosswake/proof/phase132_compat_matrix_drift_test.exs
  - test/crosswake/proof/phase142_release_integrity_test.exs
  - test/crosswake/proof/phase161_1_navigation_gate_integrity_test.exs
  - test/crosswake/proof/phase165_ci_integrity_test.exs
  - test/crosswake/proof/phase165_ci_policy_test.exs
  - test/crosswake/proof/phase166_repository_quality_test.exs
  - test/crosswake/proof/phase69_docs_contract_parity_test.exs
  - test/crosswake/proof_lane/evidence_test.exs
  - test/crosswake/support_matrix/renderer_test.exs
  - test/js/phase167_pr_dispositions.test.mjs
  - test/js/repository_verification.test.mjs
  - test/mix/tasks/crosswake.docs.sync_test.exs
findings:
  critical: 2
  warning: 3
  info: 0
  total: 5
status: issues_found
---

# Phase 167: Code Review Report

**Reviewed:** 2026-09-12T03:24:54Z
**Depth:** standard
**Files Reviewed:** 52
**Status:** issues_found

## Summary

The phase establishes useful generated-document ownership and reconciliation machinery, but two fail-closed contracts are incomplete. The final PR closeout and local-reconciliation receipts have no executable validator, and the adoption-claim validator accepts semantically impossible `:available` combinations. Three additional defects leave canonical row metadata internally inconsistent, publish a stale CI remediation command, and misidentify the executable owner of the generated support matrix.

Targeted Phase 167 Python, Node, and Elixir tests passed, as did `mix crosswake.docs.sync --check`; those suites do not exercise the defects below.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Required closeout and local-reconciliation verification modes do not exist

**Classification:** BLOCKER

**File:** `/Users/jon/projects/crosswake/script/check_phase167_pr_dispositions.py:817-859`

**Issue:** The Phase 167 closeout contract requires fixed invocations named `--verify-closeout-resolution ... --live` and `--verify-local-reconciliation ... --scope ...`, but the parser registers neither mode nor `--scope`. The implemented terminal path only accepts `--verify-resolution ... --live`, which validates an individual PR resolution receipt. Invoking either required closeout command exits through `argparse` with status 2. Consequently, the final receipt's baseline/scope hashes, merge authority, current observations, recovery transaction set, local branch/index state, and five-path Phase 168 handoff are backed only by one-time manual/property-equivalent inspection. That leaves the phase's high-impact closeout and handoff evidence mutable without a recurring fail-closed verifier.

**Fix:** Add dedicated, closed-schema `--verify-closeout-resolution` and `--verify-local-reconciliation` modes plus the required `--scope` argument. Recompute and compare baseline/scope hashes; verify merge parents, tree and reachability; query current PR/defer state in live mode; verify the clean local main/index/runtime state; and require the exact five handoff path names and owner. Add negative self-test fixtures for every field and run both fixed invocations in the phase closeout gate.

### CR-02: Adoption validation fails open for impossible available-state claims

**Classification:** BLOCKER

**File:** `/Users/jon/projects/crosswake/lib/crosswake/capability_map.ex:570-577`

**Issue:** `validate_adoption_claim!/1` applies tuple-level rules only when `activation_state` is `:reference_evidence` or `:blocked` (lines 615-645). An `:available` claim receives vocabulary checks only. For example, an existing claim changed to `evidence_subject: :first_adopter`, `source_binding: :required_missing`, `activation_state: :available`, and `support_promotion: true` is accepted unchanged. This permits the support gate to be represented as available and promoting while its source binding is explicitly missing, violating the phase's fail-closed adoption boundary.

**Fix:** Validate a closed set of complete tuples rather than fields independently. At minimum, require `:available` to use the exact reusable-contract subject and repository binding, require `:reference_evidence` to use the dated source-bound physical reference tuple, and require `:blocked` to use the non-promoting first-adopter/missing-source tuple. Reject extra or missing keys where they affect authority, and add cross-product mutation tests for all three activation states.

## Warnings

### WR-01: Canonical capability rows are populated with tuples rejected by the claim rules

**Classification:** WARNING

**File:** `/Users/jon/projects/crosswake/lib/crosswake/capability_map.ex:592-605`

**Issue:** `row/1` defaults every row to the Crosswake/repository tuple, then derives `:reference_evidence` solely from category `:demoed`. Every demoed row therefore becomes `evidence_subject: :crosswake_contract`, `source_binding: :repository_bound`, `activation_state: :reference_evidence`. Those tuples fail the module's own reference-evidence requirements for a reference host, source binding, physical source, dated runtime authority, and non-promotion. The tests only assert that each field exists and belongs to its vocabulary, so the canonical source can expose internally contradictory support metadata without failing.

**Fix:** Give each row an explicit coherent tuple or separate per-capability proof posture from the three global adoption-claim layers. Add a validator for canonical rows and a test that validates semantic combinations, not only vocabulary membership.

### WR-02: CI manifest publishes a stale Phase 41 remediation command

**Classification:** WARNING

**File:** `/Users/jon/projects/crosswake/.github/workflows/crosswake-ci.yml:560-577`; `/Users/jon/projects/crosswake/script/ci_leaf_manifest.json:159-163`

**Issue:** The actual Phase 41 job was split into a doctor test, a serialized `phase41_nested_process` run, and a separately seeded broad run. The leaf manifest still advertises the old two-command remediation. An unused `PHASE41_SUPERSEDED_MANIFEST_REMEDIATION` environment variable contains that stale string solely so the manifest validator can find it in the serialized workflow. A consumer following the manifest therefore skips the isolation and deterministic settings added to prevent the prior failure, while the parity check reports success.

**Fix:** Replace the manifest remediation with the exact three-command sequence emitted in the job summary and remove the compatibility-only environment variable. Strengthen the leaf-manifest validator to match executable `run` steps or the explicit remediation summary rather than arbitrary comments/environment strings.

### WR-03: Generated support matrix omits its primary executable owner

**Classification:** WARNING

**File:** `/Users/jon/projects/crosswake/lib/crosswake/support_matrix/renderer.ex:22-25`; `/Users/jon/projects/crosswake/guides/support_matrix.md:1-4`

**Issue:** The generated support matrix says only that `Crosswake.CapabilityMap` is canonical owner "for the first adopter claim layers." It never identifies `Crosswake.SupportMatrix`, even though that module supplies the rest of the rendered support matrix and `CONTRIBUTING.md` names it as the executable owner of this projection. The generated owner header therefore cannot tell maintainers where most support facts must be changed and conflicts with the phase's single-owner documentation guidance.

**Fix:** Render both ownership boundaries explicitly, for example: `Crosswake.SupportMatrix` owns the support matrix and `Crosswake.CapabilityMap` owns the embedded first-adopter claim layers. Add a renderer assertion covering both owners.

---

_Reviewed: 2026-09-12T03:24:54Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
