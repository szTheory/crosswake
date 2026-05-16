# Phase 3 Plan 03-04 Summary

## Outcome

The Android shell plan is now code-complete and the generated-project proof lane runs
through real SDK provisioning, Gradle bootstrap, and project compilation. The
remaining failure is host-side managed-device startup: Gradle cannot create the
Android emulator snapshot on this machine, so the runtime proof hook is still
blocked outside the repo.

## Delivered

- Implemented manifest-first Android shell templates for app launch, App Links,
  route denial UI, bounded `WebView` hosting, generated unit tests, and generated
  instrumentation tests.
- Repaired `script/verify_generated_android_shell.sh` so it:
  - validates Java by execution, not just file presence
  - prefers a working Homebrew `openjdk@17` install before falling back to direct
    download
  - avoids `pipefail` false negatives on `sdkmanager --licenses`
  - provisions the smaller `aosp-atd` managed-device image to reduce disk pressure
  - cleans up transient archives after extraction
- Replaced the broken generated `gradlew` stub with a self-bootstrapping wrapper that
  downloads and caches the Gradle distribution instead of assuming a missing
  `gradle-wrapper.jar`.
- Fixed the generated Android bridge template so the bounded bridge channel compiles
  against `WebViewCompat.addWebMessageListener`.

## Verification

Executed:

```bash
mix test test/mix/tasks/crosswake_gen_shell_test.exs \
  test/crosswake/bridge/contract_test.exs \
  test/crosswake/bridge/registry_test.exs \
  test/crosswake/compatibility/compatibility_test.exs
./script/verify_generated_android_shell.sh
```

Results:

- The generator and bridge/compatibility tests pass.
- `script/verify_generated_android_shell.sh` now reaches real Gradle execution.
- The generated Android project now compiles far enough to clear the earlier wrapper,
  toolchain, and Kotlin bridge errors.
- The remaining failure is `:app:crosswakeApi34Setup`, where Gradle reports:
  `EmulatorSnapshotCannotCreatedException` because the managed device emulator closes
  unexpectedly while creating the snapshot.

## Remaining Blocker

- Host environment: the managed Android emulator exits during Gradle's snapshot setup
  for `dev34_aosp_atd_arm64-v8a_Pixel_6`.
- This is now the gating proof-lane issue for Plan 03-04. The repo-side blockers
  found during this execution pass have been addressed.
