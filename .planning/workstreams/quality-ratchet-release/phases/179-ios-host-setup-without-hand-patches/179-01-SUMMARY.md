---
phase: 179-ios-host-setup-without-hand-patches
plan: 01
subsystem: ios-shell
tags: [phoenix, mix, ios, xcode, manifest]

requires:
  - phase: 178
    provides: approved Phase 179 host declaration and Xcode settings scope
provides:
  - Closed iOS host configuration normalization at the Mix task boundary
  - Host-router-derived manifest and static entry activation generation
  - Managed shell xcconfig wiring for the initial app and unit-test targets
affects: [179-02, 179-03, 179-04, ios-host-generation]

actuals:
  tokens: 7003
  tasks: 2
  commits: 2
plan_head_before: d0dbdf7bf196cea167ced3c50cf620bf3cb2452b
plan_head_after: ea003e773f573ac4aea07c161b3af016298141b9

tech-stack:
  added: []
  patterns:
    - Normalize ordinary Mix host configuration once and pass explicit values to generators
    - Build-time route activation contains route and origin truth without session or replay authority

key-files:
  created:
    - lib/crosswake/shell/ios_host_config.ex
    - lib/crosswake/shell/ios_host_generation.ex
    - priv/templates/crosswake/shell/ios/CrosswakeHostSettings.xcconfig.eex
    - test/crosswake/shell/ios_host_config_test.exs
    - test/mix/tasks/crosswake_gen_shell_host_test.exs
  modified:
    - lib/mix/tasks/crosswake.gen.shell.ex
    - priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex

key-decisions:
  - "Use the ordinary :crosswake, :ios_host declaration as the single production build-input source."
  - "Compile the selected Phoenix router without loading runtime configuration or starting the host application."
  - "Keep build-time activation limited to a declared route and URL; do not add account, session, media, or replay authority."

patterns-established:
  - "Reject invalid host configuration before creating output and keep diagnostics free of supplied values."
  - "Resolve simulator app identity through Xcode from the generated project and managed xcconfig."

requirements-completed: []
commits: 2
duration: 23min
completed: 2026-10-13
status: complete
---

# Phase 179 Plan 01: iOS Host Setup Without Hand Patches Summary

**A compile-only Phoenix declaration now produces selected-router iOS resources and an Xcode-resolved simulator app identity.**

## Performance

- **Duration:** 23 min
- **Started:** 2026-10-13T16:35:35Z
- **Completed:** 2026-10-13T16:58:17Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added closed-key validation for `:crosswake, :ios_host`, including router, HTTPS origin, entry route, bundle identities, and signing mode/team. Invalid declarations are rejected before output creation, and diagnostics do not echo supplied values.
- The shell task compiles the selected router and generates canonical manifest and static entry activation resources from the declared origin. The activation remains route-only and contains no session, scope, or replay authority.
- Generated shell app and unit-test targets inherit managed settings from `CrosswakeHostSettings.xcconfig`. A disposable Phoenix host test confirmed the Xcode-resolved simulator app identity equals the declaration held independently by the test.
- The disposable host probe confirmed the runtime sentinel was not evaluated and the Phoenix application, Endpoint, and Repo remained stopped during generation.

## Task Commits

1. **Task 1: Generate one host route and resolved shell setting end to end** — `3efbd93` (test)
2. **Task 2: Close production declaration and static-authority negatives** — `ea003e7` (feat)

These candidate-only commits are on branch `agent-phase179-01` in `/private/tmp/crosswake-phase179-impl`. The recovery checkout received no source edits, build output, generation, staging, or commits.

**Plan metadata:** Not committed here; the parent executor owns root planning state and closeout.

## Files Created/Modified

- `lib/crosswake/shell/ios_host_config.ex` — closed host declaration and fail-closed validation.
- `lib/crosswake/shell/ios_host_generation.ex` — selected-router manifest, static activation, and settings rendering.
- `lib/mix/tasks/crosswake.gen.shell.ex` — compile-only production config path; existing local/dev and Android branches remain available.
- `priv/templates/crosswake/shell/ios/CrosswakeHostSettings.xcconfig.eex` — host identity and signing settings.
- `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex` — root xcconfig reference and app/test target wiring.
- `test/crosswake/shell/ios_host_config_test.exs` — configuration, origin, identity, selected-router, and static-authority checks.
- `test/mix/tasks/crosswake_gen_shell_host_test.exs` — disposable Phoenix host, runtime sentinel, output denial, and real Xcode settings checks.

