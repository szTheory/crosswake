---
phase: 03-native-shell-boot-and-bounded-bridge
plan: 02
subsystem: shell
tags: [shell-generator, fixtures, android, xcode, gradle, tdd]
requires:
  - phase: 03-native-shell-boot-and-bounded-bridge
    provides: typed activation requests, stable denial vocabulary, pack compatibility checks
provides:
  - canonical shell fixture exports derived from manifest and activation truth
  - host-owned iOS and Android shell baseline generation
  - Android Gradle baseline templates with bundled manifest, activation, denial, and pack fixtures
affects: [03-03 ios-shell, 03-04 android-shell, 03-05 bounded-bridge, proof-lanes]
tech-stack:
  added: []
  patterns: [scaffold-once host-owned native generation, canonical fixture export, thin manifest-first shell baseline]
key-files:
  created:
    - lib/crosswake/shell/fixtures.ex
    - priv/templates/crosswake/shell/android/settings.gradle.eex
    - priv/templates/crosswake/shell/android/build.gradle.eex
    - priv/templates/crosswake/shell/android/gradle.properties.eex
    - priv/templates/crosswake/shell/android/gradlew.eex
    - priv/templates/crosswake/shell/android/gradlew.bat.eex
    - priv/templates/crosswake/shell/android/gradle/wrapper/gradle-wrapper.properties.eex
    - priv/templates/crosswake/shell/android/app/build.gradle.eex
    - priv/templates/crosswake/shell/android/app/src/main/AndroidManifest.xml.eex
  modified:
    - lib/mix/tasks/crosswake.gen.shell.ex
    - test/mix/tasks/crosswake_gen_shell_test.exs
key-decisions:
  - "Crosswake.Shell.Fixtures is the sole export layer for bundled manifest, activation, denial, and pack inventory fixtures so native templates do not invent parallel shell-only JSON."
  - "mix crosswake.gen.shell now states scaffold-once, host-owned ownership explicitly and preserves non-overwriting generation semantics instead of implying safe regeneration."
  - "Android baseline generation uses thin Gradle and manifest templates while iOS baseline files stay inline in the task to avoid widening ownership beyond the plan."
patterns-established:
  - "Shell generation produces host-owned app baselines plus bundled canonical fixtures on both platforms."
  - "Native shell scaffolds stay manifest-first and intentionally thin: boot seam, bundled fixture load, and denial surface only."
requirements-completed: [SHELL-01, SHELL-02, MANI-03]
duration: 3min
completed: 2026-05-15
---

# Phase 3 Plan 2: Native Shell Boot And Bounded Bridge Summary

**Canonical manifest-backed shell fixtures now ship with scaffold-once iOS and Android host baselines, replacing the Phase 1 placeholder shell output.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-14T22:23:18Z
- **Completed:** 2026-05-14T22:26:44Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments

- Added `Crosswake.Shell.Fixtures` to export canonical bundled manifest, activation, denial, declared-pack, and installed-pack fixtures from existing manifest and shell contract truth.
- Upgraded `mix crosswake.gen.shell` to generate host-owned shell baselines, emit scaffold-once ownership language, and bundle the canonical fixture set on both iOS and Android.
- Replaced the Android placeholder shell output with a thin Gradle/Android Studio baseline template set and tightened generator tests around real project artifacts.

## Task Commits

1. **Task 1 RED: shell generator contract spec** - `d4fbe66` (`test`)
2. **Tasks 1-2 GREEN: canonical fixtures plus real shell baselines** - `1a62f30` (`feat`)

## Files Created/Modified

