# Phase 166 Ownership Ledger

- Base commit: `8383aaea2a2b2e10bbe61dd843b51f4129a5d447`
- Tree commit: `d8e7cf3f7f62a88e92bd5f25e7bfa7c77869442b`
- Candidate rule: NUL-safe `git diff --name-only -z <base> <tree>`, excluding `.planning/`
- Unresolved flags: all five flagged assumptions, including `FA-ENG-02`, and both bespoke prohibitions remain unresolved by design. Plan 08 closes the mechanical final-tree reconciliation without reclassifying those planning assumptions.

This ledger is deliberately bounded at the declared immutable tree. Expansion follows only a literal caller, import, include, generator, mutator, test, or shared-authority edge and stops at the last recorded direct edge. Paths, low-cardinality ownership, and dispositions are recorded; file contents, payloads, credentials, adopter facts, and environment values are excluded.

Disposition is closed to `retained`, `changed`, `removed-with-proof`, and `unproven-retained`. “Changed” identifies a demonstrated source correction for Plan 06 or an already scheduled correction. Uncertain dead, duplicate, or compatibility claims remain `unproven-retained`.

## Candidates

| candidate | evidence | owner | disposition |
| --- | --- | --- | --- |
| .formatter.exs | deterministic root format contract and canonical format stage | toolchain and formatting owner | retained |
| .github/actions/setup-android-jvm/action.yml | literal Phase 165 workflow and manifest authority | shared CI setup owner | retained |
| .github/actions/setup-elixir-cache/action.yml | literal Phase 165 workflow and manifest authority | shared CI setup owner | retained |
| .github/workflows/aggregator-negative-control.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/brandbook-verify.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/cancel-obsolete-crosswake-ci.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/collateral-guard.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/contract-drift-gate.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/crosswake-ci.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/hex-page-proof.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/merge-blocking-ios-mirror-parity.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/native-behavioral-proof-gate.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/offline-sync-e2e-gate.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/phase10-proof.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/phase130-proof.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/phase132-proof.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/phase18-proof.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/phase23-proof.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/phase34-proof.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/phase41-proof.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/phase43-proof.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/phase45-proof.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/phase48-proof.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/phase5-proof.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/phase52-proof.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/phase58-proof.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/phase67-proof.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/phase68-proof.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/phase69-proof.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/phase70-proof.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/phase71-proof.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/phase73-proof.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/phase74-proof.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/phase75-closeout-gate.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/phase79-proof.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/phase96-proof.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/release-as-staleness-gate.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/release-please.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/required-checks-audit.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .github/workflows/requires-example-host-gate.yml | literal Phase 165 workflow and manifest authority | Crosswake CI workflow owner | retained |
| .tool-versions | exact repository preflight identity | toolchain and dependency owners | retained |
| AGENTS.md | repository execution policy | repository maintainers | retained |
| CHANGELOG.md | tracked release and support truth | documentation owner | retained |
| README.md | tracked public support truth | documentation owner | retained |
| examples/phoenix_host/e2e/offline_storage.spec.ts | focused browser regression and complete browser stage | browser proof owner | retained |
| examples/phoenix_host/e2e/offline_sync.spec.ts | focused scoped-replay regressions and complete browser stage | browser proof owner | retained |
| examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex | focused initialization-failure presentation regression and complete browser stage | offline island presentation owner | changed |
| examples/phoenix_host/mix.lock | lock-governed dependency resolution | toolchain and dependency owners | retained |
| examples/phoenix_host/playwright.config.ts | repository-mode browser regression and CI owner | browser proof owner | changed |
| examples/phoenix_host/priv/static/offline_study.js | focused initialization, storage, scoped lifecycle, and replay regressions | offline island owner | changed |
| guides/companion_compatibility.md | tracked compatibility support truth | documentation owner | retained |
| guides/install.md | tracked installation support truth | documentation owner | retained |
| guides/route_policy.md | tracked route-policy support truth | documentation owner | retained |
| lib/crosswake/bridge.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/bridge/commands/file_picker.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/bridge/commands/permissions_status.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/bridge/registry.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/commerce.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/commerce/contracts.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/commerce/provider_evidence.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/commerce/reconciliation.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/companion/state.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/companion_guard.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/companions/play_billing/evidence.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/companions/play_billing/result.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/companions/store_kit/evidence.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/companions/store_kit/result.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/compatibility/compatibility.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/compatibility/route_gate.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/doctor/doctor.ex | focused doctor tests and supported Mix entrypoint | diagnostics owner | retained |
| lib/crosswake/doctor/finding_policy.ex | focused finding-policy tests and doctor authority | diagnostics owner | retained |
| lib/crosswake/doctor/formatter.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/doctor/publish_readiness.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/install/patcher.ex | focused installer tests and supported Mix entrypoint | installation owner | retained |
| lib/crosswake/manifest/builder.ex | focused manifest tests and supported runtime entrypoints | manifest owner | retained |
| lib/crosswake/native_escape/contract.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/native_escape/runtime.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/offline/contracts.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/operator_inspection.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/packs/runtime.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/planning/closeout_verifier.ex | focused module tests and supported Mix/runtime entrypoints | planning contract owner | retained |
| lib/crosswake/planning/first_adopter_context.ex | focused module tests and supported Mix/runtime entrypoints | planning contract owner | retained |
| lib/crosswake/planning/paths.ex | focused module tests and supported Mix/runtime entrypoints | planning contract owner | retained |
| lib/crosswake/policy/schema.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/policy/validator.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/release_status.ex | focused module tests and supported Mix/runtime entrypoints | Crosswake runtime owner | retained |
| lib/crosswake/router.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/router/scope_defaults.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/runtime_line/rebuild_policy.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/shell/diagnostic_export.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/crosswake/transfer/contracts.ex | focused tests and supported runtime entrypoint | production contract owner | retained |
| lib/mix/tasks/closeout.verify.ex | supported Mix entrypoint and focused regression | Mix task owner | retained |
| lib/mix/tasks/crosswake.contract.gen.ex | supported Mix entrypoint and focused regression | Mix task owner | retained |
| lib/mix/tasks/crosswake.doctor.ex | supported doctor Mix entrypoint and focused regression | diagnostics owner | retained |
| lib/mix/tasks/crosswake.gen.offline_ui.ex | supported Mix entrypoint and focused regression | Mix task owner | retained |
| lib/mix/tasks/crosswake.gen.shell.ex | supported Mix entrypoint and focused regression | Mix task owner | retained |
| lib/mix/tasks/crosswake.gen.sync.ex | supported Mix entrypoint and focused regression | Mix task owner | retained |
| lib/mix/tasks/crosswake.install.ex | supported install Mix entrypoint and focused regression | installation owner | retained |
| lib/mix/tasks/crosswake.shell.status.ex | supported Mix entrypoint and focused regression | Mix task owner | retained |
| mix.exs | root alias and dependency contract | toolchain and dependency owners | retained |
| mix.lock | lock-governed dependency resolution | toolchain and dependency owners | retained |
| packages/crosswake_chimeway/mix.lock | lock-governed companion dependency resolution | companion package owner | retained |
| packages/crosswake_rindle/mix.lock | lock-governed companion dependency resolution | companion package owner | retained |
| packages/crosswake_rulestead/mix.lock | lock-governed companion dependency resolution | companion package owner | retained |
| priv/templates/crosswake/install_manifest.json.eex | generated installer manifest authority | installation owner | retained |
| script/capture_repository_verification_evidence.sh | exact-commit capture and closed evidence validator | repository verification owner | retained |
| script/check_aggregator_result_semantics.py | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/check_ci_leaf_manifest.py | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/check_dependency_security.sh | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/check_example_host_isolation.sh | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/check_exunit_ownership.exs | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/check_phase164_dependency_security_and_gate_authority.sh | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/check_phase165_efficient_ci.sh | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/check_phase166_clean_checkout_engineering_quality.sh | recurring Phase 166 contract | repository verification owner | retained |
| script/check_phase166_ownership_ledger.py | NUL-safe scope and canonical evidence binding | repository verification owner | retained |
| script/check_release_workflow_integrity.exs | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/check_required_checks_registered.sh | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/ci_docs_allowlist.json | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/ci_leaf_manifest.json | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/classify_ci_change.py | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/list_merge_blocking_checks.py | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/normalize_required_checks.py | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/register_required_checks.sh | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/repository_artifact_policy.json | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/repository_evidence_toolchain.json | pinned isolated evidence tool policy | toolchain and dependency owners | retained |
| script/repository_verification_stages.json | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/required_check_policy.json | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/retain_physical_iphone_evidence_transaction.sh | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/run_repository_evidence_environment.sh | pinned invocation-local environment bootstrap | repository verification owner | retained |
| script/select_obsolete_ci_runs.py | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/verify_generated_android_shell.sh | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/verify_hex_publish_dry_run.sh | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/verify_repository.mjs | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/verify_repository.sh | tracked caller, manifest, or focused regression | repository verification owner | retained |
| scripts/ci_monitor.cjs | tracked caller, manifest, or focused regression | CI evidence owner | retained |
| test/crosswake/bridge/bridge_behavioral_vector_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/bridge/contract_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/bridge/push_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/bridge/registry_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/commerce/reconciliation_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/companions/play_billing_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/companions/store_kit_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/compatibility/compatibility_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/doctor/doctor_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/doctor/doctor_threadline_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/doctor/formatter_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/guides/adopter_profiles_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/guides/capabilities_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/guides/capture_collateral_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/guides/collateral_table_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/guides/native_dev_wiring_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/guides/port_registry_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/guides/readme_see_it_run_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/guides/release_boundaries_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/guides/route_policy_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/guides/see_it_run_banner_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/guides/user_flows_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/guides/web_to_mobile_migration_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/hex_page_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/manifest/manifest_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/offline/contracts_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/offline/proof_lane_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/planning/closeout_ci_parity_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/planning/first_adopter_context_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/planning/milestone_transition_reset_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/planning/paths_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/planning/release_please_config_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/policy/compile_error_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/policy/compiler_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/policy/route_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/policy/schema_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/policy/warning_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase129_companion_contract_freeze_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase130_extraction_guards_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase130_fail_closed_contract_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase133_telemetry_contract_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase134_native_gate_blocking_proof_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase135_ci_ops_proof_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase136_decouple_proof_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase142_release_integrity_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase145_ios_backfill_script_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase153_1_cache_integrity_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase153_1_gate_integrity_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase153_ios_mirror_unblock_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase154_advisory_actionability_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase154_recipe_followable_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase164_example_host_isolation_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase164_exunit_ownership_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase165_ci_integrity_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase165_ci_policy_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase165_evidence_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase166_repository_quality_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase18_bounded_family_lane_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase18_deep_link_activation_lane_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase21_reconciliation_example_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase23_commerce_support_proof_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase33_commerce_corridor_routes_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase34_mock_storefront_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase34_paywall_corridor_proof_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase38_companion_contract_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase39_route_policy_gating_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase40_gate_evaluation_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase41_gating_doctor_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase42_rulestead_companion_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase48_provider_adapter_proof_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase5_proof_lane_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase63_advisory_proof_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase65_diagnostic_export_seam_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase68_android_uat_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase69_docs_contract_parity_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase8_selective_native_lane_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof_lane/ios_verifier_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof_lane/physical_iphone_evidence_transaction_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/router_defaults_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/router_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/shell/activation_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/shell/denial_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/shell/diagnostic_export_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/sync/event_log_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/transfer/contracts_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/fixtures/ci/cancellation/cases.json | named negative-control consumer | paired proof fixture owner | retained |
| test/fixtures/ci/classifier/cases.json | named negative-control consumer | paired proof fixture owner | retained |
| test/fixtures/ci/maximum-shape-crosswake-ci.yml | named negative-control consumer | paired proof fixture owner | retained |
| test/fixtures/ci/maximum-shape-needs.json | named negative-control consumer | paired proof fixture owner | retained |
| test/fixtures/ci/required-checks/cases.json | named negative-control consumer | paired proof fixture owner | retained |
| test/fixtures/proof/phase52_publish_readiness.json | named closed proof fixture | paired proof fixture owner | retained |
| test/fixtures/repository_quality/artifact-cases.json | named negative-control consumer | paired proof fixture owner | retained |
| test/fixtures/repository_quality/stage-cases.json | named negative-control consumer | paired proof fixture owner | retained |
| test/fixtures/security/advisory-bearing.lock | named negative-control consumer | paired proof fixture owner | retained |
| test/js/playwright_repository_mode.test.mjs | focused repository-mode browser regression | browser proof owner | retained |
| test/js/repository_verification.test.mjs | focused test path and owning production contract | repository runner proof owner | retained |
| test/mix/tasks/crosswake.gen.native_controls_ui_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/mix/tasks/crosswake.gen.offline_ui_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/mix/tasks/crosswake.gen.sync_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/mix/tasks/crosswake_adoption_context_scan_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/mix/tasks/crosswake_doctor_router_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/mix/tasks/crosswake_doctor_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/mix/tasks/crosswake_install_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/support/bridge_live_view_case.ex | focused test support and owning production contract | ExUnit support owner | retained |
| test/support/compile_router_case.ex | focused test support and owning production contract | ExUnit support owner | retained |
| test/support/example_host.ex | focused test path and owning production contract | ExUnit support owner | retained |
| test/support/router_fixtures.ex | focused test support and owning production contract | ExUnit support owner | retained |
| test/test_helper.exs | focused test path and owning production contract | ExUnit harness owner | retained |

