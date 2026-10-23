---
phase: 181-core-host-command-seam
plan: 02
subsystem: manifest
tags: [host-commands, manifest, entry-activation, declaration-driven-projection]
requires: [181-01]
provides:
  - Types.RouteEntry.host_commands (always serialized, {} when none)
  - Builder.host_commands_for/2 shared projection; host_command registry entries
  - IOSHostGeneration.entry_host_commands/2 (entry route's own commands only)
  - offline-study declares host.study.audio.play in the example router
affects: [181-03]
key-files:
  modified:
    - lib/crosswake/manifest/types.ex
    - lib/crosswake/manifest/builder.ex
    - lib/crosswake/manifest/validator.ex
    - lib/crosswake/manifest/manifest.ex
    - lib/crosswake/policy/compiler.ex
    - lib/crosswake/shell/ios_host_generation.ex
    - examples/phoenix_host/lib/crosswake_example/router.ex
    - test/support/host_command_fixtures.ex
  created:
    - test/crosswake/manifest/host_commands_test.exs
    - test/crosswake/shell/ios_host_generation_host_commands_test.exs
    - examples/phoenix_host/test/crosswake_example/host_command_seam_test.exs
status: complete
actuals:
  tokens: 30000
  tasks: 3
  commits: 3
plan_head_before: 428b79f636eef1170a5900bcc4937905e26d2c04
plan_head_after: f4e411926c3ff2d5b116416c2070005797bceb6c
candidate: /private/tmp/crosswake-phase181-impl
completed: 2026-10-14
---

# Phase 181 Plan 02: Per-route host commands in the manifest and entry activation

Each manifest route entry now carries a `host_commands` object (command to router-declared version). The generated entry activation carries only the entry route's own object. Projection comes from each route's own declaration; nothing is keyed to a route id, to config, or to the probe route.

## What was checked and what happened

All checks ran in the candidate with exit codes captured to files.

- Task verifies passed. Task 1 example-host seam test: 4 tests then (6 now). Task 2 combined root subset: 320 tests, 0 failures.
- Full root suite after the last product commit (`mix test --exclude requires_example_host --exclude advisory_only`): 2172 tests, 0 failures, 78 excluded. The final commit adds only an example-host test file, so the root suite was not re-run after it.
- Full `examples/phoenix_host` suite after the last commit: 150 tests, 0 failures.
- Both lockfiles unchanged; no diff under `examples/ios_shell_host/Fixtures`, `examples/android_shell_host`, `packages/crosswake-shell-core-android` or the bridge vector file. `@manifest_schema_version` untouched (181-03 owns it).
- The Phase 170 vacuity ledger tests pass (102 tests with the planning tests).
- Phase 180 candidate: HEAD 96e5a63 unchanged; its three untracked gate test files are still present and were not touched. Recovery checkout: no git mutation and no product edit.

D-10 property mechanism: a fixed-seed `:rand` loop (`:rand.seed(:exsss, {1, 2, 3})`, no new dependency) over 50 generated route sets (random subsets of a 6-command pool, versions 1.x.y, random live_view/offline_island routes). A manual mutation of `host_commands_for/2` to ignore each route's own capabilities turned 12 of 13 tests red, then was reverted.

## Commits (candidate)

| Task | Commit | Message |
| --- | --- | --- |
| 1 (tracer) | 26b252c | feat(181-02): offline-study host command flows to manifest host_commands and entry activation |
| 2 | c5d19a6 | test(181-02): declaration-driven host-command matrix with fixed-seed loop and mutation check |
| 3 | f4e4119 | test(181-02): generated offline-study entry activation resolves without a capability_version finding |

Candidate HEAD after this plan: `f4e411926c3ff2d5b116416c2070005797bceb6c`. Tree clean. Nothing pushed. Tracer gate: the Task 1 verify ran and passed before expansion.

## Deviations from Plan

**1. [Rule 3 - Blocking] Registry threaded through Manifest.compile, two files outside files_modified**
- `Builder.build/3` receives compiled routes only, not the router, so it cannot read `__crosswake_host_commands__/0` itself. `Crosswake.Manifest.compile` now resolves the registry with `Compiler.host_command_registry/2` (made public, `@doc false`) and passes it as `opts[:host_commands]`. Touched `lib/crosswake/manifest/manifest.ex` and `lib/crosswake/policy/compiler.ex` (one-line each). Builder falls back to `[]` when called directly; a host command absent from the registry is then omitted from `host_commands` (fail closed). Commit 26b252c.

**2. Plan text mismatch: the example router import line**
- The acceptance criterion names `import Crosswake.Router, except: [get: 4, live: 4], warn: false`. The candidate's example router has plain `import Crosswake.Router` (line 92). It was left unchanged, which satisfies the intent (no import edit). The registry call `crosswake_host_commands([{"host.study.audio.play", "1.0.0"}])` sits after the `crosswake:install:end` marker.

**3. Task 3 needed no fallout fixes**
- The full example suite and hermetic root suite were green with the declaration in place, so none of the five fallout candidates was edited; the only Task 3 change is the new capability_version test (plus a control proving an activation lacking the command is flagged).

**4. Test fixture helpers placed in the shared fixture file**
- `declared/1` and `check_matrix/2` live in `test/support/host_command_fixtures.ex` (in files_modified) so both new root test files share one checker. `declared/1` reads only router route metadata and registry, not the Builder. Added `UnreferencedRouter` and `SameCommandRouter` fixtures.

**5. Observation, not changed**
- `mix format --check-formatted` fails on `test/crosswake/guides/native_shell_upgrade_test.exs`, a pre-existing file from the base that this plan does not touch.
- A stale compiled beam caused one false red run after a local mutation experiment (same-second mtime); `touch` and a re-run were green. Not a product issue.

Also added: Validator rejects a route `host_commands` key not present in that route's `capabilities`; `:host` added to the Capability owner typespec and vocabulary; host-command registry entries use `rebuild: :native_required` (discretion A6).

## Known Stubs

None.

## Threat Flags

None. No new network, auth or file surface; no dependency change.

## Next action

Run plan 181-03 (manifest schema bump to 1.2.0, `compatibility.host_command_seam_version`, Swift wire fixture) in the same candidate starting from HEAD f4e4119. No human action needed. STATE.md and ROADMAP.md are left to the orchestrator.

## Self-Check: PASSED

Three commits are ancestors of HEAD, the new test files exist, the Phase 180 candidate is unchanged.
