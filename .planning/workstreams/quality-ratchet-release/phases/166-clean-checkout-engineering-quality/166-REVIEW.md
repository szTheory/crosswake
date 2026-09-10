---
phase: 166-clean-checkout-engineering-quality
reviewed: 2026-09-10T07:35:13Z
depth: standard
files_reviewed: 158
files_reviewed_list:
  - .formatter.exs
  - .github/workflows/crosswake-ci.yml
  - .tool-versions
  - CHANGELOG.md
  - README.md
  - examples/phoenix_host/e2e/offline_storage.spec.ts
  - examples/phoenix_host/e2e/offline_sync.spec.ts
  - examples/phoenix_host/playwright.config.ts
  - examples/phoenix_host/priv/static/offline_study.js
  - guides/companion_compatibility.md
  - guides/install.md
  - guides/route_policy.md
  - lib/crosswake/bridge.ex
  - lib/crosswake/bridge/commands/file_picker.ex
  - lib/crosswake/bridge/commands/permissions_status.ex
  - lib/crosswake/bridge/registry.ex
  - lib/crosswake/commerce.ex
  - lib/crosswake/commerce/contracts.ex
  - lib/crosswake/commerce/provider_evidence.ex
  - lib/crosswake/commerce/reconciliation.ex
  - lib/crosswake/companion/state.ex
  - lib/crosswake/companion_guard.ex
  - lib/crosswake/companions/play_billing/evidence.ex
  - lib/crosswake/companions/play_billing/result.ex
  - lib/crosswake/companions/store_kit/evidence.ex
  - lib/crosswake/companions/store_kit/result.ex
  - lib/crosswake/compatibility/compatibility.ex
  - lib/crosswake/compatibility/route_gate.ex
  - lib/crosswake/doctor/doctor.ex
  - lib/crosswake/doctor/finding_policy.ex
  - lib/crosswake/doctor/formatter.ex
  - lib/crosswake/doctor/publish_readiness.ex
  - lib/crosswake/install/patcher.ex
  - lib/crosswake/manifest/builder.ex
  - lib/crosswake/native_escape/contract.ex
  - lib/crosswake/native_escape/runtime.ex
  - lib/crosswake/offline/contracts.ex
  - lib/crosswake/operator_inspection.ex
  - lib/crosswake/packs/runtime.ex
  - lib/crosswake/policy/schema.ex
  - lib/crosswake/policy/validator.ex
  - lib/crosswake/router.ex
  - lib/crosswake/router/scope_defaults.ex
  - lib/crosswake/runtime_line/rebuild_policy.ex
  - lib/crosswake/shell/diagnostic_export.ex
  - lib/crosswake/transfer/contracts.ex
  - lib/mix/tasks/closeout.verify.ex
  - lib/mix/tasks/crosswake.contract.gen.ex
  - lib/mix/tasks/crosswake.doctor.ex
  - lib/mix/tasks/crosswake.gen.offline_ui.ex
  - lib/mix/tasks/crosswake.gen.shell.ex
  - lib/mix/tasks/crosswake.gen.sync.ex
  - lib/mix/tasks/crosswake.install.ex
  - lib/mix/tasks/crosswake.shell.status.ex
  - mix.exs
  - priv/templates/crosswake/install_manifest.json.eex
  - script/capture_repository_verification_evidence.sh
  - script/check_ci_leaf_manifest.py
  - script/check_dependency_security.sh
  - script/check_example_host_isolation.sh
  - script/check_phase166_clean_checkout_engineering_quality.sh
  - script/check_phase166_ownership_ledger.py
  - script/ci_leaf_manifest.json
  - script/list_merge_blocking_checks.py
  - script/repository_artifact_policy.json
  - script/repository_evidence_toolchain.json
  - script/repository_verification_stages.json
  - script/run_repository_evidence_environment.sh
  - script/verify_repository.mjs
  - script/verify_repository.sh
  - test/crosswake/bridge/bridge_behavioral_vector_test.exs
  - test/crosswake/bridge/contract_test.exs
  - test/crosswake/bridge/push_test.exs
  - test/crosswake/bridge/registry_test.exs
  - test/crosswake/commerce/reconciliation_test.exs
  - test/crosswake/companions/play_billing_test.exs
  - test/crosswake/companions/store_kit_test.exs
  - test/crosswake/compatibility/compatibility_test.exs
  - test/crosswake/doctor/doctor_test.exs
  - test/crosswake/doctor/doctor_threadline_test.exs
  - test/crosswake/doctor/formatter_test.exs
  - test/crosswake/guides/adopter_profiles_test.exs
  - test/crosswake/guides/capabilities_test.exs
  - test/crosswake/guides/capture_collateral_test.exs
  - test/crosswake/guides/collateral_table_test.exs
  - test/crosswake/guides/native_dev_wiring_test.exs
  - test/crosswake/guides/port_registry_test.exs
  - test/crosswake/guides/readme_see_it_run_test.exs
  - test/crosswake/guides/release_boundaries_test.exs
  - test/crosswake/guides/route_policy_test.exs
  - test/crosswake/guides/see_it_run_banner_test.exs
  - test/crosswake/guides/user_flows_test.exs
  - test/crosswake/guides/web_to_mobile_migration_test.exs
  - test/crosswake/hex_page_test.exs
  - test/crosswake/manifest/manifest_test.exs
  - test/crosswake/offline/contracts_test.exs
  - test/crosswake/offline/proof_lane_test.exs
  - test/crosswake/planning/closeout_ci_parity_test.exs
  - test/crosswake/planning/release_please_config_test.exs
  - test/crosswake/policy/compile_error_test.exs
  - test/crosswake/policy/compiler_test.exs
  - test/crosswake/policy/route_test.exs
  - test/crosswake/policy/schema_test.exs
  - test/crosswake/policy/warning_test.exs
  - test/crosswake/proof/phase129_companion_contract_freeze_test.exs
  - test/crosswake/proof/phase130_extraction_guards_test.exs
  - test/crosswake/proof/phase130_fail_closed_contract_test.exs
  - test/crosswake/proof/phase133_telemetry_contract_test.exs
  - test/crosswake/proof/phase136_decouple_proof_test.exs
  - test/crosswake/proof/phase142_release_integrity_test.exs
  - test/crosswake/proof/phase145_ios_backfill_script_test.exs
  - test/crosswake/proof/phase154_advisory_actionability_test.exs
  - test/crosswake/proof/phase154_recipe_followable_test.exs
  - test/crosswake/proof/phase164_example_host_isolation_test.exs
  - test/crosswake/proof/phase165_ci_integrity_test.exs
  - test/crosswake/proof/phase165_evidence_test.exs
  - test/crosswake/proof/phase166_repository_quality_test.exs
  - test/crosswake/proof/phase18_bounded_family_lane_test.exs
  - test/crosswake/proof/phase18_deep_link_activation_lane_test.exs
  - test/crosswake/proof/phase21_reconciliation_example_test.exs
  - test/crosswake/proof/phase23_commerce_support_proof_test.exs
  - test/crosswake/proof/phase33_commerce_corridor_routes_test.exs
  - test/crosswake/proof/phase34_mock_storefront_test.exs
  - test/crosswake/proof/phase34_paywall_corridor_proof_test.exs
  - test/crosswake/proof/phase38_companion_contract_test.exs
  - test/crosswake/proof/phase39_route_policy_gating_test.exs
  - test/crosswake/proof/phase40_gate_evaluation_test.exs
  - test/crosswake/proof/phase41_gating_doctor_test.exs
  - test/crosswake/proof/phase42_rulestead_companion_test.exs
  - test/crosswake/proof/phase48_provider_adapter_proof_test.exs
  - test/crosswake/proof/phase63_advisory_proof_test.exs
  - test/crosswake/proof/phase65_diagnostic_export_seam_test.exs
  - test/crosswake/proof/phase68_android_uat_test.exs
  - test/crosswake/proof/phase69_docs_contract_parity_test.exs
  - test/crosswake/proof/phase8_selective_native_lane_test.exs
  - test/crosswake/proof_lane/ios_verifier_test.exs
  - test/crosswake/router_defaults_test.exs
  - test/crosswake/router_test.exs
  - test/crosswake/shell/activation_test.exs
  - test/crosswake/shell/denial_test.exs
  - test/crosswake/shell/diagnostic_export_test.exs
  - test/crosswake/sync/event_log_test.exs
  - test/crosswake/transfer/contracts_test.exs
  - test/fixtures/proof/phase52_publish_readiness.json
  - test/fixtures/repository_quality/artifact-cases.json
  - test/fixtures/repository_quality/stage-cases.json
  - test/js/playwright_repository_mode.test.mjs
  - test/js/repository_verification.test.mjs
  - test/mix/tasks/crosswake.gen.native_controls_ui_test.exs
  - test/mix/tasks/crosswake.gen.offline_ui_test.exs
  - test/mix/tasks/crosswake.gen.sync_test.exs
  - test/mix/tasks/crosswake_doctor_router_test.exs
  - test/mix/tasks/crosswake_doctor_test.exs
  - test/mix/tasks/crosswake_install_test.exs
  - test/support/bridge_live_view_case.ex
  - test/support/compile_router_case.ex
  - test/support/router_fixtures.ex
  - test/test_helper.exs
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 166: Code Review Report