- `lib/crosswake/shell/fixtures.ex` - canonical shell fixture export layer for manifest, activation, denial, and pack inventory JSON
- `lib/mix/tasks/crosswake.gen.shell.ex` - scaffold-once generator contract, iOS baseline output, Android template rendering, and bundled fixture wiring
- `priv/templates/crosswake/shell/android/settings.gradle.eex` - Android Studio root settings baseline
- `priv/templates/crosswake/shell/android/build.gradle.eex` - root Android Gradle plugin baseline
- `priv/templates/crosswake/shell/android/gradle.properties.eex` - Gradle property defaults for the generated shell
- `priv/templates/crosswake/shell/android/gradlew.eex` - host-owned Gradle launcher stub
- `priv/templates/crosswake/shell/android/gradlew.bat.eex` - Windows launcher stub
- `priv/templates/crosswake/shell/android/gradle/wrapper/gradle-wrapper.properties.eex` - wrapper distribution metadata
- `priv/templates/crosswake/shell/android/app/build.gradle.eex` - thin app module build baseline
- `priv/templates/crosswake/shell/android/app/src/main/AndroidManifest.xml.eex` - app boot seam and explicit launcher manifest
- `test/mix/tasks/crosswake_gen_shell_test.exs` - TDD coverage for host-owned shell ownership language and real native artifact inventory

## Decisions Made

- Kept fixture generation fully Elixir-side and manifest-backed so later platform plans can boot the same serialized truth without introducing platform-specific contract drift.
- Moved README ownership wording into the task instead of editing the existing README templates, which kept the change inside owned files while still correcting the public generator posture.
- Limited the Android scaffold to Gradle root files, an app module manifest seam, and bundled fixtures, leaving runtime boot, offline hosts, and broader native surface area to later Phase 3 plans.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Landed the Task 1 and Task 2 GREEN work in one feature commit**
- **Found during:** Task 1 implementation
- **Issue:** The upgraded generator path renders Android baseline files directly, so splitting the generator contract and Android baseline into separate passing GREEN commits would have left an intermediate broken generator/test state.
- **Fix:** Implemented the coupled generator, fixture export, template rendering, and test contract together in one feature commit after the RED commit.
- **Files modified:** `lib/mix/tasks/crosswake.gen.shell.ex`, `lib/crosswake/shell/fixtures.ex`, Android templates, `test/mix/tasks/crosswake_gen_shell_test.exs`
- **Verification:** `mix test test/mix/tasks/crosswake_gen_shell_test.exs`
- **Committed in:** `1a62f30`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** No scope expansion. The work still matches the planned artifact set and acceptance criteria; only the GREEN commit boundary was coupled.

## Issues Encountered

- The initial README wording said "scaffolds it once" rather than the literal `scaffold once` phrase required by the new generator test; the ownership copy was tightened before final verification.
- Fixture JSON recovery metadata was normalized to string values so the generated denial example stays serializable and machine-readable.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 03-03 and Plan 03-04 can wire real shell runtime boot on top of generated host-owned baselines rather than placeholder source stubs.
- Plan 03-05 can reuse the bundled activation and denial fixtures as proof-lane inputs for the bounded bridge contract.

## Self-Check: PASSED

- Verified summary target file exists at `.planning/phases/03-native-shell-boot-and-bounded-bridge/03-native-shell-boot-and-bounded-bridge-02-SUMMARY.md`.
- Verified required files exist: `lib/mix/tasks/crosswake.gen.shell.ex`, `lib/crosswake/shell/fixtures.ex`, `priv/templates/crosswake/shell/android/settings.gradle.eex`, `priv/templates/crosswake/shell/android/build.gradle.eex`, `priv/templates/crosswake/shell/android/gradle.properties.eex`, `priv/templates/crosswake/shell/android/gradlew.eex`, `priv/templates/crosswake/shell/android/gradlew.bat.eex`, `priv/templates/crosswake/shell/android/gradle/wrapper/gradle-wrapper.properties.eex`, `priv/templates/crosswake/shell/android/app/build.gradle.eex`, `priv/templates/crosswake/shell/android/app/src/main/AndroidManifest.xml.eex`, `test/mix/tasks/crosswake_gen_shell_test.exs`.
- Verified commit hashes exist in git history: `d4fbe66`, `1a62f30`.