## Decisions Made

- The ordinary Mix declaration remains the only production host-input authority; generation receives the normalized struct explicitly.
- The selected router determines serialized route truth, while entry activation is static metadata and grants no runtime authority.
- Test-only Xcode package, derived-data, and repository caches live under the disposable host. The candidate source stayed at the pinned base before edits: `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b`, tree `12a0f1bf3c32ecdde0326f4a288b597b11e33b06`.

## TDD Gate Compliance

- **Task 1 RED:** The real host subprocess returned successfully, but the baseline generated artifact did not contain the declared host origin. The target test failed at its origin assertion; it was not a compile, load, or fixture failure. The final test now checks the canonical `host.origin` field and passes.
- **Task 2 RED:** The named origin-validation test failed because normalization accepted a hostname containing spaces. Validation now checks DNS labels and rejects the value without echoing it.
- **GREEN:** The final scoped suite passed all 29 tests, including the real Phoenix host and actual Xcode simulator settings query. The existing shell-generator suite passed all 4 tests.
- **Reporter limitation:** The local GSD RED classifier does not have an ExUnit console adapter. The unmodified ExUnit output and the named assertion failures were inspected directly for semantic RED evidence; no machine `RED_EVIDENCE_OK` verdict is claimed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing validation] Reject malformed DNS hostnames**
- **Found during:** Task 2
- **Issue:** URI parsing accepted a host containing spaces as a valid HTTPS origin.
- **Fix:** Require valid DNS labels before generation and return a safe origin-field diagnostic.
- **Files modified:** `lib/crosswake/shell/ios_host_config.ex`, `test/crosswake/shell/ios_host_config_test.exs`
- **Verification:** The targeted RED reproduced the acceptance; the final scoped suite passed.
- **Committed in:** `ea003e7`

**Total deviations:** 1 auto-fixed (Rule 2)
**Impact on plan:** The additional hostname check closes a production-input validation gap directly related to the declared origin trust boundary.

## Verification

- `MIX_ENV=test mix test test/crosswake/shell/ios_host_config_test.exs test/mix/tasks/crosswake_gen_shell_host_test.exs test/crosswake/manifest/manifest_test.exs test/crosswake/shell/activation_test.exs --seed 0` — **29 tests, 0 failures**. This run included the real disposable Phoenix compile, runtime/app-stop assertions, generated JSON inspection, and `xcodebuild -showBuildSettings -json` for the simulator shell target.
- `MIX_ENV=test mix test test/mix/tasks/crosswake_gen_shell_test.exs --seed 0` — **4 tests, 0 failures**, preserving existing local/dev and Android generator behavior.
- Dependency resolution used the exact locked versions in the candidate. The default Hex cache was unwritable and lacked one registry entry, so a temporary Hex home under `/private/tmp` was used; no dependency upgrades were made.

## Issues Encountered

- The first Xcode query ran without access to protected macOS Xcode services and exited before settings inspection. The authorized candidate test was rerun with Xcode access and temporary package/derived-data paths; the final query passed.
- Initial PBX wiring placed the xcconfig file reference inside the Fixtures group. Xcode omitted those settings, revealing the defect; the reference was moved to the project root group and the resolved identity then matched.

## User Setup Required

None.

## Next Phase Readiness

Plan 01 is complete. This does not complete IOS-01, IOS-02, IOS-03, or Phase 179: managed-output ownership/recovery, proof-target projections and the effective Xcode matrix, and guide reconciliation remain in Plans 02–04. No signing, installation, physical-device, or adopter proof is claimed.

---
*Phase: 179-ios-host-setup-without-hand-patches*
*Plan: 01*
*Completed: 2026-10-13*

## Self-Check: PASSED

- Summary file exists at the required phase path.
- Candidate commits `3efbd93` and `ea003e7` are ancestors of candidate HEAD `ea003e773f573ac4aea07c161b3af016298141b9`.
- Candidate working tree is clean.
