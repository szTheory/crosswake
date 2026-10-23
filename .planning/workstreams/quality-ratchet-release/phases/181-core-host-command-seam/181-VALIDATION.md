---
phase: "181"
slug: "core-host-command-seam"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-14"
---

# Phase 181 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `181-RESEARCH.md` § Validation Architecture. All commands run inside the 181 candidate
> (`/private/tmp/crosswake-phase181-impl`), never in the recovery checkout.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (root and `examples/phoenix_host`), XCTest via SwiftPM, `xcodebuild build` compile check |
| **Config file** | `mix.exs`; `packages/crosswake-shell-core-ios/Package.swift` |
| **Quick run command** | `cd /private/tmp/crosswake-phase181-impl && MIX_ENV=test mix test test/crosswake/policy test/crosswake/router_test.exs test/crosswake/manifest test/crosswake/shell test/crosswake/contract test/crosswake/compatibility --seed 0` |
| **Swift quick command** | `cd /private/tmp/crosswake-phase181-impl/packages/crosswake-shell-core-ios && swift test` |
| **Full suite command** | root `MIX_ENV=test mix test`, `examples/phoenix_host` `MIX_ENV=test mix test`, `swift test`, `xcodebuild build` of `examples/ios_shell_host`, `bash script/assert_manifest_contract_unchanged.sh`, Android freeze diff, D-25 gate preflight |
| **Estimated runtime** | quick ~17 s (Elixir) + ~60 s cold (Swift); host compile ~29 s |

Never pipe a gate into `tail`/`grep` and read the pipeline status as the result. Capture to a file, test `$?`, then grep the file.

---

## Sampling Rate

- **After every task commit:** the matching quick command (root subset or `swift test --filter <Suite>`)
- **After every plan wave:** root quick command + `swift test` + example-host test dir + `xcodebuild build`
- **Before `/gsd-verify-work`:** full suite, `check_exunit_ownership.exs`, `assert_manifest_contract_unchanged.sh`, Android freeze diff, D-25 preflight all green
- **Max feedback latency:** ~90 seconds

---

## Per-Task Verification Map

Task IDs are filled in by the planner. Each requirement maps to the following proofs:

| Requirement | Behavior | Test Type | Automated Command | Failing signal | File Exists |
|-------------|----------|-----------|-------------------|----------------|-------------|
| SEAM-01 | declared `host.*` accepted; undeclared/misspelled/reserved/malformed/duplicate/non-SemVer/wrong-runtime rejected with codes | unit | `mix test test/crosswake/policy/host_commands_test.exs test/crosswake/router_host_commands_test.exs` | any rejected case accepted; message lacks route id/code/fix | ❌ W0 |
| SEAM-02 | each route's manifest `host_commands` equals its own declaration (fixed-seed generated sets); two declaring routes, no cross-leak; probe-keyed mutation turns red | unit | `mix test test/crosswake/manifest/host_commands_test.exs test/crosswake/shell/ios_host_generation_host_commands_test.exs` | any route map differs; mutation stays green | ❌ W0 |
| SEAM-02 | example router: only `offline-study` declares the command | example | `cd examples/phoenix_host && mix test test/crosswake_example/host_command_seam_test.exs` | G6/G2 invariants fail | ❌ W0 |
| SEAM-03 | session grants only declared ∩ registered ∩ version in the compiled 1.x.y range; navigation matrix equals fresh resolve; denial vocabulary closed | XCTest + ExUnit | `swift test --filter HostCommandSeamTests`; `swift test --filter HostCommandNavigationTests`; `mix test test/crosswake/proof/phase154_catalog_guard_test.exs` | grant without declaration/registration; vocabulary/pinned-line drift | ❌ W0 / guard exists |
| SEAM-04 | `offline_island` → `.offlineIsland`; other non-admitted runtimes denied; example host switch exhaustive | XCTest + compile | `swift test --filter OfflineIslandAdmissionTests`; `xcodebuild build ... CODE_SIGNING_ALLOWED=NO` | island returns `.denied`; "switch must be exhaustive" | ❌ W0 |
| SEAM-05 | manifest schema 1.2.0, bridge protocol 1.1.0, malformed field blocks boot, generation gate fail-closed, Android byte-frozen, docs/contract drift clean | unit + XCTest + script | `mix test test/crosswake/manifest test/crosswake/doctor test/crosswake/contract`; `swift test --filter HostCommandWireTests`; `git diff --exit-code 96e5a63efab657f89f3ac84d5b1d84ff5da5d822 -- examples/android_shell_host packages/crosswake-shell-core-android test/fixtures/bridge_contract_vectors.json packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json`; `bash script/assert_manifest_contract_unchanged.sh` | non-zero exit; stale `"1.1.0"` manifest assertion; any Android diff | partly |
| SEAM-06 | pinned 180 gate tests (SHA-256 matches `180-GATE.json`) refute G1–G4/G6 with controls passing; `180-SEAM-HANDOFF.json` valid and bound; 180-01/02 summaries renamed `*.baseline.md` | script | `shasum -a 256` compare; `--only phase180_gate` runs with `PHASE180_BASE_KIND=authorized_seam_rerun`; `jq -e` + `git cat-file`/`rev-parse`/`merge-base --is-ancestor` checks | gate test still passes (confirmed) or a control fails; any jq/git non-zero | ❌ W0 |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Task ID map (filled by the planner)

