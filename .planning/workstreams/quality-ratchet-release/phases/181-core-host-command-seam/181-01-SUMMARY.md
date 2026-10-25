---
phase: 181-core-host-command-seam
plan: 01
subsystem: policy
tags: [host-commands, router-dsl, route-policy, seam]
requires: []
provides:
  - Crosswake.HostCommands (grammar, reserved prefixes, bridge runtimes, version range, normalize_registry!/2)
  - crosswake_host_commands/1 macro and use Crosswake.Router host_commands: sugar
  - Validator.validate/3 with opts[:host_commands]; Compiler always supplies the registry
affects: [181-02, 181-03, 181-05]
key-files:
  created:
    - lib/crosswake/host_commands.ex
    - test/support/host_command_fixtures.ex
    - test/crosswake/policy/host_commands_test.exs
    - test/crosswake/router_host_commands_test.exs
  modified:
    - lib/crosswake/router.ex
    - lib/crosswake/policy/validator.ex
    - lib/crosswake/policy/compiler.ex
decisions:
  - "Registry declared once per router; routes reference names only (D-02)."
  - "host.* is a separate validator input; @known_capabilities untouched (D-03)."
  - "validate/2 has no registry; Compiler.compile/2 always passes one, fail-closed (D-27)."
status: complete
actuals:
  tokens: 28000
  tasks: 3
  commits: 4
plan_head_before: 96e5a63efab657f89f3ac84d5b1d84ff5da5d822
plan_head_after: 428b79f636eef1170a5900bcc4937905e26d2c04
candidate: /private/tmp/crosswake-phase181-impl
completed: 2026-10-14
---

# Phase 181 Plan 01: Router host-command registry and fail-closed route validation

A router now declares its `host.*` commands once, with strict SemVer versions in the supported 1.x range. Routes reference them by name. Route policy accepts exactly the declared names and rejects every other `host.*` reference at compile time with a stable error code, the route id, the command, the declared list and a fix line.

## What was checked and what happened

All checks ran in the candidate `/private/tmp/crosswake-phase181-impl` (branch `phase181-impl`, cloned from the pinned Phase 180 candidate). Exit codes were checked; no gate output was piped.

- Candidate establishment: the Phase 180 candidate was at HEAD 96e5a63e, tree 0514b624, clean tracked tree, three gate test files hashing to the pinned values. Clone made, push URL set to `no-push-phase181`, `mix deps.get` in the root and `examples/phoenix_host`, both lockfiles unchanged. After the work the Phase 180 candidate was re-checked: same HEAD, no tracked change, the three pinned hashes still match.
- Task verifies (the plan's automated commands) passed: Task 1 (3 tests), Task 2 (`test/crosswake/policy`, 61 tests then), Task 3 (86 tests across router, policy, installer test files; `check_exunit_ownership.exs` printed its OK line).
- Test counts: `host_commands_test.exs` has 14 tests, `router_host_commands_test.exs` has 11. After the last commit, `test/crosswake/policy` plus the Phase 170 ledger test: 80 tests, 0 failures.
- Full `mix test` (2153 tests, 78 excluded by tags) was run once before the last commit and had 3 failures, all in the Phase 170 vacuous-assertion ledger caused by one `Enum.any?` assertion in my new test. I replaced it with a pinned single-error match (commit 428b79f) and re-ran the ledger test plus the policy tests: green. I did not re-run the whole suite after that final fix.
- Not run: Swift, the example host, and the Phase 180 gate tests (not part of this plan).

## Commits (candidate)

| Task | Commit | Message |
| --- | --- | --- |
| 1 (tracer) | a229ea1 | feat(181-01): router-declared host commands accepted through Compiler.compile |
| 2 | 806b031 | feat(181-01): fail-closed host-command validation with stable codes |
| 3 | 9051fee | test(181-01): registry compile errors at the declaring line for both router styles |
| fix | 428b79f | test(181-01): pin the no-registry denial instead of a collection assertion |

Candidate HEAD after this plan: `428b79f636eef1170a5900bcc4937905e26d2c04`. Working tree clean. Nothing pushed.

Tracer gate: the Task 1 verify re-ran end to end and passed before the Task 2 expansion.

## Deviations from Plan

**1. [Rule 1 - Bug in plan text] The behavior case `capabilities ["audio"]` cannot be an "unknown capability"**
- Found during: Task 2 test run.
- Issue: `audio` is already a member of the existing `@known_capabilities` set at 96e5a63, so it compiles. The plan and CONTEXT D-03 assumed it was rejected.
- Fix: the closed-set test uses `audio_playback` (a truly unknown name) and asserts the existing `unknown capability` error. `@known_capabilities` has no added line.
- Files: `test/crosswake/policy/host_commands_test.exs`.
- Commit: 806b031.

**2. [Rule 3 - Blocking] Phase 170 vacuous-assertion ledger flagged a new test assertion**
- Issue: `Enum.any?` assertion at `host_commands_test.exs:33` is treated as an unclassified collection-assertion site, failing three ledger tests.
- Fix: replaced by `assert [error] = errors` plus field assertions, so the ledger snapshot needed no change.
- Commit: 428b79f.

**3. Adapter runtime is tested at the Validator level, not through Compiler**
- `Route.new` already rejects `runtime: :adapter` before validation, so the runtime-code check for `:adapter` uses a hand-built `Route` struct with `Validator.validate/3`. `:native_screen` goes through `Compiler.compile` via `NativeScreenRouter`.

**4. Extra error codes**
- Beyond the two required codes, grammar and reserved-prefix route errors carry `[crosswake.route.invalid_host_command]` and `[crosswake.route.reserved_host_command]`; registry compile errors carry `[crosswake.router.*]` codes. No wire reason codes were added (D-18 concerns the shell wire vocabulary).

## Notes for later plans

- Registry API: `Router.__crosswake_host_commands__/0` returns `[{name, version}]` sorted by name; a module with no declaration does not define the function, and the Compiler falls back to `opts[:host_commands]`, then `[]`.
- `Crosswake.HostCommands.seam_version/0` is `"1.0.0"`; `supported_command_major/0` is `1`.
- The registry duplicate/second-declaration checks use a module attribute `__crosswake_host_commands_line__`.
- Fixture routers in `Crosswake.TestSupport.HostCommandFixtures`: `DeclaringRouter`, `UseSugarRouter`, `NoRegistryRouter`, `NativeScreenRouter`, `MisspelledRouter`, `PermutedRegistryRouter`.

## Known Stubs

None.

## Threat Flags

None. No new network, auth or file-access surface; no dependency changes (both lockfiles unchanged).

## Next action

Run plan 181-02 (manifest per-route `host_commands` and capability registry projection) in the same candidate, starting from HEAD 428b79f. No human action is needed. The recovery checkout and the Phase 180 candidate were not modified; STATE.md and ROADMAP.md are left to the orchestrator.

## Self-Check: PASSED

Candidate files exist, the four commits are ancestors of HEAD, the Phase 180 candidate is unchanged and its three gate hashes still match.
