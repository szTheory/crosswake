---
phase: "179"
slug: "ios-host-setup-without-hand-patches"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-13"
---

# Phase 179 — Validation Strategy

This audit maps all eight executed tasks and all three IOS requirements to passing automated behavior checks. Commands ran in the qualified independent candidate or disposable host fixtures; no product command ran in the protected recovery checkout. Final source-bound results are in [179-PROOF-RESULTS.json](179-PROOF-RESULTS.json), with audit repairs and process limits in [179-EXECUTION.md](179-EXECUTION.md).

## Test Infrastructure

| Property | Value |
|---|---|
| Framework | Existing ExUnit, real Phoenix host subprocess, Xcode effective-settings inspection |
| Config | `mix.exs`, `test/test_helper.exs`; ordinary host build config |
| Quick baseline | `MIX_ENV=test mix test test/mix/tasks/crosswake_gen_shell_test.exs test/mix/tasks/crosswake_gen_shell_diff_test.exs test/mix/tasks/crosswake_gen_shell_stamp_test.exs test/mix/tasks/crosswake_gen_proof_lane_test.exs` |
| Full relevant gate | Existing repository verifier root/example-host/iOS package leaves plus the new host generation and effective-settings checks; exact commands in plans |
| Observed final runtime | Root 320.21s; example host 1211.56s; iOS package 23.9s; Node Xcode suite 120.76s |

## Sampling Rate

Run the affected focused assertions after each task, and each plan's full scoped gate before its summary. Run the generation/ownership, canonical manifest/activation, actual Phoenix absent-runtime-credentials and Xcode matrix checks before phase verification. No watch mode or human UAT. Source commits, if applicable, belong only to the independently authorized execution surface; recovery Git writes remain forbidden.

## Per-Task Verification Map

All commands below use `/private/tmp/crosswake-phase179-impl` as cwd after 179-01 T1 confirms the separate clean source `/private/tmp/crosswake-phase179-source` at HEAD `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b` and tree `12a0f1bf3c32ecdde0326f4a288b597b11e33b06` or explicitly reconciles a changed base, then creates and records the independent implementation clone. Before each command, the executor asserts that candidate directory exists, its realpath and Git top-level equal the recorded path, its recorded base matches the qualified source, and required prior-plan outputs exist; a mismatch stops execution. The recovery-root path probe's eight `outside_root` warnings are intentional D-02/D-21 candidate exceptions after this qualification, not resolved by executing in recovery. Paths marked **new** are created by the named task before its command runs. The qualified candidate is recorded in `179-CANDIDATE.json`. Each task command ran during execution; final root/example-host/iOS leaves and the six-test Xcode matrix suite passed on committed HEAD `96e5a63`. The table retains the exact task commands and their failure conditions; every row is automated and green.