| Requirement | Tasks that carry the automated proof |
|-------------|--------------------------------------|
| SEAM-01 | 181-01 T1 (tracer: Compiler accepts declared, denies without registry), T2 (codes, did-you-mean, runtime, R1 arity-2), T3 (registry CompileErrors incl. versions outside the supported 1.x.y range, ownership); 181-04 T1 (author-facing gate messages) |
| SEAM-02 | 181-02 T1 (tracer: offline-study to manifest to activation), T2 (seeded loop, two-route matrix, mutation check, determinism), T3 (example-host fallout); 181-03 T1 (seam fixture drift) |
| SEAM-03 | 181-05 T1 (tracer: fixture to grant to delegate; supported-range constant and drift test), T2 (table incl. 1.0.0/1.4.2 granted and 2.0.0/9.0.0/0.9.0 denied, navigation matrix, legacy D-28, wire, diagnostics), T3 (named denials incl. version_unsupported hint, catalog guard) |
| SEAM-04 | 181-06 T1 (tracer: `.offlineIsland` plus host compile), T2 (ordering parity, D-14 hint, guards) |
| SEAM-05 | 181-03 T1 (schema 1.2.0, seam key, Swift fixture), T2 (schema-pin re-baseline, both suites); 181-04 T1-T3 (generation gate, doctor, inspect); 181-05 T1-T2 (decoder, compiled constant); 181-07 T3 (Android freeze, full regression); 181-08 T1-T2 (snippet, rendered matrix, CHANGELOG, compatibility guides); 181-09 T1-T2 (author/upgrade/offline guides, guide truth test) |
| SEAM-06 | 181-07 T1-T2 (core-head preflight); 181-10 T1 (final preflight plus rerun rehearsal), T2 (handoff R1 checks, baseline renames), T3 (TWIN text, SEAM complete, ROADMAP progress, STATE next action) |

No task lacks an `<automated>` verify; no three consecutive tasks are without one.

---

## Wave 0 Requirements

- [ ] 181 candidate created from `96e5a63efab657f89f3ac84d5b1d84ff5da5d822` with dependencies fetched
- [ ] New ExUnit files above, router fixtures under `test/support/`, ownership classified per `script/check_exunit_ownership.exs`
- [ ] New Swift test files and a generated seam manifest fixture (committed iOS/Android manifests left untouched)
- [ ] Collection-assertion ledger updated only if the inventory script reports new files

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
