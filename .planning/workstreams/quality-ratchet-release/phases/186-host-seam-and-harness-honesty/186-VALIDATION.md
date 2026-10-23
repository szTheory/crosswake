---
phase: "186"
slug: "host-seam-and-harness-honesty"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-16"
---

# Phase 186 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `186-RESEARCH.md` § Validation Architecture. All commands run in the candidate
> `/private/tmp/crosswake-phase180-impl` with `RUNS=/private/tmp/crosswake-phase180-run`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5); XCTest via `swift test` |
| **Config file** | `test/test_helper.exs`; `packages/crosswake-shell-core-ios/Package.swift` |
| **Quick run command** | `cd $C && MIX_BUILD_PATH=$RUNS/_build_186_NN_test mix test <file> > $RUNS/<name>-186-NN.out 2>&1` then `grep -Eq '^[1-9][0-9]* tests, 0 failures'` |
| **Full suite command** | `env -u MIX_BUILD_PATH mix test --exclude requires_example_host > $RUNS/fix-186.full.out 2>&1`; failure set compared with `$RUNS/fix-185.failures` |
| **Swift command** | `cd packages/crosswake-shell-core-ios && swift test --scratch-path $RUNS/_swiftbuild_186_NN > $RUNS/swift-186-NN.out 2>&1`; gate on failing-test set equal to `$RUNS/swift-baseline-186.failures` (pre-existing G4 failure only) |
| **Estimated runtime** | focused ~30–90 s; full suite several minutes |

Never pipe a check into `tail`/`head`; never share a `MIX_BUILD_PATH` between two mix runs; never accept 0 tests.

---

## Sampling Rate

- **After every task:** the focused test file for that task (red run kept as `*-186-NN.red.out` before the fix).
- **After every plan:** all files the plan owns, `mix format --check-formatted` on changed files, `mix compile --warnings-as-errors`.
- **Before verify (plan 05):** full-suite failure set equals `fix-185.failures`; Swift failing set equals the recorded baseline; mutation controls 2–26 each show a named failing test (controls 0–1 unmutated pass).
- **Max feedback latency:** ~90 s per focused run.

---

## Per-Task Verification Map