## Direct expansions

| source candidate | target | edge kind | evidence | owner | disposition |
| --- | --- | --- | --- | --- | --- |
| .github/workflows/crosswake-ci.yml | examples/phoenix_host/playwright.config.ts | include | real-config repository, local, and CI modes pass test/js/playwright_repository_mode.test.mjs | browser proof owner | changed |
| .github/workflows/crosswake-ci.yml | lib/mix/tasks/crosswake.contract.gen.ex | caller | guard-02-generate-and-diff invokes the Mix task | generated-contract owner | retained |
| lib/mix/tasks/crosswake.contract.gen.ex | docs/_contract_snippet.md | generator | default argv writes the registered documentation output | generated-contract owner | retained |
| lib/mix/tasks/crosswake.contract.gen.ex | examples/android_shell_host/app/src/dev/assets/route_activation.json | generator | dev argv writes the registered Android fixture | generated-contract owner | retained |
| lib/mix/tasks/crosswake.contract.gen.ex | examples/android_shell_host/app/src/main/assets/route_activation.json | generator | default argv writes the registered Android fixture | generated-contract owner | retained |
| lib/mix/tasks/crosswake.contract.gen.ex | examples/ios_shell_host/Fixtures/route_activation-dev.json | generator | dev argv writes the registered iOS fixture | generated-contract owner | retained |
| lib/mix/tasks/crosswake.contract.gen.ex | examples/ios_shell_host/Fixtures/route_activation.json | generator | default argv writes the registered iOS fixture | generated-contract owner | retained |
| lib/mix/tasks/crosswake.contract.gen.ex | packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json | generator | default argv writes the registered Android vectors | generated-contract owner | retained |
| lib/mix/tasks/crosswake.contract.gen.ex | packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json | generator | default argv writes the registered iOS vectors | generated-contract owner | retained |
| lib/mix/tasks/crosswake.contract.gen.ex | test/fixtures/bridge_contract_vectors.json | generator | default argv writes the canonical test vectors | generated-contract owner | retained |
| script/repository_artifact_policy.json | .gitignore | shared-authority | artifact categories reconcile tracked intent with ignore convention | repository artifact owner | retained |

