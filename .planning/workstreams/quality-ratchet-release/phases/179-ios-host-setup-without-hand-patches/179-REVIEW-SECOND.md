---
phase: 179-ios-host-setup-without-hand-patches
reviewed: 2026-10-14T00:26:51Z
depth: standard
review_head_sha: 492eb79535097d512c4ce8e19bcd6192f014032d
review_tree: 1b9de97292bdc957662e03625c5630827d3dea7d
diff_base: d0dbdf7bf196cea167ced3c50cf620bf3cb2452b
files_reviewed: 33
files_reviewed_list:
  - guides/capability_map.md
  - guides/native_shell.md
  - guides/native_shell_upgrade.md
  - guides/support_matrix.md
  - lib/crosswake/capability_map/renderer.ex
  - lib/crosswake/proof_lane/generator.ex
  - lib/crosswake/shell/ios_host_config.ex
  - lib/crosswake/shell/ios_host_generation.ex
  - lib/crosswake/shell/ios_host_project_migration.ex
  - lib/crosswake/shell/managed_outputs.ex
  - lib/crosswake/shell/pbx_project.ex
  - lib/crosswake/support_matrix/renderer.ex
  - lib/mix/tasks/crosswake.gen.proof_lane.ex
  - lib/mix/tasks/crosswake.gen.shell.ex
  - priv/crosswake/verify_ios_host_settings.mjs
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofSettings.xcconfig.eex
  - priv/templates/crosswake/shell/ios/CrosswakeHostSettings.xcconfig.eex
  - priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex
  - script/collection_assertion_ledger.json
  - script/verify_ios_host_settings.mjs
  - test/crosswake/guides/native_shell_upgrade_test.exs
  - test/crosswake/proof/phase134_template_version_drift_test.exs
  - test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs
  - test/crosswake/proof_lane/template_contract_test.exs
  - test/crosswake/shell/ios_host_config_test.exs
  - test/crosswake/shell/ios_host_effective_settings_test.mjs
  - test/crosswake/shell/ios_host_migration_graph_test.exs
  - test/crosswake/shell/ios_host_migration_security_test.exs
  - test/crosswake/shell/managed_outputs_test.exs
  - test/mix/tasks/crosswake.docs.sync_test.exs
  - test/mix/tasks/crosswake_gen_proof_lane_test.exs
  - test/mix/tasks/crosswake_gen_shell_host_test.exs
findings:
  critical: 1
  warning: 3
  info: 0
  total: 4
status: issues_found
---

# Phase 179: Code Review Report

**Reviewed:** 2026-10-14T00:26:51Z  
**Depth:** standard  
**Files reviewed:** 33  
**Status:** issues_found

## Summary

The final candidate closes all eight findings from `179-REVIEW-INITIAL.md`: CR-01 through CR-07 and WR-01 are fixed in the current tree. The final security audit's 13/13 closed result is consistent with the security controls it examined. This independent pass found one remaining overwrite risk and three recovery/checker robustness defects in the proof-lane path. The recorded focused runs are useful corroboration; no broad suites were rerun for this review.

## Prior finding dispositions

- CR-01 through CR-07: fixed and confirmed in the final source.
- WR-01: fixed and confirmed; the checker now resolves its module URL with `fileURLToPath` and handles packaged/symlinked entry paths.

## Critical issues

### CR-08: [BLOCKER] Proof project migration can overwrite a concurrent host edit

**File:** `lib/crosswake/proof_lane/generator.ex:72-80,384-390`

**Issue:** `migrate_project_settings/2` reads the PBX file into `bytes` and derives `preview.contents`, but the apply helper receives only the rewritten contents. It writes a temporary file and renames it over the project after checking only that the destination is still a regular file. If the host or Xcode tooling changes `project.pbxproj` after the read and before the rename, the migration silently discards that edit. The shell migration passes expected bytes to `ManagedOutputs.write_migration_project/3`; the proof migration does not have the same compare-before-replace protection.

**Fix:** Pass the original bytes into the apply helper and re-read the project immediately before replacement. Refuse the replacement if current bytes differ from the preview input, retaining the temporary/recovery evidence for reconciliation.

## Warnings

### WR-02: [WARNING] Version-1 proof recovery journals are accepted but cannot be recovered

**File:** `lib/crosswake/proof_lane/generator.ex:365-370,397-417`

**Issue:** Recovery accepts `version` 1 or 2, but `recovery_current_is_known/4` unconditionally decodes the `desired` field. Version-1 journals contain only `version` and `prior`, so `Map.get(staged, "desired")` is `nil` and recovery returns `PL-GENERATE-RECOVERY`. An interrupted generation left by the previously shipped journal format therefore remains blocked after upgrading, despite taking the version-1 branch.

**Fix:** Either implement v1 recovery using its recorded prior snapshot with the necessary safe current-state check, or reject v1 explicitly with a bounded migration/reconciliation path instead of claiming it is supported.

### WR-03: [WARNING] A crash between stage and pending writes leaves an unrecoverable proof update

**File:** `lib/crosswake/proof_lane/generator.ex:251-259,365-378`

**Issue:** `publish_managed_settings/6` writes the stage file before the pending marker. If the process exits after `write_stage/4` succeeds but before the pending write completes, preflight sees the leftover stage and reports an interrupted update. `recover_managed_settings/1` requires the pending marker, so `--recover` returns `PL-GENERATE-NO-RECOVERY`; subsequent generation remains blocked by the orphan stage. No project settings were changed yet, so this state can be safely reconciled automatically.

**Fix:** Make the recovery protocol recognize and clean up a stage-only pre-publication state after verifying that the settings file still matches the recorded prior state, or publish a journal format whose every intermediate state has an explicit recovery path.

### WR-04: [WARNING] The caller timeout is shorter than the checker’s valid total runtime

**File:** `lib/mix/tasks/crosswake.gen.proof_lane.ex:194-202`; `priv/crosswake/verify_ios_host_settings.mjs:143-155`

**Issue:** The checker invokes `xcodebuild` sequentially for 20 target/configuration/SDK cells, with a 120-second timeout for each invocation. Its Mix caller abandons the entire port after 180 seconds. A few slow cells can consume the caller's total budget before the checker finishes and emits its structured safe findings, even though no individual Xcode query exceeded its own timeout.

**Fix:** Use a shared total deadline that is consistent between caller and checker, or set a per-cell budget derived from the remaining total budget and ensure timeout results are emitted as safe structured findings before the caller deadline.

## Process notes (advisory)

Plan 03 records `tdd_mode: false`; its missing Task 1/2 pre-fix RED evidence remains process debt. CR-06 also lacked a semantic RED before its repair. The documented earlier pending-build observation had no retained raw cause; this review leaves that cause unknown and does not infer one from later passing Xcode observations.

---

_Reviewed: 2026-10-14T00:26:51Z_  
_Reviewer: gsd-code-reviewer_  
_Depth: standard_
