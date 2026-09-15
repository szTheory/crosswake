---
phase: 165-efficient-and-maintainable-ci
plan: 04
subsystem: ci
tags: [github-actions, runners, caching, android, swift, timeouts]
requires:
  - phase: 165-efficient-and-maintainable-ci
    plan: 02
    provides: exact proof inventory and closed CI policy
  - phase: 165-efficient-and-maintainable-ci
    plan: 03
    provides: trusted monotonic cancellation controller
provides:
  - Portable generated Android JVM proof and a reusable official JDK/Gradle setup contract
  - Complete BEAM, Gradle, and Swift compiled-cache compatibility identity
  - Command-classified runner placement, positive per-job timeout, assertion-retry, and release-trust audits
affects: [165-05, 165-06, 165-07, 165-08, 165-09, 165-10]
actuals:
  tokens: 11441
  tasks: 3
  commits: 8
tech-stack:
  added: []
  patterns:
    - Portable JVM proof exits before optional connected-device provisioning
    - Official cache actions receive complete compatibility identity and expose only closed outcomes
    - Repository-wide CI audits classify job commands rather than workflow filenames
key-files:
  created:
    - .github/actions/setup-android-jvm/action.yml
  modified:
    - script/verify_generated_android_shell.sh
    - .github/actions/setup-elixir-cache/action.yml
    - .github/workflows/native-behavioral-proof-gate.yml
    - .github/workflows/phase5-proof.yml
    - .github/workflows/phase18-proof.yml
    - .github/workflows/phase79-proof.yml
    - test/crosswake/proof/phase165_ci_integrity_test.exs
key-decisions:
  - "Treat CROSSWAKE_ANDROID_CONNECTED_TESTS=0 as an early portable exit that consumes preconfigured Java, Android SDK, and Gradle state without invoking macOS provisioning."
  - "Keep compiled BEAM build restores exact-only, while a deps-only partial restore remains observable as a closed partial/miss outcome and shared Hex storage remains inert tarballs only."
  - "Bind official setup-gradle caching to architecture, JDK, wrapper-derived Gradle, job topology, and relevant configuration/lock content without adding a second Gradle User Home cache."
patterns-established:
  - "Runner boundary: pure Elixir and Android JVM jobs use Ubuntu; legacy display identities remain on macOS only where the job invokes iOS tooling."
  - "Cache boundary: compatibility changes miss by construction, and primary Crosswake verdicts retain no raw cache keys or toolchain internals."
requirements-completed: [CIP-01, CIP-03, CIP-04]
coverage:
  - id: D1
    description: Portable generated Android package and JVM proof runs on Ubuntu through one official JDK 17 and wrapper-validating Gradle setup action.
    requirement: CIP-01
    verification:
      - kind: integration
        ref: bash -n script/verify_generated_android_shell.sh && shellcheck script/verify_generated_android_shell.sh && actionlint .github/workflows/native-behavioral-proof-gate.yml && mix test test/crosswake/proof/phase165_ci_integrity_test.exs --only runner_placement
        status: pass
    human_judgment: false
  - id: D2
    description: BEAM, Gradle, and Swift cache identities reject every independently mutated compatibility dimension and expose no raw cache keys.
    requirement: CIP-03
    verification:
      - kind: integration
        ref: mix test test/crosswake/proof/phase165_ci_integrity_test.exs --only cache_identity
        status: pass
    human_judgment: false
  - id: D3
    description: Every workflow job has a positive timeout, ordinary assertions are not retried, and Release Please trust semantics remain unchanged.
    requirement: CIP-04
    verification:
      - kind: integration
        ref: actionlint .github/workflows/phase5-proof.yml .github/workflows/phase18-proof.yml .github/workflows/phase79-proof.yml && mix test test/crosswake/proof/phase165_ci_integrity_test.exs --only timeout --only release_trust
        status: pass
    human_judgment: false
duration: 16 min
completed: 2026-09-07
status: complete
---

# Phase 165 Plan 04: Runner, Cache, and Timeout Integrity Summary

**Portable Android JVM proof, exact compiled-cache identities, and repository-wide timeout and runner audits now remove macOS waste without widening Android or weakening release trust.**

## Performance

- **Duration:** 16 min
- **Started:** 2026-09-08T00:57:00Z
- **Completed:** 2026-09-08T01:13:11Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Split generated Android verification so JVM-only mode exits before macOS JDK, SDK, emulator, and connected-device provisioning, then moved both Android JVM jobs to Ubuntu through a shared official setup action.
- Completed BEAM, Gradle, and Swift cache compatibility identities across dependency scope/topology, OS/architecture, toolchains, environments, manifests, locks, and explicit Swift resolved-state presence.
- Split Phase 5, Phase 18, and Phase 79 proof at their actual Apple boundary and added an exact repository-wide audit for runner placement, every-job timeouts, ordinary assertion retries, and Release Please trust posture.

## Task Commits

