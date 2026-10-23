---
phase: 181-core-host-command-seam
plan: 03
subsystem: manifest
tags: [host-commands, manifest-schema, swift-fixture]
requires: [181-02]
provides:
  - manifest_schema_version 1.2.0 (bridge protocol stays 1.1.0)
  - compatibility.host_command_seam_version, present only when a route declares a host command
  - host_command_seam_fixture.json (Elixir-generated, manifest + activations + legacy_manifest)
key-files:
  modified:
    - lib/crosswake/manifest/types.ex
    - test/crosswake/manifest/host_commands_test.exs
    - test/crosswake/manifest/manifest_test.exs
    - test/crosswake/manifest/builder_test.exs
    - test/crosswake/doctor/doctor_test.exs
    - test/mix/tasks/crosswake_doctor_test.exs
    - test/crosswake/proof/phase64_runtime_line_policy_test.exs
    - test/crosswake/operator_inspection/formatter_test.exs
    - test/fixtures/proof/phase52_operator_inspection.json
  created:
    - test/crosswake/manifest/host_command_seam_fixture_test.exs
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/host_command_seam_fixture.json
status: complete
actuals:
  tokens: 15000
  tasks: 2
  commits: 3
plan_head_before: f4e411926c3ff2d5b116416c2070005797bceb6c
plan_head_after: 257a337ea041fe16b8e5f64793974b71ad79243b
candidate: /private/tmp/crosswake-phase181-impl
completed: 2026-10-14
---

# Phase 181 Plan 03: Manifest schema 1.2.0 and Swift seam fixture

The manifest now reports schema 1.2.0. The seam version key appears in `compatibility` only when at least one route declares a host command. A committed fixture for the Swift tests is generated from Elixir and a drift test compares it byte for byte with a fresh render.

## What was checked and what happened

All runs captured to files with exit codes checked, in the candidate, after the last product change (the final commit contains exactly the tested tree).

- Fixture drift test and host_commands test: 18 tests, 0 failures. The fixture jq shape check passed.
- Full root suite (`mix test --exclude requires_example_host --exclude advisory_only`, write switch unset): 2177 tests, 0 failures, 78 excluded.
- `examples/phoenix_host` suite: 150 tests, 0 failures.
- Swift not run: no Swift source changed (only a JSON test resource was added).
- The phase52 golden fixture differs from base by one line (numstat 1/1), and only `source.manifest_schema_version` moved.
- No diff against base 96e5a63 under mix.lock, examples/phoenix_host/mix.lock, examples/ios_shell_host/Fixtures, examples/android_shell_host, packages/crosswake-shell-core-android, either bridge_contract_vectors.json, or lib/mix/tasks/crosswake.contract.gen.ex. Phase 180 candidate untouched; recovery checkout had no git mutation and no product edit.

## Commits (candidate)

| Task | Commit | Message |
| --- | --- | --- |
| 1 (tracer) | fa08105 | feat(181-03): manifest schema 1.2.0, conditional host_command_seam_version, generated Swift seam fixture |
| 1 follow-up | 292ef40 | test(181-03): seam-key absence test uses a router with no host commands |
| 2 | 257a337 | test(181-03): re-baseline manifest schema 1.1.0 pins to 1.2.0; seam key as Root projection |

Candidate HEAD after this plan: `257a337ea041fe16b8e5f64793974b71ad79243b`. Tree clean, nothing pushed.

Re-baselined: manifest_test (3 asserts, now `Types.manifest_schema_version()`), builder_test, doctor_test (3), crosswake_doctor_test (2), phase64_runtime_line_policy_test (assert, message, test title), formatter_test, phase52 golden string.

## Deviations from Plan

**1. [Rule 1 - Bug] Seam key moved from a Compatibility struct field to a projection in `Types.to_map(Root)`**
- First commit (fa08105) added a `host_command_seam_version` struct field set in the Builder. Two existing proof tests lock `Compatibility` to exactly five fields (`types_phase64_test.exs:175`, `phase64_runtime_line_policy_test.exs:128`), and the first one is outside this plan's files. Rather than edit that lock, the key is derived in a private `compatibility_map/1` called from `to_map(Root)`: present when any route entry has non-empty `host_commands`. This also guarantees the key cannot disagree with the routes. The Builder change was reverted; the struct is back to five fields. Commit 257a337 (fa08105 alone is not a coherent state).

**2. [Rule 3 - Blocking] Phase 170 vacuity ledger kept untouched**
- Retitling the manifest_test test ("manifest keeps schema 1.1.0 ...") or adding lines to phase64_runtime_line_policy_test would have drifted rows in `script/collection_assertion_ledger.json`, outside files_modified. So the manifest_test title was left as is (it now reads stale, "1.1.0", while asserting `Types.manifest_schema_version()`), and the phase64 comment edit adds no net lines. The title is a candidate for retitling together with a ledger re-snapshot in a later plan.

**3. First commit contained a failing test (fixed in 292ef40)**
- The seam-absence test used a router that declares no registry but references a host command, which is a compile error; switched to the managed router fixture. The Task 1 verify then passed.

## Known Stubs

None.

## Threat Flags

None.

## Next action

Run plan 181-04 in the same candidate starting from HEAD 257a337. No human action needed. STATE.md and ROADMAP.md are left to the orchestrator.

## Self-Check: PASSED

Three commits are ancestors of HEAD; fixture and new test files exist and are tracked.
