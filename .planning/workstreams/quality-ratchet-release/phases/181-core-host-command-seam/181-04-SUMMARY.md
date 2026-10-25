---
phase: 181-core-host-command-seam
plan: 04
subsystem: generation-gate-diagnostics
tags: [host-commands, shell-package-gate, doctor, inspect]
requires: [181-03]
provides:
  - Crosswake.Shell.ShellPackage (resolve/1, seam_version_at/1, first_seam_release/0 = nil, satisfies?/2)
  - IOSHostGeneration.render/2 shell_package: option with fail-closed gate
  - Swift public enum HostCommandSeam { version = "1.0.0" }
  - doctor findings host_commands_stale and host_command_shell_unsupported (check host_commands)
key-files:
  created:
    - lib/crosswake/shell/shell_package.ex
    - test/crosswake/shell/shell_package_test.exs
    - test/crosswake/shell/host_command_seam_swift_constant_test.exs
    - test/mix/tasks/crosswake_gen_shell_host_commands_test.exs
    - test/crosswake/doctor/doctor_host_commands_test.exs
    - test/crosswake/operator_inspection_host_commands_test.exs
  modified:
    - lib/crosswake/shell/ios_host_generation.ex
    - lib/mix/tasks/crosswake.gen.shell.ex
    - lib/crosswake/doctor/doctor.ex
    - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift
    - test/crosswake/shell/ios_host_generation_host_commands_test.exs
    - test/mix/tasks/crosswake_gen_shell_host_test.exs
status: complete
actuals:
  tokens: 30000
  tasks: 3
  commits: 4
plan_head_before: 257a337ea041fe16b8e5f64793974b71ad79243b
plan_head_after: fead90724b6ee2cd7ca7a96725dcfc31e98a21ba
candidate: /private/tmp/crosswake-phase181-impl
completed: 2026-10-14
---

# Phase 181 Plan 04: Shell-package gate, doctor and inspect diagnostics

Generating an iOS shell for a router that declares host commands now succeeds only when the shell package is shown to carry host-command seam version 1.0.0 or later. If it cannot be shown, generation stops with a message naming the route, the command, the package location, what was found and one fix. Doctor reports the same verdict plus stale generated manifests. Inspect already showed host commands correctly, so it needed no product change.

## Gate decision table

| Package context | Declaring route | Result |
| --- | --- | --- |
| no shell_package option (render/1) | any | pure projection, no gate |
| any | none | allowed, never gated |
| local, constant 1.0.0 or later | yes | allowed |
| local, older constant (0.9.0) | yes | blocked, "older than 1.0.0" |
| local, no HostCommandSeam declaration or malformed version | yes | blocked |
| remote (any version; first_seam_release/0 is nil) | yes | blocked, "carries no host-command seam release" |
| project file present: local relativePath, remote minimumVersion or Package.resolved pin | yes | resolved as above |
| project path unresolvable | yes | blocked, "could not be determined" |

Every blocked message contains the route id, the command and `crosswake-shell-core-ios`, and ends with one `Fix:`.

## What was checked

All runs captured to files, exit codes checked, after the last commit (tree clean).

- Root suite (`mix test --exclude requires_example_host --exclude advisory_only`): 2205 tests, 0 failures, 78 excluded (was 2177).
- `examples/phoenix_host`: 150 tests, 0 failures.
- `swift test` in packages/crosswake-shell-core-ios: 39 tests, 0 failures. `swift build` passed after adding the enum.
- `script/assert_manifest_contract_unchanged.sh` exit 0; `script/check_exunit_ownership.exs` exit 0; the Phase 170 ledger `--check` exit 0 (235 sites, no re-snapshot).
- No diff against base under examples/android_shell_host or packages/crosswake-shell-core-android. Phase 180 candidate untouched; recovery checkout had no git mutation and no product edit.

## Commits (candidate)

| Task | Commit | Message |
| --- | --- | --- |
| 1 (tracer) | 6f98715 | feat(181-04): fail-closed shell-package gate for host-command generation |
| 2 | d63de95 | feat(181-04): doctor findings for stale host_commands and unsupported shell package |
| 3 | 218dbfe | test(181-04): inspect shows declaring routes' runtime and host commands with owner host |
| ledger fix | fead907 | test(181-04): avoid ledgered Enum.all? shape in doctor host-command privacy test |

Candidate HEAD: `fead90724b6ee2cd7ca7a96725dcfc31e98a21ba`. Nothing pushed.

## Deviations from Plan

**1. [Rule 3 - Blocking] gen.shell chooses a local package context when packages/crosswake-shell-core-ios exists under the working directory**
- The `:ios_host` path rejects `--local`, so it renders the remote package reference. With the example router now declaring a command, the existing `crosswake_gen_shell_host_test.exs` was blocked by the new gate (remote carries no seam release).
- Fix: when a host-config generation runs and `packages/crosswake-shell-core-ios` exists under cwd (monorepo case), `shell_package_context/2` returns `{:local, dir}` and the generated project uses the local reference (`local or ...` passed to generate_ios_shell). An existing managed project file is authoritative (`{:project, root}`); otherwise `{:remote, nil}` (blocked when a route declares). Published hosts have no packages directory, so they are unaffected.
- The existing host test now symlinks the in-repo package into its temp host copy (6 added lines). Task 1 test files exercise the blocking path from a temp cwd with no packages directory.

**2. [Rule 1 - Bug] Ledgered `Enum.all?` assertion in my new doctor test**
- It tripped the Phase 170 vacuity ledger (3 proof test failures in the full suite). Rewritten as a `for` loop after a pinned code assertion; no ledger re-snapshot (fead907).

**3. Task 3 needed no product change**
- The existing capability view already renders `owner: "host"` and `family: "host_command"` for host commands; the phase52 golden test passes unchanged. Only a new test file was added.

**4. ios_host_generation_host_commands_test.exs** already existed from 181-02; the gate tests were appended to it instead of creating it.

## Known Stubs

None.

## Threat Flags

None. Doctor details are limited to route_id, commands, platform, package_location, found_version, required_version (asserted by a test).

## Next action

181-05 extends `HostCommandSeam` with the grammar check and the Swift side of the seam (the generation half of D-16 is done). Residual (D-16d): an older compiled shell fed fixtures generated outside the gate is only detected by doctor where the managed project shows the package; document in 181-09.