| Task | Requirement / threat | Test/script creation owner | Automated command | Fails when | Status |
|---|---|---|---|---|---|
| 179-01 T1 tracer | IOS-01/02/03; T-179-01/02 | T1: `test/mix/tasks/crosswake_gen_shell_host_test.exs` | `MIX_ENV=test mix test test/mix/tasks/crosswake_gen_shell_host_test.exs --seed 0` | Nonzero/zero tests, candidate qualification fails, real Phoenix subprocess absent, runtime sentinel evaluated, host app starts, wrong serialized route/entry/origin or actual simulator identity differs from original test-authored host declaration. | PASS |
| 179-01 T2 | IOS-01/03; T-179-01/02/03 | T2: `test/crosswake/shell/ios_host_config_test.exs` | `MIX_ENV=test mix test test/crosswake/shell/ios_host_config_test.exs test/mix/tasks/crosswake_gen_shell_host_test.exs test/crosswake/manifest/manifest_test.exs test/crosswake/shell/activation_test.exs --seed 0` | Nonzero/zero tests, invalid input writes, fixture origin accepted, private echo or static runtime authority. | PASS |
| 179-02 T1 | IOS-01; T-179-04/07 | T1: `test/crosswake/shell/managed_outputs_test.exs` | `MIX_ENV=test mix test test/crosswake/shell/managed_outputs_test.exs test/mix/tasks/crosswake_gen_shell_host_test.exs test/mix/tasks/crosswake_gen_shell_diff_test.exs test/mix/tasks/crosswake_gen_shell_stamp_test.exs --seed 0` | Nonzero/zero tests, host edit lost, read-only inspection writes, stale/unsafe output accepted or private value/hash printed. | PASS |
| 179-02 T2 | IOS-01/03; T-179-05/06 | T1's managed-output test is expanded by T2 | `MIX_ENV=test mix test test/crosswake/shell/managed_outputs_test.exs test/mix/tasks/crosswake_gen_shell_host_test.exs --seed 0` | Nonzero/zero tests, interrupted mixed set passes check or actual Xcode build, recovery loses prior state or migration changes unrelated PBX bytes. | PASS |
| 179-03 T1 | IOS-01/02; T-179-08 | Existing `test/mix/tasks/crosswake_gen_proof_lane_test.exs` expanded by T1 | `MIX_ENV=test mix test test/mix/tasks/crosswake_gen_proof_lane_test.exs --seed 0` | Nonzero/zero tests, proof identity has second authority, edited bytes lost, legacy `--config` breaks or xcconfig enters Resources. | PASS |
| 179-03 T2 | IOS-02; T-179-08/09/10 | T2: `script/verify_ios_host_settings.mjs`, `test/crosswake/shell/ios_host_effective_settings_test.mjs`; expands proof regression | `MIX_ENV=test mix test test/mix/tasks/crosswake_gen_proof_lane_test.exs --seed 0` and `node --test test/crosswake/shell/ios_host_effective_settings_test.mjs` | Nonzero/zero tests in either suite, proof migration fails, fewer than 20 effective cells, expected values sourced from generated xcconfig/metadata, original declaration missing, coherent wrong xcconfig plus metadata passes, target override goes undetected, raw expected/Xcode values retained or simulator needs Apple credentials. | PASS |
| 179-04 T1 | IOS-01/02/03; T-179-11 | Existing `test/crosswake/guides/native_shell_upgrade_test.exs` expanded by T1 | `MIX_ENV=test mix test test/crosswake/guides/native_shell_upgrade_test.exs --seed 0` | Nonzero/zero tests, guide key/flag drift, omitted repair path or unsupported physical/runtime claim. | PASS |
| 179-04 T2 | IOS-01/02/03; T-179-11/12 | Existing `test/mix/tasks/crosswake.docs.sync_test.exs` expanded by T2 | `MIX_ENV=test mix test test/mix/tasks/crosswake.docs.sync_test.exs test/crosswake/guides/native_shell_upgrade_test.exs --seed 0` followed by `script/verify_repository.sh --stage root-proof`, `--stage example-host-proof`, `--stage ios-package-proof` with pinned Node 22.14 | Nonzero/zero tests, renderer parity failure, absent stage or any required stage nonzero. | PASS |

## Wave 0 Requirements

Existing ExUnit and Xcode tooling are available. 179-01 T1 creates the real-host compile-only test before first use; 179-01 T2 creates config negatives; 179-02 T1 creates managed-output tests before T2 expands them; 179-03 T2 creates both the settings checker and its test before first use. The Node settings test holds the original ordinary host declaration in memory, derives expected IDs/signing without generated projections, executes the 20-cell Xcode matrix, and requires failure after coherent xcconfig-plus-metadata corruption and target masking in a disposable project. The declared-host proof Mix check supplies its independently declaration-derived expectation through a private in-memory pipe; no identity CLI flags, persisted expectation file or second config DSL are added. No new framework or dependency installation is selected.

## Final Scoped Gate