**Reviewed:** 2026-09-10T07:35:13Z
**Depth:** standard
**Files Reviewed:** 158
**Status:** issues_found

## Summary

All seven findings recorded across the prior review and fix report are substantively resolved. In particular, the AST-based router inference ignores comment, moduledoc, and string decoys and fails closed on absent or ambiguous top-level declarations; no regression was found in that repair. The AST-based hermeticity repair correctly catches computed `Code.require_file/2` arguments, but its receiver match misses the valid fully qualified `Elixir.Code.require_file/2` form, leaving one test-reliability warning. No privacy-boundary or Android-freeze expansion was found.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Hermeticity AST guard misses fully qualified Code loads

**File:** `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs:254-264`
**Issue:** `collect_require_file_arguments/1` recognizes only receiver AST shaped as `{:__aliases__, _, [:Code]}`. Valid Elixir source can call the same function as `Elixir.Code.require_file(runtime_path, __DIR__)`, whose receiver is `{:__aliases__, _, [Elixir, :Code]}`. The current walk records zero arguments for that call, so a fifth runtime/server load written in fully qualified form leaves the count at four and passes the merge-blocking hermeticity guard. The focused negative test covers a computed argument but only through the short `Code` alias, so it does not exercise this bypass.
**Fix:** Canonicalize the remote-call receiver and treat both `Code` and `Elixir.Code` as the same module (and either resolve or explicitly reject aliases to `Code`) before validating argument count and literal paths. Add a negative fixture containing `Elixir.Code.require_file(runtime_path, __DIR__)` and require it to be counted and rejected.

---

_Reviewed: 2026-09-10T07:35:13Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