## Closed edges

| source candidate | target | terminal result |
| --- | --- | --- |
| .github/workflows/crosswake-ci.yml | examples/phoenix_host/playwright.config.ts | changed |
| .github/workflows/crosswake-ci.yml | lib/mix/tasks/crosswake.contract.gen.ex | retained |
| lib/mix/tasks/crosswake.contract.gen.ex | docs/_contract_snippet.md | retained |
| lib/mix/tasks/crosswake.contract.gen.ex | examples/android_shell_host/app/src/dev/assets/route_activation.json | retained |
| lib/mix/tasks/crosswake.contract.gen.ex | examples/android_shell_host/app/src/main/assets/route_activation.json | retained |
| lib/mix/tasks/crosswake.contract.gen.ex | examples/ios_shell_host/Fixtures/route_activation-dev.json | retained |
| lib/mix/tasks/crosswake.contract.gen.ex | examples/ios_shell_host/Fixtures/route_activation.json | retained |
| lib/mix/tasks/crosswake.contract.gen.ex | packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json | retained |
| lib/mix/tasks/crosswake.contract.gen.ex | packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json | retained |
| lib/mix/tasks/crosswake.contract.gen.ex | test/fixtures/bridge_contract_vectors.json | retained |
| script/repository_artifact_policy.json | .gitignore | retained |

