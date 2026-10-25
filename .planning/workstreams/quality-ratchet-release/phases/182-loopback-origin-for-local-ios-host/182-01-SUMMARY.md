---
phase: 182-loopback-origin-for-local-ios-host
plan: 01
subsystem: ios-host-config
tags: [origin_mode, local_loopback, ios_host, info-plist, fail-closed]
requires: []
provides:
  - "origin_mode: :local_loopback declaration key validated by IOSHostConfig.normalize/2"
  - "Info.plist local-networking block emitted only for the mode"
  - "Base production golden and full generation SHA-256 manifest"
affects: [182-02]
key-files:
  created:
    - test/fixtures/shell/ios/Info.plist.production.golden
    - test/fixtures/shell/ios/production_generation.sha256.json
    - test/mix/tasks/crosswake_gen_shell_origin_mode_test.exs
  modified:
    - lib/crosswake/shell/ios_host_config.ex
    - lib/crosswake/shell/ios_host_generation.ex
    - lib/mix/tasks/crosswake.gen.shell.ex
    - priv/templates/crosswake/shell/ios/Info.plist.eex
    - test/crosswake/shell/ios_host_config_test.exs
    - test/crosswake/shell/ios_host_generation_host_commands_test.exs
decisions:
  - "Mode is checked first, then environment, then router and origin; Mix absent means :prod."
  - "Render assigns use Keyword.merge so the Info.plist origin_mode overrides the nil default."
status: complete
commits: 3
plan_head_before: 12f84cd950d4574921767df823faed6797c17c26
plan_head_after: bfd470d7535c6b77b85e636981d87a1936d5e775
actuals:
  tokens: 60000
  tasks: 2
  commits: 3
---

# Phase 182 Plan 01: Loopback origin tracer Summary

A local iOS host declaration can now opt into one explicit mode, `origin_mode: :local_loopback`, which accepts only `http://127.0.0.1[:port]` and `http://localhost[:port]` and adds a narrow local-networking block to the generated Info.plist. Production output is unchanged.

## What was checked and what happened

- Created the candidate clone `/private/tmp/crosswake-phase182-impl` on branch `phase182-impl` from the Phase 181 clone at base `12f84cd` (tree `e51f069d`), push URL `no-push-phase182`. Lockfiles unchanged. `mix deps.get` worked from the network, no offline fallback needed.
- Generated the fixed HTTPS declaration twice from the unmodified base. 17 files were produced. Only three files varied between runs, each by a derived or time field, so five normalization rules were recorded (generated_at in the manifest and shell.json, the target path in shell.json, and the generation id plus manifest digest in the managed metadata, both derived from the manifest timestamp). After normalization both runs were identical.
- Froze the Info.plist golden and the 17-file manifest in the first commit, alone.
- Implemented the validator, template and generation changes, then the full validator matrix.

## Verification results

- Task 1 verify (verbatim): exit 0, 2 tests, 0 failures.
- Task 2 verify (verbatim, including freeze checks and the ExUnit ownership script): exit 0; 139 tests, 0 failures in the combined run. Also ran the existing host-declaration test (3 tests, 0 failures), covering the "declaration keys" message.
- The end-to-end test compares every generated file for the production declaration against the base manifest after the recorded normalization, and the Info.plist byte for byte against the golden.

## Commits (in candidate phase182-impl)

- 8786292 chore(182-01): capture production generation golden and manifest from base (exactly the golden and manifest)
- 7d68cf6 feat(182-01): accept origin_mode :local_loopback and emit the local Info.plist block
- bfd470d test(182-01): complete fail-closed origin validator matrix and render defense in depth

Candidate head `bfd470d7535c6b77b85e636981d87a1936d5e775`, tree `d223e237c530d130f2a0cc8bcfcbdf70b7755ce3`. Golden sha256 `11e97fa81642e477364e9f347c649cc936d8b79e1d1bf6d0c5526e5d8bc62886`; manifest sha256 `02784ccbf12aeb4314ae6f04a5829b379aa556c5d81d0106e49b787a658013d3`.

## Deviations from Plan

**1. [Rule 1 - Bug] Assign precedence.** The first draft appended the Info.plist `origin_mode` assign after a `nil` default; EEx takes the first match, so the mode would never have reached the template. Fixed by building the assigns with `Keyword.merge` (defaults first, caller overrides). Caught before commit by the tracer test design.

**2. Test-only correction.** The plan sketch asserted manifest `allowlisted_origins` at top level; in this codebase it is per route, so the render test asserts `routes.lesson.allowlisted_origins` and `host.origin`.

Otherwise the plan was executed as written. `@template_version` stays 4; no Swift, Android, example host, lockfile or Phase 180 file changed.

## Boundary state

Recovery checkout HEAD still `d0f3e2f1` with an empty index; nothing was staged or committed there. Phase 180 clone HEAD `12f84cd` with its 21 dirty paths untouched. Phase 181 clone still clean at `12f84cd`. Only `182-CANDIDATE.json` and this summary were written in the phase directory, uncommitted.

## Known Stubs

None.

## Threat Flags

None beyond the plan's threat model.

## Next action

Execute 182-02.

## Self-Check: PASSED
