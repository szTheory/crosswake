---
phase: 05-packs-native-escape-and-proof-lanes
plan: 03
subsystem: ui
tags: [packs, ios, android, shell-generator, swiftui, kotlin]
requires:
  - phase: 05-packs-native-escape-and-proof-lanes
    provides: typed pack lifecycle, inventory records, and fail-closed activation gating from 05-02
provides:
  - generated iOS required-pack store and gating view
  - generated Android required-pack activity and persisted pack store
  - shared shell generator fixture wiring for pack inventory surfaces
affects: [05-05, 05-06, 05-07, 05-08, generated-shell-proof]
tech-stack:
  added: [androidx.lifecycle-runtime-ktx, kotlinx-coroutines-android]
  patterns: [manifest-backed pack inventory fixtures, foreground-first required-pack gating, generated shell local pack-store persistence]
key-files:
  created: [priv/templates/crosswake/shell/ios/PackStore.swift.eex, priv/templates/crosswake/shell/ios/RequiredPackView.swift.eex, priv/templates/crosswake/shell/android/app/src/main/java/dev/crosswake/shell/packs/PackStore.kt.eex, priv/templates/crosswake/shell/android/app/src/main/java/dev/crosswake/shell/packs/RequiredPackActivity.kt.eex, priv/templates/crosswake/shell/android/app/src/main/res/layout/activity_required_pack.xml.eex]
  modified: [lib/crosswake/shell/fixtures.ex, lib/mix/tasks/crosswake.gen.shell.ex, priv/templates/crosswake/shell/ios/ActivationCoordinator.swift.eex, priv/templates/crosswake/shell/ios/CrosswakeShellApp.swift.eex, priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex, priv/templates/crosswake/shell/android/app/build.gradle.eex, priv/templates/crosswake/shell/android/app/src/main/AndroidManifest.xml.eex, priv/templates/crosswake/shell/android/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt.eex, priv/templates/crosswake/shell/android/app/src/main/java/dev/crosswake/shell/MainActivity.kt.eex, test/mix/tasks/crosswake_gen_shell_test.exs]
key-decisions:
  - "Generated pack runtime surfaces reuse manifest-backed declared pack and inventory fixtures instead of inventing shell-local pack truth."
  - "Both platforms gate route activation on explicit required-pack UI and keep install and invalidation foreground-first."
  - "Android pack state persists through the generated shell via a narrow SharedPreferences-backed PackStore so the required-pack activity can unblock activation without widening into a background manager."
patterns-established:
  - "Generated shells surface a dedicated required-pack screen before LiveView route entry when pack state is not available."
  - "Pack lifecycle execution remains explicit and low-frequency: install, verify, retry, invalidate."
requirements-completed: [PACK-02]
duration: 6 min
completed: 2026-05-17
---

# Phase 5 Plan 03: Generated Required-Pack Runtime Summary

**Generated iOS and Android shells now emit manifest-backed required-pack install, verify, retry, and invalidation surfaces before LiveView route activation proceeds**

## Performance

- **Duration:** 6 min
- **Started:** 2026-05-17T01:13:30+02:00
- **Completed:** 2026-05-17T01:19:52+02:00
- **Tasks:** 2
- **Files modified:** 15

## Accomplishments

- Added bundled `pack_inventory.json` fixture truth and generator wiring so both shells consume the same declared-pack and installed-pack baseline.
- Implemented iOS `PackStore` and `RequiredPackView` templates, then routed activation through the required-pack surface instead of immediate pack denial.
- Implemented Android persisted `PackStore`, `RequiredPackActivity`, layout, and manifest/main-activity wiring so blocked routes stop on explicit pack lifecycle UI.

## Task Commits

Each task was committed atomically:

1. **Task 1: Generate iOS required-pack install and inventory surfaces** - `1a9d4da` (test), `e680f5f` (feat)
2. **Task 2: Generate Android required-pack install and inventory surfaces** - `ab4349b` (test), `6e53842` (feat)

## Files Created/Modified

- `lib/crosswake/shell/fixtures.ex` - exports `pack_inventory.json` alongside declared and installed pack fixtures.
- `lib/mix/tasks/crosswake.gen.shell.ex` - generates new iOS and Android required-pack runtime files.
- `priv/templates/crosswake/shell/ios/PackStore.swift.eex` - foreground-first iOS pack lifecycle store and bundled fixture loader.
- `priv/templates/crosswake/shell/ios/RequiredPackView.swift.eex` - required-pack gate UI with install, update, retry, and invalidate actions.
- `priv/templates/crosswake/shell/android/app/src/main/java/dev/crosswake/shell/packs/PackStore.kt.eex` - persisted Android pack lifecycle store backed by bundled fixtures plus local overrides.
- `priv/templates/crosswake/shell/android/app/src/main/java/dev/crosswake/shell/packs/RequiredPackActivity.kt.eex` - route-facing Android required-pack screen.
- `test/mix/tasks/crosswake_gen_shell_test.exs` - generator coverage for both platforms’ required-pack surfaces and current proof-script expectations.

## Decisions Made

- Kept pack execution tied to manifest-declared pack ids and versions, with route activation resuming only after the generated pack store reports `available`.
- Reused the fail-closed activation posture from 05-02, but switched the user-facing shell experience from silent denial to an explicit required-pack gate.
- Limited Android persistence to local pack lifecycle state so the generated shell can survive the separate required-pack activity without implying a general download manager.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated generator verification to the current Android proof hook**
- **Found during:** Task 1 (Generate iOS required-pack install and inventory surfaces)
- **Issue:** `test/mix/tasks/crosswake_gen_shell_test.exs` still expected `crosswakeApi34DebugAndroidTest`, but the dirty in-repo `script/verify_generated_android_shell.sh` now runs `connectedDebugAndroidTest`.
- **Fix:** Updated the test assertion to match the current proof-script command instead of reverting unrelated shell verification changes.
- **Files modified:** `test/mix/tasks/crosswake_gen_shell_test.exs`
- **Verification:** `rg -n "crosswakeApi34|connectedDebugAndroidTest" script/verify_generated_android_shell.sh test/mix/tasks/crosswake_gen_shell_test.exs` and `mix test test/mix/tasks/crosswake_gen_shell_test.exs`
- **Committed in:** `e680f5f`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The auto-fix was required to keep the plan’s verification file aligned with current repo truth. No contract scope widened.

## Issues Encountered

- Pre-existing dirty Phase 5 proof-script changes caused one stale assertion in the shared generator test. The plan accommodated that repo state and continued without touching the scripts themselves.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Generated shells now expose explicit required-pack lifecycle surfaces that later transfer and native-capture plans can route through.
- Proof posture still depends on the existing host-environment blockers from Phase 3; this plan only verified generator output through `mix test`.

## Self-Check: PASSED

---
*Phase: 05-packs-native-escape-and-proof-lanes*
*Completed: 2026-05-17*