## Removal evidence

| candidate | supported-entrypoint | workflow/config | dependency | dynamic-dispatch | focused-regression | complete-clean-gate |
| --- | --- | --- | --- | --- | --- | --- |

No removal is authorized at this declared tree. A future `removed-with-proof` row must fill all six D-09 evidence classes; static reachability alone is never sufficient.

## Remediation queue

| source path | owner | finding class | focused regression | focused command | result |
| --- | --- | --- | --- | --- | --- |
| examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex | offline island presentation owner | misleading-fallback | examples/phoenix_host/e2e/offline_storage.spec.ts | cd examples/phoenix_host && npx playwright test e2e/offline_storage.spec.ts | pass |
| examples/phoenix_host/playwright.config.ts | browser proof owner | misleading-fallback | test/js/playwright_repository_mode.test.mjs | node --test test/js/playwright_repository_mode.test.mjs | pass |
| examples/phoenix_host/priv/static/offline_study.js | offline island owner | misleading-fallback | examples/phoenix_host/e2e/offline_storage.spec.ts | cd examples/phoenix_host && npx playwright test e2e/offline_storage.spec.ts | pass |

The original repository-mode queue item was implemented test-first in Plan 04 (`ceca6427` RED,
`12c2c548` GREEN). The Phase 166 UI review then demonstrated two additional misleading fallback
surfaces plus missing first-failure trace retention. Commit `5f56084f` locked all three findings in
focused RED tests and `a4e8be47` implemented the bounded correction. The focused storage suite
passed 4/4, the configuration suite passed 3/3, and the complete browser suite passed 60/60. The
queue contract was then decoupled from the later evidence-only row count in `d8e7cf3f`; the queue
contains no removal candidate.