Passed in the qualified independent candidate: the focused shell/proof, canonical manifest/activation and new host/config/managed-output tests named in 179-04 `<verification>`, plus `node --test test/crosswake/shell/ios_host_effective_settings_test.mjs`. The repository-pinned Node 22.14 was selected first. `script/verify_repository.sh --stage root-proof`, `--stage example-host-proof` and `--stage ios-package-proof` ran as three actual commands and each passed. A nonzero exit, missing stage, zero tests, absent original host-declaration expectation, unobserved Xcode cell or failed coherent-corruption negative control leaves IOS-02 open. Retain only safe aggregate results and causes. Phase 178 `prepare_candidate`, `proposal_delivery`, `ci_evidence` and `join_proof --check` commands concern protected planning/release evidence and are explicitly excluded from this product generation gate.

## Spec-less Probe Disposition

The retained `/private/tmp/crosswake-179-edge-probe.json` reports IOS-01, IOS-02 and IOS-03 as unclassified/unresolved. Treat all three as flagged assumptions; neither an explicit test plan nor a guessed `backstop` rewrites that probe verdict. The probe likewise left descriptor-less product prohibitions unclassified. Goal verification must inspect those scope prohibitions independently against the actual source diff; this audit does not rewrite the original probe. The executable requirement gates above determine behavioral coverage.

## Manual-Only Verifications

None. All phase assertions are automated. Device settings inspection requires no signing/installation claim; physical-device proof and adopter authority remain outside this phase.

## Validation Sign-Off

- [x] Every plan task has an automated command and stated failure signal.
- [x] Missing test paths have a task creation owner before use.
- [x] No three consecutive tasks lack automated verification.
- [x] Effective settings cover five targets × Debug/Release × simulator/device SDK classes.
- [x] Every effective identity/signing assertion uses an expectation independently derived from the original ordinary host declaration; coherently wrong xcconfig plus metadata cannot pass.
- [x] All eight candidate-path commands pass the recorded realpath/Git-top-level/source-base gate before execution; outside_root remains a documented D-21 exception.
- [x] Real Phoenix generation passes with runtime-only credentials absent and applications stopped.
- [x] Ownership, nonwriting inspection, interruption/recovery, invalid inputs and static-authority negative controls pass.
- [x] Safe reports retain no raw Xcode settings, host-private values or low-entropy hashes.
- [x] `nyquist_compliant: true` earned by execution evidence.

**Audit status:** Validated against execution evidence. IOS-01, IOS-02 and IOS-03 are COVERED, with no missing, partial or manual-only behavioral checks. No tests were added by this audit; execution and the independent audit repairs already supplied the needed coverage. Test-first process debt remains separately disclosed below.

## Requirement Coverage Audit

| Requirement | Behavioral evidence | Result |
|---|---|---|
| IOS-01 | Real compile-only Phoenix host; host-edit preservation; nonwriting check/diff; unsafe-path/conflict negatives; interruption, stage-only/legacy recovery and concurrent migration controls | COVERED |
| IOS-02 | Original declaration held independently in memory; five targets × two configurations × two SDK classes; manual/automatic signing projections; coherent corruption and masking fail; Resources membership and packaged checker path controls | COVERED |
| IOS-03 | Canonical manifest/static activation; missing/malformed/example origin and route negatives; no runtime app start or credential evaluation; interrupted build denial; static output grants no auth/replay authority | COVERED |

The canonical packaged checker is `priv/crosswake/verify_ios_host_settings.mjs`; `script/verify_ios_host_settings.mjs` is the repository CLI shim. No UI deliverable or UI-SPEC exists in Phase179, so the UI-review hook does not apply. Phase179 is the first phase of v25; no prior phase verification exists in this milestone for the separate prior-phase regression discovery gate. The three existing proof leaves still ran as required.

## Process Evidence Limits

Plan03 Tasks1/2 and the Resources-membership repair lack qualifying pre-fix RED evidence. This remains advisory test-first process debt with configured `tdd_mode=false`; no passing test or later failure is relabeled as their RED. The spec-less probe's unclassified assumptions remain unchanged. Early failures without retained output retain unknown causes. These limits do not create missing behavioral coverage; see `179-EXECUTION.md` and the preserved review reports.

## Validation Audit 2026-10-14

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
