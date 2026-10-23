---
phase: 179-ios-host-setup-without-hand-patches
verified: 2026-10-14T01:17:58Z
status: passed
score: 4/4 roadmap truths verified on the bound candidate
candidate_head: 96e5a63efab657f89f3ac84d5b1d84ff5da5d822
candidate_tree: 0514b6244ec814c1d0701d580b04651f70f57019
candidate_report: .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/179-VERIFICATION.md in /private/tmp/crosswake-phase179-impl
candidate_binding: 179-VERIFICATION-BINDING.json
recovery_source: unchanged; not the implementation certified by this report
behavior_unverified: 0
overrides_applied: 0
covered_files:
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/179-01-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/179-01-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/179-02-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/179-02-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/179-03-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/179-03-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/179-04-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/179-04-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/179-CANDIDATE.json
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/179-CONTEXT.md
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/179-EXECUTION.md
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/179-PRESERVATION.json
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/179-PROOF-RESULTS.json
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/179-RESEARCH.md
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/179-REVIEW-DISPOSITION.md
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/179-REVIEW.md
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/179-SECURITY.md
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/179-SOURCE-SNAPSHOT.json
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/179-VALIDATION.md
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/179-VERIFICATION-BINDING.json
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/guides/capability_map.md
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/guides/native_shell.md
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/guides/native_shell_upgrade.md
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/guides/support_matrix.md
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/lib/crosswake/capability_map/renderer.ex
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/lib/crosswake/manifest/builder.ex
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/lib/crosswake/manifest/manifest.ex
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/lib/crosswake/manifest/serializer.ex
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/lib/crosswake/manifest/validator.ex
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/lib/crosswake/proof_lane/config.ex
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/lib/crosswake/proof_lane/generator.ex
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/lib/crosswake/proof_lane/generator_fs.ex
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/lib/crosswake/shell/activation.ex
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/lib/crosswake/shell/ios_host_config.ex
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/lib/crosswake/shell/ios_host_generation.ex
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/lib/crosswake/shell/ios_host_project_migration.ex
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/lib/crosswake/shell/managed_outputs.ex
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/lib/crosswake/shell/pbx_project.ex
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/lib/crosswake/support_matrix/renderer.ex
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/lib/mix/tasks/crosswake.gen.proof_lane.ex
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/lib/mix/tasks/crosswake.gen.shell.ex
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/mix.exs
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/mix.lock
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/PackStore.swift
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/priv/crosswake/verify_ios_host_settings.mjs
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/priv/native/crosswake_proof_lane_fs.c
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/priv/templates/crosswake/proof_lane/ios/CrosswakeProofSettings.xcconfig.eex
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/priv/templates/crosswake/shell/ios/CrosswakeHostSettings.xcconfig.eex
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/script/collection_assertion_ledger.json
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/script/verify_ios_host_settings.mjs
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/test/crosswake/guides/native_shell_upgrade_test.exs
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/test/crosswake/proof/phase134_template_version_drift_test.exs
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/test/crosswake/proof_lane/recovery_edges_test.exs
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/test/crosswake/proof_lane/template_contract_test.exs
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/test/crosswake/shell/ios_host_config_test.exs
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/test/crosswake/shell/ios_host_effective_settings_test.mjs
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/test/crosswake/shell/ios_host_migration_graph_test.exs
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/test/crosswake/shell/ios_host_migration_security_test.exs
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/test/crosswake/shell/managed_outputs_test.exs
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/test/mix/tasks/crosswake.docs.sync_test.exs
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/test/mix/tasks/crosswake_gen_proof_lane_test.exs
  - .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/candidate-source/test/mix/tasks/crosswake_gen_shell_host_test.exs
covered_digest: "v3:sha256:645a152b6fc70493357b2fccb08aaea0c5d031d3ec895d803156f169fa170ef1"
---

# Phase 179: iOS Host Setup Without Hand Patches — Root Artifact Verdict

This report records the goal verdict for the exact committed candidate identified above. The actual implementation was inspected and behaviorally verified in `/private/tmp/crosswake-phase179-impl`; this recovery checkout's product source remains unchanged and is not the implementation being certified. The immutable `candidate-source/` export is corroborating source evidence only; no code from that export was executed. `179-VERIFICATION-BINDING.json` retains the candidate report fingerprint and verdict.