## Plan 06 verification results

| command | result |
| --- | --- |
| `node --test test/js/playwright_repository_mode.test.mjs` | PASS (3 tests) |
| `python3 script/check_phase166_ownership_ledger.py --self-test` | PASS (15 mutation and queue controls) |
| `python3 script/check_phase166_ownership_ledger.py --verify-remediations .planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/166-ownership-ledger.md` | PASS (1 exact remediation) |
| `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 script/check_phase166_clean_checkout_engineering_quality.sh` | PASS |

The Plan 06 implementation delta is limited to this ledger plus the validator and its paired ExUnit
contract required to restore the missing fail-closed queue seam. The allowlisted browser source and
Node regression remain byte-identical to their test-first Plan 04 commits; rewriting either solely
to manufacture a Plan 06 diff is not authorized. No uncertain candidate or direct expansion changed.

## Evidence-only delta

- `.planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/evidence/clean-checkout-run.json`
- `.planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/evidence/clean-checkout-run.md`
- `.planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/166-ownership-ledger.md`
- `.planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/166-VALIDATION.md`

These four planning paths are written after the supported-code commit. Their later commit is intentionally excluded from the supported-code identity and does not require evidence to capture itself.

## D-10 duplicate review

Literal proof identities, platform-specific implementations, fixtures, validators, and negative sentinels have distinct owners or failure semantics and are retained. No pair in this cone was proven to implement the same invariant over the same input, output, authority, and failure semantics.

## D-11 compatibility review

No compatibility path was proven both migration-only and absent from every supported caller and current policy. Suspected fallbacks therefore remain retained or `unproven-retained`; the only demonstrated correction is the repository-specific browser mode scheduled in this plan.

## D-12 extraction review

No candidate presented a responsibility, side-effect, or trust-boundary split that requires extraction. File length, age, phase labels, and textual similarity were not used as evidence.