| Task ID | Req / Criterion | Behavior | Test Type | Automated Command (from `$C`, own `MIX_BUILD_PATH`) | File | Red evidence | Status |
|---------|-----------------|----------|-----------|------------------------------------------------------|------|--------------|--------|
| 186-01-T1 (tracer) | SEAM-08, SEAM-07 / SC2, SC1 | unreadable (eisdir), malformed (7 shapes), route_missing → one `:error` `host_commands_stale` with `details.reason`; absent + declaring → `:advisory` `host_commands_stale_skipped`; legacy fixture route → `host_commands_legacy_manifest` (`:error` declaring / `:warning` otherwise) | ExUnit | `MIX_BUILD_PATH=$RUNS/_build_186_01_test mix test test/crosswake/doctor/doctor_host_commands_test.exs` | doctor_host_commands_test.exs (7 new, 2 rewritten) | `red-186-01-t1.out` | ✅ green |
| 186-01-T2 | SEAM-09 / SC3 | `ShellPackage.display_location/2`: relative, `.`, `<home>/…`, `<outside project>`, remote unchanged, non-absolute never echoed, symlinked root, prefix collision | ExUnit | `mix test test/crosswake/shell/shell_package_test.exs` | shell_package_test.exs describe "display_location/2" | `red-186-01-t2.out` | ✅ green |
| 186-01-T3 | SEAM-09 / SC3 | sentinel dir: doctor finding, gate `{:error, msg}`, raised `Mix.Error` carry neither sentinel nor home; redacted form present | ExUnit | `mix test test/crosswake/shell/path_redaction_test.exs` + doctor/shell/gate/gen.shell files; compile `--warnings-as-errors`; format | path_redaction_test.exs (new) | `red-186-01-t3.out` | ✅ green |
| 186-02-T1 (tracer) | SEAM-07 / SC1 | legacy route grants nothing; `not_registered` / `version_unsupported` denials with diagnostics; plain route none | XCTest | `swift test --scratch-path $RUNS/_swiftbuild_186_02` (failing set `cmp` `swift-baseline-186.failures`) | HostCommandNavigationTests.swift | `swift-186-02.red.failures` | ✅ green |
| 186-02-T2 | SEAM-07 / SC1 | Phase 180 G3 control no longer pins the legacy grant; run once against the tracked example export | XCTest | `PHASE180_EXPORT_DIR=<example Fixtures> swift test --filter Phase180TwinFeasibilityTests`; full run vs baseline | Phase180TwinFeasibilityTests.swift | `swift-186-02.g3.red.out` (or `.g3.note`) | ✅ green |
| 186-02-T3 | SEAM-07, SEAM-09 / SC1, SC3 | upgrade-guide legacy row, compatibility seam floor (`seam_unsupported`), CHANGELOG "Legacy-manifest denial" bullet | ExUnit | `mix test test/crosswake/guides` + changelog readers; `mix crosswake.docs.sync --check` | host_command_seam_guide_test.exs | `guides-186-02.red.out` | ✅ green |
| 186-03-T1 (tracer) | LOOP-06 / SC4 | shimmed baseline passes; uninstall / restore failure → `LOOP-IOS-CLEANUP` exit 2; long device list read correctly | ExUnit (bash + PATH shims) | `mix test test/crosswake/proof_lane/loopback_origin_harness_test.exs` | loopback_origin_harness_test.exs (new) | `red-186-03-t1.out`, `red-186-03-t1b.out` | ✅ green |
| 186-03-T2 | LOOP-06 / SC4 | three-point full-tree hash → `LOOP-IOS-OWNED-HASH`; evidence precheck / checked mv → `LOOP-IOS-EVIDENCE`; byproduct allow-list | ExUnit (bash + PATH shims) | same file | loopback_origin_harness_test.exs | `red-186-03-t2.out` | ✅ green |
| 186-03-T3 | LOOP-06 / SC4 | guide documents the harness as manual phase evidence, exit codes 0/2/3, not a CI lane | ExUnit | `mix test test/crosswake/guides`; docs sync; `bash -n` | loopback_origin_guide_test.exs | `guide-186-03.red.out` | ✅ green |
| 186-04-T1 (tracer) | LOOP-07 / SC5 | `--preflight-only` / `--readiness` / `--run` blocked with `PI-PREFLIGHT-CONFIG` for a local declaration and for real local-mode gen.shell output; `device_report` never called; production control passes | ExUnit | `mix test test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs test/crosswake/proof_lane/physical_iphone_preflight_test.exs` | physical_iphone_test.exs | `red-186-04.out` + `.verdict` | ✅ green |
| 186-04-T2 | LOOP-07 / SC5 | preflight origin check (only if red) with `Generator.local_mode_refusal/0` text, no new rule id | ExUnit | same files + gen_proof_lane, origin-mode tests; compile; format | physical_iphone_preflight.ex | (T1 red run) | ✅ green |
| 186-05-T1 (tracer) | all / SC1-5 | full suite failure set = `fix-185.failures`; Swift set = `swift-baseline-186.failures`; focused, guides, ledger, docs, compile, format, adoption, diff boundaries | mixed | `env -u MIX_BUILD_PATH mix test --exclude requires_example_host`; `swift test --scratch-path $RUNS/_swiftbuild_186_05` | `$RUNS` records | n/a | ✅ green |
| 186-05-T2 | all | 27 mutation controls (0-1 unmutated, 2-26 each fail named tests) in `/private/tmp/crosswake-186-mutation` | mixed | `bash $RUNS/mutate-186.sh` | `mutation-186.log` | each control | ✅ green |
| 186-05-T3 | all | single `fix(186)` commit; probe all-zero; read-only twin preflight exit 2; history 87 OK; home-path / username scan | mixed | per 186-05-PLAN Task 3 | `fix-186.commit`, `home-scan-186.log` | n/a | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Swift baseline failing set recorded in `$RUNS/swift-baseline-186.failures` (G4 only) by 186-02 Task 1 before any Swift edit.
- [ ] New test files: `test/crosswake/shell/path_redaction_test.exs`, `test/crosswake/proof_lane/loopback_origin_harness_test.exs`.
- [ ] Harness test helpers: temp clone builder outside the repo, shim writers (`mix`, `xcodebuild`, `plutil`, `xcrun`, `mv`, `shasum` fallback over `sha256sum` when missing).
- [x] `mutate-186.sh` derived from `mutate-185.sh` by 186-05 Task 2 (throwaway copy, own `MIX_BUILD_PATH` and Swift scratch path, sha256 before/after must differ, 27 control lines).

---

## Manual-Only Verifications

All phase behaviors have automated verification. The harness itself is never run against a real Simulator in this phase (Phase 188 reruns it).

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s per focused run
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
