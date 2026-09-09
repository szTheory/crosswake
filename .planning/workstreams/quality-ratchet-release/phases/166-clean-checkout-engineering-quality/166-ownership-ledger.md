# Phase 166 Ownership Ledger

- Base commit: `8383aaea2a2b2e10bbe61dd843b51f4129a5d447`
- Tree commit: `57f465321761f9fed868c79fcab79f0b66f6eada`
- Candidate rule: NUL-safe `git diff --name-only -z <base> <tree>`, excluding `.planning/`
- Unresolved flag: `FA-ENG-02` remains unresolved until the Plan 06 source corrections and Plan 08 final-tree reconciliation pass.

This ledger is deliberately bounded at the declared immutable tree. Expansion follows only a literal caller, import, include, generator, mutator, test, or shared-authority edge and stops at the last recorded direct edge. Paths, low-cardinality ownership, and dispositions are recorded; file contents, payloads, credentials, adopter facts, and environment values are excluded.

Disposition is closed to `retained`, `changed`, `removed-with-proof`, and `unproven-retained`. “Changed” identifies a demonstrated source correction for Plan 06 or an already scheduled correction. Uncertain dead, duplicate, or compatibility claims remain `unproven-retained`.

## Candidates

| candidate | evidence | owner | disposition |
| --- | --- | --- | --- |
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
| examples/phoenix_host/mix.lock | lock-governed dependency resolution | toolchain and dependency owners | retained |
| lib/crosswake/planning/closeout_verifier.ex | focused module tests and supported Mix/runtime entrypoints | planning contract owner | retained |
| lib/crosswake/planning/first_adopter_context.ex | focused module tests and supported Mix/runtime entrypoints | planning contract owner | retained |
| lib/crosswake/planning/paths.ex | focused module tests and supported Mix/runtime entrypoints | planning contract owner | retained |
| lib/crosswake/release_status.ex | focused module tests and supported Mix/runtime entrypoints | Crosswake runtime owner | retained |
| mix.lock | lock-governed dependency resolution | toolchain and dependency owners | retained |
| script/check_aggregator_result_semantics.py | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/check_ci_leaf_manifest.py | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/check_dependency_security.sh | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/check_example_host_isolation.sh | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/check_exunit_ownership.exs | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/check_phase164_dependency_security_and_gate_authority.sh | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/check_phase165_efficient_ci.sh | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/check_release_workflow_integrity.exs | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/check_required_checks_registered.sh | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/ci_docs_allowlist.json | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/ci_leaf_manifest.json | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/classify_ci_change.py | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/list_merge_blocking_checks.py | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/normalize_required_checks.py | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/register_required_checks.sh | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/repository_artifact_policy.json | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/repository_verification_stages.json | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/required_check_policy.json | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/retain_physical_iphone_evidence_transaction.sh | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/select_obsolete_ci_runs.py | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/verify_generated_android_shell.sh | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/verify_hex_publish_dry_run.sh | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/verify_repository.mjs | tracked caller, manifest, or focused regression | repository verification owner | retained |
| script/verify_repository.sh | tracked caller, manifest, or focused regression | repository verification owner | retained |
| scripts/ci_monitor.cjs | tracked caller, manifest, or focused regression | CI evidence owner | retained |
| test/crosswake/planning/closeout_ci_parity_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/planning/first_adopter_context_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/planning/milestone_transition_reset_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/planning/paths_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase134_native_gate_blocking_proof_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase135_ci_ops_proof_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase142_release_integrity_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase153_1_cache_integrity_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase153_1_gate_integrity_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase153_ios_mirror_unblock_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase164_example_host_isolation_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase164_exunit_ownership_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase165_ci_integrity_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase165_ci_policy_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase165_evidence_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase166_repository_quality_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof/phase5_proof_lane_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/crosswake/proof_lane/physical_iphone_evidence_transaction_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/fixtures/ci/cancellation/cases.json | named negative-control consumer | paired proof fixture owner | retained |
| test/fixtures/ci/classifier/cases.json | named negative-control consumer | paired proof fixture owner | retained |
| test/fixtures/ci/maximum-shape-crosswake-ci.yml | named negative-control consumer | paired proof fixture owner | retained |
| test/fixtures/ci/maximum-shape-needs.json | named negative-control consumer | paired proof fixture owner | retained |
| test/fixtures/ci/required-checks/cases.json | named negative-control consumer | paired proof fixture owner | retained |
| test/fixtures/repository_quality/artifact-cases.json | named negative-control consumer | paired proof fixture owner | retained |
| test/fixtures/repository_quality/stage-cases.json | named negative-control consumer | paired proof fixture owner | retained |
| test/fixtures/security/advisory-bearing.lock | named negative-control consumer | paired proof fixture owner | retained |
| test/js/repository_verification.test.mjs | focused test path and owning production contract | repository runner proof owner | retained |
| test/mix/tasks/crosswake_adoption_context_scan_test.exs | focused test path and owning production contract | paired ExUnit proof owner | retained |
| test/support/example_host.ex | focused test path and owning production contract | ExUnit support owner | retained |
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
| examples/phoenix_host/playwright.config.ts | browser proof owner | misleading-fallback | test/js/playwright_repository_mode.test.mjs | node --test test/js/playwright_repository_mode.test.mjs | pass |

## D-10 duplicate review

Literal proof identities, platform-specific implementations, fixtures, validators, and negative sentinels have distinct owners or failure semantics and are retained. No pair in this cone was proven to implement the same invariant over the same input, output, authority, and failure semantics.

## D-11 compatibility review

No compatibility path was proven both migration-only and absent from every supported caller and current policy. Suspected fallbacks therefore remain retained or `unproven-retained`; the only demonstrated correction is the repository-specific browser mode scheduled in this plan.

## D-12 extraction review

No candidate presented a responsibility, side-effect, or trust-boundary split that requires extraction. File length, age, phase labels, and textual similarity were not used as evidence.