**Phase Goal:** Maintainers can produce and inspect a correctly configured iOS host from one ordinary Phoenix/Mix build declaration while retaining host-owned native edits.
**Status:** passed
**Score:** 4/4 roadmap truths verified on candidate `96e5a63efab657f89f3ac84d5b1d84ff5da5d822`.

## Goal Achievement

The bound candidate implements the single Mix declaration path through validation, selected-router manifest compilation, route-only static activation, managed iOS generation, and the proof target's shared identity/settings configuration. Host-owned native edits remain outside the managed projection allowlist. Check/diff inspect without writes, while interrupted publication denies checks/builds until bounded recovery; edited projects receive an opt-in recognized migration. Effective Xcode settings are compared against values independently derived from the original declaration across the full target/configuration/SDK matrix. The candidate tests and final proof evidence satisfy all four authoritative Phase 179 success criteria.

| # | Roadmap truth | Status | Candidate evidence |
|---|---|---|---|
| 1 | Normal Mix host configuration carries route, entry, origin, and identity/signing values; generation compiles the router without starting Phoenix or evaluating unrelated runtime credentials. | ✓ VERIFIED | Candidate report: 179-VERIFICATION.md, truth 1; real Phoenix-host test; final root-proof exit 0. |
| 2 | Generation preserves host edits; check/diff remain nonwriting; conflicts, invalid inputs and interrupted updates fail closed with safe repair. | ✓ VERIFIED | Candidate report: truth 2; guarded focused run: 15 tests, 0 failures; final security audit 13/13 closed and code review 0 findings. |
| 3 | Effective shell/proof Xcode settings represent simulator/device modes; config stays out of Resources; device settings do not claim installation. | ✓ VERIFIED | Candidate report: truth 3; final Node settings suite 6/6, 20 settings cells per signing mode; iOS package proof 39 tests, 0 failures. |
| 4 | Canonical manifest/static activation derives from the selected host router and declared route/origin, rejects invalid production inputs, and grants no runtime authority. | ✓ VERIFIED | Candidate report: truth 4; config/manifest/activation tests and final root-proof; guide and support/capability parity checks. |

**Score:** 4/4 roadmap truths verified (0 present, behavior-unverified).

## Requirements Coverage

The authoritative root requirements assign IOS-01, IOS-02 and IOS-03 to Phase 179. The four plans declare only these IDs; all are accounted for and none is orphaned.

| Requirement | Source plans | Status | Evidence |
|---|---|---|---|
| IOS-01 | 179-01, 179-02, 179-03, 179-04 | ✓ SATISFIED | Candidate implements and tests ordinary declaration input, compile-only host route generation, preservation of host-owned edits, nonwriting inspection and recovery. |
| IOS-02 | 179-01, 179-03, 179-04 | ✓ SATISFIED | Candidate tests compare actual Xcode settings to independently derived host declaration expectations across five targets, Debug/Release, and simulator/device classes. |
| IOS-03 | 179-01, 179-02, 179-04 | ✓ SATISFIED | Candidate tests validate selected-router manifest and static activation, invalid origin/route denial, interruption behavior and explicit authority boundaries. |

## Scope and Evidence Limits

The candidate's plan prohibitions were checked against actual source, test contracts, final guides, proof results and the security/review audits. Production generation rejects example or placeholder origins; static activation grants no session, scope, verified media or replay authority; effective device settings do not assert signed installation or physical-iPhone support; managed file replacements are not described as set-wide atomic; and native edits are preserved or denied for explicit recovery/migration. There is no Android expansion, package release, adopter promotion or Phase 180 result.

The source snapshot helper independently confirmed that all 45 exported files match the candidate's committed blobs and that the candidate tracked product tree is clean at the pinned HEAD/tree. The recovery preservation record reports unchanged recovery HEAD/index and zero changes among 1,263 non-planning tracked files. No product source, build, generation, Git mutation or remote operation was performed in the recovery checkout.

Plan 03's missing pre-fix RED evidence and the Resources-membership repair remain disclosed process debt; two early subprocess failures lack retained output and remain unexplained. These are not unverified product behaviors: final code review, independent security audit, and the final committed-source proof gates passed. The prior spec-less probe's unclassified assumptions remain unclassified; this verification does not recast them as a backstop. No human-only check remains.

---

_Verified: 2026-10-14T01:17:58Z_
_Verifier: the agent (gsd-verifier)_