1. **Task 1 RED: portable Android runner contracts** - `7cb65bc4` (test)
2. **Task 1 GREEN: portable generated Android JVM proof** - `d0eb9a8f` (feat)
3. **Task 2 RED: cache compatibility contracts** - `10b7e0b5` (test)
4. **Task 2 GREEN: complete compiled-cache identity** - `7628eddb` (feat)
5. **Task 3 RED: runner and timeout inventory contracts** - `9cd2b5b7` (test)
6. **Task 3 GREEN: legacy runner split and repository audit** - `4bd38cc5` (feat)
7. **Formatting: CI integrity contracts** - `a5b98148` (style)
8. **Rule 2 fix: complete Gradle cache identity** - `aa2afcc2` (fix)

## Files Created/Modified

- `.github/actions/setup-android-jvm/action.yml` - Configures Temurin 17 and wrapper-derived Gradle with official validation/caching and full JVM/config compatibility identity.
- `script/verify_generated_android_shell.sh` - Separates portable generation/JVM proof from optional connected provisioning.
- `.github/actions/setup-elixir-cache/action.yml` - Preserves scoped BEAM caches, makes build restores exact-only, and exports closed exact/partial/miss state.
- `.github/workflows/native-behavioral-proof-gate.yml` - Runs Android JVM leaves on Ubuntu and keys Swift build state by platform, architecture, toolchain, manifest, and resolved state.
- `.github/workflows/phase5-proof.yml` - Moves explicitly non-native Phase 5 proof to Ubuntu and removes dead Apple configuration.
- `.github/workflows/phase18-proof.yml` - Splits portable Elixir/Android proof from the retained iOS job.
- `.github/workflows/phase79-proof.yml` - Retains the literal macOS v5 proof for iOS and adds a bounded Ubuntu Android JVM leaf.
- `test/crosswake/proof/phase165_ci_integrity_test.exs` - Proves runner, cache, timeout, assertion-retry, and release-trust invariants.

## Decisions Made

- Portable Android mode consumes runner-provided `JAVA_HOME` and `ANDROID_SDK_ROOT`; only connected mode may provision the existing macOS SDK/emulator path.
- Gradle User Home remains owned solely by `gradle/actions/setup-gradle@v6`; its job context carries the extra JDK, architecture, wrapper, and configuration digest needed for exact compatibility.
- Release Please and propagation/recovery retry semantics remain outside ordinary CI assertion-retry policy and were left unchanged per D-24.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Cleared an existing ShellCheck declaration warning in the touched helper**
- **Found during:** Task 1 verification
- **Issue:** The required whole-file ShellCheck command failed on a combined local declaration and command substitution.
- **Fix:** Split declaration from assignment without changing provisioning behavior.
- **Files modified:** `script/verify_generated_android_shell.sh`
- **Verification:** `shellcheck script/verify_generated_android_shell.sh` passed.
- **Committed in:** `d0eb9a8f`

**2. [Rule 2 - Missing Critical] Bound official Gradle caching to explicit JVM and configuration identity**
- **Found during:** Plan-level verification against D-22
- **Issue:** Wrapper-derived setup alone did not make JDK, architecture, and relevant Gradle configuration/lock content explicit in the official action's job cache identity.
- **Fix:** Added a deterministic configuration digest and compatibility-qualified official setup context without introducing a second cache.
- **Files modified:** `.github/actions/setup-android-jvm/action.yml`, `test/crosswake/proof/phase165_ci_integrity_test.exs`
- **Verification:** Composite YAML, runner/cache integrity tests, workflow actionlint, and the complete plan gate passed.
- **Committed in:** `aa2afcc2`

---

**Total deviations:** 2 auto-fixed (1 Rule 2, 1 Rule 3).
**Impact on plan:** Both fixes were required to satisfy the plan's prescribed verification and complete cache-compatibility boundary; neither changed Android features or release authority.

## Issues Encountered

- The user-owned `.tool-versions` edit names locally unavailable Erlang/Elixir builds. Verification used command-scoped installed versions (`Erlang 28.4.1`, `Elixir 1.19.5-otp-28`) without modifying or staging that file.
- `actionlint` treats standalone composite action metadata as a workflow, so composite syntax was parsed with PyYAML while every affected workflow was checked by actionlint.

## Known Stubs

None. Empty shell values are deliberate initialization and absent-state sentinels, not product or proof placeholders.

## User Setup Required

None - no credentials, remote mutations, package installation, or human verification were required.

## Next Phase Readiness

Plan 165-05 can consolidate core proof onto the portable setup and exact cache contracts. The Android generator, Maven/JVM/vector fixtures, connected/device posture, and all Release Please authority remain unchanged.

## Self-Check: PASSED

- All eight owned files exist, including the new Android JVM setup action.
- All eight TDD/task/fix commits resolve in Git.
- Shell syntax, ShellCheck, four workflow actionlint checks, all 13 CI integrity tests, composite YAML parsing, formatting, and the four-case leaf-manifest self-test pass.
- The current inventory contains zero unbounded jobs and no pure Elixir/Android JVM job retained on macOS.

---
*Phase: 165-efficient-and-maintainable-ci*
*Completed: 2026-09-07*
